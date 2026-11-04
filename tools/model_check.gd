extends SceneTree
## Model kontrol aracı (M8, art/pipeline.md 5. adım). Her model yuvasını tek tek raporlar.
## Çalıştırma: godot --headless --script res://tools/model_check.gd
## Yeni .glb ekledikten sonra Godot editörünü bir kez açıp kapat (ya da godot --headless --import) ki içe aktarılsın.

const Checker: GDScript = preload("res://tools/model_checker.gd")


func _init() -> void:
	var data: GameData = GameData.load_from()
	if not data.errors.is_empty():
		printerr("Veri hatalı; önce validate_data.gd")
		quit(1)
		return
	var root: String = str(data.models["root"])
	var found: int = 0
	var ok: int = 0
	print("=== Model kontrolü (%s) ===" % root)
	for slot: Dictionary in Checker.slots(data):
		var path: String = root + str(slot["rel"])
		if not ResourceLoader.exists(path):
			print("  ·  %-28s %s — yok (oyunda gri kutu)" % [slot["name"], slot["rel"]])
			continue
		found += 1
		var packed: PackedScene = load(path) as PackedScene
		var node: Node3D = packed.instantiate() as Node3D if packed != null else null
		if node == null:
			print("  ✗  %-28s %s — açılamadı (dosya bozuk ya da .glb değil)" % [slot["name"], slot["rel"]])
			continue
		var warn: PackedStringArray = Checker.inspect(node, slot, data.models["limits"])
		node.free()
		if warn.is_empty():
			ok += 1
			print("  ✓  %-28s %s" % [slot["name"], slot["rel"]])
		else:
			print("  ⚠  %-28s %s" % [slot["name"], slot["rel"]])
			for w: String in warn:
				print("        - " + w)
	for f: String in Checker.unknown_files(data, root):
		print("  ?  %s — hiçbir eşya bu adı beklemiyor (ad ya da klasör yanlış olabilir, art/prompts/items.md)" % f)
	print("Toplam: %d yuva, %d model bulundu, %d sorunsuz." % [Checker.slots(data).size(), found, ok])
	quit(0)
