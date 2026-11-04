extends GutTest
## M10: banka kredisi (GDD 13.5): sınır, eşit taksit, faiz gider, erken kapatma, kırmızıda uyarı, kayıt.

var data: GameData


func before_all() -> void:
	data = GameData.load_from()


func _sim() -> Simulation:
	var sim: Simulation = Simulation.new(data, 21)
	sim.state.reputation = 50.0
	return sim


func test_limit_follows_office_and_reputation() -> void:
	var sim: Simulation = _sim()
	var base: float = float(data.bal("loans.max_1990_by_office")[0])
	assert_almost_eq(sim.loans.max_amount(sim.state), base * 1.0, 0.01, "itibar 50: ×(0.5 + 0.5)")
	sim.state.reputation = 0.0
	assert_almost_eq(sim.loans.max_amount(sim.state), base * 0.5, 0.01)
	sim.state.office_level = 3
	assert_gt(sim.loans.max_amount(sim.state), base, "büyük ofis daha çok kredi")


func test_take_pay_monthly_and_finish() -> void:
	var sim: Simulation = _sim()
	var cash0: float = sim.state.cash
	assert_eq(LoanActionCommand.new("take", 10000.0, 7).execute(sim), "ERR_LOAN_TERM")
	assert_eq(LoanActionCommand.new("take", 1.0e9, 12).execute(sim), "ERR_LOAN_AMOUNT")
	assert_eq(LoanActionCommand.new("take", 12000.0, 6).execute(sim), "")
	assert_almost_eq(sim.state.cash - cash0, 12000.0, 0.01)
	assert_eq(LoanActionCommand.new("take", 1000.0, 6).execute(sim), "ERR_LOAN_EXISTS")
	var monthly: float = float(sim.state.loan["monthly"])
	var r: float = data.balf("loans.annual_interest") / 12.0
	assert_almost_eq(monthly, 12000.0 * r / (1.0 - pow(1.0 + r, -6)), 0.01, "eşit taksit")
	var paid_interest: float = 0.0
	for i: int in 6:
		paid_interest += sim.loans.monthly(sim.state)
	assert_true(sim.state.loan.is_empty(), "6 ayda biter")
	assert_almost_eq(paid_interest, monthly * 6.0 - 12000.0, 1.0, "faiz = toplam taksit − anapara")


func test_early_repay_and_save() -> void:
	var sim: Simulation = _sim()
	sim.state.cash = 100000.0
	LoanActionCommand.new("take", 10000.0, 12).execute(sim)
	var saved: Dictionary = sim.state.to_dict()
	var copy: Simulation = Simulation.new(data, 1)
	copy.load_state(JSON.parse_string(JSON.stringify(saved)))
	assert_almost_eq(float(copy.state.loan["balance"]), 10000.0, 0.01, "kredi kayıtta")
	var cost: float = sim.loans.repay_cost(sim.state)
	assert_almost_eq(cost, 10000.0 * (1.0 + data.balf("loans.early_repay_fee")), 0.01)
	var cash0: float = sim.state.cash
	assert_eq(LoanActionCommand.new("repay").execute(sim), "")
	assert_almost_eq(cash0 - sim.state.cash, cost, 0.01)
	assert_eq(LoanActionCommand.new("repay").execute(sim), "ERR_LOAN_NONE")


func test_red_cash_suggests_a_loan() -> void:
	var sim: Simulation = _sim()
	var notes: Array = []
	sim.staff_note.connect(func(key: String, _a: Array, _k: String) -> void: notes.append(key))
	sim.state.cash = -5000.0
	sim.step_week()
	assert_has(notes, "NOTE_RED_LOAN")
	notes.clear()
	sim.state.cash = -5000.0
	LoanActionCommand.new("take", 1000.0, 6).execute(sim)
	sim.state.cash = -5000.0
	sim.state.red_weeks = 0
	sim.step_week()
	assert_does_not_have(notes, "NOTE_RED_LOAN", "kredi varken önerilmez")
