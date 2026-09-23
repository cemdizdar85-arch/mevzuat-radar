#requires -Version 5.1
<#
================================================================================
  SMMM KONU YENİDEN ETİKETLEME — yanlış etiketli soruyu ÇEKMEZ, konusunu düzeltir   23.09.2026 · bedel 0

  Cem 23.09 ("1.2.3 üçünü de yap"): etiket düzeltmesi yayından çekme değil YENİDEN ETİKETLEME olsun — soru
  doğruysa yalnız konu adı düzelir, soru kasada kalır; kapsama tablosu gerçek konuları sayar, rozetteki
  "N kez çıktı" doğru konudan hesaplanır.
  GİRDİ: arac/smmm-konu-uyum-model.ps1 çıktısı (veri/fabrika/smmm-konu-uyum-model-<kume>.json).
  YALNIZ şu kayıt düzeltilir: model "HAYIR" dedi + önerdiği konu dersin KONU LİSTESİNDE aynen var (LISTEDE_YOK / KISMEN dokunulmaz).
  NASIL: parti dosyasında o sorunun `konu` alanı yenisiyle değişir, eskisi `konu_duzeltme` {eski, kaynak, tarih} içinde
  saklanır. Yazmadan önce EŞDEĞERLİK: dosyanın geri kalanı (değişen iki alan dışında) okunup eskisiyle birebir
  kıyaslanır; tek fark varsa o parti YAZILMAZ. Sonra arac/parti-senkron.ps1 -Yukle ile ambara.
  ⛔ KOŞAN DALGA: arac/bulut-kosan-etiketler.ps1 -Kati çıktısındaki partiler ATLANIR (CLAUDE.md: bulutta koşan
     partiye ambardan yazılmaz) — bir sonraki koşuda yeniden denenir.
  🚫 GÖRMEZ: modelin önerdiği konunun doğruluğunu (anahtar karnesi ölçer); sorunun cevabını (değerlendirilmez).
  ⛔ ELLE ÖRNEKLEM (23.09, Cem "1.2.3"): model doğru etiketlilerin %17'sine HAYIR dedi → -Yaz yalnız
     arac/konu-orneklem-kapisi.ps1 izin verirse yazar (örneklem max(5,⌈%10⌉) tamamı okunmuş, yanlış ≤ %10,
     model sonucu değişmemiş). YANLIŞ işaretli kayıt hiç yazılmaz. Örneklem: veri/sinav/smmm-konu-orneklem-<kume>.json
  KULLANIM: powershell -NoProfile -File arac/smmm-konu-yeniden-etiketle.ps1 [-Kume kasa] [-OrneklemYaz | -Yaz]
            -OrneklemYaz: okunacak örneklemi dosyaya yazar (karar BEKLİYOR); okuyan DOĞRU/YANLIŞ işaretler.
================================================================================
#>
param([ValidateSet('anahtar', 'kasa')][string]$Kume = 'kasa', [switch]$Yaz, [switch]$OrneklemYaz)
$ErrorActionPreference = 'Stop'
$buDizin = $(if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$kok = Split-Path -Parent $buDizin
. (Join-Path $buDizin 'konu-orneklem-kapisi.ps1')
$girdi = Join-Path $kok "veri\fabrika\smmm-konu-uyum-model-$Kume.json"
if (-not (Test-Path $girdi)) { throw "model sonucu yok: $girdi — önce arac/smmm-konu-uyum-model.ps1 -Kume $Kume" }
$tabloKonu = @{}; foreach ($r in (Import-Csv (Join-Path $kok 'veri\fabrika\smmm-kapsama.csv') -Encoding UTF8)) { $tabloKonu["$($r.konu)"] = 1 }
$kosan = @{}
try { foreach ($e in @(& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $buDizin 'bulut-kosan-etiketler.ps1') -Kati 2>$null)) { if ("$e".Trim()) { $kosan["$e".Trim()] = 1 } } }
catch { throw "koşan dalgalar okunamadı — yazmak güvenli değil: $($_.Exception.Message)" }
if ($LASTEXITCODE) { throw 'koşan dalgalar okunamadı (bulut-kosan-etiketler -Kati çıkış ≠ 0) — yazılmadı' }

$sonuc = @(Get-Content $girdi -Raw -Encoding UTF8 | ConvertFrom-Json | ForEach-Object { $_ })
$aday = @($sonuc | Where-Object { $_.uyum -eq 'HAYIR' -and "$($_.dogru_konu)" -and "$($_.dogru_konu)" -ne 'LISTEDE_YOK' })
$gecerli = @($aday | Where-Object { $tabloKonu.ContainsKey("$($_.dogru_konu)") })
Write-Host ("model sonucu {0} · HAYIR+öneri {1} · önerisi konu listesinde aynen var {2} · koşan dalga partisi {3}" -f $sonuc.Count, $aday.Count, $gecerli.Count, $kosan.Count)
# --- ELLE ÖRNEKLEM KAPISI
$damga = (Get-FileHash $girdi -Algorithm SHA256).Hash.Substring(0, 12)
$ornekDosya = Join-Path $kok "veri\sinav\smmm-konu-orneklem-$Kume.json"
$orn = $null; if (Test-Path $ornekDosya) { $orn = Get-Content $ornekDosya -Raw -Encoding UTF8 | ConvertFrom-Json }
$adayAn = @($gecerli | ForEach-Object { "$($_.an)" })
if ($OrneklemYaz) {
  $eski = @{}; if ($orn -and "$($orn.damga)" -eq $damga) { foreach ($k in @($orn.kayitlar | ForEach-Object { $_ })) { $eski["$($k.an)"] = $k } }
  $sec = @(OrneklemSec $adayAn $damga); $kayitlar = New-Object System.Collections.Generic.List[object]
  foreach ($an in $sec) { if ($eski.ContainsKey($an)) { $kayitlar.Add($eski[$an]); continue }
    $x = $gecerli | Where-Object { "$($_.an)" -eq $an } | Select-Object -First 1
    $kayitlar.Add([ordered]@{ an = $an; onerilen_konu = "$($x.dogru_konu)"; gerekce = "$($x.gerekce)"; karar = 'BEKLİYOR'; okuyan = ''; not = '' }) }
  [IO.File]::WriteAllText($ornekDosya, (ConvertTo-Json -InputObject ([ordered]@{ damga = $damga; girdi = "veri/fabrika/smmm-konu-uyum-model-$Kume.json"; tarih = (Get-Date -Format 'yyyy-MM-dd HH:mm'); aday = $adayAn.Count; kayitlar = $kayitlar.ToArray() }) -Depth 4), (New-Object Text.UTF8Encoding $false))
  "ÖRNEKLEM YAZILDI: $($sec.Count)/$($adayAn.Count) aday → $ornekDosya (her kayıt okunup karar DOĞRU/YANLIŞ yazılır)"; exit 0
}
$kapi = OrneklemKapisi $adayAn $orn $damga
Write-Host "ÖRNEKLEM KAPISI: $(if ($kapi.izin) { 'İZİN' } else { 'KAPALI' }) — $($kapi.sebep)"
if ($Yaz -and -not $kapi.izin) { throw "yazılmadı — örneklem kapısı kapalı: $($kapi.sebep)" }
$dislaAn = @{}; foreach ($d in @($kapi.disla)) { $dislaAn["$d"] = 1 }
$gecerli = @($gecerli | Where-Object { -not $dislaAn.ContainsKey("$($_.an)") })
$partiye = $gecerli | Group-Object { ("$($_.an)" -split '/')[0] }
$yazilan = 0; $atlanan = 0; $duzelen = 0; $kayit = New-Object System.Collections.Generic.List[object]
foreach ($g in $partiye) {
  $et = $g.Name
  if ($kosan.ContainsKey($et)) { $atlanan += $g.Count; Write-Host "  ATLANDI (koşan dalga): $et · $($g.Count) soru"; continue }
  $f = Join-Path $kok "veri\fabrika\kalip-parti-$et.json"; if (-not (Test-Path $f)) { $atlanan += $g.Count; continue }
  $ham = [IO.File]::ReadAllText($f, [Text.Encoding]::UTF8); $j = $ham | ConvertFrom-Json
  $once = $ham | ConvertFrom-Json
  foreach ($x in $g.Group) {
    $id = ("$($x.an)" -split '/')[1]; $v = $j.$id; if (-not $v) { continue }
    $eski = "$($v.konu)"; if ($eski -eq "$($x.dogru_konu)") { continue }
    $v.konu = "$($x.dogru_konu)"
    $v | Add-Member -NotePropertyName konu_duzeltme -NotePropertyValue ([ordered]@{ eski = $eski; kaynak = "model $Kume ($($x.gerekce))"; tarih = (Get-Date -Format 'yyyy-MM-dd') }) -Force
    $kayit.Add([pscustomobject]@{ an = $x.an; eski = $eski; yeni = "$($x.dogru_konu)" }); $duzelen++
  }
  # EŞDEĞERLİK: iki alan dışında fark yok mu?
  $yeniMetin = ConvertTo-Json -InputObject $j -Depth 30
  $geri = $yeniMetin | ConvertFrom-Json
  foreach ($p in $geri.PSObject.Properties) { if ($p.Value -and $p.Value.PSObject.Properties['konu_duzeltme']) { $p.Value.PSObject.Properties.Remove('konu_duzeltme'); $p.Value.konu = "$($once.($p.Name).konu)" } }
  if ((ConvertTo-Json -InputObject $geri -Depth 30 -Compress) -ne (ConvertTo-Json -InputObject $once -Depth 30 -Compress)) { Write-Host "  ⛔ EŞDEĞERLİK DÜŞTÜ, yazılmadı: $et" -ForegroundColor Red; $atlanan += $g.Count; continue }
  if ($Yaz) { [IO.File]::WriteAllText($f, $yeniMetin, (New-Object Text.UTF8Encoding $false)); $yazilan++
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $buDizin 'parti-senkron.ps1') -Yukle -Etiket $et -Sinav SMMM -Yaz *> $null
    if ($LASTEXITCODE) { Write-Host "  ⚠ ambara yüklenemedi: $et (yerelde yazıldı)" -ForegroundColor Yellow } }
}
$kayit | Select-Object -First 15 | ForEach-Object { "  $($_.an): '$($_.eski)' → '$($_.yeni)'" }
"YENİDEN ETİKET: düzeltilecek $duzelen soru · parti $(@($partiye).Count) · yazılan parti $yazilan · atlanan (koşan/eşdeğerlik) $atlanan$(if (-not $Yaz) { ' · KURU — hiçbir yere yazılmadı' })"
