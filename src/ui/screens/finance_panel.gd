class_name FinancePanel
extends VBoxContainer
## Finans özeti (GDD 13.6, M2 sade sürüm): nakit, bekleyen tahsilat/ödemeler, dönem gelir-gideri;
## banka kredisi (GDD 13.5, M10). UI-2d (Cozy Refined referansı):
## sekmeler (bu ay / son 3 ay / bu yıl), nakit-gelir-gider şeridi, ikonlu ödeme satırları, son 6 ay gelir grafiği,
## kredi ve matbaa kartları. Dönem gelir-gideri SimState.finance_months kaydından okunur.

const PERIODS: Array = [["month", "UI_FIN_TAB_MONTH"], ["quarter", "UI_FIN_TAB_QUARTER"], ["year", "UI_FIN_SECTION_YEAR"]]
const CHART_MONTHS: int = 6

var _period: String = "month"
var _tabs: HBoxContainer
var _summary: HBoxContainer
var _rows: VBoxContainer
var _chart: FinanceChart
var _suppliers: VBoxContainer
var _loan: VBoxContainer
var _sig: String = ""


func _init() -> void:
	add_theme_constant_override("separation", CozyTheme.SPACE_M)
	add_child(UiUtil.heading(tr("MENU_FINANCE")))
	var top: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
	top.add_child(UiUtil.wrapped(tr("UI_FINANCE_HINT"), 13, CozyTheme.MUTED, 240.0))
	_tabs = UiUtil.hbox(0)
	top.add_child(_tabs)
	add_child(top)
	var summary_card: PanelContainer = _card()
	_summary = UiUtil.hbox(CozyTheme.SPACE_M)
	summary_card.add_child(_summary)
	var mid: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
	add_child(mid)
	var rows_card: PanelContainer = _card(mid)
	rows_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows_card.size_flags_stretch_ratio = 1.6
	_rows = UiUtil.vbox(CozyTheme.SPACE_S)
	rows_card.add_child(_rows)
	var chart_card: PanelContainer = _card(mid)
	chart_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var chart_col: VBoxContainer = UiUtil.vbox(4)
	chart_card.add_child(chart_col)
	chart_col.add_child(UiUtil.label(tr("UI_FIN_CHART"), 13, CozyTheme.MUTED))
	_chart = FinanceChart.new()
	_chart.custom_minimum_size = Vector2(150.0, 120.0)
	_chart.size_flags_vertical = Control.SIZE_EXPAND_FILL
	chart_col.add_child(_chart)
	_loan = _titled_card("building-bank", tr("UI_LOAN_TITLE"))
	_suppliers = _titled_card("receipt", tr("UI_SUPPLIERS"))


func _card(parent: Control = self) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.theme_type_variation = "Card"
	parent.add_child(card)
	return card


## İkonlu başlıklı kart; içerik kutusunu döndürür.
func _titled_card(icon_name: String, title: String) -> VBoxContainer:
	var col: VBoxContainer = UiUtil.vbox(CozyTheme.SPACE_S)
	_card().add_child(col)
	var head: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	head.add_child(UiUtil.icon(icon_name, 26, CozyTheme.FOREST))
	var l: Label = Label.new()
	l.text = title
	l.theme_type_variation = "CardHeading"
	head.add_child(l)
	col.add_child(head)
	var body: VBoxContainer = UiUtil.vbox(6)
	col.add_child(body)
	return body


func _tab_buttons() -> void:
	UiUtil.clear(_tabs)
	_tabs.add_child(UiUtil.segmented(PERIODS, _period, func(id: String) -> void:
		_period = id
		refresh()))


## Seçili dönemin (gelir, gider)'i: bu ay ve son 3 ay aylık kayıttan, bu yıl yıl toplamından.
func _period_totals(s: SimState) -> Vector2:
	if _period == "year":
		return Vector2(s.year_income, s.year_expense)
	var now: int = s.clock.year() * 12 + s.clock.month() - 1
	var span: int = 1 if _period == "month" else 3
	var total: Vector2 = Vector2.ZERO
	for rec: Dictionary in s.finance_months:
		if int(rec["m"]) > now - span:
			total += Vector2(float(rec["in"]), float(rec["out"]))
	return total


## Son n ayın gelirleri (kaydı olmayan ay 0), eskiden yeniye.
static func _recent_income(s: SimState, n: int) -> Array[float]:
	var now: int = s.clock.year() * 12 + s.clock.month() - 1
	var by_month: Dictionary = {}
	for rec: Dictionary in s.finance_months:
		by_month[int(rec["m"])] = float(rec["in"])
	var out: Array[float] = []
	for k: int in range(now - n + 1, now + 1):
		out.append(float(by_month.get(k, 0.0)))
	return out


func _summary_item(icon_name: String, icon_color: Color, name: String, value: String, value_color: Color) -> void:
	var item: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item.add_child(UiUtil.icon(icon_name, 30, icon_color))
	var col: VBoxContainer = UiUtil.vbox(0)
	col.add_child(UiUtil.label(name, 13, CozyTheme.MUTED))
	var v: Label = UiUtil.label(value, 22, value_color)
	v.add_theme_font_override("font", CozyTheme.strong_font(800))
	col.add_child(v)
	item.add_child(col)
	if _summary.get_child_count() > 0:
		_summary.add_child(VSeparator.new())
	_summary.add_child(item)


func _row(icon_name: String, name: String, value: String, color: Color = CozyTheme.TEXT) -> void:
	var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	row.add_child(UiUtil.icon(icon_name, 20, CozyTheme.FOREST_LIGHT))
	var n: Label = UiUtil.label(name, 15, CozyTheme.TEXT)
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(n)
	var v: Label = UiUtil.label(value, 15, color)
	v.add_theme_font_override("font", CozyTheme.strong_font(760))
	row.add_child(v)
	_rows.add_child(row)


## Matbaalarla ilişki puanı ve aktif anlaşmalar (GDD 10.3).
func _refresh_suppliers(s: SimState) -> void:
	UiUtil.clear(_suppliers)
	var data: GameData = DataDB.data
	for id: String in data.supplier_ids:
		_suppliers.add_child(UiUtil.label(tr("UI_SUPPLIER_LINE") % [tr(data.suppliers[id]["name_key"]),
			int(GameState.sim.suppliers.relationship(s, id))], 15))
	for deal: Dictionary in s.supplier_deals:
		_suppliers.add_child(UiUtil.label("✓ %s: %s" % [tr(data.suppliers[deal["supplier"]]["name_key"]),
			UiUtil.supplier_offer_text(deal)], 15, CozyTheme.POSITIVE))


func refresh() -> void:
	var s: SimState = GameState.sim.state
	var data: GameData = DataDB.data
	_tab_buttons()
	var receivable: float = 0.0
	var next_due: int = -1
	for r: Dictionary in s.receivables:
		receivable += float(r["amount"])
		if next_due < 0 or int(r["due_week"]) < next_due:
			next_due = int(r["due_week"])
	var payable: float = 0.0
	for p: Dictionary in s.payables:
		payable += float(p["amount"])
	var monthly: float = data.balf("cashflow.monthly_base_cost") * Economy.inflation(data, s.clock.year())
	var totals: Vector2 = _period_totals(s)
	UiUtil.clear(_summary)
	_summary_item("wallet", CozyTheme.FOREST, tr("UI_FIN_CASH"), UiUtil.money(s.cash),
		CozyTheme.NEGATIVE if s.cash < 0.0 else CozyTheme.TEXT)
	_summary_item("arrow-up", CozyTheme.POSITIVE, tr("UI_FIN_INCOME"), UiUtil.money(totals.x), CozyTheme.TEXT)
	_summary_item("arrow-down", CozyTheme.NEGATIVE, tr("UI_FIN_EXPENSE"), UiUtil.money(totals.y), CozyTheme.TEXT)
	UiUtil.clear(_rows)
	_row("receipt", tr("UI_FIN_RECEIVABLE"), "%s (%d)" % [UiUtil.money(receivable), s.receivables.size()])
	_row("calendar", tr("UI_FIN_NEXT_DUE"), tr("UI_WEEKS") % (next_due - s.clock.week_index) if next_due >= 0 else "—")
	_row("speakerphone", tr("UI_FIN_PAYABLE"), "%s (%d)" % [UiUtil.money(payable), s.payables.size()])
	var projected: float = s.cash + receivable - payable
	_row("building-bank", tr("UI_FIN_PROJECTED"), UiUtil.money(projected),
		CozyTheme.NEGATIVE if projected < 0.0 else CozyTheme.TEXT)
	_row("building", tr("UI_FIN_MONTHLY"), UiUtil.money(monthly))
	var profit: float = s.year_income - s.year_expense
	_row("chart-bar", tr("UI_FIN_YEAR_PROFIT"), UiUtil.money(profit),
		CozyTheme.NEGATIVE if profit < 0.0 else (CozyTheme.POSITIVE if profit > 0.0 else CozyTheme.TEXT))
	_row("alert-triangle", tr("UI_FIN_RED_WEEKS"), "%d / %d" % [s.red_weeks, data.bali("cashflow.red_weeks_to_bankrupt")],
		CozyTheme.NEGATIVE if s.red_weeks > 0 else CozyTheme.TEXT)
	_chart.values = _recent_income(s, CHART_MONTHS)
	_chart.queue_redraw()
	_refresh_suppliers(s)
	_refresh_loan(s)


## Kredi: varsa kalan borç, taksit ve erken kapatma; yoksa tutar ve vade seçip çekme (taksit önizlemesiyle).
func _refresh_loan(s: SimState) -> void:
	var loans: LoanSystem = GameState.sim.loans
	var sig: String = "%s|%d" % [str(s.loan), int(loans.max_amount(s) / 1000.0)]
	if sig == _sig:
		return
	_sig = sig
	UiUtil.clear(_loan)
	if loans.has_loan(s):
		_loan.add_child(UiUtil.wrapped(tr("UI_LOAN_ACTIVE") % [UiUtil.money(float(s.loan["balance"])),
			UiUtil.money(float(s.loan["monthly"])), int(s.loan["months_left"])], 15))
		var b: Button = UiUtil.button(tr("UI_LOAN_REPAY") % UiUtil.money(loans.repay_cost(s)), func() -> void: _run(LoanActionCommand.new("repay")))
		b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		_loan.add_child(b)
		return
	var max_amount: float = loans.max_amount(s)
	_loan.add_child(UiUtil.wrapped(tr("UI_LOAN_HINT") % [UiUtil.money(max_amount),
		UiUtil.percent(100.0 * DataDB.data.balf("loans.annual_interest"))], 14, CozyTheme.MUTED))
	var steps: Array = DataDB.data.bal("loans.amount_steps")
	var terms: Array = DataDB.data.bal("loans.terms_months")
	var amount_pick: OptionButton = OptionButton.new()
	for st: Variant in steps:
		amount_pick.add_item(UiUtil.money(max_amount * float(st)))
	amount_pick.select(steps.size() - 1)
	amount_pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var term_pick: OptionButton = OptionButton.new()
	for t: Variant in terms:
		term_pick.add_item(tr("UI_LOAN_TERM") % int(t))
	term_pick.select(1)
	term_pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var preview: Label = UiUtil.label("", 14, CozyTheme.MUTED)
	var update: Callable = func(_i: int = 0) -> void:
		preview.text = tr("UI_LOAN_PREVIEW") % UiUtil.money(GameState.sim.loans.monthly_payment(
			max_amount * float(steps[amount_pick.selected]), int(terms[term_pick.selected])))
	amount_pick.item_selected.connect(update)
	term_pick.item_selected.connect(update)
	update.call()
	var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	row.add_child(amount_pick)
	row.add_child(term_pick)
	var take: Button = UiUtil.button(tr("UI_LOAN_TAKE"), func() -> void:
		_run(LoanActionCommand.new("take", max_amount * float(steps[amount_pick.selected]), int(terms[term_pick.selected]))))
	take.theme_type_variation = "PrimaryButton"
	take.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(take)
	_loan.add_child(row)
	_loan.add_child(preview)


func _run(cmd: RefCounted) -> void:
	var err: String = GameState.execute(cmd)
	if not err.is_empty():
		EventBus.notification.emit(err, [], "bad")
	_sig = ""
	refresh()
