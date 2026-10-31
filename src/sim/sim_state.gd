class_name SimState
extends RefCounted
## Simülasyonun tüm durumu (tek doğruluk kaynağı). Sözlük/dizi tutulur ki kayıt sistemi (M2) kolayca JSON'a çevirsin.
## M2'de GameState autoload'u bu nesneyi saracak.

var rng: SimRng
var clock: SimClock

var cash: float = 0.0
var reputation: float = 0.0
var office_level: int = 1
var bankrupt: bool = false
var red_weeks: int = 0

## Oyuncu karakteri (M1'de tek "çalışan").
var player: Dictionary = {}

## id → müşteri sözlüğü (GDD 24.4 şeması).
var clients: Dictionary = {}
## Gelen kutusundaki brief'ler.
var inbox: Array[Dictionary] = []
## Üretimdeki kampanya (boşsa {}).
var active_campaign: Dictionary = {}
## Teslim edilmiş, yayında olan kampanyalar.
var airing: Array[Dictionary] = []
## Biten kampanyalar (rapor dahil), en yenisi sonda.
var history: Array[Dictionary] = []
## Tahsil edilecek faturalar: { "client_id", "amount", "due_week" }
var receivables: Array[Dictionary] = []
## Tedarikçiye ödenecek tutarlar (medya): { "amount", "due_week" }
var payables: Array[Dictionary] = []
## Büyüklük → en iyi ham puan (GDD 7.9 rekor).
var best_raw: Dictionary = {}

## Yıllık gelir/gider (vergi için) ve aylık özet.
var year_income: float = 0.0
var year_expense: float = 0.0

var _next_id: Dictionary = {}


func _init(data: GameData, seed_value: int) -> void:
	rng = SimRng.new(seed_value)
	clock = SimClock.new(data)
	cash = data.balf("start.cash")
	reputation = data.balf("start.reputation")
	office_level = data.bali("start.office_level")
	player = (data.bal("player") as Dictionary).duplicate(true)


func next_id(prefix: String) -> String:
	var n: int = int(_next_id.get(prefix, 0)) + 1
	_next_id[prefix] = n
	return "%s_%04d" % [prefix, n]


func is_idle() -> bool:
	return active_campaign.is_empty()


func find_brief(brief_id: String) -> Dictionary:
	for b: Dictionary in inbox:
		if b["id"] == brief_id:
			return b
	return {}
