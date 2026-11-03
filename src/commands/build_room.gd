class_name BuildRoomCommand
extends RefCounted
## Oyuncu eylemi: büyütülmüş ofisten itibaren boş alana oda çizer (GDD 12.2, K-059).

var room_type: String
var rect: Rect2


func _init(type_in: String, rect_in: Rect2) -> void:
	room_type = type_in
	rect = rect_in


## Dönüş: "" veya hata anahtarı.
func execute(sim: Simulation) -> String:
	return sim.build.build_room(sim.state, sim.economy, room_type, rect)
