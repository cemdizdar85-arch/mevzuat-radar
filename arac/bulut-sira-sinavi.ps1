# BULUT SIRASI ÖZ-SINAVI (29.09.2026) — arac/bulut-sira-karar.ps1 BsKarar
# Sahte koşu listesiyle sınar; gh çağırmaz, dosya yazmaz. Vakalar tr-TR kültüründe koşar (ondalık virgül tuzağı).
# Ayrıca: (1) bağlantı — robot iş akışı, sürücü betik, sıra dosyası birbirine bağlı mı, sıra dosyası geçerli mi;
#         (2) MUTASYON — kilit koşulları tek tek bozulur, her bozmada en az bir vaka DÜŞMELİ (CLAUDE.md kapı kuralı 8).
$ErrorActionPreference = 'Stop'
$buDizin = $(if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$depoKok = Split-Path -Parent $buDizin
$kutYol = Join-Path $buDizin 'bulut-sira-karar.ps1'
$kutMetin = [IO.File]::ReadAllText($kutYol, [Text.Encoding]::UTF8)

# --- sahte veri yardımcıları
function Ayar($SiraSatirlari, $PayTablo = $null, [bool]$Durdur = $false) {
  if ($null -eq $PayTablo) { $PayTablo = [pscustomobject]@{ toplam = 6; smmm = 3; sgs = 3; kgk = 2 } }
  [pscustomobject]@{ pay = $PayTablo; varsayilan_paralel = 5; geriye_bakis_gun = 30; durdur = $Durdur; sira = @($SiraSatirlari) }
}
function Satir([string]$P, $B = '1.5', $Ek = @{}) {
  $o = [pscustomobject]@{ plan = "veri/sinav/$P.json"; butce_usd = $B; eklenme = '2026-09-29T20:00:00Z' }
  foreach ($k in $Ek.Keys) { $o | Add-Member -NotePropertyName $k -NotePropertyValue $Ek[$k] -Force }
  return $o
}
function Kosu([string]$P, [string]$Durumu = 'in_progress', [string]$Zaman = '2026-09-29T19:00:00Z', [int]$Halka = 0) {
  [pscustomobject]@{ databaseId = 1; displayTitle = "Bulut Uretim | veri/sinav/$P.json | halka $Halka"; status = $Durumu; createdAt = $Zaman }
}

$VAKALAR = @(
  @{ ad = 'boş bulut: iki SMMM planı açılır'; ayar = (Ayar @((Satir 'plan-smmm-a-1'), (Satir 'plan-smmm-a-2'))); kosu = @(); bek = @('AC', 'AC') }
  @{ ad = 'SMMM payı dolu (3 açık) → SMMM bekler, SGS açılır'; ayar = (Ayar @((Satir 'plan-smmm-a-4'), (Satir 'plan-sgs-b-1')))
     kosu = @((Kosu 'plan-smmm-a-1'), (Kosu 'plan-smmm-a-2'), (Kosu 'plan-smmm-a-3')); bek = @('BEKLE', 'AC') }
  @{ ad = 'toplam 6 dolu → KGK bekler'; ayar = (Ayar @((Satir 'plan-kgk-d-1')))
     kosu = @((Kosu 'plan-smmm-a-1'), (Kosu 'plan-smmm-a-2'), (Kosu 'plan-smmm-a-3'), (Kosu 'plan-sgs-b-1'), (Kosu 'plan-sgs-b-2'), (Kosu 'plan-sgs-b-3')); bek = @('BEKLE') }
  @{ ad = 'aynı karar içinde pay sayılır: 4 SMMM satırı → 3 AC + 1 BEKLE'; ayar = (Ayar @((Satir 'plan-smmm-a-1'), (Satir 'plan-smmm-a-2'), (Satir 'plan-smmm-a-3'), (Satir 'plan-smmm-a-4'))); kosu = @(); bek = @('AC', 'AC', 'AC', 'BEKLE') }
  @{ ad = 'aynı karar içinde toplam sayılır: 4 SMMM(pay 9) + 3 SGS, toplam 6'; ayar = (Ayar @((Satir 'plan-smmm-a-1'), (Satir 'plan-smmm-a-2'), (Satir 'plan-smmm-a-3'), (Satir 'plan-smmm-a-4'), (Satir 'plan-sgs-b-1'), (Satir 'plan-sgs-b-2'), (Satir 'plan-sgs-b-3')) ([pscustomobject]@{ toplam = 6; smmm = 9; sgs = 3 })); kosu = @(); bek = @('AC', 'AC', 'AC', 'AC', 'AC', 'AC', 'BEKLE') }
  @{ ad = 'halka: aynı planın halka 0 + kuyruktaki halka 1 TEK plan sayılır'; ayar = (Ayar @((Satir 'plan-smmm-a-9')))
     kosu = @((Kosu 'plan-smmm-a-1' 'in_progress' '2026-09-29T10:00:00Z' 0), (Kosu 'plan-smmm-a-1' 'queued' '2026-09-29T15:00:00Z' 1), (Kosu 'plan-smmm-a-2')); bek = @('AC') }
  @{ ad = 'koşan plan yeniden açılmaz (in_progress)'; ayar = (Ayar @((Satir 'plan-smmm-a-1'))); kosu = @((Kosu 'plan-smmm-a-1')); bek = @('ACILDI') }
  @{ ad = 'kuyruktaki plan yeniden açılmaz (queued)'; ayar = (Ayar @((Satir 'plan-smmm-a-1'))); kosu = @((Kosu 'plan-smmm-a-1' 'queued')); bek = @('ACILDI') }
  @{ ad = 'yeniden=true ama önceki zincir HÂLÂ koşuyor → açılmaz'; ayar = (Ayar @((Satir 'plan-smmm-a-1' '1.5' @{ yeniden = $true })))
     kosu = @((Kosu 'plan-smmm-a-1' 'in_progress' '2026-09-28T10:00:00Z' 3)); bek = @('ACILDI') }
  @{ ad = 'bitmiş koşu (eklenmeden 10 gün önce) → açılmış sayılır'; ayar = (Ayar @((Satir 'plan-smmm-a-1'))); kosu = @((Kosu 'plan-smmm-a-1' 'completed' '2026-09-19T20:00:00Z')); bek = @('ACILDI') }
  @{ ad = 'bitmiş koşu eklenmeden SONRA → açılmış sayılır'; ayar = (Ayar @((Satir 'plan-smmm-a-1'))); kosu = @((Kosu 'plan-smmm-a-1' 'completed' '2026-09-29T20:15:00Z')); bek = @('ACILDI') }
  @{ ad = 'yeniden=true, bitmiş koşu eklenmeden önce → AÇILIR'; ayar = (Ayar @((Satir 'plan-smmm-a-1' '1.5' @{ yeniden = $true }))); kosu = @((Kosu 'plan-smmm-a-1' 'completed' '2026-09-27T20:00:00Z')); bek = @('AC') }
  @{ ad = 'bitmiş koşu 40 gün önce (pencere dışı) → AÇILIR'; ayar = (Ayar @((Satir 'plan-smmm-a-1'))); kosu = @((Kosu 'plan-smmm-a-1' 'completed' '2026-08-20T20:00:00Z')); bek = @('AC') }
  @{ ad = 'bozuk bütçe: metin / 0 / eksi / boş → ATLA, arkadaki geçerli satır açılır'
     ayar = (Ayar @((Satir 'plan-smmm-a-1' 'abc'), (Satir 'plan-smmm-a-2' '0'), (Satir 'plan-smmm-a-3' '-3'), (Satir 'plan-smmm-a-4' ''), (Satir 'plan-smmm-a-5' '1.2.3'), (Satir 'plan-smmm-a-6' '2'))); kosu = @(); bek = @('ATLA', 'ATLA', 'ATLA', 'ATLA', 'ATLA', 'AC') }
  @{ ad = 'bütçe biçimi: "1,68" ve sayı 1.68 → "1.68" (tr-TR''de bile)'; ayar = (Ayar @((Satir 'plan-smmm-a-1' '1,68'), (Satir 'plan-sgs-b-1' 1.68))); kosu = @(); bek = @('AC', 'AC'); butce = @('1.68', '1.68') }
  @{ ad = 'bütçe > 25 ölçüm koşusu yok → ATLA; varsa AÇILIR; ölçüm run id değil → ATLA'
     ayar = (Ayar @((Satir 'plan-smmm-a-1' '30'), (Satir 'plan-smmm-a-2' '30' @{ olcum_kosusu = '36307837371' }), (Satir 'plan-smmm-a-3' '3' @{ olcum_kosusu = 'abc' }))); kosu = @(); bek = @('ATLA', 'AC', 'ATLA') }
  @{ ad = 'aynı plan sırada iki kez → ikincisi ATLA'; ayar = (Ayar @((Satir 'plan-smmm-a-1'), (Satir 'plan-smmm-a-1'))); kosu = @(); bek = @('AC', 'ATLA') }
  @{ ad = 'plan yolu geçersiz → ATLA'; ayar = (Ayar @(([pscustomobject]@{ plan = 'veri/sinav/../plan-smmm-x.json'; butce_usd = '1'; eklenme = '2026-09-29T20:00:00Z' }), ([pscustomobject]@{ plan = 'veri/sinav/plan-smmm-x.json;rm'; butce_usd = '1'; eklenme = '2026-09-29T20:00:00Z' }), ([pscustomobject]@{ plan = 'motor/plan-smmm-x.json'; butce_usd = '1'; eklenme = '2026-09-29T20:00:00Z' })))
     kosu = @(); bek = @('ATLA', 'ATLA', 'ATLA') }
  @{ ad = 'sinav alanı plan adıyla uyuşmaz → ATLA; pay tablosunda olmayan sınav → ATLA'; ayar = (Ayar @((Satir 'plan-smmm-a-1' '1' @{ sinav = 'sgs' }), (Satir 'plan-c2-x' '1'), (Satir 'plan-toplam-x' '1'))); kosu = @(); bek = @('ATLA', 'ATLA', 'ATLA') }
  @{ ad = 'paralel bozuk (0, 99, x) → ATLA; boşsa varsayılan'; ayar = (Ayar @((Satir 'plan-smmm-a-1' '1' @{ paralel = 0 }), (Satir 'plan-smmm-a-2' '1' @{ paralel = 99 }), (Satir 'plan-smmm-a-3' '1' @{ paralel = 'x' }), (Satir 'plan-smmm-a-4' '1' @{ paralel = '' }))); kosu = @(); bek = @('ATLA', 'ATLA', 'ATLA', 'AC') }
  @{ ad = 'eklenme okunamıyor → ATLA'; ayar = (Ayar @((Satir 'plan-smmm-a-1' '1' @{ eklenme = 'dün' }))); kosu = @(); bek = @('ATLA') }
  @{ ad = 'başlığı çözülemeyen açık koşu toplama sayılır'; ayar = (Ayar @((Satir 'plan-sgs-b-9')))
     kosu = @((Kosu 'plan-smmm-a-1'), (Kosu 'plan-smmm-a-2'), (Kosu 'plan-smmm-a-3'), (Kosu 'plan-sgs-b-1'), (Kosu 'plan-sgs-b-2'), ([pscustomobject]@{ databaseId = 9; displayTitle = 'Bulut Uretim (soru basimi)'; status = 'in_progress'; createdAt = '2026-09-29T19:00:00Z' })); bek = @('BEKLE') }
  @{ ad = 'pay zaten aşılmış (SGS 4 açık) → SGS bekler, çökme yok'; ayar = (Ayar @((Satir 'plan-sgs-b-9'), (Satir 'plan-kgk-d-1')))
     kosu = @((Kosu 'plan-sgs-b-1'), (Kosu 'plan-sgs-b-2'), (Kosu 'plan-sgs-b-3'), (Kosu 'plan-sgs-b-4')); bek = @('BEKLE', 'AC') }
  @{ ad = 'geçmiş KESİK ve sınıra inmiyor → KÖR (açmaz)'; ayar = (Ayar @((Satir 'plan-smmm-a-1'))); kosu = @((Kosu 'plan-sgs-b-1' 'completed' '2026-09-25T00:00:00Z')); pencereTam = $false; pencereBasi = '2026-09-25T00:00:00Z'; bek = @('KOR') }
  @{ ad = 'geçmiş KESİK ama sınırdan eskiye iniyor → AÇILIR'; ayar = (Ayar @((Satir 'plan-smmm-a-1'))); kosu = @((Kosu 'plan-sgs-b-1' 'completed' '2026-08-01T00:00:00Z')); pencereTam = $false; pencereBasi = '2026-08-01T00:00:00Z'; bek = @('AC') }
  @{ ad = 'plan dosyası yok (denetçi) → ATLA'; ayar = (Ayar @((Satir 'plan-smmm-yok-1'), (Satir 'plan-smmm-a-2'))); kosu = @(); denetle = { param($y) if ($y -like '*yok*') { 'plan dosyası depoda yok' } }; bek = @('ATLA', 'AC') }
  @{ ad = 'acil fren durdur=true → hiçbir plan açılmaz'; ayar = (Ayar @((Satir 'plan-smmm-a-1'), (Satir 'plan-sgs-b-1')) $null $true); kosu = @(); bek = @('DURDU', 'DURDU') }
  @{ ad = 'PS 7 ConvertFrom-Json DateTime geçmişi de okunur'; ayar = (Ayar @((Satir 'plan-smmm-a-1')))
     kosu = @([pscustomobject]@{ databaseId = 1; displayTitle = 'Bulut Uretim | veri/sinav/plan-smmm-a-1.json | halka 0'; status = 'completed'; createdAt = [datetime]::SpecifyKind([datetime]'2026-09-29T20:30:00', [DateTimeKind]::Utc) }); bek = @('ACILDI') }
)

function VakaKos([string]$KutKaynak) {
  # kütüphaneyi temiz kapsamda yükler, her vakanın sonucunu döndürür; vakalar tr-TR kültüründe
  $sb = [scriptblock]::Create("param(`$vakalar)`n" + $KutKaynak + "`n" + @'
$eskiKultur = [Globalization.CultureInfo]::CurrentCulture
try {
  [Globalization.CultureInfo]::CurrentCulture = [Globalization.CultureInfo]::GetCultureInfo('tr-TR')
  foreach ($v in $vakalar) {
    $tam = $true; if ($v.ContainsKey('pencereTam')) { $tam = [bool]$v.pencereTam }
    $bas = '2026-01-01T00:00:00Z'; if ($v.ContainsKey('pencereBasi')) { $bas = $v.pencereBasi }
    try {
      $s = BsKarar -Ayar $v.ayar -Kosular $v.kosu -PlanDenetle $v.denetle -PencereBasi $bas -PencereTam $tam
      $gercek = @($s.kararlar | ForEach-Object { $_.karar })
      $tamam = (($gercek -join ',') -eq ($v.bek -join ','))
      if ($tamam -and $v.ContainsKey('butce')) { $tamam = ((@($s.kararlar | ForEach-Object { $_.butce }) -join ',') -eq ($v.butce -join ',')); if (-not $tamam) { $gercek += @($s.kararlar | ForEach-Object { "butce=$($_.butce)" }) } }
    } catch { $gercek = @("HATA: $($_.Exception.Message)"); $tamam = $false }
    [pscustomobject]@{ ad = $v.ad; bek = ($v.bek -join ','); gercek = ($gercek -join ','); tamam = $tamam }
  }
} finally { [Globalization.CultureInfo]::CurrentCulture = $eskiKultur }
'@)
  return @(& $sb $VAKALAR)
}

$kirmizi = 0
# kültür gerçekten tr-TR'ye geçebiliyor mu (geçmiyorsa virgül vakası KÖR olur → KIRMIZI say)
$eskiK = [Globalization.CultureInfo]::CurrentCulture
try { [Globalization.CultureInfo]::CurrentCulture = [Globalization.CultureInfo]::GetCultureInfo('tr-TR'); $kulturTamam = ((1.5).ToString() -eq '1,5') } catch { $kulturTamam = $false } finally { [Globalization.CultureInfo]::CurrentCulture = $eskiK }
if (-not $kulturTamam) { $kirmizi++; Write-Host "  KIRMIZI tr-TR kültürü kurulamadı — ondalık virgül vakası bu makinede KÖR" -ForegroundColor Red } else { "  YEŞİL  tr-TR kültürü kuruldu (1.5 → '1,5')" }

foreach ($r in (VakaKos $kutMetin)) {
  if ($r.tamam) { "  YEŞİL  $($r.ad)" } else { $kirmizi++; Write-Host "  KIRMIZI $($r.ad) (beklenen $($r.bek), sonuç $($r.gercek))" -ForegroundColor Red }
}

# (1) bağlantı
function Oku([string]$Goreli) { [IO.File]::ReadAllText((Join-Path $depoKok ($Goreli -replace '/', [IO.Path]::DirectorySeparatorChar)), [Text.Encoding]::UTF8) }
$baglar = @(
  @{ dosya = '.github/workflows/bulut-sira.yml'; desen = 'motor/bulut-sira\.ps1 -Dagit'; ad = 'robot sürücüyü -Dagit ile çağırıyor' }
  @{ dosya = '.github/workflows/bulut-sira.yml'; desen = '(?m)^\s*-\s*cron:'; ad = 'robot zamanlı (cron)' }
  @{ dosya = '.github/workflows/bulut-sira.yml'; desen = 'actions:\s*write'; ad = 'robotun dispatch yetkisi (actions: write)' }
  @{ dosya = '.github/workflows/bulut-sira.yml'; desen = 'group:\s*bulut-sira'; ad = 'robot tek sıra (concurrency) — iki tur aynı planı açmasın' }
  @{ dosya = 'motor/bulut-sira.ps1'; desen = 'bulut-sira-karar\.ps1'; ad = 'sürücü karar kütüphanesini yüklüyor' }
  @{ dosya = 'motor/bulut-sira.ps1'; desen = 'BsKarar -Ayar'; ad = 'sürücü BsKarar ile karar veriyor' }
  @{ dosya = 'motor/bulut-sira.ps1'; desen = 'butce_usd=\$\(\$kr\.butce\)'; ad = 'dispatch bütçeyi normalize değerden geçiriyor' }
  @{ dosya = '.github/workflows/dogrula.yml'; desen = 'bulut-sira-sinavi\.ps1'; ad = 'öz-sınav dogrula.yml matrisinde' }
)
foreach ($b in $baglar) {
  $say = ([regex]::Matches((Oku $b.dosya), $b.desen)).Count
  if ($say -lt 1) { $kirmizi++; Write-Host "  KIRMIZI bağlı değil: $($b.ad) ($($b.dosya))" -ForegroundColor Red } else { "  YEŞİL  bağlı: $($b.ad)" }
}
# dispatch satırında zincir/halka girdisi OLMAMALI (halkayı bulut-uretim kendisi yönetir)
if ((Oku 'motor/bulut-sira.ps1') -match "-f', 'zincir=") { $kirmizi++; Write-Host "  KIRMIZI sürücü zincir girdisi gönderiyor (halka bulut-uretim'in işi)" -ForegroundColor Red } else { "  YEŞİL  sürücü zincir girdisi göndermiyor" }

# canlı sıra dosyası: okunuyor mu, pay tablosu sağlam mı, her satır biçimce geçerli mi (bozuk satır push anında KIRMIZI)
$canliSatir = 0
try {
  $sb2 = [scriptblock]::Create("param(`$ham)`n" + $kutMetin + "`n" + @'
$n = $ham | ConvertFrom-Json
$pt = BsPayTablosu $n
$sat = @(); if ($n.PSObject.Properties['sira'] -and $null -ne $n.sira) { $sat = @($n.sira | ForEach-Object { $_ }) }
foreach ($s in $sat) { $d = BsSatirDenetle $s $pt 5; if (-not $d.tamam) { "BOZUK: $($d.plan) — $($d.neden)" } }
"SATIR:$($sat.Count)"
'@)
  foreach ($c in @(& $sb2 (Oku 'veri/sinav/bulut-sira.json'))) {
    if ("$c" -like 'SATIR:*') { $canliSatir = [int]("$c".Substring(6)) } else { $kirmizi++; Write-Host "  KIRMIZI sıra dosyası: $c" -ForegroundColor Red }
  }
  "  YEŞİL  sıra dosyası okundu ($canliSatir satır biçimce denetlendi)"
} catch { $kirmizi++; Write-Host "  KIRMIZI sıra dosyası okunamadı: $($_.Exception.Message)" -ForegroundColor Red }

# (2) mutasyon: her bozma en az bir vakayı düşürmeli
$MUTASYONLAR = @(
  @{ ad = 'toplam pay denetimi kapalı'; eski = 'if ($toplamAcik -ge $toplamPay) {'; yeni = 'if ($false) {' }
  @{ ad = 'sınav payı denetimi kapalı'; eski = 'if ($sayac[$d.sinav] -ge $payTablo[$d.sinav]) {'; yeni = 'if ($false) {' }
  @{ ad = 'açık koşu (koşan plan) denetimi kapalı'; eski = 'if ($acikPlanlar -contains $d.plan) {'; yeni = 'if ($false) {' }
  @{ ad = 'geçmişte açılmış plan denetimi kapalı'; eski = 'if ($sonrakiler.Count -gt 0) {'; yeni = 'if ($false) {' }
  @{ ad = 'açık koşular plan değil koşu sayılır (halka çift sayım)'; eski = '$acikPlanlar = @($acikListe | Sort-Object -Unique)'; yeni = '$acikPlanlar = @($acikListe)' }
  @{ ad = 'karar içinde sayaç artmıyor'; eski = "  `$toplamAcik++`n"; yeni = "`n" }
  @{ ad = 'bütçe biçim denetimi kapalı'; eski = "if (`$metin -notmatch '^\d+(\.\d+)?`$') { return `$null }"; yeni = "if (`$false) { return `$null }" }
  @{ ad = 'bütçe > 0 denetimi kapalı'; eski = '-or $sayi -le 0) { return $null }'; yeni = ') { return $null }' }
  @{ ad = '25 USD ölçüm şartı kapalı'; eski = '-gt $script:BS_OLCUM_ESIGI -and -not $olc) {'; yeni = '-gt 1e9 -and -not $olc) {' }
  @{ ad = 'sırada çift plan denetimi kapalı'; eski = 'if (-not $gorulen.Add($d.plan.ToLowerInvariant())) {'; yeni = 'if ($false) {' }
  @{ ad = 'geçmiş kapsamı (KÖR) denetimi kapalı'; eski = 'if (-not $PencereTam -and'; yeni = 'if ($false -and' }
  @{ ad = 'bütçe kültüre bağlı biçimlenir (virgül tuzağı)'; eski = "return `$sayi.ToString('0.####', `$script:BS_KULTUR)"; yeni = "return `$sayi.ToString('0.####')" }
  @{ ad = 'plan yolu deseni her şeyi kabul eder'; eski = "`$script:BS_PLAN_DESEN   = '"; yeni = "`$script:BS_PLAN_DESEN   = '.'; `$null = '" }
  @{ ad = 'acil fren yok sayılır'; eski = 'if ($durdurulmus) {'; yeni = 'if ($false) {' }
  @{ ad = 'başlığı çözülemeyen açık koşu sayılmaz'; eski = 'if ($acik) { $cozulmeyenAcik++ }'; yeni = 'if ($false) { $cozulmeyenAcik++ }' }
  @{ ad = 'yeniden=true bayrağı yok sayılır'; eski = 'if ($d.yeniden) { $sinir = $d.eklenme }'; yeni = 'if ($false) { $sinir = $d.eklenme }' }
)
foreach ($m in $MUTASYONLAR) {
  $kaynak = $kutMetin -replace "`r`n", "`n"
  if (-not $kaynak.Contains($m.eski)) { $kirmizi++; Write-Host "  KIRMIZI mutasyon kurulamadı (kütüphane metni değişmiş): $($m.ad)" -ForegroundColor Red; continue }
  $dusen = @((VakaKos ($kaynak.Replace($m.eski, $m.yeni))) | Where-Object { -not $_.tamam }).Count
  if ($dusen -lt 1) { $kirmizi++; Write-Host "  KIRMIZI mutasyon sınavı düşürmedi: $($m.ad)" -ForegroundColor Red } else { "  YEŞİL  mutasyon '$($m.ad)' → $dusen vaka düştü" }
}

$toplam = 1 + $VAKALAR.Count + $baglar.Count + 2 + $MUTASYONLAR.Count
if ($kirmizi) { Write-Host "BULUT SIRASI ÖZ-SINAVI KIRMIZI ($kirmizi / $toplam)" -ForegroundColor Red; exit 1 }
"BULUT SIRASI ÖZ-SINAVI YEŞİL ($toplam denetim: $($VAKALAR.Count) vaka · $($baglar.Count + 1) bağlantı · sıra dosyası · kültür · $($MUTASYONLAR.Count) mutasyon)"
