# 6 Müşteriler (markalar) ve brief sistemi

## 6.1 Marka (müşteri) modeli

| Alan | Açıklama |
|---|---|
| Ad, logo, sektör | Prosedürel + el yapımı karışık. Ör. "Lezzetçi Köfte" (Fast Food), "Anadolu Oto" (Otomotiv), "Mavi Kart Bank" (Finans). İsim üretici: sektör bazlı ön/son ek listeleri. |
| Ölçek | Mahalle esnafı → Yerel → Ulusal → Çok uluslu. Yıllık reklam bütçesini ve beklentiyi belirler. |
| Yıllık reklam bütçesi | Ölçeğe ve ekonomiye göre; kriz yıllarında düşer. |
| Kişilik (gizli, keşfedilebilir) | Risk iştahı (muhafazakâr ↔ cesur), Detaycılık (revizyon sayısı), Ödeme disiplini (geç ödeme riski), Ego ("logoyu büyüt" olasılığı), Sadakat. |
| Memnuniyet (0–100) | Her teslim ve olaydan sonra güncellenir. 40 altı "risk", 20 altı müşteri ajansı bırakır veya ihaleye çıkar. |
| Güven (0–100) | Uzun vadeli ilişki; Account ekibi ve tutarlı başarı ile artar. Güven yüksekse müşteri tek bir kötü kampanyayı affeder. |
| Sözleşme tipi | Proje bazlı (tek iş), Retainer (aylık sabit ücret + yıllık iş paketi), Performans (KPI'ya bağlı prim), Medya komisyonu (medya harcamasından %). |
| Geçmiş | Yapılan kampanyalar, puanlar, kullanılan kombinasyonlar (tekrar cezası için). |

## 6.2 Brief (müşteri talebi)

Brief'ler gelen kutusuna düşer (e-posta/faks dönemine göre arayüz değişir: 1990'da faks kâğıdı, 2005'te e-posta, 2020'de Slack benzeri "Slak" mesajı — küçük ama nostaljik dokunuş).

| Brief alanı | Örnek / kurallar |
|---|---|
| Hedef (zorunlu veya serbest) | "Yeni ürünümüzü tanıtmak istiyoruz" → Ürün Lansmanı. Bazı brief'ler hedefi serbest bırakır (oyuncu seçer, risk/ödül). |
| Hedef kitle ipucu | "Üniversite öğrencilerine ulaşmak istiyoruz" (açık) veya "ürünümüzü herkes sever" (belirsiz → araştırma gerekir). |
| Bütçe | Ajans ücreti (fee) + medya bütçesi ayrı. Ör. Fee ₺40.000, medya ₺250.000. |
| Teslim tarihi | Hafta cinsinden. Kısa süre = yüksek ücret ama hata riski. |
| KPI hedefi | Erişim, etkileşim, satış artışı, bilinirlik yüzdesi. Aşılırsa prim. |
| Kısıtlar | "TV olmasın", "Sadece dijital", "Ünlü kullanmayalım", "Kurumsal renkler dışına çıkmayın". |
| Kampanya büyüklüğü | Küçük (ilan/broşür), Orta (çok kanallı), Büyük (360°), Mega (ulusal 360° + TV + etkinlik; AAA karşılığı, kilitli). |

## 6.3 Brief üretim algoritması

```text
her hafta:
    for marka in aktif_müşteriler:
        if rand() < marka.brief_sıklığı * mevsim_çarpanı(ay, sektör):   # ör. Ramazan/bayram, yılbaşı, okul açılışı
            yeni_brief(marka)

# Ajans dışından yeni potansiyel müşteriler:
p_yeni = 0.04 + itibar/1000 + ödül_bonus + networking_bonus
if rand() < p_yeni: gelen_kutusu += yeni_marka_teklifi()            # direkt iş veya pitch daveti
```

**Mevsimsellik:** Ramazan ve bayramlar (gıda, telekom, perakende yoğun), yılbaşı (perakende, e-ticaret), sevgililer günü (kozmetik, moda), yaz (turizm, içecek), okul dönemi (eğitim, kırtasiye), "Efsane Cuma" (2010 sonrası e-ticaret). Takvim kayan bayramları desteklemeli (veri dosyasında yıl→tarih listesi).

## 6.4 Müşteri memnuniyeti formülü

```text
Δmemnuniyet = 12*(kalite_puanı − marka.beklenti)/2
            + 10*clamp(KPI_gerçekleşen/KPI_hedef − 1, −1, +1)
            + (teslim_zamanında ? +4 : −6*gecikme_hafta)
            + (bütçe_aşımı ? −8 : 0)
            + account_ekibi_bonusu (0..+6)          # iletişim yeteneği
            − revizyon_turu_sayısı * marka.detaycılık * 1.5
            + uyum_bonusu (kişilik eşleşmesi: cesur marka + cesur kampanya = +5)

marka.beklenti = 5 + ölçek_seviyesi*0.6 + geçmiş_ortalama*0.3 + (yıl−1990)*0.02
```

Yüksek memnuniyet → bütçe artışı (yıllık +%10–30), yeni brief sıklığı, referans (yeni müşteri getirir). Düşük memnuniyet → ihale (pitch'e çıkarır, rakip ajanslar katılır), ödeme gecikmesi, müşteri kaybı.
