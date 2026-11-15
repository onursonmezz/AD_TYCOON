class_name FinanceChart
extends Control
## Finans ekranındaki küçük sütun grafik (UI-2d): son ayların geliri, eskiden yeniye; son ay koyu yeşil.
## UI-4: altta ay kısaltmaları; gelir yoksa ortada "Henüz gelir yok" (boş kutu bozuk görünüyordu).

const LABEL_H: float = 16.0

var values: Array[float] = []
var months: Array[String] = []  # values ile aynı sırada ay kısaltmaları
var empty_text: String = ""


func _draw() -> void:
	var font: Font = get_theme_default_font()
	var base_y: float = size.y - 2.0 - (LABEL_H if not months.is_empty() else 0.0)
	draw_line(Vector2(0.0, base_y), Vector2(size.x, base_y), CozyTheme.BORDER, 1.0)
	var n: int = maxi(values.size(), months.size())
	var gap: float = size.x * 0.06
	var w: float = (size.x - gap * float(n + 1)) / float(maxi(1, n))
	for i: int in months.size():
		var x: float = gap + float(i) * (w + gap)
		draw_string(font, Vector2(x, size.y - 3.0), months[i], HORIZONTAL_ALIGNMENT_CENTER, w, 11, CozyTheme.MUTED)
	var top: float = 0.0
	for v: float in values:
		top = maxf(top, v)
	if top <= 0.0:
		if not empty_text.is_empty():
			draw_string(font, Vector2(0.0, base_y * 0.5 + 6.0), empty_text, HORIZONTAL_ALIGNMENT_CENTER, size.x, 13,
				CozyTheme.MUTED)
		return
	for i: int in values.size():
		var h: float = maxf(2.0, (base_y - 6.0) * values[i] / top)
		var rect: Rect2 = Rect2(gap + float(i) * (w + gap), base_y - h, w, h)
		var col: Color = CozyTheme.FOREST_LIGHT if i == values.size() - 1 else CozyTheme.SAGE
		draw_style_box(CozyTheme.box(col, 3, Color.TRANSPARENT, 0, false, Vector2.ZERO), rect)
