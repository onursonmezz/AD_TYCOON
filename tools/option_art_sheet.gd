extends Control
## Kampanya seçeneği çizimlerinin (OptionArt, S2) tek sayfada önizlemesi.
## Çalıştırma: godot --audio-driver Dummy --path . res://tools/option_art_sheet.tscn --resolution 1280x900 -- --out=<dosya.png>

const CELL: Vector2 = Vector2(128, 104)


func _ready() -> void:
	var out: String = "user://option_art_sheet.png"
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
	var bg: ColorRect = ColorRect.new()
	bg.color = Color("f6efe2")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var items: Array = _items()
	var cols: int = int(get_viewport_rect().size.x / CELL.x)
	for i: int in items.size():
		var pos: Vector2 = Vector2((i % cols) * CELL.x, (i / cols) * CELL.y)
		var art: OptionArt = OptionArtMedia.new(str(items[i][0]), str(items[i][1]))
		art.position = pos + Vector2(4, 4)
		art.size = Vector2(120, 84)
		add_child(art)
		var l: Label = Label.new()
		l.text = "%s/%s" % [items[i][0], items[i][1]]
		l.add_theme_font_size_override("font_size", 9)
		l.add_theme_color_override("font_color", Color("4a3b2c"))
		l.position = pos + Vector2(4, 86)
		add_child(l)
	for i: int in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out)
	get_tree().quit()


func _items() -> Array:
	var data: GameData = DataDB.data
	var out: Array = []
	for id: String in data.print_products.keys():
		out.append(["product", id])
	for q: String in ["economy", "standard", "premium"]:
		out.append(["quality", q])
	for id: String in data.distributions.keys():
		out.append(["distribution", id])
	for id: String in data.supplier_ids:
		out.append(["supplier", id])
	var cats: Dictionary = data.raw["channel_options.json"]["categories"]
	for cat: String in cats.keys():
		for def: Dictionary in (cats[cat] as Dictionary).get("options", []):
			for c: Dictionary in def["choices"]:
				out.append(["%s_%s" % [cat, def["id"]], str(c["id"])])
	out.append(["influencer", "@kaan55"])
	return out
