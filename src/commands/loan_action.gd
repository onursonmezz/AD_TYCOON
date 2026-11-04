class_name LoanActionCommand
extends RefCounted
## Oyuncu eylemi: banka kredisi çek ("take": tutar, vade ay) ya da erken kapat ("repay") (GDD 13.5).

var action: String
var amount: float
var months: int


func _init(action_in: String, amount_in: float = 0.0, months_in: int = 0) -> void:
	action = action_in
	amount = amount_in
	months = months_in


func execute(sim: Simulation) -> String:
	if action == "repay":
		return sim.loans.repay(sim.state)
	return sim.loans.take(sim.state, amount, months)
