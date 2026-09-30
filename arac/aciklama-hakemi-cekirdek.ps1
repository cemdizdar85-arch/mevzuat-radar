# arac/aciklama-hakemi-cekirdek.ps1 — AÇIKLAMA HAKEMİ ÇEKİRDEĞİ (30.09.2026, Cem "b yap": yeni üretime bağla + banka dalgası)
# Ölçüm betiği (arac/aciklama-hakemi.ps1) ve üretim koşucusu (motor/kalip-kosucu.ps1) AYNI istemi ve AYNI karar okumasını kullanır.
#   AciklamaHakemIs $id $kayit $model $effort $maxTok  → Invoke-ClaudeToplu iş kaydı
#   AciklamaHakemKarar $cevapNesnesi                    → [pscustomobject]@{ karar='TEMIZ'|'KUSURLU'|'OLCULEMEDI'; kusurlar=@(); dur }
#   AciklamaHakemBedelYaz $etiket                       → Get-BedelOzet satırını bedel defterine (veri/fabrika/bedel-kayit.jsonl) yazar
# ÖLÇÜLDÜ (30.09, 50 etiketli SGS sorusu, claude-opus-5-5 medium, toplu): elle kusurlu 25'in 20'si yakalandı; elle temiz 25'in 12'sinde alarm,
#   okunan gerekçelerin çoğu gerçek kusur. Soru başı ≈0,017 USD (giriş ≈4.700 · çıkış ≈720 jeton).
# 🚫 GÖRMEZ: yazım/üslup (bilerek) · kaynak paketinde olmayan kuralın doğruluğu · hakemin kendi hatası (kaçırdığı 5/25 hafif kusur).

$script:AH_MODEL_ALAN = @('hakem', 'hakem2', 'kor_cozum', 'simulasyon_sonnet', 'kaynak_metin_ozet', 'aciklama_hakem')
function AhKisalt($v, [int]$n) { if ($null -eq $v) { return $null }; $s = $(if ($v -is [string]) { $v } else { ConvertTo-Json -InputObject $v -Depth 12 -Compress }); if ($s.Length -gt $n) { $s.Substring(0, $n) + ' …(kısaltıldı)' } else { $s } }

function AciklamaHakemIs([string]$id, $k, [string]$model = 'claude-opus-5-5', [string]$effort = 'medium', [int]$maxTok = 1600) {
  $gorunen = [ordered]@{
    soru = $k.soru; siklar = $k.siklar; dogru = $k.dogru; aciklama = $k.aciklama
    sade = $(if ($k.sade) { [ordered]@{ dogru = $k.sade.dogru; siklar = $k.sade.siklar } } else { $null })
    teshis = $k.teshis; celdirici_yol = $k.celdirici_yol
    adimlar = $(if ($k.adimlar) { @($k.adimlar | ForEach-Object { [ordered]@{ anlatim = $_.anlatim; formul = $_.formul } }) } else { $null })
    ikiz = $(if ($k.ikiz) { [ordered]@{ ikiz_soru = $k.ikiz.ikiz_soru; tablo = $k.ikiz.tablo; hedef_cumle = $k.ikiz.hedef_cumle } } else { $null })
    hap = $k.hap; dayanak = $k.dayanak
  }
  $kaynak = AhKisalt $k.kaynak_metin_ozet 5000
  $istem = @"
Sen SMMM sınavları (staja başlama SGS ve staj bitirme) soru bankasında ÇÖZÜM ANLATIMINI denetleyen bir hakemsin. Soru kökü, şıklar ve doğru cevap harfi doğru kabul edilir; senin işin öğrenciye gösterilen AÇIKLAMA metinlerinin doğru olup olmadığıdır.

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
  return @{ id = $id; model = $model; maxTok = $maxTok; effort = $effort; icerik = @(@{ type = 'text'; text = $istem }) }
}

# toplu araç cevabı nesne döndürür ({metin, dur, ...}); 30.09 ilk ölçüm nesneyi metin sanıp 50/50 "ölçülemedi" yazmıştı
function AciklamaHakemKarar($c) {
  $metin = $(if ($c -is [hashtable]) { "$($c['metin'])" } elseif ($c -and $c.PSObject.Properties['metin']) { "$($c.metin)" } else { "$c" })
  $dur = $(if ($c -is [hashtable]) { "$($c['dur'])" } elseif ($c -and $c.PSObject.Properties['dur']) { "$($c.dur)" } else { '' })
  $karar = 'OLCULEMEDI'; $kus = @()
  $m = [regex]::Match($metin, '\{[\s\S]*\}')
  if ($m.Success) { try { $j = ConvertFrom-Json -InputObject $m.Value; $kk = "$($j.karar)".ToUpperInvariant(); if ($kk -in @('TEMIZ', 'KUSURLU')) { $karar = $kk; $kus = @($j.kusurlar | Where-Object { $_ }) } } catch {} }
  return [pscustomobject]@{ karar = $karar; kusurlar = $kus; dur = $dur }
}

# bedel defterine satır (kalip-parti-uret.ps1 BedelDefterYaz ile aynı biçim + Mutex). Etiket "<parti>/AH" → koşucu PlanHarcama plana sayar.
function AciklamaHakemBedelYaz([string]$etiket, [string]$kok) {
  $bz = Get-BedelOzet; if (-not $bz -or -not @($bz.satirlar).Count) { return $null }
  $yol = Join-Path $kok 'veri\fabrika\bedel-kayit.jsonl'
  $satir = (ConvertTo-Json -InputObject ([ordered]@{ zaman = (Get-Date -Format 'yyyy-MM-dd HH:mm'); etiket = $etiket; ders = 'aciklama-hakemi'; toplamUsd = $bz.toplamUsd; varsayim = $bz.fiyatVarsayim; satirlar = $bz.satirlar }) -Compress -Depth 4) + "`n"
  $mx = New-Object System.Threading.Mutex($false, 'Global\tetikte-bedel-kayit'); $al = $false
  try { $al = $mx.WaitOne(20000) } catch { $al = $true }
  try { [IO.File]::AppendAllText($yol, $satir, [Text.UTF8Encoding]::new($false)) } finally { if ($al) { try { $mx.ReleaseMutex() } catch {} }; $mx.Dispose() }
  return $bz.toplamUsd
}
