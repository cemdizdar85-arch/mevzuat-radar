#requires -Version 5.1
<#
================================================================================
  KONU–KAYNAK BAGI KAPISI  (11.09.2026, Cem "boyle bir sey olmamasi icin
  bastan engelleyelim hepsini")

  NE YAPAR: her mufredat konusu icin "bu konunun ambarda GERCEKTEN metni var mi"
  sorusunu cevaplar. Cikti, uretime GIREBILECEK konularin listesidir. Kaynagi
  olmayan konu plana girmez, `kaynak-eksik-konular.json` is emrine dusulur
  (bu kural 09.09'da yazildi: "kaynak yuzunden dusen konu plana girmez").

  ⛔ AD ILE DEGIL METIN ILE OLCER - ve bu ayrimi bugun pahaliya ogrendik:
  Once kaynak ADLARINA bakip "288 konunun kaynagi yok" dedim. Yanlisti.
  Kanun derslerinde kaynak adi bir KUNYEDIR ("TTK (6102 s.K.) m.370"), konu adi
  tasimaz; ad uzerinden olcmek o derslerde HICBIR ZAMAN tutmaz.
  Metinle olculunce gercek sayi ortaya cikti:
     kaynak ADI konuyla eslesmeyen soru : 260
     ama konu kelimeleri METINDE gecen  : 249  (paket saglam)
     metinde de gecmeyen                :  11  <- gercek kusur
  Yani iddiam 26 kat fazlaydi.

  ⚠ KALAN 11'IN COGU DA KAYNAK EKSIKLIGI DEGIL:
   - 'kusursuz sorumluluk' : kanun "kusuru olmasa bile" der; "kusursuz
     sorumluluk" DOKTRIN terimidir -> terim koprusu isi (sozlesme A5b, 007)
   - 'tms 28 istirakler'   : metinde "istirak" var, olcum "istirakler" aradi
     -> CEKIM farki, verinin degil OLCUMUN kusuru
  Bu yuzden bu betik KOK eslesmesi yapar (kelimenin ilk 5-6 harfi), tam
  eslesme degil; ve tek kelime eslesmesini "zayif" sayar, "yok" saymaz.

  BEDEL 0 - yalniz ambar sorgusu, model cagrilmaz.

  KULLANIM
    powershell -NoProfile -ExecutionPolicy Bypass -File arac/konu-kaynak-bagi.ps1
    powershell -NoProfile -ExecutionPolicy Bypass -File arac/konu-kaynak-bagi.ps1 -Ders 'Ticaret ve Borclar'
================================================================================
#>
param(
  [string]$Ders = '',
  [int]$Adet = 0
)
$ErrorActionPreference='Stop'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok=Split-Path -Parent $here

$KEY="$([Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'))".Trim()
if(-not $KEY){ $KEY="$($env:SUPABASE_SERVICE_KEY)".Trim() }
if(-not $KEY){ throw 'SUPABASE_SERVICE_KEY yok.' }
$SBH=@{apikey=$KEY;Authorization="Bearer $KEY";Accept='application/json';'User-Agent'='mevzuat-radar-robot/1.0'}
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12

function Katla2([string]$s){
  ("$s" -creplace 'İ','i' -creplace 'I','i' -creplace 'ı','i' -creplace 'Ğ','g' -creplace 'ğ','g' `
       -creplace 'Ü','u' -creplace 'ü','u' -creplace 'Ş','s' -creplace 'ş','s' `
       -creplace 'Ö','o' -creplace 'ö','o' -creplace 'Ç','c' -creplace 'ç','c').ToLowerInvariant()
}
# Turkce sondan eklemeli: "istirakler" ile "istirak" ayni kok. Ilk 6 harf
# (kisa kelimede tamami) kok sayilir. Tam eslesme aramak 11 sahte kusur uretti.
function Kok([string]$k){ if($k.Length -le 6){ return $k }; return $k.Substring(0,6) }

# ⚠ TURKCE KATLAMA ASIMETRISI - 11.09'da bu arac iki sahte "YOK" uretti.
# Konu adini katliyorduk ("cevrimi" -> "cevrim") ama ambar metni KATLANMAMIS
# ("çevrim"). fts(simple) gercek karakteri arar: cevrim != çevrim.
# TMS 21 ambarda VARDI ("TMS 21 Ek A - Tanimlanan terimler"), arama bulamadi.
# Cozum: her kok icin Turkce varyantlari da uretilip OR ile aranir. Tek harflik
# donusum yeter (cevrim -> çevrim); tum kombinasyonlar gereksiz ve pahali.
function KokVaryant([string]$k){
  $c=New-Object System.Collections.Generic.List[string]
  $c.Add($k)
  $harita=@{ 'c'='ç'; 's'='ş'; 'g'='ğ'; 'u'='ü'; 'o'='ö'; 'i'='ı' }
  foreach($h in $harita.Keys){
    $i=0
    while($true){
      $i=$k.IndexOf($h,$i)
      if($i -lt 0){ break }
      $v=$k.Substring(0,$i)+$harita[$h]+$k.Substring($i+1)
      if($c -notcontains $v){ $c.Add($v) }
      $i++
    }
  }
  return @($c)
}
# ⚠ KAYNAKSIZ DERSLER HATTI ISTISNASI (SORU-BASMA-KURALLARI Bolum F, 08.09):
# Turkce · Matematik · Yabanci Dil · Inkilap · Ekonomi · Maliye derslerinde
# MEVZUAT METNI YOKTUR; kural 6.1 bu derslerde TEORI NOTUYLA saglanir
# ("TEORI - <konu>", tur teori-notu). Bu derslerde mevzuat aramak ve "kaynagi
# yok" demek YANLISTIR - hat bilerek boyle kuruldu.
# 11.09 olcumu bunu gosterdi: Yabanci Dil'de "correlative conjunction" konusu
# YOK ciktı; Ingilizce dilbilgisi terimi Turkce ambarda zaten olmaz.
# Bu dersler ayri isaretlenir (TEORI-HATTI), YOK sayilmaz.
$KAYNAKSIZ_DERSLER=@('turkce','matematik','yabanci dil','ataturk ilkeleri ve inkilap tarihi','ataturk ilkeleri','ekonomi','maliye')
$DOLGU=@('ile','icin','veya','bir','olan','gibi','hesap','kaydi','islem','yonte','tutar','genel','ozel','kavra','tanim')

$oneriler=@((Get-Content (Join-Path $depoKok 'veri\kart-onerileri.json') -Raw -Encoding UTF8 | ConvertFrom-Json).oneriler)
if($Ders){ $oneriler=@($oneriler | Where-Object { "$($_.ders)" -eq $Ders }) }
if($Adet -gt 0){ $oneriler=@($oneriler | Select-Object -First $Adet) }
Write-Host ("OLCULECEK KONU: {0}" -f $oneriler.Count) -ForegroundColor Cyan

$sonuc=New-Object System.Collections.Generic.List[object]
$n=0; $guclu=0; $zayif=0; $yok=0
foreach($o in $oneriler){
  $n++
  $kel=@([regex]::Matches((Katla2 "$($o.konu)"),'[a-z0-9]{4,}') | ForEach-Object { Kok $_.Value } |
         Where-Object { $DOLGU -notcontains $_ } | Select-Object -Unique)
  if(-not $kel.Count){
    $sonuc.Add([pscustomobject]@{ders="$($o.ders)";konu="$($o.konu)";durum='ADI-OLCULEMEZ';eslesen=0;toplam=0;kaynak=''})
    continue
  }
  # Ambarda konu koklerini METINDE arayan tam metin sorgusu (fts(simple) kurali:
  # Turkce terim aramasi hep simple sozlukle - ilike tum tabloda 500 veriyor).
  # fts(simple) TAM JETON eslestirir: "calism" ile "calisma" tutmaz. Kok
  # aramasi ON EK arayisi ister -> her koke ":*" eklenir (RAG motorunda
  # olculmus desen; ilk denemede 30 konunun 23'u bu yuzden ZAYIF cikmisti).
  # Her kok, Turkce varyantlariyla birlikte OR'lanir; gruplar AND ile baglanir.
  $sorgu = (@($kel | ForEach-Object { $grp = @(@(KokVaryant $_) | ForEach-Object { "${_}:*" }); '(' + ($grp -join ' | ') + ')' }) -join ' & ')
  $u='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar?select=kaynak_ad&metin=fts(simple).'+[uri]::EscapeDataString($sorgu)+'&limit=3'
  $r=$null
  try{ $r=Invoke-RestMethod -Uri $u -Headers $SBH -TimeoutSec 60 }
  catch{ Write-Host ("  AMBAR HATASI ({0}): {1}" -f $o.konu,$_.Exception.Message) -ForegroundColor Red }
  $bulunan=@($r)
  $durum = if($bulunan.Count -ge 1){ 'GUCLU' } else { 'YOK' }
  # Tek kelimeye dusurup tekrar dene: butun kokler birlikte gecmiyorsa konu
  # "kaynaksiz" DEGIL, "dagilmis" olabilir.
  if($durum -eq 'YOK' -and $kel.Count -gt 1){
    # ⚠ PS: "$_:*" gecersiz - ':' degisken adinin parcasi sanilir. ${_} sinir cizer.
    $u2='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar?select=kaynak_ad&metin=fts(simple).'+[uri]::EscapeDataString((@($kel | ForEach-Object { (KokVaryant $_) } ) | ForEach-Object { "${_}:*" }) -join ' | ')+'&limit=3'
    $r2=$null; try{ $r2=Invoke-RestMethod -Uri $u2 -Headers $SBH -TimeoutSec 60 }catch{}
    if(@($r2).Count -ge 1){ $durum='ZAYIF'; $bulunan=@($r2) }
  }
  # Kaynaksiz dersler hattindaki YOK'lar TEORI-HATTI sayilir, kusur degildir.
  if($durum -eq 'YOK' -and ($KAYNAKSIZ_DERSLER -contains (Katla2 "$($o.ders)"))){ $durum='TEORI-HATTI' }
  switch($durum){ 'GUCLU'{$guclu++} 'ZAYIF'{$zayif++} 'YOK'{$yok++} 'TEORI-HATTI'{$zayif++} }
  $sonuc.Add([pscustomobject]@{
    ders="$($o.ders)"; konu="$($o.konu)"; durum=$durum
    kokler=($kel -join ','); kaynak=$(if($bulunan.Count){ "$($bulunan[0].kaynak_ad)" } else { '' })
  })
  if($n % 100 -eq 0){ Write-Host ("  {0}/{1} · GUCLU {2} · ZAYIF {3} · YOK {4}" -f $n,$oneriler.Count,$guclu,$zayif,$yok) -ForegroundColor DarkGray }
}

Write-Host ""
Write-Host ("BITTI: {0} konu · GUCLU {1} · ZAYIF {2} · YOK {3}" -f $sonuc.Count,$guclu,$zayif,$yok) -ForegroundColor Green
Write-Host "`nDERS BAZLI 'YOK':"
$sonuc | Where-Object { $_.durum -eq 'YOK' } | Group-Object ders | Sort-Object Count -Descending |
  ForEach-Object { Write-Host ("  {0,-32} {1,3}" -f $_.Name,$_.Count) }
Write-Host "`nURETIME GIREMEYECEK KONULARDAN ILK 15:"
$sonuc | Where-Object { $_.durum -eq 'YOK' } | Select-Object -First 15 |
  ForEach-Object { Write-Host ("  [{0}] {1}  (kokler: {2})" -f $_.ders,$_.konu,$_.kokler) }

. (Join-Path $here 'rapor-yaz.ps1')
# ⚠ KISMI KOSU TAM RAPORU EZMEZ (11.09): -Ders ya da -Adet ile kosuldugunda
#   dosya TEK DERSE inerdi. 11.09'da fark edildi: tam rapor 1.409 satirdan 37'ye
#   dusmustu. Fark edilmeseydi yarin "1.409 konu olculdu" diye 37 satirlik
#   dosyaya bakilacakti. Kismi kosu artik AYRI dosyaya yazar.
$hedefAd = if($Ders -or $Adet -gt 0){
  $ek = if($Ders){ (($Ders -replace '[^A-Za-z0-9]+','-').Trim('-')) } else { "ilk$Adet" }
  "veri\_konu-kaynak-bagi-KISMI-$ek.json"
} else { 'veri\konu-kaynak-bagi.json' }
if($hedefAd -ne 'veri\konu-kaynak-bagi.json'){ Write-Host ("KISMI KOSU -> {0} (tam rapor EZILMEDI)" -f $hedefAd) -ForegroundColor Yellow }
RaporYaz -Hedef (Join-Path $depoKok $hedefAd) -Nesne ([ordered]@{
  olcum=(Get-Date -Format 'yyyy-MM-dd HH:mm')
  yontem='Konu adinin >=4 harfli kelimelerinin KOKLERI (ilk 6 harf) ambar METNINDE fts(simple) ile aranir. AD ile DEGIL METIN ile olculur.'
  neden='11.09: ad uzerinden olcup "288 konunun kaynagi yok" demistim; metinle olculunce gercek sayi 11 cikti. Kanun derslerinde kaynak adi kunyedir, konu adi tasimaz.'
  kural='YOK cikan konu uretim planina GIRMEZ; kaynak-eksik-konular.json is emrine dusulur.'
  toplam=$sonuc.Count; guclu=$guclu; zayif=$zayif; yok=$yok
  satirlar=$sonuc
})
Write-Host ("`n-> {0}" -f $hedefAd)
