class_name CountBadge
extends PanelContainer
## Sağ üst rozet (UI-2b, Cozy Refined): krem hap içinde solda renkli daire simge, sağda değer.
## Değer değişince eski sayıdan yenisine sayar ve daire bir kez "nabız" atar (art-direction 10).

const COUNT_SECONDS: float = 0.7
const CIRCLE: float = 34.0

var _label: Label
var _circle: PanelContainer
var _fmt: Callable
var _shown: float = NAN
var _target: float = NAN
var _tween: Tween


## fmt(değer) -> metin. circle_color: simge dairesi. width: en küçük genişlik.
func _init(icon_name: String, circle_color: Color, fmt: Callable, width: float = 160.0) -> void:
	_fmt = fmt
	theme_type_variation = "HudPill"
	custom_minimum_size.x = width
	mouse_filter = Control.MOUSE_FILTER_PASS
	var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	_circle = PanelContainer.new()
	_circle.add_theme_stylebox_override("panel", CozyTheme.box(circle_color, int(CIRCLE * 0.5), Color.TRANSPARENT, 0,
		false, Vector2.ZERO))
	_circle.custom_minimum_size = Vector2(CIRCLE, CIRCLE)
	_circle.pivot_offset = Vector2(CIRCLE, CIRCLE) * 0.5
	_circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ic: TextureRect = UiUtil.icon(icon_name, 22, CozyTheme.CREAM_LIGHT)
	ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	_circle.add_child(ic)
	row.add_child(_circle)
	_label = Label.new()
	_label.add_theme_font_override("font", CozyTheme.strong_font(800))
	_label.add_theme_font_size_override("font_size", 19)
	_label.add_theme_color_override("font_color", CozyTheme.TEXT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_label)


func label_node() -> Label:
	return _label


func value() -> float:
	return _target


## İlk çağrıda doğrudan yazar; sonra sayar ve nabız atar.
func set_value(v: float) -> void:
	if is_equal_approx(v, _target):
		return
	_target = v
	if is_nan(_shown) or not is_inside_tree():
		_show(v)
		return
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_show, _shown, v, COUNT_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var pulse: Tween = create_tween()
	pulse.tween_property(_circle, "scale", Vector2.ONE * 1.15, 0.1)
	pulse.tween_property(_circle, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)


func _show(v: float) -> void:
	_shown = v
	_label.text = _fmt.call(v)
