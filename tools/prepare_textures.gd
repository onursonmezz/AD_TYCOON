extends SceneTree
## Görsel AI dokularını oyuna hazırlar (art/ai_rehberi.md 6): art/incoming/textures/<ad>.png →
## assets/textures/surfaces/<ad>.png. Ayarlar tools/texture_prep.json.
## - crop_x / crop_y: sol (üst) şeridi en iyi tutan sütunu (satırı) bulur ve resmi orada keser; tekrar eden
##   desenlerde (noktalar, tahta sıraları) kenarlar kusursuz birleşir.
## - Kare olarak size × size'a ölçekler; doygunluk/parlaklık dengesi uygular (ofisin sıcak ışığında fazla doygun duruyor).
## Çalıştırma: godot --headless --script res://tools/prepare_textures.gd

const SRC: String = "res://art/incoming/textures"
const DST: String = "res://assets/textures/surfaces"
const STRIP: int = 8           # karşılaştırılan şerit genişliği (px)
const SEARCH_FROM: float = 0.8  # kesim noktası en az genişliğin bu oranı kadar sağda


func _init() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tools/texture_prep.json"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DST))
	var size: int = int(cfg["size"])
	for name: String in cfg["textures"]:
		var t: Dictionary = cfg["textures"][name]
		var src: String = ProjectSettings.globalize_path(SRC.path_join(name + ".png"))
		if bool(t.get("skip", false)):
			print("ATLA  %s" % name)
			continue
		if not FileAccess.file_exists(src):
			print("YOK   %s" % name)
			continue
		var img: Image = Image.load_from_file(src)
		img.convert(Image.FORMAT_RGBA8)
		var w: int = img.get_width()
		var h: int = img.get_height()
		if bool(t.get("crop_x", false)):
			w = _period(img, true)
		if bool(t.get("crop_y", false)):
			h = _period(img, false)
		img = img.get_region(Rect2i(0, 0, w, h))
		img.resize(size, size, Image.INTERPOLATE_LANCZOS)
		_grade(img, t.get("grade", cfg["default_grade"]))
		img.convert(Image.FORMAT_RGB8)
		img.save_png(ProjectSettings.globalize_path(DST.path_join(name + ".png")))
		print("HAZIR %s  kesim %dx%d → %d" % [name, w, h, size])
	quit()


## Başlangıç şeridine en çok benzeyen konum (o noktada kesince desen kendine bağlanır).
func _period(img: Image, horizontal: bool) -> int:
	var n: int = img.get_width() if horizontal else img.get_height()
	var other: int = img.get_height() if horizontal else img.get_width()
	var best: int = n
	var best_d: float = INF
	for cut: int in range(int(n * SEARCH_FROM), n - STRIP + 1):
		var d: float = 0.0
		for k: int in STRIP:
			for j: int in range(0, other, 6):
				var a: Color = img.get_pixel(k, j) if horizontal else img.get_pixel(j, k)
				var b: Color = img.get_pixel(cut + k, j) if horizontal else img.get_pixel(j, cut + k)
				d += absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)
		if d < best_d:
			best_d = d
			best = cut
	return best


func _grade(img: Image, grade: Dictionary) -> void:
	var sat: float = float(grade.get("sat", 1.0))
	var val: float = float(grade.get("val", 1.0))
	for y: int in img.get_height():
		for x: int in img.get_width():
			var c: Color = img.get_pixel(x, y)
			var lum: float = c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722
			img.set_pixel(x, y, Color(clampf((lum + (c.r - lum) * sat) * val, 0.0, 1.0),
				clampf((lum + (c.g - lum) * sat) * val, 0.0, 1.0), clampf((lum + (c.b - lum) * sat) * val, 0.0, 1.0)))
