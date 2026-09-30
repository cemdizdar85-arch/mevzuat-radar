#requires -Version 5.1
# ============================================================================
#  AÇIKLAMA HAKEMİ — ÖLÇÜM (30.09.2026, Cem "1.2.3 üçünü de yap": ≤ 2 USD ölçüm onaylı)   PARALI, hep TOPLU
#
#  NEDEN: SGS risk taramasında elle okunan 1.744 sorunun 334'ü kusurluydu; kusurların çoğu ÇÖZÜM ANLATIMINDA (sade, teşhis,
#  adımlar, ikiz). Dört hakem soruya ve anahtara bakıyor, bu metni okuyan yok. 0 USD kapılar (KAPI-AS2/EK) küçük bir kısmını görüyor.
#  Bu betik, anlatımı anahtar ve kaynakla okuyan beşinci hakemin YAKALAMA ORANINI ve BEDELİNİ ölçer. Üretime BAĞLI DEĞİL;
#  bağlanması Cem'in bedeli görüp onaylamasına bağlı (CLAUDE.md SINAV · açıklama kapısı kural 3).
#
#  GİRDİ: etiketli örneklem JSON (soru içeriği taşır → depo DIŞINDA durur; depo public). Her soru: anahtar, etiket (KUSURLU/TEMIZ),
#  kusur_notu (elle okumanın notu), kayit. Model yalnız öğrencinin gördüğü alanları + kaynak özetini görür; hakem/kör/sim alanları gitmez.
#  ÇIKTI: -Cikti JSON (depo dışı): soru başı hakem kararı + gerekçe; ekrana yalnız SAYILAR (günlük public olabilir).
#  BEDEL: toplu (%50). -Kuru: istek GÖNDERİLMEZ, jeton ve en kötü durum bedeli hesaplanır; -Tavan aşılıyorsa gerçek koşu DURUR.
#  Kullanım:
#    powershell -NoProfile -File arac/aciklama-hakemi.ps1 -Orneklem <json> -Cikti <json> [-Kuru] [-Tavan 2] [-MaxTok 2500]
#  🚫 GÖRMEZ: yazım/üslup kusuru (bilerek sayılmaz) · kaynağı pakette olmayan kuralın doğruluğu (hakem kaynağa bakar, dünya bilgisine değil —
#     istemde yazılı) · etiketin kendisinin yanlış olması (elle okuma da hata yapar; YANLIŞ ALARM sayılan bulgular ayrıca okunmalı).
# ============================================================================
param([Parameter(Mandatory = $true)][string]$Orneklem, [Parameter(Mandatory = $true)][string]$Cikti,
  [string]$Model = 'claude-opus-5-5', [string]$Effort = 'medium', [int]$MaxTok = 2500, [double]$Tavan = 2.0,
  [string]$Etiket = '', [string]$HasatBid = '', [switch]$Kuru)
$ErrorActionPreference = 'Stop'
$depoKok = Split-Path -Parent $PSScriptRoot
. (Join-Path $depoKok 'motor\api-hedef.ps1')
if (-not $env:MEVZUAT_TOPLU_BEKLE_DK) { $env:MEVZUAT_TOPLU_BEKLE_DK = '1440' }   # Cem "hep toplu, ucuza bekle"
if (-not $Etiket) { $Etiket = "aciklama-hakemi-olcum-$(Get-Date -Format yyyyMMdd-HHmm)" }
$FIYAT = @{ 'claude-opus-5-5' = @(4, 20); 'claude-sonnet-5-5' = @(2, 10); 'claude-opus-5' = @(5, 25) }   # USD / 1M jeton (claude-api başvurusu 25.09); toplu ×0,5
if (-not $FIYAT.ContainsKey($Model)) { throw "fiyatı bilinmeyen model: $Model (bedel hesaplanamaz, gönderilmez)" }

$orn = Get-Content $Orneklem -Raw -Encoding UTF8 | ConvertFrom-Json
function Kisalt($v, [int]$n) { if ($null -eq $v) { return $null }; $s = $(if ($v -is [string]) { $v } else { ConvertTo-Json -InputObject $v -Depth 12 -Compress }); if ($s.Length -gt $n) { $s.Substring(0, $n) + ' …(kısaltıldı)' } else { $s } }
$isler = New-Object System.Collections.Generic.List[object]; $bilgi = @{}; $sira = 0
foreach ($q in @($orn.sorular)) {
  $sira++; $k = $q.kayit; $id = "q$sira"
  $bilgi[$id] = [pscustomobject]@{ anahtar = "$($q.anahtar)"; etiket = "$($q.etiket)"; kusur_notu = "$($q.kusur_notu)" }
  $gorunen = [ordered]@{
    soru = $k.soru; siklar = $k.siklar; dogru = $k.dogru; aciklama = $k.aciklama
    sade = $(if ($k.sade) { [ordered]@{ dogru = $k.sade.dogru; siklar = $k.sade.siklar } } else { $null })
    teshis = $k.teshis; celdirici_yol = $k.celdirici_yol
    adimlar = $(if ($k.adimlar) { @($k.adimlar | ForEach-Object { [ordered]@{ anlatim = $_.anlatim; formul = $_.formul } }) } else { $null })
    ikiz = $(if ($k.ikiz) { [ordered]@{ ikiz_soru = $k.ikiz.ikiz_soru; tablo = $k.ikiz.tablo; hedef_cumle = $k.ikiz.hedef_cumle } } else { $null })
    hap = $k.hap; dayanak = $k.dayanak
  }
  $kaynak = Kisalt $k.kaynak_metin_ozet 5000
  $istem = @"
Sen SMMM staja başlama (SGS) sınavı soru bankasında ÇÖZÜM ANLATIMINI denetleyen bir hakemsin. Soru kökü, şıklar ve doğru cevap harfi doğru kabul edilir; senin işin öğrenciye gösterilen AÇIKLAMA metinlerinin doğru olup olmadığıdır.

Denetle:
1. Her YANLIŞ şık için aciklama.X, sade.siklar.X, teshis.X ve celdirici_yol.X: anlatılan hata gerçekten o şıkkın KENDİ sayısını ya da ifadesini üretiyor mu? Başka şıkkın yolunu anlatıyorsa, sonucu yanlış yazıyorsa ya da açıklamalar bir harf kaymışsa (çözüm metni doğru şıkta değilse) KUSUR.
2. DOĞRU şıkkın anlatımı (aciklama.<doğru>, sade.dogru, adimlar): kural doğru mu, her ara rakam ve sonuç tutuyor mu? Her hesabı kendin yeniden yap.
3. İkiz soru: ikiz_soru ile tablo tutarlı mı, sonuç doğru mu, hedef_cumle cevabı açıkça veriyor mu?
4. Hesap kodu, kanun maddesi, oran: yanlışsa ya da güncel değilse (ör. KDV genel oranı %20, kurumlar vergisi %25, kâr payı stopajı %15) KUSUR. Kuralı yalnız aşağıdaki KAYNAK metne ve bu listeye dayanarak değerlendir; emin değilsen kusur deme.
Yazım, noktalama ve üslup kusurlarını SAYMA. Yalnız somut, gösterilebilir hata kusurdur; şüphe kusur değildir.

YALNIZ şu JSON'u döndür, başka hiçbir şey yazma:
{"karar":"TEMIZ" ya da "KUSURLU","kusurlar":[{"alan":"ör. sade.siklar.B","neden":"en çok 25 kelime"}]}

SORU (öğrencinin gördüğü alanlar, JSON):
$(ConvertTo-Json -InputObject $gorunen -Depth 12 -Compress)

KAYNAK (sorunun dayandığı metin özeti):
$(if ($kaynak) { $kaynak } else { '(yok)' })
"@
  $istem = $istem -replace "`r`n", "`n"
  $isler.Add(@{ id = $id; model = $Model; maxTok = $MaxTok; effort = $Effort; icerik = @(@{ type = 'text'; text = $istem }) })
}
$kar = 0; foreach ($i in $isler) { $kar += "$($i.icerik[0].text)".Length }
$girdiJ = [math]::Round($kar / 1.6)   # 30.09 ÖLÇÜLDÜ: /3 tahmini 134K dedi, gerçek 234K (≈1,7 kr/jeton, Türkçe+JSON) → /1,6 temkinli üst tahmin
$f = $FIYAT[$Model]
$enKotu = [math]::Round(0.5 * (($girdiJ / 1e6) * $f[0] + (($isler.Count * $MaxTok) / 1e6) * $f[1]), 3)
"AÇIKLAMA HAKEMİ ÖLÇÜMÜ: $($isler.Count) soru (etiket KUSURLU $(@($bilgi.Values | Where-Object { $_.etiket -eq 'KUSURLU' }).Count) · TEMIZ $(@($bilgi.Values | Where-Object { $_.etiket -eq 'TEMIZ' }).Count)) · model $Model · effort $Effort · maxTok $MaxTok"
"TAHMİN: girdi ~$girdiJ jeton · EN KÖTÜ DURUM toplu bedel $enKotu USD (her cevap maxTok'a kadar) · tavan $Tavan USD"
if ($Kuru) { "KURU: istek gönderilmedi."; exit 0 }
if ($enKotu -gt $Tavan) { throw "EN KÖTÜ DURUM BEDELİ ($enKotu USD) TAVANI ($Tavan USD) AŞIYOR — gönderilmedi. Soru sayısını ya da -MaxTok'u düşür, ya da Cem'e yeni tavan sor." }

$sonuc = @{}
if ($HasatBid) {
  $hedefH = Get-TopluBasliklar
  foreach ($hb in @($HasatBid -split '[,\s]+' | Where-Object { $_ })) { $hs = Get-ClaudeTopluSonuc $hb $hedefH $Etiket $false; if ($null -eq $hs) { "HASAT: $hb bitmemiş"; continue }; foreach ($hk in @($hs.Keys)) { if ($hk -notlike '__*') { $sonuc[$hk] = $hs[$hk] } } }
}
$kalan = @($isler | Where-Object { -not $sonuc.ContainsKey($_.id) })
if ($kalan.Count) { $y = Invoke-ClaudeToplu -Isler $kalan -Etiket $Etiket -BeklemeDk ([int]$env:MEVZUAT_TOPLU_BEKLE_DK) -OnbelleksizToplu; foreach ($yk in @($y.Keys)) { $sonuc[$yk] = $y[$yk] } }
if ($sonuc.ContainsKey('__zaman_asimi')) { throw "TOPLU ZAMAN AŞIMI — aynı komutla yeniden koşunca bedava hasat edilir. Çıktı YAZILMADI." }

$tp = 0; $fn = 0; $fp = 0; $tn = 0; $olcul = 0; $kesik = 0; $cikis = New-Object System.Collections.Generic.List[object]
foreach ($id in $bilgi.Keys) {
  # 30.09 ölçüldü: toplu araç cevabı nesne olarak döndürür ({metin, dur, girdi, cikti ...}); ilk koşu nesneyi metin sanıp 50/50 "ölçülemedi" yazdı
  $b = $bilgi[$id]; $c = $sonuc[$id]; $metin = $(if ($c -is [hashtable]) { "$($c['metin'])" } elseif ($c -and $c.PSObject.Properties['metin']) { "$($c.metin)" } else { "$c" })
  $dur = $(if ($c -is [hashtable]) { "$($c['dur'])" } elseif ($c -and $c.PSObject.Properties['dur']) { "$($c.dur)" } else { '' }); if ($dur -eq 'max_tokens') { $kesik++ }
  $karar = $null; $kus = @()
  $m = [regex]::Match($metin, '\{[\s\S]*\}')
  if ($m.Success) { try { $j = ConvertFrom-Json -InputObject $m.Value; $karar = "$($j.karar)".ToUpper(); $kus = @($j.kusurlar) } catch {} }
  if ($karar -notin @('TEMIZ', 'KUSURLU')) { $olcul++; $karar = 'OLCULEMEDI' }
  elseif ($b.etiket -eq 'KUSURLU' -and $karar -eq 'KUSURLU') { $tp++ } elseif ($b.etiket -eq 'KUSURLU') { $fn++ }
  elseif ($karar -eq 'KUSURLU') { $fp++ } else { $tn++ }
  $cikis.Add([pscustomobject]@{ id = $id; anahtar = $b.anahtar; etiket = $b.etiket; kusur_notu = $b.kusur_notu; hakem = $karar; kusurlar = $kus })
}
[IO.File]::WriteAllText($Cikti, (ConvertTo-Json -InputObject @($cikis.ToArray()) -Depth 8), [Text.UTF8Encoding]::new($false))
$bo = Get-BedelOzet
"SONUÇ: kusurlu $($tp + $fn)'nin $tp'ini yakaladı · temiz $($fp + $tn)'in $fp'inde alarm · ölçülemedi $olcul (maxTok'ta kesilen $kesik)"
"BEDEL (defter): $(($bo.satirlar | ForEach-Object { "$($_.model) giriş $($_.girdi) çıkış $($_.cikti) ≈ $($_.usd) USD" }) -join ' · ') · toplam $($bo.toplamUsd) USD"
"ÇIKTI: $Cikti (soru başı karar + gerekçe; depo dışı)"
