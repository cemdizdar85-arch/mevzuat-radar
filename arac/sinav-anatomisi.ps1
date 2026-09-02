# ============================================================================
#  SINAV ANATOMİSİ (02.09.2026 — Cem: "sınavlarla ilgili her şeyi yap: zorluk
#  derecesi, sınavda kaç konu soruluyor, aynı konuda kaç soru...")
#
#  Çıkmış kitapçıkları soru soru sökerek sınavın TÜM ölçülebilir yapısını çıkarır.
#  Hiçbir rakam tahmin edilmez; ölçülemeyen alan "olculemedi" olarak işaretlenir.
#
#  ÖLÇÜLENLER
#   A) Ders dağılımı      — ders başına soru sayısı, dönemden döneme sabit mi
#   B) Soru numarası bloğu— hangi ders hangi numara aralığında (sıra sabit mi)
#   C) Uzunluk kalıbı     — ders bazlı medyan/p90 (kalıp aracının ölçtüğü)
#   D) Soru tipi          — kayıt / hesaplama / teori / öncüllü
#   E) ZORLUK göstergeleri— 6 ölçülebilir belirteç + bileşik zorluk puanı
#   F) Şık anatomisi      — şık uzunluğu, rakam-şık mı cümle-şık mı, şık yakınlığı
#   G) Negatif soru       — "hangisi YANLIŞTIR/DEĞİLDİR" oranı (bilinen zorlaştırıcı)
#   H) Öncüllü soru       — I/II/III kalıbı oranı
#   I) Mevzuat atfı       — kanun no / madde / standart kodu geçen soru oranı
#   J) Sayısal yoğunluk   — soruda geçen rakam adedi, hesap kodu adedi
#   K) Dönemsel değişim   — yıllara göre uzunluk/zorluk kayması (sınav zorlaşıyor mu)
#   L) Konu tekrarı       — köprüden: aynı konu kaç dönemde, sınav başına kaç konu
#
#  ÇIKTI: veri/sinav-anatomisi-<sinav>.json
#  KURAL: sınıflandırma anahtar-kelime bazlı; güveni düşük soru 'belirsiz' kalır
#         ve ders bazlı ölçümlere GİRMEZ (yanlış etiket kalıbı bozar).
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
function Ist($dizi){
  $d=@($dizi | Where-Object { $null -ne $_ })
  if($d.Count -eq 0){ return $null }
  $s=@($d | Sort-Object)
  return [ordered]@{
    n=$d.Count
    ortalama=[math]::Round(($d | Measure-Object -Average).Average,1)
    medyan=$s[[int]($d.Count/2)]
    p90=$s[[int]($d.Count*0.90)]
    en_az=$s[0]; en_cok=$s[-1]
  }
}

# --- ders sınıflandırıcı (kalıp aracıyla AYNI sözlük — tek kaynak) -----------
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
function DersBul([string]$g){
  $k=Katla $g; $enIyi=''; $enPuan=0
  foreach($d in $DERSLER.Keys){
    $p=0; foreach($x in $DERSLER[$d]){ if($k -match [regex]::Escape($x)){ $p++ } }
    if($p -gt $enPuan){ $enPuan=$p; $enIyi=$d }
  }
  if($enPuan -lt 1){ return 'belirsiz' }
  return $enIyi
}

# --- kitapçıkları çek --------------------------------------------------------
$u1=$SB+'?select=kaynak_ad&kaynak_ad=ilike.'+[uri]::EscapeDataString("CIKMIS SINAV - $Sinav%")+"&limit=80&order=kaynak_ad.desc"
$y=Invoke-WebRequest -UseBasicParsing -Uri $u1 -Headers $H -TimeoutSec 120
# PS 5.1: ONCE ATA, SONRA SAR - tek satirda @(ConvertFrom-Json ...) diziyi ACMAZ,
# 80 kayit '1' sayilir (02.09'da bu araci sifir kitapcikla dusurdu).
$hamAd=ConvertFrom-Json -InputObject $y.Content
$adlar=@(@($hamAd) | ForEach-Object { "$($_.kaynak_ad)" } | Where-Object { $_ -and $_ -notmatch 'yabanci dil' })
Write-Host "kitapcik: $($adlar.Count) bulundu, $([Math]::Min($KitapcikTavan,$adlar.Count)) islenecek"

$S=New-Object System.Collections.Generic.List[object]
$kitapBilgi=New-Object System.Collections.Generic.List[object]
foreach($ad in ($adlar | Select-Object -First $KitapcikTavan)){
  $u2=$SB+'?select=metin&kaynak_ad=eq.'+[uri]::EscapeDataString($ad)+'&limit=1'
  try{ $y2=Invoke-WebRequest -UseBasicParsing -Uri $u2 -Headers $H -TimeoutSec 120; $hamM=ConvertFrom-Json -InputObject $y2.Content; $k2=@($hamM) }catch{ Write-Host "  ATLA: $ad"; continue }
  if($k2.Count -eq 0 -or -not $k2[0].metin){ continue }
  $m="$($k2[0].metin)"
  $donem=''
  $md=[regex]::Match($ad,'(20\d\d)/(\d)')
  if($md.Success){ $donem="$($md.Groups[1].Value)/$($md.Groups[2].Value)" }
  $parca=@([regex]::Split($m,'(?m)^SORU\s+(\d{1,3})\s*:\s*'))
  $n=0
  for($i=1;$i -lt $parca.Count-1;$i+=2){
    $no=0; [void][int]::TryParse($parca[$i],[ref]$no)
    $b=$parca[$i+1]
    # govde + siklar ayrimi
    $sp=@([regex]::Split($b,'(?m)^\s{0,4}A\)\s'))
    if($sp.Count -lt 2){ continue }
    $g=$sp[0].Trim()
    if($g.Length -lt 25 -or $g.Length -gt 3000){ continue }
    $sikBlok=$sp[1]
    $siklar=@([regex]::Split(("A) "+$sikBlok),'(?m)^\s{0,4}[A-E]\)\s') | Where-Object { $_.Trim() })
    $kg=Katla $g
    # --- olculebilir belirtecler
    $rakamAdet=@([regex]::Matches($g,'\d[\d\.,]*')).Count
    $hesapKodu=@([regex]::Matches($g,'\b[1-7]\d{2}\b')).Count
    $mevzuatAtif=($kg -match '\b\d{3,4}\s*sayili|\bmadde\s*\d|\bm\.\s*\d|\btms\s*\d|\btfrs\s*\d|\bbds\s*\d|\bvuk\b|\bttk\b')
    $negatif=($kg -match 'hangisi\s+(yanlis|dogru degil)|degildir|olamaz|soylenemez|yer almaz|bulunmaz')
    $onculu=($g -match '(?m)^\s*(I{1,3}|IV|V)\s*[\.\)]' -or $kg -match 'yukaridakilerden hangisi|hangileri')
    $tabloVar=($g -match "`t" -or $g -match '(?m)^\s*\|')
    $tip=if($kg -match 'muhasebe kayd|yevmiye maddesi|kayd[ıi] a[sş]a[gğ][ıi]dakilerden'){'kayit'}
      elseif($rakamAdet -ge 3 -and $kg -match 'kactir|ne kadar|tutari|hesapla|kac tl|kac ₺'){'hesaplama'}
      elseif($kg -match 'asagidakilerden hangisi|hangisi yanlis|hangisi dogru'){'teori'}
      else{'diger'}
    # sik anatomisi
    $sikUz=@($siklar | ForEach-Object { $_.Trim().Length })
    $sikRakamMi=@($siklar | Where-Object { $_.Trim() -match '^[\d\.,\s₺TL%]+$' }).Count
    # --- ZORLUK PUANI (0-100, olculebilir belirteclerden; 'his' degil)
    $z=0
    $z += [math]::Min(30,[math]::Round($g.Length/20))          # uzunluk (max 30)
    $z += [math]::Min(20,$rakamAdet*2)                          # sayisal yuk (max 20)
    $z += [math]::Min(15,$hesapKodu*3)                          # hesap kodu yogunlugu
    if($negatif){ $z += 10 }                                    # negatif soru
    if($onculu){ $z += 15 }                                     # onculu (I/II/III)
    if($tip -eq 'hesaplama'){ $z += 10 }
    $sikOrt=if($sikUz.Count){ ($sikUz | Measure-Object -Average).Average } else { 0 }
    if($sikOrt -gt 60){ $z += 5 }                               # uzun sik = okuma yuku
    $S.Add([pscustomobject]@{
      kitapcik=$ad; donem=$donem; no=$no; uzunluk=$g.Length; ders=(DersBul $g); tip=$tip
      rakam=$rakamAdet; hesapKodu=$hesapKodu; mevzuat=$mevzuatAtif; negatif=$negatif
      onculu=$onculu; tablo=$tabloVar; sikSayi=$siklar.Count
      sikOrtUz=[math]::Round($sikOrt); sikRakam=$sikRakamMi; zorluk=[math]::Min(100,$z)
    })
    $n++
  }
  $kitapBilgi.Add([pscustomobject]@{ ad=$ad; donem=$donem; soru=$n })
  Write-Host "  $ad -> $n soru"
}
Write-Host "toplam: $($S.Count) soru"
if($S.Count -lt 50){ throw "yeterli soru ayiklanamadi ($($S.Count))" }

$bilinen=@($S | Where-Object { $_.ders -ne 'belirsiz' })

# --- A) ders dagilimi + sabitlik --------------------------------------------
$dersDagilim=[ordered]@{}
foreach($gr in ($bilinen | Group-Object ders | Sort-Object Count -Descending)){
  $donemBasi=@($gr.Group | Group-Object donem | ForEach-Object { $_.Count })
  $dersDagilim[$gr.Name]=[ordered]@{
    toplam=$gr.Count
    donem_basina=(Ist $donemBasi)
    sabit_mi=$(if(@($donemBasi | Sort-Object -Unique).Count -le 2){'evet (donemden doneme +-1)'}else{'hayir - degisiyor'})
  }
}
# --- B) soru numarasi blogu --------------------------------------------------
$blok=[ordered]@{}
foreach($gr in ($bilinen | Group-Object ders)){
  $nolar=@($gr.Group | ForEach-Object { $_.no } | Sort-Object)
  $blok[$gr.Name]=[ordered]@{ ilk_soru=$nolar[0]; son_soru=$nolar[-1]; medyan_no=$nolar[[int]($nolar.Count/2)] }
}
# --- C-J) ders bazli tam kalip ----------------------------------------------
$dersKalip=[ordered]@{}
foreach($gr in ($bilinen | Group-Object ders | Sort-Object Count -Descending)){
  $g=$gr.Group
  if($g.Count -lt 8){ continue }
  $tipD=[ordered]@{}
  foreach($t in ($g | Group-Object tip | Sort-Object Count -Descending)){ $tipD[$t.Name]=[ordered]@{ adet=$t.Count; yuzde=[math]::Round(100*$t.Count/$g.Count) } }
  $dersKalip[$gr.Name]=[ordered]@{
    soru_sayisi=$g.Count
    uzunluk=(Ist @($g | ForEach-Object { $_.uzunluk }))
    zorluk=(Ist @($g | ForEach-Object { $_.zorluk }))
    tip_dagilim=$tipD
    negatif_soru_yuzde=[math]::Round(100*@($g|Where-Object{$_.negatif}).Count/$g.Count)
    onculu_soru_yuzde=[math]::Round(100*@($g|Where-Object{$_.onculu}).Count/$g.Count)
    mevzuat_atifli_yuzde=[math]::Round(100*@($g|Where-Object{$_.mevzuat}).Count/$g.Count)
    rakam_adedi=(Ist @($g | ForEach-Object { $_.rakam }))
    hesap_kodu_adedi=(Ist @($g | ForEach-Object { $_.hesapKodu }))
    sik_uzunlugu=(Ist @($g | ForEach-Object { $_.sikOrtUz }))
    rakam_sikli_soru_yuzde=[math]::Round(100*@($g|Where-Object{$_.sikRakam -ge 4}).Count/$g.Count)
  }
}
# --- K) donemsel degisim (sinav zorlasiyor mu) -------------------------------
$donemsel=[ordered]@{}
foreach($gr in ($S | Where-Object { $_.donem } | Group-Object donem | Sort-Object Name)){
  $donemsel[$gr.Name]=[ordered]@{
    soru=$gr.Count
    medyan_uzunluk=(@($gr.Group | ForEach-Object { $_.uzunluk } | Sort-Object))[[int]($gr.Count/2)]
    ortalama_zorluk=[math]::Round((($gr.Group | Measure-Object zorluk -Average).Average),1)
    onculu_yuzde=[math]::Round(100*@($gr.Group|Where-Object{$_.onculu}).Count/$gr.Count)
    negatif_yuzde=[math]::Round(100*@($gr.Group|Where-Object{$_.negatif}).Count/$gr.Count)
  }
}
# --- L) konu tekrari (kopruden) ---------------------------------------------
$konuOlcum=[ordered]@{ durum='olculemedi' }
$koprüYol=Join-Path $depoKok 'veri\fabrika\konu-koprusu.json'
if(Test-Path $koprüYol){
  $kop=Get-Content $koprüYol -Raw -Encoding UTF8 | ConvertFrom-Json
  $bu=@($kop | Where-Object { $_.sinav -eq $Sinav -and $_.donem -ge 1 })
  if($bu.Count){
    $donemler=@($bu | ForEach-Object { [int]$_.donem })
    $konuOlcum=[ordered]@{
      durum='olculdu'
      toplam_konu=$bu.Count
      konu_basina_donem=(Ist $donemler)
      her_donem_cikan=@($bu | Where-Object { [int]$_.donem -ge 8 }).Count
      tek_donemlik=@($bu | Where-Object { [int]$_.donem -eq 1 }).Count
      en_cok_cikan=@($bu | Sort-Object { -[int]$_.donem } | Select-Object -First 12 | ForEach-Object { "$($_.konu) ($($_.donem) donem)" })
    }
  }
}

$cikti=[ordered]@{
  aciklama="$Sinav sinavinin cikmis kitapciklardan olculen ANATOMISI. Zorluk puani 0-100; olculebilir belirteclerden hesaplanir (uzunluk, sayisal yuk, hesap kodu, negatif kalip, onculu kalip, tip) - subjektif degil. Ders sinifi anahtar-kelime bazlidir; guveni dusuk sorular 'belirsiz' sayilip ders olcumlerine girmez."
  sinav=$Sinav
  kitapcik=@($kitapBilgi | ForEach-Object { "$($_.ad) -> $($_.soru) soru" })
  toplam_soru=$S.Count
  siniflandirilamayan=@($S | Where-Object { $_.ders -eq 'belirsiz' }).Count
  A_ders_dagilimi=$dersDagilim
  B_soru_numarasi_blogu=$blok
  C_ders_kalibi=$dersKalip
  K_donemsel_degisim=$donemsel
  L_konu_tekrari=$konuOlcum
}
. (Join-Path $depoKok 'arac\rapor-yaz.ps1')
RaporYaz -Hedef (Join-Path $depoKok "veri\sinav-anatomisi-$(Katla $Sinav).json") -Nesne $cikti

Write-Host ""
Write-Host "=== $Sinav ANATOMISI ==="
Write-Host ("sinav basina soru: {0} | kitapcik: {1} | siniflandirilamayan: {2}" -f ([math]::Round(($kitapBilgi | Measure-Object soru -Average).Average)),$kitapBilgi.Count,$cikti.siniflandirilamayan)
Write-Host ""
Write-Host ("{0,-24} {1,-6} {2,-8} {3,-8} {4,-7} {5,-7} {6}" -f 'DERS','soru/s','medyan','zorluk','negatif','onculu','tip')
foreach($d in $dersKalip.Keys){
  $k=$dersKalip[$d]
  $dd=$dersDagilim[$d]
  $tipStr=(($k.tip_dagilim.Keys | Select-Object -First 3 | ForEach-Object { "$_ %$($k.tip_dagilim[$_].yuzde)" }) -join ' ')
  Write-Host ("{0,-24} {1,-6} {2,-8} {3,-8} {4,-7} {5,-7} {6}" -f $d,$dd.donem_basina.medyan,$k.uzunluk.medyan,$k.zorluk.medyan,"%$($k.negatif_soru_yuzde)","%$($k.onculu_soru_yuzde)",$tipStr)
}
Write-Host ""
Write-Host "--- DONEMSEL (sinav zorlasiyor mu?) ---"
foreach($d in $donemsel.Keys){ $x=$donemsel[$d]; Write-Host ("  {0}  soru={1,-4} medyan={2,-5} zorluk={3,-6} onculu=%{4,-3} negatif=%{5}" -f $d,$x.soru,$x.medyan_uzunluk,$x.ortalama_zorluk,$x.onculu_yuzde,$x.negatif_yuzde) }
if($konuOlcum.durum -eq 'olculdu'){
  Write-Host ""
  Write-Host "--- KONU TEKRARI (kopru) ---"
  Write-Host ("  toplam konu: {0} | konu basina ortalama {1} donem | 8+ donem cikan: {2} | tek donemlik: {3}" -f $konuOlcum.toplam_konu,$konuOlcum.konu_basina_donem.ortalama,$konuOlcum.her_donem_cikan,$konuOlcum.tek_donemlik)
}
