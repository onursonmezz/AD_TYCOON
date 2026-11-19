class_name CampaignPanel
extends VBoxContainer
## Kampanya ekranı (GDD 7.4, 20; UI-3 taslak 03): fazın kalan süresi, canlı S/K/T sayaçları; faz başında emek dağılımı
## görev panosu (WorkBoard, K-118): ekip üyeleri alanlara zaman payı verir, öğrenilen önem işaretleri (K-117), ekipman (K-119).
## CP-2: faz takipçisi ve yukarı sayan büyük sayaçlar (CampaignLive); kampanya yokken ortada boş durum; "Yayında"
## bölümü yalnızca yayında kampanya varken görünür.

var _info: VBoxContainer
var _live: CampaignLive
var _polish_label: Label
var _slider_box: VBoxContainer
var _airing: VBoxContainer
var _airing_head: Control
var _signature: String = ""
var _tabs: HBoxContainer  # S3D: birden çok kampanya varken üstte sekmeler
var _selected: String = ""


func _init() -> void:
	add_theme_constant_override("separation", CozyTheme.SPACE_S)
	add_child(UiUtil.heading(tr("MENU_CAMPAIGN")))
	_tabs = UiUtil.hbox(CozyTheme.SPACE_S)
	add_child(_tabs)
	_info = UiUtil.vbox(6)
	add_child(_info)
	_slider_box = UiUtil.vbox(8)
	add_child(_slider_box)
	_airing_head = Cards.section(tr("UI_ON_AIR"), "", "speakerphone")
	add_child(_airing_head)
	_airing = UiUtil.vbox(4)
	add_child(_airing)


## Gösterilen kampanya: mini oyun bekleyen, yoksa seçilen sekme, yoksa ilki.
func _camp(s: SimState) -> Dictionary:
	if s.waiting_for_input and not s.waiting_campaign.is_empty():
		return s.find_campaign(s.waiting_campaign)
	var picked: Dictionary = s.find_campaign(_selected)
	return picked if not picked.is_empty() else s.active_campaign


func refresh() -> void:
	var s: SimState = GameState.sim.state
	var camp: Dictionary = _camp(s)
	var ids: PackedStringArray = PackedStringArray()
	for c: Dictionary in s.campaigns:
		ids.append(str(c["id"]))
	var sig: String = str(camp.get("id", "")) + str(s.waiting_for_input) + str(s.airing.size()) + ",".join(ids)
	if camp.is_empty():
		sig += "idle"
	else:
		sig += str(CampaignProduction.production_done(camp))  # S3C: rötuşa geçince teslim kutusu çıksın
		if s.waiting_for_input:
			# Mini oyun bitince (K-120) bekleme notu panoya dönsün.
			sig += str(Minigames.pending(camp, GameState.sim.production.current_phase(camp)))
	if sig != _signature:
		_signature = sig
		_rebuild(s)
	if not camp.is_empty():
		_update_live(camp)


func _rebuild(s: SimState) -> void:
	UiUtil.clear(_info)
	UiUtil.clear(_slider_box)
	UiUtil.clear(_airing)
	_live = null
	var camp: Dictionary = _camp(s)
	_build_tabs(s, camp)
	if camp.is_empty():
		_info.add_child(Cards.empty_state("speakerphone", tr("UI_NO_ACTIVE_CAMPAIGN")))
	else:
		_build_header(s, camp)
		_live = CampaignLive.new()
		_info.add_child(_live)
		# Mesai (GDD 11): üst çubuktan buraya taşındı; üretimi hızlandırır, ekibi yorar.
		var overtime: CheckButton = CheckButton.new()
		overtime.text = tr("UI_OVERTIME")
		overtime.tooltip_text = tr("TIP_OVERTIME")
		overtime.button_pressed = s.overtime
		overtime.add_theme_font_size_override("font_size", 13)
		overtime.toggled.connect(func(on: bool) -> void: GameState.execute(SetOvertimeCommand.new(on)))
		_info.add_child(overtime)
		if s.waiting_for_input:
			_build_sliders(camp)
		elif CampaignProduction.production_done(camp):
			_build_polish(camp)
		else:
			# Faz sürerken: ekip çalışıyor; faz bitince yeni dağılım istenir.
			var note: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
			note.add_child(UiUtil.icon("clock", 18, CozyTheme.FOREST_LIGHT))
			var planned: bool = bool(camp["setup"].get("polish", false))  # S11: planlı kampanya (faz faz plan)
			note.add_child(UiUtil.label(tr("UI_PHASE_WORKING_PLANNED" if planned else "UI_PHASE_WORKING"), 13, CozyTheme.MUTED))
			_slider_box.add_child(note)
	_airing_head.visible = not s.airing.is_empty()
	for a: Dictionary in s.airing:
		var weeks: int = int(a["air_end_week"]) - s.clock.week_index
		_airing.add_child(UiUtil.label(tr("UI_AIRING_ROW") % [a["setup"].get("client_name", ""), weeks], 13))


## S3D: birden çok kampanya varken her biri için sekme (müşteri adı); seçilen çerçeveli.
func _build_tabs(s: SimState, current: Dictionary) -> void:
	UiUtil.clear(_tabs)
	_tabs.visible = s.campaigns.size() > 1
	if not _tabs.visible:
		return
	for c: Dictionary in s.campaigns:
		var id: String = str(c["id"])
		var on: bool = id == str(current.get("id", ""))
		var steps: Array[String] = ["UI_STEP_STRATEGY", "UI_STEP_CREATIVE", "UI_STEP_PRODUCTION"]
		var step: String = tr("UI_POLISH_TITLE") if CampaignProduction.production_done(c) else tr(steps[CampaignProduction.phase_of(c)])
		var b: Button = UiUtil.button("%s · %s" % [str(c["setup"].get("client_name", "")), step], func() -> void:
			_selected = id
			refresh())
		b.toggle_mode = true
		b.button_pressed = on
		b.theme_type_variation = "PickCardActive" if on else "PickCard"
		b.add_theme_font_size_override("font_size", 13)
		_tabs.add_child(b)


## Rötuş (S3C): üretim bitti; ekip hataları gideriyor. Oyuncu istediğinde teslim eder, yoksa süre dolunca teslim.
func _build_polish(camp: Dictionary) -> void:
	var card: PanelContainer = UiUtil.card()
	var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
	card.add_child(row)
	row.add_child(UiUtil.icon("check", 22, CozyTheme.FOREST))
	_polish_label = UiUtil.wrapped("", 13, CozyTheme.TEXT, 200.0)
	_polish_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_polish_label)
	var deliver: Button = UiUtil.button(tr("UI_DELIVER_NOW"), func() -> void:
		GameState.execute(DeliverNowCommand.new(str(camp["id"]))))
	deliver.theme_type_variation = "PrimaryButton"
	deliver.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(deliver)
	_slider_box.add_child(card)


## Başlık (UI-3, taslak 03): müşteri ve kampanya adı, hedef ve ana kanal etiketleri, sağda ekip.
func _build_header(s: SimState, camp: Dictionary) -> void:
	var data: GameData = DataDB.data
	var setup: Dictionary = camp["setup"]
	var title: String = str(setup.get("name", "")) if not str(setup.get("name", "")).is_empty() else tr("UI_UNTITLED")
	var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
	var head: HBoxContainer = Cards.header(Cards.art("brand_art", str(setup.get("client_name", "")), 44.0, "speakerphone"),
		str(setup.get("client_name", "")), title)
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
	if _live == null:
		return
	if is_instance_valid(_polish_label):
		_polish_label.text = tr("UI_POLISH_STATUS") % [int(camp["errors"]), maxi(0, int(camp["days_total"]) - int(camp["day"]))]
	var prod: CampaignProduction = GameState.sim.production
	var phase: int = prod.current_phase(camp)
	var days_total: int = CampaignProduction.production_days(camp)  # fazlar üretim süresine yayılır (S3C)
	var phase_len: float = float(days_total) / 3.0
	var phase_end: int = int(ceilf(phase_len * (phase + 1)))
	var days_left: int = maxi(0, phase_end - int(camp["day"]))
	var phase_start: float = phase_len * phase
	var progress: float = (float(camp["day"]) - phase_start) / maxf(1.0, phase_len)
	var totals: Dictionary = GameState.sim.scoring.stat_totals(camp["points"])
	var values: Array[int] = [int(totals["strategy"]), int(totals["creative"]), int(totals["technical"]), int(camp["errors"])]
	if CampaignProduction.production_done(camp):  # S3C: rötuşta üç adım da bitti
		_live.update(3, 1.0, maxi(0, int(camp["days_total"]) - int(camp["day"])), values)
		return
	_live.update(phase, progress, days_left, values)


## Faz başı: önce fazın mini oyunu (K-120, Ayarlar'dan kapatılabilir), sonra emek dağılımı panosu.
func _build_sliders(camp: Dictionary) -> void:
	UiUtil.clear(_slider_box)
	var phase: int = GameState.sim.production.current_phase(camp)
	if bool(Settings.get_value("minigames")) and Minigames.pending(camp, phase):
		# Mini oyun kendi penceresinde açılır (MinigameDialog); bitince bu panel yenilenir.
		_slider_box.add_child(UiUtil.label(tr("UI_MG_WAITING"), 14, UiUtil.MUTED))
		return
	if (camp.get("confirmed_phases", []) as Array).has(phase):
		return  # plan yapıldı; pano yok
	if bool(camp["setup"].get("polish", false)):  # S11: planlı kampanyada fazın planı kendi penceresinde
		_slider_box.add_child(UiUtil.label(tr("UI_PHASE_PLAN_WAITING"), 13, CozyTheme.TEXT))
		var plan: Button = UiUtil.button(tr("UI_PLAN_PHASE_BUTTON"), func() -> void:
			var main: Node = self
			while main != null and not main.has_method("open_modal"):
				main = main.get_parent()
			if main != null:
				main.call("open_modal", TaskPlanDialog.for_phase(camp)))
		plan.theme_type_variation = "PrimaryButton"
		plan.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		_slider_box.add_child(plan)
		return
	_slider_box.add_child(WorkBoard.new(camp, func() -> void: Clock.set_paused(false)))
