class_name DeclineBriefCommand
extends RefCounted
## Oyuncu eylemi: brief'i reddeder (GDD 4.2 "Kabul / pazarlık / ret").

var brief_id: String


func _init(brief_id_in: String) -> void:
	brief_id = brief_id_in


func execute(sim: Simulation) -> bool:
	return sim.decline_brief(brief_id)
