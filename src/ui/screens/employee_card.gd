class_name EmployeeCard
extends PanelContainer
## Ofiste tıklanan çalışanın küçük kartı (M6): ad, unvan, enerji, moral, ne yaptığı; Ekip penceresine geçiş.

var _emp_id: String
var _on_open_team: Callable
var _info: Label


func _init(emp_id: String, on_open_team: Callable) -> void:
	_emp_id = emp_id
	_on_open_team = on_open_team


func _ready() -> void:
	custom_minimum_size = Vector2(280.0, 0.0)
	var col: VBoxContainer = UiUtil.vbox(4)
	add_child(col)
	var emp: Dictionary = GameState.sim.state.staff.get(_emp_id, {})
	var top: HBoxContainer = UiUtil.hbox()
	top.add_child(UiUtil.label(GameState.employee_name(emp), 17, UiUtil.SAGE_DARK))
	top.add_child(UiUtil.spacer())
	var close: Button = Button.new()
	close.text = "✕"
	close.pressed.connect(queue_free)
	top.add_child(close)
	col.add_child(top)
	col.add_child(UiUtil.label(tr(Employee.title_key(DataDB.data, emp)), 14, UiUtil.WOOD))
	_info = UiUtil.label("", 14)
	col.add_child(_info)
	var buttons: HBoxContainer = UiUtil.hbox()
	buttons.add_child(UiUtil.spacer())
	buttons.add_child(UiUtil.button(tr("UI_OPEN_TEAM"), func() -> void:
		_on_open_team.call()
		queue_free()))
	col.add_child(buttons)
	EventBus.state_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	if not GameState.has_game() or not GameState.sim.state.staff.has(_emp_id):
		queue_free()
		return
	var s: SimState = GameState.sim.state
	var emp: Dictionary = s.staff[_emp_id]
	_info.text = tr("UI_EMP_CARD") % [int(float(emp["energy"])), int(float(emp["morale"])), tr(_status_key(s, emp))]


func _status_key(s: SimState, emp: Dictionary) -> String:
	var week: int = s.clock.week_index
	if int(emp.get("busy_until", -1)) > week:
		return "UI_EMP_AWAY"
	if int(emp.get("pitch_until", -1)) > week:
		return "UI_EMP_PITCH"
	if (s.active_campaign.get("setup", {}).get("team", []) as Array).has(emp["id"]):
		return "UI_EMP_CAMPAIGN"
	return "UI_EMP_IDLE"
