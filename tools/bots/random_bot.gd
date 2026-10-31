class_name RandomBot
extends RefCounted
## Her şeyi rastgele seçen bot (GDD 27.1): oyunun "cezalandırma" seviyesini ölçer.

const ACCEPT_CHANCE: float = 0.5

var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _init(seed_value: int) -> void:
	rng.seed = seed_value


func bot_name() -> String:
	return "rastgele"


const HIRE_CHANCE: float = 0.05


func decide(sim: Simulation) -> void:
	if rng.randf() < HIRE_CHANCE and sim.staff.headcount(sim.state) < sim.staff.capacity(sim.state):
		var roles: Array[String] = []
		for id: String in sim.data.position_ids:
			if bool(sim.data.positions[id]["hireable"]) and int(sim.data.positions[id]["available_from"]) <= sim.state.clock.year():
				roles.append(id)
		var found: Array[Dictionary] = SearchCandidatesCommand.new(roles[rng.randi_range(0, roles.size() - 1)], "job_ad",
			"tr").execute(sim)
		if not found.is_empty():
			HireEmployeeCommand.new(found[rng.randi_range(0, found.size() - 1)]["id"]).execute(sim)
	if sim.offices.can_move(sim.state) and rng.randf() < HIRE_CHANCE:
		MoveOfficeCommand.new().execute(sim)
	if not sim.state.is_idle():
		return
	for brief: Dictionary in sim.state.inbox.duplicate():
		if rng.randf() >= ACCEPT_CHANCE:
			continue
		var channels: Array[String] = BotUtil.valid_channels(sim, brief)
		if channels.is_empty():
			continue
		var data: GameData = sim.data
		var team: Array = BotUtil.available_team(sim)
		var count: int = rng.randi_range(1, mini(sim.media.channel_limit(sim.state, team), channels.size()))
		var picked: Array[String] = []
		while picked.size() < count:
			var ch: String = channels[rng.randi_range(0, channels.size() - 1)]
			if not picked.has(ch):
				picked.append(ch)
		var mix: Array = []
		for ch: String in picked:
			mix.append({"channel": ch, "share": 1.0 / count})
		var choices: Dictionary = {
			"objective": data.objective_ids[rng.randi_range(0, data.objective_ids.size() - 1)],
			"audience": data.audience_ids[rng.randi_range(0, data.audience_ids.size() - 1)],
			"tone": data.tone_ids[rng.randi_range(0, data.tone_ids.size() - 1)],
			"mix": mix,
			"sliders": [_random_sliders(), _random_sliders(), _random_sliders()],
			"team": BotUtil.available_team(sim)}
		StartCampaignCommand.new(brief["id"], choices).execute(sim)
		return


func _random_sliders() -> Array[float]:
	var a: float = rng.randf()
	var b: float = rng.randf()
	var c: float = rng.randf()
	var sum: float = maxf(0.0001, a + b + c)
	var out: Array[float] = [a / sum, b / sum]
	out.append(1.0 - out[0] - out[1])
	return out
