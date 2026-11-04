extends GutTest
## M9-C: ipucu balonları (sıra, görülme, kapatma, kampanya sınırı) ve dile göre yüzde biçimi.

var screen: Control


func before_each() -> void:
	Settings.persist = false
	Settings.set_value("tutorial", true)
	Settings.set_value("tutorial_seen", [])
	GameState.new_game(9)
	screen = load("res://src/ui/screens/main.tscn").instantiate()
	add_child_autofree(screen)
	await wait_physics_frames(3)


func after_each() -> void:
	GameState.end_game()
	Settings.load_from_disk()
	Settings.apply_all()
	Settings.persist = true


func _tut() -> Tutorial:
	return screen.get("_tutorial")


func test_welcome_first_then_queue_in_order() -> void:
	var t: Tutorial = _tut()
	assert_eq(t.current_tip(), "welcome", "oyun açılınca hoş geldin balonu")
	assert_not_null(t.target_of("speed"), "duraklat düğmesini gösterir")
	EventBus.notification.emit("NOTE_NEW_BRIEFS", [1], "info")
	assert_eq(t.current_tip(), "welcome", "yeni ipucu sıraya girer, üstüne binmez")
	t.call("_close")
	assert_true(Settings.tutorial_seen("welcome"))
	assert_eq(t.current_tip(), "first_brief")
	t.call("_close")
	EventBus.notification.emit("NOTE_NEW_BRIEFS", [1], "info")
	assert_eq(t.current_tip(), "", "görülen ipucu tekrar çıkmaz")


func test_window_tips_and_turning_off() -> void:
	var t: Tutorial = _tut()
	t.call("_close")
	EventBus.ui_opened.emit("EventDialog")
	assert_eq(t.current_tip(), "event")
	Settings.set_value("tutorial", false)
	t.call("_close")
	EventBus.ui_opened.emit("WizardDialog")
	assert_eq(t.current_tip(), "", "ipuçları kapalıyken çıkmaz")


func test_early_tips_stop_after_first_campaigns() -> void:
	var t: Tutorial = _tut()
	t.call("_close")
	for i: int in int(DataDB.data.raw["tutorial.json"]["max_campaigns"]):
		GameState.sim.state.history.append({"campaign": "c%d" % i})
	EventBus.ui_opened.emit("WizardDialog")
	assert_eq(t.current_tip(), "", "ilk kampanyalardan sonra sihirbaz ipucu yok")
	EventBus.ui_opened.emit("EventDialog")
	assert_eq(t.current_tip(), "event", "her zaman geçerli ipucu yine çıkar")


func test_every_tip_has_text_and_target() -> void:
	var t: Tutorial = _tut()
	for tip: Dictionary in DataDB.data.raw["tutorial.json"]["tips"]:
		var key: String = "TIP_" + str(tip["id"]).to_upper()
		assert_ne(tr(key), key, key)
		if not str(tip["target"]).is_empty():
			assert_not_null(t.target_of(str(tip["target"])), str(tip["target"]))


func test_percent_follows_language() -> void:
	TranslationServer.set_locale("tr")
	assert_eq(UiUtil.percent(55.0), "%55")
	assert_eq(UiUtil.percent(-12.0), "-%12")
	assert_eq(UiUtil.percent(0.3, 1, true), "+%0.3")
	TranslationServer.set_locale("en")
	assert_eq(UiUtil.percent(55.0), "55%")
	assert_eq(UiUtil.percent(0.3, 1, true), "+0.3%")
	TranslationServer.set_locale("tr")
