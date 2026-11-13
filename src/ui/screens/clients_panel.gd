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
	var col: VBoxContainer = UiUtil.vbox(CozyTheme.SPACE_S)
	card.add_child(col)
	var sat: float = float(client["satisfaction"])
	var risky: bool = sat < data.balf("clients.risk_threshold")
	var tags: Array = [Cards.warn_chip(tr("UI_RISK_TAG"))] if risky else []
	col.add_child(Cards.header(Cards.tile("building"), str(client["name"]),
		"%s · %s · %s" % [UiUtil.name_of(data.sectors, client["sector"]), tr("SCALE_%d" % int(client["scale"])),
		tr("CONTRACT_" + str(client["contract"]).to_upper())], tags))
	var row: HFlowContainer = Cards.flow_row(CozyTheme.SPACE_M)
	row.add_child(Cards.meter(tr("UI_SATISFACTION"), sat, CozyTheme.NEGATIVE if risky else CozyTheme.POSITIVE, 150.0))
	row.add_child(Cards.chip(tr("UI_TRUST") % int(client["trust"])))
	col.add_child(row)
	col.add_child(UiUtil.label(tr("UI_CLIENT_BUDGET") % [UiUtil.money(client["annual_budget"]),
		(client["history"] as Array).size()], 13, UiUtil.MUTED))
	return card
