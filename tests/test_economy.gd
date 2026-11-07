extends GutTest
## UI-2d: aylık finans kaydı (SimState.book, finance_months). Yalnızca kayıt; yıl toplamları aynı kalır.

var data: GameData


func before_all() -> void:
	data = GameData.load_from()


func test_book_adds_to_year_and_month() -> void:
	var sim: Simulation = Simulation.new(data, 5)
	var s: SimState = sim.state
	var in0: float = s.year_income
	var out0: float = s.year_expense
	s.book(1000.0, 0.0)
	sim.economy.pay(s, 250.0)
	assert_almost_eq(s.year_income, in0 + 1000.0, 0.01)
	assert_almost_eq(s.year_expense, out0 + 250.0, 0.01, "pay() gideri kaydeder")
	var key: int = s.clock.year() * 12 + s.clock.month() - 1
	assert_eq(int(s.finance_months[-1]["m"]), key)
	assert_almost_eq(float(s.finance_months[-1]["in"]), 1000.0, 0.01)
	assert_almost_eq(float(s.finance_months[-1]["out"]), 250.0, 0.01)


func test_months_survive_save_and_are_trimmed_yearly() -> void:
	var sim: Simulation = Simulation.new(data, 6)
	var s: SimState = sim.state
	var keep: int = data.bali("cashflow.history_months")
	for i: int in keep + 5:
		s.finance_months.append({"m": i, "in": float(i), "out": 0.0})
	var back: SimState = SimState.from_dict(data, s.to_dict())
	assert_eq(back.finance_months.size(), keep + 5, "kayıtta saklanır")
	sim.economy.yearly(s)
	assert_eq(s.finance_months.size(), keep, "yıl sonunda son %d ay kalır" % keep)
	assert_eq(int(s.finance_months[0]["m"]), 5, "en eskiler atılır")
