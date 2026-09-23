#requires -Version 5.1
<#
================================================================================
  ENGEL DOĞRULAMA — ÖZ-SINAV   (23.09.2026) · bedel 0

  NİYE VAR: arac/mevzuat-degisti-dogrula.ps1 yayından çekilmiş soruyu "kanıtla" geri açar. 23.09'da iki kez
  YANLIŞ KANIT üretti:
    1) git'i `cmd /c` içinden çağırıyordu; cmd'de '^' kaçış karakteri → 'X^' sessizce 'X' oldu, alarm SONRASI
       taban okundu, "AYNI-METİN" anlamsızdı (TTK geç. m.7'de GERÇEK AYM iptaline "aynı" dedi).
    2) GM elle karşılaştırmada kelime ÇOK-KÜMESİNE baktı (sıra körü) — m.617/623'e "birebir" dendi, tam metin farklıydı.
  Kanıt yanlışsa yanlış soru yayına döner. Bu sınav: yakalaması gereken (değişmiş metin → kanıtsız) + yanlış alarm
  vermemesi gereken (diziliş/dipnot farkı → kanıtlı) + '^' gerilemesi.
  ⛔ REPLİKA YOK: işlevler gerçek betikten AST ile çıkarılır (DizilisBul, EnGecTarih, DipnotSil; Damga/Sadelestir madde-damga'dan).
================================================================================
#>
param([switch]$Sessiz)
$ErrorActionPreference = 'Stop'
$buDizin = $(if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$kok = Split-Path -Parent $buDizin
function Cek([string]$yol, [string[]]$adlar) {
  $tok = $null; $err = $null; $ast = [Management.Automation.Language.Parser]::ParseFile($yol, [ref]$tok, [ref]$err)
  if ($err -and $err.Count) { throw "ayrıştırılamadı: $yol" }
  foreach ($a in $adlar) {
    $fn = @($ast.FindAll({ param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $a }, $true)) | Select-Object -First 1
    if (-not $fn) { throw "$a işlevi $yol içinde YOK (adı değiştiyse sınav da güncellenir)" }
    $fn.Extent.Text
  }
}
$hedef = Join-Path $buDizin 'mevzuat-degisti-dogrula.ps1'
. ([scriptblock]::Create(((Cek (Join-Path $kok 'motor\madde-damga.ps1') @('Sadelestir', 'Damga')) -join "`n")))
. ([scriptblock]::Create(((Cek $hedef @('DizilisBul', 'EnGecTarih', 'DipnotSil')) -join "`n")))
$gecti = 0; $dustu = New-Object System.Collections.Generic.List[string]
function T([string]$ad, [bool]$k) { if ($k) { $script:gecti++; if (-not $Sessiz) { Write-Host "  geçti $ad" } } else { $script:dustu.Add($ad) } }
function P([string]$ad, [string]$m) { [pscustomobject]@{ kaynak_ad = $ad; metin = $m } }

# --- AYNI-METİN (diziliş araması)
$a = P 'X m.5 [1/2]' 'Birinci fıkra metni burada.'; $b = P 'X m.5/A' 'Ek madde metni burada.'
$eskiMetin = "$($b.metin) $($a.metin)"   # tabanda ters dizilişle birleşmiş
T 'diziliş kaymış metin → bulunur (22.09 VUK vakası)' ([bool](DizilisBul @($a, $b) $eskiMetin.Length (Damga $eskiMetin)))
$c = P 'X m.5 [1/2]' 'Birinci fıkra metni bunada.'   # AYNI BOY, farklı metin: boy süzgeci değil DAMGA yakalamalı
T 'bir parçanın metni aynı boyda değişmiş → BULUNMAZ (damga yakalar)' (-not (DizilisBul @($c, $b) $eskiMetin.Length (Damga $eskiMetin)))
$d = P 'X m.5/B' 'Yeni eklenen ayrı madde.'
T 'aynı anahtara ayrı kayıt eklenmiş → eski metin alt kümeden bulunur' ([bool](DizilisBul @($a, $d, $b) $eskiMetin.Length (Damga $eskiMetin)))
T 'boyu tutmayan taban → BULUNMAZ' (-not (DizilisBul @($a, $b) ($eskiMetin.Length + 5) (Damga $eskiMetin)))
# --- DipnotSil (KANUN-AYNASI-AYNI)
T 'dipnot numarası farkı eşit sayılır (TTK geç. m.13: yetkilidir.116 / .115)' ((DipnotSil 'ticaret sicili müdürlüğü yetkilidir.116 (…)117') -eq (DipnotSil 'ticaret sicili müdürlüğü yetkilidir.115 (…)116'))
T 'tutar/tarih/oran DOKUNULMAZ (1.000 TL / 23/9/2026 / %20)' ((DipnotSil 'sermaye 50.000 TL ve 23/9/2026 tarihinde %20') -ne (DipnotSil 'sermaye 60.000 TL ve 23/9/2026 tarihinde %20'))
T 'bent numarası (a) 5 değişirse FARKLI' ((DipnotSil 'süre 5 yıl olup') -ne (DipnotSil 'süre 10 yıl olup'))
T 'kelimelerin YERİ değişirse FARKLI (m.617/623 dersi: çok-küme körlüğü)' ((DipnotSil 'alacaklı borçluya bildirir') -ne (DipnotSil 'borçlu alacaklıya bildirir'))
T 'AYM iptal ibaresi eklenmişse FARKLI (TTK geç. m.7)' ((DipnotSil 'on yıl sonra Hazineye intikal eder.') -ne (DipnotSil '(…) (İptal cümle: Anayasa Mahkemesinin 10/9/2025 tarihli kararı ile.)'))
# --- EnGecTarih (DEĞİŞİKLİK-YOK)
T 'bitişik yazılmış şerh tarihi okunur (15/7/20166728 → 2016)' ((EnGecTarih '(Yeniden düzenleme: 15/7/20166728/22 md.)').Year -eq 2016)
T 'en geç tarih seçilir' ((EnGecTarih '(Mülga: 30/12/1980) (Değişik:5/12/2019-7194/25 md.)').Year -eq 2019)
# --- '^' gerilemesi: cat-file çağrıları ÇÖZÜLMÜŞ kimlikle yapılmalı
$kaynak = [IO.File]::ReadAllText($hedef, [Text.Encoding]::UTF8)
T "cat-file 'X^' kullanmıyor (TabanCommit/AynaCommit doğrudan cmd'ye verilmiyor)" (-not ($kaynak -match 'cat-file blob \$\(\$(TabanCommit|AynaCommit|AynaYeniCommit)\)'))
T 'sürümler git rev-parse --verify ile çözülüyor' (($kaynak -match 'rev-parse --verify --quiet "\$TabanCommit"') -and ($kaynak -match 'rev-parse --verify --quiet "\$AynaCommit"'))
$top = $gecti + $dustu.Count
Write-Host "ENGEL DOĞRULAMA ÖZ-SINAVI: $gecti/$top geçti"
if ($dustu.Count) { $dustu | ForEach-Object { Write-Host "  ✗ $_" }; exit 1 }
exit 0
