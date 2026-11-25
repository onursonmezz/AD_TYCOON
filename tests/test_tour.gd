extends GutTest
## K-148: gezinti modu — duvar ve eşyalardan geçilmez, zaman durur, çalışanlar yalnızca görüntüde dolaşır,
## kayda hiçbir şey yazılmaz, çıkınca her şey eski hâline döner.

var data: GameData


func before_all() -> void:
	data = GameData.load_from()


func after_each() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Clock.set_paused(true)


## Gezen her yöne uzun uzun yürüse de hiçbir duvarı kesmez ve hiçbir eşyanın içine girmez.
func test_walker_never_passes_through_walls_or_furniture() -> void:
	var radius: float = float(WorldLook.cfg()["tour"]["radius"])
	for level: int in range(1, data.max_office_level() + 1):
		var l: OfficeLayout = OfficeLayout.build(data.office_layouts["office_%d" % level])
		var start: Vector2 = TourCollision.start_point(l, 1.2, radius)
		assert_false(TourCollision.blocked(l, start, radius, 0.0), "seviye %d: başlangıç boş" % level)
		for angle: float in [0.0, 0.7, 1.6, 2.5, 3.3, 4.1, 5.0, 5.9]:
			var p: Vector2 = start
			for i: int in 300:
				var to: Vector2 = TourCollision.slide(l, p, p + Vector2.from_angle(angle + i * 0.01) * 0.08, radius, 5.0)
				for w: Dictionary in l.walls:
					assert_null(Geometry2D.segment_intersects_segment(p, to, w["a"], w["b"]),
						"seviye %d: duvar kesilmez" % level)
				p = to
			for prop: Dictionary in l.props:
				if not bool(prop.get("flat", false)) and not bool(prop.get("hanging", false)):
					assert_false((prop["rect"] as Rect2).has_point(p), "seviye %d: eşyanın içinde değil" % level)


func test_walker_stays_near_the_building() -> void:
	var l: OfficeLayout = OfficeLayout.build(data.office_layouts["office_1"])
	assert_true(TourCollision.blocked(l, Vector2(-20, -20), 0.25, 5.0), "sokağın ötesi kapalı")
	assert_true(TourCollision.blocked(l, l.walls[0]["a"].lerp(l.walls[0]["b"], 0.5), 0.25, 5.0), "duvarın üstü dolu")


func test_tour_stops_time_keeps_save_and_restores_everything() -> void:
	GameState.new_game(21)
	var main: Control = Control.new()
	add_child_autofree(main)
	var view: OfficeView = OfficeView.new()
	main.add_child(view)
	var dock: Control = Control.new()
	main.add_child(dock)
	var modal_layer: Control = Control.new()
	main.add_child(modal_layer)
	await wait_physics_frames(2)
	var world: OfficeWorld = view.world
	for id: String in world.character_ids():  # herkes masasına otursun
		for i: int in 60:
			world.character(id)._process(1.0)
	Clock.set_speed(0)
	assert_true(Clock.is_running())
	var before: String = JSON.stringify(GameState.sim.state.to_dict())
	var rng_before: String = JSON.stringify(GameState.sim.state.rng.to_dict())

	assert_null(TourMode.try_open(main, view, modal_layer, true), "inşa modunda açılmaz")
	var blocker: Control = Control.new()
	modal_layer.add_child(blocker)
	assert_null(TourMode.try_open(main, view, modal_layer, false), "pencere açıkken açılmaz")
	blocker.free()

	var mode: TourMode = TourMode.try_open(main, view, modal_layer, false)
	assert_not_null(mode)
	await wait_physics_frames(1)
	assert_false(Clock.is_running(), "zaman durdu")
	assert_false(dock.visible, "arayüz gizli")
	assert_true(view.visible, "ofis görünüyor")
	assert_not_null(world.tour)
	assert_true(world.tour.camera.current, "göz hizası kamerası")
	assert_almost_eq(world.tour.position.y, float(WorldLook.cfg()["tour"]["eye_height"]), 0.001)
	assert_null(TourMode.try_open(main, view, modal_layer, false), "ikinci kez açılmaz")

	var life: TourLife = world.get("_life")
	for i: int in 40:  # ~40 saniye: biri mutlaka kalkar
		life._process(1.0)
		if life.away_count() > 0:
			break
	assert_gt(life.away_count(), 0, "zaman dururken biri masasından kalktı")
	for id: String in world.character_ids():
		world.character(id)._process(0.5)
	assert_eq(JSON.stringify(GameState.sim.state.to_dict()), before, "simülasyon ve kayıt değişmedi")
	assert_eq(JSON.stringify(GameState.sim.state.rng.to_dict()), rng_before, "oyunun zarı atılmadı")

	mode.close()
	await wait_physics_frames(1)
	assert_true(Clock.is_running(), "eski hızına döndü")
	assert_true(dock.visible, "arayüz geri geldi")
	assert_null(world.tour)
	assert_true(world.rig.camera.current, "kuşbakışı kamera")
	for id: String in world.character_ids():
		var home: String = world.home_place(id)
		assert_false(home.is_empty(), "herkesin gerçek yeri yeniden atandı")
	assert_eq(Input.mouse_mode, Input.MOUSE_MODE_VISIBLE, "fare serbest")
	GameState.end_game()


## Gezintide bütün dış duvarlar tam boy; çıkınca kameraya bakanlar yeniden alçalır.
func test_walls_are_full_height_while_touring() -> void:
	GameState.new_game(5)
	var view: OfficeView = OfficeView.new()
	add_child_autofree(view)
	await wait_physics_frames(2)
	var world: OfficeWorld = view.world
	var walls: Array = world.get("_walls")
	var cut_before: int = _cut_count(walls)
	assert_gt(cut_before, 0, "kuşbakışında kesik duvar var")
	world.begin_tour()
	assert_eq(_cut_count(walls), 0, "gezintide kesik duvar yok")
	world.end_tour()
	assert_eq(_cut_count(walls), cut_before)
	GameState.end_game()


func _cut_count(walls: Array) -> int:
	var n: int = 0
	for w: Dictionary in walls:
		if not is_equal_approx(((w["mesh"] as MeshInstance3D).mesh as BoxMesh).size.y, float(w["height"])):
			n += 1
	return n
