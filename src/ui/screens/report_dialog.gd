class_name ReportDialog
extends Control
## Kampanya raporu (GDD 7.10, 7.12, 20): sayarak yükselen puan, 4 yorum, KPI kartları, açıklama cümleleri, gelir.
## "Puan dökümü" (M2 ayar paneli) çarpanları gösterir; M2 sonrası kaldırılabilir (A-005).

var _camp: Dictionary
var _score_label: Label
var _breakdown: VBoxContainer
var _shown_score: float = 0.0


func _init(camp: Dictionary) -> void:
	_camp = camp


func _ready() -> void:
	var data: GameData = DataDB.data
	var setup: Dictionary = _camp["setup"]
	var report: Dictionary = _camp["report"]
	var score: float = float(report["score"])
	var col: VBoxContainer = UiUtil.modal_frame(self, Vector2(760.0, 640.0))
	var title: String = str(setup.get("name", "")) if not str(setup.get("name", "")).is_empty() else tr("UI_UNTITLED")
	col.add_child(UiUtil.heading(tr("UI_REPORT_TITLE") % [title, setup.get("client_name", "")]))
	col.add_child(UiUtil.label("%s · %s · %s · %s" % [UiUtil.name_of(data.objectives, setup["objective"]),
		UiUtil.name_of(data.audiences, setup["audience"]), UiUtil.name_of(data.tones, setup["tone"]),
		UiUtil.name_of(data.channels, Scoring.main_channel(setup["mix"]))], 14, UiUtil.WOOD))
	var top: HBoxContainer = UiUtil.hbox(24)
	_score_label = UiUtil.label("0.0", 72, UiUtil.score_color(score))
	top.add_child(_score_label)
	var reviews: VBoxContainer = UiUtil.vbox(4)
	reviews.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for r: Dictionary in _camp.get("reviews", []):
		reviews.add_child(UiUtil.wrapped("%s — %.1f: “%s”" % [tr(r["reviewer_key"]), float(r["score"]), tr(r["text_key"])],
			14, UiUtil.TEXT, 480.0))
	top.add_child(reviews)
	col.add_child(top)
	if bool(report.get("perfect", false)):
		col.add_child(UiUtil.label(tr("UI_PERFECT"), 20, UiUtil.MUSTARD))
	col.add_child(_kpi_cards())
	col.add_child(_channel_table())
	col.add_child(UiUtil.label(tr("UI_WHY"), 18, UiUtil.SAGE_DARK))
	var lines: Array = _camp.get("lines", [])
	if lines.is_empty():
		col.add_child(UiUtil.label(tr("RL_NOTHING_SPECIAL"), 15, UiUtil.MUTED))
	for line: Dictionary in lines:
		var good: bool = int(line["sign"]) > 0
		col.add_child(UiUtil.wrapped(("＋ " if good else "－ ") + tr(line["key"]), 15,
			UiUtil.SAGE_DARK if good else UiUtil.TERRACOTTA, 680.0))
	col.add_child(_money_block())
	var toggle: CheckButton = CheckButton.new()
	toggle.text = tr("UI_BREAKDOWN")
	toggle.toggled.connect(func(on: bool) -> void: _breakdown.visible = on)
	col.add_child(toggle)
	_breakdown = _breakdown_block(report)
	_breakdown.visible = false
	col.add_child(_breakdown)
	var buttons: HBoxContainer = UiUtil.hbox()
	buttons.add_child(UiUtil.spacer())
	buttons.add_child(UiUtil.button(tr("UI_CLOSE"), queue_free))
	col.add_child(buttons)
	var tween: Tween = create_tween()
	tween.tween_method(_set_shown_score, 0.0, score, data.balf("ui.score_count_seconds")) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _set_shown_score(v: float) -> void:
	_shown_score = v
	_score_label.text = "%.1f" % v


func _kpi_cards() -> GridContainer:
	var grid: GridContainer = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	var kpi: Dictionary = _camp.get("kpi", {})
	var setup: Dictionary = _camp["setup"]
	var ratio: float = float(_camp.get("kpi_ratio", 0.0))
	var cards: Array = [
		["KPI_REACH", UiUtil.big_number(float(kpi.get("reach", 0.0)))],
		["KPI_ENGAGEMENTS", UiUtil.big_number(float(kpi.get("engagements", 0.0)))],
		["KPI_CONVERSIONS", UiUtil.big_number(float(kpi.get("conversions", 0.0)))],
		["KPI_AWARENESS_LIFT", "+%%%.1f" % (100.0 * float(kpi.get("awareness_lift", 0.0)))],
		["KPI_ROI", "%%%d" % int(roundf(100.0 * float(kpi.get("roi", 0.0))))],
		["KPI_TARGET", "%s %s %%%d" % ["✓" if ratio >= 1.0 else "✗", tr("KPI_" + str(setup["kpi_type"]).to_upper()),
			int(roundf(100.0 * ratio))]],
	]
	for c: Array in cards:
		var card: PanelContainer = UiUtil.card()
		card.custom_minimum_size.x = 210.0
		var v: VBoxContainer = UiUtil.vbox(2)
		v.add_child(UiUtil.label(tr(c[0]), 13, UiUtil.WOOD))
		v.add_child(UiUtil.label(str(c[1]), 20))
		card.add_child(v)
		grid.add_child(card)
	if bool(kpi.get("viral", false)):
		var viral: PanelContainer = UiUtil.card()
		viral.add_child(UiUtil.label(tr("KPI_VIRAL"), 18, UiUtil.MUSTARD))
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
