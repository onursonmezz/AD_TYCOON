# 3 Referans oyun analizi

## 3.1 Game Dev Tycoon (GDT) — gönderdiğin rehberden çıkarılan algoritma

Gönderdiğin Steam rehberindeki tablolar GDT'nin kalbini gösteriyor. Bunu kendi oyunumuza "çevirmek" için önce mantığını yazıya dökelim:

| GDT kavramı | Nasıl çalışıyor | Ajans Tycoon karşılığı |
|---|---|---|
| Konu (Topic) × Tür (Genre) | Her konu-tür eşleşmesi +++ ile −−− arası bir uyum değerine sahip. İyi uyum skoru çarpar. | Sektör × Kampanya Hedefi (ör. Fast Food × Satış/Dönüşüm) |
| Hedef kitle (Y/E/M) | Konu ve platform başına kitle uyumu. | Hedef Kitle: Genç / Yetişkin / Olgun / Kurumsal (B2B) |
| Platform (PC, Playsystem…) | Tür × platform ve kitle × platform uyumu; platformların pazar payı yıllara göre değişir, lisans ücreti vardır. | Kanal / Mecra (billboard, TV, InstaFoto…) — çıkış yılı, yükseliş ve düşüş eğrisi, maliyeti var. |
| T/D oranı (Teknoloji/Tasarım) | Her türün ideal teknoloji/tasarım puan oranı var (Action 1.8, Adventure 0.4…). | S/K oranı (Strateji/Kreatif) — her kampanya hedefinin ideal oranı var. |
| 3 aşama × 3 slider | Engine, Gameplay, Story; Dialogues, Level Design, AI; World, Graphics, Sound. Tür başına önem (+++…−−−). | 3 faz × 3 odak: Strateji fazı, Kreatif faz, Prodüksiyon/Yayın fazı (Bölüm 7.4). |
| Puan = önceki en iyiye göre | İnceleme puanı mutlak değil; oyuncunun önceki en iyi oyununu geçmesi gerekir. Bu da sürekli gelişmeye zorlar. | Aynı mantık + "dönem beklentisi" (yıl ilerledikçe müşteri ve jüri beklentisi artar). |
| Tekrar cezası | Aynı tür/konuyu üst üste yapmak puanı düşürür. Bir yıl içinde devam oyunu yapmak cezalıdır. | Aynı sektör+hedef+kanal tekrarına "yorgunluk"; aynı müşteriye kopya kampanyaya "kendini tekrar" cezası. |
| Hata (bug), oyun motoru, araştırma | Bug'lar puanı düşürür; motor özellikleri tavanı belirler. | "Revizyon/hata" puanı (yazım hatası, yanlış ölçü, baskı hatası); yazılım/araç seti ve Ar-Ge tavanı belirler. |
| Ofis seviyeleri, AR-GE lab, donanım lab | Para + yıl + çalışan sayısı ile açılır. | Ev odası → küçük ofis → plaza katı → ajans binası → holding kampüsü. |
| Kendi konsolu, kendi fuarı, AAA oyun | Geç oyun hedefleri. | Kendi prodüksiyon evi, kendi medya ajansı, kendi ödül festivali, holding / satın almalar, global ağ. |

### Rehberden alınacak dersler ("yapma" listesinin ajans karşılığı)

1) Aynı sektör/hedefi üst üste yapma → yaratıcı yorgunluk. 2) Aynı müşteriye bir yıl içinde "aynı kampanyanın devamı"nı yapma → etki azalır. 3) Büyük bütçeli kampanyayı düşük seviye araç setiyle yapma (ör. 2015'te sadece "Kanvaz" ile TV reklamı) → tavan düşük. 4) "Mega kampanya"yı (AAA karşılığı) uzmanlaşmamış ekiple yapma → ağır ceza.

## 3.2 Mad Games Tycoon 2 (MGT2) — ne alıyoruz?

- **Oda inşası:** Oyuncu boş bir binaya oda çizer, oda tipini seçer (geliştirme, grafik, ses, kalite kontrol, motion capture, pazarlama, destek, sunucu, üretim) ve mobilya yerleştirir. Mobilya; çalışan motivasyonu, verim ve oda kalitesine etki eder. → Bizde: Kreatif stüdyo, toplantı odası, fotoğraf stüdyosu, kurgu odası, sunucu/veri odası, matbaa atölyesi vb.
- **Departman başına uzman çalışan:** Grafik ekibi grafik, ses ekibi ses üretir; görev odalara atanır. → Bizde de görevler departmanlara akar (Bölüm 11).
- **Fiziksel üretim / ürün stoğu:** MGT2'de oyun kutusu basımı ve stok yönetimi vardır. → Bizde: broşür/katalog baskısı, tedarikçi seçimi, adet ve depo.
- **Çok derin pazar ve yayıncı ilişkileri.** Rakip firmalar, satın almalar, hisse. → Holding ve satın alma sistemi.
- **Zayıf yanı:** Arayüz kalabalık, öğrenmesi zor. → Biz Sütun 1 (okunabilir derinlik) ile bundan kaçınıyoruz.

## 3.3 Startup Company — ne alıyoruz?

- **Bileşen üretim zinciri:** Çalışanlar küçük bileşenler (UI bileşeni, backend modülü) üretir; bunlar daha büyük modüllere birleşir. → Bizde: "ara çıktılar" (insight, slogan, key visual, storyboard, media plan) üretilir ve kampanyanın teslimatlarına birleşir (Bölüm 7.6, isteğe bağlı derin mod).
- **Yöneticilerin önemi:** Yönetici olmadan çalışanlar verimsiz kalır; yönetici sayısı ekip büyüklüğünü sınırlar. → Bizde Creative Director / Account Director kapasite limiti.
- **Mutluluk ve mobilya:** Masa, sandalye, bitki, kahve makinesi verimi etkiler. → Aynen alınır (bitkiler senin görsel referansınla da uyumlu).
- **Gerçek zamanlı akış:** Saat işler, oyun duraklatılabilir, hızlandırılabilir.

## 3.4 Bizim farkımız / "daha iyisi"

1. **Müşteri ilişkisi katmanı:** GDT'de oyunu satarsın ve biter. Bizde müşteri kalıcıdır: memnuniyet, güven, bütçe artışı, kaybetme riski. Bu "uzun vadeli ilişki yönetimi" türe yeni bir derinlik katar.
2. **Kampanya = çoklu kanal karışımı (media mix):** GDT'de tek platform seçersin; bizde bütçeyi birden fazla kanala dağıtırsın ve kanallar birbirini güçlendirir (sinerji) veya çakışır.
3. **Ölçülebilir sonuç:** Puanın yanında erişim, etkileşim, dönüşüm, ROI gibi gerçek pazarlama metrikleri. Gerçekçi ama sade.
4. **Pitch mini oyunu:** Yeni iş kazanmak için kısa, kart tabanlı sunum oyunu.
5. **Dinamik trendler:** Uyum tabloları sabit değil; dönemler ve trendler değerleri hafifçe kaydırır (ör. 2016'dan sonra Genç kitlede TV etkisi düşer).
6. **Bilgi defteri (Knowledge Book):** Oyuncunun keşfettiği uyumlar otomatik kayda geçer; rehbere ihtiyaç kalmaz ama keşif zevki korunur.
