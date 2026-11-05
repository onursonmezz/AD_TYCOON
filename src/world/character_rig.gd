class_name CharacterRig
extends Node3D
## Bir çalışanın görünür gövdesi (M8-B). İki hâl:
## - Model varsa: gövde .glb'si (iskelet + AnimationPlayer) + saç ve kıyafet parçaları, renkler katman olarak;
##   animasyonlar AnimationTree durum makinesiyle (data/characters.json "animations" adları).
## - Model yoksa: renkli kapsül + baş + saç kepi; etkinlikler basit kod hareketleriyle (sallanma, zıplama…).
## Model kuralları: art/pipeline.md "Karakterler". Gövdenin önü +Z (Blender −Y); çalışan düğümü −Z'ye baktığı için 180° çevrilir.

const FALLBACK_HEIGHT: float = 1.5

var activity: String = "idle"
var _model: bool = false
var _tree: AnimationTree
var _playback: AnimationNodeStateMachinePlayback
var _available: Array[String] = []
var _pose: Node3D
var _t: float = 0.0
## Boyanmış malzemeler (malzeme adı | renk | kaynak) → malzeme; çalışanlar arasında paylaşılır.
static var _paints: Dictionary = {}


func has_model() -> bool:
	return _model


func has_animations() -> bool:
	return _playback != null


func build(look: Dictionary, founder: bool) -> void:
	for c: Node in get_children():
		c.queue_free()
	_tree = null
	_playback = null
	_available.clear()
	var ch: Dictionary = DataDB.data.characters
	var h: float = float(ch["height"])
	var body: Node3D = ModelLibrary.instance(str(look["body_model"]), Vector2(h * 2.0, h * 2.0), h, 180.0)
	_model = body != null
	if _model:
		add_child(body)
		_dress(body, look, str(ch["head_bone"]))
		_animate(body, ch)
	else:
		_fallback(look, founder)
	set_activity(activity)


# --- model -----------------------------------------------------------------------

func _dress(body: Node3D, look: Dictionary, head_bone: String) -> void:
	var skels: Array[Node] = body.find_children("*", "Skeleton3D", true, false)
	var skel: Skeleton3D = skels[0] as Skeleton3D if not skels.is_empty() else null
	if _paint(body, look) == 0:
		ModelLibrary.tint(body, Color(look["skin"], 0.35))
	if skel == null:
		return
	_attach(skel, str(look["outfit_model"]), look, look["outfit_color"], "")
	if not bool(look["bald"]):
		_attach(skel, str(look["hair_model"]), look, look["hair_color"], head_bone)


## Parçayı gövdenin iskeletine bağlar. Deri (skin) taşıyan mesh'ler iskelete taşınır ve onunla bükülür;
## taşımayanlar (ör. sert saç) bone verilmişse o kemiğe, yoksa iskelete sabitlenir.
func _attach(skel: Skeleton3D, rel: String, look: Dictionary, color: Color, bone: String) -> void:
	var packed: PackedScene = ModelLibrary.scene(rel) if not rel.is_empty() else null
	if packed == null:
		return
	var part: Node = packed.instantiate()
	var meshes: Array[Node] = part.find_children("*", "MeshInstance3D", true, false)
	var holder: Node3D = skel
	var bone_idx: int = skel.find_bone(bone) if not bone.is_empty() else -1
	if bone_idx >= 0:
		var att: BoneAttachment3D = BoneAttachment3D.new()
		att.bone_name = bone
		skel.add_child(att)
		var inner: Node3D = Node3D.new()
		# Parça tam gövdeye göre modellendi: kemiğin dinlenme konumunu geri al ki baştaki yerine otursun.
		inner.transform = skel.get_bone_global_rest(bone_idx).affine_inverse()
		att.add_child(inner)
		holder = inner
	for m: Node in meshes:
		var mi: MeshInstance3D = m as MeshInstance3D
		var xf: Transform3D = _local_xf(mi, part)
		mi.get_parent().remove_child(mi)
		mi.owner = null
		if mi.skin != null:
			skel.add_child(mi)
			mi.transform = Transform3D.IDENTITY
			mi.skeleton = NodePath("..")
		else:
			holder.add_child(mi)
			mi.transform = xf
		if _paint(mi, look) == 0:
			var mat: StandardMaterial3D = StandardMaterial3D.new()
			mat.albedo_color = Color(color, 0.45)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mi.material_overlay = mat
	part.free()


## Modeldeki "skin", "outfit", "hair" adlı malzemeleri çalışanın renklerine boyar (art/pipeline.md "Karakterler").
## Aynı renk + malzeme bir kez üretilir; 60 çalışan aynı malzemeleri paylaşır. Boyanan yüzey sayısını döndürür.
static func _paint(root: Node, look: Dictionary) -> int:
	var colors: Dictionary = {"skin": look["skin"], "outfit": look["outfit_color"], "hair": look["hair_color"]}
	var count: int = 0
	var nodes: Array[Node] = root.find_children("*", "MeshInstance3D", true, false)
	if root is MeshInstance3D:
		nodes.append(root)
	for n: Node in nodes:
		var mi: MeshInstance3D = n
		if mi.mesh == null:
			continue
		for i: int in mi.mesh.get_surface_count():
			var base: Material = mi.mesh.surface_get_material(i)
			if base == null or not colors.has(base.resource_name):
				continue
			var c: Color = colors[base.resource_name]
			var key: String = "%s|%s|%s" % [base.resource_name, c.to_html(false), base.get_instance_id()]
			if not _paints.has(key):
				var mat: BaseMaterial3D = (base as BaseMaterial3D).duplicate() if base is BaseMaterial3D \
					else StandardMaterial3D.new()
				mat.albedo_color = c
				_paints[key] = mat
			mi.set_surface_override_material(i, _paints[key])
			count += 1
	return count


static func _local_xf(node: Node3D, root: Node) -> Transform3D:
	var xf: Transform3D = node.transform
	var p: Node = node.get_parent()
	while p != null and p != root:
		if p is Node3D:
			xf = (p as Node3D).transform * xf
		p = p.get_parent()
	return xf


## Gövdedeki AnimationPlayer'dan bulunan klipleri durum makinesine koyar; her durumdan her duruma geçiş.
func _animate(body: Node3D, ch: Dictionary) -> void:
	var players: Array[Node] = body.find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		return
	var player: AnimationPlayer = players[0]
	for name: Variant in ch["animations"]:
		if player.has_animation(str(name)):
			_available.append(str(name))
			if str(name) != "cheer":
				player.get_animation(str(name)).loop_mode = Animation.LOOP_LINEAR
	if _available.is_empty():
		return
	var sm: AnimationNodeStateMachine = AnimationNodeStateMachine.new()
	for name: String in _available:
		var node: AnimationNodeAnimation = AnimationNodeAnimation.new()
		node.animation = name
		sm.add_node(name, node)
	var blend: float = float(ch["activity"]["blend_seconds"])
	for a: String in _available:
		for b: String in _available:
			if a != b:
				var tr_ab: AnimationNodeStateMachineTransition = AnimationNodeStateMachineTransition.new()
				tr_ab.xfade_time = blend
				sm.add_transition(a, b, tr_ab)
	_tree = AnimationTree.new()
	_tree.tree_root = sm
	body.add_child(_tree)
	_tree.anim_player = _tree.get_path_to(player)
	_tree.active = true
	_playback = _tree.get("parameters/playback")
	_playback.start(_available[0])


## Etkinliğin oynatılacak klibi: yoksa en yakın yedek (ör. "type" yoksa "sit"), o da yoksa ilk klip.
func clip_for(name: String) -> String:
	if _available.has(name):
		return name
	var fallback: Dictionary = {"type": "sit", "phone": "sit", "sleep": "sit", "stress": "sit", "coffee": "idle",
		"present": "idle", "cheer": "idle", "sit": "idle", "walk": "idle"}
	var next: String = str(fallback.get(name, ""))
	if not next.is_empty():
		return clip_for(next)
	return _available[0] if not _available.is_empty() else ""


func set_activity(name: String) -> void:
	activity = name
	if _playback != null:
		var clip: String = clip_for(name)
		if not clip.is_empty() and _playback.get_current_node() != clip:
			_playback.travel(clip)


func current_clip() -> String:
	return str(_playback.get_current_node()) if _playback != null else ""


# --- model yokken: kapsül ----------------------------------------------------------

func _fallback(look: Dictionary, founder: bool) -> void:
	_pose = Node3D.new()
	add_child(_pose)
	var body: MeshInstance3D = _mesh(_capsule(0.22, FALLBACK_HEIGHT * 0.78), look["outfit_color"])
	body.position.y = FALLBACK_HEIGHT * 0.39
	_pose.add_child(body)
	var head: MeshInstance3D = _mesh(_sphere(0.17), look["skin"])
	head.position.y = FALLBACK_HEIGHT * 0.86
	head.name = "Head"
	_pose.add_child(head)
	var nose: MeshInstance3D = _mesh(_box(Vector3(0.06, 0.05, 0.06)), look["skin"])
	nose.position = Vector3(0.0, 0.0, -0.17)
	head.add_child(nose)
	if not bool(look["bald"]):
		var hair: MeshInstance3D = _mesh(_sphere(0.18, 0.2), look["hair_color"])
		hair.position.y = 0.06
		head.add_child(hair)
	if founder:
		var crown: CylinderMesh = CylinderMesh.new()
		crown.top_radius = 0.12
		crown.bottom_radius = 0.12
		crown.height = 0.06
		var c: MeshInstance3D = _mesh(crown, UiUtil.MUSTARD)
		c.position.y = 0.24
		head.add_child(c)


static func _mesh(mesh: Mesh, color: Color) -> MeshInstance3D:
	var m: MeshInstance3D = MeshInstance3D.new()
	m.mesh = mesh
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	m.material_override = mat
	return m


static func _capsule(r: float, h: float) -> CapsuleMesh:
	var c: CapsuleMesh = CapsuleMesh.new()
	c.radius = r
	c.height = h
	return c


static func _sphere(r: float, h: float = -1.0) -> SphereMesh:
	var s: SphereMesh = SphereMesh.new()
	s.radius = r
	s.height = r * 2.0 if h < 0.0 else h
	return s


static func _box(size: Vector3) -> BoxMesh:
	var b: BoxMesh = BoxMesh.new()
	b.size = size
	return b


## Kapsül hâlinde etkinliğe göre basit hareket (yürürken sallanma, yazarken öne eğilme, sevinçte zıplama…).
func _process(delta: float) -> void:
	if _model or _pose == null:
		return
	_t += delta
	var head: Node3D = _pose.get_node_or_null("Head")
	_pose.position = Vector3.ZERO
	_pose.rotation = Vector3.ZERO
	if head != null:
		head.rotation = Vector3.ZERO
	match activity:
		"walk":
			_pose.position.y = absf(sin(_t * 9.0)) * 0.05
			_pose.rotation.z = sin(_t * 9.0) * 0.06
		"type":
			_pose.rotation.x = -0.12
			if head != null:
				head.rotation.x = sin(_t * 14.0) * 0.04
		"phone":
			if head != null:
				head.rotation.z = 0.25
				head.rotation.y = sin(_t * 1.5) * 0.3
		"coffee":
			_pose.rotation.x = sin(_t * 0.8) * 0.05
		"present":
			_pose.rotation.y = sin(_t * 1.2) * 0.35
		"cheer":
			_pose.position.y = absf(sin(_t * 8.0)) * 0.25
		"stress":
			if head != null:
				head.rotation.x = 0.35
				head.rotation.z = sin(_t * 6.0) * 0.12
		"sleep":
			_pose.rotation.x = 0.25
			if head != null:
				head.rotation.x = 0.5
		_:
			_pose.position.y = sin(_t * 2.0) * 0.01
