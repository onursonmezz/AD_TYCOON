class_name SearchCandidatesCommand
extends RefCounted
## Oyuncu eylemi: bir işe alım kanalından aday arar (GDD 11.3). Kanal ücreti ödenir.

var role: String
var channel_id: String
var lang: String


func _init(role_in: String, channel_in: String, lang_in: String) -> void:
	role = role_in
	channel_id = channel_in
	lang = lang_in


## Dönüş: adaylar (boşsa geçersiz rol/kanal).
func execute(sim: Simulation) -> Array[Dictionary]:
	var found: Array[Dictionary] = sim.staff.search(sim.state, sim.economy, role, channel_id, lang)
	# Rakipten transfer (GDD 11.3): her aday güce göre seçilmiş bir rakipte çalışıyor.
	if bool(sim.data.hiring_channels.get(channel_id, {}).get("from_rival", false)):
		for c: Dictionary in found:
			c["from_rival"] = sim.rivals.pick_by_power(sim.state)
	return found
