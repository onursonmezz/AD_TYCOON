class_name RespondSupplierOfferCommand
extends RefCounted
## Oyuncu eylemi: tedarikçiden gelen teklifi (indirim / yıllık taahhüt) kabul ya da reddeder (GDD 10.3).

var offer_id: String
var accept: bool


func _init(offer_in: String, accept_in: bool) -> void:
	offer_id = offer_in
	accept = accept_in


func execute(sim: Simulation) -> String:
	if accept:
		return sim.suppliers.accept_offer(sim.state, offer_id)
	return sim.suppliers.decline_offer(sim.state, offer_id)
