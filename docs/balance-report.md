# Denge raporu (M10-A, değişiklik öncesi)

Üretildi: 2026-11-04 · kısa koşu: 1000 koşu × 10 yıl · uzun koşu: 200 koşu × 30 yıl.
Araçlar: `tools/balance_sim.gd` (botlar), `tools/balance_report.gd` (bu rapor). Hedefler GDD 27.2.

## Hedefler

| Metrik | Hedef | Değer | Durum |
|---|---|---|---|
| Rastgele bot ilk 3 yılda iflas | %20–40 | %25.6 | ✓ |
| Bilgili bot küçük ofise geçiş (medyan yıl) | Y2–Y3 | Y3 (%99 koşuda) | ✓ |
| Bilgili bot plaza katına geçiş (medyan yıl) | Y12–Y16 | Y16 (%96 koşuda) | ✓ |
| Bilgili bot ortalama puan | 7.0–8.5 | 7.48 | ✓ |
| Tekrarcı bot, bilgiliden en az 1.5 düşük | ≥ 1.5 | 0.42 (tekrarcı 7.06) | ✗ |
| Rastgele bot, bilgiliden en az 2.5 düşük | ≥ 2.5 | 1.20 (rastgele 6.28) | ✗ |
| Bilgili bot ilk ödül (medyan yıl) | Y5–Y8 | Y4 (%79 koşuda) | ✗ |
| Rastgele kombinasyonların uyum çarpanı (ortalama) | 0.93–0.97 | 0.956 | ✓ |
| …ve en az %20'si 0.85'in altında | ≥ %20 | %22.7 | ✓ |
| Bir oyun yılı gerçek süre (1x, duraklamasız) | 10–15 dk | 2.4 dk | ✗ |

## Botlar

| Bot | İflas ilk 3 yıl | İflas 10 yıl | Ort. puan | Kampanya/koşu | Ödül/koşu | Kredi/koşu |
|---|---|---|---|---|---|---|
| rastgele | %25.6 | %59.1 | 6.28 | 26.9 | 0.1 | 0.00 |
| bilgili | %0.8 | %6.2 | 7.48 | 51.1 | 1.6 | 0.14 |
| tekrarcı | %1.2 | %6.1 | 7.06 | 51.6 | 0.6 | 0.15 |
| açgözlü | %43.9 | %72.7 | 7.77 | 27.2 | 0.9 | 1.58 |

## Yıllara göre (kısa koşu)

| Yıl | rastgele nakit | puan | ekip | itibar | bilgili nakit | puan | ekip | itibar | tekrarcı nakit | puan | ekip | itibar | açgözlü nakit | puan | ekip | itibar |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Y1 | 115097 | 6.40 | 1.9 | 5.7 | 143827 | 7.27 | 1.7 | 7.7 | 142975 | 6.86 | 1.6 | 7.0 | 136569 | 8.35 | 2.0 | 10.2 |
| Y2 | 205144 | 6.47 | 1.9 | 6.4 | 277931 | 8.04 | 2.2 | 11.3 | 277429 | 7.67 | 2.3 | 10.0 | 233690 | 8.00 | 3.3 | 14.2 |
| Y3 | 276012 | 6.35 | 2.0 | 7.3 | 347688 | 8.16 | 3.2 | 17.4 | 360804 | 7.74 | 3.2 | 14.2 | 321757 | 8.21 | 4.8 | 21.0 |
| Y4 | 337489 | 6.32 | 2.4 | 7.8 | 474155 | 7.89 | 4.6 | 22.7 | 464074 | 7.47 | 4.5 | 17.4 | 563048 | 7.81 | 5.8 | 26.8 |
| Y5 | 373459 | 6.38 | 2.8 | 8.7 | 679861 | 7.54 | 5.4 | 29.6 | 655872 | 7.17 | 5.3 | 22.0 | 861925 | 7.46 | 6.0 | 33.6 |
| Y6 | 444768 | 6.37 | 3.2 | 9.3 | 1049533 | 7.41 | 5.8 | 33.9 | 1001603 | 6.93 | 5.7 | 24.3 | 1326644 | 7.36 | 6.0 | 37.7 |
| Y7 | 620111 | 6.20 | 3.5 | 9.6 | 1560195 | 7.29 | 5.9 | 37.7 | 1424328 | 6.80 | 5.9 | 26.2 | 1937094 | 7.30 | 6.0 | 41.4 |
| Y8 | 883808 | 6.08 | 3.9 | 9.4 | 2072706 | 7.22 | 6.0 | 41.3 | 1873075 | 6.79 | 7.0 | 27.9 | 1784175 | 7.39 | 8.7 | 45.0 |
| Y9 | 1163353 | 6.02 | 4.0 | 9.3 | 2419231 | 6.98 | 6.6 | 44.3 | 2360756 | 6.65 | 7.2 | 30.0 | 2229514 | 7.37 | 10.3 | 49.7 |
| Y10 | 1464705 | 5.92 | 4.2 | 9.3 | 2765624 | 6.84 | 8.5 | 47.7 | 2712668 | 6.39 | 7.6 | 32.0 | 3852581 | 7.31 | 11.6 | 54.6 |

## Yıllara göre (uzun koşu)

| Yıl | bilgili nakit | puan | ekip | itibar | açgözlü nakit | puan | ekip | itibar |
|---|---|---|---|---|---|---|---|---|
| Y1 | 142801 | 7.28 | 1.6 | 7.9 | 145807 | 8.35 | 2.0 | 10.2 |
| Y2 | 295269 | 7.98 | 2.3 | 11.4 | 218952 | 7.98 | 3.4 | 13.6 |
| Y3 | 350047 | 8.23 | 3.4 | 17.5 | 334604 | 8.18 | 4.9 | 20.2 |
| Y4 | 510034 | 7.95 | 4.7 | 22.7 | 605075 | 7.94 | 5.9 | 27.0 |
| Y5 | 705817 | 7.58 | 5.4 | 29.6 | 915915 | 7.48 | 6.0 | 33.4 |
| Y6 | 1147943 | 7.43 | 5.8 | 33.9 | 1224379 | 7.61 | 6.0 | 37.8 |
| Y7 | 1547662 | 7.34 | 6.0 | 37.7 | 1844815 | 7.22 | 6.0 | 41.4 |
| Y8 | 2031937 | 7.17 | 6.0 | 40.9 | 1666363 | 7.36 | 8.3 | 44.7 |
| Y9 | 2531045 | 7.04 | 6.7 | 44.0 | 1954793 | 7.35 | 10.0 | 49.7 |
| Y10 | 2907041 | 6.80 | 8.4 | 47.6 | 3930762 | 7.15 | 11.4 | 55.3 |
| Y11 | 3770106 | 7.08 | 10.3 | 51.4 | 5434562 | 6.74 | 12.0 | 60.7 |
| Y12 | 5124633 | 6.99 | 11.6 | 56.6 | 7973634 | 6.55 | 11.9 | 64.3 |
| Y13 | 7949774 | 6.97 | 11.8 | 59.9 | 11359688 | 6.46 | 11.9 | 66.3 |
| Y14 | 10473814 | 6.47 | 12.1 | 62.6 | 5264473 | 6.62 | 17.6 | 69.2 |
| Y15 | 12021459 | 6.39 | 12.7 | 64.6 | 5206904 | 7.17 | 20.0 | 73.0 |
| Y16 | 10497245 | 6.14 | 15.5 | 67.3 | 7009302 | 7.31 | 22.4 | 78.1 |
| Y17 | 8692936 | 6.63 | 19.2 | 70.3 | 8050657 | 6.98 | 25.3 | 80.9 |
| Y18 | 10845483 | 7.08 | 22.0 | 74.0 | 13403765 | 6.86 | 25.6 | 84.4 |
| Y19 | 13252012 | 7.24 | 23.4 | 85.0 | 13110991 | 6.86 | 25.4 | 90.4 |
| Y20 | 15681428 | 7.04 | 24.2 | 91.7 | 16338330 | 6.59 | 25.8 | 92.9 |
| Y21 | 19754466 | 6.70 | 25.3 | 94.6 | 20004540 | 6.43 | 25.3 | 95.4 |
| Y22 | 23455092 | 6.31 | 25.6 | 95.8 | 29478684 | 5.71 | 26.9 | 95.0 |
| Y23 | 29500350 | 5.91 | 26.4 | 95.7 | 30850730 | 5.24 | 26.5 | 95.1 |
| Y24 | 33141372 | 5.59 | 26.4 | 95.3 | 40812657 | 5.11 | 26.2 | 95.2 |
| Y25 | 39168400 | 5.17 | 26.9 | 94.0 | 39402468 | 5.08 | 27.2 | 94.1 |
| Y26 | 46433899 | 4.68 | 27.1 | 91.4 | 46235645 | 4.55 | 27.1 | 91.2 |
| Y27 | 51487889 | 4.40 | 27.2 | 89.3 | 54103773 | 4.32 | 27.6 | 90.3 |
| Y28 | 59689376 | 3.97 | 27.6 | 85.6 | 56816243 | 4.10 | 28.1 | 86.5 |
| Y29 | 64079224 | 3.50 | 27.9 | 80.7 | 53958043 | 3.31 | 28.4 | 84.8 |
| Y30 | 71663938 | 3.38 | 27.9 | 74.5 | 36065499 | 3.47 | 29.0 | 77.3 |

## Öneriler (onay bekliyor)

Hiçbiri henüz uygulanmadı. Denemeler `balance_sim --set=…` ile, dosyalar değiştirilmeden yapıldı: 200 koşu × 10 yıl, 30 yıllık denemeler 60 koşu.

| # | Sorun | Öneri | Deneme sonucu | Yan etki |
|---|---|---|---|---|
| Ö1 | Rastgele–bilgili farkı 1.20 (hedef ≥ 2.5) | Uyum çarpanları daha keskin: `fit_multiplier` −3: 0.45→0.30, −2: 0.62→0.45, −1: 0.82→0.72, +1: 1.06→1.10, +2: 1.14→1.25, +3: 1.25→1.40. Kaydırıcı dengesizliği cezası: `balance_sk.penalty_per_log` 0.25→0.5, `max_penalty` 0.30→0.50. Yanlış odağın tabanı: `focus.min_mult` 0.80→0.60 | Fark **2.13** (rastgele 5.16, bilgili 7.29). M1 hedefi (≥ 2) ✓, M10 hedefi (≥ 2.5) ✗ | Rastgele bot 10 yılda %65 iflas (önce %59), ilk 3 yılda %29 (hedef içinde). Bilgili bot 7.48→7.29. Yanlış seçimler daha çok acıtır. |
| Ö2 | Tekrarcı–bilgili farkı 0.42 (hedef ≥ 1.5) | Yeni yenilik kuralı (GDD 7.8'e ek): aynı ana kanal son iki kampanyada da kullanıldıysa N ×0.65 (`novelty.same_channel_streak`) | 0.85 ile fark 0.83, 0.70 ile **1.41**. 0.65 ile hedefi tutması bekleniyor (M10-B'de doğrulanır). | Bilgili bot etkilenmiyor (7.49). Oyuncu kanalını çeşitlendirmeye teşvik edilir. |
| Ö3 | İlk ödül Y4 (hedef Y5–Y8) | Ödüle başvurmak için en az itibar: `awards.min_reputation` 0→15 | 25 ile ilk ödül Y8, ama yalnızca koşuların %33'ü ödül alıyor (koşu başına 0.4; önce 1.6): fazla sert. 15 ile Y5–Y6 bekleniyor (M10-B'de doğrulanır). | Erken yıllarda ödül yok; oyuncuya "itibarın yetmiyor" diye söylenir. Alternatif: hedefi Y4–Y8 kabul edip değiştirmemek. |
| Ö4 | 21. yıldan sonra puan düşüşü (A-014) | Dönem beklentisi daha yavaş büyüsün: `score.era_growth` 1.075→1.06 | Y30 puanı 3.38→**5.15**, Y25 5.17→6.76; 30 yıl ortalaması 6.54→7.18; plaza katı Y16 ✓ | Kalan düşüş ekibin plaza katında ~28 kişide tıkanmasından. Asıl çözüm M11'de: bina katı, eşzamanlı kampanyalar. Bina katının (seviye 5) parasını ₺30M'a indirmek denendi: kira yüzünden %82 iflas, **önerilmiyor**. |
| Ö5 | 1x'te bir oyun yılı 2.4 dk (hedef 10–15 dk) | **Değişiklik önerilmiyor.** M2 playtest kararı (K-034): haftada 3 sn "iyi" bulundu; 10–15 dk, oyuncunun duraklattığı ve pencerelerde geçirdiği süreyle birlikte okunuyor. | — | M10 playtest'inde oyunculara yeniden sorulur. |

Ödül eşiklerini yükseltmek de denendi (kısa liste 7.8, bronz 8.6): ilk ödül yine Y4'te kaldı, ödül sayısı ise dörtte bire düştü. **Önerilmiyor.**
