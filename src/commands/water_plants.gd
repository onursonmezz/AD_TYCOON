class_name WaterPlantsCommand
extends RefCounted
## Oyuncu eylemi: ofisteki bitkileri sular (GDD 12.3: sulanmazsa kurur).


func execute(sim: Simulation) -> String:
	if sim.build.plant_count(sim.state) == 0:
		return "ERR_NO_PLANTS"
	sim.build.water(sim.state)
	return ""
