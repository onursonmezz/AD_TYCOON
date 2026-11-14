class_name MgSponsor
extends MinigameGame
## Sponsorluk provası (K-120): marka rozetini sürükleyip formanın göğüs alanına bırak. Ne kadar ortadaysa o kadar iyi.

const JERSEY: Vector2 = Vector2(1024, 1024)
const CHEST: Rect2 = Rect2(370, 330, 290, 190)      # forma görselinde göğüs alanı (piksel, yaklaşık)
const BADGE: float = 96.0

var _zone: Rect2
var _badge: Control
var _drag: bool = false
var _grab: Vector2


func begin() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.color = CozyTheme.SAGE_SOFT.lightened(0.45)
	bg.size = CANVAS
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var s: float = (CANVAS.y - 10.0) / JERSEY.y
	var pos: Vector2 = Vector2(CANVAS.x - JERSEY.x * s - 40.0, 5.0)
	var t: Texture2D = DraftArt.tex("props", "prop_jersey")
	if t != null:
		add_child(DraftArt._image(t, Rect2(pos, JERSEY * s), TextureRect.STRETCH_SCALE))
	_zone = Rect2(pos + CHEST.position * s, CHEST.size * s)
	var outline: ReferenceRect = ReferenceRect.new()
	outline.border_color = Color(CozyTheme.FOREST, 0.7)
	outline.border_width = 2.0
	outline.editor_only = false
	outline.position = _zone.position
	outline.size = _zone.size
	outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(outline)
	_badge = _make_badge()
	_badge.position = Vector2(70, (CANVAS.y - BADGE) * 0.5)
	add_child(_badge)


## Yuvarlak marka rozeti: marka renginde daire, ortada ürün, altta marka adı.
func _make_badge() -> Control:
	var c: Panel = Panel.new()
	c.size = Vector2(BADGE, BADGE)
	c.add_theme_stylebox_override("panel", CozyTheme.box(CozyTheme.CREAM_LIGHT, 999, ctx["accent"], 4, false, Vector2.ZERO))
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var draft: Dictionary = DraftArt.options(DataDB.data, ctx["setup"], int(ctx["year"]), int(ctx["seed"]))[0]
	var p: Texture2D = DraftArt.tex("products", str(draft["product"]))
	if p != null:
		c.add_child(DraftArt._image(p, Rect2(Vector2(18, 10), Vector2(BADGE - 36, BADGE * 0.5)), TextureRect.STRETCH_KEEP_ASPECT_CENTERED))
	DraftArt._text(c, str(ctx["brand"]), 11, CozyTheme.FOREST, Rect2(Vector2(8, BADGE * 0.58), Vector2(BADGE - 16, BADGE * 0.3)))
	return c


func _gui_input(event: InputEvent) -> void:
	if _done:
		return
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT:
		if mb.pressed and Rect2(_badge.position, _badge.size).has_point(mb.position):
			_drag = true
			_grab = mb.position - _badge.position
		elif not mb.pressed and _drag:
			_drag = false
			_drop()
		accept_event()
	var mm: InputEventMouseMotion = event as InputEventMouseMotion
	if mm != null and _drag:
		_badge.position = mm.position - _grab
		accept_event()


func _drop() -> void:
	var d: float = (_badge.position + _badge.size * 0.5).distance_to(_zone.get_center())
	var tol: float = _zone.size.x * 0.75
	if d > tol:
		return  # alanın dışı; tekrar dene
	Audio.play("click")
	finish(1.0 - d / tol)
