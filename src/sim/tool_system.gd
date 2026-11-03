class_name ToolSystem
extends RefCounted
## Yazılım, araçlar ve donanım (GDD 5.4, 12.4–12.5): alan başına araç seti, sürümler, lisans → abonelik (2013),
## AI araçlarının özgünlük bedeli, bilgisayar kuşağı. Üretim alan çarpanını SimState.tool_mults'tan okur.
## araç_çarpanı(alan) = 0.6 + Σ sahip_olunan_sürümün_katkısı × güncellik   (en fazla 1.6)

var data: GameData


func _init(game_data: GameData) -> void:
	data = game_data


func _t(key: String) -> Variant:
	return data.bal("tools." + key)


## Başlangıç: her alanın başlangıç aracı ve başlangıç yılının bilgisayar kuşağı.
func start(state: SimState) -> void:
	state.tools = {}
	for id: String in data.tool_ids:
		if bool(data.tools[id]["starter"]):
			state.tools[id] = {"version": 0, "sub": false}
	for id: String in data.hardware_ids:
		if int(data.hardware[id]["available_from"]) <= state.clock.year():
			state.hardware = id
	refresh(state)


# --- sürümler ---------------------------------------------------------------------

## Bu yıla kadar çıkmış son sürümün indeksi (-1: araç henüz yok).
func released_version(id: String, year: int) -> int:
	var v: int = -1
	var versions: Array = data.tools[id]["versions"]
	for i: int in versions.size():
		if int(versions[i][0]) <= year:
			v = i
	return v


## Bilgisayar kuşağının çalıştırabildiği en yeni sürüm (GDD 12.4).
func supported_version(state: SimState, id: String) -> int:
	var limit: int = mini(state.clock.year(), int(data.hardware[state.hardware]["max_tool_year"]))
	return released_version(id, limit)


func is_subscription_era(id: String, year: int) -> bool:
	return year >= int(data.tools[id]["subscription_from"])


func owned(state: SimState, id: String) -> bool:
	return state.tools.has(id)


func available(state: SimState) -> Array[String]:
	var out: Array[String] = []
	for id: String in data.tool_ids:
		if not bool(data.tools[id]["starter"]) and released_version(id, state.clock.year()) >= 0:
			out.append(id)
	return out


func license_cost(state: SimState, id: String) -> float:
	return float(data.tools[id]["license_1990"]) * Economy.inflation(data, state.clock.year())


func update_cost(state: SimState, id: String) -> float:
	return license_cost(state, id) * float(_t("update_cost_ratio"))


## Kişi başı aylık abonelik (çalışan sayısı kadar koltuk).
func seat_cost(state: SimState, id: String) -> float:
	return float(data.tools[id]["monthly_seat_1990"]) * Economy.inflation(data, state.clock.year())


func monthly_cost(state: SimState) -> float:
	var total: float = 0.0
	for id: String in state.tools:
		if bool(state.tools[id]["sub"]):
			total += seat_cost(state, id) * state.staff.size()
	return total


# --- oyuncu eylemleri -------------------------------------------------------------

## Satın alma: abonelik döneminde aylık koltukla, öncesinde tek seferlik lisansla. Dönüş: "" veya hata anahtarı.
func buy(state: SimState, economy: Economy, id: String) -> String:
	if not data.tools.has(id) or bool(data.tools[id]["starter"]) or released_version(id, state.clock.year()) < 0:
		return "ERR_TOOL_NA"
	if owned(state, id):
		return "ERR_TOOL_OWNED"
	var v: int = supported_version(state, id)
	if v < 0:
		return "ERR_HARDWARE"
	if is_subscription_era(id, state.clock.year()):
		state.tools[id] = {"version": v, "sub": true}
	else:
		if state.cash < license_cost(state, id):
			return "ERR_NO_CASH"
		economy.pay(state, license_cost(state, id))
		state.tools[id] = {"version": v, "sub": false}
	refresh(state)
	return ""


## Lisanslı aracı yeni sürüme yükseltme (lisansın %60'ı). Abonelik dönemi başladıysa lisans donar: abonelik gerekir.
func update(state: SimState, economy: Economy, id: String) -> String:
	if not owned(state, id) or bool(state.tools[id]["sub"]) or bool(data.tools[id]["starter"]):
		return "ERR_TOOL_NA"
	if is_subscription_era(id, state.clock.year()):
		return "ERR_TOOL_SUB_ONLY"
	var v: int = supported_version(state, id)
	if v <= int(state.tools[id]["version"]):
		return "ERR_HARDWARE" if released_version(id, state.clock.year()) > int(state.tools[id]["version"]) else "ERR_TOOL_LATEST"
	if state.cash < update_cost(state, id):
		return "ERR_NO_CASH"
	economy.pay(state, update_cost(state, id))
	state.tools[id]["version"] = v
	refresh(state)
	return ""


## Lisansı aboneliğe çevirir: hep son (desteklenen) sürüm, her ay koltuk başı ücret.
func subscribe(state: SimState, id: String) -> String:
	if not owned(state, id) or bool(state.tools[id]["sub"]) or not is_subscription_era(id, state.clock.year()):
		return "ERR_TOOL_NA"
	state.tools[id] = {"version": maxi(int(state.tools[id]["version"]), supported_version(state, id)), "sub": true}
	refresh(state)
	return ""


## Abonelik iptali: araç bırakılır.
func cancel(state: SimState, id: String) -> bool:
	if not owned(state, id) or not bool(state.tools[id]["sub"]):
		return false
	state.tools.erase(id)
	refresh(state)
	return true


func hardware_cost(state: SimState, hw_id: String) -> float:
	return float(data.hardware[hw_id]["cost_per_seat_1990"]) * Economy.inflation(data, state.clock.year()) \
		* maxi(1, state.staff.size())


func buy_hardware(state: SimState, economy: Economy, hw_id: String) -> String:
	if not data.hardware.has(hw_id) or int(data.hardware[hw_id]["available_from"]) > state.clock.year():
		return "ERR_HARDWARE_NA"
	if data.hardware_ids.find(hw_id) <= data.hardware_ids.find(state.hardware):
		return "ERR_HARDWARE_NA"
	if state.cash < hardware_cost(state, hw_id):
		return "ERR_NO_CASH"
	economy.pay(state, hardware_cost(state, hw_id))
	state.hardware = hw_id
	refresh(state)
	return ""


# --- zaman -----------------------------------------------------------------------

## Yıl başı: abonelikler güncellenir; yeni araç, yeni sürüm ve abonelik dönemi bildirimleri.
## Dönüş: [{key, args, kind}]
func yearly(state: SimState) -> Array[Dictionary]:
	var notes: Array[Dictionary] = []
	var year: int = state.clock.year()
	for id: String in data.tool_ids:
		var t: Dictionary = data.tools[id]
		if bool(t["starter"]):
			continue
		var released: int = released_version(id, year)
		if released >= 0 and int(t["versions"][released][0]) == year:
			if released == 0:
				notes.append({"key": "NOTE_TOOL_NEW", "args": [t["name_key"]], "kind": "info"})
			elif owned(state, id) and not bool(state.tools[id]["sub"]):
				notes.append({"key": "NOTE_TOOL_UPDATE", "args": [t["name_key"]], "kind": "info"})
		if owned(state, id) and not bool(state.tools[id]["sub"]) and int(t["subscription_from"]) == year:
			notes.append({"key": "NOTE_TOOL_SUBSCRIPTION", "args": [t["name_key"]], "kind": "info"})
		if owned(state, id) and bool(state.tools[id]["sub"]):
			state.tools[id]["version"] = maxi(int(state.tools[id]["version"]), supported_version(state, id))
	for id: String in data.hardware_ids:
		if int(data.hardware[id]["available_from"]) == year:
			notes.append({"key": "NOTE_HARDWARE_NEW", "args": [data.hardware[id]["name_key"]], "kind": "info"})
	refresh(state)
	return notes


# --- çarpanlar ---------------------------------------------------------------------

func area_mult(state: SimState, area: String) -> float:
	var year: int = state.clock.year()
	var fresh: Array = _t("freshness")
	var total: float = float(_t("base"))
	for id: String in state.tools:
		var t: Dictionary = data.tools[id]
		if t["area"] != area:
			continue
		var v: int = int(state.tools[id]["version"])
		var behind: int = maxi(0, released_version(id, year) - v)
		total += float(t["versions"][v][1]) * float(fresh[mini(behind, fresh.size() - 1)])
	return minf(total, float(_t("max")))


func ai_penalty(state: SimState) -> float:
	var p: float = 0.0
	for id: String in state.tools:
		p += float(data.tools[id]["ai_penalty"])
	return p


## Alan çarpanları ve AI bedeli SimState'e yazılır (kaydedilmez, yüklemede yeniden hesaplanır).
func refresh(state: SimState) -> void:
	var mults: Dictionary = {}
	for area: Variant in _t("areas"):
		mults[area] = area_mult(state, str(area))
	state.tool_mults = mults
	state.ai_penalty = ai_penalty(state)


## Odak alanının araç çarpanı (üretim, GDD 7.5 "araç").
static func focus_mult(data_ref: GameData, state: SimState, focus_id: String) -> float:
	return float(state.tool_mults.get(str(data_ref.bal("tools.focus_area").get(focus_id, "")), 1.0))
