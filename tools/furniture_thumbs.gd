extends Node3D
## Eşya küçük resimleri (UI-4): ui_layout.json "furniture_art" eşlemesi olmayan eşyaların 3D modelini saydam zeminde
## 3/4 açıdan çizer → assets/ui/thumbs/<id>.png. İnşa paletinde resim yoksa bunlar kullanılır (yoksa ikon).
## Çalıştırma: godot --path . res://tools/furniture_thumbs.tscn [-- --all]   (--all: eşlemesi olanlar da)

const OUT: String = "res://assets/ui/thumbs"
const SIZE: int = 256


func _ready() -> void:
	var all: bool = OS.get_cmdline_user_args().has("--all")
	get_viewport().transparent_bg = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.light_energy = 1.2
	sun.rotation_degrees = Vector3(-45.0, 35.0, 0.0)
	add_child(sun)
	var env: WorldEnvironment = WorldEnvironment.new()
	var e: Environment = Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(1.0, 0.95, 0.88)
	e.ambient_light_energy = 0.7
	env.environment = e
	add_child(env)
	var art: Dictionary = DataDB.data.raw["ui_layout.json"]["furniture_art"]
	var made: int = 0
	for id: String in DataDB.data.furniture:
		var def: Dictionary = DataDB.data.furniture[id]
		var rel: String = str(def.get("model", ""))
		if rel.is_empty() or not ModelLibrary.exists(rel) or (art.has(id) and not all):
			continue
		var stage: Node3D = Node3D.new()
		add_child(stage)
		var fp: Vector2 = Vector2(float(def["size"][0]), float(def["size"][1]))
		var h: float = float(def["height"])
		stage.add_child(ModelLibrary.instance(rel, fp, h))
		var span: float = maxf(maxf(fp.x, fp.y), h)
		var cam: Camera3D = Camera3D.new()
		cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		cam.size = span * 1.45
		stage.add_child(cam)
		cam.position = Vector3(span * 2.0, h * 0.5 + span * 1.4, span * 2.0)
		cam.look_at(Vector3(0, h * 0.5, 0))
		cam.current = true
		for i: int in 3:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var img: Image = get_viewport().get_texture().get_image()
		var side: int = mini(img.get_width(), img.get_height())
		img = img.get_region(Rect2i((img.get_width() - side) / 2, (img.get_height() - side) / 2, side, side))
		img.resize(SIZE, SIZE, Image.INTERPOLATE_LANCZOS)
		img.save_png(ProjectSettings.globalize_path(OUT.path_join(id + ".png")))
		stage.queue_free()
		made += 1
	print("Eşya küçük resimleri: %d → %s" % [made, OUT])
	get_tree().quit()
