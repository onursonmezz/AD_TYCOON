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
	if done:  # S7: biten araştırmanın sağında açık bir "Tamamlandı" etiketi
		var ok: PanelContainer = Cards.chip("✓ " + tr("UI_RESEARCH_DONE"))
		row.add_child(ok)
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
	# S7: kapalı düğmenin nedeni ipucunda; yürüyen araştırmanın kartında düğme yerine kalan süre.
	var active: Dictionary = s.research["active"]
	if str(active.get("id", "")) == id:
		row.add_child(Cards.chip(tr("UI_RESEARCH_RUNNING") % int(active["weeks_left"]), CozyTheme.SAGE_SOFT, CozyTheme.FOREST))
		return card
	if b.disabled:
		b.tooltip_text = tr("UI_RESEARCH_WHY_BUSY") if not active.is_empty() else tr("UI_RESEARCH_WHY_REQ")
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
			# S10: Sektör uyumu gibi renkli kutu (iyi yeşil, kötü kiremit, bilinmeyen soluk); ipucu FocusHint'ten.
			var is_known: bool = FocusHint.known(obj, f)
			var v: int = FocusHint.value(obj, f)
			var pill: PanelContainer = PanelContainer.new()
			var fill: Color = CozyTheme.CREAM
			if is_known:
				fill = CozyTheme.SAGE_SOFT if v > 0 else (CozyTheme.TERRA_SOFT if v < 0 else CozyTheme.CREAM_LIGHT)
			pill.add_theme_stylebox_override("panel", CozyTheme.box(fill, 6, CozyTheme.BORDER if not is_known else Color.TRANSPARENT,
				1 if not is_known else 0, false, Vector2(2, 1)))
			var badge: Label = FocusHint.badge(obj, f, 13)
			badge.add_theme_font_override("font", CozyTheme.strong_font())
			pill.add_child(badge)
			grid.add_child(pill)
	box.add_child(grid)
	return box


## Sektör uyumu (S7): solda sektör listesi (her birinde kaç hücrenin bilindiği), sağda seçilenin hedef ve kitle
## uyumları renkli hücrelerde. Eskiden açılır menü ve düz "+/?" yazısıydı.
func _knowledge_table(sim: Simulation, s: SimState) -> HBoxContainer:
	var data: GameData = DataDB.data
	var sectors: Array[String] = data.sectors_available(s.clock.year())
	if _sector.is_empty() or not sectors.has(_sector):
		_sector = sectors[0]
	var box: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(200.0, float(DataDB.data.raw["ui_layout.json"].get("research_fit_list_height", 300)))
	box.add_child(scroll)
	var list: VBoxContainer = UiUtil.vbox(4)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	var cells: int = data.objective_ids.size() + data.audience_ids.size()
	for id: String in sectors:
		var known: int = _known_cells(sim, s, id)
		var b: Button = UiUtil.button("%s   %d/%d" % [UiUtil.name_of(data.sectors, id), known, cells], func() -> void:
			_sector = id
			_signature = ""
			refresh())
		Cards.compact(b, id == _sector)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if id == _sector:
			b.add_theme_color_override("font_color", CozyTheme.CREAM_LIGHT)
			b.add_theme_color_override("font_hover_color", CozyTheme.CREAM_LIGHT)
		list.add_child(b)
	var right: VBoxContainer = UiUtil.vbox(CozyTheme.SPACE_S)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(right)
	var title_row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
	var title: Label = UiUtil.label(UiUtil.name_of(data.sectors, _sector), 16, CozyTheme.FOREST)
	title.add_theme_font_override("font", CozyTheme.title_font(700))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	if sim.research.has(s, "market_research"):
		var buy: Button = UiUtil.button(tr("UI_BUY_INSIGHT") % UiUtil.money(sim.research.market_research_cost(s)), func() -> void:
			var err: String = GameState.execute(ResearchActionCommand.new("insight", _sector))
			if not err.is_empty():
				EventBus.notification.emit(err, [], "bad")
			_signature = ""
			refresh())
		Cards.compact(buy, true)
		buy.disabled = _known_cells(sim, s, _sector) >= cells
		title_row.add_child(buy)
	right.add_child(title_row)
	for spec: Array in [["sector_objective", data.objective_ids, data.objectives, "UI_FIT_OBJECTIVES"],
			["sector_audience", data.audience_ids, data.audiences, "UI_FIT_AUDIENCES"]]:
		right.add_child(Cards.section(tr(spec[3]), ""))
		var grid: GridContainer = GridContainer.new()
		grid.columns = mini(6, (spec[1] as Array).size())
		grid.add_theme_constant_override("h_separation", CozyTheme.SPACE_S)
		grid.add_theme_constant_override("v_separation", CozyTheme.SPACE_S)
		# S11: başlıklar bir satırda, kutular altındaki satırda; satır yüksekliğini en uzun başlık belirler, kutular hep hizalı.
		for col_id: String in spec[1]:
			grid.add_child(_fit_head(UiUtil.name_of(spec[2], col_id)))
		for col_id: String in spec[1]:
			var known: bool = sim.research.is_known(s, spec[0], _sector, col_id)
			grid.add_child(_fit_pill(data.fit(spec[0], _sector, col_id), known))
		right.add_child(grid)
	right.add_child(UiUtil.wrapped(tr("UI_KNOWLEDGE_HINT"), 11, UiUtil.MUTED, 420.0))
	return box


func _known_cells(sim: Simulation, s: SimState, sector: String) -> int:
	var n: int = 0
	for spec: Array in [["sector_objective", DataDB.data.objective_ids], ["sector_audience", DataDB.data.audience_ids]]:
		for col_id: String in spec[1]:
			if sim.research.is_known(s, spec[0], sector, col_id):
				n += 1
	return n


## Uyum başlığı: ortalı, gerekirse alt alta; tablonun başlık satırında alta yaslı.
func _fit_head(name: String) -> Label:
	var head: Label = UiUtil.label(name, 11, CozyTheme.WOOD)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head.custom_minimum_size.x = 72.0
	head.size_flags_vertical = Control.SIZE_FILL
	head.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	return head


## Uyum kutusu: +++ / − / ? (iyi yeşil, kötü kiremit, nötr krem, bilinmeyen soluk).
func _fit_pill(v: int, known: bool) -> PanelContainer:
	var fill: Color = CozyTheme.CREAM
	var ink: Color = CozyTheme.MUTED
	if known:
		fill = CozyTheme.SAGE_SOFT if v > 0 else (CozyTheme.TERRA_SOFT if v < 0 else CozyTheme.CREAM_LIGHT)
		ink = CozyTheme.FOREST if v > 0 else (CozyTheme.NEGATIVE if v < 0 else CozyTheme.TEXT)
	var pill: PanelContainer = PanelContainer.new()
	pill.add_theme_stylebox_override("panel", CozyTheme.box(fill, 8, CozyTheme.BORDER if not known else Color.TRANSPARENT,
		1 if not known else 0, false, Vector2(6, 4)))
	var sym: Label = UiUtil.label(SYMBOLS[v] if known else "?", 16, ink)
	sym.add_theme_font_override("font", CozyTheme.strong_font())
	sym.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pill.add_child(sym)
	pill.tooltip_text = tr("UI_FIT_UNKNOWN") if not known else ""
	pill.custom_minimum_size.x = 72.0
	return pill
