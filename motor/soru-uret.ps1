# ============================================================================
#  SORU FABRIKASI — UWorld modelinin Tetikte uygulamasi (SGS + Yeterlilik).
#  Harita (sgs-analiz.json) agirliklarina gore EN COK SORU GETIREN konulardan
#  OZGUN sorular uretir. Cikmis soru KOPYALANMAZ.
#  Her soru: kok + 5 sik + dogru cevap + HER SIKKIN GEREKCESI + kanun maddesi.
#  KAPILAR (UWorld hakem surecinin robotu):
#   1) Bagimsiz COZUCU-1 soruyu cozer — anahtar ile eslesmezse RET
#   2) Bagimsiz COZUCU-2 ayni — ikisi de bulamayan soru muglaktir, RET
#   3) AMBAR TEYIDI — kaynak maddesi Supabase arsivinde gercekten var mi
#   4) Rakam disiplini — yil-degisen tutar geciyorsa RET (oran/sure sabiti serbest)
#   5) Kok tekrari — ayni konuda benzer kokle baslayan soru varsa RET
#  Cikti: veri/soru-bankasi-onay.json (STAGING — orneklem onayi sonrasi yayin).
#  ENV: ANTHROPIC_API_KEY. Kosum: $KONU_LIMIT konu x $ADET soru.
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$MODEL_URET = "claude-sonnet-5"
$MODEL_COZ  = "claude-haiku-4-5-20251001"
$KONU_LIMIT = 15   # 23.07 Cem "1500 de az": kosu basi 90 aday (15 konu x 6); 12 vardiya = ~1.080 aday/gun
$ADET = 6
$key = $env:ANTHROPIC_API_KEY
if(-not $key){ Write-Host "ANTHROPIC_API_KEY yok - atlandi."; exit 0 }

$analizYol = Join-Path $kok "veri/sgs-analiz.json"
if(-not (Test-Path $analizYol)){ Write-Host "sgs-analiz.json yok - ONCE Sinav Analizi calistir."; exit 0 }
$analiz = Get-Content $analizYol -Raw -Encoding UTF8 | ConvertFrom-Json
if(-not $analiz.donemler -or -not @($analiz.donemler).Count){ Write-Host "Harita bos - once Sinav Analizi."; exit 0 }

$bankaYol = Join-Path $kok "veri/soru-bankasi-onay.json"
$banka = if(Test-Path $bankaYol){ Get-Content $bankaYol -Raw -Encoding UTF8 | ConvertFrom-Json } else { [pscustomobject]@{ guncelleme=""; sorular=@() } }
# YAYINLANMIS banka da sayilir: onaydan tasinip yayina giden sorular tekrar
# uretilmesin, konu doygunlugu yayindakileri de gorsun.
$yayinYol = Join-Path $kok "veri/soru-bankasi.json"
$yayinSorular = @(); if(Test-Path $yayinYol){ try { $yayinSorular = @((Get-Content $yayinYol -Raw -Encoding UTF8 | ConvertFrom-Json).sorular) } catch {} }
# 23.07 #7 dersi (29 dk uretim rebase cakismasinda COPE gitti): fabrika artik ortak
# onay dosyasina DEGIL, kosu basina essiz dosyaya yazar (veri/fabrika/uretim-*.json)
# -> ayni dosyaya es zamanli yazma cakismasi imkansiz. GM denetimi bu dosyalari okur,
# onaylananlari paket-havuzuna tasir, tuketilen dosyayi [veri-operasyonu] ile siler.
# Bekleyen fabrika dosyalari kok-tekrar/doygunluk hesabina dahil edilir (dupe olmasin).
$fabrikaDir = Join-Path $kok "veri/fabrika"
$bekleyenFabrika = @()
if(Test-Path $fabrikaDir){
  Get-ChildItem $fabrikaDir -Filter *.json | ForEach-Object {
    try { $bekleyenFabrika += @((Get-Content $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json).sorular) } catch {}
  }
}

function Claude($istem,$maxtok,$model){
  $body = @{ model=$model; max_tokens=$maxtok; messages=@(@{ role="user"; content=$istem }) } | ConvertTo-Json -Depth 6 -Compress
  $r = Invoke-RestMethod -Method Post -Uri "https://api.anthropic.com/v1/messages" `
        -Headers @{ "x-api-key"=$key; "anthropic-version"="2023-06-01" } `
        -Body ([Text.Encoding]::UTF8.GetBytes($body)) -ContentType "application/json" -TimeoutSec 300
  return (@($r.content) | Where-Object { $_.type -eq 'text' } | ForEach-Object { $_.text }) -join ""
}
function JsonBul($t){ $m=[regex]::Match($t,'(?s)\[.*\]'); if($m.Success){ return $m.Value }; $m2=[regex]::Match($t,'(?s)\{.*\}'); if($m2.Success){ return $m2.Value }; return $null }
function Fold($s){ return ("$s".ToLowerInvariant().Trim() -replace 'ç','c' -replace 'ğ','g' -replace 'ı','i' -replace 'ö','o' -replace 'ş','s' -replace 'ü','u' -replace '\s+',' ') }

# AMBAR TEYIDI (gece-ajani ile ayni desen)
$SB_URL="https://bjrleanjpyujtajmazxn.supabase.co"; $SB_ANON="sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg"
$KANUN_NO=[ordered]@{ 'kvkk'='6698'; 'vuk'='213'; 'gvk'='193'; 'kdvk'='3065'; 'kdv'='3065'; 'kvk'='5520'; 'ttk'='6102'; 'smk'='6769'; 'aatuhk'='6183'; 'otv'='4760'; 'iik'='2004'; 'tbk'='6098'; 'isg'='6331' }
# SINIR-DUYARLI AMBAR SORGUSU (23.07 dersi: ilike "*m.1*" m.10-19'u da tutuyordu;
# adaylar cekilir, kesin desenle dogrulanir - ne haksiz GECTI ne haksiz RET)
function AmbarSorgu($filtre, $desen){
  try{
    $u="$SB_URL/rest/v1/dokumanlar?kaynak_ad=ilike."+[uri]::EscapeDataString($filtre)+"&select=kaynak_ad&limit=25"
    $r=Invoke-RestMethod -Uri $u -Headers @{apikey=$SB_ANON;Authorization="Bearer $SB_ANON"} -TimeoutSec 30
    foreach($x in @($r)){ if("$($x.kaynak_ad)" -match $desen){ return 'ok' } }
    return 'yok'
  }catch{ return 'atla' }
}
function AmbarTeyit($kaynak){
  $f=Fold $kaynak
  # STANDART TEYIDI (TMS/TFRS/BDS): "TMS 1 ... paragraf 29" -> ambardaki "TMS 1 p.29*" belgesi
  # 23.07 dersleri: (a) uretici "madde 29" da yaziyor - "m./madde" isareti de kabul;
  # (b) "TMS 1 p.29 ve TMS 24" gibi COKLU atifta HER standart ayri teyit edilir,
  # biri teyitsizse soru gecmez (paragrafsiz/yutulmamis ikinci atif kacak gecmesin).
  $stdMatches=[regex]::Matches($f,'(?<![a-z])(tms|tfrs|bds)\s*(\d{1,3})')
  if($stdMatches.Count -ge 1){
    for($si=0; $si -lt $stdMatches.Count; $si++){
      $sm=$stdMatches[$si]
      $bas=$sm.Index; $son=$(if($si+1 -lt $stdMatches.Count){ $stdMatches[$si+1].Index } else { $f.Length })
      $seg=$f.Substring($bas, $son-$bas)
      $pS=[regex]::Match($seg,'(?:p(?:aragraf)?|m(?:adde)?)\.?\s*(\d{1,3})')
      if(-not $pS.Success){ return 'yok' }   # paragraf gostermeyen standart atfi kabul edilmez
      $stdAd=$sm.Groups[1].Value.ToUpperInvariant(); $stdNo=$sm.Groups[2].Value; $par=$pS.Groups[1].Value
      $sonuc = AmbarSorgu ("*"+$stdAd+" "+$stdNo+" p."+$par+"*") ('(?i)'+$stdAd+'\s*'+$stdNo+'\s+p\.'+$par+'($|[^0-9])')
      if($sonuc -ne 'ok'){ return $sonuc }
    }
    return 'ok'
  }
  # MSUGT / TEKDUZEN TEYIDI: "THP 780" hesap kodu veya "MSUGT ... donemsellik" kavrami
  if($f -match 'msugt|tekduzen|hesap plani|thp'){
    $mH=[regex]::Match($f,'(?<!\d)([1-7]\d{2})(?!\d)')
    if($mH.Success){
      $filtre="*THP "+$mH.Groups[1].Value+"*"
      try{ $u="$SB_URL/rest/v1/dokumanlar?kaynak_ad=ilike."+[uri]::EscapeDataString($filtre)+"&select=id&limit=1"
        $r=Invoke-RestMethod -Uri $u -Headers @{apikey=$SB_ANON;Authorization="Bearer $SB_ANON"} -TimeoutSec 30
        if(@($r).Count -ge 1){ return 'ok' } else { return 'yok' } }catch{ return 'atla' }
    }
    # ILKE YOLU (23.07): "MSUGT ... bilanco/gelir tablosu ilkeleri" — msugt-ilkeler.json ambarda
    if($f -match 'ilke'){
      $hedefIlke = $(if($f -match 'bilanco'){ 'bilanco' } elseif($f -match 'gelir tablosu'){ 'gelir' } else { $null })
      if(-not $hedefIlke){ return 'yok' }
      try{
        $u="$SB_URL/rest/v1/dokumanlar?kaynak_ad=ilike."+[uri]::EscapeDataString('*MSUGT*ilke*')+"&select=kaynak_ad&limit=40"
        $r=Invoke-RestMethod -Uri $u -Headers @{apikey=$SB_ANON;Authorization="Bearer $SB_ANON"} -TimeoutSec 30
        foreach($x in @($r)){ if((Fold $x.kaynak_ad) -match $hedefIlke){ return 'ok' } }
        return 'yok'
      }catch{ return 'atla' }
    }
    # KAVRAM YOLU — 23.07 dersi: ambar kaynak_ad'i AKSANLI ('Dönemsellik Kavramı'),
    # ilike 'donemsellik' tutmaz (Postgres'te o != ö). Adaylar cekilir, katlanmis
    # (aksansiz) karsilastirma YERELDE yapilir.
    $kavramlar=@('donemsellik','ihtiyatlilik','onemlilik','ozun onceligi','tam aciklama','tutarlilik','sosyal sorumluluk','kisilik','isletmenin surekliligi','parayla olculme','maliyet esasi','tarafsizlik')
    $bulunan=$null; foreach($kv in $kavramlar){ if($f -match [regex]::Escape($kv)){ $bulunan=$kv; break } }
    if(-not $bulunan){ return 'yok' }
    try{
      $u="$SB_URL/rest/v1/dokumanlar?kaynak_ad=ilike."+[uri]::EscapeDataString('*MSUGT*kavram*')+"&select=kaynak_ad&limit=25"
      $r=Invoke-RestMethod -Uri $u -Headers @{apikey=$SB_ANON;Authorization="Bearer $SB_ANON"} -TimeoutSec 30
      $hedefKok=($bulunan -split ' ')[0]
      foreach($x in @($r)){ if((Fold $x.kaynak_ad) -match [regex]::Escape($hedefKok)){ return 'ok' } }
      return 'yok'
    }catch{ return 'atla' }
  }
  # TEORI NOTU TEYIDI: resmi metni olmayan ders alanlari (mali analiz, maliyet
  # muhasebesi yontemleri, mikroekonomi) veri/mevzuat/teori-notu.json kurasyonuna
  # baglanir; ambarda karsiligi olmayan teori kaynagi 'yok' doner (SIKI MOD RET).
  if($f -match 'teori notu|dikey (yuzde|analiz)|yatay analiz|trend analiz|likidite|cari oran|asit.test|nakit orani|birlesik maliyet|ortak maliyet|yan urun|normal maliyet(?! bedel)|tam maliyet|degisken maliyet|asal maliyet|atil kapasite|bos kapasite|esnekli|elasti|piyasa dengesi|tavan fiyat|taban fiyat|arz fazlasi|talep fazlasi|arz.talep|gsyh|milli gelir|gayri safi|enflasyon|deflasyon|stagflasyon|para politika|acik piyasa islem|zorunlu karsilik|reeskont|dolayli vergi|dolaysiz vergi|spesifik vergi|advalorem|artan oranli|verginin yansimasi|yardimci hesap|muavin|kayit detayi|toplulastir'){
    $notlar=[ordered]@{
      'dikey (yuzde|analiz)|yatay analiz|trend analiz'='dikey'
      'likidite|cari oran|asit.test|nakit orani'='oran'
      'birlesik maliyet|ortak maliyet|yan urun'='birlesik'
      'normal maliyet|tam maliyet|degisken maliyet|asal maliyet|atil kapasite|bos kapasite'='normal'
      'esnekli|elasti'='talep'
      'piyasa dengesi|tavan fiyat|taban fiyat|arz fazlasi|talep fazlasi|arz.talep'='arz'
      'gsyh|milli gelir|gayri safi'='gsyh'
      'enflasyon|deflasyon|stagflasyon'='enflasyon'
      'para politika|acik piyasa islem|zorunlu karsilik|reeskont'='para'
      'dolayli vergi|dolaysiz vergi|spesifik vergi|advalorem|artan oranli|verginin yansimasi|vergi teorisi'='vergi teorisi'
      'yardimci hesap|muavin|kayit detayi|toplulastir'='yardimci'
    }
    $hedefNot=$null; foreach($nk in $notlar.Keys){ if($f -match $nk){ $hedefNot=$notlar[$nk]; break } }
    if(-not $hedefNot){ return 'yok' }
    $filtre='*Teori Notu*'+$hedefNot+'*'
    try{ $u="$SB_URL/rest/v1/dokumanlar?kaynak_ad=ilike."+[uri]::EscapeDataString($filtre)+"&select=id&limit=1"
      $r=Invoke-RestMethod -Uri $u -Headers @{apikey=$SB_ANON;Authorization="Bearer $SB_ANON"} -TimeoutSec 30
      if(@($r).Count -ge 1){ return 'ok' } else { return 'yok' } }catch{ return 'atla' }
  }
  if($f -match 'gut|teblig|karar|yonetmelik|genelge'){ return 'atla' }
  $no=$null; $mN=[regex]::Match($f,'(?<!\d)(\d{3,4})(?!\d)\s*(s\.|sayili)'); if($mN.Success){ $no=$mN.Groups[1].Value }
  if(-not $no){ foreach($k in $KANUN_NO.Keys){ if($f -match ('(?<![a-z])'+[regex]::Escape($k)+'(?![a-z])')){ $no=$KANUN_NO[$k]; break } } }
  if(-not $no){ return 'atla' }
  $on=''; if($f -match 'muk(\.|errer)'){ $on='muk. ' } elseif($f -match 'gec(\.|ici)'){ $on='gec. ' } elseif($f -match '(?<![a-z])ek\s*m'){ $on='ek ' }
  # 23.07 dersi: "m.10/a" gibi BENT atfinda ambar kaydi "m.10 - ..." oldugundan
  # haksiz RET yeniyordu; teyit MADDE duzeyinde yapilir (bent metni maddenin icinde).
  $mM=[regex]::Match($kaynak,'m(?:adde)?\.?\s*(\d+)'); if(-not $mM.Success){ return 'atla' }
  $md=$mM.Groups[1].Value
  # duz madde aranirken "muk./gec./ek" kayitlarina yanlis teyit olmasin
  $onDesen=$(if($on){ [regex]::Escape($on) } else { '(?<!muk\.\s)(?<!gec\.\s)(?<!ek\s)' })
  return AmbarSorgu ("*$no*"+$on+"m."+$md+"*") ('(?i)'+$onDesen+'m\.'+$md+'($|[^0-9A-Za-z])')
}

# KILITLI HAVUZ: Supabase'e tasinan paket sorulari da kok-tekrar ve doygunluk
# hesabina girer (yoksa ayni sorular yeniden uretilirdi). Service key yalniz
# Actions ortaminda vardir; yerelde/anahtarsiz zarifce atlanir.
$havuzSorular = @()
if($env:SUPABASE_SERVICE_KEY){
  try {
    $hh = @{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization="Bearer $($env:SUPABASE_SERVICE_KEY)" }
    $havuzSorular = @(Invoke-RestMethod -Uri "$SB_URL/rest/v1/soru_havuzu?select=soru,ders,konu&limit=10000" -Headers $hh -TimeoutSec 60)
    Write-Host ("Kilitli havuzdan {0} soru cekildi (kok/doygunluk)." -f $havuzSorular.Count)
  } catch { Write-Host "Kilitli havuz cekilemedi (tablo henuz kurulmamis olabilir) - devam." }
}

# HARITA: en cok soru getiren konular (mevcut bankada az temsil edilenler oncelikli)
# MESLEK ODAGI: Yabanci Dil ve Genel Kultur uretim hedefi DEGIL — kozumuz
# kaynak-maddeli meslek sorulari (Muhasebe/Hukuk/Ekonomi/Maliye/Mat-Ist).
$HARIC_DERS = @('Yabanci Dil','Genel Kultur-Genel Yetenek')
# konu anahtari: "SINAV|ders|konu" — SGS + SMMM Yeterlilik AYNI fabrikadan beslenir
$konular=@{}
foreach($dn in $analiz.donemler){ foreach($p in $dn.konuSayim.PSObject.Properties){
  $dAd = ($p.Name -split '\|')[0]
  if($HARIC_DERS -contains $dAd){ continue }
  $konular["SGS|"+$p.Name]=[int]$konular["SGS|"+$p.Name]+[int]$p.Value } }
$analizSYol = Join-Path $kok "veri/smmm-analiz.json"
if(Test-Path $analizSYol){
  try {
    $analizS = Get-Content $analizSYol -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach($dn in @($analizS.donemler)){ foreach($p in $dn.konuSayim.PSObject.Properties){
      $konular["SMMM|"+$p.Name]=[int]$konular["SMMM|"+$p.Name]+[int]$p.Value } }
    Write-Host ("Yeterlilik haritasi da hedefte: {0} donem-ders." -f @($analizS.donemler).Count)
  } catch { Write-Host "smmm-analiz okunamadi - yalniz SGS hedeflenecek." }
}
$bankaSay=@{}
foreach($s in (@($banka.sorular)+$yayinSorular+$havuzSorular+$bekleyenFabrika)){ $kk="$($s.ders)|$($s.konu)"; $bankaSay[$kk]=1+[int]$bankaSay[$kk] }
# 23.07 Cem karari (pazarlama): konu basi sabit 10 tavan urunu SIGLASTIRIR — uye,
# tikandigi konuyu acip 20 soruda dibi gorurse "bir gunluk uyelik" hisseder.
# Yeni duzen: SINAV AGIRLIGIYLA orantili derinlik — cekirdek konu 50'ye kadar,
# kiyi konu 12. Derinlik = KOPYA degil: uretim istemi, konudaki MEVCUT ACILARI
# gorur ve bunlardan FARKLI aci uretmeye zorlanir (asagida aciBlok).
function KonuHedefi($agirlik){ return [Math]::Min(120, [Math]::Max(15, [int][Math]::Round($agirlik * 3))) }   # 23.07 Cem: "50 az, acilisi ertele doldur" — cekirdek 60-120, kiyi 15
$hedefler = $konular.GetEnumerator() | Sort-Object { -($_.Value) } | Where-Object { [int]$bankaSay[($_.Key -split '\|',2)[1]] -lt (KonuHedefi $_.Value) } | Select-Object -First $KONU_LIMIT
if(-not $hedefler){ Write-Host "Tum konular agirlikli derinlik hedefine ulasti - banka doygun."; exit 0 }

$mevcutKokler = @(@($banka.sorular)+$yayinSorular+$havuzSorular+$bekleyenFabrika) | ForEach-Object { (Fold $_.soru).Substring(0, [Math]::Min(60, (Fold $_.soru).Length)) }
# yeniListe YALNIZ bu kosunun urunlerini tutar (eski banka tasinmaz - kosu dosyasi bagimsiz)
$yeniListe = New-Object System.Collections.Generic.List[object]
$rapor = New-Object System.Collections.Generic.List[string]

foreach($h in $hedefler){
  $parca = $h.Key -split '\|'; $sinavAd=$parca[0]; $ders=$parca[1]; $konu=$parca[2]
  $sinavTanim = if($sinavAd -eq 'SMMM'){ "TURMOB-TESMER SMMM Yeterlilik Sinavi (2026/1'den beri coktan secmeli test)" } else { "TESMER Staja Giris Sinavi (SGS)" }
  Write-Host ("=== [{0}] {1} / {2} (haritada {3} soru getirmis; hedef derinlik {4}) icin {5} ozgun soru uretiliyor..." -f $sinavAd,$ders,$konu,$h.Value,(KonuHedefi $h.Value),$ADET)
  # 23.07: derinlik-kopya dengesi — konudaki MEVCUT sorularin ilk cumleleri isteme
  # verilir; uretici ayni hukmu ayni aciyla TEKRAR soramaz (mukerrer RET israfi biter).
  $konuAnahtar = "$ders|$konu"
  $mevcutAcilar = @((@($banka.sorular)+$yayinSorular+$havuzSorular+$bekleyenFabrika) | Where-Object { "$($_.ders)|$($_.konu)" -eq $konuAnahtar } | ForEach-Object { $sMet = ("$($_.soru)" -replace '\s+',' '); $sMet.Substring(0, [Math]::Min(110, $sMet.Length)) } | Select-Object -First 14)
  $aciBlok = if(@($mevcutAcilar).Count -gt 0){ "BU KONUDA BANKADA ZATEN SU ACILARDAN SORULAR VAR (ilk cumleleri):`n- " + ($mevcutAcilar -join "`n- ") + "`nBunlarin HICBIRIYLE ortusmeyen, FARKLI bir hukum/fikra/islem asamasi/hesap/senaryo acisi isleyen sorular uret; ayni hukmu ayni aciyla tekrar SORMA.`n" } else { "" }
  $uIstem = @"
Sen $sinavTanim tarzinda OZGUN coktan secmeli soru yazan uzman bir egitimcisin. Ders: $ders · Konu: $konu
$ADET adet ORTA-ZOR seviye, birbirinden farkli soru yaz. CIKMIS SORU KOPYALAMA - tamamen ozgun kurgular.
$aciBlok
KURALLAR:
1) 5 sik (A-E), TEK dogru cevap; celdirici siklar tipik ogrenci hatalarindan kurulsun.
2) aciklama alaninda HER sikkin neden dogru/yanlis oldugunu yaz — ama YARGI degil DERS: her yanlis sik belirli bir YANILGIYI temsil etmeli ve aciklamasi o yanilgiyi COZMELI. Ornek: ogrenci 653 yerine 780 sasirdiysa 'yanlistir, 780 olmali' DEME; 653 ile 780 arasindaki KAVRAM FARKINI ogret (biri is yaptirmanin, digeri para bulmanin maliyeti). Sikki seceni 'neyi bildigi, neyi karistirdigi' uzerinden yakala.
3) kaynak alanina dayandigi SPESIFIK kanun maddesini yaz (or. VUK m.323, TTK m.68). Madde uyduramazsin.
4) Yila gore degisen TUTAR sorma (asgari ucret kac TL gibi) - oran, sure, ilke, hesap mantigi sor. Ornek islem tutari (10.000 TL'lik mal gibi) SERBEST.
5) Sade, kitapcik Turkcesiyle.
6) hap alanina konunun 3-4 cumlelik OZ ANLATIMINI yaz: soruyu yanlis yapan kisi bu paragrafi okuyunca konuyu ogrenmis olsun (kural + ipucu/tuzak). Ders kitabi degil, hap: net, ezber degil mantik.
7) Soru bir MUHASEBE KAYDI/hesap isleyisi soruyorsa, dogru kaydin gorselini "yevmiye" alaninda ver: [{"hesap":"102 Bankalar","borc":88000,"alacak":0},...] — borclananlar once, alacaklananlar sonra. Kayit sorusu degilse yevmiye alanini HIC koyma.
SADECE su JSON dizisini dondur:
[{"soru":"...","siklar":{"A":"...","B":"...","C":"...","D":"...","E":"..."},"dogru":"A","aciklama":{"A":"...","B":"...","C":"...","D":"...","E":"..."},"kaynak":"...","hap":"...","yevmiye":[...]}]
"@
  # 23.07 dersi: 8000 token 5 soru + hap anlatimlara DAR geldi, JSON yarida kesildi
  # (6 konudan 4'u URETIM/JSON hatasiyla dustu). 16000'e cikarildi + API sigortasi.
  $ham = $null
  try { $ham = Claude $uIstem 16000 $MODEL_URET } catch { $rapor.Add("API HATASI: $konu ($($_.Exception.Message))"); continue }
  # 23.07 dersi (#5 kosusu): cikti token sinirinda kesilirse dizi/JSON bozuk kaliyor,
  # tum konu copten gidiyordu. Yeni: once normal ayristir; olmazsa dengeli-parantez
  # deseniyle TAMAMLANMIS soru nesnelerini tek tek kurtar (yarim nesne atilir).
  $uretilen = @()
  $js = JsonBul $ham
  if($js){ try{ $uretilen = @($js | ConvertFrom-Json) }catch{} }
  if(@($uretilen).Count -eq 0 -and $ham){
    foreach($mK in [regex]::Matches($ham,'\{(?>[^{}]+|\{(?<d>)|\}(?<-d>))*(?(d)(?!))\}')){
      try{ $oK = $mK.Value | ConvertFrom-Json; if($oK.soru -and $oK.siklar -and $oK.dogru){ $uretilen += $oK } }catch{}
    }
    if(@($uretilen).Count -gt 0){ $rapor.Add("KURTARILDI (kesik ciktidan $(@($uretilen).Count) tam soru): $konu") }
  }
  if(@($uretilen).Count -eq 0){ $rapor.Add("URETIM HATASI (JSON kurtarilamadi): $konu"); continue }

  foreach($s in @($uretilen)){
    $kokOzet = (Fold $s.soru); $kokOzet = $kokOzet.Substring(0,[Math]::Min(60,$kokOzet.Length))
    # KAPI 5: kok tekrari
    if($mevcutKokler -contains $kokOzet){ $rapor.Add("RET (tekrar): $($s.soru.Substring(0,[Math]::Min(40,$s.soru.Length)))"); continue }
    # KAPI 4: yil-degisen KANUNI tutar (ornek islem tutarlari SERBEST — muhasebe
    # hesap sorusu tutarsiz olmaz; yasak olan "asgari ucret/had/istisna kac TL" tipi,
    # her yil guncellenen mevzuat tutarini ezber soran soru). 22.07 dersi: eski hal
    # TUM TL'li sorulari kesiyordu -> fabrika 0 uretti.
    $tumMetin = "$($s.soru) " + (($s.siklar.PSObject.Properties.Value) -join ' ')
    if($tumMetin -match '(?i)(asgari ucret|asgari ücret|istisna tutar|had{1,2}i|beyan sinir|beyan sınır|tavan tutar|maktu|yeniden degerleme oran|yeniden değerleme oran|fatura duzenleme sinir|fatura düzenleme sınır|defter tutma had)' -and $tumMetin -match '(TL|lira)'){
      $rapor.Add("RET (yil-degisen kanuni tutar): $konu"); continue }
    # KAPI 3: ambar teyidi — SIKI MOD (Cem 23.07: "yutmadiysan yazma"):
    # kaynak ambardan TEYIT EDILEMIYORSA uretim YASAK. 'atla' (tebligat/standart/
    # teori gibi henuz yutulmamis kaynak) artik gecmez; o dersler ancak ilgili
    # metin ambara girince (standart-madde) acilir. YUTMA-LISTESI Sinav Teorisi Hatti.
    $at = AmbarTeyit $s.kaynak
    if($at -ne 'ok'){ $rapor.Add("RET (kaynak ambardan teyit edilemedi - once YUT): $($s.kaynak)"); continue }
    # KAPI 1+2: iki bagimsiz cozucu (cevapsiz soruyu cozer)
    $cIstem = "Su coktan secmeli soruyu coz. SADECE JSON: {`"cevap`":`"A-E arasi tek harf`"}`nSORU: $($s.soru)`nA) $($s.siklar.A)`nB) $($s.siklar.B)`nC) $($s.siklar.C)`nD) $($s.siklar.D)`nE) $($s.siklar.E)"
    $ok=$true
    foreach($t in 1,2){
      # 23.07 dersi: cozucu bazen JSON yerine duz "B" yaziyor, bos sayilip saglam soru kesiliyordu.
      # Yeni: once JSON dene, olmazsa ham metinden tek harfli cevabi yakala.
      $cv=$null; $hamC=$null
      # 23.07 dersi (#5 kosusu): cozucu API cagrisinin KENDISI patlarsa saglam soru
      # bos cevapla RET yeniyordu - bir kez yeniden dene, sonra pes et.
      foreach($den in 1,2){
        try{ $hamC = Claude $cIstem 200 $MODEL_COZ; break }catch{ if($den -lt 2){ Start-Sleep -Seconds 5 } }
      }
      if($hamC){ try{ $cv=((JsonBul $hamC) | ConvertFrom-Json).cevap }catch{} }
      if(-not $cv -and $hamC){ $mC=[regex]::Match($hamC.ToUpper(),'(?<![A-Z])([A-E])(?![A-Z])'); if($mC.Success){ $cv=$mC.Groups[1].Value } }
      if("$cv".Trim().ToUpper() -ne "$($s.dogru)".Trim().ToUpper()){ $ok=$false; $rapor.Add("RET (cozucu$t '$cv' != '$($s.dogru)'): $($s.soru.Substring(0,[Math]::Min(40,$s.soru.Length)))"); break }
    }
    if(-not $ok){ continue }
    $yeniListe.Add([pscustomobject]@{ id=[guid]::NewGuid().ToString().Substring(0,8); sinav=$sinavAd; ders=$ders; konu=$konu;
      soru=$s.soru; siklar=$s.siklar; dogru=$s.dogru; aciklama=$s.aciklama; kaynak=$s.kaynak; hap="$($s.hap)"; yevmiye=$s.yevmiye; ambar=$at;
      uretim=(Get-Date -Format "dd.MM.yyyy"); durum="onay-bekliyor" })
    $mevcutKokler += $kokOzet
    $rapor.Add("GECTI: [$konu] $($s.soru.Substring(0,[Math]::Min(50,$s.soru.Length)))...")
  }
}

# Kosu ciktisi ESSIZ dosyaya (cakisma imkansiz); rapor her kosuda yazilir (sessiz kosu yasak)
if(-not (Test-Path $fabrikaDir)){ New-Item -ItemType Directory -Force $fabrikaDir | Out-Null }
$ciktiYol = Join-Path $fabrikaDir ("uretim-" + (Get-Date -Format 'yyyyMMdd-HHmmss') + ".json")
$cikti = [ordered]@{
  uretim = (Get-Date -Format "dd.MM.yyyy HH:mm")
  sonKosuRaporu = @($rapor | Select-Object -Last 40)
  sorular = $yeniListe.ToArray()
}
[IO.File]::WriteAllText($ciktiYol, ($cikti | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false)))
Write-Host "--- RAPOR ---"; $rapor | ForEach-Object { Write-Host "  $_" }
Write-Host ("KOSU URUNU: {0} yeni soru -> {1}" -f $yeniListe.Count, (Split-Path $ciktiYol -Leaf))
exit 0
