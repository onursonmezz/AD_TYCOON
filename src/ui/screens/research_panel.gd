class_name ResearchPanel
extends VBoxContainer
## Ar-Ge (GDD 17) ve Bilgi Defteri: AP, yürüyen araştırma, araştırma listesi (koşullar ✓/✗), keşfedilen uyum hücreleri;
## Pazar Araştırması varsa parayla hücre açma.
## K-122: kaydırma yok; üç sekme (araştırmalar, sektör uyumu, odak önemi), araştırma listesi sayfalı.

const SYMBOLS: Dictionary = {3: "+++", 2: "++", 1: "+", 0: "0", -1: "−", -2: "−−", -3: "−−−"}
const TABS: Array = [["list", "UI_RESEARCH_TAB_LIST"], ["fit", "UI_RESEARCH_TAB_FIT"], ["focus", "UI_RESEARCH_TAB_FOCUS"]]

var _body: VBoxContainer
var _signature: String = ""
var _sector: String = ""
var _tab: String = "list"
var _page: int = -1  # -1: ilk bitmemiş araştırmanın sayfası


func _init() -> void:
	add_theme_constant_override("separation", 10)
	add_child(UiUtil.heading(tr("MENU_RESEARCH")))
	_body = UiUtil.vbox(8)
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_body)


func refresh() -> void:
	var s: SimState = GameState.sim.state
	var sig: String = "%d|%s|%d|%d|%s|%s|%d" % [s.clock.week_index, str(s.research), int(s.cash / 1000.0), str(s.knowledge).length(),
		_sector, _tab, _page]
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
	var hint: Label = UiUtil.label(tr("UI_RESEARCH_SHORT"), 12, CozyTheme.TEXT)
	hint.tooltip_text = tr("UI_RESEARCH_HINT")
	hint.mouse_filter = Control.MOUSE_FILTER_STOP
	head_col.add_child(hint)
	var head: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
	head.add_child(Cards.tile("flask", 48.0, CozyTheme.TERRA_SOFT))
	head.add_child(head_col)
	_body.add_child(head)
	head_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var seg: PanelContainer = UiUtil.segmented(TABS, _tab, func(id: String) -> void:
		_tab = id
		refresh())
	seg.custom_minimum_size.x = 330.0
	head.add_child(seg)
	match _tab:
		"list":
			if not active.is_empty():
				_body.add_child(Cards.section(tr("UI_RESEARCH_ACTIVE") % [tr(data.research[active["id"]]["name_key"]),
					int(active["weeks_left"])], "", "clock"))
			_list_page(sim, s)
		"fit":
			_body.add_child(UiUtil.wrapped(tr("UI_KNOWLEDGE_HINT"), 12, UiUtil.MUTED, 600.0))
			_body.add_child(_knowledge_table(sim, s))
		"focus":
			_body.add_child(_focus_table(sim, s))


## Araştırma kartları sayfa sayfa (ui_layout research_per_page); açılışta ilk bitmemiş araştırmanın sayfası.
func _list_page(sim: Simulation, s: SimState) -> void:
	var ids: Array[String] = DataDB.data.research_ids
	var per: int = int(DataDB.data.raw["ui_layout.json"]["research_per_page"])
	var pages: int = maxi(1, ceili(float(ids.size()) / float(per)))
	if _page < 0:
		_page = 0
		for i: int in ids.size():
			if not sim.research.has(s, ids[i]):
				_page = i / per
				break
	_page = clampi(_page, 0, pages - 1)
	for i: int in range(_page * per, mini(ids.size(), (_page + 1) * per)):
		_body.add_child(_research_row(sim, s, ids[i]))
	if pages <= 1:
		return
	var pager: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
	pager.alignment = BoxContainer.ALIGNMENT_CENTER
	var prev: Button = UiUtil.button("◀", func() -> void: _turn(-1))
	prev.disabled = _page == 0
	pager.add_child(prev)
	pager.add_child(UiUtil.label(tr("UI_PAGE") % [_page + 1, pages], 13, CozyTheme.FOREST))
	var next: Button = UiUtil.button("▶", func() -> void: _turn(1))
	next.disabled = _page >= pages - 1
	pager.add_child(next)
	_body.add_child(pager)


func _turn(step: int) -> void:
	_page += step
	refresh()


## Araştırma kartı: solda ikon, ortada ad, açıklama ve koşul etiketleri; sağda maliyet satırları ve düğme.
func _research_row(sim: Simulation, s: SimState, id: String) -> PanelContainer:
	var data: GameData = DataDB.data
	var rec: Dictionary = data.research[id]
	var done: bool = sim.research.has(s, id)
	var card: PanelContainer = UiUtil.card()
	var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
	card.add_child(row)
	var tile: Control = Cards.art("research_art", id, 44.0, "check" if done else "flask",
		CozyTheme.SAGE_SOFT if done else CozyTheme.TERRA_SOFT)
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
		reqs.add_child(Cards.chip(("✓ " if bool(r["ok"]) else "") + text,
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


## Hedef × odak alanı önemi (K-117): satırlar hedefler, sütunlar dokuz odak alanı; bilinmeyen "?".
func _focus_table(sim: Simulation, s: SimState) -> VBoxContainer:
	var data: GameData = DataDB.data
	var box: VBoxContainer = UiUtil.vbox(6)
	box.add_child(UiUtil.label(tr("UI_KNOW_FOCUS_TITLE"), 16, UiUtil.SAGE_DARK))
	var grid: GridContainer = GridContainer.new()
	grid.columns = data.objective_ids.size() + 1
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 4)
	grid.add_child(Control.new())
	for obj: String in data.objective_ids:
		var head: Label = UiUtil.label(UiUtil.name_of(data.objectives, obj), 11, UiUtil.WOOD)
		head.custom_minimum_size.x = 80.0
		head.autowrap_mode = TextServer.AUTOWRAP_WORD
		head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		grid.add_child(head)
	for f: String in data.focus_ids:
		grid.add_child(UiUtil.label(UiUtil.name_of(data.focus_areas, f), 12, UiUtil.TEXT))
		for obj: String in data.objective_ids:
			var cell: CenterContainer = CenterContainer.new()
			cell.add_child(FocusHint.badge(obj, f, 14))
			grid.add_child(cell)
	box.add_child(grid)
	return box


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
