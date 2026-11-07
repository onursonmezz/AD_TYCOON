# Yapay zekâ ile model üretim rehberi (görsel AI → Tripo → oyun)

Bu rehber, oyunun görselliğini referans aldığımız sıcak ve detaylı "diorama" seviyesine taşımak için yazıldı. İş bölümü şöyle:

| Adım | Kim | Ne |
|---|---|---|
| 1. Görsel | Sen | Bu rehberdeki prompt'la bir görsel AI'da (ChatGPT, Midjourney, Gemini, Flux…) konsept görsel üretirsin. |
| 2. 3D | Sen | Görseli Tripo'ya yükleyip 3D model üretirsin ve indirirsin. |
| 3. Teslim | Sen | Dosyayı doğru adla `art/incoming/` klasörüne koyar, bana "gönderdim: …" yazarsın. |
| 4. Oyuna alma | Ben | Ölçü, taban, yön, üçgen sayısı ve doku boyutu ayarı, malzeme düzeni, oyuna bağlama, kontrol ve ekran görüntüsüyle karşılaştırma. |

**Blender açmana gerek yok.** `art/pipeline.md`'deki elle temizlik adımlarını (ölçüye getirme, tabanı yere oturtma, döndürme, üçgen azaltma) artık bir betikle ben yapacağım. Senin işin iyi bir görsel ve temiz bir 3D model bulmak.

---

## 0. Önce şunu oku: neden bu yol

Referanstaki görüntüyü güzel yapan üç şey var:
1. **Elle yontulmuş karakterler.** Akıcı gövde, yüz ifadesi, tutam tutam saç, kırışık giysi.
2. **Her yüzeyde doku.** Ahşap damarı, desenli duvar kâğıdı, kabartmalı taş.
3. **Dolu bir çevre.** Gür ağaçlar, komşu binalar, çit, çiçekler, rafları dolu bitkiler.

Benim kodla ürettiğim modeller düz renkli parçalardan oluşuyor; bu yüzden "oyuncak" gibi duruyorlar. Tripo ise görseldeki dokuyu ve şekli modele taşıyor. Hedefimiz **"aynı aileden"** görünmek; birebir kopya değil.

> **Telif:** Referans oyunun adını prompt'a yazma ve onun ekran görüntülerini görsel AI'a yükleme. Stil tarifini bu rehberdeki kelimelerle yapıyoruz. Stil tutarlılığı için kendi onayladığımız ilk görselleri referans olarak kullanacağız (bkz. 2.3).

---

## 1. Hazırlık (bir kez)

1. **Görsel AI:** Hangisini rahat kullanıyorsan. Görsel yükleyip "bu stilde" diyebildiğin bir araç işini kolaylaştırır (ChatGPT ve Midjourney'de var).
2. **Tripo:** tripo3d.ai hesabı.
   - **Lisans:** Ücretsiz ve ücretli planların ticari kullanım ve paylaşım kuralları farklı olabilir. Oyunu Steam'de satacağımız için **ticari kullanıma izin veren planı** seç ve şartları bir kez oku. Aynısını görsel AI için de yap.
   - Kullandığın planı söyle; `art/asset_log.csv`'ye ben yazarım. Steam bunu soruyor.
3. **Klasörler** (proje içinde):
   - `art/incoming/` → Tripo'dan indirdiğin modeller (git'e girmez, ham dosya).
   - `art/incoming/textures/` → 2D dokular (bölüm 6).
   - `art/concepts/` → beğendiğin konsept görseller (PNG). Bunlar depoya girer; neyi neden seçtiğimizi hatırlarız.

---

## 2. Görsel üretme kuralları

### 2.1 Tripo'nun sevdiği görsel

Tripo görseldeki **tek nesneyi** 3D'ye çevirir. Görsel ne kadar temizse model o kadar temiz olur.

| Yap | Yapma |
|---|---|
| **Yalnızca eşyanın kendisi:** boş masa, boş koltuk, boş raf | Üstünde ya da yanında bitki, kitap, defter, fincan, lamba, yastık, şal, havlu |
| Tek nesne, tamamı kadrajda, kenarlardan biraz boşluk | Kesilmiş kenar, kadraja sığmayan parça |
| Üç çeyrek açı: önden ve hafif yandan, biraz yukarıdan | Tam tepeden, tam yandan ya da alttan bakış |
| Düz, açık gri arka plan | Oda, zemin, masa üstü, bulanık arka plan |
| Yumuşak, eşit ışık | Sert gölge, parlak yansıma, gün batımı ışığı (dokuya "boyanır") |
| Kalın, okunaklı parçalar | Çok ince teller, kablolar, havada asılı parçalar |
| Mat yüzeyler | Cam, ayna, şeffaf ya da çok parlak metal |
| Yazısız yüzeyler | Logo, okunaklı yazı, marka |

**Neden boş:** Oyunda bilgisayar masaya, bitkiler ve diğer eşyalar ayrı ayrı yerleşir. Masa dolu gelirse bilgisayar kitapların içine girer; koltukta yastık olursa oturan çalışan yastığın içinde kalır. Kitaplık (kitaplar), ödül dolabı (kupalar), pano (fotoğraflar) gibi içeriği eşyanın kendisi olanlar istisna.

**Var olan görseli temizlemek:** Beğendiğin ama üstünde süs olan bir görseli baştan üretmen gerekmez. Görseli aynı sohbete yükleyip şunu yaz:

```text
Remove every object that is placed on or around the furniture: plants, books, notebooks, mugs, cups, lamps, pens, pillows, blankets, towels, jars and bottles. Keep the furniture itself exactly the same: same shape, proportions, colors, materials, camera angle, lighting and plain light gray background.
```

**İpucu:** Cam gereken yerde (ödül dolabı, su sebili şişesi) "frosted" (buzlu) ya da "solid pastel blue" (düz pastel mavi) iste. Tripo şeffaflığı iyi taşımaz.

### 2.2 Sabit stil bloğu (her prompt'a eklenir)

Her eşya prompt'unun **sonuna** bu iki bloğu aynen ekle:

```text
STİL:
stylized 3D game asset for a cozy top-down management game, soft rounded chunky shapes,
slightly exaggerated proportions, hand-painted textures with subtle wood grain and fabric detail,
warm muted palette of sage green, cream, honey wood, terracotta and mustard, matte surfaces,
soft even studio lighting, no harsh shadows

KADRAJ:
the bare item only, nothing placed on top of it or around it, no extra decorations or accessories,
single object, the whole object fully visible and centered, three-quarter view from slightly above,
plain light gray background, no floor, no cast shadow, no text, no logo, no watermark
```

Kısaltma: aşağıdaki tablolarda **[NESNE]** yazan kısmı başa koy, sonra STİL ve KADRAJ bloklarını ekle.

Örnek (masa):

```text
a chunky wooden office desk with a three-drawer cabinet on the right side, honey-colored wood with
visible hand-painted grain, rounded thick tabletop edges, brass drawer handles, a completely empty
flat tabletop with nothing on it, stylized 3D game asset for a cozy top-down management game, soft rounded chunky shapes,
slightly exaggerated proportions, hand-painted textures with subtle wood grain and fabric detail,
warm muted palette of sage green, cream, honey wood, terracotta and mustard, matte surfaces,
soft even studio lighting, no harsh shadows,
the bare item only, nothing placed on top of it or around it, no extra decorations or accessories,
single object, the whole object fully visible and centered, three-quarter view from slightly above,
plain light gray background, no floor, no cast shadow, no text, no logo, no watermark
```

### 2.3 Stil tutarlılığı (çok önemli)

Tek tek güzel ama birbirine benzemeyen eşyalar, sahneyi "hazır paket karışımı" gibi gösterir. Bunu önlemek için:

1. **Önce 3 "stil çapası" üret:** masa, saksı bitkisi ve sandalye. Her biri için 4–8 görsel üret, en beğendiğini seç.
2. Bu üçünü bana gönder (`art/concepts/` içine koy). **Birlikte onaylayalım.**
3. Sonraki her görselde bu üç görseli referans olarak yükle ve prompt'un başına şunu ekle:
   `Same art style, same rendering, same color palette and same level of detail as the attached reference images.`
   - **Midjourney:** stil referans parametresiyle (`--sref`) bu görsellerin bağlantısını ver.
   - **ChatGPT ve Gemini:** görselleri mesaja ekle.
4. Bir görsel stile uymuyorsa, ne kadar güzel olursa olsun kullanma.

### 2.4 Seçerken bak

- Siluet okunaklı mı? Yukarıdan bakınca ne olduğu anlaşılıyor mu?
- Arkası da tahmin edilebilir mi? Tripo görünmeyen tarafı uydurur; sade arka taraf daha iyi sonuç verir.
- Renkler palete yakın mı? Bkz. `art/style_bible.md` 2 ve `docs/art-direction.md` 3.2.

---

## 3. Tripo'da 3D üretme

> Tripo'nun arayüzü sık güncelleniyor; ayarların adı farklıysa en yakınını seç, emin olamazsan ekran görüntüsünü bana gönder.

1. **Image to 3D** seç, görseli yükle.
   - Aynı nesnenin önden, yandan ve arkadan görselleri varsa **multi-view** (çoklu görsel) seçeneğini kullan; arka taraf çok daha iyi çıkar.
   - Görsel AI'dan aynı nesneyi yandan ve arkadan çizmesini isteyebilirsin: `Same object, exact same design, seen from the back.`
2. **Ayarlar:**

   | Ayar | Değer | Neden |
   |---|---|---|
   | Model sürümü | En yeni | Daha temiz şekil |
   | Texture (doku) | **Açık**, varsa HD | Görselliğin yarısı dokuda |
   | PBR | Kapalı (yoksa önemli değil) | Mat, boyalı görünüm istiyoruz; parlama değil |
   | Quad | Kapalı | Oyun üçgen kullanır |
   | Face limit / Smart low-poly | Küçük eşya **3.000**, büyük eşya **8.000**, karakter **15.000** | Oyunda yüzlerce eşya ve 60 çalışan aynı anda çiziliyor |

   Düşük üçgen sayısı şekli çok bozuyorsa sınırı kaldırıp yüksek detaylı indir; azaltmayı ben yaparım. Dosya büyük olur ama sorun değil.
3. **Kontrol et** (Tripo'nun önizlemesinde modeli döndür):
   - Arka tarafta delik, erimiş ya da yamuk bölüm var mı?
   - Doku lekeli mi, renkler görseldekiyle aynı mı?
   - Nesnenin yanında arka plan parçası ya da zemin kalmış mı?
   - Kötüyse aynı görselle 1–2 kez daha üret ya da görseli değiştir.
4. **İndir: GLB.** (Karakterler için bölüm 5.4'e bak.)
5. Dosyayı `art/incoming/<dosya_adı>.glb` olarak kaydet. Ad, aşağıdaki tablolardaki gibi küçük harfli ve Türkçe karaktersiz olmalı.
6. Kullandığın konsept görseli `art/concepts/<dosya_adı>.png` olarak kaydet.
7. Bana yaz: **"gönderdim: desk, chair"**. Birden fazla dosyayı tek mesajda gönderebilirsin.

**Ölçü:** Tripo modeli rastgele boyda verir. Önemli değil, ben tablodaki ölçüye getiririm. Senin dikkat edeceğin şey **oran**: masa masaya, sandalye sandalyeye benzesin. Ölçüleri prompt'a yazmana gerek yok, ama nesne tablodaki tabana göre çok uzun ya da çok basıksa söyle.

---

## 4. Eşya listesi ve prompt'lar

Sütunlar: **Taban** = genişlik × derinlik (m), **Boy** = yükseklik (m). Oyun modeli bu kutuya sığdırır.
Önerilen sıra: önce **stil çapaları** (★), sonra en çok görünenler.

### 4.1 Odalarla gelen eşyalar

| Dosya adı | Taban | Boy | [NESNE] |
|---|---|---|---|
| ★ `desk` | 1.4 × 0.7 | 0.75 | a chunky wooden office desk with a three-drawer cabinet on the right side, honey-colored wood with visible hand-painted grain, rounded thick tabletop edges, brass drawer handles, a completely empty flat tabletop with nothing on it |
| ★ `chair` | 0.5 × 0.5 | 0.9 | a cushioned swivel office chair on five wheels, sage green fabric seat and backrest with soft stitching, dark metal base, no pillow, no blanket |
| `counter` | 3.0 × 0.6 | 1.2 | a small office kitchenette counter, cream cabinet doors and drawers with brass handles, honey wooden countertop with a built-in sink and a curved brass tap, the rest of the countertop completely empty |
| `meeting_table` | 2.4 × 1.2 | 0.75 | a long rectangular wooden meeting table with rounded corners and two thick trestle legs, a completely empty tabletop |
| `sofa` | 3.0 × 0.8 | 0.55 | a long low three-seat sofa with plump sage green seat and back cushions, short wooden legs, no throw pillows, no blanket |

### 4.2 Bilgisayarlar (masanın üstünde, ekranı oturan kişiye bakar)

| Dosya adı | Dönem | Taban | Boy | [NESNE] |
|---|---|---|---|---|
| `pc386` | 1990–99 | 0.45 × 0.45 | 0.40 | a chunky beige 1990s CRT computer monitor on a flat desktop case, a thick beige keyboard in front, slightly yellowed plastic |
| `g4` | 2000–09 | 0.45 × 0.45 | 0.42 | a rounded colorful teal all-in-one computer from the early 2000s with a white front bezel, a matching white keyboard in front |
| `imak` | 2010–19 | 0.55 × 0.18 | 0.45 | a thin white all-in-one desktop computer on a silver stand, plain screen without logo |
| `mchip` | 2020+ | 0.60 × 0.30 | 0.32 | an open silver laptop next to a small dark second monitor on a stand |

Ekranlar **koyu ya da düz renkli** olsun; üstünde yazı ya da arayüz olmasın.

### 4.3 Satın alınan mobilya ve dekor

| Dosya adı | Taban | Boy | [NESNE] |
|---|---|---|---|
| ★ `plant_small` | 0.5 × 0.5 | 0.7 | a small bushy potted plant with round leaves in a terracotta pot with a painted stripe |
| `plant_medium` | 0.8 × 0.8 | 1.1 | a medium leafy potted plant with long drooping leaves in a cream ceramic pot |
| `plant_big` | 1.0 × 1.0 | 1.6 | a tall monstera plant with big split leaves in a large terracotta pot |
| `bookshelf` | 1.5 × 0.5 | 1.9 | a tall wooden bookshelf full of colorful books, only books on the shelves |
| `whiteboard` | 1.5 × 0.5 | 1.6 | a rolling office whiteboard on a metal stand with colorful marker doodles and sticky notes, no readable text |
| `mood_board` | 1.5 × 0.5 | 1.6 | a standing cork mood board on wooden legs with pinned photos, fabric swatches and color cards |
| `water_cooler` | 0.5 × 0.5 | 1.3 | an office water cooler with a frosted pastel blue water bottle on top and a cream base |
| `tea_urn` | 0.5 × 0.5 | 1.0 | a shiny copper Turkish samovar tea urn standing on a small wooden cabinet |
| `filter_coffee` | 0.5 × 0.5 | 1.0 | a dark filter coffee machine with a glass pot standing on a small wooden cabinet |
| `espresso` | 0.5 × 0.5 | 1.0 | a retro cream espresso machine with chrome details standing on a small wooden cabinet |
| `record_player` | 1.0 × 0.5 | 0.9 | a vintage record player on a low wooden cabinet with a row of vinyl records |
| `award_case` | 1.0 × 0.5 | 1.8 | a tall wooden display cabinet with open shelves holding golden trophies, no glass |
| `neon_sign` | 1.0 × 0.5 | 1.2 | a pink neon tube sign shaped like a light bulb mounted on a small wooden stand, no text |
| `office_cat` | 1.0 × 1.0 | 0.5 | a fluffy orange cat curled up asleep on a round cream cushion |
| `hex_shelf` | 1.12 × 0.16 | 1.12 | three empty hexagonal wooden wall shelves arranged like a honeycomb, nothing inside, seen from the front |
| `wall_panel` | 1.24 × 0.06 | 1.0 | a decorative wooden slat wall panel, vertical honey-colored slats, seen from the front |

### 4.4 Sokak

| Dosya adı | Taban | Boy | [NESNE] |
|---|---|---|---|
| `tree` | 1.2 × 1.2 | 3.2 | a stylized leafy street tree with a dense rounded canopy made of many leaf clusters, a slim brown trunk |
| `lamp` | 0.3 × 0.3 | 3.0 | a classic dark green iron street lamp with a lantern top |
| `bench` | 1.5 × 0.5 | 0.8 | a wooden park bench with dark green cast-iron legs and armrests |
| `billboard` | 4.0 × 0.4 | 3.6 | a billboard frame on two steel posts with a small walkway and lamps, **a completely blank flat white panel** |

> **Billboard'un paneli boş olmalı.** Oyun, kampanyanın görselini panelin önüne kendisi koyar. Panel yaklaşık 3.6 × 2.0 m olmalı ve alt kenarı yerden 1.4 m yukarıda durmalı.

### 4.5 Yeni eşyalar: çevreyi doldurmak için (Faz 2)

Bunlar oyunda henüz yok; modeller gelince oyuna ben eklerim (yerleşim kodu ve veri). Ofisin etrafını referanstaki gibi doldururlar. Ad listesi kesin değil; önce 4.1–4.4'ü bitirelim.

| Dosya adı | Taban | Boy | [NESNE] |
|---|---|---|---|
| `plant_shelf` | 1.2 × 0.4 | 1.6 | a dark metal shelving unit with three wooden shelves full of small potted plants in pastel and terracotta pots |
| `hanging_plant` | 0.5 × 0.5 | 0.9 | a trailing pothos plant in a small hanging pot with macrame rope |
| `floor_lamp` | 0.5 × 0.5 | 1.7 | a cozy floor lamp with a warm cream fabric shade and a wooden pole |
| `rug_round` | 2.0 × 2.0 | 0.02 | a round woven rug with concentric sage green rings, seen from above |
| `fence` | 2.0 × 0.2 | 1.0 | a short wooden picket fence segment, weathered brown wood |
| `flower_bush` | 1.0 × 1.0 | 0.8 | a round flowering bush with small yellow and blue flowers |
| `hedge` | 2.0 × 0.6 | 0.9 | a neatly trimmed green hedge block with soft rounded edges |
| `street_planter` | 1.0 × 0.5 | 0.8 | a wooden street planter box full of colorful flowers |
| `bicycle` | 1.6 × 0.4 | 1.0 | a vintage city bicycle with a front basket, mint green frame |
| `neighbor_house_a` | 6.0 × 5.0 | 7.0 | a two-story narrow brick townhouse with a tiled dark green roof, white window frames, a shop window with an awning on the ground floor |
| `neighbor_house_b` | 6.0 × 5.0 | 8.0 | a three-story cream plaster townhouse with wooden shutters, flower boxes under the windows and a terracotta roof |

> Binalar Tripo'da zor çıkabilir: çok büyük ve düz yüzeyler bulanık doku alır. İlk denemeden sonra birlikte bakalım; gerekirse binaları ben basit şekillerle kurup bölüm 6'daki dokularla kaplarım.

---

## 5. Karakterler

### 5.1 Yaklaşım değişiyor: parça yerine bütün karakter

Şu anki sistemde her çalışan gövde, saç ve kıyafet parçalarından kuruluyor ve renkleri oyun veriyor. Tripo ise **saçı, kıyafeti ve yüzüyle tek parça, boyanmış** bir karakter üretir. Bu yüzden:

- Her karakter kendi saçı, kıyafeti ve teniyle **hazır bir kişi** olur. Çeşitliliği karakter sayısı sağlar.
- Dönemsel kıyafet korunur: her dönemin kendi karakter seti olur. Bir çalışanın görünüşü yıl değişince o dönemin setinden seçilir; bunu oyunda ben kurarım.
- Renkleri oyun değiştiremez. Bu yüzden ten rengi, saç ve kıyafet çeşitliliğini **listede baştan** dağıttım.
- Kurucuyu kıyafet rengi yerine başının üstündeki küçük bir rozetle ayırırım.
- Eldeki 11 hareket (yürü, otur, yaz, telefon, kahve, sunum, sevin, stres, uyukla…) korunur. Nasıl bağlanacağı ilk denemede (5.4) belli olacak.

### 5.2 Karakter prompt şablonu

Karakterde STİL ve KADRAJ blokları yerine bunu kullan; yalnızca **[KİŞİ]** kısmını değiştir:

```text
full-body stylized 3D character for a cozy management game, [KİŞİ],
natural adult proportions with a slightly large head, friendly simple face with big expressive eyes,
eyebrows and a small closed smile, hand-painted textures with soft fabric folds,
A-pose: standing straight, arms straight and angled 45 degrees down away from the body,
open hands with fingers together, legs slightly apart, feet flat on the ground, facing the camera,
front view, the whole body visible from head to shoes, soft even studio lighting,
plain light gray background, no floor, no cast shadow, nothing in the hands, no bag,
no text, no logo
```

**Neden A-pozu:** Kollar gövdeden ayrı olunca Tripo kolları gövdeye yapıştırmaz, iskelet de doğru oturur. Elde eşya olmasın: telefonu ve kupayı oyun kendisi veriyor.

**Arka görünüş:** Karakterde arka taraf önemli; kamera dönünce görünüyor. Beğendiğin görselden sonra şunu iste ve Tripo'da multi-view kullan:
`Same character, exact same outfit, hair and colors, seen from directly behind, same A-pose.`
Yandan görünüş de alabilirsen daha iyi.

### 5.3 Karakter listesi (24 kişi, dönem başına 6)

Dosya adı `char_<dönem>_<sıra>`. **Cinsiyet** sütunu oyunun çalışan cinsiyetine eşlemek için.

**1990'lar**

| Dosya adı | Cinsiyet | [KİŞİ] |
|---|---|---|
| `char_1990_01` | kadın | a woman in her 30s with medium brown skin and big curly dark hair, a mustard blazer with big shoulder pads over a cream blouse, a straight knee-length brown skirt, low brown heels |
| `char_1990_02` | erkek | a man in his 30s with light skin and a brown mullet haircut, a light blue shirt with a patterned burgundy tie, pleated beige trousers with suspenders, brown loafers |
| `char_1990_03` | kadın | a young woman with light skin and big permed auburn hair, an oversized cream knit sweater, high-waisted light blue jeans, white sneakers |
| `char_1990_04` | erkek | an older man with tan skin, a neat gray side-part, a gray mustache and round glasses, a brown tweed suit with a sage green tie, dark brown shoes |
| `char_1990_05` | erkek | a young man with dark brown skin and short black hair, an oversized faded denim jacket over a white t-shirt, baggy jeans, chunky white sneakers |
| `char_1990_06` | nötr | an androgynous young adult with light olive skin and a short black bob haircut, round glasses, a black turtleneck, long plaid trousers in sage and cream, black boots |

**2000'ler**

| Dosya adı | Cinsiyet | [KİŞİ] |
|---|---|---|
| `char_2000_01` | erkek | a young man with light skin and spiky gelled brown hair, an untucked blue striped shirt, khaki cargo pants, gray sneakers |
| `char_2000_02` | kadın | a young woman with light skin and long straight blonde hair with side-swept bangs, a fitted pastel pink cardigan over a white top, flared low-rise jeans, white sneakers |
| `char_2000_03` | erkek | a man with deep brown skin and a short buzz cut, a dark green polo shirt, beige chinos, chunky brown sneakers |
| `char_2000_04` | kadın | a woman with East Asian features and a high black ponytail, a white blouse under a black blazer, wide gray trousers, black flats |
| `char_2000_05` | nötr | a young adult with medium skin and shaggy chin-length brown hair, an oversized mustard hoodie with a simple shape print, baggy jeans, skate shoes |
| `char_2000_06` | kadın | a woman with dark brown skin and long braids tied back, a colorful terracotta and cream knee-length wrap dress, simple brown sandals |

**2010'lar**

| Dosya adı | Cinsiyet | [KİŞİ] |
|---|---|---|
| `char_2010_01` | erkek | a man with light skin, a man bun and a full ginger beard, a red and dark green flannel shirt with rolled sleeves, slim dark jeans, brown boots |
| `char_2010_02` | kadın | a young woman with light skin and an undercut with dyed teal hair, an oversized gray knit sweater, black skinny jeans, white sneakers |
| `char_2010_03` | erkek | a man with brown skin, a neat side-part and thick black-rimmed glasses, a mustard cardigan over a white button-up shirt with a small bow tie, rolled cream chinos, brown shoes |
| `char_2010_04` | kadın | a woman with tan skin and long wavy chestnut hair, a light denim shirt tucked into white jeans, tan ankle boots |
| `char_2010_05` | erkek | a young man with dark brown skin and a rounded afro, a sage green bomber jacket over a white tee, dark joggers, white sneakers |
| `char_2010_06` | kadın | a woman with medium skin wearing a soft pastel mint hijab, a long cream tunic, wide sage trousers, white sneakers |

**2020'ler**

| Dosya adı | Cinsiyet | [KİŞİ] |
|---|---|---|
| `char_2020_01` | kadın | a young woman with light skin and short pastel pink hair, an oversized lavender t-shirt, wide-leg beige cargo pants, chunky white sneakers |
| `char_2020_02` | erkek | a man with olive skin and short curly black hair, a puffy sage green vest over a long-sleeve cream shirt, dark gray joggers, sneakers |
| `char_2020_03` | nötr | a young adult with deep brown skin and a bleached blonde buzz cut, an oversized terracotta hoodie, wide black trousers, white sneakers |
| `char_2020_04` | kadın | an older woman with light skin and a silver bob haircut, round tortoiseshell glasses, a loose cream linen shirt, wide olive trousers, white sneakers |
| `char_2020_05` | erkek | a young man with East Asian features and fluffy black hair, wireless headphones resting around his neck, a mustard knit sweater vest over a white shirt, beige trousers, sneakers |
| `char_2020_06` | kadın | a young woman with medium brown skin and two space buns, an orange t-shirt under blue denim overall shorts, black and white canvas sneakers |

Önce yalnızca **`char_1990_01`** üret (ilk deneme). Gerisine 5.4'teki test bitince geçeriz.

### 5.4 İlk deneme karakteri: iskelet testi

Karakterin oyunda hareket edebilmesi için içinde bir iskelet (rig) olmalı. Tripo'nun kendi iskelet özelliği var. Ama bizim hareketlerimizle uyumlu olup olmadığını bilmiyoruz, ilk karakterde test edeceğiz.

`char_1990_01` için **üç dosya** gönder:

1. **İskeletsiz GLB:** normal indirme → `char_1990_01.glb`.
2. **Tripo iskeletli:** Tripo'da **Rig** (ya da "Auto Rig", "Animate") bölümünde insan (humanoid) iskelet seç. Hazır hareket eklemene gerek yok. **FBX** olarak indir (iskelet ve ağırlıklar dahil) → `char_1990_01_rig.fbx`. Aynı ekranda GLB seçeneği de varsa onu da indir → `char_1990_01_rig.glb`.
3. **Ekran görüntüsü:** Tripo'nun rig ekranının görüntüsü. Hangi seçenekler olduğunu görmek istiyorum.

Ben bunlarla iki yolu denerim:
- **(a) Tripo iskeleti:** Bizim hareketleri ona aktarırım.
- **(b) Kendi iskeletim:** İskeletsiz modele kendi iskeletimi otomatik yerleştiririm.

Hangisi temiz çalışırsa onu seçeriz. İkisi de olmazsa yedek yol **Mixamo** (ücretsiz Adobe hesabı); `art/pipeline.md` 1. bölümde anlatıldığı gibi. O durumda sana kısa ve ayrı bir tarif yazarım.

### 5.5 Karakter kontrol listesi (Tripo önizlemesinde)

- [ ] Kollar gövdeden ayrı mı? Parmaklar tek parça "eldiven" olabilir, sorun değil.
- [ ] Bacaklar ayrı mı? Etek ya da bol pantolon bacakları birleştirmemeli. Birleştirirse görseli değiştir: daha dar pantolon, kısa etek.
- [ ] Yüz düzgün mü? Göz ve ağız kaymamış olmalı.
- [ ] Arka taraf temiz mi? Saçın arkası, sırt.
- [ ] Saç başla bütün mü? Havada kopuk tutam olmamalı.

---

## 6. Dokular (2D, Tripo'suz)

Zeminler, duvarlar ve sokak, şu an kodla çizilmiş basit desenler kullanıyor. Gerçek dokular referansla aradaki en büyük ikinci fark. Bunları doğrudan görsel AI ile üret; Tripo gerekmez.

**Kurallar:**
- **1024 × 1024**, kare.
- **Tam tepeden**, düz bakış; perspektif yok.
- **Kendini tekrarlayan (seamless, tileable):** sağ kenar sol kenara, üst kenar alt kenara kusursuz bağlanmalı. AI bunu tam beceremezse sorun değil; kenarları ben birleştiririm.
- Gölge, ışık parlaması, nesne (sandalye, ayak izi…) yok.

**Şablon** (her dokunun sonuna ekle):

```text
seamless tileable texture, top-down flat orthographic view, hand-painted stylized game texture,
cozy warm muted colors, soft and even lighting, no shadows, no objects, no text, square 1:1
```

| Dosya adı (`art/incoming/textures/`) | Nerede | [DOKU] |
|---|---|---|
| `floor_planks.png` | çalışma alanı, dinlenme, ödül lobisi | honey-colored wooden floor planks with visible grain and thin dark gaps between planks |
| `floor_planks_dark.png` | yönetici odası (ileride) | dark walnut herringbone wooden floor |
| `floor_carpet.png` | toplantı, beyin fırtınası | soft sage green office carpet with a subtle woven texture |
| `floor_tiles.png` | mutfak, Ar-Ge | cream square ceramic floor tiles with light gray grout |
| `floor_concrete.png` | boş alan, stüdyo | smooth warm gray polished concrete with subtle speckles |
| `wall_leaves.png` | çalışma alanı duvarı | sage green wallpaper with a pattern of thin cream vines and small leaves |
| `wall_dots.png` | mutfak duvarı | cream wallpaper with small terracotta dots in a regular pattern |
| `wall_stripes.png` | toplantı duvarı | wallpaper with soft vertical stripes in sage and cream |
| `ground_grass.png` | çimen | lush stylized grass with small clover patches and tiny flowers |
| `ground_cobble.png` | kaldırım | gray and warm beige cobblestone pavement with rounded stones |
| `ground_asphalt.png` | yol | dark gray asphalt road surface with subtle cracks |

---

## 7. Teslim kontrol listesi (her model için)

- [ ] Ad tablodaki gibi (`desk.glb`, `char_1990_01.glb`…).
- [ ] Dosya `art/incoming/` klasöründe; konsept görsel `art/concepts/` klasöründe.
- [ ] Tripo önizlemesinde her yönden baktım; delik, leke, arka plan parçası yok.
- [ ] Doku açık, format GLB.
- [ ] Bana "gönderdim: …" yazdım. Varsa notum: "arkası biraz bozuk", "rengi soluk"…

Ben her teslimde şunu yapıp sana görüntü göndereceğim:
1. Ölçü, taban, yön, üçgen sayısı ve doku boyutunu ayarlarım; `assets/models/...` altına koyarım.
2. Ofis ışığında, eski modelin yanında önce/sonra görüntüsü çekerim.
3. Sonucu üç gruptan birine koyarım: **"tamam"**, **"yeniden üret: şu yüzden"** ya da **"görseli değiştir: şunu ekle"**.

---

## 8. Önerilen sıra

| Tur | Ne | Neden |
|---|---|---|
| 1 | ★ `desk`, `chair`, `plant_small` görselleri, **birlikte stil onayı** | Bütün oyunun görünüşünü bu üçü belirler |
| 2 | Bu üçünün 3D'si + `char_1990_01` (5.4 testi) | Tripo kalitesini ve iskelet yolunu erken görürüz |
| 3 | Dokular (bölüm 6) | Sahnenin en geniş alanları; az emekle büyük fark |
| 4 | Kalan ofis eşyaları (4.1–4.3) | Her ekranda görünenler |
| 5 | Karakterlerin geri kalanı (5.3) | 5.4'te seçilen yolla |
| 6 | Sokak ve Faz 2 (4.4, 4.5) | Çerçeveyi doldurur |

---

## 9. Sık sorunlar

| Belirti | Neden | Çözüm |
|---|---|---|
| Modelin altında gri bir plaka var | Görselde zemin ya da gölge vardı | KADRAJ bloğunu kontrol et ("no floor, no cast shadow"); görseli yeniden üret |
| Arka taraf erimiş gibi | Tek görselden üretildi | Arka görünüşü de üret, multi-view kullan |
| Doku bulanık | Nesne görselde küçüktü ya da çok büyük düz yüzey var | Nesneyi kadrajda büyüt; büyük düz yüzeylere desen iste (ahşap damarı, kumaş dokusu) |
| Renkler soluk ya da gri | Görselde sis ya da sert ışık vardı | "soft even studio lighting, saturated warm colors" ekle |
| Karakterin kolları gövdeye yapışık | Görselde kollar gövdeye değiyordu | A-pozu cümlesini koru; "arms clearly separated from the body" ekle |
| Ekranlarda ya da tabelada anlamsız yazı | AI yazı uydurur | "blank screen", "no text" vurgusu; olmazsa bana söyle, dokudan silerim |
| Stil diğerlerine benzemiyor | Referans görseller verilmedi | 2.3'teki stil çapalarını her seferinde ekle |

Takıldığın her yerde ekran görüntüsüyle sor. Yanlış dosya göndermenin zararı yok, ben kontrol etmeden hiçbir şey oyuna girmez.

---

## 10. Ana menü illüstrasyonu (2D, Tripo'suz)

Oyun açılışında, menünün arkasında duran tam ekran resim. Doğrudan görsel AI ile üret; menü sağ tarafta durduğu için resmin sağ kısmı sade olmalı.

- **Boyut:** 1920 × 1080 (16:9), PNG ya da JPG.
- **Kayıt:** `assets/ui/menu_background.png` (`.jpg` de olur). Oyun dosyayı görünce kendisi kullanır; yoksa koyu yeşil zemin.

```text
A cozy illustrated scene of a small advertising agency office corner at golden hour, seen from a slightly elevated
three-quarter view: a chunky wooden desk with a retro beige computer, a mug with a small star, pencils in a cup,
potted plants and trailing leaves, a big window with a warm city skyline at sunset, a megaphone and sticky notes on a
cork board, warm sage green walls, honey wood, terracotta and mustard accents, hand-painted stylized game art, soft
warm light, rich details on the left half of the image, the right 45% of the image calm and slightly darker (a plain
wall and soft window light) to leave room for a menu, no text, no logo, no people, wide 16:9 composition
```
