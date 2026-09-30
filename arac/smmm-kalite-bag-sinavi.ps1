# KAPI-KALITE → BİTİRME YAYIN ŞARTI BAĞI ÖZ-SINAVI (30.09.2026, Cem "1.2.3")
# Sınanan: arac/smmm-yayin-sarti.ps1 SmmmYeniSoruMu + SmmmKaliteNeden (KAPI-AS2 + KAPI-EK yalnız YENİ soruya) ve SmmmYayinSarti'ya bağlı mı.
# Mantığın kendisi (hangi cümle eski kural) arac/eski-kural-kapisi.js --sinav'da; burada yalnız BAĞ ve YENİ/ESKİ ayrımı.
# Vakalar UYDURMA kısa cümlelerdir (depo public). Node gerekir (yoksa KIRMIZI: kapı kör çalışır, sınav bunu gizlemez).
# MUTASYON: kilit koşullar tek tek bozulur, her bozmada en az bir vaka DÜŞMELİ (CLAUDE.md kapı kuralı 8).
$ErrorActionPreference = 'Stop'
$buDizin = $(if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$sartMetin = [IO.File]::ReadAllText([IO.Path]::Combine($buDizin, 'smmm-yayin-sarti.ps1'), [Text.Encoding]::UTF8)
$kopruYol = [IO.Path]::Combine($buDizin, 'soru-kalite-kapisi.ps1')
$blokEsle = [regex]::Match($sartMetin, '(?s)\$script:SMMM_KALITE_BASLANGIC\s*=.*?(?=\r?\nfunction SmmmParmakIzi)')
if (-not $blokEsle.Success) { Write-Host 'KIRMIZI: smmm-yayin-sarti.ps1 içinde KAPI-KALITE bloğu bulunamadı' -ForegroundColor Red; exit 1 }
$blok = $blokEsle.Value.Replace("(Join-Path `$PSScriptRoot 'aciklama-hakemi-uretim.ps1')", "'" + [IO.Path]::Combine($buDizin, 'aciklama-hakemi-uretim.ps1') + "'")

function S([string]$aciklamaA, [string]$korTarih, [string]$hakem2Tarih, [string]$ah = 'TEMIZ') {
  $o = [ordered]@{ soru = 'İşletme 100.000 TL + KDV mal satmıştır (KDV oranı %20).'; siklar = [ordered]@{ A = '20.000'; B = '18.000' }; dogru = 'A'; aciklama = [ordered]@{ A = $aciklamaA } }
  if ($korTarih) { $o.kor_cozum = [ordered]@{ dogru_mu = $true; tarih = $korTarih } }
  if ($hakem2Tarih) { $o.hakem2 = [ordered]@{ karar = 'EVET'; tarih = $hakem2Tarih } }
  if ($ah) { $o.aciklama_hakem = [ordered]@{ karar = $ah } }
  return ([pscustomobject]$o | ConvertTo-Json -Depth 6 | ConvertFrom-Json)
}
$ESKI = 'KDV oranı %18 uygulanır.'; $TEMIZ = 'KDV oranı %20 uygulanır; 100.000 x 0,20 = 20.000.'
$VAKALAR = @(
  @{ ad = 'yeni soru (kör 02.10) + eski KDV %18 → DÜŞER'; bek = $true; s = (S $ESKI '2026-10-02' '') }
  @{ ad = 'yeni soru ISO tarih (01.10 08:00) → DÜŞER'; bek = $true; s = (S $ESKI '2026-10-01T08:00:00Z' '') }
  @{ ad = 'kör eski, hakem2 yeni (yeniden hakem) → DÜŞER'; bek = $true; s = (S $ESKI '2026-09-20' '2026-10-03') }
  @{ ad = 'yayındaki eski soru (kör 15.09) → GEÇER (çekilmez)'; bek = $false; s = (S $ESKI '2026-09-15' '2026-09-16') }
  @{ ad = 'tarihsiz soru → GEÇER (eski sayılır)'; bek = $false; s = (S $ESKI '' '') }
  @{ ad = 'yeni ve temiz soru → GEÇER'; bek = $false; s = (S $TEMIZ '2026-10-02' '2026-10-02') }
  @{ ad = 'yeni temiz soru, açıklama hakemi kararı YOK → DÜŞER'; bek = $true; s = (S $TEMIZ '2026-10-02' '' '') }
  @{ ad = 'yeni temiz soru, açıklama hakemi KUSURLU → DÜŞER'; bek = $true; s = (S $TEMIZ '2026-10-02' '' 'KUSURLU') }
  @{ ad = 'eski soru, açıklama hakemi kararı yok → GEÇER (çekilmez)'; bek = $false; s = (S $TEMIZ '2026-09-15' '' '') }
  @{ ad = 'yeni soru + THP''de yanlış hesap adı (252 Taşıtlar, KAPI-HK) → DÜŞER'; bek = $true; s = (S 'Kayıt: 252 TAŞITLAR hesabı borçlandırılır.' '2026-10-02' '') }
)

function VakaKos([string]$blokKaynak) {
  $sb = [scriptblock]::Create("param(`$vakalar, `$kopru)`n. `$kopru`n" + $blokKaynak + "`n" + @'
foreach ($v in $vakalar) { $n = SmmmKaliteNeden 'sinav' $v.s; $b = [bool]$n; [pscustomobject]@{ ad = $v.ad; bek = $v.bek; bulundu = $b; tamam = ($b -eq $v.bek) } }
'@)
  return @(& $sb $VAKALAR $kopruYol 3>$null)
}

$kirmizi = 0
if (-not (Get-Command node -ErrorAction SilentlyContinue)) { Write-Host 'KIRMIZI: node yok — kapı KÖR çalışır' -ForegroundColor Red; exit 1 }
foreach ($r in (VakaKos $blok)) { if ($r.tamam) { "  YEŞİL  $($r.ad)" } else { $kirmizi++; Write-Host "  KIRMIZI $($r.ad)" -ForegroundColor Red } }

if (([regex]::Matches($sartMetin, 'SmmmKaliteNeden \$anahtar \$v')).Count -lt 1) { $kirmizi++; Write-Host '  KIRMIZI kapı SmmmYayinSarti''ya bağlı değil' -ForegroundColor Red } else { '  YEŞİL  bağ: SmmmYayinSarti → SmmmKaliteNeden' }

$MUTASYONLAR = @(
  @{ ad = 'yeni soru testi hep yanlış'; eski = '"$t" -ge $script:SMMM_KALITE_BASLANGIC'; yeni = '$false' }
  @{ ad = 'bulgu olsa da geçir'; eski = 'if ($kq.Count) { return'; yeni = 'if ($false) { return' }
  @{ ad = 'en yeni tarih yerine en eski'; eski = 'Sort-Object -Descending'; yeni = 'Sort-Object' }
  @{ ad = 'başlangıç geri çekildi (eski soru da düşer)'; eski = "else { '2026-10-01' }"; yeni = "else { '2000-01-01' }" }
  @{ ad = 'açıklama hakemi denetimi kapalı'; eski = 'if (AhSecilemez $soruNesne)'; yeni = 'if ($false)' }
)
foreach ($m in $MUTASYONLAR) {
  if (-not $blok.Contains($m.eski)) { $kirmizi++; Write-Host "  KIRMIZI mutasyon kurulamadı (kapı metni değişmiş): $($m.ad)" -ForegroundColor Red; continue }
  $dusen = @((VakaKos ($blok.Replace($m.eski, $m.yeni))) | Where-Object { -not $_.tamam }).Count
  if ($dusen -lt 1) { $kirmizi++; Write-Host "  KIRMIZI mutasyon sınavı düşürmedi: $($m.ad)" -ForegroundColor Red } else { "  YEŞİL  mutasyon '$($m.ad)' → $dusen vaka düştü" }
}

$toplam = $VAKALAR.Count + 1 + $MUTASYONLAR.Count
if ($kirmizi) { Write-Host "KAPI-KALITE BİTİRME BAĞI ÖZ-SINAVI KIRMIZI ($kirmizi / $toplam)" -ForegroundColor Red; exit 1 }
"KAPI-KALITE BİTİRME BAĞI ÖZ-SINAVI YEŞİL (${toplam}: $($VAKALAR.Count) vaka · 1 bağ · $($MUTASYONLAR.Count) mutasyon)"
