class_name MeshBounds
extends RefCounted
## Mesh ölçümü (G3): bağımlılıksız; ModelLibrary ve model denetimi (tools/model_checker.gd, --script modunda autoload yok) kullanır.


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

