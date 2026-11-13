extends Control
## Oyun ekranı (GDD 20; UI-3 kabuğu, docs/reference/ui_mockups): 3D ofis tam ekran. Sol üstte ajans kartı ve oyun
## düğmeleri, üst ortada zaman hapı, sağ üstte para/itibar ve bildirimler, alt ortada krem dok (menü ikonları).
## Menü ekranları ekranın ortasında açılır ve içeriği kadar yer kaplar; inşa çubuğu dokun üstünde açılır.
## Modal pencereler en üstte.

const MENU_SCENE: String = "res://src/ui/screens/main_menu.tscn"
const WINDOW_MARGIN: float = MainHud.MARGIN
## Menü penceresi (boyutlar taslaklardan): sabit genişlik; yüksekliği içeriğe göre, en çok ekranın üçte ikisi.
const WINDOW_WIDTH: float = 720.0
const WINDOW_MAX_HEIGHT: float = 0.66  # taslaklardaki en yüksek pencere: ekranın üçte ikisi
const WINDOW_CHROME: float = 104.0  # başlık bandı + iç kenar boşlukları
const WINDOW_MIN_CONTENT: float = 70.0
const BUILD_BAR_WIDTH: float = 0.58  # inşa çubuğu: ekran genişliğinin oranı, ortada (taslak 20)
const MENU_ICONS: Dictionary = {"inbox": "inbox", "clients": "users", "campaign": "speakerphone", "team": "users-group",
	"office": "building", "tools": "tool", "research": "flask", "finance": "coins", "industry": "trophy", "history": "chart-bar"}

var _cash: CountBadge
var _rep: CountBadge
var _date: Label
var _speed_buttons: Array[Button] = []
var _pause_button: Button
var _overtime: Button
var _content: VBoxContainer
var _window: PanelContainer
var _window_title: Label
var _office: OfficeView
var _hint: Label
var _dock: PanelContainer
var _scroll: ScrollContainer = null
var _employee_card: EmployeeCard = null
var _build_bar: BuildToolbar = null
var _feed: VBoxContainer
var _menu_buttons: Dictionary = {}
var _menu_dots: Dictionary = {}
var _panel: Control = null
var _panel_id: String = ""
var _modal_layer: Control
var _modal_open: bool = false
var _last_cash: float = NAN
var _save_button: Button
var _tutorial: Tutorial


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
	_tutorial = Tutorial.new(self)
	add_child(_tutorial)
	_tutorial.trigger.call_deferred("start")
	_refresh()
	_refresh_speed()
	if GameState.is_bankrupt():
		_on_bankrupt()
	elif GameState.is_pitch_waiting():
		open_modal(PitchDialog.new())
	else:
		_open_event()


func _build() -> void:
	_office = OfficeView.new()
	add_child(_office)
	_office.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_office.employee_clicked.connect(_on_employee_clicked)
	var hint: Label = UiUtil.label(tr("UI_OFFICE_CONTROLS"), 13, CozyTheme.CREAM_LIGHT)
	_hint = hint
	hint.add_theme_color_override("font_outline_color", CozyTheme.FOREST)
	hint.add_theme_constant_override("outline_size", 4)
	add_child(hint)
	hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var d: Dictionary = MainHud.dock(self)
	_dock = d["dock"]
	_build_menu(d["menu"])
	_save_button = MainHud.agency_card(self)
	var t: Dictionary = MainHud.time_bar(self)
	_date = t["date"]
	_overtime = t["overtime"]
	_pause_button = t["pause"]
	_speed_buttons.assign(t["speeds"])
	var w: Dictionary = MainHud.wallet(self)
	_cash = w["cash"]
	_rep = w["rep"]
	_feed = w["feed"]
	_build_window()
	_modal_layer = Control.new()
	_modal_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_modal_layer)
	_dock.resized.connect(_layout)
	resized.connect(_layout)
	_layout.call_deferred()


## Pencereyi üst haplarla dok arasında ortalar; inşa çubuğu, çalışan kartı ve ipucunu dokun üstüne dizer.
func _layout() -> void:
	var clearance: float = _dock.size.y + MainHud.MARGIN + MainHud.GAP
	var middle: float = (MainHud.TOP_CLEARANCE + size.y - clearance) * 0.5
	_window.offset_top = middle
	_window.offset_bottom = middle
	_hint.offset_bottom = -clearance
	_hint.offset_top = -clearance - _hint.size.y
	if _build_bar != null:
		_build_bar.offset_bottom = -clearance
		_build_bar.offset_top = -clearance
	if _employee_card != null:
		_employee_card.offset_bottom = -clearance
		_employee_card.offset_top = -clearance
	_fit_window()


## Pencere içeriği kadar yer kaplar; içerik uzunsa üst haplarla dok arasını doldurur, gerisi kayar.
func _fit_window() -> void:
	if _scroll == null or _panel == null:
		return
	var clearance: float = _dock.size.y + MainHud.MARGIN + MainHud.GAP
	var space: float = size.y - clearance - MainHud.TOP_CLEARANCE - MainHud.GAP
	var room: float = maxf(WINDOW_MIN_CONTENT, minf(space, size.y * WINDOW_MAX_HEIGHT) - WINDOW_CHROME)
	var need: float = _panel.get_combined_minimum_size().y
	# Kaydırma çubuğu ya hep var ya hiç yok: çubuk belirip kaybolurken metin genişliği değişip titremesin.
	var mode: ScrollContainer.ScrollMode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS if need > room \
		else ScrollContainer.SCROLL_MODE_DISABLED
	if _scroll.vertical_scroll_mode != mode:
		_scroll.vertical_scroll_mode = mode
	var height: float = clampf(need, WINDOW_MIN_CONTENT, room)
	if not is_equal_approx(_scroll.custom_minimum_size.y, height):
		_scroll.custom_minimum_size.y = height


## Dok (menü ekranları): kiremit ikonlar, aralarında ince çizgi; açık olanın ikonu yeşil, zemini açık yeşil.
## Üzerine gelince adı; gelen kutusu ve kampanyada sayı balonu.
func _build_menu(col: HBoxContainer) -> void:
	for id: String in MENU_ICONS:
		if not _menu_buttons.is_empty():
			col.add_child(MainHud.dock_divider())
		var b: Button = UiUtil.icon_button(MENU_ICONS[id], tr("MENU_" + id.to_upper()), func() -> void: toggle_panel(id),
			MainHud.MENU_ICON)
		b.theme_type_variation = "DockIcon"
		_menu_buttons[id] = b
		var dot: Label = UiUtil.label("", 12, CozyTheme.CREAM_LIGHT)
		dot.add_theme_font_override("font", CozyTheme.strong_font(800))
		dot.add_theme_stylebox_override("normal", CozyTheme.box(CozyTheme.TERRA, 10, CozyTheme.CREAM_LIGHT, 2, false, Vector2(6, 0)))
		dot.position = Vector2(28, -6)
		dot.visible = false
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(dot)
		_menu_dots[id] = dot
		col.add_child(b)


## Menü ekranlarının yüzen penceresi: ekranın ortasında; içeriği kadar, merkezden iki yana büyür.
func _build_window() -> void:
	_window = PanelContainer.new()
	add_child(_window)
	_window.anchor_left = 0.5
	_window.anchor_right = 0.5
	_window.offset_left = -WINDOW_WIDTH * 0.5
	_window.offset_right = WINDOW_WIDTH * 0.5
	_window.grow_vertical = Control.GROW_DIRECTION_BOTH
	# UI-2: yeşil başlık bandı (ikon + başlık + kapat), altında içerik.
	var parts: Array = UiUtil.window_frame(_window)
	_window_title = parts[0]
	_content = parts[1]
	(parts[2] as HBoxContainer).add_child(UiUtil.close_button(close_panel))
	_window.visible = false


## Pencereyi kapatır, ofis görünür.
func close_panel() -> void:
	_window.visible = false
	UiUtil.clear(_content)
	_panel = null
	_scroll = null
	_panel_id = ""
	_refresh_menu_state()


## İnşa modu (M6-B): pencere kapanır, ofisin altında araç çubuğu açılır.
func enter_build_mode() -> void:
	close_panel()
	if _employee_card != null:
		_employee_card.queue_free()
		_employee_card = null
	if _build_bar != null:
		return
	_build_bar = BuildToolbar.new(_office, exit_build_mode)
	add_child(_build_bar)
	move_child(_build_bar, _modal_layer.get_index())
	# Dokun hemen üstünde, ortada (menü penceresiyle aynı yer).
	_build_bar.anchor_left = (1.0 - BUILD_BAR_WIDTH) * 0.5
	_build_bar.anchor_right = 1.0 - (1.0 - BUILD_BAR_WIDTH) * 0.5
	_build_bar.anchor_top = 1.0
	_build_bar.anchor_bottom = 1.0
	_build_bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_layout()
	_refresh_menu_state()


func exit_build_mode() -> void:
	if _build_bar != null:
		_build_bar.queue_free()
		_build_bar = null
		_refresh_menu_state()


## Ofiste bir çalışana tıklandı: küçük bilgi kartı.
func _on_employee_clicked(employee_id: String) -> void:
	if _employee_card != null:
		_employee_card.queue_free()
	_employee_card = EmployeeCard.new(employee_id, func() -> void: show_panel("team"))
	add_child(_employee_card)
	move_child(_employee_card, _modal_layer.get_index())
	# Sağ altta, dokun üstünde (ortadaki pencereyle çakışmasın).
	_employee_card.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_employee_card.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_employee_card.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_employee_card.offset_right = -WINDOW_MARGIN
	_layout()
	UiUtil.pop_in(_employee_card)


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
	var was_visible: bool = _window.visible
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
	_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# C3: tek kaydırma pencerenin kendisinde. Panellerin kendi dikey listeleri kaymaz, boyları içerik kadar olur;
	# böylece pencere içeriği kadar yer kaplar.
	for inner: Node in _panel.find_children("*", "ScrollContainer", true, false):
		if (inner as ScrollContainer).horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED:
			(inner as ScrollContainer).vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_panel)
	_content.add_child(_scroll)
	_panel.minimum_size_changed.connect(_fit_window)
	_panel.call("refresh")
	_fit_window()
	UiUtil.adopt_heading(_window_title, _panel, tr("MENU_" + id.to_upper()), MENU_ICONS.get(id, ""))
	if not was_visible:
		UiUtil.pop_in(_window)
	_refresh_menu_state()


## Açık pencerenin ikonu yeşil (seçili) görünür.
func _refresh_menu_state() -> void:
	_hint.visible = not _window.visible and _build_bar == null  # pencere / inşa çubuğu açıkken arkada kalmasın
	for id: String in _menu_buttons:
		(_menu_buttons[id] as Button).theme_type_variation = "DockIconActive" if id == _panel_id else "DockIcon"


func _refresh() -> void:
	if not GameState.has_game():
		return
	var s: SimState = GameState.sim.state
	if not is_nan(_last_cash) and not is_equal_approx(s.cash, _last_cash):
		Juice.cash_fly(_cash, s.cash - _last_cash, s.clock.year())
	_last_cash = s.cash
	_cash.set_value(s.cash)
	_cash.label_node().add_theme_color_override("font_color", CozyTheme.NEGATIVE if s.cash < 0.0 else CozyTheme.FOREST)
	_rep.set_value(s.reputation)
	_date.text = UiUtil.date_text(s.clock)
	_set_dot("inbox", str(s.inbox.size()) if not s.inbox.is_empty() else "")
	_set_dot("campaign", "!" if GameState.is_waiting() else "")
	_overtime.theme_type_variation = "SpeedActive" if s.overtime else "PillButton"
	if _panel != null:
		_panel.call("refresh")
	_refresh_speed()


func _set_dot(id: String, text: String) -> void:
	var dot: Label = _menu_dots[id]
	dot.text = text
	dot.visible = not text.is_empty()


func _refresh_speed() -> void:
	_pause_button.icon = UiUtil.icon_texture("player-play" if Clock.paused else "player-pause", MainHud.TIME_ICON)
	_pause_button.theme_type_variation = "SpeedActive" if Clock.paused else "PillButton"
	for i: int in _speed_buttons.size():
		_speed_buttons[i].theme_type_variation = "SpeedActive" if not Clock.paused and Clock.speed_index == i \
			else "PillButton"


func _on_notification(key: String, args: Array, kind: String) -> void:
	MainHud.toast(_feed, key, args, kind)


## Modal pencere açar; kapanınca saat kaldığı yerden devam eder.
func open_modal(dialog: Control) -> void:
	_modal_open = true
	Clock.hold()
	_modal_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_modal_layer.add_child(dialog)
	dialog.tree_exited.connect(_on_modal_closed)
	var script: Script = dialog.get_script()
	EventBus.ui_opened.emit(script.get_global_name() if script != null else "")


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


# --- çıkış, kısayollar (M9) --------------------------------------------------------

func _confirm_leave(leave: Callable) -> void:
	MainInput.confirm_leave(self, leave)


func _quit_game() -> void:
	Clock.set_paused(true)
	GameState.end_game()
	get_tree().quit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_confirm_leave(_quit_game)


func _enter_tree() -> void:
	get_tree().set_auto_accept_quit(false)


func _exit_tree() -> void:
	get_tree().set_auto_accept_quit(true)


func _unhandled_input(event: InputEvent) -> void:
	if MainInput.handle(self, event, _modal_layer, _panel_id):
		get_viewport().set_input_as_handled()
