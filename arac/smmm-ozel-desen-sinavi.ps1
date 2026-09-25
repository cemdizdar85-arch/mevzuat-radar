#requires -Version 5.1
<#
================================================================================
  SMMM ÖZEL DESEN BLOĞU — ÖZ-SINAV + EŞDEĞERLİK PROVASI   25.09.2026 · bedel 0
  motor/kalip-parti-uret.ps1'e yalnız bitirmede çalışan konu→kaynak desenleri eklendi ($OZEL_DESEN_TAM). Bu sınav:
   · SGS koşusunda sözlüğün BİREBİR aynı kaldığını,
   · SMMM'de var olan anahtarın EZİLMEDİĞİNİ,
   · yeni anahtarların kök eşleşmesiyle BAŞKA konuyu yakalamadığını — depodaki BÜTÜN konu adlarında (veri/sinav/konu/*.json,
     SGS+SMMM+KGK) eski ve yeni sözlüğün seçtiği desen kıyaslanarak (örneklem yok) ölçer.
  ⛔ REPLİKA YOK: sözlük ataması, SMMM bloğu, Katla2 ve OzelDesenKokAnahtari üreticinin kendisinden AST ile alınır.
  GÖRMEZ: desenin ambardan ne çektiğini (ağ ister; 25.09'da elle ölçüldü) · hakem sonucunu (yalnız yeni dalgada görülür).
================================================================================
#>
param([switch]$Sessiz)
$ErrorActionPreference = 'Stop'
$buDizin = $(if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$depoKok = Split-Path -Parent $buDizin
$ureticiYol = $(if ($env:OZEL_DESEN_URETICI) { $env:OZEL_DESEN_URETICI } else { Join-Path (Join-Path $depoKok 'motor') 'kalip-parti-uret.ps1' })
$belirtec = $null; $hata = $null
$agac = [Management.Automation.Language.Parser]::ParseFile($ureticiYol, [ref]$belirtec, [ref]$hata)
if ($hata.Count) { throw "üretici ayrıştırılamadı: $($hata[0].Message)" }
function UstDuzey([string]$desen) { return @($agac.EndBlock.Statements | Where-Object { $_.Extent.Text -match $desen }) }
$sozlukMetni = @(UstDuzey '^\$OZEL_DESEN=@\{')[0].Extent.Text
$tamMetni = @(UstDuzey '^\$OZEL_DESEN_TAM=')[0].Extent.Text + "`n" + @(UstDuzey '^\$OZEL_DESEN_KOK_SIRA=')[0].Extent.Text
$blokMetni = @(UstDuzey "^if\(.+?\)\{\s*\`$gugD=")[0].Extent.Text
$fonkMetni = @($agac.FindAll({ param($d) $d -is [Management.Automation.Language.FunctionDefinitionAst] -and $d.Name -in 'Katla2', 'OzelDesenKokAnahtari' }, $true) | ForEach-Object { $_.Extent.Text }) -join "`n"
if (-not ($sozlukMetni -and $tamMetni -and $blokMetni -and $fonkMetni)) { throw 'üreticide beklenen parçalar bulunamadı (sözlük / TAM / SMMM bloğu / işlevler)' }
Invoke-Expression $fonkMetni

$gecti = 0; $dustu = New-Object System.Collections.Generic.List[string]
function T([string]$ad, [bool]$k) { if ($k) { $script:gecti++; if (-not $Sessiz) { Write-Host "  geçti $ad" } } else { $script:dustu.Add($ad) } }
function Kur([string]$sinavAdi, $onEk) {
  $script:Sinav = $sinavAdi
  Invoke-Expression $sozlukMetni; $script:OZEL_DESEN = $OZEL_DESEN
  if ($onEk) { foreach ($a in $onEk.Keys) { $script:OZEL_DESEN[$a] = $onEk[$a] } }
  Invoke-Expression $tamMetni; $script:OZEL_DESEN_TAM = $OZEL_DESEN_TAM; $script:OZEL_DESEN_KOK_SIRA = $OZEL_DESEN_KOK_SIRA
  $Sinav = $sinavAdi; $OZEL_DESEN = $script:OZEL_DESEN; $OZEL_DESEN_TAM = $script:OZEL_DESEN_TAM
  Invoke-Expression $blokMetni
}
function Imza($sozluk) { return (@($sozluk.Keys | Sort-Object | ForEach-Object { "$_=" + (@($sozluk[$_]) -join '|') }) -join "`n") }

# taban: yalnız sözlük ataması (blok yok)
Invoke-Expression $sozlukMetni; $taban = $OZEL_DESEN.Clone(); $tabanImza = Imza $taban

Kur 'SGS' $null
T 'SGS koşusunda sözlük BİREBİR aynı' ((Imza $script:OZEL_DESEN) -eq $tabanImza)
T 'SGS koşusunda birebir-anahtar kümesi boş' ($script:OZEL_DESEN_TAM.Count -eq 0)

Kur 'SMMM' $null
$yeni = @($script:OZEL_DESEN_TAM)
T "SMMM'de yeni birebir anahtar eklendi ($($yeni.Count))" ($yeni.Count -ge 20)
T 'SMMM: taban anahtarların hiçbiri değişmedi' (@($taban.Keys | Where-Object { (@($script:OZEL_DESEN[$_]) -join '|') -ne (@($taban[$_]) -join '|') }).Count -eq 0)
T 'SMMM: her yeni anahtarın deseni dolu' (@($yeni | Where-Object { -not @($script:OZEL_DESEN[$_]).Count }).Count -eq 0)
T "SMMM: birebir konu kendi desenini alır ('sgk vergi odemesi')" ((OzelDesenKokAnahtari 'sgk vergi odemesi') -eq 'sgk vergi odemesi')
# M2 vakası (25.09 mutasyonda ölçüldü: bugünkü konu adları birebir dışlamasını SINAMIYORDU): 'sgk vergi odemesi'nin kökleri
#   ('vergi','odeme') başka vergi konusunu yakalamamalı.
$OZEL_DESEN = $script:OZEL_DESEN; $OZEL_DESEN_TAM = $script:OZEL_DESEN_TAM; $OZEL_DESEN_KOK_SIRA = $script:OZEL_DESEN_KOK_SIRA
# 25.09 mutasyonda ölçüldü: 'kurumlar vergisi odemesi' bu kuralı SINAMIYORDU (sözlükte önce gelen başka bir 'kurumlar vergisi' anahtarı
#   eşleşmeyi alıyordu). Vaka, köklerini ('vergi','odeme') YALNIZ yeni anahtarın taşıdığı bir adla kurulur.
T "SMMM: birebir anahtar kök eşleşmesine girmez ('qqqq vergi odemesi' SGK desenini ALMAZ)" ((OzelDesenKokAnahtari 'qqqq vergi odemesi') -ne 'sgk vergi odemesi')
# M4 vakası (bugünkü veride eşit puanlı anahtarların deseni aynı olduğu için sıra ölçülemiyordu): eşit puanda SABİT SIRANIN ilki seçilmeli.
$yedekSira = $OZEL_DESEN_KOK_SIRA; $OZEL_DESEN['alfaa betaa'] = @('A'); $OZEL_DESEN['betaa alfaa'] = @('B')
$OZEL_DESEN_KOK_SIRA = @('alfaa betaa', 'betaa alfaa'); $ilk1 = OzelDesenKokAnahtari 'alfaa betaa deltaa'
$OZEL_DESEN_KOK_SIRA = @('betaa alfaa', 'alfaa betaa'); $ilk2 = OzelDesenKokAnahtari 'alfaa betaa deltaa'
T "eşit puanda sabit sıranın İLKİ seçilir (iki sırada: '$ilk1' / '$ilk2')" ($ilk1 -eq 'alfaa betaa' -and $ilk2 -eq 'betaa alfaa')
$OZEL_DESEN.Remove('alfaa betaa'); $OZEL_DESEN.Remove('betaa alfaa'); $OZEL_DESEN_KOK_SIRA = $yedekSira
$smmmSozluk = $script:OZEL_DESEN; $smmmTam = $script:OZEL_DESEN_TAM

# var olan anahtar ezilmez: taban bu anahtarı zaten taşısaydı
Kur 'SMMM' @{ 'trend analizi net satis' = @('ESKI-DESEN') }
T 'SMMM: aynı ad tabanda varsa ESKİ desen korunur' ((@($script:OZEL_DESEN['trend analizi net satis']) -join '|') -eq 'ESKI-DESEN')
T 'SMMM: tabanda olan anahtar birebir kümesine girmez' (-not $script:OZEL_DESEN_TAM.Contains('trend analizi net satis'))

# EŞDEĞERLİK: depodaki bütün konu adlarında kök eşleşmesi eski sözlükle aynı mı (yeni birebir anahtarlar hariç)
$konular = New-Object System.Collections.Generic.HashSet[string]
foreach ($dosya in Get-ChildItem (Join-Path (Join-Path (Join-Path $depoKok 'veri') 'sinav') 'konu') -Filter '*.json') {
  try { $icerik = [IO.File]::ReadAllText($dosya.FullName, [Text.Encoding]::UTF8) | ConvertFrom-Json } catch { continue }
  foreach ($s in @($icerik | ForEach-Object { $_ })) { $ad = $(if ($s -is [string]) { $s } else { "$($s.konu)" }); if ($ad.Trim()) { [void]$konular.Add($ad.ToLowerInvariant()) } }
}
# eski davranış = blok çalışmadan kurulan sözlük (SGS kipi; üreticinin kurduğu gibi, .Clone() YOK — kopya karşılaştırıcıyı değiştirir, ölçüldü)
Kur 'SGS' $null; $OZEL_DESEN = $script:OZEL_DESEN; $OZEL_DESEN_TAM = $script:OZEL_DESEN_TAM; $OZEL_DESEN_KOK_SIRA = $script:OZEL_DESEN_KOK_SIRA
# Kıyaslanan: üreticinin o konu için KULLANACAĞI desen listesi (anahtar adı değil). 25.09 ölçüldü: 'İs kanunu kapsami' gibi büyük 'İ'li
#   adlarda PowerShell sözlüğü birebir aramayı sözlük boyuna göre farklı sonuçlandırıyor (dönen ad 'İs…' ya da 'is…'), ama iki yol da
#   AYNI kayda, aynı desene varıyor. Anahtar adını kıyaslamak bu yüzden yanlış alarm verir.
function DesenCozumu([string]$k) { $a = OzelDesenKokAnahtari $k; if ($a) { return (@($OZEL_DESEN[$a]) -join '|') } else { return '(DesenUret)' } }
$eskiSecim = @{}; foreach ($k in $konular) { $eskiSecim[$k] = DesenCozumu $k }
Kur 'SMMM' $null; $OZEL_DESEN = $script:OZEL_DESEN; $OZEL_DESEN_TAM = $script:OZEL_DESEN_TAM; $OZEL_DESEN_KOK_SIRA = $script:OZEL_DESEN_KOK_SIRA; $smmmTam = $OZEL_DESEN_TAM
$fark = New-Object System.Collections.Generic.List[string]; $bilerek = 0
foreach ($k in $konular) { $yeniSecim = DesenCozumu $k; if ($smmmTam.Contains($k)) { $bilerek++; continue }; if ($yeniSecim -ne $eskiSecim[$k]) { $fark.Add("$k : '$($eskiSecim[$k])' -> '$yeniSecim'") } }
T "EŞDEĞERLİK: $($konular.Count) konu adında seçim değişen yalnız birebir anahtarlar ($bilerek bilerek), başka fark 0" ($fark.Count -eq 0)
if ($fark.Count -and -not $Sessiz) { $fark | Select-Object -First 10 | ForEach-Object { Write-Host "    fark: $_" } }

$top = $gecti + $dustu.Count
Write-Host "SMMM ÖZEL DESEN ÖZ-SINAVI: $gecti/$top geçti · taranan konu adı $($konular.Count) · bilerek değişen $bilerek"
if ($dustu.Count) { $dustu | ForEach-Object { Write-Host "  ✗ $_" }; exit 1 }
exit 0
