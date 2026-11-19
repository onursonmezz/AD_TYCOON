class_name TaskPlan
extends RefCounted
## Görev planı (S3A, Game Dev Tycoon tarzı): her fazın üç görevi bir ağırlık (setup.sliders[faz][görev], faz toplamı 1)
## ve en çok bir kişi alır (setup.assign[faz][görev] = emp_id ya da ""). Plan kampanyanın başında bir kez yapılır.
## Kişinin kampanya yükü = atandığı görevlerin ağırlıkları toplamı (üç fazda %40'lık birer görev → %120).
## Fazdaki günlük yoğunluğu = 3 × o fazdaki ağırlıklarının toplamı (üç kişi birer %33'lük görevle %100 çalışır).
## Küçük işlerde ve küçük ekipte atama yok (Orgo, 2026-11-19): ekip her görevde ağırlık payıyla çalışır, yük sayılmaz.
## Görevlerin toplam yükü %300 olduğundan atama 3 kişiden başlar (2 kişi hep %150 yüklü olurdu).
## Sayılar balance.json "workload".


## Bu kurulum kişi ataması ister mi? Küçük iş ya da tek kişilik ekip: hayır.
static func needs_assignment(data: GameData, setup: Dictionary) -> bool:
	var sizes: Array = data.bal("workload.assign_sizes")
	return sizes.has(str(setup.get("size", ""))) and (setup.get("team", []) as Array).size() >= data.bali("workload.assign_min_team")


## Atamalı plan var mı (yoksa eski yol: herkes her görevde kaydırıcı payıyla).
static func has_plan(setup: Dictionary) -> bool:
	return not (setup.get("assign", []) as Array).is_empty()


static func assignee(setup: Dictionary, phase: int, task: int) -> String:
	var a: Array = setup.get("assign", [])
	if phase >= a.size() or task >= (a[phase] as Array).size():
		return ""
	return str(a[phase][task])


## Kampanya yükü: kişinin atandığı görevlerin ağırlıkları toplamı (1.0 = %100).
static func campaign_load(setup: Dictionary, emp_id: String) -> float:
	var total: float = 0.0
	for p: int in 3:
		for i: int in 3:
			if assignee(setup, p, i) == emp_id:
				total += float(setup["sliders"][p][i])
	return total


## Fazdaki günlük yoğunluk: 3 × o fazdaki ağırlıklarının toplamı (1.0 = tam gün).
static func phase_intensity(setup: Dictionary, phase: int, emp_id: String) -> float:
	var total: float = 0.0
	for i: int in 3:
		if assignee(setup, phase, i) == emp_id:
			total += float(setup["sliders"][phase][i])
	return 3.0 * total


## Doğrulama: 3×3, atananlar ekipte; en az bir görev atanmış. Dönüş "" ya da hata anahtarı.
static func validate(assign: Array, team: Array) -> String:
	if assign.size() != 3:
		return "ERR_PLAN"
	var any: bool = false
	for p: Variant in assign:
		if typeof(p) != TYPE_ARRAY or (p as Array).size() != 3:
			return "ERR_PLAN"
		for id: Variant in p:
			if str(id).is_empty():
				continue
			if not team.has(str(id)):
				return "ERR_PLAN_MEMBER"
			any = true
	return "" if any else "ERR_PLAN_EMPTY"


## Otomatik atama: ağır görevden hafife; her görev, yükü %100'ü aşmayacak kişilerin en uygununa (stat × uzmanlık).
static func auto_assign(data: GameData, state: SimState, sliders: Array, team: Array) -> Array:
	var assign: Array = [["", "", ""], ["", "", ""], ["", "", ""]]
	var load: Dictionary = {}
	for id: Variant in team:
		load[str(id)] = 0.0
	var tasks: Array = []
	for p: int in 3:
		for i: int in 3:
			tasks.append([p, i, float(sliders[p][i])])
	tasks.sort_custom(func(a: Array, b: Array) -> bool: return float(a[2]) > float(b[2]))
	for t: Array in tasks:
		var p: int = int(t[0])
		var area: String = data.focus_ids_of_phase(p)[int(t[1])]
		# Sıra: bu fazda görevi olmayan ve yükü %100'ü aşmayacak kişi; sonra yalnızca yük sınırı; sonra yükü en az artan.
		var best: String = ""
		var best_v: float = -1.0
		var w: float = float(t[2])
		for pass_i: int in 3:
			for id: Variant in team:
				var emp: Dictionary = state.staff.get(str(id), {})
				if emp.is_empty():
					continue
				var after: float = float(load[str(id)]) + w
				if pass_i <= 1 and after > data.balf("workload.warn_load") + 0.001:
					continue
				if pass_i == 0 and (assign[p] as Array).has(str(id)):
					continue  # önce herkese fazda bir görev
				var fit: float = Employee.area_stat(data, emp, area) * Employee.specialty_mult(data, emp, area)
				var v: float = fit if pass_i <= 1 else 1.0 / after
				if v > best_v:
					best_v = v
					best = str(id)
			if not best.is_empty():
				break
		if not best.is_empty():
			assign[p][int(t[1])] = best
			load[best] = float(load[best]) + w
	return assign
