class_name InfluencerSystem
extends RefCounted
## Influencer havuzu ve skandallar (GDD 9.6). Havuz SimState.influencers'ta, her oyun yılı yenilenir.
## Influencer: { id, name, niche, tier, followers, er, audience {young, adult, mature}, fee, authenticity (gizli),
##               scandal_chance (gizli) }. Karışım girdisinde options.influencer = id.

var data: GameData


func _init(game_data: GameData) -> void:
	data = game_data


func _cfg() -> Dictionary:
	return data.raw.get("channel_options.json", {}).get("influencers", {})


static func is_influencer_channel(game_data: GameData, channel_id: String) -> bool:
	for tier: Dictionary in game_data.raw.get("channel_options.json", {}).get("influencers", {}).get("tiers", {}).values():
		if str(tier["channel"]) == channel_id:
			return true
	return false


## Haftalık: havuz boşsa ya da süresi dolduysa yeniler (influencer kanalları açıldıktan sonra).
func weekly(state: SimState, lang: String = "tr") -> void:
	var cfg: Dictionary = _cfg()
	var any_open: bool = false
	for tier: Dictionary in cfg.get("tiers", {}).values():
		if int(data.channels[tier["channel"]]["available_from"]) <= state.clock.year():
			any_open = true
	if not any_open:
		return
	if state.influencers.is_empty() or state.clock.week_index - state.influencer_pool_week >= int(cfg["refresh_weeks"]):
		refresh(state, lang)


func refresh(state: SimState, lang: String = "tr") -> void:
	var cfg: Dictionary = _cfg()
	var tiers: Dictionary = cfg["tiers"]
	var open: Array[String] = []
	for tier_id: String in tiers:
		if int(data.channels[tiers[tier_id]["channel"]]["available_from"]) <= state.clock.year():
			open.append(tier_id)
	var names: Dictionary = data.names(lang)
	var niches: Array = (cfg["niches"] as Dictionary).keys()
	state.influencers = []
	var infl: float = Economy.inflation(data, state.clock.year())
	for i: int in int(cfg["pool_size"]):
		var tier_id: String = open[i % open.size()]
		var t: Dictionary = tiers[tier_id]
		var young: float = state.rng.range_f("influencers", float(cfg["young_share"][0]), float(cfg["young_share"][1]))
		var adult: float = state.rng.range_f("influencers", 0.1, 1.0 - young)
		state.influencers.append({"id": state.next_id("in"), "tier": tier_id,
			"name": "@" + str(state.rng.pick("influencers", names["neutral"] + names["female"] + names["male"])).to_lower() \
				+ str(state.rng.range_i("influencers", int(cfg["handle_number"][0]), int(cfg["handle_number"][1]))),
			"niche": state.rng.pick("influencers", niches),
			"followers": roundf(state.rng.range_f("influencers", float(t["followers"][0]), float(t["followers"][1]))),
			"er": state.rng.range_f("influencers", float(t["er"][0]), float(t["er"][1])),
			"audience": {"young": young, "adult": adult, "mature": 1.0 - young - adult},
			"fee": roundf(state.rng.range_f("influencers", float(t["fee_1990"][0]), float(t["fee_1990"][1])) * infl),
			"authenticity": state.rng.range_f("influencers", float(cfg["authenticity"][0]), float(cfg["authenticity"][1])),
			"scandal_chance": state.rng.range_f("influencers", float(cfg["scandal_chance"][0]), float(cfg["scandal_chance"][1]))})
	state.influencer_pool_week = state.clock.week_index


func find(state: SimState, influencer_id: String) -> Dictionary:
	for inf: Dictionary in state.influencers:
		if inf["id"] == influencer_id:
			return inf
	return {}


## Bu kanala uygun (kademe) havuz.
func pool_for(state: SimState, channel_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for inf: Dictionary in state.influencers:
		if str(_cfg()["tiers"][inf["tier"]]["channel"]) == channel_id:
			out.append(inf)
	return out


## Aynı influencer ile tekrar çalışınca indirim (en fazla %20) ve "samimiyet" etkileşim bonusu.
func fee(state: SimState, inf: Dictionary) -> float:
	var times: int = int(state.influencer_history.get(inf["id"], 0))
	var d: float = minf(float(_cfg()["repeat_discount_max"]), float(_cfg()["repeat_discount"]) * times)
	return float(inf["fee"]) * (1.0 - d)


## PR & Etkinlik ekibinden biri varsa sahte takipçi (gerçeklik oranı) görünür (GDD 11.1).
func can_see_authenticity(state: SimState) -> bool:
	for emp: Dictionary in state.staff.values():
		if Employee.has_effect(data, emp, str(_cfg()["reveal_effect"])):
			return true
	return false


## "Otomatik": bütçeye sığanlar içinde görünen değeri (takipçi × etkileşim × kitle uyumu / ücret) en iyi olan.
func auto_pick(state: SimState, channel_id: String, budget: float, setup: Dictionary) -> String:
	var best: String = ""
	var best_value: float = -1.0
	var see: bool = can_see_authenticity(state)
	for inf: Dictionary in pool_for(state, channel_id):
		var f: float = fee(state, inf)
		if f > budget:
			continue
		var v: float = float(inf["followers"]) * float(inf["er"]) * audience_match(inf, setup) * niche_mult(inf, setup) / f
		if see:
			v *= float(inf["authenticity"])
		if v > best_value:
			best_value = v
			best = inf["id"]
	return best


func audience_match(inf: Dictionary, setup: Dictionary) -> float:
	var aud: String = setup["audience"]
	if aud == "b2b":
		return float(_cfg()["b2b_match"])
	return float(inf["audience"].get(aud, 0.0)) * float(_cfg()["audience_norm"])


func niche_mult(inf: Dictionary, setup: Dictionary) -> float:
	var sectors: Array = _cfg()["niches"].get(inf["niche"], [])
	return float(_cfg()["niche_match_mult"]) if sectors.has(setup["sector"]) else 1.0


## Görülme = paylaşım sayısı (bütçe/ücret, en fazla 4) × takipçi × paylaşım erişimi × gerçeklik oranı.
func kpi_inputs(state: SimState, inf: Dictionary, budget: float, setup: Dictionary) -> Dictionary:
	var cfg: Dictionary = _cfg()
	var posts: float = clampf(floorf(budget / maxf(1.0, fee(state, inf))), 1.0, float(cfg["max_posts"]))
	var impressions: float = posts * float(inf["followers"]) * float(cfg["post_reach"]) * float(inf["authenticity"])
	var repeat: float = 1.0 + float(cfg["repeat_er_bonus"]) * minf(1.0, float(state.influencer_history.get(inf["id"], 0)))
	var er: float = float(inf["er"]) * audience_match(inf, setup) * niche_mult(inf, setup) * repeat
	return {"impressions": impressions, "er": er, "posts": posts}


func record_collab(state: SimState, influencer_id: String) -> void:
	state.influencer_history[influencer_id] = int(state.influencer_history.get(influencer_id, 0)) + 1


## Teslimde (yayın başlarken) skandal patlayabilir; oyuncu karar verir (GDD 9.6). Dönüş: skandal kaydı ya da {}.
func maybe_scandal(state: SimState, campaign_id: String, inf: Dictionary) -> Dictionary:
	if not state.rng.chance("influencers", float(inf["scandal_chance"])):
		return {}
	var s: Dictionary = {"id": state.next_id("sc"), "campaign_id": campaign_id, "influencer": inf["name"],
		"expires_week": state.clock.week_index + int(_cfg()["scandal"]["response_weeks"])}
	state.scandals.append(s)
	return s


## Skandal kararı: "terminate" / "silent" / "statement" (iletişim zar atışı). Etkiler kampanyaya yazılır.
func resolve_scandal(state: SimState, scandal_id: String, choice: String) -> Dictionary:
	var scandal: Dictionary = {}
	for s: Dictionary in state.scandals:
		if s["id"] == scandal_id:
			scandal = s
	if scandal.is_empty():
		return {}
	state.scandals.erase(scandal)
	var opt: Dictionary = _cfg()["scandal"]["options"].get(choice, _cfg()["scandal"]["options"]["silent"])
	var satisfaction: float = float(opt.get("satisfaction", 0.0))
	var success: bool = true
	if opt.has("check_stat"):
		var best: float = 0.0
		for emp: Dictionary in state.staff.values():
			best = maxf(best, float(emp["stats"][opt["check_stat"]]))
		success = state.rng.range_f("influencers", 0.0, 100.0) + best / 2.0 >= float(opt["dc"])
		satisfaction = float(opt["success_satisfaction"] if success else opt["fail_satisfaction"])
	var result: Dictionary = {"choice": choice, "success": success, "satisfaction": satisfaction,
		"impressions_mult": float(opt["impressions_mult"]), "reputation": float(opt.get("reputation", 0.0))}
	for camp: Dictionary in state.airing:
		if camp["id"] == scandal["campaign_id"]:
			camp["scandal"] = result
	state.reputation = clampf(state.reputation + float(result["reputation"]), data.balf("reputation.min"), data.balf("reputation.max"))
	return result


## Süresi dolan skandallar "sessiz kal" sayılır.
func expire_scandals(state: SimState) -> void:
	for s: Dictionary in state.scandals.duplicate():
		if int(s["expires_week"]) <= state.clock.week_index:
			resolve_scandal(state, s["id"], "silent")
