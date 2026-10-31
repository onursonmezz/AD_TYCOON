class_name CampaignPanel
extends VBoxContainer
## Faz slider ekranı (GDD 7.4, 20): fazın kalan süresi, canlı S/K/T sayaçları; faz başında üç slider (toplam %100).

var _info: VBoxContainer
var _counters: Label
var _phase_label: Label
var _progress: ProgressBar
var _slider_box: VBoxContainer
var _sliders: Array[HSlider] = []
var _value_labels: Array[Label] = []
var _airing: VBoxContainer
var _adjusting: bool = false
var _signature: String = ""


func _init() -> void:
	add_theme_constant_override("separation", 10)
	add_child(UiUtil.heading(tr("MENU_CAMPAIGN")))
	_info = UiUtil.vbox(6)
	add_child(_info)
	_slider_box = UiUtil.vbox(8)
	add_child(_slider_box)
	add_child(UiUtil.label(tr("UI_ON_AIR"), 18, UiUtil.SAGE_DARK))
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
	_counters = null
	var camp: Dictionary = s.active_campaign
	if camp.is_empty():
		_info.add_child(UiUtil.wrapped(tr("UI_NO_ACTIVE_CAMPAIGN"), 16, UiUtil.MUTED, 400.0))
	else:
		var setup: Dictionary = camp["setup"]
		var title: String = str(setup.get("name", "")) if not str(setup.get("name", "")).is_empty() else tr("UI_UNTITLED")
		_info.add_child(UiUtil.label("%s — %s" % [title, setup.get("client_name", "")], 19, UiUtil.SAGE_DARK))
		var data: GameData = DataDB.data
		_info.add_child(UiUtil.label("%s · %s · %s · %s" % [UiUtil.name_of(data.objectives, setup["objective"]),
			UiUtil.name_of(data.audiences, setup["audience"]), UiUtil.name_of(data.tones, setup["tone"]),
			UiUtil.name_of(data.channels, Scoring.main_channel(setup["mix"]))], 14, UiUtil.WOOD))
		_phase_label = UiUtil.label("", 17)
		_info.add_child(_phase_label)
		_progress = ProgressBar.new()
		_progress.custom_minimum_size = Vector2(300.0, 18.0)
		_progress.show_percentage = false
		_info.add_child(_progress)
		_counters = UiUtil.label("", 18)
		_info.add_child(_counters)
		if s.waiting_for_input:
			_build_sliders(camp)
	for a: Dictionary in s.airing:
		var weeks: int = int(a["air_end_week"]) - s.clock.week_index
		_airing.add_child(UiUtil.label(tr("UI_AIRING_ROW") % [a["setup"].get("client_name", ""), weeks], 14))
	if s.airing.is_empty():
		_airing.add_child(UiUtil.label("—", 14, UiUtil.MUTED))


func _update_live(camp: Dictionary) -> void:
	if _counters == null:
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
	_counters.text = tr("UI_COUNTERS") % [int(totals["strategy"]), int(totals["creative"]), int(totals["technical"]),
		int(camp["errors"])]


func _build_sliders(camp: Dictionary) -> void:
	var data: GameData = DataDB.data
	var phase: int = GameState.sim.production.current_phase(camp)
	_slider_box.add_child(UiUtil.label(tr("UI_PHASE_SLIDERS") % tr("PHASE_%d" % phase), 18, UiUtil.TERRACOTTA))
	_slider_box.add_child(UiUtil.wrapped(tr("UI_PHASE_SLIDERS_HINT"), 14, UiUtil.MUTED, 420.0))
	var ids: Array[String] = data.focus_ids_of_phase(phase)
	var current: Array = camp["setup"]["sliders"][phase]
	for i: int in 3:
		var row: HBoxContainer = UiUtil.hbox()
		var name_label: Label = UiUtil.label(UiUtil.name_of(data.focus_areas, ids[i]), 16)
		name_label.custom_minimum_size.x = 230.0
		row.add_child(name_label)
		var slider: HSlider = HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 100.0
		slider.step = 1.0
		slider.value = roundf(float(current[i]) * 100.0)
		slider.custom_minimum_size.x = 260.0
		slider.value_changed.connect(func(_v: float) -> void: _on_slider(i))
		row.add_child(slider)
		var value_label: Label = UiUtil.label("", 16)
		row.add_child(value_label)
		_sliders.append(slider)
		_value_labels.append(value_label)
		_slider_box.add_child(row)
	_normalize_from(0)
	_update_value_labels()
	_slider_box.add_child(UiUtil.button(tr("UI_START_PHASE"), _on_confirm))


## Bir slider değişince diğer ikisini orantılı ayarlar; toplam her zaman 100.
func _on_slider(changed: int) -> void:
	if _adjusting:
		return
	_normalize_from(changed)
	_update_value_labels()


func _normalize_from(changed: int) -> void:
	_adjusting = true
	var fixed: float = _sliders[changed].value
	var others: Array[int] = []
	for i: int in 3:
		if i != changed:
			others.append(i)
	var rest: float = _sliders[others[0]].value + _sliders[others[1]].value
	var remaining: float = 100.0 - fixed
	if rest <= 0.0:
		_sliders[others[0]].value = roundf(remaining / 2.0)
	else:
		_sliders[others[0]].value = roundf(remaining * _sliders[others[0]].value / rest)
	_sliders[others[1]].value = remaining - _sliders[others[0]].value
	_adjusting = false


func _update_value_labels() -> void:
	for i: int in _sliders.size():
		_value_labels[i].text = "%%%d" % int(_sliders[i].value)


func _on_confirm() -> void:
	var values: Array = []
	for slider: HSlider in _sliders:
		values.append(slider.value / 100.0)
	if GameState.set_phase_sliders(values):
		Clock.set_paused(false)
