extends Control
## Mini oyun önizlemesi (K-120): her mini oyunu oynanırken çeker, PNG kaydeder.
## Çalıştırma: godot --path . res://tools/minigame_preview.tscn -- --out=<klasör>

const GAMES: Array[String] = ["radio_wave", "billboard", "newspaper", "draft",
	"draft:gaming_entertainment", "draft:health_pharma", "draft:automotive", "draft:banking_finance", "draft:crypto_fintech"]


func _ready() -> void:
	Settings.persist = false
	Clock.playtime.persist = false
	var out: String = "user://minigame_preview"
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	for n: String in DraftArt.names("backgrounds"):
		print("%s parlaklık %.2f" % [n, DraftArt.luminance(n)])
	var bg: ColorRect = ColorRect.new()
	bg.color = CozyTheme.CREAM
	bg.size = Vector2(760, 470)
	add_child(bg)
	var camp: Dictionary = {"id": "cmp_onizleme", "setup": {"sector": "fast_food", "client_name": "Lezzetçi Köfte",
		"client_id": "cl_onizleme", "mix": [{"channel": "newspaper", "share": 1.0}], "objective": "awareness"}}
	for entry: String in GAMES:
		var id: String = entry.get_slice(":", 0)
		var sector: String = entry.get_slice(":", 1) if entry.contains(":") else "fast_food"
		camp["setup"]["sector"] = sector
		var game: MinigameGame = MinigameHost._make(id)
		game.ctx = {"camp": camp, "setup": camp["setup"], "brand": "Lezzetçi Köfte",
			"accent": KeyVisual.spec(DataDB.data, camp)["accent"], "year": 1995, "seed": 7}
		game.position = Vector2(60, 60)
		add_child(game)
		game.begin()
		var title: Label = UiUtil.label(tr("MG_%s_NAME" % id.to_upper()) + " · " + tr("MG_%s_HINT" % id.to_upper()), 14, CozyTheme.TEXT)
		title.position = Vector2(60, 20)
		add_child(title)
		await get_tree().create_timer(1.0).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out.path_join(entry.replace(":", "_") + ".png"))
		game.queue_free()
		title.queue_free()
		await get_tree().process_frame
	get_tree().quit()
