extends GutTest
## K-100: prodüksiyon ekipmanı ve kiralama.

var data: GameData


func before_all() -> void:
	data = GameData.load_from()


func _sim(year: int = 1990) -> Simulation:
	var sim: Simulation = Simulation.new(data, 9)
	sim.state.clock.week_index = (year - 1990) * 48
	sim.state.cash = 5000000.0
	return sim


func _setup(mix: Array, rentals: Array = []) -> Dictionary:
	return {"mix": mix, "rentals": rentals}


func test_buy_upkeep_and_sell() -> void:
	var sim: Simulation = _sim()
	var cash0: float = sim.state.cash
	assert_eq(sim.equipment.buy(sim.state, sim.economy, "vhs_camcorder"), "")
	assert_almost_eq(cash0 - sim.state.cash, sim.equipment.price(sim.state, "vhs_camcorder"), 0.01)
	assert_eq(sim.equipment.buy(sim.state, sim.economy, "vhs_camcorder"), "ERR_EQUIPMENT_OWNED")
	assert_eq(sim.equipment.buy(sim.state, sim.economy, "drone"), "ERR_EQUIPMENT_NA", "1990'da drone yok")
	assert_eq(sim.equipment.buy(sim.state, sim.economy, "studio_day"), "ERR_EQUIPMENT_NA", "kiralık satın alınmaz")
	assert_gt(sim.equipment.monthly_cost(sim.state), 0.0)
	var before: float = sim.state.cash
	assert_true(sim.equipment.sell(sim.state, "vhs_camcorder"))
	assert_almost_eq(sim.state.cash - before, sim.equipment.price(sim.state, "vhs_camcorder") * data.balf("equipment.sell_refund"), 0.01)


func test_effect_depends_on_channels_and_best_of_group() -> void:
	var sim: Simulation = _sim(2010)
	assert_almost_eq(sim.equipment.production_mult(sim.state, _setup([{"channel": "national_tv", "share": 1.0}])), 1.0, 0.0001,
		"ekipmansız etki yok")
	sim.state.equipment = ["vhs_camcorder", "hd_camera"]
	var tv: float = sim.equipment.production_mult(sim.state, _setup([{"channel": "national_tv", "share": 1.0}]))
	assert_almost_eq(tv, 1.0 + float(data.equipment["hd_camera"]["bonus"]), 0.0001, "gruptan yalnızca en iyisi")
	var half: float = sim.equipment.production_mult(sim.state, _setup([{"channel": "national_tv", "share": 0.5},
		{"channel": "radio", "share": 0.5}]))
	assert_almost_eq(half, 1.0 + float(data.equipment["hd_camera"]["bonus"]) * 0.5, 0.0001, "kanal payı kadar")
	assert_almost_eq(sim.equipment.production_mult(sim.state, _setup([{"channel": "radio", "share": 1.0}])), 1.0, 0.0001,
		"radyoda kamera işe yaramaz")


func test_rentals_add_for_one_campaign_and_bonus_is_capped() -> void:
	var sim: Simulation = _sim(2015)
	var mix: Array = [{"channel": "national_tv", "share": 1.0}]
	var with_crew: float = sim.equipment.production_mult(sim.state, _setup(mix, ["film_crew"]))
	assert_almost_eq(with_crew, 1.0 + float(data.equipment["film_crew"]["bonus"]), 0.0001)
	sim.state.equipment = ["cinema_4k", "led_panels", "green_screen", "drone", "home_studio"]
	sim.state.clock.week_index = (2017 - 1990) * 48
	var maxed: float = sim.equipment.production_mult(sim.state, _setup(mix, ["film_crew", "studio_day", "drone_crew"]))
	assert_almost_eq(maxed, 1.0 + data.balf("equipment.max_bonus"), 0.0001, "üst sınır")
	assert_eq(sim.equipment.validate_rentals(sim.state, ["helicopter_shot"]), "ERR_EQUIPMENT_NA", "2013'ten sonra helikopter yok")


func test_equipment_is_saved() -> void:
	var sim: Simulation = _sim()
	sim.state.equipment = ["vhs_camcorder"]
	var errors: Array[String] = []
	var loaded: Simulation = SaveCodec.decode(data, SaveCodec.encode(sim), errors)
	assert_eq(loaded.state.equipment, ["vhs_camcorder"])
