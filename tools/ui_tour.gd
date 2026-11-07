extends Node
## Geliştirici aracı: ekranları sırayla açıp ekran görüntüsü alır (arayüz kontrolü için).
## Çalıştırma (pencere açılır): godot --path . res://tools/ui_tour.tscn -- --out=C:/klasor [--lang=en]

var _out: String = "user://ui_tour"
## --lang=en: turu İngilizce çalıştırır (M9-C çeviri kontrolü: taşan ya da kesilen metin).
var _lang: String = "tr"


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--lang="):
			_lang = arg.trim_prefix("--lang=")
	DirAccess.make_dir_recursive_absolute(_out)
	_run.call_deferred()


func _run() -> void:
	Settings.persist = false
	Settings.set_value("tutorial", true)
	Settings.set_value("tutorial_seen", [])
	TranslationServer.set_locale(_lang)
	var menu: Control = load("res://src/ui/screens/main_menu.tscn").instantiate()
	add_child(menu)
	await _shot("01_main_menu")
	menu.call("_on_new_game")
	await _shot("01b_background")
	menu.queue_free()
	GameState.new_game(5, "marketing_manager")
	var screen: Control = load("res://src/ui/screens/main.tscn").instantiate()
	add_child(screen)
	await get_tree().create_timer(3.0).timeout
	await _shot("01c_office_home")
	# M9-C: hoş geldin ipucu; sonra ipuçları kapanır ki diğer ekranları örtmesin.
	await _shot("01d_tip")
	Settings.set_value("tutorial", false)
	(screen.get("_tutorial") as Tutorial).call("_close")
	var sim: Simulation = GameState.sim
	while sim.state.inbox.size() < 2:
		_step()
	screen.call("show_panel", "inbox")
	await _shot("02_inbox")
	var wizard: WizardDialog = WizardDialog.new(sim.state.inbox[0], screen)
	screen.call("open_modal", wizard)
	await _shot("03_wizard")
	wizard.call("_on_start")
	while not GameState.is_waiting():
		_step()
	await _shot("04_phase_sliders")
	var panel: CampaignPanel = screen.get("_panel")
	var sliders: Array[HSlider] = panel.get("_sliders")
	sliders[0].value = 30.0
	sliders[1].value = 90.0
	sliders[2].value = 60.0
	await _shot("04b_phase_sliders_moved")
	panel.call("_on_confirm")
	Clock.set_paused(true)
	for i: int in 10:
		_step()
	await _shot("05_phase_running")
	var before: int = sim.state.finished.size()
	while sim.state.finished.size() == before:
		if GameState.is_waiting():
			GameState.set_phase_sliders([0.4, 0.4, 0.2])
		_step()
	await get_tree().create_timer(2.0).timeout
	await _shot("06_report")
	var scrolls: Array[Node] = screen.find_children("*", "ScrollContainer", true, false)
	for sc: Node in scrolls:
		if (sc as ScrollContainer).is_visible_in_tree() and sc.get_parent() is PanelContainer \
				and sc.get_parent().get_parent() is CenterContainer:
			(sc as ScrollContainer).scroll_vertical = 100000
	await _shot("06b_report_bottom")
	# Rapor (ve araya giren olay) penceresi modal katmanının içinde; panelleri çekmeden önce kapat.
	await _close_modals(screen)
	for id: String in ["clients", "finance", "history"]:
		screen.call("show_panel", id)
		await _shot("07_" + id)
	sim.state.cash = 900000.0
	var hiring: HiringDialog = HiringDialog.new()
	screen.call("open_modal", hiring)
	await get_tree().process_frame
	hiring.call("_on_search")
	await _shot("08_hiring")
	var cand: Dictionary = sim.state.candidates[0]
	GameState.execute(HireEmployeeCommand.new(cand["id"]))
	hiring.queue_free()
	screen.call("show_panel", "team")
	await _shot("09_team")
	screen.call("show_panel", "office")
	await _shot("10_office")
	await _tour_media(screen, sim)
	get_tree().quit()


## M4: 3. yılda çoklu kanal + basılı iş, pazarlık penceresi, kanal bazında rapor.
func _tour_media(screen: Control, sim: Simulation) -> void:
	# M7-B: çoklu kanal, ton, kitle ve dijital kanallar araştırmayla açılır; tur için hazır sayılır.
	(sim.state.research["done"] as Array).append_array(["media_planning", "tone_choice", "audience_analysis", "digital_department"])
	while sim.state.clock.game_year() < 3 or not sim.state.is_idle() or sim.state.inbox.is_empty():
		if GameState.is_waiting():
			GameState.set_phase_sliders([0.4, 0.4, 0.2])
		_step()
	for child: Node in screen.get("_modal_layer").get_children():
		child.queue_free()
	await get_tree().process_frame
	var wizard: WizardDialog = WizardDialog.new(sim.state.inbox[0], screen)
	screen.call("open_modal", wizard)
	await get_tree().process_frame
	var mix: MixEditor = wizard.get("_mix")
	var ids: Array[String] = mix.get("_channel_ids")
	mix.call("_add_row", maxi(0, ids.find("flyer_brochure")))
	await _shot("11_wizard_mix")
	var job: Dictionary = mix.get_mix()[1].get("options", {}).get("job", {})
	if not job.is_empty():
		var dialog: NegotiationDialog = NegotiationDialog.new(job["supplier"], 20000.0, func(_d: float) -> void: pass)
		screen.call("open_modal", dialog)
		await get_tree().process_frame
		dialog.call("_on_offer")
		await _shot("12_negotiation")
		dialog.queue_free()
	wizard.call("_on_start")
	var before: int = sim.state.finished.size()
	while sim.state.finished.size() == before:
		if GameState.is_waiting():
			GameState.set_phase_sliders([0.4, 0.4, 0.2])
		_step()
	await get_tree().create_timer(2.0).timeout
	await _shot("13_report_channels")
	await _tour_options(screen, sim)


## M4-B: 2015'te açık hava + influencer seçenekleri ve skandal penceresi.
func _tour_options(screen: Control, sim: Simulation) -> void:
	for child: Node in screen.get("_modal_layer").get_children():
		child.queue_free()
	sim.state.clock.week_index = (2015 - 1990) * 48
	sim.influencers.refresh(sim.state)
	while sim.state.inbox.is_empty():
		_step()
	var brief: Dictionary = sim.state.inbox[0]
	brief["media_budget"] = 400000.0
	var wizard: WizardDialog = WizardDialog.new(brief, screen)
	screen.call("open_modal", wizard)
	await get_tree().process_frame
	var mix: MixEditor = wizard.get("_mix")
	var ids: Array[String] = mix.get("_channel_ids")
	var rows: Array = mix.get("_rows")
	(rows[0]["pick"] as OptionButton).select(maxi(0, ids.find("billboard")))
	(rows[0]["pick"] as OptionButton).item_selected.emit(maxi(0, ids.find("billboard")))
	mix.call("_add_row", maxi(0, ids.find("influencer_micro")))
	mix.call("_add_row", maxi(0, ids.find("national_tv")))
	await _shot("14_wizard_options")
	wizard.queue_free()
	var scandal: Dictionary = {"id": "sc_demo", "campaign_id": "", "influencer": "@ece42", "expires_week": sim.state.clock.week_index + 1}
	screen.call("open_modal", ScandalDialog.new(scandal))
	await _shot("15_scandal")
	await _tour_industry(screen, sim)


## M5-A: sektör ekranı (ödül takvimi, sıralama, rakipler), başvuru ve tören pencereleri.
func _tour_industry(screen: Control, sim: Simulation) -> void:
	for child: Node in screen.get("_modal_layer").get_children():
		child.queue_free()
	sim.state.cash = 900000.0
	while sim.state.clock.month() != sim.awards.entry_month("golden_apple"):
		_step()
		if GameState.is_waiting():
			GameState.set_phase_sliders([0.4, 0.4, 0.2])
	if not sim.state.history.is_empty():
		var last: Dictionary = sim.state.history[sim.state.history.size() - 1]
		last["week"] = sim.state.clock.week_index
		last["score"] = 9.2
	sim.state.rankings = sim.awards.year_end(sim.state)
	screen.call("show_panel", "industry")
	await _shot("16_industry")
	var entry: AwardEntryDialog = AwardEntryDialog.new("golden_apple", func() -> void: pass)
	screen.call("open_modal", entry)
	await _shot("17_award_entry")
	entry.queue_free()
	var fake: Dictionary = {"award": "golden_apple", "year": sim.state.clock.year(), "rivals": [{"rival": "mavi_ok", "level": "gold"}],
		"player": [{"name": "Yaz Kampanyası", "client_name": "Lezzetçi Köfte", "level": "silver"}],
		"grand_prix": {"who": "kivilcim", "campaign": ""}}
	screen.call("open_modal", CeremonyDialog.new(fake))
	await get_tree().create_timer(4.0).timeout
	await _shot("18_ceremony")
	await _tour_pitch(screen, sim)


## M5-B: ihale daveti (gelen kutusu + katılım penceresi) ve sunum mini oyunu.
func _tour_pitch(screen: Control, sim: Simulation) -> void:
	for child: Node in screen.get("_modal_layer").get_children():
		child.queue_free()
	sim.state.office_level = 3
	sim.state.pitch = {}
	sim.state.pitch_invites = [sim.pitches.make_invite(sim.state)]
	screen.call("show_panel", "inbox")
	screen.call("_refresh")
	await _shot("19_pitch_invite")
	var dialog: PitchInviteDialog = PitchInviteDialog.new(sim.state.pitch_invites[0])
	screen.call("open_modal", dialog)
	await _shot("20_pitch_join")
	dialog.call("_on_start")
	await get_tree().process_frame
	while not sim.pitches.is_waiting(sim.state):
		_step()
	var pd: PitchDialog = PitchDialog.new()
	screen.call("open_modal", pd)
	await get_tree().process_frame
	pd.call("_play", "insight_story")
	await _shot("21_pitch_round")
	pd.call("_play", "bold_concept")
	pd.call("_play", "meet_the_team")
	await _shot("22_pitch_result")
	await _tour_office(screen, sim)


## M6-A: 3D ofis (ev odası ve büyütülmüş ofis, döndürülmüş), çalışan kartı.
func _tour_office(screen: Control, sim: Simulation) -> void:
	for child: Node in screen.get("_modal_layer").get_children():
		child.queue_free()
	screen.call("close_panel")
	sim.state.office_level = 3
	sim.state.cash = 5000000.0
	for role: String in ["art_director", "copywriter", "planner", "producer", "account", "graphic_designer", "media_planner"]:
		var found: Array[Dictionary] = SearchCandidatesCommand.new(role, "job_ad", "tr").execute(sim)
		if not found.is_empty():
			HireEmployeeCommand.new(found[0]["id"]).execute(sim)
	EventBus.state_changed.emit()
	await get_tree().create_timer(6.0).timeout
	await _shot("23_office_3d")
	var view: OfficeView = screen.get("_office")
	view.world.rig.rotate_quarter(1)
	await get_tree().create_timer(1.0).timeout
	await _shot("24_office_rotated")
	var ids: Array = sim.state.staff.keys()
	screen.call("_on_employee_clicked", ids[1])
	await _shot("25_employee_card")
	await _tour_build(screen, sim)


## M6-B: ofis penceresi (kalite dökümü), çizilmiş oda ve mobilyalar, inşa modu araç çubuğu ve önizleme.
func _tour_build(screen: Control, sim: Simulation) -> void:
	var l: OfficeLayout = sim.build.layout(sim.state)
	var empty: Rect2 = Rect2()
	for room: Dictionary in l.rooms:
		if room["type"] == "empty":
			empty = room["rect"]
	GameState.execute(BuildRoomCommand.new("brainstorm", Rect2(empty.position + Vector2(1, 1), Vector2(5, 3))))
	var placed: int = 0
	for id: String in ["plant_big", "office_cat", "record_player", "plant_small", "whiteboard", "water_cooler"]:
		for x: int in range(2, 40):
			var p: Vector2 = Vector2(x * 0.5, 7.5 if placed % 2 == 0 else 0.5)
			if sim.build.place_error(sim.state, id, p, 0).is_empty():
				GameState.execute(PlaceFurnitureCommand.new(id, p, 0))
				placed += 1
				break
	GameState.execute(SetDeskTierCommand.new("ergonomic"))
	screen.call("show_panel", "office")
	await _shot("26_office_panel")
	screen.call("enter_build_mode")
	var view: OfficeView = screen.get("_office")
	var bar: BuildToolbar = screen.get("_build_bar")
	await get_tree().process_frame
	bar.call("_select", {"kind": "furniture", "id": "plant_big", "rot": 0})
	view.call("_build_hover", view.size * 0.5)
	await get_tree().create_timer(1.0).timeout
	await _shot("27_build_mode")
	await _tour_tools(screen, sim)


## M7-A: araçlar penceresi ve yeni dönem ekranı.
func _tour_tools(screen: Control, sim: Simulation) -> void:
	screen.call("exit_build_mode")
	sim.state.hardware = "imak"
	for id: String in ["pixelshop", "vektorel", "tablo_pro", "kelime_ustasi", "gooble_analitik", "sosyal_panel"]:
		GameState.execute(ToolActionCommand.new("buy", id))
	screen.call("show_panel", "tools")
	await _shot("28_tools")
	screen.call("close_panel")
	screen.call("open_modal", EraDialog.new("mobile"))
	await _shot("29_era")
	await _tour_research(screen, sim)


## M7-B: Ar-Ge ekranı ve Bilgi Defteri.
func _tour_research(screen: Control, sim: Simulation) -> void:
	for child: Node in screen.get("_modal_layer").get_children():
		child.queue_free()
	sim.state.research["points"] = 120.0
	(sim.state.research["done"] as Array).append_array(["tone_choice", "audience_analysis", "market_research"])
	sim.state.research["active"] = {"id": "media_planning", "weeks_left": 2}
	for h: Dictionary in sim.state.history:
		sim.research.reveal(sim.state, "sector_objective", h["sector"], h["objective"])
	sim.research.reveal(sim.state, "sector_objective", "fast_food", "sales")
	sim.research.reveal(sim.state, "sector_audience", "fast_food", "young")
	screen.call("show_panel", "research")
	await _shot("30_research")
	var panel: ResearchPanel = screen.get("_panel")
	panel.set("_sector", "fast_food")
	panel.call("rebuild")
	var scrolls: Array[Node] = panel.find_children("*", "ScrollContainer", true, false)
	(scrolls[0] as ScrollContainer).scroll_vertical = 100000
	await _shot("31_knowledge_book")
	await _tour_events(screen, sim)


## M7-C: olay penceresi (stat kontrolü, Kriz İletişimi seçeneği), sonucu; sertifika ve bitkiler.
func _tour_events(screen: Control, sim: Simulation) -> void:
	screen.call("close_panel")
	(sim.state.research["done"] as Array).append("crisis_comms")
	sim.state.reputation = 40.0
	sim.events._enqueue(sim.state, sim.events.events["plagiarism"], {"rival_id": DataDB.data.rival_ids[0]})
	var dialog: EventDialog = EventDialog.new(EventSystem.pending(sim.state))
	screen.call("open_modal", dialog)
	await _shot("32_event")
	dialog.call("_choose", 2)
	await _shot("33_event_result")
	dialog.queue_free()
	sim.state.build["watered_week"] = sim.state.clock.week_index - 6
	sim.build.refresh(sim.state)
	screen.call("show_panel", "office")
	await _shot("34_office_plants")
	screen.call("show_panel", "team")
	await _shot("35_team_certify")
	await _tour_art(screen, sim)


## M8-A: deneme modelleri, sokak, billboard ve posterler (gerçek .glb yerine Godot şekilleri).
func _tour_art(screen: Control, sim: Simulation) -> void:
	screen.call("close_panel")
	var view: OfficeView = screen.get("_office")
	await get_tree().create_timer(1.0).timeout
	view.world.rig.rotate_quarter(-1)
	await get_tree().create_timer(1.0).timeout
	await _shot("36_office_boxes")
	ModelLibrary.overrides = preload("res://tools/sample_models.gd").make_all("user://tour_sample_models")
	ModelLibrary.clear_cache()
	view.world.call("_build", sim.state.office_level)
	await get_tree().create_timer(1.5).timeout
	await _shot("37_office_samples")
	view.world.rig.rotate_quarter(1)
	view.world.rig.rotate_quarter(1)
	await get_tree().create_timer(1.0).timeout
	await _shot("38_office_posters")
	view.world.rig.rotate_quarter(-2)
	var size: Vector2 = view.world.layout.size
	view.world.rig.set("_target_pos", Vector3(size.x + 2.0, 0.0, size.y + 1.0))
	view.world.rig.zoom(-6)
	await get_tree().create_timer(1.5).timeout
	await _shot("39_billboard")
	# M8-B: kapsül karakterler (model yok) ve deneme karakterleri (iskeletli, animasyonlu).
	view.world.rig.set("_target_pos", Vector3(size.x * 0.35, 0.0, size.y * 0.55))
	view.world.rig.zoom(-2)
	await get_tree().create_timer(1.5).timeout
	await _shot("40_characters_capsule")
	ModelLibrary.overrides.merge(preload("res://tools/sample_models.gd").make_characters("user://tour_sample_models", DataDB.data))
	ModelLibrary.clear_cache()
	for c: OfficeCharacter in (view.world.get("_chars") as Dictionary).values():
		c.set("_look_sig", "")
	view.world.sync()
	await get_tree().create_timer(2.0).timeout
	await _shot("41_characters_samples")
	ModelLibrary.overrides = {}
	ModelLibrary.clear_cache()
	await _tour_saves(screen)


## M9-A: kaydet penceresi, ayarlar, çıkış onayı.
func _tour_saves(screen: Control) -> void:
	SaveSystem.dir = "user://tour_saves/"
	DirAccess.make_dir_recursive_absolute(SaveSystem.dir)
	GameState.sim.state.agency_name = "Mavi Fil"
	GameState.save_game("slot_1")
	var sl: SaveLoadDialog = SaveLoadDialog.new(true)
	screen.call("open_modal", sl)
	await _shot("42_save_slots")
	sl.queue_free()
	var st: SettingsDialog = SettingsDialog.new()
	screen.call("open_modal", st)
	await _shot("43_settings")
	st.queue_free()
	GameState.dirty = true
	screen.call("_confirm_leave", func() -> void: pass)
	await _shot("44_unsaved")
	for child: Node in screen.get("_modal_layer").get_children():
		child.queue_free()
	await get_tree().process_frame
	# M9-B: konfeti ve para uçuşu.
	Juice.confetti(screen)
	Juice.cash_fly(screen.get("_cash"), 250000.0, GameState.sim.state.clock.year())
	await get_tree().create_timer(0.6).timeout
	await _shot("45_juice")
	# M10: Finans ekranında kredi.
	screen.call("show_panel", "finance")
	await _shot("46_finance_loan")
	ModelLibrary.overrides = {}
	ModelLibrary.clear_cache()


func _shot(file_name: String) -> void:
	await get_tree().create_timer(0.35).timeout  # açılış animasyonu (G2) bitsin
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out.path_join(file_name + ".png"))


## Bir gün ilerletir; tur sırasında gelen olaylar (M7-C) ilk seçenekle cevaplanır, yoksa oyun durur.
func _step() -> void:
	var sim: Simulation = GameState.sim
	while not EventSystem.pending(sim.state).is_empty():
		var inst: Dictionary = EventSystem.pending(sim.state)
		sim.events.resolve(sim, inst["uid"], int(inst["options"][0]))
	GameState.step_day()


func _close_modals(screen: Node) -> void:
	for i: int in 3:
		for n: Node in screen.find_children("*", "", true, false):
			if n is ReportDialog or n is EventDialog:
				n.queue_free()
		await get_tree().process_frame
