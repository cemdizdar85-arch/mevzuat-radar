#requires -Version 5.1
<#
================================================================================
  ÇIKMIŞ SINAV KÜLLİYATINI RAG'A HAZIRLA (10.09.2026)

  NE YAPAR: Eski ambardaki (Supabase `dokumanlar`) çıkmış sınav belgelerini
  çeker ve RAG motorunun `yutdizin` komutunun okuduğu JSON biçiminde yerel
  kasaya yazar. Sonra:
      powershell -NoProfile -File rag-motor/motor.ps1 yutdizin <klasor>

  ⛔ NEDEN AYRI TÜR: bu belgeler `tur = "cikmis-sinav"` ile yazılır ve
  DAYANAK ARAMASINDAN MİMARİ OLARAK DIŞLANIR (`rag.ara` p_kaynak_tur süzgeci).

  Sebebi soru üretim sözleşmesi A1'dir: çıkmış soru birebir kopyalanamaz.
  Sınav metni dayanak havuzuna karışırsa motor bir gün çıkmış bir soruyu
  "dayanak" sanıp onu yeniden yazar — tam olarak yasaklanan şey. Karışmayı
  temenniyle değil, TÜR AYRIMIYLA engelliyoruz.

  ✅ NE İŞE YARAR: vektörlenmiş sınav külliyatı, A1'in eksik MEKANİK KAPISINI
  kurar. Üretilen her soru bu külliyattaki en yakın komşusuyla kıyaslanabilir;
  benzerlik eşiği aşılırsa soru reddedilir. Telif kuralı "isteme yazılı"
  olmaktan çıkıp ölçülebilir bir kapıya dönüşür.

  ⚠️ ÇIKTI GİT'E GİRMEZ: `_yerel-veri-kasasi/` altına yazılır (depo kuralı).

  KULLANIM
    powershell -NoProfile -File arac/cikmis-sinav-disaver.ps1
    powershell -NoProfile -File arac/cikmis-sinav-disaver.ps1 -Tavan 100
================================================================================
#>
param(
  [int]$Tavan = 400,
  [string]$Hedef = ''
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here    = Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok = Split-Path -Parent $here

if (-not $Hedef) {
  $Hedef = Join-Path (Split-Path -Parent $depoKok) '_yerel-veri-kasasi\cikmis-sinav'
}
if (-not (Test-Path $Hedef)) { New-Item -ItemType Directory -Force -Path $Hedef | Out-Null }

$KEY = $env:SUPABASE_SERVICE_KEY
if (-not $KEY) { $KEY = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
if (-not $KEY) { throw 'SUPABASE_SERVICE_KEY yok.' }
$H  = @{ apikey = $KEY; Authorization = "Bearer $KEY"; 'User-Agent' = 'mevzuat-radar-robot/1.0' }
$SB = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar'

function GuvenliAd([string]$s) {
  # Dosya adı olacak: Türkçe harf ve boşluk temizlenir, uzunluk kısılır.
  $t = ("$s" -creplace 'İ','I' -creplace 'ı','i' -creplace 'Ğ','G' -creplace 'ğ','g' `
             -creplace 'Ü','U' -creplace 'ü','u' -creplace 'Ş','S' -creplace 'ş','s' `
             -creplace 'Ö','O' -creplace 'ö','o' -creplace 'Ç','C' -creplace 'ç','c')
  $t = $t -replace '[^A-Za-z0-9]+','-' -replace '-+','-' -replace '^-|-$',''
  if ($t.Length -gt 90) { $t = $t.Substring(0,90) }
  if (-not $t) { $t = 'belge' }
  return $t
}

Write-Host "== CIKMIS SINAV KULLIYATI cekiliyor ==" -ForegroundColor Cyan
$adim = 20
$yazilan = 0; $toplamKrk = 0; $atlanan = 0
$sayac = @{}

for ($off = 0; $off -lt $Tavan; $off += $adim) {
  $u = "$SB`?select=id,kaynak_ad,baslik,metin,kaynak_url,belge_tarihi" +
       "&tur=in.(cikmis-soru,cikmis-komisyon-cevabi)&order=id&limit=$adim&offset=$off"
  try { $r = Invoke-WebRequest -Uri $u -Headers $H -UseBasicParsing -TimeoutSec 180 }
  catch { Write-Host "  ! sayfa $off alinamadi: $($_.Exception.Message)" -ForegroundColor Yellow; continue }

  # PS 5.1 TUZAGI: ConvertFrom-Json ust duzey diziyi TEK nesne dondurebilir.
  # | ForEach-Object { $_ } ile acilmadan @() sarmasi satirlari kaybettirir.
  $satirlar = @(($r.Content | ConvertFrom-Json) | ForEach-Object { $_ })
  if ($satirlar.Count -eq 0) { break }

  foreach ($s in $satirlar) {
    if (-not $s.metin -or $s.metin.Length -lt 200) { $atlanan++; continue }

    # Hangi sinav? Dosya adina yazilir ki kaynak kodundan okunabilsin.
    $sinav = if ($s.kaynak_ad -match 'KGK') { 'KGK' }
             elseif ($s.kaynak_ad -match 'SGS|STAJ') { 'SGS' }
             elseif ($s.kaynak_ad -match 'SMMM|YETERLIL') { 'SMMM' }
             else { 'DIGER' }
    if ($sayac.ContainsKey($sinav)) { $sayac[$sinav]++ } else { $sayac[$sinav] = 1 }

    $ad  = GuvenliAd $s.kaynak_ad
    $yol = Join-Path $Hedef ("SINAV-{0}-{1}-{2}.json" -f $sinav, $s.id, $ad)

    $nesne = [ordered]@{
      belgeler = @(
        [ordered]@{
          tur          = 'cikmis-sinav'      # ⛔ DAYANAK DEGIL - arama turu ile dislanir
          kaynak_ad    = $s.kaynak_ad
          baslik       = $s.baslik
          metin        = $s.metin
          kaynak_url   = $s.kaynak_url
          belge_tarihi = $s.belge_tarihi
        }
      )
    }
    $nesne | ConvertTo-Json -Depth 6 | Set-Content -Path $yol -Encoding UTF8
    $yazilan++; $toplamKrk += $s.metin.Length
  }
  Write-Host ("  {0} belge · {1:N0} karakter" -f $yazilan, $toplamKrk)
}

Write-Host ""
Write-Host ("YAZILDI: {0} belge · {1:N0} karakter · atlanan {2}" -f $yazilan, $toplamKrk, $atlanan) -ForegroundColor Green
$sayac.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object { Write-Host ("  {0,-6} {1}" -f $_.Key, $_.Value) }
Write-Host ""
Write-Host "SIRADAKI:" -ForegroundColor Cyan
Write-Host "  powershell -NoProfile -File rag-motor/motor.ps1 yutdizin `"$Hedef`""
