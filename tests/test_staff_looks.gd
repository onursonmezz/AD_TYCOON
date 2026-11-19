extends GutTest
## Görünüşler (S5): aynı 3B kadro karakteri ve aynı portre, seçenek varken iki kişiye verilmez.

var data: GameData


func before_all() -> void:
	data = GameData.load_from()


func _hire_many(sim: Simulation, n: int) -> void:
	for i: int in n:
		var found: Array[Dictionary] = sim.staff.search(sim.state, sim.economy, "copywriter", "job_ad", "tr")
		var cand: Dictionary = found[0]
		cand["gender"] = "male"
		cand["cast"] = sim.staff.unused_cast(sim.state, "male", sim.state.clock.year(), str(cand["id"]))
		cand["hired_week"] = sim.state.clock.week_index
		sim.state.staff[cand["id"]] = cand
		sim.state.candidates.erase(cand)


func test_same_cast_model_is_not_reused() -> void:
	var sim: Simulation = Simulation.new(data, 12)
	sim.state.clock.week_index = (1995 - 1990) * sim.state.clock.weeks_per_year()
	_hire_many(sim, 5)
	var seen: Dictionary = {}
	for emp: Dictionary in sim.state.staff.values():
		var cast: String = str(emp.get("cast", ""))
		if cast.is_empty():
			continue
		assert_false(seen.has(cast), "aynı model iki kişide: %s" % cast)
		seen[cast] = true


func test_candidates_get_different_portraits() -> void:
	var sim: Simulation = Simulation.new(data, 13)
	var found: Array[Dictionary] = sim.staff.search(sim.state, sim.economy, "copywriter", "job_ad", "tr")
	var by_gender: Dictionary = {}
	for c: Dictionary in found:
		var g: String = str(c["gender"])
		var list: Array = by_gender.get_or_add(g, [])
		var pool: int = 0
		for rec: Dictionary in data.raw["avatars.json"]:
			if str(rec["gender"]) == g:
				pool += 1
		if list.size() < pool:
			assert_false(list.has(c["avatar"]), "aynı portre iki adayda: %s" % c["avatar"])
		list.append(c["avatar"])
