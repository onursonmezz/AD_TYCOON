class_name WorkBoard
extends VBoxContainer
## Emek dağılımı / görev panosu (K-118), UI-3 kampanya taslağı (03) dilinde: her odak alanı bir satır (ikon, ad,
## öğrenilen önem işareti, alanın payı). Satırda kaydırıcı yerine ekip üyelerinin rozetleri durur; rozete sol tık
## kişinin zamanının %25'ini o alana verir, sağ tık geri alır. Altta kişi başına yük, prodüksiyon fazında ekipman ve
## kiralıklar (K-119), en altta "Otomatik dağıt" ve "Fazı başlat". Onaylanınca GameState.set_phase_plan.

## Alan ikonları (IconPack): stratejide alanın kendi ikonu, diğer fazlarda fazın stat ikonu.
const AREA_ICONS: Dictionary = {"research": "focus-research", "insight": "focus-insight", "positioning": "focus-positioning",
	"concept": "stat-creative", "copy": "stat-creative", "visual": "stat-creative",
	"production": "stat-technical", "media_planning": "stat-technical", "measurement": "stat-technical"}
const NAME_WIDTH: float = 190.0
const LOAD_WIDTH: float = 150.0

var _camp: Dictionary
var _phase: int = 0
var _areas: Array[String] = []
var _members: Array[String] = []
var _plan: Dictionary = {}
var _chips: Dictionary = {}       # emp_id → [Button x3]
var _share_labels: Array[Label] = []
var _loads: Dictionary = {}       # emp_id → [Label, ProgressBar]
var _rentals: Array = []          # prodüksiyon fazında seçilen kiralıklar (K-119)
var _eq_label: Label
var _error: Label
var _on_done: Callable


func _init(camp: Dictionary, on_done: Callable) -> void:
	_camp = camp
	_on_done = on_done
	add_theme_constant_override("separation", CozyTheme.SPACE_S)


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
	add_child(Cards.section(tr("UI_BOARD_TITLE") % tr("PHASE_%d" % _phase), "", "info"))
	add_child(UiUtil.wrapped(tr("UI_BOARD_HINT"), 12, UiUtil.MUTED, 600.0))
	for i: int in 3:
		add_child(_area_row(i))
	add_child(_load_section())
	if _phase == 2:
		add_child(_equipment_section())
	_error = UiUtil.label("", 13, CozyTheme.NEGATIVE)
	_error.visible = false
	add_child(_error)
	add_child(_foot())
	_refresh()


func _area_row(i: int) -> HBoxContainer:
	var data: GameData = DataDB.data
	var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
	row.add_child(UiUtil.icon(str(AREA_ICONS.get(_areas[i], "info")), 22, CozyTheme.TERRA))
	var name_box: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)  # ad ve önem işareti yan yana (K-122)
	name_box.custom_minimum_size.x = NAME_WIDTH
	name_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var name_label: Label = UiUtil.label(UiUtil.name_of(data.focus_areas, _areas[i]), 14, CozyTheme.TEXT)
	name_label.add_theme_font_override("font", CozyTheme.strong_font())
	name_box.add_child(name_label)
	var badge: Label = FocusHint.badge(str(_camp["setup"]["objective"]), _areas[i], 13)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	badge.custom_minimum_size.x = 0.0
	name_box.add_child(badge)
	row.add_child(name_box)
	var flow: HFlowContainer = Cards.flow_row(6)
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for id: String in _members:
		var b: Button = Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(0.0, 28.0)
		b.add_theme_font_size_override("font_size", 12)
		b.add_theme_font_override("font", CozyTheme.strong_font())
		b.tooltip_text = tr("UI_BOARD_CHIP_TIP")
		b.gui_input.connect(_on_chip_input.bind(id, i))
		(_chips.get_or_add(id, [null, null, null]) as Array)[i] = b
		flow.add_child(b)
	row.add_child(flow)
	var share: PanelContainer = Cards.chip("", CozyTheme.SAGE_SOFT, CozyTheme.FOREST)
	share.custom_minimum_size.x = 52.0
	var share_label: Label = share.get_child(0) as Label
	share_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	share_label.add_theme_font_size_override("font_size", 14)
	_share_labels.append(share_label)
	row.add_child(share)
	return row


## Kişi başına yük: %100'e kadar yeşil, sonra altın, %150 üstü kiremit.
func _load_section() -> HFlowContainer:
	var flow: HFlowContainer = Cards.flow_row(CozyTheme.SPACE_M)
	for id: String in _members:
		var emp: Dictionary = GameState.sim.state.staff[id]
		var box: VBoxContainer = UiUtil.vbox(2)
		box.custom_minimum_size.x = LOAD_WIDTH
		var label: Label = UiUtil.label("", 12, CozyTheme.TEXT)
		label.tooltip_text = "%s · %s" % [GameState.employee_name(emp), tr("UI_BOARD_ENERGY") % int(emp["energy"])]
		label.mouse_filter = Control.MOUSE_FILTER_STOP
		box.add_child(label)
		var bar: ProgressBar = ProgressBar.new()
		bar.show_percentage = false
		bar.max_value = DataDB.data.balf("workload.max_load")
		bar.custom_minimum_size = Vector2(LOAD_WIDTH, 8.0)
		box.add_child(bar)
		_loads[id] = [label, bar]
		flow.add_child(box)
	return flow


## Prodüksiyon fazı (K-119): ekipman çarpanı ve bu kampanya için kiralıklar (bedeli faz başlarken ödenir).
func _equipment_section() -> VBoxContainer:
	var box: VBoxContainer = UiUtil.vbox(4)
	_eq_label = UiUtil.label("", 13, CozyTheme.WOOD)
	_eq_label.add_theme_font_override("font", CozyTheme.strong_font())
	box.add_child(_eq_label)
	var flow: HFlowContainer = Cards.flow_row(6)
	var sim: Simulation = GameState.sim
	for id: String in sim.equipment.available(sim.state, "rental"):
		var b: Button = UiUtil.button(tr("UI_BOARD_RENT") % [UiUtil.name_of(DataDB.data.equipment, id),
			UiUtil.money(sim.equipment.price(sim.state, id))], func() -> void: pass)
		b.toggle_mode = true
		b.add_theme_font_size_override("font_size", 12)
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


func _foot() -> HBoxContainer:
	var foot: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
	var hint: Label = UiUtil.wrapped(tr("UI_BOARD_FOOT"), 12, UiUtil.MUTED, 260.0)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(hint)
	var auto: Button = UiUtil.button(tr("UI_BOARD_AUTO"), func() -> void:
		_plan = WorkPlan.auto(DataDB.data, GameState.sim.state, _camp, _phase)
		_refresh())
	auto.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	foot.add_child(auto)
	var start: Button = UiUtil.button(tr("UI_START_PHASE"), _confirm)
	start.theme_type_variation = "PrimaryButton"
	start.custom_minimum_size.x = 150.0
	start.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	foot.add_child(start)
	return foot


func _update_equipment() -> void:
	if _eq_label == null:
		return
	var setup: Dictionary = _camp["setup"]
	var rentals: Array = (setup.get("rentals", []) as Array).duplicate()
	rentals.append_array(_rentals)
	var mult: float = GameState.sim.equipment.production_mult(GameState.sim.state, {"mix": setup["mix"], "rentals": rentals})
	_eq_label.text = tr("UI_BOARD_EQUIPMENT") % mult


func _on_chip_input(event: InputEvent, id: String, area: int) -> void:
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


static func _short_name(emp: Dictionary) -> String:
	return str(GameState.employee_name(emp)).split(" ")[0]


func _refresh() -> void:
	var data: GameData = DataDB.data
	var staff: Dictionary = GameState.sim.state.staff
	for id: String in _members:
		var alloc: Array = _plan.get(id, [0.0, 0.0, 0.0])
		for i: int in 3:
			var v: float = float(alloc[i])
			var b: Button = _chips[id][i]
			b.text = "%s %s" % [_short_name(staff[id]), "·" if v <= 0.0 else UiUtil.percent(roundf(v * 100.0))]
			var fill: Color = CozyTheme.CREAM if v <= 0.0 else CozyTheme.SAGE_SOFT.lerp(CozyTheme.FOREST_LIGHT, clampf(v, 0.0, 1.0))
			var style: StyleBoxFlat = CozyTheme.box(fill, 999, CozyTheme.BORDER, 1, false, Vector2(10, 2))
			for s: String in ["normal", "hover", "pressed"]:
				b.add_theme_stylebox_override(s, style)
			var ink: Color = CozyTheme.CREAM_LIGHT if v >= 0.75 else (CozyTheme.MUTED if v <= 0.0 else CozyTheme.FOREST)
			b.add_theme_color_override("font_color", ink)
			b.add_theme_color_override("font_hover_color", ink)
		var load: float = WorkPlan.load_of_alloc(alloc)
		var label: Label = _loads[id][0]
		var bar: ProgressBar = _loads[id][1]
		label.text = "%s · %s" % [_short_name(staff[id]),
			tr("UI_BOARD_FREE") if load <= 0.0 else tr("UI_BOARD_LOAD") % UiUtil.percent(roundf(load * 100.0))]
		var col: Color = CozyTheme.FOREST if load <= data.balf("workload.warn_load") \
			else (CozyTheme.GOLD if load <= data.balf("workload.danger_load") else CozyTheme.NEGATIVE)
		label.add_theme_color_override("font_color", CozyTheme.MUTED if load <= 0.0 else col)
		bar.value = load
		bar.modulate = col
	var shares: Array = WorkPlan.shares_of(_plan)
	for i: int in 3:
		_share_labels[i].text = UiUtil.percent(roundf(float(shares[i]) * 100.0))
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
