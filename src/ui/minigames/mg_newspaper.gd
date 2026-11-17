class_name MgNewspaper
extends MinigameGame
## Gazete (K-120): ilanı sürükleyip sayfadaki boş ilan kutusuna bırak. Ne kadar tam oturursa o kadar iyi.

const PAGE_SIZE: Vector2 = Vector2(1024, 1400)
const SLOT: Rect2 = Rect2(196, 480, 622, 548)      # gazete görselindeki boş ilan kutusu (piksel)
const PAGE_HEIGHT: float = 340.0

var _slot: Rect2
var _ad: Control
var _drag: bool = false
var _grab: Vector2
var _home: Vector2


func begin() -> void:
	stage("bg_tabletop")  # MG-2: gazete masanın üstünde
	var s: float = PAGE_HEIGHT / PAGE_SIZE.y
	var page_pos: Vector2 = Vector2(CANVAS.x - PAGE_SIZE.x * s - 60.0, 10.0)
	var page_tex: Texture2D = DraftArt.tex("props", "prop_newspaper_page")
	if page_tex != null:
		add_child(DraftArt._image(page_tex, Rect2(page_pos, PAGE_SIZE * s), TextureRect.STRETCH_SCALE))
	_slot = Rect2(page_pos + SLOT.position * s, SLOT.size * s)
	if page_tex == null:
		var hole: ColorRect = ColorRect.new()
		hole.color = CozyTheme.BORDER
		hole.position = _slot.position
		hole.size = _slot.size
		add_child(hole)
	_ad = ad_preview(_slot.size)
	_home = Vector2(70, (CANVAS.y - _slot.size.y) * 0.5 + 20.0)
	_ad.position = _home
	_ad.rotation_degrees = -4.0  # masaya atılmış gibi
	_ad.pivot_offset = _ad.size * 0.5
	add_child(_ad)
	tag(tr("MG_NEWSPAPER_DRAG"), Vector2(24, 20), 15)


func _gui_input(event: InputEvent) -> void:
	if _done:
		return
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT:
		if mb.pressed and Rect2(_ad.position, _ad.size).has_point(mb.position):
			_drag = true
			_grab = mb.position - _ad.position
			_ad.rotation_degrees = 0.0
		elif not mb.pressed and _drag:
			_drag = false
			_drop()
		accept_event()
	var mm: InputEventMouseMotion = event as InputEventMouseMotion
	if mm != null and _drag:
		_ad.position = mm.position - _grab
		accept_event()


func _drop() -> void:
	var d: float = (_ad.position + _ad.size * 0.5).distance_to(_slot.get_center())
	var tol: float = _slot.size.x * DataDB.data.balf("minigames.newspaper_tolerance") * 2.0
	if d > tol:
		shake(_ad)  # kutunun dışına bırakıldı: sarsılıp yerine döner, tekrar dene
		var back: Tween = create_tween()
		back.tween_interval(0.25)
		back.tween_property(_ad, "position", _home, 0.2).set_trans(Tween.TRANS_CUBIC)
		return
	_ad.position = _slot.position
	flash_ok(_ad)
	Audio.play("click")
	finish(1.0 - d / tol)


func time_up() -> void:
	finish(0.0)
