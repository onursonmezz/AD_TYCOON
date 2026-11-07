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
	_col = UiUtil.modal_frame(self, Vector2(620.0, 360.0))
	_col.add_child(UiUtil.label(tr("UI_EVENT_CAT_" + str(_inst["category"]).to_upper()), 14, UiUtil.MUTED))
	_col.add_child(UiUtil.heading(_text("T"), "alert-triangle" if _inst["category"] == "crisis" else "bell"))
	_col.add_child(UiUtil.wrapped(_text("X"), 16, UiUtil.TEXT, 560.0))
	_buttons = UiUtil.vbox(6)
	for i: Variant in _inst["options"]:
		var opt: Dictionary = ev["options"][int(i)]
		var label: String = _text("O%d" % (int(i) + 1))
		if opt.has("requires_research"):
			label = "★ %s  [%s]" % [label, tr("UI_EVENT_RESEARCH_TAG")]
		if opt.has("check"):
			var check: Dictionary = opt["check"]
			label += "  (%s)" % (tr("UI_EVENT_CHECK") % [tr("STAT_" + str(check["stat"]).to_upper() + "_NAME"),
				int(roundf(100.0 * sim.events.check_chance(sim.state, _inst, check)))])
		var idx: int = int(i)
		var b: Button = UiUtil.button(label, func() -> void: _choose(idx))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
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
		args[role] = GameState.employee_name(emp) if not emp.is_empty() else "?"
	return args


func _choose(option: int) -> void:
	var r: Dictionary = GameState.execute(ResolveEventCommand.new(_inst["uid"], option))
	UiUtil.clear(_buttons)
	if not bool(r.get("ok", false)):
		queue_free()
		return
	if bool(r["checked"]):
		_buttons.add_child(UiUtil.label(tr("UI_EVENT_SUCCESS" if bool(r["success"]) else "UI_EVENT_FAIL"), 18,
			UiUtil.SAGE_DARK if bool(r["success"]) else UiUtil.TERRACOTTA))
	var lines: PackedStringArray = effect_lines(r["effects"], _args())
	if lines.is_empty():
		lines.append(tr("UI_EVENT_NOTHING"))
	for line: String in lines:
		_buttons.add_child(UiUtil.label("• " + line, 15, UiUtil.TEXT))
	var row: HBoxContainer = UiUtil.hbox()
	row.add_child(UiUtil.spacer())
	row.add_child(UiUtil.button(tr("UI_CLOSE"), queue_free))
	_buttons.add_child(row)


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
