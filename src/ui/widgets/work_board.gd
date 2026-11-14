class_name WorkBoard
extends VBoxContainer
## Görev panosu (K-099): fazın başında oyuncu ekipteki herkese üç odak alanından zaman payı verir.
## Satırlar çalışanlar, sütunlar alanlar; hücreye sol tık +%25, sağ tık −%25. Sağda kişinin yükü,
## altta ekibin emeğinden çıkan odak dağılımı. Onaylanınca GameState.set_phase_plan.

const COL_PERSON: float = 210.0
const COL_CELL: float = 132.0
const COL_LOAD: float = 120.0
const AREA_COLORS: Array[Color] = [CozyTheme.FOREST, CozyTheme.GOLD, CozyTheme.WOOD]

var _camp: Dictionary
var _phase: int = 0
var _areas: Array[String] = []
var _members: Array[String] = []
var _plan: Dictionary = {}
var _cells: Dictionary = {}   # emp_id → [Button x3]
var _loads: Dictionary = {}   # emp_id → [Label, ProgressBar]
var _focus_bar: HBoxContainer
var _focus_labels: Array[Label] = []
var _error: Label
var _on_done: Callable
var _rentals: Array = []   # prodüksiyon fazında seçilen kiralıklar (K-100)
var _eq_label: Label


func _init(camp: Dictionary, on_done: Callable) -> void:
	_camp = camp
	_on_done = on_done
	add_theme_constant_override("separation", 8)


func _ready() -> void:
	var data: GameData = DataDB.data
	var sim: Simulation = GameState.sim
	_phase = sim.production.current_phase(_camp)
	_areas = data.focus_ids_of_phase(_phase)
	for id: Variant in _camp["setup"].get("team", []):
		var emp: Dictionary = sim.state.staff.get(str(id), {})
		if not emp.is_empty() and Employee.is_available(emp, sim.state.clock.week_index):
			_members.append(str(id))
	_plan = WorkPlan.auto(data, sim.state, _camp, _phase)
	# Başlık satırında düğmeler: ekip uzun olsa da "Fazı başlat" kaydırmadan görünür.
	var top: HBoxContainer = UiUtil.hbox(8)
	top.add_child(UiUtil.label(tr("UI_BOARD_TITLE") % tr("PHASE_%d" % _phase), 18, UiUtil.TERRACOTTA))
	top.add_child(UiUtil.spacer())
	top.add_child(UiUtil.button(tr("UI_BOARD_AUTO"), func() -> void:
		_plan = WorkPlan.auto(DataDB.data, GameState.sim.state, _camp, _phase)
		_refresh()))
	top.add_child(UiUtil.button(tr("UI_BOARD_CLEAR"), func() -> void:
		for id: String in _members:
			_plan[id] = [0.0, 0.0, 0.0]
		_refresh()))
	top.add_child(UiUtil.button_kind(tr("UI_BOARD_START"), _confirm, "accept"))
	add_child(top)
	_error = UiUtil.label("", 13, UiUtil.TERRACOTTA)
	add_child(_error)
	add_child(UiUtil.wrapped(tr("UI_BOARD_HINT"), 13, UiUtil.MUTED, 640.0))
	add_child(_header())
	for id: String in _members:
		add_child(_row(id))
	add_child(_focus_section())
	if _phase == 2:
		add_child(_equipment_section())
	_refresh()


func _header() -> HBoxContainer:
	var row: HBoxContainer = UiUtil.hbox(6)
	var first: Control = Control.new()
	first.custom_minimum_size.x = COL_PERSON
	row.add_child(first)
	var objective: String = str(_camp["setup"]["objective"])
	for i: int in 3:
		var cell: VBoxContainer = UiUtil.vbox(0)
		cell.custom_minimum_size.x = COL_CELL
		var name_label: Label = UiUtil.label(UiUtil.name_of(DataDB.data.focus_areas, _areas[i]), 13, _ink(i))
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		cell.add_child(name_label)
		var badge: Label = FocusHint.badge(objective, _areas[i], 15)
		badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		cell.add_child(badge)
		row.add_child(cell)
	return row


func _row(id: String) -> PanelContainer:
	var emp: Dictionary = GameState.sim.state.staff[id]
	var panel: PanelContainer = UiUtil.card()
	var row: HBoxContainer = UiUtil.hbox(6)
	panel.add_child(row)
	var who: VBoxContainer = UiUtil.vbox(0)
	who.custom_minimum_size.x = COL_PERSON - 24.0
	who.add_child(UiUtil.label(GameState.employee_name(emp), 14, UiUtil.TEXT))
	var stats: Dictionary = emp["stats"]
	who.add_child(UiUtil.label("%s · S %d K %d T %d · ⚡%d" % [UiUtil.name_of(DataDB.data.positions, str(emp["role"])),
		int(stats["strategy"]), int(stats["creative"]), int(stats["technical"]), int(emp["energy"])], 11, UiUtil.MUTED))
	row.add_child(who)
	var buttons: Array[Button] = []
	for i: int in 3:
		var b: Button = Button.new()
		b.custom_minimum_size = Vector2(COL_CELL, 34.0)
		b.focus_mode = Control.FOCUS_NONE
		b.gui_input.connect(_on_cell_input.bind(id, i))
		buttons.append(b)
		row.add_child(b)
	_cells[id] = buttons
	var load_box: VBoxContainer = UiUtil.vbox(2)
	load_box.custom_minimum_size.x = COL_LOAD
	var load_label: Label = UiUtil.label("", 12, UiUtil.TEXT)
	load_box.add_child(load_label)
	var bar: ProgressBar = ProgressBar.new()
	bar.show_percentage = false
	bar.max_value = DataDB.data.balf("workload.max_load")
	bar.custom_minimum_size = Vector2(COL_LOAD, 8.0)
	load_box.add_child(bar)
	row.add_child(load_box)
	_loads[id] = [load_label, bar]
	return panel


func _focus_section() -> VBoxContainer:
	var box: VBoxContainer = UiUtil.vbox(4)
	box.add_child(UiUtil.label(tr("UI_BOARD_FOCUS"), 13, UiUtil.WOOD))
	_focus_bar = HBoxContainer.new()
	_focus_bar.add_theme_constant_override("separation", 2)
	_focus_bar.custom_minimum_size = Vector2(COL_PERSON + COL_CELL * 3.0 + COL_LOAD, 14.0)
	for i: int in 3:
		var r: ColorRect = ColorRect.new()
		r.color = AREA_COLORS[i]
		r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_focus_bar.add_child(r)
	box.add_child(_focus_bar)
	var legend: HBoxContainer = UiUtil.hbox(18)
	for i: int in 3:
		var l: Label = UiUtil.label("", 12, _ink(i))
		_focus_labels.append(l)
		legend.add_child(l)
	box.add_child(legend)
	return box


## Krem zeminde okunur yazı rengi: alan renginin koyusu.
static func _ink(i: int) -> Color:
	return AREA_COLORS[i].darkened(0.35)


## Prodüksiyon fazı: sahip olunan ekipmanın çarpanı ve bu kampanya için kiralık seçimi (bedel fazı başlatınca ödenir).
func _equipment_section() -> VBoxContainer:
	var box: VBoxContainer = UiUtil.vbox(4)
	_eq_label = UiUtil.label("", 13, UiUtil.WOOD)
	box.add_child(_eq_label)
	var flow: HFlowContainer = HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	var sim: Simulation = GameState.sim
	for id: String in sim.equipment.available(sim.state, "rental"):
		var b: Button = UiUtil.button(tr("UI_BOARD_RENT") % [UiUtil.name_of(DataDB.data.equipment, id),
			UiUtil.money(sim.equipment.price(sim.state, id))], func() -> void: pass)
		b.toggle_mode = true
		b.add_theme_font_size_override("font_size", 13)
		b.toggled.connect(func(on: bool) -> void:
			if on and not _rentals.has(id):
				_rentals.append(id)
			elif not on:
				_rentals.erase(id)
			_update_equipment())
		flow.add_child(b)
	box.add_child(flow)
	_update_equipment()
	return box


func _update_equipment() -> void:
	if _eq_label == null:
		return
	var setup: Dictionary = _camp["setup"]
	var rentals: Array = (setup.get("rentals", []) as Array).duplicate()
	rentals.append_array(_rentals)
	var mult: float = GameState.sim.equipment.production_mult(GameState.sim.state, {"mix": setup["mix"], "rentals": rentals})
	_eq_label.text = tr("UI_BOARD_EQUIPMENT") % mult


func _on_cell_input(event: InputEvent, id: String, area: int) -> void:
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if mb == null or not mb.pressed:
		return
	var step: float = DataDB.data.balf("workload.step")
	var alloc: Array = _plan.get(id, [0.0, 0.0, 0.0])
	if mb.button_index == MOUSE_BUTTON_LEFT:
		var room: float = DataDB.data.balf("workload.max_load") - WorkPlan.load_of_alloc(alloc)
		alloc[area] = minf(1.0, float(alloc[area]) + minf(step, maxf(0.0, room)))
	elif mb.button_index == MOUSE_BUTTON_RIGHT:
		alloc[area] = maxf(0.0, float(alloc[area]) - step)
	else:
		return
	_plan[id] = alloc
	Audio.play("click")
	_refresh()


func _refresh() -> void:
	var data: GameData = DataDB.data
	for id: String in _members:
		var alloc: Array = _plan.get(id, [0.0, 0.0, 0.0])
		var buttons: Array = _cells[id]
		for i: int in 3:
			var v: float = float(alloc[i])
			var b: Button = buttons[i]
			b.text = "—" if v <= 0.0 else UiUtil.percent(roundf(v * 100.0))
			var style: StyleBoxFlat = StyleBoxFlat.new()
			style.bg_color = Color(AREA_COLORS[i], 0.12 + 0.6 * v)
			style.set_corner_radius_all(10)
			for s: String in ["normal", "hover", "pressed"]:
				b.add_theme_stylebox_override(s, style)
			var ink: Color = Color.WHITE if v >= 0.75 else UiUtil.TEXT
			b.add_theme_color_override("font_color", ink)
			b.add_theme_color_override("font_hover_color", ink)
		var load: float = WorkPlan.load_of_alloc(alloc)
		var label: Label = _loads[id][0]
		var bar: ProgressBar = _loads[id][1]
		label.text = tr("UI_BOARD_FREE") if load <= 0.0 else tr("UI_BOARD_LOAD") % UiUtil.percent(roundf(load * 100.0))
		var col: Color = UiUtil.SAGE_DARK if load <= data.balf("workload.warn_load") \
			else (UiUtil.MUSTARD if load <= data.balf("workload.danger_load") else UiUtil.TERRACOTTA)
		label.add_theme_color_override("font_color", UiUtil.MUTED if load <= 0.0 else col)
		bar.value = load
		bar.modulate = col
	var shares: Array = WorkPlan.shares_of(_plan)
	for i: int in 3:
		var r: ColorRect = _focus_bar.get_child(i)
		r.size_flags_stretch_ratio = maxf(0.001, float(shares[i]))
		_focus_labels[i].text = "%s %s" % [UiUtil.name_of(data.focus_areas, _areas[i]), UiUtil.percent(roundf(float(shares[i]) * 100.0))]
	_error.text = ""
	_error.visible = false


func _confirm() -> void:
	var clean: Dictionary = {}
	for id: String in _members:
		var alloc: Array = _plan.get(id, [0.0, 0.0, 0.0])
		if WorkPlan.load_of_alloc(alloc) > 0.0:
			clean[id] = alloc
	var err: String = GameState.set_phase_plan(clean, _rentals)
	if not err.is_empty():
		_error.text = tr(err)
		_error.visible = true
		return
	_on_done.call()
