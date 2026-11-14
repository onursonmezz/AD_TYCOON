class_name MgFilm
extends MinigameGame
## Kurgu provası (K-120; TV, sinema, internet videosu): üç sahneyi Giriş / Ürün / Çağrı yuvalarına sırayla koy.
## Giriş = atmosfer (arka plan), Ürün = ürün yakın çekim, Çağrı = slogan ve marka. Yanlış tık başarıdan götürür.

const CARD: Vector2 = Vector2(180, 104)

var _order: Array[int] = []
var _placed: Array[int] = []
var _mistakes: int = 0
var _cards: Array[Control] = []


func begin() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.color = CozyTheme.SAGE_SOFT.lightened(0.45)
	bg.size = CANVAS
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var frame_tex: Texture2D = DraftArt.tex("props", "prop_film_frame")
	for i: int in 3:
		var slot: Rect2 = _slot_rect(i)
		if frame_tex != null:
			add_child(DraftArt._image(frame_tex, slot.grow(10), TextureRect.STRETCH_SCALE))
		var cap: Label = UiUtil.label(tr("MG_FILM_SLOT_%d" % (i + 1)), 13, CozyTheme.FOREST)
		cap.add_theme_font_override("font", CozyTheme.strong_font())
		cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cap.position = Vector2(slot.position.x, slot.end.y + 12)
		cap.size = Vector2(slot.size.x, 20)
		add_child(cap)
	_order = [0, 1, 2]
	while _order == [0, 1, 2]:
		_order.shuffle()
	for i: int in 3:
		var card: Control = _scene(_order[i])
		card.position = _card_pos(i)
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.gui_input.connect(_on_card.bind(i))
		_cards.append(card)
		add_child(card)


func _slot_rect(i: int) -> Rect2:
	return Rect2(Vector2(20 + i * 200, 22), CARD)


func _card_pos(i: int) -> Vector2:
	return Vector2(20 + i * 200, 196)


## Sahne kartı: 0 giriş (arka plan), 1 ürün, 2 çağrı (slogan + marka).
func _scene(kind: int) -> Control:
	var c: Control = Control.new()
	c.size = CARD
	c.custom_minimum_size = CARD
	c.clip_contents = true
	var draft: Dictionary = DraftArt.options(DataDB.data, ctx["setup"], int(ctx["year"]), int(ctx["seed"]))[0]
	match kind:
		0:
			var t: Texture2D = DraftArt.tex("backgrounds", str(draft["bg"]))
			if t != null:
				c.add_child(DraftArt._image(t, Rect2(Vector2.ZERO, CARD), TextureRect.STRETCH_KEEP_ASPECT_COVERED))
		1:
			var fill: ColorRect = ColorRect.new()
			fill.color = CozyTheme.CREAM_LIGHT
			fill.size = CARD
			c.add_child(fill)
			var p: Texture2D = DraftArt.tex("products", str(draft["product"]))
			if p != null:
				c.add_child(DraftArt._image(p, Rect2(Vector2(10, 6), CARD - Vector2(20, 12)), TextureRect.STRETCH_KEEP_ASPECT_CENTERED))
		_:
			var fill2: ColorRect = ColorRect.new()
			fill2.color = ctx["accent"]
			fill2.size = CARD
			c.add_child(fill2)
			var slogan: String = tr(str(draft["slogan"])).format({"brand": str(ctx["brand"])})
			DraftArt._text(c, slogan, 15, CozyTheme.CREAM_LIGHT, Rect2(Vector2(8, 4), CARD - Vector2(16, 8)))
	var border: ReferenceRect = ReferenceRect.new()
	border.border_color = CozyTheme.BORDER
	border.border_width = 2.0
	border.editor_only = false
	border.size = CARD
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(border)
	return c


func _on_card(event: InputEvent, i: int) -> void:
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if _done or mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	var scene: int = _order[i]
	if _placed.has(scene):
		return
	if scene == _placed.size():
		var card: Control = _cards[i]
		create_tween().tween_property(card, "position", _slot_rect(_placed.size()).position, 0.12)
		_placed.append(scene)
		Audio.play("click")
		if _placed.size() == 3:
			finish(1.0 - 0.34 * _mistakes)
	else:
		_mistakes += 1
		var card2: Control = _cards[i]
		var tw: Tween = create_tween()
		tw.tween_property(card2, "modulate", Color(1, 0.6, 0.6), 0.08)
		tw.tween_property(card2, "modulate", Color.WHITE, 0.2)


func time_up() -> void:
	finish(0.25 * _placed.size() * (1.0 - 0.34 * _mistakes))
