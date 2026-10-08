#requires -Version 5.1
<#
================================================================================
  KOŞUCU AYNI ETİKETLİ SATIR — ÖZ-SINAV + MUTASYON + EŞDEĞERLİK  (08.10.2026)  bedel 0

  NİYE VAR (ölçüldü 08.10, gm12 onarımı): motor/kalip-kosucu.ps1 aynı etiketli satırların yalnız ilkini
  koşturuyor, ötekiler "başka hatta basılıyor" diye 0 koduyla çıkıyordu; eşzamanlı iki satır aynı önbellek
  dosyasına yazıp kp-04/kp-05 sonucunu sildi. Kapı: arac/kosucu-satir-birlestir.ps1.
  Sınav iki yönü ölçer: birleşmesi gereken birleşir · birleşmemesi gereken (bayrak farkı, pilotId'siz,
  tek satır) AYNEN kalır / sırayla koşar.
  ⛔ REPLİKA YASAK: gerçek arac/kosucu-satir-birlestir.ps1 metni yüklenir; koşucu ve üretici bağları
     gerçek dosyalardan okunur.
  -Mutasyon   : kilit koşulları tek tek bozulur, her bozmada sınav KIRMIZI düşmeli.
  -Esdegerlik : depodaki bütün veri/sinav/plan-*.json planlarında eski (ham satır) / yeni çözümleme farkı.
  🚫 GÖRMEZ: koşucunun gerçek süreç açması (Start-Process; bulutta ölçülür) · iki ayrı bulut işinin aynı
     etiketi açması (bulut-uretim.yml MEVZUAT_ATLA_ETIKET) · üreticinin birleşik pilotId ile gerçek koşusu.
================================================================================
#>
param([switch]$Sessiz, [switch]$Mutasyon, [switch]$Esdegerlik)
$ErrorActionPreference = 'Stop'
$buDizin = $(if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$depoKok = Split-Path -Parent $buDizin
$birlestirYol = Join-Path $buDizin 'kosucu-satir-birlestir.ps1'
$birlestirMetin = [IO.File]::ReadAllText($birlestirYol, [Text.Encoding]::UTF8)
$kosucuMetin = [IO.File]::ReadAllText((Join-Path (Join-Path $depoKok 'motor') 'kalip-kosucu.ps1'), [Text.Encoding]::UTF8)
$ureticiMetin = [IO.File]::ReadAllText((Join-Path (Join-Path $depoKok 'motor') 'kalip-parti-uret.ps1'), [Text.Encoding]::UTF8)

function MetinYukle([string]$metin) {
  $tk = $null; $hata = $null
  [void][System.Management.Automation.Language.Parser]::ParseInput($metin, [ref]$tk, [ref]$hata)
  if ($hata -and $hata.Count) { throw "ayrıştırılamadı: $($hata[0].Message)" }
  return [scriptblock]::Create($metin)
}
function Satir([string]$json) { return (ConvertFrom-Json -InputObject $json) }
function Kanonik($satirDizisi) { return (@($satirDizisi | ForEach-Object { ConvertTo-Json -InputObject $_ -Compress -Depth 10 }) -join "`n") }

function SinavKos {
  $sonuc = New-Object System.Collections.Generic.List[string]
  function V([string]$ad, [bool]$ok, [string]$ek) { if ($ok) { if (-not $Sessiz -and -not $Mutasyon) { Write-Host "  OK    $ad" } } else { $sonuc.Add("$ad ($ek)"); if (-not $Sessiz -and -not $Mutasyon) { Write-Host "  DÜŞTÜ $ad ($ek)" } } }

  # --- DOKUNMAMASI gerekenler (eşdeğerlik) ---
  $a = Satir '{"etiket":"smmm-x","ders":"Vergi","adet":3}'; $b = Satir '{"etiket":"smmm-y","ders":"Vergi","adet":3,"pilotId":"kp-01"}'
  $r = KosucuSatirBirlestir @($a, $b)
  V '1 farklı etiketler: satır sayısı ve NESNE aynı, günlük boş' ($r.satirlar.Count -eq 2 -and [object]::ReferenceEquals($r.satirlar[0], $a) -and [object]::ReferenceEquals($r.satirlar[1], $b) -and @($r.gunluk).Count -eq 0) "$($r.satirlar.Count) | $(@($r.gunluk) -join ';')"
  $t = Satir '{"etiket":"smmm-t","pilotId":"kp-01, kp-01","korYenile":true}'
  $r = KosucuSatirBirlestir @($t)
  V '2 tek satır (pilotId yazımı tuhaf olsa da) DOKUNULMAZ' ($r.satirlar.Count -eq 1 -and [object]::ReferenceEquals($r.satirlar[0], $t) -and "$($r.satirlar[0].pilotId)" -eq 'kp-01, kp-01') "$($r.satirlar[0].pilotId)"
  $r = KosucuSatirBirlestir @()
  V '3 boş plan → boş' ($r.satirlar.Count -eq 0) "$($r.satirlar.Count)"

  # --- BİRLEŞMESİ gerekenler ---
  $g1 = Satir '{"etiket":"smmm-gm12","ders":"Vergi","adet":1,"korYenile":true,"pilotId":"kp-01"}'
  $g2 = Satir '{"etiket":"smmm-gm12","ders":"Vergi","adet":1,"korYenile":true,"pilotId":"kp-02"}'
  $g3 = Satir '{"etiket":"smmm-gm12","ders":"Vergi","adet":1,"korYenile":true,"pilotId":"kp-01,kp-04"}'
  $r = KosucuSatirBirlestir @($g1, $g2, $g3)
  V '4 aynı etiket + aynı bayrak → TEK satır, pilotId birleşik ve tekrarsız' ($r.satirlar.Count -eq 1 -and "$($r.satirlar[0].pilotId)" -eq 'kp-01,kp-02,kp-04' -and [bool]$r.satirlar[0].korYenile) "$($r.satirlar.Count) | $($r.satirlar[0].pilotId)"
  V '5 özgün plan nesnesi DEĞİŞMEDİ (sığ kopya)' ("$($g1.pilotId)" -eq 'kp-01') "$($g1.pilotId)"
  V '6 birleşme günlüğe yazıldı' (@($r.gunluk | Where-Object { $_ -like 'KOSUCU SATIR BIRLESTI: smmm-gm12*3 satır*' }).Count -eq 1) "$(@($r.gunluk) -join ';')"
  # alan sırası farklı yazılmış ama değerleri aynı → yine birleşir
  $h1 = Satir '{"etiket":"smmm-h","korYenile":true,"ders":"FM","pilotId":"kp-07"}'; $h2 = Satir '{"ders":"FM","pilotId":"kp-09","etiket":"smmm-h","korYenile":true}'
  $r = KosucuSatirBirlestir @($h1, $h2)
  V '7 alan sırası farklı, değerler aynı → birleşir' ($r.satirlar.Count -eq 1 -and "$($r.satirlar[0].pilotId)" -eq 'kp-07,kp-09') "$($r.satirlar.Count)"

  # --- BİRLEŞMEMESİ gerekenler (sıralı) ---
  $k1 = Satir '{"etiket":"smmm-k","ders":"FM","pilotId":"kp-01","korYenile":true}'; $k2 = Satir '{"etiket":"smmm-k","ders":"FM","pilotId":"kp-02","adimYenile":true}'
  $r = KosucuSatirBirlestir @($k1, $k2)
  V '8 bayraklar farklı (korYenile / adimYenile) → 2 satır, SIRALI günlüğü' ($r.satirlar.Count -eq 2 -and @($r.gunluk | Where-Object { $_ -like 'KOSUCU SATIR SIRALI: smmm-k*' }).Count -eq 1) "$($r.satirlar.Count) | $(@($r.gunluk) -join ';')"
  $p1 = Satir '{"etiket":"smmm-p","ders":"FM"}'; $p2 = Satir '{"etiket":"smmm-p","ders":"FM","pilotId":"kp-02"}'
  $r = KosucuSatirBirlestir @($p1, $p2)
  V '9 pilotId''siz (bütün parti) satır pilotId''li satırla birleşmez' ($r.satirlar.Count -eq 2 -and [object]::ReferenceEquals($r.satirlar[0], $p1)) "$($r.satirlar.Count)"
  $q1 = Satir '{"etiket":"smmm-q","pilotId":"kp-01","hakemYenileId":"kp-01"}'; $q2 = Satir '{"etiket":"smmm-q","pilotId":"kp-02","hakemYenileId":"kp-02"}'
  $r = KosucuSatirBirlestir @($q1, $q2)
  V '10 hakemYenileId farklı → birleşmez' ($r.satirlar.Count -eq 2) "$($r.satirlar.Count)"
  $d1 = Satir '{"etiket":"smmm-d","pilotId":"kp-01","korYenile":true}'; $d2 = Satir '{"etiket":"smmm-d","pilotId":"kp-02","adimYenile":true}'
  $d3 = Satir '{"etiket":"smmm-d","pilotId":"kp-03","korYenile":true}'; $d4 = Satir '{"etiket":"smmm-d","pilotId":"kp-04","adimYenile":true}'
  $r = KosucuSatirBirlestir @($d1, $d2, $d3, $d4)
  V '11 iki bayrak grubu → iki birleşik satır (kp-01,kp-03 · kp-02,kp-04)' ($r.satirlar.Count -eq 2 -and "$($r.satirlar[0].pilotId)" -eq 'kp-01,kp-03' -and "$($r.satirlar[1].pilotId)" -eq 'kp-02,kp-04') "$(@($r.satirlar | ForEach-Object { $_.pilotId }) -join ' | ')"

  # --- SIRALI KOŞU SEÇİCİSİ ---
  $sA = Satir '{"etiket":"A"}'; $sA2 = Satir '{"etiket":"A","pilotId":"kp-02"}'; $sB = Satir '{"etiket":"B"}'
  $kuyrukL = New-Object System.Collections.Generic.List[object]; $kuyrukL.Add($sA2); $kuyrukL.Add($sB)
  $ucanL = New-Object System.Collections.Generic.List[object]; $ucanL.Add([pscustomobject]@{ s = $sA })
  V '12 uçan A varken kuyruktaki A atlanır, B seçilir' ((KosucuSatirSec $kuyrukL $ucanL) -eq 1) "$(KosucuSatirSec $kuyrukL $ucanL)"
  $kuyrukL2 = New-Object System.Collections.Generic.List[object]; $kuyrukL2.Add($sA2)
  V '13 kalan tek satır uçan etiketin → -1 (bekle)' ((KosucuSatirSec $kuyrukL2 $ucanL) -eq -1) "$(KosucuSatirSec $kuyrukL2 $ucanL)"
  $bosUcan = New-Object System.Collections.Generic.List[object]
  V '14 uçan yoksa ilk satır (eski FIFO davranışı)' ((KosucuSatirSec $kuyrukL $bosUcan) -eq 0) "$(KosucuSatirSec $kuyrukL $bosUcan)"
  $tek = @(KosucuTekilEtiket @($sA, $sA2, $sB))
  V '15 seçim/karne için etiket başına tek satır' ($tek.Count -eq 2 -and [object]::ReferenceEquals($tek[0], $sA)) "$($tek.Count)"

  # etiketsiz satırlar (plan-siklik, plan-smmm-ilgi-* gibi koşucu planı olmayan dosyalar) gruplanmaz, sıralanmaz, tekilleşmez
  $e1 = Satir '{"ders":"FM","konuDosya":"a.json"}'; $e2 = Satir '{"ders":"Vergi","konuDosya":"b.json"}'
  $r = KosucuSatirBirlestir @($e1, $e2)
  $kuyrukE = New-Object System.Collections.Generic.List[object]; $kuyrukE.Add($e2); $ucanE = New-Object System.Collections.Generic.List[object]; $ucanE.Add([pscustomobject]@{ s = $e1 })
  V '20 etiketsiz satırlar: günlük boş, seçici bekletmez, tekil süzgeç ikisini de tutar' (@($r.gunluk).Count -eq 0 -and (KosucuSatirSec $kuyrukE $ucanE) -eq 0 -and @(KosucuTekilEtiket @($e1, $e2)).Count -eq 2) "günlük $(@($r.gunluk).Count)"

  # --- BAĞLAR (gerçek dosyalar) ---
  V '16 koşucu birleştiriciyi çağırıyor' ($kosucuMetin -match '\$satirCozum=KosucuSatirBirlestir \$satirlar' -and $kosucuMetin -match '\$satirlar=@\(\$satirCozum\.satirlar\)') 'kalip-kosucu.ps1'
  V '17 koşucu kuyruktan KosucuSatirSec ile alıyor (Dequeue yok)' ($kosucuMetin -match 'KosucuSatirSec \$kuyruk \$ucan' -and $kosucuMetin -notmatch '\.Dequeue\(\)') 'kalip-kosucu.ps1'
  V '18 seçim ve açıklama hakemi tekil etiketle' ($kosucuMetin -match 'foreach\(\$s in \$tekilSatirlar\)' -and $kosucuMetin -match 'AciklamaHakemUretim \$Kok \$tekilSatirlar') 'kalip-kosucu.ps1'
  V '21 koşucu plan alanı onarimTuru''yu üreticiye geçirir (kesik eski cevap hasadını kırmak için)' ($kosucuMetin -match '\$arg\+=@\(''-OnarimTuru'',' -and $ureticiMetin -match 'if\(\$OnarimTuru\)\{ \$script:PARMAK_TUZU') 'kalip-kosucu.ps1'
  $pilotSatir = @(($ureticiMetin -split "`n") | Where-Object { $_ -match '\$PilotId -and \(' })
  $virgulsuz = @($pilotSatir | Where-Object { $_ -notmatch "-split ','" })
  V "19 üretici: `$PilotId süzgeçlerinin hepsi virgüllü listeyi böler ($($pilotSatir.Count) yer)" ($pilotSatir.Count -ge 10 -and $virgulsuz.Count -eq 0 -and $ureticiMetin -notmatch '\$PilotId\s+-eq\s+\$id') "virgülsüz $($virgulsuz.Count)"
  return , $sonuc
}

if ($Esdegerlik) {
  . (MetinYukle $birlestirMetin)
  $planlar = @(Get-ChildItem (Join-Path (Join-Path $depoKok 'veri') 'sinav') -Filter 'plan-*.json' -File | Sort-Object Name)
  $farkli = New-Object System.Collections.Generic.List[string]; $smmmSay = 0; $okunamayan = 0; $satirTop = 0
  foreach ($pf in $planlar) {
    $ham = $null
    try { $ham = @(ConvertFrom-Json -InputObject (Get-Content $pf.FullName -Raw -Encoding UTF8)) } catch { $okunamayan++; continue }
    if ($ham.Count -eq 1 -and $ham[0].PSObject.Properties['SyncRoot']) { $ham = @($ham[0].SyncRoot) }   # koşucunun okuma satırı ile aynı
    if ($pf.Name -like 'plan-smmm-*') { $smmmSay++ }
    $satirTop += $ham.Count
    $yeni = KosucuSatirBirlestir $ham
    $ayni = ((Kanonik $ham) -ceq (Kanonik $yeni.satirlar))
    $tekrar = @($ham | Where-Object { "$($_.etiket)" } | Group-Object { "$($_.etiket)" } | Where-Object { $_.Count -gt 1 }).Count
    if (-not $ayni -or $tekrar) { $farkli.Add("$($pf.Name): satır $($ham.Count) → $($yeni.satirlar.Count) · tekrar eden etiket $tekrar · $(if($ayni){'satırlar AYNI (sıralı koşacak)'}else{'satırlar DEĞİŞTİ'}) · $(@($yeni.gunluk) -join ' | ')") }
  }
  "EŞDEĞERLİK: plan dosyası $($planlar.Count) (plan-smmm-* $smmmSay) · satır $satirTop · okunamayan $okunamayan · çözümlemesi değişen/sıralı $($farkli.Count)"
  foreach ($f in $farkli) { "  $f" }
  exit 0
}

if (-not $Mutasyon) {
  . (MetinYukle $birlestirMetin)
  $kalan = SinavKos
  ''
  "KOŞUCU SATIR ÖZ-SINAVI: $(21 - $kalan.Count)/21 geçti"
  if ($kalan.Count) { foreach ($k in $kalan) { Write-Host "  KIRMIZI: $k" -ForegroundColor Red }; exit 1 }
  Write-Host 'YEŞİL' -ForegroundColor Green
  exit 0
}

$mutasyonlar = @(
  @{ ad = 'M1 anahtar pilotId''yi de içeriyor (hiç birleşmez)'; d = 'b'; eski = "if (`$alan.Name -ceq 'pilotId') { continue }"; yeni = '' }
  @{ ad = 'M2 anahtar bayrakları yok sayıyor (farklı bayrak birleşir)'; d = 'b'; eski = 'return (ConvertTo-Json -InputObject $alanlar -Compress -Depth 10)'; yeni = "return 'x'" }
  @{ ad = 'M3 pilotId''siz satır da birleşir'; d = 'b'; eski = 'if ($satirPilot -and $satirEtiket) {'; yeni = 'if ($satirEtiket) {' }
  @{ ad = 'M4 özgün nesneye yazılıyor (kopya yok)'; d = 'b'; eski = '$kopya = $cikanSatir[$yer].PSObject.Copy()'; yeni = '$kopya = $cikanSatir[$yer]' }
  @{ ad = 'M5 seçici uçan etiketi görmüyor (eşzamanlı koşu)'; d = 'b'; eski = 'if (-not $ucanEtiket.ContainsKey("$($kuyrukListe[$sira].etiket)")) { return $sira }'; yeni = 'return $sira' }
  @{ ad = 'M6 tekil etiket süzgeci kapalı (seçim iki kez)'; d = 'b'; eski = 'if ($e -and $gorulenEtiket.ContainsKey($e)) { continue }; '; yeni = '' }
  @{ ad = 'M7 kimlik tekrarı ayıklanmıyor'; d = 'b'; eski = 'foreach ($kimlik in $yeniKimlik) { if (-not $grupKimlik[$grupAnahtar].Contains($kimlik)) { $grupKimlik[$grupAnahtar].Add($kimlik) } }
        $grupSay'; yeni = 'foreach ($kimlik in $yeniKimlik) { $grupKimlik[$grupAnahtar].Add($kimlik) }
        $grupSay' }
  @{ ad = 'M10 etiketsiz satır SIRALI sayılıyor'; d = 'b'; eski = 'if (-not $e) { continue }; '; yeni = '' }
  @{ ad = 'M11 seçici etiketsiz uçanı da bekletiyor'; d = 'b'; eski = 'if ("$($ucanKayit.s.etiket)") {'; yeni = 'if ($true) {' }
  @{ ad = 'M12 koşucu onarimTuru''yu geçirmiyor'; d = 'k'; eski = "$arg+=@('-OnarimTuru',"; yeni = "$null=@('-OnarimTuru'," }
  @{ ad = 'M8 koşucu seçimi ham satırla (tekil değil)'; d = 'k'; eski = 'foreach($s in $tekilSatirlar)'; yeni = 'foreach($s in $satirlar)' }
  @{ ad = 'M9 üreticide bir PilotId süzgeci virgülsüz'; d = 'u'; eski = "if(`$PilotId -and ((`$PilotId -split ',') -notcontains `$id)){ continue }   # pilot: yalniz secili sorular"; yeni = "if(`$PilotId -and (`$PilotId -ne `$id)){ continue }   # pilot: yalniz secili sorular" }
)
$kirmizi = 0
$asilK = $kosucuMetin; $asilU = $ureticiMetin
foreach ($m in $mutasyonlar) {
  $bM = $birlestirMetin; $script:kosucuMetin = $asilK; $script:ureticiMetin = $asilU
  $hedefMetin = $(switch ($m.d) { 'b' { $bM } 'k' { $asilK } 'u' { $asilU } })
  $eskiN = ($m.eski -replace "`r`n", "`n"); $hedefN = ($hedefMetin -replace "`r`n", "`n")
  if (-not $hedefN.Contains($eskiN)) { throw "mutasyon hedefi yok: $($m.ad)" }
  $bozuk = $hedefN.Replace($eskiN, $m.yeni)
  switch ($m.d) { 'b' { $bM = $bozuk } 'k' { $script:kosucuMetin = $bozuk } 'u' { $script:ureticiMetin = $bozuk } }
  . (MetinYukle $bM)
  try { $k = SinavKos } catch { $k = @("istisna: $($_.Exception.Message)") }   # bozuk kod patlarsa da sınav KIRMIZI sayılır
  if ($k.Count) { $kirmizi++; "  KIRMIZI (beklenen) $($m.ad) → $($k.Count) vaka düştü: $($k[0])" } else { Write-Host "  YEŞİL KALDI (SINAV EKSİK) $($m.ad)" -ForegroundColor Red }
}
"MUTASYON: $kirmizi/$($mutasyonlar.Count) bozma KIRMIZI düşürdü"
if ($kirmizi -ne $mutasyonlar.Count) { exit 1 }
exit 0
