#requires -Version 5.1
<#
================================================================================
  PARÇALI MADDE TAMAMLAMA (KAPI-PT) — ÖZ-SINAV  (01.11.2026)  bedel 0, ağ yok

  NİYE: ambarda 4.063 madde parçalı yutulmuş ("GVK (193 s.K.) m.22 [1/3]"); 199'u
  altıdan fazla parça (GVK m.94 [14], KDVK m.17 [19]). motor/kalip-parti-uret.ps1
  atıf genişletmesi her deseni AmbarCek'te limit=6 ile, sırasız çekiyordu: dayanakta
  anılan uzun maddenin parçalarının bir kısmı hakem paketine hiç girmiyordu.

  NE SINAR (gerçek üreticiden AST ile — kopya YOK; Invoke-RestMethod sahte ambar):
    P) ParcaEksik: ad kalıbından eksik kardeş parçalar (saf işlev)
    T) ParcaTamamla: çekme, KAPI-MM, Vergi güncellik, tavan (blok bütün ya da hiç),
       eşdeğerlik (parçalı ad yoksa AYNI nesne, ambar çağrısı 0)
    W) Bağ: hakem atıf bloğunda AmbarCek $atifD 7000'in hemen ardından ParcaTamamla

  -Mutasyon: her kilit parça tek tek bozulur; her bozmada sınav KIRMIZI düşmeli.
  🚫 GÖRMEZ: ambarda hiç olmayan madde (eklenecek parça yok) · kör/KK paketinin özet dalı.
================================================================================
#>
param([switch]$Mutasyon)
$ErrorActionPreference = 'Stop'
$buDizin = $(if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$depoKok = Split-Path -Parent $buDizin
$URETICI = [IO.Path]::Combine($depoKok, 'motor', 'kalip-parti-uret.ps1')
$tk = $null; $hk = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($URETICI, [ref]$tk, [ref]$hk)
if (@($hk).Count) { throw "uretici ayristirma hatasi: $(@($hk)[0].Message)" }
$FONK = @{}
foreach ($fa in @('ParcaEksik', 'ParcaTamamla', 'PaketTavani')) {
  $f = @($ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $fa }, $true)) | Select-Object -First 1
  if (-not $f) { throw "$fa uretici dosyada yok" }
  $FONK[$fa] = $f.Extent.Text
}
$URETICI_METIN = [IO.File]::ReadAllText($URETICI, [Text.Encoding]::UTF8)

# --- sahte ambar: ad -> metin; Invoke-RestMethod ad eşitliğiyle cevap verir ---
$script:SAHTE = @{}
$script:CAGRI = 0
function Invoke-RestMethod {
  param([string]$Uri, $Headers, $TimeoutSec)
  $script:CAGRI++
  $mx = [regex]::Match($Uri, 'kaynak_ad=eq\.([^&]+)')
  if (-not $mx.Success) { return @() }
  $adX = [uri]::UnescapeDataString($mx.Groups[1].Value)
  if ($script:SAHTE.ContainsKey($adX)) { return @([pscustomobject]@{ kaynak_ad = $adX; metin = $script:SAHTE[$adX] }) }
  return @()
}
function Kume($x) { return ((@($x) | Where-Object { $_ }) -join ',') }
function Parca([string]$kokA, [int]$k, [int]$m) { return "$kokA [$k/$m]" }

$G22 = 'GVK (193 s.K.) m.22'; $G94 = 'GVK (193 s.K.) m.94'; $KV5 = 'KVK (5520 s.K.) m.5'; $KD17 = 'KDVK (3065 s.K.) m.17'
$VAKA_P = @(
  , @('P1 tek parça [2/3] -> [1/3],[3/3]', @((Parca $G22 2 3)), (@((Parca $G22 1 3), (Parca $G22 3 3)) -join ','))
  , @('P2 tam madde -> boş', @((Parca $G22 2 3), (Parca $G22 1 3), (Parca $G22 3 3)), '')
  , @('P3 parçalı olmayan ad -> boş', @('GVK (193 s.K.) m.3 - İKİNCİ BÖLÜM Tam Mükellefiyet Mükellefler', 'THP 100 - KASA'), '')
  , @('P4 iki parçalı madde + tek parçalı', @((Parca $KV5 3 4), 'VUK (213 s.K.) m.229', (Parca $KD17 1 2)), (@((Parca $KV5 1 4), (Parca $KV5 2 4), (Parca $KV5 4 4), (Parca $KD17 2 2)) -join ','))
  , @('P5 [1/1] -> boş', @('X m.1 [1/1]'), '')
  , @('P6 başlıklı parçalı ad', @('SMMM ve YMM K. Disiplin Yonetmeligi m.6 [1/3]'), (@('SMMM ve YMM K. Disiplin Yonetmeligi m.6 [2/3]', 'SMMM ve YMM K. Disiplin Yonetmeligi m.6 [3/3]') -join ','))
  , @('P7 boş liste -> boş', @(), '')
  , @('P8 parça kalıbına benzemeyen ad', @('TMS 16 p.12 [giris]', 'Y m.2 [2/3] ek'), '')
  , @('P9 aynı madde iki parça -> tekrar yok', @((Parca $G22 1 3), (Parca $G22 3 3)), (Parca $G22 2 3))
)

function Kos($fonk, [string]$dosyaMetin) {
  $hata = New-Object System.Collections.Generic.List[string]
  . ([scriptblock]::Create(($fonk.Values) -join "`n"))
  $script:SB = @{}; $script:EskiPaketTavani = $false; $script:DersRegex = 'Vergi Mevzuatı'; $script:KGK_AILE_RX = $null
  $script:MULGA_MADDE = New-Object 'System.Collections.Generic.HashSet[string]'; $script:KAPI_MM_SAY = 0; $script:AMBAR_AG_HATASI = $null
  foreach ($v in $VAKA_P) { $g = Kume (ParcaEksik $v[1]); if ($g -ne $v[2]) { $hata.Add("$($v[0]): beklenen '$($v[2])' gelen '$g'") } }

  # T1: 14 parçalı maddenin 6 parçası pakette -> 8 eksik eklenir, sırayla, bütün blok
  $script:SAHTE = @{}; for ($i = 1; $i -le 14; $i++) { $script:SAHTE[(Parca $G94 $i 14)] = "m94 parca $i metni" }
  $ilk = @(1..6 | ForEach-Object { Parca $G94 $_ 14 })
  $s1 = @{ metin = (($ilk | ForEach-Object { "[$_] x" }) -join "`n---`n"); adlar = $ilk; agHatasi = $null }
  $r1 = ParcaTamamla $s1 7000
  $bek1 = (@(7..14 | ForEach-Object { Parca $G94 $_ 14 }) -join ',')
  if ((Kume $r1.parca_eklenen) -ne $bek1) { $hata.Add("T1 eklenen: beklenen '$bek1' gelen '$(Kume $r1.parca_eklenen)'") }
  if (@($r1.adlar).Count -ne 14) { $hata.Add("T1 ad sayısı 14 değil: $(@($r1.adlar).Count)") }
  foreach ($i in 7..14) { if ("$($r1.metin)" -notmatch [regex]::Escape("[$(Parca $G94 $i 14)] m94 parca $i metni")) { $hata.Add("T1 metinde parça $i bloğu yok"); break } }

  # T2: parçalı ad yok -> AYNI nesne, ambar çağrısı 0
  $script:CAGRI = 0
  $s2 = @{ metin = '[VUK (213 s.K.) m.229] y'; adlar = @('VUK (213 s.K.) m.229'); agHatasi = $null }
  $r2 = ParcaTamamla $s2 7000
  if (-not [object]::ReferenceEquals($r2, $s2)) { $hata.Add('T2 parçalı ad yokken sonuç yeni nesne (eşdeğerlik bozuk)') }
  if ($script:CAGRI -ne 0) { $hata.Add("T2 parçalı ad yokken ambar çağrısı $($script:CAGRI)") }
  $r2b = ParcaTamamla @{ metin = 'z'; adlar = @((Parca $G22 1 3), (Parca $G22 2 3), (Parca $G22 3 3)); agHatasi = $null } 7000
  if ($script:CAGRI -ne 0 -or $r2b.ContainsKey('parca_eklenen')) { $hata.Add('T2b tam maddede ambar çağrısı/ek alan var') }

  # T3: KAPI-MM - mülga listedeki eksik parça girmez, ötekiler girer
  $script:SAHTE = @{ (Parca $G22 1 3) = 'bir'; (Parca $G22 2 3) = 'iki'; (Parca $G22 3 3) = 'uc' }
  [void]$script:MULGA_MADDE.Add((Parca $G22 3 3))
  $r3 = ParcaTamamla @{ metin = "[$(Parca $G22 2 3)] iki"; adlar = @((Parca $G22 2 3)); agHatasi = $null } 7000
  if ((Kume $r3.parca_eklenen) -ne (Parca $G22 1 3)) { $hata.Add("T3 KAPI-MM: beklenen yalnız [1/3], gelen '$(Kume $r3.parca_eklenen)'") }
  $script:MULGA_MADDE.Clear()

  # T4: tavan (-EskiPaketTavani) - sığmayan blok girmez, sığan girer; kesik blok yok
  $script:EskiPaketTavani = $true
  $script:SAHTE = @{ (Parca $G22 1 3) = ('u' * 500); (Parca $G22 3 3) = 'kisa' }
  $s4 = @{ metin = ('x' * 6900); adlar = @((Parca $G22 2 3)); agHatasi = $null }
  $r4 = ParcaTamamla $s4 7000
  if ((Kume $r4.parca_eklenen) -ne (Parca $G22 3 3)) { $hata.Add("T4 tavan: beklenen yalnız [3/3], gelen '$(Kume $r4.parca_eklenen)'") }
  if ("$($r4.metin)".Length -gt 7000) { $hata.Add("T4 tavan aşıldı: $("$($r4.metin)".Length)") }
  if ("$($r4.metin)" -notmatch ([regex]::Escape("[$(Parca $G22 3 3)] kisa") + '$')) { $hata.Add('T4 sığan blok bütün değil') }
  $script:EskiPaketTavani = $false
  $r4b = ParcaTamamla $s4 7000
  if (@($r4b.parca_eklenen).Count -ne 2) { $hata.Add("T4b tavansız kipte iki parça da girmeli, gelen $(@($r4b.parca_eklenen).Count)") }

  # T5: ambarda olmayan kardeş sessizce atlanır
  $script:SAHTE = @{ (Parca $G22 1 3) = 'bir' }
  $r5 = ParcaTamamla @{ metin = 'a'; adlar = @((Parca $G22 2 3)); agHatasi = $null } 7000
  if ((Kume $r5.parca_eklenen) -ne (Parca $G22 1 3)) { $hata.Add("T5 eksik kardeş: gelen '$(Kume $r5.parca_eklenen)'") }

  # T6: Vergi güncellik kapısı (5422 dönemi metin) - AmbarCek ile aynı
  $script:SAHTE = @{ (Parca $G22 1 3) = 'eski 5422 sayılı Kanun'; (Parca $G22 3 3) = 'guncel' }
  $r6 = ParcaTamamla @{ metin = 'a'; adlar = @((Parca $G22 2 3)); agHatasi = $null } 7000
  if ((Kume $r6.parca_eklenen) -ne (Parca $G22 3 3)) { $hata.Add("T6 güncellik: gelen '$(Kume $r6.parca_eklenen)'") }

  # W1: hakem atıf bloğunda bağ
  if ($dosyaMetin -notmatch '\$atif=AmbarCek \$atifD 7000\s*\r?\n(?:\s*#[^\r\n]*\r?\n)*\s*\$atif=ParcaTamamla \$atif 7000') { $hata.Add('W1 hakem atıf bloğunda AmbarCek ardından ParcaTamamla çağrısı yok') }
  return , $hata
}

$TOPLAM = $VAKA_P.Count + 8 + 1
if (-not $Mutasyon) {
  $h = Kos $FONK $URETICI_METIN
  if ($h.Count) { foreach ($x in $h) { Write-Host "  KIRMIZI $x" -ForegroundColor Red }; Write-Host "PARÇA TAMAMLAMA ÖZ-SINAVI KIRMIZI ($($h.Count) bulgu)" -ForegroundColor Red; exit 1 }
  "PARÇA TAMAMLAMA ÖZ-SINAVI YEŞİL ($TOPLAM/$TOPLAM`: $($VAKA_P.Count) ad vakası + 8 tamamlama + 1 bağ)"; exit 0
}

function Boz([hashtable]$h, [string]$fa, [string]$eski, [string]$yeni) {
  $o = @{}; foreach ($k in $h.Keys) { $o[$k] = $h[$k] }
  if (-not $o[$fa].Contains($eski)) { throw "MUTASYON KURULAMADI: '$eski' $fa içinde yok" }
  $o[$fa] = $o[$fa].Replace($eski, $yeni); return $o
}
$MUT = @(
  , @('parça kalıbı bozuk ([k/m] yerine [k])', (Boz $FONK 'ParcaEksik' '\[(\d+)/(\d+)\]$' '\[(\d+)\]$'), $URETICI_METIN)
  , @('döngü bir eksik (-le -> -lt)', (Boz $FONK 'ParcaEksik' '$iP -le $topP' '$iP -lt $topP'), $URETICI_METIN)
  , @('var olan parça ayıklanmıyor', (Boz $FONK 'ParcaEksik' '-not $varP.Contains($adP) -and ' ''), $URETICI_METIN)
  , @('KAPI-MM süzgeci yok', (Boz $FONK 'ParcaTamamla' 'if($script:MULGA_MADDE -and $script:MULGA_MADDE.Contains($adT)){ $script:KAPI_MM_SAY++; continue }' ''), $URETICI_METIN)
  , @('tavan denetimi yok', (Boz $FONK 'ParcaTamamla' 'if(($metinT.Length + 5 + $blokT.Length) -gt $tavanT){ continue }' ''), $URETICI_METIN)
  , @('Vergi güncellik süzgeci yok', (Boz $FONK 'ParcaTamamla' "if(`$DersRegex -match 'Vergi' -and" "if(`$false -and"), $URETICI_METIN)
  , @('erken dönüş yok (eşdeğerlik)', (Boz $FONK 'ParcaTamamla' 'if(-not $eksikT.Count){ return $sonuc }' ''), $URETICI_METIN)
  , @('hakem bağı sökülmüş', $FONK, $URETICI_METIN.Replace('$atif=ParcaTamamla $atif 7000', '$atif=$atif'))
)
$kirmizi = 0
foreach ($m in $MUT) {
  $h = Kos $m[1] $m[2]
  if ($h.Count) { $kirmizi++; "  KIRMIZI (beklenen)  $($m[0])  <- $($h[0])" } else { Write-Host "  YEŞİL (KÖR SINAV!)  $($m[0])" -ForegroundColor Red }
}
if ($kirmizi -ne $MUT.Count) { Write-Host "PARÇA TAMAMLAMA MUTASYON: $kirmizi/$($MUT.Count) KIRMIZI — sınav kör" -ForegroundColor Red; exit 1 }
"PARÇA TAMAMLAMA MUTASYON: $kirmizi/$($MUT.Count) bozma -> KIRMIZI (sınav görüyor)"; exit 0
