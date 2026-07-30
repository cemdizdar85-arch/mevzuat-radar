# ============================================================================
#  KIRMIZI ÇEKME — hakem yargısı kırmızı olan YAYINDAKİ sorular yayından iner
#
#  Cem'in kuralı (29.07): "doğru olmayan veri sistemimizde olmayacak;
#  güvenmediğimiz hiçbir şey siteye girmesin."
#
#  Hakem hasadı 7.224 yargı topladı; 717'si KIRMIZI (destek=hayir veya
#  celiski=evet). Yerel kesişim ölçümü: bunların ~224'ü denetim kuyruğunda
#  DEĞİL — yani muhtemelen YAYINDA ve öğrenciye gösteriliyor.
#
#  BU BETİK SİLMEZ: yayin=false yapar + yayin_notu'na hakem gerekçesini
#  yazar. GM okur; haklı bulursa düzeltilir ya da geri açılır. Filtre
#  yayin=eq.true olduğu için zaten kapalı olanlara DOKUNULMAZ - işlem
#  yalnız yayındaki kırmızıları indirir ve ikinci koşuda 0 etkiler
#  (idempotent).
#
#  PARA HARCAMAZ: yalnız Supabase PATCH (servis anahtarı Actions'ta).
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
try { Start-Transcript -Path (Join-Path $kok 'veri/kirmizi-cek-log.txt') -Force | Out-Null } catch {}

$SB_URL = "https://bjrleanjpyujtajmazxn.supabase.co"
$KEY = $env:SUPABASE_SERVICE_KEY
if(-not $KEY){ Write-Host "SUPABASE_SERVICE_KEY yok - cikiliyor."; try{Stop-Transcript|Out-Null}catch{}; exit 1 }
$H  = @{ apikey=$KEY; Authorization="Bearer $KEY"; Prefer="return=minimal" }

$hasatYol = Join-Path $kok 'veri/hakem-hasadi.json'
if(-not (Test-Path $hasatYol)){ Write-Host "hakem-hasadi.json yok."; try{Stop-Transcript|Out-Null}catch{}; exit 1 }
$h = ConvertFrom-Json ([IO.File]::ReadAllText($hasatYol, [Text.Encoding]::UTF8))
$kirmizi = @($h.kirmizi)
Write-Host ("Kirmizi yargi: {0}" -f $kirmizi.Count)
if($kirmizi.Count -eq 0){ Write-Host "Kirmizi yok - is yok."; try{Stop-Transcript|Out-Null}catch{}; exit 0 }

# gerekceyi de tasi: GM yayin_notu'ndan NEDEN cekildigini gorsun
$cekilen = 0; $dilimSay = 0
$hepsi = @($kirmizi | ForEach-Object { "$($_.id)" } | Where-Object { $_ -match '^[0-9a-f-]{36}$' })
Write-Host ("Gecerli UUID: {0}" -f $hepsi.Count)
for($i = 0; $i -lt $hepsi.Count; $i += 80){
  $dilim = @($hepsi[$i..([Math]::Min($i+79, $hepsi.Count-1))])
  $liste = ($dilim -join ',')
  $dilimSay++
  # ONCE kac tanesi yayinda SAY (count=exact ile), SONRA cek - kor yazma yok
  try {
    $s = Invoke-WebRequest -UseBasicParsing -Uri "$SB_URL/rest/v1/soru_havuzu?select=id&yayin=eq.true&id=in.($liste)&limit=1" `
         -Headers @{ apikey=$KEY; Authorization="Bearer $KEY"; Prefer='count=exact' } -TimeoutSec 90
    $n = [int](($s.Headers['Content-Range'] -split '/')[-1])
  } catch { Write-Host ("  dilim {0}: sayim hatasi {1}" -f $dilimSay, $_.Exception.Message); continue }
  if($n -eq 0){ continue }
  $govde = @{ yayin = $false
              yayin_notu = "HAKEM KIRMIZI 29.07.2026: destek=hayir veya celiski=evet. Odenmis denetim hasadindan (hakem-hasadi.json). GM okumadan geri ACILMAZ." } | ConvertTo-Json
  try {
    Invoke-RestMethod -Method Patch -Uri "$SB_URL/rest/v1/soru_havuzu?yayin=eq.true&id=in.($liste)" `
      -Headers $H -ContentType "application/json; charset=utf-8" `
      -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 120 | Out-Null
    $cekilen += $n
    Write-Host ("  dilim {0}: {1} soru yayindan cekildi" -f $dilimSay, $n)
  } catch {
    Write-Host ("  dilim {0}: PATCH hatasi {1}" -f $dilimSay, $_.Exception.Message)
  }
}
Write-Host ""
Write-Host ("TOPLAM YAYINDAN CEKILEN: {0} soru" -f $cekilen)
Write-Host "Silinen YOK - hepsi yayin=false, gerekceleri yayin_notu'nda ve hakem-hasadi.json'da."
[IO.File]::WriteAllText((Join-Path $kok 'veri/kirmizi-cek-sonuc.json'),
  ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); kirmizi=$kirmizi.Count; yayindan_cekilen=$cekilen } | ConvertTo-Json),
  (New-Object Text.UTF8Encoding($false)))
try{Stop-Transcript|Out-Null}catch{}
