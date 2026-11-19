extends GutTest
## S9: olay metninde boş ya da açık kalan yer olmaz; her olay türünün iyi/kötü/karışık sonuç cümlesi var.


func test_untitled_campaign_uses_client_name() -> void:
	var args: Dictionary = EventDialog.with_fallbacks({"campaign": "", "client": "Ali Usta"})
	assert_eq(args["campaign"], "Ali Usta")
	var none: Dictionary = EventDialog.with_fallbacks({})
	for k: String in ["client", "campaign", "rival", "brand"]:
		assert_false(str(none[k]).is_empty(), "%s boş kalmaz" % k)


func test_every_event_text_fills_all_placeholders() -> void:
	var args: Dictionary = EventDialog.with_fallbacks({"employee": "Ayşe", "employee2": "Mehmet"})
	TranslationServer.set_locale("tr")
	var events: EventSystem = EventSystem.new(GameData.load_from())
	for id: String in events.event_ids:
		for part: String in ["T", "X"]:
			var text: String = TranslationServer.translate(EventSystem.text_key(id, part)).format(args)
			assert_false(text.contains("{"), "%s_%s açık yer: %s" % [id, part, text])
			assert_false(text.contains("''"), "%s_%s boş tırnak: %s" % [id, part, text])


func test_every_category_has_aftermath_lines() -> void:
	TranslationServer.set_locale("tr")
	for cat: Variant in DataDB.data.bal("events.categories"):
		for tone: int in [-1, 0, 1]:
			assert_false(EventDialog.aftermath(str(cat), tone, "ev7").is_empty(), "%s %d cümlesi" % [cat, tone])


func test_effect_tones_know_what_is_bad() -> void:
	var tones: Array[int] = EventDialog.effect_tones({"cash": -500.0, "team.burnout": 5.0, "rival.reputation": -3.0,
		"employee.quit": true})
	assert_eq(tones, [-1, -1, 1, -1] as Array[int])
	assert_eq(EventDialog.overall_tone({"cash": -500.0, "reputation": 3.0}), 0, "karışık")
