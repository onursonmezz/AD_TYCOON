class_name InboxPanel
extends VBoxContainer
## Gelen kutusu (GDD 6.2, 20): brief kartları, kabul (sihirbaz) ve ret.

var _main: Control
var _list: VBoxContainer
var _signature: String = ""


func _init(main_screen: Control) -> void:
	_main = main_screen
	add_theme_constant_override("separation", 10)
	add_child(UiUtil.heading(tr("MENU_INBOX")))
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_list = UiUtil.vbox(10)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)


func refresh() -> void:
	var s: SimState = GameState.sim.state
	var sig: String = str(s.inbox.size()) + str(s.is_idle()) + str(s.clock.week_index)
	for b: Dictionary in s.inbox:
		sig += str(b["id"])
	for o: Dictionary in s.supplier_offers:
		sig += str(o["id"])
	if sig == _signature:
		return
	_signature = sig
	UiUtil.clear(_list)
	for offer: Dictionary in s.supplier_offers:
		_list.add_child(_supplier_offer_card(offer, s))
	if s.inbox.is_empty():
		_list.add_child(UiUtil.wrapped(tr("UI_INBOX_EMPTY"), 16, UiUtil.MUTED, 400.0))
		return
	if not s.is_idle():
		_list.add_child(UiUtil.wrapped(tr("UI_BUSY_HINT"), 14, UiUtil.WOOD, 400.0))
	for brief: Dictionary in s.inbox:
		_list.add_child(_brief_card(brief, s))


## Matbaadan gelen teklif (GDD 10.3): hacim indirimi ya da yıllık taahhüt.
func _supplier_offer_card(offer: Dictionary, s: SimState) -> PanelContainer:
	var card: PanelContainer = UiUtil.card()
	var col: VBoxContainer = UiUtil.vbox(4)
	card.add_child(col)
	var top: HBoxContainer = UiUtil.hbox()
	top.add_child(UiUtil.label(tr(DataDB.data.suppliers[offer["supplier"]]["name_key"]), 18, UiUtil.WOOD))
	top.add_child(UiUtil.label(tr("UI_SUPPLIER_OFFER"), 14, UiUtil.MUSTARD))
	top.add_child(UiUtil.spacer())
	top.add_child(UiUtil.label(tr("UI_EXPIRES") % (int(offer["expires_week"]) - s.clock.week_index), 13, UiUtil.MUTED))
	col.add_child(top)
	col.add_child(UiUtil.wrapped(UiUtil.supplier_offer_text(offer), 15, UiUtil.TEXT, 400.0))
	var buttons: HBoxContainer = UiUtil.hbox()
	buttons.add_child(UiUtil.spacer())
	buttons.add_child(UiUtil.button(tr("UI_DECLINE"), func() -> void:
		GameState.execute(RespondSupplierOfferCommand.new(offer["id"], false))))
	buttons.add_child(UiUtil.button(tr("UI_ACCEPT"), func() -> void:
		GameState.execute(RespondSupplierOfferCommand.new(offer["id"], true))
		EventBus.notification.emit("NOTE_DEAL_SIGNED", [tr(DataDB.data.suppliers[offer["supplier"]]["name_key"])], "good")))
	col.add_child(buttons)
	return card


func _brief_card(brief: Dictionary, s: SimState) -> PanelContainer:
	var data: GameData = DataDB.data
	var client: Dictionary = brief["prospect"] if not (brief["prospect"] as Dictionary).is_empty() \
		else s.clients.get(brief["client_id"], {})
	var card: PanelContainer = UiUtil.card()
	var col: VBoxContainer = UiUtil.vbox(4)
	card.add_child(col)
	var top: HBoxContainer = UiUtil.hbox()
	top.add_child(UiUtil.label(str(client.get("name", "?")), 19, UiUtil.SAGE_DARK))
	if not (brief["prospect"] as Dictionary).is_empty():
		top.add_child(UiUtil.label(tr("UI_NEW_CLIENT"), 14, UiUtil.TERRACOTTA))
	top.add_child(UiUtil.spacer())
	var weeks_left: int = int(brief["expires_week"]) - s.clock.week_index
	top.add_child(UiUtil.label(tr("UI_EXPIRES") % weeks_left, 13, UiUtil.MUTED))
	col.add_child(top)
	var objective: String = tr("UI_OBJECTIVE_FREE") if str(brief["objective"]).is_empty() \
		else UiUtil.name_of(data.objectives, brief["objective"])
	col.add_child(UiUtil.label("%s · %s · %s" % [UiUtil.name_of(data.sectors, brief["sector"]),
		tr("SCALE_%d" % int(client.get("scale", 0))), tr("SIZE_" + str(brief["size"]).to_upper())], 14, UiUtil.WOOD))
	col.add_child(UiUtil.label(tr("UI_BRIEF_OBJECTIVE") % objective, 15))
	col.add_child(UiUtil.label(tr("UI_BRIEF_MONEY") % [UiUtil.money(brief["fee"]), UiUtil.money(brief["media_budget"]),
		int(brief["deadline_weeks"])], 15))
	var buttons: HBoxContainer = UiUtil.hbox()
	buttons.add_child(UiUtil.spacer())
	buttons.add_child(UiUtil.button(tr("UI_DECLINE"), func() -> void:
		GameState.execute(DeclineBriefCommand.new(brief["id"]))))
	var accept: Button = UiUtil.button(tr("UI_ACCEPT"), func() -> void:
		_main.call("open_modal", WizardDialog.new(brief, _main)))
	accept.disabled = not s.is_idle()
	buttons.add_child(accept)
	col.add_child(buttons)
	return card
