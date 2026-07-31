# ============================================================================
#  VERI BEKCISI - "her baktigimiz yerde veri gelmiyor" sikayetine kalici sigorta
#  (Cem 31.07). Tum HTML'lerin fetch ettigi veri/*.json dosyalarini bulur ve:
#    1) dosya repo'da VAR MI
#    2) JSON PARSE oluyor mu
#    3) ana govde BOS MU (en buyuk dizi 0 elemansa veri yok demektir)
#    4) icinde tarih damgasi varsa 21 gunden BAYAT MI (uyari)
#  Ayrica veri/ klasorunde hicbir sayfanin cekmedigi yetim dosyalari listeler.
#  CI'da her push'ta kosar (nokta-kontrol ailesi). Cikis 1 = kirmizi var.
# ============================================================================
$ErrorActionPreference = "Stop"
$kok = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $kok

$kirmizi = @(); $sari = @()
$kullanilan = @{}

# damga/isaret dosyalari: tek alanli olmalari NORMAL (bos govde sayilmaz)
$DAMGA_DOSYALARI = @('veri/kart-durum.json')

# --- 1) HTML -> fetch('veri/...') haritasi ---
# Iki desen: (a) dogrudan "veri/x.json", (b) dinamik fetch('veri/'+f) icin
# HTML'de gecen herhangi bir 'x.json' adi veri/ klasorunde varsa o da sayilir.
$htmller = Get-ChildItem -Path $kok -Filter *.html -File
$desen = "veri/[A-Za-z0-9_\-\.]+\.json"
$desenSerbest = "['""]([A-Za-z0-9_\-]+\.json)['""]"
foreach($h in $htmller){
  $icerik = Get-Content $h.FullName -Raw -Encoding UTF8
  $refler = @([regex]::Matches($icerik, $desen) | ForEach-Object { $_.Value })
  foreach($m in [regex]::Matches($icerik, $desenSerbest)){
    $aday = "veri/$($m.Groups[1].Value)"
    if(Test-Path (Join-Path $kok $aday)){ $refler += $aday }   # Join-Path / ayracini isletim sistemine gore cozer (CI=Linux!)
  }
  $refler = $refler | Sort-Object -Unique
  foreach($ref in $refler){
    $kullanilan[$ref] = $true
    $yol = Join-Path $kok $ref
    if(-not (Test-Path $yol)){
      $kirmizi += "$($h.Name) -> $ref : DOSYA YOK"
      continue
    }
    try {
      $j = Get-Content $yol -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
      $kirmizi += "$($h.Name) -> $ref : JSON PARSE HATASI ($($_.Exception.Message))"
      continue
    }
    # en buyuk koleksiyon (dizi VEYA obje-harita anahtarlari) bos mu?
    $enBuyuk = 0
    foreach($p in $j.PSObject.Properties){
      if($p.Value -is [array]){ if($p.Value.Count -gt $enBuyuk){ $enBuyuk = $p.Value.Count } }
      elseif($p.Value -is [PSCustomObject]){ $n = @($p.Value.PSObject.Properties).Count; if($n -gt $enBuyuk){ $enBuyuk = $n } }
    }
    $ozellikSay = @($j.PSObject.Properties).Count
    if($enBuyuk -eq 0 -and $ozellikSay -le 2 -and $DAMGA_DOSYALARI -notcontains $ref){
      $kirmizi += "$($h.Name) -> $ref : GOVDE BOS (koleksiyon yok, $ozellikSay ozellik)"
    }
    # tarih damgasi bayatligi (dd.MM.yyyy ilk gecen)
    $ham = Get-Content $yol -Raw -Encoding UTF8
    $m = [regex]::Match($ham, '([0-3][0-9])\.([0-1][0-9])\.(20[0-9][0-9])')
    if($m.Success){
      try {
        $t = [datetime]::ParseExact($m.Value, "dd.MM.yyyy", $null)
        if($t -lt (Get-Date).AddDays(-21)){ $sari += "$ref : damga $($m.Value) (21+ gun bayat) [$($h.Name)]" }
      } catch {}
    }
  }
}

# --- 2) yetim veri dosyalari (hicbir HTML cekmiyor; motor/CI kullaniyor olabilir - SARI) ---
$tumVeri = Get-ChildItem -Path (Join-Path $kok 'veri') -Filter *.json -File
foreach($v in $tumVeri){
  $ref = "veri/$($v.Name)"
  if(-not $kullanilan.ContainsKey($ref)){ $sari += "$ref : hicbir sayfa cekmiyor (motor ici olabilir)" }
}

# --- rapor ---
Write-Host ("HTML: {0} - cekilen benzersiz veri dosyasi: {1}" -f $htmller.Count, $kullanilan.Count)
if($kirmizi.Count){ Write-Host "`n=== KIRMIZI ($($kirmizi.Count)) ==="; $kirmizi | ForEach-Object { Write-Host "  X $_" } }
if($sari.Count){ Write-Host "`n=== SARI ($($sari.Count)) ==="; $sari | ForEach-Object { Write-Host "  ~ $_" } }
if(-not $kirmizi.Count){ Write-Host "`nKIRMIZI YOK - tum cekilen veri dosyalari mevcut + parse + dolu." }
if($kirmizi.Count){ exit 1 }
