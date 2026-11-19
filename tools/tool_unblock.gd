class_name ToolUnblock
extends RefCounted
## Araçlar için (S11): faz başında bekleyen kampanyayı ilerletir. Fazın planı yoksa eşit ağırlık ve otomatik
## atamayla planlar, plan varsa mini oyunu orta puanla geçer.


static func unblock(score: float = 0.6) -> void:
	var sim: Simulation = GameState.sim
	var camp: Dictionary = sim.state.active_campaign
	if camp.is_empty() or not sim.state.waiting_for_input:
		return
	var phase: int = sim.production.current_phase(camp)
	if not (camp.get("confirmed_phases", []) as Array).has(phase) and bool(camp["setup"].get("polish", false)):
		var third: float = 1.0 / 3.0
		var setup: Dictionary = camp["setup"]
		var row: Array = []
		if TaskPlan.has_plan(setup):
			var sl: Array = (setup["sliders"] as Array).duplicate(true)
			sl[phase] = [third, third, 1.0 - 2.0 * third]
			row = TaskPlan.auto_assign_phases(sim.data, sim.state, sl, setup.get("team", []), setup["assign"], [phase])[phase]
		GameState.execute(PlanTaskPhaseCommand.new(str(camp["id"]), [third, third, 1.0 - 2.0 * third], row))
		return
	GameState.execute(MinigameResultCommand.new(phase, score))
