class_name Cards
extends RefCounted
## Panel kartlarının ortak parçaları (C2): portre + başlık satırı, küçük etiket (chip), ikon karesi,
## tam adlı stat rozetleri, ince ölçer çubuğu. Paneller bunlarla kurulur ki hepsi aynı dili konuşsun.

const AVATAR_ASPECT: float = 0.89  # avatar resimleri 384×342


## Küçük hap etiket: durum, tür, süre. tip doluysa üzerine gelince açıklama çıkar.
static func chip(text: String, fill: Color = CozyTheme.SAGE_SOFT, color: Color = CozyTheme.FOREST, tip: String = "") -> PanelContainer:
	var p: PanelContainer = PanelContainer.new()
	p.add_theme_stylebox_override("panel", CozyTheme.box(fill, 999, Color.TRANSPARENT, 0, false, Vector2(10, 2)))
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.tooltip_text = tip
	var l: Label = UiUtil.label(text, 12, color)
	l.add_theme_font_override("font", CozyTheme.strong_font(800))
	p.add_child(l)
	return p


static func warn_chip(text: String, tip: String = "") -> PanelContainer:
	return chip(text, CozyTheme.NEGATIVE, CozyTheme.CREAM_LIGHT, tip)


static func accent_chip(text: String, tip: String = "") -> PanelContainer:
	return chip(text, CozyTheme.ACCENT_SOFT, CozyTheme.WOOD, tip)


## Yuvarlak köşeli ikon karesi (müşteri, brief, teklif kartlarının başında).
static func tile(icon_name: String, px: float = 44.0, fill: Color = CozyTheme.SAGE_SOFT) -> PanelContainer:
	var p: PanelContainer = PanelContainer.new()
	p.add_theme_stylebox_override("panel", CozyTheme.box(fill, 10, Color.TRANSPARENT, 0, false, Vector2.ZERO))
	p.custom_minimum_size = Vector2(px, px)
	p.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ic: TextureRect = UiUtil.icon(icon_name, int(px * 0.55), CozyTheme.FOREST)
	ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	p.add_child(ic)
	return p


## Çalışanın portresi: kurucuda seçtiği avatar; diğerlerinde cinsiyetine uyan avatarlardan kimliğine göre sabit biri.
## Yalnızca görünüş; simülasyona yazılmaz.
static func avatar_id(emp: Dictionary) -> String:
	if emp.has("avatar"):
		return str(emp["avatar"])
	var all: Array = DataDB.data.raw.get("avatars.json", [])
	var same: Array = all.filter(func(rec: Variant) -> bool: return str(rec["gender"]) == str(emp.get("gender", "")))
	var pool: Array = same if not same.is_empty() else all
	if pool.is_empty():
		return ""
	return str(pool[absi(str(emp.get("id", "")).hash()) % pool.size()]["id"])


static func avatar(emp: Dictionary, width: float = 56.0) -> PanelContainer:
	var pic: PanelContainer = MenuArt.picture(MenuArt.avatar_path(avatar_id(emp)), Vector2(width, roundf(width * AVATAR_ASPECT)))
	pic.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	return pic


## Kart başlığı: solda portre / ikon, ortada ad ve alt satır, sağda etiketler.
static func header(lead: Control, title: String, subtitle: String = "", trailing: Array = []) -> HBoxContainer:
	var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
	if lead != null:
		row.add_child(lead)
	var col: VBoxContainer = UiUtil.vbox(0)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var name: Label = UiUtil.label(title, 17, CozyTheme.FOREST)
	name.add_theme_font_override("font", CozyTheme.title_font(760))
	name.clip_text = true
	col.add_child(name)
	if not subtitle.is_empty():
		var sub: Label = UiUtil.label(subtitle, 13, CozyTheme.WOOD)
		sub.clip_text = true
		col.add_child(sub)
	row.add_child(col)
	for c: Variant in trailing:
		(c as Control).size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		row.add_child(c as Control)
	return row


## Tek stat rozeti: tam ad + değer; üzerine gelince ne işe yaradığı.
static func stat(stat_id: String, value: int) -> PanelContainer:
	var key: String = "STAT_" + stat_id.to_upper()
	var p: PanelContainer = PanelContainer.new()
	p.add_theme_stylebox_override("panel", CozyTheme.box(CozyTheme.CREAM, 999, CozyTheme.BORDER, 1, false, Vector2(10, 2)))
	p.tooltip_text = "%s: %s" % [TranslationServer.translate(key + "_NAME"), TranslationServer.translate(key + "_DESC")]
	var row: HBoxContainer = UiUtil.hbox(5)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(UiUtil.label(TranslationServer.translate(key + "_NAME"), 12, CozyTheme.MUTED))
	var v: Label = UiUtil.label(str(value), 14, CozyTheme.TEXT)
	v.add_theme_font_override("font", CozyTheme.strong_font(800))
	row.add_child(v)
	p.add_child(row)
	return p


## Bütün statlar, sığmazsa alt satıra kayan sıra hâlinde.
static func stats(values: Dictionary) -> HFlowContainer:
	var flow: HFlowContainer = flow_row()
	for s: Variant in DataDB.data.bal("staff_rules.stats"):
		flow.add_child(stat(str(s), int(values.get(s, 0))))
	return flow


static func flow_row(separation: int = 6) -> HFlowContainer:
	var flow: HFlowContainer = HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", separation)
	flow.add_theme_constant_override("v_separation", separation)
	return flow


## İnce ölçer: ad, renkli çubuk, sayı.
static func meter(caption: String, value: float, color: Color = CozyTheme.FOREST_LIGHT, width: float = 84.0) -> HBoxContainer:
	var row: HBoxContainer = UiUtil.hbox(6)
	row.add_child(UiUtil.label(caption, 12, CozyTheme.MUTED))
	var bar: ProgressBar = ProgressBar.new()
	bar.max_value = 100.0
	bar.value = value
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(width, 10.0)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_theme_stylebox_override("fill", CozyTheme.box(color, 6, Color.TRANSPARENT, 0, false, Vector2.ZERO))
	row.add_child(bar)
	var n: Label = UiUtil.label(str(int(value)), 12, CozyTheme.TEXT)
	n.add_theme_font_override("font", CozyTheme.strong_font(800))
	n.custom_minimum_size.x = 22.0
	row.add_child(n)
	return row


## Bilgi sütunu (UI-3): kiremit ikon, küçük başlık, altında kalın değer (ajans ücreti, süre, indirim...).
static func fact(icon_name: String, caption: String, value: String) -> HBoxContainer:
	var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ic: TextureRect = UiUtil.icon(icon_name, 24, CozyTheme.TERRA)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(ic)
	var col: VBoxContainer = UiUtil.vbox(-2)
	col.add_child(UiUtil.label(caption, 12, CozyTheme.MUTED))
	var v: Label = UiUtil.label(value, 16, CozyTheme.FOREST)
	v.add_theme_font_override("font", CozyTheme.strong_font())
	col.add_child(v)
	row.add_child(col)
	return row


## Yan yana bilgi sütunları, aralarında ince dikey çizgi.
static func facts(items: Array) -> HBoxContainer:
	var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
	for i: int in items.size():
		if i > 0:
			row.add_child(VSeparator.new())
		row.add_child(items[i] as Control)
	return row


## Bölüm şeridi (UI-3): açık yeşil bant içinde başlık; sağda (varsa) kısa bilgi.
static func section(title: String, trailing: String = "", icon_name: String = "") -> PanelContainer:
	var strip: PanelContainer = PanelContainer.new()
	strip.add_theme_stylebox_override("panel", CozyTheme.box(CozyTheme.SAGE_SOFT, CozyTheme.RADIUS_CONTROL, Color.TRANSPARENT, 0,
		false, Vector2(CozyTheme.SPACE_M, 2)))
	var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	strip.add_child(row)
	if not icon_name.is_empty():
		row.add_child(UiUtil.icon(icon_name, 18, CozyTheme.FOREST))
	var l: Label = UiUtil.label(title, 15, CozyTheme.FOREST)
	l.add_theme_font_override("font", CozyTheme.title_font(700))
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	if not trailing.is_empty():
		var t: Label = UiUtil.label(trailing, 13, CozyTheme.FOREST)
		t.add_theme_font_override("font", CozyTheme.strong_font())
		row.add_child(t)
	return strip


## Küçük ikonlu satır (maliyet, süre gibi alt alta bilgiler).
static func mini_fact(icon_name: String, text: String) -> HBoxContainer:
	var row: HBoxContainer = UiUtil.hbox(6)
	row.add_child(UiUtil.icon(icon_name, 16, CozyTheme.TERRA))
	row.add_child(UiUtil.label(text, 13, CozyTheme.TEXT))
	return row
