extends GutTest
## K-099: görev panosu — çalışan başına alan payları, yük, aşırı yükün verim/enerji/hata etkisi, otomatik dağıtım.

var data: GameData


func before_all() -> void:
	data = GameData.load_from()


func _hire(sim: Simulation, role: String) -> String:
	var p: Dictionary = sim.staff._blank(sim.state, role, 3)
	p["stats"] = {"strategy": 50.0, "creative": 50.0, "technical": 50.0, "communication": 50.0, "speed": 50.0, "attention": 50.0}
	p["hidden"] = {"potential": 90.0}
	p["salary"] = 1000.0
	p["name"] = "Test"
	sim.state.staff[p["id"]] = p
	return str(p["id"])


func _answer_events(sim: Simulation) -> void:
	while not EventSystem.pending(sim.state).is_empty():
		var inst: Dictionary = EventSystem.pending(sim.state)
		sim.events.resolve(sim, inst["uid"], int(inst["options"][0]))


## Ekip kurar, kampanyayı başlatır ve 1. fazın başında bekler.
func _waiting_sim(seed_value: int, roles: Array = []) -> Simulation:
	var sim: Simulation = Simulation.new(data, seed_value)
	sim.pause_on_phase = true
	sim.state.cash = 5000000.0
	var team: Array = [sim.state.founder()["id"]]
	for r: String in roles:
		team.append(_hire(sim, r))
	while sim.state.inbox.is_empty():
		_answer_events(sim)
		sim.step_week()
	var choices: Dictionary = {"objective": "awareness", "audience": "adult", "tone": "emotional",
		"mix": [{"channel": "newspaper", "share": 1.0}], "team": team}
	assert_true(sim.start_campaign(sim.state.inbox[0]["id"], choices)["ok"])
	sim.step_day()
	assert_true(sim.state.waiting_for_input)
	return sim


func _run_phase(sim: Simulation) -> void:
	var phase: int = sim.production.current_phase(sim.state.active_campaign)
	while not sim.state.active_campaign.is_empty() and sim.production.current_phase(sim.state.active_campaign) == phase \
			and not sim.state.waiting_for_input:
		_answer_events(sim)
		sim.step_day()


func _total_points(sim: Simulation) -> float:
	var t: float = 0.0
	for v: Variant in (sim.state.active_campaign["points"] as Dictionary).values():
		t += float(v)
	return t


func test_plan_matching_sliders_equals_old_production() -> void:
	var a: Simulation = _waiting_sim(41)
	var b: Simulation = _waiting_sim(41)
	var founder: String = a.state.founder()["id"]
	assert_true(a.set_phase_sliders([0.5, 0.3, 0.2]))
	assert_eq(b.set_phase_plan({founder: [0.5, 0.3, 0.2]}), "")
	_run_phase(a)
	_run_phase(b)
	assert_almost_eq(_total_points(b), _total_points(a), 0.0001, "herkes %100 ve paylar aynıysa üretim değişmez")


func test_overload_produces_more_but_tires_faster() -> void:
	var normal: Simulation = _waiting_sim(42)
	var heavy: Simulation = _waiting_sim(42)
	var f: String = normal.state.founder()["id"]
	assert_eq(normal.set_phase_plan({f: [0.5, 0.25, 0.25]}), "")
	assert_eq(heavy.set_phase_plan({f: [1.0, 0.5, 0.5]}), "")
	var e0: float = float(normal.state.staff[f]["energy"])
	_run_phase(normal)
	_run_phase(heavy)
	var pn: float = _total_points(normal)
	var ph: float = _total_points(heavy)
	assert_gt(ph, pn, "%200 yük toplamda daha çok üretir")
	assert_lt(ph, pn * 2.0, "ama iki katı değil (azalan getiri)")
	assert_lt(float(heavy.state.staff[f]["energy"]), float(normal.state.staff[f]["energy"]), "daha çok yorulur")
	assert_lt(float(normal.state.staff[f]["energy"]), e0 + 0.001)


func test_unassigned_member_rests_and_validation() -> void:
	var sim: Simulation = _waiting_sim(43, ["copywriter"])
	var f: String = sim.state.founder()["id"]
	var team: Array = sim.state.active_campaign["setup"]["team"]
	var cw: String = str(team[1])
	sim.state.staff[cw]["energy"] = 50.0
	assert_eq(sim.set_phase_plan({"yok": [1.0, 0.0, 0.0]}), "ERR_PLAN_MEMBER")
	assert_eq(sim.set_phase_plan({f: [1.0, 1.0, 0.5]}), "ERR_PLAN_OVERLOAD")
	assert_eq(sim.set_phase_plan({f: [0.0, 0.0, 0.0]}), "ERR_PLAN_EMPTY")
	assert_eq(sim.set_phase_plan({f: [1.0, 0.0, 0.0]}), "")
	assert_eq(sim.state.active_campaign["setup"]["sliders"][0], [1.0, 0.0, 0.0], "odak payı plandan gelir")
	_run_phase(sim)
	assert_gt(float(sim.state.staff[cw]["energy"]), 50.0, "görevsiz ekip üyesi dinlenir")


func test_auto_plan_covers_every_area_with_big_team() -> void:
	var sim: Simulation = _waiting_sim(44, ["copywriter", "art_director", "planner"])
	var plan: Dictionary = WorkPlan.auto(data, sim.state, sim.state.active_campaign, 0)
	assert_eq(plan.size(), 4)
	for i: int in 3:
		var covered: bool = false
		for id: Variant in plan:
			covered = covered or float(plan[id][i]) > 0.0
		assert_true(covered, "alan %d boş kalmaz" % i)
	for id: Variant in plan:
		assert_almost_eq(WorkPlan.load_of_alloc(plan[id]), 1.0, 0.0001, "otomatik plan kimseyi aşırı yüklemez")
	assert_eq(WorkPlan.validate(data, plan, sim.state.active_campaign["setup"]["team"]), "")


func test_solo_auto_plan_uses_sliders() -> void:
	var sim: Simulation = _waiting_sim(45)
	var plan: Dictionary = WorkPlan.auto(data, sim.state, sim.state.active_campaign, 0)
	var f: String = sim.state.founder()["id"]
	assert_almost_eq(WorkPlan.load_of_alloc(plan[f]), 1.0, 0.0001)
