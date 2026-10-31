class_name TeamPanel
extends VBoxContainer
## Ekip ekranı (GDD 20, 11): çalışan kartları, statlar, enerji/moral/tükenmişlik, eğitim, uzmanlaşma, zam, kovma.

var _main: Control
var _header: Label
var _list: VBoxContainer
var _signature: String = ""


func _init(main_screen: Control) -> void:
	_main = main_screen
	add_theme_constant_override("separation", 10)
	var top: HBoxContainer = UiUtil.hbox()
	top.add_child(UiUtil.heading(tr("MENU_TEAM")))
	top.add_child(UiUtil.spacer())
	top.add_child(UiUtil.button(tr("UI_HIRE"), func() -> void: _main.call("open_modal", HiringDialog.new())))
	add_child(top)
	_header = UiUtil.label("", 15, UiUtil.WOOD)
	add_child(_header)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_list = UiUtil.vbox(10)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)


func refresh() -> void:
	var sim: Simulation = GameState.sim
	var s: SimState = sim.state
	_header.text = tr("UI_TEAM_HEADER") % [s.staff.size(), sim.staff.capacity(s), UiUtil.money(sim.staff.monthly_payroll(s))]
	var sig: String = str(s.clock.week_index)
	for emp: Dictionary in s.staff.values():
		sig += str(emp["id"]) + str(emp["level"]) + str(emp["salary"])
	if sig == _signature:
		return
	_signature = sig
	UiUtil.clear(_list)
	for emp: Dictionary in s.staff.values():
		_list.add_child(_card(emp, sim))


func _card(emp: Dictionary, sim: Simulation) -> PanelContainer:
	var data: GameData = DataDB.data
	var s: SimState = sim.state
	var card: PanelContainer = UiUtil.card()
	var col: VBoxContainer = UiUtil.vbox(5)
	card.add_child(col)
	var top: HBoxContainer = UiUtil.hbox()
	top.add_child(UiUtil.label(GameState.employee_name(emp), 19, UiUtil.SAGE_DARK))
	top.add_child(UiUtil.label("%s · %s" % [tr(Employee.title_key(data, emp)), tr("UI_LEVEL") % int(emp["level"])], 15, UiUtil.WOOD))
	top.add_child(UiUtil.spacer())
	if not Employee.is_available(emp, s.clock.week_index):
		top.add_child(UiUtil.label(tr("BUSY_" + str(emp["busy_reason"]).to_upper()) % (int(emp["busy_until"]) - s.clock.week_index),
			14, UiUtil.TERRACOTTA))
	col.add_child(top)
	if not str(emp.get("specialization", "")).is_empty():
		col.add_child(UiUtil.label(tr("UI_SPECIALIZED") % UiUtil.name_of(data.sectors, emp["specialization"]), 14, UiUtil.MUSTARD))
	col.add_child(_stats_row(emp))
	col.add_child(_bars_row(emp))
	col.add_child(_traits_row(emp))
	if not bool(emp["is_founder"]):
		var market: float = Employee.market_value(data, emp, s.clock.year())
		var pay_color: Color = UiUtil.TERRACOTTA if float(emp["salary"]) < market * data.balf("staff_rules.offer_check_ratio") else UiUtil.TEXT
		col.add_child(UiUtil.label(tr("UI_SALARY_LINE") % [UiUtil.money(emp["salary"]), UiUtil.money(market)], 14, pay_color))
	col.add_child(_actions_row(emp, sim))
	return card


func _stats_row(emp: Dictionary) -> HBoxContainer:
	var row: HBoxContainer = UiUtil.hbox(14)
	for stat: Variant in DataDB.data.bal("staff_rules.stats"):
		row.add_child(UiUtil.label("%s %d" % [tr("STAT_" + str(stat).to_upper()), int(emp["stats"][stat])], 14))
	var hidden: String = tr("UI_HIDDEN_UNKNOWN")
	if bool(emp["hidden_revealed"]):
		hidden = tr("UI_HIDDEN_LINE") % [int(emp["hidden"]["potential"]), int(emp["hidden"]["loyalty"])]
	var h: Label = UiUtil.label(hidden, 13, UiUtil.MUTED)
	h.tooltip_text = tr("TIP_HIDDEN")
	h.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(h)
	return row


func _bars_row(emp: Dictionary) -> HBoxContainer:
	var row: HBoxContainer = UiUtil.hbox(8)
	for key: String in ["energy", "morale", "burnout"]:
		row.add_child(UiUtil.label(tr("UI_" + key.to_upper()), 13))
		var bar: ProgressBar = ProgressBar.new()
		bar.max_value = 100.0
		bar.value = float(emp[key])
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(90.0, 14.0)
		bar.tooltip_text = "%d" % int(emp[key])
		row.add_child(bar)
	return row


func _traits_row(emp: Dictionary) -> HBoxContainer:
	var row: HBoxContainer = UiUtil.hbox(8)
	for t: Variant in emp.get("traits", []):
		var rec: Dictionary = DataDB.data.traits.get(str(t), {})
		var l: Label = UiUtil.label("◆ " + tr(str(rec.get("name_key", t))), 13, UiUtil.WOOD)
		l.tooltip_text = tr(str(rec.get("desc_key", "")))
		l.mouse_filter = Control.MOUSE_FILTER_PASS
		row.add_child(l)
	return row


func _actions_row(emp: Dictionary, sim: Simulation) -> HBoxContainer:
	var data: GameData = DataDB.data
	var row: HBoxContainer = UiUtil.hbox(8)
	var stat_pick: OptionButton = OptionButton.new()
	var stats: Array = data.bal("staff_rules.stats")
	for stat: Variant in stats:
		stat_pick.add_item(tr("STAT_" + str(stat).to_upper()))
	row.add_child(stat_pick)
	row.add_child(UiUtil.button(tr("UI_TRAIN") % UiUtil.money(sim.staff.training_cost(sim.state)), func() -> void:
		_run(TrainEmployeeCommand.new(emp["id"], str(stats[stat_pick.selected])))))
	if int(emp["level"]) >= data.bali("staff_rules.specialization_min_level") and str(emp.get("specialization", "")).is_empty():
		var sector_pick: OptionButton = OptionButton.new()
		for id: String in data.sector_ids:
			sector_pick.add_item(UiUtil.name_of(data.sectors, id))
		row.add_child(sector_pick)
		row.add_child(UiUtil.button(tr("UI_SPECIALIZE"), func() -> void:
			_run(TrainEmployeeCommand.new(emp["id"], "", data.sector_ids[sector_pick.selected]))))
	if not bool(emp["is_founder"]):
		row.add_child(UiUtil.spacer())
		row.add_child(UiUtil.button(tr("UI_RAISE"), func() -> void: _run(RaiseSalaryCommand.new(emp["id"]))))
		row.add_child(UiUtil.button(tr("UI_FIRE") % UiUtil.money(sim.staff.severance(sim.state, emp)), func() -> void:
			_run(FireEmployeeCommand.new(emp["id"]))))
	return row


func _run(command: RefCounted) -> void:
	var err: Variant = GameState.execute(command)
	if typeof(err) == TYPE_STRING and not str(err).is_empty():
		EventBus.notification.emit(str(err), [], "bad")
	_signature = ""
	refresh()
