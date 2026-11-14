class_name MinigameHost
extends VBoxContainer
## Fazın başındaki mini oyunu kampanya penceresinin içinde oynatır (K-120): başlık ve tek cümlelik ipucu, oyun alanı,
## süre çubuğu ve "Atla". Bitince sonucu kısa bir süre gösterir, MinigameResultCommand ile kaydeder ve on_done çağırır.
## Oyun zamanı zaten faz başında beklediği için durur. Süre ve gösterim balance.json "minigames".


var _camp: Dictionary
var _phase: int
var _on_done: Callable
var _id: String
var _game: MinigameGame
var _bar: ProgressBar
var _result: Label
var _skip: Button
var _left: float
var _draft: Dictionary = {}
var _finished: bool = false


func _init(camp: Dictionary, phase: int, on_done: Callable) -> void:
	_camp = camp
	_phase = phase
	_on_done = on_done
	add_theme_constant_override("separation", CozyTheme.SPACE_S)


func _ready() -> void:
	var data: GameData = DataDB.data
	var setup: Dictionary = _camp["setup"]
	_id = Minigames.game_for(data, setup, _phase)
	var key: String = "MG_%s" % _id.to_upper()
	add_child(Cards.section(tr("UI_MG_TITLE") % tr(key + "_NAME"), "", "player-play"))
	add_child(UiUtil.wrapped(tr(key + "_HINT"), 13, CozyTheme.TEXT, 600.0))
	_game = _make(_id)
	_game.ctx = {"camp": _camp, "setup": setup, "brand": str(setup.get("client_name", "")),
		"accent": KeyVisual.spec(data, _camp)["accent"], "year": GameState.sim.state.clock.year(),
		"seed": absi(str(_camp.get("id", "")).hash())}
	_game.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_child(_game)
	_game.begin()
	_game.finished.connect(_on_finished)
	if _game is MgDraft:
		(_game as MgDraft).chosen.connect(func(d: Dictionary) -> void: _draft = d)
	var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(0, 8)
	_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_left = data.balf("minigames.duration")
	_bar.max_value = _left
	_bar.value = _left
	_bar.visible = _id != Minigames.DRAFT
	row.add_child(_bar)
	_result = UiUtil.label("", 15, CozyTheme.FOREST)
	_result.add_theme_font_override("font", CozyTheme.strong_font())
	row.add_child(_result)
	_skip = UiUtil.button(tr("MG_DRAFT_SKIP") if _id == Minigames.DRAFT else tr("UI_MG_SKIP"), func() -> void: _game.time_up())
	row.add_child(_skip)
	add_child(row)


static func _make(id: String) -> MinigameGame:
	match id:
		"radio_wave":
			return MgRadio.new()
		"billboard":
			return MgBillboard.new()
		"newspaper":
			return MgNewspaper.new()
	return MgDraft.new()


func _process(delta: float) -> void:
	if _finished or _id == Minigames.DRAFT:
		return
	_left -= delta
	_bar.value = maxf(0.0, _left)
	if _left <= 0.0:
		_game.time_up()


func _on_finished(quality: float) -> void:
	if _finished:
		return
	_finished = true
	_skip.disabled = true
	var data: GameData = DataDB.data
	if _id == Minigames.DRAFT:
		GameState.execute(MinigameResultCommand.new(_phase, 0.0, _draft))
		_result.text = tr("MG_DRAFT_DONE")
	else:
		GameState.execute(MinigameResultCommand.new(_phase, quality))
		var bonus: float = quality * data.balf("minigames.max_bonus") / data.balf("minigames.scoring_games") * 100.0
		var band: String = "GREAT" if quality >= 0.8 else ("OK" if quality >= 0.4 else "MISS")
		_result.text = tr("MG_RESULT_" + band) % ("%.1f" % bonus)
		_result.add_theme_color_override("font_color", CozyTheme.FOREST if quality >= 0.4 else CozyTheme.MUTED)
		if quality >= 0.8:
			_confetti()
		Audio.play("money" if quality >= 0.8 else "click")
	await get_tree().create_timer(data.balf("minigames.result_hold")).timeout
	if is_inside_tree():
		_on_done.call()


func _confetti() -> void:
	var t: Texture2D = DraftArt.tex("effects", "fx_confetti")
	if t == null:
		return
	var fx: TextureRect = DraftArt._image(t, Rect2(Vector2.ZERO, MinigameGame.CANVAS), TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	_game.add_child(fx)
	fx.modulate.a = 0.0
	create_tween().tween_property(fx, "modulate:a", 1.0, 0.25)
