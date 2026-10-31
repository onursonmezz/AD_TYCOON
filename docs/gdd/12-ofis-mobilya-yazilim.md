# 12 Ofisler, odalar, mobilya, donanım ve yazılım

## 12.1 Ofis seviyeleri

| Seviye | Kapasite | Açılma koşulu (örnek) | Özellik |
|---|---|---|---|
| 1. Ev odası / garaj | 1–2 | Başlangıç | Sadece küçük/orta işler, tek oda, kira yok. |
| 2. Küçük ofis (semt pasajı) | 2–6 | ₺500k nakit ve Y2+ | 2–3 oda; toplantı odası açılır. |
| 3. Büyütülmüş ofis | 6–12 | Y8+, 4 çalışan, ₺3M | Büyük kampanya kilidi, stüdyo odaları. |
| 4. Plaza katı | 12–30 | Y14+, 10 çalışan, ₺15M, itibar ≥ 40 | Oda inşası serbest (MGT2 tarzı), Ar-Ge lab, prodüksiyon stüdyosu. |
| 5. Ajans binası / Holding kampüsü | 30–120 | Y22+, ₺80M, itibar ≥ 70 | Çok katlı bina, ayrı şirketler (medya ajansı, prodüksiyon evi), çatı katı etkinlik alanı. |

## 12.2 Oda tipleri (MGT2 tarzı inşa)

| Oda | İşlev |
|---|---|
| Kreatif atölye (open office) | Kreatif/strateji ekiplerinin çalışma alanı. Mobilya kalitesi verimi etkiler. |
| Toplantı / sunum odası | Müşteri toplantısı (memnuniyet +), pitch provası (pitch puanı +). Seviye 2'de açılır. |
| Beyin fırtınası odası | Konsept odağında +%10; duvarlarda post-it'ler (görsel olarak sevimli). |
| Fotoğraf stüdyosu | Ürün çekimlerini içeride yapma (dış maliyet ↓). |
| Kurgu & ses odası | Video/jingle prodüksiyonu. |
| Film stüdyosu (yeşil perde) | TV reklamı çekimi (geç oyun). |
| Baskı atölyesi | Plotter → dijital baskı → ofset (dikey entegrasyon). |
| Veri / sunucu odası | Dijital performans verimi, "kendi analitik platformu" Ar-Ge'si. |
| Ar-Ge lab | Araştırma puanı üretimi, özel projeler. |
| Mutfak / kafeterya | Enerji yenileme hızı ↑, moral ↑. |
| Dinlenme / oyun odası | Tükenmişlik ↓ (masa tenisi, langırt, PlayStation parodisi "Playsystem"). |
| Ödül duvarı / lobi | Ödüller sergilenir; müşteri ziyaretlerinde itibar etkisi. |
| Arşiv / depo | Basılı malzeme stoğu. |

## 12.3 Mobilya ve dekor

Masa (basit → ergonomik → ayarlanabilir), sandalye, bilgisayar, bitkiler (moral +; görsel referansındaki bitki dükkânı estetiğiyle birebir uyumlu, bakımı gerekir — sulanmazsa kurur, ufak sevimli mekanik), kahve makinesi (1990: semaver/çaycı, 2005: filtre kahve, 2015: espresso makinesi — dönemsel nostalji!), su sebili, beyaz tahta, mood board, plak çalar, ödül vitrinleri, neon tabela, kedi/köpek (ofis maskotu, moral +).

```text
oda_kalitesi = Σ mobilya.konfor * yakınlık_etkisi / oda_alanı + dekor_çeşitliliği_bonusu − kalabalık_cezası
ofis_çarpanı = 0.85 + 0.40 * clamp(oda_kalitesi/100, 0, 1)
```

## 12.4 Donanım

Bilgisayarlar dönemsel: 1990 "PC-386" ve "Elmacık Macintosh", 2000 "Elmacık G4", 2010 "iMak", 2020 "M-çip Pro". Donanım seviyesi tasarım/prodüksiyon hızını etkiler; eski donanım yeni yazılım sürümlerini çalıştıramaz (yükseltme baskısı). Ayrıca: tarayıcı (scanner), renk kalibrasyonlu monitör, kamera seti, ışık seti, render farm, VR seti (2018+).

## 12.5 Yazılım ve abonelikler (aylık gider)

| Oyun içi ad (parodi) | Gerçek karşılığı | Çıkış | Etki alanı | Model |
|---|---|---|---|---|
| SayfaUstası / InDizayn | PageMaker / InDesign | 1990 / 1999 | Baskı işleri (Görsel + Prodüksiyon) | Lisans → 2013'te aylık |
| PixelShop | Photoshop | 1990 | Görsel, retouch | Lisans → 2013 abonelik |
| Vektörel / Illustrata | Illustrator / CorelDRAW | 1990 | Logo, kimlik, Görsel | Lisans → abonelik |
| Kurgu Pro | Premiere | 1995 | Video prodüksiyon | Lisans → abonelik |
| EfektSonrası | After Effects | 1995 | Motion, Prodüksiyon | Lisans → abonelik |
| Kübik 3D | Cinema 4D / Blender | 2000 | 3D, anamorfik billboard | Lisans |
| Figmo | Figma | 2016 | UI/UX, ekip işbirliği (+hız) | Aylık |
| Kanvaz | Canva | 2013 | Ucuz, hızlı ama düşük tavan (kalite tavanı −%15) | Aylık, ucuz |
| Analitik Pro / Gooble Analitik | Google Analytics | 2005 | Ölçümleme | Ücretsiz/Premium |
| SosyalPanel | Hootsuite vb. | 2009 | Sosyal medya yönetim verimi | Aylık |
| Slak | Slack | 2014 | Ekip iletişimi: koordinasyon ↑ (büyük ekiplerde) | Kişi başı aylık |
| Hayalci AI | Midjourney vb. | 2022 | Görsel hızı +%40, özgünlük riski | Aylık |
| Yazgan AI | LLM metin araçları | 2023 | Copy hızı +%30, özgünlük riski | Aylık |
| Video AI | Video üretim AI | 2025 | Prodüksiyon maliyeti −%50 (düşük-orta işler) | Aylık |

> "Gerçek karşılığı" sütunu yalnızca tasarım referansıdır; oyun içinde gerçek ürün adları kullanılmaz (Bölüm 28.1).

```text
araç_çarpanı(alan) = 0.6 + Σ ilgili_araçların_güncelliği * araç.katkı   # max 1.6
güncellik = 1.0 (son sürüm) ... 0.5 (3+ sürüm geride)
abonelik_gideri_aylık = Σ araç.koltuk_ücreti * kullanan_çalışan_sayısı
```

> **Neden ilginç?** 2013'te "lisans → abonelik" geçişi bir olay olarak gelir: aylık giderin artar ama hep güncel sürümdesin. Bu, gerçek ajansların yaşadığı bir dönüşüm ve oyuncuya anlamlı bir finansal karar verdirir. AI araçları ise "hız vs özgünlük" ikilemi yaratır.
