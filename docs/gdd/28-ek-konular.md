# 28 Senin aklına gelmeyen ama gereken her şey

## 28.1 Hukuki & lisans

- **Marka adları:** Gerçek şirket, platform ve yazılım adları kullanma (Instagram → InstaFoto, Photoshop → PixelShop, Cannes Lions → Kıyı Aslanları). Game Dev Tycoon ve benzerleri de bu yüzden parodi isim kullanır. Gerçek logolara benzeyen logolar da kullanma.
- **Gerçek kişiler:** Ünlü reklamcı veya ünlü isimleri birebir kullanma; parodi isim ve özgün görünüm.
- **AI içerik beyanı:** Steam, mağaza sayfası için önceden üretilmiş AI içeriğinin beyan edilmesini ister. Asset kaydını (`asset_log.csv`) bunun için tut. Yasal/istikrarlı ticari lisanslı araçlar ve planlar kullan.
- **Yazı tipleri:** Ticari kullanıma açık (ör. OFL lisanslı) fontlar seç ve lisans dosyalarını oyunla birlikte dağıt.
- **Godot lisansı:** MIT; oyunun "Krediler" ekranına Godot lisans metnini ekle (yükümlülük).
- **Şirket & vergi:** Steam'den gelir almak için Steamworks'te vergi ve banka bilgileri gerekir; Türkiye'de şahıs şirketi/limited ve oyun geliri vergilendirmesi için bir mali müşavirle konuş (Claude bunu senin yerine çözemez; dönemsel değişen kurallar var). Bu bir hukuk/finans tavsiyesi değil.

## 28.2 Pazarlama (geliştirmeyle paralel)

- Steam sayfası erken açılmalı (M8–M10 civarı, ilk güzel görseller hazır olunca). İstek listesi (wishlist) sayısı çıkış başarısının en güçlü göstergesidir.
- **Steam Next Fest:** Demo ile katılmak büyük görünürlük sağlar.
- **YouTube kanalın büyük bir avantaj:** Geliştirme günlüğü (devlog) serisi; ayrıca tycoon/simülasyon YouTuber'larına demo anahtarı gönder.
- **Hedef nişler:** Reklamcılık/tasarım toplulukları (LinkedIn, sektör siteleri), Reddit (r/tycoon, r/incremental_games, r/godot), Discord sunucusu.
- **Paylaşılabilir anlar:** "Ajans karnesi" görseli, komik olay ekranları, viral kampanya anı — kolay ekran görüntüsü/GIF.
- **Fiyat:** Türün referansları ~10–25 $ aralığında; çıkış öncesi rakipleri incele, bölgesel fiyatlandırmayı Steam önerileriyle kullan.
- **Fragman:** İlk 5 saniyede çekirdek döngü: brief → fikir → puan → büyüyen ofis.

## 28.3 Kalite ve oyuncu deneyimi

- **Erişilebilirlik:** Renk körü modu (semboller zaten var), metin boyutu, tamamen duraklatılabilir oyun, animasyon azaltma seçeneği.
- **Yerelleştirme genişlemesi:** TR/EN'den sonra Almanca, Portekizce (Brezilya), İspanyolca, Rusça, Çince tycoon türünde güçlü pazarlar. Veri odaklı yapı bunu kolaylaştırır.
- **Steam Deck:** Kontrolcü/dokunmatik dostu UI baştan düşünülürse sonradan kolay doğrulanır.
- **Kayıt güvenliği:** Bulut kayıt + yedek kayıt; güncellemelerde kayıt göçü.
- **Zorluk ayarları:** "Rahat" (iflas yok), "Normal", "Usta Reklamcı" (ekonomi sert, müşteriler acımasız). Ayrıca "özel başlangıç" (yıl, para, ofis).
- **Sandbox / sonsuz mod:** 2035 sonrası devam.

## 28.4 Proje yönetimi riskleri

| Risk | Önlem |
|---|---|
| Kapsam şişmesi (scope creep) | Bu doküman tam oyunu tarif eder; MVP sadece Bölüm 2.4'teki listedir. Yeni fikirleri `docs/ideas.md`'ye yaz, M10'dan önce ekleme. |
| "Eğlenceli değil" riski | M2'de yalnızca menülerle eğlenceyi kanıtla. Görsellere para/zaman harcamadan önce. |
| AI asset tutarsızlığı | Stil incili, palet dokusu, az ama tutarlı asset. |
| Kod karmaşası | Simülasyon/sunum ayrımı, testler, küçük commit'ler, CLAUDE.md kuralları. |
| Motivasyon kaybı | Her 2 haftada bir gösterilebilir ilerleme (devlog videosu bunun için harika). |
| Dengeleme sonsuz döngüsü | Bot simülasyonu + hedef metrikler; "yeterince iyi"yi baştan tanımla. |
