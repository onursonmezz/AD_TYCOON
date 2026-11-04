extends GutTest
## M8-A: model kaydı ve yedek (gri kutu), model denetimi, kampanya görselleri (GDD 21.3–21.4).

const Checker: GDScript = preload("res://tools/model_checker.gd")
const Samples: GDScript = preload("res://tools/sample_models.gd")
const ChecksM8: GDScript = preload("res://tools/data_checks_m8.gd")

var data: GameData
var samples: Dictionary


func before_all() -> void:
	data = GameData.load_from()
	samples = Samples.make_all("user://test_sample_models")


func after_each() -> void:
	ModelLibrary.overrides = {}
	ModelLibrary.clear_cache()


func test_missing_model_falls_back_to_box() -> void:
	assert_false(ModelLibrary.exists("props/counter.glb"), "depoda henüz model yok")
	assert_null(ModelLibrary.instance("props/counter.glb", Vector2(3.0, 0.6), 0.95))
	var parent: Node3D = autofree(Node3D.new())
	var t: Dictionary = OfficeDressing.thing(parent, "props/counter.glb", Vector2(2, 3), Vector2(1.4, 0.7), 0.75, Color.RED)
	assert_false(bool(t["model"]))
	assert_true(t["node"] is MeshInstance3D, "gri kutu")


func test_model_is_fitted_to_footprint_and_grounded() -> void:
	ModelLibrary.overrides = samples
	assert_true(ModelLibrary.exists("props/desk.glb"))
	var m: Node3D = autofree(ModelLibrary.instance("props/desk.glb", Vector2(1.4, 0.7), 0.75))
	assert_not_null(m)
	var box: AABB = ModelLibrary.bounds(m)
	assert_lte(box.size.x, 1.4 + 0.001, "santimetre ölçeğindeki masa 1.4 m'ye sığar")
	assert_lte(box.size.z, 0.7 + 0.001)
	assert_lte(box.size.y, 0.75 + 0.001)
	assert_almost_eq(box.size.x, 1.4, 0.02, "en dar sınıra kadar büyür")
	assert_almost_eq(box.position.y, 0.0, 0.001, "taban yerde")
	assert_almost_eq(box.position.x + box.size.x * 0.5, 0.0, 0.001, "ortada")
	assert_almost_eq(box.position.z + box.size.z * 0.5, 0.0, 0.001)


func test_checker_reports_problems() -> void:
	var limits: Dictionary = data.models["limits"]
	var slot: Dictionary = {"name": "t", "rel": "x", "size": Vector2(0.5, 0.5), "height": 0.9}
	var chair: Node3D = autofree((load(samples["props/chair.glb"]) as PackedScene).instantiate())
	assert_eq(Checker.inspect(chair, slot, limits), PackedStringArray(), "deneme sandalyesi kurallara uyuyor")
	var desk: Node3D = autofree((load(samples["props/desk.glb"]) as PackedScene).instantiate())
	var warn: PackedStringArray = Checker.inspect(desk, {"name": "d", "rel": "x", "size": Vector2(1.4, 0.7), "height": 0.75}, limits)
	assert_eq(warn.size(), 2, "santimetre masası: boy yanlış ve ortada değil (%s)" % ", ".join(warn))
	var floating: Node3D = autofree((load(samples["props/chair.glb"]) as PackedScene).instantiate())
	for c: Node in floating.get_children():
		(c as Node3D).position.y += 0.5
	assert_true(", ".join(Checker.inspect(floating, slot, limits)).contains("taban yerde değil"))


func test_every_slot_has_a_valid_path_and_unknown_files_are_listed() -> void:
	var slots: Array[Dictionary] = Checker.slots(data)
	assert_eq(slots.size(), data.furniture_ids.size() + 5 + data.hardware_ids.size() + 4 + 3 + 3 + 9 + 12, "eşyalar + 3 duvar süsü + 3 gövde, 9 saç, 12 kıyafet")
	var bad: Dictionary = data.raw.duplicate(true)
	bad["furniture.json"][0]["model"] = "Bitki Büyük.glb"
	assert_eq(ChecksM8.check(data.raw), PackedStringArray())
	assert_eq(ChecksM8.check(bad).size(), 1, "yanlış model adı yakalanır")
	DirAccess.make_dir_recursive_absolute("user://fake_models/props")
	FileAccess.open("user://fake_models/props/masa.glb", FileAccess.WRITE).store_string("x")
	assert_eq(Checker.unknown_files(data, "user://fake_models/"), PackedStringArray(["props/masa.glb"]))


func test_key_visual_is_stable_and_awards_come_first() -> void:
	var sim: Simulation = Simulation.new(data, 4)
	var mk: Callable = func(id: String, score: float) -> Dictionary:
		return {"id": id, "setup": {"client_name": "Pusula", "name": "Yaz " + id, "sector": data.sector_ids[0]},
			"report": {"score": score}}
	sim.state.finished.assign([mk.call("c1", 6.0), mk.call("c2", 9.0), mk.call("c3", 7.0)])
	sim.state.award_history.append({"campaign": "c1", "level": "bronze"})
	var posters: Array[Dictionary] = KeyVisual.poster_campaigns(sim.state, 2)
	assert_eq([posters[0]["id"], posters[1]["id"]], ["c1", "c2"], "ödüllü önce, sonra puan")
	var a: Dictionary = KeyVisual.spec(data, posters[0], KeyVisual.awarded_campaigns(sim.state))
	var b: Dictionary = KeyVisual.spec(data, posters[0], KeyVisual.awarded_campaigns(sim.state))
	assert_eq(a, b, "aynı kampanya hep aynı görsel")
	assert_eq(a["award"], "bronze")
	assert_eq(a["brand"], "Pusula")
	assert_ne(TranslationServer.translate(a["slogan_key"]), a["slogan_key"], "slogan çevrili")
	assert_eq(KeyVisual.billboard_campaign(sim.state)["id"], "c3", "yayında iş yoksa en son biten")
	assert_true(bool(KeyVisual.spec(data, {})["empty"]))
	for i: int in int(data.models["key_visual"]["slogans"]):
		assert_ne(TranslationServer.translate("KV_SLOGAN_%d" % (i + 1)), "KV_SLOGAN_%d" % (i + 1))


func test_office_dressing_builds_street_billboard_and_posters() -> void:
	GameState.new_game(8)
	var sim: Simulation = GameState.sim
	sim.state.office_level = 2
	sim.build.refresh(sim.state)
	var world: OfficeWorld = OfficeWorld.new()
	add_child_autofree(world)
	await wait_physics_frames(2)
	var quads: Array[Node] = world.find_children("*", "MeshInstance3D", true, false).filter(
		func(n: Node) -> bool: return (n as MeshInstance3D).mesh is QuadMesh)
	assert_eq(quads.size(), 1, "posterler yok (biten iş yok), billboard'da 'kiralık alan'")
	sim.state.finished.append({"id": "k1", "setup": {"client_name": "Mavi", "name": "Kış", "sector": data.sector_ids[0]},
		"report": {"score": 8.0}})
	world.sync()
	await wait_physics_frames(2)
	quads = world.find_children("*", "MeshInstance3D", true, false).filter(
		func(n: Node) -> bool: return (n as MeshInstance3D).mesh is QuadMesh and n.is_inside_tree() and not n.is_queued_for_deletion())
	assert_eq(quads.size(), 2, "billboard + 1 poster")
	GameState.end_game()


func test_blender_models_pass_the_checker() -> void:
	# G3: tools/blender ile üretilen modeller depoda; hepsi ölçü, taban ve üçgen sınırına uymalı.
	var limits: Dictionary = data.models["limits"]
	for slot: Dictionary in Checker.slots(data):
		if not str(slot["rel"]) in ["props/desk.glb", "furniture/bookshelf.glb", "furniture/plant_small.glb",
				"furniture/plant_big.glb", "decor/plant_medium.glb", "decor/hex_shelf.glb", "decor/wall_panel.glb"]:
			continue
		assert_true(ModelLibrary.exists(str(slot["rel"])), str(slot["rel"]))
		var node: Node3D = autofree(ModelLibrary.scene(str(slot["rel"])).instantiate())
		assert_eq(Checker.inspect(node, slot, limits), PackedStringArray(), str(slot["rel"]))
