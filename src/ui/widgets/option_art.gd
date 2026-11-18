class_name OptionArt
extends Control
## Kampanya seçeneklerinin küçük çizimi (S2): seçim panelindeki kartlarda ve seçici düğmede. Görsel dosya yok,
## kodla çizilir (logolar gibi). Tasarım alanı 120x84; Control hangi boydaysa ona ölçeklenir.
## Bu dosya baskı seçenekleri (ürün, kalite, dağıtım, matbaa); medya seçenekleri OptionArtMedia'da.
## Yeni çizim: kind + id için _d_<kind>_<id> ya da _d_<kind>(id) yaz.

const W: float = 120.0
const H: float = 84.0
const INK: Color = Color("4a3b2c")
const PAPER: Color = Color("fffaf0")
const TERRA: Color = Color("c8643b")
const SAGE: Color = Color("8fae8b")
const FOREST: Color = Color("2f5d46")
const MUSTARD: Color = Color("e0a93b")
const SKY: Color = Color("7fb3d5")

var kind: String = ""
var id: String = ""


func _init(k: String = "", i: String = "") -> void:
	kind = k
	id = i
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(k: String, i: String) -> void:
	kind = k
	id = i
	queue_redraw()


func _draw() -> void:
	var s: float = minf(size.x / W, size.y / H)
	draw_set_transform(Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5), 0.0, Vector2(s, s))
	var k: String = kind.replace(".", "_").replace("social_", "digital_")  # sosyal kanallar dijitalin seçeneklerini kullanır
	var f: String = "_d_%s_%s" % [k, id]
	if has_method(f):
		call(f)
	elif has_method("_d_" + k):
		call("_d_" + k, id)
	else:
		_blob(Vector2(60, 42), 22, SAGE)
	draw_set_transform(Vector2.ZERO)


# --- yardımcılar -----------------------------------------------------------------------------------------------

func _box(r: Rect2, fill: Color, line: Color = INK, w: float = 2.0) -> void:
	draw_rect(r, fill)
	draw_rect(r, line, false, w)


func _lines(r: Rect2, n: int, col: Color = Color(INK, 0.35)) -> void:
	for i: int in n:
		var y: float = r.position.y + (i + 0.5) * r.size.y / n
		draw_line(Vector2(r.position.x, y), Vector2(r.end.x - (r.size.x * 0.25 if i == n - 1 else 0.0), y), col, 2.0)


func _blob(c: Vector2, r: float, col: Color) -> void:
	draw_circle(c, r, col)


func _poly(pts: Array, col: Color) -> void:
	draw_colored_polygon(PackedVector2Array(pts), col)


func _person(c: Vector2, h: float, col: Color) -> void:
	draw_circle(c + Vector2(0, -h * 0.75), h * 0.22, col)
	_poly([c + Vector2(-h * 0.3, 0), c + Vector2(-h * 0.22, -h * 0.5), c + Vector2(h * 0.22, -h * 0.5), c + Vector2(h * 0.3, 0)], col)


func _star(c: Vector2, r: float, col: Color) -> void:
	var p: PackedVector2Array = PackedVector2Array()
	for i: int in 10:
		var a: float = -PI * 0.5 + PI * i / 5.0
		p.append(c + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.45))
	draw_colored_polygon(p, col)


# --- baskı ürünleri: kağıt oranı doğru (A5 dikey, katalog kalın, wobbler yaylı) ---------------------------------

func _d_product_flyer_a5() -> void:
	_box(Rect2(42, 8, 36, 52), PAPER)
	draw_rect(Rect2(46, 12, 28, 18), Color(TERRA, 0.75))
	_lines(Rect2(46, 34, 28, 20), 3)
	draw_string(get_theme_default_font(), Vector2(40, 78), "A5", HORIZONTAL_ALIGNMENT_CENTER, 40, 13, INK)


func _d_product_brochure_a4() -> void:
	# Üç kırımlı broşür: zikzak paneller.
	_poly([Vector2(20, 12), Vector2(48, 18), Vector2(48, 70), Vector2(20, 64)], PAPER)
	_poly([Vector2(48, 18), Vector2(76, 12), Vector2(76, 64), Vector2(48, 70)], Color("f3eadb"))
	_poly([Vector2(76, 12), Vector2(102, 18), Vector2(102, 70), Vector2(76, 64)], PAPER)
	draw_polyline(PackedVector2Array([Vector2(20, 12), Vector2(48, 18), Vector2(76, 12), Vector2(102, 18), Vector2(102, 70),
		Vector2(76, 64), Vector2(48, 70), Vector2(20, 64), Vector2(20, 12)]), INK, 2.0)
	draw_rect(Rect2(80, 22, 18, 14), Color(SAGE, 0.9))
	_lines(Rect2(24, 26, 20, 30), 4)
	_lines(Rect2(52, 26, 20, 30), 4)


func _catalog(pages: int) -> void:
	var t: float = 3.0 + pages / 8.0  # sayfa sayısı arttıkça kalınlaşır
	for i: int in int(t):
		_box(Rect2(32 + i * 1.2, 12 + i * 1.6, 48, 50), PAPER, Color(INK, 0.5), 1.0)
	_box(Rect2(32, 12, 48, 50), Color("f7e3c8"))
	draw_rect(Rect2(36, 16, 40, 22), Color(TERRA, 0.7))
	draw_string(get_theme_default_font(), Vector2(36, 56), str(pages), HORIZONTAL_ALIGNMENT_CENTER, 40, 14, INK)


func _d_product_catalog_16() -> void:
	_catalog(16)


func _d_product_catalog_32() -> void:
	_catalog(32)


func _d_product_catalog_64() -> void:
	_catalog(64)


func _d_product_pop_wobbler() -> void:
	draw_rect(Rect2(14, 60, 92, 6), Color("d9c3a0"))  # raf
	draw_polyline(PackedVector2Array([Vector2(60, 60), Vector2(56, 54), Vector2(64, 48), Vector2(56, 42), Vector2(62, 36)]), INK, 2.0)
	draw_circle(Vector2(62, 24), 15, MUSTARD)
	draw_arc(Vector2(62, 24), 15, 0, TAU, 24, INK, 2.0)
	draw_string(get_theme_default_font(), Vector2(48, 29), "%", HORIZONTAL_ALIGNMENT_CENTER, 28, 15, INK)
	draw_arc(Vector2(62, 24), 22, -0.8, 0.8, 8, Color(INK, 0.4), 2.0)


func _d_product_pop_stand() -> void:
	_box(Rect2(40, 8, 40, 58), Color("f7e3c8"))
	draw_rect(Rect2(44, 12, 32, 26), Color(TERRA, 0.75))
	_lines(Rect2(44, 42, 32, 18), 2)
	_poly([Vector2(34, 66), Vector2(86, 66), Vector2(90, 74), Vector2(30, 74)], Color("d9c3a0"))


# --- kalite: ekonomik ince ve soluk, standart beyaz, premium parlak ---------------------------------------------

func _d_quality(q: String) -> void:
	var fill: Color = {"economy": Color("e6ddcc"), "standard": PAPER, "premium": Color("fffdf8")}.get(q, PAPER)
	_box(Rect2(36, 10, 48, 60), fill, INK if q != "economy" else Color(INK, 0.5))
	draw_rect(Rect2(40, 14, 40, 26), Color(TERRA, {"economy": 0.35, "standard": 0.7, "premium": 0.95}.get(q, 0.7)))
	if q == "premium":
		_poly([Vector2(56, 10), Vector2(68, 10), Vector2(44, 70), Vector2(36, 70), Vector2(36, 60)], Color(1, 1, 1, 0.55))
		_star(Vector2(86, 14), 9, MUSTARD)
	elif q == "economy":
		for i: int in 3:
			draw_line(Vector2(40, 48 + i * 7), Vector2(80, 50 + i * 7), Color(INK, 0.2), 1.0)


# --- dağıtım ---------------------------------------------------------------------------------------------------

func _d_distribution_door_to_door() -> void:
	_box(Rect2(38, 8, 44, 66), Color("b07a4f"))
	draw_rect(Rect2(52, 36, 16, 4), INK)  # posta deliği
	_box(Rect2(56, 22, 14, 18), PAPER, INK, 1.5)
	draw_circle(Vector2(74, 44), 3, MUSTARD)


func _d_distribution_newspaper_insert() -> void:
	_box(Rect2(26, 30, 60, 40), Color("ecebe6"))
	_lines(Rect2(30, 36, 52, 28), 4)
	_box(Rect2(52, 12, 34, 40), Color("fbe7d6"), TERRA)
	draw_rect(Rect2(56, 16, 26, 12), Color(TERRA, 0.7))


func _d_distribution_in_store() -> void:
	_box(Rect2(24, 34, 72, 40), PAPER)
	for i: int in 5:
		_poly([Vector2(22 + i * 15, 24), Vector2(37 + i * 15, 24), Vector2(37 + i * 15, 36), Vector2(22 + i * 15, 36)],
			TERRA if i % 2 == 0 else PAPER)
	draw_rect(Rect2(22, 24, 76, 12), INK, false, 2.0)
	_box(Rect2(52, 48, 16, 26), Color("b07a4f"))
	_box(Rect2(30, 44, 16, 14), Color(SKY, 0.6))


func _d_distribution_fair() -> void:
	_box(Rect2(22, 36, 76, 34), Color("f7e3c8"))
	draw_rect(Rect2(22, 30, 76, 8), FOREST)
	draw_line(Vector2(30, 30), Vector2(30, 8), INK, 2.0)
	_poly([Vector2(30, 8), Vector2(50, 13), Vector2(30, 18)], TERRA)
	_person(Vector2(78, 70), 26, Color(INK, 0.7))


# --- matbaa: küçük baskı makinesi, matbaanın rengiyle ----------------------------------------------------------

func _d_supplier(s: String) -> void:
	var col: Color = {"ucuzcu_ofset": Color("9c7b5b"), "renkli_baski": TERRA, "altin_varak": MUSTARD, "hizli_dijital": SKY}.get(s, SAGE)
	_box(Rect2(24, 30, 72, 34), col.lightened(0.35))
	draw_rect(Rect2(24, 30, 72, 34), INK, false, 2.0)
	draw_circle(Vector2(44, 47), 9, col.darkened(0.2))
	draw_circle(Vector2(76, 47), 9, col.darkened(0.2))
	_box(Rect2(36, 10, 48, 22), PAPER, INK, 1.5)
	if s == "renkli_baski":  # CMYK şeritleri
		var cmyk: Array[Color] = [Color("00a3d9"), Color("e6007e"), Color("ffe600"), Color("222222")]
		for i: int in 4:
			draw_rect(Rect2(40 + i * 10, 14, 8, 14), cmyk[i])
	elif s == "altin_varak":
		_star(Vector2(60, 21), 8, MUSTARD)
	elif s == "hizli_dijital":  # şimşek: hız
		_poly([Vector2(62, 12), Vector2(52, 23), Vector2(59, 23), Vector2(55, 31), Vector2(67, 19), Vector2(60, 19)], SKY.darkened(0.3))
	else:
		_lines(Rect2(40, 14, 40, 14), 2)
	draw_rect(Rect2(28, 66, 64, 6), Color(INK, 0.6))
