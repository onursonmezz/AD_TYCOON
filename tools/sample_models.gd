extends RefCounted
## Deneme modelleri (M8): gerçek .glb gelene kadar model sisteminin çalıştığını göstermek için Godot şekilleriyle
## kurulmuş küçük sahneler. Bilerek yanlış ölçekte (santimetre) ve kaydırılmış kurulur; ModelLibrary'nin
## onları tabana ve boya doğru sığdırdığı test edilir. Oyuna girmez; testler ve ekran turu kullanır.


## Sahneleri dir'e kaydeder ve ModelLibrary.overrides için { göreli yol: sahne yolu } döner.
static func make_all(dir: String) -> Dictionary:
	DirAccess.make_dir_recursive_absolute(dir)
	var out: Dictionary = {}
	var recipes: Dictionary = {
		"props/desk.glb": _desk(),
		"props/chair.glb": _chair(),
		"furniture/plant_big.glb": _plant(),
		"equipment/pc386.glb": _crt(),
		"street/tree.glb": _tree(),
	}
	for rel: String in recipes:
		var path: String = dir.path_join(rel.get_file().get_basename() + ".tscn")
		var packed: PackedScene = PackedScene.new()
		packed.pack(recipes[rel])
		ResourceSaver.save(packed, path)
		(recipes[rel] as Node).free()
		out[rel] = path
	return out


## Kök + parçalar; her parça sahibine bağlanır ki kaydedilsin. scale: 100 = santimetre (yanlış ölçek denemesi).
static func _root(offset: Vector3) -> Node3D:
	var r: Node3D = Node3D.new()
	r.name = "Sample"
	r.position = offset
	return r


static func _part(root: Node3D, mesh: Mesh, pos: Vector3, color: Color) -> void:
	var m: MeshInstance3D = MeshInstance3D.new()
	m.mesh = mesh
	m.position = pos
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	m.material_override = mat
	root.add_child(m)
	m.owner = root


static func _boxm(x: float, y: float, z: float) -> BoxMesh:
	var b: BoxMesh = BoxMesh.new()
	b.size = Vector3(x, y, z)
	return b


static func _desk() -> Node3D:
	# Santimetre ölçeğinde (140 × 75 × 70) ve merkezden kaymış.
	var r: Node3D = _root(Vector3.ZERO)
	var wood: Color = Color(0.65, 0.49, 0.32)
	_part(r, _boxm(140, 5, 70), Vector3(50, 72.5, 20), wood)
	for x: float in [-62.0, 62.0]:
		for z: float in [-28.0, 28.0]:
			_part(r, _boxm(6, 70, 6), Vector3(50 + x, 35, 20 + z), wood.darkened(0.2))
	_part(r, _boxm(40, 20, 60), Vector3(50 + 40, 55, 20), wood.lightened(0.1))
	return r


static func _chair() -> Node3D:
	var r: Node3D = _root(Vector3.ZERO)
	var green: Color = Color(0.36, 0.5, 0.4)
	_part(r, _boxm(0.48, 0.08, 0.46), Vector3(0, 0.46, 0), green)
	_part(r, _boxm(0.48, 0.45, 0.07), Vector3(0, 0.72, 0.2), green)
	var stem: CylinderMesh = CylinderMesh.new()
	stem.top_radius = 0.03
	stem.bottom_radius = 0.03
	stem.height = 0.4
	_part(r, stem, Vector3(0, 0.22, 0), Color(0.25, 0.25, 0.28))
	_part(r, _boxm(0.5, 0.04, 0.5), Vector3(0, 0.02, 0), Color(0.25, 0.25, 0.28))
	return r


static func _plant() -> Node3D:
	var r: Node3D = _root(Vector3.ZERO)
	var pot: CylinderMesh = CylinderMesh.new()
	pot.top_radius = 0.3
	pot.bottom_radius = 0.22
	pot.height = 0.45
	_part(r, pot, Vector3(0, 0.225, 0), Color(0.78, 0.4, 0.29))
	for i: int in 5:
		var leaf: SphereMesh = SphereMesh.new()
		leaf.radius = 0.28
		leaf.height = 0.5
		var a: float = TAU * i / 5.0
		_part(r, leaf, Vector3(cos(a) * 0.18, 0.75 + 0.15 * (i % 2), sin(a) * 0.18), Color(0.3, 0.5, 0.32))
	var top: SphereMesh = SphereMesh.new()
	top.radius = 0.3
	top.height = 0.55
	_part(r, top, Vector3(0, 1.3, 0), Color(0.36, 0.55, 0.36))
	return r


static func _crt() -> Node3D:
	var r: Node3D = _root(Vector3.ZERO)
	var beige: Color = Color(0.86, 0.82, 0.7)
	_part(r, _boxm(0.38, 0.32, 0.36), Vector3(0, 0.24, -0.02), beige)
	_part(r, _boxm(0.3, 0.22, 0.02), Vector3(0, 0.25, 0.17), Color(0.2, 0.3, 0.28))
	_part(r, _boxm(0.42, 0.03, 0.14), Vector3(0, 0.015, 0.16), beige.darkened(0.1))
	_part(r, _boxm(0.2, 0.08, 0.2), Vector3(0, 0.04, -0.02), beige.darkened(0.15))
	return r


static func _tree() -> Node3D:
	var r: Node3D = _root(Vector3.ZERO)
	var trunk: CylinderMesh = CylinderMesh.new()
	trunk.top_radius = 0.1
	trunk.bottom_radius = 0.14
	trunk.height = 1.6
	_part(r, trunk, Vector3(0, 0.8, 0), Color(0.45, 0.33, 0.22))
	var crown: SphereMesh = SphereMesh.new()
	crown.radius = 0.6
	crown.height = 1.4
	_part(r, crown, Vector3(0, 2.3, 0), Color(0.36, 0.55, 0.36))
	return r


## Karakter deneme parçaları (M8-B): iskeletli ve animasyonlu bir gövde, sert bir saç, bir yelek. Bütün gövde,
## saç ve kıyafet yuvaları bu üçüne yönlendirilir. Kemik adları Mixamo'daki gibi (data/characters.json head_bone).
static func make_characters(dir: String, data: GameData) -> Dictionary:
	DirAccess.make_dir_recursive_absolute(dir)
	var paths: Dictionary = {}
	for pair: Array in [["body", _body()], ["hair", _hair()], ["outfit", _vest()]]:
		var packed: PackedScene = PackedScene.new()
		packed.pack(pair[1])
		var path: String = dir.path_join("sample_%s.tscn" % pair[0])
		ResourceSaver.save(packed, path)
		(pair[1] as Node).free()
		paths[pair[0]] = path
	var out: Dictionary = {}
	for b: Dictionary in data.characters["bodies"]:
		out[b["model"]] = paths["body"]
	for h: Dictionary in data.characters["hair"]:
		if not str(h["model"]).is_empty():
			out[h["model"]] = paths["hair"]
	for o: Dictionary in data.characters["outfits"]:
		out[o["model"]] = paths["outfit"]
	return out


static func _own(root: Node, n: Node) -> void:
	n.owner = root
	for c: Node in n.get_children():
		_own(root, c)


static func _body() -> Node3D:
	var r: Node3D = _root(Vector3.ZERO)
	var skel: Skeleton3D = Skeleton3D.new()
	skel.name = "Skeleton3D"
	r.add_child(skel)
	var bones: Array = [["mixamorig_Hips", -1, Vector3(0, 0.9, 0)], ["mixamorig_Spine", 0, Vector3(0, 0.3, 0)],
		["mixamorig_Head", 1, Vector3(0, 0.4, 0)]]
	for b: Array in bones:
		var i: int = skel.add_bone(b[0])
		skel.set_bone_parent(i, b[1])
		skel.set_bone_rest(i, Transform3D(Basis(), b[2]))
		skel.set_bone_pose_position(i, b[2])
	var parts: Array = [["mixamorig_Hips", _capsule_mesh(0.2, 0.9), Vector3(0, -0.4, 0)],
		["mixamorig_Spine", _capsule_mesh(0.22, 0.6), Vector3(0, 0.15, 0)],
		["mixamorig_Head", _sphere_mesh(0.17), Vector3(0, 0.1, 0)]]
	for p: Array in parts:
		var att: BoneAttachment3D = BoneAttachment3D.new()
		att.bone_name = p[0]
		skel.add_child(att)
		# Ağaç dışında da (sığdırma için) doğru yerde dursun: kemiğin dinlenme konumu.
		att.transform = skel.get_bone_global_rest(skel.find_bone(p[0]))
		var m: MeshInstance3D = MeshInstance3D.new()
		m.mesh = p[1]
		m.position = p[2]
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = Color(0.85, 0.85, 0.85)
		m.material_override = mat
		att.add_child(m)
	var player: AnimationPlayer = AnimationPlayer.new()
	player.name = "AnimationPlayer"
	r.add_child(player)
	var lib: AnimationLibrary = AnimationLibrary.new()
	# Her klip: Spine öne/yana eğilir, Hips iner/zıplar. Adlar data/characters.json "animations".
	var clips: Dictionary = {"idle": [0.0, 0.0, 0.0], "walk": [0.15, 0.0, 0.04], "sit": [0.0, -0.4, 0.0],
		"type": [0.3, -0.4, 0.0], "cheer": [-0.2, 0.0, 0.2], "stress": [0.5, -0.4, 0.0]}
	for name: String in clips:
		var v: Array = clips[name]
		var a: Animation = Animation.new()
		a.length = 1.0
		var rot: int = a.add_track(Animation.TYPE_ROTATION_3D)
		a.track_set_path(rot, NodePath("Skeleton3D:mixamorig_Spine"))
		a.rotation_track_insert_key(rot, 0.0, Quaternion(Vector3.RIGHT, float(v[0]) * 0.5))
		a.rotation_track_insert_key(rot, 0.5, Quaternion(Vector3.RIGHT, float(v[0])))
		a.rotation_track_insert_key(rot, 1.0, Quaternion(Vector3.RIGHT, float(v[0]) * 0.5))
		var pos: int = a.add_track(Animation.TYPE_POSITION_3D)
		a.track_set_path(pos, NodePath("Skeleton3D:mixamorig_Hips"))
		a.position_track_insert_key(pos, 0.0, Vector3(0, 0.9 + float(v[1]), 0))
		a.position_track_insert_key(pos, 0.5, Vector3(0, 0.9 + float(v[1]) + float(v[2]), 0))
		a.position_track_insert_key(pos, 1.0, Vector3(0, 0.9 + float(v[1]), 0))
		lib.add_animation(name, a)
	player.add_animation_library("", lib)
	_own(r, skel)
	player.owner = r
	return r


static func _hair() -> Node3D:
	var r: Node3D = _root(Vector3.ZERO)
	var cap: SphereMesh = SphereMesh.new()
	cap.radius = 0.19
	cap.height = 0.22
	_part(r, cap, Vector3(0, 1.79, 0), Color(0.9, 0.9, 0.9))
	return r


static func _vest() -> Node3D:
	var r: Node3D = _root(Vector3.ZERO)
	_part(r, _boxm(0.5, 0.45, 0.32), Vector3(0, 1.3, 0), Color(0.9, 0.9, 0.9))
	return r


static func _capsule_mesh(rad: float, h: float) -> CapsuleMesh:
	var c: CapsuleMesh = CapsuleMesh.new()
	c.radius = rad
	c.height = h
	return c


static func _sphere_mesh(rad: float) -> SphereMesh:
	var s: SphereMesh = SphereMesh.new()
	s.radius = rad
	s.height = rad * 2.0
	return s
