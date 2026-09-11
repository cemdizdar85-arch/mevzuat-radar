# KGK KONU DOSYALARI (10.09.2026) - 0 USD, model cagrisi YOK.
# Girdi : veri/fabrika/kgk-plan.csv (arac tarafindan degil, olcum betigi tarafindan uretildi)
# Cikti : veri/sinav/konu/kgk-olcum-<modul>.json  -> YALNIZ kaynak on-olcumu icin
#         (basim konu dosyalari plan onaylandiktan sonra ayrica uretilir)
# NEDEN: uretime girmeden once her modulun konu-kaynak eslesmesi olculecek. SGS'de bu adim
#        50+ konuyu alakasiz kaynaktan kurtardi (10.09 T3 topyekun denetimi).
param([int]$EnAzCikan = 2)
$ErrorActionPreference = 'Stop'
$kok = Split-Path $PSScriptRoot -Parent
# modul -> uretici DersRegex (motor/kalip-parti-uret.ps1 $DERS_KANUN anahtarlariyla BIREBIR)
$MODUL_DERS = @{
  'a) Turkiye Muhasebe Standartlari'        = @{ k = 'tms';     r = 'Türkiye Muhasebe Standartları' }
  'b) Turkiye Denetim Standartlari'         = @{ k = 'tds';     r = 'Türkiye Denetim Standartları' }
  'c) Kurumsal Yonetim ve Finansal Yonetim' = @{ k = 'kyfy';    r = 'Kurumsal Yönetim İlkeleri ve Finansal Yönetim' }
  'c) Sermaye Piyasasi Mevzuati'            = @{ k = 'spk';     r = 'Sermaye Piyasası Mevzuatı' }
  'd) Bankacilik Mevzuati'                  = @{ k = 'banka';   r = 'Bankacılık Mevzuatı' }
  'e) Sigortacilik ve Ozel Emeklilik'       = @{ k = 'sigorta'; r = 'Sigortacılık ve Özel Emeklilik Mevzuatı' }
  'f) Kurumsal Surdurulebilirlik'           = @{ k = 'surdur';  r = 'Kurumsal Sürdürülebilirlik Raporlaması' }
}
$csv = Join-Path $kok 'veri\fabrika\kgk-plan.csv'
if (-not (Test-Path $csv)) { Write-Host "kgk-plan.csv yok" -ForegroundColor Red; exit 1 }
$c = Import-Csv $csv -Encoding UTF8
$konuDir = Join-Path $kok 'veri\sinav\konu'
New-Item -ItemType Directory -Force $konuDir | Out-Null
$COP_DESEN = '(?i)okunamad|okunmad|bilinmiyor|belirsiz|\(\d+\s*soru|^\?+$|^\s*$'
$ozet = New-Object System.Collections.Generic.List[object]
foreach ($m in ($MODUL_DERS.Keys | Sort-Object)) {
  $b = $MODUL_DERS[$m]
  $lst = @($c | Where-Object { "$($_.modul)" -eq $m -and [int]$_.cikan -ge $EnAzCikan -and [int]$_.yazilacak -gt 0 -and "$($_.guncellik)" -eq 'GUNCEL' -and "$($_.konu)" -notmatch $COP_DESEN } | Sort-Object { -[int]$_.cikan })
  if (-not $lst.Count) { Write-Host ("{0,-42} konu yok, atlandi" -f $m); continue }
  $konular = @($lst | ForEach-Object { "$($_.konu)" })
  $yol = Join-Path $konuDir ("kgk-olcum-{0}.json" -f $b.k)
  [IO.File]::WriteAllText($yol, (ConvertTo-Json -InputObject @($konular) -Depth 2), [Text.UTF8Encoding]::new($false))
  $ozet.Add([pscustomobject]@{ modul = $m; kod = $b.k; ders = $b.r; konu = $konular.Count; yazilacak = (($lst | Measure-Object yazilacak -Sum).Sum); dosya = "veri/sinav/konu/kgk-olcum-$($b.k).json" })
  Write-Host ("{0,-42} konu {1,4} | yazilacak {2,5} -> kgk-olcum-{3}.json" -f $m, $konular.Count, (($lst | Measure-Object yazilacak -Sum).Sum), $b.k)
}
$ozet | Export-Csv (Join-Path $kok 'veri\fabrika\kgk-olcum-listesi.csv') -NoTypeInformation -Encoding UTF8
Write-Host ''
Write-Host ("TOPLAM: {0} modul | {1} konu | {2} yazilacak soru" -f $ozet.Count, (($ozet | Measure-Object konu -Sum).Sum), (($ozet | Measure-Object yazilacak -Sum).Sum)) -ForegroundColor Green
Write-Host 'Simdi her modul icin: arac/konu-kaynak-on-olcum.ps1 -KonuDosya <dosya> -Ders "<ders>"'
