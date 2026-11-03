class_name SimState
extends RefCounted
## Simülasyonun tüm durumu (tek doğruluk kaynağı). Sözlük/dizi tutulur ki kayıt sistemi kolayca JSON'a çevirsin.
## GameState autoload'u bu nesneyi (Simulation üzerinden) sarar.

var rng: SimRng
var clock: SimClock

var cash: float = 0.0
var reputation: float = 0.0
var office_level: int = 1
var bankrupt: bool = false
var red_weeks: int = 0
## Faz başında oyuncunun slider girmesi bekleniyor (oyun durur).
var waiting_for_input: bool = false

## id → çalışan sözlüğü (GDD 11.2; kurucu da bir çalışandır, is_founder = true). Alanlar: Employee sınıfına bakın.
var staff: Dictionary = {}
## Son işe alım aramasının adayları.
var candidates: Array[Dictionary] = []
## Rakip transfer teklifleri: { "id", "employee_id", "offer_salary", "expires_week" }
var offers: Array[Dictionary] = []
## Fazla mesai (crunch) açık mı (GDD 11.4).
var overtime: bool = false

## Tedarikçiler (GDD 10.3): ilişki puanları, gelen teklifler, aktif anlaşmalar, yıllık baskı hacmi, açık pazarlık.
var supplier_rel: Dictionary = {}
var supplier_offers: Array[Dictionary] = []
var supplier_deals: Array[Dictionary] = []
var print_volume_year: Dictionary = {}
var negotiation: Dictionary = {}
## Bu yıl satın alınan medya (hacim indirimi, GDD 10.4).
var year_media: float = 0.0

## Influencer havuzu (GDD 9.6), havuzun kurulduğu hafta, birlikte çalışma sayıları, karar bekleyen skandallar.
var influencers: Array[Dictionary] = []
var influencer_pool_week: int = -1
var influencer_history: Dictionary = {}
var scandals: Array[Dictionary] = []

## id → müşteri sözlüğü (GDD 24.4 şeması).
var clients: Dictionary = {}
## Gelen kutusundaki brief'ler.
var inbox: Array[Dictionary] = []
## Üretimdeki kampanya (boşsa {}).
var active_campaign: Dictionary = {}
## Teslim edilmiş, yayında olan kampanyalar.
var airing: Array[Dictionary] = []
## Biten kampanyaların özetleri (tekrar cezası için), en yenisi sonda.
var history: Array[Dictionary] = []
## Raporu ekranda gösterilebilecek son biten kampanyalar (tam kayıt).
var finished: Array[Dictionary] = []
## Tahsil edilecek faturalar: { "client_id", "amount", "income", "due_week" }
var receivables: Array[Dictionary] = []
## Tedarikçiye ödenecek tutarlar (medya): { "amount", "due_week" }
var payables: Array[Dictionary] = []
## Büyüklük → en iyi ham puan (GDD 7.9 rekor).
var best_raw: Dictionary = {}

## Rakip ajanslar (GDD 14.3): id → { reputation, staff, alive, award_points, closed_year }.
var rivals: Dictionary = {}
## Ödüller (GDD 15): bekleyen başvurular, geçmiş sonuçlar, bu yılın ödül puanı, yeni müşteri çekimi.
var award_entries: Array[Dictionary] = []
var award_history: Array[Dictionary] = []
var award_points_year: float = 0.0
var award_buzz: float = 0.0
## Son yıl sonu sıralaması ve yıllara göre oyuncunun sırası.
var rankings: Dictionary = {}
var ranking_history: Array[Dictionary] = []
var last_year_income: float = 0.0
## Pitch (GDD 14.2): bekleyen davetler, yürüyen pitch, kısa listede kaldığımız "sıcak" markalar, sonuçlar.
var pitch_invites: Array[Dictionary] = []
var pitch: Dictionary = {}
var warm_clients: Dictionary = {}
var pitch_history: Array[Dictionary] = []
## Ofis düzeni (M6-B): çizilen odalar, mobilyalar, masa kalitesi. room_quality ve office_effects ondan hesaplanır, kaydedilmez.
var build: Dictionary = BuildSystem.empty_build()
var room_quality: float = 50.0
var office_effects: Dictionary = {}
## Araçlar (M7): id → { version, sub }, bilgisayar kuşağı; tool_mults ve ai_penalty onlardan hesaplanır, kaydedilmez.
var tools: Dictionary = {}
var hardware: String = "pc386"
var tool_mults: Dictionary = {}
var ai_penalty: float = 0.0

## Yıllık gelir/gider (vergi için).
var year_income: float = 0.0
var year_expense: float = 0.0

var _next_id: Dictionary = {}

## Kayda giren alanlar (rng ve clock ayrıca yazılır).
const SAVED_FIELDS: Array[String] = ["cash", "reputation", "office_level", "bankrupt", "red_weeks", "waiting_for_input",
	"staff", "candidates", "offers", "overtime", "supplier_rel", "supplier_offers", "supplier_deals", "print_volume_year",
	"negotiation", "year_media", "influencers", "influencer_pool_week", "influencer_history", "scandals", "clients", "inbox", "active_campaign", "airing", "history", "finished",
	"receivables", "payables", "best_raw", "year_income", "year_expense", "_next_id",
	"rivals", "award_entries", "award_history", "award_points_year", "award_buzz", "rankings", "ranking_history", "last_year_income",
	"pitch_invites", "pitch", "warm_clients", "pitch_history", "build", "tools", "hardware"]


func _init(data: GameData, seed_value: int) -> void:
	rng = SimRng.new(seed_value)
	clock = SimClock.new(data)
	cash = data.balf("start.cash")
	reputation = data.balf("start.reputation")
	office_level = data.bali("start.office_level")


func founder() -> Dictionary:
	for emp: Dictionary in staff.values():
		if bool(emp.get("is_founder", false)):
			return emp
	return {}


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


func to_dict() -> Dictionary:
	var out: Dictionary = {"rng": rng.to_dict(), "clock": clock.to_dict()}
	for field: String in SAVED_FIELDS:
		var value: Variant = get(field)
		out[field] = value.duplicate(true) if (value is Dictionary or value is Array) else value
	return out


static func from_dict(data: GameData, saved: Dictionary) -> SimState:
	var s: SimState = SimState.new(data, 0)
	s.rng = SimRng.from_dict(saved.get("rng", {}))
	s.clock.load_dict(saved.get("clock", {}))
	s.cash = float(saved.get("cash", s.cash))
	s.reputation = float(saved.get("reputation", s.reputation))
	s.office_level = int(saved.get("office_level", s.office_level))
	s.bankrupt = bool(saved.get("bankrupt", false))
	s.red_weeks = int(saved.get("red_weeks", 0))
	s.waiting_for_input = bool(saved.get("waiting_for_input", false))
	s.staff = saved.get("staff", {})
	s.candidates.assign(saved.get("candidates", []))
	s.offers.assign(saved.get("offers", []))
	s.overtime = bool(saved.get("overtime", false))
	s.supplier_rel = saved.get("supplier_rel", {})
	s.supplier_offers.assign(saved.get("supplier_offers", []))
	s.supplier_deals.assign(saved.get("supplier_deals", []))
	s.print_volume_year = saved.get("print_volume_year", {})
	s.negotiation = saved.get("negotiation", {})
	s.year_media = float(saved.get("year_media", 0.0))
	s.influencers.assign(saved.get("influencers", []))
	s.influencer_pool_week = int(saved.get("influencer_pool_week", -1))
	s.influencer_history = saved.get("influencer_history", {})
	s.scandals.assign(saved.get("scandals", []))
	s.clients = saved.get("clients", {})
	s.inbox.assign(saved.get("inbox", []))
	s.active_campaign = saved.get("active_campaign", {})
	s.airing.assign(saved.get("airing", []))
	s.history.assign(saved.get("history", []))
	s.finished.assign(saved.get("finished", []))
	s.receivables.assign(saved.get("receivables", []))
	s.payables.assign(saved.get("payables", []))
	s.best_raw = saved.get("best_raw", {})
	s.year_income = float(saved.get("year_income", 0.0))
	s.year_expense = float(saved.get("year_expense", 0.0))
	s._next_id = saved.get("_next_id", {})
	s.rivals = saved.get("rivals", {})
	s.award_entries.assign(saved.get("award_entries", []))
	s.award_history.assign(saved.get("award_history", []))
	s.award_points_year = float(saved.get("award_points_year", 0.0))
	s.award_buzz = float(saved.get("award_buzz", 0.0))
	s.rankings = saved.get("rankings", {})
	s.ranking_history.assign(saved.get("ranking_history", []))
	s.last_year_income = float(saved.get("last_year_income", 0.0))
	s.pitch_invites.assign(saved.get("pitch_invites", []))
	s.pitch = saved.get("pitch", {})
	s.warm_clients = saved.get("warm_clients", {})
	s.pitch_history.assign(saved.get("pitch_history", []))
	s.build = saved.get("build", BuildSystem.empty_build())
	s.tools = saved.get("tools", {})
	s.hardware = str(saved.get("hardware", "pc386"))
	return s
