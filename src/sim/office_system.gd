class_name OfficeSystem
extends RefCounted
## Ofis seviyeleri (GDD 12.1, 17 kilit açma özeti): kapasite, açılma koşulları, taşınma bedeli, kira.
## 3D ofis ve oda inşası M6'da; burada yalnızca sayılar var.

var data: GameData


func _init(game_data: GameData) -> void:
	data = game_data


func current(state: SimState) -> Dictionary:
	return data.office(state.office_level)


func next_office(state: SimState) -> Dictionary:
	return data.office(state.office_level + 1)


## Taşınma bedeli = koşuldaki nakit (enflasyona göre ölçeklenir, K-037).
func move_cost(state: SimState, office: Dictionary) -> float:
	return float(office["requirements"].get("cash", 0)) * Economy.inflation(data, state.clock.year())


## Sonraki ofisin koşulları: [{ "key", "need", "have", "ok" }]. Hepsi ok ise taşınılabilir.
func requirements(state: SimState) -> Array[Dictionary]:
	var office: Dictionary = next_office(state)
	var out: Array[Dictionary] = []
	if office.is_empty():
		return out
	var req: Dictionary = office["requirements"]
	var cost: float = move_cost(state, office)
	out.append({"key": "REQ_CASH", "need": cost, "have": state.cash, "ok": state.cash >= cost})
	var need_year: int = int(req.get("game_year", 1))
	var need_month: int = int(req.get("game_month", 1))
	var year_ok: bool = state.clock.game_year() > need_year \
		or (state.clock.game_year() == need_year and state.clock.month() >= need_month)
	out.append({"key": "REQ_YEAR", "need": need_year, "have": state.clock.game_year(), "ok": year_ok})
	var need_emp: int = int(req.get("employees", 0))
	if need_emp > 0:
		out.append({"key": "REQ_EMPLOYEES", "need": need_emp, "have": state.staff.size(), "ok": state.staff.size() >= need_emp})
	var need_rep: float = float(req.get("reputation", 0))
	if need_rep > 0.0:
		out.append({"key": "REQ_REPUTATION", "need": need_rep, "have": state.reputation, "ok": state.reputation >= need_rep})
	return out


func can_move(state: SimState) -> bool:
	var reqs: Array[Dictionary] = requirements(state)
	if reqs.is_empty():
		return false
	for r: Dictionary in reqs:
		if not bool(r["ok"]):
			return false
	return true


## Dönüş: "" veya hata anahtarı.
func move(state: SimState, economy: Economy) -> String:
	if not can_move(state):
		return "ERR_OFFICE_REQUIREMENTS"
	economy.pay(state, move_cost(state, next_office(state)))
	state.office_level += 1
	return ""


func monthly_rent(state: SimState) -> float:
	return float(current(state)["rent_1990"]) * Economy.inflation(data, state.clock.year())


func allowed_sizes(state: SimState) -> Array:
	return current(state)["allowed_sizes"]
