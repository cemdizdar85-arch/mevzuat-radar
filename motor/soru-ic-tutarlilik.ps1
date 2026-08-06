# ============================================================================
#  SORU IC-TUTARLILIK DENETCISI — 06.08.2026 (Cem: "cevap kontrolu, ayni
#  cevaplar; siklarda ayni sorular olmasin - A sik ve C sik ayni gibi;
#  aklima gelmeyen baska ne varsa bir kontrol ayarla, sorulari basmadan")
#
#  SORU-ICI kurallar (her biri tek basina soruyu sakatlar, AI'siz olculur):
#   S1 sik mukerrer      : iki sik normalize edilince ayni metin/deger
#   S2 cevap sizintisi   : dogru sikkin metni (>=12 krk) soru kokunde aynen
#   S3 dogru harf gecersiz: dogru A-E disi ya da isaretli sik bos
#   S4 sik eksik/bos     : 5 siktan biri bos ya da 2 karakterden kisa
#   S5 dogru aciklamasiz : isaretli dogru sikkin aciklamasi yok/cok kisa
#   S6 hepsi/hicbiri     : 'yukaridakilerin hepsi/hicbiri' siki (zayif pratik)
#  KASA kurallari:
#   K1 tam-metin mukerrer: ayni sorunun kasada birden fazla kopyasi (imza)
#   K2 cevap-harf yigilmasi: sinav bazinda dogru cevap dagilimi (bilgi;
#      bir harf %35'i asarsa KIRMIZI isaret - beklenen ~%20)
#   K3 dogru-sik-en-uzun : dogru sik oturumlarin kacinda en uzun sik
#      (>%45 ise kurnaz ogrenci uzunluktan kokar - bilgi)
#
#  Varsayilan OLCUM; -yaz ile S1-S5 bulgululari yayin=false (hakem kuyrugu).
#  S6/K2/K3 bilgi duzeyi - cekmez, raporlar. Uretim tarafinda S1+S2 ayni
#  mantikla soru-uret-v2 kapisina eklendi (IC-TUTARLILIK KAPISI).
# ============================================================================
param([switch]$yaz)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$raporYol = Join-Path $kok 'veri/ic-tutarlilik-raporu.json'
function RaporYaz($n){ [IO.File]::WriteAllText($raporYol, (ConvertTo-Json -InputObject $n -Depth 6), (New-Object Text.UTF8Encoding($false))) }
trap {
  RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'; hata="$($_.Exception.Message)"; satir=$_.InvocationInfo.ScriptLineNumber })
  Write-Host ("HATA (satir {0}): {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message); exit 1
}

$KEY = $env:SUPABASE_SERVICE_KEY
if(-not $KEY){ Write-Host 'SUPABASE_SERVICE_KEY yok - cikildi.'; exit 0 }
$U = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu'
# DIKKAT: baslik degiskeni $H OLAMAZ - asagida sik dongusu $h kullaniyor ve
# PowerShell degisken adlari buyuk-kucuk harf AYIRMAZ ($h = $H). Ilk kosuda
# ikinci sayfada baslik 'E' stringine donusup patladi (06.08 dersi).
$BASLIKLAR = @{ apikey=$KEY }
if($KEY -like 'eyJ*'){ $BASLIKLAR.Authorization = "Bearer $KEY" }

function SikNorm([string]$t){
  $t = "$t".ToLowerInvariant() -replace '\s+',' '
  $t = $t -replace '[\.\,\;\:\!\?\(\)"]',''
  return $t.Trim()
}
$sha=[Security.Cryptography.SHA256]::Create()
function MetinImza([string]$t){ return ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes(("$t" -replace '\s+',' ').Trim().ToLowerInvariant()))) -replace '-','').Substring(0,24) }
$reHepsiHicbiri = [regex]'(?i)yukar[ıi]dakilerin (hepsi|hi[cç]biri)|hepsi do[gğ]rudur|hi[cç]biri do[gğ]ru de[gğ]il'

$taranan=0
$bulgular = New-Object System.Collections.Generic.List[object]
$bilgiler = New-Object System.Collections.Generic.List[object]
$imzaGrup = @{}            # K1: imza -> id listesi
$harfSayim = @{}           # K2: sinav -> harf -> adet
$uzunToplam=0; $uzunDogru=0  # K3
$bas=0
while($true){
  # PS5.1/7 farki sigortasi: boru diziyi her surumde tek tek acar
  $r = @(Invoke-RestMethod -Uri "$U`?select=id,sinav,ders,soru,siklar,dogru,aciklama,yayin&order=id&limit=500&offset=$bas" -Headers $BASLIKLAR -TimeoutSec 300 | ForEach-Object { $_ })
  if($r.Count -eq 0){ break }
  foreach($s in $r){
    if($null -eq $s){ continue }
    $taranan++
    $sebep = @()
    $harfler = @('A','B','C','D','E')
    $sik = @{}
    foreach($h in $harfler){ $v=''; try { $v = "$($s.siklar.$h)" } catch {}; $sik[$h] = $v }
    $dogru = "$($s.dogru)".Trim()

    # S4 sik eksik/bos
    $bos = @($harfler | Where-Object { $sik[$_].Trim().Length -le 2 })
    if($bos.Count){ $sebep += ('S4 bos/eksik sik: ' + ($bos -join ',')) }
    # S1 sik mukerrer
    $gorulen = @{}
    foreach($h in $harfler){
      $n = SikNorm $sik[$h]
      if($n.Length -lt 2){ continue }
      if($gorulen.ContainsKey($n)){ $sebep += ('S1 ayni sik: ' + $gorulen[$n] + '=' + $h) }
      else { $gorulen[$n] = $h }
    }
    # S3 dogru harf gecersiz
    if($dogru -notin $harfler){ $sebep += ('S3 gecersiz dogru harf: "' + $dogru + '"') }
    elseif($sik[$dogru].Trim().Length -le 2){ $sebep += 'S3 isaretli dogru sik bos' }
    else {
      # S2 cevap sizintisi (yalniz metin siklari; kisa/rakamsal sik hatali alarm verir)
      $dm = SikNorm $sik[$dogru]
      if($dm.Length -ge 12 -and (SikNorm "$($s.soru)").Contains($dm)){ $sebep += 'S2 dogru sik metni soru kokunde geciyor' }
      # S5 dogru aciklamasiz
      $ac=''; try { if($s.aciklama -and $s.aciklama.PSObject.Properties[$dogru]){ $ac = "$($s.aciklama.$dogru)" } } catch {}
      if($ac.Trim().Length -lt 80){ $sebep += 'S5 dogru sikkin aciklamasi yok/kisa' }
      # K2 harf sayimi
      $sv = "$($s.sinav)"
      if(-not $harfSayim.ContainsKey($sv)){ $harfSayim[$sv] = @{A=0;B=0;C=0;D=0;E=0} }
      $harfSayim[$sv][$dogru]++
      # K3 en-uzun
      $enUzun = ($harfler | Sort-Object { $sik[$_].Length } -Descending)[0]
      $uzunToplam++
      if($enUzun -eq $dogru -and $sik[$dogru].Length -gt (($harfler | Where-Object { $_ -ne $dogru } | ForEach-Object { $sik[$_].Length } | Measure-Object -Maximum).Maximum)){ $uzunDogru++ }
    }
    # S6 hepsi/hicbiri (bilgi)
    $hh = @($harfler | Where-Object { $reHepsiHicbiri.IsMatch($sik[$_]) })
    if($hh.Count){ $bilgiler.Add([pscustomobject]@{ id=$s.id; sinav=$s.sinav; tur='S6 hepsi/hicbiri'; sik=($hh -join ',') }) }
    # K1 tam-metin imza
    $im = MetinImza "$($s.soru)"
    if(-not $imzaGrup.ContainsKey($im)){ $imzaGrup[$im] = New-Object System.Collections.Generic.List[string] }
    $imzaGrup[$im].Add("$($s.id)")

    if($sebep.Count){ $bulgular.Add([pscustomobject]@{ id=$s.id; sinav=$s.sinav; ders=$s.ders; yayin=[bool]$s.yayin; sebep=($sebep -join ' | ') }) }
  }
  if($r.Count -lt 500){ break }
  $bas += 500
  Write-Host ("  ... {0} tarandi" -f $taranan)
}

$mukerrer = @($imzaGrup.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 } | ForEach-Object { [pscustomobject]@{ imza=$_.Key; adet=$_.Value.Count; idler=@($_.Value) } })
$harfOzet = @{}
foreach($sv in $harfSayim.Keys){
  $t = ($harfSayim[$sv].Values | Measure-Object -Sum).Sum
  $dag = @{}; $alarm=@()
  foreach($h in 'A','B','C','D','E'){
    $o = if($t){ [math]::Round(100.0*$harfSayim[$sv][$h]/$t,1) } else { 0 }
    $dag[$h] = $o
    if($o -gt 35){ $alarm += ("$h %$o") }
  }
  $harfOzet[$sv] = [ordered]@{ toplam=$t; dagilimYuzde=$dag; yigilmaAlarmi=($alarm -join ', ') }
}
$uzunOran = if($uzunToplam){ [math]::Round(100.0*$uzunDogru/$uzunToplam,1) } else { 0 }

Write-Host ("Taranan: {0} | soru-ici bulgu: {1} | tam-metin mukerrer grubu: {2} | dogru-en-uzun: %{3}" -f $taranan, $bulgular.Count, $mukerrer.Count, $uzunOran)

$cekilen=0
if($yaz){
  $HW = $BASLIKLAR + @{ Prefer='return=minimal'; 'Content-Type'='application/json' }
  foreach($b in $bulgular){
    $gov = ConvertTo-Json -InputObject @{ yayin=$false; yayin_notu=('ic-tutarlilik denetimi 06.08: ' + $b.sebep) } -Compress
    try { Invoke-RestMethod -Method Patch -Uri ("$U`?id=eq." + $b.id) -Headers $HW -Body ([Text.Encoding]::UTF8.GetBytes($gov)) -TimeoutSec 60 | Out-Null; $cekilen++ } catch {}
  }
  Write-Host ("Cekilen: {0}" -f $cekilen)
}

RaporYaz ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum=$(if($yaz){'YAZILDI'}else{'OLCUM'})
  taranan=$taranan; soruIciBulgu=$bulgular.Count; cekilen=$cekilen
  mukerrerGrup=$mukerrer.Count
  dogruEnUzunYuzde=$uzunOran
  cevapHarfDagilimi=$harfOzet
  bulgular=@($bulgular | Select-Object -First 500)
  mukerrerler=@($mukerrer | Select-Object -First 200)
  bilgiler=@($bilgiler | Select-Object -First 200)
})
Write-Host 'Bitti.'
