# KAYDIR-ÇÖZ — cevap kalıbı BUILDER (05.09.2026 KİLİTLENDİ, şartname: STANDART-CEVAP-KALIBI.md). Cache'ten HTML basar, API yok, bedel 0.
# Başlangıç 03.09 prototip (Cem "a yap prototip göster"): 5 soru, tam ekran kart, yukari kaydir = sonraki,
# tutari sola surukle = BORC, saga = ALACAK. Cache'ten (sgs-fmuh-30 + sgs-bosluk), API yok, bedel 0.
param([string]$SadeceId='',[string]$Cikti='KAYDIR-COZ.html',[string]$SecimDosya='')   # SadeceId: tek soru; SecimDosya: sgs30-secim.json (etiket/id/ders listesi)
$script:T0=Get-Date; function Sure([string]$ad){ "[süre] $ad`: $([int]((Get-Date)-$script:T0).TotalSeconds) sn" }   # 04.09: basım 250 sn, darboğaz ölçümü
$kok=Split-Path $PSScriptRoot -Parent   # depo kökü (motor/'un üstü)
# 05.09 depoya taşındı: seçim listeleri depoda (elle yazılır), önbellekler veri/fabrika altında (gitignore), çıktı sql-yerel/ (gitignore)
$SECIM_DIR=Join-Path $kok 'veri\sinav\kaydir-secim'; $ONB_DIR=Join-Path $kok 'veri\fabrika\kaydir-onbellek'; New-Item -ItemType Directory -Force $ONB_DIR | Out-Null
$aday=New-Object System.Collections.Generic.List[object]
foreach($et in @('sgs-fmuh-30','sgs-bosluk-finansalmuhasebe')){
  $cf=Join-Path $kok "veri\fabrika\kalip-parti-$et.json"; if(-not (Test-Path $cf)){ continue }
  $c=Get-Content $cf -Raw -Encoding UTF8 | ConvertFrom-Json
  foreach($pp in $c.PSObject.Properties){
    $v=$pp.Value; if(-not $v.soru -or "$($v.hakem.karar)" -ne 'EVET' -or "$($v.hakem.konu_uyum)" -eq 'KONU-DISI'){ continue }
    if(-not ($v.sema -and "$($v.sema.tur)" -eq 'yevmiye')){ continue }
    $kyt=@(); if($v.sema.kayitlar){ $kyt=@($v.sema.kayitlar) } elseif($v.sema.ogeler){ $kyt=@(,([pscustomobject]@{baslik='';ogeler=$v.sema.ogeler})) }
    if($kyt.Count -ne 1){ continue }   # prototip: tek kayitli sorular (surukleme oyunu tek tablo)
    $ky=$kyt[0]; if(-not ($ky.ogeler.borc -and $ky.ogeler.alacak)){ continue }
    if(@($ky.ogeler.borc).Count + @($ky.ogeler.alacak).Count -gt 4){ continue }
    $aday.Add([pscustomobject]@{ et=$et; id=$pp.Name; v=$v; ky=$ky; donem=[int]$v.donem })
  }
}
"aday: $($aday.Count)"
$sec=@($aday | Sort-Object @{e='donem';Descending=$true} | Select-Object -First 5)
if($SadeceId){ $sec=@($aday | Where-Object { "$($_.et)/$($_.id)" -eq $SadeceId }); "tek soru: $SadeceId -> $($sec.Count) bulundu" }
# Cem 04.09 "30'luk SGS seti": secim dosyasindan (etiket/id/ders); yevmiyesiz sorular da alinir (oyun yalniz kayitlilarda)
if($SecimDosya){
  $secimYol=if(Test-Path $SecimDosya){ $SecimDosya } else { Join-Path $SECIM_DIR $SecimDosya }; $liste=@((Get-Content $secimYol -Raw -Encoding UTF8 | ConvertFrom-Json)); $sec=@(); $cacheOn=@{}
  foreach($l in $liste){
    if(-not $cacheOn.ContainsKey($l.etiket)){ $cf=Join-Path $kok "veri\fabrika\kalip-parti-$($l.etiket).json"; $cacheOn[$l.etiket]=if(Test-Path $cf){ Get-Content $cf -Raw -Encoding UTF8 | ConvertFrom-Json } else { $null } }
    $c=$cacheOn[$l.etiket]; if(-not $c -or -not $c.PSObject.Properties[$l.id]){ "  YOK: $($l.etiket)/$($l.id)"; continue }
    $v=$c.($l.id); $ky=$null
    if($v.sema -and "$($v.sema.tur)" -eq 'yevmiye'){ $kyt=@(); if($v.sema.kayitlar){ $kyt=@($v.sema.kayitlar) } elseif($v.sema.ogeler){ $kyt=@(,([pscustomobject]@{baslik='';ogeler=$v.sema.ogeler})) }; if($kyt.Count -ge 1 -and $kyt[0].ogeler.borc -and $kyt[0].ogeler.alacak){ $ky=$kyt[0] } }
    $DERS_TR=@{'Borclar Hukuku'='Borçlar Hukuku';'Is ve Sosyal Guvenlik Hukuku'='İş ve Sosyal Güvenlik Hukuku';'Vergi Hukuku'='Vergi Hukuku';'Ticaret Hukuku'='Ticaret Hukuku'}
    $dersAd="$($l.ders)"; if($DERS_TR.ContainsKey($dersAd)){ $dersAd=$DERS_TR[$dersAd] }
    $sec+=[pscustomobject]@{ et=$l.etiket; id=$l.id; v=$v; ky=$ky; donem=[int]$v.donem; ders=$dersAd }
  }
  "secim dosyasi: $($liste.Count) istendi -> $($sec.Count) bulundu"
}
Sure 'soru seçimi'
# --- TURKCE ONARIM (Cem 03.09 "1. resim Turkce harf sikintisi"; bedel 0): adim/aciklama metinleri ASCII yazilmis.
# Sozluk, elimizdeki DOGRU Turkce metinlerden (tum cache'lerdeki soru/sik/hap/taktik alanlari) kurulur:
# katlanmis kelime -> en sik gorulen Turkce yazim. ASCII bicimi de gercek kelime olarak korpusta yasiyorsa
# (kasa, ve, bu...) DOKUNULMAZ; Turkce bicim en az 3 kat sikse degistirilir.
function Katla([string]$s){ ("$s" -creplace 'İ','i' -creplace 'I','i' -creplace 'ı','i' -creplace 'Ğ','g' -creplace 'ğ','g' -creplace 'Ü','u' -creplace 'ü','u' -creplace 'Ş','s' -creplace 'ş','s' -creplace 'Ö','o' -creplace 'ö','o' -creplace 'Ç','c' -creplace 'ç','c' -creplace 'Â','a' -creplace 'â','a' -creplace 'Î','i' -creplace 'î','i' -creplace 'Û','u' -creplace 'û','u').ToLowerInvariant() }
$SAY=@{}   # katlanmis -> @{ 'yazim'=adet }
# 04.09 ÖLÇÜLDÜ: sözlük kurulumu 100 sn (36 cache, yüz binlerce kelime × Katla). Sözlük diske yazılır; cache'lerden
# yeni bir dosya yoksa oradan yüklenir (SOZ + ENF en sık biçim + IVAR i/İ ile başlayan biçim var mı).
$SOZ_YOL=Join-Path $ONB_DIR 'turkce-sozluk-onbellek.json'; $SOZ=@{}; $ENF=@{}; $IVAR=@{}; $sozYuklendi=$false
$cacheDosyalar=@(Get-ChildItem (Join-Path $kok 'veri\fabrika\kalip-parti-*.json'))
if(Test-Path $SOZ_YOL){ $enYeni=($cacheDosyalar | Measure-Object LastWriteTime -Maximum).Maximum; if((Get-Item $SOZ_YOL).LastWriteTime -gt $enYeni){ try{ $sj=Get-Content $SOZ_YOL -Raw -Encoding UTF8 | ConvertFrom-Json; foreach($p in $sj.SOZ.PSObject.Properties){ $SOZ[$p.Name]="$($p.Value)" }; foreach($p in $sj.ENF.PSObject.Properties){ $ENF[$p.Name]="$($p.Value)" }; foreach($p in $sj.IVAR.PSObject.Properties){ $IVAR[$p.Name]=$true }; $sozYuklendi=$true }catch{ $SOZ=@{}; $ENF=@{}; $IVAR=@{}; $sozYuklendi=$false } } }
if(-not $sozYuklendi){
foreach($cf in $cacheDosyalar){
  try{ $c=Get-Content $cf.FullName -Raw -Encoding UTF8 | ConvertFrom-Json }catch{ continue }
  foreach($pp in $c.PSObject.Properties){
    $v=$pp.Value; $metinler=@("$($v.soru)","$($v.hap)","$($v.sinav_taktigi)","$($v.notlandirici)","$($v.konu)")
    if($v.siklar){ foreach($h in 'A','B','C','D','E'){ $metinler+="$($v.siklar.$h)" } }
    # 04.09: açıklama + adım anlatımları da korpusa (İş-SGK partisinin hap/tuzak satırları ASCII'ydi, sözlük bu biçimleri tanımıyordu)
    if($v.aciklama){ foreach($h in 'A','B','C','D','E'){ if($v.aciklama.PSObject.Properties[$h] -and $v.aciklama.$h -is [string]){ $metinler+="$($v.aciklama.$h)" } } }
    foreach($a0 in @($v.adimlar)){ if($a0 -and $a0.PSObject.Properties['anlatim']){ $metinler+="$($a0.anlatim)" } }
    if($v.sade){ $metinler+="$($v.sade.dogru)"; foreach($kv0 in @($v.sade.kavramlar)){ if($kv0){ $metinler+="$($kv0.tanim)" } } }
    foreach($mt in $metinler){ foreach($m in [regex]::Matches($mt,'[A-Za-zÇĞİÖŞÜçğıöşüÂâÎîÛû]{3,}')){ $w=$m.Value; $lw=$w.ToLower([cultureinfo]::GetCultureInfo('tr-TR')); $k=Katla $w; if(-not $SAY.ContainsKey($k)){ $SAY[$k]=@{} }; if(-not $SAY[$k].ContainsKey($lw)){ $SAY[$k][$lw]=0 }; $SAY[$k][$lw]++ } }
  }
}
foreach($k in $SAY.Keys){
  # DİKKAT: PS harf ayırmaz - '$enF' yazılırsa $ENF sözlüğünü EZER (04.09'da 17.847 hata üretti). Kısa ad yok.
  $h=$SAY[$k]; $enIyi=$null; $enIyiN=0; $asciiN=0; $enSikBicim=$null; $enSikSayi=0
  foreach($y in $h.Keys){ if($h[$y] -gt $enSikSayi){ $enSikBicim=$y; $enSikSayi=$h[$y] }; if($y.StartsWith('i') -or $y.StartsWith('İ')){ $IVAR[$k]=$true }; if($y -eq $k){ $asciiN=$h[$y] } elseif($h[$y] -gt $enIyiN){ $enIyi=$y; $enIyiN=$h[$y] } }
  if($enSikBicim){ $ENF[$k]=$enSikBicim }
  if($enIyi -and $enIyiN -ge 2 -and $enIyiN -ge 3*$asciiN){ $SOZ[$k]=$enIyi }
}
[IO.File]::WriteAllText($SOZ_YOL,(ConvertTo-Json -InputObject @{ SOZ=$SOZ; ENF=$ENF; IVAR=$IVAR } -Depth 3 -Compress),[Text.UTF8Encoding]::new($false))
}
# 05.09: korpusta yeterince geçmeyen sık maliyet/muhasebe kelimeleri (tabloda "yuklenir", "kismi", "Bos" kalıyordu) — sabit yedek
$SABIT_SOZ=@{ yuklenir='yüklenir'; yuklenen='yüklenen'; yuklenecek='yüklenecek'; yukleme='yükleme'; kismi='kısmı'; kisim='kısım'; bos='boş'; uretim='üretim'; degisken='değişken'; kullanim='kullanım'; orani='oranı'; gideri='gideri'; toplami='toplamı'; kapasite='kapasite'; calismayan='çalışmayan'; sapmasi='sapması'; farki='farkı'; esdeger='eşdeğer'; birim='birim'; dagitim='dağıtım'; dagitimi='dağıtımı'; sonucu='sonucu'; tutari='tutarı'; hesabi='hesabı'; maliyeti='maliyeti'; isci='işçi'; iscilik='işçilik'; iscilik_='işçilik'; hammadde='hammadde'; malzeme='malzeme'; yari='yarı'; mamul='mamul'; satilan='satılan'; satis='satış'; satislar='satışlar'; donem='dönem'; donemi='dönemi'; gelir='gelir'; kar='kâr'; kari='kârı'; zarar='zarar'; zarari='zararı'; olcek='ölçek'; olcum='ölçüm'; yontemi='yöntemi'; yontem='yöntem'; oran='oran'; oranla='oranla'; carpim='çarpım'; bolum='bölüm'; eksik='eksik'; fazla='fazla'; yuk='yük'; sabit='sabit'; gercek='gerçek'; gerceklesen='gerçekleşen'; buyuk='büyük'; kucuk='küçük'; ucret='ücret'; ucreti='ücreti'; ayrilan='ayrılan'; ayrilmis='ayrılmış'; islem='işlem'; isletme='işletme'; sirket='şirket'; ortak='ortak'; urun='ürün'; urunler='ürünler'; urunu='ürünü'; agirlik='ağırlık'; agirlikli='ağırlıklı'; fiili='fiili'; butce='bütçe'; butcelenen='bütçelenen'; standart='standart'; olculen='ölçülen' }
foreach($k0 in $SABIT_SOZ.Keys){ if(-not $SOZ.ContainsKey($k0)){ $SOZ[$k0]=$SABIT_SOZ[$k0] } }
"turkce sozluk: $($SOZ.Count) kelime (en sık biçim $($ENF.Count) kök)$(if($sozYuklendi){ ' · önbellekten' } else { ' · yeniden kuruldu' })"
function TurkceOnar([string]$t){
  if(-not $t){ return $t }
  # kelime siniri Turkce harfleri de kapsar: "çıkarılan" icindeki "kar" parcasi ayri kelime sanilip "kâr" yapilmasin
  $onarilan=[regex]::Replace($t,'[A-Za-zÇĞİÖŞÜçğıöşüÂâÎîÛû]{3,}',{ param($m) $w=$m.Value
      # bas harfi buyuk I olan kelime (Iptal, Isletme): korpusta 'i' ile baslayan bicimi varsa İ yapilir
      if($w -cmatch '^I[a-zçğıöşü]'){ $k0=Katla $w; if($IVAR.ContainsKey($k0)){ $w='İ'+$w.Substring(1) } }
      if($w -cmatch '[çğıöşüÇĞİÖŞÜâîû]'){ return $w }; $k=$w.ToLowerInvariant()
      # TAMAMEN BUYUK kelime (HISSE, IPTAL, SENEDI): korpustaki en sik kucuk bicim tr-TR ile buyutulur -> HİSSE, İPTAL, SENEDİ
      if($w.Length -ge 3 -and $w -ceq $w.ToUpperInvariant() -and $ENF.ContainsKey($k)){ return [cultureinfo]::GetCultureInfo('tr-TR').TextInfo.ToUpper($ENF[$k]) }
      if(-not $SOZ.ContainsKey($k)){ return $w }; $y=$SOZ[$k]
      # buyuk harf Turkce kurala gore (tr-TR: i->İ, ı->I); invariant kultur 'ı'yi buyutmuyordu ("KARLARı")
      $TI=[cultureinfo]::GetCultureInfo('tr-TR').TextInfo
      if($w -ceq $TI.ToUpper($w)){ return $TI.ToUpper($y) }
      if($w.Substring(0,1) -ceq $TI.ToUpper($w.Substring(0,1))){ return ($TI.ToUpper($y.Substring(0,1))+$y.Substring(1)) }
      return $y })
  # 05.09 (kalıp-1): üretici terim onarımı "lehte (olumlu)" → "olumlu (olumlu)dur" bırakmıştı; aynı kelimenin parantez tekrarı silinir
  $onarilan=[regex]::Replace($onarilan,'(?i)\b(\p{L}+)\s*\(\1\)','$1')
  # 06.09 (kalıp-4): sınav dili kısaltma açımı — sınav "dönem başı yarı mamul", "ilk giren ilk çıkar" der; DB YM / GÜG / FIFO demez
  foreach($cf in @(@('\bDB\s+YM\b','dönem başı yarı mamul'),@('\bDS\s+YM\b','dönem sonu yarı mamul'),@('\bYM\b','yarı mamul'),@('\bGÜG\b','genel üretim gideri'),@('\bDİMM\b','direkt ilk madde ve malzeme'),@('\bDİG\b','direkt işçilik gideri'),@('\bFIFO yöntemi(ni|nde|yle)?\b','ilk giren ilk çıkar yöntemi$1'),@("\bFIFO'(da|nda|ya)\b","ilk giren ilk çıkar yönteminde"),@('\bFIFO\b','ilk giren ilk çıkar (FIFO)'))){ $onarilan=[regex]::Replace($onarilan,$cf[0],$cf[1]) }
  $onarilan=[regex]::Replace($onarilan,'(?<=[.!?]\s|^)dönem başı yarı mamul','Dönem başı yarı mamul')
  return [regex]::Replace($onarilan,'(?i)\b(\p{L}+),?\s+yani\s+(?=\1)','')   # "olumlu yani olumlu" → "olumlu"
}
"deneme: " + (TurkceOnar 'Simdi farki hesapliyoruz: satis hasilati sermaye payini gecerse artan kisim kar sayilir. 100 KASA (BORC) 130.000 TL')
# 04.09 Cem "@{ne_soruluyor=...} bu ne?": model açıklamayı bazen YAPILI nesne döndürüyor; string'e çevrilince PS
# hashtable dökümü ekrana düşüyordu. Üreticideki AciklamaDuz'un aynısı: alanlardan okunur metin derlenir.
function AciklamaDuz($a){
  if($null -eq $a){ return '' }
  if($a -is [string]){ return $a }
  $p=New-Object System.Collections.Generic.List[string]
  if($a.PSObject.Properties['ne_soruluyor'] -and $a.ne_soruluyor){ $p.Add("Ne soruluyor: $($a.ne_soruluyor)") }
  if($a.PSObject.Properties['kural'] -and $a.kural){ $p.Add("Kural: $($a.kural)") }
  if($a.PSObject.Properties['tuzak'] -and $a.tuzak){ $p.Add("$($a.tuzak)") }
  if($a.PSObject.Properties['hesap'] -and $a.hesap){ $p.Add("Hesap: $($a.hesap)") }
  if($a.PSObject.Properties['dogrusu'] -and $a.dogrusu){ $p.Add("Doğrusu: $($a.dogrusu)") }
  if($p.Count -eq 0){ foreach($pr in $a.PSObject.Properties){ $p.Add("$($pr.Value)") } }
  return ($p -join ' ')
}
function TuzakAyir([string]$a){ $mt=[regex]::Match($a,'^([^:]{3,60}):\s*(.*)$'); if($mt.Success){ return @{ ad=($mt.Groups[1].Value.Trim() -replace '^\[|\]$','' -replace '\]\s*',' '); metin=$mt.Groups[2].Value.Trim() } }; return @{ ad='Tuzak'; metin=$a } }
# yapılı yanlış-şık açıklamasında tuzak metni 'tuzak' alanındadır ("[Genel Üretim Gideri İhmali] Tuzağı: ..."); ad oradan alınır,
# "Ne soruluyor" satırı tuzak adı sanılmaz (04.09 kp-28'de görüldü)
function TuzakMetin($a){
  if($null -eq $a){ return '' }
  if($a -is [string]){ return $a }
  if($a.PSObject.Properties['tuzak'] -and $a.tuzak){ $t="$($a.tuzak)"; if($a.PSObject.Properties['dogrusu'] -and $a.dogrusu){ $t+=" Doğrusu: $($a.dogrusu)" }; return $t }
  return (AciklamaDuz $a)
}
$sorular=@()
foreach($x in $sec){
  $v=$x.v; $d="$($v.dogru)"; $acD=AciklamaDuz $v.aciklama.$d
  $kural=''; $olay=''
  $m=[regex]::Match($acD,'(?s)Kural:\s*(.*?)(?=(Hesap:|Bu olayda:|Doğrusu:|Dogrusu:|$))'); if($m.Success){ $kural=$m.Groups[1].Value.Trim() }
  $m2=[regex]::Match($acD,'(?s)(Hesap:|Bu olayda:)\s*(.*?)(?=(Doğrusu:|Dogrusu:|$))'); if($m2.Success){ $olay=$m2.Groups[2].Value.Trim() }
  if(-not $kural){ $kural=$acD }
  $tz=@{}; foreach($h in 'A','B','C','D','E'){ if($h -ne $d -and $v.aciklama.$h){ $tz[$h]=TuzakAyir (TuzakMetin $v.aciklama.$h) } }
  $kayit=@(); if($x.ky){ foreach($og in @($x.ky.ogeler.borc)){ $kayit+=@{ hesap=(TurkceOnar "$($og.hesap)"); tutar="$($og.tutar)"; taraf='B' } }; foreach($og in @($x.ky.ogeler.alacak)){ $kayit+=@{ hesap=(TurkceOnar "$($og.hesap)"); tutar="$($og.tutar)"; taraf='A' } } }
  $siklar=@{}; foreach($h in 'A','B','C','D','E'){ if($v.siklar.$h){ $siklar[$h]="$($v.siklar.$h)" } }
  # ogretmen anlatimli adimlar (genc dili) + cozum tablosu + soruda verilen hucreler
  $adimlar=@(); foreach($a in @($v.adimlar)){ if(-not $a){ continue }
    $fm="$($a.formul)".Trim(); $an=TurkceOnar "$($a.anlatim)"
    # 04.09 Cem'e gösterilen İş-SGK sorusunda 4 adımın başlığı boştu: başlık yoksa anlatımın ilk cümlesi başlık olur
    if(-not $fm){ $fm=(($an -split '(?<=[.!?])\s+')[0]); if($fm.Length -gt 110){ $fm=$fm.Substring(0,108)+'…' } }
    $fmT=TurkceOnar $fm
    # 05.09 (kalıp-2 pilotu): model sonuç adımını iki kez yazdı (adım 6 ve 7 aynı ad, aynı sonuç). Ad ve sonuç önceki adımla
    # aynıysa yeni adım açılmaz, anlatımı öncekine eklenir.
    $adAyni=$false
    if($adimlar.Count){ $onc=$adimlar[$adimlar.Count-1].formul; $adK={ param($f) $p=@("$f" -split '\s=\s'); @(($p[0] -replace '\s+',' ').Trim().ToLowerInvariant(), ($p[-1] -replace '\s*\([^)]*\)','' -replace '\s+',' ').Trim().ToLowerInvariant()) }
      $k1=& $adK $onc; $k2=& $adK $fmT; if($k1[0] -eq $k2[0] -and $k1[1] -eq $k2[1] -and $k1[0] -notmatch '^(verilen|soruda ne var|yanlış yol)'){ $adAyni=$true } }
    if($adAyni){ $adimlar[$adimlar.Count-1].anlatim=($adimlar[$adimlar.Count-1].anlatim+' '+$an).Trim(); "    adım birleştirildi (tekrar): $fmT"; continue }
    $adimlar+=@{ anlatim=$an; formul=$fmT; doldur=@(@($a.doldur) | ForEach-Object { ,@(@($_ | ForEach-Object { [int]$_ })) }) } }
  # 04.09 FAZ S: sade Doğrusu + sınav dili + yanlış şık sade nedeni + anahtar kavramlar (üretici cache'inden; yoksa null)
  $sade=$null
  if($v.PSObject.Properties['sade'] -and $v.sade -and $v.sade.dogru){
    $ss=@{}; if($v.sade.siklar){ foreach($p in $v.sade.siklar.PSObject.Properties){ $ss[$p.Name]=(TurkceOnar "$($p.Value)") } }
    # kaynak künyesi ambar adıyla gelir ("VUK (213 s.K.) m.275 - İmal edilen emtia"); öğrenciye sınav diliyle gösterilir
    $KaynakAdSade={ param($ka) $x="$ka" -replace '\s+-\s.*$',''
      $x=$x -replace '^VUK\b','Vergi Usul Kanunu' -replace '^TTK\b','Türk Ticaret Kanunu' -replace '^TBK\b','Türk Borçlar Kanunu' -replace '^GVK\b','Gelir Vergisi Kanunu' -replace '^KVK\b','Kurumlar Vergisi Kanunu' -replace '^İş K\.','İş Kanunu' -replace '^KDVK\b','Katma Değer Vergisi Kanunu'
      $x=$x -replace '\s*\(\d+ s\.K\.\)','' -replace '\bm\.(\d+)(/\w+)?','$1$2. madde' -replace '\bp\.(\d+)','paragraf $1' -replace '^THP (\d+)','Tekdüzen Hesap Planı $1' -replace '\s*\[\d+/\d+\]',''
      $x.Trim() }
    $kvL=@(); foreach($kv in @($v.sade.kavramlar)){ if($kv -and $kv.ad){ $kvL+=@{ ad=(TurkceOnar "$($kv.ad)"); tanim=(TurkceOnar "$($kv.tanim)"); kaynak=(& $KaynakAdSade $kv.kaynak) } } }
    $sade=@{ dogru=(TurkceOnar "$($v.sade.dogru)"); sinav=(TurkceOnar "$($v.sade.sinav)"); siklar=$ss; kavramlar=$kvL }
  }
  $kural=TurkceOnar $kural; $olay=TurkceOnar $olay
  # Cem 03.09 "öğretmen kısmı yok": üretici tablosuz soruya adım yazmamış -> adımlar eldeki kural + kayıttan
  # OTOMATİK kurulur (verilenler → kural → borç → alacak → denklik). Model çağrısı yok; içerik cache'ten.
  if($adimlar.Count -eq 0 -and $kayit.Count){
    $tutarlar=@($kayit | ForEach-Object { $_.tutar } | Select-Object -Unique)
    $adimlar+=@{ anlatim="Soru bize şunları vermiş: $($tutarlar -join ' TL, ') TL. Bunları biz bulmadık, soru verdi. Önce hangi işlem olduğunu anlayalım: $(($v.konu -replace '\s+',' '))."; formul="Verilen tutar = $($tutarlar -join ' / ') (soruda verilen)"; doldur=@() }
    $adimlar+=@{ anlatim=$kural; formul="Kural: $((TurkceOnar "$($v.konu)"))"; doldur=@() }
    foreach($r in ($kayit | Where-Object { $_.taraf -eq 'B' })){ $adimlar+=@{ anlatim="Önce borç tarafı. $($r.hesap) hesabı artıyor, o yüzden borç yazıyoruz. Dikkat: tarafı yanlış seçersen kayıt denk görünse de yanlıştır."; formul="$($r.hesap) (BORÇ) $($r.tutar) (soruda verilen)"; doldur=@() } }
    foreach($r in ($kayit | Where-Object { $_.taraf -eq 'A' })){ $adimlar+=@{ anlatim="Şimdi alacak tarafı. $($r.hesap) hesabına alacak yazıyoruz; borcun karşılığı budur."; formul="$($r.hesap) (ALACAK) $($r.tutar) (soruda verilen)"; doldur=@() } }
    $bT=[decimal]0; $aT=[decimal]0; foreach($r in $kayit){ $s=("$($r.tutar)" -replace '(?i)\s*tl\s*','' -replace '[^\d\.,]',''); if($s){ try{ $n=[decimal]::Parse($s,[Globalization.CultureInfo]::GetCultureInfo('tr-TR')); if($r.taraf -eq 'B'){ $bT+=$n } else { $aT+=$n } }catch{} } }
    $adimlar+=@{ anlatim="Son kontrol: borç toplamı alacak toplamına eşit, kayıt denk. Şimdi aynı kaydı sen sürükleyerek yap."; formul="Borç toplamı $($bT.ToString('N0',[cultureinfo]::GetCultureInfo('tr-TR'))) = Alacak toplamı $($aT.ToString('N0',[cultureinfo]::GetCultureInfo('tr-TR'))) → denk"; doldur=@() }
    "    adım sentezlendi ($($adimlar.Count)): $($v.konu)"
  }
  foreach($h in @($tz.Keys)){ $tz[$h]=@{ ad=(TurkceOnar $tz[$h].ad); metin=(TurkceOnar $tz[$h].metin) } }
  # 05.09 Cem: tablo hücreleri ASCII kalıyordu ("Degisken", "Bos kapasite") → Türkçe onarım hücrelere de
  $tablo=$null; if($v.cozum_tablo -and $v.cozum_tablo.satirlar){ $tablo=@{ basliklar=@($v.cozum_tablo.basliklar | ForEach-Object { TurkceOnar "$_" }); satirlar=@(@($v.cozum_tablo.satirlar) | ForEach-Object { ,@(@($_) | ForEach-Object { TurkceOnar "$_" }) }) } }
  elseif(-not $kayit.Count -and $adimlar.Count){
    # teori sorusu: ureticinin KAVRAM TABLOSU (Ne soruluyor / Kural / Bu olayda / Dogru sik) — adimlarin doldur hedefi
    # 06.09 Cem (kalıp-6): üreticinin "Ne soruluyor" cümlesi ayırt edici olguyu yazıp cevabı ele veriyordu ("az gösterilmesi riski…")
    # → satır artık sorunun KENDİ KÖKÜ (soru işaretiyle biten son cümle); kök cevabı ele veremez.
    $satT=@(); $kokM=[regex]::Match("$($v.soru)",'([^.?!]{8,}\?)\s*$'); $neSor=$(if($kokM.Success){ $kokM.Groups[1].Value.Trim() } else { $neT=[regex]::Match($acD,'(?s)Ne soruluyor:\s*(.*?)(?=Kural:|Hesap:|Bu olayda:|Doğrusu:|Dogrusu:|$)'); if($neT.Success){ $neT.Groups[1].Value.Trim() } else { '' } }); if($neSor){ $satT+=,@('Ne soruluyor',(TurkceOnar $neSor)) }
    if($kural){ $satT+=,@('Kural',$kural) }; if($olay){ $satT+=,@('Bu olayda',$olay) }; $satT+=,@('Doğru şık',"$d) $($siklar[$d])")
    if($satT.Count -ge 2){ $tablo=@{ basliklar=@('Adım','İçerik'); satirlar=$satT } }
  }
  # 06.09 ölçüldü: verilen çiftleri cache'te hem [r,c] hem {value:[r,c]} biçiminde; eski kod yalnız .value okuyordu, dizi biçimi 0 verilen sayılıyordu
  $verilen=@(); foreach($vv in @($v.verilen)){ $arr=$(if($vv -and $vv.PSObject.Properties['value']){ @($vv.value) } else { @($vv) }); if($arr.Count -ge 2){ $verilen+=,@([int]$arr[0],[int]$arr[1]) } }
  # 06.09 VERİLENLER BLOĞU (Cem "1 yap"): tablo VERİLENLER → HESAP → SONUÇ diye kurulur. Sorudaki her sayı kendi satırında
  # (ad + değer; anlam Adım 1'de listelenir). Hesap satırları ve adım koordinatları $kay kadar aşağı kayar; Adım 1 verilen satırlarını açar.
  $verilenler=@(); $VER_N=0
  if($v.PSObject.Properties['verilenler'] -and @($v.verilenler).Count -and $tablo -and $tablo.satirlar){
    $verilenler=@(@($v.verilenler) | ForEach-Object { @{ ad=(TurkceOnar "$($_.ad)"); deger="$($_.deger)"; anlam=(TurkceOnar "$($_.anlam)") } })
    $VER_N=$verilenler.Count; $kay=$VER_N+2; $cols=[Math]::Max(2,@($tablo.basliklar).Count)
    $dolgu=@(); if($cols -gt 2){ $dolgu=@(1..($cols-2) | ForEach-Object { '-' }) }
    $yeniSat=@(); $yeniSat+=,(@('VERİLENLER')+@(1..($cols-1) | ForEach-Object { '-' }))
    foreach($vv in $verilenler){ $yeniSat+=,(@($vv.ad,$vv.deger)+$dolgu) }
    $yeniSat+=,(@('HESAP')+@(1..($cols-1) | ForEach-Object { '-' }))
    foreach($st in @($tablo.satirlar)){ $yeniSat+=,@($st) }
    $tablo=@{ basliklar=$tablo.basliklar; satirlar=$yeniSat }
    # PS 5.1 tuzağı (06.09 ölçüldü): tek çiftli liste düz 2 sayıya iniyor, boru içinde `[int]$_[0]+$kay` Object[] hatası veriyor
    # → çiftler List[object] ile kurulur, tek çift düz gelmişse sarılır, dönüş `,` ile korunur.
    function Kaydir($liste,[int]$k){ $out=New-Object System.Collections.Generic.List[object]; $arr=@($liste); if($arr.Count -eq 2 -and -not ($arr[0] -is [array])){ $arr=@(,$arr) }
      foreach($p in $arr){ $pp=$(if($p -and $p.PSObject.Properties['value']){ @($p.value) } else { @($p) }); if($pp.Count -lt 2){ continue }; $r0=[int]$pp[0]; $c0=[int]$pp[1]; $out.Add(@(($r0+$k),$c0)) }; return ,$out.ToArray() }
    $verilen=Kaydir $verilen $kay; $vl=New-Object System.Collections.Generic.List[object]; foreach($p in @($verilen)){ $vl.Add($p) }; for($q=1;$q -le $VER_N;$q++){ $vl.Add(@($q,1)) }; $verilen=$vl.ToArray()
    for($ai=0;$ai -lt $adimlar.Count;$ai++){ $adimlar[$ai].doldur=Kaydir $adimlar[$ai].doldur $kay }
    if($adimlar.Count -and "$($adimlar[0].formul)" -match '^(Verilen|Soruda ne var)'){ $d0=New-Object System.Collections.Generic.List[object]; for($q=1;$q -le $VER_N;$q++){ $d0.Add(@($q,1)) }; foreach($p in @($adimlar[0].doldur)){ $d0.Add($p) }; $adimlar[0].doldur=$d0.ToArray() }
  }
# --- OYUN SORUSU (Cem 04.09 "kaydı sen yap kısmında soru farklı sorsak"): ikiz varsa ikiz; yoksa AYNI OLAY, YENİ TUTARLAR
  # (tüm tutarlar aynı katsayıyla ölçeklenir; oranlar, günler, yıllar dokunulmaz - doğrusal kayıtlarda geçerli)
  $oyun=$null
  if($v.ikiz -and $v.ikiz.ikiz_soru -and $v.ikiz_sema -and "$($v.ikiz_sema.tur)" -eq 'yevmiye'){
    $ik=@(); if($v.ikiz_sema.kayitlar){ $ik=@($v.ikiz_sema.kayitlar) } elseif($v.ikiz_sema.ogeler){ $ik=@(,([pscustomobject]@{baslik='';ogeler=$v.ikiz_sema.ogeler})) }
    if($ik.Count -eq 1 -and $ik[0].ogeler.borc -and $ik[0].ogeler.alacak){ $ok=@(); foreach($og in @($ik[0].ogeler.borc)){ $ok+=@{ hesap=(TurkceOnar "$($og.hesap)"); tutar="$($og.tutar)"; taraf='B' } }; foreach($og in @($ik[0].ogeler.alacak)){ $ok+=@{ hesap=(TurkceOnar "$($og.hesap)"); tutar="$($og.tutar)"; taraf='A' } }; $oyun=@{ tur='ikiz'; soru=(TurkceOnar "$($v.ikiz.ikiz_soru)"); kayit=$ok; not='İkiz soru: aynı yöntem, yeni rakamlar.' } }
  }
  if(-not $oyun -and $kayit.Count){
    $kat=[decimal]2; $tr=[cultureinfo]::GetCultureInfo('tr-TR')
    $olcek={ param($t) [regex]::Replace("$t",'\d{1,3}(?:\.\d{3})+(?:,\d+)?',{ param($m) try{ $n=[decimal]::Parse($m.Value,$tr); ($n*$kat).ToString('N0',$tr) }catch{ $m.Value } }) }
    $ok=@(); foreach($r in $kayit){ $ok+=@{ hesap=$r.hesap; tutar=(& $olcek $r.tutar); taraf=$r.taraf } }
    $oyun=@{ tur='olcek'; soru=(& $olcek "$($v.soru)"); kayit=$ok; not='Aynı olay, tutarlar değişti: kaydı yeni rakamlarla sen yap.' }
  }
  # Cem 04.09 "Sen çöz kaldırılmış; bir soru verip aynısını çözdürüyorduk": tablolu (hesaplama) sorularda ikiz = TABLO DOLDURMA
  # (üretici ikiz.tablo + verilen + bosluk üretir). Aday boş hücreleri yazar, hücre hücre ölçülür.
  if(-not $oyun -and $v.ikiz -and $v.ikiz.PSObject.Properties['tablo'] -and $v.ikiz.tablo -and $v.ikiz.tablo.satirlar){
    # 06.09: cache'te çift iki biçimde: [r,c] ya da {value:[r,c],Count:2} (PS boru sargısı ConvertTo-Json'da böyle yazılır) - ikisi de okunur
    $cift={ param($l) $o=New-Object System.Collections.Generic.List[object]; foreach($p in @($l)){ $arr=$(if($p -and $p.PSObject.Properties['value']){ @($p.value) } else { @($p) }); if($arr.Count -ge 2){ $o.Add(@([int]$arr[0],[int]$arr[1])) } }; ,$o.ToArray() }
    $itb=@{ basliklar=@(@($v.ikiz.tablo.basliklar) | ForEach-Object { TurkceOnar "$_" }); satirlar=@(@($v.ikiz.tablo.satirlar) | ForEach-Object { ,@(@($_) | ForEach-Object { TurkceOnar "$_" }) }) }
    $oyun=@{ tur='tablo'; soru=(TurkceOnar "$($v.ikiz.ikiz_soru)"); hedef=(TurkceOnar "$($v.ikiz.hedef_cumle)"); tablo=$itb; verilen=(& $cift $v.ikiz.verilen); bosluk=(& $cift $v.ikiz.bosluk); not='İkiz soru: aynı yöntem, yeni rakamlar. Boş hücreleri sen doldur.' }
  }
  # 06.09 (Cem "geç"): konu girişi kartı (FAZ G) - Nöbetçi'nin 0. adımı
  $konuGiris=$null; if($v.PSObject.Properties['konu_giris'] -and $v.konu_giris -and $v.konu_giris.nedir){ $konuGiris=@{ nedir=(TurkceOnar "$($v.konu_giris.nedir)"); sinavda=(TurkceOnar "$($v.konu_giris.sinavda)"); yontemler=(TurkceOnar "$($v.konu_giris.yontemler)"); ornek=$(if($v.konu_giris.PSObject.Properties['ornek']){ TurkceOnar "$($v.konu_giris.ornek)" } else { '' }) } }
  if($adimlar.Count -and "$($adimlar[0].formul)" -match '^(Verilen|Soruda ne var|Soru bize)'){ $adimlar[0].verilenAdim=$true }
  $sorular+=@{ id="$($x.et)/$($x.id)"; konu=(TurkceOnar "$($v.konu)"); donem=$x.donem; oyun=$oyun; verilenler=$verilenler; konuGiris=$konuGiris; ders=$(if($x.PSObject.Properties['ders'] -and $x.ders){ "$($x.ders)" } else { 'Finansal Muhasebe' }); soru="$($v.soru)"; siklar=$siklar; dogru=$d; tuzak=$tz; kural=$kural; olay=$olay; hap=(TurkceOnar "$($v.hap)"); sade=$sade; taktik="$($v.sinav_taktigi)"; kayit=$kayit; kayitBaslik="$($x.ky.baslik)"; dayanak="$($v.dayanak)"; adimlar=$adimlar; tablo=$tablo; verilen=$verilen }
  "  $($x.et) $($x.id) · $($v.konu) · $($x.donem) donem · kayit satiri $($kayit.Count)"
}
Sure 'sözlük + soru kurulumu'
# --- HESAP SOZLUGU (Cem 03.09: "yanlis cevaptan konuyu hic bilmeyene anlatir gibi ogretelim; 645 yerine 521 neden?")
# Siklarda ve kayitta gecen her 3 haneli hesap kodunun TEKDUZEN HESAP PLANI tanimi ambardan cekilir (bedel 0).
$KEY=$env:SUPABASE_SERVICE_KEY; $SBH=@{ apikey=$KEY; Authorization="Bearer $KEY"; 'User-Agent'='mevzuat-radar-robot/1.0' }
# --- AMBAR ÖNBELLEĞİ (Cem 04.09 "1 yap": basım 60 sn → 346 sn, ambar sorguları yavaşladı) ---------------------------
# Her sorgunun ilk kaydı (kaynak_ad, metin) diske yazılır (ambar-onbellek.json); 14 gün taze sayılır. Sayım + süre loglanır.
$ONB_YOL=Join-Path $ONB_DIR 'ambar-onbellek.json'; $ONB=@{}
if(Test-Path $ONB_YOL){ try{ $oj=Get-Content $ONB_YOL -Raw -Encoding UTF8 | ConvertFrom-Json; foreach($p in $oj.PSObject.Properties){ $ONB[$p.Name]=$p.Value } }catch{ $ONB=@{} } }
$script:ONB_SORGU=0; $script:ONB_ISABET=0; $script:ONB_SN=[double]0; $script:ONB_KIRLI=$false
function AmbarGetir([string]$u,[string]$anahtar){
  # dönüş: @{kaynak_ad;metin} ya da $null (kayıt yok da önbelleğe yazılır: 'YOK')
  if($ONB.ContainsKey($anahtar)){ $e=$ONB[$anahtar]; $ts=[datetime]::MinValue; try{ $ts=[datetime]::ParseExact("$($e.ts)",'yyyy-MM-dd',$null) }catch{}
    if(((Get-Date)-$ts).TotalDays -le 14){ $script:ONB_ISABET++; if("$($e.durum)" -eq 'YOK'){ return $null }; return @{ kaynak_ad="$($e.kaynak_ad)"; metin="$($e.metin)" } } }
  $script:ONB_SORGU++; $t0=Get-Date; $son=$null
  try{ $w=Invoke-WebRequest -UseBasicParsing -Uri $u -Headers $SBH -TimeoutSec 60; $c=$w.Content; if($c -is [byte[]]){ $c=[Text.Encoding]::UTF8.GetString($c) }; $r=@(($c | ConvertFrom-Json)); if($r.Count){ $son=@{ kaynak_ad="$($r[0].kaynak_ad)"; metin="$($r[0].metin)" } } }catch{ $script:ONB_SN+=((Get-Date)-$t0).TotalSeconds; return $null }
  $script:ONB_SN+=((Get-Date)-$t0).TotalSeconds
  $ONB[$anahtar]=$(if($son){ @{ ts=(Get-Date -Format 'yyyy-MM-dd'); durum='VAR'; kaynak_ad=$son.kaynak_ad; metin=$son.metin } } else { @{ ts=(Get-Date -Format 'yyyy-MM-dd'); durum='YOK' } }); $script:ONB_KIRLI=$true
  return $son
}
function AmbarKaydet(){ if($script:ONB_KIRLI){ [IO.File]::WriteAllText($ONB_YOL,(ConvertTo-Json -InputObject $ONB -Depth 4 -Compress),[Text.UTF8Encoding]::new($false)) }; "ambar: $($script:ONB_SORGU) sorgu ($([math]::Round($script:ONB_SN)) sn) · $($script:ONB_ISABET) önbellekten · dosya $([math]::Round((Get-Item $ONB_YOL -ErrorAction SilentlyContinue).Length/1KB)) KB" }
$THP=@{}
function ThpTanim([string]$kod){
  if($THP.ContainsKey($kod)){ return $THP[$kod] }
  $u='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar?select=kaynak_ad,metin&kaynak_ad=ilike.'+[uri]::EscapeDataString("THP $kod %")+'&limit=1'
  $son=$null
  try{ $g=AmbarGetir $u ("THP|"+$kod); $r=@(); if($g){ $r=@($g) }   # @($null).Count 1 döner - PS 5.1 tuzağı
    if($r.Count){ $ad=("$($r[0].kaynak_ad)" -replace '^THP\s*\d{3}\s*-\s*','').Trim(); $m="$($r[0].metin)" -replace '\s+',' '; $m=$m -replace '^MSUGT.*?Tekduzen Hesap Plani\s*-\s*',''; $m=$m -replace ('^'+$kod+'\s+[^:]{1,80}:\s*',''); $m=($m -replace '\s*\(\d{2}\.\d{2}\s+eklendi[^)]*\)','').Trim(); if($m.Length -gt 340){ $kes=$m.LastIndexOf('. ',340); if($kes -gt 120){ $m=$m.Substring(0,$kes+1) } else { $m=$m.Substring(0,340)+'…' } }; $son=@{ ad=$ad; tanim=$m } } }catch{}
  $THP[$kod]=$son; return $son
}
for($i=0;$i -lt $sorular.Count;$i++){
  $s=$sorular[$i]; $kodlar=New-Object System.Collections.Generic.HashSet[string]
  foreach($h in $s.siklar.Keys){ foreach($m in [regex]::Matches($s.siklar[$h],'(?<![\d.,])(\d{3})(?![\d.,]|\s*(?:TL|%|adet|gün|yıl|ay))')){ [void]$kodlar.Add($m.Groups[1].Value) } }
  foreach($r in $s.kayit){ $m=[regex]::Match($r.hesap,'^\d{3}'); if($m.Success){ [void]$kodlar.Add($m.Value) } }
  # 05.09 Cem: tablo hücresinde "680 hesap" gibi çıplak kod → sınav dili "680 Çalışmayan Kısım Gider ve Zararları hesabı"
  $tabloKod=@(); if($s.tablo){ foreach($st in $s.tablo.satirlar){ foreach($c in $st){ foreach($m in [regex]::Matches("$c",'(?<![\d.,])([1-7]\d{2})\s+hesa(?:p|bı|bına)\b')){ [void]$kodlar.Add($m.Groups[1].Value); $tabloKod+=$m.Groups[1].Value } } } }
  $hs=@{}; foreach($k in $kodlar){ $t=ThpTanim $k; if($t){ $hs[$k]=$t } }
  if($tabloKod.Count -and $s.tablo){ $yeni=@(); foreach($st in $s.tablo.satirlar){ $yeni+=,@(@($st) | ForEach-Object { $c="$_"; foreach($kod in ($tabloKod | Select-Object -Unique)){ if($hs[$kod]){ $c=[regex]::Replace($c,'(?<![\d.,])'+$kod+'\s+hesa(?:p|bı|bına)\b',("$kod "+$hs[$kod].ad+' hesabı')) } }; $c }) }; $sorular[$i].tablo.satirlar=$yeni }
  # ikiz (oyun) tablosu da aynı onarımdan geçer: Türkçe harf + hesap adı
  if($s.oyun -and $s.oyun.tur -eq 'tablo' -and $s.oyun.tablo){ $yeniO=@(); foreach($st in $s.oyun.tablo.satirlar){ $yeniO+=,@(@($st) | ForEach-Object { $c=TurkceOnar "$_"; foreach($m in [regex]::Matches($c,'(?<![\d.,])([1-7]\d{2})\s+hesa(?:p|bı|bına)\b')){ $kod=$m.Groups[1].Value; $t2=ThpTanim $kod; if($t2){ $c=[regex]::Replace($c,'(?<![\d.,])'+$kod+'\s+hesa(?:p|bı|bına)\b',("$kod "+$t2.ad+' hesabı')) } }; $c }) }; $sorular[$i].oyun.tablo.satirlar=$yeniO }
  $sorular[$i].hesaplar=$hs
  "  hesap sozlugu [$($s.konu)]: $($hs.Count)/$($kodlar.Count) kod bulundu"
}
Sure 'hesap sözlüğü'
# --- 1. SEN ANLAT anahtar kavramlar (ucretsiz surum): hap + kural + adimlardan ayirt edici kokler + dogru siktaki hesap kodlari
$STOPK='^(olarak|olan|olup|için|ile|gibi|daha|sonra|önce|bunun|bunları|hesap|hesabı|hesabına|hesaplar|soruda|verilen|dönem|dönemin|dönemde|dönemi|kayıt|kaydı|kaydedilir|kaydedilerek|yazılır|yapılır|edilir|ettirilir|tarafı|tarafına|tutar|tutarı|toplam|toplamı|şimdi|dikkat|çünkü|yüzden|olduğu|olduğunu|değil|ancak|zaten|henüz|bütün|hangi|nedir|neden|işletme|işletmenin|işlem|işlemin)$'
for($i=0;$i -lt $sorular.Count;$i++){
  $s=$sorular[$i]; $metin=(@("$($s.hap)","$($s.kural)") + @($s.adimlar | ForEach-Object { $_.anlatim })) -join ' '
  $say=@{}; foreach($m in [regex]::Matches($metin,'[A-Za-zÇĞİÖŞÜçğıöşü]{6,}')){ $w=$m.Value.ToLowerInvariant() -creplace 'I','ı'; if($w -match $STOPK){ continue }; $k=$w.Substring(0,[Math]::Min(6,$w.Length)); if(-not $say.ContainsKey($k)){ $say[$k]=@{ n=0; ornek=$w } }; $say[$k].n++ }
  $anahtar=@($say.GetEnumerator() | Sort-Object { $_.Value.n } -Descending | Select-Object -First 6 | ForEach-Object { @{ kok=$_.Key; ornek=$_.Value.ornek } })
  foreach($m in [regex]::Matches("$($s.siklar[$s.dogru])",'(?<![\d.,])([1-7]\d{2})(?![\d.,]|\s*(?:TL|%|adet|gün|yıl|ay))')){ $anahtar+=@{ kok=$m.Groups[1].Value; ornek=$m.Groups[1].Value } }
  $sorular[$i].anahtar=$anahtar
}
Sure 'sen anlat'
# --- 2. SINAVDA NASIL CIKTI: cikmis arsiv metinlerinde konu koklerini tasiyan cumleler (yil + kisa alinti)
$arsivDir=Join-Path $kok 'veri\sgs-arsiv'
$arsivDosya=@(Get-ChildItem $arsivDir -Recurse -File | Where-Object { $_.Name -match '\.duz\.txt$' })
# 04.09 ÖLÇÜLDÜ: bu bölüm 158 sn — her soruda 65 kitapçık yeniden okunup gevşek regex (.{0,120}) tüm arşivde koşuyordu.
# Metinler BİR KEZ belleğe alınır; dönem etiketi olmayan soruda gevşek arama yalnız ilk 12 kitapçıkta.
$arsivMetin=@{}; function ArsivMetin($f){ if(-not $arsivMetin.ContainsKey($f.FullName)){ $arsivMetin[$f.FullName]=[IO.File]::ReadAllText($f.FullName) }; return $arsivMetin[$f.FullName] }   # tembel: yalnız gerekince okunur
# 04.09 (Cem "1 yap"): SINAVDA ÖNBELLEĞİ — konu → dönemler + alıntılar diske yazılır (sinavda-onbellek.json). Damga =
# kitapçık sayısı + en yeni kitapçık tarihi + analiz güncelleme; damga değişirse önbellek sıfırlanır (yeni kitapçık gelince).
$SIN_YOL=Join-Path $ONB_DIR 'sinavda-onbellek.json'; $SIN=@{}; $script:SIN_KIRLI=$false
$sinDamga="$($arsivDosya.Count)|$(($arsivDosya | Measure-Object LastWriteTime -Maximum).Maximum.ToString('yyyyMMddHHmm'))|$(try{ (Get-Item (Join-Path $kok 'veri\sgs-analiz.json')).LastWriteTime.ToString('yyyyMMddHHmm') }catch{ '' })"
if(Test-Path $SIN_YOL){ try{ $sj=Get-Content $SIN_YOL -Raw -Encoding UTF8 | ConvertFrom-Json; if("$($sj.damga)" -eq $sinDamga){ foreach($p in $sj.konular.PSObject.Properties){ $SIN[$p.Name]=$p.Value } } }catch{ $SIN=@{} } }
$script:SIN_ISABET=0
# Cem 04.09 "7 dönem yazıyor, bir dönem vermiş": dönem listesi KONU ETİKETİNDEN (veri/sgs-analiz.json konuSayim,
# köprünün 7'sinin kaynağı); alıntılar o dönemlerin kitapçıklarından aranır.
$analiz=$null; try{ $analiz=Get-Content (Join-Path $kok 'veri\sgs-analiz.json') -Raw -Encoding UTF8 | ConvertFrom-Json }catch{}
for($i=0;$i -lt $sorular.Count;$i++){
  $s=$sorular[$i]; $konuHam="$($sec[$i].v.konu)".ToLowerInvariant()
  if($SIN.ContainsKey($konuHam)){ $e0=$SIN[$konuHam]; $script:SIN_ISABET++; $sorular[$i].cikmis=@{ donemler=@(@($e0.donemler) | ForEach-Object { "$_" }); ornekler=@(@($e0.ornekler) | ForEach-Object { @{ yil="$($_.yil)"; alinti="$($_.alinti)" } }); kopru=$s.donem }; continue }
  # 05.09: analiz konu adları ASCII ("sapmasi"), cache Türkçe ("sapması") → dönem 0 çıkıyordu; Türkçe harf katlanarak eşlenir
  $konuKat=Katla $konuHam
  $donemler=@(); if($analiz){ foreach($dn in @($analiz.donemler)){ if($dn.konuSayim){ foreach($k in $dn.konuSayim.PSObject.Properties){ if((Katla ($k.Name -replace '^[^|]*\|','')) -eq $konuKat){ $donemler+="$($dn.donem)"; break } } } } }
  $donemler=@($donemler | Select-Object -Unique | Sort-Object)
  $kokler=@(($konuHam -split '\s+') | Where-Object { $_.Length -ge 4 -and $_ -notmatch '^(tms|tfrs|bds)$' } | ForEach-Object { if($_.Length -ge 7){ $_.Substring(0,$_.Length-2) } else { $_ } })
  $bul=@()
  if($kokler.Count){
    $rxGovde=($kokler | ForEach-Object { [regex]::Escape($_) }) -join '[^?.\n]{0,60}'
    $rxGevsek=($kokler | ForEach-Object { [regex]::Escape($_) }) -join '.{0,120}'
    # once etiketli donemlerin kitapciklari (varsa), yoksa tum arsiv; once soru govdesi, bulamazsa gevsek
    $hedefDosya=@($arsivDosya | Where-Object { $ad=$_.Name; @($donemler | Where-Object { $ad -match ('_'+($_ -replace '/','_')+'_') }).Count -gt 0 })
    $etiketli=[bool]$hedefDosya.Count; if(-not $hedefDosya.Count){ $hedefDosya=$arsivDosya }
    $gevsekSayac=0
    foreach($f in $hedefDosya){ $t=ArsivMetin $f; $m=[regex]::Match($t,"(?i)[^?.\n]{0,220}$rxGovde[^?\n]{0,220}\?"); $al=''
      if($m.Success){ $al=$m.Value }
      elseif($etiketli -or $gevsekSayac -lt 12){ $gevsekSayac++; $m=[regex]::Match($t,"(?is)$rxGevsek"); if($m.Success){
          # eslesme siklardaysa, hemen ONCEKI soru cumlesini al ("... hangisidir?"): geriye dogru son '?' ve ondan onceki cumle basi
          $bas=[Math]::Max(0,$m.Index-700); $onceki=$t.Substring($bas,$m.Index-$bas); $q=$onceki.LastIndexOf('?')
          if($q -gt 0){ $govde=$onceki.Substring(0,$q+1); $cs=[Math]::Max($govde.LastIndexOf(".`n"),[Math]::Max($govde.LastIndexOf("`n`n"),$govde.LastIndexOf('. '))); if($cs -gt 0 -and $govde.Length-$cs -lt 420){ $govde=$govde.Substring($cs+1) } elseif($govde.Length -gt 420){ $govde=$govde.Substring($govde.Length-420) }; $al=$govde } else { $al=$t.Substring([Math]::Max(0,$m.Index-180),[Math]::Min(360,$t.Length-[Math]::Max(0,$m.Index-180))) } } }
      if($al){ $yil=[regex]::Match($f.Name,'(\d{4})_(\d)').Value -replace '_','/'; $al=($al -replace '\s+',' ').Trim(); if($al.Length -gt 320){ $al='…'+$al.Substring($al.Length-318) }; $bul+=@{ yil=$yil; alinti=$al } } }
  }
  $ornekler=@($bul | Sort-Object { $_.yil } -Descending | Select-Object -First 3)
  $sorular[$i].cikmis=@{ donemler=$donemler; ornekler=$ornekler; kopru=$s.donem }
  $SIN[$konuHam]=@{ donemler=$donemler; ornekler=$ornekler }; $script:SIN_KIRLI=$true
  "  sinavda: $konuHam -> etiketli $($donemler.Count) dönem ($($donemler -join ', ')) · köprü $($s.donem) · alıntı $($bul.Count)"
}
if($script:SIN_KIRLI){ [IO.File]::WriteAllText($SIN_YOL,(ConvertTo-Json -InputObject @{ damga=$sinDamga; konular=$SIN } -Depth 5 -Compress),[Text.UTF8Encoding]::new($false)) }
"sinavda önbellek: $($script:SIN_ISABET) konu önbellekten · $($sorular.Count-$script:SIN_ISABET) tarandı · damga $sinDamga"
Sure 'sınavda (arşiv tarama)'
# --- 3. KAYNAGI GOSTER (Cem 04.09 son bakis): ambardan gercek madde/hesap metni, hakemin alintiladigi cumle isaretli
for($i=0;$i -lt $sorular.Count;$i++){
  $v=$sec[$i].v; $kl=@()
  foreach($ka in (@($v.kaynak_adlar) | Where-Object { "$_" -notmatch ' p\.0 -' } | Select-Object -First 2)){
    $u='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar?select=kaynak_ad,metin&kaynak_ad=eq.'+[uri]::EscapeDataString("$ka")+'&limit=1'
    try{ $g=AmbarGetir $u ("KAYNAK|"+$ka); $r=@(); if($g){ $r=@($g) }; if($r.Count){ $m="$($r[0].metin)" -replace '\s+',' '; $m=$m -replace '^MSUGT.*?Tekduzen Hesap Plani\s*-\s*',''; if($m.Length -gt 1600){ $m=$m.Substring(0,1600)+'…' }; if("$($r[0].kaynak_ad)" -match '^TEORI'){ $m=TurkceOnar $m }   # 05.09: teori notları ASCII yazılmıştı ("BIRLESIK MALIYET"), ekrana öyle düşüyordu
        $kl+=@{ ad="$($r[0].kaynak_ad)"; metin=$m } } }catch{}
  }
  $alinti=''; $ma=[regex]::Match("$($v.hakem.gerekce)","['‘’""“”]([^'‘’""“”]{20,})['‘’""“”]"); if($ma.Success){ $alinti=$ma.Groups[1].Value.Trim() }
  $sorular[$i].kaynak=@{ liste=$kl; alinti=$alinti; hakem="$($v.hakem.gerekce)" }
  "  kaynak: $($sorular[$i].konu) -> $($kl.Count) metin · alıntı $([bool]$alinti)"
}
Sure 'kaynak'
$json=ConvertTo-Json -InputObject $sorular -Compress -Depth 20
Sure 'json'
$html=@'
<!doctype html><html lang="tr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover,user-scalable=no"><meta name="theme-color" content="#141518"><title>Tetikte · Kaydır-Çöz</title>
<style>
:root{--bg:#141518;--kart:#1e2026;--cizgi:#2e3138;--yazi:#e9e9ec;--dim:#9aa1ad;--mavi:#78b4ff;--yesil:#8fc98f;--kirmizi:#e07b7b;--altin:#e0a458}
*{box-sizing:border-box;-webkit-tap-highlight-color:transparent}html,body{margin:0;height:100%;background:var(--bg);color:var(--yazi);font-family:Segoe UI,system-ui,Arial,sans-serif;overflow:hidden}
#akis{height:100%;overflow-y:auto;scroll-snap-type:y mandatory;scroll-behavior:smooth}
.kart{height:100%;scroll-snap-align:start;scroll-snap-stop:always;position:relative;display:flex;flex-direction:column;padding:14px 14px 0;max-width:560px;margin:0 auto}
.ust{display:flex;justify-content:space-between;align-items:center;font-size:.78em;color:var(--dim);margin-bottom:8px}
.noktalar{display:flex;gap:5px}.noktalar i{width:8px;height:8px;border-radius:50%;background:var(--cizgi);display:block}.noktalar i.ok{background:var(--yesil)}.noktalar i.yan{background:var(--kirmizi)}.noktalar i.simdi{outline:2px solid var(--mavi);outline-offset:1px}
.noktalar.cok{gap:3px;flex-wrap:wrap;max-width:58%;justify-content:center}.noktalar.cok i{width:5px;height:5px}
.tt.teori td:first-child{white-space:nowrap;font-weight:700;color:var(--dim);width:1%}
.sinavDil{font:inherit;font-size:.78em;color:var(--mavi);background:transparent;border:1px solid var(--cizgi);border-radius:999px;padding:1px 8px;margin-left:6px;cursor:pointer}
.sinavDilM{margin-top:6px;font-size:.86em;color:var(--dim);border-left:2px solid var(--cizgi);padding-left:8px}
.govde{flex:1;overflow-y:auto;padding-bottom:90px}
.rozet{display:inline-block;font-size:.72em;color:var(--altin);border:1px solid rgba(224,164,88,.5);border-radius:20px;padding:2px 9px;margin-bottom:8px}
.soru{font-weight:600;font-size:1.02em;line-height:1.45;margin:0 0 12px}
.sik{display:block;width:100%;text-align:left;background:var(--kart);color:var(--yazi);border:1px solid var(--cizgi);border-radius:12px;padding:12px 13px;margin:7px 0;font-size:.95em;cursor:pointer;transition:transform .08s}.sik:active{transform:scale(.985)}
.sik b{color:var(--dim);margin-right:6px}.sik.dogru{border-color:var(--yesil);background:rgba(143,201,143,.12)}.sik.yanlis{border-color:var(--kirmizi);background:rgba(224,123,123,.12)}.sik:disabled{cursor:default}
.ipucu{position:absolute;left:0;right:0;bottom:14px;text-align:center;color:var(--dim);font-size:.8em;pointer-events:none;animation:zipla 1.6s ease-in-out infinite}
@keyframes zipla{0%,100%{transform:translateY(0);opacity:.6}50%{transform:translateY(-6px);opacity:1}}
/* alt panel: cevap */
.panel{position:absolute;left:0;right:0;bottom:0;max-height:78%;background:var(--kart);border-top:1px solid var(--cizgi);border-radius:18px 18px 0 0;transform:translateY(105%);transition:transform .28s ease;overflow-y:auto;padding:12px 14px 20px;box-shadow:0 -10px 30px rgba(0,0,0,.45)}
.panel.acik{transform:translateY(0)}.tutamac{width:38px;height:4px;border-radius:4px;background:var(--cizgi);margin:0 auto 10px}
/* Cem 03.09 "gorunum boyle geliyor": KAPALI panel kartin altina (105%) kayiyor ve SONRAKI KARTIN ustune biniyordu.
   Kapaliyken gorunmez + kart tasan iceriği kirpar. */
.panel{visibility:hidden;transition:transform .28s ease,visibility 0s linear .28s}.panel.acik{visibility:visible;transition:transform .28s ease,visibility 0s}
.kart{overflow:hidden}
.geri{border-left:4px solid var(--kirmizi);background:rgba(224,123,123,.08);padding:9px 11px;border-radius:0 10px 10px 0;margin:6px 0 10px;font-size:.95em}.geri.ok{border-color:var(--yesil);background:rgba(143,201,143,.08)}.geri b{margin-right:4px}
.et{color:var(--mavi);font-weight:800;font-size:.75em;letter-spacing:.3px;text-transform:uppercase;margin-top:8px}.panel p{margin:3px 0 6px;font-size:.95em;line-height:1.45}
.hap{border-left:4px solid var(--altin);background:rgba(224,164,88,.08);padding:8px 11px;border-radius:0 10px 10px 0;font-weight:600;font-size:.93em;margin:8px 0}
/* tek ekran paneli: uc satir + cipler; bolumler dokununca */
.ozet{font-size:.93em;margin:0 0 8px;line-height:1.45}.ozet b{color:var(--yesil)}
.cipler{display:flex;gap:6px;flex-wrap:wrap;margin:10px 0 4px}
.cip2{background:var(--bg);color:var(--yazi);border:1px solid var(--cizgi);border-radius:20px;padding:7px 12px;font-size:.84em;cursor:pointer}.cip2.acik{border-color:var(--mavi);color:var(--mavi)}.cip2.ana{background:var(--yesil);color:#0f1013;font-weight:800;border:0;margin-left:auto}
.cip2.birincil{background:var(--mavi);color:#0f1013;font-weight:800;border:0;padding:9px 14px;font-size:.9em}
.cip2.ek{display:none}.cipler.acikEk .cip2.ek{display:inline-block}.cipler.acikEk .bDaha{color:var(--dim)}
.cipler .bDaha{border-style:dashed;color:var(--dim)}
.sek{display:none;margin-top:8px}.sek.acik{display:block;animation:gir .2s ease}
.diger{font-size:.88em;color:var(--dim)}.diger div{margin:6px 0}
/* yanlis kutusu + hazirlik skoru */
.ustSag{display:flex;align-items:center;gap:6px}.ustCip{background:var(--kart);color:var(--yazi);border:1px solid var(--cizgi);border-radius:14px;padding:2px 8px;font-size:.85em;cursor:pointer}.ustCip.hazir{border-color:var(--yesil);color:var(--yesil)}
.kutuEkran{position:fixed;inset:0;background:rgba(0,0,0,.55);display:none;z-index:40;align-items:flex-end;justify-content:center}.kutuEkran.acik{display:flex}
.kutuIc{background:var(--kart);width:min(100%,640px);max-height:88vh;overflow-y:auto;border-radius:18px 18px 0 0;padding:14px 18px 22px;border:1px solid var(--cizgi)}
@media(min-width:900px){.kutuEkran{align-items:center}.kutuIc{border-radius:18px}}
.kutuIc .basl{display:flex;justify-content:space-between;align-items:center;font-weight:800;margin-bottom:6px}
.skorBuyuk{font-size:3em;font-weight:900;color:var(--yesil);line-height:1}
.dersSat{display:grid;grid-template-columns:1fr 2fr auto;gap:10px;align-items:center;margin:8px 0;font-size:.92em}.dersSat .bar{height:8px;background:var(--cizgi);border-radius:4px;overflow:hidden}.dersSat .bar i{display:block;height:100%;background:var(--yesil)}
.kutuSat{display:flex;justify-content:space-between;align-items:center;gap:10px;border:1px solid var(--cizgi);border-radius:10px;padding:8px 11px;margin:6px 0;font-size:.92em}
/* kaynak metni */
.kaynakAd{color:var(--mavi);font-weight:800;font-size:.85em;margin:8px 0 4px}.kaynakMetin{font-size:.9em;line-height:1.55;max-height:260px;overflow-y:auto;background:var(--bg);border:1px solid var(--cizgi);border-radius:10px;padding:8px 11px}.kaynakMetin mark{background:rgba(224,164,88,.35);color:var(--yazi);padding:1px 2px;border-radius:3px}
/* sen anlat / t-hesabi / sinavda */
.ipnot{font-size:.84em;color:var(--dim);margin:2px 0 8px}
.anlatK{width:100%;background:#0f1013;color:var(--yazi);border:1px solid var(--cizgi);border-radius:10px;padding:9px 11px;font-size:.95em;font-family:inherit;resize:vertical}
.anlatSonuc{font-size:.92em;margin-top:8px;line-height:1.5}.anlatPuan{font-weight:800;font-size:1.05em;margin-bottom:4px}.anlatOrnek{margin-top:8px;border-left:4px solid var(--altin);padding:6px 10px;background:rgba(224,164,88,.08);border-radius:0 8px 8px 0}
.tKutular{display:grid;grid-template-columns:1fr;gap:12px}@media(min-width:600px){.tKutular{grid-template-columns:1fr 1fr}}
.tHesap{background:var(--kart);border:1px solid var(--cizgi);border-radius:12px;padding:10px 12px}.tAd{font-weight:800;text-align:center;margin-bottom:6px;font-size:.92em}
.tGovde{display:grid;grid-template-columns:1fr 1fr;border-top:2px solid var(--yazi);min-height:88px}.tSol{border-right:2px solid var(--yazi);padding:6px 8px}.tSag{padding:6px 8px;text-align:right}
.tBaslik{font-size:.75em;color:var(--dim);text-transform:uppercase;letter-spacing:.3px;margin-bottom:4px}
.tTutar{font-weight:800;color:var(--altin);font-variant-numeric:tabular-nums;transition:opacity .5s,transform .5s}.tTutar.gizliT{opacity:0;transform:translateY(-14px)}.tTutar.gelir{opacity:1;transform:none}
.tBakiye{text-align:center;font-size:.85em;color:var(--yesil);font-weight:700;margin-top:6px;min-height:18px;opacity:0;transition:opacity .5s}.tBakiye.gelir{opacity:1}
.cikmisK{border:1px solid var(--cizgi);border-radius:10px;padding:8px 11px;margin:6px 0;font-size:.88em;color:var(--dim);line-height:1.45}.cikmisK .yil{display:inline-block;background:rgba(120,180,255,.15);color:var(--mavi);font-weight:800;border-radius:6px;padding:1px 7px;margin-right:6px;font-size:.85em}
/* hic bilmeyene: hesap tanimlari */
.ogret{margin:4px 0 6px}.thpNot{font-size:.85em;color:var(--dim);margin:2px 0 8px}
.hesapK{border:1px solid var(--cizgi);border-radius:10px;padding:8px 11px;margin:6px 0;font-size:.9em;line-height:1.45}.hesapK.yan{border-color:rgba(224,123,123,.6)}.hesapK.dog{border-color:rgba(143,201,143,.6)}
.hesapK .rol{font-size:.78em;color:var(--dim);margin-left:6px}.hesapK.yan .rol{color:var(--kirmizi)}.hesapK.dog .rol{color:var(--yesil)}.hesapK div{color:var(--yazi);margin-top:3px}
.neden{font-size:.93em;border-left:4px solid var(--yesil);padding:6px 10px;margin:6px 0}
.oyun .soruMini{font-size:.86em;color:var(--dim);background:var(--kart);border:1px solid var(--cizgi);border-radius:10px;padding:8px 11px;margin-bottom:10px;max-height:26%;overflow-y:auto;line-height:1.45}.oyun .soruMini b{color:var(--yazi)}
.btnrow{display:flex;gap:8px;flex-wrap:wrap;margin:10px 0 4px}.btn{background:var(--bg);color:var(--yazi);border:1px solid var(--cizgi);border-radius:10px;padding:9px 12px;font-size:.9em;cursor:pointer}.btn.ana{background:var(--yesil);color:#0f1013;font-weight:800;border:0}.btn.mavi{border-color:var(--mavi);color:var(--mavi)}
/* surukleme oyunu */
/* Cem 03.09: "ekranlar tam sigmiyor" - tam ekran katmanlar karta degil PENCEREYE sabitlenir (fixed) */
.oyun{position:fixed;top:0;bottom:0;left:50%;transform:translateX(-50%);width:min(100%,560px);background:var(--bg);display:none;flex-direction:column;padding:14px;z-index:20;overflow-y:auto}.oyun.acik{display:flex}
.oyun{right:auto}
#akis,.govde,.tabloSar,.serit,.panel,.oyun{scrollbar-width:none}#akis::-webkit-scrollbar,.govde::-webkit-scrollbar,.tabloSar::-webkit-scrollbar,.serit::-webkit-scrollbar,.panel::-webkit-scrollbar,.oyun::-webkit-scrollbar{display:none}
.oyun h3{margin:4px 0 2px;font-size:1em}.oyun .alt{color:var(--dim);font-size:.82em;margin-bottom:10px}
.satir{display:grid;grid-template-columns:1fr 1fr;gap:8px;align-items:stretch;margin:8px 0;position:relative}
.hesapAd{grid-column:1/3;font-weight:600;font-size:.9em;margin-bottom:2px}
.kutu{border:2px dashed var(--cizgi);border-radius:12px;min-height:56px;display:flex;align-items:center;justify-content:center;color:var(--dim);font-size:.8em;position:relative}.kutu.borc{border-color:rgba(120,180,255,.5)}.kutu.alacak{border-color:rgba(224,164,88,.5)}
.kutu.dolu{border-style:solid}.kutu.dog{border-color:var(--yesil);background:rgba(143,201,143,.12)}.kutu.yan{border-color:var(--kirmizi);background:rgba(224,123,123,.12)}
.cip{position:absolute;left:50%;top:50%;transform:translate(-50%,-50%);background:var(--altin);color:#0f1013;font-weight:800;padding:10px 16px;border-radius:30px;touch-action:none;cursor:grab;user-select:none;box-shadow:0 6px 16px rgba(0,0,0,.4);z-index:3;white-space:nowrap}.cip.tasiniyor{transition:none;cursor:grabbing}.cip.yerlesti{position:static;transform:none;box-shadow:none;padding:8px 14px}
/* 06.09 Cem "hepsini yapsın, yanlış yapsın": tutar havuzu + serbest sürükleme + çeldirici */
.cipHavuz{display:flex;flex-wrap:wrap;gap:8px;min-height:54px;padding:8px 10px;border:1px dashed var(--cizgi);border-radius:12px;margin:6px 0 10px;align-items:center}.cip.havuzda{position:static;transform:none;box-shadow:none;padding:9px 14px}.cip.ucuyor{position:fixed;z-index:60;pointer-events:none;transform:none;box-shadow:0 10px 24px rgba(0,0,0,.5);opacity:.95}
.kutu.hedefAday{background:color-mix(in srgb,var(--mavi) 18%,transparent);border-style:solid}.cip.artan{opacity:.4}.kutu .kutuEt[hidden]{display:none}
.oyun .toplam{display:grid;grid-template-columns:1fr 1fr;gap:8px;margin-top:6px;font-weight:800;font-size:.9em}.oyun .toplam div{text-align:center;padding:6px;border-top:2px solid var(--mavi)}
.oyun .msj{margin-top:10px;font-weight:800;min-height:24px}
.satir .neden{grid-column:1/3;font-size:.86em;color:var(--yazi);border-left:4px solid var(--kirmizi);background:rgba(224,123,123,.08);padding:6px 10px;border-radius:0 8px 8px 0;margin-top:2px;line-height:1.45}.satir .neden b{color:var(--kirmizi)}
.ok{color:var(--yesil)}.hata{color:var(--kirmizi)}
/* ogretmen: adim adim yatay kaydirici */
.ders{position:fixed;top:0;bottom:0;left:50%;right:auto;transform:translateX(-50%);width:min(100%,560px);background:var(--bg);display:none;flex-direction:column;padding:12px 0 0;z-index:21}.ders.acik{display:flex}
.ders .basl{display:flex;justify-content:space-between;align-items:center;padding:0 14px 6px;font-size:.85em;color:var(--dim)}
.ders .tabloSar{padding:0 14px;overflow:auto;max-height:44%;flex:0 0 auto}
/* Cem 03.09: "521 kaplama tam kapanmiyor" - hucre hucre outline yerine SATIR cercevesi (ic golge; tablo
   koseleri kirpmaz, hucre araliklari cerceveyi bolmez) */
.tt tr.kayit.vurguS td{background:rgba(224,164,88,.18);box-shadow:inset 0 2px 0 var(--altin),inset 0 -2px 0 var(--altin)}
.tt tr.kayit.vurguS td:first-child{box-shadow:inset 2px 2px 0 var(--altin),inset 2px -2px 0 var(--altin),inset 0 2px 0 var(--altin),inset 0 -2px 0 var(--altin)}
.tt tr.kayit.vurguS td:last-child{box-shadow:inset -2px 2px 0 var(--altin),inset -2px -2px 0 var(--altin),inset 0 2px 0 var(--altin),inset 0 -2px 0 var(--altin)}
.tt td.vurgu{outline:none;box-shadow:inset 0 0 0 2px var(--altin)}
.serit{min-height:0}.adimK{min-height:120px}
.tt{width:100%;border-collapse:collapse;font-size:.86em;background:var(--kart);border-radius:10px;overflow:hidden}
.tt th{color:var(--yesil);text-align:left;padding:6px 9px;border-bottom:2px solid var(--yesil);font-size:.82em}.tt td{padding:6px 9px;border-bottom:1px dotted var(--cizgi)}
.tt td.ver{border-left:3px solid var(--mavi)}.tt tr.sonuc td{background:rgba(143,201,143,.12);font-weight:800}.tt td.vurgu{outline:2px solid var(--altin);outline-offset:-2px;background:rgba(224,164,88,.18)}
.tt tr.ara th{color:var(--mavi);border-bottom:2px solid var(--mavi);padding-top:10px}.tt tr.kayit{display:none}.tt tr.kayit.goster{display:table-row}.tt td.tutar{text-align:right;color:var(--altin);font-weight:700}.tt td.al{padding-left:28px}
/* tek kartli, animasyonlu adim (Cem 03.09: "geri donme/kaydirma daha profesyonel olsun") */
.serit{flex:1;min-height:0;position:relative;padding:10px 14px 4px;touch-action:pan-y;overflow:hidden}
.adimK{position:absolute;inset:10px 14px 4px;background:var(--kart);border:1px solid var(--altin);border-radius:14px;padding:12px 14px;overflow-y:auto;animation:gir .28s ease both}
.adimK.geri{animation-name:girGeri}@keyframes gir{from{opacity:0;transform:translateX(40px)}to{opacity:1;transform:none}}@keyframes girGeri{from{opacity:0;transform:translateX(-40px)}to{opacity:1;transform:none}}
.adimK .say{color:var(--altin);font-weight:800;font-size:.78em;display:flex;justify-content:space-between}.adimK .say .baslik{color:var(--yazi);font-weight:700}
.adimK code{display:block;background:#0f1013;padding:12px 14px;border-radius:10px;margin:10px 0;white-space:pre-wrap;font-size:1.02em;line-height:1.8;color:var(--mavi);font-family:ui-monospace,Consolas,monospace}.adimK code .esit{color:var(--dim)}.adimK code .satir{display:block}.adimK p{margin:0;font-size:.95em;line-height:1.55}
.adimK code.mat0{background:transparent;padding:0;margin:6px 0;font-family:inherit;line-height:1.5;color:var(--metin)}
.mat{background:#0f1013;border-radius:10px;padding:10px 14px;margin:8px 0;font-variant-numeric:tabular-nums;font-size:1.04em}
.matAd{color:var(--dim);font-size:.82em;letter-spacing:.02em;margin-bottom:6px}.matSatir{display:flex;align-items:center;gap:12px;flex-wrap:wrap;row-gap:10px}
.mat .esit{color:var(--dim);font-size:1.2em;padding:0 2px}.matSonuc{font-weight:900;font-size:1.12em}
.kesir{display:inline-flex;flex-direction:column;align-items:center;vertical-align:middle}.kesir .pay{border-bottom:2px solid var(--metin);padding:0 10px 2px}.kesir .payda{padding:2px 10px 0}
.sutun{display:inline-grid;grid-template-columns:auto auto auto;column-gap:10px;row-gap:3px;align-items:baseline}.sutun .op{color:var(--dim);text-align:right;min-width:12px}.sutun .deg{text-align:right}.sutun .not{color:var(--dim);font-size:.78em;font-style:italic}
.sutun .deg:nth-last-of-type(1){}.matSatir .sutun{padding-bottom:6px;border-bottom:2px solid var(--metin);margin-right:4px}
.notI{color:var(--dim);font-size:.78em;font-style:italic;font-weight:400}.kesir i{color:var(--dim);font-size:.78em;font-style:italic}
.soruIsaret{font-family:inherit;font-size:.98em;line-height:1.6;color:var(--metin);white-space:normal}.soruIsaret .et{font-size:.74em;letter-spacing:.06em;color:var(--dim);text-transform:uppercase;margin-bottom:6px}
.verilenSatir{font-size:.84em;color:var(--dim);margin:2px 0 6px 4px}
.mat.gizliMat{opacity:0;transform:translateY(8px);max-height:0;padding-top:0;padding-bottom:0;margin:0;overflow:hidden}.mat{transition:opacity .35s ease,transform .35s ease}.mat.geldi{animation:matGel .4s ease}@keyframes matGel{from{opacity:0;transform:translateY(8px)}to{opacity:1;transform:none}}
.ucan{position:fixed;z-index:9999;pointer-events:none;font-weight:900;color:var(--altin);background:rgba(224,164,88,.22);border:1px solid var(--altin);border-radius:8px;padding:2px 8px;transition:transform .6s cubic-bezier(.2,.8,.2,1),opacity .6s;will-change:transform}
.tt td.bekliyor{color:transparent}.tt td.indi{animation:indi .7s ease}@keyframes indi{0%{background:rgba(224,164,88,.6);transform:scale(1.15)}100%{background:transparent;transform:scale(1)}}
.matEt{display:inline-block;color:var(--dim);font-size:.82em;margin-right:8px;padding:1px 7px;border:1px solid var(--cizgi);border-radius:999px}.kesir .kesir{margin:0 4px}
.adimK{display:flex;flex-direction:column}.adimK .say,.adimK code,.adimK p{flex:0 0 auto}
.yol{margin-top:auto;padding-top:10px;border-top:1px dashed var(--cizgi)}
.yolCip{display:flex;align-items:center;flex-wrap:wrap;gap:0;font-size:.8em}.yc{display:inline-flex;align-items:center;justify-content:center;min-width:26px;height:26px;border-radius:999px;border:1px solid var(--cizgi);color:var(--dim);padding:0 7px;cursor:pointer;user-select:none;transition:transform .12s}.yc:hover{transform:scale(1.15);border-color:var(--metin);color:var(--metin)}
.yc.gecti{border-color:var(--yesil);color:var(--yesil)}.yc.simdi{background:var(--metin);color:#111;border-color:var(--metin);font-weight:800}.yc.hedef{border-color:var(--altin);color:var(--altin)}
.ycb{width:10px;height:1px;background:var(--cizgi)}.yolAd{margin-left:10px;color:var(--metin);font-weight:700;font-size:1.05em}
.tabloSarO{overflow-x:auto;margin:8px 0}.tt.oyunT td.bosH{padding:3px 4px}.tt.oyunT td.bosH input{width:96px;max-width:100%;font:inherit;font-size:.95em;padding:6px 8px;border-radius:8px;border:1px solid var(--mavi);background:#0f1013;color:var(--metin);text-align:right}
.hucreSar{display:inline-flex;align-items:center;gap:4px}.ipucuB{font:inherit;font-size:.8em;width:22px;height:22px;border-radius:999px;border:1px solid var(--cizgi);background:transparent;color:var(--dim);cursor:pointer}.ipucuB:hover{border-color:var(--altin);color:var(--altin)}.ipucuB:disabled{opacity:.4;cursor:default}
.ipucuM{font-size:.8em;color:var(--altin);margin-top:4px;text-align:right}
.sorB{font:inherit;font-size:.85em;width:24px;height:22px;border-radius:6px;border:1px solid var(--kirmizi);background:transparent;cursor:pointer;padding:0}.sorB:hover{background:rgba(224,110,110,.18)}
.tt.oyunT td.dog input{border-color:var(--yesil);background:rgba(143,201,143,.15)}.tt.oyunT td.yan input{border-color:var(--kirmizi);background:rgba(224,110,110,.15)}.tt.oyunT td.goster input{border-color:var(--altin);background:rgba(224,164,88,.18)}
.yol .neden{margin-top:8px;font-size:.88em;color:var(--metin);background:rgba(224,164,88,.10);border-left:3px solid var(--altin);padding:5px 10px;border-radius:0 8px 8px 0}
.adimK.sonAdim{border-color:var(--yesil)}
.adimBar{display:flex;gap:4px;padding:0 14px 6px}.adimBar i{flex:1;height:5px;border-radius:3px;background:var(--cizgi);display:block;cursor:pointer}.adimBar i.gecti{background:rgba(224,164,88,.55)}.adimBar i.simdi{background:var(--altin)}
.ders .altc{display:flex;justify-content:space-between;align-items:center;padding:8px 14px 14px;font-size:.82em;color:var(--dim);gap:10px}
.ders .altc .btn{min-width:64px}.ders .altc .btn:disabled{opacity:.3}
.tt td.gizliH{color:transparent;position:relative}.tt td.gizliH::after{content:'?';color:var(--dim);position:absolute;left:0;right:0;text-align:right;padding-right:9px;font-weight:700}
.tt td.acildi{animation:yan .5s ease}@keyframes yan{from{background:rgba(224,164,88,.5)}to{background:transparent}}
.tt td.kaynakH{outline:2px solid var(--mavi);outline-offset:-2px;background:rgba(122,168,240,.16);color:var(--mavi);font-weight:700}
.adimK code .kSayi{color:var(--mavi);font-weight:800;background:rgba(122,168,240,.14);border-radius:4px;padding:0 3px}
.adimK code .sSayi{color:var(--altin);font-weight:900;background:rgba(224,164,88,.16);border-radius:4px;padding:0 3px}
.lejant{font-size:.78em;color:var(--dim);margin:6px 2px 0}.lejant i{display:inline-block;width:10px;height:10px;border-radius:2px;vertical-align:-1px;margin:0 3px 0 8px}.lejant i.m{background:var(--mavi)}.lejant i.a{background:var(--altin)}
/* MASAUSTU (Cem 03.09: "ikisine de farkli goruntu"): genis sutun, ogretmen ekraninda tablo solda adimlar sagda */
@media (min-width:900px){
  /* Cem 03.09: "sik tiklayinca cok asagida kaliyor" - masaustunde ALT PANEL YOK; iki kolon: sol soru+siklar,
     sag cevap paneli (UWorld/Becker duzeni). Telefon alt panelde kalir. */
  .kart{max-width:1360px;padding:22px 32px 0;display:grid;grid-template-columns:minmax(0,1fr) minmax(0,1fr);grid-template-rows:auto minmax(0,1fr);column-gap:28px}
  .ust{grid-column:1/3}.govde{grid-column:1;grid-row:2;padding-bottom:24px}.ipucu{left:32px;right:auto;width:calc(50% - 46px);bottom:10px}
  .soru{font-size:1.08em}.sik{font-size:1em;padding:13px 16px}
  .panel{position:static;grid-column:2;grid-row:2;max-height:calc(100vh - 92px);width:auto;left:auto;right:auto;transform:none;border:1px solid var(--cizgi);border-radius:16px;padding:16px 22px 24px;box-shadow:none;transition:opacity .28s ease}
  .panel:not(.acik){visibility:hidden;opacity:0}.panel.acik{visibility:visible;opacity:1;transform:none}
  .tutamac{display:none}.cip2.ana{margin-left:auto}
  .ders,.oyun{width:min(100%,1100px)}
  .ders{display:none;padding:18px 0 0;height:100vh;height:100dvh;overflow:hidden}.ders.acik{display:grid;grid-template-columns:1.1fr 1fr;grid-template-rows:auto minmax(0,1fr) auto;column-gap:18px}
  .ders .basl{grid-column:1/3}.ders .tabloSar{grid-column:1;grid-row:2;max-height:none;min-height:0;padding-left:22px}
  .ders .serit{grid-column:2;grid-row:2;padding:0 22px 0 0;min-height:0}.adimK{inset:0 22px 0 0}.ders .altc{grid-column:1/3}
  .ders .altc .adimBar{flex:1;max-width:520px;margin:0 auto}
  .oyun{padding:22px 28px}.satir{grid-template-columns:1fr 1fr;gap:12px}.kutu{min-height:64px}
  /* hesap kâğıdı masaüstü: cevaptan önce sağ kolon (panelin yeri), cevaptan sonra çiple açılan üst katman */
  /* özgüllük .kart .kagit: temel .kagit kuralı bu bloktan SONRA yazılı, aynı özgüllükte sonraki kazanırdı (06.09 tarayıcıda görüldü) */
  .kart .kagit{position:static;grid-column:2;grid-row:2;transform:none;visibility:visible;height:auto;min-height:0;max-height:calc(100vh - 92px);border:1px dashed var(--cizgi);border-radius:16px;padding:14px 18px 16px;transition:none}
  .kart .kagitGovde{min-height:240px}
  .kart:not(.cevaplandi) .kagitKapat,.kart .kagitAc{display:none}
  .kart.cevaplandi .kagit{display:none}.kart.cevaplandi .kagit.acik{display:flex;position:absolute;top:60px;right:32px;bottom:20px;width:min(46%,640px);z-index:7;background:var(--kart);border-style:solid}
}
/* 06.09 HESAP KÂĞIDI (Cem "yan tarafa kâğıt kalem", "1.2.3 yap, telefona uysun"): TESMER SGS kılavuzu hesap makinesini ve
   müsvedde kâğıdını sınava sokmayı yasaklıyor → kâğıt HESAPLAMAZ, kitapçık kenarı gibidir. Telefon: alt sayfa, parmakla çizim + yazı
   sekmeleri, varsayılan kapalı (✏️ düğmesi). Masaüstü: cevaptan önce sağ kolonda açık, cevaptan sonra "✏️ Kâğıdım" çipiyle üstte açılır.
   Soru başına yerelde saklanır (kc_kagit); kutudan dönen aday eski kâğıdını görür. */
.kagit{position:absolute;left:0;right:0;bottom:0;height:74%;background:var(--kart);border-top:1px solid var(--cizgi);border-radius:18px 18px 0 0;transform:translateY(105%);visibility:hidden;transition:transform .28s ease,visibility 0s linear .28s;display:flex;flex-direction:column;padding:10px 12px 12px;z-index:6}
.kagit.acik{transform:none;visibility:visible;transition:transform .28s ease,visibility 0s}
.kagitUst{display:flex;align-items:center;gap:6px;flex-wrap:wrap;font-size:.8em;color:var(--dim);margin-bottom:6px}.kagitUst b{color:var(--yazi);font-size:1.05em}
.kagitSek{margin-left:auto;display:flex;gap:4px}.kagitSek button{font:inherit;font-size:.82em;background:var(--bg);color:var(--yazi);border:1px solid var(--cizgi);border-radius:14px;padding:4px 10px;cursor:pointer}.kagitSek button.acik{border-color:var(--mavi);color:var(--mavi)}
.kagitGovde{flex:1;min-height:0;position:relative}
.kagitYaz{width:100%;height:100%;resize:none;background:var(--bg);color:var(--yazi);border:1px dashed var(--cizgi);border-radius:10px;padding:8px 12px;font:inherit;font-size:1.02em;line-height:27px;background-image:repeating-linear-gradient(transparent 0 26px,var(--cizgi) 26px 27px);background-attachment:local;outline:none}
.kagitCiz{width:100%;height:100%;display:block;background:var(--bg);border:1px dashed var(--cizgi);border-radius:10px;touch-action:none;cursor:crosshair}
.kagit[data-sek="ciz"] .kagitYaz,.kagit[data-sek="yaz"] .kagitCiz{display:none}
.kagitAc{position:absolute;right:14px;bottom:44px;z-index:5;background:var(--kart);color:var(--yazi);border:1px solid var(--cizgi);border-radius:20px;padding:8px 12px;font:inherit;font-size:.86em;cursor:pointer}.kagitAc.var{border-color:var(--altin);color:var(--altin)}
.kagitNot{font-size:.78em;color:var(--altin);margin-top:4px;min-height:1em}
.tt td.kagitVar::after{content:'✏️';font-size:.72em;margin-left:5px;opacity:.9}
/* 06.09 tahmin kapısı + konu girişi */
.tahminSor{background:var(--kart);border:1px dashed var(--altin);border-radius:12px;padding:14px 16px;margin:10px 0}.tahminSor p{margin:6px 0 10px;line-height:1.5}.tahminGir{display:flex;gap:8px;flex-wrap:wrap;align-items:center}.tahminI{font:inherit;font-size:1.1em;padding:9px 12px;border:1px solid var(--cizgi);border-radius:10px;background:var(--bg);color:var(--yazi);width:160px}.tahminNot{font-size:.78em;color:var(--dim);margin-top:8px}
.tahminSonuc{border-radius:10px;padding:8px 12px;margin-bottom:8px;font-size:.95em}.tahminSonuc.ok{background:color-mix(in srgb,var(--yesil) 14%,transparent);color:var(--yesil)}.tahminSonuc.hata{background:color-mix(in srgb,var(--kirmizi) 14%,transparent);color:var(--kirmizi)}.tahminSonuc b{color:var(--yazi)}
.girisK{padding:4px 0}.girisK .et{margin-top:10px}.girisK p{margin:4px 0 0;line-height:1.55;font-size:1.02em}.girisK .girisOrnek{border-left:3px solid var(--altin);padding-left:10px;color:var(--yazi)}
.kuralKart{background:var(--kart);border:1px solid var(--cizgi);border-left:4px solid var(--altin);border-radius:12px;padding:12px 16px;margin:6px 0 10px}.kuralKart p{margin:4px 0 0;font-size:1.12em;line-height:1.55;font-weight:600}
.tahminT{width:100%;font:inherit;font-size:1em;padding:9px 12px;border:1px solid var(--cizgi);border-radius:10px;background:var(--bg);color:var(--yazi);resize:vertical}
/* 06.09 rakip dersi (UWorld/Becker: şık eleme): şıkkın sağındaki ✕ şıkkı çizer, seçmez; sınavda kâğıtta yapılanın karşılığı */
.sik{position:relative;padding-right:40px}.sikCiz{position:absolute;right:10px;top:50%;transform:translateY(-50%);color:var(--dim);font-size:.85em;padding:4px 6px;border-radius:8px;opacity:.55}.sik:hover .sikCiz{opacity:1}.sik.cizili{opacity:.45}.sik.cizili .sikMetin{text-decoration:line-through}.sik.cizili .sikCiz{color:var(--kirmizi);opacity:1}
.sureCip{font-size:.8em;color:var(--dim);margin-left:8px}
/* 06.09 R1 akran yüzdesi: şıkkın sağ altında küçük yüzde; yanlış şıkta %40+ ise "çoğunluk tuzağı" vurgusu */
.sikYuzde{position:absolute;right:34px;bottom:4px;font-size:.72em;color:var(--dim)}.sik.akranCok .sikYuzde{color:var(--kirmizi);font-weight:700}.sik.dogru .sikYuzde{color:var(--yesil)}
.akranNot{font-size:.84em;color:var(--dim);margin-top:6px}
/* 06.09 VERİLENLER → HESAP → SONUÇ blokları */
.tt tr.blok th{text-align:left;font-size:.72em;letter-spacing:.08em;color:var(--dim);background:var(--bg);padding:7px 8px;cursor:pointer;user-select:none}.tt tr.blok .blokSay{color:var(--altin)}.tt tr.blok .blokAcKapa{float:right;color:var(--mavi)}
.tt tr.vblok.katli{display:none}.tabloSar.acikBlok tr.vblok.katli{display:table-row}
.verilenListe{margin:10px 0 0;padding:0;list-style:none;font-size:.9em}.verilenListe li{padding:6px 0;border-top:1px solid var(--cizgi);line-height:1.45}.verilenListe b{color:var(--mavi)}.verilenListe i{color:var(--dim);font-style:normal}
/* 06.09 GM-2: telefonda rakam klavyesi (inputmode=decimal) işleç vermez → işleç tuş şeridi; yalnız dokunmatikte ve Yaz sekmesinde */
.kagitTus{display:none;gap:4px;flex-wrap:wrap;margin:0 0 6px}.kagitTus button{font:inherit;font-size:1.05em;min-width:36px;height:34px;background:var(--bg);color:var(--yazi);border:1px solid var(--cizgi);border-radius:9px;cursor:pointer}.kagitTus .kagitSatirTus{font-size:.82em;padding:0 10px}
@media (pointer:coarse){ .kagit[data-sek="yaz"] .kagitTus{display:flex} }
.kagitOzet{font-size:.8em;color:var(--dim);margin:6px 2px 0;line-height:1.5}.kagitOzet b{color:var(--yazi)}.kagitYanlis{color:var(--kirmizi);font-weight:700}
.son{justify-content:center;text-align:center}.son .buyuk{font-size:2.6em;font-weight:900;margin:8px 0}.son .seri{font-size:1.1em;color:var(--altin);font-weight:800}
.paylas{background:var(--kart);border:1px solid var(--cizgi);border-radius:14px;padding:14px;margin:14px auto;max-width:320px;text-align:left;font-size:.9em}
</style></head><body>
<div id="akis"></div>
<script>
const SORULAR=__JSON__;
const akis=document.getElementById('akis');
const durum={cevap:{},dogru:0,seri:0};
try{ durum.seri=parseInt(localStorage.getItem('kc_seri')||'0')||0; }catch(e){}
// ===== YANLIS KUTUSU + HAZIRLIK SKORU (Cem 04.09 "1 yap goreyim") — Surgent ReadySCORE + Duolingo Mistakes Hub =====
const GUN=86400000; const KUTU={ kayit:[], kutu:[], oyun:[], ileri:0 };   // ileri: demo icin "zaman ileri sarma" (ms)
try{ KUTU.kayit=JSON.parse(localStorage.getItem('kc_kayit')||'[]'); KUTU.kutu=JSON.parse(localStorage.getItem('kc_kutu')||'[]'); KUTU.oyun=JSON.parse(localStorage.getItem('kc_oyun')||'[]'); KUTU.ileri=parseInt(localStorage.getItem('kc_ileri')||'0')||0; }catch(e){}
const simdi=()=>Date.now()+KUTU.ileri;
function kutuKaydet(){ try{ localStorage.setItem('kc_kayit',JSON.stringify(KUTU.kayit.slice(-500))); localStorage.setItem('kc_kutu',JSON.stringify(KUTU.kutu)); localStorage.setItem('kc_oyun',JSON.stringify(KUTU.oyun.slice(-500))); localStorage.setItem('kc_ileri',String(KUTU.ileri)); }catch(e){} }
// 05.09 Cem "ipucu sayısını Hazırlık Skoru'na yansıt": Sen çöz sonucu kaydedilir — tam (ipuçsuz) = +0,25 ustalık,
// ipuçlu = +0,12, doğruları göster = 0. Yanlış Kutusu'na girmez; yalnız skora işler.
function oyunKaydet(s,sonuc){ KUTU.oyun.push({id:s.id,sonuc:sonuc,t:simdi()}); kutuKaydet(); skorCiz(); }
function cevapKaydet(s,dogruMu){
  KUTU.kayit.push({id:s.id,konu:s.konu,ders:s.ders,donem:s.donem,dogru:dogruMu,t:simdi()});
  const k=KUTU.kutu.find(x=>x.id===s.id);
  if(!dogruMu){ if(k){ k.tur=1; k.due=simdi()+2*GUN; k.yanlis=(k.yanlis||0)+1; } else { KUTU.kutu.push({id:s.id,konu:s.konu,ders:s.ders,donem:s.donem,tur:1,due:simdi()+2*GUN,yanlis:1}); } }
  else if(k){ if(k.tur>=2){ KUTU.kutu=KUTU.kutu.filter(x=>x.id!==s.id); } else { k.tur=2; k.due=simdi()+7*GUN; } }
  kutuKaydet(); skorCiz();
}
function skorHesapla(){
  // konu ustaligi: kutuda -> 0,3 (tur2: 0,6); son cevap dogru ve kutuda degil -> 1; hic cozulmemis -> 0. Agirlik = konunun cikmis donem sayisi (sinav DNA'si).
  const konular={}; SORULAR.forEach(s=>{ konular[s.id]={ders:s.ders,w:Math.max(1,s.donem||1),u:0,cozuldu:false}; });
  KUTU.kayit.forEach(r=>{ const k=konular[r.id]; if(k){ k.cozuldu=true; k.u=r.dogru?1:0; } });
  KUTU.kutu.forEach(x=>{ const k=konular[x.id]; if(k){ k.u=x.tur>=2?0.6:0.3; } });
  const sonOyun={}; KUTU.oyun.forEach(o=>{ sonOyun[o.id]=o.sonuc; }); let oyTam=0,oyIp=0;
  Object.entries(konular).forEach(([id,k])=>{ const o=sonOyun[id]; if(o==='tam'){ k.u=Math.min(1,k.u+0.25); oyTam++; } else if(o==='ipuclu'){ k.u=Math.min(1,k.u+0.12); oyIp++; } });
  const ders={}; let tw=0,tu=0,cz=0; Object.values(konular).forEach(k=>{ if(!ders[k.ders]) ders[k.ders]={w:0,u:0,n:0,c:0}; ders[k.ders].w+=k.w; ders[k.ders].u+=k.w*k.u; ders[k.ders].n++; if(k.cozuldu){ ders[k.ders].c++; cz++; } tw+=k.w; tu+=k.w*k.u; });
  return { toplam: tw?Math.round(tu/tw*100):0, cozulen:cz, n:SORULAR.length, oyunTam:oyTam, oyunIpuclu:oyIp, ders:Object.entries(ders).map(([ad,d])=>({ad,yuzde:d.w?Math.round(d.u/d.w*100):0,cozulen:d.c,n:d.n})) };
}
function skorCiz(){ const sk=skorHesapla(); const vade=KUTU.kutu.filter(x=>x.due<=simdi()).length; const azVeri=KUTU.kayit.length<5; document.querySelectorAll('.skorCip').forEach(el=>{ el.textContent=azVeri?'🎯 —':('🎯 %'+sk.toplam); el.title=azVeri?'Hazırlık skoru 5 sorudan sonra görünür':'Hazırlık skoru'; }); /* 05.09: ilk yanlıştan sonra "%4" görmek caydırıcı; 5 cevaptan önce yüzde yok */ document.querySelectorAll('.kutuCip').forEach(el=>{ el.textContent='📥 '+KUTU.kutu.length+(vade?' ·'+vade+' hazır':''); el.classList.toggle('hazir',vade>0); }); }
function kartSifirla(i){ const k=akis.children[i]; if(!k) return; delete durum.cevap[i]; k.querySelectorAll('.sik').forEach(x=>{ x.disabled=false; x.classList.remove('dogru','yanlis'); }); const p=k.querySelector('.panel'); p.classList.remove('acik'); k.querySelectorAll('.sek').forEach(x=>x.classList.remove('acik')); k.querySelectorAll('.cip2').forEach(x=>x.classList.remove('acik')); k.querySelector('.ipucu').style.display=''; document.querySelectorAll('.noktalar i[data-j="'+i+'"]').forEach(n=>{ n.classList.remove('ok','yan'); }); k.scrollIntoView({behavior:'smooth'}); }
function kutuEkraniAc(){
  let e=document.getElementById('kutuEkran'); if(!e){ e=document.createElement('div'); e.id='kutuEkran'; e.className='kutuEkran'; document.body.appendChild(e); }
  const sk=skorHesapla(); const t=simdi();
  const gunStr=ms=>{ const d=Math.ceil((ms-t)/GUN); return d<=0?'<b style="color:var(--yesil)">şimdi hazır</b>':(d+' gün sonra'); };
  e.innerHTML='<div class="kutuIc"><div class="basl"><span>🎯 Hazırlık skoru ve yanlış kutusu</span><button class="btn" id="kutuKapat" style="padding:5px 10px">✕</button></div>'
   +'<div class="skorBuyuk">%'+sk.toplam+'</div><div class="ipnot">Sınav DNA’sı ağırlıklı: çok çıkan konudaki yanlış daha çok düşürür. Çözülen '+sk.cozulen+' / '+sk.n+' konu · Sen çöz: '+sk.oyunTam+' ipuçsuz (tam puan) · '+sk.oyunIpuclu+' ipuçlu (yarım puan).</div>'
   +sk.ders.map(d=>'<div class="dersSat"><span>'+esc(d.ad)+'</span><div class="bar"><i style="width:'+d.yuzde+'%"></i></div><b>%'+d.yuzde+'</b></div>').join('')
   +'<div class="et" style="margin-top:14px">📥 Yanlış kutusu ('+KUTU.kutu.length+')</div>'
   +(KUTU.kutu.length?KUTU.kutu.map(x=>{ const i=SORULAR.findIndex(s=>s.id===x.id); return '<div class="kutuSat"><div><b>'+esc(x.konu)+'</b> <span class="ipnot" style="display:inline">· '+(x.tur>=2?'2. tur (7 gün)':'1. tur (2 gün)')+' · '+gunStr(x.due)+'</span></div>'+(x.due<=t&&i>=0?'<button class="btn mavi kutuCoz" data-i="'+i+'">Şimdi çöz</button>':'')+'</div>'; }).join(''):'<p class="ipnot">Kutu boş. Yanlış yaptığın her soru buraya düşer ve 2 gün sonra geri gelir.</p>')
   +'<div class="btnrow" style="margin-top:14px"><button class="btn" id="kutuIleri">⏩ Demo: 2 gün ileri sar</button><button class="btn gri" id="kutuSifirla">Verileri sıfırla</button></div>'
   +'<p class="ipnot">Nasıl çalışır: yanlış → kutuya girer, 2 gün sonra geri gelir; o gün doğru bilirsen 7 gün sonra bir kez daha gelir; onu da bilirsen kutudan çıkar ve ustalık tam sayılır.</p></div>';
  e.classList.add('acik');
  e.querySelector('#kutuKapat').addEventListener('click',()=>e.classList.remove('acik'));
  e.querySelector('#kutuIleri').addEventListener('click',()=>{ KUTU.ileri+=2*GUN; kutuKaydet(); kutuEkraniAc(); skorCiz(); });
  e.querySelector('#kutuSifirla').addEventListener('click',()=>{ if(confirm('Skor, kutu ve seri sıfırlansın mı?')){ KUTU.kayit=[]; KUTU.kutu=[]; KUTU.ileri=0; kutuKaydet(); location.reload(); } });
  e.querySelectorAll('.kutuCoz').forEach(b=>b.addEventListener('click',()=>{ e.classList.remove('acik'); kartSifirla(parseInt(b.dataset.i)); }));
}
const esc=s=>String(s||'').replace(/[&<>]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;'}[c]));
const nrm=t=>String(t||'').toLowerCase().replace(/tl/g,'').replace(/[.\s]/g,'').replace(',','.').trim();
const say=t=>{const n=parseFloat(nrm(t));return isNaN(n)?0:n;};
const fmt=n=>n.toLocaleString('tr-TR');
function noktalar(i){ return '<div class="noktalar'+(SORULAR.length>12?' cok':'')+'">'+SORULAR.map((s,j)=>'<i data-j="'+j+'" class="'+(j===i?'simdi':'')+'"></i>').join('')+'<i data-j="son"></i></div>'; }
SORULAR.forEach((s,i)=>{
  const k=document.createElement('section'); k.className='kart'; k.dataset.i=i;
  k.innerHTML='<div class="ust"><span>'+esc(s.konu)+'</span>'+noktalar(i)+'<span class="ustSag"><button class="ustCip skorCip" title="Hazırlık skoru">🎯</button><button class="ustCip kutuCip" title="Yanlış kutusu">📥</button>'+(i+1)+' / '+SORULAR.length+'</span></div>'
   +'<div class="govde"><span class="rozet">📌 '+Math.max(s.donem||0,(s.cikmis&&s.cikmis.donemler)?s.cikmis.donemler.length:0)+' dönemde çıktı</span><p class="soru">'+esc(s.soru)+'</p><div class="siklar">'
   +Object.keys(s.siklar).sort().map(h=>'<button class="sik" data-h="'+h+'"><b>'+h+')</b><span class="sikMetin">'+esc(s.siklar[h])+'</span><span class="sikCiz" title="Bu şıkkı ele (çiz)">✕</span></button>').join('')+'</div></div>'
   +'<div class="ipucu">▲ cevapla, sonra yukarı kaydır</div>'
   +'<div class="kagit" data-sek="yaz"><div class="kagitUst"><b>✏️ Hesap kâğıdı</b><span>sınavda hesap makinesi yok; kâğıda yazar gibi</span><div class="kagitSek"><button class="kagitSekYaz acik">Yaz</button><button class="kagitSekCiz">Çiz</button><button class="kagitTemizle" title="Bu sayfayı temizle">Temizle</button><button class="kagitKapat" title="Kapat">✕</button></div></div><div class="kagitTus"><button data-t="+">+</button><button data-t="−">−</button><button data-t="×">×</button><button data-t="/">/</button><button data-t="=">=</button><button data-t="%">%</button><button data-t="(">(</button><button data-t=")">)</button><button data-t=".">.</button><button data-t=",">,</button><button data-t="&#10;" class="kagitSatirTus">↵ satır</button></div><div class="kagitGovde"><textarea class="kagitYaz" spellcheck="false" inputmode="decimal" placeholder="150.000 − 8.000 = …&#10;142.000 × 120.000 / 200.000 = …"></textarea><canvas class="kagitCiz"></canvas></div><div class="kagitNot"></div></div>'
   +'<button class="kagitAc" title="Hesap kâğıdı">✏️ Kâğıt</button>'
   +'<div class="panel"><div class="tutamac"></div><div class="geri"></div><div class="ozet"></div><div class="hap">💡 '+esc(s.hap)+'</div>'
   +'<div class="cipler"><button class="cip2 bDers">🎬 Nöbetçi anlatsın</button><button class="cip2 bOyun">'+(s.oyun&&s.oyun.tur==='tablo'?'⚖️ Sen çöz':'⚖️ Sen yap')+'</button><button class="cip2 cKagit" title="Hesap kâğıdın">✏️ Kâğıdım</button><button class="cip2 bDaha" title="Daha fazla">⋯ Daha fazla</button><button class="cip2 ana bSonraki">Sonraki ▲</button>'
   +'<button class="cip2 ek cKaynak">📜 Kaynağı göster</button><button class="cip2 ek cOgret">📘 Hesaplar</button><button class="cip2 ek cKural">Kural</button><button class="cip2 ek cAnlat">🧠 Sen anlat</button><button class="cip2 ek cThesap">📒 T-hesabı</button><button class="cip2 ek cCikmis">📈 Sınavda</button><button class="cip2 ek bDiger">Diğer şıklar</button><button class="cip2 ek cHata">🚩 Hata bildir</button></div>'
   +'<div class="sek kaynakS"><div class="et">📜 Kaynak metni</div><div class="kaynakIc"></div></div>'
   +'<div class="sek ogret"></div><div class="sek kuralK"><div class="et">Kural</div><p>'+esc(s.kural)+'</p>'+(s.olay?'<div class="et">Bu olayda</div><p>'+esc(s.olay)+'</p>':'')+'</div><div class="sek diger"></div>'
   +'<div class="sek anlat"><div class="et">🧠 Sen anlat</div><p class="ipnot">Kendi kelimelerinle tek cümle: doğru kayıt neden böyle? Nöbetçi anahtar kavramlara bakar.</p><textarea class="anlatK" rows="3" placeholder="Örnek: gider bu döneme ait, faturası gelmediği için…"></textarea><div class="btnrow"><button class="btn mavi bAnlatGoster">Nöbetçi’ye göster</button></div><div class="anlatSonuc"></div></div>'
   +'<div class="sek thesap"><div class="et">📒 T-hesabı canlansın</div><p class="ipnot">Kayıt defterde böyle görünür: sol taraf borç, sağ taraf alacak.</p><div class="tKutular"></div><div class="btnrow"><button class="btn bThesapOynat">↺ Tekrar oynat</button></div></div>'
   +'<div class="sek cikmis"><div class="et">📈 Bu konu sınavda nasıl çıktı</div><div class="cikmisIc"></div></div></div>'
   +'<div class="ders"><div class="basl"><span>🎬 Nöbetçi anlatıyor · '+esc(s.konu)+'</span><button class="btn bDersKapat" style="padding:5px 10px">✕</button></div><div class="tabloSar"></div><div class="serit"></div><div class="altc"><button class="btn bOnce">◀ Geri</button><div class="adimBar"></div><button class="btn bSonra">İleri ▶</button></div></div>'
   +'<div class="oyun"><div class="soruMini"><b>'+(s.oyun&&(s.oyun.tur==='ikiz'||s.oyun.tur==='tablo')?'İkiz soru':'Yeni tutarlarla')+':</b> '+esc(s.oyun?s.oyun.soru:s.soru)+'<div class="ipnot" style="margin:6px 0 0">'+esc(s.oyun?s.oyun.not:'')+'</div></div><h3>⚖️ '+esc(s.kayitBaslik||'Kaydı sen yap')+'</h3><div class="alt">Havuzdaki tutarları hesapların <b>BORÇ</b> ya da <b>ALACAK</b> kutusuna sürükle; fazladan tutar var, hepsini kullanma. Bitince <b>Kontrol et</b>.</div><div class="satirlar"></div><div class="toplam"><div>Borç <span class="tb">—</span></div><div>Alacak <span class="ta">—</span></div></div><div class="msj"></div><div class="btnrow"><button class="btn bOyunKapat">← Karta dön</button><button class="btn bTekrar">↺ Tekrar</button></div></div>';
  akis.appendChild(k);
  const panel=k.querySelector('.panel'); const geri=k.querySelector('.geri');
  // 06.09 rakip dersi: şık eleme (✕) — seçmeden çizer; sınavda kâğıtta yapılan eleme burada da yapılır, cevap anında kayda geçer
  k.querySelectorAll('.sikCiz').forEach(x=>x.addEventListener('click',e=>{ e.stopPropagation(); if(durum.cevap[i]!==undefined) return; x.closest('.sik').classList.toggle('cizili'); }));
  // 06.09 rakip dersi: soru süresi — kart görünür olunca başlar, cevapta durur; cevap satırında gösterilir, kasaya gider
  if(!durum.t0) durum.t0={}; if(!durum.sn) durum.sn={};
  k.querySelectorAll('.sik').forEach(b=>b.addEventListener('click',()=>{
    if(durum.cevap[i]!==undefined) return; const h=b.dataset.h; durum.cevap[i]=h;
    if(durum.t0[i]){ durum.sn[i]=Math.round((Date.now()-durum.t0[i])/1000); }
    const elenen=[...k.querySelectorAll('.sik.cizili')].map(x=>x.dataset.h);
    k.querySelectorAll('.sik').forEach(x=>{ x.disabled=true; if(x.dataset.h===s.dogru) x.classList.add('dogru'); });
    const dogruMu=(h===s.dogru); const t=s.tuzak[h]||{};
    // TELEFONDA TEK EKRAN (Cem 03.09): panelde uc satir - tuzak (tek cumle) / dogru hesap tek satir / hap; gerisi ciplerde
    // Cem 03.09 "yarım kalmış": kesme yok - ilk cümle (nokta/noktalı virgül) TAM gösterilir
    const ilkCumle=m=>{ const x=String(m||'').split(/Doğrusu:|Dogrusu:/)[0].trim(); const c=x.split(/(?<=[.!?;])\s+/)[0].trim(); return c.length>40?c:x; };
    const dogruK0=[...new Set([...String(s.siklar[s.dogru]||'').matchAll(/(?<![\d.,])(\d{3})(?![\d.,]|\s*(?:TL|%|adet|gün|yıl|ay))/g)].map(x=>x[1]))];
    const hs0=s.hesaplar||{}; const dogruAd=dogruK0.filter(x=>hs0[x]).map(x=>x+' '+hs0[x].ad).join(', ');
    // 04.09 FAZ S (Cem "herkesin anlayacağı dil"): sade katman varsa tuzak ve Doğrusu sade cümleyle; sınav dili tıklayınca açılır
    const sd=s.sade||null; const sdSik=sd&&sd.siklar?sd.siklar[h]:'';
    const sureH=(durum.sn[i]!==undefined)?'<span class="sureCip">⏱ '+(durum.sn[i]>=60?Math.floor(durum.sn[i]/60)+' dk '+(durum.sn[i]%60)+' sn':durum.sn[i]+' sn')+(elenen.length?' · elediğin: '+elenen.join(', '):'')+'</span>':'';
    if(dogruMu){ durum.dogru++; geri.className='geri ok'; geri.innerHTML='✅ <b>Doğru.</b> '+esc(sd&&sd.dogru?sd.dogru:ilkCumle(s.kural))+sureH; }
    else { b.classList.add('yanlis'); geri.className='geri'; geri.innerHTML='❌ <b>'+esc(t.ad||'Tuzak')+':</b> '+esc(sdSik?sdSik:ilkCumle(t.metin))+sureH; }
    // dogruda tekrar satiri yok (sik zaten yesil); yanlista tek satir "Dogrusu"
    const nedenKisa=(t.metin||'').split(/Doğrusu:|Dogrusu:/)[1]; const oz=k.querySelector('.ozet'); if(dogruMu){ oz.style.display='none'; } else { oz.innerHTML='✅ <b>Doğrusu '+s.dogru+':</b> '+esc(sd&&sd.dogru?sd.dogru:(nedenKisa?nedenKisa.trim():(dogruAd?dogruAd:String(s.siklar[s.dogru])))); }
    if(sd&&sd.sinav){ const sdEl=dogruMu?geri:oz; sdEl.innerHTML+=' <button class="sinavDil">sınav dili</button><div class="sinavDilM" hidden>📝 '+esc(sd.sinav)+'</div>'; sdEl.querySelector('.sinavDil').addEventListener('click',e=>{ const m=sdEl.querySelector('.sinavDilM'); m.hidden=!m.hidden; e.target.textContent=m.hidden?'sınav dili':'gizle'; }); }
    // Cem 04.09 "akılda kalsın gerekli mi?": hap, kural/dogrusu ile AYNI seyi soyluyorsa gizlenir (uc kez ayni cumle olmasin);
    // yalniz kisa ve farkli bir ezber cumlesiyse kalir. Kalip kilidinde istem "12 kelimelik ezber cumlesi" yazacak.
    const kel=t=>new Set(kat(t).match(/[a-zçğıöşü]{5,}/g)||[]); const hapK=kel(s.hap); const refK=kel(String(s.kural)+' '+String(oz.innerText||'')+' '+String(geri.innerText||''));
    let ortak=0; hapK.forEach(w=>{ if(refK.has(w)) ortak++; }); const oran=hapK.size?ortak/hapK.size:1; const hapEl=k.querySelector('.hap'); if(oran>=0.6||String(s.hap||'').length>140){ hapEl.style.display='none'; } else { hapEl.innerHTML='💡 <b>Akılda kalsın:</b> '+esc(s.hap); }
    // HİÇ BİLMEYENE (Cem 03.09): secilen siktaki hesaplar ile dogru siktaki hesaplarin THP tanimlari yan yana
    const kodlar=m=>[...String(m||'').matchAll(/(?<![\d.,])(\d{3})(?![\d.,]|\s*(?:TL|%|adet|gün|yıl|ay))/g)].map(x=>x[1]);
    const dogruK=[...new Set(kodlar(s.siklar[s.dogru]))], secK=[...new Set(kodlar(s.siklar[h]))]; const yanlisK=secK.filter(x=>!dogruK.includes(x));
    const hs=s.hesaplar||{}; let og='';
    const satir=(kod,rol)=>{ const d=hs[kod]; if(!d) return ''; return '<div class="hesapK '+rol+'"><b>'+kod+' '+esc(d.ad)+'</b> <span class="rol">'+(rol==='yan'?'senin seçtiğin':'doğru hesap')+'</span><div>'+esc(d.tanim)+'</div></div>'; };
    if(!dogruMu&&yanlisK.length){ og+=yanlisK.map(k=>satir(k,'yan')).join(''); }
    // yanlista yalniz FARK gosterilir (ikisinde de olan 100 Kasa gibi hesaplar listeyi sisirmesin); dogruda hepsi
    og+=(dogruMu?dogruK:dogruK.filter(x=>!secK.includes(x))).map(k=>satir(k,'dog')).join('');
    // Cem 03.09 olcumu: cikmis sinav metinlerinde "THP" kisaltmasi 0 kez geciyor -> ogretilmez; hesaplar kod+adiyla tanitilir
    // 04.09 Cem "belirli süreli sözleşmeyi kısa açıklasak": anahtar kavramlar (FAZ S, tanım ambar metninden) hesapların üstünde
    let kvH=''; if(sd&&sd.kavramlar&&sd.kavramlar.length){ kvH='<div class="et">📘 Kavramları tanı</div>'+sd.kavramlar.map(kv=>'<div class="hesapK dog"><b>'+esc(kv.ad)+'</b>'+(kv.kaynak?' <span class="rol">'+esc(kv.kaynak)+'</span>':'')+'<div>'+esc(kv.tanim)+'</div></div>').join(''); }
    if(og||kvH){ const nedenT=(t.metin||'').split(/Doğrusu:|Dogrusu:/)[1]; k.querySelector('.ogret').innerHTML=kvH+(og?'<div class="et">📘 Hesapları tanı</div>'+og+(nedenT&&!dogruMu?'<p class="neden"><b>Neden bu hesap?</b> '+esc(sdSik?sdSik:nedenT.trim().replace(/THP'de özel olarak /,''))+'</p>':''):''); const cO=k.querySelector('.cOgret'); if(cO&&!og){ cO.textContent='📘 Kavramlar'; } }
    else { const cO=k.querySelector('.cOgret'); if(cO) cO.style.display='none'; }
    document.querySelectorAll('.noktalar i[data-j="'+i+'"]').forEach(n=>n.classList.add(dogruMu?'ok':'yan'));
    cevapKaydet(s,dogruMu);   // yanlis kutusu + hazirlik skoru
    // TEK ANA DUGME (Cem 03.09 "gencleri sikar mi?"): yanlista Nobetci, dogruda Sen yap birincil; gerisi "Daha fazla"da
    const bDersC=k.querySelector('.bDers'), bOyunC=k.querySelector('.bOyun'); [bDersC,bOyunC].forEach(x=>{ if(x) x.classList.remove('birincil'); });
    const kayitVar=!!(s.kayit&&s.kayit.length); const oyunVar=!!(s.oyun&&(s.oyun.tur==='tablo'||(s.oyun.kayit&&s.oyun.kayit.length)));
    if(!kayitVar){ const el=k.querySelector('.cThesap'); if(el) el.style.display='none'; }
    if(!oyunVar){ const el=k.querySelector('.bOyun'); if(el) el.style.display='none'; }
    // 05.09 (GM ürün incelemesi): Maliyet sorusunda "Kaynağı göster" Vergi Usul Kanunu m.275 + teori notu gösteriyor —
    // maliyet TEKNİĞİNİN kaynağı değil, güven zedeler. MSUGT Sıra No 2 deseni bağlanana dek Maliyet'te ve metin yoksa gizli.
    if(/maliyet/i.test(String(s.ders||''))||!(s.kaynak&&s.kaynak.liste&&s.kaynak.liste.length)){ const el=k.querySelector('.cKaynak'); if(el) el.style.display='none'; }
    if((!dogruMu||!oyunVar)&&bDersC){ bDersC.classList.add('birincil'); } else if(bOyunC){ bOyunC.classList.add('birincil'); if(bDersC) bDersC.classList.add('ek'); }
    k.querySelector('.ipucu').style.display='none'; panel.classList.add('acik');
    k.classList.add('cevaplandi'); const kg=k.querySelector('.kagit'); if(kg) kg.classList.remove('acik');   // 06.09: kâğıt kapanır, cevap paneli yerini alır; "✏️ Kâğıdım" ile geri açılır
    // 06.09: kâğıt eşlemesi cevaptan hemen sonra kâğıdın altına + kasaya kayıt (Cem "1 ve 3 yap")
    try{ cevapKasayaYaz(h,dogruMu,durum.sn[i],elenen); akranYuzdesi(); }catch(e){}   // 06.09 R1: cevap kaydı + akran yüzdesi
    try{ const es=kagitEsle(); if(es){ const kn=k.querySelector('.kagitNot'); kn.innerHTML='Tablodan '+es.tabloda.length+'/'+es.tabloN+' değeri bulmuşsun'+(es.eksikTablo.length?'; eksik: <b>'+esc(es.eksikTablo.join(', '))+'</b>':'')+(es.tabloDisi.length?'; tabloda olmayan: <span class="kagitYanlis">'+esc(es.tabloDisi.join(', '))+'</span>':'')+'. Nöbetçi anlatımında ✏️ işaretli hücreler senin bulduklarındır.'; } kagitKasayaYaz(h,dogruMu); }catch(e){}
  }));
  // cipler: tek seferde tek bolum acik (akordeon); panel ancak dokununca uzar
  const sekAc=(sinif,cipEl)=>{ const hedef=k.querySelector('.sek.'+sinif); const acikti=hedef.classList.contains('acik'); k.querySelectorAll('.sek').forEach(x=>x.classList.remove('acik')); k.querySelectorAll('.cip2').forEach(x=>x.classList.remove('acik')); if(!acikti){ hedef.classList.add('acik'); cipEl.classList.add('acik'); hedef.scrollIntoView({block:'nearest',behavior:'smooth'}); } };
  k.querySelector('.bDaha').addEventListener('click',e=>{ const c=k.querySelector('.cipler'); c.classList.toggle('acikEk'); e.currentTarget.textContent=c.classList.contains('acikEk')?'⋯ Daha az':'⋯ Daha fazla'; });
  // ===== ✏️ HESAP KÂĞIDI (06.09 Cem "1.2.3 yap, telefona uysun") — hesaplamaz (TESMER: hesap makinesi yasak), yazı + parmak çizimi, soru başına saklanır
  const kagit=k.querySelector('.kagit'), kYaz=kagit.querySelector('.kagitYaz'), kCiz=kagit.querySelector('.kagitCiz'), kNot=kagit.querySelector('.kagitNot'), kAc=k.querySelector('.kagitAc');
  const KAG_KEY='kc_kagit'; const kagitOku=()=>{ try{ return JSON.parse(localStorage.getItem(KAG_KEY)||'{}'); }catch(e){ return {}; } };
  let kagitDurum=kagitOku()[s.id]||null, cizimVar=false, kaydetZ=null, cizKur=false;
  const ctx=kCiz.getContext('2d');
  const kagitKaydet=()=>{ clearTimeout(kaydetZ); kaydetZ=setTimeout(()=>{ try{ const h=kagitOku(); const c=cizimVar?kCiz.toDataURL('image/png'):((kagitDurum&&kagitDurum.c)||''); if(kYaz.value.trim()||c){ h[s.id]={m:kYaz.value,c:(c.length<250000?c:''),t:Date.now()}; } else { delete h[s.id]; } localStorage.setItem(KAG_KEY,JSON.stringify(h)); kagitDurum=h[s.id]||null; kAc.classList.toggle('var',!!kagitDurum); }catch(e){} },400); };
  if(kagitDurum){ kYaz.value=kagitDurum.m||''; kAc.classList.add('var'); if(Date.now()-kagitDurum.t>3600000){ const gun=Math.floor((Date.now()-kagitDurum.t)/GUN); kNot.textContent='Geçen seferki kâğıdın ('+(gun>0?gun+' gün önce':'bugün')+'). Nerede takıldığına bak, sonra temizleyip yeniden dene.'; } }
  function kanvasBoyut(){ const r=kCiz.getBoundingClientRect(); if(!r.width||!r.height) return; const dpr=window.devicePixelRatio||1; const eski=cizKur&&cizimVar?kCiz.toDataURL():null; kCiz.width=Math.round(r.width*dpr); kCiz.height=Math.round(r.height*dpr); ctx.setTransform(dpr,0,0,dpr,0,0); ctx.lineCap='round'; ctx.lineJoin='round'; ctx.lineWidth=2.2; ctx.strokeStyle=getComputedStyle(document.documentElement).getPropertyValue('--yazi').trim()||'currentColor'; const src=eski||((!cizKur&&kagitDurum&&kagitDurum.c)||null); if(src){ const im=new Image(); im.onload=()=>{ ctx.drawImage(im,0,0,r.width,r.height); }; im.src=src; cizimVar=true; } cizKur=true; }
  let ciziyor=false, sonN=null;
  kCiz.addEventListener('pointerdown',e=>{ ciziyor=true; kCiz.setPointerCapture(e.pointerId); const r=kCiz.getBoundingClientRect(); sonN=[e.clientX-r.left,e.clientY-r.top]; e.preventDefault(); });
  kCiz.addEventListener('pointermove',e=>{ if(!ciziyor) return; const r=kCiz.getBoundingClientRect(); const p=[e.clientX-r.left,e.clientY-r.top]; ctx.beginPath(); ctx.moveTo(sonN[0],sonN[1]); ctx.lineTo(p[0],p[1]); ctx.stroke(); sonN=p; cizimVar=true; });
  const cizBitti=()=>{ if(!ciziyor) return; ciziyor=false; kagitKaydet(); }; kCiz.addEventListener('pointerup',cizBitti); kCiz.addEventListener('pointercancel',cizBitti);
  kYaz.addEventListener('input',kagitKaydet);
  // 06.09 GM-2: işleç tuşları imlecin olduğu yere yazar, odak kâğıtta kalır (telefon rakam klavyesinde + − × / yok)
  kagit.querySelectorAll('.kagitTus button').forEach(b=>b.addEventListener('pointerdown',e=>{ e.preventDefault(); const t=b.dataset.t==='\n'||b.classList.contains('kagitSatirTus')?'\n':b.dataset.t; const a=kYaz.selectionStart||0, z=kYaz.selectionEnd||0; const ek=(t==='\n'||/[()\n.,%]/.test(t))?t:(' '+t+' '); kYaz.value=kYaz.value.slice(0,a)+ek+kYaz.value.slice(z); const c=a+ek.length; kYaz.focus(); try{ kYaz.setSelectionRange(c,c); }catch(x){} kagitKaydet(); }));
  const sekSec=ad=>{ kagit.dataset.sek=ad; kagit.querySelector('.kagitSekYaz').classList.toggle('acik',ad==='yaz'); kagit.querySelector('.kagitSekCiz').classList.toggle('acik',ad==='ciz'); if(ad==='ciz'){ requestAnimationFrame(kanvasBoyut); } };
  kagit.querySelector('.kagitSekYaz').addEventListener('click',()=>{ sekSec('yaz'); setTimeout(()=>kYaz.focus(),120); }); kagit.querySelector('.kagitSekCiz').addEventListener('click',()=>sekSec('ciz'));
  kagit.querySelector('.kagitTemizle').addEventListener('click',()=>{ if(kagit.dataset.sek==='ciz'){ ctx.save(); ctx.setTransform(1,0,0,1,0,0); ctx.clearRect(0,0,kCiz.width,kCiz.height); ctx.restore(); cizimVar=false; if(kagitDurum) kagitDurum.c=''; } else { kYaz.value=''; } kNot.textContent=''; kagitKaydet(); });
  const kagitAc=()=>{ kagit.classList.add('acik'); if(kagit.dataset.sek==='ciz') requestAnimationFrame(kanvasBoyut); };
  const kagitKapat=()=>kagit.classList.remove('acik');
  kagit.querySelector('.kagitKapat').addEventListener('click',kagitKapat); kAc.addEventListener('click',kagitAc);
  const cKg=k.querySelector('.cKagit'); if(cKg) cKg.addEventListener('click',()=>{ if(kagit.classList.contains('acik')) kagitKapat(); else kagitAc(); });
  if(matchMedia('(pointer:coarse)').matches) sekSec('ciz');   // dokunmatik: parmakla çizim varsayılan; masaüstü: yazı
  // 06.09 (Cem "1 yap"): kâğıt ↔ çözüm tablosu eşlemesi. Kâğıttaki rakamlar (yazı sekmesi) tablo değerleriyle karşılaştırılır.
  // Soruda VERİLEN rakamlar "bulmadığın" sayılmaz (onlar hesap değil). Dönüş: {tabloda, eksikTablo, tabloDisi, tabloN}
  const normK=t=>{ const s0=String(t||'').replace(/\s*(TL|₺|kg|adet|saat|ton|br|birim)\s*$/i,'').trim(); return (s0.startsWith('-')?'-':'')+s0.replace(/[^\d,]/g,''); };
  function kagitEsle(){
    const metin=String(kYaz.value||''); if(!metin.trim()) return null;
    const rk=/\d{1,3}(?:\.\d{3})*(?:,\d+)?/g;
    const kagitS=new Set([...metin.matchAll(rk)].map(m=>normK(m[0])).filter(x=>/\d/.test(x)&&x.replace(/\D/g,'').length>=2));
    const soruS=new Set([...String(s.soru||'').matchAll(rk)].map(m=>normK(m[0])));
    const tabloS=new Set(); if(s.tablo){ s.tablo.satirlar.forEach(st=>st.forEach((c,ci)=>{ if(ci>0){ const n=normK(c); if(/\d/.test(n)&&!soruS.has(n)) tabloS.add(n); } })); }
    (s.kayit||[]).forEach(r=>{ const n=normK(r.tutar); if(/\d/.test(n)&&!soruS.has(n)) tabloS.add(n); });
    const fmtK=n=>{ const v=parseFloat(String(n).replace(',','.')); return isNaN(v)?String(n):v.toLocaleString('tr-TR'); };   // "142000" → "142.000"
    const tabloda=[...tabloS].filter(n=>kagitS.has(n)).map(fmtK), eksikTablo=[...tabloS].filter(n=>!kagitS.has(n)).map(fmtK), tabloDisi=[...kagitS].filter(n=>!tabloS.has(n)&&!soruS.has(n)&&n.replace(/\D/g,'').length>=3).map(fmtK);
    // yüzdeler ("%66,67") ve tek-iki haneli katsayılar tabloDisi'ne girmez (oran/katsayı hesap sonucu değil)
    return { tabloda, eksikTablo, tabloDisi, tabloN:tabloS.size, tablodaHam:[...tabloS].filter(n=>kagitS.has(n)) };
  }
  // 06.09 (Cem "3 yap"): kâğıt satırları KASAYA yazılır (kagit_kayit, anon insert; SQL: radar-app/sql/2026-09-06-kagit-kayit.sql).
  // Tablo basılmamışsa istek sessizce düşer (404); prototipte kullanıcı kimliği yok, oturum damgası tarayıcıda üretilir.
  const KAG_SB_URL='https://bjrleanjpyujtajmazxn.supabase.co', KAG_SB_KEY='sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg';
  let oturumDamga=''; try{ oturumDamga=localStorage.getItem('kc_oturum')||''; if(!oturumDamga){ oturumDamga=Math.random().toString(36).slice(2,10)+Date.now().toString(36); localStorage.setItem('kc_oturum',oturumDamga); } }catch(e){}
  // 06.09 R1 (Cem "1 yap"): CEVAP KAYDI + AKRAN YÜZDESİ — her cevap cevap_kayit'e (anon insert), sonra sik_yuzdesi ile
  // "bu şıkkı seçenlerin %N'i" (UWorld). SQL: radar-app/sql/2026-09-06-cevap-kayit.sql; basılmadan 404 sessiz, yüzde çıkmaz.
  function cevapKasayaYaz(secH,dogruMu,sn,elenen){
    try{ const govde={ soru_id:s.id, ders:s.ders, konu:s.konu, secim:secH, dogru:s.dogru, dogru_mu:!!dogruMu, sn:(sn===undefined?null:sn), elenen:elenen||[], tahmin_dogru:0, tahmin_n:0, oturum:oturumDamga, kaynak:'kaydir-coz' };
      fetch(KAG_SB_URL+'/rest/v1/cevap_kayit',{ method:'POST', headers:{ 'Content-Type':'application/json', apikey:KAG_SB_KEY, Authorization:'Bearer '+KAG_SB_KEY, Prefer:'return=minimal' }, body:JSON.stringify(govde) }).catch(()=>{}); }catch(e){}
  }
  function akranYuzdesi(){
    try{ fetch(KAG_SB_URL+'/rest/v1/rpc/sik_yuzdesi',{ method:'POST', headers:{ 'Content-Type':'application/json', apikey:KAG_SB_KEY, Authorization:'Bearer '+KAG_SB_KEY }, body:JSON.stringify({ p_soru_id:s.id }) })
      .then(r=>r.ok?r.json():null).then(rows=>{ if(!rows||!rows.length) return; const top=rows.reduce((a,r)=>a+Number(r.n||0),0); if(top<5) return;   // 5 cevaptan az: yüzde yanıltır, gösterme
        const say={}; rows.forEach(r=>{ say[String(r.secim)]=Number(r.n||0); });
        k.querySelectorAll('.sik').forEach(b=>{ const h=b.dataset.h; const y=Math.round(100*(say[h]||0)/top); let c=b.querySelector('.sikYuzde'); if(!c){ c=document.createElement('span'); c.className='sikYuzde'; b.appendChild(c); } c.textContent='%'+y; c.title=(say[h]||0)+' / '+top+' aday bu şıkkı seçti'; b.classList.toggle('akranCok',y>=40&&h!==s.dogru); });
        const g=k.querySelector('.geri'); if(g&&!g.querySelector('.akranNot')){ const secH=durum.cevap[i]; const n=document.createElement('div'); n.className='akranNot'; n.textContent='👥 '+top+' adayın %'+Math.round(100*(say[secH]||0)/top)+'\'i senin gibi '+secH+' dedi; %'+Math.round(100*(say[s.dogru]||0)/top)+'\'i doğruyu buldu.'; g.appendChild(n); } })
      .catch(()=>{}); }catch(e){}
  }
  function kagitKasayaYaz(secH,dogruMu){
    try{ const metin=String(kYaz.value||''); if(!metin.trim()&&!cizimVar) return; const es=kagitEsle()||{tabloda:[],eksikTablo:[],tabloDisi:[],tabloN:0};
      const govde={ soru_id:s.id, konu:s.konu, ders:s.ders, secim:secH, dogru:s.dogru, dogru_mu:!!dogruMu, metin:metin.slice(0,4000), satir_sayisi:metin.split(/\n/).filter(x=>x.trim()).length, cizim_var:!!cizimVar, tabloda:es.tabloda, eksik:es.eksikTablo, tablo_disi:es.tabloDisi, tablo_n:es.tabloN, oturum:oturumDamga, kaynak:'kaydir-coz' };
      fetch(KAG_SB_URL+'/rest/v1/kagit_kayit',{ method:'POST', headers:{ 'Content-Type':'application/json', apikey:KAG_SB_KEY, Authorization:'Bearer '+KAG_SB_KEY, Prefer:'return=minimal' }, body:JSON.stringify(govde) }).then(r=>{ if(!r.ok) console.warn('kagit_kayit',r.status); }).catch(()=>{});
    }catch(e){}
  }
  window.addEventListener('resize',()=>{ if(kagit.dataset.sek==='ciz'&&(kagit.classList.contains('acik')||(matchMedia('(min-width:900px)').matches&&!k.classList.contains('cevaplandi')))) kanvasBoyut(); });
  k.querySelector('.cOgret').addEventListener('click',e=>sekAc('ogret',e.currentTarget));
  // 📜 KAYNAGI GOSTER: ambardaki gercek metin, hakemin dogruladigi cumle sari
  k.querySelector('.cKaynak').addEventListener('click',e=>{ const ic=k.querySelector('.kaynakIc'); if(!ic.innerHTML){ const ky=s.kaynak||{liste:[]}; if(!ky.liste.length){ ic.innerHTML='<p class="ipnot">Bu soru için ambardan metin çekilemedi.</p>'; } else { ic.innerHTML=ky.liste.map(x=>{ let m=esc(x.metin); if(ky.alinti){ const a=esc(ky.alinti); const i=m.toLowerCase().indexOf(a.toLowerCase()); if(i>=0) m=m.slice(0,i)+'<mark>'+m.slice(i,i+a.length)+'</mark>'+m.slice(i+a.length); } return '<div class="kaynakAd">'+esc(String(x.ad).replace(/^THP\s+/,'Tekdüzen Hesap Planı ').replace(/^VUK \(213 s\.K\.\)/,'Vergi Usul Kanunu').replace(/^TTK \(6102 s\.K\.\)/,'Türk Ticaret Kanunu').replace(/^TBK \(6098 s\.K\.\)/,'Türk Borçlar Kanunu'))+'</div><div class="kaynakMetin">'+m+'</div>'; }).join('')+(ky.alinti?'<p class="ipnot">Sarı işaretli cümle, bağımsız hakemin doğru şık için kaynaktan doğruladığı hükümdür.</p>':'<p class="ipnot">Hakem notu: '+esc(ky.hakem||'')+'</p>'); } } sekAc('kaynakS',e.currentTarget); const mk=k.querySelector('.kaynakIc mark'); if(mk&&k.querySelector('.sek.kaynakS').classList.contains('acik')) setTimeout(()=>mk.scrollIntoView({block:'center',behavior:'smooth'}),250); });
  // 🚩 HATA BILDIR (prototip: yerelde saklanir; uygulamada kasaya 'itiraz' kaydi olur)
  k.querySelector('.cHata').addEventListener('click',()=>{ const n=prompt('Bu soruda ne yanlış? (kısa yaz)'); if(n&&n.trim()){ try{ const l=JSON.parse(localStorage.getItem('kc_hata')||'[]'); l.push({id:s.id,konu:s.konu,not:n.trim(),t:new Date().toISOString()}); localStorage.setItem('kc_hata',JSON.stringify(l)); }catch(e){} alert('Teşekkürler, bildirimin kaydedildi: '+s.id); } });
  // 🧠 SEN ANLAT (Feynman; ucretsiz surum = anahtar kavram kontrolu, model yok)
  k.querySelector('.cAnlat').addEventListener('click',e=>{ sekAc('anlat',e.currentTarget); const ta=k.querySelector('.anlatK'); if(k.querySelector('.sek.anlat').classList.contains('acik')) setTimeout(()=>ta.focus(),200); });
  const kat=t=>String(t||'').toLowerCase().replace(/İ/g,'i').replace(/I/g,'ı');
  k.querySelector('.bAnlatGoster').addEventListener('click',()=>{ const y=kat(k.querySelector('.anlatK').value); const so=k.querySelector('.anlatSonuc'); if(y.trim().length<8){ so.innerHTML='<span style="color:var(--kirmizi)">Bir cümle yaz, sonra göster.</span>'; return; }
    const an=(s.anahtar||[]); const var_=[],yok=[]; an.forEach(a=>{ const kk=kat(a.kok); if(y.includes(kk)) var_.push(a.ornek); else yok.push(a.ornek); });
    const oran=an.length?Math.round(var_.length/an.length*100):0; const renk=oran>=60?'var(--yesil)':(oran>=30?'var(--altin)':'var(--kirmizi)');
    so.innerHTML='<div class="anlatPuan" style="color:'+renk+'">Kavram isabeti: '+var_.length+' / '+an.length+'</div>'+(var_.length?'<div>✔ Yakaladın: '+esc(var_.join(', '))+'</div>':'')+(yok.length?'<div>✖ Eksik: '+esc(yok.join(', '))+'</div>':'')+'<div class="anlatOrnek"><b>Nöbetçi böyle anlatırdı:</b> '+esc(s.hap)+'</div>'; });
  // 📒 T-HESABI CANLANSIN: her hesap icin T; borc sola, alacak saga animasyonla iner
  const fmtT=t=>String(t||'');
  function tKur(){ const kutu=k.querySelector('.tKutular'); const hesaplar=[]; s.kayit.forEach(r=>{ let h=hesaplar.find(x=>x.ad===r.hesap); if(!h){ h={ad:r.hesap,b:[],a:[]}; hesaplar.push(h); } (r.taraf==='B'?h.b:h.a).push(r.tutar); });
    kutu.innerHTML=hesaplar.map(h=>'<div class="tHesap"><div class="tAd">'+esc(h.ad)+'</div><div class="tGovde"><div class="tSol"><div class="tBaslik">Borç</div>'+h.b.map(t=>'<div class="tTutar gizliT">'+esc(fmtT(t))+'</div>').join('')+'</div><div class="tSag"><div class="tBaslik">Alacak</div>'+h.a.map(t=>'<div class="tTutar gizliT">'+esc(fmtT(t))+'</div>').join('')+'</div></div><div class="tBakiye"></div></div>').join(''); }
  // Cem 03.09 "T hesaplarinda rakam yok": cip acilinca KENDILIGINDEN canlanir; dugme = tekrar oynat
  const tOynat=()=>{ const ts=[...k.querySelectorAll('.tKutular .tTutar')]; ts.forEach(t=>{ t.classList.add('gizliT'); t.classList.remove('gelir'); }); k.querySelectorAll('.tBakiye').forEach(b=>b.classList.remove('gelir')); ts.forEach((t,i)=>setTimeout(()=>{ t.classList.remove('gizliT'); t.classList.add('gelir'); },350+i*600));
    setTimeout(()=>{ k.querySelectorAll('.tHesap').forEach(h=>{ const say=x=>{const n=parseFloat(String(x||'').replace(/tl/gi,'').replace(/[.\s]/g,'').replace(',','.'));return isNaN(n)?0:n;}; let b=0,a=0; h.querySelectorAll('.tSol .tTutar').forEach(x=>b+=say(x.textContent)); h.querySelectorAll('.tSag .tTutar').forEach(x=>a+=say(x.textContent)); const fark=b-a; h.querySelector('.tBakiye').textContent=fark>0?('Borç bakiyesi '+fark.toLocaleString('tr-TR')):(fark<0?('Alacak bakiyesi '+(-fark).toLocaleString('tr-TR')):'Bakiye 0'); h.querySelector('.tBakiye').classList.add('gelir'); }); },350+ts.length*600+300); };
  k.querySelector('.cThesap').addEventListener('click',e=>{ tKur(); sekAc('thesap',e.currentTarget); if(k.querySelector('.sek.thesap').classList.contains('acik')) setTimeout(tOynat,250); });
  k.querySelector('.bThesapOynat').addEventListener('click',tOynat);
  // 📈 SINAVDA NASIL CIKTI: arsivden yillar + kisa alintilar (bedel 0)
  k.querySelector('.cCikmis').addEventListener('click',e=>{ const ic=k.querySelector('.cikmisIc'); if(!ic.innerHTML){ const c=s.cikmis||{yillar:[],ornekler:[]}; ic.innerHTML='<p>Bu konu çıkmış sınavlarda <b>'+((c.donemler&&c.donemler.length)||s.donem)+' dönemde</b> soruldu'+(c.donemler&&c.donemler.length?': <b>'+esc(c.donemler.join(', '))+'</b>.':'.')+'</p>'+(c.ornekler||[]).map(o=>'<div class="cikmisK"><span class="yil">'+esc(o.yil)+'</span> …'+esc(o.alinti)+'…</div>').join('')+((c.ornekler&&c.ornekler.length)?'<p class="ipnot">Alıntılar gerçek kitapçık metninden, kısaltılmış. Bizim soru aynı konuyu bugünün mevzuatıyla soruyor.</p>':'<p class="ipnot">Bizim soru aynı konuyu bugünün mevzuatıyla soruyor.</p>'); } sekAc('cikmis',e.currentTarget); });
  k.querySelector('.cKural').addEventListener('click',e=>sekAc('kuralK',e.currentTarget));
  k.querySelector('.bDiger').addEventListener('click',e=>{ const d=k.querySelector('.diger'); if(!d.innerHTML){ d.innerHTML=Object.keys(s.tuzak).sort().map(h=>'<div><b>'+h+')</b> <b style="color:var(--kirmizi)">'+esc(s.tuzak[h].ad)+':</b> '+esc(s.tuzak[h].metin)+'</div>').join(''); } sekAc('diger',e.currentTarget); });
  k.querySelector('.bSonraki').addEventListener('click',()=>{ const n=akis.children[i+1]; if(n) n.scrollIntoView({behavior:'smooth'}); });
  // --- surukleme oyunu
  const oyun=k.querySelector('.oyun'); const satirlar=oyun.querySelector('.satirlar');
  // 05.09 Cem "1.2 yap": kalem adındaki FORMÜL ipucu ("(100.000×0,80)") hem Nöbetçi tablosundan hem oyundan kalkar;
  // hesap adı ("680 Çalışmayan Kısım … hesabı") kalır. Ayrılan ipucu, oyunda "?" düğmesiyle isteğe bağlı açılır.
  function ipucuAyir(t){ let ad=String(t||'').replace(/\s*\((?:-|\+)\)/g,''); const ipuclari=[]; const kalan=[];
    ad=ad.replace(/\s*\(([^()]*)\)/g,(m,ic)=>{ if(!/\d/.test(ic)) return m; const parcalar=ic.split(/\s*[,;]\s*/); const hesap=parcalar.filter(p=>/hesab/i.test(p)&&!/[×x*\/+\-]\s*\d/.test(p)); const form=parcalar.filter(p=>!hesap.includes(p)); if(form.length) ipuclari.push(form.join(', ')); return hesap.length?' ('+hesap.join(', ')+')':''; });
    return { ad: ad.replace(/\s{2,}/g,' ').trim(), ipucu: ipuclari.join(' · ') }; }
  function tabloOyunKur(){
    // TABLO DOLDURMA (Cem 04.09): ikiz tablo, verilen hücreler dolu, boşluklar giriş kutusu; "Kontrol et" hücre hücre ölçer
    const o=s.oyun;
    // 05.09 Cem "tabloyu sen doldur diyoruz ama yanda bütün cevabı veriyoruz; tahtaya çıkıp kendi hesaplasın":
    // (1) kalem adındaki ipucu parantezleri ("(120.000×0,75)", "(9.000/12.000)") KALDIRILIR; (2) VERİLEN = yalnız ikiz soru
    // metninde geçen rakamlar; ara sonuçlar (%75 gibi) verilen sayılmaz, aday hesaplar.
    const soruSayi=new Set([...String(o.soru||'').matchAll(/\d{1,3}(?:\.\d{3})*(?:,\d+)?/g)].map(m=>m[0].replace(/\./g,'').replace(',','.')));
    const normV=t=>String(t||'').replace(/\s*(TL|₺|kg|adet|%)\s*$/i,'').replace(/^%\s*/,'').replace(/\./g,'').replace(',','.').replace(/[^\d.\-]/g,'');
    const ver=new Set(); const bos=new Set();
    // 05.09 (GM ürün incelemesi): rakam eşleşmesi tek başına SIZDIRIYORDU — B'nin eşdeğer miktarı 3.000, metindeki A fiili
    // miktarı 3.000'e çakışınca "verilen" sayılıp dolu geldi. Kural: hücre verilen = metinde geçer VE üretici de verilen
    // listesine yazmış (kesişim). Üretici listesi boşsa eski davranış (yalnız metin eşleşmesi).
    const uretVer=new Set((o.verilen||[]).map(p=>p[0]+','+p[1]));
    o.tablo.satirlar.forEach((st,r)=>st.forEach((c,ci)=>{ if(ci===0) return; const v=String(c).trim(); if(!v||v==='-') return; const n=normV(v); const key=r+','+ci; if(n&&soruSayi.has(n)&&!/^%/.test(v)&&(!uretVer.size||uretVer.has(key))) ver.add(key); else bos.add(key); }));
    const ipucuSil=t=>ipucuAyir(t).ad;
    oyun.querySelector('h3').textContent='⚖️ Tabloyu sen doldur'; oyun.querySelector('.alt').textContent=o.hedef||'Boş hücreleri doldur, sonra Kontrol et.'; oyun.querySelector('.toplam').style.display='none';
    let h='<div class="tabloSarO"><table class="tt oyunT"><thead><tr>'+(o.tablo.basliklar||[]).map(b=>'<th>'+esc(b)+'</th>').join('')+'</tr></thead><tbody>';
    o.tablo.satirlar.forEach((st,r)=>{ const ay=ipucuAyir(st[0]); h+='<tr>'+st.map((c,ci)=>{ const key=r+','+ci; if(ci===0) return '<td>'+esc(ay.ad)+'</td>'; if(bos.has(key)&&String(c).trim()&&String(c).trim()!=='-') return '<td class="bosH" data-r="'+r+'" data-c="'+ci+'" data-v="'+esc(c)+'"><span class="hucreSar"><input inputmode="decimal" placeholder="?" aria-label="hücre">'+(ay.ipucu?'<button class="ipucuB" data-ip="'+esc(ay.ipucu)+'" title="İpucu iste (seri sayılmaz)">?</button>':'')+'</span></td>'; return '<td class="'+(ver.has(key)?'ver':'')+'">'+esc(c)+'</td>'; }).join('')+'</tr>'; });
    h+='</tbody></table></div><div class="btnrow"><button class="btn mavi bKontrol">✔ Kontrol et</button><button class="btn bGoster">Doğruları göster</button></div>';
    satirlar.innerHTML=h;
    const normS=t=>String(t||'').replace(/\s*(TL|₺|kg|adet|%)\s*$/i,'').replace(/\./g,'').replace(',','.').replace(/[^\d.\-]/g,'');
    // Cem 04.09 "tekrar tekrar kontrol edince seri yükseliyor": tablo tamamlanınca kilitlenir, seri BİR kez artar;
    // "Doğruları göster"den sonra tamamlansa da seri artmaz (kendi çözmedi). ↺ Tekrar yeni bir deneme açar.
    let bitti=false, gosterildi=false, ipucuAcildi=false;
    const kilitle=()=>{ bitti=true; satirlar.querySelectorAll('td.bosH input').forEach(i=>i.disabled=true); const bk=satirlar.querySelector('.bKontrol'); if(bk){ bk.disabled=true; bk.textContent='✔ Tamamlandı'; } };
    const olcT=()=>{ if(bitti) return; let d=0,n=0,bosN=0; satirlar.querySelectorAll('td.bosH').forEach(td=>{ n++; const g=normS(td.querySelector('input').value), b=normS(td.dataset.v); if(g==='') bosN++; const ok=g!==''&&(g===b||(!isNaN(parseFloat(g))&&!isNaN(parseFloat(b))&&Math.abs(parseFloat(g)-parseFloat(b))<0.5)); td.classList.toggle('dog',ok); td.classList.toggle('yan',!ok); if(ok) d++; });
      const m=oyun.querySelector('.msj');
      if(d===n){ kilitle();
        if(!gosterildi&&!ipucuAcildi){ durum.seri++; try{ localStorage.setItem('kc_seri',String(durum.seri)); }catch(e){} m.className='msj ok'; m.textContent='🏅 Tablo tam doğru! Seri: '+durum.seri+(durum.seri>=3?' 🔥':'')+' · Hazırlık Skoru +'; if(navigator.vibrate) navigator.vibrate([20,40,20]); oyunKaydet(s,'tam'); }
        else if(!gosterildi){ m.className='msj ok'; m.textContent='Tablo tamam; ipucu aldığın için seri sayılmadı, skora yarım puan işlendi. ↺ Tekrar ile ipuçsuz dene.'; oyunKaydet(s,'ipuclu'); }
        else { m.className='msj ok'; m.textContent='Tablo tamam, ama doğruları açtığın için seri ve skor sayılmadı. ↺ Tekrar ile kendin çöz.'; oyunKaydet(s,'gosterildi'); } }
      else { durum.seri=0; try{ localStorage.setItem('kc_seri','0'); }catch(e){} m.className='msj hata'; m.textContent=d+' doğru · '+(n-d-bosN)+' yanlış · '+bosN+' boş. Kırmızı hücrede 🎬 ile o adımı Nöbetçi anlatır; takılırsan "?" ipucu ya da "Doğruları göster".';
        // 05.09 Cem "2 yap" — Nöbetçi'ye sor: yanlış hücrede tek tık, o hücreyi dolduran ADIM açılır (ipucu ile tam çözüm arası kademe)
        satirlar.querySelectorAll('td.bosH.yan').forEach(td=>{ if(td.querySelector('.sorB')) return; const r=parseInt(td.dataset.r), c=parseInt(td.dataset.c); const b=document.createElement('button'); b.className='sorB'; b.title='Bu adımı Nöbetçi anlatsın'; b.textContent='🎬'; b.addEventListener('click',()=>{ let idx=s.adimlar.findIndex(a=>(a.doldur||[]).some(p=>p[0]===r&&p[1]===c)); if(idx<0){ idx=Math.min(s.adimlar.length-1,Math.max(0,r)); } gosterildi=true; oyun.classList.remove('acik'); dersKur(); adimGoster(idx,1); ders.classList.add('acik'); }); td.querySelector('.hucreSar').appendChild(b); }); } };
    satirlar.querySelector('.bKontrol').addEventListener('click',olcT);
    // 05.09 Cem "Doğruları göster sıralı dolsun": hücreler çözüm sırasıyla 350 ms arayla yazılır, Nöbetçi akışıyla aynı ritim
    satirlar.querySelector('.bGoster').addEventListener('click',()=>{ if(bitti) return; gosterildi=true; const tds=[...satirlar.querySelectorAll('td.bosH')].filter(td=>!td.classList.contains('dog')); tds.forEach((td,q)=>setTimeout(()=>{ if(!document.body.contains(td)) return; const inp=td.querySelector('input'); inp.value=td.dataset.v; td.classList.add('goster','indi'); setTimeout(()=>td.classList.remove('indi'),700); },q*350)); oyun.querySelector('.msj').className='msj'; oyun.querySelector('.msj').textContent='Doğrular sırayla yazılıyor (sarı). Nöbetçi anlatımında hangi adımdan geldiğini görebilirsin. Bu deneme seriye sayılmaz.'; });
    satirlar.querySelectorAll('input').forEach(i=>i.addEventListener('keydown',e=>{ if(e.key==='Enter'){ olcT(); } }));
    // 05.09 "ipucu iste": takılan aday tek hücre için formülü açar; o deneme seriye sayılmaz (hocanın fısıldaması)
    satirlar.querySelectorAll('.ipucuB').forEach(b=>b.addEventListener('click',()=>{ if(bitti) return; ipucuAcildi=true; const td=b.closest('td'); if(!td.querySelector('.ipucuM')){ const m=document.createElement('div'); m.className='ipucuM'; m.textContent='💡 '+b.dataset.ip; td.appendChild(m); } b.disabled=true; const msg=oyun.querySelector('.msj'); msg.className='msj'; msg.textContent='İpucu açıldı; bu deneme seriye sayılmaz.'; }));
    const ilk=satirlar.querySelector('input'); if(ilk) setTimeout(()=>ilk.focus(),150);
  }
  function oyunKur(){
    if(s.oyun&&s.oyun.tur==='tablo'){ oyun.querySelector('.msj').textContent=''; tabloOyunKur(); return; }
    // 06.09 Cem: "rakamlar sadece olduğu yere atıyor; öğrenci öğrenmek istiyorsa hepsini yapsın, yanlış yapsın" → TUTARLAR HAVUZDA
    // KARIŞIK, üstüne sorudaki diğer rakamlar ÇELDİRİCİ olarak eklenir. Öğrenci hangi tutarı hangi hesaba, hangi tarafa koyacağına
    // kendi karar verir; "Kontrol et" ile ölçülür, yanlış kutunun altında nedeni yazar. Serbest sürükleme: bırakılan noktadaki kutu hedeftir.
    satirlar.innerHTML=''; oyun.querySelector('.msj').textContent=''; oyun.querySelector('.tb').textContent='—'; oyun.querySelector('.ta').textContent='—';
    const kayitO=(s.oyun&&s.oyun.kayit&&s.oyun.kayit.length)?s.oyun.kayit:s.kayit;
    const hesaplar=[...new Set(kayitO.map(r=>r.hesap))].sort((a,b)=>a.localeCompare(b,'tr'));
    const gercek=kayitO.map(r=>String(r.tutar));
    const metin=String(s.oyun&&s.oyun.soru?s.oyun.soru:s.soru); const gercekN=new Set(gercek.map(t=>nrm(t)));
    const celdirici=[...new Set([...metin.matchAll(/\d{1,3}(?:\.\d{3})+(?:,\d+)?/g)].map(m=>m[0]))].filter(t=>!gercekN.has(nrm(t))&&nrm(t).replace(/\D/g,'').length>=4).slice(0,2);
    const cipler=[...gercek.map(t=>({t,d:0})),...celdirici.map(t=>({t,d:1}))]; for(let i=cipler.length-1;i>0;i--){ const j=Math.floor(Math.random()*(i+1)); [cipler[i],cipler[j]]=[cipler[j],cipler[i]]; }
    let h='<div class="cipHavuz">'+cipler.map(c=>'<div class="cip havuzda" data-t="'+esc(c.t)+'" data-decoy="'+c.d+'">'+esc(c.t)+'</div>').join('')+'</div>';
    hesaplar.forEach(hs=>{ h+='<div class="satir" data-hesap="'+esc(hs)+'"><div class="hesapAd">'+esc(hs)+'</div><div class="kutu borc"><span class="kutuEt">BORÇ</span></div><div class="kutu alacak"><span class="kutuEt">ALACAK</span></div></div>'; });
    satirlar.innerHTML=h;
    const havuz=satirlar.querySelector('.cipHavuz'); let bittiK=false, kontrolN=0;
    const toplamGuncelle=()=>{ let b=0,a=0; satirlar.querySelectorAll('.kutu.borc .cip').forEach(c=>b+=say(c.dataset.t)); satirlar.querySelectorAll('.kutu.alacak .cip').forEach(c=>a+=say(c.dataset.t)); oyun.querySelector('.tb').textContent=b?fmt(b):'—'; oyun.querySelector('.ta').textContent=a?fmt(a):'—'; };
    const hedefBul=(x,y)=>{ const el=document.elementFromPoint(x,y); const kt=el?el.closest('.kutu'):null; return (kt&&satirlar.contains(kt))?kt:null; };
    const havuzaKoy=cip=>{ const ek=cip.closest('.kutu'); havuz.appendChild(cip); cip.classList.add('havuzda'); cip.classList.remove('yerlesti'); if(ek){ ek.classList.remove('dolu','dog','yan'); const et=ek.querySelector('.kutuEt'); if(et) et.hidden=false; const nd=ek.closest('.satir').querySelector('.neden'); if(nd) nd.remove(); } toplamGuncelle(); };
    const yerlestir=(cip,kutu)=>{ const eski=kutu.querySelector('.cip'); if(eski&&eski!==cip) havuzaKoy(eski); const ek=cip.closest('.kutu'); if(ek&&ek!==kutu){ ek.classList.remove('dolu','dog','yan'); const et0=ek.querySelector('.kutuEt'); if(et0) et0.hidden=false; } kutu.appendChild(cip); cip.classList.remove('havuzda'); cip.classList.add('yerlesti'); kutu.classList.add('dolu'); kutu.classList.remove('dog','yan'); const et=kutu.querySelector('.kutuEt'); if(et) et.hidden=true; const nd=kutu.closest('.satir').querySelector('.neden'); if(nd) nd.remove(); if(navigator.vibrate) navigator.vibrate(10); toplamGuncelle(); };
    let surukle=null;
    satirlar.querySelectorAll('.cip').forEach(cip=>{
      cip.addEventListener('pointerdown',e=>{ if(bittiK) return; e.preventDefault(); const r=cip.getBoundingClientRect(); surukle={cip,dx:e.clientX-r.left,dy:e.clientY-r.top}; cip.classList.add('ucuyor'); cip.style.left=r.left+'px'; cip.style.top=r.top+'px'; cip.style.width=r.width+'px'; cip.setPointerCapture(e.pointerId); });
      cip.addEventListener('pointermove',e=>{ if(!surukle||surukle.cip!==cip) return; cip.style.left=(e.clientX-surukle.dx)+'px'; cip.style.top=(e.clientY-surukle.dy)+'px'; const alt=hedefBul(e.clientX,e.clientY); satirlar.querySelectorAll('.kutu').forEach(q=>q.classList.toggle('hedefAday',q===alt)); });
      const birak=e=>{ if(!surukle||surukle.cip!==cip) return; const alt=hedefBul(e.clientX,e.clientY); cip.classList.remove('ucuyor'); cip.style.left=''; cip.style.top=''; cip.style.width=''; satirlar.querySelectorAll('.kutu').forEach(q=>q.classList.remove('hedefAday')); surukle=null; if(alt){ yerlestir(cip,alt); } else { havuzaKoy(cip); } };
      cip.addEventListener('pointerup',birak); cip.addEventListener('pointercancel',birak);
    });
    oyun.querySelector('.alt').innerHTML='Havuzdaki tutarları hesapların <b>BORÇ</b> ya da <b>ALACAK</b> kutusuna sürükle. Havuzda <b>fazladan</b> tutar var (soruda geçen ama kayda girmeyen); hepsini kullanma. Bitince <b>Kontrol et</b>.';
    let bk=oyun.querySelector('.bKontrolK'); if(!bk){ bk=document.createElement('button'); bk.className='btn mavi bKontrolK'; bk.textContent='✔ Kontrol et'; oyun.querySelector('.btnrow').insertBefore(bk,oyun.querySelector('.bTekrar')); }
    bk.disabled=false; bk.textContent='✔ Kontrol et';
    bk.onclick=()=>{ if(bittiK) return; kontrolN++;
      const bekl={}; kayitO.forEach(r=>{ const key=r.hesap+'|'+r.taraf; bekl[key]=(bekl[key]||0)+say(r.tutar); });
      const kod=h0=>(String(h0).match(/^\d{3}/)||[''])[0];
      const sinifKural=k3=>{ const c=k3.charAt(0), c2=k3.slice(0,2); if(c==='1'||c==='2') return 'varlık hesabı: artınca BORÇ, azalınca alacak'; if(c==='3'||c==='4') return 'yabancı kaynak (borç) hesabı: artınca ALACAK, ödenince borç'; if(c==='5') return 'özkaynak hesabı: artınca ALACAK'; if(c==='6'){ return (['60','64','67'].includes(c2))?'gelir hesabı: gelir doğunca ALACAK':'gider/indirim hesabı: gider doğunca BORÇ'; } if(c==='7') return 'maliyet-gider hesabı: gider doğunca BORÇ'; return ''; };
      let dogru=0,n=0,b=0,a=0;
      satirlar.querySelectorAll('.satir').forEach(sat=>{ const nd=sat.querySelector('.neden'); if(nd) nd.remove(); const hs=sat.dataset.hesap; const k3=kod(hs); const sebep=[];
        ['B','A'].forEach(t=>{ const kutu=sat.querySelector(t==='B'?'.kutu.borc':'.kutu.alacak'); const beklenen=bekl[hs+'|'+t]||0; const cip=kutu.querySelector('.cip'); const varT=cip?say(cip.dataset.t):0; if(t==='B') b+=varT; else a+=varT;
          if(!beklenen&&!cip){ kutu.classList.remove('dog','yan'); return; } n++; const ok=Math.abs(beklenen-varT)<0.5; if(ok) dogru++; kutu.classList.toggle('dog',ok); kutu.classList.toggle('yan',!ok);
          if(!ok){ if(cip&&cip.dataset.decoy==='1') sebep.push('<b>'+esc(cip.dataset.t)+'</b> soruda geçiyor ama bu kayda girmez (çeldirici).'); else if(cip&&!beklenen) sebep.push('Bu hesabın <b>'+(t==='B'?'borç':'alacak')+'</b> tarafına kayıt yok; '+esc(k3+' '+sinifKural(k3))+'.'); else if(!cip&&beklenen) sebep.push('<b>'+(t==='B'?'Borç':'Alacak')+'</b> tarafı boş kaldı; buraya <b>'+fmt(beklenen)+'</b> gelmeli ('+esc(sinifKural(k3))+').'); else sebep.push('<b>'+(t==='B'?'Borç':'Alacak')+'</b> tarafına '+fmt(beklenen)+' gelmeli, sen '+fmt(varT)+' koydun.'); } });
        if(sebep.length){ const d=(s.hesaplar||{})[k3]; const isl=d&&(d.tanim.match(/İşleyişi?\s*:?\s*([^]*)/i)||[])[1]; const el=document.createElement('div'); el.className='neden'; el.innerHTML=sebep.join(' ')+(isl?' <i>'+esc(isl.split(/(?<=[.!?])\s+/)[0].replace(/\.+$/,''))+'.</i>':''); sat.appendChild(el); } });
      toplamGuncelle(); const m=oyun.querySelector('.msj'); const denk=(b===a&&b>0);
      if(dogru===n){ bittiK=true; bk.disabled=true; bk.textContent='✔ Tamamlandı'; satirlar.querySelectorAll('.cip.havuzda').forEach(c=>c.classList.add('artan'));
        if(kontrolN===1){ durum.seri++; try{ localStorage.setItem('kc_seri',String(durum.seri)); }catch(e){} m.className='msj ok'; m.textContent='🏅 Kayıt tam doğru, ilk denemede! Seri: '+durum.seri+(durum.seri>=3?' 🔥':'')+' · Hazırlık Skoru +'; if(navigator.vibrate) navigator.vibrate([20,40,20]); oyunKaydet(s,'tam'); }
        else { m.className='msj ok'; m.textContent='Kayıt doğru; '+kontrolN+'. denemede tamamlandı, skora yarım puan işlendi.'; oyunKaydet(s,'ipuclu'); } }
      else { durum.seri=0; try{ localStorage.setItem('kc_seri','0'); }catch(e){} m.className='msj hata'; m.textContent=dogru+' / '+n+' kutu doğru'+(denk?' (toplamlar denk ama yerler yanlış)':' (borç ve alacak toplamı denk değil)')+'. Kırmızı kutunun altında neden yazıyor; tutarı sürükleyip düzelt, tekrar kontrol et.'; } };
  }
  function olc(){ /* 06.09: kayıt oyunu artık Kontrol et ile ölçülür (bKontrolK) */ }
  k.querySelector('.bOyun').addEventListener('click',()=>{ oyunKur(); oyun.classList.add('acik'); });
  oyun.querySelector('.bOyunKapat').addEventListener('click',()=>oyun.classList.remove('acik'));
  oyun.querySelector('.bTekrar').addEventListener('click',oyunKur);
  // --- OGRETMEN: adim adim yatay kaydirici (Cem 03.09: "ogretmen seklinde kaydirici da iyiydi, onu yapalim")
  const ders=k.querySelector('.ders'); const bDers=k.querySelector('.bDers');
  if(bDers){
    const tabloSar=ders.querySelector('.tabloSar'), serit=ders.querySelector('.serit'), adimBar=ders.querySelector('.adimBar');
    // Cem 03.09 "kalıp gibi olmasın, konuyu öğretelim": üreticinin adım yazmadığı sorularda anlatım, ambardaki
    // GERÇEK hesap tanımlarından (Tekdüzen Hesap Planı metni), sorunun kendi kuralından ve tuzağından kurulur.
    if((!s.adimlar||!s.adimlar.length)&&!(s.kayit&&s.kayit.length)){
      // TEORI sorusu, uretici adim yazmamis: olay -> kural -> dogru sik -> en sik hata (cache metinlerinden, model yok)
      const ilkC=t=>{ const x=String(t||'').split(/(?<=[.!?])\s+/)[0]; return x.length>240?x.slice(0,238)+'…':x; };
      const tz=Object.keys(s.tuzak||{}).map(h=>s.tuzak[h]).find(t=>t&&t.metin);
      s.adimlar=[{formul:'Olay: '+ilkC(s.soru),anlatim:'Önce olayı anla: '+ilkC(s.soru)+' Bizden istenen, bu duruma hangi kuralın uygulanacağı.',doldur:[[0,1]]},
        {formul:'Kural',anlatim:s.kural||s.hap,doldur:[[1,1]]},
        {formul:'Doğru şık: '+s.dogru,anlatim:(s.olay?s.olay+' ':'')+'Doğru şık: '+String(s.siklar[s.dogru]||''),doldur:[[2,1],[3,1]]},
        {formul:'En sık hata',anlatim:(tz?('En sık hata, '+tz.ad+': '+ilkC(tz.metin)):'Şıkları kuralla tek tek sına; kelime benzerliğine aldanma.'),doldur:[]}];
    }
    if((!s.adimlar||!s.adimlar.length||s.adimlar.some(a=>/^Verilen tutar =/.test(a.formul||'')))&&s.kayit&&s.kayit.length){
      const hs=s.hesaplar||{}; const kod=h=>(String(h).match(/^\d{3}/)||[''])[0];
      const ad=[]; const ilkCum=t=>{ const x=String(t||'').split(/(?<=[.!?])\s+/)[0]; return x.length>220?x.slice(0,218)+'…':x; };
      const neSor=(String(s.kural||'')); const soruOz=ilkCum(s.soru);
      ad.push({formul:'Olay: '+soruOz, anlatim:'Önce olayı anla: '+soruOz+' Bizden istenen, bu işlemin defterdeki kaydı. Rakamlar soruda verili; biz hangi hesabın hangi tarafa yazılacağına karar vereceğiz.', doldur:[]});
      s.kayit.forEach(r=>{ const k2=kod(r.hesap); const d=hs[k2]; if(d){ ad.push({formul:k2+' '+d.ad+' nedir?', anlatim:d.tanim, doldur:[]}); } });
      ad.push({formul:'Kural', anlatim:neSor||s.hap, doldur:[]});
      s.kayit.filter(r=>r.taraf==='B').forEach(r=>{ const k2=kod(r.hesap); const d=hs[k2]; const isl=d&&/İşleyişi?\s*:?\s*([^]*)/i.test(d.tanim)?(d.tanim.match(/İşleyişi?\s*:?\s*([^]*)/i)||[])[1]:''; ad.push({formul:r.hesap+' (BORÇ) '+r.tutar+' (soruda verilen)', anlatim:'Borç tarafı: '+r.hesap+'. '+(isl?('Hesabın işleyişi: '+ilkCum(isl)+' '):'')+(s.olay?ilkCum(s.olay):''), doldur:[]}); });
      s.kayit.filter(r=>r.taraf==='A').forEach(r=>{ const k2=kod(r.hesap); const d=hs[k2]; const isl=d&&(d.tanim.match(/İşleyişi?\s*:?\s*([^]*)/i)||[])[1]; ad.push({formul:r.hesap+' (ALACAK) '+r.tutar+' (soruda verilen)', anlatim:'Alacak tarafı: '+r.hesap+'. '+(isl?('Hesabın işleyişi: '+ilkCum(isl)):'Borcun karşılığı bu hesaba alacak yazılır.'), doldur:[]}); });
      const tz=Object.keys(s.tuzak||{}).map(h=>s.tuzak[h]).find(t=>t&&t.metin);
      ad.push({formul:'Denklik ve en sık hata', anlatim:'Borç toplamı alacak toplamına eşit, kayıt denk. '+(tz?('En sık hata, '+tz.ad+': '+ilkCum(tz.metin)+' '):'')+'Şimdi aynı kaydı sen sürükleyerek yap.', doldur:[]});
      s.adimlar=ad;
    }
    const bOnce=ders.querySelector('.bOnce'), bSonra=ders.querySelector('.bSonra');
    let adimNo=0; const gosterilen=new Set(); const acilan=new Set();
    // 06.09 (Cem "geç", 05.09'dan beri önerilen): ADIM İÇİNDE SORU — hesap adımı açılmadan önce "sence kaç çıkar?" sorulur,
    // öğrenci yazar, sonra tahta açılır. Birebir ders: hoca sorar, öğrenci dener, hoca düzeltir. tahmin[j]={cevap,dogru,atla}
    const tahmin={};
    const tahminGerek=(a,j,son)=>{ if(j===0||son||a.kisi||a.giris||a.verilenAdim) return false; const f=String(a.formul||''); if(/^(Verilen|Soruda ne var|Yanlış yol|Senin seçimin)/i.test(f)) return false; if(!(a.doldur&&a.doldur.length)) return false; return !(j in tahmin); };
    const hedefDegeri=a=>{ const p=(a.doldur||[])[0]; if(!p||!s.tablo||!s.tablo.satirlar[p[0]]) return null; const c=String(s.tablo.satirlar[p[0]][p[1]]||''); const ad=ipucuAyir(String(s.tablo.satirlar[p[0]][0]||'')).ad; return {deger:c, ad:ad}; };
    // Cem 03.09 (3): "iptal kari verilmiyor, en sonda hesaplaniyor" - soruda VERILMEYEN hucreler '?' ile gizli
    // baslar, ilgili adim gelince acilir (birikimli). Verilenler bastan acik (mavi kenar).
    function dersKur(){
      // 05.09 (GM ürün incelemesi, Cem "1 yap"): son adım ÖĞRENCİNİN KENDİ HATASINI anlatır. Üreticinin "en sık hata" adımı
      // genel tuzağı gösteriyordu (80); öğrenci A'yı (40) seçmişse kendi yolunu bulamıyordu. Seçilen yanlış şıkkın tuzağı
      // (ad + neden) SON adım olarak eklenir; üreticinin yanlış yolu zaten o şıksa eklenmez. Bedel 0, cache'ten.
      if(!s.adimBase) s.adimBase=(s.adimlar||[]).slice();
      s.adimlar=s.adimBase.slice();
      // 06.09 (Cem "geç"): KONU GİRİŞİ 0. adım — konu nedir / sınavda nasıl sorulur / yöntemler (soruya girmeden harita)
      if(s.konuGiris&&s.konuGiris.nedir&&!(s.adimlar[0]&&s.adimlar[0].giris)){ s.adimlar.unshift({ giris:true, formul:'Konu: '+s.konu, anlatim:'', doldur:[] }); }
      const secH=durum.cevap[i]; const tzS=(secH&&secH!==s.dogru&&s.tuzak)?s.tuzak[secH]:null;
      if(tzS&&s.adimlar.length){
        const sonF=String(s.adimlar[s.adimlar.length-1].formul||''); const hatali=(sonF.match(/=\s*([\d.,]+)[^=]*\(HATALI\)/)||[])[1];
        const secDeg=(String(s.siklar[secH]||'').match(/\d{1,3}(?:\.\d{3})*(?:,\d+)?/)||[])[0];
        const ayni=hatali&&secDeg&&nrm(hatali)===nrm(secDeg);
        // 06.09 (Cem "geç"): TEK HATA ADIMI — kişisel adım üreticinin genel "Yanlış yol" adımının YERİNE geçer (iki hata adımı arka arkaya gelmez)
        if(!ayni){ const kisi={ kisi:true, formul:'Senin seçimin '+secH+': '+String(s.siklar[secH])+' (HATALI) → doğrusu '+s.dogru+': '+String(s.siklar[s.dogru]), anlatim:'Sen '+secH+' şıkkını seçtin. '+(tzS.ad||'Tuzak')+': '+String(tzS.metin||''), doldur:[] };
          if(/^Yanlış yol/i.test(sonF)){ s.adimlar[s.adimlar.length-1]=kisi; } else { s.adimlar.push(kisi); } }
      }
      Object.keys(tahmin).forEach(k=>delete tahmin[k]);
      if(!s.tablo&&!(s.kayit&&s.kayit.length)){ const ilkC=t=>{ const x=String(t||'').split(/(?<=[.!?])\s+/)[0]; return x.length>200?x.slice(0,198)+'…':x; }; s.tablo={basliklar:['Adım','İçerik'],satirlar:[['Olay',ilkC(s.soru)],['Kural',s.kural||''],['Bu olayda',s.olay||''],['Doğru şık',s.dogru+') '+String(s.siklar[s.dogru]||'')]].filter(r=>r[1])}; s.verilen=[[0,1]]; }
      let h='<table class="tt'+(s.tablo&&s.tablo.basliklar&&s.tablo.basliklar[0]==='Adım'?' teori':'')+'">'+(s.tablo?'<thead><tr>'+s.tablo.basliklar.map(b=>'<th>'+esc(b)+'</th>').join('')+'</tr></thead>':'')+'<tbody>';
      const ver=new Set((s.verilen||[]).map(p=>p[0]+','+p[1]));
      // 06.09: blok başlığı satırı (VERİLENLER / HESAP: değer hücreleri '-') colspan başlık olur; VERİLENLER altındaki satırlar 'vblok'
      let blokAd='';
      if(s.tablo){ s.tablo.satirlar.forEach((st,r)=>{ const basMi=st.length>1&&st.slice(1).every(c=>String(c).trim()==='-'||String(c).trim()==='')&&/^[A-ZÇĞİÖŞÜ\s]+$/.test(String(st[0]).trim());
        if(basMi){ blokAd=String(st[0]).trim(); const n=blokAd==='VERİLENLER'?(s.verilenler||[]).length:0; h+='<tr class="blok" data-blok="'+esc(blokAd)+'"><th colspan="'+st.length+'">'+esc(blokAd)+(n?' <span class="blokSay">('+n+')</span>':'')+(blokAd==='VERİLENLER'?' <span class="blokAcKapa">▾</span>':'')+'</th></tr>'; return; }
        h+='<tr class="'+(r===s.tablo.satirlar.length-1?'sonuc':'')+(blokAd==='VERİLENLER'?' vblok':'')+'">'+st.map((c,ci)=>ci===0?'<td>'+esc(ipucuAyir(c).ad)+'</td>':'<td class="'+(ver.has(r+','+ci)?'ver':'gizliH')+'" data-r="'+r+'" data-c="'+ci+'">'+esc(c)+'</td>').join('')+'</tr>'; }); }
      h+='<tr class="ara kayit"><th>Kayıt</th><th>Borç</th><th>Alacak</th></tr>';
      s.kayit.forEach(r=>{ const kod=(String(r.hesap).match(/^\d{3}/)||[''])[0]; h+='<tr class="kayit" data-kod="'+kod+'"><td class="'+(r.taraf==='A'?'al':'')+'">'+esc(r.hesap)+'</td><td class="tutar">'+(r.taraf==='B'?esc(r.tutar):'')+'</td><td class="tutar">'+(r.taraf==='A'?esc(r.tutar):'')+'</td></tr>'; });
      h+='</tbody></table>'; tabloSar.innerHTML=h;
      // 06.09 (Cem "1 yap"): KÂĞIT ↔ TABLO EŞLEMESİ — öğrencinin kâğıdındaki rakamlar tabloda ✏️ ile işaretlenir; tabloda
      // olmayan rakamları ayrı listelenir. Hangi katmanı atladığı kendi kâğıdından okunur ("8.000 ve 142.000 var, 85.200 yok").
      try{ const es=kagitEsle(); if(es){ es.tablodaHam.forEach(n=>{ tabloSar.querySelectorAll('td[data-r]').forEach(td=>{ if(normK(td.textContent)===n) td.classList.add('kagitVar'); }); });
        const oz=document.createElement('div'); oz.className='kagitOzet'; oz.innerHTML='✏️ Kâğıdında tablodan <b>'+es.tabloda.length+' / '+es.tabloN+'</b> değer var'+(es.eksikTablo.length?' · bulmadığın: <b>'+esc(es.eksikTablo.join(', '))+'</b>':'')+(es.tabloDisi.length?' · tabloda olmayan rakamların: <span class="kagitYanlis">'+esc(es.tabloDisi.join(', '))+'</span>':''); tabloSar.appendChild(oz); } }catch(e){}
      adimBar.innerHTML=s.adimlar.map((a,j)=>'<i data-j="'+j+'" title="Adım '+(j+1)+'"></i>').join('');
      adimBar.querySelectorAll('i').forEach(n=>n.addEventListener('click',()=>adimGit(parseInt(n.dataset.j)-adimNo)));
      const blokBas=tabloSar.querySelector('tr.blok[data-blok="VERİLENLER"]'); if(blokBas){ blokBas.addEventListener('click',()=>{ tabloSar.classList.toggle('acikBlok'); blokBas.querySelector('.blokAcKapa').textContent=tabloSar.classList.contains('acikBlok')?'▾':'▸'; }); }
      gosterilen.clear(); acilan.clear(); adimNo=0; adimGoster(0,0);
    }
    const adimBaslik=a=>{ const f=String(a.formul||''); let b=f.split('=')[0].trim(); b=b.replace(/\(soruda verilen\)/gi,'').trim(); if(b.length>34) b=b.slice(0,32)+'…'; return b; };
    function adimGoster(j,yon){
      let a=s.adimlar[j]; if(!a) return; adimNo=j; ders.dataset.adim=j;
      const son=(j===s.adimlar.length-1);
      const verilenAdimMi=!!a.verilenAdim||/^(Verilen|Soruda ne var|Soru bize)/i.test(String(a.formul||''));   // 06.09: en başta tanımlı (TDZ hatası yaşandı)
      // 06.09 TAHMİN KAPISI: hesap adımından önce öğrenciye sor. Teori sorusunda (kavram tablosu) sayı yok → "kuralı sen söyle" (serbest metin,
      // notlanmaz, üretme etkisi için); sayı sorusunda hedef hücre gerçekten sayıysa "kaç çıkar?"
      const teoriMi=!!(s.tablo&&s.tablo.basliklar&&s.tablo.basliklar[0]==='Adım');
      if(tahminGerek(a,j,son)&&teoriMi&&!/^(Doğru şık|Sonuç)/i.test(adimBaslik(a))){
        const nT=s.adimlar.length, sonrakiAd=adimBaslik(a);
        serit.innerHTML='<div class="adimK tahminK"><div class="say"><span>ADIM '+(j+1)+' / '+nT+'</span><span class="baslik">'+esc(sonrakiAd)+'</span></div>'
          +'<div class="tahminSor"><div class="et">Önce sen söyle</div><p>Bu adımda <b>'+esc(sonrakiAd)+'</b> gelecek. Sence kural ne diyor? Tek cümle yaz, sonra Nöbetçi\'ninkiyle karşılaştır.</p>'
          +'<div class="tahminGir"><textarea class="tahminT" rows="2" placeholder="örn. kanıt, test edilen iddiaya yönelik olmalı"></textarea></div><div class="tahminGir"><button class="btn mavi bTahmin">Karşılaştır</button><button class="btn bTahminAtla">Bilmiyorum, göster</button></div><div class="tahminNot">Yazdığın notlanmaz; kendi cümlenle Nöbetçi\'ninki yan yana gelir.</div></div>'
          +'<div class="yol"><div class="yolCip">'+s.adimlar.map((x,q)=>'<span class="yc '+(q<j?'gecti':(q===j?'simdi':''))+'" title="'+esc(adimBaslik(x))+'">'+(q+1)+'</span>').join('<span class="ycb"></span>')+'<span class="yolAd">'+esc(sonrakiAd)+'</span></div></div></div>';
        const ta=serit.querySelector('.tahminT'); setTimeout(()=>ta.focus(),120);
        serit.querySelector('.bTahmin').addEventListener('click',()=>{ tahmin[j]={teori:true,metin:ta.value.trim()}; adimGoster(j,1); });
        serit.querySelector('.bTahminAtla').addEventListener('click',()=>{ tahmin[j]={atla:true}; adimGoster(j,1); });
        serit.querySelectorAll('.yc').forEach((el,q)=>el.addEventListener('click',()=>adimGit(q-adimNo)));
        adimBar.querySelectorAll('i').forEach(n=>{ const q=parseInt(n.dataset.j); n.classList.toggle('simdi',q===j); n.classList.toggle('gecti',q<j); });
        bOnce.disabled=(j===0); bSonra.disabled=false; bSonra.textContent='İleri ▶';
        return; }
      if(tahminGerek(a,j,son)&&!teoriMi){ const hd=hedefDegeri(a); const sayiMi=hd&&/\d/.test(hd.deger)&&String(hd.deger).trim().length<=24&&normK(hd.deger).replace(/\D/g,'').length>=2; if(sayiMi){
        const nT=s.adimlar.length; const sonrakiAd=adimBaslik(a);
        serit.innerHTML='<div class="adimK tahminK"><div class="say"><span>ADIM '+(j+1)+' / '+nT+'</span><span class="baslik">'+esc(sonrakiAd)+'</span></div>'
          +'<div class="tahminSor"><div class="et">Önce sen dene</div><p>Bu adımda <b>'+esc(hd.ad)+'</b> bulunacak. Sence kaç çıkar? Elindeki verilenlerle hesapla, kâğıdı kullan.</p>'
          +'<div class="tahminGir"><input class="tahminI" inputmode="decimal" placeholder="örn. 142.000"><button class="btn mavi bTahmin">Kontrol et</button><button class="btn bTahminAtla">Bilmiyorum, göster</button></div><div class="tahminNot">Yanlış tahmin puan düşürmez; tahta hemen açılır ve nerede saptığını gösterir.</div></div>'
          +'<div class="yol"><div class="yolCip">'+s.adimlar.map((x,q)=>'<span class="yc '+(q<j?'gecti':(q===j?'simdi':''))+'" title="'+esc(adimBaslik(x))+'">'+(q+1)+'</span>').join('<span class="ycb"></span>')+'<span class="yolAd">'+esc(sonrakiAd)+'</span></div></div></div>';
        const inp=serit.querySelector('.tahminI'); setTimeout(()=>inp.focus(),120);
        const kontrol=()=>{ const g=nrm(inp.value), b=nrm(hd.deger); if(g===''){ inp.focus(); return; } const gv=parseFloat(g), bv=parseFloat(b); const ok=(g===b)||(!isNaN(gv)&&!isNaN(bv)&&Math.abs(gv-bv)<=Math.max(0.5,Math.abs(bv)*0.005)); tahmin[j]={cevap:inp.value.trim(),dogru:ok,hedef:hd.deger}; adimGoster(j,1); };
        serit.querySelector('.bTahmin').addEventListener('click',kontrol); inp.addEventListener('keydown',e=>{ if(e.key==='Enter'){ e.preventDefault(); e.stopPropagation(); kontrol(); } });
        serit.querySelector('.bTahminAtla').addEventListener('click',()=>{ tahmin[j]={atla:true,hedef:hd.deger}; adimGoster(j,1); });
        serit.querySelectorAll('.yc').forEach((el,q)=>el.addEventListener('click',()=>adimGit(q-adimNo)));
        adimBar.querySelectorAll('i').forEach(n=>{ const q=parseInt(n.dataset.j); n.classList.toggle('simdi',q===j); n.classList.toggle('gecti',q<j); });
        bOnce.disabled=(j===0); bSonra.disabled=false; bSonra.textContent='İleri ▶';
        return; } }
      // kart: tek eleman, yonlu animasyon
      // Cem 04.09 "260'ın nereden geldiğini göstermek lazım, farklı renk": formüldeki rakamlar tabloda aranır;
      // bulunduğu hücre MAVİ (nereden geldi), bu adımda bulunan hücre ALTIN; formülde aynı rakamlar aynı renkle boyanır.
      const hedef=new Set((a.doldur||[]).map(p=>p[0]+','+p[1]));
      // 05.09: "-40.000" hedef hücresi ile "40.000" kaynak hücresi aynı sayılıyordu (işaret atılıyordu) → kaynak mavi yanmıyordu
      const norm=t=>{ const s0=String(t||'').replace(/\s*(TL|₺)\s*$/i,'').trim(); return (s0.startsWith('-')?'-':'')+s0.replace(/[^\d,]/g,''); };
      const hucreDeger={}; if(s.tablo){ s.tablo.satirlar.forEach((st,r)=>st.forEach((c,ci)=>{ if(ci>0){ const n=norm(c); if(n&&/\d/.test(n)) (hucreDeger[n]=hucreDeger[n]||[]).push(r+','+ci); } })); }
      // 05.09 Cem "%20 ile 0,20'yi birlikte yazma, sınavda hangisi varsa o": ölçüldü, sınav %20 yazar (169'a 28) →
      // formülde çarpım/bölüm oranı olan "0,20" → "%20" (0,5 → %50, 0,125 → %12,5); "0,60 TL" gibi tutarlar dokunulmaz.
      const oranYuzde=t=>String(t||'').replace(/(?<=[×x*\/]\s*)0,(\d{1,3})(?!\d)(?!\s*(?:TL|₺|kg|adet|saat))/g,(m,d)=>{ if(d.length===1) return '%'+d+'0'; if(d.length===2) return '%'+String(parseInt(d,10)); return '%'+String(parseInt(d.slice(0,2),10))+','+d.slice(2); }).replace(/(?<![\d,])0,(\d{1,3})(?!\d)\s*\(soruda verilen\)\s*(?=[×x*])/g,(m,d)=>{ if(d.length===1) return '%'+d+'0 (soruda verilen) '; if(d.length===2) return '%'+String(parseInt(d,10))+' (soruda verilen) '; return '%'+String(parseInt(d.slice(0,2),10))+','+d.slice(2)+' (soruda verilen) '; });
      a={...a, formul:oranYuzde(a.formul)};
      const fTemiz=String(a.formul||'').replace(/\b\d+\.\s*adımda/gi,' adımda');
      const kaynakH=new Set(); const hedefDeger=new Set([...hedef].map(k=>{ const [r,c]=k.split(',').map(Number); return s.tablo&&s.tablo.satirlar[r]?norm(s.tablo.satirlar[r][c]):''; }).filter(Boolean));
      // yalnız zaten AÇIK (verilen ya da önceki adımda bulunan) hücreler kaynak olabilir; henüz bulunmamış bir hücrenin
      // değeri tesadüfen aynıysa (P birim maliyeti 40 = birim eşdeğer maliyet 40) yanlış yanmasın
      // 05.09 Cem (kademeli dağıtım): 40.000 başlangıç hücresi mavi yanmıyordu — üretici 'verilen' listesine yazmamıştı.
      // Açık hücre = ekranda GÖRÜNEN hücre (gizliH değil): verilen ya da önceki adımda bulunmuş olsun fark etmez.
      const acikMi=key=>{ const [r,c]=key.split(',').map(Number); const td=tabloSar.querySelector('td[data-r="'+r+'"][data-c="'+c+'"]'); if(td) return !td.classList.contains('gizliH'); return (s.verilen||[]).some(p=>p[0]===r&&p[1]===c) || s.adimlar.slice(0,j).some(x=>(x.doldur||[]).some(p=>p[0]===r&&p[1]===c)); };
      [...fTemiz.matchAll(/(?<![\d.,])\d{1,3}(?:\.\d{3})*(?:,\d+)?(?![\d.,]\d)/g)].map(m=>norm(m[0])).forEach(n=>{ if(!n||hedefDeger.has(n)) return; (hucreDeger[n]||[]).forEach(k=>{ if(!hedef.has(k)&&acikMi(k)) kaynakH.add(k); }); });
      [...String(a.formul||'').matchAll(/(\d+)\.\s*adımda/gi)].forEach(m=>{ const q=parseInt(m[1])-1; if(s.adimlar[q]) (s.adimlar[q].doldur||[]).forEach(p=>{ const k=p[0]+','+p[1]; if(!hedef.has(k)) kaynakH.add(k); }); });
      const kaynakDeger=new Set([...kaynakH].map(k=>{ const [r,c]=k.split(',').map(Number); return (s.tablo&&s.tablo.satirlar[r])?norm(s.tablo.satirlar[r][c]):''; }).filter(Boolean));
      let fH=esc(a.formul||'').replace(/(?<![\d.,])\d{1,3}(?:\.\d{3})*(?:,\d+)?(?![\d.,]\d)/g,m=>{ const n=norm(m); if(hedefDeger.has(n)) return '<span class="sSayi">'+m+'</span>'; if(kaynakDeger.has(n)) return '<span class="kSayi">'+m+'</span>'; return m; });
      // Cem 04.09 "soru bitince çıkıyor, kalsın; sürükle değil SEN ÇÖZ": kayıtlıda oyun, kayıtsızda "Sen anlat" açılır
      const oyunVarD=!!(s.oyun&&(s.oyun.tur==='tablo'||(s.oyun.kayit&&s.oyun.kayit.length)));
      const sonBtn=son?(oyunVarD?'<div class="btnrow"><button class="btn ana bDersOyun">⚖️ Sen çöz</button></div>':'<div class="btnrow"><button class="btn ana bDersBitti">🧠 Sen çöz</button></div>'):'';
      // Cem 04.09 "formül kısmı çok küçük, aşağısı boş": formül satır satır ve büyük (";" ayrı satır, "=" soluk); boş alana
      // YOL HARİTASI: tüm adım başlıkları, geçilenler yeşil, buradasın kalın, son adım (hedef) altın + "bu adım niye var" cümlesi
      // Cem 04.09 "formüller birbirine karışıyor, matematik gibi gösterelim": her formül kendi kutusunda; toplama/çıkarma
      // ALT ALTA SÜTUN (sağa hizalı, çizgi, sonuç), bölme KESİR (pay/payda), çarpma satır içi. Rakam renkleri korunur.
      const renkli=t=>{ const n=norm(t); if(!n||!/\d/.test(n)) return esc(t); if(hedefDeger.has(n)) return '<span class="sSayi">'+esc(t)+'</span>'; if(kaynakDeger.has(n)) return '<span class="kSayi">'+esc(t)+'</span>'; return esc(t); };
      const notKisa=n=>String(n).replace(/^soruda verilen$/i,'verilen').replace(/^(\d+)\.\s*adımda bulduk$/i,'adım $1').replace(/^bizim bildiğimiz kural$/i,'kural').replace(/^bizim bilgimiz$/i,'kural');
      const terim=t=>{ const m=String(t).trim().match(/^(.*?)\s*\(([^()]*)\)\s*$/); return m?{deg:m[1].trim(),not:notKisa(m[2].trim())}:{deg:String(t).trim(),not:''}; };
      // parantez DIŞINDAKİ işleçlere göre böl (notlardaki "4. adımda" ve "TL/kg" karışmasın)
      const ustBol=(s0,ops)=>{ const out=[]; let d=0,cur=''; for(let i=0;i<s0.length;i++){ const ch=s0[i]; if(ch==='(') d++; else if(ch===')') d--; if(d===0&&ops.includes(ch)&&/\s/.test(s0[i-1]||'')&&/\s/.test(s0[i+1]||'')){ out.push(cur.trim()); out.push(ch); cur=''; continue; } cur+=ch; } out.push(cur.trim()); return out; };
      const ifade1=seg=>{ // tek ifade: a + b + c | x / y | p × q | düz
        let s0=String(seg).trim(); if(!s0) return ''; let etiket='';
        const em=s0.match(/^([A-ZÇĞİÖŞÜa-zçğıöşü][^:=+\/×()]{0,24}):\s+(.+)$/); if(em){ etiket='<span class="matEt">'+esc(em[1])+'</span>'; s0=em[2]; }
        const kes=ustBol(s0,'/÷'); if(kes.length===3){ const p=terim(kes[0]),q=terim(kes[2]); return etiket+'<span class="kesir"><span class="pay">'+ifade1(p.deg)+(p.not?' <i>'+esc(p.not)+'</i>':'')+'</span><span class="payda">'+ifade1(q.deg)+(q.not?' <i>'+esc(q.not)+'</i>':'')+'</span></span>'; }
        const tok=ustBol(s0,'+-'); if(tok.length>=3){ let h='<span class="sutun">'; for(let i=0;i<tok.length;i+=2){ const t=terim(tok[i]); h+='<span class="op">'+(i===0?'':esc(tok[i-1]))+'</span><span class="deg">'+renkli(t.deg)+'</span><span class="not">'+esc(t.not)+'</span>'; } return etiket+h+'</span>'; }
        const car=ustBol(s0,'×*x'); if(car.length>=3){ return etiket+car.filter((x,i)=>i%2===0).map(c=>{ const t=terim(c); return renkli(t.deg)+(t.not?' <i class="notI">'+esc(t.not)+'</i>':''); }).join(' <span class="op">×</span> '); }
        const t=terim(s0); return etiket+renkli(t.deg)+(t.not?' <i class="notI">'+esc(t.not)+'</i>':''); };
      const ifade=seg=>String(seg).split(/\s*(?:->|→)\s*/).filter(Boolean).map(ifade1).join('<span class="esit">→</span>');
      const bloklar=String(a.formul||'').split(/\s*;\s*/).filter(x=>x.trim()).map(f=>{
        const seg=f.split(/\s=\s/).map(x=>x.trim()).filter(Boolean); if(seg.length<2){ return '<div class="mat"><div class="matSatir">'+ifade(f)+'</div></div>'; }
        // ad: ilk parça sayı/işleç içermiyorsa formülün adıdır; içeriyorsa ("Q: 240.000 / 2.000 = 120") ifadedir
        const adMi=!/\d/.test(seg[0])&&!/[+\/×→]|->/.test(seg[0]); const ad=adMi?seg[0]:''; const orta=adMi?seg.slice(1,-1):seg.slice(0,-1); const son=seg[seg.length-1]; const sonT=terim(son);
        return '<div class="mat">'+(ad?'<div class="matAd">'+esc(ad)+'</div>':'')+'<div class="matSatir">'+(orta.length?orta.map(ifade).join('<span class="esit">=</span>')+'<span class="esit">=</span>':'')+'<span class="matSonuc">'+renkli(sonT.deg)+(sonT.not?' <i class="notI">'+esc(sonT.not)+'</i>':'')+'</span></div></div>'; });
      fH=bloklar.join('');
      // 06.09 Cem (kalıp-6, "anlamadım"): TEORİ adımında formül tahtası yok — kural KART olarak düz cümleyle çizilir; etiketler
      // ("(soruda verilen kural)", "(3. adımda bulduk)") ve ok işaretleri sökülür.
      const teoriAdimMi=!!(s.tablo&&s.tablo.basliklar&&s.tablo.basliklar[0]==='Adım')&&!verilenAdimMi&&!a.giris;
      if(teoriAdimMi){ let kt=String(a.formul||'').replace(/\s*\((soruda verilen[^)]*|\d+\.\s*adımda bulduk|bizim bildiğimiz kural|bizim bilgimiz)\)/gi,'').replace(/\s*(->|→)\s*/g,' → ').replace(/\s{2,}/g,' ').trim(); const kp=kt.split(/\s=\s/); const ktAd=kp.length>1?kp[0]:''; const ktGovde=kp.length>1?kp.slice(1).join(' = '):kt; fH='<div class="kuralKart">'+(ktAd?'<div class="et">'+esc(ktAd)+'</div>':'')+'<p>'+esc(ktGovde)+'</p></div>'; }
      // 05.09 Cem "soru %20 vermiş, onu da belli etmeli": formülde 'soruda verilen' etiketli ama TABLODA OLMAYAN değerler
      // (oranlar, katsayılar) ayrı satırda gösterilir — aday bunların soru metninden geldiğini görür.
      const dısVer=[]; [...String(a.formul||'').matchAll(/([%\d.,]+(?:\s*(?:TL|kg|saat|adet))?)\s*\(soruda verilen\)/gi)].forEach(m=>{ const v=m[1].trim(); const n=norm(v.replace('%','')); if(v&&!hucreDeger[n]&&!dısVer.includes(v)) dısVer.push(v); });
      if(j>0&&dısVer.length&&!teoriAdimMi){ fH+='<div class="verilenSatir">Soruda verilen: '+dısVer.map(v=>'<span class="kSayi">'+esc(v)+'</span>').join(' · ')+'</div>'; }
      // 05.09 Cem "soru bize şunları vermiş yerine direkt soruyu yazsak": ADIM 1 = SORUNUN KENDİ METNİ, verilen rakamlar
      // mavi işaretli (kâğıtta altını çizmenin karşılığı); anlatımda yalnız "Dikkat" cümlesi kalır, tekrar anlatım kalkar.
      let anlatimH=esc(a.anlatim);
      // 06.09 tahmin geri bildirimi: öğrencinin tahmini anlatımın başına
      if(tahmin[j]&&!tahmin[j].atla){ anlatimH=(tahmin[j].teori?('<div class="tahminSonuc '+(tahmin[j].metin?'ok':'hata')+'">'+(tahmin[j].metin?('✍️ Senin cümlen: <b>'+esc(tahmin[j].metin)+'</b>. Nöbetçi\'ninkiyle karşılaştır:'):'Bir cümle yazmadın; Nöbetçi\'ninkini oku, sonra kendi cümlenle tekrar et.')+'</div>'):('<div class="tahminSonuc '+(tahmin[j].dogru?'ok':'hata')+'">'+(tahmin[j].dogru?('✔ Tahminin doğru: <b>'+esc(tahmin[j].cevap)+'</b>. Şimdi neden böyle olduğuna bak.'):('✖ Sen <b>'+esc(tahmin[j].cevap)+'</b> dedin, doğrusu <b>'+esc(tahmin[j].hedef)+'</b>. Nerede saptığını aşağıda gör.'))+'</div>'))+anlatimH; }
      // 06.09 KONU GİRİŞİ kartı (0. adım)
      if(a.giris&&s.konuGiris){ fH='<div class="girisK"><div class="et">Bu konu nedir?</div><p>'+esc(s.konuGiris.nedir)+'</p>'+(s.konuGiris.ornek?'<div class="et">Somut örnek</div><p class="girisOrnek">'+esc(s.konuGiris.ornek)+'</p>':'')+'<div class="et">Sınavda nasıl sorulur?</div><p>'+esc(s.konuGiris.sinavda)+'</p>'+(s.konuGiris.yontemler?'<div class="et">Yöntemler, hangisi ne zaman?</div><p>'+esc(s.konuGiris.yontemler)+'</p>':'')+'</div>'; anlatimH=''; }
      if(verilenAdimMi&&!a.giris){
        const soruH=esc(s.soru).replace(/(?<![\d.,])\d{1,3}(?:\.\d{3})*(?:,\d+)?(?:\s*(?:TL|₺|kg|adet|saat|gün|yıl|%))?(?![\d.,])/g,m=>'<span class="kSayi">'+m+'</span>');
        fH='<div class="soruIsaret"><div class="et">Soru, verilenler işaretli</div>'+soruH+'</div>';
        // 06.09: VERİLENLERİ TANI — her verilen ad · değer · tek cümle anlam (hiç bilmeyene ders burada başlar)
        if(s.verilenler&&s.verilenler.length){ fH+='<ul class="verilenListe">'+s.verilenler.map(v=>'<li><b>'+esc(v.deger)+'</b> · '+esc(v.ad)+(v.anlam?'<i> — '+esc(v.anlam)+'</i>':'')+'</li>').join('')+'</ul>'; }
        const dk=String(a.anlatim||'').match(/((?:Dikkat|Not|Önemli)[^.!?]*[.!?])/i)||String(a.anlatim||'').match(/([^.!?]*(?:anahtar|belirleyici|yöntem)[^.!?]*[.!?])/i);
        anlatimH=esc(dk?dk[1].trim():String(a.anlatim||'').split(/(?<=[.!?])\s+/).slice(-1)[0]);
      }
      // hedef = "Sonuç" adımı; son adım "Yanlış yol / en sık hata" ise ondan önceki sonuç adımıdır
      let hedefIdx=s.adimlar.length-1; for(let q=s.adimlar.length-1;q>=0;q--){ const b=adimBaslik(s.adimlar[q]); if(!/^(yanlış|en sık hata|tuzak|senin seçimin)/i.test(b)){ hedefIdx=q; break; } }
      const sonBas=adimBaslik(s.adimlar[hedefIdx]); const sonrakiBas=(j+1<s.adimlar.length)?adimBaslik(s.adimlar[j+1]):'';
      // Cem 04.09 "yol haritası ekranı kaplıyor": tek satır — numaralı noktalar (geçilen yeşil, buradasın kalın, hedef altın bayrak),
      // yalnız bulunduğun adımın adı yazılı; başlıklar üstüne gelince görünür. Kartın altına yaslanır.
      const yolH='<div class="yol"><div class="yolCip">'+s.adimlar.map((x,q)=>'<span class="yc '+(q<j?'gecti':(q===j?'simdi':(q===hedefIdx?'hedef':'')))+'" title="'+esc(adimBaslik(x))+'">'+(q===hedefIdx&&q!==j?'🏁':(q+1))+'</span>').join('<span class="ycb"></span>')+'<span class="yolAd">'+esc(adimBaslik(a))+'</span></div>'
        +(a.giris?'<div class="neden">Önce konunun haritası: nedir, sınav ne sorar, hangi yöntem ne zaman. Sonra sorunun verilenleri, sonra hesap; hedef <b>'+esc(sonBas)+'</b>.</div>'
          :(verilenAdimMi&&s.verilenler&&s.verilenler.length)?'<div class="neden">Önce elimizdekileri tanıyoruz: <b>'+s.verilenler.length+' verilen</b>. Hesap bloğundaki her satır bunlardan kurulacak; hedef <b>'+esc(sonBas)+'</b>.</div>'
          :son?'<div class="neden">Hedefe ulaştık: <b>'+esc(sonBas)+'</b>. Şimdi aynı yolu sen yürü.</div>'
          :(j>=hedefIdx?'<div class="neden">Hedef bulundu (<b>'+esc(sonBas)+'</b>). '+(a.kisi?'Bu adım <b>senin seçtiğin şıkkın</b> neden yanlış olduğunu gösterir.':'Bu adım, adayların en sık düştüğü yanlış yolu gösterir.')+'</div>'
          :(j+1===hedefIdx?'<div class="neden">Bu adım niye var? Burada bulduğumuz değer doğrudan hedefe götürür: sıradaki adım <b>'+esc(sonBas)+'</b>.</div>'
          :'<div class="neden">Bu adım niye var? Burada bulduğumuz değer sıradaki adımda (<b>'+esc(sonrakiBas)+'</b>) kullanılacak; hedef <b>'+esc(sonBas)+'</b>.</div>')))+'</div>';
      serit.innerHTML='<div class="adimK'+(son?' sonAdim':'')+(yon<0?' geri':'')+'"><div class="say"><span>ADIM '+(j+1)+' / '+s.adimlar.length+'</span><span class="baslik">'+esc(adimBaslik(a))+'</span></div><code class="mat0">'+fH+'</code><p>'+anlatimH+'</p>'+yolH+sonBtn+'</div>';
      // Cem 04.09 "numaralara basarak sayfa değiştirsek": yol haritası yuvarlakları tıklanınca o adıma gider
      serit.querySelectorAll('.yc').forEach((el,q)=>el.addEventListener('click',()=>adimGit(q-adimNo)));
      const bo=serit.querySelector('.bDersOyun'); if(bo){ bo.addEventListener('click',()=>{ ders.classList.remove('acik'); oyunKur(); oyun.classList.add('acik'); }); }
      const bb=serit.querySelector('.bDersBitti'); if(bb){ bb.addEventListener('click',()=>{ ders.classList.remove('acik'); const cA=k.querySelector('.cAnlat'); if(cA){ if(cA.offsetParent===null){ const bd=k.querySelector('.bDaha'); if(bd) bd.click(); } cA.click(); const ta=k.querySelector('.anlatK'); if(ta) setTimeout(()=>ta.focus(),200); } }); }
      // tablo: bu adimin hucreleri acilir ve yanar; onceki adimlarda acilanlar acik kalir
      tabloSar.querySelectorAll('td.vurgu,td.kaynakH').forEach(td=>{ td.classList.remove('vurgu'); td.classList.remove('kaynakH'); }); tabloSar.querySelectorAll('tr.kayit.vurguS').forEach(tr=>tr.classList.remove('vurguS'));
      for(let q=0;q<=j;q++){ (s.adimlar[q].doldur||[]).forEach(p=>acilan.add(p[0]+','+p[1])); }
      kaynakH.forEach(k=>acilan.add(k));   // formülde kullanılan hücre görünür olmalı
      if(son&&s.tablo){ s.tablo.satirlar.forEach((st,r)=>st.forEach((c,ci)=>{ if(ci>0) acilan.add(r+','+ci); })); }
      tabloSar.querySelectorAll('td[data-r]').forEach(td=>{ const key=td.dataset.r+','+td.dataset.c; if(acilan.has(key)&&td.classList.contains('gizliH')){ td.classList.remove('gizliH'); td.classList.add('acildi'); } });
      (a.doldur||[]).forEach(p=>{ const td=tabloSar.querySelector('td[data-r="'+p[0]+'"][data-c="'+p[1]+'"]'); if(td) td.classList.add('vurgu'); });
      // 05.09 Cem "%80 çıktığını o rakamı tabloya doldurduğumuzu göstersek": sonuç formülden tablodaki hücreye UÇAR
      // 05.09 Cem "bir anda çözümler geliyor, sırayla çözüyor gibi yapsa": adımda birden çok hesap varsa formül kutuları
      // SIRAYLA belirir (900 ms arayla), her kutunun sonucu belirince kendi hücresine uçar; hücre uçuş bitene dek boş kalır.
      if(yon>=0&&j>0&&!verilenAdimMi&&!a.giris){
        const mats=[...serit.querySelectorAll('.mat')]; const hedefler=(a.doldur||[]).map(p=>tabloSar.querySelector('td[data-r="'+p[0]+'"][data-c="'+p[1]+'"]')).filter(Boolean);
        const cokKutu=mats.length>1; const adimBu=j;
        hedefler.forEach(td=>td.classList.add('bekliyor'));
        mats.forEach((m,q)=>{ if(q>0&&cokKutu){ m.classList.add('gizliMat'); } });
        hedefler.forEach((td,pi)=>{ const kaynakM=mats[Math.min(pi,Math.max(0,mats.length-1))]; const gecikme=cokKutu?pi*900:pi*120;
          setTimeout(()=>{ if(adimNo!==adimBu||!document.body.contains(td)){ td.classList.remove('bekliyor'); return; }
            if(kaynakM){ kaynakM.classList.remove('gizliMat'); kaynakM.classList.add('geldi'); }
            const kaynakEl=kaynakM?kaynakM.querySelector('.matSonuc'):null; const from=kaynakEl?kaynakEl.getBoundingClientRect():null, to=td.getBoundingClientRect();
            if(!from||!from.width||!to.width){ td.classList.remove('bekliyor'); td.classList.add('indi'); setTimeout(()=>td.classList.remove('indi'),700); return; }
            const u=document.createElement('div'); u.className='ucan'; u.textContent=td.textContent.trim()||kaynakEl.textContent.trim(); document.body.appendChild(u); u.style.left=from.left+'px'; u.style.top=from.top+'px';
            requestAnimationFrame(()=>{ u.style.transform='translate('+(to.left-from.left)+'px,'+(to.top-from.top)+'px) scale(.85)'; u.style.opacity='0.15'; });
            setTimeout(()=>{ u.remove(); td.classList.remove('bekliyor'); td.classList.add('indi'); setTimeout(()=>td.classList.remove('indi'),700); },650); }, gecikme); });
        // hedefi olmayan fazladan kutular da sırayla gelsin
        mats.forEach((m,q)=>{ if(q>=hedefler.length&&m.classList.contains('gizliMat')){ setTimeout(()=>{ if(adimNo===adimBu){ m.classList.remove('gizliMat'); m.classList.add('geldi'); } }, q*900); } });
      }
      kaynakH.forEach(k=>{ const [r,c]=k.split(','); const td=tabloSar.querySelector('td[data-r="'+r+'"][data-c="'+c+'"]'); if(td) td.classList.add('kaynakH'); });
      // 06.09: VERİLENLER bloğu Adım 1'den sonra katlanır; bu adımın formülünde kullanılan verilen satırı açık kalır (mavi), başlık tıklanınca hepsi açılır
      tabloSar.querySelectorAll('tr.vblok').forEach(tr=>{ const td=tr.querySelector('td[data-r]'); const key=td?td.dataset.r+','+td.dataset.c:''; tr.classList.toggle('katli', j>0 && !kaynakH.has(key) && !hedef.has(key)); });
      let lej=tabloSar.querySelector('.lejant'); if(!lej){ lej=document.createElement('div'); lej.className='lejant'; tabloSar.appendChild(lej); }
      lej.innerHTML=kaynakH.size?'<i class="m"></i>nereden geldi <i class="a"></i>bu adımda bulundu':(hedef.size?'<i class="a"></i>bu adımda bulundu':''); lej.style.display=lej.innerHTML?'block':'none';
      // kayit satirlari: adimda anilan hesap kodu (uc hane; "100.000" icindeki 100 sayilmaz)
      const kodlar=new Set([...(String(a.formul)+' '+String(a.anlatim)).matchAll(/(?<![\d.,])(\d{3})(?![\d.,]|\s*(?:TL|%|adet|gün|yıl|ay))/g)].map(m=>m[1]));
      tabloSar.querySelectorAll('tr.kayit[data-kod]').forEach(tr=>{ const k2=tr.dataset.kod; const an=k2&&kodlar.has(k2); if(an||son){ gosterilen.add(k2); } tr.classList.toggle('goster',gosterilen.has(k2)); tr.classList.toggle('vurguS',!!an); });
      const ara=tabloSar.querySelector('tr.ara'); if(ara){ ara.classList.toggle('goster',gosterilen.size>0); }
      adimBar.querySelectorAll('i').forEach(n=>{ const q=parseInt(n.dataset.j); n.classList.toggle('simdi',q===j); n.classList.toggle('gecti',q<j); });
      bOnce.disabled=(j===0); bSonra.disabled=son; bSonra.textContent=son?'Bitti ✓':'İleri ▶';
      const vurgu=tabloSar.querySelector('td.vurgu, tr.vurguS'); if(vurgu) vurgu.scrollIntoView({block:'nearest',behavior:'smooth'});
    }
    const adimGit=d=>{ const cur=s.adimlar[adimNo]; if(d>0&&cur&&tahminGerek(cur,adimNo,adimNo===s.adimlar.length-1)&&serit.querySelector('.tahminK')){ tahmin[adimNo]={atla:true}; adimGoster(adimNo,1); return; }   // 06.09: tahmin ekranında ileri = "göster"
      const j=Math.min(s.adimlar.length-1,Math.max(0,adimNo+d)); if(j===adimNo) return; adimGoster(j,d); };
    bOnce.addEventListener('click',()=>adimGit(-1)); bSonra.addEventListener('click',()=>adimGit(1));
    // fare tekerlegi, klavye oklari, parmakla yatay kaydirma (sola = ileri)
    let tekerKilit=0; serit.addEventListener('wheel',e=>{ e.preventDefault(); const t=Date.now(); if(t-tekerKilit<350) return; tekerKilit=t; adimGit((e.deltaY||e.deltaX)>0?1:-1); },{passive:false});
    let sx=null; serit.addEventListener('pointerdown',e=>{ sx=e.clientX; }); serit.addEventListener('pointerup',e=>{ if(sx===null) return; const dx=e.clientX-sx; sx=null; if(Math.abs(dx)>50) adimGit(dx<0?1:-1); });
    document.addEventListener('keydown',e=>{ if(!ders.classList.contains('acik')) return; if(e.key==='ArrowRight'||e.key===' '){ e.preventDefault(); adimGit(1); } if(e.key==='ArrowLeft'){ e.preventDefault(); adimGit(-1); } if(e.key==='Escape'){ ders.classList.remove('acik'); } });
    bDers.addEventListener('click',()=>{ dersKur(); ders.classList.add('acik'); });
    ders.querySelector('.bDersKapat').addEventListener('click',()=>ders.classList.remove('acik'));
  }
});
// --- son kart
const son=document.createElement('section'); son.className='kart son';
son.innerHTML='<div class="ust"><span>Nöbet bitti</span>'+noktalar(-1)+'<span>&nbsp;</span></div><div class="govde son" style="display:flex;flex-direction:column;justify-content:center"><div id="sonSkor"></div></div>';
akis.appendChild(son);
document.querySelectorAll('.skorCip,.kutuCip').forEach(b=>b.addEventListener('click',kutuEkraniAc)); skorCiz();
if(!durum.t0) durum.t0={}; durum.t0[0]=Date.now();   // ilk kart: süre sayfa açılınca başlar
akis.addEventListener('scroll',()=>{ const i=Math.round(akis.scrollTop/akis.clientHeight); document.querySelectorAll('.noktalar i').forEach(n=>n.classList.toggle('simdi',n.dataset.j==String(i)||(i>=SORULAR.length&&n.dataset.j==='son')));
  if(i<SORULAR.length&&durum.cevap[i]===undefined&&!durum.t0[i]) durum.t0[i]=Date.now();   // 06.09: karta gelince süre başlar
  if(i>=SORULAR.length){ const c=Object.keys(durum.cevap).length; document.getElementById('sonSkor').innerHTML='<div class="buyuk">'+durum.dogru+' / '+SORULAR.length+'</div><div class="seri">🔥 Denk serisi: '+durum.seri+'</div><p style="color:var(--dim);font-size:.9em">'+(SORULAR.length-durum.dogru)+' yanlış kutuya girdi, 2 gün sonra yeniden gelir.</p><div class="skorBuyuk" style="font-size:2.2em">🎯 Hazırlık %'+skorHesapla().toplam+'</div><button class="btn mavi" onclick="kutuEkraniAc()">📥 Yanlış kutusu ('+KUTU.kutu.length+')</button><div class="paylas">Tetikte · Kaydır-Çöz<br><b>'+durum.dogru+'/'+SORULAR.length+' doğru · seri '+durum.seri+'</b><br><span style="color:var(--dim)">Yanlışını böyle öğrenirsin.</span></div><button class="btn ana" onclick="akis.scrollTo({top:0,behavior:\'smooth\'})">Baştan ▲</button>'; } });
document.addEventListener('keydown',e=>{ if(e.key==='ArrowDown'||e.key==='PageDown'){ akis.scrollBy({top:akis.clientHeight,behavior:'smooth'}); } if(e.key==='ArrowUp'||e.key==='PageUp'){ akis.scrollBy({top:-akis.clientHeight,behavior:'smooth'}); } });
</script></body></html>
'@
$html=$html.Replace('__JSON__',$json)
$out=Join-Path $kok "sql-yerel\$Cikti"
[IO.File]::WriteAllText($out,$html,[Text.UTF8Encoding]::new($false))
$y="C:\TETIKTE-YEDEK\kaydir-coz-$(Get-Date -Format yyyyMMdd)"; New-Item -ItemType Directory -Force $y | Out-Null; Copy-Item $out $y -Force
AmbarKaydet
"yazildi: $out ($([math]::Round((Get-Item $out).Length/1024)) KB) · soru $($sorular.Count)"
