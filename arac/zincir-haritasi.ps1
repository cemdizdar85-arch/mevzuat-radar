# ============================================================================
#  ZINCIR HARITASI — "o an hepsi degissin" icin once BAGIMLILIK bilinmeli
#  (25.08.2026)
#
#  CEM: "bir daha site okunmayan eskide kalmayacak, otomatik, o an hepsi
#  degisen bir sistem kur."
#
#  TESHIS. Bugun olculdu: is akislari birbirinin urettigi veriyi okuyor ama
#  siralari TAKVIMLE kurulmus. Ornek (25.08 gecesi, TR):
#      Kanun Aynasi   04:49 -> 05:15 (madde-degisim.json 55. dakikada yazilir)
#      RG Nobeti      05:05                <-- 40 dk ONCE okuyor
#  Yani nobet DUNUN dosyasini okuyordu. Sebep: GitHub zamanlanmis isleri
#  40-100 dk geciktiriyor ve gecikme HER IS ICIN FARKLI. Takvimle kurulan
#  sira, gecikme degisince BOZULUR ve bunu kimse gormez.
#
#  DOGRU YOL: uretici bitince tuketici koser (on: workflow_run). Bu betik
#  once bagimliligi CIKARIR, sonra hangi ciftlerin hala takvime yaslandigini
#  soyler. Elle bulunan tek vakayi (rg-nobeti) sistematige cevirir.
#
#  YONTEM:
#   1) Her is akisinin CAGIRDIGI betikler bulunur.
#   2) O betiklerin YAZDIGI ve OKUDUGU veri/*.json dosyalari cikarilir.
#   3) "X yazar, Y okur" ciftleri = bagimlilik.
#   4) Y'nin tetiginde `workflow_run` ile X'e bagli mi diye bakilir.
#      Bagli degilse ve ikisi de cron'la kosuyorsa -> SIRA RISKI.
#
#  DURUSTLUK: bu bir metin analizidir. Bir betik dosyayi kosula bagli yazabilir
#  ya da adi degiskenden kurabilir; oyle durumlar KACAR. Bulduklari GERCEK,
#  ama "hepsi" oldugu iddia EDILMEZ.
#
#  KULLANIM: pwsh arac/zincir-haritasi.ps1
#  CIKIS: 0 sira riski yok · 2 risk var (IS LISTESI, kapi degil)
# ============================================================================
$ErrorActionPreference = 'Stop'
$kok = Split-Path -Parent $PSScriptRoot
Set-Location $kok

# --- is akisi -> cagirdigi betikler ---
$isBetik = @{}
$isMetin = @{}
foreach ($w in Get-ChildItem '.github/workflows' -Filter *.yml) {
  $t = Get-Content $w.FullName -Raw -Encoding UTF8
  $isMetin[$w.Name] = $t
  $b = @()
  foreach ($m in [regex]::Matches($t, '(motor|arac)/([A-Za-z0-9_\-\.]+\.(ps1|js))')) { $b += $m.Value }
  $isBetik[$w.Name] = @($b | Select-Object -Unique)
}

# --- betik -> yazdigi / okudugu veri dosyalari ---
$yazar = @{}; $okur = @{}
foreach ($s in (Get-ChildItem 'motor','arac' -Recurse -Include *.ps1,*.js -File)) {
  $rel = ($s.FullName.Replace("$kok\", '') -replace '\\','/')
  $t = Get-Content $s.FullName -Raw -Encoding UTF8
  $y = @(); $o = @()
  foreach ($m in [regex]::Matches($t, "veri/([A-Za-z0-9_\-\.]+\.json)")) {
    $d = "veri/" + $m.Groups[1].Value
    # yazma kalibi bu dosya adinin YAKININDA mi geciyor?
    $pen = [Math]::Max(0, $m.Index - 160)
    $uz  = [Math]::Min(260, $t.Length - $pen)
    $cevre = $t.Substring($pen, $uz)
    if ($cevre -match '(WriteAllText|Set-Content|Out-File|writeFileSync|Export-Csv)') { $y += $d } else { $o += $d }
  }
  $yazar[$rel] = @($y | Select-Object -Unique)
  $okur[$rel]  = @($o | Select-Object -Unique)
}

# --- is akisi duzeyinde yazan/okuyan ---
$isYazar = @{}; $isOkur = @{}
foreach ($n in $isBetik.Keys) {
  $y = @(); $o = @()
  foreach ($b in $isBetik[$n]) { if ($yazar.ContainsKey($b)) { $y += $yazar[$b] }; if ($okur.ContainsKey($b)) { $o += $okur[$b] } }
  $isYazar[$n] = @($y | Select-Object -Unique)
  $isOkur[$n]  = @($o | Select-Object -Unique)
}

function CronVarMi([string]$n) { return ($isMetin[$n] -match '(?m)^\s*schedule:') }

# --- CRON'LARI DAKIKAYA CEVIR (UTC gun ici) ---
# Ilk surum "ikisi de cron -> RISK" diyordu ve DUZELTILMIS cifti bile risk
# sayiyordu; yani kendi kurt masalini anlatiyordu (bugunun ana dersi kendi
# aracima dondu). Artik SIRA gercekten yanlis mi diye BAKAR.
function CronDakikalari([string]$n) {
  $d = @()
  foreach ($m in [regex]::Matches($isMetin[$n], "cron:\s*['""]([^'""]+)['""]")) {
    $p = $m.Groups[1].Value -split '\s+'
    if ($p.Count -ge 2 -and $p[0] -match '^\d+$' -and $p[1] -match '^\d+$') { $d += ([int]$p[1] * 60 + [int]$p[0]) }
  }
  return @($d | Sort-Object)
}
# Uretici ile tuketici arasindaki EN DAR pay (dakika). Gun donusu hesaba katilir:
# uretici 22:00, tuketici 00:13 ise pay 133 dk'dir, -1307 degil.
function EnDarPay([int[]]$ureticiler, [int[]]$tuketiciler) {
  if (-not $ureticiler -or -not $tuketiciler) { return $null }
  $enDar = 99999
  foreach ($t in $tuketiciler) {
    $buTuketiciIcinEnIyi = -99999
    foreach ($u in $ureticiler) {
      $pay = $t - $u
      if ($pay -lt 0) { $pay = $pay + 1440 }   # uretici onceki gun
      if ($pay -gt $buTuketiciIcinEnIyi) { }
      # tuketiciden ONCE kosan EN YAKIN uretici pay'i belirler
      if ($pay -lt $enDar) { $enDar = $pay }
    }
  }
  return $enDar
}
# GitHub gecikmesi 13-96 dk arasinda olculdu (25.08). Iki isin gecikmesi farkli
# olabildigi icin guvenli pay bu farkin uzerinde olmali: 120 dk secildi.
$GUVENLI_PAY_DK = 120
function WorkflowRunKaynagi([string]$n) {
  $m = [regex]::Match($isMetin[$n], 'workflow_run:\s*\r?\n\s*workflows:\s*\[([^\]]+)\]')
  if ($m.Success) { return ($m.Groups[1].Value -replace '"','' ) }
  return $null
}
$isAdi = @{}
foreach ($n in $isMetin.Keys) { $isAdi[$n] = ([regex]::Match($isMetin[$n], '(?m)^name:\s*(.+)$')).Groups[1].Value.Trim() }

$ciftler = New-Object System.Collections.ArrayList
foreach ($tuketici in $isOkur.Keys) {
  foreach ($dosya in $isOkur[$tuketici]) {
    foreach ($uretici in $isYazar.Keys) {
      if ($uretici -eq $tuketici) { continue }
      if ($isYazar[$uretici] -notcontains $dosya) { continue }
      $wr = WorkflowRunKaynagi $tuketici
      $bagli = ($wr -and $isAdi[$uretici] -and ($wr -like "*$($isAdi[$uretici])*"))
      $ikisiDeCron = (CronVarMi $uretici) -and (CronVarMi $tuketici)
      $pay = $null
      if ($ikisiDeCron) { $pay = EnDarPay (CronDakikalari $uretici) (CronDakikalari $tuketici) }
      # RISK yalniz: bag YOK, ikisi de cron, VE pay guvenli esigin ALTINDA.
      # Pay genisse sira takvimle kurulmus ama FIILEN DOGRU - bunu risk saymak
      # yanlis alarmdir (tarayici kendi kurt masalini anlatmasin).
      $risk = ((-not $bagli) -and $ikisiDeCron -and ($null -ne $pay) -and ($pay -lt $GUVENLI_PAY_DK))
      [void]$ciftler.Add([ordered]@{
        uretici = $uretici; tuketici = $tuketici; dosya = $dosya
        workflow_run_bagli = [bool]$bagli
        ikisi_de_cron = [bool]$ikisiDeCron
        pay_dk = $pay
        risk = $risk
      })
    }
  }
}

$riskli = @($ciftler | Where-Object { $_.risk }) | Sort-Object uretici, tuketici
$bagliOlan = @($ciftler | Where-Object { $_.workflow_run_bagli })

Write-Host "=== ZINCIR HARITASI ==="
Write-Host ("is akisi: {0} | bulunan uretici-tuketici cifti: {1}" -f $isMetin.Count, $ciftler.Count)
Write-Host ("workflow_run ile BAGLI: {0} | SIRA RISKI (pay < {1} dk): {2}" -f $bagliOlan.Count, $GUVENLI_PAY_DK, $riskli.Count)
$genisPay = @($ciftler | Where-Object { (-not $_.risk) -and (-not $_.workflow_run_bagli) -and $_.ikisi_de_cron })
Write-Host ("TAKVIMLE AMA PAY GENIS (kabul edilebilir): {0}" -f $genisPay.Count)
if ($bagliOlan.Count -gt 0) {
  Write-Host ""
  Write-Host "--- ZATEN OLAYA BAGLI (dogru kurulmus) ---"
  foreach ($c in ($bagliOlan | Select-Object -First 10)) { Write-Host ("  {0}  ->  {1}   ({2})" -f $c.uretici, $c.tuketici, $c.dosya) }
}
if ($riskli.Count -gt 0) {
  Write-Host ""
  Write-Host "--- SIRA RISKI (takvime yasliyor; gecikme degisince bozulur) ---"
  $g = $riskli | Group-Object { "$($_.uretici) -> $($_.tuketici)" }
  foreach ($x in ($g | Sort-Object Count -Descending | Select-Object -First 20)) {
    $d = @($x.Group | ForEach-Object { $_.dosya } | Select-Object -Unique -First 3) -join ', '
    $py = ($x.Group | Select-Object -First 1).pay_dk
    Write-Host ("  {0,-52} pay {1,4} dk   {2}" -f $x.Name, $py, $d)
  }
  if ($g.Count -gt 20) { Write-Host ("  ... ve {0} cift daha" -f ($g.Count - 20)) }
}

$rapor = [ordered]@{
  tarih = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  is_akisi = $isMetin.Count
  cift = $ciftler.Count
  olaya_bagli = $bagliOlan.Count
  sira_riski = $riskli.Count
  riskliler = @($riskli)
  yontem_notu = "Metin analizi: is akisi -> cagirdigi betik -> betigin yazdigi/okudugu veri/*.json. Kosula bagli ya da degiskenden kurulan dosya adlari KACAR; bulunanlar gercek, 'hepsi' iddia edilmez."
}
[IO.File]::WriteAllText((Join-Path $kok 'veri/zincir-haritasi.json'), ($rapor | ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding($false)))
Write-Host ""
Write-Host "-> veri/zincir-haritasi.json"
Write-Host 'COZUM KALIBI: tuketicinin tetigine ->  on: workflow_run: workflows: ["URETICI ADI"], types: [completed]'
if ($riskli.Count -gt 0) { exit 2 }
exit 0
