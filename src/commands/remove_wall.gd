class_name RemoveWallCommand
extends RefCounted
## Oyuncu eylemi: noktadaki oyuncu kapısını kapatır ya da iç duvarı yıkar (K-116).

var point: Vector2


func _init(point_in: Vector2) -> void:
	point = point_in


## Dönüş: "" veya hata anahtarı.
func execute(sim: Simulation) -> String:
	return sim.walls.remove_at(sim.state, point)
