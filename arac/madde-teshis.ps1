#requires -Version 5.1
<#
================================================================================
  MADDE TESHISI — "ambarda mi yok, pakette mi yok?"  (11.09.2026)

  NIYE VAR: kurtarma turu, hakemin "kaynak metni su maddeyi ICERMEMEKTEDIR"
  gerekcesinden madde cikarip DOGRUDAN "AMBAR EKSIGI - yutma is emri" diyordu.
  AMBARA HIC SORMADAN. Cem "41 eksik maddeyi yut" dedi; yutmadan once olctum:
  41'in 41'i AMBARDA VARDI (metinleriyle dogrulandi - VUK m.231 "Fatura
  nizami", TTK m.376 sermaye kaybi, TBK m.417). Yutma is emri degil, YANLIS
  TESHIS. Uzerine is yapilsaydi bosa emek + mukerrer yutma olurdu.

  Ayni hata bugun IKINCI kez: sabah "492 Harclar ambarda yok" demistim, kanun
  240 maddeyle yutulmus cikti (sirasiz limit=1 tuzagi). Kural tek:
  ⛔ OLCMEDIGINE VAR/YOK DEME.

  ⛔ IKINCI DUZELTME (11.09 03:00) — "pakette_yok" ETIKETI DE YANLISTI.
  Gerekceleri OKUYUNCA gorunuyor ki hakem maddenin EKSIK oldugunu soylemiyor,
  maddenin NE DEDIGINI soyluyor:
    "VUK m.283 YALNIZCA alacaklarin mukayyet degeriyle faizle degerlenmesini
     soyler, ... gider tahakkuk hesaplama yontemini TANIMLAMAZ"
    "VUK m.227'de YALNIZCA belgelerin tevsiki duzenlenmistir; kayit surecinin
     siralamasi bu maddede YER ALMAMAKTADIR"
  Yani madde pakette VAR; sorunun IDDIASINI desteklemiyor. Bu bir DAYANAK
  UYUSMAZLIGI - ne yutma isi ne de paket eksigi.

  Bir regex bu ikisini AYIRAMAZ. O yuzden betik artik SEBEP ATAMIYOR; yalnizca
  OLCTUGU seyi soyluyor: madde ambarda var mi, yok mu. Sebep tayini gerekceyi
  OKUMAYI ister (insan ya da model), regex'i degil.

  ⛔ BU DOSYA IKI KEZ YANLIS ETIKET URETTI. Ders: "su kusurdur" demek, olcum
     degil YORUMDUR. Olcum "madde ambarda var" der; gerisini okuyan soyler.

  KULLANIM
    . arac/madde-teshis.ps1                 # kutuphane: AmbardaVarMi
    powershell -File arac/madde-teshis.ps1 -Tazele
        veri/kurtarma-turu.json'dan yeniden turetir, veri/kurtarma-ambar-eksigi.json yazar.
        Turu YENIDEN KOSMAZ - bedel 0.
================================================================================
#>
param([switch]$Tazele)

$MADDE_ONEK=@{ 'VUK'='VUK (213 s.K.)'; 'TTK'='TTK (6102 s.K.)'; 'TBK'='TBK (6098 s.K.)'
               'GVK'='GVK (193 s.K.)'; 'KVK'='KVK (5520 s.K.)'; 'KDVK'='KDVK (3065 s.K.)'
               'AATUHK'='(6183 s.K.)'; 'IYUK'='(2577 s.K.)' }
$MADDE_ANAHTAR="$($env:SUPABASE_SERVICE_KEY)".Trim()
if(-not $MADDE_ANAHTAR){ $MADDE_ANAHTAR="$([Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'))".Trim() }
$MADDE_BASLIK=@{ apikey=$MADDE_ANAHTAR; Authorization="Bearer $MADDE_ANAHTAR"
                 Accept='application/json'; 'User-Agent'='mevzuat-radar-robot/1.0' }
$MADDE_TABAN='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12

# $true = ambarda var · $false = ambarda yok · $null = OLCULEMEDI ("yok" deme!)
function MaddeAdAra([string]$desen,[string]$madde){
  $adres=$MADDE_TABAN+'?select=kaynak_ad&kaynak_ad=ilike.'+[uri]::EscapeDataString($desen)+'&order=kaynak_ad.asc&limit=40'
  $cevap=$null
  try{ $cevap=Invoke-RestMethod -Uri $adres -Headers $MADDE_BASLIK -TimeoutSec 90 }catch{ return $null }
  # ⚠ '%m.15%' sorgusu m.150'yi de getirir - donen ADLAR regex ile DOGRULANIR.
  #   'ek m.' ve 'gec. m.' AYRI maddelerdir, sayilmaz.
  $adlar=@($cevap|ForEach-Object{ "$($_.kaynak_ad)" })
  return @($adlar|Where-Object{ $_ -match ("(?<!ek )(?<!gec\. )m\." + $madde + "(\D|$)") }).Count
}
function AmbardaVarMi([string]$kanun,[string]$madde){
  if(-not $MADDE_ANAHTAR){ return $null }
  # ⛔ AMBARDA TEK BIR AD KALIBI YOK. Olculdu (11.09):
  #      "TBK (6098 s.K.) m.417"      <- kisaltma + parantez
  #      "5510 s. SGK Kanunu m.3"     <- numara + acik ad
  #      "1475 s. Is K. (kidem ... m.14) bolum 1"
  #    Ilk surum yalniz birinci kalibi biliyordu ve "5510 m.3" icin AMBARDA YOK
  #    dedi - oysa 6 parca halinde duruyordu. Bir ad kalibina gore "yok" demek,
  #    olcmemektir. Simdi onek DENENIR, tutmazsa GEVSEK desene dusulur.
  # ⚠ Gevsek desen dogrudan kullanilamaz: ilike '%VUK%' "AVUKatlik"a takiliyor.
  #    O yuzden once dar desen, sonra gevsek - ve ikisinde de ad regex'le dogrulanir.
  $onek=$MADDE_ONEK[$kanun]
  if($onek){
    $n=MaddeAdAra ('%'+$onek+'%m.'+$madde+'%') $madde
    if($n -eq $null){ return $null }
    if($n -gt 0){ return $true }
  }
  # gevsek: kanun numarasi ya da kisaltma, ad kalibi ne olursa olsun
  $n2=MaddeAdAra ('%'+$kanun+'%m.'+$madde+'%') $madde
  if($n2 -eq $null){ return $null }
  return ($n2 -gt 0)
}

# Gerekce metninden kanun+madde cikarir (kurtarma-turu.ps1 ile AYNI iki desen)
function GerekcedenMadde([string]$gerekce){
  $cikan=New-Object System.Collections.Generic.List[object]
  foreach($e in [regex]::Matches($gerekce,'(?i)(\d{3,5})\s*say[ıi]l[ıi][^,;.]{0,40}?\bm\.?\s*(\d{1,4})')){
    $cikan.Add([pscustomobject]@{ kanun=$e.Groups[1].Value; madde=$e.Groups[2].Value })
  }
  foreach($e in [regex]::Matches($gerekce,'(?i)\b(IYUK|VUK|TTK|TBK|KVK|GVK|KDVK|AATUHK|BDS|TMS|TFRS)\s*m\.?\s*(\d{1,4})')){
    $cikan.Add([pscustomobject]@{ kanun=$e.Groups[1].Value.ToUpperInvariant(); madde=$e.Groups[2].Value })
  }
  return $cikan.ToArray()
}

if(-not $Tazele){ return }

# --- TAZELEME: turu yeniden kosmadan, mevcut tur ciktisindan yeniden turet ---
$ErrorActionPreference='Stop'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok=Split-Path -Parent $here
. (Join-Path $here 'olcum-kapilari.ps1')
$kapi=Test-OlcumKapilari -Sessiz
if((Dizi $kapi).Count){ foreach($h in (Dizi $kapi)){ Write-Host "  - $h" -ForegroundColor Red }; throw 'olcum kapilari dustu' }

$turDosya=Join-Path $depoKok 'veri\kurtarma-turu.json'
if(-not (Test-Path $turDosya)){ throw "tur ciktisi yok: $turDosya" }
# ⛔ once degiskene al, sonra @() ile sar (PS 5.1 dizi sarma tuzagi)
$tur=Get-Content $turDosya -Raw -Encoding UTF8|ConvertFrom-Json
$kayitlar=@($tur.kayitlar)
Write-Host ("tur ciktisi: {0:N0} kayit · olcum {1}" -f $kayitlar.Count,$tur.olcum) -ForegroundColor Cyan

$vakalar=New-Object System.Collections.Generic.List[object]
foreach($k in $kayitlar){
  if("$($k.yeni)" -eq 'EVET'){ continue }
  foreach($m in (GerekcedenMadde "$($k.gerekce)")){
    $vakalar.Add([ordered]@{ etiket="$($k.etiket)"; id="$($k.id)"; konu="$($k.konu)"
                             kanun=$m.kanun; madde=$m.madde; gerekce="$($k.gerekce)" })
  }
}
$benzersiz=@{}
foreach($v in (Dizi $vakalar)){ $benzersiz["$($v.kanun) m.$($v.madde)"]=$v }
Write-Host ("vaka {0} · benzersiz madde {1} — ambara soruluyor..." -f (Dizi $vakalar).Count,$benzersiz.Count) -ForegroundColor Cyan

$ambardaYok=New-Object System.Collections.Generic.List[string]
$ambardaVar=New-Object System.Collections.Generic.List[string]
$olculemedi=New-Object System.Collections.Generic.List[string]
foreach($ad in @($benzersiz.Keys|Sort-Object)){
  $v=$benzersiz[$ad]
  $sonuc=AmbardaVarMi "$($v.kanun)" "$($v.madde)"
  if($sonuc -eq $null){ $olculemedi.Add($ad) } elseif($sonuc){ $ambardaVar.Add($ad) } else { $ambardaYok.Add($ad) }
}

. (Join-Path $here 'rapor-yaz.ps1')
RaporYaz -Hedef (Join-Path $depoKok 'veri\kurtarma-ambar-eksigi.json') -Nesne ([ordered]@{
  olcum=(Get-Date -Format 'yyyy-MM-dd HH:mm')
  olculen='Hakemin gerekcesinde gecen kanun maddeleri AMBARA SORULDU. Bu dosya yalnizca "madde ambarda var mi" sorusunu cevaplar.'
  olculmeyen='SEBEP. Hakem maddeyi cogu zaman EKSIK oldugu icin degil, NE DEDIGINI soylemek icin aniyor ("VUK m.283 YALNIZCA ... tanimlamaz"). Yani madde pakette VAR ama iddiayi desteklemiyor olabilir - DAYANAK UYUSMAZLIGI. Bir regex bunu ayiramaz; sebep icin gerekce OKUNMALI.'
  uyari='⛔ Bu dosya iki kez YANLIS ETIKET uretti (once "ambar eksigi", sonra "paket kusuru"). Ucuncusunu uretmemek icin artik SEBEP ATANMIYOR.'
  kaynak='arac/madde-teshis.ps1 -Tazele (veri/kurtarma-turu.json uzerinden, tur YENIDEN KOSULMADI)'
  benzersiz_madde=$benzersiz.Count; toplam_vaka=(Dizi $vakalar).Count
  ambarda_yok_sayi=$ambardaYok.Count; ambarda_var_sayi=$ambardaVar.Count; olculemedi_sayi=$olculemedi.Count
  maddeler_ambarda_yok=$ambardaYok.ToArray()
  maddeler_ambarda_var=$ambardaVar.ToArray()
  maddeler_olculemedi=$olculemedi.ToArray()
  kayitlar=@((Dizi $vakalar)|ForEach-Object{ [pscustomobject]$_ })
})
Write-Host ("`nMADDE OLCUMU: {0} benzersiz ({1} vaka)" -f $benzersiz.Count,(Dizi $vakalar).Count) -ForegroundColor Cyan
Write-Host ("  AMBARDA YOK -> yutma is emri : {0}" -f $ambardaYok.Count) -ForegroundColor $(if($ambardaYok.Count){'Yellow'}else{'Green'})
Write-Host ("  AMBARDA VAR -> sebep OKUNARAK bulunur : {0}" -f $ambardaVar.Count) -ForegroundColor Cyan
if($olculemedi.Count){ Write-Host ("  OLCULEMEDI                   : {0}" -f $olculemedi.Count) -ForegroundColor DarkGray }
Write-Host "  ⛔ SEBEP ATANMADI - bu dosya 'su kusurdur' DEMEZ, yalniz olcer." -ForegroundColor DarkGray
Write-Host "-> veri/kurtarma-ambar-eksigi.json" -ForegroundColor Green
