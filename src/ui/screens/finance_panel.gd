class_name FinancePanel
extends VBoxContainer
## Finans özeti (GDD 13.6, M2 sade sürüm): nakit, bekleyen tahsilat/ödemeler, bu yılın gelir-gideri;
## banka kredisi (GDD 13.5, M10).

var _grid: GridContainer
var _suppliers: VBoxContainer
var _loan: VBoxContainer
var _sig: String = ""


func _init() -> void:
	add_theme_constant_override("separation", 10)
	add_child(UiUtil.heading(tr("MENU_FINANCE")))
	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.add_theme_constant_override("h_separation", 40)
	_grid.add_theme_constant_override("v_separation", 8)
	add_child(_grid)
	add_child(UiUtil.wrapped(tr("UI_FINANCE_HINT"), 14, UiUtil.MUTED, 420.0))
	add_child(UiUtil.label(tr("UI_LOAN_TITLE"), 18, UiUtil.SAGE_DARK))
	_loan = UiUtil.vbox(6)
	add_child(_loan)
	add_child(UiUtil.label(tr("UI_SUPPLIERS"), 18, UiUtil.SAGE_DARK))
	_suppliers = UiUtil.vbox(4)
	add_child(_suppliers)


## Matbaalarla ilişki puanı ve aktif anlaşmalar (GDD 10.3).
func _refresh_suppliers(s: SimState) -> void:
	UiUtil.clear(_suppliers)
	var data: GameData = DataDB.data
	for id: String in data.supplier_ids:
		_suppliers.add_child(UiUtil.label(tr("UI_SUPPLIER_LINE") % [tr(data.suppliers[id]["name_key"]),
			int(GameState.sim.suppliers.relationship(s, id))], 14))
	for deal: Dictionary in s.supplier_deals:
		_suppliers.add_child(UiUtil.label("✓ %s: %s" % [tr(data.suppliers[deal["supplier"]]["name_key"]),
			UiUtil.supplier_offer_text(deal)], 14, UiUtil.SAGE_DARK))


func refresh() -> void:
	var s: SimState = GameState.sim.state
	var data: GameData = DataDB.data
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
	var rows: Array = [
		["UI_FIN_CASH", UiUtil.money(s.cash)],
		["UI_FIN_RECEIVABLE", "%s (%d)" % [UiUtil.money(receivable), s.receivables.size()]],
		["UI_FIN_NEXT_DUE", tr("UI_WEEKS") % (next_due - s.clock.week_index) if next_due >= 0 else "—"],
		["UI_FIN_PAYABLE", "%s (%d)" % [UiUtil.money(payable), s.payables.size()]],
		["UI_FIN_PROJECTED", UiUtil.money(s.cash + receivable - payable)],
		["UI_FIN_YEAR_INCOME", UiUtil.money(s.year_income)],
		["UI_FIN_YEAR_EXPENSE", UiUtil.money(s.year_expense)],
		["UI_FIN_YEAR_PROFIT", UiUtil.money(s.year_income - s.year_expense)],
		["UI_FIN_MONTHLY", UiUtil.money(monthly)],
		["UI_FIN_RED_WEEKS", "%d / %d" % [s.red_weeks, data.bali("cashflow.red_weeks_to_bankrupt")]],
	]
	_refresh_suppliers(s)
	_refresh_loan(s)
	UiUtil.clear(_grid)
	for row: Array in rows:
		_grid.add_child(UiUtil.label(tr(row[0]), 16, UiUtil.WOOD))
		_grid.add_child(UiUtil.label(str(row[1]), 16))


## Kredi: varsa kalan borç, taksit ve erken kapatma; yoksa tutar ve vade seçip çekme (taksit önizlemesiyle).
func _refresh_loan(s: SimState) -> void:
	var loans: LoanSystem = GameState.sim.loans
	var sig: String = "%s|%d" % [str(s.loan), int(loans.max_amount(s) / 1000.0)]
	if sig == _sig:
		return
	_sig = sig
	UiUtil.clear(_loan)
	if loans.has_loan(s):
		_loan.add_child(UiUtil.label(tr("UI_LOAN_ACTIVE") % [UiUtil.money(float(s.loan["balance"])),
			UiUtil.money(float(s.loan["monthly"])), int(s.loan["months_left"])], 15))
		var b: Button = UiUtil.button(tr("UI_LOAN_REPAY") % UiUtil.money(loans.repay_cost(s)), func() -> void: _run(LoanActionCommand.new("repay")))
		_loan.add_child(b)
		return
	var max_amount: float = loans.max_amount(s)
	_loan.add_child(UiUtil.wrapped(tr("UI_LOAN_HINT") % [UiUtil.money(max_amount),
		UiUtil.percent(100.0 * DataDB.data.balf("loans.annual_interest"))], 14, UiUtil.MUTED, 420.0))
	var steps: Array = DataDB.data.bal("loans.amount_steps")
	var terms: Array = DataDB.data.bal("loans.terms_months")
	var amount_pick: OptionButton = OptionButton.new()
	for st: Variant in steps:
		amount_pick.add_item(UiUtil.money(max_amount * float(st)))
	amount_pick.select(steps.size() - 1)
	var term_pick: OptionButton = OptionButton.new()
	for t: Variant in terms:
		term_pick.add_item(tr("UI_LOAN_TERM") % int(t))
	term_pick.select(1)
	var preview: Label = UiUtil.label("", 14, UiUtil.WOOD)
	var update: Callable = func(_i: int = 0) -> void:
		preview.text = tr("UI_LOAN_PREVIEW") % UiUtil.money(GameState.sim.loans.monthly_payment(
			max_amount * float(steps[amount_pick.selected]), int(terms[term_pick.selected])))
	amount_pick.item_selected.connect(update)
	term_pick.item_selected.connect(update)
	update.call()
	var row: HBoxContainer = UiUtil.hbox()
	row.add_child(amount_pick)
	row.add_child(term_pick)
	row.add_child(UiUtil.button(tr("UI_LOAN_TAKE"), func() -> void:
		_run(LoanActionCommand.new("take", max_amount * float(steps[amount_pick.selected]), int(terms[term_pick.selected])))))
	_loan.add_child(row)
	_loan.add_child(preview)


func _run(cmd: RefCounted) -> void:
	var err: String = GameState.execute(cmd)
	if not err.is_empty():
		EventBus.notification.emit(err, [], "bad")
	_sig = ""
	refresh()
