# 1 Bu doküman nasıl kullanılır

Bu PDF iki okuyucu için yazıldı: sen (oyunun yaratıcısı, oyun motoru deneyimi olmayan biri) ve Claude Code (kodu yazacak yapay zekâ). Bölüm 2–22 "ne yapacağız" sorusunu (oyun tasarımı), Bölüm 23–29 "nasıl yapacağız" sorusunu (teknik + yol haritası) cevaplar.

## 1.1 Claude Code'a bu dokümanı nasıl vereceksin?

1. Proje klasörünü oluştur (Bölüm 25'teki adımlar). Bu PDF'i `docs/GDD.pdf` olarak klasöre koy.
2. Claude Code'u proje klasöründe başlat ve ilk mesaj olarak şunu yaz:

   > **CLAUDE CODE PROMPT**
   >
   > docs/GDD.pdf dosyasını baştan sona oku. Bu, geliştireceğimiz "Ajans Tycoon" oyununun tasarım dokümanı. Önce dokümanı bölüm bölüm markdown dosyalarına dönüştür: docs/gdd/01-vizyon.md, docs/gdd/07-puanlama.md gibi (her bölüm ayrı dosya). Sonra Bölüm 25'teki CLAUDE.md şablonunu proje köküne oluştur. Ardından Bölüm 26'daki M0 kilometre taşını uygula. Hiçbir kodu dokümanla çelişecek şekilde yazma; çelişki veya belirsizlik görürsen bana sor ve kararı docs/decisions.md dosyasına kaydet.

3. Her kilometre taşında (M0, M1, M2…) Bölüm 26'daki hazır promptu kullan. Bir taş bitmeden sonrakine geçme; her taşın "kabul kriterleri" var.
4. Oyunu her taş sonunda kendin oyna. "Eğlenceli mi?" sorusunu yalnızca sen cevaplayabilirsin. Notlarını `docs/playtest-notes.md`'ye yaz ve Claude'a ver.

## 1.2 Altın kurallar

- **Önce simülasyon, sonra görsel.** Oyunun kalbi matematik. 3D ofis, karakterler, animasyonlar en son gelir. İlk oynanabilir sürüm sadece butonlu menülerden oluşabilir (Game Dev Tycoon'un bile kalbi menülerdir).
- **Her şey veri dosyasında.** Sektörler, kanallar, araçlar, çalışan pozisyonları, olaylar, fiyatlar JSON dosyalarında durur, koda gömülmez. Böylece dengeyi kod bilmeden değiştirebilirsin.
- **Küçük adımlar, sık test.** Claude'dan tek seferde "bütün oyunu yap" isteme. Her prompt tek bir sistem veya ekran.
- **Git ile kaydet.** Her çalışan adımdan sonra commit. Bir şey bozulursa geri dönersin.
- **Gerçek marka adı yok.** Oyundaki markalar, platformlar ve yazılımlar parodi isimler taşır (Game Dev Tycoon'daki "Playsystem", "mBox" gibi). Bölüm 28'de hukuki gerekçe var.
