# ============================================================================
#  GTIP SORGU v0 - urunun kalbi: "kodunu gir, durumunu gor"
#  Kullanim: powershell -ExecutionPolicy Bypass -File sorgu.ps1 -Gtip 6910.10.00.00.00
# ============================================================================
param([Parameter(Mandatory=$true)][string]$Gtip)
$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

$duruYol = Join-Path $here "hafiza\gtip-durum.json"
$kiymetYol = Join-Path $here "hafiza\kiymetler.json"

Write-Host ""
Write-Host ("=== GTIP DURUM KARTI: {0} ===" -f $Gtip) -ForegroundColor Cyan

$bulundu = $false

# 1) Resmi birlesik tablolardan mevcut gozetim durumu
if(Test-Path $duruYol){
  $durum = Get-Content $duruYol -Raw -Encoding UTF8 | ConvertFrom-Json
  $kayit = $durum.$Gtip
  if($kayit){
    $bulundu = $true
    Write-Host ""
    Write-Host "GOZETIM DURUMU (resmi birlesik metinlerden):" -ForegroundColor Yellow
    foreach($k in @($kayit)){
      Write-Host ("  Birim kiymet: {0}" -f $k.deger)
      Write-Host ("  Dayanak: Ithalatta Gozetim Tebligi {0}" -f $k.teblig)
      Write-Host ("  Resmi metin: {0}" -f $k.kaynak)
    }
  }
}

# 2) Guncel degisiklik hafizasi (radar kartlarindan)
if(Test-Path $kiymetYol){
  $kiymet = Get-Content $kiymetYol -Raw -Encoding UTF8 | ConvertFrom-Json
  $gecmis = $kiymet.$Gtip
  if($gecmis){
    $bulundu = $true
    Write-Host ""
    Write-Host "RADAR KAYITLARI (yeni degisiklikler):" -ForegroundColor Yellow
    foreach($g in @($gecmis)){
      Write-Host ("  {0}: {1}  (RG degisikligi: {2})" -f $g.tarih, $g.deger, $g.teblig)
    }
  }
}

if(-not $bulundu){
  Write-Host ""
  Write-Host "Bu kod icin kayitli gozetim durumu bulunamadi." -ForegroundColor Green
  Write-Host "(Kapsam: aktif gozetim tebligleri. Damping/UGD katmanlari yolda.)"
}
Write-Host ""
Write-Host "Not: Bilgilendirme amaclidir; islem oncesi kaynak teblige bakiniz." -ForegroundColor DarkGray