class_name Tutorial
extends Control
## İpucu balonları (M9-C, GDD 20; Orgo kararı K-074): ilk kampanyalar boyunca doğru anda çıkan, ilgili düğmeyi
## çerçeveleyen kısa balonlar. Oyunu durdurmaz, tıklamaları engellemez (balonun kendisi hariç).
## Tetikler data/tutorial.json "on": start, brief, phase, delivered, state, ui:<PencereSınıfı>.
## Görülen ipuçları ve aç/kapa Settings'te; "ipuçlarını baştan göster" ile sıfırlanır.

var _main: Control
var _queue: Array[String] = []
var _current: String = ""
var _bubble: PanelContainer
var _frame: Panel
var _text: Label


func _init(main_screen: Control) -> void:
	_main = main_screen


func _cfg() -> Dictionary:
	return DataDB.data.raw.get("tutorial.json", {})


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame = Panel.new()
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.border_color = UiUtil.MUSTARD
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(10)
	_frame.add_theme_stylebox_override("panel", sb)
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.visible = false
	add_child(_frame)
	_bubble = UiUtil.card()
	_bubble.custom_minimum_size.x = 320.0
	_bubble.visible = false
	var col: VBoxContainer = UiUtil.vbox(8)
	_bubble.add_child(col)
	col.add_child(UiUtil.label(tr("UI_TIP"), 14, UiUtil.WOOD))
	_text = UiUtil.wrapped("", 15, UiUtil.TEXT, 300.0)
	col.add_child(_text)
	var row: HBoxContainer = UiUtil.hbox()
	row.add_child(UiUtil.button(tr("UI_TIP_OFF"), func() -> void:
		Settings.set_value("tutorial", false)
		_queue.clear()
		_close()))
	row.add_child(UiUtil.spacer())
	row.add_child(UiUtil.button(tr("UI_TIP_OK"), _close))
	col.add_child(row)
	add_child(_bubble)
	EventBus.notification.connect(func(key: String, _a: Array, _k: String) -> void:
		if key == "NOTE_NEW_BRIEFS":
			trigger("brief"))
	EventBus.phase_started.connect(func(_p: int) -> void: trigger("phase"))
	EventBus.campaign_delivered.connect(func(_c: Dictionary) -> void: trigger("delivered"))
	EventBus.ui_opened.connect(func(name: String) -> void: trigger("ui:" + name))
	EventBus.state_changed.connect(func() -> void: trigger("state"))


func enabled() -> bool:
	return bool(Settings.get_value("tutorial"))


## Bu tetikteki, koşulu tutan ve görülmemiş ipuçlarını sıraya koyar.
func trigger(on: String) -> void:
	if not enabled() or not GameState.has_game():
		return
	var s: SimState = GameState.sim.state
	var done: int = s.history.size()
	for tip: Dictionary in _cfg().get("tips", []):
		var id: String = tip["id"]
		if tip["on"] != on or Settings.tutorial_seen(id) or _queue.has(id) or _current == id:
			continue
		if not bool(tip.get("any_time", false)) and done >= int(_cfg()["max_campaigns"]):
			continue
		if done < int(tip.get("min_campaigns", 0)) or s.clock.game_year() < int(tip.get("min_game_year", 0)):
			continue
		_queue.append(id)
	_show_next()


func current_tip() -> String:
	return _current


func _show_next() -> void:
	if not _current.is_empty() or _queue.is_empty():
		return
	_current = _queue.pop_front()
	var tip: Dictionary = {}
	for t: Dictionary in _cfg()["tips"]:
		if t["id"] == _current:
			tip = t
	_text.text = tr("TIP_" + _current.to_upper())
	_bubble.visible = true
	_bubble.reset_size()
	var target: Control = target_of(str(tip.get("target", "")))
	if target != null and target.is_visible_in_tree():
		var r: Rect2 = target.get_global_rect().grow(4.0)
		_frame.visible = true
		_frame.global_position = r.position
		_frame.size = r.size
		var pos: Vector2 = r.position + Vector2(r.size.x + 12.0, 0.0)
		if pos.x + _bubble.size.x > size.x:
			pos = Vector2(r.end.x - _bubble.size.x, r.end.y + 12.0)
		_bubble.global_position = pos.clamp(Vector2.ZERO, size - _bubble.size)
	else:
		_frame.visible = false
		_bubble.global_position = Vector2((size.x - _bubble.size.x) * 0.5, 90.0)
	move_to_front()


func _close() -> void:
	if not _current.is_empty():
		Settings.mark_tutorial_seen(_current)
	_current = ""
	_bubble.visible = false
	_frame.visible = false
	_show_next()


## Balonun gösterdiği düğme: "menu:<id>" (sol menü), "speed" (duraklat), "top:save" (Kaydet); yoksa null.
func target_of(name: String) -> Control:
	if name.begins_with("menu:"):
		return (_main.get("_menu_buttons") as Dictionary).get(name.trim_prefix("menu:"))
	match name:
		"speed": return _main.get("_pause_button")
		"top:save": return _main.get("_save_button")
	return null
