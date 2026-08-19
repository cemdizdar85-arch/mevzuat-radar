# ============================================================================
#  ALACAK ARSIV BOL (19.08.2026) — 4 MB'lik tek dosya sayfayi yavaslatiyordu.
#  Arsiv turu havuzu 343 -> 5.728 ilana cikarinca alacak-ilan-canli.json 4 MB
#  oldu ve SAYFA ACILISINDA indiriliyordu (mobilde kabul edilemez).
#  Ayrim:
#    veri/alacak-ilan-canli.json -> SON 400 ilan (sayfa acilisi, ~300 KB)
#    veri/alacak-arsiv.json      -> TAM arsiv (yalniz tarama yapilinca yuklenir)
#  Gunluk hasat canli dosyayi yeniler; bu betik hasattan SONRA kosarak yeni
#  ilanlari arsive de isler ve canliyi 400'e kirpar. Idempotent.
# ============================================================================
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$canliYol = Join-Path $kok 'veri\alacak-ilan-canli.json'
$arsivYol = Join-Path $kok 'veri\alacak-arsiv.json'
$CANLI_ADET = 400

function TarihAnahtar($s){ try { [datetime]::ParseExact("$s",'dd.MM.yyyy',$null) } catch { [datetime]'1900-01-01' } }

$canli = Get-Content $canliYol -Raw -Encoding UTF8 | ConvertFrom-Json
$hepsi = [ordered]@{}
# once mevcut arsiv (varsa), sonra canlidaki kayitlar (yeni/zengin olan kazanir)
if (Test-Path $arsivYol) {
  $eskiArsiv = Get-Content $arsivYol -Raw -Encoding UTF8 | ConvertFrom-Json
  foreach ($e in @($eskiArsiv.ilanlar)) { $hepsi["$($e.ilanNo)"] = $e }
}
foreach ($e in @($canli.ilanlar)) {
  $k = "$($e.ilanNo)"
  if ($hepsi.Contains($k)) {
    # zenginlestirme kaybolmasin: borclu/vkn dolu olan surumu koru
    $eski = $hepsi[$k]
    if (-not $e.borclu -and $eski.borclu) { $e | Add-Member -NotePropertyName borclu -NotePropertyValue $eski.borclu -Force }
    if (-not $e.vkn    -and $eski.vkn)    { $e | Add-Member -NotePropertyName vkn    -NotePropertyValue $eski.vkn -Force }
  }
  $hepsi[$k] = $e
}

$liste = @($hepsi.Values) | Sort-Object -Property @{ Expression = { TarihAnahtar $_.tarih } } -Descending
$sonGuncelleme = if ($canli.guncelleme) { $canli.guncelleme } else { (Get-Date).ToString('dd.MM.yyyy HH:mm') }

# --- TAM ARSIV ---
$arsiv = [ordered]@{
  guncelleme = $sonGuncelleme
  kaynak     = 'Basin Ilan Kurumu Resmi Ilan Portali (ilan.gov.tr) - iflas-hukuku kategorisi'
  adet       = @($liste).Count
  ilanlar    = $liste
}
[System.IO.File]::WriteAllText($arsivYol, ($arsiv | ConvertTo-Json -Depth 6), (New-Object System.Text.UTF8Encoding $false))

# --- SON 30 GUN SAYACI (19.08 Cem: sayfa rozeti soyut korku degil OLCULMUS
#     rakam gostersin). Sayilan sey ILAN adedidir, firma adedi DEGILDIR: ayni
#     dosyada mühlet/sira cetveli/tebligat gibi birden cok ilan cikabiliyor.
#     Rozet metni de bu yuzden "ilan" der. Hesap TAM arsivden yapilir (canli
#     400 kayit 30 gunu kapatmayabilir).
$esik  = (Get-Date).Date.AddDays(-30)
$son30 = @($liste | Where-Object { (TarihAnahtar $_.tarih) -ge $esik })

# --- CANLI (son N) ---
$son = @($liste | Select-Object -First $CANLI_ADET)
$canliYeni = [ordered]@{
  guncelleme      = $sonGuncelleme
  kaynak          = $arsiv.kaynak
  adet            = @($son).Count
  arsivAdet       = @($liste).Count
  arsivDosya      = 'veri/alacak-arsiv.json'
  son30Gun        = 30
  son30           = @($son30).Count
  son30Konkordato = @($son30 | Where-Object { $_.tur -eq 'konkordato' }).Count
  son30Iflas      = @($son30 | Where-Object { $_.tur -eq 'iflas' }).Count
  ilanlar         = $son
}
[System.IO.File]::WriteAllText($canliYol, ($canliYeni | ConvertTo-Json -Depth 6), (New-Object System.Text.UTF8Encoding $false))

# --- YAZ -> GERI OKU ---
$ga = Get-Content $arsivYol -Raw -Encoding UTF8 | ConvertFrom-Json
$gc = Get-Content $canliYol -Raw -Encoding UTF8 | ConvertFrom-Json
$mbA = [Math]::Round((Get-Item $arsivYol).Length/1MB,2)
$kbC = [Math]::Round((Get-Item $canliYol).Length/1KB)
$vknA = @($ga.ilanlar | Where-Object { $_.vkn }).Count
$borcA = @($ga.ilanlar | Where-Object { $_.borclu }).Count
Write-Host ("ARSIV : {0} ilan · {1} MB · borclu {2} · VKN {3}" -f @($ga.ilanlar).Count, $mbA, $borcA, $vknA)
Write-Host ("CANLI : {0} ilan · {1} KB (sayfa acilisi)" -f @($gc.ilanlar).Count, $kbC)
Write-Host ("SON30 : {0} ilan (konkordato {1} / iflas {2}) - sayfa rozeti bunu basar" -f $gc.son30, $gc.son30Konkordato, $gc.son30Iflas)
if (@($ga.ilanlar).Count -lt @($liste).Count) { throw 'KAYIP: arsiv eksik yazildi' }
if ($gc.son30 -ne @($son30).Count) { throw 'KAYIP: son30 sayaci geri okunamadi' }
