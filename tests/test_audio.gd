extends GutTest
## M9-B: ses kanalları, yer tutucu sesler, dönemsel bildirim sesi, müzik listesi, ortam sesi, juice.


func after_each() -> void:
	GameState.end_game()


func test_buses_exist_and_volume_settings_reach_them() -> void:
	for bus: String in ["Music", "SFX", "Ambient"]:
		assert_gt(AudioServer.get_bus_index(bus), 0, bus)
	Settings.persist = false
	Settings.set_value("volume_music", 0.5)
	assert_almost_eq(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")), linear_to_db(0.5), 0.01)
	Settings.load_from_disk()
	Settings.apply_all()
	Settings.persist = true


func test_every_sound_is_generated_without_files() -> void:
	for name: String in DataDB.data.sounds["sfx"]:
		assert_false(Audio.has_file(name), "%s için henüz dosya yok" % name)
		var s: AudioStream = Audio.stream_of(name)
		assert_true(s is AudioStreamWAV, name)
		assert_gt(s.get_length(), 0.01, name)
	var wav: AudioStreamWAV = Audio.stream_of("ambient_typing")
	assert_eq(wav.loop_mode, AudioStreamWAV.LOOP_FORWARD, "ortam sesi döngüde")


func test_synth_is_deterministic_and_respects_gaps() -> void:
	var segs: Array = [{"wave": "square", "f0": 1000, "dur": 0.1, "vol": 0.5}, {"gap": 0.1}]
	var a: AudioStreamWAV = SfxSynth.build(segs, 22050, 7)
	var b: AudioStreamWAV = SfxSynth.build(segs, 22050, 7)
	assert_eq(a.data, b.data)
	assert_almost_eq(a.get_length(), 0.2, 0.002)
	assert_eq(a.data.decode_s16(a.data.size() - 2), 0, "boşluk sessiz")


func test_notification_sound_follows_the_era() -> void:
	assert_eq(Audio.resolve("notify", 1992), "notify_pager", "90'lar: çağrı cihazı")
	assert_eq(Audio.resolve("notify", 2003), "notify_sms")
	assert_eq(Audio.resolve("notify", 2015), "notify_ding")
	assert_eq(Audio.resolve("brief", 1995), "fax")
	assert_eq(Audio.resolve("brief", 2005), "mail")
	assert_eq(Audio.resolve("money", 2005), "money")
	EventBus.notification.emit("NOTE_NEW_BRIEFS", [1], "info")
	assert_eq(Audio.history.back(), "fax", "oyun yokken başlangıç yılı (1990)")
	EventBus.notification.emit("NOTE_CLIENT_LOST", ["X"], "bad")
	assert_eq(Audio.history.back(), "bad")


func test_music_and_ambient() -> void:
	assert_eq(Audio.tracks_for("classic"), [] as Array[String], "müzik dosyası yokken liste boş, çökmez")
	assert_eq(Audio.ambient_level(), 0.0, "oyun yokken ortam sesi yok")
	GameState.new_game(5)
	assert_gt(Audio.ambient_level(), 0.0, "ofiste biri varken hafif uğultu")
	assert_lt(Audio.ambient_level(), 0.2, "tek kişi, oyun durmuş: çok kısık")


func test_juice_cash_fly_and_confetti() -> void:
	var holder: Control = Control.new()
	holder.size = Vector2(400, 300)
	add_child_autofree(holder)
	var anchor: Label = Label.new()
	holder.add_child(anchor)
	Juice.cash_fly(anchor, 10.0, 1990)
	assert_eq(anchor.get_child_count(), 0, "küçük değişim gösterilmez")
	Juice.cash_fly(anchor, 50000.0, 1990)
	assert_eq(anchor.get_child_count(), 1)
	assert_eq(Audio.history.back(), "money")
	var p: CPUParticles2D = Juice.confetti(holder)
	assert_true(p.emitting)
	assert_eq(p.amount, int(DataDB.data.sounds["juice"]["confetti_count"]))
