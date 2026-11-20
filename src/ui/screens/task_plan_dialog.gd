class_name TaskPlanDialog
extends Control
## Görev planı (S3A, Game Dev Tycoon tarzı). S11 (Orgo): fazlar sırayla — kampanya başlarken yalnız 1. fazın planı,
## 2. ve 3. faz başladığında o fazın planı (for_phase). Her görevin ağırlık
## çubuğu (fazın üç görevi oranlanır, toplam %100) ve atama gereken işlerde tek kişilik atama yeri. Altta kişilerin
## kampanya yükü (atandığı görevlerin ağırlık toplamı; %100 üstü yorulur). Küçük iş / tek kişi: atama yok.
## Onaylanınca StartCampaignCommand (choices + sliders + assign + rentals, planned).

const ROW_H: float = 72.0

var _brief: Dictionary
var _choices: Dictionary
var _on_started: Callable
var _team: Array = []
var _assign_mode: bool = false
var _raw: Array = [[50.0, 50.0, 50.0], [50.0, 50.0, 50.0], [50.0, 50.0, 50.0]]
var _assign: Array = [["", "", ""], ["", "", ""], ["", "", ""]]
var _rentals: Array = []
var _share_labels: Array = [[], [], []]
var _who_buttons: Array = [[], [], []]
var _loads: Dictionary = {}  # emp_id → Label
var _error: Label
var _phase: int = 0  # S11: bu pencerenin planladığı faz
var _camp: Dictionary = {}  # S11: faz başı planında kampanya (boşsa kampanya başlangıcı)


func _init(brief: Dictionary, choices: Dictionary, on_started: Callable) -> void:
	_brief = brief
	_choices = choices
	_on_started = on_started
	_team = (choices.get("team", []) as Array).duplicate()


## S11: faz başında (2. ve 3. faz) o fazın planı; önceki fazların planı yüke sayılır.
static func for_phase(camp: Dictionary) -> TaskPlanDialog:
	var setup: Dictionary = camp["setup"]
	var d: TaskPlanDialog = TaskPlanDialog.new({"size": setup["size"], "objective": setup["objective"], "id": ""},
		{"team": setup.get("team", []), "objective": setup["objective"]}, Callable())
	d._camp = camp
	d._phase = GameState.sim.production.current_phase(camp)
	for p: int in 3:
		for i: int in 3:
			d._raw[p][i] = 100.0 * float(setup["sliders"][p][i])
		d._raw[d._phase] = [50.0, 50.0, 50.0]
	if TaskPlan.has_plan(setup):
		d._assign = (setup["assign"] as Array).duplicate(true)
	return d


func _ready() -> void:
	var data: GameData = DataDB.data
	set_meta("esc_closes", _camp.is_empty())  # faz başı planı kapatılırsa kampanya bekler; panelden yeniden açılır
	_assign_mode = TaskPlan.needs_assignment(data, {"size": _brief["size"], "team": _team})
	if _assign_mode:
		_assign = TaskPlan.auto_assign_phases(data, GameState.sim.state, sliders(), _team, _assign, [_phase])
	var col: VBoxContainer = UiUtil.modal_frame(self, UiUtil.dialog_size("task_plan"), true, true)
	col.add_theme_constant_override("separation", CozyTheme.SPACE_S)
	col.add_child(UiUtil.heading(tr("UI_PLAN_TITLE"), "users-group"))
	# S12 (Orgo'nun taslağı): müşteri adı ve "iş boyu · gün", ok biçimli faz adımları, kısa yönerge, görev satırları.
	var head: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
	var client: Label = UiUtil.label(_client_name(), 20, CozyTheme.FOREST)
	client.add_theme_font_override("font", CozyTheme.title_font(700))
	client.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	client.clip_text = true
	head.add_child(client)
	head.add_child(UiUtil.label("%s · %s" % [tr("SIZE_" + str(_brief["size"]).to_upper()), tr("UI_PLAN_DAYS") % _phase_days()], 15,
		CozyTheme.TEXT))
	col.add_child(head)
	var names: Array[String] = []
	for ph: int in 3:
		names.append(tr("UI_PLAN_STEP_%d" % ph))
	col.add_child(PhaseSteps.new(_phase, names))
	col.add_child(UiUtil.label(tr("UI_PLAN_PHASE_HINT_%d" % _phase), 15, CozyTheme.TEXT))
	var areas: Array[String] = data.focus_ids_of_phase(_phase)
	for i: int in 3:
		col.add_child(_task_row(_phase, i, areas[i]))
		if i < 2:
			col.add_child(HSeparator.new())
	if _phase == 2:
		col.add_child(_rentals_box())
	if _assign_mode:
		col.add_child(_load_strip())
	var frame: VBoxContainer = UiUtil.modal_outer(col)
	_error = UiUtil.label("", 13, CozyTheme.NEGATIVE)
	_error.visible = false
	frame.add_child(_error)
	var foot: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	var info: TextureRect = UiUtil.icon("info", 18, CozyTheme.TEXT)
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	foot.add_child(info)
	var note: Label = UiUtil.label(tr("UI_PLAN_FOOT_ASSIGN" if _assign_mode else "UI_PLAN_FOOT_AUTO"), 13, CozyTheme.TEXT)
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	foot.add_child(note)
	if _assign_mode:
		foot.add_child(UiUtil.button(tr("UI_BOARD_AUTO"), func() -> void:
			_assign = TaskPlan.auto_assign_phases(DataDB.data, GameState.sim.state, sliders(), _team, _assign, [_phase])
			_refresh()))
	if _camp.is_empty():
		foot.add_child(UiUtil.button(tr("UI_BACK"), queue_free))
	var start: Button = UiUtil.button(tr("UI_START_CAMPAIGN") if _camp.is_empty() else tr("UI_PLAN_START_PHASE"), _start)
	start.theme_type_variation = "PrimaryButton"
	start.custom_minimum_size = Vector2(170.0, 44.0)
	foot.add_child(start)
	frame.add_child(foot)
	_refresh()


func _client_name() -> String:
	if not _camp.is_empty():
		return str(_camp["setup"].get("client_name", ""))
	var prospect: Dictionary = _brief.get("prospect", {})
	if not prospect.is_empty():
		return str(prospect.get("name", ""))
	return str(GameState.sim.state.clients.get(str(_brief.get("client_id", "")), {}).get("name", ""))


## Fazın süresi (gün): üretim günleri üç faza eşit bölünür (rötuş payı hariç, S3C).
func _phase_days() -> int:
	if not _camp.is_empty():
		return maxi(1, CampaignProduction.production_days(_camp) / 3)
	var data: GameData = DataDB.data
	var total: int = int(_brief.get("deadline_weeks", 1)) * data.bali("calendar.days_per_week")
	return maxi(1, int(ceilf(float(total) * (1.0 - data.balf("production.polish_share")))) / 3)


## Ham çubuk değerlerinden faz başına paylar (toplam 1).
func sliders() -> Array:
	var out: Array = []
	for p: int in 3:
		var total: float = float(_raw[p][0]) + float(_raw[p][1]) + float(_raw[p][2])
		if total <= 0.0:
			out.append([1.0 / 3.0, 1.0 / 3.0, 1.0 - 2.0 / 3.0])
			continue
		var a: float = float(_raw[p][0]) / total
		var b: float = float(_raw[p][1]) / total
		out.append([a, b, 1.0 - a - b])
	return out


## Görev satırı (taslak): solda kâğıt üstü çizim, adı (büyük) ve alt adı, çentikli ağırlık çubuğu, büyük yüzde;
## atama gereken işte en sağda kişi düğmesi.
func _task_row(p: int, i: int, area: String) -> HBoxContainer:
	var data: GameData = DataDB.data
	var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
	row.custom_minimum_size.y = ROW_H
	var art: FocusArt = FocusArt.new(area)
	art.custom_minimum_size = Vector2(100.0, 70.0)
	art.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(art)
	var full: String = UiUtil.name_of(data.focus_areas, area)
	var parts: PackedStringArray = _split_name(full)
	var names: VBoxContainer = UiUtil.vbox(-2)
	names.custom_minimum_size.x = 180.0
	names.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var title: Label = UiUtil.label(parts[0], 18, CozyTheme.TEXT)
	title.add_theme_font_override("font", CozyTheme.title_font(700))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # uzun ad iki satıra iner, kesilmez
	title.custom_minimum_size.x = 180.0
	title.tooltip_text = full
	title.mouse_filter = Control.MOUSE_FILTER_STOP
	names.add_child(title)
	var sub: HBoxContainer = UiUtil.hbox(6)
	if not parts[1].is_empty():
		sub.add_child(UiUtil.label(parts[1], 13, CozyTheme.TEXT))
	sub.add_child(FocusHint.badge(str(_choices.get("objective", _brief["objective"])), area, 12))
	names.add_child(sub)
	row.add_child(names)
	var slider: HSlider = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 5.0
	slider.tick_count = 5  # çentikler yüzde 25, 50, 75 (uçlardakiler çizilmez)
	slider.ticks_on_borders = false
	slider.value = float(_raw[p][i])
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.tooltip_text = tr("UI_PLAN_WEIGHT_TIP")
	_style_slider(slider)
	slider.value_changed.connect(func(v: float) -> void:
		_raw[p][i] = v
		_refresh())
	row.add_child(slider)
	var share: Label = UiUtil.label("", 20, CozyTheme.FOREST)
	share.add_theme_font_override("font", CozyTheme.title_font(700))
	share.custom_minimum_size.x = 60.0
	share.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	share.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(share)
	(_share_labels[p] as Array).append(share)
	if _assign_mode:
		var who: Button = Button.new()
		who.focus_mode = Control.FOCUS_NONE
		who.custom_minimum_size = Vector2(104.0, 34.0)
		who.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		who.clip_text = true
		who.add_theme_font_size_override("font_size", 12)
		who.pressed.connect(func() -> void: _pick_person(p, i, area, who))
		(_who_buttons[p] as Array).append(who)
		row.add_child(who)
	return row


## S12 (taslak): kalın yuvarlak ray (dolu kısım yeşil, boşu krem ve kiremit kenarlı), turuncu "II" tutamak, altta çentikler.
static func _style_slider(slider: HSlider) -> void:
	var rail: StyleBoxFlat = CozyTheme.box(Color("f8e6cf"), 999, Color("e3ad85"), 1, false, Vector2(0.0, 7.0))
	var fill: StyleBoxFlat = CozyTheme.box(Color("a9b98b"), 999, Color("a9b98b"), 1, false, Vector2(0.0, 7.0))
	var fill_hi: StyleBoxFlat = CozyTheme.box(Color("98ab78"), 999, Color("98ab78"), 1, false, Vector2(0.0, 7.0))
	slider.add_theme_stylebox_override("slider", rail)
	slider.add_theme_stylebox_override("grabber_area", fill)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill_hi)
	slider.add_theme_icon_override("grabber", CozyIcons.pill_grabber(CozyTheme.TERRA))
	slider.add_theme_icon_override("grabber_highlight", CozyIcons.pill_grabber(CozyTheme.TERRA.darkened(0.1)))
	slider.add_theme_icon_override("tick", CozyIcons.slider_tick(Color("d9865a")))
	slider.custom_minimum_size.y = 40.0


## "Büyük Fikir / Konsept" → ["Büyük Fikir", "Konsept"]; "Metin Yazarlığı (Copy)" → ["Metin Yazarlığı", "Copy"].
static func _split_name(full: String) -> PackedStringArray:
	if full.contains(" / "):
		return PackedStringArray([full.get_slice(" / ", 0), full.get_slice(" / ", 1)])
	if full.contains(" (") and full.ends_with(")"):
		return PackedStringArray([full.get_slice(" (", 0), full.get_slice(" (", 1).trim_suffix(")")])
	return PackedStringArray([full, ""])


## Görevin kişisini seçme: ekipteki herkes portresi, o göreve uygunluğu ve yüküyle; "Kimse" ile boşaltılır.
func _pick_person(p: int, i: int, area: String, anchor: Button) -> void:
	var data: GameData = DataDB.data
	var popup: PopupPanel = PopupPanel.new()
	popup.add_theme_stylebox_override("panel", CozyTheme.box(CozyTheme.CREAM_LIGHT, 12, CozyTheme.BORDER, 1, true, Vector2(8, 8)))
	var list: VBoxContainer = UiUtil.vbox(4)
	popup.add_child(list)
	for id: Variant in _team:
		var emp: Dictionary = GameState.sim.state.staff.get(str(id), {})
		if emp.is_empty():
			continue
		var b: Button = Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(250.0, 40.0)
		var line: HBoxContainer = UiUtil.hbox(8)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 4)
		b.add_child(line)
		line.add_child(Cards.avatar(emp, 30.0))
		var who: VBoxContainer = UiUtil.vbox(-3)
		who.add_child(UiUtil.label(GameState.employee_name(emp), 13, CozyTheme.TEXT))
		var fit: int = int(roundf(Employee.area_stat(data, emp, area)))
		who.add_child(UiUtil.label(tr("UI_PLAN_PICK_INFO") % [fit, UiUtil.percent(roundf(_load_of(str(id)) * 100.0))], 11,
			CozyTheme.MUTED))
		line.add_child(who)
		b.pressed.connect(func() -> void:
			_assign[p][i] = str(id)
			popup.queue_free()
			_refresh())
		list.add_child(b)
	list.add_child(UiUtil.button(tr("UI_PLAN_NOBODY"), func() -> void:
		_assign[p][i] = ""
		popup.queue_free()
		_refresh()))
	add_child(popup)
	popup.popup(Rect2i(Vector2i(anchor.get_screen_position() + Vector2(0.0, anchor.size.y)), Vector2i(260, 10)))
	popup.popup_hide.connect(popup.queue_free)


func _load_of(emp_id: String) -> float:
	return TaskPlan.campaign_load({"sliders": sliders(), "assign": _assign}, emp_id)


func _load_strip() -> HFlowContainer:
	var flow: HFlowContainer = Cards.flow_row(CozyTheme.SPACE_M)
	for id: Variant in _team:
		var emp: Dictionary = GameState.sim.state.staff.get(str(id), {})
		if emp.is_empty():
			continue
		var item: HBoxContainer = UiUtil.hbox(6)
		item.add_child(Cards.avatar(emp, 28.0))
		var l: Label = UiUtil.label("", 13, CozyTheme.TEXT)
		l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		item.add_child(l)
		_loads[str(id)] = l
		flow.add_child(item)
	return flow


## Prodüksiyon fazının kiralıkları (K-119): bedeli kampanya başlarken ödenir.
func _rentals_box() -> Control:
	var sim: Simulation = GameState.sim
	var ids: Array = sim.equipment.available(sim.state, "rental")
	var box: VBoxContainer = UiUtil.vbox(4)
	var flow: HFlowContainer = Cards.flow_row(4)
	if ids.is_empty():
		return box
	box.add_child(UiUtil.label(tr("UI_PLAN_RENTALS"), 12, CozyTheme.WOOD))
	box.add_child(flow)
	for id: Variant in ids:
		var b: Button = UiUtil.button(tr("UI_BOARD_RENT") % [UiUtil.name_of(DataDB.data.equipment, str(id)),
			UiUtil.money(sim.equipment.price(sim.state, str(id)))], func() -> void: pass)
		b.toggle_mode = true
		b.add_theme_font_size_override("font_size", 11)
		b.toggled.connect(func(on: bool) -> void:
			if on and not _rentals.has(id):
				_rentals.append(id)
			elif not on:
				_rentals.erase(id))
		flow.add_child(b)
	return box


func _refresh() -> void:
	var data: GameData = DataDB.data
	var s: Array = sliders()
	for p: int in 3:
		if (_share_labels[p] as Array).is_empty():
			continue  # S11: yalnızca planlanan fazın satırları var
		for i: int in 3:
			(_share_labels[p][i] as Label).text = UiUtil.percent(roundf(float(s[p][i]) * 100.0))
			if _assign_mode:
				var b: Button = _who_buttons[p][i]
				var id: String = str(_assign[p][i])
				var emp: Dictionary = GameState.sim.state.staff.get(id, {})
				b.text = (str(GameState.employee_name(emp)).split(" ")[0] if not emp.is_empty() else tr("UI_PLAN_ASSIGN"))
				b.add_theme_color_override("font_color", CozyTheme.FOREST if not emp.is_empty() else CozyTheme.TERRA)
				b.icon = UiUtil.icon_texture("user" if not emp.is_empty() else "users", 14)
	for id: String in _loads:
		var load: float = _load_of(id)
		var emp: Dictionary = GameState.sim.state.staff[id]
		var col: Color = CozyTheme.MUTED if load <= 0.0 else (CozyTheme.FOREST if load <= data.balf("workload.warn_load") + 0.001
			else (CozyTheme.GOLD if load <= data.balf("workload.danger_load") else CozyTheme.NEGATIVE))
		var l: Label = _loads[id]
		l.text = "%s · %s" % [str(GameState.employee_name(emp)).split(" ")[0],
			tr("UI_BOARD_FREE") if load <= 0.0 else tr("UI_BOARD_LOAD") % UiUtil.percent(roundf(load * 100.0))]
		l.add_theme_color_override("font_color", col)
	if _error != null:
		_error.visible = false


func _start() -> void:
	if not _camp.is_empty():  # S11: faz başı planı
		var row: Array = (_assign[_phase] as Array).duplicate() if _assign_mode else []
		var err: String = GameState.execute(PlanTaskPhaseCommand.new(str(_camp["id"]), sliders()[_phase], row,
			_rentals.duplicate()))
		if not err.is_empty():
			_error.text = tr(err)
			_error.visible = true
			return
		queue_free()
		return
	var choices: Dictionary = _choices.duplicate(true)
	choices["sliders"] = sliders()
	choices["planned"] = true
	choices["minigames"] = bool(Settings.get_value("minigames"))
	choices["rentals"] = _rentals.duplicate()
	if _assign_mode:
		choices["assign"] = _assign.duplicate(true)
	var result: Dictionary = GameState.execute(StartCampaignCommand.new(_brief["id"], choices))
	if not bool(result["ok"]):
		_error.text = tr(str(result["error"]))
		_error.visible = true
		return
	_on_started.call()
	queue_free()
