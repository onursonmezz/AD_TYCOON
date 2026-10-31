class_name SmartBot
extends RefCounted
## "Tabloyu bilen" açgözlü bot (GDD 27.1 bilgili bot): uyum tablolarını bilir, slider'ları ideal kurar,
## nakdi yetecek en kârlı brief'i seçer.

## Medya ödemesinden sonra elde kalması istenen nakit (aylık sabit gider katı).
const CASH_RESERVE_MONTHS: float = 3.0


func bot_name() -> String:
	return "bilgili"


func decide(sim: Simulation) -> void:
	if not sim.state.is_idle():
		return
	var data: GameData = sim.data
	var reserve: float = CASH_RESERVE_MONTHS * data.balf("cashflow.monthly_base_cost") \
		* Economy.inflation(data, sim.state.clock.year())
	var committed: float = 0.0
	for p: Dictionary in sim.state.payables:
		committed += float(p["amount"])
	var best_brief: Dictionary = {}
	var best_value: float = -1.0
	for brief: Dictionary in sim.state.inbox:
		if sim.state.cash - committed - float(brief["media_budget"]) < reserve:
			continue
		var value: float = float(brief["fee"]) + float(brief["media_budget"]) * data.balf("media_commission.default")
		if value > best_value and not BotUtil.valid_channels(sim, brief).is_empty():
			best_value = value
			best_brief = brief
	if best_brief.is_empty():
		return
	StartCampaignCommand.new(best_brief["id"], best_choices(sim, best_brief)).execute(sim)


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
	var s1: Array[float] = _ideal_sliders(sim, best["objective"], 0)
	var s2: Array[float] = _ideal_sliders(sim, best["objective"], 1)
	best["sliders"] = [s1, s2, _best_phase3_sliders(sim, best["objective"], s1, s2)]
	return best


## 3. fazda Medya Planlama ve Ölçümleme S'ye de puan yazar; F ile S/K dengesini (B) birlikte en iyileyen dağılım.
func _best_phase3_sliders(sim: Simulation, objective: String, s1: Array[float], s2: Array[float]) -> Array[float]:
	var player: Dictionary = sim.state.player
	var est_points: Dictionary = {}
	var phases: Array = [s1, s2]
	for phase: int in 2:
		var ids: Array[String] = sim.data.focus_ids_of_phase(phase)
		for i: int in 3:
			est_points[ids[i]] = sim.scoring.effective_share(float(phases[phase][i])) * sim.production.area_stat(player, ids[i])
	var ids3: Array[String] = sim.data.focus_ids_of_phase(2)
	var best: Array[float] = _ideal_sliders(sim, objective, 2)
	var best_value: float = -1.0
	for a: int in 11:
		for b: int in 11 - a:
			var sliders: Array[float] = [a / 10.0, b / 10.0, (10 - a - b) / 10.0]
			var pts: Dictionary = est_points.duplicate()
			for i: int in 3:
				pts[ids3[i]] = sim.scoring.effective_share(sliders[i]) * sim.production.area_stat(player, ids3[i])
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
