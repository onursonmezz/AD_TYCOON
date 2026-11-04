extends RefCounted
## Model denetimi (M8, art/pipeline.md 5. adım): her model yuvası için dosya var mı, boy ve taban beklenene yakın mı,
## taban yerde ve ortada mı, üçgen sayısı sınırda mı. tools/model_check.gd ve testler kullanır.


## Oyunun model bekledigi bütün yuvalar: { name, rel, size (taban), height }.
static func slots(data: GameData) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id: String in data.furniture_ids:
		var f: Dictionary = data.furniture[id]
		out.append({"name": "furniture." + id, "rel": str(f["model"]),
			"size": Vector2(float(f["size"][0]), float(f["size"][1])), "height": float(f["height"])})
	for group: String in ["props", "equipment", "street"]:
		var g: Dictionary = data.models[group]
		for id: String in g:
			out.append({"name": "%s.%s" % [group, id], "rel": str(g[id]["model"]),
				"size": Vector2(float(g[id]["size"][0]), float(g[id]["size"][1])), "height": float(g[id]["height"])})
	return out


## Modelin uyarıları (boş = sorun yok). limits: data/models.json "limits".
static func inspect(root: Node3D, slot: Dictionary, limits: Dictionary) -> PackedStringArray:
	var warn: PackedStringArray = PackedStringArray()
	var box: AABB = ModelLibrary.bounds(root)
	if box.size.length() < 0.0001:
		warn.append("içinde görünür mesh yok")
		return warn
	var tol: float = float(limits["size_tolerance"])
	var h: float = float(slot["height"])
	if absf(box.size.y - h) / h > tol:
		warn.append("boy %.2f m, beklenen %.2f m (oyun orantılı küçültür/büyütür ama oranlar değişebilir)" % [box.size.y, h])
	var fp: Vector2 = slot["size"]
	var ratio_model: float = box.size.x / maxf(0.001, box.size.z)
	var ratio_slot: float = fp.x / maxf(0.001, fp.y)
	if absf(ratio_model - ratio_slot) / ratio_slot > tol * 2.0:
		warn.append("taban oranı %.2f × %.2f, beklenen %.2f × %.2f (yan dönmüş olabilir: Numpad 1'de önden bak)"
			% [box.size.x, box.size.z, fp.x, fp.y])
	var ctol: float = float(limits["center_tolerance"])
	if absf(box.position.y) > ctol:
		warn.append("taban yerde değil (en alt nokta Y = %.2f): 3. adım, taban yerde" % box.position.y)
	var cx: float = box.position.x + box.size.x * 0.5
	var cz: float = box.position.z + box.size.z * 0.5
	if absf(cx) > ctol or absf(cz) > ctol:
		warn.append("ortada değil (merkez %.2f, %.2f): Location 0, 0, 0 ve Origin to 3D Cursor" % [cx, cz])
	var limit: int = int(limits["triangles_big"] if h >= float(limits["big_from_height"]) else limits["triangles_small"])
	var tris: int = ModelLibrary.triangle_count(root)
	if tris > limit:
		warn.append("%d üçgen, sınır %d: Decimate ile azalt" % [tris, limit])
	return warn


## assets/models altındaki, hiçbir yuvanın beklemediği .glb dosyaları (yanlış ad ya da klasör).
static func unknown_files(data: GameData, root_dir: String) -> PackedStringArray:
	var expected: Dictionary = {}
	for s: Dictionary in slots(data):
		expected[s["rel"]] = true
	var out: PackedStringArray = PackedStringArray()
	_scan(root_dir, "", expected, out)
	return out


static func _scan(root_dir: String, rel: String, expected: Dictionary, out: PackedStringArray) -> void:
	var dir: DirAccess = DirAccess.open(root_dir.path_join(rel))
	if dir == null:
		return
	for sub: String in dir.get_directories():
		_scan(root_dir, rel.path_join(sub) if not rel.is_empty() else sub, expected, out)
	for f: String in dir.get_files():
		if f.get_extension() == "glb":
			var key: String = rel.path_join(f) if not rel.is_empty() else f
			if not expected.has(key):
				out.append(key)
