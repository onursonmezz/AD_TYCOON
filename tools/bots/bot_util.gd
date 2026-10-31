class_name BotUtil
extends RefCounted
## Botların ortak yardımcıları.


## Brief için bu yıl kullanılabilen ve tek kanal olarak min. bütçeyi karşılayan kanallar.
static func valid_channels(sim: Simulation, brief: Dictionary) -> Array[String]:
	var year: int = sim.state.clock.year()
	var infl: float = Economy.inflation(sim.data, year)
	var out: Array[String] = []
	for ch: String in sim.data.channels_available(year):
		if float(brief["media_budget"]) >= float(sim.data.channels[ch]["min_budget"]) * infl:
			out.append(ch)
	return out
