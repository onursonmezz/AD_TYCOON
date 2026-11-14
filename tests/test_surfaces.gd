extends GutTest
## T1: görsel AI dokuları (assets/textures/surfaces, data/look.json): look.json'da adı geçen her dokunun dosyası var
## ve dokulu malzeme dünya koordinatında döşenir.


func _entries() -> Array[Dictionary]:
	var c: Dictionary = WorldLook.cfg()
	var out: Array[Dictionary] = [c["ground"]]
	for e: Dictionary in c["floors"].values():
		out.append(e)
	for e: Dictionary in c.get("wallpapers", {}).values():
		out.append(e)
	for e: Dictionary in c.get("street", {}).values():
		out.append(e)
	return out


func test_every_named_texture_exists() -> void:
	var named: int = 0
	for e: Dictionary in _entries():
		if e.has("texture"):
			named += 1
			assert_true(WorldLook.has_surface(e), "%s dosyası var" % e["texture"])
	assert_gt(named, 10, "zemin, duvar, çimen ve sokak dokuları tanımlı")


func test_surface_material_tiles_in_world_space() -> void:
	var mat: StandardMaterial3D = WorldLook.surface_material({"texture": "floor_planks", "tile": 2.0})
	assert_not_null(mat.albedo_texture)
	assert_true(mat.uv1_world_triplanar)
	assert_almost_eq(mat.uv1_scale.x, 0.5, 0.001, "2 m'de bir tekrar")


func test_surface_texture_has_mipmaps() -> void:
	var mat: StandardMaterial3D = WorldLook.surface_material({"texture": "wall_leaves", "tile": 2.0})
	assert_true(mat.albedo_texture.get_image().has_mipmaps(), "uzaktan kumlanmasın diye mipmap üretilir")


func test_quality_levels_are_complete() -> void:
	var q: Dictionary = WorldLook.cfg()["quality"]
	assert_true((q["levels"] as Dictionary).has(str(q["default"])), "varsayılan kademe tanımlı")
	assert_eq(str(Settings.DEFAULTS[WorldQuality.SETTING]), str(q["default"]))
	for id: String in WorldQuality.ids():
		var l: Dictionary = q["levels"][id]
		for key: String in ["msaa", "screen_aa", "scale", "debanding", "ssao", "ssil", "glow", "dof"]:
			assert_true(l.has(key), "%s.%s" % [id, key])
		assert_true(WorldQuality.MSAA.has(int(l["msaa"])), "%s msaa" % id)
		assert_true(WorldQuality.SCREEN_AA.has(str(l["screen_aa"])), "%s screen_aa" % id)
