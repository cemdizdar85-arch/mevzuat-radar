# ============================================================================
#  VEKTOR KANALI KARNESI — vektor arama, madde_ara'nin bulamadigini buluyor mu?
#
#  NEDEN VAR (10.09.2026). Butun gun olculen tek arıza su: ambarda DURAN dogru
#  madde, arama tarafindan bulunamiyor.
#    · 'vergi ziyai cezasi' -> madde_ara m.370'i (Izaha davet) getiriyor,
#      oysa m.341 (Vergi ziyai) ve m.344 (cezasi) ambarda duruyor.
#    · 'degerleme olculeri' -> bir kosuda m.261 (dogru), sonraki kosuda m.49.
#    · Genel rakam: uretim plan satirlarinin %29,4'u "maddesiz" sayilip atlandi.
#
#  Yeni motorun cevabi HIBRIT ARAMA: tam metin kanalinin yaninda bir de VEKTOR
#  kanali. Ama bu bir iddia; olculmeden dogru sayilmaz.
#
#  BU ARAC O IDDIAYI SINAR ve Postgres'e ihtiyac DUYMAZ:
#    1) VUK parcalarini ambardan ceker (PostgREST - elimizde anahtar var)
#    2) hepsini Gemini ile gomer (RETRIEVAL_DOCUMENT)
#    3) her konuyu sorgu olarak gomer (RETRIEVAL_QUERY - ASIMETRIK)
#    4) cosine benzerligiyle en yakin parcayi bulur
#    5) sonucu BEKLENEN madde ile karsilastirir ve madde_ara'nin ayni konuda
#       ne getirdigini yaninda gosterir
#
#  Yani rag semasi bos olsa da "vektor kanali ise yarar mi" sorusu bugun
#  cevaplanabilir. Postgres sifresi geldiginde ayni mantik rag.ara icinde,
#  RRF ile tam metin kanalina EKLENEREK calisacak.
#
#  NORMALIZE SART (olculdu): Gemini outputDimensionality ile kisaltilmis
#  vektoru NORMALIZE ETMEDEN donduruyor (olculen L2 normu 0,58). Cosine
#  hesabi normalize edilmeden yapilirsa uzun metinler yapay avantaj kazanir.
#
#  PARA: gomme ucu. Yeni anahtar FATURASIZ projede (ucretsiz kota), yani bu
#  kosuda ucret cikmaz; kota sinirina takilirsa yavaslar, durmaz.
#
#  CIKTI: veri/vektor-kanali-karnesi.json
#  KOSMA: powershell -NoProfile -File arac/vektor-kanali-karnesi.ps1
# ============================================================================
param(
  [int]$Yigin = 20,
  # Ucretsiz kota DAKIKALIK istek sinirlidir; 400 ms ile 43 istegi arka arkaya
  # atmak 429 uretiyor (olculdu). 8 sn fren ~7 istek/dk demek - guvenli tarafta.
  [int]$FrenMs = 8000
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$kok = Split-Path -Parent $PSScriptRoot
$SB  = 'https://bjrleanjpyujtajmazxn.supabase.co'
$SK  = if($env:SB_PUBLISHABLE){ $env:SB_PUBLISHABLE } else { 'sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg' }
$SH  = @{ apikey=$SK; Authorization="Bearer $SK" }
$G   = $env:GEMINI_API_KEY
if(-not $G){ $G=[Environment]::GetEnvironmentVariable('GEMINI_API_KEY','User') }
if(-not $G){ Write-Host 'KOR: GEMINI_API_KEY yok.'; exit 3 }
. (Join-Path $kok 'arac\rapor-yaz.ps1')

# Beklenen dayanak = 002_konu_madde.sql'e basilan konu kartlari.
$KONULAR = @(
  @{ konu='degerleme olculeri ve maliyet bedeli'; bekle='m.261' }
  @{ konu='amortisman ayirma sartlari';           bekle='m.313' }
  @{ konu='supheli alacak karsiligi';             bekle='m.323' }
  @{ konu='vergi ziyai cezasi';                   bekle='m.344' }
  @{ konu='fatura duzenleme suresi';              bekle='m.231' }
)
$DERS='Vergi Mevzuatı ve Uygulaması'

# 429'A OZEL BEKLEME (olculdu 10.09): ucretsiz kotanin sinirі DAKIKALIK'tir.
# Ustel geri cekilme 2/4/6/8/10 sn ile toplam ~30 sn eder ve dakikalik pencere
# dolmadan tekrar carpar. 429 gorulunce 65 saniye beklenir - pencere kapanir.
# Diger hatalar icin kisa geri cekilme yeterli.
function Cagir([scriptblock]$is,[int]$n=10){
  foreach($d in 1..$n){
    try{ return (& $is) }
    catch{
      if($d -eq $n){ throw }
      $m="$($_.Exception.Message)"
      if($m -match '429|Too Many'){
        Write-Host ("    kota siniri (429) - 65 sn bekleniyor [{0}/{1}]" -f $d,$n) -ForegroundColor DarkYellow
        Start-Sleep -Seconds 65
      } else {
        Start-Sleep -Seconds (3*$d)
      }
    }
  }
}
function Normalize([double[]]$v){
  $kare=0.0; foreach($x in $v){ $kare += $x*$x }
  $u=[math]::Sqrt($kare); if($u -lt 1e-12){ return $v }
  $c=New-Object double[] $v.Length
  for($i=0;$i -lt $v.Length;$i++){ $c[$i]=$v[$i]/$u }
  return $c
}
function Cosine([double[]]$a,[double[]]$b){ $s=0.0; for($i=0;$i -lt $a.Length;$i++){ $s += $a[$i]*$b[$i] }; return $s }

function Gom([string[]]$metinler,[string]$gorev){
  $istekler=@($metinler|ForEach-Object{ @{ model='models/gemini-embedding-001'; content=@{ parts=@(@{ text=$_ }) }; taskType=$gorev; outputDimensionality=768 } })
  $govde=@{ requests=$istekler } | ConvertTo-Json -Depth 10
  $y = Cagir { Invoke-RestMethod -Method Post -Uri "https://generativelanguage.googleapis.com/v1beta/models/gemini-embedding-001:batchEmbedContents?key=$G" -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 300 }
  # PS TUZAGI (olculdu): `@(... | ForEach-Object { Normalize ... })` ic dizileri
  # DUZLESTIRIR - 20 vektor x 768 boyut = 15.360 eleman olur ve sayi tutmaz.
  # Diziyi bozmadan tasimak icin ArrayList + basinda virgul ile donduruluyor.
  $out = New-Object System.Collections.ArrayList
  foreach($e in $y.embeddings){ [void]$out.Add((Normalize @($e.values))) }
  return ,$out.ToArray()
}

# --- 1) VUK parcalari -----------------------------------------------------
Write-Host 'VUK parcalari cekiliyor...'
$parcalar=New-Object System.Collections.ArrayList; $sonId=''
while($true){
  $u="$SB/rest/v1/dokumanlar?select=id,kaynak_ad,metin&kaynak_ad=like."+[uri]::EscapeDataString('VUK*')+"&order=id&limit=200"
  if($sonId){ $u += "&id=gt.$sonId" }
  $r = Cagir { Invoke-WebRequest -Uri $u -Headers $SH -UseBasicParsing -UserAgent 'mevzuat-radar-robot/1.0' -TimeoutSec 180 }
  $s = @([Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray())|ConvertFrom-Json|ForEach-Object{$_})
  if($s.Count -eq 0){ break }
  foreach($x in $s){ [void]$parcalar.Add($x) }
  $sonId="$($s[$s.Count-1].id)"
  Start-Sleep -Milliseconds 150
}
Write-Host ("  {0:N0} parca" -f $parcalar.Count)

# --- 2) belge tarafi gomme -------------------------------------------------
Write-Host 'Gomuluyor (RETRIEVAL_DOCUMENT)...'
$vek=New-Object System.Collections.ArrayList
$sw=[Diagnostics.Stopwatch]::StartNew()
for($i=0; $i -lt $parcalar.Count; $i+=$Yigin){
  $son=[Math]::Min($i+$Yigin,$parcalar.Count)-1
  $dilim=@($parcalar[$i..$son])
  $v = Gom @($dilim|ForEach-Object{ "$($_.metin)" }) 'RETRIEVAL_DOCUMENT'
  if($v.Count -ne $dilim.Count){ throw "gomme sayisi uyusmuyor: $($v.Count)/$($dilim.Count)" }
  for($z=0;$z -lt $dilim.Count;$z++){ [void]$vek.Add([pscustomobject]@{ ad="$($dilim[$z].kaynak_ad)"; v=$v[$z] }) }
  if(($i+$Yigin) % 200 -lt $Yigin){ Write-Host ("  {0}/{1} ..." -f ($son+1),$parcalar.Count) }
  Start-Sleep -Milliseconds $FrenMs
}
Write-Host ("  bitti: {0} vektor / {1:N1} sn" -f $vek.Count, ($sw.ElapsedMilliseconds/1000))

# --- 3) sorgu tarafi + karsilastirma --------------------------------------
Write-Host ''
$sonuc=New-Object System.Collections.ArrayList
foreach($k in $KONULAR){
  $sv = (Gom @("$DERS $($k.konu)") 'RETRIEVAL_QUERY')[0]
  $en=$null; $enSkor=-2.0; $ilk5=@()
  foreach($p in $vek){
    $s = Cosine $sv $p.v
    $ilk5 += [pscustomobject]@{ ad=$p.ad; skor=$s }
    if($s -gt $enSkor){ $enSkor=$s; $en=$p.ad }
  }
  $ilk5 = @($ilk5 | Sort-Object skor -Descending | Select-Object -First 5)
  $tuttu = ($en -match [regex]::Escape($k.bekle))
  [void]$sonuc.Add([pscustomobject]@{
    konu=$k.konu; beklenen=$k.bekle; vektor_ilk=$en; skor=[math]::Round($enSkor,4); isabet=$tuttu
    ilk5=@($ilk5|ForEach-Object{ [pscustomobject]@{ ad=$_.ad; skor=[math]::Round($_.skor,4) } })
  })
  Write-Host ("{0,-40} bekle {1,-7} -> {2}  [{3}]" -f $k.konu,$k.beklenen,$en,$(if($tuttu){'ISABET'}else{'ISKA'}))
  Start-Sleep -Milliseconds $FrenMs
}

$isabet=@($sonuc|Where-Object{$_.isabet}).Count
Write-Host ''
Write-Host ("VEKTOR KANALI: {0}/{1} isabet" -f $isabet,$sonuc.Count)

$cikti=[ordered]@{
  olcum=(Get-Date -Format 'dd.MM.yyyy HH:mm')
  aciklama='Vektor kanali, madde_ara nin bulamadigi maddeleri buluyor mu? Postgres GEREKTIRMEZ - gomme + cosine yerelde hesaplanir.'
  model='gemini-embedding-001 (768, asimetrik, L2 normalize)'
  parca_sayisi=$parcalar.Count
  isabet=$isabet; toplam=$sonuc.Count
  satirlar=@($sonuc)
}
RaporYaz -Hedef (Join-Path $kok 'veri\vektor-kanali-karnesi.json') -Nesne $cikti -ZamanAlanlari @('olcum') | Out-Null
Write-Host '  -> veri/vektor-kanali-karnesi.json'
