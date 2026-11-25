# Oyun denetimi — 25 Kasım 2026

Bu rapor ilk hâliyle yalnızca tespitti. Onayınla 1–3 numaralı hatalar (K-149) ve 4–6 numaralı hatalar (K-150) düzeltildi; 7 ve 8 bekliyor.

## Neye baktım

| Kontrol | Sonuç |
|---|---|
| Birim testleri (302 test) | Hepsi geçiyor |
| Veri doğrulama (`data/*.json`) | Temiz |
| Denge simülasyonu, 200 koşu × 10 yıl | Çalışıyor; iki hedef tutmuyor (aşağıda) |
| Denge simülasyonu, 30 koşu × 30 yıl | Bilgili bot 30 yılda %20 iflas ediyor; aşağıda |
| Ekran turu, pencere ve panel çekimleri (Türkçe + İngilizce), arayüz denetimi | Kesik yazı, taşma ya da boy değişimi yok |
| Performans: 60 çalışan, gerçek modeller | Saniyede 250 kare (hedef 60) |
| Kodu okuma | Simülasyon çekirdeği, para, müşteri, ekip, kayıt, saat, ana ekran |

"Doğrulandı" yazan hataları küçük bir deneme betiğiyle tek tek denedim, gerçekten oluyorlar. Diğerlerini kodu okuyarak buldum.

---

## Hatalar

### 1. Müşteri, işi sürerken giderse ajans parasını alamıyor — **ciddi, doğrulandı · DÜZELTİLDİ (K-149)**
- **Ne oluyor:** Bir müşterinin kampanyası üretimdeyken müşteri ayrılabiliyor. Bunun iki yolu var: başka bir kampanyası kötü bittiği için memnuniyeti düşer, ya da bir olayda "müşteri ayrılıyor" seçeneği çıkar.
- **Sonuç:** Kampanya teslim edilince medya bedeli yine ajanstan ödeniyor, ama müşteriye fatura kesilmiyor. Ajans hem medya parasını hem ücretini kaybediyor. Denemede ₺17.265'lik medya bedeli ödendi, karşılığında hiç tahsilat oluşmadı.
- **Neden:** Rakip müşteri çalarken "işi süren müşteri çalınmaz, ajans parasını alamazdı" kuralı var. Ama memnuniyetsizlikten ayrılmada ve olaydaki ayrılmada bu kural yok.
- **Ne zaman olur:** Kampanyası yayında olan müşteri yeni brief gönderebiliyor. İlk kampanya kötü biterse müşteri, ikincisi daha üretimdeyken gidiyor.
- **Önerim:** Rakip çalmadaki kuralı her yerde uygulamak. İşi süren müşteri iş bitene kadar kalsın, sonra gitsin.

### 2. Yıl sonu vergisi sessizce kesiliyor — **orta, doğrulandı · DÜZELTİLDİ (K-149)**
- **Ne oluyor:** Her yıl sonunda kârın %25'i kurumlar vergisi olarak kasadan düşüyor. Oyuncuya hiçbir bildirim çıkmıyor.
- **Sonuç:** Denemede ₺1 milyon kârlı bir yılın sonunda kasadan ₺250 bin habersiz gitti. Bu ödeme finans ekranındaki gider grafiğinde de görünmüyor.
- **Önerim:** "Yıl sonu vergisi: ₺… ödendi" bildirimi göstermek, vergiyi o ayın giderine yazmak, finans ekranında "bu yıl ödenecek tahmini vergi" satırı eklemek.

### 3. Ayrılan çalışanın görevleri sahipsiz kalıyor — **orta, doğrulandı · DÜZELTİLDİ (K-149)**
- **Ne oluyor:** Görev atamalı bir kampanyada (orta/büyük iş, en az 3 kişi) görevli biri istifa ederse, rakibe geçerse ya da bir olayla ayrılırsa, ekipten çıkarılıyor ama görev planında adı kalıyor.
- **Sonuç:** O görev fazın sonuna kadar hiç puan üretmiyor ve oyuncuya bunu söyleyen bir uyarı yok. Kampanya puanı sebepsizce düşmüş gibi görünüyor.
- **Önerim:** Görevi kendiliğinden en uygun boştaki ekip üyesine vermek ve "X ayrıldı, görevi Y'ye geçti" bildirimi göstermek.

### 4. Ay başında pencere çıkarsa otomatik kayıt o ay hiç yapılmıyor — **küçük · DÜZELTİLDİ (K-150)**
- Otomatik kayıt ay başında, yalnızca zaman akarken yapılıyor.
- Ay başında çoğu zaman bir pencere açılıyor: olay, ödül töreni, rakip teklifi ya da faz planı. Pencere zamanı durduruyor, kayıt o ay atlanıyor ve bir sonraki aya kadar yeniden denenmiyor.
- **Önerim:** Kaydı, pencere kapanıp zaman yeniden akınca yapmak.

### 5. Faz planı beklerken kaydedilen oyun yüklenince plan penceresi açılmıyor — **küçük · DÜZELTİLDİ (K-150)**
- Yükleyince oyun durmuş kalıyor; yalnızca kampanya düğmesinde "!" işareti var. Kampanya penceresinden plan açılabiliyor, yani oyun kilitlenmiyor, ama ilk anda neden durduğu belli değil.
- **Önerim:** Açılışta bekleyen faz planı varsa pencereyi kendiliğinden açmak; olay ve pitch için bu zaten yapılıyor.

### 6. Kayıt yazılırken çok küçük bir risk — **küçük · DÜZELTİLDİ (K-150)**
- Kayıt önce geçici dosyaya yazılıyor, bu iyi. Ama eski kayıt yenisi yerine konmadan *önce* siliniyor. Tam o anda bir sorun çıkarsa (disk dolu, antivirüs dosyayı kilitledi) slot boş kalır.
- **Önerim:** Eski kaydı silmek yerine `.bak` adıyla bir yedek olarak saklamak.

### 7. İyi oynayan ajans bile geç dönemde batabiliyor — **DÜZELTİLDİ (K-151)**
- 30 yıllık simülasyonda bilinçli oynayan bot 30 koşunun 6'sında iflas etti (%20). İlk 10 yılda bu oran %6,5; yani batmaların çoğu 10. yıldan sonra.
- Aynı dönemde hayatta kalanların ortanca kasası ₺10–70 milyon. Batanlar azınlık ama oran yüksek.
- 17. yılda (plaza katına taşınma) ortanca kasa ₺12,5 milyondan ₺9,3 milyona düşüyor. Plaza kirası ve büyüyen ekip şüpheli.
- **200 koşuyla ölçüldü (25 Kasım):** Genel iflas oranı %15,5 çıktı (31 oyun; 30 koşudaki %20 biraz abartılıydı).
  - 13'ü ilk 10 yılda battı, hepsi küçük ofiste ve 1–2 kişiyle (4–6. yıl).
  - 18'i 10. yıldan sonra battı; 17'si plaza katında, taşındıktan 1–4 yıl sonra.
- **Plaza katındaki batışın nedeni:** Taşınma bedeli ₺15M. Bot taşındıktan sonra elinde ~₺2,4M kalıyor; aylık gider ₺160 binden ₺270 bine çıkıyor.
  - Gelen kutusunda iş olduğu hâlde bot hiçbirini almıyor. Kuralı "tahsilata kadar kasa 1 aylık giderin altına inecekse alma".
  - İşsiz kalmak da kasayı eritiyor, ama bot bunu hesaba katmıyor. 40 hafta boyunca boş oturup batıyor; bu arada moral 54'ten 23'e iniyor, çalışanlar rakiplere kaçıyor.
- **Deneme:** Aynı oyunları bir kural farkıyla oynayan bot denendi: "işsiz kalmak da kasayı yedeğin altına indirecekse, kırmızıya düşürmeyen işi al".
  - Geç dönem iflası 18'den 3'e indi, genel iflas %15,5'ten %7'ye. Erken iflaslar (11) neredeyse aynı kaldı.
  - Yani geç dönem iflasının çoğu oyunun değil botun zaafı. Ama gerçek bir oyuncu da plazaya taşınınca aynı tuzağa düşebilir: kasa boşalıyor, kira 4–5 katına çıkıyor ve taşınma ekranı bunu söylemiyor.
- **Düzeltme (K-151):** Kural bota kondu ve ofis ekranına "taşınınca para kaç ay yeter" satırı eklendi. 200×30 ölçümde iflas %15,5 → %7,0.
- 30 yılın iyi yanları da var: geç dönem puanı eskisinden çok daha iyi (30. yılda 5,2; eskiden 2–3,5), rastgele bot ilk 3 yılda %20 iflasla bu örnekte hedefte, plaza katı 17. yılda açılıyor.

### 8. Teknik gürültü — **önemsiz, oyuncu görmez**
- Testlerde ve ekran çekimlerinde "Lambda capture … was freed" hatası çıkıyor (testlerde 42 kez).
- Mini oyun ya da pencere kapandıktan sonra çalışan bir geri çağrı, silinmiş bir düğmeye uzanıyor. Oyun bozulmuyor, ama günlüğü kirletip gerçek hataları gizleyebilir.

---

## Bilerek böyle bırakılanlar (hata değil, hatırlatma)
- **İlk 3 yılda iflas oranı:** Rastgele oynayan bot ilk 3 yılda %15,5 iflas ediyor; GDD hedefi %20–40. Bunun nedeni ilk brief garantisi; senin kararınla bırakıldı (K-131, K-142).
- **Plaza katı geç açılıyor:** Hedef 12–16. yıl, ama yaklaşık 17. yılda açılıyor (K-097). Nakit şartını düşürmek işe yaramadı. Kalan kollar taşınma bedeli ve plaza kirası.
- **Gezinti modu:** Binanın dış yüzünde iç duvar kâğıdı görünüyor ve kapı boşluklarının üstünde lento yok (K-148).
- **Tripo modeli `1bc5496a`:** Godot'yu çökertmişti, hâlâ incelenmedi.
- **Kadro dönemleri:** Karakterlerin dönemlere dağılımı benim önerimdi, değiştirmek istersen değiştirilebilir (K-147).

---

## Neler geliştirilebilir

### Oyuncunun anlaması
1. **Para nereye gitti?** Vergiden sonra en çok kafa karıştıracak şey nakitteki ani düşüşler. Finans ekranına "son 4 haftanın hareketleri" listesi eklenebilir: maaş, kira, medya ödemesi, vergi, tahsilat.
2. **Müşteri gitmek üzere uyarısı:** Memnuniyet ayrılma sınırına yaklaşınca, müşteri gitmeden önce bir uyarı kartı gösterilebilir. Şu an oyuncu kaybı ancak olunca öğreniyor.
3. **Faz sonu özeti:** Her fazın sonunda kısa bir "bu fazda Strateji +…, hata …" satırı. Puanın nereden geldiği daha erken görülür, rapor sürpriz olmaz.

### Oyun akışı
4. **Uzun dönem puan düşüşü:** 30 yıllık oyunda 20. yıldan sonra puanlar yine yavaşça düşüyor: 20. yılda 8,4, 30. yılda 5,2 (A-014). Geç dönemi canlı tutacak bir şey gerekiyor. Seçenekler: dönemsel büyük müşteriler, ajans "uzmanlık" seçimi ya da kurucu emekliliği/devir.
5. **Gezinti modunu tamamlamak:** Dış cephe kaplaması, kapı lentoları, adım sesi. İstenirse çalışanın yanına gelince başının üstünde adının ve o anki işinin yazması; bu bakmak sayılır, etkileşim sayılmaz.
6. **Mini oyunların karıştırılması:** Film ve radyo mini oyunlarındaki sıra, tohumlu zar yerine motorun kendi rastgeleliğiyle karışıyor. Puanı etkilemiyor, ama aynı kayıttan tekrar oynayınca farklı sıra çıkıyor. Bilerek mi, karar vermek lazım.

### Teknik sağlık
7. **Kök klasörde artık dosyalar:** `s11shot_tmp`, `s12shot_tmp`, `s13shot_tmp` (`.gd`, `.uid`, `.tscn`) kök klasörde duruyor. Git dışında oldukları için zararsızlar, ama Godot her açılışta bunları da tarıyor. Silinebilirler.
8. **Büyüyen dosyalar:** `main.gd` (452 satır), `office_layout.gd` (431), `simulation.gd` ve `office_world.gd` (414) 400 satır kuralını aşmış. Bölünmeleri sonraki değişiklikleri kolaylaştırır.
9. **Hatalar için test:** 1–3 numaralı hataların her biri için birer test yazılırsa aynı sorunlar bir daha sessizce geri gelmez.

---

## Önerdiğim sıra
1. Hata 1 (müşteri parası), 2 (vergi bildirimi), 3 (sahipsiz görev) ve her biri için testleri.
2. Hata 7'yi 200 koşuyla ölçüp nedenini bulmak.
3. Hata 4, 5, 6 (kayıt ve açılış).
4. Geliştirmelerden 1 ve 2 (para hareketleri, müşteri uyarısı).
5. Geri kalanlar senin önceliğine göre.
