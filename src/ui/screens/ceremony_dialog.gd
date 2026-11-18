class_name CeremonyDialog
extends Control
## Ödül töreni (GDD 15 "duygusal bir an"; UI-3 taslağı 21): her başvuru bir sahnede (perdeler, defne dalları, konfeti,
## ışıltılar, kırmızı halı üstünde kupa, derece kurdelesi); altında rakipler ve Grand Prix yan yana, en altta ödül
## sezonu ve "Devam et". Sonuçlar teker teker açılır, Grand Prix en sonda. Ölçüler data/ui_layout.json "ceremony_stage".

const REVEAL_SECONDS: float = 0.8
const FOOTER_HEIGHT: float = 34.0

var _result: Dictionary
var _cfg: Dictionary
var _stages: VBoxContainer
var _bottom: HBoxContainer


func _init(result: Dictionary) -> void:
	_result = result
	set_meta("esc_closes", true)


func _ready() -> void:
	var data: GameData = DataDB.data
	var layout: Dictionary = data.raw["ui_layout.json"]
	_cfg = layout["ceremony_stage"]
	var col: VBoxContainer = UiUtil.modal_frame(self, UiUtil.dialog_size("ceremony"), true, true)
	col.add_theme_constant_override("separation", 0)
	var head: Label = UiUtil.heading("%s · %d" % [UiUtil.name_of(data.awards, _result["award"]), int(_result["year"])], "trophy")
	var emblem: String = str((layout["award_art"] as Dictionary).get(str(_result["award"]), ""))
	if not emblem.is_empty():
		head.set_meta("heading_art", _emblem(emblem))
	col.add_child(head)
	# Sahne pencere kenarına kadar uzanır: çerçevenin iç boşluğu sıfırlanır, alt kısımlar kendi boşluğunu alır.
	var body: VBoxContainer = UiUtil.modal_outer(col)
	var margin: MarginContainer = body.get_parent() as MarginContainer
	for side: String in ["left", "right", "top"]:
		margin.add_theme_constant_override("margin_" + side, 0)
	margin.add_theme_constant_override("margin_bottom", CozyTheme.SPACE_M)
	body.add_theme_constant_override("separation", 0)
	_stages = UiUtil.vbox(0)
	col.add_child(_stages)
	var lower: VBoxContainer = UiUtil.vbox(CozyTheme.SPACE_S)
	col.add_child(_pad(lower))
	lower.add_child(HSeparator.new())
	_bottom = UiUtil.hbox(CozyTheme.SPACE_M)
	_bottom.custom_minimum_size.y = float(_cfg["bottom_art"])
	lower.add_child(_bottom)
	var foot: VBoxContainer = UiUtil.vbox(CozyTheme.SPACE_S)
	foot.add_child(HSeparator.new())
	var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	row.custom_minimum_size.y = FOOTER_HEIGHT
	row.add_child(_season())
	row.add_child(UiUtil.spacer())
	var close: Button = UiUtil.button(tr("UI_CEREMONY_CONTINUE"), queue_free)
	close.theme_type_variation = "PrimaryButton"
	close.custom_minimum_size = Vector2(120.0, FOOTER_HEIGHT)
	row.add_child(close)
	foot.add_child(row)
	body.add_child(_pad(foot))
	_reveal()


func _reveal() -> void:
	var data: GameData = DataDB.data
	for r: Dictionary in _result["player"]:
		if not await _pause():
			return
		var stage: Control = _stage(r)
		_stages.add_child(stage)
		UiUtil.pop_in(stage)
	if not await _pause():
		return
	_bottom.add_child(_bottom_cell("rivals", tr("UI_RIVALS"),
		tr("UI_CEREMONY_RIVALS_SHORT") % (_result["rivals"] as Array).size(), false))
	if not await _pause():
		return
	var gp: Dictionary = _result["grand_prix"]
	var who: String = tr("UI_CEREMONY_GP_NONE")
	if gp["who"] == "player":
		who = tr("UI_CEREMONY_GP_US")
	elif not str(gp["who"]).is_empty():
		who = UiUtil.name_of(data.rivals, gp["who"])
	_bottom.add_child(VSeparator.new())
	_bottom.add_child(_bottom_cell("grand_prix", tr("LEVEL_GRAND_PRIX"), who, true))


## Sıradaki satırdan önce kısa bekleme; pencere kapandıysa false.
func _pause() -> bool:
	await get_tree().create_timer(REVEAL_SECONDS).timeout
	return is_inside_tree()


func _pad(c: Control) -> MarginContainer:
	var m: MarginContainer = MarginContainer.new()
	for side: String in ["left", "right"]:
		m.add_theme_constant_override("margin_" + side, CozyTheme.SPACE_L)
	m.add_child(c)
	return m


func _art(key: String) -> String:
	return str(_cfg["art"][key])


func _rect(key: String) -> Rect2:
	var a: Array = _cfg[key]
	return Rect2(float(a[0]), float(a[1]), float(a[2]), float(a[3]))


## Sahneye konumlu çizim ekler. mirror: tasarım genişliğine göre sağ eşi.
func _place(stage: Control, tex: Texture2D, r: Rect2, mirror: bool = false, tint: Color = Color.WHITE) -> TextureRect:
	var t: TextureRect = TextureRect.new()
	t.texture = tex
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.modulate = tint
	t.size = r.size
	t.position = Vector2(float(_cfg["design_width"]) - r.position.x - r.size.x if mirror else r.position.x, r.position.y)
	stage.add_child(t)
	return t


## Çizimin alt kısmı (frac oranı) aşağı doğru saydamlaşır: perdenin düz kesik ucu görünmesin.
func _fade_bottom(tex: Texture2D, frac: float) -> Texture2D:
	var img: Image = tex.get_image()
	var h: int = img.get_height()
	var start: int = int(h * (1.0 - frac))
	for y: int in range(start, h):
		var k: float = 1.0 - float(y - start) / float(maxi(1, h - start))
		k = k * k * (3.0 - 2.0 * k)
		for x: int in img.get_width():
			var c: Color = img.get_pixel(x, y)
			c.a *= k
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


## Defne çelengin sol ya da sağ yarısı: tek dal.
func _sprig(px: int, right: bool) -> AtlasTexture:
	var a: AtlasTexture = AtlasTexture.new()
	a.atlas = IconPack.art(_art("laurel"), px)
	a.region = Rect2(px * 0.5 if right else 0.0, 0.0, px * 0.5, px)
	return a


## Yatay yatırılmış dal (kurdele altındaki süs): sol dal sola, sağ dal sağa uzanır.
func _sprig_flat(px: int, right: bool) -> Texture2D:
	var a: AtlasTexture = _sprig(px, right)
	var img: Image = a.atlas.get_image().get_region(Rect2i(a.region))
	img.rotate_90(COUNTERCLOCKWISE if right else CLOCKWISE)
	return ImageTexture.create_from_image(img)


## Bir başvurunun sahnesi (taslak 21'in ortası).
func _stage(r: Dictionary) -> Control:
	var level: String = str(r["level"])
	var tints: Dictionary = _cfg["tint"]
	var tint: Color = Color(str(tints.get(level, tints[""])))
	var stage: Control = Control.new()
	var w: float = float(_cfg["design_width"])
	stage.custom_minimum_size = Vector2(w, float(_cfg["height"]))
	stage.clip_contents = true
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Perdeler sahnenin üst köşelerinden sarkar: boş kenarı atılmış çizim, üstü ve dış kenarı sahneye yapışık.
	var curtain: Rect2 = _rect("curtain")
	for right: bool in [false, true]:
		var ct: Texture2D = _fade_bottom(IconPack.art_wide(_art("curtain_right" if right else "curtain_left"),
			int(curtain.size.x)), float(_cfg["curtain_fade"]))
		var ch: float = curtain.size.x * float(ct.get_height()) / float(ct.get_width())
		_place(stage, ct, Rect2(0.0, 0.0, curtain.size.x, ch), right).stretch_mode = TextureRect.STRETCH_SCALE
	for c: Array in _cfg["confetti"]:
		_place(stage, IconPack.art(_art("confetti"), int(c[2])), Rect2(float(c[0]), float(c[1]), float(c[2]), float(c[2])))
	for s: Array in _cfg["sparkles"]:
		_place(stage, IconPack.art(_art("sparkles"), int(s[2])), Rect2(float(s[0]), float(s[1]), float(s[2]), float(s[2])))
	var carpet: Rect2 = _rect("carpet")
	var rug: TextureRect = _place(stage, IconPack.art_wide(_art("carpet"), int(carpet.size.x)), carpet)
	rug.stretch_mode = TextureRect.STRETCH_SCALE
	var branch: Rect2 = _rect("branch")
	var bpx: int = int(branch.size.y)
	_place(stage, _sprig(bpx, false), branch).stretch_mode = TextureRect.STRETCH_SCALE
	_place(stage, _sprig(bpx, true), branch, true).stretch_mode = TextureRect.STRETCH_SCALE
	if not level.is_empty():
		var trophy: Rect2 = _rect("trophy")
		var cups: Dictionary = DataDB.data.raw["ui_layout.json"]["trophy_art"]
		var file: String = str(cups.get(level, cups["silver"]))
		# Kendi çizimi olmayan dereceler (bronz, kısa liste) gümüş kupanın o renkle boyanmış hali.
		var cup_tint: Color = tint if file == str(cups["silver"]) else Color.WHITE
		_place(stage, IconPack.art(file, int(trophy.size.y)), trophy, false, cup_tint)
	var ribbon: Rect2 = _rect("ribbon")
	# Kurdele görseli taslaktakinden kısa: yatayda gerilerek taslak boyuna getirilir.
	_place(stage, IconPack.art_wide(_art("ribbon"), int(ribbon.size.x)), ribbon, false, tint).stretch_mode = \
		TextureRect.STRETCH_SCALE
	# Derece yazısı kurdelenin ortasında, kurdelenin kavsine uyan bir yayda; beyaz, kurdele renginin koyusuyla konturlu.
	var band: ArcText = ArcText.new()
	band.text = tr("UI_RIBBON_" + (level.to_upper() if not level.is_empty() else "NONE"))
	band.font = CozyTheme.title_font(700)
	band.font_size = int(_cfg["ribbon_text_size"])
	band.radius = float(_cfg["ribbon_text_radius"])
	band.outline_color = Color(tint.darkened(0.55), 0.9)
	band.position = Vector2(ribbon.position.x, float(_cfg["ribbon_text_y"]))
	band.size = Vector2(ribbon.size.x, float(_cfg["ribbon_text_h"]))
	stage.add_child(band)
	stage.add_child(_ornament(_rect("ornament")))
	var title: String = str(r.get("name", "")) if not str(r.get("name", "")).is_empty() else tr("UI_UNTITLED")
	stage.add_child(_centered(title, 26, CozyTheme.FOREST, CozyTheme.title_font(700), w, float(_cfg["title_y"])))
	stage.add_child(_client_line(str(r.get("client_name", "")), w))
	var sprig: Rect2 = _rect("title_sprig")
	_place(stage, _sprig(int(sprig.size.y), false), sprig)
	_place(stage, _sprig(int(sprig.size.y), true), sprig, true)
	return stage


func _centered(text: String, size: int, color: Color, font: Font, w: float, y: float) -> Label:
	var l: Label = UiUtil.label(text, size, color)
	l.add_theme_font_override("font", font)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = Vector2(0.0, y)
	l.size = Vector2(w, 0.0)
	return l


## "— Müşteri —": eğik kiremit yazı, iki yanında ince çizgi.
func _client_line(client: String, w: float) -> HBoxContainer:
	var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i: int in 3:
		if i == 1:
			var l: Label = UiUtil.label(client, 18, CozyTheme.TERRA)
			l.add_theme_font_override("font", MenuArt.italic(CozyTheme.body_font()))
			row.add_child(l)
			continue
		var dash: ColorRect = ColorRect.new()
		dash.color = Color(CozyTheme.TERRA, 0.7)
		dash.custom_minimum_size = Vector2(26.0, 1.5)
		dash.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(dash)
	row.position = Vector2(0.0, float(_cfg["client_y"]))
	row.size = Vector2(w, 0.0)
	return row


## Kurdelenin altındaki küçük süs: dal · yıldız · dal.
func _ornament(r: Rect2) -> HBoxContainer:
	var row: HBoxContainer = UiUtil.hbox(4)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h: float = r.size.y
	for i: int in 3:
		var t: TextureRect = TextureRect.new()
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if i == 1:
			t.texture = IconPack.art(_art("star"), int(h))
			t.custom_minimum_size = Vector2(h, h)
		else:
			t.texture = _sprig_flat(int(h * 2.0), i == 2)
			t.custom_minimum_size = Vector2(h * 2.0, h)
		row.add_child(t)
	row.position = r.position
	row.size = r.size
	return row


## Alt satırdaki hücre: çizim (iki yanında dal), başlık ve kiremit alt yazı.
func _bottom_cell(art_key: String, title: String, sub: String, italic: bool) -> HBoxContainer:
	var px: int = int(_cfg["bottom_art"])
	var lead: HBoxContainer = UiUtil.hbox(0)
	if art_key == "rivals":
		lead.add_child(_small_sprig(false))
	var art: TextureRect = TextureRect.new()
	art.texture = IconPack.art(_art(art_key), px)
	art.custom_minimum_size = Vector2(px, px)
	art.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	lead.add_child(art)
	if art_key == "rivals":
		lead.add_child(_small_sprig(true))
	var cell: HBoxContainer = Cards.header(lead, title, sub)
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.size_flags_stretch_ratio = float(_cfg["rivals_ratio"]) if art_key == "rivals" else 1.0
	cell.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var name: Label = (cell.get_child(1) as VBoxContainer).get_child(0) as Label
	name.add_theme_font_size_override("font_size", 20)
	var line: Label = (cell.get_child(1) as VBoxContainer).get_child(1) as Label
	line.add_theme_color_override("font_color", CozyTheme.TERRA)
	line.clip_text = false
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.add_theme_font_size_override("font_size", 16 if italic else 14)
	if italic:
		line.add_theme_font_override("font", MenuArt.italic(CozyTheme.body_font()))
	UiUtil.pop_in(cell)
	return cell


func _small_sprig(right: bool) -> TextureRect:
	var h: int = int(float(_cfg["bottom_art"]) * 0.8)
	var t: TextureRect = TextureRect.new()
	t.texture = _sprig(h, right)
	t.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	t.custom_minimum_size = Vector2(h * 0.5, h)
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return t


## Alttaki "— 2015 ödül sezonu —" yazısı, iki yanında küçük dal.
func _season() -> HBoxContainer:
	var px: int = int(_cfg["footer_sprig"])
	var row: HBoxContainer = UiUtil.hbox(6)
	for i: int in 3:
		if i == 1:
			var l: Label = UiUtil.label(tr("UI_CEREMONY_SEASON") % int(_result["year"]), 15, CozyTheme.TEXT)
			l.add_theme_font_override("font", MenuArt.italic(CozyTheme.body_font()))
			row.add_child(l)
			continue
		var t: TextureRect = TextureRect.new()
		t.texture = _sprig(px, i == 2)
		t.modulate = Color(0.55, 0.5, 0.42)
		t.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(t)
	return row


## Başlık bandı amblemi: ödül çizimi, iki yanında küçük defne dalı (taslaktaki gibi).
func _emblem(file: String) -> Texture2D:
	var px: int = 30
	var img: Image = Image.create(px * 2, px, false, Image.FORMAT_RGBA8)
	var laurel: Image = IconPack.art(_art("laurel"), px).get_image()
	laurel.convert(Image.FORMAT_RGBA8)
	img.blend_rect(laurel, Rect2i(0, 0, px / 2, px), Vector2i(0, 0))
	img.blend_rect(laurel, Rect2i(px / 2, 0, px / 2, px), Vector2i(px * 3 / 2, 0))
	var logo: Texture2D = IconPack.art(file, int(px * 0.8))
	if logo != null:
		var li: Image = logo.get_image()
		li.convert(Image.FORMAT_RGBA8)
		img.blend_rect(li, Rect2i(Vector2i.ZERO, li.get_size()), Vector2i((px * 2 - li.get_width()) / 2, (px - li.get_height()) / 2))
	return ImageTexture.create_from_image(img)
