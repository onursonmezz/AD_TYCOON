class_name Minigames
extends RefCounted
## Fazlar arası mini oyunlar (K-120): 3–5 saniyelik, atlanabilir, kampanyanın ana kanalına göre seçilen küçük oyunlar
## ve kreatif fazdan sonra ekibin 3 taslağından seçim. Puana etkisi en çok %5: ham puan × (1 + max_bonus × ortalama
## başarı). Atlanan ya da oynanmayan oyun 0 sayılır, ceza yoktur. Sayılar balance.json "minigames".
## Kayıt: campaign.minigames = {"0": başarı 0..1, "1": …}; seçilen taslak campaign.setup.draft.

const DRAFT: String = "draft"


static func _m(data: GameData) -> Dictionary:
	return data.bal("minigames")


## Fazın başında oynanacak oyun: 0 ve 1. fazda kanal oyunu, 2. fazda (kreatif bitti) taslak seçimi.
static func game_for(data: GameData, setup: Dictionary, phase: int) -> String:
	if phase >= 2:
		return DRAFT
	var cfg: Dictionary = _m(data)
	var pool: Array = cfg["pool"]
	var main: String = Scoring.main_channel(setup.get("mix", []))
	var first: String = str((cfg["by_channel"] as Dictionary).get(main, ""))
	if first.is_empty() and data.channels.has(main):
		first = str((cfg["by_category"] as Dictionary).get(str(data.channels[main]["category"]), ""))
	if first.is_empty():
		first = str(pool[absi(hash(str(setup.get("client_id", "")))) % pool.size()])
	if phase == 0:
		return first
	# 1. fazda başka bir oyun: havuzda bir sonraki.
	return str(pool[(pool.find(first) + 1) % pool.size()])


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
