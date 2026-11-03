class_name PlaceFurnitureCommand
extends RefCounted
## Oyuncu eylemi: inşa modunda mobilya satın alıp yerleştirir (GDD 12.3).

var furniture_id: String
var pos: Vector2
var rot: int


func _init(id_in: String, pos_in: Vector2, rot_in: int) -> void:
	furniture_id = id_in
	pos = pos_in
	rot = rot_in


## Dönüş: "" veya hata anahtarı.
func execute(sim: Simulation) -> String:
	return sim.build.place(sim.state, sim.economy, furniture_id, pos, rot)
