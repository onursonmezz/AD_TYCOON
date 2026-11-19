extends GutTest
## Aynı anda birden çok kampanya (S3D): bir kişi tek kampanyada; boşta kimse yoksa yeni kampanya yok; hepsi ilerler.

var data: GameData


func before_all() -> void:
	data = GameData.load_from()


func _choices(team: Array) -> Dictionary:
	return {"objective": "awareness", "audience": "adult", "tone": "emotional",
		"mix": [{"channel": "newspaper", "share": 1.0}], "team": team, "planned": true}


func _add_employee(sim: Simulation) -> String:
	var found: Array[Dictionary] = sim.staff.search(sim.state, sim.economy, "copywriter", "job_ad", "tr")
	var emp: Dictionary = found[0]
	emp["hired_week"] = sim.state.clock.week_index - 30
	sim.state.staff[emp["id"]] = emp
	return str(emp["id"])


func _brief(sim: Simulation) -> String:
	var client: Dictionary = sim.state.clients.values()[sim.state.inbox.size() % sim.state.clients.size()]
	var b: Dictionary = sim.briefs.make_brief(sim.state, client, {})
	sim.state.inbox.append(b)
	return str(b["id"])


func test_two_campaigns_run_side_by_side() -> void:
	var sim: Simulation = Simulation.new(data, 31)
	var founder: String = sim.state.founder()["id"]
	var other: String = _add_employee(sim)
	assert_true(sim.start_campaign(_brief(sim), _choices([founder]))["ok"], "birinci kampanya")
	assert_true(sim.state.has_free_staff(), "bir kişi daha boşta")
	var second: Dictionary = sim.start_campaign(_brief(sim), _choices([other]))
	assert_true(second["ok"], "ikinci kampanya: %s" % second.get("error", ""))
	assert_eq(sim.state.campaigns.size(), 2)
	assert_false(sim.state.has_free_staff(), "herkes kampanyada")
	var third: Dictionary = sim.start_campaign(_brief(sim), _choices([founder]))
	assert_false(third["ok"], "boşta kimse yokken yeni kampanya olmaz")
	for i: int in 10:
		sim.step_day()
	for c: Dictionary in sim.state.campaigns:
		assert_gt(int(c["day"]), 0, "iki kampanya da ilerler")


func test_person_cannot_be_on_two_campaigns() -> void:
	var sim: Simulation = Simulation.new(data, 32)
	var founder: String = sim.state.founder()["id"]
	var other: String = _add_employee(sim)
	assert_true(sim.start_campaign(_brief(sim), _choices([founder]))["ok"])
	var r: Dictionary = sim.start_campaign(_brief(sim), _choices([founder, other]))
	assert_eq(str(r["error"]), "ERR_BUSY_EMPLOYEE", "kurucu zaten bir kampanyada")


func test_legacy_save_with_single_campaign_loads() -> void:
	var sim: Simulation = Simulation.new(data, 33)
	assert_true(sim.start_campaign(_brief(sim), _choices([sim.state.founder()["id"]]))["ok"])
	var saved: Dictionary = sim.state.to_dict()
	saved["active_campaign"] = saved["campaigns"][0]  # S3D öncesi biçim
	saved.erase("campaigns")
	var back: SimState = SimState.from_dict(data, saved)
	assert_eq(back.campaigns.size(), 1, "eski kayıttaki tek kampanya listeye girer")
