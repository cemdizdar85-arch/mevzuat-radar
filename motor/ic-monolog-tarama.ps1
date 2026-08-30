# ============================================================================
#  IC MONOLOG TARAMASI - 25.08.2026 gece (50'lik orneklem dersinden)
#
#  NEDEN: orneklem idx12 (VUK 283) sorusunda uretici modelin COKEN ic monologu
#  ("Dur, hesap hatasi var... siklari tersine muhendislik yapmaliyim...
#   O halde A dogru toplam...") ACIKLAMA olarak birebir YAYINLANMISTI.
#  Kapilarin hicbiri bu sinifi aramiyordu. Bu betik tum kasada uretici
#  ic-konusma kaliplarini tarar.
#
#  OLCUM MODU - kasaya YAZMAZ, para HARCAMAZ. Rapor: veri/ic-monolog-raporu.json
#  (rapora yalniz id + alan + yakalanan kalip yazilir; soru metni SIZMAZ).
# ============================================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
if(-not $env:SUPABASE_SERVICE_KEY){ $env:SUPABASE_SERVICE_KEY = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
$KEY = $env:SUPABASE_SERVICE_KEY
if([string]::IsNullOrWhiteSpace($KEY)){ Write-Host 'SUPABASE_SERVICE_KEY yok - cikildi.'; exit 0 }
$URI = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu'
$HDR = @{ apikey=$KEY; Authorization=("Bearer "+$KEY) }

# Kaliplar: uretici modelin kendi kendine konusmasi / cozum surecini itiraf etmesi.
# Ogrenciye donuk mesru cumleleri yakalamamak icin dar tutuldu (oz-sinav asagida).
$kaliplar = @(
  'tersine m[uü]hendislik',
  '(?i)\bDur,\s',
  '(?i)hesap hatas[iı] (var|yapt[iı]m)',
  '(?i)yeniden hesaplamal[iı]y[iı]m',
  '(?i)\bkontrol edeyim\b',
  '(?i)\bo h[aâ]lde\b.{0,50}(do[gğ]ru olmal[iı]|cevap olmal[iı])',
  '(?i)s[iı]klar[iı] (tersine|geri) ',
  '(?i)\bwait\b|\bhmm+\b',
  '(?i)soruyu (yazarken|kurgularken)',
  '(?i)(kabul ediyorum|varsayal[iı]m) ki cevap'
)
$reList = $kaliplar | ForEach-Object { [regex]::new($_) }

# --- OZ-SINAV: bilinen pozitif ve negatif ornekler dogru siniflanmali ---
$pozitif = @(
  'Dur, hesap hatasi var. Siklari tersine muhendislik yapmaliyim. O halde A dogru toplam olmali.',
  'Rakam tutmadi, yeniden hesaplamaliyim.'
)
$negatif = @(
  'Kidem tazminati karsiligi 472 hesabinda izlenir.',
  'Dogrusu: senet lehtara iade edilir. TUZAK: protesto suresi.',
  'Duran varliklar amortismana tabidir; kontrol gucu onemlidir.'
)
foreach($p in $pozitif){ $vur=$false; foreach($re in $reList){ if($re.IsMatch($p)){ $vur=$true; break } }; if(-not $vur){ Write-Host "OZ-SINAV KIRMIZI: pozitif ornek kacti: $p"; exit 1 } }
foreach($n in $negatif){ foreach($re in $reList){ if($re.IsMatch($n)){ Write-Host "OZ-SINAV KIRMIZI: negatif ornek yakalandi: $n / kalip: $($re)"; exit 1 } } }
Write-Host 'oz-sinav: 2 pozitif + 3 negatif GECTI'

$bulgular = New-Object System.Collections.Generic.List[object]
$taranan = 0; $bas = 0
while($true){
  $r = @(Invoke-RestMethod -Uri "$URI`?select=id,ders,soru,siklar,aciklama,hap&order=id&limit=500&offset=$bas" -Headers $HDR -TimeoutSec 300 | ForEach-Object { $_ })
  if($r.Count -eq 0){ break }
  foreach($s in $r){
    if($null -eq $s){ continue }
    $taranan++
    $alanlar = [ordered]@{ soru="$($s.soru)"; hap="$($s.hap)" }
    foreach($hf in 'A','B','C','D','E'){
      try { if($s.aciklama -and $s.aciklama.PSObject.Properties[$hf]){ $alanlar["aciklama$hf"] = "$($s.aciklama.$hf)" } } catch {}
      try { if($s.siklar -and $s.siklar.PSObject.Properties[$hf]){ $alanlar["sik$hf"] = "$($s.siklar.$hf)" } } catch {}
    }
    foreach($ad in @($alanlar.Keys)){
      $t = $alanlar[$ad]
      if([string]::IsNullOrWhiteSpace($t)){ continue }
      foreach($re in $reList){
        $m = $re.Match($t)
        if($m.Success){
          $bulgular.Add([pscustomobject]@{ id=$s.id; ders=$s.ders; alan=$ad; kalip=$re.ToString(); kesit=$m.Value })
          break
        }
      }
    }
  }
  $bas += 500
  if($taranan % 5000 -lt 500){ Write-Host "  ...$taranan" }
}

$idler = @($bulgular | Select-Object -ExpandProperty id -Unique)
$rapor = [ordered]@{
  tarih   = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  taranan = $taranan
  bulgu   = $bulgular.Count
  soru    = $idler.Count
  idler   = $idler
  ornekler = @($bulgular | Select-Object -First 40)
  not     = 'OLCUM - kasaya yazilmadi. Bu idler yayina-al kara listesine "IC-MONOLOG" olarak baglanmali (yayin-havuzu-olcum.ps1).'
}
$yol = Join-Path $kok 'veri\ic-monolog-raporu.json'
[IO.File]::WriteAllText($yol, (ConvertTo-Json -InputObject $rapor -Depth 5), (New-Object Text.UTF8Encoding($false)))
Write-Host ''
Write-Host '======== IC MONOLOG TARAMASI ========'
Write-Host ("  taranan : {0}" -f $taranan)
Write-Host ("  bulgu   : {0}  ({1} soruda)" -f $bulgular.Count, $idler.Count)
Write-Host ("  rapor   : veri/ic-monolog-raporu.json")
