class_name MinigameDialog
extends Control
## "… provası" penceresi (K-120): başlıkta oyunun adı ve ikonu, altında "Müşteri | Kanal" satırı ve tek cümlelik görev,
## ortada oyun, altta süre ve Atla (MinigameHost). Faz başında ana ekran kendiliğinden açar (maybe_open);
## bitince pencere kapanır ve kampanya penceresinde emek dağılımı panosu görünür. Boyut ui_layout.json dialogs.minigame.

const ICONS: Dictionary = {"radio_wave": "volume", "billboard": "speakerphone", "newspaper": "receipt",
	"film": "device-desktop", "feed": "inbox", "sponsor": "trophy", "ribbon": "star", "audience": "users-group",
	"map": "world", "draft": "folder-open"}

var _camp: Dictionary
var _phase: int
var _on_done: Callable


func _init(camp: Dictionary, phase: int, on_done: Callable = Callable()) -> void:
	_camp = camp
	_phase = phase
	_on_done = on_done


## Faz başında bekleyen mini oyun varsa (ve ayarlardan açıksa, başka pencere yoksa) pencereyi açar.
static func maybe_open(screen: Node, modal_layer: Node) -> void:
	if not GameState.has_game() or not GameState.is_waiting() or GameState.is_pitch_waiting():
		return
	if not GameState.pending_event().is_empty():
		return
	var planned: Dictionary = GameState.sim.state.active_campaign
	if not bool(Settings.get_value("minigames")):
		# Mini oyunlar sonradan kapatıldıysa planlı kampanya faz başında takılı kalmasın (S3A).
		if not planned.is_empty() and (planned.get("confirmed_phases", []) as Array).has(GameState.sim.production.current_phase(planned)):
			GameState.execute(MinigameResultCommand.new(GameState.sim.production.current_phase(planned), 0.0, {}, true))
		return
	if modal_layer.get_child_count() > 0:
		return
	var camp: Dictionary = GameState.sim.state.active_campaign
	if camp.is_empty():
		return
	var phase: int = GameState.sim.production.current_phase(camp)
	if not Minigames.pending(camp, phase):
		return
	# S11: planlı kampanyada mini oyundan sonra ofis görünür (çalışanlar izlenir); eski yolda kampanya penceresi.
	var planned_camp: bool = bool(camp["setup"].get("polish", false))
	screen.call("open_modal", MinigameDialog.new(camp, phase, func() -> void:
		if planned_camp:
			screen.call("close_panel")
		else:
			screen.call("show_panel", "campaign")))


func _ready() -> void:
	var data: GameData = DataDB.data
	var setup: Dictionary = _camp["setup"]
	var id: String = Minigames.game_for(data, setup, _phase)
	var key: String = "MG_%s" % id.to_upper()
	var col: VBoxContainer = UiUtil.modal_frame(self, UiUtil.dialog_size("minigame"), true, true)
	col.add_child(UiUtil.heading(tr(key + "_TITLE"), str(ICONS.get(id, "player-play"))))
	var sub: HBoxContainer = UiUtil.hbox(CozyTheme.SPACE_M)
	var client: Label = UiUtil.label(str(setup.get("client_name", "")), 16, CozyTheme.FOREST)
	client.add_theme_font_override("font", CozyTheme.title_font(700))
	sub.add_child(client)
	sub.add_child(VSeparator.new())
	sub.add_child(UiUtil.label(UiUtil.name_of(data.channels, Scoring.main_channel(setup["mix"])), 14, CozyTheme.TEXT))
	col.add_child(sub)
	col.add_child(HSeparator.new())
	col.add_child(UiUtil.wrapped(tr(key + "_HINT"), 14, CozyTheme.TEXT, 600.0))
	col.add_child(MinigameHost.new(_camp, _phase, func() -> void:
		queue_free()
		if _on_done.is_valid():
			_on_done.call()))
