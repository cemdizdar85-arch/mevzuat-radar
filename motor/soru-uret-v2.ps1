# ============================================================================
#  SORU URETICI v2 — 29.07.2026
#
#  Bu betik, bu gece kurulan her seyin bir araya geldigi yer:
#    KOTA      (veri/uretim-kotasi.json)  ders x konu x kurgu, 12 donem TESMER
#    BAG       kasadaki 4.101 bagli sorudan konu -> kanun maddesi haritasi
#    AMBAR     maddenin TAM METNI (madde-coz.ps1)
#    SABLON    STANDART-ACIKLAMA.md - dort parca, tuzak adlandirma, gorsel
#    KAPILAR   riskli sayi / dil / benzerlik
#
#  EN ONEMLI KARAR: uretilen soru DOGRUDAN YAYINA GIRMEZ.
#  yayin=false ile kasaya duser, profesor yargilar, GM okur, sonra acilir.
#  "Hata olsa bile yayinlanmadan yakalayalim" sarti ancak boyle karsilanir.
#  800 USD'lik ilk parti denetimsiz yayina girdigi icin bu geceyi hatalari
#  toplayarak gecirdik; ayni hatayi tekrarlamiyoruz.
#
#  KAYNAKSIZ SORU URETILMEZ: konu bir maddeye baglanamiyorsa o satir ATLANIR
#  ve rapora yazilir. Model hafizasindan soru yazmasin - bu gece bulunan uc
#  gercek hatanin ucu de "model hatirladigindan yazmis" tipiydi.
# ============================================================================
param(
  [switch]$calistir,
  [int]$sinir = 200,
  [string]$ders = '',
  [string]$model = 'claude-sonnet-4-5-20250929',
  [string]$cikti = ''
)
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$SB_URL = "https://bjrleanjpyujtajmazxn.supabase.co"
try { Start-Transcript -Path (Join-Path $kok 'veri/uretim-log.txt') -Force | Out-Null } catch {}

$KEY = $env:SUPABASE_SERVICE_KEY
if(-not $KEY){ Write-Host "SUPABASE_SERVICE_KEY yok."; exit 1 }
$AK = "$env:ANTHROPIC_API_KEY".Trim()
$H  = @{ apikey=$KEY; Authorization="Bearer $KEY" }
$HW = $H + @{ Prefer="return=minimal" }
$HDR = @{ 'x-api-key'=$AK; 'anthropic-version'='2023-06-01' }
. (Join-Path $here 'madde-coz.ps1') -kutuphane

# --- kota
$kota = Get-Content (Join-Path $kok "veri/uretim-kotasi.json") -Raw -Encoding UTF8 | ConvertFrom-Json
$plan = @($kota.plan)
if($ders){ $plan = @($plan | Where-Object { "$($_.ders)" -eq $ders }) }
Write-Host ("Kota satiri: {0}" -f $plan.Count)

# --- kasadan KONU -> MADDE haritasi (4.101 bagli soru zaten var, bedava kaynak)
Write-Host "Kasa okunuyor (konu -> madde haritasi + benzerlik icin soru metinleri)..."
$kasa = New-Object System.Collections.Generic.List[object]
$bas = 0
while($true){
  $s = Invoke-RestMethod -Uri "$SB_URL/rest/v1/soru_havuzu?select=id,ders,konu,soru,kanun_no,madde_no&order=id&offset=$bas&limit=1000" -Headers $H -TimeoutSec 180
  $d = @($s); if($d.Count -eq 0){ break }
  foreach($x in $d){ $kasa.Add($x) }
  if($d.Count -lt 1000){ break }
  $bas += 1000
}
Write-Host ("  kasa: {0} soru" -f $kasa.Count)

function Kel([string]$t){
  $l=@(); foreach($w in (("$t".ToLowerInvariant() -replace '[ıİ]','i' -replace '[şŞ]','s' -replace '[ğĞ]','g' -replace '[üÜ]','u' -replace '[öÖ]','o' -replace '[çÇ]','c') -split '[^a-z0-9]+')){ if($w.Length -ge 4){ $l += $w } }
  return $l
}
# kelime -> (kanun,madde) adaylari
$kelMadde=@{}
foreach($k in $kasa){
  if(-not $k.kanun_no -or -not $k.madde_no){ continue }
  if("$($k.kanun_no)" -in @('STD','THP')){ continue }
  foreach($w in (Kel "$($k.konu)")){
    if(-not $kelMadde.ContainsKey($w)){ $kelMadde[$w]=@{} }
    $anahtar = "$($k.kanun_no)|$($k.madde_no)"
    $kelMadde[$w][$anahtar] = 1 + [int]$kelMadde[$w][$anahtar]
  }
}
Write-Host ("  konu-kelime indeksi: {0} kelime" -f $kelMadde.Count)

function MaddeBul([string]$konu){
  $sayac=@{}
  foreach($w in (Kel $konu)){
    if(-not $kelMadde.ContainsKey($w)){ continue }
    foreach($p in $kelMadde[$w].GetEnumerator()){ $sayac[$p.Key] = [int]$sayac[$p.Key] + $p.Value }
  }
  if($sayac.Count -eq 0){ return $null }
  $en = ($sayac.GetEnumerator() | Sort-Object {-$_.Value} | Select-Object -First 1)
  return $en.Key
}

# --- mevcut soru metinleri (benzerlik kapisi icin)
$mevcutKok=@{}
foreach($k in $kasa){ $mevcutKok[((Kel "$($k.soru)") -join ' ')] = 1 }

function IstemKur($ders,$konu,$kurgu,$uzun,$maddeAd,$maddeMetni){
  $gorsel = ''
  if($ders -in @('Finansal Muhasebe','Maliyet Muhasebesi','Mali Tablolar Analizi','Finansal Tablolar ve Analizi')){
    $gorsel = @"

GORSEL: soru KAYIT tipindeyse "yevmiye" alanini doldur
  [{"hesap":"100 KASA","borc":5000,"alacak":0},{"hesap":"600 YURTICI SATISLAR","borc":0,"alacak":5000}]
Soru TABLO/ANALIZ tipindeyse "tablo" alanini doldur
  {"baslik":"Gelir Tablosu (TL)","kolonlar":["Kalem","Tutar"],"satirlar":[["Brut Satislar","100.000"],["Brut Kar <-","40.000"]]}
Gerekmiyorsa bos birak. UYDURMA TABLO, TABLOSUZLUKTAN KOTUDUR.
"@
  }
  return @"
Sen TURMOB-TESMER SMMM YETERLILIK sinavi icin soru yazan bir editorsun.

=== DAYANAK METIN ($maddeAd) ===
$maddeMetni
=== METIN BITTI ===

YAZILACAK SORU:
  Ders   : $ders
  Konu   : $konu
  Kurgu  : $kurgu   (bilgi=duz bilgi/tanim · hesap=rakamli hesaplama · vaka=olay anlatilip hukum sorulur · kayit=yevmiye/muhasebelestirme · karsilastir=iki kavramin farki)
  Uzunluk: $uzun    (kisa=tek cumle · orta · uzun=paragraf/vaka metni)

MUTLAK KURALLAR:
1. Soru YALNIZCA yukaridaki dayanak metne dayanacak. Metinde YAZMAYAN hicbir rakam, oran, sure ya da esik kullanma - ne soruda ne aciklamada. Emin degilsen sayi verme.
2. BES sik (A-E), TAM OLARAK BIRI dogru. Digerleri makul ama acikca yanlis olmali - "neredeyse dogru" sik yazma.
3. Cikmis sinav sorusu KOPYALAMA. Ozgun yaz.
4. Istenen KURGUYA sadik kal. "bilgi" istendiyse hesap sorusu yazma.

ACIKLAMA SABLONU - dogru sik icin DORT PARCA, bu basliklarla:
Ne soruluyor: <tek cumle, hic muhasebe bilmeyene>
Kural: <maddeye dayali, gunluk dille>
Bu olayda: <kuralin uygulanisi, adim adim>
Akilda kalsin: <tek cumle>
400-700 karakter.

YANLIS SIKLARDA TEK IS: tuzagi adlandirmak. "Bu sik X ile Y'yi karistiriyor. X sudur; Y ise budur." 120-250 karakter.

DIL: cumle ortalama 20 kelimeyi gecmesin, tek cumle 30'u asmasin. Teknik terimi ilk kullandiginda parantezle acikla. Edilgen degil etken yaz.
$gorsel
SADECE gecerli JSON dondur:
{"soru":"...","siklar":{"A":"...","B":"...","C":"...","D":"...","E":"..."},"dogru":"A","aciklama":{"A":"...","B":"...","C":"...","D":"...","E":"..."},"hap":"...","yevmiye":[],"tablo":null}
"@
}

# --- kurgu dagilimindan tip sec (deterministik: sirayla dagit)
$dersKurgu=@{}
foreach($o in $kota.ozet){
  $l=@()
  foreach($par in ("$($o.kurgu)" -split ' · ')){
    if($par -match '^(\S+)\s+%(\d+)$'){ for($i=0;$i -lt [int]$Matches[2];$i++){ $l += $Matches[1] } }
  }
  if($l.Count -eq 0){ $l = @('bilgi') }
  $dersKurgu["$($o.ders)"] = $l
}

# --- isler
$isler = New-Object System.Collections.Generic.List[object]
$ist=[ordered]@{ planSatir=0; maddesiz=0; metinsiz=0; hazir=0 }
$sayac=@{}
foreach($p in $plan){
  if($isler.Count -ge $sinir){ break }
  $ist.planSatir++
  $anahtar = MaddeBul "$($p.konu)"
  if(-not $anahtar){ $ist.maddesiz++; continue }
  $par = $anahtar -split '\|'
  $seri=''; $mn="$($par[1])"
  if($mn -match '^(gec|ek|muk)(\d+)$'){ $seri=$Matches[1]; $mn=$Matches[2] }
  $m = MaddeMetni "$($par[0])" $mn $seri
  if(-not $m -or -not $m.metin){ $ist.metinsiz++; continue }
  $metin = "$($m.metin)"; if($metin.Length -gt 6000){ $metin = $metin.Substring(0,6000) }

  $adet = [Math]::Min([int]$p.adet, $sinir - $isler.Count)
  $kl = $dersKurgu["$($p.ders)"]; if(-not $kl){ $kl=@('bilgi') }
  for($i=0; $i -lt $adet; $i++){
    if($isler.Count -ge $sinir){ break }
    $n = [int]$sayac["$($p.ders)"]; $sayac["$($p.ders)"] = $n + 1
    $kurgu = $kl[$n % $kl.Count]
    $uzun = @('orta','kisa','orta','uzun')[$n % 4]
    $isler.Add([pscustomobject]@{
      ders="$($p.ders)"; konu="$($p.konu)"; kurgu=$kurgu; uzun=$uzun
      kanun=$par[0]; madde=$par[1]; maddeAd="$($m.ad)"
      istem=(IstemKur "$($p.ders)" "$($p.konu)" $kurgu $uzun "$($m.ad)" $metin)
      metin=$metin
    })
    $ist.hazir++
  }
}
Write-Host ""
foreach($k in $ist.Keys){ Write-Host ("  {0,-12} {1}" -f $k, $ist[$k]) }
$gk=0; foreach($i in $isler){ $gk += $i.istem.Length }
$tahmin = ((([math]::Round($gk/3))/1e6*3.0) + (($isler.Count*1400)/1e6*15.0))/2
Write-Host ("MALIYET TAHMINI (Batch %50): ~{0:N2} USD" -f $tahmin)
if(-not $calistir){ Write-Host "OLCUM MODU - 0 USD."; try{Stop-Transcript|Out-Null}catch{}; exit 0 }
if(-not $AK){ Write-Host "ANTHROPIC_API_KEY yok."; exit 1 }
if($isler.Count -eq 0){ Write-Host "KIRMIZI: uretilecek is yok."; exit 1 }

# --- batch
$sonuc=@{}; $gG=0; $gC=0
$PARTI=200
for($p2=0; $p2 -lt [math]::Ceiling($isler.Count/$PARTI); $p2++){
  $dilim=@($isler[($p2*$PARTI)..([math]::Min(($p2+1)*$PARTI-1,$isler.Count-1))])
  $req=@(); $ix=0
  foreach($i in $dilim){ $req += @{ custom_id=("u{0}_{1}" -f $p2,$ix); params=@{ model=$model; max_tokens=2500; messages=@(@{role='user';content=$i.istem}) } }; $ix++ }
  $govde=@{requests=$req}|ConvertTo-Json -Depth 8
  Write-Host ("PARTI {0}: {1} soru" -f ($p2+1), $dilim.Count)
  $b = Invoke-RestMethod -Method Post -Uri 'https://api.anthropic.com/v1/messages/batches' -Headers $HDR -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($govde))
  $tur=0
  while($true){ Start-Sleep -Seconds 20; $tur++
    $st = Invoke-RestMethod -Uri "https://api.anthropic.com/v1/messages/batches/$($b.id)" -Headers $HDR
    if($st.processing_status -eq 'ended'){ break }
    if($tur -ge 90){ Write-Host "  ZAMAN ASIMI"; break } }
  $adres = if($st.results_url){ "$($st.results_url)" } else { "https://api.anthropic.com/v1/messages/batches/$($b.id)/results" }
  $cev = Invoke-WebRequest -UseBasicParsing -Uri $adres -Headers $HDR -TimeoutSec 300
  $mt2 = if($cev.Content -is [byte[]]){ [Text.Encoding]::UTF8.GetString($cev.Content) } else { "$($cev.Content)" }
  foreach($sat in ($mt2 -split "`r?`n")){
    if("$sat".Trim().Length -eq 0){ continue }
    try { $r = $sat | ConvertFrom-Json } catch { continue }
    if("$($r.result.type)" -ne 'succeeded'){ continue }
    $gG += [int]"$($r.result.message.usage.input_tokens)"; $gC += [int]"$($r.result.message.usage.output_tokens)"
    $jm=[regex]::Match("$($r.result.message.content[0].text)", '\{[\s\S]*\}')
    if(-not $jm.Success){ continue }
    try { $sonuc["$($r.custom_id)"] = ($jm.Value | ConvertFrom-Json) } catch {}
  }
}

# --- KAPILAR + yazma
function SayiListe([string]$t){ $l=@(); foreach($m in [regex]::Matches("$t",'\d[\d\.\,]*')){ $l += $m.Value.TrimEnd('.',',') }; return $l }
$YAZI=[ordered]@{ 'bir'=1;'iki'=2;'uc'=3;'üç'=3;'dort'=4;'dört'=4;'bes'=5;'beş'=5;'alti'=6;'altı'=6;'yedi'=7;'sekiz'=8;'dokuz'=9;'on'=10;'yirmi'=20;'otuz'=30;'elli'=50 }
function Riskli([string]$t){
  $l=@()
  foreach($k in $YAZI.Keys){ foreach($m in [regex]::Matches("$t","(?i)\b$k\s+(g[uü]n|ay|y[iı]l|hafta|kez|defa|kat)\b")){ $l += "$($YAZI[$k])" } }
  foreach($m in [regex]::Matches("$t",'%\s*(\d[\d\.,]*)')){ $l += $m.Groups[1].Value.TrimEnd('.',',') }
  foreach($m in [regex]::Matches("$t",'(\d[\d\.,]*)\s*%')){ $l += $m.Groups[1].Value.TrimEnd('.',',') }
  foreach($m in [regex]::Matches("$t","(?i)(\d+)\s*(g[uü]n|ay|y[iı]l|hafta)\b")){ $l += $m.Groups[1].Value }
  return $l
}
$ozet=[ordered]@{ uretilen=0; rakamRed=0; dilRed=0; sikRed=0; benzerRed=0; cevapsiz=0; yazmaHatasi=0 }
$red = New-Object System.Collections.Generic.List[object]
$yeni = New-Object System.Collections.Generic.List[object]
for($p2=0; $p2 -lt [math]::Ceiling($isler.Count/$PARTI); $p2++){
  for($ix=0; $ix -lt $PARTI; $ix++){
    $gi = $p2*$PARTI + $ix
    if($gi -ge $isler.Count){ break }
    $i = $isler[$gi]
    $y = $sonuc[("u{0}_{1}" -f $p2,$ix)]
    if(-not $y -or -not $y.soru -or -not $y.siklar){ $ozet.cevapsiz++; continue }
    # sik kapisi
    $dolu=0; foreach($h in @('A','B','C','D','E')){ if("$($y.siklar.$h)".Trim().Length -gt 2){ $dolu++ } }
    if($dolu -ne 5 -or "$($y.dogru)" -notin @('A','B','C','D','E')){ $ozet.sikRed++; continue }
    if("$($y.aciklama.$($y.dogru))".Trim().Length -lt 300){ $ozet.sikRed++; continue }
    # rakam kapisi
    $tumMetin = "$($y.soru)"; foreach($h in @('A','B','C','D','E')){ $tumMetin += " $($y.siklar.$h) $($y.aciklama.$h)" }
    $kaynakSay=@{}; foreach($n in (SayiListe $i.metin)){ $kaynakSay[$n]=1 }
    $kaynakRisk=@{}; foreach($n in (Riskli $i.metin)){ $kaynakRisk[$n]=1 }
    $uyd=@()
    foreach($n in (Riskli $tumMetin)){ if(-not $kaynakRisk.ContainsKey($n) -and -not $kaynakSay.ContainsKey($n)){ $uyd += $n } }
    if($uyd.Count){ $ozet.rakamRed++; $red.Add([pscustomobject]@{ konu=$i.konu; sebep='riskli-sayi'; deger=($uyd -join ',') }); continue }
    # dil kapisi
    $cum=@(($tumMetin -split '(?<=[.!?:])\s+') | Where-Object { $_.Trim().Length -gt 3 })
    $kel=@(); $enU=0; foreach($c in $cum){ $k2=@($c -split '\s+' | Where-Object{$_}).Count; $kel+=$k2; if($k2 -gt $enU){$enU=$k2} }
    $ort = if($kel.Count){ ($kel|Measure-Object -Average).Average } else { 0 }
    if($ort -gt 20 -or $enU -gt 30){ $ozet.dilRed++; $red.Add([pscustomobject]@{ konu=$i.konu; sebep='dil'; deger=("ort {0:N1} enuzun {1}" -f $ort,$enU) }); continue }
    # benzerlik kapisi
    $kokAn = ((Kel "$($y.soru)") -join ' ')
    if($mevcutKok.ContainsKey($kokAn)){ $ozet.benzerRed++; continue }
    $mevcutKok[$kokAn]=1

    $id = [guid]::NewGuid().ToString()
    $satir=[ordered]@{
      id=$id; sinav='SMMM'; ders=$i.ders; konu=$i.konu
      soru="$($y.soru)"; siklar=$y.siklar; dogru="$($y.dogru)"; aciklama=$y.aciklama
      hap="$($y.hap)"; kaynak=$i.maddeAd; uretim=("kota-v2 " + (Get-Date -Format 'dd.MM.yyyy'))
      kanun_no=$i.kanun; madde_no=$i.madde
      yayin=$false
      yayin_notu='YENI URETIM - profesor denetimi ve GM okumasi bekliyor. Denetlenmeden yayina cikmaz.'
    }
    if($y.yevmiye -and @($y.yevmiye).Count){ $satir['yevmiye']=$y.yevmiye }
    elseif($y.tablo -and $y.tablo.satirlar -and @($y.tablo.satirlar).Count){ $satir['tablo']=$y.tablo }
    $yeni.Add($satir)
  }
}

# --- kasaya yaz (150'lik partiler)
for($i2=0; $i2 -lt $yeni.Count; $i2 += 150){
  $dl = @($yeni[$i2..([Math]::Min($i2+149,$yeni.Count-1))])
  try {
    Invoke-RestMethod -Method Post -Uri "$SB_URL/rest/v1/soru_havuzu" -Headers $HW -ContentType "application/json; charset=utf-8" `
      -Body ([Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject $dl -Depth 6))) -TimeoutSec 120 | Out-Null
    $ozet.uretilen += $dl.Count
  } catch { $ozet.yazmaHatasi += $dl.Count; Write-Host ("YAZMA HATASI: {0}" -f $_.Exception.Message) }
}

$gercek = (($gG/1e6*3.0)+($gC/1e6*15.0))/2
Write-Host ""
Write-Host "======== URETIM ========"
foreach($k in $ozet.Keys){ Write-Host ("  {0,-14} {1}" -f $k, $ozet[$k]) }
Write-Host ("  GERCEK FATURA: ~{0:N2} USD" -f $gercek)
Write-Host "  NOT: uretilen sorularin HEPSI yayin=false. Profesor + GM onayi olmadan ogrenciye gitmez."
$yol = if($cikti){ $cikti } else { Join-Path $kok 'veri/uretim-rapor.json' }
[IO.File]::WriteAllText($yol, ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); model=$model; hazirlik=$ist; ozet=$ozet
  fatura=[ordered]@{ giris=$gG; cikis=$gC; usd=[math]::Round($gercek,2) }
  redler=@($red | Select-Object -First 60)
} | ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding($false)))
Write-Host ("-> {0}" -f $yol)
try{Stop-Transcript|Out-Null}catch{}
exit 0
