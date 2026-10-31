class_name TrainEmployeeCommand
extends RefCounted
## Oyuncu eylemi: stat eğitimi (stat verilir) ya da sektör uzmanlaşması (sector verilir) (GDD 11.2, 11.3).

var employee_id: String
var stat: String
var sector: String


func _init(employee_in: String, stat_in: String = "", sector_in: String = "") -> void:
	employee_id = employee_in
	stat = stat_in
	sector = sector_in


func execute(sim: Simulation) -> String:
	if not sector.is_empty():
		return sim.staff.specialize(sim.state, sim.economy, employee_id, sector)
	return sim.staff.train(sim.state, sim.economy, employee_id, stat)
