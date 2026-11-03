class_name SmartBot
extends RefCounted
## "Tabloyu bilen" açgözlü bot (GDD 27.1 bilgili bot): uyum tablolarını bilir, slider'ları ideal kurar,
## nakdi yetecek en kârlı brief'i seçer.

## Nakit tahmininde en dip noktada bile elde kalması istenen yedek (aylık sabit gider katı).
const CASH_RESERVE_MONTHS: float = 1.0
## İşe alım/taşınma kararında bakılan süre ve yedek.
const GROWTH_HORIZON_WEEKS: int = 26
const GROWTH_RESERVE_MONTHS: float = 2.0
## Kampanya kararında, en kötü tahsilat vadesinin üstüne eklenen güvenlik payı (hafta).
const PAYMENT_SAFETY_WEEKS: int = 2
## İkinci kanalın bütçe payı.
const SECOND_SHARE: float = 0.4
## Ekibi bu sırayla büyütür: önce kreatif ve strateji, sonra prodüksiyon, account, hata yakalama.
const HIRE_ORDER: Array[String] = ["art_director", "planner", "copywriter", "producer", "account", "graphic_designer",
	"media_planner", "proofreader", "copywriter", "art_director", "planner", "producer"]


func bot_name() -> String:
	return "bilgili"


func decide(sim: Simulation) -> void:
	_grow(sim)
	if not sim.state.is_idle():
		return
	var data: GameData = sim.data
	var reserve: float = CASH_RESERVE_MONTHS * BotUtil.monthly_costs(sim)
	var best_brief: Dictionary = {}
	var best_value: float = -1.0
	for brief: Dictionary in sim.state.inbox:
		if not _affordable(sim, brief, reserve):
			continue
		var value: float = float(brief["fee"]) + float(brief["media_budget"]) * data.balf("media_commission.default")
		if value > best_value and not BotUtil.valid_channels(sim, brief).is_empty():
			best_value = value
			best_brief = brief
	if best_brief.is_empty():
		return
	var choices: Dictionary = best_choices(sim, best_brief)
	choices["team"] = BotUtil.available_team(sim)
	StartCampaignCommand.new(best_brief["id"], choices).execute(sim)


## Kampanyanın medya ödemesi (teslim + medya vadesi) ve faturası (teslim + en uzun vade + pay) hesaba katılınca
## nakit hiçbir hafta yedeğin altına düşmüyorsa alınabilir.
func _affordable(sim: Simulation, brief: Dictionary, reserve: float) -> bool:
	var now: int = sim.state.clock.week_index
	var delivery: int = now + int(brief["deadline_weeks"])
	var terms: Array = sim.data.bal("cashflow.payment_terms")
	var worst_term: int = int(terms[terms.size() - 1]["weeks"])
	var client: Dictionary = brief["prospect"] if not (brief["prospect"] as Dictionary).is_empty() \
		else sim.state.clients.get(brief["client_id"], {})
	# Avans hemen gelir; medya ödemesinden düşmek temkinli bir yaklaşıklıktır (K-050).
	var advance: float = sim.economy.media_advance(client, float(brief["media_budget"]))
	var media: float = float(brief["media_budget"]) - advance
	var income: float = float(brief["fee"]) + float(brief["media_budget"]) * sim.data.balf("media_commission.default") + media
	var horizon: int = int(brief["deadline_weeks"]) + worst_term + PAYMENT_SAFETY_WEEKS
	return BotUtil.min_projected_cash(sim, horizon, media, delivery + sim.data.bali("cashflow.media_payment_weeks"),
		income, delivery + worst_term + PAYMENT_SAFETY_WEEKS) >= reserve


## Nakit tahmini izin veriyorsa ofis taşır; kapasite varsa sıradaki pozisyonu işe alır (en iyi ana statlı aday).
func _grow(sim: Simulation) -> void:
	var reserve: float = GROWTH_RESERVE_MONTHS * BotUtil.monthly_costs(sim)
	if sim.offices.can_move(sim.state):
		var next: Dictionary = sim.offices.next_office(sim.state)
		var rent_diff: float = (float(next["rent_1990"]) - float(sim.offices.current(sim.state)["rent_1990"])) \
			* Economy.inflation(sim.data, sim.state.clock.year())
		var low: float = BotUtil.min_projected_cash(sim, GROWTH_HORIZON_WEEKS, sim.offices.move_cost(sim.state, next),
			sim.state.clock.week_index + 1, 0.0, 0, rent_diff)
		if low >= reserve:
			MoveOfficeCommand.new().execute(sim)
	if sim.staff.headcount(sim.state) >= sim.staff.capacity(sim.state):
		return
	var hired: int = sim.state.staff.size() - 1
	var role: String = HIRE_ORDER[hired % HIRE_ORDER.size()]
	var infl: float = Economy.inflation(sim.data, sim.state.clock.year())
	var expected_salary: float = float(sim.data.positions[role]["base_salary"]) * infl \
		* (1.0 + sim.data.balf("economy.payroll_tax"))
	# İşe alımdan sonra da orta boy bir işin medya yükünü taşıyabilecek nakit kalmalı (yoksa iş alamaz, maaşla kan kaybeder).
	var media_float: float = float(sim.data.bal("briefs.media.medium")[0]) * infl
	if BotUtil.min_projected_cash(sim, GROWTH_HORIZON_WEEKS, 0.0, 0, 0.0, 0, expected_salary) < reserve + media_float:
		return
	var found: Array[Dictionary] = SearchCandidatesCommand.new(role, "job_ad", "tr").execute(sim)
	var best: Dictionary = {}
	var best_value: float = -1.0
	for c: Dictionary in found:
		var v: float = 0.0
		for s: Variant in sim.data.positions[role]["primary_stats"]:
			v += float(c["stats"][s])
		if v > best_value:
			best_value = v
			best = c
	if not best.is_empty():
		HireEmployeeCommand.new(best["id"]).execute(sim)


func best_choices(sim: Simulation, brief: Dictionary) -> Dictionary:
	var data: GameData = sim.data
	var client: Dictionary = brief["prospect"] if not (brief["prospect"] as Dictionary).is_empty() \
		else sim.state.clients[brief["client_id"]]
	var objectives: Array[String] = []
	if str(brief["objective"]).is_empty():
		objectives = data.objective_ids
	else:
		objectives = [str(brief["objective"])]
	var channels: Array[String] = BotUtil.valid_channels(sim, brief)
	var best: Dictionary = {}
	var best_m: float = -1.0
	for obj: String in objectives:
		for aud: String in data.audience_ids:
			for ch: String in channels:
				var setup: Dictionary = {"client_id": brief["client_id"], "sector": brief["sector"], "objective": obj,
					"audience": aud, "tone": "emotional", "mix": [{"channel": ch, "share": 1.0}]}
				setup["tone"] = _best_tone(sim, setup, client)
				var m: float = float(sim.scoring.combination(setup, client)["m"]) \
					* float(sim.scoring.novelty(setup, sim.state.history, sim.state.clock.week_index, sim.state.clock.year())["n"])
				if m > best_m:
					best_m = m
					best = setup
	_maybe_add_second_channel(sim, brief, best, client, channels, best_m)
	var s1: Array[float] = _ideal_sliders(sim, best["objective"], 0)
	var s2: Array[float] = _ideal_sliders(sim, best["objective"], 1)
	best["sliders"] = [s1, s2, _best_phase3_sliders(sim, best["objective"], s1, s2)]
	return best


## Kanal sınırı ve bütçe izin veriyorsa, M × sinerjiyi artıran ikinci kanalı %40 payla ekler (GDD 7.3).
func _maybe_add_second_channel(sim: Simulation, brief: Dictionary, best: Dictionary, client: Dictionary,
		channels: Array[String], single_m: float) -> void:
	if sim.media.channel_limit(sim.state, BotUtil.available_team(sim)) < 2:
		return
	var media_budget: float = float(brief["media_budget"])
	var year: int = sim.state.clock.year()
	var infl: float = Economy.inflation(sim.data, year)
	var first: String = best["mix"][0]["channel"]
	var best_value: float = single_m * float(sim.scoring.synergy(best["mix"], media_budget, year)["synergy"])
	var best_mix: Array = best["mix"]
	for ch: String in channels:
		if ch == first or media_budget * SECOND_SHARE < float(sim.data.channels[ch]["min_budget"]) * infl \
				or media_budget * (1.0 - SECOND_SHARE) < float(sim.data.channels[first]["min_budget"]) * infl:
			continue
		var mix: Array = [{"channel": first, "share": 1.0 - SECOND_SHARE}, {"channel": ch, "share": SECOND_SHARE}]
		var trial: Dictionary = best.duplicate()
		trial["mix"] = mix
		var value: float = float(sim.scoring.combination(trial, client)["m"]) \
			* float(sim.scoring.novelty(trial, sim.state.history, sim.state.clock.week_index, year)["n"]) \
			* float(sim.scoring.synergy(mix, media_budget, year)["synergy"])
		if value > best_value:
			best_value = value
			best_mix = mix
	best["mix"] = best_mix


## 3. fazda Medya Planlama ve Ölçümleme S'ye de puan yazar; F ile S/K dengesini (B) birlikte en iyileyen dağılım.
func _best_phase3_sliders(sim: Simulation, objective: String, s1: Array[float], s2: Array[float]) -> Array[float]:
	var player: Dictionary = sim.state.founder()
	var est_points: Dictionary = {}
	var phases: Array = [s1, s2]
	for phase: int in 2:
		var ids: Array[String] = sim.data.focus_ids_of_phase(phase)
		for i: int in 3:
			est_points[ids[i]] = sim.scoring.effective_share(float(phases[phase][i])) * Employee.area_stat(sim.data, player, ids[i])
	var ids3: Array[String] = sim.data.focus_ids_of_phase(2)
	var best: Array[float] = _ideal_sliders(sim, objective, 2)
	var best_value: float = -1.0
	for a: int in 11:
		for b: int in 11 - a:
			var sliders: Array[float] = [a / 10.0, b / 10.0, (10 - a - b) / 10.0]
			var pts: Dictionary = est_points.duplicate()
			for i: int in 3:
				pts[ids3[i]] = sim.scoring.effective_share(sliders[i]) * Employee.area_stat(sim.data, player, ids3[i])
			var totals: Dictionary = sim.scoring.stat_totals(pts)
			var value: float = float(sim.scoring.phase_focus(objective, 2, sliders)["f"]) \
				* float(sim.scoring.balance_sk(totals["strategy"], totals["creative"], objective)["b"])
			if value > best_value + 0.000001:
				best_value = value
				best = sliders
	return best


func _best_tone(sim: Simulation, setup: Dictionary, client: Dictionary) -> String:
	var best: String = ""
	var best_v: int = -99
	for tone: String in sim.data.tone_ids:
		var v: int = sim.scoring.tone_value(setup["sector"], tone, client)
		if v > best_v:
			best_v = v
			best = tone
	return best


## En önemli alana %60, ikinciye %40 (GDD 7.4 tavan kuralı).
func _ideal_sliders(sim: Simulation, objective: String, phase: int) -> Array[float]:
	var ids: Array[String] = sim.data.focus_ids_of_phase(phase)
	var order: Array[int] = [0, 1, 2]
	order.sort_custom(func(a: int, b: int) -> bool:
		return sim.data.focus_importance(objective, ids[a]) > sim.data.focus_importance(objective, ids[b]))
	var cap: float = sim.data.balf("focus.slider_soft_cap")
	var out: Array[float] = [0.0, 0.0, 0.0]
	out[order[0]] = cap
	out[order[1]] = 1.0 - cap
	return out
