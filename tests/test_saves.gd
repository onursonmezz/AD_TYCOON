extends GutTest
## M9-A: kayıt slotları, otomatik kayıt, sürüm göçü (v2 → v3), ayarlar.

var data: GameData
var _dir_before: String


func before_all() -> void:
	data = GameData.load_from()


func before_each() -> void:
	_dir_before = SaveSystem.dir
	SaveSystem.dir = "user://test_saves_%d/" % randi()
	DirAccess.make_dir_recursive_absolute(SaveSystem.dir)
	Settings.persist = false
	GameState.autosave_needs_clock = false


func after_each() -> void:
	for f: String in DirAccess.get_files_at(SaveSystem.dir):
		DirAccess.remove_absolute(SaveSystem.dir.path_join(f))
	DirAccess.remove_absolute(SaveSystem.dir)
	SaveSystem.dir = _dir_before
	Settings.persist = true
	GameState.autosave_needs_clock = true
	Settings.load_from_disk()
	GameState.end_game()


func test_slots_save_load_and_show_summary() -> void:
	assert_false(SaveSystem.has_save(), "boş klasörde kayıt yok")
	GameState.new_game(12, "", 0, "Mavi Fil")
	GameState.sim.pause_on_phase = false
	for i: int in 10:
		GameState.sim.step_week()
	assert_eq(GameState.first_free_slot(), "slot_1")
	assert_true(GameState.save_game("slot_2"))
	assert_eq(GameState.current_slot, "slot_2")
	assert_false(GameState.dirty)
	var meta: Dictionary = SaveSystem.slot_meta("slot_2")
	assert_eq(meta["agency"], "Mavi Fil")
	assert_eq(int(meta["week_index"]), 10)
	assert_true(SaveLoadDialog.summary(meta).begins_with("Mavi Fil"))
	assert_eq(SaveLoadDialog.summary({}), tr("UI_SLOT_EMPTY"))
	var cash: float = GameState.sim.state.cash
	GameState.end_game()
	assert_true(GameState.load_game(), "boş slot adı: en son kayıt")
	assert_eq(GameState.current_slot, "slot_2")
	assert_almost_eq(GameState.sim.state.cash, cash, 0.01)
	assert_eq(GameState.sim.state.agency_name, "Mavi Fil")


func test_autosave_every_month_without_touching_manual_slot() -> void:
	GameState.new_game(13)
	GameState.sim.pause_on_phase = false
	Settings.set_value("autosave", true)
	for i: int in GameState.sim.state.clock.days_per_week * GameState.sim.state.clock.weeks_per_month + 1:
		GameState.step_day()
	assert_true(SaveSystem.has_save(SaveSystem.AUTO), "ay dönünce otomatik kayıt")
	assert_eq(GameState.current_slot, "", "elle kayıt slotu seçilmedi")
	assert_true(GameState.dirty, "otomatik kayıt 'kaydedildi' saymaz")
	assert_eq(SaveSystem.latest_slot(), SaveSystem.AUTO)
	assert_true(GameState.load_game(SaveSystem.AUTO))
	assert_eq(GameState.current_slot, "", "otomatik kayıttan yüklenince üstüne elle yazılmaz")


func test_autosave_can_be_turned_off() -> void:
	Settings.set_value("autosave", false)
	GameState.new_game(14)
	GameState.sim.pause_on_phase = false
	for i: int in GameState.sim.state.clock.days_per_week * GameState.sim.state.clock.weeks_per_month * 2:
		GameState.step_day()
	assert_false(SaveSystem.has_save(SaveSystem.AUTO))


func test_v2_save_migrates_and_corrupt_file_does_not_crash() -> void:
	var sim: Simulation = Simulation.new(data, 3)
	sim.state.agency_name = "Eski"
	var doc: Dictionary = JSON.parse_string(SaveCodec.encode(sim))
	doc.erase("meta")
	doc["save_version"] = 2
	var errors: Array[String] = []
	var loaded: Simulation = SaveCodec.decode(data, JSON.stringify(doc), errors)
	assert_eq(errors, [] as Array[String])
	assert_not_null(loaded)
	assert_eq(loaded.state.agency_name, "Eski")
	var f: FileAccess = FileAccess.open_compressed(SaveSystem.path_of("slot_3"), FileAccess.WRITE, FileAccess.COMPRESSION_GZIP)
	f.store_string("{bozuk")
	f.close()
	assert_true(bool(SaveSystem.slot_meta("slot_3").get("corrupt", false)))
	var errs: Array[String] = []
	assert_null(SaveSystem.load_game(data, "slot_3", errs))
	assert_has(errs, "ERR_SAVE_CORRUPT")
	assert_push_error("ERR_SAVE_CORRUPT")
	assert_engine_error_count(1)


func test_settings_apply_and_defaults() -> void:
	Settings.set_value("language", "en")
	assert_true(TranslationServer.get_locale().begins_with("en"))
	Settings.set_value("language", "tr")
	assert_true(TranslationServer.get_locale().begins_with("tr"))
	Settings.set_value("ui_scale", 1.15)
	assert_almost_eq(get_tree().root.content_scale_factor, 1.15, 0.001)
	Settings.reset()
	assert_almost_eq(get_tree().root.content_scale_factor, 1.0, 0.001)
	assert_eq(Settings.get_value("autosave"), true)
	Settings.mark_tutorial_seen("first_brief")
	assert_true(Settings.tutorial_seen("first_brief"))
