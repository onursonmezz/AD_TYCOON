class_name RepeaterBot
extends SmartBot
## Tekrarcı bot (GDD 27.1): bilgili bot gibi oynar ama ilk bulduğu iyi kitle, ton ve kanalı hep tekrarlar.
## Tekrar cezasının (yenilik N) yeterli olup olmadığını ölçer: bilgili bottan en az 1.5 puan düşük olmalı (27.2).

var _fixed: Dictionary = {}


func bot_name() -> String:
	return "tekrarcı"


func best_choices(sim: Simulation, brief: Dictionary) -> Dictionary:
	var c: Dictionary = super.best_choices(sim, brief)
	if _fixed.is_empty():
		_fixed = {"audience": c["audience"], "tone": c["tone"], "channel": c["mix"][0]["channel"]}
		return c
	c["audience"] = _fixed["audience"]
	c["tone"] = _fixed["tone"]
	if BotUtil.valid_channels(sim, brief).has(_fixed["channel"]):
		c["mix"] = [{"channel": _fixed["channel"], "share": 1.0}]
	return c
