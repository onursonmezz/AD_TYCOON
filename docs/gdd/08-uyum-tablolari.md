# 8 Uyum tabloları

Bu tablolar oyunun "gizli bilgi"sidir; GDT rehberindeki tabloların bizim oyunumuzdaki karşılığı. Değerler −3 (−−−) ile +3 (+++) arasındadır; ~ "fark etmez" demektir. Oyunda oyuncuya başta gösterilmez; deneyerek, "Pazar Araştırması" yaparak veya "Fokus Grup" Ar-Ge'si ile keşfedilir ve Bilgi Defterine yazılır. Claude Code bu tabloları birebir `data/fit/*.json` dosyalarına aktarmalıdır.

> Veri karşılığı: 8.1 → `data/fit/sector_objective.json` + `data/fit/sector_audience.json` (+ `data/sectors.json`), 8.2 → `data/objectives.json`, 8.3 → `data/fit/tone_fit.json` (+ `data/tone_groups.json`), 8.4 → `data/fit/channel_fit.json` (+ `data/channels.json`). Bu dosyadaki tablolar doğrudan JSON'dan üretildi; JSON ile PDF birebir aynıdır.

## 8.0 Dağılım kuralı (zorluğun temeli)

Tablolar kolayca "her şey yeşil" hâline gelebilir; o zaman rastgele seçim de iyi sonuç verir ve doğru kombinasyonu bulmanın zevki kaybolur. Bu yüzden her satır sabit bir dağılım kuralına uyar:

| Tablo tipi | Her satırda zorunlu dağılım | Sonuç |
|---|---|---|
| 6 sütunlu (hedef, ton) | 1× +++, 1× ++, 2× + veya ~ (biri + biri ~), 1× −, 1× −− veya −−− | %50 olumlu · %17 nötr · %33 olumsuz |
| 4 sütunlu (hedef kitle) | 1× +++, 1× ++ veya +, 1× ~ veya −, 1× −− veya −−− | %50 olumlu · ~%14 nötr · ~%36 olumsuz |

- Her satırda tam olarak tek bir +++ var: her sektörün/kanalın bir "doğru cevabı" vardır ve onu bulmak ödüllendirilir.
- Her satırda en az bir güçlü olumsuz (−− / −−−) var: bilmeden seçim yapmak gerçekten risklidir.
- Asimetrik çarpanla (Bölüm 7.2) birlikte: rastgele bir kombinasyonun ortalama uyum çarpanı ≈ 0.95 (ve rastgele denemelerin ~%23'ü 0.85'in altında kalır), en iyi kombinasyonunki ≈ 1.24. Yani doğru bilgi, kampanya puanında ≈ %30 fark yaratır.
- Bu kural `tools/validate_data.gd` içinde otomatik kontrol edilir; bir satır kuralı bozarsa veri doğrulama hata verir. Playtest'te değerleri değiştirebilirsin ama dağılımı korumalısın.

### Mantık notları

Değerler gerçek reklamcılık sezgisine göre verildi (ör. Emlak'ta Etkileşim −−−, STK'da Satış −−−, B2B'de Genç kitle −−−, Lüks'te Satış/İndirim kampanyası −−− çünkü markayı ucuzlatır). Gizli bilgi olduğu için oyuncu bunları deneyerek ve Bilgi Defteri ile öğrenir.

## 8.1 Sektör × Kampanya Hedefi | Sektör × Hedef Kitle

| Sektör | Yıl | Bilinirlik | Lansman | Satış/Dön. | Yenileme | Etkileşim | SSR/İtibar | Genç | Yetişkin | Olgun | B2B |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Fast Food | 1990 | ++ | ~ | +++ | − | + | −− | +++ | + | − | −−− |
| Gıda & Ambalajlı Ürün | 1990 | +++ | + | ++ | −− | − | ~ | + | +++ | ~ | −−− |
| Alkolsüz İçecek | 1990 | +++ | + | ~ | − | ++ | −−− | +++ | + | − | −−− |
| Kahve & Kafe Zinciri | 1995 | ++ | ~ | − | + | +++ | −− | ++ | +++ | − | −− |
| Otomotiv | 1990 | ++ | +++ | ~ | + | −− | − | −− | +++ | + | ~ |
| Banka & Finans | 1990 | ++ | − | +++ | + | −− | ~ | − | +++ | ++ | −− |
| Sigorta | 1990 | + | −− | +++ | ~ | − | ++ | −−− | ++ | +++ | ~ |
| Telekom & GSM | 1994 | +++ | + | ++ | −− | ~ | − | +++ | + | ~ | −− |
| Teknoloji & Elektronik | 1990 | + | +++ | ++ | − | ~ | −−− | +++ | + | −−− | ~ |
| Moda & Tekstil | 1990 | + | +++ | − | ++ | ~ | −− | +++ | ++ | − | −−− |
| Kozmetik & Güzellik | 1990 | + | +++ | ~ | −− | ++ | − | ++ | +++ | − | −−− |
| Perakende / Market | 1990 | + | −− | +++ | ~ | ++ | − | ~ | +++ | + | −−− |
| E-ticaret | 1999 | ~ | + | +++ | −− | ++ | − | ++ | +++ | − | −− |
| Turizm & Otel | 1990 | +++ | − | ++ | + | ~ | −− | − | +++ | ++ | −− |
| Havayolu | 1990 | ++ | − | + | +++ | −− | ~ | ~ | +++ | −− | ++ |
| Emlak & İnşaat | 1990 | + | +++ | ++ | ~ | −−− | − | −−− | ++ | +++ | ~ |
| Sağlık & İlaç | 1990 | ++ | ~ | −− | + | − | +++ | −− | + | +++ | ~ |
| Özel Hastane | 1993 | +++ | −− | ~ | + | − | ++ | −−− | ++ | +++ | − |
| Eğitim & Dershane/Okul | 1990 | ++ | − | +++ | −− | ~ | + | +++ | ++ | −− | − |
| Oyun & Eğlence | 1990 | + | +++ | ~ | − | ++ | −−− | +++ | + | − | −−− |
| Spor & Spor Giyim | 1990 | ++ | + | − | −− | +++ | ~ | +++ | ++ | − | −− |
| Enerji & Akaryakıt | 1990 | + | −− | ~ | ++ | − | +++ | −− | + | ~ | +++ |
| Beyaz Eşya & Ev Aletleri | 1990 | + | ++ | +++ | ~ | −− | − | −− | +++ | ++ | − |
| Mobilya & Dekorasyon | 1990 | ~ | + | +++ | ++ | − | −− | ~ | +++ | + | −− |
| Lüks Ürünler | 1990 | +++ | + | −−− | ++ | ~ | − | −−− | ++ | +++ | − |
| Bebek & Çocuk Ürünleri | 1990 | ++ | − | + | −− | +++ | ~ | − | +++ | + | −−− |
| Evcil Hayvan Ürünleri | 1998 | − | ~ | ++ | −− | +++ | + | ++ | +++ | ~ | −−− |
| STK & Vakıf | 1990 | + | − | −−− | ~ | ++ | +++ | ++ | ~ | +++ | −− |
| Kamu & Belediye | 1990 | ++ | − | −−− | + | ~ | +++ | ~ | +++ | ++ | −− |
| Mobil Uygulama & Startup | 2010 | ~ | +++ | ++ | −− | + | − | +++ | ++ | −−− | ~ |
| B2B Yazılım & Hizmet | 1995 | ~ | ++ | +++ | + | −− | − | −−− | ~ | + | +++ |
| Lojistik & Kargo | 1990 | ~ | −− | ++ | +++ | − | + | −−− | ~ | + | +++ |
| Festival & Müzik | 1990 | ++ | + | ~ | −− | +++ | − | +++ | ++ | − | −−− |
| Medya & Yayıncılık | 1990 | ++ | +++ | − | ~ | + | −− | ++ | +++ | ~ | −− |
| Kripto & Fintech | 2017 | + | +++ | ++ | − | ~ | −−− | +++ | + | −−− | ~ |

## 8.2 Hedef × Faz Odak Önemi (GDT "Genre/Stages Chart" karşılığı)

Her hedef için 9 odak alanının önemi ve ideal Strateji/Kreatif (S/K) oranı. Ör. Satış/Dönüşüm kampanyası ölçüm ve medya planlama ister (analitik, S/K 1.7); Marka Yenileme ise derin araştırma ve görsel kimlik ister (S/K 0.5 → kreatif ağırlıklı).

Sütunlar: Faz 1: Strateji (Araştırma, İçgörü, Konum.) · Faz 2: Kreatif (Konsept, Copy, Görsel) · Faz 3: Prodüksiyon & Yayın (Prodüks., Medya Pl., Ölçüm).

| Kampanya hedefi | İdeal S/K | Araştırma | İçgörü | Konum. | Konsept | Copy | Görsel | Prodüks. | Medya Pl. | Ölçüm |
|---|---|---|---|---|---|---|---|---|---|---|
| Bilinirlik | 0.6 | ~ | ++ | ++ | +++ | ++ | +++ | ++ | +++ | − |
| Lansman | 1.0 | ++ | ++ | +++ | +++ | ++ | ++ | +++ | ++ | ~ |
| Satış / Dönüşüm | 1.7 | ++ | + | ++ | ~ | +++ | + | + | +++ | +++ |
| Marka Yenileme | 0.5 | +++ | +++ | +++ | ++ | ~ | +++ | ++ | − | −− |
| Etkileşim / Sadakat | 0.9 | + | +++ | + | +++ | ++ | ++ | + | ++ | ++ |
| SSR / İtibar | 0.8 | ++ | +++ | ++ | ++ | +++ | + | ~ | + | − |

### Çift hedef (Multi-Genre karşılığı)

"Çift Hedef" Ar-Ge'si açıldığında (≈ 2008) oyuncu iki hedef seçebilir (ör. Lansman + Satış). Kurallar GDT'deki gibi:

```text
fit_çift(sektör) = 2/3 * fit(hedef1) + 1/3 * fit(hedef2)
önem_çift(odak)  = 2/3 * önem(hedef1) + 1/3 * önem(hedef2)
ideal_SK_çift    = 2/3 * SK(hedef1) + 1/3 * SK(hedef2)
```

Bazı eşleşmeler doğal olarak çakışır (Satış + SSR → ek −%10 "samimiyetsiz" cezası; `data/combo_rules.json`).

## 8.3 Sektör grubu × Ton

| Sektör grubu | Duygusal | Esprili | Bilgilendirici | Cesur | Lüks | Nostaljik |
|---|---|---|---|---|---|---|
| Fast Food / Gıda / İçecek | + | +++ | − | ~ | −− | ++ |
| Otomotiv | + | −− | ~ | ++ | +++ | − |
| Banka / Sigorta / Finans | ++ | − | +++ | −− | ~ | + |
| Telekom | ++ | +++ | ~ | + | −− | − |
| Teknoloji / Startup / Fintech | − | + | ++ | +++ | ~ | −− |
| Moda / Kozmetik / Lüks | + | − | −− | ++ | +++ | ~ |
| Sağlık / İlaç / Hastane | ++ | − | +++ | −−− | ~ | + |
| Perakende / E-ticaret | + | +++ | ++ | − | −−− | ~ |
| STK / Kamu | +++ | − | ++ | + | −−− | ~ |
| Oyun / Festival / Spor | ~ | ++ | − | +++ | −− | + |
| B2B / Lojistik / Enerji | + | −− | +++ | ~ | ++ | − |

Marka kişiliği tonu ayrıca etkiler: "cesur" marka Cesur/Esprili tona +1, "muhafazakâr" marka Cesur tona −1 alır.

> Sektör → ton grubu eşlemesi `data/sectors.json` içindeki `tone_group` alanındadır. PDF'te gruba yazılmamış 10 sektörün eşlemesi `docs/decisions.md` K-003'te.

## 8.4 Kanal × Hedef | Kanal × Kitle (GDT "Platform" tablosu karşılığı)

| Kanal | Tür | Yıl | Min. ₺k* | Bilinirlik | Lansman | Satış/Dön. | Yenileme | Etkileşim | SSR/İtibar | Genç | Yetişkin | Olgun | B2B | Viral |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Gazete ilanı | Baskı | 1990 | 2 | + | +++ | ++ | ~ | −− | − | −−− | + | +++ | ~ | – |
| Dergi ilanı | Baskı | 1990 | 3 | + | ++ | − | +++ | −− | ~ | + | +++ | − | −− | – |
| Broşür & el ilanı | Baskı | 1990 | 0.5 | ~ | ++ | +++ | −− | + | − | − | +++ | ++ | −− | – |
| Katalog | Baskı | 1990 | 4 | ~ | ++ | +++ | − | + | −−− | −− | ++ | +++ | ~ | – |
| POP / mağaza içi | Baskı | 1990 | 1.5 | ~ | ++ | +++ | − | + | −− | + | +++ | ~ | −−− | – |
| Billboard | OOH | 1990 | 5 | +++ | ++ | − | + | −− | ~ | + | +++ | ~ | −− | – |
| Raket / durak | OOH | 1990 | 2 | +++ | + | ++ | ~ | −− | − | +++ | ++ | − | −−− | – |
| Otobüs / metro giydirme | OOH | 1993 | 6 | +++ | ++ | − | ~ | + | −− | +++ | + | − | −− | ★ |
| Megalight / bina giydirme | OOH | 1996 | 15 | ++ | +++ | −− | + | − | ~ | ~ | +++ | ++ | −− | ★ |
| Dijital billboard (DOOH) | OOH | 2012 | 20 | ++ | +++ | + | − | ~ | −− | +++ | ++ | − | −− | ★ |
| 3D anamorfik billboard | OOH | 2021 | 60 | + | ++ | −−− | ~ | +++ | − | +++ | + | − | −−− | ★★★ |
| Gerilla / ambient | Gerilla | 1990 | 1 | ++ | ~ | −−− | − | +++ | + | +++ | ++ | − | −−− | ★★★ |
| Radyo spotu / jingle | Yayın | 1990 | 3 | ++ | + | +++ | − | ~ | −− | − | ++ | +++ | −− | – |
| Ulusal TV | Yayın | 1990 | 80 | +++ | ++ | − | + | −− | ~ | ~ | +++ | ++ | −−− | ★ |
| Yerel TV | Yayın | 1992 | 10 | + | ~ | +++ | −− | − | ++ | − | ++ | +++ | −−− | – |
| Sinema reklamı | Yayın | 1990 | 8 | ++ | +++ | −− | ~ | + | − | +++ | ++ | − | −−− | – |
| CTV / bağlı TV | Yayın | 2018 | 30 | ++ | + | +++ | ~ | − | −− | + | +++ | ~ | −− | – |
| Podcast | Yayın | 2018 | 4 | ~ | −− | − | + | +++ | ++ | ++ | +++ | −− | ~ | – |
| Kurumsal web sitesi | Dijital | 1997 | 3 | − | + | ++ | +++ | ~ | −− | −− | ++ | ~ | +++ | – |
| Banner / display | Dijital | 1998 | 3 | +++ | + | ++ | ~ | − | −− | ++ | +++ | − | −− | – |
| E-posta bülteni | Dijital | 1998 | 0.8 | −− | + | ++ | ~ | +++ | − | −− | ++ | ~ | +++ | – |
| SMS pazarlama | Dijital | 2001 | 1 | ~ | + | +++ | −−− | ++ | − | ~ | +++ | + | −− | – |
| Arama reklamı (Gooble Kelime) | Dijital | 2002 | 2 | + | ++ | +++ | −− | ~ | − | ~ | +++ | −− | ++ | – |
| SEO & içerik | Dijital | 2004 | 4 | + | −− | +++ | ~ | ++ | − | ~ | ++ | −− | +++ | – |
| Görüntülü Ağ (GDN karşılığı) | Dijital | 2007 | 3 | +++ | + | ++ | − | ~ | −− | ++ | +++ | − | −− | – |
| Mobil uygulama | Dijital | 2011 | 15 | − | + | ++ | ~ | +++ | −− | +++ | ++ | −−− | ~ | ★ |
| Programatik | Dijital | 2013 | 10 | ++ | + | +++ | −− | ~ | − | ++ | +++ | ~ | −− | – |
| AR filtre / deneyim | Dijital | 2018 | 8 | + | ++ | −− | ~ | +++ | − | +++ | + | −−− | − | ★★ |
| Retail media | Dijital | 2023 | 8 | ~ | ++ | +++ | −− | + | − | + | +++ | ~ | −−− | – |
| YouTüp video reklamı | Sosyal | 2007 | 6 | +++ | ++ | − | ~ | + | −− | +++ | ++ | − | −− | ★★ |
| FaceBuk reklamları | Sosyal | 2008 | 2 | + | ~ | ++ | − | +++ | −− | − | +++ | ++ | −− | ★★ |
| Cıvıl (mikroblog) | Sosyal | 2009 | 1.5 | + | ~ | −−− | − | +++ | ++ | +++ | ++ | − | −− | ★★★ |
| LinkedOut | Sosyal | 2011 | 4 | + | − | ++ | +++ | −− | ~ | −−− | + | ~ | +++ | – |
| InstaFoto reklamları | Sosyal | 2015 | 3 | + | +++ | ~ | − | ++ | −− | +++ | ++ | − | −−− | ★★ |
| TikTak | Sosyal | 2019 | 3 | ++ | + | ~ | −− | +++ | − | +++ | + | −−− | − | ★★★ |
| Ünlü yüzü (TV dönemi) | Influencer | 1990 | 50 | +++ | ++ | ~ | + | − | −− | ~ | +++ | ++ | −−− | ★ |
| Influencer (mikro) | Influencer | 2012 | 2 | ~ | + | ++ | −− | +++ | − | +++ | ++ | − | −−− | ★★ |
| Influencer (makro / mega) | Influencer | 2014 | 30 | ++ | +++ | ~ | − | + | −− | +++ | + | − | −− | ★★★ |
| Etkinlik / lansman partisi | Etkinlik | 1990 | 15 | ~ | +++ | −− | + | ++ | − | ++ | ~ | −− | +++ | ★★ |
| Fuar standı | Etkinlik | 1990 | 12 | ~ | ++ | +++ | + | − | −− | −−− | + | ~ | +++ | – |
| Konser / festival sponsorluğu | Sponsorluk | 1990 | 25 | +++ | ~ | −− | + | ++ | − | +++ | + | − | −−− | ★ |
| Spor sponsorluğu | Sponsorluk | 1990 | 30 | +++ | − | −− | ++ | + | ~ | ++ | +++ | ~ | −− | ★ |
| Dizi içi ürün yerleştirme | Sponsorluk | 1995 | 20 | +++ | ~ | ++ | + | − | −−− | − | ++ | +++ | −−− | ★ |
| PR & basın bülteni | PR | 1990 | 1 | + | ~ | −− | ++ | − | +++ | −− | ++ | ~ | +++ | ★ |
| Sosyal sorumluluk projesi | PR | 1990 | 10 | ~ | − | −−− | ++ | + | +++ | +++ | ++ | ~ | −− | ★★ |

\* Min. bütçe 1990 bazlı bin ₺ (oyun içi para); enflasyon ve kanal talebiyle her yıl güncellenir. Viral ★ = viral potansiyel. Kanal yalnızca çıkış yılından itibaren ve ilgili Ar-Ge açıldıysa kullanılabilir.
