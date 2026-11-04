extends SceneTree
## Denge raporu (M10, GDD 27.2): balance_sim'in JSON çıktılarını birleştirir, hedeflerle karşılaştırır ve
## docs/balance-report.md yazar.
## Çalıştırma: godot --headless --script res://tools/balance_report.gd -- --in=user://a.json,user://b.json
##   [--long=user://uzun1.json,user://uzun2.json] (30 yıllık koşu: plaza katı ve geç oyun) [--out=res://docs/balance-report.md]
##   [--title=Başlık]

const COMBO_SAMPLES: int = 20000


func _init() -> void:
	var inputs: PackedStringArray = PackedStringArray()
	var long_path: String = ""
	var out: String = "res://docs/balance-report.md"
	var title: String = "Denge raporu"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--in="):
			inputs = arg.trim_prefix("--in=").split(",")
		elif arg.begins_with("--long="):
			long_path = arg.trim_prefix("--long=")
		elif arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
		elif arg.begins_with("--title="):
			title = arg.trim_prefix("--title=")
	var data: GameData = GameData.load_from()
	var short: Dictionary = _merge(inputs)
	var long: Dictionary = _merge(long_path.split(",")) if not long_path.is_empty() else {}
	var md: String = _report(data, title, short, long)
	var f: FileAccess = FileAccess.open(out, FileAccess.WRITE)
	f.store_string(md)
	f.close()
	print(md)
	quit(0)


## Birden çok JSON (her biri bir ya da birkaç bot) tek sonuç sözlüğünde.
func _merge(paths: PackedStringArray) -> Dictionary:
	var out: Dictionary = {"results": {}}
	for p: String in paths:
		var doc: Dictionary = _read(p)
		out["runs"] = doc.get("runs", 0)
		out["years"] = doc.get("years", 0)
		(out["results"] as Dictionary).merge(doc.get("results", {}))
	return out


func _read(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


# --- hedefler ---------------------------------------------------------------------

func _report(data: GameData, title: String, short: Dictionary, long: Dictionary) -> String:
	var r: Dictionary = short["results"]
	var lr: Dictionary = long.get("results", {})
	var lines: PackedStringArray = PackedStringArray()
	lines.append("# %s" % title)
	lines.append("")
	lines.append("Üretildi: %s · kısa koşu: %d koşu × %d yıl%s." % [Time.get_date_string_from_system(), int(short.get("runs", 0)),
		int(short.get("years", 0)), (" · uzun koşu: %d koşu × %d yıl" % [int(long["runs"]), int(long["years"])]) if not long.is_empty() else ""])
	lines.append("Araçlar: `tools/balance_sim.gd` (botlar), `tools/balance_report.gd` (bu rapor). Hedefler GDD 27.2.")
	lines.append("")
	lines.append("## Hedefler")
	lines.append("")
	lines.append("| Metrik | Hedef | Değer | Durum |")
	lines.append("|---|---|---|---|")
	var smart: Dictionary = r.get("smart", {})
	var rnd: Dictionary = r.get("random", {})
	var rep: Dictionary = r.get("repeater", {})
	if not rnd.is_empty():
		var v: float = 100.0 * float(rnd["bankrupt_3y"])
		lines.append(_row("Rastgele bot ilk 3 yılda iflas", "%20–40", "%%%.1f" % v, v >= 20.0 and v <= 40.0))
	if not smart.is_empty():
		var y2: Array = _reach(smart, 2)
		lines.append(_row("Bilgili bot küçük ofise geçiş (medyan yıl)", "Y2–Y3", _reach_text(y2, smart),
			not y2.is_empty() and _median(y2) >= 2.0 and _median(y2) <= 3.0))
		var lsmart: Dictionary = lr.get("smart", {})
		if not lsmart.is_empty():
			var y4: Array = _reach(lsmart, 4)
			lines.append(_row("Bilgili bot plaza katına geçiş (medyan yıl)", "Y12–Y16", _reach_text(y4, lsmart),
				not y4.is_empty() and _median(y4) >= 12.0 and _median(y4) <= 16.0))
		var s: float = float(smart["avg_score"])
		lines.append(_row("Bilgili bot ortalama puan", "7.0–8.5", "%.2f" % s, s >= 7.0 and s <= 8.5))
		if not rep.is_empty():
			var d: float = s - float(rep["avg_score"])
			lines.append(_row("Tekrarcı bot, bilgiliden en az 1.5 düşük", "≥ 1.5", "%.2f (tekrarcı %.2f)" % [d, float(rep["avg_score"])], d >= 1.5))
		if not rnd.is_empty():
			var d2: float = s - float(rnd["avg_score"])
			lines.append(_row("Rastgele bot, bilgiliden en az 2.5 düşük", "≥ 2.5", "%.2f (rastgele %.2f)" % [d2, float(rnd["avg_score"])], d2 >= 2.5))
		var fa: Array = smart["first_award"]
		lines.append(_row("Bilgili bot ilk ödül (medyan yıl)", "Y5–Y8", ("Y%d (%%%d koşuda)" % [int(_median(fa)),
			int(100.0 * fa.size() / maxf(1.0, float(smart["runs"])))]) if not fa.is_empty() else "—",
			not fa.is_empty() and _median(fa) >= 5.0 and _median(fa) <= 8.0))
	var combo: Dictionary = _combo_stats(data)
	lines.append(_row("Rastgele kombinasyonların uyum çarpanı (ortalama)", "0.93–0.97", "%.3f" % combo["mean"],
		combo["mean"] >= 0.93 and combo["mean"] <= 0.97))
	lines.append(_row("…ve en az %20'si 0.85'in altında", "≥ %20", "%%%.1f" % (100.0 * combo["below"]), combo["below"] >= 0.2))
	var minutes: float = data.balf("time.seconds_per_week_1x") * data.bali("time.weeks_per_month") \
		* data.bali("calendar.months_per_year") / 60.0
	lines.append(_row("Bir oyun yılı gerçek süre (1x, duraklamasız)", "10–15 dk", "%.1f dk" % minutes, minutes >= 10.0 and minutes <= 15.0))
	lines.append("")
	lines.append("## Botlar")
	lines.append("")
	lines.append("| Bot | İflas ilk 3 yıl | İflas %d yıl | Ort. puan | Kampanya/koşu | Ödül/koşu | Kredi/koşu |" % int(short.get("years", 0)))
	lines.append("|---|---|---|---|---|---|---|")
	for kind: String in r:
		var b: Dictionary = r[kind]
		lines.append("| %s | %%%.1f | %%%.1f | %.2f | %.1f | %.1f | %.2f |" % [_label(kind), 100.0 * float(b["bankrupt_3y"]),
			100.0 * float(b["bankrupt_any"]), float(b["avg_score"]), float(b["campaigns_per_run"]), float(b["awards_per_run"]),
			float(b.get("loans_per_run", 0.0))])
	lines.append_array(_yearly("## Yıllara göre (kısa koşu)", r))
	if not lr.is_empty():
		lines.append_array(_yearly("## Yıllara göre (uzun koşu)", lr))
	return "\n".join(lines) + "\n"


func _row(name: String, target: String, value: String, ok: bool) -> String:
	return "| %s | %s | %s | %s |" % [name, target, value, "✓" if ok else "✗"]


func _reach(b: Dictionary, level: int) -> Array:
	return (b["office_reach"] as Dictionary).get(str(level), (b["office_reach"] as Dictionary).get(level, []))


func _reach_text(years: Array, b: Dictionary) -> String:
	if years.is_empty():
		return "ulaşılmadı"
	return "Y%d (%%%d koşuda)" % [int(_median(years)), int(100.0 * years.size() / maxf(1.0, float(b["runs"])))]


## Yıl sonu medyan nakit, ortalama puan, ekip ve itibar (her bot için).
func _yearly(heading: String, r: Dictionary) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray(["", heading, ""])
	var head: String = "| Yıl |"
	var sep: String = "|---|"
	for kind: String in r:
		head += " %s nakit | puan | ekip | itibar |" % _label(kind)
		sep += "---|---|---|---|"
	out.append(head)
	out.append(sep)
	var years: int = (r.values()[0]["scores_by_year"] as Array).size()
	for y: int in years:
		var line: String = "| Y%d |" % (y + 1)
		for kind: String in r:
			var b: Dictionary = r[kind]
			line += " %s | %.2f | %.1f | %.1f |" % [_money(_median(b["cash_by_year"][y])), _mean(b["scores_by_year"][y]),
				_mean(b["staff_by_year"][y]), _mean(b["rep_by_year"][y])]
		out.append(line)
	return out


## Tamamen rastgele kurulumların (sektör, hedef, kitle, ton, kanal) uyum çarpanı dağılımı.
func _combo_stats(data: GameData) -> Dictionary:
	var scoring: Scoring = Scoring.new(data)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 12345
	var sum: float = 0.0
	var below: int = 0
	for i: int in COMBO_SAMPLES:
		var setup: Dictionary = {"sector": data.sector_ids[rng.randi() % data.sector_ids.size()],
			"objective": data.objective_ids[rng.randi() % data.objective_ids.size()],
			"audience": data.audience_ids[rng.randi() % data.audience_ids.size()],
			"tone": data.tone_ids[rng.randi() % data.tone_ids.size()],
			"mix": [{"channel": data.channel_ids[rng.randi() % data.channel_ids.size()], "share": 1.0}]}
		var m: float = float(scoring.combination(setup, {})["m"])
		sum += m
		if m < 0.85:
			below += 1
	return {"mean": sum / COMBO_SAMPLES, "below": float(below) / COMBO_SAMPLES}


func _label(kind: String) -> String:
	return {"random": "rastgele", "smart": "bilgili", "repeater": "tekrarcı", "greedy": "açgözlü"}.get(kind, kind)


func _mean(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var s: float = 0.0
	for v: Variant in values:
		s += float(v)
	return s / values.size()


func _median(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var sorted: Array = values.duplicate()
	sorted.sort()
	return float(sorted[sorted.size() / 2])


func _money(v: float) -> String:
	return String.num_int64(int(v))
