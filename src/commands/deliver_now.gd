class_name DeliverNowCommand
extends RefCounted
## Oyuncu eylemi (S3C): rötuş sırasında kampanyayı hemen teslim et (S3D: hangi kampanya).

var campaign_id: String


func _init(id: String = "") -> void:
	campaign_id = id


## Dönüş: "" veya hata anahtarı.
func execute(sim: Simulation) -> String:
	return sim.deliver_now(campaign_id)
