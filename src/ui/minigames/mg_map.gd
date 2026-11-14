class_name MgMap
extends MinigameGame
## Konum provası (K-120; strateji fazı ya da gerilla/halkla ilişkiler): haritadaki iğnelerden en kalabalık olanı seç.
## Kalabalık iğnenin çevresindeki insan noktalarıyla görünür. En kalabalık 1, ikinci 0,5, diğerleri 0,1.

const SPOTS: Array[Vector2] = [Vector2(0.22, 0.25), Vector2(0.52, 0.44), Vector2(0.8, 0.28), Vector2(0.33, 0.76),
	Vector2(0.72, 0.74), Vector2(0.15, 0.55)]
const PIN_RADIUS: float = 26.0

var _map: Rect2
var _pins: Array[Vector2] = []
var _density: Array[int] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _overlay: Control


func begin() -> void:
	_rng.seed = int(ctx["seed"])
	var bg: ColorRect = ColorRect.new()
	bg.color = CozyTheme.SAGE_SOFT.lightened(0.45)
	bg.size = CANVAS
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var side: float = CANVAS.y - 16.0
	_map = Rect2(Vector2(CANVAS.x - side - 40.0, 8.0), Vector2(side, side))
	var t: Texture2D = DraftArt.tex("props", "prop_city_map")
	if t != null:
		add_child(DraftArt._image(t, _map, TextureRect.STRETCH_SCALE))
	var legend: PanelContainer = Cards.chip(tr("MG_MAP_LEGEND"), CozyTheme.CREAM_LIGHT, CozyTheme.FOREST)
	legend.position = Vector2(30, 40)
	add_child(legend)
	var n: int = DataDB.data.bali("minigames.map_pins")
	var spots: Array = SPOTS.duplicate()
	for i: int in n:
		var k: int = _rng.randi_range(0, spots.size() - 1)
		_pins.append(_map.position + (spots[k] as Vector2) * _map.size)
		spots.remove_at(k)
	var levels: Array = range(1, n + 1)
	for i: int in range(levels.size() - 1, 0, -1):
		var j: int = _rng.randi_range(0, i)
		var tmp: Variant = levels[i]
		levels[i] = levels[j]
		levels[j] = tmp
	for v: Variant in levels:
		_density.append(int(v))
	# İğneler ve kalabalık haritanın üstünde ayrı katmanda çizilir.
	_overlay = Control.new()
	_overlay.size = CANVAS
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.draw.connect(_draw_pins)
	add_child(_overlay)
	_overlay.queue_redraw()


func _draw_pins() -> void:
	if _pins.is_empty():
		return
	var o: Control = _overlay
	var crowd: RandomNumberGenerator = RandomNumberGenerator.new()
	crowd.seed = int(ctx["seed"]) + 11
	for i: int in _pins.size():
		var p: Vector2 = _pins[i]
		for k: int in _density[i] * 6:
			var off: Vector2 = Vector2(crowd.randf_range(-1, 1), crowd.randf_range(-1, 1)) * PIN_RADIUS * 1.1
			o.draw_circle(p + off, 3.0, CozyTheme.TEXT)
		o.draw_circle(p + Vector2(0, -14), 9.0, CozyTheme.TERRA)
		o.draw_circle(p + Vector2(0, -14), 4.0, CozyTheme.CREAM_LIGHT)
		o.draw_line(p + Vector2(0, -6), p, CozyTheme.TERRA, 3.0)


func _gui_input(event: InputEvent) -> void:
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if _done or mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	for i: int in _pins.size():
		if mb.position.distance_to(_pins[i]) <= PIN_RADIUS:
			var top: int = _density.max()
			Audio.play("click")
			finish(1.0 if _density[i] == top else (0.5 if _density[i] == top - 1 else 0.1))
			accept_event()
			return
