# ============================================================================
#  TLS TESHIS - bir adrese PowerShell'den hangi TLS ayariyla baglanilabiliyor?
#  14.08: Actions'ta KIK'e curl http=200 aliyor, openssl el sikismasi temiz, ama
#  Invoke-WebRequest "The SSL connection could not be established" diyordu.
#  Bu betik ayarlari TEK TEK dener ve hangisinin tuttugunu yazar - tahmin yok.
#  Hicbir sey yazmaz, yalniz olcer.
# ============================================================================
param([string]$Adres = "https://ekap.kik.gov.tr/ekap/ilan/bultenindirme.aspx")

Write-Host ("PowerShell {0} · {1}" -f $PSVersionTable.PSVersion, $PSVersionTable.Platform)
Write-Host ("Adres: {0}`n" -f $Adres)
$ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) MevzuatRadar-TlsTeshis/1.0"

$adaylar = @(
  @{ ad = 'varsayilan (dokunma)'; kur = { } },
  @{ ad = 'SystemDefault';        kur = { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::SystemDefault } },
  @{ ad = 'Tls12 (eski ayarimiz)';kur = { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } },
  @{ ad = 'Tls12 + Tls13';        kur = { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]'Tls12,Tls13' } }
)
foreach($a in $adaylar){
  try { & $a.kur } catch { Write-Host ("{0,-22} : AYAR KURULAMADI - {1}" -f $a.ad, $_.Exception.Message); continue }
  try {
    $r = Invoke-WebRequest -Uri $Adres -Headers @{ "User-Agent" = $ua } -UseBasicParsing -TimeoutSec 40
    Write-Host ("{0,-22} : HTTP {1} · {2:N0} bayt  <-- CALISIYOR" -f $a.ad, $r.StatusCode, $r.RawContentLength)
  } catch {
    $ic = ""
    if($_.Exception.InnerException){ $ic = " || ic: " + $_.Exception.InnerException.Message }
    Write-Host ("{0,-22} : HATA - {1}{2}" -f $a.ad, $_.Exception.Message, $ic)
  }
}
