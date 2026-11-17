class_name PhaseTracker
extends Control
## Üç basamaklı faz şeridi (CP-2): her basamak yuvarlak bir rozet (biten: yeşil ve işaretli, şimdiki: kiremit halka,
## gelecek: soluk), aralarında çizgi; şimdiki basamağa giden çizgi fazın ilerlemesiyle dolar. Altta fazın kısa adı.

const HEIGHT: float = 56.0
const DOT: float = 30.0
const LINE: float = 5.0
const NAMES: Array[String] = ["UI_STEP_STRATEGY", "UI_STEP_CREATIVE", "UI_STEP_PRODUCTION"]
const ICONS: Array[String] = ["stat-strategy", "stat-creative", "stat-technical"]

var _phase: int = 0
var _progress: float = 0.0
var _days: int = -1
var _icons: Array[Texture2D] = []


func _init() -> void:
	custom_minimum_size = Vector2(0, HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for n: String in ICONS:
		_icons.append(UiUtil.icon_texture(n, 18))


## days: içinde bulunulan fazın kalan günü; şimdiki basamağın adının yanında yazılır.
func set_state(phase: int, progress: float, days: int = -1) -> void:
	if phase == _phase and absf(progress - _progress) < 0.002 and days == _days:
		return
	_phase = phase
	_days = days
	_progress = clampf(progress, 0.0, 1.0)
	queue_redraw()


func _centers() -> Array[Vector2]:
	var out: Array[Vector2] = []
	var margin: float = size.x * 0.12
	for i: int in 3:
		out.append(Vector2(margin + (size.x - 2.0 * margin) * i / 2.0, DOT * 0.5 + 2.0))
	return out


func _draw() -> void:
	var c: Array[Vector2] = _centers()
	var font: Font = get_theme_default_font()
	# Çizgiler: biten aralık yeşil, şimdiki fazdan sonrakine giden aralık ilerleme kadar dolu.
	for i: int in 2:
		var a: Vector2 = c[i] + Vector2(DOT * 0.5 + 4, 0)
		var b: Vector2 = c[i + 1] - Vector2(DOT * 0.5 + 4, 0)
		draw_line(a, b, CozyTheme.BORDER, LINE, true)
		var fill: float = 1.0 if i < _phase else (_progress if i == _phase else 0.0)
		if fill > 0.0:
			draw_line(a, a.lerp(b, fill), CozyTheme.FOREST_LIGHT, LINE, true)
	for i: int in 3:
		var done: bool = i < _phase
		var now: bool = i == _phase
		var fill_col: Color = CozyTheme.FOREST_LIGHT if done else (CozyTheme.TERRA if now else CozyTheme.CREAM)
		draw_circle(c[i], DOT * 0.5 + (3.0 if now else 0.0), Color(CozyTheme.TERRA, 0.25) if now else Color(0, 0, 0, 0))
		draw_circle(c[i], DOT * 0.5, fill_col)
		if not done and not now:
			draw_arc(c[i], DOT * 0.5, 0.0, TAU, 32, CozyTheme.BORDER, 2.0, true)
		var ic: Texture2D = UiUtil.icon_texture("check", 18) if done else _icons[i]
		var tint: Color = CozyTheme.CREAM_LIGHT if (done or now) else CozyTheme.MUTED
		draw_texture_rect(ic, Rect2(c[i] - Vector2(9, 9), Vector2(18, 18)), false, tint)
		var col: Color = CozyTheme.FOREST if now else (CozyTheme.TEXT if done else CozyTheme.MUTED)
		var name: String = tr(NAMES[i])
		if now and _days >= 0:
			name = tr("UI_STEP_DAYS") % [name, _days]
		draw_string(font, Vector2(c[i].x - 90, HEIGHT - 4), name, HORIZONTAL_ALIGNMENT_CENTER, 180, 13, col)
