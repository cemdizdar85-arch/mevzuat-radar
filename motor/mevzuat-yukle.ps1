# ============================================================================
#  MEVZUAT YUKLEYICI  —  veri/mevzuat/*.json (kanun madde-belgeleri) -> Supabase
#  'dokumanlar' tablosu. Beyin (net-cevap) FTS ile MADDENIN KENDISINDEN alintiyla
#  cevaplar. Kaynak: mevzuat.gov.tr konsolide metin (pdftotext, madde madde).
#  tur='kanun-madde' -> kuratorlu 14 ambar belgesine (ambar-yukle) DOKUNMAZ.
#  Idempotent: once tur=kanun-madde siler, sonra toplu ekler (batch=500).
#  ENV: SUPABASE_SERVICE_KEY (zorunlu). Yoksa zarifce atlar (exit 0).
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
try { [System.Text.Encoding]::RegisterProvider([System.Text.CodePagesEncodingProvider]::Instance) } catch {}

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$SB_URL = "https://bjrleanjpyujtajmazxn.supabase.co"

$KEY = $env:SUPABASE_SERVICE_KEY
if(-not $KEY){ Write-Host "SUPABASE_SERVICE_KEY yok - mevzuat yukleyici atlandi."; exit 0 }
$H = @{ apikey = $KEY; Authorization = "Bearer $KEY" }

$dir = Join-Path $kok "veri/mevzuat"
if(-not (Test-Path $dir)){ Write-Host "veri/mevzuat yok."; exit 0 }

# --- topla + dedup (kaynak_ad) ---
$hepsi = New-Object System.Collections.Generic.List[object]
$gorulen = @{}
Get-ChildItem $dir -Filter *.json | ForEach-Object {
  $d = Get-Content $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
  foreach($b in @($d.belgeler)){
    if(-not $b.kaynak_ad -or -not $b.metin){ continue }
    $k = "$($b.kaynak_ad)"
    if($gorulen.ContainsKey($k)){ continue }
    $gorulen[$k] = $true
    $hepsi.Add([ordered]@{
      tur          = $(if($b.tur){ "$($b.tur)" } else { "kanun-madde" })   # standart-madde (TMS/BDS) belgeleri kendi turunu tasir
      kaynak_ad    = $k
      baslik       = "$($b.baslik)"
      metin        = "$($b.metin)"
      kaynak_url   = "$($b.kaynak_url)"
      belge_tarihi = $null
    })
  }
}
Write-Host ("Yuklenecek: {0} madde-belgesi" -f $hepsi.Count)
if($hepsi.Count -eq 0){ exit 0 }

# --- once eski kayitlari sil (idempotent) ---
# 27.07.2026 DUZELTME: silme listesinde 'teblig' YOKTU. Dosyalardaki 1.288
# teblig kaydi her kosuda siliNMEden yeniden ekleniyordu; ambarda ayni
# kaynak_ad'dan 45 KOPYA birikmisti (57.622 satir). Silme listesine eklendi.
# KURAL: bu betik hangi tur'leri EKLIYORSA, hepsini SILMEK zorunda.
$SILINECEK = "kanun-madde,standart-madde,teori-notu,teblig"
try {
  Invoke-RestMethod -Method Delete -Uri "$SB_URL/rest/v1/dokumanlar?tur=in.($SILINECEK)" -Headers ($H + @{ Prefer = "return=minimal" }) -TimeoutSec 300 | Out-Null
  Write-Host "Eski kayitlar silindi (tur: $SILINECEK)."
} catch {
  Write-Host "KRITIK: silme basarisiz ($_) - cift kayit riski, kosu durduruluyor."
  exit 1
}

# --- toplu ekle ---
# 27.07.2026 DUZELTME: eski hal batch=500 idi ve basarisiz partiyi SESSIZCE
# yutup devam ediyordu (sadece Write-Host). Bu yuzden 3.162 kayit (3.088
# kanun-madde + 74 standart-madde, ic. tum MSUGT ilkeleri ve 44 THP hesabi)
# ambara hic girmemis, kosu yine de YESIL gorunmustu. Artik: parti kucultuldu,
# basarisiz parti 3 kez denenir, yine olmazsa TEK TEK yazilir ve sonunda
# eksik varsa is KIRMIZI biter. Sessiz veri kaybi yok.
$batch = 200; $eklenen = 0; $basarisiz = New-Object System.Collections.Generic.List[object]

function Gonder($kayitlar){
  $json = ($kayitlar | ConvertTo-Json -Depth 5)
  if(@($kayitlar).Count -eq 1){ $json = "[$json]" }   # tek elemanda PS array'i acar
  $gonder = [System.Text.Encoding]::UTF8.GetBytes($json)
  Invoke-RestMethod -Method Post -Uri "$SB_URL/rest/v1/dokumanlar" -Headers ($H + @{ Prefer = "return=minimal" }) -ContentType "application/json; charset=utf-8" -Body $gonder -TimeoutSec 300 | Out-Null
}

for($i=0; $i -lt $hepsi.Count; $i += $batch){
  $son = [Math]::Min($i+$batch, $hepsi.Count) - 1
  $dilim = $hepsi[$i..$son]
  $ok = $false
  for($deneme=1; $deneme -le 3 -and -not $ok; $deneme++){
    try { Gonder $dilim; $ok = $true }
    catch {
      Write-Host ("  UYARI batch {0}-{1} deneme {2}/3: {3}" -f $i, $son, $deneme, $_)
      if($deneme -lt 3){ Start-Sleep -Seconds (5 * $deneme) }
    }
  }
  if($ok){
    $eklenen += $dilim.Count
    Write-Host ("  batch {0}-{1} eklendi ({2}/{3})" -f $i, $son, $eklenen, $hepsi.Count)
  } else {
    # parti 3 kez dustu -> tek tek yaz, boylece yalniz gercekten bozuk kayit duser
    Write-Host ("  batch {0}-{1} 3 denemede gecmedi -> tek tek yaziliyor" -f $i, $son)
    foreach($k in $dilim){
      try { Gonder @($k); $eklenen++ }
      catch { $basarisiz.Add($k.kaynak_ad); Write-Host ("    DUSEN: {0} | {1}" -f $k.kaynak_ad, $_) }
    }
  }
}

Write-Host ("MEVZUAT YUKLENDI - {0}/{1} belge yazildi." -f $eklenen, $hepsi.Count)
if($basarisiz.Count -gt 0){
  Write-Host ("KIRMIZI: {0} kayit ambara GIRMEDI. Ilk 20:" -f $basarisiz.Count)
  $basarisiz | Select-Object -First 20 | ForEach-Object { Write-Host ("   - " + $_) }
  exit 1
}
if($eklenen -ne $hepsi.Count){
  Write-Host ("KIRMIZI: sayim tutmuyor ({0} != {1})." -f $eklenen, $hepsi.Count)
  exit 1
}
exit 0
