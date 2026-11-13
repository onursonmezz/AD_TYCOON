class_name HiringDialog
extends Control
## İşe alım (GDD 11.3): pozisyon + kanal seç, ücretini öde, adaylardan birini işe al.

var _role: OptionButton
var _channel: OptionButton
var _role_ids: Array[String] = []
var _channel_ids: Array[String] = []
var _search_button: Button
var _list: VBoxContainer
var _error: Label


func _ready() -> void:
	var data: GameData = DataDB.data
	var s: SimState = GameState.sim.state
	var col: VBoxContainer = UiUtil.modal_frame(self, Vector2(706.0, 450.0))
	col.add_child(UiUtil.heading(tr("UI_HIRE_TITLE"), "users-group"))
	col.add_child(UiUtil.label(tr("UI_TEAM_HEADER") % [s.staff.size(), GameState.sim.staff.capacity(s),
		UiUtil.money(GameState.sim.staff.monthly_payroll(s))], 13, CozyTheme.FOREST))
	_role = OptionButton.new()
	for id: String in data.position_ids:
		var pos: Dictionary = data.positions[id]
		if bool(pos["hireable"]) and int(pos["available_from"]) <= s.clock.year() and GameState.sim.research.position_unlocked(s, id):
			_role_ids.append(id)
			_role.add_item("%s (%s)" % [tr(pos["name_key"]), tr("DEPT_" + str(pos["department"]).to_upper())])
	_add_row(col, "UI_ROLE", _role)
	_channel = OptionButton.new()
	for id: String in data.hiring_channel_ids:
		var ch: Dictionary = data.hiring_channels[id]
		if int(ch["available_from"]) <= s.clock.year():
			_channel_ids.append(id)
			_channel.add_item("%s — %s" % [tr(ch["name_key"]), UiUtil.money(float(ch["cost_1990"]) * Economy.inflation(data, s.clock.year()))])
	_channel.item_selected.connect(func(_i: int) -> void: _update_hint())
	_add_row(col, "UI_HIRE_CHANNEL", _channel)
	_search_button = UiUtil.button(tr("UI_SEARCH"), _on_search)
	_search_button.theme_type_variation = "PrimaryButton"
	col.add_child(_search_button)
	_error = UiUtil.label("", 14, UiUtil.TERRACOTTA)
	col.add_child(_error)
	_list = UiUtil.vbox(8)
	col.add_child(_list)
	_update_hint()
	var buttons: HBoxContainer = UiUtil.hbox()
	buttons.add_child(UiUtil.spacer())
	buttons.add_child(UiUtil.button(tr("UI_CLOSE"), queue_free))
	col.add_child(buttons)


func _add_row(col: VBoxContainer, key: String, control: Control) -> void:
	var row: HBoxContainer = UiUtil.hbox()
	var l: Label = UiUtil.label(tr(key), 13, CozyTheme.FOREST)
	l.add_theme_font_override("font", CozyTheme.strong_font())
	l.custom_minimum_size.x = 120.0
	Cards.compact(control)
	row.add_child(l)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	col.add_child(row)


func _update_hint() -> void:
	if _channel_ids.is_empty():
		return
	_error.text = ""
	_search_button.tooltip_text = tr(DataDB.data.hiring_channels[_channel_ids[_channel.selected]]["desc_key"])
	_search_button.text = tr("UI_SEARCH") + " — " + _search_button.tooltip_text


func _on_search() -> void:
	var found: Array[Dictionary] = GameState.execute(SearchCandidatesCommand.new(_role_ids[_role.selected],
		_channel_ids[_channel.selected], GameState.lang()))
	UiUtil.clear(_list)
	if found.is_empty():
		_error.text = tr("ERR_NO_CANDIDATE")
	for cand: Dictionary in found:
		_list.add_child(_candidate_card(cand))


## Aday kartı (UI-3 kart dili): portre, ad ve unvan, sağda beklenen maaş; stat rozetleri (pozisyonun ana statları
## yeşil çerçeveli), özellik etiketleri ve yeşil "İşe al".
func _candidate_card(cand: Dictionary) -> PanelContainer:
	var data: GameData = DataDB.data
	var card: PanelContainer = UiUtil.card()
	var col: VBoxContainer = UiUtil.vbox(CozyTheme.SPACE_S)
	card.add_child(col)
	var tags: Array = []
	if data.rivals.has(str(cand.get("from_rival", ""))):
		tags.append(Cards.chip(tr("UI_FROM_RIVAL") % UiUtil.name_of(data.rivals, cand["from_rival"]), CozyTheme.TERRA_SOFT, CozyTheme.TERRA))
	tags.append(Cards.chip(tr("UI_EXPECTED_SALARY") % UiUtil.money(cand["salary"]), CozyTheme.CREAM, CozyTheme.TEXT))
	col.add_child(Cards.header(Cards.avatar(cand, 44.0), str(cand["name"]),
		"%s · %s" % [tr(Employee.title_key(data, cand)), tr("UI_LEVEL") % int(cand["level"])], tags))
	var stats: HFlowContainer = Cards.flow_row()
	var prim: Array = data.positions[cand["role"]]["primary_stats"]
	for stat: Variant in data.bal("staff_rules.stats"):
		var chip: PanelContainer = Cards.stat(str(stat), int(cand["stats"][stat]))
		if prim.has(stat):
			chip.add_theme_stylebox_override("panel", CozyTheme.box(CozyTheme.SAGE_SOFT, 999, CozyTheme.FOREST_LIGHT, 1, false,
				Vector2(10.0, 2.0)))
		stats.add_child(chip)
	col.add_child(stats)
	var bottom: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	var traits: HFlowContainer = Cards.flow_row()
	traits.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for t: Variant in cand.get("traits", []):
		var rec: Dictionary = data.traits.get(str(t), {})
		traits.add_child(Cards.accent_chip(tr(str(rec.get("name_key", t))), tr(str(rec.get("desc_key", "")))))
	bottom.add_child(traits)
	var hire: Button = UiUtil.button(tr("UI_HIRE_THIS"), func() -> void:
		var err: String = GameState.execute(HireEmployeeCommand.new(cand["id"]))
		if err.is_empty():
			EventBus.notification.emit("NOTE_HIRED", [cand["name"]], "good")
			queue_free()
		else:
			_error.text = tr(err))
	hire.theme_type_variation = "PrimaryButton"
	bottom.add_child(hire)
	col.add_child(bottom)
	return card
