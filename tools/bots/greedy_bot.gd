class_name GreedyBot
extends SmartBot
## Açgözlü büyüme botu (GDD 27.1): bilgili bot gibi kampanya yapar ama nakde bakmadan büyür: kapasite boşaldıkça
## işe alır, taşınabilir olur olmaz taşınır, nakit iki aylık giderin altına inince en büyük krediyi çeker.
## Ekonominin riskini ölçer: kontrolsüz büyüme cezalandırılmalı.


func bot_name() -> String:
	return "açgözlü"


func _grow(sim: Simulation) -> void:
	if not sim.loans.has_loan(sim.state) and sim.state.cash < 2.0 * BotUtil.monthly_costs(sim):
		var terms: Array = sim.data.bal("loans.terms_months")
		LoanActionCommand.new("take", sim.loans.max_amount(sim.state), int(terms[terms.size() - 1])).execute(sim)
	if sim.offices.can_move(sim.state):
		MoveOfficeCommand.new().execute(sim)
	if sim.staff.headcount(sim.state) >= sim.staff.capacity(sim.state):
		return
	var role: String = HIRE_ORDER[(sim.state.staff.size() - 1) % HIRE_ORDER.size()]
	var found: Array[Dictionary] = SearchCandidatesCommand.new(role, "job_ad", "tr").execute(sim)
	if not found.is_empty():
		HireEmployeeCommand.new(found[0]["id"]).execute(sim)


## Nakit tahminine bakmadan her işi alır (risk ölçümü).
func _affordable(_sim: Simulation, _brief: Dictionary, _reserve: float) -> bool:
	return true
