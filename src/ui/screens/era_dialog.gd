class_name EraDialog
extends Control
## Yeni dönem ekranı (GDD 5.2): dönemin adı ve havası, bu dönemde açılan kanallar, araçlar ve bilgisayar kuşağı.

var _era_id: String


func _init(era_id: String) -> void:
	_era_id = era_id


func _ready() -> void:
	var data: GameData = DataDB.data
	var era: Dictionary = data.eras[_era_id]
	var col: VBoxContainer = UiUtil.modal_frame(self, Vector2(640.0, 420.0))
	col.add_child(UiUtil.label(tr("UI_ERA_TITLE") % [int(era["from"]), tr(era["name_key"])], 26, UiUtil.MUSTARD))
	col.add_child(UiUtil.wrapped(tr(era["desc_key"]), 16, UiUtil.TEXT, 580.0))
	var lo: int = int(era["from"])
	var hi: int = int(era["to"])
	var channels: PackedStringArray = PackedStringArray()
	for id: String in data.channel_ids:
		var from: int = int(data.channels[id]["available_from"])
		if from >= lo and from <= hi:
			channels.append("%s (%d)" % [UiUtil.name_of(data.channels, id), from])
	var tools: PackedStringArray = PackedStringArray()
	for id: String in data.tool_ids:
		var from: int = int(data.tools[id]["versions"][0][0])
		if not bool(data.tools[id]["starter"]) and from >= lo and from <= hi:
			tools.append("%s (%d)" % [UiUtil.name_of(data.tools, id), from])
	for id: String in data.hardware_ids:
		var from: int = int(data.hardware[id]["available_from"])
		if from >= lo and from <= hi:
			tools.append("%s (%d)" % [UiUtil.name_of(data.hardware, id), from])
	if not channels.is_empty():
		col.add_child(UiUtil.label(tr("UI_ERA_CHANNELS"), 16, UiUtil.SAGE_DARK))
		col.add_child(UiUtil.wrapped(", ".join(channels), 14, UiUtil.TEXT, 580.0))
	if not tools.is_empty():
		col.add_child(UiUtil.label(tr("UI_ERA_TOOLS"), 16, UiUtil.SAGE_DARK))
		col.add_child(UiUtil.wrapped(", ".join(tools), 14, UiUtil.TEXT, 580.0))
	var buttons: HBoxContainer = UiUtil.hbox()
	buttons.add_child(UiUtil.spacer())
	buttons.add_child(UiUtil.button(tr("UI_ERA_GO"), queue_free))
	col.add_child(buttons)
