#requires -Version 5.1
# ============================================================================
#  TFRS 18 ÖNCESİ (2026'da YÜRÜRLÜKTE) TMS/TFRS METİNLERİ — ayrı kayıt adıyla ambara   05.11.2026 · BEDEL 0
#
#  NEDEN: ambardaki TMS 7 / TMS 34 / TMS 29 / TFRS 16 / TMS 8 / TMS 10 kayıtları KGK 2026 KIRMIZI Kitap'tan
#    (TFRS 18 sonuç değişiklikleri işlenmiş; TFRS 18 yürürlüğü 1.1.2027). 2026 sınavında ve 31.12.2026'ya kadar
#    yürürlükte olan ESKİ metin ambarda yoktu (ör. TMS 7 eski p.33-34 faiz/temettü sınıflaması).
#    İş emri: C:\TETIKTE-CALISMA\kgk-is\basim\IS-EMRI-YUTMA-TFRS18-ONCESI.md (kol kgkbasim, Cem 05.11 "evet (1)").
#  KAYNAK: yalnız KGK resmî yayını — 2026 MAVİ Kitap (TMS_TFRS_Setleri/2026/Mavi_Kitap/...). Mavi Kitap metninde
#    "TFRS 18" geçmez (kuru koşu bunu her standart için ölçer; geçerse DURUR).
#  ⛔ MEVCUT (Kırmızı Kitap, TFRS 18 değişik) kayıtlar SİLİNMEZ/EZİLMEZ: bu betik yalnız POST eder, DELETE yoktur.
#    Yeni kayıt adı: "<std> (TFRS 18 oncesi, 2026'da yururlukte) <parça>"  ör. "TMS 7 (TFRS 18 oncesi, 2026'da yururlukte) p.33 - Faiz ve temettüler".
#    Yazımdan önce ve sonra mevcut "<std> ..." kayıtlarının ad+metin özeti alınır; değişmişse KIRMIZI.
#  BÖLME: motor/standart-yut.ps1'in KENDİ işlevleri (AST ile okunur, kopya kod yok) + aynı TMS/TFRS ana akışı
#    (düz çıkarım, layout adayı yalnız resmî numaralardan sapma azalırsa). Sağlama: aynı yol Kırmızı Kitap PDF'ine de
#    uygulanır ve ambardaki mevcut parça sayısıyla kıyaslanır (yolun motorla aynı sonucu verdiğinin ölçüsü).
#  -Uygula yoksa KURU (indir, böl, ön kontrol; yazmaz). -Std ile tek standart seçilir.
#  GÖRMEZ: Mavi Kitap PDF'inin kendisinde KGK'nın yaptığı hata · paragraf içi tablo düzeni (pdftotext ne veriyorsa o).
# ============================================================================
param([switch]$Uygula, [string[]]$Std = @())
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$depoKok = Split-Path -Parent $PSScriptRoot
$surumEki = "(TFRS 18 oncesi, 2026'da yururlukte)"
$baslikNotu = "KGK 2026 Mavi Kitap metni - TFRS 18 sonuc degisikliklerinden ONCEKI surum; 31.12.2026'ya kadar baslayan donemlerde yururlukte (TFRS 18 yururlugu 1.1.2027)"
$kokAdres = 'https://www.kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TMS_TFRS_Setleri/2026'
$planTam = [ordered]@{ 'TMS 7' = 'TMS'; 'TMS 34' = 'TMS'; 'TMS 29' = 'TMS'; 'TFRS 16' = 'TFRS'; 'TMS 8' = 'TMS'; 'TMS 10' = 'TMS' }
$Std = @($Std | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })   # -File tek dize verir: "TMS 8,TMS 10"
$plan = [ordered]@{}; foreach ($k in $planTam.Keys) { if (-not $Std.Count -or $Std -contains $k) { $plan[$k] = $planTam[$k] } }
if (-not $plan.Count) { throw 'plan boş (-Std tutmadı)' }
$yedekKlasor = 'C:\TETIKTE-YEDEK\ambar-yut-tfrs18-oncesi-20261105'

# --- standart-yut.ps1 işlevleri (yalnız işlev tanımları; ana akış koşmaz)
. (Join-Path $depoKok 'arac\dipnot-ayir.ps1')
$syYol = Join-Path $depoKok 'motor\standart-yut.ps1'
$hata = $null; $belirtec = $null
$ast = [Management.Automation.Language.Parser]::ParseFile($syYol, [ref]$belirtec, [ref]$hata)
if ($hata -and $hata.Count) { throw "standart-yut.ps1 ayrıştırılamadı: $($hata[0].Message)" }
$islevler = @($ast.FindAll({ param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -like 'SY_*' }, $false))
if ($islevler.Count -lt 10) { throw "standart-yut işlevleri eksik okundu ($($islevler.Count))" }
foreach ($f in $islevler) { . ([scriptblock]::Create($f.Extent.Text)) }
$sinav = @(SY_OzSinav)
if ($sinav.Count) { throw "standart-yut öz-sınavı düştü: $($sinav -join ' | ')" }
Write-Host ("standart-yut işlevleri yüklendi: {0} · öz-sınav geçti" -f $islevler.Count)
$arac = SY_PdfAraci; if (-not $arac) { throw 'pdftotext yok' }
Write-Host "pdftotext: $arac"

$anahtarSb = "$($env:SUPABASE_SERVICE_KEY)".Trim(); if (-not $anahtarSb) { $anahtarSb = "$([Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'))".Trim() }
if (-not $anahtarSb) { throw 'SUPABASE_SERVICE_KEY yok' }
$basliklarSb = @{ apikey = $anahtarSb; Authorization = "Bearer $anahtarSb"; 'User-Agent' = 'mevzuat-radar-robot/1.0' }
$tabloAdr = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar'

function AmbarOnek([string]$onek) {
  $q = [uri]::EscapeDataString("$onek*")
  $w = Invoke-WebRequest -UseBasicParsing -Uri "$tabloAdr`?select=id,tur,kaynak_ad,baslik,metin,kaynak_url&kaynak_ad=like.$q&order=kaynak_ad.asc&limit=5000" -Headers $basliklarSb -TimeoutSec 120
  @(([Text.Encoding]::UTF8.GetString($w.RawContentStream.ToArray()) | ConvertFrom-Json) | ForEach-Object { $_ })
}
function Ozet($kayitlar) {
  $md5 = [Security.Cryptography.MD5]::Create()
  $satir = @($kayitlar | Sort-Object kaynak_ad | ForEach-Object { "$($_.kaynak_ad)|$($_.tur)|$($_.kaynak_url)|" + [BitConverter]::ToString($md5.ComputeHash([Text.Encoding]::UTF8.GetBytes("$($_.metin)"))) })
  [BitConverter]::ToString($md5.ComputeHash([Text.Encoding]::UTF8.GetBytes(($satir -join "`n"))))
}
# Mevcut (Kırmızı Kitap) kayıtlar: ad = std ya da "std " ile başlar, yeni sürüm eki DEĞİL
function Mevcut([string]$s) { @(AmbarOnek "$s " | Where-Object { -not "$($_.kaynak_ad)".StartsWith("$s $surumEki") }) + @(AmbarOnek $s | Where-Object { "$($_.kaynak_ad)" -ceq $s }) }

function Bol([string]$s, [string]$url, [string]$etiket) {
  $gecici = Join-Path ([IO.Path]::GetTempPath()) ("tfrs18o-" + ($s -replace '[^A-Za-z0-9]', '') + "-$etiket")
  $null = New-Item -ItemType Directory -Force $gecici
  $pdf = Join-Path $gecici 'kaynak.pdf'; $txt = Join-Path $gecici 'kaynak.txt'; $lay = Join-Path $gecici 'kaynak-layout.txt'
  $y = Invoke-WebRequest -UseBasicParsing -Uri $url -TimeoutSec 240
  $bayt = $y.RawContentStream.ToArray(); [IO.File]::WriteAllBytes($pdf, $bayt)
  if ([Text.Encoding]::ASCII.GetString($bayt, 0, 4) -ne '%PDF') { throw "PDF DEĞİL: $url" }
  $onceki = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
  & $arac -enc UTF-8 -nopgbrk $pdf $txt 2>$null | Out-Null
  & $arac -enc UTF-8 -nopgbrk -layout $pdf $lay 2>$null | Out-Null
  $ErrorActionPreference = $onceki
  $tam = [IO.File]::ReadAllText($txt, [Text.Encoding]::UTF8)
  $yeni = @(SY_Bol $tam $s)
  $layMetin = [IO.File]::ReadAllText($lay, [Text.Encoding]::UTF8)
  $layAday = @(SY_Bol (SY_TmsLayoutDuzle $layMetin $s) $s)
  $hak = SY_LayoutHakikat $layMetin
  $dd = SY_HakikatSapmasi $yeni $hak; $ld = SY_HakikatSapmasi $layAday $hak
  $dk = ($yeni | ForEach-Object { $_.metin.Length } | Measure-Object -Sum).Sum; $lk = ($layAday | ForEach-Object { $_.metin.Length } | Measure-Object -Sum).Sum
  $secim = 'duz'
  if ($layAday.Count -gt 0 -and $ld -lt $dd -and $lk -ge ($dk * 0.98)) { $yeni = $layAday; $secim = 'layout' }
  [pscustomobject]@{ parcalar = $yeni; metin = $tam; bayt = $bayt.Length; secim = $secim; delik = "duz $dd / layout $ld" }
}

# 1) KURU: indir, böl, sağla, ön kontrol
$is = New-Object System.Collections.Generic.List[object]
foreach ($s in $plan.Keys) {
  $tip = $plan[$s]
  $maviUrl = "$kokAdres/Mavi_Kitap/$tip/$($s -replace ' ','%20').pdf"
  $kirmiziUrl = "$kokAdres/Kirmizi_Kitap/$tip/$($s -replace ' ','%20').pdf"
  $m = Bol $s $maviUrl 'mavi'
  $k = Bol $s $kirmiziUrl 'kirmizi'
  $t18 = ([regex]::Matches($m.metin, 'TFRS\s*18')).Count
  if ($t18 -gt 0) { throw "$s Mavi Kitap metninde 'TFRS 18' $t18 kez geçiyor — TFRS 18 öncesi sürüm DEĞİL, durdu" }
  $mevcut = @(Mevcut $s)
  $yeniAd = @(AmbarOnek "$s $surumEki")
  if ($yeniAd.Count -ne 0) { throw "ÖN KONTROL: '$s $surumEki' önekiyle ambarda zaten $($yeniAd.Count) kayıt var — yazılmadı" }
  $docs = New-Object System.Collections.Generic.List[object]; $adlar = @{}
  foreach ($p in $m.parcalar) {
    $ad = "$($p.kaynak_ad)"
    if (-not ($ad.StartsWith("$s ") -or $ad -ceq $s)) { throw "parça adı standartla başlamıyor: $ad" }
    $ad2 = "$s $surumEki" + $ad.Substring($s.Length)
    # motor da çift ad üretebilir (ambarda TFRS 16 p.0 üç kez): durdurmaz, sayar; geri okuma ad başına metin kümesini kıyaslar
    if ($adlar.ContainsKey($ad2)) { $adlar[$ad2]++ } else { $adlar[$ad2] = 1 }
    if (-not "$($p.metin)".Trim()) { throw "boş metin: $ad2" }
    $docs.Add([pscustomobject]@{ kaynak_ad = $ad2; metin = "$($p.metin)"; baslik = "$s - $baslikNotu"; kaynak_url = $maviUrl })
  }
  $ciftler = @($adlar.Keys | Where-Object { $adlar[$_] -gt 1 } | ForEach-Object { "$_ x$($adlar[$_])" })
  if ($ciftler.Count) { Write-Host ("      çift ad (motor davranışı): {0}" -f ($ciftler -join ' | ')) -ForegroundColor Yellow }
  $mk = ($m.parcalar | ForEach-Object { $_.metin.Length } | Measure-Object -Sum).Sum
  $mevKr = ($mevcut | ForEach-Object { "$($_.metin)".Length } | Measure-Object -Sum).Sum
  # fark: Kırmızı bölmede olup Mavi'de olmayan / tersi paragraf etiketleri
  $etk = { param($ad) if ($ad -match ' (p\.\S+|Ek .*)') { ($Matches[1] -replace ' - .*$', '') } else { $ad } }
  $mE = @($m.parcalar | ForEach-Object { & $etk $_.kaynak_ad.Substring($s.Length) }); $kE = @($k.parcalar | ForEach-Object { & $etk $_.kaynak_ad.Substring($s.Length) })
  $yalnizMavi = @($mE | Where-Object { $kE -notcontains $_ }); $yalnizKirmizi = @($kE | Where-Object { $mE -notcontains $_ })
  Write-Host ("  {0}: MAVİ {1} parça/{2:N0} kr ({3}; {4}) · Kırmızı bölme {5} parça · ambar mevcut {6} parça/{7:N0} kr · TFRS 18 geçişi Mavi 0" -f $s, $m.parcalar.Count, $mk, $m.secim, $m.delik, $k.parcalar.Count, $mevcut.Count, $mevKr)
  Write-Host ("      yalnız Mavi'de: {0}" -f ($(if ($yalnizMavi.Count) { $yalnizMavi -join ', ' } else { '-' })))
  Write-Host ("      yalnız Kırmızı'da: {0}" -f ($(if ($yalnizKirmizi.Count) { $yalnizKirmizi -join ', ' } else { '-' })))
  $birebir = 0; foreach ($kp in $k.parcalar) { if (@($mevcut | Where-Object { "$($_.kaynak_ad)" -ceq "$($kp.kaynak_ad)" -and "$($_.metin)" -ceq "$($kp.metin)" }).Count -ge 1) { $birebir++ } }
  Write-Host ("      sağlama: Kırmızı bölme ambarla ad+metin birebir {0}/{1}" -f $birebir, $mevcut.Count)
  if ($k.parcalar.Count -ne $mevcut.Count) { Write-Host ("      ! SAĞLAMA: Kırmızı bölme {0} ≠ ambar {1} (motor yolu ambarı birebir üretmiyor; incele)" -f $k.parcalar.Count, $mevcut.Count) -ForegroundColor Yellow }
  $is.Add([pscustomobject]@{ std = $s; url = $maviUrl; docs = $docs; mevcut = $mevcut; mevcutOzet = (Ozet $mevcut) })
}
$planYol = Join-Path ([IO.Path]::GetTempPath()) 'tfrs18-oncesi-plan.json'
[IO.File]::WriteAllText($planYol, (ConvertTo-Json -InputObject @($is | ForEach-Object { [ordered]@{ std = $_.std; url = $_.url; parca = $_.docs.Count; parcalar = $_.docs.ToArray() } }) -Depth 5), (New-Object Text.UTF8Encoding $false))
Write-Host "plan: $planYol"
if (-not $Uygula) { "KURU: $($is.Count) standart hazır, ön kontrol TAMAM — yazılmadı (-Uygula)"; return }

# 2) YAZ — yedek (mevcut kayıtlar + yazılacaklar), yalnız POST, geri oku, mevcutlar değişmedi mi
New-Item -ItemType Directory -Force $yedekKlasor | Out-Null
$damga = Get-Date -Format 'yyyyMMdd-HHmmss'
foreach ($p in $is) {
  $slug = ($p.std -replace ' ', '').ToLower()
  $yd = Join-Path $yedekKlasor ("{0}.mevcut-ambar.{1}.json" -f $slug, $damga)
  [IO.File]::WriteAllText($yd, (ConvertTo-Json -InputObject @($p.mevcut) -Depth 5), (New-Object Text.UTF8Encoding $false))
  [IO.File]::WriteAllText((Join-Path $yedekKlasor ("{0}.yazilacak.{1}.json" -f $slug, $damga)), (ConvertTo-Json -InputObject $p.docs.ToArray() -Depth 5), (New-Object Text.UTF8Encoding $false))
  for ($i = 0; $i -lt $p.docs.Count; $i += 50) {
    $dilim = @($p.docs[$i..([Math]::Min($i + 49, $p.docs.Count - 1))])
    $govde = ConvertTo-Json -InputObject @($dilim | ForEach-Object { [ordered]@{ tur = 'standart-madde'; kaynak_ad = $_.kaynak_ad; baslik = $_.baslik; metin = $_.metin; kaynak_url = $_.kaynak_url } }) -Depth 5
    if ($govde.TrimStart()[0] -ne '[') { $govde = "[$govde]" }
    Invoke-RestMethod -Method Post -Uri $tabloAdr -Headers ($basliklarSb + @{ Prefer = 'return=minimal' }) -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 180 | Out-Null
  }
  Start-Sleep -Seconds 1
  $geri = @(AmbarOnek "$($p.std) $surumEki")
  if ($geri.Count -ne $p.docs.Count) { throw "GERİ OKUMA TUTMADI (sayı): $($p.std) ambar $($geri.Count) / yazılan $($p.docs.Count) — yedek: $yd" }
  foreach ($grup in @($p.docs | Group-Object kaynak_ad -CaseSensitive)) {
    $g = @($geri | Where-Object { $_.kaynak_ad -ceq $grup.Name })
    $yazMetin = (@($grup.Group | ForEach-Object { $_.metin } | Sort-Object -CaseSensitive) -join "`n<>`n")
    $geriMetin = (@($g | ForEach-Object { "$($_.metin)" } | Sort-Object -CaseSensitive) -join "`n<>`n")
    $kotu = @($g | Where-Object { "$($_.baslik)" -cne $grup.Group[0].baslik -or "$($_.kaynak_url)" -cne $grup.Group[0].kaynak_url -or "$($_.tur)" -ne 'standart-madde' })
    if ($g.Count -ne $grup.Count -or $yazMetin -cne $geriMetin -or $kotu.Count) { throw "GERİ OKUMA TUTMADI: $($grup.Name) — yedek: $yd" }
  }
  $sonra = @(Mevcut $p.std)
  if ($sonra.Count -ne $p.mevcut.Count -or (Ozet $sonra) -ne $p.mevcutOzet) { throw "MEVCUT KAYITLAR DEĞİŞTİ: $($p.std) önce $($p.mevcut.Count) / sonra $($sonra.Count) — yedek: $yd" }
  Write-Host ("  AMBAR YAZILDI + geri okundu (birebir {0}/{0}) · mevcut {1} kayıt aynen: {2} {3}" -f $p.docs.Count, $sonra.Count, $p.std, $surumEki)
}
"UYGULANDI: $($is.Count) standart · yedek klasörü $yedekKlasor"
