#requires -Version 5.1
# ============================================================================
#  SMMM KLASİK ARŞİV TOHUM TABLOSU   13.09.2026  (BEDEL 0: yalnız ambar okuma)
#
#  NEDEN (Cem 13.09 "1. yap"): bitirme sınavı 2026'da teste geçti; biçim çapası yalnız 2 dönem
#  (320 soru). İçerik çapası klasik arşivden gelecek: klasik soru + komisyon cevabı → test
#  sorusu tohumu (alt madde başına bir mikro soru). Bu betik "hangi klasik belge tohum
#  olabilir" sorusunu ÖLÇER; dönüştürmez.
#
#  ÖLÇÜLENLER (belge başına):
#   tur          soru+cevap | yalniz-cevap | yalniz-soru  (2019 sonrası bazı belgeler yalnız
#                komisyon cevabı taşır, vaka metni yoktur → tohum olamaz)
#   soru_sayisi  "SORU n / Soru n / n-)" işaretinden (kaba; işaret yoksa null = ölçülmedi)
#   alt_madde    soru kısmında "a) b) c)" sayısı (mikro soru tohumu)
#   hesap        soru kısmında 1.000 karakter başına tutar yoğunluğu >= 1,5
#   yururluk     veri/yururluk-kontrolu-smmm.json işareti (mülga kanun bağlamı)
#   konular      veri/smmm-analiz.json aynı dönem|ders etiketleri (belge düzeyi, tam eşleşme)
#   testte_de    bu etiketlerden 2026 test kitapçıklarında da geçenler (eski↔yeni örnek çifti)
#   tohum_uygun  tur=soru+cevap VE yürürlük işareti yok
#
#  TELİF: klasik soru/cevap METNİ bu çıktıya YAZILMAZ (repo public). Yalnız künye + sayı + etiket.
#  Çıktı: veri/smmm-klasik-tohum.json (RaporYaz) + veri/SMMM-KLASIK-TOHUM.md
# ============================================================================
param()
$ErrorActionPreference = 'Stop'
$depoKok = Split-Path -Parent $PSScriptRoot
. (Join-Path $depoKok 'arac\rapor-yaz.ps1')
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$anahtarSb = "$($env:SUPABASE_SERVICE_KEY)".Trim()
if (-not $anahtarSb) { $anahtarSb = "$([Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'))".Trim() }
if (-not $anahtarSb) { throw 'SUPABASE_SERVICE_KEY yok' }
$basliklarSb = @{ apikey = $anahtarSb; Authorization = "Bearer $anahtarSb"; 'User-Agent' = 'mevzuat-radar-robot/1.0' }
$DERS_AD = @{ '01' = 'Finansal Muhasebe'; '02' = 'Finansal Tablolar ve Analizi'; '03' = 'Maliyet Muhasebesi'; '04' = 'Muhasebe Denetimi'; '05' = 'Vergi Mevzuatı ve Uygulaması'; '06' = 'Hukuk'; '07' = 'Muh. ve Mali Müş. Meslek Hukuku'; '08' = 'Sermaye Piyasası Mevzuatı' }

# --- 1) ambar: SMMM komisyon cevabı belgeleri (sayfalı, sıralı) ---
$belgeler = New-Object System.Collections.Generic.List[object]
$ofs = 0
while ($true) {
  $adr = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar?select=kaynak_ad,metin&tur=eq.cikmis-komisyon-cevabi&kaynak_ad=ilike.' + [uri]::EscapeDataString('%smmm_%') + '&order=id.asc&limit=40&offset=' + $ofs
  $yanitSayfa = $null
  for ($den = 1; $den -le 3; $den++) { try { $yanitSayfa = Invoke-WebRequest -Uri $adr -Headers $basliklarSb -UseBasicParsing -TimeoutSec 180; break } catch { if ($den -eq 3) { throw }; Start-Sleep -Seconds (5 * $den) } }
  $sayfaSatir = @((ConvertFrom-Json -InputObject $yanitSayfa.Content))
  foreach ($st in $sayfaSatir) { if ($st) { $belgeler.Add($st) } }
  $ofs += $sayfaSatir.Count
  if ($sayfaSatir.Count -lt 40) { break }
}
if ($belgeler.Count -lt 100) { throw "KÖR: ambardan yalnız $($belgeler.Count) klasik belge geldi" }

# --- 2) analiz (konu etiketleri) + yürürlük işaretleri ---
$analizHam = Get-Content (Join-Path $depoKok 'veri\smmm-analiz.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$konuHarita = @{}; $testKonu = @{}
foreach ($dn in @($analizHam.donemler)) {
  $kodDn = [regex]::Match("$($dn.kaynakUrl)", '_(\d{2})\.pdf$').Groups[1].Value
  if (-not $kodDn -or -not $dn.konuSayim) { continue }
  $anahtarDn = "$($dn.donem)|$kodDn"
  $etiketler = @($dn.konuSayim.PSObject.Properties | ForEach-Object { $_.Name })
  $konuHarita[$anahtarDn] = $etiketler
  if ("$($dn.donem)" -like '2026/*') { if (-not $testKonu.ContainsKey($kodDn)) { $testKonu[$kodDn] = @{} }; foreach ($et in $etiketler) { $testKonu[$kodDn][$et] = 1 } }
}
$yururlukHam = Get-Content (Join-Path $depoKok 'veri\yururluk-kontrolu-smmm.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$yururlukIsaret = @{}
foreach ($kt in @($yururlukHam.kitapciklar)) { $yururlukIsaret["$($kt.anahtar)"] = @($kt.isaret | ForEach-Object { "$($_.mulga)" }) }

# --- 3) belge başına ölçüm ---
$satirlar = New-Object System.Collections.Generic.List[object]
foreach ($bg in $belgeler) {
  $mt = [regex]::Match("$($bg.kaynak_ad)", 'smmm_(\d{4})_(\d)_(\d{2})'); if (-not $mt.Success) { continue }
  $donemBg = "$($mt.Groups[1].Value)/$($mt.Groups[2].Value)"; $kodBg = $mt.Groups[3].Value; $anahtarBg = "$donemBg|$kodBg"
  $metinBg = ("$($bg.metin)" -replace '\s+', ' ')
  $cevapBas = [regex]::Match($metinBg, '\bCEVAPLAR\b|\bCEVAP\s*1\b|\bCevap\s*1\b|\bYANITLAR\b')
  $soruIsareti = [regex]::Matches($metinBg, '\bSORULAR\b|\bSORU\s*\d+|\bSoru\s*\d+|(?<![\d.,])\d\s*-\s*\)|İSTENİLEN|İstenilen|hesaplayınız|yapınız|açıklayınız|yazınız|belirtiniz')
  $soruKismi = $(if ($cevapBas.Success) { $metinBg.Substring(0, $cevapBas.Index) } else { $metinBg })
  $turBg = $(if ($soruIsareti.Count -ge 1 -and $cevapBas.Success) { 'soru+cevap' } elseif ($soruIsareti.Count -ge 1) { 'yalniz-soru' } else { 'yalniz-cevap' })
  if ($turBg -eq 'yalniz-cevap') { $soruKismi = '' }
  $soruNo = @([regex]::Matches($soruKismi, '\bSORU\s*(\d+)|\bSoru\s*(\d+)|(?<![\d.,])(\d)\s*-\s*\)') | ForEach-Object { foreach ($gi in 1..3) { if ($_.Groups[$gi].Success) { [int]$_.Groups[$gi].Value } } } | Select-Object -Unique)
  $altMadde = ([regex]::Matches($soruKismi, '(?:^|\s)[a-hA-H]\s*[).]\s')).Count
  $tutarSay = ([regex]::Matches($soruKismi, '\d{1,3}(?:\.\d{3})+')).Count
  $yogunluk = $(if ($soruKismi.Length -gt 0) { [math]::Round($tutarSay * 1000.0 / $soruKismi.Length, 2) } else { 0 })
  $isaretBg = $(if ($yururlukIsaret.ContainsKey($anahtarBg)) { $yururlukIsaret[$anahtarBg] } else { @() })
  $konuBg = $(if ($konuHarita.ContainsKey($anahtarBg)) { $konuHarita[$anahtarBg] } else { @() })
  $testteDe = @($konuBg | Where-Object { $testKonu.ContainsKey($kodBg) -and $testKonu[$kodBg].ContainsKey($_) })
  $uygun = ($turBg -eq 'soru+cevap' -and -not @($isaretBg).Count)
  $gerekce = $(if ($turBg -ne 'soru+cevap') { "tur $turBg (vaka metni ya da resmi cevap yok)" } elseif (@($isaretBg).Count) { "yürürlük: $(@($isaretBg) -join ', ')" } else { '' })
  $satirlar.Add([pscustomobject][ordered]@{
      anahtar = $anahtarBg; donem = $donemBg; ders_kodu = $kodBg; ders = $DERS_AD[$kodBg]; tur = $turBg
      soru_kismi_kr = $soruKismi.Length; soru_sayisi = $(if ($soruNo.Count) { $soruNo.Count } else { $null }); alt_madde = $altMadde
      puan_yazan = [bool]($soruKismi -match '\b\d{1,3}\s*[Pp]uan'); tutar_yogunlugu = $yogunluk; hesap = ($yogunluk -ge 1.5)
      yururluk = @($isaretBg); konular = @($konuBg); testte_de = @($testteDe); tohum_uygun = $uygun; gerekce = $gerekce
    })
}
$satirDizi = @($satirlar.ToArray() | Sort-Object ders_kodu, donem)

# --- 4) ders özeti ---
$ozet = New-Object System.Collections.Generic.List[object]
foreach ($kod in @($DERS_AD.Keys | Sort-Object)) {
  $ds = @($satirDizi | Where-Object { $_.ders_kodu -eq $kod })
  if (-not $ds.Count) { continue }
  $uygunlar = @($ds | Where-Object { $_.tohum_uygun })
  $ozet.Add([pscustomobject][ordered]@{
      ders_kodu = $kod; ders = $DERS_AD[$kod]; belge = $ds.Count
      soru_cevap = @($ds | Where-Object { $_.tur -eq 'soru+cevap' }).Count; yalniz_cevap = @($ds | Where-Object { $_.tur -eq 'yalniz-cevap' }).Count; yalniz_soru = @($ds | Where-Object { $_.tur -eq 'yalniz-soru' }).Count
      yururluk_isaretli = @($ds | Where-Object { @($_.yururluk).Count }).Count
      tohum_uygun_belge = $uygunlar.Count
      tohum_uygun_soru = [int](($uygunlar | Where-Object { $null -ne $_.soru_sayisi } | Measure-Object soru_sayisi -Sum).Sum)
      tohum_uygun_alt_madde = [int](($uygunlar | Measure-Object alt_madde -Sum).Sum)
      hesap_belge = @($uygunlar | Where-Object { $_.hesap }).Count
      soru_sayisi_olculemeyen = @($uygunlar | Where-Object { $null -eq $_.soru_sayisi }).Count
      ornek_cift_konu = @($uygunlar | ForEach-Object { @($_.testte_de) } | Select-Object -Unique).Count
      yil_araligi = "$(($uygunlar | ForEach-Object { [int]$_.donem.Substring(0,4) } | Measure-Object -Minimum).Minimum)-$(($uygunlar | ForEach-Object { [int]$_.donem.Substring(0,4) } | Measure-Object -Maximum).Maximum)"
    })
}

$cikti = [ordered]@{
  olcum = (Get-Date -Format 'yyyy-MM-dd HH:mm')
  uretici = 'arac/smmm-klasik-tohum.ps1'
  kaynak = 'ambar dokumanlar tur=cikmis-komisyon-cevabi (SMMM) + veri/smmm-analiz.json + veri/yururluk-kontrolu-smmm.json'
  not = 'soru_sayisi ve alt_madde işaretten sayılır (kaba); konular belge düzeyidir (soru başına değil). Metin yazılmaz (telif).'
  belge = $satirDizi.Count
  ders_ozeti = @($ozet.ToArray())
  belgeler = $satirDizi
}
RaporYaz -Hedef (Join-Path $depoKok 'veri\smmm-klasik-tohum.json') -Nesne $cikti

$md = New-Object System.Text.StringBuilder
[void]$md.AppendLine('# SMMM KLASİK ARŞİV — TOHUM TABLOSU')
[void]$md.AppendLine('')
[void]$md.AppendLine("> Üretim: **$($cikti.olcum)** (makine; elle düzenlenmez — ``arac/smmm-klasik-tohum.ps1``). Bedel 0. Klasik metin yazılmaz (telif).")
[void]$md.AppendLine('')
[void]$md.AppendLine("Ambardaki SMMM komisyon cevabı belgesi: **$($satirDizi.Count)**. Tohum = vaka metni + resmî cevap taşıyan, yürürlük işareti olmayan belge.")
[void]$md.AppendLine('')
[void]$md.AppendLine('| Ders | Belge | Soru+cevap | Yalnız cevap | Yürürlük işaretli | **Tohum belge** | Tohum soru* | Tohum alt madde* | Hesaplı belge | Eski↔2026 ortak konu | Yıl |')
[void]$md.AppendLine('|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|')
foreach ($oz in $ozet) { [void]$md.AppendLine("| $($oz.ders) | $($oz.belge) | $($oz.soru_cevap) | $($oz.yalniz_cevap) | $($oz.yururluk_isaretli) | **$($oz.tohum_uygun_belge)** | $($oz.tohum_uygun_soru) ($($oz.soru_sayisi_olculemeyen) belgede ölçülemedi) | $($oz.tohum_uygun_alt_madde) | $($oz.hesap_belge) | $($oz.ornek_cift_konu) | $($oz.yil_araligi) |") }
[void]$md.AppendLine('')
[void]$md.AppendLine('\* Soru ve alt madde sayısı işaretten sayılır (kaba). "Eski↔2026 ortak konu": tohum belgenin analiz etiketlerinden 2026 test kitapçıklarında da aynen geçenler (etiket adı dönemler arasında farklı yazılmışsa sayılmaz).')
[void]$md.AppendLine('')
[void]$md.AppendLine('⚠ **Yürürlük işareti yalnız mülga kanun bağlamını yakalar** (6762 TTK, 818 BK, 2499 SPKn, eski SPK serileri…). Vergi/SGK oran, had ve tutarları her yıl değişir; "işaretsiz" tohumun rakamları GÜNCEL DEĞİLDİR. Dönüştürmede senaryo yapısı alınır, oran/had soru kökünde güncel değerle ve kaynak paketinden yeniden kurulur.')
[void]$md.AppendLine('')
[void]$md.AppendLine('**Dönüştürme kuralı (13.09 GM kararı, Cem "önerin"; seçenek (a) bağımsız kart):** 2026 testlerinde ortak veri bloklu soru grubu yalnız FTA 2026/2''de (13/40; "birbirinden bağımsız olarak cevaplayınız"), öteki 7 derste 0. Bir klasik vakadan çıkan her mikro soru, gereken veriyi kendi kökünde taşıyan BAĞIMSIZ karttır.')
$mdYol = Join-Path $depoKok 'veri\SMMM-KLASIK-TOHUM.md'
$mdMetin = $md.ToString()
$eskiMd = $(if (Test-Path $mdYol) { [IO.File]::ReadAllText($mdYol, [Text.Encoding]::UTF8) -replace '\*\*\d{4}-\d{2}-\d{2} \d{2}:\d{2}\*\*', '' } else { '' })
if ($eskiMd -ne ($mdMetin -replace '\*\*\d{4}-\d{2}-\d{2} \d{2}:\d{2}\*\*', '')) { [IO.File]::WriteAllText($mdYol, $mdMetin, [Text.UTF8Encoding]::new($false)) }
$ozet | Format-Table ders, belge, soru_cevap, yalniz_cevap, yururluk_isaretli, tohum_uygun_belge, tohum_uygun_soru, tohum_uygun_alt_madde, hesap_belge, ornek_cift_konu, yil_araligi -AutoSize | Out-String -Width 220
