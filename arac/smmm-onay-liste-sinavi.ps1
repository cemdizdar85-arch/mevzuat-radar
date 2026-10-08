#requires -Version 5.1
<#
================================================================================
  BİTİRME ONAY LİSTESİ — SINIFLAMA ÖZ-SINAVI  (08.10.2026)  bedel 0

  NİYE VAR (ölçüldü 08.10): üreticinin KÖR KAPISI kör ✗ + kaynaklı ✓ soruyu anlatım fazlarına
  ONAYDAN SONRA sokuyor (kalip-parti-uret.ps1 'ONAY-BEKLIYOR'); arac/smmm-onay.ps1 -Liste ise aynı
  soruyu "simülasyon hiç koşmadı" diye OTOMATİK ATIYORDU → soru Cem'e hiç ulaşmıyordu (kilit;
  o0710kor KOR-ONAY-BEKLER=3, üçü de atılan listesinde). Sınav iki yönü ölçer:
    · anlatımı eksik ama öteki şartları tutan soru BEKLEYEN'e düşmeli,
    · öteki gerekçelerle (kaynaklı ✗, hakem2, sim YANLIŞ, KC teşhis, AH KUSURLU …) atılan ATILAN kalmalı,
    · bayraksız SmmmYayinSarti (koşucu/kaydir-coz yolu) anlatımsız soruyu yine GEÇİRMEMELİ,
    · (08.10) kör HİÇBİRİ + kaynaklı ✓ soru da BEKLEYEN'e düşmeli; KK tek başına yayın açmamalı.
  ⛔ REPLİKA YASAK: gerçek arac/smmm-yayin-sarti.ps1 dot-source edilir; SmmmOnaySinifla gerçek
     arac/smmm-onay.ps1'den AST ile çıkarılır.
  -Mutasyon: kilit koşulları tek tek bozulur, her bozmada sınav KIRMIZI düşmeli.
  🚫 GÖRMEZ: ambardaki gerçek sorular (eşdeğerlik ayrı ölçülür) · üreticinin onaydan sonra anlatımı gerçekten koşması
     · mail/HTML biçimi · Node'lu KAPI-KALITE (sınav soruları eski tarihli; yeni tarihli vakada node yoksa kapı KÖR geçer).
================================================================================
#>
param([switch]$Sessiz, [switch]$Mutasyon)
$ErrorActionPreference = 'Stop'
$buDizin = $(if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$sartYol = Join-Path $buDizin 'smmm-yayin-sarti.ps1'
$onayYolu = Join-Path $buDizin 'smmm-onay.ps1'
. $sartYol   # gerçek yardımcılar (KH, MD, HAD, MA, OM, AH, kalite) yüklensin
# AST'den yeniden kurulan işlevde $PSScriptRoot boş → gerçek listeler burada (aynı okuyucularla) önceden yüklenir
$script:MD_LISTE = MdListeOku (Split-Path -Parent $buDizin); $script:HAD_HARITA = HadHaritaOku (Split-Path -Parent $buDizin)

function IslevMetni([string]$kaynakMetin, [string[]]$adlar) {
  $tk = $null; $hata = $null
  $ast = [System.Management.Automation.Language.Parser]::ParseInput($kaynakMetin, [ref]$tk, [ref]$hata)
  if ($hata -and $hata.Count) { throw "ayrıştırılamadı: $($hata[0].Message)" }
  $parca = foreach ($ad in $adlar) {
    $fn = @($ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $ad }, $true))
    if (-not $fn.Count) { throw "$ad BULUNAMADI" }
    $fn[0].Extent.Text
  }
  return ($parca -join "`n")
}
$sartMetin = [IO.File]::ReadAllText($sartYol, [Text.Encoding]::UTF8)
$onayMetin = [IO.File]::ReadAllText($onayYolu, [Text.Encoding]::UTF8)

# --- sentetik soru: anlatım öncesi bütün şartları tutar (eski tarih → KAPI-KALITE/AH kapsam dışı) ---
function Soru([string]$id, [switch]$Anlatimli, [string]$tarih = '2026-09-01') {
  $s = [pscustomobject]@{
    soru = "Sinav sorusu $id hangisidir"; dogru = 'B'; konu = 'sinav'; dayanak = 'Sinav dayanagi'
    siklar = [pscustomobject]@{ A = 'bir'; B = 'iki'; C = 'uc'; D = 'dort'; E = 'bes' }
    aciklama = [pscustomobject]@{ A = 'a yanlis'; B = 'b dogru'; C = 'c yanlis'; D = 'd yanlis'; E = 'e yanlis' }
    teshis = [pscustomobject]@{ A = 'ta'; C = 'tc'; D = 'td'; E = 'te' }
    hakem = [pscustomobject]@{ karar = 'EVET' }
    hakem2 = [pscustomobject]@{ karar = 'EVET'; tarih = $tarih }
    kor_cozum = [pscustomobject]@{ dogru_mu = $false; cevap = 'C'; tarih = $tarih }
  }
  if ($Anlatimli) {
    $s | Add-Member -NotePropertyName adimlar -NotePropertyValue @([pscustomobject]@{ formul = 'f'; anlatim = 'a' })
    $s | Add-Member -NotePropertyName sade -NotePropertyValue ([pscustomobject]@{ dogru = 'sade' })
    $s | Add-Member -NotePropertyName simulasyon_sonnet -NotePropertyValue ([pscustomobject]@{ dogru_mu = $true })
  }
  return $s
}
function KK($s, [bool]$dogruMu, [string]$cevap = '') {
  if (-not $cevap) { $cevap = $(if ($dogruMu) { 'B' } else { 'E' }) }
  $s | Add-Member -NotePropertyName kor_cozum_kaynakli -NotePropertyValue ([pscustomobject]@{ dogru_mu = $dogruMu; cevap = $cevap; kor_cevap = "$($s.kor_cozum.cevap)"; parmak_izi = (SmmmParmakIzi $s) }) -Force
  return $s
}

function SinavKos {
  $et = 'smmm-sinav-x'
  $sonuc = New-Object System.Collections.Generic.List[string]
  function V([string]$ad, [bool]$ok, [string]$ek) { if ($ok) { if (-not $Sessiz -and -not $Mutasyon) { Write-Host "  OK    $ad" } } else { $sonuc.Add("$ad ($ek)"); if (-not $Sessiz -and -not $Mutasyon) { Write-Host "  DÜŞTÜ $ad ($ek)" } } }
  $bos = @{}
  # 1) tam soru → BEKLEYEN, anlatım notu yok
  $r = SmmmOnaySinifla "$et/kp-01" (KK (Soru 'kp-01' -Anlatimli) $true) $bos
  V 'tam soru (sim ✓, adım, sade) → BEKLEYEN, anlatım notu yok' ($r.sinif -eq 'BEKLEYEN' -and -not $r.anlatim) "$($r.sinif) | $($r.neden)"
  # 2) KİLİT VAKASI: anlatımsız (adım/sade/sim yok) → BEKLEYEN + "onaydan sonra anlatım fazları koşacak"
  $r = SmmmOnaySinifla "$et/kp-02" (KK (Soru 'kp-02') $true) $bos
  V 'KİLİT: anlatımsız kör ✗ + KK ✓ → BEKLEYEN' ($r.sinif -eq 'BEKLEYEN' -and $r.neden -like '*onaydan sonra anlatım fazları koşacak*') "$($r.sinif) | $($r.neden)"
  # 3) adım var, sim hiç koşmamış → BEKLEYEN
  $s3 = KK (Soru 'kp-03') $true; $s3 | Add-Member -NotePropertyName adimlar -NotePropertyValue @([pscustomobject]@{ formul = 'f' }); $s3 | Add-Member -NotePropertyName sade -NotePropertyValue ([pscustomobject]@{ dogru = 'x' })
  $r = SmmmOnaySinifla "$et/kp-03" $s3 $bos
  V 'adım var, simülasyon hiç koşmamış → BEKLEYEN' ($r.sinif -eq 'BEKLEYEN' -and $r.anlatim -like '*simülasyon hiç koşmadı*') "$($r.sinif) | $($r.neden)"
  # --- ATILAN kalması gerekenler (anlatımsız sorularda bile) ---
  $r = SmmmOnaySinifla "$et/kp-04" (KK (Soru 'kp-04') $false) $bos
  V 'kaynaklı ✗ → ATILAN "kaynaklı çözüm de yanlış"' ($r.sinif -eq 'ATILAN' -and $r.neden -like 'kaynaklı çözüm de yanlış*') "$($r.sinif) | $($r.neden)"
  $r = SmmmOnaySinifla "$et/kp-05" (Soru 'kp-05') $bos
  V 'kaynaklı yok → ATILAN "koşmadı"' ($r.sinif -eq 'ATILAN' -and $r.neden -like 'kaynaklı ikinci çözüm koşmadı*') "$($r.sinif) | $($r.neden)"
  $s6 = KK (Soru 'kp-06') $true; $s6.hakem2.karar = 'HAYIR'
  $r = SmmmOnaySinifla "$et/kp-06" $s6 $bos
  V 'anlatımsız + hakem2 HAYIR → ATILAN (hakem2)' ($r.sinif -eq 'ATILAN' -and $r.neden -like '*hakem2 EVET değil*') "$($r.sinif) | $($r.neden)"
  $r = SmmmOnaySinifla "$et/kp-07" (KK (Soru 'kp-07') $true 'D') $bos
  V 'KK dogru_mu ama cevabı anahtar değil → ATILAN' ($r.sinif -eq 'ATILAN' -and $r.neden -like '*anahtarla tutmuyor*') "$($r.sinif) | $($r.neden)"
  $s8 = KK (Soru 'kp-08') $true; $s8 | Add-Member -NotePropertyName simulasyon_sonnet -NotePropertyValue ([pscustomobject]@{ dogru_mu = $false })
  $r = SmmmOnaySinifla "$et/kp-08" $s8 $bos
  V 'simülasyon YANLIŞ → ATILAN' ($r.sinif -eq 'ATILAN' -and $r.neden -like '*simülasyon yanlış*') "$($r.sinif) | $($r.neden)"
  $s9 = KK (Soru 'kp-09') $true; $s9.hakem | Add-Member -NotePropertyName konu_uyum -NotePropertyValue 'KONU-DISI'
  $r = SmmmOnaySinifla "$et/kp-09" $s9 $bos
  V 'hakem KONU-DISI → ATILAN' ($r.sinif -eq 'ATILAN' -and $r.neden -like '*KONU-DISI*') "$($r.sinif) | $($r.neden)"
  $s10 = KK (Soru 'kp-10') $true; $s10.teshis.PSObject.Properties.Remove('C')
  $r = SmmmOnaySinifla "$et/kp-10" $s10 $bos
  V 'anlatımsız + teşhis C eksik → ATILAN (KC teşhis)' ($r.sinif -eq 'ATILAN' -and $r.neden -like '*teşhis C*') "$($r.sinif) | $($r.neden)"
  $s11 = KK (Soru 'kp-11' -tarih '2026-10-07') $true; $s11 | Add-Member -NotePropertyName aciklama_hakem -NotePropertyValue ([pscustomobject]@{ karar = 'KUSURLU' })
  $r = SmmmOnaySinifla "$et/kp-11" $s11 $bos
  V 'yeni soru + açıklama hakemi KUSURLU → ATILAN' ($r.sinif -eq 'ATILAN' -and $r.neden -like '*AÇIKLAMA HAKEMİ*') "$($r.sinif) | $($r.neden)"
  # yeni tarihli, açıklama hakemi HİÇ koşmamış, anlatımsız → BEKLEYEN (hakem anlatımdan sonra koşar)
  $r = SmmmOnaySinifla "$et/kp-12" (KK (Soru 'kp-12' -tarih '2026-10-07') $true) $bos
  V 'yeni soru, AH kaydı yok, anlatımsız → BEKLEYEN' ($r.sinif -eq 'BEKLEYEN') "$($r.sinif) | $($r.neden)"
  # --- karar verilmiş sorular ---
  $s13 = KK (Soru 'kp-13') $true; $h13 = @{ "$et/kp-13" = [pscustomobject]@{ karar = 'ONAY'; parmak_izi = (SmmmParmakIzi $s13) } }
  $r = SmmmOnaySinifla "$et/kp-13" $s13 $h13
  V 'ONAY verilmiş anlatımsız → KARARLI ONAY + anlatım notu' ($r.sinif -eq 'KARARLI' -and $r.neden -eq 'ONAY' -and $r.anlatim) "$($r.sinif) | $($r.neden)"
  $s14 = KK (Soru 'kp-14') $true; $h14 = @{ "$et/kp-14" = [pscustomobject]@{ karar = 'RED'; parmak_izi = (SmmmParmakIzi $s14) } }
  $r = SmmmOnaySinifla "$et/kp-14" $s14 $h14
  V 'RED verilmiş → KARARLI RED (listeye girmez)' ($r.sinif -eq 'KARARLI' -and $r.neden -eq 'RED') "$($r.sinif) | $($r.neden)"
  $s15 = KK (Soru 'kp-15') $true; $h15 = @{ "$et/kp-15" = [pscustomobject]@{ karar = 'ONAY'; parmak_izi = 'eski' } }
  $r = SmmmOnaySinifla "$et/kp-15" $s15 $h15
  V 'onaydan sonra soru değişmiş → yeniden BEKLEYEN' ($r.sinif -eq 'BEKLEYEN') "$($r.sinif) | $($r.neden)"
  # --- bayraksız yayın şartı (koşucu / kaydir-coz yolu) GEVŞEMEMELİ ---
  $s16 = KK (Soru 'kp-16') $true; $o16 = @{ "$et/kp-16" = [pscustomobject]@{ karar = 'ONAY'; parmak_izi = (SmmmParmakIzi $s16) } }
  $y = SmmmYayinSarti "$et/kp-16" $s16 $o16
  V 'bayraksız yayın şartı: onaylı ama anlatımsız → GEÇMEZ' (-not $y.gecer) "$($y.gecer) | $($y.neden)"
  $s17 = KK (Soru 'kp-17' -Anlatimli) $true; $o17 = @{ "$et/kp-17" = [pscustomobject]@{ karar = 'ONAY'; parmak_izi = (SmmmParmakIzi $s17) } }
  $y = SmmmYayinSarti "$et/kp-17" $s17 $o17
  V 'bayraksız yayın şartı: onaylı + anlatımlı → GEÇER' ($y.gecer) "$($y.gecer) | $($y.neden)"
  # --- 08.10 kör HİÇBİRİ (üretici artık kaynaklı ikinci çözümü açıyor; liste ve yayın şartı tutarlı işlemeli) ---
  $s18 = Soru 'kp-18'; $s18.kor_cozum.cevap = 'HİÇBİRİ'; $s18 = KK $s18 $true
  $r = SmmmOnaySinifla "$et/kp-18" $s18 $bos
  V 'kör HİÇBİRİ + KK ✓ (anlatımsız) → BEKLEYEN' ($r.sinif -eq 'BEKLEYEN') "$($r.sinif) | $($r.neden)"
  $s19 = Soru 'kp-19'; $s19.kor_cozum.cevap = 'HİÇBİRİ'
  $r = SmmmOnaySinifla "$et/kp-19" $s19 $bos
  V 'kör HİÇBİRİ, KK henüz yok → ATILAN, gerekçe "kör HİÇBİRİ" (tuzak şıkkı değil DENMEZ)' ($r.sinif -eq 'ATILAN' -and $r.neden -like 'kör HİÇBİRİ*') "$($r.sinif) | $($r.neden)"
  $s20 = Soru 'kp-20' -Anlatimli; $s20.kor_cozum.cevap = 'HİÇBİRİ'; $s20 = KK $s20 $true; $o20 = @{ "$et/kp-20" = [pscustomobject]@{ karar = 'ONAY'; parmak_izi = (SmmmParmakIzi $s20) } }
  $y = SmmmYayinSarti "$et/kp-20" $s20 $o20
  V 'kör HİÇBİRİ + KK ✓ + ONAY + anlatımlı → yayın GEÇER' ($y.gecer) "$($y.gecer) | $($y.neden)"
  $s21 = Soru 'kp-21' -Anlatimli; $s21.kor_cozum.cevap = 'HİÇBİRİ'; $s21 = KK $s21 $true
  $y = SmmmYayinSarti "$et/kp-21" $s21 $bos
  V 'kör HİÇBİRİ + KK ✓, ONAY YOK → yayın GEÇMEZ (KK tek başına açmaz)' (-not $y.gecer -and $y.neden -like '*Cem onayı bekliyor*') "$($y.gecer) | $($y.neden)"
  $s22 = Soru 'kp-22' -Anlatimli; $s22.kor_cozum.cevap = 'HİÇBİRİ'; $s22 = KK $s22 $true; $s22.kor_cozum.cevap = 'C'; $o22 = @{ "$et/kp-22" = [pscustomobject]@{ karar = 'ONAY'; parmak_izi = (SmmmParmakIzi $s22) } }
  $y = SmmmYayinSarti "$et/kp-22" $s22 $o22
  V 'KK kör HİÇBİRİ kararına ait, kör sonra C → yayın GEÇMEZ (bayat KK)' (-not $y.gecer -and $y.neden -like '*eski kör çözüme ait*') "$($y.gecer) | $($y.neden)"
  return , $sonuc
}

function Yukle([string]$sMetin, [string]$oMetin) {
  return (IslevMetni $sMetin @('SmmmKaliteNeden', 'SmmmKorIstisna', 'SmmmYayinSarti')) + "`n" + (IslevMetni $oMetin @('SmmmOnaySinifla'))
}

if (-not $Mutasyon) {
  . ([scriptblock]::Create((Yukle $sartMetin $onayMetin)))
  $kalan = SinavKos
  ''
  "ONAY LİSTESİ SINIFLAMA ÖZ-SINAVI: $(22 - $kalan.Count)/22 geçti"
  if ($kalan.Count) { foreach ($k in $kalan) { Write-Host "  KIRMIZI: $k" -ForegroundColor Red }; exit 1 }
  Write-Host 'YEŞİL' -ForegroundColor Green
  exit 0
}

# --- MUTASYON: her bozma en az bir vakayı KIRMIZI düşürmeli ---
$mutasyonlar = @(
  @{ ad = 'M1 liste: anlatım öncesi yedeği kapalı'; d = 'o'; eski = '$once = SmmmYayinSarti $anh $v $sahteOnay -AnlatimOncesi'; yeni = '$once = SmmmYayinSarti $anh $v $sahteOnay' }
  @{ ad = 'M2 şart: simülasyon-hiç-koşmadı bekletmesi kapalı'; d = 's'; eski = 'if (-not $AnlatimOncesi -and -not (SmmmSimDogru $v))'; yeni = 'if (-not (SmmmSimDogru $v))' }
  @{ ad = 'M3 şart: KC adım/sade bekletmesi kapalı'; d = 's'; eski = "-not (`$AnlatimOncesi -and `$_ -in 'adımlar', 'sade anlatım')"; yeni = '$true' }
  @{ ad = 'M4 şart: bayrak hakem2''yi de atlıyor (gevşeme)'; d = 's'; eski = "if (-not (`$v.PSObject.Properties['hakem2']"; yeni = "if (-not `$AnlatimOncesi -and -not (`$v.PSObject.Properties['hakem2']" }
  @{ ad = 'M5 şart: bayrak AH KUSURLU''yu da atlıyor (gevşeme)'; d = 's'; eski = '$ahBeklet = ($AnlatimOncesi -and -not $ahKaydiVar)'; yeni = '$ahBeklet = [bool]$AnlatimOncesi' }
  @{ ad = 'M6 şart: bayraksız yol da simülasyonu atlıyor (koşucu gevşer)'; d = 's'; eski = 'if (-not $AnlatimOncesi -and -not (SmmmSimDogru $v))'; yeni = 'if ($false)' }
  @{ ad = 'M7 liste: tam şart yerine hep anlatım öncesi (bekleyen notu kaybolur)'; d = 'o'; eski = '$digeri = SmmmYayinSarti $anh $v $sahteOnay'; yeni = '$digeri = SmmmYayinSarti $anh $v $sahteOnay -AnlatimOncesi' }
  @{ ad = 'M8 liste: kör HİÇBİRİ gerekçesi kapalı (08.10)'; d = 'o'; eski = 'elseif ($korHicbiri)'; yeni = 'elseif ($false)' }
  @{ ad = 'M9 şart: kör istisnası kör cevabını eşlemiyor (bayat KK açar)'; d = 's'; eski = 'if ("$($kaynakli.kor_cevap)" -ne "$($soruNesne.kor_cozum.cevap)")'; yeni = 'if ($false)' }
)
$kirmizi = 0
foreach ($m in $mutasyonlar) {
  $sM = $sartMetin; $oM = $onayMetin
  if ($m.d -eq 's') { if (-not $sM.Contains($m.eski)) { throw "mutasyon hedefi yok: $($m.ad)" }; $sM = $sM.Replace($m.eski, $m.yeni) }
  else { if (-not $oM.Contains($m.eski)) { throw "mutasyon hedefi yok: $($m.ad)" }; $oM = $oM.Replace($m.eski, $m.yeni) }
  . ([scriptblock]::Create((Yukle $sM $oM)))
  $k = SinavKos
  if ($k.Count) { $kirmizi++; "  KIRMIZI (beklenen) $($m.ad) → $($k.Count) vaka düştü: $($k[0])" } else { Write-Host "  YEŞİL KALDI (SINAV EKSİK) $($m.ad)" -ForegroundColor Red }
}
. ([scriptblock]::Create((Yukle $sartMetin $onayMetin)))
"MUTASYON: $kirmizi/$($mutasyonlar.Count) bozma KIRMIZI düşürdü"
if ($kirmizi -ne $mutasyonlar.Count) { exit 1 }
exit 0
