class_name UiUtil
extends RefCounted
## Arayüz yardımcıları: palet (GDD 21.1), biçimlendirme, sık kullanılan kontroller.

const CREAM: Color = Color(0.961, 0.933, 0.863)
const CARD: Color = Color(0.988, 0.969, 0.925)
const SAGE: Color = Color(0.357, 0.498, 0.404)
const SAGE_DARK: Color = Color(0.235, 0.345, 0.275)
const WOOD: Color = Color(0.651, 0.486, 0.322)
const TERRACOTTA: Color = Color(0.784, 0.4, 0.29)
const MUSTARD: Color = Color(0.851, 0.643, 0.255)
const TEXT: Color = Color(0.23, 0.21, 0.19)
const MUTED: Color = Color(0.48, 0.45, 0.41)


static func label(text: String, size: int = 16, color: Color = TEXT) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func wrapped(text: String, size: int = 15, color: Color = TEXT, min_width: float = 200.0) -> Label:
	var l: Label = label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = min_width
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


static func heading(text: String) -> Label:
	return label(text, 22, SAGE_DARK)


static func button(text: String, on_press: Callable) -> Button:
	var b: Button = Button.new()
	b.text = text
	b.pressed.connect(func() -> void: Audio.play("click"))
	b.pressed.connect(on_press)
	add_hover(b)
	return b


## Üzerine gelince hafifçe büyüme (M9-B "juice"); yalnızca görüntü, yerleşimi bozmaz.
static func add_hover(c: Control) -> void:
	var s: float = float(DataDB.data.sounds["juice"]["hover_scale"]) if DataDB.is_ok() else 1.0
	c.mouse_entered.connect(func() -> void:
		c.pivot_offset = c.size * 0.5
		c.create_tween().tween_property(c, "scale", Vector2.ONE * s, 0.08))
	c.mouse_exited.connect(func() -> void: c.create_tween().tween_property(c, "scale", Vector2.ONE, 0.08))


## CheckBox/CheckButton tema gereği düğme zeminini miras alır; düz ve okunaklı yapar.
static func style_toggle(toggle: BaseButton, pressed_color: Color = SAGE_DARK) -> void:
	toggle.flat = true
	for state: String in ["font_color", "font_hover_color", "font_focus_color"]:
		toggle.add_theme_color_override(state, TEXT)
	toggle.add_theme_color_override("font_pressed_color", pressed_color)
	toggle.add_theme_color_override("font_hover_pressed_color", pressed_color)


## Tedarikçi teklifinin / anlaşmasının açıklaması.
static func supplier_offer_text(offer: Dictionary) -> String:
	var pct: int = int(roundf(float(offer["discount"]) * 100.0))
	if offer["type"] == "volume":
		return tr_fmt("UI_OFFER_VOLUME", [int(offer["min_quantity"]), pct, int(offer["duration_weeks"])])
	return tr_fmt("UI_OFFER_ANNUAL", [int(offer["commit_quantity"]), pct])


static func card() -> PanelContainer:
	return PanelContainer.new()


static func vbox(separation: int = 8) -> VBoxContainer:
	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", separation)
	return v


static func hbox(separation: int = 10) -> HBoxContainer:
	var h: HBoxContainer = HBoxContainer.new()
	h.add_theme_constant_override("separation", separation)
	return h


static func spacer() -> Control:
	var c: Control = Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c


static func clear(node: Node) -> void:
	for child: Node in node.get_children():
		node.remove_child(child)
		child.queue_free()


## ₺1.234.567 (TR) / ₺1,234,567 (EN)
static func money(value: float) -> String:
	var negative: bool = value < 0.0
	var digits: String = str(absi(int(roundf(value))))
	var sep: String = "." if TranslationServer.get_locale().begins_with("tr") else ","
	var out: String = ""
	var count: int = 0
	for i: int in range(digits.length() - 1, -1, -1):
		out = digits[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = sep + out
	return ("-₺" if negative else "₺") + out


static func big_number(value: float) -> String:
	if value >= 1000000.0:
		return "%.1fM" % (value / 1000000.0)
	if value >= 1000.0:
		return "%.1fK" % (value / 1000.0)
	return str(int(roundf(value)))


static func score_color(score: float) -> Color:
	if score >= 8.0:
		return SAGE
	if score < 5.0:
		return TERRACOTTA
	return MUSTARD


static func date_text(clock: SimClock) -> String:
	return tr_fmt("FMT_DATE", [clock.year(), clock.month(), clock.week_in_month(), clock.game_year()])


## Metin argümanları da çevrilir: simülasyon rakip/ödül adlarını anahtar olarak gönderir (anahtar olmayan metin aynen kalır).
static func tr_fmt(key: String, args: Array) -> String:
	if args.is_empty():
		return TranslationServer.translate(key)
	var shown: Array = []
	for a: Variant in args:
		shown.append(TranslationServer.translate(a) if a is String else a)
	return TranslationServer.translate(key) % shown


static func t(key: String) -> String:
	return TranslationServer.translate(key)


## Veri kaydının görünen adı (name_key üzerinden).
static func name_of(table: Dictionary, id: String) -> String:
	if not table.has(id):
		return id
	return t(str(table[id]["name_key"]))


## Modal pencere iskeleti: root'un içine karartılmış arka plan + ortada kaydırılabilir kart kurar.
## Dönüş: içeriğin ekleneceği kutu.
static func modal_frame(root: Control, min_size: Vector2) -> VBoxContainer:
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.1, 0.09, 0.08, 0.55)
	root.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center: CenterContainer = CenterContainer.new()
	root.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel: PanelContainer = card()
	panel.custom_minimum_size = min_size
	center.add_child(panel)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(min_size.x - 30.0, minf(min_size.y, 640.0))
	panel.add_child(scroll)
	var content: VBoxContainer = vbox(10)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	return content
