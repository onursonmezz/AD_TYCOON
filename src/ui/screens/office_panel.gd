class_name OfficePanel
extends VBoxContainer
## Ofis (GDD 12.1–12.3): oda kalitesi dökümü, oda etkileri, masa kalitesi, inşa moduna geçiş; sonraki ofisin koşulları ve taşınma.

var _main: Control
var _body: VBoxContainer
var _signature: String = ""


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
	var cur: Dictionary = sim.offices.current(s)
	_body.add_child(UiUtil.label(tr(cur["name_key"]), 20, UiUtil.SAGE_DARK))
	_body.add_child(UiUtil.label(tr("UI_OFFICE_LINE") % [s.staff.size(), int(cur["capacity"]),
		UiUtil.money(sim.offices.monthly_rent(s)), int(roundf(s.room_quality))], 15))
	_quality_block(sim, s)
	_body.add_child(UiUtil.label(tr("UI_OFFICE_SIZES") % _sizes_text(cur["allowed_sizes"]), 14, UiUtil.WOOD))
	var next: Dictionary = sim.offices.next_office(s)
	if next.is_empty():
		_body.add_child(UiUtil.label(tr("UI_OFFICE_MAX"), 15, UiUtil.MUTED))
		return
	_body.add_child(UiUtil.label(" ", 6))
	_body.add_child(UiUtil.label(tr("UI_OFFICE_NEXT") % tr(next["name_key"]), 18, UiUtil.SAGE_DARK))
	_body.add_child(UiUtil.label(tr("UI_OFFICE_LINE_NEXT") % [int(next["capacity"]),
		UiUtil.money(float(next["rent_1990"]) * Economy.inflation(DataDB.data, s.clock.year())), int(next["room_quality"])], 15))
	_body.add_child(UiUtil.label(tr("UI_OFFICE_SIZES") % _sizes_text(next["allowed_sizes"]), 14, UiUtil.WOOD))
	for r: Dictionary in sim.offices.requirements(s):
		var ok: bool = bool(r["ok"])
		var need: String = UiUtil.money(r["need"]) if r["key"] == "REQ_CASH" else str(int(r["need"]))
		var have: String = UiUtil.money(r["have"]) if r["key"] == "REQ_CASH" else str(int(r["have"]))
		_body.add_child(UiUtil.label(("✓ " if ok else "✗ ") + tr(r["key"]) % [need, have], 15,
			UiUtil.SAGE_DARK if ok else UiUtil.TERRACOTTA))
	var move: Button = UiUtil.button(tr("UI_MOVE_OFFICE") % UiUtil.money(sim.offices.move_cost(s, next)), func() -> void:
		var err: String = GameState.execute(MoveOfficeCommand.new())
		if err.is_empty():
			EventBus.notification.emit("NOTE_MOVED", [tr(sim.offices.current(GameState.sim.state)["name_key"])], "good")
		else:
			EventBus.notification.emit(err, [], "bad")
		_signature = ""
		refresh())
	move.disabled = not sim.offices.can_move(s)
	_body.add_child(move)


## Oda kalitesi dökümü (12.3), etkin oda etkileri (12.2), masa kalitesi ve inşa modu düğmesi.
func _quality_block(sim: Simulation, s: SimState) -> void:
	var q: Dictionary = sim.build.quality_parts(s)
	_body.add_child(UiUtil.label(tr("UI_QUALITY_PARTS") % [float(q["base"]), float(q["comfort"]), float(q["variety"]),
		float(q["crowding"]), Employee.office_mult(DataDB.data, s.room_quality)], 14, UiUtil.WOOD))
	var effects: PackedStringArray = PackedStringArray()
	for type: String in DataDB.data.room_type_ids:
		if not (DataDB.data.room_types[type]["effects"] as Dictionary).is_empty() and sim.build.layout(s).has_closed_room(type):
			effects.append(tr(DataDB.data.room_types[type]["desc_key"]))
	_body.add_child(UiUtil.wrapped(tr("UI_ROOM_EFFECTS") % ("; ".join(effects) if not effects.is_empty() else tr("UI_NONE")), 14,
		UiUtil.TEXT, 600.0))
	var tiers: HBoxContainer = UiUtil.hbox()
	tiers.add_child(UiUtil.label(tr("UI_DESK_TIER"), 14))
	var defs: Dictionary = DataDB.data.bal("build.desk_tiers")
	for tier: String in defs:
		var current: bool = s.build["desk_tier"] == tier
		var text: String = tr(defs[tier]["name_key"]) + ("" if current else " (%s)" % UiUtil.money(sim.build.desk_tier_cost(s, tier)))
		var b: Button = UiUtil.button(text, func() -> void:
			var err: String = GameState.execute(SetDeskTierCommand.new(tier))
			if not err.is_empty():
				EventBus.notification.emit(err, [], "bad")
			_signature = ""
			refresh())
		b.disabled = current or int(defs[tier]["available_from"]) > s.clock.year()
		tiers.add_child(b)
	_body.add_child(tiers)
	_plants_row(sim, s)
	_body.add_child(UiUtil.button(tr("UI_BUILD_MODE"), func() -> void: _main.call("enter_build_mode")))


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
	var row: HBoxContainer = UiUtil.hbox()
	row.add_child(UiUtil.label(tr("UI_PLANTS_STATE") % [count, sim.build.weeks_since_watered(s)], 14))
	if sim.build.plants_dry(s):
		row.add_child(UiUtil.label(tr("UI_PLANTS_DRY"), 14, UiUtil.TERRACOTTA))
	row.add_child(UiUtil.button(tr("UI_WATER_PLANTS"), func() -> void:
		GameState.execute(WaterPlantsCommand.new())
		_signature = ""
		refresh()))
	_body.add_child(row)
