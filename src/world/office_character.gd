class_name OfficeCharacter
extends Node3D
## Gri kutu çalışan (M6, kapsül): yol boyunca yürür, hedefte oturur/bekler, başından baloncuk çıkarır.
## Simülasyonu bilmez; OfficeWorld hedef ve baloncuk söyler. Tıklama için Area3D taşır (meta: employee_id).

const WALK_SPEED: float = 1.6
const TURN_SPEED: float = 10.0
const BODY_HEIGHT: float = 1.5
const SIT_DROP: float = 0.35
const BUBBLE_RISE: float = 0.9
const BUBBLE_SECONDS: float = 1.3

var employee_id: String = ""
var speed_mult: float = 1.0
var _path: PackedVector2Array = PackedVector2Array()
var _face_dir: Vector2 = Vector2(0, -1)
var _seated: bool = false
var _body: Node3D


func setup(emp_id: String, color: Color, founder: bool) -> void:
	employee_id = emp_id
	_body = Node3D.new()
	add_child(_body)
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.8
	var capsule: MeshInstance3D = MeshInstance3D.new()
	var mesh: CapsuleMesh = CapsuleMesh.new()
	mesh.radius = 0.22
	mesh.height = BODY_HEIGHT
	capsule.mesh = mesh
	capsule.material_override = mat
	capsule.position.y = BODY_HEIGHT * 0.5
	_body.add_child(capsule)
	var nose: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(0.12, 0.08, 0.12)
	nose.mesh = box
	nose.position = Vector3(0.0, BODY_HEIGHT * 0.82, -0.22)
	_body.add_child(nose)
	if founder:
		var crown: MeshInstance3D = MeshInstance3D.new()
		var cyl: CylinderMesh = CylinderMesh.new()
		cyl.top_radius = 0.16
		cyl.bottom_radius = 0.16
		cyl.height = 0.08
		crown.mesh = cyl
		var gold: StandardMaterial3D = StandardMaterial3D.new()
		gold.albedo_color = UiUtil.MUSTARD
		crown.material_override = gold
		crown.position.y = BODY_HEIGHT + 0.05
		_body.add_child(crown)
	var area: Area3D = Area3D.new()
	area.set_meta("employee_id", emp_id)
	var shape: CollisionShape3D = CollisionShape3D.new()
	var cap: CapsuleShape3D = CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = BODY_HEIGHT + 0.2
	shape.shape = cap
	shape.position.y = BODY_HEIGHT * 0.5
	area.add_child(shape)
	add_child(area)


func ground_pos() -> Vector2:
	return Vector2(position.x, position.z)


func teleport(p: Vector2) -> void:
	position = Vector3(p.x, 0.0, p.y)
	_path = PackedVector2Array()


## Yeni yol; varınca face yönüne döner. sit: hedefte oturur (masa, kanepe, toplantı).
func walk(path: PackedVector2Array, face: Vector2, sit: bool) -> void:
	_path = path
	_face_dir = face
	_seated = false
	set_meta("sit_on_arrival", sit)
	_body.position.y = 0.0


func is_moving() -> bool:
	return not _path.is_empty()


func bubble(text: String, color: Color) -> void:
	var label: Label3D = Label3D.new()
	label.text = text
	label.font_size = 72
	label.outline_size = 18
	label.modulate = color
	label.outline_modulate = Color(1, 1, 1, 0.9)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.pixel_size = 0.006
	label.position = Vector3(0.0, BODY_HEIGHT + 0.35, 0.0)
	add_child(label)
	var tween: Tween = label.create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y + BUBBLE_RISE, BUBBLE_SECONDS)
	tween.tween_property(label, "modulate:a", 0.0, BUBBLE_SECONDS).set_delay(BUBBLE_SECONDS * 0.4)
	tween.chain().tween_callback(label.queue_free)


func _process(delta: float) -> void:
	if _path.is_empty():
		_turn_towards(_face_dir, delta)
		return
	var target: Vector2 = _path[0]
	var here: Vector2 = ground_pos()
	var step: float = WALK_SPEED * speed_mult * delta
	var to_target: Vector2 = target - here
	if to_target.length() <= step:
		position = Vector3(target.x, 0.0, target.y)
		_path.remove_at(0)
		if _path.is_empty() and bool(get_meta("sit_on_arrival", false)):
			_seated = true
			_body.position.y = -SIT_DROP
		return
	var dir: Vector2 = to_target.normalized()
	position += Vector3(dir.x, 0.0, dir.y) * step
	_turn_towards(dir, delta)


func _turn_towards(dir: Vector2, delta: float) -> void:
	if dir.is_zero_approx():
		return
	var target_yaw: float = atan2(-dir.x, -dir.y)
	rotation.y = lerp_angle(rotation.y, target_yaw, clampf(delta * TURN_SPEED, 0.0, 1.0))
