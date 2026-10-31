# 14 Yeni iş: pitch, rakip ajanslar, itibar

## 14.1 İtibar (Ajans Ünü)

```text
itibar (0–100), yavaş değişen bir değer:
  + kampanya puanı ≥ 8: +0.5 .. +2 (büyüklükle)
  + ödüller: kısa liste +1, bronz +2, gümüş +3, altın +5, Grand Prix +10
  + pitch kazanmak, ünlü müşteri, basında haber
  − puan ≤ 4: −1 .. −3; müşteri kaybı −2; skandal −5 .. −15
  − her yıl itibar 50'nin üstündeyse %3 sönümlenir (zirvede kalmak emek ister)
```

Ek olarak "uzmanlık itibarı" sektör ve kanal bazında tutulur (ör. "Otomotivde güçlü ajans", "Dijitalde uzman").

## 14.2 Pitch (ihale / sunum yarışması)

Büyük müşteriler ajans seçerken birden fazla ajansı yarıştırır. Pitch oyunun en heyecanlı anlarından biri olmalı.

1. **Davet:** Gelen kutusuna gelir veya oyuncu "ihale takibi" ile başvurur. Katılım ücretsizdir ama zaman ve ekip maliyeti vardır (bazı pitch'ler "katılım ücreti" öder).
2. **Hazırlık (1–4 hafta):** Pitch ekibi seçilir; kısa bir kampanya üretimi gibi çalışır (Strateji + Kreatif puan biriktirilir, prodüksiyon yok).
3. **Sunum mini oyunu (kart tabanlı, 2–3 dakika):** Müşterinin gizli tercihleri (risk iştahı, ton tercihi, bütçe hassasiyeti) "ipucu kartları" ile kısmen görünür. Oyuncu elindeki kartlardan 3 tur seçer:
   - **Açılış:** Pazar verisi / İçgörü hikâyesi / Esprili giriş
   - **Fikir:** Güvenli konsept / Cesur konsept / Dijital odaklı konsept
   - **Kapanış:** Fiyat avantajı / Ekibi tanıtma / Canlı demo

   Her kartın gücü hazırlıkta biriken S/K puanına ve sunumu yapan çalışanın İletişim statına bağlıdır. Müşterinin tepki baloncukları (gülümseme, kaş çatma) anlık geri bildirim verir.
4. **Rakip ajanslar** da arka planda puan üretir (gücü itibarlarına, ekiplerine bağlı).

```text
pitch_skoru = (S_hazırlık*0.4 + K_hazırlık*0.6) * kart_uyumu(müşteri_tercihleri) * (1 + itibar/200)
              * (1 + ilişki_bonusu) * fiyat_rekabeti(teklif_ücreti / ortalama_teklif)

kazanma_olasılığı = softmax( [pitch_skoru_oyuncu, rakip_1, rakip_2, ...] / sıcaklık )
Kaybedilen pitch'te bile: "Kısa listeye kaldınız" → itibar +0.5, aynı müşteriden ileride direkt teklif olasılığı ↑
```

## 14.3 Rakip ajanslar (yapay zekâ)

- 8–15 rakip ajans: her birinin adı, logosu, kişiliği (agresif fiyatçı, kreatif butik, dev network ajansı, dijital start-up), itibarı, büyüklüğü, uzmanlık sektörleri vardır.
- Rakipler zaman içinde büyür, küçülür, batar, birleşir; yeni rakipler doğar (dijital çağda çok sayıda küçük dijital ajans).
- **Sektör sıralaması:** Yıllık "En Kreatif Ajanslar" ve "En Büyük Ajanslar" listeleri (gelire ve ödüllere göre). Oyuncunun sırası önemli bir hedef.
- **Etkileşimler:** Çalışan transferi (onlar senden, sen onlardan), müşteri çalma, fiyat savaşı, satın alma teklifi (sen onları veya onlar seni!), ortak iş (konsorsiyum pitch).
- **Basitleştirme:** Rakipler tam simüle edilmez; aylık "güç skoru" güncellemesi ve olay üretimi yeterlidir (performans ve sadelik için).

## 14.4 Networking

Sektör etkinlikleri, iş yemekleri, dernek üyeliği (Reklamcılar Derneği parodisi), golf turnuvası (geç oyun). Networking puanı yeni müşteri tekliflerini ve pitch davetlerini artırır; CEO karakterinin zamanını harcar.
