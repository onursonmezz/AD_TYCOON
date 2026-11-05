extends Node3D
## Karakter hareket sayfası (C2): her klibi masa ve sandalyeyle önden ve yandan çeker, iki özet sayfa yazar.
## godot --path . res://tools/pose_sheet.tscn --resolution 640x480 -- --out=<klasör>
func _ready() -> void:
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
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-50.0, 150.0, 0.0)
	add_child(sun)
	OfficeDressing.box(self, Vector3(0, -0.05, 0), Vector3(12, 0.1, 12), Color(0.8, 0.7, 0.55))
	var out: String = "user://pose_sheet"
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
	DirAccess.make_dir_recursive_absolute(out)
	var seated: Array[String] = ["sit", "type", "phone", "present", "cheer", "stress", "sleep"]
	for clip: String in ["idle", "walk", "sit", "type", "phone", "coffee", "present", "cheer", "cheer_stand", "stress", "sleep"]:
		var stage: Node3D = Node3D.new()
		add_child(stage)
		var look: Dictionary = CharacterLook.make(DataDB.data, {"id": "em_0004", "gender": "male"}, 1995)
		var rig: CharacterRig = CharacterRig.new()
		stage.add_child(rig)
		rig.build(look, false)
		rig.set_activity(clip)
		if seated.has(clip):
			var desk: Node3D = ModelLibrary.instance("props/desk.glb", Vector2(1.4, 0.7), 0.75)
			desk.position = Vector3(0, 0, -0.8)
			stage.add_child(desk)
			var chair: Node3D = ModelLibrary.instance("props/chair.glb", Vector2(0.5, 0.5), 0.9, 180.0)
			chair.position = Vector3(0, 0, -0.1)
			stage.add_child(chair)
			var pc: Node3D = ModelLibrary.instance("equipment/pc386.glb", Vector2(0.45, 0.4), 0.32)
			if pc != null:
				pc.position = Vector3(0, 0.75, -0.85)
				stage.add_child(pc)
		var cam: Camera3D = Camera3D.new()
		stage.add_child(cam)
		cam.position = Vector3(1.5, 1.9, -1.9)
		cam.look_at(Vector3(0, 0.85, -0.25))
		cam.fov = 45
		cam.current = true
		await get_tree().create_timer(0.75).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out.path_join(clip + ".png"))
		cam.position = Vector3(-1.9, 1.3, 0.2)
		cam.look_at(Vector3(0, 0.85, -0.3))
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out.path_join(clip + "_side.png"))
		stage.queue_free()
	for suffix: String in ["", "_side"]:
		var sheet: Image = Image.create(1280, 720, false, Image.FORMAT_RGBA8)
		var i: int = 0
		for clip: String in ["idle", "walk", "sit", "type", "phone", "coffee", "present", "cheer", "cheer_stand", "stress", "sleep"]:
			var img: Image = Image.load_from_file(out.path_join(clip + suffix + ".png"))
			img.convert(Image.FORMAT_RGBA8)
			img.resize(320, 240)
			sheet.blit_rect(img, Rect2i(0, 0, 320, 240), Vector2i((i % 4) * 320, (i / 4) * 240))
			i += 1
		sheet.save_png(out.path_join("sheet" + suffix + ".png"))
	get_tree().quit()
