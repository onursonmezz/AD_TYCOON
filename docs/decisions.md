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
