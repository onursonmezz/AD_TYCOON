class_name OfficeCharacter
extends Node3D
## Ofisteki çalışan (M6; M8-B modüler karakter): yol boyunca yürür, hedefte oturur/bekler, etkinliğe göre
## animasyon oynar (CharacterRig), başından baloncuk çıkarır.
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
var _body: CharacterRig
var _founder: bool = false
var _look_sig: String = ""
## OfficeWorld'un istediği etkinlik (otururken yazma, telefon…); yürürken "walk" oynar.
var _activity: String = "idle"
var _cheer_left: float = 0.0


func setup(emp_id: String, look: Dictionary, founder: bool) -> void:
	employee_id = emp_id
	_founder = founder
	_body = CharacterRig.new()
	add_child(_body)
	apply_look(look)
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


## Görünüş (gövde, saç, kıyafet, renk); yalnızca değiştiyse (ör. yeni dönemde kıyafet) yeniden kurulur.
func apply_look(look: Dictionary) -> void:
	var sig: String = CharacterLook.signature(look)
	if sig == _look_sig:
		return
	_look_sig = sig
	_body.build(look, _founder)
	_body.position.y = -SIT_DROP if _seated and not _body.has_animations() else 0.0


## Hedefteyken yapılacak iş: "sit", "type", "phone", "coffee", "present", "stress", "sleep", "idle".
func set_activity(name: String) -> void:
	_activity = name


## Kısa sevinç (seviye atlama, iyi puan).
func cheer() -> void:
	_cheer_left = float(DataDB.data.characters["activity"]["cheer_seconds"])


func current_activity() -> String:
	return _body.activity


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
	_cheer_left = maxf(0.0, _cheer_left - delta)
	var cheer: String = "cheer" if _seated else "cheer_stand"
	var want: String = "walk" if not _path.is_empty() else (cheer if _cheer_left > 0.0 else _activity)
	if _body.activity != want:
		_body.set_activity(want)
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
			if not _body.has_animations():
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
