class_name OfficeView
extends SubViewportContainer
## 3D ofisi arayüze gömen kap (M6): fare tekerleği yakınlaştırır, sağ tuşla sürükleme kaydırır, sol tık çalışanı seçer;
## Q/E döndürür, WASD/oklar kaydırır. Tıklanan çalışan employee_clicked ile bildirilir.

signal employee_clicked(employee_id: String)

const PAN_PER_PIXEL: float = 0.03
const KEY_PAN_SPEED: float = 10.0

var world: OfficeWorld
var _viewport: SubViewport
var _dragging: bool = false


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


func _unhandled_key_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo or not is_visible_in_tree():
		return
	if key.keycode == KEY_Q:
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
