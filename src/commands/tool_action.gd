class_name ToolActionCommand
extends RefCounted
## Oyuncu eylemi (GDD 12.4–12.5): araç al, sürüm yükselt, aboneliğe geç, aboneliği iptal et ya da bilgisayar kuşağı al.

var action: String
var id: String


## action: "buy" | "update" | "subscribe" | "cancel" | "hardware"
func _init(action_in: String, id_in: String) -> void:
	action = action_in
	id = id_in


## Dönüş: "" veya hata anahtarı.
func execute(sim: Simulation) -> String:
	match action:
		"buy":
			return sim.tools.buy(sim.state, sim.economy, id)
		"update":
			return sim.tools.update(sim.state, sim.economy, id)
		"subscribe":
			return sim.tools.subscribe(sim.state, id)
		"cancel":
			return "" if sim.tools.cancel(sim.state, id) else "ERR_TOOL_NA"
		"hardware":
			return sim.tools.buy_hardware(sim.state, sim.economy, id)
	return "ERR_TOOL_NA"
