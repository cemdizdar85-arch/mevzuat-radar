# ============================================================================
#  DERS-ETIKET DENETCISI — 06.08.2026 (Cem: "Ataturk Inkilap diyor, ders soru
#  Turkce - bu hata olmasin, BUTUN dersleri denetle, kabul edilemez")
#
#  VAKA: SGS orneklem #19 - ders='Ataturk Ilke ve Inkilap Tarihi',
#  kaynak='turk medeni kanunu', icerik ANLATIM BOZUKLUGU (Turkce) sorusu.
#  KGK denetimi ayni hastaligi olcmustu: FY etiketli 14 kartin ~7'si baska
#  dersin sorusu. Etiket yanlissa koc, karne, tuyolar, prova bilesimi -
#  hepsi yanlis dersten beslenir.
#
#  YONTEM (0 USD, deterministik, YUKSEK ISABET kurallari - suphe degil kanit):
#   K1  Genel-kultur dersi (Turkce/Matematik/Inkilap/Yabanci Dil) etiketli
#       soruda KAYNAK alani kanun/standart gosteriyor -> sacmalik (vaka #19).
#   K2  Inkilap/Matematik/Yabanci Dil etiketli metinde Turkce dilbilgisi
#       imzasi (anlatim bozuklugu, yazim yanlisi, noktalama...) -> Turkce.
#   K3  Turkce/Matematik/Yabanci Dil etiketli metinde Inkilap imzasi
#       (Lozan, TBMM, saltanat...) -> Inkilap.
#   K4  Genel-kultur etiketli soruda yevmiye kaydi/hesap plani -> muhasebe.
#   K5  KGK FY/KY etiketli soruda yevmiye alani dolu -> muhasebe sizintisi.
#  Iceriksel-supheli durumlar (iki alan dersi arasi gecis) BURAYA GIRMEZ -
#  onlar etiket-onarim robotunun (bulgu #13) isi; bu denetci yalniz APACIK
#  yanlislari yakalar ki yanlis-pozitif sifira yakin olsun.
#
#  Varsayilan OLCUM; -yaz ile bulgulular yayin=false + not (hakem kuyrugu).
# ============================================================================
param([switch]$yaz)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$raporYol = Join-Path $kok 'veri/ders-etiket-raporu.json'
function RaporYaz($n){ [IO.File]::WriteAllText($raporYol, (ConvertTo-Json -InputObject $n -Depth 5), (New-Object Text.UTF8Encoding($false))) }
trap {
  RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'; hata="$($_.Exception.Message)"; satir=$_.InvocationInfo.ScriptLineNumber })
  Write-Host ("HATA (satir {0}): {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message); exit 1
}

$KEY = $env:SUPABASE_SERVICE_KEY
if(-not $KEY){ Write-Host 'SUPABASE_SERVICE_KEY yok - cikildi.'; exit 0 }
$U = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu'
$H = @{ apikey=$KEY }
if($KEY -like 'eyJ*'){ $H.Authorization = "Bearer $KEY" }

function Duz([string]$t){
  return "$t".ToLowerInvariant().Replace('ç','c').Replace('ğ','g').Replace('ı','i').Replace('İ','i').Replace('ö','o').Replace('ş','s').Replace('ü','u')
}
# imzalar (duz-ascii uzerinden aranir)
$reGenelKulturDers = [regex]'(?i)turkce|matematik|inkilap|ataturk|yabanci dil|genel kultur'
$reKanunKaynak     = [regex]'(?i)kanun|vuk|ttk|tmk|kvk|gvk|amme|icra|iflas|\btms\b|\btfrs\b|\bbds\b|sayili|madde|\bm\.\s*\d|teblig|yonetmelik|khk'
$reTurkceImza      = [regex]'anlatim bozuklugu|yazim yanlis|yazim kural|noktalama|sozcugun|es anlam|zit anlam|cumlenin oges|ozne|yuklem|paragraf|dil bilgisi|ses olayi|buyuk harf'
$reInkilapImza     = [regex]'lozan|mudanya|tbmm|saltanat|hilafet|milli mucadele|sivas kongre|erzurum kongre|misak|kuvay|mustafa kemal|ataturk ilke|cumhuriyetin ilan|sevr'
$reMuhasebeImza    = [regex]'yevmiye|hesabina borc|hesabina alacak|hesap plani|\b7[0-9]{2}\b.{0,20}hesab|tekduzen'
$reMatematikDers   = [regex]'matematik'
$reTurkceDers      = [regex]'turkce'
$reInkilapDers     = [regex]'inkilap|ataturk'
$reYabanciDers     = [regex]'yabanci dil|ingilizce'

$taranan=0
$bulgular = New-Object System.Collections.Generic.List[object]
$bas=0
while($true){
  $r = @(Invoke-RestMethod -Uri "$U`?select=id,sinav,ders,konu,kaynak,soru,siklar,aciklama,yevmiye,yayin&order=id&limit=500&offset=$bas" -Headers $H -TimeoutSec 300)
  if($r.Count -eq 0){ break }
  foreach($s in $r){
    if($null -eq $s){ continue }
    $taranan++
    $ders   = Duz "$($s.ders)"
    $kaynak = Duz "$($s.kaynak)"
    $sikMetin = (@('A','B','C','D','E') | ForEach-Object { try { "$($s.siklar.$_)" } catch { '' } }) -join ' '
    $govde  = Duz ("$($s.soru) " + $sikMetin)
    $tum    = $govde + ' ' + (Duz ("$($s.aciklama)"))
    $genelKultur = $reGenelKulturDers.IsMatch($ders)
    $sebep = @()
    # K1: genel-kultur dersinde kanun kaynagi
    if($genelKultur -and $kaynak -ne '' -and $reKanunKaynak.IsMatch($kaynak)){ $sebep += 'K1 genel-kultur dersinde kanun kaynagi: ' + "$($s.kaynak)" }
    # K2: Turkce-olmayan genel kultur dersinde dilbilgisi imzasi
    if(($reInkilapDers.IsMatch($ders) -or $reMatematikDers.IsMatch($ders) -or $reYabanciDers.IsMatch($ders)) -and $reTurkceImza.IsMatch($govde)){ $sebep += 'K2 icerik Turkce dilbilgisi' }
    # K3: Inkilap-olmayan genel kultur dersinde Inkilap imzasi
    if(($reTurkceDers.IsMatch($ders) -or $reMatematikDers.IsMatch($ders) -or $reYabanciDers.IsMatch($ders)) -and $reInkilapImza.IsMatch($govde)){ $sebep += 'K3 icerik Inkilap tarihi' }
    # K4: genel-kultur dersinde muhasebe imzasi
    if($genelKultur -and ($reMuhasebeImza.IsMatch($tum) -or $s.yevmiye)){ $sebep += 'K4 icerik muhasebe' }
    # K5: KGK FY/KY dersinde yevmiye
    if("$($s.sinav)" -eq 'KGK' -and $s.yevmiye -and ($ders -match 'finansal yonetim|kurumsal yonetim')){ $sebep += 'K5 FY/KY etiketli yevmiye sorusu' }
    if($sebep.Count){
      $bulgular.Add([pscustomobject]@{ id=$s.id; sinav=$s.sinav; ders=$s.ders; konu=$s.konu; yayin=[bool]$s.yayin; sebep=($sebep -join ' | ') })
    }
  }
  if($r.Count -lt 500){ break }
  $bas += 500
  Write-Host ("  ... {0} tarandi" -f $taranan)
}
Write-Host ("Taranan: {0} | etiket bulgusu: {1}" -f $taranan, $bulgular.Count)
$bulgular | Group-Object sinav | ForEach-Object { Write-Host ("  {0}: {1}" -f $_.Name, $_.Count) }

$cekilen=0
if($yaz){
  $HW = $H + @{ Prefer='return=minimal'; 'Content-Type'='application/json' }
  foreach($b in $bulgular){
    $gov = ConvertTo-Json -InputObject @{ yayin=$false; yayin_notu=('ders-etiket denetimi 06.08: ' + $b.sebep + ' - etiket duzeltilip hakemden gececek') } -Compress
    try { Invoke-RestMethod -Method Patch -Uri ("$U`?id=eq." + $b.id) -Headers $HW -Body ([Text.Encoding]::UTF8.GetBytes($gov)) -TimeoutSec 60 | Out-Null; $cekilen++ } catch {}
  }
  Write-Host ("Cekilen: {0}" -f $cekilen)
}

RaporYaz ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum=$(if($yaz){'YAZILDI'}else{'OLCUM'})
  taranan=$taranan; bulgu=$bulgular.Count; cekilen=$cekilen
  bulgular=@($bulgular | Select-Object -First 500)
})
Write-Host 'Bitti.'
