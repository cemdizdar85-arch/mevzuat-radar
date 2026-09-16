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
| Sabit renk yazmak (`#abc`, `rgba(...)`) | `arac/renk-sabiti-denetcisi.ps1` kapısı düşer. Tema jetonu kullanılır; saydamlık için `color-mix(in srgb,var(--jeton) X%,transparent)`. **`var(--dim,#5d6b7c)` gibi YEDEK DEĞER de sabittir.** Renk gerçekten sabit kalmalıysa tabanı tazele ve **nedenini commit'e yaz**. |

---

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

- ⛔⭐ **TOPLU SORU BASIMI YALNIZ BULUTTA** (16.09.2026, Cem: *"herşeyi buluta taşıdık hızlı olması için, ne oldu yine benim bilgisayara döndü"*).
  Plan depoya yazılır (plan + `veri/sinav/konu/*.json`, göreli yol), sonra: `gh workflow run bulut-uretim.yml -f plan=<plan> -f paralel=<n>`.
  Bulut işi 320 dk'da kendini yeniden tetikler; gönderilen toplu partilerin kaydı ambarda (`arac/bekleyen-senkron.ps1`) → çift ödeme yok,
  anlık yola düşme yok. `motor/kalip-kosucu.ps1` yerelde **durur** (`MEVZUAT_YEREL_BASIM='<gerekçe>'` ile bilerek açılır — yalnız
  hazır-soru dosyası gibi bu makineye bağlı işler için). Neden: 16.09'da yerel koşular 65 süreç, 281 MB boş RAM, paralellik 1 üretti.
  Yerelde kalan tek iş: planı kurmak, küçük onarım (`kalip-parti-uret.ps1 -PilotId`), ölçüm.
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

- ⭐ **Sınavla ilgili "var mı / kaç / eksik ne" sorusunun TEK cevabı `veri/SINAV-TEK-SAYFA.md`** (02.09.2026, Cem: "tek yerden, hızlı, güvenilir, kaybolmadan"). 7 bölüm = Cem'in 7 sorusu: dersler · çıkmış sorular · yeterli miyiz · ambar · kaynak sağlığı · yutulmayan mevzuat · basılacaklar. Üretici `motor/sinav-tek-sayfa.ps1`, robot `sinav-tek-sayfa.yml` (her sabah 08:30 TR). Elle düzenlenmez; **⚠ işaretli satır = girdisi bayat/kırık, o sayı "ölçülmedi"dir** — önce bölüm 5'teki girdi tazelenir. Hafızadan sınav rakamı YAZILMAZ, bu sayfadan okunur.
- ⛔⭐ **RET KÜTÜĞÜ — üretim/hasat turu bitince, istisnasız** (11.09.2026, Cem: *"retleri topla ama bir daha karşılaşmayacak şekilde kurumsal olarak kâğıda dök"*). Tur biter bitmez `powershell -NoProfile -File arac/ret-kutugu.ps1` koşar (bedel 0) → `veri/RET-KUTUGU.md`. **Ret nedenleri okunmadan yeni tur başlatılmaz.** Bir kök neden sınıfı ilk üçe giriyorsa önce ona kapı kurulur — kapısız tekrar üretim aynı parayı ikinci kez yakar. **İlk ölçüm (11.09): 1.288 retin %56,6'sı soruyla değil KAYNAK PAKETİYLE ilgiliydi** (paket cevabı destekleyen hükmü taşımıyor ya da ortadan kesik). Şartname: `SORU-BASMA-KURALLARI.md` bölüm G.
- "Sınav" = **her zaman üçü**: SGS + yeterlilik + KGK. Üçünü kapsamayan ölçümle iddia kurulmaz.
- Kaynak okunmadan soru yazılmaz. Madde/hesap kodu **ambardan** alınır, hafızadan değil.
- Yaz → geri oku → karşılaştır.
- Pazarlamada "mali müşavir/SMMM" unvanı kullanılmaz. Cem = "Tetikte'nin kurucusu".
  Üründe "hoca" yok → "Nöbetçi".
