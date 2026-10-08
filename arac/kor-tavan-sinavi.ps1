#requires -Version 5.1
<#
================================================================================
  KÖR ÇÖZÜM TAVANI + KÖR "HİÇBİRİ" KAYNAKLI YOLU — ÖZ-SINAV + MUTASYON  (08.10.2026)  bedel 0

  NİYE VAR (ölçüldü 08.10, gm12):
   (a) kör + kaynaklı ikinci çözüm çağrılarının çıktı tavanı 2.500 jetondu (düşünme dahil) → cevaplar kesik,
       "KÖR ÇÖZÜM BOZUK". Tavan 8.000 oldu (motor/kalip-parti-uret.ps1 $KOR_MAXTOK). Toplu hasat parmak izi
       max_tokens'ı TAŞIMAMALI ki eski etiketlerin ödenmiş sonuçları bedava hasat edilsin.
   (b) kör "HİÇBİRİ" dediğinde kaynaklı ikinci çözüm (KK) açılmıyordu (A–E harf şartı) → soru KAYNAKLI-YOK'ta
       kalıp Cem onayına hiç ulaşmıyordu. Artık açılır; KK tek başına yayın AÇMAZ (Cem ONAY + parmak izi).
  ⛔ REPLİKA YASAK: KorKaynakliGerekli / SmmmKorKapisi gerçek üreticiden AST ile çıkarılır; SmmmParmakIzi /
     SmmmKorIstisna gerçek arac/smmm-yayin-sarti.ps1'den; parmak izi gerçek motor/api-hedef.ps1'den.
  -Mutasyon: kilit koşulları tek tek bozulur, her bozmada sınav KIRMIZI düşmeli.
  🚫 GÖRMEZ: 8.000'in gerçek çağrıda yetip yetmediği (ücretli koşu ister; dur=max_tokens sayımı yok) ·
     KK'nın gerçek model cevabı · bulut toplu partisinin gerçek eşleşmesi (yalnız parmak izi girdisi ölçülür).
================================================================================
#>
param([switch]$Sessiz, [switch]$Mutasyon)
$ErrorActionPreference = 'Stop'
$buDizin = $(if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path })
$depoKok = Split-Path -Parent $buDizin
. (Join-Path $buDizin 'smmm-yayin-sarti.ps1')   # SmmmParmakIzi · SmmmKorIstisna (gerçek)
$ureticiAsil = [IO.File]::ReadAllText((Join-Path (Join-Path $depoKok 'motor') 'kalip-parti-uret.ps1'), [Text.Encoding]::UTF8)
$apiAsil = [IO.File]::ReadAllText((Join-Path (Join-Path $depoKok 'motor') 'api-hedef.ps1'), [Text.Encoding]::UTF8)

function Ayristir([string]$metin) {
  $tk = $null; $hata = $null
  $ast = [System.Management.Automation.Language.Parser]::ParseInput($metin, [ref]$tk, [ref]$hata)
  if ($hata -and $hata.Count) { throw "ayrıştırılamadı: $($hata[0].Message)" }
  return $ast
}
function IslevYukle([string]$metin, [string[]]$adlar) {
  $ast = Ayristir $metin
  $parca = foreach ($ad in $adlar) {
    $fn = @($ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $ad }, $true))
    if (-not $fn.Count) { throw "$ad BULUNAMADI" }
    $fn[0].Extent.Text
  }
  return [scriptblock]::Create(($parca -join "`n"))
}

function Soru([string]$metin) { return [pscustomobject]@{ soru = $metin; dogru = 'B'; siklar = [pscustomobject]@{ A = 'bir'; B = 'iki'; C = 'üç'; D = 'dört'; E = 'beş' } } }
function Kor($s, [string]$cevap) { $s | Add-Member -NotePropertyName kor_cozum -NotePropertyValue ([pscustomobject]@{ dogru_mu = ($cevap -eq 'B'); cevap = $cevap; sonuc = '123.456' }) -Force; return $s }
function KK($s, [bool]$dogruMu, [switch]$Bayat) {
  $s | Add-Member -NotePropertyName kor_cozum_kaynakli -NotePropertyValue ([pscustomobject]@{ dogru_mu = $dogruMu; cevap = $(if ($dogruMu) { 'B' } else { 'E' }); kor_cevap = "$($s.kor_cozum.cevap)"; parmak_izi = $(if ($Bayat) { 'eski' } else { SmmmParmakIzi $s }) }) -Force
  return $s
}

function SinavKos([string]$uretici, [string]$api) {
  $sonuc = New-Object System.Collections.Generic.List[string]
  function V([string]$ad, [bool]$ok, [string]$ek) { if ($ok) { if (-not $Sessiz -and -not $Mutasyon) { Write-Host "  OK    $ad" } } else { $sonuc.Add("$ad ($ek)"); if (-not $Sessiz -and -not $Mutasyon) { Write-Host "  DÜŞTÜ $ad ($ek)" } } }

  # ===== (a) TAVAN =====
  $uAst = Ayristir $uretici
  $atama = @($uAst.FindAll({ param($n) $n -is [System.Management.Automation.Language.AssignmentStatementAst] -and "$($n.Left)" -eq '$KOR_MAXTOK' }, $true))
  $deger = $(if ($atama.Count -eq 1) { [int]"$($atama[0].Right)" } else { -1 })
  V "a1 `$KOR_MAXTOK tek kez atanır ve ≥ 8000 ($deger)" ($deger -ge 8000) "atama $($atama.Count), değer $deger"
  # kör modeliyle yapılan BÜTÜN çağrılar (TopluTopla / Invoke-ClaudeMesaj) tavanı sabitten alır
  $korCagri = @($uAst.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] -and @('TopluTopla', 'Invoke-ClaudeMesaj') -contains "$($n.GetCommandName())" -and $n.Extent.Text -match '\$KorModel' }, $true))
  $sabitsiz = @($korCagri | Where-Object { $_.Extent.Text -notmatch '\$KOR_MAXTOK' })
  V "a2 kör/KK çağrılarının hepsi `$KOR_MAXTOK kullanır ($($korCagri.Count) çağrı)" ($korCagri.Count -ge 6 -and $sabitsiz.Count -eq 0) "sabitsiz: $(@($sabitsiz | ForEach-Object { $_.Extent.Text.Substring(0,[Math]::Min(70,$_.Extent.Text.Length)) }) -join ' | ')"
  # parmak izi max_tokens taşımaz: Get-IcerikParmak tek parametreli ve her çağrıda yalnız içerik verilir
  $aAst = Ayristir $api
  $pFn = @($aAst.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Get-IcerikParmak' }, $true))
  $pParam = $(if ($pFn.Count -and $pFn[0].Parameters) { $pFn[0].Parameters.Count } elseif ($pFn.Count -and $pFn[0].Body.ParamBlock) { $pFn[0].Body.ParamBlock.Parameters.Count } else { -1 })
  V "a3 Get-IcerikParmak tek parametre (içerik)" ($pParam -eq 1) "parametre $pParam"
  $pCagri = @(@($aAst, $uAst) | ForEach-Object { $_.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] -and "$($n.GetCommandName())" -eq 'Get-IcerikParmak' }, $true) })
  $pYabanci = @($pCagri | Where-Object { @($_.CommandElements).Count -ne 2 -or "$($_.CommandElements[1])" -notmatch '^\$(i|is)\.icerik$' })
  V "a4 parmak izi çağrıları yalnız içerik verir ($($pCagri.Count) çağrı)" ($pCagri.Count -ge 3 -and $pYabanci.Count -eq 0) "yabancı: $(@($pYabanci | ForEach-Object { $_.Extent.Text }) -join ' | ')"
  # işlevsel: aynı içerik 2.500 ve 8.000 tavanla AYNI parmak izi; farklı içerik FARKLI (yanlış alarm denetimi)
  . ([scriptblock]::Create($api))
  $dok = Join-Path ([IO.Path]::GetTempPath()) ("kor-tavan-sinav-" + [guid]::NewGuid().ToString('N') + '.jsonl')
  $eskiDok = $env:MEVZUAT_ISTEM_DOK; $env:MEVZUAT_ISTEM_DOK = $dok
  try {
    $is1 = @{ id = 'kp-01'; model = 'claude-opus-5'; icerik = 'Kör istem METNİ'; maxTok = 2500; effort = '' }
    $is2 = @{ id = 'kp-01'; model = 'claude-opus-5'; icerik = 'Kör istem METNİ'; maxTok = 8000; effort = '' }
    $is3 = @{ id = 'kp-01'; model = 'claude-opus-5'; icerik = 'Kör istem METNİ.'; maxTok = 8000; effort = '' }
    Write-IstemDokumu -Isler @($is1, $is2, $is3) -Etiket 'sinav/K' 6>$null | Out-Null
    $sat = @(Get-Content $dok -Encoding UTF8 | ForEach-Object { ConvertFrom-Json -InputObject $_ })
  } finally { $env:MEVZUAT_ISTEM_DOK = $eskiDok; Remove-Item $dok -ErrorAction SilentlyContinue }
  V 'a5 aynı istem 2.500 / 8.000 tavanla → AYNI parmak izi (eski ödenmiş parti hasat edilir)' ($sat.Count -eq 3 -and "$($sat[0].parmak)" -eq "$($sat[1].parmak)" -and [int]$sat[1].maxTok -eq 8000) "$($sat[0].parmak) / $($sat[1].parmak)"
  V 'a6 istem bir karakter değişince parmak izi FARKLI (yanlış hasat yok)' ($sat.Count -eq 3 -and "$($sat[1].parmak)" -ne "$($sat[2].parmak)") "$($sat[1].parmak) / $($sat[2].parmak)"

  # ===== (b) HİÇBİRİ → KAYNAKLI İKİNCİ ÇÖZÜM =====
  . (IslevYukle $uretici @('KorKaynakliGerekli', 'SmmmKorKapisi'))
  $script:Sinav = 'SMMM'; $script:KorKaynak = $false; $script:ApiKapali = $false; $script:SadeceHtml = $false; $script:Etiket = 'smmm-sinav-x'; $script:kok = $depoKok
  $script:SMMM_ONAY_HARITA = @{}
  V 'b1 kör HİÇBİRİ, KK yok → KK AÇILIR' ((KorKaynakliGerekli (Kor (Soru 's1') 'HİÇBİRİ'))) 'false'
  V 'b2 kör HİÇBİRİ, bu metne ait güncel KK var → yeniden AÇILMAZ (çift ödeme yok)' (-not (KorKaynakliGerekli (KK (Kor (Soru 's2') 'HİÇBİRİ') $true))) 'true'
  V 'b3 kör HİÇBİRİ, KK eski soru metnine ait → AÇILIR' ((KorKaynakliGerekli (KK (Kor (Soru 's3') 'HİÇBİRİ') $true -Bayat))) 'false'
  $s4 = Kor (Soru 's4') 'C'; $s4 | Add-Member -NotePropertyName celdirici_yol -NotePropertyValue ([pscustomobject]@{ C = 'oranı yarıya indirmedi' })
  V 'b4 kör C + C bizim tuzağımız → AÇILIR (eski kural aynen)' ((KorKaynakliGerekli $s4)) 'false'
  V 'b5 kör C, tuzak işareti yok → AÇILMAZ (eski kural aynen)' (-not (KorKaynakliGerekli (Kor (Soru 's5') 'C'))) 'true'
  V 'b6 kör doğru (B) → AÇILMAZ' (-not (KorKaynakliGerekli (Kor (Soru 's6') 'B'))) 'true'
  V 'b7 kör cevabı bozuk/boş → AÇILMAZ' (-not (KorKaynakliGerekli (Kor (Soru 's7') ''))) 'true'
  # KAPI-BOS ölçümünde (30.09) A–E dışı anahtar gerçekten görüldü ("F_placeholder"): böyle bir kör cevabı tuzak sözlüğünde karşılık bulsa da KK açmaz
  $s7b = Kor (Soru 's7b') 'F_placeholder'; $s7b | Add-Member -NotePropertyName celdirici_yol -NotePropertyValue ([pscustomobject]@{ F_placeholder = 'yer tutucu' })
  V 'b7b kör cevabı A–E dışı (F_placeholder) ve sözlükte karşılığı var → AÇILMAZ' (-not (KorKaynakliGerekli $s7b)) 'true'
  $script:Sinav = 'SGS'
  V 'b8 SGS''de kör HİÇBİRİ → AÇILMAZ (yol yalnız bitirme)' (-not (KorKaynakliGerekli (Kor (Soru 's8') 'HİÇBİRİ'))) 'true'
  $script:Sinav = 'SMMM'; $script:KorKaynak = $true
  V 'b9 -KorKaynak koşusunda (kör zaten kaynaklı) → AÇILMAZ' (-not (KorKaynakliGerekli (Kor (Soru 's9') 'HİÇBİRİ'))) 'true'
  $script:KorKaynak = $false
  # kör kapısı (sonraki fazlara giriş) HİÇBİRİ kaydını tutarlı işler
  V 'b10 kapı: HİÇBİRİ + KK yok → KAYNAKLI-YOK' ((SmmmKorKapisi 'kp-10' (Kor (Soru 's10') 'HİÇBİRİ')) -eq 'KAYNAKLI-YOK') ''
  V 'b11 kapı: HİÇBİRİ + KK ✗ → IKISI-YANLIS' ((SmmmKorKapisi 'kp-11' (KK (Kor (Soru 's11') 'HİÇBİRİ') $false)) -eq 'IKISI-YANLIS') ''
  V 'b12 kapı: HİÇBİRİ + KK ✓, onay yok → ONAY-BEKLIYOR' ((SmmmKorKapisi 'kp-12' (KK (Kor (Soru 's12') 'HİÇBİRİ') $true)) -eq 'ONAY-BEKLIYOR') ''
  $s13 = KK (Kor (Soru 's13') 'HİÇBİRİ') $true
  $script:SMMM_ONAY_HARITA = @{ 'smmm-sinav-x/kp-13' = [pscustomobject]@{ karar = 'ONAY'; parmak_izi = (SmmmParmakIzi $s13); tarih = '2026-10-08' } }
  V 'b13 kapı: HİÇBİRİ + KK ✓ + Cem ONAY → GECER' ((SmmmKorKapisi 'kp-13' $s13) -eq 'GECER') ''
  # yayın şartının kör istisnası (KK TEK BAŞINA yayın açmaz)
  V 'b14 yayın: HİÇBİRİ + KK ✓, onay YOK → geçmez' (-not (SmmmKorIstisna 'smmm-sinav-x/kp-14' (KK (Kor (Soru 's14') 'HİÇBİRİ') $true) @{}).gecer) ''
  V 'b15 yayın: HİÇBİRİ + KK ✓ + ONAY (parmak izi tutuyor) → geçer' ((SmmmKorIstisna 'smmm-sinav-x/kp-13' $s13 $script:SMMM_ONAY_HARITA).gecer) ''
  $s16 = KK (Kor (Soru 's16') 'HİÇBİRİ') $true; $s16.kor_cozum.cevap = 'C'
  V 'b16 yayın: KK HİÇBİRİ kör kararına ait, kör sonra C oldu → geçmez' (-not (SmmmKorIstisna 'smmm-sinav-x/kp-16' $s16 @{ 'smmm-sinav-x/kp-16' = [pscustomobject]@{ karar = 'ONAY'; parmak_izi = (SmmmParmakIzi $s16) } }).gecer) ''
  return , $sonuc
}

$TOPLAM = 23
if (-not $Mutasyon) {
  $kalan = SinavKos $ureticiAsil $apiAsil
  ''
  "KÖR TAVAN + HİÇBİRİ ÖZ-SINAVI: $($TOPLAM - $kalan.Count)/$TOPLAM geçti"
  if ($kalan.Count) { foreach ($k in $kalan) { Write-Host "  KIRMIZI: $k" -ForegroundColor Red }; exit 1 }
  Write-Host 'YEŞİL' -ForegroundColor Green
  exit 0
}

$mutasyonlar = @(
  @{ ad = 'Ma1 tavan 2.500''e geri'; d = 'u'; eski = '$KOR_MAXTOK=8000'; yeni = '$KOR_MAXTOK=2500' }
  @{ ad = 'Ma2 bir kör çağrısı sabit 2.500 (KK toplu)'; d = 'u'; eski = 'TopluTopla $id $KorModel $istKK $KOR_MAXTOK'; yeni = 'TopluTopla $id $KorModel $istKK 2500' }
  @{ ad = 'Ma3 bir kör çağrısı sabit 2.500 (anlık tekrar)'; d = 'u'; eski = '$yK2=Invoke-ClaudeMesaj -Model $KorModel -Icerik $istK -MaxTok $KOR_MAXTOK'; yeni = '$yK2=Invoke-ClaudeMesaj -Model $KorModel -Icerik $istK -MaxTok 2500' }
  @{ ad = 'Ma4 parmak izine max_tokens girdi (toplu kayıt)'; d = 'a'; eski = '$parmakHep["$($i.id)"] = (Get-IcerikParmak $i.icerik)'; yeni = '$parmakHep["$($i.id)"] = (Get-IcerikParmak ("$($i.maxTok)"+$i.icerik))' }
  @{ ad = 'Ma5 parmak izine max_tokens girdi (döküm, işlevsel)'; d = 'a'; eski = 'parmak = ((Get-IcerikParmak $i.icerik)'; yeni = 'parmak = ((Get-IcerikParmak ("$($i.maxTok)"+$i.icerik))' }
  @{ ad = 'Mb1 HİÇBİRİ dalı kapalı'; d = 'u'; eski = 'if($kkHarf -ceq ''HİÇBİRİ''){'; yeni = 'if($false){' }
  @{ ad = 'Mb2 HİÇBİRİ dalında güncel-KK denetimi yok (çift ödeme)'; d = 'u'; eski = '-eq $kkHarf){ return $false }   # bu soru metni için güncel karar var
    return $true'; yeni = '-eq $kkHarf){ return $true }   # bu soru metni için güncel karar var
    return $true' }
  @{ ad = 'Mb3 tuzak şartı kalktı (A–E her yanlışta KK)'; d = 'u'; eski = 'if(-not $kkTuzak){ return $false }'; yeni = '' }
  @{ ad = 'Mb4 SGS korunması kalktı'; d = 'u'; eski = "if(`$Sinav -ne 'SMMM' -or `$KorKaynak -or `$ApiKapali -or `$SadeceHtml){ return `$false }"; yeni = 'if($KorKaynak -or $ApiKapali -or $SadeceHtml){ return $false }' }
  @{ ad = 'Mb5 A–E harf şartı kalktı (bozuk cevap da KK açar)'; d = 'u'; eski = "if(`$kkHarf -notmatch '^[A-E]`$'){ return `$false }"; yeni = '' }
)
$kirmizi = 0
foreach ($m in $mutasyonlar) {
  $u = ($ureticiAsil -replace "`r`n", "`n"); $a = ($apiAsil -replace "`r`n", "`n"); $eskiN = ($m.eski -replace "`r`n", "`n"); $yeniN = ($m.yeni -replace "`r`n", "`n")
  if ($m.d -eq 'u') { if (-not $u.Contains($eskiN)) { throw "mutasyon hedefi yok: $($m.ad)" }; $u = $u.Replace($eskiN, $yeniN) }
  else { if (-not $a.Contains($eskiN)) { throw "mutasyon hedefi yok: $($m.ad)" }; $a = $a.Replace($eskiN, $yeniN) }
  try { $k = SinavKos $u $a } catch { $k = @("istisna: $($_.Exception.Message)") }   # bozuk kod patlarsa da sınav KIRMIZI sayılır
  if ($k.Count) { $kirmizi++; "  KIRMIZI (beklenen) $($m.ad) → $($k.Count) vaka düştü: $($k[0])" } else { Write-Host "  YEŞİL KALDI (SINAV EKSİK) $($m.ad)" -ForegroundColor Red }
}
"MUTASYON: $kirmizi/$($mutasyonlar.Count) bozma KIRMIZI düşürdü"
if ($kirmizi -ne $mutasyonlar.Count) { exit 1 }
exit 0
