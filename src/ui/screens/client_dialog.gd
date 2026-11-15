class_name ClientDialog
extends Control
## Müşteri kartı (GDD 20 "Müşteri portföyü"): Müşteriler panelindeki kartın okuna basınca açılır. Logo, sektör ve
## ölçek, sözleşme, memnuniyet ve güven, yıllık bütçe, beklenen puan ve bu müşteriyle yapılan kampanyaların listesi
## (her biri raporunu açar). Kişilik GDD 6.1'de gizli olduğu için gösterilmez. Yalnızca okur.

const CHROME: float = 62.0  # kaydırmanın dışındaki alt satır
const METER_WIDTH: float = 220.0
const LABEL_WIDTH: float = 82.0

var _client: Dictionary
var _main: Control


func _init(client: Dictionary, main_screen: Control) -> void:
	_client = client
	_main = main_screen


func _ready() -> void:
	var data: GameData = DataDB.data
	var sim: Simulation = GameState.sim
	var col: VBoxContainer = UiUtil.modal_frame(self, UiUtil.dialog_size("client") - Vector2(0.0, CHROME), true, true)
	col.add_child(UiUtil.heading(tr("UI_CLIENT_TITLE"), "user"))
	var sat: float = float(_client["satisfaction"])
	var risk_line: float = data.balf("clients.risk_threshold")
	var tags: Array = [Cards.chip(tr("CONTRACT_" + str(_client["contract"]).to_upper()))]
	if sat < risk_line:
		tags.append(Cards.warn_chip(tr("UI_RISK_TAG")))
	col.add_child(Cards.header(Cards.art("brand_art", str(_client["name"]), 56.0, "building"), str(_client["name"]),
		"%s · %s" % [UiUtil.name_of(data.sectors, _client["sector"]), tr("SCALE_%d" % int(_client["scale"]))], tags))
	var hist: Array = _client["history"]
	var avg: String = "—"
	if not hist.is_empty():
		var sum: float = 0.0
		for h: Dictionary in hist:
			sum += float(h["score"])
		avg = UiUtil.score_text(sum / hist.size())
	col.add_child(Cards.facts([
		Cards.fact("coins", tr("UI_ANNUAL_BUDGET"), UiUtil.money(_client["annual_budget"])),
		Cards.fact("star", tr("UI_CLIENT_EXPECTATION"), "%s / 10" % UiUtil.score_text(sim.clients.expectation(_client, sim.state.clock.year()))),
		Cards.fact("chart-bar", tr("UI_CLIENT_AVG_SCORE"), avg)]))
	col.add_child(_meter(tr("UI_SATISFACTION"), sat, CozyTheme.NEGATIVE if sat < risk_line else CozyTheme.FOREST_LIGHT))
	col.add_child(_meter(tr("UI_TRUST_NAME"), float(_client["trust"]), CozyTheme.SAGE))
	if sat < risk_line:
		col.add_child(UiUtil.wrapped(tr("UI_CLIENT_RISK_NOTE") % int(risk_line), 13, CozyTheme.NEGATIVE))
	col.add_child(Cards.section(tr("UI_CLIENT_HISTORY"), tr("UI_CAMPAIGN_COUNT") % hist.size(), "speakerphone"))
	if hist.is_empty():
		col.add_child(UiUtil.label(tr("UI_CLIENT_NO_HISTORY"), 14, UiUtil.MUTED))
	for i: int in range(hist.size() - 1, -1, -1):
		col.add_child(_history_row(hist[i]))
	var frame: VBoxContainer = UiUtil.modal_outer(col)
	frame.add_child(HSeparator.new())
	var foot: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
	foot.add_child(UiUtil.spacer())
	var close: Button = UiUtil.button(tr("UI_CLOSE"), queue_free)
	close.theme_type_variation = "PrimaryButton"
	close.custom_minimum_size.x = 120.0
	foot.add_child(close)
	frame.add_child(foot)


func _meter(caption: String, value: float, color: Color) -> HBoxContainer:
	var m: HBoxContainer = Cards.meter(caption, value, color, METER_WIDTH)
	(m.get_child(0) as Label).custom_minimum_size.x = LABEL_WIDTH
	(m.get_child(0) as Label).add_theme_color_override("font_color", CozyTheme.TEXT)
	return m


## Geçmişteki bir kampanya: yıl, ad ve hedef, puan; raporu hâlâ duruyorsa "Raporu aç".
func _history_row(h: Dictionary) -> PanelContainer:
	var data: GameData = DataDB.data
	var card: PanelContainer = UiUtil.card()
	var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
	card.add_child(row)
	var year: Label = UiUtil.label(str(int(h["year"])), 14, CozyTheme.MUTED)
	year.custom_minimum_size.x = 44.0
	row.add_child(year)
	var camp: Dictionary = _finished(str(h["campaign"]))
	var name: String = tr("UI_UNTITLED")
	if not camp.is_empty() and not str(camp["setup"].get("name", "")).is_empty():
		name = str(camp["setup"]["name"])
	var mid: VBoxContainer = UiUtil.vbox(-2)
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title: Label = UiUtil.label(name, 14, CozyTheme.FOREST)
	title.add_theme_font_override("font", CozyTheme.strong_font())
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	mid.add_child(title)
	mid.add_child(UiUtil.label(UiUtil.name_of(data.objectives, h["objective"]), 12, CozyTheme.TEXT))
	row.add_child(mid)
	var score: float = float(h["score"])
	var s: Label = UiUtil.label(UiUtil.score_text(score), 20, UiUtil.score_color(score))
	s.add_theme_font_override("font", CozyTheme.title_font(700))
	row.add_child(s)
	if not camp.is_empty():
		var open: Button = UiUtil.button(tr("UI_OPEN_REPORT"), func() -> void: _main.call("open_modal", ReportDialog.new(camp)))
		Cards.compact(open)
		open.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(open)
	return card


func _finished(campaign_id: String) -> Dictionary:
	for camp: Dictionary in GameState.sim.state.finished:
		if str(camp["id"]) == campaign_id:
			return camp
	return {}
