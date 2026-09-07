# KAYDIR-ÇÖZ YAYIN YOLU (07/08.09.2026, A kovası 10 — "ürüne bağlantı yok": v29 sayfaları sql-yerel'de tek dosya duruyordu, siteden erişilemiyordu)
# Seçim dosyasındaki (hakem ∧ sim ∧ kör çözüm ∧ hakem2 geçmiş) soruları DERS DERS Kaydır-Çöz sayfasına basar ve bir dizin sayfası kurar:
#   kaydir/<sinav>/<ders-slug>.html  (kaydir-coz.ps1 ile, her ders ayrı sayfa)
#   kaydir/<sinav>/index.html        (ders kartları, soru sayıları; stil.css + stil-acik.css; noindex)
# Sayfalar depo klasörüne yazılır ama COMMIT EDİLMEZ; siteye çıkması (menü/index/sitemap "beş yer" + üye kapısı) Cem'in kararıdır.
# Kullanım: powershell -NoProfile -File motor/kaydir-yayin.ps1 -Sinav sgs -SecimDosya parti30-secim.json
param([string]$Sinav='sgs',[string]$SecimDosya='parti30-secim.json',[string]$Baslik='Staja Başlama (SGS) · Kaydır-Çöz')
$ErrorActionPreference='Stop'
$kok=Split-Path $PSScriptRoot -Parent
$secYol=Join-Path $kok "veri\sinav\kaydir-secim\$SecimDosya"; if(-not (Test-Path $secYol)){ throw "seçim dosyası yok: $secYol" }
$sec=@(ConvertFrom-Json -InputObject (Get-Content $secYol -Raw -Encoding UTF8)); if($sec.Count -eq 1 -and $sec[0].PSObject.Properties['SyncRoot']){ $sec=@($sec[0].SyncRoot) }
function Slug([string]$s){ $t=("$s" -creplace 'İ','i' -creplace 'I','i' -creplace 'ı','i' -creplace 'Ğ','g' -creplace 'ğ','g' -creplace 'Ü','u' -creplace 'ü','u' -creplace 'Ş','s' -creplace 'ş','s' -creplace 'Ö','o' -creplace 'ö','o' -creplace 'Ç','c' -creplace 'ç','c').ToLowerInvariant(); ($t -replace '[^a-z0-9]+','-').Trim('-') }
$hedefDir=Join-Path $kok "kaydir\$Sinav"; New-Item -ItemType Directory -Force $hedefDir | Out-Null
$gruplar=@($sec | Group-Object ders | Sort-Object Name)
$kartlar=@(); $toplam=0
foreach($g in $gruplar){
  $ders="$($g.Name)"; $slug=Slug $ders; $altSec="yayin-$Sinav-$slug.json"
  [IO.File]::WriteAllText((Join-Path $kok "veri\sinav\kaydir-secim\$altSec"),(ConvertTo-Json -InputObject @($g.Group) -Depth 3),[Text.UTF8Encoding]::new($false))
  $cikti="..\kaydir\$Sinav\$slug.html"
  $out=& powershell -NoProfile -File (Join-Path $PSScriptRoot 'kaydir-coz.ps1') -SecimDosya $altSec -Cikti $cikti 2>&1 | Select-String -Pattern 'yazildi|ÖZ-SINAV|Exception|Cannot' | ForEach-Object { $_.Line }
  $out | ForEach-Object { "  $ders : $_" }
  $n=@($g.Group).Count; $toplam+=$n
  $kartlar+=[pscustomobject]@{ ders=$ders; slug=$slug; n=$n; konular=(@($g.Group | ForEach-Object { "$($_.konu)" } | Select-Object -Unique) -join ' · ') }
}
function E([string]$s){ [System.Net.WebUtility]::HtmlEncode("$s") }
$kartH=($kartlar | ForEach-Object { "<a class=`"kart`" href=`"$($_.slug).html`"><div class=`"ad`">$(E $_.ders)</div><div class=`"sayi`">$($_.n) soru</div><div class=`"konu`">$(E $_.konular)</div></a>" }) -join "`n"
$html=@"
<!doctype html><html lang="tr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="robots" content="noindex,nofollow">
<title>$(E $Baslik) · Tetikte</title>
<link rel="stylesheet" href="../../stil.css"><link rel="stylesheet" href="../../stil-acik.css">
<style>
.kaydirDizin{max-width:960px;margin:0 auto;padding:24px 16px}
.kaydirDizin h1{font-size:1.5em;margin:0 0 6px}.kaydirDizin .alt{color:var(--dim);margin:0 0 18px}
.kaydirDizin .izgara{display:grid;grid-template-columns:repeat(auto-fill,minmax(260px,1fr));gap:12px}
.kaydirDizin .kart{display:block;border:1px solid var(--cizgi);border-radius:14px;padding:14px 16px;text-decoration:none;color:inherit;background:var(--kart)}
.kaydirDizin .kart:hover{border-color:var(--altin)}
.kaydirDizin .ad{font-weight:700;margin-bottom:4px}.kaydirDizin .sayi{color:var(--altin);font-weight:700;margin-bottom:6px}.kaydirDizin .konu{color:var(--dim);font-size:.85em;line-height:1.4}
.kaydirDizin .not{margin-top:22px;color:var(--dim);font-size:.9em;border-top:1px solid var(--cizgi);padding-top:12px}
</style></head><body>
<main class="kaydirDizin">
<h1>$(E $Baslik)</h1>
<p class="alt">$toplam soru · $($kartlar.Count) ders · her soru: sınav gibi çöz → yanlışını gör → Nöbetçi adım adım anlatsın → ikizini sen çöz. Bu sorular hakem, öğrenci simülasyonu, bağımsız kör çözüm ve ikinci hakemden geçti.</p>
<div class="izgara">
$kartH
</div>
<p class="not">Basım: $(Get-Date -Format 'dd.MM.yyyy HH:mm') · seçim dosyası $(E $SecimDosya) · kalıp v29. Bu dizin taslaktır; menüye ve site haritasına bağlanması ile üye kapısı Cem'in kararıdır.</p>
</main></body></html>
"@
[IO.File]::WriteAllText((Join-Path $hedefDir 'index.html'),$html,[Text.UTF8Encoding]::new($false))
"yazildi: $hedefDir\index.html · $toplam soru · $($kartlar.Count) ders sayfası"
