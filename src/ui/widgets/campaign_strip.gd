class_name CampaignStrip
extends PanelContainer
## Faz sürerken üstteki ince kampanya şeridi (S3B): saat kutusunun altında; müşteri, faz ve kalan gün, dört sayaç
## (Strateji, Kreatif, Teknik, Hata). Pencere açmadan ilerlemeyi gösterir; basınca kampanya penceresi açılır.
## Puan baloncukları (PointBubbles) sayaçlara uçar: counter_pos ile hedefi, pulse ile varışı gösterir.

const COUNTERS: Array = [["stat-strategy", CozyTheme.FOREST], ["stat-creative", CozyTheme.TERRA],
	["stat-technical", Color("3d6fa8")], ["alert-triangle", CozyTheme.NEGATIVE]]

var _client: Label
var _phase: Label
var _values: Array[Label] = []
var _icons: Array[Control] = []
var _bar: ProgressBar
var _on_open: Callable


func _init(on_open: Callable) -> void:
	_on_open = on_open
	var cfg: Dictionary = DataDB.data.raw["ui_layout.json"]["campaign_strip"]
	add_theme_stylebox_override("panel", CozyTheme.box(Color(CozyTheme.CREAM_LIGHT, 0.95), 999, CozyTheme.BORDER, 1, true,
		Vector2(16.0, 3.0)))
	custom_minimum_size = Vector2(float(cfg["width"]), float(cfg["height"]))
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tooltip_text = tr("UI_STRIP_TIP")
	var col: VBoxContainer = UiUtil.vbox(1)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(col)
	var row: HBoxContainer = UiUtil.hbox(8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(row)
	_client = UiUtil.label("", 13, CozyTheme.FOREST)
	_client.add_theme_font_override("font", CozyTheme.strong_font())
	_client.clip_text = true
	_client.custom_minimum_size.x = 96.0
	_client.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_client)
	_phase = UiUtil.label("", 12, CozyTheme.MUTED)
	row.add_child(_phase)
	for i: int in COUNTERS.size():
		var box: HBoxContainer = UiUtil.hbox(2)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ic: Control = UiUtil.icon(str(COUNTERS[i][0]), 15, COUNTERS[i][1])
		box.add_child(ic)
		_icons.append(ic)
		var v: Label = UiUtil.label("0", 14, COUNTERS[i][1])
		v.add_theme_font_override("font", CozyTheme.strong_font(800))
		v.custom_minimum_size.x = 30.0
		box.add_child(v)
		_values.append(v)
		row.add_child(box)
	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.custom_minimum_size.y = 4.0
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_bar)


func _gui_input(event: InputEvent) -> void:
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		_on_open.call()


## Günlük yenileme: kampanya yoksa gizlenir.
func refresh(camp: Dictionary) -> void:
	visible = not camp.is_empty()
	if camp.is_empty():
		return
	var sim: Simulation = GameState.sim
	var setup: Dictionary = camp["setup"]
	_client.text = str(setup.get("client_name", ""))
	var phase: int = sim.production.current_phase(camp)
	var days_total: int = int(camp["days_total"])
	var phase_len: float = float(days_total) / 3.0
	var days_left: int = maxi(0, int(ceilf(phase_len * (phase + 1) - float(camp["day"]))))
	_phase.text = tr("UI_STRIP_PHASE") % [tr("UI_STEP_" + ["STRATEGY", "CREATIVE", "PRODUCTION"][phase]), days_left]
	_bar.value = 100.0 * float(camp["day"]) / maxf(1.0, float(days_total))
	var totals: Dictionary = sim.scoring.stat_totals(camp["points"])
	var values: Array = [int(totals["strategy"]), int(totals["creative"]), int(totals["technical"]), int(camp["errors"])]
	for i: int in 4:
		_values[i].text = str(values[i])


## i. sayacın ekrandaki yeri (baloncuğun hedefi).
func counter_pos(i: int) -> Vector2:
	var ic: Control = _icons[clampi(i, 0, 3)]
	return ic.global_position + ic.size * 0.5


## Baloncuk varınca sayaç kısa bir zıplama yapar.
func pulse(i: int) -> void:
	var ic: Control = _icons[clampi(i, 0, 3)]
	ic.pivot_offset = ic.size * 0.5
	var tw: Tween = ic.create_tween()
	tw.tween_property(ic, "scale", Vector2(1.35, 1.35), 0.08)
	tw.tween_property(ic, "scale", Vector2.ONE, 0.14)
