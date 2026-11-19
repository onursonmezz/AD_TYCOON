class_name ScoreFactors
extends VBoxContainer
## "Neden bu puan?" (S4): puanı etkileyen etkenler kart kart. Her kartta ikon, ad, derece (Güçlü/İyi/Nötr/Zayıf),
## dört dilimli ölçek ve bir cümle: o etkene ait rapor cümlesi (RL_*) varsa o, yoksa derecenin genel cümlesi.
## Üstte en büyük güç ve en büyük zaaf. Etkenler ve eşikler data/report_lines.json "factors"; ham sayı ipucunda.

const LEVELS: Array[String] = ["WEAK", "NEUTRAL", "GOOD", "STRONG"]
const COLUMNS: int = 2

var _camp: Dictionary
## Ham çarpanlar (rapor dökümü): başlık satırının ipucu.
var raw_tip: String = ""


func _init(camp: Dictionary) -> void:
	_camp = camp
	add_theme_constant_override("separation", CozyTheme.SPACE_S)


func _ready() -> void:
	var factors: Array = DataDB.data.raw["report_lines.json"].get("factors", [])
	var m: Dictionary = ReportWriter.metrics(_camp["report"])
	var matched: Array = []
	for line: Dictionary in _camp.get("lines", []):
		matched.append(str(line["key"]))
	var rows: Array = []
	for f: Dictionary in factors:
		var value: float = float(m.get(str(f["metric"]), 1.0))
		rows.append({"f": f, "value": value, "level": level_of(f, value), "line": _line_for(f, matched)})
	add_child(_headline(rows))
	var grid: GridContainer = GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", CozyTheme.SPACE_S)
	grid.add_theme_constant_override("v_separation", CozyTheme.SPACE_S)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for r: Dictionary in rows:
		grid.add_child(_card(r))
	add_child(grid)


## Derece: 0 zayıf … 3 güçlü. thresholds = [zayıf altı, nötr altı, iyi altı]; invert: küçük değer iyidir (hata).
static func level_of(f: Dictionary, value: float) -> int:
	var t: Array = f["thresholds"]
	if bool(f.get("invert", false)):
		if value <= float(t[2]):
			return 3
		if value <= float(t[1]):
			return 2
		return 1 if value <= float(t[0]) else 0
	if value < float(t[0]):
		return 0
	if value < float(t[1]):
		return 1
	return 2 if value < float(t[2]) else 3


## Etkenin rapordaki cümlesi (rules içinden ilk eşleşen); yoksa "".
func _line_for(f: Dictionary, matched: Array) -> String:
	for key: Variant in f.get("rules", []):
		if matched.has(str(key)):
			return str(key)
	return ""


func _headline(rows: Array) -> HBoxContainer:
	var best: Dictionary = {}
	var worst: Dictionary = {}
	for r: Dictionary in rows:
		if int(r["level"]) == 3 and (best.is_empty() or int(r["level"]) > int(best["level"])):
			best = r
		if int(r["level"]) == 0 and worst.is_empty():
			worst = r
	var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	row.tooltip_text = raw_tip
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	if not best.is_empty():
		row.add_child(Cards.chip(tr("UI_WHY_BEST") % tr(str(best["f"]["name_key"])), CozyTheme.SAGE_SOFT, CozyTheme.FOREST))
	if not worst.is_empty():
		row.add_child(Cards.chip(tr("UI_WHY_WORST") % tr(str(worst["f"]["name_key"])), CozyTheme.TERRA_SOFT, CozyTheme.TERRA))
	if best.is_empty() and worst.is_empty():
		row.add_child(UiUtil.label(tr("RL_NOTHING_SPECIAL"), 13, CozyTheme.MUTED))
	return row


func _card(r: Dictionary) -> PanelContainer:
	var f: Dictionary = r["f"]
	var level: int = int(r["level"])
	var fill: Color = [CozyTheme.TERRA_SOFT, CozyTheme.CREAM_LIGHT, CozyTheme.SAGE_SOFT, CozyTheme.SAGE_SOFT][level]
	var ink: Color = [CozyTheme.TERRA, CozyTheme.MUTED, CozyTheme.FOREST, CozyTheme.FOREST][level]
	var card: PanelContainer = PanelContainer.new()
	card.add_theme_stylebox_override("panel", CozyTheme.box(fill, CozyTheme.RADIUS_CONTROL, CozyTheme.BORDER, 1, false, Vector2(10, 4)))
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.tooltip_text = tr("UI_WHY_RAW") % UiUtil.num(float(r["value"]), 2)
	var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	card.add_child(row)
	var ic: Control = UiUtil.icon(str(f["icon"]), 22, ink)
	ic.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(ic)
	var col: VBoxContainer = UiUtil.vbox(2)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	var top: HBoxContainer = UiUtil.hbox(6)
	var name: Label = UiUtil.label(tr(str(f["name_key"])), 13, CozyTheme.TEXT)
	name.add_theme_font_override("font", CozyTheme.strong_font())
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(name)
	top.add_child(_meter(level, ink))
	top.add_child(UiUtil.label(tr("UI_WHY_" + LEVELS[level]), 12, ink))
	col.add_child(top)
	var key: String = str(r["line"]) if not str(r["line"]).is_empty() else "RF_%s_%s" % [str(f["id"]).to_upper(), LEVELS[level]]
	var text: Label = UiUtil.wrapped(tr(key), 12, CozyTheme.TEXT, 200.0)
	col.add_child(text)
	return card


## Dört dilim; derece kadarı dolu.
func _meter(level: int, ink: Color) -> HBoxContainer:
	var m: HBoxContainer = UiUtil.hbox(2)
	m.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for i: int in 4:
		var seg: ColorRect = ColorRect.new()
		seg.custom_minimum_size = Vector2(10, 6)
		seg.color = ink if i <= level else Color(CozyTheme.BORDER, 0.8)
		m.add_child(seg)
	return m
