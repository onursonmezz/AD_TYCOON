extends GutTest
## K-151: taşınma ekranında kalan nakdin kaç ay yettiği; botun işsiz kalmaktansa güvenli iş alması.

var data: GameData


func before_all() -> void:
	data = GameData.load_from()


func test_after_move_uses_new_rent_and_remaining_cash() -> void:
	var sim: Simulation = Simulation.new(data, 601)
	var next: Dictionary = sim.offices.next_office(sim.state)
	var cost: float = sim.offices.move_cost(sim.state, next)
	sim.state.cash = cost + 100000.0
	var r: Dictionary = MonthlyCosts.after_move(sim)
	var new_rent: float = float(next["rent_1990"]) * Economy.inflation(data, sim.state.clock.year())
	var monthly: float = MonthlyCosts.total(sim) - sim.offices.monthly_rent(sim.state) + new_rent
	assert_almost_eq(float(r["cash_left"]), 100000.0, 0.01)
	assert_almost_eq(float(r["monthly"]), monthly, 0.01, "yeni kirayla aylık gider")
	assert_almost_eq(float(r["months"]), 100000.0 / monthly, 0.001)
	assert_eq(bool(r["warn"]), float(r["months"]) < data.balf("cashflow.move_runway_warn_months"))


func test_after_move_warns_when_little_cash_is_left() -> void:
	var sim: Simulation = Simulation.new(data, 602)
	var cost: float = sim.offices.move_cost(sim.state, sim.offices.next_office(sim.state))
	sim.state.cash = cost
	assert_true(bool(MonthlyCosts.after_move(sim)["warn"]), "taşınınca kasa boş kalıyor")
	sim.state.cash = cost + 1000.0 * MonthlyCosts.total(sim) * 100.0
	assert_false(bool(MonthlyCosts.after_move(sim)["warn"]), "bol nakit")


func test_after_move_empty_at_top_office() -> void:
	var sim: Simulation = Simulation.new(data, 603)
	sim.state.office_level = data.max_office_level()
	assert_true(MonthlyCosts.after_move(sim).is_empty())


func test_bot_takes_safe_job_when_idling_would_breach_reserve() -> void:
	var sim: Simulation = Simulation.new(data, 604)
	var client: Dictionary = sim.state.clients.values()[0]
	var brief: Dictionary = sim.briefs.make_brief(sim.state, client, {})
	sim.state.cash = 50.0 * MonthlyCosts.total(sim)
	var huge: float = sim.state.cash * 10.0
	var bot: SmartBot = SmartBot.new()
	assert_false(bot._fits(sim, brief, huge), "eski kural: yedek tutmuyor")
	assert_true(bot._affordable(sim, brief, huge), "işsiz de yedeğin altı; kasayı eksiye düşürmeyen iş alınır")
	sim.state.cash = -1.0
	assert_false(bot._affordable(sim, brief, huge), "kasa zaten eksideyse alınmaz")
