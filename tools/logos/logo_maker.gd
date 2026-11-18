extends Node
## Parodi logoları PNG'ye çevirir (LG-1): her logo bir SubViewport'ta LogoCanvas ile çizilir ve
## assets/ui/icons/logo-<id>.png olarak kaydedilir; ayrıca tüm logolar yan yana sheet.png (kontrol için).
## Çalıştırma: godot --audio-driver Dummy --path . res://tools/logos/logo_maker.tscn [-- --only=pear,yourtube --sheet=<dosya>]

const LOGOS: Array[String] = ["pear", "nitrosoft_newcel", "nitrosoft_strongpoint", "nitrosoft_world", "slak", "chattnt",
	"abode_photostore", "abode_vectorator", "abode_outdesign", "abode_premium_pro", "abode_before_effects", "kamva", "digma",
	"topjourney", "theatre_4d", "tricksfield", "surveycappybara", "gooble_analytics", "tootsuite", "gooble_abs", "yourtube",
	"facenook", "tweakker", "linkedout", "instagraph", "ticktock"]
const OUT_DIR: String = "res://assets/ui/icons"
const SIZE: int = 256


func _ready() -> void:
	var only: PackedStringArray = PackedStringArray()
	var sheet_path: String = ""
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.trim_prefix("--only=").split(",")
		elif a.begins_with("--sheet="):
			sheet_path = a.trim_prefix("--sheet=")
	var made: Array[Image] = []
	for id: String in LOGOS:
		if not only.is_empty() and not only.has(id):
			continue
		var vp: SubViewport = SubViewport.new()
		vp.size = Vector2i(SIZE, SIZE)
		vp.transparent_bg = true
		vp.msaa_2d = Viewport.MSAA_8X
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		var c: LogoCanvas = LogoSocial.new()
		c.logo = id
		c.size = Vector2(SIZE, SIZE)
		vp.add_child(c)
		add_child(vp)
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var img: Image = vp.get_texture().get_image()
		img.save_png(ProjectSettings.globalize_path("%s/logo-%s.png" % [OUT_DIR, id.replace("_", "-")]))
		made.append(img)
		vp.queue_free()
		print("logo: ", id)
	if not sheet_path.is_empty() and not made.is_empty():
		var cols: int = mini(6, made.size())
		var rows: int = ceili(float(made.size()) / cols)
		var sheet: Image = Image.create(cols * SIZE, rows * SIZE, false, Image.FORMAT_RGBA8)
		sheet.fill(Color("f6efe2"))
		for i: int in made.size():
			sheet.blend_rect(made[i], Rect2i(0, 0, SIZE, SIZE), Vector2i((i % cols) * SIZE, (i / cols) * SIZE))
		sheet.save_png(sheet_path)
	get_tree().quit()
