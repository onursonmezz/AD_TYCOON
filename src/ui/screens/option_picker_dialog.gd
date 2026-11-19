class_name OptionPickerDialog
extends Control
## Kampanya seçeneği seçici (S2): açılır menü yerine küçük bir panel. Her seçenek çizimli bir kart (OptionArt);
## seçili olan işaretli. Karta basınca seçilir ve panel kapanır. Satır sayısı seçenek sayısına göre; genişlik sabit.
## items: [{ "id", "name", "sub" (isteğe bağlı kısa açıklama), "art_kind", "art_id" }]

const COLUMNS: int = 4
const ART: Vector2 = Vector2(104.0, 72.0)
const ART_GAP: float = 44.0
const COMPACT_FROM: int = 8
const COMPACT_COLUMNS: int = 5
const COMPACT_ROW: float = 0.68  # seçici düğmede soldaki çizimin yeri

var _title: String
var _items: Array
var _current: String
var _on_pick: Callable
var _compact: bool = false


func _init(title: String, items: Array, current: String, on_pick: Callable) -> void:
	_title = title
	_items = items
	_current = current
	_on_pick = on_pick


func _ready() -> void:
	set_meta("esc_closes", true)
	var base: Vector2 = UiUtil.dialog_size("option_picker")
	_compact = _items.size() > COMPACT_FROM  # S5: çok seçenekte (pozisyonlar) küçük kartlar, 5 sütun
	var columns: int = COMPACT_COLUMNS if _compact else COLUMNS
	var rows: int = ceili(float(_items.size()) / columns)
	var row_h: float = float(DataDB.data.raw["ui_layout.json"]["option_picker_row"]) * (COMPACT_ROW if _compact else 1.0)
	var col: VBoxContainer = UiUtil.modal_frame(self, Vector2(base.x, base.y + row_h * rows), true, true)
	col.add_child(UiUtil.heading(_title, "speakerphone"))
	var grid: GridContainer = GridContainer.new()
	grid.columns = mini(columns, _items.size())
	grid.add_theme_constant_override("h_separation", CozyTheme.SPACE_S)
	grid.add_theme_constant_override("v_separation", CozyTheme.SPACE_S)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(grid)
	for it: Dictionary in _items:
		grid.add_child(_card(it))


func _card(it: Dictionary) -> Button:
	var on: bool = str(it["id"]) == _current
	var b: Button = UiUtil.button("", func() -> void:
		_on_pick.call(str(it["id"]))
		queue_free())
	b.theme_type_variation = "PickCardActive" if on else "PickCard"
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.tooltip_text = str(it.get("sub", ""))
	var box: VBoxContainer = UiUtil.vbox(2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 6)
	b.add_child(box)
	var art: OptionArt = OptionArtMedia.new(str(it["art_kind"]), str(it["art_id"]))
	var art_size: Vector2 = ART * (0.55 if _compact else 1.0)
	art.custom_minimum_size = art_size
	box.add_child(art)
	var name: Label = UiUtil.label(str(it["name"]), 13, CozyTheme.FOREST if on else CozyTheme.TEXT)
	name.add_theme_font_override("font", CozyTheme.strong_font())
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name.custom_minimum_size = Vector2(art_size.x if not _compact else 0.0, 34.0)
	name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if _compact:
		name.add_theme_font_size_override("font_size", 12)
	box.add_child(name)
	if not str(it.get("note", "")).is_empty():  # kartın altında küçük not (fiyat, departman)
		var note: Label = UiUtil.label(str(it["note"]), 11, CozyTheme.MUTED)
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(note)
	b.custom_minimum_size = Vector2(art_size.x + 12.0, art_size.y + (60.0 if not str(it.get("note", "")).is_empty() else 46.0))
	if on:
		var tick: TextureRect = TextureRect.new()
		tick.texture = UiUtil.icon_texture("check", 16)
		tick.modulate = CozyTheme.FOREST
		tick.position = Vector2(6, 6)
		tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(tick)
	return b


## Seçiciyi açan düğme (açılır menünün yerine): küçük çizim, "Başlık: seçili ad" ve ok. Bastığında panel açılır.
static func opener(title: String, items: Array, current: String, main_screen: Control, on_pick: Callable) -> Button:
	var chosen: Dictionary = {}
	for it: Dictionary in items:
		if str(it["id"]) == current:
			chosen = it
	# Yazı düğmenin kendi metni (genişlik ondan hesaplanır, üst üste binmez); çizim solda, ok sağda.
	var b: Button = Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0.0, 34.0)
	b.tooltip_text = str(chosen.get("sub", ""))
	b.text = "%s: %s" % [title, str(chosen.get("name", ""))]
	b.add_theme_font_size_override("font_size", 13)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.icon = UiUtil.icon_texture("chevron-right", 12)
	b.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	for st: String in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		var box: StyleBox = b.get_theme_stylebox(st, "Button").duplicate()
		box.content_margin_left = ART_GAP
		b.add_theme_stylebox_override(st, box)
	if not chosen.is_empty():
		var art: OptionArt = OptionArtMedia.new(str(chosen["art_kind"]), str(chosen["art_id"]))
		art.size = Vector2(32.0, 24.0)
		art.position = Vector2(6.0, 5.0)
		b.add_child(art)
	b.pressed.connect(func() -> void:
		main_screen.call("open_modal", OptionPickerDialog.new(title, items, current, on_pick)))
	return b
