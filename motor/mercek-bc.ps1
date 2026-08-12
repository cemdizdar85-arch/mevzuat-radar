# ============================================================================
#  MERCEK B (HESAP) ve MERCEK C (OGRETME + DIL)      (10.08.2026)
#
#  CEM 09.08: "birisi kontrol etsin, birisi mevzuat karsilastirsin, birisi
#  baska birseyle" -> tek hakem yerine UC BAGIMSIZ MERCEK.
#    Mercek A - mevzuat  : motor/profesor-v2.ps1  (ZATEN VAR, alinti dogrulamali)
#    Mercek B - hesap    : BU BETIK -mercek b
#    Mercek C - ogretme  : BU BETIK -mercek c
#
#  NEDEN AYRI CAGRI: B ve C'yi tek istemde birlestirmek parayi yariya indirir
#  ama BAGIMSIZLIGI oldurur - ayni model ayni okumada iki hukum verir, ikisi
#  birlikte yanilir. Cem'in istedigi sey tam olarak bagimsizlikti.
#
#  MERCEK B - HESAP
#    Soruyu SIFIRDAN cozer. Isaretli cevabi ONE KOYMAZ - onun ne oldugunu
#    soylemeden once kendi sonucunu ister. Sonra makine karsilastirir.
#    Bu, "modelin isaretli cevaba demir atmasi" (anchoring) tuzagina karsi.
#    MAKINE KAPISI: modelin sectigi sik ile kasadaki dogru sik tutmuyorsa
#    BAYRAK - modelin gerekcesine bakilmaz, cakisma yeterlidir.
#
#  MERCEK C - OGRETME + DIL
#    Aciklama 4 parcali mi, her YANLIS sikta tuzak adi + "Dogrusu:" var mi,
#    Turkce temiz mi, yapay zeka kokusu var mi, ders etiketi icerikle uyuyor mu.
#    MAKINE KAPISI: model "Dogrusu var" dese bile metinde "Dogrusu" gecmiyorsa
#    modelin hukmu gecersiz sayilir. Modelin sozune degil metne bakilir.
#
#  PARA: -olcum HICBIR SEY HARCAMAZ. Gercek kosu -calistir ile, Batch API
#  uzerinden (%50 indirim). Parti kimlikleri GONDERILIR GONDERILMEZ
#  veri/bekleyen-partiler.json'a yazilir - bu ders iki kez ~39 USD'ye ogrenildi.
# ============================================================================
param(
  [ValidateSet('b','c')][string]$mercek = 'c',
  [switch]$olcum,
  [switch]$calistir,
  [int]$sinir = 0,                 # 0 = hepsi
  [string]$idler = '',             # yalniz bu kimlikler (JSON dizi dosyasi)
  [string]$haric = '',             # bu kimlikler ATLANIR (odenmis yargi)
  [string]$kurtar = '',            # islenmis partiyi YENIDEN GONDERMEDEN cek
  [string]$model = 'claude-opus-5',
  [string]$caba = 'high',
  # 10.08: yayin-kapisi.ps1 (temiz id listesi ureten kapi) harf onarimindan
  # sonra cok yavasladi - K4'un Turkce buyuk harf deseni artik cok daha fazla
  # yerde esleziyor ve geri-izleme patliyor. Mercekleri ona BAGLAMAMAK icin
  # burada dogrudan bir aday suzgeci var: aciklamasinda "Dogrusu:" gecen
  # sorular. Cem'in en temel ogretme sarti bu; kasadaki en ayirt edici olcut.
  [switch]$dogrusuVar,
  # 10.08: MERCEKLERIN ASIL ISI YENIDEN YAZILMIS METNI YARGILAMAKTIR.
  # Kasadaki hali degil - o zaten degisecek. Yeniden yazim ciktisi
  # (veri/yeniden-yazim-3540.json) verilirse sorular ORADAN okunur.
  [string]$yenidenYazim = '',
  [string]$cikti = ''
)
$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['Invoke-WebRequest:UserAgent'] = 'mevzuat-radar-robot/1.0'
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here

if(-not $olcum -and -not $calistir){
  Write-Host 'Kullanim:'
  Write-Host '  mercek-bc.ps1 -mercek b -olcum      # PARA HARCAMAZ'
  Write-Host '  mercek-bc.ps1 -mercek b -calistir   # gercek kosu (Batch, %50)'
  Write-Host '  mercek-bc.ps1 -mercek c -calistir'
  exit 0
}

$SBKEY = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User')
if(-not $SBKEY){ $SBKEY = $env:SUPABASE_SERVICE_KEY }
if(-not $SBKEY){ Write-Host 'SUPABASE_SERVICE_KEY yok.'; exit 1 }
$SBH = @{ apikey=$SBKEY; Authorization="Bearer $SBKEY" }
$SBU = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu'

# ---------------------------------------------------------------- kaynak
$sorular = New-Object System.Collections.Generic.List[object]

if($yenidenYazim -ne ''){
  # YENIDEN YAZILMIS METNI YARGILA. Alan adlari kasadakine cevrilir ki
  # istem kurucular ve kapilar hicbir sey bilmeden ayni sekilde calissin.
  if(-not (Test-Path $yenidenYazim)){ Write-Host "KIRMIZI: dosya yok - $yenidenYazim"; exit 1 }
  $yy = ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($yenidenYazim,[Text.Encoding]::UTF8))
  foreach($k in @($yy.kayit)){
    if("$($k.durum)" -ne 'YAZILDI'){ continue }
    $sorular.Add([pscustomobject]@{
      id="$($k.id)"; sinav=''; ders="$($k.yeniDers)"; konu=''
      soru="$($k.yeniSoru)"; siklar=$k.yeniSiklar; dogru="$($k.yeniDogru)"
      aciklama=$k.yeniAciklama; hap="$($k.yeniHap)"; tuzak=$k.yeniTuzak
    })
  }
  Write-Host ("Yeniden yazim dosyasindan: {0} soru ({1})" -f $sorular.Count,(Split-Path $yenidenYazim -Leaf))
  if($sorular.Count -eq 0){ Write-Host 'KIRMIZI: dosyada YAZILDI durumunda soru yok.'; exit 1 }
}
else {
Write-Host 'Kasa cekiliyor...'
$bas = 0
while($true){
  $s = $null
  for($d=1; $d -le 4; $d++){
    try{ $s = Invoke-RestMethod -Uri "$SBU`?select=id,sinav,ders,konu,soru,siklar,dogru,aciklama,hap&order=id&offset=$bas&limit=500" -Headers $SBH -TimeoutSec 180; break }
    catch{ if($d -eq 4){ throw }; Start-Sleep -Seconds (2*$d) }
  }
  $dz = @($s); if($dz.Count -eq 0){ break }
  foreach($x in $dz){ $sorular.Add($x) }
  if($dz.Count -lt 500){ break }
  $bas += 500
  if($bas % 5000 -eq 0){ Write-Host ("  ...{0}" -f $sorular.Count) }
}
$tekil = @($sorular | Group-Object id).Count
Write-Host ("Kasa: {0} soru (tekil {1})" -f $sorular.Count,$tekil)
if($tekil -ne $sorular.Count){ Write-Host 'KIRMIZI: mukerrer cekim - durduruldu.'; exit 1 }

# SIGORTA (profesor-v2'den): siklar/aciklama METIN gelirse istem SIKSIZ gider
# ve odenmis kosu cope gider. Bir kez cevrilir; cevrilemezse DURULUR.
$bozuk = 0
foreach($s in $sorular){
  foreach($alan in 'siklar','aciklama'){
    $v = $s.$alan
    if($v -is [string] -and "$v".Trim().StartsWith('{')){
      try{ $s.$alan = ($v | ConvertFrom-Json) }catch{ $bozuk++ }
    }
  }
}
if($bozuk -gt 0){ Write-Host ("KIRMIZI: {0} kayitta siklar/aciklama cozulemedi." -f $bozuk); exit 1 }
}   # <- kasa dalinin sonu (yenidenYazim verilmediyse buradan gecilir)

# Iki yol da ayni kapiya cikar: siklar gercekten okunuyor mu? Okunmuyorsa
# istem SIKSIZ gider, mercek dogal olarak "yetersiz" der ve odenmis kosu
# sessizce cope gider.
if($sorular.Count -gt 0 -and "$($sorular[0].siklar.A)".Trim().Length -eq 0){
  Write-Host 'KIRMIZI: siklar okunamiyor - bos istem gonderilmez.'; exit 1
}

# ---------------------------------------------------------------- suzgecler
if($haric -and (Test-Path $haric)){
  $atla = @{}
  foreach($x in @(ConvertFrom-Json ([IO.File]::ReadAllText($haric,[Text.Encoding]::UTF8)))){ $atla["$x"] = 1 }
  $once = $sorular.Count
  $sorular = @($sorular | Where-Object {
    $t = "$($_.id)"
    -not ($atla.ContainsKey($t) -or ($t.Length -ge 8 -and $atla.ContainsKey($t.Substring(0,8))))
  })
  Write-Host ("HARIC: {0} kimlik atlandi ({1} -> {2})" -f $atla.Count,$once,$sorular.Count)
}
if($idler){
  if(-not (Test-Path $idler)){ Write-Host "KIRMIZI: kimlik dosyasi yok - $idler"; exit 1 }
  # 10.08: kimlik dosyasi IKI BICIMDE gelebilir - duz dizi ["id","id"] ya da
  # yayin-kapisi ciktisi { idler:[{id,sinav,ders}] }. Duz dizi bekleyip nesne
  # gelirse her anahtar "@{id=...}" olur, HICBIRI eslesmez ve kosu sessizce
  # bos doner. Ikisi de kabul edilir.
  $hamKimlik = ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($idler,[Text.Encoding]::UTF8))
  $kimlikDizi = if($null -ne $hamKimlik.idler){ @($hamKimlik.idler) } else { @($hamKimlik) }
  $ist = @{}
  foreach($x in $kimlikDizi){
    $anahtar = if($null -ne $x.id){ "$($x.id)" } else { "$x" }
    if($anahtar.Trim().Length -gt 0){ $ist[$anahtar] = 1 }
  }
  if($ist.Count -eq 0){ Write-Host 'KIRMIZI: kimlik dosyasindan tek kimlik cikarilamadi.'; exit 1 }
  $sorular = @($sorular | Where-Object { $ist.ContainsKey("$($_.id)") })
  Write-Host ("HEDEFLI: {0} kimlik istendi, {1} eslesti" -f $ist.Count,$sorular.Count)
  if($sorular.Count -eq 0){ Write-Host 'KIRMIZI: hicbir kimlik eslesmedi.'; exit 1 }
}

if($dogrusuVar){
  $reDogrusu = [regex]("(?i)do[g" + [char]0x011F + "]rusu\s*:")   # ğ = g-breve; duz yazilirsa BOM'suz dosyada bozulur
  $once = $sorular.Count
  $sorular = @($sorular | Where-Object {
    $t = ''
    foreach($h in 'A','B','C','D','E'){ $t += " $($_.aciklama.$h)" }
    $reDogrusu.IsMatch($t)
  })
  Write-Host ("DOGRUSU suzgeci: {0} -> {1}" -f $once,$sorular.Count)
}

# Mercek B YALNIZ rakam iceren soruya bakar. Rakamsiz soruyu "coz" demek
# anlamsizdir ve para yakar.
$SAYI = [regex]'\b\d{1,3}(?:\.\d{3})+(?:,\d+)?\b|\b\d+,\d+\b|\b\d{3,}\b'
if($mercek -eq 'b'){
  $once = $sorular.Count
  $sorular = @($sorular | Where-Object { $SAYI.Matches("$($_.soru)").Count -ge 2 })
  Write-Host ("MERCEK B suzgeci (en az 2 sayi): {0} -> {1}" -f $once,$sorular.Count)
}
if($sinir -gt 0 -and $sorular.Count -gt $sinir){ $sorular = @($sorular | Select-Object -First $sinir); Write-Host ("SINIR: {0}" -f $sorular.Count) }
if($sorular.Count -eq 0){ Write-Host 'Yargilanacak soru yok.'; exit 0 }

# ---------------------------------------------------------------- istemler
function SikMetni($s){
  $t = ''
  foreach($h in 'A','B','C','D','E'){ $v = "$($s.siklar.$h)"; if($v.Trim().Length -gt 0){ $t += "$h) $v`n" } }
  return $t
}
function AciklamaMetni($s){
  $t = ''
  foreach($h in 'A','B','C','D','E'){ $v = "$($s.aciklama.$h)"; if($v.Trim().Length -gt 0){ $t += "${h} : $v`n" } }
  if($t.Trim().Length -eq 0){ $t = '(aciklama yok)' }
  return $t
}

function IstemB($s){
  # DIKKAT: isaretli dogru cevap BILEREK verilmiyor. Model once kendi
  # sonucunu bulmali; yoksa verilen cevaba demir atar ve mercek korlesir.
  return @"
Asagida bir Turk muhasebe/maliye sinavi sorusu ve siklari var.
ISARETLI CEVAP SANA VERILMEDI - bilerek. Once SEN coz.

Yalnizca kesin muhasebe/vergi/maliyet bilgisine ve soruda verilen verilere
dayan. Soru eksik veri iceriyorsa ya da tek bir dogru sonuca goturmuyorsa
"COZULEMEDI" de ve nedenini yaz - tahmin etme.

SORU: $($s.soru)

SIKLAR:
$(SikMetni $s)

Yap:
1. Cozumu ADIM ADIM yaz. Kullandigin formulu acikca yaz.
2. Bulduguna en yakin sikki sec.
3. Siklardan KAC TANESI dogru bir ifade? (birden fazla dogru varsa soru bozuktur)
4. Sik degerleri birbiriyle tutarli mi? Yevmiye kaydi varsa BORC=ALACAK mi?

Yalnizca su JSON'u dondur, baska hicbir sey yazma:
{"cozum_adimlari":"<kisa, formullu>","hesapladigim_deger":"<sayi ya da ifade>","sectigim_sik":"A|B|C|D|E|COZULEMEDI","dogru_sik_sayisi":<0-5>,"borc_alacak_dengeli":"evet|hayir|ilgisiz","sorun":"<varsa tek cumle, yoksa bos>"}
"@
}

function IstemC($s){
  return @"
Sen bir sinav sorusu ogretim denetcisisin. Asagidaki soruyu ADAYIN GOZUYLE oku.
Amacimiz: aday soruyu cozdukten sonra KONUYU OGRENMIS olsun.

SORU: $($s.soru)
DERS ETIKETI: $($s.ders)
KONU: $($s.konu)

SIKLAR:
$(SikMetni $s)
ISARETLI DOGRU CEVAP: $($s.dogru)

SIK ACIKLAMALARI:
$(AciklamaMetni $s)

HAP BILGI: $($s.hap)

Su alti sey denetlenir:
1. ogretiyor_mu : Aciklama yalnizca "dogru sik B'dir" mi diyor, yoksa NEDEN
   dogru oldugunu ogretiyor mu?
2. tuzak_adlari : HER YANLIS sik icin, o sikki secen adayin dustugu tuzak
   ADLANDIRILMIS mi? (ornek: "brut/net karistirma", "KDV'yi maliyete katma")
3. dogrusu_var  : Her yanlis sik aciklamasi "Dogrusu:" ile dogruyu ogretiyor mu?
4. turkce_temiz : Turkce karakterler dogru mu (c g i o s u)? Bozuk kelime,
   arkaik/Osmanlica kelime, devrik/bozuk cumle var mi?
5. yz_kokusu    : Yapay zeka yazmis gibi duruyor mu? (kalip cumleler, asiri
   simetrik siklar, hep ayni uzunlukta secenekler, "Bu baglamda" tipi gecisler)
6. ders_dogru   : DERS ETIKETI icerikle uyuyor mu? Uymuyorsa dogrusu ne?

Yalnizca su JSON'u dondur, baska hicbir sey yazma:
{"ogretiyor_mu":"evet|kismen|hayir","tuzak_adlari":"tam|eksik|yok","dogrusu_var":"evet|kismen|hayir","turkce_temiz":"evet|hayir","turkce_kusurlari":"<varsa bozuk kelimeler, virgulle>","yz_kokusu":"var|yok","yz_gerekce":"<varsa tek cumle>","ders_dogru":"evet|hayir","onerilen_ders":"<yanlissa dogrusu, dogruysa bos>","karar":"TEMIZ|ZAYIF","gerekce":"<tek cumle>"}
"@
}

$isler = New-Object System.Collections.Generic.List[object]
foreach($s in $sorular){
  $istem = if($mercek -eq 'b'){ IstemB $s } else { IstemC $s }
  $isler.Add([pscustomobject]@{ id="$($s.id)"; soru=$s; istem=$istem })
}

# ---------------------------------------------------------------- maliyet
$krToplam = 0
foreach($i in $isler){ $krToplam += $i.istem.Length }
$girisTok = [math]::Round($krToplam / 3)     # kaba cevrim: ~3 karakter = 1 token (TAHMIN)
$cikisTahmin = if($mercek -eq 'b'){ 700 } else { 420 }
$cikisTok = $isler.Count * $cikisTahmin
# Opus 5 liste fiyati: 5 USD/M girdi, 25 USD/M cikti (referanstan)
$FG = 5.0; $FC = 25.0
$hamUSD = ($girisTok/1e6*$FG) + ($cikisTok/1e6*$FC)
$batchUSD = $hamUSD / 2

Write-Host ''
Write-Host ("======== MERCEK {0} - MALIYET TAHMINI (TAHMINDIR) ========" -f $mercek.ToUpper())
Write-Host ("  soru        : {0}" -f $isler.Count)
Write-Host ("  giris  ~{0:N0} token  | cikis ~{1:N0} token" -f $girisTok,$cikisTok)
Write-Host ("  model       : {0} (caba {1})" -f $model,$caba)
Write-Host ("  liste       : ~{0:N2} USD" -f $hamUSD)
Write-Host ("  BATCH (%50) : ~{0:N2} USD   <-- kullanilacak yol" -f $batchUSD)

if($olcum){
  Write-Host ''
  Write-Host 'OLCUM MODU - hicbir istek atilmadi, 0 USD.'
  [IO.File]::WriteAllText((Join-Path $kok ("veri/mercek-{0}-olcum.json" -f $mercek)), ([ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); mercek=$mercek; model=$model
    soru=$isler.Count; tahminiBatchUSD=[math]::Round($batchUSD,2)
    not='Tahmin: 3 karakter=1 token kaba cevrimi. Gercek rakam kosudan sonra faturada.'
  } | ConvertTo-Json -Depth 4), (New-Object Text.UTF8Encoding($false)))
  exit 0
}

# ---------------------------------------------------------------- gercek kosu
# 12.08: cift hat - hedef api-hedef.ps1'den (anthropic | aws)
. (Join-Path $PSScriptRoot 'api-hedef.ps1')
$HEDEF = Get-ApiHedef
$AK = $HEDEF.anahtar
$HDR = $HEDEF.basliklar
$API_TABAN = $HEDEF.taban
Write-Host ("API hedefi: {0}" -f $HEDEF.ad)
$BATCH_MAX = 400

Write-Host 'ON KONTROL: anahtar + model sinaniyor...'
try{
  $dene = @{ model=$model; max_tokens=1; messages=@(@{ role='user'; content='tamam' }) } | ConvertTo-Json -Depth 5
  $ok = Invoke-RestMethod -Method Post -Uri ($API_TABAN + '/v1/messages') -Headers $HDR -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($dene)) -TimeoutSec 60
  Write-Host ("  TAMAM - model: {0}" -f $ok.model)
}catch{
  Write-Host ("ON KONTROL DUSTU: {0}" -f $_.Exception.Message)
  Write-Host 'Parti GONDERILMEDI - para harcanmadi.'
  exit 1
}

function BekleyenYaz([string]$bid){
  try{
    $byol = Join-Path $kok 'veri/bekleyen-partiler.json'
    $bek = @()
    if(Test-Path $byol){ foreach($x in (ConvertFrom-Json ([IO.File]::ReadAllText($byol,[Text.Encoding]::UTF8)))){ $bek += "$x" } }
    if($bek -notcontains $bid){ $bek += $bid }
    [IO.File]::WriteAllText($byol, (ConvertTo-Json -InputObject ([object[]]$bek) -Depth 3), (New-Object Text.UTF8Encoding($false)))
  }catch{ Write-Host ("  bekleyen parti yazilamadi: {0}" -f $_.Exception.Message) }
}

$sonuclar = @{}
$gG = 0; $gC = 0
$partiler = [math]::Ceiling($isler.Count / $BATCH_MAX)
for($p=0; $p -lt $partiler; $p++){
  $dilim = @($isler[($p*$BATCH_MAX)..([math]::Min(($p+1)*$BATCH_MAX-1, $isler.Count-1))])
  $req = @()
  foreach($i in $dilim){
    # custom_id = SORUNUN KENDI KIMLIGI. Sira numarasi kullanmak odenmis
    # partiyi cope attirmisti (28.07).
    $req += @{
      custom_id = "$($i.id)"
      params = @{
        model = $model
        # 10.08: ilk sinamada 20 sorunun 7'si "hata" dondu. Opus 5'te DUSUNME
        # VARSAYILAN ACIK ve dusunme jetonlari max_tokens'tan yeniyor; 1200
        # yetmeyince metin blogu hic uretilmiyor, cevap 'json-yok' oluyor ve
        # ODENMIS istek cope gidiyor. Tavan yukseltildi.
        max_tokens = $(if($mercek -eq 'b'){ 4000 } else { 3000 })
        output_config = @{ effort = $caba }
        messages = @(@{ role='user'; content=$i.istem })
      }
    }
  }
  $govde = @{ requests = $req } | ConvertTo-Json -Depth 8
  Write-Host ("PARTI {0}/{1}: {2} soru ({3:N0} KB)..." -f ($p+1),$partiler,$dilim.Count,($govde.Length/1024))
  try{
    $b = Invoke-RestMethod -Method Post -Uri ($API_TABAN + '/v1/messages/batches') -Headers $HDR -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($govde))
  }catch{
    Write-Host ("BATCH GONDERIM DUSTU: {0}" -f $_.Exception.Message)
    try{ Write-Host ((New-Object IO.StreamReader($_.Exception.Response.GetResponseStream())).ReadToEnd()) }catch{}
    throw
  }
  $bid = $b.id
  Write-Host ("  batch id: {0}" -f $bid)
  BekleyenYaz $bid    # GONDERILIR GONDERILMEZ - once yaz, sonra bekle

  $tur = 0; $zamanAsimi = $false
  while($true){
    Start-Sleep -Seconds 20
    $tur++
    $st = Invoke-RestMethod -Uri "$API_TABAN/v1/messages/batches/$bid" -Headers $HDR
    if($tur % 5 -eq 0 -or $st.processing_status -eq 'ended'){ Write-Host ("  durum: {0}" -f $st.processing_status) }
    if($st.processing_status -eq 'ended'){ break }
    if($tur -ge 540){
      Write-Host ("  ZAMAN ASIMI (3 saat). Kurtarma: -kurtar {0}" -f $bid)
      $zamanAsimi = $true; break
    }
  }
  if($zamanAsimi){ continue }

  $adres = if($st.results_url){ "$($st.results_url)" } else { "$API_TABAN/v1/messages/batches/$bid/results" }
  $cev = Invoke-WebRequest -UseBasicParsing -Uri $adres -Headers $HDR -TimeoutSec 300
  # PS7 metin saymadigi cevabi BYTE DIZISI dondurur; string sanip bolunce
  # her bayt ayri "satir" olur ve odenmis parti cope gider (28.07).
  $metin = if($cev.Content -is [byte[]]){ [Text.Encoding]::UTF8.GetString($cev.Content) } else { "$($cev.Content)" }
  $satirlar = $metin -split "`r?`n"
  Write-Host ("  ham cevap: {0} satir, {1} karakter" -f $satirlar.Count,$metin.Length)

  foreach($sat in $satirlar){
    if("$sat".Trim().Length -eq 0){ continue }
    try{ $r = $sat | ConvertFrom-Json }catch{ continue }
    $cid = "$($r.custom_id)"
    if($cid.Length -eq 0){ continue }
    if("$($r.result.type)" -ne 'succeeded'){ $sonuclar[$cid] = @{ hata="$($r.result.type)" }; continue }
    $gG += [int]"$($r.result.message.usage.input_tokens)"
    $gC += [int]"$($r.result.message.usage.output_tokens)"
    # Dusunme acikken content[0] THINKING blogudur - text blogu ARANIR.
    $txt = ''
    foreach($bl in @($r.result.message.content)){ if("$($bl.type)" -eq 'text'){ $txt += "$($bl.text)" } }
    $mt = [regex]::Match($txt,'(?s)\{.*\}')
    if(-not $mt.Success){ $sonuclar[$cid] = @{ hata='json-yok' }; continue }
    try{ $sonuclar[$cid] = ($mt.Value | ConvertFrom-Json) }catch{ $sonuclar[$cid] = @{ hata='json-bozuk' } }
  }
}

# ---------------------------------------------------------------- MAKINE KAPISI
# Modelin sozune degil METNE bakilir. Model "var" dese bile metinde yoksa
# hukmu gecersizdir.
$rapor = New-Object System.Collections.Generic.List[object]
$sy = [ordered]@{ temiz=0; bayrak=0; hata=0; cozulemedi=0 }
foreach($i in $isler){
  $h = $sonuclar[$i.id]
  if(-not $h -or $h.hata){ $sy.hata++; continue }
  $s = $i.soru

  if($mercek -eq 'b'){
    $sec = "$($h.sectigim_sik)".Trim().ToUpperInvariant()
    $kasa = "$($s.dogru)".Trim().ToUpperInvariant()
    $adet = 0; [void][int]::TryParse("$($h.dogru_sik_sayisi)",[ref]$adet)
    if($sec -eq 'COZULEMEDI'){ $sy.cozulemedi++ }
    # CAKISMA = BAYRAK. Modelin gerekcesine bakilmaz; iki bagimsiz hesap
    # ayni sonuca varmiyorsa soru yayina cikmaz, insan okur.
    $cakisma = ($sec -ne 'COZULEMEDI' -and $sec -ne '' -and $kasa -ne '' -and $sec -ne $kasa)
    $coklu   = ($adet -gt 1)
    $denge   = ("$($h.borc_alacak_dengeli)" -eq 'hayir')
    $sorunlu = $cakisma -or $coklu -or $denge
    if($sorunlu){ $sy.bayrak++ } elseif($sec -ne 'COZULEMEDI'){ $sy.temiz++ }
    $rapor.Add([pscustomobject]@{
      id=$i.id; mercek='B'; ders="$($s.ders)"
      kasaDogru=$kasa; modelSik=$sec; hesapladigi="$($h.hesapladigim_deger)"
      dogruSikSayisi=$adet; borcAlacak="$($h.borc_alacak_dengeli)"
      cakisma=$cakisma; cokluDogru=$coklu
      sorun="$($h.sorun)"; cozum="$($h.cozum_adimlari)"
      hukum=$(if($sec -eq 'COZULEMEDI'){ 'COZULEMEDI-INSAN-OKUSUN' } elseif($sorunlu){ 'BAYRAK' } else { 'TEMIZ' })
    })
    continue
  }

  # --- Mercek C makine kapisi: "Dogrusu:" GERCEKTEN metinde geciyor mu
  $acikTum = ''
  foreach($x in 'A','B','C','D','E'){ $acikTum += " $($s.aciklama.$x)" }
  # 10.08 KUSUR: bu desen 'do[gğ]rusu' diye DUZ yazilmisti. Dosya BOM'suz
  # oldugu icin PS 5.1 onu ANSI okuyup 'do[gÄŸ]rusu' yapiyor ve "Dogrusu:"
  # HICBIR ZAMAN eslesmiyordu. Sonuc: kasada "yalniz 178 soruda Dogrusu var"
  # diye YANLIS bir olcum urettim ve Mercek C'nin bayraklarini sisirdim.
  # Kalici cozum: ozel harf desene \u kacisiyla girer, kodlamadan bagimsiz.
  $dogrusuGercek = ([regex]("(?i)do[g" + [char]0x011F + "]rusu\s*:")).Matches($acikTum).Count
  $yanlisSik = 0
  foreach($x in 'A','B','C','D','E'){
    if("$($s.siklar.$x)".Trim().Length -gt 0 -and $x -ne "$($s.dogru)".Trim().ToUpperInvariant()){ $yanlisSik++ }
  }
  $modelDedi = "$($h.dogrusu_var)"
  # Model "evet" diyor ama metinde yanlis sik sayisi kadar "Dogrusu:" yoksa
  # modelin hukmu GECERSIZ - kendi gozumuzle sayiyoruz.
  $iddiaTutuyor = -not ($modelDedi -eq 'evet' -and $dogrusuGercek -lt $yanlisSik)
  $sorunlu = ("$($h.karar)" -eq 'ZAYIF') -or ("$($h.turkce_temiz)" -eq 'hayir') -or `
             ("$($h.yz_kokusu)" -eq 'var') -or ("$($h.ders_dogru)" -eq 'hayir') -or `
             ($dogrusuGercek -lt $yanlisSik)
  if($sorunlu){ $sy.bayrak++ } else { $sy.temiz++ }
  $rapor.Add([pscustomobject]@{
    id=$i.id; mercek='C'; ders="$($s.ders)"
    ogretiyor="$($h.ogretiyor_mu)"; tuzakAdlari="$($h.tuzak_adlari)"
    dogrusuModelDedi=$modelDedi; dogrusuMetindeSayim=$dogrusuGercek; yanlisSikSayisi=$yanlisSik
    modelIddiasiTutuyor=$iddiaTutuyor
    turkceTemiz="$($h.turkce_temiz)"; turkceKusurlari="$($h.turkce_kusurlari)"
    yzKokusu="$($h.yz_kokusu)"; yzGerekce="$($h.yz_gerekce)"
    dersDogru="$($h.ders_dogru)"; onerilenDers="$($h.onerilen_ders)"
    karar="$($h.karar)"; gerekce="$($h.gerekce)"
    hukum=$(if($sorunlu){ 'BAYRAK' } else { 'TEMIZ' })
  })
}

Write-Host ''
Write-Host ("======== MERCEK {0} SONUC ========" -f $mercek.ToUpper())
foreach($k in $sy.Keys){ Write-Host ("  {0,-12} {1}" -f $k,$sy[$k]) }
if($mercek -eq 'c'){
  $iddiaBos = @($rapor | Where-Object { -not $_.modelIddiasiTutuyor }).Count
  Write-Host ("  MODEL IDDIASI TUTMAYAN: {0}  <- model 'Dogrusu var' dedi, metinde yok" -f $iddiaBos)
}
$gercekUSD = (($gG/1e6*$FG) + ($gC/1e6*$FC)) / 2
Write-Host ''
Write-Host '======== GERCEK FATURA (API jetonu) ========'
Write-Host ("  giris {0:N0} | cikis {1:N0} jeton" -f $gG,$gC)
Write-Host ("  TUTAR ~{0:N2} USD (Batch %50 dahil)" -f $gercekUSD)

$yol = if($cikti){ $cikti } else { Join-Path $kok ("veri/mercek-{0}-rapor.json" -f $mercek) }
[IO.File]::WriteAllText($yol, ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); mercek=$mercek; model=$model; caba=$caba
  ozet=$sy; fatura=[ordered]@{ girisJeton=$gG; ciktiJeton=$gC; batchUSD=[math]::Round($gercekUSD,2) }
  sonuclar=$rapor
} | ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding($false)))
Write-Host ("-> {0}" -f $yol)
Write-Host 'SIRADAKI KAPI: BAYRAK alanlardan ornek OKUNACAK. Sayi yeterli degil.'
