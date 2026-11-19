class_name OptionArtBrief
extends OptionArtMedia
## Kampanya kurulumunun hedef, kitle ve ton seçeneklerinin çizimleri (S10). Eskiden bu üçü açılır menüydü.
## Tasarım alanı 120x84 (OptionArt). Seçim paneli bu sınıfı kullanır; baskı ve medya çizimleri üst sınıflarda.


# --- hedef ------------------------------------------------------------------------------------------------------

func _d_objective(o: String) -> void:
	match o:
		"awareness":  # megafon ve ses dalgaları
			_poly([Vector2(30, 34), Vector2(58, 20), Vector2(58, 64), Vector2(30, 50)], TERRA)
			_box(Rect2(20, 34, 12, 16), MUSTARD)
			for i: int in 3:
				draw_arc(Vector2(62, 42), 12.0 + i * 9.0, -0.7, 0.7, 10, Color(INK, 0.6 - i * 0.15), 2.5)
		"launch":  # roket ve duman
			_poly([Vector2(60, 10), Vector2(72, 28), Vector2(72, 56), Vector2(48, 56), Vector2(48, 28)], PAPER)
			draw_polyline(PackedVector2Array([Vector2(60, 10), Vector2(72, 28), Vector2(72, 56), Vector2(48, 56), Vector2(48, 28),
				Vector2(60, 10)]), INK, 2.0)
			draw_circle(Vector2(60, 34), 6, SKY)
			_poly([Vector2(48, 44), Vector2(38, 60), Vector2(48, 56)], TERRA)
			_poly([Vector2(72, 44), Vector2(82, 60), Vector2(72, 56)], TERRA)
			_poly([Vector2(52, 58), Vector2(60, 76), Vector2(68, 58)], MUSTARD)
		"sales":  # yükselen sütunlar ve ok
			for i: int in 4:
				var h: float = 12.0 + i * 12.0
				_box(Rect2(26 + i * 18, 70 - h, 12, h), SAGE if i < 3 else FOREST, INK, 1.5)
			draw_polyline(PackedVector2Array([Vector2(24, 50), Vector2(48, 38), Vector2(66, 42), Vector2(94, 16)]), TERRA, 3.0)
			_poly([Vector2(94, 16), Vector2(84, 16), Vector2(94, 26)], TERRA)
		"rebrand":  # eski logo → yeni logo
			_box(Rect2(14, 26, 32, 32), Color("d9d2c3"), Color(INK, 0.5))
			draw_string(get_theme_default_font(), Vector2(14, 48), "A", HORIZONTAL_ALIGNMENT_CENTER, 32, 18, Color(INK, 0.5))
			draw_line(Vector2(52, 42), Vector2(68, 42), INK, 2.5)
			_poly([Vector2(68, 36), Vector2(76, 42), Vector2(68, 48)], INK)
			draw_circle(Vector2(94, 42), 17, TERRA)
			draw_string(get_theme_default_font(), Vector2(78, 49), "A", HORIZONTAL_ALIGNMENT_CENTER, 32, 20, PAPER)
		"engagement":  # konuşma balonları ve kalp
			_box(Rect2(16, 14, 50, 30), PAPER)
			_poly([Vector2(26, 44), Vector2(24, 54), Vector2(36, 44)], INK)
			_lines(Rect2(22, 20, 38, 18), 2)
			_box(Rect2(54, 38, 50, 28), Color(SAGE, 0.6))
			_poly([Vector2(92, 66), Vector2(96, 76), Vector2(84, 66)], INK)
			_heart(Vector2(79, 51), 8.0, TERRA)
		"csr":  # el içinde fidan
			draw_arc(Vector2(60, 58), 26, 0.15, PI - 0.15, 16, INK, 3.0)
			draw_line(Vector2(60, 58), Vector2(60, 30), FOREST, 3.0)
			_leaf(Vector2(60, 40), Vector2(-16, -10))
			_leaf(Vector2(60, 34), Vector2(14, -12))
			_poly([Vector2(36, 62), Vector2(84, 62), Vector2(78, 72), Vector2(42, 72)], Color("b07a4f"))
		_:
			_blob(Vector2(60, 42), 22, SAGE)


# --- kitle -------------------------------------------------------------------------------------------------------

func _d_audience(a: String) -> void:
	match a:
		"young":  # kaykay ve şapka
			_person(Vector2(60, 64), 46, TERRA)
			_poly([Vector2(48, 24), Vector2(72, 24), Vector2(76, 28), Vector2(48, 28)], FOREST)
			_box(Rect2(36, 66, 48, 5), MUSTARD)
			draw_circle(Vector2(44, 74), 3.5, INK)
			draw_circle(Vector2(76, 74), 3.5, INK)
		"adult":  # iki kişi, biri çantalı
			_person(Vector2(46, 72), 48, FOREST)
			_person(Vector2(76, 72), 42, SKY.darkened(0.2))
			_box(Rect2(84, 54, 14, 12), Color("b07a4f"))
		"mature":  # gözlüklü ve bastonlu
			_person(Vector2(56, 72), 46, Color("9c7b5b"))
			draw_arc(Vector2(51, 37), 4, 0, TAU, 10, INK, 1.5)
			draw_arc(Vector2(61, 37), 4, 0, TAU, 10, INK, 1.5)
			draw_line(Vector2(78, 40), Vector2(78, 74), INK, 3.0)
			draw_arc(Vector2(74, 40), 4, PI, TAU, 6, INK, 3.0)
		"b2b":  # iki bina ve tokalaşma çizgisi
			_box(Rect2(18, 20, 30, 52), Color("e6ddcc"))
			_box(Rect2(72, 30, 30, 42), Color("e6ddcc"))
			for i: int in 3:
				draw_rect(Rect2(24, 26 + i * 14, 8, 8), SKY)
				draw_rect(Rect2(34, 26 + i * 14, 8, 8), SKY)
				if i < 2:
					draw_rect(Rect2(78, 36 + i * 14, 8, 8), SKY)
					draw_rect(Rect2(88, 36 + i * 14, 8, 8), SKY)
			draw_line(Vector2(50, 50), Vector2(70, 50), TERRA, 4.0)
		_:
			_blob(Vector2(60, 42), 22, SAGE)


# --- ton ---------------------------------------------------------------------------------------------------------

func _d_tone(t: String) -> void:
	match t:
		"emotional":
			_heart(Vector2(60, 40), 20.0, TERRA)
			draw_circle(Vector2(84, 56), 3, SKY)
			_poly([Vector2(84, 48), Vector2(81, 55), Vector2(87, 55)], SKY)
		"humorous":  # gülen yüz
			draw_circle(Vector2(60, 42), 26, MUSTARD)
			draw_arc(Vector2(60, 42), 26, 0, TAU, 24, INK, 2.0)
			draw_arc(Vector2(51, 36), 4, PI, TAU, 6, INK, 2.5)
			draw_arc(Vector2(69, 36), 4, PI, TAU, 6, INK, 2.5)
			_poly([Vector2(46, 46), Vector2(74, 46), Vector2(70, 56), Vector2(60, 60), Vector2(50, 56)], INK)
		"informative":  # bilgi kartı ve ok işaretleri
			_box(Rect2(30, 12, 60, 60), PAPER)
			draw_circle(Vector2(60, 26), 6, SKY.darkened(0.2))
			draw_string(get_theme_default_font(), Vector2(54, 31), "i", HORIZONTAL_ALIGNMENT_CENTER, 12, 12, PAPER)
			_lines(Rect2(38, 38, 44, 28), 3)
		"bold":  # şimşek ve patlama
			_star(Vector2(60, 42), 32, Color(TERRA, 0.35))
			_poly([Vector2(64, 12), Vector2(46, 46), Vector2(58, 46), Vector2(52, 74), Vector2(76, 36), Vector2(63, 36)], TERRA)
		"luxury":  # elmas
			_poly([Vector2(40, 30), Vector2(80, 30), Vector2(92, 40), Vector2(60, 72), Vector2(28, 40)], Color("cfe6ef"))
			draw_polyline(PackedVector2Array([Vector2(40, 30), Vector2(80, 30), Vector2(92, 40), Vector2(60, 72), Vector2(28, 40),
				Vector2(40, 30)]), INK, 2.0)
			draw_line(Vector2(28, 40), Vector2(92, 40), INK, 1.5)
			draw_line(Vector2(50, 40), Vector2(60, 72), Color(INK, 0.5), 1.0)
			draw_line(Vector2(70, 40), Vector2(60, 72), Color(INK, 0.5), 1.0)
			_star(Vector2(88, 20), 7, MUSTARD)
		"nostalgic":  # eski fotoğraf
			_box(Rect2(30, 14, 60, 56), Color("f3e3c3"), Color("9c7b5b"))
			draw_rect(Rect2(36, 20, 48, 36), Color("c9a77c"))
			_person(Vector2(60, 56), 28, Color("8a6440"))
			draw_rect(Rect2(36, 20, 48, 36), Color(1, 0.9, 0.7, 0.25))
		_:
			_blob(Vector2(60, 42), 22, SAGE)


# --- yardımcılar ---------------------------------------------------------------------------------------------------

func _heart(c: Vector2, r: float, col: Color) -> void:
	draw_circle(c + Vector2(-r * 0.5, -r * 0.2), r * 0.55, col)
	draw_circle(c + Vector2(r * 0.5, -r * 0.2), r * 0.55, col)
	_poly([c + Vector2(-r * 1.02, 0.0), c + Vector2(r * 1.02, 0.0), c + Vector2(0.0, r * 1.1)], col)


func _leaf(base: Vector2, tip: Vector2) -> void:
	var side: Vector2 = Vector2(-tip.y, tip.x).normalized() * 6.0
	_poly([base, base + tip * 0.5 + side, base + tip, base + tip * 0.5 - side], SAGE.darkened(0.15))
