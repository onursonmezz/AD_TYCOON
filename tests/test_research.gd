extends GutTest
## M7-B: Ar-Ge (GDD 17) — araştırma puanı, kilitler, etkiler, Ar-Ge lab, Bilgi Defteri.

var data: GameData


func before_all() -> void:
	data = GameData.load_from()


func _choices(mix: Array = [{"channel": "newspaper", "share": 1.0}]) -> Dictionary:
	return {"objective": "awareness", "audience": "young", "tone": "humorous", "mix": mix}


func _sim(year: int = 1990) -> Simulation:
	var sim: Simulation = Simulation.new(data, 6)
	sim.state.clock.week_index = (year - 1990) * 48
	sim.state.cash = 5000000.0
	return sim


func _start(sim: Simulation, choices: Dictionary) -> Dictionary:
	while sim.state.inbox.is_empty():
		sim.step_week()
	sim.state.inbox[0]["media_budget"] = 400000.0
	return sim.start_campaign(sim.state.inbox[0]["id"], choices)


func test_tone_and_audience_are_automatic_before_research() -> void:
	var sim: Simulation = _sim()
	assert_true(bool(_start(sim, _choices())["ok"]))
	var setup: Dictionary = sim.state.active_campaign["setup"]
	assert_eq(setup["audience"], "", "araştırma yokken kitle otomatik")
	assert_eq(setup["tone"], "")
	var m: Dictionary = sim.scoring.combination(setup, {})
	assert_eq(float(m["sk"]), 1.0, "otomatik kitle nötr")
	assert_eq(float(m["tone"]), 1.0, "otomatik ton nötr")
	var sim2: Simulation = _sim()
	(sim2.state.research["done"] as Array).append_array(["tone_choice", "audience_analysis"])
	_start(sim2, _choices())
	assert_eq(sim2.state.active_campaign["setup"]["audience"], "young")
	assert_eq(sim2.state.active_campaign["setup"]["tone"], "humorous")


func test_research_needs_points_money_and_time() -> void:
	var sim: Simulation = _sim()
	assert_false(sim.research.can_start(sim.state, "tone_choice"), "Y1'de ton araştırması yok")
	sim.state.clock.week_index = 48
	assert_false(sim.research.can_start(sim.state, "tone_choice"), "AP yetmiyor")
	sim.research.on_campaign(sim.state, 8.0, "medium")
	assert_almost_eq(float(sim.state.research["points"]), 16.0, 0.001, "puan × büyüklük (orta ×2)")
	var cash0: float = sim.state.cash
	assert_eq(ResearchActionCommand.new("begin", "tone_choice").execute(sim), "")
	assert_almost_eq(cash0 - sim.state.cash, sim.research.cost(sim.state, "tone_choice"), 0.01)
	assert_eq(ResearchActionCommand.new("begin", "audience_analysis").execute(sim), "ERR_RESEARCH", "aynı anda bir araştırma")
	for i: int in int(data.research["tone_choice"]["weeks"]):
		assert_false(sim.research.has(sim.state, "tone_choice"))
		sim.step_week()
	assert_true(sim.research.has(sim.state, "tone_choice"))


func test_multi_channel_and_digital_need_research() -> void:
	var sim: Simulation = _sim(1999)
	var team: Array = [sim.state.founder()["id"]]
	assert_eq(sim.media.channel_limit(sim.state, team), 1)
	(sim.state.research["done"] as Array).append("media_planning")
	assert_gt(sim.media.channel_limit(sim.state, team), 1)
	assert_false(sim.research.channel_unlocked(sim.state, "banner_display"))
	assert_true(sim.research.channel_unlocked(sim.state, "newspaper"))
	assert_eq(str(_start(sim, _choices([{"channel": "banner_display", "share": 1.0}]))["error"]), "ERR_CHANNEL_LOCKED")
	assert_true(SearchCandidatesCommand.new("web_developer", "job_ad", "tr").execute(sim).is_empty(), "dijital pozisyon kilitli")
	(sim.state.research["done"] as Array).append("digital_department")
	assert_true(sim.research.channel_unlocked(sim.state, "banner_display"))
	assert_false(SearchCandidatesCommand.new("web_developer", "job_ad", "tr").execute(sim).is_empty())


func test_series_research_removes_repeat_client_penalty() -> void:
	var sim: Simulation = _sim()
	var setup: Dictionary = {"sector": "fast_food", "objective": "awareness", "client_id": "c1", "mix": [{"channel": "radio", "share": 1.0}]}
	var history: Array[Dictionary] = [{"sector": "retail", "objective": "awareness", "client_id": "c1", "main_channel": "tv", "week": 0}]
	var n0: float = float(sim.scoring.novelty(setup, history, 2, 1990)["n"])
	setup["series"] = true
	assert_gt(float(sim.scoring.novelty(setup, history, 2, 1990)["n"]), n0)


func test_ai_workshop_halves_ai_penalty() -> void:
	var sim: Simulation = _sim(2024)
	sim.state.hardware = "mchip"
	ToolActionCommand.new("buy", "hayalci_ai").execute(sim)
	assert_almost_eq(sim.research.ai_penalty_mult(sim.state), 1.0, 0.0001)
	(sim.state.research["done"] as Array).append("ai_workshop")
	assert_almost_eq(sim.research.ai_penalty_mult(sim.state), 0.5, 0.0001)


func test_rd_lab_needs_strategy_director_and_makes_points() -> void:
	var sim: Simulation = _sim()
	sim.state.office_level = 3
	sim.build.refresh(sim.state)
	var empty: Rect2 = Rect2()
	for room: Dictionary in sim.build.layout(sim.state).rooms:
		if room["type"] == "empty":
			empty = room["rect"]
	var rect: Rect2 = Rect2(empty.position + Vector2(1, 1), Vector2(4, 3))
	assert_eq(sim.build.room_error(sim.state, "rd_lab", rect), "ERR_ROOM_NEEDS_PLANNER")
	var p: Dictionary = sim.staff._blank(sim.state, "planner", 7)
	p["stats"] = {"strategy": 70.0, "creative": 40.0, "technical": 40.0, "communication": 60.0, "speed": 50.0, "attention": 50.0}
	sim.state.staff[p["id"]] = p
	assert_eq(BuildRoomCommand.new("rd_lab", rect).execute(sim), "")
	var ap0: float = float(sim.state.research["points"])
	sim.step_week()
	assert_almost_eq(float(sim.state.research["points"]) - ap0, 3.0, 0.001, "lab haftada +3 AP")
	assert_eq(sim.build.room_error(sim.state, "studio", Rect2(rect.position + Vector2(5, 0), Vector2(4, 3))), "ERR_ROOM_NEEDS_PRODUCER")


func test_knowledge_book_learns_from_campaigns_and_market_research() -> void:
	var sim: Simulation = _sim()
	(sim.state.research["done"] as Array).append_array(["tone_choice", "audience_analysis"])
	var setup: Dictionary = {"sector": "fast_food", "objective": "sales", "audience": "young", "tone": "humorous",
		"mix": [{"channel": "radio", "share": 1.0}]}
	assert_eq(sim.research.learn_from(sim.state, setup), 5)
	assert_true(sim.research.is_known(sim.state, "sector_objective", "fast_food", "sales"))
	assert_eq(sim.research.learn_from(sim.state, setup), 0, "aynı hücreler ikinci kez sayılmaz")
	assert_eq(ResearchActionCommand.new("insight", "fast_food").execute(sim), "ERR_RESEARCH")
	(sim.state.research["done"] as Array).append("market_research")
	var cash0: float = sim.state.cash
	assert_eq(ResearchActionCommand.new("insight", "fast_food").execute(sim), "")
	assert_almost_eq(cash0 - sim.state.cash, sim.research.market_research_cost(sim.state), 0.01)


func test_quick_start_knows_its_era_and_old_saves_keep_unlocks() -> void:
	var sim: Simulation = Simulation.new(data, 7, "", 2010)
	assert_true(sim.research.has(sim.state, "digital_department"), "2010'da dijital departman bilinen bir şey")
	assert_false(sim.research.has(sim.state, "tone_choice"), "ajansın kendi gelişimi yine araştırmayla")
	var old: Simulation = _sim(1996)
	var saved: Dictionary = old.state.to_dict()
	saved.erase("research")
	old.load_state(saved)
	assert_true(old.research.has(old.state, "media_planning"), "eski kayıtta Y7'de açık olanlar araştırılmış sayılır")
	assert_true(old.research.has(old.state, "tone_choice"))
