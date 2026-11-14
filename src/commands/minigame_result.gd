class_name MinigameResultCommand
extends RefCounted
## Oyuncu eylemi (K-120): fazın mini oyununun sonucu (0..1) ya da seçilen taslak.

var phase: int
var quality: float
var draft: Dictionary


func _init(phase_in: int, quality_in: float, draft_in: Dictionary = {}) -> void:
	phase = phase_in
	quality = quality_in
	draft = draft_in


## Dönüş: "" veya hata anahtarı.
func execute(sim: Simulation) -> String:
	var camp: Dictionary = sim.state.active_campaign
	if camp.is_empty():
		return "ERR_PLAN"
	if not draft.is_empty():
		Minigames.choose_draft(camp, draft)
	else:
		Minigames.record(camp, phase, quality)
	return ""
