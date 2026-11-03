extends GutTest
## M5-B: pitch (GDD 14.2) — davet, hazırlık, kartlar, sonuç ve etkileri.

var data: GameData


func before_all() -> void:
	data = GameData.load_from()


func _sim_with_invite(seed_value: int) -> Simulation:
	var sim: Simulation = Simulation.new(data, seed_value)
	sim.state.office_level = 2
	sim.state.pitch_invites.append(sim.pitches.make_invite(sim.state))
	return sim


func _accept(sim: Simulation) -> void:
	var inv: Dictionary = sim.state.pitch_invites[0]
	assert_eq(sim.pitches.accept(sim.state, inv["id"], [sim.state.founder()["id"]], 1.0), "")


func _to_presentation(sim: Simulation) -> void:
	while not sim.pitches.is_waiting(sim.state):
		sim.step_week()


func _cards() -> Array:
	return ["market_data", "safe_concept", "price_advantage"]


func test_no_invites_from_home_office() -> void:
	var sim: Simulation = Simulation.new(data, 1)
	assert_eq(sim.pitches.call("_invite_chance", sim.state), 0.0, "ev odasına büyük marka ihale daveti göndermez")
	sim.state.office_level = 2
	assert_gt(sim.pitches.call("_invite_chance", sim.state), 0.0)


func test_invite_is_for_big_client_with_rivals() -> void:
	var sim: Simulation = _sim_with_invite(2)
	var inv: Dictionary = sim.state.pitch_invites[0]
	assert_gte(int(inv["client"]["scale"]), 2, "ulusal ya da çok uluslu marka")
	assert_false((inv["rivals"] as Array).is_empty())
	for key: String in PitchSystem.PREF_KEYS:
		assert_between(float(inv["prefs"][key]), -1.0, 1.0)


func test_accept_reserves_team_and_prep_builds_points() -> void:
	var sim: Simulation = _sim_with_invite(3)
	var founder: Dictionary = sim.state.founder()
	var fee: float = float(sim.state.pitch_invites[0]["participation_fee"])
	var cash0: float = sim.state.cash
	_accept(sim)
	assert_almost_eq(sim.state.cash - cash0, fee, 0.01, "katılım ücreti varsa ajansa ödenir")
	assert_false(Employee.is_available(founder, sim.state.clock.week_index), "pitch ekibi kampanyada çalışmaz")
	assert_eq(sim.pitches.accept(sim.state, "yok", [founder["id"]], 1.0), "ERR_NO_PITCH")
	sim.step_week()
	assert_gt(float(sim.state.pitch["s"]), 0.0)
	assert_gt(float(sim.state.pitch["k"]), 0.0)


func test_presentation_stops_time_in_game_mode() -> void:
	var sim: Simulation = _sim_with_invite(4)
	_accept(sim)
	_to_presentation(sim)
	sim.pause_on_phase = true
	var week: int = sim.state.clock.week_index
	sim.step_week()
	assert_eq(sim.state.clock.week_index, week, "sunum beklerken zaman ilerlemez")


func test_present_validates_rounds() -> void:
	var sim: Simulation = _sim_with_invite(5)
	_accept(sim)
	_to_presentation(sim)
	assert_false(bool(sim.pitches.present(sim.state, ["safe_concept", "market_data", "price_advantage"])["ok"]), "tur sırası")
	assert_false(bool(sim.pitches.present(sim.state, ["market_data"])["ok"]))
	assert_true(sim.pitches.is_waiting(sim.state))


func test_winning_adds_client_brief_and_reputation() -> void:
	var sim: Simulation = _sim_with_invite(6)
	_accept(sim)
	_to_presentation(sim)
	sim.state.pitch["rivals"] = []
	var client_id: String = sim.state.pitch["client"]["id"]
	var rep0: float = sim.state.reputation
	var r: Dictionary = sim.pitches.present(sim.state, _cards())
	assert_true(bool(r["won"]), "rakip yoksa kazanırız")
	assert_true(sim.state.clients.has(client_id))
	var has_brief: bool = false
	for b: Dictionary in sim.state.inbox:
		has_brief = has_brief or b["client_id"] == client_id
	assert_true(has_brief, "kazanınca ilk brief gelir")
	assert_almost_eq(sim.state.reputation - rep0, data.balf("pitch.win_reputation"), 0.001)
	assert_true(sim.state.pitch.is_empty())
	assert_true(Employee.is_available(sim.state.founder(), sim.state.clock.week_index), "ekip serbest kalır")


func test_losing_second_puts_client_on_shortlist() -> void:
	var sim: Simulation = _sim_with_invite(7)
	_accept(sim)
	_to_presentation(sim)
	sim.state.pitch["rivals"] = ["mavi_ok"]
	sim.state.rivals["mavi_ok"]["staff"] = 1000000.0
	var rep0: float = sim.state.reputation
	var r: Dictionary = sim.pitches.present(sim.state, _cards())
	assert_false(bool(r["won"]))
	assert_eq(int(r["rank"]), 2)
	assert_eq(r["winner"], "mavi_ok")
	assert_almost_eq(sim.state.reputation - rep0, data.balf("pitch.shortlist_reputation"), 0.001)
	assert_eq(sim.state.warm_clients.size(), 1)


func test_cards_fit_client_preferences() -> void:
	var sim: Simulation = _sim_with_invite(8)
	var pitch: Dictionary = {"prefs": {"risk": 1.0, "budget": 0.0, "digital": 0.0, "humor": 0.0}}
	assert_eq(sim.pitches.reaction(sim.pitches.card_fit(pitch, "bold_concept")), "good")
	assert_eq(sim.pitches.reaction(sim.pitches.card_fit(pitch, "safe_concept")), "bad")
	pitch["prefs"]["budget"] = 1.0
	assert_gt(sim.pitches.price_mult(pitch, 0.85), sim.pitches.price_mult(pitch, 1.15), "düşük teklif daha cazip")


func test_bot_mode_auto_presents_forgotten_pitch() -> void:
	var sim: Simulation = _sim_with_invite(9)
	_accept(sim)
	for i: int in 12:
		sim.step_week()
	assert_true(sim.state.pitch.is_empty(), "duraklamasız modda unutulan sunum kendiliğinden yapılır")
	assert_eq(sim.state.pitch_history.size(), 1)


func test_pitch_survives_save() -> void:
	var sim: Simulation = _sim_with_invite(10)
	_accept(sim)
	sim.step_week()
	var errors: Array[String] = []
	var loaded: Simulation = SaveCodec.decode(data, SaveCodec.encode(sim), errors)
	assert_eq(errors.size(), 0)
	assert_eq(loaded.state.pitch["phase"], "prep")
	assert_almost_eq(float(loaded.state.pitch["s"]), float(sim.state.pitch["s"]), 0.0001)
