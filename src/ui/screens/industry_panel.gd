class_name IndustryPanel
extends VBoxContainer
## Sektör ekranı (GDD 14.3, 15): ödül takvimi ve başvuru, yıl sonu sıralamaları, kazandığımız ödüller, rakip ajanslar.
## UI-2d: üç sekme (ödül takvimi + kazandıklarımız, sıralamalar, rakipler); ödüller ikonlu satır kartları.

const RANK_ROWS: int = 5
const AWARD_ROWS: int = 8
const TABS: Array = [["awards", "UI_AWARD_CALENDAR"], ["rankings", "UI_RANKINGS"], ["rivals", "UI_RIVALS"]]
const AWARD_ICONS: Array[String] = ["star", "speakerphone", "heart", "trophy"]

var _main: Control
var _body: VBoxContainer
var _week: int = -1
var _tab: String = "awards"


func _init(main_screen: Control) -> void:
	_main = main_screen
	add_theme_constant_override("separation", 10)
	add_child(UiUtil.heading(tr("MENU_INDUSTRY")))
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_body = UiUtil.vbox(10)
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_body)


func refresh() -> void:
	var s: SimState = GameState.sim.state
	if s.clock.week_index == _week:
		return
	_week = s.clock.week_index
	rebuild()


func rebuild() -> void:
	UiUtil.clear(_body)
	_body.add_child(UiUtil.segmented(TABS, _tab, func(id: String) -> void:
		_tab = id
		rebuild()))
	match _tab:
		"awards":
			_body.add_child(_awards_block())
			var won: PanelContainer = PanelContainer.new()
			won.theme_type_variation = "Card"
			var col: VBoxContainer = UiUtil.vbox(6)
			won.add_child(col)
			var head: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
			head.alignment = BoxContainer.ALIGNMENT_CENTER
			head.add_child(UiUtil.icon("trophy", 24, CozyTheme.GOLD))
			var title: Label = UiUtil.label(tr("UI_OUR_AWARDS"), 20, CozyTheme.FOREST)
			title.add_theme_font_override("font", CozyTheme.title_font())
			head.add_child(title)
			head.add_child(UiUtil.icon("trophy", 24, CozyTheme.GOLD))
			col.add_child(head)
			col.add_child(_our_awards())
			_body.add_child(won)
		"rankings":
			_body.add_child(_rankings())
		"rivals":
			_body.add_child(_rivals())


func _awards_block() -> VBoxContainer:
	var sim: Simulation = GameState.sim
	var data: GameData = DataDB.data
	var list: VBoxContainer = UiUtil.vbox(CozyTheme.SPACE_S)
	var i: int = 0
	for id: String in sim.awards.available(sim.state):
		var card: PanelContainer = PanelContainer.new()
		card.theme_type_variation = "Card"
		card.tooltip_text = tr(data.awards[id]["desc_key"])
		list.add_child(card)
		var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
		card.add_child(row)
		var icon_name: String = str(data.awards[id].get("icon", AWARD_ICONS[i % AWARD_ICONS.size()]))
		row.add_child(UiUtil.icon(icon_name, 30, [CozyTheme.GOLD, CozyTheme.ACCENT, CozyTheme.NEGATIVE, CozyTheme.FOREST_LIGHT][i % 4]))
		i += 1
		var info: VBoxContainer = UiUtil.vbox(0)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var name: Label = UiUtil.label(UiUtil.name_of(data.awards, id), 16, CozyTheme.TEXT)
		name.add_theme_font_override("font", CozyTheme.strong_font(800))
		info.add_child(name)
		info.add_child(UiUtil.label(tr("UI_AWARD_WHEN") % [tr("MONTH_%d" % sim.awards.entry_month(id)),
			tr("MONTH_%d" % int(data.awards[id]["month"]))], 13, CozyTheme.MUTED))
		row.add_child(info)
		var fee: Label = UiUtil.label(UiUtil.money(sim.awards.entry_fee(sim.state, id)), 16, CozyTheme.TEXT)
		fee.add_theme_font_override("font", CozyTheme.strong_font(800))
		row.add_child(fee)
		if sim.awards.is_open(sim.state, id):
			var enter: Button = UiUtil.button(tr("UI_AWARD_ENTER"), func() -> void:
				_main.call("open_modal", AwardEntryDialog.new(id, rebuild)))
			enter.icon = UiUtil.icon_texture("chevron-right", 18)
			enter.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			row.add_child(enter)
		else:
			row.add_child(UiUtil.label(tr("UI_AWARD_CLOSED"), 13, CozyTheme.MUTED))
	return list


func _our_awards() -> VBoxContainer:
	var box: VBoxContainer = UiUtil.vbox(2)
	var won: Array[Dictionary] = []
	for r: Dictionary in GameState.sim.state.award_history:
		if not str(r["level"]).is_empty():
			won.append(r)
	if won.is_empty():
		box.add_child(UiUtil.label(tr("UI_NO_AWARDS"), 14, UiUtil.MUTED))
	for i: int in range(won.size() - 1, maxi(-1, won.size() - 1 - AWARD_ROWS), -1):
		var r: Dictionary = won[i]
		box.add_child(UiUtil.label("%d · %s · %s — %s" % [int(r["year"]), UiUtil.name_of(DataDB.data.awards, r["award"]),
			tr("LEVEL_" + str(r["level"]).to_upper()), r.get("client_name", "")], 14, UiUtil.MUSTARD))
	return box


func _who(who: String) -> String:
	return tr("UI_US") if who == "player" else UiUtil.name_of(DataDB.data.rivals, who)


func _rankings() -> Control:
	var r: Dictionary = GameState.sim.state.rankings
	if r.is_empty():
		return UiUtil.label(tr("UI_NO_RANKINGS"), 14, UiUtil.MUTED)
	var row: HBoxContainer = UiUtil.hbox(30)
	for list: Array in [[ "UI_RANK_CREATIVE", r["creative"], "points"], ["UI_RANK_BIGGEST", r["biggest"], "revenue"]]:
		var col: VBoxContainer = UiUtil.vbox(2)
		col.add_child(UiUtil.label(tr(list[0]) % int(r["year"]), 15, UiUtil.WOOD))
		var rows: Array = list[1]
		for i: int in mini(RANK_ROWS, rows.size()):
			var e: Dictionary = rows[i]
			var value: String = "%d" % int(e["points"]) if list[2] == "points" else UiUtil.money(float(e["revenue"]))
			col.add_child(UiUtil.label("%d. %s — %s" % [i + 1, _who(e["who"]), value], 14,
				UiUtil.SAGE_DARK if e["who"] == "player" else UiUtil.TEXT))
		row.add_child(col)
	var box: VBoxContainer = UiUtil.vbox(4)
	box.add_child(UiUtil.label(tr("UI_OUR_RANKS") % [int(r["creative_rank"]), int(r["biggest_rank"])], 15))
	if not str(r["agency_of_year"]).is_empty():
		box.add_child(UiUtil.label(tr("UI_AGENCY_OF_YEAR") % _who(r["agency_of_year"]), 15, UiUtil.MUSTARD))
	box.add_child(row)
	return box


func _rivals() -> GridContainer:
	var sim: Simulation = GameState.sim
	var data: GameData = DataDB.data
	var grid: GridContainer = GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 18)
	for key: String in ["UI_COL_AGENCY", "UI_COL_TYPE", "UI_COL_STAFF", "UI_COL_REPUTATION", "UI_COL_POWER"]:
		grid.add_child(UiUtil.label(tr(key), 13, UiUtil.WOOD))
	var ids: Array = sim.state.rivals.keys()
	ids.sort_custom(func(a: String, b: String) -> bool:
		return sim.rivals.power(sim.state, a) > sim.rivals.power(sim.state, b))
	for id: String in ids:
		var rv: Dictionary = sim.state.rivals[id]
		var alive: bool = bool(rv["alive"])
		var color: Color = UiUtil.TEXT if alive else UiUtil.MUTED
		var name_label: Label = UiUtil.label(UiUtil.name_of(data.rivals, id), 14, color)
		var sectors: Array[String] = []
		for sec: Variant in data.rivals[id]["sectors"]:
			sectors.append(UiUtil.name_of(data.sectors, str(sec)))
		name_label.tooltip_text = tr("UI_RIVAL_SECTORS") % ", ".join(sectors)
		name_label.mouse_filter = Control.MOUSE_FILTER_PASS
		grid.add_child(name_label)
		grid.add_child(UiUtil.label(tr("PERS_" + str(data.rivals[id]["personality"]).to_upper()), 14, color))
		grid.add_child(UiUtil.label("%d" % int(roundf(float(rv["staff"]))) if alive else tr("UI_RIVAL_CLOSED") % int(rv["closed_year"]), 14, color))
		grid.add_child(UiUtil.label("%.0f" % float(rv["reputation"]), 14, color))
		grid.add_child(UiUtil.label("%.1f" % sim.rivals.power(sim.state, id) if alive else "—", 14, color))
	return grid
