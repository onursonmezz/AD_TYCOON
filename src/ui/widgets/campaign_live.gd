class_name CampaignLive
extends VBoxContainer
## Kampanya penceresinin canlı bölümü (CP-2): üç basamaklı faz takipçisi (Strateji → Kreatif → Prodüksiyon; biten
## basamak işaretli, içinde bulunulan basamak kendi ilerlemesiyle dolar) ve büyük sayaç kartları (Strateji, Kreatif,
## Teknik, Hata). Sayılar arttıkça yukarı sayar, kartın üstünde "+n" yükselir; kampanyanın ilerlediği hissedilir.

const COUNTERS: Array = [["stat-strategy", "STAT_STRATEGY_NAME"], ["stat-creative", "STAT_CREATIVE_NAME"],
	["stat-technical", "STAT_TECHNICAL_NAME"], ["alert-triangle", "UI_COUNT_ERRORS"]]
const STEP_ICONS: Array[String] = ["stat-strategy", "stat-creative", "stat-technical"]
const COUNT_SECONDS: float = 0.6
const FLOAT_RISE: float = 26.0

var _tracker: PhaseTracker
var _values: Array[Label] = []
var _cards: Array[PanelContainer] = []
var _overlays: Array[Control] = []  # kartın üstünde serbest katman: "+n" yerel konumla çizilir (pencere ölçeğine uyar)
var _shown: Array[float] = [0.0, 0.0, 0.0, 0.0]
var _target: Array[int] = [-1, -1, -1, -1]


func _init() -> void:
	add_theme_constant_override("separation", CozyTheme.SPACE_S)
	var track_card: PanelContainer = UiUtil.card()
	_tracker = PhaseTracker.new()
	track_card.add_child(_tracker)
	track_card.tooltip_text = ""
	add_child(track_card)
	var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	for i: int in COUNTERS.size():
		row.add_child(_counter_card(i))
	add_child(row)


func _counter_card(i: int) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.theme_type_variation = "Card"
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	card.add_child(row)
	var tile: PanelContainer = Cards.tile(str(COUNTERS[i][0]), 38.0, CozyTheme.TERRA_SOFT if i < 3 else CozyTheme.CREAM)
	tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(tile)
	var col: VBoxContainer = UiUtil.vbox(-4)
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var value: Label = UiUtil.label("0", 24, CozyTheme.FOREST if i < 3 else CozyTheme.MUTED)
	value.add_theme_font_override("font", CozyTheme.title_font(800))
	col.add_child(value)
	col.add_child(UiUtil.label(tr(str(COUNTERS[i][1])), 12, CozyTheme.MUTED))
	row.add_child(col)
	_values.append(value)
	_cards.append(card)
	var overlay: Control = Control.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(overlay)
	_overlays.append(overlay)
	return card


## Her yenilemede: faz, fazın ilerlemesi, kalan gün ve dört sayaç.
func update(phase: int, phase_progress: float, days_left: int, values: Array[int]) -> void:
	_tracker.set_state(phase, phase_progress, days_left)
	_tracker.tooltip_text = tr("UI_PHASE_STATUS") % [tr("PHASE_%d" % phase), days_left]
	for i: int in values.size():
		var v: int = values[i]
		if _target[i] < 0:
			_target[i] = v
			_shown[i] = float(v)
			_values[i].text = str(v)
			if i == 3 and v > 0:
				_values[i].add_theme_color_override("font_color", CozyTheme.NEGATIVE)
			continue
		if v == _target[i]:
			continue
		var gain: int = v - _target[i]
		_target[i] = v
		_count_to(i, v)
		if gain > 0:
			_float_gain(i, gain)
		if i == 3 and v > 0:
			_values[i].add_theme_color_override("font_color", CozyTheme.NEGATIVE)


func _count_to(i: int, v: int) -> void:
	var tw: Tween = create_tween()
	tw.tween_method(func(x: float) -> void:
		_shown[i] = x
		_values[i].text = str(int(roundf(x))), _shown[i], float(v), COUNT_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## Kartın üstünde yükselip kaybolan "+n" (hata için kırmızı).
func _float_gain(i: int, gain: int) -> void:
	var overlay: Control = _overlays[i]
	if not overlay.is_inside_tree():
		return
	var l: Label = UiUtil.label("+%d" % gain, 16, CozyTheme.POSITIVE if i < 3 else CozyTheme.NEGATIVE)
	l.add_theme_font_override("font", CozyTheme.title_font(800))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(l)
	l.position = Vector2(overlay.size.x - 40.0, 0.0)
	var tw: Tween = l.create_tween().set_parallel(true)
	tw.tween_property(l, "position:y", -FLOAT_RISE, 0.9).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.9).set_delay(0.3)
	tw.chain().tween_callback(l.queue_free)
