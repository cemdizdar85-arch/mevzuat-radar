# ============================================================================
#  RG KARAR ARAMA - belirli bir tarih araligindaki Resmi Gazete fihristlerini
#  tarar ve verilen desenleri arar. Cem 13.08: "Cumhurbaskani karari var mi - olc".
#  Somut soru: 4734 s.K. ek m.13 (Ek: 24/7/2026-7590/13 md.) yerli mali
#  avantajinin AB'ye mutekabiliyetle taninmasi yetkisi KULLANILDI MI?
#  OLCUM betigi - hicbir yere yazmaz, ekrana rapor eder.
# ============================================================================
param(
  [string]$Bas = "2026-07-24",
  [string]$Son = "2026-08-13",
  [string[]]$Desen = @('m[üu]tekabiliyet','yerli mal','yerli istekli','4734')
)
$ErrorActionPreference = "Continue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) MevzuatRadar-RGTarama/1.0"

$b = [datetime]::ParseExact($Bas,'yyyy-MM-dd',$null)
$s = [datetime]::ParseExact($Son,'yyyy-MM-dd',$null)
Write-Host ("RG taramasi: {0:dd.MM.yyyy} - {1:dd.MM.yyyy} ({2} gun)" -f $b,$s,(($s-$b).Days+1))
Write-Host ("Desenler: " + ($Desen -join ' | ') + "`n")

$bulgu = @(); $okunan = 0; $bosGun = @()
# platform bagimsiz gecici dosya (Linux/Actions uyumu)
$gecici = Join-Path ([IO.Path]::GetTempPath()) "rg-fihrist.html"
# TUZAK (13.08 olculdu): RG fihristi WINDOWS-1254 (Turkce) kodlu ama sayfada charset
# meta'si yok; Invoke-WebRequest .Content'i Latin1 sanip cozuyor ve "Karar Sayısı"
# metinde "Karar Sayýsý" oluyor. Ilk kosu 14 gunde SIFIR bulgu verdi - oysa her gun
# karar var. Ham bayt indirilir, 1254 ile cozulur.
# (Ayni ailenin dersleri: turkce-harf-bozulmasi, pdftotext -enc UTF-8.)
$kod1254 = [Text.Encoding]::GetEncoding(1254)
for($t = $b; $t -le $s; $t = $t.AddDays(1)){
  $u = "https://www.resmigazete.gov.tr/eskiler/{0:yyyy}/{0:MM}/{0:yyyyMMdd}.htm" -f $t
  try {
    Invoke-WebRequest -Uri $u -Headers @{ "User-Agent"=$ua } -UseBasicParsing -TimeoutSec 60 -OutFile $gecici
  } catch { $bosGun += ("{0:dd.MM} (erisilemedi)" -f $t); continue }
  $okunan++
  $ham = $kod1254.GetString([IO.File]::ReadAllBytes($gecici))
  # HTML etiketlerini sok, metni sadelestir
  $m = ($ham -replace '<[^>]+>',' ') -replace '&nbsp;',' ' -replace '\s+',' '
  foreach($d in $Desen){
    foreach($x in ([regex]::Matches($m, "(?i).{0,140}$d.{0,140}"))){
      $bulgu += [pscustomobject]@{ tarih=("{0:dd.MM.yyyy}" -f $t); desen=$d; baglam=$x.Value.Trim(); url=$u }
    }
  }
  Start-Sleep -Milliseconds 250
}
Write-Host ("Okunan fihrist: {0} · erisilemeyen: {1}" -f $okunan, $bosGun.Count)
if($bosGun.Count){ Write-Host ("  " + ($bosGun -join ', ')) }

if(-not $bulgu.Count){
  Write-Host "`nSONUC: Bu aralikta hicbir desen gecmedi."
  exit 0
}
Write-Host ("`n=== {0} BULGU ===" -f $bulgu.Count)
foreach($g in ($bulgu | Sort-Object tarih)){
  Write-Host ("`n[{0}] ~{1}~" -f $g.tarih, $g.desen)
  Write-Host ("   " + $g.baglam)
  Write-Host ("   {0}" -f $g.url)
}
