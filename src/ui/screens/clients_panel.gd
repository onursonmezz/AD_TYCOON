class_name ClientsPanel
extends VBoxContainer
## Müşteri portföyü (GDD 20): sektör, ölçek, memnuniyet barı, güven, yıllık bütçe, risk etiketi.

var _list: VBoxContainer
var _signature: String = ""


func _init() -> void:
	add_theme_constant_override("separation", 10)
	add_child(UiUtil.heading(tr("MENU_CLIENTS")))
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_list = UiUtil.vbox(10)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)


func refresh() -> void:
	var s: SimState = GameState.sim.state
	var sig: String = ""
	for c: Dictionary in s.clients.values():
		sig += "%s%d%d" % [c["id"], int(c["satisfaction"]), (c["history"] as Array).size()]
	if sig == _signature:
		return
	_signature = sig
	UiUtil.clear(_list)
	if s.clients.is_empty():
		_list.add_child(UiUtil.label(tr("UI_NO_CLIENTS"), 16, UiUtil.MUTED))
	for client: Dictionary in s.clients.values():
		_list.add_child(_client_card(client))


func _client_card(client: Dictionary) -> PanelContainer:
	var data: GameData = DataDB.data
	var card: PanelContainer = UiUtil.card()
	var col: VBoxContainer = UiUtil.vbox(4)
	card.add_child(col)
	var top: HBoxContainer = UiUtil.hbox()
	top.add_child(UiUtil.label(str(client["name"]), 19, UiUtil.SAGE_DARK))
	top.add_child(UiUtil.spacer())
	var sat: float = float(client["satisfaction"])
	if sat < data.balf("clients.risk_threshold"):
		top.add_child(UiUtil.label(tr("UI_RISK_TAG"), 14, UiUtil.TERRACOTTA))
	col.add_child(top)
	col.add_child(UiUtil.label("%s · %s · %s" % [UiUtil.name_of(data.sectors, client["sector"]),
		tr("SCALE_%d" % int(client["scale"])), tr("CONTRACT_" + str(client["contract"]).to_upper())], 14, UiUtil.WOOD))
	var row: HBoxContainer = UiUtil.hbox()
	row.add_child(UiUtil.label(tr("UI_SATISFACTION"), 14))
	var bar: ProgressBar = ProgressBar.new()
	bar.max_value = 100.0
	bar.value = sat
	bar.custom_minimum_size = Vector2(180.0, 18.0)
	bar.show_percentage = false
	row.add_child(bar)
	row.add_child(UiUtil.label("%d" % int(sat), 14))
	row.add_child(UiUtil.label(tr("UI_TRUST") % int(client["trust"]), 14))
	col.add_child(row)
	col.add_child(UiUtil.label(tr("UI_CLIENT_BUDGET") % [UiUtil.money(client["annual_budget"]),
		(client["history"] as Array).size()], 14))
	return card
