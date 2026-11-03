extends GutTest
## M7-A: araçlar, sürümler, abonelik, donanım (GDD 12.4–12.5), dönemler ve hızlı başlangıç (5.1–5.2).

var data: GameData


func before_all() -> void:
	data = GameData.load_from()


func _sim_at(year: int) -> Simulation:
	var sim: Simulation = Simulation.new(data, 3)
	sim.state.clock.week_index = (year - 1990) * sim.state.clock.weeks_per_year()
	sim.state.cash = 10000000.0
	sim.tools.refresh(sim.state)
	return sim


func test_starter_tools_keep_old_balance() -> void:
	var sim: Simulation = Simulation.new(data, 1)
	for area: Variant in data.bal("tools.areas"):
		assert_almost_eq(float(sim.state.tool_mults[area]), 1.0, 0.0001, "%s: başlangıç araçlarıyla ×1.0" % area)
	assert_eq(sim.state.hardware, "pc386")
	assert_eq(sim.tools.monthly_cost(sim.state), 0.0)


func test_buying_a_license_raises_its_area() -> void:
	var sim: Simulation = _sim_at(1990)
	var cash0: float = sim.state.cash
	assert_eq(ToolActionCommand.new("buy", "pixelshop").execute(sim), "")
	assert_almost_eq(cash0 - sim.state.cash, 4000.0, 0.01)
	assert_almost_eq(float(sim.state.tool_mults["design"]), 1.15, 0.0001)
	assert_eq(ToolActionCommand.new("buy", "pixelshop").execute(sim), "ERR_TOOL_OWNED")
	assert_eq(ToolActionCommand.new("buy", "figmo").execute(sim), "ERR_TOOL_NA", "1990'da Figmo yok")


func test_old_versions_lose_value_and_can_be_updated() -> void:
	var sim: Simulation = _sim_at(1990)
	ToolActionCommand.new("buy", "pixelshop").execute(sim)
	sim.state.clock.week_index = (1998 - 1990) * 48
	sim.tools.refresh(sim.state)
	assert_almost_eq(float(sim.state.tool_mults["design"]), 1.0 + 0.15 * 0.7, 0.0001, "2 sürüm geride: katkı %70")
	var cost: float = sim.tools.update_cost(sim.state, "pixelshop")
	assert_almost_eq(cost, 4000.0 * Economy.inflation(data, 1998) * 0.6, 0.01)
	assert_eq(ToolActionCommand.new("update", "pixelshop").execute(sim), "")
	assert_almost_eq(float(sim.state.tool_mults["design"]), 1.25, 0.0001)


func test_old_computers_cannot_run_new_versions() -> void:
	var sim: Simulation = _sim_at(1990)
	ToolActionCommand.new("buy", "pixelshop").execute(sim)
	sim.state.clock.week_index = (2004 - 1990) * 48
	assert_eq(ToolActionCommand.new("update", "pixelshop").execute(sim), "", "PC-386 1999'a kadar: 1998 sürümüne çıkar")
	assert_eq(int(sim.state.tools["pixelshop"]["version"]), 2)
	assert_eq(ToolActionCommand.new("update", "pixelshop").execute(sim), "ERR_HARDWARE", "2003 sürümü G4 ister")
	assert_eq(ToolActionCommand.new("hardware", "g4").execute(sim), "")
	assert_eq(ToolActionCommand.new("update", "pixelshop").execute(sim), "")
	assert_eq(int(sim.state.tools["pixelshop"]["version"]), 3)


func test_subscription_era_freezes_licenses() -> void:
	var sim: Simulation = _sim_at(2010)
	sim.state.hardware = "imak"
	ToolActionCommand.new("buy", "pixelshop").execute(sim)
	sim.state.clock.week_index = (2013 - 1990) * 48
	var notes: Array[Dictionary] = sim.tools.yearly(sim.state)
	var keys: Array = notes.map(func(n: Dictionary) -> String: return n["key"])
	assert_has(keys, "NOTE_TOOL_SUBSCRIPTION")
	assert_eq(ToolActionCommand.new("update", "pixelshop").execute(sim), "ERR_TOOL_SUB_ONLY")
	assert_eq(ToolActionCommand.new("subscribe", "pixelshop").execute(sim), "")
	assert_eq(int(sim.state.tools["pixelshop"]["version"]), 5, "abonelik hep son sürüm")
	assert_almost_eq(sim.tools.monthly_cost(sim.state), sim.tools.seat_cost(sim.state, "pixelshop") * sim.state.staff.size(), 0.01)
	assert_eq(ToolActionCommand.new("cancel", "pixelshop").execute(sim), "")
	assert_false(sim.tools.owned(sim.state, "pixelshop"))


func test_tools_raise_production_points() -> void:
	var a: Simulation = _sim_at(1990)
	var b: Simulation = _sim_at(1990)
	for id: String in ["pixelshop", "vektorel", "tablo_pro", "slayt_ustasi", "kelime_ustasi", "sayfa_ustasi", "anket_pro"]:
		ToolActionCommand.new("buy", id).execute(b)
	var pts: Array[float] = []
	for sim: Simulation in [a, b]:
		while sim.state.inbox.is_empty():
			sim.step_week()
		sim.start_campaign(sim.state.inbox[0]["id"], {"objective": "awareness", "audience": "adult", "tone": "emotional",
			"mix": [{"channel": "newspaper", "share": 1.0}]})
		for i: int in 21:
			sim.step_day()
		var total: float = 0.0
		for v: Variant in (sim.state.active_campaign["points"] as Dictionary).values():
			total += float(v)
		pts.append(total)
	assert_gt(pts[1], pts[0] * 1.1, "araçlı ajans aynı sürede daha çok puan üretir")


func test_ai_tools_cost_novelty() -> void:
	var sim: Simulation = _sim_at(2023)
	sim.state.hardware = "mchip"
	assert_eq(ToolActionCommand.new("buy", "hayalci_ai").execute(sim), "")
	assert_almost_eq(sim.state.ai_penalty, 0.04, 0.0001)
	var setup: Dictionary = {"sector": "fast_food", "objective": "awareness", "client_id": "x", "ai_penalty": sim.state.ai_penalty,
		"mix": [{"channel": "newspaper", "share": 1.0}]}
	var with_ai: float = float(sim.scoring.novelty(setup, [], 0, 2023)["n"])
	setup["ai_penalty"] = 0.0
	assert_almost_eq(with_ai, float(sim.scoring.novelty(setup, [], 0, 2023)["n"]) * 0.96, 0.0001)


func test_quick_start_scales_cash_and_era_base() -> void:
	var sim: Simulation = Simulation.new(data, 5, "", 2010)
	assert_eq(sim.state.clock.year(), 2010)
	assert_eq(sim.state.clock.game_year(), 1)
	assert_almost_eq(sim.state.cash, data.balf("start.cash") * Economy.inflation(data, 2010), 0.01)
	assert_almost_eq(sim.scoring.era_base(2010, "small"), 120.0, 0.001,
		"dönem tabanı oyunun başladığı yıldan büyür")
	assert_true(sim.state.rivals.has("yeni_nesil"), "2009'da açılan rakip var")
	assert_eq(sim.state.hardware, "imak")
	var errors: Array[String] = []
	var loaded: Simulation = SaveCodec.decode(data, SaveCodec.encode(sim), errors)
	assert_eq(loaded.state.clock.year(), 2010, "başlangıç yılı kayda girer")
	assert_almost_eq(loaded.scoring.era_base(2010, "small"), 120.0, 0.001)


func test_new_era_is_announced() -> void:
	var sim: Simulation = _sim_at(1996)
	sim.state.clock.week_index = (1997 - 1990) * 48 - 1
	watch_signals(sim)
	sim.step_week()
	assert_signal_emitted_with_parameters(sim, "era_started", ["web_dawn"])
	assert_eq(data.era_of(1990), "classic")
	assert_eq(data.era_of(2024), "ai")
