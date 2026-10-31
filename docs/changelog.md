# Değişiklik günlüğü

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
