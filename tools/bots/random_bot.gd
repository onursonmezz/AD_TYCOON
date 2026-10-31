class_name RandomBot
extends RefCounted
## Her şeyi rastgele seçen bot (GDD 27.1): oyunun "cezalandırma" seviyesini ölçer.

const ACCEPT_CHANCE: float = 0.5

var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _init(seed_value: int) -> void:
	rng.seed = seed_value


func bot_name() -> String:
	return "rastgele"


func decide(sim: Simulation) -> void:
	if not sim.state.is_idle():
		return
	for brief: Dictionary in sim.state.inbox.duplicate():
		if rng.randf() >= ACCEPT_CHANCE:
			continue
		var channels: Array[String] = BotUtil.valid_channels(sim, brief)
		if channels.is_empty():
			continue
		var data: GameData = sim.data
		var choices: Dictionary = {
			"objective": data.objective_ids[rng.randi_range(0, data.objective_ids.size() - 1)],
			"audience": data.audience_ids[rng.randi_range(0, data.audience_ids.size() - 1)],
			"tone": data.tone_ids[rng.randi_range(0, data.tone_ids.size() - 1)],
			"mix": [{"channel": channels[rng.randi_range(0, channels.size() - 1)], "share": 1.0}],
			"sliders": [_random_sliders(), _random_sliders(), _random_sliders()]}
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
