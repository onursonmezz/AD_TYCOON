class_name MoveOfficeCommand
extends RefCounted
## Oyuncu eylemi: bir üst ofis seviyesine taşınır (GDD 12.1).


func execute(sim: Simulation) -> String:
	var err: String = sim.offices.move(sim.state, sim.economy)
	if err.is_empty():
		# Mobilya ve çizilen odalar yeni binaya gelmez; mobilya bedelinin yarısı iade (K-062).
		var refund: float = sim.build.on_move(sim.state)
		if refund > 0.0:
			sim.staff_note.emit("NOTE_FURNITURE_SOLD", [refund], "info")
	return err
