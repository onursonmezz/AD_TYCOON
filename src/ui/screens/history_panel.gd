class_name HistoryPanel
extends VBoxContainer
## Biten kampanyalar ve raporları. UI-4: her kampanya bir kart (puan rozeti, müşteri, hedef ve kanal); boşken ortada mesaj.

var _main: Control
var _list: VBoxContainer
var _count: int = -1


func _init(main_screen: Control) -> void:
	_main = main_screen
	add_theme_constant_override("separation", 10)
	add_child(UiUtil.heading(tr("MENU_HISTORY")))
	_list = UiUtil.vbox(CozyTheme.SPACE_S)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_list)


func refresh() -> void:
	var finished: Array[Dictionary] = GameState.sim.state.finished
	if finished.size() == _count:
		return
	_count = finished.size()
	UiUtil.clear(_list)
	if finished.is_empty():
		_list.add_child(Cards.empty_state("chart-bar", tr("UI_NO_HISTORY_LONG")))
		return
	var data: GameData = DataDB.data
	for i: int in range(finished.size() - 1, -1, -1):
		var camp: Dictionary = finished[i]
		var setup: Dictionary = camp["setup"]
		var score: float = float(camp["report"]["score"])
		var card: PanelContainer = UiUtil.card()
		var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
		card.add_child(row)
		var badge: PanelContainer = Cards.chip(UiUtil.score_text(score), CozyTheme.CREAM, UiUtil.score_color(score))
		badge.custom_minimum_size = Vector2(58.0, 0.0)
		var badge_label: Label = badge.get_child(0) as Label
		badge_label.add_theme_font_size_override("font_size", 20)
		badge_label.add_theme_font_override("font", CozyTheme.title_font(700))
		badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(badge)
		var title: String = str(setup.get("client_name", ""))
		var name: String = str(setup.get("name", ""))
		if not name.is_empty():
			title += " · " + name
		var sub: String = "%s · %s" % [UiUtil.name_of(data.objectives, setup["objective"]),
			UiUtil.name_of(data.channels, Scoring.main_channel(setup["mix"]))]
		var text: VBoxContainer = UiUtil.vbox(0)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var t: Label = UiUtil.label(title, 16, CozyTheme.FOREST)
		t.add_theme_font_override("font", CozyTheme.title_font(700))
		t.clip_text = true
		text.add_child(t)
		text.add_child(UiUtil.label(sub, 12, CozyTheme.MUTED))
		row.add_child(text)
		var open: Button = UiUtil.button(tr("UI_OPEN_REPORT"), func() -> void: _main.call("open_modal", ReportDialog.new(camp)))
		open.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(open)
		_list.add_child(card)
