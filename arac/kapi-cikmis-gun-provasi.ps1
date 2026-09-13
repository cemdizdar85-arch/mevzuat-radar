#requires -Version 5.1
# ============================================================================
#  KAPI-CB + KAPI-GT EŞDEĞERLİK PROVASI   13.09.2026  (BEDEL 0: yalnız ambar okuma)
#
#  NEDEN: veri/KUSUR-ONARIM-PROTOKOLU.md — kapı basılmadan eski/yeni mantık
#  AMBARIN TAMAMINDA kıyaslanır (örneklem yasak). İki kapı YENİ: eski mantıkta
#  hiçbir soru bu gerekçeyle düşmüyordu; yani fark = yeni kapının işaretlediği
#  soru sayısı olmalıdır. Prova her ambar sorusunu (kalip_parti, bütün sınavlar)
#  motor/kapi-cikmis-gun.ps1'in AYNI fonksiyonlarından geçirir ve sayar:
#    · KAPI-CB SERT (aynı çıkmış soruyla >= 2 cümle %80+)  · KAPI-CB NOT (tek cümle)
#    · KAPI-GT (çözüm 360/365 kullanıyor, kök tabanı yazmıyor / başka taban)
#  Çıktı: veri/kapi-cikmis-gun-provasi.json + .md  (çıkmış soru METNİ yazılmaz;
#  yalnız çıkmış kitapçık adı + soru no + bizim cümlemizin başı).
#  Kapı bugünden sonraki üretimi düşürür; mevcut işaretli sorular silinmez →
#  rapordaki liste "TAZELEME BEKLİYOR" iş emridir.
# ============================================================================
param([string]$Etiket = '')
$ErrorActionPreference = 'Stop'
$depoKok = Split-Path -Parent $PSScriptRoot
. (Join-Path $depoKok 'arac\rapor-yaz.ps1')
. (Join-Path $depoKok 'motor\kapi-cikmis-gun.ps1')
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$anahtarSb = "$($env:SUPABASE_SERVICE_KEY)".Trim()
if (-not $anahtarSb) { $anahtarSb = "$([Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'))".Trim() }
if (-not $anahtarSb) { throw 'SUPABASE_SERVICE_KEY yok' }
$basliklarSb = @{ apikey = $anahtarSb; Authorization = "Bearer $anahtarSb"; 'User-Agent' = 'mevzuat-radar-robot/1.0' }

if (-not (CikmisDiziniKur $basliklarSb)) { throw "KAPI-CB KÖR: $($script:CIKMIS_DIZIN_KOR) — prova yapılamaz" }

$sayac = [ordered]@{ parti = 0; soru = 0; cb_sert = 0; cb_not = 0; gt = 0; herhangi_sert = 0 }
$sinavSayac = @{}
$liste = New-Object System.Collections.Generic.List[object]
$ofs = 0; $sayfaBoy = 10
while ($true) {
  $adr = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/kalip_parti?select=etiket,sinav,icerik&order=etiket.asc&limit=' + $sayfaBoy + '&offset=' + $ofs
  if ($Etiket) { $adr = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/kalip_parti?select=etiket,sinav,icerik&etiket=eq.' + [uri]::EscapeDataString($Etiket) }
  $sayfa = $null
  # K2 tuzağı (13.09 ilk koşuda yaşandı): PS 5.1 Invoke-RestMethod JSON dizisini TEK nesne olarak verir; @(...) 1 elemanlı dizi yapar → foreach ile aç
  for ($den = 1; $den -le 3; $den++) { try { $hamSayfa = Invoke-RestMethod -Uri $adr -Headers $basliklarSb -TimeoutSec 300; $sayfa = @(foreach ($ogeSayfa in $hamSayfa) { $ogeSayfa }); break } catch { if ($den -eq 3) { throw } ; Start-Sleep -Seconds (5 * $den) } }
  foreach ($parti in $sayfa) {
    if (-not $parti -or -not $parti.icerik) { continue }
    $sayac.parti++
    $sinavAd = "$($parti.sinav)"; if (-not $sinavSayac.ContainsKey($sinavAd)) { $sinavSayac[$sinavAd] = [ordered]@{ soru = 0; cb_sert = 0; cb_not = 0; gt = 0 } }
    foreach ($pr in @($parti.icerik.PSObject.Properties)) {
      $soruNesne = $pr.Value
      if (-not $soruNesne -or -not ($soruNesne.PSObject.Properties['soru']) -or -not $soruNesne.soru) { continue }
      $sayac.soru++; $sinavSayac[$sinavAd].soru++
      $cb = CikmisCumleKapisi $soruNesne $basliklarSb
      $adimlarBu = $(if ($soruNesne.PSObject.Properties['adimlar']) { $soruNesne.adimlar } else { @() })
      $gt = @(GunTabaniKapisi $soruNesne $adimlarBu)
      if (@($cb.kusur).Count) { $sayac.cb_sert++; $sinavSayac[$sinavAd].cb_sert++ }
      if (@($cb.not).Count -and -not @($cb.kusur).Count) { $sayac.cb_not++; $sinavSayac[$sinavAd].cb_not++ }
      if ($gt.Count) { $sayac.gt++; $sinavSayac[$sinavAd].gt++ }
      if (@($cb.kusur).Count -or $gt.Count) {
        $sayac.herhangi_sert++
        $hakemKarar = $(if ($soruNesne.PSObject.Properties['hakem'] -and $soruNesne.hakem) { "$($soruNesne.hakem.karar)" } else { '' })
        $liste.Add([pscustomobject]@{ etiket = "$($parti.etiket)"; id = $pr.Name; sinav = $sinavAd; konu = "$($soruNesne.konu)"; hakem = $hakemKarar; cb = @($cb.kusur); gt = $gt })
      }
    }
  }
  if ($Etiket -or $sayfa.Count -lt $sayfaBoy) { break }
  $ofs += $sayfa.Count
  if ($sayac.parti % 100 -lt $sayfaBoy) { Write-Host ("  ... {0} parti · {1} soru · CB sert {2} · CB not {3} · GT {4}" -f $sayac.parti, $sayac.soru, $sayac.cb_sert, $sayac.cb_not, $sayac.gt) -ForegroundColor DarkGray }
}

$cikti = [ordered]@{
  olcum = (Get-Date -Format 'yyyy-MM-dd HH:mm')
  kapi_dosyasi = 'motor/kapi-cikmis-gun.ps1'
  esik = $KCB_ESIK; sert_adet = $KCB_SERT_ADET
  cikmis_dizini = [ordered]@{ soru = $script:CIKMIS_DIZIN.Birimler.Count; cumle = $script:CIKMIS_DIZIN.SegmentSayisi }
  eski_mantik_isaretli = 0
  yeni_mantik_isaretli = $sayac.herhangi_sert
  sayac = $sayac
  sinav = $sinavSayac
  isaretli = @($liste.ToArray())
}
$hedefJson = Join-Path $depoKok 'veri\kapi-cikmis-gun-provasi.json'
RaporYaz -Hedef $hedefJson -Nesne $cikti

$md = New-Object System.Text.StringBuilder
[void]$md.AppendLine('# KAPI-CB + KAPI-GT eşdeğerlik provası')
[void]$md.AppendLine('')
[void]$md.AppendLine("Ölçüm: $($cikti.olcum) · üretici: ``arac/kapi-cikmis-gun-provasi.ps1`` · bedel 0")
[void]$md.AppendLine('')
[void]$md.AppendLine("Ambar: **$($sayac.parti) parti · $($sayac.soru) soru**. Çıkmış dizini: $($cikti.cikmis_dizini.soru) soru · $($cikti.cikmis_dizini.cumle) cümle.")
[void]$md.AppendLine('')
[void]$md.AppendLine('| Sınav | Soru | CB sert (≥2 cümle) | CB not (1 cümle) | GT gün tabanı |')
[void]$md.AppendLine('|---|---:|---:|---:|---:|')
foreach ($sn in @($sinavSayac.Keys | Sort-Object)) { $v = $sinavSayac[$sn]; [void]$md.AppendLine("| $sn | $($v.soru) | $($v.cb_sert) | $($v.cb_not) | $($v.gt) |") }
[void]$md.AppendLine("| **Toplam** | **$($sayac.soru)** | **$($sayac.cb_sert)** | **$($sayac.cb_not)** | **$($sayac.gt)** |")
[void]$md.AppendLine('')
[void]$md.AppendLine("Eski mantık bu iki gerekçeyle 0 soru işaretliyordu; yeni mantık **$($sayac.herhangi_sert)** soru işaretliyor (CB sert ∪ GT). Fark = kasıtlı değişiklik.")
[void]$md.AppendLine('')
[void]$md.AppendLine('## İşaretli sorular (TAZELEME BEKLİYOR)')
[void]$md.AppendLine('')
foreach ($s in $liste) { [void]$md.AppendLine("- ``$($s.etiket)/$($s.id)`` [$($s.sinav)] $($s.konu) · hakem $($s.hakem)$(if(@($s.cb).Count){' · CB: ' + (@($s.cb)[0])})$(if(@($s.gt).Count){' · GT: ' + (@($s.gt) -join '; ')})") }
$hedefMd = Join-Path $depoKok 'veri\kapi-cikmis-gun-provasi.md'
$mdMetin = $md.ToString()
$eskiMd = $(if (Test-Path $hedefMd) { ([IO.File]::ReadAllText($hedefMd, [Text.Encoding]::UTF8) -replace '(?m)^Ölçüm: .*$', '') } else { '' })
if ($eskiMd -ne ($mdMetin -replace '(?m)^Ölçüm: .*$', '')) { [IO.File]::WriteAllText($hedefMd, $mdMetin, [Text.UTF8Encoding]::new($false)) }
Write-Host ("PROVA: {0} parti · {1} soru · CB sert {2} · CB not {3} · GT {4} · işaretli {5}" -f $sayac.parti, $sayac.soru, $sayac.cb_sert, $sayac.cb_not, $sayac.gt, $sayac.herhangi_sert) -ForegroundColor Green
