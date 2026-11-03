class_name OfficeView
extends SubViewportContainer
## 3D ofisi arayüze gömen kap (M6): fare tekerleği yakınlaştırır, sağ tuşla sürükleme kaydırır, sol tık çalışanı seçer;
## Q/E döndürür, WASD/oklar kaydırır. Tıklanan çalışan employee_clicked ile bildirilir.

signal employee_clicked(employee_id: String)
## İnşa modu (M6-B): yerleştirme, oda çizme, kaldırma istekleri (BuildToolbar komuta çevirir).
signal place_requested(furniture_id: String, pos: Vector2, rot: int)
signal room_requested(room_type: String, rect: Rect2)
signal remove_requested(point: Vector2)
signal hover_changed(text_key: String)

const PAN_PER_PIXEL: float = 0.03
const KEY_PAN_SPEED: float = 10.0

var world: OfficeWorld
var _viewport: SubViewport
var _dragging: bool = false
## {} = inşa yok; { "kind": "furniture", "id", "rot" } | { "kind": "room", "type" } | { "kind": "remove" }
var build_tool: Dictionary = {}
var _room_start: Vector2 = Vector2.INF


func _init() -> void:
	stretch = true
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_STOP
	_viewport = SubViewport.new()
	_viewport.msaa_3d = Viewport.MSAA_2X
	_viewport.own_world_3d = true
	add_child(_viewport)
	world = OfficeWorld.new()
	_viewport.add_child(world)


func _gui_input(event: InputEvent) -> void:
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if mb != null:
		if mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			world.rig.zoom(-1.0)
			accept_event()
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			world.rig.zoom(1.0)
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			_dragging = mb.pressed
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_LEFT and not build_tool.is_empty():
			_build_click(mb)
			accept_event()
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			var cam: Camera3D = world.rig.camera
			var p: Vector2 = mb.position * (Vector2(_viewport.size) / size)
			var id: String = world.pick(cam.project_ray_origin(p), cam.project_ray_normal(p))
			if not id.is_empty():
				employee_clicked.emit(id)
				accept_event()
	var mm: InputEventMouseMotion = event as InputEventMouseMotion
	if mm != null and _dragging:
		world.rig.pan(-mm.relative * PAN_PER_PIXEL)
		accept_event()
	if mm != null and not build_tool.is_empty():
		_build_hover(mm.position)


func _unhandled_key_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo or not is_visible_in_tree():
		return
	if key.keycode == KEY_R and build_tool.get("kind", "") == "furniture":
		build_tool["rot"] = (int(build_tool["rot"]) + 1) % 2
	elif key.keycode == KEY_ESCAPE and not build_tool.is_empty():
		set_tool({})
		get_viewport().set_input_as_handled()
	elif key.keycode == KEY_Q:
		world.rig.rotate_quarter(-1)
	elif key.keycode == KEY_E:
		world.rig.rotate_quarter(1)


func _process(delta: float) -> void:
	if not is_visible_in_tree() or get_viewport().gui_get_focus_owner() is LineEdit:
		return
	var dir: Vector2 = Vector2(
		float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)),
		float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)))
	if not dir.is_zero_approx():
		world.rig.pan(dir * KEY_PAN_SPEED * delta)


# --- inşa modu --------------------------------------------------------------------

func set_tool(tool: Dictionary) -> void:
	build_tool = tool
	_room_start = Vector2.INF
	world.hide_ghost()


## Fare altındaki zemin noktası (metre, y = 0 düzlemi).
func ground_point(screen_pos: Vector2) -> Vector2:
	var cam: Camera3D = world.rig.camera
	var hit: Variant = Plane(Vector3.UP, 0.0).intersects_ray(cam.project_ray_origin(screen_pos), cam.project_ray_normal(screen_pos))
	if hit == null:
		return Vector2.INF
	return Vector2((hit as Vector3).x, (hit as Vector3).z)


static func snap(p: Vector2, step: float) -> Vector2:
	return Vector2(floorf(p.x / step) * step, floorf(p.y / step) * step)


func _furniture_rect(p: Vector2) -> Rect2:
	var def: Dictionary = DataDB.data.furniture[build_tool["id"]]
	return OfficeLayout.furniture_rect(def, snap(p, OfficeLayout.CELL), int(build_tool["rot"]))


func _room_rect(a: Vector2, b: Vector2) -> Rect2:
	var p0: Vector2 = snap(Vector2(minf(a.x, b.x), minf(a.y, b.y)), 1.0)
	var p1: Vector2 = snap(Vector2(maxf(a.x, b.x), maxf(a.y, b.y)), 1.0) + Vector2.ONE
	return Rect2(p0, p1 - p0)


func _build_hover(screen_pos: Vector2) -> void:
	var p: Vector2 = ground_point(screen_pos)
	if p == Vector2.INF:
		return
	var sim: Simulation = GameState.sim
	match str(build_tool["kind"]):
		"furniture":
			var r: Rect2 = _furniture_rect(p)
			var err: String = sim.build.place_error(sim.state, build_tool["id"], r.position, int(build_tool["rot"]), false)
			world.show_ghost(r, float(DataDB.data.furniture[build_tool["id"]]["height"]), err.is_empty())
			hover_changed.emit(err)
		"room":
			if _room_start != Vector2.INF:
				var rr: Rect2 = _room_rect(_room_start, p)
				var err: String = sim.build.room_error(sim.state, build_tool["type"], rr)
				world.show_ghost(rr, 0.2, err.is_empty())
				hover_changed.emit(err)
		"remove":
			world.show_ghost(Rect2(snap(p, OfficeLayout.CELL), Vector2(OfficeLayout.CELL, OfficeLayout.CELL)), 0.1, true)


func _build_click(mb: InputEventMouseButton) -> void:
	var p: Vector2 = ground_point(mb.position)
	if p == Vector2.INF:
		return
	match str(build_tool["kind"]):
		"furniture":
			if mb.pressed:
				place_requested.emit(build_tool["id"], _furniture_rect(p).position, int(build_tool["rot"]))
		"room":
			if mb.pressed:
				_room_start = p
			elif _room_start != Vector2.INF:
				room_requested.emit(build_tool["type"], _room_rect(_room_start, p))
				_room_start = Vector2.INF
				world.hide_ghost()
		"remove":
			if mb.pressed:
				remove_requested.emit(p)
