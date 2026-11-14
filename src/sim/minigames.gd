class_name Minigames
extends RefCounted
## Fazlar arası mini oyunlar (K-120): 3–5 saniyelik, atlanabilir, kampanyanın ana kanalına göre seçilen küçük oyunlar
## ve kreatif fazdan sonra ekibin 3 taslağından seçim. Puana etkisi en çok %5: ham puan × (1 + max_bonus × ortalama
## başarı). Atlanan ya da oynanmayan oyun 0 sayılır, ceza yoktur. Sayılar balance.json "minigames".
## Kayıt: campaign.minigames = {"0": başarı 0..1, "1": …}; seçilen taslak campaign.setup.draft.

const DRAFT: String = "draft"


static func _m(data: GameData) -> Dictionary:
	return data.bal("minigames")


## Fazın başında oynanacak oyun: 1. fazda strateji oyunu (hedef kitle ya da konum), 2. fazda ana kanalın oyunu,
## 3. fazda (kreatif bitti) taslak seçimi. İki oyun aynı çıkmaz.
static func game_for(data: GameData, setup: Dictionary, phase: int) -> String:
	if phase >= 2:
		return DRAFT
	var channel_game: String = _channel_game(data, setup)
	if phase == 1:
		return channel_game
	var cfg: Dictionary = _m(data)
	var main: String = Scoring.main_channel(setup.get("mix", []))
	var category: String = str(data.channels[main]["category"]) if data.channels.has(main) else ""
	var strategy: String = str((cfg["strategy_by_category"] as Dictionary).get(category, cfg["strategy_default"]))
	if strategy == channel_game:
		strategy = "audience" if strategy != "audience" else "map"
	return strategy


static func _channel_game(data: GameData, setup: Dictionary) -> String:
	var cfg: Dictionary = _m(data)
	var main: String = Scoring.main_channel(setup.get("mix", []))
	var game: String = str((cfg["by_channel"] as Dictionary).get(main, ""))
	if game.is_empty() and data.channels.has(main):
		game = str((cfg["by_category"] as Dictionary).get(str(data.channels[main]["category"]), ""))
	if game.is_empty():
		var pool: Array = cfg["pool"]
		game = str(pool[absi(hash(str(setup.get("client_id", "")))) % pool.size()])
	return game


static func pending(campaign: Dictionary, phase: int) -> bool:
	if phase >= 2:
		return not (campaign["setup"] as Dictionary).has("draft")
	return not (campaign.get("minigames", {}) as Dictionary).has(str(phase))


## Kanal oyununun sonucu (0..1; atlandıysa 0).
static func record(campaign: Dictionary, phase: int, quality: float) -> void:
	(campaign.get_or_add("minigames", {}) as Dictionary)[str(phase)] = clampf(quality, 0.0, 1.0)


## Seçilen taslak: { bg, product, fx, layout, slogan } (görsel adları ve düzen sırası).
static func choose_draft(campaign: Dictionary, draft: Dictionary) -> void:
	campaign["setup"]["draft"] = draft.duplicate()


## Ham puan çarpanı: 1 + max_bonus × (kanal oyunlarının başarı toplamı / kampanya başına kanal oyunu sayısı).
static func mult(data: GameData, campaign: Dictionary) -> float:
	var cfg: Dictionary = _m(data)
	var results: Dictionary = campaign.get("minigames", {})
	var total: float = 0.0
	for k: Variant in results:
		total += float(results[k])
	return 1.0 + float(cfg["max_bonus"]) * minf(1.0, total / maxf(1.0, float(cfg["scoring_games"])))
