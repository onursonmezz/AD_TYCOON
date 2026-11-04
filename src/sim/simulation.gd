class_name Simulation
extends RefCounted
## Simülasyon çekirdeğinin giriş noktası: sistemleri bağlar, zamanı ilerletir, oyuncu komutlarını uygular.
## Node'a bağımlı değildir; headless testler ve tools/balance_sim.gd doğrudan kullanır.

## Sunum katmanı (M2) bu sinyalleri GameState üzerinden EventBus'a aktarır; simülasyon UI'ı bilmez.
signal phase_started(phase: int)
signal campaign_delivered(campaign: Dictionary)
signal campaign_finished(campaign: Dictionary)
signal briefs_received(count: int)
signal clients_lost(client_names: Array[String])
signal went_bankrupt()
signal week_passed()
## Çalışan bildirimleri (izin, istifa, seviye atlama…): key yerelleştirme anahtarı.
signal staff_note(key: String, args: Array, kind: String)
signal offer_received(offer: Dictionary)
signal supplier_offer_received(offer: Dictionary)
signal scandal_started(scandal: Dictionary)
## M5: ödül töreni sonucu (oyuncunun başvurusu varsa) ve yıl sonu sıralaması.
signal award_ceremony(result: Dictionary)
signal rankings_published(result: Dictionary)
## Pitch hazırlığı bitti, sunum bekleniyor (oyunda zaman durur).
signal pitch_ready()
## Yeni dönem başladı (GDD 5.2): kısa "yeni dönem" ekranı.
signal era_started(era_id: String)
## Olay kararı bekliyor (M7-C, GDD 16): oyunda zaman durur.
signal event_started(event: Dictionary)

var data: GameData
var state: SimState
var scoring: Scoring
var kpi: Kpi
var economy: Economy
var clients: ClientSystem
var briefs: BriefGenerator
var production: CampaignProduction
var reports: ReportWriter
## Çalışan ve ofis sistemleri; komutlar (src/commands) doğrudan bunları çağırır.
var staff: StaffSystem
var staff_life: StaffLife
var offices: OfficeSystem
## Tedarikçiler, baskı ve medya planlama (M4).
var suppliers: SupplierSystem
var prints: PrintSystem
var media: MediaPlanning
var options: ChannelOptions
var influencers: InfluencerSystem
## Rakipler ve ödüller (M5).
var rivals: RivalSystem
var awards: AwardSystem
var pitches: PitchSystem
var build: BuildSystem
var tools: ToolSystem
var research: ResearchSystem
var events: EventSystem

## true: her fazın başında oyuncunun slider girmesi beklenir (oyun). false: kurulumdaki slider'larla devam (bot/test).
var pause_on_phase: bool = false


## background: oyuncunun geçmişi (data/backgrounds.json, GDD 11.5); boşsa varsayılan.
## start_year: hızlı başlangıç (GDD 5.1: 1990 / 2000 / 2010); 0 = varsayılan. Başlangıç nakdi enflasyonla ölçeklenir.
func _init(game_data: GameData, seed_value: int, background: String = "", start_year: int = 0) -> void:
	data = game_data
	state = SimState.new(data, seed_value)
	if start_year > 0:
		state.clock.start_year = start_year
		state.cash = data.balf("start.cash") * Economy.inflation(data, start_year)
	scoring = Scoring.new(data)
	scoring.era_offset = state.clock.start_year - data.bali("time.base_year")
	kpi = Kpi.new(data, scoring)
	economy = Economy.new(data)
	clients = ClientSystem.new(data)
	briefs = BriefGenerator.new(data, clients)
	production = CampaignProduction.new(data, scoring)
	reports = ReportWriter.new(data)
	staff = StaffSystem.new(data)
	staff_life = StaffLife.new(data)
	offices = OfficeSystem.new(data)
	suppliers = SupplierSystem.new(data)
	prints = PrintSystem.new(data, suppliers)
	options = ChannelOptions.new(data)
	influencers = InfluencerSystem.new(data)
	media = MediaPlanning.new(data, prints, options, influencers)
	rivals = RivalSystem.new(data)
	awards = AwardSystem.new(data, rivals)
	pitches = PitchSystem.new(data, clients, briefs, scoring, rivals)
	build = BuildSystem.new(data)
	tools = ToolSystem.new(data)
	research = ResearchSystem.new(data)
	events = EventSystem.new(data)
	events.build = build
	kpi.prints = prints
	kpi.options = options
	var founder: Dictionary = staff.create_founder(state, background)
	clients.create_starting(state, int(data.backgrounds[founder["background"]]["extra_start_clients"]))
	rivals.ensure(state)
	build.refresh(state)
	tools.start(state)
	research.start(state)


func set_overtime(on: bool) -> void:
	state.overtime = on


## Kayıttan gelen durumla değiştirir (SaveSystem).
func load_state(saved: Dictionary) -> void:
	state = SimState.from_dict(data, saved)
	scoring.era_offset = state.clock.start_year - data.bali("time.base_year")
	rivals.ensure(state)
	build.refresh(state)
	if state.tools.is_empty():
		tools.start(state)
	else:
		tools.refresh(state)
	# M7-B öncesi kayıt: o güne dek kendiliğinden açık olan ton, kitle, çoklu kanal ve dijital kanallar araştırılmış sayılır.
	if not saved.has("research"):
		research.grant_reachable(state)


# --- zaman -------------------------------------------------------------------

func step_day() -> void:
	if state.bankrupt or state.waiting_for_input:
		return
	if pause_on_phase and (pitches.is_waiting(state) or not EventSystem.pending(state).is_empty()):
		return
	if not state.active_campaign.is_empty():
		if pause_on_phase and _needs_phase_input():
			return
		production.produce_day(state.active_campaign, state)
		if production.is_finished(state.active_campaign):
			_deliver()
	staff_life.daily(state)
	pitches.produce_day(state)
	var ended: Dictionary = state.clock.advance_day()
	if ended["week"]:
		var inbox_before: int = state.inbox.size()
		briefs.weekly(state)
		_update_airing()
		for note: Dictionary in staff_life.weekly(state):
			staff_note.emit(note["key"], note["args"], note["kind"])
		influencers.weekly(state)
		IndustryCalendar.weekly(self)
		build.refresh(state)
		var done: String = research.weekly(state)
		if not done.is_empty():
			staff_note.emit("NOTE_RESEARCH_DONE", [data.research[done]["name_key"]], "good")
		influencers.expire_scandals(state)
		var supplier_offer: Dictionary = suppliers.weekly(state)
		if not supplier_offer.is_empty():
			supplier_offer_received.emit(supplier_offer)
		economy.weekly(state)
		if state.inbox.size() > inbox_before:
			briefs_received.emit(state.inbox.size() - inbox_before)
		week_passed.emit()
		if state.bankrupt:
			went_bankrupt.emit()
	if ended["month"]:
		economy.monthly(state, offices.monthly_rent(state) + staff.monthly_payroll(state) + tools.monthly_cost(state))
		for offer: Dictionary in staff_life.monthly_offers(state):
			offer["rival"] = rivals.pick_by_power(state)
			offer_received.emit(offer)
		IndustryCalendar.monthly(self)
	if ended["year"]:
		_end_year()


## Yeni bir faza girildiyse ve slider'ları onaylanmadıysa bekle.
func _needs_phase_input() -> bool:
	var camp: Dictionary = state.active_campaign
	var phase: int = production.current_phase(camp)
	var confirmed: Array = camp.get("confirmed_phases", [])
	for p: Variant in confirmed:
		if int(p) == phase:
			return false
	state.waiting_for_input = true
	phase_started.emit(phase)
	return true


## Oyuncu fazın slider'larını onaylar (GDD 7.4: üç slider, toplam %100).
func set_phase_sliders(sliders: Array) -> bool:
	if state.active_campaign.is_empty() or sliders.size() != 3:
		return false
	var sum: float = 0.0
	for v: Variant in sliders:
		if float(v) < 0.0:
			return false
		sum += float(v)
	if not is_equal_approx(sum, 1.0):
		return false
	var camp: Dictionary = state.active_campaign
	var phase: int = production.current_phase(camp)
	camp["setup"]["sliders"][phase] = sliders.duplicate()
	var confirmed: Array = camp.get("confirmed_phases", [])
	confirmed.append(phase)
	camp["confirmed_phases"] = confirmed
	state.waiting_for_input = false
	return true


func step_week() -> void:
	for i: int in state.clock.days_per_week:
		step_day()


# --- komutlar (src/commands bunları çağırır) ---------------------------------

## choices: { "objective" (brief serbestse), "audience", "tone", "mix": [{channel, share}], "sliders": [[..]x3], "name" }
## Dönüş: { "ok": bool, "error": hata anahtarı, "campaign_id" }
func start_campaign(brief_id: String, choices: Dictionary) -> Dictionary:
	return CampaignStarter.start(self, brief_id, choices)


func decline_brief(brief_id: String) -> bool:
	var brief: Dictionary = state.find_brief(brief_id)
	if brief.is_empty():
		return false
	state.inbox.erase(brief)
	return true


# --- kampanya yaşam döngüsü (GDD 4.2) ----------------------------------------

## Üretim bitti: puanla, medyayı öde, faturayı kes, yayına al.
func _deliver() -> void:
	var camp: Dictionary = state.active_campaign
	state.active_campaign = {}
	var setup: Dictionary = camp["setup"]
	var client: Dictionary = state.clients.get(setup["client_id"], {})
	var size: String = setup["size"]
	var caught: int = staff_life.catch_errors(state, int(camp["errors"]))
	camp["errors"] = int(camp["errors"]) - caught
	camp["errors_caught"] = caught
	var report: Dictionary = scoring.evaluate(camp, client, state.history, state.clock.week_index, state.clock.year(),
		float(state.best_raw.get(size, 0.0)), state.rng.stream("scoring"))
	state.best_raw[size] = report["new_best"]
	camp["report"] = report
	var media_budget: float = float(setup["media_budget"])
	setup["media_efficiency"] = media.efficiency(state, setup.get("team", []))
	var settled: Dictionary = media.settle_delivery(setup, state)
	setup["production_margin"] = settled["production_margin"]
	setup["late_weeks"] = settled["late_weeks"]
	camp["print_results"] = settled["print_results"]
	setup["option_satisfaction"] = settled["option_satisfaction"]
	if float(settled["fines"]) > 0.0:
		economy.pay(state, float(settled["fines"]))
	for note: Dictionary in settled["notes"]:
		staff_note.emit(note["key"], note["args"], note["kind"])
	var income: Dictionary = kpi.agency_income(setup, 0.0)
	economy.add_payable(state, float(settled["payable"]))
	if not client.is_empty():
		var media_due: float = media_budget - float(setup.get("media_advance", 0.0))
		economy.invoice(state, client, float(income["fee"]) + media_due + float(income["commission"]),
			float(income["fee"]) + float(income["commission"]) + float(income["production_margin"]))
	var airing: Array = data.bal("briefs.airing_weeks")
	camp["air_end_week"] = state.clock.week_index + state.rng.range_i("airing", int(airing[0]), int(airing[1]))
	state.airing.append(camp)
	state.history.append({"campaign": camp["id"], "client_id": setup["client_id"], "sector": setup["sector"],
		"objective": setup["objective"], "main_channel": Scoring.main_channel(setup["mix"]), "size": size,
		"week": state.clock.week_index, "year": state.clock.year(), "score": report["score"],
		"factors": {"m": report["combination"]["m"], "f": report["focus"]["f"], "b": report["balance"]["b"],
			"n": report["novelty"]["n"], "synergy": report["synergy"]["synergy"], "r": report["r"],
			"errors": report["errors"], "points": report["s"] + report["k"] + report["t"]},
		"client_name": setup.get("client_name", ""), "name": setup.get("name", ""), "team": setup.get("team", []).duplicate(),
		"channel_count": (setup["mix"] as Array).size()})
	for inf: Dictionary in settled["scandal_candidates"]:
		var scandal: Dictionary = influencers.maybe_scandal(state, camp["id"], inf)
		if not scandal.is_empty():
			scandal_started.emit(scandal)
	campaign_delivered.emit(camp)


func _update_airing() -> void:
	var still: Array[Dictionary] = []
	for camp: Dictionary in state.airing:
		if int(camp["air_end_week"]) <= state.clock.week_index:
			_finish(camp)
		else:
			still.append(camp)
	state.airing = still


## Yayın bitti: KPI, prim, memnuniyet, itibar.
func _finish(camp: Dictionary) -> void:
	var setup: Dictionary = camp["setup"]
	var score: float = float(camp["report"]["score"])
	var year: int = state.clock.year()
	var client: Dictionary = state.clients.get(setup["client_id"], {})
	var kpi_client: Dictionary = client if not client.is_empty() else {"scale": setup.get("client_scale", 0)}
	media.before_kpi(camp, score, state)
	EventSystem.prepare_kpi(state, setup)
	var result: Dictionary = kpi.compute(setup, kpi_client, score, year, state.rng, state.clock.month())
	var ratio: float = Kpi.value_of(result, setup["kpi_type"]) / maxf(0.000001, float(setup["kpi_target"]))
	camp["kpi"] = result
	camp["kpi_ratio"] = ratio
	var income: Dictionary = kpi.agency_income(setup, ratio)
	camp["income"] = income
	camp["satisfaction_delta"] = 0.0
	if not client.is_empty():
		var bonus: float = float(income["bonus"])
		if bonus > 0.0:
			economy.invoice(state, client, bonus, bonus)
		var team: Array = setup.get("team", [])
		var parts: Dictionary = clients.satisfaction_parts(client, score, ratio, setup["tone"], year,
			staff_life.account_bonus(state, team), int(setup.get("late_weeks", 0)),
			float(setup.get("production_margin", 0.0)) < 0.0)
		parts["risks"] = float(setup.get("option_satisfaction", 0.0))
		parts["scandal"] = float(camp.get("scandal", {}).get("satisfaction", 0.0))
		parts["office"] = float(state.office_effects.get("satisfaction", 0.0))
		parts["event"] = float(camp.get("event_satisfaction", 0.0))
		parts["expectation"] = clients.expectation(client, year)
		var delta: float = 0.0
		for key: String in parts:
			if key != "expectation":
				delta += float(parts[key])
		camp["satisfaction_parts"] = parts
		camp["satisfaction_delta"] = delta
		clients.apply_result(client, camp["id"], score, setup["objective"], year, delta)
	_apply_reputation(score, setup["size"])
	camp["ap"] = research.on_campaign(state, score, setup["size"])
	camp["learned"] = research.learn_from(state, setup)
	for emp_name: String in staff_life.campaign_finished(state, setup.get("team", []), camp["report"]):
		if emp_name.is_empty():
			staff_note.emit("NOTE_LEVEL_UP_FOUNDER", [], "good")
		else:
			staff_note.emit("NOTE_LEVEL_UP", [emp_name], "good")
	camp["lines"] = reports.explanation_lines(camp["report"])
	camp["reviews"] = reports.reviews(score, state.rng.stream("reviews"))
	state.finished.append(camp)
	while state.finished.size() > data.bali("ui.finished_campaigns_kept"):
		state.finished.pop_front()
	for i: int in range(state.history.size() - 1, -1, -1):
		if state.history[i]["campaign"] == camp["id"]:
			state.history[i]["kpi_ratio"] = ratio
			state.history[i]["viral"] = result["viral"]
			break
	var lost_names: Array[String] = []
	drop_clients(clients.remove_unhappy(state, lost_names))
	campaign_finished.emit(camp)
	if not lost_names.is_empty():
		clients_lost.emit(lost_names)


## Kaybedilen müşteriler: itibar −2 (14.1), gelen kutusundaki brief'leri silinir.
func drop_clients(lost: Array[String]) -> void:
	state.reputation -= lost.size() * data.balf("reputation.client_lost")
	if not lost.is_empty():
		var kept: Array[Dictionary] = []
		for b: Dictionary in state.inbox:
			if not lost.has(b["client_id"]):
				kept.append(b)
		state.inbox = kept
	state.reputation = clampf(state.reputation, data.balf("reputation.min"), data.balf("reputation.max"))


## GDD 14.1 itibar: iyi puan +, kötü puan − (büyüklükle ölçeklenir).
func _apply_reputation(score: float, size: String) -> void:
	if score >= data.balf("reputation.good_score"):
		state.reputation += float(data.bal("reputation.good_gain")[size])
	elif score <= data.balf("reputation.bad_score"):
		state.reputation -= float(data.bal("reputation.bad_loss")[size])
	state.reputation = clampf(state.reputation, data.balf("reputation.min"), data.balf("reputation.max"))


func _end_year() -> void:
	var penalty: float = suppliers.year_end(state)
	if penalty > 0.0:
		economy.pay(state, penalty)
		staff_note.emit("NOTE_COMMIT_PENALTY", [penalty], "bad")
	IndustryCalendar.yearly(self)
	state.year_media = 0.0
	economy.yearly(state)
	# Rekor çıtası her yıl biraz erir (K-047): tek bir şanslı iş yıllarca aşılamaz çıta bırakmasın.
	for size: Variant in state.best_raw:
		state.best_raw[size] = float(state.best_raw[size]) * (1.0 - data.balf("score.best_yearly_decay"))
	clients.yearly(state)
	if state.reputation > data.balf("reputation.decay_threshold"):
		state.reputation *= 1.0 - data.balf("reputation.decay_above_50")
