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
		if float(brief["media_budget"]) >= float(sim.data.channels[ch]["min_budget"]) * infl:
			out.append(ch)
	return out
