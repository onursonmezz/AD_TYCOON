class_name LogoTools
extends LogoCanvas
## Diğer yazılım logoları (LG-1): Slak, ChatTNT, Kamva, Digma, TopJourney, Theatre 4D, Tricksfield,
## Survey Cappybara, Gooble Analytics, Tootsuite. Kural LogoCanvas başındaki gibi.


## Slak: dört renkli kare-diyez, ama çubuklar gevşek, ortadan sarkıyor ("slack").
func _l_slak() -> void:
	_tile(Color("fbf7f0"))
	var cols: Array[Color] = [Color("36c5f0"), Color("2eb67d"), Color("ecb22e"), Color("e01e5a")]
	var bars: Array = [[Vector2(96, 70), Vector2(92, 186)], [Vector2(160, 70), Vector2(156, 186)],
		[Vector2(70, 100), Vector2(186, 104)], [Vector2(70, 156), Vector2(186, 160)]]
	for i: int in 4:
		var a: Vector2 = bars[i][0]
		var b: Vector2 = bars[i][1]
		var sag: Vector2 = Vector2(0, 16) if i >= 2 else Vector2(10, 0)
		var pts: PackedVector2Array = PackedVector2Array()
		for k: int in 13:
			var t: float = k / 12.0
			pts.append(a.lerp(b, t) + sag * sin(PI * t))
		draw_polyline(pts, cols[i], 22.0, true)
		draw_circle(pts[0], 11.0, cols[i])
		draw_circle(pts[pts.size() - 1], 11.0, cols[i])


## ChatTNT: yeşil-mavi kare, beyaz konuşma balonu, içinde fitili yanan dinamit.
func _l_chattnt() -> void:
	_tile(Color("10a37f"))
	var bubble: PackedVector2Array = _rounded(Rect2(40, 52, 176, 128), 40)
	bubble = _union(bubble, PackedVector2Array([Vector2(76, 160), Vector2(112, 176), Vector2(60, 214)]))
	draw_colored_polygon(bubble, Color.WHITE)
	draw_colored_polygon(_rounded(Rect2(72, 98, 104, 40), 8), Color("d93a2b"))
	_text("TNT", Vector2(124, 118), 28, Color.WHITE)
	draw_polyline(PackedVector2Array([Vector2(176, 112), Vector2(190, 98), Vector2(184, 84)]), Color("444444"), 4.0, true)
	for i: int in 6:  # kıvılcım
		var a: float = TAU * i / 6.0
		draw_line(Vector2(184, 78), Vector2(184, 78) + Vector2(cos(a), sin(a)) * 12.0, Color("ffb000"), 4.0, true)


## Kamva: turkuazdan mora geçen daire, eğik yazıyla ad.
func _l_kamva() -> void:
	var c: PackedVector2Array = _circle(Vector2(128, 128), 110, 64)
	var cols: PackedColorArray = PackedColorArray()
	for v: Vector2 in c:
		var t: float = clampf(((v.x - 18) + (v.y - 18)) / 440.0, 0.0, 1.0)
		cols.append(Color("00c4cc").lerp(Color("7d2ae8"), t))
	draw_polygon(c, cols)
	_text("Kamva", Vector2(128, 124), 64, Color.WHITE, "", 0, CozyTheme.body_font(800))


## Digma: koyu kare üstünde Figma'nın beş rengi, ama zar beşlisi gibi dizili.
func _l_digma() -> void:
	_tile(Color("1e1e1e"))
	var cols: Array[Color] = [Color("f24e1e"), Color("ff7262"), Color("a259ff"), Color("1abcfe"), Color("0acf83")]
	var at: Array[Vector2] = [Vector2(80, 80), Vector2(176, 80), Vector2(128, 128), Vector2(80, 176), Vector2(176, 176)]
	for i: int in 5:
		var r: float = 26.0 if i % 2 == 0 else 14.0
		draw_colored_polygon(_rounded(Rect2(at[i] - Vector2(26, 26), Vector2(52, 52)), r), cols[i])


## TopJourney: siyah kare, beyaz yelkenli; direğin tepesinde silindir şapka.
func _l_topjourney() -> void:
	_tile(Color("0d0d0d"))
	draw_colored_polygon(PackedVector2Array([Vector2(124, 78), Vector2(124, 168), Vector2(64, 168)]), Color.WHITE)
	draw_colored_polygon(PackedVector2Array([Vector2(134, 96), Vector2(134, 168), Vector2(184, 168)]), Color(1, 1, 1, 0.8))
	draw_colored_polygon(PackedVector2Array([Vector2(56, 178), Vector2(200, 178), Vector2(180, 202), Vector2(76, 202)]), Color.WHITE)
	draw_rect(Rect2(112, 40, 26, 28), Color.WHITE)  # şapka
	draw_rect(Rect2(100, 66, 50, 8), Color.WHITE)
	draw_rect(Rect2(112, 58, 26, 4), Color("0d0d0d"))


## Theatre 4D: mavi küre, üstünde beyaz gülen tiyatro maskesi.
func _l_theatre_4d() -> void:
	_poly_grad(_circle(Vector2(128, 128), 108, 64), Color("3a8dff"), Color("0b3c8c"))
	draw_colored_polygon(_ellipse(Vector2(128, 112), 54, 58, 0.0), Color.WHITE)
	draw_colored_polygon(_ellipse(Vector2(106, 98), 13, 8, -0.3), Color("0b3c8c"))
	draw_colored_polygon(_ellipse(Vector2(150, 98), 13, 8, 0.3), Color("0b3c8c"))
	draw_arc(Vector2(128, 118), 28, 0.35, PI - 0.35, 16, Color("0b3c8c"), 8.0, true)
	_text("4D", Vector2(128, 200), 36, Color.WHITE)


## Tricksfield: mor kare, sihirbaz şapkasından çıkan oynat düğmesi ve ışıltılar (yapay zekâ video).
func _l_tricksfield() -> void:
	_tile(Color("5b2bd6"))
	draw_colored_polygon(PackedVector2Array([Vector2(104, 62), Vector2(160, 92), Vector2(104, 122)]), Color.WHITE)
	draw_colored_polygon(_rounded(Rect2(78, 134, 100, 70), 8), Color("1b1036"))
	draw_colored_polygon(_rounded(Rect2(60, 126, 136, 18), 9), Color("1b1036"))
	draw_rect(Rect2(78, 154, 100, 12), Color("ff4fa3"))
	for p: Vector3 in [Vector3(64, 76, 14), Vector3(192, 70, 10), Vector3(180, 116, 8)]:
		var c: Vector2 = Vector2(p.x, p.y)
		var z: float = p.z
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -z), c + Vector2(z * 0.3, -z * 0.3), c + Vector2(z, 0),
			c + Vector2(z * 0.3, z * 0.3), c + Vector2(0, z), c + Vector2(-z * 0.3, z * 0.3), c + Vector2(-z, 0),
			c + Vector2(-z * 0.3, -z * 0.3)]), Color("ffd84a"))


## Survey Cappybara: yeşil kare, maymun yerine beyaz kapibara başı: uzun kutu burun, küçük kulak, uykulu göz.
func _l_surveycappybara() -> void:
	_tile(Color("00bf6f"))
	# Önden: geniş düz tepe, aşağı doğru uzayan kutu yüz, iki yanda küçük kulak, yukarıda uykulu gözler, iri burun.
	var ink: Color = Color("00804a")
	for x: float in [70.0, 186.0]:
		draw_colored_polygon(_ellipse(Vector2(x, 66), 18, 14, 0.0), Color.WHITE)
		draw_colored_polygon(_ellipse(Vector2(x, 68), 9, 6, 0.0), Color("bfeedd"))
	draw_colored_polygon(_rounded(Rect2(56, 58, 144, 152), 54), Color.WHITE)
	draw_line(Vector2(84, 104), Vector2(106, 104), ink, 7.0, true)  # uykulu gözler
	draw_line(Vector2(150, 104), Vector2(172, 104), ink, 7.0, true)
	# Kapibara burnu: geniş koyu bant, içinde yarık burun delikleri; altında Y biçimli ağız (domuz burnu gibi yuvarlak değil).
	draw_colored_polygon(_rounded(Rect2(80, 140, 96, 20), 10), ink)
	draw_colored_polygon(_ellipse(Vector2(108, 150), 7, 3, -0.4), Color.WHITE)
	draw_colored_polygon(_ellipse(Vector2(148, 150), 7, 3, 0.4), Color.WHITE)
	draw_line(Vector2(128, 160), Vector2(128, 178), ink, 5.0, true)
	draw_arc(Vector2(116, 178), 12, 0.0, PI * 0.8, 8, ink, 5.0, true)
	draw_arc(Vector2(140, 178), 12, PI * 0.2, PI, 8, ink, 5.0, true)


## Gooble Analytics: beyaz kare, turuncu-sarı yükselen üç çubuk; en uzun çubuğun üstünde oynak gözler.
func _l_gooble_analytics() -> void:
	_tile(Color("fbf7f0"))
	var bars: Array = [[Vector2(72, 158), Color("e37400")], [Vector2(128, 116), Color("f9ab00")], [Vector2(184, 74), Color("f9ab00")]]
	for b: Array in bars:
		var top: Vector2 = b[0]
		draw_colored_polygon(_rounded(Rect2(top.x - 22, top.y, 44, 206 - top.y), 22), b[1])
	draw_circle(Vector2(174, 98), 12, Color.WHITE)
	draw_circle(Vector2(196, 96), 12, Color.WHITE)
	draw_circle(Vector2(177, 103), 6, Color("202124"))
	draw_circle(Vector2(192, 92), 6, Color("202124"))


## Tootsuite: siyah kare, baykuş yerine renkli şeritli parti düdüğü ("toot").
func _l_tootsuite() -> void:
	_tile(Color("1c1c1c"))
	draw_colored_polygon(PackedVector2Array([Vector2(48, 118), Vector2(168, 84), Vector2(168, 172), Vector2(48, 138)]), Color.WHITE)
	var stripes: Array[Color] = [Color("ff4c46"), Color("ffb000"), Color("3ec7f0")]
	for i: int in 3:
		var x: float = 78.0 + i * 30.0
		var h: float = lerpf(10.0, 42.0, (x - 48.0) / 120.0)
		draw_rect(Rect2(x, 128.0 - h, 12, h * 2.0), stripes[i])
	draw_colored_polygon(_ellipse(Vector2(170, 128), 12, 46, 0.0), Color("dddddd"))
	for i: int in 3:  # ses çizgileri
		draw_arc(Vector2(176, 128), 28.0 + i * 13.0, -0.6, 0.6, 12, Color.WHITE, 5.0, true)
