# ============================================================================
#  GECIKME ZAMMI HASAT — GiB "Gecikme Zammi Orani" PDF -> veri/gecikme-zammi.json
#  Cross-platform (pdftotext / poppler-utils). En GUNCEL tarihli orani secer.
#  DETERMINISTIK: en yuksek tarihli "DD/MM/YYYY ... % X,Y" satirini alir; oran
#  0-20 araligi disindaysa YAZMAZ (exit 2 -> robot 'elle bak' alert'ine duser).
#  Kullanim: gecikme-hasat.ps1 <pdfYolu>
# ============================================================================
param([Parameter(Mandatory=$true)][string]$Pdf)
$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$cikti = Join-Path $kok "veri\gecikme-zammi.json"

# --- PDF -> metin (pdftotext; yoksa hata) ---
$txt = $null
try { $txt = (& pdftotext -layout $Pdf - 2>$null) -join " " } catch {}
if([string]::IsNullOrWhiteSpace($txt)){
  try { $txt = (& pdftotext $Pdf - 2>$null) -join " " } catch {}
}
if([string]::IsNullOrWhiteSpace($txt)){ Write-Host "HATA: pdftotext metin uretemedi"; exit 2 }
$t = $txt -replace '\s+',' '

# --- en guncel tarihli oran ---
$ms = [regex]::Matches($t,'(\d{1,2})/(\d{1,2})/(\d{4}) tarihinden itibaren Her Ay için % (\d+),(\d+)')
if($ms.Count -eq 0){ Write-Host "HATA: oran satiri bulunamadi"; exit 2 }
$en=$null; $enSkor=-1
foreach($m in $ms){ $g=$m.Groups; $skor=[int]$g[3].Value*10000+[int]$g[2].Value*100+[int]$g[1].Value
  if($skor -gt $enSkor){ $enSkor=$skor; $en=$m } }
$g=$en.Groups
$oran=[double]("$($g[4].Value).$($g[5].Value)")
$tarih="{0:D2}.{1:D2}.{2}" -f [int]$g[1].Value,[int]$g[2].Value,$g[3].Value

# --- DOGRULAMA: makul aralik disindaysa yazma ---
if($oran -le 0 -or $oran -ge 20){ Write-Host "HATA: oran makul degil ($oran) - yazilmadi"; exit 2 }

# --- JSON (degismediyse dokunma) ---
$eski = $null
if(Test-Path $cikti){ try { $eski = Get-Content $cikti -Raw -Encoding UTF8 | ConvertFrom-Json } catch {} }
if($eski -and [double]$eski.aylik -eq $oran -and "$($eski.tarih)" -eq $tarih){ Write-Host "AYNI: gecikme zammi %$oran ($tarih) - degisiklik yok"; exit 0 }

$obj = [ordered]@{ aylik=$oran; tarih=$tarih;
  kaynak="GİB — Gecikme Zammı Oranı (cdn.gib.gov.tr, 6183 s. Kanun m.51)";
  not="Aylık gecikme zammı = gecikme faizi (VUK m.112) = pişmanlık zammı (m.371) oranı. Robot GİB PDF'inden otomatik günceller." }
($obj | ConvertTo-Json -Compress) | Out-File $cikti -Encoding utf8
Write-Host "GUNCELLENDI: gecikme zammi -> %$oran ($tarih)"
exit 0
