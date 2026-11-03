class_name AwardEntryDialog
extends Control
## Ödül başvurusu (GDD 15): son 12 ayın uygun kampanyaları, her başvuru ayrı ücret.

var _award_id: String
var _on_done: Callable
var _list: VBoxContainer
var _status: Label


func _init(award_id: String, on_done: Callable) -> void:
	_award_id = award_id
	_on_done = on_done


func _ready() -> void:
	var data: GameData = DataDB.data
	var sim: Simulation = GameState.sim
	var col: VBoxContainer = UiUtil.modal_frame(self, Vector2(640.0, 460.0))
	col.add_child(UiUtil.heading(UiUtil.name_of(data.awards, _award_id)))
	col.add_child(UiUtil.wrapped(tr(data.awards[_award_id]["desc_key"]), 14, UiUtil.MUTED, 580.0))
	col.add_child(UiUtil.wrapped(tr("UI_AWARD_ENTRY_HINT") % UiUtil.money(sim.awards.entry_fee(sim.state, _award_id)), 14,
		UiUtil.TEXT, 580.0))
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size.y = 240.0
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	_list = UiUtil.vbox(6)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	_status = UiUtil.label("", 14, UiUtil.TERRACOTTA)
	col.add_child(_status)
	var buttons: HBoxContainer = UiUtil.hbox()
	buttons.add_child(UiUtil.spacer())
	buttons.add_child(UiUtil.button(tr("UI_CLOSE"), _close))
	col.add_child(buttons)
	_fill()


func _fill() -> void:
	UiUtil.clear(_list)
	var data: GameData = DataDB.data
	var eligible: Array[Dictionary] = GameState.sim.awards.eligible_campaigns(GameState.sim.state, _award_id)
	if eligible.is_empty():
		_list.add_child(UiUtil.label(tr("UI_AWARD_NO_CAMPAIGNS"), 14, UiUtil.MUTED))
	for h: Dictionary in eligible:
		var row: HBoxContainer = UiUtil.hbox()
		var score: float = float(h["score"])
		var score_label: Label = UiUtil.label("%.1f" % score, 18, UiUtil.score_color(score))
		score_label.custom_minimum_size.x = 46.0
		row.add_child(score_label)
		var title: String = str(h.get("name", "")) if not str(h.get("name", "")).is_empty() else tr("UI_UNTITLED")
		row.add_child(UiUtil.label("%s · %s · %s" % [title, h.get("client_name", ""), UiUtil.name_of(data.channels, h["main_channel"])], 14))
		row.add_child(UiUtil.spacer())
		var cid: String = h["campaign"]
		row.add_child(UiUtil.button(tr("UI_AWARD_SEND"), func() -> void: _send(cid)))
		_list.add_child(row)


func _send(campaign_id: String) -> void:
	var err: String = GameState.execute(EnterAwardCommand.new(_award_id, campaign_id))
	_status.text = tr(err) if not err.is_empty() else tr("UI_AWARD_SENT")
	_status.add_theme_color_override("font_color", UiUtil.TERRACOTTA if not err.is_empty() else UiUtil.SAGE_DARK)
	_fill()


func _close() -> void:
	if _on_done.is_valid():
		_on_done.call()
	queue_free()
