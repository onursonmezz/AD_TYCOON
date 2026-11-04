# Değişiklik günlüğü

## G3-B: Bütün eşyalar modellendi (2026-11-05)
- **Oyunda artık gri kutu yok** (karakterler hariç). 22 yeni model:
  - **Ofis:** tekerlekli sandalye, mutfak tezgâhı (evye, musluk, kettle), toplantı masası, kanepe.
  - **Bilgisayarlar, dönemine göre:** 90'ların bej tüplü monitörü, 2000'lerin renkli tombul bilgisayarı, 2010'ların ince beyaz ekranı, 2020'lerin dizüstü + ikinci ekranı.
  - **Satın alınanlar:** semaver, filtre kahve, espresso, su sebili, beyaz tahta, ilham panosu, pikap, ödül dolabı, neon ampul tabelası, minderde uyuyan ofis kedisi.
  - **Sokak:** ağaç, lamba, bank, billboard.
- 60 çalışanlı ofiste oyun rahat akıyor (567 FPS).
- Nasıl test ederim:
  1. Oyunu aç ve bir oyun başlat: masalarda dönemin bilgisayarı, önlerinde sandalyeler; mutfakta tezgâh; toplantı odasında masa.
  2. Sokağa bak: ağaçlar, lambalar, bank ve billboard. Kampanya bitince billboard'da görseli belirir.
  3. İnşa modunda kahve makinelerini, beyaz tahtayı, pikabı, neon tabelayı ve kediyi tek tek yerleştir.
  4. Yıllar geçtikçe (ya da başka dönemde başlayıp) masadaki bilgisayarın değiştiğini gör.
  5. Denetle: `godot --headless --import`, sonra `godot --headless --script res://tools/model_check.gd` ("29 model bulundu, 29 sorunsuz").
  6. `docs/screenshots/03_g3_world_default.png` ile `04_g3b_world_default.png`'yi karşılaştır.

## G3: Blender ile ilk modeller (2026-11-05)
- **Yeni 3D modeller** (gri kutuların yerine):
  - çekmeceli çalışma masası;
  - kitaplarla dolu kitaplık;
  - küçük ve büyük saksı bitkisi (orta boy da hazır, henüz satılmıyor).
- **Duvar süsleri:** Uzun duvarlarda posterlerin yanında altıgen petek raf ve çıtalı ahşap panel var. Duvar kameraya bakıp alçalınca gizlenirler.
- **Modeller kodla üretiliyor:** `tools/blender/` betikleri Blender'da çalışır ve `.glb` dosyalarını yazar. Ölçü ya da renk değiştirmek için betikteki sayıyı değiştirip yeniden çalıştırmak yeter.
- Bütün modeller tek bir renk atlası kullanır (`assets/textures/palette.png`).
- **Model kontrol aracı düzeltildi:** Gerçek bir model bulunca hata verip yine de "sorunsuz" diyordu.
- Nasıl test ederim:
  1. Oyunu aç, bir oyun yükle ya da başlat: masalar çekmeceli ahşap, saksılar terrakota, kitaplık renkli kitaplı.
  2. Duvarlara bak: posterin yanında bal peteği raf ya da çıtalı panel. Q/E ile döndür; kameraya bakan duvarda gizlenirler.
  3. İnşa modunda bir kitaplık ya da bitki yerleştir: yeni model görünür.
  4. Modelleri yeniden üret (proje klasöründe):
     `"C:/Program Files (x86)/Steam/steamapps/common/Blender/blender.exe" --background --python tools/blender/build_all.py`
  5. Denetle: `godot --headless --import`, sonra `godot --headless --script res://tools/model_check.gd` (7 model, 7 sorunsuz).
  6. `docs/screenshots/01_g1_world_close.png` ile `03_g3_world_close.png`'yi karşılaştır.

## G2: Yeni arayüz (2026-11-05)
- **Ofis artık tam ekran;** arayüz onun üstünde yüzüyor:
  - Solda dikey ikon çubuğu. Gelen kutusu ve kampanya ikonlarında kırmızı sayaç noktası var.
  - Sol altta kaydet, yükle, ayarlar ve ana menü.
  - Sağ üstte para ve itibar rozetleri, altında birkaç saniye sonra solan bildirim kartları.
  - Sağ altta tarih ve hız düğmeleri.
- **Ekranlar** sol tarafta yuvarlak köşeli, çerçeveli bir pencerede açılır; sağ üst köşedeki kırmızı ✕ ile kapanır.
- **Yeni görünüş:** adaçayı-krem paneller, hap düğmeler (kabul yeşil, bekle gri, reddet kırmızı), Fredoka başlıklar, Nunito gövde metni, Tabler ikonları.
- **Canlılık:** pencereler hafif zıplayarak açılır, düğmeler üstüne gelince büyür, para ve itibar sayarak değişir, para değişimi rozetin yanından yukarı süzülür.
- **UI kiti vitrini:** `tools/ui_kit_demo.tscn`. Bütün bileşenleri tek ekranda görürsün.
- Nasıl test ederim:
  1. Oyunu aç, yeni oyun başlat: ofis tam ekran, kenarlarda yüzen arayüz.
  2. Sol çubuktaki ikonlara tıkla: pencere zıplayarak açılır, kırmızı ✕ kapatır. Üstüne gelince ikonun adı çıkar.
  3. Bir kampanya bitir: para rozeti sayarak artar, yanından "+₺…" süzülür; sağda bildirim kartı belirip solar.
  4. Sağ alttaki hız düğmeleriyle oyunu durdur ve hızlandır.
  5. Ofis ekranından inşa moduna gir: inşa çubuğu altta, tarih düğmelerinin üstünde açılır.
  6. Editörde `tools/ui_kit_demo.tscn`'yi aç ve F6 ile çalıştır: bütün bileşenler ve "Pencere aç" animasyonu.
  7. `docs/screenshots/01_g1_ui_panel.png` ile `02_g2_ui_panel.png`'yi karşılaştır.

## G1: Işık ve atmosfer (2026-11-05)
- **Ofis artık sıcak bir öğleden sonra ışığında:** yumuşak ama belirgin gölgeler, köşelerde ve eşya diplerinde ortam gölgelemesi, sıcak renkler, hafif parlama.
- **Kamera** biraz daha yukarıdan bakıyor (−50°). Uzak kenarlar hafif bulanık (tilt-shift); ekran kenarlarında hafif kararma var.
- **Duvarlar:**
  - Kameraya bakan duvarlar diz hizasına iniyor.
  - Bütün duvarların üstünde yuvarlak uçlu ahşap pervaz var.
  - Bina köşeleri kavisli.
  - Duvarların iç rengi odaya göre değişiyor (çalışma alanı adaçayı yeşili, lounge terrakota…).
- **Zeminler desenli:** çalışma alanında parke, mutfakta karo, toplantıda halı. Çimen dokulu.
- **Ayarlar veri dosyasında:** `data/look.json`. Işık, renk ve duvar ölçüleriyle kod değiştirmeden oynayabilirsin.
- **Görsel karşılaştırma aracı:** `tools/screenshot.tscn`. Örnek bir ajansı sabit açılardan çekip `docs/screenshots/` altına kaydeder.
- Nasıl test ederim:
  1. Oyunu aç ve bir oyun başlat: ofis sıcak ışıkta, gölgeli ve desenli zeminli görünür.
  2. Q/E ile döndür: kameraya bakan duvarlar diz hizasına iner, pervaz da onlarla iner.
  3. `docs/screenshots/00_before_world_default.png` ile `01_g1_world_default.png`'yi yan yana aç.
  4. İstersen `data/look.json`'da `"sun"` → `"energy"` değerini değiştir, oyunu yeniden aç ve farkı gör.


## M10-A: Kredi, dört bot ve denge raporu (2026-11-04)
- **Banka kredisi** (Finans ekranı):
  - Ofisine ve itibarına göre bir üst sınıra kadar kredi çekebilirsin. Vade 6, 12 ya da 24 ay; yıllık %24 faiz, eşit aylık taksit.
  - Erken kapatabilirsin (%2 bedel).
  - Nakit eksiye düşünce oyun "kredi çekebilirsin" diye uyarır.
- **Denge simülasyonu dört botla** (GDD 27.1): rastgele, bilgili, tekrarcı (hep aynı kombinasyon) ve açgözlü (nakde bakmadan büyür, kredi çeker).
- **Denge raporu:** `docs/balance-report.md`. 1000 koşu × 10 yıl ve 200 koşu × 30 yıl, GDD 27.2 hedefleriyle ✓/✗ karşılaştırma, yıllara göre nakit, puan, ekip ve itibar tabloları.
- **Öneriler onayını bekliyor** (raporun sonunda, Ö1–Ö5). Oyunun dengesi bu adımda **değişmedi**.
- Nasıl test ederim:
  1. Oyunda **Finans** ekranını aç: "Banka kredisi" bölümünde üst sınırı, faizi ve aylık taksit önizlemesini gör.
  2. Tutar ve vade seçip **Kredi çek**: nakit artar, bölüm "Kalan borç · aylık taksit · kalan ay" gösterir. Her ay sonunda taksit düşer.
  3. **Erken kapat** ile krediyi bitir.
  4. `docs/balance-report.md`'yi oku: hedefler tablosu ve en alttaki öneriler.


## M9-C: İpuçları, İngilizce ve performans (2026-11-04)
- **İpucu balonları (tutorial):** İlk kampanyalar boyunca doğru anda kısa ipuçları çıkar ve ilgili düğmeyi sarı çerçeveyle gösterir: zaman kontrolleri, gelen kutusu, sihirbaz, faz kaydırıcıları, rapor, işe alım, kayıt, Ar-Ge, ofis, olaylar.
  - Oyunu durdurmazlar. "Anladım" ile geçilir, "İpuçlarını kapat" ile hepsi kapanır.
  - Ayarlar'dan yeniden açılabilir ya da baştan gösterilebilir.
- **Menü düğmesi:** Üst çubuktaki Kaydet, Ayarlar ve Ana Menü artık tek bir **Menü ▾** düğmesinde; içine **Yükle** de eklendi. İngilizcede çubuk taşıyordu.
- **İngilizce:**
  - Bütün metinler iki dilde de dolu (test bunu her seferinde denetliyor).
  - Yüzdeler dile göre yazılıyor: Türkçede "%55", İngilizcede "55%".
  - Ekranların hepsi İngilizce açılıp kontrol edildi.
- **Performans:** 60 çalışanlı en büyük ofiste 4x hızda ortalama 500+ FPS; 120 çalışanla 285 FPS (bu bilgisayarda). Ölçüm aracı: `tools/perf_check.tscn`.
- Nasıl test ederim:
  1. Yeni oyun aç: üstte "İpucu: Ajansına hoş geldin!" balonu çıkar ve Devam düğmesi sarı çerçeveyle işaretlenir. **Anladım**'a bas.
  2. İlk brief gelince Gelen Kutusu işaretlenir. Sihirbazı açınca bir ipucu daha çıkar.
  3. Bir balonda **İpuçlarını kapat**'a bas: başka balon gelmez. Ayarlar → "İpuçlarını baştan göster" ve "İpuçlarını göster" ile geri gelir.
  4. Ayarlar'da dili English yap: menüler, raporlar, olaylar İngilizce; rapordaki yüzdeler "55%" biçiminde.
  5. Üst çubukta **Menü ▾** → Kaydet / Yükle / Ayarlar / Ana Menü.
  6. Performans ölçümü (pencere açar, 20 sn sürer): `godot --path . res://tools/perf_check.tscn -- --staff=60`.


## M9-B: Ses, müzik ve canlı arayüz (2026-11-04)
- **Oyunun artık sesi var.** Düğme tıkı, bildirimler, ka-ching, alkış, olay uyarısı ve ofiste klavye uğultusu çalıyor. Hepsi kodla üretilmiş yer tutucular; gerçek ses dosyalarını `assets/audio/` altına koyduğunda onlar çalar (rehber: `assets/audio/README.md`).
- **Döneme göre sesler:** Bildirim 90'larda çağrı cihazı, 2000'lerde SMS, 2010'larda "ding". Yeni brief 90'larda faks, sonra e-posta sesiyle geliyor.
- **Müzik sistemi:** Her dönemin klasöründeki parçaları karışık çalar, parçalar arasında yavaşça geçer, dönem değişince müzik de değişir. Klasörler boş olduğu için şimdilik müzik yok.
- **Ofis ortamı:** Ekip büyüdükçe klavye uğultusu artar, oyun durunca kısılır.
- **Canlı arayüz:**
  - Para girince üst çubukta "+₺…" uçar.
  - Bildirimler kayarak gelir.
  - 8 ve üzeri puanlı raporda konfeti yağar.
  - Düğmeler üzerine gelince hafifçe büyür.
- **Ayarlar → Ses** kaydırıcıları artık gerçekten çalışıyor (genel, müzik, efekt, ofis ortamı).
- Nasıl test ederim:
  1. Oyunu aç, düğmelere bas: tık sesi gelir. Bir brief gelince faks sesi duyulur.
  2. Birkaç kişi işe al ve oyunu 1x'te çalıştır: hafif klavye uğultusu artar. Duraklatınca kısılır.
  3. Bir kampanya bitsin, fatura tahsil edilince "ka-ching" duyulur ve nakdin yanında "+₺…" uçar.
  4. 8 ve üzeri puan alınca raporda konfeti yağar ve fanfar çalar.
  5. Ayarlar → Efektler'i 0 yap: sesler susar.
  6. Yer tutucu sesleri tek tek dinlemek için: `godot --headless --script res://tools/export_sounds.gd`, sonra `art/sound_previews` klasöründeki dosyaları aç.


## M9-A: Kayıt slotları ve ayarlar (2026-11-04)
- **3 kayıt slotu + otomatik kayıt.**
  - Ana menüde **Devam Et** en son kaydı açar; **Yükle** slotları ajans adı, oyun tarihi, nakit, çalışan sayısı ve kayıt zamanıyla listeler.
  - Oyun her ay başında ayrı bir slota kendiliğinden kaydeder.
- **Ajans adı:** Yeni oyunda ajansına ad verebiliyorsun; boş bırakırsan "Ajansım".
- **Kaydetmeden çıkma uyarısı:** Ana menüye dönerken ya da pencereyi kapatırken son kayıttan beri oynamışsan "Kaydet ve çık / Kaydetmeden çık / Vazgeç" diye sorar.
- **Ayarlar** (ana menüde ve oyunun üst çubuğunda):
  - ses seviyeleri (genel, müzik, efekt, ofis ortamı);
  - dil;
  - arayüz ve metin boyutu (%90–%130);
  - tam ekran ve pencere boyutu;
  - otomatik kayıt, ipuçları;
  - günlük klasörünü açma.
- **Kısayollar:** F5 hızlı kayıt; Esc pencereyi kapatır; Boşluk duraklat; 1/2/3 hız.
- **Eski kaydın** olduğu gibi 1. slotta açılır.
- **Hata günlüğü:** `user://logs/` (Ayarlar → "Günlük klasörünü aç"). Bir sorun olursa en yeni dosyayı bana gönderebilirsin.
- Nasıl test ederim:
  1. Yeni oyun aç, ajansa bir ad ver. Biraz oyna, üst çubukta **Kaydet** → Slot 2 → **Kaydet**.
  2. **Ana Menü**'ye dön: kaydettiğin için soru gelmez. **Yükle** ekranında Slot 2'de ajans adını ve tarihi gör.
  3. Yükle, bir ay oyna, **Ana Menü**'ye bas: "Kaydedilmemiş ilerleme" sorusu gelir. **Vazgeç**.
  4. Bir ay (1x hızda) oyna, sonra ana menüdeki **Yükle** ekranında "Otomatik kayıt" satırını gör.
  5. **Ayarlar**'dan dili English yap: ekran İngilizce yeniden kurulur. Arayüz boyutunu %130 yap: her şey büyür.
  6. Oyunda F5'e bas: "Oyun kaydedildi" bildirimi gelir. Esc açık pencereyi kapatır.
  7. Pencerenin X'ine bas: kaydetmediysen soru gelir.


## M8-B: Modüler karakterler ve animasyon (2026-11-04)
- **Her çalışan artık kendine özgü görünüyor:** gövde (kadın, erkek, nötr), saç, kıyafet, ten, saç ve kıyafet rengi. Görünüş kayıttan kayda değişmez. Kurucu hardal renkli.
- **Dönemsel kıyafet:** 90'larda vatkalı ceket ve kumaş pantolon, 2010'larda oduncu gömleği, 2020'lerde kapüşonlu ve bol tişört. Yeni döneme girince çalışanlar dönemin kıyafetine geçer.
- **Etkinliğe göre hareket:**
  - Yürür, masada yazar (kampanya ekibi), telefonla konuşur (account, new business, PR, medya).
  - Mutfakta kahve içer, toplantıda sunum yapar.
  - Çok yorgunken uyuklar, tükenmişken stres yapar, seviye atlayınca sevinir.
- **Model yokken** çalışanlar artık renkli gövde, ten rengi baş ve saçla görünüyor; bu hareketleri basit sallanma, eğilme ve zıplamalarla yapıyorlar. Model gelince aynı durumlar gerçek animasyonlarla oynar.
- **Karakter üretim rehberi:** `art/pipeline.md` → "Karakterler". Konsept, Mixamo ile iskelet, 10 animasyonun adı, Blender'da birleştirme, saç ve kıyafeti gövdeye bağlama.
- Nasıl test ederim:
  1. Oyunu aç, birkaç kişi işe al: her biri farklı renkte kıyafet ve saçla görünür. Kurucu hardal renkli ve tepesinde küçük bir taç var.
  2. Bir kampanya başlat: ekip masada öne eğilip "yazar"; account çalışanı bazı günler başını yana eğip "telefonla konuşur".
  3. Enerjisi düşen çalışan mutfağa gidip kahve içer; çok yorgunsa masasında öne eğilip uyuklar.
  4. Çalışan seviye atlayınca ★ baloncuğuyla birlikte zıplar.
  5. Deneme karakterlerini görmek için `model_preview` aracını `--samples` ile çalıştır. `art/previews` içinde `character.body_*` resimleri çıkar.


## M8-A: Model sistemi, sokak ve kampanya görselleri (2026-11-04)
- **Model sistemi:** Ofisteki her eşya artık bir 3D model dosyası arıyor. Dosya varsa onu doğru boyuta sığdırıp kullanıyor, yoksa eskisi gibi gri kutu çiziyor. Model eklemek için kod gerekmiyor: doğru adlı `.glb`'yi `assets/models/` altındaki doğru klasöre koymak yeterli.
- **Sanat rehberi** (`art/`):
  - `style_bible.md`: stil, palet, ölçü ve yön kuralları, prompt şablonu.
  - `pipeline.md`: görsel AI → image-to-3D → Blender temizliği → dışa aktarma → oyunda kontrol, adım adım.
  - `prompts/items.md`: 26 eşyanın dosya adı, ölçüsü ve prompt'u.
  - `asset_log.csv`: Steam'in AI beyanı için kayıt.
- **Masalarda sandalye ve dönemsel bilgisayar.** Bilgisayar, ajansın bilgisayar kuşağına göre değişiyor. **Kuru bitkiler** kahverengiye dönüyor.
- **Sokak:** Ofisin önünde kaldırım, yol, ağaçlar, lambalar, bank ve bir **billboard**. Kamera sokağı görecek kadar dışarı kaydırılabiliyor.
- **Kampanya görselleri:**
  - Billboard'da yayındaki en yeni kampanyanın görseli: marka rengi, başlık, slogan.
  - Ofis duvarlarında en iyi işlerin posterleri; ödüllüler altın çerçeveli ve ★ işaretli.
- **Araçlar:** `tools/model_check.gd` (modelleri denetler) ve `tools/model_preview.tscn` (modelleri PNG'ye çizer).
- Nasıl test ederim:
  1. Oyunu aç: masalarda sandalye ve bilgisayar kutuları, ofisin önünde kaldırım ve ağaçlar görünür.
  2. Bir kampanya bitir ve yayına çıkmasını bekle. Kamerayı sağ tuşla sürükleyip ofisin sağ ön köşesinin ötesine kaydır: billboard'da kampanyanın adı ve sloganı yazar.
  3. Birkaç kampanya daha bitir. Kamerayı Q/E ile döndür: dış duvarların içinde posterler görünür.
  4. Deneme modellerini gör (terminalde, proje klasöründe):
     `godot --path . res://tools/model_preview.tscn -- --out=art/previews --samples`
     Ardından `art/previews` klasöründeki resimlere bak.
  5. Model denetimi: `godot --headless --script res://tools/model_check.gd`. Şimdilik her satırda "yok (oyunda gri kutu)" yazar. İlk modelini ekleyince ✓ ya da ⚠ görürsün.


## M7-C: Olaylar ve krizler (2026-11-04)
- **Olay sistemi:** Oynarken ara sıra bir olay penceresi açılır ve sen karar verene kadar oyun durur.
  - 7 kategoride 83 olay: müşteri, çalışan, prodüksiyon, kriz, fırsat, piyasa, ofis hayatı.
  - Bazı seçenekler bir yeteneği sınar (ör. "İletişim kontrolü · şans ~%62"). Sonuçta neyin değiştiği listelenir.
- **Kriz İletişimi araştırması:** Kriz olaylarında ★ işaretli ek bir seçenek açar ve şansı artırır.
- **Dönem olayları** tarihinde gelir:
  - 1994, 2001, 2008 krizleri: yeni işlerin bütçesi %25–30 düşer, 1 yıl sürer.
  - 2018 kur şoku.
  - Büyük Kapanma (2020): açık hava ve etkinlik çöker, dijital ve sosyal güçlenir.
  - Ayrıca özel TV, dot-com, Dünya Kupası, seçimler, veri kanunu, yapay zekâ.
- **Bitkiler:**
  - 3 hafta sulanmazsa susar, 5 haftada kurur. Kuru bitki konfor vermez.
  - Ofis ekranında "Bitkileri sula" düğmesi var. Ofis asistanı işe alırsan o sular.
- **Yazılım sertifikası** (Ekip ekranı): Ajansın bir alanda gerçek bir aracı varsa çalışanı o alanda sertifikalandırabilirsin. O alandaki üretimi +%10 olur.
- Kampanya raporunun memnuniyet dökümüne "Olaylar" kalemi eklendi.
- Nasıl test ederim:
  1. Yeni oyun aç ve birkaç ay oyna: bir olay penceresi açılır, oyun durur. Bir seçenek seç, sonuç satırlarını gör, Kapat'a bas; zaman devam eder.
  2. Yetenek kontrollü bir seçenekte şans yüzdesini gör. Kriz İletişimi araştırmasından sonra bir kriz olayında ★ seçeneği gör.
  3. Ofise bitki koy (inşa modu), 5 hafta bekle: Ofis ekranında "Kurudu!" ve oda kalitesinin düştüğünü gör. "Bitkileri sula" ile geri gelir.
  4. Araçlar'dan PixelShop'u al. Ekip ekranında bir çalışana Görsel alanında "Sertifika" ver; 2 hafta eğitimde kalır, sonra kartında "Sertifikalar: Görsel" yazar.
  5. Hızlı başlangıçla 1990'da başla ve Nisan 1994'e kadar oyna: kriz penceresi gelir, sonra gelen brief'lerin bütçeleri belirgin şekilde düşer.


## M7-B: Ar-Ge ve Bilgi Defteri (2026-11-04)
- **Ar-Ge ekranı** (sol menüde yeni):
  - araştırma puanı (AP), yürüyen araştırma;
  - 12 araştırma, her birinin AP, para ve süre bedeli ve koşulları (✓/✗).
  - AP her kampanyadan gelir (puan × iş büyüklüğü).
- **GDT gibi kilitler:** Oyunun başında ton ve kitle "otomatik" (nötr) ve tek kanal var.
  - Ton Seçimi (Y2), Hedef Kitle Analizi (Y3) ve Medya Planlama (Y3, çoklu kanal) araştırmayla açılıyor.
  - Dijital ve sosyal kanallar ile dijital pozisyonlar Dijital Departman (1998) ister; CPA teklif modeli Performans Pazarlama (2010) ister.
- **Diğer araştırmalar:** Pazar Araştırması, Fokus Grup (sihirbazda "fokus grup" düğmesi), Seri Kampanya, Sosyal Medya Yönetimi, Influencer Analitiği, Kriz İletişimi, AI Atölyesi.
- **Yeni odalar:** Ar-Ge lab (Strateji Direktörü gerekir, haftada +3 AP) ve prodüksiyon stüdyosu (Ar-Ge lab ve Prodüktör gerekir, Prodüksiyon +%10).
- **Bilgi Defteri:** Ar-Ge ekranının altında. Sektör seçince öğrendiğin hedef ve kitle uyumlarını (+++ … −−−) görürsün; bilinmeyenler "?". Pazar Araştırması varsa parayla bir hücre açabilirsin.
- **Hızlı başlangıç** 2000 ya da 2010'da dijital araştırmalar hazır gelir. Eski kayıtlar kilitlenmeden devam eder.
- Nasıl test ederim:
  1. Yeni oyun (1990) aç, bir brief kabul et: kitle ve ton "Otomatik (… araştırması gerekli)" yazar, en fazla 1 kanal seçilir.
  2. Birkaç kampanya bitir: raporda "Araştırma puanı +…" satırını gör. 2. yılda Ar-Ge → Ton Seçimi → **Araştır**; 2 hafta sonra bildirim gelir ve sihirbazda ton seçilebilir.
  3. 3. yılda Medya Planlama'yı araştır: sihirbazda "+ Kanal ekle" açılır.
  4. Ar-Ge ekranında Bilgi Defteri'ne in, kampanya yaptığın sektörü seç: kullandığın hedef ve kitlenin işaretlerini gör.
  5. 1998'den önce dijital kanalların listede olmadığını, Dijital Departman'dan sonra geldiğini kontrol et.

## M7-A: Dönemler ve araçlar (2026-11-03)
- **Araçlar ekranı** (sol menüde yeni). Beş alanın (Strateji, Metin, Görsel, Prodüksiyon, Ölçümleme) çarpanını ve araçlarını gösteriyor.
  - Al, güncelle, aboneliğe geç, aboneliği bitir.
  - Bilgisayarlar ve aylık abonelik gideri de burada.
  - Her alan ücretsiz bir başlangıç aracıyla ×1.0'dan başlıyor, araç aldıkça ×1.6'ya kadar çıkıyor.
- **Sürümler:** Yeni sürüm çıkınca bildirim geliyor; eski sürüm gitgide daha az verim veriyor.
  - Eski bilgisayarlar yeni sürümleri çalıştıramıyor (PC-386 → Elmacık G4 → iMak → M-çip Pro).
  - 2013'te büyük yazılımlar aboneliğe geçiyor: lisansın donuyor, aboneliğe geçersen hep güncel kalıyorsun ama her ay çalışan başına ödüyorsun.
- **AI araçları (2022+):** Çok verimli ama kampanyanın yenilik puanını düşürüyor; 2026'dan sonra daha da çok.
- **Dönemler:** Yeni bir döneme girilince (1997 Web Şafağı, 2005 Sosyal Doğuş …) o dönemin kanallarını ve araçlarını anlatan bir pencere açılıyor.
- **Başlangıç yılı:** Yeni oyunda 1990, 2000 ya da 2010 seçebiliyorsun.
- **Denge:** Dönem beklentisi biraz daha yavaş büyüyor (yılda %8.5 yerine %7.5). Bilgili bot 30 yılda plaza katına ulaşıyor, puanları 22. yıla kadar 6–8 arasında kalıyor.
- Nasıl test ederim:
  1. **Araçlar** ekranını aç: her alan ×1.00. 1990'da PixelShop'u al; Görsel'in ×1.15'e çıktığını ve nakdin düştüğünü gör.
  2. Birkaç yıl oyna: "PixelShop yeni sürümü çıktı" bildiriminden sonra satırda "1 sürüm geride" ve düşen çarpanı gör. **Güncelle**.
  3. 2000'den sonra bir sürüm "Bilgisayarların bu sürümü çalıştıramıyor" derse üstten Elmacık G4'ü al, sonra güncelle.
  4. Yeni oyunu 2010'dan başlat: 2013'te abonelik bildirimini gör, **Aboneliğe geç**, aylık giderin arttığını Finans'ta gör.
  5. 1996'nın sonunu geç: "1997: Web Şafağı başladı" penceresini gör.
  6. 2022'den sonra Hayalci AI'ı al. Görsel çarpanının arttığını, sonraki kampanyanın raporunda yeniliğin biraz düştüğünü (Puan dökümü) gör.

## M6-B: İnşa modu (2026-11-03)
- **Ofis penceresi:**
  - oda kalitesi dökümü (taban, konfor, çeşitlilik, kalabalık) ve üretim çarpanı;
  - etkin oda etkileri;
  - masa ve sandalye kalitesi (basit, ergonomik, 2005'ten ayarlanabilir);
  - **İnşa moduna geç** düğmesi.
- **İnşa modu:** Ofisin altında bir araç çubuğu açılıyor.
  - 13 mobilya: bitkiler, döneme göre kahve makinesi, su sebili, beyaz tahta, mood board, kitaplık, plak çalar, ödül vitrini, neon tabela, ofis kedisi.
  - Ofiste fareyle gezerken yeşil ya da kırmızı önizleme kutusu çıkıyor, tıklayınca yerleşiyor. R döndürür, Esc aracı bırakır.
  - "Kaldır / sat" aracı mobilyayı yarı fiyatına satar, çizdiğin odayı yıkar.
- **Oda çizme (büyütülmüş ofisten):** Gri boş alanda sürükleyerek kreatif atölye, toplantı, beyin fırtınası, mutfak, dinlenme ya da ödül lobisi yaparsın.
- **Oda etkileri:** toplantı odası müşteri memnuniyeti +2; beyin fırtınası odası Konsept +%10; mutfak enerji +%25; dinlenme odası tükenmişlik iyileşmesi +%50; ödül lobisi pitch +%5.
- Nasıl test ederim:
  1. **Ofis** penceresini aç, oda kalitesi dökümünü ve üretim çarpanını oku.
  2. **İnşa moduna geç**, "Küçük bitki" seç, ofiste gez: önizleme masaların ve duvarların üstünde kırmızı, boş yerde yeşil olur. Tıkla, nakdin düştüğünü ve üstteki oda kalitesinin arttığını gör.
  3. Bir kapının önüne büyük bitki koymaya çalış: "yolu kapatıyor" uyarısı çıkmalı.
  4. **Kaldır / sat** ile bitkiye tıkla: yarı parası geri gelir.
  5. Ofis penceresinden masaları **Ergonomik** yap, kalitenin arttığını gör.
  6. Büyütülmüş ofiste **Oda çiz** → "Beyin fırtınası odası" seç, gri zeminde sürükle. Ofis penceresinde "Konsept odağında +%10" etkisini gör.
  7. Küçük ofise taşındığında raporun memnuniyet dökümünde "+2.0 Toplantı odası" kalemini gör.

## M6-A: 3D ofis (gri kutu) (2026-11-03)
- **Ana ekran:** Ortada 3D ofis var. Menü ekranları ofisin üstünde pencere olarak açılıyor (✕ ya da aynı menü düğmesi kapatır).
- **Her ofis seviyesinin hazır binası:** ev odası (çaycı köşesi ve minder dahil), küçük ofis (toplantı odası, mutfak), büyütülmüş ofis, plaza, bina. Taşınınca yeni bina yükleniyor.
- **Kamera:** Fare tekerleği yakınlaştırır; sağ tuşla sürükleme, WASD ya da ok tuşları kaydırır; Q/E 90° döndürür. Kameraya bakan dış duvarlar alçalır (bebek evi görünümü).
- **Çalışanlar:** Departman renginde kapsüller masalarına yürüyor. İzindeyken görünmüyorlar, pitch hazırlığında toplantı odasına, yorgunken mutfağa gidiyorlar.
- **Baloncuklar:** Kampanyada çalışanların başında fazın harfi çıkıyor (S yeşil, K turuncu, T mavi); hata olunca kırmızı "!", seviye atlayınca "★".
- **Bilgi kartı:** Bir çalışana tıklayınca adı, unvanı, enerjisi, morali ve ne yaptığı görünüyor. "Ekip ekranında aç" düğmesi var.
- Nasıl test ederim:
  1. Yeni oyun aç: ortada ev odasını ve masanda oturan seni (sarı halkalı kapsül) gör.
  2. Tekerlekle yakınlaş/uzaklaş, sağ tuşla sürükle, Q ve E ile döndür. Döndükçe öndeki duvarların alçaldığını gör.
  3. Sol menüden bir ekran aç, ✕ ile ya da aynı düğmeyle kapat.
  4. Bir kampanya başlat, oyunu 1x'te oynat: başının üstünde S/K/T baloncuklarını gör.
  5. Kendine tıkla: bilgi kartını gör. Fazla mesaiyle enerjin düşünce mutfağa yürüdüğünü izle.
  6. Küçük ofise taşın: yeni binayı (toplantı odası, mutfak) ve yeni çalışanların kendi masalarına yürüdüğünü gör.
  7. Akıcılık ve kamera rahatlığı hakkında bana not yaz (bilgisayarına göre değişir).

## M5-B: Pitch (2026-11-03)
- **İhale davetleri:** Küçük ofisten itibaren büyük markalar (ulusal, çok uluslu) ihale daveti gönderir. Davette rakip ajanslar, hazırlık süresi ve varsa katılım ücreti yazar.
- **Hazırlık:** Pitch ekibini ve ücret teklifini (%85 / %100 / %115) seçersin. Ekip hazırlık boyunca Strateji ve Kreatif puan biriktirir, bu sürede kampanyada çalışmaz. Gelen kutusunda ilerleme görünür.
- **Sunum mini oyunu:**
  - müşteri hakkında 2–3 ipucu;
  - 3 tur (açılış, fikir, kapanış), her turda 3 kart;
  - her karttan sonra müşterinin yüz ifadesi (😊 😐 😠);
  - sonunda rakiplerle birlikte skor çubukları ve kazanma olasılığı.
- **Kazanırsan** marka portföye girer ve ilk brief'i hemen gelir. **2. olursan** itibar +0.5 alırsın ve marka ileride doğrudan iş teklif edebilir.
- Nasıl test ederim:
  1. Küçük ofise taşın ve oynamaya devam et. Bir süre sonra "… ihaleye çağırıyor" bildirimi gelir.
  2. Gelen kutusunda ihale kartında **Katıl**'a bas. Ekibi ve ücret teklifini seç, **Hazırlığa başla**. Pitch ekibindekilerin yeni kampanyanın ekip listesinde seçilemediğini gör.
  3. Gelen kutusunun üstünde hazırlığın kalan haftasını ve biriken S/K puanını izle.
  4. Sunum günü pencere kendiliğinden açılır (oyun durur). İpuçlarına göre kart seç, her kartın tepkisini gör.
  5. Sonuçta kazandıysan müşteri listesinde yeni markayı ve gelen kutusunda ilk brief'ini gör. 2. olduysan itibarın 0.5 arttığını kontrol et.

## M5-A: Rakipler, ödüller, sıralamalar (2026-11-03)
- **Sektör ekranı:** Sol menüde yeni. Ödül takvimi ve başvuru, kazandığımız ödüller, yıl sonu sıralamaları ("En Kreatif", "En Büyük", Yılın Ajansı) ve rakip ajanslar tablosu (tip, çalışan, itibar, güç; uzman olduğu sektörler ipucunda).
- **12 rakip ajans:** Dört kişilik tipi var (dev network, kreatif butik, agresif fiyatçı, dijital start-up). Rakipler büyür, küçülür, kapanır; yeni ajanslar yıllar içinde sektöre girer.
- **Rakip etkileşimleri:**
  - memnuniyeti düşük müşteriyi rakip çalabilir;
  - çalışanlara gelen transfer tekliflerinde artık teklifi yapan ajansın adı yazıyor;
  - yeni işe alım kanalı "Rakipten transfer": pahalı ama deneyimli adaylar, işe aldığın kişi rakibi zayıflatır.
- **5 ödül:** Altın Elma, Etkin Ödülleri (2008+), Kıyı Aslanları, Dijital Yıldızlar (2005+), İyilik İçin.
  - Başvuru dönemi bildirimle açılır. Son 12 ayın kampanyalarını ücretle gönderirsin.
  - Tören ayında sonuçlar tek tek açılan bir pencerede gösterilir.
  - Ödüller itibar, ekip morali, ödül alan çalışanın piyasa değeri ve yeni müşteri getirir.
- Nasıl test ederim:
  1. Yeni oyun aç, sol menüden **Sektör**'e gir: ödül takvimini ve 4 rakip ajansı gör (diğerleri yıllar içinde açılır).
  2. 8+ puan alan bir kampanyadan sonra bildirimde "… başvuruları açıldı" yazınca Sektör → **Başvur** → kampanyanın yanındaki **Gönder**; nakdin ücret kadar düştüğünü gör.
  3. Ertesi ay tören penceresi açılır: sonucunu, rakiplerin aldığı ödül sayısını ve Grand Prix'yi gör. Ödül aldıysan itibarın arttığını, ödül "Kazandığımız ödüller" listesine düştüğünü kontrol et.
  4. İlk yıl sonunda bildirimde sıralamanı ve Sektör ekranındaki iki listeyi gör.
  5. Ekip → işe alım → kanal "Rakipten transfer": adayın hangi ajansta çalıştığı yazar. İşe alınca Sektör ekranında o ajansın çalışan sayısının 1 düştüğünü gör.
  6. Bir müşterinin memnuniyetini düşük bırakırsan (40 altı) bir süre sonra "… ile çalışmaya başladı" bildirimi gelebilir.

## Denge adımı (2026-11-03, A-014)
- Hata cezası artık işin kendi kalitesinin yüzdesi (hata başına %3, en fazla %40); dönemle büyümüyor.
- Rekor çıtası her yıl %10 eriyor: tek şanslı bir iş yıllarca aşılamaz çıta bırakmıyor.
- Ofis taşınma bedelleri GDD 12.1'deki tutarlar (₺500k / ₺3M / ₺15M / ₺80M), enflasyonla büyümüyor.
- Büyük ofise daha büyük markalar geliyor.
- Yerel markalar medya bütçesinin yarısını, ulusal ve çok uluslu markalar tamamını kampanya başında avans ödüyor (sihirbazda yazıyor).
- Sonuç: bilgili botun 10 yıllık ortalama puanı 6.45 → 7.11 (GDD hedefi 7.0–8.5); küçük ofis Y3; büyütülmüş ofis Y11'de (önce hiç); rastgele bot ilk 3 yılda %22 iflas.
- Kalan: 15. yıldan sonra puan hâlâ düşüyor; plaza katı itibar (M5) bekliyor. Bkz. decisions.md A-014.
- Nasıl test ederim:
  1. Yeni oyun aç, 2–3. yılda ₺500k biriktirip küçük ofise taşın; bedelin tam ₺500.000 olduğunu gör.
  2. Yerel veya ulusal bir markanın brief'ini aç; sihirbazda yeşil "avans" satırını gör, kampanyayı başlatınca nakdin o kadar arttığını kontrol et.
  3. Hatalı bir kampanyanın raporunda "Puan dökümü"nü aç; hata payının puanı yüzdeyle düşürdüğünü gör.

## Rapor açıklamaları (2026-11-03, playtest geri bildirimi)
- "Neden bu puan?" bölümü artık iş miktarını da söylüyor: emek dönem beklentisinin çok altındaysa "daha büyük ekip / uzmanlar / daha uzun iş gerekir" satırı çıkıyor.
- Müşteri memnuniyeti değişimi kalem kalem gösteriliyor (puan ve beklenti, KPI, gecikme, account, riskler, skandal).
- Nasıl test ederim: Ekipsiz, kısa süreli bir işi iyi kombinasyonla yap; raporda yeşil uyum satırlarının yanında kırmızı "emek az kaldı" satırını ve memnuniyetin altındaki dökümü gör.

## M4-B — Kanal seçenekleri ve influencer (2026-10-31)

### Eklenenler
- Kanal seçenekleri (veriden otomatik çizilen menüler; varsayılan "Otomatik"):
  - Açık hava: lokasyon A/B/C, süre, megalight izin gecikmesi, DOOH ölçümleme bonusu.
  - TV/radyo/sinema: kuşak, spot süresi, çekim prodüksiyonu (ajansa marj), cesur tonda Yayın Kurulu riski.
  - Dijital/sosyal: teklif modeli (CPM/CPC/CPA), hedefleme (2024+ çerezsiz dünya).
  - Gerilla: 5 fikir kartı, belediye cezası, basına çıkma (erişim ×2).
  - Etkinlik: mekân, catering, davetliler; hava ve aksilik riskleri; %20 prodüksiyon marjı.
- Influencer havuzu (2012+): kademe, niş, takipçi, etkileşim, ücret; gizli sahte takipçi oranı (PR ekibi görür); tekrar çalışma indirimi; skandal kararı penceresi.
- PR & Etkinlik departmanı etkileri: etkinlik riskini yarıya indirir, sahte takipçiyi görür, gerilla işini basına taşır.
- Raporda riskler, basına çıkma ve skandal satırları.
- Testler: `tests/test_channel_options.gd` (15); toplam 94.

### Nasıl test ederim
1. Billboard seçince altında **Lokasyon paketi** ve **Süre** çıkar; A pahalı ama çok daha görünür.
2. Ulusal TV'de **Kuşak** ve **Spot süresi** seç. Cesur tonla yaparsan Yayın Kurulu reklamı durdurabilir.
3. 2012'den sonra (hızlı denemek için 2010 başlangıcı yoksa uzun oyun gerekir) **Influencer (mikro)** seç; havuzdan bir kişi seç. Skandal patlarsa karar penceresi açılır.
4. Gerilla kartlarından "Sahte ürün kuyruğu" riskli ama etkili; raporda ceza ya da "basına çıktı" satırı görünür.
5. Ekibe bir PR uzmanı alınca influencer listesinde gerçek takipçi oranı görünür.

## M4-A — Kanal karışımı ve matbaa (2026-10-31)

### Eklenenler
- Çoklu kanal karışımı (3. yıldan itibaren): sihirbazda kanal ekle/çıkar, bütçe öncelikleri, gerçek pay ve bütçe yanında; kanal sınırı ofis ve medya planlamacıya bağlı.
- 45 kanalın hepsinin ilgi eğrisi ve kendi CPM/ER/CVR değeri; kanal etkisi ve maliyeti yıllara göre değişiyor; CPM'de mevsim etkisi.
- Raporda kanal bazında bütçe, gösterim, erişim, etkileşim, dönüşüm tablosu.
- Basılı işler: ürün, kalite, adet, dağıtım, prova, matbaa; GDD 10.2 fiyat formülü; baskı hatası ve gecikme; prodüksiyon marjı geliri.
- 4 matbaa, ilişki puanı, gelen kutusuna düşen hacim/yıllık taahhüt teklifleri, yıl sonu taahhüt cezası.
- 3 turluk pazarlık penceresi; satın alma uzmanı gizli tabanı tahmin ediyor.
- Medya satın alma verimi (medya planlamacı + yıllık hacim).
- Finans ekranında matbaa ilişkileri ve aktif anlaşmalar.
- Testler: `tests/test_media.gd` (19); toplam 79. Botlar çoklu kanal kullanıyor.

### Nasıl test ederim
1. Yeni oyunu 3. yıla kadar oyna (Y1–Y2'de tek kanal var).
2. Bir brief kabul et → sihirbazda **+ Kanal ekle** → ikinci bir kanal seç; slider'larla bütçeyi böl, yanında gerçek payı gör.
3. El ilanı/broşür, katalog ya da POP seçersen baskı ayarları açılır. Kaliteyi, adedi, matbaayı değiştir ve maliyet/marj/teslim satırını izle. Teslim, son faza sığmazsa kırmızı yanar.
4. **Pazarlık et** → üç teklif hakkın var. Çok düşük teklif ilişkiyi zedeleyebilir.
5. Rapor açılınca kanal tablosuna ve "Prodüksiyon marjı" satırına bak.
6. Gelen kutusuna bir matbaa teklifi düşünce kabul et; Finans ekranında aktif anlaşmayı gör.

## M3 — Çalışanlar ve departmanlar (2026-10-31)

### Eklenenler
- Çalışan modeli (GDD 11.2): 6 stat, gizli statlar, enerji, moral, tükenmişlik, XP/seviye, kıdem unvanları, özellikler, sektör uzmanlaşması.
- Çalışan bazlı puan üretimi (7.5): ekipteki herkes kendi statı, uzmanlığı (×1.3 / ×1.0 / ×0.6), morali, enerjisi ve özellikleriyle üretiyor.
- Fazla mesai: üretim ×1.35, enerji ×2, tükenmişlik +6/hafta, hata ×1.6.
- İşe alım (ilan, staj, kariyer sitesi 2000+, headhunter), eğitim, uzmanlaşma, zam, kovma, rakip transfer teklifi.
- Departman etkileri: Account (müşteri memnuniyeti), Trafik/Prova (hata temizleme), Creative Director (kreatif kapasitesi).
- Ofis seviyeleri (12.1): kapasite, koşullar, taşınma bedeli, kira, oda kalitesi.
- Yeni oyunda oyuncu geçmişi seçimi (11.5).
- Veri: `positions.json`, `traits.json`, `hiring_channels.json`, `offices.json`, `backgrounds.json`, `names_tr.json`, `names_en.json`.
- Arayüz: Ekip ve Ofis ekranları, İşe Alım ve rakip teklif pencereleri, sihirbazda ekip seçimi, üst barda fazla mesai anahtarı.
- Kayıt sürümü 2: eski kayıtlar otomatik göç ediyor.
- Testler: `tests/test_staff.gd` (17); toplam 62. Botlar işe alım ve ofis taşınması yapıyor.

### Nasıl test ederim
1. F5 → **Yeni Oyun** → bir geçmiş seç (ör. Eski Pazarlama Müdürü fazladan bir müşteriyle başlar).
2. **Ekip** → **İşe al** → pozisyon ve kanal seç → **Aday ara** → birini işe al. Ev odasında sen dahil en fazla 2 kişi olabilirsin.
3. Bir brief kabul et; sihirbazın altındaki **Ekip** kutucuklarıyla kimin çalışacağını seç.
4. Kampanya sürerken **Ekip** ekranında enerji ve moral barlarına bak. Üst bardaki **Fazla mesai**'yi açınca enerji hızla düşer, tükenmişlik birikir.
5. Kampanya bitince ekip XP kazanır; seviye atlayan bildirimde görünür.
6. **Ofis** ekranında bir sonraki ofisin koşullarını gör (Y2 + ₺500k). Koşullar sağlanınca **Taşın**.
7. Eski bir kaydı **Devam Et** ile aç: kurucu otomatik oluşur.

## M2 — Oynanabilir 2D prototip (2026-10-31)

### Eklenenler
- Autoload'lar: `DataDB`, `EventBus`, `SaveSystem`, `GameState`, `Clock` (Duraklat/1x/2x/4x, Boşluk ve 1/2/3 kısayolları).
- Ekranlar: ana menü (Yeni oyun, Devam et, dil), oyun ekranı (üst bar, sol menü, bildirim akışı), Gelen Kutusu, Müşteriler, Kampanya (faz slider'ları + canlı S/K/T sayaçları), Finans, Raporlar.
- Pencereler: kampanya sihirbazı, kampanya raporu (sayarak yükselen puan, 4 yorum, KPI kartları, "Neden bu puan?", puan dökümü), iflas ekranı.
- Tema: krem zemin, adaçayı yeşili, yuvarlak köşeler.
- Kayıt/yükleme (tek slot), `SaveCodec`, `ReportWriter`, `data/report_lines.json`.
- `strings.csv`'ye 166 yeni anahtar (TR + EN).
- Testler: `tests/test_m2_flow.gd`; toplam 45 test. `tools/ui_tour.tscn`: ekranların görüntüsünü alan geliştirici aracı.

### Nasıl test ederim
1. Godot'yu aç (`C:\Users\osonm\Tools\Godot\Godot_v4.7.2-stable_win64.exe`) ve projeyi seç. Editör açılınca yeni dosyaları içe aktarması birkaç saniye sürer.
2. **F5** (veya sağ üstteki ▶) ile oyunu başlat → **Yeni Oyun**.
3. Oyun duraklatılmış başlar. **1x**'e bas (veya Boşluk). Brief'ler haftalık gelir.
4. **Gelen Kutusu** → bir brief'te **Kabul et** → sihirbazda kitle, ton ve kanal seç → **Kampanyayı başlat**.
5. Her fazın başında oyun durur: üç slider'ı ayarla → **Fazı başlat**. Üç faz bitince kampanya teslim edilir ve yayına çıkar.
6. Yayın bitince rapor açılır. "Puan dökümü" düğmesi puanı oluşturan çarpanları gösterir.
7. **Kaydet** → Ana Menü → **Devam Et** ile kaydın geri geldiğini kontrol et.
8. 30 dakika oyna ve `docs/playtest-notes.md`'ye yaz: "Bir kampanya daha" hissi var mı? Neler sıkıcı, neler anlaşılmaz?

## M1 — Simülasyon çekirdeği (2026-10-31)

### Eklenenler
- `src/sim/`: `GameData`, `SimRng`, `SimState`, `SimClock`, `Scoring` (7.2–7.9), `Kpi` (7.10–7.11), `Economy` (13), `ClientSystem` + `BriefGenerator` (6, mevsimsellik dahil), `CampaignProduction` (7.5), `Simulation`.
- `src/commands/`: `StartCampaignCommand`, `DeclineBriefCommand`.
- Veri: `data/calendar.json` (mevsimler + 1990–2035 kayan bayram ayları), `data/brands/` (isim parçaları, el yapımı markalar), `sectors.json → avg_basket`, `focus_areas.json → stats`, `balance.json`'a M1 sabitleri.
- `tools/balance_sim.gd` + `tools/bots/` (rastgele bot, bilgili bot). `--runs`, `--years`, `--seed`, `--set=yol=değer`.
- Testler: `tests/test_scoring.gd` (16), `tests/test_sim_systems.gd` (12). Toplam 38 test geçiyor.
- Veri doğrulayıcı takvim, marka ve sepet alanlarını da kontrol ediyor.

### Denge sonucu
Bkz. `docs/decisions.md` "M1 denge sonucu". Rastgele bot ilk 3 yılda %41 iflas ediyor (hedef %20–40, sınırda). Puan farkı 1.51 (hedef ≥ 2); karar bekleyen soru A-005.

### Nasıl test ederim
1. Testler: `"C:/Users/osonm/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe" --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit` → 38 test geçmeli.
2. Denge simülasyonu (~3 dk): `"C:/Users/osonm/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe" --headless --script res://tools/balance_sim.gd -- --runs=200` → tablo ve "M1 kabul" satırı.
3. Bir değeri dosyaya dokunmadan denemek: aynı komutun sonuna `--set=briefs.free_objective_chance=0.7` ekle.
4. Görsel bir şey yok; oyun ekranı M2'de gelecek.

## M0 — Kurulum & iskelet (2026-10-31)

### Eklenenler
- Godot 4.7.2 projesi (`project.godot`), GDD 24.2 klasör yapısı, M0 açılış ekranı (`src/ui/screens/boot_screen.tscn`).
- `CLAUDE.md` (GDD 25.2 şablonu, sürüm 4.7.2 sabitlendi + yerel ortam notu).
- GDD'nin bölüm bölüm markdown hâli: `docs/gdd/00-icindekiler.md` … `29-ekler.md`.
- Veri: `balance.json` (29.1), `sectors.json` (35), `objectives.json` (6, odak önemi + ideal S/K), `audiences.json` (4), `tones.json` (6), `tone_groups.json` (11), `focus_areas.json` (9), `channels.json` (45), `combo_rules.json`, `fit/sector_objective.json`, `fit/sector_audience.json`, `fit/tone_fit.json`, `fit/channel_fit.json`.
- Yerelleştirme: `localization/strings.csv` (TR + EN, 120 anahtar).
- GUT 9.7.1 test eklentisi + `tests/test_data_validator.gd` (10 test).
- Veri doğrulama: `tools/validate_data.gd` + `tools/data_validator.gd` (id tutarlılığı, GDD 8.0 tam satır dağılım kuralı).
- `docs/decisions.md` (K-001…K-015 + açık sorular), `docs/playtest-notes.md`, `docs/ideas.md`, `.gitignore`.

### Nasıl test ederim
1. Godot'yu aç: `C:\Users\osonm\Tools\Godot\Godot_v4.7.2-stable_win64.exe` → **İçe Aktar (Import)** → `AD_TYCOON\project.godot` → **İçe Aktar ve Düzenle**.
2. Sağ üstteki ▶ (veya **F5**) ile çalıştır: krem zeminde "Ajans Tycoon" yazan açılış ekranı gelmeli; alttaki Çıktı (Output) panelinde kırmızı hata olmamalı.
3. Testler (Git Bash veya PowerShell, proje klasöründe):
   `"C:/Users/osonm/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe" --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit` → "All tests passed".
4. Veri doğrulama: `"C:/Users/osonm/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe" --headless --script res://tools/validate_data.gd` → "Veri doğrulama BAŞARILI".
5. Bozuk satır denemesi: `data/fit/sector_objective.json` içinde `fast_food` satırındaki altı değeri de `3` yap, 4. adımı tekrarla → "dağılım kuralını bozuyor" hatası ve çıkış kodu 1. Sonra değişikliği geri al (`git checkout data/fit/sector_objective.json`).
