extends GutTest
## M4-B: kanal kategorisi seçenekleri, riskler, influencer havuzu ve skandallar (GDD 9.2–9.7).

var data: GameData


func before_all() -> void:
	data = GameData.load_from()


func _setup(channel: String, options: Dictionary = {}, extra: Dictionary = {}) -> Dictionary:
	var s: Dictionary = {"sector": "fast_food", "objective": "awareness", "audience": "adult", "tone": "emotional",
		"mix": [{"channel": channel, "share": 1.0, "options": options}], "fee": 1000.0, "media_budget": 50000.0,
		"sliders": [[0.4, 0.3, 0.3], [0.4, 0.3, 0.3], [0.4, 0.3, 0.3]], "team": []}
	s.merge(extra, true)
	return s


func _impressions(sim: Simulation, setup: Dictionary, year: int = 1995) -> float:
	return float(sim.kpi.compute(setup, {"scale": 3}, 6.0, year, sim.state.rng)["per_channel"][0]["impressions"])


func test_ooh_location_a_costs_more_but_reaches_more() -> void:
	var sim: Simulation = Simulation.new(data, 1)
	var b: float = _impressions(sim, _setup("billboard", {"location": "b", "weeks": "2"}))
	var a: float = _impressions(sim, _setup("billboard", {"location": "a", "weeks": "2"}))
	assert_almost_eq(a / b, 2.5 / 2.0, 0.001, "A: maliyet ×2, erişim ×2.5 (GDD 9.2)")


func test_defaults_are_filled_and_validated() -> void:
	var sim: Simulation = Simulation.new(data, 2)
	var setup: Dictionary = _setup("billboard")
	setup["mix"][0].erase("options")
	setup["deadline_weeks"] = 6
	assert_eq(sim.media.prepare_mix(setup, sim.state), "")
	assert_eq(setup["mix"][0]["options"], {"location": "b", "weeks": "2"})
	setup["mix"][0]["options"]["location"] = "z"
	assert_eq(sim.media.prepare_mix(setup, sim.state), "ERR_CHANNEL_OPTION")


func test_option_from_year() -> void:
	var sim: Simulation = Simulation.new(data, 2)
	var opts: Dictionary = {"venue": "hotel", "catering": "basic", "guests": "press_influencers"}
	assert_eq(sim.options.validate("event_launch", opts, 2000), "ERR_CHANNEL_OPTION", "influencer davetlisi 2012+")
	assert_eq(sim.options.validate("event_launch", opts, 2013), "")


func test_bid_model_fits_objective() -> void:
	var sim: Simulation = Simulation.new(data, 3)
	var sales_cpa: Dictionary = sim.options.effects("search_ads", {"bid": "cpa", "targeting": "balanced"},
		_setup("search_ads", {}, {"objective": "sales"}), 2005)
	var aware_cpa: Dictionary = sim.options.effects("search_ads", {"bid": "cpa", "targeting": "balanced"},
		_setup("search_ads", {}, {"objective": "awareness"}), 2005)
	assert_gt(float(sales_cpa["er_mult"]), float(aware_cpa["er_mult"]), "Bilinirlik + CPA = kötü (GDD 9.5)")


func test_cookieless_world_weakens_narrow_targeting() -> void:
	var sim: Simulation = Simulation.new(data, 3)
	var setup: Dictionary = _setup("search_ads")
	var before: float = float(sim.options.effects("search_ads", {"bid": "cpm", "targeting": "narrow"}, setup, 2020)["er_mult"])
	var after: float = float(sim.options.effects("search_ads", {"bid": "cpm", "targeting": "narrow"}, setup, 2025)["er_mult"])
	assert_lt(after, before, "2024+ çerezsiz dünya")


func test_daypart_audience_fit() -> void:
	var sim: Simulation = Simulation.new(data, 3)
	var young: Dictionary = sim.options.effects("national_tv", {"daypart": "night", "spot": "30"}, _setup("national_tv", {}, {"audience": "young"}), 1995)
	var mature: Dictionary = sim.options.effects("national_tv", {"daypart": "night", "spot": "30"}, _setup("national_tv", {}, {"audience": "mature"}), 1995)
	assert_gt(float(young["impressions_mult"]), float(mature["impressions_mult"]), "Genç → gece (GDD 9.4)")


func test_tv_production_share_earns_margin_not_commission() -> void:
	var sim: Simulation = Simulation.new(data, 4)
	var setup: Dictionary = _setup("national_tv", {"daypart": "day", "spot": "30"}, {"deadline_weeks": 6, "media_budget": 100000.0})
	var settled: Dictionary = sim.media.settle_delivery(setup, sim.state)
	setup["production_margin"] = settled["production_margin"]
	assert_almost_eq(float(settled["production_margin"]), 100000.0 * 0.2 * 0.2, 0.01)
	var income: Dictionary = sim.kpi.agency_income(setup, 1.0)
	assert_almost_eq(float(income["commission"]), 100000.0 * 0.8 * 0.15, 0.01, "komisyon yalnız medya kısmından")


func test_event_is_production_with_margin() -> void:
	var sim: Simulation = Simulation.new(data, 4)
	var setup: Dictionary = _setup("event_launch", {"venue": "hotel", "catering": "basic", "guests": "public"},
		{"deadline_weeks": 6, "media_budget": 100000.0})
	var settled: Dictionary = sim.media.settle_delivery(setup, sim.state)
	assert_almost_eq(float(settled["production_margin"]), 100000.0 * 0.2, 0.01, "etkinlik marjı %20 (GDD 9.7: %15–25)")
	setup["production_margin"] = settled["production_margin"]
	assert_almost_eq(float(sim.kpi.agency_income(setup, 1.0)["commission"]), 0.0, 0.01)
	assert_gt(_impressions(sim, setup), 0.0)


func test_event_coordinator_halves_event_risk() -> void:
	var sim: Simulation = Simulation.new(data, 5)
	var opts: Dictionary = {"venue": "open_air", "catering": "basic", "guests": "public"}
	var count: Callable = func(team: Array) -> int:
		var n: int = 0
		for i: int in 2000:
			var setup: Dictionary = _setup("event_launch", opts, {"team": team})
			for o: Dictionary in sim.options.roll_risks("event_launch", opts, setup, 1000.0, sim.state):
				if o["note"] == "NOTE_EVENT_WEATHER":
					n += 1
		return n
	var alone: int = count.call([])
	var coord: Dictionary = sim.staff._blank(sim.state, "event_coordinator", 1)
	sim.state.staff[coord["id"]] = coord
	var with_coord: int = count.call([coord["id"]])
	assert_between(alone, 330, 470, "açık hava hava riski %20")
	assert_between(float(with_coord) / alone, 0.35, 0.65, "etkinlik koordinatörü riski yarıya indirir")


func test_guerrilla_fine_is_paid() -> void:
	var sim: Simulation = Simulation.new(data, 6)
	var fined: int = 0
	for i: int in 400:
		var setup: Dictionary = _setup("guerrilla", {"card": "fake_queue"}, {"deadline_weeks": 6})
		if float(sim.media.settle_delivery(setup, sim.state)["fines"]) > 0.0:
			fined += 1
	assert_between(fined, 80, 160, "sahte kuyruk %30 risk")


func test_influencer_pool_opens_with_channel() -> void:
	var sim: Simulation = Simulation.new(data, 7)
	sim.influencers.weekly(sim.state)
	assert_eq(sim.state.influencers.size(), 0, "1990'da influencer yok")
	sim.state.clock.week_index = (2013 - 1990) * 48
	sim.influencers.weekly(sim.state)
	assert_eq(sim.state.influencers.size(), 12)
	assert_eq(sim.influencers.pool_for(sim.state, "influencer_macro").size(), 0, "makro 2014+")
	sim.state.clock.week_index = (2015 - 1990) * 48
	sim.influencers.weekly(sim.state)
	assert_gt(sim.influencers.pool_for(sim.state, "influencer_macro").size(), 0)


func test_fake_followers_waste_budget() -> void:
	var sim: Simulation = Simulation.new(data, 8)
	sim.state.clock.week_index = (2015 - 1990) * 48
	sim.influencers.refresh(sim.state)
	var inf: Dictionary = sim.influencers.pool_for(sim.state, "influencer_micro")[0]
	var setup: Dictionary = _setup("influencer_micro")
	inf["authenticity"] = 1.0
	var real: float = float(sim.influencers.kpi_inputs(sim.state, inf, float(inf["fee"]) * 4, setup)["impressions"])
	inf["authenticity"] = 0.4
	var fake: float = float(sim.influencers.kpi_inputs(sim.state, inf, float(inf["fee"]) * 4, setup)["impressions"])
	assert_almost_eq(fake / real, 0.4, 0.0001)
	assert_false(sim.influencers.can_see_authenticity(sim.state))
	var pr: Dictionary = sim.staff._blank(sim.state, "pr_specialist", 1)
	sim.state.staff[pr["id"]] = pr
	assert_true(sim.influencers.can_see_authenticity(sim.state), "PR & Etkinlik sahte takipçiyi görür (11.1)")


func test_repeat_collaboration_discount() -> void:
	var sim: Simulation = Simulation.new(data, 9)
	sim.state.clock.week_index = (2015 - 1990) * 48
	sim.influencers.refresh(sim.state)
	var inf: Dictionary = sim.state.influencers[0]
	var f0: float = sim.influencers.fee(sim.state, inf)
	sim.influencers.record_collab(sim.state, inf["id"])
	assert_almost_eq(sim.influencers.fee(sim.state, inf) / f0, 0.9, 0.0001)
	for i: int in 5:
		sim.influencers.record_collab(sim.state, inf["id"])
	assert_almost_eq(sim.influencers.fee(sim.state, inf) / f0, 0.8, 0.0001, "en fazla %20")


func test_scandal_decisions() -> void:
	var sim: Simulation = Simulation.new(data, 10)
	sim.state.clock.week_index = (2015 - 1990) * 48
	sim.influencers.refresh(sim.state)
	var inf: Dictionary = sim.state.influencers[0]
	inf["scandal_chance"] = 1.0
	sim.state.airing.append({"id": "cp_x"})
	var s: Dictionary = sim.influencers.maybe_scandal(sim.state, "cp_x", inf)
	assert_false(s.is_empty())
	var r: Dictionary = ResolveScandalCommand.new(s["id"], "terminate").execute(sim)
	assert_almost_eq(float(r["impressions_mult"]), 0.3, 0.0001)
	assert_eq(sim.state.airing[0]["scandal"]["choice"], "terminate")
	var s2: Dictionary = sim.influencers.maybe_scandal(sim.state, "cp_x", inf)
	sim.state.clock.week_index += 2
	sim.influencers.expire_scandals(sim.state)
	assert_eq(sim.state.airing[0]["scandal"]["choice"], "silent", "cevapsız kalınca sessiz kalınmış sayılır")
	assert_eq(sim.state.scandals.size(), 0)
	assert_ne(s2["id"], s["id"])


func test_influencer_campaign_end_to_end() -> void:
	var sim: Simulation = Simulation.new(data, 11)
	sim.state.clock.week_index = (2015 - 1990) * 48
	sim.state.cash = 2000000.0
	sim.influencers.refresh(sim.state)
	while sim.state.inbox.is_empty():
		sim.step_week()
	var brief: Dictionary = sim.state.inbox[0]
	var r: Dictionary = sim.start_campaign(brief["id"], {"objective": "engagement", "audience": "young", "tone": "humorous",
		"mix": [{"channel": "influencer_micro", "share": 1.0}]})
	assert_true(r["ok"], str(r))
	for i: int in 40:
		for sc: Dictionary in sim.state.scandals.duplicate():
			ResolveScandalCommand.new(sc["id"], "statement").execute(sim)
		sim.step_week()
	assert_eq(sim.state.finished.size(), 1)
	assert_gt(float(sim.state.finished[0]["kpi"]["per_channel"][0]["impressions"]), 0.0)
