class_name MinigameResultCommand
extends RefCounted
## Oyuncu eylemi (K-120): fazın mini oyununun sonucu (0..1) ya da seçilen taslak.

var phase: int
var quality: float
var draft: Dictionary
## Mini oyunlar kapalıyken faz beklemesini kaldırmak için (S3A): sonuç yazılmaz, faz atlandı sayılır.
var skip: bool


func _init(phase_in: int, quality_in: float, draft_in: Dictionary = {}, skip_in: bool = false) -> void:
	phase = phase_in
	quality = quality_in
	draft = draft_in
	skip = skip_in


## Dönüş: "" veya hata anahtarı.
func execute(sim: Simulation) -> String:
	var camp: Dictionary = sim.state.active_campaign
	if camp.is_empty():
		return "ERR_PLAN"
	if skip:
		(camp.get_or_add("minigames_skipped", []) as Array).append(phase)
	elif not draft.is_empty():
		Minigames.choose_draft(camp, draft)
	else:
		Minigames.record(camp, phase, quality)
	# Planlı kampanyada faz yalnızca mini oyunu bekliyordu: devam.
	if (camp.get("confirmed_phases", []) as Array).has(phase):
		sim.state.waiting_for_input = false
		sim.state.waiting_campaign = ""
	return ""
