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
  # CESITLILIK TAVANI icin genis havuz iste (30), elemeden sonra ilk 6 kullanilir.
  # edge/net-cevap.ts de zaten adet=30 cekip ayni elemeyi yapiyor - SENKRON.
  $govde = @{ sorgu = ($tokler -join ' '); adet = 30 } | ConvertTo-Json -Compress
  # 25.08 — TEKRAR DENEME. madde_ara ARALIKLI 500 donuyor (olculdu: bir pencerede
  # 3 sorgu 500, sonraki pencerede ayni sorgu 12/12 basarili, ~300 ms). Tek atisla
  # sorulunca bu kapi kendi olcumunu kirletiyordu: bir kosuda 8 "dusen"in 5'i
  # aslinda RPC hatasiydi. Sunucu hatasi bir CEVAP DEGILDIR.
  $havuz = $null
  foreach ($d in 1..4) {
    try { $havuz = @(Invoke-RestMethod -Method Post -Uri "$SB/rest/v1/rpc/madde_ara" -Headers @{ apikey = $KEY; Authorization = "Bearer $KEY" } -ContentType 'application/json' -Body $govde); break }
    catch { if ($d -eq 4) { throw }; Start-Sleep -Milliseconds (700 * $d) }
  }
  # --- CESITLILIK TAVANI (25.08, olculdu: 44 -> 45/48) ---
  # Ayni MADDEDEN en fazla 1, ayni BELGEDEN en fazla 2 parca. "tapu harci alim
  # satim" sorgusunda top-6'nin 4'u ayni belgenin (Harclar GT 56 ek m.12) farkli
  # parcalariydi; Harclar Kanunu'nun kendisi hic gorunmuyordu.
  # edge/net-cevap.ts icindeki eleme ile BIREBIR AYNI olmali.
  # DUZLESTIRME SART (25.08 canli yasandi): $havuz tek elemanli cikip o eleman
  # 30'luk dizi olabiliyordu. O halde `foreach` BIR kez donuyor, `$ust += $d`
  # bir dizi ekledigi icin CONCAT yapiyor ve 30 kaydin hepsi listeye giriyor.
  # Sonuc iki katli yalan: (1) tavan hic calismiyor, (2) test top-6 yerine
  # top-30'a bakip skoru SISIRIYOR (44 -> sahte 47). ArrayList + duzlestirme
  # ikisini de kapatir. Ayni `+=` tuzagi arac/sirala-tarti.ps1'de de yasanmisti.
  $havuz = @($havuz | ForEach-Object { $_ })
  $ust = New-Object System.Collections.ArrayList
  $mSay = @{}; $bSay = @{}
  foreach ($d in $havuz) {
    $ad = [string]$d.kaynak_ad
    if (-not $ad) { continue }
    $mk = ($ad -replace '\s*\[\d+/\d+\]\s*$','').Trim()
    $bk = [regex]::Replace($mk, '\s+((gec\.|muk\.|mük\.|ek|mükerrer)\s+)?m\.\s*\d.*$', '')
    $bk = [regex]::Replace($bk, '\s+(bolum|bölüm)\s+\d.*$', '', 'IgnoreCase').Trim()
    if ([int]$mSay[$mk] -ge 1) { continue }
    if ([int]$bSay[$bk] -ge 2) { continue }
    $mSay[$mk] = [int]$mSay[$mk] + 1; $bSay[$bk] = [int]$bSay[$bk] + 1
    [void]$ust.Add($d)
    if ($ust.Count -ge 6) { break }
  }
  if ($env:TARTI_HATA_AYIKLA) { Write-Host ("      [ayikla] havuz=$($havuz.Count) ust=$($ust.Count) sorgu='$($tokler -join ' ')'") }
  return @($ust)
}

# UC DURUM, IKI DEGIL (25.08): gecti / dustu / OLCULEMEDI.
# Eskiden RPC hatasi DUSEN sayiliyordu - yani "bakamadim" ile "yanlis cevap"
# ayni kefeye giriyordu. Bu, ayni gun mevzuat.yml'de 38 gunluk yalan kirmiziya
# yol acan hatanin ta kendisi. Olcemedigine kusur deme.
# ---------------------------------------------------------------------------
#  IKI DUZEY (25.08): KAYNAK ve MADDE
#  'beklenen' KAYNAK duzeyindedir: "vuk (213" gecen HERHANGI bir VUK maddesi
#  vakayi gecirir. Bu GEVSEK ve olculdu: 'anayasaya gore vergi odevi'
#  sorgusunda donen madde m.73 degil m.72 oldugu halde vaka GECIYORDU. Yani
#  45/48 rakami gercek kaliteden IYIMSER.
#  'beklenen_madde' dolu olan vakalarda ayrica MADDE duzeyi olculur. Alan,
#  yalniz maddenin METNI AMBARDAN OKUNUP TEYIT EDILDIGI vakalarda doldurulur
#  (ezberden yazilmaz - [[feedback-rakam-disiplini]] ile ayni disiplin).
#  Bos birakilan vaka madde duzeyinde SAYILMAZ; test haksiz kirmizi yakmaz.
#  Madde esleme SINIR-DUYARLI: "m.5" kalibi "m.53"e YANLIS eslesmesin diye
#  desenin ardindan bosluk, '[' ya da satir sonu aranir.
# ---------------------------------------------------------------------------
function MaddeTutar([string]$ad, [string]$beklenen) {
  return [regex]::IsMatch($ad, [regex]::Escape($beklenen) + '(\s|\[|$)')
}

$dusen = 0; $gecen = 0; $olculemeyen = 0; $olculemeyenler = @()
$mAdet = 0; $mGecen = 0; $mDusen = @()
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
  # --- MADDE DUZEYI (yalniz beklenen_madde dolu vakalarda) ---
  if ($v.beklenen_madde) {
    $mAdet++
    $bm = Fold ([string]$v.beklenen_madde)
    $mTuttu = $false
    foreach ($a in $adlar) { if (MaddeTutar $a $bm) { $mTuttu = $true; break } }
    if ($mTuttu) { $mGecen++ }
    else { $mDusen += ("{0}  -> beklenen madde: {1}" -f $v.soru, $v.beklenen_madde) }
  }
}
# ===========================================================================
#  KABUL SARTLARI — SQL DOSYALARININ DIBINDEN BURAYA TASINDI (25.08.2026)
#
#  NEDEN. 17.07'de madde_ara v5 yazildi ve dosyasinin dibine kabul sorgusu
#  konuldu: madde_ara('anayasaya gore vergi odevi nedir') -> Anayasa m.73.
#  O sorgu bir SQL dosyasinin icinde YORUM olarak kaldi; kimse kosturmadi.
#  30.07 yeniden yaziminda v5'in dar aday havuzu DUSTU, kabul sarti da
#  sessizce ihlal edildi ve 5 HAFTA kimse gormedi. 25.08'de ayni hata koduyla
#  (57014 statement timeout) geri geldi ve elle bulundu.
#  DERS: bir kabul sarti KOSTURULMUYORSA sart degildir, dilektir.
#  Bundan sonra her madde_ara surumunun kabul sarti BURAYA yazilir.
#
#  Bu blok RETRIEVAL kusuru olcmez, YAPISAL sozlesme olcer; o yuzden ayri
#  raporlanir ve ayri cikis kodu uretir.
# ===========================================================================
$kabulDusen = @()
# (1) CIKMIS SINAV SIZINTISI — v6/v7/v8 sozlesmesi: 'cikmis%' turu ASLA donmez.
#     Bu belgeler tek satirda on binlerce karakter tasir ve FTS'i kazanir;
#     sizarsa Net Cevap kanun yerine sinav kagidi alintilar.
try {
  $s1 = Sorgula 'yevmiye kaydi kurum kazanci kanunen kabul edilmeyen gider'
  $sz = @($s1 | Where-Object { "$($_.tur)" -like 'cikmis*' }).Count
  if ($sz -gt 0) { $kabulDusen += "cikmis% sizintisi: $sz kayit (beklenen 0)" }
} catch { $kabulDusen += "cikmis% sizinti sinavi OLCULEMEDI (RPC)" }

Write-Host "----------------------------------------------"
Write-Host "ALTIN TEST: $gecen gecti, $dusen dustu, $olculemeyen OLCULEMEDI / $($set.vakalar.Count) vaka"
if ($mAdet -gt 0) {
  Write-Host "MADDE DUZEYI: $mGecen/$mAdet  (yalniz metni okunup teyit edilmis vakalar)"
  foreach ($m in $mDusen) { Write-Host "   madde-dusen: $m" }
}
if ($kabulDusen.Count -gt 0) {
  Write-Host ""
  Write-Host "KABUL SARTI IHLALI (yapisal sozlesme):"
  foreach ($k in $kabulDusen) { Write-Host "   $k" }
}
if ($olculemeyen -gt 0) {
  Write-Host ""
  Write-Host "OLCULEMEYENLER (4 denemede de RPC hatasi - retrieval kusuru DEGIL):"
  foreach ($o in $olculemeyenler) { Write-Host "   $o" }
  Write-Host "Bunlar 'dusen' SAYILMAZ. Ama sessiz de gecilmez: madde_ara araliksiz"
  Write-Host "500 donuyorsa bu gercek kullaniciya da dusuyor demektir."
}
# KIRMIZI yalniz GERCEK kusurda. Olculemeyen kayit kapiyi kirmizi yakmaz
# (yalan kirmizi uretir) ama yukarida GORUNUR - ucuncu durum: KOR.
# Kabul sarti ihlali de KIRMIZI: yapisal sozlesme bozulmus demektir ve 25.08'de
# tam bunun gorunmemesi 5 haftalik regresyona yol acti.
if ($kabulDusen.Count -gt 0) { exit 1 }
if ($dusen -gt 0) { exit 1 }
if ($olculemeyen -gt 0) { exit 3 }
