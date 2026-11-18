class_name LogoCanvas
extends Control
## Parodi logo çizimleri (LG-1). Her logo 256x256 şeffaf zeminde şekil + yazıyla çizilir; logo_maker bunu PNG'ye
## çevirir. Kural: gerçek logonun rengi ve genel hissi tanıdık gelsin, ama adın şakası çizimde açıkça görünsün
## (Abode'da çatı, Pear'da armut, YourTube'da macun tüpü...). Yeni logo: LOGOS'a ekle, aynı adlı _l_<id> yaz.

const S: float = 256.0
const PAD: float = 16.0
const RADIUS: float = 52.0
const FONT_BOLD: String = "res://assets/fonts/SourceSans3.ttf"
const FONT_ROUND: String = "res://assets/fonts/Fredoka.ttf"

var logo: String = ""


func _draw() -> void:
	if has_method("_l_" + logo):
		call("_l_" + logo)


# --- yardımcılar -------------------------------------------------------------------------------------------

func _font(path: String, weight: int) -> Font:
	var f: FontVariation = FontVariation.new()
	f.base_font = load(path) as Font
	f.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
	return f


## Yuvarlak köşeli kare zemin; yukarıdan aşağı çok hafif koyulaşır (sert parlama çizgisi yok).
func _tile(col: Color, r: float = RADIUS, rect: Rect2 = Rect2(PAD, PAD, S - PAD * 2, S - PAD * 2)) -> void:
	_poly_grad(_rounded(rect, r), col.lightened(0.06), col.darkened(0.08))


func _rounded(rect: Rect2, r: float, seg: int = 10) -> PackedVector2Array:
	var p: PackedVector2Array = PackedVector2Array()
	var cs: Array[Vector2] = [rect.end - Vector2(r, r), Vector2(rect.position.x + r, rect.end.y - r), rect.position + Vector2(r, r),
		Vector2(rect.end.x - r, rect.position.y + r)]
	for k: int in 4:
		for i: int in seg + 1:
			var a: float = PI * 0.5 * k + PI * 0.5 * i / seg
			p.append(cs[k] + Vector2(cos(a), sin(a)) * r)
	return p


## font verilirse yol/ağırlık yerine o kullanılır (oyunun kendi yazı tipleri: CozyTheme).
func _text(t: String, center: Vector2, size: int, col: Color, path: String = FONT_BOLD, weight: int = 800, font: Font = null) -> void:
	var f: Font = font if font != null else _font(path, weight)
	var w: Vector2 = f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	var base: float = center.y + (f.get_ascent(size) - f.get_descent(size)) * 0.5
	draw_string(f, Vector2(center.x - w.x * 0.5, base), t, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


func _circle(c: Vector2, r: float, n: int = 48) -> PackedVector2Array:
	var p: PackedVector2Array = PackedVector2Array()
	for i: int in n:
		var a: float = TAU * i / n
		p.append(c + Vector2(cos(a), sin(a)) * r)
	return p


func _ellipse(c: Vector2, rx: float, ry: float, rot: float, n: int = 32) -> PackedVector2Array:
	var p: PackedVector2Array = PackedVector2Array()
	for i: int in n:
		var a: float = TAU * i / n
		p.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot))
	return p


func _union(a: PackedVector2Array, b: PackedVector2Array) -> PackedVector2Array:
	var m: Array[PackedVector2Array] = Geometry2D.merge_polygons(a, b)
	return m[0] if not m.is_empty() else a


func _cut(a: PackedVector2Array, b: PackedVector2Array) -> PackedVector2Array:
	var m: Array[PackedVector2Array] = Geometry2D.clip_polygons(a, b)
	return m[0] if not m.is_empty() else a


## Dikey renk geçişli çokgen (üst renk → alt renk).
func _poly_grad(p: PackedVector2Array, top: Color, bottom: Color) -> void:
	var y0: float = INF
	var y1: float = -INF
	for v: Vector2 in p:
		y0 = minf(y0, v.y)
		y1 = maxf(y1, v.y)
	var cols: PackedColorArray = PackedColorArray()
	for v: Vector2 in p:
		cols.append(top.lerp(bottom, (v.y - y0) / maxf(1.0, y1 - y0)))
	draw_polygon(p, cols)


# --- Abode ailesi: koyu kare, iki-üç harf, harflerin üstünde küçük ev çatısı ("abode" = ev) ------------------

func _abode(bg: Color, fg: Color, letters: String) -> void:
	_tile(bg)
	var roof: PackedVector2Array = PackedVector2Array([Vector2(84, 100), Vector2(128, 62), Vector2(172, 100)])
	draw_polyline(roof, fg, 13.0, true)
	draw_rect(Rect2(150, 64, 11, 22), fg)  # baca
	_text(letters, Vector2(128, 160), 92, fg)


func _l_abode_photostore() -> void:
	_abode(Color("0b2440"), Color("4fb3ff"), "Pst")


# --- Nitrosoft ofis ailesi: renkli kare, solda beyaz kart üstünde harf, sağda ürünün simgesi ------------------

func _nitro_card(bg: Color, letter: String) -> void:
	var card: StyleBoxFlat = StyleBoxFlat.new()
	card.bg_color = Color.WHITE
	card.set_corner_radius_all(18)
	card.anti_aliasing = true
	draw_style_box(card, Rect2(36, 70, 112, 116))
	_text(letter, Vector2(92, 128), 92, bg)
	# Nitrosoft imzası: köşede dört küçük renkli alev (pencere yerine).
	var flames: Array[Color] = [Color("f25022"), Color("7fba00"), Color("00a4ef"), Color("ffb900")]
	for i: int in 4:
		var c: Vector2 = Vector2(186 + (i % 2) * 22, 52 + (i / 2) * 24)
		var f: PackedVector2Array = PackedVector2Array([c + Vector2(0, -11), c + Vector2(8, 3), c + Vector2(0, 10), c + Vector2(-8, 3)])
		draw_colored_polygon(f, flames[i])


func _l_nitrosoft_newcel() -> void:
	var bg: Color = Color("1d7044")
	_tile(bg)
	for i: int in 4:  # tablo satırları
		draw_rect(Rect2(160, 108 + i * 22, 62, 12), Color(1, 1, 1, 0.55 if i % 2 == 0 else 0.3))
	_nitro_card(bg, "N")


# --- YourTube: kırmızı oynat düğmesi, ama bir macun tüpünün üstünde ------------------------------------------

func _l_yourtube() -> void:
	var red: Color = Color("ff2a2a")
	# Tüp gövdesi: sağa doğru hafif genişleyen yuvarlak dikdörtgen; solda kapak, sağda kıvrık uç.
	# Boyun (kapak tarafı) dar, gövde sağa doğru genişler; köşeler yuvarlak.
	var body: PackedVector2Array = PackedVector2Array([Vector2(44, 108), Vector2(70, 84), Vector2(196, 70), Vector2(196, 186),
		Vector2(70, 172), Vector2(44, 148)])
	_poly_grad(body, red.lightened(0.12), red.darkened(0.12))
	var crimp: PackedVector2Array = PackedVector2Array()
	for i: int in 9:
		crimp.append(Vector2(196 + (12 if i % 2 == 0 else 22), 70 + i * 14.5))
	crimp.append(Vector2(196, 186))
	crimp.append(Vector2(196, 70))
	draw_colored_polygon(crimp, red.darkened(0.25))
	_poly_grad(_rounded(Rect2(16, 100, 32, 56), 6), Color("f4f4f4"), Color("c9c9c9"))  # kapak, boyna oturur
	for i: int in 4:
		draw_line(Vector2(22 + i * 7, 104), Vector2(22 + i * 7, 152), Color(0, 0, 0, 0.12), 2.0)
	var play: PackedVector2Array = PackedVector2Array([Vector2(108, 100), Vector2(156, 128), Vector2(108, 156)])
	draw_colored_polygon(play, Color.WHITE)


# --- Pear: ısırılmış armut, yaprak; gri metalik ------------------------------------------------------------

func _l_pear() -> void:
	# Armut kesiti: yukarıda dar, aşağıda geniş, belde girinti yok (yumuşak profil).
	var right: PackedVector2Array = PackedVector2Array()
	var left: PackedVector2Array = PackedVector2Array()
	var n: int = 40
	for i: int in n + 1:
		var t: float = float(i) / n
		var w: float = (34.0 + 42.0 * smoothstep(0.15, 0.85, t)) * pow(sin(PI * t), 0.55)
		var y: float = 66.0 + 168.0 * t
		right.append(Vector2(128 + w, y))
		left.append(Vector2(128 - w, y))
	left.reverse()
	var body: PackedVector2Array = right + left
	body = _cut(body, _circle(Vector2(184, 132), 26))  # ısırık
	_poly_grad(body, Color("9aa0a6"), Color("3c4043"))
	draw_line(Vector2(128, 66), Vector2(134, 38), Color("5f6368"), 8.0, true)  # sap
	draw_colored_polygon(_ellipse(Vector2(152, 44), 22, 10, -0.5), Color("5f6368"))


func _l_abode_vectorator() -> void:
	_abode(Color("2e0f00"), Color("ff9a00"), "Vr")


func _l_abode_outdesign() -> void:
	_abode(Color("49021f"), Color("ff3f7f"), "Od")


func _l_abode_premium_pro() -> void:
	_abode(Color("00005b"), Color("9999ff"), "Pp")


func _l_abode_before_effects() -> void:
	_abode(Color("1f0040"), Color("d291ff"), "Be")


func _l_nitrosoft_strongpoint() -> void:
	var bg: Color = Color("c43e1c")
	_tile(bg)
	# Sunum tahtası: pasta grafiği, bir dilimi dışarı çıkmış.
	var c: Vector2 = Vector2(190, 146)
	var pie: PackedVector2Array = PackedVector2Array([c])
	for i: int in 37:
		var a: float = -PI * 0.5 + TAU * 0.75 * i / 36.0
		pie.append(c + Vector2(cos(a), sin(a)) * 30)
	draw_colored_polygon(pie, Color(1, 1, 1, 0.85))
	var sc: Vector2 = c + Vector2(6, -6)
	var slice: PackedVector2Array = PackedVector2Array([sc])
	for i: int in 13:
		var a: float = PI + PI * 0.5 * i / 12.0
		slice.append(sc + Vector2(cos(a), sin(a)) * 30)
	draw_colored_polygon(slice, Color(1, 1, 1, 0.5))
	_nitro_card(bg, "S")


func _l_nitrosoft_world() -> void:
	var bg: Color = Color("185abd")
	_tile(bg)
	for i: int in 5:  # metin satırları
		draw_rect(Rect2(160, 100 + i * 18, 62 - (24 if i == 4 else 0), 9), Color(1, 1, 1, 0.6))
	_nitro_card(bg, "W")
