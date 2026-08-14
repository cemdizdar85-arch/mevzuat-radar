# ============================================================================
#  EM-DASH SADELESTIRME - kullanici metnindeki cümle-içi tire (14.08.2026)
#  Cem: "toplu sadeleştirme turu yap." Kullanici metnindeki cumle-ici " — "
#  noktalama isaretine cevrilir; BASLIK (<title>) ve KOD (yorum/regex/ikon) korunur.
#  -Yaz verilmedikce dosya YAZMAZ, yalnizca kac degisiklik olacagini raporlar.
# ============================================================================
param([switch]$Yaz, [string]$Dosya = "")
$ErrorActionPreference = "Continue"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here

# GUVENLI DONUSUM: yalniz "bosluk EM-DASH bosluk" (cumle-ici dusunce ayraci).
# Bitisik em-dash (aralik: 2020—2021), kod suslemesi (———), ikon korunur.
# Karar: em-dash oncesi virgul YOKSA virgul; varsa yalniz tireyi kaldir.
# Boylece "X — Y" -> "X, Y" ; "X, — Y" -> "X, Y".
function Sadelestir([string]$satir){
  if($satir -notmatch ' — '){ return $satir }
  # ikon/susleme satiri (———, — — —) dokunma
  if($satir -match '—\s*—'){ return $satir }
  $r = $satir -replace '([,;:])\s*—\s+', '$1 '     # zaten noktalama varsa tireyi at
  $r = $r -replace '\s+—\s+', ', '                  # cumle-ici tire -> virgul
  return $r
}

$dosyalar = if($Dosya){ @(Join-Path $kok $Dosya | Get-Item) } else { Get-ChildItem $kok -Filter *.html }
$toplamDeg = 0; $rapor = New-Object Collections.ArrayList
foreach($f in $dosyalar){
  $ham = [IO.File]::ReadAllText($f.FullName, [Text.UTF8Encoding]::new($false))
  $sonuc = New-Object Text.StringBuilder
  $dosyaDeg = 0
  $icYorum = $false   # /* ... */ blok yorumu takibi
  foreach($satir in ($ham -split "(?<=`n)")){
    $s = $satir
    $korunacak = $false
    # <title> satiri: baslik gelenegi, em-dash serbest
    if($s -match '<title>'){ $korunacak = $true }
    # tek satir yorum // veya JS regex/ikon iceren satir sezgisi
    if($s -match '^\s*//'){ $korunacak = $true }
    # blok yorum icindeysek
    if($icYorum){ $korunacak = $true }
    if($s -match '/\*'){ $icYorum = $true; $korunacak = $true }
    if($s -match '\*/'){ $icYorum = $false }
    if(-not $korunacak){
      $yeni = Sadelestir $s
      if($yeni -ne $s){ $dosyaDeg += ([regex]::Matches($s,' — ')).Count }
      $s = $yeni
    }
    [void]$sonuc.Append($s)
  }
  if($dosyaDeg -gt 0){
    [void]$rapor.Add([pscustomobject]@{ Dosya=$f.Name; Degisiklik=$dosyaDeg })
    $toplamDeg += $dosyaDeg
    if($Yaz){ [IO.File]::WriteAllText($f.FullName, $sonuc.ToString(), [Text.UTF8Encoding]::new($false)) }
  }
}
Write-Host ("=== EM-DASH SADELESTIRME{0} ===" -f $(if($Yaz){' (YAZILDI)'}else{' (olcum)'}))
$rapor | Sort-Object Degisiklik -Descending | ForEach-Object { Write-Host ("  {0,-28} {1} degisiklik" -f $_.Dosya, $_.Degisiklik) }
Write-Host ("`nTOPLAM: {0} cumle-ici tire, {1} sayfada" -f $toplamDeg, $rapor.Count)
