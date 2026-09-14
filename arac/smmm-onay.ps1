#requires -Version 5.1
# ============================================================================
#  BİTİRME (SMMM) ONAY LİSTESİ + ONAY KAYDI + HAFTALIK NÖBET   14.09.2026  (bedel 0)
#
#  Cem 14.09: "(a) + kaynaklı ikinci çözüm + senin onayın ... siteye yanlış bir soru girmesini istemiyorum".
#  -Liste  : smmm-* sorularından onay bekleyenleri bulur → veri/fabrika/SMMM-ONAY-LISTESI.md
#            (veri/fabrika gitignore'da: depo HERKESE AÇIK, soru metni depoya girmez)
#            Aday = kör çözüm yanlış ∧ kaynaklı ikinci çözüm DOĞRU ∧ öteki bütün yayın şartları sağlanmış
#            (arac/smmm-yayin-sarti.ps1) ∧ geçerli (parmak izi tutan) karar yok.
#  -Ambar  : önbellek yerel dosyadan değil ambardaki kalip_parti tablosundan okunur (bulut nöbeti).
#  -Mail   : bekleyen kart varsa ve bu kart takımı (anahtar+parmak izi) daha önce bildirilmediyse Cem'e tek mail
#            (Resend). Bildirilen takım veri/smmm-onay-bildirim.json'a yazılır (yalnız anahtar + parmak izi).
#            Cem 14.09 "1 ve 2 yap" (GM önerisi 2: onay listesi haftalık robota bağlansın, gözden kaçmasın).
#  -Anahtar etiket/id -Karar ONAY|RED -Not "...": Cem'in SOHBETTE verdiği kararı kaydeder
#            (veri/sinav/smmm-insan-onay.json). Parmak izi o anki soru+şıklar+cevaptan alınır.
#            ONAY yalnız kaynaklı ikinci çözümü doğru olan soruya yazılabilir.
#  Kararı ASLA robot ya da model vermez; kayıt yalnız Cem'in açık kararıyla koşulur.
# ============================================================================
param([switch]$Liste, [switch]$Ambar, [switch]$Mail, [switch]$MailYok, [string]$Anahtar = '', [ValidateSet('', 'ONAY', 'RED')][string]$Karar = '', [string]$Not = '')
$ErrorActionPreference = 'Stop'
$depoKok = Split-Path -Parent $PSScriptRoot
. (Join-Path (Join-Path $depoKok 'arac') 'smmm-yayin-sarti.ps1')
$onayYol = Join-Path (Join-Path (Join-Path $depoKok 'veri') 'sinav') 'smmm-insan-onay.json'
$fabrika = Join-Path (Join-Path $depoKok 'veri') 'fabrika'
$bildirimYol = Join-Path (Join-Path $depoKok 'veri') 'smmm-onay-bildirim.json'

function OnbellekSoru([string]$anahtarS) {
  $parca = $anahtarS -split '/', 2
  $cf = Join-Path $fabrika "kalip-parti-$($parca[0]).json"
  if (-not (Test-Path $cf)) { throw "önbellek yok: $cf" }
  $c = Get-Content $cf -Raw -Encoding UTF8 | ConvertFrom-Json
  if (-not $c.PSObject.Properties[$parca[1]]) { throw "soru yok: $anahtarS" }
  return $c.($parca[1])
}

# etiket → önbellek nesnesi (yerel dosyalardan ya da ambardan)
function SmmmPartiler {
  $partiler = New-Object System.Collections.Generic.List[object]
  if ($Ambar) {
    $anahtarAmbar = "$($env:SUPABASE_SERVICE_KEY)".Trim()
    if (-not $anahtarAmbar) { $anahtarAmbar = "$([Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'))".Trim() }
    if (-not $anahtarAmbar) { throw 'SUPABASE_SERVICE_KEY yok' }
    $basliklar = @{ apikey = $anahtarAmbar; Authorization = "Bearer $anahtarAmbar"; Accept = 'application/json'; 'User-Agent' = 'mevzuat-radar-robot/1.0' }
    $kayma = 0
    while ($true) {
      $adres = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/kalip_parti?select=etiket,icerik&etiket=like.smmm-*&order=etiket.asc&limit=50&offset=' + $kayma
      $cevapAmbar = $null
      foreach ($deneme in 1..3) { try { $cevapAmbar = Invoke-RestMethod -Uri $adres -Headers $basliklar -TimeoutSec 120; break } catch { if ($deneme -eq 3) { throw "ambar okunamadı: $($_.Exception.Message)" }; Start-Sleep -Seconds (10 * $deneme) } }
      $sayfa = @(foreach ($satirA in $cevapAmbar) { $satirA })   # PS 5.1: dizi tek öğeye sarılmasın
      foreach ($satirA in $sayfa) { if ($satirA.icerik) { $partiler.Add([pscustomobject]@{ etiket = "$($satirA.etiket)"; c = $satirA.icerik }) } }
      if ($sayfa.Count -lt 50) { break }
      $kayma += 50
    }
  }
  else {
    foreach ($f in @(Get-ChildItem $fabrika -Filter 'kalip-parti-smmm-*.json' -ErrorAction SilentlyContinue | Sort-Object Name)) {
      $partiler.Add([pscustomobject]@{ etiket = ($f.BaseName -replace '^kalip-parti-', ''); c = (Get-Content $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json) })
    }
  }
  return , $partiler
}

function HtmlKacis([string]$metin) { return "$metin".Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;') }

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
  $partiListesi = SmmmPartiler
  foreach ($parti in $partiListesi) {
    $et = $parti.etiket; $c = $parti.c
    foreach ($p in $c.PSObject.Properties) {
      $v = $p.Value; if (-not $v -or $v -is [string] -or -not $v.PSObject.Properties['soru'] -or -not $v.soru -or -not $v.PSObject.Properties['kor_cozum'] -or -not $v.kor_cozum) { continue }
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
      $bekleyen.Add([pscustomobject]@{ anahtar = $anh; v = $v; kk = $kk; parmak = (SmmmParmakIzi $v); eskiKarar = $(if ($onayH.ContainsKey($anh)) { "$($onayH[$anh].karar) (soru değiştiği için geçersiz)" } else { '' }) })
    }
  }
  $md = New-Object System.Text.StringBuilder
  $html = New-Object System.Text.StringBuilder
  [void]$md.AppendLine('# BİTİRME (SMMM) — CEM ONAY LİSTESİ')
  [void]$md.AppendLine('')
  $girisMetni = "Üretim: $(Get-Date -Format 'yyyy-MM-dd HH:mm') · arac/smmm-onay.ps1 -Liste · bedel 0. Kör çözüm yanıldı ama KANUN METNİYLE çözen model bizim cevabımızı buldu ve öteki bütün şartlar sağlandı. Karar senin: sohbette ""ONAY"" ya da ""RED"" de. Onay, sorunun o anki metnine bağlıdır; soru değişirse düşer."
  [void]$md.AppendLine("> $girisMetni")
  [void]$md.AppendLine('')
  [void]$md.AppendLine("**Onay bekleyen: $($bekleyen.Count)** · Otomatik atılan (kör yanlış, istisna şartı yok): $($atilan.Count)")
  [void]$html.Append("<h3>Bitirme (SMMM) — onay bekleyen $($bekleyen.Count) soru</h3><p>$(HtmlKacis $girisMetni)</p>")
  foreach ($b in $bekleyen) {
    $v = $b.v; $korH = "$($v.kor_cozum.cevap)"
    $tuzakMetni = $(if ($v.aciklama -and $v.aciklama -isnot [string] -and $v.aciklama.PSObject.Properties[$korH]) { "$($v.aciklama.$korH)" } else { '-' })
    $celiski = $(if ("$($b.kk.kaynak_celisti)".Trim()) { " · kaynak–ezber çelişkisi: $($b.kk.kaynak_celisti)" } else { '' })
    [void]$md.AppendLine(''); [void]$md.AppendLine("---"); [void]$md.AppendLine("## $($b.anahtar) · $($v.konu)$(if($b.eskiKarar){" · ⚠ eski karar $($b.eskiKarar)"})")
    [void]$md.AppendLine(''); [void]$md.AppendLine("**Soru:** $($v.soru)"); [void]$md.AppendLine('')
    [void]$html.Append("<hr><h4>$(HtmlKacis $b.anahtar) · $(HtmlKacis $v.konu)$(if($b.eskiKarar){" · ⚠ eski karar $(HtmlKacis $b.eskiKarar)"})</h4><p><b>Soru:</b> $(HtmlKacis $v.soru)</p><ul>")
    foreach ($h in 'A', 'B', 'C', 'D', 'E') {
      $isaret = "$(if($h -eq "$($v.dogru)"){' ← cevap anahtarı'})$(if($h -eq $korH){' ← kör çözümün seçtiği'})"
      [void]$md.AppendLine("- **$h)** $($v.siklar.$h)$isaret")
      [void]$html.Append("<li><b>$h)</b> $(HtmlKacis $v.siklar.$h)<i>$(HtmlKacis $isaret)</i></li>")
    }
    [void]$md.AppendLine('')
    [void]$md.AppendLine("**Kör çözüm (kaynaksız) $korH seçti:** $($v.kor_cozum.hesap)"); [void]$md.AppendLine('')
    [void]$md.AppendLine("**Kaynaklı ikinci çözüm $($b.kk.cevap) seçti (doğru):** $($b.kk.hesap)$celiski"); [void]$md.AppendLine('')
    [void]$md.AppendLine("**Bizim tuzak açıklamamız ($korH):** $tuzakMetni"); [void]$md.AppendLine('')
    [void]$md.AppendLine("**Dayanak:** $($v.dayanak)")
    [void]$html.Append("</ul><p><b>Kör çözüm (kaynaksız) $korH seçti:</b> $(HtmlKacis $v.kor_cozum.hesap)</p><p><b>Kaynaklı ikinci çözüm $($b.kk.cevap) seçti (doğru):</b> $(HtmlKacis $b.kk.hesap)$(HtmlKacis $celiski)</p><p><b>Bizim tuzak açıklamamız ($korH):</b> $(HtmlKacis $tuzakMetni)</p><p><b>Dayanak:</b> $(HtmlKacis $v.dayanak)</p>")
  }
  if ($atilan.Count) { [void]$md.AppendLine(''); [void]$md.AppendLine('---'); [void]$md.AppendLine('## Otomatik atılanlar (yayına girmez, onay istemez)'); foreach ($a in $atilan) { [void]$md.AppendLine("- ``$($a.anahtar)`` — $($a.neden)") } }
  New-Item -ItemType Directory -Force $fabrika | Out-Null
  $mdYol = Join-Path $fabrika 'SMMM-ONAY-LISTESI.md'
  [IO.File]::WriteAllText($mdYol, $md.ToString(), [Text.UTF8Encoding]::new($false))
  Write-Host "ONAY LİSTESİ: bekleyen $($bekleyen.Count) · otomatik atılan $($atilan.Count) → veri/fabrika/SMMM-ONAY-LISTESI.md (depoya girmez)"

  if ($Mail) {
    $takim = @($bekleyen | ForEach-Object { "$($_.anahtar)|$($_.parmak)" } | Sort-Object)
    $eskiTakim = @(); if (Test-Path $bildirimYol) { try { $eskiTakim = @(foreach ($x in (Get-Content $bildirimYol -Raw -Encoding UTF8 | ConvertFrom-Json).bildirilen) { "$x" }) } catch { $eskiTakim = @() } }
    $yeniKart = @($takim | Where-Object { $eskiTakim -notcontains $_ })
    $mailDurum = 'gerek yok (bekleyen yok ya da hepsi daha önce bildirildi)'
    if ($yeniKart.Count) {
      if ($MailYok) { $mailDurum = 'gitmedi (-MailYok prova)' }
      elseif (-not $env:RESEND_KEY -or -not $env:RESEND_FROM) { $mailDurum = 'gitmedi (RESEND_KEY/RESEND_FROM yok)' }
      else {
        try {
          $govde = @{ from = $env:RESEND_FROM; to = @('cemdizdar85@hotmail.com'); subject = "Tetikte: bitirme onay listesinde $($bekleyen.Count) soru kararını bekliyor"; html = $html.ToString(); text = $md.ToString() } | ConvertTo-Json -Depth 3
          Invoke-RestMethod -Method Post -Uri 'https://api.resend.com/emails' -Headers @{ Authorization = ('Bearer ' + ("$env:RESEND_KEY" -replace '[^\x21-\x7e]', '')) } -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -ContentType 'application/json' -TimeoutSec 60 | Out-Null
          $mailDurum = 'gönderildi'
        } catch { $mailDurum = "gitmedi (Resend hatası: $($_.Exception.Message))" }
      }
    }
    Write-Host "MAIL: $mailDurum"
    # bildirim kütüğü yalnız mail gittiyse ve takım değiştiyse yazılır (boş commit üretmez)
    if ($mailDurum -eq 'gönderildi') {
      [IO.File]::WriteAllText($bildirimYol, (ConvertTo-Json -InputObject ([ordered]@{ not = 'yalnız anahtar + parmak izi; soru metni burada tutulmaz (depo herkese açık)'; son_bildirim = (Get-Date -Format 'yyyy-MM-dd HH:mm'); bildirilen = @($takim) }) -Depth 3), [Text.UTF8Encoding]::new($false))
    }
    if ($mailDurum -like 'gitmedi (Resend*' ) { exit 1 }
  }
}
