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
	menu.queue_free()
	GameState.new_game(5)
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
	GameState.set_phase_sliders([0.5, 0.3, 0.2])
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
	for child: Node in screen.get_children():
		if child.get_child_count() > 0 and child.get_child(0) is ReportDialog:
			child.get_child(0).queue_free()
	for id: String in ["clients", "finance", "history"]:
		screen.call("show_panel", id)
		await _shot("07_" + id)
	get_tree().quit()


func _shot(file_name: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out.path_join(file_name + ".png"))
