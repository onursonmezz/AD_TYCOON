class_name MgFilm
extends MinigameGame
## Kurgu provası (K-120; TV, sinema, internet videosu): üç sahneyi Giriş / Ürün / Çağrı yuvalarına sırayla koy.
## Giriş = atmosfer (arka plan), Ürün = ürün yakın çekim, Çağrı = slogan ve marka. Yanlış tık başarıdan götürür.

const CARD: Vector2 = Vector2(176, 104)

var _order: Array[int] = []
var _placed: Array[int] = []
var _mistakes: int = 0
var _cards: Array[Control] = []


func begin() -> void:
	stage("bg_studio")  # MG-2: kurgu masası gibi stüdyo fonu
	var frame_tex: Texture2D = DraftArt.tex("props", "prop_film_frame")
	for i: int in 3:
		var slot: Rect2 = _slot_rect(i)
		if frame_tex != null:
			add_child(DraftArt._image(frame_tex, slot.grow(10), TextureRect.STRETCH_SCALE))
		var cap: Control = tag("%d · %s" % [i + 1, tr("MG_FILM_SLOT_%d" % (i + 1))], Vector2(slot.position.x + 30, slot.end.y + 14),
			14)
		cap.z_index = 2
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
	return Rect2(Vector2(34 + i * 202, 26), CARD)


func _card_pos(i: int) -> Vector2:
	return Vector2(34 + i * 202, 230)


## Sahne kartı: 0 giriş (arka plan), 1 ürün, 2 çağrı (slogan + marka).
func _scene(kind: int) -> Control:
	var c: Control = Control.new()
	c.size = CARD
	c.custom_minimum_size = CARD
	c.clip_contents = true
	var draft: Dictionary = draft_option()
	match kind:
		0:
			# Giriş: açılış planı (sokak ya da doğa) ve altta "… sunar" yazısı.
			var t: Texture2D = DraftArt.tex("backgrounds", "bg_street" if int(ctx["seed"]) % 2 == 0 else "bg_nature")
			if t != null:
				c.add_child(DraftArt._image(t, Rect2(Vector2.ZERO, CARD), TextureRect.STRETCH_KEEP_ASPECT_COVERED))
			var band: ColorRect = ColorRect.new()
			band.color = Color(0, 0, 0, 0.45)
			band.position = Vector2(0, CARD.y - 30)
			band.size = Vector2(CARD.x, 30)
			band.mouse_filter = Control.MOUSE_FILTER_IGNORE
			c.add_child(band)
			DraftArt._text(c, tr("MG_FILM_PRESENTS") % str(ctx["brand"]), 12, CozyTheme.CREAM_LIGHT,
				Rect2(Vector2(6, CARD.y - 28), Vector2(CARD.x - 12, 26)))
		1:
			# Ürün: masa üstünde yakın çekim.
			var tt: Texture2D = DraftArt.tex("backgrounds", "bg_tabletop")
			if tt != null:
				c.add_child(DraftArt._image(tt, Rect2(Vector2.ZERO, CARD), TextureRect.STRETCH_KEEP_ASPECT_COVERED))
			var p: Texture2D = DraftArt.tex("products", str(draft["product"]))
			if p != null:
				c.add_child(DraftArt._image(p, Rect2(Vector2(30, 8), CARD - Vector2(60, 20)), TextureRect.STRETCH_KEEP_ASPECT_CENTERED))
		_:
			# Çağrı: marka renginde slogan ve "Hemen dene" düğmesi.
			var fill2: ColorRect = ColorRect.new()
			fill2.color = ctx["accent"]
			fill2.size = CARD
			fill2.mouse_filter = Control.MOUSE_FILTER_IGNORE
			c.add_child(fill2)
			var slogan: String = tr(str(draft["slogan"])).format({"brand": str(ctx["brand"])})
			DraftArt._text(c, slogan, 14, CozyTheme.CREAM_LIGHT, Rect2(Vector2(8, 6), Vector2(CARD.x - 16, 58)))
			var cta: PanelContainer = Cards.chip(tr("MG_FILM_CTA"), CozyTheme.CREAM_LIGHT, CozyTheme.FOREST)
			cta.position = Vector2(CARD.x * 0.5 - 44, CARD.y - 34)
			cta.mouse_filter = Control.MOUSE_FILTER_IGNORE
			c.add_child(cta)
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
		create_tween().tween_property(card, "position", _slot_rect(_placed.size()).position, 0.14).set_trans(Tween.TRANS_CUBIC)
		flash_ok(card)
		_placed.append(scene)
		Audio.play("click")
		if _placed.size() == 3:
			finish(1.0 - 0.34 * _mistakes)
	else:
		_mistakes += 1
		shake(_cards[i])


func time_up() -> void:
	finish(0.25 * _placed.size() * (1.0 - 0.34 * _mistakes))
