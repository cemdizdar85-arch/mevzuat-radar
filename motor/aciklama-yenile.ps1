# ============================================================================
#  ACIKLAMA YENILEME — 29.07.2026
#
#  NIYE: olcum yapildi. Aciklamalarimizin ortalamasi 162 KARAKTER, yani iki
#  cumle. O uzunlukta "bu sik yanlis cunku..." denir; KONU OGRETILMEZ. Cem'in
#  hedefi "kitabi ezberlemeden, soru cozerek konuyu ogretmek" - bu boyda olmaz.
#  Her sikka ayri aciklama zaten %100 var (iyi); eksik olan DERINLIK.
#
#  NE DEGISIR, NE DEGISMEZ:
#    DEGISIR : aciklama (her sik), hap
#    ASLA DEGISMEZ : soru metni, siklar, dogru cevap, kaynak
#  Aciklamayi zenginlestirmek icin sorunun kendisine dokunmak, yeni soru
#  uretmektir - bu kanaldan gecmez.
#
#  SABLON (dogru sik):
#    1) Ne soruluyor  - tek cumle, hic muhasebe bilmeyene
#    2) Kural         - maddeye dayali ama gunluk dille
#    3) Bu olayda     - kuralin soruya uygulanisi, adim adim
#    4) Akilda kalsin - tek cumlelik hap
#  Yanlis siklarda tek is: TUZAGI ADLANDIRMAK. "Yanlis" demek ogretmez;
#  "bu sik X ile Y'yi karistiriyor" ogretir. Sinavda kaybettiren sey bilgi
#  eksigi degil, karistirmadir.
#
#  RAKAM KAPISI (bu betigin asil sigortasi):
#  Yeni aciklamada gecen HER SAYI, kaynak metinde (madde metni + soru + siklar)
#  gecmek ZORUNDA. Gecmiyorsa o sorunun yenilemesi COPE ATILIR ve eski aciklama
#  KALIR. Bu gece bulunan uc gercek hatanin ucu de uydurulmus RAKAM/SUREYDI
#  (SGK %20 yerine %21, AATUHK 7 gun yerine 15, 3568 alikoyma suresi).
#  Aciklamayi zenginlestirirken ayni hatayi UretMEK, hic zenginlestirmemekten
#  kotudur.
# ============================================================================
param(
  [switch]$calistir,
  [string]$ders = '',        # yalniz bu ders (bos = hepsi)
  [int]$sinir = 0,           # kac soru (0 = hepsi)
  [string]$model = 'claude-sonnet-4-5-20250929',
  [string]$cikti = '',
  [switch]$hapTamir    # PARA HARCAMAZ: bos kalan hap'i aciklamadan turetir
)
$ErrorActionPreference = "Stop"
# Supabase gizli anahtarli istegi KIMLIKSIZ gelirse 401 ile reddeder.
# (16.08.2026 olculdu: ayni sorgu UA'siz 401, UA'li 5 kayit. madde-coz.ps1
#  bu yuzden her kaynaga "ambarda-yok" diyordu.) IRM ve IWR AYRI yazilir.
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$PSDefaultParameterValues['Invoke-WebRequest:UserAgent'] = 'mevzuat-radar-robot/1.0'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$SB_URL = "https://bjrleanjpyujtajmazxn.supabase.co"

$LOG = Join-Path $kok 'veri/aciklama-log.txt'
try { Start-Transcript -Path $LOG -Force | Out-Null } catch {}

$KEY = $env:SUPABASE_SERVICE_KEY
if(-not $KEY){ Write-Host "SUPABASE_SERVICE_KEY yok."; exit 1 }
$AK = "$env:ANTHROPIC_API_KEY".Trim()
$H  = @{ apikey=$KEY; Authorization="Bearer $KEY" }
$HW = $H + @{ Prefer="return=minimal" }
$HDR = @{ 'x-api-key'=$AK; 'anthropic-version'='2023-06-01' }

. (Join-Path $here 'madde-coz.ps1') -kutuphane

# --- sorulari cek
$u = "$SB_URL/rest/v1/soru_havuzu?select=id,sinav,ders,konu,soru,siklar,dogru,aciklama,hap,kaynak,kanun_no,madde_no&order=id"
if($ders){ $u += "&ders=eq." + [uri]::EscapeDataString($ders) }
$sorular = New-Object System.Collections.Generic.List[object]
$bas = 0
while($true){
  $s = Invoke-RestMethod -Uri "$u&offset=$bas&limit=500" -Headers $H -TimeoutSec 180
  $d = @($s); if($d.Count -eq 0){ break }
  foreach($x in $d){ $sorular.Add($x) }
  if($d.Count -lt 500){ break }
  $bas += 500
}
Write-Host ("Soru: {0}{1}" -f $sorular.Count, $(if($ders){" (ders: $ders)"}else{""}))
if($sorular.Count -eq 0){ Write-Host "KIRMIZI: soru okunamadi."; try{Stop-Transcript|Out-Null}catch{}; exit 1 }

# ---------------------------------------------------------------- HAP TAMIRI
# PARA HARCAMAZ. Yenileme sirasinda model bazen 'hap' alanini bos donduruyor ve
# eski hap USTUNE BOS YAZILIYORDU (ornek dokumunde 4 sorunun 1'inde yakalandi).
# Iyilestirme adi altinda veri silmek kabul edilemez. Neyse ki bilgi kaybolmadi:
# dort parcali aciklamanin son satiri zaten "Akilda kalsin: ..." - hap oradan
# BIREBIR turetilebilir. Modele tekrar sormaya, yani ayni isi ikinci kez odemeye
# gerek yok.
if($hapTamir){
  $t=[ordered]@{ bakilan=0; bosBulunan=0; onarilan=0; turetilemeyen=0; hata=0 }
  foreach($s in $sorular){
    $t.bakilan++
    if("$($s.hap)".Trim().Length -ge 5){ continue }
    $t.bosBulunan++
    $ak = [regex]::Match("$($s.aciklama.$($s.dogru))", '(?is)Ak[ıi]lda\s+kals[ıi]n\s*:\s*(.+?)\s*$')
    if(-not $ak.Success){ $t.turetilemeyen++; continue }
    $yeni = $ak.Groups[1].Value.Trim()
    if($yeni.Length -lt 5 -or $yeni.Length -gt 300){ $t.turetilemeyen++; continue }
    try {
      Invoke-RestMethod -Method Patch -Uri "$SB_URL/rest/v1/soru_havuzu?id=eq.$($s.id)" -Headers $HW `
        -ContentType "application/json; charset=utf-8" -Body ([Text.Encoding]::UTF8.GetBytes((@{hap=$yeni}|ConvertTo-Json -Compress))) -TimeoutSec 60 | Out-Null
      $t.onarilan++
    } catch { $t.hata++ }
  }
  Write-Host ""
  Write-Host "======== HAP TAMIRI (0 USD) ========"
  foreach($k in $t.Keys){ Write-Host ("  {0,-16} {1}" -f $k, $t[$k]) }
  [IO.File]::WriteAllText((Join-Path $kok 'veri/hap-tamir.json'), ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); ozet=$t } | ConvertTo-Json -Depth 4), (New-Object Text.UTF8Encoding($false)))
  Write-Host "-> veri/hap-tamir.json"
  try{Stop-Transcript|Out-Null}catch{}
  exit 0
}

# Muhasebe ailesi derslerde GORSEL ZORUNLU. Site tabloyu ve yevmiyeyi ZATEN
# ciziyor (Cem'in 24.07 fikri: exhibit tablosu + yevmiye + 'hayalet kayit') ama
# veri bostu: 581 soruluk olcumde tablo %0, yevmiye %4. Muhasebede bir kaydi
# lafla anlatmak, cizmemekle ayni sey degil.
$GORSELLI_DERS = @('Finansal Muhasebe','Maliyet Muhasebesi','Mali Tablolar Analizi','Finansal Tablolar ve Analizi','Muhasebe Denetimi')

function IstemKur($s, $maddeMetni){
  $gorsel = ''; $gorselAlan = ''
  if($GORSELLI_DERS -contains "$($s.ders)"){
    $gorsel = @"

GORSEL (bu ders icin ZORUNLU, konu elveriyorsa):
- Soru bir KAYIT sorusuysa "yevmiye" alanini doldur: dogru yevmiye maddesi.
  Bicim: [{"hesap":"100 KASA","borc":5000,"alacak":0}, {"hesap":"600 YURTICI SATISLAR","borc":0,"alacak":5000}]
  Borclu hesaplar once, alacakli hesaplar sonra. Tutarlar SAYI olsun, metin degil.
- Soru bir TABLO/ANALIZ sorusuysa (bilanco, gelir tablosu, nakit akis, oran analizi)
  "tablo" alanini doldur.
  Bicim: {"baslik":"Gelir Tablosu (TL)","kolonlar":["Kalem","Tutar"],"satirlar":[["Brut Satislar","100.000"],["Satis Maliyeti (-)","60.000"],["Brut Kar ←","40.000"]]}
  Ogrencinin gormesi gereken satirin ilk hucresinin sonuna ← koy; site o satiri vurgular.
- Konu gorsel gerektirmiyorsa iki alani da bos birak. ZORLAMA - uydurma tablo, tablosuzluktan kotudur.
- Tablodaki ve yevmiyedeki BUTUN TUTARLAR sorudaki verilerden gelmeli ya da onlardan hesaplanmali.
"@
    $gorselAlan = ',"yevmiye":[],"tablo":null'
  }
  $sik = ""; foreach($h in @('A','B','C','D','E')){ $v="$($s.siklar.$h)"; if($v.Trim()){ $sik += "$h) $v`n" } }
  $dayanak = if($maddeMetni){ "=== DAYANAK METIN ($($s.kaynak)) ===`n$maddeMetni`n=== METIN BITTI ===`n" } else { "(Bu soru bir kanun maddesine dayanmiyor - dil/matematik/genel kultur. Dayanak sorunun kendi kurgusudur.)`n" }
  return @"
Sen bir SMMM sinav hazirlik platformunun editorusun. Gorevin bir sorunun ACIKLAMALARINI yeniden yazmak.

$dayanak
SORU: $($s.soru)
SIKLAR:
$sik
DOGRU CEVAP: $($s.dogru)

MUTLAK KURALLAR:
1. SORUYU, SIKLARI VE DOGRU CEVABI DEGISTIRME. Yalniz aciklamalari yazacaksin.
2. Yukaridaki dayanak metinde YAZMAYAN hicbir rakam, oran, sure ya da esik YAZMA. Emin degilsen sayi vermeden anlat. Uydurulmus tek bir rakam butun isi bozar.
3. HIC MUHASEBE BILMEYEN birine anlatiyorsun. Teknik terimi ilk kullandiginda parantez icinde tek cumleyle acikla.
4. Cumleler kisa: ortalama 20 kelimeyi gecmesin. Edilgen degil etken yaz ("kayit yapilir" degil, "isletme su kaydi yapar").

DOGRU SIKKIN ($($s.dogru)) aciklamasi DORT PARCA olacak, bu basliklarla ve bu sirayla:
Ne soruluyor: <tek cumle>
Kural: <maddeye dayali, gunluk dille>
Bu olayda: <kuralin bu soruya uygulanisi, adim adim, varsa rakamli>
Akilda kalsin: <tek cumle>
Uzunlugu 400-700 karakter olsun.

YANLIS SIKLARIN her birinde TEK IS var: tuzagi adlandirmak. Kalip:
"<Bu sik> X ile Y'yi karistiriyor. X sudur; Y ise budur."
120-250 karakter. "Yanlistir" deyip gecme - ogrenci NEYI karistirdigini gormeli.

hap: butun sorunun tek cumlelik ozeti (en fazla 120 karakter).
$gorsel
SADECE gecerli JSON dondur, baska hicbir sey yazma:
{"aciklama":{"A":"...","B":"...","C":"...","D":"...","E":"..."},"hap":"..."$gorselAlan}
Sorunun bos olan sikki varsa o harfi de bos string birak.
"@
}

# --- isler
$isler = New-Object System.Collections.Generic.List[object]
$ist = [ordered]@{ toplam=0; hazir=0; metinli=0; metinsiz=0 }
foreach($s in $sorular){
  $ist.toplam++
  if($sinir -gt 0 -and $isler.Count -ge $sinir){ break }
  $metin = ''
  if($s.kanun_no -and $s.madde_no -and "$($s.kanun_no)" -notin @('STD','THP')){
    $m = MaddeMetni "$($s.kanun_no)" ("$($s.madde_no)" -replace '^(gec|ek|muk)','') $( if("$($s.madde_no)" -match '^(gec|ek|muk)'){ $Matches[1] } else { '' } )
    if($m -and $m.metin){ $metin = "$($m.metin)"; if($metin.Length -gt 6000){ $metin = $metin.Substring(0,6000) } }
  }
  if($metin){ $ist.metinli++ } else { $ist.metinsiz++ }
  $isler.Add([pscustomobject]@{ id="$($s.id)"; soru=$s; metin=$metin; istem=(IstemKur $s $metin) })
  $ist.hazir++
  if($ist.hazir % 200 -eq 0){ Write-Host ("  hazirlanan ...{0}" -f $ist.hazir) }
}
Write-Host ""
foreach($k in $ist.Keys){ Write-Host ("  {0,-10} {1}" -f $k, $ist[$k]) }

# --- maliyet
$gk=0; foreach($i in $isler){ $gk += $i.istem.Length }
$gt=[math]::Round($gk/3); $ct=$isler.Count*700
$FG=3.0; $FC=15.0
$tahmin = (($gt/1e6*$FG)+($ct/1e6*$FC))/2
Write-Host ""
Write-Host ("MALIYET TAHMINI (Batch %50): ~{0:N2} USD   soru basina ~{1:N4}" -f $tahmin, $(if($isler.Count){$tahmin/$isler.Count}else{0}))
if(-not $calistir){ Write-Host "OLCUM MODU - istek atilmadi, 0 USD."; try{Stop-Transcript|Out-Null}catch{}; exit 0 }
if(-not $AK){ Write-Host "ANTHROPIC_API_KEY yok."; exit 1 }

# --- batch
$sonuc=@{}; $gG=0; $gC=0
$PARTI=400
for($p=0; $p -lt [math]::Ceiling($isler.Count/$PARTI); $p++){
  $dilim=@($isler[($p*$PARTI)..([math]::Min(($p+1)*$PARTI-1,$isler.Count-1))])
  $req=@(); foreach($i in $dilim){ $req += @{ custom_id="$($i.id)"; params=@{ model=$model; max_tokens=2000; messages=@(@{role='user';content=$i.istem}) } } }
  $govde=@{requests=$req}|ConvertTo-Json -Depth 8
  Write-Host ("PARTI {0}: {1} soru ({2:N0} KB)" -f ($p+1), $dilim.Count, ($govde.Length/1024))
  $b = Invoke-RestMethod -Method Post -Uri 'https://api.anthropic.com/v1/messages/batches' -Headers $HDR -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($govde))
  $tur=0
  while($true){ Start-Sleep -Seconds 20; $tur++
    $st = Invoke-RestMethod -Uri "https://api.anthropic.com/v1/messages/batches/$($b.id)" -Headers $HDR
    if($st.processing_status -eq 'ended'){ break }
    if($tur -ge 90){ Write-Host "  ZAMAN ASIMI"; break } }
  $adres = if($st.results_url){ "$($st.results_url)" } else { "https://api.anthropic.com/v1/messages/batches/$($b.id)/results" }
  $cev = Invoke-WebRequest -UseBasicParsing -Uri $adres -Headers $HDR -TimeoutSec 300
  # PS7 metin tanimadigi cevaplarda byte dizisi dondurur - 28.07'de ogrenildi
  $metinCevap = if($cev.Content -is [byte[]]){ [Text.Encoding]::UTF8.GetString($cev.Content) } else { "$($cev.Content)" }
  foreach($sat in ($metinCevap -split "`r?`n")){
    if("$sat".Trim().Length -eq 0){ continue }
    try { $r = $sat | ConvertFrom-Json } catch { continue }
    if("$($r.result.type)" -ne 'succeeded'){ continue }
    $gG += [int]"$($r.result.message.usage.input_tokens)"; $gC += [int]"$($r.result.message.usage.output_tokens)"
    $mt=[regex]::Match("$($r.result.message.content[0].text)", '\{[\s\S]*\}')
    if(-not $mt.Success){ continue }
    try { $sonuc["$($r.custom_id)"] = ($mt.Value | ConvertFrom-Json) } catch {}
  }
}

# --- RAKAM KAPISI + yazma
# 29.07 KAPI DUZELTMESI - pilotun ogrettigi.
# Ilk hali "aciklamadaki her sayi kaynakta gecmeli" diyordu ve 150 sorunun
# 28'ini reddetti (%19). Reddedilenlere bakinca kapinin kendisinde kusur
# oldugu goruldu: 500/300/80, 3.000x4, 60.000 gibi sayilar UYDURMA DEGIL,
# HESAPLANMIS TUTARLARDI. Muhasebe sorusunda "Bu olayda" parcasi zaten toplama
# cikarma yapar; sonuc kaynakta birebir gecmez. Yani kapi, tam da istedigimiz
# "rakamli adim adim anlatim"i engelliyordu.
#
# YENI AYRIM - riske gore:
#   RISKLI SAYI  : oran (%), sure (gun/ay/yil/hafta), yil (1900-2099), madde no.
#                  Bunlar KAYNAKTA GECMEK ZORUNDA. 28.07'de bulunan uc gercek
#                  hatanin ucu de tam bu tipti (%20-%21, 7-15 gun, 6 ay-1 yil).
#   TUTAR        : hesaplanabilir. Kaynakta yoksa, kaynak sayilarindan basit
#                  aritmetikle (toplam/fark/carpim/1-12 kati) uretilebiliyor mu
#                  diye bakilir. Uretilemiyorsa RAPORA yazilir, GM ornekler.
function SayiListe([string]$t){
  $l=@(); foreach($m in [regex]::Matches("$t", '\d[\d\.\,]*')){ $l += ($m.Value.TrimEnd('.',',')) }
  return $l
}
function SayiDeger([string]$s){
  # "60.000" -> 60000 ; "0,20" -> 0.20
  $x = "$s"
  if($x -match '^\d{1,3}(\.\d{3})+(,\d+)?$'){ $x = $x -replace '\.','' -replace ',','.' }
  else { $x = $x -replace ',','.' }
  $d = 0.0
  if([double]::TryParse($x, [Globalization.NumberStyles]::Any, [Globalization.CultureInfo]::InvariantCulture, [ref]$d)){ return $d }
  return $null
}
# 29.07: YAZIYLA SAYI. Ornek dokumunde yakalandi: bir aciklama "uc kez ilan
# edilir" yazmis ve rakam kapisi gormemis - cunku kapi yalniz RAKAMA bakiyordu.
# Sure ve adet Turkce'de sik sik yaziyla yazilir; kapinin en buyuk deligi buydu.
$YAZI_SAYI = [ordered]@{ 'bir'=1;'iki'=2;'uc'=3;'üç'=3;'dort'=4;'dört'=4;'bes'=5;'beş'=5;'alti'=6;'altı'=6;'yedi'=7;'sekiz'=8;'dokuz'=9;'on'=10;'onbes'=15;'onbeş'=15;'yirmi'=20;'otuz'=30;'kirk'=40;'kırk'=40;'elli'=50;'altmis'=60;'altmış'=60;'yetmis'=70;'yetmiş'=70;'seksen'=80;'doksan'=90;'yuz'=100;'yüz'=100 }
function YaziylaSayilar([string]$t){
  $l=@()
  foreach($k in $YAZI_SAYI.Keys){
    foreach($m in [regex]::Matches("$t", "(?i)\b$k\s+(g[uü]n|ay|y[iı]l|hafta|saat|kez|defa|kat)\b")){
      $l += "$($YAZI_SAYI[$k])"
    }
  }
  return $l
}
function RiskliSayilar([string]$t){
  $l=@()
  foreach($n in (YaziylaSayilar $t)){ $l += $n }
  foreach($m in [regex]::Matches("$t", '%\s*(\d[\d\.,]*)')){ $l += $m.Groups[1].Value.TrimEnd('.',',') }
  foreach($m in [regex]::Matches("$t", '(\d[\d\.,]*)\s*%')){ $l += $m.Groups[1].Value.TrimEnd('.',',') }
  foreach($m in [regex]::Matches("$t", '(?i)(\d+)\s*(g[üu]n|ay|y[ıi]l|hafta|saat)\b')){ $l += $m.Groups[1].Value }
  foreach($m in [regex]::Matches("$t", '(?<![\d.,])(19\d{2}|20\d{2})(?![\d.,])')){ $l += $m.Groups[1].Value }
  foreach($m in [regex]::Matches("$t", '(?i)(?:madde|m\.)\s*(\d{1,4})')){ $l += $m.Groups[1].Value }
  return $l
}
function AritmetikUretilebilir([double]$hedef, $kaynakDegerler){
  foreach($a in $kaynakDegerler){
    if([math]::Abs($a - $hedef) -lt 0.005){ return $true }
    for($k=2; $k -le 12; $k++){ if([math]::Abs($a*$k - $hedef) -lt 0.005){ return $true }; if($a -ne 0 -and [math]::Abs($a/$k - $hedef) -lt 0.005){ return $true } }
    foreach($b in $kaynakDegerler){
      if([math]::Abs(($a+$b) - $hedef) -lt 0.005){ return $true }
      if([math]::Abs(($a-$b) - $hedef) -lt 0.005){ return $true }
      if([math]::Abs(($a*$b) - $hedef) -lt 0.005){ return $true }
      if($b -ne 0 -and [math]::Abs(($a/$b) - $hedef) -lt 0.005){ return $true }
      # yuzde uygulamasi: a'nin b yuzdesi
      if([math]::Abs(($a*$b/100.0) - $hedef) -lt 0.005){ return $true }
    }
  }
  return $false
}
$ozet=[ordered]@{ yenilenen=0; rakamRed=0; dilRed=0; tutarIsaretli=0; tabloEklendi=0; bosRed=0; cevapsiz=0; yazmaHatasi=0 }
$red = New-Object System.Collections.Generic.List[object]
foreach($i in $isler){
  $y = $sonuc[$i.id]
  if(-not $y -or -not $y.aciklama){ $ozet.cevapsiz++; continue }
  $yeniMetin = ""
  foreach($h in @('A','B','C','D','E')){ $yeniMetin += " " + "$($y.aciklama.$h)" }
  $yeniMetin += " " + "$($y.hap)"
  # 29.07: alt sinir 100'du - o kadar kisa bir metin dort parcali sablonu
  # tasiyamaz, yani standardi karsilamadigi halde geciyordu. Hedef 400-700;
  # 300 altini kabul etmiyoruz.
  if("$($y.aciklama.$($i.soru.dogru))".Trim().Length -lt 300){ $ozet.bosRed++; continue }

  # 29.07 VERI KAYBI ONLEMI: model bazen 'hap' alanini bos donduruyor ve eski
  # hap USTUNE BOS YAZILIYORDU. Ornek dokumunde 4 sorunun 1'inde yakalandi.
  # Iyilestirme adi altinda veri silmek kabul edilemez. Once aciklamanin
  # icindeki "Akilda kalsin:" satirindan turetilir; o da yoksa hap YAZILMAZ,
  # eskisi kalir.
  if("$($y.hap)".Trim().Length -lt 5){
    $ak = [regex]::Match("$($y.aciklama.$($i.soru.dogru))", '(?is)Ak[ıi]lda\s+kals[ıi]n\s*:\s*(.+?)\s*$')
    if($ak.Success){ $y.hap = $ak.Groups[1].Value.Trim() }
  }

  $kaynakMetin = $i.metin + " " + "$($i.soru.soru)"
  foreach($h in @('A','B','C','D','E')){ $kaynakMetin += " " + "$($i.soru.siklar.$h)" }
  $kaynakSay = @{}; foreach($n in (SayiListe $kaynakMetin)){ $kaynakSay[$n]=1 }
  $kaynakDeg = @(); foreach($n in $kaynakSay.Keys){ $d = SayiDeger $n; if($null -ne $d){ $kaynakDeg += $d } }

  # (1) RISKLI SAYI KAPISI - oran / sure / yil / madde no. Bunlar hesaplanamaz,
  #     ya kaynakta yazar ya uydurmadir. Gecmiyorsa yenileme COPE, eski kalir.
  $riskliKaynak = @{}; foreach($n in (RiskliSayilar $kaynakMetin)){ $riskliKaynak[$n]=1 }
  $riskliUydurma = @()
  foreach($n in (RiskliSayilar $yeniMetin)){
    if($riskliKaynak.ContainsKey($n)){ continue }
    if($kaynakSay.ContainsKey($n)){ continue }   # metinde sayi olarak geciyorsa kabul
    $riskliUydurma += $n
  }
  if($riskliUydurma.Count -gt 0){
    $ozet.rakamRed++
    $red.Add([pscustomobject]@{ id=$i.id; sebep='riskli-sayi-kaynakta-yok'; rakamlar=($riskliUydurma -join ',') })
    continue
  }

  # (2) TUTAR KONTROLU - hesaplanabilir olmali. Reddetmez, ISARETLER: muhasebe
  #     aciklamasi zaten toplama/carpma yapar, sonuc kaynakta birebir gecmez.
  #     Ama hicbir aritmetikle uretilemeyen tutar da supheli - GM orneklesin.
  $izahsiz = @()
  foreach($n in (SayiListe $yeniMetin)){
    if($n.Length -le 1){ continue }
    if($kaynakSay.ContainsKey($n)){ continue }
    $d = SayiDeger $n; if($null -eq $d){ continue }
    if(AritmetikUretilebilir $d $kaynakDeg){ continue }
    $izahsiz += $n
  }
  if($izahsiz.Count -gt 0){
    $ozet.tutarIsaretli++
    $red.Add([pscustomobject]@{ id=$i.id; sebep='TUTAR-IZAHSIZ (yazildi, GM orneklesin)'; rakamlar=($izahsiz -join ',') })
  }

  # (3) DIL KAPISI - olculur, temenni degil. Cumle ortalamasi <=20, tek cumle <=30.
  $cumleler = @(($yeniMetin -split '(?<=[.!?:])\s+') | Where-Object { $_.Trim().Length -gt 3 })
  $kel = @(); $enUzun = 0
  foreach($c in $cumleler){ $k = @($c -split '\s+' | Where-Object { $_ }).Count; $kel += $k; if($k -gt $enUzun){ $enUzun = $k } }
  $ort = if($kel.Count){ ($kel | Measure-Object -Average).Average } else { 0 }
  if($ort -gt 20 -or $enUzun -gt 30){
    $ozet.dilRed++
    $red.Add([pscustomobject]@{ id=$i.id; sebep='dil-kapisi'; rakamlar=("ort {0:N1} kelime, en uzun {1}" -f $ort, $enUzun) })
    continue
  }

  $satir = [ordered]@{ aciklama=$y.aciklama }
  # hap yalniz DOLU ise yazilir - bos gonderip eskisini silmek veri kaybidir
  if("$($y.hap)".Trim().Length -ge 5){ $satir['hap'] = "$($y.hap)".Trim() }
  # Gorseller: yalniz DOLU gelenler yazilir. Bos gonderip mevcut gorseli
  # silmek, iyilestirme adi altinda kayip olur.
  if($y.PSObject.Properties['yevmiye'] -and @($y.yevmiye).Count -gt 0){ $satir['yevmiye'] = $y.yevmiye; $ozet.tabloEklendi++ }
  elseif($y.PSObject.Properties['tablo'] -and $y.tablo -and $y.tablo.satirlar -and @($y.tablo.satirlar).Count -gt 0){ $satir['tablo'] = $y.tablo; $ozet.tabloEklendi++ }
  $govde = $satir | ConvertTo-Json -Depth 6
  try {
    Invoke-RestMethod -Method Patch -Uri "$SB_URL/rest/v1/soru_havuzu?id=eq.$($i.id)" -Headers $HW `
      -ContentType "application/json; charset=utf-8" -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 60 | Out-Null
    $ozet.yenilenen++
  } catch { $ozet.yazmaHatasi++ }
}

$gercek = (($gG/1e6*$FG)+($gC/1e6*$FC))/2
Write-Host ""
Write-Host "======== ACIKLAMA YENILEME ========"
foreach($k in $ozet.Keys){ Write-Host ("  {0,-14} {1}" -f $k, $ozet[$k]) }
Write-Host ("  GERCEK FATURA : ~{0:N2} USD  ({1:N0} giris + {2:N0} cikis token)" -f $gercek, $gG, $gC)
Write-Host ("  NOT: rakam kapisindan donen {0} sorunun ESKI aciklamasi KALDI - bozulmadi." -f $ozet.rakamRed)

$yol = if($cikti){ $cikti } else { Join-Path $kok 'veri/aciklama-rapor.json' }
[IO.File]::WriteAllText($yol, ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); ders=$ders; model=$model
  ozet=$ozet; fatura=[ordered]@{ giris=$gG; cikis=$gC; usd=[math]::Round($gercek,2) }
  redler=@($red | Select-Object -First 100)
} | ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding($false)))
Write-Host ("-> {0}" -f $yol)
try{Stop-Transcript|Out-Null}catch{}
exit 0
