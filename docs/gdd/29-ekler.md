# 29 Ekler

## 29.1 Başlangıç balance.json taslağı

> `data/balance.json` bu taslaktan birebir oluşturuldu; Bölüm 7.6'da geçen `deep_mode: false` eklendi (bkz. `docs/decisions.md`).

```json
{
    "time": { "start_year": 1990, "end_year": 2035, "weeks_per_month": 4, "seconds_per_week_1x": 3.0 },
    "start": { "cash": 60000, "reputation": 5, "office_level": 1 },
    "fit_multiplier": { "-3": 0.45, "-2": 0.62, "-1": 0.82, "0": 1.0, "1": 1.06, "2": 1.14, "3": 1.25 },
    "fit_row_rules": { "six_col": "1x+3, 1x+2, 1x+1, 1x0, 1x-1, 1x(-2|-3)", "four_col": "1x+3, 1x(+1|+2), 1x(0|-1), 1x(-2|-3)" },
    "combo_weights": { "sector_objective": 0.35, "sector_audience": 0.25, "channel": 0.30, "tone": 0.10 },
    "focus": { "min_mult": 0.80, "max_mult": 1.20, "slider_soft_cap": 0.60 },
    "importance_values": { "3": 1.0, "2": 0.7, "1": 0.45, "0": 0.3, "-1": 0.15, "-2": 0.05, "-3": 0.0 },
    "balance_sk": { "penalty_per_log": 0.25, "max_penalty": 0.30 },
    "novelty": { "same_pair_recent3": 0.88, "same_triplet_last": 0.75, "same_client_12w": 0.85,
                 "pioneer_bonus": 1.10, "ai_fatigue_from_2026": 0.95 },
    "score": { "era_base": 120, "era_growth": 1.085, "beat_best_factor": 1.05,
               "exponent": 0.8, "offset": -1.5, "noise": 0.4, "best_update_lerp": 0.6 },
    "size_multiplier": { "small": 1.0, "medium": 2.6, "large": 6.0, "mega": 14.0 },
    "media_commission": { "default": 0.15, "min": 0.08, "max": 0.17 },
    "print": { "scale_exponent": -0.18, "proof_error_mult": 0.3,
               "quality_mult": { "economy": 0.7, "standard": 1.0, "premium": 1.6 } },
    "staff": { "overtime_output": 1.35, "overtime_energy_mult": 2.0, "burnout_per_overtime_week": 6,
               "specialty_bonus": 1.3, "offspec_penalty": 0.6, "base_error_rate": 0.06 },
    "economy": { "inflation_mode": "simple", "simple_rate": 0.08, "payroll_tax": 0.205, "corporate_tax": 0.25 },
    "reputation": { "decay_above_50": 0.03 }
}
```

**Para birimi ve enflasyon:** "simple" mod sabit oran (öngörülebilir); "historical" mod Türkiye benzeri dalgalı oranlar + 2005 para reformu olayı. Ayarlar ekranında oyuncu seçebilir.

## 29.2 Reklamcılık sözlüğü (oyunda ipucu metinleri için)

| Terim | Anlamı |
|---|---|
| Brief | Müşterinin ajansa verdiği iş tanımı: hedef, kitle, bütçe, süre. |
| Insight (İçgörü) | Tüketiciye dair, kampanyanın üzerine kurulduğu gizli gerçek. |
| Key Visual | Kampanyanın ana görseli; tüm mecralara uyarlanır. |
| Copy / Copywriter | Reklam metni / metin yazarı. |
| Art Director | Görsel yönetmen; copywriter ile ikili çalışır. |
| Account | Müşteri ilişkileri ekibi. |
| Retainer | Aylık sabit ücretli uzun dönem anlaşma. |
| Pitch | Yeni müşteri kazanmak için ajanslar arası sunum yarışması. |
| OOH | Out-of-Home, açık hava reklamı. |
| CPM / CPC / CPA | Bin gösterim / tıklama / dönüşüm başı maliyet. |
| CTR / ER / CVR | Tıklama oranı / etkileşim oranı / dönüşüm oranı. |
| Erişim / Frekans | Reklamı gören tekil kişi / kişi başı görülme sayısı. |
| 360° kampanya | Birden çok mecrada entegre kampanya. |
| Gerilla pazarlama | Düşük bütçeli, sürpriz, alışılmadık sokak uygulamaları. |
| Prova (Proof) | Baskı öncesi kontrol çıktısı. |
| Trafik | Ajans içinde işlerin akışını ve teslim tarihlerini yöneten birim. |
| Showreel | Ajansın en iyi işlerini gösteren tanıtım videosu. |

## 29.3 Kontrol listeleri

**Her Claude Code oturumunda**

- [ ] İlgili GDD bölümünü okuttum
- [ ] Tek sistem / net kabul kriteri verdim
- [ ] Testler ve veri doğrulama geçti
- [ ] Oyunu açıp elle denedim
- [ ] Commit yapıldı
- [ ] Karar/değişiklik decisions.md'de

**Demo öncesi**

- [ ] Tutorial baştan sona sorunsuz
- [ ] 1990–1998 bir oturumda bitiyor
- [ ] Kayıt/yükleme güvenilir
- [ ] TR/EN tüm metinler çevrili
- [ ] 5+ dış playtest yapıldı
- [ ] Steam sayfası + fragman hazır
- [ ] AI içerik beyanı ve lisans kayıtları tam

> **Son söz:** Bu dokümanın tamamı "tam oyun" vizyonudur; ama oyunu güzel yapacak olan, M2'de menülerden oluşan ilk prototipte o "bir kampanya daha" hissini yakalamaktır. Oradan sonrası, Claude ile katman katman eklemek. Kolay gelsin, ajansın bol ödüllü olsun!
