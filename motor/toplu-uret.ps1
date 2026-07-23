# ============================================================================
#  TOPLU GECE URETIMI — Anthropic Message Batches API (%50 indirimli) ile
#  TUM eksik konulara TEK SEFERDE uretim gorevi basar (23.07 Cem: "1500 az,
#  bir gunde bitirecek islem yok mu" -> var, bu). Damla-damla cron fabrikasinin
#  yaninda, banka doldurma hamlesi olarak elle/tetikle kosturulur.
#  AKIS: hedef konulari cikar (agirlikli derinlik, KonuHedefi ile ayni formul)
#   -> her konu icin 1-3 uretim gorevi (6'sar soru) -> tek batch'e gonder
#   -> bitene kadar bekle (poll) -> sonuclari indir -> AYNI 5 KAPIDAN gecir
#   -> veri/fabrika/toplu-*.json (cakismaz kanal; GM denetimi sonrasi kasa).
#  KAPILAR soru-uret.ps1 ile birebir ayni (kopya blok - degisiklikte IKISINI guncelle).
#  ENV: ANTHROPIC_API_KEY zorunlu; SUPABASE_SERVICE_KEY istege (havuz doygunluk).
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$MODEL_URET = "claude-sonnet-5"
$MODEL_COZ  = "claude-haiku-4-5-20251001"
$ADET = 6
$MAX_GOREV = 600          # 23.07 Cem "bugun bitirsin": dalga basi 600 gorev x 6 = 3.600 aday; gecede 5 dalga
$KONU_GECE_TAVANI = 18    # tek konuya gecede en fazla 18 soru (cesitlilik korunur)
$key = $env:ANTHROPIC_API_KEY
if(-not $key){ Write-Host "ANTHROPIC_API_KEY yok - atlandi."; exit 0 }

$analiz = Get-Content (Join-Path $kok "veri/sgs-analiz.json") -Raw -Encoding UTF8 | ConvertFrom-Json
$banka = if(Test-Path (Join-Path $kok "veri/soru-bankasi-onay.json")){ Get-Content (Join-Path $kok "veri/soru-bankasi-onay.json") -Raw -Encoding UTF8 | ConvertFrom-Json } else { [pscustomobject]@{ sorular=@() } }
$yayinSorular = @(); $yy = Join-Path $kok "veri/soru-bankasi.json"; if(Test-Path $yy){ try { $yayinSorular = @((Get-Content $yy -Raw -Encoding UTF8 | ConvertFrom-Json).sorular) } catch {} }
$fabrikaDir = Join-Path $kok "veri/fabrika"
$bekleyenFabrika = @()
if(Test-Path $fabrikaDir){ Get-ChildItem $fabrikaDir -Filter *.json | ForEach-Object { try { $bekleyenFabrika += @((Get-Content $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json).sorular) } catch {} } }

function Fold($s){ return ("$s".ToLowerInvariant().Trim() -replace 'ç','c' -replace 'ğ','g' -replace 'ı','i' -replace 'ö','o' -replace 'ş','s' -replace 'ü','u' -replace '\s+',' ') }
function JsonBul($t){ $m=[regex]::Match($t,'(?s)\[.*\]'); if($m.Success){ return $m.Value }; $m2=[regex]::Match($t,'(?s)\{.*\}'); if($m2.Success){ return $m2.Value }; return $null }

# ---- AMBAR TEYIDI (soru-uret.ps1 kopyasi - degisirse IKISINI guncelle) ----
$SB_URL="https://bjrleanjpyujtajmazxn.supabase.co"; $SB_ANON="sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg"
$KANUN_NO=[ordered]@{ 'kvkk'='6698'; 'vuk'='213'; 'gvk'='193'; 'kdvk'='3065'; 'kdv'='3065'; 'kvk'='5520'; 'ttk'='6102'; 'smk'='6769'; 'aatuhk'='6183'; 'otv'='4760'; 'iik'='2004'; 'tbk'='6098'; 'isg'='6331' }
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
  $stdMatches=[regex]::Matches($f,'(?<![a-z])(tms|tfrs|bds)\s*(\d{1,3})')
  if($stdMatches.Count -ge 1){
    for($si=0; $si -lt $stdMatches.Count; $si++){
      $sm=$stdMatches[$si]
      $bas=$sm.Index; $son=$(if($si+1 -lt $stdMatches.Count){ $stdMatches[$si+1].Index } else { $f.Length })
      $seg=$f.Substring($bas, $son-$bas)
      $stdAd=$sm.Groups[1].Value.ToUpperInvariant(); $stdNo=$sm.Groups[2].Value
      $ekM=[regex]::Match($seg,'(?<![a-z])ek[- ]?(\d)')
      if($ekM.Success){
        $ekNo=$ekM.Groups[1].Value
        $sonucEk = AmbarSorgu ("*"+$stdAd+" "+$stdNo+" Ek-"+$ekNo+"*") ('(?i)'+$stdAd+'\s*'+$stdNo+'\s+Ek-?'+$ekNo)
        if($sonucEk -ne 'ok'){ return $sonucEk }
        continue
      }      # 'md.' kisaltmasi da taninir (TMS 2 ambardayken "md. 12" atiflari bosuna yaniyordu)
      $pS=[regex]::Match($seg,'(?:p(?:aragraf)?|m(?:adde)?|md)\.?\s*(a?\d{1,3})')
      # 24.07 dalga-1 dersi: model "BDS 500.A25" yaziyor (p'siz A-paragrafi) - ambarda
      # "BDS 500 p.A25" olarak VAR ama eski desen yalniz rakam yakaladigi icin RET yaniyordu.
      # Aralikli atifta (A14-A25) tum adaylar denenir; BIRI ambarda varsa atif gecerli.
      $adaylar=@(); if($pS.Success){ $adaylar += $pS.Groups[1].Value }
      foreach($am in [regex]::Matches($seg,'[\s.,(-](a\d{1,3})')){ $adaylar += $am.Groups[1].Value }
      $adaylar = @($adaylar | Select-Object -Unique)
      if(-not $adaylar.Count){ return 'yok' }
      $sonuc='yok'
      foreach($par in $adaylar){
        $sonuc = AmbarSorgu ("*"+$stdAd+" "+$stdNo+" p."+$par+"*") ('(?i)'+$stdAd+'\s*'+$stdNo+'\s+p\.'+$par+'($|[^0-9])')
        if($sonuc -eq 'ok'){ break }
      }
      if($sonuc -ne 'ok'){ return $sonuc }
    }
    return 'ok'
  }
  # 24.07 dalga-1 dersi: model tebligi tam adiyla ("Muhasebe Sistemi Uygulama Genel Tebligi")
  # yazinca eski desen tanimiyordu - ambarda OLAN kaynak "teyitsiz" diye yaniyordu (53 RET'in cogu).
  if($f -match 'msugt|tekduzen|hesap plani|thp|muhasebe sistemi uygulama'){
    $mH=[regex]::Match($f,'(?<!\d)([1-7]\d{2})(?!\d)')
    if($mH.Success){
      $filtre="*THP "+$mH.Groups[1].Value+"*"
      try{ $u="$SB_URL/rest/v1/dokumanlar?kaynak_ad=ilike."+[uri]::EscapeDataString($filtre)+"&select=id&limit=1"
        $r=Invoke-RestMethod -Uri $u -Headers @{apikey=$SB_ANON;Authorization="Bearer $SB_ANON"} -TimeoutSec 30
        if(@($r).Count -ge 1){ return 'ok' } else { return 'yok' } }catch{ return 'atla' }
    }
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
  $mM=[regex]::Match($kaynak,'m(?:adde)?\.?\s*(\d+)'); if(-not $mM.Success){ return 'atla' }
  $md=$mM.Groups[1].Value
  $onDesen=$(if($on){ [regex]::Escape($on) } else { '(?<!muk\.\s)(?<!gec\.\s)(?<!ek\s)' })
  return AmbarSorgu ("*$no*"+$on+"m."+$md+"*") ('(?i)'+$onDesen+'m\.'+$md+'($|[^0-9A-Za-z])')
}
# ---- kopya blok sonu ----

$havuzSorular = @()
if($env:SUPABASE_SERVICE_KEY){
  try {
    $hh = @{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization="Bearer $($env:SUPABASE_SERVICE_KEY)" }
    $havuzSorular = @(Invoke-RestMethod -Uri "$SB_URL/rest/v1/soru_havuzu?select=soru,ders,konu&limit=10000" -Headers $hh -TimeoutSec 60)
    Write-Host ("Kilitli havuz: {0} soru." -f $havuzSorular.Count)
  } catch { Write-Host "Havuz cekilemedi - devam." }
}

# ---- hedef konular (agirlikli derinlik) ----
$DIL_DERSLER = @('Yabanci Dil','Genel Kultur-Genel Yetenek')   # 23.07 Cem: GK+YD ACILDI; mevzuat teyidi yerine dil-icerik kurali
$konular=@{}
foreach($dn in $analiz.donemler){ foreach($p in $dn.konuSayim.PSObject.Properties){
  $konular["SGS|"+$p.Name]=[int]$konular["SGS|"+$p.Name]+[int]$p.Value } }   # 23.07: GK+YD dahil (Cem karari)
$aS = Join-Path $kok "veri/smmm-analiz.json"
if(Test-Path $aS){ try { $x2 = Get-Content $aS -Raw -Encoding UTF8 | ConvertFrom-Json; foreach($dn in @($x2.donemler)){ foreach($p in $dn.konuSayim.PSObject.Properties){ $konular["SMMM|"+$p.Name]=[int]$konular["SMMM|"+$p.Name]+[int]$p.Value } } } catch {} }
function KonuHedefi($agirlik){ return [Math]::Min(120, [Math]::Max(15, [int][Math]::Round($agirlik * 3))) }
$tumSorular = @(@($banka.sorular)+$yayinSorular+$havuzSorular+$bekleyenFabrika)
$bankaSay=@{}
foreach($s in $tumSorular){ $kk="$($s.ders)|$($s.konu)"; $bankaSay[$kk]=1+[int]$bankaSay[$kk] }

$sabitIstem = @"
OZGUN coktan secmeli sinav sorusu yazacaksin. KURALLAR:
1) 5 sik (A-E), TEK dogru cevap; celdirici siklar tipik ogrenci hatalarindan kurulsun.
2) aciklama alaninda HER sikkin neden dogru/yanlis oldugunu yaz — ama YARGI degil DERS: her yanlis sik belirli bir YANILGIYI temsil etmeli ve aciklamasi o yanilgiyi COZMELI. Sikki seceni 'neyi bildigi, neyi karistirdigi' uzerinden yakala.
3) kaynak alanina dayandigi SPESIFIK kanun maddesini yaz (or. VUK m.323, TTK m.68). Madde uyduramazsin.
4) Yila gore degisen TUTAR sorma (asgari ucret kac TL gibi) - oran, sure, ilke, hesap mantigi sor. Ornek islem tutari SERBEST.
5) Soru koku sade, kitapcik Turkcesiyle ve sinav ciddiyetinde.
5b) DIL VE TON (24.07 Cem kurali): aciklama ve hap alanlarinda robot/ders-kitabi agzi YASAK - okuyan "bunu yapay zeka yazmis" dememeli. Her aciklamanin ILK cumlesi, konuyu hic bilmeyen birinin de ANINDA anlayacagi sadelikte olsun; teknik terim ancak o ilk cumleden sonra gelsin. Senaryolari gunluk hayattan, genclerin tanidigi dunyalardan kur (e-ticaret magazasi, kafe, yazilimci, kurye, oyun sirketi, sosyal medya ajansi vb.). Yer yer ZEKI ve HAFIF bir espri/benzetme serbest ve makbul - ama abartmadan, her soruda degil, dogal dustugu yerde; siyaset/tartismali guncel olay ASLA.
6) hap alanina konunun 3-4 cumlelik OZ ANLATIMINI yaz (kural + ipucu/tuzak).
7) MUHASEBE KAYDI sorusuysa dogru kaydi "yevmiye" alaninda ver: [{"hesap":"...","borc":0,"alacak":0},...]. Kayit sorusu degilse yevmiye koyma.
7b) TABLO/ANALIZ sorusuysa (dikey-yatay analiz, oran analizi, gelir tablosu/bilanco kalemi hesabi) hesabi LAFLA degil TABLO USTUNDE goster - "tablo" alaninda mini tabloyu ver: {"baslik":"Gelir Tablosu (dikey %)","kolonlar":["Kalem","Tutar","Dikey %"],"satirlar":[["Brut Satislar","2.500.000",""],["NET SATISLAR","2.000.000","%100 (baz)"],["SMM (-)","1.200.000","%60 ←"]]}. Cevabin ciktigi satirin son hucresine '←' koy (ekran o satiri vurgular). Tablo sorusu degilse tablo alani koyma.
7c) HAYALET KAYIT: muhasebe kaydi sorusunda celdirici siklardan biri ALTERNATIF bir kaydi temsil ediyorsa, o sikkin ima ettigi YANLIS kaydi "yanlisKayitlar" alaninda ver: {"B":[{"hesap":"...","borc":0,"alacak":0}]} - ekran bunu soluk 'hayalet' olarak gosterir (senin cevabin defterde boyle olurdu). Yalniz gercekten kayit ima eden celdiriciler icin; digerlerini koyma.
CIKMIS SORU KOPYALAMA. SADECE su JSON dizisini dondur:
[{"soru":"...","siklar":{"A":"...","B":"...","C":"...","D":"...","E":"..."},"dogru":"A","aciklama":{"A":"...","B":"...","C":"...","D":"...","E":"..."},"kaynak":"...","hap":"...","yevmiye":[...],"tablo":{...},"yanlisKayitlar":{...}}]
"@

$gorevler = New-Object System.Collections.Generic.List[object]
$hedefListe = $konular.GetEnumerator() | Sort-Object { -($_.Value) }
foreach($h in $hedefListe){
  if($gorevler.Count -ge $MAX_GOREV){ break }
  $parca = $h.Key -split '\|'; $sinavAd=$parca[0]; $ders=$parca[1]; $konu=$parca[2]
  $konuAnahtar = "$ders|$konu"
  $mevcut = [int]$bankaSay[$konuAnahtar]
  $hedef = KonuHedefi $h.Value
  $eksik = [Math]::Min($KONU_GECE_TAVANI, $hedef - $mevcut)
  if($eksik -le 0){ continue }
  $gorevSayisi = [Math]::Ceiling($eksik / $ADET)
  $sinavTanim = if($sinavAd -eq 'SMMM'){ "TURMOB-TESMER SMMM Yeterlilik Sinavi (test)" } else { "TESMER Staja Giris Sinavi (SGS)" }
  $mevcutAcilar = @($tumSorular | Where-Object { "$($_.ders)|$($_.konu)" -eq $konuAnahtar } | ForEach-Object { $sM = ("$($_.soru)" -replace '\s+',' '); $sM.Substring(0, [Math]::Min(110, $sM.Length)) } | Select-Object -First 14)
  for($g=1; $g -le $gorevSayisi -and $gorevler.Count -lt $MAX_GOREV; $g++){
    $aciBlok = if(@($mevcutAcilar).Count -gt 0){ "BU KONUDA BANKADA ZATEN SU ACILARDAN SORULAR VAR (ilk cumleleri):`n- " + ($mevcutAcilar -join "`n- ") + "`nBunlarin HICBIRIYLE ortusmeyen, FARKLI hukum/fikra/islem asamasi/hesap/senaryo acilari isle. Gorev no: $g (ayni konunun diger gorevlerinden de FARKLI acilar sec)." } else { "Gorev no: $g." }
    $dersYonerge = if($ders -eq 'Yabanci Dil'){ "OZEL: Bu bir YABANCI DIL (Ingilizce) sorusudur - soru koku ve siklar INGILIZCE yazilir (SGS YD tarzi: kelime bilgisi, dil bilgisi, cumle tamamlama, okudugunu anlama); aciklama ve hap alanlari TURKCE ogretir. kaynak alanina dayandigi DIL BILGISI KURALININ adini yaz (or. 'Present Perfect Tense kullanim kurali'). Kanun maddesi ARANMAZ." } elseif($ders -eq 'Genel Kultur-Genel Yetenek'){ "OZEL: Bu bir GENEL KULTUR-GENEL YETENEK sorusudur - Turkce dil bilgisi/anlam/paragraf/anlatim bozuklugu VEYA temel matematik-mantik. kaynak alanina dayandigi KURALIN adini yaz (or. 'TDK buyuk harflerin kullanimi kurali', 'oran-oranti kurali'). Kanun maddesi ARANMAZ. Guncel siyaset/tartismali guncel olay SORMA." } else { "" }
    $degisken = "GOREV: $sinavTanim icin soru yaz. Ders: $ders · Konu: $konu`n$ADET adet ORTA-ZOR seviye, birbirinden farkli soru yaz.`n$dersYonerge`n$aciBlok"
    $gorevler.Add([ordered]@{
      custom_id = "g" + $gorevler.Count.ToString("000")   # yalniz [a-zA-Z0-9_-] gecerli; '|' API'den 400 dondurttu (ilk kosu dersi)
      params = [ordered]@{
        model = $MODEL_URET; max_tokens = 16000
        messages = @(@{ role="user"; content=@(
          @{ type="text"; text=$sabitIstem; cache_control=@{ type="ephemeral" } },
          @{ type="text"; text=$degisken }) })
      }
      meta = @{ sinav=$sinavAd; ders=$ders; konu=$konu }
    })
  }
}
if($gorevler.Count -eq 0){ Write-Host "Tum konular derinlik hedefinde - toplu uretime gerek yok."; exit 0 }
Write-Host ("TOPLU BATCH: {0} gorev (~{1} aday soru) gonderiliyor..." -f $gorevler.Count, ($gorevler.Count * $ADET))

# meta'yi ayri sakla (API'ye gitmez), custom_id ile eslestirecegiz
$metaMap = @{}
$istekler = @()
foreach($gr in $gorevler){ $metaMap[$gr.custom_id] = $gr.meta; $istekler += [ordered]@{ custom_id=$gr.custom_id; params=$gr.params } }
$batchBody = @{ requests = $istekler } | ConvertTo-Json -Depth 12 -Compress
$H = @{ "x-api-key"=$key; "anthropic-version"="2023-06-01" }
$batch = Invoke-RestMethod -Method Post -Uri "https://api.anthropic.com/v1/messages/batches" -Headers $H -Body ([Text.Encoding]::UTF8.GetBytes($batchBody)) -ContentType "application/json" -TimeoutSec 300
Write-Host ("Batch id: {0} durum: {1}" -f $batch.id, $batch.processing_status)

# poll (en fazla ~5 saat; batch'ler cogunlukla <1 saatte biter)
$sonDurum = $batch
for($i=0; $i -lt 300; $i++){
  Start-Sleep -Seconds 60
  $sonDurum = Invoke-RestMethod -Uri ("https://api.anthropic.com/v1/messages/batches/" + $batch.id) -Headers $H -TimeoutSec 60
  Write-Host ("  [{0}dk] durum: {1} (islenen: {2})" -f ($i+1), $sonDurum.processing_status, ($sonDurum.request_counts | ConvertTo-Json -Compress))
  if($sonDurum.processing_status -eq 'ended'){ break }
}
if($sonDurum.processing_status -ne 'ended'){ Write-Host "HATA: batch suresinde bitmedi - kosu kirmizi."; exit 1 }

$sonuclarHam = Invoke-RestMethod -Uri $sonDurum.results_url -Headers $H -TimeoutSec 300
# results JSONL string olarak gelir; satir satir parse
$satirlar = if($sonuclarHam -is [string]){ $sonuclarHam -split "`n" | Where-Object { $_.Trim() } } else { @($sonuclarHam) }

function Claude($istem,$maxtok,$model){
  $body = @{ model=$model; max_tokens=$maxtok; messages=@(@{ role="user"; content=$istem }) } | ConvertTo-Json -Depth 6 -Compress
  $r = Invoke-RestMethod -Method Post -Uri "https://api.anthropic.com/v1/messages" -Headers $H -Body ([Text.Encoding]::UTF8.GetBytes($body)) -ContentType "application/json" -TimeoutSec 300
  return (@($r.content) | Where-Object { $_.type -eq 'text' } | ForEach-Object { $_.text }) -join ""
}
# 23.07 GEMINI CAPRAZ COZUCU (Cem kurulumu): cozucu-2 once Google Gemini'ye sorulur
# (bedava kota + FARKLI firmanin modeli = capraz dogrulama). Kota biterse/hata olursa
# aninda Haiku'ya duser - hat ASLA durmaz. Kota bitince gun boyu tekrar denenmez.
$script:gkey = $env:GEMINI_API_KEY
$script:geminiSayac = 0
function GeminiCoz($istem){
  if(-not $script:gkey){ return $null }
  try{
    $b = @{ contents = @(@{ parts = @(@{ text=$istem }) }) } | ConvertTo-Json -Depth 8 -Compress
    $r = Invoke-RestMethod -Method Post -Uri ("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=" + $script:gkey) -Body ([Text.Encoding]::UTF8.GetBytes($b)) -ContentType "application/json" -TimeoutSec 60
    $script:geminiSayac++
    return (@($r.candidates[0].content.parts) | ForEach-Object { $_.text }) -join ""
  }catch{
    if("$($_.Exception.Message)" -match '429|quota|RESOURCE_EXHAUSTED|Too Many'){ $script:gkey = $null; Write-Host "Gemini kotasi doldu - cozucu-2 Haiku'ya dondu." }
    return $null
  }
}

$mevcutKokler = @($tumSorular | ForEach-Object { (Fold $_.soru).Substring(0, [Math]::Min(60, (Fold $_.soru).Length)) })
$yeniListe = New-Object System.Collections.Generic.List[object]
$rapor = New-Object System.Collections.Generic.List[string]
$islenen = 0
foreach($satir in $satirlar){
  $sonuc = $null
  try { $sonuc = $satir | ConvertFrom-Json } catch { continue }
  $cid = $sonuc.custom_id
  $meta = $metaMap[$cid]; if(-not $meta){ continue }
  if($sonuc.result.type -ne 'succeeded'){ $rapor.Add("BATCH HATA ($cid $($meta.konu)): $($sonuc.result.type)"); continue }
  $ham = (@($sonuc.result.message.content) | Where-Object { $_.type -eq 'text' } | ForEach-Object { $_.text }) -join ""
  $islenen++
  $uretilen = @()
  $js = JsonBul $ham
  if($js){ try{ $uretilen = @($js | ConvertFrom-Json) }catch{} }
  if(@($uretilen).Count -eq 0 -and $ham){
    foreach($mK in [regex]::Matches($ham,'\{(?>[^{}]+|\{(?<d>)|\}(?<-d>))*(?(d)(?!))\}')){
      try{ $oK = $mK.Value | ConvertFrom-Json; if($oK.soru -and $oK.siklar -and $oK.dogru){ $uretilen += $oK } }catch{}
    }
    if(@($uretilen).Count -gt 0){ $rapor.Add("KURTARILDI ($($meta.konu)): $(@($uretilen).Count)") }
  }
  foreach($s in @($uretilen)){
    $kokOzet = (Fold $s.soru); $kokOzet = $kokOzet.Substring(0,[Math]::Min(60,$kokOzet.Length))
    if($mevcutKokler -contains $kokOzet){ $rapor.Add("RET (tekrar): $($meta.konu)"); continue }
    $tumMetin = "$($s.soru) $(@($s.siklar.PSObject.Properties.Value) -join ' ')"
    if($tumMetin -match '(asgari ücret|asgari ucret|yeniden değerleme oranı|had|istisna tutarı)[^.]{0,40}(kaç TL|kac TL|ne kadar)'){ $rapor.Add("RET (yil-degisen tutar): $($meta.konu)"); continue }
    # 23.07: dil dersleri (YD/GK) mevzuat maddesi gostermez - teyit yerine 'dil-icerik'
    # damgasi; kalite yuku cift cozucu + GM denetiminde. Meslek dersleri SIKI MOD aynen.
    $at = if($DIL_DERSLER -contains $meta.ders){ 'dil-icerik' } else { AmbarTeyit $s.kaynak }
    if($at -ne 'ok' -and $at -ne 'dil-icerik'){ $rapor.Add("RET (teyitsiz kaynak): $($s.kaynak)"); continue }
    $cIstem = "Su coktan secmeli soruyu coz. SADECE JSON: {`"cevap`":`"A-E arasi tek harf`"}`nSORU: $($s.soru)`nA) $($s.siklar.A)`nB) $($s.siklar.B)`nC) $($s.siklar.C)`nD) $($s.siklar.D)`nE) $($s.siklar.E)"
    $ok=$true
    foreach($t in 1,2){
      $cv=$null; $hamC=$null
      if($t -eq 2){ $hamC = GeminiCoz $cIstem }   # cozucu-2: once Gemini (capraz model, bedava)
      if(-not $hamC){ foreach($den in 1,2){ try{ $hamC = Claude $cIstem 200 $MODEL_COZ; break }catch{ if($den -lt 2){ Start-Sleep -Seconds 5 } } } }
      if($hamC){ try{ $cv=((JsonBul $hamC) | ConvertFrom-Json).cevap }catch{} }
      if(-not $cv -and $hamC){ $mC=[regex]::Match($hamC.ToUpper(),'(?<![A-Z])([A-E])(?![A-Z])'); if($mC.Success){ $cv=$mC.Groups[1].Value } }
      if("$cv".Trim().ToUpper() -ne "$($s.dogru)".Trim().ToUpper()){ $ok=$false; $rapor.Add("RET (cozucu$t '$cv' != '$($s.dogru)'): $($meta.konu)"); break }
    }
    if(-not $ok){ continue }
    $yeniListe.Add([pscustomobject]@{ id=[guid]::NewGuid().ToString().Substring(0,8); sinav=$meta.sinav; ders=$meta.ders; konu=$meta.konu;
      soru=$s.soru; siklar=$s.siklar; dogru=$s.dogru; aciklama=$s.aciklama; kaynak=$s.kaynak; hap="$($s.hap)"; yevmiye=$s.yevmiye; ambar=$at;
      uretim=(Get-Date -Format "dd.MM.yyyy"); durum="onay-bekliyor" })
    $mevcutKokler += $kokOzet
    $rapor.Add("GECTI: [$($meta.konu)] $($s.soru.Substring(0,[Math]::Min(50,$s.soru.Length)))...")
  }
}

if(-not (Test-Path $fabrikaDir)){ New-Item -ItemType Directory -Force $fabrikaDir | Out-Null }
$ciktiYol = Join-Path $fabrikaDir ("toplu-" + (Get-Date -Format 'yyyyMMdd-HHmmss') + ".json")
$cikti = [ordered]@{
  uretim = (Get-Date -Format "dd.MM.yyyy HH:mm") + " TOPLU GECE URETIMI (batch: " + $batch.id + ")"
  gorevSayisi = $gorevler.Count; islenenCevap = $islenen; geminiCozum = $script:geminiSayac
  sonKosuRaporu = @($rapor | Select-Object -Last 120)
  sorular = $yeniListe.ToArray()
}
[IO.File]::WriteAllText($ciktiYol, ($cikti | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false)))
Write-Host ("TOPLU URETIM BITTI: {0} gorev -> {1} soru 5 kapidan GECTI -> {2}" -f $gorevler.Count, $yeniListe.Count, (Split-Path $ciktiYol -Leaf))
exit 0
