class_name PitchDialog
extends Control
## Sunum mini oyunu (GDD 14.2): ipucu kartları, 3 tur (açılış → fikir → kapanış), her seçimde müşteri tepkisi,
## sonunda rakiplerle birlikte sonuç. Tepkiler simülasyondan salt-okunur hesaplanır; sonuç tek komutla gelir.

const FACES: Dictionary = {"good": "😊", "neutral": "😐", "bad": "😠"}
const LEVEL_HIGH: float = 0.33

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
	col.add_child(UiUtil.label(tr("UI_PITCH_PREPARED") % [float(pitch["s"]), float(pitch["k"]),
		GameState.employee_name(presenter), int(presenter.get("stats", {}).get("communication", 0))], 14, UiUtil.WOOD))
	col.add_child(UiUtil.label(tr("UI_PITCH_HINTS"), 16, UiUtil.SAGE_DARK))
	var hints: HFlowContainer = HFlowContainer.new()
	for key: String in sim.pitches.hints(pitch):
		var v: float = float(pitch["prefs"][key])
		var level: String = "HIGH" if v >= LEVEL_HIGH else ("LOW" if v <= -LEVEL_HIGH else "MID")
		var card: PanelContainer = UiUtil.card()
		card.add_child(UiUtil.label(tr("PREF_" + key.to_upper()) + ": " + tr("PREF_LEVEL_" + level), 14))
		hints.add_child(card)
	col.add_child(hints)
	_reactions = UiUtil.hbox(18)
	col.add_child(_reactions)
	_title = UiUtil.label("", 18, UiUtil.SAGE_DARK)
	col.add_child(_title)
	_round_box = UiUtil.vbox(6)
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
	var row: HBoxContainer = UiUtil.hbox(10)
	for id: String in GameState.sim.pitches.cards_of_round(round_name):
		var card: PanelContainer = UiUtil.card()
		card.custom_minimum_size = Vector2(220.0, 0.0)
		var v: VBoxContainer = UiUtil.vbox(4)
		v.add_child(UiUtil.label(UiUtil.name_of(DataDB.data.pitch_cards, id), 16, UiUtil.SAGE_DARK))
		v.add_child(UiUtil.wrapped(tr(DataDB.data.pitch_cards[id]["desc_key"]), 13, UiUtil.MUTED, 200.0))
		v.add_child(UiUtil.button(tr("UI_PITCH_PLAY"), func() -> void: _play(id)))
		card.add_child(v)
		row.add_child(card)
	_round_box.add_child(row)


func _play(card_id: String) -> void:
	var sim: Simulation = GameState.sim
	var face: String = FACES[sim.pitches.reaction(sim.pitches.card_fit(sim.state.pitch, card_id))]
	var box: VBoxContainer = UiUtil.vbox(2)
	box.add_child(UiUtil.label(face, 36))
	box.add_child(UiUtil.label(UiUtil.name_of(DataDB.data.pitch_cards, card_id), 13, UiUtil.WOOD))
	_reactions.add_child(box)
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
	_title.add_theme_color_override("font_color", UiUtil.SAGE_DARK if won else UiUtil.TERRACOTTA)
	if not won and int(result["rank"]) <= 2:
		_round_box.add_child(UiUtil.wrapped(tr("UI_PITCH_SHORTLIST"), 14, UiUtil.WOOD, 680.0))
	var top: float = 0.0001
	for s: Dictionary in result["scores"]:
		top = maxf(top, float(s["score"]))
	for s: Dictionary in result["scores"]:
		var row: HBoxContainer = UiUtil.hbox()
		var who: String = tr("UI_US") if s["who"] == "player" else UiUtil.name_of(DataDB.data.rivals, s["who"])
		var name_label: Label = UiUtil.label(who, 14, UiUtil.SAGE_DARK if s["who"] == "player" else UiUtil.TEXT)
		name_label.custom_minimum_size.x = 200.0
		row.add_child(name_label)
		var bar: ProgressBar = ProgressBar.new()
		bar.custom_minimum_size = Vector2(380.0, 18.0)
		bar.show_percentage = false
		bar.value = 100.0 * float(s["score"]) / top
		row.add_child(bar)
		_round_box.add_child(row)
	_round_box.add_child(UiUtil.label(tr("UI_PITCH_CHANCE") % int(roundf(100.0 * float(result["p_win"]))), 13, UiUtil.MUTED))
	var buttons: HBoxContainer = UiUtil.hbox()
	buttons.add_child(UiUtil.spacer())
	buttons.add_child(UiUtil.button(tr("UI_CLOSE"), queue_free))
	_round_box.add_child(buttons)
