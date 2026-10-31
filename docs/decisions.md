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

## Açık sorular (ilgili kilometre taşında sorulacak)

- **A-001 (M1):** 7.2 `uyum_KN` için `(kanal_hedef + kanal_kitle) / 2` buçuklu değer verebilir (ör. +0.5); `f(x)` yalnızca tam sayılarda tanımlı. Öneri: komşu değerler arasında doğrusal ara değer.
- **A-002 (M1):** 7.2'de `uyum_ton` zaten `^0.5` alınıyor, M formülünde ayrıca `^0.10` ağırlığı var — ikisi birlikte mi uygulanacak (toplam üs 0.05)? Metin "tonun etkisi daha yumuşak" diyor; birlikte uygulamak doğrudan okunuş.
- **A-003 (M1):** 7.9 `hata_ağırlığı(yıl)` ve 7.10 `talep()`, `hatırlanma()`, `kitle_büyüklüğü`, `pazar_nüfusu`, `ortalama_sepet(sektör)` için sayı/eğri verilmemiş.
- **A-004 (M1):** 6.4 `12*(kalite_puanı − marka.beklenti)/2` — sadeleştirilmiş hâli `6*(…)`; bilinçli mi yazım mı?
- **A-005 (M1/M10):** M1 kabulü "akıllı bot rastgele bottan ≥ 2 puan iyi", 27.2 hedefi "≥ 2.5". Şimdilik M1 için ≥ 2, M10 için ≥ 2.5 olarak okunuyor.
- **A-006 (M3/M7):** 12.1 büyütülmüş ofis "Y8+", 17 "Y8 A6" — 17'deki ayrıntılı koşul esas alınabilir.
