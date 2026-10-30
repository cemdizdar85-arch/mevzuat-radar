#requires -Version 5.1
# ============================================================================
#  KAPI TARAMASI — hazır soru dosyalarına ön denetim + alıntı + çizim + G2 öncül kapıları   30.10.2026 · bedel 0 (model yok)
#
#  NEDEN (Cem 30.10 "kapı taramaları laptopta bellek darlığından kesiliyor, GitHub Actions'ta koştur"): yerel kapi-son/kapi-tek
#  koşuları 0,2–0,6 GB boş bellekte arka planda öldürülüyordu. Aynı kapılar bulutta (.github/workflows/kapi-tarama.yml) koşar.
#  Depo herkese açık → soru metni ve kapı ayrıntısı günlüğe/depoya YAZILMAZ: ayrıntı ambara (kalip_parti etiket '__kapi/<ad>',
#  sinav 'SISTEM'; hazir-senkron'un __hazir düzeni), günlüğe yalnız sayılar.
#
#  KULLANIM (depo kökünden)
#    powershell -NoProfile -File arac/kapi-tarama.ps1 -Desen '^hazir-smmm-bicim-spk-' -Klasor <çıktı klasörü> [-Ambar]
#    powershell -NoProfile -File arac/kapi-tarama.ps1 -Indir -Desen 'smmm-bicim-spk-' -Klasor <klasör>   (ambardaki sonuçları yerele)
#  Girdi: veri/fabrika/hazir-*.json (bulutta önce arac/hazir-senkron.ps1 -Indir). Her dosyaya:
#    arac/hazir-soru-denetle.ps1 -Dosya … -IkizEtiket <ad> -Ders <dersin adı> · arac/alinti-kapi.js · arac/cizim-kapi.js · arac/g2-oncul.js
#  Çıktı: <Klasor>/<ad>.{on,alinti,cizim,g2}.txt + <Klasor>/ozet.tsv; -Ambar ile her dosyanın dört çıktısı + özeti __kapi/<ad>'a.
#  🚫 GÖRMEZ: profil kapısı (profil-kapi-smmm.js yerel, kalıba göre üretilir) · okuyucu işi · ders adı bulunamayan etikette -Ders verilmez
#    (ön denetim SMMM etiketinde sözlüğü etiketten kurar; uzunluk tavanı SMMM p90 yerine varsayılan olabilir — özette "ders?" yazar).
# ============================================================================
param([string]$Desen = '', [string]$Klasor = '', [switch]$Ambar, [switch]$Indir)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$depoKok = Split-Path -Parent $PSScriptRoot
if (-not $Klasor) { throw '-Klasor zorunlu' }
New-Item -ItemType Directory -Force $Klasor | Out-Null
$anahtar = "$env:SUPABASE_SERVICE_KEY".Trim(); if (-not $anahtar) { $anahtar = "$([Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'))".Trim() }
$env:SUPABASE_SERVICE_KEY = $anahtar
$uc = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/kalip_parti'
$bas = @{ apikey = $anahtar; Authorization = "Bearer $anahtar"; Accept = 'application/json'; 'User-Agent' = 'mevzuat-radar-robot/1.0' }

if ($Indir) {
  $r = Invoke-WebRequest -UseBasicParsing -Uri ("$uc" + '?select=etiket,icerik&etiket=like.' + [uri]::EscapeDataString("__kapi/$Desen*") + '&order=etiket.asc&limit=500') -Headers $bas -TimeoutSec 120
  $satir = @(([Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray()) | ConvertFrom-Json) | ForEach-Object { $_ })
  foreach ($s in $satir) { $ic = $s.icerik; if ($ic -is [string]) { $ic = ConvertFrom-Json $ic }; $ad = "$($s.etiket)".Substring(7)
    foreach ($k in 'on', 'alinti', 'cizim', 'g2') { [IO.File]::WriteAllText((Join-Path $Klasor "$ad.$k.txt"), "$($ic.$k)", (New-Object Text.UTF8Encoding $false)) }
    "$ad · $($ic.ozet) · koşu $($ic.kosu) · $($ic.zaman)" }
  "İNDİ: $($satir.Count) sonuç"; return
}

. (Join-Path $depoKok 'arac\smmm-ders-adi.ps1')
$EK = [ordered]@{ 'spk' = 'Sermaye Piyasası Mevzuatı'; 'meslek' = 'Muhasebecilik ve Mali Müşavirlik Meslek Hukuku'; 'denetim' = 'Muhasebe Denetimi' }
function DersBul([string]$ad) {
  if ($ad -notmatch '^smmm-') { return '' }
  $d = SmmmDersAdi $ad $null; if ($d) { return $d }
  foreach ($k in $EK.Keys) { if ($ad -match "(^|-)$k(-|$)") { return $EK[$k] } }
  return ''
}
$fab = Join-Path $depoKok 'veri\fabrika'
$dosyalar = @(Get-ChildItem $fab -Filter 'hazir-*.json' | Where-Object { $_.Name -notmatch '^hazir-dusen-' -and $_.BaseName -match $Desen } | Sort-Object Name)
if (-not $dosyalar.Count) { throw "desene uyan hazır dosya yok: $Desen" }
$utf = New-Object Text.UTF8Encoding $false
$ozet = New-Object System.Collections.Generic.List[string]; $ozet.Add("ad`tsoru`tkusursuz`talinti_kusurlu`tcizim`tg2`tders")
foreach ($f in $dosyalar) {
  $ad = $f.BaseName -replace '^hazir-', ''; $ders = DersBul $ad; $rel = "veri\fabrika\$($f.Name)"
  $c = @{}
  $arg = @('-NoProfile', '-File', (Join-Path $depoKok 'arac\hazir-soru-denetle.ps1'), '-Dosya', $rel, '-IkizEtiket', $ad); if ($ders) { $arg += @('-Ders', $ders) }
  Push-Location $depoKok; $eapEski = $ErrorActionPreference; $ErrorActionPreference = "Continue"   # PS 5.1: Stop + yerel komutun stderr'i = sahte hata
  try {
    $c.on = (& powershell @arg 2>&1 | ForEach-Object { "$_" }) -join "`n"
    $c.alinti = (& node 'arac/alinti-kapi.js' $rel.Replace('\', '/') 2>&1 | ForEach-Object { "$_" }) -join "`n"
    $c.cizim = (& node 'arac/cizim-kapi.js' . $rel.Replace('\', '/') 2>&1 | ForEach-Object { "$_" }) -join "`n"
    $c.g2 = (& node 'arac/g2-oncul.js' $rel 2>&1 | ForEach-Object { "$_" }) -join "`n"
  } finally { $ErrorActionPreference = $eapEski; Pop-Location }
  foreach ($k in $c.Keys) { [IO.File]::WriteAllText((Join-Path $Klasor "$ad.$k.txt"), $c[$k], $utf) }
  $n = @((ConvertFrom-Json ([IO.File]::ReadAllText($f.FullName))) | ForEach-Object { $_ }).Count
  $tem = [regex]::Match($c.on, 'ozet: (\d+)/(\d+) soru kusursuz'); $ali = [regex]::Match($c.alinti, "KUSUR'lu (\d+)"); $ciz = [regex]::Match($c.cizim, 'ozet: (\d+)/(\d+)')
  $g2n = @($c.g2 -split "`n" | Where-Object { $_ -match 'G2' }).Count
  $sat = "$ad`t$n`t$(if($tem.Success){$tem.Groups[1].Value}else{'?'})`t$(if($ali.Success){$ali.Groups[1].Value}else{'?'})`t$(if($ciz.Success){"$($ciz.Groups[1].Value)/$($ciz.Groups[2].Value)"}else{'?'})`t$g2n`t$(if($ders){'ok'}else{'ders?'})"
  $ozet.Add($sat); $sat   # günlüğe yalnız sayılar
  if ($Ambar) {
    $p = $sat -split "`t"
    $govde = [ordered]@{ etiket = "__kapi/$ad"; sinav = 'SISTEM'; yazan = 'kapi-tarama'
      icerik = [ordered]@{ aciklama = 'Kapı taraması sonucu (arac/kapi-tarama.ps1); soru metni yok, kapı çıktıları.'; zaman = (Get-Date).ToUniversalTime().ToString('yyyy-MM-dd HH:mm'); kosu = "$env:GITHUB_RUN_ID"
        ozet = "soru $($p[1]) · kusursuz $($p[2]) · alıntı KUSUR'lu $($p[3]) · çizim $($p[4]) · G2 $($p[5])"; on = $c.on; alinti = $c.alinti; cizim = $c.cizim; g2 = $c.g2 } }
    $bayt = [Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject $govde -Depth 6 -Compress))
    [void](Invoke-RestMethod -Method Post -Uri "$uc`?on_conflict=etiket" -Headers ($bas + @{ Prefer = 'resolution=merge-duplicates,return=minimal' }) -ContentType 'application/json; charset=utf-8' -Body $bayt -TimeoutSec 120)
  }
}
[IO.File]::WriteAllText((Join-Path $Klasor 'ozet.tsv'), ($ozet -join "`r`n"), $utf)
"TARAMA BİTTİ: $($dosyalar.Count) dosya$(if($Ambar){' · sonuçlar ambarda __kapi/*'})"
