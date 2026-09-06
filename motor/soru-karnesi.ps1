# ============================================================================
#  SORU KARNESİ + İSTİSNA KUYRUĞU (06.09.2026 — Cem: "basılan tüm soruları ben kontrol edemiyorum, yardıma ihtiyacım var" → GM-1 "bu beşi geç")
#
#  NE YAPAR: üretici önbelleklerindeki (veri/fabrika/kalip-parti-<etiket>.json) her soruya 8 hücreli karne çıkarır:
#    1 hakem (bağımsız hakem kararı)        5 türkçe (ASCII kalmış Türkçe kelime)
#    2 sim (öğrenci simülasyonu öğretti mi)  6 şık dengesi (yön çifti · doğru en uzun · sayı sırası)
#    3 aritmetik (formül zincirleri tutuyor mu) 7 pencere (K10: son N dönemde çıktı mı)
#    4 hesap kodu–ad (Tekdüzen Hesap Planı)  8 kaynak (ambar kaynağı var mı, ne zaman yüklendi)
#  Hücre: YESIL / KIRMIZI / OLCULMEDI. Soru durumu: biri kırmızı → KIRMIZI; kırmızı yok ama ölçülmemiş var → SARI; hepsi yeşil → YESIL.
#  KUYRUK (Cem'in okuyacağı): KIRMIZI + SARI + yeşillerden rastgele %N örneklem (id'den türeyen sabit tohum, her koşuda aynı örneklem).
#  ÇIKTI: veri/fabrika/soru-karnesi.json (RaporYaz) + sql-yerel/KARNE.html (kuyruk sayfası; Okey/Yanlış tıkı soru_bildirim'e oturum='karne-cem').
#  KURAL: hücre ölçülemiyorsa "ölçülmedi" yazılır, yeşil sayılmaz (olcemedigine-kusur-deme'nin tersi de geçerli: ölçmediğine "tamam" deme).
# ============================================================================
param(
  [string]$Etiketler='sgs-fmuh-parti1,sgs-maliyet-parti1,sgs-denetim-parti2,sgs-mta-parti2',
  [int]$OrneklemYuzde=10,
  [string]$Cikti='KARNE.html',
  [switch]$AmbarYok      # ağ yokken: hesap kodu ve kaynak hücreleri "ölçülmedi"
)
$ErrorActionPreference='Stop'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$here=Split-Path -Parent $MyInvocation.MyCommand.Path; $kok=Split-Path -Parent $here
. (Join-Path $kok 'arac\rapor-yaz.ps1')
$SB_URL='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar'
# yalnız OKUMA yapılır; herkese açık (publishable) anahtar yeter. 06.09 ölçüldü: ortamdaki SUPABASE_SERVICE_KEY 401 verdi, anon 200.
$SB_KEY='sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg'
# PS harf tuzağı (06.09 bu betikte yaşandı): başlık $H iken foreach($h in 'A'..'E') aynı değişkeni EZDİ → her ambar sorgusu 401. Kısa ad yasak.
$BASLIK=@{ apikey=$SB_KEY; Authorization="Bearer $SB_KEY"; 'User-Agent'='mevzuat-radar-robot/1.0' }

function Katla([string]$s){ $s="$s".ToLowerInvariant() -replace 'ı','i' -replace 'İ','i' -replace 'ş','s' -replace 'ğ','g' -replace 'ç','c' -replace 'ö','o' -replace 'ü','u' -replace 'â','a' -replace 'î','i' -replace 'û','u'; ($s -replace '[^a-z0-9%.,/ ]+',' ' -replace '\s+',' ').Trim() }
function SayiCoz([string]$s){ $t=$s -replace '\.','' -replace ',','.'; $v=0.0; if([double]::TryParse($t,[Globalization.NumberStyles]::Any,[Globalization.CultureInfo]::InvariantCulture,[ref]$v)){ return $v }; return $null }
$YUZDE_ONDALIK=[System.Text.RegularExpressions.MatchEvaluator]{ param($m) $v=SayiCoz $m.Groups[1].Value; if($null -eq $v){ return $m.Value }; return ' '+(([string]($v/100)) -replace '\.',',')+' ' }
function ZincirHesapla([string]$sol){
  $toks=@([regex]::Matches($sol,'([\d\.,]+)|([x*/+\-])') | ForEach-Object { $_.Value }); if(-not $toks.Count){ return $null }
  $terimler=New-Object System.Collections.Generic.List[double]; $cur=$null; $bekleyen='+'; $op=$null
  foreach($tk in $toks){
    if($tk -match '^[x*/+\-]$'){ $op=$tk; continue }
    $v=SayiCoz $tk; if($null -eq $v){ return $null }
    if($null -eq $cur){ $cur=$v; continue }
    if($null -eq $op){ return $null }
    switch($op){ 'x'{ $cur=$cur*$v } '*'{ $cur=$cur*$v } '/'{ if($v -eq 0){ return $null }; $cur=$cur/$v } '+'{ $terimler.Add($(if($bekleyen -eq '-'){ -$cur } else { $cur })); $bekleyen='+'; $cur=$v } '-'{ $terimler.Add($(if($bekleyen -eq '-'){ -$cur } else { $cur })); $bekleyen='-'; $cur=$v } default{ return $null } }
    $op=$null
  }
  if($null -ne $cur){ $terimler.Add($(if($bekleyen -eq '-'){ -$cur } else { $cur })) }
  $t=0.0; foreach($x in $terimler){ $t+=$x }; return $t
}
# aritmetik zincir değerlendirici — motor/kalip-parti-uret.ps1 AritmetikKusur ile aynı kural (birim kelimeleri atılır, hesap kodu zinciri atlanır)
function AritmetikKusur($adimlar){
  $out=New-Object System.Collections.Generic.List[string]
  foreach($a in @($adimlar)){ if(-not $a){ continue }
    foreach($sat in ("$($a.formul)" -split "`n")){
      if($sat -match '\d{1,2}\.\d{1,2}\.\d{4}'){ continue }   # tarih farkı hesap zinciri değil
      $tmz=$sat -replace '×','x' -replace 'X','x' -replace '\([^)]*\)',' '
      $tmz=[regex]::Replace($tmz,'%\s*([\d\.,]+)',$YUZDE_ONDALIK); $tmz=[regex]::Replace($tmz,'([\d\.,]+)\s*%',$YUZDE_ONDALIK)
      $tmz=$tmz -replace '(?i)\b(TL|₺|USD|EUR|kg|ton|adet|ay|yil|yıl|gun|gün|saat|birim|kisi|kişi)\b',' '
      foreach($m in [regex]::Matches($tmz,'((?:[\d\.,]+\s*[x*/+\-]\s*)+[\d\.,]+)\s*=\s*([\d\.,]+)')){
        $sol=$m.Groups[1].Value; $c1=SayiCoz $m.Groups[2].Value; if($null -eq $c1){ continue }
        $terimler=@([regex]::Matches($sol,'[\d\.,]+') | ForEach-Object { $_.Value })
        if(($terimler.Count -ge 2) -and (-not @($terimler | Where-Object { $_ -notmatch '^[1-7]\d{2}$' }).Count) -and ("$($m.Groups[2].Value)" -match '^[1-7]\d{2}$')){ continue }
        $hes=ZincirHesapla $sol; if($null -eq $hes){ continue }
        $tol=[Math]::Max(0.51,[Math]::Abs($c1)*0.001)
        $uyum=([Math]::Abs($hes-$c1) -le $tol) -or ([Math]::Abs($hes*100-$c1) -le $tol) -or ([Math]::Abs($hes/100-$c1) -le $tol)
        if(-not $uyum){ $out.Add("'$($m.Value.Trim())' hesap=$([math]::Round($hes,2))") }
      } } }
  return @($out)
}
# Tekdüzen Hesap Planı sözlüğü (ambar, kaynak_ad "THP 120 - Alıcılar")
$script:THP=$null
function ThpSozluk{
  if($script:THP){ return $script:THP }; $d=@{}
  if(-not $AmbarYok){ try{ $u=$SB_URL+'?select=kaynak_ad&kaynak_ad=ilike.'+[uri]::EscapeDataString('THP %')+'&limit=1000'
      (ConvertFrom-Json (Invoke-WebRequest -Uri $u -Headers $BASLIK -UseBasicParsing -TimeoutSec 120).Content) | ForEach-Object { $m=[regex]::Match("$($_.kaynak_ad)",'^THP\s+(\d{3})\s*-\s*(.+)$'); if($m.Success){ $d[$m.Groups[1].Value]=$m.Groups[2].Value.Trim() } } }catch{ Write-Host "THP sözlüğü çekilemedi: $($_.Exception.Message)" -ForegroundColor DarkYellow } }
  $script:THP=$d; return $d
}
function HesapKodKusur($c){
  $d=ThpSozluk; if(-not $d.Count){ return $null }
  $metinler=New-Object System.Collections.Generic.List[string]; foreach($h in 'A','B','C','D','E'){ $metinler.Add("$($c.siklar.$h)") }
  if($c.sema){ $kyt=@(); if($c.sema.PSObject.Properties['kayitlar']){ $kyt=@($c.sema.kayitlar) } elseif($c.sema.PSObject.Properties['ogeler']){ $kyt=@($c.sema) }
    foreach($ky in $kyt){ if($ky -and $ky.ogeler){ foreach($og in @($ky.ogeler.borc)+@($ky.ogeler.alacak)){ if($og){ $metinler.Add("$($og.hesap)") } } } } }
  $kusur=New-Object System.Collections.Generic.List[string]; $gor=@{}
  foreach($t in $metinler){ foreach($m in [regex]::Matches($t,'(?<![\d.,])(?<!(?:BDS|TMS|TFRS|GDS|KKS|UMS|UFRS|IFRS|ISA|ISQM|KGK|Sıra No|No|madde|m\.|md\.|p\.)\s{0,2})([1-7]\d{2})(?![\d.,])\s+([^\d]{3,90})')){ $kod=$m.Groups[1].Value; if(-not $d.ContainsKey($kod)){ continue }
      $yazHam=$m.Groups[2].Value.Trim(); $yaz=Katla $yazHam; $res=Katla $d[$kod]; $resK=@(($res -split '\s+') | Where-Object { $_.Length -ge 3 -and $_ -notmatch '^(ve|veya|ile|hesabi|hs)$' }); if(-not $resK.Count){ continue }
      $eksik=@($resK | Where-Object { $w=$_; $on=$(if($w.Length -gt 5){ $w.Substring(0,5) } else { $w }); $yaz -notmatch ('\b'+[regex]::Escape($on)) })
      $an="$kod|$yaz"; if($gor[$an]){ continue }; $gor[$an]=1
      if($eksik.Count -gt [Math]::Floor($resK.Count/2)){ $kusur.Add("$kod '$($yazHam.Substring(0,[Math]::Min(36,$yazHam.Length)))' ≠ '$($d[$kod])'") } } }
  return @($kusur | Select-Object -Unique)
}
# Türkçe harf: ASCII kalmış, her zaman yanlış olan kelimeler (kâr/kar, oran gibi çift anlamlılar listede YOK)
$ASCII_TR='(?i)\b(icin|degil|gunu|sirket|isletme|isletmenin|donem|donemin|uretim|butun|dogru|yanlis|ucret|ucreti|olcum|hesabi|hesabina|karsilik|karsiligi|musteri|satis|satislar|alis|odeme|yukumluluk|ozkaynak|donen|buyuk|kucuk|yil|yuzde|deger|degeri|sayi|isci|iscilik|surec|sure|gecerli|gecmis|dagitim|dagitimi|olusan|olusur|bagli|bagimsiz|yonetim|denetci|dusuk|yuksek|artis|azalis|gerceklesen|gercek|agirlikli|musavir|mudur|kayit|kaydi|birikmis|odenmis|odenecek|verilmis|alinmis|bagis|tasit|tasitlar|demirbas|demirbaslar|ozel|dogrudan|gunluk|gunler|aylik|yillik|uyesi|uyeler|tuketim|urun|urunler|yari mamul|uretilen)\b'   # 06.09 ölçüm: "ilk madde", "hammadde", "yasal", "malzemesi" doğru Türkçe, listeden çıktı
function TurkceKusur($c){
  $metin=("$($c.soru) "+(@('A','B','C','D','E') | ForEach-Object { "$($c.siklar.$_)" }) -join ' ')+' '+((@($c.adimlar) | ForEach-Object { "$($_.formul) $($_.anlatim)" }) -join ' ')
  $ms=@([regex]::Matches($metin,$ASCII_TR) | ForEach-Object { $_.Value.ToLowerInvariant() } | Select-Object -Unique); return @($ms)
}
# şık dengesi: yön çiftleri (üreticideki SikDengesi kuralı) + cümle şıklarında doğru en uzun ve medyanın 1,3 katı + saf sayı şıkları artan sıra
function SikKusur($c){
  if(-not $c.siklar -or -not $c.dogru){ return @('şık/doğru yok') }
  $harf=@('A','B','C','D','E'); $sik=@($harf | ForEach-Object { "$($c.siklar.$_)".Trim() }); $d="$($c.dogru)".Trim().ToUpperInvariant(); $out=@()
  $yonlu=@($sik | Where-Object { $_ -match '(?i)\b(olumlu|olumsuz|lehte|aleyhte|eksik yükleme|fazla yükleme|eksik|fazla)\b' })
  if($yonlu.Count -ge 4){ $cift=@{}; foreach($s in $sik){ $t=[regex]::Match($s,'\d{1,3}(?:\.\d{3})+(?:,\d+)?|\d+(?:,\d+)?').Value; if(-not $t){ continue }; $y=if($s -match '(?i)\b(olumlu|lehte|fazla)\b'){ '+' } elseif($s -match '(?i)\b(olumsuz|aleyhte|eksik)\b'){ '-' } else { '?' }; if(-not $cift.ContainsKey($t)){ $cift[$t]=@{} }; $cift[$t][$y]=1 }
    $iki=@($cift.Keys | Where-Object { $cift[$_].Count -ge 2 }); if($cift.Count -ge 2 -and $iki.Count -lt 2){ $out+="yön şıklarında $($cift.Count) tutar, iki yönle görünen $($iki.Count)" }
    if($sik -match '(?i)\b(lehte|aleyhte)\b'){ $out+="'lehte/aleyhte' (sınav dili olumlu/olumsuz)" } }
  $trS=[cultureinfo]::GetCultureInfo('tr-TR'); $deg=@{}; $safSayi=$true
  foreach($h in $harf){ $m=[regex]::Match("$($c.siklar.$h)".Trim(),'^%?\s*(-?\d{1,3}(?:\.\d{3})+(?:,\d+)?|-?\d+(?:,\d+)?)\s*(₺|TL|%|adet|kg|saat|gün|yıl|ton|birim|TL/kg|TL/adet|TL/saat|TL/ton)?\s*$'); if(-not $m.Success){ $safSayi=$false; break }; try{ $deg[$h]=[double]::Parse($m.Groups[1].Value,$trS) }catch{ $safSayi=$false; break } }
  if($safSayi -and $yonlu.Count -lt 4){ if(@($deg.Values | Select-Object -Unique).Count -lt 5){ $out+='sayı şıklarında tekrar eden tutar' }; $sira=@($harf | Sort-Object { $deg[$_] }); if(($sira -join '') -ne ($harf -join '')){ $out+='sayı şıkları küçükten büyüğe değil' } }
  elseif(-not $safSayi){ $uz=@($harf | ForEach-Object { "$($c.siklar.$_)".Length } | Sort-Object); $med=$uz[2]; $dU="$($c.siklar.$d)".Length; if($med -gt 0 -and $dU -eq $uz[4] -and $dU -gt 1.3*$med -and $uz[4] -ne $uz[3]){ $out+="doğru şık en uzun ($dU kr, medyan $med)" } }
  return @($out)
}
# kaynak hücresi: ambarda kaynak var mı, en son ne zaman yüklendi (belge_tarihi boşsa yüklenme tarihi)
function KaynakBilgi($c){
  $adlar=@($c.kaynak_adlar | Where-Object { $_ }); if(-not $adlar.Count){ return @{ durum='KIRMIZI'; not='kaynak adı yok' } }
  if($AmbarYok){ return @{ durum='OLCULMEDI'; not="$($adlar.Count) kaynak adı var, tarih ölçülmedi (ağ yok)" } }
  try{ $ilk=@($adlar | Select-Object -First 3); $u=$SB_URL+'?select=kaynak_ad,belge_tarihi,yuklenme&kaynak_ad=in.('+(($ilk | ForEach-Object { '"'+($_ -replace '"','') +'"' }) -join ',')+')&limit=5'
    $rows=New-Object System.Collections.Generic.List[object]; (ConvertFrom-Json (Invoke-WebRequest -Uri ([uri]::EscapeUriString($u)) -Headers $BASLIK -UseBasicParsing -TimeoutSec 60).Content) | ForEach-Object { $rows.Add($_) }
    if(-not $rows.Count){ return @{ durum='KIRMIZI'; not="kaynak adı ambarda bulunamadı: $($ilk[0])" } }
    $tar=@($rows | ForEach-Object { if("$($_.belge_tarihi)"){ "$($_.belge_tarihi)" } else { "$($_.yuklenme)".Substring(0,10) } } | Sort-Object -Descending)
    return @{ durum='YESIL'; not="$($rows.Count) kaynak ambarda · en yeni $($tar[0])" }
  }catch{ return @{ durum='OLCULMEDI'; not="ambar sorgusu düştü: $($_.Exception.Message)" } }
}
function Hucre([string]$durum,[string]$not){ return [ordered]@{ durum=$durum; not=$not } }
# K10 pencere (06.09): üretici alanı yoksa karne kendisi ölçer — veri/<sinav>-analiz.json son N dönem etiketleri, kök-önekiyle eşleşme
# (üreticideki KokOnek ile aynı kural; "evre"→"safha", "gug"→"genel"). Sonuç: kaç dönemde geçti; analiz dosyası yoksa $null (ölçülmedi).
$PENCERE=7
$script:PENCERE_ETIKET=@{}
function KokOnek([string]$s){ $t=(Katla $s) -replace '[^a-z0-9 ]',' '; $es=@{ 'evre'='safha'; 'gug'='genel'; 'dimm'='ilk' }
  @(($t -split '\s+') | Where-Object { $_.Length -ge 3 -and $_ -notmatch '^(ve|ile|veya|icin|bir|olan|sistemi|yontemi|sistem|yontem|hesaplama|hesabi|kaydi|kayit|analizi|analiz|orani|oran|tablosu|tablo|muhasebesi|muhasebe)$' } | ForEach-Object { $w=$_; if($es.ContainsKey($w)){ $w=$es[$w] }; if($w.Length -gt 5){ $w.Substring(0,5) } else { $w } } | Select-Object -Unique) }
function PencereSay([string]$sinav,[string]$konu){
  if(-not $script:PENCERE_ETIKET.ContainsKey($sinav)){
    $anYol=Join-Path $kok ("veri\"+$sinav.ToLowerInvariant()+"-analiz.json"); $etiketDonem=$null
    if(Test-Path $anYol){ try{ $anJ=Get-Content $anYol -Raw -Encoding UTF8 | ConvertFrom-Json; $dList=New-Object System.Collections.Generic.List[object]; $anJ.donemler | ForEach-Object { $dList.Add($_) }
        $sonD=@($dList | Sort-Object { [int]("$($_.donem)" -replace '/','') } -Descending | Select-Object -First $PENCERE); $etiketDonem=@{}
        foreach($dn in $sonD){ foreach($p in @($dn.konuSayim.PSObject.Properties)){ $k=(KokOnek ($p.Name -replace '^[^|]*\|','')) -join ' '; if(-not $etiketDonem.ContainsKey($k)){ $etiketDonem[$k]=@{} }; $etiketDonem[$k]["$($dn.donem)"]=1 } } }catch{ $etiketDonem=$null } }
    $script:PENCERE_ETIKET[$sinav]=$etiketDonem
  }
  $ed=$script:PENCERE_ETIKET[$sinav]; if($null -eq $ed){ return $null }
  $kokler=@(KokOnek $konu); if(-not $kokler.Count){ return $null }; $dset=@{}; $gerek=[Math]::Min(2,$kokler.Count)
  foreach($et in $ed.Keys){ $etK=$et -split ' '; $ortak=@($kokler | Where-Object { $etK -contains $_ }).Count; if($ortak -ge $gerek){ foreach($d in $ed[$et].Keys){ $dset[$d]=1 } } }
  return $dset.Count
}

$sorular=New-Object System.Collections.Generic.List[object]
foreach($et in ($Etiketler -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })){
  $yol=Join-Path $kok "veri\fabrika\kalip-parti-$et.json"
  if(-not (Test-Path $yol)){ Write-Host "YOK: $yol" -ForegroundColor Yellow; continue }
  $j=Get-Content $yol -Raw -Encoding UTF8 | ConvertFrom-Json
  foreach($id in @($j.PSObject.Properties.Name | Sort-Object)){
    $c=$j.$id; if(-not $c -or -not $c.soru){ continue }
    $h=[ordered]@{}
    # 1 hakem
    if($c.hakem -and $c.hakem.karar){ $h.hakem=Hucre $(if("$($c.hakem.karar)" -eq 'EVET'){'YESIL'}else{'KIRMIZI'}) "$($c.hakem.karar)$(if($c.hakem.gerekce -and "$($c.hakem.karar)" -ne 'EVET'){ ': '+"$($c.hakem.gerekce)".Substring(0,[Math]::Min(160,"$($c.hakem.gerekce)".Length)) })" } else { $h.hakem=Hucre 'OLCULMEDI' 'hakem koşmadı' }
    # 2 sim
    $sim=$null; foreach($sa in 'simulasyon_sonnet','simulasyon'){ if(-not $sim -and $c.PSObject.Properties[$sa] -and $c.$sa -and $c.$sa.PSObject.Properties['dogru_mu']){ $sim=$c.$sa } }
    if($sim){ $h.sim=Hucre $(if([bool]$sim.dogru_mu){'YESIL'}else{'KIRMIZI'}) "$(if($sim.PSObject.Properties['tur']){"$($sim.tur) · "})cevap $($sim.cevap) / hedef $($sim.hedef) · $($sim.model)$(if(-not [bool]$sim.dogru_mu -and "$($sim.eksik)"){ ' · '+"$($sim.eksik)".Substring(0,[Math]::Min(140,"$($sim.eksik)".Length)) })" }
    else { $h.sim=Hucre 'OLCULMEDI' $(if($c.PSObject.Properties['ikiz'] -and $c.ikiz){ 'ikiz var, simülasyon koşmadı' } else { 'ikiz yok (teori: Ö24 teori ikizi gerek)' }) }
    # 3 aritmetik
    if($c.PSObject.Properties['adimlar'] -and $c.adimlar){ $ar=$(if($c.PSObject.Properties['aritmetik']){ @($c.aritmetik) } else { @(AritmetikKusur $c.adimlar) }); $h.aritmetik=Hucre $(if($ar.Count){'KIRMIZI'}else{'YESIL'}) $(if($ar.Count){ ($ar | Select-Object -First 3) -join ' · ' } else { "$(@($c.adimlar).Count) adım, zincirler tutuyor" }) } else { $h.aritmetik=Hucre 'OLCULMEDI' 'adım yok' }
    # 4 hesap kodu–ad
    if($c.PSObject.Properties['hesap_kod']){ $hk=@($c.hesap_kod); $h.hesapKod=Hucre $(if($hk.Count){'KIRMIZI'}else{'YESIL'}) $(if($hk.Count){ $hk -join ' · ' } else { 'kodlar resmî adla eşleşti (üretici kapısı)' }) }
    else { if(-not (ThpSozluk).Count){ $h.hesapKod=Hucre 'OLCULMEDI' 'THP sözlüğü yok' } else { $hk=@(HesapKodKusur $c | Where-Object { $_ }); $h.hesapKod=Hucre $(if($hk.Count){'KIRMIZI'}else{'YESIL'}) $(if($hk.Count){ $hk -join ' · ' } else { 'kodlar resmî adla eşleşti' }) } }   # boş dizi PS'te $null döner; sözlük varlığı ayrı sınanır
    # 5 türkçe
    $tk=TurkceKusur $c; $h.turkce=Hucre $(if($tk.Count){'KIRMIZI'}else{'YESIL'}) $(if($tk.Count){ 'ASCII kalmış: '+($tk -join ', ') } else { 'Türkçe harfler tam' })
    # 6 şık dengesi
    $sk=SikKusur $c; $h.sik=Hucre $(if($sk.Count){'KIRMIZI'}else{'YESIL'}) $(if($sk.Count){ $sk -join ' · ' } else { 'şıklar dengeli' })
    # 7 pencere (K10)
    if($c.PSObject.Properties['son_donem']){ $sd=[int]$c.son_donem; $h.pencere=Hucre $(if($sd -ge 1){'YESIL'}else{'KIRMIZI'}) "son $($c.pencere) dönemde $sd kez$(if($c.PSObject.Properties['capa_kaynak'] -and $c.capa_kaynak){ ' · çapa '+$c.capa_kaynak })" }
    else { $sd=PencereSay ($et -replace '-.*$','') "$($c.konu)"; if($null -eq $sd){ $h.pencere=Hucre 'OLCULMEDI' "pencere ölçülmedi (toplam $($c.donem) dönem, 2015'ten)" } else { $h.pencere=Hucre $(if($sd -ge 1){'YESIL'}else{'KIRMIZI'}) "son $PENCERE dönemde $sd kez (karne ölçtü; toplam $($c.donem))" } }
    # 8 kaynak
    $kb=KaynakBilgi $c; $h.kaynak=Hucre $kb.durum $kb.not
    $durumlar=@($h.Values | ForEach-Object { $_.durum })
    $durum=$(if($durumlar -contains 'KIRMIZI'){ 'KIRMIZI' } elseif($durumlar -contains 'OLCULMEDI'){ 'SARI' } else { 'YESIL' })
    # örneklem: id'den sabit tohum (her koşuda aynı yeşiller seçilir)
    $tohum=[Math]::Abs([BitConverter]::ToInt32([Security.Cryptography.MD5]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes("$et/$id")),0)) % 100
    $kuyruk=($durum -ne 'YESIL') -or ($tohum -lt $OrneklemYuzde)
    $sorular.Add([ordered]@{ id="$et/$id"; etiket=$et; kp=$id; ders=$(if($c.PSObject.Properties['ders']){ "$($c.ders)" } else { '' }); konu="$($c.konu)"; durum=$durum; kuyruk=$kuyruk; ornek=($durum -eq 'YESIL' -and $kuyruk); hucre=$h; soru="$($c.soru)"; dogru="$($c.dogru)"; siklar=$c.siklar })
    Write-Host ("  {0,-8} {1,-28} {2,-7} {3}" -f $durum,"$et/$id","$(if($kuyruk){'KUYRUK'}else{''})",(($h.Keys | Where-Object { $h[$_].durum -ne 'YESIL' } | ForEach-Object { "$_=$($h[$_].durum)" }) -join ' '))
  }
}
$ozet=[ordered]@{ soru=$sorular.Count; kirmizi=@($sorular | Where-Object { $_.durum -eq 'KIRMIZI' }).Count; sari=@($sorular | Where-Object { $_.durum -eq 'SARI' }).Count; yesil=@($sorular | Where-Object { $_.durum -eq 'YESIL' }).Count; kuyruk=@($sorular | Where-Object { $_.kuyruk }).Count; ornek=@($sorular | Where-Object { $_.ornek }).Count }
$hucreOzet=[ordered]@{}; foreach($ad in 'hakem','sim','aritmetik','hesapKod','turkce','sik','pencere','kaynak'){ $hucreOzet[$ad]=[ordered]@{ yesil=@($sorular | Where-Object { $_.hucre[$ad].durum -eq 'YESIL' }).Count; kirmizi=@($sorular | Where-Object { $_.hucre[$ad].durum -eq 'KIRMIZI' }).Count; olculmedi=@($sorular | Where-Object { $_.hucre[$ad].durum -eq 'OLCULMEDI' }).Count } }
# PS harf tuzağı: rapor nesnesi $Cikti parametresiyle çakışmasın diye $raporNesne (ilk koşuda sayfa yolu OrderedDictionary oldu)
$raporNesne=[ordered]@{ olcum=(Get-Date -Format 'yyyy-MM-dd HH:mm'); etiketler=$Etiketler; orneklem_yuzde=$OrneklemYuzde; ozet=$ozet; hucre_ozet=$hucreOzet; sorular=@($sorular | ForEach-Object { $s=$_; [ordered]@{ id=$s.id; ders=$s.ders; konu=$s.konu; durum=$s.durum; kuyruk=$s.kuyruk; ornek=$s.ornek; hucre=$s.hucre } }) }
[void](RaporYaz -Hedef (Join-Path $kok 'veri\fabrika\soru-karnesi.json') -Nesne $raporNesne)
"KARNE: $($ozet.soru) soru · kırmızı $($ozet.kirmizi) · sarı $($ozet.sari) · yeşil $($ozet.yesil) · Cem'e kuyruk $($ozet.kuyruk) (örneklem $($ozet.ornek))"

# --- KUYRUK SAYFASI ---------------------------------------------------------------------------------------------------
function E([string]$s){ [System.Net.WebUtility]::HtmlEncode("$s") }
$sb=New-Object System.Text.StringBuilder
[void]$sb.Append(@'
<!doctype html><html lang="tr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Soru Karnesi · Kuyruk</title>
<style>
:root{--bg:#141518;--kart:#1e2026;--cizgi:#2e3138;--yazi:#e9e9ec;--dim:#9aa1ad;--mavi:#78b4ff;--yesil:#8fc98f;--kirmizi:#e07b7b;--altin:#e0a458}
body{margin:0;background:var(--bg);color:var(--yazi);font:15px/1.5 system-ui,Segoe UI,Roboto,sans-serif;padding:16px}
h1{font-size:1.3em;margin:0 0 4px}.ozet{color:var(--dim);margin-bottom:14px}.ozet b{color:var(--yazi)}
.sekme{display:flex;gap:6px;flex-wrap:wrap;margin-bottom:12px}.sekme button{background:var(--kart);color:var(--yazi);border:1px solid var(--cizgi);border-radius:14px;padding:4px 12px;cursor:pointer}.sekme button.acik{border-color:var(--mavi)}
.soru{background:var(--kart);border:1px solid var(--cizgi);border-radius:12px;padding:12px 14px;margin-bottom:10px}
.soru.KIRMIZI{border-left:4px solid var(--kirmizi)}.soru.SARI{border-left:4px solid var(--altin)}.soru.YESIL{border-left:4px solid var(--yesil)}
.bas{display:flex;justify-content:space-between;gap:8px;flex-wrap:wrap;align-items:center}.bas b{font-size:1.02em}.kim{color:var(--dim);font-size:.85em}
.hucreler{display:grid;grid-template-columns:repeat(auto-fill,minmax(150px,1fr));gap:6px;margin:8px 0}
.h{border:1px solid var(--cizgi);border-radius:8px;padding:5px 8px;font-size:.82em}.h i{display:inline-block;width:9px;height:9px;border-radius:50%;margin-right:5px;vertical-align:middle}
.h.YESIL i{background:var(--yesil)}.h.KIRMIZI i{background:var(--kirmizi)}.h.OLCULMEDI i{background:var(--dim)}.h small{display:block;color:var(--dim);margin-top:2px;white-space:normal}
details{margin-top:6px}summary{cursor:pointer;color:var(--mavi);font-size:.9em}.govde{white-space:pre-wrap;color:var(--yazi);font-size:.92em;margin-top:6px}
.karar{display:flex;gap:8px;margin-top:8px;align-items:center}.karar button{border:1px solid var(--cizgi);background:var(--kart);color:var(--yazi);border-radius:8px;padding:6px 12px;cursor:pointer}.karar button.ok{border-color:var(--yesil)}.karar button.yan{border-color:var(--kirmizi)}.karar .dur{color:var(--dim);font-size:.85em}
.gizli{display:none}
</style></head><body>
'@)
[void]$sb.Append("<h1>Soru Karnesi · Cem'in kuyruğu</h1><div class='ozet'>Ölçüm $($raporNesne.olcum) · <b>$($ozet.soru)</b> soru · kırmızı <b>$($ozet.kirmizi)</b> · sarı (ölçülmemiş hücre) <b>$($ozet.sari)</b> · yeşil <b>$($ozet.yesil)</b> · kuyruk <b>$($ozet.kuyruk)</b> (bunun $($ozet.ornek)'i yeşil örneklem, %$OrneklemYuzde). Kırmızı ve sarı olanlar ile örneklem senin okuyacakların; yeşil kalanı makine geçirdi.</div>")
[void]$sb.Append("<div class='sekme'><button class='acik' data-f='kuyruk'>Kuyruk ($($ozet.kuyruk))</button><button data-f='KIRMIZI'>Kırmızı ($($ozet.kirmizi))</button><button data-f='SARI'>Sarı ($($ozet.sari))</button><button data-f='hepsi'>Hepsi ($($ozet.soru))</button></div>")
$hAd=[ordered]@{ hakem='Hakem'; sim='Öğretti mi (sim)'; aritmetik='Aritmetik'; hesapKod='Hesap kodu–ad'; turkce='Türkçe'; sik='Şık dengesi'; pencere='Pencere (K10)'; kaynak='Kaynak' }
foreach($s in ($sorular | Sort-Object { @{KIRMIZI=0;SARI=1;YESIL=2}[$_.durum] }, id)){
  [void]$sb.Append("<div class='soru $($s.durum)' data-durum='$($s.durum)' data-kuyruk='$(if($s.kuyruk){1}else{0})' data-id='$(E $s.id)'><div class='bas'><b>$(E $s.konu)</b><span class='kim'>$(E $s.ders) · $(E $s.id)$(if($s.ornek){ ' · yeşil örneklem' })</span></div><div class='hucreler'>")
  foreach($ad in $hAd.Keys){ $hc=$s.hucre[$ad]; [void]$sb.Append("<div class='h $($hc.durum)'><i></i>$($hAd[$ad])<small>$(E $hc.not)</small></div>") }
  $sikM=(@('A','B','C','D','E') | ForEach-Object { "$_) $($s.siklar.$_)" }) -join "`n"
  [void]$sb.Append("</div><details><summary>Soruyu göster (doğru: $($s.dogru))</summary><div class='govde'>$(E $s.soru)`n`n$(E $sikM)</div></details><div class='karar'><button class='ok'>Okey</button><button class='yan'>Yanlış…</button><span class='dur'></span></div></div>")
}
[void]$sb.Append(@'
<script>
const SB='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_bildirim', KEY='sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg';
const sekme=document.querySelectorAll('.sekme button'); function suz(f){ sekme.forEach(b=>b.classList.toggle('acik',b.dataset.f===f)); document.querySelectorAll('.soru').forEach(el=>{ const g=(f==='hepsi')||(f==='kuyruk'&&el.dataset.kuyruk==='1')||(el.dataset.durum===f); el.classList.toggle('gizli',!g); }); }
sekme.forEach(b=>b.addEventListener('click',()=>suz(b.dataset.f))); suz('kuyruk');
let kayit={}; try{ kayit=JSON.parse(localStorage.getItem('karne_karar')||'{}'); }catch(e){}
document.querySelectorAll('.soru').forEach(el=>{ const id=el.dataset.id; const dur=el.querySelector('.dur'); if(kayit[id]) dur.textContent='kaydedildi: '+kayit[id];
  const gonder=(metin)=>{ kayit[id]=metin; try{ localStorage.setItem('karne_karar',JSON.stringify(kayit)); }catch(e){} dur.textContent='kaydediliyor…';
    const [ders,konu]=[el.querySelector('.kim').textContent.split(' · ')[0], el.querySelector('.bas b').textContent];
    fetch(SB,{method:'POST',headers:{'Content-Type':'application/json',apikey:KEY,Authorization:'Bearer '+KEY,Prefer:'return=minimal'},body:JSON.stringify({soru_id:id,ders:ders,konu:konu,not_metni:metin,oturum:'karne-cem',uye:'cem'})}).then(r=>{ dur.textContent=(r.ok?'kaydedildi: ':'yerelde kaldı ('+r.status+'): ')+metin; }).catch(()=>{ dur.textContent='yerelde kaldı: '+metin; }); };
  el.querySelector('.ok').addEventListener('click',()=>gonder('KARNE OKEY'));
  el.querySelector('.yan').addEventListener('click',()=>{ const n=prompt('Neyi yanlış buldun? (kısa)'); if(n&&n.trim()) gonder('KARNE YANLIŞ: '+n.trim()); });
});
</script></body></html>
'@)
$hedefHtml=Join-Path $kok ("sql-yerel\"+$Cikti)
[IO.File]::WriteAllText($hedefHtml,$sb.ToString(),[Text.UTF8Encoding]::new($false))
"sayfa: $hedefHtml"
