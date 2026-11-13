class_name CampaignPanel
extends VBoxContainer
## Faz slider ekranı (GDD 7.4, 20): fazın kalan süresi, canlı S/K/T sayaçları; faz başında üç slider (toplam %100).

var _info: VBoxContainer
var _counter_labels: Array[Label] = []

const SLIDER_ICONS: Array[String] = ["chart-bar", "star", "speakerphone"]
var _phase_label: Label
var _progress: ProgressBar
var _slider_box: VBoxContainer
var _sliders: Array[HSlider] = []
var _value_labels: Array[Label] = []
var _airing: VBoxContainer
var _signature: String = ""


func _init() -> void:
	add_theme_constant_override("separation", CozyTheme.SPACE_S)
	add_child(UiUtil.heading(tr("MENU_CAMPAIGN")))
	_info = UiUtil.vbox(6)
	add_child(_info)
	_slider_box = UiUtil.vbox(8)
	add_child(_slider_box)
	add_child(Cards.section(tr("UI_ON_AIR"), "", "speakerphone"))
	_airing = UiUtil.vbox(4)
	add_child(_airing)


func refresh() -> void:
	var s: SimState = GameState.sim.state
	var camp: Dictionary = s.active_campaign
	var sig: String = str(camp.get("id", "")) + str(s.waiting_for_input) + str(s.airing.size())
	if camp.is_empty():
		sig += "idle"
	if sig != _signature:
		_signature = sig
		_rebuild(s)
	if not camp.is_empty():
		_update_live(camp)


func _rebuild(s: SimState) -> void:
	UiUtil.clear(_info)
	UiUtil.clear(_slider_box)
	UiUtil.clear(_airing)
	_sliders.clear()
	_value_labels.clear()
	_counter_labels.clear()
	_phase_label = null
	var camp: Dictionary = s.active_campaign
	if camp.is_empty():
		_info.add_child(UiUtil.wrapped(tr("UI_NO_ACTIVE_CAMPAIGN"), 15, UiUtil.MUTED, 400.0))
	else:
		_build_header(s, camp)
		# Faz şeridi: adı ve kalan gün, altında ilerleme çubuğu.
		var strip: PanelContainer = Cards.section("")
		_phase_label = (strip.get_child(0) as HBoxContainer).get_child(0) as Label
		_info.add_child(strip)
		_progress = ProgressBar.new()
		_progress.custom_minimum_size = Vector2(300.0, 10.0)
		_progress.show_percentage = false
		_info.add_child(_progress)
		# Canlı sayaçlar: üç stat ve hata.
		var counters: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
		for spec: Array in [["tool", tr("STAT_STRATEGY_NAME")], ["star", tr("STAT_CREATIVE_NAME")],
				["device-desktop", tr("STAT_TECHNICAL_NAME")], ["alert-triangle", tr("UI_COUNT_ERRORS")]]:
			var box: PanelContainer = PanelContainer.new()
			box.add_theme_stylebox_override("panel", CozyTheme.box(CozyTheme.CREAM, CozyTheme.RADIUS_CONTROL, CozyTheme.BORDER, 1, false,
				Vector2(CozyTheme.SPACE_M, 4)))
			box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
			box.add_child(row)
			row.add_child(UiUtil.icon(str(spec[0]), 18, CozyTheme.TERRA))
			var name: Label = UiUtil.label(str(spec[1]), 13, CozyTheme.TEXT)
			name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(name)
			var value: Label = UiUtil.label("0", 15, CozyTheme.FOREST)
			value.add_theme_font_override("font", CozyTheme.strong_font())
			row.add_child(value)
			_counter_labels.append(value)
			counters.add_child(box)
		_info.add_child(counters)
		if s.waiting_for_input:
			_build_sliders(camp)
	for a: Dictionary in s.airing:
		var weeks: int = int(a["air_end_week"]) - s.clock.week_index
		_airing.add_child(UiUtil.label(tr("UI_AIRING_ROW") % [a["setup"].get("client_name", ""), weeks], 13))
	if s.airing.is_empty():
		_airing.add_child(UiUtil.label(tr("UI_NO_AIRING"), 13, UiUtil.MUTED))


## Başlık (UI-3, taslak 03): müşteri ve kampanya adı, hedef ve ana kanal etiketleri, sağda ekip.
func _build_header(s: SimState, camp: Dictionary) -> void:
	var data: GameData = DataDB.data
	var setup: Dictionary = camp["setup"]
	var title: String = str(setup.get("name", "")) if not str(setup.get("name", "")).is_empty() else tr("UI_UNTITLED")
	var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
	var head: HBoxContainer = Cards.header(Cards.tile("speakerphone", 44.0, CozyTheme.TERRA_SOFT), str(setup.get("client_name", "")), title)
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(head)
	var tags: VBoxContainer = UiUtil.vbox(4)
	tags.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tags.add_child(Cards.chip(UiUtil.name_of(data.objectives, setup["objective"]), CozyTheme.SAGE_SOFT, CozyTheme.FOREST,
		"%s · %s" % [UiUtil.name_of(data.audiences, setup["audience"]), UiUtil.name_of(data.tones, setup["tone"])]))
	tags.add_child(Cards.chip(UiUtil.name_of(data.channels, Scoring.main_channel(setup["mix"])), CozyTheme.TERRA_SOFT, CozyTheme.TERRA))
	row.add_child(tags)
	row.add_child(VSeparator.new())
	var names: PackedStringArray = PackedStringArray()
	var first: Dictionary = {}
	for id: Variant in setup.get("team", []):
		var emp: Dictionary = s.staff.get(str(id), {})
		if not emp.is_empty():
			names.append(GameState.employee_name(emp))
			if first.is_empty():
				first = emp
	if not first.is_empty():
		var pic: PanelContainer = Cards.avatar(first, 40.0)
		pic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(pic)
	var team: Label = UiUtil.wrapped(tr("UI_TEAM_LINE") % ", ".join(names), 13, CozyTheme.TEXT, 120.0)
	team.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	team.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(team)
	_info.add_child(row)


func _update_live(camp: Dictionary) -> void:
	if _phase_label == null:
		return
	var prod: CampaignProduction = GameState.sim.production
	var phase: int = prod.current_phase(camp)
	var days_total: int = int(camp["days_total"])
	var phase_len: float = float(days_total) / 3.0
	var phase_end: int = int(ceilf(phase_len * (phase + 1)))
	var days_left: int = maxi(0, phase_end - int(camp["day"]))
	_phase_label.text = tr("UI_PHASE_STATUS") % [tr("PHASE_%d" % phase), days_left]
	_progress.max_value = days_total
	_progress.value = int(camp["day"])
	var totals: Dictionary = GameState.sim.scoring.stat_totals(camp["points"])
	var values: Array = [int(totals["strategy"]), int(totals["creative"]), int(totals["technical"]), int(camp["errors"])]
	for i: int in _counter_labels.size():
		_counter_labels[i].text = str(values[i])


func _build_sliders(camp: Dictionary) -> void:
	var data: GameData = DataDB.data
	var phase: int = GameState.sim.production.current_phase(camp)
	_slider_box.add_child(Cards.section(tr("UI_PHASE_SLIDERS") % tr("PHASE_%d" % phase)))
	var ids: Array[String] = data.focus_ids_of_phase(phase)
	for i: int in 3:
		var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
		row.add_child(UiUtil.icon(SLIDER_ICONS[i], 22, CozyTheme.TERRA))
		var name_label: Label = UiUtil.label(UiUtil.name_of(data.focus_areas, ids[i]), 14, CozyTheme.TEXT)
		name_label.add_theme_font_override("font", CozyTheme.strong_font())
		name_label.custom_minimum_size.x = 200.0
		row.add_child(name_label)
		var slider: HSlider = HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 100.0
		slider.step = 1.0
		slider.value = data.balf("focus.slider_default_priority")
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		slider.value_changed.connect(func(_v: float) -> void: _update_value_labels())
		row.add_child(slider)
		var chip: PanelContainer = Cards.chip("", CozyTheme.SAGE_SOFT, CozyTheme.FOREST)
		chip.custom_minimum_size.x = 52.0
		var value_label: Label = chip.get_child(0) as Label
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		value_label.add_theme_font_size_override("font_size", 14)
		row.add_child(chip)
		_sliders.append(slider)
		_value_labels.append(value_label)
		_slider_box.add_child(row)
	_update_value_labels()
	var foot: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
	var hint: Label = UiUtil.wrapped(tr("UI_PHASE_SLIDERS_HINT"), 12, UiUtil.MUTED, 300.0)
	foot.add_child(hint)
	var start: Button = UiUtil.button(tr("UI_START_PHASE"), _on_confirm)
	start.theme_type_variation = "PrimaryButton"
	start.custom_minimum_size.x = 150.0
	start.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	foot.add_child(start)
	_slider_box.add_child(foot)


## Her slider bağımsız bir öncelik (GDT gibi); iş payı = öncelik / öncelikler toplamı (K-033).
## Hepsi 0 ise iş eşit dağılır. Paylar her zaman tam %100 eder.
func shares() -> Array[float]:
	var total: float = 0.0
	for slider: HSlider in _sliders:
		total += slider.value
	var out: Array[float] = []
	for i: int in _sliders.size():
		out.append(1.0 / _sliders.size() if total <= 0.0 else _sliders[i].value / total)
	out[out.size() - 1] = 1.0 - out[0] - out[1]
	return out


func _update_value_labels() -> void:
	var s: Array[float] = shares()
	for i: int in _sliders.size():
		_value_labels[i].text = UiUtil.percent(roundf(s[i] * 100.0))


func _on_confirm() -> void:
	if GameState.set_phase_sliders(shares()):
		Clock.set_paused(false)
