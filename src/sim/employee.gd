class_name Employee
extends RefCounted
## Çalışan hesapları (GDD 11.2, 7.5). Çalışan sözlük olarak SimState.staff içinde durur; bu sınıf saf fonksiyonlardır.
## Çalışan alanları: id, name, role, level, xp, stats{}, hidden{}, hidden_revealed, energy, morale, burnout,
## salary, traits[], specialization (sektör id), hired_week, busy_until (eğitim/izin), busy_reason, is_founder.


static func position(data: GameData, emp: Dictionary) -> Dictionary:
	return data.positions[emp["role"]]


## Kıdem unvanı indeksi: seviyeye göre (levels_per_title seviyede bir), unvan sayısıyla sınırlı.
static func title_index(data: GameData, emp: Dictionary) -> int:
	var titles: Array = position(data, emp)["title_keys"]
	return mini(titles.size() - 1, (int(emp["level"]) - 1) / data.bali("staff_rules.levels_per_title"))


static func title_key(data: GameData, emp: Dictionary) -> String:
	return str(position(data, emp)["title_keys"][title_index(data, emp)])


static func has_trait(emp: Dictionary, trait_id: String) -> bool:
	for t: Variant in emp.get("traits", []):
		if str(t) == trait_id:
			return true
	return false


## Özelliklerin bir etkisinin çarpımı (yoksa 1.0) ya da toplamı (additive = true ise; yoksa 0).
static func trait_effect(data: GameData, emp: Dictionary, effect: String, additive: bool = false) -> float:
	var v: float = 0.0 if additive else 1.0
	for t: Variant in emp.get("traits", []):
		var effects: Dictionary = data.traits.get(str(t), {}).get("effects", {})
		if effects.has(effect):
			v = v + float(effects[effect]) if additive else v * float(effects[effect])
	return v


static func has_effect(data: GameData, emp: Dictionary, effect: String) -> bool:
	return (position(data, emp).get("effects", []) as Array).has(effect)


## GDD 7.5 uzmanlık: uzman alanı ×1.3; ana statına giden alan ×1.0; başka iş ×0.6 (K-036). Kurucu genelcidir: ×1.0.
static func specialty_mult(data: GameData, emp: Dictionary, area: String) -> float:
	var pos: Dictionary = position(data, emp)
	if has_effect(data, emp, "generalist"):
		return 1.0
	if (pos["specialty_focus"] as Array).has(area):
		return data.balf("staff.specialty_bonus")
	var area_stats: Dictionary = data.focus_areas[area]["stats"]
	for s: Variant in pos["primary_stats"]:
		if area_stats.has(s):
			return 1.0
	return data.balf("staff.offspec_penalty")


static func area_stat(data: GameData, emp: Dictionary, area: String) -> float:
	var split: Dictionary = data.focus_areas[area]["stats"]
	var v: float = 0.0
	for stat: String in split:
		v += float(emp["stats"][stat]) * float(split[stat])
	return v


static func office_mult(data: GameData, office_level: int) -> float:
	var quality: float = clampf(float(data.office(office_level).get("room_quality", 50)) / 100.0, 0.0, 1.0)
	return data.balf("office.quality_base") + data.balf("office.quality_range") * quality


## GDD 7.5: alana bağlı olmayan kişisel çarpanlar (hız, araç, ofis, moral, enerji, özellikler).
static func person_mult(data: GameData, emp: Dictionary, office_level: int) -> float:
	var ref: float = data.balf("production.stat_reference")
	var speed: float = float(emp["stats"]["speed"]) / ref * trait_effect(data, emp, "speed_mult")
	var morale: float = data.balf("morale.mult_base") + data.balf("morale.mult_range") * float(emp["morale"]) / 100.0
	var energy: float = data.balf("energy.low_mult") if float(emp["energy"]) < data.balf("energy.low_threshold") else 1.0
	return speed * data.balf("founder.tool_mult") * office_mult(data, office_level) * morale * energy \
		* trait_effect(data, emp, "output_mult")


## Kampanyaya özgü çarpanlar: sektör uzmanlığı, trend avcısı (yeni kanal), nostaljik (klasik/dijital kanal).
static func campaign_mult(data: GameData, emp: Dictionary, setup: Dictionary, year: int) -> float:
	var m: float = 1.0
	if str(emp.get("specialization", "")) == str(setup["sector"]):
		m *= data.balf("staff_rules.sector_specialization_bonus")
	var main: String = Scoring.main_channel(setup["mix"])
	var ch: Dictionary = data.channels[main]
	var from: int = int(ch["available_from"])
	if from > data.bali("time.base_year") and year - from <= data.bali("novelty_rules.pioneer_years"):
		m *= trait_effect(data, emp, "new_channel_mult")
	var cat: String = str(ch["category"])
	if cat in ["print", "ooh", "broadcast"]:
		m *= trait_effect(data, emp, "classic_channel_mult")
	elif cat in ["digital", "social", "influencer"]:
		m *= trait_effect(data, emp, "digital_channel_mult")
	return m


## Piyasa değeri (aylık maaş beklentisi): pozisyon tabanı × enflasyon × kıdem × ana stat düzeyi (GDD 11.2, K-035).
static func market_value(data: GameData, emp: Dictionary, year: int) -> float:
	var pos: Dictionary = position(data, emp)
	if float(pos["base_salary"]) <= 0.0:
		return 0.0
	var prim: Array = pos["primary_stats"]
	var avg: float = 0.0
	for s: Variant in prim:
		avg += float(emp["stats"][s])
	avg = avg / maxf(1.0, prim.size()) if not prim.is_empty() else float(emp["stats"]["attention"])
	return float(pos["base_salary"]) * Economy.inflation(data, year) \
		* (1.0 + data.balf("staff_rules.market_seniority_step") * title_index(data, emp)) \
		* (avg / data.balf("staff_rules.market_stat_reference")) * (1.0 + award_premium(data, emp))


## Ödül alan çalışanın piyasa değeri artar (GDD 15 "rakipler teklif yapar").
static func award_premium(data: GameData, emp: Dictionary) -> float:
	return minf(float(emp.get("award_points", 0.0)) * data.balf("awards.market_value_per_point"),
		data.balf("awards.market_value_max"))


## İzinde, eğitimde ya da pitch hazırlığında (M5) olan çalışan kampanyada çalışmaz.
static func is_available(emp: Dictionary, week_index: int) -> bool:
	return maxi(int(emp.get("busy_until", -1)), int(emp.get("pitch_until", -1))) <= week_index


static func is_creative(data: GameData, emp: Dictionary) -> bool:
	return str(position(data, emp)["department"]) == "creative"


static func is_creative_director(data: GameData, emp: Dictionary) -> bool:
	return is_creative(data, emp) and title_index(data, emp) >= data.bali("staff_rules.cd_title_index")
