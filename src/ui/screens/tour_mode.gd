class_name TourMode
extends Control
## Gezinti modu (K-148): ofiste göz hizasında yürümek, yalnızca çevreyi görmek için. Bütün arayüz gizlenir,
## oyun saati durur (Clock.hold), hiçbir tıklama ya da kısayol oyuna gitmez; Esc ile çıkılır ve her şey eski hâline
## döner. Çalışanların dolaşması OfficeWorld/TourLife'ta (yalnızca görüntü).

const DOT_SIZE: float = 6.0

var _office: OfficeView
var _hidden: Array[CanvasItem] = []


## Açılabiliyorsa açar (oyun var, inşa modu ve pencere yok, ofis kurulu); açılan modu döndürür, açılamazsa null.
static func try_open(main: Control, office: OfficeView, modal_layer: Control, building: bool) -> TourMode:
	if not GameState.has_game() or building or modal_layer.get_child_count() > 0 or office.world.layout == null \
			or office.world.tour != null:
		return null
	var mode: TourMode = TourMode.new(office)
	for child: Node in main.get_children():
		if child is CanvasItem and child != office and (child as CanvasItem).visible:
			(child as CanvasItem).visible = false
			mode._hidden.append(child)
	main.add_child(mode)
	return mode


func _init(office: OfficeView) -> void:
	_office = office
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dot: ColorRect = ColorRect.new()
	dot.color = Color(CozyTheme.CREAM_LIGHT, 0.85)
	dot.custom_minimum_size = Vector2(DOT_SIZE, DOT_SIZE)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dot)
	dot.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)
	var hint: Label = UiUtil.label(tr("UI_TOUR_HINT"), 13, Color(CozyTheme.CREAM_LIGHT, 0.75))
	hint.add_theme_constant_override("outline_size", 4)
	hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.45))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hint.offset_left = MainHud.EDGE
	hint.offset_bottom = -MainHud.EDGE


func _ready() -> void:
	Clock.hold()
	_office.world.begin_tour()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func close() -> void:
	if is_queued_for_deletion():
		return
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_office.world.end_tour()
	for item: CanvasItem in _hidden:
		if is_instance_valid(item):
			item.visible = true
	_hidden.clear()
	Clock.release()
	queue_free()


## Bütün girdiyi yutar: yalnızca bakış, yürüyüş ve Esc.
func _input(event: InputEvent) -> void:
	get_viewport().set_input_as_handled()
	if event.is_action_pressed("ui_cancel"):
		close()
		return
	var mm: InputEventMouseMotion = event as InputEventMouseMotion
	if mm != null and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and _office.world.tour != null:
		_office.world.tour.look(mm.relative)
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if mb != null and mb.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED  # pencere odağını kaybedip dönünce tıkla, bakış geri gelsin


func _process(delta: float) -> void:
	var tour: TourCamera = _office.world.tour
	if tour == null:
		return
	var dir: Vector2 = Vector2(
		float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)),
		float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)))
	tour.walk(dir, Input.is_key_pressed(KEY_SHIFT), delta)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
