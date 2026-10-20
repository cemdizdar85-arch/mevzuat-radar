# arac/bulut-zincir-karar-sinavi.ps1 - arac/bulut-zincir-karar.ps1 OZ-SINAVI + MUTASYON (21.10.2026, Cem "2 yap").
# Bedel 0: sahte gunluk klasoru + sahte bekleyen-partiler.json; ag/gh/model cagrisi YOK.
# Vakalar: eski karar sirasinin esdegerligi (yalniz hasat, butce, bakiye, hata, yarim, tavan) + 21.10 yeni sinyaller
#   (AH zaman asimi izi, Uret dustu + odenmis hasat edilmemis parti) + yanlis alarm (eski kayit, baska plan, hasat edilmis,
#   g1/g10 onek tuzagi, Uret basarili). Baglanti denetimi: api-hedef izi yaziyor, koşucu iz yolunu veriyor, yml karar betigini cagiriyor.
# Mutasyon: karar betiginin kopyasi tek tek bozulur, her bozmada sinav KIRMIZI dusmeli.
# GORMEZ: GitHub'in gercek workflow_dispatch'i ve concurrency kuyrugu (yalniz karar olculur); api-hedef'in gercek zaman asimi yolu
#   (metin baglantisi olculur, calistirilmaz).
param([switch]$MutasyonIci, [string]$KararYol = '')
$ErrorActionPreference = 'Stop'
$kok = Split-Path -Parent $PSScriptRoot
if (-not $KararYol) { $KararYol = Join-Path $kok 'arac/bulut-zincir-karar.ps1' }
. $KararYol

$tmp = Join-Path ([IO.Path]::GetTempPath()) ("zincir-sinav-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force $tmp | Out-Null
$utf8 = New-Object Text.UTF8Encoding($false); $utf8Bom = New-Object Text.UTF8Encoding($true)
$script:sayac = 0
function YeniVaka([hashtable]$loglar, $bekleyen) {
  $script:sayac++
  $d = Join-Path $tmp "v$($script:sayac)"; $lk = Join-Path $d 'kosucu-log/plan-x'
  New-Item -ItemType Directory -Force $lk | Out-Null
  foreach ($ad in @($loglar.Keys)) { [IO.File]::WriteAllText((Join-Path $lk $ad), $loglar[$ad], $utf8) }
  $by = Join-Path $d 'bekleyen-partiler.json'
  if ($null -ne $bekleyen) { [IO.File]::WriteAllText($by, (ConvertTo-Json -InputObject @($bekleyen) -Depth 4), $utf8) }
  return @{ log = (Join-Path $d 'kosucu-log'); bek = $by }
}
$ET = @('kgk-t6-tms-g1-kolay', 'kgk-t6-tms-g2-zor')
$BAS = '2026-10-20 14:35'
function K($v, [string]$uret = 'success', [int]$halka = 0, [string]$yh = '0') {
  return BulutZincirKarar -LogKok $v.log -BekleyenYol $v.bek -PlanEtiketleri $ET -KosuBasi $BAS -UretSonuc $uret -Halka $halka -YalnizHasat $yh -ButceUsd '2.1' -Tavan 10
}
$parti = { param($id, $et, $zaman, $durum) [pscustomobject]@{ id = $id; etiket = $et; zaman = $zaman; durum = $durum } }
$sonuclar = New-Object System.Collections.Generic.List[object]
function Vaka([string]$ad, $k, [string]$karar, [bool]$kirmizi) {
  $ok = ($k.karar -eq $karar -and [bool]$k.kirmizi -eq $kirmizi)
  $sonuclar.Add([pscustomobject]@{ ad = $ad; ok = $ok; bulunan = "$($k.karar)/$(if($k.kirmizi){'KIRMIZI'}else{'yesil'})"; beklenen = "$karar/$(if($kirmizi){'KIRMIZI'}else{'yesil'})" })
}

# --- eski karar sirasi (esdegerlik) ---
Vaka 'yalniz hasat: hata izi olsa da zincir yok, yesil' (K (YeniVaka @{ 'hata-cikan.log' = "YARIM (hata kodu 1) · a`r`n" } $null) 'failure' 0 '1') 'hasat-bitti' $false
Vaka 'temiz bitis: tamam, yesil' (K (YeniVaka @{ 'kgk-t6-tms-g1-kolay.log' = "BITTI`r`n" } $null)) 'tamam' $false
Vaka 'parti gunlugunde TOPLU ANLIKSIZ: yeniden' (K (YeniVaka @{ 'kgk-t6-tms-g1-kolay.log' = "  TOPLU ANLIKSIZ: x/A1 icin bekleme doldu`r`n" } $null) 'failure') 'yeniden' $false
Vaka 'butce doldu (yarim olsa da): kirmizi dur' (K (YeniVaka @{ 'butce-doldu.log' = "YARIM (butce doldu) · a`r`n"; 'a.log' = "TOPLU ANLIKSIZ`r`n" } $null)) 'butce-doldu' $true
Vaka 'AH butcesiz: butce-doldu yolundan kirmizi' (K (YeniVaka @{ 'butce-doldu.log' = "YARIM (açıklama hakemi bütçesiz: 5 soru) · p`r`n" } $null)) 'butce-doldu' $true
Vaka 'bakiye bitti: kirmizi dur (yeniden yok)' (K (YeniVaka @{ 'bakiye-bitti.log' = "YARIM (bakiye bitti) · a`r`n"; 'a.log' = "TOPLU ANLIKSIZ`r`n" } $null) 'failure') 'bakiye-bitti' $true
Vaka 'yalniz hata kodu: kirmizi, yeniden yok' (K (YeniVaka @{ 'hata-cikan.log' = "YARIM (hata kodu 1) · a`r`n" } $null) 'failure') 'hata' $true
Vaka 'yarim + hata: yeniden ama kirmizi' (K (YeniVaka @{ 'hata-cikan.log' = "YARIM (hata kodu 1) · a`r`n"; 'b.log' = "TOPLU ANLIKSIZ`r`n" } $null) 'failure') 'yeniden' $true
Vaka 'halka 10 + yarim: tavan, kirmizi' (K (YeniVaka @{ 'a.log' = "TOPLU ANLIKSIZ`r`n" } $null) 'failure' 10) 'tavan' $true
Vaka 'halka 9 + yarim: yeniden (tavan alti)' (K (YeniVaka @{ 'a.log' = "TOPLU ANLIKSIZ`r`n" } $null) 'failure' 9) 'yeniden' $false
Vaka 'cakisma/sure doldu izi (koşucu): yeniden' (K (YeniVaka @{ 'sure-doldu-atlanan.log' = "TOPLU ANLIKSIZ (süre doldu) · a`r`n" } $null)) 'yeniden' $false

# --- 21.10 yeni sinyaller ---
Vaka 'KGK t6 deseni: AH zaman asimi izi (toplu-anliksiz.log) -> yeniden' (K (YeniVaka @{ 'toplu-anliksiz.log' = "TOPLU ANLIKSIZ (zaman asimi) · kgk-t6-tms-g1-kolay/AH · msgbatch_1`r`n"; 'kgk-t6-tms-g1-kolay.log' = "BITTI`r`n" } @(& $parti 'msgbatch_1' 'kgk-t6-tms-g1-kolay/AH' '2026-10-20 15:10' 'zaman asimi - hasat bekliyor')) 'failure') 'yeniden' $false
Vaka 'iz yok + Uret dustu + bu kosunun hasat edilmemis AH partisi -> yeniden' (K (YeniVaka @{ 'kgk-t6-tms-g1-kolay.log' = "BITTI`r`n" } @(& $parti 'msgbatch_2' 'kgk-t6-tms-g1-kolay/AH' '2026-10-20 15:10' 'gonderildi')) 'failure') 'yeniden' $false
Vaka 'iz yok + Uret dustu + zaman asimi durumlu parti -> yeniden' (K (YeniVaka @{} @(& $parti 'msgbatch_3' 'kgk-t6-tms-g2-zor/A1' '2026-10-20 16:00' 'zaman asimi - hasat bekliyor')) 'failure') 'yeniden' $false
Vaka 'iz yok + Uret dustu + halka 10 + acik parti -> tavan kirmizi' (K (YeniVaka @{} @(& $parti 'msgbatch_4' 'kgk-t6-tms-g1-kolay/AH' '2026-10-20 15:10' 'gonderildi')) 'failure' 10) 'tavan' $true

# --- yanlis alarm (yeniden ACILMAMALI) ---
Vaka 'acik parti ama kosu basindan ESKI (onceki halka) -> tamam' (K (YeniVaka @{} @(& $parti 'msgbatch_5' 'kgk-t6-tms-g1-kolay/AH' '2026-10-20 14:34' 'gonderildi')) 'failure') 'tamam' $false
Vaka 'acik parti BASKA planin -> tamam' (K (YeniVaka @{} @(& $parti 'msgbatch_6' 'kgk-t6-fy-g1-kolay/AH' '2026-10-20 15:10' 'gonderildi')) 'failure') 'tamam' $false
Vaka 'g1 / g10 onek tuzagi -> tamam' (K (YeniVaka @{} @(& $parti 'msgbatch_7' 'kgk-t6-tms-g1-kolay0/AH' '2026-10-20 15:10' 'gonderildi')) 'failure') 'tamam' $false
Vaka 'parti hasat edilmis -> tamam' (K (YeniVaka @{} @(& $parti 'msgbatch_8' 'kgk-t6-tms-g1-kolay/AH' '2026-10-20 15:10' 'hasat edildi')) 'failure') 'tamam' $false
Vaka 'Uret BASARILI + acik kayit -> tamam (sinyal 2 yalniz dususte)' (K (YeniVaka @{} @(& $parti 'msgbatch_9' 'kgk-t6-tms-g1-kolay/AH' '2026-10-20 15:10' 'gonderildi'))) 'tamam' $false
Vaka 'Uret dustu, bekleyen dosyasi YOK -> hata kodu yoksa tamam' (K (YeniVaka @{} $null) 'failure') 'tamam' $false
Vaka 'Uret dustu, acik parti + hata kodu -> yeniden kirmizi' (K (YeniVaka @{ 'hata-cikan.log' = "YARIM (hata kodu 1) · a`r`n" } @(& $parti 'msgbatch_10' 'kgk-t6-tms-g2-zor' '2026-10-20 15:10' 'gonderildi')) 'failure') 'yeniden' $true
$bosV = YeniVaka @{} $null; [IO.File]::WriteAllText($bosV.bek, '', $utf8)
Vaka 'bos bekleyen dosyasi -> cokmez, tamam' (K $bosV 'failure') 'tamam' $false

# --- plan etiketi okuma ---
$planY = Join-Path $tmp 'plan.json'
[IO.File]::WriteAllText($planY, '[{"etiket":"kgk-t6-tms-g1-kolay","adet":5},{"etiket":"kgk-t6-tms-g2-zor"},{"etiket":"kgk-t6-tms-g1-kolay"}]', $utf8)
$pe = @(ZincirPlanEtiketleri $planY)
$sonuclar.Add([pscustomobject]@{ ad = 'plan etiketleri tekil okunur (2)'; ok = ($pe.Count -eq 2 -and $pe -contains 'kgk-t6-tms-g2-zor'); bulunan = ($pe -join ','); beklenen = '2 etiket' })
[IO.File]::WriteAllText($planY, '{"etiket":"tek-satir"}', $utf8)
$pe1 = @(ZincirPlanEtiketleri $planY)
$sonuclar.Add([pscustomobject]@{ ad = 'tek satirli plan (dizi degil) okunur'; ok = ($pe1.Count -eq 1 -and $pe1[0] -eq 'tek-satir'); bulunan = ($pe1 -join ','); beklenen = 'tek-satir' })

# --- baglanti denetimi (yalniz ana sinavda; mutasyon kopyasi bunu degistirmez) ---
if (-not $MutasyonIci) {
  $api = [IO.File]::ReadAllText((Join-Path $kok 'motor/api-hedef.ps1'))
  $ko = [IO.File]::ReadAllText((Join-Path $kok 'motor/kalip-kosucu.ps1'))
  $yml = [IO.File]::ReadAllText((Join-Path $kok '.github/workflows/bulut-uretim.yml'))
  $iAnl = $api.IndexOf('MEVZUAT_ANLIKSIZ_IZ'); $iExit = $api.IndexOf('exit 75')
  $sonuclar.Add([pscustomobject]@{ ad = 'api-hedef: iz exit 75 ONCESINDE yaziliyor'; ok = ($iAnl -gt 0 -and $iExit -gt $iAnl -and $api -match 'AppendAllText\("\$env:MEVZUAT_ANLIKSIZ_IZ"[^\r\n]*TOPLU ANLIKSIZ'); bulunan = "iz $iAnl / exit $iExit"; beklenen = 'iz < exit' })
  $iEnv = $ko.IndexOf('$env:MEVZUAT_ANLIKSIZ_IZ='); $iAh = $ko.IndexOf('AciklamaHakemUretim $Kok')
  $sonuclar.Add([pscustomobject]@{ ad = 'koşucu: iz yolu AH cagrisindan ONCE veriliyor'; ok = ($iEnv -gt 0 -and $iAh -gt $iEnv); bulunan = "env $iEnv / AH $iAh"; beklenen = 'env < AH' })
  $ymlOk = ($yml -match '\. \./arac/bulut-zincir-karar\.ps1') -and ($yml -match 'id: uret') -and ($yml -match 'URET_SONUC: \$\{\{ steps\.uret\.outcome \}\}') -and ($yml -match 'ZINCIR_KOSU_BASI=') -and ($yml -match "-BekleyenYol 'veri/bekleyen-partiler\.json'") -and ($yml -match "if\(\`$k\.karar -eq 'yeniden'\)")
  $sonuclar.Add([pscustomobject]@{ ad = 'bulut-uretim.yml karar betigine bagli (id/outcome/kosu basi/bekleyen yolu)'; ok = $ymlOk; bulunan = "$ymlOk"; beklenen = 'True' })
  $apiBek = ($api -match "Join-Path \`$kok 'veri\\bekleyen-partiler\.json'") -and ($api -match "zaman=\(Get-Date -Format 'yyyy-MM-dd HH:mm'\)")
  $sonuclar.Add([pscustomobject]@{ ad = 'bekleyen kaydi yolu/zaman bicimi kararla ayni (veri/bekleyen-partiler.json, yyyy-MM-dd HH:mm)'; ok = $apiBek; bulunan = "$apiBek"; beklenen = 'True' })
}

Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
$kirik = @($sonuclar | Where-Object { -not $_.ok })
if ($MutasyonIci) { if ($kirik.Count) { exit 1 } else { exit 0 } }
foreach ($r in $sonuclar) { "{0} {1}{2}" -f $(if ($r.ok) { 'GECTI ' } else { 'KALDI ' }), $r.ad, $(if ($r.ok) { '' } else { "  (bulunan $($r.bulunan), beklenen $($r.beklenen))" }) }
"OZ-SINAV: $($sonuclar.Count - $kirik.Count)/$($sonuclar.Count)"
if ($kirik.Count) { "KIRMIZI: oz-sinav kaldi"; exit 1 }

# --- MUTASYON: her bozma sinavi KIRMIZI yapmali ---
$asil = [IO.File]::ReadAllText($KararYol)
$mutlar = [ordered]@{
  'sinyal1-anliksiz-izi-kapali' = @("Select-String -Pattern 'TOPLU ANLIKSIZ' -List", "Select-String -Pattern 'XYZYOK' -List")
  'sinyal2-acik-parti-kapali'   = @('if ("$UretSonuc" -ne ''success'')', 'if ($false)')
  'sinyal2-uret-sartsiz'        = @('if ("$UretSonuc" -ne ''success'')', 'if ($true)')
  'kosu-basi-suzgeci-kapali'    = @('"$kosuBasi") -lt 0) { continue }', '"$kosuBasi") -lt -999999) { continue }')
  'hasat-edildi-suzgeci-kapali' = @("-eq 'hasat edildi') { continue }", "-eq 'XYZ') { continue }")
  'onek-tuzagi-acik'            = @('$et.StartsWith("$pe/")', '$et.StartsWith("$pe")')
  'plan-ait-suzgeci-kapali'     = @('if (-not $ait) { continue }', '')
  'tavan-gevsedi'               = @('if ($Halka -ge $Tavan)', 'if ($Halka -gt $Tavan)')
  'butce-kapisi-kapali'         = @('if ($butce.Count) {', 'if ($false) {')
  'bakiye-kapisi-kapali'        = @('if ($bakiye.Count) {', 'if ($false) {')
  'hata-kirmizisi-yeniden-kayip'= @("return (& `$sonuc 'yeniden' `$true)", "return (& `$sonuc 'yeniden' `$false)")
  'hata-tek-basina-yesil'       = @("return (& `$sonuc 'hata' `$true)", "return (& `$sonuc 'hata' `$false)")
  'yalniz-hasat-kapali'         = @('if ("$YalnizHasat" -eq ''1'')', 'if ($false)')
}
$mTmp = Join-Path ([IO.Path]::GetTempPath()) ("zincir-mut-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force $mTmp | Out-Null
$kac = 0; $mToplam = 0
$psYol = (Get-Process -Id $PID).Path
# kontrol: BOZULMAMIS kopya alt surecte YESIL donmeli (yoksa "yakalandi" demek cokme de olabilir - sahte mutasyon)
$kYol = Join-Path $mTmp 'kontrol.ps1'; [IO.File]::WriteAllText($kYol, $asil, $utf8Bom)
& $psYol -NoProfile -File $PSCommandPath -MutasyonIci -KararYol $kYol | Out-Null
if ($LASTEXITCODE -ne 0) { "KIRMIZI: bozulmamis kopya alt surecte YESIL donmedi (kod $LASTEXITCODE) - mutasyon olcumu gecersiz"; exit 1 }
"kontrol: bozulmamis kopya YESIL"
foreach ($ad in $mutlar.Keys) {
  $mToplam++
  $esk = $mutlar[$ad][0]; $yen = $mutlar[$ad][1]
  if ($asil.IndexOf($esk) -lt 0) { "MUTASYON KURULAMADI (metin yok): $ad"; $kac++; continue }
  $mYol = Join-Path $mTmp "$ad.ps1"
  [IO.File]::WriteAllText($mYol, $asil.Replace($esk, $yen), $utf8Bom)
  & $psYol -NoProfile -File $PSCommandPath -MutasyonIci -KararYol $mYol | Out-Null
  if ($LASTEXITCODE -eq 0) { "MUTASYON KACTI (sinav yesil kaldi): $ad"; $kac++ } else { "mutasyon yakalandi: $ad" }
}
Remove-Item -Recurse -Force $mTmp -ErrorAction SilentlyContinue
"MUTASYON: $($mToplam - $kac)/$mToplam bozma KIRMIZI dustu"
if ($kac) { "KIRMIZI: $kac mutasyon kacti"; exit 1 }
"YESIL"
exit 0
