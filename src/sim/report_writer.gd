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
		"volume": volume_ratio(report)}


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


## Dört yorumcunun puanı ve cümlesi (GDT'nin 4 inceleme sitesi karşılığı).
func reviews(score: float, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var cfg: Dictionary = _lines_data()
	var spread: float = float(cfg.get("review_spread", 0.5))
	var out: Array[Dictionary] = []
	for reviewer: Dictionary in cfg.get("reviewers", []):
		var s: float = snappedf(clampf(score + rng.randf_range(-spread, spread),
			data.balf("scoring.min_score"), data.balf("scoring.max_score")), 0.1)
		var keys: Array = band_keys(s)
		out.append({"reviewer_key": reviewer["name_key"], "score": s,
			"text_key": keys[rng.randi_range(0, keys.size() - 1)] if not keys.is_empty() else ""})
	return out


func band_keys(score: float) -> Array:
	var keys: Array = []
	for band: Dictionary in _lines_data().get("review_bands", []):
		if score >= float(band["min"]):
			keys = band["keys"]
	return keys
