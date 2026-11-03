class_name CampaignStarter
extends RefCounted
## Brief'ten kampanya kurulumu (GDD 4.2, 6.2): seçimleri doğrular, müşteriyi portföye alır, KPI hedefini ve medya
## avansını yazar. simulation.gd 400 satırı aşmasın diye ayrı. Ton ve kitle araştırılmadıysa "otomatik" (nötr) kalır (M7-B).


## choices: { "objective" (brief serbestse), "audience", "tone", "mix": [{channel, share}], "sliders": [[..]x3], "name", "team" }
## Dönüş: { "ok": bool, "error": hata anahtarı, "campaign_id" }
static func start(sim: Simulation, brief_id: String, choices: Dictionary) -> Dictionary:
	var state: SimState = sim.state
	if not state.is_idle():
		return {"ok": false, "error": "ERR_BUSY"}
	var brief: Dictionary = state.find_brief(brief_id)
	if brief.is_empty():
		return {"ok": false, "error": "ERR_NO_BRIEF"}
	var objective: String = brief["objective"] if not str(brief["objective"]).is_empty() else str(choices.get("objective", ""))
	var sliders: Array = choices.get("sliders", [])
	if sliders.is_empty():
		var third: float = 1.0 / 3.0
		sliders = [[third, third, third], [third, third, third], [third, third, third]]
	var brief_client: Dictionary = brief["prospect"] if not (brief["prospect"] as Dictionary).is_empty() \
		else state.clients.get(brief["client_id"], {})
	var audience: String = str(choices.get("audience", "")) if sim.research.has(state, "audience_analysis") else ""
	var tone: String = str(choices.get("tone", "")) if sim.research.has(state, "tone_choice") else ""
	var setup: Dictionary = {"client_id": brief["client_id"], "sector": brief["sector"], "objective": objective,
		"audience": audience, "tone": tone, "mix": choices.get("mix", []),
		"sliders": sliders, "name": choices.get("name", ""), "size": brief["size"],
		"fee": brief["fee"], "media_budget": brief["media_budget"], "deadline_weeks": brief["deadline_weeks"],
		"client_name": brief_client.get("name", ""), "client_scale": int(brief_client.get("scale", 0)),
		"ai_penalty": state.ai_penalty * sim.research.ai_penalty_mult(state), "series": sim.research.has(state, "series_campaign"),
		"category_er_mult": {"social": sim.data.balf("research.social_er_mult")} if sim.research.has(state, "social_media_management") else {}}
	var team: Array = choices.get("team", [])
	if team.is_empty():
		team = [state.founder()["id"]]
	setup["team"] = team.duplicate()
	var err: String = sim.production.validate_setup(setup, state.clock.year())
	for entry: Dictionary in setup["mix"]:
		if err.is_empty() and sim.data.channels.has(str(entry.get("channel", ""))) and not sim.research.channel_unlocked(state, entry["channel"]):
			err = "ERR_CHANNEL_LOCKED"
	if err.is_empty():
		err = sim.production.validate_team(team, state)
	if err.is_empty():
		err = sim.media.prepare_mix(setup, state)
	if not err.is_empty():
		return {"ok": false, "error": err}
	var prospect: Dictionary = brief["prospect"]
	if prospect.is_empty() and not state.clients.has(brief["client_id"]):
		state.inbox.erase(brief)
		return {"ok": false, "error": "ERR_NO_BRIEF"}
	if not prospect.is_empty():
		state.clients[prospect["id"]] = prospect
	var client: Dictionary = state.clients[setup["client_id"]]
	setup["kpi_type"] = sim.kpi.kpi_type(objective)
	setup["kpi_target"] = sim.kpi.reference_value(objective, float(setup["media_budget"]), client, state.clock.year()) \
		* float(brief["kpi_factor"])
	setup["media_advance"] = sim.economy.media_advance(client, float(setup["media_budget"]))
	state.cash += float(setup["media_advance"])
	state.inbox.erase(brief)
	var id: String = state.next_id("cp")
	state.active_campaign = sim.production.create(setup, id, state.clock.week_index)
	return {"ok": true, "error": "", "campaign_id": id}
