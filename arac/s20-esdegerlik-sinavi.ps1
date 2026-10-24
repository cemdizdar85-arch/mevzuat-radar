#requires -Version 5.1
# ============================================================================
#  S20 İSTEM EŞDEĞERLİĞİ SINAVI (24.10.2026) — 0 USD, model çağrısı YOK
#  Soru: s20 bulut işlerinin modele göndereceği istek, üretimdekiyle BAYTI BAYTINA aynı mı?
#
#  A · KÖR KALİBRASYON (girdinin TAMAMI, örneklem yok):
#    yol 1 = arac/s20-kor-cekirdek.ps1 (üreticiden AST ile alınan deyimler) → S20DalgaKos → Invoke-ClaudeToplu → İSTEM DÖKÜMÜ
#    yol 2 = BAĞIMSIZ kurulum: motor/kalip-parti-uret.ps1 HAM METNİNDEN düzenli ifadeyle $korIstem / $KOR_MAXTOK / $KorModel okunur,
#            şık listesi + Replace zinciri burada ayrıca yazılır, üreticinin TopluTopla iş kaydı biçimiyle Invoke-ClaudeToplu
#            (SGS: -OnbelleksizToplu YOK) → İSTEM DÖKÜMÜ
#    iki döküm satır satır kıyaslanır: istem metni SHA-256 (tumSha), blok yapısı + önbellek işareti, model, maxTok, effort, parmak izi.
#    ayrıştırıcı: çekirdeğe yüklenen Coz/KorCoz metni üretici dosyasında AYNEN geçmeli + 6 örnek cevapla davranış sınaması.
#  B · AÇIKLAMA HAKEMİ (verilen aday dosyasının TAMAMI):
#    yol 1 = s20-ah-banka yolu (S20AhUretimAyari + AciklamaHakemIs + S20DalgaKos) → İSTEM DÖKÜMÜ
#    yol 2 = ÜRETİMİN KENDİSİ: arac/aciklama-hakemi-uretim.ps1 AciklamaHakemUretim, geçici fabrika klasöründe (aynı kayıtlar; yalnız
#            seçim kapısını geçsin diye hakem/hakem2 alanları EVET — bu alanlar istemde YOK) → İSTEM DÖKÜMÜ
#  Döküm, api-hedef MEVZUAT_ISTEM_DOK yoludur: istek GÖNDERİLMEZ, bedel 0. Ambar yalnız okunur (B: istenen kayıtlar).
#  Kullanım: powershell -NoProfile -File arac/s20-esdegerlik-sinavi.ps1 [-KorGirdi <json>] [-AhGirdi <json>] [-Yalniz A|B]
#  Öz-sınav: S20_SINAMA_MUTASYON=A (istem şablonunda iki kelime) / =B (bir istemin sonuna tek boşluk) → çıkış 1 olmalı.
#  Çıkış: 0 = tümü eşit · 1 = fark var (bulut iş akışı bu durumda PARALI adıma GEÇMEZ)
#  🚫 GÖRMEZ: modelin aynı istemde aynı cevabı vermesi (olasılıksal; sınav yalnız giden isteği kıyaslar) · üretimde plan satırının
#    korModel/korKaynak vermesi (s20 planlarında yok) · B'de üretim anındaki yerel dosya ile ambar kopyasının anahtar SIRASI farkı.
# ============================================================================
param([string]$KorGirdi = 'veri/sinav/s20-kalibrasyon-cikmis3.json', [string]$KorModel = '', [string]$AhGirdi = '', [ValidateSet('', 'A', 'B')][string]$Yalniz = '')
$ErrorActionPreference = 'Stop'
$depoKok = Split-Path -Parent $PSScriptRoot
Set-Location $depoKok
. (Join-Path $depoKok 'motor\api-hedef.ps1')
. (Join-Path $PSScriptRoot 's20-ortak.ps1')
$gecici = Join-Path $(if ($env:RUNNER_TEMP) { $env:RUNNER_TEMP } else { [IO.Path]::GetTempPath() }) ("s20-esdeger-" + (Get-Date -Format 'yyyyMMddHHmmss'))
New-Item -ItemType Directory -Force $gecici | Out-Null
$fark = 0
function DokOku([string]$y) { if (-not (Test-Path $y)) { return @() }; return @([IO.File]::ReadAllLines($y, [Text.Encoding]::UTF8) | Where-Object { $_.Trim() } | ForEach-Object { ConvertFrom-Json -InputObject $_ }) }
$script:BEKLENEN_FARK = @{}
function DokKiyas($d1, $d2, [string]$ad, [string[]]$beklenen = @()) {
  $f = 0
  if ($d1.Count -ne $d2.Count) { Write-Host "  !! $ad : döküm satır sayısı farklı ($($d1.Count) / $($d2.Count))" -ForegroundColor Red; return 1 }
  for ($i = 0; $i -lt $d1.Count; $i++) {
    $a = $d1[$i]; $b = $d2[$i]
    $blA = (@($a.bloklar | ForEach-Object { "$($_.boy):$($_.sha):$($_.onbellek)" }) -join '|'); $blB = (@($b.bloklar | ForEach-Object { "$($_.boy):$($_.sha):$($_.onbellek)" }) -join '|')
    foreach ($alan in @(@('tumSha', $a.tumSha, $b.tumSha), @('model', $a.model, $b.model), @('maxTok', $a.maxTok, $b.maxTok), @('effort', $a.effort, $b.effort), @('parmak', $a.parmak, $b.parmak), @('bloklar', $blA, $blB))) {
      if ("$($alan[1])" -cne "$($alan[2])" -and $beklenen -contains $alan[0]) { $script:BEKLENEN_FARK[$alan[0]] = 1 + [int]$script:BEKLENEN_FARK[$alan[0]]; continue }
      if ("$($alan[1])" -cne "$($alan[2])") { $f++; if ($f -le 5) { Write-Host ("  !! {0} satır {1} ({2} / {3}): {4} farklı" -f $ad, $i, $a.id, $b.id, $alan[0]) -ForegroundColor Red } }
    }
  }
  return $f
}

if ($Yalniz -ne 'B') {
  Write-Host "=== A · KÖR KALİBRASYON İSTEMİ ===" -ForegroundColor Cyan
  . (Join-Path $PSScriptRoot 's20-kor-cekirdek.ps1')
  $sorular = @((S20Json $KorGirdi) | ForEach-Object { $_ })
  # yol 1: çekirdek + gerçek gönderim yolu (S20DalgaKos → Invoke-ClaudeToplu), döküme
  # -KorModel (emir cozucu_model): yol 1 o modelle kurulur; MODEL alanı farkı BEKLENEN fark sayılır, istem farkı yine 0 olmalı
  $isler1 = @(foreach ($q in $sorular) { S20KorIs "$($q.id)" $q $KorModel })
  $tt = S20Tahmin $isler1 500
  $env:MEVZUAT_ISTEM_DOK = Join-Path $gecici 'kor-yol1.jsonl'
  [void](S20DalgaKos -Isler $isler1 -Tahmin $tt.tahmin -EnKotu $tt.enKotu -Tavan 1e9 -Etiket 'sgs-s20-kalibrasyon/sinama' -IlkDalga 30 -Onbelleksiz $false -BeklemeDk 1)
  # yol 2: ham metinden bağımsız kurulum
  $ham = [IO.File]::ReadAllText((Join-Path $depoKok 'motor/kalip-parti-uret.ps1'), [Text.Encoding]::UTF8)
  $mI = [regex]::Matches($ham, "(?m)^\`$korIstem=@'\r?\n([\s\S]*?)\r?\n'@"); if ($mI.Count -ne 1) { throw "yol 2: `$korIstem here-string'i $($mI.Count) kez" }
  $sablon2 = $mI[0].Groups[1].Value
  $mT = [regex]::Matches($ham, '(?m)^\$KOR_MAXTOK=(\d+)\s*$'); if ($mT.Count -ne 1) { throw 'yol 2: $KOR_MAXTOK' }
  $mM = [regex]::Matches($ham, "\[string\]\`$KorModel='([^']+)'"); if ($mM.Count -ne 1) { throw 'yol 2: $KorModel' }
  $maxTok2 = [int]$mT[0].Groups[1].Value; $model2 = $mM[0].Groups[1].Value
  if ("$env:S20_SINAMA_MUTASYON" -eq 'A') { $sablon2 = $sablon2.Replace('çok titiz', 'titiz') }   # öz-sınav: sınav farkı GÖRÜYOR mu
  # üretici satır ~5186/5193/5198 ile aynı anlam, ayrı yazım: "A) metin" satırları LF ile; {KAYNAK} kaynaksız yolda boş
  $isler2 = @(foreach ($q in $sorular) {
      $sk = New-Object System.Collections.Generic.List[string]; foreach ($h in 'A', 'B', 'C', 'D', 'E') { $sk.Add($h + ') ' + [string]$q.siklar.$h) }
      $ist = $sablon2.Replace('{SORU}', [string]$q.soru).Replace('{SIKLAR}', ($sk -join "`n")).Replace('{KAYNAK}', '')
      @{ id = "$($q.id)"; model = $model2; icerik = $ist; maxTok = $maxTok2; effort = ''; faz = 'K' }   # TopluTopla iş kaydı biçimi
    })
  $env:MEVZUAT_ISTEM_DOK = Join-Path $gecici 'kor-yol2.jsonl'
  [void](Invoke-ClaudeToplu -Isler $isler2 -Etiket 'sgs-s20-sinama/K' -BeklemeDk 1 -OnbelleksizToplu:$false -ParmakTuz '')
  Remove-Item Env:\MEVZUAT_ISTEM_DOK
  $d1 = DokOku (Join-Path $gecici 'kor-yol1.jsonl'); $d2 = DokOku (Join-Path $gecici 'kor-yol2.jsonl')
  $esit = 0; for ($i = 0; $i -lt [math]::Min($isler1.Count, $isler2.Count); $i++) { if ([string]$isler1[$i].icerik -ceq [string]$isler2[$i].icerik) { $esit++ } }
  $bekA = @(); if ($KorModel -and $KorModel -ne $model2) { $bekA = @('model') }
  $fA = DokKiyas $d1 $d2 'A' $bekA
  # effort kapısı: api-hedef toplu yolu effort'u yalnız şu kalıba uyan modele koyar (döküm effort'u kalıba bakmadan yazar → ayrıca denetlenir)
  $apiHam = [IO.File]::ReadAllText((Join-Path $depoKok 'motor/api-hedef.ps1'), [Text.Encoding]::UTF8)
  $mE = [regex]::Match($apiHam, 'if\("\$\(\$i\.model\)" -match ''([^'']+)''\)\{ \$g\.output_config')
  if (-not $mE.Success) { $fA++; Write-Host '  !! A: api-hedef toplu effort kapısı bulunamadı' -ForegroundColor Red }
  $efM = $(if ($KorModel) { $KorModel } else { $model2 }); $efGider = ($mE.Success -and $efM -match $mE.Groups[1].Value)
  if ($esit -ne $sorular.Count) { $fA++ }
  Write-Host ("  A: {0} soru · istem dizesi birebir eşit {1}/{0} · döküm satırı {2}/{3} · istek alanı farkı {4} · üretim modeli {5} · çözücü modeli {6} · maxTok {7} · effort {8}" -f $sorular.Count, $esit, $d1.Count, $d2.Count, $fA, $model2, $efM, $maxTok2, $(if ($efGider) { "gönderilir ($($d1[0].effort))" } else { "GÖNDERİLMEZ (api-hedef kalıbı '$($mE.Groups[1].Value)')" }))
  if ($script:BEKLENEN_FARK.Count) { Write-Host ("  A: BEKLENEN fark (emir cozucu_model): " + (($script:BEKLENEN_FARK.GetEnumerator() | ForEach-Object { "$($_.Key) $($_.Value) satır" }) -join ', ') + " — istem/blok/parmak/maxTok farkı 0 olmalı") -ForegroundColor Yellow }
  # ayrıştırıcı: yüklenen metin üreticide AYNEN var mı + davranış
  foreach ($fn in 'Coz', 'KorCoz') { $t = (Get-Variable -Scope Script -Name "S20_FN_$fn").Value; if (-not $ham.Contains($t)) { $fA++; Write-Host "  !! A: $fn metni üreticide aynen YOK" -ForegroundColor Red } }
  $q0 = [pscustomobject]@{ dogru = 'C' }
  $ornek = @(
    @('{"cevap":"C","sonuc":"5","hesap":"x","guven":"yüksek","kusur":"","kaynak_celisti":""}', 'C', $true),
    @('Önce hesaplayalım... sonuç 5. {"cevap":"B","sonuc":"5","hesap":"x","guven":"orta","kusur":"","kaynak_celisti":""}', 'B', $false),
    @("``````json`n{""cevap"":""c"",""sonuc"":""5""}`n``````", 'C', $true),
    @('{"cevap":"HİÇBİRİ","sonuc":"7"}', 'HİÇBİRİ', $false),
    @('{"cevap":"C) 5 TL","sonuc":"5"}', 'C', $true),
    @('cevap veremedim', $null, $null))
  foreach ($o in $ornek) { $k = S20KorKarar $q0 $o[0]; $c = $(if ($k) { $k.cevap } else { $null }); $dm = $(if ($k) { [bool]$k.dogru_mu } else { $null }); if ("$c" -cne "$($o[1])" -or "$dm" -ne "$($o[2])") { $fA++; Write-Host "  !! A ayrıştırıcı: '$($o[0].Substring(0,[math]::Min(40,$o[0].Length)))' → $c/$dm (beklenen $($o[1])/$($o[2]))" -ForegroundColor Red } }
  Write-Host ("  A SONUÇ: {0}" -f $(if ($fA) { "FARK $fA" } else { 'EŞİT (istem, istek alanları, ayrıştırıcı)' })) -ForegroundColor $(if ($fA) { 'Red' } else { 'Green' })
  $fark += $fA
}

if ($Yalniz -ne 'A' -and $AhGirdi) {
  Write-Host "=== B · AÇIKLAMA HAKEMİ İSTEMİ ===" -ForegroundColor Cyan
  . (Join-Path $PSScriptRoot 'aciklama-hakemi-cekirdek.ps1')
  $AH = S20AhUretimAyari (Join-Path $PSScriptRoot 'aciklama-hakemi-uretim.ps1')
  $sira = @((S20Json $AhGirdi) | ForEach-Object { "$($_.soru_id)".Trim() } | Where-Object { $_ } | Select-Object -Unique)
  $kayit = S20AmbarKayit $sira
  $var = @($sira | Where-Object { $kayit.ContainsKey($_) -and $kayit[$_].soru })
  # yol 1: s20-ah-banka yolu
  $isler1 = @(foreach ($sid in $var) { AciklamaHakemIs (S20AhId $sid) $kayit[$sid] $AH.model $AH.effort $AH.maxTok })
  if ("$env:S20_SINAMA_MUTASYON" -eq 'B' -and $isler1.Count) { $isler1[0].icerik[0].text += ' ' }   # öz-sınav: tek boşluk farkı görülmeli
  $tt = S20Tahmin $isler1 900
  $env:MEVZUAT_ISTEM_DOK = Join-Path $gecici 'ah-yol1.jsonl'
  [void](S20DalgaKos -Isler $isler1 -Tahmin $tt.tahmin -EnKotu $tt.enKotu -Tavan 1e9 -Etiket 'sgs-s20-ah-banka/sinama' -IlkDalga 30 -Onbelleksiz $AH.onbelleksiz -BeklemeDk 1)
  # yol 2: AciklamaHakemUretim'in kendisi, geçici fabrikada (her soru kendi etiketinde, sırası korunur)
  $fab = Join-Path $gecici 'fabrika'; New-Item -ItemType Directory -Force $fab | Out-Null
  $satir = New-Object System.Collections.Generic.List[object]; $n = 0
  foreach ($sid in $var) {
    $n++; $k = ConvertFrom-Json -InputObject (ConvertTo-Json -InputObject $kayit[$sid] -Depth 30)
    foreach ($ad in 'aciklama_hakem', 'simulasyon', 'simulasyon_sonnet') { if ($k.PSObject.Properties[$ad]) { $k.PSObject.Properties.Remove($ad) } }
    $k | Add-Member -NotePropertyName hakem -NotePropertyValue ([pscustomobject]@{ karar = 'EVET' }) -Force
    $k | Add-Member -NotePropertyName hakem2 -NotePropertyValue ([pscustomobject]@{ karar = 'EVET'; tarih = '2026-10-24' }) -Force
    $et = "s20sinama$('{0:d4}' -f $n)"; $kp = ($sid -split '/', 2)[1]
    $par = [ordered]@{}; $par[$kp] = $k
    [IO.File]::WriteAllText((Join-Path $fab "kalip-parti-$et.json"), (ConvertTo-Json -InputObject $par -Depth 30), [Text.UTF8Encoding]::new($false))
    $satir.Add([pscustomobject]@{ etiket = $et })
  }
  $env:AH_BASLANGIC = '2000-01-01'   # yalnız seçim kapısı (AhYeniMi); istemi etkilemez
  . (Join-Path $PSScriptRoot 'aciklama-hakemi-uretim.ps1')
  $env:MEVZUAT_ISTEM_DOK = Join-Path $gecici 'ah-yol2.jsonl'
  $eskiButce = $env:MEVZUAT_BUTCE_USD; Remove-Item Env:\MEVZUAT_BUTCE_USD -ErrorAction SilentlyContinue
  $rp = AciklamaHakemUretim $depoKok $satir.ToArray() 0 $fab
  Remove-Item Env:\MEVZUAT_ISTEM_DOK; Remove-Item Env:\AH_BASLANGIC; if ($eskiButce) { $env:MEVZUAT_BUTCE_USD = $eskiButce }
  $d1 = DokOku (Join-Path $gecici 'ah-yol1.jsonl'); $d2 = DokOku (Join-Path $gecici 'ah-yol2.jsonl')
  $fB = DokKiyas $d1 $d2 'B'
  if ($d1.Count -ne $var.Count -or [int]$rp.aday -ne $var.Count) { $fB++ }
  Write-Host ("  B: {0} aday · ambarda {1} · üretim yolu aday {2} · döküm satırı {3}/{4} · istek alanı farkı {5} · model {6} · effort {7} · maxTok {8} · önbelleksiz {9}" -f $sira.Count, $var.Count, $rp.aday, $d1.Count, $d2.Count, $fB, $AH.model, $AH.effort, $AH.maxTok, $(if ($d1.Count) { -not [bool]@($d1[0].bloklar | Where-Object { $_.onbellek }).Count } else { '?' }))
  Write-Host ("  B SONUÇ: {0}" -f $(if ($fB) { "FARK $fB" } else { 'EŞİT (üretim işleviyle istek alanları birebir)' })) -ForegroundColor $(if ($fB) { 'Red' } else { 'Green' })
  $fark += $fB
} elseif ($Yalniz -ne 'A') { Write-Host "B: aday dosyası verilmedi (-AhGirdi) — atlandı" }

Remove-Item -Recurse -Force $gecici -ErrorAction SilentlyContinue
if ($fark) { Write-Host "EŞDEĞERLİK DÜŞTÜ ($fark fark) — paralı koşu YAPILMAMALI" -ForegroundColor Red; exit 1 }
Write-Host "EŞDEĞERLİK: TAMAM (0 USD)" -ForegroundColor Green
exit 0
