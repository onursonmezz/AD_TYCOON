extends GutTest
## Üretim + rötuş ve teslim düğmesi (S3C).

var data: GameData


func before_all() -> void:
	data = GameData.load_from()


func _camp(sim: Simulation, polish: bool) -> Dictionary:
	var founder: String = sim.state.founder()["id"]
	var third: float = 1.0 / 3.0
	return sim.production.create({"team": [founder], "sliders": [[third, third, third], [third, third, third],
		[third, third, third]], "deadline_weeks": 8, "size": "small", "mix": [{"channel": "newspaper", "share": 1.0}],
		"sector": "fast_food", "objective": "awareness", "audience": "", "tone": "", "polish": polish}, "cp_p", 0)


func test_production_takes_part_of_the_time() -> void:
	var sim: Simulation = Simulation.new(data, 2)
	var camp: Dictionary = _camp(sim, true)
	var total: int = int(camp["days_total"])
	var expected: int = int(ceilf(total * (1.0 - data.balf("production.polish_share"))))
	assert_eq(CampaignProduction.production_days(camp), expected)
	assert_eq(CampaignProduction.production_days(_camp(sim, false)), total, "eski kampanya: tüm süre üretim")


func test_same_total_points_in_shorter_production() -> void:
	var a: Simulation = Simulation.new(data, 6)
	var b: Simulation = Simulation.new(data, 6)
	var short: Dictionary = _camp(a, true)
	var full: Dictionary = _camp(b, false)
	while not CampaignProduction.production_done(short):
		a.production.produce_day(short, a.state)
	while not CampaignProduction.production_done(full):
		b.production.produce_day(full, b.state)
	var sum_a: float = 0.0
	var sum_b: float = 0.0
	for id: String in data.focus_ids:
		sum_a += float(short["points"][id])
		sum_b += float(full["points"][id])
	assert_almost_eq(sum_a, sum_b, sum_b * 0.12, "sıkıştırılmış üretim aynı toplam işi çıkarır")


func test_polish_fixes_errors_without_points() -> void:
	var sim: Simulation = Simulation.new(data, 9)
	var camp: Dictionary = _camp(sim, true)
	camp["day"] = CampaignProduction.production_days(camp)
	camp["errors"] = 30
	var before: Dictionary = (camp["points"] as Dictionary).duplicate()
	for i: int in 10:
		sim.production.produce_day(camp, sim.state)
	assert_lt(int(camp["errors"]), 30, "rötuşta hata azalır")
	assert_eq(camp["points"], before, "rötuşta yeni puan yok")


func test_deliver_now_needs_finished_production() -> void:
	var sim: Simulation = Simulation.new(data, 11)
	sim.state.active_campaign = _camp(sim, true)
	assert_eq(sim.deliver_now(), "ERR_NOT_READY")
	sim.state.active_campaign["day"] = CampaignProduction.production_days(sim.state.active_campaign)
	sim.state.active_campaign["setup"]["client_id"] = ""
	sim.state.active_campaign["setup"]["fee"] = 10000.0
	sim.state.active_campaign["setup"]["media_budget"] = 10000.0
	sim.state.active_campaign["setup"]["client_name"] = "Test"
	sim.state.active_campaign["setup"]["client_scale"] = 0
	sim.state.active_campaign["setup"]["kpi_type"] = "reach"
	sim.state.active_campaign["setup"]["kpi_target"] = 1000.0
	assert_eq(sim.deliver_now(), "", "rötuşta teslim edilebilir")
	assert_true(sim.state.active_campaign.is_empty(), "kampanya teslim edildi")
