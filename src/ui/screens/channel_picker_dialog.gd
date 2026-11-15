class_name ChannelPickerDialog
extends Control
## Medya kanalı seçici (UI-3 taslağı 04): üstte kategori etiketleri ve arama; altında kategori kategori iki sütunlu
## kanal düğmeleri (çizim + ad; seçili olan işaretli); en altta seçili kanal. on_pick(kanal kimliği).

const CHROME: float = 44.0  # kaydırmanın dışındaki alt satır
const COLUMNS: int = 2

var _ids: Array[String] = []
var _current: String = ""
var _on_pick: Callable
var _category: String = ""
var _search: LineEdit
var _chips: HFlowContainer
var _list: VBoxContainer
var _selected: Label


func _init(channel_ids: Array[String], current: String, on_pick: Callable) -> void:
	_ids = channel_ids
	_current = current
	_on_pick = on_pick


func _ready() -> void:
	set_meta("esc_closes", true)
	var col: VBoxContainer = UiUtil.modal_frame(self, UiUtil.dialog_size("channel_picker") - Vector2(0.0, CHROME), true, true)
	col.add_child(UiUtil.heading(tr("UI_PICK_CHANNEL"), "speakerphone"))
	var top: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	_chips = Cards.flow_row(4)
	_chips.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_chips)
	_search = LineEdit.new()
	_search.placeholder_text = tr("UI_CHANNEL_SEARCH")
	_search.custom_minimum_size.x = 120.0
	Cards.compact(_search)
	_search.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_search.text_changed.connect(func(_t: String) -> void: _fill())
	top.add_child(_search)
	col.add_child(top)
	_list = UiUtil.vbox(6)
	col.add_child(_list)
	var frame: VBoxContainer = UiUtil.modal_outer(col)
	frame.add_child(HSeparator.new())
	_selected = UiUtil.label("", 13, CozyTheme.TEXT)
	frame.add_child(_selected)
	_fill()


func _categories() -> Array[String]:
	var out: Array[String] = []
	for id: String in _ids:
		var cat: String = str(DataDB.data.channels[id]["category"])
		if not out.has(cat):
			out.append(cat)
	return out


func _fill() -> void:
	var data: GameData = DataDB.data
	UiUtil.clear(_chips)
	_chips.add_child(_chip("", tr("UI_TAB_ALL")))
	for cat: String in _categories():
		_chips.add_child(_chip(cat, tr("CAT_" + cat.to_upper())))
	UiUtil.clear(_list)
	var needle: String = _search.text.strip_edges().to_lower()
	for cat: String in _categories():
		if not _category.is_empty() and cat != _category:
			continue
		var grid: GridContainer = GridContainer.new()
		grid.columns = COLUMNS
		grid.add_theme_constant_override("h_separation", 6)
		grid.add_theme_constant_override("v_separation", 4)
		for id: String in _ids:
			if str(data.channels[id]["category"]) != cat:
				continue
			if not needle.is_empty() and not UiUtil.name_of(data.channels, id).to_lower().contains(needle):
				continue
			grid.add_child(_channel_button(id))
		if grid.get_child_count() == 0:
			grid.free()
			continue
		_list.add_child(Cards.section(tr("CAT_" + cat.to_upper())))
		_list.add_child(grid)
	_selected.text = tr("UI_CHANNEL_SELECTED") % UiUtil.name_of(data.channels, _current)


## Kategori etiketi: seçili olan çerçeveli.
func _chip(category: String, text: String) -> Button:
	var b: Button = UiUtil.button(text, func() -> void:
		_category = category
		_fill())
	var on: bool = category == _category
	var style: StyleBoxFlat = CozyTheme.box(CozyTheme.CREAM_LIGHT if on else CozyTheme.SAGE_SOFT, 999,
		CozyTheme.FOREST if on else Color.TRANSPARENT, 1 if on else 0, false, Vector2(10.0, 1.0))
	for st: String in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		b.add_theme_stylebox_override(st, style)
	b.add_theme_font_size_override("font_size", 12)
	return b


func _channel_button(id: String) -> Button:
	var data: GameData = DataDB.data
	var on: bool = id == _current
	var b: Button = UiUtil.button("", func() -> void:
		_on_pick.call(id)
		queue_free())
	b.theme_type_variation = "PickCardActive" if on else "PickCard"
	b.custom_minimum_size.y = 32.0
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 6)
	b.add_child(row)
	var layout: Dictionary = DataDB.data.raw["ui_layout.json"]
	if (layout["channel_art"] as Dictionary).has(id):
		row.add_child(Cards.art("channel_art", id, 22.0, "speakerphone", Color.TRANSPARENT))
	else:
		row.add_child(Cards.art("channel_category_art", str(data.channels[id]["category"]), 22.0, "speakerphone", Color.TRANSPARENT))
	var name: Label = UiUtil.label(UiUtil.name_of(data.channels, id), 13, CozyTheme.TEXT)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.clip_text = true
	row.add_child(name)
	if on:
		row.add_child(UiUtil.icon("check", 14, CozyTheme.FOREST))
	return b
