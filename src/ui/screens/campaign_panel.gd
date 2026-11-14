class_name CampaignPanel
extends VBoxContainer
## Kampanya ekranı (GDD 7.4, 20): fazın kalan süresi, canlı S/K/T sayaçları; faz başında görev panosu (K-099).

var _info: VBoxContainer
var _counters: Label
var _phase_label: Label
var _progress: ProgressBar
var _slider_box: VBoxContainer
var _airing: VBoxContainer
var _signature: String = ""


func _init() -> void:
	add_theme_constant_override("separation", 10)
	add_child(UiUtil.heading(tr("MENU_CAMPAIGN")))
	# Görev panosu ekip büyüdükçe uzar: pencere sabit kalır, içerik kayar.
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var pad: MarginContainer = MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_theme_constant_override("margin_right", 16)
	scroll.add_child(pad)
	var body: VBoxContainer = UiUtil.vbox(10)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_child(body)
	_info = UiUtil.vbox(6)
	body.add_child(_info)
	_slider_box = UiUtil.vbox(8)
	body.add_child(_slider_box)
	body.add_child(UiUtil.label(tr("UI_ON_AIR"), 18, UiUtil.SAGE_DARK))
	_airing = UiUtil.vbox(4)
	body.add_child(_airing)


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
		var names: PackedStringArray = PackedStringArray()
		for id: Variant in setup.get("team", []):
			var emp: Dictionary = s.staff.get(str(id), {})
			if not emp.is_empty():
				names.append(GameState.employee_name(emp))
		_info.add_child(UiUtil.label(tr("UI_TEAM_LINE") % ", ".join(names), 14))
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


## Faz başı (K-099): kaydırıcılar yerine görev panosu; odak payları ekibin emeğinden hesaplanır.
func _build_sliders(camp: Dictionary) -> void:
	_slider_box.add_child(WorkBoard.new(camp, func() -> void: Clock.set_paused(false)))
