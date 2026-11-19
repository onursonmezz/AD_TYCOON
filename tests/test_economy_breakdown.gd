extends GutTest
## S8: aylık gider dökümü simülasyonun ödediğiyle aynı; finans ekranı yalnız taban gideri göstermez.

var data: GameData


func before_all() -> void:
	data = GameData.load_from()


func test_month_end_pays_exactly_the_breakdown_total() -> void:
	var sim: Simulation = Simulation.new(data, 21)
	sim.state.clock.week_index = 3
	var found: Array[Dictionary] = sim.staff.search(sim.state, sim.economy, "copywriter", "job_ad", "tr")
	var cand: Dictionary = found[0]
	cand["hired_week"] = sim.state.clock.week_index
	sim.state.staff[cand["id"]] = cand
	sim.state.receivables = []
	sim.state.payables = []
	var b: Dictionary = MonthlyCosts.breakdown(sim)
	assert_gt(float(b["payroll"]), 0.0, "maaş dökümde")
	assert_gt(MonthlyCosts.total(sim), float(b["base"]), "toplam taban giderden büyük")
	var before: float = sim.state.cash
	var expected: float = MonthlyCosts.total(sim) - float(b["loan"])
	sim.economy.monthly(sim.state, MonthlyCosts.extra(sim))
	assert_almost_eq(before - sim.state.cash, expected, 0.01, "ay sonu ödenen = döküm toplamı")
