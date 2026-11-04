class_name UiTheme
extends RefCounted
## UI kiti (G2, docs/art-direction.md 3.1, 8, 9): palet, fontlar ve Godot Theme'i tek yerden kurar.
## tools/build_theme.gd bunu src/ui/theme/main_theme.tres olarak kaydeder (proje teması). Renk değişince betiği
## yeniden çalıştır.
## Tür varyasyonları (theme_type_variation): AcceptButton, WaitButton, DeclineButton, IconButton, IconButtonActive,
## CloseButton, CardLight, HeaderStrip, Badge, Toast, DarkPill.

const PANEL: Color = Color("#CDE8C7")
const PANEL_LIGHT: Color = Color("#E4F3DF")
const PANEL_HEADER: Color = Color("#9DBFA4")
const FRAME: Color = Color("#3F6B52")
const FRAME_DARK: Color = Color("#2E4F3D")
const INK: Color = Color("#3A5646")
const INK_SOFT: Color = Color("#6D8A77")
const ON_DARK: Color = Color("#F1F7EC")
const ACCEPT: Color = Color("#8CCB52")
const ACCEPT_DARK: Color = Color("#5E9A34")
const WAIT: Color = Color("#A3A7A4")
const WAIT_DARK: Color = Color("#7D817E")
const DECLINE: Color = Color("#D2574A")
const DECLINE_DARK: Color = Color("#9E3A30")
const GOLD: Color = Color("#F2C230")
const GOLD_DARK: Color = Color("#C99A1C")
const SLATE: Color = Color("#4E6A61")
const SLATE_HOVER: Color = Color("#5F7E74")
const TOAST: Color = Color("#DCEFD6")
const SHADOW: Color = Color(0.118, 0.18, 0.145, 0.32)

const RADIUS_PANEL: int = 22
const RADIUS_PILL: int = 22
const FRAME_WIDTH: int = 5

const FONT_BODY: String = "res://assets/fonts/Nunito.ttf"
const FONT_HEAD: String = "res://assets/fonts/Fredoka.ttf"


static func font(path: String, weight: int) -> FontVariation:
	var base: FontFile = load(path) as FontFile
	var f: FontVariation = FontVariation.new()
	f.base_font = base
	var ts: TextServer = TextServerManager.get_primary_interface()
	f.variation_opentype = {ts.name_to_tag("wght"): weight}
	return f


static func body_font() -> FontVariation:
	return font(FONT_BODY, 650)


static func head_font() -> FontVariation:
	return font(FONT_HEAD, 560)


## Köşesi yuvarlak düz kutu; border_bottom > 0 ise altında "basılabilir" koyu kenar.
static func box(bg: Color, radius: int, border: int = 0, border_color: Color = Color.TRANSPARENT,
		margin: Vector4 = Vector4(14, 8, 14, 8), border_bottom: int = -1) -> StyleBoxFlat:
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.set_border_width_all(border)
	if border_bottom >= 0:
		s.border_width_bottom = border_bottom
	s.border_color = border_color
	s.content_margin_left = margin.x
	s.content_margin_top = margin.y
	s.content_margin_right = margin.z
	s.content_margin_bottom = margin.w
	s.anti_aliasing = true
	s.corner_detail = 10
	return s


static func panel_box() -> StyleBoxFlat:
	var s: StyleBoxFlat = box(PANEL, RADIUS_PANEL, FRAME_WIDTH, FRAME, Vector4(20, 18, 20, 18))
	s.shadow_color = SHADOW
	s.shadow_size = 10
	s.shadow_offset = Vector2(0, 6)
	return s


## Hap düğme: normal/hover/pressed/disabled/focus. Basınca alt kenar kaybolur, yazı 2 px iner.
static func _pill(t: Theme, type: String, bg: Color, edge: Color, text: Color) -> void:
	var m: Vector4 = Vector4(20, 8, 20, 8)
	t.set_stylebox("normal", type, box(bg, RADIUS_PILL, 0, edge, m, 4))
	t.set_stylebox("hover", type, box(bg.lightened(0.1), RADIUS_PILL, 0, edge, m, 4))
	t.set_stylebox("pressed", type, box(bg.darkened(0.05), RADIUS_PILL, 0, edge, Vector4(m.x, m.y + 3, m.z, m.w - 1), 1))
	t.set_stylebox("hover_pressed", type, t.get_stylebox("pressed", type))
	t.set_stylebox("disabled", type, box(WAIT.lerp(PANEL, 0.4), RADIUS_PILL, 0, WAIT_DARK, m, 4))
	var focus: StyleBoxFlat = box(Color.TRANSPARENT, RADIUS_PILL + 2, 2, GOLD, m)
	focus.draw_center = false
	t.set_stylebox("focus", type, focus)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		t.set_color(state, type, text)
	t.set_color("font_disabled_color", type, ON_DARK.darkened(0.15))
	t.set_color("icon_normal_color", type, text)
	t.set_color("icon_hover_color", type, text)
	t.set_color("icon_pressed_color", type, text)


static func build() -> Theme:
	var t: Theme = Theme.new()
	t.default_font = body_font()
	t.default_font_size = 16
	var head: FontVariation = head_font()
	# Paneller
	t.set_stylebox("panel", "PanelContainer", panel_box())
	t.set_stylebox("panel", "Panel", panel_box())
	t.set_type_variation("CardLight", "PanelContainer")
	t.set_stylebox("panel", "CardLight", box(PANEL_LIGHT, 16, 0, Color.TRANSPARENT, Vector4(14, 10, 14, 10)))
	t.set_type_variation("HeaderStrip", "PanelContainer")
	t.set_stylebox("panel", "HeaderStrip", box(PANEL_HEADER, 14, 0, Color.TRANSPARENT, Vector4(16, 8, 16, 8)))
	t.set_type_variation("Badge", "PanelContainer")
	t.set_stylebox("panel", "Badge", box(Color(GOLD, 0.95), RADIUS_PILL, 0, Color.TRANSPARENT, Vector4(40, 4, 18, 4)))
	t.set_type_variation("Toast", "PanelContainer")
	var toast: StyleBoxFlat = box(TOAST, 18, 3, FRAME, Vector4(16, 10, 18, 10))
	toast.shadow_color = SHADOW
	toast.shadow_size = 8
	toast.shadow_offset = Vector2(0, 4)
	t.set_stylebox("panel", "Toast", toast)
	t.set_type_variation("DarkPill", "PanelContainer")
	t.set_stylebox("panel", "DarkPill", box(SLATE, RADIUS_PILL, 0, Color.TRANSPARENT, Vector4(10, 4, 10, 4)))
	# Metin
	t.set_color("font_color", "Label", INK)
	t.set_color("font_color", "RichTextLabel", INK)
	t.set_color("default_color", "RichTextLabel", INK)
	# Düğmeler: varsayılan = koyu adaçayı ikincil; tür varyasyonları kabul/bekle/ret.
	t.set_font("font", "Button", head)
	t.set_font_size("font_size", "Button", 17)
	_pill(t, "Button", FRAME, FRAME_DARK, ON_DARK)
	for v: Array in [["AcceptButton", ACCEPT, ACCEPT_DARK, Color.WHITE], ["WaitButton", WAIT, WAIT_DARK, Color.WHITE],
			["DeclineButton", DECLINE, DECLINE_DARK, Color.WHITE]]:
		t.set_type_variation(v[0], "Button")
		_pill(t, v[0], v[1], v[2], v[3])
	t.set_type_variation("IconButton", "Button")
	var im: Vector4 = Vector4(12, 12, 12, 12)
	t.set_stylebox("normal", "IconButton", box(SLATE, 16, 0, FRAME_DARK, im, 4))
	t.set_stylebox("hover", "IconButton", box(SLATE_HOVER, 16, 0, FRAME_DARK, im, 4))
	t.set_stylebox("pressed", "IconButton", box(SLATE, 16, 0, FRAME_DARK, Vector4(12, 14, 12, 10), 1))
	t.set_stylebox("hover_pressed", "IconButton", t.get_stylebox("pressed", "IconButton"))
	t.set_stylebox("focus", "IconButton", StyleBoxEmpty.new())
	t.set_type_variation("IconButtonActive", "Button")
	t.set_stylebox("normal", "IconButtonActive", box(ACCEPT, 16, 0, ACCEPT_DARK, im, 4))
	t.set_stylebox("hover", "IconButtonActive", box(ACCEPT.lightened(0.1), 16, 0, ACCEPT_DARK, im, 4))
	t.set_stylebox("pressed", "IconButtonActive", box(ACCEPT, 16, 0, ACCEPT_DARK, Vector4(12, 14, 12, 10), 1))
	t.set_stylebox("focus", "IconButtonActive", StyleBoxEmpty.new())
	t.set_type_variation("CloseButton", "Button")
	var cm: Vector4 = Vector4(8, 6, 8, 6)
	t.set_stylebox("normal", "CloseButton", box(DECLINE, 20, 3, Color.WHITE, cm))
	t.set_stylebox("hover", "CloseButton", box(DECLINE.lightened(0.12), 20, 3, Color.WHITE, cm))
	t.set_stylebox("pressed", "CloseButton", box(DECLINE_DARK, 20, 3, Color.WHITE, cm))
	t.set_stylebox("focus", "CloseButton", StyleBoxEmpty.new())
	t.set_color("font_color", "CloseButton", Color.WHITE)
	t.set_color("font_hover_color", "CloseButton", Color.WHITE)
	# Giriş kutuları, seçim kutuları, açılır menü
	var field: StyleBoxFlat = box(PANEL_LIGHT, 14, 2, FRAME.lerp(PANEL, 0.4), Vector4(12, 6, 12, 6))
	t.set_stylebox("normal", "LineEdit", field)
	t.set_stylebox("focus", "LineEdit", box(Color.WHITE, 14, 2, FRAME, Vector4(12, 6, 12, 6)))
	t.set_stylebox("read_only", "LineEdit", field)
	t.set_color("font_color", "LineEdit", INK)
	t.set_color("font_placeholder_color", "LineEdit", INK_SOFT)
	t.set_color("caret_color", "LineEdit", FRAME)
	for st: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		var c: Color = PANEL_LIGHT if st != "hover" else Color.WHITE
		t.set_stylebox(st, "OptionButton", box(c if st != "disabled" else PANEL.darkened(0.05), 14, 2,
			FRAME.lerp(PANEL, 0.4) if st != "focus" else FRAME, Vector4(12, 6, 12, 6)))
	t.set_font("font", "OptionButton", t.default_font)
	t.set_font_size("font_size", "OptionButton", 16)
	for st: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(st, "OptionButton", INK)
	t.set_color("font_disabled_color", "OptionButton", INK_SOFT)
	t.set_stylebox("panel", "PopupMenu", box(PANEL_LIGHT, 14, 3, FRAME, Vector4(6, 6, 6, 6)))
	t.set_stylebox("hover", "PopupMenu", box(PANEL_HEADER, 10, 0, Color.TRANSPARENT, Vector4(8, 4, 8, 4)))
	t.set_color("font_color", "PopupMenu", INK)
	t.set_color("font_hover_color", "PopupMenu", Color.WHITE)
	t.set_stylebox("panel", "TooltipPanel", box(FRAME_DARK, 12, 0, Color.TRANSPARENT, Vector4(12, 8, 12, 8)))
	t.set_color("font_color", "TooltipLabel", ON_DARK)
	# İlerleme çubuğu, kaydırıcı, kaydırma çubuğu
	t.set_stylebox("background", "ProgressBar", box(PANEL_LIGHT, 12, 2, FRAME.lerp(PANEL, 0.5), Vector4(0, 0, 0, 0)))
	t.set_stylebox("fill", "ProgressBar", box(ACCEPT, 12, 0, Color.TRANSPARENT, Vector4(0, 0, 0, 0)))
	t.set_color("font_color", "ProgressBar", INK)
	t.set_stylebox("slider", "HSlider", box(PANEL_LIGHT.darkened(0.08), 6, 0, Color.TRANSPARENT, Vector4(0, 4, 0, 4)))
	t.set_stylebox("grabber_area", "HSlider", box(ACCEPT, 6, 0, Color.TRANSPARENT, Vector4(0, 4, 0, 4)))
	t.set_stylebox("grabber_area_highlight", "HSlider", box(ACCEPT.lightened(0.1), 6, 0, Color.TRANSPARENT, Vector4(0, 4, 0, 4)))
	for sb: String in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("scroll", sb, box(Color(FRAME, 0.12), 6, 0, Color.TRANSPARENT, Vector4(5, 5, 5, 5)))
		t.set_stylebox("grabber", sb, box(FRAME, 6, 0, Color.TRANSPARENT, Vector4(5, 5, 5, 5)))
		t.set_stylebox("grabber_highlight", sb, box(SLATE_HOVER, 6, 0, Color.TRANSPARENT, Vector4(5, 5, 5, 5)))
		t.set_stylebox("grabber_pressed", sb, box(FRAME_DARK, 6, 0, Color.TRANSPARENT, Vector4(5, 5, 5, 5)))
	# Onay kutuları
	for cb: String in ["CheckBox", "CheckButton"]:
		for st: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
			t.set_color(st, cb, INK)
		for st: String in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
			t.set_stylebox(st, cb, StyleBoxEmpty.new())
	# Sekmeler
	t.set_stylebox("tab_selected", "TabBar", box(ACCEPT, 14, 0, Color.TRANSPARENT, Vector4(16, 6, 16, 6)))
	t.set_stylebox("tab_unselected", "TabBar", box(PANEL_HEADER, 14, 0, Color.TRANSPARENT, Vector4(16, 6, 16, 6)))
	t.set_stylebox("tab_hovered", "TabBar", box(PANEL_HEADER.lightened(0.1), 14, 0, Color.TRANSPARENT, Vector4(16, 6, 16, 6)))
	t.set_color("font_selected_color", "TabBar", Color.WHITE)
	t.set_color("font_unselected_color", "TabBar", ON_DARK)
	t.set_font("font", "TabBar", head)
	return t
