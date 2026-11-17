class_name MgRadio
extends MinigameGame
## Radyo (K-120): üç parçaya bölünmüş ses dalgasını doğru sırayla üstteki yuvalara koy. İlk parça sessizlikle başlar,
## son parça sessizlikle biter; birleşim yerleri ipucu verir. Her yanlış tık başarıdan bir parça götürür.
## MG-2: stüdyo zemininde koyu bir ses düzenleme masası; üstte zaman çizelgesi (1-2-3 izleri, saniye çizgileri),
## altta renkli klipler; yayın ışığı tamamlanınca yanar.

const SAMPLES: int = 240
const DESK: Rect2 = Rect2(24, 20, 592, 320)
const SLOT: Vector2 = Vector2(176, 84)
const CLIP_COLORS: Array[Color] = [Color("d9824f"), Color("6f9f72"), Color("c9a24d")]
const DESK_COLOR: Color = Color("2b3330")
const LANE_COLOR: Color = Color("3a4541")
const GRID_COLOR: Color = Color(1, 1, 1, 0.07)

var _wave: PackedFloat32Array = PackedFloat32Array()
var _order: Array[int] = []       # aşağıdaki parçaların sırası (karışık)
var _placed: Array[int] = []      # yuvalara konan parça kimlikleri
var _mistakes: int = 0
var _flash: float = 0.0
var _flash_piece: int = -1
var _canvas: Control


func begin() -> void:
	stage("bg_studio")
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
	# Çizim ayrı bir katmanda: zemin resmi (çocuk) kendi çizimimizi örtmesin.
	_canvas = Control.new()
	_canvas.size = CANVAS
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_desk)
	add_child(_canvas)
	_canvas.queue_redraw()


func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta)
		_canvas.queue_redraw()


func _slot_rect(i: int) -> Rect2:
	return Rect2(Vector2(DESK.position.x + 18 + i * (SLOT.x + 12), DESK.position.y + 58), SLOT)


func _piece_rect(i: int) -> Rect2:
	return Rect2(Vector2(DESK.position.x + 18 + i * (SLOT.x + 12), DESK.position.y + 210), SLOT)


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
			_flash_piece = piece
		_canvas.queue_redraw()
		accept_event()
		return


func time_up() -> void:
	finish(0.25 * _placed.size() * (1.0 - 0.34 * _mistakes))


func _draw_desk() -> void:
	var c: Control = _canvas
	var font: Font = get_theme_default_font()
	c.draw_style_box(CozyTheme.box(DESK_COLOR, 14, Color(0, 0, 0, 0.35), 2, true, Vector2.ZERO), DESK)
	# Üst şerit: yayın ışığı ve zaman çizelgesi başlığı.
	var on_air: bool = _placed.size() == 3
	var lamp: Rect2 = Rect2(DESK.position + Vector2(18, 14), Vector2(78, 24))
	c.draw_style_box(CozyTheme.box(Color("c94a3a") if on_air else Color("5a3a35"), 6, Color.TRANSPARENT, 0, false,
		Vector2.ZERO), lamp)
	c.draw_string(font, lamp.position + Vector2(0, 17), tr("MG_RADIO_ON_AIR"), HORIZONTAL_ALIGNMENT_CENTER, lamp.size.x, 13,
		Color(1, 0.95, 0.88, 1.0 if on_air else 0.45))
	for k: int in 16:
		var x: float = DESK.position.x + 18 + k * (DESK.size.x - 36) / 15.0
		c.draw_line(Vector2(x, DESK.position.y + 50), Vector2(x, DESK.position.y + 150), GRID_COLOR, 1.0)
		if k % 5 == 0 and k < 15:  # son çizginin etiketi masanın dışına taşmasın
			c.draw_string(font, Vector2(x + 3, DESK.position.y + 48), "0:%02d" % (k / 5 * 10), HORIZONTAL_ALIGNMENT_LEFT, -1, 10,
				Color(1, 1, 1, 0.45))
	# Zaman çizelgesi yuvaları.
	for i: int in 3:
		var r: Rect2 = _slot_rect(i)
		c.draw_style_box(CozyTheme.box(LANE_COLOR, 8, Color(1, 1, 1, 0.12), 1, false, Vector2.ZERO), r)
		c.draw_string(font, r.position + Vector2(8, 16), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.4))
		if i == _placed.size() and not on_air:
			# Sıradaki boş iz: ortasında soluk "buraya" yazısı.
			c.draw_string(font, r.position + Vector2(0, r.size.y * 0.5 + 6), tr("MG_RADIO_NEXT"), HORIZONTAL_ALIGNMENT_CENTER,
				r.size.x, 13, Color(1, 1, 1, 0.35))
		if i < _placed.size():
			_draw_clip(r, _placed[i], 1.0)
	# Alttaki klipler.
	c.draw_string(font, Vector2(DESK.position.x + 18, DESK.position.y + 200), tr("MG_RADIO_CLIPS"), HORIZONTAL_ALIGNMENT_LEFT,
		-1, 12, Color(1, 1, 1, 0.55))
	for i: int in 3:
		var piece: int = _order[i]
		if _placed.has(piece):
			continue
		var r2: Rect2 = _piece_rect(i)
		if _flash > 0.0 and piece == _flash_piece:
			r2.position.x += sin(_flash * 60.0) * 5.0
		_draw_clip(r2, piece, 1.0)
		if _flash > 0.0 and piece == _flash_piece:
			c.draw_style_box(CozyTheme.box(Color.TRANSPARENT, 8, CozyTheme.NEGATIVE, 3, false, Vector2.ZERO), r2)


## Renkli klip: yuvarlak köşeli kutu, içinde dalga (krem), üstte ince başlık şeridi.
func _draw_clip(r: Rect2, piece: int, alpha: float) -> void:
	var c: Control = _canvas
	var col: Color = Color(CLIP_COLORS[piece], alpha)
	c.draw_style_box(CozyTheme.box(col, 8, col.darkened(0.25), 2, false, Vector2.ZERO), r)
	c.draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(r.size.x - 4, 12)), col.darkened(0.18))
	var n: int = SAMPLES / 3
	var mid: float = r.position.y + 14 + (r.size.y - 14) * 0.5
	var amp: float = (r.size.y - 22) * 0.5
	for k: int in n:
		var v: float = absf(_wave[piece * n + k])
		var x: float = r.position.x + 6 + (r.size.x - 12) * float(k) / (n - 1)
		c.draw_line(Vector2(x, mid - v * amp), Vector2(x, mid + v * amp), Color(1, 0.97, 0.9, 0.95), 1.6)
