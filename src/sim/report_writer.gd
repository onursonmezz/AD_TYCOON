class_name ReportWriter
extends RefCounted
## Kampanya raporunun açıklama cümleleri (GDD 7.12) ve jüri/medya yorumları (GDD 20).
## Sadece metin anahtarı üretir; çeviriyi UI yapar (tr()).

var data: GameData


func _init(game_data: GameData) -> void:
	data = game_data


func _lines_data() -> Dictionary:
	return data.raw.get("report_lines.json", {})


## Rapordaki çarpanlardan ölçülebilir değerler.
static func metrics(report: Dictionary) -> Dictionary:
	var comb: Dictionary = report["combination"]
	var bal: Dictionary = report["balance"]
	return {"sh": comb["sh"], "sk": comb["sk"], "kn": comb["kn"], "tone": comb["tone"], "m": comb["m"],
		"f": report["focus"]["f"], "b": bal["b"], "sk_vs_ideal": float(bal["ratio"]) / maxf(0.0001, float(bal["ideal"])),
		"n": report["novelty"]["n"], "fragmentation": report["synergy"]["fragmentation"],
		"synergy_pairs": (report["synergy"]["pairs"] as Array).size(), "errors": report["errors"],
		"volume": volume_ratio(report), "synergy": float((report["synergy"] as Dictionary).get("synergy", 1.0)),
		"minigame": float(report.get("minigame", 1.0))}


## İş miktarı: ekibin ürettiği ham emek (S+K+T, çarpanlardan önce) / dönem beklentisi (GDD 7.9 hedef puan).
## Kalite çarpanları ne kadar iyi olursa olsun, bu oran düşükse puan düşük kalır.
static func volume_ratio(report: Dictionary) -> float:
	var points: float = float(report["s"]) + float(report["k"]) + float(report["t"])
	return points / maxf(1.0, float(report["target"]))


static func _compare(a: float, op: String, b: float) -> bool:
	match op:
		">=": return a >= b
		"<=": return a <= b
		">": return a > b
		"<": return a < b
	return false


## Dönüş: [{ "key": "RL_SH_GOOD", "sign": 1 }, ...] — olumlu olanlar önce.
func explanation_lines(report: Dictionary) -> Array[Dictionary]:
	var m: Dictionary = metrics(report)
	var good: Array[Dictionary] = []
	var bad: Array[Dictionary] = []
	for rule: Dictionary in _lines_data().get("explanations", []):
		if not _compare(float(m[rule["metric"]]), rule["op"], float(rule["value"])):
			continue
		if rule.has("and"):
			var extra: Dictionary = rule["and"]
			if not _compare(float(m[extra["metric"]]), extra["op"], float(extra["value"])):
				continue
		var line: Dictionary = {"key": rule["key"], "sign": int(rule["sign"])}
		if int(rule["sign"]) > 0:
			good.append(line)
		else:
			bad.append(line)
	good.append_array(bad)
	return good


## Dört yorumcunun puanı ve cümlesi (GDT'nin 4 inceleme sitesi karşılığı). S4: her yayının kendi sesi (puan aralığına
## göre kendi havuzu); bazen kampanyanın özelliğine dair bir cümle (hata, yenilik, uyum, KPI, viral). Aynı raporda
## bir cümle iki kez çıkmaz. camp: özellikler için (boşsa yalnızca havuzlar).
func reviews(score: float, rng: RandomNumberGenerator, camp: Dictionary = {}) -> Array[Dictionary]:
	var cfg: Dictionary = _lines_data()
	var spread: float = float(cfg.get("review_spread", 0.5))
	var used: Array[String] = []
	var aspects: Array = _aspect_keys(camp)
	var aspect_used: bool = false
	var out: Array[Dictionary] = []
	for reviewer: Dictionary in cfg.get("reviewers", []):
		var s: float = snappedf(clampf(score + rng.randf_range(-spread, spread),
			data.balf("scoring.min_score"), data.balf("scoring.max_score")), 0.1)
		var key: String = ""
		var free_aspects: Array = aspects.filter(func(k: Variant) -> bool: return not used.has(str(k)))
		if not aspect_used and not free_aspects.is_empty() and rng.randf() < float(cfg.get("review_aspect_chance", 0.0)):
			key = str(free_aspects[rng.randi_range(0, free_aspects.size() - 1)])
			aspect_used = true  # özelliğe dair cümle raporda en fazla bir kez (iki yayın aynı konuya girmesin)
		if key.is_empty():
			var pool: Array = _reviewer_pool(reviewer, s).filter(func(k: Variant) -> bool: return not used.has(str(k)))
			if pool.is_empty():
				pool = band_keys(s)
			key = str(pool[rng.randi_range(0, pool.size() - 1)]) if not pool.is_empty() else ""
		used.append(key)
		out.append({"reviewer_key": reviewer["name_key"], "score": s, "text_key": key})
	return out


## Yorumcunun bu puan aralığındaki cümleleri (reviewers[].bands, review_bands sırasıyla).
func _reviewer_pool(reviewer: Dictionary, score: float) -> Array:
	var bands: Array = reviewer.get("bands", [])
	var index: int = -1
	for band: Dictionary in _lines_data().get("review_bands", []):
		if score >= float(band["min"]):
			index += 1
	return bands[index] if index >= 0 and index < bands.size() else []


## Kampanyanın özelliklerine uyan cümleler (review_aspects).
func _aspect_keys(camp: Dictionary) -> Array:
	if camp.is_empty() or not camp.has("report"):
		return []
	var m: Dictionary = metrics(camp["report"])
	m["kpi_ratio"] = float(camp.get("kpi_ratio", 1.0))
	m["viral"] = 1.0 if bool(camp.get("kpi", {}).get("viral", false)) else 0.0
	var out: Array = []
	for a: Dictionary in _lines_data().get("review_aspects", []):
		if _compare(float(m.get(str(a["metric"]), 1.0)), str(a["op"]), float(a["value"])):
			out.append_array(a["keys"])
	return out


func band_keys(score: float) -> Array:
	var keys: Array = []
	for band: Dictionary in _lines_data().get("review_bands", []):
		if score >= float(band["min"]):
			keys = band["keys"]
	return keys
