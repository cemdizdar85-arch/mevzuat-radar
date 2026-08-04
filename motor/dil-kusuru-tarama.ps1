# ============================================================================
#  DIL KUSURU TARAMASI (04.08.2026) — 0 USD, API YOK, YAZMA YOK
#
#  Cem'in bu gece taslakta yakaladigi UC dil kusurunu TEK kosuda olcer.
#  Amac: tek ornekten genelleme yapmamak (bu gecenin en pahali dersi).
#
#  1) UYDURMA SIKISTIRILMIS TERIM
#     Cem: "'cok donemli giderler' derken... bir neden varsa onlari yazmali."
#     Cem CUMLEYI "cok ONEMLI" diye okudu - bir SMMM yanlis okuyorsa aday
#     kesin yanlis okur. "Cok donemli gider" standart muhasebe Turkcesi
#     DEGILDIR; dogrusu "birden fazla donemi ilgilendiren giderler" ya da
#     dogrudan "pesin odenen giderler". Model resmi terim yerine kendi
#     kisaltmasini uyduruyor.
#
#  2) ESKI TERIM KEHRIBAR KARTTA
#     Acilis olcumu "genel imal" kalibini AKILDA KALSIN bolumunde 396 kez
#     buldu. Eski terim her yerde kotudur ama EZBERLENECEK kartta olmasi
#     en kotusudur.
#
#  3) TEKRARLAYAN SENARYO ISIMLERI
#     Mehmet Bey 276, Yildirim Makina 216, Mehmet Yilmaz 173, Yildirim
#     Mobilya 134... "Yildirim"in uc varyanti var - model favori isme
#     takilmis. Art arda ayni ismi goren aday makine izi sezer.
#
#  CIKTI: veri/dil-kusuru-raporu.json  ·  ENV: SUPABASE_SERVICE_KEY
# ============================================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$raporYol = Join-Path $kok 'veri/dil-kusuru-raporu.json'

function RaporYaz($n){
  $j = ConvertTo-Json -InputObject $n -Depth 6
  if($j.Length -gt 40960){ $j = ConvertTo-Json -Depth 2 -InputObject @{ durum='KIRMIZI - rapor sismis'; boyut=$j.Length } }
  Set-Content -LiteralPath $raporYol -Value $j -Encoding UTF8 -NoNewline
}
trap {
  $g=''; if($_.ErrorDetails -and $_.ErrorDetails.Message){ $g=$_.ErrorDetails.Message }
  RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'
    hata="$($_.Exception.Message)"; sunucu=$g; satir=$_.InvocationInfo.ScriptLineNumber })
  Write-Host ("HATA (satir {0}): {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message); exit 1
}
if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host "SUPABASE_SERVICE_KEY yok."; exit 0 }
$U  = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu"
$SB = @{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization="Bearer $($env:SUPABASE_SERVICE_KEY)" }
function CekListe([string]$uri){
  $h = Invoke-WebRequest -Uri $uri -Headers $SB -UseBasicParsing -TimeoutSec 180
  $m = if($h.RawContentStream){ [Text.Encoding]::UTF8.GetString($h.RawContentStream.ToArray()) } else { "$($h.Content)" }
  return @($m | ConvertFrom-Json)
}
$kasa = New-Object System.Collections.Generic.List[object]
for($o=0; $o -lt 60000; $o+=1000){
  $r = CekListe "$U`?select=id,ders,soru,dogru,aciklama,hap&order=id&limit=1000&offset=$o"
  if($r.Count -eq 0){ break }
  foreach($x in $r){ if($null -ne $x){ $kasa.Add($x) } }
  if($r.Count -lt 1000){ break }
}
Write-Host ("Kasa: {0} soru" -f $kasa.Count)

# --- 1) UYDURMA SIKISTIRILMIS TERIMLER (Cem'in "cok donemli" bulgusu) ---
#     Her biri: desen + dogrusu. Yalniz OLCULUR, degistirilmez.
$UYDURMA = @(
  @{ ad='cok donemli gider';       desen='(?i)çok\s+dönemli';                         dogrusu='birden fazla dönemi ilgilendiren / peşin ödenen' }
  @{ ad='cok yilli gider';         desen='(?i)çok\s+y[ıi]ll[ıi]\s+gider';             dogrusu='gelecek yıllara ait giderler' }
  @{ ad='donemsel gider';          desen='(?i)dönemsel\s+gider';                      dogrusu='döneme ait gider' }
  @{ ad='ileri donemli';           desen='(?i)ileri\s+dönemli';                       dogrusu='gelecek dönemlere ait' }
  @{ ad='pesinli gider';           desen='(?i)pe[şs]inli\s+gider';                    dogrusu='peşin ödenen gider' }
  @{ ad='kismi donemli';           desen='(?i)k[ıi]smi\s+dönemli';                    dogrusu='dönemin bir kısmına ait' }
  @{ ad='coklu donem';             desen='(?i)çoklu\s+dönem';                         dogrusu='birden fazla dönem' }
  @{ ad='gider yazimi (tek kelime)'; desen='(?i)giderle[şs]tirme\s+i[şs]lemi';        dogrusu='gider kaydı' }
)
# --- 2) ESKI TERIMLER (ozellikle hap/kehribar kartta) ---
$ESKI = @(
  @{ ad='genel imal gideri'; desen='(?i)genel\s+imal';        dogrusu='genel üretim giderleri (THP 730)' }
  @{ ad='imal edilen emtia'; desen='(?i)imal\s+edilen\s+emtia'; dogrusu='üretilen mamul' }
  @{ ad='mubayaa';           desen='(?i)mubayaa';             dogrusu='satın alma' }
  @{ ad='mezkur';            desen='(?i)mezk[uû]r';           dogrusu='anılan / söz konusu' }
  @{ ad='isbu';              desen='(?i)\bi[şs]bu\b';         dogrusu='bu' }
)
# --- 3) SENARYO ISIMLERI (kisi + sirket) ---
$reKisi   = [regex]'(?i)\b([A-ZÇĞİÖŞÜ][a-zçğıöşü]+)\s+(Bey|Han[ıi]m)\b'
$reSirket = [regex]'(?i)\b([A-ZÇĞİÖŞÜ][a-zçğıöşü]+)\s+(Makina|Makine|Mobilya|G[ıi]da|Tekstil|Sanayi|Ticaret|In[şs]aat|Nakliyat|Elektronik)\b'

$uydurmaSay = @{}; $uydurmaOrnek = @{}
$eskiSay = @{};    $eskiHapSay = @{}
$kisiSay = @{};    $sirketSay = @{}
foreach($u in $UYDURMA){ $uydurmaSay[$u.ad] = 0; $uydurmaOrnek[$u.ad] = New-Object System.Collections.Generic.List[string] }
foreach($e in $ESKI){ $eskiSay[$e.ad] = 0; $eskiHapSay[$e.ad] = 0 }

$hapliSoru = 0
foreach($s in $kasa){
  $dh = "$($s.dogru)".Trim().ToUpper()
  $ac = ''
  try { if($s.aciklama){ foreach($p in $s.aciklama.PSObject.Properties){ $ac += ' ' + "$($p.Value)" } } } catch {}
  $hap = "$($s.hap)"
  $tum = "$($s.soru) $ac $hap"
  if($hap.Trim().Length -gt 3){ $hapliSoru++ }

  foreach($u in $UYDURMA){
    if([regex]::IsMatch($tum, $u.desen)){
      $uydurmaSay[$u.ad]++
      if($uydurmaOrnek[$u.ad].Count -lt 5){ $uydurmaOrnek[$u.ad].Add("$($s.id)") }
    }
  }
  foreach($e in $ESKI){
    if([regex]::IsMatch($tum, $e.desen)){ $eskiSay[$e.ad]++ }
    if($hap.Trim().Length -gt 3 -and [regex]::IsMatch($hap, $e.desen)){ $eskiHapSay[$e.ad]++ }
  }
  foreach($m in $reKisi.Matches("$($s.soru)")){
    $ad = $m.Groups[1].Value
    if(-not $kisiSay.ContainsKey($ad)){ $kisiSay[$ad]=0 }; $kisiSay[$ad]++
  }
  foreach($m in $reSirket.Matches("$($s.soru)")){
    $ad = $m.Groups[1].Value
    if(-not $sirketSay.ContainsKey($ad)){ $sirketSay[$ad]=0 }; $sirketSay[$ad]++
  }
}

function Liste($tablo, $adet){
  $l = New-Object System.Collections.Generic.List[object]
  foreach($k in ($tablo.Keys | Sort-Object { -$tablo[$_] } | Select-Object -First $adet)){
    if($tablo[$k] -le 0){ continue }
    $l.Add([ordered]@{ ad=$k; soru=$tablo[$k]; yuzde=[Math]::Round(100.0*$tablo[$k]/$kasa.Count,2) })
  }
  return $l.ToArray()
}
$uydurmaRapor = New-Object System.Collections.Generic.List[object]
foreach($u in $UYDURMA){
  if($uydurmaSay[$u.ad] -le 0){ continue }
  $uydurmaRapor.Add([ordered]@{ terim=$u.ad; soru=$uydurmaSay[$u.ad]; dogrusu=$u.dogrusu; ornek_id=@($uydurmaOrnek[$u.ad]) })
}
$eskiRapor = New-Object System.Collections.Generic.List[object]
foreach($e in $ESKI){
  if($eskiSay[$e.ad] -le 0 -and $eskiHapSay[$e.ad] -le 0){ continue }
  $eskiRapor.Add([ordered]@{ terim=$e.ad; toplam_soru=$eskiSay[$e.ad]; KEHRIBAR_KARTTA=$eskiHapSay[$e.ad]; dogrusu=$e.dogrusu })
}
$kisiTop = ($kisiSay.Values | Measure-Object -Sum).Sum
$sirketTop = ($sirketSay.Values | Measure-Object -Sum).Sum

RaporYaz ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='TAMAM'; mod='OLCUM (0 USD, yazma yok)'
  kasa=$kasa.Count; kehribar_karti_olan=$hapliSoru
  bir_uydurma_terim=$uydurmaRapor.ToArray()
  iki_eski_terim=$eskiRapor.ToArray()
  uc_senaryo_isimleri=[ordered]@{
    farkli_kisi_adi=$kisiSay.Count; toplam_kisi_gecis=$kisiTop
    farkli_sirket_adi=$sirketSay.Count; toplam_sirket_gecis=$sirketTop
    en_sik_kisi=(Liste $kisiSay 15)
    en_sik_sirket=(Liste $sirketSay 15)
  }
  not='Yalniz OLCUM - kasaya dokunulmadi. "KEHRIBAR_KARTTA" sutunu onemlidir: eski terim her yerde kotudur ama ogrencinin EZBERLEYECEGI kartta olmasi en kotusudur.'
})
Write-Host "`n=== DIL KUSURU TARAMASI ==="
Write-Host "  1) UYDURMA TERIM:"
foreach($r in $uydurmaRapor){ Write-Host ("     {0,-26} {1,5} soru  -> dogrusu: {2}" -f $r.terim, $r.soru, $r.dogrusu) }
Write-Host "  2) ESKI TERIM (toplam / kehribar kartta):"
foreach($r in $eskiRapor){ Write-Host ("     {0,-26} {1,5} / {2,4}  -> dogrusu: {3}" -f $r.terim, $r.toplam_soru, $r.KEHRIBAR_KARTTA, $r.dogrusu) }
Write-Host ("  3) SENARYO ADI: {0} farkli kisi / {1} farkli sirket" -f $kisiSay.Count, $sirketSay.Count)
