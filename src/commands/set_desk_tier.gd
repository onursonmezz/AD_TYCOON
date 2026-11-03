class_name SetDeskTierCommand
extends RefCounted
## Oyuncu eylemi: bütün masa ve sandalyeleri bir kaliteye yükseltir (GDD 12.3 "basit → ergonomik → ayarlanabilir").

var tier: String


func _init(tier_in: String) -> void:
	tier = tier_in


## Dönüş: "" veya hata anahtarı.
func execute(sim: Simulation) -> String:
	return sim.build.set_desk_tier(sim.state, sim.economy, tier)
