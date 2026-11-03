class_name EnterAwardCommand
extends RefCounted
## Oyuncu eylemi: bir kampanyayı açık başvuru dönemindeki bir ödüle gönderir; başvuru ücreti ödenir (GDD 15).

var award_id: String
var campaign_id: String


func _init(award_in: String, campaign_in: String) -> void:
	award_id = award_in
	campaign_id = campaign_in


## Dönüş: "" veya hata anahtarı.
func execute(sim: Simulation) -> String:
	return sim.awards.enter(sim.state, sim.economy, award_id, campaign_id)
