# ============================================================================
#  ÇIKMIŞ SORU → DERS KALIBI (02.09.2026 — Cem: "sınavda sorulan soruları konu
#  konu ders ders ayrıştır, o kalıpta yapacağız")
#
#  NE YAPAR: Ambardaki çıkmış sınav kitapçıklarından soruları ayıklar, HER
#  SORUYU DERSE atar (anahtar kelime sınıflandırıcı, LLM'siz) ve ders bazında
#  gerçek kalıbı ölçer: gövde uzunluğu dağılımı, tip kırılımı (kayıt sorusu /
#  hesaplama / teori), tablo içerme oranı.
#  ÇIKTI: veri/cikmis-ders-kalibi.json  → üretici bu dosyadan ders tavanını okur.
#
#  NEDEN: 02.09 ölçümü — ürettiğimiz FMuh soruları gerçeğin 2 katı uzundu
#  (medyan 652 vs 315). Genel ortalama yanıltır; her dersin kendi kalıbı var.
#  KURAL: sınıflandırma güveni düşükse soru 'belirsiz'e düşer, kalıba GİRMEZ.
# ============================================================================
param(
  [string]$Sinav='SGS',
  [int]$KitapcikTavan=12
)
$ErrorActionPreference='Stop'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok=Split-Path -Parent $here
$KEY=$env:SUPABASE_SERVICE_KEY
if(-not $KEY){ throw 'SUPABASE_SERVICE_KEY yok.' }
$H=@{ apikey=$KEY; Authorization="Bearer $KEY"; 'User-Agent'='mevzuat-radar-robot/1.0' }
$SB='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar'

function Katla([string]$s){
  ("$s" -creplace 'İ','i' -creplace 'I','i' -creplace 'ı','i' -creplace 'Ğ','g' -creplace 'ğ','g' `
        -creplace 'Ü','u' -creplace 'ü','u' -creplace 'Ş','s' -creplace 'ş','s' `
        -creplace 'Ö','o' -creplace 'ö','o' -creplace 'Ç','c' -creplace 'ç','c').ToLowerInvariant()
}

# --- DERS SINIFLANDIRICI -----------------------------------------------------
# Her ders icin ANAHTAR desenler + agirlik. En yuksek puan kazanir; puan esigin
# altindaysa 'belirsiz' (kalip disi). Desenler KATLANMIS metne uygulanir.
$DERSLER=[ordered]@{
  'Turkce'              = @('cumle','sozcuk','anlatim bozuk','deyim','atasozu','paragraf','ek fiil','zarf','tumlec','noktalama','yazim','unlu uyum','unsuz')
  'Matematik'           = @('islemin sonucu','kactir','denklem','fonksiyon','limit','turev','integral','ucgen','koordinat','basamak','ebob','okek','yuzde kac','olasilik')
  'Ataturk Ilkeleri'    = @('ataturk','osmanli','kongre','inkilap','cumhuriyet','lozan','milli mucadele','tbmm','saltanat','harf devrimi','misak')
  'Yabanci Dil'         = @('which of the following','the sentence','according to the passage','complete the','best completes')
  'Finansal Muhasebe'   = @('yevmiye','muhasebe kayd','hesab[ıi]na','mizan','bilancoda yer','amortisman','reeskont','karsilik ayr','stok','alacak senedi','bono','police','kdv hesapla','doneme ait','tekduzen','aktiflestir','deger dusuklugu','hesap kalani','sermaye artir','kar dagitim')
  'Maliyet Muhasebesi'  = @('safha maliyet','siparis maliyet','esdeger urun','genel uretim gider','gug','standart maliyet','sapma','ortak maliyet','yan urun','direkt iscilik','direkt ilk madde','maliyet dagitim','birim maliyet')
  'Mali Tablolar Analizi'= @('oran analiz','cari oran','asit-test','likidite','devir hiz','kar marj','nakit akis','net calisma sermayesi','dikey yuzde','yatay analiz','kaldirac','ozkaynak karlilik','faaliyet kari oran')
  'Denetim'             = @('bds ','bagimsiz denet','denetci','denetim kanit','ornekleme','ic kontrol','onemli yanlislik','denetim riski','gorus','calisma kagit','teyit')
  'Ekonomi'             = @('arz egri','talep egri','piyasa denge','tekel','oligopol','esneklik','enflasyon','gsyh','issizlik','para politikasi','faiz oran','marjinal fayda','uretim imkan')
  'Maliye'              = @('kamu geliri','kamu harcama','butce','parafiskal','vergi yuku','transfer harcama','mali politika','laffer','vergi teori','operasyonel acik','borclanma')
  'Meslek Hukuku'       = @('3568','smmm','ymm','turmob','meslek mensub','oda','ruhsat','staj','disiplin','serbest muhasebeci')
  'Is ve Sosyal Guvenlik'= @('4857','is kanunu','is sozlesme','sendika','6356','5510','sosyal sigorta','kidem','ihbar','prim','isci')
  'Vergi Hukuku'        = @('213 sayili','vuk','3065','katma deger vergisi kanun','5520','kurumlar vergisi kanun','193','gelir vergisi kanun','damga vergisi','tarhiyat','vergi ziyai','uzlasma','beyanname ver')
  'Ticaret ve Borclar'  = @('6102','turk ticaret kanun','6098','turk borclar kanun','sirket tur','anonim sirket','limited sirket','ciro','kambiyo senet','sebepsiz zenginlesme','temsil','vekalet','haksiz fiil')
}
function DersBul([string]$govde){
  $k=Katla $govde
  $enIyi=''; $enPuan=0
  foreach($d in $DERSLER.Keys){
    $p=0
    foreach($desen in $DERSLER[$d]){ if($k -match [regex]::Escape($desen)){ $p++ } }
    if($p -gt $enPuan){ $enPuan=$p; $enIyi=$d }
  }
  if($enPuan -lt 1){ return @{ ders='belirsiz'; puan=0 } }
  return @{ ders=$enIyi; puan=$enPuan }
}
# --- SORU TIPI ---------------------------------------------------------------
function TipBul([string]$govde){
  $k=Katla $govde
  if($k -match 'muhasebe kayd|yevmiye|kayd[ıi] a[sş]a[gğ][ıi]dakilerden'){ return 'kayit' }
  if($govde -match '\d' -and $k -match 'kactir|ne kadar|tutari|hesaplay|bulunuz|kac ' ){ return 'hesaplama' }
  if($k -match 'asagidakilerden hangisi|hangisi yanlis|hangisi dogru'){ return 'teori' }
  return 'diger'
}

# --- KITAPCIKLARI CEK --------------------------------------------------------
$u1=$SB+'?select=kaynak_ad&kaynak_ad=ilike.'+[uri]::EscapeDataString("CIKMIS SINAV - $Sinav 20%")+"&limit=60&order=kaynak_ad.desc"
$y=Invoke-WebRequest -UseBasicParsing -Uri $u1 -Headers $H -TimeoutSec 120
$ham=ConvertFrom-Json -InputObject $y.Content
$adlar=@(@($ham) | ForEach-Object { "$($_.kaynak_ad)" } | Where-Object { $_ -and $_ -notmatch 'yabanci dil' })
Write-Host "kitapcik bulundu: $($adlar.Count) (islenecek: $([Math]::Min($KitapcikTavan,$adlar.Count)))"

$kayitlar=New-Object System.Collections.Generic.List[object]
foreach($ad in ($adlar | Select-Object -First $KitapcikTavan)){
  $u2=$SB+'?select=metin&kaynak_ad=eq.'+[uri]::EscapeDataString($ad)+'&limit=1'
  try{
    $y2=Invoke-WebRequest -UseBasicParsing -Uri $u2 -Headers $H -TimeoutSec 120
    $k2=@(ConvertFrom-Json -InputObject $y2.Content)
  }catch{ Write-Host "  ATLA (cekilemedi): $ad"; continue }
  if($k2.Count -eq 0 -or -not $k2[0].metin){ continue }
  $m="$($k2[0].metin)"
  $parca=@([regex]::Split($m,'(?m)^SORU\s+(\d{1,3})\s*:\s*'))
  $n=0
  for($i=1;$i -lt $parca.Count-1;$i+=2){
    $no=0; [void][int]::TryParse($parca[$i],[ref]$no)
    $b=$parca[$i+1]
    $sp=@([regex]::Split($b,'(?m)^\s{0,4}A\)\s'))
    if($sp.Count -lt 2){ continue }
    $g=$sp[0].Trim()
    if($g.Length -lt 25 -or $g.Length -gt 3000){ continue }
    $d=DersBul $g
    $kayitlar.Add([pscustomobject]@{
      kitapcik=$ad; no=$no; uzunluk=$g.Length; ders=$d.ders; guven=$d.puan
      tip=(TipBul $g); tabloVar=($g -match '(?m)^\s*[IVX]+\.|\t')
    })
    $n++
  }
  Write-Host "  $ad -> $n soru"
}
Write-Host "toplam soru: $($kayitlar.Count)"

# --- DERS BAZINDA KALIP ------------------------------------------------------
$kalip=[ordered]@{}
foreach($grup in ($kayitlar | Where-Object { $_.ders -ne 'belirsiz' } | Group-Object ders | Sort-Object Count -Descending)){
  $u=@($grup.Group | ForEach-Object { $_.uzunluk } | Sort-Object)
  if($u.Count -lt 8){ continue }
  $tipler=[ordered]@{}
  foreach($tg in ($grup.Group | Group-Object tip | Sort-Object Count -Descending)){ $tipler[$tg.Name]=$tg.Count }
  $kalip[$grup.Name]=[ordered]@{
    soru_sayisi = $u.Count
    ortalama    = [math]::Round(($u | Measure-Object -Average).Average)
    medyan      = $u[[int]($u.Count/2)]
    p75         = $u[[int]($u.Count*0.75)]
    p90         = $u[[int]($u.Count*0.90)]
    en_uzun     = $u[-1]
    tavan       = [math]::Max(220,$u[[int]($u.Count*0.90)])   # uretim tavani = gercek p90
    tip_dagilim = $tipler
  }
}
$belirsiz=@($kayitlar | Where-Object { $_.ders -eq 'belirsiz' }).Count
$cikti=[ordered]@{
  aciklama = "Cikmis $Sinav kitapciklarindan ders bazli GERCEK soru kalibi. Uretici her dersin 'tavan' degerini soru govdesi ust siniri olarak kullanir. Sinıflandirma anahtar-kelime bazli; guveni dusuk sorular 'belirsiz' sayilip kalip disi birakilir."
  sinav = $Sinav
  kitapcik_sayisi = [Math]::Min($KitapcikTavan,$adlar.Count)
  toplam_soru = $kayitlar.Count
  siniflandirilamayan = $belirsiz
  dersler = $kalip
}
. (Join-Path $depoKok 'arac\rapor-yaz.ps1')
$hedef=Join-Path $depoKok "veri\cikmis-ders-kalibi-$(Katla $Sinav).json"
RaporYaz -Hedef $hedef -Nesne $cikti

Write-Host ""
Write-Host "=== DERS KALIPLARI ($Sinav) ==="
foreach($d in $kalip.Keys){
  $k=$kalip[$d]
  Write-Host ("  {0,-24} n={1,-4} medyan={2,-5} p90={3,-5} TAVAN={4,-5} tip: {5}" -f $d,$k.soru_sayisi,$k.medyan,$k.p90,$k.tavan,(($k.tip_dagilim.Keys | ForEach-Object { "$_=$($k.tip_dagilim[$_])" }) -join ' '))
}
Write-Host "siniflandirilamayan: $belirsiz / $($kayitlar.Count)"
