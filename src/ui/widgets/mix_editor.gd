class_name MixEditor
extends VBoxContainer
## Kanal karışımı düzenleyicisi (GDD 7.1, 7.3, 9.1): kanal satırları, bütçe öncelikleri (gerçek pay yanında),
## basılı kanallarda baskı ayarları ("Otomatik" varsayılan) ve matbaa pazarlığı.

var _brief: Dictionary
var _limit: int
var _main: Control
var _rows: Array[Dictionary] = []
var _rows_box: VBoxContainer
var _add_button: Button
var _channel_ids: Array[String] = []


func _init(brief: Dictionary, limit: int, main_screen: Control) -> void:
	_brief = brief
	_limit = limit
	_main = main_screen
	add_theme_constant_override("separation", 6)
	var data: GameData = DataDB.data
	var year: int = GameState.sim.state.clock.year()
	for id: String in data.channels_available(year):
		if float(brief["media_budget"]) >= float(data.channels[id]["min_budget"]) * Economy.inflation(data, year) \
				and GameState.sim.research.channel_unlocked(GameState.sim.state, id):
			_channel_ids.append(id)
	var head: HBoxContainer = UiUtil.hbox()
	head.add_child(UiUtil.label(tr("UI_CHANNEL_MIX") % _limit, 16))
	head.add_child(UiUtil.spacer())
	_add_button = UiUtil.button(tr("UI_ADD_CHANNEL"), func() -> void: _add_row(0))
	head.add_child(_add_button)
	add_child(head)
	_rows_box = UiUtil.vbox(8)
	add_child(_rows_box)
	if not _channel_ids.is_empty():
		_add_row(0)


func media_budget() -> float:
	return float(_brief["media_budget"])


## Dönüş: [{ "channel", "share", "options": { "job" | "influencer" | kategori seçenekleri } }] — paylar öncelik oranından, toplam tam 1.
func get_mix() -> Array:
	var total: float = 0.0
	for row: Dictionary in _rows:
		total += (row["slider"] as HSlider).value
	var mix: Array = []
	var used: float = 0.0
	for i: int in _rows.size():
		var row: Dictionary = _rows[i]
		var share: float = 1.0 / _rows.size() if total <= 0.0 else (row["slider"] as HSlider).value / total
		if i == _rows.size() - 1:
			share = 1.0 - used
		used += share
		var entry: Dictionary = {"channel": _channel_ids[(row["pick"] as OptionButton).selected], "share": share}
		if not (row["job"] as Dictionary).is_empty():
			entry["options"] = {"job": (row["job"] as Dictionary).duplicate()}
		elif not str(row["influencer"]).is_empty():
			entry["options"] = {"influencer": row["influencer"]}
		elif not (row["opts"] as Dictionary).is_empty():
			entry["options"] = (row["opts"] as Dictionary).duplicate()
		mix.append(entry)
	return mix


func _add_row(channel_index: int) -> void:
	if _rows.size() >= _limit or _channel_ids.is_empty():
		return
	var data: GameData = DataDB.data
	var box: VBoxContainer = UiUtil.vbox(4)
	var line: HBoxContainer = UiUtil.hbox(8)
	var pick: OptionButton = OptionButton.new()
	for id: String in _channel_ids:
		pick.add_item("%s (%s)" % [UiUtil.name_of(data.channels, id), tr("CAT_" + str(data.channels[id]["category"]).to_upper())])
	pick.selected = channel_index
	pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(pick)
	var slider: HSlider = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.value = DataDB.data.balf("focus.slider_default_priority")
	slider.custom_minimum_size.x = 140.0
	line.add_child(slider)
	var share_label: Label = UiUtil.label("", 15)
	share_label.custom_minimum_size.x = 120.0
	line.add_child(share_label)
	var remove: Button = Button.new()
	remove.text = "✕"
	remove.tooltip_text = tr("UI_REMOVE_CHANNEL")
	line.add_child(remove)
	box.add_child(line)
	var print_box: VBoxContainer = UiUtil.vbox(4)
	box.add_child(print_box)
	var row: Dictionary = {"box": box, "pick": pick, "slider": slider, "share": share_label, "print_box": print_box,
		"job": {}, "auto": true, "opts": {}, "influencer": ""}
	_rows.append(row)
	_rows_box.add_child(box)
	pick.item_selected.connect(func(_i: int) -> void:
		row["job"] = {}
		row["auto"] = true
		row["opts"] = {}
		row["influencer"] = ""
		_refresh())
	slider.value_changed.connect(func(_v: float) -> void: _refresh())
	remove.pressed.connect(func() -> void:
		if _rows.size() <= 1:
			return
		_rows.erase(row)
		box.queue_free()
		_refresh())
	_refresh()


## Payları, uyarıları ve basılı iş panellerini günceller. Otomatik baskı işi her değişiklikte bütçeye göre yeniden kurulur.
func _refresh() -> void:
	_add_button.disabled = _rows.size() >= _limit
	var mix: Array = get_mix()
	var data: GameData = DataDB.data
	var sim: Simulation = GameState.sim
	var infl: float = Economy.inflation(data, sim.state.clock.year())
	for i: int in _rows.size():
		var row: Dictionary = _rows[i]
		var ch: String = mix[i]["channel"]
		var budget: float = media_budget() * float(mix[i]["share"])
		var label: Label = row["share"]
		label.text = "%s · %s" % [UiUtil.percent(roundf(float(mix[i]["share"]) * 100.0)), UiUtil.money(budget)]
		var too_small: bool = budget < float(data.channels[ch]["min_budget"]) * infl
		label.add_theme_color_override("font_color", UiUtil.TERRACOTTA if too_small else UiUtil.TEXT)
		label.tooltip_text = tr("UI_MIN_BUDGET") % UiUtil.money(float(data.channels[ch]["min_budget"]) * infl)
		if PrintSystem.is_print_channel(data, ch):
			if bool(row["auto"]) or (row["job"] as Dictionary).is_empty():
				var discount: float = float((row["job"] as Dictionary).get("negotiated_discount", 0.0))
				row["job"] = sim.prints.auto_job(ch, budget, _brief["sector"], sim.state, int(_brief["deadline_weeks"]))
				row["job"]["negotiated_discount"] = discount
			_build_print_panel(row, ch, budget)
		elif InfluencerSystem.is_influencer_channel(data, ch):
			row["job"] = {}
			_build_influencer_panel(row, ch, budget)
		else:
			row["job"] = {}
			_build_options_panel(row, ch)


func _build_print_panel(row: Dictionary, channel_id: String, budget: float) -> void:
	var box: VBoxContainer = row["print_box"]
	UiUtil.clear(box)
	var data: GameData = DataDB.data
	var sim: Simulation = GameState.sim
	var job: Dictionary = row["job"]
	var grid: HFlowContainer = HFlowContainer.new()
	grid.add_theme_constant_override("h_separation", 8)
	var product_ids: Array = data.channels[channel_id]["print_products"]
	grid.add_child(_option(product_ids, job["product"], func(id: String) -> String: return tr(data.print_products[id]["name_key"]),
		func(id: String) -> void:
			job["product"] = id
			job["distribution"] = str(data.print_products[id]["distributions"][0])
			_manual(row)))
	var qualities: Array = (data.bal("print.quality_mult") as Dictionary).keys()
	grid.add_child(_option(qualities, job["quality"], func(id: String) -> String: return tr("QUALITY_" + id.to_upper()),
		func(id: String) -> void:
			job["quality"] = id
			_manual(row)))
	grid.add_child(_option(data.print_products[job["product"]]["distributions"], job["distribution"],
		func(id: String) -> String: return tr(data.distributions[id]["name_key"]),
		func(id: String) -> void:
			job["distribution"] = id
			_manual(row)))
	grid.add_child(_option(data.supplier_ids, job["supplier"], func(id: String) -> String: return tr(data.suppliers[id]["name_key"]),
		func(id: String) -> void:
			job["supplier"] = id
			job["negotiated_discount"] = 0.0
			_manual(row)))
	var qty: SpinBox = SpinBox.new()
	var product: Dictionary = data.print_products[job["product"]]
	qty.max_value = float(product["max_quantity"])
	qty.min_value = float(product["min_quantity"])
	qty.step = 1000.0 if float(product["min_quantity"]) >= 1000.0 else 10.0
	qty.value = float(job["quantity"])
	qty.suffix = tr("UI_PIECES")
	qty.custom_minimum_size.x = 170.0
	qty.value_changed.connect(func(v: float) -> void:
		job["quantity"] = int(v)
		_manual(row))
	grid.add_child(qty)
	var proof: CheckBox = CheckBox.new()
	proof.text = tr("UI_PROOF")
	proof.tooltip_text = tr("TIP_PROOF")
	proof.button_pressed = bool(job["proof"])
	UiUtil.style_toggle(proof)
	proof.toggled.connect(func(on: bool) -> void:
		job["proof"] = on
		_manual(row))
	grid.add_child(proof)
	box.add_child(grid)
	var cost: Dictionary = sim.prints.cost(job, sim.state)
	var margin: float = budget - float(cost["total"])
	var weeks: int = sim.prints.delivery_weeks(job, sim.state)
	var window: int = PrintSystem.print_window_weeks(int(_brief["deadline_weeks"]))
	var info: HBoxContainer = UiUtil.hbox(10)
	var cost_label: Label = UiUtil.label(tr("UI_PRINT_COST") % [UiUtil.money(cost["total"]), UiUtil.money(margin), weeks], 14,
		UiUtil.TERRACOTTA if margin < 0.0 or weeks > window else UiUtil.WOOD)
	if weeks > window:
		cost_label.text += " · " + tr("UI_PRINT_LATE_WARNING") % window
	info.add_child(cost_label)
	info.add_child(UiUtil.spacer())
	if float(job.get("negotiated_discount", 0.0)) > 0.0:
		info.add_child(UiUtil.label(tr("UI_NEGOTIATED") % int(roundf(100.0 * float(job["negotiated_discount"]))), 14, UiUtil.SAGE_DARK))
	info.add_child(UiUtil.button(tr("UI_NEGOTIATE"), func() -> void:
		var list_job: Dictionary = job.duplicate()
		list_job["negotiated_discount"] = 0.0
		var list_price: float = float(sim.prints.cost(list_job, sim.state)["total"])
		_main.call("open_modal", NegotiationDialog.new(job["supplier"], list_price, func(discount: float) -> void:
			job["negotiated_discount"] = discount
			_refresh()))))
	info.add_child(UiUtil.button(tr("UI_AUTO"), func() -> void:
		row["auto"] = true
		_refresh()))
	box.add_child(info)


func _manual(row: Dictionary) -> void:
	row["auto"] = false
	_refresh.call_deferred()


func _option(ids: Array, selected: String, label_of: Callable, on_pick: Callable) -> OptionButton:
	var o: OptionButton = OptionButton.new()
	for i: int in ids.size():
		o.add_item(str(label_of.call(str(ids[i]))))
		if str(ids[i]) == selected:
			o.selected = i
	o.item_selected.connect(func(i: int) -> void: on_pick.call(str(ids[i])))
	return o


## Kategori seçenekleri (GDD 9.2–9.7): veriden otomatik çizilir; varsayılan "Otomatik".
func _build_options_panel(row: Dictionary, channel_id: String) -> void:
	var box: VBoxContainer = row["print_box"]
	UiUtil.clear(box)
	var sim: Simulation = GameState.sim
	var defs: Array = sim.options.option_defs(channel_id)
	if defs.is_empty():
		row["opts"] = {}
		return
	var opts: Dictionary = row["opts"]
	var defaults: Dictionary = sim.options.defaults(channel_id)
	var flow: HFlowContainer = HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 8)
	var year: int = sim.state.clock.year()
	for def: Dictionary in defs:
		var key: String = def["id"]
		if not opts.has(key):
			opts[key] = defaults[key]
		var ids: Array = []
		for c: Dictionary in def["choices"]:
			if int(c.get("from_year", 0)) <= year:
				ids.append(str(c["id"]))
		var names: Dictionary = {}
		for c: Dictionary in def["choices"]:
			names[str(c["id"])] = tr(c["name_key"])
		var label: Label = UiUtil.label(tr(def["name_key"]), 14, UiUtil.WOOD)
		flow.add_child(label)
		flow.add_child(_option(ids, str(opts[key]), func(id: String) -> String: return str(names[id]),
			func(id: String) -> void: opts[key] = id))
	box.add_child(flow)


## Influencer seçici (GDD 9.6): havuzdaki uygun kademeden; sahte takipçi oranı ancak PR ekibi varsa görünür.
func _build_influencer_panel(row: Dictionary, channel_id: String, budget: float) -> void:
	var box: VBoxContainer = row["print_box"]
	UiUtil.clear(box)
	var sim: Simulation = GameState.sim
	var pool: Array[Dictionary] = sim.influencers.pool_for(sim.state, channel_id)
	if pool.is_empty():
		box.add_child(UiUtil.label(tr("UI_NO_INFLUENCERS"), 14, UiUtil.TERRACOTTA))
		return
	var ids: Array = []
	var texts: Dictionary = {}
	var see: bool = sim.influencers.can_see_authenticity(sim.state)
	for inf: Dictionary in pool:
		ids.append(inf["id"])
		var text: String = tr("UI_INFLUENCER_ROW") % [inf["name"], tr("TIER_" + str(inf["tier"]).to_upper()),
			tr("NICHE_" + str(inf["niche"]).to_upper()), UiUtil.big_number(float(inf["followers"])), 100.0 * float(inf["er"]),
			UiUtil.money(sim.influencers.fee(sim.state, inf))]
		if see:
			text += " · " + tr("UI_AUTHENTICITY") % int(roundf(100.0 * float(inf["authenticity"])))
		texts[inf["id"]] = text
	if str(row["influencer"]).is_empty() or not ids.has(row["influencer"]):
		row["influencer"] = sim.influencers.auto_pick(sim.state, channel_id, budget, {"audience": "adult", "sector": _brief["sector"]})
		if str(row["influencer"]).is_empty():
			row["influencer"] = ids[0]
	var pick: OptionButton = _option(ids, str(row["influencer"]), func(id: String) -> String: return str(texts[id]),
		func(id: String) -> void:
			row["influencer"] = id
			_refresh.call_deferred())
	pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(pick)
	var chosen: Dictionary = sim.influencers.find(sim.state, str(row["influencer"]))
	if not chosen.is_empty() and sim.influencers.fee(sim.state, chosen) > budget:
		box.add_child(UiUtil.label(tr("ERR_INFLUENCER_FEE"), 14, UiUtil.TERRACOTTA))
	if not see:
		box.add_child(UiUtil.label(tr("UI_AUTHENTICITY_HIDDEN"), 13, UiUtil.MUTED))
