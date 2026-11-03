class_name ChannelOptions
extends RefCounted
## Kanal kategorisi seçenekleri (GDD 9.2–9.7): açık hava, yayın, dijital/sosyal, gerilla, etkinlik.
## Seçenekler ve etkileri data/channel_options.json'da; burada yalnızca yorumlanır.
## Karışım girdisi: { "channel", "share", "options": { "<seçenek id>": "<seçim id>", ... } }

const SCALAR_EFFECTS: Array[String] = ["cost_mult", "impressions_mult", "er_mult", "cvr_mult", "recall_mult"]

var data: GameData


func _init(game_data: GameData) -> void:
	data = game_data


func _cfg() -> Dictionary:
	return data.raw.get("channel_options.json", {})


func category_of(channel_id: String) -> String:
	return str(data.channels[channel_id]["category"])


func _category(channel_id: String) -> Dictionary:
	var cats: Dictionary = _cfg().get("categories", {})
	var c: Dictionary = cats.get(category_of(channel_id), {})
	if c.has("same_as"):
		return cats.get(c["same_as"], {})
	return c


## Bu kanalın seçenek tanımları (yoksa []).
func option_defs(channel_id: String) -> Array:
	return _category(channel_id).get("options", [])


func _choice(def: Dictionary, choice_id: String) -> Dictionary:
	for c: Dictionary in def["choices"]:
		if str(c["id"]) == choice_id:
			return c
	return {}


## "Otomatik" seçimler: her seçeneğin varsayılanı (o yıl açık olmayanlar atlanır).
func defaults(channel_id: String) -> Dictionary:
	var out: Dictionary = {}
	for def: Dictionary in option_defs(channel_id):
		out[def["id"]] = str(def["default"])
	return out


## done: tamamlanan araştırmalar (ör. CPA teklif modeli Performans Pazarlama ister, GDD 17).
func validate(channel_id: String, options: Dictionary, year: int, done: Array = []) -> String:
	for def: Dictionary in option_defs(channel_id):
		var c: Dictionary = _choice(def, str(options.get(def["id"], "")))
		if c.is_empty() or int(c.get("from_year", 0)) > year or (c.has("research") and not done.has(c["research"])):
			return "ERR_CHANNEL_OPTION"
	return ""


## Prodüksiyon payı (TV çekimi, etkinlik): bütçenin bu kısmı medya değil prodüksiyondur; ajans marj alır.
func production(channel_id: String) -> Dictionary:
	var p: Dictionary = _category(channel_id).get("production", {})
	if p.is_empty():
		return {}
	if p.has("channels") and not (p["channels"] as Array).has(channel_id):
		return {}
	return p


## Seçeneklerin ve teslimde yaşanan risklerin birleşik etkisi.
func effects(channel_id: String, options: Dictionary, setup: Dictionary, year: int) -> Dictionary:
	var e: Dictionary = {}
	for key: String in SCALAR_EFFECTS:
		e[key] = 1.0
	for def: Dictionary in option_defs(channel_id):
		_apply(e, _choice(def, str(options.get(def["id"], ""))).get("effects", {}), setup, year)
	for outcome: Variant in options.get("_outcomes", []):
		_apply(e, outcome.get("effects", {}), setup, year)
	var bonus: float = float(_category(channel_id).get("measurement_bonus", {}).get(channel_id, 0.0))
	if bonus > 0.0:
		var ids: Array[String] = data.focus_ids_of_phase(2)
		var share: float = float(setup["sliders"][2][ids.find("measurement")])
		e["er_mult"] = float(e["er_mult"]) * (1.0 + bonus * share)
	return e


func _apply(e: Dictionary, fx: Dictionary, setup: Dictionary, year: int) -> void:
	for key: String in SCALAR_EFFECTS:
		if fx.has(key):
			e[key] = float(e[key]) * float(fx[key])
	if fx.has("audience_mult"):
		e["impressions_mult"] = float(e["impressions_mult"]) * float(fx["audience_mult"].get(setup["audience"], 1.0))
	if fx.has("objective_mult"):
		e["er_mult"] = float(e["er_mult"]) * float(fx["objective_mult"].get(setup["objective"], 1.0))
	if fx.has("after_year") and year >= int(fx["after_year"]):
		_apply(e, fx["after_effects"], setup, year)


## Teslimde riskler (GDD 9.2 belediye izni, 9.3 gerilla cezası, 9.4 yayın kurulu, 9.7 etkinlik riskleri).
## Dönüş: gerçekleşen sonuçlar [{ "note", "effects", "fine", "satisfaction" }]. Etki azaltan çalışan varsa olasılık yarıya iner.
func roll_risks(channel_id: String, options: Dictionary, setup: Dictionary, billed: float, state: SimState) -> Array[Dictionary]:
	var risks: Array = []
	for def: Dictionary in option_defs(channel_id):
		var c: Dictionary = _choice(def, str(options.get(def["id"], "")))
		if c.has("risk"):
			risks.append(c["risk"])
	var cat: Dictionary = _category(channel_id)
	if cat.get("channel_risks", {}).has(channel_id):
		risks.append(cat["channel_risks"][channel_id])
	if cat.has("tone_risk") and str(cat["tone_risk"]["tone"]) == str(setup["tone"]):
		risks.append(cat["tone_risk"])
	if cat.has("base_risk"):
		risks.append(cat["base_risk"])
	var out: Array[Dictionary] = []
	for risk: Dictionary in risks:
		var p: float = float(risk["chance"])
		if risk.has("reduced_by") and _team_has(state, setup.get("team", []), str(risk["reduced_by"])):
			p *= float(_cfg().get("risk_reduce_mult", 1.0))
		if state.rng.chance("channel_risk", p):
			out.append({"note": risk.get("note", ""), "effects": risk.get("effects", {}),
				"fine": billed * float(risk.get("fine_share", 0.0)), "satisfaction": float(risk.get("satisfaction", 0.0)),
				"channel": channel_id})
	return out


func _team_has(state: SimState, team: Array, effect: String) -> bool:
	for id: Variant in team:
		var emp: Dictionary = state.staff.get(str(id), {})
		if not emp.is_empty() and Employee.has_effect(data, emp, effect):
			return true
	return false


## Gerilla basına çıkarsa erişim katlanır (GDD 9.3): olasılık = 0.25 + 0.05 × (puan − 6); PR uzmanı artırır.
func guerrilla_press(channel_id: String, score: float, team: Array, state: SimState) -> bool:
	var press: Dictionary = _category(channel_id).get("press", {})
	if press.is_empty():
		return false
	var p: float = float(press["base"]) + float(press["per_point"]) * (score - float(press["pivot"]))
	if _team_has(state, team, "pr_press"):
		p *= float(press.get("pr_mult", 1.0))
	return state.rng.chance("channel_risk", clampf(p, 0.0, 1.0))


func press_mult(channel_id: String) -> float:
	return float(_category(channel_id).get("press", {}).get("impressions_mult", 1.0))
