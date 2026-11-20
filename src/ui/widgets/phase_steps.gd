class_name PhaseSteps
extends Control
## Faz adımları şeridi (S12, taslak): üç ok biçimli parça. Geçen faz açık yeşil ve ✓, şimdiki faz koyu yeşil,
## sonraki faz krem. Kodla çizilir; yükseklik sabit, genişlik kaba yayılır.

const HEIGHT: float = 34.0
const TIP: float = 14.0

var current: int = 0
var names: Array[String] = []


func _init(phase: int, phase_names: Array[String]) -> void:
	current = phase
	names = phase_names
	custom_minimum_size = Vector2(0.0, HEIGHT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var n: int = names.size()
	if n == 0:
		return
	var w: float = (size.x + TIP * float(n - 1)) / float(n)
	var font: Font = CozyTheme.title_font(700)
	for i: int in n:
		var x: float = float(i) * (w - TIP)
		var first: bool = i == 0
		var last: bool = i == n - 1
		var pts: PackedVector2Array = PackedVector2Array([
			Vector2(x, 0.0), Vector2(x + w - (0.0 if last else TIP), 0.0), Vector2(x + w, HEIGHT * 0.5),
			Vector2(x + w - (0.0 if last else TIP), HEIGHT), Vector2(x, HEIGHT),
			Vector2(x + (0.0 if first else TIP), HEIGHT * 0.5)])
		if last:
			pts = PackedVector2Array([Vector2(x, 0.0), Vector2(x + w, 0.0), Vector2(x + w, HEIGHT), Vector2(x, HEIGHT),
				Vector2(x + (0.0 if first else TIP), HEIGHT * 0.5)])
		var fill: Color = CozyTheme.FOREST if i == current \
			else (CozyTheme.SAGE_SOFT if i < current else CozyTheme.CREAM.darkened(0.06))
		var ink: Color = CozyTheme.CREAM_LIGHT if i == current else (CozyTheme.FOREST if i < current else CozyTheme.TEXT)
		draw_colored_polygon(pts, fill)
		var text: String = ("✓  " if i < current else "") + names[i]
		var px: int = 15
		var tw: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
		var cx: float = x + w * 0.5 + (TIP * 0.25 if not first else -TIP * 0.25)
		draw_string(font, Vector2(cx - tw * 0.5, HEIGHT * 0.5 + px * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, ink)
