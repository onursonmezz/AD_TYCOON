class_name HireEmployeeCommand
extends RefCounted
## Oyuncu eylemi: son aramadaki bir adayı işe alır (ofis kapasitesi ve CD sınırı kontrol edilir).

var candidate_id: String


func _init(candidate_in: String) -> void:
	candidate_id = candidate_in


## Dönüş: "" veya hata anahtarı.
func execute(sim: Simulation) -> String:
	var rival: String = ""
	for c: Dictionary in sim.state.candidates:
		if c["id"] == candidate_id:
			rival = str(c.get("from_rival", ""))
	var err: String = sim.staff.hire(sim.state, candidate_id)
	if err.is_empty() and not rival.is_empty():
		sim.rivals.weaken_by_transfer(sim.state, rival)
	return err
