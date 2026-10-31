# 21 Sanat yönü ve yapay zekâ ile asset üretim hattı

## 21.1 Görsel stil (gönderdiğin bitki dükkânı referansına göre)

- **Kamera:** Sabit açılı izometrik-perspektif (≈ 35–45° eğim), 4 yöne 90° döndürme, yakınlaştırma. Ofisin bir duvarı/çatısı "kesik" görünür (dollhouse görünümü).
- **Şekil dili:** Yumuşak, hafif abartılı oranlar; yuvarlatılmış kenarlar; düşük-orta poligon ama pürüzsüz (low-poly değil, "stylized").
- **Malzeme:** El boyaması hissi veren dokular veya düz renk + hafif gradyan; az metal/yansıma.
- **Işık:** Sıcak öğleden sonra güneşi, yumuşak gölgeler, hafif ambient occlusion; gece sahnesinde sarı masa lambaları.
- **Palet:** Adaçayı yeşili, krem, sıcak ahşap, terrakota, hardal sarısı vurgular. (Bu PDF'in renkleri de bu paletten.)
- **Karakterler:** Chibi'ye kaymayan, hafif büyük kafalı stilize insanlar; çeşitli saç, ten, kıyafet. Döneme göre kıyafet (90'lar vatkalı ceket, 2010'lar hipster gözlük).
- **Çevre:** Ofisin dışında küçük bir sokak parçası: kaldırım taşları, ağaçlar, araba, yaya — ofis büyüdükçe çevre de değişir.
- **UI:** Yuvarlak köşeli paneller, krem zemin, yeşil başlıklar, büyük okunaklı ikonlar.

## 21.2 Stil İncili (Style Bible) — tutarlılığın anahtarı

AI araçlarıyla üretirken en büyük risk stil tutarsızlığıdır (her model başka bir oyundan gelmiş gibi görünür). Çözüm:

1. Önce 6–10 adet referans konsept görsel üret (görsel AI ile): ofis içi, masa, sandalye, karakter, bitki, bilgisayar. En beğendiğini "ana referans" seç.
2. Sabit bir prompt şablonu kullan ve dosyada sakla (`art/style_bible.md`):

   ```text
   [NESNE], stylized 3D game asset, cozy isometric management game style, soft rounded shapes,
   hand-painted look, warm sage green / cream / warm wood / terracotta palette, soft lighting,
   clean silhouette, single object, centered, plain light gray background, no text, no logo
   ```

3. Tüm 3D modelleri aynı ölçek referansına göre (1 birim = 1 metre; masa 0.75 m yükseklik) ve aynı doku çözünürlüğü (ör. 1024 px) ile dışa aktar.
4. Mümkünse tüm küçük objeler için tek bir ortak renk paleti dokusu (palette atlas) kullan: modellerin renklerini bu palete eşle → hem tutarlılık hem performans.

## 21.3 Asset üretim hattı

| Adım | Ne yapılır |
|---|---|
| 1) KONSEPT | Görsel AI (ör. Midjourney, ChatGPT görsel üretimi, Gemini görsel, Flux) → nesnenin ön/yan görünümlü temiz görseli (image-to-3D için en iyi girdi) |
| 2) 3D ÜRETİM | Image-to-3D AI (ör. Meshy, Tripo, Hunyuan3D, Rodin) → .glb indir. Basit nesnelerde birden fazla deneme yapıp en temizini seç. |
| 3) TEMİZLİK | Blender (ücretsiz): ölçek ve pivot (taban merkezde, yerde) · gereksiz poligonu azalt (Decimate) · bozuk yüzeyleri düzelt · doku boyutunu standardize et · gerekirse palet dokusuna geçir · glTF 2.0 (.glb) olarak dışa aktar |
| 4) KARAKTERLER | AI ile T-poz karakter → otomatik rig (Meshy/Tripo auto-rig veya Mixamo) → animasyonlar: yürüme, oturma, klavye yazma, telefonla konuşma, kahve içme, sunum yapma, sevinme, stresli kafa kaşıma, uyuklama |
| 5) GODOT'A ALMA | `assets/models/...` altına .glb koy → Godot otomatik içe aktarır → Claude Code sahneye yerleştirme ve collision/etkileşim kodunu yazar |
| 6) İKONLAR/UI | Görsel AI ile düz (flat) ikon seti, aynı prompt şablonuyla; SVG/PNG 256px |

> **Gerçekçi beklenti:** AI 3D araçları masa, sandalye, bitki, bilgisayar gibi statik objelerde çok iyi; karakterlerde ve animasyonda hâlâ temizlik gerekir. Karakter sayısını azaltmak için modüler karakter yaklaşımı öner: 2–3 temel gövde + değiştirilebilir saç/kıyafet/renk (Godot'da shader ile renk değişimi). Böylece 100 farklı çalışan 6–8 model ile üretilir.

## 21.4 Asset listesi (MVP için)

| Kategori | Öğeler | Adet |
|---|---|---|
| Ofis kabuğu | Duvar parçaları (düz, pencereli, kapılı), zemin (parke, halı, beton), tavan lambası, pencere | ~15 |
| Mobilya | Masa ×3 seviye, sandalye ×3, koltuk, toplantı masası, beyaz tahta, raf, dolap, kahve köşesi, su sebili | ~20 |
| Ekipman (dönemsel) | Tüplü monitör PC, Mac klasik, düz ekran PC, iMac tarzı, laptop, faks, telefon (kablolu/cep/akıllı), yazıcı, plotter, kamera | ~15 |
| Dekor | Bitkiler ×8 (saksılı, asma, büyük palmiye), posterler, ödül heykelcikleri, neon tabela, halı, kedi | ~20 |
| Karakterler | 3 temel gövde (kadın/erkek/nötr), 10 saç, 12 kıyafet (dönemsel), 12 animasyon | ~40 |
| Dış mekân | Sokak parçası, ağaç, bank, sokak lambası, araba, billboard (kendi kampanyalarının görseli burada görünür!) | ~12 |

> **Harika bir detay fikri:** Oyuncunun yaptığı kampanyaların "key visual"ları prosedürel olarak (şablon + marka renkleri + slogan) ofisin önündeki billboard'da ve ofis duvarlarındaki posterlerde görünsün. Bu, oyuncunun eserini dünyada görmesini sağlar.

## 21.5 AI araçları ve lisans

- Her aracın ticari kullanım şartlarını kullandığın planda kontrol et (çoğu ücretsiz planda ticari hak vermez veya sınırlar). Hangi asset'in hangi araçla, hangi planda üretildiğini `art/asset_log.csv`'ye kaydet.
- Steam, yayın formunda AI ile üretilmiş içerik beyanı ister; bu kayıt bu beyan için de gereklidir (Bölüm 28).
- Görsel AI'a gerçek marka logoları veya telifli karakterler ürettirme.
