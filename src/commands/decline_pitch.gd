class_name DeclinePitchCommand
extends RefCounted
## Oyuncu eylemi: ihale davetini reddeder.

var invite_id: String


func _init(invite_in: String) -> void:
	invite_id = invite_in


func execute(sim: Simulation) -> bool:
	return sim.pitches.decline(sim.state, invite_id)
