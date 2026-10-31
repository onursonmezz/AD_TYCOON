# 9 Kanallar ve özel mekanikleri

Kanallar sadece "tablodaki bir satır" değildir; her kategorinin kendine has mini kararları vardır. Bu kararlar oyunu GDT'den daha zengin yapar ama hepsi opsiyonel derinlik olarak tasarlanmalıdır: oyuncu "otomatik" seçerse makul varsayılan uygulanır (Medya Planlamacı çalışanı varsa onun yeteneğine göre).

## 9.1 Basılı işler (broşür, katalog, el ilanı, afiş, POP)

- **Ürün tipi:** El ilanı (A5), broşür (A4 katlamalı), katalog (16–64 sayfa), afiş (50×70), POP (stand, wobbler, dangler), ambalaj tasarımı (ileri seviye).
- **Kâğıt & baskı kalitesi:** Ekonomik / Standart / Premium (kuşe, selefon, lak). Kalite algıyı ve Lüks sektör uyumunu etkiler.
- **Adet:** 1.000 – 1.000.000. Birim maliyet ölçek ekonomisiyle düşer (Bölüm 10.2).
- **Dağıtım:** Kapı kapı, gazete arası, mağaza, fuar. Dağıtım ekibi maliyeti ve "çöpe giden oran" (verim).
- **Riskler:** Baskı hatası (renk kayması, yazım hatası → yeniden baskı), geç teslim, depo maliyeti.
- **Prova (proof):** Matbaa provası istemek 1 hafta + küçük maliyet ekler ama baskı hatası riskini %70 düşürür.

## 9.2 Açık hava (OOH): billboard, raket, megalight, araç giydirme, DOOH

- **Lokasyon paketi:** A (ana arterler, meydanlar), B (semt), C (çevre yollar). A pahalı ama erişim ×2.5.
- **Süre:** 1–4 hafta periyotlar. OOH "yer kiralama" mantığıyla çalışır, popüler dönemlerde (seçim, bayram) dolar → bekleme listesi.
- **Belediye izni:** Megalight ve bina giydirmede izin süresi ve reddedilme riski.
- **Hava/zaman olayları:** Fırtına billboardı yırtar (sigorta Ar-Ge'si), "Billboard fotoğrafı viral oldu" olayı.
- **DOOH (2012+):** Saat bazlı yayın, hava durumuna göre dinamik içerik (Ölçümleme odaklı bonus).
- **3D anamorfik (2021+):** Çok pahalı, yüksek prodüksiyon (3D sanatçı gerekir), çok yüksek viral şansı.

## 9.3 Gerilla / ambient pazarlama

Ucuz ama riskli, yüksek ödül. Oyuncu bir gerilla fikri kartı seçer (ör. "Dev ayak izleri", "Kaldırıma 3D çizim", "Flash mob", "Duraklara yerleştirme", "Sahte ürün kuyruğu"). Her kartın:

```text
etki = kreatif_puan * kart.yaratıcılık * şehir_kalabalığı
risk_ceza = kart.risk * (1 − PR_yeteneği/150)       # belediye cezası, olumsuz basın
basın_haberi = rand() < 0.25 + 0.05*(puan_10−6)     # haber olursa PR sinerjisi devreye girer
```

## 9.4 TV, radyo, sinema

- **Prodüksiyon şart:** TV reklamı için film çekimi (prodüksiyon firması veya kendi stüdyon). Yönetmen seçimi (ünlü yönetmen = pahalı, kalite ↑), oyuncu/ünlü kullanımı, çekim günü sayısı.
- **Kuşak seçimi:** Sabah, gündüz, prime time (pahalı), gece. Hedef kitleye göre kuşak uyumu (Olgun → gündüz/akşam haberleri; Genç → gece/özel yayınlar).
- **Spot süresi:** 15/30/45/60 sn. Uzun spot = daha yüksek hatırlanma ama maliyet.
- **Radyo jingle:** Ses departmanı veya dış stüdyo. "Akılda kalıcı jingle" olasılığı (Copy + Ses yeteneği) → yıllarca marka bilinirliğine pasif bonus.
- **RTÜK benzeri kurul ("Yayın Kurulu"):** Cesur/provokatif tonda reklam durdurma riski — olay olarak.

## 9.5 Dijital performans: arama, display (GDN), sosyal, programatik

- **Teklif modeli:** CPM (bin gösterim), CPC (tıklama), CPA (dönüşüm). Oyuncu hedefe göre seçer; yanlış seçim verimi düşürür (Bilinirlik + CPA = kötü).
- **Hedefleme seviyesi:** Geniş / Dengeli / Dar. Dar hedefleme CTR'ı artırır ama erişimi kısar. 2024+ "çerezsiz dünya" dar hedeflemeyi zayıflatır.
- **A/B testi (Ölçümleme odağı):** Ölçümleme puanı yüksekse kampanya yayında kendini optimize eder: her hafta verim +%2–5.
- **Canlı panel:** Yayındaki dijital kampanyalarda oyuncu haftalık "bütçeyi kaydır" kararı verebilir (mini dashboard). Opsiyonel ama dijital çağın en eğlenceli kısmı olabilir.
- **Reklam yorgunluğu:** Aynı kreatif 4 haftadan uzun yayında kalırsa CTR düşer → "kreatif yenileme" görevi.
- **Sosyal medya hesabı yönetimi (retainer işi):** Aylık içerik paketi (ör. 12 post + 4 story). Topluluk yöneticisi gerekir; kriz anında hızlı yanıt mekaniği.

## 9.6 Influencer pazarlaması

| Özellik | Açıklama |
|---|---|
| Influencer havuzu | Prosedürel karakterler: takipçi sayısı, etkileşim oranı, niş (oyun, güzellik, yemek, spor, teknoloji, anne, mizah), kitle dağılımı (Y/E/O), ücret, güvenilirlik. |
| Kademeler | Nano (<10k), Mikro (10k–100k), Makro (100k–1M), Mega/Ünlü (1M+). Mikro'lar ucuz ve etkileşimi yüksek; mega'lar erişim için. |
| Sahte takipçi | Gizli "gerçeklik oranı". "Influencer Analitiği" Ar-Ge'si ile görünür olur. Sahte takipçili influencer = boşa giden bütçe. |
| Skandal riski | Her influencer'ın küçük bir skandal olasılığı; kampanya sırasında patlarsa müşteri memnuniyeti ↓, hızlı kriz yönetimi kararı (sözleşmeyi fesih / sessiz kal / açıklama yap). |
| Uzun dönem ilişki | Aynı influencer ile tekrar çalışınca indirim ve "samimiyet" bonusu; ileride kendi influencer ajansını kurabilirsin (geç oyun). |

## 9.7 Etkinlik & organizasyon

- **Etkinlik tipleri:** Ürün lansmanı, bayi toplantısı, basın toplantısı, festival standı, konser, kurumsal gala, roadshow, pop-up mağaza, deneyim alanı.
- **Kararlar:** Mekân (kapasite, prestij, fiyat), catering seviyesi, sahne/teknik (ses-ışık), sanatçı/sunucu, davetli listesi (basın + influencer → PR sinerjisi), ikram.
- **Riskler:** Hava durumu (açık hava), katılımın düşük olması, teknik arıza, ünlü gelmedi! Etkinlik ekibinin "Organizasyon" yeteneği riskleri azaltır.
- **Ek gelir:** Etkinlik prodüksiyon marjı (genellikle %15–25).
- **2020 "Büyük Kapanma":** Fiziksel etkinlikler 1 yıl kapalı → "online etkinlik" alternatifi açılır.

## 9.8 Sponsorluk ve ürün yerleştirme

Uzun süreli (sezonluk) sözleşmeler. Spor sponsorluğunda takımın performansı rastgele olaylarla marka algısını etkiler ("Sponsor olduğunuz takım şampiyon oldu! Bilinirlik +%8"). Dizi ürün yerleştirmede dizinin reytingi belirsizdir (dizi erken final yaparsa kayıp).

## 9.9 PR, kriz iletişimi ve sosyal sorumluluk

- Basın bülteni, basın gezisi, röportaj ayarlama. PR yeteneği yüksek çalışan "haber olma" ihtimalini artırır.
- **Kriz iletişimi hizmeti:** Müşterinin başı derde girdiğinde (ürün geri çağırma, sosyal medya linci) acil brief gelir: süre çok kısa, ücret yüksek, başarı = büyük güven artışı.
- **SSR projesi:** Uzun vadeli itibar; ödüllerde (özellikle "İyilik İçin" kategorisi) güçlü.

## 9.10 Ajansın kendi tanıtımı

Oyuncu kendi ajansı için de kampanya yapabilir (GDT'deki "kendi oyununu pazarlama"ya benzer): web sitesi, sektör dergisine ilan, ödül başvurusu, sektör etkinliğinde konuşma, "ajans showreel" videosu. Sonuç: itibar ve yeni müşteri akışı ↑.
