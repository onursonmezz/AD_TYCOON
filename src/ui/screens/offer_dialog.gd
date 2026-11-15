class_name OfferDialog
extends Control
## Rakip transfer teklifi (GDD 11.2): zam yapıp tut ya da bırak gitsin. Cevapsız kalırsa çalışan gider.
## UI-3 dili: portreli çalışan kartı (rakibin logosu sağda), maaş bilgi şeridi; alt satırda iki karar düğmesi.

var _offer: Dictionary


func _init(offer: Dictionary) -> void:
	_offer = offer


func _ready() -> void:
	var sim: Simulation = GameState.sim
	var emp: Dictionary = sim.state.staff.get(_offer["employee_id"], {})
	if emp.is_empty():
		queue_free.call_deferred()
		return
	var data: GameData = DataDB.data
	var keep_salary: float = roundf(Employee.market_value(data, emp, sim.state.clock.year()) \
		* (1.0 + data.balf("staff_rules.offer_raise_over_market")))
	var col: VBoxContainer = UiUtil.modal_frame(self, UiUtil.dialog_size("offer"))
	col.add_child(UiUtil.heading(tr("UI_OFFER_TITLE"), "users"))
	var rival: String = str(_offer.get("rival", ""))
	var trailing: Array = []
	if data.rivals.has(rival):
		trailing.append(Cards.art("rival_art", rival, 44.0, "building", Color.TRANSPARENT))
	col.add_child(Cards.header(Cards.avatar(emp, 52.0), GameState.employee_name(emp), tr(Employee.title_key(data, emp)), trailing))
	var text: String = tr("UI_OFFER_TEXT") % [GameState.employee_name(emp), tr(Employee.title_key(data, emp)),
		UiUtil.money(_offer["offer_salary"]), UiUtil.money(emp["salary"])]
	if data.rivals.has(rival):
		text = tr("UI_OFFER_TEXT_RIVAL") % [GameState.employee_name(emp), tr(Employee.title_key(data, emp)),
			UiUtil.name_of(data.rivals, rival), UiUtil.money(_offer["offer_salary"]), UiUtil.money(emp["salary"])]
	col.add_child(UiUtil.wrapped(text, 14, CozyTheme.TEXT))
	col.add_child(Cards.facts([
		Cards.fact("coins", tr("UI_OFFER_NOW"), UiUtil.money(emp["salary"])),
		Cards.fact("arrow-up", tr("UI_OFFER_THEIRS"), UiUtil.money(_offer["offer_salary"])),
		Cards.fact("check", tr("UI_OFFER_KEEP"), UiUtil.money(keep_salary))]))
	var frame: VBoxContainer = UiUtil.modal_outer(col)
	frame.add_child(HSeparator.new())
	var foot: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	foot.add_child(UiUtil.spacer())
	var release: Button = UiUtil.button(tr("UI_OFFER_RELEASE"), func() -> void: _resolve("release"))
	release.theme_type_variation = "DeclineButton"
	foot.add_child(release)
	var keep: Button = UiUtil.button(tr("UI_OFFER_MATCH") % UiUtil.money(keep_salary), func() -> void: _resolve("match"))
	keep.theme_type_variation = "PrimaryButton"
	foot.add_child(keep)
	frame.add_child(foot)


func _resolve(choice: String) -> void:
	GameState.execute(ResolveOfferCommand.new(_offer["id"], choice))
	queue_free()
