class_name FinancePanel
extends VBoxContainer
## Finans özeti (GDD 13.6, M2 sade sürüm): nakit, bekleyen tahsilat/ödemeler, bu yılın gelir-gideri.

var _grid: GridContainer


func _init() -> void:
	add_theme_constant_override("separation", 10)
	add_child(UiUtil.heading(tr("MENU_FINANCE")))
	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.add_theme_constant_override("h_separation", 40)
	_grid.add_theme_constant_override("v_separation", 8)
	add_child(_grid)
	add_child(UiUtil.wrapped(tr("UI_FINANCE_HINT"), 14, UiUtil.MUTED, 420.0))


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
	UiUtil.clear(_grid)
	for row: Array in rows:
		_grid.add_child(UiUtil.label(tr(row[0]), 16, UiUtil.WOOD))
		_grid.add_child(UiUtil.label(str(row[1]), 16))
