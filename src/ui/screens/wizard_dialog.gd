class_name WizardDialog
extends Control
## Kampanya sihirbazı (GDD 7.1, 20): ad, hedef (serbestse), kitle, ton, kanal karışımı, ekip. Büyüklük brief'ten gelir.
## Uyum tabloları gizlidir (GDD 8): burada hiçbir uyum değeri gösterilmez.

var _brief: Dictionary
var _main: Control
var _name_edit: LineEdit
## S10: hedef, kitle ve ton açılır menü değil, çizimli seçim paneli (OptionPickerDialog); seçili kimlikler burada.
var _objective: String = ""
var _audience: String = ""
var _tone: String = ""
var _brief_box: VBoxContainer
var _estimate: Label
var _mix: MixEditor
var _team_checks: Dictionary = {}
var _plan: TaskPlanDialog
var _error: Label


func _init(brief: Dictionary, main_screen: Control) -> void:
	_brief = brief
	_main = main_screen


func _ready() -> void:
	var data: GameData = DataDB.data
	var s: SimState = GameState.sim.state
	var col: VBoxContainer = UiUtil.modal_frame(self, UiUtil.dialog_size("wizard") - Vector2(0.0, 62.0), true, true)
	var client: Dictionary = _brief["prospect"] if not (_brief["prospect"] as Dictionary).is_empty() \
		else s.clients.get(_brief["client_id"], {})
	col.add_child(UiUtil.heading(tr("UI_WIZARD_NEW"), "speakerphone"))
	# UI-3 (taslak 05): üstte müşteri ve üç bilgi; altında iki sütun (kampanya bilgileri | medya planı + ekip).
	var top: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
	var head: HBoxContainer = Cards.header(Cards.art("brand_art", str(client.get("name", "")), 44.0, "building"), str(client.get("name", "")),
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
	_objective = str(_brief["objective"]) if not str(_brief["objective"]).is_empty() else data.objective_ids[0]
	_audience = data.audience_ids[0]
	_tone = data.tone_ids[0]
	_brief_box = UiUtil.vbox(4)
	left.add_child(_brief_box)
	_build_brief_pickers()
	var free_staff: Array = []
	var busy: Array = s.busy_staff()  # S3D: başka kampanyada çalışan seçilemez
	for emp: Dictionary in s.staff.values():
		if Employee.is_available(emp, s.clock.week_index) and not busy.has(str(emp["id"])):
			free_staff.append(emp["id"])
	_mix = MixEditor.new(_brief, GameState.sim.media.channel_limit(s, free_staff), _main)
	right.add_child(_mix)
	right.add_child(Cards.section(tr("UI_TEAM_PICK")))
	for emp: Dictionary in s.staff.values():
		var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
		var check: CheckBox = CheckBox.new()
		UiUtil.style_toggle(check)
		var on_other: bool = busy.has(str(emp["id"]))
		var available: bool = Employee.is_available(emp, s.clock.week_index) and not on_other
		check.button_pressed = available
		check.disabled = not available
		if on_other:
			check.tooltip_text = tr("UI_EMP_CAMPAIGN")
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
	# Alt satır kaydırmanın dışında: düğmeler hep görünür.
	var frame: VBoxContainer = UiUtil.modal_outer(col)
	frame.add_child(HSeparator.new())
	_error = UiUtil.label("", 14, UiUtil.TERRACOTTA)
	_error.visible = false
	frame.add_child(_error)
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
	frame.add_child(buttons)


func _fail(key: String) -> void:
	_error.text = tr(key)
	_error.visible = true


## Hedef, kitle, ton seçicileri. Brief hedefi belirlediyse hedef sabit; kitle ve ton araştırılmadıysa (GDD 17)
## otomatik sayılır, seçici yerine soluk bir not durur.
func _build_brief_pickers() -> void:
	var data: GameData = DataDB.data
	UiUtil.clear(_brief_box)
	var fixed_objective: bool = not str(_brief["objective"]).is_empty()
	if fixed_objective:
		_add_row(_brief_box, "UI_OBJECTIVE", _fixed(UiUtil.name_of(data.objectives, _objective)))
	else:
		_add_row(_brief_box, "UI_OBJECTIVE", _picker("UI_OBJECTIVE", "objective", data.objectives, data.objective_ids, _objective,
			func(id: String) -> void: _objective = id))
	for spec: Array in [["UI_AUDIENCE", "audience", data.audiences, data.audience_ids, "audience_analysis", "UI_AUTO_AUDIENCE"],
			["UI_TONE", "tone", data.tones, data.tone_ids, "tone_choice", "UI_AUTO_TONE"]]:
		if not GameState.sim.research.has(GameState.sim.state, str(spec[4])):
			_add_row(_brief_box, str(spec[0]), _fixed(tr(str(spec[5]))))
			continue
		var kind: String = str(spec[1])
		_add_row(_brief_box, str(spec[0]), _picker(str(spec[0]), kind, spec[2], spec[3], _audience if kind == "audience" else _tone,
			func(id: String) -> void:
				if kind == "audience":
					_audience = id
				else:
					_tone = id))


func _picker(title_key: String, kind: String, table: Dictionary, ids: Array[String], current: String, on_pick: Callable) -> Button:
	var items: Array = []
	for id: String in ids:
		items.append({"id": id, "name": UiUtil.name_of(table, id), "art_kind": kind, "art_id": id,
			"sub": tr(str(table[id].get("desc_key", ""))) if table[id].has("desc_key") else ""})
	var b: Button = OptionPickerDialog.opener(tr(title_key), items, current, _main, func(id: String) -> void:
		on_pick.call(id)
		_build_brief_pickers.call_deferred())
	b.clip_text = true
	return b


func _fixed(text: String) -> Label:
	var l: Label = UiUtil.label(text, 13, CozyTheme.MUTED)
	l.clip_text = true
	l.tooltip_text = text
	l.mouse_filter = Control.MOUSE_FILTER_STOP
	return l


## Fokus Grup (GDD 17): yayından önce kombinasyonun uyumuna dair kaba bir tahmin (iyi / orta / zayıf).
func _on_focus_group() -> void:
	var sim: Simulation = GameState.sim
	var mix: Array = _mix.get_mix()
	if mix.is_empty():
		return
	var client: Dictionary = _brief["prospect"] if not (_brief["prospect"] as Dictionary).is_empty() \
		else sim.state.clients.get(_brief["client_id"], {})
	var setup: Dictionary = {"sector": _brief["sector"], "mix": mix,
		"objective": _objective,
		"audience": _audience if sim.research.has(sim.state, "audience_analysis") else "",
		"tone": _tone if sim.research.has(sim.state, "tone_choice") else ""}
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
	var mix: Array = _mix.get_mix()
	if mix.is_empty():
		_fail("ERR_CHANNEL")
		return
	var choices: Dictionary = {
		"name": _name_edit.text.strip_edges(),
		"objective": _objective,
		"audience": _audience,
		"tone": _tone,
		"mix": mix,
		"team": _picked_team(),
	}
	if (choices["team"] as Array).is_empty():
		_fail("ERR_TEAM_EMPTY")
		return
	# S3A: önce görev planı (ağırlıklar ve gerekiyorsa kişi ataması); kampanya plan onaylanınca başlar.
	_plan = TaskPlanDialog.new(_brief, choices, func() -> void:
		_main.call("show_panel", "campaign")
		queue_free())
	_main.call("open_modal", _plan)


## Araçlar ve testler için: sihirbazı ve görev planını varsayılan (otomatik) planla onaylar.
func start_auto() -> void:
	_on_start()
	if is_instance_valid(_plan):
		_plan.call("_start")
