class_name PitchInviteDialog
extends Control
## İhaleye katılım (GDD 14.2): pitch ekibi ve ücret teklifi. Ekip hazırlık bitene kadar kampanyada çalışmaz.

var _invite: Dictionary
var _team_checks: Dictionary = {}
var _fee_ratio: float = 1.0
var _fee_buttons: Array[Button] = []
var _error: Label


func _init(invite: Dictionary) -> void:
	_invite = invite


## Davet özeti (gelen kutusu kartında da kullanılır): rakipler, hazırlık süresi, katılım ücreti.
static func summary(inv: Dictionary) -> String:
	var names: Array[String] = []
	for rid: Variant in inv["rivals"]:
		names.append(UiUtil.name_of(DataDB.data.rivals, str(rid)))
	var text: String = UiUtil.tr_fmt("UI_PITCH_SUMMARY", [int(inv["prep_weeks"]), ", ".join(names)])
	if float(inv["participation_fee"]) > 0.0:
		text += " " + UiUtil.tr_fmt("UI_PITCH_PAID", [UiUtil.money(float(inv["participation_fee"]))])
	return text


func _ready() -> void:
	var data: GameData = DataDB.data
	var s: SimState = GameState.sim.state
	var col: VBoxContainer = UiUtil.modal_frame(self, Vector2(700.0, 480.0))
	col.add_child(UiUtil.heading(tr("UI_PITCH_INVITE_TITLE") % _invite["client"]["name"], "inbox"))
	col.add_child(UiUtil.wrapped(summary(_invite), 15, UiUtil.TEXT, 640.0))
	col.add_child(UiUtil.wrapped(tr("UI_PITCH_HOW"), 14, UiUtil.MUTED, 640.0))
	col.add_child(UiUtil.label(tr("UI_PITCH_TEAM"), 16))
	var busy: Array = s.active_campaign.get("setup", {}).get("team", [])
	var team_box: HFlowContainer = HFlowContainer.new()
	for emp: Dictionary in s.staff.values():
		var check: CheckBox = CheckBox.new()
		check.text = tr("UI_PITCH_MEMBER") % [GameState.employee_name(emp), tr(Employee.title_key(data, emp)),
			int(emp["stats"]["communication"])]
		if busy.has(emp["id"]):
			check.text += " ⚠"
			check.tooltip_text = tr("UI_PITCH_ON_CAMPAIGN")
		UiUtil.style_toggle(check)
		check.disabled = not Employee.is_available(emp, s.clock.week_index)
		check.button_pressed = not check.disabled and not busy.has(emp["id"])
		_team_checks[emp["id"]] = check
		team_box.add_child(check)
	col.add_child(team_box)
	col.add_child(UiUtil.label(tr("UI_PITCH_FEE"), 16))
	var fee_row: HBoxContainer = UiUtil.hbox()
	for ratio: Variant in data.bal("pitch.fee_options"):
		var r: float = float(ratio)
		var b: Button = UiUtil.button(tr("UI_PITCH_FEE_%d" % int(roundf(r * 100.0))), func() -> void: _set_fee(r))
		b.toggle_mode = true
		b.set_meta("ratio", r)
		_fee_buttons.append(b)
		fee_row.add_child(b)
	col.add_child(fee_row)
	col.add_child(UiUtil.wrapped(tr("UI_PITCH_FEE_HINT"), 13, UiUtil.MUTED, 640.0))
	_set_fee(1.0)
	_error = UiUtil.label("", 15, UiUtil.TERRACOTTA)
	col.add_child(_error)
	var buttons: HBoxContainer = UiUtil.hbox()
	buttons.add_child(UiUtil.spacer())
	buttons.add_child(UiUtil.button(tr("UI_CANCEL"), queue_free))
	buttons.add_child(UiUtil.button(tr("UI_PITCH_START"), _on_start))
	col.add_child(buttons)


func _set_fee(ratio: float) -> void:
	_fee_ratio = ratio
	for b: Button in _fee_buttons:
		b.set_pressed_no_signal(is_equal_approx(float(b.get_meta("ratio")), ratio))


func _on_start() -> void:
	var team: Array = []
	for id: Variant in _team_checks:
		if (_team_checks[id] as CheckBox).button_pressed:
			team.append(id)
	var err: String = GameState.execute(AcceptPitchCommand.new(_invite["id"], team, _fee_ratio))
	if err.is_empty():
		EventBus.notification.emit("NOTE_PITCH_STARTED", [_invite["client"]["name"], int(_invite["prep_weeks"])], "info")
		queue_free()
	else:
		_error.text = tr(err)
