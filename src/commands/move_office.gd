class_name MoveOfficeCommand
extends RefCounted
## Oyuncu eylemi: bir üst ofis seviyesine taşınır (GDD 12.1).


func execute(sim: Simulation) -> String:
	return sim.offices.move(sim.state, sim.economy)
