class_name MgNewspaper
extends MinigameGame
## Gazete (K-120, S3E): masada üç gazete; birinin ilan yeri dikey, birininki fazla enine, birininki ilana tam uyan
## boyda. İlanı doğru gazeteye sürükle. Yanlış gazeteye bırakılan ilan sarsılıp geri döner (hata sayılır);
## doğrusunda ilan yerine oturur. Başarı: hata sayısı ve ilanın ne kadar tam bırakıldığı.

const PAGE_SIZE: Vector2 = Vector2(1024, 1400)
const SLOT: Rect2 = Rect2(196, 480, 622, 548)      # gazete görselindeki ilan kutusu (piksel), doğru oran
const BAND: Rect2 = Rect2(84, 466, 858, 578)       # ilan kutusu ve iki yanındaki yazı sütunları (yeniden çizilir)
const SHAPES: Dictionary = {"right": Vector2(622, 548), "tall": Vector2(330, 548), "wide": Vector2(840, 290)}
const PAGE_HEIGHT: float = 206.0
const PAGE_GAP: float = 12.0
const AD_SCALE: float = 1.45  # masadaki ilan, gazetedekinden büyük görünür
const PAPER: Color = Color("f7e7cb")
const INK: Color = Color(0.45, 0.48, 0.42, 0.55)

var _slots: Array[Rect2] = []
var _pages: Array[Rect2] = []
var _right: int = 0
var _ad: Control
var _drag: bool = false
var _grab: Vector2
var _home: Vector2
var _mistakes: int = 0


func begin() -> void:
	stage("bg_tabletop")  # MG-2: gazeteler masanın üstünde
	var s: float = PAGE_HEIGHT / PAGE_SIZE.y
	var order: Array = SHAPES.keys()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(ctx["seed"])
	for i: int in range(order.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: Variant = order[i]
		order[i] = order[j]
		order[j] = tmp
	var page_w: float = PAGE_SIZE.x * s
	var x0: float = CANVAS.x - 3.0 * page_w - 2.0 * PAGE_GAP - 16.0
	var y: float = CANVAS.y - PAGE_HEIGHT - 18.0
	var page_tex: Texture2D = DraftArt.tex("props", "prop_newspaper_page")
	for i: int in 3:
		var pos: Vector2 = Vector2(x0 + i * (page_w + PAGE_GAP), y)
		var page: Control = Control.new()
		page.position = pos
		page.size = PAGE_SIZE * s
		page.rotation_degrees = [-2.0, 1.0, -1.0][i]  # masaya gelişigüzel konmuş
		page.pivot_offset = page.size * 0.5
		page.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if page_tex != null:
			page.add_child(DraftArt._image(page_tex, Rect2(Vector2.ZERO, page.size), TextureRect.STRETCH_SCALE))
		var shape: Vector2 = SHAPES[str(order[i])]
		var slot_local: Rect2 = Rect2(SLOT.get_center() - shape * 0.5, shape)
		page.add_child(_band(s, slot_local))
		add_child(page)
		_pages.append(Rect2(pos, page.size))
		_slots.append(Rect2(pos + slot_local.position * s, slot_local.size * s))
		if str(order[i]) == "right":
			_right = i
	var slot_size: Vector2 = _slots[_right].size
	_ad = ad_preview(slot_size)
	_ad.pivot_offset = Vector2.ZERO
	_ad.scale = Vector2(AD_SCALE, AD_SCALE)
	_home = Vector2(18.0, y + 16.0)
	_ad.position = _home
	add_child(_ad)
	tag(tr("MG_NEWSPAPER_DRAG"), Vector2(24, 20), 15)


## Ortadaki bant: kâğıt rengiyle örtülür, yeni boyda boş ilan yeri ve çevresinde yazı satırları çizilir.
func _band(s: float, slot: Rect2) -> Control:
	var band: Control = Control.new()
	band.position = BAND.position * s
	band.size = BAND.size * s
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.draw.connect(func() -> void:
		band.draw_rect(Rect2(Vector2.ZERO, band.size), PAPER)
		var local: Rect2 = Rect2((slot.position - BAND.position) * s, slot.size * s)
		var line_h: float = 3.0
		var y: float = 2.0
		while y < band.size.y - line_h:
			var row: Rect2 = Rect2(0.0, y, band.size.x, line_h)
			if not row.intersects(local.grow(4.0)):
				band.draw_rect(Rect2(2.0, y, band.size.x - 4.0, line_h), INK)
			else:
				if local.position.x - 6.0 > 4.0:
					band.draw_rect(Rect2(2.0, y, local.position.x - 8.0, line_h), INK)
				if band.size.x - local.end.x - 6.0 > 4.0:
					band.draw_rect(Rect2(local.end.x + 6.0, y, band.size.x - local.end.x - 8.0, line_h), INK)
			y += 7.0
		band.draw_rect(local, Color("fbf1df"))
		band.draw_rect(local, Color("c9a77a"), false, 1.5))
	return band


func _gui_input(event: InputEvent) -> void:
	if _done:
		return
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT:
		if mb.pressed and Rect2(_ad.position, _ad.size * _ad.scale).has_point(mb.position):
			_drag = true
			_grab = mb.position - _ad.position
		elif not mb.pressed and _drag:
			_drag = false
			_drop()
		accept_event()
	var mm: InputEventMouseMotion = event as InputEventMouseMotion
	if mm != null and _drag:
		_ad.position = mm.position - _grab
		accept_event()


func _drop() -> void:
	var center: Vector2 = _ad.position + _ad.size * _ad.scale * 0.5
	var hit: int = -1
	for i: int in _pages.size():
		if _pages[i].grow(10.0).has_point(center):
			hit = i
	if hit != _right:
		if hit >= 0:
			_mistakes += 1  # yanlış gazete: ilan oraya sığmıyor
		shake(_ad)
		var back: Tween = create_tween()
		back.tween_interval(0.25)
		back.tween_property(_ad, "position", _home, 0.2).set_trans(Tween.TRANS_CUBIC)
		return
	var slot: Rect2 = _slots[_right]
	var off: float = center.distance_to(slot.get_center()) / maxf(1.0, _pages[_right].size.x)
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(_ad, "position", slot.position, 0.18).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(_ad, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_CUBIC)
	flash_ok(_ad)
	Audio.play("click")
	finish(clampf(1.0 - DataDB.data.balf("minigames.newspaper_mistake_cost") * _mistakes - off * 0.5, 0.0, 1.0))


func time_up() -> void:
	finish(0.0)
