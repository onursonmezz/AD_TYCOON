extends Control
## Oyun ekranı (GDD 20, M2 sade sürüm): üst bar, sol menü, içerik paneli, bildirim akışı, modal pencereler.

const MENU_SCENE: String = "res://src/ui/screens/main_menu.tscn"
const WINDOW_MARGIN: float = 14.0

var _cash: Label
var _date: Label
var _rep: Label
var _speed_buttons: Array[Button] = []
var _pause_button: Button
var _overtime: CheckButton
var _content: VBoxContainer
var _window: PanelContainer
var _office: OfficeView
var _employee_card: EmployeeCard = null
var _build_bar: BuildToolbar = null
var _feed: VBoxContainer
var _menu_buttons: Dictionary = {}
var _panel: Control = null
var _panel_id: String = ""
var _modal_layer: Control
var _modal_open: bool = false


func _ready() -> void:
	_build()
	EventBus.state_changed.connect(_refresh)
	EventBus.speed_changed.connect(func(_i: int, _p: bool) -> void: _refresh_speed())
	EventBus.notification.connect(_on_notification)
	EventBus.phase_started.connect(func(_phase: int) -> void: show_panel("campaign"))
	EventBus.campaign_finished.connect(_on_campaign_finished)
	EventBus.bankrupt.connect(_on_bankrupt)
	EventBus.offer_received.connect(func(offer: Dictionary) -> void: open_modal(OfferDialog.new(offer)))
	EventBus.scandal_started.connect(func(scandal: Dictionary) -> void: open_modal(ScandalDialog.new(scandal)))
	EventBus.award_ceremony.connect(func(result: Dictionary) -> void: open_modal(CeremonyDialog.new(result)))
	EventBus.pitch_ready.connect(func() -> void: open_modal(PitchDialog.new()))
	EventBus.era_started.connect(func(era: String) -> void: open_modal(EraDialog.new(era)))
	EventBus.event_started.connect(func(_ev: Dictionary) -> void: _open_event())
	_refresh()
	_refresh_speed()
	if GameState.is_bankrupt():
		_on_bankrupt()
	elif GameState.is_pitch_waiting():
		open_modal(PitchDialog.new())
	else:
		_open_event()


func _build() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.color = UiUtil.CREAM
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	add_child(margin)
	var root: VBoxContainer = UiUtil.vbox(10)
	margin.add_child(root)
	root.add_child(_build_top_bar())
	var body: HBoxContainer = UiUtil.hbox(12)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	body.add_child(_build_menu())
	body.add_child(_build_center())
	var feed_card: PanelContainer = UiUtil.card()
	feed_card.custom_minimum_size.x = 260.0
	var feed_col: VBoxContainer = UiUtil.vbox(6)
	feed_col.add_child(UiUtil.label(tr("UI_NOTIFICATIONS"), 18, UiUtil.SAGE_DARK))
	_feed = UiUtil.vbox(6)
	feed_col.add_child(_feed)
	feed_card.add_child(feed_col)
	body.add_child(feed_card)
	_modal_layer = Control.new()
	_modal_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_modal_layer)


func _build_top_bar() -> PanelContainer:
	var bar: PanelContainer = UiUtil.card()
	var row: HBoxContainer = UiUtil.hbox(12)
	bar.add_child(row)
	_cash = UiUtil.label("", 20)
	_cash.tooltip_text = tr("TIP_CASH")
	_cash.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(_cash)
	_date = UiUtil.label("", 18, UiUtil.WOOD)
	row.add_child(_date)
	_rep = UiUtil.label("", 18)
	_rep.tooltip_text = tr("TIP_REPUTATION")
	_rep.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(_rep)
	row.add_child(UiUtil.spacer())
	_overtime = CheckButton.new()
	_overtime.text = tr("UI_OVERTIME")
	_overtime.tooltip_text = tr("TIP_OVERTIME")
	UiUtil.style_toggle(_overtime, UiUtil.TERRACOTTA)
	_overtime.toggled.connect(func(on: bool) -> void: GameState.execute(SetOvertimeCommand.new(on)))
	row.add_child(_overtime)
	_pause_button = UiUtil.button("", func() -> void: Clock.toggle_pause())
	_pause_button.tooltip_text = tr("TIP_PAUSE")
	row.add_child(_pause_button)
	var speeds: Array = DataDB.data.bal("time.speeds")
	for i: int in speeds.size():
		var b: Button = UiUtil.button("%dx" % int(speeds[i]), func() -> void: Clock.set_speed(i))
		b.toggle_mode = true
		b.tooltip_text = tr("TIP_SPEED") % (i + 1)
		_speed_buttons.append(b)
		row.add_child(b)
	row.add_child(UiUtil.button(tr("UI_SAVE"), func() -> void: GameState.save_game()))
	row.add_child(UiUtil.button(tr("UI_MAIN_MENU"), _to_menu))
	return bar


## Orta alan (M6): 3D ofis her zaman görünür; menü ekranları üstünde kapatılabilir pencere olarak açılır.
func _build_center() -> Control:
	var center: Control = Control.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.clip_contents = true
	_office = OfficeView.new()
	center.add_child(_office)
	_office.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_office.employee_clicked.connect(_on_employee_clicked)
	var hint: Label = UiUtil.label(tr("UI_OFFICE_CONTROLS"), 12, UiUtil.MUTED)
	center.add_child(hint)
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	hint.position += Vector2(WINDOW_MARGIN, -WINDOW_MARGIN)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_window = UiUtil.card()
	center.add_child(_window)
	_window.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "top", "right", "bottom"]:
		_window.set("offset_" + side, WINDOW_MARGIN if side in ["left", "top"] else -WINDOW_MARGIN)
	var col: VBoxContainer = UiUtil.vbox(6)
	_window.add_child(col)
	var header: HBoxContainer = UiUtil.hbox()
	header.add_child(UiUtil.spacer())
	var close: Button = Button.new()
	close.text = "✕"
	close.tooltip_text = tr("TIP_CLOSE_WINDOW")
	close.pressed.connect(close_panel)
	header.add_child(close)
	col.add_child(header)
	_content = UiUtil.vbox(0)
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_content)
	_window.visible = false
	return center


## Pencereyi kapatır, ofis görünür.
func close_panel() -> void:
	_window.visible = false
	UiUtil.clear(_content)
	_panel = null
	_panel_id = ""


## İnşa modu (M6-B): pencere kapanır, ofisin altında araç çubuğu açılır.
func enter_build_mode() -> void:
	close_panel()
	if _build_bar != null:
		return
	_build_bar = BuildToolbar.new(_office, exit_build_mode)
	_office.get_parent().add_child(_build_bar)
	_build_bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_build_bar.offset_left = WINDOW_MARGIN
	_build_bar.offset_right = -WINDOW_MARGIN
	_build_bar.offset_bottom = -WINDOW_MARGIN
	_build_bar.grow_vertical = Control.GROW_DIRECTION_BEGIN


func exit_build_mode() -> void:
	if _build_bar != null:
		_build_bar.queue_free()
		_build_bar = null


## Ofiste bir çalışana tıklandı: küçük bilgi kartı.
func _on_employee_clicked(employee_id: String) -> void:
	if _employee_card != null:
		_employee_card.queue_free()
	_employee_card = EmployeeCard.new(employee_id, func() -> void: show_panel("team"))
	_office.get_parent().add_child(_employee_card)
	_employee_card.position = Vector2(WINDOW_MARGIN, WINDOW_MARGIN)


func _build_menu() -> PanelContainer:
	var card: PanelContainer = UiUtil.card()
	card.custom_minimum_size.x = 190.0
	var col: VBoxContainer = UiUtil.vbox(8)
	card.add_child(col)
	for id: String in ["inbox", "clients", "campaign", "team", "office", "tools", "research", "finance", "industry", "history"]:
		var b: Button = UiUtil.button(tr("MENU_" + id.to_upper()), func() -> void: toggle_panel(id))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_menu_buttons[id] = b
		col.add_child(b)
	return card


## Menü düğmesi: aynı pencere açıksa kapatır.
func toggle_panel(id: String) -> void:
	if _panel_id == id and _window.visible:
		close_panel()
	else:
		show_panel(id)


func show_panel(id: String) -> void:
	exit_build_mode()
	if _panel_id == id and _panel != null:
		return
	UiUtil.clear(_content)
	_panel_id = id
	_window.visible = true
	match id:
		"inbox":
			_panel = InboxPanel.new(self)
		"clients":
			_panel = ClientsPanel.new()
		"campaign":
			_panel = CampaignPanel.new()
		"team":
			_panel = TeamPanel.new(self)
		"office":
			_panel = OfficePanel.new(self)
		"finance":
			_panel = FinancePanel.new()
		"tools":
			_panel = ToolsPanel.new()
		"research":
			_panel = ResearchPanel.new()
		"industry":
			_panel = IndustryPanel.new(self)
		"history":
			_panel = HistoryPanel.new(self)
	_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_child(_panel)
	_panel.call("refresh")


func _refresh() -> void:
	if not GameState.has_game():
		return
	var s: SimState = GameState.sim.state
	_cash.text = UiUtil.money(s.cash)
	_cash.add_theme_color_override("font_color", UiUtil.TERRACOTTA if s.cash < 0.0 else UiUtil.TEXT)
	_date.text = UiUtil.date_text(s.clock)
	_rep.text = tr("UI_REPUTATION") % s.reputation
	(_menu_buttons["inbox"] as Button).text = tr("MENU_INBOX") + (" (%d)" % s.inbox.size() if not s.inbox.is_empty() else "")
	(_menu_buttons["campaign"] as Button).text = tr("MENU_CAMPAIGN") + (" ●" if GameState.is_waiting() else "")
	_overtime.set_pressed_no_signal(s.overtime)
	if _panel != null:
		_panel.call("refresh")
	_refresh_speed()


func _refresh_speed() -> void:
	_pause_button.text = tr("UI_RESUME") if Clock.paused else tr("UI_PAUSE")
	for i: int in _speed_buttons.size():
		_speed_buttons[i].button_pressed = not Clock.paused and Clock.speed_index == i


func _on_notification(key: String, args: Array, kind: String) -> void:
	var color: Color = UiUtil.TEXT
	if kind == "good":
		color = UiUtil.SAGE_DARK
	elif kind == "bad":
		color = UiUtil.TERRACOTTA
	var prefix: String = UiUtil.date_text(GameState.sim.state.clock) + "\n" if GameState.has_game() else ""
	var note: Label = UiUtil.wrapped(prefix + UiUtil.tr_fmt(key, args), 13, color, 230.0)
	_feed.add_child(note)
	_feed.move_child(note, 0)
	while _feed.get_child_count() > DataDB.data.bali("ui.notifications_kept"):
		var last: Node = _feed.get_child(_feed.get_child_count() - 1)
		_feed.remove_child(last)
		last.queue_free()


## Modal pencere açar; kapanınca saat kaldığı yerden devam eder.
func open_modal(dialog: Control) -> void:
	_modal_open = true
	Clock.hold()
	_modal_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_modal_layer.add_child(dialog)
	dialog.tree_exited.connect(_on_modal_closed)


func _on_modal_closed() -> void:
	if _modal_layer.get_child_count() == 0:
		_modal_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Clock.release()
	_refresh()
	_open_event.call_deferred()


## Kuyruktaki olay (M7-C) için pencere; aynı anda tek olay penceresi açık olur, kapanınca sıradaki gelir.
func _open_event() -> void:
	if GameState.pending_event().is_empty() or not is_inside_tree():
		return
	for child: Node in _modal_layer.get_children():
		if child is EventDialog and not child.is_queued_for_deletion():
			return
	open_modal(EventDialog.new(GameState.pending_event()))


func _on_campaign_finished(camp: Dictionary) -> void:
	open_modal(ReportDialog.new(camp))


func _on_bankrupt() -> void:
	Clock.set_paused(true)
	open_modal(GameOverDialog.new(_to_menu))


func _to_menu() -> void:
	Clock.set_paused(true)
	GameState.end_game()
	get_tree().change_scene_to_file(MENU_SCENE)
