class_name TaskPlanDialog
extends Control
## Görev planı (S3A, Game Dev Tycoon tarzı): kampanya başlamadan bir kez. Üç faz yan yana; her görevin ağırlık
## çubuğu (fazın üç görevi oranlanır, toplam %100) ve atama gereken işlerde tek kişilik atama yeri. Altta kişilerin
## kampanya yükü (atandığı görevlerin ağırlık toplamı; %100 üstü yorulur). Küçük iş / tek kişi: atama yok.
## Onaylanınca StartCampaignCommand (choices + sliders + assign + rentals, planned).

const ROW_H: float = 58.0

var _brief: Dictionary
var _choices: Dictionary
var _on_started: Callable
var _team: Array = []
var _assign_mode: bool = false
var _raw: Array = [[50.0, 50.0, 50.0], [50.0, 50.0, 50.0], [50.0, 50.0, 50.0]]
var _assign: Array = [["", "", ""], ["", "", ""], ["", "", ""]]
var _rentals: Array = []
var _share_labels: Array = [[], [], []]
var _who_buttons: Array = [[], [], []]
var _loads: Dictionary = {}  # emp_id → Label
var _error: Label


func _init(brief: Dictionary, choices: Dictionary, on_started: Callable) -> void:
	_brief = brief
	_choices = choices
	_on_started = on_started
	_team = (choices.get("team", []) as Array).duplicate()


func _ready() -> void:
	set_meta("esc_closes", true)
	var data: GameData = DataDB.data
	_assign_mode = TaskPlan.needs_assignment(data, {"size": _brief["size"], "team": _team})
	if _assign_mode:
		_assign = TaskPlan.auto_assign(data, GameState.sim.state, sliders(), _team)
	var col: VBoxContainer = UiUtil.modal_frame(self, UiUtil.dialog_size("task_plan"), true, true)
	col.add_child(UiUtil.heading(tr("UI_PLAN_TITLE"), "users-group"))
	col.add_child(UiUtil.wrapped(tr("UI_PLAN_HINT_ASSIGN" if _assign_mode else "UI_PLAN_HINT_AUTO"), 13, CozyTheme.TEXT, 400.0))
	var phases: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	for p: int in 3:
		phases.add_child(_phase_card(p))
	col.add_child(phases)
	if _assign_mode:
		col.add_child(_load_strip())
	var frame: VBoxContainer = UiUtil.modal_outer(col)
	frame.add_child(HSeparator.new())
	_error = UiUtil.label("", 13, CozyTheme.NEGATIVE)
	_error.visible = false
	frame.add_child(_error)
	var foot: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	foot.add_child(UiUtil.spacer())
	if _assign_mode:
		foot.add_child(UiUtil.button(tr("UI_BOARD_AUTO"), func() -> void:
			_assign = TaskPlan.auto_assign(DataDB.data, GameState.sim.state, sliders(), _team)
			_refresh()))
	foot.add_child(UiUtil.button(tr("UI_BACK"), queue_free))
	var start: Button = UiUtil.button(tr("UI_START_CAMPAIGN"), _start)
	start.theme_type_variation = "PrimaryButton"
	foot.add_child(start)
	frame.add_child(foot)
	_refresh()


## Ham çubuk değerlerinden faz başına paylar (toplam 1).
func sliders() -> Array:
	var out: Array = []
	for p: int in 3:
		var total: float = float(_raw[p][0]) + float(_raw[p][1]) + float(_raw[p][2])
		if total <= 0.0:
			out.append([1.0 / 3.0, 1.0 / 3.0, 1.0 - 2.0 / 3.0])
			continue
		var a: float = float(_raw[p][0]) / total
		var b: float = float(_raw[p][1]) / total
		out.append([a, b, 1.0 - a - b])
	return out


func _phase_card(p: int) -> PanelContainer:
	var data: GameData = DataDB.data
	var card: PanelContainer = UiUtil.card()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box: VBoxContainer = UiUtil.vbox(4)
	card.add_child(box)
	box.add_child(Cards.section(tr("PHASE_%d" % p)))
	var areas: Array[String] = data.focus_ids_of_phase(p)
	for i: int in 3:
		box.add_child(_task_row(p, i, areas[i]))
	if p == 2:
		box.add_child(_rentals_box())
	return card


func _task_row(p: int, i: int, area: String) -> VBoxContainer:
	var data: GameData = DataDB.data
	var row: VBoxContainer = UiUtil.vbox(0)
	row.custom_minimum_size.y = ROW_H
	var top: HBoxContainer = UiUtil.hbox(6)
	top.add_child(UiUtil.icon(str(WorkBoard.AREA_ICONS.get(area, "info")), 18, CozyTheme.TERRA))
	var name: Label = UiUtil.label(UiUtil.name_of(data.focus_areas, area), 13, CozyTheme.TEXT)
	name.add_theme_font_override("font", CozyTheme.strong_font())
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.clip_text = true
	top.add_child(name)
	top.add_child(FocusHint.badge(str(_choices.get("objective", _brief["objective"])), area, 12))
	var share: Label = UiUtil.label("", 13, CozyTheme.FOREST)
	share.add_theme_font_override("font", CozyTheme.strong_font())
	share.custom_minimum_size.x = 40.0
	share.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(share)
	(_share_labels[p] as Array).append(share)
	row.add_child(top)
	var bottom: HBoxContainer = UiUtil.hbox(6)
	var slider: HSlider = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 5.0
	slider.value = float(_raw[p][i])
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.tooltip_text = tr("UI_PLAN_WEIGHT_TIP")
	slider.value_changed.connect(func(v: float) -> void:
		_raw[p][i] = v
		_refresh())
	bottom.add_child(slider)
	if _assign_mode:
		var who: Button = Button.new()
		who.focus_mode = Control.FOCUS_NONE
		who.custom_minimum_size = Vector2(112.0, 30.0)
		who.clip_text = true
		who.add_theme_font_size_override("font_size", 12)
		who.pressed.connect(func() -> void: _pick_person(p, i, area, who))
		(_who_buttons[p] as Array).append(who)
		bottom.add_child(who)
	row.add_child(bottom)
	return row


## Görevin kişisini seçme: ekipteki herkes portresi, o göreve uygunluğu ve yüküyle; "Kimse" ile boşaltılır.
func _pick_person(p: int, i: int, area: String, anchor: Button) -> void:
	var data: GameData = DataDB.data
	var popup: PopupPanel = PopupPanel.new()
	popup.add_theme_stylebox_override("panel", CozyTheme.box(CozyTheme.CREAM_LIGHT, 12, CozyTheme.BORDER, 1, true, Vector2(8, 8)))
	var list: VBoxContainer = UiUtil.vbox(4)
	popup.add_child(list)
	for id: Variant in _team:
		var emp: Dictionary = GameState.sim.state.staff.get(str(id), {})
		if emp.is_empty():
			continue
		var b: Button = Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(250.0, 40.0)
		var line: HBoxContainer = UiUtil.hbox(8)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 4)
		b.add_child(line)
		line.add_child(Cards.avatar(emp, 30.0))
		var who: VBoxContainer = UiUtil.vbox(-3)
		who.add_child(UiUtil.label(GameState.employee_name(emp), 13, CozyTheme.TEXT))
		var fit: int = int(roundf(Employee.area_stat(data, emp, area)))
		who.add_child(UiUtil.label(tr("UI_PLAN_PICK_INFO") % [fit, UiUtil.percent(roundf(_load_of(str(id)) * 100.0))], 11,
			CozyTheme.MUTED))
		line.add_child(who)
		b.pressed.connect(func() -> void:
			_assign[p][i] = str(id)
			popup.queue_free()
			_refresh())
		list.add_child(b)
	list.add_child(UiUtil.button(tr("UI_PLAN_NOBODY"), func() -> void:
		_assign[p][i] = ""
		popup.queue_free()
		_refresh()))
	add_child(popup)
	popup.popup(Rect2i(Vector2i(anchor.get_screen_position() + Vector2(0.0, anchor.size.y)), Vector2i(260, 10)))
	popup.popup_hide.connect(popup.queue_free)


func _load_of(emp_id: String) -> float:
	return TaskPlan.campaign_load({"sliders": sliders(), "assign": _assign}, emp_id)


func _load_strip() -> HFlowContainer:
	var flow: HFlowContainer = Cards.flow_row(CozyTheme.SPACE_M)
	for id: Variant in _team:
		var emp: Dictionary = GameState.sim.state.staff.get(str(id), {})
		if emp.is_empty():
			continue
		var item: HBoxContainer = UiUtil.hbox(6)
		item.add_child(Cards.avatar(emp, 28.0))
		var l: Label = UiUtil.label("", 13, CozyTheme.TEXT)
		l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		item.add_child(l)
		_loads[str(id)] = l
		flow.add_child(item)
	return flow


## Prodüksiyon fazının kiralıkları (K-119): bedeli kampanya başlarken ödenir.
func _rentals_box() -> Control:
	var sim: Simulation = GameState.sim
	var ids: Array = sim.equipment.available(sim.state, "rental")
	var box: VBoxContainer = UiUtil.vbox(4)
	var flow: HFlowContainer = Cards.flow_row(4)
	if ids.is_empty():
		return box
	box.add_child(UiUtil.label(tr("UI_PLAN_RENTALS"), 12, CozyTheme.WOOD))
	box.add_child(flow)
	for id: Variant in ids:
		var b: Button = UiUtil.button(tr("UI_BOARD_RENT") % [UiUtil.name_of(DataDB.data.equipment, str(id)),
			UiUtil.money(sim.equipment.price(sim.state, str(id)))], func() -> void: pass)
		b.toggle_mode = true
		b.add_theme_font_size_override("font_size", 11)
		b.toggled.connect(func(on: bool) -> void:
			if on and not _rentals.has(id):
				_rentals.append(id)
			elif not on:
				_rentals.erase(id))
		flow.add_child(b)
	return box


func _refresh() -> void:
	var data: GameData = DataDB.data
	var s: Array = sliders()
	for p: int in 3:
		for i: int in 3:
			(_share_labels[p][i] as Label).text = UiUtil.percent(roundf(float(s[p][i]) * 100.0))
			if _assign_mode:
				var b: Button = _who_buttons[p][i]
				var id: String = str(_assign[p][i])
				var emp: Dictionary = GameState.sim.state.staff.get(id, {})
				b.text = (str(GameState.employee_name(emp)).split(" ")[0] if not emp.is_empty() else tr("UI_PLAN_ASSIGN"))
				b.add_theme_color_override("font_color", CozyTheme.FOREST if not emp.is_empty() else CozyTheme.TERRA)
				b.icon = UiUtil.icon_texture("user" if not emp.is_empty() else "users", 14)
	for id: String in _loads:
		var load: float = _load_of(id)
		var emp: Dictionary = GameState.sim.state.staff[id]
		var col: Color = CozyTheme.MUTED if load <= 0.0 else (CozyTheme.FOREST if load <= data.balf("workload.warn_load") + 0.001
			else (CozyTheme.GOLD if load <= data.balf("workload.danger_load") else CozyTheme.NEGATIVE))
		var l: Label = _loads[id]
		l.text = "%s · %s" % [str(GameState.employee_name(emp)).split(" ")[0],
			tr("UI_BOARD_FREE") if load <= 0.0 else tr("UI_BOARD_LOAD") % UiUtil.percent(roundf(load * 100.0))]
		l.add_theme_color_override("font_color", col)
	if _error != null:
		_error.visible = false


func _start() -> void:
	var choices: Dictionary = _choices.duplicate(true)
	choices["sliders"] = sliders()
	choices["planned"] = true
	choices["minigames"] = bool(Settings.get_value("minigames"))
	choices["rentals"] = _rentals.duplicate()
	if _assign_mode:
		choices["assign"] = _assign.duplicate(true)
	var result: Dictionary = GameState.execute(StartCampaignCommand.new(_brief["id"], choices))
	if not bool(result["ok"]):
		_error.text = tr(str(result["error"]))
		_error.visible = true
		return
	_on_started.call()
	queue_free()
