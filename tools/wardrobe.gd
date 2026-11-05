extends Node3D
## Gardırop (C3): her kıyafeti farklı saç ve gövdeyle giydirip tek karede çeker.
## godot --path . res://tools/wardrobe.tscn --resolution 1920x1080 -- --out=<dosya.png> [--act=idle|type|walk…]
func _ready() -> void:
	var env: WorldEnvironment = WorldEnvironment.new()
	var e: Environment = Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = UiUtil.CREAM
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(1.0, 0.95, 0.88)
	e.ambient_light_energy = 0.6
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.environment = e
	add_child(env)
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-45.0, 30.0, 0.0)
	add_child(sun)
	OfficeDressing.box(self, Vector3(0, -0.05, 0), Vector3(30, 0.1, 30), Color(0.8, 0.7, 0.55))
	var ch: Dictionary = DataDB.data.characters
	var outfits: Array = ch["outfits"]
	var hairs: Array = ch["hair"]
	var colors: Array = ch["outfit_colors"]
	var act: String = "idle"
	var out: String = "user://wardrobe.png"
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--act="):
			act = a.substr(6)
		elif a.begins_with("--out="):
			out = a.substr(6)
	for i: int in outfits.size():
		var o: Dictionary = outfits[i]
		var body: String = str((o["bodies"] as Array)[i % (o["bodies"] as Array).size()])
		var h: Dictionary = hairs[i % hairs.size()]
		var look: Dictionary = CharacterLook.make(DataDB.data, {"id": "em_%04d" % i, "gender": body}, 2000)
		look["body"] = body
		for b: Dictionary in ch["bodies"]:
			if b["id"] == body:
				look["body_model"] = b["model"]
		look["outfit_model"] = o["model"]
		look["hair_model"] = h["model"]
		look["bald"] = str(h["model"]).is_empty()
		var c: Array = colors[i % colors.size()]
		look["outfit_color"] = Color(c[0], c[1], c[2])
		var rig: CharacterRig = CharacterRig.new()
		add_child(rig)
		rig.position = Vector3(-2.75 + (i % 6) * 1.1, 0, -1.6 * (i / 6))
		rig.rotation.y = PI
		rig.build(look, false)
		rig.set_activity(act)
		var l: Label3D = Label3D.new()
		l.text = "%s
%s" % [o["id"], h["id"]]
		l.font_size = 16
		l.position = Vector3(0, 2.0, 0)
		l.modulate = Color.BLACK
		rig.add_child(l)
		l.rotation.y = PI
	var cam: Camera3D = Camera3D.new()
	add_child(cam)
	cam.position = Vector3(0, 2.4, 4.3)
	cam.look_at(Vector3(0, 0.9, -0.8))
	cam.fov = 55
	await get_tree().create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out)
	get_tree().quit()
