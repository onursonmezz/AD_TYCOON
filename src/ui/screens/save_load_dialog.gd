class_name SaveLoadDialog
extends Control
## Kaydet / Yükle penceresi (M9): 3 elle kayıt slotu (+ yüklemede otomatik kayıt). Her slotta ajans adı, oyun tarihi,
## nakit, çalışan sayısı ve kayıt zamanı. Dolu slotun üstüne yazmak ikinci tıklamayla onaylanır. Esc ile kapanır.

var _saving: bool
var _on_loaded: Callable
var _list: VBoxContainer
var _confirm_slot: String = ""
var _error: Label


## saving: true = kaydet, false = yükle. on_loaded: yükleme başarılıysa çağrılır (ör. oyun sahnesine geçiş).
func _init(saving: bool, on_loaded: Callable = Callable()) -> void:
	_saving = saving
	_on_loaded = on_loaded
	set_meta("esc_closes", true)


func _ready() -> void:
	var col: VBoxContainer = UiUtil.modal_frame(self, Vector2(620.0, 420.0))
	col.add_child(UiUtil.heading(tr("UI_SAVE_TITLE" if _saving else "UI_LOAD_TITLE")))
	_list = UiUtil.vbox(8)
	col.add_child(_list)
	_error = UiUtil.label("", 14, UiUtil.TERRACOTTA)
	col.add_child(_error)
	var buttons: HBoxContainer = UiUtil.hbox()
	buttons.add_child(UiUtil.spacer())
	buttons.add_child(UiUtil.button(tr("UI_CANCEL"), queue_free))
	col.add_child(buttons)
	_rebuild()


func _rebuild() -> void:
	UiUtil.clear(_list)
	var slots: Array[String] = SaveSystem.SLOTS.duplicate()
	if not _saving:
		slots.append(SaveSystem.AUTO)
	for slot: String in slots:
		_list.add_child(_row(slot))


func _row(slot: String) -> PanelContainer:
	var card: PanelContainer = UiUtil.card()
	var row: HBoxContainer = UiUtil.hbox()
	card.add_child(row)
	var info: VBoxContainer = UiUtil.vbox(2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title: String = tr("UI_SLOT_AUTO") if slot == SaveSystem.AUTO else tr("UI_SLOT") % (SaveSystem.SLOTS.find(slot) + 1)
	if slot == GameState.current_slot and GameState.has_game():
		title += "  ·  " + tr("UI_SLOT_CURRENT")
	info.add_child(UiUtil.label(title, 17, UiUtil.SAGE_DARK))
	var meta: Dictionary = SaveSystem.slot_meta(slot)
	info.add_child(UiUtil.label(summary(meta), 14, UiUtil.TEXT if not meta.is_empty() else UiUtil.MUTED))
	row.add_child(info)
	if _saving:
		var label: String = tr("UI_SLOT_OVERWRITE") if _confirm_slot == slot else tr("UI_SAVE")
		row.add_child(UiUtil.button(label, func() -> void: _save(slot, meta.is_empty())))
	else:
		var b: Button = UiUtil.button(tr("UI_LOAD"), func() -> void: _load(slot))
		b.disabled = meta.is_empty() or bool(meta.get("corrupt", false))
		row.add_child(b)
	return card


## Slot özeti: "Ajans · 2003 Ay 4 · ₺1.2M · 12 çalışan · 04.11.2026 14:30"; boşsa "Boş".
static func summary(meta: Dictionary) -> String:
	if meta.is_empty():
		return TranslationServer.translate("UI_SLOT_EMPTY")
	if bool(meta.get("corrupt", false)):
		return TranslationServer.translate("ERR_SAVE_CORRUPT")
	var data: GameData = DataDB.data
	var wpy: int = data.bali("time.weeks_per_month") * data.bali("calendar.months_per_year")
	var week: int = int(meta["week_index"])
	var year: int = int(meta["start_year"]) + week / wpy
	var month: int = (week % wpy) / data.bali("time.weeks_per_month") + 1
	var agency: String = str(meta.get("agency", ""))
	var parts: PackedStringArray = PackedStringArray([agency if not agency.is_empty() else TranslationServer.translate("UI_DEFAULT_AGENCY"),
		TranslationServer.translate("UI_SLOT_DATE") % [year, month], UiUtil.money(float(meta["cash"])),
		TranslationServer.translate("UI_SLOT_STAFF") % int(meta["staff"])])
	if float(meta.get("saved_at", 0.0)) > 0.0:
		var t: Dictionary = Time.get_datetime_dict_from_unix_time(int(meta["saved_at"]) + _tz_offset())
		parts.append("%02d.%02d.%d %02d:%02d" % [t["day"], t["month"], t["year"], t["hour"], t["minute"]])
	if bool(meta.get("bankrupt", false)):
		parts.append(TranslationServer.translate("UI_SLOT_BANKRUPT"))
	return " · ".join(parts)


static func _tz_offset() -> int:
	return int(Time.get_time_zone_from_system().get("bias", 0)) * 60


func _save(slot: String, empty: bool) -> void:
	if not empty and _confirm_slot != slot and slot != GameState.current_slot:
		_confirm_slot = slot
		_rebuild()
		return
	if GameState.save_game(slot):
		queue_free()
	else:
		_error.text = tr("NOTE_SAVE_FAILED")


func _load(slot: String) -> void:
	if GameState.load_game(slot):
		if _on_loaded.is_valid():
			_on_loaded.call()
		queue_free()
	else:
		_error.text = tr("ERR_SAVE_CORRUPT")
