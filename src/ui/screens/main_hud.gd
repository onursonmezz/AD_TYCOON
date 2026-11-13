class_name MainHud
extends RefCounted
## Ana ekranın yüzen arayüz parçaları (G2; C1 düzeni). main.gd 400 satırı aşmasın diye ayrı.
## C1: ekranın sağı solu boş kalır. Altta tek sıra çubuk (solda oyun düğmeleri, ortada menü, sağda hız);
## sağ üstte tarih, para, itibar ve bildirimler. Her kurucu, main'in tutacağı düğümleri döndürür.

const MARGIN: float = 16.0
const TOASTS_KEPT: int = 4
const TOAST_SECONDS: float = 7.0
const GAME_ICON: int = 20
const MENU_ICON: int = 22
## Alt çubuğun yüksekliği + boşluk: pencere, çalışan kartı ve inşa çubuğu bunun üstünde biter.
const BAR_CLEARANCE: float = 80.0


## Alt çubuk: ekranın altına yaslı tek sıra; parçalar arasındaki boşluk tıklamayı ofise geçirir.
static func bottom_bar(main: Control) -> HBoxContainer:
	var bar: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main.add_child(bar)
	bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bar.offset_left = MARGIN
	bar.offset_right = -MARGIN
	bar.offset_bottom = -MARGIN
	return bar


static func gap(bar: HBoxContainer) -> void:
	var s: Control = UiUtil.spacer()
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(s)


## Alt çubuğun solu: kaydet, yükle, ayarlar, ana menü. Dönüş: kaydet düğmesi (ipucu balonu onu gösterir).
static func game_buttons(main: Control, bar: HBoxContainer) -> Button:
	var pill: PanelContainer = PanelContainer.new()
	pill.theme_type_variation = "DarkPill"
	pill.size_flags_vertical = Control.SIZE_SHRINK_END
	bar.add_child(pill)
	var row: HBoxContainer = UiUtil.hbox(2)
	pill.add_child(row)
	var reload: Callable = func() -> void: main.get_tree().reload_current_scene()
	var save: Button = UiUtil.icon_button("device-floppy", main.tr("UI_SAVE") + " (F5)", func() -> void:
		main.call("open_modal", SaveLoadDialog.new(true)), GAME_ICON)
	row.add_child(save)
	row.add_child(UiUtil.icon_button("folder-open", main.tr("MENU_LOAD"), func() -> void:
		main.call("open_modal", SaveLoadDialog.new(false, reload)), GAME_ICON))
	row.add_child(UiUtil.icon_button("settings", main.tr("UI_SETTINGS"), func() -> void:
		main.call("open_modal", SettingsDialog.new(reload)), GAME_ICON))
	row.add_child(UiUtil.icon_button("logout", main.tr("UI_MAIN_MENU"), func() -> void:
		main.call("_confirm_leave", Callable(main, "_to_menu")), GAME_ICON))
	return save


## Sağ üst: tarih, para ve itibar rozetleri; altında bildirim kartları. Dönüş: { date, cash, rep, feed }.
static func badges(main: Control) -> Dictionary:
	var col: VBoxContainer = UiUtil.vbox(10)
	main.add_child(col)
	col.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	col.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	col.offset_right = -MARGIN
	col.offset_top = MARGIN
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	row.alignment = BoxContainer.ALIGNMENT_END
	col.add_child(row)
	var date_pill: PanelContainer = PanelContainer.new()
	date_pill.theme_type_variation = "HudPill"
	date_pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var date_row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	date_pill.add_child(date_row)
	date_row.add_child(UiUtil.icon("calendar", 20, CozyTheme.FOREST))
	var date: Label = UiUtil.label("", 15, CozyTheme.TEXT)
	date.add_theme_font_override("font", CozyTheme.strong_font(780))
	date_row.add_child(date)
	row.add_child(date_pill)
	var cash: CountBadge = CountBadge.new("currency-lira", CozyTheme.GOLD,
		func(v: float) -> String: return UiUtil.money(v), 170.0)
	cash.tooltip_text = main.tr("TIP_CASH")
	row.add_child(cash)
	var rep: CountBadge = CountBadge.new("star", CozyTheme.ACCENT,
		func(v: float) -> String: return "%d" % int(roundf(v)), 88.0)
	rep.tooltip_text = main.tr("TIP_REPUTATION")
	row.add_child(rep)
	var feed: VBoxContainer = UiUtil.vbox(8)
	feed.custom_minimum_size.x = 320.0
	feed.size_flags_horizontal = Control.SIZE_SHRINK_END
	feed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(feed)
	return {"date": date, "cash": cash, "rep": rep, "feed": feed}


## Alt çubuğun sağı: mesai, duraklat ve hız düğmeleri. Dönüş: { overtime, pause, speeds }.
static func time_controls(main: Control, bar: HBoxContainer) -> Dictionary:
	var pill: PanelContainer = PanelContainer.new()
	pill.theme_type_variation = "DarkPill"
	pill.size_flags_vertical = Control.SIZE_SHRINK_END
	var row: HBoxContainer = UiUtil.hbox(2)
	pill.add_child(row)
	bar.add_child(pill)
	var overtime: Button = UiUtil.icon_button("clock", main.tr("UI_OVERTIME") + ": " + main.tr("TIP_OVERTIME"), func() -> void:
		GameState.execute(SetOvertimeCommand.new(not GameState.sim.state.overtime)), GAME_ICON)
	row.add_child(overtime)
	var pause: Button = UiUtil.icon_button("player-pause", main.tr("TIP_PAUSE"), func() -> void: Clock.toggle_pause(), GAME_ICON)
	row.add_child(pause)
	var speeds: Array[Button] = []
	var values: Array = DataDB.data.bal("time.speeds")
	for i: int in values.size():
		var b: Button = UiUtil.button("%d×" % int(values[i]), func() -> void: Clock.set_speed(i))
		b.theme_type_variation = "IconButton"
		b.custom_minimum_size = Vector2(44, 44)
		b.tooltip_text = main.tr("TIP_SPEED") % (i + 1)
		speeds.append(b)
		row.add_child(b)
	return {"overtime": overtime, "pause": pause, "speeds": speeds}


## Bildirim kartı (toast): kayarak gelir, birkaç saniye sonra solup kaybolur; en fazla TOASTS_KEPT tane.
static func toast(feed: VBoxContainer, key: String, args: Array, kind: String) -> void:
	var card: PanelContainer = PanelContainer.new()
	card.theme_type_variation = "Toast"
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row: HBoxContainer = UiUtil.hbox(10)
	card.add_child(row)
	var icon_name: String = {"good": "check", "bad": "alert-triangle"}.get(kind, "bell")
	var icon_color: Color = {"good": CozyTheme.POSITIVE, "bad": CozyTheme.NEGATIVE}.get(kind, CozyTheme.FOREST)
	row.add_child(UiUtil.icon(icon_name, 26, icon_color))
	var text: Label = UiUtil.wrapped(UiUtil.tr_fmt(key, args), 15, UiUtil.TEXT, 260.0)
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
