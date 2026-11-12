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
var _previewing: bool = false  # durum satırında satış önizlemesi var (eşyadan çıkınca ipucuna döner)

const PALETTE_HEIGHT: float = 52.0


func _init(view: OfficeView, on_exit: Callable) -> void:
	_view = view
	_on_exit = on_exit


func _ready() -> void:
	var col: VBoxContainer = UiUtil.vbox(6)
	add_child(col)
	var top: HBoxContainer = UiUtil.hbox()
	top.add_child(UiUtil.label(tr("UI_BUILD_TITLE"), 17, UiUtil.SAGE_DARK))
	_quality = UiUtil.label("", 14, UiUtil.WOOD)
	top.add_child(_quality)
	top.add_child(UiUtil.spacer())
	top.add_child(UiUtil.label(tr("UI_BUILD_KEYS"), 12, UiUtil.MUTED))
	top.add_child(UiUtil.button(tr("UI_BUILD_DONE"), _exit))
	col.add_child(top)
	var row: HBoxContainer = UiUtil.hbox(6)
	col.add_child(row)
	var remove: Button = UiUtil.button(tr("UI_BUILD_REMOVE"), func() -> void: _select({"kind": "remove"}))
	remove.icon = UiUtil.icon_texture("trash", 18)
	remove.toggle_mode = true
	remove.set_meta("tool", "remove")
	remove.theme_type_variation = "DeclineButton"
	_tool_buttons.append(remove)
	row.add_child(remove)
	for d: int in [-1, 1]:
		var rb: Button = UiUtil.button("", func() -> void: _view.rotate_tool(d))
		rb.icon = UiUtil.icon_texture("rotate-left" if d < 0 else "rotate-right", 20)
		rb.tooltip_text = tr("UI_BUILD_ROTATE_LEFT" if d < 0 else "UI_BUILD_ROTATE_RIGHT")
		for state: String in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
			rb.add_theme_color_override(state, UiUtil.TEXT)
		rb.add_theme_color_override("icon_disabled_color", Color(UiUtil.MUTED, 0.45))
		rb.disabled = true
		_rotate_buttons.append(rb)
		row.add_child(rb)
	row.add_child(VSeparator.new())
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size.y = PALETTE_HEIGHT
	var palette: HBoxContainer = UiUtil.hbox(6)
	scroll.add_child(palette)
	var sim: Simulation = GameState.sim
	for id: String in sim.build.available_furniture(sim.state):
		var b: Button = UiUtil.button("%s %s" % [UiUtil.name_of(DataDB.data.furniture, id),
			UiUtil.money(sim.build.furniture_cost(sim.state, id))], func() -> void: _select({"kind": "furniture", "id": id, "rot": 0}))
		b.toggle_mode = true
		b.add_theme_font_size_override("font_size", 13)
		b.set_meta("tool", id)
		_tool_buttons.append(b)
		palette.add_child(b)
	row.add_child(scroll)
	if sim.build.can_build_rooms(sim.state):
		var rooms: HBoxContainer = UiUtil.hbox()
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
		rooms.add_child(UiUtil.label(tr("UI_BUILD_ROOM_HINT"), 12, UiUtil.MUTED))
		col.add_child(rooms)
	else:
		col.add_child(UiUtil.label(tr("UI_BUILD_ROOMS_LOCKED"), 12, UiUtil.MUTED))
	_status = UiUtil.label(tr("UI_BUILD_PICK"), 14, UiUtil.TEXT)
	col.add_child(_status)
	_view.place_requested.connect(_on_place)
	_view.room_requested.connect(_on_room)
	_view.remove_requested.connect(_on_remove)
	_view.hover_changed.connect(func(key: String) -> void:
		_show(key if not key.is_empty() else "UI_BUILD_OK", key.is_empty()))
	_view.remove_hover.connect(_on_remove_hover)
	_refresh_quality()


func _select(tool: Dictionary) -> void:
	_view.set_tool(tool)
	for rb: Button in _rotate_buttons:
		rb.disabled = tool.get("kind", "") != "furniture"
	var key: String = str(tool.get("id", tool.get("kind", "")))
	for b: Button in _tool_buttons:
		b.set_pressed_no_signal(str(b.get_meta("tool")) == key)
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
