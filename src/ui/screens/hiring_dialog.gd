class_name HiringDialog
extends Control
## İşe alım (GDD 11.3): pozisyon + kanal seç, ücretini öde, adaylardan birini işe al.

## S5: pozisyon ve kanal açılır menü değil, çizimli seçim paneliyle (OptionPickerDialog) seçilir.
const DEPT_ICONS: Dictionary = {"account": "user", "strategy": "stat-strategy", "creative": "stat-creative",
	"design": "stat-creative", "production": "stat-technical", "media": "chart-bar", "digital": "device-desktop",
	"pr_event": "speakerphone", "operations": "tool", "new_business": "coins", "support": "users", "founder": "user"}
const CHANNEL_ICONS: Dictionary = {"job_ad": "receipt", "internship": "user", "career_site": "world", "headhunter": "search",
	"rival_transfer": "building"}

var _role_i: int = 0
var _channel_i: int = 0
var _pickers: VBoxContainer
var _role_ids: Array[String] = []
var _channel_ids: Array[String] = []
var _search_button: Button
var _list: VBoxContainer
var _error: Label


func _ready() -> void:
	var data: GameData = DataDB.data
	var s: SimState = GameState.sim.state
	var col: VBoxContainer = UiUtil.modal_frame(self, Vector2(706.0, 480.0), true, true)  # S11: adaylar gelince pencere büyümesin
	col.add_child(UiUtil.heading(tr("UI_HIRE_TITLE"), "users-group"))
	col.add_child(UiUtil.label(tr("UI_TEAM_HEADER") % [s.staff.size(), GameState.sim.staff.capacity(s),
		UiUtil.money(GameState.sim.staff.monthly_payroll(s))], 13, CozyTheme.FOREST))
	for id: String in data.position_ids:
		var pos: Dictionary = data.positions[id]
		if bool(pos["hireable"]) and int(pos["available_from"]) <= s.clock.year() and GameState.sim.research.position_unlocked(s, id):
			_role_ids.append(id)
	for id: String in data.hiring_channel_ids:
		if int(data.hiring_channels[id]["available_from"]) <= s.clock.year():
			_channel_ids.append(id)
	_pickers = UiUtil.vbox(CozyTheme.SPACE_S)
	col.add_child(_pickers)
	_build_pickers()
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


func _build_pickers() -> void:
	var data: GameData = DataDB.data
	var year: int = GameState.sim.state.clock.year()
	UiUtil.clear(_pickers)
	var roles: Array = []
	for id: String in _role_ids:
		var pos: Dictionary = data.positions[id]
		roles.append({"id": id, "name": tr(pos["name_key"]), "note": tr("DEPT_" + str(pos["department"]).to_upper()),
			"art_kind": "icon", "art_id": str(DEPT_ICONS.get(str(pos["department"]), "user"))})
	_add_row(_pickers, "UI_ROLE", OptionPickerDialog.opener(tr("UI_ROLE"), roles, _role_ids[_role_i] if not _role_ids.is_empty() else "",
		_screen(), func(id: String) -> void:
			_role_i = _role_ids.find(id)
			_build_pickers.call_deferred()))
	var chans: Array = []
	for id: String in _channel_ids:
		var ch: Dictionary = data.hiring_channels[id]
		chans.append({"id": id, "name": tr(ch["name_key"]), "sub": tr(ch["desc_key"]),
			"note": UiUtil.money(float(ch["cost_1990"]) * Economy.inflation(data, year)),
			"art_kind": "icon", "art_id": str(CHANNEL_ICONS.get(id, "search"))})
	_add_row(_pickers, "UI_HIRE_CHANNEL", OptionPickerDialog.opener(tr("UI_HIRE_CHANNEL"), chans,
		_channel_ids[_channel_i] if not _channel_ids.is_empty() else "", _screen(), func(id: String) -> void:
			_channel_i = _channel_ids.find(id)
			_build_pickers.call_deferred()
			_update_hint.call_deferred()))


## Seçim panelini açacak ana ekran (open_modal).
func _screen() -> Control:
	var n: Node = self
	while n != null and not n.has_method("open_modal"):
		n = n.get_parent()
	return n as Control


func _add_row(col: VBoxContainer, key: String, control: Control) -> void:
	var row: HBoxContainer = UiUtil.hbox()
	var l: Label = UiUtil.label(tr(key), 13, CozyTheme.FOREST)
	l.add_theme_font_override("font", CozyTheme.strong_font())
	l.custom_minimum_size.x = 120.0
	if not control is Button:  # seçici düğmenin sol boşluğunda çizimi var; sıkıştırma onu silerdi
		Cards.compact(control)
	row.add_child(l)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	col.add_child(row)


func _update_hint() -> void:
	if _channel_ids.is_empty():
		return
	_error.text = ""
	_search_button.tooltip_text = tr(DataDB.data.hiring_channels[_channel_ids[_channel_i]]["desc_key"])
	_search_button.text = tr("UI_SEARCH") + " — " + _search_button.tooltip_text


func _on_search() -> void:
	var found: Array[Dictionary] = GameState.execute(SearchCandidatesCommand.new(_role_ids[_role_i],
		_channel_ids[_channel_i], GameState.lang()))
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
