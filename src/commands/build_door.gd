class_name BuildDoorCommand
extends RefCounted
## Oyuncu eylemi: inşa modunda bir iç duvara kapı boşluğu açar (K-116).

var point: Vector2


func _init(point_in: Vector2) -> void:
	point = point_in


## Dönüş: "" veya hata anahtarı.
func execute(sim: Simulation) -> String:
	return sim.walls.build_door(sim.state, sim.economy, point)
