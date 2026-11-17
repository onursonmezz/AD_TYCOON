class_name MinigameGame
extends Control
## Mini oyunların ortak tabanı (K-120). Oyun bittiğinde finished(başarı 0..1) yayar; süre dolunca host time_up() çağırır.
## ctx: { camp, setup, brand, accent, year, seed }.
## MG-2: her oyun gerçek bir sahnede oynanır (stage: zemin resmi, yuvarlak köşe, çerçeve); bitince ortada büyük bir
## sonuç mührü ("Harika!" / "Fena değil" / "Kaçtı!"); doğru hamlede yeşil parlama, yanlışta sarsılma (flash_ok, shake).

signal finished(quality: float)

const CANVAS: Vector2 = Vector2(640, 360)
const RADIUS: int = 16
const STAMP_GREAT: float = 0.8
const STAMP_OK: float = 0.4

static var _stage_cache: Dictionary = {}

var ctx: Dictionary = {}
## Doluysa mühürde bu yazı çıkar (ör. taslak seçiminde "Seçildi!").
var stamp_text: String = ""
var _done: bool = false


func _init() -> void:
	custom_minimum_size = CANVAS
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true


## Oyunu kurar (ctx atandıktan sonra, ağaca eklenince host çağırır).
func begin() -> void:
	pass


## Süre doldu: o anki duruma göre kısmi başarı.
func time_up() -> void:
	finish(0.0)


func finish(quality: float) -> void:
	if _done:
		return
	_done = true
	var q: float = clampf(quality, 0.0, 1.0)
	_show_stamp(q)
	finished.emit(q)


## Sahne zemini: assets/minigame/backgrounds/<bg>.png oyun alanını kaplar (köşeleri yuvarlatılmış), istenirse üstüne
## yarı saydam bir örtü (okunurluk için). En alta eklenir; çerçeve (frame) en üstte, oyun nesneleri arada.
func stage(bg: String, veil: Color = Color(0, 0, 0, 0)) -> void:
	var tex: Texture2D = _stage_texture(bg)
	var r: TextureRect = TextureRect.new()
	r.texture = tex
	r.size = CANVAS
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	move_child(r, 0)
	if veil.a > 0.0:
		var v: Panel = Panel.new()
		v.add_theme_stylebox_override("panel", CozyTheme.box(veil, RADIUS, Color.TRANSPARENT, 0, false, Vector2.ZERO))
		v.size = CANVAS
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(v)
		move_child(v, 1)
	var frame: Panel = Panel.new()
	var sb: StyleBoxFlat = CozyTheme.box(Color.TRANSPARENT, RADIUS, CozyTheme.BORDER, 2, false, Vector2.ZERO)
	sb.draw_center = false
	frame.add_theme_stylebox_override("panel", sb)
	frame.size = CANVAS
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.z_index = 5
	add_child(frame)


## Zemin dokusu: kaplayacak şekilde kırpılır, CANVAS boyutuna getirilir, köşeleri saydam (önbellekli).
static func _stage_texture(bg: String) -> Texture2D:
	if _stage_cache.has(bg):
		return _stage_cache[bg]
	var src: Texture2D = DraftArt.tex("backgrounds", bg)
	var w: int = int(CANVAS.x)
	var h: int = int(CANVAS.y)
	var img: Image
	if src != null:
		img = src.get_image().duplicate()
		img.convert(Image.FORMAT_RGBA8)
		var aspect: float = CANVAS.x / CANVAS.y
		var cw: int = img.get_width()
		var ch: int = int(cw / aspect)
		if ch > img.get_height():
			ch = img.get_height()
			cw = int(ch * aspect)
		img = img.get_region(Rect2i((img.get_width() - cw) / 2, (img.get_height() - ch) / 2, cw, ch))
		img.resize(w, h, Image.INTERPOLATE_LANCZOS)
	else:
		img = Image.create(w, h, false, Image.FORMAT_RGBA8)
		img.fill(CozyTheme.SAGE_SOFT.lightened(0.45))
	for y: int in RADIUS:
		for x: int in RADIUS:
			var d: float = Vector2(RADIUS - x - 0.5, RADIUS - y - 0.5).length()
			var a: float = clampf(RADIUS - d + 0.5, 0.0, 1.0)
			if a >= 1.0:
				continue
			for p: Vector2i in [Vector2i(x, y), Vector2i(w - 1 - x, y), Vector2i(x, h - 1 - y), Vector2i(w - 1 - x, h - 1 - y)]:
				var c: Color = img.get_pixelv(p)
				c.a *= a
				img.set_pixelv(p, c)
	var t: ImageTexture = ImageTexture.create_from_image(img)
	_stage_cache[bg] = t
	return t


## Sahnenin üstünde okunur kâğıt etiket (örn. "Hedef · Genç", "Aranan gönderi"); konum sol üst köşesi.
func tag(text: String, pos: Vector2, size: int = 14) -> Control:
	var t: Control = MenuArt.tape(text, "", size, -1.5)
	t.position = pos
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(t)
	return t


## Doğru hamle: kısa yeşil parlama ve hafif büyüme.
func flash_ok(c: CanvasItem) -> void:
	var tw: Tween = c.create_tween()
	tw.tween_property(c, "modulate", Color(0.75, 1.15, 0.75), 0.08)
	tw.tween_property(c, "modulate", Color.WHITE, 0.25)
	if c is Control:
		var ctl: Control = c as Control
		ctl.pivot_offset = ctl.size * 0.5
		var s: Tween = ctl.create_tween()
		s.tween_property(ctl, "scale", Vector2(1.08, 1.08), 0.08)
		s.tween_property(ctl, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Yanlış hamle: kırmızımsı yanıp sönme ve yana sarsılma.
func shake(c: CanvasItem) -> void:
	var tw: Tween = c.create_tween()
	tw.tween_property(c, "modulate", Color(1.2, 0.6, 0.55), 0.06)
	tw.tween_property(c, "modulate", Color.WHITE, 0.3)
	if c is Control:
		var ctl: Control = c as Control
		var x0: float = ctl.position.x
		var s: Tween = ctl.create_tween()
		for dx: float in [-8.0, 7.0, -5.0, 3.0, 0.0]:
			s.tween_property(ctl, "position:x", x0 + dx, 0.04)


## Sonuç mührü: ortada eğik kâğıt etiket, arkasında (başarıda) ışın patlaması; zıplayarak gelir.
func _show_stamp(q: float) -> void:
	var key: String = "MG_STAMP_GREAT" if q >= STAMP_GREAT else ("MG_STAMP_OK" if q >= STAMP_OK else "MG_STAMP_MISS")
	var holder: Control = Control.new()
	holder.size = CANVAS
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.z_index = 10
	add_child(holder)
	var dim: Panel = Panel.new()
	dim.add_theme_stylebox_override("panel", CozyTheme.box(Color(0.1, 0.16, 0.12, 0.28), RADIUS, Color.TRANSPARENT, 0, false,
		Vector2.ZERO))
	dim.size = CANVAS
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(dim)
	if q >= STAMP_OK:
		var burst: Texture2D = DraftArt.tex("effects", "fx_rays")
		if burst != null:
			var b: TextureRect = DraftArt._image(burst, Rect2(CANVAS * 0.5 - Vector2(220, 160), Vector2(440, 320)),
				TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
			holder.add_child(b)
	var stamp: Control = MenuArt.tape(stamp_text if not stamp_text.is_empty() else tr(key), "", 46, -6.0)
	holder.add_child(stamp)
	await get_tree().process_frame
	if not is_instance_valid(stamp):
		return
	var sz: Vector2 = stamp.get_combined_minimum_size()
	stamp.position = (CANVAS - sz) * 0.5
	stamp.pivot_offset = sz * 0.5
	stamp.scale = Vector2(0.35, 0.35)
	var tw: Tween = stamp.create_tween()
	tw.tween_property(stamp, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if q < STAMP_OK:
		stamp.modulate = Color(0.85, 0.85, 0.85)


## Taslak dizgicisiyle küçük bir ilan (billboard, gazete): kampanyanın ilk taslak seçeneği.
func ad_preview(size_px: Vector2) -> Control:
	var box: Control = Control.new()
	box.size = size_px
	box.custom_minimum_size = size_px
	box.clip_contents = true
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var draft: Dictionary = (ctx["setup"] as Dictionary).get("draft", {})
	if draft.is_empty():
		draft = DraftArt.options(DataDB.data, ctx["setup"], int(ctx["year"]), int(ctx["seed"]))[0]
	DraftArt.compose(box, draft, size_px, str(ctx["brand"]), ctx["accent"])
	return box


## Taslak seçeneği (ürün, slogan, zemin) — sahne kartları ve rozetler için.
func draft_option() -> Dictionary:
	var draft: Dictionary = (ctx["setup"] as Dictionary).get("draft", {})
	if draft.is_empty():
		draft = DraftArt.options(DataDB.data, ctx["setup"], int(ctx["year"]), int(ctx["seed"]))[0]
	return draft
