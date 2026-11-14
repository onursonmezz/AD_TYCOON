class_name MgRadio
extends MinigameGame
## Radyo (K-120): üç parçaya bölünmüş ses dalgasını doğru sırayla üstteki yuvalara koy. İlk parça sessizlikle başlar,
## son parça sessizlikle biter; birleşim yerleri ipucu verir. Her yanlış tık başarıdan bir parça götürür.

const SAMPLES: int = 240
const SLOT: Vector2 = Vector2(180, 88)

var _wave: PackedFloat32Array = PackedFloat32Array()
var _order: Array[int] = []       # aşağıdaki parçaların sırası (karışık)
var _placed: Array[int] = []      # yuvalara konan parça kimlikleri
var _mistakes: int = 0
var _flash: float = 0.0


func begin() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(ctx["seed"])
	_wave.resize(SAMPLES)
	for i: int in SAMPLES:
		var t: float = float(i) / SAMPLES
		var env: float = sin(t * PI)  # baş ve son sessiz
		_wave[i] = env * (0.6 * sin(t * 38.0) + 0.3 * sin(t * 91.0 + 1.3) + rng.randf_range(-0.15, 0.15))
	_order = [0, 1, 2]
	while _order == [0, 1, 2]:
		_order.shuffle()
	queue_redraw()


func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta)
		queue_redraw()


func _slot_rect(i: int) -> Rect2:
	return Rect2(Vector2(20 + i * 200, 40), SLOT)


func _piece_rect(i: int) -> Rect2:
	return Rect2(Vector2(20 + i * 200, 190), SLOT)


func _gui_input(event: InputEvent) -> void:
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if _done or mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	for i: int in 3:
		var piece: int = _order[i]
		if _placed.has(piece) or not _piece_rect(i).has_point(mb.position):
			continue
		if piece == _placed.size():
			_placed.append(piece)
			Audio.play("click")
			if _placed.size() == 3:
				finish(1.0 - 0.34 * _mistakes)
		else:
			_mistakes += 1
			_flash = 0.35
		queue_redraw()
		accept_event()
		return


func time_up() -> void:
	finish(0.25 * _placed.size() * (1.0 - 0.34 * _mistakes))


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, CANVAS), CozyTheme.CREAM_LIGHT)
	for i: int in 3:
		var r: Rect2 = _slot_rect(i)
		draw_rect(r, CozyTheme.SAGE_SOFT if i < _placed.size() else Color(CozyTheme.SAGE_SOFT, 0.35))
		draw_rect(r, CozyTheme.BORDER, false, 2.0)
		if i < _placed.size():
			_draw_piece(r, _placed[i], CozyTheme.FOREST)
	for i: int in 3:
		var piece: int = _order[i]
		if _placed.has(piece):
			continue
		var r: Rect2 = _piece_rect(i)
		var wrong: bool = _flash > 0.0
		draw_rect(r, CozyTheme.CREAM)
		draw_rect(r, CozyTheme.NEGATIVE if wrong else CozyTheme.TERRA, false, 2.0)
		_draw_piece(r, piece, CozyTheme.TERRA)


func _draw_piece(r: Rect2, piece: int, color: Color) -> void:
	var n: int = SAMPLES / 3
	var pts: PackedVector2Array = PackedVector2Array()
	for k: int in n:
		var v: float = _wave[piece * n + k]
		pts.append(Vector2(r.position.x + r.size.x * float(k) / (n - 1), r.position.y + r.size.y * (0.5 - v * 0.42)))
	draw_polyline(pts, color, 2.0, true)
