class_name ToolsPanel
extends VBoxContainer
## Araçlar (GDD 12.4–12.5): alan başına araç seti ve çarpanı, sürüm durumu, al / güncelle / aboneliğe geç / iptal;
## bilgisayar kuşağı ve aylık abonelik gideri. "Ekipman" sekmesi: prodüksiyon ekipmanı (K-119, EquipmentList; taslak 15'te yok).
## K-122: kaydırma yok; alanlar iki sütunda, satırlar tek satır (uzun durum metni üzerine gelince).

var _body: VBoxContainer
var _signature: String = ""
var _tab: String = "software"


func _init() -> void:
	add_theme_constant_override("separation", 10)
	add_child(UiUtil.heading(tr("MENU_TOOLS")))
	_body = UiUtil.vbox(8)
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_body)


func refresh() -> void:
	var s: SimState = GameState.sim.state
	var sig: String = "%d|%s|%s|%d|%d|%s|%s" % [s.clock.year(), str(s.tools), s.hardware, int(s.cash / 1000.0), s.staff.size(),
		str(s.equipment), _tab]
	if sig == _signature:
		return
	_signature = sig
	rebuild()


func rebuild() -> void:
	UiUtil.clear(_body)
	var sim: Simulation = GameState.sim
	var s: SimState = sim.state
	var data: GameData = DataDB.data
	var tabs: PanelContainer = UiUtil.segmented([["software", "UI_TOOLS_TAB_SOFTWARE"], ["equipment", "UI_TOOLS_TAB_EQUIPMENT"]], _tab,
		func(id: String) -> void:
			_tab = id
			_signature = ""
			refresh())
	tabs.custom_minimum_size.x = 300.0
	if _tab == "equipment":
		_body.add_child(EquipmentList.build(func() -> void:
			_signature = ""
			refresh(), tabs))  # UI-4: sekmeler bakım satırının sağında
		return
	# UI-3 (taslak 15): üstte bilgisayar kuşağı ve aylık abonelik; altında alan alan araç tablosu.
	var head: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
	head.add_child(Cards.art("hardware_art", "default", 52.0, "device-desktop"))
	var hw_col: VBoxContainer = UiUtil.vbox(-2)
	hw_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hw_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hw_col.add_child(UiUtil.label(tr("UI_HARDWARE_COMPAT") % int(data.hardware[s.hardware]["max_tool_year"]), 12, CozyTheme.TEXT))
	var hw: Label = UiUtil.label(tr("UI_HARDWARE_NAME") % tr(data.hardware[s.hardware]["name_key"]), 15, CozyTheme.FOREST)
	hw.add_theme_font_override("font", CozyTheme.title_font(700))
	hw.clip_text = true
	hw_col.add_child(hw)
	hw_col.move_child(hw, 0)
	head.add_child(hw_col)
	var next_hw: String = ""
	for id: String in data.hardware_ids:
		if data.hardware_ids.find(id) > data.hardware_ids.find(s.hardware) and int(data.hardware[id]["available_from"]) <= s.clock.year():
			next_hw = id
	if not next_hw.is_empty():
		var buy: Button = _action_button(tr("UI_HARDWARE_BUY") % [tr(data.hardware[next_hw]["name_key"]),
			UiUtil.money(sim.tools.hardware_cost(s, next_hw))], "hardware", next_hw)
		buy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		head.add_child(buy)
	var monthly: PanelContainer = Cards.chip(tr("UI_TOOLS_MONTHLY") % UiUtil.money(sim.tools.monthly_cost(s)), CozyTheme.CREAM_LIGHT,
		CozyTheme.FOREST, tr("UI_TOOLS_HINT"))
	monthly.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	hw_col.add_child(monthly)
	head.add_child(tabs)  # K-122: sekmeler bilgisayar satırının sağında (ayrı satır kaplamasın)
	_body.add_child(head)
	# UI-4: iki sütun, alanlar satır sayısına göre kısa olan sütuna eklenir (sıra korunur, sütunlar dengeli).
	var pair: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
	_body.add_child(pair)
	var columns: Array[VBoxContainer] = []
	var heights: Array[int] = [0, 0]
	for i: int in 2:
		var c: VBoxContainer = UiUtil.vbox(CozyTheme.SPACE_S)
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pair.add_child(c)
		columns.append(c)
	for area: Variant in data.bal("tools.areas"):
		var col: VBoxContainer = UiUtil.vbox(4)
		col.add_child(Cards.section(tr("AREA_" + str(area).to_upper()), "×" + UiUtil.num(float(s.tool_mults.get(area, 1.0)), 2)))
		var rows: int = 0
		for id: String in data.tool_ids:
			if data.tools[id]["area"] == area and (sim.tools.owned(s, id) or sim.tools.available(s).has(id)):
				col.add_child(_tool_row(sim, s, id))
				rows += 1
		var pick: int = 0 if heights[0] <= heights[1] else 1
		columns[pick].add_child(col)
		heights[pick] += rows + 1


func _tool_row(sim: Simulation, s: SimState, id: String) -> HBoxContainer:
	var t: Dictionary = DataDB.data.tools[id]
	var year: int = s.clock.year()
	var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	row.custom_minimum_size.y = 24.0
	var owned: bool = sim.tools.owned(s, id)
	row.add_child(UiUtil.icon("tool", 18, CozyTheme.TERRA if owned else CozyTheme.MUTED))
	var name_label: Label = UiUtil.label(UiUtil.name_of(DataDB.data.tools, id), 13, CozyTheme.TEXT)
	name_label.add_theme_font_override("font", CozyTheme.strong_font())
	name_label.custom_minimum_size.x = 104.0
	name_label.clip_text = true
	name_label.tooltip_text = name_label.text
	name_label.mouse_filter = Control.MOUSE_FILTER_STOP
	row.add_child(name_label)
	var status: String = ""
	var color: Color = UiUtil.TEXT
	if owned:
		var v: int = int(s.tools[id]["version"])
		var behind: int = sim.tools.released_version(id, year) - v
		status = tr("UI_TOOL_VERSION") % int(t["versions"][v][0])
		if bool(s.tools[id]["sub"]):
			status += " · " + tr("UI_TOOL_SUB") % UiUtil.money(sim.tools.seat_cost(s, id))
		if behind > 0:
			status += " · " + tr("UI_TOOL_BEHIND") % behind
			color = UiUtil.TERRACOTTA
	else:
		status = tr("UI_TOOL_NOT_OWNED")
		color = UiUtil.MUTED
	if float(t["ai_penalty"]) > 0.0:
		status += " · " + tr("UI_TOOL_AI")
	var st: Label = UiUtil.label(status, 11, color)
	st.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	st.clip_text = true
	st.tooltip_text = status
	st.mouse_filter = Control.MOUSE_FILTER_STOP
	row.add_child(st)
	if bool(t["starter"]):
		row.add_child(Cards.chip("✓ " + tr("UI_TOOL_IN_USE")))
		return row
	var sub_era: bool = sim.tools.is_subscription_era(id, year)
	if not sim.tools.owned(s, id):
		var price: String = tr("UI_TOOL_SEAT") % UiUtil.money(sim.tools.seat_cost(s, id)) if sub_era \
			else UiUtil.money(sim.tools.license_cost(s, id))
		row.add_child(_action_button(tr("UI_TOOL_BUY") % price, "buy", id))
	elif bool(s.tools[id]["sub"]):
		row.add_child(_action_button(tr("UI_TOOL_CANCEL"), "cancel", id))
	elif sub_era:
		row.add_child(_action_button(tr("UI_TOOL_SUBSCRIBE") % UiUtil.money(sim.tools.seat_cost(s, id)), "subscribe", id))
	elif sim.tools.released_version(id, year) > int(s.tools[id]["version"]):
		row.add_child(_action_button(tr("UI_TOOL_UPDATE") % UiUtil.money(sim.tools.update_cost(s, id)), "update", id))
	return row


func _action_button(text: String, action: String, id: String) -> Button:
	var b: Button = UiUtil.button(text, func() -> void:
		var err: String = GameState.execute(ToolActionCommand.new(action, id))
		if not err.is_empty():
			EventBus.notification.emit(err, [], "bad")
		_signature = ""
		refresh())
	Cards.compact(b)
	return b
