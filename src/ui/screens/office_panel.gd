class_name OfficePanel
extends VBoxContainer
## Ofis (GDD 12.1): şimdiki ofis ve bir sonrakinin koşulları; taşınma. 3D ofis M6'da.

var _body: VBoxContainer
var _signature: String = ""


func _init() -> void:
	add_theme_constant_override("separation", 10)
	add_child(UiUtil.heading(tr("MENU_OFFICE")))
	_body = UiUtil.vbox(8)
	add_child(_body)


func refresh() -> void:
	var sim: Simulation = GameState.sim
	var s: SimState = sim.state
	var sig: String = "%d%d%d%d%d" % [s.office_level, s.staff.size(), int(s.cash / 1000.0), s.clock.game_year(), int(s.reputation)]
	if sig == _signature:
		return
	_signature = sig
	UiUtil.clear(_body)
	var cur: Dictionary = sim.offices.current(s)
	_body.add_child(UiUtil.label(tr(cur["name_key"]), 20, UiUtil.SAGE_DARK))
	_body.add_child(UiUtil.label(tr("UI_OFFICE_LINE") % [s.staff.size(), int(cur["capacity"]),
		UiUtil.money(sim.offices.monthly_rent(s)), int(cur["room_quality"])], 15))
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


func _sizes_text(sizes: Array) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for size: Variant in sizes:
		parts.append(tr("SIZE_" + str(size).to_upper()))
	return ", ".join(parts)
