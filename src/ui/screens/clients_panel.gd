class_name ClientsPanel
extends VBoxContainer
## Müşteri portföyü (GDD 20; UI-3 taslağı 12_musteriler): arama ve sektör süzgeci; her kartta sektör, ölçek, sözleşme,
## memnuniyet ve güven çubukları, sağda yıllık bütçe ve kampanya sayısı.

const LABEL_WIDTH: float = 82.0

var _count: Label
var _search: LineEdit
var _sector: OptionButton
var _sector_ids: Array[String] = []
var _list: VBoxContainer
var _footer: Label
var _signature: String = ""
var _main: Control


func _init(main_screen: Control) -> void:
	_main = main_screen
	add_theme_constant_override("separation", CozyTheme.SPACE_S)
	var top: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	top.add_child(UiUtil.heading(tr("MENU_CLIENTS")))
	_count = UiUtil.label("", 13, CozyTheme.FOREST)
	_count.add_theme_font_override("font", CozyTheme.strong_font())
	_count.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_count)
	_search = LineEdit.new()
	_search.placeholder_text = tr("UI_CLIENT_SEARCH")
	_search.custom_minimum_size.x = 200.0
	Cards.compact(_search)
	_search.text_changed.connect(func(_t: String) -> void: refresh())
	top.add_child(_search)
	_sector = OptionButton.new()
	Cards.compact(_sector)
	_sector.item_selected.connect(func(_i: int) -> void: refresh())
	top.add_child(_sector)
	add_child(top)
	_list = UiUtil.vbox(CozyTheme.SPACE_S)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_list)
	_footer = UiUtil.label("", 12, CozyTheme.TEXT)
	add_child(_footer)


func refresh() -> void:
	var s: SimState = GameState.sim.state
	_fill_sectors(s)
	var sig: String = "%s|%d" % [_search.text, _sector.selected]
	for c: Dictionary in s.clients.values():
		sig += "%s%d%d%d" % [c["id"], int(c["satisfaction"]), int(c["trust"]), (c["history"] as Array).size()]
	if sig == _signature:
		return
	_signature = sig
	UiUtil.clear(_list)
	_count.text = tr("UI_CLIENTS_COUNT") % s.clients.size()
	if s.clients.is_empty():
		_list.add_child(UiUtil.label(tr("UI_NO_CLIENTS"), 15, UiUtil.MUTED))
	var needle: String = _search.text.strip_edges().to_lower()
	var sector: String = _sector_ids[_sector.selected - 1] if _sector.selected > 0 else ""
	var shown: int = 0
	for client: Dictionary in s.clients.values():
		if not sector.is_empty() and str(client["sector"]) != sector:
			continue
		if not needle.is_empty() and not str(client["name"]).to_lower().contains(needle):
			continue
		_list.add_child(_client_card(client))
		shown += 1
	_footer.text = tr("UI_CLIENTS_SHOWN") % shown


## Sektör süzgeci: yalnızca müşterisi olan sektörler (ilk seçenek "tüm sektörler").
func _fill_sectors(s: SimState) -> void:
	var ids: Array[String] = []
	for c: Dictionary in s.clients.values():
		if not ids.has(str(c["sector"])):
			ids.append(str(c["sector"]))
	if ids == _sector_ids and _sector.item_count > 0:
		return
	var current: String = _sector_ids[_sector.selected - 1] if _sector.selected > 0 else ""
	_sector_ids = ids
	_sector.clear()
	_sector.add_item(tr("UI_ALL_SECTORS"))
	for id: String in ids:
		_sector.add_item(UiUtil.name_of(DataDB.data.sectors, id))
	_sector.select(ids.find(current) + 1)


func _client_card(client: Dictionary) -> PanelContainer:
	var data: GameData = DataDB.data
	var card: PanelContainer = UiUtil.card()
	var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_L)
	card.add_child(row)
	var tile: Control = Cards.art("brand_art", str(client["name"]), 56.0, "building")
	tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(tile)
	var sat: float = float(client["satisfaction"])
	var risky: bool = sat < data.balf("clients.risk_threshold")
	var mid: VBoxContainer = UiUtil.vbox(2)
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(mid)
	var tags: Array = [Cards.warn_chip(tr("UI_RISK_TAG"))] if risky else []
	mid.add_child(Cards.header(null, str(client["name"]), "", tags))
	var sub: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	sub.add_child(UiUtil.label("%s · %s" % [UiUtil.name_of(data.sectors, client["sector"]), tr("SCALE_%d" % int(client["scale"]))],
		13, CozyTheme.TEXT))
	sub.add_child(Cards.chip(tr("CONTRACT_" + str(client["contract"]).to_upper()), CozyTheme.CREAM, CozyTheme.TEXT))
	mid.add_child(sub)
	mid.add_child(_meter(tr("UI_SATISFACTION"), sat, CozyTheme.NEGATIVE if risky else CozyTheme.FOREST_LIGHT))
	mid.add_child(_meter(tr("UI_TRUST_NAME"), float(client["trust"]), CozyTheme.SAGE))
	row.add_child(VSeparator.new())
	var side: VBoxContainer = UiUtil.vbox(2)
	side.custom_minimum_size.x = 170.0
	side.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(side)
	side.add_child(UiUtil.label(tr("UI_ANNUAL_BUDGET"), 12, CozyTheme.MUTED))
	var budget: Label = UiUtil.label(UiUtil.money(client["annual_budget"]), 17, CozyTheme.FOREST)
	budget.add_theme_font_override("font", CozyTheme.strong_font())
	side.add_child(budget)
	var camp: HBoxContainer = UiUtil.hbox(6)
	camp.add_child(UiUtil.icon("speakerphone", 18, CozyTheme.TERRA))
	camp.add_child(UiUtil.label(tr("UI_CAMPAIGN_COUNT") % (client["history"] as Array).size(), 13, CozyTheme.TEXT))
	side.add_child(camp)
	var arrow: TextureRect = UiUtil.icon("chevron-right", 14, CozyTheme.FOREST)
	arrow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(arrow)
	# Kartın tamamı (ok dahil) müşteri kartını açar.
	card.tooltip_text = tr("UI_CLIENT_OPEN")
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	_pass_clicks(row)
	card.gui_input.connect(func(e: InputEvent) -> void:
		var mb: InputEventMouseButton = e as InputEventMouseButton
		if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_main.call("open_modal", ClientDialog.new(client, _main)))
	return card


## Çubuk gibi tıklamayı yutan alt öğeler tıklamayı karta bıraksın.
func _pass_clicks(node: Node) -> void:
	for c: Node in node.get_children():
		if c is Control and (c as Control).mouse_filter == Control.MOUSE_FILTER_STOP:
			(c as Control).mouse_filter = Control.MOUSE_FILTER_PASS
		_pass_clicks(c)


func _meter(caption: String, value: float, color: Color) -> HBoxContainer:
	var m: HBoxContainer = Cards.meter(caption, value, color, 170.0)
	(m.get_child(0) as Label).custom_minimum_size.x = LABEL_WIDTH
	(m.get_child(0) as Label).add_theme_color_override("font_color", CozyTheme.TEXT)
	return m
