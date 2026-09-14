#requires -Version 5.1
# ============================================================================
#  BİTİRME (SMMM) ONAY LİSTESİ + ONAY KAYDI   14.09.2026  (bedel 0)
#
#  Cem 14.09: "(a) + kaynaklı ikinci çözüm + senin onayın ... siteye yanlış bir soru girmesini istemiyorum".
#  -Liste  : önbellekteki smmm-* sorularından onay bekleyenleri bulur → veri/sinav/SMMM-ONAY-LISTESI.md
#            Aday = kör çözüm yanlış ∧ kaynaklı ikinci çözüm DOĞRU ∧ öteki bütün yayın şartları sağlanmış
#            (arac/smmm-yayin-sarti.ps1) ∧ geçerli (parmak izi tutan) karar yok.
#            Her kartta Cem'in görmesi gereken: soru, şıklar, cevap anahtarı, kör çözümün seçtiği şık ve
#            gerekçesi, kaynaklı çözümün gerekçesi, tuzak açıklaması, dayanak.
#  -Anahtar etiket/id -Karar ONAY|RED -Not "...": Cem'in SOHBETTE verdiği kararı kaydeder
#            (veri/sinav/smmm-insan-onay.json). Parmak izi o anki soru+şıklar+cevaptan alınır.
#            ONAY yalnız aday olan soruya verilebilir (kaynaklı çözüm doğru değilse RED'den başka karar yazılmaz).
#  Kararı ASLA robot ya da model vermez; bu betik yalnız Cem'in açık kararıyla koşulur.
# ============================================================================
param([switch]$Liste, [string]$Anahtar = '', [ValidateSet('', 'ONAY', 'RED')][string]$Karar = '', [string]$Not = '')
$ErrorActionPreference = 'Stop'
$depoKok = Split-Path -Parent $PSScriptRoot
. (Join-Path $depoKok 'arac\smmm-yayin-sarti.ps1')
$onayYol = Join-Path $depoKok 'veri\sinav\smmm-insan-onay.json'

function OnbellekSoru([string]$anahtarS) {
  $parca = $anahtarS -split '/', 2
  $cf = Join-Path $depoKok "veri\fabrika\kalip-parti-$($parca[0]).json"
  if (-not (Test-Path $cf)) { throw "önbellek yok: $cf" }
  $c = Get-Content $cf -Raw -Encoding UTF8 | ConvertFrom-Json
  if (-not $c.PSObject.Properties[$parca[1]]) { throw "soru yok: $anahtarS" }
  return $c.($parca[1])
}

if ($Anahtar) {
  if (-not $Karar) { throw '-Karar ONAY ya da RED verilmeli' }
  if ($Anahtar -notlike 'smmm-*/*') { throw 'yalnız bitirme (smmm-*) soruları' }
  $v = OnbellekSoru $Anahtar
  if ($Karar -eq 'ONAY') {
    $kk = $(if ($v.PSObject.Properties['kor_cozum_kaynakli']) { $v.kor_cozum_kaynakli } else { $null })
    if (-not ($kk -and [bool]$kk.dogru_mu)) { throw "ONAY verilemez: $Anahtar için kaynaklı ikinci çözüm doğru değil (kilit 1 kapalı)" }
  }
  $mevcut = @(); if (Test-Path $onayYol) { $mevcut = @(foreach ($o in (Get-Content $onayYol -Raw -Encoding UTF8 | ConvertFrom-Json)) { $o }) }
  $yeni = [pscustomobject][ordered]@{ anahtar = $Anahtar; karar = $Karar; parmak_izi = (SmmmParmakIzi $v); tarih = (Get-Date -Format 'yyyy-MM-dd HH:mm'); kim = 'Cem (sohbette)'; not = $Not }
  $tum = @($mevcut + $yeni)
  [IO.File]::WriteAllText($onayYol, (ConvertTo-Json -InputObject $tum -Depth 4), [Text.UTF8Encoding]::new($false))
  Write-Host "KARAR KAYDEDİLDİ: $Anahtar → $Karar (parmak izi $($yeni.parmak_izi.Substring(0,12))…)" -ForegroundColor Green
  $sonuc = SmmmYayinSarti $Anahtar $v (SmmmOnayHarita $depoKok)
  Write-Host "Yayın şartı şimdi: $(if($sonuc.gecer){'GEÇER'}else{'GEÇMEZ'}) — $($sonuc.neden)"
}

if ($Liste) {
  $onayH = SmmmOnayHarita $depoKok
  $bekleyen = New-Object System.Collections.Generic.List[object]; $atilan = New-Object System.Collections.Generic.List[object]
  foreach ($f in @(Get-ChildItem (Join-Path $depoKok 'veri\fabrika') -Filter 'kalip-parti-smmm-*.json' | Sort-Object Name)) {
    $et = $f.BaseName -replace '^kalip-parti-', ''
    $c = Get-Content $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($p in $c.PSObject.Properties) {
      $v = $p.Value; if (-not $v -or -not $v.soru -or -not $v.PSObject.Properties['kor_cozum'] -or -not $v.kor_cozum) { continue }
      if (SmmmKorDogru $v) { continue }
      $anh = "$et/$($p.Name)"
      $kk = $(if ($v.PSObject.Properties['kor_cozum_kaynakli']) { $v.kor_cozum_kaynakli } else { $null })
      if (-not ($kk -and [bool]$kk.dogru_mu)) { $atilan.Add([pscustomobject]@{ anahtar = $anh; neden = $(if ($kk) { "kaynaklı çözüm de yanlış ($($kk.cevap))" } else { 'kaynaklı ikinci çözüm koşmadı (tuzak şıkkı değil ya da eski kayıt)' }) }); continue }
      # öteki şartlar: kör istisnası dışında her şey sağlanmış mı (istisnayı geçici olarak "onaylı" sayıp bak)
      $sahteOnay = @{}; $sahteOnay[$anh] = [pscustomobject]@{ karar = 'ONAY'; parmak_izi = (SmmmParmakIzi $v); tarih = '-' }
      $digeri = SmmmYayinSarti $anh $v $sahteOnay
      if (-not $digeri.gecer) { $atilan.Add([pscustomobject]@{ anahtar = $anh; neden = "başka şart sağlanmıyor: $($digeri.neden)" }); continue }
      $gecerliKarar = $(if ($onayH.ContainsKey($anh) -and "$($onayH[$anh].parmak_izi)" -eq (SmmmParmakIzi $v)) { "$($onayH[$anh].karar)" } else { '' })
      if ($gecerliKarar) { continue }
      $bekleyen.Add([pscustomobject]@{ anahtar = $anh; v = $v; kk = $kk; eskiKarar = $(if ($onayH.ContainsKey($anh)) { "$($onayH[$anh].karar) (soru değiştiği için geçersiz)" } else { '' }) })
    }
  }
  $md = New-Object System.Text.StringBuilder
  [void]$md.AppendLine('# BİTİRME (SMMM) — CEM ONAY LİSTESİ')
  [void]$md.AppendLine('')
  [void]$md.AppendLine("> Üretim: $(Get-Date -Format 'yyyy-MM-dd HH:mm') · ``arac/smmm-onay.ps1 -Liste`` · bedel 0. Kör çözüm yanıldı ama KANUN METNİYLE çözen model bizim cevabımızı buldu ve öteki bütün şartlar sağlandı. Karar senin: sohbette ""ONAY"" ya da ""RED"" de. Onay, sorunun o anki metnine bağlıdır; soru değişirse düşer.")
  [void]$md.AppendLine('')
  [void]$md.AppendLine("**Onay bekleyen: $($bekleyen.Count)** · Otomatik atılan (kör yanlış, istisna şartı yok): $($atilan.Count)")
  foreach ($b in $bekleyen) {
    $v = $b.v; $korH = "$($v.kor_cozum.cevap)"
    [void]$md.AppendLine(''); [void]$md.AppendLine("---"); [void]$md.AppendLine("## $($b.anahtar) · $($v.konu)$(if($b.eskiKarar){" · ⚠ eski karar $($b.eskiKarar)"})")
    [void]$md.AppendLine(''); [void]$md.AppendLine("**Soru:** $($v.soru)"); [void]$md.AppendLine('')
    foreach ($h in 'A', 'B', 'C', 'D', 'E') { [void]$md.AppendLine("- **$h)** $($v.siklar.$h)$(if($h -eq "$($v.dogru)"){' ← cevap anahtarı'})$(if($h -eq $korH){' ← kör çözümün seçtiği'})") }
    [void]$md.AppendLine('')
    [void]$md.AppendLine("**Kör çözüm (kaynaksız) $korH seçti:** $($v.kor_cozum.hesap)")
    [void]$md.AppendLine('')
    [void]$md.AppendLine("**Kaynaklı ikinci çözüm $($b.kk.cevap) seçti (doğru):** $($b.kk.hesap)$(if("$($b.kk.kaynak_celisti)".Trim()){" · kaynak–ezber çelişkisi: $($b.kk.kaynak_celisti)"})")
    [void]$md.AppendLine('')
    [void]$md.AppendLine("**Bizim tuzak açıklamamız ($korH):** $(if($v.aciklama -and $v.aciklama.$korH){ "$($v.aciklama.$korH)" } else { '-' })")
    [void]$md.AppendLine('')
    [void]$md.AppendLine("**Dayanak:** $($v.dayanak)")
  }
  if ($atilan.Count) { [void]$md.AppendLine(''); [void]$md.AppendLine('---'); [void]$md.AppendLine('## Otomatik atılanlar (yayına girmez, onay istemez)'); foreach ($a in $atilan) { [void]$md.AppendLine("- ``$($a.anahtar)`` — $($a.neden)") } }
  $mdYol = Join-Path $depoKok 'veri\sinav\SMMM-ONAY-LISTESI.md'
  [IO.File]::WriteAllText($mdYol, $md.ToString(), [Text.UTF8Encoding]::new($false))
  Write-Host "ONAY LİSTESİ: bekleyen $($bekleyen.Count) · otomatik atılan $($atilan.Count) → veri/sinav/SMMM-ONAY-LISTESI.md"
}
