class_name HireEmployeeCommand
extends RefCounted
## Oyuncu eylemi: son aramadaki bir adayı işe alır (ofis kapasitesi ve CD sınırı kontrol edilir).

var candidate_id: String


func _init(candidate_in: String) -> void:
	candidate_id = candidate_in


## Dönüş: "" veya hata anahtarı.
func execute(sim: Simulation) -> String:
	return sim.staff.hire(sim.state, candidate_id)
