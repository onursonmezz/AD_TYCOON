class_name StartCampaignCommand
extends RefCounted
## Oyuncu eylemi: gelen kutusundaki bir brief'i kabul edip kampanyayı başlatır (GDD 4.2, 7.1).

var brief_id: String
var choices: Dictionary


func _init(brief_id_in: String, choices_in: Dictionary) -> void:
	brief_id = brief_id_in
	choices = choices_in


## Dönüş: { "ok", "error", "campaign_id" }
func execute(sim: Simulation) -> Dictionary:
	return sim.start_campaign(brief_id, choices)
