extends GutTest
## K-117: kampanyalardan hedef × odak alanı önemini öğrenme.

var data: GameData


func before_all() -> void:
	data = GameData.load_from()


func _setup(sliders: Array) -> Dictionary:
	return {"sector": "fast_food", "objective": "sales", "audience": "young", "tone": "humorous",
		"mix": [{"channel": "radio", "share": 1.0}], "sliders": sliders}


func test_emphasised_sliders_are_learned_first() -> void:
	var sim: Simulation = Simulation.new(data, 3)
	# Strateji fazında araştırma öne çıkarıldı, kreatifte metin kısıldı; prodüksiyon dengeli.
	var learned: Array[String] = sim.research.learn_focus(sim.state, _setup([[90, 30, 30], [60, 10, 50], [50, 50, 50]]))
	assert_eq(learned.size(), int(data.bal("research.focus_learn_per_campaign")))
	assert_true(learned.has("research"), "en çok sapan alan önce")
	assert_true(learned.has("copy"))
	assert_true(sim.research.focus_known(sim.state, "sales", "research"))
	assert_false(sim.research.focus_known(sim.state, "awareness", "research"), "başka hedefte bilinmez")


func test_works_with_saved_shares() -> void:
	var sim: Simulation = Simulation.new(data, 3)
	# Oyunda kaydırıcılar paylar olarak kaydedilir (toplam 1).
	var learned: Array[String] = sim.research.learn_focus(sim.state, _setup([[0.6, 0.2, 0.2], [0.34, 0.33, 0.33], [0.33, 0.33, 0.34]]))
	assert_eq(learned[0], "research", "%60 pay en çok öne çıkan")
	for id: String in learned:
		assert_true(data.focus_ids_of_phase(0).has(id), "dengeli fazlardan öğrenilmez")


func test_known_areas_are_not_relearned() -> void:
	var sim: Simulation = Simulation.new(data, 3)
	var setup: Dictionary = _setup([[90, 30, 30], [60, 10, 50], [50, 50, 50]])
	var first: Array[String] = sim.research.learn_focus(sim.state, setup)
	var second: Array[String] = sim.research.learn_focus(sim.state, setup)
	for id: String in second:
		assert_false(first.has(id), "aynı alan iki kez öğrenilmez")


func test_balanced_sliders_learn_at_most_one_by_chance() -> void:
	var sim: Simulation = Simulation.new(data, 3)
	var total: int = 0
	for i: int in 20:
		total += sim.research.learn_focus(sim.state, _setup([[50, 50, 50], [50, 50, 50], [50, 50, 50]])).size()
	assert_gt(total, 0, "dengeli dağılımda da zamanla bir şey öğrenilir")
	assert_lte(total, 9, "en fazla dokuz alan var")

