class_name RaiseSalaryCommand
extends RefCounted
## Oyuncu eylemi: maaşı piyasa değerine çeker.

var employee_id: String


func _init(employee_in: String) -> void:
	employee_id = employee_in


func execute(sim: Simulation) -> String:
	return sim.staff.raise_to_market(sim.state, employee_id)
