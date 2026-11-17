class_name TrailerOverlay
extends CanvasLayer
## Fragman katmanı (tanıtım videosu): sahne geçişleri (karartma), alt üçte birde kâğıt etiketli yazı kartı,
## açılış ve kapanış kartı (menü illüstrasyonu üstünde logo). Oyunun kendi görsel diliyle (MenuArt, CozyTheme).

const CARD_SIZE: int = 40
const CARD_LEFT: float = 96.0
const CARD_BOTTOM: float = 150.0
const CARD_SLIDE: float = 60.0

var cards_enabled: bool = true
var _fade: ColorRect
var _card: Control
var _title: Control


func _init() -> void:
	layer = 120
	_fade = ColorRect.new()
	_fade.color = Color(0.06, 0.1, 0.08, 1.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)


func _ready() -> void:
	add_child(_fade)


## Karartma: alpha 1 → 0 (açılış) ya da 0 → 1 (kapanış).
func fade(to_alpha: float, seconds: float) -> void:
	move_child(_fade, get_child_count() - 1)
	var t: Tween = create_tween()
	t.tween_property(_fade, "color:a", to_alpha, seconds).set_trans(Tween.TRANS_SINE)
	await t.finished


## Alt üçte bir yazı kartı: soldan kayarak gelir, `hold` saniye durur, kayarak gider.
func card(text: String, hold: float) -> void:
	if not cards_enabled:
		return
	if _card != null:
		_card.queue_free()
	var root: Control = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	move_child(root, maxi(0, _fade.get_index()))
	var tape: Control = MenuArt.tape(text, "", CARD_SIZE, -2.0)
	root.add_child(tape)
	_card = root
	await get_tree().process_frame
	var rect_size: Vector2 = tape.get_combined_minimum_size()
	var view: Vector2 = root.size
	var final: Vector2 = Vector2(CARD_LEFT, view.y - CARD_BOTTOM - rect_size.y)
	tape.position = final - Vector2(CARD_SLIDE, 0.0)
	tape.modulate.a = 0.0
	var t: Tween = create_tween().set_parallel(true)
	t.tween_property(tape, "position", final, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(tape, "modulate:a", 1.0, 0.35)
	t.chain().tween_interval(hold)
	t.chain().tween_property(tape, "modulate:a", 0.0, 0.35)
	t.chain().tween_callback(root.queue_free)


## Açılış/kapanış kartı: menü illüstrasyonu, ortada logo, altında etiketler (ör. alt başlık, "istek listene ekle").
func title_card(lines: Array[String]) -> void:
	clear_title()
	var root: Control = MenuArt.backdrop()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	move_child(root, maxi(0, _fade.get_index()))
	var side: CenterContainer = CenterContainer.new()
	side.anchor_left = 0.4 if MenuArt.texture() != null else 0.0
	side.anchor_right = 0.82 if MenuArt.texture() != null else 1.0
	side.anchor_bottom = 1.0
	root.add_child(side)
	var col: VBoxContainer = UiUtil.vbox(CozyTheme.SPACE_L)
	side.add_child(col)
	col.add_child(_logo())
	for i: int in lines.size():
		var tag: Control = MenuArt.tape(lines[i], "", 22 if i == 0 else 28, -3.0 if i == 0 else 2.0)
		(tag as HBoxContainer).alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_child(tag)
	_title = root


func clear_title() -> void:
	if _title != null:
		_title.queue_free()
		_title = null


## Menüdeki logo: iki satır eğik yazı ve turuncu megafon (main_menu._logo ile aynı düzen).
static func _logo() -> Control:
	var words: PackedStringArray = TranslationServer.translate("GAME_TITLE").split(" ", false, 1)
	var box: VBoxContainer = UiUtil.vbox(-22)
	var top: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_child(MenuArt.logo_label(words[0], 96))
	top.add_child(UiUtil.icon("speakerphone", 72, CozyTheme.ACCENT))
	box.add_child(top)
	if words.size() > 1:
		var second: Label = MenuArt.logo_label(words[1], 96)
		second.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(second)
	var center: CenterContainer = CenterContainer.new()
	center.add_child(MenuArt.tilted(box, -4.0))
	return center
