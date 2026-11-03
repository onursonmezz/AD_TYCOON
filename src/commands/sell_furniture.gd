class_name SellFurnitureCommand
extends RefCounted
## Oyuncu eylemi: yerleştirilmiş bir mobilyayı satar (bedelin yarısı geri gelir).

var index: int


func _init(index_in: int) -> void:
	index = index_in


func execute(sim: Simulation) -> bool:
	return sim.build.sell(sim.state, index)
