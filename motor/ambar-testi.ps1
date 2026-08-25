# ============================================================================
#  AMBAR ALTIN TESTI — retrieval sigortasi (guven katmani C-1)
#  veri/ambar-altin-test.json'daki her soru icin madde_ara RPC'sini cagirir;
#  beklenen kaynak top-6'da yoksa vaka DUSER. Dusen vaka varsa exit 1 →
#  CI kirmizi + GitHub bildirimi. LLM YOK: bu kapi saf retrieval olcer.
#  Yerel: pwsh motor/ambar-testi.ps1   CI: mevzuat.yml hasat sonrasi adim.
# ============================================================================
$ErrorActionPreference = 'Stop'
# Supabase gizli anahtarli istegi KIMLIKSIZ gelirse 401 ile reddeder.
# (16.08.2026 olculdu: ayni sorgu UA'siz 401, UA'li 5 kayit. madde-coz.ps1
#  bu yuzden her kaynaga "ambarda-yok" diyordu.) IRM ve IWR AYRI yazilir.
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$PSDefaultParameterValues['Invoke-WebRequest:UserAgent'] = 'mevzuat-radar-robot/1.0'
$SB  = 'https://bjrleanjpyujtajmazxn.supabase.co'
$KEY = if ($env:SB_PUBLISHABLE) { $env:SB_PUBLISHABLE } else { 'sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg' }  # public anon key

$kok = Split-Path -Parent $PSScriptRoot
$setYol = Join-Path $kok 'veri/ambar-altin-test.json'
$set = Get-Content -Raw -Encoding UTF8 $setYol | ConvertFrom-Json

# edge/net-cevap.ts ile AYNI on-isleme: tr-lower + noktalama temizle + stop + fold
$STOP = @('var','varsa','yok','kac','ne','nasil','mi','mu','olur','odeme','sure','suresi','icin','ile','bir','bu','kesilir','geldi','aldim','nedir','kadar','gibi','daha','cok','hangi')  # 'vergi' cikarildi (17.07.2026) — edge ile AYNI kalmali
function Fold([string]$s) {
  $s = $s.ToLower([System.Globalization.CultureInfo]::GetCultureInfo('tr-TR'))
  ($s -replace 'ı','i' -replace 'ş','s' -replace 'ğ','g' -replace 'ü','u' -replace 'ö','o' -replace 'ç','c' -replace 'â','a' -replace 'î','i' -replace 'û','u')
}
# ---------------------------------------------------------------------------
#  TURKCE EK SOYMA (25.08.2026) — OLCULEREK SECILDI, TAHMINLE DEGIL.
#
#  Sorun: sorgu cekimli, belge kok halinde. to_tsquery prefix'i ('kelime:*')
#  yalniz SAGA dogru genisler; sorgudaki ek belgeyi bulmayi ENGELLER.
#  Kokle aramak ise KAPSAMI GENISLETIR: 'sicil:*' hem "sicili" hem "siciline"
#  hem "sicilinde"yi tutar.
#
#  arac/sirala-tarti.ps1 -Dil ile 48 altin vaka uzerinde UCTAN UCA olculdu:
#      mevcut (taban)      41/48
#      genis durak listesi 41/48   (+0  -> fayda yok, birlesince ZARARLI: 43)
#      ek soyma kok>=5     44/48   (+3) <-- SECILEN
#      ek soyma kok>=4     40/48   (-1  -> asiri soyma tabanin ALTINA dusuyor)
#  kok>=4'un dusmesi ogretici: 'vergisi'->'verg', 'artisi'->'arti' gibi kiyimlar
#  gurultu yayiyor. v6'nin (19.08) 48->41 cokusu buyuk ihtimalle tam buydu;
#  bu kez CANLIYA YAZMADAN goruldu.
#
#  TASARIM KURALI: EN UZUN eki dene; kok $enAz'in altina duserse HIC SOYMA.
#  Ilk surum "uzun ek engellenirse kisa eke dus" diyordu ve kelime kiyiyordu
#  (cezasi->cezas, koruma->korum). Yanlis ek soymak, hic soymamaktan KOTUDUR.
#
#  ⚠️ radar-app/edge/net-cevap.ts ile BIREBIR SENKRON kalmali. Sapan biri
#  bu testi yalanci yapar.
# ---------------------------------------------------------------------------
$EKLER = @('lerinin','larinin','lerine','larina','lerini','larini','lerin','larin','leri','lari','ler','lar',
           'sinin','nin','nun','in','un','sine','sina','ine','ina','ye','ya','e','a',
           'sinde','sinda','inde','inda','de','da','te','ta',
           'sinden','sindan','inden','indan','den','dan','ten','tan',
           'siyle','iyle','yle','le','la','ligi','lugi','lik','luk','lugu',
           'si','su','i','u','mesi','masi','mek','mak','me','ma') | Sort-Object { $_.Length } -Descending
function EkSoy([string]$w, [int]$enAz = 5) {
  $x = $w
  for ($tur = 0; $tur -lt 3; $tur++) {
    $ek = $EKLER | Where-Object { $x.EndsWith($_) } | Select-Object -First 1
    if (-not $ek) { break }
    if ($x.Length - $ek.Length -lt $enAz) { break }
    $x = $x.Substring(0, $x.Length - $ek.Length)
  }
  return $x
}

function Sorgula([string]$soru) {
  $tokler = (Fold $soru) -replace '[^\w\s]',' ' -split '\s+' | Where-Object { $_.Length -ge 3 -and $STOP -notcontains $_ } | Select-Object -First 8
  # EK SOYMA, takma addan ONCE: 'sgk' zaten 3 harf, soyulmaz; boylece asagidaki
  # kurum takma adi davranisi AYNEN korunur (o ayri bir olcumdu, bozmuyoruz).
  $tokler = @($tokler | ForEach-Object { EkSoy $_ 5 } | Where-Object { $_.Length -ge 3 })
  # KURUM TAKMA ADI (edge ile AYNI): 'sgk' -> kanunun kendi dili
  $tokler = @($tokler | ForEach-Object { if ($_ -eq 'sgk') { 'sigortali','sosyal','prim' } else { $_ } }) | Select-Object -First 8
  if (-not $tokler) { return @() }
  $govde = @{ sorgu = ($tokler -join ' '); adet = 6 } | ConvertTo-Json -Compress
  # 25.08 — TEKRAR DENEME. madde_ara ARALIKLI 500 donuyor (olculdu: bir pencerede
  # 3 sorgu 500, sonraki pencerede ayni sorgu 12/12 basarili, ~300 ms). Tek atisla
  # sorulunca bu kapi kendi olcumunu kirletiyordu: bir kosuda 8 "dusen"in 5'i
  # aslinda RPC hatasiydi. Sunucu hatasi bir CEVAP DEGILDIR.
  foreach ($d in 1..4) {
    try { return @(Invoke-RestMethod -Method Post -Uri "$SB/rest/v1/rpc/madde_ara" -Headers @{ apikey = $KEY; Authorization = "Bearer $KEY" } -ContentType 'application/json' -Body $govde) }
    catch { if ($d -eq 4) { throw }; Start-Sleep -Milliseconds (700 * $d) }
  }
}

# UC DURUM, IKI DEGIL (25.08): gecti / dustu / OLCULEMEDI.
# Eskiden RPC hatasi DUSEN sayiliyordu - yani "bakamadim" ile "yanlis cevap"
# ayni kefeye giriyordu. Bu, ayni gun mevzuat.yml'de 38 gunluk yalan kirmiziya
# yol acan hatanin ta kendisi. Olcemedigine kusur deme.
$dusen = 0; $gecen = 0; $olculemeyen = 0; $olculemeyenler = @()
foreach ($v in $set.vakalar) {
  $sonuc = @()
  try { $sonuc = Sorgula $v.soru }
  catch { Write-Host "OLCULEMEDI (RPC): $($v.soru)"; $olculemeyen++; $olculemeyenler += $v.soru; continue }
  $adlar = $sonuc | ForEach-Object { Fold ([string]$_.kaynak_ad) }
  $tutan = $false
  foreach ($b in @($v.beklenen)) { if ($adlar | Where-Object { $_ -like "*$b*" }) { $tutan = $true; break } }
  if ($tutan) { $gecen++ }
  else {
    $dusen++
    Write-Host "DUSTU: '$($v.soru)'  beklenen: $($v.beklenen -join ' | ')"
    Write-Host "   top-6: $((($sonuc | ForEach-Object { $_.kaynak_ad }) | Select-Object -First 6) -join ' § ')"
  }
}
Write-Host "----------------------------------------------"
Write-Host "ALTIN TEST: $gecen gecti, $dusen dustu, $olculemeyen OLCULEMEDI / $($set.vakalar.Count) vaka"
if ($olculemeyen -gt 0) {
  Write-Host ""
  Write-Host "OLCULEMEYENLER (4 denemede de RPC hatasi - retrieval kusuru DEGIL):"
  foreach ($o in $olculemeyenler) { Write-Host "   $o" }
  Write-Host "Bunlar 'dusen' SAYILMAZ. Ama sessiz de gecilmez: madde_ara araliksiz"
  Write-Host "500 donuyorsa bu gercek kullaniciya da dusuyor demektir."
}
# KIRMIZI yalniz GERCEK retrieval kusurunda. Olculemeyen kayit kapiyi kirmizi
# yakmaz (yalan kirmizi uretir) ama yukarida GORUNUR - ucuncu durum: KOR.
if ($dusen -gt 0) { exit 1 }
if ($olculemeyen -gt 0) { exit 3 }
