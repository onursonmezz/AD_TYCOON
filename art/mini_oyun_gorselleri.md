# Mini oyunlar ve taslaklar için görsel listesi

Bu görseller iki yerde kullanılacak:

1. **Ekibin 3 taslağı:** Kreatif fazın sonunda oyun bu parçaları birleştirip üç ilan taslağı kurar. Taslakta arka plan, ürün görseli, efekt, marka rengi ve slogan bir araya gelir. Seçtiğin taslak ofis duvarında, sokaktaki billboard'da ve ödül töreninde görünür.
2. **Mini oyunlar:** Fazlar arasındaki 3–5 saniyelik oyunların parçaları.

Görsel gelene kadar oyun sade şekillerle çalışır. Her dosya geldikçe kendiliğinden yerini alır; hepsini birden göndermen gerekmez.

---

## 1. Genel kurallar (bütün görseller)

- **Biçim:** PNG.
- **Arka plan:** Ürün, efekt ve parçalarda **saydam**; arka plan görsellerinde dolu.
- **Yazı yok:** Görselin üstünde hiçbir harf, rakam ya da logo olmasın. Marka adı ve sloganı oyun kendisi yazar.
- **Gerçek marka yok:** Bilinen bir markanın şişesi, logosu ya da arabası olmasın. Hepsi uydurma ve "jenerik" görünsün.
- **Stil:** Oyunun genel havası: sıcak, yumuşak, el boyaması hissi, hafif tombul oranlar. Fotoğraf gibi gerçekçi değil, "stilize illüstrasyon". Renkler `art/style_bible.md` paletine yakın; saf siyah ve saf beyaz yok.
- **Tek nesne:** Ürün görselinde tek bir ürün ya da küçük bir grup (ör. köfte tabağı) ortada dursun, kenarlara değmesin.

**Klasör:** Hepsini `art/incoming/minigame/` altındaki dört klasöre koy:

```
art/incoming/minigame/products/
art/incoming/minigame/backgrounds/
art/incoming/minigame/effects/
art/incoming/minigame/props/
```

Dosya adları aşağıdaki tablolarda. Küçük harf, Türkçe karakter yok, boşluk yerine alt çizgi.

---

## 2. Ürün görselleri (sektör başına)

- **Ölçü:** 1024×1024, saydam arka plan, ürün ortada, kenarlarda boşluk.
- **Ad:** `product_<sektör>_<sıra>.png`. Örnek: `product_fast_food_1.png`, `product_fast_food_2.png`.
- **Adet:** Sektör başına en az 1, ideali 2–3. Üç taslağın birbirinden farklı görünmesi için 2–3 daha iyi.
- **Dönem farkı (isteğe bağlı):** Telefon, bilgisayar ve araba gibi dönemle değişen ürünlerde istersen dönem ekle: `product_telecom_1990_1.png`, `product_telecom_2020_1.png`. Dönemsiz dosya her yılda kullanılır.

| # | Sektör (dosya adı) | Oyundaki adı | Ürün önerileri |
|---|---|---|---|
| 1 | `fast_food` | Fast Food | köfte tabağı, hamburger, dürüm, patates kızartması kutusu |
| 2 | `packaged_food` | Gıda & Ambalajlı Ürün | makarna paketi, bisküvi kutusu, konserve, kahvaltılık kavanoz |
| 3 | `soft_drinks` | Alkolsüz İçecek | soğuk şişe (buğulu), kutu içecek, meyve suyu kutusu |
| 4 | `coffee_chain` | Kahve & Kafe Zinciri | köpüklü kahve fincanı, karton bardak, kruvasan + kahve |
| 5 | `automotive` | Otomotiv | aile arabası, küçük şehir arabası, SUV (jenerik) |
| 6 | `banking_finance` | Banka & Finans | banka kartı, kumbara, bozuk para yığını |
| 7 | `insurance` | Sigorta | şemsiye altında ev, kalkan, el içinde ev |
| 8 | `telecom` | Telekom & GSM | cep telefonu, sinyal kulesi, sim kart |
| 9 | `technology` | Teknoloji & Elektronik | dizüstü bilgisayar, kulaklık, televizyon |
| 10 | `fashion` | Moda & Tekstil | askıda ceket, elbise, kot pantolon katlı |
| 11 | `cosmetics` | Kozmetik & Güzellik | ruj, krem kavanozu, parfüm şişesi |
| 12 | `retail` | Perakende / Market | dolu market sepeti, alışveriş arabası, poşet |
| 13 | `ecommerce` | E-ticaret | kargo kutusu, ekranda sepet ikonu olan telefon |
| 14 | `tourism_hotel` | Turizm & Otel | bavul, plaj şemsiyesi, otel anahtarı |
| 15 | `airline` | Havayolu | uçak (jenerik), uçak bileti, valiz |
| 16 | `real_estate` | Emlak & İnşaat | anahtar, maket ev, apartman bloğu |
| 17 | `health_pharma` | Sağlık & İlaç | ilaç kutusu, şurup şişesi, vitamin kavanozu |
| 18 | `private_hospital` | Özel Hastane | stetoskop, kalp simgesi, hastane binası |
| 19 | `education` | Eğitim & Dershane/Okul | kitap yığını, okul çantası, mezuniyet kepi |
| 20 | `gaming_entertainment` | Oyun & Eğlence | oyun kolu, patlamış mısır, sinema bileti |
| 21 | `sports_apparel` | Spor & Spor Giyim | spor ayakkabı, forma, top |
| 22 | `energy_fuel` | Enerji & Akaryakıt | yakıt pompası, şarj istasyonu, güneş paneli |
| 23 | `home_appliances` | Beyaz Eşya & Ev Aletleri | çamaşır makinesi, buzdolabı, blender |
| 24 | `furniture_decor` | Mobilya & Dekorasyon | koltuk, lamba, bitki + sehpa |
| 25 | `luxury` | Lüks Ürünler | kol saati, mücevher kutusu, el çantası |
| 26 | `baby_kids` | Bebek & Çocuk Ürünleri | biberon, oyuncak ayı, bebek arabası |
| 27 | `pet_products` | Evcil Hayvan Ürünleri | mama torbası, mama kabı, oyuncak kemik |
| 28 | `ngo_foundation` | STK & Vakıf | uzanan eller, fidan, bağış kutusu |
| 29 | `public_municipality` | Kamu & Belediye | belediye binası, otobüs, park bankı |
| 30 | `mobile_startup` | Mobil Uygulama & Startup | ekranında uygulama olan telefon, roket |
| 31 | `b2b_software` | B2B Yazılım & Hizmet | grafikli ekran, sunucu, dişliler |
| 32 | `logistics` | Lojistik & Kargo | kamyon, koli yığını, forklift |
| 33 | `festival_music` | Festival & Müzik | gitar, sahne ışığı, festival bilekliği |
| 34 | `media_publishing` | Medya & Yayıncılık | gazete rulosu, mikrofon, dergi yığını |
| 35 | `crypto_fintech` | Kripto & Fintech | parlayan jeton, cüzdan uygulamalı telefon |

---

## 3. Arka planlar (6 adet)

İlanın zemini. Ürün ve slogan bunun üstüne gelir; bu yüzden **sade** olsun, ortası nispeten boş kalsın.

- **Ölçü:** 1536×1024 (yatay). Oyun bunu billboard için yatay, poster için dikey kırpar. Bu yüzden önemli bir şey kenarlarda olmasın.
- **Ad:** `bg_<ad>.png`.

| Dosya adı | Ne | Hangi işlere |
|---|---|---|
| `bg_sunny.png` | Sıcak turuncu-sarı gradyan, yumuşak güneş ışınları | yemek, içecek, yaz, indirim |
| `bg_street.png` | Bulanık şehir sokağı, sıcak akşam ışığı | otomotiv, moda, telekom |
| `bg_tabletop.png` | Ahşap masa üstü, yakından, arkası bulanık | yemek, kahve, kozmetik, ev |
| `bg_studio.png` | Krem stüdyo kâğıdı, yumuşak gölge | lüks, teknoloji, her şey (nötr) |
| `bg_nature.png` | Yeşil park ya da tepe, açık gökyüzü | sağlık, enerji, STK, turizm |
| `bg_night.png` | Gece, koyu lacivert, birkaç neon ışık lekesi | oyun, festival, fintech, startup |

İstersen iki tane daha: `bg_pattern.png` (pastel desenli kâğıt) ve `bg_sky.png` (bulutlu gökyüzü; havayolu, turizm).

---

## 4. Efektler (saydam)

Taslakları canlandıran küçük süsler. Ürünün çevresine ya da köşelere konur.

- **Ölçü:** 1024×1024, saydam.
- **Ad:** `fx_<ad>.png`.

| Dosya adı | Ne |
|---|---|
| `fx_confetti.png` | Renkli konfeti dağılımı (ortası seyrek) |
| `fx_sparkle.png` | Birkaç parıltı / yıldız ışıltısı |
| `fx_steam.png` | Sıcak yemek dumanı / buhar (beyazımsı, yumuşak) |
| `fx_starburst.png` | Yıldız patlaması rozeti, içi boş (oyun içine "%50" gibi yazı koyar) |
| `fx_rays.png` | Arkadan ışık hüzmeleri |
| `fx_splash.png` | Su ya da meyve suyu sıçraması |

İstersen: `fx_hearts.png` (uçuşan kalpler), `fx_leaves.png` (uçuşan yapraklar).

---

## 5. Mini oyun parçaları (saydam)

Bunların çoğunu kodla sade biçimde çizebilirim. Görsel gelirse daha güzel görünür. Yıldızlı (★) olanlar ilk prototip için gerekli.

- **Ad:** `prop_<ad>.png`, ölçü aşağıda.

| Dosya adı | Ölçü | Ne | Mini oyun |
|---|---|---|---|
| ★ `prop_newspaper_page.png` | 1024×1400 | Gazete sayfası; yazılar bulanık çizgiler, ortada **boş bir ilan kutusu** | Gazete: ilanı boşluğa yerleştir |
| ★ `prop_car_side.png` | 1024×512 | Yandan görünen jenerik araba | Billboard: araba geçerken tıkla |
| ★ `prop_road_strip.png` | 1536×512 | Yandan yol ve kaldırım şeridi, arkada boş billboard direği | Billboard sahnesi |
| `prop_phone_frame.png` | 600×1200 | Ekranı boş akıllı telefon çerçevesi | Sosyal medya: akışta gönderini yakala |
| `prop_film_frame.png` | 1024×768 | Boş film karesi çerçevesi (delikli şerit) | TV/sinema: sahneleri sırala |
| `prop_ribbon_scissors.png` | 1024×512 | Kırmızı kurdele ve makas | Lansman / etkinlik: kurdeleyi doğru anda kes |
| `prop_city_map.png` | 1024×1024 | Yukarıdan sade şehir haritası (sokaklar, park, meydan) | Gerilla: kalabalık noktayı bul |
| `prop_jersey.png` | 1024×1024 | Önden boş forma | Sponsorluk: logoyu doğru yere bırak |
| `prop_people.png` | 6 ayrı dosya, 512×1024 | Siluet ya da sade figürler: `prop_person_young`, `_adult`, `_mature`, `_business`, `_kid`, `_family` | Strateji: hedef kitleyi bul |

Radyo ses dalgası için görsel gerekmiyor; kodla çizeceğim.

---

## 6. Hazır prompt şablonları

Kullandığın görsel aracına bunları yapıştırıp yalnızca **[KONU]** kısmını değiştir.

**Ürün görseli:**
```text
a single [KONU], stylized hand-painted illustration for a cozy management game, soft rounded shapes,
warm muted palette (sage green, cream, warm wood, terracotta, mustard), gentle soft lighting,
centered with empty margins, isolated on a transparent background, no text, no logo, no brand names
```

**Arka plan:**
```text
[KONU], soft blurred background for an advertising poster, stylized hand-painted illustration,
warm cozy palette, calm and simple composition with an open empty center for a product and a headline,
no text, no logo, no people in focus, 3:2 landscape
```

**Efekt:**
```text
[KONU], decorative effect element for an advertising poster, stylized hand-painted, warm cozy palette,
isolated on a transparent background, sparse in the center, no text
```

---

## 7. Öncelik (hepsini birden gönderme)

**1. tur, ilk prototip için:**
- `product_fast_food_1–3`
- `bg_sunny`, `bg_tabletop`, `bg_studio`
- `fx_confetti`, `fx_sparkle`, `fx_steam`
- `prop_newspaper_page`, `prop_car_side`, `prop_road_strip`

**2. tur:**
- En sık çıkan sektörlerin ürünleri: kahve, alkolsüz içecek, otomotiv, banka, telekom, perakende, moda, kozmetik.
- Kalan arka planlar ve efektler.

**3. tur:**
- Kalan sektörler ve mini oyun parçaları.

Gönderdiğinde bana "gönderdim" yazman yeterli; ben dosyaları kontrol edip (boyut, saydamlık, kenar boşluğu) oyuna bağlarım.
