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
