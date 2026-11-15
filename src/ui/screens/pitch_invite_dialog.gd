class_name PitchInviteDialog
extends Control
## İhaleye katılım (GDD 14.2): pitch ekibi ve ücret teklifi. Ekip hazırlık bitene kadar kampanyada çalışmaz.
## UI-3 dili: marka kartı, hazırlık/rakip/ücret şeridi, ekip kartları (portre, iletişim), ücret sekme şeridi.

var _invite: Dictionary
var _team_checks: Dictionary = {}
var _fee_ratio: float = 1.0
var _fee_box: HBoxContainer
var _error: Label


func _init(invite: Dictionary) -> void:
	_invite = invite


## Davet özeti (gelen kutusu kartında da kullanılır): rakipler, hazırlık süresi, katılım ücreti.
static func summary(inv: Dictionary) -> String:
	var names: Array[String] = []
	for rid: Variant in inv["rivals"]:
		names.append(UiUtil.name_of(DataDB.data.rivals, str(rid)))
	var text: String = UiUtil.tr_fmt("UI_PITCH_SUMMARY", [int(inv["prep_weeks"]), ", ".join(names)])
	if float(inv["participation_fee"]) > 0.0:
		text += " " + UiUtil.tr_fmt("UI_PITCH_PAID", [UiUtil.money(float(inv["participation_fee"]))])
	return text


func _ready() -> void:
	var data: GameData = DataDB.data
	var s: SimState = GameState.sim.state
	var client: Dictionary = _invite["client"]
	var col: VBoxContainer = UiUtil.modal_frame(self, UiUtil.dialog_size("pitch_invite"))
	col.add_child(UiUtil.heading(tr("UI_PITCH_INVITE_TITLE") % client["name"], "inbox"))
	col.add_child(Cards.header(Cards.art("brand_art", str(client["name"]), 52.0, "building"), str(client["name"]),
		"%s · %s" % [UiUtil.name_of(data.sectors, client["sector"]), tr("SCALE_%d" % int(client["scale"]))]))
	var rivals: Array[String] = []
	for rid: Variant in _invite["rivals"]:
		rivals.append(UiUtil.name_of(data.rivals, str(rid)))
	var fee: float = float(_invite["participation_fee"])
	col.add_child(Cards.facts([
		Cards.fact("calendar", tr("UI_PITCH_PREP_SHORT"), tr("UI_WEEKS") % int(_invite["prep_weeks"])),
		Cards.fact("users-group", tr("UI_PITCH_RIVALS"), str(rivals.size())),
		Cards.fact("coins", tr("UI_PITCH_PAID_SHORT"), UiUtil.money(fee) if fee > 0.0 else "—")]))
	col.add_child(UiUtil.wrapped(", ".join(rivals), 13, CozyTheme.WOOD))
	col.add_child(UiUtil.wrapped(tr("UI_PITCH_HOW"), 13, CozyTheme.MUTED))
	col.add_child(Cards.section(tr("UI_PITCH_TEAM"), "", "users-group"))
	var busy: Array = s.active_campaign.get("setup", {}).get("team", [])
	var team_box: VBoxContainer = UiUtil.vbox(6)
	for emp: Dictionary in s.staff.values():
		var card: PanelContainer = UiUtil.card()
		var check: CheckBox = CheckBox.new()
		check.disabled = not Employee.is_available(emp, s.clock.week_index)
		check.button_pressed = not check.disabled and not busy.has(emp["id"])
		check.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var tags: Array = [Cards.chip(tr("UI_PITCH_COMM") % int(emp["stats"]["communication"]))]
		if busy.has(emp["id"]):
			tags.append(Cards.warn_chip(tr("UI_PITCH_BUSY"), tr("UI_PITCH_ON_CAMPAIGN")))
		var row: HBoxContainer = Cards.header(Cards.avatar(emp, 34.0), GameState.employee_name(emp),
			tr(Employee.title_key(data, emp)), tags)
		row.add_child(check)
		card.add_child(row)
		_team_checks[emp["id"]] = check
		team_box.add_child(card)
	col.add_child(team_box)
	col.add_child(Cards.section(tr("UI_PITCH_FEE"), "", "coins"))
	_fee_box = UiUtil.hbox()
	col.add_child(_fee_box)
	col.add_child(UiUtil.wrapped(tr("UI_PITCH_FEE_HINT"), 13, CozyTheme.MUTED))
	_set_fee(1.0)
	var frame: VBoxContainer = UiUtil.modal_outer(col)
	frame.add_child(HSeparator.new())
	var foot: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_S)
	_error = UiUtil.label("", 13, CozyTheme.NEGATIVE)
	_error.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	foot.add_child(_error)
	foot.add_child(UiUtil.button(tr("UI_CANCEL"), queue_free))
	var start: Button = UiUtil.button(tr("UI_PITCH_START"), _on_start)
	start.theme_type_variation = "PrimaryButton"
	foot.add_child(start)
	frame.add_child(foot)


## Ücret seçimi taslaklardaki sekme şeridi gibi; seçilen yeşil.
func _set_fee(ratio: float) -> void:
	_fee_ratio = ratio
	var tabs: Array = []
	for r: Variant in DataDB.data.bal("pitch.fee_options"):
		var pct: int = int(roundf(float(r) * 100.0))
		tabs.append([str(pct), "UI_PITCH_FEE_%d" % pct])
	UiUtil.clear(_fee_box)
	var seg: PanelContainer = UiUtil.segmented(tabs, str(int(roundf(ratio * 100.0))), func(id: String) -> void:
		_set_fee(float(id) / 100.0))
	seg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fee_box.add_child(seg)


func _on_start() -> void:
	var team: Array = []
	for id: Variant in _team_checks:
		if (_team_checks[id] as CheckBox).button_pressed:
			team.append(id)
	var err: String = GameState.execute(AcceptPitchCommand.new(_invite["id"], team, _fee_ratio))
	if err.is_empty():
		EventBus.notification.emit("NOTE_PITCH_STARTED", [_invite["client"]["name"], int(_invite["prep_weeks"])], "info")
		queue_free()
	else:
		_error.text = tr(err)
