class_name MainHud
extends RefCounted
## Ana ekranın yüzen arayüz parçaları (UI-3 kabuğu, docs/reference/ui_mockups). main.gd 400 satırı aşmasın diye ayrı.
##   Sol üst: ajans kartı (logo, ad, alt yazı), altında küçük oyun düğmeleri.
##   Üst orta: zaman hapı (tarih, mesai, duraklat, hızlar). Sağ üst: para ve itibar hapı, altında bildirimler.
##   Alt orta: krem dok (menü ikonları). Pencereler ekranın ortasında açılır (main.gd).

const MARGIN: float = 16.0
const GAP: float = 10.0  # dok / üst çubuk ile pencere arası
const TOP_CLEARANCE: float = 64.0  # üst hapların yüksekliği + boşluk
const TOASTS_KEPT: int = 4
const TOAST_SECONDS: float = 7.0
const SMALL_ICON: int = 16
const TIME_ICON: int = 18
const MENU_ICON: int = 26
const BADGE_CIRCLE: float = 30.0
const LOGO_SIZE: int = 40
const BADGE_FONT: int = 18
const TOAST_WIDTH: float = 250.0


static func _pill() -> PanelContainer:
	var p: PanelContainer = PanelContainer.new()
	p.theme_type_variation = "HudPill"
	return p


static func _divider() -> ColorRect:
	var line: ColorRect = ColorRect.new()
	line.color = CozyTheme.BORDER
	line.custom_minimum_size = Vector2(1.0, 18.0)
	line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return line


## Sol üst: ajans kartı + küçük oyun düğmeleri (kaydet, yükle, ayarlar, ana menü).
## Dönüş: kaydet düğmesi (ipucu balonu onu gösterir).
static func agency_card(main: Control) -> Button:
	var col: VBoxContainer = UiUtil.vbox(6)
	main.add_child(col)
	col.position = Vector2(MARGIN, MARGIN)
	var card: PanelContainer = PanelContainer.new()
	card.add_theme_stylebox_override("panel", CozyTheme.box(CozyTheme.CREAM_LIGHT, 12, CozyTheme.BORDER, 1, true,
		Vector2(CozyTheme.SPACE_M, 6)))
	col.add_child(card)
	var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
	card.add_child(row)
	var logo: TextureRect = UiUtil.icon("speakerphone", LOGO_SIZE, CozyTheme.TERRA)
	var logo_art: Texture2D = IconPack.art("ajans-logo", LOGO_SIZE)
	if logo_art != null:
		logo.texture = logo_art
		logo.modulate = Color.WHITE
	row.add_child(logo)
	var names: VBoxContainer = UiUtil.vbox(-4)
	row.add_child(names)
	var agency: Label = UiUtil.label(GameState.agency_display(), 19, CozyTheme.FOREST)
	agency.add_theme_font_override("font", CozyTheme.title_font(700))
	names.add_child(agency)
	var tagline: Label = UiUtil.label(main.tr("UI_AGENCY_TAGLINE"), 12, CozyTheme.TEXT)
	tagline.add_theme_font_override("font", MenuArt.italic(CozyTheme.body_font()))
	names.add_child(tagline)
	var buttons: HBoxContainer = UiUtil.hbox(6)
	col.add_child(buttons)
	var reload: Callable = func() -> void: main.get_tree().reload_current_scene()
	var save: Button = _mini("device-floppy", main.tr("UI_SAVE") + " (F5)", func() -> void:
		main.call("open_modal", SaveLoadDialog.new(true)))
	buttons.add_child(save)
	buttons.add_child(_mini("folder-open", main.tr("MENU_LOAD"), func() -> void:
		main.call("open_modal", SaveLoadDialog.new(false, reload))))
	buttons.add_child(_mini("settings", main.tr("UI_SETTINGS"), func() -> void:
		main.call("open_modal", SettingsDialog.new(reload))))
	buttons.add_child(_mini("logout", main.tr("UI_MAIN_MENU"), func() -> void:
		main.call("_confirm_leave", Callable(main, "_to_menu"))))
	return save


static func _mini(icon_name: String, tip: String, on_press: Callable) -> Button:
	var b: Button = UiUtil.icon_button(icon_name, tip, on_press, SMALL_ICON)
	b.theme_type_variation = "MiniButton"
	return b


## Üst orta: zaman hapı. Dönüş: { date, overtime, pause, speeds }.
static func time_bar(main: Control) -> Dictionary:
	var pill: PanelContainer = _pill()
	main.add_child(pill)
	pill.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	pill.grow_horizontal = Control.GROW_DIRECTION_BOTH
	pill.offset_top = MARGIN
	var row: HBoxContainer = UiUtil.hbox(6)
	pill.add_child(row)
	row.add_child(UiUtil.icon("calendar", 20, CozyTheme.FOREST))
	var date: Label = UiUtil.label("", 15, CozyTheme.FOREST)
	date.add_theme_font_override("font", CozyTheme.strong_font())
	row.add_child(date)
	row.add_child(_divider())
	var overtime: Button = UiUtil.icon_button("clock", main.tr("UI_OVERTIME") + ": " + main.tr("TIP_OVERTIME"), func() -> void:
		GameState.execute(SetOvertimeCommand.new(not GameState.sim.state.overtime)), TIME_ICON)
	overtime.theme_type_variation = "PillButton"
	row.add_child(overtime)
	var pause: Button = UiUtil.icon_button("player-pause", main.tr("TIP_PAUSE"), func() -> void: Clock.toggle_pause(), TIME_ICON)
	pause.theme_type_variation = "PillButton"
	row.add_child(pause)
	row.add_child(_divider())
	var speeds: Array[Button] = []
	var values: Array = DataDB.data.bal("time.speeds")
	for i: int in values.size():
		var b: Button = UiUtil.button("%d×" % int(values[i]), func() -> void: Clock.set_speed(i))
		b.theme_type_variation = "PillButton"
		b.custom_minimum_size = Vector2(40, 0)
		b.tooltip_text = main.tr("TIP_SPEED") % (i + 1)
		speeds.append(b)
		row.add_child(b)
	return {"date": date, "overtime": overtime, "pause": pause, "speeds": speeds}


## Sağ üst: para ve itibar tek hapta; altında bildirim kartları. Dönüş: { cash, rep, feed }.
static func wallet(main: Control) -> Dictionary:
	var col: VBoxContainer = UiUtil.vbox(8)
	main.add_child(col)
	col.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	col.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	col.offset_right = -MARGIN
	col.offset_top = MARGIN
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pill: PanelContainer = _pill()
	pill.size_flags_horizontal = Control.SIZE_SHRINK_END
	col.add_child(pill)
	var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	pill.add_child(row)
	var cash: CountBadge = CountBadge.new("currency-lira", CozyTheme.GOLD,
		func(v: float) -> String: return UiUtil.money(v), 140.0, BADGE_CIRCLE, BADGE_FONT)
	cash.tooltip_text = main.tr("TIP_CASH")
	row.add_child(cash)
	row.add_child(_divider())
	var rep: CountBadge = CountBadge.new("star", CozyTheme.ACCENT,
		func(v: float) -> String: return "%d" % int(roundf(v)), 62.0, BADGE_CIRCLE, BADGE_FONT)
	rep.tooltip_text = main.tr("TIP_REPUTATION")
	row.add_child(rep)
	cash.set_art(IconPack.art("para", int(BADGE_CIRCLE)))
	rep.set_art(IconPack.art("yildiz", int(BADGE_CIRCLE)))
	for badge: CountBadge in [cash, rep]:
		badge.add_theme_stylebox_override("panel", StyleBoxEmpty.new())  # ikisi tek hapın içinde
	var feed: VBoxContainer = UiUtil.vbox(8)
	feed.custom_minimum_size.x = TOAST_WIDTH
	feed.size_flags_horizontal = Control.SIZE_SHRINK_END
	feed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(feed)
	return {"cash": cash, "rep": rep, "feed": feed}


## Alt orta: krem dok. Dönüş: { dock, menu (ikonların ekleneceği sıra) }.
static func dock(main: Control) -> Dictionary:
	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", CozyTheme.box(CozyTheme.CREAM_LIGHT, 22, CozyTheme.BORDER, 1, true,
		Vector2(CozyTheme.SPACE_L, CozyTheme.SPACE_S)))
	main.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.offset_bottom = -MARGIN
	var menu: HBoxContainer = UiUtil.hbox(4)
	panel.add_child(menu)
	return {"dock": panel, "menu": menu}


## Dok ikonları arasındaki ince çizgi.
static func dock_divider() -> ColorRect:
	var line: ColorRect = _divider()
	line.color = Color(CozyTheme.TERRA, 0.45)
	line.custom_minimum_size = Vector2(1.0, 22.0)
	return line


## Bildirim kartı (toast): kayarak gelir, birkaç saniye sonra solup kaybolur; en fazla TOASTS_KEPT tane.
static func toast(feed: VBoxContainer, key: String, args: Array, kind: String) -> void:
	var card: PanelContainer = PanelContainer.new()
	card.theme_type_variation = "Toast"
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row: HBoxContainer = UiUtil.hbox(10)
	card.add_child(row)
	var icon_name: String = {"good": "check", "bad": "alert-triangle"}.get(kind, "bell")
	var icon_color: Color = {"good": CozyTheme.POSITIVE, "bad": CozyTheme.NEGATIVE}.get(kind, CozyTheme.FOREST)
	row.add_child(UiUtil.icon(icon_name, 22, icon_color))
	var text: Label = UiUtil.wrapped(UiUtil.tr_fmt(key, args), 14, UiUtil.TEXT, TOAST_WIDTH - 90.0)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	feed.add_child(card)
	Juice.slide_in(card)
	var fade: Tween = card.create_tween()
	fade.tween_interval(TOAST_SECONDS)
	fade.tween_property(card, "modulate:a", 0.0, 0.5)
	fade.tween_callback(card.queue_free)
	while feed.get_child_count() > TOASTS_KEPT:
		var first: Node = feed.get_child(0)
		feed.remove_child(first)
		first.queue_free()
