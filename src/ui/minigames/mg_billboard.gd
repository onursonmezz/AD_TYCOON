class_name MgBillboard
extends MinigameGame
## Billboard (K-120): araba yoldan geçerken ilanın tam önündeyken tıkla (ya da boşluk). Ne kadar ortadaysa o kadar iyi.

const STRIP_SIZE: Vector2 = Vector2(1536, 512)
const PANEL: Rect2 = Rect2(840, 112, 485, 132)     # yol görselindeki boş billboard paneli (piksel)
const CAR_WIDTH: float = 150.0
const CROSS_SECONDS: float = 2.6

var _scale: float
var _strip_pos: Vector2
var _car: TextureRect
var _t: float = 0.0
var _target_x: float


func begin() -> void:
	_scale = CANVAS.x / STRIP_SIZE.x
	_strip_pos = Vector2(0, CANVAS.y - STRIP_SIZE.y * _scale)
	var sky: ColorRect = ColorRect.new()
	sky.color = CozyTheme.SAGE_SOFT.lightened(0.4)
	sky.size = CANVAS
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sky)
	var strip_tex: Texture2D = DraftArt.tex("props", "prop_road_strip")
	var panel: Rect2 = Rect2(_strip_pos + PANEL.position * _scale, PANEL.size * _scale)
	var ad: Control = ad_preview(panel.size)
	ad.position = panel.position
	if strip_tex != null:
		var strip: TextureRect = DraftArt._image(strip_tex, Rect2(_strip_pos, STRIP_SIZE * _scale), TextureRect.STRETCH_SCALE)
		add_child(strip)
	add_child(ad)
	_target_x = panel.get_center().x
	var car_tex: Texture2D = DraftArt.tex("props", "prop_car_side")
	_car = TextureRect.new()
	_car.texture = car_tex
	_car.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_car.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	_car.size = Vector2(CAR_WIDTH, CAR_WIDTH * 0.5)
	_car.position = Vector2(-CAR_WIDTH, CANVAS.y - CAR_WIDTH * 0.5 - 6.0)
	_car.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if car_tex == null:
		var body: ColorRect = ColorRect.new()
		body.color = CozyTheme.TERRA
		body.size = _car.size * Vector2(1, 0.6)
		_car.add_child(body)
	add_child(_car)
	var marker: ColorRect = ColorRect.new()
	marker.color = Color(CozyTheme.FOREST, 0.5)
	marker.size = Vector2(4, 16)
	marker.position = Vector2(_target_x - 2, CANVAS.y - 18)
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(marker)


func _process(delta: float) -> void:
	if _done or _car == null:
		return
	_t += delta / CROSS_SECONDS
	_car.position.x = lerpf(-CAR_WIDTH, CANVAS.x, _t)
	if _t >= 1.0:
		finish(0.0)


func _gui_input(event: InputEvent) -> void:
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		_catch()
		accept_event()


func _unhandled_key_input(event: InputEvent) -> void:
	var k: InputEventKey = event as InputEventKey
	if k != null and k.pressed and not k.echo and k.keycode == KEY_SPACE and is_visible_in_tree():
		_catch()
		get_viewport().set_input_as_handled()


func _catch() -> void:
	if _done:
		return
	var center: float = _car.position.x + CAR_WIDTH * 0.5
	var window: float = CANVAS.x * DataDB.data.balf("minigames.billboard_window")
	finish(1.0 - absf(center - _target_x) / (window * 2.0))
