class_name MgAudience
extends MinigameGame
## Hedef kitle provası (K-120, strateji fazı): brief'in hedef kitlesine uyan kişilere tıkla. Hepsi seçilince biter;
## yanlış kişi başarıdan götürür. Eşleme balance.json minigames.audience_targets.

const PEOPLE: Array[String] = ["young", "adult", "mature", "business", "kid", "family"]
const FIG: Vector2 = Vector2(92, 210)

var _targets: Array = []
var _chosen: Array[String] = []
var _mistakes: int = 0
var _figs: Dictionary = {}


func begin() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.color = CozyTheme.SAGE_SOFT.lightened(0.45)
	bg.size = CANVAS
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var aud: String = str((ctx["setup"] as Dictionary).get("audience", ""))
	_targets = (DataDB.data.bal("minigames.audience_targets") as Dictionary).get(aud, ["adult", "young"])
	var name: String = UiUtil.name_of(DataDB.data.audiences, aud) if DataDB.data.audiences.has(aud) else tr("MG_AUDIENCE_BROAD")
	var tag: PanelContainer = Cards.chip(tr("MG_AUDIENCE_TARGET") % name, CozyTheme.CREAM_LIGHT, CozyTheme.FOREST)
	tag.position = Vector2(CANVAS.x * 0.5 - 90, 12)
	add_child(tag)
	var order: Array = PEOPLE.duplicate()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(ctx["seed"])
	for i: int in range(order.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: Variant = order[i]
		order[i] = order[j]
		order[j] = tmp
	for i: int in order.size():
		var who: String = str(order[i])
		var holder: Control = Control.new()
		holder.position = Vector2(14 + i * (FIG.x + 7), 64)
		holder.size = FIG + Vector2(0, 24)
		holder.mouse_filter = Control.MOUSE_FILTER_STOP
		holder.gui_input.connect(_on_pick.bind(who))
		var ring: Panel = Panel.new()
		ring.add_theme_stylebox_override("panel", CozyTheme.box(Color(CozyTheme.FOREST_LIGHT, 0.0), 999,
			CozyTheme.FOREST_LIGHT, 3, false, Vector2.ZERO))
		ring.position = Vector2(8, FIG.y - 4)
		ring.size = Vector2(FIG.x - 16, 24)
		ring.visible = false
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(ring)
		var t: Texture2D = DraftArt.tex("props", "prop_person_" + who)
		if t != null:
			holder.add_child(DraftArt._image(t, Rect2(Vector2.ZERO, FIG), TextureRect.STRETCH_KEEP_ASPECT_CENTERED))
		add_child(holder)
		_figs[who] = [holder, ring]


func _on_pick(event: InputEvent, who: String) -> void:
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if _done or mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT or _chosen.has(who):
		return
	if _targets.has(who):
		_chosen.append(who)
		(_figs[who][1] as Panel).visible = true
		Audio.play("click")
		if _chosen.size() == _targets.size():
			finish(1.0 - 0.34 * _mistakes)
	else:
		_mistakes += 1
		var tw: Tween = create_tween()
		tw.tween_property(_figs[who][0], "modulate", Color(1, 0.6, 0.6), 0.08)
		tw.tween_property(_figs[who][0], "modulate", Color.WHITE, 0.2)


func time_up() -> void:
	finish(float(_chosen.size()) / maxf(1.0, float(_targets.size())) * 0.5 * (1.0 - 0.34 * _mistakes))
