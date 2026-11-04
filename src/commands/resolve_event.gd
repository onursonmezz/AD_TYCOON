class_name ResolveEventCommand
extends RefCounted
## Oyuncu eylemi: karar bekleyen olayda bir seçenek seçer (GDD 16). option: olay verisindeki seçenek sırası (0'dan).

var event_uid: String
var option: int


func _init(uid_in: String, option_in: int) -> void:
	event_uid = uid_in
	option = option_in


func execute(sim: Simulation) -> Dictionary:
	return sim.events.resolve(sim, event_uid, option)
