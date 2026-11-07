# Kararlar (decisions.md)

GDD'deki çelişki ve belirsizlikler için verilen kararlar. Biçim: **K-xxx** · tarih · durum · kim karar verdi.
"Orgo onayı" = geliştiriciye soruldu ve onaylandı. "Uygulama kararı" = dokümanla çelişmeyen, teknik/biçimsel bir seçim.

---

## K-001 · 2026-10-31 · Kabul · Orgo onayı
**Konu:** GDD markdown dosya adları.
**Durum:** Örnek promptta `docs/gdd/01-vizyon.md` var, ama vizyon Bölüm 2; aynı promptta `07-puanlama.md` Bölüm 7 ile eşleşiyor.
**Karar:** Dosyalar bölüm numarasıyla adlandırılır: `01-kullanim.md`, `02-vizyon.md` … `07-puanlama.md` … `29-ekler.md`; içindekiler + "bir cümlede oyun" `00-icindekiler.md`.

## K-002 · 2026-10-31 · Kabul · Orgo onayı
**Konu:** Satış/Dönüşüm hedefinin ideal S/K oranı.
**Durum:** Tablo 8.2 ve 8.2'nin açıklaması **1.7**; Bölüm 7.7'deki yorum satırı "Satış 1.6".
**Karar:** **1.7** geçerli (tablo veri kaynağıdır). `data/objectives.json → sales.ideal_sk = 1.7`. 7.7'deki 1.6 yazım hatası sayılır.

## K-003 · 2026-10-31 · Kabul · Orgo onayı
**Konu:** Ton tablosunda (8.3) gruba yazılmamış sektörler.
**Durum:** 8.3 ton uyumu 11 sektör grubu için tanımlı; 10 sektör hiçbir grubun adında geçmiyor.
**Karar:** `data/sectors.json → tone_group` eşlemesi:

| Sektör | Ton grubu |
|---|---|
| Kahve & Kafe Zinciri | Fast Food / Gıda / İçecek |
| Evcil Hayvan Ürünleri | Fast Food / Gıda / İçecek |
| Turizm & Otel | Moda / Kozmetik / Lüks |
| Havayolu | Otomotiv |
| Emlak & İnşaat | Otomotiv |
| Eğitim & Dershane/Okul | Sağlık / İlaç / Hastane |
| Bebek & Çocuk Ürünleri | Sağlık / İlaç / Hastane |
| Beyaz Eşya & Ev Aletleri | Perakende / E-ticaret |
| Mobilya & Dekorasyon | Perakende / E-ticaret |
| Medya & Yayıncılık | Oyun / Festival / Spor |

Adı grupta geçen diğer 25 sektör doğrudan o gruba bağlandı (ör. Gıda & Ambalajlı Ürün, Alkolsüz İçecek → Fast Food / Gıda / İçecek; Mobil Uygulama & Startup, Kripto & Fintech → Teknoloji / Startup / Fintech; E-ticaret → Perakende / E-ticaret; Özel Hastane → Sağlık; STK ve Kamu → STK / Kamu; Oyun, Spor, Festival → Oyun / Festival / Spor; B2B Yazılım, Lojistik, Enerji → B2B / Lojistik / Enerji).

## K-004 · 2026-10-31 · Kabul · Uygulama kararı
**Konu:** Bölüm 7'deki kaymış tablo numaraları.
**Durum:** 7.2'de `uyum_SK # Tablo 8.2` (sektör × kitle aslında 8.1'in sağ yarısı); 7.4 ve 7.7'de "Tablo 8.3" (odak önemi ve ideal S/K aslında 8.2'de; 8.3 ton tablosu).
**Karar:** Atıflar yazım hatası sayılır; içerik değişmez. `docs/gdd/07-puanlama.md` içine açıklayıcı not eklendi.

## K-005 · 2026-10-31 · Kabul · Uygulama kararı
**Konu:** PDF'in konumu.
**Durum:** PDF proje kökünde `Ajans_Tycoon_GDD_ve_Yol_Haritasi_1.pdf` adıyla duruyordu; GDD `docs/GDD.pdf` bekliyor. Dosya başka bir programda açık olduğu için taşınamadı.
**Karar:** `docs/GDD.pdf` olarak kopyalandı (bayt bayt aynı). Kökteki orijinal `.gitignore`'a eklendi; istersen silebilirsin.

## K-006 · 2026-10-31 · Kabul · Orgo onayı
**Konu:** Godot ve test eklentisi sürümü.
**Karar:** Godot **4.7.2-stable** (2026-08-18, en güncel kararlı 4.x; resmi GitHub sürümü) `C:/Users/osonm/Tools/Godot/` altına kuruldu (proje dışında). GUT **9.7.1** (Godot 4.7 uyumlu) `addons/gut/` altına kuruldu. Sürüm `CLAUDE.md`'ye yazıldı; yükseltme ayrı bir görev olarak yapılır (GDD 23).

## K-007 · 2026-10-31 · Kabul · Uygulama kararı
**Konu:** Veri kimlikleri (id) ve dosya biçimi.
**Karar:**
- id'ler İngilizce `snake_case` (GDD 24.4 örnekleri gibi: `fast_food`, `billboard`, `sales`, `young/adult/mature/b2b`). Parodi platform adları korunur (`instafoto`, `tiktak`, `youtup_video`…).
- Görünen adlar `name_key` ile `localization/strings.csv`'de (TR + EN). Önek: `SEC_`, `OBJ_`, `AUD_`, `TONE_`, `TG_`, `FOCUS_`, `CH_`.
- Liste dosyaları (`sectors.json`, `channels.json`…) kayıt dizisidir. Uyum dosyaları şu yapıdadır:
  `{ "row_type": "sector", "tables": { "objective": { "column_type": "objective", "rule": "six_col", "values": { "<satır id>": { "<sütun id>": -3..3 } } } } }`
  `channel_fit.json` iki tablo içerir (`objective`, `audience`). `rule`, `balance.json → fit_row_rules` anahtarıdır.
- Kanal min. bütçesi tablodaki "₺k" × 1000 olarak ₺ cinsinden yazılır (24.4 örneğinde billboard `5000`). Viral ★ sayısı `viral` 0–3.
- Kanal türleri: Baskı→`print`, OOH→`ooh`, Gerilla→`guerrilla`, Yayın→`broadcast`, Dijital→`digital`, Sosyal→`social`, Influencer→`influencer`, Etkinlik→`event`, Sponsorluk→`sponsorship`, PR→`pr`.
- Odak alanları: `research, insight, positioning` (strateji) · `concept, copy, visual` (kreatif) · `production, media_planning, measurement` (prodüksiyon).

## K-008 · 2026-10-31 · Kabul · Uygulama kararı
**Konu:** M0'da kanallarda olmayan alanlar.
**Durum:** 24.4 şemasındaki `base_cpm`, `base_er`, `base_cvr`, `audience_size`, `options` yalnızca billboard örneğinde değerle verilmiş; diğer kanallar için GDD'de sayı yok.
**Karar:** M0'da yalnızca GDD'de değeri olan alanlar yazıldı: tüm kanallar için tür/yıl/min. bütçe/viral; `interest_curve` sadece gazete, InstaFoto, billboard (5.3); `needs_outputs` sadece billboard, ulusal/yerel TV, arama reklamı (7.6); billboard'un 24.4 örnek değerleri. Diğer değerler M4'te (KPI) eklenecek; uydurma sayı girilmedi. `requires_research` şimdilik hepsinde `null` (kanal→Ar-Ge eşlemesi M7'de; ör. dijital kanallar → "Dijital Departman").

## K-009 · 2026-10-31 · Kabul · Uygulama kararı
**Konu:** Bölüm 5.2 ile 8.4 arasındaki kanal yılları farkı.
**Durum:** YouTüp 2005/2007, FaceBuk 2007/2008, Cıvıl 2008/2009, TikTak 2018/2019; DOOH 5.2'de Yapay Zekâ Çağı listesinde ama 8.4'te 2012 (9.2'de de "2012+"); 2.2'de "2000'de Gooble Kelime Reklamları" ama 5.2 ve 8.4'te 2002.
**Karar:** Kanalın kullanılabildiği yıl için 8.4 tablosu esas (veri tablosu, "birebir" kuralı). 5.2'deki yıllar platformun ortaya çıkışı / dönemin öne çıkanı olarak okunur (InstaFoto "2011, reklam 2015" örneğindeki gibi); 2.2'deki 2000 yaklaşık örnek sayılır. İleride dönem olaylarında (ör. "yeni platform çıktı") 5.2 yılları kullanılabilir.

## K-010 · 2026-10-31 · Kabul · Uygulama kararı
**Konu:** `.gitignore` içeriği.
**Karar:** CLAUDE.md kuralına uyularak hem `.godot/` hem `*.import` dosyaları depoya girmez. Ayrıca `strings.csv`'den üretilen `*.translation` dosyaları da dışarıda (editör/`--import` yeniden üretir). Not: Godot'nun resmi önerisi `.import` dosyalarını depoya koymaktır; M6/M8'de özel içe aktarma ayarı gereken modeller gelirse bu karar yeniden ele alınmalı.

## K-011 · 2026-10-31 · Kabul · Uygulama kararı
**Konu:** `balance.json` içeriği.
**Karar:** 29.1 taslağı birebir alındı; 7.6'da "balance.json → deep_mode: false" geçtiği için `"deep_mode": false` eklendi.

## K-012 · 2026-10-31 · Kabul · Uygulama kararı
**Konu:** 24.2 listesinde olmayan ek veri dosyaları ve araçlar.
**Karar:**
- `data/tone_groups.json` — 8.3'teki 11 sektör grubu (ton tablosunun satırları).
- `data/focus_areas.json` — 7.4'teki 9 odak alanı (8.2 sütunları).
- `data/combo_rules.json` — 8.2'de adı geçen dosya; şimdilik tek kural: Satış + SSR → ×0.90 ("samimiyetsiz").
- 8.2 odak önemleri ve ideal S/K `data/objectives.json` içinde (`focus_importance`, `ideal_sk`).
- `tools/data_validator.gd` (`DataValidator` sınıfı) — doğrulama mantığı; `tools/validate_data.gd` komut satırı girişi ve GUT testleri bunu kullanır. M1'de DataDB de bunu kullanabilir.
- `src/ui/screens/boot_screen.tscn` — M0 açılış ekranı (proje "Çalıştır" ile hatasız açılsın diye); M2'de gerçek ana menüyle değişecek.

## K-013 · 2026-10-31 · Kabul · Uygulama kararı
**Konu:** Doğrulama kuralının kapsamı.
**Durum:** M0 promptu "her satırda tek +++, en az bir −−/−−−" diyor; 8.0 ve 29.1 daha ayrıntılı tam dağılımı tanımlıyor.
**Karar:** Doğrulayıcı tam kuralı (`balance.json → fit_row_rules` metninden okuyarak) uygular; M0 promptundaki iki koşul bunun alt kümesidir. Mevcut 91 satırın (35 sektör × 2 tablo, 11 ton grubu, 45 kanal × 2 tablo) hepsi tam kurala uyuyor.

## K-014 · 2026-10-31 · Kabul · Uygulama kararı
**Konu:** Bölüm 16 olay JSON örneği.
**Karar:** Örnekteki `+4` gibi artı işaretli sayılar standart JSON'da geçersiz; veri dosyalarında `4` yazılacak. `title`/`text`/`label` alanları CLAUDE.md'nin "koda/veriye Türkçe metin gömme" ilkesine uygun olarak M7'de yerelleştirme anahtarına dönüşecek (ör. `title_key`).

## K-015 · 2026-10-31 · Kabul · Uygulama kararı
**Konu:** Proje kök klasörü.
**Karar:** 24.2'deki `ajans-tycoon/` kökünün karşılığı mevcut `AD_TYCOON/` klasörüdür; klasör yeniden adlandırılmadı.

---

## K-016 · 2026-10-31 · Kabul · Orgo onayı (A-001)
**Konu:** 7.2 `uyum_KN` içinde `(kanal_hedef + kanal_kitle) / 2` buçuklu değer verebilir (ör. +0.5); `f(x)` yalnızca tam sayılarda tanımlı.
**Karar:** `f` buçuklu değerlerde komşu iki tam sayının çarpanları arasında doğrusal ara değer alır (ör. f(+0.5) = (1.00 + 1.06) / 2 = 1.03).

## K-017 · 2026-10-31 · Kabul · Orgo onayı (A-002)
**Konu:** 7.2'de `uyum_ton = f(…)^0.5`, M formülünde ayrıca `uyum_ton^0.10`.
**Karar:** İkisi birlikte uygulanır (dokümandaki gibi; toplam etki üssü 0.05). Playtest'te ton etkisi fazla zayıf kalırsa yeniden ele alınır.

## K-018 · 2026-10-31 · Kabul · Orgo onayı (A-003)
**Konu:** 7.9 `hata_ağırlığı(yıl)`, 7.10 `talep()`, `hatırlanma()`, `kitle_büyüklüğü`, `pazar_nüfusu`, `ortalama_sepet(sektör)` için GDD'de sayı yok.
**Karar:** Claude M1 planında başlangıç değerlerini önerir; Orgo onayından sonra `data/balance.json`'a yazılır ve burada listelenir.

## K-019 · 2026-10-31 · Kabul · Orgo onayı (A-004)
**Konu:** 6.4 `12*(kalite_puanı − marka.beklenti)/2`.
**Karar:** Dokümandaki gibi bırakılır (etkin katsayı 6); `balance.json`'da tek katsayı olarak tutulur.

---

## K-020 · 2026-10-31 · Kabul · Orgo onayı (M1 planı)
**Konu:** M1 başlangıç değerleri (K-018 kapsamı). Hepsi `data/balance.json`'da.
**Karar:**
- `hata_ağırlığı(yıl, büyüklük) = 0.03 × dönem_tabanı(yıl, büyüklük)` (`scoring.error_weight_ratio`).
- `talep(ilgi) = 0.6 + 0.8 × ilgi`; eğrisi olmayan kanalda ilgi = 1.0 (`kpi.demand_*`).
- `hatırlanma(puan) = 0.2 + 0.06 × puan_10` (`kpi.recall_*`).
- Pazar nüfusu 1990'da 56 milyon, yılda +%1. Kitle payları Genç 0.30 · Yetişkin 0.40 · Olgun 0.20 · B2B 0.10.
- Müşteri ölçeğine göre erişim tavanı: Mahalle 0.02 · Yerel 0.1 · Ulusal 0.6 · Çok uluslu 1.0.
- Kanal CPM/ER/CVR: kanal türü varsayılanları (`kpi.category_defaults`); kanalda `base_*` varsa o kullanılır (billboard, GDD 24.4).
- Hedefe göre dönüşüm çarpanı (7.10'da yalnız Satış 1.5, Bilinirlik 0.4 verilmiş): Lansman 0.8, Yenileme 0.5, Etkileşim 0.9, SSR 0.3.
- `ortalama_sepet(sektör)`: `data/sectors.json → avg_basket` (1990 ₺).
- Ev ofisi aylık gideri ₺1.500 (enflasyonla artar).
- Brief ücretleri (1990 ₺): fee küçük 6–15k / orta 25–60k; medya küçük 15–60k / orta 120–400k.

## K-021 · 2026-10-31 · Kabul · Uygulama kararı
**Konu:** 7.5 "her üretim bir hata olasılığı taşır".
**Karar:** Hata zarı çalışan başına günde bir kez atılır: `p = 0.06 × (1 − dikkat/100) × (acele ? 1.4 : 1)`. Teslim süresi 4 haftanın altındaysa "acele" sayılır (`production.rush_below_weeks`). Alan başına zar atılsaydı günde 3 kat hata çıkardı.

## K-022 · 2026-10-31 · Kabul · Uygulama kararı
**Konu:** M1 mimarisi.
**Karar:** Simülasyon `src/sim` altında, Node'dan bağımsız: `GameData` (veri), `SimRng` (sistem başına tohumlu akış), `SimState` (tüm durum, sözlük/dizi), `SimClock`, `Scoring`, `Kpi`, `Economy`, `ClientSystem`, `BriefGenerator`, `CampaignProduction`, `Simulation` (bağlayıcı). Oyuncu eylemleri `src/commands` (`StartCampaignCommand`, `DeclineBriefCommand`). M2'de `GameState`/`Clock`/`DataDB` autoload'ları bunları saracak (24.2'deki `clock.gd` autoload olarak kalır, saf hesap `sim_clock.gd`'de).

## K-023 · 2026-10-31 · Kabul · Uygulama kararı
**Konu:** M1 sadeleştirmeleri (ilgili taşta gerçek sistemle değişecek).
**Karar:** Tek üretici oyuncu karakteri; araç çarpanı 1.0 (M7), uzmanlık 1.0 (M3), ev odası kalitesi 50 → ofis çarpanı 1.05 (M6), moral 70 ve enerji 100 sabit (M3). Revizyon turu, gecikme, bütçe aşımı, account bonusu 0. Trend = 1, AI yorgunluğu yok (M7). Tedarikçi verimi 1, CPM'de mevsim 1, prodüksiyon marjı yok (M4). Çift hedef ve `combo_rules` uygulanmıyor (Ar-Ge, M7). Ar-Ge kilitleri yok: ton/kitle/çoklu kanal baştan açık (M7). Aynı anda tek kampanya üretimde (yayındakiler paralel). Memnuniyet < 20 olan müşteri ihaleye çıkmadan ayrılır (M5'te pitch). Yeni marka teklifleri doğrudan iştir (M5'te pitch daveti). Güven (trust) değişmiyor (M3 account ekibi).

## K-024 · 2026-10-31 · Kabul · Uygulama kararı (geçici)
**Konu:** M1'de büyüme mekaniği yok; dönem tabanı her yıl %8.5 artıyor.
**Durum:** Hiç büyümeyen tek kişilik ajansta puanlar yıl yıl düşüyor (ilk ölçüm: bilgili bot Y1 5.2 → Y10 2.1).
**Karar:** GDD 11.2/11.5'teki XP/seviye mekaniğinin sade hâli oyuncuya uygulandı: puan × 10 XP, 100 XP'de seviye, seviye başına +3 stat (o kampanyanın S/K/T payına göre) ve +1 hız, tavan 100 (`player_growth`). M3'te çalışan modeliyle değiştirilecek. Başlangıç statları: Strateji 75, Kreatif 75, Teknik 60, Hız 70, Dikkat 50.

## K-025 · 2026-10-31 · Kabul · Uygulama kararı
**Konu:** Kampanya para akışı (GDD 7.11, 13.3).
**Karar:** Teslimde müşteriye tek fatura kesilir: fee + medya + %15 komisyon. Vade ödeme disiplinine göre 4/8/12 hafta (30/60/90 gün); geç ödeme olasılığı `(100 − ödeme)/100 × 0.1`, gecikme +4..8 hafta. Medya, tedarikçiye teslimden 6 hafta sonra ödenir (`cashflow.media_payment_weeks`; GDD "peşin veya 30 gün", ayarla 45 güne çekildi). Medya geçiş kalemidir, vergiye girmez. KPI aşılırsa yayın sonunda ayrı prim faturası: fee × min(%50, KPI oranı − 1). Yıl sonunda kârın %25'i kurumlar vergisi.

## K-026 · 2026-10-31 · Kabul · Uygulama kararı
**Konu:** Brief ve müşteri detayları.
**Karar:** Oyun 2 başlangıç müşterisiyle açılır (Lezzetçi Köfte, Çınar Mobilya; mahalle ölçeği). Brief büyüklüğü müşteri ölçeğine göre (mahalle: küçük; yerel: küçük/orta; ulusal ve üstü: orta). Ev odasında büyük/mega yok (12.1). Teslim süreleri küçük 4–7, orta 8–12 hafta. Brief'lerin %40'ında hedef serbest. Brief 2 hafta sonra düşer. Haftalık brief olasılığı ölçeğe göre %5–8 × mevsim çarpanı (×1.5). KPI türü hedefe göre (Bilinirlik/Lansman/SSR → erişim, Satış → dönüşüm, Yenileme → bilinirlik artışı, Etkileşim → etkileşim). Hedef değer: ortalama kanal + ortalama kitle + puan 6 ile hesaplanan referans × 0.8–1.2.

## K-027 · 2026-10-31 · Kabul · Uygulama kararı
**Konu:** Formüllerdeki küçük yorumlar.
**Karar:**
- 6.4 `detaycılık` 0–100 tutulduğu için revizyon cezasında /100 ile kullanılır (yoksa tek revizyon −150 eder).
- 7.3 `önerilen_kanal` formülündeki ₺10.000 enflasyonla ölçeklenir (8.4'teki min. bütçeler gibi 1990 bazlı).
- 7.8 "öncü" bonusu yalnızca 1990'dan sonra çıkan kanallara verilir (oyun başında zaten var olanlar "yeni çıkmış" sayılmaz).
- 7.10 viral mekaniği 2005'ten itibaren (formüldeki "2005+"; 5.2'de "2008 Viral mekaniği açılır" yazıyor, Bölüm 7 esas alındı). Viral zarı kanal başına atılır; olasılık × kanalın yıldız sayısı × ton bonusu (Esprili/Cesur ×1.5).
- 14.1 itibar aralıkları büyüklüğe dağıtıldı: puan ≥ 8 → küçük +0.5, orta +1, büyük +1.5, mega +2; puan ≤ 4 → −1/−1.5/−2/−3; müşteri kaybı −2.

## K-028 · 2026-10-31 · Kabul · Uygulama kararı
**Konu:** Arayüzün yapısı (M2).
**Karar:** Ekranlar kodla kurulur: `src/ui/screens/*.gd`, her biri bir `class_name`. Sahne dosyası yalnızca iki kök için var (`main_menu.tscn`, `main.tscn`). Böylece bütün arayüz düz metin olarak okunup düzeltilebilir. Ortak yardımcılar `src/ui/widgets/ui_util.gd`, tema `src/ui/theme/main_theme.tres`. M0'daki `boot_screen` kaldırıldı; ana sahne artık ana menü.

## K-029 · 2026-10-31 · Kabul · Uygulama kararı
**Konu:** Faz slider'larının ne zaman girileceği.
**Karar:** GDT'deki gibi her fazın başında oyun durur ve oyuncu o fazın üç slider'ını girer (`Simulation.pause_on_phase`). Botlar ve testler kurulumdaki slider'larla duraksamadan devam eder. Sihirbaz slider sormaz; varsayılan her alan için 1/3'tür.

## K-030 · 2026-10-31 · Kabul · Uygulama kararı
**Konu:** Rapor ne zaman açılır, ne içerir.
**Karar:** GDD 4.2'deki sıraya uygun olarak rapor yayın bittiğinde otomatik açılır; puan teslimde hesaplanmış olur, teslimde sadece bildirim gelir. Raporun içeriği:
- 4 yorumcu (Reklam Dünyası, Pazarlama Gazetesi, Kreatif Blog, Müşteri): her biri puan ±0.6 verir, puan aralığına göre 5 bant × 2 cümleden biri seçilir.
- Açıklama cümleleri: 7.12'deki 5 örneğe ek olarak kitle, kanal, ton, odak (F), denge (B iki yönlü), öncü bonusu ve sinerji için eşikler. Hepsi `data/report_lines.json`'da.
- Açılıp kapanan "Puan dökümü": M2 ayarı için (A-005).

## K-031 · 2026-10-31 · Kabul · Uygulama kararı
**Konu:** Kayıt sistemi (M2: tek slot).
**Karar:** `user://save_slot_1.sav`, gzip'li JSON, `save_version: 1`, sürüm göçü yeri `SaveCodec.migrate()`. RNG akışlarının seed/state'i 64 bit olduğu için metin olarak yazılır; yüklenen oyun birebir aynı devam eder (test var). Sadece elle kayıt; otomatik kayıt ve 3 slot M9'da.

## K-032 · 2026-10-31 · Kabul · Uygulama kararı
**Konu:** M2'de saat, dil ve büyüklük.
**Karar:**
- Hızlar `time.speeds` = 1x/2x/4x; kısayollar Boşluk (duraklat), 1/2/3. Modal pencere açıkken saat durur.
- Dil ana menüdeki düğmeyle seçilir, varsayılan Türkçe. Ayarlar ekranı M9'da.
- M2 promptu sihirbazda "büyüklük" sayıyor, GDD 6.2'de ise büyüklük brief'in bir alanı. Bu yüzden sihirbazda brief'ten gelen büyüklük salt-okunur gösterilir.

## K-033 · 2026-10-31 · Kabul · Orgo playtest'i
**Konu:** Faz slider'larının davranışı (GDD 7.4).
**Durum:** M2'de bir slider oynatılınca diğer ikisi toplamı %100'de tutmak için kayıyordu; playtest'te hedef yüzdeyi tutturmak zor bulundu.
**Karar:** GDT'deki gibi her slider 0–100 arası bağımsız bir öncelik. İş payı = öncelik / öncelikler toplamı; hepsi 0 ise eşit. Ekranda her slider'ın yanında gerçek pay görünür. Simülasyona yine toplamı %100 olan paylar gider; 7.4'teki %60 azalan getiri kuralı bu paylara uygulanır, formül değişmedi. Varsayılan öncelik 50 (`focus.slider_default_priority`).

## K-034 · 2026-10-31 · Kabul · Orgo playtest'i (A-005, A-010 kapandı)
**Karar:** M2 playtest'inde puanlama ve müşteri tepkileri "adil", oyun hızı (1x'te haftada 3 sn, 5.1) "iyi" bulundu. Bölüm 7 formülleri ve `time.seconds_per_week_1x` olduğu gibi kalıyor. Bot puan farkı (1.5) M10'daki denge çalışmasında 27.2 hedefleriyle (≥ 2.5) yeniden ele alınacak. 4.1 ve 27.2'deki "yıl 10–15 dk" ifadesi, oyuncunun duraklattığı süreyle birlikte kaba bir tahmin olarak okunuyor.

## K-035 · 2026-10-31 · Kabul · Orgo onayı (M3 planı; sayılar uygulama kararı)
**Konu:** Çalışan modeli ve GDD'de sayısı olmayan değerler (M3). Hepsi `data/balance.json → staff_rules` ve ilgili veri dosyalarında.
**Karar:**
- **Kurucu bir çalışandır** (`role: founder`): 4 geçmişten biriyle başlar (`data/backgrounds.json`, 11.5), maaş almaz, genelcidir, account etkisi taşır. M1'in geçici oyuncu büyümesi (K-024) kaldırıldı.
- **Pozisyonlar** (`data/positions.json`): 11.1'deki bütün roller, kıdem unvanları, uzman alanlar, ana statlar, çıkış yılları. 1990 taban maaşları ₺1.600–5.000/ay; GDD örneği art director ₺3.500. Kıdem unvanı her 3 seviyede bir ilerler. Piyasa değeri = taban × enflasyon × (1 + 0.35 × kıdem) × (ana stat ort. / 50).
- **İşe alım** (`data/hiring_channels.json`): İlan ₺500, 3 aday, ana stat ~42, potansiyel 45–75 · Staj ₺200, stat ~30, potansiyel 70–95, maaş ×0.5 · Kariyer sitesi (2000+) ₺1.500, 4 aday, stat ~48 · Headhunter ₺8.000, stat ~62, seviye 3–6, maaş ×1.15. Ana olmayan statlar ortalamanın 12 altında. Hız ~55. Adaylar 1–2 özellik taşır (11.2'deki 10 özellik, `data/traits.json`).
- **Enerji:** Kampanyada çalışırken günde −1.5 (fazla mesaide ×2), boştayken +4, hafta sonu +12.
- **Moral (11.4):** Her hafta hedefe doğru %15 yaklaşır. Hedef = 60 + ofis konforu × 0.5 + diğerlerinin ego etkisi (−5 kişi başı). Buna eklenenler: (maaş/piyasa − 1) × 20, fazla mesai −4/hafta, kampanya sonunda (puan − 6) × 2. Hedefe yaklaşma kuralı GDD'de yok; olmazsa moral sürekli 0 ya da 100'e kayıyor.
- **Tükenmişlik:** Fazla mesai haftası +6 (gece kuşu ×0.5), normal hafta −3. 80'e ulaşınca %30 olasılıkla 2 hafta hastalık izni (−30), yoksa sadakate bağlı istifa olasılığı.
- **XP:** Kampanya puanı × 10; 100 XP'de seviye. Seviye başına +3 ana stat (kurucuda kampanyanın S/K/T payına göre) ve +1 hız; tavan gizli potansiyel. Mentor varsa junior'lar (seviye ≤ 3) ×1.25 XP.
- **Gizli statlar** 24 hafta sonra ya da ajansta İK uzmanı varken görünür.
- **Eğitim:** ₺2.000 (1990), 2 hafta, −25 enerji, +3..6 stat. **Uzmanlaşma:** seviye 5+, ₺5.000, 4 hafta, seçilen sektörde ×1.15.
- **Kovma:** kıdem yılı başına bir aylık maaş (en az bir ay); diğerlerinin morali −5.
- **Rakip teklif:** Maaşı piyasa değerinin %90'ının altındaysa ayda %10 olasılıkla teklif gelir (piyasa +%20). Oyuncu 2 hafta içinde "piyasa +%10 zam" ya da "bırak" seçer; cevapsız kalırsa çalışan gider. Genel olay sistemi M7'de.
- **Departman etkileri:** Account bonusu = 6 × iletişim/100 (+3 müşteri dostu), ekipteki en iyi account'tan gelir. Trafik/Prova okuyucu teslimden önce her hatayı dikkat/100 × 0.6 olasılıkla temizler. Her Creative Director (kreatif departmanda 5. unvan) 6 kreatif yönetir; CD yoksa ilk 6'ya izin var.
- **Maaşlar** aylık, %20.5 SGK ile (29.1 `payroll_tax`).

## K-036 · 2026-10-31 · Kabul · Orgo onayı
**Konu:** 7.5 "uzmanlık bonusu (pozisyon alanla eşleşirse 1.3; uyumsuzsa 0.6)".
**Karar:** Uzman alanı ×1.3; ana statına giden ama uzman olmadığı alan ×1.0; tamamen başka iş ×0.6. Kurucu her alanda ×1.0.

## K-037 · 2026-10-31 · Kabul · Orgo onayı (A) + uygulama kararı
**Konu:** Ofis seviyeleri M3'te (`data/offices.json`, 12.1).
**Karar:** Kapasite 2 / 6 / 12 / 30 / 120. Koşullar 12.1 ve 17'deki gibi (büyütülmüş ofis Y8 A6). 12.1'deki nakit tutarı **taşınma bedeli** olarak ödenir (GDT'deki gibi; enflasyonla ölçekleme K-048 ile kaldırıldı). GDD'de olmayan değerler: aylık kira (1990 ₺) 0 / 3.000 / 12.000 / 50.000 / 250.000; oda kalitesi 50 / 60 / 70 / 80 / 90 (ofis çarpanı 7.5); konfor 0 / 2 / 4 / 6 / 8 (moral). Büyük işler büyütülmüş ofisle (seviye 3) açılır (17 "Büyük Kampanya: Ofis 3"); büyük brief ücret/medya aralıkları eklendi.

## K-038 · 2026-10-31 · Kabul · Uygulama kararı
**Konu:** M3'te ertelenenler.
**Karar:** Aynı anda tek kampanya (A-013). Rakipten transfer kanalı (rakipler M5'te). Yazılım sertifikası ve festival gezisi eğitimleri (M7/M5). Medya, PR, New Business, Muhasebe ve Satın alma etkileri (M4/M5). Ödül avcısı ve sunum canavarı özellikleri veride var, etkileri ödüller ve pitch'le gelecek. Ajans kültürü (geç oyun). İş yükü aşımı ve müşteri kabalığı moral terimleri 0 (olay sistemi M7).

## K-039 · 2026-10-31 · Kabul · Uygulama kararı (denge)
**Konu:** Ekiple birlikte ekonomi ayarı.
**Karar:** Brief ücretleri M1 önerisinin ~2.4 katına çıktı: küçük ₺15–36k, orta ₺60–150k, büyük ₺200–500k. Gerekçe: GDD Y2'de ₺500k'lık ofis bekliyor; eski ücretlerle yılda ~₺85k kâr çıkıyordu. Enerji dengesi düzeltildi (K-035): eski değerlerle sürekli çalışan ekibin enerjisi birkaç ayda 20'nin altına inip üretim yarıya düşüyordu. Kayıt sürümü 2: M2 kayıtları otomatik olarak kurucu çalışana göç eder (`SaveCodec.migrate_v1_to_v2`).

## K-040 · 2026-10-31 · Kabul · Orgo onayı (M4 planı A) + uygulama kararı
**Konu:** GDD'de olmayan kanal verisi.
**Karar:** 45 kanalın hepsine ilgi eğrisi ve CPM/ER/CVR yazıldı (`data/channels.json`; gazete, InstaFoto ve billboard eğrileri 5.3'ten, billboard KPI'ı 24.4'ten). Eğriler 5.2'deki dönemlere göre kuruldu:
- gazete/dergi/el ilanı/SMS/banner zamanla düşer, OOH dayanıklıdır;
- ulusal TV özel TV patlamasıyla (1992+) zirve yapar, 2016'dan sonra düşer;
- dijital ve sosyal kanallar çıkış yılında 0.3 civarı başlar ve yükselir;
- reklam engelleyici (2014+) display'i, çerezsiz dünya (2024) programatiği düşürür;
- Büyük Kapanma (2020) etkinlik ve sinemayı bir yıl çökertir.

Kanal etkinliği (gösterim) ilgiyle çarpılır (5.3 "kanalın etkinliği bu eğriyle çarpılır"), CPM de talep üzerinden ilgiyle artar. CPM'e mevsim etkisi eklendi (`calendar.json → cpm_season`: Kasım ×1.1, Aralık ×1.2, Ramazan Bayramı ×1.1, Kurban Bayramı ×1.05).

## K-041 · 2026-10-31 · Kabul · Uygulama kararı
**Konu:** Basılı işler (9.1, 10.2).
**Karar:**
- Basılı iş yapan kanallar: el ilanı/broşür, katalog, POP. Gazete ve dergi ilanı medya alımı sayılır.
- Bu kanalların bütçe payı medya değil prodüksiyondur: müşteriye fatura edilir, matbaaya baskı + dağıtım ödenir, aradaki fark prodüksiyon marjıdır (7.11); bu pay için komisyon alınmaz.
- Ürünler, dağıtım yolları ve 1990 fiyatları `data/print_options.json`'da (ör. A5 el ilanı ₺0.15/adet @1.000, kurulum ₺300). Dağıtımın çöpe giden oranı: kapı kapı %35, gazete arası %45, mağaza %25, fuar %15. Görülme = adet × parça başı görülme × (1 − çöp oranı).
- Kalite algıyı etkiler: ekonomik ×0.95, premium ×1.05; lüks grubunda ×0.85 / ×1.10.
- Teslim = adet / haftalık kapasite + sıra + (prova 1 hafta). Baskı son fazdan (teslim süresi / 3) uzun sürerse gecikme olur (6.4, haftada −6 memnuniyet). Baskı hatasında yeniden basılır: ek maliyet + 1 hafta. Marj eksiye düşerse "bütçe aşımı" sayılır (−8).
- **Otomatik baskı:** ilk ürün, standart kalite (lüks sektörde premium), Renkli Baskı, prova açık. Adet, bütçenin %20 marj bırakacak kısmı kadar ve son faza yetişecek kadarla sınırlı.
- Matbaalar 10.2'deki 4 örnek; değerler `data/suppliers.json`'da. Hızlı Dijital'de ölçek ekonomisi neredeyse yok (üs −0.02).

## K-042 · 2026-10-31 · Kabul · Uygulama kararı
**Konu:** Tedarikçi teklifleri ve pazarlık (10.3).
**Karar:**
- Haftada %4 olasılıkla teklif gelir; 2 hafta içinde kabul edilmezse düşer.
- Teklif türleri: hacim indirimi (10k–30k adet üzeri işlerde %10–20, 12 hafta) ya da yıllık taahhüt (50k–150k adet karşılığı %15–25 yıl sonuna kadar). Taahhüt tutmazsa ceza = eksik adet × ortalama birim fiyat × 0.1.
- İlişki puanı 50 ile başlar; her iş +2. Puan 50'nin üstündeyse en fazla %5 indirim; 80 ve üstünde sırada öne geçilir (−1 hafta).
- Pazarlık: gizli taban liste fiyatının %5–25 altında (iyi ilişki tabanı düşürür). 3 tur var; her ret %25 olasılıkla ilişkiyi −5 zedeler. Anlaşma olmazsa liste fiyatı geçerli. Satın alma uzmanı tabanı ±(liste × 0.2 × (1 − iletişim/100)) aralığıyla gösterir.

## K-043 · 2026-10-31 · Kabul · Uygulama kararı
**Konu:** Kanal karışımı ve medya satın alma (7.1, 10.4).
**Karar:**
- Çoklu kanal Y3'te açılır (17). Kanal sınırı ofise göre 2/3/4/6/8; ekipte medya planlamacı varsa +1. Bütçe payları faz slider'ları gibi bağımsız önceliklerle verilir (K-033).
- 10.4 tedarikçi verimi = 1 + yetenek/400 + hacim indirimi. Yetenek, ekipteki en iyi medya planlamacının (strateji + iletişim)/2'si. Hacim indirimi, yıllık medya hacminin her ₺1M'u (1990) için %2, en fazla %15. Verim etkin harcamayı (gösterimi) artırır.
- Eşzamanlı kampanya kararı (A-013) M4'ten sonraya kaldı (Orgo, C kararı).

## K-044 · 2026-10-31 · Kabul · Uygulama kararı
**Konu:** Kanal kategorisi seçenekleri (9.2–9.5, 9.7).
**Karar:** Hepsi `data/channel_options.json`'da; arayüz seçenekleri bu dosyadan otomatik çizer, varsayılan "Otomatik"tir.
- **Açık hava:** Lokasyon A (maliyet ×2, gösterim ×2.5; 9.2) / B / C (×0.6 / ×0.5). Süre 1/2/4 hafta: hatırlanma ×0.9 / 1 / 1.1. Megalight için belediye izni gecikmesi %20 (gösterim ×0.5, memnuniyet −3). DOOH'ta ölçümleme slider payı etkileşimi en fazla %20 artırır.
- **Yayın:** Kuşak: sabah ve gündüz Olgun'a, gece Genç'e uygun (9.4); prime pahalı ama geniş. Spot 15–60 sn: maliyet ×0.6–1.8, hatırlanma ×0.8–1.2. TV/sinema/CTV bütçesinin %20'si çekim prodüksiyonudur, ajans bunun %20'sini marj alır. Cesur tonda %10 olasılıkla Yayın Kurulu durdurması (gösterim ×0.3, memnuniyet −5).
- **Dijital ve sosyal:** Teklif modeli CPM/CPC/CPA, hedefe göre etkili ("Bilinirlik + CPA = kötü", 9.5). Hedefleme geniş/dengeli/dar; dar hedeflemenin etkisi 2024'ten sonra zayıflar (çerezsiz dünya).
- **Gerilla:** 9.3'teki 5 fikir kartı; her birinin etkisi ve riski farklı (ceza = bütçenin %10–25'i, memnuniyet −2..−6). Basına çıkma olasılığı = 0.25 + 0.05 × (puan − 6), ekipte PR varsa ×1.33; basına çıkarsa gösterim ×2.
- **Etkinlik:** Bütçenin tamamı prodüksiyon, marj %20 (9.7 "%15–25"). Mekân, catering ve davetli seçenekleri; basın + influencer davetlisi 2012'den itibaren. Riskler: açık havada hava %20, her etkinlikte genel aksilik %12. PR & Etkinlik çalışanı riskleri yarıya indirir.
- Telafi edilmeyen ertelemeler (B kararı): dijital canlı panel, A/B testi, reklam yorgunluğu, sponsorluk sezonu olayları, aylık sosyal medya retainer işi.

## K-045 · 2026-10-31 · Kabul · Uygulama kararı
**Konu:** Influencer pazarlaması (9.6).
**Karar:**
- Havuzda 12 kişi var, her oyun yılı yenilenir. Kademeler (9.6): nano/mikro "mikro" kanalında, makro/mega "makro" kanalında. Takipçi, etkileşim oranı ve ücret aralıkları `channel_options.json → influencers`'ta.
- Gizli "gerçeklik oranı" %40–100 arası. PR & Etkinlik departmanından biri varsa görünür (11.1 "influencer sahte takipçi tespiti"; Ar-Ge'deki "Influencer Analitiği" M7'de).
- Görülme = paylaşım (bütçe/ücret, en fazla 4) × takipçi × 0.35 × gerçeklik oranı. Etkileşim = influencer'ın oranı × kitle uyumu × niş uyumu (sektörle eşleşen niş ×1.3) × tekrar bonusu.
- Aynı kişiyle tekrar çalışınca iş başına %10 indirim (en fazla %20) ve +%10 etkileşim.
- Skandal olasılığı kişi başına %2–12; teslimde zarlanır. Oyuncu 1 hafta içinde karar verir, cevap vermezse sessiz kalmış sayılır:
  - Feshet: gösterim ×0.3, memnuniyet −2.
  - Sessiz kal: memnuniyet −8, itibar −2.
  - Açıklama yap: ekipteki en iyi iletişim statıyla zar atılır; başarıda −2, başarısızlıkta −10.

## K-046 · 2026-11-03 · Kabul · Orgo playtest'i
**Konu:** Rapor "neden bu puan?" sorusunu tam cevaplamıyordu (GDD Sütun 1).
**Durum:** Oyuncu bütün uyumları doğru yaptı, rapor sadece yeşil satırlar gösterdi ama puan 5.4 geldi. Sebep iş miktarıydı: ekibin ürettiği emek (66 puan) dönem beklentisinin (130) %51'iydi. Baskı gecikmesi puanı değil memnuniyeti etkilemişti, rapor bunu da ayırmıyordu.
**Karar:**
- "Neden bu puan?" bölümüne iş miktarı satırı eklendi: emek / dönem beklentisi ≤ 0.6 ise olumsuz, ≥ 0.85 ise olumlu satır (`report_lines.json`, metrik `volume`).
- Memnuniyet değişimi 6.4 formülünün kalemleriyle gösteriliyor: kalite (puan ve beklenti), KPI, zamanlama, bütçe, revizyon, account, cesur eşleşme, kanal riskleri, skandal.
- Formüller değişmedi; yalnızca açıklama eklendi.

## K-047 · 2026-11-03 · Kabul · Orgo onayı (denge adımı)
**Konu:** 7.9 hata cezası ve rekor çıtası uzun vadede puanı çökertiyordu (A-014).
**Durum:** Hata başına ceza dönem tabanının %3'üydü. Taban yılda %8.5 büyürken ekibin emeği büyümüyor, 23. yılda hatalar işin tamamını siliyordu (446 puanlık işten 45 kalıyordu). Rekor (en_iyi_ham) hiç düşmüyordu: 7. yıldaki tek bir şanslı iş, ekip büyüyemediği için yıllarca aşılamayan bir çıta bırakıyordu.
**Karar (GDD formülünden sapma):**
- `Ham = (S+K+T) × M × F × B × N × sinerji × (1 − hata_payı)`; hata_payı = hata sayısı × %3, en fazla %40 (`scoring.error_penalty_per_error`, `error_penalty_max`). GDD'nin "hata ağırlığı kampanya büyüdükçe artar" ilkesi korunuyor: ceza işin kendi emeğiyle ölçekleniyor.
- Rekor her yıl sonunda %10 erir (`score.best_yearly_decay`). Hedef yine `max(rekor × 1.05, dönem tabanı)`.

## K-048 · 2026-11-03 · Kabul · Orgo onayı (denge adımı) · K-037'yi değiştirir
**Konu:** Ofis taşınma bedeli.
**Karar:** 12.1'deki tutarlar açılma yılının parası olarak okunur, enflasyonla büyümez (₺500k, ₺3M, ₺15M, ₺80M). Gerekçe: enflasyonla büyüyen ₺3M (Y15'te ₺8.8M) gerçek kârla hiç birikmiyordu. Kira hâlâ enflasyonla büyür.

## K-049 · 2026-11-03 · Kabul · Orgo onayı (denge adımı)
**Konu:** Yeni müşterilerin ölçeği (6.1, 6.3).
**Karar:** Dışarıdan gelen markanın ölçek olasılığı ofis seviyesine bağlı (`clients.scale_weights_by_office`). Ev odasına çoğunlukla mahalle esnafı gelir, plaza katına ulusal ve çok uluslu markalar. Eski sabit dağılım (%50/35/13/2) ev odası ile küçük ofis arasında bir yerdeydi; büyük ofiste büyük iş hiç gelmiyordu.

## K-050 · 2026-11-03 · Kabul · Orgo kararı (seçenek: büyük markalar avans verir)
**Konu:** Medya bütçesinin nakit yükü (13.3).
**Durum:** Ajans müşterinin medya bütçesini teslimden 6 hafta sonra ödüyor, müşteri ise bunu 4–12 hafta sonra geri ödüyordu. Büyük bir işte (Y15'te ₺2–6M) bu açık hiçbir ajansın taşıyamayacağı kadar büyüktü. Bilgili bot 3. ofiste bile büyük iş alamıyor, ekip 6 kişide kalıyordu.
**Karar:** Müşteri, medya bütçesinin bir kısmını kampanya başında avans olarak öder: mahalle esnafı %0, yerel %50, ulusal ve çok uluslu %100 (`cashflow.media_advance_by_scale`). Faturada avans düşülür. Ev odası dönemindeki nakit gerilimi korunur. Avans sihirbazda gösterilir.

## K-051 · 2026-11-03 · Kabul · Orgo onayı (M5 planı) + uygulama kararı
**Konu:** Rakip ajanslar (14.3).
**Karar:** `data/rivals.json`'da 12 ajans var; GDD 8–15 diyor. 1990'da 4 ajans açık, sonrakiler açılış yıllarında gelir (1993, 1995, 2000, 2001, 2006, 2009, 2012, 2016). Dijital start-up'lar dijital çağı temsil ediyor. Kişilikler balance.json `rivals.personalities`'te:

| Kişilik | Aylık büyüme | İtibar hedefi | Kreatiflik | En fazla çalışan |
|---|---|---|---|---|
| Dev network | %1.2 | 55 | 0.9 | 140 |
| Kreatif butik | %0.6 | 62 | 1.3 | 30 |
| Agresif fiyatçı | %0.8 | 25 | 0.7 | 45 |
| Dijital start-up | %2 (2010'dan sonra ×2) | 35 | 1.0 | 70 |

- Aylık gürültü var. İtibar her ay hedefe %3 yaklaşır.
- 2 kişinin altına düşen ajans her ay %5 olasılıkla kapanır.
- Güç skoru = çalışan^0.6 × (0.5 + itibar/100).
- Tam simülasyon yok: GDD 14.3'teki "basitleştirme" uygulandı.
- Birleşme, satın alma teklifi, fiyat savaşı ve konsorsiyum M11'de.

## K-052 · 2026-11-03 · Kabul · Uygulama kararı
**Konu:** Rakip etkileşimleri (14.3, 11.3).
**Karar:**
- **Müşteri çalma:** Memnuniyeti risk eşiğinin (40) altında olan ve o an üretimde ya da yayında işi olmayan müşteriyi, her ay %8 olasılıkla güce göre seçilen bir rakip alır. Etkisi müşteri kaybıyla aynı: itibar −2 (14.1).
- **Transfer teklifi:** M3'teki teklif olayına teklifi yapan rakibin adı eklendi.
- **Rakipten transfer** (yeni işe alım kanalı, 11.3 "çok pahalı, rakibi zayıflatır"):
  - ₺20.000 (1990), 2 aday, seviye 4–7, ana stat ortalaması 66, maaş ×1.3;
  - işe alınan kişinin geldiği rakip 1 çalışan ve 0.5 itibar kaybeder.

## K-053 · 2026-11-03 · Kabul · Uygulama kararı
**Konu:** Ödül takvimi ve jüri (15).
**Karar:** `data/awards.json`'da 5 ödül var. Başvuru dönemi törenden önceki ay.

| Ödül | Tören | Başvuru ücreti (1990) | Zorluk | Koşul |
|---|---|---|---|---|
| Altın Elma | Kasım | ₺3.000 | 0 | — |
| Etkin Ödülleri (2008+) | Ekim | ₺4.000 | −0.6 | KPI aşımı ×3 |
| Kıyı Aslanları | Haziran | ₺15.000 | −1.0 | — |
| Dijital Yıldızlar (2005+) | Nisan | ₺2.500 | 0 | Yalnızca dijital, sosyal, influencer |
| İyilik İçin | Mart | ₺1.500 | +0.3 | Sosyal sorumluluk hedefi veya STK/belediye |

- Jüri skoru 15'teki formül: puan × 0.5 + N × 2 + viral 1 + kategori uyumu 0.55 + jüri ±1 + zorluk. Kategori uyumu GDD'de sayısız; 0.8 ile bilgili bot ilk ödülü Y3'te alıyordu, 0.55 ile koşuların %63'ünde Y4 (hedef Y5–Y8; puanlar Y5'ten sonra düştüğü için ödüller erken yıllarda toplanıyor, A-014).
- Kategori, ana kanalın türüdür; 3+ kanallı işler "entegre" sayılır.
- Eşikler bütün ödüllerde Altın Elma örneğindeki gibi (7.5 / 8.3 / 8.9 / 9.4 / 9.7).
- **Grand Prix:** O törendeki en yüksek skor (oyuncu ve rakipler) ve ≥ 9.7. GDD "yılın en yüksek skoru" diyor; her ödülün yılda tek töreni olduğu için aynı şey.
- Rakipler her törene 0–3 iş gönderir. Ortalama skor = 4.6 + 2.2 × kreatiflik + 0.025 × itibar, sapma 1.
- Yılın Ajansı: ayrı bir başvuru değil, yıl sonunda hesaplanır (K-055).

## K-054 · 2026-11-03 · Kabul · Uygulama kararı
**Konu:** Ödüllerin etkisi (15, 6.3).
**Karar:**
- **İtibar:** GDD'deki gibi: kısa liste +1, bronz +2, gümüş +3, altın +5, Grand Prix +10.
- **Ekip:** Kampanya ekibinin morali +3 / +5 / +7 / +10 / +15. Ödül puanı her kişiye yazılır, çalışanın piyasa değeri puan başına %2 artar (en fazla %40). Bu, rakip transfer teklifini doğal olarak tetikler.
- **Yeni müşteri:** 6.3'teki "ödül_bonus" ödül puanı başına +0.002 haftalık olasılık, her yıl yarıya iner.
- **Sıralama puanı:** Ödül puanları itibar değerleriyle aynı (1/2/3/5/10).

## K-055 · 2026-11-03 · Kabul · Uygulama kararı
**Konu:** Yıllık sıralamalar ve Yılın Ajansı (14.3, 15).
**Karar:**
- **"En Kreatif":** Yılın ödül puanına göre sıralanır.
- **"En Büyük":** Gelire göre sıralanır. Oyuncunun geliri gerçek ajans geliri; rakibinki çalışan × ₺70.000 (1990) × enflasyon ± %15.
- **Yılın Ajansı:** Ödül puanı + 10 × büyüme oranı en yüksek olan ajans; en az bir ödül şart. Rakibin büyümesi kişiliğindeki büyüme oranından alınır. Oyuncu kazanırsa itibar +5 (GDD'de sayı yok).
- Sıralamalar yıl sonunda Sektör ekranında ve bildirimde yayınlanır.

## K-056 · 2026-11-03 · Kabul · Uygulama kararı
**Konu:** Bildirimlerde yerelleştirilmiş ad.
**Karar:** Simülasyon rakip ve ödül adlarını yerelleştirme anahtarı olarak gönderir; `UiUtil.tr_fmt` metin argümanlarını da çevirir. Anahtar olmayan metinler (müşteri adı gibi) aynen kalır. Böylece simülasyon çeviri bilmeden çalışmaya devam ediyor.

## K-057 · 2026-11-03 · Kabul · Orgo onayı (M5 planı: pitch hazırlığı kampanyayla paralel)
**Konu:** Pitch akışı (14.2).
**Karar:**
- **Davet:** Küçük ofisten itibaren gelir. Haftalık olasılık 0.015 + itibar/2000; aynı anda tek davet ya da tek pitch olabilir.
  - Davet eden marka ulusal (%75) ya da çok uluslu (%25).
  - 2–4 rakip güce göre davet edilir. Hazırlık süresi 2–4 hafta.
  - Davetlerin %30'u katılım ücreti öder: ₺5.000 (1990), ajansa kabulde ödenir.
  - Davetin süresi 2 hafta.
- **Hazırlık:** Seçilen ekip hazırlık bitene kadar kampanyada çalışmaz (`pitch_until`). Aktif kampanyadaki biri seçilirse o kampanyaya katkısı durur; arayüz bunu uyarır.
  - Her çalışan günde 0.5 × kişi çarpanı × Strateji/50 S ve aynı biçimde Kreatif/50 K biriktirir.
- **Sunum:** Hazırlık bitince oyunda zaman durur ve sunum penceresi açılır. Bot ve test modunda unutulan sunum bir hafta sonra her turun ilk kartıyla kendiliğinden yapılır.
- **Ödül:**
  - Kazanırsak marka portföye girer (memnuniyet +10) ve hemen ilk brief'i gelir; brief'in ücreti teklif oranıyla çarpılır. İtibar +2 (GDD'de sayı yok).
  - 2. olursak GDD'deki gibi itibar +0.5 alırız ve marka "sıcak" olur: her hafta %3 olasılıkla doğrudan brief gönderir, sonraki ihalesinde ilişki bonusu +%10.

## K-058 · 2026-11-03 · Kabul · Uygulama kararı
**Konu:** Pitch skoru ve kartlar (14.2).
**Karar:**
- **Gizli tercihler** (−1..+1):
  - risk = (risk kişiliği − 50) / 50;
  - fiyat hassasiyeti rastgele;
  - dijital yakınlık = (yıl − 2005) / 12, dijital sektörlerde +0.4;
  - mizah = sektörün "Esprili" ton uyumu / 3.
- **İpuçları:** Varsayılan olarak 2 tercih görünür; hazırlıkta S ≥ 25 birikmişse 3.
- **Kartlar:** 9 kart `data/pitch_cards.json`'da. Kart uyumu = kartın tercih ağırlıkları · müşterinin tercihleri.
  - Kartın çarpanı = 1 + 0.18 × uyum × (0.5 + İletişim/100) + 0.1 × (kartın statındaki hazırlık payı − 0.5).
  - Uyum ≥ 0.25 ise müşteri gülümser, ≤ −0.25 ise kaşlarını çatar.
- **Oyuncu skoru:** 14.2 formülü: (S × 0.4 + K × 0.6) × üç kartın çarpımı × (1 + itibar/200) × (1 + ilişki) × fiyat. Fiyat = teklif^(−0.8 × (1 + 0.5 × fiyat hassasiyeti)); teklif seçenekleri %85 / %100 / %115.
- **Rakip skoru:** güç × 1.0 × hazırlık haftası × rastgele kart (her tur 0.9–1.12) × (1 + itibar/200) × sektör uzmanlığı 1.15 × fiyat.
  - Rakiplerin teklif oranı: fiyatçı %85, start-up %95, butik %105, network %110.
  - Rakip katsayısı 1.5 iken bilgili bot ihalelerin %16'sını kazanıyordu, 1.0 ile %32'sini (2–4 rakiple adil pay).
- **Kazanan:** softmax(skor / en yüksek skor / 0.12).

## K-059 · 2026-11-03 · Kabul · Orgo kararı (M6 planı: ofis ortada, oda inşası büyütülmüş ofisten)
**Konu:** 3D ofis ve ana ekran (12.1, 20, 21.1).
**Karar:**
- **Ana ekran:** Ortada her zaman 3D ofis görünür. Sol menü ekranları ofisin üstünde ✕ ile kapanan pencere olarak açılır; aynı menü düğmesine tekrar basmak pencereyi kapatır. Oyun pencere açık değilken başlar.
- **Oda inşası** (M6-B) büyütülmüş ofisten (seviye 3) itibaren açılacak. GDD plaza katı (seviye 4) diyor; plaza A-014 yüzünden şu an açılmıyor.
- **Hazır yerleşimler:** Her ofis seviyesinin hazır yerleşimi `data/office_layouts.json`'da: çalışma alanı, toplantı, mutfak, dinlenme, boş alan.
  - Masalar çalışma alanında 2 × 2.5 m aralıkla otomatik dizilir. Her seviyede masa sayısı kapasiteyi karşılar (test).
- **Karakterler:** Kapsül karakterler, departmana göre renkli; kurucunun başında sarı bir halka var.
  - Yerleri simülasyondan okunur: izin/eğitim → görünmez; pitch hazırlığı → toplantı odası; enerji eşiğin altında → mutfak; yoksa masası.
  - Baloncuklar yalnızca görsel: masadaki kampanya ekibinden günde ~%45'i fazın harfini çıkarır (S/K/T), yeni hata "!", seviye atlama "★".

## K-060 · 2026-11-03 · Kabul · Uygulama kararı
**Konu:** Yürüme için NavigationAgent3D yerine AStarGrid2D.
**Karar:** GDD 26'daki M6 metni NavigationAgent3D diyor. Yerleşim 0.5 m'lik ızgarada `AStarGrid2D` ile yürünüyor: duvarlar ve mobilyalar engel, kapılar boşluk. Gerekçe:
- sahnesiz test edilebilir (yerleşim saf veri, `OfficeLayout`);
- çalışma anında navmesh pişirmeye gerek yok;
- M6-B'deki ızgaralı oda ve mobilya yerleştirme aynı ızgarayı kullanacak.

## K-061 · 2026-11-03 · Kabul · Uygulama kararı
**Konu:** Oda kalitesi formülü (12.3).
**Karar:** `oda_kalitesi = taban + 30 × Σkonfor / çalışma_alanı + 1.5 × dekor_türü (en fazla 6) − 200 × max(0, kişi/alan − 0.125)`, sonuç 0..100.
- **Taban:** Eski sabit değer (50/60/70/80/90). Mobilyasız ofiste kalite ve üretim değişmez, mevcut denge korunur (test).
- **Konfor:**
  - Masa kalitesi masa başına: basit 0, ergonomik 1, ayarlanabilir 2 (2005+).
  - Mobilya kendi konfor değerini verir; çalışma alanındaysa tam, başka odadaysa yarısını (12.3 "yakınlık etkisi" sadeleştirildi).
- **Kalabalık:** Kişi başı 8 m²'den az çalışma alanı düşürür.
- **Çarpan:** `ofis_çarpanı = 0.85 + 0.40 × kalite/100` (GDD). Oda kalitesi `SimState.room_quality`'de tutulur, düzenden her hafta ve her inşa işleminde yeniden hesaplanır, kaydedilmez.
- **Katsayılar:** İlk denemede konfor katsayısı 40, çeşitlilik 2 idi; tam döşenmiş büyütülmüş ofis kaliteyi 70'ten 93'e çıkarıyordu. Biraz yumuşatıldı (~+17).
- **Ertelendi:** Bitkilerin sulanması (12.3 "sulanmazsa kurur") M7 ya da M9'a kaldı.

## K-062 · 2026-11-03 · Kabul · Uygulama kararı
**Konu:** Oda etkileri, mobilya ve oda çizme kuralları (12.2, 12.3).
**Karar:**
- **Oda etkileri** (`data/room_types.json`; GDD'de yalnızca beyin fırtınası için sayı var):

  | Oda | Etki |
  |---|---|
  | Toplantı odası | müşteri memnuniyeti +2 (raporda "Toplantı odası" kalemi) |
  | Beyin fırtınası odası | Konsept odağı +%10 (GDD) |
  | Mutfak | enerji %25 daha hızlı dolar |
  | Dinlenme odası | tükenmişlik %50 daha hızlı geçer |
  | Ödül lobisi | pitch skoru +%5 |

  - Etkiler yalnızca kapılı (kapalı) odalardan gelir. Ev odasındaki çaycı ve minder köşeleri süs, etkisi yok. Küçük ofisin hazır toplantı odası ve mutfağı etki veriyor; bu küçük bir denge değişikliği.
  - Aynı tipte ikinci oda etkiyi artırmaz.
  - Stüdyolar (fotoğraf, kurgu, film) ve Ar-Ge lab M7'de.
- **Mobilya:** 13 parça `data/furniture.json`'da.
  - Fiyatlar 1990 parası, enflasyonla artar. Kahve makinesi döneme göre değişir: semaver 1990–2004, filtre kahve 2005–2014, espresso 2015+.
  - 0.5 m'lik ızgaraya oturur, 90° döner.
  - Duvar, masa ya da başka bir eşyanın üstüne konmaz; bir masanın, odanın ya da girişin yolunu kapatamaz.
  - Satışta yarı fiyatı geri gelir. Taşınınca mobilyalar ve çizilen odalar yeni binaya gelmez, mobilya bedelinin yarısı iade edilir; masa kalitesi taşınır.
- **Oda çizme** (büyütülmüş ofisten, K-059):
  - Yalnızca hazır "boş alan"a (gri zemin) çizilir; en az 3 × 3 m, 1 m'lik ızgara.
  - Başka çizilmiş oda ya da eşyayla çakışmaz, yolu kesmez.
  - Bedeli m² başına (₺400–900, 1990). Kapı otomatik olarak boş alana bakan ilk kenara açılır. Yıkınca bedel geri gelmez.
- **Yerleşim düzeltmesi:** Masalar kapalı odaların kapı önüne dizilmiyor (bina seviyesi 5'te mutfak kapısı kapanıyordu). Duvara çok yakın düşen bekleme noktaları atılıyor. Testler artık her seviyede bütün masa ve noktaların girişten ulaşılabildiğini doğruluyor.
- **Kayıt:** Ofis düzeni `SimState.build` olarak kaydediliyor. Eski kayıtlar boş düzenle açılır, sürüm değişmedi (planda kayıt sürümü 3 diyordum; varsayılan değer yetti).
- **Denge (200×10):** Botlar mobilya almıyor; yalnızca küçük ofisin oda etkileri değişti. Bilgili bot ort. puan 6.95 → 6.90, iflas %1 / %6.5, büyütülmüş ofis %58 → %66 (Y10), rastgele bot ilk 3 yılda %35 iflas (değişmedi).

## K-063 · 2026-11-03 · Kabul · Orgo kararı (M7 planı: alan başına araç seti; araştırma GDT gibi)
**Konu:** Araçlar, yazılım ve donanım (5.4, 12.4, 12.5).
**Karar:**
- **Alanlar:** Strateji, Metin, Görsel, Prodüksiyon, Ölçümleme. Her odak alanının bir araç alanı var (`tools.focus_area`): araştırma/medya planlama/ölçümleme → Ölçümleme; içgörü/konumlandırma/konsept → Strateji; metin → Metin; görsel → Görsel; prodüksiyon → Prodüksiyon. Üretimde her odak kendi alanının çarpanıyla çarpılır. Pitch hazırlığında S Strateji, K Görsel çarpanıyla çarpılır.
- **Formül:** GDD'deki gibi `0.6 + Σ katkı × güncellik`, en fazla 1.6. Katkı sahip olunan sürümün değeri. Güncellik 1.0 / 0.85 / 0.7 / 0.5 (0, 1, 2, 3+ sürüm geride).
- **Başlangıç araçları:** Her alanın ücretsiz bir başlangıç aracı var (defter, daktilo, çizim masası, fotokopi, anket formu), katkısı 0.4. Böylece başlangıçta her alan ×1.0, M6'ya kadarki denge korunuyor (test). Eski `founder.tool_mult` 1.0 olarak kaldı.
- **Araç listesi:** 18 parodi araç `data/tools.json`'da (GDD 12.5'teki adlarla). Strateji için GDD'de araç yoktu; TabloPro ve SlaytUstası eklendi.
- **Lisans ve abonelik:**
  - Lisans tek seferlik ve ajans başına (koltuk başı değil, sadeleştirme). Sürüm yükseltme lisansın %60'ı.
  - Abonelik dönemi başlayınca (büyük yazılımlarda 2013) lisans donar: güncellenmez, giderek eskir. Aboneliğe geçen araç hep son sürümde kalır, her ay çalışan başına ücret alınır.
  - Abonelik iptal edilirse araç bırakılır.
- **AI araçları** (Hayalci, Yazgan, Video AI): Her biri yenilik (N) çarpanından %4 düşer. 2026'dan sonra ek ×0.95 ("AI'dan bıktık", 5.2). AI Atölyesi araştırması bu bedeli yarıya indirecek (M7-B).
- **Donanım:** 4 bilgisayar kuşağı (PC-386, Elmacık G4, iMak, M-çip Pro). Her kuşak belli bir yıla kadar çıkan sürümleri çalıştırır. Yeni kuşak çalışan başına ücretle alınır. Kuşağın doğrudan hız etkisi yok (sadeleştirme): eski donanım güncellemeyi engelleyerek dolaylı yoldan yavaşlatır.
- **Kanvaz'ın kalite tavanı** (−%15) uygulanmadı; katkısı düşük, ucuz bir araç.
- **Bilgili bot:** Ayda bir, güvenli nakdin %20'siyle araç alır ve günceller, aboneliğe geçer, bilgisayarları yeniler. AI araçlarını almaz; yenilik bedeli oyuncunun kararı.

## K-064 · 2026-11-03 · Kabul · Uygulama kararı (A-014) · GDD 7.9 sayısından sapma
**Konu:** Dönem tabanı büyümesi ve hızlı başlangıç.
**Karar:**
- **Dönem büyümesi** `score.era_growth` 1.085 → 1.075. Gerekçe: araçlar kişi başı üretkenliği en fazla ×1.6 artırıyor, ekip plaza katında 25–30 kişide kalıyor; 30 yılda ×10.6 büyüyen dönem tabanına yetişilemiyordu. 1.075 ile taban 30 yılda ×8.2 büyüyor.
  - 20 koşu × 30 yıl, bilgili bot (1.085 → 1.075): ortalama puan 6.24 → 6.60; Y22'de 5.87 → 6.40; Y30'da 3.15 → 3.50; plaza katı %75 → %90 (Y16).
- **Hızlı başlangıç** (5.1): 2000 ya da 2010'da başlayan oyunda dönem tabanı oyunun başladığı yıldan büyümeye başlar (`Scoring.era_offset`). Yoksa ev odasındaki tek kişilik ajans 2010'da 1990'ın 2 katı beklentiyle karşılaşırdı.
  - Başlangıç nakdi enflasyonla ölçeklenir. Rakipler, kanallar ve bilgisayar kuşağı o yılın durumundadır.
  - Başlangıç yılı kayda girer; eski kayıtlar 1990 sayılır.
- **M7-A denge (200×10):** bilgili bot ort. puan 7.51 (hedef 7.0–8.5 ✓), iflas ilk 3 yıl %2; rastgele %30 ✓; ilk ödül %82 Y4. 50×30: bilgili ort. 6.63, plaza %90 Y16 ✓, ilk ödül Y5 ✓, puan Y22 6.30 → Y30 3.37.
- **Hâlâ açık:** 25. yıldan sonra puan yine düşüyor (bilgili bot Y30 ~3.5). Bina seviyesi 5 (₺80M, itibar 70) 30 yılda açılmıyor. Ar-Ge (M7-B) ve geç oyun (M11) ele alacak.

## K-065 · 2026-11-04 · Kabul · Orgo kararı (M7 planı: araştırma GDT gibi kilit açar)
**Konu:** Ar-Ge (17).
**Karar:**
- **Araştırma puanı (AP):** Kampanya bitince puan × büyüklük (küçük 1, orta 2, büyük 3, mega 5) kadar gelir. Ar-Ge lab odası haftada +3 AP üretir.
- **Araştırma:** AP + para (1990 ₺, enflasyonla artar) + hafta ister. Aynı anda tek araştırma yürür. 12 araştırma `data/research.json`'da; AP, para ve süre sayıları GDD'de yok.
- **Kilitler:**
  - Ton Seçimi (Y2) ve Hedef Kitle Analizi (Y3) yapılana kadar ton ve kitle "otomatik": seçim kapalı, uyum nötr (0). KPI'da otomatik kitle yetişkin payı kadar geniş sayılır.
  - Medya Planlama (Y3) yapılana kadar tek kanal. Eski `mix.multi_from_game_year` kaldırıldı.
  - Dijital Departman (1998) yapılana kadar dijital ve sosyal kategorideki kanallar ve dijital departmandaki pozisyonlar kilitli.
  - CPA teklif modeli Performans Pazarlama (2010) ister.
- **Etkiler:**
  - Pazar Araştırması: Bilgi Defteri'nde ₺3.000 (1990) karşılığı bir sektörün bilinmeyen hedef ya da kitle hücresini açar.
  - Fokus Grup: sihirbazda kombinasyon uyumunu kaba olarak söyler (M ≥ 1.08 "çok beğendi", < 0.92 "ikna olmadı"). GDD "tahmini puan aralığı" diyor; puan emek ve faz dengesine de bağlı olduğundan yalnızca uyumu gösterdik.
  - Seri Kampanya (Y8): aynı müşteri ve aynı hedef cezası kalkar.
  - Sosyal Medya Yönetimi (2008): sosyal kanallarda etkileşim +%15. GDD'deki aylık retainer hizmeti M11'e kaldı.
  - Influencer Analitiği (2015): sahte takipçi oranı PR uzmanı olmadan görünür.
  - Kriz İletişimi (Y10): skandal açıklamasının başarı zarına +20. Olaylardaki ek seçenekler M7-C'de.
  - AI Atölyesi (2023): AI araçlarının yenilik bedeli yarıya iner.
- **Oyunda zaten başka yolla olanlar:** Büyük Kampanya ofis 3 ile açılıyor. Çift Hedef, Mega Kampanya, Kendi Prodüksiyon Evi, Kendi Medya Ajansı ve Global Ağ M11'e kaldı.
- **Yeni odalar:**
  - Ar-Ge lab: kurmak için ekipte Strateji Direktörü (planner, 3. unvan) gerekli.
  - Prodüksiyon stüdyosu: Ar-Ge lab ve bir Prodüktör gerekli; Prodüksiyon odağına +%10.
  - Aynı türden sözlük etkiler (ör. beyin fırtınası + stüdyo odak çarpanları) birleşir.

## K-066 · 2026-11-04 · Kabul · Uygulama kararı
**Konu:** Bilgi Defteri, hızlı başlangıç ve eski kayıtlarda araştırma.
**Karar:**
- **Bilgi Defteri:** Biten her kampanya kullandığı hücreleri deftere yazar: sektör × hedef, sektör × kitle, ton grubu × ton, kanal × hedef, kanal × kitle. Ekran şimdilik sektör × hedef ve sektör × kitle tablolarını gösteriyor. Rapor kaç yeni bilgi öğrenildiğini söylüyor.
- **Hızlı başlangıç:** Mutlak yıla bağlı araştırmalar (Dijital Departman 1998, Sosyal 2008, Performans 2010) başlangıç yılına kadar "dünyanın bildiği" sayılır, tamam başlar. Ajansın kendi gelişimi (ton, kitle, medya planlama…) yine araştırılır.
- **Eski kayıt** (araştırma alanı yok): o güne kadar koşulu tutan bütün araştırmalar tamam sayılır, eski oyun kilitlenmeden devam eder.
- **Denge (60×10):** bilgili bot 7.48 (önce 7.51), rastgele bot 6.30 (önce 6.23), rastgele bot ilk 3 yılda %30 iflas. Rastgele bot araştırma yapmadığı için tonu ve kitleyi yanlış seçemiyor (otomatik = nötr); iki bot arasındaki fark 1.18'e indi (M10 hedefi ≥ 2.5, A-005 notu).
- **Dosya bölme:** `simulation.gd` 400 satırın altına indi; kampanya kurulumu `CampaignStarter`'a taşındı.


## K-067 · 2026-11-04 · Kabul · Uygulama kararı (GDD 16 olay biçimi)
**Konu:** Olay sistemi (M7-C).
**Karar:**
- **Veri:** `data/events/<kategori>.json`; 7 kategori (müşteri, çalışan, prodüksiyon, kriz, fırsat, piyasa, ofis hayatı), toplam 83 olay. Biçim GDD 16'daki gibi: `conditions`, `chance`, `options` (`effects` ya da `check` + `success`/`fail`). Ek alanlar: `category`, `trigger`, `once`, `cooldown_weeks`, seçenekte `requires_research`.
- **Metinler** veriye yazılmaz, anahtardan türetilir: `EV_<ID>_T` (başlık), `EV_<ID>_X` (metin), `EV_<ID>_O<n>` (seçenek). Metinde `{client}`, `{employee}`, `{employee2}`, `{rival}`, `{campaign}` yer tutucuları kullanılır.
- **Tetikler ve sıklık:**
  - `weekly`, `production` (üretimdeki kampanya), `airing` (yayındaki kampanya): her hafta sonu genel bir kapıdan geçilirse (sırayla %10 / %6 / %8) uygun olaylardan biri gelir. `chance` olaylar arasında ağırlıktır.
  - İki olay arasında en az 3 hafta; aynı olay 3 yıl (144 hafta) tekrar gelmez.
  - `fixed`: ay başında, tarihi tutan olay kapısız gelir (dönem krizleri).
- **Karar beklerken oyun durur** (pitch sunumu gibi). Bot ve test modunda cevapsız olay bir hafta sonra ilk seçenekle kapanır; bu yüzden ilk seçenek her zaman "güvenli" seçenektir ve araştırma isteyemez.
- **Stat kontrolü:** Skandaldaki formülün aynısı: zar(0..100) + ajansın o stattaki en iyisi / 2 ≥ zorluk. Pencerede yaklaşık şans gösterilir (GDD'de yok; oyuncu riski görsün diye).
- **Kriz İletişimi:** Kriz olaylarında ek bir seçenek açar (★) ve stat kontrollerine +20 ekler.
- **Bağlam:** Kurucu "çalışan" olaylarına girmez, istifa edemez. Etkiler hedefini anahtar önekinden bulur (`client.`, `employee.`, `campaign.`…). Hedefi olmayan olay (ör. çalışan yokken zam talebi) gelmez.
- **Kampanyaya etkiler:** Üretimdekine teslim süresi, hata, kalite (tüm puanlar ×(1+x)). Yayındakine görülme çarpanı, memnuniyet (rapordaki memnuniyet dökümünde "Olaylar" kalemi) ve ek ödeme.
- **Para** 1990 ₺ cinsinden yazılır, enflasyonla ölçeklenir.

## K-068 · 2026-11-04 · Kabul · Uygulama kararı
**Konu:** Dönem krizleri, bitkiler ve yazılım sertifikası.
**Karar:**
- **Krizler:** 1994 Nisan (bütçe ×0.70, 12 ay), 2001 Şubat (×0.70, 12 ay), 2008 Ekim (×0.75, 12 ay), 2018 Ağustos kur şoku (×0.85, 9 ay). Bütçe çarpanı yeni brief'lerin ücretine ve medya bütçesine uygulanır.
- **Büyük Kapanma (Mart 2020, 9 ay):** bütçe ×0.85. Kategori başına görülme çarpanı: açık hava ×0.4, etkinlik ×0.15, sponsorluk ve gerilla ×0.5, dijital ×1.25, sosyal ×1.3.
- **Diğer piyasa olayları:**
  - Özel TV 1992 (yayın ×1.2, 2 yıl);
  - dot-com 2000 (dijital ×0.8);
  - Dünya Kupası 2002 (sponsorluk ×1.4);
  - sosyal ağ çılgınlığı 2008 (sosyal ×1.2);
  - kişisel veri kanunu 2016 (dijital ve sosyal maliyet ×1.1);
  - seçimler (açık hava maliyeti ×1.3, 2 ay);
  - 2000 paniği, para reformu 2005, yapay zekâ 2023.
  
  Çarpanlar GDD'de yok; kriz yılları ve "bütçeler düşer" (5, 13) GDD'den.
- **Bitkiler** (12.3):
  - Bütün bitkiler birlikte sulanır.
  - 3 hafta sulanmazsa "susadı", 5 haftada kurur. Kuru bitki ne konfor ne dekor çeşitliliği verir.
  - Ofis ekranında "Bitkileri sula" düğmesi var.
  - Ofis asistanı işe alınmışsa bitkileri o sular.
- **Yazılım sertifikası** (11.3): Çalışan başına, araç alanı başına bir kez. 1990 ₺3.000, 2 hafta, enerji −15.
  - Sertifikalı çalışanın o alandaki üretimi ×1.10.
  - Ajansın o alanda başlangıç aracı dışında bir aracı olmalı.
- **Denge (60×10, bilgili bot olaylara beklenen değerle karar verir):**
  - Bilgili bot ortalama 7.46 (önce 7.48). 10 yılda %3.3 iflas (önce %0); kriz yılı tek kişilik ajansı zorluyor.
  - Rastgele bot 6.29, ilk 3 yılda %30 iflas.
  - Plaza katı %63 Y10, ilk ödül %70 Y4.


## K-069 · 2026-11-04 · Kabul · Orgo kararı (M8 planı)
**Konu:** Sanat geçişi (GDD 21).
**Karar:**
- **Sistem + yedek:** Claude modelleri takan sistemi kurar; modelleri Orgo zamanla üretir. Model dosyası yoksa eşya gri kutu olarak çizilir, oyun hiçbir zaman bozulmaz. Bir modeli eklemek için doğru adlı `.glb`'yi doğru klasöre koymak yeterli (`art/pipeline.md`).
- **Modüler karakterler** (21.3): 3 temel gövde + saç + kıyafet + renk shader'ı (M8-B).
- M8 iki parça: **M8-A** model sistemi, sanat dosyaları, billboard ve posterler; **M8-B** karakterler ve animasyon.

## K-070 · 2026-11-04 · Kabul · Uygulama kararı
**Konu:** Model kaydı, sığdırma ve kampanya görselleri (M8-A).
**Karar:**
- **Yollar:** Satın alınan mobilyanın modeli `data/furniture.json` `model` alanında. Sabit eşyalar (masa, sandalye, tezgâh, toplantı masası, kanepe), bilgisayar kuşakları ve sokak eşyaları `data/models.json`'da. Hepsi `assets/models/` altına göre "klasör/ad.glb".
- **Sığdırma:** Model, eşyanın tabanına ve boyuna **orantılı** sığdırılır (en dar sınıra kadar), tabanı yere ve merkezi ortaya taşınır. Böylece santimetre ölçeğinde ya da kaymış bir model de doğru durur; ama ölçüye yakın üretmek oranları korur.
  - Yön kuralı: modelin önü +Z (Blender'da −Y).
- **Dönemsel bilgisayar:** Masadaki bilgisayar ajansın bilgisayar kuşağını gösterir (PC-386 → Elmacık G4 → iMak → M-çip Pro).
- **Kuru bitki:** Kahverengi kutu; modelse kahverengi yarı saydam katman.
- **Sokak:** Girişin önünde kaldırım ve yol; ağaç, lamba, bank; köşede billboard. Kamera artık binanın 6 m dışına kadar kaydırılabiliyor.
- **Kampanya görselleri** (21.4):
  - Görsel üç şablondan biri: marka rengi (marka adından), vurgu rengi, başlık, slogan (12 kalıp) ve marka. Aynı kampanya hep aynı görseli verir.
  - **Billboard:** yayındaki en yeni kampanya, yoksa en son biten; hiç iş yoksa "Bu alan kiralıktır".
  - **Posterler:** dış duvarların iç yüzünde en fazla 4. Önce ödüllü işler (altın çerçeve, ★), sonra en yüksek puanlılar. Kameraya bakan kesik duvarda gizlenir.
- **Araçlar:**
  - `tools/model_check.gd`: her yuvayı raporlar (yok / ✓ / ⚠ boy, taban, ortalama, üçgen; yanlış adlı dosyalar).
  - `tools/model_preview.tscn`: modeli oyundaki gibi sığdırıp 1 m'lik küpün yanında PNG'ye çizer.
  - `--samples`: Godot şekilleriyle kurulmuş deneme modelleri.
- **Ertelendi:**
  - Duvar ve zemin modelleri (şimdilik düz renk).
  - Pencere ve kapı parçaları.
  - Gece ışığı.


## K-071 · 2026-11-04 · Kabul · Uygulama kararı (GDD 21.3 modüler karakter)
**Konu:** Modüler karakterler ve animasyon (M8-B).
**Karar:**
- **Parçalar** (`data/characters.json`):
  - 3 gövde: kadın, erkek ve nötr. Kurucu ve cinsiyeti boş olanlar nötr gövdeyi alır.
  - 10 saç (biri "kel", modelsiz). 90'lara özel mullet, 2010+ için topuz.
  - 12 kıyafet; her birinin giyildiği yıllar var (90'lar vatkalı ceket, 2010'lar oduncu gömleği, 2020+ bol tişört…).
  - Validator her gövdeye her yıl (1990–2035) en az bir saç ve kıyafet düştüğünü denetler.
- **Görünüş çalışanın kimliğinden türetilir:** gövde, saç, kıyafet, ten, saç ve kıyafet rengi. Aynı çalışan hep aynı görünür. Dönem değişince kıyafeti de dönemin kıyafetlerinden birine geçer. Kurucu hardal renk giyer.
- **Renk:** Parçalar açık gri ya da beyaz üretilir. Oyun rengi yarı saydam bir renk katmanıyla verir (her kopyaya ayrı shader yerine, tek bir malzeme katmanı).
- **Bağlama:**
  - Deri taşıyan (skinned) parça gövdenin iskeletine taşınır, onunla bükülür.
  - Sert parça (saç) baş kemiğine (`mixamorig_Head`) bağlanır; kemiğin dinlenme konumu geri alınır ki tam gövdeye göre modellenen parça yerine otursun.
  - Godot kemik adındaki ":"yi kabul etmez; Mixamo'nun `mixamorig:Head` adı içe aktarılırken `mixamorig_Head` olur.
- **Animasyon:**
  - AnimationTree durum makinesi, 10 durum: idle, walk, sit, type, phone, coffee, present, cheer, stress, sleep. Her durumdan her duruma 0.25 sn geçiş. Gövdede olmayan klibin yerine en yakını oynar (type → sit → idle).
  - **Etkinlik seçimi:**
    - Yürürken walk.
    - Masada: kampanya ekibindeyse type; account, new business, PR ve medya departmanlarındaysa günlük %35 phone.
    - Enerjisi 15'in altındaysa sleep, tükenmişliği 60 ve üstündeyse stress.
    - Mutfakta coffee, toplantıda present, dinlenme köşesinde sit.
    - Seviye atlayınca 2.5 sn cheer.
- **Model yokken:** Kapsül yerine renkli gövde + ten rengi baş + saç kepi (kel değilse). Etkinlikler basit kod hareketleriyle oynar (sallanma, öne eğilme, zıplama…).
- **Ertelendi:** Yürüme hızının animasyonla eşlenmesi, yüz ifadeleri, aksesuarlar (gözlük, kulaklık).


## K-072 · 2026-11-04 · Kabul · Orgo kararı + uygulama (M9 planı; M9-A kayıt ve ayarlar)
**Konu:** Cila (GDD 20, 22, 24.5).
**Karar:**
- **M9 planı:**
  - Ses sistemi kodla üretilmiş basit yer tutucu seslerle başlar; Orgo'nun dosyaları onların yerine geçer (M9-B).
  - Tutorial, ilk 3 kampanya boyunca ipucu balonları olarak yapılır; atlanabilir ve ayarlardan yeniden açılabilir (M9-C).
- **Slotlar:** 3 elle kayıt + 1 otomatik kayıt.
  - Her slotun yanında küçük bir `.meta` dosyası var; yükleme ekranı ajans adını, tarihi, nakdi, çalışan sayısını ve kayıt zamanını dosyayı açmadan okur.
  - Kayıt önce geçici dosyaya yazılır, sonra eskisinin yerine konur.
  - M2'nin tek kaydı (`save_slot_1.sav`) olduğu gibi 1. slot.
- **Sürüm 3:** Kayda özet (`meta`) eklendi. `migrate_v2_to_v3` eski kayda özeti ekler. Bozuk dosya oyunu çökertmez: yükleme ekranı "okunamadı" gösterir, slotun yükle düğmesi kapanır.
- **Ajans adı:** Yeni oyunda verilir (boşsa "Ajansım"), kayıtta tutulur.
- **"Devam et"** en son kaydedilen slotu (otomatik dahil) açar.
- **Otomatik kayıt:**
  - Her ay başında yapılır, ayarlardan kapatılabilir.
  - Elle kayıt slotunu ve "kaydedilmedi" bilgisini değiştirmez. Otomatik kayıttan yüklenen oyun, elle kayıtta slot sordurur.
  - Yalnızca oyun saati çalışırken yapılır, böylece testler gerçek kaydın üstüne yazmaz.
- **Çıkış:** Son kayıttan beri oynanmışsa "Kaydet ve çık / Kaydetmeden çık / Vazgeç" sorulur (ana menüye dönerken ve pencere kapatılırken).
- **Ayarlar** (`user://settings.cfg`):
  - ses: genel, müzik, efekt ve ortam (ses kanalları M9-B'de);
  - dil (oyun içinde değişince ekran yeniden kurulur);
  - arayüz boyutu (%90–130, bütün arayüzü büyütür);
  - tam ekran ve pencere boyutu;
  - otomatik kayıt, ipuçları, "ipuçlarını baştan göster", günlük klasörü.
- **Kısayollar:** F5 hızlı kaydeder (slot yoksa sorar). Esc en üstteki kapatılabilir pencereyi, yoksa yan pencereyi kapatır. Olay ve pitch gibi karar pencereleri Esc ile kapanmaz.
- **Günlük:** Godot'nun dosya günlüğü açık: `user://logs/godot.log`, son 5 dosya.


## K-073 · 2026-11-04 · Kabul · Uygulama kararı (GDD 22 ses, 20 juice)
**Konu:** Ses, müzik ve arayüz geri bildirimi (M9-B).
**Karar:**
- **Kanallar:** Master'a bağlı Music, SFX ve Ambient kanalları oyun açılırken kodla kurulur. Ayarlardaki seviyeler bunlara uygulanır.
- **Efektler** (`data/sounds.json`):
  - Her efektin adı ve bir yer tutucu tarifi var (dalga, frekans, süre, ses, zarf); oyun bundan 16 bit mono WAV üretir.
  - `assets/audio/sfx/<ad>.(ogg|wav|mp3)` varsa dosya kullanılır.
  - Dalgalar: sine, square, triangle, noise; alkış için crackle, klavye için typing.
- **Dönemsel sesler:**
  - Bildirim: 1990 çağrı cihazı, 1998 SMS, 2008 "ding", 2020 yumuşak.
  - Yeni brief: 1990 faks, 2000 e-posta.
- **Ne zaman çalar:**
  - Her düğme tık sesi çıkarır.
  - Bildirimler türüne (iyi, bilgi, kötü) ya da anahtarına göre çalar. Yeni brief, kayıt, araştırma bitti ve seviye atlama için özel sesler var.
  - Kampanya raporunda 8 ve üzeri puana "cheer", altına "report" çalar.
  - Ödül töreninde alkış, olay penceresinde "event" çalar.
- **Müzik:** Dönemin klasöründeki parçalar karışık sırayla çalar. Parça bitince 4 sn ara, sonra yeni parça 2.5 sn'lik geçişle başlar. Dönem değişince müzik yeni döneme geçer. Klasör boşsa kökteki parçalar, o da boşsa sessizlik.
- **Ofis ortamı:** Klavye uğultusu döngüsü; seviyesi çalışan sayısı / 20 (en fazla 1). Oyun durunca %30'a iner, oyun yokken susar.
- **Juice:**
  - Nakit değişimi 1990 ₺1.000'i (enflasyonla) geçerse üst çubukta "+₺…/−₺…" uçar; artışta ka-ching.
  - Bildirimler belirerek ve kayarak gelir.
  - Raporda puan zaten sayarak yükseliyordu; 8 ve üzerinde konfeti eklendi.
  - Düğmeler üzerine gelince %4 büyür.
- **Araç:** `tools/export_sounds.gd` yer tutucu sesleri dinlemek için `.wav` olarak dışa aktarır.
- **Ertelendi:** "Ofis radyosu" objesiyle müzik değiştirme (GDD 22), sesin ofisteki konumdan gelmesi (3D ses).


## K-074 · 2026-11-04 · Kabul · Uygulama kararı (M9-C: tutorial, İngilizce, performans)
**Konu:** İpucu balonları, çeviri bütünlüğü, performans ölçümü.
**Karar:**
- **İpuçları** (`data/tutorial.json`, 11 balon):
  - Hoş geldin, ilk brief, sihirbaz, faz kaydırıcıları, teslim, rapor, işe alım, kayıt, Ar-Ge, ofis, olay.
  - Doğru anda çıkarlar (oyun başı, yeni brief, faz başı, teslim, bir pencere açılınca ya da durum koşulu tutunca). İlgili düğmeyi hardal çerçeveyle gösterirler.
  - Oyunu durdurmazlar. Aynı anda tek balon görünür, diğerleri sıraya girer. Görülen balon bir daha çıkmaz.
  - "İpuçlarını kapat" hepsini kapatır; Ayarlar'dan yeniden açılır ya da baştan gösterilir.
  - Erken ipuçları ilk 3 kampanyayla sınırlı; Ar-Ge, ofis ve olay ipuçları her zaman geçerli.
- **Üst çubuk:** Kaydet, Yükle, Ayarlar ve Ana Menü tek bir "Menü ▾" düğmesinde. İngilizce metinlerle çubuk taşıyor, bildirim sütununu ekran dışına itiyordu.
- **Yüzde biçimi** dile göre: Türkçe "%55", İngilizce "55%" (`UiUtil.percent`). Koda sabitlenmiş Türkçe biçimler bununla değişti.
- **Çeviri denetimi** (test):
  - Her satırda iki dil dolu.
  - Biçim işaretleri (`%s`, `%d`…) iki dilde aynı sayıda.
  - Koddaki her `tr("ANAHTAR")` CSV'de var.
  - Aynı kalan satırlar özel ad ya da sektör terimi (Billboard, Copywriter, parodi marka adları).
- **Ekran turu** `--lang=en` ile İngilizce çalışıyor (taşan metin kontrolü).
- **Performans** (`tools/perf_check.tscn`, en büyük ofis, 4x hız, bu makine RTX 3060 Ti):

  | Durum | Ortalama | %95 | %99 | En kötü |
  |---|---|---|---|---|
  | 60 çalışan, gri kutu | 545 FPS (1.83 ms) | 2.08 ms | 2.78 ms | 5.5 ms |
  | 60 çalışan, deneme modelleri | 511 FPS | 2.38 ms | 3.03 ms | 79 ms (tek seferlik) |
  | 120 çalışan, deneme modelleri | 285 FPS | 4.17 ms | 5.10 ms | 9.3 ms |

  - Hedef (60 çalışanla 60 FPS) rahat tutuyor; optimizasyon gerekmedi.
  - Tek seferlik büyük kareler, malzemelerin ilk çizimdeki derlenmesi ya da ilk otomatik kaydın diske yazılmasıyla ilişkili görünüyor. Otomatik kayıt yalnızca ~2 ms sürüyor.
  - Çizim çağrısı 850–1500: her eşya ayrı kutu ya da model.
- **M10'a not:** Zayıf bir makinede (entegre grafik) tekrar ölçülecek. Gerekirse aynı eşyalar MultiMesh ile toplanır, uzaktaki karakterler sadeleşir.


## K-075 · 2026-11-04 · Kabul · Orgo kararı + uygulama (M10 planı; banka kredisi)
**Konu:** M10 planı ve banka kredisi (GDD 13.5).
**Karar:**
- **M10 planı:**
  - Basit banka kredisi eklenir.
  - Demo 1998 sonunda özet ve istek listesi ekranıyla biter (M10-B).
  - Denge değişiklikleri önce öneri olarak sunulur, Orgo onaylayınca uygulanır.
- **Kredi** (`loans`):
  - Üst sınır = ofis tabanı (1990 ₺ 20 bin / 60 bin / 200 bin / 600 bin / 1.5 milyon) × enflasyon × (0.5 + itibar/100).
  - Yıllık %24 faiz, eşit aylık taksit (anüite). Vade 6, 12 ya da 24 ay.
  - Aynı anda tek kredi; erken kapatma bedeli %2.
  - Faiz gider sayılır (vergiden düşer), anapara sayılmaz.
  - Nakit eksiye düştüğü ilk hafta, kredi yoksa "kredi çekebilirsin" bildirimi gelir.
  - Teminat (GDD 13.5) yok, sadeleştirme.
- **Bilgili bot** kırmızıya düşünce sınırın yarısı kadar, 12 aylık kredi çeker. 40 koşuluk karşılaştırmada iflas ve puan farkı yok (%5, 7.45 ve 7.46).

## K-076 · 2026-11-04 · Kabul · Uygulama kararı (GDD 27 denge altyapısı)
**Konu:** Dört bot, denge raporu ve öneri kolları.
**Karar:**
- **Botlar:**
  - Tekrarcı: bilgili gibi oynar, ilk bulduğu kitle, ton ve kanalı hep tekrarlar.
  - Açgözlü: nakde bakmadan işe alır ve taşınır, her işi alır, nakit azalınca en büyük krediyi çeker.
- `balance_sim` `--bots`, `--json` ve `--set=data:…` (ofis, ödül gibi diğer veriler) alıyor. `balance_report` JSON'ları birleştirip `docs/balance-report.md` yazıyor, GDD 27.2 hedefleriyle ✓/✗ karşılaştırıyor.
- **Etkisiz başlayan iki yeni ayar** (değerleri Orgo onaylarsa M10-B'de):
  - `novelty.same_channel_streak` (1.0): aynı ana kanal son iki kampanyada kullanıldıysa N çarpanı. GDD 7.8'e ek bir kural.
  - `awards.min_reputation` (0): ödüle başvurmak için en az itibar.
- **Değişiklik öncesi sonuç** (1000 koşu × 10 yıl, 200 koşu × 30 yıl):
  - Hedefi tutanlar: rastgele bot ilk 3 yılda %25.6 iflas, küçük ofis Y3, plaza katı Y16, bilgili bot ortalama 7.48, uyum çarpanı ortalaması 0.956 (%22.7'si 0.85'in altında).
  - Tutmayanlar: tekrarcı farkı 0.42, rastgele farkı 1.20, ilk ödül Y4, yıl süresi 2.4 dk (K-034 ile bilinçli).
  - Açgözlü bot ilk 3 yılda %44, 10 yılda %73 iflas.
  - 30 yılda puan 21. yıldan sonra düşüyor (Y30 3.38).
- Öneriler ve deneme sonuçları: `docs/balance-report.md` → "Öneriler".


## K-077 · 2026-11-05 · Kabul · Orgo kararı + uygulama (görsel yenileme planı; G1 ışık ve atmosfer)
**Konu:** Leafy Corner referanslı görsel yenileme (`docs/art-direction.md`).
**Karar:**
- **Sıra:** G1 ışık ve atmosfer → G2 UI kiti → G3 Blender ile basit objeler. M10 denge önerileri (Ö1–Ö5) bu sırada bekliyor.
- **Görünüş ayarları veri dosyasında:** `data/look.json` (ortam, güneş, dolgu ışığı, kamera, vinyet, duvarlar, zeminler, oda duvar renkleri, çimen). Kod `src/world/world_look.gd`.
- **Işık:**
  - ACES ton eşleme (pozlama 0.92), SSAO (yoğunluk 3.2), SSIL, glow (soft light).
  - Sıcak güneş (enerji 1.7, −44°) ve gölgesiz soğuk dolgu ışığı.
  - Gölge atlası 8192, yumuşak filtre en yüksek kalite. Basamaklı gölge kenarları bununla gitti.
- **Kamera:** −50° bakış, 30° görüş açısı. Uzak alan derinliği kamera mesafesine göre güncellenir (tilt-shift). 3D görüntünün üstünde hafif vinyet.
- **Duvarlar:**
  - Kesik duvar 0.65 m (önce 0.35 m).
  - Her duvar parçasının üstünde yuvarlak uçlu ahşap pervaz var; kesilince duvarla birlikte iner.
  - Bina köşeleri 0.5 m yarıçaplı, 6 parçalı çeyrek yaylarla döner.
  - Dış duvarın iç rengi yanındaki odanın türünden gelir (çalışma alanı adaçayı, lounge terrakota, toplantı krem…).
- **Zeminler:** Kodla üretilen desen dokuları, dünya koordinatına göre: tahta (parke), karo, halı, beton. Çimen dikişsiz gürültü dokusu (FastNoiseLite).
- **Araç:** `tools/screenshot.tscn`. Sabit tohumlu örnek ajans (2005, ofis 2, 7 çalışan); 3 dünya açısı ve 2 arayüz görüntüsü `docs/screenshots/` altına. Depoda yalnızca "önce" (00) ve son (01_g1) görüntüleri tutulur.
- **Referansla kalan farklar (sonraki adımlar):**
  - Eşyalar hâlâ renkli kutu (G3 ve modeller).
  - Çevrede bina cephesi, çit, çiçek yok.
  - Duvar kâğıdı deseni yok.
  - Ana ekranda 3D, iki yan panelin arasına sıkışık; referanstaki gibi tam ekran ofis ve üstünde yüzen arayüz G2'de.

## K-078 · 2026-11-05 · Kabul · Orgo kararı + uygulama (G2 UI kiti)
**Konu:** Arayüzün şekil dili, fontlar, ikonlar ve ana ekran yerleşimi (`docs/art-direction.md` 8–10).
**Karar:**
- **Tema kodla üretilir:** `src/ui/theme/ui_theme.gd` (`UiTheme`) renkleri ve stilleri tanımlar. `tools/build_theme.gd` bunu proje teması `src/ui/theme/main_theme.tres` olarak kaydeder. Renk ya da ölçü değişince bu araç yeniden çalıştırılır; `.tres` elle düzenlenmez.
- **Palet:** adaçayı-krem paneller (#CDE8C7 / #E4F3DF), koyu yeşil çerçeve (#3F6B52), hap düğmeler: kabul yeşil, bekle gri, reddet kırmızı. Para rozeti altın, itibar rozeti yeşil.
- **Şekil:** büyük yarıçaplı (22), kalın çerçeveli, gölgeli paneller. İç içe kalın çerçeve olmasın diye liste kartları çerçevesiz açık zemin (`CardLight`); çerçeveli panel yalnız dış pencerede (`UiUtil.panel()`).
- **Fontlar:** başlıklar Fredoka, gövde Nunito (ikisi de OFL, `assets/fonts/`). Değişken fontlar `FontVariation` ile kalınlaştırılır.
- **İkonlar:** Tabler Icons (MIT), `assets/icons/ui/*.svg`. Çalışırken `Image.load_svg_from_string` ile istenen boyutta çizilir ve önbelleğe alınır; bu yüzden **Windows dışa aktarımında `*.svg` dosyaları "dahil edilecek dosyalar" filtresine eklenmeli** (M10-C).
- **Ana ekran:** 3D ofis tam ekran. Sol: dikey ikon çubuğu (kırmızı noktalı sayaçlar). Sol alt: kaydet, yükle, ayarlar, ana menü. Sağ üst: para ve itibar rozetleri, altında solan bildirim kartları (en fazla 4, 7 sn). Sağ alt: tarih hapı ve hız grubu. Ekranlar sol tarafta yüzen pencerede açılır, sağ üst köşesinde kırmızı kapatma düğmesi var. İnşa çubuğu alt HUD'un üstünde, tam genişlikte.
- **Animasyon:** pencereler 0.25 sn'de ölçek 0.86→1 ve saydamlıkla açılır (`UiUtil.pop_in`); para ve itibar eski değerden yenisine sayar, daire bir kez nabız atar (`CountBadge`); para değişimi rozetin solunda beyaz yazı + renkli konturla yukarı süzülür.
- **Vitrin:** `tools/ui_kit_demo.tscn` bütün bileşenleri tek ekranda gösterir.

## K-079 · 2026-11-05 · Kabul · Orgo kararı + uygulama (G3 Blender betikleri)
**Konu:** Basit eşyaları Blender Python betikleriyle üretmek (`docs/art-direction.md` 7).
**Karar:**
- **Araç:** Orgo'nun Steam'deki Blender 5.2.3 kurulumu (`C:/Program Files (x86)/Steam/steamapps/common/Blender`). Betikler `tools/blender/`; yalnızca `bpy` ve `bmesh` kullanır, Blender 4.x'te de çalışır.
- **Tek malzeme, palet atlası:** `assets/textures/palette.png` (256×256, 16×16 kare). Her parçanın UV'si kendi renk karesinin ortasına eşlenir; doku "en yakın piksel" okunur. Renk sırası sabittir (yeni renk sona).
- **Şekil:** her kutu ve silindirin keskin kenarları 1–2.5 cm, 1–3 segmentli bevel ile yuvarlanır; yaprak kümeleri düzensiz ikosferler. Yumuşak gölgelendirme, 50°'den keskin kenarlar korunur.
- **Üretilen modeller:**
  - `props/desk`: sağda çekmeceli dolap, çekmeceler oturana bakar.
  - `furniture/bookshelf`: tohumlu rastgele kitaplar, saksı ve vazo.
  - `furniture/plant_small` ve `plant_big`, ayrıca `decor/plant_medium`.
  - `decor/hex_shelf`: altıgen petek raf.
  - `decor/wall_panel`: çıtalı akustik panel.
- **Duvar süsleri (yeni, `data/models.json` `decor` ve `wall_decor`):**
  - En uzun dış duvarlarda (≥ 4 m), posterin bulunduğu duvar ortasından uzunluğun %30'u kadar yana, sırayla altıgen raf ve panel asılır (en fazla 4).
  - Önünde 1 m'den uzun bir eşya varsa o duvar atlanır.
  - Kameraya bakan kesik duvarda posterler gibi gizlenir.
- **Orta boy saksı** (`decor/plant_medium`) şimdilik oyunda kullanılmıyor. Satın alınabilir yeni bir mobilya olması fiyat ve konfor dengesi gerektirdiği için Orgo'nun kararını bekliyor.
- **Model denetimi düzeltmesi:** `tools/model_check.gd`, gerçek bir model bulunca `ModelLibrary`'nin autoload bağımlılığı yüzünden betik hatası verip yine de "sorunsuz" yazıyordu. Ölçüm fonksiyonları bağımlılıksız `MeshBounds` sınıfına taşındı.
- **Ön yüz kuralı:** Blender'da −Y, Godot'da +Z. Duvar süslerinin arkası +Y (duvara).

## K-080 · 2026-11-05 · Kabul · Orgo kararı ("Daha çok model") + uygulama
**Konu:** Karakterler dışındaki bütün model yuvalarını Blender betikleriyle doldurmak.
**Karar:**
- **22 yeni model; karakterler dışındaki 29 yuvanın hepsi dolu:**
  - Sabit eşyalar (`tools/blender/models_props.py`): sandalye, mutfak tezgâhı, toplantı masası, kanepe.
  - Dönemsel bilgisayarlar (aynı dosya): pc386, g4, imak, mchip.
  - Satın alınan mobilya (`tools/blender/models_furniture.py`): semaver, filtre kahve, espresso, su sebili, beyaz tahta, ilham panosu, pikap, ödül dolabı, neon tabela, ofis kedisi.
  - Sokak (aynı dosya): ağaç, lamba, bank, billboard.
- **Palet:** 12 renk sona eklendi (neon pembe, çelik, bej PC, camgöbeği, kırık beyaz, ekran, ekran ışığı, kedi turuncusu, mantar, su mavisi, kırmızı, lamba yeşili). Eski renklerin yeri değişmedi.
- **Tezgâh boyu 0.95 → 1.2 m** (`data/models.json`): Model, tezgâh üstündeki musluk ve kettle ile 1.2 m. Boy 0.95 kalsaydı oyun modeli orantılı küçültürdü. Bu boy yalnızca görünüş için; simülasyonu etkilemez.
- **Billboard:** Panel 3.6 × 2.0 m, alt kenarı 1.4 m (`street_layout`). Panel yüzü, oyunun kampanya görselini koyduğu düzlemin (merkezden 5 cm önde) gerisinde kalır.
- **Yazı ve logo yok** (style_bible 5): Beyaz tahtadaki karalamalar ve neon tabela yalnızca şekil.
- **Ödül dolabı öne açık vitrin.** Tek malzeme saydamlık desteklemiyor; cam yok.
- **Performans:** 60 çalışanlı ofiste kare ortalaması 1.76 ms (567 FPS), hedef 16.7 ms.
- **Test:** Karakterler dışındaki her yuvada model bulunmalı ve denetimden geçmeli (`test_models`).

## K-081 · 2026-11-05 · Kabul · Orgo kararı ("Onayla, C1'le başla") + uygulama
**Konu:** Karakterleri Mixamo/AI yerine Blender betikleriyle üretmek; ilk adım (C1) iskelet, 3 gövde ve temel hareketler.
**Karar:**
- **Kendi iskeletimiz** (`tools/blender/characters.py`): 17 kemik (`hips`, `spine`, `chest`, `neck`, `head`, kollar `upper_arm_l/forearm_l/hand_l`, bacaklar `thigh_l/shin_l/foot_l`, sağ taraf `_r`). `data/characters.json` `head_bone` `mixamorig_Head` → `head`.
- **Üç gövde aynı iskeleti ve aynı kol/bacak ölçülerini kullanır;** yalnızca omuz, bel, kalça ve göğüs derinliği değişir. Her saç ve kıyafet üç gövdeye de oturur, tek animasyon seti hepsinde çalışır.
- **Bağlama:** Gövde (kasıktan boyna) tek parça halkalarla örülür ve kalça → bel → göğüs kemiklerine yüksekliğe göre yumuşak dağılır. Kol ve bacak parçaları tek kemiğe sert bağlıdır; dirsek, diz ve omuzdaki toplar bükülmede boşluğu kapatır.
- **Renk:** Modelde `skin`, `outfit`, `hair` adlı beyaz malzemeler var; `CharacterRig._paint` bunların rengini çalışana göre değiştirir. Aynı renk ve malzeme bir kez üretilip paylaşılır. Eski yarı saydam katman yalnızca adlı malzemesi olmayan modellerde (ör. deneme modelleri) kalır; katman ışığı düzleştirdiği için gerçek modelde soluk görünürdü.
- **Gövdede temel giyim:** tişört (kıyafet rengi), kot pantolon ve ayakkabı (palete `denim` eklendi). C3'teki kıyafetler bunun üstüne giyilecek.
- **Hareketler (C1):** `idle` (2 sn), `walk` (0.67 sn; 1.6 m/sn yürüyüşe göre iki adım), `sit` (kalça 0.56 m'ye iner). Her klip bütün kemikleri anahtarlar ki klipler birbirine sızmasın. Kalan 8 hareket C2'de; o zamana kadar `CharacterRig.clip_for` en yakınını oynatır (`type` → `sit` gibi).
- **Saç:** C1'de yalnızca `hair_short`; diğer saçların modeli olmadığı için o çalışanlar şimdilik kel görünür (C3).
- **Kurucunun tacı** yalnızca kapsülde kaldı; modelde kurucuyu hardal kıyafet rengi ayırt eder.
- **Hata düzeltmesi (M8'den):** `CharacterLook` saç, kıyafet ve renkleri `hash / 7`, `/13`, `/17`, `/19` ile seçiyordu. Ardışık kimlikler (em_0001, em_0002…) ardışık özet verdiği için herkes aynı rengi ve teni alıyordu. Artık her seçim için sayı karıştırılıyor (`_mix`). Kayıtlı oyunlardaki çalışanların görünüşü bir kez değişir; oyuna etkisi yok.
- **Performans:** 60 çalışanla kare ortalaması 1.94 ms (516 FPS). Karakter başına ~2.500 üçgen (sınır 15.000).
- **Test:** Gerçek gövde modeli çalışanın ten ve kıyafet rengini alıyor; ardışık kimlikler farklı görünüyor (`test_characters`). Kapsül testi artık var olmayan bir gövde yolu kullanıyor.

## K-082 · 2026-11-05 · Kabul · Orgo kararı ("Uygun, C2'ye geç") + uygulama
**Konu:** Kalan karakter hareketleri (C2).
**Karar:**
- **7 yeni klip** (`tools/blender/characters_anim.py`; mesh betiği `characters.py` 400 satırı geçmesin diye ayrıldı):
  - `type` (0.5 sn): öne eğik, eller klavyede sırayla iner kalkar.
  - `phone` (3 sn): sağ el kulakta, sol el konuşurken sallanır.
  - `coffee` (4 sn, ayakta): kupa göğüs hizasında, ara ara yudum.
  - `present` (3 sn, oturarak): eller açık anlatır, baş toplantıdakilere döner.
  - `cheer` / `cheer_stand` (2.5 sn, döngüsüz): kollar havada yumruk sallar.
  - `stress` (1.5 sn): eller başın iki yanında, baş sallanır.
  - `sleep` (4 sn): baş göğse düşer, yavaş nefes.
- **Oturan / ayakta:** Ofiste sunum toplantı masasında oturarak yapılıyor (`OfficeWorld._go`: yalnız mutfakta ayakta). Bu yüzden `present` oturarak, `coffee` ayakta.
- **Yeni klip `cheer_stand`:** Sevinç her yerde tetiklenebiliyor (seviye atlama). Oturan sevinci ayaktaki karaktere oynatılırsa çömelmiş görünürdü. `OfficeCharacter` oturuyorsa `cheer`, ayaktaysa `cheer_stand` ister. Klip yoksa `CharacterRig.clip_for` `cheer`'e düşer. `data/characters.json` `animations` listesine eklendi.
- **Eldeki eşyalar:** Telefon ve kupa, sağ ele bağlı `prop_phone` ve `prop_cup` kemiklerine bağlı gövde parçaları. Kendi klibi dışındaki her klipte kemik ölçeği 0.001 olduğu için görünmezler. Ayrı model ya da kod gerekmedi.
- **Eli hedefe götürmek:** Eller elle açı yazılarak değil, iki kemikli bir uzanma hesabıyla (`_reach`) klavyeye, kulağa, ağza ya da başa götürülür. Gövde eğilse de el hedefte kalır.
- **Oturuş düzeltmesi:** Kalça 0.11 m öne alındı (`SIT_HIPS` y +0.03 → −0.08). Sandalye oturma noktasından 0.1 m masaya yakın durduğu için karakter minderin arka kenarındaydı; şimdi ortada, elleri masaya yetişiyor.
- **Araç:** `tools/pose_sheet.tscn` her klibi masa ve sandalyeyle önden ve yandan çeker; iki özet sayfa yazar.
- **Performans:** 60 çalışanla kare ortalaması 2.33 ms (429 FPS). Karakter ~2.770 üçgen.
- **Test:** Gerçek gövdede `animations` listesindeki her hareketin kendi klibi var (`test_characters`).

## K-083 · 2026-11-05 · Kabul · Orgo kararı ("Evet, C3'e geç") + uygulama
**Konu:** Saçlar ve dönemsel kıyafetler (C3).
**Karar:**
- **9 saç** (`tools/blender/characters_wear.py`): short, buzz, side_part, bob, long, bun, curly, mullet, man_bun. Başa oturan sert parçalar; hepsi `hair` malzemesinde, rengini oyun verir. Topuz lastiği paletten sabit (terrakota).
- **12 kıyafet, tişörtün üstüne giyilen kabuk:** Kabuk gövdenin aynı halkalarından biraz şişirilerek örülür ve gövdeyle aynı ağırlıklarla bükülür; tişörtü tamamen örter.
  - Kumaş `outfit` malzemesinde, çalışanın kıyafet rengini alır.
  - Ayrıntılar paletten sabit: iç gömlek şeridi, yaka, düğme, kravat, cep.
  - Yeleklerin (sweater_vest, tech_vest) altındaki gömlek de sabit renkte, beyaz ya da açık mavi. Kumaş rengi yalnızca yeleğe gelir; böylece katmanlar ayırt edilir.
- **Her gövdeye ayrı kabuk, tek dosyada:** Nesne adları `outfit_<ad>_<gövde>`. `CharacterRig._for_body` adında başka bir gövdenin eki olan parçaları atlar. Ek olmayan parçalar herkese giydirilir; bu, elle yapılmış modellerle de uyumlu. Hangi gövdelere kabuk yapılacağı `data/characters.json` `outfits[].bodies` alanından okunur. Tek kabukla dar gövdeli kadın modeli bol görünürdü.
- **Elbise:** Etek bel hizasından dize iner; alt kısmı uyluk kemiklerine geçer, oturunca bacaklarla birlikte öne katlanır. Kotu örtmek için bacaklara ten renkli (`skin`) kılıf giydirildi.
- **Takım elbise:** Ceketle aynı renkte pantolon kılıfı kotu örter.
- **Ekose (hipster_flannel):** Boyanan kumaşa desen çizilemediği için koyu yatay şeritler ve kol bantlarıyla ima edilir.
- **Araç:** `tools/wardrobe.tscn` her kıyafeti farklı saç ve gövdeyle giydirip tek karede çeker (`--act=type` gibi).
- **Performans:** 60 çalışanla kare ortalaması 2.96 ms (338 FPS). Çizim çağrısı 470'ten 622'ye çıktı; giyinik karakter başına ~3.000–4.500 üçgen (sınır 15.000).
- **Test:** Bütün model yuvaları (karakterler dahil, 53) depoda ve denetimden geçiyor. Kıyafet dosyasından yalnızca çalışanın gövdesinin kabuğu giydiriliyor, kabuk gövdeyle bükülüyor ve saç başa bağlı.

---

## M5 denge sonucu (M5-A + M5-B)

| Bot | İflas ilk 3 yıl | İflas 10 yıl | Ort. puan (10 yıl) | Büyütülmüş ofis | İlk ödül | Pitch/koşu, kazanma |
|---|---|---|---|---|---|---|
| Rastgele (200×10) | %35.0 ✓ | %65.5 | 5.74 | %1 | %2 | 0.7, %43 |
| Bilgili (200×10) | %1.0 | %6.0 | 6.95 (hedef 7.0–8.5, sınırda) | %58, Y9 | %70, Y4 | 3.9, %52 |
| Bilgili (50×30) | %0 | %6 (30 yıl) | 5.05 (30 yıl) | %96, Y10 | %96, Y5 ✓ | 15.0, %30 |

İtibar (bilgili, 30 yıl): Y5 19.9 → Y10 24.4 → Y13 23.3 → Y16 15.6 → Y20 5.5 → Y25 0.3. Ödüller ve pitch ilk 13 yılda itibarı taşıyor. 15. yıldan sonra kişi başı üretkenlik dönem tabanına yetişemiyor; puanlar düşüyor, kötü puanlar ve müşteri kayıpları itibarı eritiyor. Plaza katı (itibar 40) bu yüzden açılmıyor. Kök neden M5 değil, A-014.

---

## M5-A denge sonucu (200 koşu × 10 yıl)

| Bot | İflas ilk 3 yıl | İflas 10 yıl | Ort. puan | Küçük ofis | İlk ödül (bronz+) | Ödül/koşu | İtibar Y5 / Y10 |
|---|---|---|---|---|---|---|---|
| Rastgele | %35.5 ✓ | %73.5 | 5.89 | %72, Y5 | %2 | 0.0 | 3.3 / 1.5 |
| Bilgili | %1.0 | %5.0 | 7.11 ✓ | %99, Y3 ✓ | %67, Y4 (hedef Y5–Y8) | 1.2 | 20.0 / 22.9 |

Bilgili botun itibarı 30 yıllık koşuda 13. yılda ~28'e çıkıyor, sonra düşen puanlarla geriliyor. Plaza katı (40) hâlâ açılmıyor. M5-B'de pitch kazanmak itibar ekleyecek; sonra yeniden ölçülecek (A-014).

---

## Denge adımı sonucu (K-047..K-050)

| Bot | İflas ilk 3 yıl | İflas 10 yıl | Ort. puan (10 yıl) | Küçük ofis | Büyütülmüş ofis |
|---|---|---|---|---|---|
| Rastgele (200×10) | %22.0 ✓ | %48.0 | 5.92 | %82, Y4 | %4 |
| Bilgili (200×10) | %2.0 | %6.0 | **7.11 ✓** | %99, **Y3 ✓** | %38 (10 yılda) |
| Bilgili (50×30) | %2.0 | %6 (30 yıl) | 5.25 (30 yıl) | Y3 | %94, Y11 |

Bilgili bot, 30 yıllık koşu: puan Y4 7.7 → Y13 6.6 → Y22 3.95 → Y28 2.4 (önce: Y13 4.2, Y22 1.7, Y28 1.0). Ekip Y13'te 11, sonra 12'de kalıyor. Çöküş ertelendi ama bitmedi: plaza katı (seviye 4) hiç açılmıyor, çünkü itibar en fazla ~15'e çıkıyor. İtibarı 40'a taşıyacak ödül, pitch ve basın M5'te gelecek. İtibar engeli kaldırılarak yapılan denemede bile plaza katı Y25'te açılıyor, %55 iflas oluyor (kira yükü). Bkz. A-014.

---

## M4-B denge sonucu (200 koşu × 10 yıl)

| Bot | İflas ilk 3 yıl | İflas 10 yıl | Ort. puan | Kampanya/koşu | Küçük ofis |
|---|---|---|---|---|---|
| Rastgele | %38.0 ✓ | %70.0 | 5.51 | 21.8 | %60 koşu, medyan Y4 |
| Bilgili | %1.5 | %7.0 | 6.46 | 55.3 | %99 koşu, medyan Y4 |

**30 yıllık koşu (50 koşu):** Y20'den sonra iki botun ortalama puanı da 1–2'ye çöküyor. Bilgili bot büyütülmüş ofise (₺3M × enflasyon) hiç çıkamıyor, ekip 6 kişide kalıyor. Dönem beklentisi ise 30 yılda ×11 büyüyor (7.9). Bkz. A-014.

---

## M4-A denge sonucu (200 koşu × 10 yıl)

| Bot | İflas ilk 3 yıl | İflas 10 yıl | Ort. puan | Kampanya/koşu | Küçük ofis |
|---|---|---|---|---|---|
| Rastgele | %38.5 ✓ | %71.5 | 5.51 | 21.7 | %59 koşu, medyan Y5 |
| Bilgili | %1.5 | %6.5 | 6.45 | 56.1 | %99 koşu, medyan Y4 |

Rastgele botun iflası ilk kez GDD hedefinde (%20–40; A-012 ilerledi). Küçük ofis Y4 (hedef Y2–Y3) ve uzun vadede düşen puanlar (A-011) açık.

---

## M3 denge sonucu (200 koşu × 10 yıl)

| Bot | İflas ilk 3 yıl | İflas 10 yıl | Ort. puan | Kampanya/koşu | Küçük ofis |
|---|---|---|---|---|---|
| Rastgele | %45.5 | %77.0 | 5.52 | 19.8 | %52 koşu, medyan Y5 |
| Bilgili | %1.0 | %10.0 | 6.51 | 54.6 | %98 koşu, medyan Y5 |

Bilgili bot: puan Y2 7.79 → Y5 6.96 → Y10 5.04; ekip Y5'te 3.6, Y10'da 5.8 kişi. Açık konular: A-011, A-012, A-013.

---

## M1 denge sonucu (200 koşu × 10 yıl, `tools/balance_sim.gd`)

| Bot | İflas ilk 3 yıl | İflas 10 yıl | Ort. puan | Kampanya/koşu |
|---|---|---|---|---|
| Rastgele | %41.0 | %58.5 | 5.09 | 23.1 |
| Bilgili | %0.0 | %0.0 | 6.60 | 54.2 |

Bilgili bot yıllık ortalama puan: Y1 7.89 → Y5 6.64 → Y10 5.88. Rastgele: Y1 5.62 → Y10 4.23.
**M1 kabulü:** puan farkı **1.51** (hedef ≥ 2) ✗ · rastgele bot iflası **%41** (hedef %20–40, sınırda) ✗. Ayrıntı ve seçenekler: A-005, A-007.

---

## Açık sorular (ilgili kilometre taşında sorulacak)

- **A-005:** Kapandı, bkz. K-034 (M10'da 27.2 hedefleriyle tekrar bakılacak).
- **A-006:** Kapandı: büyütülmüş ofis koşulu 17'deki gibi Y8 A6 (`data/offices.json`).
- **A-007 (M2/M3):** S/K oranı tek kişilik ajansta yapısal olarak ≥ ~1 çıkıyor, çünkü Strateji fazının bütün üretimi S'ye gidiyor. İdeal oranı 1'in altında olan hedefler (Bilinirlik 0.6, Yenileme 0.5, SSR 0.8, Etkileşim 0.9) her zaman B cezası alıyor. Ekip kurulunca (M3) kreatif ağırlıklı ekip bunu çözer; ya da faz sürelerinin oyuncuya bırakılması düşünülebilir. M3 notu: artık kreatif ağırlıklı ekip (copywriter/art director) K'yi artırıp oranı düşürebiliyor.
- **A-008 (M4):** 7.3 "Display + Retargeting" sinerjisi: kanal tablosunda "retargeting" kanalı yok (5.2'de özellik olarak geçiyor). Çift veride duruyor ama `b` tarafı boş, yani etkisiz.
- **A-009:** Kapandı: M3'te kurucu gerçek bir çalışan oldu (K-035); M1'deki geçici oyuncu büyümesi kaldırıldı.
- **A-010:** Kapandı, bkz. K-034.
- **A-011 (M10, ilerledi):** Küçük ofis Y3 ✓, bilgili botun 10 yıllık ortalama puanı 7.11 ✓ (denge adımı). Büyütülmüş ofis Y11, plaza katı açılmıyor (A-014).
- **A-012:** Kapandı. Rastgele bot ilk 3 yılda %22 iflas ediyor (200×10, hedef %20–40).
- **A-014 (açık, ilerledi):** M5 sonrası: ödül ve pitch ilk 13 yılda itibarı ~24'e taşıyor, ama 15. yıldan sonra puanlar düştüğü için itibar sıfıra iniyor ve plaza katı açılmıyor (M5 denge sonucu). Denge adımı (K-047..K-050) ilk 13 yılı düzeltti, ama 15. yıldan sonra puan yine düşüyor. Kalan iki engel: (1) plaza katı açılmıyor, itibar 40 gerekiyor ve itibar kaynakları (ödül, pitch, basın) M5'te; (2) kişi başı üretkenlik 30 yıl boyunca sabit, dönem tabanı ise ×10.6 büyüyor. Yetişmenin tek yolu ekibi 2'den ~22 kişiye çıkarmak; plaza katının kirası da bunu zorlaştırıyor. Ayar kolları: dönem büyüme oranı (1.085), dönemsel araç ve yazılım çarpanı (12.3, M7), çalışan gelişimi, plaza katı kirası.
- **A-013 (M4/M5):** GDD 11.1 Trafik "eşzamanlı kampanya sayısını ↑" diyor; şu an aynı anda tek kampanya üretimde. Eşzamanlı kampanyalar ekibin daha fazla iş, yani daha fazla gelir üretmesini sağlar (A-011'e de yardım eder), ama faz slider ekranının birden çok kampanyayı yönetmesi gerekir.

## K-084 · 2026-11-05 · Kabul · Orgo kararı (Tripo ile ilk deneme: masa) + uygulama
**Konu:** Yapay zekâ (görsel AI + Tripo) modellerini oyuna alma hattı (`art/ai_rehberi.md`).
**Karar:**
- **İçe alma betiği:** `tools/blender/import_ai.py`. Hangi dosyanın nereye, hangi ölçüyle gideceği `tools/blender/ai_imports.json`'da yazar. Ham Tripo dosyaları `art/incoming/` klasöründe durur (git dışı). Betik sırasıyla:
  - parçaları birleştirir, döndürür;
  - oyunun kutusuna ölçekler;
  - tabanı yere oturtur ve ortalar;
  - üçgen sayısını sınıra indirir;
  - dokuyu küçültür (JPEG, ≤1024 px);
  - yüzeyi mat yapar.
  `build_all.py` bu listedeki adları atlar; Blender betiği AI modelinin üstüne yazmaz.
- **"stretch" sığdırma:** Boyu işlev taşıyan eşyalar (masa 0.75 m: klavye ve el hizası) eksen eksen ölçeklenir. Tripo masası 1.0 × 0.53 × 0.45 m geldi; oranlı sığdırma masayı 0.59 m'ye indirirdi. Eksenler arası oran 1.35'i geçerse betik uyarır.
- **Renk dengeleme:** Görsel AI dokuları ofisin sıcak ışığında fazla doygun durdu. Masanın doygunluğu 0.61, palet ahşabı 0.49; parlaklık 0.84'e karşı 0.79 idi. Bütün AI dokularına varsayılan olarak doygunluk ×0.8 ve parlaklık ×0.94 uygulanıyor; eşyaya özel `grade` ile değiştirilebilir. Masa sonrası: doygunluk 0.48, parlaklık 0.79.
- **İlk model:** masa (`props/desk.glb`). 5.437 → 2.939 üçgen, doku 1024 px. Çekmeceler oturana bakıyor; ek döndürme gerekmedi.

## K-085 · 2026-11-07 · Kabul · Orgo kararı ("Cozy Refined" UI kiti) + uygulama
**Konu:** Orgo'nun hazırladığı "Cozy Refined" tasarım sistemi (krem paneller, orman yeşili, turuncu birincil eylem, ince çerçeve, hafif gölge). İlk adım (UI-1): ortak tema, ana menü ve finans ekranı.
**Karar:**
- **Kitin betiği (`CozyRefinedTheme.gd`) olduğu gibi alınmadı.** Godot 4.7'de çalışıyordu ama:
  - boşlukla girintiliydi, gereksiz `@tool` vardı;
  - açılır seçim, ipucu, kaydırma çubuğu, onay kutusu ve sekme stilleri yoktu;
  - ekranların kullandığı eski adlar (`AcceptButton`, `CardLight`, `CloseButton`…) tanımlı değildi. Eksik türler proje temasına düşer, iki görünüm karışırdı.
  Yerine `src/ui/theme/cozy_theme.gd` (`CozyTheme`) yazıldı. Kitin renk ve ölçü tokenları aynen alındı. Eksik kontrol türleri aynı dille eklendi; eski adlar yeni dile eşlendi. Onay kutusu, açılır ok ve kaydırıcı tutamağı ikonları kodla çiziliyor; Godot'nun varsayılan beyaz ikonları krem zeminde görünmüyordu.
- **Kademeli geçiş:** Proje teması (`UiTheme` → `main_theme.tres`) şimdilik değişmedi. Yeni tema yalnızca:
  - ana menüde: kökte `theme`;
  - finans penceresinde: `main.gd` yalnız finans açıkken pencereye ve kapatma düğmesine `CozyTheme` verir.
  Diğer ekranlar onaydan sonra; o zaman proje teması `CozyTheme` olur.
- **Düğme fontu Nunito (kalın):** Fredoka bu boyda "ş" çengelini harften ayrık çiziyor ("Çıkış¸"). Kit de Türkçe destekli gövde fontu istiyor. Başlıklar Fredoka'da kaldı. Eski temada aynı sorun bütün düğmelerde var; geçişte düzelecek.
- **Ana menü:** orman yeşili zemin üstünde krem modal. Tek turuncu birincil eylem: kayıt varsa "Devam et", yoksa "Yeni oyun". Çıkış çerçevesiz sessiz düğme. İşlevler ve sinyaller aynı.
- **Finans:** Üstte üç büyük sayı kartı: nakit, bekleyen tahsilat (notunda sıradaki tahsilat), hepsi ödenince nakit. Altında "Bu yıl", "Nakit akışı", kredi ve matbaa kartları. Eksi değerler kırmızımsı, kâr yeşil. "Kredi çek" birincil eylem. Hesaplar, komutlar ve veriler aynı. 2 yeni metin: `UI_FIN_SECTION_YEAR`, `UI_FIN_SECTION_FLOW`.
- **Referans görsel ZIP'te yoktu;** tasarım README'deki tokenlara ve kurallara göre uygulandı.
- **Ekran turu düzeltmesi:** Tur, rapor ve olay pencerelerini modal katmanında bulup kapatıyor; önceden finans görüntüsü rapor penceresinin altında kalıyordu.
