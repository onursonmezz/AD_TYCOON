class_name MenuArt
extends RefCounted
## Açılış sayfalarının ortak parçaları (A1): oda illüstrasyonu arka planı, logo, eğik kâğıt başlık etiketi,
## çerçeveli portre / avatar resmi. Görseller assets/ui altında; dosya yoksa sade yer tutucu çizilir.

const BACKGROUND: String = "res://assets/ui/menu_background"  # .png, .jpg ya da .webp
const AVATARS: String = "res://assets/ui/avatars"
const PORTRAITS: String = "res://assets/ui/portraits"
const ITALIC: Transform2D = Transform2D(Vector2(1.0, 0.18), Vector2(0.0, 1.0), Vector2.ZERO)


## Ana menü illüstrasyonu; yoksa null.
static func texture() -> Texture2D:
	for ext: String in ["webp", "png", "jpg"]:
		var path: String = "%s.%s" % [BACKGROUND, ext]
		if ResourceLoader.exists(path):
			return load(path) as Texture2D
	return null


## Tam ekran arka plan. zoom > 0: resim sola ve aşağı taşırılır, sağdaki boş duvar genişler (form sayfaları için).
static func backdrop(zoom: float = 0.0) -> Control:
	var root: Control = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.clip_contents = true
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var bg: ColorRect = ColorRect.new()
	bg.color = CozyTheme.FOREST
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var tex: Texture2D = texture()
	if tex != null:
		var art: TextureRect = TextureRect.new()
		art.texture = tex
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.anchor_left = -zoom
		art.anchor_top = 0.0
		art.anchor_right = 1.0
		art.anchor_bottom = 1.0 + zoom
		root.add_child(art)
	else:
		bg.color = CozyTheme.CREAM
	return root


## Eğik yazılı serif logo fontu.
static func logo_font() -> FontVariation:
	var f: FontVariation = CozyTheme.title_font()
	var it: FontVariation = CozyTheme.italic_of(f)
	if it != null:
		return it
	f.variation_transform = ITALIC
	return f


static func logo_label(text: String, size: int) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_override("font", logo_font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", CozyTheme.FOREST)
	return l


## Hafif eğik krem kâğıt etiket içinde başlık (referanstaki "Sen Kimsin?" bandı).
static func tape(text: String, icon_name: String = "", size: int = 34, tilt: float = -1.5) -> Control:
	var holder: HBoxContainer = HBoxContainer.new()
	var tag: PanelContainer = PanelContainer.new()
	tag.add_theme_stylebox_override("panel", CozyTheme.box(CozyTheme.CREAM, 4, CozyTheme.BORDER, 1, true,
		Vector2(CozyTheme.SPACE_XL, 6)))
	holder.add_child(tilted(tag, tilt))
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", CozyTheme.SPACE_M)
	tag.add_child(row)
	if not icon_name.is_empty():
		row.add_child(UiUtil.icon(icon_name, size, CozyTheme.FOREST))
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_override("font", CozyTheme.title_font(800))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", CozyTheme.FOREST)
	row.add_child(l)
	return holder


## Çerçeveli resim: dosya varsa kutuyu doldurur, yoksa ortada soluk bir ikon.
static func picture(path: String, min_size: Vector2, fallback_icon: String = "user") -> PanelContainer:
	var box: PanelContainer = PanelContainer.new()
	box.add_theme_stylebox_override("panel", CozyTheme.box(CozyTheme.CREAM, 10, CozyTheme.BORDER, 1, false, Vector2(4, 4)))
	box.custom_minimum_size = min_size
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex: TextureRect = TextureRect.new()
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	if ResourceLoader.exists(path):
		tex.texture = load(path) as Texture2D
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	else:
		tex.texture = UiUtil.icon_texture(fallback_icon, int(minf(min_size.x, min_size.y) * 0.5))
		tex.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		tex.modulate = CozyTheme.SAGE
	box.add_child(tex)
	return box


static func avatar_path(id: String) -> String:
	return "%s/%s.png" % [AVATARS, id]


static func portrait_path(background_id: String) -> String:
	return "%s/%s.png" % [PORTRAITS, background_id]


## Bir parçayı hafif eğik gösterir. Kaplar çocuklarının dönüşünü sıfırladığı için parça düz bir Control'e konur.
static func tilted(child: Control, degrees: float) -> Control:
	var holder: Control = Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(child)
	var fit: Callable = func() -> void:
		var s: Vector2 = child.get_combined_minimum_size()
		holder.custom_minimum_size = s
		child.size = s
		child.pivot_offset = s * 0.5
		child.rotation_degrees = degrees
	child.minimum_size_changed.connect(fit)
	fit.call_deferred()
	return holder


## Bir fontun eğik (italik görünümlü) hâli.
static func italic(base: FontVariation) -> FontVariation:
	var it: FontVariation = CozyTheme.italic_of(base)
	if it != null:
		return it
	base.variation_transform = ITALIC
	return base
