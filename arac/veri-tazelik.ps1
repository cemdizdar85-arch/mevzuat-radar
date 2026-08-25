# ============================================================================
#  VERI TAZELIK NOBETCISI  (25.08.2026)
#
#  Veri kapisi (arac/veri-kapisi.ps1) "gelen veri saglam mi" diye sorar.
#  Bu betik BASKA bir soruyu sorar: "TAZE VERI GELMEYI BIRAKTI MI?"
#  Ikisi ayri arizadir. Kapi sessizce gecerken kaynak aylardir olmus olabilir.
#
#  ⚠️ OLCU SECIMI - BUGUN OGRENILEN DERS:
#  Eski bekci (arac/veri-bekcisi.ps1) bayatligi DOSYANIN ICINDEKI ilk tarih
#  benzeri metinden okuyordu. Bu YANLIS ALARM uretiyor:
#     nice-siniflar.json "30.12.2016" diye isaretlendi ve "10 yillik bayat veri"
#     sanildi. Oysa o tarih KAYNAK TEBLIGIN RG tarihidir (TPE 2016/2); dosyanin
#     kendisi 21.08.2026'da guncellenmis ve icinde neden 2016 ekinin kullanildigini
#     anlatan bir SERH bile var. Ayni sebeple "22 dosya bayat" rakami sismisti;
#     git yasiyla olculunce gercek sayi 12.
#  DOGRU OLCU: TAZE VERININ EN SON NE ZAMAN GELDIGI = dosyanin son git commit'i.
#  Verinin ICERIGINDEKI tarihler kaynak atfi olabilir, guncellik gostergesi degil.
#
#  UC DURUM (iki degil):
#    TAZE     - sozlesmedeki azami_yas_saat icinde
#    BAYAT    - asti  -> gercek ariza, gorunur olmali
#    TANIMSIZ - sozlesmede azami_yas_saat NULL (guncelleme ritmi belirlenmemis)
#               -> YANLIS ALARM URETME; tuketilebilir bir IS LISTESI olarak listele
#
#  KULLANIM: pwsh arac/veri-tazelik.ps1
#  CIKIS: 0 hepsi taze · 1 BAYAT var · 3 yalniz TANIMSIZ var (kor nokta)
# ============================================================================
$ErrorActionPreference = 'Stop'
$kok = Split-Path -Parent $PSScriptRoot
Set-Location $kok

$sozYol = Join-Path $kok 'veri/_sozlesme.json'
if (-not (Test-Path $sozYol)) { Write-Host "veri/_sozlesme.json yok."; exit 0 }
$soz = Get-Content $sozYol -Raw -Encoding UTF8 | ConvertFrom-Json

$taze = New-Object System.Collections.ArrayList
$bayat = New-Object System.Collections.ArrayList
$tanimsiz = New-Object System.Collections.ArrayList
$bilincli = New-Object System.Collections.ArrayList
$yok = New-Object System.Collections.ArrayList

foreach ($p in $soz.dosyalar.PSObject.Properties) {
  $f = $p.Name
  if (-not (Test-Path $f)) { [void]$yok.Add($f); continue }

  # TAZE VERININ GELDIGI AN = son git commit'i. Dosya icindeki tarihler DEGIL.
  $ts = $null
  try { $ts = (git log -1 --format=%ct -- $f 2>$null | Select-Object -First 1) } catch {}
  if (-not $ts) { [void]$tanimsiz.Add([ordered]@{ dosya=$f; sebep='git gecmisi yok (henuz commit edilmemis)' }); continue }
  $yasSaat = [Math]::Round(((Get-Date) - ([DateTimeOffset]::FromUnixTimeSeconds([int]$ts)).LocalDateTime).TotalHours, 1)

  $azami = $p.Value.azami_yas_saat
  # "elle" = BILINCLI ELLE BESLENEN dosya (veri/otomasyon-borcu.json'da gerekcesi
  # yazili). Bunlar icin yas siniri ANLAMSIZDIR - urun metni, tohum dosya ya da
  # sinav gunune bagli paket olabilir. Kor nokta DEGIL, bilincli karar; ayri
  # sayilir ki gercek kor noktalar kalabaligin icinde kaybolmasin.
  if ("$azami" -eq 'elle') {
    [void]$bilincli.Add([ordered]@{ dosya=$f; yas_gun=[Math]::Round($yasSaat/24,1); dayanak=[string]$p.Value.ritim_dayanagi })
    continue
  }
  if ($null -eq $azami) {
    [void]$tanimsiz.Add([ordered]@{ dosya=$f; yas_saat=$yasSaat; yas_gun=[Math]::Round($yasSaat/24,1); sebep='sozlesmede azami_yas_saat tanimli degil' })
    continue
  }
  if ($yasSaat -gt [double]$azami) {
    [void]$bayat.Add([ordered]@{ dosya=$f; yas_saat=$yasSaat; yas_gun=[Math]::Round($yasSaat/24,1); azami_saat=[double]$azami; not=[string]$p.Value.not })
  } else {
    [void]$taze.Add($f)
  }
}

Write-Host "=== VERI TAZELIK NOBETCISI ==="
Write-Host ("olcu: son git commit'i (dosya icindeki tarihler DEGIL - bkz. nice-siniflar dersi)")
Write-Host ("TAZE {0} · BAYAT {1} · BILINCLI-ELLE {2} · TANIMSIZ {3} · DOSYA YOK {4}" -f $taze.Count, $bayat.Count, $bilincli.Count, $tanimsiz.Count, $yok.Count)

if ($bayat.Count -gt 0) {
  Write-Host ""
  Write-Host "--- BAYAT (taze veri gelmeyi birakmis) ---"
  foreach ($b in ($bayat | Sort-Object { -$_.yas_gun })) {
    Write-Host ("  {0,-36} {1,6} gun  (azami {2} saat)" -f $b.dosya, $b.yas_gun, $b.azami_saat)
  }
}
if ($tanimsiz.Count -gt 0) {
  Write-Host ""
  Write-Host "--- TANIMSIZ (guncelleme ritmi belirlenmemis - KOR NOKTA, is listesi) ---"
  foreach ($t in ($tanimsiz | Sort-Object { -$_.yas_gun } | Select-Object -First 15)) {
    Write-Host ("  {0,-36} {1,6} gun" -f $t.dosya, $t.yas_gun)
  }
  if ($tanimsiz.Count -gt 15) { Write-Host ("  ... ve {0} dosya daha" -f ($tanimsiz.Count - 15)) }
}
if ($yok.Count -gt 0) {
  Write-Host ""
  Write-Host "--- SOZLESMEDE VAR AMA DOSYA YOK ---"
  foreach ($y in $yok) { Write-Host ("  {0}" -f $y) }
}

$rapor = [ordered]@{
  tarih = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  olcu  = "son git commit zamani"
  taze = $taze.Count; bayat = $bayat.Count; bilincli_elle = $bilincli.Count; tanimsiz = $tanimsiz.Count; dosya_yok = $yok.Count
  bilincli_elleler = @($bilincli)
  bayatlar = @($bayat)
  tanimsizlar = @($tanimsiz)
  yoklar = @($yok)
}
[IO.File]::WriteAllText((Join-Path $kok 'veri/veri-tazelik-raporu.json'), ($rapor | ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding($false)))
Write-Host ""
Write-Host "-> veri/veri-tazelik-raporu.json"

if ($bayat.Count -gt 0) { exit 1 }
if ($tanimsiz.Count -gt 0) { exit 3 }
exit 0
