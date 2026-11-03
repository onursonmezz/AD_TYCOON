class_name PresentPitchCommand
extends RefCounted
## Oyuncu eylemi: sunumun üç turunda seçilen kartlar (açılış, fikir, kapanış). Sonucu döndürür (GDD 14.2).

var cards: Array


func _init(cards_in: Array) -> void:
	cards = cards_in


## Dönüş: PitchSystem.present sonucu ({ "ok": false } geçersizse).
func execute(sim: Simulation) -> Dictionary:
	return sim.pitches.present(sim.state, cards)
