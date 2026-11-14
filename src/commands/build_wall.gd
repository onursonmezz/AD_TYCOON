class_name BuildWallCommand
extends RefCounted
## Oyuncu eylemi: inşa modunda iç duvar çeker (metre başı ücret, K-116).

var a: Vector2
var b: Vector2


func _init(a_in: Vector2, b_in: Vector2) -> void:
	a = a_in
	b = b_in


## Dönüş: "" veya hata anahtarı.
func execute(sim: Simulation) -> String:
	return sim.walls.build_wall(sim.state, sim.economy, a, b)
