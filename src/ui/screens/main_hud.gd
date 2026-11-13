class_name MainHud
extends RefCounted
## Ana ekranın yüzen arayüz parçaları (G2; C3 düzeni). main.gd 400 satırı aşmasın diye ayrı.
## C3: her şey altta tek bir dokta toplanır, ekranın geri kalanı ofise kalır.
##   Dok üst satır: menü ikonları (ortada). Dok alt satır: solda zaman (mesai, duraklat, hız, tarih),
##   ortada ajansın adı, sağda para ve itibar. Sağ üstte yalnızca küçük oyun düğmeleri ve bildirimler.
## Pencereler dokun hemen üstünde, ortada açılır (main.gd).

const MARGIN: float = 12.0
const GAP: float = 8.0  # dok ile üstünde açılan pencere arası
const TOASTS_KEPT: int = 4
const TOAST_SECONDS: float = 7.0
const SMALL_ICON: int = 18
const MENU_ICON: int = 24
const DOCK_ALPHA: float = 0.96
const BADGE_CIRCLE: float = 26.0
const BADGE_FONT: int = 16
const TOAST_WIDTH: float = 250.0


## Alt dok. Dönüş: { dock, menu (ikonların ekleneceği sıra), date, overtime, pause, speeds, cash, rep }.
static func dock(main: Control) -> Dictionary:
	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", CozyTheme.box(Color(CozyTheme.FOREST, DOCK_ALPHA), 16, Color.TRANSPARENT, 0,
		true, Vector2(CozyTheme.SPACE_M, 6)))
	main.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.offset_left = MARGIN
	panel.offset_right = -MARGIN
	panel.offset_bottom = -MARGIN
	var col: VBoxContainer = UiUtil.vbox(4)
	panel.add_child(col)
	var menu: HBoxContainer = UiUtil.hbox(4)
	menu.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(menu)
	var line: ColorRect = ColorRect.new()
	line.color = Color(CozyTheme.CREAM_LIGHT, 0.14)
	line.custom_minimum_size.y = 1.0
	col.add_child(line)
	var status: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
	col.add_child(status)
	# Sol ve sağ grup eşit genişler, böylece ajansın adı tam ortada kalır.
	var left: HBoxContainer = UiUtil.hbox(2)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.add_child(left)
	var out: Dictionary = _time_controls(main, left)
	var agency: Label = UiUtil.label(GameState.agency_display(), 16, CozyTheme.CREAM_LIGHT)
	agency.add_theme_font_override("font", CozyTheme.title_font(700))
	status.add_child(agency)
	var right: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.alignment = BoxContainer.ALIGNMENT_END
	status.add_child(right)
	var cash: CountBadge = CountBadge.new("currency-lira", CozyTheme.GOLD,
		func(v: float) -> String: return UiUtil.money(v), 150.0, BADGE_CIRCLE, BADGE_FONT)
	cash.tooltip_text = main.tr("TIP_CASH")
	right.add_child(cash)
	var rep: CountBadge = CountBadge.new("star", CozyTheme.ACCENT,
		func(v: float) -> String: return "%d" % int(roundf(v)), 70.0, BADGE_CIRCLE, BADGE_FONT)
	rep.tooltip_text = main.tr("TIP_REPUTATION")
	right.add_child(rep)
	# Hiçbir parça satır yüksekliğine gerilmesin (yuvarlak rozetler oval olmasın).
	for group: Control in [left, right]:
		for child: Node in group.get_children():
			(child as Control).size_flags_vertical = Control.SIZE_SHRINK_CENTER
	out.merge({"dock": panel, "menu": menu, "cash": cash, "rep": rep})
	return out


## Dokun sol altı: mesai, duraklat, hız düğmeleri ve tarih. Dönüş: { overtime, pause, speeds, date }.
static func _time_controls(main: Control, row: HBoxContainer) -> Dictionary:
	var overtime: Button = UiUtil.icon_button("clock", main.tr("UI_OVERTIME") + ": " + main.tr("TIP_OVERTIME"), func() -> void:
		GameState.execute(SetOvertimeCommand.new(not GameState.sim.state.overtime)), SMALL_ICON)
	overtime.theme_type_variation = "DockButton"
	row.add_child(overtime)
	var pause: Button = UiUtil.icon_button("player-pause", main.tr("TIP_PAUSE"), func() -> void: Clock.toggle_pause(), SMALL_ICON)
	pause.theme_type_variation = "DockButton"
	row.add_child(pause)
	var speeds: Array[Button] = []
	var values: Array = DataDB.data.bal("time.speeds")
	for i: int in values.size():
		var b: Button = UiUtil.button("%d×" % int(values[i]), func() -> void: Clock.set_speed(i))
		b.theme_type_variation = "DockButton"
		b.custom_minimum_size = Vector2(36, 0)
		b.tooltip_text = main.tr("TIP_SPEED") % (i + 1)
		speeds.append(b)
		row.add_child(b)
	var gap: Control = Control.new()
	gap.custom_minimum_size.x = CozyTheme.SPACE_S
	row.add_child(gap)
	row.add_child(UiUtil.icon("calendar", 20, CozyTheme.SAGE))
	var date: Label = UiUtil.label("", 15, CozyTheme.CREAM_LIGHT)
	date.add_theme_font_override("font", CozyTheme.strong_font(780))
	row.add_child(date)
	return {"overtime": overtime, "pause": pause, "speeds": speeds, "date": date}


## Sağ üst: küçük oyun düğmeleri (kaydet, yükle, ayarlar, ana menü), altında bildirim kartları.
## Dönüş: { save (ipucu balonu onu gösterir), feed }.
static func corner(main: Control) -> Dictionary:
	var col: VBoxContainer = UiUtil.vbox(10)
	main.add_child(col)
	col.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	col.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	col.offset_right = -MARGIN
	col.offset_top = MARGIN
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pill: PanelContainer = PanelContainer.new()
	pill.theme_type_variation = "DarkPill"
	pill.size_flags_horizontal = Control.SIZE_SHRINK_END
	col.add_child(pill)
	var row: HBoxContainer = UiUtil.hbox(0)
	pill.add_child(row)
	var reload: Callable = func() -> void: main.get_tree().reload_current_scene()
	var save: Button = UiUtil.icon_button("device-floppy", main.tr("UI_SAVE") + " (F5)", func() -> void:
		main.call("open_modal", SaveLoadDialog.new(true)), SMALL_ICON)
	row.add_child(save)
	row.add_child(UiUtil.icon_button("folder-open", main.tr("MENU_LOAD"), func() -> void:
		main.call("open_modal", SaveLoadDialog.new(false, reload)), SMALL_ICON))
	row.add_child(UiUtil.icon_button("settings", main.tr("UI_SETTINGS"), func() -> void:
		main.call("open_modal", SettingsDialog.new(reload)), SMALL_ICON))
	row.add_child(UiUtil.icon_button("logout", main.tr("UI_MAIN_MENU"), func() -> void:
		main.call("_confirm_leave", Callable(main, "_to_menu")), SMALL_ICON))
	var feed: VBoxContainer = UiUtil.vbox(8)
	feed.custom_minimum_size.x = TOAST_WIDTH
	feed.size_flags_horizontal = Control.SIZE_SHRINK_END
	feed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(feed)
	return {"save": save, "feed": feed}


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
