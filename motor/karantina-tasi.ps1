# ============================================================================
#  KARANTINA TASIYICI — 28.07.2026
#
#  SORUN: veri/fabrika altinda 535 soru duruyor ve bu depo PUBLIC. Tasiyici
#  yalnizca 'gm-onay' ve 'paket-havuzu' durumundakileri kasaya tasiyip depodan
#  siliyordu; karantinadakiler (okunmamis 435 + GM'nin reddettigi 34 + digerleri)
#  tasinamadigi icin ACIKTA kaliyordu. Parasi odenmis icerik herkese acik.
#
#  NIYE SIMDIYE KADAR TASINAMADI: kasaya giren her soru ANINDA CANLI oluyordu.
#  Okunmamis ya da reddedilmis bir soruyu kasaya koymak, onu ogrenciye servis
#  etmek demekti. Bugun Yayin Kapisi kuruldu (yayin kolonu) - artik bir soru
#  kasada DURABILIR ama YAYINDA OLMAZ. Tasima ancak bugun mumkun hale geldi.
#
#  NE YAPAR: karantinadaki sorulari kasaya yayin=false olarak tasir, sebebini
#  yayin_notu'na yazar, GERI OKUYUP DOGRULAR ve ancak ondan sonra yerel
#  dosyadan siler. Dogrulanmayan hicbir soru silinmez.
#
#  KARANTINA ASLA SILINMEZ kurali korunuyor: soru yok olmuyor, kasaya gecip
#  yayindan kapali bekliyor. GM okuyunca yayin=true yapilir.
# ============================================================================
param(
  [switch]$yaz     # gercekten tasi (varsayilan: yalniz olcum)
)
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$SB_URL = "https://bjrleanjpyujtajmazxn.supabase.co"

# 03.08 KOR KALMA: 12:28 kosusu FAILURE dondu ve iz birakmadi (Actions logu
# kilitli). Artik her olumcul hata veri/karantina-tasima.json'a yazilir.
trap {
  $g = ""; if($_.ErrorDetails -and $_.ErrorDetails.Message){ $g = $_.ErrorDetails.Message }
  [IO.File]::WriteAllText((Join-Path $kok 'veri/karantina-tasima.json'), (ConvertTo-Json -InputObject ([ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'
    hata="$($_.Exception.Message)"; sunucu=$g; satir=$_.InvocationInfo.ScriptLineNumber
  }) -Depth 4), (New-Object Text.UTF8Encoding($false)))
  Write-Host ("HATA (satir {0}): {1} | sunucu: {2}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message, $g)
  exit 1
}

$KEY = $env:SUPABASE_SERVICE_KEY
if(-not $KEY){ Write-Host "SUPABASE_SERVICE_KEY yok - atlandi."; exit 0 }
$H  = @{ apikey=$KEY; Authorization="Bearer $KEY" }
$HW = $H + @{ Prefer="return=minimal" }

# yayin kolonu olmadan bu is YAPILAMAZ - yoksa soru kasaya girer girmez canli olur
try { Invoke-RestMethod -Uri "$SB_URL/rest/v1/soru_havuzu?select=yayin&limit=1" -Headers $H -TimeoutSec 30 | Out-Null }
catch { Write-Host "KIRMIZI: 'yayin' kolonu yok. Tasima YAPILMAZ - soru kasaya girer girmez canli olurdu."; exit 1 }

$fabrikaDir = Join-Path $kok "veri\fabrika"
# 03.08 GERCEK: veri/fabrika .gitignore'DA (sizma korumasi - dogru karar).
# Yani bu klasor YALNIZ CEM'IN MAKINESINDE var; Actions kosucusunda YOKTUR
# ve tasima orada CALISAMAZ (12:47 kosusunun hatasi buydu). Kosucuda nazikce
# atlanir; gercek tasima YERELDE kosulur:
#   $env:SUPABASE_SERVICE_KEY = '<anahtar>' ; .\motor\karantina-tasi.ps1 -yaz
if(-not (Test-Path $fabrikaDir)){
  [IO.File]::WriteAllText((Join-Path $kok 'veri/karantina-tasima.json'), (ConvertTo-Json -InputObject ([ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='ATLANDI'
    not='veri/fabrika bu makinede yok (gitignore - yalniz yerelde). Tasima YERELDEN kosulmali: SUPABASE_SERVICE_KEY ile -yaz.'
  }) -Depth 4), (New-Object Text.UTF8Encoding($false)))
  Write-Host 'ATLANDI: veri/fabrika yok (yalniz yerel). Tasima yerelden kosulmali.'; exit 0
}
$TASINACAK = @('karantina','karantina-red','kasa-mukerrer','katman1-temiz')

# --- kasada zaten olan kimlikler (ayni soru iki kez girmesin)
$mevcut = @{}
$bas = 0
while($true){
  $s = Invoke-RestMethod -Uri "$SB_URL/rest/v1/soru_havuzu?select=id&order=id&offset=$bas&limit=1000" -Headers $H -TimeoutSec 180
  $d = @($s); if($d.Count -eq 0){ break }
  foreach($x in $d){ $mevcut["$($x.id)"] = 1 }
  if($d.Count -lt 1000){ break }
  $bas += 1000
}
Write-Host ("Kasadaki kimlik: {0}" -f $mevcut.Count)

$aday = New-Object System.Collections.Generic.List[object]
$ist = [ordered]@{ gorulen=0; zatenKasada=0; aday=0; yuklendi=0; dogrulandi=0; silindi=0 }
foreach($f in @(Get-ChildItem $fabrikaDir -Filter *.json | Sort-Object Name)){
  try { $x = Get-Content $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  if(-not $x.sorular){ continue }
  foreach($s in @($x.sorular)){
    if(-not $s){ continue }
    if($TASINACAK -notcontains "$($s.durum)"){ continue }
    $ist.gorulen++
    if($mevcut.ContainsKey("$($s.id)")){ $ist.zatenKasada++; continue }
    $aday.Add([pscustomobject]@{ dosya=$f.FullName; soru=$s })
    $ist.aday++
  }
}
Write-Host ("Karantinada: {0}  (kasada zaten var: {1})  TASINACAK: {2}" -f $ist.gorulen, $ist.zatenKasada, $ist.aday)

if(-not $yaz){ Write-Host "OLCUM MODU - hicbir sey tasinmadi. Tasimak icin -yaz."; exit 0 }
if($ist.aday -eq 0){ Write-Host "Tasinacak soru yok."; exit 0 }

# --- yukle (150'lik partiler; buyuk govde sunucu sinirlarina takiliyordu)
$yuklenen = @{}
$PARTI = 150
for($i=0; $i -lt $aday.Count; $i += $PARTI){
  $dilim = @($aday[$i..([Math]::Min($i+$PARTI-1, $aday.Count-1))])
  $govde = @($dilim | ForEach-Object {
    $s = $_.soru
    $sebep = switch("$($s.durum)"){
      'karantina'     { "KARANTINA: denetci itiraz etti, GM HENUZ OKUMADI." }
      'karantina-red' { "GM REDDETTI: " + "$($s.gmKarar)" }
      'kasa-mukerrer' { "MUKERRER: ayni soru kasada zaten var." }
      default         { "BEKLEMEDE: " + "$($s.durum)" }
    }
    [ordered]@{
      id=$s.id; sinav="$($s.sinav)"; ders="$($s.ders)"; konu="$($s.konu)"; soru="$($s.soru)"
      siklar=$s.siklar; dogru="$($s.dogru)"; aciklama=$s.aciklama
      kaynak="$($s.kaynak)"; hap="$($s.hap)"
      onay=$(if("$($s.gmKarar)".Trim()){ "GM $($s.gmTarih): $($s.gmKarar)" } else { "" })
      uretim="$($s.uretim)"
      yayin=$false
      yayin_notu=$sebep
    }
  })
  $json = ConvertTo-Json -InputObject $govde -Depth 6
  try {
    Invoke-RestMethod -Method Post -Uri "$SB_URL/rest/v1/soru_havuzu" -Headers $HW `
      -ContentType "application/json; charset=utf-8" -Body ([Text.Encoding]::UTF8.GetBytes($json)) -TimeoutSec 120 | Out-Null
    foreach($d in $dilim){ $yuklenen["$($d.soru.id)"] = 1 }
    $ist.yuklendi += $dilim.Count
  } catch {
    $cevap = ""
    try { $cevap = (New-Object IO.StreamReader($_.Exception.Response.GetResponseStream())).ReadToEnd() } catch {}
    Write-Host ("PARTI HATASI ({0} soru): {1}" -f $dilim.Count, $_.Exception.Message)
    if($cevap){ Write-Host ("SUNUCU: " + $cevap.Substring(0,[Math]::Min(400,$cevap.Length))) }
  }
  Write-Host ("  yuklendi ...{0}/{1}" -f $ist.yuklendi, $aday.Count)
}

# --- DOGRULA: yukledigimizi iddia ettigimiz kimlikler GERCEKTEN kasada mi?
# Depodaki ders: 'yesil kosu tam veri demek DEGIL' (45x cift kayit + 3.162
# kaydin sessiz kaybi boyle cikmisti). Silmeden once SAYARAK bak.
$dogru = @{}
$bas = 0
while($true){
  $s = Invoke-RestMethod -Uri "$SB_URL/rest/v1/soru_havuzu?select=id&order=id&offset=$bas&limit=1000" -Headers $H -TimeoutSec 180
  $d = @($s); if($d.Count -eq 0){ break }
  foreach($x in $d){ if($yuklenen.ContainsKey("$($x.id)")){ $dogru["$($x.id)"] = 1 } }
  if($d.Count -lt 1000){ break }
  $bas += 1000
}
$ist.dogrulandi = $dogru.Count
Write-Host ("DOGRULAMA: yuklendi {0}, kasada bulundu {1}" -f $ist.yuklendi, $ist.dogrulandi)
if($ist.dogrulandi -lt $ist.yuklendi){
  Write-Host "KIRMIZI: kasada bulunamayan kayit var - YEREL DOSYADAN HICBIR SEY SILINMEDI."
  exit 1
}

# --- ancak simdi yerelden sil (yalniz DOGRULANMIS kimlikler)
foreach($f in @(Get-ChildItem $fabrikaDir -Filter *.json)){
  try { $x = Get-Content $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  if(-not $x.sorular){ continue }
  $kalan = @($x.sorular | Where-Object { -not $dogru.ContainsKey("$($_.id)") })
  if($kalan.Count -eq @($x.sorular).Count){ continue }
  $ist.silindi += (@($x.sorular).Count - $kalan.Count)
  $yeni = [ordered]@{}
  foreach($p in $x.PSObject.Properties){ if($p.Name -ne 'sorular'){ $yeni[$p.Name] = $p.Value } }
  $yeni['sorular'] = $kalan
  [IO.File]::WriteAllText($f.FullName, (([pscustomobject]$yeni) | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false)))
}

Write-Host ""
Write-Host "======== KARANTINA TASIMA ========"
foreach($k in $ist.Keys){ Write-Host ("  {0,-14} {1}" -f $k, $ist[$k]) }
if($ist.silindi -ne $ist.dogrulandi){
  Write-Host ("UYARI: dogrulanan {0} ama yerelden silinen {1} - fark incelenmeli." -f $ist.dogrulandi, $ist.silindi)
}
[IO.File]::WriteAllText((Join-Path $kok 'veri/karantina-tasima.json'), ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); ozet=$ist
} | ConvertTo-Json -Depth 5), (New-Object Text.UTF8Encoding($false)))
exit 0
