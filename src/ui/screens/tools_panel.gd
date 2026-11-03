class_name ToolsPanel
extends VBoxContainer
## Araçlar (GDD 12.4–12.5): alan başına araç seti ve çarpanı, sürüm durumu, al / güncelle / aboneliğe geç / iptal;
## bilgisayar kuşağı ve aylık abonelik gideri.

var _body: VBoxContainer
var _signature: String = ""


func _init() -> void:
	add_theme_constant_override("separation", 10)
	add_child(UiUtil.heading(tr("MENU_TOOLS")))
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_body = UiUtil.vbox(8)
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_body)


func refresh() -> void:
	var s: SimState = GameState.sim.state
	var sig: String = "%d|%s|%s|%d|%d" % [s.clock.year(), str(s.tools), s.hardware, int(s.cash / 1000.0), s.staff.size()]
	if sig == _signature:
		return
	_signature = sig
	rebuild()


func rebuild() -> void:
	UiUtil.clear(_body)
	var sim: Simulation = GameState.sim
	var s: SimState = sim.state
	var data: GameData = DataDB.data
	_body.add_child(UiUtil.wrapped(tr("UI_TOOLS_HINT"), 14, UiUtil.MUTED, 640.0))
	var hw_row: HBoxContainer = UiUtil.hbox()
	hw_row.add_child(UiUtil.label(tr("UI_HARDWARE") % [tr(data.hardware[s.hardware]["name_key"]),
		int(data.hardware[s.hardware]["max_tool_year"])], 15))
	hw_row.add_child(UiUtil.spacer())
	var next_hw: String = ""
	for id: String in data.hardware_ids:
		if data.hardware_ids.find(id) > data.hardware_ids.find(s.hardware) and int(data.hardware[id]["available_from"]) <= s.clock.year():
			next_hw = id
	if not next_hw.is_empty():
		hw_row.add_child(_action_button(tr("UI_HARDWARE_BUY") % [tr(data.hardware[next_hw]["name_key"]),
			UiUtil.money(sim.tools.hardware_cost(s, next_hw))], "hardware", next_hw))
	_body.add_child(hw_row)
	_body.add_child(UiUtil.label(tr("UI_TOOLS_MONTHLY") % UiUtil.money(sim.tools.monthly_cost(s)), 14, UiUtil.WOOD))
	for area: Variant in data.bal("tools.areas"):
		_body.add_child(UiUtil.label(tr("UI_TOOL_AREA") % [tr("AREA_" + str(area).to_upper()), float(s.tool_mults.get(area, 1.0))], 17,
			UiUtil.SAGE_DARK))
		for id: String in data.tool_ids:
			if data.tools[id]["area"] == area and (sim.tools.owned(s, id) or sim.tools.available(s).has(id)):
				_body.add_child(_tool_row(sim, s, id))


func _tool_row(sim: Simulation, s: SimState, id: String) -> HBoxContainer:
	var t: Dictionary = DataDB.data.tools[id]
	var year: int = s.clock.year()
	var row: HBoxContainer = UiUtil.hbox()
	var name_label: Label = UiUtil.label(UiUtil.name_of(DataDB.data.tools, id), 15)
	name_label.custom_minimum_size.x = 190.0
	row.add_child(name_label)
	var status: String = ""
	var color: Color = UiUtil.TEXT
	if sim.tools.owned(s, id):
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
	row.add_child(UiUtil.label(status, 13, color))
	row.add_child(UiUtil.spacer())
	if bool(t["starter"]):
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
	b.add_theme_font_size_override("font_size", 13)
	return b
