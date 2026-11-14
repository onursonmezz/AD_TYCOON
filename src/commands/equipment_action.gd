class_name EquipmentActionCommand
extends RefCounted
## Oyuncu eylemi (K-100): prodüksiyon ekipmanı satın al ya da sat.

var action: String
var id: String


## action: "buy" | "sell"
func _init(action_in: String, id_in: String) -> void:
	action = action_in
	id = id_in


## Dönüş: "" veya hata anahtarı.
func execute(sim: Simulation) -> String:
	match action:
		"buy":
			return sim.equipment.buy(sim.state, sim.economy, id)
		"sell":
			return "" if sim.equipment.sell(sim.state, id) else "ERR_EQUIPMENT_NA"
	return "ERR_EQUIPMENT_NA"
