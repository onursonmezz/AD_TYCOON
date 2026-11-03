class_name ResearchActionCommand
extends RefCounted
## Oyuncu eylemi (GDD 17): bir araştırmayı başlatır ya da Pazar Araştırması hizmetiyle bir uyum hücresini açar.

var action: String
var id: String


## action: "begin" (id = araştırma) | "insight" (id = sektör)
func _init(action_in: String, id_in: String) -> void:
	action = action_in
	id = id_in


## Dönüş: "" veya hata anahtarı.
func execute(sim: Simulation) -> String:
	if action == "begin":
		return sim.research.begin(sim.state, sim.economy, id)
	if action == "insight":
		return str(sim.research.buy_insight(sim.state, sim.economy, id)["error"])
	return "ERR_RESEARCH"
