class_name FireEmployeeCommand
extends RefCounted
## Oyuncu eylemi: çalışanı işten çıkarır (tazminat ödenir, diğerlerinin morali düşer).

var employee_id: String


func _init(employee_in: String) -> void:
	employee_id = employee_in


func execute(sim: Simulation) -> String:
	return sim.staff.fire(sim.state, sim.economy, employee_id)
