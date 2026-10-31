# 5 Zaman, dönemler ve teknoloji ağacı

## 5.1 Zaman birimi

- Oyun zamanı Yıl / Ay / Hafta (Y1 A1 H1) olarak ilerler. 1 ay = 4 hafta, 1 yıl = 12 ay = 48 hafta (GDT'deki gibi sadeleştirilmiş).
- Hız: Duraklat / 1x / 2x / 4x. 1x'te 1 hafta ≈ 3 saniye (ayarlanabilir sabit `SECONDS_PER_WEEK`).
- Simülasyon "tick" tabanlıdır: her gün (hafta/7) çalışan puan üretimi, her hafta ekonomi ve olay kontrolü, her ay maaş/kira/abonelik, her yıl vergi, festival ve dönem kontrolü.
- Başlangıç yılı varsayılan 1990; yeni oyun ekranında 1990 / 2000 / 2010 (hızlı başlangıç) seçilebilir. Oyun 2035 sonunda "final raporu" verir, isteyen sonsuz modda devam eder.

## 5.2 Dönemler

| Dönem | Yıllar | Yeni kanallar / araçlar | Dönem olayları |
|---|---|---|---|
| Klasik Çağ | 1990–1996 | Gazete, dergi, radyo, ulusal TV, özel TV kanallarının patlaması (1992+), billboard, raket/durak, broşür, el ilanı, katalog, POP malzemesi. Araçlar: fiziksel çizim masası, "SayfaUstası" dizgi yazılımı, fotokopi, faks. | Özel TV dönemi (TV reklam fiyatları düşer, talep artar), 1994 ekonomik kriz (müşteri bütçeleri −%30). |
| Web Şafağı | 1997–2004 | Kurumsal web sitesi, banner reklam, e-posta bülteni, CD-ROM katalog, SMS pazarlama (2001+), Gooble Kelime Reklamları (2002), forum/portal sponsorluğu. | "Dot-com balonu" (2000–01: dijital müşteriler batar), 2001 kriz. |
| Sosyal Doğuş | 2005–2010 | YouTüp video (2005), FaceBuk sayfa + reklam (2007), blog seeding, viral video, mobil uyumlu site, Cıvıl mikroblog (2008), display ağı (GDN karşılığı: "Gooble Görüntülü Ağ"). | 2008 küresel kriz, "Viral" mekaniği açılır. |
| Mobil Çağ | 2011–2016 | InstaFoto (2011, reklam 2015), mobil uygulama, programatik reklam, native içerik, influencer v1 (blogger), LinkedOut (B2B), e-ticaret entegrasyonu, retargeting. | "Reklam engelleyici" trendi (display etkisi −), veri gizliliği tartışması. |
| Video & Creator | 2017–2022 | TikTak (2018), Stories, canlı yayın, podcast reklamı, influencer pazarlaması (mikro/makro/mega), CTV (bağlı TV), AR filtreleri. | Büyük Kapanma (2020: etkinlik ve OOH çöker, dijital patlar), influencer skandalları. |
| Yapay Zekâ Çağı | 2023–2029 | AI görsel/metin araçları (prodüksiyon süresini kısaltır), retail media (market platformlarında reklam), kısa video ağırlığı, dijital billboard (DOOH), 3D anamorfik billboard, creator ekonomisi. | "AI'dan bıktık" tepki olayı (çok AI kullanan ajansın özgünlük puanı düşer), çerezsiz dünya (hedefleme zorlaşır). |
| Gelecek | 2030–2035+ | AR gözlük reklamları, hologram OOH, kişiselleştirilmiş dinamik video, sanal influencer, "nöro-pazarlama" laboratuvarı (spekülatif, eğlenceli). | Yeni mecraların riskli ama yüksek ödüllü olduğu "keşif" dönemi. |

> Not: Bu tablodaki bazı yıllar Bölüm 8.4 kanal tablosunun "Yıl" sütunundan farklı (ör. YouTüp 2005 / 2007, FaceBuk 2007 / 2008, Cıvıl 2008 / 2009, TikTak 2018 / 2019; DOOH 8.4'te 2012, burada Yapay Zekâ Çağı). Kanalın oyunda kullanılabildiği yıl için 8.4 esas alınır; buradaki yıllar platformun ortaya çıkışıdır (InstaFoto "2011, reklam 2015" örneğindeki gibi). Bkz. `docs/decisions.md` K-009.

## 5.3 Kanal yaşam eğrisi

Her kanalın bir pazar ilgi eğrisi (0–1) vardır: çıkış → yükseliş → zirve → olgunluk → düşüş. GDT'de konsolların pazar payının yıllara göre değişmesiyle aynı mantık. Kanalın etkinliği bu eğriyle çarpılır, maliyeti de talebe göre artar.

```text
ilgi(kanal, yıl)  =  piecewise_linear(kanal.curve, yıl)           # JSON'da [yıl, değer] noktaları

ör. "instafoto":     [[2011,0.15],[2013,0.5],[2016,0.95],[2022,1.0],[2028,0.75],[2035,0.55]]
"gazete":            [[1990,1.0],[2000,0.9],[2008,0.6],[2015,0.35],[2025,0.15],[2035,0.08]]
"billboard":         [[1990,0.9],[2005,1.0],[2020,0.8],[2035,0.7]]           # OOH dayanıklıdır
```

## 5.4 Yazılım ve araçların dönemsel evrimi

Gerçek ürün isimleri yerine parodi isimler (ayrıntılar Bölüm 12.5). Her aracın sürümleri yıllara göre çıkar; yeni sürüm verim ve kalite tavanını artırır, eski sürüm bir süre sonra "modası geçmiş" cezası verir.
