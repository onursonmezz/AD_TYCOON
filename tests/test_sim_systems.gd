extends GutTest
## Saat, ekonomi, KPI, brief ve simülasyon akışı testleri (GDD 5, 6, 7.10–7.11, 13).

var data: GameData


func before_all() -> void:
	data = GameData.load_from()


func _good_choices() -> Dictionary:
	return {"objective": "awareness", "audience": "adult", "tone": "emotional",
		"mix": [{"channel": "newspaper", "share": 1.0}], "sliders": [[0.4, 0.3, 0.3], [0.4, 0.3, 0.3], [0.4, 0.3, 0.3]]}


func test_clock_periods() -> void:
	var clock: SimClock = SimClock.new(data)
	var ended: Dictionary = {}
	for i: int in 7:
		ended = clock.advance_day()
	assert_true(ended["week"])
	assert_false(ended["month"])
	for i: int in 7 * 3:
		ended = clock.advance_day()
	assert_true(ended["month"])
	assert_eq(clock.month(), 2)
	for i: int in 7 * 44:
		ended = clock.advance_day()
	assert_true(ended["year"])
	assert_eq(clock.year(), 1991)
	assert_eq(clock.game_year(), 2)


func test_inflation_simple_mode() -> void:
	assert_almost_eq(Economy.inflation(data, 1990), 1.0, 0.0001)
	assert_almost_eq(Economy.inflation(data, 1991), 1.08, 0.0001)


func test_invoice_is_collected_on_due_week() -> void:
	var state: SimState = SimState.new(data, 1)
	var economy: Economy = Economy.new(data)
	var client: Dictionary = {"id": "cl_x", "personality": {"pay": 100}}
	var cash0: float = state.cash
	economy.invoice(state, client, 5000.0, 1000.0)
	economy.weekly(state)
	assert_almost_eq(state.cash, cash0, 0.01, "vade gelmeden tahsil edilmez")
	state.clock.week_index = 4
	economy.weekly(state)
	assert_almost_eq(state.cash, cash0 + 5000.0, 0.01)
	assert_almost_eq(state.year_income, 1000.0, 0.01, "sadece ajans geliri vergiye girer")


func test_bankruptcy_after_red_weeks() -> void:
	var state: SimState = SimState.new(data, 1)
	var economy: Economy = Economy.new(data)
	state.cash = -1.0
	for i: int in 3:
		economy.weekly(state)
	assert_false(state.bankrupt)
	economy.weekly(state)
	assert_true(state.bankrupt, "4 hafta kırmızı → iflas")


func test_corporate_tax_on_profit() -> void:
	var state: SimState = SimState.new(data, 1)
	var economy: Economy = Economy.new(data)
	state.year_income = 100000.0
	state.year_expense = 20000.0
	var cash0: float = state.cash
	assert_almost_eq(economy.yearly(state), 20000.0, 0.01)
	assert_almost_eq(state.cash, cash0 - 20000.0, 0.01)


func test_interest_curve_piecewise_linear() -> void:
	var kpi: Kpi = Kpi.new(data, Scoring.new(data))
	assert_almost_eq(kpi.interest("newspaper", 1995), 0.95, 0.0001)
	assert_almost_eq(kpi.interest("newspaper", 2035), 0.08, 0.0001)
	assert_almost_eq(kpi.interest("radio", 2000), 1.0, 0.0001, "eğrisi olmayan kanal")


func test_kpi_reach_grows_with_budget_and_saturates() -> void:
	var kpi: Kpi = Kpi.new(data, Scoring.new(data))
	var sim_rng: SimRng = SimRng.new(3)
	var client: Dictionary = {"scale": 2}
	var setup: Dictionary = {"sector": "fast_food", "objective": "sales", "audience": "young", "tone": "emotional",
		"mix": [{"channel": "radio", "share": 1.0}], "fee": 10000.0, "media_budget": 50000.0}
	var small: Dictionary = kpi.compute(setup, client, 6.0, 1990, sim_rng)
	setup["media_budget"] = 500000.0
	var big: Dictionary = kpi.compute(setup, client, 6.0, 1990, sim_rng)
	assert_gt(float(big["reach"]), float(small["reach"]))
	var pool: float = kpi.population(1990) * 0.30 * 0.6
	assert_lte(float(big["reach"]), pool)


func test_performance_bonus_capped() -> void:
	var kpi: Kpi = Kpi.new(data, Scoring.new(data))
	var setup: Dictionary = {"fee": 10000.0, "media_budget": 100000.0}
	assert_almost_eq(float(kpi.agency_income(setup, 0.9)["bonus"]), 0.0, 0.01)
	assert_almost_eq(float(kpi.agency_income(setup, 1.2)["bonus"]), 2000.0, 0.01)
	assert_almost_eq(float(kpi.agency_income(setup, 3.0)["bonus"]), 5000.0, 0.01, "en fazla fee × %50")
	assert_almost_eq(float(kpi.agency_income(setup, 1.0)["commission"]), 15000.0, 0.01)


func test_season_multiplier() -> void:
	var gen: BriefGenerator = BriefGenerator.new(data, ClientSystem.new(data))
	assert_almost_eq(gen.season_multiplier("ecommerce", 2012, 11), 1.5, 0.0001)
	assert_almost_eq(gen.season_multiplier("ecommerce", 2005, 11), 1.0, 0.0001, "Efsane Cuma 2010 sonrası")
	assert_almost_eq(gen.season_multiplier("fast_food", 1990, 4), 1.5, 0.0001, "1990 Ramazan Bayramı Nisan")
	assert_almost_eq(gen.season_multiplier("automotive", 1990, 4), 1.0, 0.0001)


func test_same_seed_same_game() -> void:
	var a: Simulation = Simulation.new(data, 99)
	var b: Simulation = Simulation.new(data, 99)
	for i: int in 60:
		a.step_week()
		b.step_week()
	assert_eq(a.state.inbox.size(), b.state.inbox.size())
	assert_almost_eq(a.state.cash, b.state.cash, 0.001)


func test_start_campaign_validation() -> void:
	var sim: Simulation = Simulation.new(data, 5)
	while sim.state.inbox.is_empty():
		sim.step_week()
	var brief_id: String = sim.state.inbox[0]["id"]
	var bad: Dictionary = _good_choices()
	bad["mix"] = [{"channel": "tiktak", "share": 1.0}]
	assert_eq(sim.start_campaign(brief_id, bad)["error"], "ERR_CHANNEL", "TikTak 1990'da yok")
	bad = _good_choices()
	bad["mix"] = [{"channel": "newspaper", "share": 0.5}]
	assert_eq(sim.start_campaign(brief_id, bad)["error"], "ERR_SHARE")
	assert_true(sim.start_campaign(brief_id, _good_choices())["ok"])
	assert_false(sim.state.is_idle())


func test_campaign_lifecycle_creates_history_and_invoice() -> void:
	var sim: Simulation = Simulation.new(data, 11)
	while sim.state.inbox.is_empty():
		sim.step_week()
	var cmd: StartCampaignCommand = StartCampaignCommand.new(sim.state.inbox[0]["id"], _good_choices())
	assert_true(cmd.execute(sim)["ok"])
	for i: int in 30:
		sim.step_week()
	assert_eq(sim.state.history.size(), 1)
	var h: Dictionary = sim.state.history[0]
	assert_between(float(h["score"]), 1.0, 10.0)
	assert_true(h.has("kpi_ratio"), "yayın bitince KPI yazılır")
