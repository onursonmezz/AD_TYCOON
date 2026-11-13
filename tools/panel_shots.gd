extends Node
## Panel çekimi (UI-3): sabit tohumlu bir oyunda on menü penceresini tek tek, üstünde olay penceresi olmadan çeker.
## Taslaklarla (docs/reference/ui_mockups) yan yana karşılaştırmak için.
## Çalıştırma: godot --path . res://tools/panel_shots.tscn --resolution 1672x941 -- --out=<klasör> [--only=team,inbox]

const PANELS: Array[String] = ["inbox", "clients", "campaign", "team", "office", "tools", "research", "finance", "industry", "history"]
const WARMUP_DAYS: int = 400

var _out: String = "user://panel_shots"
var _only: PackedStringArray = PackedStringArray()


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--only="):
			_only = arg.trim_prefix("--only=").split(",")
	DirAccess.make_dir_recursive_absolute(_out)
	_run.call_deferred()


func _step() -> void:
	var sim: Simulation = GameState.sim
	while not EventSystem.pending(sim.state).is_empty():
		var inst: Dictionary = EventSystem.pending(sim.state)
		sim.events.resolve(sim, inst["uid"], int(inst["options"][0]))
	GameState.step_day()


func _run() -> void:
	Settings.persist = false
	Clock.playtime.persist = false
	Settings.set_value("tutorial", false)
	Settings.set_value("autosave", false)
	TranslationServer.set_locale("tr")
	GameState.new_game(7, "marketing_manager", 0, "", {"name": "Defne", "avatar": "kadin_02"})
	var screen: Control = load("res://src/ui/screens/main.tscn").instantiate()
	add_child(screen)
	var sim: Simulation = GameState.sim
	var days: int = 0
	while sim.state.inbox.is_empty() and days < WARMUP_DAYS:
		_step()
		days += 1
	# Kampanya penceresi dolu görünsün diye ilk brief'i başlat.
	if not sim.state.inbox.is_empty():
		var wizard: WizardDialog = WizardDialog.new(sim.state.inbox[0], screen)
		screen.call("open_modal", wizard)
		await get_tree().create_timer(0.4).timeout
		wizard.call("_on_start")
		while not GameState.is_waiting() and days < WARMUP_DAYS:
			_step()
			days += 1
	for id: String in PANELS:
		if not _only.is_empty() and not _only.has(id):
			continue
		for c: Node in (screen.get("_modal_layer") as Control).get_children():
			c.queue_free()
		screen.call("show_panel", id)
		await get_tree().create_timer(0.9).timeout
		get_viewport().get_texture().get_image().save_png(_out.path_join(id + ".png"))
	print("Panel çekimleri: %s" % _out)
	get_tree().quit()
