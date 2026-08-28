# ============================================================================
#  SURUM TAZELIGI KAPISI — 28.08.2026 (Cem: "1 yapalim ama yilda bir cok degil mi" -> AYLIK)
#
#  NEDEN VAR: TMS 37 vakasi — ambar KAPSAMA olarak tamdi ama SURUM olarak
#  bayatti (mulga TMS 17/TFRS 4 atifli eski metin). Kapsama kapisi eksigi,
#  kurul-karari nobetcisi YENI degisikligi yakalar; ikisi de VAR OLAN kaymayi
#  yakalamaz. Bu kapi her standardi guncel KGK PDF'iyle KIYASLAR.
#
#  YONTEM: ambardaki her TMS/TFRS/TSRS standardi icin standart-yut.ps1 KURU
#  PROVASI kosulur (indirir, boler, ambar toplamiyla karsilastirir - YAZMAZ).
#  Sonuc uc renk (olcemedigine-kusur-deme kurali geregi ucuncu sonuc var):
#    TUTARLI     : parca VE karakter farki kucuk (±%2)
#    INCELE      : fark var - insan bakar (yeniden yutma adayi)
#    OLCULEMEDI  : indirme/cozme basarisiz - kusur DEGIL, olcum yok
#  BDS/GDS/KYS v1 kapsam disi (URL kalibi farkli; ayri tur).
#
#  Cikti: veri/fabrika/surum-tazeligi-karnesi.json + konsol tablosu.
#  0 USD, model yok. AYLIK zamanlanmis gorevle kosulur; elle de kosulabilir.
# ============================================================================
param([string]$yalniz='')   # 'TMS 37' ya da virgullu liste: 'TMS 1,TFRS 18'

# --- 28.08 ilk supurme dersleri ---
# OZEL YOL: KGK dosya adlari kaliptan sapabiliyor. TFRS 18 dosyasi 'TFRS 18 .pdf'
# (sonda BOSLUK); TMS 1 Kirmizi Kitap 2026'dan CIKTI (yerini TFRS 18 aldi),
# 2026'da fiilen uygulanan set MAVI Kitap'ta yasiyor - sinav mufredati o.
$OZEL_URL=@{
  'TMS 1'  ='https://www.kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TMS_TFRS_Setleri/2026/Mavi_Kitap/TMS/TMS%201.pdf'
  'TFRS 18'='https://www.kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TMS_TFRS_Setleri/2026/Kirmizi_Kitap/TFRS/TFRS%2018%20.pdf'
}
# ELLE-ZENGIN ISTISNA: bu kaynaklarda ambar, set PDF'inden DAHA guncel/zengin
# (26.08 elle islenen Temmuz 2026 kurul kararlari). Fark cikmasi MESRUDUR;
# INCELE yerine ISTISNA yazilir - yeniden yutmak GERILEME olur.
$ELLE_ZENGIN=@('TMS 28')
# TSRS'ler ayri sette (URL kalibi farkli) + 26.08 elle guncel: v1'de olcum disi.
$KAPSAM_DISI=@('TSRS 1','TSRS 2')
$ErrorActionPreference='Continue'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$kok=Split-Path -Parent $here
$KEY=[Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User')
if(-not $KEY){ $KEY=$env:SUPABASE_SERVICE_KEY }
$H=@{apikey=$KEY;Authorization="Bearer $KEY"}
$U='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar'

# --- 1) ambardaki standart listesi ---
$adlar=@{}
foreach($on in @('TMS','TFRS','TSRS')){
  $bas=0
  while($true){
    $r=@()
    # 28.08 dersi 3: %2520 CIFT kodlamaydi ('%20' literal araniyordu) - TMS 27'yi dusurdu
    try{ $r=@(Invoke-RestMethod -Uri "$U`?select=kaynak_ad&kaynak_ad=ilike.$on%20%25&limit=1000&offset=$bas" -Headers $H -UserAgent 'mevzuat-radar-robot/1.0' -TimeoutSec 120 | % { $_ }) }catch{ break }
    if($r.Count -eq 0){ break }
    foreach($x in $r){ if("$($x.kaynak_ad)" -match '^((TMS|TFRS|TSRS)\s+\d+)'){ $adlar[$Matches[1]]=$true } }
    $bas+=1000; if($r.Count -lt 1000){ break }
  }
}
$liste=@($adlar.Keys | Sort-Object { $_ -replace '\D','' -as [int] } | Sort-Object { ($_ -split ' ')[0] })
if($yalniz){ $ist=@($yalniz -split ',' | % { $_.Trim() }); $liste=@($liste | ? { $ist -contains $_ }) }
Write-Host "Standart listesi: $($liste.Count) adet"

# --- 2) her biri icin kuru prova + siniflama ---
$karne=New-Object System.Collections.Generic.List[object]
$n=0
foreach($std in $liste){
  $n++
  if($KAPSAM_DISI -contains $std){
    $karne.Add([pscustomobject]@{standart=$std;durum='ISTISNA-KAPSAM-DISI';ambar_parca=0;ambar_krk=0;yeni_parca=0;yeni_krk=0;oran=0})
    Write-Host ("  [{0}/{1}] {2,-10} ISTISNA (ayri set / elle guncel)" -f $n,$liste.Count,$std)
    continue
  }
  $cikti=''
  # 28.08 oz-sinav dersi 2: yutucu Write-Host kullaniyor -> 2>&1 yakalamaz, *>&1 gerekir
  $ekArg=@{}; if($OZEL_URL.ContainsKey($std)){ $ekArg['url']=$OZEL_URL[$std] }
  try{ $cikti=(& (Join-Path $here 'standart-yut.ps1') -standart $std @ekArg *>&1 | Out-String) }catch{ $cikti="HATA: $_" }
  $ap=0;$ak=0;$yp=0;$yk=0
  # 28.08 oz-sinav dersi: '·' ayirici yakalama sirasinda farklilasabiliyor - \D ile gevsek oku
  if($cikti -match 'AMBARDAKI HALI\D+([\d\.]+) parca\D+([\d\.]+) karakter'){ $ap=[int]($Matches[1] -replace '\.',''); $ak=[int]($Matches[2] -replace '\.','') }
  if($cikti -match 'YENI HALI\D+([\d\.]+) parca\D+([\d\.]+) karakter'){ $yp=[int]($Matches[1] -replace '\.',''); $yk=[int]($Matches[2] -replace '\.','') }
  $durum='OLCULEMEDI'; $oran=0
  if($ak -gt 0 -and $yk -gt 0){
    $oran=[math]::Round($yk/$ak,3)
    if([math]::Abs(1-$oran) -le 0.02 -and [math]::Abs($yp-$ap) -le [math]::Max(2,[int]($ap*0.05))){ $durum='TUTARLI' } else { $durum='INCELE' }
  } elseif($ak -gt 0 -and $yk -eq 0){ $durum='OLCULEMEDI' }
  if($durum -eq 'INCELE' -and $ELLE_ZENGIN -contains $std -and $oran -lt 1){ $durum='ISTISNA-ELLE-ZENGIN' }
  $karne.Add([pscustomobject]@{standart=$std;durum=$durum;ambar_parca=$ap;ambar_krk=$ak;yeni_parca=$yp;yeni_krk=$yk;oran=$oran})
  Write-Host ("  [{0}/{1}] {2,-10} {3,-11} ambar {4}p/{5}k -> yeni {6}p/{7}k (oran {8})" -f $n,$liste.Count,$std,$durum,$ap,$ak,$yp,$yk,$oran)
}

# --- 3) karne yaz (BIRLESTIREREK - 28.08 dersi 4: dar -yalniz kosusu tam
#     supurmenin kaydini EZIYORDU; envanter tek dogru sayfa olacaksa karne
#     onceki satirlari korur, yalniz kosulanlari gunceller) ---
$hedef=Join-Path $kok 'veri\fabrika\surum-tazeligi-karnesi.json'
if(Test-Path $hedef){
  try{
    $eski=Get-Content $hedef -Raw -Encoding UTF8 | ConvertFrom-Json
    $simdiki=@{}; foreach($x in $karne){ $simdiki["$($x.standart)"]=$true }
    foreach($e in @($eski.satirlar | % { $_ })){
      if(-not $simdiki["$($e.standart)"]){ $karne.Add([pscustomobject]@{standart="$($e.standart)";durum="$($e.durum)";ambar_parca=[int]$e.ambar_parca;ambar_krk=[int]$e.ambar_krk;yeni_parca=[int]$e.yeni_parca;yeni_krk=[int]$e.yeni_krk;oran=$e.oran}) }
    }
  }catch{ Write-Host "  eski karne birlestirilemedi: $_" }
}
$ozet=[ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm')
  toplam=$karne.Count
  tutarli=@($karne|?{$_.durum -eq 'TUTARLI'}).Count
  incele=@($karne|?{$_.durum -eq 'INCELE'}).Count
  olculemedi=@($karne|?{$_.durum -eq 'OLCULEMEDI'}).Count
  not='INCELE = otomatik kusur DEGIL; bolme/normalizasyon farki da olabilir - insan tek tek bakar. OLCULEMEDI = olcum yok, kusur sayilmaz (ucuncu-sonuc kurali). BDS/GDS/KYS v1 kapsam disi.'
  satirlar=$karne.ToArray()
}
$hedef=Join-Path $kok 'veri\fabrika\surum-tazeligi-karnesi.json'
[IO.File]::WriteAllText($hedef,(ConvertTo-Json -InputObject $ozet -Depth 4),[Text.UTF8Encoding]::new($false))
""
"OZET: $($ozet.toplam) standart | TUTARLI $($ozet.tutarli) | INCELE $($ozet.incele) | OLCULEMEDI $($ozet.olculemedi)"
"karne: $hedef"
if($ozet.incele -gt 0){ "INCELE listesi:"; @($karne|?{$_.durum -eq 'INCELE'}) | % { "  - $($_.standart) (oran $($_.oran))" } }
