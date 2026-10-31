#requires -Version 5.1
# ============================================================================
#  SMMM (BİTİRME) — YALNIZ AÇIKLAMA DENETİMİ YOLU (31.10.2026, Cem "13 açıklamanın denetimi: (b)")   PARALI yalnız -Calistir ile, hep TOPLU
#
#  Cem: "Bitirme hattına ayrı 'yalnız açıklama denetimi' yolu yaz; SGS dosyalarına ve SGS oturumuna dokunma. ... Bu yol kalıcı olsun,
#  ileride bulunacak açıklama hataları da buradan geçsin." + "Hakemin 'kusurlu' dediği her soruyu resmî metinle okumadan kabul etme;
#  ilgili madde metnini ambardan hakeme ver."
#  NE: açıklaması onarılmış SMMM sorularını (eski ya da yeni) açıklama hakemine (AH) okutur, kararı AMBARDAKİ kayda 'aciklama_hakem'
#   olarak yazar (onarım hattının alanı: arac/onarim-hatti.js gecmeNedeni + arac/smmm-yayin-sarti.ps1 aynı alanı okur).
#  HAKEM: arac/aciklama-hakemi-cekirdek.ps1 AciklamaHakemIs (istem) + AciklamaHakemKarar (ayrıştırıcı) AYNEN çağrılır; model, effort,
#   jeton tavanı ve önbelleksiz toplu bayrağı arac/aciklama-hakemi-uretim.ps1 AciklamaHakemUretim gövdesinden AST ile okunur (kopya yok,
#   kısma yok). Çekirdek DEĞİŞMEZ: istemin SONUNA "RESMÎ MADDE METNİ" bölümü + madde metni kuralı eklenir (çıktı biçimi aynı).
#   31.10 ÖLÇÜLDÜ: AH 17 kararın 4'ünde madde metnini görmeden yanlış bent/fıkra iddia etti (VUK 30/3, VUK 118/2, KVK 2/6, ÖTVK 4/1).
#  VERİ: arac/smmm-ah-yalniz.js (ambar okuma, tazelik, madde metni, koşullu yazım, geri okuma). Ayrıntı orada.
#  GİRDİ: veri/sinav/smmm-ah-yalniz-girdi-<ad>.json (node arac/smmm-ah-yalniz.js girdi <onarım klasörü> --ad <ad>) ya da kimlik listesi
#   [{soru_id}] / ["<etiket>/<kp>"]; -Dayanak {"<etiket>/<kp>":[{kaynak_ad, alinti}]} isteğe bağlı.
#  PARA: -ButceUsd ZORUNLU (paralı koşu). En kötü durum = girdi karakter/1,6 jeton + çıktı maxTok, toplu yarı fiyat (üretimle aynı formül);
#   bütçeyi aşarsa HİÇ BAŞLAMAZ (çıkış 4). Soru başı en kötü ≈0,05–0,06 USD (madde metniyle). Bedel bedel_kaydi'na etiket
#   "smmm-ah-yalniz/<ad>" (SMMM), ders 'aciklama-hakemi'. Anlık yola DÜŞÜLMEZ: toplu bekleme dolarsa hiçbir şey yazılmaz, çıkış 75
#   (yeniden koşu kuyruktaki partiye bağlanır / bitmişse bedava hasat eder — aynı istek ikinci kez ödenmez).
#  ÇIKTI: ambardaki kayıtta aciklama_hakem {karar, kusurlar, model, tarih, yol, kosu, icerik_sha, madde_kaynak, madde_adlari, …};
#   KUSURLU → kaynak_okundu:false + incelenecek:true (resmî metinle okunmadan "geçmedi" sayılmaz). Sonuç dosyası
#   veri/sinav/smmm-ah-yalniz-sonuc-<ad>.json (kimlik + karar + kusur ALAN adı; gerekçe yalnız ambarda — depo PUBLIC).
#  ÇIKIŞ: 0 tamam · 1 hata · 3 yarış (damga değişti, HİÇBİR ŞEY yazılmadı) · 4 bütçe yetmez (başlamadı) · 75 toplu kuyruk bitmedi
#  KULLANIM:
#    powershell -NoProfile -File arac/smmm-ah-yalniz.ps1 -Girdi veri/sinav/smmm-ah-yalniz-girdi-<ad>.json                 (KURU, 0 USD)
#    powershell -NoProfile -File arac/smmm-ah-yalniz.ps1 -Girdi … -ButceUsd 0.70 -Calistir                                 (PARALI)
#    bulut: .github/workflows/smmm-ah-yalniz.yml (workflow_dispatch: girdi, butce_usd, calistir)
#  Öz-sınav: powershell -NoProfile -File arac/smmm-ah-yalniz-sinavi.ps1 (sahte ambar + sahte model, ağ yok)
#  🚫 GÖRMEZ: kararın doğruluğu (KUSURLU elle okunur) · ambarda olmayan madde metni (kaynaksiz işaretlenir) · yayın (bu yol yayını
#    DEĞİŞTİRMEZ; eski soruda yayın şartı AH aramaz, onarım hattı 'hakem' komutu TEMIZ'i elle ret çıkışında kullanır).
# ============================================================================
param(
  [Parameter(Mandatory = $true)][string]$Girdi,
  [string]$Dayanak = '',
  [double]$ButceUsd = 0,
  [switch]$Calistir,
  [switch]$Yeniden,
  [switch]$UstuneYaz,
  [int]$BeklemeDk = 290,
  [int]$MaddeKr = 4000,
  [string]$KosuAd = '',
  [string]$SonucYolu = ''
)
$ErrorActionPreference = 'Stop'
$depoKok = Split-Path -Parent $PSScriptRoot
. (Join-Path $depoKok 'motor/api-hedef.ps1')
. (Join-Path $depoKok 'motor/model-kod.ps1')
. (Join-Path $depoKok 'arac/aciklama-hakemi-cekirdek.ps1')
$jsArac = Join-Path $depoKok 'arac/smmm-ah-yalniz.js'
$sahteDizin = "$env:SMMM_AH_SAHTE"   # yalnız öz-sınav: sahte ambar + sahte model (ağ yok, para yok)

function SmmmAhUretimAyari([string]$yol) {
  $tk = $null; $hh = $null
  $ast = [System.Management.Automation.Language.Parser]::ParseFile($yol, [ref]$tk, [ref]$hh)
  if ($hh -and @($hh).Count) { throw "AH: üretim dosyası ayrıştırılamadı: $(@($hh)[0].Message)" }
  $fn = @($ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'AciklamaHakemUretim' }, $true))
  if ($fn.Count -ne 1) { throw "AH: AciklamaHakemUretim $($fn.Count) kez bulundu" }
  $tekAta = { param($ad0) $l = @($fn[0].Body.FindAll({ param($n) $n -is [System.Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -eq $ad0 }, $true)); if ($l.Count -ne 1) { throw "AH: '$ad0' ataması $($l.Count) kez" }; $l[0].Right.Expression.Value }
  $ahIs = @($fn[0].Body.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] -and $n.GetCommandName() -eq 'AciklamaHakemIs' }, $true))
  if ($ahIs.Count -ne 1) { throw "AH: AciklamaHakemIs çağrısı $($ahIs.Count) kez" }
  $el = $ahIs[0].CommandElements
  if ($el.Count -ne 6 -or $el[3].Extent.Text -ne '$model' -or $el[5].Extent.Text -ne '$maxTok') { throw "AH: AciklamaHakemIs çağrı biçimi beklenen değil: $($ahIs[0].Extent.Text)" }
  $top = @($fn[0].Body.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] -and $n.GetCommandName() -eq 'Invoke-ClaudeToplu' }, $true))
  if ($top.Count -ne 1) { throw "AH: Invoke-ClaudeToplu çağrısı $($top.Count) kez" }
  $onb = [bool]@($top[0].CommandElements | Where-Object { $_ -is [System.Management.Automation.Language.CommandParameterAst] -and $_.ParameterName -eq 'OnbelleksizToplu' }).Count
  return [pscustomobject]@{ model = [string](& $tekAta '$model'); maxTok = [int](& $tekAta '$maxTok'); effort = [string]$el[4].Value; onbelleksiz = $onb }
}
function SmmmAhFiyat([string]$mdl) {
  $f = Get-BedelFiyat; $fy = $null; $kUz = -1
  foreach ($k in $f.Keys) { if ($mdl -like "$k*" -and $k.Length -gt $kUz) { $fy = $f[$k]; $kUz = $k.Length } }
  if (-not $fy) { throw "fiyatı bilinmeyen model: $mdl (bedel hesaplanamaz, gönderilmez)" }
  return $fy
}
function SmmmJsonYaz([string]$yol, $nesne) { [IO.File]::WriteAllText($yol, (ConvertTo-Json -InputObject $nesne -Depth 12), [Text.UTF8Encoding]::new($false)) }
function SmmmNode([string[]]$argv) { & node $jsArac @argv | ForEach-Object { Write-Host $_ }; return $LASTEXITCODE }

$AH = SmmmAhUretimAyari (Join-Path $depoKok 'arac/aciklama-hakemi-uretim.ps1')
Write-Host ("AÇIKLAMA HAKEMİ (üretimden, AST): model kodu {0} · effort {1} · maxTok {2} · önbelleksiz toplu {3}" -f (ModelKod $AH.model), $AH.effort, $AH.maxTok, $AH.onbelleksiz)

$girdiTam = $(if ([IO.Path]::IsPathRooted($Girdi)) { $Girdi } else { Join-Path (Get-Location).Path $Girdi })
if (-not (Test-Path $girdiTam)) { throw "girdi yok: $Girdi" }
$girdiNesne = ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($girdiTam, [Text.Encoding]::UTF8))
$adKosu = $KosuAd
if (-not $adKosu -and $girdiNesne.PSObject.Properties['ad']) { $adKosu = "$($girdiNesne.ad)" }
if (-not $adKosu) { $adKosu = ([IO.Path]::GetFileNameWithoutExtension($girdiTam) -replace '^smmm-ah-yalniz-girdi-', '') }
if ($adKosu -notmatch '^[a-z0-9][a-z0-9-]{1,60}$') { throw "koşu adı küçük harf/rakam/tire olmalı: '$adKosu'" }
$etiketBedel = "smmm-ah-yalniz/$adKosu"
$sonucHedef = $(if ($SonucYolu) { $SonucYolu } else { Join-Path $depoKok "veri/sinav/smmm-ah-yalniz-sonuc-$adKosu.json" })

$geciciKok = $(if ("$env:RUNNER_TEMP") { "$env:RUNNER_TEMP" } else { [IO.Path]::GetTempPath() })
$gecici = Join-Path $geciciKok ("smmm-ah-yalniz-$adKosu-$PID")   # soru içeriği taşır → iş sonunda silinir
New-Item -ItemType Directory -Force $gecici | Out-Null
$cikisKodu = 0
try { & {   # gövde ayrı blokta: içerideki return yalnız bloğu bitirir, çıkış kodu aşağıda (script düzeyi return exit kodunu 0 yapardı)
  # --- bulutta koşan partiler (ücretli koşuda): bulut-uretim o partiyi iş sonunda bütünüyle yükler → kararı ezer; atlanır
  $hazirArg = New-Object System.Collections.Generic.List[string]
  foreach ($x in @('hazirla', $girdiTam, (Join-Path $gecici 'hazir.json'), '--madde-kr', "$MaddeKr")) { $hazirArg.Add($x) }
  if ($Dayanak) { $hazirArg.Add('--dayanak'); $hazirArg.Add($(if ([IO.Path]::IsPathRooted($Dayanak)) { $Dayanak } else { Join-Path (Get-Location).Path $Dayanak })) }
  if ($Yeniden) { $hazirArg.Add('--yeniden') }
  if ($UstuneYaz) { $hazirArg.Add('--ustune-yaz') }
  if ($Calistir -and -not $sahteDizin) {
    $kosanListe = @(& (Join-Path $depoKok 'arac/bulut-kosan-etiketler.ps1') -Kati)   # planı okunamayan koşan iş varsa DURUR (yazan araç beklemeli)
    $kosanDosya = Join-Path $gecici 'kosan.txt'; [IO.File]::WriteAllText($kosanDosya, ($kosanListe -join "`n"), [Text.UTF8Encoding]::new($false))
    $hazirArg.Add('--kosan'); $hazirArg.Add($kosanDosya)
    Write-Host ("BULUTTA KOŞAN parti etiketi: {0}" -f $kosanListe.Count)
  }
  $kod = SmmmNode $hazirArg.ToArray(); if ($kod) { throw "hazırlık düştü ($kod)" }
  $hazir = ConvertFrom-Json -InputObject ([IO.File]::ReadAllText((Join-Path $gecici 'hazir.json'), [Text.Encoding]::UTF8))

  # --- istemler: çekirdek AciklamaHakemIs + RESMÎ MADDE METNİ bölümü
  $isler = New-Object System.Collections.Generic.List[object]; $harita = @{}; $kar = @{}
  foreach ($o in @($hazir.ogeler)) {
    if ("$($o.durum)" -ne 'hazir') { continue }
    $iid = "ah-" + ("$($o.soru_id)" -replace "/", "__" -replace "^_+", ""); if ($iid -notmatch '^[A-Za-z0-9_-]{1,64}$') { throw "custom_id kuralına uymayan kimlik: $($o.soru_id)" }
    $is = AciklamaHakemIs $iid $o.kayit $AH.model $AH.effort $AH.maxTok
    $md = $o.madde
    if ("$($md.kaynak)" -eq 'kayit') {
      # kayıttaki kaynak_metin_ozet beyan alıntılarını içeriyor (ya da başka kaynak okunamadı): çekirdek istem onu KAYNAK olarak zaten taşır
      $ekMetin = "`n`nMADDE METNİ KURALI: Yukarıdaki KAYNAK, sorunun dayandığı resmî mevzuat metninden alınmıştır. Kanun maddesi, fıkra, bent, süre ve oran hakkındaki her kusur iddiasını önce bu metinle karşılaştır. Açıklamadaki atıf ya da kural bu metinle örtüşüyorsa o konuda kusur deme. Metinle çelişiyorsa 'neden' alanına metindeki doğru madde, fıkra ya da bendi yaz. Çıktı biçimi değişmez."
    } elseif ("$($md.kaynak)" -eq 'kaynaksiz' -or -not "$($md.metin)") {
      $ekMetin = "`n`nRESMÎ MADDE METNİ: (ambarda bu sorunun dayanağı okunamadı — madde, fıkra, bent ve oran iddiasında yalnız yukarıdaki KAYNAK metne dayan.)"
    } else {
      $ekMetin = "`n`nRESMÎ MADDE METNİ (ambardaki resmî mevzuat metninden okundu" + $(if ("$($md.kaynak)" -eq 'kart') { ', sorunun kendi dayanağı' } else { ', onarımın dayanağı' }) + "):`n" + "$($md.metin)" +
        "`n`nMADDE METNİ KURALI: Kanun maddesi, fıkra, bent, süre ve oran hakkındaki her kusur iddiasını önce yukarıdaki RESMÎ MADDE METNİ ile karşılaştır. Açıklamadaki atıf ya da kural bu metinle örtüşüyorsa o konuda kusur deme. Metinle çelişiyorsa 'neden' alanına metindeki doğru madde, fıkra ya da bendi yaz. Metinde geçmeyen konularda yukarıdaki denetim kuralları aynen geçerlidir. Çıktı biçimi değişmez."
    }
    $is.icerik[0].text = ("$($is.icerik[0].text)" + $ekMetin) -replace "`r`n", "`n"
    $isler.Add($is); $harita[$iid] = "$($o.soru_id)"; $kar[$iid] = "$($is.icerik[0].text)".Length
    if ($sahteDizin) { [IO.File]::WriteAllText((Join-Path $sahteDizin "istem-$iid.txt"), "$($is.icerik[0].text)", [Text.UTF8Encoding]::new($false)) }
  }
  # --- bedel tahmini (üretim AciklamaHakemUretim formülü: girdi kr/1,6 jeton; en kötü çıktı = maxTok; toplu yarı fiyat)
  $fy = SmmmAhFiyat $AH.model
  $enKotu = 0.0; $tahmin = 0.0
  foreach ($i in $isler) { $gJ = $kar["$($i.id)"] / 1.6; $enKotu += 0.5 * (($gJ / 1e6) * $fy[0] + ($AH.maxTok / 1e6) * $fy[1]); $tahmin += 0.5 * (($gJ / 1e6) * $fy[0] + ([math]::Min(900, $AH.maxTok) / 1e6) * $fy[1]) }
  Write-Host ("GÖNDERİLECEK: {0} soru · TAHMİN {1:N3} USD (çıktı 900 jeton varsayımı) · EN KÖTÜ {2:N3} USD (soru başı {3:N3}) · bütçe {4} USD → {5}" -f $isler.Count, $tahmin, $enKotu, $(if ($isler.Count) { $enKotu / $isler.Count } else { 0 }), $ButceUsd, $(if ($enKotu -le $ButceUsd) { 'SIĞAR' } else { 'SIĞMAZ' }))
  if (-not $Calistir) { Write-Host "KURU: istek gönderilmedi, ambara yazılmadı (0 USD). Paralı: -ButceUsd <tavan> -Calistir"; return }
  if (-not $isler.Count) { Write-Host "Gönderilecek soru yok (0 USD)." }
  if ($isler.Count -and $ButceUsd -le 0) { throw '-ButceUsd verilmedi — paralı koşu bütçesiz başlamaz' }
  if ($isler.Count -and $enKotu -gt $ButceUsd) { Write-Host ("⛔ BÜTÇE YETMEZ — BAŞLAMADI: en kötü {0:N3} USD > bütçe {1} USD (0 USD harcandı, ambara yazılmadı)" -f $enKotu, $ButceUsd) -ForegroundColor Red; $script:cikisKodu = 4; return }

  # --- hakem (hep toplu; sahtede dosyadan)
  $sonuc = @{}
  if ($isler.Count) {
    if ($sahteDizin) {
      $sm = ConvertFrom-Json -InputObject ([IO.File]::ReadAllText((Join-Path $sahteDizin 'model.json'), [Text.Encoding]::UTF8))
      foreach ($p in $sm.PSObject.Properties) { $sonuc[$p.Name] = @{ metin = "$($p.Value)"; dur = 'end_turn' } }
    } else {
      $sonuc = Invoke-ClaudeToplu -Isler $isler.ToArray() -Etiket $etiketBedel -BeklemeDk $BeklemeDk -OnbelleksizToplu:([bool]$AH.onbelleksiz)
    }
  }
  # --- bedel → bedel_kaydi (SMMM etiketi)
  $bz = Get-BedelOzet; $usd = 0.0
  foreach ($s in @($bz.satirlar)) { Write-Host ("  BEDEL {0}: {1} çağrı · girdi {2} · çıktı {3} · ≈{4} USD" -f $s.model, $s.cagri, $s.girdi, $s.cikti, $s.usd) }
  if (@($bz.satirlar).Count -and [double]$bz.toplamUsd -gt 0) {
    $usd = [double](@($bz.satirlar | ForEach-Object { [double]$_.usd }) | Measure-Object -Sum).Sum
    if (Save-BedelKesin (Get-Date -Format 'yyyy-MM-dd HH:mm') $etiketBedel 'aciklama-hakemi' ([double]$bz.toplamUsd) ([bool]$bz.fiyatVarsayim) $bz.satirlar 'smmm-ah-yalniz') { Save-BedelAra $etiketBedel $true; Write-Host "  BEDEL: bedel_kaydi'na yazıldı · $etiketBedel · $($bz.toplamUsd) USD (satır toplamı $([math]::Round($usd,4)))" }
    else { Write-Host "  !! BEDEL bedel_kaydi'na YAZILAMADI ($etiketBedel) — ara kayıt açık, arac/bedel-ara-kapat.ps1 yazar" -ForegroundColor Red }
  } else { Write-Host "  BEDEL: ödenen istek yok (0 USD) — deftere satır yazılmadı" }
  if ($sonuc.ContainsKey('__zaman_asimi')) {
    Write-Host "⏳ TOPLU KUYRUK BİTMEDİ ($BeklemeDk dk) — kayda HİÇBİR ŞEY yazılmadı; yeniden koşu aynı partiye bağlanır / bedava hasat eder" -ForegroundColor Yellow
    $script:cikisKodu = 75; return
  }
  # --- kararlar
  $kararlar = [ordered]@{}; $olcul = New-Object System.Collections.Generic.List[string]
  foreach ($iid in $harita.Keys) {
    $sid = $harita[$iid]
    if (-not $sonuc.ContainsKey($iid)) { $olcul.Add($sid); continue }
    $kr = AciklamaHakemKarar $sonuc[$iid]
    if ($kr.karar -eq 'OLCULEMEDI') { $olcul.Add($sid); continue }
    $kararlar[$sid] = [ordered]@{ karar = $kr.karar; kusurlar = @($kr.kusurlar); model = $AH.model; tarih = (Get-Date -Format 'yyyy-MM-dd') }
  }
  SmmmJsonYaz (Join-Path $gecici 'kararlar.json') ([ordered]@{ kararlar = $kararlar; olculemedi = $olcul.ToArray() })
  SmmmJsonYaz (Join-Path $gecici 'meta.json') ([ordered]@{ ad = $adKosu; kosu = $(if ($env:GITHUB_RUN_ID) { "gh$($env:GITHUB_RUN_ID)" } else { "yerel-$PID" }); butce_usd = $ButceUsd; usd = [math]::Round($usd, 4)
      hakem = [ordered]@{ model = (ModelKod $AH.model); effort = $AH.effort; maxTok = $AH.maxTok; onbelleksiz = $AH.onbelleksiz; ek = 'RESMÎ MADDE METNİ bölümü (ambardan)' } })
  $kod = SmmmNode @('yaz', (Join-Path $gecici 'hazir.json'), (Join-Path $gecici 'kararlar.json'), $sonucHedef, '--meta', (Join-Path $gecici 'meta.json'))
  Write-Host "SONUÇ: $sonucHedef"
  if ($kod -eq 3) { $script:cikisKodu = 3 } elseif ($kod) { $script:cikisKodu = 1 }
} }
finally { Remove-Item $gecici -Recurse -Force -ErrorAction SilentlyContinue }
exit $cikisKodu
