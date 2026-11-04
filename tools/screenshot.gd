extends Node
## Görsel karşılaştırma aracı (G1, docs/art-direction.md): sabit tohumlu örnek bir ajans kurar, ofisi ve ana ekranı
## sabit açılardan çeker, docs/screenshots/ altına kaydeder. Her görsel değişiklikten sonra çalıştırılıp
## referanslarla (C:\Users\osonm\Documents\reference) karşılaştırılır.
## Çalıştırma (pencere açılır): godot --path . res://tools/screenshot.tscn -- [--out=docs/screenshots] [--tag=ad]
##   [--samples] (deneme modelleriyle) [--level=2]

const W: int = 1920
const H: int = 1080

var _out: String = "res://docs/screenshots"
var _tag: String = ""
var _samples: bool = false
var _level: int = 2


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--tag="):
			_tag = arg.trim_prefix("--tag=") + "_"
		elif arg == "--samples":
			_samples = true
		elif arg.begins_with("--level="):
			_level = int(arg.trim_prefix("--level="))
	if not _out.begins_with("res://") and not _out.begins_with("user://") and not _out.is_absolute_path():
		_out = "res://" + _out
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out))
	get_window().size = Vector2i(W, H)
	_run.call_deferred()


func _run() -> void:
	Settings.persist = false
	Settings.set_value("tutorial", false)
	Settings.set_value("autosave", false)
	TranslationServer.set_locale("tr")
	if _samples:
		var s: GDScript = preload("res://tools/sample_models.gd")
		ModelLibrary.overrides = s.make_all("user://shot_samples")
		ModelLibrary.overrides.merge(s.make_characters("user://shot_samples", DataDB.data))
	_make_agency()
	# 1) Yalnızca dünya (referanslar gibi tam ekran 3D).
	var view: OfficeView = OfficeView.new()
	add_child(view)
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await _wait(3.0)
	await _shot("world_default")
	view.world.rig.rotate_quarter(1)
	await _wait(1.0)
	await _shot("world_rotated")
	view.world.rig.rotate_quarter(-1)
	view.world.rig.zoom(-4.0)
	await _wait(1.2)
	await _shot("world_close")
	view.queue_free()
	# 2) Ana ekran (arayüzle birlikte).
	var screen: Control = load("res://src/ui/screens/main.tscn").instantiate()
	add_child(screen)
	await _wait(3.0)
	await _shot("ui_main")
	screen.call("show_panel", "team")
	await _wait(0.6)
	await _shot("ui_panel")
	print("Ekran görüntüleri: %s" % ProjectSettings.globalize_path(_out))
	get_tree().quit()


## Sabit tohumlu örnek ajans: 2005, ofis seviyesi _level, 8 çalışan, mobilyalar, birkaç biten kampanya (posterler).
func _make_agency() -> void:
	GameState.new_game(4242, "", 2000)
	var sim: Simulation = GameState.sim
	sim.pause_on_phase = false
	sim.state.clock.week_index = 5 * sim.state.clock.weeks_per_year()
	sim.state.cash = 2.0e6
	sim.state.reputation = 30.0
	sim.state.office_level = _level
	sim.state.hardware = "g4"
	var roles: Array[String] = ["art_director", "copywriter", "account", "planner", "producer", "graphic_designer", "media_planner"]
	for i: int in roles.size():
		var p: Dictionary = sim.staff._blank(sim.state, roles[i], 3)
		p["stats"] = {"strategy": 55.0, "creative": 60.0, "technical": 50.0, "communication": 55.0, "speed": 50.0, "attention": 50.0}
		p["hidden"] = {"potential": 80.0}
		p["salary"] = 1000.0
		p["gender"] = ["female", "male", "neutral"][i % 3]
		p["name"] = "Ekip %d" % i
		sim.state.staff[p["id"]] = p
	sim.build.refresh(sim.state)
	var placed: int = 0
	for id: String in ["plant_big", "bookshelf", "whiteboard", "plant_small", "water_cooler", "mood_board", "plant_small", "record_player"]:
		for y: int in range(1, 30):
			var done: bool = false
			for x: int in range(1, 40):
				var p: Vector2 = Vector2(x * 0.5, y * 0.5)
				if sim.build.place_error(sim.state, id, p, 0).is_empty():
					PlaceFurnitureCommand.new(id, p, 0).execute(sim)
					placed += 1
					done = true
					break
			if done:
				break
	for i: int in 3:
		sim.state.finished.append({"id": "shot_%d" % i, "setup": {"client_name": ["Pusula", "Mavi Fil", "Lezzetçi"][i],
			"name": ["Yaz Serinliği", "Bir Yudum Mutluluk", "Sabah Keyfi"][i], "sector": DataDB.data.sector_ids[i]},
			"report": {"score": 8.0 - i}})
	EventBus.state_changed.emit()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(name: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var path: String = _out.path_join(_tag + name + ".png")
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
