class_name MgAudience
extends MinigameGame
## Hedef kitle provası (K-120, strateji fazı): brief'in hedef kitlesine uyan kişilere tıkla. Hepsi seçilince biter;
## yanlış kişi başarıdan götürür. Eşleme balance.json minigames.audience_targets.

const PEOPLE: Array[String] = ["young", "adult", "mature", "business", "kid", "family"]
const FIG: Vector2 = Vector2(98, 236)
const GAP: float = 10.0
const CROP_STEP: int = 4
const CROP_ALPHA: float = 0.5

var _targets: Array = []
var _chosen: Array[String] = []
var _mistakes: int = 0
var _figs: Dictionary = {}


func begin() -> void:
	stage("bg_street", Color(0.98, 0.95, 0.88, 0.18))  # MG-2: kalabalık bir çarşı sokağı
	var aud: String = str((ctx["setup"] as Dictionary).get("audience", ""))
	_targets = (DataDB.data.bal("minigames.audience_targets") as Dictionary).get(aud, ["adult", "young"])
	var name: String = UiUtil.name_of(DataDB.data.audiences, aud) if DataDB.data.audiences.has(aud) else tr("MG_AUDIENCE_BROAD")
	var label: Control = tag(tr("MG_AUDIENCE_TARGET") % name, Vector2(18, 14), 18)
	label.z_index = 4
	var order: Array = PEOPLE.duplicate()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(ctx["seed"])
	for i: int in range(order.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: Variant = order[i]
		order[i] = order[j]
		order[j] = tmp
	# Görseller kenar boşluğu kırpılıp hepsi aynı boya getirilir (Orgo: boy farkı algıyı bozuyordu); geniş görsel (aile)
	# daha geniş yer alır. Hepsi sığmazsa boy birlikte küçülür.
	var texs: Dictionary = {}
	var widths: Dictionary = {}
	var h: float = FIG.y
	var total: float = 0.0
	for who: Variant in order:
		var t: Texture2D = _cropped(DraftArt.tex("props", "prop_person_" + str(who)))
		texs[who] = t
		var aspect: float = float(t.get_width()) / float(t.get_height()) if t != null else FIG.x / FIG.y
		widths[who] = aspect
		total += aspect
	var room: float = CANVAS.x - 20.0 - GAP * (order.size() - 1)
	h = minf(h, room / maxf(0.1, total))
	var x: float = 10.0 + (room - total * h) * 0.5
	for i: int in order.size():
		var who: String = str(order[i])
		var fig: Vector2 = Vector2(float(widths[who]) * h, h)
		var holder: Control = Control.new()
		holder.position = Vector2(x, CANVAS.y - h - 30)
		holder.size = fig + Vector2(0, 24)
		x += fig.x + GAP
		holder.mouse_filter = Control.MOUSE_FILTER_STOP
		holder.gui_input.connect(_on_pick.bind(who))
		var ring: Panel = Panel.new()
		ring.add_theme_stylebox_override("panel", CozyTheme.box(Color(CozyTheme.FOREST_LIGHT, 0.0), 999,
			CozyTheme.FOREST_LIGHT, 3, false, Vector2.ZERO))
		ring.position = Vector2(4, fig.y - 4)
		ring.size = Vector2(maxf(40.0, fig.x - 8), 24)
		ring.visible = false
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(ring)
		# Ayak altında yumuşak gölge: kişiler sokağa bassın (havada durmasın).
		var shadow: Panel = Panel.new()
		shadow.add_theme_stylebox_override("panel", CozyTheme.box(Color(0.25, 0.16, 0.08, 0.13), 999, Color.TRANSPARENT, 0, false,
			Vector2.ZERO))
		shadow.position = Vector2(fig.x * 0.15, fig.y - 6)  # kırpılmış görselin alt kenarı ayak hizası
		shadow.size = Vector2(fig.x * 0.7, 9)
		shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(shadow)
		var t: Texture2D = texs[who]
		if t != null:
			holder.add_child(DraftArt._image(t, Rect2(Vector2.ZERO, fig), TextureRect.STRETCH_KEEP_ASPECT_CENTERED))
		add_child(holder)
		_figs[who] = [holder, ring]


## Görselin saydam kenarlarını atar (kişi kendi boyunda ölçeklensin).
func _cropped(t: Texture2D) -> Texture2D:
	if t == null:
		return null
	var img: Image = t.get_image()
	if img == null:
		return t
	if img.is_compressed():
		img.decompress()
	# Soluk kenar pikselleri (gölge, kenar yumuşatma) sayılmasın: küçültülmüş kopyada belirgin piksellerin kutusu.
	var small: Image = img.duplicate()
	small.resize(maxi(1, img.get_width() / CROP_STEP), maxi(1, img.get_height() / CROP_STEP), Image.INTERPOLATE_BILINEAR)
	var lo: Vector2i = Vector2i(small.get_width(), small.get_height())
	var hi: Vector2i = Vector2i(-1, -1)
	for y: int in small.get_height():
		for x: int in small.get_width():
			if small.get_pixel(x, y).a > CROP_ALPHA:
				lo = Vector2i(mini(lo.x, x), mini(lo.y, y))
				hi = Vector2i(maxi(hi.x, x), maxi(hi.y, y))
	if hi.x < 0:
		return t
	var used: Rect2i = Rect2i(lo * CROP_STEP, (hi - lo + Vector2i.ONE) * CROP_STEP).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	var a: AtlasTexture = AtlasTexture.new()
	a.atlas = t
	a.region = Rect2(used)
	return a


func _on_pick(event: InputEvent, who: String) -> void:
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if _done or mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT or _chosen.has(who):
		return
	if _targets.has(who):
		_chosen.append(who)
		(_figs[who][1] as Panel).visible = true
		flash_ok(_figs[who][0])
		Audio.play("click")
		if _chosen.size() == _targets.size():
			finish(1.0 - 0.34 * _mistakes)
	else:
		_mistakes += 1
		shake(_figs[who][0])


func time_up() -> void:
	finish(float(_chosen.size()) / maxf(1.0, float(_targets.size())) * 0.5 * (1.0 - 0.34 * _mistakes))
