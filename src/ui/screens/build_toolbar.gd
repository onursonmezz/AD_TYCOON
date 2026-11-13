class_name BuildToolbar
extends PanelContainer
## İnşa modu araç çubuğu (M6-B): mobilya paleti, oda çizme (büyütülmüş ofisten), kaldırma; ofisin altında durur.
## OfficeView'in isteklerini komutlara çevirir, sonucu/hata nedenini gösterir. Paletin solunda sabit duran "Sil / sat"
## düğmesi ve iki döndürme düğmesi (eşya seçiliyken) var; Delete tuşu imlecin altındaki eşyayı satar.

var _view: OfficeView
var _on_exit: Callable
var _status: Label
var _quality: Label
var _room_type: OptionButton
var _room_ids: Array[String] = []
var _tool_buttons: Array[Button] = []
var _rotate_buttons: Array[Button] = []
var _cat_row: HBoxContainer
var _palette: HBoxContainer
var _category: String = "all"
var _previewing: bool = false  # durum satırında satış önizlemesi var (eşyadan çıkınca ipucuna döner)

const CARD_SIZE: Vector2 = Vector2(88.0, 82.0)
const TOOLS_WIDTH: float = 190.0
const CATEGORIES: Array = [["all", "UI_BUILD_CAT_ALL"], ["plants", "UI_BUILD_CAT_PLANTS"], ["other", "UI_BUILD_CAT_OTHER"]]


func _init(view: OfficeView, on_exit: Callable) -> void:
	_view = view
	_on_exit = on_exit


func _ready() -> void:
	# UI-3 (taslak 20): iki kutu yan yana. Solda araçlar ve durum; sağda kategori sekmeleri, eşya kartları, oda çizme.
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var split: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	add_child(split)
	split.add_child(_tools_box())
	var right: PanelContainer = PanelContainer.new()
	right.add_theme_stylebox_override("panel", CozyTheme.box(CozyTheme.CREAM_LIGHT, CozyTheme.RADIUS_MODAL, CozyTheme.BORDER, 1, true,
		Vector2(CozyTheme.SPACE_M, CozyTheme.SPACE_S)))
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(right)
	var col: VBoxContainer = UiUtil.vbox(6)
	right.add_child(col)
	var top: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	_cat_row = UiUtil.hbox()
	_cat_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_cat_row)
	var done: Button = UiUtil.button(tr("UI_BUILD_DONE"), _exit)
	done.theme_type_variation = "PrimaryButton"
	top.add_child(done)
	col.add_child(top)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size.y = CARD_SIZE.y + 12.0
	_palette = UiUtil.hbox(6)
	scroll.add_child(_palette)
	col.add_child(scroll)
	var sim: Simulation = GameState.sim
	if sim.build.can_build_rooms(sim.state):
		var rooms: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
		_room_type = OptionButton.new()
		for type: String in DataDB.data.room_type_ids:
			if bool(DataDB.data.room_types[type]["buildable"]):
				_room_ids.append(type)
				_room_type.add_item("%s (%s/m²)" % [UiUtil.name_of(DataDB.data.room_types, type),
					UiUtil.money(sim.build.room_cost(sim.state, type, Rect2(0, 0, 1, 1)))])
		rooms.add_child(_room_type)
		var draw: Button = UiUtil.button(tr("UI_BUILD_ROOM"), func() -> void:
			_select({"kind": "room", "type": _room_ids[_room_type.selected]}))
		draw.toggle_mode = true
		draw.set_meta("tool", "room")
		_tool_buttons.append(draw)
		rooms.add_child(draw)
		rooms.add_child(UiUtil.wrapped(tr("UI_BUILD_ROOM_HINT"), 11, UiUtil.MUTED, 160.0))
		col.add_child(rooms)
	else:
		col.add_child(UiUtil.label(tr("UI_BUILD_ROOMS_LOCKED"), 11, UiUtil.MUTED))
	col.add_child(UiUtil.label(tr("UI_BUILD_KEYS"), 11, UiUtil.MUTED))
	_fill_palette("all")
	_view.place_requested.connect(_on_place)
	_view.room_requested.connect(_on_room)
	_view.remove_requested.connect(_on_remove)
	_view.hover_changed.connect(func(key: String) -> void:
		_show(key if not key.is_empty() else "UI_BUILD_OK", key.is_empty()))
	_view.remove_hover.connect(_on_remove_hover)
	_refresh_quality()


## Sol kutu: yeşil başlık, oda kalitesi, döndür / sat araçları ve durum satırı.
func _tools_box() -> PanelContainer:
	var box: PanelContainer = PanelContainer.new()
	box.custom_minimum_size.x = TOOLS_WIDTH
	var parts: Array = UiUtil.window_frame(box)
	(parts[0] as Label).text = tr("UI_BUILD_TITLE")
	(parts[0] as Label).add_theme_font_size_override("font_size", 15)
	var ic: TextureRect = (parts[0] as Label).get_parent().get_node("Icon")
	ic.texture = UiUtil.icon_texture("hammer", 18)
	ic.visible = true
	var col: VBoxContainer = parts[1]
	col.add_theme_constant_override("separation", 6)
	_quality = UiUtil.wrapped("", 12, CozyTheme.TEXT, TOOLS_WIDTH - 48.0)
	col.add_child(_quality)
	var row: HBoxContainer = UiUtil.hbox(6)
	col.add_child(row)
	for d: int in [-1, 1]:
		var rb: Button = UiUtil.button("", func() -> void: _view.rotate_tool(d))
		rb.icon = UiUtil.icon_texture("rotate-left" if d < 0 else "rotate-right", 20)
		rb.tooltip_text = tr("UI_BUILD_ROTATE_LEFT" if d < 0 else "UI_BUILD_ROTATE_RIGHT")
		rb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for state: String in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
			rb.add_theme_color_override(state, CozyTheme.TERRA)
		rb.add_theme_color_override("icon_disabled_color", Color(UiUtil.MUTED, 0.45))
		rb.disabled = true
		_rotate_buttons.append(rb)
		row.add_child(rb)
	var remove: Button = UiUtil.button(tr("UI_BUILD_REMOVE"), func() -> void: _select({"kind": "remove"}))
	remove.icon = UiUtil.icon_texture("trash", 16)
	remove.toggle_mode = true
	remove.set_meta("tool", "remove")
	remove.theme_type_variation = "DeclineButton"
	remove.add_theme_font_size_override("font_size", 13)
	_tool_buttons.append(remove)
	col.add_child(remove)
	_status = UiUtil.wrapped(tr("UI_BUILD_PICK"), 12, UiUtil.TEXT, TOOLS_WIDTH - 48.0)
	col.add_child(_status)
	return box


## Kategori sekmeleri ve eşya kartları. Kategori eşyanın "decor" alanından: bitkiler ve diğerleri.
func _fill_palette(category: String) -> void:
	_category = category
	UiUtil.clear(_cat_row)
	_cat_row.add_child(UiUtil.segmented(CATEGORIES, _category, _fill_palette))
	for b: Button in _tool_buttons.duplicate():
		if b.get_parent() == _palette:
			_tool_buttons.erase(b)
	UiUtil.clear(_palette)
	var sim: Simulation = GameState.sim
	var current: String = str(_view.build_tool.get("id", ""))
	for id: String in sim.build.available_furniture(sim.state):
		var plant: bool = str(DataDB.data.furniture[id].get("decor", "")) == "plant"
		if (category == "plants" and not plant) or (category == "other" and plant):
			continue
		var b: Button = Button.new()
		b.toggle_mode = true
		b.theme_type_variation = "PickCard"
		b.custom_minimum_size = CARD_SIZE
		b.set_meta("tool", id)
		b.button_pressed = id == current
		b.pressed.connect(func() -> void: _select({"kind": "furniture", "id": id, "rot": 0}))
		var inner: VBoxContainer = UiUtil.vbox(0)
		inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 6)
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(inner)
		var ic: TextureRect = UiUtil.icon("plant" if plant else "building", 26, CozyTheme.POSITIVE if plant else CozyTheme.TERRA)
		ic.size_flags_vertical = Control.SIZE_EXPAND_FILL
		inner.add_child(ic)
		var name: Label = UiUtil.label(UiUtil.name_of(DataDB.data.furniture, id), 11, CozyTheme.TEXT)
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name.clip_text = true
		inner.add_child(name)
		var price: Label = UiUtil.label(UiUtil.money(sim.build.furniture_cost(sim.state, id)), 11, CozyTheme.FOREST)
		price.add_theme_font_override("font", CozyTheme.strong_font())
		price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		inner.add_child(price)
		b.tooltip_text = UiUtil.name_of(DataDB.data.furniture, id)
		_tool_buttons.append(b)
		_palette.add_child(b)


func _select(tool: Dictionary) -> void:
	_view.set_tool(tool)
	for rb: Button in _rotate_buttons:
		rb.disabled = tool.get("kind", "") != "furniture"
	var key: String = str(tool.get("id", tool.get("kind", "")))
	for b: Button in _tool_buttons:
		b.set_pressed_no_signal(str(b.get_meta("tool")) == key)
		if b.get_parent() == _palette:
			b.theme_type_variation = "PickCardActive" if str(b.get_meta("tool")) == key else "PickCard"
	_show("UI_BUILD_PICK_" + str(tool["kind"]).to_upper(), true)


func _show(key: String, ok: bool) -> void:
	_previewing = false
	_status.text = tr(key)
	_status.add_theme_color_override("font_color", UiUtil.SAGE_DARK if ok else UiUtil.TERRACOTTA)


func _refresh_quality() -> void:
	var s: SimState = GameState.sim.state
	_quality.text = tr("UI_BUILD_QUALITY") % [s.room_quality, Employee.office_mult(DataDB.data, s.room_quality)]


func _on_place(id: String, pos: Vector2, rot: int) -> void:
	var err: String = GameState.execute(PlaceFurnitureCommand.new(id, pos, rot))
	_show(err if not err.is_empty() else "UI_BUILD_PLACED", err.is_empty())
	_refresh_quality()


func _on_room(type: String, rect: Rect2) -> void:
	var err: String = GameState.execute(BuildRoomCommand.new(type, rect))
	_show(err if not err.is_empty() else "UI_BUILD_ROOM_DONE", err.is_empty())
	_refresh_quality()


## Noktadaki oyuncu eşyasını satar (halının üstündeki eşya önce). Satıldıysa true.
func _sell_at(p: Vector2) -> bool:
	var sim: Simulation = GameState.sim
	var prop: Dictionary = sim.build.layout(sim.state).furniture_at(p)
	if prop.is_empty():
		return false
	GameState.execute(SellFurnitureCommand.new(int(prop["index"])))
	_show("UI_BUILD_SOLD", true)
	_refresh_quality()
	return true


## Önce mobilya, yoksa çizilmiş oda kaldırılır.
func _on_remove(p: Vector2) -> void:
	var sim: Simulation = GameState.sim
	if _sell_at(p):
		return
	var rooms: Array = sim.state.build["rooms"]
	for i: int in rooms.size():
		var r: Array = rooms[i]["rect"]
		if Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3])).has_point(p):
			GameState.execute(DemolishRoomCommand.new(i))
			_show("UI_BUILD_DEMOLISHED", true)
			_refresh_quality()
			return
	_show("UI_BUILD_NOTHING", false)


func _unhandled_key_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo or not is_visible_in_tree():
		return
	if key.keycode == KEY_DELETE:
		var p: Vector2 = _view.hover_point()
		if p == Vector2.INF or not _sell_at(p):
			_show("UI_BUILD_NOTHING", false)
		_view.refresh_hover()
		get_viewport().set_input_as_handled()


## Sil aracında imlecin altındaki eşyanın adı ve geri gelecek para.
func _on_remove_hover(prop: Dictionary) -> void:
	if str(_view.build_tool.get("kind", "")) != "remove":
		return
	if prop.is_empty():
		if _previewing:
			_show("UI_BUILD_PICK_REMOVE", true)
		return
	var sim: Simulation = GameState.sim
	_status.text = tr("UI_BUILD_SELL_PREVIEW") % [UiUtil.name_of(DataDB.data.furniture, prop["id"]),
		UiUtil.money(sim.build.refund(sim.state, int(prop["index"])))]
	_status.add_theme_color_override("font_color", UiUtil.TERRACOTTA)
	_previewing = true


func _exit() -> void:
	_view.set_tool({})
	_on_exit.call()
