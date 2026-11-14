class_name EraDialog
extends Control
## Yeni dönem ekranı (GDD 5.2): dönemin adı ve havası, bu dönemde açılan kanallar, araçlar ve bilgisayar kuşağı.
## UI-3 dili: büyük yıl ve dönem adı, açıklama; kanallar çizimli küçük kartlar, araçlar etiket; alt satır ayrı.

const CHANNEL_ART: float = 30.0

var _era_id: String


func _init(era_id: String) -> void:
	_era_id = era_id


func _ready() -> void:
	var data: GameData = DataDB.data
	var era: Dictionary = data.eras[_era_id]
	var col: VBoxContainer = UiUtil.modal_frame(self, UiUtil.dialog_size("era"))
	col.add_child(UiUtil.heading(tr("UI_ERA_TITLE") % [int(era["from"]), tr(era["name_key"])], "calendar"))
	var hero: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_L)
	var year: Label = UiUtil.label(str(int(era["from"])), 40, CozyTheme.TERRA)
	year.add_theme_font_override("font", CozyTheme.title_font(700))
	year.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	hero.add_child(year)
	hero.add_child(VSeparator.new())
	var words: VBoxContainer = UiUtil.vbox(2)
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name: Label = UiUtil.label(tr(era["name_key"]), 22, CozyTheme.FOREST)
	name.add_theme_font_override("font", CozyTheme.title_font(700))
	words.add_child(name)
	var desc: Label = UiUtil.label(tr(era["desc_key"]), 14, CozyTheme.TEXT)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.add_child(desc)
	hero.add_child(words)
	col.add_child(hero)
	var lo: int = int(era["from"])
	var hi: int = int(era["to"])
	var channels: Array[String] = []
	for id: String in data.channel_ids:
		var from: int = int(data.channels[id]["available_from"])
		if from >= lo and from <= hi:
			channels.append(id)
	if not channels.is_empty():
		col.add_child(Cards.section(tr("UI_ERA_CHANNELS"), str(channels.size()), "speakerphone"))
		var grid: GridContainer = GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", CozyTheme.SPACE_S)
		grid.add_theme_constant_override("v_separation", CozyTheme.SPACE_S)
		for id: String in channels:
			grid.add_child(_channel_card(id))
		col.add_child(grid)
	var tools: HFlowContainer = HFlowContainer.new()
	tools.add_theme_constant_override("h_separation", 6)
	tools.add_theme_constant_override("v_separation", 6)
	for id: String in data.tool_ids:
		var from: int = int(data.tools[id]["versions"][0][0])
		if not bool(data.tools[id]["starter"]) and from >= lo and from <= hi:
			tools.add_child(Cards.chip("%s · %d" % [UiUtil.name_of(data.tools, id), from]))
	for id: String in data.hardware_ids:
		var from: int = int(data.hardware[id]["available_from"])
		if from >= lo and from <= hi:
			tools.add_child(Cards.chip("%s · %d" % [UiUtil.name_of(data.hardware, id), from], CozyTheme.CREAM, CozyTheme.TEXT))
	if tools.get_child_count() > 0:
		col.add_child(Cards.section(tr("UI_ERA_TOOLS"), "", "tool"))
		col.add_child(tools)
	var frame: VBoxContainer = col.get_parent().get_parent() as VBoxContainer
	frame.add_child(HSeparator.new())
	var foot: HBoxContainer = UiUtil.hbox()
	foot.add_child(UiUtil.spacer())
	var go: Button = UiUtil.button(tr("UI_ERA_GO"), queue_free)
	go.theme_type_variation = "PrimaryButton"
	go.custom_minimum_size.x = 140.0
	foot.add_child(go)
	frame.add_child(foot)


## Açılan kanal: çizimi (yoksa ikon), adı ve açıldığı yıl.
func _channel_card(id: String) -> PanelContainer:
	var data: GameData = DataDB.data
	var card: PanelContainer = UiUtil.card()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	card.add_child(row)
	row.add_child(Cards.art("channel_art", id, CHANNEL_ART, "speakerphone"))
	var name: Label = UiUtil.label(UiUtil.name_of(data.channels, id), 14, CozyTheme.FOREST)
	name.add_theme_font_override("font", CozyTheme.strong_font())
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(name)
	row.add_child(UiUtil.label(str(int(data.channels[id]["available_from"])), 13, CozyTheme.MUTED))
	return card
