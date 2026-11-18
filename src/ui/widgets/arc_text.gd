class_name ArcText
extends Control
## Bir yay boyunca dizilmiş yazı (tören kurdelesi): harfler ortası yukarıda olan bir çemberin üstüne tek tek
## dizilir ve her biri yayın o noktasındaki eğime göre döner. Yazı bu Control'ün ortasına (center) oturur.

var text: String = ""
var font: Font
var font_size: int = 30
var color: Color = Color.WHITE
var outline_color: Color = Color(0, 0, 0, 0.5)
var outline: int = 3
## Harfin altına düşen yumuşak gölge (kurdelenin üstünde yazı kabarık dursun).
var shadow_color: Color = Color(0, 0, 0, 0.3)
var shadow_offset: Vector2 = Vector2(0, 2)
## Yayın yarıçapı (piksel); büyüdükçe yazı düzleşir. 0 veya altı: düz yazı.
var radius: float = 600.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if text.is_empty() or font == null:
		return
	var widths: Array[float] = []
	var total: float = 0.0
	for ch: String in text:
		var w: float = font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		widths.append(w)
		total += w
	var mid: Vector2 = size * 0.5
	# Taban çizgisini harf yüksekliğinin ortasına göre ayarla: yazı dikeyde de ortalı dursun.
	var lift: float = (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
	for pass_i: int in 3:  # gölge, kontur, harf (kontur komşu harfi örtmesin)
		var x: float = -total * 0.5
		for i: int in text.length():
			var cx: float = x + widths[i] * 0.5
			var ang: float = cx / radius if radius > 0.0 else 0.0
			var drop: float = radius - radius * cos(ang) if radius > 0.0 else 0.0
			var px: float = radius * sin(ang) if radius > 0.0 else cx
			draw_set_transform(mid + Vector2(px, drop), ang)
			var at: Vector2 = Vector2(-widths[i] * 0.5, lift)
			if pass_i == 0:
				draw_string_outline(font, at + shadow_offset, text[i], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline + 2,
					shadow_color)
			elif pass_i == 1:
				draw_string_outline(font, at, text[i], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline, outline_color)
			else:
				draw_string(font, at, text[i], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
			x += widths[i]
	draw_set_transform(Vector2.ZERO)
