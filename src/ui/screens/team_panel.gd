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
	_header = UiUtil.label("", 14, UiUtil.WOOD)
	_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_header)
	top.add_child(UiUtil.button(tr("UI_HIRE"), func() -> void: _main.call("open_modal", HiringDialog.new())))
	add_child(top)
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
	var col: VBoxContainer = UiUtil.vbox(CozyTheme.SPACE_S)
	card.add_child(col)
	# C2: portre + ad, sağda durum etiketleri.
	var tags: Array = []
	if not str(emp.get("specialization", "")).is_empty():
		tags.append(Cards.accent_chip(UiUtil.name_of(data.sectors, emp["specialization"]),
			tr("UI_SPECIALIZED") % UiUtil.name_of(data.sectors, emp["specialization"])))
	if not Employee.is_available(emp, s.clock.week_index):
		tags.append(Cards.warn_chip(tr("BUSY_" + str(emp["busy_reason"]).to_upper()) % (int(emp["busy_until"]) - s.clock.week_index)))
	col.add_child(Cards.header(Cards.avatar(emp), GameState.employee_name(emp),
		"%s · %s" % [tr(Employee.title_key(data, emp)), tr("UI_LEVEL") % int(emp["level"])], tags))
	col.add_child(Cards.stats(emp["stats"]))
	col.add_child(_bars_row(emp))
	col.add_child(_traits_row(emp))
	if not bool(emp["is_founder"]):
		var market: float = Employee.market_value(data, emp, s.clock.year())
		var pay_color: Color = UiUtil.TERRACOTTA if float(emp["salary"]) < market * data.balf("staff_rules.offer_check_ratio") else UiUtil.MUTED
		col.add_child(UiUtil.label(tr("UI_SALARY_LINE") % [UiUtil.money(emp["salary"]), UiUtil.money(market)], 13, pay_color))
	col.add_child(_actions_row(emp, sim))
	return card


func _bars_row(emp: Dictionary) -> HFlowContainer:
	var row: HFlowContainer = Cards.flow_row(CozyTheme.SPACE_M)
	var colors: Dictionary = {"energy": CozyTheme.POSITIVE, "morale": CozyTheme.ACCENT, "burnout": CozyTheme.NEGATIVE}
	for key: String in ["energy", "morale", "burnout"]:
		row.add_child(Cards.meter(tr("UI_" + key.to_upper()), float(emp[key]), colors[key]))
	return row


## Özellikler, sertifikalar ve gizli statlar (potansiyel, sadakat) küçük etiketler hâlinde.
func _traits_row(emp: Dictionary) -> HFlowContainer:
	var row: HFlowContainer = Cards.flow_row()
	for t: Variant in emp.get("traits", []):
		var rec: Dictionary = DataDB.data.traits.get(str(t), {})
		row.add_child(Cards.accent_chip(tr(str(rec.get("name_key", t))), tr(str(rec.get("desc_key", "")))))
	var certs: PackedStringArray = PackedStringArray()
	for area: Variant in emp.get("certs", []):
		certs.append(tr("AREA_" + str(area).to_upper()))
	if not certs.is_empty():
		row.add_child(Cards.chip(tr("UI_CERTS") % ", ".join(certs)))
	var hidden: String = tr("UI_HIDDEN_UNKNOWN")
	if bool(emp["hidden_revealed"]):
		hidden = tr("UI_HIDDEN_LINE") % [int(emp["hidden"]["potential"]), int(emp["hidden"]["loyalty"])]
	row.add_child(Cards.chip(hidden, CozyTheme.CREAM, CozyTheme.MUTED, tr("TIP_HIDDEN")))
	return row


func _actions_row(emp: Dictionary, sim: Simulation) -> HFlowContainer:
	var data: GameData = DataDB.data
	# Satır uzayınca (sertifika, M7-C) düğmeler alt satıra kayar.
	var row: HFlowContainer = HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 6)
	var stat_pick: OptionButton = OptionButton.new()
	var stats: Array = data.bal("staff_rules.stats")
	for stat: Variant in stats:
		stat_pick.add_item(tr("STAT_" + str(stat).to_upper() + "_NAME"))
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
	# Yazılım sertifikası (M7-C): ajansın gerçek aracı olan, çalışanın henüz sertifikası olmayan alanlar.
	var areas: Array[String] = []
	for area: Variant in data.bal("tools.areas"):
		if sim.staff.has_real_tool(sim.state, str(area)) and not (emp.get("certs", []) as Array).has(area):
			areas.append(str(area))
	if not areas.is_empty():
		var area_pick: OptionButton = OptionButton.new()
		for area: String in areas:
			area_pick.add_item(tr("AREA_" + area.to_upper()))
		row.add_child(area_pick)
		row.add_child(UiUtil.button(tr("UI_CERTIFY") % UiUtil.money(sim.staff.certification_cost(sim.state)), func() -> void:
			_run(TrainEmployeeCommand.new(emp["id"], "", "", areas[area_pick.selected]))))
	if not bool(emp["is_founder"]):
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
