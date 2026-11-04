# Sanat yönü (Art direction)

Bu belge oyunun görsel hedefini tarif eder. Hedefin ilhamı **Leafy Corner**'ın ekran görüntüleri (`C:\Users\osonm\Documents\reference\`, 11 adet) ve oynanış videosu. Amaç kopyalamak değil; aynı **sıcak, yumuşak, "minyatür diorama"** hissini reklam ajansı temasıyla kendi oyunumuza taşımak. GDD 21 ve `art/style_bible.md` ile birlikte okunur; çelişki olursa bu belge daha yenidir.

> Referans görüntüler başka bir oyuna ait ve telifli. Depoya girmezler; yalnızca bu bilgisayarda karşılaştırma için kullanılır.

---

## 1. Tek cümlede

**Sıcak öğleden sonra ışığında, yuvarlak hatlı, oyuncak gibi bir ofis dioraması. Etrafında yumuşak, nane-adaçayı tonlu, kalın kenarlıklı "şeker" arayüz.**

## 2. Referansta ne görüyoruz?

| Konu | Gözlem |
|---|---|
| Kamera | Yüksek izometrik-perspektif: ~50–55° aşağı bakış, 45° yan açı, dar görüş açısı (FOV ~30°). Neredeyse ortografik ama hafif derinlik var. Dükkân ekranın %70'ini kaplar, etrafında sokak ve bahçe "çerçeve" olur. |
| Işık | Tek, sıcak, sol üstten gelen güneş. **Uzun, yumuşak kenarlı gölgeler**, çok belirgin **ortam gölgelemesi** (köşeler, raf altları, saksı dipleri koyu). İçeride hafif sarı dolgu ışığı. Lamba ve ışık zincirleri hafif **parlar** (glow). |
| Atmosfer | Hafif **tilt-shift**: ekranın üst kenarı (ağaçlar, binalar) bulanık, odak dükkânda. Hafif vinyet. Renkler doygun ama "filmik" (ACES benzeri ton eşleme), siyahlar asla tam siyah değil. |
| Malzeme | Düz renk ağırlıklı, hafif el boyaması doku. Pürüzlü (mat) yüzeyler, neredeyse hiç parlama yok. Ahşap sıcak bal rengi, saksılar terrakota ve pastel, metal raflar koyu kömür. |
| Şekil | Her şey yuvarlak kenarlı (bevel), hafif tombul ve abartılı. İnce detay az, okunaklı siluet çok. |
| Duvar kesme | Kameraya bakan duvarlar alçak bir **"diz yüksekliği" bandı** olarak kalır. Bandın üstü kalın, **büyük yarıçapla yuvarlatılmış ahşap pervaz**. Dış köşeler keskin değil, ~0.5 m yarıçaplı kavisle döner. Arka duvarlar tam boy, içi desenli duvar kâğıdı. |
| Çevre | Dükkân bir sokağa oturur: taş kaldırım, çit, çimen, çiçekler, ağaçlar, binanın kendisi. Ortam "yaşıyor": yürüyen yayalar. |
| Karakterler | Hafif büyük kafalı, sade yüzlü stilize insanlar. Kıyafet tek renk bloklar. |
| Arayüz | Nane yeşili paneller, koyu yeşil kalın kenarlık, büyük köşe yarıçapı. Hap şeklinde düğmeler ve listeler, köşede kırmızı yuvarlak kapatma düğmesi. Simgeler büyük ve basit. Yazı tipi yuvarlak ve sevimli. |

## 3. Renk paleti

Referanstan örneklenip bizim paletimize (adaçayı, krem, ahşap, terrakota, hardal) uyarlandı. Arayüz için tek kaynak bu tablodur; UI kiti (`src/ui/theme/`) bu adlarla tanımlanır.

### 3.1 Arayüz

| Ad | Hex | Kullanım |
|---|---|---|
| `panel` | `#CDE8C7` | Panel gövdesi (nane) |
| `panel_light` | `#E4F3DF` | Liste satırı, iç kutu, ilerleme çubuğu boşluğu |
| `panel_header` | `#9DBFA4` | Panel başlık şeridi |
| `frame` | `#3F6B52` | Panel kenarlığı (4–6 px), koyu sekmeler |
| `frame_dark` | `#2E4F3D` | Gölge tarafı, koyu arka planlı kutular |
| `ink` | `#3A5646` | Ana metin (siyah yerine) |
| `ink_soft` | `#6D8A77` | İkincil metin |
| `on_dark` | `#F1F7EC` | Koyu zemin üstü metin |
| `accept` | `#8CCB52` | Kabul / onay (hap düğme) |
| `accept_dark` | `#5E9A34` | Kabul düğmesinin alt kenar gölgesi |
| `wait` | `#A3A7A4` | Bekle / nötr |
| `decline` | `#D2574A` | Ret, kapatma düğmesi, kötü haber |
| `gold` | `#F2C230` | Para rozeti, fiyat etiketi |
| `gold_dark` | `#C99A1C` | Para rozeti kenarı |
| `slate` | `#4E6A61` | İkon çubuğu düğmeleri, hız kontrolleri |
| `slate_hover` | `#5F7E74` | İkon düğmesi üstüne gelince |
| `toast` | `#DCEFD6` | Bildirim kartı |
| `shadow` | `#1E2E2540` | Panel gölgesi (yarı saydam) |

### 3.2 Dünya

| Ad | Hex | Kullanım |
|---|---|---|
| `wood` | `#C9A266` | Masa, raf, pervaz |
| `wood_light` | `#E0C38A` | Tezgâh üstü, açık ahşap |
| `wood_dark` | `#8A6440` | Parke, koyu ahşap |
| `wall_sage` | `#4F7A5C` | İç duvar (kreatif bölüm) |
| `wall_deep` | `#2F5A40` | Koyu duvar kâğıdı |
| `wall_cream` | `#EFE6D2` | Açık duvar (yönetim, toplantı) |
| `terracotta` | `#C8664A` | Saksı, vurgu |
| `mustard` | `#D9A441` | Lamba, ödül, vurgu |
| `charcoal` | `#3B3C40` | Metal raf ayağı, koyu zemin |
| `grass` | `#79AE45` | Çimen |
| `cobble` | `#6E6C78` | Taş kaldırım |
| `sun` | `#FFE2B8` | Güneş ışığının rengi |
| `ambient` | `#B9D3C2` | Ortam (gökyüzü) ışığının rengi |

## 4. Işık ve son işlem (Godot ayarları)

Hedef değerler; ekran görüntüsü döngüsüyle ince ayar yapılacak.

- **Güneş (DirectionalLight3D):** renk `sun`, enerji 1.6–2.0. Açı: −50° aşağı, 30–40° yan. Gölge açık. "Blur" 1.5–2.5 (yumuşak kenar), PSSM 2 bölüm, gölgenin bitiş uzaklığı ofise göre (40–60 m).
- **Ortam ışığı:** gökyüzü yerine renk, `ambient`, enerji 0.5. Biraz yeşilimsi soğuk dolgu, güneşin sıcaklığıyla kontrast yapar.
- **Ton eşleme:** Filmic ya da ACES, pozlama 1.0–1.1, beyaz 6.
- **SSAO:** açık, yarıçap 1.0–1.5, yoğunluk 2.0–2.5, güç 1.5. Köşe ve raf altlarındaki koyuluğun kaynağı bu.
- **SSIL:** açık, düşük yoğunluk (0.5–1.0). Duvardan zemine yeşil, ahşaptan sıcak renk sızması.
- **Glow:** açık, eşik 0.9–1.0, yoğunluk 0.4, karıştırma "soft light". Lambalar, ışık zincirleri, ekranlar parlasın, gerisi parlamasın.
- **Tilt-shift:** Kamera "DOF blur far" ve "near" ile, odak dükkânın ortası. Uzak bulanıklık yumuşak (miktar 0.05–0.08). Ekranın üst kenarı bulanık, alt kenarı hafif.
- **Renk düzeltme:** Doygunluk 1.05–1.1, kontrast 1.05. Gerekirse yeşilleri hafif sarıya kaydıran küçük bir renk eğrisi.
- **Vinyet:** Hafif (shader ya da CanvasLayer üstünde radyal gradyan).
- **Gece / akşam (ileride):** Güneş turuncuya döner ve kısılır, iç mekânda sarı lamba ışıkları ve ışık zincirleri öne çıkar.

## 5. Kamera

- Bakış açısı −50° (şu an −40°; daha yukarıdan bakılacak), FOV 30°.
- 4 yöne 90° döndürme (var).
- Yakınlaştırma sınırları: en yakında bir masa ekranın üçte birini kaplar, en uzakta sokak dahil ofisin tamamı görünür.
- Kaydırma, binanın 6 m dışına kadar (var).

## 6. Duvarlar ve bina

- **Kesik duvar:** Kameraya bakan dış duvarlar 0.35 m yerine **0.6–0.7 m** yüksekliğe iner. Üstünde 0.12 m kalın, 0.35 m genişliğinde, köşeleri yuvarlatılmış ahşap pervaz durur.
- **Dış köşeler:** Bina köşeleri 0.5 m yarıçaplı kavisle döner. Pervaz da kavisi izler.
- **Arka duvarlar:** Tam boy (2.6 m). Üst kenarında aynı pervaz, iç yüzeyinde duvar kâğıdı (oda türüne göre: çizgili, yaprak desenli, düz). Duvar kâğıtları ileride `data/` içinde seçilebilir olur.
- **Zemin:** Oda türüne göre parke (ahşap), karo (mutfak), halı (toplantı). Kenarlarda hafif koyu süpürgelik.
- **Dış:** Binanın kendisi (cephe, pencereler, kapı saçağı, tabela), sokak, kaldırım, çimen, çit.

## 7. Malzeme hissi

- Mat, `roughness` 0.75–0.95, `metallic` 0. Tek istisna metal raf ayakları (0.3).
- Ortak **palet dokusu**: Bütün basit modeller tek bir 256×256 renk atlası kullanır (`assets/textures/palette.png`, 16×16 renk karesi). Her yüzey bir renk karesine eşlenir: tutarlılık ve tek malzeme (performans).
- Yuvarlatılmış kenarlar (bevel) kenar ışığını yakalar; modellerde 2–3 segmentli, 1–3 cm bevel.
- Hafif "el boyaması" için palet dokusundaki karelerde çok hafif dikey gradyan (üst açık, alt koyu).

## 8. Arayüz şekil dili

- **Panel:**
  - Gövde `panel`, köşe yarıçapı **22 px**, kenarlık `frame` 5 px.
  - Altında 6–8 px aşağı kaymış yumuşak gölge.
  - Üstte 56 px'lik `panel_header` şeridi, ortalanmış BÜYÜK HARF başlık, iki yanında küçük yıldız ya da yaprak süsü.
- **Kapatma:** Panelin sağ üst köşesine taşan 40 px'lik yuvarlak `decline` düğmesi, beyaz ×, 3 px koyu kenar.
- **Düğmeler:**
  - Hap şeklinde (yarıçap = yükseklik/2), yükseklik 40–44 px.
  - Altında 3 px koyu "basılabilir" kenar; basınca bu kenar kaybolur ve düğme 2 px iner.
  - Renkler: **yeşil `accept` = kabul**, **gri `wait` = bekle / nötr**, **kırmızı `decline` = ret**. İkincil düğme `frame` zemin, `on_dark` yazı.
- **Liste satırı:** Hap şeklinde `panel_light` satır. Solunda koyu hap içinde sayı ve simge, sağda değer. Seçili ya da ödül alınabilir satır `accept` renginde.
- **İlerleme çubuğu:** Hap şeklinde; dolu kısım `accept` ya da `panel_header`, boşluk `panel_light`. İçinde sol yanda etiket, sağ yanda "9/25".
- **Sol dikey ikon çubuğu:** 64×64 px yuvarlak kareler (yarıçap 14), `slate` zemin, açık simge, aralarında 10 px. Seçili olan `accept`.
- **Sağ üst rozetler:** Para ve itibar. Solda büyük daire simge (para için `gold` üstünde ₺, itibar için yıldız), sağa doğru uzanan hap; değer büyük ve kalın.
- **Sağ alt:** "1998 · Ay 3" tarih hapı (`panel_header` zemin, beyaz yazı). Altında hız grubu: koyu `slate` hap içinde ⚙ · ⏸ · ▶ · ⏩.
- **Bildirim (toast):** Üst ortada `toast` kart, solda simge kutusu, başlık + alt satır. Yukarıdan kayarak gelir.
- **Diyalog balonu** (müşteri, olay): Geniş `panel_light` balon. Sol üstte koyu etiket ("MÜŞTERİ"), altında hap düğmeler sırası.
- **Simgeler:** Kalın, yuvarlak uçlu çizgi simgeler, tek renk. Kaynak: OFL ya da CC0 bir set (ör. Tabler Icons veya Phosphor "bold", MIT lisanslı), ya da özel çizim.

## 9. Yazı tipi

Ticari kullanıma açık, **SIL Open Font License (OFL)** lisanslı, yuvarlak fontlar:

| Rol | Öneri | Neden |
|---|---|---|
| Başlıklar, düğmeler, sayılar | **Fredoka** (Google Fonts, OFL) | Referanstakine en yakın yuvarlak, tombul, sevimli karakter; Türkçe karakterleri tam |
| Gövde metni | **Nunito** (OFL) | Yuvarlak uçlu, uzun metinde okunaklı, Türkçe tam |
| Alternatif | **Baloo 2** (OFL), **Quicksand** (OFL) | Daha oyunbaz (Baloo) ya da daha ince (Quicksand) |

Fontların lisans dosyası (`OFL.txt`) `assets/fonts/` altında fontun yanında durur ve oyunun "Katkıda bulunanlar" ekranında anılır.

## 10. Animasyon prensipleri

- **Pencere açılışı:** Ölçek 0.85 → 1.04 → 1.0 ve saydamlık 0 → 1, toplam ~0.25 sn (ease-out-back). Kapanış 0.12 sn'de hafif küçülüp kaybolma.
- **Düğme:** Üstüne gelince ölçek 1.05 (0.08 sn). Basınca 0.95, bırakınca hafif zıplayarak 1.0. Tık sesi.
- **Sayılar:** Para ve itibar değişince eski değerden yeniye 0.6–1.0 sn'de sayar, rozet bir kez "nabız" atar (ölçek 1.1). Artışta yeşil, azalışta kırmızı küçük sayı uçar.
- **Bildirimler:** Yukarıdan 0.3 sn'de kayar, 3–4 sn durur, yukarı kayıp kaybolur.
- **Dünya:**
  - Karakterler yürürken hafif zıplar, otururken nefes alır gibi hafifçe hareket eder.
  - Bitkiler çok hafif sallanır (rüzgâr shader'ı).
  - Yeni yerleştirilen mobilya küçükten büyüyüp yerine "oturur" (squash & stretch).
- **Genel kural:** Hiçbir şey anında belirmez ya da kaybolmaz; ama hiçbir animasyon oyuncuyu 0.3 sn'den fazla bekletmez.

## 11. Bizi Leafy Corner'dan ayıracak olanlar

- **Tema:** Bitkiler yerine reklam ajansı. Mood board'lar, beyaz tahtalar, maket kartonlar, kahve kupaları, bilgisayarlar, ödül vitrinleri. Duvarda bizim kampanya posterlerimiz, binanın önünde bizim billboard'umuz (var).
- **Dönemler:** 1990'ların bej bilgisayarları ve kahverengi ahşabı, 2010'ların beyaz-beton-bitki ofisi. Palet dönemle hafifçe değişir.
- **Renk:** Onların derin orman yeşili duvarları yerine bizde oda türüne göre krem, adaçayı ve sıcak tonlar karışık. Yeşil var ama tek renk değil.
- **Arayüz:** Aynı "şeker" şekil dili, ama vurgu rengi olarak terrakota ve hardal daha fazla.
