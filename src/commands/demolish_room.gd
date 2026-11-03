class_name DemolishRoomCommand
extends RefCounted
## Oyuncu eylemi: çizilen bir odayı yıkar (bedel geri gelmez).

var index: int


func _init(index_in: int) -> void:
	index = index_in


func execute(sim: Simulation) -> bool:
	return sim.build.demolish_room(sim.state, index)
