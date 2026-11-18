class_name LogoSocial
extends LogoTools
## Platform logoları (LG-1): Gooble Abs, FaceNook, tweakker, LinkedOut, Instagraph, TickTock (YourTube LogoCanvas'ta).


## Gooble Abs: sarı-mavi "A" çubukları; yeşil nokta yerine yeşil dambıl.
func _l_gooble_abs() -> void:
	_tile(Color("fbf7f0"))
	draw_line(Vector2(90, 178), Vector2(132, 74), Color("fbbc04"), 34.0, true)
	draw_line(Vector2(132, 74), Vector2(176, 180), Color("4285f4"), 34.0, true)
	draw_circle(Vector2(132, 74), 17, Color("4285f4"))
	draw_circle(Vector2(176, 180), 17, Color("4285f4"))
	draw_circle(Vector2(90, 178), 17, Color("fbbc04"))
	var g: Color = Color("34a853")  # dambıl, A'nın altında
	draw_line(Vector2(86, 216), Vector2(178, 216), g, 10.0)
	draw_colored_polygon(_rounded(Rect2(74, 194, 22, 44), 7), g)
	draw_colored_polygon(_rounded(Rect2(168, 194, 22, 44), 7), g)


## FaceNook: mavi kare, beyaz küçük "n".
func _l_facenook() -> void:
	_tile(Color("1877f2"))
	_text("n", Vector2(132, 126), 190, Color.WHITE, "", 0, CozyTheme.body_font(800))


## tweakker: mavi kare, kuş yerine beyaz İngiliz anahtarı ("tweak" = ince ayar).
func _l_tweakker() -> void:
	_tile(Color("1d9bf0"))
	draw_line(Vector2(76, 182), Vector2(150, 108), Color.WHITE, 30.0, true)
	draw_circle(Vector2(76, 182), 15, Color.WHITE)
	var head: PackedVector2Array = _circle(Vector2(168, 90), 44)
	head = _cut(head, PackedVector2Array([Vector2(172, 84), Vector2(230, 26), Vector2(250, 46), Vector2(192, 104)]))
	draw_colored_polygon(head, Color.WHITE)


## LinkedOut: mavi kare, "out" ve dışarı fırlayan ok.
func _l_linkedout() -> void:
	_tile(Color("0a66c2"))
	_text("out", Vector2(116, 146), 96, Color.WHITE)
	draw_line(Vector2(168, 96), Vector2(204, 60), Color.WHITE, 12.0, true)
	draw_colored_polygon(PackedVector2Array([Vector2(218, 46), Vector2(214, 84), Vector2(180, 50)]), Color.WHITE)


## Instagraph: sarı-turuncu-pembe-mor çapraz geçişli kare; kamera çerçevesinde objektif yerine çizgi grafik.
func _l_instagraph() -> void:
	var tile: PackedVector2Array = _rounded(Rect2(PAD, PAD, S - PAD * 2, S - PAD * 2), RADIUS)
	var cols: PackedColorArray = PackedColorArray()
	var stops: Array[Color] = [Color("feda75"), Color("fa7e1e"), Color("d62976"), Color("962fbf"), Color("4f5bd5")]
	for v: Vector2 in tile:
		var t: float = clampf(((v.x - PAD) + (S - PAD - v.y)) / ((S - PAD * 2) * 2.0), 0.0, 1.0)
		var k: float = t * (stops.size() - 1)
		var i: int = mini(int(k), stops.size() - 2)
		cols.append(stops[i].lerp(stops[i + 1], k - i))
	draw_polygon(tile, cols)
	var frame: PackedVector2Array = _rounded(Rect2(56, 56, 144, 144), 38)
	frame.append(frame[0])
	draw_polyline(frame, Color.WHITE, 14.0, true)
	draw_polyline(PackedVector2Array([Vector2(80, 164), Vector2(108, 130), Vector2(132, 148), Vector2(172, 102)]), Color.WHITE, 13.0, true)
	draw_circle(Vector2(80, 164), 6.5, Color.WHITE)
	draw_circle(Vector2(172, 102), 6.5, Color.WHITE)
	draw_circle(Vector2(170, 78), 8, Color.WHITE)


## TickTock: siyah kare, nota yerine camgöbeği-kırmızı gölgeli çalar saat.
func _l_ticktock() -> void:
	_tile(Color("010101"))
	var offs: Array[Vector2] = [Vector2(-5, -4), Vector2(5, 4), Vector2.ZERO]
	var cols: Array[Color] = [Color("25f4ee"), Color("fe2c55"), Color.WHITE]
	for k: int in 3:
		var c: Vector2 = Vector2(128, 136) + offs[k]
		draw_arc(c, 64, 0, TAU, 48, cols[k], 15.0, true)
		draw_line(c, c + Vector2(0, -38), cols[k], 12.0, true)
		draw_line(c, c + Vector2(28, 14), cols[k], 12.0, true)
		draw_arc(c + Vector2(-50, -58), 16, PI, TAU, 10, cols[k], 10.0, true)
		draw_arc(c + Vector2(50, -58), 16, PI, TAU, 10, cols[k], 10.0, true)
