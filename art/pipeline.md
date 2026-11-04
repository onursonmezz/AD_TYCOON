# Model üretim hattı: adım adım

Bu rehber bir eşyayı fikirden oyuna kadar götürür (GDD 21.3). **Kod yazman gerekmez:** doğru adlı `.glb` dosyasını doğru klasöre koyduğunda oyun onu kendisi kullanır. Dosya yoksa o eşya gri kutu olarak görünmeye devam eder; yani modelleri istediğin sırayla, tek tek ekleyebilirsin.

Önce `art/style_bible.md`'yi bir kez oku.

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
