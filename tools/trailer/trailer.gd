extends Node
## Steam tanıtım videosu (fragman) yönetmeni: sabit tohumlu bir oyunu oynatır, kamerayı yönetir, pencereleri açar;
## arada kâğıt etiketli yazı kartları. Görüntüler tamamen oyunun içinden (Godot Movie Maker ile kare kare kayıt).
## Kayıt (1080p, 30 fps):
##   godot --path . --write-movie marketing/trailer/raw/trailer.avi --fixed-fps 30 --resolution 1920x1080
##         res://tools/trailer/trailer.tscn
## Deneme (kayıtsız, pencerede): godot --path . res://tools/trailer/trailer.tscn --resolution 1920x1080
##   -- --stills=<klasör>  her sahnenin anahtar karesini PNG kaydeder (Steam ekran görüntüleri de buradan)
##   -- --only=garage,growth  yalnızca bu sahneler (açılış ve kapanış hep çalışır)
##   -- --no-cards  yazı kartları olmadan (Steam ekran görüntüleri için; --fullscreen ile 1920×1080)
## Tam kayıt için kısayol: tools/trailer/record.bat (kayıt süresince override.cfg ile pencere 1920×1080).

const SEED: int = 11
const FOUNDER: Dictionary = {"name": "Defne", "avatar": "kadin_02"}
const SCENES: Array[String] = ["intro", "garage", "brief", "montage", "echo", "growth", "awards", "billboard", "outro"]
const CARD_HOLD: float = 3.2
## Kanal provalarından kurgu: billboard (araba geçer), TV kurgusu (sahne sırası), sosyal akış (kayan telefon).
const MONTAGE_CHANNELS: Array[String] = ["billboard", "national_tv", "youtup_video"]

var _overlay: TrailerOverlay
var _screen: Control
var _stills: String = ""
var _only: PackedStringArray = PackedStringArray()
var _shot_count: int = 0
var _no_cards: bool = false  # Steam ekran görüntüleri: yazı kartları olmadan


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--stills="):
			_stills = arg.trim_prefix("--stills=")
			DirAccess.make_dir_recursive_absolute(_stills)
		elif arg == "--no-cards":
			_no_cards = true
		elif arg.begins_with("--only="):
			_only = arg.trim_prefix("--only=").split(",")
	Settings.persist = false
	Clock.playtime.persist = false
	Settings.set_value("tutorial", false)
	Settings.set_value("autosave", false)
	Settings.set_value("minigames", false)  # provaları fragman kendisi açar (zamanlama elde olsun)
	AudioServer.set_bus_mute(0, true)  # müzik sonradan kurguda eklenir (yer tutucu sesler duyulmasın)
	TranslationServer.set_locale("tr")
	_overlay = TrailerOverlay.new()
	_overlay.cards_enabled = not _no_cards
	add_child(_overlay)
	_run.call_deferred()


func _wants(scene: String) -> bool:
	return _only.is_empty() or _only.has(scene) or scene == "intro" or scene == "outro"


func _run() -> void:
	await _intro()
	await _start_game()
	for scene: String in SCENES.slice(1, SCENES.size() - 1):
		if _wants(scene):
			await call("_" + scene)
	await _outro()
	get_tree().quit()


# --- sahneler --------------------------------------------------------------------------

## 0–5 sn: menü illüstrasyonu üstünde logo ve alt başlık.
func _intro() -> void:
	_overlay.title_card([tr("BOOT_SUBTITLE")])
	await _overlay.fade(0.0, 0.8)
	await _wait(2.6)
	await _snap("intro")
	await _overlay.fade(1.0, 0.6)
	_overlay.clear_title()


func _start_game() -> void:
	GameState.new_game(SEED, "marketing_manager", 1990, tr("TRAILER_AGENCY"), FOUNDER)
	_screen = load("res://src/ui/screens/main.tscn").instantiate()
	add_child(_screen)
	move_child(_overlay, get_child_count() - 1)
	(_screen.get("_hint") as Control).modulate.a = 0.0
	(_screen.get("_feed") as Control).modulate.a = 0.0  # sağ üst bildirimler kurguyu kirletmesin
	(DataDB.data.sounds["juice"] as Dictionary)["cash_fly_min_1990"] = 1.0e12  # para uçuşu da (yalnızca bu çalışmada)
	# Gelen kutusuna ilk brief düşene kadar saati kapalı ilerlet (ekranda görünmez, karartma altında).
	Clock.set_paused(true)
	var sim: Simulation = GameState.sim
	while sim.state.inbox.is_empty():
		_step()
	await _wait(0.5)


## 5–12 sn: garaj ofisi; kurucu masasında, kamera yavaşça yaklaşır ve hafifçe döner.
func _garage() -> void:
	var rig: CameraRig = _rig()
	await _wait(0.1)  # dünya ilk kurulumda kamerayı ortalar; hedefi ondan sonra ver
	_focus_staff(1.0, -0.6)  # kurucu ekranın ortasında (masa odanın kuzey duvarında, çubuğun altında kalmasın)
	rig.set("_target_distance", float(rig.get("_target_distance")) * 1.35)
	rig.set("_distance", rig.get("_target_distance"))
	Clock.set_speed(0)
	Clock.set_paused(false)
	_dolly(0.62, 7.0, 18.0)
	await _overlay.fade(0.0, 0.7)
	_overlay.card(tr("TRAILER_GARAGE"), CARD_HOLD)
	await _wait(3.4)
	await _snap("garage")
	await _wait(2.6)


## 12–24 sn: gelen kutusu, kampanya sihirbazı (ad yazılır), başlat; stratejinin provası.
func _brief() -> void:
	Clock.set_paused(true)
	var sim: Simulation = GameState.sim
	while sim.state.inbox.is_empty():  # garaj sahnesinde saat aktı; brief'in süresi dolmuş olabilir
		_step()
	_screen.call("show_panel", "inbox")
	_overlay.card(tr("TRAILER_BRIEF"), CARD_HOLD + 1.0)
	await _wait(1.6)
	var wizard: WizardDialog = WizardDialog.new(sim.state.inbox[0], _screen)
	_screen.call("open_modal", wizard)
	await _wait(0.8)
	var name_edit: LineEdit = wizard.get("_name_edit")
	for ch: String in tr("TRAILER_CAMPAIGN_NAME"):
		name_edit.text += ch
		await _wait(0.06)
	await _wait(0.6)
	await _snap("wizard")
	await _wait(0.6)
	wizard.call("_on_start")
	while not GameState.is_waiting():  # faz başına kadar ilerle: kampanya penceresinde emek dağılımı panosu
		_step()
	_close_modals()
	await _wait(0.3)
	_screen.call("show_panel", "campaign")
	# Faz başının provası (strateji): gerçek oyundaki gibi pencere açılır, oynanır, sonuç gösterilir.
	var camp: Dictionary = sim.state.active_campaign
	await _play_minigame(camp, 0, 2.4, 1.0)
	await _wait(1.6)
	await _snap("work_board")


## 24–34 sn: kanal provalarından hızlı kurgu (billboard, TV kurgusu, sosyal akış) ve ekibin üç taslağı.
func _montage() -> void:
	_overlay.card(tr("TRAILER_MINIGAMES"), CARD_HOLD + 2.0)
	var camp: Dictionary = GameState.sim.state.active_campaign
	for channel: String in MONTAGE_CHANNELS:
		var fake: Dictionary = camp.duplicate(true)
		(fake["setup"] as Dictionary)["mix"] = [{"channel": channel, "share": 1.0}]
		await _play_minigame(fake, 1, 1.7, 0.95, "montage_" + channel)
	# Taslak seçimi gerçek kampanyaya yazılır: billboard ve ofis posterinde bu görünür.
	var host_dialog: MinigameDialog = MinigameDialog.new(camp, 2)
	_screen.call("open_modal", host_dialog)
	await _wait(1.4)
	await _snap("draft")
	var game: MgDraft = _game() as MgDraft
	if game != null:
		game.call("_pick", 1)
	await _wait(1.3)


## 34–42 sn: kampanya biter, yankılar: dergi puanları ve yorumlar.
func _echo() -> void:
	var sim: Simulation = GameState.sim
	_close_modals()
	var before: int = sim.state.finished.size()
	GameState.set_phase_sliders([0.4, 0.4, 0.2])
	while sim.state.finished.size() == before:
		if GameState.is_waiting():
			GameState.set_phase_sliders([0.4, 0.4, 0.2])
		_step()
	await _wait(0.2)
	_close_modals()
	# Fragmanda iyi bir iş göstermek için puan ve yorumlar yüksek bantta yeniden yazılır (yalnızca görüntü).
	var camp: Dictionary = sim.state.finished[sim.state.finished.size() - 1]
	(camp["report"] as Dictionary)["score"] = 8.6
	camp["reviews"] = sim.reports.reviews(8.6, sim.state.rng.stream("trailer"))
	_screen.call("close_panel")
	_overlay.card(tr("TRAILER_ECHO"), CARD_HOLD)
	_screen.call("open_modal", EchoDialog.new(camp, func() -> void: pass))
	await _wait(2.6)
	await _snap("echo")
	await _wait(2.2)


## 42–54 sn: dönem geçişi, büyüyen ofis ve kalabalık ekip; inşa modunda eşya yerleştirme.
func _growth() -> void:
	var sim: Simulation = GameState.sim
	_close_modals()
	_screen.call("close_panel")
	sim.state.clock.week_index = (2011 - 1990) * sim.state.clock.weeks_per_year()
	_screen.call("open_modal", EraDialog.new("mobile"))
	_overlay.card(tr("TRAILER_GROWTH"), CARD_HOLD + 4.0)
	await _wait(2.2)
	await _snap("era")
	await _overlay.fade(1.0, 0.35)
	_close_modals()
	_grow_agency(sim)
	Clock.set_speed(2)
	Clock.set_paused(false)  # karanlıkta hızlı akar: yeni çalışanlar masalarına yürüyüp otursun
	await _wait(4.0)
	Clock.set_paused(true)
	var rig: CameraRig = _rig()
	_focus_staff(0.55)
	rig.set("_distance", float(rig.get("_target_distance")) * 1.0)
	rig.set("_target_distance", rig.get("_distance"))
	Clock.set_speed(0)
	Clock.set_paused(false)
	_dolly(0.62, 6.5, -20.0)
	await _overlay.fade(0.0, 0.5)
	await _wait(2.6)
	await _snap("office_big")
	# İnşa modu: bitki ve kitaplık önizlemesi, yerleştirme.
	_screen.call("enter_build_mode")
	var view: OfficeView = _screen.get("_office")
	var bar: BuildToolbar = _screen.get("_build_bar")
	await _wait(0.4)
	for id: String in ["plant_big", "bookshelf"]:
		bar.call("_select", {"kind": "furniture", "id": id, "rot": 0})
		for k: int in 6:
			view.call("_build_hover", view.size * Vector2(0.42 + 0.03 * k, 0.48))
			await _wait(0.12)
		await _snap("build_" + id)
	_screen.call("exit_build_mode")
	await _wait(0.4)


## 54–60 sn: ödül töreni (Altın Elma).
func _awards() -> void:
	var sim: Simulation = GameState.sim
	Clock.set_paused(true)
	var camp: Dictionary = sim.state.finished[sim.state.finished.size() - 1] if not sim.state.finished.is_empty() else {}
	var fake: Dictionary = {"award": "golden_apple", "year": sim.state.clock.year(), "rivals": [{"rival": "mavi_ok", "level": "silver"}],
		"player": [{"name": tr("TRAILER_CAMPAIGN_NAME"), "client_name": str(camp.get("setup", {}).get("client_name", "")),
			"level": "gold"}], "grand_prix": {"who": "player", "campaign": tr("TRAILER_CAMPAIGN_NAME")}}
	_overlay.card(tr("TRAILER_AWARDS"), CARD_HOLD)
	_screen.call("open_modal", CeremonyDialog.new(fake))
	await _wait(3.6)
	await _snap("ceremony")
	await _wait(1.8)
	await _overlay.fade(1.0, 0.35)
	_close_modals()


## 60–66 sn: sokaktaki billboard'da oyuncunun seçtiği taslak.
func _billboard() -> void:
	var view: OfficeView = _screen.get("_office")
	var rig: CameraRig = view.world.rig
	var bb: Transform3D = view.world.get("_dressing").get("_billboard_anchor")
	var out: Vector2 = OfficeDressing.OUTWARD[OfficeOutdoor.entrance_side(view.world.layout)]
	# Hedef ilanın biraz arkasında: panel yüksek olduğu için ekranın üstüne, çubuğun altına kaçmasın.
	var target: Vector3 = Vector3(bb.origin.x - out.x * 1.6, 0.0, bb.origin.z - out.y * 1.6)
	rig.set("_target_pos", target)
	rig.position = target
	_face_street(rig, view.world.layout)  # ilanın yüzü kameraya dönük (önceki sahnelerin dönüşünden bağımsız)
	rig.set("_distance", 17.0)
	rig.set("_target_distance", 17.0)
	Clock.set_paused(false)
	await _overlay.fade(0.0, 0.4)
	_overlay.card(tr("TRAILER_BILLBOARD"), CARD_HOLD)
	var t: Tween = create_tween()
	t.tween_property(rig, "_target_distance", 12.0, 4.8).set_trans(Tween.TRANS_SINE)
	await _wait(3.0)
	await _snap("billboard")
	await _wait(1.9)
	await _overlay.fade(1.0, 0.6)


## 66–71 sn: kapanış: logo, "Steam'de istek listene ekle".
func _outro() -> void:
	if _screen != null:
		_screen.queue_free()
	_overlay.title_card([tr("BOOT_SUBTITLE"), tr("TRAILER_WISHLIST")])
	await _overlay.fade(0.0, 0.6)
	await _wait(1.6)
	await _snap("outro")
	await _wait(2.6)


# --- yardımcılar ----------------------------------------------------------------------

## Mini oyun penceresini açar, `play` saniye oynatır, `quality` ile bitirir, sonuç gösterilip kapanana dek bekler.
func _play_minigame(camp: Dictionary, phase: int, play: float, quality: float, still: String = "") -> void:
	var dialog: MinigameDialog = MinigameDialog.new(camp, phase)
	_screen.call("open_modal", dialog)
	await _wait(play)
	if not still.is_empty():
		await _snap(still)
	var game: MinigameGame = _game()
	if game != null:
		game.finish(quality)
	await _wait(DataDB.data.balf("minigames.result_hold") + 0.3)
	if is_instance_valid(dialog):
		dialog.queue_free()
	await _wait(0.1)


func _game() -> MinigameGame:
	var hosts: Array[Node] = get_tree().root.find_children("*", "MinigameHost", true, false)
	return null if hosts.is_empty() else (hosts[0] as MinigameHost).get("_game") as MinigameGame


## Ajansı 2011'e büyütür: plaza öncesi büyük ofis, kalabalık ekip, beyin fırtınası odası, eşyalar, bilgisayar.
func _grow_agency(sim: Simulation) -> void:
	sim.state.office_level = 3
	sim.state.cash = 6000000.0
	sim.state.reputation = 46.0
	sim.state.hardware = "imak"
	for role: String in ["art_director", "copywriter", "planner", "producer", "account", "graphic_designer", "media_planner",
			"copywriter", "art_director"]:
		var found: Array[Dictionary] = SearchCandidatesCommand.new(role, "job_ad", "tr").execute(sim)
		if not found.is_empty():
			HireEmployeeCommand.new(found[0]["id"]).execute(sim)
	var l: OfficeLayout = sim.build.layout(sim.state)
	for room: Dictionary in l.rooms:
		if room["type"] == "empty":
			var r: Rect2 = room["rect"]
			GameState.execute(BuildRoomCommand.new("brainstorm", Rect2(r.position + Vector2(1, 1), Vector2(5, 3))))
			break
	var placed: int = 0
	for id: String in ["plant_big", "office_cat", "record_player", "plant_small", "whiteboard", "water_cooler", "neon_sign"]:
		for x: int in range(2, 40):
			var p: Vector2 = Vector2(x * 0.5, 7.5 if placed % 2 == 0 else 0.5)
			if sim.build.place_error(sim.state, id, p, 0).is_empty():
				GameState.execute(PlaceFurnitureCommand.new(id, p, 0))
				placed += 1
				break
	GameState.execute(SetDeskTierCommand.new("ergonomic"))
	EventBus.state_changed.emit()


## Kamera hedefini çalışanların ortalamasına doğru kaydırır (weight: 0 bina ortası, 1 tam çalışanlar).
func _focus_staff(weight: float, south: float = 1.0) -> void:
	var rig: CameraRig = _rig()
	var world: OfficeWorld = (_screen.get("_office") as OfficeView).world
	# Anlık konum değil oturacakları masa: yeni gelenler henüz kapıdan yürüyor olabilir.
	var desk_of: Dictionary = world.call("allocate_desks", world.get("_desk_of"), GameState.sim.state.staff.keys(),
		world.layout.desks.size())
	if desk_of.is_empty():
		return
	var sum: Vector3 = Vector3.ZERO
	for id: Variant in desk_of:
		var seat: Vector2 = world.layout.desks[int(desk_of[id])]["seat"]
		sum += Vector3(seat.x, 0.0, seat.y + south)  # south: üst çubuk masaların üstünü örtmesin
	var avg: Vector3 = sum / float(desk_of.size())
	var target: Vector3 = (rig.get("_target_pos") as Vector3).lerp(avg, weight)
	rig.set("_target_pos", target)
	rig.position = target


## Kamerayı sokak tarafına alır: dört çeyrekten bakış yönü binanın ön yüzüne (girişin dışına) en yakın olanı.
func _face_street(rig: CameraRig, layout: OfficeLayout) -> void:
	var out: Vector2 = OfficeDressing.OUTWARD[OfficeOutdoor.entrance_side(layout)]
	var best: int = 0
	var best_dot: float = -2.0
	for q: int in 4:
		var yaw: float = deg_to_rad(45.0 + 90.0 * q)
		var d: float = Vector2(sin(yaw), cos(yaw)).dot(out)
		if d > best_dot:
			best_dot = d
			best = q
	rig.quarter = best
	(rig.get("_yaw_node") as Node3D).rotation_degrees.y = 45.0 + 90.0 * best
	rig.yaw_changed.emit(45.0 + 90.0 * best)


func _rig() -> CameraRig:
	return (_screen.get("_office") as OfficeView).world.rig


## Kamera yolculuğu: uzaklık `ratio` katına iner, `yaw_deg` kadar döner; `seconds` boyunca yumuşak.
func _dolly(ratio: float, seconds: float, yaw_deg: float) -> void:
	var rig: CameraRig = _rig()
	var t: Tween = create_tween().set_parallel(true)
	t.tween_property(rig, "_target_distance", float(rig.get("_target_distance")) * ratio, seconds).set_trans(Tween.TRANS_SINE)
	var yaw_node: Node3D = rig.get("_yaw_node")
	t.tween_property(yaw_node, "rotation_degrees:y", yaw_node.rotation_degrees.y + yaw_deg, seconds).set_trans(Tween.TRANS_SINE)


func _close_modals() -> void:
	for c: Node in (_screen.get("_modal_layer") as Control).get_children():
		c.queue_free()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


## --stills verildiyse anahtar kareyi PNG kaydeder (Steam ekran görüntüleri ve kontrol için).
func _snap(name: String) -> void:
	if _stills.is_empty():
		return
	await RenderingServer.frame_post_draw
	_shot_count += 1
	get_viewport().get_texture().get_image().save_png(_stills.path_join("%02d_%s.png" % [_shot_count, name]))


## Bir gün ilerletir; araya giren olaylar ilk seçenekle cevaplanır.
func _step() -> void:
	var sim: Simulation = GameState.sim
	while not EventSystem.pending(sim.state).is_empty():
		var inst: Dictionary = EventSystem.pending(sim.state)
		sim.events.resolve(sim, inst["uid"], int(inst["options"][0]))
	GameState.step_day()
