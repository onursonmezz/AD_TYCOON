class_name OfficeWorld
extends Node3D
## 3D ofis (M6, gri kutu): bina, odalar, mobilya kutuları, çalışan kapsülleri ve baloncuklar.
## Simülasyona yalnızca okuma ile bağlanır (GameState.sim.state + EventBus); hiçbir şeyi değiştirmez (GDD 24).

const OUTER_WALL_HEIGHT: float = 2.6
const CUT_WALL_HEIGHT: float = 0.35
const PARTITION_HEIGHT: float = 1.3
const WALL_THICKNESS: float = 0.15
const BUBBLE_CHANCE: float = 0.45
const FLOOR_COLORS: Dictionary = {
	"work": Color(0.86, 0.78, 0.64), "meeting": Color(0.62, 0.72, 0.62), "kitchen": Color(0.86, 0.66, 0.58),
	"lounge": Color(0.9, 0.8, 0.55), "empty": Color(0.8, 0.79, 0.76), "brainstorm": Color(0.75, 0.82, 0.88),
	"award_lobby": Color(0.92, 0.85, 0.62), "rd_lab": Color(0.7, 0.78, 0.86), "studio": Color(0.6, 0.6, 0.66),
}
const PROP_STYLE: Dictionary = {
	"desk": [0.75, Color(0.65, 0.49, 0.32)], "counter": [0.95, Color(0.95, 0.93, 0.88)],
	"table": [0.75, Color(0.55, 0.4, 0.27)], "sofa": [0.55, Color(0.36, 0.5, 0.4)],
}
const DEPT_COLORS: Dictionary = {
	"founder": Color(0.85, 0.64, 0.25), "creative": Color(0.88, 0.5, 0.35), "design": Color(0.93, 0.6, 0.45),
	"strategy": Color(0.36, 0.5, 0.4), "account": Color(0.3, 0.45, 0.65), "production": Color(0.45, 0.55, 0.8),
	"media": Color(0.55, 0.45, 0.7), "digital": Color(0.35, 0.65, 0.7), "pr_event": Color(0.8, 0.45, 0.6),
	"new_business": Color(0.6, 0.6, 0.35), "operations": Color(0.55, 0.55, 0.55), "support": Color(0.7, 0.68, 0.62),
}
const BUBBLES: Array[Array] = [["S", Color(0.24, 0.55, 0.32)], ["K", Color(0.9, 0.5, 0.2)], ["T", Color(0.25, 0.45, 0.85)]]

var rig: CameraRig
var layout: OfficeLayout
var _level: int = 0
var _build_version: int = -1
var _building: Node3D
var _walls: Array[Dictionary] = []
var _chars: Dictionary = {}
var _desk_of: Dictionary = {}
var _place_of: Dictionary = {}
var _last_day: int = -1
var _last_errors: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	var env: WorldEnvironment = WorldEnvironment.new()
	var e: Environment = Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = UiUtil.CREAM
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(1.0, 0.95, 0.88)
	e.ambient_light_energy = 0.55
	env.environment = e
	add_child(env)
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.9, 0.75)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-55.0, 35.0, 0.0)
	add_child(sun)
	rig = CameraRig.new()
	add_child(rig)
	rig.yaw_changed.connect(func(_y: float) -> void: _update_cut())
	EventBus.state_changed.connect(sync)
	EventBus.notification.connect(_on_notification)
	sync()


# --- bina ---------------------------------------------------------------------

## Bina geometrisi. Yalnızca düzen değiştiyse (mobilya, oda) çalışanlar yerinde kalır ve yeniden yol bulur;
## taşınınca hepsi kapıdan yeniden girer.
func _build(level: int) -> void:
	var moved: bool = level != _level
	_level = level
	_build_version = int(GameState.sim.state.build.get("version", 0))
	if _building != null:
		_building.queue_free()
	if moved:
		for c: OfficeCharacter in _chars.values():
			c.queue_free()
		_chars.clear()
		_desk_of.clear()
	_place_of.clear()
	_walls.clear()
	_building = Node3D.new()
	add_child(_building)
	layout = GameState.sim.build.layout(GameState.sim.state)
	_box(Vector3(layout.size.x * 0.5, -0.06, layout.size.y * 0.5), Vector3(layout.size.x + 6.0, 0.1, layout.size.y + 6.0),
		Color(0.7, 0.78, 0.6))
	for room: Dictionary in layout.rooms:
		var r: Rect2 = room["rect"]
		_box(Vector3(r.get_center().x, 0.0, r.get_center().y), Vector3(r.size.x, 0.04, r.size.y), FLOOR_COLORS[room["type"]])
	for w: Dictionary in layout.walls:
		var a: Vector2 = w["a"]
		var b: Vector2 = w["b"]
		var mid: Vector2 = (a + b) * 0.5
		var horizontal: bool = is_equal_approx(a.y, b.y)
		var length: float = a.distance_to(b)
		var height: float = OUTER_WALL_HEIGHT if bool(w["outer"]) else PARTITION_HEIGHT
		var size: Vector3 = Vector3(length, height, WALL_THICKNESS) if horizontal else Vector3(WALL_THICKNESS, height, length)
		var mesh: MeshInstance3D = _box(Vector3(mid.x, height * 0.5, mid.y), size, Color(0.96, 0.94, 0.89))
		_walls.append({"mesh": mesh, "side": w["side"], "outer": w["outer"], "height": height, "mid": mid})
	for prop: Dictionary in layout.props:
		var pr: Rect2 = prop["rect"]
		if prop["kind"] == "furniture":
			var def: Dictionary = DataDB.data.furniture[prop["id"]]
			var c: Array = def["color"]
			_box(Vector3(pr.get_center().x, float(def["height"]) * 0.5, pr.get_center().y),
				Vector3(pr.size.x * 0.9, float(def["height"]), pr.size.y * 0.9), Color(float(c[0]), float(c[1]), float(c[2])))
			continue
		var style: Array = PROP_STYLE[prop["kind"]]
		_box(Vector3(pr.get_center().x, float(style[0]) * 0.5, pr.get_center().y), Vector3(pr.size.x, float(style[0]), pr.size.y),
			style[1])
		if prop["kind"] == "desk":
			_box(Vector3(pr.get_center().x, float(style[0]) + 0.2, pr.get_center().y - 0.1), Vector3(0.5, 0.35, 0.06),
				Color(0.25, 0.25, 0.28))
	if moved:
		rig.frame(layout.size)
	_update_cut()


func _box(pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var m: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	m.mesh = mesh
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	m.material_override = mat
	m.position = pos
	_building.add_child(m)
	return m


## Dollhouse görünümü (21.1): kameraya bakan dış duvarlar alçalır.
func _update_cut() -> void:
	if rig == null:
		return
	var view: Vector2 = rig.view_dir()
	var normals: Dictionary = {"n": Vector2(0, -1), "s": Vector2(0, 1), "w": Vector2(-1, 0), "e": Vector2(1, 0)}
	for w: Dictionary in _walls:
		var mesh: MeshInstance3D = w["mesh"]
		var cut: bool = bool(w["outer"]) and (normals[w["side"]] as Vector2).dot(view) > 0.1
		var h: float = CUT_WALL_HEIGHT if cut else float(w["height"])
		(mesh.mesh as BoxMesh).size.y = h
		mesh.position.y = h * 0.5


# --- çalışanlar -----------------------------------------------------------------

func sync() -> void:
	if not GameState.has_game():
		return
	var s: SimState = GameState.sim.state
	if s.office_level != _level or int(s.build.get("version", 0)) != _build_version:
		_build(s.office_level)
	for id: String in _chars.keys():
		if not s.staff.has(id):
			(_chars[id] as OfficeCharacter).queue_free()
			_chars.erase(id)
			_desk_of.erase(id)
			_place_of.erase(id)
	for emp: Dictionary in s.staff.values():
		if not _chars.has(emp["id"]):
			_spawn(emp)
	_assign_places(s)
	var day: int = s.clock.week_index * s.clock.days_per_week + s.clock.day_in_week
	if day != _last_day:
		_last_day = day
		_daily_bubbles(s)
	var speed: float = float(Clock.speeds()[Clock.speed_index]) if Clock.is_running() else 1.0
	for c: OfficeCharacter in _chars.values():
		c.speed_mult = speed


func _spawn(emp: Dictionary) -> void:
	var c: OfficeCharacter = OfficeCharacter.new()
	var dept: String = str(DataDB.data.positions[emp["role"]]["department"])
	c.setup(emp["id"], DEPT_COLORS.get(dept, Color(0.6, 0.6, 0.6)), bool(emp.get("is_founder", false)))
	add_child(c)
	c.teleport(layout.entrance)
	_chars[emp["id"]] = c
	var used: Array = _desk_of.values()
	for i: int in layout.desks.size():
		if not used.has(i):
			_desk_of[emp["id"]] = i
			break


## Nerede olmalı: izinde → görünmez; pitch'te → toplantı odası; yorgun → mutfak; yoksa masası.
func _assign_places(s: SimState) -> void:
	var week: int = s.clock.week_index
	var counters: Dictionary = {}
	var low_energy: float = DataDB.data.balf("energy.low_threshold")
	for id: String in _chars:
		var emp: Dictionary = s.staff[id]
		var place: String = "desk"
		if int(emp.get("busy_until", -1)) > week:
			place = "away"
		elif int(emp.get("pitch_until", -1)) > week:
			place = "meeting"
		elif float(emp["energy"]) < low_energy:
			place = "kitchen"
		if place != "desk" and place != "away" and layout.spot_list(place).is_empty():
			place = "lounge" if not layout.spot_list("lounge").is_empty() else "desk"
		var slot: int = int(counters.get(place, 0))
		counters[place] = slot + 1
		var key: String = "%s:%d" % [place, slot]
		if _place_of.get(id, "") == key:
			continue
		_place_of[id] = key
		_go(_chars[id], id, place, slot)


func _go(c: OfficeCharacter, id: String, place: String, slot: int) -> void:
	c.visible = place != "away"
	if place == "away":
		c.teleport(layout.entrance)
		return
	var target: Vector2
	var face: Vector2 = Vector2(0, -1)
	var sit: bool = true
	if place == "desk":
		var desk: Dictionary = layout.desks[int(_desk_of.get(id, 0)) % layout.desks.size()]
		target = desk["seat"]
	else:
		var spots: Array = layout.spot_list(place)
		target = spots[slot % spots.size()]
		sit = place != "kitchen"
		if place == "meeting":
			face = (layout.room_rect("meeting").get_center() - target).normalized()
	var path: PackedVector2Array = layout.path(c.ground_pos(), target)
	if path.is_empty():
		c.teleport(target)
		path = PackedVector2Array([target])
	c.walk(path, face, sit)


# --- baloncuklar ------------------------------------------------------------------

## Her oyun günü: kampanya ekibinin masada oturanlarından bazıları fazın alanında baloncuk çıkarır; yeni hata = "!".
func _daily_bubbles(s: SimState) -> void:
	var camp: Dictionary = s.active_campaign
	if camp.is_empty():
		_last_errors = 0
		return
	var phase: int = GameState.sim.production.current_phase(camp)
	var team: Array = camp["setup"].get("team", [])
	for id: Variant in team:
		var c: OfficeCharacter = _chars.get(str(id))
		if c != null and c.visible and not c.is_moving() and str(_place_of.get(str(id), "")).begins_with("desk") \
				and _rng.randf() < BUBBLE_CHANCE:
			var b: Array = BUBBLES[clampi(phase, 0, BUBBLES.size() - 1)]
			c.bubble(str(b[0]), b[1])
	var errors: int = int(camp.get("errors", 0))
	if errors > _last_errors and not team.is_empty():
		var c: OfficeCharacter = _chars.get(str(team[_rng.randi_range(0, team.size() - 1)]))
		if c != null and c.visible:
			c.bubble("!", UiUtil.TERRACOTTA)
	_last_errors = errors


func _on_notification(key: String, args: Array, _kind: String) -> void:
	if not GameState.has_game() or not key.begins_with("NOTE_LEVEL_UP"):
		return
	for id: String in _chars:
		var emp: Dictionary = GameState.sim.state.staff.get(id, {})
		if (key == "NOTE_LEVEL_UP_FOUNDER" and bool(emp.get("is_founder", false))) \
				or (not args.is_empty() and str(emp.get("name", "")) == str(args[0])):
			(_chars[id] as OfficeCharacter).bubble("★", UiUtil.MUSTARD)


## Ekrandaki bir noktadan tıklanan çalışan ("" = yok).
func pick(camera_ray_from: Vector3, camera_ray_dir: Vector3) -> String:
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(camera_ray_from, camera_ray_from + camera_ray_dir * 500.0)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or not (hit["collider"] as Object).has_meta("employee_id"):
		return ""
	return str((hit["collider"] as Object).get_meta("employee_id"))


# --- inşa modu önizlemesi ------------------------------------------------------------

var _ghost: MeshInstance3D


## Yerleştirme/oda önizlemesi: yeşil uygun, kırmızı değil.
func show_ghost(rect: Rect2, height: float, ok: bool) -> void:
	if _ghost == null:
		_ghost = MeshInstance3D.new()
		_ghost.mesh = BoxMesh.new()
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_ghost.material_override = mat
		add_child(_ghost)
	_ghost.visible = true
	(_ghost.mesh as BoxMesh).size = Vector3(rect.size.x, height, rect.size.y)
	_ghost.position = Vector3(rect.get_center().x, height * 0.5, rect.get_center().y)
	(_ghost.material_override as StandardMaterial3D).albedo_color = Color(0.3, 0.75, 0.4, 0.45) if ok else Color(0.85, 0.3, 0.25, 0.45)


func hide_ghost() -> void:
	if _ghost != null:
		_ghost.visible = false
