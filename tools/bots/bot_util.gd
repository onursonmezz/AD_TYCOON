class_name BotUtil
extends RefCounted
## Botların ortak yardımcıları.


## Kampanyaya atanabilecek (müsait) bütün çalışanlar.
static func available_team(sim: Simulation) -> Array:
	var team: Array = []
	for emp: Dictionary in sim.state.staff.values():
		if Employee.is_available(emp, sim.state.clock.week_index):
			team.append(emp["id"])
	return team


## Sabit aylık giderler (taban + kira + maaş/SGK).
static func monthly_costs(sim: Simulation) -> float:
	return sim.data.balf("cashflow.monthly_base_cost") * Economy.inflation(sim.data, sim.state.clock.year()) \
		+ sim.offices.monthly_rent(sim.state) + sim.staff.monthly_payroll(sim.state)


## Önümüzdeki `weeks` hafta boyunca en düşük nakit tahmini: bekleyen tahsilat/ödemeler, haftalık sabit gider ve
## isteğe bağlı yeni bir kampanya (medya ödemesi ve faturası en kötü vadeyle). Botun "nakdim yeter mi" kontrolü.
static func min_projected_cash(sim: Simulation, weeks: int, extra_out: float = 0.0, extra_out_week: int = 0,
		extra_in: float = 0.0, extra_in_week: int = 0, extra_monthly: float = 0.0) -> float:
	var now: int = sim.state.clock.week_index
	var weekly_cost: float = (monthly_costs(sim) + extra_monthly) / sim.data.balf("time.weeks_per_month")
	var outs: Dictionary = {extra_out_week: extra_out}
	var ins: Dictionary = {extra_in_week: extra_in}
	# Üretimdeki kampanya henüz borç/fatura listesinde değil: teslimdeki medya ödemesi ve en geç tahsilat.
	var camp: Dictionary = sim.state.active_campaign
	if not camp.is_empty():
		var setup: Dictionary = camp["setup"]
		var terms: Array = sim.data.bal("cashflow.payment_terms")
		var delivery: int = int(camp["start_week"]) + int(setup["deadline_weeks"])
		var media: float = float(setup["media_budget"])
		var advance: float = float(setup.get("media_advance", 0.0))
		var media_week: int = delivery + sim.data.bali("cashflow.media_payment_weeks")
		var in_week: int = delivery + int(terms[terms.size() - 1]["weeks"])
		outs[media_week] = float(outs.get(media_week, 0.0)) + media
		ins[in_week] = float(ins.get(in_week, 0.0)) + float(setup["fee"]) + media * (1.0 + sim.data.balf("media_commission.default")) - advance
	var cash: float = sim.state.cash
	var lowest: float = cash
	for w: int in range(1, weeks + 1):
		var week: int = now + w
		cash -= weekly_cost
		for r: Dictionary in sim.state.receivables:
			if int(r["due_week"]) == week:
				cash += float(r["amount"])
		for p: Dictionary in sim.state.payables:
			if int(p["due_week"]) == week:
				cash -= float(p["amount"])
		cash -= float(outs.get(week, 0.0))
		cash += float(ins.get(week, 0.0))
		lowest = minf(lowest, cash)
	return lowest


static func committed_payables(sim: Simulation) -> float:
	var total: float = 0.0
	for p: Dictionary in sim.state.payables:
		total += float(p["amount"])
	return total


## Brief için bu yıl kullanılabilen ve tek kanal olarak min. bütçeyi karşılayan kanallar.
static func valid_channels(sim: Simulation, brief: Dictionary) -> Array[String]:
	var year: int = sim.state.clock.year()
	var infl: float = Economy.inflation(sim.data, year)
	var out: Array[String] = []
	for ch: String in sim.data.channels_available(year):
		if float(brief["media_budget"]) >= float(sim.data.channels[ch]["min_budget"]) * infl and sim.research.channel_unlocked(sim.state, ch):
			out.append(ch)
	return out


## Açık ödüllere başvurur (GDD 15). min_margin: beklenen skorun kısa liste eşiğini en az bu kadar aşması;
## chance: her uygun kampanya için başvurma olasılığı (rastgele bot). Başvuru ücreti sonrası en az bir aylık gider kalmalı.
static func enter_awards(sim: Simulation, min_margin: float, chance: float, rng: RandomNumberGenerator) -> void:
	for award_id: String in sim.awards.open_awards(sim.state):
		var shortlist: float = float(sim.data.awards[award_id]["thresholds"]["shortlist"])
		for h: Dictionary in sim.awards.eligible_campaigns(sim.state, award_id):
			if sim.awards.expected_score(award_id, h) < shortlist + min_margin or rng.randf() >= chance:
				continue
			if sim.state.cash - sim.awards.entry_fee(sim.state, award_id) < monthly_costs(sim):
				return
			EnterAwardCommand.new(award_id, h["campaign"]).execute(sim)


## Pitch (GDD 14.2). Bilgili bot: kampanyada olmayan en iyi iki kişiyle katılır, bilinen ipuçlarına göre kart seçer.
## Rastgele bot: yarı yarıya katılır, rastgele ekip ve kart.
static func handle_pitch(sim: Simulation, smart: bool, rng: RandomNumberGenerator) -> void:
	var state: SimState = sim.state
	if sim.pitches.is_waiting(state):
		var cards: Array = []
		for r: String in PitchSystem.ROUNDS:
			var options: Array[String] = sim.pitches.cards_of_round(r)
			cards.append(_best_card(sim, options) if smart else options[rng.randi_range(0, options.size() - 1)])
		sim.pitches.present(state, cards)
		return
	if state.pitch_invites.is_empty() or (not smart and rng.randf() < 0.5):
		return
	var on_campaign: Array = state.active_campaign.get("setup", {}).get("team", [])
	var free: Array[Dictionary] = []
	for emp: Dictionary in state.staff.values():
		if Employee.is_available(emp, state.clock.week_index) and not on_campaign.has(emp["id"]):
			free.append(emp)
	if free.is_empty() or (smart and state.staff.size() < 3):
		return
	free.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["stats"]["strategy"]) + float(a["stats"]["creative"]) > float(b["stats"]["strategy"]) + float(b["stats"]["creative"]))
	var size: int = mini(2, free.size()) if smart else rng.randi_range(1, mini(2, free.size()))
	var team: Array = []
	for i: int in size:
		team.append(free[i]["id"])
	sim.pitches.accept(state, state.pitch_invites[0]["id"], team, 1.0)


static func _best_card(sim: Simulation, options: Array[String]) -> String:
	var pitch: Dictionary = sim.state.pitch
	var known: Dictionary = {"prefs": {"risk": 0.0, "budget": 0.0, "digital": 0.0, "humor": 0.0}}
	for key: String in sim.pitches.hints(pitch):
		known["prefs"][key] = pitch["prefs"][key]
	var best: String = options[0]
	for id: String in options:
		if sim.pitches.card_fit(known, id) > sim.pitches.card_fit(known, best):
			best = id
	return best


## Araçlar (GDD 12.5). Bilgili bot: ayda bir, güvenli nakdin küçük bir kısmıyla eksik araçları alır (AI araçları hariç:
## yenilik bedeli oyuncunun kararı), eski sürümleri günceller,
## abonelik dönemine geçer, bilgisayarları yeniler. Rastgele bot: arada bir rastgele bir araç alır.
static func manage_tools(sim: Simulation, smart: bool, rng: RandomNumberGenerator) -> void:
	var state: SimState = sim.state
	if state.clock.week_in_month() != 1 or state.clock.day_in_week != 0:
		return
	# Önümüzdeki yarım yılın en dip nakdi, yedek ve orta boy bir işin medya yükü düşüldükten sonra kalanın bir kısmı.
	var media_float: float = float(sim.data.bal("briefs.media.medium")[0]) * Economy.inflation(sim.data, state.clock.year())
	var budget: float = (min_projected_cash(sim, TOOL_HORIZON_WEEKS) - TOOL_RESERVE_MONTHS * monthly_costs(sim) - media_float) \
		* TOOL_BUDGET_SHARE
	if not smart:
		var ids: Array[String] = sim.tools.available(state)
		if not ids.is_empty() and rng.randf() < RANDOM_TOOL_CHANCE:
			ToolActionCommand.new("buy", ids[rng.randi_range(0, ids.size() - 1)]).execute(sim)
		return
	for hw: String in sim.data.hardware_ids:
		if int(sim.data.hardware[hw]["available_from"]) <= state.clock.year() \
				and sim.data.hardware_ids.find(hw) > sim.data.hardware_ids.find(state.hardware) and sim.tools.hardware_cost(state, hw) < budget:
			ToolActionCommand.new("hardware", hw).execute(sim)
	for id: String in sim.tools.available(state):
		var year: int = state.clock.year()
		if float(sim.data.tools[id]["ai_penalty"]) > 0.0:
			continue
		if not sim.tools.owned(state, id):
			var cost: float = sim.tools.seat_cost(state, id) * state.staff.size() * 12.0 if sim.tools.is_subscription_era(id, year) \
				else sim.tools.license_cost(state, id)
			if cost < budget:
				ToolActionCommand.new("buy", id).execute(sim)
		elif not bool(state.tools[id]["sub"]):
			if sim.tools.is_subscription_era(id, year):
				ToolActionCommand.new("subscribe", id).execute(sim)
			elif sim.tools.update_cost(state, id) < budget:
				ToolActionCommand.new("update", id).execute(sim)


const TOOL_RESERVE_MONTHS: float = 3.0
const TOOL_HORIZON_WEEKS: int = 26
const TOOL_BUDGET_SHARE: float = 0.2
const RANDOM_TOOL_CHANCE: float = 0.05


## Ar-Ge (GDD 17). Bilgili bot: boştaysa veri sırasıyla ilk başlatılabilir araştırmayı (ucuzsa) başlatır.
## Rastgele bot: arada bir rastgele başlatılabilir bir araştırma.
static func manage_research(sim: Simulation, smart: bool, rng: RandomNumberGenerator) -> void:
	var state: SimState = sim.state
	if not (state.research["active"] as Dictionary).is_empty():
		return
	var ready: Array[String] = []
	for id: String in sim.data.research_ids:
		if sim.research.can_start(state, id) and sim.research.cost(state, id) < state.cash - TOOL_RESERVE_MONTHS * monthly_costs(sim):
			ready.append(id)
	if ready.is_empty() or (not smart and rng.randf() >= RANDOM_RESEARCH_CHANCE):
		return
	ResearchActionCommand.new("begin", ready[0] if smart else ready[rng.randi_range(0, ready.size() - 1)]).execute(sim)


const RANDOM_RESEARCH_CHANCE: float = 0.1


## Olaylar (M7-C): bilgili bot her seçeneğin beklenen değerini kaba ağırlıklarla tartar; rastgele bot rastgele seçer.
static func handle_events(sim: Simulation, smart: bool, rng: RandomNumberGenerator) -> void:
	var inst: Dictionary = EventSystem.pending(sim.state)
	if inst.is_empty():
		return
	var opts: Array = inst["options"]
	var choice: int = int(opts[rng.randi_range(0, opts.size() - 1)])
	if smart:
		var best: float = -INF
		for i: Variant in opts:
			var opt: Dictionary = sim.events.events[inst["id"]]["options"][int(i)]
			var v: float = _effects_value(sim, opt.get("effects", {}))
			if opt.has("check"):
				var p: float = sim.events.check_chance(sim.state, inst, opt["check"])
				v = p * _effects_value(sim, opt.get("success", {})) + (1.0 - p) * _effects_value(sim, opt.get("fail", {}))
			if v > best:
				best = v
				choice = int(i)
	ResolveEventCommand.new(inst["uid"], choice).execute(sim)


## Kaba değer: 1990 ₺ 1000 = 1 puan; itibar 3, müşteri memnuniyeti 0.5, moral 0.1…; müşteri ya da çalışan kaybı ağır.
static func _effects_value(sim: Simulation, effects: Dictionary) -> float:
	const W: Dictionary = {"reputation": 3.0, "award_buzz": 300.0, "research_points": 0.3, "prospect_brief": 8.0,
		"client.satisfaction": 0.5, "client.trust": 0.3, "client.budget": 20.0, "client.leave": -25.0, "client.brief": 6.0,
		"clients.satisfaction": 1.5, "employee.morale": 0.1, "employee2.morale": 0.1, "employee.energy": 0.05,
		"employee.burnout": -0.1, "employee.salary": -10.0, "employee.xp": 0.02, "employee.quit": -20.0,
		"employee.leave_weeks": -1.5, "team.morale": 0.4, "team.energy": 0.2, "team.burnout": -0.4,
		"campaign.days": -0.8, "campaign.errors": -1.5, "campaign.quality": 60.0, "campaign.kpi": 10.0,
		"campaign.satisfaction": 0.5, "campaign.fee_bonus": 20.0, "rival.reputation": -0.5}
	var v: float = 0.0
	for key: String in effects:
		var x: Variant = effects[key]
		if key == "cash":
			v += float(x) / 1000.0
		elif W.has(key):
			v += float(W[key]) * (1.0 if x is bool else float(x))
	return v
