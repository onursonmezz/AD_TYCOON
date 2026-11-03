extends GutTest
## M6-A: ofis yerleşimleri (masa sayısı, yürünebilirlik) ve 3D ofisin simülasyonu doğru okuması.

var data: GameData


func before_all() -> void:
	data = GameData.load_from()


func test_every_office_has_enough_reachable_desks() -> void:
	for level: int in range(1, data.max_office_level() + 1):
		var l: OfficeLayout = OfficeLayout.build(data.office_layouts["office_%d" % level])
		var capacity: int = int(data.office(level)["capacity"])
		assert_gte(l.desks.size(), capacity, "seviye %d: masa sayısı kapasiteyi karşılamalı" % level)
		assert_true(l.is_walkable(l.entrance), "seviye %d: giriş yürünebilir" % level)
		for d: Dictionary in l.desks:
			assert_false(l.path(l.entrance, d["seat"]).is_empty(), "seviye %d: masaya yol var %s" % [level, str(d["seat"])])
		for kind: String in ["kitchen", "meeting", "lounge"]:
			for p: Variant in l.spot_list(kind):
				assert_false(l.path(l.entrance, p).is_empty(), "seviye %d: %s noktasına yol var" % [level, kind])


func test_closed_rooms_are_entered_through_their_door() -> void:
	var l: OfficeLayout = OfficeLayout.build(data.office_layouts["office_2"])
	var meeting: Rect2 = l.room_rect("meeting")
	var path: PackedVector2Array = l.path(l.entrance, meeting.get_center() + Vector2(0, -1.8))
	assert_false(path.is_empty())
	var door_x: float = meeting.position.x
	var crossed: bool = false
	for i: int in range(1, path.size()):
		if (path[i - 1].x < door_x) != (path[i].x < door_x):
			crossed = true
			assert_between(path[i].y, meeting.get_center().y - 1.0, meeting.get_center().y + 1.0, "batı kapısından girer")
	assert_true(crossed)


func test_world_places_people_by_sim_state() -> void:
	GameState.new_game(12)
	var view: OfficeView = OfficeView.new()
	add_child_autofree(view)
	await wait_physics_frames(2)
	var s: SimState = GameState.sim.state
	var world: OfficeWorld = view.world
	assert_eq(world.get("_chars").size(), s.staff.size(), "her çalışana bir kapsül")
	var founder: Dictionary = s.founder()
	founder["busy_until"] = s.clock.week_index + 2
	world.sync()
	assert_false((world.get("_chars")[founder["id"]] as OfficeCharacter).visible, "izindeki çalışan ofiste görünmez")
	founder["busy_until"] = -1
	founder["energy"] = 5.0
	world.sync()
	assert_true(str(world.get("_place_of")[founder["id"]]).begins_with("kitchen"), "yorgun çalışan mutfağa gider")
	s.office_level = 2
	world.sync()
	assert_eq(world.layout.desks.size(), OfficeLayout.build(data.office_layouts["office_2"]).desks.size(), "taşınınca yeni bina")
	GameState.end_game()
