extends Control
## Oyun ekranı (GDD 20, M2 sade sürüm): üst bar, sol menü, içerik paneli, bildirim akışı, modal pencereler.

const MENU_SCENE: String = "res://src/ui/screens/main_menu.tscn"

var _cash: Label
var _date: Label
var _rep: Label
var _speed_buttons: Array[Button] = []
var _pause_button: Button
var _content: PanelContainer
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
	show_panel("inbox")
	_refresh()
	_refresh_speed()
	if GameState.is_bankrupt():
		_on_bankrupt()


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
	_content = UiUtil.card()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(_content)
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
	var row: HBoxContainer = UiUtil.hbox(18)
	bar.add_child(row)
	row.add_child(UiUtil.label(tr("GAME_TITLE"), 22, UiUtil.SAGE_DARK))
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


func _build_menu() -> PanelContainer:
	var card: PanelContainer = UiUtil.card()
	card.custom_minimum_size.x = 190.0
	var col: VBoxContainer = UiUtil.vbox(8)
	card.add_child(col)
	for id: String in ["inbox", "clients", "campaign", "finance", "history"]:
		var b: Button = UiUtil.button(tr("MENU_" + id.to_upper()), func() -> void: show_panel(id))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_menu_buttons[id] = b
		col.add_child(b)
	return card


func show_panel(id: String) -> void:
	if _panel_id == id and _panel != null:
		return
	UiUtil.clear(_content)
	_panel_id = id
	match id:
		"inbox":
			_panel = InboxPanel.new(self)
		"clients":
			_panel = ClientsPanel.new()
		"campaign":
			_panel = CampaignPanel.new()
		"finance":
			_panel = FinancePanel.new()
		"history":
			_panel = HistoryPanel.new(self)
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


func _on_campaign_finished(camp: Dictionary) -> void:
	open_modal(ReportDialog.new(camp))


func _on_bankrupt() -> void:
	Clock.set_paused(true)
	open_modal(GameOverDialog.new(_to_menu))


func _to_menu() -> void:
	Clock.set_paused(true)
	GameState.end_game()
	get_tree().change_scene_to_file(MENU_SCENE)
