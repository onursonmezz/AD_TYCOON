class_name ModelLibrary
extends RefCounted
## 3D model kaydı (M8, GDD 21.3): data/furniture.json ve data/models.json'daki yollardan .glb yükler, modeli verilen
## tabana ve boya orantılı sığdırır (taban yerde, ortada). Dosya yoksa null döner; çağıran gri kutu çizer.
## Kural (art/style_bible.md): 1 birim = 1 m, taban Y = 0, ön yüz +Z (Blender'da −Y).

## Test ve ekran turu için: göreli yol → başka bir sahne yolu (ör. kodla üretilmiş deneme modeli).
static var overrides: Dictionary = {}
static var _cache: Dictionary = {}


static func full_path(rel: String) -> String:
	if overrides.has(rel):
		return str(overrides[rel])
	return str(DataDB.data.models.get("root", "res://assets/models/")) + rel


static func exists(rel: String) -> bool:
	return not rel.is_empty() and ResourceLoader.exists(full_path(rel))


static func scene(rel: String) -> PackedScene:
	var path: String = full_path(rel)
	if not _cache.has(path):
		_cache[path] = load(path) as PackedScene if ResourceLoader.exists(path) else null
	return _cache[path]


static func clear_cache() -> void:
	_cache.clear()


## Modeli taban (x, z) ve boy içine orantılı sığdırır; yaw derece (0 = ön yüz +Z). Model yoksa null.
static func instance(rel: String, footprint: Vector2, height: float, yaw_deg: float = 0.0) -> Node3D:
	var packed: PackedScene = scene(rel) if not rel.is_empty() else null
	if packed == null:
		return null
	var inner: Node3D = packed.instantiate() as Node3D
	if inner == null:
		return null
	var box: AABB = bounds(inner)
	var wrap: Node3D = Node3D.new()
	wrap.name = rel.get_file().get_basename()
	wrap.add_child(inner)
	if box.size.x <= 0.0001 or box.size.y <= 0.0001 or box.size.z <= 0.0001:
		return wrap
	var s: float = minf(minf(footprint.x / box.size.x, footprint.y / box.size.z), height / box.size.y)
	inner.scale = Vector3.ONE * s
	inner.position = Vector3(-(box.position.x + box.size.x * 0.5) * s, -box.position.y * s, -(box.position.z + box.size.z * 0.5) * s)
	wrap.rotation.y = deg_to_rad(yaw_deg)
	return wrap


## Sahnedeki bütün mesh'lerin, kökün kendi koordinatlarındaki birleşik kutusu (ağaçta olmasa da çalışır).
static func bounds(root: Node3D) -> AABB:
	var out: Array[AABB] = []
	_collect(root, Transform3D.IDENTITY, out, true)
	if out.is_empty():
		return AABB()
	var total: AABB = out[0]
	for i: int in range(1, out.size()):
		total = total.merge(out[i])
	return total


static func _collect(node: Node, xf: Transform3D, out: Array[AABB], is_root: bool) -> void:
	var here: Transform3D = xf
	if node is Node3D and not is_root:
		here = xf * (node as Node3D).transform
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		out.append(here * (node as MeshInstance3D).mesh.get_aabb())
	for child: Node in node.get_children():
		_collect(child, here, out, false)


static func triangle_count(root: Node) -> int:
	var n: int = 0
	for node: Node in [root] + root.find_children("*", "MeshInstance3D", true, false):
		if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
			var mesh: Mesh = (node as MeshInstance3D).mesh
			for s: int in mesh.get_surface_count():
				var arrays: Array = mesh.surface_get_arrays(s)
				var idx: Variant = arrays[Mesh.ARRAY_INDEX]
				n += (idx as PackedInt32Array).size() / 3 if idx != null else (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	return n


## Kuru bitki gibi durumlar için bütün mesh'lere yarı saydam renk katmanı.
static func tint(root: Node, color: Color) -> void:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		(node as MeshInstance3D).material_overlay = mat
