class_name NegotiationStage
extends Control
## Pazarlık sahnesi (S2): solda kurucu, sağda matbaanın temsilcisi, ortada el sıkışma. Teklif verince kurucu öne
## eğilip teklifini söyler; ret gelince temsilci başını sallar (ilişki zedelenince kızarır, pazarlık bozulunca
## sinirlenir); kabul edilince eller sıkışır, ikisi de sevinçle zıplar ve ışıltı çıkar. Ölçüler ui_layout negotiation_stage.

const ANGRY: Color = Color(1.0, 0.62, 0.55)

var _cfg: Dictionary
var _us: Control
var _them: Control
var _hands: Control
var _bubble_us: PanelContainer
var _bubble_them: PanelContainer
var _grip: float = 0.0  # 0: eller ayrı, 1: sıkışmış
var _broken: bool = false
var _sparkle: float = 0.0


func _init(founder_avatar: String, rep_avatar: String) -> void:
	_cfg = DataDB.data.raw["ui_layout.json"]["negotiation_stage"]
	custom_minimum_size = Vector2(0.0, float(_cfg["height"]))
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var px: Vector2 = Vector2(float(_cfg["portrait"]), float(_cfg["portrait"]))
	_us = _side(MenuArt.avatar_path(founder_avatar), px)
	_them = _side(MenuArt.avatar_path(rep_avatar), px)
	add_child(_us)
	add_child(_them)
	_hands = Control.new()
	_hands.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hands.draw.connect(_draw_hands)
	add_child(_hands)
	_bubble_us = _bubble()
	_bubble_them = _bubble()
	add_child(_bubble_us)
	add_child(_bubble_them)
	resized.connect(_layout)


func _side(path: String, px: Vector2) -> Control:
	var holder: Control = Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.size = px
	holder.pivot_offset = Vector2(px.x * 0.5, px.y)
	var pic: PanelContainer = MenuArt.picture(path, px)
	pic.size = px
	holder.add_child(pic)
	return holder


func _bubble() -> PanelContainer:
	var b: PanelContainer = PanelContainer.new()
	b.add_theme_stylebox_override("panel", CozyTheme.box(CozyTheme.CREAM_LIGHT, 12, CozyTheme.BORDER, 1, true, Vector2(10, 4)))
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(UiUtil.label("", 14, CozyTheme.TEXT))
	b.modulate.a = 0.0
	return b


func _layout() -> void:
	var px: float = float(_cfg["portrait"])
	var y: float = size.y - px - 4.0
	_us.position = Vector2(float(_cfg["side_margin"]), y)
	_them.position = Vector2(size.x - px - float(_cfg["side_margin"]), y)
	_hands.position = Vector2.ZERO
	_hands.size = size


# --- tepkiler ---------------------------------------------------------------------------------------------------

## Kurucu teklifini söyler: öne eğilir, balonda fiyat.
func offer(text: String) -> void:
	_say(_bubble_us, _us, text, CozyTheme.TEXT)
	var tw: Tween = create_tween()
	tw.tween_property(_us, "rotation", 0.08, 0.15)
	tw.tween_property(_us, "rotation", 0.0, 0.25)


## Temsilci reddeder: başını sallar; strained: ilişki zedelendi (kızarır).
func reject(text: String, strained: bool) -> void:
	_say(_bubble_them, _them, text, CozyTheme.WOOD)
	_shake(_them, 4, 0.07)
	if strained:
		_flush(_them, ANGRY, 0.9)


## Pazarlık bozuldu: temsilci sinirlenir, eller çekilir, el sıkışma kırık.
func fail(text: String) -> void:
	_say(_bubble_them, _them, text, CozyTheme.NEGATIVE)
	_shake(_them, 7, 0.06)
	_flush(_them, ANGRY, 0.0)
	_broken = true
	var tw: Tween = create_tween()
	tw.tween_method(_set_grip, _grip, 0.0, 0.3)


## Anlaşma: eller sıkışır, ikisi de zıplar, ışıltı.
func accept(text: String) -> void:
	_say(_bubble_them, _them, text, CozyTheme.FOREST)
	var tw: Tween = create_tween()
	tw.tween_method(_set_grip, 0.0, 1.0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void:
		_hop(_us)
		_hop(_them)
		var sp: Tween = create_tween()
		sp.tween_method(func(v: float) -> void:
			_sparkle = v
			_hands.queue_redraw(), 0.0, 1.0, 0.9))


func _set_grip(v: float) -> void:
	_grip = v
	_hands.queue_redraw()


func _say(bubble: PanelContainer, who: Control, text: String, col: Color) -> void:
	var l: Label = bubble.get_child(0) as Label
	l.text = text
	l.add_theme_color_override("font_color", col)
	bubble.reset_size()
	var x: float = clampf(who.position.x + who.size.x * 0.5 - bubble.size.x * 0.5, 0.0, size.x - bubble.size.x)
	bubble.position = Vector2(x, who.position.y - bubble.size.y - 6.0)
	bubble.modulate.a = 0.0
	var tw: Tween = create_tween()
	tw.tween_property(bubble, "modulate:a", 1.0, 0.15)
	tw.tween_property(bubble, "position:y", bubble.position.y - 4.0, 0.15)


func _shake(c: Control, times: int, step: float) -> void:
	var tw: Tween = create_tween()
	for i: int in times:
		tw.tween_property(c, "rotation", 0.09 if i % 2 == 0 else -0.09, step)
	tw.tween_property(c, "rotation", 0.0, step)


## Yüz kızarması: resim kırmızımsı olur; back > 0 ise o kadar saniye sonra geri döner.
func _flush(c: Control, col: Color, back: float) -> void:
	var tw: Tween = create_tween()
	tw.tween_property(c, "modulate", col, 0.2)
	if back > 0.0:
		tw.tween_interval(back)
		tw.tween_property(c, "modulate", Color.WHITE, 0.4)


func _hop(c: Control) -> void:
	var y: float = c.position.y
	var tw: Tween = create_tween()
	for i: int in 2:
		tw.tween_property(c, "position:y", y - 14.0, 0.14).set_ease(Tween.EASE_OUT)
		tw.tween_property(c, "position:y", y, 0.14).set_ease(Tween.EASE_IN)


# --- el sıkışma: iki kol ortada buluşur -------------------------------------------------------------------------

func _draw_hands() -> void:
	var px: float = float(_cfg["portrait"])
	var mid: float = size.x * 0.5
	var table_y: float = size.y - 22.0
	# Aradaki masa ve üstünde sözleşme kâğıdı: sahne bir pazarlık masası gibi okunsun.
	_hands.draw_rect(Rect2(_us.position.x + px - 10.0, table_y, _them.position.x - _us.position.x - px + 20.0, 10.0), Color("b07a4f"))
	_hands.draw_rect(Rect2(_us.position.x + px - 10.0, table_y + 10.0, _them.position.x - _us.position.x - px + 20.0, 4.0),
		Color("8a5d3b"))
	var paper: Rect2 = Rect2(mid - 26.0, table_y - 6.0, 52.0, 8.0)
	_hands.draw_rect(paper, Color("fffaf0"))
	_hands.draw_rect(paper, Color(0, 0, 0, 0.2), false, 1.0)
	# Kollar masanın üstünden ortaya uzanır; dinlenirken eller kişinin önünde durur, anlaşınca ortada buluşur.
	var shake: float = sin(_sparkle * TAU * 2.0) * 5.0 if _grip > 0.95 else 0.0
	var hand_y: float = table_y - 16.0 + shake
	var left_from: Vector2 = Vector2(_us.position.x + px - 6.0, table_y - 4.0)
	var right_from: Vector2 = Vector2(_them.position.x + 6.0, table_y - 4.0)
	var reach: float = lerpf(0.2, 1.0, _grip)
	var lh: Vector2 = Vector2(lerpf(left_from.x + 22.0, mid - 9.0, reach), hand_y)
	var rh: Vector2 = Vector2(lerpf(right_from.x - 22.0, mid + 9.0, reach), hand_y)
	var skin: Color = Color("e8b98f")
	_arm(left_from, lh, CozyTheme.FOREST, skin, 1.0)
	_arm(right_from, rh, CozyTheme.TERRA, skin.darkened(0.12), -1.0)
	if _grip > 0.95:  # kenetlenmiş eller: üstte bizim başparmak
		_hands.draw_colored_polygon(_mitt(Vector2(mid, hand_y), 1.0), skin)
		_hands.draw_line(Vector2(mid - 4.0, hand_y - 9.0), Vector2(mid + 6.0, hand_y - 12.0), skin.darkened(0.2), 3.0, true)
	if _broken:  # kırık el sıkışma: ortada çarpı
		var cy: float = hand_y - 20.0
		_hands.draw_line(Vector2(mid - 10, cy - 10), Vector2(mid + 10, cy + 10), CozyTheme.NEGATIVE, 4.0)
		_hands.draw_line(Vector2(mid + 10, cy - 10), Vector2(mid - 10, cy + 10), CozyTheme.NEGATIVE, 4.0)
	if _sparkle > 0.0 and _sparkle < 1.0:
		for i: int in 8:
			var a: float = TAU * i / 8.0
			var r: float = lerpf(18.0, 50.0, _sparkle)
			var p: Vector2 = Vector2(mid, hand_y) + Vector2(cos(a), sin(a)) * r
			_hands.draw_circle(p, 4.5 * (1.0 - _sparkle), UiUtil.MUSTARD)


## Kol: yuvarlak kollu yen ve başparmaklı el. dir: 1 sağa uzanır, -1 sola.
func _arm(from: Vector2, hand: Vector2, sleeve: Color, skin: Color, dir: float) -> void:
	var cuff: Vector2 = hand - Vector2(dir * 12.0, 0.0)
	var elbow: Vector2 = from.lerp(cuff, 0.5) + Vector2(0.0, 8.0)
	_hands.draw_polyline(PackedVector2Array([from, elbow, cuff]), sleeve, 16.0, true)
	_hands.draw_circle(from, 8.0, sleeve)
	_hands.draw_rect(Rect2(cuff - Vector2(4.0, 9.0), Vector2(8.0, 18.0)), sleeve.lightened(0.25))
	_hands.draw_colored_polygon(_mitt(hand, dir), skin)
	_hands.draw_line(hand + Vector2(-dir * 2.0, -7.0), hand + Vector2(dir * 5.0, -13.0), skin, 5.0, true)  # başparmak


func _mitt(c: Vector2, dir: float) -> PackedVector2Array:
	var p: PackedVector2Array = PackedVector2Array()
	for i: int in 16:
		var a: float = TAU * i / 16.0
		p.append(c + Vector2(cos(a) * 11.0 * (1.15 if cos(a) * dir > 0.0 else 1.0), sin(a) * 8.0))
	return p
