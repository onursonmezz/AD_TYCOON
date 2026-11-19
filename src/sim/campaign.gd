class_name CampaignProduction
extends RefCounted
## Kampanya kurulumu doğrulama ve günlük puan üretimi (GDD 7.1, 7.4, 7.5).
## Faz başına görev planı varsa (K-118, WorkPlan) her çalışan kendi zaman paylarıyla üretir; yoksa kaydırıcı paylarıyla.

var data: GameData
var scoring: Scoring
## Prodüksiyon ekipmanı (K-119); Simulation bağlar. Yoksa çarpan 1.
var equipment: EquipmentSystem


const EQUIPMENT_AREA: String = "production"


func _init(game_data: GameData, scoring_ref: Scoring) -> void:
	data = game_data
	scoring = scoring_ref


## Oyuncu seçimlerini kontrol eder. Dönüş: boş = geçerli, aksi halde hata anahtarı.
func validate_setup(setup: Dictionary, year: int) -> String:
	if not data.objectives.has(setup.get("objective", "")):
		return "ERR_OBJECTIVE"
	# "" = otomatik: Hedef Kitle / Ton araştırması yapılmadan önce (M7-B) nötr sayılır.
	if str(setup.get("audience", "")) != "" and not data.audiences.has(setup["audience"]):
		return "ERR_AUDIENCE"
	if str(setup.get("tone", "")) != "" and not data.tones.has(setup["tone"]):
		return "ERR_TONE"
	var mix: Array = setup.get("mix", [])
	if mix.is_empty():
		return "ERR_MIX_EMPTY"
	var total: float = 0.0
	var seen: Array[String] = []
	var infl: float = Economy.inflation(data, year)
	for entry: Dictionary in mix:
		var ch: String = str(entry.get("channel", ""))
		if not data.channels.has(ch) or int(data.channels[ch]["available_from"]) > year or seen.has(ch):
			return "ERR_CHANNEL"
		seen.append(ch)
		var share: float = float(entry.get("share", 0.0))
		if share <= 0.0:
			return "ERR_SHARE"
		if float(setup["media_budget"]) * share < float(data.channels[ch]["min_budget"]) * infl:
			return "ERR_MIN_BUDGET"
		total += share
	if not is_equal_approx(total, 1.0):
		return "ERR_SHARE"
	var sliders: Array = setup.get("sliders", [])
	if sliders.size() != 3:
		return "ERR_SLIDERS"
	for phase: Variant in sliders:
		if typeof(phase) != TYPE_ARRAY or (phase as Array).size() != 3:
			return "ERR_SLIDERS"
		var sum: float = 0.0
		for v: Variant in phase:
			if float(v) < 0.0:
				return "ERR_SLIDERS"
			sum += float(v)
		if not is_equal_approx(sum, 1.0):
			return "ERR_SLIDERS"
	return ""


func create(setup: Dictionary, campaign_id: String, week_index: int) -> Dictionary:
	var points: Dictionary = {}
	for id: String in data.focus_ids:
		points[id] = 0.0
	# S3C: planlı kampanyada süre üretim + rötuş; üretim aynı toplam işi sürenin bir kısmında çıkarır.
	var share: float = 1.0 - data.balf("production.polish_share") if bool(setup.get("polish", false)) else 1.0
	return {"id": campaign_id, "setup": setup, "points": points, "errors": 0, "day": 0,
		"days_total": int(setup["deadline_weeks"]) * data.bali("calendar.days_per_week"), "start_week": week_index,
		"production_share": share}


func current_phase(campaign: Dictionary) -> int:
	return phase_of(campaign)


static func phase_of(campaign: Dictionary) -> int:
	return mini(2, int(campaign.get("day", 0)) * 3 / production_days(campaign))


## Üretim günleri (S3C): sürenin production_share kadarı; eski kampanyalarda tüm süre.
static func production_days(campaign: Dictionary) -> int:
	var total: int = maxi(1, int(campaign.get("days_total", 1)))
	return clampi(int(ceilf(float(total) * float(campaign.get("production_share", 1.0)))), 1, total)


## Üretim bitti, rötuşta (hata gideriliyor): teslim düğmesi açık.
static func production_done(campaign: Dictionary) -> bool:
	return int(campaign.get("day", 0)) >= production_days(campaign)


## Teslim zamanı: süre doldu ya da oyuncu "Kampanyayı teslim et" dedi.
func is_finished(campaign: Dictionary) -> bool:
	return int(campaign["day"]) >= int(campaign["days_total"]) or bool(campaign.get("deliver_now", false))


## Günlük üretim hızı: üretim süreye sıkıştırıldıysa aynı toplam iş için daha hızlı (puan ve hata zarı).
static func production_rate(campaign: Dictionary) -> float:
	return 1.0 / maxf(0.1, float(campaign.get("production_share", 1.0)))


## Rötuş günü (S3C): yeni puan yok; her müsait ekip üyesi dikkatine göre bir hatayı giderebilir.
func _polish_day(campaign: Dictionary, state: SimState) -> void:
	var fixed: int = 0
	for id: Variant in campaign["setup"].get("team", []):
		if int(campaign["errors"]) <= 0:
			break
		var emp: Dictionary = state.staff.get(str(id), {})
		if emp.is_empty() or not Employee.is_available(emp, state.clock.week_index):
			continue
		var p: float = data.balf("production.polish_fix_chance") * float(emp["stats"]["attention"]) / 100.0
		if state.rng.chance("polish", p):
			campaign["errors"] = int(campaign["errors"]) - 1
			fixed += 1
	campaign["errors_fixed"] = int(campaign.get("errors_fixed", 0)) + fixed
	campaign["day"] = int(campaign["day"]) + 1


## Ekibin geçerliliği: en az bir kişi, herkes var ve müsait (eğitimde/izinde değil).
func validate_team(team: Array, state: SimState) -> String:
	if team.is_empty():
		return "ERR_TEAM_EMPTY"
	for id: Variant in team:
		var emp: Dictionary = state.staff.get(str(id), {})
		if emp.is_empty() or not Employee.is_available(emp, state.clock.week_index):
			return "ERR_BUSY_EMPLOYEE"
	return ""


## Bir günlük üretim (GDD 7.5): ekipteki her müsait çalışan, fazın üç odak alanına slider payıyla puan üretir;
## her çalışan için günde bir hata zarı atılır (K-021).
func produce_day(campaign: Dictionary, state: SimState) -> void:
	if production_done(campaign):
		_polish_day(campaign, state)
		return
	var rate: float = production_rate(campaign)
	var phase: int = current_phase(campaign)
	var ids: Array[String] = data.focus_ids_of_phase(phase)
	var setup: Dictionary = campaign["setup"]
	var sliders: Array = setup["sliders"][phase]
	var ref: float = data.balf("production.stat_reference")
	var year: int = state.clock.year()
	var overtime_out: float = (data.balf("staff.overtime_output") if state.overtime else 1.0) * rate
	var rush: bool = int(setup["deadline_weeks"]) < data.bali("production.rush_below_weeks")
	var points: Dictionary = campaign["points"]
	# Oda etkisi (12.2): ör. beyin fırtınası odası konsepte +%10.
	var focus_mult: Dictionary = state.office_effects.get("focus_mult", {})
	var plan: Dictionary = WorkPlan.phase_plan(campaign, phase)
	var eq_mult: float = equipment.production_mult(state, setup) if equipment != null else 1.0
	var tasked: bool = TaskPlan.has_plan(setup)  # S3A: görev başına tek kişi
	for id: Variant in setup.get("team", []):
		var emp: Dictionary = state.staff.get(str(id), {})
		if emp.is_empty() or not Employee.is_available(emp, state.clock.week_index):
			continue
		if tasked:
			_produce_tasked(campaign, state, emp, phase, ids, points, focus_mult, eq_mult, overtime_out, rush, ref, year)
			continue
		var alloc: Array = plan.get(str(id), []) if not plan.is_empty() else []
		if not plan.is_empty() and WorkPlan.load_of_alloc(alloc) <= 0.0:
			continue  # bu fazda görevsiz
		var load: float = WorkPlan.load_of_alloc(alloc) if not plan.is_empty() else 1.0
		var over: float = WorkPlan.overload_mult(data, load)
		var base: float = data.balf("production.base_per_day") * Employee.person_mult(data, emp, state.room_quality) \
			* Employee.campaign_mult(data, emp, setup, year) * overtime_out
		for i: int in ids.size():
			var share: float = float(alloc[i]) * over if not plan.is_empty() else scoring.effective_share(float(sliders[i]))
			points[ids[i]] = float(points[ids[i]]) + base * Employee.area_stat(data, emp, ids[i]) / ref \
				* Employee.specialty_mult(data, emp, ids[i]) * share * float(focus_mult.get(ids[i], 1.0)) \
				* ToolSystem.focus_mult(data, state, ids[i]) * Employee.cert_mult(data, emp, ids[i]) \
				* (eq_mult if ids[i] == EQUIPMENT_AREA else 1.0)
		var p_error: float = data.balf("staff.base_error_rate") * (1.0 - float(emp["stats"]["attention"]) / 100.0) \
			* Employee.trait_effect(data, emp, "error_mult") * WorkPlan.error_mult(data, load)
		if rush:
			p_error *= data.balf("production.rush_error_mult")
		if state.overtime:
			p_error *= data.balf("production.overtime_error_mult")
		if state.rng.chance("production", minf(1.0, p_error * production_rate(campaign))):
			campaign["errors"] = int(campaign["errors"]) + 1
	campaign["day"] = int(campaign["day"]) + 1


## Atamalı plan (S3A): kişi yalnızca bu fazda atandığı görevlerde üretir; görevin payı ağırlığın 3 katı (üç kişi
## birer %33'lük görevle tam gün çalışır). Fazla çalışma kampanya yükünden (Orgo: üç fazda %40'lık görev → %120):
## %100'ü geçen kişinin verimi düşer, hatası artar (WorkPlan çarpanları).
func _produce_tasked(campaign: Dictionary, state: SimState, emp: Dictionary, phase: int, ids: Array[String],
		points: Dictionary, focus_mult: Dictionary, eq_mult: float, overtime_out: float, rush: bool, ref: float, year: int) -> void:
	var setup: Dictionary = campaign["setup"]
	var emp_id: String = str(emp["id"])
	if TaskPlan.phase_intensity(setup, phase, emp_id) <= 0.0:
		return  # bu fazda görevsiz
	var total_load: float = TaskPlan.campaign_load(setup, emp_id)
	var over: float = WorkPlan.overload_mult(data, total_load)
	var base: float = data.balf("production.base_per_day") * Employee.person_mult(data, emp, state.room_quality) \
		* Employee.campaign_mult(data, emp, setup, year) * overtime_out
	for i: int in ids.size():
		if TaskPlan.assignee(setup, phase, i) != emp_id:
			continue
		var share: float = 3.0 * float(setup["sliders"][phase][i]) * over
		points[ids[i]] = float(points[ids[i]]) + base * Employee.area_stat(data, emp, ids[i]) / ref \
			* Employee.specialty_mult(data, emp, ids[i]) * share * float(focus_mult.get(ids[i], 1.0)) \
			* ToolSystem.focus_mult(data, state, ids[i]) * Employee.cert_mult(data, emp, ids[i]) \
			* (eq_mult if ids[i] == EQUIPMENT_AREA else 1.0)
	var p_error: float = data.balf("staff.base_error_rate") * (1.0 - float(emp["stats"]["attention"]) / 100.0) \
		* Employee.trait_effect(data, emp, "error_mult") * WorkPlan.error_mult(data, total_load)
	if rush:
		p_error *= data.balf("production.rush_error_mult")
	if state.overtime:
		p_error *= data.balf("production.overtime_error_mult")
	if state.rng.chance("production", minf(1.0, p_error * production_rate(campaign))):
		campaign["errors"] = int(campaign["errors"]) + 1
