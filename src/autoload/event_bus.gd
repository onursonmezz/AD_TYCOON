extends Node
## Global sinyaller (GDD 24.3). Sunum katmanı yalnızca bunları dinler; simülasyon UI'ı bilmez.

## Bildirim akışı: text_key yerelleştirme anahtarı, args format değerleri, kind: "info" | "good" | "bad".
signal notification(text_key: String, args: Array, kind: String)
signal game_started()
signal state_changed()
signal phase_started(phase: int)
signal campaign_delivered(campaign: Dictionary)
signal campaign_finished(campaign: Dictionary)
signal bankrupt()
signal speed_changed(speed_index: int, paused: bool)
signal offer_received(offer: Dictionary)
signal scandal_started(scandal: Dictionary)
signal award_ceremony(result: Dictionary)
signal pitch_ready()
signal era_started(era_id: String)
