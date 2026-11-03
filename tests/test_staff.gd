extends GutTest
## M3: çalışanlar, departmanlar, ofis (GDD 11, 12.1, 7.5).

var data: GameData


func before_all() -> void:
	data = GameData.load_from()


func _sim(seed_value: int = 3) -> Simulation:
	return Simulation.new(data, seed_value)


## Testler için doğrudan çalışan ekler (işe alım akışını atlar).
func _add(sim: Simulation, role: String, stat_value: float = 60.0, traits: Array = []) -> Dictionary:
	var emp: Dictionary = sim.staff._blank(sim.state, role, 1)
	for stat: Variant in data.bal("staff_rules.stats"):
		emp["stats"][stat] = stat_value
	emp["hidden"] = {"potential": 100.0, "loyalty": 50.0, "ego": 50.0, "stress_tolerance": 50.0}
	emp["traits"] = traits
	emp["name"] = role
	emp["salary"] = roundf(Employee.market_value(data, emp, sim.state.clock.year()))
	sim.state.staff[emp["id"]] = emp
	return emp


func _campaign(sim: Simulation, team: Array, objective: String = "awareness") -> Dictionary:
	var setup: Dictionary = {"client_id": "x", "sector": "fast_food", "objective": objective, "audience": "young",
		"tone": "humorous", "mix": [{"channel": "radio", "share": 1.0}], "size": "small", "fee": 1.0, "media_budget": 1.0,
		"deadline_weeks": 6, "sliders": [[1.0 / 3, 1.0 / 3, 1.0 / 3], [0.0, 1.0, 0.0], [1.0 / 3, 1.0 / 3, 1.0 / 3]],
		"team": team}
	return sim.production.create(setup, "cp_t", 0)


func _points_in_phase2_copy(sim: Simulation, emp: Dictionary) -> float:
	var camp: Dictionary = _campaign(sim, [emp["id"]])
	camp["day"] = int(camp["days_total"]) / 3 + 1  # 2. faz (Kreatif), slider'ın hepsi Copy'de
	sim.production.produce_day(camp, sim.state)
	return float(camp["points"]["copy"])


func test_specialist_produces_more_in_own_area() -> void:
	var sim: Simulation = _sim()
	var copywriter: Dictionary = _add(sim, "copywriter")
	var producer: Dictionary = _add(sim, "producer")
	var cw: float = _points_in_phase2_copy(sim, copywriter)
	var pr: float = _points_in_phase2_copy(sim, producer)
	assert_gt(cw, pr, "aynı statlarda copywriter Copy'de prodüktörden çok üretmeli")
	assert_almost_eq(cw / pr, 1.3 / 0.6, 0.01, "uzman ×1.3, tamamen başka iş ×0.6 (K-036)")


func test_specialty_interpretation() -> void:
	var sim: Simulation = _sim()
	var copywriter: Dictionary = _add(sim, "copywriter")
	assert_almost_eq(Employee.specialty_mult(data, copywriter, "copy"), 1.3, 0.0001)
	assert_almost_eq(Employee.specialty_mult(data, copywriter, "visual"), 1.0, 0.0001, "ana stat (kreatif), uzman değil")
	assert_almost_eq(Employee.specialty_mult(data, copywriter, "production"), 0.6, 0.0001)
	assert_almost_eq(Employee.specialty_mult(data, sim.state.founder(), "production"), 1.0, 0.0001, "kurucu genelci")


func test_team_produces_more_than_founder_alone() -> void:
	var sim: Simulation = _sim()
	var designer: Dictionary = _add(sim, "graphic_designer")
	var alone: Dictionary = _campaign(sim, [sim.state.founder()["id"]])
	var team: Dictionary = _campaign(sim, [sim.state.founder()["id"], designer["id"]])
	for i: int in 10:
		sim.production.produce_day(alone, sim.state)
		sim.production.produce_day(team, sim.state)
	var a: float = 0.0
	var b: float = 0.0
	for area: String in data.focus_ids:
		a += float(alone["points"][area])
		b += float(team["points"][area])
	assert_gt(b, a)


func test_overtime_increases_burnout() -> void:
	var sim: Simulation = _sim()
	var emp: Dictionary = _add(sim, "copywriter")
	sim.state.active_campaign = _campaign(sim, [emp["id"]])
	sim.state.overtime = true
	sim.staff_life.weekly(sim.state)
	assert_almost_eq(float(emp["burnout"]), 6.0, 0.0001, "fazla mesai haftası +6")
	sim.state.overtime = false
	sim.staff_life.weekly(sim.state)
	assert_almost_eq(float(emp["burnout"]), 3.0, 0.0001, "normal hafta toparlanma")


func test_night_owl_halves_overtime_burnout() -> void:
	var sim: Simulation = _sim()
	var emp: Dictionary = _add(sim, "copywriter", 60.0, ["night_owl"])
	sim.state.active_campaign = _campaign(sim, [emp["id"]])
	sim.state.overtime = true
	sim.staff_life.weekly(sim.state)
	assert_almost_eq(float(emp["burnout"]), 3.0, 0.0001)


func test_overtime_boosts_output_and_drains_energy() -> void:
	var sim: Simulation = _sim()
	var emp: Dictionary = _add(sim, "copywriter")
	sim.state.active_campaign = _campaign(sim, [emp["id"]])
	var normal: float = _points_in_phase2_copy(sim, emp)
	sim.state.overtime = true
	var crunch: float = _points_in_phase2_copy(sim, emp)
	assert_almost_eq(crunch / normal, 1.35, 0.001)
	var e0: float = float(emp["energy"])
	sim.staff_life.daily(sim.state)
	assert_almost_eq(e0 - float(emp["energy"]), 2.0 * data.balf("staff_rules.energy_work_per_day"), 0.0001, "enerji kaybı ×2")


func test_underpaid_employee_loses_morale() -> void:
	var sim: Simulation = _sim()
	var fair: Dictionary = _add(sim, "copywriter")
	var cheap: Dictionary = _add(sim, "copywriter")
	cheap["salary"] = float(cheap["salary"]) * 0.6
	for i: int in 8:
		sim.staff_life.weekly(sim.state)
	assert_lt(float(cheap["morale"]), float(fair["morale"]) - 10.0)


func test_hire_respects_office_capacity() -> void:
	var sim: Simulation = _sim()
	sim.state.cash = 1000000.0
	var found: Array[Dictionary] = SearchCandidatesCommand.new("copywriter", "job_ad", "tr").execute(sim)
	assert_eq(found.size(), 3)
	assert_eq(HireEmployeeCommand.new(found[0]["id"]).execute(sim), "")
	assert_eq(sim.state.staff.size(), 2)
	assert_eq(HireEmployeeCommand.new(found[1]["id"]).execute(sim), "ERR_OFFICE_FULL", "ev odası 1–2 kişi")


func test_search_costs_money_and_respects_years() -> void:
	var sim: Simulation = _sim()
	var cash0: float = sim.state.cash
	SearchCandidatesCommand.new("planner", "headhunter", "tr").execute(sim)
	assert_almost_eq(cash0 - sim.state.cash, 8000.0, 0.01)
	assert_eq(SearchCandidatesCommand.new("ui_ux_designer", "job_ad", "tr").execute(sim).size(), 0, "UI/UX 2000+")
	assert_eq(SearchCandidatesCommand.new("planner", "career_site", "tr").execute(sim).size(), 0, "kariyer sitesi 2000+")


func test_fire_pays_severance_and_hurts_morale() -> void:
	var sim: Simulation = _sim()
	var emp: Dictionary = _add(sim, "copywriter")
	var other: Dictionary = _add(sim, "producer")
	var cash0: float = sim.state.cash
	var m0: float = float(other["morale"])
	assert_eq(FireEmployeeCommand.new(emp["id"]).execute(sim), "")
	assert_almost_eq(cash0 - sim.state.cash, float(emp["salary"]), 0.01, "en az bir aylık tazminat")
	assert_almost_eq(float(other["morale"]), m0 - 5.0, 0.0001)
	assert_eq(FireEmployeeCommand.new(sim.state.founder()["id"]).execute(sim), "ERR_CANNOT_FIRE")


func test_office_move_requirements() -> void:
	var sim: Simulation = _sim()
	assert_false(sim.offices.can_move(sim.state), "Y1, ₺60k ile taşınılamaz")
	sim.state.cash = 2000000.0
	assert_false(sim.offices.can_move(sim.state), "Y2 dolmadan taşınılamaz")
	sim.state.clock.week_index = 48
	assert_true(sim.offices.can_move(sim.state))
	var cost: float = sim.offices.move_cost(sim.state, sim.offices.next_office(sim.state))
	assert_almost_eq(cost, 500000.0, 0.01, "GDD 12.1 tutarı, enflasyonsuz (K-048)")
	assert_eq(MoveOfficeCommand.new().execute(sim), "")
	assert_eq(sim.state.office_level, 2)
	assert_almost_eq(2000000.0 - sim.state.cash, cost, 0.01)
	assert_eq(sim.staff.capacity(sim.state), 6)


func test_monthly_costs_include_payroll_and_rent() -> void:
	var sim: Simulation = _sim()
	var emp: Dictionary = _add(sim, "copywriter")
	sim.state.office_level = 2
	var expected: float = data.balf("cashflow.monthly_base_cost") + 3000.0 + float(emp["salary"]) * 1.205
	var cash0: float = sim.state.cash
	sim.economy.monthly(sim.state, sim.offices.monthly_rent(sim.state) + sim.staff.monthly_payroll(sim.state))
	assert_almost_eq(cash0 - sim.state.cash, expected, 0.01)


func test_campaign_xp_levels_up_primary_stats() -> void:
	var sim: Simulation = _sim()
	var emp: Dictionary = _add(sim, "copywriter", 50.0)
	var report: Dictionary = {"score": 10.0, "s": 10.0, "k": 10.0, "t": 10.0}
	var names: Array[String] = sim.staff_life.campaign_finished(sim.state, [emp["id"]], report)
	assert_eq(names, ["copywriter"] as Array[String])
	assert_eq(int(emp["level"]), 2)
	assert_almost_eq(float(emp["stats"]["creative"]), 53.0, 0.0001, "ana stat kreatif +3")
	assert_almost_eq(float(emp["stats"]["strategy"]), 50.0, 0.0001)
	emp["hidden"]["potential"] = 53.0
	sim.staff_life.campaign_finished(sim.state, [emp["id"]], report)
	assert_almost_eq(float(emp["stats"]["creative"]), 53.0, 0.0001, "potansiyel tavanı")


func test_account_bonus_and_error_catch() -> void:
	var sim: Simulation = _sim()
	var acc: Dictionary = _add(sim, "account", 100.0, ["client_friend"])
	assert_almost_eq(sim.staff_life.account_bonus(sim.state, [acc["id"]]), 6.0 + 3.0, 0.0001)
	assert_almost_eq(sim.staff_life.account_bonus(sim.state, []), 0.0, 0.0001)
	var sim2: Simulation = _sim(9)
	assert_eq(sim2.staff_life.catch_errors(sim2.state, 5), 0, "trafikçi yoksa hata temizlenmez")
	_add(sim2, "proofreader", 100.0)
	var caught: int = 0
	for i: int in 50:
		caught += sim2.staff_life.catch_errors(sim2.state, 4)
	assert_between(caught, 80, 160, "dikkat 100 → hata başına ~%60")


func test_rival_offer_match_and_expiry() -> void:
	var sim: Simulation = _sim()
	var emp: Dictionary = _add(sim, "copywriter")
	emp["salary"] = float(emp["salary"]) * 0.5
	var rules: Dictionary = data.bal("staff_rules")
	var old_chance: float = float(rules["offer_monthly_chance"])
	rules["offer_monthly_chance"] = 1.0
	var offers: Array[Dictionary] = sim.staff_life.monthly_offers(sim.state)
	rules["offer_monthly_chance"] = old_chance
	assert_eq(offers.size(), 1)
	assert_eq(ResolveOfferCommand.new(offers[0]["id"], "match").execute(sim), "")
	assert_gt(float(emp["salary"]), Employee.market_value(data, emp, 1990))
	emp["salary"] = 1.0
	rules["offer_monthly_chance"] = 1.0
	sim.staff_life.monthly_offers(sim.state)
	rules["offer_monthly_chance"] = old_chance
	sim.state.clock.week_index += 3
	sim.staff_life.weekly(sim.state)
	assert_false(sim.state.staff.has(emp["id"]), "teklif cevapsız kalınca rakibe geçer")


func test_backgrounds_change_founder() -> void:
	var a: Simulation = Simulation.new(data, 1, "copywriter")
	var b: Simulation = Simulation.new(data, 1, "marketing_manager")
	assert_gt(float(a.state.founder()["stats"]["creative"]), float(b.state.founder()["stats"]["creative"]))
	assert_eq(b.state.clients.size(), a.state.clients.size() + 1, "pazarlama müdürü: müşteri ağı")


func test_save_migration_v1_to_v2() -> void:
	var sim: Simulation = _sim()
	var doc: Dictionary = JSON.parse_string(SaveCodec.encode(sim))
	doc["save_version"] = 1
	doc["state"].erase("staff")
	doc["state"]["player"] = {"strategy": 70, "creative": 80, "technical": 55, "communication": 50, "speed": 66,
		"attention": 50, "morale": 70, "energy": 100, "xp": 20, "level": 3}
	var errors: Array[String] = []
	var loaded: Simulation = SaveCodec.decode(data, JSON.stringify(doc), errors)
	assert_eq(errors.size(), 0)
	var f: Dictionary = loaded.state.founder()
	assert_false(f.is_empty())
	assert_almost_eq(float(f["stats"]["creative"]), 80.0, 0.0001)
	assert_eq(int(f["level"]), 3)
	for i: int in 10:
		loaded.step_week()
	assert_false(loaded.state.bankrupt)
