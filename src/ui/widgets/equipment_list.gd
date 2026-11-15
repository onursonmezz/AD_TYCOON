class_name EquipmentList
extends RefCounted
## Araçlar penceresinin "Ekipman" sekmesi (K-119): sahip olunan ve alınabilen ekipman, grup başına en iyisi,
## aylık bakım; kiralıkların listesi (seçimi kampanyanın prodüksiyon fazında yapılır).
## UI-4: gruplar (kamera, fotoğraf, ışık…) iki dengeli sütunda, her grubun görseli; grup başına sahip olunanlar ve
## alınabilecek en iyi bir tane (eskimiş seçenekler kalabalık etmesin); uzun açıklama bilgi işaretinin ipucunda.

## Grup → ikon paketi görseli (assets/ui/icons).
const GROUP_ART: Dictionary = {"camera": "sinema", "photo": "dergi-ilani", "light": "yildiz-isiltilari", "sound": "radyo",
	"aerial": "acik-hava-kategorisi", "set": "fuar-standi", "crew": "ekip"}


## on_change: bir alım/satımdan sonra pencereyi yenilemek için. tabs: sağ üstte duracak sekme şeridi.
static func build(on_change: Callable, tabs: Control = null) -> VBoxContainer:
	var sim: Simulation = GameState.sim
	var s: SimState = sim.state
	var data: GameData = DataDB.data
	var box: VBoxContainer = UiUtil.vbox(CozyTheme.SPACE_S)
	var top: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	top.add_child(Cards.chip(UiUtil.tr_fmt("UI_EQ_MONTHLY", [UiUtil.money(sim.equipment.monthly_cost(s))]), CozyTheme.CREAM_LIGHT,
		CozyTheme.FOREST))
	var info: TextureRect = UiUtil.icon("info", 16, CozyTheme.FOREST)
	info.mouse_filter = Control.MOUSE_FILTER_STOP
	info.tooltip_text = TranslationServer.translate("UI_EQ_HINT")
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(info)
	top.add_child(UiUtil.spacer())
	if tabs != null:
		top.add_child(tabs)
	box.add_child(top)
	var best: Dictionary = sim.equipment.best_by_group(s, {})
	# Grup sırası veriden; her grupta sahip olunanlar + alınabilen en güçlü bir tane.
	var groups: Array[String] = []
	var items: Dictionary = {}
	for id: String in data.equipment_ids:
		var e: Dictionary = data.equipment[id]
		if e["kind"] != "owned":
			continue
		var g: String = str(e["group"])
		if not groups.has(g):
			groups.append(g)
			items[g] = []
		if sim.equipment.owns(s, id):
			(items[g] as Array).append(id)
	for g: String in groups:
		var next: String = ""
		for id: String in sim.equipment.available(s, "owned"):
			if str(data.equipment[id]["group"]) == g and not sim.equipment.owns(s, id):
				if next.is_empty() or float(data.equipment[id]["bonus"]) > float(data.equipment[next]["bonus"]):
					next = id
		if not next.is_empty():
			(items[g] as Array).append(next)
	var pair: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
	box.add_child(pair)
	var cols: Array[VBoxContainer] = []
	var heights: Array[int] = [0, 0]
	for i: int in 2:
		var c: VBoxContainer = UiUtil.vbox(CozyTheme.SPACE_S)
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pair.add_child(c)
		cols.append(c)
	for g: String in groups:
		if (items[g] as Array).is_empty():
			continue
		var col: VBoxContainer = UiUtil.vbox(4)
		col.add_child(_group_head(g))
		for id: String in items[g]:
			col.add_child(_row(id, best, on_change))
		var pick: int = 0 if heights[0] <= heights[1] else 1
		cols[pick].add_child(col)
		heights[pick] += (items[g] as Array).size() + 1
	var rentals: Array = sim.equipment.available(s, "rental")
	if not rentals.is_empty():
		box.add_child(Cards.section(TranslationServer.translate("UI_EQ_RENTALS"), "", "receipt"))
		var flow: HFlowContainer = Cards.flow_row(CozyTheme.SPACE_S)
		for id: String in rentals:
			var e: Dictionary = data.equipment[id]
			flow.add_child(Cards.chip("%s · +%s · %s" % [UiUtil.name_of(data.equipment, id),
				UiUtil.percent(float(e["bonus"]) * 100.0), UiUtil.money(sim.equipment.price(s, id))], CozyTheme.CREAM_LIGHT,
				CozyTheme.TEXT, TranslationServer.translate("UI_EQ_RENT_ROW") % [int(roundf(float(e["bonus"]) * 100.0)), _needs(e),
				UiUtil.money(sim.equipment.price(s, id))]))
		box.add_child(flow)
	return box


static func _group_head(g: String) -> PanelContainer:
	var band: PanelContainer = Cards.section(TranslationServer.translate("EQ_GROUP_" + g.to_upper()))
	var row: HBoxContainer = band.get_child(0) as HBoxContainer
	var art: Texture2D = IconPack.art(str(GROUP_ART.get(g, "araclar")), 40)
	if art != null:
		var pic: TextureRect = TextureRect.new()
		pic.texture = art
		pic.custom_minimum_size = Vector2(20, 20)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(pic)
		row.move_child(pic, 0)
	return band


static func _needs(e: Dictionary) -> String:
	return TranslationServer.translate("EQ_NEEDS_" + str(e["needs"]).to_upper())


## Tek satır: durum işareti, ad (kısalırsa ipucunda tamamı), etki etiketi, al/sat düğmesi.
static func _row(id: String, best: Dictionary, on_change: Callable) -> HBoxContainer:
	var sim: Simulation = GameState.sim
	var s: SimState = sim.state
	var e: Dictionary = DataDB.data.equipment[id]
	var owned: bool = sim.equipment.owns(s, id)
	var outdated: bool = owned and str(best.get(e["group"], id)) != id
	var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	row.custom_minimum_size.y = 26.0
	row.add_child(UiUtil.icon("check" if owned else "tool", 16,
		(CozyTheme.MUTED if outdated else CozyTheme.POSITIVE) if owned else CozyTheme.MUTED))
	var name_label: Label = UiUtil.label(UiUtil.name_of(DataDB.data.equipment, id), 13, CozyTheme.MUTED if outdated else CozyTheme.TEXT)
	name_label.add_theme_font_override("font", CozyTheme.strong_font())
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	var tip: String = TranslationServer.translate("UI_EQ_ROW") % [int(roundf(float(e["bonus"]) * 100.0)), _needs(e),
		UiUtil.money(float(e.get("upkeep_1990", 0.0)) * Economy.inflation(DataDB.data, s.clock.year()))]
	if outdated:
		tip += " · " + TranslationServer.translate("UI_EQ_OUTDATED")
	name_label.tooltip_text = tip
	name_label.mouse_filter = Control.MOUSE_FILTER_STOP
	row.add_child(name_label)
	row.add_child(Cards.chip("+%s %s" % [UiUtil.percent(float(e["bonus"]) * 100.0), _needs(e)],
		CozyTheme.SAGE_SOFT if owned and not outdated else CozyTheme.CREAM, CozyTheme.FOREST))
	var action: String = "sell" if owned else "buy"
	var text: String = TranslationServer.translate("UI_EQ_SELL") % UiUtil.money(sim.equipment.price(s, id)
		* DataDB.data.balf("equipment.sell_refund")) if owned else TranslationServer.translate("UI_EQ_BUY") % UiUtil.money(sim.equipment.price(s, id))
	var b: Button = UiUtil.button(text, func() -> void:
		var err: String = GameState.execute(EquipmentActionCommand.new(action, id))
		if not err.is_empty():
			EventBus.notification.emit(err, [], "bad")
		on_change.call())
	Cards.compact(b, not owned)
	row.add_child(b)
	return row
