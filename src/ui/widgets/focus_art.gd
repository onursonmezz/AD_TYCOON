class_name FocusArt
extends OptionArt
## Görev çizimleri (S12, Orgo'nun faz ekranı taslağı): dokuz odak alanının her biri kâğıt üstünde küçük bir çizim.
## Tasarım alanı 120x84 (OptionArt). kind = "focus", id = odak alanı kimliği.

const NOTE: Color = Color("f7e3c8")


func _init(area: String = "") -> void:
	super._init("focus", area)


func _d_focus(area: String) -> void:
	match area:
		"research":  # sütun grafik ve büyüteç
			_paper(Rect2(22, 12, 64, 58))
			for i: int in 3:
				draw_rect(Rect2(32 + i * 14, 52 - i * 10, 10, 12 + i * 10), Color(SAGE, 0.9))
			draw_arc(Vector2(78, 46), 14, 0, TAU, 24, INK, 3.0)
			draw_circle(Vector2(78, 46), 12, Color(SKY, 0.25))
			draw_line(Vector2(88, 56), Vector2(100, 68), INK, 5.0)
		"insight":  # parlayan ampul
			draw_circle(Vector2(60, 36), 18, Color(MUSTARD, 0.95))
			draw_arc(Vector2(60, 36), 18, 0, TAU, 24, INK, 2.0)
			_box(Rect2(52, 54, 16, 10), Color("c9c2b4"))
			draw_line(Vector2(52, 59), Vector2(68, 59), INK, 1.5)
			for a: float in [-2.4, -1.57, -0.74, -3.2, 0.1]:
				var d: Vector2 = Vector2(cos(a), sin(a))
				draw_line(Vector2(60, 36) + d * 24.0, Vector2(60, 36) + d * 32.0, TERRA, 3.0)
		"positioning":  # hedef tahtası ve ok
			for r: int in [26, 18, 10]:
				draw_circle(Vector2(56, 44), r, TERRA if r != 18 else PAPER)
			draw_arc(Vector2(56, 44), 26, 0, TAU, 28, INK, 2.0)
			draw_line(Vector2(96, 18), Vector2(58, 43), INK, 3.0)
			_poly([Vector2(96, 18), Vector2(102, 16), Vector2(100, 24)], FOREST)
		"concept":  # spiralli defter ve ampul
			_paper(Rect2(26, 14, 60, 58))
			for i: int in 6:
				draw_arc(Vector2(32 + i * 10, 14), 3, PI, TAU, 6, INK, 1.5)
			draw_circle(Vector2(56, 40), 11, Color(MUSTARD, 0.9))
			draw_arc(Vector2(56, 40), 11, 0, TAU, 20, TERRA, 2.0)
			draw_rect(Rect2(52, 51, 8, 6), Color(INK, 0.6))
			for a: float in [-2.6, -1.57, -0.5]:
				var d: Vector2 = Vector2(cos(a), sin(a))
				draw_line(Vector2(56, 40) + d * 15.0, Vector2(56, 40) + d * 20.0, TERRA, 2.0)
		"copy":  # yazılı kâğıt ve kalem
			_paper(Rect2(20, 16, 62, 52))
			for i: int in 4:
				draw_polyline(PackedVector2Array([Vector2(28, 28 + i * 9), Vector2(40, 25 + i * 9), Vector2(52, 29 + i * 9),
					Vector2(64, 26 + i * 9), Vector2(72 - i * 6, 28 + i * 9)]), Color(TERRA, 0.8), 1.5)
			_poly([Vector2(94, 16), Vector2(102, 22), Vector2(78, 62), Vector2(70, 56)], TERRA)
			_poly([Vector2(70, 56), Vector2(78, 62), Vector2(68, 70)], Color("f3d2a8"))
		"visual":  # bantlı resim: dağ ve güneş
			_box(Rect2(20, 18, 72, 52), PAPER)
			_poly([Vector2(24, 66), Vector2(46, 38), Vector2(62, 56), Vector2(72, 46), Vector2(88, 66)], TERRA)
			_poly([Vector2(44, 66), Vector2(62, 52), Vector2(88, 66)], FOREST)
			draw_circle(Vector2(76, 30), 7, MUSTARD)
			_poly([Vector2(30, 12), Vector2(50, 12), Vector2(50, 22), Vector2(30, 22)], Color(MUSTARD, 0.7))
		"production":  # klaket
			_box(Rect2(26, 34, 68, 36), Color("4a3b2c"), INK)
			_poly([Vector2(26, 22), Vector2(92, 14), Vector2(94, 26), Vector2(28, 34)], PAPER)
			for i: int in 4:
				_poly([Vector2(34 + i * 16, 21 - i * 2), Vector2(42 + i * 16, 20 - i * 2), Vector2(44 + i * 16, 31 - i * 2),
					Vector2(36 + i * 16, 32 - i * 2)], INK)
			_lines(Rect2(32, 42, 54, 22), 2, Color(PAPER, 0.6))
		"media_planning":  # takvim ve megafon
			_paper(Rect2(20, 18, 56, 50))
			draw_rect(Rect2(20, 18, 56, 10), TERRA)
			for r: int in 3:
				for c: int in 4:
					draw_rect(Rect2(25 + c * 12, 33 + r * 11, 8, 7), Color(SAGE, 0.8 if (r + c) % 3 else 0.35))
			_poly([Vector2(80, 44), Vector2(98, 34), Vector2(98, 62), Vector2(80, 52)], TERRA)
			_box(Rect2(74, 43, 8, 10), MUSTARD)
		"measurement":  # yükselen çizgi grafik
			_paper(Rect2(20, 14, 72, 56))
			draw_line(Vector2(28, 62), Vector2(86, 62), INK, 2.0)
			draw_line(Vector2(28, 62), Vector2(28, 20), INK, 2.0)
			draw_polyline(PackedVector2Array([Vector2(30, 56), Vector2(44, 48), Vector2(56, 52), Vector2(70, 34), Vector2(84, 24)]),
				FOREST, 3.0)
			for p: Vector2 in [Vector2(44, 48), Vector2(70, 34), Vector2(84, 24)]:
				draw_circle(p, 3, TERRA)
		_:
			_blob(Vector2(60, 42), 22, SAGE)


## Hafif yamuk, gölgeli kâğıt (taslaktaki defter sayfası hissi).
func _paper(r: Rect2) -> void:
	draw_rect(Rect2(r.position + Vector2(3, 3), r.size), Color(INK, 0.15))
	_box(r, NOTE, Color(INK, 0.6), 1.5)
