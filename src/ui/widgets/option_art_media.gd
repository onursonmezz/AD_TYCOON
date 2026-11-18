class_name OptionArtMedia
extends OptionArt
## Medya seçeneklerinin çizimleri (S2): billboard lokasyonu ve süresi, TV kuşağı ve spot süresi, dijital teklif ve
## hedefleme, gerilla fikirleri, etkinlik mekânı, catering, davetliler, influencer. Tasarım alanı 120x84.


# --- açık hava: lokasyon paketi haritada yol yoğunluğu, süre takvimde --------------------------------------------

func _d_ooh_location(l: String) -> void:
	_box(Rect2(14, 8, 92, 66), Color("eef2e4"), Color(INK, 0.5))
	match l:
		"a":  # ana arterler: kalın kesişen yollar, çok pano
			draw_line(Vector2(14, 40), Vector2(106, 40), Color("9aa0a6"), 10.0)
			draw_line(Vector2(60, 8), Vector2(60, 74), Color("9aa0a6"), 10.0)
			for p: Vector2 in [Vector2(30, 28), Vector2(86, 28), Vector2(36, 58), Vector2(84, 56), Vector2(72, 18)]:
				draw_rect(Rect2(p - Vector2(6, 4), Vector2(12, 8)), TERRA)
		"b":  # semt: ince ızgara sokaklar
			for i: int in 3:
				draw_line(Vector2(14, 22 + i * 20), Vector2(106, 22 + i * 20), Color("c9ccce"), 4.0)
				draw_line(Vector2(36 + i * 24, 8), Vector2(36 + i * 24, 74), Color("c9ccce"), 4.0)
			for p: Vector2 in [Vector2(48, 32), Vector2(72, 52)]:
				draw_rect(Rect2(p - Vector2(6, 4), Vector2(12, 8)), TERRA)
		_:  # çevre yolu: şehrin dışında halka
			draw_arc(Vector2(60, 41), 26, 0, TAU, 32, Color("9aa0a6"), 6.0)
			draw_rect(Rect2(52, 34, 16, 14), Color(INK, 0.25))
			draw_rect(Rect2(Vector2(90, 58) - Vector2(6, 4), Vector2(12, 8)), TERRA)


func _d_ooh_weeks(w: String) -> void:
	_box(Rect2(24, 12, 72, 60), PAPER)
	draw_rect(Rect2(24, 12, 72, 12), TERRA)
	var n: int = int(w)
	for i: int in 4:
		var r: Rect2 = Rect2(30 + i * 16, 34, 12, 30)
		draw_rect(r, FOREST if i < n else Color(INK, 0.12))


# --- yayın: kuşak güneşin/ayın yeriyle, spot süresi kronometrede ------------------------------------------------

func _d_broadcast_daypart(d: String) -> void:
	var sky: Color = {"morning": Color("fde2c4"), "day": Color("d7ecf7"), "prime": Color("3b3f6b"), "night": Color("1f2340")}.get(d, SKY)
	_box(Rect2(14, 8, 92, 66), sky, Color(INK, 0.5))
	draw_rect(Rect2(14, 60, 92, 14), Color("8fae8b"))
	match d:
		"morning":
			draw_circle(Vector2(36, 60), 14, MUSTARD)
		"day":
			draw_circle(Vector2(60, 26), 13, MUSTARD)
		"prime":  # akşam: evde televizyon başında
			_box(Rect2(44, 28, 32, 24), Color("222222"), Color("dddddd"))
			_star(Vector2(60, 40), 8, MUSTARD)
		_:
			draw_circle(Vector2(82, 24), 11, Color("f4f1de"))
			draw_circle(Vector2(87, 20), 10, sky)
			for p: Vector2 in [Vector2(30, 20), Vector2(48, 32), Vector2(64, 16)]:
				draw_circle(p, 1.8, Color.WHITE)


func _d_broadcast_spot(sec: String) -> void:
	var c: Vector2 = Vector2(60, 46)
	draw_circle(c, 28, PAPER)
	var frac: float = float(sec) / 60.0
	var pie: PackedVector2Array = PackedVector2Array([c])
	for i: int in 25:
		var a: float = -PI * 0.5 + TAU * frac * i / 24.0
		pie.append(c + Vector2(cos(a), sin(a)) * 26)
	draw_colored_polygon(pie, Color(TERRA, 0.8))
	draw_arc(c, 28, 0, TAU, 32, INK, 2.5)
	draw_rect(Rect2(55, 10, 10, 8), INK)
	draw_circle(c, 13, PAPER)  # sayı dilimin üstünde okunsun
	draw_string(get_theme_default_font(), Vector2(30, 52), sec, HORIZONTAL_ALIGNMENT_CENTER, 60, 15, INK)


# --- dijital ---------------------------------------------------------------------------------------------------

func _d_digital_bid(b: String) -> void:
	_box(Rect2(20, 10, 80, 54), PAPER)
	draw_rect(Rect2(20, 10, 80, 10), Color(SKY, 0.8))
	match b:
		"cpm":  # göz: gösterim
			draw_colored_polygon(_eye(Vector2(60, 40)), Color.WHITE)
			draw_polyline(_eye(Vector2(60, 40)), INK, 2.0)
			draw_circle(Vector2(60, 40), 7, FOREST)
		"cpc":  # tıklayan imleç
			_box(Rect2(36, 30, 48, 16), Color(TERRA, 0.8), INK, 1.5)
			_poly([Vector2(66, 38), Vector2(66, 62), Vector2(72, 56), Vector2(77, 66), Vector2(81, 64), Vector2(76, 54), Vector2(84, 54)], INK)
		_:  # sepet: satış
			_poly([Vector2(40, 30), Vector2(84, 30), Vector2(78, 50), Vector2(46, 50)], Color(TERRA, 0.85))
			draw_line(Vector2(32, 26), Vector2(40, 30), INK, 2.5)
			draw_circle(Vector2(50, 56), 4, INK)
			draw_circle(Vector2(74, 56), 4, INK)
	draw_string(get_theme_default_font(), Vector2(20, 80), b.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 80, 12, INK)


func _eye(c: Vector2) -> PackedVector2Array:
	var p: PackedVector2Array = PackedVector2Array()
	for i: int in 25:
		var t: float = TAU * i / 24.0
		p.append(c + Vector2(cos(t) * 20, sin(t) * 11 * absf(cos(t * 0.5)) * 1.3))
	return p


func _d_digital_targeting(t: String) -> void:
	var c: Vector2 = Vector2(78, 42)
	for i: int in 3:
		draw_circle(c, 26 - i * 8, [Color(TERRA, 0.25), Color(TERRA, 0.5), TERRA][i])
	var spread: float = {"broad": 0.75, "balanced": 0.4, "narrow": 0.12}.get(t, 0.4)
	_poly([Vector2(16, 42), c + Vector2(-8, -34 * spread * 1.6), c + Vector2(-8, 34 * spread * 1.6)], Color(SKY, 0.55))
	draw_circle(Vector2(16, 42), 5, INK)


# --- gerilla ---------------------------------------------------------------------------------------------------

func _d_guerrilla_card_footprints() -> void:
	draw_rect(Rect2(10, 10, 100, 64), Color("d9d4cc"))
	for i: int in 3:
		var c: Vector2 = Vector2(26 + i * 34, 60 - i * 18)
		draw_colored_polygon(_ellipse(c, 9, 14, 0.3), TERRA)
		for k: int in 4:
			draw_circle(c + Vector2(-6 + k * 4, -17), 2.6, TERRA)


func _ellipse(c: Vector2, rx: float, ry: float, rot: float) -> PackedVector2Array:
	var p: PackedVector2Array = PackedVector2Array()
	for i: int in 20:
		var a: float = TAU * i / 20.0
		p.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot))
	return p


func _d_guerrilla_card_street_art() -> void:
	draw_rect(Rect2(10, 10, 100, 64), Color("d9d4cc"))
	_poly([Vector2(30, 34), Vector2(90, 34), Vector2(100, 62), Vector2(20, 62)], Color("3a2f28"))  # 3D çukur
	_poly([Vector2(30, 34), Vector2(90, 34), Vector2(84, 42), Vector2(36, 42)], Color("6b5a4c"))
	_person(Vector2(96, 30), 22, INK)


func _d_guerrilla_card_flash_mob() -> void:
	draw_rect(Rect2(10, 56, 100, 18), Color("d9d4cc"))
	for i: int in 7:
		var x: float = 18 + i * 14
		_person(Vector2(x, 58 - (i % 2) * 4), 26, [TERRA, FOREST, MUSTARD, SKY][i % 4])
	for i: int in 2:  # nota
		var n: Vector2 = Vector2(34 + i * 50, 20)
		draw_circle(n, 4, INK)
		draw_line(n + Vector2(3.5, 0), n + Vector2(3.5, -14), INK, 2.0)
		draw_line(n + Vector2(3.5, -14), n + Vector2(10, -10), INK, 2.0)


func _d_guerrilla_card_bus_stops() -> void:
	draw_rect(Rect2(10, 66, 100, 8), Color("9aa0a6"))
	_box(Rect2(30, 18, 60, 46), Color(SKY, 0.35))
	draw_rect(Rect2(30, 14, 60, 6), FOREST)
	_box(Rect2(40, 26, 26, 34), Color(TERRA, 0.75), INK, 1.5)
	draw_line(Vector2(100, 66), Vector2(100, 20), INK, 2.0)
	draw_circle(Vector2(100, 18), 7, MUSTARD)


func _d_guerrilla_card_fake_queue() -> void:
	_box(Rect2(84, 18, 26, 50), Color("b07a4f"))
	for i: int in 5:
		_person(Vector2(20 + i * 13, 68), 24, [INK, TERRA, FOREST, SKY, MUSTARD][i])
	draw_string(get_theme_default_font(), Vector2(84, 14), "!", HORIZONTAL_ALIGNMENT_CENTER, 26, 14, TERRA)


# --- etkinlik --------------------------------------------------------------------------------------------------

func _d_event_venue(v: String) -> void:
	match v:
		"hall":
			_box(Rect2(20, 14, 80, 56), Color("f3eadb"))
			for i: int in 3:
				for k: int in 4:
					draw_rect(Rect2(32 + k * 16, 40 + i * 9, 8, 5), Color(INK, 0.55))
			draw_rect(Rect2(36, 20, 48, 10), TERRA)
		"hotel":
			_box(Rect2(14, 10, 92, 62), Color("efe1c6"))
			draw_line(Vector2(60, 10), Vector2(60, 22), INK, 2.0)
			for i: int in 5:  # avize
				draw_circle(Vector2(44 + i * 8, 28 + (2 if i % 2 else 0)), 3.5, MUSTARD)
			draw_arc(Vector2(60, 24), 18, 0.2, PI - 0.2, 12, MUSTARD, 2.0)
			draw_rect(Rect2(14, 58, 92, 14), Color(TERRA, 0.6))
		_:
			draw_rect(Rect2(10, 10, 100, 64), Color("d7ecf7"))
			draw_rect(Rect2(10, 58, 100, 16), Color("8fae8b"))
			_poly([Vector2(36, 58), Vector2(60, 26), Vector2(84, 58)], PAPER)
			draw_polyline(PackedVector2Array([Vector2(36, 58), Vector2(60, 26), Vector2(84, 58)]), TERRA, 3.0)
			draw_circle(Vector2(20, 50), 9, FOREST)
			draw_circle(Vector2(100, 48), 10, FOREST)


func _d_event_catering(c: String) -> void:
	draw_colored_polygon(_ellipse(Vector2(56, 64), 44, 11, 0.0), Color("e8e3d9"))
	if c == "premium":  # gümüş servis kapağı ve kadeh
		draw_colored_polygon(_dome(Vector2(52, 60), 30), Color("c9ccce"))
		draw_polyline(_dome(Vector2(52, 60), 30), INK, 2.0)
		draw_circle(Vector2(52, 26), 4, INK)
		_poly([Vector2(90, 22), Vector2(106, 22), Vector2(98, 40)], Color(SKY, 0.6))
		draw_line(Vector2(98, 40), Vector2(98, 60), INK, 2.0)
		draw_line(Vector2(92, 60), Vector2(104, 60), INK, 2.0)
	else:  # iki dilim sandviç
		for i: int in 2:
			var x: float = 26.0 + i * 36.0
			_poly([Vector2(x, 60), Vector2(x + 30, 60), Vector2(x + 26, 40), Vector2(x + 4, 40)], Color("e7c38f"))
			draw_rect(Rect2(x + 4, 47, 22, 4), SAGE)
			draw_rect(Rect2(x + 3, 52, 24, 4), TERRA)
			draw_polyline(PackedVector2Array([Vector2(x, 60), Vector2(x + 30, 60), Vector2(x + 26, 40), Vector2(x + 4, 40),
				Vector2(x, 60)]), INK, 1.5)


func _dome(c: Vector2, r: float) -> PackedVector2Array:
	var p: PackedVector2Array = PackedVector2Array()
	for i: int in 21:
		var a: float = PI + PI * i / 20.0
		p.append(c + Vector2(cos(a) * r, sin(a) * r))
	return p


func _d_event_guests(g: String) -> void:
	for i: int in 4:
		_person(Vector2(22 + i * 16, 70), 28, [INK, TERRA, FOREST, SKY][i])
	if g != "public":  # basın: flaşlı kamera
		_box(Rect2(78, 30, 30, 20), Color("444444"), INK, 1.5)
		draw_circle(Vector2(93, 40), 6, Color("bbbbbb"))
		_star(Vector2(104, 22), 9, MUSTARD)
	if g == "press_influencers":
		_box(Rect2(86, 56, 16, 24), Color("222222"), INK, 1.5)
		draw_circle(Vector2(94, 68), 3, Color("e6007e"))


# --- influencer: baş harfli yuvarlak ve kademe ------------------------------------------------------------------

func _d_influencer(name: String) -> void:
	draw_circle(Vector2(60, 40), 28, Color(TERRA, 0.85))
	draw_arc(Vector2(60, 40), 32, 0, TAU, 32, Color("e6007e"), 3.0)
	var letter: String = name.trim_prefix("@").substr(0, 1).to_upper()
	draw_string(get_theme_default_font(), Vector2(30, 50), letter, HORIZONTAL_ALIGNMENT_CENTER, 60, 28, Color.WHITE)
