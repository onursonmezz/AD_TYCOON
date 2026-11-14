class_name OfficeView
extends SubViewportContainer
## 3D ofisi arayüze gömen kap (M6): fare tekerleği yakınlaştırır, sağ tuşla sürükleme kaydırır, sol tık çalışanı seçer;
## Q/E döndürür, WASD/oklar kaydırır. Tıklanan çalışan employee_clicked ile bildirilir.

signal employee_clicked(employee_id: String)
## İnşa modu (M6-B): yerleştirme, oda çizme, kaldırma istekleri (BuildToolbar komuta çevirir).
signal place_requested(furniture_id: String, pos: Vector2, rot: int)
signal room_requested(room_type: String, rect: Rect2)
signal remove_requested(point: Vector2)
## Duvar aracı (K-116): a–b arasına duvar; kapı aracı: noktadaki duvara kapı.
signal wall_requested(a: Vector2, b: Vector2)
signal door_requested(point: Vector2)
signal hover_changed(text_key: String)
## Silme aracında farenin altındaki oyuncu eşyası ({} = yok); araç çubuğu geri gelecek parayı yazar.
signal remove_hover(prop: Dictionary)
## Eşya aracının yönü değişti (0..3, 90° adım).
signal tool_rotated(rot: int)

const PAN_PER_PIXEL: float = 0.03
const KEY_PAN_SPEED: float = 10.0

var world: OfficeWorld
var _viewport: SubViewport
var _dragging: bool = false
## {} = inşa yok; { "kind": "furniture", "id", "rot" } | { "kind": "room", "type" } | { "kind": "remove" }
## | { "kind": "wall" } | { "kind": "door" }
var build_tool: Dictionary = {}
var _room_start: Vector2 = Vector2.INF
var _last_mouse: Vector2 = Vector2.INF


func _init() -> void:
	stretch = true
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_STOP
	_viewport = SubViewport.new()
	WorldQuality.apply_viewport(_viewport)
	Settings.changed.connect(_on_setting_changed)
	_viewport.own_world_3d = true
	add_child(_viewport)
	world = OfficeWorld.new()
	_viewport.add_child(world)
	# Kenar kararması (G1): 3D görüntünün üstünde, tıklamaları geçirir.
	var vignette: ColorRect = WorldLook.make_vignette()
	add_child(vignette)
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _on_setting_changed(key: String) -> void:
	if key == WorldQuality.SETTING:
		WorldQuality.apply_viewport(_viewport)
		world.refresh_quality()


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
	if mm != null:
		_last_mouse = mm.position
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
		rotate_tool(-1 if key.shift_pressed else 1)
		get_viewport().set_input_as_handled()
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
	remove_hover.emit({})
	refresh_hover()


## Eşya aracını döndürür: 1 saat yönünde, -1 tersine (4 yön).
func rotate_tool(direction: int) -> void:
	if build_tool.get("kind", "") != "furniture":
		return
	build_tool["rot"] = posmod(int(build_tool["rot"]) + direction, 4)
	tool_rotated.emit(int(build_tool["rot"]))
	refresh_hover()


## Önizlemeyi farenin son konumuna göre yeniler (döndürme, satış sonrası).
func refresh_hover() -> void:
	if _last_mouse != Vector2.INF and not build_tool.is_empty():
		_build_hover(_last_mouse)


## Farenin altındaki zemin noktası (Delete tuşuyla silme için); fare görünüm dışındaysa INF.
func hover_point() -> Vector2:
	return ground_point(_last_mouse) if _last_mouse != Vector2.INF else Vector2.INF


## Fare altındaki zemin noktası (metre, y = 0 düzlemi).
func ground_point(screen_pos: Vector2) -> Vector2:
	var cam: Camera3D = world.rig.camera
	var vp_pos: Vector2 = screen_pos * (Vector2(_viewport.size) / size)
	var hit: Variant = Plane(Vector3.UP, 0.0).intersects_ray(cam.project_ray_origin(vp_pos), cam.project_ray_normal(vp_pos))
	if hit == null:
		return Vector2.INF
	return Vector2((hit as Vector3).x, (hit as Vector3).z)


static func snap(p: Vector2, step: float) -> Vector2:
	return Vector2(floorf(p.x / step) * step, floorf(p.y / step) * step)


func _furniture_rect(p: Vector2) -> Rect2:
	var def: Dictionary = DataDB.data.furniture[build_tool["id"]]
	var rot: int = int(build_tool["rot"])
	var r: Rect2 = OfficeLayout.furniture_rect(def, Vector2.ZERO, rot)
	# Fare eşyanın ortasında dursun (döndürünce eşya imlecin etrafında döner).
	return OfficeLayout.furniture_rect(def, snap(p - r.size * 0.5 + Vector2.ONE * OfficeLayout.CELL * 0.5, OfficeLayout.CELL), rot)


func _room_rect(a: Vector2, b: Vector2) -> Rect2:
	var p0: Vector2 = snap(Vector2(minf(a.x, b.x), minf(a.y, b.y)), 1.0)
	var p1: Vector2 = snap(Vector2(maxf(a.x, b.x), maxf(a.y, b.y)), 1.0) + Vector2.ONE
	return Rect2(p0, p1 - p0)


## Duvar aracında başlangıç ve fare noktasından ızgaraya oturan düz duvar: uzun eksen boyunca, öbürü sabit.
func _wall_line(a: Vector2, b: Vector2) -> Array[Vector2]:
	var step: float = float(DataDB.data.bal("build.wall_snap"))
	var p0: Vector2 = (a / step).round() * step
	var p1: Vector2 = (b / step).round() * step
	if absf(p1.x - p0.x) >= absf(p1.y - p0.y):
		p1.y = p0.y
	else:
		p1.x = p0.x
	return [p0, p1]


## Duvar parçasını yerde ince bir kutu olarak gösterir (önizleme).
func _wall_ghost(a: Vector2, b: Vector2, mode: String) -> void:
	var thick: float = float(WorldLook.cfg()["walls"]["thickness"]) + 0.06
	var r: Rect2 = Rect2(a, Vector2.ZERO).expand(b).grow(thick * 0.5)
	world.show_ghost(r, float(WorldLook.cfg()["walls"]["partition_height"]) + 0.05, mode)


func _wall_hover(p: Vector2) -> void:
	var sim: Simulation = GameState.sim
	match str(build_tool["kind"]):
		"wall":
			if _room_start == Vector2.INF:
				var step: float = float(DataDB.data.bal("build.wall_snap"))
				var c: Vector2 = (p / step).round() * step
				world.show_ghost(Rect2(c - Vector2.ONE * 0.12, Vector2.ONE * 0.24), 0.3, "ok")
				hover_changed.emit("")
				return
			var line: Array[Vector2] = _wall_line(_room_start, p)
			var err: String = sim.walls.wall_error(sim.state, line[0], line[1], false)
			_wall_ghost(line[0], line[1], "ok" if err.is_empty() else "bad")
			if err.is_empty():
				hover_changed.emit("")
				remove_hover.emit({"kind": "wall_cost", "cost": sim.walls.wall_cost(sim.state, line[0], line[1]),
					"length": line[0].distance_to(line[1])})
			else:
				hover_changed.emit(err)
		"door":
			var gap: Dictionary = sim.walls.door_gap(sim.state, p)
			if gap.has("error"):
				world.show_ghost(Rect2(snap(p, OfficeLayout.CELL), Vector2(OfficeLayout.CELL, OfficeLayout.CELL)), 0.1, "bad")
				hover_changed.emit(str(gap["error"]))
			else:
				_wall_ghost(gap["a"], gap["b"], "ok")
				hover_changed.emit("")


func _build_hover(screen_pos: Vector2) -> void:
	var p: Vector2 = ground_point(screen_pos)
	if p == Vector2.INF:
		return
	var sim: Simulation = GameState.sim
	match str(build_tool["kind"]):
		"furniture":
			var def: Dictionary = DataDB.data.furniture[build_tool["id"]]
			var rot: int = int(build_tool["rot"])
			var r: Rect2 = _furniture_rect(p)
			var err: String = sim.build.place_error(sim.state, build_tool["id"], r.position, rot, false)
			world.show_ghost(r, float(def["height"]), "ok" if err.is_empty() else "bad", {
				"model": str(def.get("model", "")), "size": Vector2(float(def["size"][0]), float(def["size"][1])),
				"height": float(def["height"]), "yaw": -90.0 * rot, "base_y": float(def.get("mount_y", 0.0))})
			hover_changed.emit(err)
		"room":
			if _room_start != Vector2.INF:
				var rr: Rect2 = _room_rect(_room_start, p)
				var err: String = sim.build.room_error(sim.state, build_tool["type"], rr)
				world.show_ghost(rr, 0.2, "ok" if err.is_empty() else "bad")
				hover_changed.emit(err)
		"wall", "door":
			_wall_hover(p)
		"remove":
			var prop: Dictionary = sim.build.layout(sim.state).furniture_at(p)
			if prop.is_empty():
				# Eşya yoksa kapı, sonra iç duvar (K-116).
				var door: Dictionary = sim.walls.door_at(sim.state, p)
				var seg: Dictionary = sim.walls.wall_at(sim.state, p) if door.is_empty() else {}
				if not door.is_empty():
					_wall_ghost(door["a"], door["b"], "remove")
					remove_hover.emit({"kind": "door"})
				elif not seg.is_empty():
					_wall_ghost(seg["a"], seg["b"], "remove")
					remove_hover.emit({"kind": "wall", "refund": sim.walls.wall_refund(sim.state, seg)})
				else:
					world.show_ghost(Rect2(snap(p, OfficeLayout.CELL), Vector2(OfficeLayout.CELL, OfficeLayout.CELL)), 0.1, "remove")
					remove_hover.emit({})
				return
			else:
				var def: Dictionary = DataDB.data.furniture[prop["id"]]
				world.show_ghost((prop["rect"] as Rect2).grow(0.05), float(def["height"]) + 0.05, "remove",
					{"base_y": float(def.get("mount_y", 0.0))})
			remove_hover.emit(prop)


func _build_click(mb: InputEventMouseButton) -> void:
	var p: Vector2 = ground_point(mb.position)
	if p == Vector2.INF:
		return
	match str(build_tool["kind"]):
		"furniture":
			if mb.pressed:
				place_requested.emit(build_tool["id"], _furniture_rect(p).position, int(build_tool["rot"]))
				refresh_hover()
		"room":
			if mb.pressed:
				_room_start = p
			elif _room_start != Vector2.INF:
				room_requested.emit(build_tool["type"], _room_rect(_room_start, p))
				_room_start = Vector2.INF
				world.hide_ghost()
		"wall":
			if mb.pressed:
				_room_start = p
			elif _room_start != Vector2.INF:
				var line: Array[Vector2] = _wall_line(_room_start, p)
				_room_start = Vector2.INF
				wall_requested.emit(line[0], line[1])
				refresh_hover()
		"door":
			if mb.pressed:
				door_requested.emit(p)
				refresh_hover()
		"remove":
			if mb.pressed:
				remove_requested.emit(p)
				refresh_hover()
