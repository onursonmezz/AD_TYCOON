# Model üretim hattı: adım adım

Bu rehber bir eşyayı fikirden oyuna kadar götürür (GDD 21.3). **Kod yazman gerekmez:** doğru adlı `.glb` dosyasını doğru klasöre koyduğunda oyun onu kendisi kullanır. Dosya yoksa o eşya gri kutu olarak görünmeye devam eder; yani modelleri istediğin sırayla, tek tek ekleyebilirsin.

Önce `art/style_bible.md`'yi bir kez oku.

## Kısa yol: Blender betikleri (G3)

Basit eşyalar (masa, kitaplık, saksılar, duvar süsleri) konsept ve AI adımı olmadan, Blender'ın Python betikleriyle doğrudan üretilir:

```
"C:/Program Files (x86)/Steam/steamapps/common/Blender/blender.exe" --background --python tools/blender/build_all.py
```

- Yalnızca birkaçını üretmek için sona `-- --only=desk,plant_big` ekle.
- Betikler:
  - `tools/blender/common.py`: palet, yuvarlatılmış kutu ve silindir, dışa aktarma.
  - `tools/blender/models.py`: eşyaların ölçüleri ve parçaları.
  - `tools/blender/build_all.py`: hangi eşya hangi dosyaya yazılır.
- Bütün modeller tek bir renk atlası kullanır: `assets/textures/palette.png`. Yeni renk `common.py`'deki `PALETTE` listesinin **sonuna** eklenir.
- Sonra 5. adımdaki gibi Godot'da içe aktar ve `model_check` ile denetle.

## 0. Hangi dosya nereye?

Tüm modeller `assets/models/` altına gider. Dosya adı tablodaki gibi olmalı (küçük harf, Türkçe karakter yok).

| Klasör | Dosya adları | Ne |
|---|---|---|
| `furniture/` | `plant_small.glb`, `plant_big.glb`, `tea_urn.glb`, `filter_coffee.glb`, `espresso.glb`, `water_cooler.glb`, `whiteboard.glb`, `mood_board.glb`, `bookshelf.glb`, `record_player.glb`, `award_case.glb`, `neon_sign.glb`, `office_cat.glb` | İnşa modunda satın alınan mobilya ve dekor |
| `props/` | `desk.glb`, `chair.glb`, `counter.glb`, `meeting_table.glb`, `sofa.glb` | Odalarla kendiliğinden gelen eşyalar |
| `equipment/` | `pc386.glb`, `g4.glb`, `imak.glb`, `mchip.glb` | Masadaki bilgisayar, bilgisayar kuşağına göre |
| `street/` | `tree.glb`, `lamp.glb`, `bench.glb`, `billboard.glb` | Ofisin önündeki sokak |

Tam liste, ölçüler ve hazır prompt'lar: `art/prompts/items.md`. Oyunun bu adları okuduğu yer `data/furniture.json` (`model` alanı) ve `data/models.json`.

## 1. Konsept görsel (görsel AI)

1. `art/prompts/items.md`'den eşyanın prompt'unu kopyala (Midjourney, ChatGPT, Gemini ya da Flux).
2. 4–8 görsel üret. Şunlara bak:
   - tek nesne var, arka plan düz;
   - üç çeyrek açıdan (önden ve hafif yandan) görünüyor;
   - renkler palete yakın.
3. Beğendiğini `art/concepts/<dosya_adı>.png` olarak kaydet (ör. `art/concepts/plant_big.png`).

## 2. 3D'ye çevirme (image-to-3D AI)

1. Meshy, Tripo, Hunyuan3D ya da Rodin'e konsept görseli yükle.
2. Ayar varsa "stylized", "low/medium poly" ve "PBR kapalı / yalnızca renk" seç.
3. 2–3 deneme yap, en temizini **.glb** olarak indir.
4. `art/asset_log.csv`'ye bir satır ekle: hangi araç, hangi plan (ücretsiz/ücretli), tarih. Steam bunu soruyor.

## 3. Blender'da temizlik

Blender'ı aç, başlangıç küpünü sil (X), sonra:

1. **İçe aktar:** File → Import → glTF 2.0 → indirdiğin dosya.
2. **Ölçü:** N tuşu → sağdaki panelde Dimensions. Boyu (Z) `items.md`'deki boya getir. Oranı korumak için yalnızca bir sayıyı değiştir, sonra Scale'in üç değerini aynı yap.
3. **Taban yerde, ortada:**
   1. Modeli seç. Object → Set Origin → Origin to Geometry.
   2. Konumu (Location) 0, 0, 0 yap.
   3. Modeli Z'de yukarı kaydır (G, Z), ta ki en alt noktası kırmızı/yeşil çizgilerin olduğu zemine otursun.
   4. Object → Set Origin → Origin to 3D Cursor (imleç 0,0,0'da olmalı; değilse Shift+C).
4. **Yön:** Numpad 1 (Front görünümü). Eşyanın önü sana bakmalı; değilse R, Z, 90 (ya da 180) ile çevir.
5. **Dönüşümleri uygula:** Ctrl+A → All Transforms. Bu adım unutulursa oyunda model yanlış boyda çıkar.
6. **Poligon azaltma** (Overlays → Statistics açıkken üçgen sayısı sınırı aşıyorsa): Modifier → Decimate → Ratio'yu düşür (0.3–0.5), görüntü bozulmuyorsa Apply.
7. **Doku boyutu:** Image Editor'da dokuyu aç → Image → Resize → 512 ya da 1024.

## 4. Dışa aktarma

File → Export → glTF 2.0:

- **Format:** glTF Binary (.glb)
- **Include:** ✓ Selected Objects (önce modeli seç)
- **Transform:** ✓ +Y Up
- **Mesh:** ✓ Apply Modifiers
- **Animation:** kapalı (mobilya için)
- Dosya adı tablodaki gibi, kayıt yeri `assets/models/<klasör>/`.

## 5. Oyunda kontrol

1. Godot editörünü bir kez aç ve kapat. Godot yeni dosyayı içe aktarır; `.import` dosyası oluşur, onlara dokunma.
2. Model kontrol aracını çalıştır (terminal, proje klasöründe):
   ```
   godot --headless --script res://tools/model_check.gd
   ```
   Her model için ✓ ya da ⚠ yazar: boy beklenenden çok farklı mı, taban yerde mi, ortada mı, üçgen sayısı sınırda mı.
3. Görsel önizleme (pencere açar, her modeli 1 m'lik ölçü küpünün yanında PNG olarak kaydeder):
   ```
   godot --path . res://tools/model_preview.tscn -- --out=art/previews
   ```
4. Oyunu aç, eşyayı inşa modunda yerleştir, kamerayı 4 yöne döndürerek bak.

> Bu makinede `godot` yerine `C:/Users/osonm/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe` yaz.

## Sık sorunlar

| Belirti | Neden | Çözüm |
|---|---|---|
| Model yerin içine gömülü ya da havada | Taban 0'da değil | 3. adım: taban yerde |
| Model yan yatmış | Dönüşüm uygulanmadı ya da +Y Up kapalı | Ctrl+A All Transforms, dışa aktarmada +Y Up |
| Oyunda hâlâ gri kutu | Dosya adı ya da klasör yanlış | Tablodaki adı birebir kullan; model_check "bulunamadı" der |
| Renkler soluk ya da siyah | Doku dosyası .glb'ye girmemiş | Dışa aktarmada Materials: Export; Format .glb olmalı |
| Model çok parlak, plastik gibi | Metal/roughness değerleri | Blender'da malzemenin Metallic 0, Roughness 0.8–1.0 |

---

# Karakterler (modüler)

Çalışanlar parçalardan kurulur (GDD 21.3): **3 gövde** (kadın, erkek, nötr) + **saç** + **kıyafet**. Oyun her çalışana kimliğinden bir saç, kıyafet, ten, saç ve kıyafet rengi seçer. Kıyafet döneme göre değişir (90'larda vatkalı ceket, 2010'larda oduncu gömleği…). Model yokken çalışan renkli kapsül olarak görünür ve basit hareketler yapar.

## Kısa yol: Blender betiği (C1'den beri kullanılan)

Gövdeler, iskelet ve hareketler `tools/blender/characters.py` ile kodla üretilir; Mixamo ya da AI gerekmez:
```
"C:/Program Files (x86)/Steam/steamapps/common/Blender/blender.exe" --background --python tools/blender/build_all.py -- --only=body_female,body_male,body_neutral,hair_short
```
- Kemik adları sade: `hips`, `spine`, `chest`, `neck`, `head`, `upper_arm_l`, `forearm_l`, `hand_l`, `thigh_l`, `shin_l`, `foot_l` (sağ taraf `_r`). Oyun saçı `head` kemiğine bağlar (`data/characters.json` `head_bone`).
- **Renk için malzeme adları:** `skin` (ten), `outfit` (kıyafet), `hair` (saç). Bu adlı malzemeleri beyaz bırak; oyun rengini çalışana göre verir. Başka malzemeler (göz, ayakkabı, palet) olduğu gibi kalır.
- Hareketler `tools/blender/characters_anim.py`'de. Oturanlar (`sit`, `type`, `phone`, `present`, `cheer`, `stress`, `sleep`) kalçayı sandalye minderine indirir; `coffee` ve `cheer_stand` ayakta. Telefon ve kupa sağ ele bağlı `prop_phone` ve `prop_cup` kemiklerinde; kendi klipleri dışında ölçekleri ~0. Kontrol için: `godot --path . res://tools/pose_sheet.tscn --resolution 640x480 -- --out=<klasör>`.
- Aşağıdaki elle yol (Meshy/Mixamo) hâlâ çalışır; kemik adını `head_bone`'a yazman yeter.

## Dosyalar (`assets/models/characters/`)

| Dosya | Ne |
|---|---|
| `body_female.glb`, `body_male.glb`, `body_neutral.glb` | İskeletli gövde + **animasyonlar** (aşağıda) |
| `hair_<ad>.glb` | Saç: `short`, `bob`, `long`, `bun`, `curly`, `buzz`, `side_part`, `mullet` (90'lar), `man_bun` (2010+) |
| `outfit_<ad>.glb` | Kıyafet: `shoulder_pad_blazer` (90'lar), `pleated_suit`, `sweater_vest`, `denim_jacket`, `polo`, `office_shirt`, `cardigan`, `hipster_flannel` (2010'lar), `hoodie`, `oversize_tee` (2020+), `dress`, `tech_vest` |

Hangi saç ve kıyafetin hangi gövdeye ve yıllara ait olduğu `data/characters.json`'da yazar. Hepsini birden yapmana gerek yok. İlk deneme için bir gövde (`body_neutral.glb`), bir saç (`hair_short.glb`) ve bir kıyafet (`outfit_office_shirt.glb`) yeter; olmayan parça görünmez, gövde yine çalışır.

## 1. Gövde

1. **Konsept:** prompt şablonuna şunu koy: `a stylized office worker character, slightly big head, simple neutral clothes, T-pose, front view`. "Chibi"ye kaçmasın (kafa gövdenin ~1/5'i).
2. **3D:** Meshy/Tripo'da "character" ya da "T-pose" seçeneğiyle üret, .glb indir.
3. **Rig (iskelet):** [Mixamo](https://www.mixamo.com) (ücretsiz Adobe hesabı):
   1. Blender'da .glb'yi aç, File → Export → **FBX** yap.
   2. FBX'i Mixamo'ya yükle; çene, bilek, dirsek, diz ve kasık noktalarını işaretle.
   3. Kemik adları `mixamorig:Head` gibi olur. Godot içe aktarırken ":" işaretini "_" yapar (`mixamorig_Head`); oyun başı bu adla bulur. Bu yolu kullanırsan `data/characters.json` `head_bone` değerini `mixamorig_Head` yap.
4. **Animasyonlar:** Mixamo'da aynı karaktere şu animasyonları seç ve her birini **"Without Skin"** FBX olarak indir (ilki "With Skin"):

   | Oyundaki ad | Mixamo'da ara |
   |---|---|
   | `idle` | Idle |
   | `walk` | Walking |
   | `sit` | Sitting Idle |
   | `type` | Typing |
   | `phone` | Talking On Phone (Sitting) |
   | `coffee` | Drinking |
   | `present` | Talking / Presenting |
   | `cheer` | Cheering / Victory |
   | `stress` | Sitting Disbelief / Head Scratch |
   | `sleep` | Sitting Sleeping / Tired |

   | `cheer_stand` | Cheering (ayakta; yoksa `cheer` oynar) |

   Hepsi şart değil. Olmayan animasyonun yerine en yakını oynar (ör. `type` yoksa `sit`, o da yoksa `idle`). En az `idle` ve `walk` yap.
5. **Blender'da birleştirme:**
   1. Skin'li FBX'i içe aktar, sonra animasyonlu FBX'leri içe aktar.
   2. Animasyon FBX'lerinin iskeletlerini sil ama hareketlerini tut: Dope Sheet → Action Editor'da her hareket bir "Action" olarak kalır.
   3. Her Action'ı yukarıdaki tablodaki **oyundaki ada** yeniden adlandır (`idle`, `walk`…), yanındaki **F** (kalkan) düğmesine bas ki silinmesin.
6. **Ölçü ve yön:** Boy 1.7 m, ayaklar Y = 0'da, yüzü Front görünümünde (Numpad 1) sana baksın. Sonra Ctrl+A → All Transforms.
7. **Dışa aktar:** glTF Binary, ✓ Selected Objects (iskelet + gövde), ✓ +Y Up, Animation: ✓ açık, "Group by NLA Track" kapalı, "Export All Actions" ✓.

## 2. Saç ve kıyafet

Parçalar gövdenin üstünde, **doğru yerinde** modellenir ve gövdeyle aynı ölçüde, aynı başlangıç noktasıyla (0,0,0) dışa aktarılır.

- **Saç (sert parça):** Gövdeyi Blender'a al ve saçı kafanın üstüne yerleştir. Yalnızca saçı seçip dışa aktar. Oyun saçı baş kemiğine (`data/characters.json` `head_bone`) bağlar; baş dönünce saç da döner.
- **Kıyafet (bükülen parça):**
  1. Kıyafeti gövdenin üstüne giydir.
  2. Kıyafeti seç, sonra iskeleti Shift ile seç → Ctrl+P → **With Automatic Weights**.
  3. Kıyafeti iskeletle birlikte dışa aktar. Kıyafet gövdeyle birlikte bükülür.
  4. Kıyafeti olabildiğince açık gri ya da beyaz boya: oyun rengi kendisi verir (her çalışan farklı renk giyer).
- Saçı da beyaza yakın boya: rengini oyun verir.

## 3. Kontrol

- `model_check` karakterleri de listeler: gövdenin boyu, tabanı ve ortalaması denetlenir. Parçalar için yalnızca dosya ve üçgen sayısı (≤ 15.000) bakılır.
- Deneme karakterlerini görmek için ekran turu ya da şu komut (gövde olarak Godot şekilleriyle kurulmuş, iskeletli ve animasyonlu bir deneme kullanır):
  ```
  godot --path . res://tools/model_preview.tscn -- --out=art/previews --samples
  ```
