class_name EquipmentList
extends RefCounted
## Araçlar penceresinin "Ekipman" sekmesi (K-119): sahip olunan ve alınabilen ekipman, grup başına en iyisi,
## aylık bakım; kiralıkların listesi (seçimi kampanyanın prodüksiyon fazında yapılır).


## on_change: bir alım/satımdan sonra pencereyi yenilemek için.
static func build(on_change: Callable) -> VBoxContainer:
	var sim: Simulation = GameState.sim
	var s: SimState = sim.state
	var data: GameData = DataDB.data
	var box: VBoxContainer = UiUtil.vbox(8)
	box.add_child(UiUtil.wrapped(TranslationServer.translate("UI_EQ_HINT"), 14, UiUtil.MUTED, 640.0))
	box.add_child(UiUtil.label(TranslationServer.translate("UI_EQ_MONTHLY") % UiUtil.money(sim.equipment.monthly_cost(s)), 14,
		UiUtil.WOOD))
	var best: Dictionary = sim.equipment.best_by_group(s, {})
	var shown: Array[String] = []
	for id: String in data.equipment_ids:
		var e: Dictionary = data.equipment[id]
		if e["kind"] != "owned":
			continue
		if sim.equipment.owns(s, id) or sim.equipment.available(s, "owned").has(id):
			shown.append(id)
	for id: String in shown:
		box.add_child(_row(id, best, on_change))
	box.add_child(UiUtil.label(TranslationServer.translate("UI_EQ_RENTALS"), 16, UiUtil.SAGE_DARK))
	for id: String in sim.equipment.available(s, "rental"):
		var e: Dictionary = data.equipment[id]
		var row: HBoxContainer = UiUtil.hbox()
		var name_label: Label = UiUtil.label(UiUtil.name_of(data.equipment, id), 15)
		name_label.custom_minimum_size.x = 230.0
		row.add_child(name_label)
		row.add_child(UiUtil.label(TranslationServer.translate("UI_EQ_RENT_ROW") % [int(roundf(float(e["bonus"]) * 100.0)),
			_needs(e), UiUtil.money(sim.equipment.price(s, id))], 13, UiUtil.TEXT))
		box.add_child(row)
	return box


static func _needs(e: Dictionary) -> String:
	return TranslationServer.translate("EQ_NEEDS_" + str(e["needs"]).to_upper())


static func _row(id: String, best: Dictionary, on_change: Callable) -> HBoxContainer:
	var sim: Simulation = GameState.sim
	var s: SimState = sim.state
	var e: Dictionary = DataDB.data.equipment[id]
	var row: HBoxContainer = UiUtil.hbox()
	var name_label: Label = UiUtil.label(UiUtil.name_of(DataDB.data.equipment, id), 15)
	name_label.custom_minimum_size.x = 230.0
	row.add_child(name_label)
	var owned: bool = sim.equipment.owns(s, id)
	var outdated: bool = owned and str(best.get(e["group"], id)) != id
	var info: String = TranslationServer.translate("UI_EQ_ROW") % [int(roundf(float(e["bonus"]) * 100.0)), _needs(e),
		UiUtil.money(float(e.get("upkeep_1990", 0.0)) * Economy.inflation(DataDB.data, s.clock.year()))]
	if outdated:
		info += " · " + TranslationServer.translate("UI_EQ_OUTDATED")
	row.add_child(UiUtil.label(info, 13, UiUtil.MUTED if outdated else (UiUtil.SAGE_DARK if owned else UiUtil.TEXT)))
	row.add_child(UiUtil.spacer())
	var action: String = "sell" if owned else "buy"
	var text: String = TranslationServer.translate("UI_EQ_SELL") % UiUtil.money(sim.equipment.price(s, id)
		* DataDB.data.balf("equipment.sell_refund")) if owned else TranslationServer.translate("UI_EQ_BUY") % UiUtil.money(sim.equipment.price(s, id))
	var b: Button = UiUtil.button(text, func() -> void:
		var err: String = GameState.execute(EquipmentActionCommand.new(action, id))
		if not err.is_empty():
			EventBus.notification.emit(err, [], "bad")
		on_change.call())
	b.add_theme_font_size_override("font_size", 13)
	row.add_child(b)
	return row
