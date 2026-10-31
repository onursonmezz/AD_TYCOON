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

var data: GameData
var state: SimState
var scoring: Scoring
var kpi: Kpi
var economy: Economy
var clients: ClientSystem
var briefs: BriefGenerator
var production: CampaignProduction
var reports: ReportWriter

## true: her fazın başında oyuncunun slider girmesi beklenir (oyun). false: kurulumdaki slider'larla devam (bot/test).
var pause_on_phase: bool = false


func _init(game_data: GameData, seed_value: int) -> void:
	data = game_data
	state = SimState.new(data, seed_value)
	scoring = Scoring.new(data)
	kpi = Kpi.new(data, scoring)
	economy = Economy.new(data)
	clients = ClientSystem.new(data)
	briefs = BriefGenerator.new(data, clients)
	production = CampaignProduction.new(data, scoring)
	reports = ReportWriter.new(data)
	clients.create_starting(state)


## Kayıttan gelen durumla değiştirir (SaveSystem).
func load_state(saved: Dictionary) -> void:
	state = SimState.from_dict(data, saved)


# --- zaman -------------------------------------------------------------------

func step_day() -> void:
	if state.bankrupt or state.waiting_for_input:
		return
	if not state.active_campaign.is_empty():
		if pause_on_phase and _needs_phase_input():
			return
		production.produce_day(state.active_campaign, state.player, state.rng)
		if production.is_finished(state.active_campaign):
			_deliver()
	var ended: Dictionary = state.clock.advance_day()
	if ended["week"]:
		var inbox_before: int = state.inbox.size()
		briefs.weekly(state)
		_update_airing()
		economy.weekly(state)
		if state.inbox.size() > inbox_before:
			briefs_received.emit(state.inbox.size() - inbox_before)
		week_passed.emit()
		if state.bankrupt:
			went_bankrupt.emit()
	if ended["month"]:
		economy.monthly(state)
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
	if not state.is_idle():
		return {"ok": false, "error": "ERR_BUSY"}
	var brief: Dictionary = state.find_brief(brief_id)
	if brief.is_empty():
		return {"ok": false, "error": "ERR_NO_BRIEF"}
	var objective: String = brief["objective"] if not str(brief["objective"]).is_empty() else str(choices.get("objective", ""))
	var sliders: Array = choices.get("sliders", [])
	if sliders.is_empty():
		var third: float = 1.0 / 3.0
		sliders = [[third, third, third], [third, third, third], [third, third, third]]
	var brief_client: Dictionary = brief["prospect"] if not (brief["prospect"] as Dictionary).is_empty() \
		else state.clients.get(brief["client_id"], {})
	var setup: Dictionary = {"client_id": brief["client_id"], "sector": brief["sector"], "objective": objective,
		"audience": choices.get("audience", ""), "tone": choices.get("tone", ""), "mix": choices.get("mix", []),
		"sliders": sliders, "name": choices.get("name", ""), "size": brief["size"],
		"fee": brief["fee"], "media_budget": brief["media_budget"], "deadline_weeks": brief["deadline_weeks"],
		"client_name": brief_client.get("name", ""), "client_scale": int(brief_client.get("scale", 0))}
	var err: String = production.validate_setup(setup, state.clock.year())
	if not err.is_empty():
		return {"ok": false, "error": err}
	var prospect: Dictionary = brief["prospect"]
	if prospect.is_empty() and not state.clients.has(brief["client_id"]):
		state.inbox.erase(brief)
		return {"ok": false, "error": "ERR_NO_BRIEF"}
	if not prospect.is_empty():
		state.clients[prospect["id"]] = prospect
	var client: Dictionary = state.clients[setup["client_id"]]
	setup["kpi_type"] = kpi.kpi_type(objective)
	setup["kpi_target"] = kpi.reference_value(objective, float(setup["media_budget"]), client, state.clock.year()) \
		* float(brief["kpi_factor"])
	state.inbox.erase(brief)
	var id: String = state.next_id("cp")
	state.active_campaign = production.create(setup, id, state.clock.week_index)
	return {"ok": true, "error": "", "campaign_id": id}


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
	var report: Dictionary = scoring.evaluate(camp, client, state.history, state.clock.week_index, state.clock.year(),
		float(state.best_raw.get(size, 0.0)), state.rng.stream("scoring"))
	state.best_raw[size] = report["new_best"]
	camp["report"] = report
	var media: float = float(setup["media_budget"])
	var income: Dictionary = kpi.agency_income(setup, 0.0)
	economy.add_payable(state, media)
	_grow_player(report)
	if not client.is_empty():
		economy.invoice(state, client, float(income["fee"]) + media + float(income["commission"]),
			float(income["fee"]) + float(income["commission"]))
	var airing: Array = data.bal("briefs.airing_weeks")
	camp["air_end_week"] = state.clock.week_index + state.rng.range_i("airing", int(airing[0]), int(airing[1]))
	state.airing.append(camp)
	state.history.append({"campaign": camp["id"], "client_id": setup["client_id"], "sector": setup["sector"],
		"objective": setup["objective"], "main_channel": Scoring.main_channel(setup["mix"]), "size": size,
		"week": state.clock.week_index, "year": state.clock.year(), "score": report["score"],
		"factors": {"m": report["combination"]["m"], "f": report["focus"]["f"], "b": report["balance"]["b"],
			"n": report["novelty"]["n"], "synergy": report["synergy"]["synergy"], "r": report["r"],
			"errors": report["errors"], "points": report["s"] + report["k"] + report["t"]}})
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
	var result: Dictionary = kpi.compute(setup, kpi_client, score, year, state.rng)
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
		var delta: float = clients.satisfaction_delta(client, score, ratio, setup["tone"], year)
		camp["satisfaction_delta"] = delta
		clients.apply_result(client, camp["id"], score, setup["objective"], year, delta)
	_apply_reputation(score, setup["size"])
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
	var lost: Array[String] = clients.remove_unhappy(state, lost_names)
	state.reputation -= lost.size() * data.balf("reputation.client_lost")
	if not lost.is_empty():
		var kept: Array[Dictionary] = []
		for b: Dictionary in state.inbox:
			if not lost.has(b["client_id"]):
				kept.append(b)
		state.inbox = kept
	state.reputation = clampf(state.reputation, data.balf("reputation.min"), data.balf("reputation.max"))
	campaign_finished.emit(camp)
	if not lost_names.is_empty():
		clients_lost.emit(lost_names)


## GDD 14.1 itibar: iyi puan +, kötü puan − (büyüklükle ölçeklenir).
func _apply_reputation(score: float, size: String) -> void:
	if score >= data.balf("reputation.good_score"):
		state.reputation += float(data.bal("reputation.good_gain")[size])
	elif score <= data.balf("reputation.bad_score"):
		state.reputation -= float(data.bal("reputation.bad_loss")[size])
	state.reputation = clampf(state.reputation, data.balf("reputation.min"), data.balf("reputation.max"))


## Oyuncu karakteri kampanyalardan XP kazanır, seviye atlayınca statlar artar (GDD 11.2, 11.5).
## M1'in geçici sade sürümü; M3'te çalışan modeliyle değiştirilecek (K-024).
func _grow_player(report: Dictionary) -> void:
	var g: Dictionary = data.bal("player_growth")
	state.player["xp"] = float(state.player.get("xp", 0.0)) + float(report["score"]) * float(g["xp_per_score_point"])
	var per_level: float = float(g["xp_per_level"])
	var cap: float = float(g["stat_cap"])
	while float(state.player["xp"]) >= per_level:
		state.player["xp"] = float(state.player["xp"]) - per_level
		state.player["level"] = int(state.player.get("level", 1)) + 1
		var total: float = maxf(1.0, float(report["s"]) + float(report["k"]) + float(report["t"]))
		var shares: Dictionary = {"strategy": float(report["s"]) / total, "creative": float(report["k"]) / total,
			"technical": float(report["t"]) / total}
		var points: float = float(g["stat_points_per_level"])
		for stat: String in shares:
			state.player[stat] = minf(cap, float(state.player[stat]) + points * float(shares[stat]))
		state.player["speed"] = minf(cap, float(state.player["speed"]) + float(g["speed_per_level"]))


func _end_year() -> void:
	economy.yearly(state)
	clients.yearly(state)
	if state.reputation > data.balf("reputation.decay_threshold"):
		state.reputation *= 1.0 - data.balf("reputation.decay_above_50")
