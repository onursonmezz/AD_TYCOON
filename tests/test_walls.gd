extends GutTest
## K-116: inşa modunda iç duvar çekme, silme, kapı açma; oda kapalılığı duvarlardan.
## Ofis 2 (14×9): solda açık çalışma alanı, sağda kapısı batıda toplantı (üst) ve mutfak (alt).

var data: GameData


func before_all() -> void:
	data = GameData.load_from()


func _sim(level: int = 2) -> Simulation:
	var sim: Simulation = Simulation.new(data, 4)
	sim.state.office_level = level
	sim.state.cash = 5000000.0
	sim.build.refresh(sim.state)
	return sim


func _layout(sim: Simulation) -> OfficeLayout:
	return sim.build.layout(sim.state)


func test_wall_intervals_merge_and_split() -> void:
	var lines: Dictionary = {}
	OfficeWalls.add(lines, "h:2.00", 0.0, 2.0)
	OfficeWalls.add(lines, "h:2.00", 1.5, 4.0)
	assert_eq(lines["h:2.00"], [[0.0, 4.0]], "üst üste binen duvarlar birleşir")
	OfficeWalls.subtract(lines, "h:2.00", 1.0, 2.0)
	assert_eq(lines["h:2.00"], [[0.0, 1.0], [2.0, 4.0]], "ortadan silinince ikiye ayrılır")
	assert_almost_eq(OfficeWalls.covered(lines, Vector2(0, 2), Vector2(4, 2)), 3.0, 0.001)


func test_rules() -> void:
	var sim: Simulation = _sim()
	assert_eq(sim.walls.wall_error(sim.state, Vector2(1, 1), Vector2(3, 3)), "ERR_WALL_STRAIGHT")
	assert_eq(sim.walls.wall_error(sim.state, Vector2(11, 7), Vector2(11, 7.5)), "ERR_WALL_SHORT")
	assert_eq(sim.walls.wall_error(sim.state, Vector2(2, 0), Vector2(6, 0)), "ERR_WALL_OUTSIDE", "dış duvara dokunulmaz")
	assert_eq(sim.walls.wall_error(sim.state, Vector2(9, 5), Vector2(14, 5)), "ERR_WALL_EXISTS")
	assert_eq(sim.walls.wall_error(sim.state, Vector2(10, 2.5), Vector2(13, 2.5)), "ERR_PLACE_BLOCKED", "masanın içinden geçmez")


func test_removing_builtin_wall_opens_room_and_drawing_closes_it() -> void:
	var sim: Simulation = _sim()
	assert_true(_layout(sim).has_closed_room("meeting"))
	var cash0: float = sim.state.cash
	assert_eq(RemoveWallCommand.new(Vector2(9, 0.8)).execute(sim), "")
	assert_false(_layout(sim).has_closed_room("meeting"), "duvarı yıkılan oda açık sayılır")
	assert_almost_eq(sim.state.cash, cash0, 0.01, "hazır duvarı yıkmak bedava, iade yok")
	var cost: float = sim.walls.wall_cost(sim.state, Vector2(9, 0), Vector2(9, 2))
	assert_almost_eq(cost, 2.0 * sim.walls.wall_cost_per_m(sim.state), 0.01)
	assert_eq(BuildWallCommand.new(Vector2(9, 0), Vector2(9, 2)).execute(sim), "")
	assert_true(_layout(sim).has_closed_room("meeting"), "duvar geri çekilince oda yine kapalı")
	assert_almost_eq(sim.state.cash, cash0 - cost, 0.01)


func test_own_wall_refunds_half() -> void:
	var sim: Simulation = _sim()
	var a: Vector2 = Vector2(11.5, 6.5)
	var b: Vector2 = Vector2(11.5, 9.0)
	assert_eq(BuildWallCommand.new(a, b).execute(sim), "")
	assert_true(_layout(sim).all_reachable())
	var cash0: float = sim.state.cash
	assert_eq(RemoveWallCommand.new(Vector2(11.5, 8.0)).execute(sim), "")
	assert_almost_eq(sim.state.cash, cash0 + 2.5 * sim.walls.wall_cost_per_m(sim.state) * 0.5, 0.01)
	assert_eq(sim.walls.wall_at(sim.state, Vector2(11.5, 8.0)), {})


func test_wall_cannot_lock_anyone_in() -> void:
	var sim: Simulation = _sim(1)
	var cash0: float = sim.state.cash
	var err: String = BuildWallCommand.new(Vector2(0, 4.5), Vector2(7, 4.5)).execute(sim)
	assert_true(err == "ERR_PLACE_PATH" or err == "ERR_PLACE_BLOCKED", "girişi kapatan duvar çekilmez: " + err)
	assert_eq(sim.state.cash, cash0)


func test_door_opens_gap_and_closing_is_free() -> void:
	var sim: Simulation = _sim()
	assert_eq(BuildDoorCommand.new(Vector2(11.5, 5.0)).execute(sim), "ERR_DOOR_BLOCKED", "mutfak tezgâhının arkasına kapı yok")
	# Toplantı odasının batı duvarının alt parçası (3.3–5 m).
	var p: Vector2 = Vector2(9.0, 4.2)
	var cash0: float = sim.state.cash
	assert_eq(BuildDoorCommand.new(p).execute(sim), "")
	assert_almost_eq(sim.state.cash, cash0 - sim.walls.door_cost(sim.state), 0.01)
	p = Vector2(9.0, 4.1)
	assert_true(_layout(sim).is_walkable(p), "kapı boşluğundan geçilir")
	assert_false(sim.walls.door_at(sim.state, p).is_empty())
	assert_eq(RemoveWallCommand.new(p).execute(sim), "", "kapıya silme: kapı kapanır")
	assert_true(sim.walls.door_at(sim.state, p).is_empty())
	assert_false(_layout(sim).is_walkable(p))
	assert_almost_eq(sim.walls.wall_refund(sim.state, sim.walls.wall_at(sim.state, p)), 0.0, 0.01,
		"kapanan kapının yerinden iade gelmez")
	assert_eq(BuildDoorCommand.new(Vector2(4, 2)).execute(sim), "ERR_WALL_NONE")


func test_moving_refunds_drawn_walls() -> void:
	var sim: Simulation = _sim(1)
	sim.state.clock.week_index = 48 * 3
	assert_eq(BuildWallCommand.new(Vector2(5, 0), Vector2(5, 1.5)).execute(sim), "")
	var back: float = sim.walls.move_refund(sim.state)
	assert_almost_eq(back, 1.5 * sim.walls.wall_cost_per_m(sim.state) * 0.5, 0.01)
	var cash0: float = sim.state.cash
	var move_cost: float = sim.offices.move_cost(sim.state, sim.offices.next_office(sim.state))
	assert_eq(MoveOfficeCommand.new().execute(sim), "")
	assert_almost_eq(sim.state.cash, cash0 - move_cost + back, 0.01)
	assert_true((sim.state.build["wall_ops"] as Array).is_empty())


func test_walls_survive_save() -> void:
	var sim: Simulation = _sim()
	assert_eq(RemoveWallCommand.new(Vector2(9, 0.8)).execute(sim), "")
	assert_eq(BuildWallCommand.new(Vector2(13, 0), Vector2(13, 2.5)).execute(sim), "")
	var errors: Array[String] = []
	var loaded: Simulation = SaveCodec.decode(data, SaveCodec.encode(sim), errors)
	assert_eq(errors.size(), 0)
	assert_false(_layout(loaded).has_closed_room("meeting"), "yıkılan duvar yüklemeden sonra da yok")
	assert_false(loaded.walls.wall_at(loaded.state, Vector2(13, 1)).is_empty(), "çekilen duvar yüklemeden sonra yerinde")
