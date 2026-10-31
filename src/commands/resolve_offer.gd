class_name ResolveOfferCommand
extends RefCounted
## Oyuncu eylemi: rakip transfer teklifine karşılık ("match": zam) ya da bırakma ("release").

var offer_id: String
var choice: String


func _init(offer_in: String, choice_in: String) -> void:
	offer_id = offer_in
	choice = choice_in


func execute(sim: Simulation) -> String:
	return sim.staff_life.resolve_offer(sim.state, offer_id, choice)
