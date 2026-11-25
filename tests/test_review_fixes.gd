extends GutTest
## K-149 (denetim düzeltmeleri): işi süren müşteri gitmez, yıl sonu vergisi duyurulur, ayrılanın görevi devredilir.

var data: GameData


func before_all() -> void:
	data = GameData.load_from()


func _choices(team: Array) -> Dictionary:
	return {"objective": "awareness", "audience": "adult", "tone": "emotional",
		"mix": [{"channel": "newspaper", "share": 1.0}], "team": team, "planned": true}


func _start(sim: Simulation, client: Dictionary, team: Array, size: String = "", assign: Array = []) -> Dictionary:
	var b: Dictionary = sim.briefs.make_brief(sim.state, client, {})
	if not size.is_empty():
		b["size"] = size
	sim.state.inbox.append(b)
	var ch: Dictionary = _choices(team)
	if not assign.is_empty():
		ch["assign"] = assign
	var r: Dictionary = sim.start_campaign(str(b["id"]), ch)
	assert_true(r["ok"], "kampanya başladı: %s" % r.get("error", ""))
	return sim.state.find_campaign(str(r["campaign_id"]))


func _hire(sim: Simulation) -> String:
	var found: Array[Dictionary] = sim.staff.search(sim.state, sim.economy, "copywriter", "job_ad", "tr")
	var emp: Dictionary = found[0]
	emp["hired_week"] = sim.state.clock.week_index - 30
	sim.state.staff[emp["id"]] = emp
	return str(emp["id"])


func test_unhappy_client_with_work_in_production_stays_until_paid() -> void:
	var sim: Simulation = Simulation.new(data, 501)
	var client: Dictionary = sim.state.clients.values()[0]
	var camp: Dictionary = _start(sim, client, [sim.state.founder()["id"]])
	client["satisfaction"] = 0.0
	var lost: Array[String] = sim.clients.remove_unhappy(sim.state)
	assert_true(lost.is_empty(), "üretimde işi olan müşteri ayrılmaz")
	var before: int = sim.state.receivables.size()
	sim._deliver(camp)
	assert_gt(sim.state.receivables.size(), before, "teslimde fatura kesilir")
	# Yayın biterken (kendi kampanyası sayılmaz) artık gidebilir.
	assert_true(ClientSystem.is_busy(sim.state, str(client["id"])), "yayında")
	assert_false(ClientSystem.is_busy(sim.state, str(client["id"]), str(camp["id"])), "biten kampanya sayılmaz")
	lost = sim.clients.remove_unhappy(sim.state, [], str(camp["id"]))
	assert_eq(lost, [str(client["id"])] as Array[String], "son işi biterken ayrılır")


func test_leaving_client_sends_no_new_briefs() -> void:
	var sim: Simulation = Simulation.new(data, 502)
	for c: Dictionary in sim.state.clients.values():
		c["satisfaction"] = 0.0
	sim.state.clock.week_index = 30  # ilk brief garantisinin dışında
	for i: int in 200:
		sim.briefs.weekly(sim.state)
	for b: Dictionary in sim.state.inbox:
		assert_false(sim.state.clients.has(b["client_id"]) and (b["prospect"] as Dictionary).is_empty(),
			"ayrılmak üzere olan müşteriden brief gelmez")


func test_event_leave_waits_for_running_work() -> void:
	var sim: Simulation = Simulation.new(data, 503)
	var client: Dictionary = sim.state.clients.values()[0]
	_start(sim, client, [sim.state.founder()["id"]])
	var notes: Array[String] = []
	sim.staff_note.connect(func(k: String, _a: Array, _kind: String) -> void: notes.append(k))
	EventEffects.apply(sim, {"id": "t", "ctx": {"client_id": client["id"]}}, {"client.leave": true})
	assert_true(sim.state.clients.has(client["id"]), "işi süren müşteri hemen gitmez")
	assert_eq(float(client["satisfaction"]), 0.0, "işi bitince gidecek")
	assert_has(notes, "NOTE_CLIENT_LEAVES_LATER")


func test_year_end_tax_is_announced_and_booked() -> void:
	var sim: Simulation = Simulation.new(data, 504)
	var notes: Array = []
	sim.staff_note.connect(func(k: String, a: Array, _kind: String) -> void:
		if k == "NOTE_YEAR_TAX":
			notes.append(a))
	sim.state.year_income = 1000000.0
	sim.state.year_expense = 200000.0
	var cash: float = sim.state.cash
	sim._end_year()
	var tax: float = 800000.0 * data.balf("economy.corporate_tax")
	assert_almost_eq(cash - sim.state.cash, tax, 0.01, "vergi kasadan düşer")
	assert_eq(notes.size(), 1, "bildirim çıkar")
	assert_almost_eq(float(notes[0][0]), tax, 0.01)
	assert_almost_eq(float(notes[0][1]), 800000.0, 0.01, "kâr")
	assert_almost_eq(float(sim.state.finance_months[-1]["out"]), tax, 0.01, "finans grafiğinde gider")
	assert_eq(sim.state.year_expense, 0.0, "vergi gelecek yılın matrahından düşmez")


func test_no_tax_note_on_loss() -> void:
	var sim: Simulation = Simulation.new(data, 505)
	var got: Array[String] = []
	sim.staff_note.connect(func(k: String, _a: Array, _kind: String) -> void: got.append(k))
	sim.state.year_income = 100.0
	sim.state.year_expense = 500.0
	sim._end_year()
	assert_does_not_have(got, "NOTE_YEAR_TAX")


func test_departed_assignee_tasks_go_to_team() -> void:
	var sim: Simulation = Simulation.new(data, 506)
	var ids: Array = [str(sim.state.founder()["id"])]
	for i: int in 3:
		ids.append(_hire(sim))
	var client: Dictionary = sim.state.clients.values()[0]
	var camp: Dictionary = _start(sim, client, ids, "medium", [[ids[1], ids[2], ids[3]], ["", "", ""], ["", "", ""]])
	var victim: String = str(ids[3])
	var notes: Array[Dictionary] = sim.staff_life.remove_employee(sim.state, victim)
	var row: Array = camp["setup"]["assign"][0]
	assert_false(row.has(victim), "ayrılanın adı planda kalmaz")
	assert_false(str(row[2]).is_empty(), "görev kalan birine geçti")
	assert_true((camp["setup"]["team"] as Array).has(str(row[2])), "devralan ekipte")
	assert_eq(notes.size(), 1, "devir bildirimi")
	assert_eq(str(notes[0]["key"]), "NOTE_TASK_REASSIGNED")
	assert_gt(TaskPlan.phase_intensity(camp["setup"], 0, str(row[2])), 0.0, "devralan bu fazda üretir")


func test_loading_a_game_waiting_for_phase_plan_reopens_the_plan() -> void:
	# K-150: faz planı beklerken kaydedilen oyun açılınca plan penceresi kendiliğinden gelir.
	GameState.new_game(507)
	var sim: Simulation = GameState.sim
	var client: Dictionary = sim.state.clients.values()[0]
	_start(sim, client, [sim.state.founder()["id"]])
	for i: int in 400:
		if GameState.is_waiting():
			break
		while not EventSystem.pending(sim.state).is_empty():
			var inst: Dictionary = EventSystem.pending(sim.state)
			sim.events.resolve(sim, inst["uid"], int(inst["options"][0]))
		sim.step_day()
	assert_true(GameState.is_waiting(), "2. fazın planı bekleniyor")
	sim.state.events["queue"] = []
	var screen: Control = load("res://src/ui/screens/main.tscn").instantiate()
	add_child_autofree(screen)
	await wait_physics_frames(3)
	assert_eq(screen.find_children("*", "TaskPlanDialog", true, false).size(), 1, "plan penceresi açık")
	GameState.end_game()
