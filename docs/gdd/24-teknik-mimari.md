# 24 Teknik mimari

## 24.1 Temel ilke: Simülasyon ↔ Sunum ayrımı

```text
┌──────────────────────── SUNUM (Godot sahneleri) ────────────────────────┐
│ 3D ofis, karakterler, UI ekranları, sesler, animasyonlar                │
│ → sadece EventBus sinyallerini dinler ve GameState'i OKUR               │
│ → oyuncu eylemlerini Command olarak simülasyona GÖNDERİR                │
└──────────────────────────────▲─────────────┬────────────────────────────┘
                     sinyaller │             │ komutlar (ör. StartCampaign)
┌──────────────────────────────┴─────────────▼────────────────────────────┐
│ SİMÜLASYON ÇEKİRDEĞİ (saf GDScript sınıfları, Node'a bağımlı değil)     │
│ Clock · Economy · Clients · Campaigns · Scoring · Staff · Suppliers     │
│ Rivals · Awards · Events · Research · Trends                            │
│ → Headless çalışabilir, birim testi yazılabilir, 45 yıl 3 saniyede      │
└──────────────────────────────▲──────────────────────────────────────────┘
                               │ okur
┌──────────────────────────────┴──────────────────────────────────────────┐
│ VERİ (data/*.json) sektörler, kanallar, araçlar, olaylar, denge         │
└─────────────────────────────────────────────────────────────────────────┘
```

Bu ayrım sayesinde: (1) Claude simülasyonu görsellerden bağımsız test edebilir, (2) denge simülasyonları binlerce oyun saniyeler içinde koşar, (3) 3D sahne istediğin kadar değişse simülasyon bozulmaz, (4) kayıt sistemi sadece simülasyon durumunu kaydeder.

## 24.2 Klasör yapısı

```text
ajans-tycoon/
├─ CLAUDE.md                    # Claude Code için kalıcı proje talimatları
├─ project.godot
├─ docs/ GDD.pdf · gdd/*.md · decisions.md · playtest-notes.md · changelog.md
├─ data/
│  ├─ balance.json              # tüm sayısal sabitler
│  ├─ sectors.json · objectives.json · audiences.json · tones.json
│  ├─ fit/ sector_objective.json · sector_audience.json · channel_fit.json · tone_fit.json
│  ├─ channels.json · suppliers.json · tools.json · hardware.json · furniture.json
│  ├─ positions.json · traits.json · names_tr.json · names_en.json
│  ├─ brands/ name_parts.json · handcrafted_brands.json
│  ├─ events/ client.json · staff.json · crisis.json · macro.json · fun.json
│  ├─ research.json · awards.json · rivals.json · achievements.json · eras.json · calendar.json
│  └─ report_lines.json
├─ src/
│  ├─ autoload/ game_state.gd · clock.gd · event_bus.gd · data_db.gd · save_system.gd · settings.gd
│  ├─ sim/      economy.gd · client_system.gd · brief_generator.gd · campaign.gd · scoring.gd
│  │            kpi.gd · staff_system.gd · employee.gd · supplier_system.gd · pitch.gd
│  │            rivals.gd · awards.gd · event_system.gd · research.gd · trends.gd · rng.gd
│  ├─ commands/ start_campaign.gd · hire_employee.gd · ... (oyuncu eylemleri)
│  ├─ ui/       screens/*.tscn+gd · widgets/*.tscn+gd · theme/main_theme.tres
│  └─ world/    office.tscn · room.gd · furniture_item.gd · character.tscn · camera_rig.gd
├─ assets/ models/ · textures/ · icons/ · audio/music · audio/sfx · fonts/
├─ localization/ strings.csv    # key, tr, en
├─ tests/ (GUT test eklentisi) test_scoring.gd · test_economy.gd · ...
├─ tools/ balance_sim.gd (headless) · validate_data.gd
└─ art/   style_bible.md · asset_log.csv · prompts/
```

> M0 uygulama notu: proje kökü `AD_TYCOON/` klasörüdür; M0'da eklenen ek veri dosyaları (`tone_groups.json`, `focus_areas.json`, `combo_rules.json`) ve `tools/data_validator.gd` için bkz. `docs/decisions.md`.

## 24.3 Autoload (singleton) görevleri

| Autoload | Görev |
|---|---|
| DataDB | Açılışta tüm JSON'ları yükler, doğrular (eksik alan, yanlış id → anlaşılır hata), salt-okunur sözlükler sağlar. |
| GameState | Tüm simülasyon durumunu tutar (ajans, müşteriler, çalışanlar, kampanyalar, rakipler...). Tek doğruluk kaynağı. |
| Clock | Zaman, hız, duraklatma; gün/hafta/ay/yıl tick sinyalleri yayar. |
| EventBus | Global sinyaller: `campaign_finished(id)`, `cash_changed`, `notification(text, type)` … |
| SaveSystem | GameState → JSON (sürüm numaralı, sıkıştırılmış), otomatik kayıt (her ay), 3 slot + otomatik slot, sürüm göçü (migration). |
| Settings | Dil, ses, çözünürlük, metin boyutu, otomatik duraklatma tercihleri. |

## 24.4 Veri şeması örnekleri

```text
// data/channels.json (bir kayıt)
{ "id": "billboard", "name_key": "CH_BILLBOARD", "category": "ooh",
  "available_from": 1990, "requires_research": null,
  "min_budget": 5000, "base_cpm": 4.0, "base_er": 0.002, "base_cvr": 0.01,
  "audience_size": { "young": 0.8, "adult": 1.0, "mature": 0.8, "b2b": 0.2 },
  "interest_curve": [[1990,0.9],[2005,1.0],[2020,0.8],[2035,0.7]],
  "needs_outputs": ["key_visual","slogan"], "viral": 0,
  "options": { "location_tier": ["A","B","C"], "weeks": [1,2,4] } }

// data/positions.json
{ "id": "art_director", "department": "creative", "name_key": "POS_ART_DIRECTOR",
  "specialty_focus": ["concept","visual"], "primary_stats": ["creative","technical"],
  "available_from": 1990, "base_salary": 3500, "seniority_levels": ["junior","mid","senior"] }

// data/tools.json
{ "id": "pixelshop", "name": "PixelShop", "boosts": { "visual": 0.25, "production": 0.10 },
  "versions": [ {"v":"2.0","year":1991}, {"v":"5.0","year":1998}, {"v":"CS","year":2003},
                {"v":"CC","year":2013,"model":"subscription"} ],
  "price_license": 2000, "price_monthly_seat": 60, "requires_hardware_tier": 1 }

// GameState içindeki bir müşteri (kayıt dosyasında)
{ "id": "cl_0012", "name": "Lezzetçi Köfte", "sector": "fast_food", "scale": 2,
  "annual_budget": 420000, "personality": { "risk": 70, "detail": 30, "pay": 80, "ego": 55, "loyalty": 60 },
  "satisfaction": 72, "trust": 58, "contract": "retainer", "retainer_monthly": 12000,
  "history": [ {"campaign":"cp_0101","score":7.8,"objective":"sales","year":1996} ] }
```

## 24.5 Diğer teknik kararlar

- **Tohumlu rastgelelik (seeded RNG):** Her sistem kendi `RandomNumberGenerator`'ına sahip; aynı tohum = aynı oyun. Hata ayıklama ve denge testleri için şart.
- **Statik tipli GDScript** (`var x: int`) ve sınıf adları (`class_name`): Claude'un hata yapma olasılığını düşürür.
- **Yerelleştirme:** Arayüzde hiçbir metin koda gömülmez; `tr("KEY")` ve `localization/strings.csv`. Prosedürel isimler dil başına ayrı listeler.
- **Performans:** 120 çalışan + 3D ofis hedefi. Karakter animasyonları için LOD ve uzak kamerada basitleştirme; çalışan başına mantık günlük tick'te (her karede değil).
- **Kayıt sürümleme:** `"save_version": 3` ve `migrate_v2_to_v3()` fonksiyonları. Erken erişimde kayıtların bozulmaması oyuncu güveni için kritik.
- **Hata kaydı:** `user://logs/` altına günlük; çökme sonrası oyuncunun gönderebileceği rapor.
- **Mod desteği (ileride):** `user://mods/` klasöründeki JSON'lar DataDB tarafından birleştirilir (veri odaklı tasarımın bedava hediyesi). Steam Workshop sonraki adım.
