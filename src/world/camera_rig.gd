class_name CameraRig
extends Node3D
## İzometrik-perspektif kamera (GDD 21.1): ≈40° eğim, 90°'lik dönüşler, yakınlaştırma, kaydırma.
## Girdiyi OfficeView verir; bu düğüm yalnızca kamerayı yumuşakça hedefe taşır.

const PITCH_DEG: float = -40.0
const FOV: float = 32.0
const ROTATE_SECONDS: float = 0.35
const SMOOTH: float = 10.0
const ZOOM_STEP: float = 1.15
const MIN_DISTANCE: float = 6.0
const STREET_MARGIN: float = 6.0
## Açılışta bina ekrana sığsın: köşegen × katsayı, küçük ofiste en az bu mesafe.
const FRAME_FACTOR: float = 1.3
const MIN_FRAME_DISTANCE: float = 13.0

signal yaw_changed(yaw: float)

var camera: Camera3D
var _yaw_node: Node3D
var _distance: float = 14.0
var _target_distance: float = 14.0
var _target_pos: Vector3 = Vector3.ZERO
var _bounds: Rect2 = Rect2()
var _max_distance: float = 30.0
## 0..3: kaç kez 90° döndürüldü (dollhouse kesiği bunu kullanır).
var quarter: int = 0


func _init() -> void:
	_yaw_node = Node3D.new()
	add_child(_yaw_node)
	camera = Camera3D.new()
	camera.fov = float(WorldLook.cfg()["camera"]["fov"]) if DataDB.is_ok() else FOV
	camera.current = true
	_yaw_node.add_child(camera)
	_yaw_node.rotation_degrees.y = 45.0
	_place_camera()


## Bina büyüklüğüne göre sınırlar ve başlangıç yakınlığı.
func frame(size: Vector2) -> void:
	# Sokak ve billboard da görülebilsin (M8): binanın çevresinde pay.
	_bounds = Rect2(Vector2.ZERO, size).grow(STREET_MARGIN)
	_target_pos = Vector3(size.x * 0.5, 0.0, size.y * 0.5)
	position = _target_pos
	_max_distance = maxf(MIN_DISTANCE * 3.0, size.length() * 2.0)
	_target_distance = clampf(size.length() * FRAME_FACTOR, MIN_FRAME_DISTANCE, _max_distance)
	_distance = _target_distance
	_place_camera()


func zoom(steps: float) -> void:
	_target_distance = clampf(_target_distance * pow(ZOOM_STEP, steps), MIN_DISTANCE, _max_distance)


## Ekran düzleminde kaydırma (dx, dz metre, kameranın baktığı yöne göre).
func pan(screen_delta: Vector2) -> void:
	var basis_y: Basis = Basis(Vector3.UP, _yaw_node.rotation.y)
	var move: Vector3 = basis_y * Vector3(screen_delta.x, 0.0, screen_delta.y)
	_target_pos.x = clampf(_target_pos.x + move.x, _bounds.position.x, _bounds.end.x)
	_target_pos.z = clampf(_target_pos.z + move.z, _bounds.position.y, _bounds.end.y)


func rotate_quarter(direction: int) -> void:
	quarter = posmod(quarter + direction, 4)
	var tween: Tween = create_tween()
	tween.tween_property(_yaw_node, "rotation_degrees:y", _yaw_node.rotation_degrees.y + 90.0 * direction,
		ROTATE_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void: _yaw_node.rotation_degrees.y = 45.0 + 90.0 * quarter)
	yaw_changed.emit(45.0 + 90.0 * quarter)


## Kameranın binaya baktığı yön (xz): duvar kesiği bunun tersine bakan duvarları alçaltır.
func view_dir() -> Vector2:
	var yaw: float = deg_to_rad(45.0 + 90.0 * quarter)
	return Vector2(sin(yaw), cos(yaw))


func _process(delta: float) -> void:
	var t: float = clampf(delta * SMOOTH, 0.0, 1.0)
	position = position.lerp(_target_pos, t)
	_distance = lerpf(_distance, _target_distance, t)
	_place_camera()


func _place_camera() -> void:
	var pitch_deg: float = _pitch()
	var pitch: float = deg_to_rad(-pitch_deg)
	camera.position = Vector3(0.0, sin(pitch) * _distance, cos(pitch) * _distance)
	camera.rotation_degrees.x = pitch_deg
	if DataDB.is_ok():
		WorldLook.apply_camera(camera, _distance)


## Bakış açısı ve görüş açısı data/look.json'dan (G1); veri yoksa sabitler.
func _pitch() -> float:
	return float(WorldLook.cfg()["camera"]["pitch"]) if DataDB.is_ok() else PITCH_DEG
