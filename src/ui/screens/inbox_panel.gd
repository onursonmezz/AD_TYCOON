class_name InboxPanel
extends VBoxContainer
## Gelen kutusu (GDD 6.2, 20; UI-3 taslakları 06/07): Tümü / Briefler / Teklifler sekmeleri; brief kartları
## (kabul = sihirbaz, ret), tedarikçi teklifleri, ihale davetleri ve yürüyen pitch.

const TABS: Array = [["all", "UI_TAB_ALL"], ["briefs", "UI_TAB_BRIEFS"], ["offers", "UI_TAB_OFFERS"]]

var _main: Control
var _tabs: HBoxContainer
var _list: VBoxContainer
var _tab: String = "all"
var _signature: String = ""


func _init(main_screen: Control) -> void:
	_main = main_screen
	add_theme_constant_override("separation", CozyTheme.SPACE_S)
	add_child(UiUtil.heading(tr("MENU_INBOX")))
	_tabs = UiUtil.hbox()
	add_child(_tabs)
	_list = UiUtil.vbox(CozyTheme.SPACE_S)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_list)


func _pick_tab(id: String) -> void:
	_tab = id
	refresh()


func refresh() -> void:
	var s: SimState = GameState.sim.state
	var sig: String = _tab + str(s.inbox.size()) + str(s.is_idle()) + str(s.clock.week_index)
	for b: Dictionary in s.inbox:
		sig += str(b["id"])
	for o: Dictionary in s.supplier_offers:
		sig += str(o["id"])
	for inv: Dictionary in s.pitch_invites:
		sig += str(inv["id"])
	sig += str(s.pitch.get("phase", ""))
	if sig == _signature:
		return
	_signature = sig
	UiUtil.clear(_tabs)
	var seg: PanelContainer = UiUtil.segmented(TABS, _tab, _pick_tab)
	seg.custom_minimum_size.x = 330.0
	_tabs.add_child(seg)
	UiUtil.clear(_list)
	var shown: int = 0
	if _tab != "briefs":
		if not s.pitch.is_empty():
			_list.add_child(_pitch_status_card(s))
			shown += 1
		for inv: Dictionary in s.pitch_invites:
			_list.add_child(_pitch_invite_card(inv, s))
			shown += 1
		for offer: Dictionary in s.supplier_offers:
			_list.add_child(_supplier_offer_card(offer, s))
			shown += 1
	if _tab != "offers":
		if not s.inbox.is_empty() and not s.is_idle():
			_list.add_child(UiUtil.wrapped(tr("UI_BUSY_HINT"), 13, UiUtil.WOOD, 400.0))
		for brief: Dictionary in s.inbox:
			_list.add_child(_brief_card(brief, s))
			shown += 1
	if shown == 0:
		_list.add_child(Cards.empty_state("inbox", tr("UI_INBOX_EMPTY")))


## Kartın altındaki düğme sırası: solda (varsa) açıklama, sağda ret ve yeşil kabul.
func _buttons(note: String, decline_text: String, on_decline: Callable, accept: Button) -> HBoxContainer:
	var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	var text: Label = UiUtil.wrapped(note, 13, CozyTheme.TEXT, 200.0)
	row.add_child(text)
	row.add_child(UiUtil.button(decline_text, on_decline))
	accept.theme_type_variation = "PrimaryButton"
	row.add_child(accept)
	return row


## Matbaadan gelen teklif (GDD 10.3): hacim indirimi ya da yıllık taahhüt.
func _supplier_offer_card(offer: Dictionary, s: SimState) -> PanelContainer:
	var card: PanelContainer = UiUtil.card()
	var col: VBoxContainer = UiUtil.vbox(CozyTheme.SPACE_S)
	card.add_child(col)
	var supplier: String = tr(DataDB.data.suppliers[offer["supplier"]]["name_key"])
	col.add_child(Cards.header(Cards.art("supplier_art", str(offer["supplier"]), 44.0, "receipt"), supplier, "",
		[Cards.chip(tr("UI_SUPPLIER_OFFER"), CozyTheme.TERRA_SOFT, CozyTheme.TERRA),
		Cards.chip(tr("UI_EXPIRES") % (int(offer["expires_week"]) - s.clock.week_index), CozyTheme.CREAM, CozyTheme.TEXT)]))
	col.add_child(HSeparator.new())
	var volume: bool = offer["type"] == "volume"
	col.add_child(Cards.facts([
		Cards.fact("receipt", tr("UI_FACT_DISCOUNT"), UiUtil.percent(roundf(float(offer["discount"]) * 100.0))),
		Cards.fact("coins", tr("UI_FACT_QUANTITY"), "%d+" % int(offer["min_quantity"] if volume else offer["commit_quantity"])),
		Cards.fact("calendar", tr("UI_FACT_VALID"),
			tr("UI_WEEKS") % int(offer["duration_weeks"]) if volume else tr("UI_FACT_YEAR_END"))]))
	var accept: Button = UiUtil.button(tr("UI_ACCEPT"), func() -> void:
		GameState.execute(RespondSupplierOfferCommand.new(offer["id"], true))
		EventBus.notification.emit("NOTE_DEAL_SIGNED", [supplier], "good"))
	col.add_child(_buttons(UiUtil.supplier_offer_text(offer), tr("UI_DECLINE"), func() -> void:
		GameState.execute(RespondSupplierOfferCommand.new(offer["id"], false)), accept))
	return card


func _brief_card(brief: Dictionary, s: SimState) -> PanelContainer:
	var data: GameData = DataDB.data
	var client: Dictionary = brief["prospect"] if not (brief["prospect"] as Dictionary).is_empty() \
		else s.clients.get(brief["client_id"], {})
	var card: PanelContainer = UiUtil.card()
	var col: VBoxContainer = UiUtil.vbox(CozyTheme.SPACE_S)
	card.add_child(col)
	var tags: Array = []
	if not (brief["prospect"] as Dictionary).is_empty():
		tags.append(Cards.chip(tr("UI_NEW_CLIENT"), CozyTheme.TERRA_SOFT, CozyTheme.TERRA))
	tags.append(Cards.chip(tr("UI_EXPIRES") % (int(brief["expires_week"]) - s.clock.week_index), CozyTheme.CREAM, CozyTheme.TEXT))
	col.add_child(Cards.header(Cards.art("brand_art", str(client.get("name", "")), 44.0, "building"), str(client.get("name", "?")),
		"%s · %s · %s" % [UiUtil.name_of(data.sectors, brief["sector"]), tr("SCALE_%d" % int(client.get("scale", 0))),
		tr("SIZE_" + str(brief["size"]).to_upper())], tags))
	var objective: String = tr("UI_OBJECTIVE_FREE") if str(brief["objective"]).is_empty() \
		else UiUtil.name_of(data.objectives, brief["objective"])
	col.add_child(HSeparator.new())
	col.add_child(Cards.facts([
		Cards.fact("coins", tr("UI_FACT_FEE"), UiUtil.money(brief["fee"])),
		Cards.fact("speakerphone", tr("UI_FACT_MEDIA"), UiUtil.money(brief["media_budget"])),
		Cards.fact("calendar", tr("UI_FACT_DURATION"), tr("UI_WEEKS") % int(brief["deadline_weeks"]))]))
	var accept: Button = UiUtil.button(tr("UI_ACCEPT"), func() -> void:
		_main.call("open_modal", WizardDialog.new(brief, _main)))
	accept.disabled = not s.is_idle()
	col.add_child(_buttons(tr("UI_BRIEF_OBJECTIVE") % objective, tr("UI_DECLINE"), func() -> void:
		GameState.execute(DeclineBriefCommand.new(brief["id"])), accept))
	return card


## İhale daveti (GDD 14.2): büyük marka, davetli rakipler, hazırlık süresi, varsa katılım ücreti.
func _pitch_invite_card(inv: Dictionary, s: SimState) -> PanelContainer:
	var data: GameData = DataDB.data
	var client: Dictionary = inv["client"]
	var card: PanelContainer = UiUtil.card()
	var col: VBoxContainer = UiUtil.vbox(4)
	card.add_child(col)
	col.add_child(Cards.header(Cards.tile("trophy", 44.0, CozyTheme.ACCENT_SOFT), str(client["name"]),
		"%s · %s" % [UiUtil.name_of(data.sectors, client["sector"]), tr("SCALE_%d" % int(client["scale"]))],
		[Cards.accent_chip(tr("UI_PITCH_INVITE")),
		Cards.chip(tr("UI_EXPIRES") % (int(inv["expires_week"]) - s.clock.week_index), CozyTheme.CREAM, CozyTheme.MUTED)]))
	col.add_child(UiUtil.wrapped(PitchInviteDialog.summary(inv), 15, UiUtil.TEXT, 400.0))
	var buttons: HBoxContainer = UiUtil.hbox()
	buttons.add_child(UiUtil.spacer())
	buttons.add_child(UiUtil.button(tr("UI_DECLINE"), func() -> void: GameState.execute(DeclinePitchCommand.new(inv["id"]))))
	buttons.add_child(UiUtil.button(tr("UI_PITCH_JOIN"), func() -> void: _main.call("open_modal", PitchInviteDialog.new(inv))))
	col.add_child(buttons)
	return card


## Yürüyen pitch: hazırlıkta kalan süre ve biriken puan ya da sunuma geçiş düğmesi.
func _pitch_status_card(s: SimState) -> PanelContainer:
	var p: Dictionary = s.pitch
	var card: PanelContainer = UiUtil.card()
	var row: HBoxContainer = UiUtil.hbox()
	card.add_child(row)
	if p["phase"] == "prep":
		row.add_child(UiUtil.label(tr("UI_PITCH_PREP") % [p["client"]["name"], maxi(0, int(p["end_week"]) - s.clock.week_index),
			float(p["s"]), float(p["k"])], 15, UiUtil.WOOD))
	else:
		row.add_child(UiUtil.label(tr("UI_PITCH_READY") % p["client"]["name"], 15, UiUtil.SAGE_DARK))
		row.add_child(UiUtil.spacer())
		row.add_child(UiUtil.button(tr("UI_PITCH_PRESENT"), func() -> void: _main.call("open_modal", PitchDialog.new())))
	return card
