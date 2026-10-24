#requires -Version 5.1
# ============================================================================
#  SGS SON 20 GÜN — KÖR KALİBRASYON (24.10.2026, Cem onayı: tavan 13 USD toplam; emir başına tavan uygulanır)   PARALI, hep TOPLU
#
#  NE: girdi dosyasındaki sorular (çıkmış SGS soruları) BULUT KÖR KAPISININ AYNI çözücüsüyle, KAYNAKSIZ ve AÇIKLAMASIZ çözülür;
#  kör cevap resmî anahtarla karşılaştırılır. Kör kapının gerçek sınav sorusunda ne kadar tuttuğunu ders ders ölçer.
#  ÇÖZÜCÜ: arac/s20-kor-cekirdek.ps1 — istem, model, jeton tavanı, ayrıştırıcı motor/kalip-parti-uret.ps1'den AST ile alınır (kopya yok).
#  KAPI: veri/sinav/s20-kalibrasyon-emir.json → {emirler:[{no, onay, tavan_usd, girdi, aciklama, uygulandi}]}
#        onay:true + damgasız + -Calistir → PARALI; diğer her durum KURU (soru sayısı + tahmini USD, API'ye gidilmez, 0 USD).
#  GİRDİ: [{id, ders, soru, siklar:{A..E}, dogru}]   (id = Anthropic custom_id kuralına uyar: [A-Za-z0-9_-], en çok 64)
#  BEDEL: tahmin = girdi karakter/1,6 jeton + çıktı 500 jeton (ölçüldü 24.10: SGS kör, Opus 5 toplu, 09–24.10 bedel_kaydi
#         196 çağrı → çağrı başı girdi 777 · çıktı 340 jeton; 500 temkinli) · en kötü durum = çıktı KOR_MAXTOK.
#         Toplam tahmin tavanı aşarsa HİÇ GÖNDERİLMEZ. Gönderim ÖNCE DALGA, SONRA HEPSİ (arac/s20-ortak.ps1 S20DalgaKos).
#         Gerçek bedel bedel_kaydi'na etiket "sgs-s20-kalibrasyon/<no>".
#  ÇIKTI: veri/sinav/s20-kalibrasyon-sonuc-<no>.json → {ozet:{ders ders doğru/toplam}, sorular:[{id, ders, cevap, dogru, dogru_mu, hesap_kisa}]}
#  Kullanım:
#    powershell -NoProfile -File arac/s20-kor-kalibrasyon.ps1                         (emir dosyası, KURU)
#    powershell -NoProfile -File arac/s20-kor-kalibrasyon.ps1 -Calistir               (yalnız onaylı emir PARALI — bulut iş akışı)
#    powershell -NoProfile -File arac/s20-kor-kalibrasyon.ps1 -GirdiDosya x.json      (doğrudan girdi, HER ZAMAN KURU)
#  🚫 GÖRMEZ: çıkmış sorunun model eğitiminde görülmüş olması (ezber; kalibrasyon bunu ayıramaz) · görsel/tablolu sorular (girdi dışı)
#    · ikinci dalga gönderildikten sonra gerçek bedelin tahmini aşması (toplu parti yarıda kesilemez; ilk dalga en kötü durumla sınırlı).
# ============================================================================
param([string]$EmirDosya = 'veri/sinav/s20-kalibrasyon-emir.json', [string]$GirdiDosya = '', [switch]$Calistir,
  [int]$IlkDalga = 30, [int]$BeklemeDk = 290, [int]$CiktiTahminJ = 500)
$ErrorActionPreference = 'Stop'
$depoKok = Split-Path -Parent $PSScriptRoot
Set-Location $depoKok
. (Join-Path $depoKok 'motor\api-hedef.ps1')
. (Join-Path $depoKok 'motor\model-kod.ps1')
. (Join-Path $PSScriptRoot 's20-ortak.ps1')
. (Join-Path $PSScriptRoot 's20-kor-cekirdek.ps1')
Write-Host ("KÖR ÇÖZÜCÜ (üreticiden): model {0} · maxTok {1} · effort '' (→ {2}) · iz {3}" -f $script:S20_KOR_MODEL, $script:S20_KOR_MAXTOK, (Get-EffortDegeri ''), $script:S20_KOR_IZ.Substring(0, 16))

function KalGirdiOku([string]$yol) {
  if (-not (Test-Path $yol)) { throw "girdi dosyası yok: $yol" }
  $ham = @((S20Json $yol) | ForEach-Object { $_ })
  $tamam = New-Object System.Collections.Generic.List[object]; $gor = @{}
  foreach ($q in $ham) {
    $qid = "$($q.id)"
    if ($qid -notmatch '^[A-Za-z0-9_-]{1,64}$') { throw "geçersiz id (custom_id kuralı): '$qid'" }
    if ($gor.ContainsKey($qid)) { throw "yinelenen id: $qid" }; $gor[$qid] = 1
    if (-not "$($q.soru)".Trim()) { throw "soru metni boş: $qid" }
    foreach ($h in 'A', 'B', 'C', 'D', 'E') { if (-not $q.siklar -or -not "$($q.siklar.$h)".Trim()) { throw "şık eksik: $qid $h" } }
    if ("$($q.dogru)" -notmatch '^[A-E]$') { throw "doğru harfi geçersiz: $qid '$($q.dogru)'" }
    $tamam.Add($q)
  }
  return $tamam.ToArray()
}

$kosKor = {
  param($em, [bool]$odeme)
  $no = [int]$em.no; $tavanD = [double]$em.tavan_usd; $etiketK = "sgs-s20-kalibrasyon/$no"
  $sorular = @(KalGirdiOku "$($em.girdi)")
  $isler = @(foreach ($q in $sorular) { S20KorIs "$($q.id)" $q })
  $tt = S20Tahmin $isler $CiktiTahminJ
  $tTop = S20Topla $tt.tahmin @($isler | ForEach-Object { $_.id }); $kTop = S20Topla $tt.enKotu @($isler | ForEach-Object { $_.id })
  $dersSay = @{}; foreach ($q in $sorular) { $dersSay["$($q.ders)"] = 1 + [int]$dersSay["$($q.ders)"] }
  Write-Host ("SORU: {0} ({1} ders) · girdi {2}" -f $sorular.Count, $dersSay.Count, $em.girdi)
  Write-Host ("TAHMİN: {0:N2} USD (çıktı {1} jeton/soru varsayımı) · EN KÖTÜ DURUM {2:N2} USD (her cevap {3} jetona kadar) · tavan {4} USD" -f $tTop, $CiktiTahminJ, $kTop, $script:S20_KOR_MAXTOK, $tavanD)
  if ($tTop -gt $tavanD) { throw ("TAHMİNİ BEDEL ({0:N2} USD) TAVANI ({1} USD) AŞIYOR — GÖNDERİLMEZ" -f $tTop, $tavanD) }
  if (-not $odeme) { Write-Host "KURU: istek gönderilmedi (0 USD)."; return @{ durum = 'kuru' } }

  $onceki = 0.0; if ($em.PSObject.Properties['harcanan_usd']) { $onceki = [double]$em.harcanan_usd }
  $r1 = S20DalgaKos -Isler $isler -Tahmin $tt.tahmin -EnKotu $tt.enKotu -Tavan $tavanD -Etiket $etiketK -IlkDalga $IlkDalga -Onbelleksiz $false -BeklemeDk $BeklemeDk -OncekiHarcama $onceki
  if (-not $r1.gonderilen) { throw 'HİÇBİR İSTEK GÖNDERİLMEDİ (tavan ilk dalganın en kötü durumunu karşılamıyor) — emir damgalanmaz' }
  if ($r1.zaman_asimi) { $u = S20BedelYaz $etiketK 'sgs-s20-kalibrasyon' 's20-kor-kalibrasyon'; return @{ durum = 'bekliyor'; usd = $u } }
  $qMap = @{}; foreach ($q in $sorular) { $qMap["$($q.id)"] = $q }
  $karar = @{}; $bozuk = New-Object System.Collections.Generic.List[string]
  foreach ($i in $isler) { $iid = "$($i.id)"; if (-not $r1.sonuc.ContainsKey($iid)) { if ($r1.hata.ContainsKey($iid)) { $bozuk.Add($iid) }; continue }
    $kr = S20KorKarar $qMap[$iid] "$($r1.sonuc[$iid].metin)"; if ($kr) { $karar[$iid] = $kr } else { $bozuk.Add($iid) } }
  # bozuk/hatalı cevap: üretici bir kez ANLIK yeniden sorar; burada hep toplu → TUZLU ikinci toplu dalga (aynı istem, bozuk cevap bedava geri gelmez)
  $r2 = $null
  if ($bozuk.Count) {
    Write-Host "  BOZUK/HATALI CEVAP: $($bozuk.Count) soru → tuzlu toplu yeniden (bir kez)" -ForegroundColor Yellow
    $isB = @($isler | Where-Object { $bozuk.Contains("$($_.id)") })
    $r2 = S20DalgaKos -Isler $isB -Tahmin $tt.tahmin -EnKotu $tt.enKotu -Tavan $tavanD -Etiket $etiketK -IlkDalga $isB.Count -Onbelleksiz $false -BeklemeDk $BeklemeDk -ParmakTuz 's20-yeniden-1' -OncekiHarcama $onceki
    foreach ($iid in @($r2.sonuc.Keys)) { $kr = S20KorKarar $qMap[$iid] "$($r2.sonuc[$iid].metin)"; if ($kr) { $karar[$iid] = $kr } }
  }
  $butceYok = @{}; foreach ($x in @($r1.butce_yok)) { $butceYok[$x] = 1 }
  $liste = New-Object System.Collections.Generic.List[object]; $ozD = [ordered]@{}
  foreach ($q in $sorular) {
    $qid = "$($q.id)"; $d = "$($q.ders)"; if (-not $ozD.Contains($d)) { $ozD[$d] = [ordered]@{ dogru = 0; toplam = 0; cevapsiz = 0 } }
    $ozD[$d].toplam++
    if ($karar.ContainsKey($qid)) {
      $k = $karar[$qid]; if ($k.dogru_mu) { $ozD[$d].dogru++ }
      $hk = ("$($k.hesap)" -replace '\s+', ' ').Trim(); if ($hk.Length -gt 240) { $hk = $hk.Substring(0, 240) + '…' }
      $liste.Add([ordered]@{ id = $qid; ders = $d; cevap = $k.cevap; dogru = "$($q.dogru)"; dogru_mu = [bool]$k.dogru_mu; guven = $k.guven; hesap_kisa = $hk })
    } else {
      $ozD[$d].cevapsiz++
      $liste.Add([ordered]@{ id = $qid; ders = $d; cevap = $null; dogru = "$($q.dogru)"; dogru_mu = $null; durum = $(if ($butceYok.ContainsKey($qid)) { 'BUTCE_YETMEDI' } else { 'BOZUK' }) })
    }
  }
  $usd = S20BedelYaz $etiketK 'sgs-s20-kalibrasyon' 's20-kor-kalibrasyon'
  $dT = 0; $cT = 0; foreach ($v in $ozD.Values) { $dT += $v.dogru; $cT += ($v.toplam - $v.cevapsiz) }
  $cikti = "veri/sinav/s20-kalibrasyon-sonuc-$no.json"
  S20JsonYaz $cikti ([ordered]@{
      no = $no; tarih = (Get-Date -Format 'yyyy-MM-dd HH:mm'); girdi = "$($em.girdi)"; cozucu = [ordered]@{ model = (ModelKod $script:S20_KOR_MODEL); maxTok = $script:S20_KOR_MAXTOK; kaynak = 'yok (kör)'; iz = $script:S20_KOR_IZ.Substring(0, 16) }
      ozet = [ordered]@{ toplam = $sorular.Count; cevaplanan = $cT; dogru = $dT; bozuk = ($sorular.Count - $cT - $butceYok.Count); butce_yetmedi = $butceYok.Count; olculen_oran = $r1.oran; usd = $usd; ders = $ozD }
      sorular = $liste.ToArray()
    }) 8
  Write-Host ("SONUÇ: {0}/{1} doğru (cevaplanan {2}) · {3}" -f $dT, $sorular.Count, $cT, (($ozD.GetEnumerator() | ForEach-Object { "$($_.Key) $($_.Value.dogru)/$($_.Value.toplam)" }) -join ' · '))
  return @{ durum = 'tamam'; usd = $usd; cikti = $cikti }
}

if ($GirdiDosya) {
  Write-Host "DOĞRUDAN GİRDİ — her zaman KURU (para yalnız emir kapısından)."
  [void](& $kosKor ([pscustomobject]@{ no = 0; tavan_usd = 13; girdi = $GirdiDosya }) $false)
  exit 0
}
$kod = S20EmirIsle $EmirDosya ([bool]$Calistir) $kosKor
exit $kod
