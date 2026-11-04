extends SceneTree
## Denge simülasyonu (GDD 27): botlar 1990'dan N yıl oynar, sonuçları tablo olarak yazar.
## Çalıştırma: godot --headless --script res://tools/balance_sim.gd -- --runs=200 [--years=10] [--seed=1]
##   [--bots=random,smart,repeater,greedy] [--json=user://sonuc.json] (M10: sonuçlar tools/balance_report.gd için)
## Deneme için balance.json'u dosyayı değiştirmeden ezmek: --set=cashflow.late_chance_mult=0.25 (birden çok verilebilir);
## diğer veri: --set=data:offices.office_5.requirements.cash=30000000

const RandomBotScript: GDScript = preload("res://tools/bots/random_bot.gd")
const SmartBotScript: GDScript = preload("res://tools/bots/smart_bot.gd")
const RepeaterBotScript: GDScript = preload("res://tools/bots/repeater_bot.gd")
const GreedyBotScript: GDScript = preload("res://tools/bots/greedy_bot.gd")
const ALL_BOTS: String = "random,smart,repeater,greedy"


func _init() -> void:
	var args: Dictionary = {"runs": 200, "years": 10, "seed": 1}
	for arg: String in OS.get_cmdline_user_args():
		for key: String in args.keys():
			if arg.begins_with("--%s=" % key):
				args[key] = arg.get_slice("=", 1).to_int()
	var data: GameData = GameData.load_from()
	if not data.errors.is_empty():
		for e: String in data.errors:
			printerr("HATA: " + e)
		quit(1)
		return
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--set="):
			_override(data, arg.trim_prefix("--set="))
	var started: int = Time.get_ticks_msec()
	var results: Dictionary = {}
	var bots: String = "random,smart"
	var json_path: String = ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--bots="):
			bots = arg.trim_prefix("--bots=").replace("all", ALL_BOTS)
		elif arg.begins_with("--json="):
			json_path = arg.trim_prefix("--json=")
	for bot_kind: String in bots.split(","):
		results[bot_kind] = _run_many(data, bot_kind, int(args["runs"]), int(args["years"]), int(args["seed"]))
	_print_report(results, int(args["runs"]), int(args["years"]))
	if not json_path.is_empty():
		var out: FileAccess = FileAccess.open(json_path, FileAccess.WRITE)
		out.store_string(JSON.stringify({"runs": int(args["runs"]), "years": int(args["years"]), "results": results}))
		out.close()
		print("JSON: %s" % ProjectSettings.globalize_path(json_path))
	print("Süre: %.1f sn" % ((Time.get_ticks_msec() - started) / 1000.0))
	quit(0)


## "yol.alt=değer": değer JSON olarak okunur (sayı, dizi, metin).
func _override(data: GameData, spec: String) -> void:
	var eq: int = spec.find("=")
	var keys: PackedStringArray = spec.substr(0, eq).split(".")
	var value: Variant = JSON.parse_string(spec.substr(eq + 1))
	# "data:offices.office_5.requirements.cash=…": balance.json dışındaki veri (GameData sözlükleri) için.
	var node: Dictionary = data.balance
	if keys[0].begins_with("data:"):
		node = data.get(keys[0].trim_prefix("data:"))
		keys.remove_at(0)
	for i: int in keys.size() - 1:
		node = node[keys[i]]
	node[keys[keys.size() - 1]] = value
	print("ayar: %s = %s" % [spec.substr(0, eq), str(value)])


func _make_bot(kind: String, seed_value: int) -> RefCounted:
	match kind:
		"random": return RandomBotScript.new(seed_value)
		"repeater": return RepeaterBotScript.new()
		"greedy": return GreedyBotScript.new()
	return SmartBotScript.new()


func _run_many(data: GameData, kind: String, runs: int, years: int, seed_base: int) -> Dictionary:
	var weeks_per_year: int = data.bali("time.weeks_per_month") * data.bali("calendar.months_per_year")
	var bankrupt_3y: int = 0
	var bankrupt_any: int = 0
	var scores: Array[float] = []
	var scores_by_year: Array = []
	var cash_by_year: Array = []
	var campaigns: int = 0
	var staff_by_year: Array = []
	var rep_by_year: Array = []
	var first_award: Array = []
	var awards_won: int = 0
	var pitches: int = 0
	var pitch_wins: int = 0
	var office_reach: Dictionary = {}
	var loans_taken: int = 0
	for y: int in years:
		scores_by_year.append([])
		cash_by_year.append([])
		staff_by_year.append([])
		rep_by_year.append([])
	for run: int in runs:
		var sim: Simulation = Simulation.new(data, seed_base * 100000 + run)
		var bot: RefCounted = _make_bot(kind, seed_base * 100000 + run + 7)
		var level_seen: int = sim.state.office_level
		var had_loan: bool = false
		for week: int in years * weeks_per_year:
			bot.call("decide", sim)
			if not had_loan and not sim.state.loan.is_empty():
				loans_taken += 1
			had_loan = not sim.state.loan.is_empty()
			sim.step_week()
			if sim.state.bankrupt:
				break
			if sim.state.office_level > level_seen:
				level_seen = sim.state.office_level
				(office_reach.get_or_add(level_seen, []) as Array).append(sim.state.clock.game_year())
			if (week + 1) % weeks_per_year == 0:
				var yi: int = (week + 1) / weeks_per_year - 1
				(cash_by_year[yi] as Array).append(sim.state.cash)
				(staff_by_year[yi] as Array).append(sim.state.staff.size())
				(rep_by_year[yi] as Array).append(sim.state.reputation)
		if sim.state.bankrupt:
			bankrupt_any += 1
			if sim.state.clock.week_index < 3 * weeks_per_year:
				bankrupt_3y += 1
		for h: Dictionary in sim.state.history:
			scores.append(float(h["score"]))
			var yi: int = int(h["year"]) - data.bali("time.start_year")
			if yi < years:
				(scores_by_year[yi] as Array).append(float(h["score"]))
		campaigns += sim.state.history.size()
		var first: int = 0
		for r: Dictionary in sim.state.award_history:
			if not str(r["level"]).is_empty() and str(r["level"]) != "shortlist":
				awards_won += 1
				if first == 0:
					first = int(r["year"]) - data.bali("time.start_year") + 1
		if first > 0:
			first_award.append(first)
		for p: Dictionary in sim.state.pitch_history:
			pitches += 1
			pitch_wins += 1 if bool(p["won"]) else 0
	return {"bankrupt_3y": float(bankrupt_3y) / runs, "bankrupt_any": float(bankrupt_any) / runs,
		"avg_score": _mean(scores), "campaigns_per_run": float(campaigns) / runs,
		"scores_by_year": scores_by_year, "cash_by_year": cash_by_year, "staff_by_year": staff_by_year,
		"office_reach": office_reach, "runs": runs,
		"rep_by_year": rep_by_year, "first_award": first_award, "awards_per_run": float(awards_won) / runs,
		"pitches_per_run": float(pitches) / runs, "pitch_win_rate": float(pitch_wins) / maxf(1.0, pitches),
		"loans_per_run": float(loans_taken) / runs}


func _print_report(results: Dictionary, runs: int, years: int) -> void:
	print("")
	print("=== Ajans Tycoon denge simülasyonu: %d koşu × %d yıl ===" % [runs, years])
	print("%-10s | %13s | %14s | %9s | %16s" % ["Bot", "İflas ilk 3 yıl", "İflas %d yıl" % years, "Ort. puan", "Kampanya/koşu"])
	for kind: String in results:
		var r: Dictionary = results[kind]
		print("%-10s | %13.1f%% | %13.1f%% | %9.2f | %16.1f" % [_label(kind), 100.0 * r["bankrupt_3y"],
			100.0 * r["bankrupt_any"], r["avg_score"], r["campaigns_per_run"]])
	print("")
	print("Yıl sonu medyan nakit (₺, hayatta kalanlar) ve yıllık ortalama puan:")
	var header: String = "%-5s" % "Yıl"
	for kind: String in results:
		header += " | %14s | %6s | %5s | %5s" % [_label(kind) + " nakit", "puan", "ekip", "itibar"]
	print(header)
	for y: int in years:
		var line: String = "Y%-4d" % (y + 1)
		for kind: String in results:
			var r: Dictionary = results[kind]
			line += " | %14s | %6.2f | %5.1f | %5.1f" % [_money(_median(r["cash_by_year"][y])), _mean(r["scores_by_year"][y]),
				_mean(r["staff_by_year"][y]), _mean(r["rep_by_year"][y])]
		print(line)
	print("")
	print("Ofis taşınma (ulaşan koşu oranı, medyan oyun yılı) — GDD 27.2 hedefi: küçük ofis Y2–Y3, plaza Y12–Y16:")
	for kind: String in results:
		var r: Dictionary = results[kind]
		var parts: PackedStringArray = PackedStringArray()
		for level: int in range(2, 6):
			var reached: Array = r["office_reach"].get(level, [])
			if not reached.is_empty():
				parts.append("seviye %d: %%%d, Y%d" % [level, int(100.0 * reached.size() / int(r["runs"])), int(_median(reached))])
		print("  %-9s %s" % [_label(kind), " · ".join(parts) if not parts.is_empty() else "—"])
	print("İlk ödül (bronz+; ulaşan koşu oranı, medyan oyun yılı) — GDD 27.2 hedefi: bilgili bot Y5–Y8:")
	for kind: String in results:
		var r: Dictionary = results[kind]
		var fa: Array = r["first_award"]
		print("  %-9s %s · koşu başına %.1f ödül" % [_label(kind), ("%%%d, Y%d" % [int(100.0 * fa.size() / int(r["runs"])), int(_median(fa))]) if not fa.is_empty() else "—",
			float(r["awards_per_run"])])
	print("Pitch (koşu başına, kazanma oranı):")
	for kind: String in results:
		print("  %-9s %.1f pitch · %%%d kazanma" % [_label(kind), float(results[kind]["pitches_per_run"]),
			int(100.0 * float(results[kind]["pitch_win_rate"]))])
	if not results.has("smart") or not results.has("random"):
		return
	var diff: float = float(results["smart"]["avg_score"]) - float(results["random"]["avg_score"])
	var rb: float = 100.0 * float(results["random"]["bankrupt_3y"])
	print("")
	print("M1 kabul: puan farkı %.2f (hedef ≥ 2) %s · rastgele bot ilk 3 yılda iflas %%%.1f (hedef %%20–40) %s" % [
		diff, "✓" if diff >= 2.0 else "✗", rb, "✓" if rb >= 20.0 and rb <= 40.0 else "✗"])


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
