extends GutTest
## M10: dört bot (GDD 27.1) bir yıl hatasız oynar; yeni "aynı kanal üst üste" yenilik kuralı (varsayılan etkisiz).

const Bots: Dictionary = {"random": preload("res://tools/bots/random_bot.gd"), "smart": preload("res://tools/bots/smart_bot.gd"),
	"repeater": preload("res://tools/bots/repeater_bot.gd"), "greedy": preload("res://tools/bots/greedy_bot.gd")}

var data: GameData


func before_all() -> void:
	data = GameData.load_from()


func test_every_bot_plays_a_year() -> void:
	for kind: String in Bots:
		var sim: Simulation = Simulation.new(data, 31)
		var bot: RefCounted = Bots[kind].new(5) if kind == "random" else Bots[kind].new()
		for w: int in sim.state.clock.weeks_per_year():
			bot.call("decide", sim)
			sim.step_week()
		assert_gt(sim.state.history.size(), 0, "%s en az bir kampanya yaptı" % kind)


func test_repeater_keeps_its_combination() -> void:
	var sim: Simulation = Simulation.new(data, 32)
	var bot: RepeaterBot = RepeaterBot.new()
	var tones: Dictionary = {}
	(sim.state.research["done"] as Array).append_array(["tone_choice", "audience_analysis"])
	for w: int in sim.state.clock.weeks_per_year():
		bot.decide(sim)
		sim.step_week()
		if not sim.state.active_campaign.is_empty():
			tones[sim.state.active_campaign["setup"]["tone"]] = true
	assert_eq(tones.size(), 1, "tekrarcı hep aynı tonu seçer")


func test_channel_streak_rule_is_off_by_default() -> void:
	var sim: Simulation = Simulation.new(data, 33)
	var setup: Dictionary = {"sector": "fast_food", "objective": "awareness", "client_id": "x",
		"mix": [{"channel": "radio", "share": 1.0}]}
	var history: Array[Dictionary] = []
	for i: int in 2:
		history.append({"sector": "retail", "objective": "sales", "client_id": "y%d" % i, "main_channel": "radio", "week": 0})
	assert_almost_eq(float(sim.scoring.novelty(setup, history, 100, 1990)["n"]), 1.0, 0.0001, "1.0 = etkisiz")
	data.balance["novelty"]["same_channel_streak"] = 0.85
	assert_almost_eq(float(sim.scoring.novelty(setup, history, 100, 1990)["n"]), 0.85, 0.0001)
	data.balance["novelty"]["same_channel_streak"] = 1.0
