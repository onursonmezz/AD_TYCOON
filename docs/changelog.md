# Değişiklik günlüğü

## Denetim düzeltmeleri: kayıt ve yükleme (2026-11-25)
- Ay başında bir pencere açılsa bile otomatik kayıt artık atlanmıyor; pencere kapanıp zaman akınca yapılıyor.
- Faz planı beklerken kaydedilmiş bir oyun yüklenince plan penceresi kendiliğinden açılıyor. Eskiden mini oyun plandan önce geliyordu; mini oyunlar kapalıysa hiçbir şey açılmıyordu.
- Üstüne kaydederken eski kayıt bir yedek olarak saklanıyor. Kayıt bozulursa oyun otomatik olarak bir önceki kayıttan açılıyor.
- Nasıl test ederim:
  1. Oyunu oynat ve ay başında bir olay penceresi çıkınca kapat. Birkaç gün sonra Yükle ekranında "Otomatik" kaydın tarihi o aya geçmiş olmalı.
  2. Bir kampanya başlat ve 2. faz başlayıp plan penceresi çıkınca kapatma, oyunu "Kaydet ve çık" ile kapat. Oyunu açıp kaydı yükle: önce görev planı penceresi açılmalı, mini oyun ondan sonra gelmeli.
  3. Aynı slota iki kez kaydet. `%APPDATA%\Godot\app_userdata\Ajans Tycoon` klasöründe `save_slot_1.sav` yanında `save_slot_1.sav.bak` dosyası olmalı.

## Denetim düzeltmeleri: müşteri parası, vergi, görev devri (2026-11-25)
- İşi süren müşteri artık ajanstan gitmiyor; iş bitince ayrılıyor. Eskiden giderse medya parası ajanstan çıkıyor ama fatura kesilmiyordu.
- Ayrılmak üzere olan müşteri yeni brief göndermiyor.
- Bir olayda "müşteri ayrılıyor" çıkarsa ve müşterinin süren işi varsa "işi bitince ayrılacak" bildirimi geliyor.
- Yıl sonunda kurumlar vergisi bildirimi çıkıyor ve vergi finans grafiğinde ocak giderinde görünüyor. Eskiden sessizce kesiliyordu.
- Görev planındaki biri istifa ederse, rakibe geçerse ya da bir olayla ayrılırsa görevleri kalan ekibin en uygun kişisine geçiyor ve bildirim çıkıyor. Eskiden görev sahipsiz kalıp hiç puan üretmiyordu.
- Nasıl test ederim:
  1. Bir oyunu bir yıl oynat ve yıl sonunu geç. Sağda "Kurumlar vergisi ödendi: ₺…" bildirimi çıkmalı (o yıl kâr ettiysen). Finans ekranının grafiğinde ocak ayının gideri o kadar yüksek olmalı.
  2. En az 3 kişilik ekiple orta boy bir kampanya başlat ve görevleri dağıt. Görevli biri ayrılırsa "… ayrıldı; kampanyadaki görevlerini … üstlendi" bildirimi gelmeli.
  3. Kötü biten bir kampanyadan sonra müşteri ayrılıyorsa: o müşterinin ikinci kampanyası sürüyorsa müşteri hemen gitmemeli, ikinci kampanyanın faturası finans ekranındaki bekleyen tahsilatlarda görünmeli.

## Gezinti modu: ofiste yürü (2026-11-25)
- Doktaki son düğme (yürüyen insan) ya da F tuşu ile ofise göz hizasından girilir.
- WASD ile yürünür, fareyle bakılır, Shift ile daha hızlı gidilir; Esc ile çıkılır.
- Gezinti yalnızca bakmak için: hiçbir şeye tıklanmaz, arayüz gizlenir.
- Zaman durur, ama çalışanlar arada kalkıp kahveye gider, telefonla konuşur ve masalarına döner. Bu yalnızca görüntü; oyuna ve kayda etkisi yok.
- Duvarlar tam boy, üstte tavan var; binanın önündeki sokağa da çıkılabilir.
- Nasıl test ederim:
  1. Oyunu 1x hızda başlat, F'ye bas. Arayüz kaybolmalı, girişte göz hizasında durmalısın.
  2. WASD ile yürü, fareyle etrafa bak. Duvarlardan ve masalardan geçememelisin, kapılardan geçebilmelisin.
  3. Yarım dakika bekle. Birkaç çalışan kalkıp mutfağa ya da dinlenme alanına gidip dönmeli.
  4. Kapıdan çıkıp sokağa yürü. Gökyüzü mavi olmalı, binanın biraz ötesinde durmalısın.
  5. Esc'ye bas. Arayüz geri gelmeli, kamera eski yerinde olmalı, tarih girdiğin günde kalmış olmalı ve oyun yine 1x akmalı.
  6. İnşa modunu aç ve F'ye bas. Gezinti açılmamalı.

## Yeni kadro karakterleri ve dönem kilidi (2026-11-25)
- Orgo'nun 10 yeni Tripo karakteri oyunda. İskeletleri benzer karakterlerden kopyalandı; hepsi yürüyor, oturuyor, yazıyor, telefonla konuşuyor.
- Artık her dönemde kadın ve erkek karakter var. 1990: 1 kadın, 3 erkek; 2000: 5 kadın, 1 erkek; 2010: 2 kadın, 1 erkek; 2020: 2 kadın, 2 erkek.
- Ayarlar → Oyun'da "Dönem kilidi" (varsayılan açık). Kapatınca yeni işe alınanlar her dönemin karakterlerinden gelebilir.
- Nasıl test ederim:
  1. 1990'da yeni oyun başlat ve birkaç kişi işe al. Ofiste takım elbiseli yaşlı adam, siyah takımlı kadın ya da yeşil polo tişörtlü adam görünmeli.
  2. Ayarlar → Oyun → "Dönem kilidi"ni kapat ve yeni adaylarla birkaç kişi daha al. Kot ceketli adam ya da kapüşonlu genç gibi sonraki dönemlerin karakterleri de gelebilmeli.
  3. Kilidi yeniden aç. Daha önce işe alınanların görünüşü değişmemeli.
  4. 2010'da başla. Gözlüklü kadın, pembe hırkalı kadın ve kot ceketli adam görünebilmeli (eskiden 2010'larda hiç model yoktu).

## Orgo'nun düzeltmeleri: arayüz ve faz akışı (2026-11-20)
- Fazlar yine sırayla geliyor: kampanya başlarken 1. faz, sonra 2. ve 3. faz başlarken o fazın planı.
- Faz sürerken kampanya penceresi kapalı; ofiste çalışanları izliyorsun, ilerleme üstteki şeritte.
- Pencereler sabit boyda; sekme ya da sayfa değişince yazılar büyüyüp küçülmüyor. Uzun listeler kendi kutusunda kayıyor.
- Fareyle üstüne gelince düğmeler büyümüyor, yazı kaymıyor, kart pencereden taşmıyor.
- Tarih "Kasım 1993 · Hafta 2 (Y4)" biçiminde.
- Bitkiler susayınca sağda "Sula" düğmeli kalıcı bir kart çıkıyor.
- Tek kanalda gereksiz "%100 · tutar" yazısı kalktı.
- Nasıl test ederim:
  1. Orta boy bir işi 3+ kişiyle başlat. Önce yalnızca "Görev planı · Faz 1" açılmalı. Başlatınca pencere kapanmalı ve ofis görünmeli.
  2. Faz 1 bitince oyun durmalı ve "Görev planı · Faz 2" açılmalı; Faz 3'te kiralık ekipman seçenekleri de olmalı.
  3. Ar-Ge'de sekmeler ve sayfalar arasında gezin. Pencere ve yazı boyu hiç değişmemeli.
  4. Medya kanalı seçerken "Tümü" ile tek bir kategori arasında geçiş yap. Yazılar aynı boyda kalmalı.
  5. Fareyi düğmelerin ve olay seçeneklerinin üstünde gezdir. Hiçbir şey kaymamalı ya da taşmamalı.
  6. Bitkileri birkaç hafta sulama. Sağda "Bitkiler susadı · Sula" kartı çıkmalı; basınca kaybolmalı.
  7. Üstteki tarih "Ay adı Yıl · Hafta n (Yn)" biçiminde olmalı.

## İnceleme 10. aşama: genel cila (2026-11-19)
- Büyük ofiste "İnşa moduna geç" düğmesi artık kesilmiyor; bitki sulama ile aynı satırda.
- Yeni kampanyada hedef, hedef kitle ve ton da çizimli kartlarla seçiliyor (açılır menü kalmadı).
- Ar-Ge → Odak önemi tablosu renkli kutularda.
- Nasıl test ederim:
  1. 2015'te başla (ya da ofisini büyüt), Ofis penceresini aç. İnşa moduna geç düğmesi tam görünmeli.
  2. Bir brief kabul et ve Yeni kampanya penceresini aç. Hedef, kitle ve ton düğmelerine basınca çizimli kartlar çıkmalı. Araştırılmamış seçeneklerde "otomatik" yazmalı.
  3. Ar-Ge → Odak önemi sekmesine bak. Bilinen hücreler yeşil ya da kiremit, bilinmeyenler soluk "?" olmalı.

## İnceleme tamamlandı (10 aşama)
- Orgo'nun listesindeki maddelerin hepsi işaretlendi (docs/review_backlog.md). Kararlar K-131 ile K-144 arasında.

## İnceleme 9. aşama: olaylar ve bildirimler (2026-11-19)
- Adı verilmemiş kampanyada olay metni artık boş tırnak yerine müşterinin adını yazıyor.
- Olay sonucunda ne olduğunu anlatan kısa bir cümle var (iyi, kötü ya da karışık sonuç); etkiler yeşil ve kiremit etiketlerde.
- Aynı anda birden çok kampanya varken üretim olayları hepsine eşit dağılıyor.
- Nasıl test ederim:
  1. Bir kampanyayı adsız başlat ve olay gelene kadar oyna. Metinde boş '' görmemelisin, müşterinin adı yazmalı.
  2. Bir olayda bir seçenek seç. Sonuçta bir cümle ve renkli etiketler görmelisin; kötü etkiler kiremit, iyiler yeşil olmalı.
  3. İki kampanya birlikte yürürken gelen üretim olaylarının ikisine de denk geldiğini gör.

## İnceleme 8. aşama: para ve uzun dönem (2026-11-19)
- Finans ekranında "Aylık giderler" artık gerçek toplam (maaş, kira, abonelik, bakım, kredi dahil). Tutara basınca kalem kalem döküm açılıyor.
- Yeni satır "Nakit kaç ay yeter": parasız kalmaya 2 aydan az varsa kırmızı oluyor.
- Grafik hem geliri (yeşil) hem gideri (kiremit) gösteriyor.
- Kredi tutarı ve vadesi düğmelerle seçiliyor; aylık taksit hemen görünüyor.
- Nasıl test ederim:
  1. Birkaç kişi işe al, Finans → Özet'e bak. Aylık giderler maaşlarla birlikte büyük bir rakam olmalı.
  2. Tutara bas: maaş, kira, abonelik ayrı satırlarda görünmeli; geri düğmesiyle dön. Pencere boyu değişmemeli.
  3. Banka kredisi sekmesinde farklı tutar ve vadeleri seç. Aylık taksit her seçimde değişmeli.
  4. Birkaç ay oyna. Grafikte her ay için yeşil ve kiremit iki sütun olmalı.

## İnceleme 7. aşama: Araçlar, Ar-Ge, ekipman (2026-11-19)
- Araçlarda her satırda artık bir düğme ya da durum var: güncel araçta "✓ Güncel", bilgisayar yetmiyorsa "Yeni bilgisayar gerekir". Ücretsiz araçlarda fiyat yerine "ücretsiz" yazıyor.
- Aboneliğini bitirdiğin araç "+ N araç daha" düğmesinde; o düğme artık belirgin.
- Ar-Ge'de biten araştırmalarda "Tamamlandı" yazıyor. Araştır düğmesi kapalıysa, üstüne gelince nedeni çıkıyor.
- Sektör uyumu sekmesinde açılır menü yok. Solda sektör listesi ve her sektörde kaç uyumu bildiğin (3/10 gibi) var; sağda uyumlar renkli kutularda.
- Nasıl test ederim:
  1. 2015'te Araçlar penceresini aç. Hiçbir satır sağ tarafı boş kalmamalı.
  2. Bir aracın aboneliğini bitir. "+ N araç daha"ya basınca o araç yeniden alınabilir görünmeli.
  3. Ar-Ge'de bir araştırma başlat, sonra başka birinin Araştır düğmesinin üstüne gel. Neden kapalı olduğu yazmalı.
  4. Sektör uyumu sekmesinde soldan farklı sektörler seç. Sayılar ve renkli kutular değişmeli.

## İnceleme 6. aşama: ofis ve inşa (2026-11-19)
- Eşyalar duvara tam yaslanıyor; duvara yaklaşınca kendiliğinden yapışıyor. Ctrl basılı tutarsan ızgarasız, serbest konuyor.
- Yerleştirirken görülen önizleme artık saydam değil; koyduğun eşya önizlemede nasıl duruyorsa öyle duruyor (pano ters dönmüyor).
- Kapı daha dar (1,2 m).
- Asılı saksı duvara, masanın ya da rafın üstüne asılabiliyor.
- Bitkiler kuruyunca soluk bir hayalete dönmüyor; renkleri kalıyor, yaprakları sararıyor.
- Nasıl test ederim:
  1. İnşa modunda bir bitki rafını duvara yaklaştır. Duvara boşluksuz yapışmalı.
  2. Ctrl basılı tutarak gezdir. Eşya ızgaraya oturmadan, ince adımlarla kaymalı.
  3. Panoyu (mood board) yerleştir. Önizlemede gördüğün yüz, koyunca da aynı yüz olmalı.
  4. Duvarlar sekmesinden kapı ekle. Açıklık eskisinden dar olmalı.
  5. Asılı saksıyı bir duvara ve bir masanın üstüne as.
  6. Bitkileri birkaç hafta sulama. Kuruyunca renkli kalmalı, sadece sararmalı.

## İnceleme 5. aşama: ekip (2026-11-19)
- Aynı karakter tekrar gelmiyor. Ofiste kullanılmayan bir 3B model seçiliyor, yoksa saçı, kıyafeti ve rengi farklı bir karakter geliyor. Aday portreleri de birbirinden farklı.
- Kurucunun her ofiste ekipten ayrı, ekibe dönük kendi masası var.
- İşe almada pozisyon ve kanal, ikonlu kartlardan seçiliyor (açılır menü yok).
- Ekip tablosunda roller kesilmiyor.
- Nasıl test ederim:
  1. 1990 başlangıcıyla oyna ve birkaç erkek çalışan işe al. Ofiste hepsi aynı karakter olmamalı.
  2. Aday ara; aynı aramadaki adayların portreleri birbirinden farklı olmalı.
  3. Ofise bak. Kurucu ekiple karşılıklı değil, kendi ayrı masasında ekibe dönük oturmalı. Ofis taşıyınca yeni ofiste de öyle olmalı.
  4. İşe alım penceresinde Pozisyon düğmesine bas; departman ikonlu kartlar açılmalı. Kanalda fiyatlar kartın altında yazmalı.

## İnceleme 4. aşama: sonuç ve puanlama (2026-11-19)
- Raporda yeni "Neden bu puan?" sekmesi var. Puanı etkileyen 8 etken renkli kartlarda; her birinde Güçlü/İyi/Nötr/Zayıf derecesi ve ne yapman gerektiğini söyleyen bir cümle var. Formül dilindeki puan dökümü kalktı (sayılar ipucunda).
- Kanal performans tablosu pencerenin tamamına yayılıyor.
- Sekmeler arasında geçerken pencere ve sekme çubuğu artık zıplamıyor.
- Yankılarda her yayının kendi sesi ve kendi cümleleri var (120 yeni cümle). Aynı raporda bir cümle tekrar etmiyor; cümlelerde müşterinin ve kanalın adı geçiyor.
- Türkçede ondalıklar virgüllü.
- Nasıl test ederim:
  1. Bir kampanyayı bitir. Yankılar penceresinde dört yorum birbirinden farklı olmalı; bazılarında müşterinin adı geçmeli.
  2. Raporu incele. Sekmeler arasında gezin; başlık ve sekme çubuğu yerinden oynamamalı.
  3. Neden bu puan? sekmesinde 8 kart görmelisin. Üstte en büyük güç ve zaaf yazmalı; bir karta gelince ham sayı çıkmalı.
  4. Özet sekmesinde kanal tablosu pencerenin tamamına yayılmalı.
  5. Birkaç kampanya daha bitir; yorumlar her seferinde farklı olmalı.

## İnceleme 3. aşama: kampanya sistemi (2026-11-19)
- **Görev planı:** "Kampanyayı başlat" önce bir görev planı açıyor.
  - Üç fazın görevlerine ağırlık çubuklarıyla önem veriyorsun.
  - 3+ kişilik ekiple orta/büyük işte her göreve bir kişi atıyorsun. Kişinin yükü aldığı görevlerin ağırlık toplamı; %100'ü aşan yorulur ve hata yapar.
  - Küçük işte ve küçük ekipte atama yok. "Otomatik dağıt" herkese yaklaşık %100 yük verir.
- **Faz sürerken pencere yok:** Saat kutusunun altındaki şerit müşteriyi, fazı, kalan günü ve dört sayacı gösteriyor. Çalışanların başından "+n" puanlar çıkıp sayaçlara uçuyor; hata olunca kırmızı "!".
- **Rötuş ve teslim:** Süre üretim ve rötuş diye ikiye ayrıldı. Üretim bitince ekip hataları gideriyor (yeşil "−1"). "Kampanyayı teslim et" ile istediğin an yayınlıyorsun; basmazsan son gün kendiliğinden teslim.
- **Birden çok kampanya:** Boşta kişi varsa yeni brief kabul edilebiliyor. Bir kişi tek kampanyada çalışıyor. Kampanya penceresinde sekmeler var, üstte her kampanyanın şeridi.
- **Mini oyunlar:**
  - Hedef kitledeki kişiler aynı boyda.
  - Başarılı bitişte tepeden konfeti yağıyor.
  - Gazete oyununda üç gazeteden doğrusunu buluyorsun.
- **Ekipman ekranı:** Adlar tam görünüyor; kiralıklar artık görev planında seçiliyor.
- Nasıl test ederim:
  1. Bir brief kabul et ve "Kampanyayı başlat"a bas. Görev planı açılmalı; çubukları oynatınca yüzdeler değişmeli.
  2. 3 kişilik ekiple orta boy bir işte görevlerin yanındaki kişi düğmesine bas; portreler, uygunluk ve yük görünmeli. Birine üç görev ver, yükü %100'ü geçince turuncu ya da kırmızıya dönmeli.
  3. Kampanya başlayınca pencereyi kapat. Üstte şerit görünmeli; çalışanların başından "+n" puanlar şeride uçmalı.
  4. Üretim bitince bildirim gelmeli. Kampanya penceresinde "Kampanyayı teslim et" çıkmalı; beklersen hata sayısı azalmalı.
  5. Birinci kampanya sürerken, boşta bir çalışan varsa yeni bir brief kabul et. İki şerit alt alta görünmeli, pencerede iki sekme olmalı. Başka kampanyadaki kişi sihirbazda seçilememeli.
  6. Hedef kitle provasında kişiler aynı boyda olmalı; iyi bitirince konfeti tepeden yağmalı.
  7. Gazete provasında ilanı yanlış gazeteye bırak (geri dönmeli), sonra doğrusuna bırak (oturmalı).
  8. Eski bir kaydı aç; kampanyası varsa devam etmeli.

## İnceleme 2. aşama: kampanya kurma (2026-11-19)
- Kampanya penceresinde açılır menü yok. Ürün, kalite, matbaa, lokasyon, kuşak, mekân gibi her seçenek küçük çizimli bir düğme; basınca seçenekler resimli kartlarla açılıyor, seçince kapanıyor.
- Tek kanallı planda anlamsız bütçe çubuğu gizli; birden çok kanalda bütçeyi böldüğünü ipucu söylüyor.
- Prova eklenince pencere artık yana kaymıyor.
- Pazarlıkta iki karakterli bir sahne var. Kurucu teklifini söylüyor; matbaacı reddederse başını sallıyor ya da kızıyor, anlaşınca masanın üstünden el sıkışıyorlar.
- Nasıl test ederim:
  1. Bir brief kabul et ve medya planına basılı bir kanal ekle (broşür, katalog). Ürün düğmesine bas; resimli kartlardan birini seç, panel kapanmalı ve düğmede yeni çizim görünmeli.
  2. İkinci bir kanal ekle; iki kanalda da bütçe çubuğu görünmeli. Birini kaldırınca çubuk kaybolmalı.
  3. Prova kutusunu işaretle; pencere yana kaymamalı.
  4. Pazarlık et'e bas. Önce çok düşük teklif ver (temsilci başını sallamalı), sonra makul bir teklif ver (eller sıkışmalı, ikisi zıplamalı).
  5. 2015 sonrası bir billboard ve influencer kanalı seç; lokasyon, süre ve influencer düğmeleri üst üste binmemeli.

## İnceleme 1. aşama: ilk açılış (2026-11-19)
- İlk brief artık oyunun ilk haftasında geliyor ve 8 hafta bekliyor; yeni oyuncu boş odaya bakmıyor, ipuçlarını okurken işi de kaçırmıyor.
- Açılış kamerası arka duvara biraz daha yakın bakıyor; kurucunun masası üst çubuğun altında kalmıyor.
- Ajans kurma ekranı:
  - Ad kutularının yanında rastgele ad öneren düğme var.
  - Geçmiş açıklamaları oyundaki etkiyi anlatıyor.
  - Seçili geçmişin en güçlü iki özelliği yeşil.
- Nasıl test ederim:
  1. Yeni Oyun'u aç. Ajans adının yanındaki dönen ok düğmesine birkaç kez bas; her seferinde yeni bir ad gelmeli.
  2. Geçmiş kartlarını sırayla seç. Alttaki açıklama ve yeşil özellikler değişmeli.
  3. Karakter adımında bir görünüş seç, ad düğmesine bas; görünüşe uygun bir ad ve soyad gelmeli.
  4. Oyuna başla ve 1× hızda bekle. Yaklaşık 3 saniye içinde yeni brief bildirimi gelmeli; brief'te uzun bir kalan süre (8 hafta civarı) yazmalı.

## Görsel elden geçirme: mini oyunlar, kampanya, okunurluk, ofis (2026-11-17)
- **Mini oyunlar:** Her prova gerçek bir sahnede oynanıyor (sokak, masa üstü, stüdyo, gökyüzü, saha).
  - Bitişte ortada büyük bir "Harika!" mührü çıkıyor; doğru hamle yeşil parlıyor, yanlış hamle sarsılıyor.
  - Ses provası bir ses düzenleme masası gibi görünüyor.
  - Billboard'daki ilan okunuyor.
- **Kampanya penceresi:**
  - Üstte Strateji → Kreatif → Prodüksiyon adımları var; şimdiki adımda kalan gün yazıyor.
  - Altındaki büyük sayaçlar puanlar geldikçe yukarı sayıyor ve "+5" gibi yükseliyor.
- **Ofis:** Masalar karşılıklı adalar halinde; çalışanlar yüz yüze oturuyor. Boş oda ahşap zeminli. Kamera biraz daha yakın.
- **Araçlar:** Her alanda sahip olduğun araçlar ve alınabilecek en yeni araç görünüyor; diğerleri "+N seçenek daha" ile açılıyor. Yazılar daha büyük.
- Nasıl test ederim:
  1. Bir kampanya başlat. Strateji provası sokak sahnesinde açılmalı; bitince ortada büyük bir mühür çıkmalı.
  2. Radyo, billboard, TV ve sosyal medya kanallı kampanyalarda provaların sahnelerine bak. Billboard'daki ilan okunmalı.
  3. Kampanya sürerken Kampanya penceresini açık tut; sayaçlar artarken "+n" yükselmeli.
  4. Ofiste birkaç kişi işe al; masalarına karşılıklı oturmalılar.
  5. Geç bir yılda Araçlar'ı aç; alan başına kısa liste ve "+N seçenek daha" görünmeli.

## Steam tanıtım videosu (2026-11-17)
- **Fragman:** `marketing/trailer/ajans_tycoon_trailer_tr.mp4`. 68 saniye, 1920×1080, 30 kare/sn, Türkçe yazılı, şimdilik müziksiz. Görüntülerin hepsi oyunun içinden.
- **Steam ekran görüntüleri:** `marketing/steam/` altında 7 adet, 1920×1080, yazısız.
- **Yeniden üretmek:** Oyun değişince fragmanı baştan çekmek için `tools\trailer\record.bat`'a çift tıkla. Ekran görüntüleri için `record.bat stills`.
- Nasıl test ederim:
  1. MP4'ü aç ve baştan sona izle. Yazı kartları okunaklı olmalı, sahneler yumuşak geçmeli.
  2. Billboard sahnesinde, taslak seçiminde seçilen ilan görünmeli.
  3. `marketing/steam` içindeki görüntüleri Steam'e yükle; boyut uyarısı çıkmamalı.

## Arayüz gözden geçirmesi (2026-11-15)
- **İkonlar:** Logoların ve ikonların üstündeki ince çizgiler (komşu ikondan kalan parçalar) temizlendi; bilgi ikonu yeniden çizildi.
- **Türkçe sayılar:** Puanlar ve çarpanlar artık virgüllü: "7,4 / 10", "×1,30".
- **İpucu:** İlk ipucu artık hız düğmelerinin üstünü kapatmıyor.
- **Pencereler:**
  - Ofis penceresi kaydırmasız sığıyor.
  - Araçlar'da sütunlar dengeli.
  - Ekipman sekmesi gruplu ve görselli.
  - Pitch sunumu yeni görünümde.
  - Raporlar listesi kartlı.
  - Boş Raporlar, Gelen Kutusu ve küçük ekipte ortada açıklama var.
- **Finans:** Gelir grafiğinin altında ay adları var; gelir yokken "Henüz gelir yok" yazıyor.
- **İnşa modu:** Espresso, filtre kahve, plak çalar, neon tabela, ofis kedisi gibi eşyalar artık kendi resimleriyle görünüyor; uzun adlar kesilmiyor.
- **Küçük düzeltmeler:**
  - Yankılar kartlarındaki puanlar aynı hizada.
  - Para değişimi yazısı kutunun altında.
  - En fazla 3 bildirim gösteriliyor.
  - Müşteri logoları tek tip kutuda.
  - Konum provasında harita ortalandı, sponsorluk rozetinde marka adı dairenin içinde.
  - Karakter ekranında kartlar hizalı.
- Nasıl test ederim:
  1. Yeni oyun aç. Karakter ekranında sol kart ızgarayla aynı boyda olmalı; ilk ipucu üst çubuğun altında çıkmalı.
  2. Müşteriler'de Lezzetçi Köfte logosunun üstünde çizgi olmamalı; logosu olmayan müşteriler de aynı kutuda görünmeli.
  3. Bir kampanya bitir. Yankılar'da puanlar "1,4" gibi virgüllü ve aynı hizada olmalı; Raporlar listesi kartlı olmalı.
  4. Finans'ı aç: grafiğin altında ay adları, gelir yoksa "Henüz gelir yok" yazmalı.
  5. Araçlar → Ekipman: Kamera, Fotoğraf… grupları iki sütunda görünmeli.
  6. İnşa modunda espresso ve kedi gibi eşyalar resimleriyle görünmeli, uzun adlar kesilmemeli.
  7. Bir pitch'e katıl: sunum ve sonuç penceresi kartlı olmalı, sonuçta bizim çubuğumuz turuncu olmalı.

## Geç oyunda puan düşüşü yumuşadı (2026-11-15)
- **Ne değişti:** Eski en iyi işin her yıl daha çabuk unutuluyor (%10 yerine %25) ve dönemin beklentisi yılda %6 yerine %5 büyüyor.
- **Sonuç:** Bilgili oyuncunun ortalaması 3. yıldan 10. yıla eskiden 1,1 puan düşüyordu, şimdi 0,8 düşüyor. İlk ödülü kazanma ihtimali de arttı.
- Nasıl test ederim:
  1. Bir oyunu birkaç yıl oyna (4× hız). Aynı kalitede iş çıkardığında puanların eskisi kadar hızlı düşmemeli.
  2. Rastgele seçimler hâlâ düşük puan almalı: bilgili oyunla fark yaklaşık 3 puan.

## Genel tarama ve düzeltmeler (2026-11-15)
- **Çökme:** İngilizce dilde Kampanya ya da Ofis penceresi açılınca oyun kapanıyordu. Düzeldi.
- **Gelen kutusu:** Pitch hazırlığı satırı hata veriyordu (aynı adlı iki çeviri). Düzeldi.
- **3D ofis:**
  - Çalışanlar artık aynı masaya yığılmıyor; herkesin kendi masası var. Masa yetmezse kişi dinlenme alanında bekler.
  - Mutfak tezgâhında artık tek lavabo var.
- **Pencereler:**
  - Olay pencerelerinde (Baskı hatası, İntihal suçlaması…) son seçenek artık kesilmiyor. Açılır pencereler de kaydırmak yerine biraz küçülüyor.
  - Taslak seçimindeki üç kart büyüdü.
  - Ofisin altındaki yardım yazısının artık okunaklı bir zemini var.
- **Rapor:** Puan dökümünde mini oyun bonusu da görünüyor.
- **Kod:** Ofis dışı (bahçe, çit, yol) ayrı bir dosyaya taşındı.
- Nasıl test ederim:
  1. Ayarlar → Dil → English. Kampanya, Ofis ve Ar-Ge pencerelerini aç: oyun kapanmamalı, hiçbirinde kaydırma çubuğu olmamalı.
  2. Türkçeye dön. Bir pitch davetini kabul et ve Gelen Kutusu'na bak: "Pitch hazırlığı: … hafta kaldı · S … · K …" satırı düzgün görünmeli.
  3. İnşa modunda masa sayısından fazla çalışan işe al ya da birkaç masa sil. Çalışanlar tek masada üst üste durmamalı; masası olmayan dinlenme alanına gitmeli.
  4. Mutfağı olan bir ofiste tezgâhta tek lavabo görünmeli.
  5. Bir olay penceresi çıktığında bütün seçenekler kaydırmadan görünmeli.
  6. Bir kampanya raporunda "Puan dökümü" sekmesinin altında "Mini oyun bonusu ×1,0xx" satırı olmalı.

## Pencereler kaydırmasız sığıyor (2026-11-14)
- **Ar-Ge ortada:** Pencere artık sağa taşmıyor.
- **Kaydırma yok:** Menü pencerelerinde içerik sığmazsa pencere büyümüyor, içerik biraz küçülüyor (en fazla %72'ye kadar).
- **Ar-Ge:** Üç sekme var: Araştırmalar, Sektör uyumu, Odak önemi. Araştırmalar sayfa sayfa geliyor, her sayfada 3 kart ve altta ◀ 1/4 ▶.
- **Finans:** Üstte Özet, Banka kredisi ve Matbaalar sekmeleri var.
- **Araçlar:** Alanlar iki sütunda gösteriliyor.
- **Kampanya:** Emek dağılımı satırları daha sıkı.
- Nasıl test ederim:
  1. Ar-Ge'yi aç. Pencere ekranın ortasında olmalı ve kaydırma çubuğu görünmemeli. ◀ ▶ ile sayfaları gez, sonra Sektör uyumu ve Odak önemi sekmelerine bak.
  2. Finans'ı aç. Özet'te dönem sekmeleri sağda görünmeli. Banka kredisi sekmesinden kredi çekmeyi dene.
  3. Araçlar, Ofis, Kampanya ve Müşteriler pencerelerinde kaydırma çubuğu olmamalı, her şey pencerenin içinde görünmeli.

## Mini oyunlar: prova pencereleri ve altı yeni oyun (2026-11-16)
- **Ayrı pencere:** Mini oyunlar artık kendi penceresinde açılıyor: "Ses provası", "Kurgu provası" gibi bir başlık, altında müşteri ve kanal, tek cümlelik görev, ortada oyun, altta "Kalan süre 04,3 sn", süre çubuğu ve Atla. Faz başında kendiliğinden açılır.
- **Sıra:** 1. fazın başında bir strateji provası (hedef kitle ya da konum), 2. fazın başında kanalın provası, 3. fazın başında taslak seçimi.
- **Yeni provalar:**
  - **Kurgu (TV, sinema, video):** üç sahneyi Giriş / Ürün / Çağrı sırasına koy.
  - **Akış (sosyal medya, dijital, influencer):** kayan telefon akışında kendi gönderini yakala.
  - **Sponsorluk:** marka rozetini formanın göğüs alanına sürükle.
  - **Açılış (etkinlik, lansman):** işaret yeşil bölgeye gelince "Kes".
  - **Hedef kitle:** brief'in kitlesine uyan kişileri seç.
  - **Konum (gerilla, halkla ilişkiler):** haritada en kalabalık noktayı seç.
- **Billboard:** yolda yeşil "doğru an" bölgesi ve "Göster" düğmesi var.
- **Görseller:** 35 sektörün hepsinin ürün görseli geldi; taslaklar sektöre uygun zemin ve efekt seçiyor.
- Nasıl test ederim:
  1. TV kanallı bir kampanya başlat. 1. faz başında "Hedef kitle provası" penceresi açılmalı: kitleye uyan kişilere tıkla. 2. faz başında "Kurgu provası" gelmeli.
  2. Sosyal medya kanallı bir kampanyada "Akış provası": telefon akışında kendi ilanını yakala.
  3. Billboard kampanyasında 1. fazda "Konum provası", 2. fazda araba yeşil bölgedeyken "Göster".
  4. Etkinlik kanalında "Açılış provası", sponsorlukta "Sponsorluk provası" gelmeli.
  5. Banka ya da oyun sektöründe taslak seçimine bak: ürün o sektörün görseli, zemin ve efekt ona uygun olmalı (oyun sektöründe gece zemininde yazı açık renk).

## Mini oyunlar ve ekibin taslakları (2026-11-16)
- **Fazlar arasında mini oyunlar:** 1. ve 2. fazın başında, kampanyanın ana kanalına göre birkaç saniyelik küçük bir oyun çıkar:
  - **Radyo:** ses dalgasının üç parçasını doğru sırayla tıkla.
  - **Billboard:** araba ilanın tam önündeyken tıkla (ya da boşluk tuşu).
  - **Gazete:** ilanı sürükleyip sayfadaki boş kutuya bırak.
- İyi oynarsan puan en çok %5 artar; atlarsan ya da kaçırırsan hiçbir şey kaybetmezsin. Her oyunda "Atla" düğmesi var; Ayarlar → Oyun'dan tamamen kapatılabilir.
- **Ekibin 3 taslağı:** Kreatif faz bitince ekip üç ilan taslağı sunar (arka plan, ürün, efekt, slogan). Seçtiğin taslak ofis duvarındaki posterde ve sokaktaki billboard'da görünür.
- Şimdilik yalnızca Fast Food'un ürün görselleri var; diğer sektörlerde taslakta ürün yerine markanın baş harfi çıkar.
- Nasıl test ederim:
  1. Yeni oyun başlat, gazete kanallı bir brief al. 1. faz başında "Mini oyun · Gazete ilanı" çıkmalı: ilanı sürükleyip boş kutuya bırak. Sonuç ("Harika! +%2.5" gibi) görünmeli, ardından emek dağılımı panosu açılmalı.
  2. 2. faz başında başka bir oyun çıkmalı (gazetede radyo dalgası). Parçaları yanlış sırayla tıklarsan parça kırmızı yanıp sönmeli.
  3. Billboard kanallı bir kampanyada arabayı ilanın önünde yakalamayı dene.
  4. 3. faz başında üç taslak çıkmalı (Fast Food'da köfte, hamburger, dürüm). Birini seç. Kampanya bitince sokaktaki billboard'a ve duvar posterine bak: seçtiğin taslak orada olmalı.
  5. Ayarlar → Oyun → "Fazlar arasında mini oyunlar" kapatılınca faz başında doğrudan pano açılmalı.

## KG1–KG3: Kampanya geliştirme — öğrenilen ipuçları, görev panosu, ekipman (2026-11-14)
- **Öğrenilen ipuçları:** Bir kampanyada bir odak alanını belirgin şekilde öne çıkarır ya da kısarsan, o hedef için o alanın önemini öğrenirsin. Raporda "Satış kampanyalarında Metin Yazarlığı çok önemli (+++)" gibi cümleler çıkar. Sonraki kampanyalarda panoda alan adının altında işaret görünür (+++ … −−−, bilinmiyorsa "?"). Bilgi Defteri'nde yeni "Hedef × odak alanı" tablosu var.
- **Görev panosu:** Faz başında kaydırıcılar yerine bir pano açılır. Satırlarda ekip, sütunlarda fazın üç alanı var. Hücreye sol tıklamak kişinin zamanının %25'ini o alana verir, sağ tık geri alır. Sağda kişinin yükü görünür:
  - %100'e kadar normal.
  - Üstünde kişi daha çok iş çıkarır ama verimi düşer, çabuk yorulur, hata yapar.
  - Görev verilmeyen ekip üyesi o fazda dinlenir.
  - Odak dağılımı ekibin emeğinden hesaplanır.
  - "Otomatik dağıt" herkesi en güçlü alanına koyar.
- **Ekipman:** Araçlar → Ekipman sekmesinden kamera (VHS'ten 4K'ya), fotoğraf seti, ışık, ses, yeşil perde ve drone alınır. Prodüksiyon alanında üretimi artırır; etkisi kampanyanın kanallarına bağlı (kamera TV ve videoda, fotoğraf basılı işte, ses radyoda işe yarar). Aylık bakımı var. Stüdyo, film ekibi, drone ekibi ve helikopter çekimi prodüksiyon fazının panosunda kampanya başına kiralanır.
- Nasıl test ederim:
  1. Yeni oyun başlat, bir brief al. Faz başında görev panosu açılmalı. Hücrelere tıklayınca yüzde artmalı, sağ tıkla azalmalı. Yük göstergesi %100'ü geçince sarıya, %150'yi geçince kırmızıya dönmeli.
  2. Bir alana %100, diğerlerine %0 vererek kampanyayı bitir. Raporda "✎ … çok önemli / pek önemli değil" cümleleri çıkmalı.
  3. Aynı hedefle yeni bir kampanya başlat. Panoda o alanın altında "?" yerine işaret görünmeli. Ar-Ge → Bilgi Defteri'nin en altında hedef × odak tablosunda da görünmeli.
  4. Bir çalışan işe al. İkinci kampanyada çalışanı hiçbir alana koyma: enerjisi o fazda artmalı. İkisini de %200'e çıkar: enerjileri hızla düşmeli.
  5. Araçlar → Ekipman'dan VHS kamera al, TV kanallı bir kampanya yap. Prodüksiyon fazının panosunda "Ekipman · prodüksiyon ×1.08" yazmalı; bir kiralık seçince sayı artmalı, faz başlarken parası düşülmeli.
  6. Finans'ta aylık giderlerde ekipman bakımının çıktığını kontrol et.

## İnşa modunda duvar ve kapı (2026-11-15)
- **Duvar çek:** İnşa modu → Duvarlar → Duvar. Ofiste sürükleyerek yatay ya da dikey duvar çekersin; önizleme yeşilse
  olur, kırmızıysa durum satırı nedenini yazar. Fiyat metre başı (1990'da ₺150/m); durum satırında uzunluk ve tutar.
- **Kapı:** Duvarlar → Kapı, sonra bir iç duvara tıkla: 1,6 m'lik kapı boşluğu açılır (₺400).
- **Yık:** "Sat" aracıyla (ya da imleç üstündeyken Del) iç duvara tıkla: duvar yıkılır. Kendi çektiğin duvarın yarı
  parası geri gelir; ofisle gelen duvarları yıkmak bedava. Açtığın bir kapıya tıklarsan kapı kapanır.
- **Odalar:** Bir odanın duvarını yıkarsan oda "açık alan" sayılır ve odanın etkisi gider; duvarı geri çekince döner.
- Dış duvarlara dokunulmaz; kimseyi bir yere kapatan duvar çekilemez.
- Nasıl test ederim:
  1. Bir oyun aç, inşa moduna gir, "Duvarlar" sekmesini seç, "Duvar"ı seç ve boş bir yerde sürükle: yeşil önizleme
     ve "2,5 m · ₺375" gibi bir yazı görmelisin; bırakınca duvar çıkmalı, para azalmalı.
  2. Masanın üstünden ya da girişin önünü kapatacak şekilde çekmeyi dene: kırmızı olmalı ve çekilmemeli.
  3. "Kapı"yı seçip bir iç duvara tıkla: duvarda boşluk açılmalı, çalışanlar oradan geçebilmeli.
  4. "Sat" aracıyla toplantı odasının bir duvarına gel: duvar kırmızımsı yanmalı; tıklayınca yıkılmalı.
  5. Kaydet, yükle: duvarlar aynı kalmalı.
  6. Hepsini tek seferde görmek: `godot --path . res://tools/wall_shots.tscn --resolution 1672x941 -- --out=<klasör>`.

## Müşteri kartı, ödül töreni, taslağı olmayan pencereler (2026-11-15)
- **Müşteri kartı:** Müşteriler ekranında bir karta (ya da sağdaki oka) basınca açılır: bütçe, beklediği puan, ortalama
  puan, memnuniyet, güven ve o müşteriyle yapılan kampanyalar ("Raporu aç" ile rapor).
- **Ödül töreni:** Taslaktaki gibi perdeler, defne dalları, konfeti, ışıltılar, kırmızı halı, derece kurdelesi; başlıkta
  ödül amblemi; altta rakipler, Grand Prix ve "ödül sezonu".
- **Yeni görünüm:** Skandal (üç seçenek kartı), ödül başvurusu, yeni dönem, rakip teklifi, matbaa pazarlığı, ihale daveti,
  iflas ve "kaydedilmemiş ilerleme" pencereleri taslakların diliyle yeniden düzenlendi.
- **Düzeltme:** İngilizcede ofis adı ("Spare room / garage") kesilmiyor; uzun kart başlıkları "…" ile biter, üzerine
  gelince tamamı görünür.
- Nasıl test ederim:
  1. Müşteriler ekranını aç, bir müşteri kartına bas: müşteri kartı açılmalı. Kampanya yaptığın bir müşteride
     "Raporu aç" raporu göstermeli.
  2. Sektör → bir ödüle "Başvur": amblemli kart, ücret / başvuru ayı / tören ayı ve kampanya kartları görünmeli.
  3. Bir ödül törenini bekle (ya da ekran turunu çalıştır): sahne taslak 21'e benzemeli; gümüş, altın ve bronzda kurdele
     rengi değişmeli.
  4. Ayarlar → Dil → English: pencerelerde kesik ya da taşan yazı olmamalı.
  5. Pencereleri tek seferde görmek: `godot --path . res://tools/dialog_shots.tscn --resolution 1672x941 -- --out=<klasör>`
     (İngilizce için `--lang=en`).

## Oda içi ışıklar (2026-11-15)
- **Masa lambaları:** Her masada yeşil şapkalı küçük bir lamba; masa üstüne sıcak bir ışık havuzu düşürüyor.
- **Tavan ışığı:** Çalışma, toplantı, mutfak ve dinlenme odalarının ortasında yumuşak, sıcak bir ışık.
- **Düşük grafik:** Ayarlar → Ekran → Düşük seçilince bu ışıklar kapanır.
- Görüntüler: `docs/screenshots/29_3d_lamba*.png`.
- Nasıl test ederim:
  1. Bir oyuna gir ve bir masaya yakınlaş: masanın arka sağ köşesinde lamba, masa üstünde sıcak ışık görünmeli.
  2. İşe biri al: yeni masada da lamba çıkmalı.
  3. Ayarlar → Ekran → Grafik kalitesi Düşük: lambaların ışığı kapanmalı.

## 3D sahne: sıcak minyatür görünümü (2026-11-15)
- **Işık:** Alçak, sıcak akşamüstü güneşi; uzun ve yumuşak gölgeler; gölgeli yerler hafif serin. Renkler daha uyumlu, daha az doygun.
- **Kamera:** Açılışta ofis ekranın çoğunu kaplar; kenarlar hafif bulanık (maket etkisi).
- **Malzemeler:** Zemin koyu ceviz, masalar zeminden ayrılıyor; mutfak karosu kırık beyaz; duvar kapakları ince.
- **Dekor:** Oda köşelerine saksılar; binanın çevresinde çalı ve ağaçlar. Sahnenin kenarı karanlık boşluk yerine çimle devam edip sise karışıyor.
- Önce / sonra: `docs/screenshots/28_3d_once.png` → `28_3d_sonra*.png`.
- Nasıl test ederim:
  1. Bir oyuna gir: ışık sıcak ve alçak gelmeli, gölgeler uzun ve yumuşak olmalı.
  2. Tekerlekle en uzağa çık: sahnenin kenarı karanlık bir boşlukla değil, çim ve sisle bitmeli.
  3. Q / E ile döndür: binanın her yanında çalı ve ağaç olmalı; sokak tarafı açık kalmalı.
  4. Oda köşelerinde saksılar olmalı; kapı ağızlarında olmamalı. Çalışanlar saksıların içinden geçiyorsa bana yaz.
  5. Ayarlar → Ekran → Grafik kalitesi Düşük: görüntü sadeleşmeli ama renkler aynı kalmalı.

## Yazı tipleri (2026-11-15)
- **Başlıklar:** Lora Bold (pencere başlıkları, kart ve bölüm başlıkları, logo, büyük sayılar).
- **Menü ve açıklamalar:** Source Sans 3 (düğmeler, listeler, tablolar, bildirimler); kalın yerlerde SemiBold.
- **İtalik:** Alt yazılar, yorum alıntıları ve logo gerçek italik kesimle yazılıyor.
- Görüntüler: `docs/screenshots/27_font_*`.
- Nasıl test ederim:
  1. Ana menüyü aç: logo eğik Lora, düğmeler Source Sans 3 olmalı.
  2. Bir oyuna gir ve birkaç menü aç: pencere başlıkları Lora Bold, içerik Source Sans 3 olmalı.
  3. Türkçe karakterleri kontrol et: ı, İ, ş, ğ, ü, ö, ç her yerde doğru görünmeli.

## UI-3 (8. adım): Yankılar, kanal seçici, işe alım (2026-11-14)
- **Kampanyanın yankıları:** Kampanya bitince önce dört yayının puanı ve yorumu, altında genel değerlendirme. "Raporu incele" ayrıntılı raporu açar.
- **Kanal seçici:** Yeni kampanyada kanal satırına basınca açılır; kategori etiketleri, arama ve çizimli kanal düğmeleri var.
- **İşe alım:** Aday kartlarında portre, tam adlı stat rozetleri (pozisyonun ana statları yeşil), özellik etiketleri.
- Görüntüler: `docs/screenshots/26_pencere_*`.
- Nasıl test ederim:
  1. Bir kampanyayı bitir: önce "Kampanyanın yankıları" açılmalı. "Raporu incele"ye bas: rapor açılmalı. "Kapat" raporu açmadan kapatmalı.
  2. Bir brief kabul et, kanal satırındaki düğmeye bas: kanal seçici açılmalı. Bir kategori etiketine bas, arama kutusuna yaz, bir kanal seç: satırdaki ad ve çizim değişmeli.
  3. Ekip → "+ İşe al" → "Aday ara": aday kartları portreli olmalı; "İşe al" çalışmalı.

## UI-3 (5.–7. adım): Taslak ölçüleri, görsel paketi, panel ayrıntıları (2026-11-14)
- **Boyutlar:** Her pencere kendi taslağındaki genişlik ve yükseklikte. Üst kutular ve alt menü Ayarlar taslağının ölçülerinde.
- **Hız kutusu:** Duraklat ayrı yuvarlak düğme; seçili hız kiremit kutuda, önünde oynat işareti.
- **İnşa modu:** Alt menü gizlenir; çubuk alçak ve geniş; eşya kartlarında resim; oda çizme "Odalar" sekmesinde.
- **Görseller:** Simge paketi, marka / rakip / ödül logoları, kanal ve araştırma çizimleri, ofis ve masa resimleri, tören perdesi ve kupaları, sekiz çalışan portresi.
- **Taşınanlar:** Yükle ve ana menüye dön Ayarlar → Oyun sekmesinde; mesai anahtarı Kampanya penceresinde.
- **Ayrıntılar:** Ekip, Müşteriler, Finans, Sektör, Ar-Ge ve Araçlar taslaklarıyla karşılaştırılıp düzeltildi.
- Görüntüler: `docs/screenshots/24_gorsel_*`, `25_panel_*`.
- Nasıl test ederim:
  1. Ayarlar taslağını yanına aç: üstteki üç kutu ve alt menü aynı yerde ve boyda olmalı.
  2. 1× hızda "▶ 1×" kiremit kutuda olmalı; duraklatınca yuvarlak düğme dolmalı.
  3. Her menüyü taslağıyla karşılaştır: pencere boyutu aynı olmalı.
  4. Ofis → inşa modu: alt menü kaybolmalı; eşya kartlarında resim olmalı; "Odalar" sekmesinden oda çizebilmelisin.
  5. Ayarlar → Oyun: "Yükle" ve "Ana menü" orada olmalı. Kampanya penceresinde "Mesai" anahtarı çalışmalı.
  6. Sektör → Rakip ajanslar: logolar görünmeli. Bir ödül töreninde perde ve elma kupası görünmeli.

## UI-3 (3.–4. adım): İkon paketi, Kampanya, sihirbaz, rapor, inşa modu, tören (2026-11-14)
- **İkonlar:** Gönderdiğin ikon paketi alt menüde, üst kutularda ve pencerelerde. Logo, altın ve yıldız renkli.
- **Kampanya:** Müşteri ve ekip başlığı, faz şeridi, dört sayaç kutusu, ikonlu emek kaydırıcıları, yeşil "Fazı başlat".
- **Yeni kampanya:** İki sütun: solda kampanya bilgileri, sağda medya planı ve ekip; üstte ücret, medya bütçesi, süre.
- **Kampanya raporu:** Üstte genel puan; dört sekme: Özet, Yorumlar, Gelir ve kazanımlar, Puan dökümü.
- **İnşa modu:** İki kutu: solda döndür / sat ve durum, sağda Tümü / Bitkiler / Diğer sekmeleri ve eşya kartları.
- **Ödül töreni:** Kampanya adı, müşteri, derece renginde kupa ve derece şeridi; altında rakipler ve Grand Prix.
- Görüntüler: `docs/screenshots/22_ui3_*`.
- Nasıl test ederim:
  1. Bir brief kabul et: yeni kampanya penceresi iki sütunlu olmalı. Kanal ekle, payı kaydır, kampanyayı başlat.
  2. Kampanya penceresinde kaydırıcıları oynat: sağdaki yüzdeler değişmeli. "Fazı başlat"a bas.
  3. Kampanya bitince rapor açılır: dört sekmeye sırayla bas; "Kapat" her sekmede altta görünmeli.
  4. Ofis → "İnşa moduna geç": bir eşya kartına bas, ofise yerleştir; Bitkiler sekmesine geç; "Sil / sat" ile bir eşyayı sat.
  5. Alt menüdeki ikonlar paketteki ikonlar olmalı; açık olan yeşil, diğerleri kiremit.

## UI-3 (2. adım): Küçük pencereler, dört panel ve olay penceresi (2026-11-14)
- **Pencere boyutları:** Menü pencereleri taslaklardaki ölçüye indi. Açılır pencereler artık içerikleri kadar yer kaplıyor; boş alan kalmıyor.
- **Ar-Ge:** İkonlu kartlar; koşullar etiket hâlinde; sağda AP, para ve süre alt alta; yeşil "Araştır".
- **Araçlar:** Üstte bilgisayar ve aylık abonelik; alan alan şeritli tablo; kullanılan araçta "Kullanılıyor" etiketi.
- **Ofis:** Solda mevcut ofis, sağda sonraki ofis ve taşınma koşulları. Masa kademeleri seçim kartı.
- **Sektör:** Ödül satırları kiremit ikonlu; rakipler tabloda, güçleri çubukla.
- **Olay penceresi:** Tür etiketi ve oklu seçenek satırları; stat kontrolü sağda yüzdeyle.
- **Ekip:** Sütunlar daraldı, tablo küçük pencereye sığıyor.
- Görüntüler: `docs/screenshots/21_ui3_*`.
- Nasıl test ederim:
  1. Menülerin hepsini sırayla aç: hiçbiri ekranın üçte ikisinden yüksek olmamalı, bildirimlerin üstüne binmemeli.
  2. Ar-Ge'de bir araştırma kartına bak: koşul etiketleri (✓ / ✗) ve sağda üç satır maliyet olmalı.
  3. Araçlar'da bir araç al ya da aboneliği bitir: satır hemen güncellenmeli.
  4. Ofis'te masa kademesi kartına bas: kullanılan kart turuncu çerçeveli olmalı; "İnşa moduna geç" çalışmalı.
  5. Sektör → Rakip ajanslar: güce göre sıralı tablo ve çubuklar görünmeli.
  6. Bir olay çıkınca: pencere küçük olmalı, seçenekler ok işaretli satırlar hâlinde durmalı.

## UI-3 (1. adım): Taslaklara göre kabuk, tema ve üç ekran (2026-11-14)
- **Kabuk:** Sol üstte ajans kartı ve küçük oyun düğmeleri, üst ortada tarih ve hız, sağ üstte para ve itibar, alt ortada krem menü çubuğu. Pencereler ekranın ortasında açılır.
- **Tema:** Koyu yeşil başlıklar, yeşil ana düğmeler, serif yazı, kiremit renkli ikonlar.
- **Ekip:** Tablo hâlinde. Çalışan arama, rol süzgeci ve sıralama var. Satıra tıklayınca altında özellikler, maaş ve eğitim / zam / kovma düğmeleri açılır.
- **Müşteriler:** Arama ve sektör süzgeci; memnuniyet ve güven çubukları; sağda yıllık bütçe ve kampanya sayısı.
- **Gelen Kutusu:** Tümü / Briefler / Teklifler sekmeleri; her kartta ücret, medya bütçesi ve süre yan yana.
- Taslaklar: `docs/reference/ui_mockups/`. Görüntüler: `docs/screenshots/20_ui3_*`.
- Nasıl test ederim:
  1. Bir oyuna gir: üstte üç krem kutu, altta ortada krem menü çubuğu olmalı.
  2. Menü ikonlarına bas: pencere ekranın ortasında açılmalı, açık olanın ikonu yeşil olmalı.
  3. Ekip'i aç, bir satıra tıkla: altında ayrıntı ve düğmeler açılmalı; tekrar tıklayınca kapanmalı. Arama kutusuna bir ad yaz: liste süzülmeli.
  4. Müşteriler'de arama kutusuna yaz ve sektör seç: liste süzülmeli.
  5. Gelen Kutusu'nda sekmeler arasında geç: Briefler yalnızca briefleri, Teklifler yalnızca tedarikçi tekliflerini ve ihale davetlerini göstermeli.
  6. Hız düğmelerine bas: seçili hız kiremit renginde olmalı.

## C3: Tek dok, pencereler ortada (2026-11-13)
- **Dok:** Her şey altta tek çubukta. Üst satırda menü ikonları; alt satırda solda mesai/duraklat/hız ve tarih, ortada ajansının adı, sağda para ve itibar.
- **Pencereler:** Menüye basınca pencere dokun hemen üstünde, ortada açılır. İçeriği kadar yer kaplar; uzun içerik kayar.
- **Sağ üst:** Yalnızca küçük kaydet/yükle/ayarlar/çıkış düğmeleri ve bildirimler.
- **İnşa modu:** Çubuk dokun üstünde, ortada açılır.
- **Daha ince başlıklar:** Pencere başlık bantları küçüldü.
- Görüntüler: `docs/screenshots/19_dock_*`.
- Nasıl test ederim:
  1. Bir oyuna gir. Altta tek çubuk olmalı; sol, sağ ve üst (sağ üst köşe hariç) boş kalmalı.
  2. Menü ikonlarına sırayla bas: pencere ortada, çubuğun hemen üstünde açılmalı; aynı ikona tekrar basınca kapanmalı.
  3. Raporlar gibi kısa bir pencere küçük, Ekip gibi uzun bir pencere daha yüksek açılmalı; Ekip'te içerik tekerlekle kaymalı.
  4. Ofis → "İnşa moduna geç": inşa çubuğu aynı yerde açılmalı.
  5. Hız düğmelerine ve duraklat'a bas: seçili olan turuncu olmalı, tarih yanında ilerlemeli.

## C2: Yeni kartlar — Ekip, Müşteriler, Gelen Kutusu (2026-11-13)
- **Ekip:** Her çalışanın portresi var. Statlar tam adıyla rozet hâlinde (üzerine gelince açıklama); enerji yeşil, moral turuncu, tükenmişlik kırmızı çubuk. Özellikler ve uzmanlık küçük etiket.
- **Çalışan kartı:** Ofiste tıklanan herkesin portresi görünür.
- **Müşteriler:** İkonlu başlık, renkli memnuniyet çubuğu, kırmızı "RİSKLİ" etiketi.
- **Gelen Kutusu:** İkonlu başlık, "yeni müşteri" ve süre etiketleri; "Kabul et" turuncu.
- **Düzeltmeler:** Pencere açıkken kontrol ipucu yazısı gizlenir; uçan "+₺" yazısı tarihin üstüne binmez.
- Görüntüler: `docs/screenshots/18_cards_*`.
- Nasıl test ederim:
  1. Ekip'i aç: her kartta portre, altı stat rozeti ve üç renkli çubuk olmalı. Fareyi bir rozetin üstünde beklet: açıklama çıkmalı.
  2. "Eğit" yanındaki listede statlar tam adıyla yazmalı (Strateji, Kreatif…).
  3. Müşteriler'i aç: memnuniyeti düşük müşteride çubuk kırmızı ve "RİSKLİ" etiketi olmalı.
  4. Gelen Kutusu'nda bir brief kartına bak: "Kabul et" turuncu, süre sağ üstte etiket olmalı.
  5. Ofiste bir çalışana tıkla: sağ alttaki kartta portresi görünmeli.

## C1: Alt çubuk düzeni (2026-11-13)
- **Kenarlar boş:** Soldaki dikey ikon çubuğu kalktı. Menü ikonları ekranın altında, ortada tek sıra duruyor.
- **Alt çubuk:** Solda kaydet/yükle/ayarlar/çıkış, ortada menüler, sağda mesai, duraklat ve hız.
- **Sağ üst:** Tarih, para ve itibar yan yana; bildirimler altında.
- **Pencereler küçüldü:** Menü penceresi sol altta, çubuğun üstünde açılıyor ve ekranın yarısını kaplamıyor. İçerik uzunsa kayıyor.
- Görüntüler: `docs/screenshots/17_bottombar_*`.
- Nasıl test ederim:
  1. Bir oyuna gir. Sol ve sağ kenar boş olmalı; ikonlar altta ortada dizili olmalı.
  2. Alt çubuktaki ikonlara sırayla tıkla: pencere sol altta açılmalı, aynı ikona tekrar basınca kapanmalı.
  3. Finans'ı aç: pencere ekrandan taşmamalı, içerik fare tekerleğiyle kaymalı.
  4. Ofis → "İnşa moduna geç": inşa çubuğu alt çubuğun hemen üstünde açılmalı.
  5. Bir çalışana tıkla: kartı sağ altta, hız düğmelerinin üstünde çıkmalı.

## A1: Yeni açılış ve karakter sayfaları (2026-11-13)
- **Ana menü:** Oda illüstrasyonu arka planda; sağda eğik logo, kâğıt etiket ve ikonlu büyük düğmeler.
- **"Sen kimsin?":** Küçük pencere yerine tam sayfa. Dört geçmişin portresi var; başlangıç yılı hap biçimli düğmelerle seçilir.
- **Stat açıklamaları:** S K T İ H D yerine tam adlar yazıyor (Strateji, Kreatif, Teknik, İletişim, Hız, Dikkat). Üzerine gelince ne işe yaradığı çıkıyor.
- **"Karakterini oluştur" (yeni):** 11 avatardan birini seç, adını yaz. Solda seçimin büyük hâli görünür.
- **Oyun içinde:** Ad girdiysen "Sen" yerine adın yazar; ofiste kendi karakterine tıklayınca kartında avatarın görünür.
- Görüntüler: `docs/screenshots/16_menu_*`.
- Nasıl test ederim:
  1. Oyunu aç. Ana menüde oda resmi, eğik "Ajans Tycoon" logosu ve düğmeler görünmeli.
  2. "Yeni Oyun"a bas. "Sen kimsin?" sayfasında dört portreye sırayla tıkla: alttaki açıklama ve stat sayıları değişmeli.
  3. Fareyi "Strateji 65" gibi bir rozetin üstünde beklet: kısa açıklama çıkmalı.
  4. "Devam Et"e bas. Bir avatar seç ve adını yaz: soldaki büyük kartta resim ve ad hemen değişmeli. "Geri" ile dönünce ilk sayfadaki seçimlerin durmalı.
  5. "Oyuna Başla"ya bas. Ofiste kendi karakterine tıkla: kartta avatarın ve adın görünmeli. Ekip panelinde de adın yazmalı.
  6. Kaydet, ana menüye dön, "Devam Et": ad ve avatar korunmuş olmalı.

## B1: Daha pürüzsüz 3D görüntü (2026-11-13)
- **Kenarlar:** Sandalye ayağı, bank, duvar kenarı gibi ince çizgilerdeki tırtıklar giderildi.
- **Dokular:** Duvar kâğıdı, çim ve halı uzaktan bakınca artık kumlanmıyor.
- **Işık:** Gölgeler daha açık ve yumuşak, kontrast daha düşük; görüntü daha sıcak ve sakin.
- **Grafik kalitesi:** Ayarlar → Ekran'da Düşük / Orta / Yüksek seçeneği var (varsayılan Yüksek).
- Önce/sonra görüntüleri: `docs/screenshots/14_cast_*` ve `15_smooth_*`.
- Nasıl test ederim:
  1. Oyunu aç, bir kayda gir. Ofise bak: masa ve sandalye kenarları pürüzsüz olmalı, duvar kâğıdı kamerayı kaydırırken titreşmemeli.
  2. Tekerlekle yakınlaş ve uzaklaş: zemin tahtaları ve çim her mesafede temiz görünmeli.
  3. Ayarlar → Ekran → Grafik kalitesi'ni Düşük yap: görüntü hemen biraz kabalaşmalı, gölgelerin köşe kararması kaybolmalı. Yüksek'e geri al.
  4. Kamera ya da karakterler hâlâ takılıyorsa bana yaz; o ayrı bir konu.

## M10-B: Denge ve tempo ölçümü (2026-11-13)
- **Puanlar daha keskin:** Doğru hedef/kitle/ton/kanal seçimi eskisinden çok daha fazla ödüllendiriliyor, yanlış seçim daha çok cezalandırılıyor. Rastgele oynayan ortalama 4.5, bilen oyuncu 7.1 alıyor (önce 6.3 / 7.5).
- **Tekrar cezası:** Aynı ana kanalı üst üste üç kampanyada kullanmak yenilik puanını düşürüyor.
- **Ödüller:** Başvurmak için en az 15 itibar gerekiyor; ilk ödül 4. yıl yerine 6. yılda geliyor.
- **Geç oyun:** Dönem beklentisi daha yavaş büyüyor; 30. yıldaki puan düşüşü azaldı.
- **Tempo ölçümü:** Ayarlar → Tempo, her oyun yılının gerçekte kaç dakika sürdüğünü gösteriyor. Hız değişmedi; kararı bu sayılarla vereceğiz.
- Nasıl test ederim:
  1. 1990'da yeni oyun başlat ve 3–4 kampanya yap. Bilgi Defteri'nde yeşil hücrelere uyan seçimler belirgin şekilde yüksek, kırmızılar belirgin şekilde düşük puan almalı.
  2. Aynı ana kanalı (ör. radyo) üst üste üç kampanyada kullan. Üçüncünün raporunda "daha önce gördük" türü bir açıklama ve daha düşük puan görmelisin.
  3. İtibarın 15'in altındayken ödül başvurusu "itibarın yetmiyor" uyarısı vermeli.
  4. Normal oynadığın gibi 2–3 oyun yılı oyna, sonra Ayarlar → Tempo'yu aç. Her yıl için toplam ve akan dakika görünmeli; bu sayıları bana yaz.
  5. Denge raporu: `docs/balance-report.md` (en altta önce/sonra tablosu).

## K4–A2–B1: Mixamo karakterleri, yeni eşyalar, kolay yerleştirme (2026-11-12)
- **Karakterler:** Kadroya 6 karakter eklendi. Askılı pantolonlu adam 1990'larda, dört kadın 2000'lerde, bulutlu ceketli adam 2020'lerde işe alınanlarda görünür. Kadro aracı artık Mixamo FBX dosyalarını da okuyor; yatık gelen karakteri kendisi dikiyor.
- **Eşyalar:** Kitaplık, bitki rafı, ofis kedisi, turkuaz bilgisayar (g4), laptop + monitör (mchip), bank ve sokak feneri yeni modellerle değişti.
  - Yeni satın alınabilir eşyalar: asılı saksı, çiçek kasası, örgü halı.
  - Halının üstünden yürünür ve üstüne eşya konur.
  - Mutfakta lavabolu tezgâh var; bina önünde çit çalısı, top çalı ve tahta çit duruyor.
- **İnşa modu:**
  - Yerleştirirken kutunun içinde eşyanın kendisi yarı saydam görünür.
  - Eşya ↺ ↻ düğmeleriyle ya da R / Shift+R ile 4 yöne dönebilir.
  - "Sil / sat" düğmesi paletin başında sabit durur. Silerken imlecin altındaki eşya kırmızı yanar ve kaç para geri geleceği yazar.
  - Delete tuşu imlecin altındaki eşyayı satar.
- Nasıl test ederim:
  1. 2000'de yeni oyun başlat, birkaç kadın çalışan işe al: yeni dört kadından biriyle gelmeliler. 1990'da erkekler askılı pantolonlu adamla gelmeli.
  2. İnşa moduna geç, "Bitki rafı"nı seç ve fareyi ofiste gezdir. Yeşil kutunun içinde rafın kendisi görünmeli; uygun olmayan yerde kırmızıya dönmeli.
  3. ↻ düğmesine ya da R tuşuna bas: eşya 90° dönmeli. Dört basışta başa dönmeli; Shift+R ters yöne çevirir.
  4. Örgü halıyı yerleştir, sonra üstüne küçük bitki koy: izin vermeli. Çalışanlar halının üstünden yürümeli.
  5. Sol baştaki kırmızı "Sil / sat"a bas, fareyi bir eşyanın üstüne getir. Eşya kırmızı yanmalı, altta "Tıklarsan … satılır, ₺… geri gelir." yazmalı. Tıkla: eşya gitmeli.
  6. Herhangi bir araçla bir eşyanın üstündeyken Delete'e bas: eşya satılmalı. Oda yıkılmamalı.
  7. Asılı saksıyı yerleştir: yerden yüksekte durmalı. Mutfakta lavabolu dolaplar, bina önünde çalılar ve çit görünmeli.

## K2–K3: Kadro karakterleri için toplu araç ve rehber (2026-11-07)
- Karakterleri `art/incoming/cast/` klasörüne `char_<dönem>_<f|m|n><sıra>.glb` adıyla koyman yeterli. Tek komut hareketleri aktarır, saçı düzeltir ve karakteri oyuna ekler.
- İskeleti olmayan dosya atlanır ve uyarı verilir.
- Rehberin karakter bölümü ve 24 kişilik liste yeni adlarla güncellendi; prompt kartları yeni bağlantıda.
- Nasıl test ederim:
  1. Tripo'da bir karakteri Rig'le, GLB indir, örneğin `art/incoming/cast/char_1990_m01.glb` olarak kaydet.
  2. `"C:/Program Files (x86)/Steam/steamapps/common/Blender/blender.exe" --background --python tools/blender/build_cast.py`
  3. Çıktıda "Kadroya eklendi: char_1990_m01" görmelisin.
  4. 1990'da yeni oyun başlatıp erkek çalışan işe al: yeni karakterle gelmeli.

## K1: Tripo karakterleri çalışanlarda (2026-11-07)
- 2020 ve sonrasında işe alınan kadın ve nötr çalışanlar artık Tripo karakteri olarak görünüyor: dokulu yüz, saç ve kıyafet. Yürüyor, oturuyor, yazıyor ve diğer 11 hareketi yapıyor.
- Telefonla konuşurken elinde telefon, kahve içerken kupa var.
- Çalışan işe alındığı dönemin karakterinde kalır; uygun Tripo karakteri olmayanlar eskisi gibi görünür.
- Kadroda şimdilik bir karakter var; yeni karakterler geldikçe çeşitlenecek.
- Nasıl test ederim:
  1. 2020'de yeni oyun başlat ve birkaç kadın çalışan işe al: Tripo karakteriyle gelmeliler.
  2. Telefonla konuşan ya da mutfakta kahve içen birine bak: elde telefon / kupa.
  3. 1990'da başlayan bir oyunda çalışanlar eskisi gibi olmalı.
  4. `docs/screenshots/14_cast_world_close.png` ve `14_cast_coffee.png`.

## A1: Tripo eşyaları: koltuk, kanepe, 90'lar bilgisayarı, sokak ağacı (2026-11-07)
- Masalarda yeni yeşil, turuncu kolçaklı koltuklar; çalışanlar üzerlerine oturuyor.
- 90'larda masalarda bej tüplü monitör, kasa ve klavye.
- Dinlenme odasında düğmeli yeşil kanepe; sokakta yapraklı ağaçlar.
- İki deneme karakteri iskelet dosyası gelince eklenecek.
- Nasıl test ederim:
  1. 1990'da yeni oyun başlat: masada bej bilgisayar, önünde yeni koltuk olmalı.
  2. Ofisin önündeki sokağa bak: yeni ağaçlar.
  3. Dinlenme odası olan bir ofiste kanepeye bak.
  4. `docs/screenshots/12_tripo_props_desk.png` ve `12_tripo_props_sofa.png`.

## T1: Zemin, duvar ve sokak dokuları (2026-11-07)
- **Ofis artık dokulu:**
  - Çalışma alanında bal tonlu tahta zemin, toplantıda yeşil halı, mutfakta krem fayans, boş alanda beton.
  - Duvar kâğıtları: çalışma alanı yapraklı, mutfak noktalı, toplantı çizgili.
  - Dışarıda çiçekli çimen, parke taşı kaldırım, asfalt yol.
- Dokular kenarlardan birbirine kusursuz bağlanıyor; iki tanesi bunun için desen aralığında kırpıldı.
- Balıksırtı koyu zemin kenarlarda kırıldığı için şimdilik eklenmedi; yeni prompt'u rehberde.
- Nasıl test ederim:
  1. Oyunu aç ve bir oyun başlat: zeminler ve duvarlar dokulu olmalı.
  2. Kamerayı yaklaştır: tahtalarda ve taşlarda kare kare tekrar eden çizgi ya da kopukluk olmamalı.
  3. Q/E ile döndürüp dört yönden bak.
  4. Yeni bir doku üretirsen `art/incoming/textures/` klasörüne koy ve `godot --headless --script res://tools/prepare_textures.gd` çalıştır (ya da bana söyle).
  5. `docs/screenshots/11_textures_world_default.png` ile `07_c3_world_default.png`'yi karşılaştır.

## UI-2: Cozy Refined bütün oyunda (2026-11-07)
- **Bütün pencereler yeni görünümde:** üstte koyu yeşil başlık bandı, ikon, zarif serif başlık ve kapat düğmesi; krem gövde, ince çerçeve.
- **Ekranın kenarları:**
  - Sol ikon çubuğu koyu yeşil; açık olan ekranın ikonu turuncu.
  - Para, itibar ve tarih krem kutularda; hız ve kaydet düğmeleri koyu yeşil haplarda.
- **Ana menü:** Logo, kâğıt etiketli alt başlık, ikonlu düğmeler. Arkaya bir illüstrasyon koyabilirsin; prompt'u `art/ai_rehberi.md` 10. bölümde.
- **Ayarlar:** Solda ikonlu sekmeler (Ses, Oyun, Ekran, Dil), açma/kapama anahtarları.
- **Sen kimsin?:** Geçmişler yan yana kartlar; seçince açıklaması ve statları görünür.
- **Finans:**
  - "Bu ay / Son 3 ay / Bu yıl" sekmeleri; nakit, gelir ve gider şeridi.
  - İkonlu satırlar ve son 6 ayın gelir grafiği.
- **Sektör:** Ödül takvimi, sıralamalar ve rakipler ayrı sekmelerde; ödüller ikonlu kartlar.
- **Diğer düzeltmeler:**
  - Düğmelerdeki "ş" sorunu her yerde düzeldi.
  - Çalışan kartı artık sağ altta açılıyor, pencereleri örtmüyor.
- Nasıl test ederim:
  1. Oyunu aç: ana menü yeni düzende.
  2. Yeni oyun → "Sen kimsin?" kartlarına tıkla; açıklama ve statlar değişmeli.
  3. Oyunda sol çubuktan her ekranı aç: hepsinde yeşil başlık bandı ve ikon olmalı.
  4. Finans: sekmeleri değiştir. Birkaç ay oynayınca grafik dolmalı ve gelir/gider sekmeye göre değişmeli.
  5. Ayarlar: sekmeler arasında geç, ses kaydırıcısını ve anahtarları dene.
  6. Bir çalışana tıkla: kart sağ altta açılmalı.
  7. `docs/screenshots/10_ui2_*.png`.

## UI-1: Cozy Refined arayüz, ilk iki ekran (2026-11-07)
- **Yeni ana menü:** Orman yeşili zemin üstünde krem kart, büyük başlık. Turuncu tek ana düğme: kayıt varsa "Devam et", yoksa "Yeni oyun". Çıkış sade bir yazı düğmesi.
- **Yeni finans ekranı:**
  - Üstte büyük sayılarla nakit, bekleyen tahsilat ve "hepsi ödenince nakit" kartları.
  - Altında "Bu yıl", "Nakit akışı", kredi ve matbaa kartları.
  - Eksi değerler kırmızımsı, kâr yeşil.
- **Türkçe karakter düzeltmesi:** Düğmelerde "ş" artık düzgün ("Çıkış").
- Diğer ekranlar şimdilik eski görünümde; birlikte değerlendirdikten sonra geçecek.
- Nasıl test ederim:
  1. Oyunu aç: ana menü yeni tasarımda. Kayıt varsa "Devam et" turuncu, yoksa "Yeni oyun".
  2. Bir oyun aç, soldaki para ikonuyla Finans'ı aç: krem pencere, üç büyük sayı kartı, alt kartlar.
  3. Kredi bölümünde tutar ve vade seç: aylık taksit önizlemesi değişmeli. "Kredi çek" çalışmalı, kredi alınca "erken kapat" düğmesi gelmeli.
  4. Başka bir pencereye (Müşteriler gibi) geç: o pencere eski görünümde kalmalı.
  5. `docs/screenshots/09_ui1_main_menu.png` ve `09_ui1_finance.png`.

## C3: Saçlar ve dönemsel kıyafetler (2026-11-05)
- **Kel kalan yok:** 9 saç tipi var: kısa, tıraş, yandan ayrık, küt, uzun, topuz, kıvırcık, mullet (90'lar), erkek topuzu (2010+). Saç rengi çalışana göre değişir.
- **Kıyafetler döneme göre değişiyor:**
  - **90'lar:** vatkalı ceket, takım elbise (kravatlı), süveter yelek.
  - **2000'ler:** kot ceket, polo yaka.
  - **2010'lar:** ekose oduncu gömleği, hırka.
  - **2015 sonrası:** kapüşonlu; 2020'ler bol tişört; 2018 sonrası teknoloji yeleği.
  - **Her dönem:** kolları kıvrık ofis gömleği, elbise.
- Kıyafet rengi çalışana göre değişir; kurucu hardal giyer. Kıyafetler oturunca, yazarken ve yürürken gövdeyle birlikte bükülür.
- 60 çalışanlı ofiste oyun rahat akıyor (338 FPS).
- Nasıl test ederim:
  1. 1990'da yeni oyun başlat ve birkaç kişi işe al: vatkalı ceketler, takım elbiseler, süveter yelekler, mullet saçlar görmelisin.
  2. 2020'de başlayan yeni bir oyun aç: kapüşonlular, bol tişörtler, teknoloji yelekleri, erkek topuzları.
  3. Uzun bir oyunda yıllar ilerledikçe aynı çalışanın kıyafeti dönemine göre değişmeli.
  4. Bütün kıyafetleri tek karede gör:
     `godot --path . res://tools/wardrobe.tscn --resolution 1920x1080 -- --out=C:/Users/osonm/Desktop/gardirop.png`
     (ya da `docs/screenshots/07_c3_wardrobe.png`; oturarak hâli `07_c3_wardrobe_type.png`).
  5. Denetle: `godot --headless --script res://tools/model_check.gd` ("53 model bulundu, 53 sorunsuz").

## C2: Karakter hareketleri (2026-11-05)
- **Çalışanlar artık işlerini gösteriyor:**
  - Kampanya ekibi masada klavyede yazıyor; hesap ve medya ekibinden bazıları telefonla konuşuyor (telefon kulakta).
  - Mutfaktakiler ayakta, elde sarı kupa, ara ara yudum alıyor.
  - Toplantıdakiler elleriyle anlatıp masadakilere dönüyor.
  - Çok yorgun olan masasında uyukluyor; tükenmiş olan ellerini başına koyup sallanıyor.
  - Seviye atlayan kollarını havaya kaldırıp seviniyor; ayaktaysa zıplayarak.
- **Oturuş düzeldi:** Çalışanlar sandalyenin arka kenarında değil, ortasında oturuyor; elleri masaya yetişiyor.
- 60 çalışanlı ofiste oyun rahat akıyor (429 FPS).
- Nasıl test ederim:
  1. Bir kampanya başlat: ekip masasında yazmalı. Hesap/medya çalışanlarından bazıları telefonla konuşmalı.
  2. Bir çalışanın enerjisi düşünce mutfağa gidip kupayla kahve içmeli. Enerjisi çok düşükse masasında uyuklamalı.
  3. Toplantı odası olan bir ofiste toplantıdakiler el kol hareketiyle anlatmalı.
  4. Bir çalışan seviye atlayınca (★ baloncuğu) kollarını kaldırıp sevinmeli.
  5. Bütün hareketleri tek sayfada gör:
     `godot --path . res://tools/pose_sheet.tscn --resolution 640x480 -- --out=C:/Users/osonm/Desktop/pozlar`
     (ya da `docs/screenshots/06_c2_poses.png` ve `06_c2_poses_side.png`).

## C1: İlk karakterler (2026-11-05)
- **Kapsüller gitti:** Çalışanlar artık büyük kafalı, yumuşak hatlı insanlar. Kadın, erkek ve nötr olmak üzere üç gövde var; her biri tişört, kot pantolon ve ayakkabı giyiyor.
- **Her çalışan farklı görünür:** Ten, tişört rengi ve saç rengi çalışana göre değişir; kurucunun tişörtü hardal rengi.
- **Hareketler:** Ofiste yürürken kollar ve bacaklar sallanır. Masada sandalyeye gerçekten oturur, beklerken hafifçe nefes alır.
- **Düzeltme:** Önceden neredeyse bütün çalışanlar aynı renk giyiyordu (M8'den kalma bir hata).
- **Henüz yok (C2 ve C3):**
  - Yazma, telefon, kahve, sunum, sevinme, stres ve uyuklama hareketleri. Şimdilik oturma ya da bekleme oynuyor.
  - Kısa saç dışındaki saçlar ve dönemsel kıyafetler. O saçları seçilen çalışanlar şimdilik kel görünüyor.
- 60 çalışanlı ofiste oyun rahat akıyor (516 FPS).
- Nasıl test ederim:
  1. Oyunu aç ve yeni bir oyun başlat: kurucu hardal tişörtle ofiste.
  2. Birkaç çalışan işe al: her biri farklı ten ve tişört rengiyle gelir, masasına yürür ve sandalyeye oturur.
  3. Yakınlaştır (fare tekerleği) ve yürüyüşe bak: kollar bacakların tersine sallanmalı.
  4. Karakterleri yeniden üret (proje klasöründe):
     `"C:/Program Files (x86)/Steam/steamapps/common/Blender/blender.exe" --background --python tools/blender/build_all.py -- --only=body_female,body_male,body_neutral,hair_short`
  5. Denetle: `godot --headless --import`, sonra `godot --headless --script res://tools/model_check.gd` ("33 model bulundu, 33 sorunsuz").
  6. `docs/screenshots/04_g3b_world_close.png` ile `05_c1_world_close.png`'yi karşılaştır.

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
