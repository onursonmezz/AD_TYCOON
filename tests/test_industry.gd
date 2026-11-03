extends GutTest
## M5-A: rakip ajanslar (14.3), ödüller (15), sıralamalar.

var data: GameData


func before_all() -> void:
	data = GameData.load_from()


## data.balance'taki bir değeri test süresince değiştirir; dönüş eski değer.
func _set_bal(path: String, value: Variant) -> Variant:
	var keys: PackedStringArray = path.split(".")
	var node: Dictionary = data.balance
	for i: int in keys.size() - 1:
		node = node[keys[i]]
	var old: Variant = node[keys[keys.size() - 1]]
	node[keys[keys.size() - 1]] = value
	return old


func _hist(sim: Simulation, score: float, extra: Dictionary = {}) -> Dictionary:
	var h: Dictionary = {"campaign": sim.state.next_id("cp"), "client_id": "", "sector": "fast_food", "objective": "awareness",
		"main_channel": "national_tv", "size": "small", "week": sim.state.clock.week_index, "year": sim.state.clock.year(),
		"score": score, "factors": {"n": 1.0}, "client_name": "Lezzetçi", "name": "Test", "team": [sim.state.founder()["id"]],
		"channel_count": 1, "kpi_ratio": 1.0, "viral": false}
	h.merge(extra, true)
	sim.state.history.append(h)
	return h


func _go_to_month(sim: Simulation, month: int) -> void:
	while sim.state.clock.month() != month:
		sim.step_week()


func test_rivals_open_with_their_year() -> void:
	var sim: Simulation = Simulation.new(data, 1)
	assert_false(sim.state.rivals.has("piksel"), "2000'de açılan ajans 1990'da yok")
	assert_true(sim.state.rivals.has("mavi_ok"))
	sim.state.clock.week_index = (2000 - 1990) * sim.state.clock.weeks_per_year()
	sim.rivals.monthly(sim.state)
	assert_true(sim.state.rivals.has("piksel"))


func test_rival_stays_within_limits_and_can_close() -> void:
	var sim: Simulation = Simulation.new(data, 2)
	var old: Variant = _set_bal("rivals.close_monthly_chance", 1.0)
	sim.state.rivals["kivilcim"]["staff"] = 1.0
	for i: int in 24:
		sim.rivals.monthly(sim.state)
	_set_bal("rivals.close_monthly_chance", old)
	assert_false(bool(sim.state.rivals["kivilcim"]["alive"]), "1 kişilik ajans kapanır")
	var max_staff: float = float(sim.rivals.personality("mavi_ok")["max_staff"])
	assert_lte(float(sim.state.rivals["mavi_ok"]["staff"]), max_staff)
	assert_false(sim.rivals.alive_ids(sim.state).has("kivilcim"))


func test_unhappy_idle_client_can_be_stolen() -> void:
	var sim: Simulation = Simulation.new(data, 3)
	var old: Variant = _set_bal("rivals.steal_monthly_chance", 1.0)
	var ids: Array = sim.state.clients.keys()
	sim.state.clients[ids[0]]["satisfaction"] = 10.0
	sim.state.clients[ids[1]]["satisfaction"] = 90.0
	var stolen: Array[Dictionary] = sim.rivals.steal_clients(sim.state)
	_set_bal("rivals.steal_monthly_chance", old)
	assert_eq(stolen.size(), 1)
	assert_eq(stolen[0]["client_id"], ids[0])


func test_award_entry_only_in_open_month_and_once() -> void:
	var sim: Simulation = Simulation.new(data, 4)
	var h: Dictionary = _hist(sim, 8.5)
	assert_eq(sim.awards.enter(sim.state, sim.economy, "golden_apple", h["campaign"]), "ERR_AWARD_CLOSED")
	_go_to_month(sim, sim.awards.entry_month("golden_apple"))
	h["week"] = sim.state.clock.week_index
	var cash0: float = sim.state.cash
	assert_eq(sim.awards.enter(sim.state, sim.economy, "golden_apple", h["campaign"]), "")
	assert_almost_eq(cash0 - sim.state.cash, sim.awards.entry_fee(sim.state, "golden_apple"), 0.01)
	assert_eq(sim.awards.enter(sim.state, sim.economy, "golden_apple", h["campaign"]), "ERR_AWARD_NOT_ELIGIBLE", "ikinci kez olmaz")


func test_category_and_cause_eligibility() -> void:
	var sim: Simulation = Simulation.new(data, 5)
	var tv: Dictionary = _hist(sim, 9.0)
	var social: Dictionary = _hist(sim, 9.0, {"main_channel": "instafoto"})
	var csr: Dictionary = _hist(sim, 9.0, {"objective": "csr"})
	assert_false(sim.awards.is_eligible("digital_stars", tv), "TV işi Dijital Yıldızlar'a giremez")
	assert_true(sim.awards.is_eligible("digital_stars", social))
	assert_false(sim.awards.is_eligible("good_cause", tv))
	assert_true(sim.awards.is_eligible("good_cause", csr))
	assert_eq(sim.awards.category_of(_hist(sim, 8.0, {"channel_count": 3})), "integrated")


func test_jury_score_follows_gdd_formula() -> void:
	var sim: Simulation = Simulation.new(data, 6)
	var old: Variant = _set_bal("awards.jury_noise", 0.0)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	var h: Dictionary = _hist(sim, 9.0, {"viral": true, "factors": {"n": 1.1}})
	var expected: float = 9.0 * 0.5 + 1.1 * 2.0 + data.balf("awards.viral_bonus") + data.balf("awards.category_match")
	assert_almost_eq(sim.awards.jury_score("golden_apple", h, rng), expected, 0.0001)
	h["kpi_ratio"] = 1.5
	assert_almost_eq(sim.awards.jury_score("effie", h, rng), 9.0 * 0.5 + 1.1 * 2.0 + data.balf("awards.viral_bonus")
		+ 3.0 * 0.5 + float(data.awards["effie"]["difficulty"]), 0.0001, "Effie: KPI aşımı ×3, kategori yok")
	_set_bal("awards.jury_noise", old)


func test_ceremony_rewards_player_and_team() -> void:
	var sim: Simulation = Simulation.new(data, 7)
	var old_noise: Variant = _set_bal("awards.jury_noise", 0.0)
	var old_entries: Variant = _set_bal("rivals.entries_per_rival", [0, 0])
	var founder: Dictionary = sim.state.founder()
	founder["morale"] = 50.0
	var h: Dictionary = _hist(sim, 10.0, {"viral": true, "factors": {"n": 1.1}})
	sim.state.award_entries.append({"award": "golden_apple", "campaign": h["campaign"], "year": sim.state.clock.year()})
	var rep0: float = sim.state.reputation
	var result: Dictionary = sim.awards.ceremony(sim.state, "golden_apple")
	_set_bal("awards.jury_noise", old_noise)
	_set_bal("rivals.entries_per_rival", old_entries)
	var row: Dictionary = result["player"][0]
	# 10 × 0.5 + 1.1 × 2 + viral 1 + kategori uyumu: bronz/gümüş arası; Grand Prix eşiği 9.7'nin altında kalır.
	var expected: String = sim.awards.level_for("golden_apple", float(row["score"]))
	assert_true(["bronze", "silver"].has(expected))
	assert_eq(row["level"], expected)
	assert_eq(result["grand_prix"]["who"], "")
	assert_almost_eq(sim.state.reputation - rep0, float(data.bal("awards.reputation")[expected]), 0.001)
	assert_gt(float(founder["morale"]), 50.0)
	assert_gt(float(founder.get("award_points", 0.0)), 0.0)
	assert_true(sim.state.award_entries.is_empty())
	assert_eq(sim.state.award_history.size(), 1)


func test_award_points_raise_market_value() -> void:
	var sim: Simulation = Simulation.new(data, 8)
	var emp: Dictionary = {"role": "art_director", "level": 3, "stats": {"strategy": 50, "creative": 60, "technical": 50,
		"communication": 50, "speed": 55, "attention": 50}}
	var base: float = Employee.market_value(data, emp, 1995)
	emp["award_points"] = 5.0
	assert_almost_eq(Employee.market_value(data, emp, 1995), base * (1.0 + 5.0 * data.balf("awards.market_value_per_point")), 0.01)
	emp["award_points"] = 1000.0
	assert_almost_eq(Employee.market_value(data, emp, 1995), base * (1.0 + data.balf("awards.market_value_max")), 0.01)


func test_year_end_rankings_include_player_and_reset_points() -> void:
	var sim: Simulation = Simulation.new(data, 9)
	sim.state.award_points_year = 999.0
	sim.state.year_income = 1.0
	var r: Dictionary = sim.awards.year_end(sim.state)
	assert_eq(int(r["creative_rank"]), 1, "999 ödül puanıyla en kreatif ajans biziz")
	assert_gt(int(r["biggest_rank"]), 1, "₺1 gelirle en büyük değiliz")
	assert_eq(r["agency_of_year"], "player")
	assert_eq(sim.state.award_points_year, 0.0)
	assert_eq(sim.state.ranking_history.size(), 1)


func test_rival_transfer_weakens_rival() -> void:
	var sim: Simulation = Simulation.new(data, 10)
	sim.state.office_level = 2
	sim.state.cash = 500000.0
	var found: Array[Dictionary] = SearchCandidatesCommand.new("copywriter", "rival_transfer", "tr").execute(sim)
	assert_false(found.is_empty())
	var rival: String = found[0]["from_rival"]
	assert_true(sim.state.rivals.has(rival))
	var staff0: float = float(sim.state.rivals[rival]["staff"])
	assert_eq(HireEmployeeCommand.new(found[0]["id"]).execute(sim), "")
	assert_almost_eq(float(sim.state.rivals[rival]["staff"]), staff0 - data.balf("rivals.transfer_staff_loss"), 0.001)


func test_industry_state_survives_save() -> void:
	var sim: Simulation = Simulation.new(data, 11)
	for i: int in 60:
		sim.step_week()
	_hist(sim, 9.0)
	sim.state.award_buzz = 0.01
	var errors: Array[String] = []
	var loaded: Simulation = SaveCodec.decode(data, SaveCodec.encode(sim), errors)
	assert_eq(errors.size(), 0)
	assert_eq(loaded.state.rivals.size(), sim.state.rivals.size())
	assert_almost_eq(float(loaded.state.rivals["mavi_ok"]["staff"]), float(sim.state.rivals["mavi_ok"]["staff"]), 0.0001)
	assert_almost_eq(loaded.state.award_buzz, 0.01, 0.0001)
