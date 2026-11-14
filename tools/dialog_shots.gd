extends Node
## Pencere çekimi (UI-3): panel_shots'ın açılır pencere karşılığı. Sabit tohumlu bir oyunda bir kampanyayı bitirir, sonra
## rapor sekmelerini, yankıları, Sektör sekmelerini, Ayarlar sekmelerini ve Gelen Kutusu'nu tek tek çeker.
## Çalıştırma: godot --path . res://tools/dialog_shots.tscn --resolution 1672x941 -- --out=<klasör> [--lang=en]

const WARMUP_DAYS: int = 400

var _out: String = "user://dialog_shots"
var _lang: String = "tr"
var _screen: Control


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--lang="):
			_lang = arg.trim_prefix("--lang=")
	DirAccess.make_dir_recursive_absolute(_out)
	_run.call_deferred()


func _step() -> void:
	var sim: Simulation = GameState.sim
	while not EventSystem.pending(sim.state).is_empty():
		var inst: Dictionary = EventSystem.pending(sim.state)
		sim.events.resolve(sim, inst["uid"], int(inst["options"][0]))
	GameState.step_day()


func _shot(name: String) -> void:
	await get_tree().create_timer(0.8).timeout
	get_viewport().get_texture().get_image().save_png(_out.path_join(name + ".png"))


func _clear() -> void:
	for c: Node in (_screen.get("_modal_layer") as Control).get_children():
		c.queue_free()
	await get_tree().process_frame


func _open(dialog: Control) -> Control:
	await _clear()
	_screen.call("open_modal", dialog)
	return dialog


func _run() -> void:
	Settings.persist = false
	Clock.playtime.persist = false
	Settings.set_value("tutorial", false)
	Settings.set_value("autosave", false)
	TranslationServer.set_locale(_lang)
	GameState.new_game(7, "marketing_manager", 0, "", {"name": "Defne", "avatar": "kadin_02"})
	_screen = load("res://src/ui/screens/main.tscn").instantiate()
	add_child(_screen)
	var sim: Simulation = GameState.sim
	var days: int = 0
	while sim.state.inbox.is_empty() and days < WARMUP_DAYS:
		_step()
		days += 1
	await _clear()
	_screen.call("show_panel", "inbox")
	await _shot("inbox")
	_screen.call("close_panel")
	var wizard: WizardDialog = await _open(WizardDialog.new(sim.state.inbox[0], _screen))
	wizard.call("_on_start")
	var before: int = sim.state.finished.size()
	while sim.state.finished.size() == before and days < WARMUP_DAYS * 2:
		if GameState.is_waiting():
			GameState.set_phase_sliders([0.4, 0.4, 0.2])
		_step()
		days += 1
	_screen.call("close_panel")
	var camp: Dictionary = sim.state.finished[sim.state.finished.size() - 1]
	await _open(EchoDialog.new(camp, func() -> void: pass))
	await _shot("echo")
	var report: ReportDialog = await _open(ReportDialog.new(camp))
	for tab: String in ["summary", "reviews", "income", "breakdown"]:
		report.call("_show_tab", tab)
		await _shot("report_" + tab)
	var client: Dictionary = sim.state.clients.get(str(camp["setup"].get("client_id", "")), {})
	if client.is_empty():
		client = sim.state.clients.values()[0]
	await _open(ClientDialog.new(client, _screen))
	await _shot("client")
	await _open(ClientDialog.new(sim.state.clients.values()[sim.state.clients.size() - 1], _screen))
	await _shot("client_empty")
	await _clear()
	_screen.call("show_panel", "industry")
	var industry: Control = _screen.get("_panel")
	for tab: String in ["awards", "rankings", "rivals"]:
		industry.set("_tab", tab)
		industry.call("rebuild")
		await _shot("industry_" + tab)
	_screen.call("close_panel")
	var settings: SettingsDialog = await _open(SettingsDialog.new())
	for tab: String in ["audio", "game", "display", "language", "tempo"]:
		settings.set("_tab", tab)
		settings.call("_build")
		await _shot("settings_" + tab)
	await _clear()
	# Taslağı olmayan pencereler (UI-3 dili).
	await _open(ScandalDialog.new({"id": "sc_shot", "influencer": "@moda_ece"}))
	await _shot("scandal")
	await _open(AwardEntryDialog.new("golden_apple", func() -> void: pass))
	await _shot("award_entry")
	await _open(EraDialog.new("mobile"))
	await _shot("era")
	var emp: Dictionary = sim.state.staff.values()[0]
	await _open(OfferDialog.new({"id": "of_shot", "employee_id": emp["id"], "offer_salary": float(emp["salary"]) * 1.4,
		"rival": "mavi_ok"}))
	await _shot("offer")
	await _open(NegotiationDialog.new("renkli_baski", 20000.0, func(_d: float) -> void: pass))
	await _shot("negotiation")
	var fake: Dictionary = {"award": "golden_apple", "year": sim.state.clock.year(), "rivals": [{"rival": "mavi_ok", "level": "gold"}],
		"player": [{"name": "Yaz Kampanyası", "client_name": "Lezzetçi Köfte", "level": "silver"}],
		"grand_prix": {"who": "kivilcim", "campaign": ""}}
	await _open(CeremonyDialog.new(fake))
	await get_tree().create_timer(3.5).timeout
	await _shot("ceremony")
	await _clear()
	print("Pencere çekimleri: %s" % _out)
	get_tree().quit()
