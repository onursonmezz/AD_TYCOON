class_name ResearchPanel
extends VBoxContainer
## Ar-Ge (GDD 17) ve Bilgi Defteri: AP, yürüyen araştırma, araştırma listesi (koşullar ✓/✗), keşfedilen uyum hücreleri;
## Pazar Araştırması varsa parayla hücre açma.

const SYMBOLS: Dictionary = {3: "+++", 2: "++", 1: "+", 0: "0", -1: "−", -2: "−−", -3: "−−−"}

var _body: VBoxContainer
var _signature: String = ""
var _sector: String = ""


func _init() -> void:
	add_theme_constant_override("separation", 10)
	add_child(UiUtil.heading(tr("MENU_RESEARCH")))
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_body = UiUtil.vbox(8)
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_body)


func refresh() -> void:
	var s: SimState = GameState.sim.state
	var sig: String = "%d|%s|%d|%d|%s" % [s.clock.week_index, str(s.research), int(s.cash / 1000.0), str(s.knowledge).length(), _sector]
	if sig == _signature:
		return
	_signature = sig
	rebuild()


func rebuild() -> void:
	UiUtil.clear(_body)
	var sim: Simulation = GameState.sim
	var s: SimState = sim.state
	var data: GameData = DataDB.data
	var active: Dictionary = s.research["active"]
	_body.add_child(UiUtil.label(tr("UI_AP") % float(s.research["points"]), 18, UiUtil.SAGE_DARK))
	_body.add_child(UiUtil.wrapped(tr("UI_RESEARCH_HINT"), 13, UiUtil.MUTED, 640.0))
	if not active.is_empty():
		_body.add_child(UiUtil.label(tr("UI_RESEARCH_ACTIVE") % [tr(data.research[active["id"]]["name_key"]), int(active["weeks_left"])],
			15, UiUtil.WOOD))
	for id: String in data.research_ids:
		_body.add_child(_research_row(sim, s, id))
	_body.add_child(UiUtil.label(tr("UI_KNOWLEDGE_BOOK"), 18, UiUtil.SAGE_DARK))
	_body.add_child(UiUtil.wrapped(tr("UI_KNOWLEDGE_HINT"), 13, UiUtil.MUTED, 640.0))
	_body.add_child(_knowledge_table(sim, s))


func _research_row(sim: Simulation, s: SimState, id: String) -> PanelContainer:
	var data: GameData = DataDB.data
	var card: PanelContainer = UiUtil.card()
	var col: VBoxContainer = UiUtil.vbox(2)
	card.add_child(col)
	var top: HBoxContainer = UiUtil.hbox()
	var done: bool = sim.research.has(s, id)
	top.add_child(UiUtil.label(("✓ " if done else "") + tr(data.research[id]["name_key"]), 16, UiUtil.SAGE_DARK if done else UiUtil.TEXT))
	top.add_child(UiUtil.spacer())
	if not done:
		top.add_child(UiUtil.label(tr("UI_RESEARCH_COST") % [int(data.research[id]["ap"]), UiUtil.money(sim.research.cost(s, id)),
			int(data.research[id]["weeks"])], 13, UiUtil.WOOD))
		var b: Button = UiUtil.button(tr("UI_RESEARCH_START"), func() -> void:
			var err: String = GameState.execute(ResearchActionCommand.new("begin", id))
			if not err.is_empty():
				EventBus.notification.emit(err, [], "bad")
			_signature = ""
			refresh())
		b.disabled = not sim.research.can_start(s, id)
		top.add_child(b)
	col.add_child(top)
	col.add_child(UiUtil.wrapped(tr(data.research[id]["desc_key"]), 13, UiUtil.MUTED, 600.0))
	if not done:
		var reqs: PackedStringArray = PackedStringArray()
		for r: Dictionary in sim.research.requirements(s, id):
			var need: String = tr(str(r["need"])) if r["key"] == "REQ_RESEARCH" else str(r["need"])
			reqs.append(("✓ " if bool(r["ok"]) else "✗ ") + tr(str(r["key"]) + "_SHORT") % need)
		col.add_child(UiUtil.label(" · ".join(reqs), 12, UiUtil.TEXT))
	return card


## Seçilen sektörün hedef ve kitle uyumları; bilinmeyen hücre "?".
func _knowledge_table(sim: Simulation, s: SimState) -> VBoxContainer:
	var data: GameData = DataDB.data
	var box: VBoxContainer = UiUtil.vbox(6)
	var pick: OptionButton = OptionButton.new()
	var sectors: Array[String] = data.sectors_available(s.clock.year())
	if _sector.is_empty() or not sectors.has(_sector):
		_sector = sectors[0]
	for i: int in sectors.size():
		pick.add_item(UiUtil.name_of(data.sectors, sectors[i]))
		if sectors[i] == _sector:
			pick.selected = i
	pick.item_selected.connect(func(i: int) -> void:
		_sector = sectors[i]
		_signature = ""
		refresh())
	var row: HBoxContainer = UiUtil.hbox()
	row.add_child(pick)
	if sim.research.has(s, "market_research"):
		row.add_child(UiUtil.button(tr("UI_BUY_INSIGHT") % UiUtil.money(sim.research.market_research_cost(s)), func() -> void:
			var err: String = GameState.execute(ResearchActionCommand.new("insight", _sector))
			if not err.is_empty():
				EventBus.notification.emit(err, [], "bad")
			_signature = ""
			refresh()))
	box.add_child(row)
	for spec: Array in [["sector_objective", data.objective_ids, data.objectives], ["sector_audience", data.audience_ids, data.audiences]]:
		var grid: GridContainer = GridContainer.new()
		grid.columns = (spec[1] as Array).size()
		grid.add_theme_constant_override("h_separation", 16)
		for col_id: String in spec[1]:
			grid.add_child(UiUtil.label(UiUtil.name_of(spec[2], col_id), 12, UiUtil.WOOD))
		for col_id: String in spec[1]:
			var known: bool = sim.research.is_known(s, spec[0], _sector, col_id)
			var v: int = data.fit(spec[0], _sector, col_id)
			grid.add_child(UiUtil.label(SYMBOLS[v] if known else "?", 15,
				UiUtil.MUTED if not known else (UiUtil.SAGE_DARK if v > 0 else (UiUtil.TERRACOTTA if v < 0 else UiUtil.TEXT))))
		box.add_child(grid)
	return box
