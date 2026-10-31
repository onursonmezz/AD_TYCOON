# 10 Tedarikçiler, matbaalar ve medya satın alma

## 10.1 Tedarikçi tipleri

| Tedarikçi | Ne sağlar | Önemli değişkenler |
|---|---|---|
| Matbaa | Broşür, katalog, afiş, kartvizit, ambalaj baskısı | Fiyat, kalite, teslim süresi, hata oranı, minimum adet, kapasite |
| Dijital baskı / branda | Billboard brandası, araç giydirme, stand, roll-up | Fiyat/m², dayanıklılık, montaj dahil mi |
| Açık hava medya şirketi | Billboard/raket lokasyonları | Lokasyon kalitesi, doluluk, dönemsel fiyat |
| TV/radyo kanalları (medya satıcıları) | Reklam kuşakları | Reyting, kuşak fiyatı, yıllık anlaşma indirimi |
| Prodüksiyon şirketi | Film çekimi, fotoğraf, animasyon | Yönetmen kalitesi, ekipman, fiyat/gün |
| Etkinlik tedarikçileri | Mekân, catering, ses-ışık, hostes | Kapasite, prestij, güvenilirlik |
| Influencer menajerlik | Influencer bağlantıları | Komisyon, havuz büyüklüğü |
| Dağıtım firması | El ilanı/broşür dağıtımı | Kişi başı ücret, verim (atılmadan ulaşma) |

## 10.2 Matbaa fiyat modeli

```text
birim_fiyat(ürün, adet, kalite, matbaa, yıl) =
      ürün.taban_fiyat * enflasyon(yıl) * kalite_çarpanı[Ekonomik 0.7 | Standart 1.0 | Premium 1.6]
    * matbaa.fiyat_çarpanı (0.8 .. 1.3)
    * (adet / 1000) ^ (−0.18)          # ölçek ekonomisi: 10x adet → birim fiyat ~%34 düşer
    * (1 − aktif_anlaşma_indirimi)

toplam = sabit_kurulum (kalıp, film/plaka) + birim_fiyat * adet
teslim_süresi = ceil( adet / matbaa.kapasite_haftalık ) + matbaa.sıra_bekleme
hata_olasılığı = matbaa.hata_oranı * (prova_yapıldı ? 0.3 : 1)
```

Örnek matbaalar (`data/suppliers.json`): Ucuzcu Ofset (ucuz, %8 hata, yavaş), Renkli Baskı A.Ş. (orta), Altın Varak Matbaacılık (premium, pahalı, %1 hata), Hızlı Dijital (küçük adet ucuz, büyük adet pahalı — dijital baskı mantığı).

## 10.3 Dinamik teklifler ve anlaşmalar ("baskı firmalarından gelen farklı fiyat anlaşmaları")

- **Gelen teklifler:** Rastgele aralıklarla gelen kutusuna teklif düşer: "Renkli Baskı: 3 ay boyunca 20.000 adet üzeri işlerde %18 indirim." / "Ucuzcu Ofset: Yıllık 100.000 adet taahhüt verirseniz %25 indirim (taahhüt tutmazsa ceza)."
- **Yıllık çerçeve anlaşma:** Hacim taahhüdü ↔ indirim. Oyuncu tahmin hatası yaparsa ceza öder (gerçekçi risk yönetimi).
- **Pazarlık mini oyunu:** Tedarikçinin gizli "minimum kabul fiyatı" var. Oyuncu 3 tura kadar karşı teklif verir; her turda reddedilme ve "ilişki bozulması" riski. İletişim yeteneği yüksek satın alma uzmanı bu aralığı daraltarak görmeyi sağlar.
- **İlişki puanı:** Zamanında ödeme, düzenli iş → öncelik ve indirim. Geç ödeme → fiyat artışı, kapasite önceliği kaybı.
- **Kriz olayları:** "Kâğıt fiyatları %40 arttı" (kur şoku), "Matbaa iflas etti, iş yarım kaldı".
- **Dikey entegrasyon (geç oyun):** Kendi baskı atölyeni kur (plotter → dijital baskı makinesi → ofset makinesi). Yüksek yatırım, uzun vadede marj.

## 10.4 Medya satın alma

```text
tedarikçi_verimi_k = 1 + medya_satın_alma_yeteneği/400 + yıllık_anlaşma_indirimi + hacim_indirimi(toplam_yıllık_medya)
hacim_indirimi: ajansın yıllık medya hacmi büyüdükçe kanallardan daha ucuza alır (büyük ajans avantajı)
```

Geç oyunda "Kendi Medya Ajansın" (ayrı şirket) kurulunca tüm müşterilerin medyası tek elden alınır → büyük hacim indirimi + ayrı gelir kalemi.
