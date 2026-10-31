# 23 Oyun motoru seçimi: neden Godot?

| Kriter | Godot 4 | Unity 6 | Unreal 5 |
|---|---|---|---|
| Ücret | Tamamen ücretsiz, MIT lisans, gelir payı yok | Ücretsiz katman + gelir eşiğinde ücretli plan | Gelir eşiğinden sonra %5 royalty |
| Claude Code ile çalışma | Çok iyi: sahneler (.tscn), kaynaklar (.tres) ve kodlar (.gd) düz metin; Claude her şeyi okuyup yazabilir. Godot için MCP sunucuları mevcut. | İyi (C#), ama sahneler/prefab'lar karmaşık YAML; editörde çok el işi | Zayıf: Blueprint görsel kodlama ve ağır C++ |
| UI sistemi (tycoon için kritik) | Güçlü Control/Container sistemi, temalar | UI Toolkit/uGUI iyi | UMG, ağır |
| Stilize 3D | Yeterli ve hafif (bu stil için fazlasıyla yeterli) | Çok iyi | Aşırı güçlü / gereksiz ağır |
| Öğrenme ve kurulum | ~100 MB, saniyeler içinde açılır, Python benzeri GDScript | Büyük kurulum, Hub, C# | Çok büyük kurulum, güçlü PC |
| Headless test | Komut satırından `--headless` ile simülasyon testleri kolay | Mümkün, daha zahmetli | Zahmetli |
| Steam | GodotSteam eklentisi ile başarımlar, bulut kayıt | Yerleşik eklentiler | Yerleşik |

> **Karar: Godot 4 (en güncel kararlı 4.x sürümü) + GDScript (statik tipli)**
>
> Oyun motoru bilgin olmadığı ve kodu Claude yazacağı için en önemli kriter "Claude'un projeyi baştan sona metin olarak görebilmesi". Godot burada açık ara önde. Bu oyun türü (menü ağırlıklı simülasyon + stilize 3D sahne) Godot'un en güçlü olduğu alanda. C# yerine GDScript: daha az kurulum, editörle tam entegre, Claude'un hata ayıklaması daha kolay.

**Not:** Proje başlarken Claude'a "Godot'nun şu an en güncel kararlı 4.x sürümünü kullan ve CLAUDE.md'ye sürüm numarasını yaz" de. Sürüm proje boyunca sabitlenmeli; büyük sürüm yükseltmeleri ayrı bir görev olarak yapılmalı.

> M0'da seçilen sürüm: **Godot 4.7.2-stable** (bkz. `CLAUDE.md`, `docs/decisions.md` K-006).
