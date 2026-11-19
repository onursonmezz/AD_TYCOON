extends GutTest
## S11 (Orgo): planlı kampanyada fazlar sırayla planlanır. Başta yalnız 1. faz; 2. ve 3. faz başladığında oyun bekler,
## o fazın planı onaylanınca devam eder.

var data: GameData


func before_all() -> void:
	data = GameData.load_from()


func test_phases_are_planned_one_after_another() -> void:
	var sim: Simulation = Simulation.new(data, 41)
	sim.pause_on_phase = true  # oyunda olduğu gibi faz başında bekle
	var client: Dictionary = sim.state.clients.values()[0]
	var b: Dictionary = sim.briefs.make_brief(sim.state, client, {})
	sim.state.inbox.append(b)
	var r: Dictionary = sim.start_campaign(str(b["id"]), {"objective": "awareness", "audience": "adult", "tone": "emotional",
		"mix": [{"channel": "newspaper", "share": 1.0}], "team": [sim.state.founder()["id"]], "planned": true})
	assert_true(bool(r["ok"]), str(r.get("error", "")))
	var camp: Dictionary = sim.state.campaigns[0]
	assert_eq(camp["confirmed_phases"], [0], "başta yalnız 1. faz planlı")
	var planned: Array[int] = []
	for i: int in 400:
		if sim.state.campaigns.is_empty():
			break
		if sim.state.waiting_for_input:
			var ph: int = sim.production.current_phase(camp)
			assert_true(ph > 0, "1. faz başta planlandı; bekleme sonraki fazlarda")
			assert_eq(sim.plan_task_phase(str(camp["id"]), [0.5, 0.25, 0.25], []), "", "faz %d planı" % ph)
			planned.append(ph)
			assert_almost_eq(float(camp["setup"]["sliders"][ph][0]), 0.5, 0.0001, "ağırlık yazıldı")
		sim.step_day()
	assert_eq(planned, [1, 2] as Array[int], "2. ve 3. faz sırayla planlandı")


func test_wrong_campaign_or_phase_is_refused() -> void:
	var sim: Simulation = Simulation.new(data, 42)
	assert_eq(sim.plan_task_phase("yok", [0.4, 0.3, 0.3], []), "ERR_PLAN")
