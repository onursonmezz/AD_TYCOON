extends SceneTree
## Denge simülasyonu (GDD 27): botlar 1990'dan N yıl oynar, sonuçları tablo olarak yazar.
## Çalıştırma: godot --headless --script res://tools/balance_sim.gd -- --runs=200 [--years=10] [--seed=1]
## Deneme için balance.json'u dosyayı değiştirmeden ezmek: --set=cashflow.late_chance_mult=0.25 (birden çok verilebilir)

const RandomBotScript: GDScript = preload("res://tools/bots/random_bot.gd")
const SmartBotScript: GDScript = preload("res://tools/bots/smart_bot.gd")


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
	for bot_kind: String in ["random", "smart"]:
		results[bot_kind] = _run_many(data, bot_kind, int(args["runs"]), int(args["years"]), int(args["seed"]))
	_print_report(results, int(args["runs"]), int(args["years"]))
	print("Süre: %.1f sn" % ((Time.get_ticks_msec() - started) / 1000.0))
	quit(0)


## "yol.alt=değer": değer JSON olarak okunur (sayı, dizi, metin).
func _override(data: GameData, spec: String) -> void:
	var eq: int = spec.find("=")
	var keys: PackedStringArray = spec.substr(0, eq).split(".")
	var value: Variant = JSON.parse_string(spec.substr(eq + 1))
	var node: Dictionary = data.balance
	for i: int in keys.size() - 1:
		node = node[keys[i]]
	node[keys[keys.size() - 1]] = value
	print("ayar: %s = %s" % [spec.substr(0, eq), str(value)])


func _make_bot(kind: String, seed_value: int) -> RefCounted:
	if kind == "random":
		return RandomBotScript.new(seed_value)
	return SmartBotScript.new()


func _run_many(data: GameData, kind: String, runs: int, years: int, seed_base: int) -> Dictionary:
	var weeks_per_year: int = data.bali("time.weeks_per_month") * data.bali("calendar.months_per_year")
	var bankrupt_3y: int = 0
	var bankrupt_any: int = 0
	var scores: Array[float] = []
	var scores_by_year: Array = []
	var cash_by_year: Array = []
	var campaigns: int = 0
	for y: int in years:
		scores_by_year.append([])
		cash_by_year.append([])
	for run: int in runs:
		var sim: Simulation = Simulation.new(data, seed_base * 100000 + run)
		var bot: RefCounted = _make_bot(kind, seed_base * 100000 + run + 7)
		for week: int in years * weeks_per_year:
			bot.call("decide", sim)
			sim.step_week()
			if sim.state.bankrupt:
				break
			if (week + 1) % weeks_per_year == 0:
				(cash_by_year[(week + 1) / weeks_per_year - 1] as Array).append(sim.state.cash)
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
	return {"bankrupt_3y": float(bankrupt_3y) / runs, "bankrupt_any": float(bankrupt_any) / runs,
		"avg_score": _mean(scores), "campaigns_per_run": float(campaigns) / runs,
		"scores_by_year": scores_by_year, "cash_by_year": cash_by_year}


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
		header += " | %14s | %6s" % [_label(kind) + " nakit", "puan"]
	print(header)
	for y: int in years:
		var line: String = "Y%-4d" % (y + 1)
		for kind: String in results:
			var r: Dictionary = results[kind]
			line += " | %14s | %6.2f" % [_money(_median(r["cash_by_year"][y])), _mean(r["scores_by_year"][y])]
		print(line)
	var diff: float = float(results["smart"]["avg_score"]) - float(results["random"]["avg_score"])
	var rb: float = 100.0 * float(results["random"]["bankrupt_3y"])
	print("")
	print("M1 kabul: puan farkı %.2f (hedef ≥ 2) %s · rastgele bot ilk 3 yılda iflas %%%.1f (hedef %%20–40) %s" % [
		diff, "✓" if diff >= 2.0 else "✗", rb, "✓" if rb >= 20.0 and rb <= 40.0 else "✗"])


func _label(kind: String) -> String:
	return "rastgele" if kind == "random" else "bilgili"


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
