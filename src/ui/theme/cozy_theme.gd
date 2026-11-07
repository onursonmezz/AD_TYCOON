class_name CozyTheme
extends RefCounted
## "Cozy Refined" UI teması (UI-1, Orgo'nun tasarım rehberi: krem paneller, orman yeşili, turuncu birincil eylem).
## Sıcak, ince çerçeveli, hafif gölgeli; gradyan, kabartma ve kalın çerçeve yok.
## UI-2: proje teması (tools/build_theme.gd bunu src/ui/theme/main_theme.tres olarak kaydeder). Başlıklar serif
## (Fraunces), gövde ve düğmeler Nunito. Pencereler: üstte yeşil başlık bandı (UiUtil.window_frame).
##
## Tür varyasyonları (theme_type_variation):
##   Paneller: QuietPanel (iç panel), Card (kart), StatCard (büyük sayı kartı)
##   Düğmeler: PrimaryButton (turuncu, ekranda az), QuietButton (çerçevesiz metin düğmesi)
##   Etiketler: TitleLabel, SectionHeading, MutedLabel, StatValue, StatLabel, PositiveLabel, NegativeLabel
##   Eski adlar da tanımlı (AcceptButton, WaitButton, DeclineButton, IconButton, IconButtonActive, CloseButton,
##   CardLight, HeaderStrip, Badge, Toast, DarkPill) ki bu temaya geçen ekranlarda eski görünüm karışmasın.

const FOREST: Color = Color("#304F40")
const FOREST_LIGHT: Color = Color("#416B55")
const SAGE: Color = Color("#8DAA8E")
const SAGE_SOFT: Color = Color("#DCE6D6")
const CREAM: Color = Color("#F5EBD9")
const CREAM_LIGHT: Color = Color("#FFF8ED")
const ACCENT: Color = Color("#E98A24")
const ACCENT_HOVER: Color = Color("#F1A448")
const ACCENT_PRESSED: Color = Color("#D47719")
const BORDER: Color = Color("#D7CDBA")
const TEXT: Color = Color("#283C32")
const MUTED: Color = Color("#718076")
const POSITIVE: Color = Color("#3F7A4E")
const NEGATIVE: Color = Color("#B4533A")
const WOOD: Color = Color("#8A6440")  # ikincil etiket (sıcak kahve)
const GOLD: Color = Color("#D9A441")  # yıldız, taç, ödül vurgusu
const SHADOW: Color = Color(0.09, 0.15, 0.12, 0.12)

## Boşluk ritmi (README: 8/12/16/24/32) ve köşe yarıçapları.
const SPACE_S: int = 8
const SPACE_M: int = 12
const SPACE_L: int = 16
const SPACE_XL: int = 24
const RADIUS_MODAL: int = 14
const RADIUS_CARD: int = 10
const RADIUS_CONTROL: int = 8

static var _theme: Theme = null

const FONT_TITLE: String = "res://assets/fonts/Fraunces.ttf"  # serif başlık (OFL), değişken: wght, opsz, SOFT


## Paylaşılan tema (bir kez kurulur).
static func get_theme() -> Theme:
	if _theme == null:
		_theme = build()
	return _theme


static func box(fill: Color, radius: int = RADIUS_CONTROL, border_color: Color = Color.TRANSPARENT, border_width: int = 0,
		shadow: bool = false, margin: Vector2 = Vector2(SPACE_M, SPACE_S)) -> StyleBoxFlat:
	var b: StyleBoxFlat = StyleBoxFlat.new()
	b.bg_color = fill
	b.draw_center = fill.a > 0.0
	b.set_corner_radius_all(radius)
	b.set_border_width_all(border_width)
	b.border_color = border_color
	b.content_margin_left = margin.x
	b.content_margin_right = margin.x
	b.content_margin_top = margin.y
	b.content_margin_bottom = margin.y
	b.anti_aliasing = true
	b.corner_detail = 8
	if shadow:
		b.shadow_color = SHADOW
		b.shadow_size = 6
		b.shadow_offset = Vector2(0, 3)
	return b


## Serif başlık fontu (pencere başlıkları, logo, bölüm başlıkları).
static func title_font(weight: int = 620) -> FontVariation:
	var f: FontVariation = FontVariation.new()
	f.base_font = load(FONT_TITLE) as FontFile
	var ts: TextServer = TextServerManager.get_primary_interface()
	f.variation_opentype = {ts.name_to_tag("wght"): weight, ts.name_to_tag("opsz"): 48, ts.name_to_tag("SOFT"): 60}
	return f


## Kalın gövde fontu (düğmeler, kart başlıkları, sayılar). Fredoka "ş" çengelini harften ayrık çiziyor.
static func strong_font(weight: int = 760) -> FontVariation:
	return UiTheme.font(UiTheme.FONT_BODY, weight)


static func build() -> Theme:
	var t: Theme = Theme.new()
	t.default_font = UiTheme.body_font()
	t.default_font_size = 16
	var head: FontVariation = title_font()
	_panels(t)
	_buttons(t, head)
	_labels(t, head)
	_inputs(t)
	_bars(t)
	_toggles(t)
	_tabs(t, head)
	return t


static func _panels(t: Theme) -> void:
	var modal: StyleBoxFlat = box(CREAM, RADIUS_MODAL, BORDER, 1, true, Vector2(SPACE_XL, SPACE_XL))
	t.set_stylebox("panel", "Panel", modal)
	t.set_stylebox("panel", "PanelContainer", modal)
	t.set_stylebox("panel", "PopupPanel", modal)
	# Pencere: kenar boşluğu yok; üstte yeşil başlık bandı, altta içerik (UiUtil.window_frame).
	t.set_type_variation("WindowPanel", "PanelContainer")
	var win: StyleBoxFlat = box(CREAM, RADIUS_MODAL, BORDER, 1, true, Vector2.ZERO)
	t.set_stylebox("panel", "WindowPanel", win)
	t.set_type_variation("HeaderBand", "PanelContainer")
	var band: StyleBoxFlat = box(FOREST, RADIUS_MODAL, Color.TRANSPARENT, 0, false, Vector2(SPACE_XL, SPACE_M))
	band.corner_radius_bottom_left = 0
	band.corner_radius_bottom_right = 0
	band.expand_margin_left = 1.0
	band.expand_margin_right = 1.0
	band.expand_margin_top = 1.0
	t.set_stylebox("panel", "HeaderBand", band)
	var quiet: StyleBoxFlat = box(CREAM_LIGHT, RADIUS_CONTROL, BORDER, 1, false, Vector2(SPACE_L, SPACE_M))
	var card: StyleBoxFlat = box(CREAM_LIGHT, RADIUS_CARD, BORDER, 1, false, Vector2(SPACE_L, SPACE_M))
	for v: Array in [["QuietPanel", quiet], ["Card", card], ["CardLight", card],
			["StatCard", box(CREAM_LIGHT, RADIUS_CARD, BORDER, 1, false, Vector2(SPACE_L, SPACE_M))],
			["HeaderStrip", box(SAGE_SOFT, RADIUS_CONTROL, Color.TRANSPARENT, 0, false, Vector2(SPACE_L, SPACE_S))],
			["Badge", box(CREAM_LIGHT, 999, BORDER, 1, false, Vector2(SPACE_M, 4))],
			["Toast", box(CREAM_LIGHT, RADIUS_CARD, BORDER, 1, true, Vector2(SPACE_L, SPACE_M))],
			["DarkPill", box(FOREST, 999, Color.TRANSPARENT, 0, false, Vector2(SPACE_M, 4))]]:
		t.set_type_variation(v[0], "PanelContainer")
		t.set_stylebox("panel", v[0], v[1])
	var sep: StyleBoxLine = StyleBoxLine.new()
	sep.color = BORDER
	sep.thickness = 1
	t.set_stylebox("separator", "HSeparator", sep)
	t.set_constant("separation", "HSeparator", SPACE_M)


## Düğme durumları; renkler [normal, hover, pressed] arka plan, çerçeve, yazı.
static func _button(t: Theme, type: String, fills: Array, border: Color, text: Color, pressed_text: Color,
		margin: Vector2 = Vector2(SPACE_L, 10)) -> void:
	var bw: int = 1 if border.a > 0.0 else 0
	t.set_stylebox("normal", type, box(fills[0], RADIUS_CONTROL, border, bw, false, margin))
	t.set_stylebox("hover", type, box(fills[1], RADIUS_CONTROL, FOREST_LIGHT if bw > 0 else border, bw, false, margin))
	t.set_stylebox("pressed", type, box(fills[2], RADIUS_CONTROL, FOREST_LIGHT if bw > 0 else border, bw, false, margin))
	t.set_stylebox("hover_pressed", type, t.get_stylebox("pressed", type))
	t.set_stylebox("disabled", type, box(CREAM, RADIUS_CONTROL, BORDER, 1, false, margin))
	t.set_stylebox("focus", type, box(Color.TRANSPARENT, RADIUS_CONTROL + 1, FOREST, 2, false, margin))
	for st: String in ["font_color", "font_hover_color", "font_focus_color"]:
		t.set_color(st, type, text)
	t.set_color("font_pressed_color", type, pressed_text)
	t.set_color("font_hover_pressed_color", type, pressed_text)
	t.set_color("font_disabled_color", type, MUTED)
	for st: String in ["icon_normal_color", "icon_hover_color", "icon_focus_color"]:
		t.set_color(st, type, text)
	t.set_color("icon_pressed_color", type, pressed_text)
	t.set_color("icon_disabled_color", type, MUTED)


static func _buttons(t: Theme, _head: FontVariation) -> void:
	t.set_font("font", "Button", strong_font())
	t.set_font_size("font_size", "Button", 16)
	_button(t, "Button", [CREAM_LIGHT, CREAM, SAGE], BORDER, TEXT, TEXT)
	for v: String in ["PrimaryButton", "AcceptButton"]:
		t.set_type_variation(v, "Button")
		_button(t, v, [ACCENT, ACCENT_HOVER, ACCENT_PRESSED], Color.TRANSPARENT, TEXT, Color.WHITE)
	t.set_type_variation("WaitButton", "Button")
	_button(t, "WaitButton", [CREAM_LIGHT, CREAM, SAGE], BORDER, TEXT, TEXT)
	t.set_type_variation("DeclineButton", "Button")
	_button(t, "DeclineButton", [CREAM_LIGHT, CREAM, CREAM], BORDER, NEGATIVE, NEGATIVE)
	t.set_type_variation("QuietButton", "Button")
	_button(t, "QuietButton", [Color.TRANSPARENT, SAGE_SOFT, SAGE], Color.TRANSPARENT, MUTED, TEXT)
	t.set_type_variation("IconButton", "Button")
	_button(t, "IconButton", [FOREST, FOREST_LIGHT, FOREST], Color.TRANSPARENT, CREAM_LIGHT, CREAM_LIGHT,
		Vector2(SPACE_M, SPACE_M))
	t.set_type_variation("IconButtonActive", "Button")
	_button(t, "IconButtonActive", [ACCENT, ACCENT_HOVER, ACCENT_PRESSED], Color.TRANSPARENT, TEXT, Color.WHITE,
		Vector2(SPACE_M, SPACE_M))
	# Kapatma: başlık bandında, yeşil üstünde krem çarpı; üzerine gelince hafif açık daire.
	t.set_type_variation("CloseButton", "Button")
	var cm: Vector2 = Vector2(6, 6)
	t.set_stylebox("normal", "CloseButton", box(Color.TRANSPARENT, 999, Color.TRANSPARENT, 0, false, cm))
	t.set_stylebox("hover", "CloseButton", box(FOREST_LIGHT, 999, Color.TRANSPARENT, 0, false, cm))
	t.set_stylebox("pressed", "CloseButton", box(FOREST_LIGHT.lightened(0.1), 999, Color.TRANSPARENT, 0, false, cm))
	t.set_stylebox("hover_pressed", "CloseButton", t.get_stylebox("pressed", "CloseButton"))
	t.set_stylebox("focus", "CloseButton", box(Color.TRANSPARENT, 999, ACCENT, 2, false, cm))
	for st: String in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
		t.set_color(st, "CloseButton", CREAM_LIGHT)


static func _label(t: Theme, type: String, color: Color, size: int, font: Font = null) -> void:
	t.set_type_variation(type, "Label")
	t.set_color("font_color", type, color)
	t.set_font_size("font_size", type, size)
	if font != null:
		t.set_font("font", type, font)


static func _labels(t: Theme, head: FontVariation) -> void:
	t.set_color("font_color", "Label", TEXT)
	t.set_font_size("font_size", "Label", 16)
	_label(t, "TitleLabel", FOREST, 44, head)
	_label(t, "SectionHeading", FOREST, 24, head)
	_label(t, "CardHeading", FOREST, 18, strong_font(800))
	_label(t, "WindowTitle", CREAM_LIGHT, 26, head)
	_label(t, "MutedLabel", MUTED, 14)
	_label(t, "StatValue", TEXT, 26, strong_font(800))
	_label(t, "StatLabel", MUTED, 13)
	_label(t, "PositiveLabel", POSITIVE, 16)
	_label(t, "NegativeLabel", NEGATIVE, 16)
	t.set_color("default_color", "RichTextLabel", TEXT)
	t.set_color("font_color", "TooltipLabel", CREAM_LIGHT)
	t.set_stylebox("panel", "TooltipPanel", box(FOREST, RADIUS_CONTROL, Color.TRANSPARENT, 0, false, Vector2(SPACE_M, SPACE_S)))


static func _inputs(t: Theme) -> void:
	var field: StyleBoxFlat = box(CREAM_LIGHT, RADIUS_CONTROL, BORDER, 1, false, Vector2(SPACE_M, SPACE_S))
	t.set_stylebox("normal", "LineEdit", field)
	t.set_stylebox("read_only", "LineEdit", field)
	t.set_stylebox("focus", "LineEdit", box(Color.TRANSPARENT, RADIUS_CONTROL, FOREST, 2, false, Vector2(SPACE_M, SPACE_S)))
	t.set_color("font_color", "LineEdit", TEXT)
	t.set_color("font_placeholder_color", "LineEdit", MUTED)
	t.set_color("caret_color", "LineEdit", FOREST)
	t.set_color("selection_color", "LineEdit", Color(SAGE, 0.5))
	# Açılır seçim: ikincil düğme gibi, sağda ok.
	_button(t, "OptionButton", [CREAM_LIGHT, CREAM, CREAM], BORDER, TEXT, TEXT, Vector2(SPACE_M, 10))
	t.set_font("font", "OptionButton", t.default_font)
	t.set_icon("arrow", "OptionButton", _arrow_icon())
	t.set_stylebox("panel", "PopupMenu", box(CREAM_LIGHT, RADIUS_CONTROL, BORDER, 1, true, Vector2(4, 4)))
	t.set_stylebox("hover", "PopupMenu", box(SAGE_SOFT, 6, Color.TRANSPARENT, 0, false, Vector2(SPACE_S, 4)))
	t.set_color("font_color", "PopupMenu", TEXT)
	t.set_color("font_hover_color", "PopupMenu", TEXT)
	t.set_color("font_disabled_color", "PopupMenu", MUTED)
	t.set_icon("radio_checked", "PopupMenu", _check_icon(true, true))
	t.set_icon("radio_unchecked", "PopupMenu", _check_icon(false, true))
	t.set_icon("checked", "PopupMenu", _check_icon(true, false))
	t.set_icon("unchecked", "PopupMenu", _check_icon(false, false))


static func _bars(t: Theme) -> void:
	t.set_stylebox("background", "ProgressBar", box(CREAM, 6, BORDER, 1, false, Vector2.ZERO))
	t.set_stylebox("fill", "ProgressBar", box(FOREST_LIGHT, 6, Color.TRANSPARENT, 0, false, Vector2.ZERO))
	t.set_color("font_color", "ProgressBar", TEXT)
	var rail: StyleBoxFlat = box(BORDER, 4, Color.TRANSPARENT, 0, false, Vector2(0, 3))
	t.set_stylebox("slider", "HSlider", rail)
	t.set_stylebox("grabber_area", "HSlider", box(FOREST_LIGHT, 4, Color.TRANSPARENT, 0, false, Vector2(0, 3)))
	t.set_stylebox("grabber_area_highlight", "HSlider", box(FOREST, 4, Color.TRANSPARENT, 0, false, Vector2(0, 3)))
	t.set_icon("grabber", "HSlider", _dot_icon(FOREST_LIGHT))
	t.set_icon("grabber_highlight", "HSlider", _dot_icon(FOREST))
	for sb: String in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("scroll", sb, box(Color(BORDER, 0.35), 4, Color.TRANSPARENT, 0, false, Vector2(3, 3)))
		t.set_stylebox("grabber", sb, box(SAGE, 4, Color.TRANSPARENT, 0, false, Vector2(3, 3)))
		t.set_stylebox("grabber_highlight", sb, box(FOREST_LIGHT, 4, Color.TRANSPARENT, 0, false, Vector2(3, 3)))
		t.set_stylebox("grabber_pressed", sb, box(FOREST, 4, Color.TRANSPARENT, 0, false, Vector2(3, 3)))


static func _toggles(t: Theme) -> void:
	for cb: String in ["CheckBox", "CheckButton"]:
		for st: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
			t.set_color(st, cb, TEXT)
		t.set_color("font_disabled_color", cb, MUTED)
		for st: String in ["normal", "pressed", "disabled", "hover_pressed"]:
			t.set_stylebox(st, cb, StyleBoxEmpty.new())
		t.set_stylebox("hover", cb, box(SAGE_SOFT, 6, Color.TRANSPARENT, 0, false, Vector2(4, 2)))
		t.set_stylebox("focus", cb, box(Color.TRANSPARENT, 6, FOREST, 2, false, Vector2(4, 2)))
	t.set_icon("checked", "CheckBox", _check_icon(true, false))
	t.set_icon("unchecked", "CheckBox", _check_icon(false, false))
	t.set_icon("radio_checked", "CheckBox", _check_icon(true, true))
	t.set_icon("radio_unchecked", "CheckBox", _check_icon(false, true))


static func _tabs(t: Theme, _head: FontVariation) -> void:
	var m: Vector2 = Vector2(SPACE_L, SPACE_S)
	for type: String in ["TabBar", "TabContainer"]:
		t.set_stylebox("tab_selected", type, box(CREAM_LIGHT, RADIUS_CONTROL, BORDER, 1, false, m))
		t.set_stylebox("tab_unselected", type, box(CREAM, RADIUS_CONTROL, Color.TRANSPARENT, 0, false, m))
		t.set_stylebox("tab_hovered", type, box(SAGE_SOFT, RADIUS_CONTROL, Color.TRANSPARENT, 0, false, m))
		t.set_stylebox("tab_disabled", type, box(CREAM, RADIUS_CONTROL, Color.TRANSPARENT, 0, false, m))
		t.set_color("font_selected_color", type, FOREST)
		t.set_color("font_unselected_color", type, MUTED)
		t.set_color("font_hovered_color", type, TEXT)
		t.set_font("font", type, strong_font())
	t.set_stylebox("panel", "TabContainer", box(CREAM_LIGHT, RADIUS_CONTROL, BORDER, 1, false, Vector2(SPACE_L, SPACE_M)))


# --- kodla çizilen küçük ikonlar (onay kutusu, ok, kaydırıcı tutamağı) --------------------------------

const ICON_PX: int = 18


## Kenarı yumuşatılmış daire ya da yuvarlak kare; seçiliyse dolu ve ortasında işaret.
static func _check_icon(checked: bool, radio: bool) -> ImageTexture:
	var n: int = ICON_PX
	var img: Image = Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c: Vector2 = Vector2(n, n) * 0.5
	for y: int in n:
		for x: int in n:
			var p: Vector2 = Vector2(x + 0.5, y + 0.5) - c
			var d: float = p.length() - (n * 0.5 - 1.0) if radio else _round_rect_dist(p, n * 0.5 - 1.0, 4.0)
			var col: Color = Color.TRANSPARENT
			if checked:
				col = Color(FOREST, clampf(0.5 - d, 0.0, 1.0))
			else:
				var fill: Color = CREAM_LIGHT
				var edge: float = clampf(1.0 - absf(d + 0.75), 0.0, 1.0)
				col = Color(fill.lerp(MUTED, edge), clampf(0.5 - d, 0.0, 1.0))
			img.set_pixel(x, y, col)
	if checked:
		if radio:
			for y: int in n:
				for x: int in n:
					var d2: float = (Vector2(x + 0.5, y + 0.5) - c).length() - 3.5
					if d2 < 0.5:
						img.set_pixel(x, y, CREAM_LIGHT.lerp(FOREST, clampf(d2 + 0.5, 0.0, 1.0)))
		else:
			_stroke(img, [Vector2(4.5, 9.5), Vector2(7.5, 12.5), Vector2(13.5, 5.5)], CREAM_LIGHT, 1.4)
	return ImageTexture.create_from_image(img)


static func _round_rect_dist(p: Vector2, half: float, r: float) -> float:
	var q: Vector2 = Vector2(absf(p.x), absf(p.y)) - Vector2(half - r, half - r)
	return Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0) - r


## Kırık çizgi (onay işareti, ok); kalınlık piksel.
static func _stroke(img: Image, pts: Array, col: Color, width: float) -> void:
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


static func _arrow_icon() -> ImageTexture:
	var img: Image = Image.create(14, 14, false, Image.FORMAT_RGBA8)
	_stroke(img, [Vector2(3.5, 5.5), Vector2(7.0, 9.0), Vector2(10.5, 5.5)], MUTED, 1.1)
	return ImageTexture.create_from_image(img)


static func _dot_icon(col: Color) -> ImageTexture:
	var n: int = ICON_PX
	var img: Image = Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c: Vector2 = Vector2(n, n) * 0.5
	for y: int in n:
		for x: int in n:
			var d: float = (Vector2(x + 0.5, y + 0.5) - c).length()
			var inner: float = clampf(n * 0.5 - 3.0 - d + 0.5, 0.0, 1.0)
			var outer: float = clampf(n * 0.5 - 1.0 - d + 0.5, 0.0, 1.0)
			img.set_pixel(x, y, Color(CREAM_LIGHT.lerp(col, inner), outer))
	return ImageTexture.create_from_image(img)
