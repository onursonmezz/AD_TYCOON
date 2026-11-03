extends GutTest
## M2: kayıt/yükleme, faz başında bekleme, rapor cümleleri, arayüz duman testi.

var data: GameData


func before_all() -> void:
	data = GameData.load_from()


func _choices() -> Dictionary:
	return {"objective": "awareness", "audience": "adult", "tone": "emotional",
		"mix": [{"channel": "newspaper", "share": 1.0}]}


## Basit, belirlenimci oyuncu: boştaysa ilk brief'i alır, fazları sabit slider'la onaylar.
func _play_week(sim: Simulation) -> void:
	if sim.state.is_idle() and not sim.state.inbox.is_empty():
		sim.start_campaign(sim.state.inbox[0]["id"], _choices())
	for i: int in sim.state.clock.days_per_week:
		if sim.state.waiting_for_input:
			sim.set_phase_sliders([0.5, 0.3, 0.2])
		sim.step_day()


func test_phase_start_waits_for_sliders() -> void:
	var sim: Simulation = Simulation.new(data, 21)
	sim.pause_on_phase = true
	while sim.state.inbox.is_empty():
		sim.step_week()
	assert_true(sim.start_campaign(sim.state.inbox[0]["id"], _choices())["ok"])
	var week: int = sim.state.clock.week_index
	sim.step_day()
	assert_true(sim.state.waiting_for_input, "1. faz başında beklemeli")
	sim.step_week()
	assert_eq(sim.state.clock.week_index, week, "beklerken zaman ilerlemez")
	assert_false(sim.set_phase_sliders([0.5, 0.5, 0.5]), "toplam 1 olmalı")
	assert_true(sim.set_phase_sliders([0.6, 0.4, 0.0]))
	var phases_seen: Array[int] = [0]
	for i: int in 200:
		if sim.state.active_campaign.is_empty():
			break
		if sim.state.waiting_for_input:
			phases_seen.append(sim.production.current_phase(sim.state.active_campaign))
			sim.set_phase_sliders([0.2, 0.3, 0.5])
		sim.step_day()
	assert_eq(phases_seen, [0, 1, 2], "her faz başında bir kez sorulur")
	assert_eq(sim.state.history.size(), 1)


func test_save_roundtrip_continues_identically() -> void:
	var a: Simulation = Simulation.new(data, 77)
	for i: int in 20:
		_play_week(a)
	var text: String = SaveCodec.encode(a)
	var errors: Array[String] = []
	var b: Simulation = SaveCodec.decode(data, text, errors)
	assert_eq(errors.size(), 0)
	assert_not_null(b)
	assert_almost_eq(b.state.cash, a.state.cash, 0.001)
	for i: int in 40:
		_play_week(a)
		_play_week(b)
	assert_eq(b.state.history.size(), a.state.history.size())
	assert_almost_eq(b.state.cash, a.state.cash, 0.01, "yüklenen oyun aynı şekilde devam etmeli")
	assert_eq(b.state.clock.week_index, a.state.clock.week_index)


func test_corrupt_save_is_rejected() -> void:
	var errors: Array[String] = []
	assert_null(SaveCodec.decode(data, "{bozuk", errors))
	assert_eq(errors, ["ERR_SAVE_CORRUPT"])


func _fake_report(sh: float, b: float, ratio: float, ideal: float, n: float) -> Dictionary:
	return {"combination": {"sh": sh, "sk": 1.0, "kn": 1.0, "tone": 1.0, "m": 1.0}, "focus": {"f": 1.0},
		"balance": {"b": b, "ratio": ratio, "ideal": ideal}, "novelty": {"n": n},
		"synergy": {"fragmentation": 0.0, "pairs": []}, "errors": 0, "s": 30.0, "k": 30.0, "t": 10.0, "target": 100.0}


func test_low_work_volume_is_explained_even_when_choices_are_perfect() -> void:
	# Oyuncu geri bildirimi: her şey yeşil ama puan 5.4. Sebep emeğin azlığıydı; rapor bunu söylemeli.
	var w: ReportWriter = ReportWriter.new(data)
	var report: Dictionary = _fake_report(1.25, 0.95, 1.0, 1.0, 1.0)
	report.merge({"s": 30.0, "k": 26.0, "t": 10.0, "target": 130.2}, true)
	var keys: Array[String] = []
	for line: Dictionary in w.explanation_lines(report):
		keys.append(str(line["key"]))
	assert_has(keys, "RL_VOLUME_LOW")
	assert_has(keys, "RL_SH_GOOD")
	report.merge({"s": 60.0, "k": 50.0, "t": 20.0}, true)
	keys.clear()
	for line: Dictionary in w.explanation_lines(report):
		keys.append(str(line["key"]))
	assert_has(keys, "RL_VOLUME_HIGH")


func test_satisfaction_parts_sum_to_delta() -> void:
	var clients: ClientSystem = ClientSystem.new(data)
	var client: Dictionary = {"scale": 0, "history": [], "personality": {"risk": 80, "detail": 50}}
	var parts: Dictionary = clients.satisfaction_parts(client, 5.4, 0.35, "bold", 1991, 3.0, 3, false, 1)
	var sum: float = 0.0
	for v: Variant in parts.values():
		sum += float(v)
	assert_almost_eq(sum, clients.satisfaction_delta(client, 5.4, 0.35, "bold", 1991, 3.0, 3, false, 1), 0.0001)
	assert_almost_eq(float(parts["timing"]), -18.0, 0.0001, "3 hafta gecikme")
	assert_almost_eq(float(parts["kpi"]), -6.5, 0.0001)
	assert_almost_eq(float(parts["bold_match"]), 5.0, 0.0001)


func test_report_lines_follow_thresholds() -> void:
	var w: ReportWriter = ReportWriter.new(data)
	var keys: Array[String] = []
	for line: Dictionary in w.explanation_lines(_fake_report(1.25, 0.8, 2.0, 0.6, 0.7)):
		keys.append(str(line["key"]))
	assert_has(keys, "RL_SH_GOOD")
	assert_has(keys, "RL_B_ANALYTIC", "oran ideali aşıyor → fazla analitik")
	assert_does_not_have(keys, "RL_B_CREATIVE")
	assert_has(keys, "RL_N_BAD")
	assert_eq(keys[0], "RL_SH_GOOD", "olumlu cümleler önce")


func test_reviews_match_score_band() -> void:
	var w: ReportWriter = ReportWriter.new(data)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	var reviews: Array[Dictionary] = w.reviews(9.6, rng)
	assert_eq(reviews.size(), 4)
	for r: Dictionary in reviews:
		assert_true(str(r["text_key"]).begins_with("REV_BAND5") or str(r["text_key"]).begins_with("REV_BAND4"))


func test_all_data_text_keys_are_translated() -> void:
	var keys: Dictionary = {}
	var csv: FileAccess = FileAccess.open("res://localization/strings.csv", FileAccess.READ)
	while not csv.eof_reached():
		var row: PackedStringArray = csv.get_csv_line()
		if row.size() >= 3 and not row[1].is_empty() and not row[2].is_empty():
			keys[row[0]] = true
	var missing: Array[String] = []
	for file_name: String in ["sectors.json", "objectives.json", "audiences.json", "tones.json", "tone_groups.json",
			"focus_areas.json", "channels.json", "combo_rules.json", "positions.json", "traits.json",
			"hiring_channels.json", "offices.json", "backgrounds.json", "rivals.json", "awards.json"]:
		for rec: Dictionary in data.raw[file_name]:
			for field: String in ["name_key", "desc_key"]:
				if rec.has(field) and not keys.has(rec[field]):
					missing.append(rec[field])
			for k: Variant in rec.get("title_keys", []):
				if not keys.has(k):
					missing.append(str(k))
	for cat: Dictionary in data.raw["channel_options.json"]["categories"].values():
		for def: Dictionary in cat.get("options", []):
			for k: Variant in [def["name_key"]]:
				if not keys.has(k):
					missing.append(str(k))
			for c: Dictionary in def["choices"]:
				for field: String in ["name_key", "desc_key"]:
					if c.has(field) and not keys.has(c[field]):
						missing.append(str(c[field]))
	for pos: Dictionary in data.raw["positions.json"]:
		var dept: String = "DEPT_" + str(pos["department"]).to_upper()
		if not keys.has(dept):
			missing.append(dept)
	var lines: Dictionary = data.raw["report_lines.json"]
	for rule: Dictionary in lines["explanations"]:
		if not keys.has(rule["key"]):
			missing.append(rule["key"])
	for r: Dictionary in lines["reviewers"]:
		if not keys.has(r["name_key"]):
			missing.append(r["name_key"])
	for band: Dictionary in lines["review_bands"]:
		for k: String in band["keys"]:
			if not keys.has(k):
				missing.append(k)
	assert_eq(missing, [] as Array[String], "TR+EN çevirisi eksik anahtarlar")


func test_ui_full_loop_smoke() -> void:
	GameState.new_game(5)
	var screen: Control = load("res://src/ui/screens/main.tscn").instantiate()
	add_child_autofree(screen)
	await wait_physics_frames(2)
	for id: String in ["inbox", "clients", "campaign", "finance", "history"]:
		screen.call("show_panel", id)
		await wait_physics_frames(1)
	var sim: Simulation = GameState.sim
	while sim.state.inbox.is_empty():
		GameState.step_day()
	var brief: Dictionary = sim.state.inbox[0]
	var wizard: WizardDialog = WizardDialog.new(brief, screen)
	screen.call("open_modal", wizard)
	await wait_physics_frames(2)
	wizard.call("_on_start")
	await wait_physics_frames(2)
	assert_false(sim.state.is_idle(), "sihirbaz kampanyayı başlattı")
	while not GameState.is_waiting():
		GameState.step_day()
	screen.call("show_panel", "campaign")
	await wait_physics_frames(1)
	var panel: CampaignPanel = screen.get("_panel")
	var sliders: Array[HSlider] = panel.get("_sliders")
	for s: HSlider in sliders:
		s.value = 100.0
	assert_almost_eq(panel.shares()[0], 1.0 / 3.0, 0.0001, "hepsi %100 → eşit dağılım (GDT)")
	sliders[0].value = 30.0
	sliders[1].value = 30.0
	sliders[2].value = 60.0
	assert_eq(sliders[0].value, 30.0, "bir slider diğerlerini kaydırmaz")
	assert_almost_eq(panel.shares()[2], 0.5, 0.0001)
	panel.call("_on_confirm")
	assert_false(GameState.is_waiting())
	var reports_before: int = sim.state.finished.size()
	for i: int in 1000:
		if GameState.is_waiting():
			GameState.set_phase_sliders([0.4, 0.4, 0.2])
		GameState.step_day()
		if sim.state.finished.size() > reports_before:
			break
	await wait_physics_frames(3)
	assert_gt(sim.state.finished.size(), reports_before, "rapor üretildi")
	GameState.end_game()
