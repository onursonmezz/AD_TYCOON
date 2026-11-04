extends GutTest
## M8-B: modüler karakterler (görünüş, dönemsel kıyafet), karakter kurulumu, animasyon durumları.

const Samples: GDScript = preload("res://tools/sample_models.gd")

var data: GameData


func before_all() -> void:
	data = GameData.load_from()


func after_each() -> void:
	ModelLibrary.overrides = {}
	ModelLibrary.clear_cache()


func _emp(id: String, gender: String = "female") -> Dictionary:
	return {"id": id, "gender": gender, "is_founder": false}


func test_look_is_stable_and_follows_gender() -> void:
	var a: Dictionary = CharacterLook.make(data, _emp("em_0007"), 1995)
	assert_eq(a, CharacterLook.make(data, _emp("em_0007"), 1995), "aynı çalışan hep aynı görünür")
	assert_eq(a["body"], "female")
	assert_eq(CharacterLook.make(data, _emp("em_0007", "male"), 1995)["body"], "male")
	assert_eq(CharacterLook.make(data, _emp("em_0007", ""), 1995)["body"], "neutral", "kurucu (cinsiyetsiz) nötr gövde")
	var looks: Dictionary = {}
	for i: int in 40:
		looks[CharacterLook.signature(CharacterLook.make(data, _emp("em_%04d" % i), 2005))] = true
	assert_gt(looks.size(), 8, "çalışanlar birbirinden farklı görünür")


func test_outfits_follow_the_era() -> void:
	var outfits: Dictionary = {}
	for o: Dictionary in data.characters["outfits"]:
		outfits[o["id"]] = o
	for i: int in 30:
		for year: int in [1992, 2012, 2030]:
			var look: Dictionary = CharacterLook.make(data, _emp("em_%04d" % i, ["female", "male", "neutral"][i % 3]), year)
			var o: Dictionary = outfits[look["outfit"]]
			assert_true(int(o.get("from", 0)) <= year and year <= int(o.get("to", 9999)), "%s %d yılında giyilir" % [o["id"], year])
	var founder: Dictionary = CharacterLook.make(data, {"id": "em_0001", "gender": "", "is_founder": true}, 1990)
	assert_eq(founder["outfit_color"], CharacterLook._color(data.characters["founder_outfit_color"]))


func test_fallback_capsule_moves_by_activity() -> void:
	var rig: CharacterRig = CharacterRig.new()
	add_child_autofree(rig)
	rig.build(CharacterLook.make(data, _emp("em_0003"), 1990), true)
	assert_false(rig.has_model(), "model yokken kapsül")
	assert_false(rig.has_animations())
	rig.set_activity("cheer")
	await wait_physics_frames(10)
	var pose: Node3D = rig.get_child(0)
	assert_gt(pose.position.y, 0.0, "sevinçte zıplar")
	assert_not_null(pose.get_node_or_null("Head"))


func test_model_rig_dresses_and_animates() -> void:
	ModelLibrary.overrides = Samples.make_characters("user://test_char_samples", data)
	var rig: CharacterRig = CharacterRig.new()
	add_child_autofree(rig)
	var look: Dictionary = CharacterLook.make(data, _emp("em_0005", "male"), 2000)
	look["bald"] = false
	rig.build(look, false)
	assert_true(rig.has_model())
	assert_true(rig.has_animations(), "deneme gövdesinde klipler var")
	assert_eq(rig.clip_for("phone"), "sit", "telefon klibi yoksa oturma")
	assert_eq(rig.clip_for("present"), "idle")
	assert_eq(rig.clip_for("type"), "type")
	var hair_on_head: int = 0
	for n: Node in rig.find_children("*", "BoneAttachment3D", true, false):
		var att: BoneAttachment3D = n
		if att.bone_name == data.characters["head_bone"] and att.get_child_count() > 0 \
				and att.get_child(0).get_child_count() > 0 and att.get_child(0).get_child(0) is MeshInstance3D:
			hair_on_head += 1
	assert_eq(hair_on_head, 1, "saç başa bağlandı")
	rig.set_activity("type")
	await wait_physics_frames(30)
	assert_eq(rig.current_clip(), "type")
	var box: AABB = ModelLibrary.bounds(rig.get_child(0))
	assert_almost_eq(box.size.y, float(data.characters["height"]), 0.15, "gövde 1.7 m'ye sığdırıldı")
