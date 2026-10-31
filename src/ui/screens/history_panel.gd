class_name HistoryPanel
extends VBoxContainer
## Biten kampanyalar ve raporları.

var _main: Control
var _list: VBoxContainer
var _count: int = -1


func _init(main_screen: Control) -> void:
	_main = main_screen
	add_theme_constant_override("separation", 10)
	add_child(UiUtil.heading(tr("MENU_HISTORY")))
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_list = UiUtil.vbox(6)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)


func refresh() -> void:
	var finished: Array[Dictionary] = GameState.sim.state.finished
	if finished.size() == _count:
		return
	_count = finished.size()
	UiUtil.clear(_list)
	if finished.is_empty():
		_list.add_child(UiUtil.label(tr("UI_NO_HISTORY"), 16, UiUtil.MUTED))
	var data: GameData = DataDB.data
	for i: int in range(finished.size() - 1, -1, -1):
		var camp: Dictionary = finished[i]
		var setup: Dictionary = camp["setup"]
		var score: float = float(camp["report"]["score"])
		var row: HBoxContainer = UiUtil.hbox()
		var score_label: Label = UiUtil.label("%.1f" % score, 20, UiUtil.score_color(score))
		score_label.custom_minimum_size.x = 50.0
		row.add_child(score_label)
		row.add_child(UiUtil.label("%s · %s · %s" % [setup.get("client_name", ""),
			UiUtil.name_of(data.objectives, setup["objective"]), UiUtil.name_of(data.channels, Scoring.main_channel(setup["mix"]))], 15))
		row.add_child(UiUtil.spacer())
		row.add_child(UiUtil.button(tr("UI_OPEN_REPORT"), func() -> void: _main.call("open_modal", ReportDialog.new(camp))))
		_list.add_child(row)
