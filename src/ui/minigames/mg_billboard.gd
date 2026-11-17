class_name MgBillboard
extends MinigameGame
## Açık hava provası (K-120): araba yoldan geçerken ilanın önündeki yeşil bölgedeyken "Göster" (ya da tıkla / boşluk).
## Ne kadar ortadaysa o kadar iyi.

const STRIP_SIZE: Vector2 = Vector2(1536, 512)
const PANEL: Rect2 = Rect2(840, 112, 485, 132)     # yol görselindeki boş billboard paneli (piksel)
const CAR_WIDTH: float = 170.0
const STRIP_SCALE: float = 0.72  # yol görselinin ölçeği: panel ortada iken şerit iki kenarı da kaplar
const CROSS_SECONDS: float = 2.6

var _scale: float
var _strip_pos: Vector2
var _car: TextureRect
var _t: float = 0.0
var _target_x: float


func begin() -> void:
	_scale = STRIP_SCALE
	# Panel ekranın ortasına gelsin; şerit yatayda taşar (kenarlar kırpılır).
	_strip_pos = Vector2(CANVAS.x * 0.5 - (PANEL.position.x + PANEL.size.x * 0.5) * _scale, CANVAS.y - STRIP_SIZE.y * _scale)
	stage("bg_sky")
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
	_car.position = Vector2(-CAR_WIDTH, CANVAS.y - CAR_WIDTH * 0.5 - 4.0)
	_car.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if car_tex == null:
		var body: ColorRect = ColorRect.new()
		body.color = CozyTheme.TERRA
		body.size = _car.size * Vector2(1, 0.6)
		_car.add_child(body)
	add_child(_car)
	# Yolda doğru anın bölgesi (araba merkezi bu aralıktayken gösterilmeli).
	var window: float = CANVAS.x * DataDB.data.balf("minigames.billboard_window")
	var zone: Panel = Panel.new()
	zone.add_theme_stylebox_override("panel", CozyTheme.box(Color(CozyTheme.SAGE_SOFT, 0.55), 6, CozyTheme.FOREST_LIGHT, 2, false,
		Vector2.ZERO))
	zone.position = Vector2(_target_x - window, CANVAS.y - 26.0)
	zone.size = Vector2(window * 2.0, 22.0)
	zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(zone)
	move_child(zone, _car.get_index())
	var show: Button = UiUtil.button(tr("MG_BILLBOARD_SHOW"), _catch)
	show.theme_type_variation = "PrimaryButton"
	show.custom_minimum_size = Vector2(120, 34)
	show.position = Vector2(CANVAS.x - 136, 14)
	add_child(show)


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
