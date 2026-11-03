class_name WizardDialog
extends Control
## Kampanya sihirbazı (GDD 7.1, 20): ad, hedef (serbestse), kitle, ton, kanal karışımı, ekip. Büyüklük brief'ten gelir.
## Uyum tabloları gizlidir (GDD 8): burada hiçbir uyum değeri gösterilmez.

var _brief: Dictionary
var _main: Control
var _name_edit: LineEdit
var _objective: OptionButton
var _audience: OptionButton
var _tone: OptionButton
var _mix: MixEditor
var _team_checks: Dictionary = {}
var _error: Label


func _init(brief: Dictionary, main_screen: Control) -> void:
	_brief = brief
	_main = main_screen


func _ready() -> void:
	var data: GameData = DataDB.data
	var s: SimState = GameState.sim.state
	var col: VBoxContainer = UiUtil.modal_frame(self, Vector2(860.0, 640.0))
	var client: Dictionary = _brief["prospect"] if not (_brief["prospect"] as Dictionary).is_empty() \
		else s.clients.get(_brief["client_id"], {})
	col.add_child(UiUtil.heading(tr("UI_WIZARD_TITLE") % str(client.get("name", ""))))
	col.add_child(UiUtil.label("%s · %s · %s" % [UiUtil.name_of(data.sectors, _brief["sector"]),
		tr("SIZE_" + str(_brief["size"]).to_upper()), tr("UI_WEEKS") % int(_brief["deadline_weeks"])], 15, UiUtil.WOOD))
	col.add_child(UiUtil.label(tr("UI_BRIEF_MONEY") % [UiUtil.money(_brief["fee"]), UiUtil.money(_brief["media_budget"]),
		int(_brief["deadline_weeks"])], 15))
	var advance: float = GameState.sim.economy.media_advance(client, float(_brief["media_budget"]))
	if advance > 0.0:
		col.add_child(UiUtil.label(tr("UI_MEDIA_ADVANCE") % UiUtil.money(advance), 14, UiUtil.SAGE_DARK))
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = tr("UI_CAMPAIGN_NAME_HINT")
	_name_edit.max_length = 40
	_add_row(col, "UI_CAMPAIGN_NAME", _name_edit)
	_objective = OptionButton.new()
	if str(_brief["objective"]).is_empty():
		for id: String in data.objective_ids:
			_objective.add_item(UiUtil.name_of(data.objectives, id))
	else:
		_objective.add_item(UiUtil.name_of(data.objectives, _brief["objective"]))
		_objective.disabled = true
	_add_row(col, "UI_OBJECTIVE", _objective)
	_audience = _option_for(data.audiences, data.audience_ids)
	_add_row(col, "UI_AUDIENCE", _audience)
	_tone = _option_for(data.tones, data.tone_ids)
	_add_row(col, "UI_TONE", _tone)
	var free_staff: Array = []
	for emp: Dictionary in s.staff.values():
		if Employee.is_available(emp, s.clock.week_index):
			free_staff.append(emp["id"])
	_mix = MixEditor.new(_brief, GameState.sim.media.channel_limit(s, free_staff), _main)
	col.add_child(_mix)
	col.add_child(UiUtil.label(tr("UI_TEAM_PICK"), 16))
	var team_box: HFlowContainer = HFlowContainer.new()
	for emp: Dictionary in s.staff.values():
		var check: CheckBox = CheckBox.new()
		check.text = "%s (%s)" % [GameState.employee_name(emp), tr(Employee.title_key(data, emp))]
		UiUtil.style_toggle(check)
		var available: bool = Employee.is_available(emp, s.clock.week_index)
		check.button_pressed = available
		check.disabled = not available
		_team_checks[emp["id"]] = check
		team_box.add_child(check)
	col.add_child(team_box)
	col.add_child(UiUtil.wrapped(tr("UI_WIZARD_HINT"), 14, UiUtil.MUTED, 560.0))
	_error = UiUtil.label("", 15, UiUtil.TERRACOTTA)
	col.add_child(_error)
	var buttons: HBoxContainer = UiUtil.hbox()
	buttons.add_child(UiUtil.spacer())
	buttons.add_child(UiUtil.button(tr("UI_CANCEL"), queue_free))
	buttons.add_child(UiUtil.button(tr("UI_START_CAMPAIGN"), _on_start))
	col.add_child(buttons)


func _picked_team() -> Array:
	var team: Array = []
	for id: Variant in _team_checks:
		if (_team_checks[id] as CheckBox).button_pressed:
			team.append(id)
	return team


func _option_for(table: Dictionary, ids: Array[String]) -> OptionButton:
	var o: OptionButton = OptionButton.new()
	for id: String in ids:
		o.add_item(UiUtil.name_of(table, id))
	return o


func _add_row(col: VBoxContainer, key: String, control: Control) -> void:
	var row: HBoxContainer = UiUtil.hbox()
	var l: Label = UiUtil.label(tr(key), 16)
	l.custom_minimum_size.x = 160.0
	row.add_child(l)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	col.add_child(row)


func _on_start() -> void:
	var data: GameData = DataDB.data
	var mix: Array = _mix.get_mix()
	if mix.is_empty():
		_error.text = tr("ERR_CHANNEL")
		return
	var choices: Dictionary = {
		"name": _name_edit.text.strip_edges(),
		"objective": data.objective_ids[_objective.selected] if not _objective.disabled else _brief["objective"],
		"audience": data.audience_ids[_audience.selected],
		"tone": data.tone_ids[_tone.selected],
		"mix": mix,
		"team": _picked_team(),
	}
	if (choices["team"] as Array).is_empty():
		_error.text = tr("ERR_TEAM_EMPTY")
		return
	var result: Dictionary = GameState.execute(StartCampaignCommand.new(_brief["id"], choices))
	if not bool(result["ok"]):
		_error.text = tr(str(result["error"]))
		return
	_main.call("show_panel", "campaign")
	queue_free()
