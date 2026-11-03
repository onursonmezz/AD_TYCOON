class_name AcceptPitchCommand
extends RefCounted
## Oyuncu eylemi: ihale davetini kabul eder, pitch ekibini ve ücret teklifini seçer (GDD 14.2).

var invite_id: String
var team: Array
var fee_ratio: float


func _init(invite_in: String, team_in: Array, fee_ratio_in: float) -> void:
	invite_id = invite_in
	team = team_in
	fee_ratio = fee_ratio_in


## Dönüş: "" veya hata anahtarı.
func execute(sim: Simulation) -> String:
	return sim.pitches.accept(sim.state, invite_id, team, fee_ratio)
