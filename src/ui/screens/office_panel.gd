class_name OfficePanel
extends VBoxContainer
## Ofis (GDD 12.1–12.3): oda kalitesi dökümü, oda etkileri, masa kalitesi, inşa moduna geçiş; sonraki ofisin koşulları ve taşınma.

var _main: Control
var _body: VBoxContainer
var _signature: String = ""
var _col: VBoxContainer  # o an doldurulan sütun

const COLUMN_TEXT: float = 300.0
const OFFICE_ART: float = 84.0
const DESK_ART: int = 40


func _init(main_screen: Control) -> void:
	_main = main_screen
	add_theme_constant_override("separation", 10)
	add_child(UiUtil.heading(tr("MENU_OFFICE")))
	_body = UiUtil.vbox(8)
	add_child(_body)


func refresh() -> void:
	var sim: Simulation = GameState.sim
	var s: SimState = sim.state
	var sig: String = "%d%d%d%d%d" % [s.office_level, s.staff.size(), int(s.cash / 1000.0), s.clock.game_year(), int(s.reputation)] + str(s.build.get("version", 0)) + str(sim.build.weeks_since_watered(s))
	if sig == _signature:
		return
	_signature = sig
	UiUtil.clear(_body)
	# UI-3 (taslak 18): solda mevcut ofis, sağda sonraki ofis ve taşınma koşulları.
	var cols: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_L)
	_body.add_child(cols)
	_col = _column()
	cols.add_child(_col)
	var cur: Dictionary = sim.offices.current(s)
	_col.add_child(Cards.section(tr("UI_OFFICE_CURRENT")))
	_col.add_child(Cards.header(Cards.art("office_art", str(s.office_level), OFFICE_ART, "building"), tr(cur["name_key"]), "",
		[Cards.chip(tr("UI_OFFICE_CURRENT_TAG"))]))
	_col.add_child(UiUtil.wrapped(tr("UI_OFFICE_LINE") % [s.staff.size(), int(cur["capacity"]),
		UiUtil.money(sim.offices.monthly_rent(s)), int(roundf(s.room_quality))], 13, CozyTheme.TEXT, COLUMN_TEXT))
	_col.add_child(Cards.meter(tr("UI_OFFICE_QUALITY"), s.room_quality, CozyTheme.FOREST_LIGHT, 150.0))
	_quality_block(sim, s)
	_col.add_child(_sizes_row(cur["allowed_sizes"]))
	_desk_tiers(sim, s)
	_plants_row(sim, s)
	var build: Button = UiUtil.button(tr("UI_BUILD_MODE"), func() -> void: _main.call("enter_build_mode"))
	build.theme_type_variation = "PrimaryButton"
	build.icon = UiUtil.icon_texture("hammer", 18)
	_col.add_child(build)
	cols.add_child(VSeparator.new())
	_col = _column()
	cols.add_child(_col)
	_col.add_child(Cards.section(tr("UI_OFFICE_NEXT_TITLE")))
	var next: Dictionary = sim.offices.next_office(s)
	if next.is_empty():
		_col.add_child(UiUtil.wrapped(tr("UI_OFFICE_MAX"), 14, UiUtil.MUTED, COLUMN_TEXT))
		return
	_col.add_child(Cards.header(Cards.art("office_art", str(s.office_level + 1), OFFICE_ART, "building-bank", CozyTheme.SAGE_SOFT),
		tr(next["name_key"])))
	_col.add_child(UiUtil.wrapped(tr("UI_OFFICE_LINE_NEXT") % [int(next["capacity"]),
		UiUtil.money(float(next["rent_1990"]) * Economy.inflation(DataDB.data, s.clock.year())), int(next["room_quality"])], 13,
		CozyTheme.TEXT, COLUMN_TEXT))
	_col.add_child(_sizes_row(next["allowed_sizes"]))
	_col.add_child(Cards.section(tr("UI_MOVE_REQS")))
	for r: Dictionary in sim.offices.requirements(s):
		var ok: bool = bool(r["ok"])
		var need: String = UiUtil.money(r["need"]) if r["key"] == "REQ_CASH" else str(int(r["need"]))
		var have: String = UiUtil.money(r["have"]) if r["key"] == "REQ_CASH" else str(int(r["have"]))
		var line: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
		line.add_child(UiUtil.icon("check" if ok else "x", 16, CozyTheme.POSITIVE if ok else CozyTheme.TERRA))
		line.add_child(UiUtil.wrapped(tr(r["key"]) % [need, have], 13, CozyTheme.TEXT if ok else CozyTheme.NEGATIVE, COLUMN_TEXT - 30.0))
		_col.add_child(line)
	var move: Button = UiUtil.button(tr("UI_MOVE_OFFICE") % UiUtil.money(sim.offices.move_cost(s, next)), func() -> void:
		var err: String = GameState.execute(MoveOfficeCommand.new())
		if err.is_empty():
			EventBus.notification.emit("NOTE_MOVED", [tr(sim.offices.current(GameState.sim.state)["name_key"])], "good")
		else:
			EventBus.notification.emit(err, [], "bad")
		_signature = ""
		refresh())
	move.disabled = not sim.offices.can_move(s)
	move.theme_type_variation = "PrimaryButton"
	_col.add_child(move)


func _column() -> VBoxContainer:
	var c: VBoxContainer = UiUtil.vbox(CozyTheme.SPACE_S)
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.custom_minimum_size.x = COLUMN_TEXT
	return c


## Alınabilecek iş büyüklükleri küçük etiketler hâlinde.
func _sizes_row(sizes: Array) -> HFlowContainer:
	var row: HFlowContainer = Cards.flow_row()
	row.add_child(UiUtil.label(tr("UI_OFFICE_JOBS"), 13, CozyTheme.FOREST))
	for size: Variant in sizes:
		row.add_child(Cards.chip(tr("SIZE_" + str(size).to_upper()), CozyTheme.CREAM, CozyTheme.TEXT))
	return row


## Oda kalitesi dökümü (12.3) ve etkin oda etkileri (12.2).
func _quality_block(sim: Simulation, s: SimState) -> void:
	var q: Dictionary = sim.build.quality_parts(s)
	_col.add_child(UiUtil.wrapped(tr("UI_QUALITY_PARTS") % [float(q["base"]), float(q["comfort"]), float(q["variety"]),
		float(q["crowding"]), Employee.office_mult(DataDB.data, s.room_quality)], 12, UiUtil.MUTED, COLUMN_TEXT))
	var effects: PackedStringArray = PackedStringArray()
	for type: String in DataDB.data.room_type_ids:
		if not (DataDB.data.room_types[type]["effects"] as Dictionary).is_empty() and sim.build.layout(s).has_closed_room(type):
			effects.append(tr(DataDB.data.room_types[type]["desc_key"]))
	_col.add_child(UiUtil.wrapped(tr("UI_ROOM_EFFECTS") % ("; ".join(effects) if not effects.is_empty() else tr("UI_NONE")), 12,
		UiUtil.TEXT, COLUMN_TEXT))


## Masa ve sandalye kademesi: yan yana seçim kartları; kullanılan işaretli, diğerlerinde fiyat.
func _desk_tiers(sim: Simulation, s: SimState) -> void:
	_col.add_child(UiUtil.label(tr("UI_DESK_TIER"), 13, CozyTheme.FOREST))
	var tiers: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	var defs: Dictionary = DataDB.data.bal("build.desk_tiers")
	for tier: String in defs:
		var current: bool = s.build["desk_tier"] == tier
		var text: String = tr(defs[tier]["name_key"]) + "\n" + ("✓ " + tr("UI_TOOL_IN_USE") if current
			else UiUtil.money(sim.build.desk_tier_cost(s, tier)))
		var b: Button = UiUtil.button(text, func() -> void:
			var err: String = GameState.execute(SetDeskTierCommand.new(tier))
			if not err.is_empty():
				EventBus.notification.emit(err, [], "bad")
			_signature = ""
			refresh())
		b.theme_type_variation = "PickCardActive" if current else "PickCard"
		b.add_theme_font_size_override("font_size", 11)
		var desk: String = str(DataDB.data.raw["ui_layout.json"]["desk_art"].get(tier, ""))
		b.icon = IconPack.art(desk, DESK_ART) if not desk.is_empty() else null
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		for st: String in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color", "icon_disabled_color"]:
			b.add_theme_color_override(st, Color.WHITE)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.disabled = int(defs[tier]["available_from"]) > s.clock.year()
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE if current else Control.MOUSE_FILTER_STOP
		tiers.add_child(b)
	_col.add_child(tiers)


func _sizes_text(sizes: Array) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for size: Variant in sizes:
		parts.append(tr("SIZE_" + str(size).to_upper()))
	return ", ".join(parts)


## Bitkiler (12.3): sayı, son sulama; kuruysa uyarı. Ofis asistanı varsa o sular.
func _plants_row(sim: Simulation, s: SimState) -> void:
	var count: int = sim.build.plant_count(s)
	if count == 0:
		return
	var row: HFlowContainer = Cards.flow_row(CozyTheme.SPACE_S)
	row.add_child(UiUtil.label(tr("UI_PLANTS_STATE") % [count, sim.build.weeks_since_watered(s)], 13))
	if sim.build.plants_dry(s):
		row.add_child(UiUtil.label(tr("UI_PLANTS_DRY"), 14, UiUtil.TERRACOTTA))
	row.add_child(UiUtil.button(tr("UI_WATER_PLANTS"), func() -> void:
		GameState.execute(WaterPlantsCommand.new())
		_signature = ""
		refresh()))
	_col.add_child(row)
