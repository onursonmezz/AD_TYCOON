class_name SetOvertimeCommand
extends RefCounted
## Oyuncu eylemi: fazla mesaiyi açar/kapatır (GDD 11.4).

var on: bool


func _init(on_in: bool) -> void:
	on = on_in


func execute(sim: Simulation) -> bool:
	sim.set_overtime(on)
	return true
