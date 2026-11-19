class_name DeliverNowCommand
extends RefCounted
## Oyuncu eylemi (S3C): rötuş sırasında kampanyayı hemen teslim et.


## Dönüş: "" veya hata anahtarı.
func execute(sim: Simulation) -> String:
	return sim.deliver_now()
