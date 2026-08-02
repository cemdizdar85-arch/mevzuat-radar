# ============================================================================
#  DAYANAK KAPSAM OLCUMU — kasa capinda "kaynak cozuluyor mu?" (03.08.2026)
#
#  NEDEN: Ilk 40'lik denetimde 40 sorunun 39'unda dayanak cozulemiyordu;
#  Cem 03.08: "EN BUYUGU bu - yapilacak listesinde var deme, olc." B7 tanisi
#  12 bilinen vakada kosucu=yerel esitligini kanitladi; bu robot ise KASANIN
#  TAMAMINDA gercek orani cikarir. Hakem partisi oncesi kapsam fotografi.
#
#  NE YAPAR: tum sorularin kaynak alanini ceker, BENZERSIZ kaynaklari
#  KaynakCoz'dan gecirir (onbellek sayesinde sorgu = benzersiz kaynak sayisi),
#  durum dagilimini ve cozulmeyen kaynaklarin EN SIK 40'ini raporlar.
#  PARA HARCAMAZ. ENV: SUPABASE_SERVICE_KEY.
#  Cikti: veri/dayanak-kapsam.json
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$enc = New-Object Text.UTF8Encoding($false)
$cikti = Join-Path $kok 'veri/dayanak-kapsam.json'
function Yaz($n){ [IO.File]::WriteAllText($cikti, (ConvertTo-Json -InputObject $n -Depth 6), $enc) }
trap {
  Yaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'; hata="$($_.Exception.Message)"; satir=$_.InvocationInfo.ScriptLineNumber })
  Write-Host ("HATA (satir {0}): {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message); exit 1
}
$SERVIS = "$env:SUPABASE_SERVICE_KEY"
if([string]::IsNullOrWhiteSpace($SERVIS)){
  Yaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='ATLANDI'; not='SUPABASE_SERVICE_KEY yok' })
  Write-Host 'SUPABASE_SERVICE_KEY yok - atlandi.'; exit 0
}
$KASA_BASLIK = @{ apikey = $SERVIS; Authorization = "Bearer $SERVIS" }
$KASA_TABAN = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu'

# madde-coz kutuphanesi (kendi $H basligini kendisi kurar - degisken ezme yok)
. (Join-Path $here 'madde-coz.ps1') -kutuphane

# --- tum kaynak + konu ciftlerini cek
$kaynakSayim = @{}   # "kaynak|konu" -> soru sayisi (konu teori notu esleme icin gerekli)
$toplamSoru = 0
$offset = 0; $sayfa = 1000
while($true){
  $istekUri = "${KASA_TABAN}?select=kaynak,konu&order=id&limit=$sayfa&offset=$offset"
  $hw = Invoke-WebRequest -UseBasicParsing -Uri $istekUri -Headers $KASA_BASLIK -TimeoutSec 180
  $gv = if($hw.Content -is [byte[]]){ [Text.Encoding]::UTF8.GetString($hw.Content) } else { "$($hw.Content)" }
  $parti = @(); foreach($x in (ConvertFrom-Json $gv)){ $parti += $x }
  if(-not $parti.Count){ break }
  foreach($s in $parti){
    $toplamSoru++
    $anah = "$($s.kaynak)|||$($s.konu)"
    $kaynakSayim[$anah] = 1 + [int]$kaynakSayim[$anah]
  }
  if($parti.Count -lt $sayfa){ break }
  $offset += $sayfa
}
Write-Host ("Soru: {0} | benzersiz kaynak+konu: {1}" -f $toplamSoru, $kaynakSayim.Count)

# --- benzersizleri coz (onbellek madde-coz icinde)
$durumSoru = @{}     # durum -> soru sayisi
$cozulmeyen = @{}    # kaynak -> soru sayisi (cozulmeyenler)
$i = 0
foreach($anah in $kaynakSayim.Keys){
  $i++
  if($i % 250 -eq 0){ Write-Host ("  ...{0}/{1}" -f $i, $kaynakSayim.Count) }
  $parcalar = $anah -split '\|\|\|', 2
  $kk = $parcalar[0]; $konu = $parcalar[1]
  $adet = [int]$kaynakSayim[$anah]
  $d = 'EXCEPTION'
  try { $c = KaynakCoz $kk $konu; $d = "$($c.durum)"; if(-not $c -or -not $c.metin -or "$($c.metin)".Trim().Length -lt 40){ if($d -like 'cozuldu*'){ $d = 'cozuldu-ama-metin-kisa' } } } catch { $d = 'EXCEPTION' }
  $durumSoru[$d] = $adet + [int]$durumSoru[$d]
  if($d -notlike 'cozuldu*'){ $cozulmeyen[$kk] = $adet + [int]$cozulmeyen[$kk] }
}
$cozulenSoru = 0
foreach($k in $durumSoru.Keys){ if($k -like 'cozuldu*' -and $k -ne 'cozuldu-ama-metin-kisa'){ $cozulenSoru += [int]$durumSoru[$k] } }
$oran = if($toplamSoru){ [math]::Round(100.0 * $cozulenSoru / $toplamSoru, 1) } else { 0 }

$enSik = @($cozulmeyen.GetEnumerator() | Sort-Object { -[int]$_.Value } | Select-Object -First 40 | ForEach-Object { [ordered]@{ kaynak = $_.Key; soru = [int]$_.Value } })

Yaz ([ordered]@{
  tarih = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  durum = 'TAMAM'
  toplam_soru = $toplamSoru
  benzersiz_kaynak = $kaynakSayim.Count
  cozulen_soru = $cozulenSoru
  cozum_orani_yuzde = $oran
  durum_dagilimi = $durumSoru
  cozulmeyen_en_sik_40 = $enSik
})
Write-Host ("DAYANAK KAPSAM: {0}/{1} soru cozuluyor (%{2})" -f $cozulenSoru, $toplamSoru, $oran)
