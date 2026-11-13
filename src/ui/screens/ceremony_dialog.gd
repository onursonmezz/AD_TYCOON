class_name CeremonyDialog
extends Control
## Ödül töreni (GDD 15 "duygusal bir an"; UI-3 taslağı 21): her başvuru bir sahne kartında (kampanya, müşteri, büyük
## kupa ve derece); altında rakipler ve Grand Prix yan yana. Sonuçlar teker teker açılır, Grand Prix en sonda.
## Taslaktaki perde ve elma çizimi yerine şimdilik büyük kupa ikonu var (çizim dosyası gelince değişir).

const REVEAL_SECONDS: float = 0.8
const CUP_SIZE: float = 110.0
const CURTAIN_SIZE: float = 96.0
const LEVEL_COLORS: Dictionary = {"gold": Color("#D9A441"), "grand_prix": Color("#D9A441"), "silver": Color("#A9B0B3"),
	"bronze": Color("#B9793F"), "shortlist": Color("#8DAA8E")}

var _result: Dictionary
var _stage: VBoxContainer
var _footer: HBoxContainer


func _init(result: Dictionary) -> void:
	_result = result


func _ready() -> void:
	var data: GameData = DataDB.data
	var col: VBoxContainer = UiUtil.modal_frame(self, UiUtil.dialog_size("ceremony"), true, true)
	col.add_child(UiUtil.heading("%s · %d" % [UiUtil.name_of(data.awards, _result["award"]), int(_result["year"])], "trophy"))
	_stage = UiUtil.vbox(CozyTheme.SPACE_S)
	col.add_child(_stage)
	col.add_child(HSeparator.new())
	_footer = UiUtil.hbox(CozyTheme.SPACE_M)
	col.add_child(_footer)
	var buttons: HBoxContainer = UiUtil.hbox()
	buttons.add_child(UiUtil.spacer())
	var close: Button = UiUtil.button(tr("MENU_CONTINUE"), queue_free)
	close.theme_type_variation = "PrimaryButton"
	close.custom_minimum_size.x = 130.0
	buttons.add_child(close)
	col.add_child(buttons)
	_reveal()


func _reveal() -> void:
	var data: GameData = DataDB.data
	for r: Dictionary in _result["player"]:
		if not await _pause():
			return
		_stage.add_child(_entry_card(r))
	if not await _pause():
		return
	var rivals: HBoxContainer = Cards.header(Cards.tile("building", 44.0, CozyTheme.TERRA_SOFT), tr("UI_RIVALS"),
		tr("UI_CEREMONY_RIVALS_SHORT") % (_result["rivals"] as Array).size())
	rivals.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_footer.add_child(rivals)
	if not await _pause():
		return
	var gp: Dictionary = _result["grand_prix"]
	var who: String = tr("UI_CEREMONY_GP_NONE")
	if gp["who"] == "player":
		who = tr("UI_CEREMONY_GP_US")
	elif not str(gp["who"]).is_empty():
		who = UiUtil.name_of(data.rivals, gp["who"])
	_footer.add_child(VSeparator.new())
	var prize: HBoxContainer = Cards.header(Cards.tile("trophy", 44.0, CozyTheme.ACCENT_SOFT), tr("LEVEL_GRAND_PRIX"), who)
	prize.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_footer.add_child(prize)


## Sıradaki satırdan önce kısa bekleme; pencere kapandıysa false.
func _pause() -> bool:
	await get_tree().create_timer(REVEAL_SECONDS).timeout
	return is_inside_tree()


## Bir başvurunun sahnesi: kampanya adı, müşteri, derece renginde büyük kupa ve derece şeridi.
func _entry_card(r: Dictionary) -> PanelContainer:
	var level: String = str(r["level"])
	var color: Color = LEVEL_COLORS.get(level, CozyTheme.MUTED)
	var card: PanelContainer = UiUtil.card()
	var v: VBoxContainer = UiUtil.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var stage: HBoxContainer = UiUtil.hbox(0)
	card.add_child(stage)
	stage.add_child(_curtain("perde-sol"))
	stage.add_child(v)
	stage.add_child(_curtain("perde-sag"))
	var title: Label = UiUtil.label(str(r.get("name", "")) if not str(r.get("name", "")).is_empty() else tr("UI_UNTITLED"), 20,
		CozyTheme.FOREST)
	title.add_theme_font_override("font", CozyTheme.title_font(700))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var client: Label = UiUtil.label(str(r.get("client_name", "")), 14, CozyTheme.TERRA)
	client.add_theme_font_override("font", MenuArt.italic(CozyTheme.body_font()))
	client.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(client)
	# Kupa: altın ve gümüş için çizim (data/ui_layout.json trophy_art); diğer derecelerde derece renginde ikon.
	var cup: Control = Cards.art("trophy_art", level, CUP_SIZE, "trophy", Color.TRANSPARENT)
	if cup is PanelContainer:
		cup = UiUtil.icon("trophy", 72, color)
	cup.custom_minimum_size = Vector2(CUP_SIZE, CUP_SIZE)
	cup.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(cup)
	var ribbon: HBoxContainer = UiUtil.hbox()
	ribbon.alignment = BoxContainer.ALIGNMENT_CENTER
	var band: PanelContainer = PanelContainer.new()
	band.add_theme_stylebox_override("panel", CozyTheme.box(Color(color, 0.25), 6, color, 1, false, Vector2(CozyTheme.SPACE_XL, 2)))
	var text: Label = UiUtil.label(tr("LEVEL_" + level.to_upper()) if not level.is_empty() else tr("LEVEL_NONE"), 22,
		CozyTheme.FOREST if not level.is_empty() else CozyTheme.MUTED)
	text.add_theme_font_override("font", CozyTheme.title_font(800))
	band.add_child(text)
	ribbon.add_child(band)
	v.add_child(ribbon)
	UiUtil.pop_in(card)
	return card


## Sahnenin yanındaki perde çizimi (dosya yoksa boş yer).
func _curtain(file: String) -> TextureRect:
	var r: TextureRect = TextureRect.new()
	r.texture = IconPack.art(file, int(CURTAIN_SIZE))
	r.custom_minimum_size = Vector2(CURTAIN_SIZE, CURTAIN_SIZE)
	r.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	r.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r
