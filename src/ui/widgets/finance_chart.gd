class_name FinanceChart
extends Control
## Finans ekranındaki küçük sütun grafik (UI-2d): son aylarin geliri, eskiden yeniye; son ay koyu yeşil.
## Değer yoksa ya da hepsi 0 ise ince bir taban çizgisi çizer.

var values: Array[float] = []


func _draw() -> void:
	var base_y: float = size.y - 2.0
	draw_line(Vector2(0.0, base_y), Vector2(size.x, base_y), CozyTheme.BORDER, 1.0)
	if values.is_empty():
		return
	var top: float = 0.0
	for v: float in values:
		top = maxf(top, v)
	if top <= 0.0:
		return
	var n: int = values.size()
	var gap: float = size.x * 0.06
	var w: float = (size.x - gap * float(n + 1)) / float(n)
	for i: int in n:
		var h: float = maxf(2.0, (size.y - 8.0) * values[i] / top)
		var rect: Rect2 = Rect2(gap + float(i) * (w + gap), base_y - h, w, h)
		var col: Color = CozyTheme.FOREST_LIGHT if i == n - 1 else CozyTheme.SAGE
		draw_style_box(CozyTheme.box(col, 3, Color.TRANSPARENT, 0, false, Vector2.ZERO), rect)
