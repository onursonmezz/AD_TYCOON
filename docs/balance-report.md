# Denge raporu (M10-B, Ö1–Ö4 ve puan eğrisi uygulandı)

Üretildi: 2026-11-14 · kısa koşu: 1000 koşu × 10 yıl · uzun koşu: 200 koşu × 30 yıl.
Araçlar: `tools/balance_sim.gd` (botlar), `tools/balance_report.gd` (bu rapor). Hedefler GDD 27.2.

## Hedefler

| Metrik | Hedef | Değer | Durum |
|---|---|---|---|
| Rastgele bot ilk 3 yılda iflas | %20–40 | %22.8 | ✓ |
| Bilgili bot küçük ofise geçiş (medyan yıl) | Y2–Y3 | Y3 (%99 koşuda) | ✓ |
| Bilgili bot plaza katına geçiş (medyan yıl) | Y12–Y16 | Y17 (%85 koşuda) | ✗ |
| Bilgili bot ortalama puan | 7.0–8.5 | 7.12 | ✓ |
| Tekrarcı bot, bilgiliden en az 1.5 düşük | ≥ 1.5 | 2.38 (tekrarcı 4.74) | ✓ |
| Rastgele bot, bilgiliden en az 2.5 düşük | ≥ 2.5 | 2.66 (rastgele 4.46) | ✓ |
| Bilgili bot ilk ödül (medyan yıl) | Y5–Y8 | Y6 (%54 koşuda) | ✓ |
| Rastgele kombinasyonların uyum çarpanı (ortalama) | 0.93–0.97 | 0.936 | ✓ |
| …ve en az %20'si 0.85'in altında | ≥ %20 | %36.4 | ✓ |
| Bir oyun yılı gerçek süre (1x, duraklamasız) | 10–15 dk | 2.4 dk | ✗ |

## Botlar

| Bot | İflas ilk 3 yıl | İflas 10 yıl | Ort. puan | Kampanya/koşu | Ödül/koşu | Kredi/koşu |
|---|---|---|---|---|---|---|
| rastgele | %22.8 | %56.7 | 4.46 | 24.1 | 0.0 | 0.00 |
| bilgili | %1.0 | %5.6 | 7.12 | 51.3 | 0.9 | 0.13 |
| tekrarcı | %0.9 | %15.9 | 4.74 | 45.0 | 0.0 | 0.25 |
| açgözlü | %43.5 | %76.4 | 7.39 | 26.2 | 0.4 | 1.55 |

## Yıllara göre (kısa koşu)

| Yıl | rastgele nakit | puan | ekip | itibar | bilgili nakit | puan | ekip | itibar | tekrarcı nakit | puan | ekip | itibar | açgözlü nakit | puan | ekip | itibar |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Y1 | 118003 | 4.46 | 1.9 | 3.6 | 143164 | 6.06 | 1.7 | 5.5 | 142722 | 4.22 | 1.6 | 3.5 | 138265 | 7.59 | 2.0 | 6.3 |
| Y2 | 223287 | 4.54 | 1.9 | 2.2 | 276082 | 7.55 | 2.2 | 6.4 | 263693 | 4.26 | 2.2 | 1.4 | 239397 | 7.61 | 3.2 | 7.6 |
| Y3 | 307044 | 4.34 | 2.1 | 1.5 | 345704 | 7.93 | 3.2 | 9.8 | 320991 | 5.08 | 2.8 | 1.4 | 301842 | 8.01 | 4.7 | 11.6 |
| Y4 | 372190 | 4.44 | 2.5 | 0.9 | 436395 | 7.64 | 4.6 | 12.9 | 369174 | 5.21 | 3.7 | 1.2 | 480694 | 7.52 | 5.7 | 14.9 |
| Y5 | 365568 | 4.51 | 3.1 | 1.0 | 650209 | 7.25 | 5.4 | 18.2 | 420386 | 5.11 | 4.4 | 2.1 | 805180 | 6.98 | 6.0 | 20.0 |
| Y6 | 445461 | 4.58 | 3.5 | 0.9 | 969569 | 7.02 | 5.8 | 21.2 | 607771 | 4.87 | 4.9 | 1.5 | 1199395 | 6.95 | 6.0 | 23.0 |
| Y7 | 567105 | 4.56 | 3.9 | 0.7 | 1479164 | 6.95 | 5.9 | 23.9 | 810457 | 4.80 | 5.5 | 1.2 | 1793624 | 6.97 | 6.0 | 25.6 |
| Y8 | 754885 | 4.54 | 4.0 | 0.6 | 1941310 | 6.93 | 6.0 | 26.4 | 1055148 | 4.70 | 5.9 | 1.0 | 1842139 | 7.06 | 7.8 | 28.3 |
| Y9 | 1026794 | 4.37 | 4.2 | 0.6 | 2378021 | 6.80 | 6.4 | 29.2 | 1269295 | 4.54 | 6.3 | 0.8 | 2130793 | 7.16 | 9.6 | 32.0 |
| Y10 | 1239599 | 4.24 | 4.2 | 0.6 | 2580601 | 6.74 | 7.9 | 32.5 | 1551648 | 4.46 | 6.6 | 0.9 | 2842000 | 7.08 | 11.1 | 36.8 |

## Yıllara göre (uzun koşu)

| Yıl | bilgili nakit | puan | ekip | itibar | açgözlü nakit | puan | ekip | itibar |
|---|---|---|---|---|---|---|---|---|
| Y1 | 144267 | 6.08 | 1.6 | 5.5 | 146120 | 7.55 | 2.0 | 6.3 |
| Y2 | 277288 | 7.45 | 2.2 | 6.2 | 239022 | 7.60 | 3.3 | 7.3 |
| Y3 | 334348 | 7.91 | 3.4 | 9.4 | 315819 | 8.00 | 4.9 | 11.7 |
| Y4 | 418278 | 7.60 | 4.8 | 12.6 | 523311 | 7.55 | 5.9 | 15.0 |
| Y5 | 709370 | 7.20 | 5.5 | 17.2 | 823067 | 6.96 | 6.0 | 19.7 |
| Y6 | 996394 | 7.00 | 5.9 | 20.3 | 1250552 | 6.71 | 6.0 | 22.7 |
| Y7 | 1523505 | 6.86 | 6.0 | 22.8 | 1858549 | 6.91 | 6.0 | 25.6 |
| Y8 | 1965434 | 6.94 | 6.1 | 25.2 | 1943967 | 7.09 | 7.7 | 29.0 |
| Y9 | 2408707 | 6.87 | 6.4 | 28.0 | 2130793 | 6.86 | 9.8 | 32.6 |
| Y10 | 2578131 | 6.78 | 8.1 | 31.1 | 2900868 | 7.10 | 11.4 | 38.3 |
| Y11 | 3047171 | 7.00 | 10.0 | 35.4 | 5432430 | 6.65 | 11.8 | 42.1 |
| Y12 | 4208151 | 6.72 | 11.1 | 40.3 | 7525713 | 6.62 | 11.9 | 45.6 |
| Y13 | 6205367 | 6.60 | 11.5 | 43.0 | 9489798 | 6.34 | 12.0 | 47.0 |
| Y14 | 9580047 | 6.13 | 11.9 | 45.1 | 8480750 | 5.98 | 14.0 | 47.7 |
| Y15 | 12068415 | 5.63 | 12.2 | 45.6 | 9679690 | 6.16 | 16.2 | 48.7 |
| Y16 | 12021575 | 5.56 | 13.3 | 47.4 | 9779888 | 6.23 | 18.2 | 52.8 |
| Y17 | 11367619 | 5.90 | 16.1 | 48.4 | 14585778 | 5.77 | 20.1 | 56.9 |
| Y18 | 12373684 | 6.37 | 18.1 | 51.0 | 16339593 | 6.42 | 20.7 | 58.7 |
| Y19 | 12629081 | 6.71 | 19.5 | 63.0 | 16355529 | 6.59 | 21.0 | 67.9 |
| Y20 | 13321233 | 6.81 | 20.2 | 72.4 | 20829134 | 6.71 | 21.6 | 74.7 |
| Y21 | 15841130 | 6.65 | 21.9 | 78.2 | 22777077 | 6.77 | 22.3 | 79.8 |
| Y22 | 21622822 | 6.53 | 22.8 | 82.0 | 30284844 | 6.56 | 23.1 | 85.4 |
| Y23 | 26418753 | 6.50 | 23.8 | 84.1 | 32668315 | 5.80 | 22.8 | 89.6 |
| Y24 | 30713799 | 6.08 | 24.2 | 84.8 | 36435596 | 6.38 | 24.2 | 91.9 |
| Y25 | 34956223 | 5.75 | 25.0 | 85.3 | 41441668 | 6.14 | 25.5 | 92.6 |
| Y26 | 40868147 | 5.34 | 25.5 | 85.2 | 31903384 | 5.68 | 24.7 | 93.6 |
| Y27 | 45153003 | 4.80 | 25.9 | 84.6 | 39398870 | 5.14 | 25.2 | 95.1 |
| Y28 | 53491584 | 4.65 | 26.2 | 83.7 | 38008700 | 4.46 | 26.8 | 94.6 |
| Y29 | 57801993 | 4.41 | 26.4 | 81.2 | 45189037 | 4.48 | 28.4 | 90.6 |
| Y30 | 63916416 | 4.08 | 26.6 | 78.0 | 54262129 | 4.24 | 27.8 | 87.5 |

## Uygulanan değişiklikler (K-097) ve önceki raporla karşılaştırma

| Ayar | Önce | Sonra | Neden |
|---|---|---|---|
| `fit_multiplier` −3/−2/−1/+1/+2/+3 | 0.45/0.62/0.82/1.06/1.14/1.25 | 0.30/0.45/0.72/1.10/1.25/1.40 | Ö1: uyum tabloları daha keskin |
| `balance_sk` ceza / üst sınır | 0.25 / 0.30 | 0.5 / 0.5 | Ö1: dengesiz kaydırıcı daha çok acıtır |
| `focus.min_mult` | 0.80 | 0.60 | Ö1: yanlış odağın tabanı |
| `novelty.same_channel_streak` | 1.0 (kapalı) | 0.65 | Ö2: üst üste aynı ana kanal |
| `awards.min_reputation` | 0 | 15 | Ö3: ilk ödül çok erkendi |
| `score.era_growth` | 1.075 | 1.06 | Ö4: geç yıllardaki çöküş |
| `score.exponent` / `score.offset` | 0.8 / −1.5 | 1.0 / −1.2 | Puan eğrisi: iyi ile kötü iş arasındaki fark açılır, ortalama yerinde kalır |
| `scoring.tone_exponent` | 0.5 | 0.75 | Tonun etkisi biraz artar |
| `score.era_base` | 120 | 135 | Dönem beklentisi biraz yüksek: rastgele işler daha düşük puan alır |

| Metrik | Önce | Sonra |
|---|---|---|
| Rastgele farkı (hedef ≥ 2.5) | 1.20 ✗ | 2.66 ✓ |
| Tekrarcı farkı (hedef ≥ 1.5) | 0.42 ✗ | 2.38 ✓ |
| Bilgili ortalama (7.0–8.5) | 7.48 ✓ | 7.12 ✓ |
| İlk ödül (Y5–Y8) | Y4 ✗ | Y6 ✓ (koşuların %54'ü) |
| Rastgele iflas ilk 3 yıl (%20–40) | %25.6 ✓ | %22.8 ✓ |
| Plaza katı (Y12–Y16) | Y16 ✓ | Y17 ✗ |
| Y30 bilgili puan (uzun koşu) | 3.38 | 4.08 |

**Açık kalanlar**
- Plaza katı bir yıl gecikti (Y17). Denendi: plaza itibar şartı 40→35, ödül eşiği 15→10 ve nakit şartı ₺15M→₺12M → üçü de Y17'de kaldı, şartlar GDD'deki değerlerinde bırakıldı. Asıl fren taşınma bedeli ve plaza kirası: bot taşınmayı ancak bunları güvenle karşılayacak nakde ulaşınca yapıyor. Plazayı öne çekmek için bunlara bakılmalı (karar Orgo'da).
- Geç yıllardaki puan düşüşü azaldı ama sürüyor (Y30 4.08). Asıl çözüm M11'de (bina katı, eşzamanlı kampanyalar).
- Yıl süresi: hız değişmedi; Ayarlar → Tempo'daki gerçek ölçümle karar verilecek (K-096).
- Tekrarcı ile rastgele bot artık birbirine yakın (4.74 / 4.46): hep aynı şeyi yapmak neredeyse rastgele oynamak kadar cezalandırılıyor. Playtest'te sert gelirse `same_channel_streak` 0.65→0.75 yumuşatılabilir.
