class_name PitchDialog
extends Control
## Sunum mini oyunu (GDD 14.2): ipucu kartları, 3 tur (açılış → fikir → kapanış), her seçimde müşteri tepkisi,
## sonunda rakiplerle birlikte sonuç. Tepkiler simülasyondan salt-okunur hesaplanır; sonuç tek komutla gelir.
## UI-4: diğer pencerelerin dili: üstte bilgi şeridi, bölüm bantları, ipuçları etiket, turlar seçim kartı,
## sonuçta bizim çubuğumuz kiremit, kazananınki yeşil.

const FACES: Dictionary = {"good": "😊", "neutral": "😐", "bad": "😠"}
const LEVEL_HIGH: float = 0.33
const ROUND_ICONS: Dictionary = {"opening": "speakerphone", "idea": "star", "closing": "check"}

var _picked: Array = []
var _round_box: VBoxContainer
var _reactions: HBoxContainer
var _title: Label


func _ready() -> void:
	var sim: Simulation = GameState.sim
	var pitch: Dictionary = sim.state.pitch
	var col: VBoxContainer = UiUtil.modal_frame(self, Vector2(760.0, 560.0))
	col.add_child(UiUtil.heading(tr("UI_PITCH_TITLE") % pitch["client"]["name"], "speakerphone"))
	var presenter: Dictionary = sim.pitches.presenter(sim.state, pitch)
	var strip: PanelContainer = UiUtil.card()
	strip.add_child(Cards.facts([
		Cards.fact("stat-strategy", tr("STAT_STRATEGY_NAME"), str(int(pitch["s"]))),
		Cards.fact("stat-creative", tr("STAT_CREATIVE_NAME"), str(int(pitch["k"]))),
		Cards.fact("user", tr("UI_PITCH_PRESENTER"), "%s · %s %d" % [GameState.employee_name(presenter),
			tr("STAT_COMMUNICATION_NAME"), int(presenter.get("stats", {}).get("communication", 0))])]))
	col.add_child(strip)
	col.add_child(Cards.section(tr("UI_PITCH_HINTS"), "", "info"))
	var hints: HFlowContainer = Cards.flow_row(CozyTheme.SPACE_S)
	for key: String in sim.pitches.hints(pitch):
		var v: float = float(pitch["prefs"][key])
		var level: String = "HIGH" if v >= LEVEL_HIGH else ("LOW" if v <= -LEVEL_HIGH else "MID")
		hints.add_child(Cards.chip(tr("PREF_" + key.to_upper()) + ": " + tr("PREF_LEVEL_" + level), CozyTheme.CREAM_LIGHT,
			CozyTheme.FOREST))
	col.add_child(hints)
	_reactions = UiUtil.hbox(CozyTheme.SPACE_M)
	col.add_child(_reactions)
	var title_band: PanelContainer = Cards.section("")
	_title = (title_band.get_child(0) as HBoxContainer).get_child(0) as Label
	col.add_child(title_band)
	_round_box = UiUtil.vbox(CozyTheme.SPACE_S)
	col.add_child(_round_box)
	_show_round()


func _show_round() -> void:
	UiUtil.clear(_round_box)
	var rnd: int = _picked.size()
	if rnd >= PitchSystem.ROUNDS.size():
		_finish()
		return
	var round_name: String = PitchSystem.ROUNDS[rnd]
	_title.text = tr("UI_PITCH_ROUND") % [rnd + 1, tr("ROUND_" + round_name.to_upper())]
	var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
	for id: String in GameState.sim.pitches.cards_of_round(round_name):
		var card: PanelContainer = Cards.choice(str(ROUND_ICONS.get(round_name, "star")),
			UiUtil.name_of(DataDB.data.pitch_cards, id), tr(DataDB.data.pitch_cards[id]["desc_key"]), tr("UI_PITCH_PLAY"),
			func() -> void: _play(id))
		card.custom_minimum_size.x = 200.0
		row.add_child(card)
	_round_box.add_child(row)


func _play(card_id: String) -> void:
	var sim: Simulation = GameState.sim
	var face: String = FACES[sim.pitches.reaction(sim.pitches.card_fit(sim.state.pitch, card_id))]
	# Tepki: küçük kart, solda yüz, sağda oynanan kartın adı.
	var chip: PanelContainer = UiUtil.card()
	var box: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	chip.add_child(box)
	box.add_child(UiUtil.label(face, 26))
	var played: Label = UiUtil.label(UiUtil.name_of(DataDB.data.pitch_cards, card_id), 13, CozyTheme.TEXT)
	played.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(played)
	_reactions.add_child(chip)
	_picked.append(card_id)
	_show_round()


func _finish() -> void:
	var result: Dictionary = GameState.execute(PresentPitchCommand.new(_picked))
	if not bool(result.get("ok", false)):
		queue_free()
		return
	var won: bool = bool(result["won"])
	_title.text = tr("UI_PITCH_WON") % result["client_name"] if won else tr("UI_PITCH_LOST") % [
		UiUtil.name_of(DataDB.data.rivals, result["winner"]), int(result["rank"])]
	_title.add_theme_color_override("font_color", CozyTheme.FOREST if won else CozyTheme.TERRA)
	if not won and int(result["rank"]) <= 2:
		_round_box.add_child(UiUtil.wrapped(tr("UI_PITCH_SHORTLIST"), 14, UiUtil.WOOD, 680.0))
	var top: float = 0.0001
	for s: Dictionary in result["scores"]:
		top = maxf(top, float(s["score"]))
	var board: PanelContainer = UiUtil.card()
	var rows: VBoxContainer = UiUtil.vbox(CozyTheme.SPACE_S)
	board.add_child(rows)
	for i: int in (result["scores"] as Array).size():
		var s: Dictionary = result["scores"][i]
		var us: bool = s["who"] == "player"
		var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
		var who: String = tr("UI_US") if us else UiUtil.name_of(DataDB.data.rivals, s["who"])
		var name_label: Label = UiUtil.label("%d. %s" % [i + 1, who], 14, CozyTheme.TERRA if us else CozyTheme.TEXT)
		name_label.add_theme_font_override("font", CozyTheme.strong_font(760 if us else 500))
		name_label.custom_minimum_size.x = 200.0
		row.add_child(name_label)
		var bar: ProgressBar = ProgressBar.new()
		bar.custom_minimum_size = Vector2(0.0, 14.0)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.show_percentage = false
		bar.value = 100.0 * float(s["score"]) / top
		var fill: Color = CozyTheme.TERRA if us else (CozyTheme.FOREST_LIGHT if i == 0 else CozyTheme.SAGE)
		bar.add_theme_stylebox_override("fill", CozyTheme.box(fill, 7, Color.TRANSPARENT, 0, false, Vector2.ZERO))
		row.add_child(bar)
		rows.add_child(row)
	_round_box.add_child(board)
	var buttons: HBoxContainer = UiUtil.hbox()
	buttons.add_child(UiUtil.label(tr("UI_PITCH_CHANCE") % int(roundf(100.0 * float(result["p_win"]))), 13, UiUtil.MUTED))
	buttons.add_child(UiUtil.spacer())
	var close: Button = UiUtil.button(tr("UI_CLOSE"), queue_free)
	close.theme_type_variation = "PrimaryButton"
	buttons.add_child(close)
	_round_box.add_child(buttons)
