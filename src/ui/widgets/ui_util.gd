class_name UiUtil
extends RefCounted
## Arayüz yardımcıları: palet (GDD 21.1), biçimlendirme, sık kullanılan kontroller.

## Eski adlar G2 paletine bağlı (UiTheme, docs/art-direction.md 3.1); ekranlar bu adları kullanmaya devam eder.
const CREAM: Color = UiTheme.PANEL_LIGHT
const CARD: Color = UiTheme.PANEL
const SAGE: Color = UiTheme.ACCEPT_DARK
const SAGE_DARK: Color = UiTheme.FRAME
const WOOD: Color = Color("#8A6440")
const TERRACOTTA: Color = UiTheme.DECLINE
const MUSTARD: Color = Color("#D9A441")
const TEXT: Color = UiTheme.INK
const MUTED: Color = UiTheme.INK_SOFT

static var _icon_cache: Dictionary = {}
static var _head_font: Font = null


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
	var l: Label = label(text, 24, SAGE_DARK)
	l.add_theme_font_override("font", head_font())
	return l


## Başlık fontu (Fredoka; sayılar, rozetler, başlıklar).
static func head_font() -> Font:
	if _head_font == null:
		_head_font = UiTheme.head_font()
	return _head_font


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


## İç kart (G2): açık nane, çerçevesiz; pencerelerin içindeki satırlar ve kutular.
static func card() -> PanelContainer:
	var p: PanelContainer = PanelContainer.new()
	p.theme_type_variation = "CardLight"
	return p


## Çerçeveli, gölgeli yüzen panel (G2): pencere, çalışan kartı, ipucu balonu.
static func panel() -> PanelContainer:
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
	dim.color = Color(0.08, 0.14, 0.1, 0.45)
	root.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center: CenterContainer = CenterContainer.new()
	root.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = min_size
	center.add_child(panel)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(min_size.x - 30.0, minf(min_size.y, 640.0))
	panel.add_child(scroll)
	var content: VBoxContainer = vbox(10)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	pop_in(panel)
	# Esc ile kapanan pencerelerde köşeye taşan kırmızı kapatma düğmesi (G2).
	if root.has_meta("esc_closes"):
		var close: Button = close_button(root.queue_free)
		root.add_child(close)
		var place: Callable = func() -> void:
			close.global_position = panel.global_position + Vector2(panel.size.x - 30.0, -12.0)
		panel.resized.connect(place)
		panel.item_rect_changed.connect(place)
	return content


## Yüzde, dile göre: Türkçe "%55", İngilizce "55%" (M9-C). decimals: ondalık; signed: "+" işareti.
static func percent(value_pct: float, decimals: int = 0, signed: bool = false) -> String:
	var num: String = ("%+." if signed else "%.") + str(decimals) + "f"
	var s: String = num % value_pct
	if TranslationServer.get_locale().begins_with("tr"):
		var sign: String = ""
		if s.begins_with("+") or s.begins_with("-"):
			sign = s.substr(0, 1)
			s = s.substr(1)
		return sign + "%" + s
	return s + "%"


# --- G2 UI kiti ---------------------------------------------------------------------

## assets/icons/ui/<ad>.svg'yi istenen piksel boyutunda çizer (beyaz; rengi modulate ile verilir). Önbellekli.
## Dışa aktarmada .svg dosyaları pakete dahil edilmeli (export filtresi "*.svg").
static func icon_texture(name: String, px: int) -> Texture2D:
	var key: String = "%s@%d" % [name, px]
	if _icon_cache.has(key):
		return _icon_cache[key]
	var text: String = FileAccess.get_file_as_string("res://assets/icons/ui/%s.svg" % name)
	var tex: Texture2D = null
	if not text.is_empty():
		var img: Image = Image.new()
		if img.load_svg_from_string(text, float(px) / 24.0) == OK:
			tex = ImageTexture.create_from_image(img)
	_icon_cache[key] = tex
	return tex


static func icon(name: String, px: int = 28, color: Color = Color.WHITE) -> TextureRect:
	var r: TextureRect = TextureRect.new()
	r.texture = icon_texture(name, px)
	r.custom_minimum_size = Vector2(px, px)
	r.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	r.modulate = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## Hap düğme türü: "accept" (yeşil kabul), "wait" (gri bekle), "decline" (kırmızı ret), "" (koyu ikincil).
static func button_kind(text: String, on_press: Callable, kind: String = "") -> Button:
	var b: Button = button(text, on_press)
	b.theme_type_variation = {"accept": "AcceptButton", "wait": "WaitButton", "decline": "DeclineButton"}.get(kind, "")
	return b


## Simgeli kare düğme (sol ikon çubuğu, hız kontrolleri).
static func icon_button(icon_name: String, tip: String, on_press: Callable, px: int = 30) -> Button:
	var b: Button = button("", on_press)
	b.icon = icon_texture(icon_name, px)
	b.theme_type_variation = "IconButton"
	b.tooltip_text = tip
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.expand_icon = false
	return b


## Panelin köşesine taşan kırmızı yuvarlak kapatma düğmesi.
static func close_button(on_press: Callable) -> Button:
	var b: Button = button("", on_press)
	b.icon = icon_texture("x", 22)
	b.theme_type_variation = "CloseButton"
	b.custom_minimum_size = Vector2(42, 42)
	b.tooltip_text = TranslationServer.translate("TIP_CLOSE_WINDOW")
	return b


## Açılış animasyonu: küçükten büyüyüp hafifçe zıplar, belirir (~0.25 sn; art-direction 10).
static func pop_in(c: Control) -> void:
	c.modulate.a = 0.0
	c.scale = Vector2.ONE * 0.86
	var t: Tween = c.create_tween().set_parallel(true)
	t.tween_callback(func() -> void: c.pivot_offset = c.size * 0.5)
	t.tween_property(c, "scale", Vector2.ONE, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(c, "modulate:a", 1.0, 0.14)
