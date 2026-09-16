# ============================================================================
#  SMMM YETERLİLİK CEVAP TAMLIK ÖLÇÜMÜ   16.09.2026 (Cem "1 VE 2 YAP", GM 2)
#  Soru: KGK'da görüntüden okuduğumuz gibi, SMMM'de de cevabı yalnız GÖRÜNTÜDE kalan kitapçık var mı?
#  Paralı görüntü okumaya gitmeden önce ölçülür.
#
#  NE YAPAR (bedel 0, model yok, ambara/diske yazmaz — yalnız rapor):
#   1. veri/smmm-arsiv/pdf/smmm_YYYY_D_KK.pdf — her PDF'in sayfa sayfa metin miktarı (pdftotext, sayfa ayracı \f)
#      ve görüntü taşıyan sayfaları (pdfimages -list). METİNSİZ SAYFA = <50 harf; GÖRÜNTÜ SAYFASI = metinsiz + görüntülü.
#   2. Cevap kaynağı:
#      - TEST dönemi (2026+): veri/smmm-cevap-anahtari.json'da "dönem|kod" var mı (kitapçık son sayfası tablosu).
#      - KLASİK dönem (2008–2025): ambarda tur='cikmis-komisyon-cevabi' belgesi var mı, metin boyu, "cevap/çözüm"
#        işaretleri; PDF'te metinsiz/görüntü sayfası varsa o sayfalardaki içerik belgede EKSİK olabilir → İNCELE.
#  Çıktı: veri/smmm-cevap-tamlik.json (RaporYaz). Kitapçık metni rapora girmez, yalnız sayı.
#  Kullanım: powershell -NoProfile -File arac/smmm-cevap-tamlik.ps1   (yalnız yerelde: PDF'ler git dışı)
# ============================================================================
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$depoKok = Split-Path -Parent $PSScriptRoot
. (Join-Path (Join-Path $depoKok 'arac') 'rapor-yaz.ps1')
$pdfKlasoru = Join-Path (Join-Path (Join-Path $depoKok 'veri') 'smmm-arsiv') 'pdf'
if(-not (Test-Path $pdfKlasoru)){ Write-Host 'KÖR: veri/smmm-arsiv/pdf yok (yalnız yerelde).'; exit 2 }
$popplerAdaylari = @('C:\Users\cemdi\AppData\Local\Microsoft\WinGet\Packages\oschwartz10612.Poppler_Microsoft.Winget.Source_8wekyb3d8bbwe\poppler-25.07.0\Library\bin\pdftotext.exe', (Get-Command pdftotext -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Source))
$pdfMetin = $popplerAdaylari | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
if(-not $pdfMetin){ Write-Host 'KÖR: pdftotext bulunamadı.'; exit 2 }
$pdfGorsel = Join-Path (Split-Path $pdfMetin) ('pdfimages' + [IO.Path]::GetExtension($pdfMetin))

$sbAnahtar = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'); if(-not $sbAnahtar){ $sbAnahtar = $env:SUPABASE_SERVICE_KEY }
if(-not $sbAnahtar){ Write-Host 'KÖR: SUPABASE_SERVICE_KEY yok'; exit 2 }
$sbBasliklar = @{ apikey=$sbAnahtar; Authorization="Bearer $sbAnahtar"; 'User-Agent'='mevzuat-radar-robot/1.0' }
$komisyon = @{}
$sayfaBasi = 0
while($true){
  $parca = @(foreach($x in (Invoke-RestMethod -Uri ("https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar?select=kaynak_ad,metin&tur=eq.cikmis-komisyon-cevabi&order=kaynak_ad&limit=100&offset=$sayfaBasi") -Headers $sbBasliklar -TimeoutSec 180)){ $x })
  foreach($belge in $parca){
    $kokAdi = [regex]::Match("$($belge.kaynak_ad)",'\((smmm_\d{4}_\d_\d{2})\)').Groups[1].Value
    if(-not $kokAdi){ continue }
    $govde = "$($belge.metin)"
    $komisyon[$kokAdi] = [pscustomobject]@{ boy=$govde.Length; cevap_isareti=([regex]::Matches($govde,'(?i)cevap|çözüm|cozum')).Count }
  }
  if($parca.Count -lt 100){ break }
  $sayfaBasi += 100
}
$anahtarDosyasi = Get-Content (Join-Path $depoKok 'veri\smmm-cevap-anahtari.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$testAnahtari = @{}
foreach($p in $anahtarDosyasi.donemler.PSObject.Properties){ $testAnahtari[$p.Name] = @($p.Value.a.PSObject.Properties).Count }

$kitapciklar = New-Object System.Collections.Generic.List[object]
# PS 5.1: poppler'in stderr uyarıları ("Unknown font tag") Stop altında sonlandırıcı hataya döner → PDF döngüsünde Continue
$ErrorActionPreference = 'Continue'
foreach($pdf in (Get-ChildItem $pdfKlasoru -Filter 'smmm_*.pdf' | Sort-Object Name)){
  $es = [regex]::Match($pdf.BaseName,'^smmm_(\d{4})_(\d)_(\d{2})$'); if(-not $es.Success){ continue }
  $yil = [int]$es.Groups[1].Value; $donem = "$yil/$($es.Groups[2].Value)"; $dersKodu = $es.Groups[3].Value
  $gecici = [IO.Path]::GetTempFileName()
  & $pdfMetin -enc UTF-8 $pdf.FullName $gecici 2>$null
  $tumMetin = [IO.File]::ReadAllText($gecici,[Text.Encoding]::UTF8)
  [IO.File]::Delete($gecici)
  $sayfaMetinleri = $tumMetin -split "`f"
  if($sayfaMetinleri.Count -gt 1 -and -not $sayfaMetinleri[-1].Trim()){ $sayfaMetinleri = $sayfaMetinleri[0..($sayfaMetinleri.Count-2)] }
  $gorselliSayfalar = New-Object System.Collections.Generic.HashSet[int]
  foreach($satir in @(& $pdfGorsel -list $pdf.FullName 2>$null | Select-Object -Skip 2)){ $alan = ($satir.Trim() -split '\s+'); if($alan.Count -ge 4 -and $alan[0] -match '^\d+$' -and [int]$alan[3] -ge 200){ [void]$gorselliSayfalar.Add([int]$alan[0]) } }
  $metinsiz = New-Object System.Collections.Generic.List[int]; $gorselSayfa = New-Object System.Collections.Generic.List[int]
  for($i = 0; $i -lt $sayfaMetinleri.Count; $i++){
    $harfSayisi = ([regex]::Matches($sayfaMetinleri[$i],'\p{L}')).Count
    if($harfSayisi -lt 50){ $metinsiz.Add($i+1); if($gorselliSayfalar.Contains($i+1)){ $gorselSayfa.Add($i+1) } }
  }
  $test = $yil -ge 2026
  $anahtarAdi = "$donem|$dersKodu"
  $durum = ''
  if($test){
    $durum = if($testAnahtari.ContainsKey($anahtarAdi)){ "TEST ANAHTARI VAR ($($testAnahtari[$anahtarAdi]))" } else { 'TEST ANAHTARI YOK' }
  } else {
    $kb = $komisyon[$pdf.BaseName]
    # 16.09 ölçüldü: 2019–2025'te görüntü sayfaları SORU kâğıdıdır (imzalı tarama); "SINAV KOMİSYONU CEVAPLARI" sonraki sayfada metin.
    $cevapSayfasi = 0
    #   Başlık biçimi değişir ("KOMİSYONU CEVAPLARI", "KOMİSYONUCEVAPLARI", "CEVAP ANAHTARI", başlıksız yevmiye) →
    #   başlık yoksa İLK METİNLİ SAYFA cevap başlangıcıdır. Hiç metinli sayfa yoksa kitapçığın tamamı görüntüdür.
    for($i = 0; $i -lt $sayfaMetinleri.Count; $i++){ if($sayfaMetinleri[$i].ToUpperInvariant() -match 'KOM[İI]SYONU?\s*CEVAP|CEVAP\s+ANAHTAR'){ $cevapSayfasi = $i + 1; break } }
    if($cevapSayfasi -eq 0){ for($i = 0; $i -lt $sayfaMetinleri.Count; $i++){ if(-not $metinsiz.Contains($i + 1)){ $cevapSayfasi = $i + 1; break } } }
    $tamamiGorsel = ($cevapSayfasi -eq 0)
    $cevapGorsel = @($gorselSayfa | Where-Object { $cevapSayfasi -eq 0 -or $_ -ge $cevapSayfasi }).Count
    $soruGorsel = @($gorselSayfa | Where-Object { $cevapSayfasi -gt 0 -and $_ -lt $cevapSayfasi }).Count
    # ambar belgesi PDF metninin tamamını taşımalı (2017/3–2018/3 Hukuk: kitapçık kısa, belge tam — ölçüldü)
    $durum = if(-not $kb){ 'KOMİSYON CEVABI YOK' } elseif($tamamiGorsel){ 'İNCELE: kitapçığın tamamı görüntü' } elseif($cevapGorsel){ 'İNCELE: cevap sayfası görüntü' } elseif($kb.boy -lt 0.9 * $tumMetin.Trim().Length){ 'İNCELE: cevap belgesi PDF metninden kısa' } elseif($soruGorsel){ 'CEVAP METİN · SORU GÖRÜNTÜDE' } else { 'KOMİSYON CEVABI METİN' }
  }
  $kitapciklar.Add([ordered]@{
    kok=$pdf.BaseName; donem=$donem; ders_kodu=$dersKodu; tur=$(if($test){'test'}else{'klasik'})
    sayfa=$sayfaMetinleri.Count; metinsiz_sayfa=$metinsiz.ToArray(); goruntu_sayfasi=$gorselSayfa.ToArray()
    cevap_sayfasi=$(if($test){ $null } else { $cevapSayfasi }); soru_goruntu_sayfasi=$(if($test){ 0 } else { $soruGorsel })
    komisyon_boy=$(if($komisyon.ContainsKey($pdf.BaseName)){ $komisyon[$pdf.BaseName].boy } else { $null })
    durum=$durum
  })
}
$yillar = [ordered]@{}
foreach($g in ($kitapciklar | Group-Object { $_.donem.Substring(0,4) } | Sort-Object Name)){
  $dagilim = [ordered]@{}; foreach($dg in ($g.Group | Group-Object { ($_.durum -replace '\s*\(\d+\)$','') } | Sort-Object Name)){ $dagilim[$dg.Name] = $dg.Count }
  $yillar[$g.Name] = [ordered]@{ kitapcik=$g.Count; goruntu_sayfali=@($g.Group | Where-Object { @($_.goruntu_sayfasi).Count }).Count; durum=$dagilim }
  Write-Host ("{0}: kitapçık {1,2} · görüntü sayfalı {2,2} · {3}" -f $g.Name,$g.Count,$yillar[$g.Name].goruntu_sayfali,(($dagilim.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ', '))
}
$genel = [ordered]@{}; foreach($dg in ($kitapciklar | Group-Object { ($_.durum -replace '\s*\(\d+\)$','') } | Sort-Object Name)){ $genel[$dg.Name] = $dg.Count }
$rapor = [ordered]@{
  olcum = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  kural = 'METİNSİZ SAYFA = <50 harf; GÖRÜNTÜ SAYFASI = metinsiz ve ≥200 px görüntü taşıyan sayfa. Klasik dönem: ambarda komisyon cevabı yoksa YOK; "KOMİSYON CEVAPLARI" sayfasından önceki görüntü sayfaları SORU kâğıdıdır (SORU GÖRÜNTÜDE — soru metni ambarda yok); sonraki görüntü sayfası İNCELE; ambar belgesi PDF metninin %90''ından kısaysa İNCELE. Test dönemi: veri/smmm-cevap-anahtari.json.'
  soru_goruntu_sayfasi = (@($kitapciklar | ForEach-Object { $_.soru_goruntu_sayfasi }) | Measure-Object -Sum).Sum
  kitapcik = $kitapciklar.Count
  komisyon_belgesi = $komisyon.Count
  durum = $genel
  yillar = $yillar
  kitapciklar = $kitapciklar.ToArray()
}
[void](RaporYaz -Hedef (Join-Path (Join-Path $depoKok 'veri') 'smmm-cevap-tamlik.json') -Nesne $rapor -Sessiz)
Write-Host ("ÖZET: kitapçık {0} · komisyon belgesi {1} · {2}" -f $kitapciklar.Count,$komisyon.Count,(($genel.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ', '))
exit 0
