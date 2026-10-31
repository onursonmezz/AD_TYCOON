class_name NegotiateCommand
extends RefCounted
## Oyuncu eylemi: matbaayla pazarlık (GDD 10.3). list_price verilirse yeni pazarlık açılır; price verilirse karşı teklif.
## Dönüş: pazarlık durumu { "status", "round", "price", "list_price", ... }

var supplier_id: String
var list_price: float
var price: float


func _init(supplier_in: String, list_price_in: float = 0.0, price_in: float = 0.0) -> void:
	supplier_id = supplier_in
	list_price = list_price_in
	price = price_in


func execute(sim: Simulation) -> Dictionary:
	if list_price > 0.0:
		return sim.suppliers.start_negotiation(sim.state, supplier_id, list_price)
	return sim.suppliers.counter(sim.state, price)
