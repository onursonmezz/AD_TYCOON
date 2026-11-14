extends Node
## Duvar aracı çekimi (K-116): ofis 2'de inşa modunu açar; duvar çizerken, kapı açarken, duvar silerken ve sonuçta
## ekranı kaydeder. Çalıştırma: godot --path . res://tools/wall_shots.tscn --resolution 1672x941 -- --out=<klasör> [--lang=en]

var _out: String = "user://wall_shots"
var _lang: String = "tr"
var _screen: Control
var _view: OfficeView


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--lang="):
			_lang = arg.trim_prefix("--lang=")
	DirAccess.make_dir_recursive_absolute(_out)
	_run.call_deferred()


func _shot(name: String) -> void:
	await get_tree().create_timer(0.8).timeout
	get_viewport().get_texture().get_image().save_png(_out.path_join(name + ".png"))


## Dünya noktasının (metre) ekrandaki yeri; önizlemeyi farenin oradaymış gibi göstermek için.
func _screen_of(p: Vector2) -> Vector2:
	var cam: Camera3D = _view.world.rig.camera
	var vp: SubViewport = _view.get_child(0) as SubViewport
	return cam.unproject_position(Vector3(p.x, 0.0, p.y)) * (_view.size / Vector2(vp.size))


func _run() -> void:
	Settings.persist = false
	Clock.playtime.persist = false
	Settings.set_value("tutorial", false)
	Settings.set_value("autosave", false)
	TranslationServer.set_locale(_lang)
	GameState.new_game(7, "marketing_manager", 0, "", {"name": "Defne", "avatar": "kadin_02"})
	var sim: Simulation = GameState.sim
	sim.state.office_level = 2
	sim.state.cash = 500000.0
	sim.build.refresh(sim.state)
	_screen = load("res://src/ui/screens/main.tscn").instantiate()
	add_child(_screen)
	await get_tree().create_timer(1.0).timeout
	_screen.call("enter_build_mode")
	await get_tree().process_frame
	_view = _screen.get("_office")
	var bar: BuildToolbar = _screen.get("_build_bar")
	bar.call("_fill_palette", "walls")
	bar.call("_select", {"kind": "wall", "id": "wall"})
	# Kamera biraz aşağı-sağa: toplantı odası ve mutfak araç çubuğunun üstünde kalsın.
	_view.world.rig.pan(Vector2(2.0, 3.0))
	await get_tree().create_timer(1.0).timeout
	# Toplantı odasının içinde bölme duvarı çizilirken.
	_view.set("_room_start", Vector2(13.0, 0.0))
	_view.call("_build_hover", _screen_of(Vector2(13.0, 2.5)))
	await _shot("1_wall_drag")
	_view.call("_build_click", _release(Vector2(13.0, 2.5)))
	await _shot("2_wall_built")
	bar.call("_select", {"kind": "door", "id": "door"})
	_view.call("_build_hover", _screen_of(Vector2(9.0, 4.2)))
	await _shot("3_door_hover")
	GameState.execute(BuildDoorCommand.new(Vector2(9.0, 4.2)))
	bar.call("_select", {"kind": "remove"})
	_view.call("_build_hover", _screen_of(Vector2(11.5, 5.0)))
	await _shot("4_remove_hover")
	GameState.execute(RemoveWallCommand.new(Vector2(11.5, 5.0)))
	_view.call("_build_hover", _screen_of(Vector2(4.0, 4.0)))
	await _shot("5_result")
	print("Duvar çekimleri: %s" % _out)
	get_tree().quit()


func _release(p: Vector2) -> InputEventMouseButton:
	var mb: InputEventMouseButton = InputEventMouseButton.new()
	mb.button_index = MOUSE_BUTTON_LEFT
	mb.pressed = false
	mb.position = _screen_of(p)
	return mb
