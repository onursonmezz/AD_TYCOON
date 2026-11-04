extends Node3D
## Model önizleme (M8, art/pipeline.md 5. adım): bulunan her modeli oyundaki gibi sığdırıp 1 m'lik ölçü küpünün
## yanında çizer ve PNG kaydeder. Pencere açar.
## Çalıştırma: godot --path . res://tools/model_preview.tscn -- --out=art/previews [--samples]
## --samples: gerçek model yerine deneme modelleri (tools/sample_models.gd).

const Checker: GDScript = preload("res://tools/model_checker.gd")
const Samples: GDScript = preload("res://tools/sample_models.gd")

var _out: String = "res://art/previews"
var _stage: Node3D


func _ready() -> void:
	var samples: bool = false
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg == "--samples":
			samples = true
	if not _out.begins_with("res://") and not _out.begins_with("user://") and not _out.is_absolute_path():
		_out = "res://" + _out
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out))
	if samples:
		ModelLibrary.overrides = Samples.make_all("user://sample_models")
		ModelLibrary.overrides.merge(Samples.make_characters("user://sample_models", DataDB.data))
	_setup_scene()
	await _run()
	get_tree().quit()


func _setup_scene() -> void:
	var env: WorldEnvironment = WorldEnvironment.new()
	var e: Environment = Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = UiUtil.CREAM
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(1.0, 0.95, 0.88)
	e.ambient_light_energy = 0.6
	env.environment = e
	add_child(env)
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-50.0, 35.0, 0.0)
	add_child(sun)
	OfficeDressing.box(self, Vector3(0, -0.05, 0), Vector3(12, 0.1, 12), Color(0.8, 0.79, 0.76))


func _run() -> void:
	var data: GameData = DataDB.data
	var count: int = 0
	for slot: Dictionary in Checker.slots(data):
		if not ModelLibrary.exists(str(slot["rel"])):
			continue
		if _stage != null:
			_stage.queue_free()
		_stage = Node3D.new()
		add_child(_stage)
		var fp: Vector2 = slot["size"]
		var h: float = float(slot["height"])
		var model: Node3D = ModelLibrary.instance(str(slot["rel"]), fp, h)
		_stage.add_child(model)
		# Beklenen kutu (ince çerçeve yerine yarı saydam) ve 1 m'lik ölçü küpü.
		var ghost: MeshInstance3D = OfficeDressing.box(_stage, Vector3(0, h * 0.5, 0), Vector3(fp.x, h, fp.y), Color(0.3, 0.75, 0.4))
		var mat: StandardMaterial3D = ghost.material_override
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(0.3, 0.75, 0.4, 0.15)
		var span: float = maxf(maxf(fp.x, fp.y), h)
		OfficeDressing.box(_stage, Vector3(-maxf(fp.x, 1.0) * 0.5 - 0.9, 0.5, 0), Vector3.ONE, Color(0.78, 0.4, 0.29))
		var cam: Camera3D = Camera3D.new()
		_stage.add_child(cam)
		cam.position = Vector3(span * 0.9 + 0.6, span * 0.8 + 0.7, span * 1.2 + 1.6)
		cam.look_at(Vector3(-0.4, h * 0.45, 0))
		cam.current = true
		for i: int in 3:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var file: String = _out.path_join(str(slot["name"]) + ".png")
		get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(file))
		count += 1
	print("Önizleme: %d model → %s" % [count, _out])
