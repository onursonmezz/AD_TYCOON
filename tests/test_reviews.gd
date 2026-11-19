extends GutTest
## Yorumlar (S4): her yayının kendi havuzu; aynı raporda bir cümle iki kez çıkmaz; her anahtarın çevirisi var.

var data: GameData


func before_all() -> void:
	data = GameData.load_from()


func test_no_repeated_line_in_one_report() -> void:
	var writer: ReportWriter = ReportWriter.new(data)
	for seed: int in 200:
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = seed
		var score: float = 1.0 + float(seed % 90) / 10.0
		var keys: Array = []
		for r: Dictionary in writer.reviews(score, rng):
			assert_false(keys.has(r["text_key"]), "tohum %d: tekrar eden yorum %s" % [seed, r["text_key"]])
			keys.append(r["text_key"])


func test_each_outlet_has_its_own_voice() -> void:
	var writer: ReportWriter = ReportWriter.new(data)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 5
	var reviews: Array[Dictionary] = writer.reviews(6.0, rng)
	assert_eq(reviews.size(), 4)
	assert_true(str(reviews[0]["text_key"]).begins_with("REV_RD_"), "Reklam Dünyası kendi havuzundan")
	assert_true(str(reviews[3]["text_key"]).begins_with("REV_MU_"), "müşteri kendi havuzundan")


func test_all_review_keys_are_translated() -> void:
	var cfg: Dictionary = data.raw["report_lines.json"]
	var keys: Array = []
	for r: Dictionary in cfg["reviewers"]:
		for band: Array in r["bands"]:
			keys.append_array(band)
	for a: Dictionary in cfg["review_aspects"]:
		keys.append_array(a["keys"])
	for k: Variant in keys:
		assert_ne(TranslationServer.translate(str(k)), str(k), "çevirisi yok: %s" % k)
