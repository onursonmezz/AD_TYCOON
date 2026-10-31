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

- **A-005 (M2'ye ertelendi · Orgo kararı, 2026-10-31):** M1 bu hâliyle kabul edildi; Bölüm 7 formülleri ve tablolar M2 prototipi oynanırken birlikte ayarlanacak (GDD 26 M2 kontrol noktası). Rastgele bot iflası (%41) da o ayarda tekrar ölçülecek. Puan farkı 1.5'te takılıyor; ayarla ≥ 2'ye çıkmıyor (serbest hedef oranı %100'de bile 1.74). Sebepler: (1) Göreceli puan (7.9): bilgili bot kendi rekoruyla (×1.05) yarışıyor, rastgele bot ise yalnızca dönem tabanıyla. İyi oyuncunun çıtası yükseldikçe fark sıkışıyor. (2) Hedefi çoğu zaman brief belirliyor, en ağır uyum (sektör × hedef, ağırlık 0.35) oyuncunun bilgisine bağlı değil. (3) F aralığı dar (0.8–1.2); rastgele slider'lar bile ~1.12 alıyor. M10 hedefi (27.2) ise ≥ 2.5.
- **A-006 (M3/M7):** 12.1 büyütülmüş ofis "Y8+", 17 "Y8 A6": 17'deki ayrıntılı koşul esas alınabilir.
- **A-007 (M2/M3):** S/K oranı tek kişilik ajansta yapısal olarak ≥ ~1 çıkıyor, çünkü Strateji fazının bütün üretimi S'ye gidiyor. İdeal oranı 1'in altında olan hedefler (Bilinirlik 0.6, Yenileme 0.5, SSR 0.8, Etkileşim 0.9) her zaman B cezası alıyor. Ekip kurulunca (M3) kreatif ağırlıklı ekip bunu çözer; ya da faz sürelerinin oyuncuya bırakılması düşünülebilir.
- **A-008 (M4):** 7.3 "Display + Retargeting" sinerjisi: kanal tablosunda "retargeting" kanalı yok (5.2'de özellik olarak geçiyor). Çift veride duruyor ama `b` tarafı boş, yani etkisiz.
- **A-009 (M3):** K-024'teki geçici oyuncu XP büyümesi M3'te gerçek çalışan modeline devredilmeli.
- **A-010 (M2 playtest):** Oyun hızı çelişkisi. 5.1 "1x'te 1 hafta ≈ 3 saniye" diyor, bu da yılda 2.4 dakika eder. 4.1 ve 27.2 ise "bir oyun yılı 1x'te 10–15 dakika" diyor. Duraklamalar (sihirbaz, slider, rapor) süreyi uzatıyor ama bu kadar değil. Playtest'te hissedip birlikte karar verelim (`time.seconds_per_week_1x`).
- **A-006 (M3/M7):** 12.1 büyütülmüş ofis "Y8+", 17 "Y8 A6" — 17'deki ayrıntılı koşul esas alınabilir.
