class_name OfferDialog
extends Control
## Rakip transfer teklifi (GDD 11.2): zam yapıp tut ya da bırak gitsin. Cevapsız kalırsa çalışan gider.

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
	var keep_salary: float = Employee.market_value(data, emp, sim.state.clock.year()) \
		* (1.0 + data.balf("staff_rules.offer_raise_over_market"))
	var col: VBoxContainer = UiUtil.modal_frame(self, Vector2(540.0, 280.0))
	col.add_child(UiUtil.label(tr("UI_OFFER_TITLE"), 24, UiUtil.TERRACOTTA))
	var rival: String = str(_offer.get("rival", ""))
	var text: String = tr("UI_OFFER_TEXT") % [GameState.employee_name(emp), tr(Employee.title_key(data, emp)),
		UiUtil.money(_offer["offer_salary"]), UiUtil.money(emp["salary"])]
	if data.rivals.has(rival):
		text = tr("UI_OFFER_TEXT_RIVAL") % [GameState.employee_name(emp), tr(Employee.title_key(data, emp)),
			UiUtil.name_of(data.rivals, rival), UiUtil.money(_offer["offer_salary"]), UiUtil.money(emp["salary"])]
	col.add_child(UiUtil.wrapped(text, 16, UiUtil.TEXT, 480.0))
	var buttons: HBoxContainer = UiUtil.hbox()
	buttons.add_child(UiUtil.spacer())
	buttons.add_child(UiUtil.button(tr("UI_OFFER_RELEASE"), func() -> void: _resolve("release")))
	buttons.add_child(UiUtil.button(tr("UI_OFFER_MATCH") % UiUtil.money(roundf(keep_salary)), func() -> void: _resolve("match")))
	col.add_child(buttons)


func _resolve(choice: String) -> void:
	GameState.execute(ResolveOfferCommand.new(_offer["id"], choice))
	queue_free()
