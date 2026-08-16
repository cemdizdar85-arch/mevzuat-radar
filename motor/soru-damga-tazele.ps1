# ============================================================================
#  SORU DAMGA TAZELEME — eski formulle yazilmis damgalari bugunku formule cevirir
#
#  NEDEN: kasadaki damgalarin buyuk kismi HAM metin uzerinden (Sadelestir
#  uygulanmadan) yazilmis; ambar damgacisi ise Sadelestir'li formul kullaniyor.
#  Iki taraf ayni metni farkli formulle damgaladigi icin nobetci HER soruyu
#  "degismis" saniyor. Tam kasa olcumu: 14.128 soruda metin AYNI, yalniz
#  formul eski.
#
#  DOKUNMA KURALI (dar ve kanitli): SADECE  DamgaHam(bugunku metin) == saklanan
#  damga  olan satirlar. Bu esitlik metnin BUGUN DE AYNI oldugunun kanitidir.
#  Metni degismis satira DOKUNULMAZ - yoksa gercek degisim sinyali silinir.
#
#  Yazilan deger: DamgaSade(bugunku metin). Boylece bundan sonra nobetci ile
#  ayni dili konusur.
#
#  VARSAYILAN OLCUM. Yazmak icin -uygula. Yazma sonrasi GERI OKUMA zorunlu.
#  ENV: SUPABASE_SERVICE_KEY. Rapor: veri/soru-damga-tazeleme.json
# ============================================================================
param([switch]$uygula, [int]$sinir = 0)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$PSDefaultParameterValues['Invoke-WebRequest:UserAgent'] = 'mevzuat-radar-robot/1.0'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
if(-not $env:SUPABASE_SERVICE_KEY){ $env:SUPABASE_SERVICE_KEY = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
$KEY = $env:SUPABASE_SERVICE_KEY
if([string]::IsNullOrWhiteSpace($KEY)){ Write-Host 'SUPABASE_SERVICE_KEY yok - cikildi.'; exit 0 }
$U = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu'
$H = @{ apikey=$KEY; Authorization=("Bearer "+$KEY) }
$raporYol = Join-Path $kok 'veri/soru-damga-tazeleme.json'
function RaporYaz($n){ [IO.File]::WriteAllText($raporYol, (ConvertTo-Json -InputObject $n -Depth 6), (New-Object Text.UTF8Encoding($false))) }
trap {
  RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'; hata="$($_.Exception.Message)"; satir=$_.InvocationInfo.ScriptLineNumber })
  Write-Host ("HATA (satir {0}): {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message); exit 1
}
. (Join-Path $here 'madde-coz.ps1') -kutuphane

function Sadelestir([string]$t){
  $x = "$t".ToLowerInvariant()
  $x = $x -replace '[''‘’"“”]', "'"
  $x = $x -replace '\s+', ' '
  return $x.Trim()
}
function Hash16([string]$t){
  $sha = [Security.Cryptography.SHA256]::Create()
  return ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($t))) -replace '-','').Substring(0,16).ToLowerInvariant()
}
function DamgaSade([string]$t){ return Hash16 (Sadelestir $t) }
function DamgaHam([string]$t){ return Hash16 $t }

Write-Host 'Kasa cekiliyor...'
$kasaSatirlari = New-Object System.Collections.Generic.List[object]
$bas = 0
while($true){
  # Uzun kosuda tek gecici kopma her seyi dusurmesin - uc deneme, artan bekleme.
  $govde = $null
  foreach($deneme in 1..3){
    try {
      $r = Invoke-WebRequest -Uri ("$U`?select=id,kaynak,madde_damga&madde_damga=not.is.null&order=id&limit=1000&offset=$bas") -Headers $H -UseBasicParsing -TimeoutSec 300
      $govde = [Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray())
      break
    } catch {
      if($deneme -eq 3){ throw }
      Write-Host ("  baglanti koptu (offset {0}), {1}. deneme..." -f $bas, ($deneme+1))
      Start-Sleep -Seconds (5 * $deneme)
    }
  }
  $cozulmus = ConvertFrom-Json -InputObject $govde
  $adet = 0
  foreach($satir in $cozulmus){ [void]$kasaSatirlari.Add($satir); $adet++ }
  if($adet -eq 0){ break }
  $bas += 1000
  if($adet -lt 1000){ break }
}
Write-Host ("Damgali soru: {0}" -f $kasaSatirlari.Count)
$parti = $kasaSatirlari.ToArray()
if($sinir -gt 0 -and $sinir -lt $parti.Count){ $parti = $parti[0..($sinir-1)] }

$tazelenecek = New-Object System.Collections.Generic.List[object]
$zatenSade = 0; $dokunulmaz = 0; $cozulemedi = 0; $n = 0
foreach($s in $parti){
  $n++
  if(($n % 2000) -eq 0){ Write-Host ("  ...{0}/{1}" -f $n, $parti.Count) }
  $c = $null
  try { $c = KaynakCoz "$($s.kaynak)" } catch {}
  if(-not $c -or -not $c.metin){ $cozulemedi++; continue }
  $sade = DamgaSade $c.metin
  if($sade -eq "$($s.madde_damga)"){ $zatenSade++; continue }
  if((DamgaHam $c.metin) -eq "$($s.madde_damga)"){
    $tazelenecek.Add([pscustomobject]@{ id="$($s.id)"; yeni=$sade })   # metin AYNI, formul eski
  } else {
    $dokunulmaz++                                                      # metin degismis - DOKUNMA
  }
}
Write-Host ''
Write-Host '======== DAMGA TAZELEME ========'
Write-Host ("  incelenen        : {0}" -f $parti.Count)
Write-Host ("  zaten guncel     : {0}" -f $zatenSade)
Write-Host ("  TAZELENECEK      : {0}   (metin AYNI, formul eski)" -f $tazelenecek.Count)
Write-Host ("  DOKUNULMAZ       : {0}   (metin degismis - sinyal silinmez)" -f $dokunulmaz)
Write-Host ("  cozulemedi       : {0}" -f $cozulemedi)
$toplam = $zatenSade + $tazelenecek.Count + $dokunulmaz + $cozulemedi
Write-Host ("  KOVA TOPLAMI     : {0} / {1}  {2}" -f $toplam, $parti.Count, $(if($toplam -eq $parti.Count){'(tutuyor)'}else{'(TUTMUYOR)'}))

if(-not $uygula){
  RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='OLCUM'; incelenen=$parti.Count
    zaten_guncel=$zatenSade; tazelenecek=$tazelenecek.Count; dokunulmaz=$dokunulmaz; cozulemedi=$cozulemedi
    kova_toplami=$toplam; hesap_tutuyor=($toplam -eq $parti.Count) })
  Write-Host ''
  Write-Host 'OLCUM modu - kasaya hicbir sey yazilmadi. Yazmak icin: -uygula'
  exit 0
}
if($toplam -ne $parti.Count){ Write-Host 'KOVALAR TUTMUYOR - yazma yapilmadi.'; exit 1 }

$curlAd = if($env:OS -match 'Windows'){ 'curl.exe' } else { 'curl' }
$yazildi = 0; $hata = 0; $i = 0
foreach($t in $tazelenecek){
  $i++
  if(($i % 500) -eq 0){ Write-Host ("  yazilan {0}/{1}" -f $i, $tazelenecek.Count) }
  $gov = ConvertTo-Json -Compress -InputObject @{ madde_damga = $t.yeni }
  $tmp = [IO.Path]::GetTempFileName(); [IO.File]::WriteAllText($tmp,$gov,(New-Object Text.UTF8Encoding($false)))
  $kod = & $curlAd -s -o $(if($env:OS -match 'Windows'){'NUL'}else{'/dev/null'}) -w "%{http_code}" -X PATCH -H "apikey: $KEY" -H "Content-Type: application/json" -H "Prefer: return=minimal" -H "User-Agent: mevzuat-radar-robot/1.0" --data-binary "@$tmp" ("$U`?id=eq." + $t.id)
  Remove-Item $tmp -Force -ErrorAction SilentlyContinue
  if("$kod" -eq '204'){ $yazildi++ } else { $hata++ }
  Start-Sleep -Milliseconds 90
}
Write-Host ("YAZILDI: {0} | hata: {1}" -f $yazildi, $hata)

# --- GERI OKUMA (yesil kosu != tam veri): ornekleme degil, HEPSI
$tutmayan = @()
$j = 0
foreach($t in $tazelenecek){
  $j++
  if(($j % 1000) -eq 0){ Write-Host ("  geri okunan {0}/{1}" -f $j, $tazelenecek.Count) }
  $g = Invoke-WebRequest -Uri ("$U`?select=id,madde_damga&id=eq." + $t.id) -Headers $H -UseBasicParsing -TimeoutSec 60
  $gh = [Text.Encoding]::UTF8.GetString($g.RawContentStream.ToArray())
  $o = ConvertFrom-Json -InputObject $gh
  $bulunan = $null; foreach($x in $o){ $bulunan = $x; break }
  if(-not $bulunan -or "$($bulunan.madde_damga)" -ne $t.yeni){ $tutmayan += $t.id }
}
$durum = if($hata -eq 0 -and $tutmayan.Count -eq 0){ 'TAMAM' } else { 'KIRMIZI' }
RaporYaz ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum=$durum; mod='uygula'
  incelenen=$parti.Count; zaten_guncel=$zatenSade; tazelenen=$tazelenecek.Count
  dokunulmaz=$dokunulmaz; cozulemedi=$cozulemedi
  yazildi=$yazildi; yazma_hatasi=$hata
  geri_okuma_tutmayan=$tutmayan.Count; tutmayan_ornek=@($tutmayan | Select-Object -First 20)
})
Write-Host ("GERI OKUMA: tutmayan {0}" -f $tutmayan.Count)
if($durum -eq 'KIRMIZI'){ exit 1 }
Write-Host 'TAMAM.'
