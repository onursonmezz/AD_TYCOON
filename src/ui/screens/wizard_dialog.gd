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
var _estimate: Label
var _mix: MixEditor
var _team_checks: Dictionary = {}
var _error: Label


func _init(brief: Dictionary, main_screen: Control) -> void:
	_brief = brief
	_main = main_screen


func _ready() -> void:
	var data: GameData = DataDB.data
	var s: SimState = GameState.sim.state
	var col: VBoxContainer = UiUtil.modal_frame(self, Vector2(720.0, 440.0))
	var client: Dictionary = _brief["prospect"] if not (_brief["prospect"] as Dictionary).is_empty() \
		else s.clients.get(_brief["client_id"], {})
	col.add_child(UiUtil.heading(tr("UI_WIZARD_NEW"), "speakerphone"))
	# UI-3 (taslak 05): üstte müşteri ve üç bilgi; altında iki sütun (kampanya bilgileri | medya planı + ekip).
	var top: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
	var head: HBoxContainer = Cards.header(Cards.tile("building", 44.0, CozyTheme.TERRA_SOFT), str(client.get("name", "")),
		"%s · %s" % [UiUtil.name_of(data.sectors, _brief["sector"]), tr("SIZE_" + str(_brief["size"]).to_upper())])
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(head)
	var facts: HBoxContainer = Cards.facts([
		Cards.fact("coins", tr("UI_FACT_FEE"), UiUtil.money(_brief["fee"])),
		Cards.fact("speakerphone", tr("UI_FACT_MEDIA"), UiUtil.money(_brief["media_budget"])),
		Cards.fact("calendar", tr("UI_FACT_DURATION"), tr("UI_WEEKS") % int(_brief["deadline_weeks"]))])
	facts.custom_minimum_size.x = 400.0
	top.add_child(facts)
	col.add_child(top)
	var advance: float = GameState.sim.economy.media_advance(client, float(_brief["media_budget"]))
	if advance > 0.0:
		col.add_child(UiUtil.label(tr("UI_MEDIA_ADVANCE") % UiUtil.money(advance), 13, UiUtil.SAGE_DARK))
	col.add_child(HSeparator.new())
	var cols: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_L)
	col.add_child(cols)
	var left: VBoxContainer = UiUtil.vbox(4)
	left.custom_minimum_size.x = 280.0
	cols.add_child(left)
	cols.add_child(VSeparator.new())
	var right: VBoxContainer = UiUtil.vbox(CozyTheme.SPACE_S)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(right)
	left.add_child(Cards.section(tr("UI_CAMPAIGN_INFO")))
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = tr("UI_CAMPAIGN_NAME_HINT")
	_name_edit.max_length = 40
	_add_row(left, "UI_CAMPAIGN_NAME", _name_edit)
	_objective = OptionButton.new()
	if str(_brief["objective"]).is_empty():
		for id: String in data.objective_ids:
			_objective.add_item(UiUtil.name_of(data.objectives, id))
	else:
		_objective.add_item(UiUtil.name_of(data.objectives, _brief["objective"]))
		_objective.disabled = true
	_add_row(left, "UI_OBJECTIVE", _objective)
	_audience = _option_for(data.audiences, data.audience_ids)
	_add_row(left, "UI_AUDIENCE", _audience)
	_tone = _option_for(data.tones, data.tone_ids)
	_add_row(left, "UI_TONE", _tone)
	# Araştırılmadıysa (GDD 17) otomatik: seçim kapalı, nötr sayılır; gereken araştırma altında yazar.
	_lock_unless(_audience, "audience_analysis", "UI_AUTO_AUDIENCE")
	_lock_unless(_tone, "tone_choice", "UI_AUTO_TONE")
	var free_staff: Array = []
	for emp: Dictionary in s.staff.values():
		if Employee.is_available(emp, s.clock.week_index):
			free_staff.append(emp["id"])
	_mix = MixEditor.new(_brief, GameState.sim.media.channel_limit(s, free_staff), _main)
	right.add_child(_mix)
	right.add_child(Cards.section(tr("UI_TEAM_PICK")))
	for emp: Dictionary in s.staff.values():
		var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
		var check: CheckBox = CheckBox.new()
		UiUtil.style_toggle(check)
		var available: bool = Employee.is_available(emp, s.clock.week_index)
		check.button_pressed = available
		check.disabled = not available
		_team_checks[emp["id"]] = check
		row.add_child(check)
		var pic: PanelContainer = Cards.avatar(emp, 32.0)
		pic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(pic)
		var who: VBoxContainer = UiUtil.vbox(-3)
		var name: Label = UiUtil.label(GameState.employee_name(emp), 14, CozyTheme.FOREST if available else CozyTheme.MUTED)
		name.add_theme_font_override("font", CozyTheme.strong_font())
		who.add_child(name)
		who.add_child(UiUtil.label(tr(Employee.title_key(data, emp)), 12, CozyTheme.MUTED))
		row.add_child(who)
		right.add_child(row)
	col.add_child(HSeparator.new())
	_error = UiUtil.label("", 14, UiUtil.TERRACOTTA)
	_error.visible = false
	col.add_child(_error)
	var buttons: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	buttons.add_child(UiUtil.icon("alert-triangle", 16, CozyTheme.MUTED))
	var hint: Label = UiUtil.wrapped(tr("UI_WIZARD_HINT"), 12, UiUtil.MUTED, 200.0)
	hint.tooltip_text = tr("UI_WIZARD_HINT")
	buttons.add_child(hint)
	if GameState.sim.research.has(GameState.sim.state, "focus_group"):
		_estimate = UiUtil.label("", 13, UiUtil.WOOD)
		buttons.add_child(UiUtil.button(tr("UI_FOCUS_GROUP"), _on_focus_group))
		buttons.add_child(_estimate)
	buttons.add_child(UiUtil.button(tr("UI_CANCEL"), queue_free))
	var start: Button = UiUtil.button(tr("UI_START_CAMPAIGN"), _on_start)
	start.theme_type_variation = "PrimaryButton"
	buttons.add_child(start)
	col.add_child(buttons)


func _fail(key: String) -> void:
	_error.text = tr(key)
	_error.visible = true


func _lock_unless(o: OptionButton, research_id: String, key: String) -> void:
	if GameState.sim.research.has(GameState.sim.state, research_id):
		return
	o.clear()
	o.add_item(tr(key))
	o.disabled = true


## Fokus Grup (GDD 17): yayından önce kombinasyonun uyumuna dair kaba bir tahmin (iyi / orta / zayıf).
func _on_focus_group() -> void:
	var sim: Simulation = GameState.sim
	var mix: Array = _mix.get_mix()
	if mix.is_empty():
		return
	var client: Dictionary = _brief["prospect"] if not (_brief["prospect"] as Dictionary).is_empty() \
		else sim.state.clients.get(_brief["client_id"], {})
	var setup: Dictionary = {"sector": _brief["sector"], "mix": mix,
		"objective": DataDB.data.objective_ids[_objective.selected] if not _objective.disabled else _brief["objective"],
		"audience": DataDB.data.audience_ids[_audience.selected] if not _audience.disabled else "",
		"tone": DataDB.data.tone_ids[_tone.selected] if not _tone.disabled else ""}
	var m: float = float(sim.scoring.combination(setup, client)["m"])
	var band: String = "GOOD" if m >= DataDB.data.balf("research.focus_good") \
		else ("WEAK" if m < DataDB.data.balf("research.focus_weak") else "MID")
	_estimate.text = tr("UI_FOCUS_" + band)


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


## Alan: üstte kalın başlık, altında denetim (dar sütuna sığsın).
func _add_row(col: VBoxContainer, key: String, control: Control) -> void:
	var l: Label = UiUtil.label(tr(key), 13, CozyTheme.FOREST)
	l.add_theme_font_override("font", CozyTheme.strong_font())
	col.add_child(l)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if control is OptionButton:
		(control as OptionButton).fit_to_longest_item = false
		(control as OptionButton).clip_text = true
	col.add_child(control)


func _on_start() -> void:
	var data: GameData = DataDB.data
	var mix: Array = _mix.get_mix()
	if mix.is_empty():
		_fail("ERR_CHANNEL")
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
		_fail("ERR_TEAM_EMPTY")
		return
	var result: Dictionary = GameState.execute(StartCampaignCommand.new(_brief["id"], choices))
	if not bool(result["ok"]):
		_fail(str(result["error"]))
		return
	_main.call("show_panel", "campaign")
	queue_free()
