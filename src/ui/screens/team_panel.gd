class_name TeamPanel
extends VBoxContainer
## Ekip ekranı (GDD 20, 11; UI-3 taslağı 13_ekip): arama, rol süzgeci ve sıralamalı çalışan tablosu.
## Satıra tıklayınca altında ayrıntı açılır: özellikler, maaş, eğitim / uzmanlaşma / sertifika / zam / kovma.

const COL_NAME: float = 104.0
const COL_ROLE: float = 96.0
const COL_STAT: float = 30.0
const COL_AVATAR: float = 34.0
const COL_GAP: int = 6
const COL_BAR: float = 70.0
const SORTS: Array[String] = ["name", "role", "level"]

var _main: Control
var _header: Label
var _payroll: Label
var _footer: Label
var _search: LineEdit
var _role: OptionButton
var _sort: OptionButton
var _role_ids: Array[String] = []
var _list: VBoxContainer
var _signature: String = ""
var _open_id: String = ""


func _init(main_screen: Control) -> void:
	_main = main_screen
	add_theme_constant_override("separation", CozyTheme.SPACE_S)
	var top: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	top.add_child(UiUtil.heading(tr("MENU_TEAM")))
	_header = UiUtil.label("", 13, CozyTheme.FOREST)
	_header.add_theme_font_override("font", CozyTheme.strong_font())
	_payroll = UiUtil.label("", 13, CozyTheme.FOREST)
	_payroll.add_theme_font_override("font", CozyTheme.strong_font())
	_payroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_header)
	top.add_child(VSeparator.new())
	top.add_child(_payroll)
	_search = LineEdit.new()
	_search.placeholder_text = tr("UI_TEAM_SEARCH")
	_search.custom_minimum_size.x = 130.0
	Cards.compact(_search)
	_search.text_changed.connect(func(_t: String) -> void: refresh())
	top.add_child(_search)
	_role = OptionButton.new()
	_role.fit_to_longest_item = false
	_role.custom_minimum_size.x = 96.0
	Cards.compact(_role)
	_role.clip_text = true
	_role.item_selected.connect(func(_i: int) -> void: refresh())
	top.add_child(_role)
	_sort = OptionButton.new()
	_sort.fit_to_longest_item = false
	_sort.custom_minimum_size.x = 96.0
	Cards.compact(_sort)
	_sort.clip_text = true
	for key: String in SORTS:
		_sort.add_item(tr("UI_SORT_" + key.to_upper()))
	_sort.item_selected.connect(func(_i: int) -> void: refresh())
	top.add_child(_sort)
	var hire: Button = UiUtil.button("+ " + tr("UI_HIRE"), func() -> void: _main.call("open_modal", HiringDialog.new()))
	Cards.compact(hire, true)
	top.add_child(hire)
	add_child(top)
	add_child(_column_titles())
	_list = UiUtil.vbox(2)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_list)
	_footer = UiUtil.label("", 12, CozyTheme.TEXT)
	add_child(_footer)


func refresh() -> void:
	var sim: Simulation = GameState.sim
	var s: SimState = sim.state
	_header.text = tr("UI_TEAM_COUNT") % [s.staff.size(), sim.staff.capacity(s)]
	_payroll.text = tr("UI_TEAM_PAYROLL") % UiUtil.money(sim.staff.monthly_payroll(s))
	_fill_roles(s)
	var sig: String = "%d|%s|%d|%d|%s" % [s.clock.week_index, _search.text, _role.selected, _sort.selected, _open_id]
	for emp: Dictionary in s.staff.values():
		sig += str(emp["id"]) + str(emp["level"]) + str(emp["salary"])
	if sig == _signature:
		return
	_signature = sig
	UiUtil.clear(_list)
	var shown: Array = _visible_staff(s)
	_footer.text = tr("UI_TEAM_SHOWN") % [shown.size(), s.staff.size()]
	for emp: Dictionary in shown:
		_list.add_child(_row(emp))
		if str(emp["id"]) == _open_id:
			_list.add_child(_detail(emp, sim))


## Rol süzgeci: yalnızca ekipte bulunan roller (ilk seçenek "tüm roller").
func _fill_roles(s: SimState) -> void:
	var ids: Array[String] = []
	for emp: Dictionary in s.staff.values():
		if not ids.has(str(emp["role"])):
			ids.append(str(emp["role"]))
	if ids == _role_ids:
		return
	var current: String = _role_ids[_role.selected - 1] if _role.selected > 0 else ""
	_role_ids = ids
	_role.clear()
	_role.add_item(tr("UI_TEAM_ALL_ROLES"))
	for id: String in ids:
		_role.add_item(tr(str(DataDB.data.positions[id]["name_key"])))
	_role.select(ids.find(current) + 1)


func _visible_staff(s: SimState) -> Array:
	var needle: String = _search.text.strip_edges().to_lower()
	var role: String = _role_ids[_role.selected - 1] if _role.selected > 0 else ""
	var out: Array = []
	for emp: Dictionary in s.staff.values():
		if not role.is_empty() and str(emp["role"]) != role:
			continue
		if not needle.is_empty() and not GameState.employee_name(emp).to_lower().contains(needle):
			continue
		out.append(emp)
	var key: String = SORTS[maxi(0, _sort.selected)]
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if bool(a["is_founder"]) != bool(b["is_founder"]):
			return bool(a["is_founder"])  # kurucu hep en üstte
		match key:
			"role":
				return str(a["role"]) < str(b["role"])
			"level":
				return int(a["level"]) > int(b["level"])
		return GameState.employee_name(a).naturalnocasecmp_to(GameState.employee_name(b)) < 0)
	return out


# --- tablo ----------------------------------------------------------------------------

func _cell(text: String, width: float, size: int = 13, color: Color = CozyTheme.TEXT, strong: bool = false) -> Label:
	var l: Label = UiUtil.label(text, size, color)
	l.custom_minimum_size.x = width
	l.clip_text = true
	l.mouse_filter = Control.MOUSE_FILTER_PASS
	if strong:
		l.add_theme_font_override("font", CozyTheme.strong_font())
	return l


func _column_titles() -> PanelContainer:
	var strip: PanelContainer = PanelContainer.new()
	strip.add_theme_stylebox_override("panel", CozyTheme.box(CozyTheme.CREAM_LIGHT, 7, CozyTheme.BORDER, 1, false, Vector2(CozyTheme.SPACE_L, 3.0)))
	var row: HBoxContainer = UiUtil.hbox(COL_GAP)
	strip.add_child(row)
	row.add_child(_cell(tr("UI_COL_EMPLOYEE"), COL_AVATAR + COL_GAP + COL_NAME, 12, CozyTheme.FOREST, true))
	row.add_child(_cell(tr("UI_COL_ROLE"), COL_ROLE, 12, CozyTheme.FOREST, true))
	for stat: Variant in DataDB.data.bal("staff_rules.stats"):
		var key: String = "STAT_" + str(stat).to_upper()
		var head: Label = _cell(tr(key + "_SHORT"), COL_STAT, 12, CozyTheme.FOREST, true)
		head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		head.tooltip_text = "%s: %s" % [tr(key + "_NAME"), tr(key + "_DESC")]
		row.add_child(head)
	row.add_child(_cell(tr("UI_ENERGY"), COL_BAR, 12, CozyTheme.FOREST, true))
	row.add_child(_cell(tr("UI_MORALE"), COL_BAR, 12, CozyTheme.FOREST, true))
	return strip


func _row(emp: Dictionary) -> Button:
	var id: String = str(emp["id"])
	var open: bool = id == _open_id
	var b: Button = Button.new()
	b.theme_type_variation = "PickCardActive" if open else "QuietButton"
	if open:
		for st: String in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
			b.add_theme_stylebox_override(st, CozyTheme.box(CozyTheme.CREAM_LIGHT, CozyTheme.RADIUS_CONTROL, CozyTheme.FOREST_LIGHT, 2,
				false, Vector2(CozyTheme.SPACE_S, 4)))
	b.pressed.connect(func() -> void:
		_open_id = "" if open else id
		refresh())
	var row: HBoxContainer = UiUtil.hbox(COL_GAP)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 4)
	row.offset_left = CozyTheme.SPACE_L  # başlık şeridinin iç boşluğuyla hizalı
	b.add_child(row)
	var pic: PanelContainer = Cards.avatar(emp, COL_AVATAR)
	pic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(pic)
	var name: Label = _cell(GameState.employee_name(emp), COL_NAME, 14, CozyTheme.FOREST)
	name.add_theme_font_override("font", CozyTheme.title_font(700))
	row.add_child(name)
	row.add_child(_cell(tr(Employee.title_key(DataDB.data, emp)), COL_ROLE))
	for stat: Variant in DataDB.data.bal("staff_rules.stats"):
		var pill: PanelContainer = Cards.chip(str(int(emp["stats"][stat])), CozyTheme.CREAM_LIGHT, CozyTheme.TEXT)
		pill.add_theme_stylebox_override("panel", CozyTheme.box(CozyTheme.CREAM_LIGHT, 999, CozyTheme.BORDER, 1, false, Vector2(2.0, 1.0)))
		pill.custom_minimum_size.x = COL_STAT
		pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		(pill.get_child(0) as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(pill)
	row.add_child(_bar_cell(float(emp["energy"]), CozyTheme.POSITIVE))
	row.add_child(_bar_cell(float(emp["morale"]), CozyTheme.ACCENT))
	b.custom_minimum_size.y = 40.0
	return b


func _bar_cell(value: float, color: Color) -> HBoxContainer:
	var m: HBoxContainer = Cards.meter("", value, color, COL_BAR - 34.0)
	m.custom_minimum_size.x = COL_BAR
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.get_child(0).visible = false  # tabloda başlık sütun adında
	return m


## Açılan satırın ayrıntısı: seviye, durum, tükenmişlik, özellikler, maaş ve eylemler.
func _detail(emp: Dictionary, sim: Simulation) -> PanelContainer:
	var data: GameData = DataDB.data
	var s: SimState = sim.state
	var card: PanelContainer = UiUtil.card()
	var col: VBoxContainer = UiUtil.vbox(CozyTheme.SPACE_S)
	card.add_child(col)
	var top: HFlowContainer = Cards.flow_row(CozyTheme.SPACE_S)
	top.add_child(Cards.chip(tr("UI_LEVEL") % int(emp["level"])))
	if not str(emp.get("specialization", "")).is_empty():
		top.add_child(Cards.accent_chip(tr("UI_SPECIALIZED") % UiUtil.name_of(data.sectors, emp["specialization"])))
	if not Employee.is_available(emp, s.clock.week_index):
		top.add_child(Cards.warn_chip(tr("BUSY_" + str(emp["busy_reason"]).to_upper()) % (int(emp["busy_until"]) - s.clock.week_index)))
	top.add_child(Cards.meter(tr("UI_BURNOUT"), float(emp["burnout"]), CozyTheme.NEGATIVE))
	col.add_child(top)
	col.add_child(_traits_row(emp))
	if not bool(emp["is_founder"]):
		var market: float = Employee.market_value(data, emp, s.clock.year())
		var pay_color: Color = UiUtil.TERRACOTTA if float(emp["salary"]) < market * data.balf("staff_rules.offer_check_ratio") else UiUtil.MUTED
		col.add_child(UiUtil.label(tr("UI_SALARY_LINE") % [UiUtil.money(emp["salary"]), UiUtil.money(market)], 13, pay_color))
	col.add_child(_actions_row(emp, sim))
	return card


## Özellikler, sertifikalar ve gizli statlar (potansiyel, sadakat) küçük etiketler hâlinde.
func _traits_row(emp: Dictionary) -> HFlowContainer:
	var row: HFlowContainer = Cards.flow_row()
	for t: Variant in emp.get("traits", []):
		var rec: Dictionary = DataDB.data.traits.get(str(t), {})
		row.add_child(Cards.accent_chip(tr(str(rec.get("name_key", t))), tr(str(rec.get("desc_key", "")))))
	var certs: PackedStringArray = PackedStringArray()
	for area: Variant in emp.get("certs", []):
		certs.append(tr("AREA_" + str(area).to_upper()))
	if not certs.is_empty():
		row.add_child(Cards.chip(tr("UI_CERTS") % ", ".join(certs)))
	var hidden: String = tr("UI_HIDDEN_UNKNOWN")
	if bool(emp["hidden_revealed"]):
		hidden = tr("UI_HIDDEN_LINE") % [int(emp["hidden"]["potential"]), int(emp["hidden"]["loyalty"])]
	row.add_child(Cards.chip(hidden, CozyTheme.CREAM, CozyTheme.MUTED, tr("TIP_HIDDEN")))
	return row


func _actions_row(emp: Dictionary, sim: Simulation) -> HFlowContainer:
	var data: GameData = DataDB.data
	# Satır uzayınca (sertifika, M7-C) düğmeler alt satıra kayar.
	var row: HFlowContainer = Cards.flow_row(CozyTheme.SPACE_S)
	var stat_pick: OptionButton = OptionButton.new()
	var stats: Array = data.bal("staff_rules.stats")
	for stat: Variant in stats:
		stat_pick.add_item(tr("STAT_" + str(stat).to_upper() + "_NAME"))
	row.add_child(stat_pick)
	row.add_child(UiUtil.button(tr("UI_TRAIN") % UiUtil.money(sim.staff.training_cost(sim.state)), func() -> void:
		_run(TrainEmployeeCommand.new(emp["id"], str(stats[stat_pick.selected])))))
	if int(emp["level"]) >= data.bali("staff_rules.specialization_min_level") and str(emp.get("specialization", "")).is_empty():
		var sector_pick: OptionButton = OptionButton.new()
		for id: String in data.sector_ids:
			sector_pick.add_item(UiUtil.name_of(data.sectors, id))
		row.add_child(sector_pick)
		row.add_child(UiUtil.button(tr("UI_SPECIALIZE"), func() -> void:
			_run(TrainEmployeeCommand.new(emp["id"], "", data.sector_ids[sector_pick.selected]))))
	# Yazılım sertifikası (M7-C): ajansın gerçek aracı olan, çalışanın henüz sertifikası olmayan alanlar.
	var areas: Array[String] = []
	for area: Variant in data.bal("tools.areas"):
		if sim.staff.has_real_tool(sim.state, str(area)) and not (emp.get("certs", []) as Array).has(area):
			areas.append(str(area))
	if not areas.is_empty():
		var area_pick: OptionButton = OptionButton.new()
		for area: String in areas:
			area_pick.add_item(tr("AREA_" + area.to_upper()))
		row.add_child(area_pick)
		row.add_child(UiUtil.button(tr("UI_CERTIFY") % UiUtil.money(sim.staff.certification_cost(sim.state)), func() -> void:
			_run(TrainEmployeeCommand.new(emp["id"], "", "", areas[area_pick.selected]))))
	if not bool(emp["is_founder"]):
		row.add_child(UiUtil.button(tr("UI_RAISE"), func() -> void: _run(RaiseSalaryCommand.new(emp["id"]))))
		var fire: Button = UiUtil.button(tr("UI_FIRE") % UiUtil.money(sim.staff.severance(sim.state, emp)), func() -> void:
			_run(FireEmployeeCommand.new(emp["id"])))
		fire.theme_type_variation = "DeclineButton"
		row.add_child(fire)
	return row


func _run(command: RefCounted) -> void:
	var err: Variant = GameState.execute(command)
	if typeof(err) == TYPE_STRING and not str(err).is_empty():
		EventBus.notification.emit(str(err), [], "bad")
	_signature = ""
	refresh()
