# Kodla çizilen görseller

> **Durum (2026-11-21):** Bölüm 1–4'teki 77 görselin hepsi geldi ve oyunda kullanılıyor (`assets/ui/option_art/`, 360×240; asılları `art/incoming/option_art/`). Kod çizimi yalnızca görsel yoksa yedek olarak çalışır. Değiştirmek için aynı adla yeni PNG koyman yeterli (sonra küçültme komutu için bana haber ver).

Bu listedeki görselleri şu an oyun kodla çiziyor. Hazır resim gelirse yerine konabilir.
Dosya adlarını aynen kullanırsan bağlamayı ben yaparım. Öneri: şeffaf PNG, sıcak "cozy" çizim tarzı (oyundaki ikon paketiyle aynı), kenarlarda boşluk az.

Toplam: 77 görsel (+ aşağıdaki küçük arayüz parçaları ve logolar).

## ChatGPT için hazır istem

Her görsel için aşağıdaki istemi kullan; `<ÇİZİM FİKRİ>` yerine tablodaki çizim fikrini yaz:

> Sıcak, el çizimi "cozy" tarzda tek bir oyun ikonu çiz: <ÇİZİM FİKRİ>. Kalın ama yumuşak kahverengi kontur, düz renkler,
> hafif kâğıt dokusu. Renkler: kiremit (#C9532A), adaçayı yeşili (#8DAA8E), koyu yeşil (#1E5631), hardal (#E0A93B),
> krem (#F8EFE0). Şeffaf arka plan, nesne ortada, kenarlarda az boşluk, metin yok. Yatay 3:2 oran (ör. 600×400 PNG).

- Görev çizimleri (bölüm 4) için başa "kâğıt bir kartın ya da defter sayfasının üstünde" ekle (görev planı taslağındaki gibi).
- Tek istisna: kataloglarda kapaktaki sayı (16, 32, 64) görünmeli; başka yazı olmasın.
- Hepsini aynı sohbette sırayla çizdirmen, tarzın tutarlı kalmasını sağlar.
- Bitince PNG'leri `art/incoming/option_art/` klasörüne aynı dosya adlarıyla koy; oyuna bağlamayı ben yaparım.

## 1. Baskı seçenekleri (kampanya kurulumu → baskı kanalı)

Kart içinde küçük çizim; yatay, 120×84 oranında.

| # | Dosya adı | Ne | Çizim fikri |
|---|---|---|---|
| 1 | `opt_product_flyer_a5.png` | El ilanı (A5) | Tek sayfa dikey A5 el ilanı, üstte renkli görsel, altta birkaç satır yazı |
| 2 | `opt_product_brochure_a4.png` | Broşür (A4 katlamalı) | Üç kırımlı açık broşür (zikzak paneller) |
| 3 | `opt_product_catalog_16.png` | Katalog (16 sayfa) | İnce katalog, kapakta "16" |
| 4 | `opt_product_catalog_32.png` | Katalog (32 sayfa) | Orta kalınlıkta katalog, kapakta "32" |
| 5 | `opt_product_catalog_64.png` | Katalog (64 sayfa) | Kalın katalog, kapakta "64" |
| 6 | `opt_product_pop_wobbler.png` | POP: wobbler / dangler | Raf kenarına yaylı çubukla takılmış yuvarlak indirim kartı ("%") |
| 7 | `opt_product_pop_stand.png` | POP: stand | Mağaza zemininde duran dik karton stand |
| 8 | `opt_quality_economy.png` | Ekonomik | İnce, soluk renkli, sarımsı ucuz kâğıt |
| 9 | `opt_quality_standard.png` | Standart | Temiz beyaz kâğıt, normal renkler |
| 10 | `opt_quality_premium.png` | Premium (kuşe, selefon, lak) | Parlak kuşe kâğıt, ışık yansıması ve küçük altın yıldız |
| 11 | `opt_distribution_door_to_door.png` | Kapı kapı | Kapının posta deliğine sokulmuş el ilanı |
| 12 | `opt_distribution_newspaper_insert.png` | Gazete arası | Gazetenin arasından çıkan renkli ek |
| 13 | `opt_distribution_in_store.png` | Mağazada | Tenteli dükkân vitrini, kapıda ilan |
| 14 | `opt_distribution_fair.png` | Fuarda | Fuar standı, bayrak ve ziyaretçi |
| 15 | `opt_supplier_ucuzcu_ofset.png` | Köşebaşı Ofset | Eski, kahverengi küçük ofset baskı makinesi (ucuz) |
| 16 | `opt_supplier_renkli_baski.png` | Baskılı Renkler A.Ş. | Kiremit rengi baskı makinesi, CMYK renk şeritleri |
| 17 | `opt_supplier_altin_varak.png` | Altın Varak Matbaacılık | Altın sarısı lüks baskı makinesi, yıldız |
| 18 | `opt_supplier_hizli_dijital.png` | Hızlı Dijital | Mavi dijital baskı makinesi, şimşek (hız) |

## 2. Medya seçenekleri (kampanya kurulumu → kanal ayarları)

Açık hava, yayın, dijital, gerilla ve etkinlik kanallarının seçenek kartları. Sosyal kanallar dijitalinkileri kullanır.

| # | Dosya adı | Ne | Çizim fikri |
|---|---|---|---|
| 19 | `opt_ooh_location_a.png` | Lokasyon paketi: A (ana arterler, meydanlar) | Şehir haritası: kalın kesişen ana yollar, çok sayıda pano işareti |
| 20 | `opt_ooh_location_b.png` | Lokasyon paketi: B (semt) | Şehir haritası: ince ızgara semt sokakları, birkaç pano |
| 21 | `opt_ooh_location_c.png` | Lokasyon paketi: C (çevre yollar) | Şehir haritası: kenardan geçen çevre yolu, az pano |
| 22 | `opt_ooh_weeks_1.png` | Süre: 1 hafta | Takvim, 1 hafta işaretli |
| 23 | `opt_ooh_weeks_2.png` | Süre: 2 hafta | Takvim, 2 hafta işaretli |
| 24 | `opt_ooh_weeks_4.png` | Süre: 4 hafta | Takvim, 4 hafta (bütün ay) işaretli |
| 25 | `opt_broadcast_daypart_morning.png` | Kuşak: Sabah | Sabah: doğan güneş, kahve fincanı |
| 26 | `opt_broadcast_daypart_day.png` | Kuşak: Gündüz | Gündüz: tepedeki güneş, mutfakta radyo |
| 27 | `opt_broadcast_daypart_prime.png` | Kuşak: Prime time | Akşam: koltukta aile, açık televizyon |
| 28 | `opt_broadcast_daypart_night.png` | Kuşak: Gece | Gece: ay ve yıldızlar, karanlık oda, TV ışığı |
| 29 | `opt_broadcast_spot_15.png` | Spot süresi: 15 sn | Kronometre, kısa dilim (15 sn) |
| 30 | `opt_broadcast_spot_30.png` | Spot süresi: 30 sn | Kronometre, çeyrek dilim (30 sn) |
| 31 | `opt_broadcast_spot_45.png` | Spot süresi: 45 sn | Kronometre, büyük dilim (45 sn) |
| 32 | `opt_broadcast_spot_60.png` | Spot süresi: 60 sn | Kronometre, tam tur (60 sn) |
| 33 | `opt_digital_bid_cpm.png` | Teklif modeli: CPM (bin gösterim) | Göz ikonu (gösterim başına ödeme) |
| 34 | `opt_digital_bid_cpc.png` | Teklif modeli: CPC (tıklama) | Tıklayan fare imleci |
| 35 | `opt_digital_bid_cpa.png` | Teklif modeli: CPA (dönüşüm) | Alışveriş sepeti / onay işareti (satın alma) |
| 36 | `opt_digital_targeting_broad.png` | Hedefleme: Geniş | Geniş daire içinde çok sayıda insan |
| 37 | `opt_digital_targeting_balanced.png` | Hedefleme: Dengeli | Orta daire, birkaç kişi |
| 38 | `opt_digital_targeting_narrow.png` | Hedefleme: Dar | Hedef tahtası, tam ortada tek kişi |
| 39 | `opt_guerrilla_card_footprints.png` | Gerilla fikri: Dev ayak izleri | Kaldırımda dev ayak izleri |
| 40 | `opt_guerrilla_card_street_art.png` | Gerilla fikri: Kaldırıma 3D çizim | Kaldırıma çizilmiş 3D çukur illüzyonu |
| 41 | `opt_guerrilla_card_flash_mob.png` | Gerilla fikri: Flash mob | Meydanda aynı anda dans eden kalabalık |
| 42 | `opt_guerrilla_card_bus_stops.png` | Gerilla fikri: Duraklara yerleştirme | Otobüs durağına yerleştirilmiş şaşırtıcı ürün |
| 43 | `opt_guerrilla_card_fake_queue.png` | Gerilla fikri: Sahte ürün kuyruğu | Dükkân önünde uzun insan kuyruğu |
| 44 | `opt_event_venue_hall.png` | Mekân: Küçük salon | Küçük salon, birkaç sandalye ve sahne |
| 45 | `opt_event_venue_hotel.png` | Mekân: Otel balo salonu | Otel balo salonu, avize |
| 46 | `opt_event_venue_open_air.png` | Mekân: Açık hava alanı | Açık hava: çadır, bayraklar, ağaçlar |
| 47 | `opt_event_catering_basic.png` | Catering: Basit | Basit ikram masası: kurabiye ve çay |
| 48 | `opt_event_catering_premium.png` | Catering: Premium | Lüks ikram: kanepeler, şampanya kadehleri |
| 49 | `opt_event_guests_public.png` | Davetliler: Sadece katılımcılar | Sıradan katılımcılar, isim kartları |
| 50 | `opt_event_guests_press.png` | Davetliler: Basın | Basın: fotoğraf makineleri ve mikrofonlar |
| 51 | `opt_event_guests_press_influencers.png` | Davetliler: Basın + influencer | Basın + telefonla canlı yayın yapan influencerlar |
| 52 | `opt_influencer.png` | Influencer (genel) | Renkli halkalı yuvarlak profil resmi (hikâye halkası gibi); kişisiz, genel |

## 3. Hedef, kitle ve ton (yeni kampanya penceresi)

| # | Dosya adı | Ne | Çizim fikri |
|---|---|---|---|
| 53 | `opt_objective_awareness.png` | Bilinirlik | Megafon ve ses dalgaları |
| 54 | `opt_objective_launch.png` | Lansman | Kalkan roket |
| 55 | `opt_objective_sales.png` | Satış/Dönüşüm | Yükselen sütun grafik ve ok |
| 56 | `opt_objective_rebrand.png` | Marka Yenileme | Eski soluk logo → yeni parlak logo |
| 57 | `opt_objective_engagement.png` | Etkileşim/Sadakat | Konuşma balonları ve kalp |
| 58 | `opt_objective_csr.png` | Sosyal Sorumluluk/İtibar | Avuç içinde fidan |
| 59 | `opt_audience_young.png` | Genç | Kaykaylı, şapkalı genç |
| 60 | `opt_audience_adult.png` | Yetişkin | Çantalı iki yetişkin |
| 61 | `opt_audience_mature.png` | Olgun | Gözlüklü, bastonlu yaşlı kişi |
| 62 | `opt_audience_b2b.png` | Kurumsal/B2B | İki şirket binası, aralarında el sıkışma |
| 63 | `opt_tone_emotional.png` | Duygusal | Kalp ve gözyaşı damlası |
| 64 | `opt_tone_humorous.png` | Esprili | Kahkaha atan yüz |
| 65 | `opt_tone_informative.png` | Bilgilendirici | Bilgi kartı, "i" işareti ve satırlar |
| 66 | `opt_tone_bold.png` | Cesur/Provokatif | Şimşek ve patlama yıldızı |
| 67 | `opt_tone_luxury.png` | Lüks/Prestijli | Pırlanta ve küçük altın yıldız |
| 68 | `opt_tone_nostalgic.png` | Nostaljik | Sararmış eski fotoğraf |

## 4. Görev çizimleri (görev planı penceresi)

Taslaktaki gibi kâğıt üstü küçük çizimler; yatay, ~100×70.

| # | Dosya adı | Ne | Çizim fikri |
|---|---|---|---|
| 69 | `focus_research.png` | Pazar Araştırması | Kâğıt üstünde sütun grafik ve büyüteç |
| 70 | `focus_insight.png` | İçgörü (Insight) | Parlayan ampul |
| 71 | `focus_positioning.png` | Konumlandırma & Mesaj | Hedef tahtası ve ok |
| 72 | `focus_concept.png` | Büyük Fikir / Konsept | Spiralli defter, üstünde ampul |
| 73 | `focus_copy.png` | Metin Yazarlığı (Copy) | Yazılı kâğıt ve kalem |
| 74 | `focus_visual.png` | Görsel Tasarım (Art) | Bantlı resim: dağlar ve güneş |
| 75 | `focus_production.png` | Prodüksiyon | Film klaketi |
| 76 | `focus_media_planning.png` | Medya Planlama | Takvim ve megafon |
| 77 | `focus_measurement.png` | Ölçümleme & Optimizasyon | Yükselen çizgi grafik |

## 5. Küçük arayüz parçaları

Bunlar çok küçük (16–34 px); çizdirmek şart değil, istersen:

| Dosya adı | Ne |
|---|---|
| `ui_checkbox_on.png` / `ui_checkbox_off.png` | Onay kutusu (dolu / boş) |
| `ui_radio_on.png` / `ui_radio_off.png` | Yuvarlak seçim düğmesi |
| `ui_switch_on.png` / `ui_switch_off.png` | Aç/kapa anahtarı |
| `ui_dropdown_arrow.png` | Açılır menü oku |
| `ui_slider_dot.png` | Ayarlar kaydırıcısının yuvarlak tutamağı |
| `ui_slider_pill.png` | Görev planı kaydırıcısının turuncu "II" tutamağı |

## 6. Kodla çizilen sahneler (ikon değil)

- Pazarlık penceresindeki tokalaşma sahnesi ve iki konuşan kişi (`negotiation_stage`).
- Faz adımları şeridi (ok biçimli üç parça), finans grafiği, faz takip çubuğu: bunlar çizim değil, arayüz parçası; kodda kalmaları daha iyi.
- Mini oyunlardan "Harita" ve "Radyo"da bazı parçalar kodla çiziliyor.

## 7. Parodi logolar (zaten PNG, ama kodla üretildi)

Bunlar `assets/ui/icons/logo-*.png` dosyaları; kodla çizilip PNG olarak kaydedildi. Daha güzel istersen aynı adla değiştirebilirsin:

- `logo-abode-before-effects.png`
- `logo-abode-outdesign.png`
- `logo-abode-photostore.png`
- `logo-abode-premium-pro.png`
- `logo-abode-vectorator.png`
- `logo-chattnt.png`
- `logo-digma.png`
- `logo-facenook.png`
- `logo-gooble-abs.png`
- `logo-gooble-analytics.png`
- `logo-instagraph.png`
- `logo-kamva.png`
- `logo-linkedout.png`
- `logo-nitrosoft-newcel.png`
- `logo-nitrosoft-strongpoint.png`
- `logo-nitrosoft-world.png`
- `logo-pear.png`
- `logo-slak.png`
- `logo-surveycappybara.png`
- `logo-theatre-4d.png`
- `logo-ticktock.png`
- `logo-tootsuite.png`
- `logo-topjourney.png`
- `logo-tricksfield.png`
- `logo-tweakker.png`
- `logo-yourtube.png`
