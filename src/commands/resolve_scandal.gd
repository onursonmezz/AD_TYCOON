class_name ResolveScandalCommand
extends RefCounted
## Oyuncu eylemi: influencer skandalına karar verir: "terminate" (sözleşmeyi feshet), "silent" (sessiz kal),
## "statement" (açıklama yap; iletişim zar atışı) (GDD 9.6).

var scandal_id: String
var choice: String


func _init(scandal_in: String, choice_in: String) -> void:
	scandal_id = scandal_in
	choice = choice_in


func execute(sim: Simulation) -> Dictionary:
	return sim.influencers.resolve_scandal(sim.state, scandal_id, choice)
