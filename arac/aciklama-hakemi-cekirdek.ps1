# arac/aciklama-hakemi-cekirdek.ps1 — AÇIKLAMA HAKEMİ ÇEKİRDEĞİ (30.09.2026, Cem "b yap": yeni üretime bağla + banka dalgası)
# Ölçüm betiği (arac/aciklama-hakemi.ps1) ve üretim koşucusu (motor/kalip-kosucu.ps1) AYNI istemi ve AYNI karar okumasını kullanır.
#   AciklamaHakemIs $id $kayit $model $effort $maxTok  → Invoke-ClaudeToplu iş kaydı
#   AciklamaHakemKarar $cevapNesnesi                    → [pscustomobject]@{ karar='TEMIZ'|'KUSURLU'|'OLCULEMEDI'; kusurlar=@(); dur }
#   AciklamaHakemBedelYaz $etiket                       → Get-BedelOzet satırını bedel defterine (veri/fabrika/bedel-kayit.jsonl) yazar
# ÖLÇÜLDÜ (30.09, 50 etiketli SGS sorusu, claude-opus-5-5 medium, toplu): elle kusurlu 25'in 20'si yakalandı; elle temiz 25'in 12'sinde alarm,
#   okunan gerekçelerin çoğu gerçek kusur. Soru başı ≈0,017 USD (giriş ≈4.700 · çıkış ≈720 jeton).
# 🚫 GÖRMEZ: yazım/üslup (bilerek) · kaynak paketinde olmayan kuralın doğruluğu · hakemin kendi hatası (kaçırdığı 5/25 hafif kusur) ·
#   06.11'den önce TEMIZ almış soruların konu özeti (o kararlar özeti görmeden verildi) · 01.10'dan eski sorular (AhAday dışı).

$script:AH_MODEL_ALAN = @('hakem', 'hakem2', 'kor_cozum', 'simulasyon_sonnet', 'kaynak_metin_ozet', 'aciklama_hakem')
function AhKisalt($v, [int]$n) { if ($null -eq $v) { return $null }; $s = $(if ($v -is [string]) { $v } else { ConvertTo-Json -InputObject $v -Depth 12 -Compress }); if ($s.Length -gt $n) { $s.Substring(0, $n) + ' …(kısaltıldı)' } else { $s } }

# 06.11.2026 (Cem "bu hatayı yeni soru basımında kontrol olarak kural olarak ekleyelim"): konu özeti de öğrenciye gösterilir ama hakeme gitmiyordu.
#   ÖLÇÜLDÜ: smmm-w3-yvergi-kolay/kp-03 (özet "zammı en sona ayrı ekle", doğru cevap zamsız 17.350) · smmm-w8-1-fmuh-kolay/kp-02 · kgk-t4-tms-g3-cokzor/kp-04.
#   Üye doğru cevaba itiraz etti, çünkü özet yanlış şıkkın yolunu öğretiyordu. Kural 5 + konu_ozeti alanı bu boşluğu kapatmak için eklendi; yakalama oranı ÖLÇÜLMEDİ.
function AhKonuOzeti($k) {
  if ($env:AHS_MUTASYON -eq 'ozet-yok' -or -not $k.PSObject.Properties['konu_giris'] -or $null -eq $k.konu_giris) { return $null }
  $g = $k.konu_giris; if ($g -is [string]) { return $g }
  # 07.11 B33: terimler de ekranda basılır ama hakeme gitmiyordu ("Dönem Sonu Stok · piyasa fiyatlar", smmm-4k-a-yfta-kolay-r6/kp-01). Yakalama oranı ÖLÇÜLMEDİ.
  $terim = $(if ($env:AHS_MUTASYON -eq 'terim-yok') { $null } else { $g.terimler })
  return [ordered]@{ nedir = $g.nedir; desen = $g.desen; sinavda = $g.sinavda; harita = $g.harita; yontemler = $g.yontemler; ornek = $g.ornek; panel_ornek = $g.panel_ornek; terimler = $terim }
}

function AciklamaHakemIs([string]$id, $k, [string]$model = 'claude-opus-5-5', [string]$effort = 'medium', [int]$maxTok = 1600) {
  $gorunen = [ordered]@{
    konu_ozeti = (AhKonuOzeti $k); sinav_taktigi = $k.sinav_taktigi; notlandirici = $k.notlandirici
    soru = $k.soru; siklar = $k.siklar; dogru = $k.dogru; aciklama = $k.aciklama
    # 07.11 B34: öğrencinin gördüğü ama hakeme gitmeyen alanlar (verilenler, sade.sinav, sade.kavramlar, yevmiye) eklendi. Yakalama oranı ÖLÇÜLMEDİ.
    sade = $(if ($k.sade) { if ($env:AHS_MUTASYON -eq 'alan-yok') { [ordered]@{ dogru = $k.sade.dogru; siklar = $k.sade.siklar } } else { [ordered]@{ dogru = $k.sade.dogru; sinav = $k.sade.sinav; siklar = $k.sade.siklar; kavramlar = $k.sade.kavramlar } } } else { $null })
    verilenler = $(if ($env:AHS_MUTASYON -eq 'alan-yok') { $null } else { $k.verilenler })
    yevmiye = $(if ($env:AHS_MUTASYON -eq 'alan-yok' -or -not $k.sema -or "$($k.sema.tur)" -ne 'yevmiye') { $null } else { $k.sema })
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
5. konu_ozeti, hap, sinav_taktigi, notlandirici: doğru cevabın çözüm yoluyla çelişiyor mu? Doğru çözümün dışarıda bıraktığı bir kalemi eklemeyi ya da yanlış şıkkın hesabını doğru yol gibi öğretiyorsa, doğru çözümün yaptığı şeyi "tuzak" diye gösteriyorsa, yanlış madde ya da paragraf numarası veriyorsa KUSUR. Tuzağı doğru tarif eden cümle kusur değildir.
6. konu_ozeti.terimler: her terimin tanim'ı doğru mu, kim ve kaynak alanı gerçeği söylüyor mu? kim, o değeri gerçek hayatta koyan kişi ya da kurumdur ve boş olabilir. Kayıttan gelen ya da formülle çıkan kaleme (dönem stoku, ortalama stok, devir hızı, finansal oran) "piyasa fiyatlar" ya da "işletme yönetimi belirler" yazılmışsa, soruda verilen değere "sen hesaplarsın" denmişse KUSUR. Kanun yalnız kalemin işleyişini söylüyor, tutarı ya da oranı taraflar koyuyorsa (vade farkı, iskonto, taşıma gideri gibi) "kanun sabitler" yazmak KUSUR. Soruda değeri geçmeyen kaleme "soruda verilir" yazmak KUSUR.
7. teshis.<doğru>, adimlar, konu_ozeti.yontemler, sinav_taktigi: BU sorunun kökünü ve şıklarını doğru anlatıyor mu? Olumsuz kökte (hangisi değildir, girmez, yanlıştır) öteki şıklar kurala UYDUKLARI için elenir; onları "şartı eksik", "kuralı düşürüyor", "başka hükmü uyguluyor" diye anlatmak KUSUR. Soruda bulunmayan bir şeyden (olmayan sözcük farkı, hesap, tutar) söz etmek KUSUR. Soruyu ve şıkları hiç anmayan, her soruya yapışabilecek kalıp cümle bu soruyu yanlış anlatıyorsa KUSUR.
8. verilenler, sade.sinav, sade.kavramlar, yevmiye: değer ve tutar soruyla aynı mı, anlam ve tanım doğru mu, verinin çözümdeki rolü doğru çözümle uyuşuyor mu, yevmiye doğru çözümün tutarlarını veriyor mu? Tutmuyorsa KUSUR.
Yazım, noktalama ve üslup kusurlarını SAYMA. Yalnız somut, gösterilebilir hata kusurdur; şüphe kusur değildir.

YALNIZ şu JSON'u döndür, başka hiçbir şey yazma:
{"karar":"TEMIZ" ya da "KUSURLU","kusurlar":[{"alan":"ör. sade.siklar.B","neden":"en çok 25 kelime"}]}

SORU (öğrencinin gördüğü alanlar, JSON):
$(ConvertTo-Json -InputObject $gorunen -Depth 12 -Compress)

KAYNAK (sorunun dayandığı metin özeti):
$(if ($kaynak) { $kaynak } else { '(yok)' })
"@
  $istem = $istem -replace "`r`n", "`n"
  if ($env:AHS_MUTASYON -eq 'kural5-yok') { $istem = $istem -replace '(?m)^5\. konu_ozeti.*\n', '' }
  if ($env:AHS_MUTASYON -eq 'kural6-yok') { $istem = $istem -replace '(?m)^6\. konu_ozeti.*\n', '' }
  if ($env:AHS_MUTASYON -eq 'kural7-yok') { $istem = $istem -replace '(?m)^7\. teshis.*\n', '' }
  if ($env:AHS_MUTASYON -eq 'kural8-yok') { $istem = $istem -replace '(?m)^8\. verilenler.*\n', '' }
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
