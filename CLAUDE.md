# TETİKTE — HER OTURUMUN UYACAĞI KURALLAR

> Bu dosyayı her Claude oturumu **otomatik okur**. Cem'in ayrıca söylemesi gerekmez.
> Kurallar 30.08.2026'da yazıldı: o gün iki tel 3 gün ayrı kalmış, 66 commit +
> 878 commit + 245 commit'siz dosya çarpışmıştı. Bu dosya o günün tekrarını önler.

---

## 🔴 AÇILIŞ PROTOKOLÜ — ilk iş, istisnasız

Kod ya da veri dosyasına dokunmadan **ÖNCE** şunu koş:

```powershell
powershell -NoProfile -File motor/oturum.ps1 -Ac -Kol "<iş kolu>"
```

İş kolu adları: `alacak` · `marka` · `destek` · `ihale` · `sinav` · `site` · `pazarlama` · `altyapi`

Betik üç şeyi yapar ve **üçü de geçmeden çalışmaya başlanmaz:**
1. `git fetch` + ana telden ne kadar geride olunduğunu söyler — geride ise **önce birleştirir**
2. Aynı iş kolunda başka bir oturum açık mı bakar (`veri/OTURUM-KILIDI.json`)
3. Bu oturumu kütüğe yazar

**Başka oturum aynı kolda çalışıyorsa:** o kola dokunma. Cem'e söyle, başka kol öner.

---

## 🔴 KAPANIŞ PROTOKOLÜ — iş biter bitmez, "sonra" yok

```powershell
powershell -NoProfile -File motor/oturum.ps1 -Kapat -Kol "<açtığın kol>"
```

> `-Kol` **yaz**. Kilit koldan bırakılır, PID'den değil (`-Ac` ile `-Kapat`
> ayrı süreçlerdir). Kol yazılmazsa: tek kilit varsa bırakılır, birden fazla
> kol açıksa **hiçbiri bırakılmaz** ve sana sorulur.

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
| Rakam uydurmak / hafızadan rakam yazmak | Her rakamın kaynağı gösterilir. Yıl-yıl değişen tutarlara sabit rakam yazılmaz. |
| Uzun commit mesajını `-m` ile vermek | Git mesajın bir kısmını pathspec sanıp **sessizce commit atlıyor** — sonra "PUSH OK" der ama ortada commit yoktur. 30.08'de **dört kez** oldu. Uzun mesaj **her zaman** `git commit -F <dosya>`. ⚙️ Bu artık yazılı kural değil: `arac/commit-mesaj-kapisi.ps1` (PreToolUse hook) çok satırlı `-m`'yi **engelliyor**. Tek satırlık `-m` serbest. |
| Yeni HTML sayfasını `stil-acik.css` bağlamadan eklemek | Sayfa açık temada **beyaz zeminde beyaz yazı** olur. `stil.css`'ten SONRA bağlanır (eşit özgüllükte sonraki kazanır). 29.08'de `durum.html`, 30.08'de `pano.html` bu yüzden kırmızıya düştü. |
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

- "Sınav" = **her zaman üçü**: SGS + yeterlilik + KGK. Üçünü kapsamayan ölçümle iddia kurulmaz.
- Kaynak okunmadan soru yazılmaz. Madde/hesap kodu **ambardan** alınır, hafızadan değil.
- Yaz → geri oku → karşılaştır.
- Pazarlamada "mali müşavir/SMMM" unvanı kullanılmaz. Cem = "Tetikte'nin kurucusu".
  Üründe "hoca" yok → "Nöbetçi".
