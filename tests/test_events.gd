extends GutTest
## M7-C: olay sistemi (GDD 16), dönem krizleri, bitki sulama, yazılım sertifikası.

var data: GameData


func before_all() -> void:
	data = GameData.load_from()


func _sim(year: int = 1990, seed_value: int = 11) -> Simulation:
	var sim: Simulation = Simulation.new(data, seed_value)
	sim.state.clock.week_index = (year - 1990) * sim.state.clock.weeks_per_year()
	sim.state.cash = 5000000.0
	return sim


func _hire(sim: Simulation, role: String = "copywriter", level: int = 3) -> Dictionary:
	var p: Dictionary = sim.staff._blank(sim.state, role, level)
	p["stats"] = {"strategy": 50.0, "creative": 50.0, "technical": 50.0, "communication": 50.0, "speed": 50.0, "attention": 50.0}
	p["hidden"] = {"potential": 90.0}
	p["salary"] = 1000.0
	p["name"] = "Test"
	sim.state.staff[p["id"]] = p
	return p


## Belli bir olayı kuyruğa koyar (bağlam verilir).
func _force(sim: Simulation, id: String, ctx: Dictionary = {}) -> Dictionary:
	return sim.events._enqueue(sim.state, sim.events.events[id], ctx)


func test_every_event_text_is_translated() -> void:
	var keys: Dictionary = {}
	var csv: FileAccess = FileAccess.open("res://localization/strings.csv", FileAccess.READ)
	while not csv.eof_reached():
		var row: PackedStringArray = csv.get_csv_line()
		if row.size() >= 3 and not row[1].is_empty() and not row[2].is_empty():
			keys[row[0]] = true
	var sim: Simulation = _sim()
	var missing: Array[String] = []
	var per_cat: Dictionary = {}
	for id: String in sim.events.event_ids:
		var ev: Dictionary = sim.events.events[id]
		per_cat[ev["category"]] = int(per_cat.get(ev["category"], 0)) + 1
		var parts: Array[String] = ["T", "X"]
		for i: int in (ev["options"] as Array).size():
			parts.append("O%d" % (i + 1))
		for part: String in parts:
			if not keys.has(EventSystem.text_key(id, part)):
				missing.append(EventSystem.text_key(id, part))
		for opt: Dictionary in ev["options"]:
			for p: String in ["effects", "success", "fail"]:
				for k: String in opt.get(p, {}):
					var eff: String = "EFF_" + k.replace(".", "_").to_upper()
					if k.begins_with("employee"):
						eff = "EFF_EMPLOYEE_" + ("STAT" if k.split(".")[1] == "stat" else k.split(".")[1].to_upper())
					if not keys.has(eff) and not missing.has(eff):
						missing.append(eff)
	assert_eq(missing, [] as Array[String], "eksik çeviriler")
	for cat: Variant in data.bal("events.categories"):
		assert_gte(int(per_cat.get(cat, 0)), 10, "%s kategorisinde en az 10 olay" % cat)


func test_condition_operators() -> void:
	assert_true(EventSystem.compare(60, ">=60"))
	assert_false(EventSystem.compare(59.9, ">=60"))
	assert_true(EventSystem.compare(1994, "==1994"))
	assert_true(EventSystem.compare(3, "<4"))
	assert_true(EventSystem.compare("large", "==large"))
	assert_false(EventSystem.compare("small", "==large"))
	assert_true(EventSystem.compare(true, true))


func test_weekly_events_arrive_and_pause_the_game() -> void:
	var sim: Simulation = _sim(1996)
	_hire(sim)
	_hire(sim, "account")
	var got: Array = []
	sim.event_started.connect(func(ev: Dictionary) -> void: got.append(ev))
	sim.pause_on_phase = true
	for i: int in 200:
		sim.step_week()
		if not got.is_empty():
			break
	assert_false(got.is_empty(), "200 haftada en az bir olay gelmeli")
	var week: int = sim.state.clock.week_index
	sim.step_week()
	assert_eq(sim.state.clock.week_index, week, "karar beklerken zaman durur")
	var inst: Dictionary = EventSystem.pending(sim.state)
	var r: Dictionary = ResolveEventCommand.new(inst["uid"], int(inst["options"][0])).execute(sim)
	assert_true(bool(r["ok"]))
	assert_true(EventSystem.pending(sim.state).is_empty())
	sim.step_week()
	assert_gt(sim.state.clock.week_index, week, "karardan sonra zaman akar")


func test_unpaused_mode_auto_resolves_with_first_option() -> void:
	var sim: Simulation = _sim()
	_force(sim, "office_cat")
	var cash0: float = sim.state.cash
	sim.step_week()
	sim.step_week()
	assert_true(EventSystem.pending(sim.state).is_empty(), "bot modunda bir hafta sonra kapanır")
	assert_lt(sim.state.cash, cash0 + 0.01)
	assert_eq(str(sim.state.events["log"][0]["id"]), "office_cat")


func test_check_options_roll_and_crisis_comms_adds_option() -> void:
	var sim: Simulation = _sim(2015)
	sim.state.reputation = 50.0
	var inst: Dictionary = _force(sim, "plagiarism", {"rival_id": data.rival_ids[0]})
	assert_eq(inst["options"], [0, 1], "Kriz İletişimi yokken ek seçenek yok")
	var check: Dictionary = sim.events.events["plagiarism"]["options"][1]["check"]
	var p0: float = sim.events.check_chance(sim.state, inst, check)
	(sim.state.research["done"] as Array).append("crisis_comms")
	assert_gt(sim.events.check_chance(sim.state, inst, check), p0, "kriz iletişimi şansı artırır")
	sim.state.events["queue"] = []
	sim.state.events["last"] = {}
	inst = _force(sim, "plagiarism", {"rival_id": data.rival_ids[0]})
	assert_eq(inst["options"], [0, 1, 2])
	var rep0: float = sim.state.reputation
	var r: Dictionary = sim.events.resolve(sim, inst["uid"], 2)
	assert_almost_eq(sim.state.reputation - rep0, 4.0, 0.001)
	assert_true(r["effects"].has("cash"))


func test_effects_reach_clients_staff_and_campaign() -> void:
	var sim: Simulation = _sim()
	var emp: Dictionary = _hire(sim)
	var client_id: String = sim.state.clients.keys()[0]
	var inst: Dictionary = _force(sim, "headhunter", {"employee_id": emp["id"], "rival_id": data.rival_ids[0]})
	sim.events.resolve(sim, inst["uid"], 2)
	assert_false(sim.state.staff.has(emp["id"]), "gitsin dersen çalışan ayrılır")
	inst = _force(sim, "client_scandal", {"client_id": client_id})
	sim.events.resolve(sim, inst["uid"], 1)
	assert_false(sim.state.clients.has(client_id), "müşteriyi bırak")
	var inbox0: int = sim.state.inbox.size()
	inst = _force(sim, "last_minute_brief")
	sim.events.resolve(sim, inst["uid"], 0)
	assert_eq(sim.state.inbox.size(), inbox0 + 1, "son dakika brief gelir")
	while sim.state.inbox.is_empty():
		sim.step_week()
	sim.state.inbox[0]["media_budget"] = 100000.0
	sim.start_campaign(sim.state.inbox[0]["id"], {"objective": "awareness", "audience": "", "tone": "",
		"mix": [{"channel": "newspaper", "share": 1.0}]})
	var camp: Dictionary = sim.state.active_campaign
	var days0: int = int(camp["days_total"])
	inst = _force(sim, "supplier_delay", {"campaign_id": camp["id"]})
	sim.events.resolve(sim, inst["uid"], 0)
	assert_eq(int(camp["days_total"]), days0 + 3, "tedarikçi gecikmesi teslimi uzatır")


func test_once_and_cooldown() -> void:
	var sim: Simulation = _sim()
	var ctx: Dictionary = sim.events._context(sim.state, "weekly")
	_force(sim, "office_cat")
	assert_false(sim.events._eligible(sim.state, sim.events.events["office_cat"], ctx), "bekleme süresinde tekrar gelmez")
	sim.state.clock.week_index += int(data.bal("events.cooldown_weeks"))
	assert_true(sim.events._eligible(sim.state, sim.events.events["office_cat"], ctx))
	sim.state.clock.week_index = 0
	_force(sim, "fax_broke")
	sim.state.clock.week_index = 400
	assert_false(sim.events._eligible(sim.state, sim.events.events["fax_broke"], ctx), "bir kerelik olay")


func test_1994_crisis_cuts_budgets_for_a_year() -> void:
	var sim: Simulation = _sim(1994)
	var client: Dictionary = sim.state.clients.values()[0]
	sim.state.clock.week_index += 3 * sim.state.clock.weeks_per_month - 1
	var got: Array = []
	sim.event_started.connect(func(ev: Dictionary) -> void: got.append(ev["id"]))
	sim.step_week()
	assert_has(got, "crisis_1994", "Nisan 1994'te kriz")
	sim.step_week()
	sim.step_week()
	assert_almost_eq(EventSystem.budget_mult(sim.state), 0.7, 0.0001)
	var cheap: Dictionary = sim.briefs.make_brief(sim.state, client, {})
	assert_lt(float(cheap["fee"]), float(data.bal("briefs.fee")[cheap["size"]][1]) * Economy.inflation(data, 1994) * 0.71)
	sim.state.clock.week_index += 12 * sim.state.clock.weeks_per_month
	sim.step_week()
	assert_almost_eq(EventSystem.budget_mult(sim.state), 1.0, 0.0001, "kriz bir yıl sonra biter")


func test_lockdown_hits_outdoor_reach() -> void:
	var sim: Simulation = _sim(2020)
	var setup: Dictionary = {"media_budget": 500000.0, "fee": 100000.0, "audience": "", "objective": "awareness",
		"sector": data.sector_ids[0], "mix": [{"channel": "billboard", "share": 1.0}]}
	var client: Dictionary = sim.state.clients.values()[0]
	var before: float = float(sim.kpi.compute(setup, client, 7.0, 2020, SimRng.new(1))["per_channel"][0]["impressions"])
	var inst: Dictionary = _force(sim, "lockdown")
	sim.events.resolve(sim, inst["uid"], 0)
	EventSystem.prepare_kpi(sim.state, setup)
	assert_almost_eq(float(setup["macro_impressions"]["ooh"]), 0.4, 0.0001)
	var after: float = float(sim.kpi.compute(setup, client, 7.0, 2020, SimRng.new(1))["per_channel"][0]["impressions"])
	assert_almost_eq(after, before * 0.4, before * 0.001, "kapanmada açık hava görülmesi ×0.4")


func test_plants_dry_without_water() -> void:
	var sim: Simulation = _sim()
	sim.state.office_level = 2
	sim.build.refresh(sim.state)
	var spot: Vector2 = Vector2.ZERO
	var placed: bool = false
	for x: int in range(1, 12):
		for y: int in range(1, 12):
			if not placed and sim.build.place_error(sim.state, "plant_big", Vector2(x, y), 0).is_empty():
				assert_eq(PlaceFurnitureCommand.new("plant_big", Vector2(x, y), 0).execute(sim), "")
				placed = true
				spot = Vector2(x, y)
	assert_true(placed, "bitki yerleşti (%s)" % spot)
	var q0: float = sim.state.room_quality
	for i: int in data.bali("plants.dry_weeks"):
		sim.step_week()
	assert_true(sim.build.plants_dry(sim.state))
	assert_lt(sim.state.room_quality, q0, "kuru bitki konfor vermez")
	assert_eq(WaterPlantsCommand.new().execute(sim), "")
	assert_almost_eq(sim.state.room_quality, q0, 0.001, "sulayınca geri gelir")
	_hire(sim, str(data.bal("plants.auto_water_role")), 1)
	for i: int in data.bali("plants.dry_weeks") + 1:
		sim.step_week()
	assert_false(sim.build.plants_dry(sim.state), "ofis asistanı sular")


func test_certification_needs_a_real_tool_and_boosts_its_area() -> void:
	var sim: Simulation = _sim()
	var emp: Dictionary = _hire(sim, "graphic_designer")
	assert_eq(TrainEmployeeCommand.new(emp["id"], "", "", "design").execute(sim), "ERR_NO_TOOL")
	assert_eq(ToolActionCommand.new("buy", "pixelshop").execute(sim), "")
	var cash0: float = sim.state.cash
	assert_eq(TrainEmployeeCommand.new(emp["id"], "", "", "design").execute(sim), "")
	assert_almost_eq(cash0 - sim.state.cash, sim.staff.certification_cost(sim.state), 0.01)
	assert_eq(TrainEmployeeCommand.new(emp["id"], "", "", "design").execute(sim), "ERR_CERTIFIED")
	assert_almost_eq(Employee.cert_mult(data, emp, "visual"), 1.0 + data.balf("certification.bonus"), 0.0001)
	assert_almost_eq(Employee.cert_mult(data, emp, "copy"), 1.0, 0.0001)


func test_events_survive_save_and_load() -> void:
	var sim: Simulation = _sim(2020)
	var inst: Dictionary = _force(sim, "lockdown")
	sim.events.resolve(sim, inst["uid"], 0)
	_force(sim, "office_cat")
	var saved: Dictionary = sim.state.to_dict()
	var copy: Simulation = _sim()
	copy.load_state(JSON.parse_string(JSON.stringify(saved)))
	assert_eq(str(EventSystem.pending(copy.state)["id"]), "office_cat")
	assert_almost_eq(EventSystem.budget_mult(copy.state), 0.85, 0.0001)
	var old: Dictionary = saved.duplicate(true)
	old.erase("events")
	copy.load_state(old)
	assert_true(EventSystem.pending(copy.state).is_empty(), "eski kayıt olaysız açılır")
