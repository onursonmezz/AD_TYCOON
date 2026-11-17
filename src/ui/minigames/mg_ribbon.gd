class_name MgRibbon
extends MinigameGame
## Açılış provası (K-120; etkinlik, lansman): işaret çubukta gidip gelirken yeşil bölgeye geldiğinde kurdeleyi kes
## ("Kes", tıklama ya da boşluk). Ortaya ne kadar yakınsa o kadar iyi.

const BAR: Rect2 = Rect2(120, 268, 400, 16)

var _t: float = 0.0
var _marker: ColorRect
var _ribbon: TextureRect


func begin() -> void:
	stage("bg_street")  # MG-2: dükkânın önü
	tag(str(ctx["brand"]), Vector2(CANVAS.x * 0.5 - 90, 14), 20)
	var t: Texture2D = DraftArt.tex("props", "prop_ribbon_scissors")
	if t != null:
		_ribbon = DraftArt._image(t, Rect2(40, 70, CANVAS.x - 80, 180), TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
		add_child(_ribbon)
	var bar: Panel = Panel.new()
	bar.position = BAR.position
	bar.size = BAR.size
	bar.add_theme_stylebox_override("panel", CozyTheme.box(CozyTheme.CREAM_LIGHT, 999, CozyTheme.BORDER, 2, false, Vector2.ZERO))
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)
	var win: float = BAR.size.x * DataDB.data.balf("minigames.ribbon_window")
	var zone: ColorRect = ColorRect.new()
	zone.color = Color(CozyTheme.FOREST_LIGHT, 0.45)
	zone.position = Vector2(BAR.get_center().x - win, BAR.position.y)
	zone.size = Vector2(win * 2.0, BAR.size.y)
	zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(zone)
	_marker = ColorRect.new()
	_marker.color = CozyTheme.NEGATIVE
	_marker.size = Vector2(4, BAR.size.y + 14)
	_marker.position = Vector2(BAR.position.x, BAR.position.y - 7)
	_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_marker)
	var cut: Button = UiUtil.button(tr("MG_RIBBON_CUT"), _cut)
	cut.theme_type_variation = "PrimaryButton"
	cut.custom_minimum_size = Vector2(140, 36)
	cut.position = Vector2(CANVAS.x * 0.5 - 70, 302)
	add_child(cut)


func _process(delta: float) -> void:
	if _done or _marker == null:
		return
	_t += delta / DataDB.data.balf("minigames.ribbon_seconds")
	var x: float = pingpong(_t, 1.0)
	_marker.position.x = BAR.position.x + x * BAR.size.x - 2.0


func _gui_input(event: InputEvent) -> void:
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		_cut()
		accept_event()


func _unhandled_key_input(event: InputEvent) -> void:
	var k: InputEventKey = event as InputEventKey
	if k != null and k.pressed and not k.echo and k.keycode == KEY_SPACE and is_visible_in_tree():
		_cut()
		get_viewport().set_input_as_handled()


func _cut() -> void:
	if _done:
		return
	var d: float = absf(_marker.position.x + 2.0 - BAR.get_center().x)
	if _ribbon != null:
		create_tween().tween_property(_ribbon, "scale", Vector2(1.05, 0.9), 0.1)
	finish(1.0 - d / (BAR.size.x * 0.4))
