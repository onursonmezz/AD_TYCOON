class_name ReportDialog
extends Control
## Kampanya raporu (GDD 7.10, 7.12, 20; UI-3 taslakları 01/02): üstte müşteri ve sayarak yükselen genel puan;
## dört sekme: Özet (KPI kartları, kanal tablosu, açıklama cümleleri), Yorumlar (dört yayın), Gelir ve kazanımlar,
## Puan dökümü (çarpanlar; ayar için, A-005).

const TABS: Array = [["summary", "UI_REP_SUMMARY"], ["reviews", "UI_REP_REVIEWS"], ["income", "UI_REP_INCOME"],
	["breakdown", "UI_REP_BREAKDOWN"]]
const KPI_ICONS: Array[String] = ["users-group", "star", "check", "speakerphone", "coins", "chart-bar"]

var _camp: Dictionary
var _score_label: Label
var _tabs_row: HBoxContainer
var _body: VBoxContainer
var _tab: String = "summary"
var _shown_score: float = 0.0


func _init(camp: Dictionary) -> void:
	_camp = camp


func _ready() -> void:
	var data: GameData = DataDB.data
	var setup: Dictionary = _camp["setup"]
	var report: Dictionary = _camp["report"]
	var score: float = float(report["score"])
	var col: VBoxContainer = UiUtil.modal_frame(self, Vector2(720.0, 380.0))
	col.add_child(UiUtil.heading(tr("UI_REPORT_HEADING"), "chart-bar"))
	var title: String = str(setup.get("name", "")) if not str(setup.get("name", "")).is_empty() else tr("UI_UNTITLED")
	var top: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
	var head: HBoxContainer = Cards.header(Cards.tile("speakerphone", 44.0, CozyTheme.TERRA_SOFT), str(setup.get("client_name", "")),
		"%s · %s" % [title, UiUtil.name_of(data.channels, Scoring.main_channel(setup["mix"]))])
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.tooltip_text = "%s · %s · %s" % [UiUtil.name_of(data.objectives, setup["objective"]),
		UiUtil.name_of(data.audiences, setup["audience"]), UiUtil.name_of(data.tones, setup["tone"])]
	top.add_child(head)
	if bool(report.get("perfect", false)):
		top.add_child(Cards.chip(tr("UI_PERFECT"), CozyTheme.GOLD, CozyTheme.TEXT))
	var pill: PanelContainer = PanelContainer.new()
	pill.add_theme_stylebox_override("panel", CozyTheme.box(CozyTheme.TERRA_SOFT, 999, CozyTheme.TERRA, 1, false,
		Vector2(CozyTheme.SPACE_L, 2)))
	pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var pill_row: HBoxContainer = UiUtil.hbox(4)
	pill.add_child(pill_row)
	_score_label = UiUtil.label("0.0", 24, UiUtil.score_color(score))
	_score_label.add_theme_font_override("font", CozyTheme.title_font(700))
	pill_row.add_child(_score_label)
	pill_row.add_child(UiUtil.label("/ 10", 14, CozyTheme.TERRA))
	top.add_child(pill)
	var caption: Label = UiUtil.label(tr("UI_REP_OVERALL"), 13, CozyTheme.TEXT)
	caption.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(caption)
	col.add_child(top)
	_tabs_row = UiUtil.hbox()
	col.add_child(_tabs_row)
	_body = UiUtil.vbox(CozyTheme.SPACE_S)
	col.add_child(_body)
	_show_tab("summary")
	# Alt satır kaydırmanın dışında: uzun raporda da Kapat hep görünür.
	var frame: VBoxContainer = col.get_parent().get_parent() as VBoxContainer
	frame.add_child(HSeparator.new())
	frame.add_child(_footer())
	var tween: Tween = create_tween()
	tween.tween_method(_set_shown_score, 0.0, score, data.balf("ui.score_count_seconds")) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if score >= float(data.sounds["juice"]["confetti_score"]):
		tween.tween_callback(func() -> void: Juice.confetti(self))


func _set_shown_score(v: float) -> void:
	_shown_score = v
	_score_label.text = "%.1f" % v


func _show_tab(id: String) -> void:
	_tab = id
	UiUtil.clear(_tabs_row)
	var seg: PanelContainer = UiUtil.segmented(TABS, _tab, _show_tab)
	seg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tabs_row.add_child(seg)
	UiUtil.clear(_body)
	match id:
		"summary":
			_body.add_child(_kpi_cards())
			_body.add_child(Cards.section(tr("UI_REP_CHANNELS"), "", "chart-bar"))
			_body.add_child(_channel_table())
			_body.add_child(Cards.section(tr("UI_WHY")))
			var lines: Array = _camp.get("lines", [])
			if lines.is_empty():
				_body.add_child(UiUtil.label(tr("RL_NOTHING_SPECIAL"), 14, UiUtil.MUTED))
			for line: Dictionary in lines:
				var good: bool = int(line["sign"]) > 0
				_body.add_child(UiUtil.wrapped(("＋ " if good else "－ ") + tr(line["key"]), 14,
					CozyTheme.TEXT if good else UiUtil.TERRACOTTA, 600.0))
		"reviews":
			_body.add_child(_reviews())
		"income":
			_body.add_child(_money_block())
		"breakdown":
			_body.add_child(_breakdown_block(_camp["report"]))


## Dört yayının puanı ve yorumu yan yana kartlarda (taslak 01).
func _reviews() -> HBoxContainer:
	var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	for r: Dictionary in _camp.get("reviews", []):
		var card: PanelContainer = UiUtil.card()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var v: VBoxContainer = UiUtil.vbox(4)
		card.add_child(v)
		var who: Label = UiUtil.wrapped(tr(r["reviewer_key"]), 13, CozyTheme.TEXT, 100.0)
		who.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		who.add_theme_font_override("font", CozyTheme.strong_font())
		v.add_child(who)
		v.add_child(HSeparator.new())
		var score: Label = UiUtil.label("%.1f" % float(r["score"]), 30, CozyTheme.TERRA)
		score.add_theme_font_override("font", CozyTheme.title_font(700))
		score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(score)
		var of: Label = UiUtil.label("/ 10", 12, CozyTheme.MUTED)
		of.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(of)
		var quote: Label = UiUtil.wrapped("“%s”" % tr(r["text_key"]), 13, CozyTheme.TEXT, 100.0)
		quote.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		quote.add_theme_font_override("font", MenuArt.italic(CozyTheme.body_font()))
		v.add_child(quote)
		row.add_child(card)
	return row


## Alt satır: müşteri memnuniyeti değişimi, kazanılan AP ve bilgi etiketleri, Tamam.
func _footer() -> HBoxContainer:
	var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	row.add_child(UiUtil.icon("users-group", 18, CozyTheme.TERRA))
	var delta: float = float(_camp.get("satisfaction_delta", 0.0))
	var sat: Label = UiUtil.label(tr("UI_SATISFACTION_DELTA") % ("%+.1f" % delta), 14,
		CozyTheme.FOREST if delta >= 0.0 else UiUtil.TERRACOTTA)
	sat.add_theme_font_override("font", CozyTheme.strong_font())
	row.add_child(sat)
	if _camp.has("ap"):
		row.add_child(Cards.chip(tr("UI_REP_AP") % float(_camp["ap"])))
		row.add_child(Cards.chip(tr("UI_REP_LEARNED") % int(_camp.get("learned", 0))))
	row.add_child(UiUtil.spacer())
	var ok: Button = UiUtil.button(tr("UI_CLOSE"), queue_free)
	ok.theme_type_variation = "PrimaryButton"
	ok.custom_minimum_size.x = 120.0
	row.add_child(ok)
	return row


func _kpi_cards() -> GridContainer:
	var grid: GridContainer = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", CozyTheme.SPACE_S)
	grid.add_theme_constant_override("v_separation", CozyTheme.SPACE_S)
	var kpi: Dictionary = _camp.get("kpi", {})
	var setup: Dictionary = _camp["setup"]
	var ratio: float = float(_camp.get("kpi_ratio", 0.0))
	var cards: Array = [
		["KPI_REACH", UiUtil.big_number(float(kpi.get("reach", 0.0)))],
		["KPI_ENGAGEMENTS", UiUtil.big_number(float(kpi.get("engagements", 0.0)))],
		["KPI_CONVERSIONS", UiUtil.big_number(float(kpi.get("conversions", 0.0)))],
		["KPI_AWARENESS_LIFT", UiUtil.percent(100.0 * float(kpi.get("awareness_lift", 0.0)), 1, true)],
		["KPI_ROI", UiUtil.percent(roundf(100.0 * float(kpi.get("roi", 0.0))))],
		["KPI_TARGET", "%s %s %s" % ["✓" if ratio >= 1.0 else "✗", tr("KPI_" + str(setup["kpi_type"]).to_upper()),
			UiUtil.percent(roundf(100.0 * ratio))]],
	]
	for i: int in cards.size():
		var card: PanelContainer = UiUtil.card()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_child(Cards.fact(KPI_ICONS[i], tr(cards[i][0]), str(cards[i][1])))
		grid.add_child(card)
	if bool(kpi.get("viral", false)):
		var viral: PanelContainer = UiUtil.card()
		viral.add_child(UiUtil.label(tr("KPI_VIRAL"), 16, UiUtil.MUSTARD))
		grid.add_child(viral)
	return grid


## Kanal bazında KPI (GDD 7.10, M4).
func _channel_table() -> GridContainer:
	var grid: GridContainer = GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 18)
	for key: String in ["UI_COL_CHANNEL", "UI_COL_SPEND", "UI_COL_IMPRESSIONS", "KPI_REACH", "KPI_ENGAGEMENTS", "KPI_CONVERSIONS"]:
		grid.add_child(UiUtil.label(tr(key), 13, UiUtil.WOOD))
	var budget: float = float(_camp["setup"]["media_budget"])
	var shares: Dictionary = {}
	for entry: Dictionary in _camp["setup"]["mix"]:
		shares[entry["channel"]] = float(entry["share"])
	for row: Dictionary in _camp.get("kpi", {}).get("per_channel", []):
		grid.add_child(UiUtil.label(UiUtil.name_of(DataDB.data.channels, row["channel"]), 14))
		grid.add_child(UiUtil.label(UiUtil.money(budget * float(shares.get(row["channel"], 0.0))), 14))
		for key: String in ["impressions", "reach", "engagements", "conversions"]:
			grid.add_child(UiUtil.label(UiUtil.big_number(float(row[key])), 14))
	return grid


func _money_block() -> VBoxContainer:
	var v: VBoxContainer = UiUtil.vbox(2)
	var income: Dictionary = _camp.get("income", {})
	v.add_child(UiUtil.wrapped(tr("UI_INCOME_LINE") % [UiUtil.money(float(income.get("fee", 0.0))),
		UiUtil.money(float(income.get("commission", 0.0))), UiUtil.money(float(income.get("bonus", 0.0)))], 15, UiUtil.TEXT, 680.0))
	if (_camp.get("print_results", []) as Array).size() > 0:
		v.add_child(UiUtil.label(tr("UI_PRODUCTION_MARGIN") % UiUtil.money(float(income.get("production_margin", 0.0))), 15))
	for r: Dictionary in _camp.get("print_results", []):
		var line: String = tr("UI_PRINT_RESULT") % [UiUtil.name_of(DataDB.data.channels, r["channel"]), UiUtil.money(r["cost"]),
			int(r["weeks"])]
		if bool(r["error"]):
			line += " · " + tr("UI_PRINT_REPRINTED")
		v.add_child(UiUtil.label(line, 14, UiUtil.TERRACOTTA if bool(r["error"]) else UiUtil.WOOD))
	for entry: Dictionary in _camp["setup"]["mix"]:
		var opts: Dictionary = entry.get("options", {})
		for o: Variant in opts.get("_outcomes", []):
			v.add_child(UiUtil.label("－ " + UiUtil.tr_fmt(str(o["note"]), [_camp["setup"].get("client_name", "")]), 14, UiUtil.TERRACOTTA))
		if opts.has("_press"):
			v.add_child(UiUtil.label("＋ " + tr("UI_GUERRILLA_PRESS"), 14, UiUtil.SAGE_DARK))
	if _camp.has("scandal"):
		v.add_child(UiUtil.label(tr("UI_REPORT_SCANDAL") % tr("UI_SCANDAL_" + str(_camp["scandal"]["choice"]).to_upper()), 14, UiUtil.TERRACOTTA))
	var late: int = int(_camp["setup"].get("late_weeks", 0))
	if late > 0:
		v.add_child(UiUtil.label(tr("UI_LATE_DELIVERY") % late, 15, UiUtil.TERRACOTTA))
	if _camp.has("ap"):
		v.add_child(UiUtil.label(tr("UI_REPORT_AP") % [float(_camp["ap"]), int(_camp.get("learned", 0))], 14, UiUtil.WOOD))
	var delta: float = float(_camp.get("satisfaction_delta", 0.0))
	v.add_child(UiUtil.label(tr("UI_SATISFACTION_DELTA") % ("%+.1f" % delta), 15,
		UiUtil.SAGE_DARK if delta >= 0.0 else UiUtil.TERRACOTTA))
	v.add_child(_satisfaction_parts())
	return v


## Memnuniyet değişiminin kalemleri (GDD 6.4): hangi kalem ne kadar ekledi/götürdü.
func _satisfaction_parts() -> VBoxContainer:
	var box: VBoxContainer = UiUtil.vbox(1)
	var parts: Dictionary = _camp.get("satisfaction_parts", {})
	if parts.is_empty():
		return box
	var score: float = float(_camp["report"]["score"])
	for key: String in ["quality", "kpi", "timing", "budget", "revisions", "account", "bold_match", "risks", "scandal", "office", "event"]:
		var value: float = float(parts.get(key, 0.0))
		if absf(value) < 0.05:
			continue
		var text: String = tr("SAT_" + key.to_upper())
		if key == "quality":
			text = tr("SAT_QUALITY") % [score, float(parts.get("expectation", 0.0))]
		elif key == "kpi":
			text = tr("SAT_KPI") % int(roundf(100.0 * float(_camp.get("kpi_ratio", 0.0))))
		elif key == "timing" and value < 0.0:
			text = tr("SAT_LATE") % int(_camp["setup"].get("late_weeks", 0))
		box.add_child(UiUtil.label("    %+.1f  %s" % [value, text], 13, UiUtil.SAGE_DARK if value >= 0.0 else UiUtil.TERRACOTTA))
	return box


func _breakdown_block(report: Dictionary) -> VBoxContainer:
	var v: VBoxContainer = UiUtil.vbox(2)
	var comb: Dictionary = report["combination"]
	var bal: Dictionary = report["balance"]
	var text: String = tr("BD_LINE1") % [comb["m"], comb["sh"], comb["sk"], comb["kn"], comb["tone"]] + "\n"
	text += tr("BD_LINE2") % [report["focus"]["f"], bal["b"], bal["ratio"], bal["ideal"], report["novelty"]["n"],
		report["synergy"]["synergy"]] + "\n"
	text += tr("BD_LINE3") % [report["s"], report["k"], report["t"], int(report["errors"])] + "\n"
	text += tr("BD_LINE4") % [report["raw"], report["target"], report["r"]]
	v.add_child(UiUtil.label(text, 13, UiUtil.MUTED))
	return v
