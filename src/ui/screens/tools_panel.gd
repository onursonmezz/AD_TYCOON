class_name ToolsPanel
extends VBoxContainer
## Araçlar (GDD 12.4–12.5): alan başına araç seti ve çarpanı, sürüm durumu, al / güncelle / aboneliğe geç / iptal;
## bilgisayar kuşağı ve aylık abonelik gideri. "Ekipman" sekmesi: prodüksiyon ekipmanı (K-119, EquipmentList; taslak 15'te yok).
## K-122: kaydırma yok; alanlar iki sütunda, satırlar tek satır (uzun durum metni üzerine gelince).

var _body: VBoxContainer
var _signature: String = ""
var _tab: String = "software"
var _open_areas: Array[String] = []  # "N seçenek daha" ile açılan alanlar


func _init() -> void:
	add_theme_constant_override("separation", 10)
	add_child(UiUtil.heading(tr("MENU_TOOLS")))
	_body = UiUtil.vbox(8)
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_body)


func refresh() -> void:
	var s: SimState = GameState.sim.state
	var sig: String = "%d|%s|%s|%d|%d|%s|%s" % [s.clock.year(), str(s.tools), s.hardware, int(s.cash / 1000.0), s.staff.size(),
		str(s.equipment), _tab]
	if sig == _signature:
		return
	_signature = sig
	rebuild()


func rebuild() -> void:
	UiUtil.clear(_body)
	var sim: Simulation = GameState.sim
	var s: SimState = sim.state
	var data: GameData = DataDB.data
	var tabs: PanelContainer = UiUtil.segmented([["software", "UI_TOOLS_TAB_SOFTWARE"], ["equipment", "UI_TOOLS_TAB_EQUIPMENT"]], _tab,
		func(id: String) -> void:
			_tab = id
			_signature = ""
			refresh())
	tabs.custom_minimum_size.x = 300.0
	if _tab == "equipment":
		_body.add_child(EquipmentList.build(func() -> void:
			_signature = ""
			refresh(), tabs))  # UI-4: sekmeler bakım satırının sağında
		return
	# UI-3 (taslak 15): üstte bilgisayar kuşağı ve aylık abonelik; altında alan alan araç tablosu.
	var head: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
	head.add_child(_hardware_art())
	var hw_col: VBoxContainer = UiUtil.vbox(-2)
	hw_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hw_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hw_col.add_child(UiUtil.label(tr("UI_HARDWARE_COMPAT") % int(data.hardware[s.hardware]["max_tool_year"]), 12, CozyTheme.TEXT))
	var hw: Label = UiUtil.label(tr("UI_HARDWARE_NAME") % tr(data.hardware[s.hardware]["name_key"]), 15, CozyTheme.FOREST)
	hw.add_theme_font_override("font", CozyTheme.title_font(700))
	hw.clip_text = true
	hw_col.add_child(hw)
	hw_col.move_child(hw, 0)
	head.add_child(hw_col)
	var next_hw: String = ""
	for id: String in data.hardware_ids:
		if data.hardware_ids.find(id) > data.hardware_ids.find(s.hardware) and int(data.hardware[id]["available_from"]) <= s.clock.year():
			next_hw = id
	if not next_hw.is_empty():
		var buy: Button = _action_button(tr("UI_HARDWARE_BUY") % [tr(data.hardware[next_hw]["name_key"]),
			UiUtil.money(sim.tools.hardware_cost(s, next_hw))], "hardware", next_hw)
		buy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		head.add_child(buy)
	var monthly: PanelContainer = Cards.chip(tr("UI_TOOLS_MONTHLY") % UiUtil.money(sim.tools.monthly_cost(s)), CozyTheme.CREAM_LIGHT,
		CozyTheme.FOREST, tr("UI_TOOLS_HINT"))
	monthly.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	hw_col.add_child(monthly)
	head.add_child(tabs)  # K-122: sekmeler bilgisayar satırının sağında (ayrı satır kaplamasın)
	_body.add_child(head)
	# UI-4: iki sütun, alanlar satır sayısına göre kısa olan sütuna eklenir (sıra korunur, sütunlar dengeli).
	var pair: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
	_body.add_child(pair)
	var columns: Array[VBoxContainer] = []
	var heights: Array[int] = [0, 0]
	for i: int in 2:
		var c: VBoxContainer = UiUtil.vbox(CozyTheme.SPACE_S)
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pair.add_child(c)
		columns.append(c)
	var blocks: Array = []
	for area: Variant in data.bal("tools.areas"):
		var col: VBoxContainer = UiUtil.vbox(4)
		col.add_child(Cards.section(tr("AREA_" + str(area).to_upper()), "×" + UiUtil.num(float(s.tool_mults.get(area, 1.0)), 2)))
		# Okunurluk (RD-1): sahip olunanlar ve alınabilecek en yeni bir araç; kalanlar "N seçenek daha" ile açılır.
		var owned: Array[String] = []
		var buyable: Array[String] = []
		for id: String in data.tool_ids:
			if data.tools[id]["area"] != area:
				continue
			if sim.tools.owned(s, id):
				owned.append(id)
			elif sim.tools.available(s).has(id):
				buyable.append(id)
		var shown: Array[String] = owned.duplicate()
		var open: bool = _open_areas.has(str(area))
		if open:
			shown.append_array(buyable)
		elif not buyable.is_empty():
			shown.append(buyable[buyable.size() - 1])  # veri sırasında son gelen en yenisi
		for id: String in shown:
			col.add_child(_tool_row(sim, s, id))
		var hidden: int = buyable.size() - (shown.size() - owned.size())
		var rows: int = shown.size()
		if hidden > 0 or open and buyable.size() > 1:
			var more: Button = UiUtil.button(tr("UI_TOOLS_MORE") % hidden if not open else tr("UI_TOOLS_LESS"),
				_toggle_area.bind(str(area)))
			# S7: gizli araçlar görünür bir düğmede (eskiden soluk yazıydı; bırakılan araç orada kayboluyordu).
			Cards.compact(more)
			more.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			col.add_child(more)
			rows += 1
		blocks.append([col, rows + 1])
	# Uzun alanlar önce yerleşir, her biri kısa olan sütuna (iki sütun dengeli kalır).
	blocks.sort_custom(func(a: Array, b: Array) -> bool: return int(a[1]) > int(b[1]))
	for block: Array in blocks:
		var pick: int = 0 if heights[0] <= heights[1] else 1
		columns[pick].add_child(block[0])
		heights[pick] += int(block[1])


func _toggle_area(area: String) -> void:
	if _open_areas.has(area):
		_open_areas.erase(area)
	else:
		_open_areas.append(area)
	_signature = ""
	refresh()


## Bilgisayar çizimi; ekranında açılıştaki gibi markanın (Pear) açık renkli logosu (K-130).
func _hardware_art() -> Control:
	var art: Control = Cards.art("hardware_art", "default", 52.0, "device-desktop")
	var file: String = str((DataDB.data.raw["ui_layout.json"].get("hardware_art", {}) as Dictionary).get("badge", ""))
	var tex: Texture2D = IconPack.art(file, 16) if not file.is_empty() else null
	if tex == null:
		return art
	var box: Control = Control.new()
	box.custom_minimum_size = Vector2(56, 52)
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(art)
	var badge: TextureRect = TextureRect.new()
	badge.texture = tex
	badge.size = Vector2(16, 16)
	badge.position = Vector2(18, 9)
	badge.modulate = Color(1.9, 1.9, 1.9, 0.9)  # gri armut koyu ekranda açık görünsün
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(badge)
	return box


## Aracın parodi logosu (LG-1); sahip olunmayan soluk. Logosu olmayan (defter, daktilo...) genel alet ikonu alır.
func _tool_logo(id: String, owned: bool) -> Control:
	var file: String = str((DataDB.data.raw["ui_layout.json"].get("tool_art", {}) as Dictionary).get(id, ""))
	var tex: Texture2D = IconPack.art(file, 22) if not file.is_empty() else null
	if tex == null:
		return UiUtil.icon("tool", 18, CozyTheme.TERRA if owned else CozyTheme.MUTED)
	var r: TextureRect = TextureRect.new()
	r.texture = tex
	r.custom_minimum_size = Vector2(22, 22)
	r.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.modulate = Color(1, 1, 1, 1.0 if owned else 0.6)
	return r


func _tool_row(sim: Simulation, s: SimState, id: String) -> HBoxContainer:
	var t: Dictionary = DataDB.data.tools[id]
	var year: int = s.clock.year()
	var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	row.custom_minimum_size.y = 28.0
	var owned: bool = sim.tools.owned(s, id)
	row.add_child(_tool_logo(id, owned))
	var name_label: Label = UiUtil.label(UiUtil.name_of(DataDB.data.tools, id), 14, CozyTheme.TEXT)
	name_label.add_theme_font_override("font", CozyTheme.strong_font())
	name_label.custom_minimum_size.x = 104.0  # ad kesilmez ("Nitrosoft StrongPoint"); yer daralırsa durum yazısı kısalır
	name_label.tooltip_text = name_label.text
	name_label.mouse_filter = Control.MOUSE_FILTER_STOP
	row.add_child(name_label)
	var status: String = ""
	var color: Color = UiUtil.TEXT
	if owned:
		var v: int = int(s.tools[id]["version"])
		var behind: int = sim.tools.released_version(id, year) - v
		status = tr("UI_TOOL_VERSION") % int(t["versions"][v][0])
		if bool(s.tools[id]["sub"]):
			status += " · " + tr("UI_TOOL_SUB") % UiUtil.money(sim.tools.seat_cost(s, id))
		if behind > 0:
			status += " · " + tr("UI_TOOL_BEHIND") % behind
			color = UiUtil.TERRACOTTA
	else:
		status = tr("UI_TOOL_NOT_OWNED")
		color = UiUtil.MUTED
	if float(t["ai_penalty"]) > 0.0:
		status += " · " + tr("UI_TOOL_AI")
	var st: Label = UiUtil.label(status, 12, color)
	st.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	st.clip_text = true
	st.tooltip_text = status
	st.mouse_filter = Control.MOUSE_FILTER_STOP
	row.add_child(st)
	# S7: her satırda ya bir düğme ya da durum etiketi var (eskiden güncel araçta ve donanım yetmeyende boş kalıyordu).
	match sim.tools.row_action(s, id):
		"starter":
			row.add_child(Cards.chip("✓ " + tr("UI_TOOL_IN_USE")))
		"latest":
			row.add_child(Cards.chip("✓ " + tr("UI_TOOL_LATEST"), CozyTheme.SAGE_SOFT, CozyTheme.FOREST, tr("UI_TOOL_LATEST_TIP")))
		"needs_hardware":
			row.add_child(Cards.chip(tr("UI_TOOL_NEEDS_HW"), CozyTheme.CREAM, CozyTheme.TERRA, tr("ERR_HARDWARE")))
		"buy":
			var sub_era: bool = sim.tools.is_subscription_era(id, year)
			var price: String = tr("UI_TOOL_SEAT") % UiUtil.money(sim.tools.seat_cost(s, id)) if sub_era \
				else UiUtil.money(sim.tools.license_cost(s, id))
			if not sub_era and is_zero_approx(sim.tools.license_cost(s, id)):
				price = tr("UI_TOOL_FREE")
			row.add_child(_action_button(tr("UI_TOOL_BUY") % price, "buy", id))
		"cancel":
			row.add_child(_action_button(tr("UI_TOOL_CANCEL"), "cancel", id))
		"subscribe":
			row.add_child(_action_button(tr("UI_TOOL_SUBSCRIBE") % UiUtil.money(sim.tools.seat_cost(s, id)), "subscribe", id))
		"update":
			row.add_child(_action_button(tr("UI_TOOL_UPDATE") % UiUtil.money(sim.tools.update_cost(s, id)), "update", id))
	return row


func _action_button(text: String, action: String, id: String) -> Button:
	var b: Button = UiUtil.button(text, func() -> void:
		var err: String = GameState.execute(ToolActionCommand.new(action, id))
		if not err.is_empty():
			EventBus.notification.emit(err, [], "bad")
		_signature = ""
		refresh())
	Cards.compact(b)
	return b
