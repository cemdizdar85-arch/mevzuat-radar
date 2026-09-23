# TETİKTE — HER OTURUMUN UYACAĞI KURALLAR

> Bu dosyayı her Claude oturumu **otomatik okur**. Cem'in ayrıca söylemesi gerekmez.
> Kurallar 30.08.2026'da yazıldı: o gün iki tel 3 gün ayrı kalmış, 66 commit +
> 878 commit + 245 commit'siz dosya çarpışmıştı. Bu dosya o günün tekrarını önler.

---

## 🔴 AÇILIŞ PROTOKOLÜ — ilk iş, istisnasız

Kod ya da veri dosyasına dokunmadan **ÖNCE** şunu koş:

```powershell
powershell -NoProfile -File motor/oturum.ps1 -Ac -Kol "<iş kolu>" -Is "<kısa iş>" -Ad "<ListAgents'teki adın>"
```

İş kolu adları: `alacak` · `marka` · `destek` · `ihale` · `sinav` · `site` · `pazarlama` · `altyapi`

**Adını öğren, başlığını koy (15.09.2026, Cem "oturum adına iş kolu yazalım"):**
`ListAgents` çıktısının ilk satırı bu oturumun mesaj adını söyler ("This session is mevzuat-i-i-cc") → `-Ad`e o yazılır.
Oturum başlığı `set_session_title` ile **`<kol> · <iş>`** yapılır (ör. `sinav · bitirme basımı`).
Neden: 15.09'da "bitirme oturumuna not" iki yanlış oturuma gitti — oturum adları yalnız numaraydı, kilit kaydında iş yazmıyordu.
Başka bir oturuma not düşeceksen önce `motor/oturum.ps1 -Durum` bak: kol · iş · **mesaj adı** orada.

Betik üç şeyi yapar ve **üçü de geçmeden çalışmaya başlanmaz:**
1. `git fetch` + ana telden ne kadar geride olunduğunu söyler — geride ise **önce birleştirir**
2. Aynı iş kolunda başka bir **canlı oturum** açık mı bakar (`veri/OTURUM-KILIDI.json`; kimlik = `CLAUDE_CODE_SESSION_ID` + `CLAUDE_PID`)
3. Bu oturumu kütüğe yazar

**Başka oturum aynı kolda çalışıyorsa:** o kola dokunma. Cem'e söyle, başka kol öner — ya da kilitteki mesaj adına yaz.

**Bir iş = bir oturum (15.09.2026, Cem "bir işi tek oturuma verelim").** Aynı iş iki pencereye yazılmış olabilir
(15.09'da `motor/oturum.ps1` kilit onarımı iki oturuma birden verildi; iki çözüm aynı dosyada üst üste bindi, biri durup
diğeri çekildi). Kilidi olmayan bir dosyaya — `motor/`, `arac/`, `CLAUDE.md` gibi kol dışı ortak dosyalar dahil — büyük
bir değişiklik yapmadan ÖNCE: `ListAgents` + `-Durum` ile başka oturumun aynı işi tutup tutmadığına bak; tutuyorsa ona
yaz ve **ilk başlayan devam eder**, sonra gelen çekilir ve kendi değişikliğini geri alır. Düzenleme sırasında "dosya diskte
değişti" uyarısı gelirse DUR: başka oturum aynı dosyadadır, önce mesajlaş.

---

## 🔴 KAPANIŞ PROTOKOLÜ — iş biter bitmez, "sonra" yok

```powershell
powershell -NoProfile -File motor/oturum.ps1 -Kapat -Kol "<açtığın kol>"
```

> Kilit **KOL + OTURUM** ile bırakılır (15.09.2026): `-Kapat` yalnız **bu oturumun** açtığı kilidi
> bırakır; `-Kol` yazılmazsa bu oturumun bütün kollarını bırakır. Başka bir oturumun kilidine
> dokunmaz, uyarır — gerçekten terk edilmişse Cem onayıyla `-Zorla`. (15.09 20:29'da eski mantık
> site oturumunun kapanışında sınav oturumunun canlı kilidini silmişti; ayrıca kilit, kapanan
> powershell'in PID'ini tuttuğu için hiçbir oturumu fiilen durdurmuyordu.)
> Kilit mantığının öz-sınavı: `powershell -NoProfile -File motor/oturum.ps1 -KilitSinavi`
> Kilitsiz düzenleme uyarısı (15.09): kilidi olmayan oturum depo dosyasına Edit/Write yapınca `arac/kilit-uyari-kapisi.ps1` hook'u **uyarır, durdurmaz** (10 dk'da bir). Uyarı gelirse önce `-Ac` ile kol al. Öz-sınav: `arac/kilit-uyari-kapisi.ps1 -Sinav`

> Bu makinede `pwsh` (PowerShell 7) **yok**, `powershell` (5.1) var. Betikleri
> `powershell -NoProfile -File` ile çağır. Ayrıca 5.1 BOM'suz UTF-8'i ANSI sanar:
> **Türkçe içeren her `.ps1` BOM'lu UTF-8 kaydedilir**, yoksa "başka" → "baÅŸka" olur
> ve betik ayrıştırılamaz (30.08'de yaşandı).

Bu betik commit edilmemiş iş kalmışsa **UYARIR**. Uyarı varsa oturum bitmemiştir.

**Altın kural: düzenleme → commit → `git push origin HEAD:main` AYNI çağrıda.**
Arada başka iş yapma. Robotlar ana tele dakikalar içinde yazıyor; beklersen çarpışırsın.

Push reddedilirse (robot araya girdiyse):
```powershell
git fetch origin main; git merge origin/main --no-edit; git push origin HEAD:main
```

---

## ⛔ ASLA YAPILMAYACAKLAR

| Yasak | Neden |
|---|---|
| Dal açıp orada uzun süre çalışmak | Robotlar **push edilen her dala** yazar → her dal yeni çakışma fabrikası (30.08 kanıtı: `210d9319`) |
| `veri/*.json` dosyalarını elle düzenlemek | Bunlar robot çıktısıdır. Elle yazarsan bir sonraki koşu ezer. Üreten betiği düzelt. |
| Çakışmayı ölçmeden çözmek | 30.08'de 3 dosyada YEREL doğruydu (Türkçe harf bozulması + 30'luk parti + tam arşiv ölçümü). Körlemesine "uzağı al" o işleri silerdi. |
| `git stash -u` | Takipsiz dosyaları **siler**. `--autostash` kullan. |
| `_kaynak/` ve büyük PDF'leri commit'lemek | Depo 1 GB'a şişer; 80 MB'a indirildi, orada kalacak. |
| Ölçmediğine "var/yok" demek | VAR/YOK iddiası yalnız `veri/AMBAR-ENVANTERI.md`'den. Ölçülmemiş hücre = "ölçülmedi". |
| **Kapı ekleyip veriyi tazelememek** | ⭐ **Cem kuralı (10.09.2026, değişmez standart).** Bir yutucuya/üreticiye sınır, kapı ya da ayrıştırma kuralı eklendiyse, o kuralın etkilediği **veri de aynı commit'te tazelenir**. Aynı commit'te olmuyorsa mesaja **`TAZELEME BEKLİYOR: <ne, nerede, neden>`** satırı düşülür ve iş emrine yazılır. Sessizce bırakılmaz. **Bedeli ölçüldü:** `kgk-standart-yut.ps1`'e 02.08'de boy kapısı eklendi, veri tazelenmedi; ambar bir ay kapısız dönemin verisiyle çalıştı, en büyüğü **146.979 karakterlik tek satır** olan dev parçalar aramada mıknatıs gibi çalıştı (278 konunun 110'u tek o satıra düştü), altın test 45→43'e indi ve 10.09'da üç yanlış teşhisle bir gün kaybedildi. **"Kod düzeldi" ≠ "arıza kapandı"** — bunu ancak veriyi ölçen bir test söyler (`motor/ambar-testi.ps1`). |
| Rakam uydurmak / hafızadan rakam yazmak | Her rakamın kaynağı gösterilir. Yıl-yıl değişen tutarlara sabit rakam yazılmaz. |
| Uzun commit mesajını `-m` ile vermek | Git mesajın bir kısmını pathspec sanıp **sessizce commit atlıyor** — sonra "PUSH OK" der ama ortada commit yoktur. 30.08'de **dört kez** oldu. Uzun mesaj **her zaman** `git commit -F <dosya>`. ⚙️ Bu artık yazılı kural değil: `arac/commit-mesaj-kapisi.ps1` (PreToolUse hook) çok satırlı `-m`'yi **engelliyor**. Tek satırlık `-m` serbest. |
| Yeni HTML sayfasını `stil-acik.css` bağlamadan eklemek | Sayfa açık temada **beyaz zeminde beyaz yazı** olur. `stil.css`'ten SONRA bağlanır (eşit özgüllükte sonraki kazanır). 29.08'de `durum.html`, 30.08'de `pano.html` bu yüzden kırmızıya düştü. |
| Rapor JSON'unu doğrudan `Set-Content` ile yazmak | Çıktıda `olcum` zaman damgası olduğu için dosya, **sonuç hiç değişmese bile** her koşuda "değişmiş" görünür → kapanış denetimi takılır, robotlar boş commit üretir, iki koşu gereksiz çakışır. Bunun yerine: `. (Join-Path $depoKok 'arac\rapor-yaz.ps1')` + `RaporYaz -Hedef $hedef -Nesne $cikti` — **helper `arac/` altındadır, `motor/` değil** (01.09'da bir oturum `$PSScriptRoot`'ta arayıp düştü). Zaman alanları hariç kıyaslar; aynıysa dosyaya **hiç dokunmaz**. Betiğin ayrıca kendi "yazildi" mesajını basması yasak — dokunulmadığı hâlde "yazdım" der (30.08'de beş betikte vardı). |
| **Bilinen tuzağı tekrar yazmak** | ⛔ **Mekanik kapı: `arac/tuzak-nobetcisi.ps1`** (11.09.2026). Kod **çalıştırılmadan** okunur, beş bilinen tuzağı yakalar: **K1** değişken çakışması (`$DERS` ↔ `$ders`) · **K2** `@(...\|ConvertFrom-Json)` dizi sarma · **K3** `@($list)` List patlaması · **K4** sıralamasız `limit=1` var/yok testi · **K5** BOM'suz Türkçe `.ps1`. Niye var: 11.09'da en çok zamanı *aynı* hataları tekrarlamak yedi — K1 **altı kez**, K2 üç kez. Hepsi `arac/olcum-kapilari.ps1`'de **yazılıydı**; yorum kimseyi durdurmadı. `motor/oturum.ps1 -Kapat` bu kapıyı **değişen `.ps1` dosyalarında** koşar; 🔴 ZARARLI bulgu varsa oturum kapanmaz (`-Birak "gerekçe"` ile bilerek geçilir). Depodaki **210 eski bulgu ayrı iş emri** — hepsini kapatmak kapıyı ilk gün kapatırdı. **Kurt masalı okumaz:** her kural öz-sınavlı (6 kural + K5'in 3 vakası + K1'in ağırlık ayrımı); yanlış alarm ölçülerek ayıklandı (K5 104→44, K2 80→76). Bilerek bozuk test verisi `# nobetci:gec` / `# nobetci:bolge-basla`…`-bitir` ile susturulur, **gerekçesi yazılarak**. |
| **Kapı kurup "bir daha düşmez" demek** | ⭐ **Cem kuralı (21.09.2026):** *"şu an sen kapı bir daha düşmeyecek şekilde yapıyorum deme."* Bkz. aşağıdaki **KAPI KURMA KURALLARI** — iddia yalnız ölçülmüş vaka kadardır. |
| Sabit renk yazmak (`#abc`, `rgba(...)`) | `arac/renk-sabiti-denetcisi.ps1` kapısı düşer. Tema jetonu kullanılır; saydamlık için `color-mix(in srgb,var(--jeton) X%,transparent)`. **`var(--dim,#5d6b7c)` gibi YEDEK DEĞER de sabittir.** Renk gerçekten sabit kalmalıysa tabanı tazele ve **nedenini commit'e yaz**. |

---

## 🚪 KAPI KURMA KURALLARI — "bir daha düşmez" DENMEZ

> ⭐ **Cem kuralı (21.09.2026):** *"bunu kural haline getirelim; şu an sen kapı bir
> daha düşmeyecek şekilde yapıyorum deme."*

**Neden (o gün ölçüldü):** `kaynak.yml` sabah koşusu 4 gün üst üste düştü ve
**üç ayrı kapı** bunu kaçırdı. Üçü de "ölçüyorum" diyordu:

| Kapı | Ne sanıyordu | Gerçekte |
|---|---|---|
| `yapisal-denetci.ps1` | ikincil kaynak yakalıyor | ihale firmasının **adını** kaynak sandı (KPMG/PwC), 4 gün yayını durdurdu |
| `ci-kirmizi-nobetcisi.ps1` | üst üste kırmızıyı görüyor | desen `F S F S F S` olunca seri hep **1**'de kaldı, 5 gün kör; ayrıca 159 workflow'un yalnız **100**'üne bakıyordu |
| `veri-tazelik.ps1` | tazeliği ölçüyor | 55 dosyanın **29'u** "TANIMSIZ" diye hiç denetlenmiyordu |

### Kurallar

1. **İddia, ölçülmüş vaka kadardır.** "Bir daha düşmez", "artık yakalanır",
   "bu sorun kapandı" **yazılmaz**. Yazılacak olan: *"şu 10 vakada şunu yakaladı,
   şunu kaçırdı (tarih)."* Ölçülmemişse **"ölçülmedi"** denir.
2. **Her kapının öz-sınavı olur ve `dogrula.yml` matrisinde koşar.**
   Öz-sınavı olmayan kapı "ölçüyor" sayılmaz — çünkü kendi bozulduğunda
   sessizce yalan söyler. Sınav hem **yakalaması gerekeni** hem
   **yanlış alarm vermemesi gerekeni** içerir.
3. **Kapının kendisi de kör olabilir; körlüğü yazılı olur.** Her kapının
   başına *"bu kapı şunu GÖRMEZ"* satırı düşülür. Görmediği bilinen desen,
   bilinmeyen desenden iyidir.
4. **Rapor, bakmadığını da söyler.** `aktif_workflow: 100` değil,
   `workflow_toplam: 159 / alinan: 100 / KÖR: 59`. Eksik kapsama **"temiz"**
   diye raporlanamaz — kapsam düştüyse çıktı **KÖR**'dür.
5. **Kapı bir LİSTEYLE çalışıyorsa (yasaklı kelime, ikincil kaynak adı),
   o liste meşru veriyle çakışabilir.** Liste eklerken öz-sınava şu vaka
   yazılır: *"bu kelime meşru veri olarak geçebilir mi?"* — 21.09'da KPMG'ydi,
   yarın bir marka adı ya da firma unvanı olur.
6. **Bir iş kırmızıysa önce HANGİ ADIMIN düştüğüne bakılır, hata metnine değil.**
   21.09'da log'daki en gürültülü hata (EKAP SSL) suçlu değildi —
   `continue-on-error` ile yutuluyordu. Suçlu, sessizce atlanan
   **"Değişiklik varsa yayınla"** adımıydı.
7. **Kapı düşünce ne kadar iş durduğu ölçülür.** "Tek ihlalde tüm yayını
   durdur" ile "yalnız bozuk dosyayı geri al" aynı şey değildir; 21.09'da
   birinci desen **1 yanlış alarm yüzünden 30+ dosyanın hasadını** çöpe attı.

## 📏 ÇAKIŞMA ÇÖZME REÇETESİ (30.08'de kanıtlandı)

Ham bayt farkı **yanıltır**. `konu-kaynak-karnesi.json` 476 KB küçük görünüyordu,
içerikte uzak sürüm 239 karakter **daha büyüktü** — fark sadece JSON girintisiydi.

Sıra:
1. **Normalize et, sonra kıyasla:** JSON'u `ConvertFrom-Json | ConvertTo-Json -Compress`, metni `-replace "\r\n","\n"`
2. **Kayıt say:** belge/madde/satır sayısı — sayı aynıysa kayıp yoktur
3. **Alan alan ölç:** hangi alanda kaç karakter değişmiş
4. Ancak bundan sonra karar ver

Küçülme her zaman kayıp değildir: akış tazelenmesi (eski duyuru düşer),
çözülmüş kusur (kırık link sayısı azalır), biçim değişikliği — üçü de normaldir.

---

## 🗂️ NEREYE YAZILIR

| Ne | Nereye | Not |
|---|---|---|
| Robot çıktısı | `veri/` | Elle dokunulmaz |
| Robot betiği | `motor/` | 330 betik var; 172'si Actions'tan çağrılıyor |
| Zamanlanmış iş | `.github/workflows/` | 128 akış, 20'si cron'lu |
| SQL göçü | `radar-app/sql/` + **`UYGULANDI.md`'ye satır** | "Hangi SQL basılı?" sorusunun TEK cevabı |
| Ham kaynak (PDF) | `_kaynak/` | Git'e **girmez** |

**Yeni bir araç eklerken beş yere birden konur:** `index.html` · `menu.js` ·
karşılama ekranı · `sitemap.xml` · ilgili radar sayfası. Biri unutulursa araç görünmez.

---

## 🔎 GitHub CLI (`gh`) — Actions günlüğünü okumak için

30.08'de kuruldu (`winget install GitHub.cli`, sürüm 2.98). **Yol:**
`C:\Program Files\GitHub CLI\gh.exe` — yeni açılan kabukta `gh` olarak da
çalışır, eski oturumda tam yol gerekir.

✅ **Giriş YAPILI** (15.09.2026 ölçüldü: `gh auth status` → hesap `cemdizdar85-arch`, anahtar zinciri,
kapsam `repo`). Eski not "yapılmadı" diyordu ve bir gün boyunca Cem'e elle "Run workflow" tıklatılmak
istendi — önce `gh auth status` bak. Giriş düşerse Cem şunu koşar (tarayıcı açar, kimlik bilgisi Claude'a girilmez): `gh auth login`.

**Elle akış tetikleme (Cem onayıyla):** `gh workflow run <akis>.yml -f girdi=deger` → `gh run watch <id> --exit-status`.

**Neden gerekli:** Actions günlüğünü okumak depo yöneticisi yetkisi ister.
30.08'de `ihale-ozet-tazele.yml` üç kez düştü ve sebep görülemediği için üç
tur tahminle harcandı. `gh` ile tek komut yeterdi:

```bash
gh run list --workflow=<akis>.yml --limit 5
gh run view <id> --log-failed
```

Giriş yapıldıktan sonra bu iki komut, "kapı neden düştü" sorusunun en kısa
cevabıdır — tahmin etmeden önce ona bak.

## 🌐 KAYNAK İNDİRME — nerede koşar

30.08 ölçümü (`veri/ip-olcum-raporu.md`): 10 kaynaktan **8'i GitHub runner'dan iniyor**.
Yalnız `mevzuat.gov.tr` inmiyor (kod `000`).

- **Yeni indirme işi yazarken varsayılan: GitHub Actions.** Cem'in makinesi değil.
- Sadece `mevzuat.gov.tr` TR-IP ister.
- "Şu site buluttan inmiyor" demeden **önce ölç** — `ip-olcum.yml`'ye hedef ekle.
- HTTP 200 yetmez: içerik tipi + gerçek imza (`%PDF`/JSON/HTML) birlikte bakılır.
  Ölü adres 200+HTML döner, bilinmeyen API yolu 200+SPA kabuğu verir.

---

## 📤 HER TESLİMDE İKİ BLOK — yoksa iş teslim edilmemiştir

```
## SORMADIĞIN AMA GÖRDÜĞÜM
(çalışırken fark ettiklerim — hiçbir şey yoksa "yok" yaz)

## GM ÖNERİLERİ
(3 somut hamle, gerekçeli)
```

Ayrıca: önce kendi fikrimi söylerim → Cem karar verir → uygularım.
Cem yanlış bir şey isterse "böyle olmaz" derim; ısrar ederse kararına uyarım.

---

## 🧾 SINAV / SORU İŞİ

- ⛔⭐⭐ **PARA HARCAYAN SORU BASIMI KURALI — KİM BASARSA BASSIN, HER SINAVDA** (17.09.2026, Cem: *"boşuna 400 USD harcadık …
  kim soru basacaksa bunları yapsın, kural olsun"*). **Olay (ölçüldü):** 16.09 gecesi bitirme için 3.983 soruluk plan ölçülmeden, tek
  seferde açıldı; 400 USD kredi bir gecede bitti, kasaya 387 soru girdi (yayına giren soru başı ≈1 USD, hedef 0,068). Bedel defteri
  harcamanın ¼'ünü yazıyordu, kredi bitince zincir "tamamlandı" dedi, ~1.800 soru yarım kaldı. Kurallar:
  1. **Önce küçük ölçüm, sonra büyüt.** Yeni plan ya da yeni sınav önce **tek ders, ≤25 USD** ile koşar. Gerçek bedel **YAYINA GİREN
     soru başına** çıkarılır (üretilen soru başına değil) + yayın oranı + kapı sayımı (`KAPI SAYIM` günlük satırı). Cem bu rakamı
     görüp onay vermeden büyük basım yok. **"Tamamını başlat" talimatı ölçüm adımını atlatmaz** — önce risk ve bedel yeniden söylenir.
  2. **Bütçesiz basım yok (mekanik):** `bulut-uretim.yml` `butce_usd` olmadan başlamaz; plan harcaması bütçeye ulaşınca yeni parti
     açılmaz, iş KIRMIZI biter. Bütçe >25 USD ise `olcum_kosusu` (bitmiş ölçüm koşusunun run id'si) zorunlu. Kesin fren Anthropic
     Console aylık harcama tavanıdır (Cem koyar); kredi yalnız o işin bütçesi kadar yüklenir, otomatik yükleme kapalı.
  3. **Koşu sürerken harcama ölçülür, hız değil.** Saat başı gerçek harcama (Console Cost ya da toplu sonuçların `usage` örneklemi)
     ile bütçe kıyaslanır; "para kaybı yok" gibi ölçülmemiş cümle kurulmaz. Defter/fren tutarsız görünürse (ör. "bu ay ≈25.000 USD")
     **ücretli iş durdurulur**, önce düzeltilir.
  4. **Kapı ret oranı yüksekse basım büyütülmez.** `KAPI SAYIM`da yeniden yazım (d1-*) taslakların üçte birini geçiyorsa önce en çok
     döndüren kapının kökü çözülür (bitirmede: doğru şık uzunluğu, yuvarlak tutar, yakın adlı konu tekrarı — 17.09 ölçümü).
  5. **Plan temiz kurulur:** aynı konunun farklı yazımları birleştirilir (bitirme: `veri/sinav/smmm-konu-es.json`), bir konuya tur
     sayısı tavanlanır; ilgi hakeminden geçmemiş konu basılmaz.
  6. **Yarım iş önce biter:** kredi/bütçe yüzünden yarım kalan plan yeniden basılmaz; aynı plan aynı etiketle devam ettirilir (ödenmiş
     toplu sonuçlar bedava hasat edilir).
  Mekanik parçalar: `motor/kalip-kosucu.ps1` (bütçe kapısı, bakiye/hata izi, kapı sayımı toplamı) · `motor/kalip-parti-uret.ps1`
  (bedel defteri 75/çöküşte de yazılır, `KAPI SAYIM`) · `.github/workflows/bulut-uretim.yml` (bütçe + ölçüm kapısı, zincir kırmızı durur).

- ⛔⭐ **TOPLU SORU BASIMI YALNIZ BULUTTA** (16.09.2026, Cem: *"herşeyi buluta taşıdık hızlı olması için, ne oldu yine benim bilgisayara döndü"*).
  Plan depoya yazılır (plan + `veri/sinav/konu/*.json`, göreli yol), sonra: `gh workflow run bulut-uretim.yml -f plan=<plan> -f paralel=<n> -f butce_usd=<USD> [-f olcum_kosusu=<run id>]` (17.09: bütçe zorunlu, yukarıdaki kural).
  Bulut işi 320 dk'da kendini yeniden tetikler; gönderilen toplu partilerin kaydı ambarda (`arac/bekleyen-senkron.ps1`) → çift ödeme yok,
  anlık yola düşme yok. `motor/kalip-kosucu.ps1` yerelde **durur** (`MEVZUAT_YEREL_BASIM='<gerekçe>'` ile bilerek açılır — yalnız
  hazır-soru dosyası gibi bu makineye bağlı işler için). Neden: 16.09'da yerel koşular 65 süreç, 281 MB boş RAM, paralellik 1 üretti.
  Yerelde kalan tek iş: planı kurmak, küçük onarım (`kalip-parti-uret.ps1 -PilotId`), ölçüm.
- ⛔⭐ **TÜM SORULAR, TÜM SINAVLARDA, NE OLURSA OLSUN TOPLU** (16.09.2026, Cem: *"dönen sorular toplu basılacak kural olsun, sadece bu sınav
  değil bütün sınavlarda … tüm sorular ne olursa olsun toplu basılacak"*). Kapıdan dönen sorunun yeniden yazımı dahil (FAZ A ikinci toplu
  parti `AR`/`A1B`). Mekanik kapı: `motor/kalip-parti-uret.ps1` `-Toplu` olmadan ücretli çağrı yapmaz ("TOPLU ZORUNLU"); `motor/kalip-kosucu.ps1`
  plan `toplu:false`, `MEVZUAT_TOPLU=0` ve kuyruk sağlığı düşürmesini yok sayar. Tek kaçış Cem'in yazılı onayı: `MEVZUAT_ANLIK_CEM_ONAYI='<tarih+gerekçe>'`.
  Neden: 15.09'dan beri "toplu" SGS koşularında harcamanın %54'ü (8,88/16,46 USD) anlık gitmişti. Hâlâ anlık kalan dar yollar (bozuk toplu cevabın
  tek tekrarı, SMMM kaynaklı ikinci çözüm, ikinci bakış, 32k kesik tekrarı) iş emridir.
- ⛔⭐ **BULUTTA KOŞAN PARTİYE AMBARDAN YAZILMAZ** (16.09.2026, Cem "1.2.3 yap"). Bulut işi partiyi başta indirir, sonda
  tamamını yükler; arada ambara yazan her iş (kaynak bağı taşıma, `arac/paket-tazele.ps1`, elle düzeltme) ya ezilir ya
  bulutun sonucunu siler. Ambardaki bir **kaynağı yeniden bölen/yutan** iş de (standart-yut, TFRS/TMS resmî metin) bağlı
  partileri bayatlatır. Kural: parti yazan araç önce `arac/bulut-kosan-etiketler.ps1 -Kati` çağırır, çıkan etiketleri
  atlar (plan adı okunamayan eski iş varsa bekler). Kaynak yeniden bölme işi, etki raporundaki partiler bulutta koşuyorsa
  o partilerin taşımasını bulut bitene kadar sıraya koyar. 16.09 kanıtı: TFRS 18 taşımasında 17 SGS partisinin 13'ü koşuyordu.
- ⛔⭐ **BULUT GÜVENLİĞİ — "bulut güvenli, kimse sızamaz" DENMEZ** (16.09.2026, Cem: *"güvenlik kısmını kural olarak yaz"*).
  Ölçülmüş gerçek (16.09): depo **PUBLIC**; Actions iş günlükleri herkese açık. 13.09 bulut koşusunun günlüğünde soru metni **yok**,
  sırlar `***` ile maskeli. Ama depoda plan/konu dosyaları, `veri/mevzuat/teori-notlari-*.json` ve (14.09 ölçümü) 7.043 SGS sorusu taşıyan
  dosyalar **herkese açık** durur. Kurallar:
  1. **Sır yalnız GitHub Secrets / kullanıcı ortam değişkeninde.** Koda, plana, günlüğe, commit mesajına anahtar yazılmaz; sır `echo`/`Write-Host` edilmez.
  2. **Bulut işinin ekran çıktısına (stdout) soru metni, şık, cevap, açıklama, kaynak paketi basılmaz.** Yalnız sayı, etiket, bedel. Yeni bir
     bulut adımı eklerken bu kural günlükte ölçülür (`gh run view <id> --log` taranır).
  3. **Bulut işi artifact yüklemez** (`motor/artifact-nobeti.ps1` `.enc` dışını kırmızı sayar). Parti içeriği yalnız ambara (Supabase,
     servis anahtarı, RLS açık + politika yok) yazılır.
  4. **Müşteri verisi (alacak, fiş, evrak, kişi verisi) buluta/Actions'a/açık depoya GİRMEZ** — kurumsal güvenli servis kuralı her şeyin üstünde.
  5. **Depoya yeni soru içeriği commit'lenmez**; soru ve cevap ambarda durur. Depoda duran açık içerik ayrı iş emri (paket kasası, `ADIM2-PAKET-KASASI-PLANI.md`).
  6. Güvenlik iddiası **ölçümle** yazılır: "sızmaz" değil, "şu günlükte/şu dosyada şu yok (tarih)" denir. Ölçülmemişse "ölçülmedi".

- ⛔⭐⭐ **SORU BASIM PLANI KAPSAMA TABLOSUNDAN KURULUR — ELDEN PLAN YOK** (22.09.2026, Cem: *"exceli yap ve ona göre soru çıkaralım · ben böyle biliyordum, bunu kural olarak yazalım"*).
  **Olay (ölçüldü 22.09):** bitirme planları aylarca elde kuruldu; kapsam **genişliğe** gitti, **sıklığa** gitmedi. Çıkmış sınavlarda
  **43 kez** görülen "amortisman ayırma"da 7, **31 kez** görülen "bilanço düzenleme"de ve **25 kez** görülen "şüpheli alacak
  karşılığı"nda **SIFIR** sorumuz vardı. Sebep: SGS'nin ve KGK'nın kapsama tablosu vardı, **bitirmeninki yoktu**.
  **Kural — bu sıra atlanmaz:**
  0. **HEDEF = 4.000 SORU** (Cem kararı, 23.09.2026: *"4.000 olsun"*). Hedef konu başına "kat" değil, **bankanın toplamı**;
     çıkmış sıklığına göre konulara dağıtılır (`-ToplamHedef 4000`, varsayılan). Hedef değişirse tek komutla yeniden üretilir.
     23.09 ölçümü: elde **2.442**, hedef dağıtımı **4.439**, **açık ≈3.300** — açık 2.000 değil, çünkü eldeki soruların
     **1.388'i hedefin üstündeki konularda** duruyor (sayı var, doğru yerde değil).
  0b. ⛔⭐ **SON 10 YIL KURALI** (Cem, 23.09.2026: *"10 yıldır sorulmayan bir soruya bizde soru basmamalıyız · son 10 yıl kural
     oluşturalım, ona göre soru ve kanun baksın"*). Konunun ağırlığı **tüm zamanların çıkma sayısı DEĞİL, son 10 yılda kaç kez
     sorulduğu**dur (`son10` sütunu, kaynak `veri/smmm-analiz.json` — 419 dönem×ders kaydı, 2008–2026). Son 10 yılda hiç
     sorulmayan konunun hedefi **0**'dır; plan kurucu ona soru yazmaz. Adı analizde eşleşmeyen konunun yeniliği **ölçülemez**
     (`OLCULMEDI`) ve ona da hedef verilmez — yeni olduğunu kanıtlayamadığımız konuya para verilmez.
     **Ölçüldü (23.09):** eski dağıtım 1.121 soruluk hedefi **10+ yıldır sorulmayan** 1.013 konuya veriyordu; bu konulara
     bugüne kadar **223 soru** basılmıştı. "Şüpheli alacak karşılığı" tüm zamanlarda 25 kez çıkmış ama **son 10 yılda 1 kez**
     (son 2020/2) — eski kuralla bu gece 3 soru basılacaktı. "Amortisman ayırma" ise son 10 yılda **29 kez** (son 2025/3).
     **Kanun tarafı:** konunun dayandığı madde değiştiyse, o konunun eski çıkma sıklığı yeni sınavı öngörmeyebilir ve eski
     soruların cevabı yanlış olabilir → soru **eski metinden basılmaz**, önce yeni metin ambara yutulur. Madde değişikliğini
     `motor/soru-dayanak-nobetcisi.ps1` işaretler (`veri/sinav/mevzuat-degisti-yeni-hat.json`) ve yayın şartı o soruyu çeker.
     ⚠ **Nöbetçinin alarmı toplu çekimden ÖNCE doğrulanır** (27.08 robot kıyımı dersi: *"kaynak değişti ≠ değer değişti"*):
     22.09'da "VUK m.370 SİLİNDİ" kaydı 689 soruyu (SMMM'de ~340) yayından çekti; 23.09 ölçümünde VUK'un madde parmak izi
     dosyasında 08:00 ile 19:22 arasında **hiçbir madde silinmemiş/değişmemişti** ve m.370 **iki dosyada da yoktu** — yani
     gerçek bir kanun değişikliği mi, yutma eksiği mi **ölçülmedi**. Doğrulanmadan geri de açılmaz, olduğu gibi de bırakılmaz.
  1. **Tablo tazelenir:** `arac/smmm-kapsama-tablosu.ps1` → `veri/fabrika/smmm-kapsama.csv`
     (ders · konu · **sınavda kaç kez çıktı** · yazdık · yayınlanabilir · hedef · açık · **engel**). Bedel 0.
     ⛔ **Bayat tabloyla plan kurulmaz (mekanik):** `smmm-plan-kur.ps1` tablo 12 saatten eskiyse **durur**.
     Neden: 23.09'da ölçüldü — hedefin üstüne yazılmış **1.388 soru**nun sahibi 325 konunun **323'ü birden çok
     partiden** geldi ("dikey yüzde analizi" 23 ayrı partiden 49 soru, hedefi 13). **303'ünün payı tek bir dalgada:
     `smmm-4k`** (16–17.09'un 400 USD'lik gecesi), çünkü o plan `r1..r10` turlarıyla aynı konu listesini yeniden bastı.
     Üreticinin konu tekilleştirmesi parti **içinde** çalışır, partiler **arasında** çalışmaz — tek koruma taze tablodur.
  2. **Excel'e dökülür:** `arac/smmm-basim-excel.ps1` → Masaüstü `SMMM-Bitirme-Konu-Basim-Plani.xlsx`
     (+ `veri/fabrika/SMMM-KAPSAMA-excel.csv`). Cem bu dosyadan bakar. **Elle düzenlenmez**, her koşuda yeniden yazılır.
  3. **Plan o tablodan kurulur:** `arac/smmm-plan-kur.ps1` — seçim **SIKLIK ÖNCE** (çıkmış ≥ eşik · açık > 0 · **ENGEL yok**).
     Elde konu listesi yazılmaz. Ders adı etiketten **kanonik** ada çevrilir (`arac/smmm-ders-adi.ps1`); çözülemeyen etiketle plan **kurulmaz**.
  4. **ENGELLİ konuya para verilmez.** `KISIR` / `KAYNAK-BORCU` işaretli konu plana alınmaz — bunlar **para ile değil kaynak yutma ile**
     çözülür, iş emri `veri/KAYNAK-BORCU.md`. Kaynağı gelince `arac/kisir-konu-olc.ps1 -BorcOdendi '<konu>' -BorcNotu '<kaynak>'`.
  5. **Aynı konu yasak değildir.** En çok çıkan konularda açık zaten vardır (amortisman ayırma 122 açık); amaç o konuya **ikinci soruyu**
     yazmaktır. Kopyayı ikiz kapısı engeller (`arac/ikiz-olcusu.ps1`, 22.09'dan beri **üretimde de** koşar). ⚠ 22.09'da "önceki dalgada
     geçen konuyu alma" denilince havuz 239'dan **39** konuya düşmüştü — bu eleme YANLIŞTIR.
  6. **Zorluk karışımı:** banka sınavdan **zor** olacak (Cem 21.09) — kolay %25 · zor %50 · çok zor %25.
  7. ⛔⭐ **HER DALGA DÖNGÜ BETİĞİYLE AÇILIR — "yanlış konu basmıyoruz" DENMEZ, GÖSTERİLİR** (Cem 23.09: *"excel güncellenecek
     ve yanlış konu basmayacağız deme · bunu da kural olarak yap"*). Yeni dalga yalnız
     `arac/smmm-dalga-dongu.ps1 -Etiket wN -Rezerve '<koşan dalgalar>'` ile kurulur. Betik sırayla: partileri indirir →
     kapsama tablosunu tazeler → **Excel'i yeniden yazar** → planı rezervli kurar → **KONU DENETİMİ** yapar: yeni dalganın
     **her konusu** tablodan tek tek kontrol edilir (son 10 yılda sorulmuş mu · açığı var mı · engelli mi · ders adı kanonik mi ·
     konu dosyası yerinde mi · koşan dalgalar + bu dalga açığı aşıyor mu). **Tek ihlal varsa plan dosyaları silinir, dalga AÇILMAZ.**
     Betiğin son satırı `DENETİM: …` Cem'e **aynen** gösterilir — "yanlış konu yok" cümlesi yerine o satır yazılır.
     Koşan/eski bir dalga `-SadeceDenetim` ile denetlenir (dosyaya dokunmaz).
     **Ölçüldü (23.09, gerçek dalgalarla):** w9 YEŞİL (65 konu, 180/180 son 10 yıl) · eski kuralla kurulmuş w6 KIRMIZI (10+ yıl
     eski, engelli, hedefi dolu konuları yakaladı) · koşan w8'de 1 ihlal (taşıt satışı: planlı 2 > açık 1 — w7'nin biten yarısı
     açığı kapattı; koşan dalga durdurulmadı, bedeli 1 fazla soru).
     🚫 GÖRMEZ: konu adı yazım farkları · paralel dalgaların birbirinin yeni sorusu (ikizi yayın kapısı yakalar).
     Öz-sınav: `arac/smmm-dalga-dongu-sinavi.ps1` (`dogrula.yml`'de, 23.09) — gerçek betik `-DenetimKok` ile geçici
     klasörde koşar; 14 vaka (9 ihlal türü + 4 yanlış alarm + silme). Mutasyonla ölçüldü: 10+ yıl kontrolü, açık aşımı
     kontrolü ya da silme kapatılınca sınav KIRMIZI düşüyor. Plan kurucunun SEÇİMİNİ ölçmez (o ayrı betik).
     **Plan satır tavanı 8** (`smmm-plan-kur.ps1 -SatirTavan`, 23.09): bulut işi aynı anda 8 satır koşturur; 9–15 satırlı
     plan iki sıra koşuyordu. Dalga yine aynı toplam soruyu basar, yalnız daha çok plana bölünür.
  **Tablonun körlükleri yazılıdır:** konu adı yazım farklarını tek konuya indirmez · "çıkmış" köprüden gelir, köprü yanlışsa hedef de
  yanlıştır · ikiz süzgecinin yayında eleyeceğini görmez. Bu üçü **"ölçülmedi"** sayılır, "yok" sayılmaz.

- ⭐ **Sınavla ilgili "var mı / kaç / eksik ne" sorusunun TEK cevabı `veri/SINAV-TEK-SAYFA.md`** (02.09.2026, Cem: "tek yerden, hızlı, güvenilir, kaybolmadan"). 7 bölüm = Cem'in 7 sorusu: dersler · çıkmış sorular · yeterli miyiz · ambar · kaynak sağlığı · yutulmayan mevzuat · basılacaklar. Üretici `motor/sinav-tek-sayfa.ps1`, robot `sinav-tek-sayfa.yml` (her sabah 08:30 TR). Elle düzenlenmez; **⚠ işaretli satır = girdisi bayat/kırık, o sayı "ölçülmedi"dir** — önce bölüm 5'teki girdi tazelenir. Hafızadan sınav rakamı YAZILMAZ, bu sayfadan okunur.
- ⛔⭐ **RET KÜTÜĞÜ — üretim/hasat turu bitince, istisnasız** (11.09.2026, Cem: *"retleri topla ama bir daha karşılaşmayacak şekilde kurumsal olarak kâğıda dök"*). Tur biter bitmez `powershell -NoProfile -File arac/ret-kutugu.ps1` koşar (bedel 0) → `veri/RET-KUTUGU.md`. **Ret nedenleri okunmadan yeni tur başlatılmaz.** Bir kök neden sınıfı ilk üçe giriyorsa önce ona kapı kurulur — kapısız tekrar üretim aynı parayı ikinci kez yakar. **İlk ölçüm (11.09): 1.288 retin %56,6'sı soruyla değil KAYNAK PAKETİYLE ilgiliydi** (paket cevabı destekleyen hükmü taşımıyor ya da ortadan kesik). Şartname: `SORU-BASMA-KURALLARI.md` bölüm G.
- "Sınav" = **her zaman üçü**: SGS + yeterlilik + KGK. Üçünü kapsamayan ölçümle iddia kurulmaz.
- Kaynak okunmadan soru yazılmaz. Madde/hesap kodu **ambardan** alınır, hafızadan değil.
- Yaz → geri oku → karşılaştır.
- Pazarlamada "mali müşavir/SMMM" unvanı kullanılmaz. Cem = "Tetikte'nin kurucusu".
  Üründe "hoca" yok → "Nöbetçi".
