extends Node
## Panel çekimi (UI-3): sabit tohumlu bir oyunda on menü penceresini tek tek, üstünde olay penceresi olmadan çeker.
## Taslaklarla (docs/reference/ui_mockups) yan yana karşılaştırmak için.
## Çalıştırma: godot --path . res://tools/panel_shots.tscn --resolution 1672x941 -- --out=<klasör> [--only=team,inbox] [--lang=en] [--cash=520000]

const PANELS: Array[String] = ["inbox", "clients", "campaign", "team", "office", "tools", "research", "finance", "industry", "history"]
const WARMUP_DAYS: int = 400
## Panel içi sekmeler (K-122): [panel, değişken, değer]; ana çekimden sonra ayrıca çekilir.
const SUB_VIEWS: Array = [["research", "_tab", "fit"], ["research", "_tab", "focus"], ["finance", "_view", "loan"],
	["finance", "_view", "suppliers"]]

var _out: String = "user://panel_shots"
var _audit: UiAudit = UiAudit.new()  # S11
var _only: PackedStringArray = PackedStringArray()
var _lang: String = "tr"
var _cash: float = -1.0  # --cash=: kasayı ayarla (ör. taşınma uyarısını görmek için)


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--only="):
			_only = arg.trim_prefix("--only=").split(",")
		elif arg.begins_with("--lang="):
			_lang = arg.trim_prefix("--lang=")
		elif arg.begins_with("--cash="):
			_cash = float(arg.trim_prefix("--cash="))
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
	Settings.set_value("minigames", false)  # mini oyun penceresi panelin üstüne çıkmasın
	TranslationServer.set_locale(_lang)
	GameState.new_game(7, "marketing_manager", 0, "", {"name": "Defne", "avatar": "kadin_02"})
	var screen: Control = load("res://src/ui/screens/main.tscn").instantiate()
	add_child(screen)
	var sim: Simulation = GameState.sim
	if _cash >= 0.0:
		sim.state.cash = _cash
	var days: int = 0
	while sim.state.inbox.is_empty() and days < WARMUP_DAYS:
		_step()
		days += 1
	# Kampanya penceresi dolu görünsün diye ilk brief'i başlat.
	if not sim.state.inbox.is_empty():
		var wizard: WizardDialog = WizardDialog.new(sim.state.inbox[0], screen)
		screen.call("open_modal", wizard)
		await get_tree().create_timer(0.4).timeout
		wizard.call("start_auto")
		while not GameState.is_waiting() and days < WARMUP_DAYS:
			_step()
			days += 1
	# S11: faz başında plan/mini oyun beklemesini geç (yoksa pencere kapanır, panel bulunmaz).
	for i: int in 6:
		if GameState.is_waiting():
			ToolUnblock.unblock(0.6)
	await get_tree().create_timer(0.3).timeout
	for id: String in PANELS:
		if not _only.is_empty() and not _only.has(id):
			continue
		for c: Node in (screen.get("_modal_layer") as Control).get_children():
			c.queue_free()
		screen.call("show_panel", id)
		await get_tree().create_timer(0.9).timeout
		var panel: Control = screen.get("_panel")
		var need: Vector2 = panel.get_combined_minimum_size()
		print("%s: içerik %.0f×%.0f" % [id, need.x, need.y])
		_audit.check(get_tree().root, id)
		get_viewport().get_texture().get_image().save_png(_out.path_join(id + ".png"))
		for sub: Array in SUB_VIEWS:
			if sub[0] != id:
				continue
			panel.set(str(sub[1]), sub[2])
			panel.call("refresh")
			await get_tree().create_timer(0.5).timeout
			need = panel.get_combined_minimum_size()
			print("%s/%s: içerik %.0f×%.0f" % [id, sub[2], need.x, need.y])
			_audit.check(get_tree().root, "%s_%s" % [id, sub[2]])
			get_viewport().get_texture().get_image().save_png(_out.path_join("%s_%s.png" % [id, sub[2]]))
	print("Panel çekimleri: %s" % _out)
	_audit.save(_out.path_join("audit.txt"))
	get_tree().quit()
