extends Node
## Geliştirici aracı: ekranları sırayla açıp ekran görüntüsü alır (arayüz kontrolü için).
## Çalıştırma (pencere açılır): godot --path . res://tools/ui_tour.tscn -- --out=C:/klasor

var _out: String = "user://ui_tour"


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(_out)
	_run.call_deferred()


func _run() -> void:
	TranslationServer.set_locale("tr")
	var menu: Control = load("res://src/ui/screens/main_menu.tscn").instantiate()
	add_child(menu)
	await _shot("01_main_menu")
	menu.call("_on_new_game")
	await _shot("01b_background")
	menu.queue_free()
	GameState.new_game(5, "marketing_manager")
	var screen: Control = load("res://src/ui/screens/main.tscn").instantiate()
	add_child(screen)
	var sim: Simulation = GameState.sim
	while sim.state.inbox.size() < 2:
		GameState.step_day()
	screen.call("show_panel", "inbox")
	await _shot("02_inbox")
	var wizard: WizardDialog = WizardDialog.new(sim.state.inbox[0], screen)
	screen.call("open_modal", wizard)
	await _shot("03_wizard")
	wizard.call("_on_start")
	while not GameState.is_waiting():
		GameState.step_day()
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
		GameState.step_day()
	await _shot("05_phase_running")
	var before: int = sim.state.finished.size()
	while sim.state.finished.size() == before:
		if GameState.is_waiting():
			GameState.set_phase_sliders([0.4, 0.4, 0.2])
		GameState.step_day()
	await get_tree().create_timer(2.0).timeout
	await _shot("06_report")
	var scrolls: Array[Node] = screen.find_children("*", "ScrollContainer", true, false)
	for sc: Node in scrolls:
		if (sc as ScrollContainer).is_visible_in_tree() and sc.get_parent() is PanelContainer \
				and sc.get_parent().get_parent() is CenterContainer:
			(sc as ScrollContainer).scroll_vertical = 100000
	await _shot("06b_report_bottom")
	for child: Node in screen.get_children():
		if child.get_child_count() > 0 and child.get_child(0) is ReportDialog:
			child.get_child(0).queue_free()
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
	while sim.state.clock.game_year() < 3 or not sim.state.is_idle() or sim.state.inbox.is_empty():
		if GameState.is_waiting():
			GameState.set_phase_sliders([0.4, 0.4, 0.2])
		GameState.step_day()
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
		GameState.step_day()
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
		GameState.step_day()
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


func _shot(file_name: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out.path_join(file_name + ".png"))
