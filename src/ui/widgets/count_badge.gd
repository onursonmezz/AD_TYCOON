class_name CountBadge
extends Control
## Sağ üst rozet (G2, art-direction 8): solda büyük daire simge, sağa uzanan hap ve içinde değer.
## Değer değişince eski sayıdan yenisine sayar ve daire bir kez "nabız" atar (art-direction 10).

const COUNT_SECONDS: float = 0.7
const CIRCLE: float = 58.0

var _label: Label
var _circle: PanelContainer
var _fmt: Callable
var _shown: float = NAN
var _target: float = NAN
var _tween: Tween


## fmt(değer) -> metin. circle_color: daire; pill_color: hap.
func _init(icon_name: String, circle_color: Color, pill_color: Color, fmt: Callable, width: float = 200.0) -> void:
	_fmt = fmt
	custom_minimum_size = Vector2(width, CIRCLE)
	mouse_filter = Control.MOUSE_FILTER_PASS
	var pill: PanelContainer = PanelContainer.new()
	pill.add_theme_stylebox_override("panel", UiTheme.box(pill_color, 22, 0, Color.TRANSPARENT, Vector4(CIRCLE * 0.6, 4, 18, 4)))
	pill.position = Vector2(CIRCLE * 0.45, 9.0)
	pill.size = Vector2(width - CIRCLE * 0.45, CIRCLE - 18.0)
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pill)
	_label = Label.new()
	_label.add_theme_font_override("font", UiUtil.head_font())
	_label.add_theme_font_size_override("font_size", 24)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.add_theme_color_override("font_outline_color", pill_color.darkened(0.35))
	_label.add_theme_constant_override("outline_size", 6)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pill.add_child(_label)
	_circle = PanelContainer.new()
	_circle.add_theme_stylebox_override("panel", UiTheme.box(circle_color, int(CIRCLE * 0.5), 4, Color.WHITE, Vector4.ZERO))
	_circle.custom_minimum_size = Vector2(CIRCLE, CIRCLE)
	_circle.size = Vector2(CIRCLE, CIRCLE)
	_circle.pivot_offset = Vector2(CIRCLE, CIRCLE) * 0.5
	_circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ic: TextureRect = UiUtil.icon(icon_name, 34)
	ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	_circle.add_child(ic)
	add_child(_circle)


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
	pulse.tween_property(_circle, "scale", Vector2.ONE * 1.12, 0.1)
	pulse.tween_property(_circle, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)


func _show(v: float) -> void:
	_shown = v
	_label.text = _fmt.call(v)
