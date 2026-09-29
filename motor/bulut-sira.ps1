# ============================================================================
#  BULUT SIRASI (29.09.2026, Cem "1.2.3 üçünü de yap" madde 1)
#  Soru basım planlarını OTURUMDAN BAĞIMSIZ, paya göre bulutta açar.
#
#  KİM NE YAPAR
#    Sınav oturumu : -Ekle ile sıraya plan koyar (bütçesiyle), commit + push eder. O kadar.
#    Bulut robotu  : .github/workflows/bulut-sira.yml, 15 dk'da bir -Dagit koşar:
#                    açık bulut-uretim koşularını sayar, pay boşsa sıradaki planı açar.
#    Herkes        : -Durum ile sırayı + payı + robotun son koşusunu görür (dispatch yok).
#
#  Kullanım:
#    powershell -NoProfile -File motor/bulut-sira.ps1 -Ekle -Plan veri/sinav/plan-smmm-gm5-11.json -Butce 1.68 [-Paralel 5] [-OlcumKosusu <run id>] [-Yeniden] [-Not "..."] [-Ekleyen "<oturum adı>"]
#    powershell -NoProfile -File motor/bulut-sira.ps1 -Cikar -Plan veri/sinav/plan-smmm-gm5-11.json
#    powershell -NoProfile -File motor/bulut-sira.ps1 -Temizle   (açılmış + bitmiş satırları budar; -Ekle bunu kendiliğinden yapar)
#    powershell -NoProfile -File motor/bulut-sira.ps1 -Durum
#    ./motor/bulut-sira.ps1 -Dagit [-Kuru]      (bulutta; -Kuru = yalnız karar yazar)
#
#  ⛔ PARA KURALI DEĞİŞMEDİ: sıraya giren her satır bütçelidir (butce_usd zorunlu; >25 USD ise
#     olcum_kosusu zorunlu). Sıraya koymak = o planı açma KARARI; bedel Cem'e önceden sorulur.
#  ⛔ Stdout'a yalnız plan yolu, sayı, bütçe basılır — soru içeriği ASLA (depo public).
#  Karar mantığı: arac/bulut-sira-karar.ps1 · öz-sınav: arac/bulut-sira-sinavi.ps1 (dogrula.yml).
# ============================================================================
param(
  [switch]$Dagit,
  [switch]$Kuru,
  [switch]$Durum,
  [switch]$Ekle,
  [switch]$Cikar,
  [switch]$Temizle,
  [string]$Plan = '',
  [string]$Butce = '',
  [string]$Paralel = '',
  [string]$OlcumKosusu = '',
  [switch]$Yeniden,
  [string]$Not = '',
  [string]$Ekleyen = '',
  [string]$SiraYolu = ''
)
$ErrorActionPreference = 'Stop'
$buDizin = $(if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$depoKok = Split-Path -Parent $buDizin
. (Join-Path $depoKok (Join-Path 'arac' 'bulut-sira-karar.ps1'))
if (-not $SiraYolu) { $SiraYolu = Join-Path $depoKok (Join-Path 'veri' (Join-Path 'sinav' 'bulut-sira.json')) }
$GECMIS_TAVAN = 1000

$ghKomut = 'gh'
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
  $ghTam = 'C:\Program Files\GitHub CLI\gh.exe'
  if (Test-Path $ghTam) { $ghKomut = $ghTam }
}

function GhCagir([string[]]$Argumanlar) {
  # Yerel komut: EAP=Stop altında stderr yönlendirmesi betiği öldürür (tuzak K6) → geçici Continue, çıkış kodu elle.
  # 3 deneme, artan bekleme; üçü de düşerse throw (robot KIRMIZI biter, sessiz ölüm yok).
  $sonHata = ''
  foreach ($deneme in 1..3) {
    $eskiEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try { $cikti = & $ghKomut @Argumanlar 2>&1; $kod = $LASTEXITCODE } finally { $ErrorActionPreference = $eskiEap }
    $metin = @($cikti | ForEach-Object { "$_" }) -join "`n"
    if ($kod -eq 0) { return $metin }
    $sonHata = "çıkış $kod"
    Write-Host "  gh denemesi $deneme düştü ($sonHata): $($Argumanlar[0]) $($Argumanlar[1])"
    if ($deneme -lt 3) { Start-Sleep -Seconds (15 * $deneme) }
  }
  throw "gh üç denemede düştü ($sonHata): $($Argumanlar -join ' ')"
}

function SiraOku {
  if (-not (Test-Path $SiraYolu)) { throw "sıra dosyası yok: $SiraYolu" }
  $ham = [IO.File]::ReadAllText($SiraYolu, [Text.Encoding]::UTF8)
  $nesne = $ham | ConvertFrom-Json
  $liste = @()
  if ($nesne.PSObject.Properties['sira'] -and $null -ne $nesne.sira) { $liste = @($nesne.sira | ForEach-Object { $_ }) }
  $nesne | Add-Member -NotePropertyName sira -NotePropertyValue $liste -Force
  return $nesne
}

function SiraYaz($Nesne) {
  $metin = ConvertTo-Json -InputObject $Nesne -Depth 6
  [IO.File]::WriteAllText($SiraYolu, $metin + "`n", (New-Object Text.UTF8Encoding($false)))
}

function KosuGecmisi {
  $ham = GhCagir @('run', 'list', '-w', 'bulut-uretim.yml', '-L', "$GECMIS_TAVAN", '--json', 'databaseId,displayTitle,status,createdAt')
  $js = $ham | ConvertFrom-Json
  $kosular = @($js | ForEach-Object { $_ })
  $enEski = $null
  foreach ($k in $kosular) { $z = BsZaman $k.createdAt; if ($null -ne $z -and ($null -eq $enEski -or $z -lt $enEski)) { $enEski = $z } }
  return [pscustomobject]@{ kosular = $kosular; en_eski = $enEski; tam = ($kosular.Count -lt $GECMIS_TAVAN) }
}

$planDenetle = {
  param($Yol)
  $tam = Join-Path $depoKok ($Yol -replace '/', [IO.Path]::DirectorySeparatorChar)
  if (-not (Test-Path $tam)) { return "plan dosyası depoda yok ($Yol) — plan commit+push edildi mi?" }
  try { $pj = [IO.File]::ReadAllText($tam, [Text.Encoding]::UTF8) | ConvertFrom-Json } catch { return "plan JSON okunamadı ($Yol)" }
  $satirlar = @($pj | ForEach-Object { $_ })
  if ($satirlar.Count -lt 1) { return "plan boş ($Yol)" }
  $sinavlar = @($satirlar | ForEach-Object { if ($_.PSObject.Properties['sinav'] -and "$($_.sinav)") { "$($_.sinav)" } else { 'SGS' } } | Sort-Object -Unique)
  if ($sinavlar.Count -ne 1) { return "plan birden çok sınav içeriyor ($($sinavlar -join ',')) — bulut-uretim reddeder" }
  return $null
}

function KararYaz($Sonuc, $Gecmis) {
  $paySatir = @(foreach ($ad in @($Sonuc.pay.Keys | Where-Object { $_ -ne 'toplam' } | Sort-Object)) { "$ad $($Sonuc.sinav_acik[$ad])/$($Sonuc.pay[$ad])" }) -join ' · '
  "PAY: toplam açık $($Sonuc.toplam_acik)/$($Sonuc.toplam_pay) · $paySatir$(if ($Sonuc.cozulmeyen_acik) { " · başlığı çözülemeyen açık $($Sonuc.cozulmeyen_acik)" })$(if ($Sonuc.durdur) { ' · ⛔ DURDUR=true' })"
  $kapsam = if ($Gecmis.tam) { 'TAM' } else { 'KESİK (tavan ' + $GECMIS_TAVAN + ')' }
  "GEÇMİŞ: $(@($Gecmis.kosular).Count) koşu · en eski $(if ($Gecmis.en_eski) { '{0:yyyy-MM-dd HH:mm}' -f $Gecmis.en_eski } else { '-' }) UTC · kapsam $kapsam"
  foreach ($kr in $Sonuc.kararlar) {
    "  {0,-6} {1} | {2} | {3} USD | paralel {4}{5} | {6}" -f $kr.karar, $kr.plan, $kr.sinav, $kr.butce, $kr.paralel, $(if ($kr.olcum) { " | ölçüm $($kr.olcum)" } else { '' }), $kr.neden
  }
  $say = @{}; foreach ($kr in $Sonuc.kararlar) { $say[$kr.karar] = 1 + [int]$say[$kr.karar] }
  "ÖZET: açılacak $([int]$say['AC']) · açılmış $([int]$say['ACILDI']) · bekleyen $([int]$say['BEKLE']) · atlanan(bozuk) $([int]$say['ATLA']) · KÖR $([int]$say['KOR']) · durdurulan $([int]$say['DURDU'])"
  $bekBtc = 0.0
  foreach ($kr in $Sonuc.kararlar) { if (($kr.karar -eq 'AC' -or $kr.karar -eq 'BEKLE') -and $kr.butce) { $bekBtc += [double]::Parse($kr.butce, [Globalization.CultureInfo]::InvariantCulture) } }
  "BÜTÇE: açılacak + bekleyen planların tavanı toplamı $($bekBtc.ToString('0.##', [Globalization.CultureInfo]::InvariantCulture)) USD"
}

function BitmisleriBuda($Nesne, $Gecmis) {
  # Açılmış ve koşusu BİTMİŞ satırları sıradan çıkarır (dosya küçük kalsın; eski satır geçmiş penceresinden
  # taşınca KÖR'e düşmesin). Koşan satıra dokunmaz. Döner: budanan satır sayısı. Dosyaya YAZMAZ.
  $sn = BsKarar -Ayar $Nesne -Kosular $Gecmis.kosular -PlanDenetle $null -PencereBasi $Gecmis.en_eski -PencereTam $Gecmis.tam
  $biten = @($sn.kararlar | Where-Object { $_.karar -eq 'ACILDI' -and $_.neden -like 'açılmış, bitmiş*' } | ForEach-Object { $_.plan })
  if (-not $biten.Count) { return 0 }
  $once = @($Nesne.sira).Count
  $Nesne.sira = @(@($Nesne.sira) | Where-Object { $biten -notcontains ("$($_.plan)".Trim() -replace '\\', '/') })
  return ($once - @($Nesne.sira).Count)
}

# ---------------------------------------------------------------- -Temizle
if ($Temizle) {
  $nesne = SiraOku
  $budanan = BitmisleriBuda $nesne (KosuGecmisi)
  if (-not $budanan) { "budanacak bitmiş satır yok (dokunulmadı)"; exit 0 }
  SiraYaz $nesne
  "bitmiş $budanan satır sıradan budandı. Commit + push et."
  exit 0
}

# ---------------------------------------------------------------- -Ekle
if ($Ekle) {
  if (-not $Plan -or -not $Butce) { throw "-Ekle için -Plan ve -Butce zorunlu" }
  $nesne = if (Test-Path $SiraYolu) { SiraOku } else { throw "sıra dosyası yok: $SiraYolu" }
  $yeniSatir = [pscustomobject][ordered]@{
    plan = ($Plan.Trim() -replace '\\', '/'); butce_usd = $null; paralel = $null; olcum_kosusu = $OlcumKosusu.Trim()
    sinav = (BsSinavi $Plan); eklenme = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ', [Globalization.CultureInfo]::InvariantCulture)
    ekleyen = $Ekleyen; yeniden = [bool]$Yeniden; not = $Not
  }
  $yeniSatir.butce_usd = BsButce $Butce
  if ($Paralel) { $yeniSatir.paralel = $Paralel } else { $yeniSatir.paralel = "$($nesne.varsayilan_paralel)" }
  $payT = BsPayTablosu $nesne
  $dn = BsSatirDenetle $yeniSatir $payT 5
  if (-not $dn.tamam) { throw "SATIR REDDEDİLDİ: $($dn.neden)" }
  $yeniSatir.paralel = $dn.paralel
  $pn = & $planDenetle $dn.plan
  if ($pn) { throw "SATIR REDDEDİLDİ: $pn" }
  foreach ($eski in @($nesne.sira)) {
    if ("$($eski.plan)".Trim() -replace '\\', '/' -eq $dn.plan) { throw "SATIR REDDEDİLDİ: plan sırada zaten var ($($dn.plan)). Önce -Cikar." }
  }
  # Geçmişte açılmış mı? (yeniden değilse geriye_bakis_gun içinde tek koşu bile yeter)
  $gec = KosuGecmisi
  $denemeAyar = [pscustomobject]@{ pay = $nesne.pay; varsayilan_paralel = $nesne.varsayilan_paralel; geriye_bakis_gun = $nesne.geriye_bakis_gun; durdur = $false; sira = @($yeniSatir) }
  $kr = @((BsKarar -Ayar $denemeAyar -Kosular $gec.kosular -PlanDenetle $null -PencereBasi $gec.en_eski -PencereTam $gec.tam).kararlar)[0]
  if ($kr.karar -eq 'ACILDI') { throw "SATIR REDDEDİLDİ: $($dn.plan) zaten açılmış — $($kr.neden). Bilerek yeniden açmak (Cem onayı) için -Yeniden." }
  if ($kr.karar -eq 'KOR') { throw "SATIR REDDEDİLDİ: $($kr.neden)" }
  $budanan = BitmisleriBuda $nesne $gec
  $nesne.sira = @($nesne.sira) + @($yeniSatir)
  SiraYaz $nesne
  if ($budanan) { "bitmiş $budanan satır sıradan budandı (geçmişi git log'da)" }
  "SIRAYA EKLENDİ: $($dn.plan) | $($dn.sinav) | $($dn.butce) USD | paralel $($dn.paralel)$(if ($dn.olcum) { " | ölçüm $($dn.olcum)" })$(if ($dn.yeniden) { ' | YENİDEN' })"
  "Şimdi AYNI ÇAĞRIDA commit + push et: git add veri/sinav/bulut-sira.json; git commit -m ...; git push origin HEAD:main"
  "Robot en geç ~15 dk içinde paya göre açar. Bu planı ELLE AÇMA (çift ödeme)."
  exit 0
}

# ---------------------------------------------------------------- -Cikar
if ($Cikar) {
  if (-not $Plan) { throw "-Cikar için -Plan zorunlu" }
  $nesne = SiraOku
  $hedef = $Plan.Trim() -replace '\\', '/'
  $once = @($nesne.sira).Count
  $nesne.sira = @(@($nesne.sira) | Where-Object { ("$($_.plan)".Trim() -replace '\\', '/') -ne $hedef })
  $cikan = $once - @($nesne.sira).Count
  if (-not $cikan) { "sırada yok: $hedef (dokunulmadı)"; exit 0 }
  SiraYaz $nesne
  "SIRADAN ÇIKTI: $hedef ($cikan satır). Açılmış koşu varsa DURMAZ — gerekiyorsa: gh run cancel <id>. Commit + push et."
  exit 0
}

# ---------------------------------------------------------------- -Durum / -Dagit
if (-not ($Durum -or $Dagit)) { throw "Kip seç: -Ekle · -Cikar · -Temizle · -Durum · -Dagit [-Kuru]" }
$nesne = SiraOku
$gec = KosuGecmisi
$sonuc = BsKarar -Ayar $nesne -Kosular $gec.kosular -PlanDenetle $planDenetle -PencereBasi $gec.en_eski -PencereTam $gec.tam
KararYaz $sonuc $gec

if ($Durum) {
  # Robot yaşıyor mu? (rapor bakmadığını da söyler: robot hiç koşmadıysa "SUSKUN")
  try {
    $rj = (GhCagir @('run', 'list', '-w', 'bulut-sira.yml', '-L', '1', '--json', 'createdAt,conclusion,status')) | ConvertFrom-Json
    $son = @($rj | ForEach-Object { $_ })
    if ($son.Count) {
      $dk = [int]((Get-Date).ToUniversalTime() - (BsZaman $son[0].createdAt)).TotalMinutes
      "ROBOT: son koşu $dk dk önce · $($son[0].status) $($son[0].conclusion)$(if ($dk -gt 45) { ' · ⚠ ROBOT SUSKUN (>45 dk) — cron düşmüş olabilir' })"
    } else { "ROBOT: ⚠ hiç koşmamış (bulut-sira.yml ana telde mi?)" }
  } catch { "ROBOT: ⚠ GÖRÜNMÜYOR — bulut-sira.yml ana telde yok ya da gh düştü ($($_.Exception.Message))" }
  "(-Durum dispatch YAPMAZ)"
  exit 0
}

# ---------------------------------------------------------------- -Dagit
$acilacak = @($sonuc.kararlar | Where-Object { $_.karar -eq 'AC' })
$ozetYol = $env:GITHUB_STEP_SUMMARY
$acilan = 0
if ($Kuru) { "KURU KOŞU: $($acilacak.Count) plan açılacaktı, dispatch YOK" }
else {
  foreach ($kr in $acilacak) {
    $an = (Get-Date).ToUniversalTime().AddMinutes(-2)
    $ghArg = @('workflow', 'run', 'bulut-uretim.yml', '--ref', 'main', '-f', "plan=$($kr.plan)", '-f', "paralel=$($kr.paralel)", '-f', 'indir_parti=true', '-f', "butce_usd=$($kr.butce)")
    if ($kr.olcum) { $ghArg += @('-f', "olcum_kosusu=$($kr.olcum)") }
    [void](GhCagir $ghArg)
    # Açıldığı GÖRÜLMEDEN sonrakine geçilmez: görünmezse bir sonraki tur geçmişte görür (çift açma yok), bu tur KIRMIZI biter.
    $goruldu = $false
    foreach ($bk in 1..8) {
      Start-Sleep -Seconds 10
      $son = @(((GhCagir @('run', 'list', '-w', 'bulut-uretim.yml', '-L', '30', '--json', 'displayTitle,createdAt')) | ConvertFrom-Json) | ForEach-Object { $_ })
      foreach ($s in $son) {
        $m = [regex]::Match("$($s.displayTitle)", $script:BS_BASLIK_DESEN)
        $sz = BsZaman $s.createdAt
        if ($m.Success -and $m.Groups[1].Value -eq $kr.plan -and $null -ne $sz -and $sz -ge $an) { $goruldu = $true; break }
      }
      if ($goruldu) { break }
    }
    if (-not $goruldu) { throw "AÇILDI AMA 80 sn'de GÖRÜNMEDİ: $($kr.plan) — bu tur durdu; sonraki tur geçmişe bakar, yeniden AÇMAZ." }
    $acilan++
    "AÇILDI: $($kr.plan) | $($kr.sinav) | $($kr.butce) USD | paralel $($kr.paralel)"
  }
}
if ($ozetYol) {
  $satirlar = @('### Bulut sırası', '', '```') + @(KararYaz $sonuc $gec) + @('```', '', "Bu turda açılan: $acilan$(if ($Kuru) { ' (KURU)' })")
  Add-Content -Path $ozetYol -Value ($satirlar -join "`n") -Encoding UTF8
}
$bozuk = @($sonuc.kararlar | Where-Object { $_.karar -eq 'ATLA' -or $_.karar -eq 'KOR' })
if ($bozuk.Count) {
  Write-Host "::error::$($bozuk.Count) sıra satırı AÇILAMADI (ATLA/KÖR) — satırı düzelt ya da -Cikar ile kaldır. Geçerli satırlar açıldı."
  exit 1
}
"SIRA TAMAM: bu turda açılan $acilan"
