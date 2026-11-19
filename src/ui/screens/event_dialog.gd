class_name EventDialog
extends Control
## Olay penceresi (GDD 16): başlık, metin, seçenekler. Stat kontrolü olan seçenekte kontrolün türü ve yaklaşık şans
## görünür. Seçim yapılınca sonuç (başarılı/olmadı ve etkiler) gösterilir. Karar verilene kadar oyun durur.

var _inst: Dictionary
var _col: VBoxContainer
var _buttons: VBoxContainer


func _init(inst: Dictionary) -> void:
	_inst = inst


func _ready() -> void:
	var sim: Simulation = GameState.sim
	var ev: Dictionary = sim.events.events[_inst["id"]]
	_col = UiUtil.modal_frame(self, UiUtil.dialog_size("event"), true, true)
	_col.add_child(UiUtil.heading(_text("T"), "alert-triangle" if _inst["category"] == "crisis" else "bell"))
	# UI-3 (taslak 10): olay türü etiketi, metin, altında oklu seçenek satırları.
	var cat: HBoxContainer = UiUtil.hbox()
	cat.add_child(Cards.chip(tr("UI_EVENT_CAT_" + str(_inst["category"]).to_upper())))
	_col.add_child(cat)
	_col.add_child(UiUtil.wrapped(_text("X"), 15, UiUtil.TEXT, 480.0))
	_col.add_child(HSeparator.new())
	_buttons = UiUtil.vbox(6)
	for i: Variant in _inst["options"]:
		var opt: Dictionary = ev["options"][int(i)]
		var label: String = _text("O%d" % (int(i) + 1))
		var idx: int = int(i)
		var b: Button = UiUtil.button("", func() -> void: _choose(idx))
		b.custom_minimum_size.y = 42.0
		var row: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, CozyTheme.SPACE_M)
		b.add_child(row)
		var text: Label = UiUtil.label(label, 15, CozyTheme.FOREST)
		text.add_theme_font_override("font", CozyTheme.strong_font())
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.clip_text = true
		row.add_child(text)
		if opt.has("requires_research"):  # UI-4: araştırmayla açılan seçenek, metin içi köşeli parantez yerine etiket
			row.add_child(Cards.accent_chip("★ " + tr("UI_EVENT_RESEARCH_TAG")))
		if opt.has("check"):
			var check: Dictionary = opt["check"]
			row.add_child(UiUtil.label(tr("STAT_" + str(check["stat"]).to_upper() + "_NAME"), 13, CozyTheme.MUTED))
			row.add_child(Cards.chip(UiUtil.percent(roundf(100.0 * sim.events.check_chance(sim.state, _inst, check)))))
		row.add_child(UiUtil.icon("chevron-right", 18, CozyTheme.FOREST))
		_buttons.add_child(b)
	_col.add_child(_buttons)


func _text(part: String) -> String:
	return tr(EventSystem.text_key(_inst["id"], part)).format(_args())


func _args() -> Dictionary:
	var args: Dictionary = {}
	for k: String in _inst["args"]:
		args[k] = tr(str(_inst["args"][k]))
	for role: String in ["employee", "employee2"]:
		var emp: Dictionary = GameState.sim.state.staff.get(_inst["ctx"].get(role + "_id", ""), {})
		args[role] = GameState.employee_name(emp) if not emp.is_empty() else tr("UI_EVENT_SOMEONE")
	return with_fallbacks(args)


## S9: metinde boş ya da eksik yer kalmasın. Adı verilmemiş kampanyanın yerine müşterinin adı yazılır (eskiden "'' taslakları"
## yazıyordu); müşteri, rakip, marka yoksa genel bir söz.
static func with_fallbacks(args: Dictionary) -> Dictionary:
	var out: Dictionary = args.duplicate()
	var tr_: Callable = func(k: String) -> String: return TranslationServer.translate(k)
	if str(out.get("client", "")).is_empty():
		out["client"] = tr_.call("UI_EVENT_A_CLIENT")
	if str(out.get("campaign", "")).is_empty():
		out["campaign"] = str(out["client"])  # metinler '{campaign}' diye tırnaklı: "'Ali Usta' taslakları"
	if str(out.get("rival", "")).is_empty():
		out["rival"] = tr_.call("UI_EVENT_A_RIVAL")
	if str(out.get("brand", "")).is_empty():
		out["brand"] = str(out["client"])
	return out


func _choose(option: int) -> void:
	var r: Dictionary = GameState.execute(ResolveEventCommand.new(_inst["uid"], option))
	UiUtil.clear(_buttons)
	if not bool(r.get("ok", false)):
		queue_free()
		return
	# S9: sonuç bir cümleyle anlatılır (olay türü × iyi/kötü/karışık), etkiler renkli etiketlerde (iyi yeşil, kötü kiremit).
	var tone: int = overall_tone(r["effects"])
	if bool(r["checked"]):
		tone = 1 if bool(r["success"]) and tone >= 0 else (-1 if not bool(r["success"]) else tone)
		_buttons.add_child(UiUtil.label(tr("UI_EVENT_SUCCESS" if bool(r["success"]) else "UI_EVENT_FAIL"), 18,
			UiUtil.SAGE_DARK if bool(r["success"]) else UiUtil.TERRACOTTA))
	var story: Label = UiUtil.wrapped(aftermath(str(_inst.get("category", "")), tone, str(_inst["uid"])), 15, CozyTheme.TEXT, 460.0)
	_buttons.add_child(story)
	var flow: HFlowContainer = Cards.flow_row()
	var tones: Array[int] = effect_tones(r["effects"])
	var lines: PackedStringArray = effect_lines(r["effects"], _args())
	if lines.is_empty():
		flow.add_child(Cards.chip(tr("UI_EVENT_NOTHING"), CozyTheme.CREAM, CozyTheme.MUTED))
	for i: int in lines.size():
		var t: int = tones[i] if i < tones.size() else 0
		flow.add_child(Cards.chip(lines[i], CozyTheme.SAGE_SOFT if t > 0 else (CozyTheme.TERRA_SOFT if t < 0 else CozyTheme.CREAM),
			CozyTheme.FOREST if t > 0 else (CozyTheme.NEGATIVE if t < 0 else CozyTheme.TEXT)))
	_buttons.add_child(flow)
	var row: HBoxContainer = UiUtil.hbox()
	row.add_child(UiUtil.spacer())
	row.add_child(UiUtil.button(tr("UI_CLOSE"), queue_free))
	_buttons.add_child(row)


## Her etkinin ajans için iyi (+1), kötü (−1) ya da nötr (0) oluşu; effect_lines ile aynı sırada.
## Artınca kötü olanlar (tükenmişlik, gecikme, hata, rakibin itibarı) balance events.bad_when_up'ta; evet/hayır
## etkiler bool_tone'da.
static func effect_tones(effects: Dictionary) -> Array[int]:
	var cfg: Dictionary = DataDB.data.bal("events")
	var out: Array[int] = []
	for key: String in effects:
		var v: Variant = effects[key]
		if v is bool:
			out.append(int((cfg["bool_tone"] as Dictionary).get(key, 0)))
			continue
		if (cfg["neutral_effects"] as Array).has(key):
			out.append(0)
			continue
		var sign_: int = int(signf(float(v)))
		out.append(-sign_ if (cfg["bad_when_up"] as Array).has(key) else sign_)
	return out


static func overall_tone(effects: Dictionary) -> int:
	var good: int = 0
	var bad: int = 0
	for t: int in effect_tones(effects):
		good += 1 if t > 0 else 0
		bad += 1 if t < 0 else 0
	if good > 0 and bad > 0:
		return 0
	return 1 if good > 0 else (-1 if bad > 0 else 0)


## Sonuç cümlesi: EVR_<TÜR>_<GOOD|BAD|MIXED>_<n>; aynı olay hep aynı cümleyi alır (uid'den).
static func aftermath(category: String, tone: int, uid: String) -> String:
	var cat: String = category.to_upper() if not category.is_empty() else "OPPORTUNITY"
	var t: String = "GOOD" if tone > 0 else ("BAD" if tone < 0 else "MIXED")
	var n: int = DataDB.data.bali("events.aftermath_variants")
	var key: String = "EVR_%s_%s_%d" % [cat, t, posmod(uid.hash(), n) + 1]
	var text: String = TranslationServer.translate(key)
	return "" if text == key else text


## Uygulanan etkilerin okunur satırları (EFF_* anahtarları).
static func effect_lines(effects: Dictionary, args: Dictionary) -> PackedStringArray:
	var data: GameData = DataDB.data
	var percent: Array = data.bal("events.percent_effects")
	var out: PackedStringArray = PackedStringArray()
	for key: String in effects:
		var v: Variant = effects[key]
		var parts: PackedStringArray = key.split(".")
		var value: String = ""
		if key == "cash":
			value = ("+" if float(v) >= 0.0 else "−") + UiUtil.money(absf(float(v)))
		elif key == "macro":
			value = str(int(v))
		elif v is bool:
			value = ""
		elif percent.has(key):
			value = UiUtil.percent(roundf(100.0 * float(v)), 0, true)
		else:
			value = "%+d" % int(roundf(float(v)))
		if parts[0] == "employee" or parts[0] == "employee2":
			var who: String = str(args.get(parts[0], ""))
			if parts[1] == "stat":
				out.append(TranslationServer.translate("EFF_EMPLOYEE_STAT") % [who,
					TranslationServer.translate("STAT_" + parts[2].to_upper() + "_NAME"), value])
			elif v is bool:
				out.append(TranslationServer.translate("EFF_EMPLOYEE_" + parts[1].to_upper()) % who)
			else:
				out.append(TranslationServer.translate("EFF_EMPLOYEE_" + parts[1].to_upper()) % [who, value])
			continue
		var k: String = "EFF_" + key.replace(".", "_").to_upper()
		out.append(TranslationServer.translate(k) if v is bool else TranslationServer.translate(k) % value)
	return out
