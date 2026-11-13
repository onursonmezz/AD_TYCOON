extends GutTest
## A1: kurucunun adı ve avatarı (yeni oyun sayfası); avatar listesi data/avatars.json, resimler assets/ui/avatars.


func before_each() -> void:
	Settings.persist = false
	Clock.playtime.persist = false


func test_every_avatar_has_picture_and_known_gender() -> void:
	var ids: Array = BackgroundDialog.avatar_ids()
	assert_gt(ids.size(), 3, "seçilecek avatarlar var")
	for rec: Dictionary in DataDB.data.raw["avatars.json"]:
		assert_true(ResourceLoader.exists(MenuArt.avatar_path(str(rec["id"]))), "%s resmi var" % rec["id"])
		assert_true(str(rec["gender"]) in ["female", "male", "neutral"], "%s cinsiyeti" % rec["id"])


func test_every_background_has_portrait() -> void:
	for id: String in DataDB.data.background_ids:
		assert_true(ResourceLoader.exists(MenuArt.portrait_path(id)), "%s portresi var" % id)


func test_new_game_sets_founder_profile() -> void:
	GameState.new_game(21, "copywriter", 0, "Mavi Fil", {"name": "  Defne  ", "avatar": "kadin_02"})
	var emp: Dictionary = GameState.sim.state.founder()
	assert_eq(str(emp["name"]), "Defne")
	assert_eq(str(emp["avatar"]), "kadin_02")
	assert_eq(str(emp["gender"]), "female")
	assert_eq(GameState.employee_name(emp), "Defne")


func test_founder_without_profile_is_you() -> void:
	GameState.new_game(22, "", 0, "", {"name": "", "avatar": "yok_boyle_biri"})
	var emp: Dictionary = GameState.sim.state.founder()
	assert_false(emp.has("avatar"), "bilinmeyen avatar yok sayılır")
	assert_eq(GameState.employee_name(emp), tr("UI_YOU"))


func test_founder_profile_survives_save_roundtrip() -> void:
	GameState.new_game(23, "", 0, "", {"name": "Defne", "avatar": "erkek_01"})
	var saved: String = SaveCodec.encode(GameState.sim)
	var again: Simulation = SaveCodec.decode(DataDB.data, saved)
	assert_eq(str(again.state.founder().get("avatar", "")), "erkek_01")
	assert_eq(str(again.state.founder()["name"]), "Defne")
