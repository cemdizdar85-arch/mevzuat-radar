# ============================================================================
#  KARAR DURUMU YOGUNLASMA NOBETI  (28.08.2026)
#
#  NEDEN VAR: 28.08'de 'ret_iflas' damgasi kuruldu ve sayilar temiz gorundu
#  (65 ilan, kirli kayit 0). Ama IL KIRILIMI bakilinca ortaya cikti:
#      ISTANBUL 1.462 konkordato · 231 ret ilani · basliginda iflas gecen <2
#      BURSA      309 konkordato ·  29 ret ilani · basliginda iflas gecen 39
#  IIK m.308/b iflasa tabi sirketlerde iflas kararini ZORUNLU kilar; Istanbul'da
#  231 retin hicbirinin iflasla bitmemesi imkansiz. Yani olculen sey OLAY degil,
#  MAHKEMENIN BASLIK YAZMA ALISKANLIGIYDI. Bursa yaziyor, Istanbul yazmiyor.
#
#  DERS (bu nobetin varlik sebebi): bir alani METINDEN turetiyorsan, dagilimina
#  COGRAFYA kiriliminda da bak. Tek bir il/kurum patliyorsa olctugun sey olay
#  degil, o kurumun yazim pratigidir. Bunu gozle yakalamak sansa kalir - kapiya
#  cevrildi.
#
#  NASIL CALISIR: her karar_durumu icin "en buyuk ilin payi" olculur ve ARSIVIN
#  KENDI TABANIYLA kiyaslanir (tum ilanlarda en buyuk il ~%27 = Istanbul). Bir
#  durumda en buyuk il payi tabanin KAT_ESIGI katini asiyorsa o durum supheli.
#
#  UC SONUC (kalici sigorta kurali - bkz kalici-sigorta-3katman):
#    YESIL   - olculdu, supheli durum yok
#    KIRMIZI - olculdu, en az bir durum esigi asti
#    KOR     - OLCULEMEDI (anahtar yok / istek basarisiz). Sifir sonuc DEGIL.
#
#  Env: SUPABASE_URL, SUPABASE_SERVICE_KEY  (kaynak.yml'deki secret ile ayni)
# ============================================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$URL = $env:SUPABASE_URL;         if (-not $URL) { $URL = 'https://bjrleanjpyujtajmazxn.supabase.co' }
$KEY = $env:SUPABASE_SERVICE_KEY
$KAT_ESIGI = if ($env:KAT_ESIGI) { [double]$env:KAT_ESIGI } else { 2.0 }
$MIN_ILAN  = if ($env:MIN_ILAN)  { [int]$env:MIN_ILAN }     else { 20 }

if (-not $KEY) {
  Write-Host "KOR: SUPABASE_SERVICE_KEY yok - yogunlasma OLCULEMEDI (sifir sonuc degil)."
  exit 0
}

# --- veriyi cek (PostgREST 1.000 satir tavani: Range ile sayfala) ------------
$bas = (Get-Date).AddDays(-365).ToString('yyyy-MM-dd')
$H = @{ apikey = $KEY; Authorization = "Bearer $KEY"; Accept = 'application/json' }
$satirlar = @()
$adim = 1000; $ofset = 0
try {
  while ($true) {
    $u = "$URL/rest/v1/alacak_ilan?select=il,karar_durumu&tarih=gte.$bas"
    $hh = $H.Clone(); $hh['Range'] = "$ofset-$($ofset + $adim - 1)"
    $p = Invoke-RestMethod -Method Get -Uri $u -Headers $hh -TimeoutSec 90
    $p = @($p); if (-not $p.Count) { break }
    $satirlar += $p
    if ($p.Count -lt $adim) { break }
    $ofset += $adim
    if ($ofset -gt 60000) { break }   # kacak dongu freni
  }
} catch {
  Write-Host ("KOR: veri cekilemedi - {0}" -f $_.Exception.Message)
  exit 0
}

if (-not $satirlar.Count) { Write-Host "KOR: 0 satir dondu - kasa bos olamaz, olcum guvenilmez."; exit 0 }
Write-Host ("Olculen: {0} ilan (son 365 gun)" -f $satirlar.Count)

function IlAdi($x) { if ("$x") { "$x" } else { 'Belirtilmemis' } }

# --- TABAN: tum arsivde en buyuk ilin payi -----------------------------------
$tumIl = @{}
foreach ($s in $satirlar) { $i = IlAdi $s.il; $tumIl[$i] = 1 + $(if ($tumIl.ContainsKey($i)) { $tumIl[$i] } else { 0 }) }
$tabanIl  = ($tumIl.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1)
$tabanPay = [double]$tabanIl.Value / $satirlar.Count
Write-Host ("TABAN: en buyuk il {0} = %{1:N1} (tum ilanlarda)" -f $tabanIl.Key, ($tabanPay * 100))
Write-Host ""

# --- her durum icin yogunlasma ----------------------------------------------
$durumlar = @{}
foreach ($s in $satirlar) {
  $d = if ("$($s.karar_durumu)") { "$($s.karar_durumu)" } else { 'damgasiz' }
  $i = IlAdi $s.il
  if (-not $durumlar.ContainsKey($d)) { $durumlar[$d] = @{} }
  $durumlar[$d][$i] = 1 + $(if ($durumlar[$d].ContainsKey($i)) { $durumlar[$d][$i] } else { 0 })
}

$supheli = @()
Write-Host ("{0,-16} {1,7} {2,-16} {3,8} {4,7}  {5}" -f 'durum','toplam','en buyuk il','adet','pay','sonuc')
Write-Host ('-' * 78)
foreach ($d in ($durumlar.Keys | Sort-Object)) {
  $toplam = ($durumlar[$d].Values | Measure-Object -Sum).Sum
  $enb = ($durumlar[$d].GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1)
  $pay = [double]$enb.Value / $toplam
  $kat = if ($tabanPay -gt 0) { $pay / $tabanPay } else { 0 }
  $sonuc = 'ok'
  if ($toplam -ge $MIN_ILAN -and $kat -ge $KAT_ESIGI) {
    $sonuc = ("SUPHELI (tabanin {0:N1} kati)" -f $kat)
    $supheli += [pscustomobject]@{ durum = $d; toplam = $toplam; il = $enb.Key; adet = $enb.Value; pay = $pay; kat = $kat }
  }
  Write-Host ("{0,-16} {1,7} {2,-16} {3,8} {4,6:N1}%  {5}" -f $d, $toplam, $enb.Key, $enb.Value, ($pay * 100), $sonuc)
}

Write-Host ""
if ($supheli.Count) {
  Write-Host "KIRMIZI: $($supheli.Count) durumda cografi yogunlasma esigi asildi."
  foreach ($s in $supheli) {
    Write-Host ("  - '{0}': {1} ilanin {2} tanesi {3} ({4:N1}%). Bu, o durumun GERCEK dagilimi olabilir" -f $s.durum, $s.toplam, $s.adet, $s.il, ($s.pay * 100))
    Write-Host ("    ama once sunu ele: o ildeki mahkemeler basligi FARKLI mi yaziyor? Ayni olay baska")
    Write-Host ("    illerde baska bir durum kovasinda duruyor olabilir - iddia kurmadan METINDEN dogrula.")
  }
  exit 1
}
Write-Host "YESIL: hicbir durumda esigi asan cografi yogunlasma yok."
exit 0
