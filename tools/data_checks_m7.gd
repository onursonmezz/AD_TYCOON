extends RefCounted
## M7-C veri kontrolleri: data/events/*.json (GDD 16). Anahtarlar EventSystem/EventEffects'in tanıdıklarıyla sınırlı.

const TRIGGERS: Array[String] = ["weekly", "production", "airing", "fixed"]
const MIN_PER_CATEGORY: int = 10
const MAX_OPTIONS: int = 4
const TOP_EFFECTS: Array[String] = ["cash", "reputation", "award_buzz", "research_points", "prospect_brief", "macro"]
const PREFIX_EFFECTS: Dictionary = {
	"client": ["satisfaction", "trust", "budget", "leave", "brief"],
	"clients": ["satisfaction"],
	"employee": ["morale", "energy", "burnout", "salary", "xp", "stat", "leave_weeks", "quit", "award_points"],
	"employee2": ["morale", "energy", "burnout", "salary", "xp", "stat", "leave_weeks", "quit", "award_points"],
	"team": ["morale", "energy", "burnout"],
	"campaign": ["days", "errors", "quality", "kpi", "satisfaction", "fee_bonus"],
	"rival": ["reputation"],
	"plants": ["water", "dry"],
}
const TOP_CONDITIONS: Array[String] = ["year", "month", "reputation", "staff", "clients", "office_level", "era", "cash_1990",
	"plants", "research", "no_research", "years", "room", "position"]
const PREFIX_CONDITIONS: Dictionary = {
	"client": ["risk", "detail", "pay", "ego", "loyalty", "satisfaction", "trust", "scale"],
	"employee": ["morale", "energy", "burnout", "level", "salary_ratio", "stat", "trait"],
	"employee2": ["morale", "energy", "burnout", "level", "salary_ratio", "stat"],
	"campaign": ["phase", "size", "score", "errors", "channels", "category"],
}
const MACRO_KEYS: Array[String] = ["months", "budget_mult", "impressions", "cost"]


static func check(data: Dictionary) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	var balance: Dictionary = data.get("balance.json", {}) if typeof(data.get("balance.json")) == TYPE_DICTIONARY else {}
	var categories: Array = balance.get("events", {}).get("categories", [])
	var stats: Array = balance.get("staff_rules", {}).get("stats", [])
	var research: Array = []
	for r: Variant in data.get("research.json", []):
		if typeof(r) == TYPE_DICTIONARY:
			research.append(r.get("id"))
	var channel_categories: Array = []
	for ch: Variant in data.get("channels.json", []):
		if typeof(ch) == TYPE_DICTIONARY and not channel_categories.has(ch.get("category")):
			channel_categories.append(ch.get("category"))
	var seen: Dictionary = {}
	var per_category: Dictionary = {}
	for file_name: String in data:
		if not file_name.begins_with("events/"):
			continue
		if typeof(data[file_name]) != TYPE_ARRAY:
			errors.append("%s: dizi olmalı" % file_name)
			continue
		for ev: Variant in data[file_name]:
			if typeof(ev) != TYPE_DICTIONARY:
				errors.append("%s: kayıt sözlük olmalı" % file_name)
				continue
			var id: String = str(ev.get("id", ""))
			var where: String = "%s: '%s'" % [file_name, id]
			if id.is_empty() or seen.has(id):
				errors.append("%s boş ya da tekrar eden id" % where)
			seen[id] = true
			var cat: String = str(ev.get("category", ""))
			if not categories.has(cat):
				errors.append("%s bilinmeyen kategori '%s'" % [where, cat])
			per_category[cat] = int(per_category.get(cat, 0)) + 1
			if not TRIGGERS.has(str(ev.get("trigger", ""))):
				errors.append("%s bilinmeyen tetik '%s'" % [where, str(ev.get("trigger", ""))])
			for key: Variant in ev.get("conditions", {}):
				if not _known(str(key), TOP_CONDITIONS, PREFIX_CONDITIONS):
					errors.append("%s bilinmeyen koşul '%s'" % [where, str(key)])
			var conds: Dictionary = ev.get("conditions", {})
			for key: String in ["research", "no_research"]:
				if conds.has(key) and not research.has(conds[key]):
					errors.append("%s bilinmeyen araştırma '%s'" % [where, str(conds[key])])
			if conds.has("campaign.category") and not channel_categories.has(conds["campaign.category"]):
				errors.append("%s bilinmeyen kanal kategorisi '%s'" % [where, str(conds["campaign.category"])])
			var opts: Variant = ev.get("options", [])
			if typeof(opts) != TYPE_ARRAY or (opts as Array).is_empty() or (opts as Array).size() > MAX_OPTIONS:
				errors.append("%s 1..%d seçenek olmalı" % [where, MAX_OPTIONS])
				continue
			if (opts[0] as Dictionary).has("requires_research"):
				errors.append("%s ilk seçenek (varsayılan) araştırma isteyemez" % where)
			for opt: Dictionary in opts:
				var req: String = str(opt.get("requires_research", ""))
				if not req.is_empty() and not research.has(req):
					errors.append("%s bilinmeyen araştırma '%s'" % [where, req])
				var parts: Array[String] = ["effects"]
				if opt.has("check"):
					parts = ["success", "fail"]
					var check: Dictionary = opt["check"]
					if not stats.has(check.get("stat")) or not (check.get("dc") is float or check.get("dc") is int):
						errors.append("%s geçersiz stat kontrolü" % where)
				for part: String in parts:
					if not opt.has(part):
						errors.append("%s seçenekte '%s' yok" % [where, part])
						continue
					for key: Variant in opt[part]:
						errors.append_array(_check_effect(where, str(key), opt[part][key], stats, channel_categories))
	for cat: Variant in categories:
		if int(per_category.get(cat, 0)) < MIN_PER_CATEGORY:
			errors.append("events: '%s' kategorisinde en az %d olay olmalı (%d var)" % [str(cat), MIN_PER_CATEGORY,
				int(per_category.get(cat, 0))])
	return errors


static func _known(key: String, top: Array[String], prefixed: Dictionary) -> bool:
	var parts: PackedStringArray = key.split(".")
	if parts.size() == 1:
		return top.has(key)
	return prefixed.has(parts[0]) and (prefixed[parts[0]] as Array).has(parts[1])


static func _check_effect(where: String, key: String, value: Variant, stats: Array, channel_categories: Array) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if not _known(key, TOP_EFFECTS, PREFIX_EFFECTS):
		errors.append("%s bilinmeyen etki '%s'" % [where, key])
		return errors
	var parts: PackedStringArray = key.split(".")
	if parts.size() > 1 and parts[1] == "stat" and (parts.size() < 3 or not stats.has(parts[2])):
		errors.append("%s bilinmeyen stat etkisi '%s'" % [where, key])
	if key == "macro":
		if typeof(value) != TYPE_DICTIONARY:
			errors.append("%s macro sözlük olmalı" % where)
			return errors
		for k: Variant in value:
			if not MACRO_KEYS.has(k):
				errors.append("%s bilinmeyen macro alanı '%s'" % [where, str(k)])
		for field: String in ["impressions", "cost"]:
			for c: Variant in value.get(field, {}):
				if not channel_categories.has(c):
					errors.append("%s bilinmeyen kanal kategorisi '%s'" % [where, str(c)])
	return errors
