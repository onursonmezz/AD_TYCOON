extends GutTest
## M6-B: inşa modu (GDD 12.2–12.3) — mobilya, masa kalitesi, oda çizme, oda kalitesi ve oda etkileri.

var data: GameData


func before_all() -> void:
	data = GameData.load_from()


func _sim(level: int = 1) -> Simulation:
	var sim: Simulation = Simulation.new(data, 4)
	sim.state.office_level = level
	sim.state.cash = 5000000.0
	sim.build.refresh(sim.state)
	return sim


## Boş bir köşe (ev odasında masaların sağında).
func _free_spot(sim: Simulation, id: String) -> Vector2:
	var l: OfficeLayout = sim.build.layout(sim.state)
	for x: int in int(l.size.x * 2.0):
		for z: int in int(l.size.y * 2.0):
			var p: Vector2 = Vector2(x * 0.5, z * 0.5)
			if sim.build.place_error(sim.state, id, p, 0) == "":
				return p
	return Vector2.INF


func test_no_furniture_keeps_old_room_quality() -> void:
	for level: int in range(1, data.max_office_level() + 1):
		var sim: Simulation = _sim(level)
		assert_almost_eq(sim.state.room_quality, float(data.office(level)["room_quality"]), 0.001,
			"seviye %d: mobilyasız kalite eski sabit değer (denge korunur)" % level)


func test_furniture_raises_quality_costs_money_and_sells_for_half() -> void:
	var sim: Simulation = _sim(2)
	var q0: float = sim.state.room_quality
	var cash0: float = sim.state.cash
	var p: Vector2 = _free_spot(sim, "plant_big")
	assert_ne(p, Vector2.INF)
	assert_eq(PlaceFurnitureCommand.new("plant_big", p, 0).execute(sim), "")
	var cost: float = sim.build.furniture_cost(sim.state, "plant_big")
	assert_almost_eq(cash0 - sim.state.cash, cost, 0.01)
	assert_gt(sim.state.room_quality, q0)
	assert_eq(sim.build.place_error(sim.state, "plant_big", p, 0), "ERR_PLACE_BLOCKED", "aynı yere ikinci eşya konmaz")
	assert_true(SellFurnitureCommand.new(0).execute(sim))
	assert_almost_eq(sim.state.cash, cash0 - cost * 0.5, 0.01, "yarı fiyatına satılır")
	assert_almost_eq(sim.state.room_quality, q0, 0.001)


func test_furniture_cannot_block_paths_or_exceed_limit() -> void:
	var sim: Simulation = _sim(2)
	var l: OfficeLayout = sim.build.layout(sim.state)
	var kitchen: Rect2 = l.room_rect("kitchen")
	var door: Vector2 = Vector2(kitchen.position.x - 0.5, kitchen.get_center().y - 0.5)
	assert_eq(sim.build.place_error(sim.state, "plant_big", door, 0), "ERR_PLACE_PATH", "mutfak kapısı kapatılamaz")
	assert_eq(PlaceFurnitureCommand.new("office_cat", _free_spot(sim, "office_cat"), 0).execute(sim), "")
	assert_eq(sim.build.place_error(sim.state, "office_cat", _free_spot(sim, "plant_small"), 0), "ERR_FURNITURE_LIMIT")
	assert_eq(sim.build.place_error(sim.state, "espresso", Vector2(1, 1), 0), "ERR_FURNITURE", "1990'da espresso makinesi yok")


func test_desk_tier_upgrade() -> void:
	var sim: Simulation = _sim(2)
	var q0: float = sim.state.room_quality
	var cost: float = sim.build.desk_tier_cost(sim.state, "ergonomic")
	assert_almost_eq(cost, 1500.0 * sim.build.layout(sim.state).desks.size(), 0.01, "masa başına bedel (1990)")
	assert_eq(SetDeskTierCommand.new("adjustable").execute(sim), "ERR_DESK_TIER", "2005'ten önce yok")
	assert_eq(SetDeskTierCommand.new("ergonomic").execute(sim), "")
	assert_gt(sim.state.room_quality, q0)


func test_crowding_lowers_quality() -> void:
	var sim: Simulation = _sim(1)
	var q0: float = sim.state.room_quality
	for i: int in 6:
		var emp: Dictionary = sim.state.founder().duplicate(true)
		emp["id"] = "x%d" % i
		emp["is_founder"] = false
		sim.state.staff[emp["id"]] = emp
	sim.build.refresh(sim.state)
	assert_lt(sim.state.room_quality, q0, "25 m²'ye 7 kişi kalabalık")


func test_rooms_only_from_enlarged_office_on_empty_space() -> void:
	var sim: Simulation = _sim(2)
	assert_eq(sim.build.room_error(sim.state, "brainstorm", Rect2(0, 0, 4, 4)), "ERR_ROOM_LEVEL")
	sim = _sim(3)
	var empty: Rect2 = Rect2()
	for room: Dictionary in sim.build.layout(sim.state).rooms:
		if room["type"] == "empty":
			empty = room["rect"]
	assert_eq(sim.build.room_error(sim.state, "brainstorm", Rect2(empty.position, Vector2(2, 2))), "ERR_ROOM_SMALL")
	assert_eq(sim.build.room_error(sim.state, "brainstorm", Rect2(0, 0, 4, 4)), "ERR_ROOM_NOT_EMPTY", "çalışma alanına çizilmez")
	var rect: Rect2 = Rect2(empty.position + Vector2(1, 1), Vector2(4, 3))
	assert_false(sim.state.office_effects.has("focus_mult"))
	assert_eq(BuildRoomCommand.new("brainstorm", rect).execute(sim), "")
	assert_eq(float(sim.state.office_effects["focus_mult"]["concept"]), 1.1, "beyin fırtınası odası konsepte +%10")
	assert_eq(sim.build.room_error(sim.state, "lounge", rect.grow(1.0)), "ERR_ROOM_OVERLAP")
	assert_true(sim.build.layout(sim.state).all_reachable())
	assert_true(DemolishRoomCommand.new(0).execute(sim))
	assert_false(sim.state.office_effects.has("focus_mult"))


func test_room_effects_come_from_closed_rooms() -> void:
	var home: Simulation = _sim(1)
	assert_false(home.state.office_effects.has("burnout_recovery_mult"), "ev odasındaki minder köşesi etki vermez")
	assert_false(home.state.office_effects.has("energy_rest_mult"))
	var small: Simulation = _sim(2)
	assert_eq(float(small.state.office_effects["energy_rest_mult"]), 1.25, "küçük ofisin mutfağı")
	assert_eq(float(small.state.office_effects["satisfaction"]), 2.0, "küçük ofisin toplantı odası")


func test_moving_sells_furniture_for_half() -> void:
	var sim: Simulation = _sim(1)
	sim.state.clock.week_index = 48 * 3
	sim.state.office_level = 1
	sim.build.refresh(sim.state)
	assert_eq(PlaceFurnitureCommand.new("plant_small", _free_spot(sim, "plant_small"), 0).execute(sim), "")
	var paid: float = sim.build.furniture_cost(sim.state, "plant_small")
	var cash0: float = sim.state.cash
	assert_eq(MoveOfficeCommand.new().execute(sim), "")
	assert_almost_eq(sim.state.cash, cash0 - sim.offices.move_cost(sim.state, sim.offices.current(sim.state)) + paid * 0.5, 0.01)
	assert_true((sim.state.build["furniture"] as Array).is_empty())


func test_build_survives_save() -> void:
	var sim: Simulation = _sim(2)
	assert_eq(PlaceFurnitureCommand.new("whiteboard", _free_spot(sim, "whiteboard"), 0).execute(sim), "")
	var errors: Array[String] = []
	var loaded: Simulation = SaveCodec.decode(data, SaveCodec.encode(sim), errors)
	assert_eq(errors.size(), 0)
	assert_eq((loaded.state.build["furniture"] as Array).size(), 1)
	assert_almost_eq(loaded.state.room_quality, sim.state.room_quality, 0.001, "kalite yüklemede yeniden hesaplanır")
