class_name BackgroundDialog
extends Control
## Yeni oyun: oyuncunun geçmişi (GDD 11.5).

var _on_pick: Callable


func _init(on_pick: Callable) -> void:
	_on_pick = on_pick


func _ready() -> void:
	var data: GameData = DataDB.data
	var col: VBoxContainer = UiUtil.modal_frame(self, Vector2(620.0, 520.0))
	col.add_child(UiUtil.heading(tr("UI_BACKGROUND_TITLE")))
	col.add_child(UiUtil.wrapped(tr("UI_BACKGROUND_HINT"), 15, UiUtil.MUTED, 560.0))
	for id: String in data.background_ids:
		var bg: Dictionary = data.backgrounds[id]
		var card: PanelContainer = UiUtil.card()
		var row: HBoxContainer = UiUtil.hbox()
		card.add_child(row)
		var info: VBoxContainer = UiUtil.vbox(2)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_child(UiUtil.label(tr(bg["name_key"]), 18, UiUtil.SAGE_DARK))
		info.add_child(UiUtil.wrapped(tr(bg["desc_key"]), 14, UiUtil.TEXT, 360.0))
		var stats: PackedStringArray = PackedStringArray()
		for stat: Variant in data.bal("staff_rules.stats"):
			stats.append("%s %d" % [tr("STAT_" + str(stat).to_upper()), int(bg["stats"][stat])])
		info.add_child(UiUtil.label(" · ".join(stats), 13, UiUtil.WOOD))
		row.add_child(info)
		row.add_child(UiUtil.button(tr("UI_PICK"), func() -> void: _on_pick.call(id)))
		col.add_child(card)
	var buttons: HBoxContainer = UiUtil.hbox()
	buttons.add_child(UiUtil.spacer())
	buttons.add_child(UiUtil.button(tr("UI_CANCEL"), queue_free))
	col.add_child(buttons)
