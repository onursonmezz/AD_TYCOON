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


func _money_block() -> VBoxContainer:
	var v: VBoxContainer = UiUtil.vbox(2)
	var income: Dictionary = _camp.get("income", {})
	v.add_child(UiUtil.label(tr("UI_INCOME_LINE") % [UiUtil.money(float(income.get("fee", 0.0))),
		UiUtil.money(float(income.get("commission", 0.0))), UiUtil.money(float(income.get("bonus", 0.0)))], 15))
	var delta: float = float(_camp.get("satisfaction_delta", 0.0))
	v.add_child(UiUtil.label(tr("UI_SATISFACTION_DELTA") % ("%+.1f" % delta), 15,
		UiUtil.SAGE_DARK if delta >= 0.0 else UiUtil.TERRACOTTA))
	return v


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
