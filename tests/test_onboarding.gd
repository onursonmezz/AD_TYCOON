extends GutTest
## İlk dakikalar (S1): ilk brief şansa bırakılmaz ve oyuncuya okuma payı bırakır.

var data: GameData


func before_all() -> void:
	data = GameData.load_from()


func test_first_brief_arrives_in_first_week() -> void:
	for seed: int in [1, 7, 42, 99]:
		var sim: Simulation = Simulation.new(data, seed)
		sim.step_week()
		assert_eq(sim.state.inbox.size() >= 1, true, "tohum %d: 1. hafta sonunda brief var" % seed)


func test_first_brief_waits_longer() -> void:
	var sim: Simulation = Simulation.new(data, 3)
	sim.step_week()
	var b: Dictionary = sim.state.inbox[0]
	var expected: int = sim.state.clock.week_index + data.bali("briefs.first_brief_expiry_weeks")
	assert_eq(int(b["expires_week"]), expected, "ilk brief uzun süre geçerli")
