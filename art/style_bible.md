# Stil İncili (Style Bible)

Bu dosya, oyundaki her görselin aynı oyundan çıkmış gibi görünmesi için kurallar listesidir (GDD 21.1–21.2). Yeni bir şey üretmeden önce buraya bak.

## 1. Görünüş

- **Kamera:** Yukarıdan, yaklaşık 40° eğik bakan izometrik-perspektif. Oyuncu 4 yöne döndürür. Modelin her yönden güzel görünmesi gerekir; arkası boş bırakılmaz.
- **Şekil dili:** Yumuşak, yuvarlatılmış kenarlar; hafif abartılı oranlar (biraz tombul, biraz kısa). Gerçekçi değil, "stilize". Çok köşeli "low-poly" da değil.
- **Malzeme:** Düz renk + hafif gradyan ya da el boyaması hissi. Parlak metal, ayna, cam yansıması yok.
- **Işık:** Oyun ışığı kendisi verir. Modelin dokusuna gölge ya da ışık "boyama".

## 2. Renk paleti

Oyunun arayüzüyle aynı palet. Modellerin ana renkleri bunlara yakın olsun:

| Ad | Renk (hex) | Nerede |
|---|---|---|
| Adaçayı yeşili | `#5B7F67` | bitkiler, koltuklar, vurgular |
| Koyu adaçayı | `#3C5846` | gölgeli yeşiller |
| Krem | `#F5EEDC` | duvarlar, beyaz eşyalar |
| Sıcak ahşap | `#A67C52` | masalar, raflar, parke |
| Terrakota | `#C8664A` | saksılar, aksesuarlar |
| Hardal | `#D9A441` | lambalar, ödüller, küçük vurgular |
| Koyu metin | `#3B3530` | siyah yerine bunu kullan |

Saf siyah (`#000000`) ve saf beyaz (`#FFFFFF`) kullanma.

## 3. Ölçü ve yön kuralları (çok önemli)

Oyun modeli eşyanın kapladığı alana kendisi sığdırır. Yine de ölçü doğru olursa oranlar bozulmaz:

- **1 birim = 1 metre.**
- **Taban yerde:** Modelin en alt noktası Y = 0'da.
- **Ortada:** Model, X ve Z'de (Blender'da X ve Y'de) 0 noktasının etrafında ortalanmış olsun.
- **Ön yüz:** Blender'da modelin önü "Front" görünümünde sana bakmalı (−Y yönü). Oyun bunu güneye, kameraya bakan yön olarak kabul eder.
- **Referans boylar:** masa 0.75 m · sandalye oturağı 0.45 m · kapı 2.1 m · insan 1.6–1.8 m · tavan 2.6 m.
- **Doku çözünürlüğü:** küçük eşya 512 px, büyük eşya 1024 px. 2048'i geçme.
- **Poligon sınırı:** küçük eşya ≤ 3.000 üçgen, büyük eşya ≤ 8.000, karakter ≤ 15.000.

Her eşyanın oyundaki boyutu `data/furniture.json`'da yazar (`size` = taban, `height` = boy). `tools/model_check` aracı modelini bu ölçülerle karşılaştırır.

## 4. Sabit prompt şablonu (görsel AI için)

Her eşya için aynı şablonu kullan, yalnızca `[NESNE]` kısmını değiştir:

```text
[NESNE], stylized 3D game asset, cozy isometric management game style, soft rounded shapes,
hand-painted look, warm sage green / cream / warm wood / terracotta palette, soft lighting,
clean silhouette, single object, centered, front three-quarter view, plain light gray background,
no text, no logo
```

Eşyaya özel hazır prompt'lar: `art/prompts/items.md`.

## 5. Yapma

- Gerçek marka logosu, gerçek ürün adı, telifli karakter yok. Monitörde "Apple" logosu yerine düz bir şekil.
- Modelin içine yazı koyma: oyunun dili değişince yazı İngilizce kalır.
- Zemini, gölgeyi ya da arka planı modele dahil etme. Yalnızca eşyanın kendisi.

## 6. Dönem havası

Eşyalar döneme göre değişir (GDD 5):

| Dönem | Bilgisayar | Hava |
|---|---|---|
| 1990–1999 | Bej tüplü monitör, kalın kasa (PC-386) | Kahverengi ahşap, kâğıt yığınları, faks, kablolu telefon |
| 2000–2009 | Renkli, yarı saydam tüplü bilgisayar (Elmacık G4) | Açık renkler, CD'ler, ilk düz ekranlar |
| 2010–2019 | İnce, tek parça beyaz ekran (iMak) | Beyaz masalar, beton, bitkiler bol |
| 2020+ | Dizüstü + ikinci ekran (M-çip Pro) | Esnek masalar, kulaklıklar, sıcak tonlar |
