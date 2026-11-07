class_name CozyIcons
extends RefCounted
## Cozy Refined temasının kodla çizilen küçük ikonları (UI-2): onay kutusu, radyo, anahtar, açılır ok, kaydırıcı
## tutamağı. Godot'nun hazır beyaz ikonları krem zeminde görünmediği için.


const ICON_PX: int = 18


## Kenarı yumuşatılmış daire ya da yuvarlak kare; seçiliyse dolu ve ortasında işaret.
static func check(checked: bool, radio: bool) -> ImageTexture:
	var n: int = ICON_PX
	var img: Image = Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c: Vector2 = Vector2(n, n) * 0.5
	for y: int in n:
		for x: int in n:
			var p: Vector2 = Vector2(x + 0.5, y + 0.5) - c
			var d: float = p.length() - (n * 0.5 - 1.0) if radio else round_rect_dist(p, n * 0.5 - 1.0, 4.0)
			var col: Color = Color.TRANSPARENT
			if checked:
				col = Color(CozyTheme.FOREST, clampf(0.5 - d, 0.0, 1.0))
			else:
				var fill: Color = CozyTheme.CREAM_LIGHT
				var edge: float = clampf(1.0 - absf(d + 0.75), 0.0, 1.0)
				col = Color(fill.lerp(CozyTheme.MUTED, edge), clampf(0.5 - d, 0.0, 1.0))
			img.set_pixel(x, y, col)
	if checked:
		if radio:
			for y: int in n:
				for x: int in n:
					var d2: float = (Vector2(x + 0.5, y + 0.5) - c).length() - 3.5
					if d2 < 0.5:
						img.set_pixel(x, y, CozyTheme.CREAM_LIGHT.lerp(CozyTheme.FOREST, clampf(d2 + 0.5, 0.0, 1.0)))
		else:
			stroke(img, [Vector2(4.5, 9.5), Vector2(7.5, 12.5), Vector2(13.5, 5.5)], CozyTheme.CREAM_LIGHT, 1.4)
	return ImageTexture.create_from_image(img)


static func round_rect_dist(p: Vector2, half: float, r: float) -> float:
	var q: Vector2 = Vector2(absf(p.x), absf(p.y)) - Vector2(half - r, half - r)
	return Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0) - r


## Kırık çizgi (onay işareti, ok); kalınlık piksel.
static func stroke(img: Image, pts: Array, col: Color, width: float) -> void:
	for y: int in img.get_height():
		for x: int in img.get_width():
			var p: Vector2 = Vector2(x + 0.5, y + 0.5)
			var best: float = 99.0
			for i: int in pts.size() - 1:
				var a: Vector2 = pts[i]
				var b: Vector2 = pts[i + 1]
				var t: float = clampf((p - a).dot(b - a) / (b - a).length_squared(), 0.0, 1.0)
				best = minf(best, (p - (a + (b - a) * t)).length())
			var k: float = clampf(width - best + 0.5, 0.0, 1.0)
			if k > 0.0:
				img.set_pixel(x, y, img.get_pixel(x, y).lerp(col, k) if img.get_pixel(x, y).a > 0.0 else Color(col, k))


## Hap biçimli anahtar: açıkken yeşil ray + sağda topuz, kapalıyken bej ray + solda topuz.
static func switch(on: bool) -> ImageTexture:
	var w: int = 44
	var h: int = 24
	var img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var r: float = h * 0.5
	var knob: Vector2 = Vector2(w - r, r) if on else Vector2(r, r)
	for y: int in h:
		for x: int in w:
			var p: Vector2 = Vector2(x + 0.5, y + 0.5)
			var cx: float = clampf(p.x, r, w - r)
			var d: float = (p - Vector2(cx, r)).length() - (r - 0.5)
			var col: Color = Color(CozyTheme.FOREST_LIGHT if on else CozyTheme.BORDER, clampf(0.5 - d, 0.0, 1.0))
			var kd: float = (p - knob).length() - (r - 3.5)
			if kd < 0.5:
				col = col.lerp(CozyTheme.CREAM_LIGHT, clampf(0.5 - kd, 0.0, 1.0))
				col.a = maxf(col.a, clampf(0.5 - kd, 0.0, 1.0))
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)


static func arrow() -> ImageTexture:
	var img: Image = Image.create(14, 14, false, Image.FORMAT_RGBA8)
	stroke(img, [Vector2(3.5, 5.5), Vector2(7.0, 9.0), Vector2(10.5, 5.5)], CozyTheme.MUTED, 1.1)
	return ImageTexture.create_from_image(img)


static func dot(col: Color) -> ImageTexture:
	var n: int = ICON_PX
	var img: Image = Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c: Vector2 = Vector2(n, n) * 0.5
	for y: int in n:
		for x: int in n:
			var d: float = (Vector2(x + 0.5, y + 0.5) - c).length()
			var inner: float = clampf(n * 0.5 - 3.0 - d + 0.5, 0.0, 1.0)
			var outer: float = clampf(n * 0.5 - 1.0 - d + 0.5, 0.0, 1.0)
			img.set_pixel(x, y, Color(CozyTheme.CREAM_LIGHT.lerp(col, inner), outer))
	return ImageTexture.create_from_image(img)
