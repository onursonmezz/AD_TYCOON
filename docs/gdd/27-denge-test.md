# 27 Denge, test ve simülasyon

## 27.1 Bot stratejileri (balance_sim)

- **Rastgele bot:** Her şeyi rastgele seçer → oyunun "cezalandırma" seviyesini ölçer.
- **Bilgili bot:** Uyum tablolarını bilir, slider'ları ideal kurar → oyunun "tavan"ını ölçer.
- **Tekrarcı bot:** Hep aynı iyi kombinasyonu yapar → tekrar cezasının yeterliliğini ölçer (bilgili bottan belirgin şekilde kötü olmalı).
- **Açgözlü büyüme botu:** Sürekli işe alır, kredi çeker → ekonomik riskleri ölçer.

## 27.2 Hedef metrikler (başlangıç önerisi)

| Metrik | Hedef |
|---|---|
| Rastgele bot ilk 3 yılda iflas | %20–40 (ev odası dönemi gerilimli olmalı — GDT rehberindeki "bodrumda batıyordum" hissi) |
| Bilgili bot küçük ofise geçiş | Y2–Y3 |
| Bilgili bot plaza katına geçiş | Y12–Y16 |
| Bilgili bot ortalama puan | 7.0–8.5 (hep 10 değil!) |
| Tekrarcı bot ortalama puan | Bilgili bottan en az 1.5 düşük |
| Rastgele bot ortalama puan | Bilgili bottan en az 2.5 düşük (tablolar yeterince "keskin" mi?) |
| Rastgele kombinasyonların uyum çarpanı | Ortalama 0.93–0.97; en az %20'si 0.85'in altında |
| Bir oyun yılı gerçek süre (1x) | 10–15 dakika |
| İlk ödül | Bilgili bot Y5–Y8 |
| Nakit eğrisi | Dönem geçişlerinde kısa düşüşler (yatırım), uzun vadede üstel ama yavaşlayan büyüme |

> Not: M1 kabul kriterinde puan farkı "≥ 2", burada "en az 2.5" yazıyor; M1 için ≥ 2, M10 hedefi için ≥ 2.5 olarak okunur (bkz. `docs/decisions.md`).

## 27.3 İnsan playtest'i

- M2'den itibaren her taşta en az 2 kişiye oynat (biri reklamcı, biri tycoon oyuncusu ideal). Sessizce izle, nerede takıldıklarını not al.
- Oyun içi basit yerel telemetri (sadece oyuncunun kendi bilgisayarında, isteğe bağlı paylaşım): hangi ekranda ne kadar kaldı, ilk iflas yılı, kampanya puan dağılımı.
- Soru listesi: "En sıkıcı an neydi?", "Neyi anlamadın?", "Bir daha oynamak ister misin?", "Bu oyunu kime önerirdin?"
