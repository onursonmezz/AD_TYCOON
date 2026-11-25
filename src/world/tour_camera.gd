class_name TourCamera
extends Node3D
## Gezinti modunun göz hizası kamerası (K-148): fareyle bakış, WASD ile yürüyüş, duvar ve eşyalara çarpar
## (TourCollision). Girdiyi TourMode verir; ayarlar data/look.json "tour".

const PITCH_LIMIT: float = 85.0

var camera: Camera3D
var _layout: OfficeLayout
var _yaw: float = 0.0
var _pitch: float = 0.0


func _init() -> void:
	camera = Camera3D.new()
	camera.near = 0.05
	add_child(camera)


static func cfg() -> Dictionary:
	return WorldLook.cfg()["tour"]


## Girişin içinde, binanın ortasına bakarak başlar. env: dünyanın ortamı (kopyası gökyüzüyle bu kameraya verilir).
func start(layout: OfficeLayout, env: Environment) -> void:
	_layout = layout
	var c: Dictionary = cfg()
	camera.fov = float(c["fov"])
	camera.environment = _sky_environment(env)
	_add_ceiling()
	var p: Vector2 = TourCollision.start_point(layout, float(c["start_back"]), float(c["radius"]))
	position = Vector3(p.x, float(c["eye_height"]), p.y)
	var look: Vector2 = layout.size * 0.5 - p
	_yaw = atan2(-look.x, -look.y) if not look.is_zero_approx() else 0.0
	_pitch = 0.0
	_apply_rotation()
	camera.current = true


## Fare hareketi (piksel): sağa/sola döner, yukarı/aşağı bakar.
func look(relative: Vector2) -> void:
	var s: float = deg_to_rad(float(cfg()["look_sensitivity"]))
	_yaw -= relative.x * s
	_pitch = clampf(_pitch - relative.y * s, deg_to_rad(-PITCH_LIMIT), deg_to_rad(PITCH_LIMIT))
	_apply_rotation()


## input: x sağ (+) / sol (−), y geri (+) / ileri (−). Bakılan yöne göre yerde yürür.
func walk(input: Vector2, run: bool, delta: float) -> void:
	if input.is_zero_approx() or _layout == null:
		return
	var c: Dictionary = cfg()
	var speed: float = float(c["walk_speed"]) * (float(c["run_mult"]) if run else 1.0)
	var dir: Vector2 = input.normalized().rotated(-_yaw) * speed * delta
	var here: Vector2 = ground_pos()
	var to: Vector2 = TourCollision.slide(_layout, here, here + dir, float(c["radius"]), float(c["street_margin"]))
	position.x = to.x
	position.z = to.y


func ground_pos() -> Vector2:
	return Vector2(position.x, position.z)


func yaw() -> float:
	return _yaw


## Kuşbakışında gök görünmez (düz renk); göz hizasında gökyüzü ve ufukta aynı renkte sis.
func _sky_environment(env: Environment) -> Environment:
	var e: Environment = env.duplicate() if env != null else Environment.new()
	var s: Dictionary = cfg()["sky"]
	var mat: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
	mat.sky_top_color = WorldLook.col(s["top"])
	mat.sky_horizon_color = WorldLook.col(s["horizon"])
	mat.ground_horizon_color = WorldLook.col(s["horizon"])
	mat.ground_bottom_color = WorldLook.col(s["ground"])
	var sky: Sky = Sky.new()
	sky.sky_material = mat
	e.background_mode = Environment.BG_SKY
	e.sky = sky
	e.fog_light_color = WorldLook.col(s["horizon"])
	return e


## Binanın üstünü örten tavan (dış duvar boyunda): gölge düşürmez, içerisi güneşle aydınlanmaya devam eder.
## Kamerayla değil binayla durur (kardeş düğüm); gezinti bitince kamerayla birlikte silinir.
func _add_ceiling() -> void:
	var t: Dictionary = cfg()["ceiling"]
	var thick: float = float(t["thickness"])
	var height: float = float(WorldLook.cfg()["walls"]["outer_height"])
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(_layout.size.x, thick, _layout.size.y)
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = WorldLook.col(t["color"])
	var m: MeshInstance3D = MeshInstance3D.new()
	m.mesh = box
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.position = Vector3(_layout.size.x * 0.5, height + thick * 0.5, _layout.size.y * 0.5)
	m.name = "TourCeiling"
	get_parent().add_child(m)
	tree_exiting.connect(m.queue_free)


func _apply_rotation() -> void:
	rotation = Vector3(0.0, _yaw, 0.0)
	camera.rotation = Vector3(_pitch, 0.0, 0.0)
