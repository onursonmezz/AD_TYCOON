class_name PlanTaskPhaseCommand
extends RefCounted
## Oyuncu eylemi (S11): planlı kampanyada faz başında o fazın görev planı (ağırlıklar, kişiler, prodüksiyonda kiralıklar).

var campaign_id: String
var weights: Array
var assign_row: Array
var rentals: Array


func _init(id: String = "", w: Array = [], a: Array = [], r: Array = []) -> void:
	campaign_id = id
	weights = w
	assign_row = a
	rentals = r


## Dönüş: "" veya hata anahtarı.
func execute(sim: Simulation) -> String:
	return sim.plan_task_phase(campaign_id, weights, assign_row, rentals)
