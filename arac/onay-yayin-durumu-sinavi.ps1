# ============================================================================
#  ONAY YAYIN KAPISI SINIFLAMA - ÖZ-SINAV + MUTASYON (22.10.2026)
#  Ağ/ambar yok; arac/onay-yayin-durumu.ps1 işlevini sahte kümelerle koşar.
#  Vaka 3 gerçek olaydır: smmm-4k-a-fmuh-zor-r7/kp-03 (21-22.10 kasa yayını iki gün KIRMIZI).
#  Mutasyonlar (ONAY_DURUM_MUTASYON): sira-eski · sart-yok · ret-yok → her birinde sınav KIRMIZI düşmeli.
# ============================================================================
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'onay-yayin-durumu.ps1')

function Kume([string[]]$a) { $h = @{}; foreach ($x in $a) { if ($x) { $h[$x] = 1 } }; return $h }
$secim = Kume @('e|yayinda')
$ikiz = Kume @('e|ikiz')
$sart = Kume @('e|sart-kor')
$adayAn = Kume @('e|yayinda', 'e|ikiz', 'e|bilinmez')
$ret = @{ 'e|sart-kor' = 'KAPI-KOR KOR-CELISKI'; 'e|elle' = 'ELLE onarim'; 'e|ret' = 'KAPI-SIM SIM-YANLIS' }

$vakalar = @(
  @('yayında olan', 'e|yayinda', 'yayında', $false),
  @('ikizden düşen', 'e|ikiz', 'ikiz', $false),
  @('21.10 olayı: yayın şartından düştü + eski KAPI-KOR kütük kaydı', 'e|sart-kor', 'yayın şartı', $false),
  @('elle ret listesinde', 'e|elle', 'elle ret', $false),
  @('şart geçti ama ret kütüğü durdurdu', 'e|ret', 'ONAYA RAĞMEN RET KÜTÜĞÜ', $true),
  @('hiçbir kümede yok, aday değil', 'e|yok', 'yayın şartı', $false),
  @('aday ama seçilmemiş, nedeni yok', 'e|bilinmez', 'BİLİNMİYOR', $true)
)

function Kos {
  $ok = 0
  foreach ($v in $vakalar) {
    $d = OnayYayinDurumu $v[1] $secim $ikiz $sart $ret $adayAn
    $g = ($d -eq $v[2]) -and ((OnayYayinKirmiziMi $d) -eq $v[3])
    if ($g) { $ok++ }
    if (-not $env:ONAY_DURUM_MUTASYON) { Write-Host ("  {0} {1} -> {2}" -f $(if ($g) { '✓' } else { '✗' }), $v[0], $d) }
  }
  return $ok
}

$env:ONAY_DURUM_MUTASYON = ''
$ok = Kos
$tamam = ($ok -eq $vakalar.Count)
Write-Host ("Vakalar: {0}/{1}" -f $ok, $vakalar.Count)

$mutOk = 0; $mutlar = @('sira-eski', 'sart-yok', 'ret-yok')
foreach ($m in $mutlar) {
  $env:ONAY_DURUM_MUTASYON = $m
  $mo = Kos
  $dustu = ($mo -lt $vakalar.Count)
  if ($dustu) { $mutOk++ }
  Write-Host ("  mutasyon {0}: {1}/{2} -> {3}" -f $m, $mo, $vakalar.Count, $(if ($dustu) { 'KIRMIZI (beklenen)' } else { 'YEŞİL - sınav kör!' }))
}
$env:ONAY_DURUM_MUTASYON = ''
Write-Host ("Mutasyon: {0}/{1} yakalandı" -f $mutOk, $mutlar.Count)

if ($tamam -and $mutOk -eq $mutlar.Count) { Write-Host 'ONAY YAYIN KAPISI ÖZ-SINAVI YEŞİL'; exit 0 }
Write-Host 'ONAY YAYIN KAPISI ÖZ-SINAVI KIRMIZI'; exit 1
