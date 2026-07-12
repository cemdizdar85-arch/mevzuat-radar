# ============================================================================
#  KAYNAK NOBETCISI - resmi kaynak dosyalarini/sayfalarini HASH ile izler.
#  Bir kaynak degisince: (a) deterministik olanlari otomatik yeniden hasat eder,
#  (b) hepsini Cem'e mail ile bildirir. Boylece hicbir ust-kaynak degisikligi kacmaz.
#  GitHub Actions (ubuntu + pwsh) uzerinde haftalik kosar.
#  KURAL: yapay zeka ile "okuyup yazma" YOK - sadece deterministik yeniden hasat.
# ============================================================================
$ErrorActionPreference = "Continue"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$veriDir = Join-Path $kok "veri"
$hashDosya = Join-Path $veriDir ".kaynak-hash.json"
$UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) MevzuatRadar-Nobetci"

# --- izlenen kaynaklar -------------------------------------------------------
# tip=alert  : degisince sadece mail (elle/API ile guncellenecek: KDV, OTV, asgari ucret...)
# tip=rejim  : Ithalat Rejimi Excel duyuru sayfasi; zip degisirse otomatik yeniden hasat
$kaynaklar = @(
  @{ ad="GİB güncel KDV oranları (PDF)"; tip="alert"; url="https://cdn.gib.gov.tr/api/gibportal-file/file/getFileResources?objectKey=arsiv/yardim-kaynaklar/yararli-bilgiler/kdv-oranlari.pdf" }
  @{ ad="Ticaret Bak. Güncel Vergi Kodları"; tip="alert"; url="https://ticaret.gov.tr/gumruk-islemleri/dijital-gumruk-uygulamalari/edi-xml-referans-mesajlari/guncel-vergi-kodlari" }
  @{ ad="İthalat Rejimi / TGTC duyuru (Excel seti)"; tip="rejim"; url="https://ggm.ticaret.gov.tr/duyurular" }
)

function Hashle([string]$metin){
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $b = $sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($metin))
  return [System.BitConverter]::ToString($b) -replace '-',''
}
function Cek([string]$url){
  try { return (Invoke-WebRequest -Uri $url -UserAgent $UA -TimeoutSec 90 -UseBasicParsing).Content } catch { return $null }
}

# --- onceki hash'ler ---------------------------------------------------------
$onceki = @{}
if(Test-Path $hashDosya){ try { $j = Get-Content $hashDosya -Raw -Encoding UTF8 | ConvertFrom-Json; foreach($p in $j.PSObject.Properties){ $onceki[$p.Name] = $p.Value } } catch {} }
$yeni = @{}
$degisenler = @()

foreach($k in $kaynaklar){
  $icerik = Cek $k.url
  if($null -eq $icerik){ Write-Host "ULASILAMADI: $($k.ad)"; if($onceki.ContainsKey($k.ad)){ $yeni[$k.ad] = $onceki[$k.ad] }; continue }
  # sayfalarda tarih/oturum gurultusunu azalt: sadece govde metnini/duyuru linklerini hash'le
  $imza = $icerik
  if($k.tip -eq "rejim"){
    $imza = (([regex]::Matches($icerik, '(?i)(ithalat rejimi|gümrük tarife cetveli|istatistik pozisyon)[^<]{0,80}')) | ForEach-Object { $_.Value }) -join "|"
  }
  $h = Hashle $imza
  $yeni[$k.ad] = $h
  if($onceki.ContainsKey($k.ad) -and $onceki[$k.ad] -ne $h){
    $degisenler += $k
    Write-Host "DEGISTI: $($k.ad)"
  } elseif(-not $onceki.ContainsKey($k.ad)){
    Write-Host "ILK KAYIT: $($k.ad) (bu tur mail atilmaz)"
  } else {
    Write-Host "AYNI: $($k.ad)"
  }
}

# --- hash dosyasini guncelle -------------------------------------------------
($yeni | ConvertTo-Json) | Out-File $hashDosya -Encoding utf8

# --- degisiklik varsa mail ---------------------------------------------------
if($degisenler.Count -gt 0){
  $liste = ($degisenler | ForEach-Object { "- [$($_.tip)] $($_.ad): $($_.url)" }) -join "`n"
  $mail = @{
    access_key = "5b227e56-94fb-4123-a39a-4286f63db14a"
    subject    = "KAYNAK NOBETCISI: resmi kaynak degisti ($(Get-Date -Format dd.MM.yyyy))"
    from_name  = "Mevzuat Radari Kaynak Nobetcisi"
    email      = "cemdizdar85@hotmail.com"
    "Degisen kaynaklar" = $liste
    "Yapilacak" = "rejim tipi degistiyse: yeni Excel'i indirip 'pwsh motor/hepsini-hasat.ps1' calistir (deterministik, otomatik). alert tipi (KDV/vergi kodlari): birincil metni okuyup ilgili veriyi elle/deterministik guncelle. Robot uydurmaz - sadece haber verir."
  } | ConvertTo-Json
  try {
    Invoke-RestMethod -Method Post -Uri "https://api.web3forms.com/submit" -Body ([System.Text.Encoding]::UTF8.GetBytes($mail)) -ContentType "application/json" -TimeoutSec 30 | Out-Null
    Write-Host "MAIL gonderildi ($($degisenler.Count) kaynak)"
  } catch { Write-Host "MAIL gonderilemedi: $($_.Exception.Message)" }
} else {
  Write-Host "Degisiklik yok - mail atilmadi."
}
