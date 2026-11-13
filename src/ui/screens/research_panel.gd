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
	# UI-3 (taslak 17): üstte ikon, araştırma puanı ve kısa açıklama.
	var head_col: VBoxContainer = UiUtil.vbox(2)
	head_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var points: Label = UiUtil.label(tr("UI_AP") % float(s.research["points"]), 16, CozyTheme.FOREST)
	points.add_theme_font_override("font", CozyTheme.title_font(700))
	head_col.add_child(points)
	var hint: Label = UiUtil.wrapped(tr("UI_RESEARCH_HINT"), 12, UiUtil.MUTED, 400.0)
	head_col.add_child(hint)
	var head: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
	head.add_child(Cards.tile("flask", 48.0, CozyTheme.TERRA_SOFT))
	head.add_child(head_col)
	_body.add_child(head)
	if not active.is_empty():
		_body.add_child(Cards.section(tr("UI_RESEARCH_ACTIVE") % [tr(data.research[active["id"]]["name_key"]), int(active["weeks_left"])],
			"", "clock"))
	for id: String in data.research_ids:
		_body.add_child(_research_row(sim, s, id))
	_body.add_child(Cards.section(tr("UI_KNOWLEDGE_BOOK")))
	_body.add_child(UiUtil.wrapped(tr("UI_KNOWLEDGE_HINT"), 12, UiUtil.MUTED, 400.0))
	_body.add_child(_knowledge_table(sim, s))


## Araştırma kartı: solda ikon, ortada ad, açıklama ve koşul etiketleri; sağda maliyet satırları ve düğme.
func _research_row(sim: Simulation, s: SimState, id: String) -> PanelContainer:
	var data: GameData = DataDB.data
	var rec: Dictionary = data.research[id]
	var done: bool = sim.research.has(s, id)
	var card: PanelContainer = UiUtil.card()
	var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
	card.add_child(row)
	var tile: PanelContainer = Cards.tile("check" if done else "flask", 44.0, CozyTheme.SAGE_SOFT if done else CozyTheme.TERRA_SOFT)
	tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(tile)
	var mid: VBoxContainer = UiUtil.vbox(2)
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(mid)
	var name: Label = UiUtil.label(tr(rec["name_key"]), 15, CozyTheme.FOREST)
	name.add_theme_font_override("font", CozyTheme.title_font(700))
	mid.add_child(name)
	mid.add_child(UiUtil.wrapped(tr(rec["desc_key"]), 12, CozyTheme.TEXT, 240.0))
	if done:
		return card
	var reqs: HFlowContainer = Cards.flow_row()
	for r: Dictionary in sim.research.requirements(s, id):
		var need: String = tr(str(r["need"])) if r["key"] == "REQ_RESEARCH" else str(r["need"])
		var text: String = tr(str(r["key"]) + "_SHORT") % need
		reqs.add_child(Cards.chip(("✓ " if bool(r["ok"]) else "✗ ") + text,
			CozyTheme.SAGE_SOFT if bool(r["ok"]) else CozyTheme.CREAM, CozyTheme.FOREST if bool(r["ok"]) else CozyTheme.MUTED))
	mid.add_child(reqs)
	row.add_child(VSeparator.new())
	var cost: VBoxContainer = UiUtil.vbox(0)
	cost.custom_minimum_size.x = 96.0
	cost.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cost.add_child(Cards.mini_fact("flask", tr("REQ_AP_SHORT") % str(int(rec["ap"]))))
	cost.add_child(Cards.mini_fact("coins", UiUtil.money(sim.research.cost(s, id))))
	cost.add_child(Cards.mini_fact("calendar", tr("UI_WEEKS") % int(rec["weeks"])))
	row.add_child(cost)
	var b: Button = UiUtil.button(tr("UI_RESEARCH_START"), func() -> void:
		var err: String = GameState.execute(ResearchActionCommand.new("begin", id))
		if not err.is_empty():
			EventBus.notification.emit(err, [], "bad")
		_signature = ""
		refresh())
	b.disabled = not sim.research.can_start(s, id)
	b.theme_type_variation = "PrimaryButton"
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(b)
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
