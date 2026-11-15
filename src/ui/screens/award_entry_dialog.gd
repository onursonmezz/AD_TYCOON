class_name AwardEntryDialog
extends Control
## Ödül başvurusu (GDD 15): son 12 ayın uygun kampanyaları, her başvuru ayrı ücret.
## UI-3 dili: amblemli başlık kartı, ücret/başvuru/tören bilgi şeridi, kampanya kartları; alt satır kaydırmanın dışında.

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
	var award: Dictionary = data.awards[_award_id]
	var col: VBoxContainer = UiUtil.modal_frame(self, UiUtil.dialog_size("award_entry"))
	col.add_child(UiUtil.heading(tr("UI_AWARD_ENTRY_TITLE"), "trophy"))
	var head: HBoxContainer = Cards.header(Cards.art("award_art", _award_id, 56.0, "trophy", Color.TRANSPARENT),
		UiUtil.name_of(data.awards, _award_id), "")
	var desc: Label = UiUtil.label(tr(award["desc_key"]), 13, CozyTheme.WOOD)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	(head.get_child(1) as VBoxContainer).add_child(desc)
	col.add_child(head)
	col.add_child(Cards.facts([
		Cards.fact("coins", tr("UI_AWARD_FEE"), UiUtil.money(sim.awards.entry_fee(sim.state, _award_id))),
		Cards.fact("calendar", tr("UI_AWARD_ENTRY_MONTH"), tr("MONTH_%d" % sim.awards.entry_month(_award_id))),
		Cards.fact("trophy", tr("UI_AWARD_CEREMONY_MONTH"), tr("MONTH_%d" % int(award["month"])))]))
	col.add_child(UiUtil.wrapped(tr("UI_AWARD_JURY"), 13, CozyTheme.MUTED))
	_list = UiUtil.vbox(CozyTheme.SPACE_S)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(_list)
	var frame: VBoxContainer = UiUtil.modal_outer(col)
	frame.add_child(HSeparator.new())
	var foot: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
	_status = UiUtil.label("", 13, CozyTheme.MUTED)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(_status)
	var close: Button = UiUtil.button(tr("UI_CLOSE"), _close)
	close.theme_type_variation = "PrimaryButton"
	close.custom_minimum_size.x = 120.0
	close.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	foot.add_child(close)
	frame.add_child(foot)
	_fill()


func _fill() -> void:
	UiUtil.clear(_list)
	var data: GameData = DataDB.data
	var eligible: Array[Dictionary] = GameState.sim.awards.eligible_campaigns(GameState.sim.state, _award_id)
	_list.add_child(Cards.section(tr("UI_AWARD_ELIGIBLE"), tr("UI_CAMPAIGN_COUNT") % eligible.size(), "speakerphone"))
	if eligible.is_empty():
		_list.add_child(UiUtil.label(tr("UI_AWARD_NO_CAMPAIGNS"), 14, UiUtil.MUTED))
	for h: Dictionary in eligible:
		var card: PanelContainer = UiUtil.card()
		var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
		card.add_child(row)
		var score: float = float(h["score"])
		var score_label: Label = UiUtil.label(UiUtil.score_text(score), 22, UiUtil.score_color(score))
		score_label.add_theme_font_override("font", CozyTheme.title_font(700))
		score_label.custom_minimum_size.x = 46.0
		row.add_child(score_label)
		var title: String = str(h.get("name", "")) if not str(h.get("name", "")).is_empty() else tr("UI_UNTITLED")
		var info: HBoxContainer = Cards.header(null, title, "%s · %s" % [h.get("client_name", ""),
			UiUtil.name_of(data.channels, h["main_channel"])])
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		((info.get_child(0) as VBoxContainer).get_child(0) as Label).add_theme_font_size_override("font_size", 15)
		row.add_child(info)
		var cid: String = h["campaign"]
		var send: Button = UiUtil.button(tr("UI_AWARD_SEND"), func() -> void: _send(cid))
		Cards.compact(send, true)
		send.custom_minimum_size.x = 84.0
		row.add_child(send)
		_list.add_child(card)


func _send(campaign_id: String) -> void:
	var err: String = GameState.execute(EnterAwardCommand.new(_award_id, campaign_id))
	_status.text = tr(err) if not err.is_empty() else tr("UI_AWARD_SENT")
	_status.add_theme_color_override("font_color", CozyTheme.NEGATIVE if not err.is_empty() else CozyTheme.FOREST)
	_fill()


func _close() -> void:
	if _on_done.is_valid():
		_on_done.call()
	queue_free()
