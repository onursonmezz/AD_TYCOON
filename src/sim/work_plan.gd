class_name WorkPlan
extends RefCounted
## Görev panosu (K-118): her fazda ekipteki her çalışan zamanını fazın üç odak alanına böler (0..1 paylar).
## Kişinin yükü = paylarının toplamı; 1'i (%100) geçerse kişi başına verim düşer, enerji ve hata artar.
## Alanların odak payı ekibin o alana verdiği toplam emektir (kaydırıcılar bundan hesaplanır).
## Plan yoksa (botlar, eski kayıtlar) herkes faz kaydırıcılarının paylarıyla çalışır: eski davranış.
## Kayıt: campaign.setup.plan = [{emp_id: [a0, a1, a2]}, {…}, {…}]. Sayılar balance.json "workload".


static func _w(data: GameData, key: String) -> float:
	return data.balf("workload." + key)


## Fazın planı; yoksa {}.
static func phase_plan(campaign: Dictionary, phase: int) -> Dictionary:
	var plan: Array = campaign["setup"].get("plan", [])
	return plan[phase] if phase < plan.size() and plan[phase] is Dictionary else {}


static func load_of_alloc(alloc: Array) -> float:
	var total: float = 0.0
	for v: Variant in alloc:
		total += float(v)
	return total


## Çalışanın o fazdaki yükü (plan yoksa ekipteyse 1.0, değilse 0).
static func load_of(campaign: Dictionary, phase: int, emp_id: String) -> float:
	var plan: Dictionary = phase_plan(campaign, phase)
	if plan.is_empty():
		return 1.0 if (campaign["setup"].get("team", []) as Array).has(emp_id) else 0.0
	return load_of_alloc(plan.get(emp_id, []))


## Kişi başına verim: yük ≤ 1 → 1; üstünde yük^(−overload_exp). Toplam üretim yine artar ama azalan getiriyle.
static func overload_mult(data: GameData, load: float) -> float:
	return 1.0 if load <= 1.0 else pow(load, -_w(data, "overload_exp"))


## Günlük enerji kaybı çarpanı: yük kadar (fazlası daha hızlı yorar); görevsiz ekip üyesi dinlenir (0).
static func energy_mult(data: GameData, load: float) -> float:
	if load <= 1.0:
		return load
	return pow(load, _w(data, "overload_energy_exp"))


## Hata zarı çarpanı: az çalışan az hata yapar; %100 üstünde ek risk.
static func error_mult(data: GameData, load: float) -> float:
	return load * (1.0 + maxf(0.0, load - 1.0) * _w(data, "overload_error"))


## Planın alanlara düşen emeğinden odak payları (toplam 1). Emek yoksa eşit.
static func shares_of(plan: Dictionary) -> Array:
	var sums: Array = [0.0, 0.0, 0.0]
	for id: Variant in plan:
		var alloc: Array = plan[id]
		for i: int in 3:
			sums[i] = float(sums[i]) + float(alloc[i])
	var total: float = float(sums[0]) + float(sums[1]) + float(sums[2])
	if total <= 0.0:
		return [1.0 / 3.0, 1.0 / 3.0, 1.0 - 2.0 / 3.0]
	var out: Array = [float(sums[0]) / total, float(sums[1]) / total, 0.0]
	out[2] = 1.0 - float(out[0]) - float(out[1])
	return out


## Plan doğrulama. Dönüş: "" ya da hata anahtarı.
static func validate(data: GameData, plan: Dictionary, team: Array) -> String:
	var total: float = 0.0
	for id: Variant in plan:
		if not team.has(str(id)):
			return "ERR_PLAN_MEMBER"
		var alloc: Array = plan[id]
		if alloc.size() != 3:
			return "ERR_PLAN"
		for v: Variant in alloc:
			if float(v) < 0.0 or float(v) > 1.0:
				return "ERR_PLAN"
		var load: float = load_of_alloc(alloc)
		if load > _w(data, "max_load") + 0.0001:
			return "ERR_PLAN_OVERLOAD"
		total += load
	if total <= 0.0:
		return "ERR_PLAN_EMPTY"
	return ""


## Otomatik dağıtım: ekip 3'ten azsa herkes zamanını üç alana kaydırıcı paylarıyla böler; daha büyük ekipte herkes
## %100'ünü en güçlü olduğu alana verir (stat × uzmanlık), boş kalan alan olursa en uygun kişi oraya kaydırılır.
static func auto(data: GameData, state: SimState, campaign: Dictionary, phase: int) -> Dictionary:
	var ids: Array[String] = data.focus_ids_of_phase(phase)
	var sliders: Array = campaign["setup"]["sliders"][phase]
	var team: Array[String] = []
	for id: Variant in campaign["setup"].get("team", []):
		var emp: Dictionary = state.staff.get(str(id), {})
		if not emp.is_empty() and Employee.is_available(emp, state.clock.week_index):
			team.append(str(id))
	var plan: Dictionary = {}
	if team.size() < 3:
		for id: String in team:
			plan[id] = [float(sliders[0]), float(sliders[1]), float(sliders[2])]
		return plan
	var best: Dictionary = {}
	var covered: Array = [false, false, false]
	for id: String in team:
		var fit: Array = _fit(data, state.staff[id], ids)
		var i: int = fit.find(fit.max())
		best[id] = fit
		plan[id] = [0.0, 0.0, 0.0]
		plan[id][i] = 1.0
		covered[i] = true
	for i: int in 3:
		if bool(covered[i]):
			continue
		# En çok kişinin olduğu alandan, bu alana en uygun kişiyi kaydır.
		var pick: String = ""
		for id: String in team:
			if pick.is_empty() or float(best[id][i]) > float(best[pick][i]):
				var from: int = (plan[id] as Array).find(1.0)
				if _count(plan, from) > 1:
					pick = id
		if not pick.is_empty():
			plan[pick] = [0.0, 0.0, 0.0]
			plan[pick][i] = 1.0
	return plan


static func _fit(data: GameData, emp: Dictionary, ids: Array[String]) -> Array:
	var out: Array = []
	for f: String in ids:
		out.append(Employee.area_stat(data, emp, f) * Employee.specialty_mult(data, emp, f))
	return out


static func _count(plan: Dictionary, area: int) -> int:
	var n: int = 0
	for id: Variant in plan:
		if float(plan[id][area]) >= 1.0:
			n += 1
	return n
