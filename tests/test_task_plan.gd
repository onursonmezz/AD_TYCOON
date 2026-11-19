extends GutTest
## Görev planı (S3A): ağırlık + tek kişilik atama, kampanya yükü, küçük işte atamasız çalışma.

var data: GameData


func before_all() -> void:
	data = GameData.load_from()


func _setup(size: String, team: Array) -> Dictionary:
	return {"size": size, "team": team, "sliders": [[0.4, 0.3, 0.3], [0.4, 0.3, 0.3], [0.4, 0.3, 0.3]]}


func test_small_job_and_solo_need_no_assignment() -> void:
	assert_false(TaskPlan.needs_assignment(data, _setup("small", ["a", "b"])), "küçük iş")
	assert_false(TaskPlan.needs_assignment(data, _setup("medium", ["a"])), "tek kişi")
	assert_false(TaskPlan.needs_assignment(data, _setup("medium", ["a", "b"])), "iki kişi: toplam yük %300, atama yok")
	assert_true(TaskPlan.needs_assignment(data, _setup("medium", ["a", "b", "c"])), "orta iş, üç kişi")


func test_load_is_sum_of_weights() -> void:
	var s: Dictionary = _setup("medium", ["a", "b"])
	s["assign"] = [["a", "b", "b"], ["a", "b", "b"], ["a", "b", "b"]]
	assert_almost_eq(TaskPlan.campaign_load(s, "a"), 1.2, 0.0001, "üç fazda %40 → %120")
	assert_almost_eq(TaskPlan.campaign_load(s, "b"), 1.8, 0.0001)
	assert_almost_eq(TaskPlan.phase_intensity(s, 0, "a"), 1.2, 0.0001)


func test_validate() -> void:
	assert_eq(TaskPlan.validate([["a", "", ""], ["", "", ""], ["", "", ""]], ["a"]), "")
	assert_eq(TaskPlan.validate([["x", "", ""], ["", "", ""], ["", "", ""]], ["a"]), "ERR_PLAN_MEMBER")
	assert_eq(TaskPlan.validate([["", "", ""], ["", "", ""], ["", "", ""]], ["a"]), "ERR_PLAN_EMPTY")


func test_only_assignee_produces_task() -> void:
	var sim: Simulation = Simulation.new(data, 4)
	var founder: String = sim.state.founder()["id"]
	var camp: Dictionary = sim.production.create({"team": [founder], "sliders": [[0.5, 0.5, 0.0], [0.34, 0.33, 0.33],
		[0.34, 0.33, 0.33]], "deadline_weeks": 6, "size": "medium", "mix": [{"channel": "newspaper", "share": 1.0}], "sector": "fast_food", "objective": "awareness", "audience": "",
		"tone": "", "assign": [[founder, "", ""], ["", "", ""], ["", "", ""]]}, "cp_t", 0)
	sim.production.produce_day(camp, sim.state)
	var areas: Array[String] = data.focus_ids_of_phase(0)
	assert_gt(float(camp["points"][areas[0]]), 0.0, "atanan görev puan alır")
	assert_eq(float(camp["points"][areas[1]]), 0.0, "atanmamış görev puan almaz")


func test_auto_assign_covers_all_tasks() -> void:
	var sim: Simulation = Simulation.new(data, 8)
	var team: Array = [sim.state.founder()["id"]]
	var assign: Array = TaskPlan.auto_assign(data, sim.state, _setup("medium", team)["sliders"], team)
	for p: Array in assign:
		for id: Variant in p:
			assert_eq(str(id), str(team[0]), "tek kişi her görevde")
