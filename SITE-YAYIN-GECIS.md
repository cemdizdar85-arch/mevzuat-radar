# SİTE YAYINI: "Deploy from branch" → "GitHub Actions" (beyaz liste) — geçiş ve geri dönüş

> Bu dosya depo kökündedir ve **kendisi yayına çıkmaz** (kökteki `.md` beyaz listede yok).
> Araçlar: `arac/site-yayin.js` (kurucu + denetim + öz-sınav) · `arac/site-beyaz-liste.txt` (liste) ·
> `.github/workflows/site-yayin.yml` (yayın akışı) · `arac/site-esdegerlik.js` (tarayıcılı tarama + Pages benzeri sunucu + kıyas).

## Neden

08.10.2026 ölçümü: tetikte.com deponun KÖKÜNDEN yayınlanıyor; `/CLAUDE.md`, `/DEVIR-NOTU.md`, `/motor/*.ps1`,
`/radar-app/sql/UYGULANDI.md`, `/radar-app/edge/*.ts`, `/veri/*.md`, `motor/cikti/` altında 354 HTML herkese 200 dönüyor.
`robots.txt` bunları yalnız arama motorundan saklar, erişimi kapatmaz.

## Yeni düzen

- Yayına **yalnız** `arac/site-beyaz-liste.txt`'e uyan izlenen dosyalar çıkar (08.10: 563 dosya / 9.295, 31 MB).
- İki kilit: liste + listeden bağımsız **YASAK** denetimi (md/ps1/sql/ts/yml, `motor/`, `arac/`, `radar-app/` … listeye
  yazılsa bile yayın durur).
- Akış, Pages kaynağı "GitHub Actions" olmadıkça **siteye dokunmaz** (yalnız kurar + denetler). Yani akış depoya
  girdiği anda bir şey değişmez; değişim Pages ayarı çevrilince başlar.
- Tetik: elle push · ana tele iten 150 robot akışının bitişi (`workflow_run`; robotlar `GITHUB_TOKEN` ile itiyor, bu
  itme `push` tetiğini çalıştırmıyor) · her saat :07 ve :37 yedek koşu · elle `gh workflow run site-yayin.yml -f zorla=true`.
- Değişiklik site dosyasına dokunmuyorsa (karşılaştırma API'si) dağıtım atlanır.

## Eşdeğerlik provası (08.10.2026, geçişten ÖNCE, yerel Pages benzeri sunucuda)

- Canlı tarama (`arac/site-esdegerlik.js --tara`): 387 tohum (kök + kaydir + sayfalar + arsiv + tasarim/bulten… HTML'leri +
  harita) → derinlik 3, telefon + masaüstü → **641 sayfa**, aynı kökenden 749 istek yolu (JS fetch dahil) + bağlantılar;
  ayrıca depoda anılan 88 mutlak `tetikte.com/...` adresi (e-posta, robot, uygulama).
- Kıyas: canlıda 200 dönen **490 site yolunun 490'ı** yeni yayında 200 · **KAYIP 0**.
- Bilerek düşen **12** yol: `tasarim/` taslakları (8), `bulten/sablon.html`, `kaynak-ozetleri/etebligat-…html` ve yalnız
  taslakların çektiği `veri/sinav-tek-sayfa.json`, `veri/rg-gozetim-haritasi.json` — hiçbir site sayfası bunlara bağlanmıyor
  (taramaya yalnız doğrudan tohum olarak verildiler).
- İç dosya: depoda izlenen ama yayına girmeyen **8.530 dosyanın 8.530'u** yeni yayında 404 (canlıda bugün 52'lik örneğin
  52'si 200: CLAUDE.md, DEVIR-NOTU.md, motor/*.ps1, motor/cikti/*.html, radar-app/sql + edge, veri/*.md, arac/, veri/sinav/).
- `dogrula.yml`: öz-sınav 15/15 · mutasyon 6/6 KIRMIZI (yasak/zorunlu/bag/haric/glob/tetik) · gerçek depo denetimi YEŞİL.
- 🚫 Ölçülmedi: GitHub'ın gerçek Actions dağıtımı (geçişten sonra aynı kıyas canlıya karşı koşulacak).

## Yeni bir sayfa / veri dosyası eklerken

Sayfa yeni bir `veri/…json` çekiyorsa `arac/site-beyaz-liste.txt`'e satır eklenir. Eklenmezse:
`dogrula.yml` "Site beyaz liste DENETIMI" KIRMIZI (KOPUK) düşer; yayın akışı **durmaz**, uyarır (o dosya sitede 404 olur).
Yeni bir robot akışı ana tele itiyorsa: `node arac/site-yayin.js --tetik-yaz` (yoksa dogrula TETIK ile düşer).

## GEÇİŞ (Cem onayıyla) — iki yoldan biri

**Yol A — Claude yapar (Cem "geç" der):**
```
gh api -X PUT repos/cemdizdar85-arch/mevzuat-radar/pages -f build_type=workflow
gh workflow run site-yayin.yml -f zorla=true
```

**Yol B — Cem panelden:**
1. github.com/cemdizdar85-arch/mevzuat-radar → **Settings** → soldan **Pages**
2. "Build and deployment" → **Source**: "Deploy from a branch" yerine **"GitHub Actions"** seç (kaydet düğmesi yok, seçince kaydolur)
3. Aynı sayfada **Custom domain** kutusunda `tetikte.com` yazdığını ve "Enforce HTTPS" işaretli olduğunu gör
4. **Actions** sekmesi → "Site Yayini (beyaz liste)" → **Run workflow** → `zorla` işaretle → Run

**Geçişten hemen sonra (Claude ölçer, ~5 dk):**
1. Akış yeşil + "GitHub Pages'e dagit" adımı koştu
2. `node arac/site-esdegerlik.js --kiyas --canli <08.10 canlı tarama> --yeni https://tetikte.com --ic <iç liste> --ek <mutlak adresler>`
   → site yolları 200, iç dosyalar 404
3. Telefon + bilgisayar ekran görüntüsü (ana sayfa, fiyat, kaydır, satın al)
4. `canli-tarama.yml` elle tetiklenir (yeşil olmalı)

## GERİ DÖNÜŞ (bir şey bozulursa, ~2 dk)

```
gh api -X PUT repos/cemdizdar85-arch/mevzuat-radar/pages -f build_type=legacy -f "source[branch]=main" -f "source[path]=/"
gh api -X POST repos/cemdizdar85-arch/mevzuat-radar/pages/builds
```
Panelden: Settings → Pages → Source: **"Deploy from a branch"** → Branch **main**, klasör **/ (root)** → Save.
Eski düzen aynen geri gelir (depoda hiçbir dosya silinmedi; yayın akışı Pages kaynağı "workflow" değilken dağıtmaz).
Custom domain alanı boşalmışsa `tetikte.com` yeniden yazılır.

## Bilinen sınırlar (🚫 GÖRMEZ)

- Dizgeyle kurulan yollar (`'veri/canli/' + kod + '.json'`) statik denetimde görünmez; listede kalıpla tutulur,
  ölçümü tarayıcı taramasıdır.
- Gecikme: robot itmesinden siteye ≈ robotun bitişi + 1–3 dk (eski düzende itmeden 1–2 dk). Robot ittikten sonra
  uzun süre koşmaya devam ediyorsa fark büyür; yedek koşu en geç 30 dk.
- `canli-tarama.yml` hâlâ "Yayin" bitişinden 240 sn sonra bakıyor; yayın artık ayrı akışta olduğundan bu bekleme
  ölçülmeli (öneri: "Site Yayini (beyaz liste)" bitişine bağlamak).
- Eski düzenin `github-pages` artifact'leri (deponun TAMAMI, ~81 MB, 1 gün saklama) geçişten sonra 24 saat içinde kendiliğinden düşer.
