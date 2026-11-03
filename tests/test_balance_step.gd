extends GutTest
## Denge adımı (K-047..K-050): hata payı, eriyen rekor, enflasyonsuz ofis bedeli, ofise göre müşteri ölçeği, medya avansı.

var data: GameData


func before_all() -> void:
	data = GameData.load_from()


func _choices() -> Dictionary:
	return {"objective": "awareness", "audience": "adult", "tone": "emotional",
		"mix": [{"channel": "newspaper", "share": 1.0}]}


func test_error_penalty_is_capped() -> void:
	var scoring: Scoring = Scoring.new(data)
	assert_almost_eq(scoring.error_penalty(0), 0.0, 0.0001)
	assert_almost_eq(scoring.error_penalty(2), 2.0 * data.balf("scoring.error_penalty_per_error"), 0.0001)
	assert_almost_eq(scoring.error_penalty(1000), data.balf("scoring.error_penalty_max"), 0.0001)


func test_best_record_decays_each_year() -> void:
	var sim: Simulation = Simulation.new(data, 3)
	sim.state.best_raw["small"] = 400.0
	sim.call("_end_year")
	assert_almost_eq(float(sim.state.best_raw["small"]), 400.0 * (1.0 - data.balf("score.best_yearly_decay")), 0.001)


func test_bigger_office_attracts_bigger_clients() -> void:
	var avg: Array[float] = []
	for level: int in [1, 4]:
		var sim: Simulation = Simulation.new(data, 9)
		sim.state.office_level = level
		var total: float = 0.0
		for i: int in 300:
			total += float(sim.clients.create_prospect(sim.state)["scale"])
		avg.append(total / 300.0)
	assert_gt(avg[1], avg[0] + 1.0, "plaza katındaki ajansa gelen markalar ortalamada en az bir ölçek büyük")


func test_large_clients_pay_media_in_advance() -> void:
	var sim: Simulation = Simulation.new(data, 21)
	while sim.state.inbox.is_empty():
		sim.step_week()
	var brief: Dictionary = sim.state.inbox[0]
	var client: Dictionary = sim.state.clients[brief["client_id"]] if (brief["prospect"] as Dictionary).is_empty() \
		else brief["prospect"]
	client["scale"] = 2
	var media: float = float(brief["media_budget"])
	var cash0: float = sim.state.cash
	assert_true(sim.start_campaign(brief["id"], _choices())["ok"])
	assert_almost_eq(sim.state.cash - cash0, media, 0.01, "ulusal marka medyanın tamamını başta öder")
	var setup: Dictionary = sim.state.active_campaign["setup"]
	assert_almost_eq(float(setup["media_advance"]), media, 0.01)
	for i: int in 400:
		if sim.state.active_campaign.is_empty():
			break
		if sim.state.waiting_for_input:
			sim.set_phase_sliders([0.5, 0.3, 0.2])
		sim.step_day()
	var invoiced: float = 0.0
	for r: Dictionary in sim.state.receivables:
		if r["client_id"] == client["id"]:
			invoiced += float(r["amount"])
	assert_lt(invoiced, media, "faturada medya yok, yalnızca ücret ve komisyon")


func test_neighbourhood_clients_pay_no_advance() -> void:
	var economy: Economy = Economy.new(data)
	assert_eq(economy.media_advance({"scale": 0}, 50000.0), 0.0)
	assert_almost_eq(economy.media_advance({"scale": 1}, 50000.0), 25000.0, 0.01)
