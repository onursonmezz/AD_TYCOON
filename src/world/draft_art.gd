class_name DraftArt
extends RefCounted
## İlan taslağı dizgicisi (K-120): arka plan + ürün görseli + efekt + slogan + marka. Görseller assets/minigame/
## (art/mini_oyun_gorselleri.md). Hem "ekibin 3 taslağı" kartlarında hem duvar posteri ve billboard'da (KeyVisual)
## aynı çizim kullanılır; oyuncu seçtiği ilanı ofiste birebir görür. Dosya yoksa o katman atlanır.

const ROOT: String = "res://assets/minigame/"
const LAYOUTS: int = 3

static var _cache: Dictionary = {}


static func tex(kind: String, name: String) -> Texture2D:
	if name.is_empty():
		return null
	var path: String = "%s%s/%s.png" % [ROOT, kind, name]
	if not _cache.has(path):
		_cache[path] = load(path) as Texture2D if ResourceLoader.exists(path) else null
	return _cache[path]


## Klasördeki görsel adları (uzantısız), isteğe bağlı önekle.
static func names(kind: String, prefix: String = "") -> Array[String]:
	var out: Array[String] = []
	var dir: DirAccess = DirAccess.open(ROOT + kind)
	if dir == null:
		return out
	for f: String in dir.get_files():
		var file: String = f.trim_suffix(".import").trim_suffix(".remap")
		if file.ends_with(".png") and file.begins_with(prefix):
			var n: String = file.get_basename()
			if not out.has(n):
				out.append(n)
	out.sort()
	return out


## Sektörün ürün görselleri; dönemli dosyalardan (product_<sektör>_<yıl>_N) yalnızca o yıla kadar olanlar.
static func products(sector: String, year: int) -> Array[String]:
	var out: Array[String] = []
	for n: String in names("products", "product_%s_" % sector):
		var rest: String = n.trim_prefix("product_%s_" % sector)
		var parts: PackedStringArray = rest.split("_")
		if parts.size() >= 2 and parts[0].length() == 4 and parts[0].is_valid_int():
			if int(parts[0]) > year:
				continue
		out.append(n)
	return out


## Ekibin 3 taslağı: kampanyaya göre belirlenimci; ürün, arka plan, efekt ve düzen birbirinden farklı.
static func options(data: GameData, setup: Dictionary, year: int, seed_value: int) -> Array[Dictionary]:
	var prods: Array[String] = products(str(setup.get("sector", "")), year)
	var bgs: Array[String] = names("backgrounds", "bg_")
	var fxs: Array[String] = names("effects", "fx_")
	var slogans: int = int(data.models["key_visual"]["slogans"])
	var out: Array[Dictionary] = []
	for i: int in 3:
		var s: int = absi(seed_value) + i * 7
		out.append({
			"product": prods[(s + i) % prods.size()] if not prods.is_empty() else "",
			"bg": bgs[(s / 3 + i) % bgs.size()] if not bgs.is_empty() else "",
			"fx": fxs[(s / 5 + i * 2) % fxs.size()] if not fxs.is_empty() else "",
			"layout": i % LAYOUTS,
			"slogan": "KV_SLOGAN_%d" % ((s + i * 3) % slogans + 1),
		})
	return out


## Taslağı parent'ın içine size boyutunda çizer (Control düğümleri; SubViewport'a da eklenebilir).
static func compose(parent: Node, draft: Dictionary, size: Vector2, brand: String, accent: Color) -> void:
	var bg_tex: Texture2D = tex("backgrounds", str(draft.get("bg", "")))
	if bg_tex != null:
		parent.add_child(_image(bg_tex, Rect2(Vector2.ZERO, size), TextureRect.STRETCH_KEEP_ASPECT_COVERED))
	else:
		var fill: ColorRect = ColorRect.new()
		fill.color = CozyTheme.CREAM
		fill.size = size
		parent.add_child(fill)
	var unit: float = minf(size.x, size.y)
	var layout: int = int(draft.get("layout", 0))
	var prod_rect: Rect2
	var text_rect: Rect2
	match layout:
		0:  # ürün ortada altta, slogan üstte
			prod_rect = Rect2(size.x * 0.22, size.y * 0.3, size.x * 0.56, size.y * 0.62)
			text_rect = Rect2(size.x * 0.06, size.y * 0.04, size.x * 0.88, size.y * 0.26)
		1:  # ürün sağda, slogan solda
			prod_rect = Rect2(size.x * 0.48, size.y * 0.1, size.x * 0.5, size.y * 0.8)
			text_rect = Rect2(size.x * 0.05, size.y * 0.12, size.x * 0.44, size.y * 0.6)
		_:  # ürün solda, slogan sağda
			prod_rect = Rect2(size.x * 0.02, size.y * 0.1, size.x * 0.5, size.y * 0.8)
			text_rect = Rect2(size.x * 0.51, size.y * 0.12, size.x * 0.45, size.y * 0.6)
	var fx_tex: Texture2D = tex("effects", str(draft.get("fx", "")))
	var prod_tex: Texture2D = tex("products", str(draft.get("product", "")))
	if prod_tex != null:
		parent.add_child(_image(prod_tex, prod_rect, TextureRect.STRETCH_KEEP_ASPECT_CENTERED))
	else:
		# Sektörün görseli yoksa: marka baş harfi büyük bir dairede.
		_text(parent, brand.substr(0, 1).to_upper(), unit * 0.4, accent, prod_rect)
	if fx_tex != null:
		var fx: TextureRect = _image(fx_tex, prod_rect.grow(unit * 0.08), TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
		parent.add_child(fx)
	var slogan: String = TranslationServer.translate(str(draft.get("slogan", "KV_SLOGAN_1"))).format({"brand": brand})
	_text(parent, slogan, unit * (0.085 if layout == 0 else 0.075), CozyTheme.TEXT, text_rect)
	var chip: ColorRect = ColorRect.new()
	chip.color = accent
	chip.position = Vector2(size.x * 0.04, size.y * 0.85)
	chip.size = Vector2(size.x * 0.5, size.y * 0.11)
	parent.add_child(chip)
	_text(parent, brand.to_upper(), unit * 0.05, CozyTheme.CREAM_LIGHT, Rect2(chip.position, chip.size))


static func _image(t: Texture2D, rect: Rect2, mode: int) -> TextureRect:
	var r: TextureRect = TextureRect.new()
	r.texture = t
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = mode
	r.position = rect.position
	r.size = rect.size
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


static func _text(parent: Node, text: String, font_size: float, color: Color, rect: Rect2) -> void:
	var l: Label = Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", maxi(8, int(font_size)))
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_override("font", CozyTheme.title_font(700))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	# Boyut ağaca girdikten sonra: satır kaydırma bu genişliğe göre yapılır.
	l.custom_minimum_size = Vector2(rect.size.x, 0.0)
	l.position = rect.position
	l.size = rect.size
