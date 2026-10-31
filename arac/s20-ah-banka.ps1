#requires -Version 5.1
# ============================================================================
#  SGS SON 20 GÜN — AÇIKLAMA HAKEMİ, BANKA ADAYLARI (24.10.2026, Cem onayı: tavan 8 USD; ≈0,017 USD/soru ölçülmüş)   PARALI, hep TOPLU
#
#  NE: bankadaki (yayındaki) aday soruların çözüm anlatımını ÜRETİMDEKİ açıklama hakemine okutur; karar SONUÇ dosyasına (yalnız harf) + ambara (gerekçeli) yazılır
#  (kalip-parti kayıtlarına / ambara YAZILMAZ).
#  HAKEM: arac/aciklama-hakemi-cekirdek.ps1 AciklamaHakemIs (istem) + AciklamaHakemKarar (ayrıştırıcı) AYNEN çağrılır. Model, effort,
#    jeton tavanı ve önbelleksiz toplu bayrağı arac/aciklama-hakemi-uretim.ps1 AciklamaHakemUretim gövdesinden AST ile okunur (kopya yok).
#  SORU VERİSİ: üretimdeki hakemin gördüğü biçim = kalip-parti kaydı (bulutta veri/fabrika/kalip-parti-<etiket>.json ambardan iner).
#    Ambar kalip_parti tablosundan YALNIZ istenen kayıtlar çekilir: etiket başına select=icerik->"kp-01",… (tam parti inmez; çıkış ücretli).
#    Kimlik: paket_soru id'si "<etiket>/<kp>" (ör. sgs-k4-turkce-kolay/kp-01).
#  KAPI: veri/sinav/s20-ah-banka-emir.json → {emirler:[{no, onay, tavan_usd, girdi, uygulandi}]}; onay:true + damgasız + -Calistir → PARALI,
#    aksi KURU (soru sayısı + tahmini USD; ambardan yalnız istenen kayıtlar okunur, model çağrısı yok, 0 USD).
#  GİRDİ: [{soru_id, oncelik}] — dosya SIRASI öncelik sırasıdır (sıra korunur; oncelik alanı yalnız rapora yazılır).
#  BEDEL: tahmin = girdi karakter/1,6 + çıktı 900 jeton (ölçüldü 02.10 B dalgası: 292 çağrı, maxTok 3.200 → çıktı 875/çağrı). Önceliğe göre
#    gönderilir; tahmini bedel tavana erişince DURULUR, kalanlar "bütçe yetmedi". Kayıtta zaten aciklama_hakem kararı varsa yeniden
#    gönderilmez (karar 'onceki' olarak taşınır, 0 USD). Bedel bedel_kaydi'na etiket "sgs-s20-ah-banka/<no>".
#  ÇIKTI: depo veri/sinav/s20-ah-banka-karar-<no>.json → {sayim:{…}, kararlar:{soru_id: "TEMIZ"|"KUSURLU"|"KARARSIZ"}} — GEREKÇE YOK (depo public).
#         ambar kalip_parti '__s20/ah-banka-karar-<no>' (sinav SISTEM) → kararlar + kusurlar + ölçülemedi/bütçe yetmedi/bulunamadı listeleri;
#         yazılır, GERİ OKUNUP doğrulanır (S20AmbarSistemYaz). KARARSIZ = ölçülemedi · bütçe yetmedi · ambarda bulunamadı (sayımda ayrı).
#  Kullanım:
#    powershell -NoProfile -File arac/s20-ah-banka.ps1                          (emir dosyası, KURU)
#    powershell -NoProfile -File arac/s20-ah-banka.ps1 -Calistir                (yalnız onaylı emir PARALI — bulut iş akışı)
#    powershell -NoProfile -File arac/s20-ah-banka.ps1 -GirdiDosya x.json       (doğrudan girdi, HER ZAMAN KURU)
#  🚫 GÖRMEZ: paket_soru'daki sitede duran metnin kalip-parti kaydından SONRA elle değiştirilmiş olması (hakem kaydı okur, üretimdeki gibi)
#    · hakemin kendi hatası (etiketli ölçüm 30.09: kusurlu 25'in 5'ini kaçırdı) · kararın öğrenciye görünen siteye yansıması (bu iş yazmaz).
# ============================================================================
param([string]$EmirDosya = 'veri/sinav/s20-ah-banka-emir.json', [string]$GirdiDosya = '', [switch]$Calistir,
  [int]$IlkDalga = 30, [int]$BeklemeDk = 290, [int]$CiktiTahminJ = 900)
$ErrorActionPreference = 'Stop'
$depoKok = Split-Path -Parent $PSScriptRoot
Set-Location $depoKok
. (Join-Path $depoKok 'motor\api-hedef.ps1')
. (Join-Path $depoKok 'motor\model-kod.ps1')
. (Join-Path $PSScriptRoot 's20-ortak.ps1')
. (Join-Path $PSScriptRoot 'aciklama-hakemi-cekirdek.ps1')

$AH = S20AhUretimAyari (Join-Path $PSScriptRoot 'aciklama-hakemi-uretim.ps1')
Write-Host ("AÇIKLAMA HAKEMİ (üretimden): model {0} · effort {1} · maxTok {2} · önbelleksiz toplu {3}" -f $AH.model, $AH.effort, $AH.maxTok, $AH.onbelleksiz)

$kosAh = {
  param($em, [bool]$odeme)
  $no = [int]$em.no; $tavanD = [double]$em.tavan_usd; $etiketA = "sgs-s20-ah-banka/$no"
  if (-not (Test-Path "$($em.girdi)")) { throw "girdi dosyası yok: $($em.girdi) (Cem koyacak)" }
  $aday = @((S20Json "$($em.girdi)") | ForEach-Object { $_ })
  $sira = New-Object System.Collections.Generic.List[string]; $gor = @{}; $oncB = $null; $monoton = $true
  foreach ($a in $aday) { $sid = "$($a.soru_id)".Trim(); if (-not $sid -or $gor.ContainsKey($sid)) { continue }; $gor[$sid] = 1; $sira.Add($sid)
    if ($null -ne $a.oncelik -and "$($a.oncelik)" -match '^-?\d+([.,]\d+)?$') { $ov = [double]("$($a.oncelik)" -replace ',', '.'); if ($null -ne $oncB -and $ov -lt $oncB) { $monoton = $false }; $oncB = $ov } }
  Write-Host ("ADAY: {0} soru (dosya sırası = öncelik{1})" -f $sira.Count, $(if ($monoton) { '' } else { '; ⚠ oncelik alanı artan değil — DOSYA SIRASI esas alındı' }))
  $kayit = S20AmbarKayit $sira.ToArray()
  $bulunamadi = @($sira | Where-Object { -not $kayit.ContainsKey($_) })
  $onceki = [ordered]@{}; $isler = New-Object System.Collections.Generic.List[object]; $harita = @{}
  foreach ($sid in $sira) {
    if (-not $kayit.ContainsKey($sid)) { continue }; $k = $kayit[$sid]
    if (-not $k.soru) { $bulunamadi += $sid; continue }
    if ($k.PSObject.Properties['aciklama_hakem'] -and $k.aciklama_hakem -and "$($k.aciklama_hakem.karar)" -in @('TEMIZ', 'KUSURLU')) { $onceki[$sid] = $k.aciklama_hakem; continue }
    $iid = S20AhId $sid; if ($iid -notmatch '^[A-Za-z0-9_-]{1,64}$') { throw "custom_id kuralına uymayan soru kimliği: $sid" }
    $harita[$iid] = $sid; $isler.Add((AciklamaHakemIs $iid $k $AH.model $AH.effort $AH.maxTok))
  }
  $tt = S20Tahmin $isler.ToArray() $CiktiTahminJ
  $ids = @($isler | ForEach-Object { $_.id })
  $tTop = S20Topla $tt.tahmin $ids; $kTop = S20Topla $tt.enKotu $ids
  $sigan = 0; $c = 0.0; foreach ($x in $ids) { $c += [double]$tt.tahmin[$x]; if ($c -le $tavanD) { $sigan++ } else { break } }
  Write-Host ("GÖNDERİLECEK: {0} soru · önceki kararlı {1} (0 USD) · bulunamadı {2}" -f $isler.Count, $onceki.Count, $bulunamadi.Count)
  Write-Host ("TAHMİN: {0:N3} USD (soru başı ≈{1:N4}; çıktı {2} jeton varsayımı) · EN KÖTÜ DURUM {3:N3} USD · tavan {4} USD → tahminle tavana sığan {5}/{6}" -f $tTop, $(if ($ids.Count) { $tTop / $ids.Count } else { 0 }), $CiktiTahminJ, $kTop, $tavanD, $sigan, $ids.Count)
  if (-not $odeme) { Write-Host "KURU: istek gönderilmedi (0 USD)."; return @{ durum = 'kuru' } }

  $oncH = 0.0; if ($em.PSObject.Properties['harcanan_usd']) { $oncH = [double]$em.harcanan_usd }
  $r = S20DalgaKos -Isler $isler.ToArray() -Tahmin $tt.tahmin -EnKotu $tt.enKotu -Tavan $tavanD -Etiket $etiketA -IlkDalga $IlkDalga -Onbelleksiz $AH.onbelleksiz -BeklemeDk $BeklemeDk -OncekiHarcama $oncH
  if ($isler.Count -and -not $r.gonderilen) { throw 'HİÇBİR İSTEK GÖNDERİLMEDİ (tavan ilk dalganın en kötü durumunu karşılamıyor) — emir damgalanmaz' }
  if ($r.zaman_asimi) { $u = S20BedelYaz $etiketA 'aciklama-hakemi' 's20-ah-banka'; return @{ durum = 'bekliyor'; usd = $u } }
  $kararlar = [ordered]@{}; $olcul = New-Object System.Collections.Generic.List[string]; $say = [ordered]@{ aday = $sira.Count; gonderilen = $r.gonderilen; temiz = 0; kusurlu = 0; olculemedi = 0; onceki = $onceki.Count; butce_yetmedi = @($r.butce_yok).Count; bulunamadi = $bulunamadi.Count; usd = 0 }
  foreach ($iid in $ids) {
    $sid = $harita[$iid]
    if (-not $r.sonuc.ContainsKey($iid)) { if (-not $r.butce_yok.Contains($iid)) { $olcul.Add($sid); $say.olculemedi++ }; continue }
    $kr = AciklamaHakemKarar $r.sonuc[$iid]
    if ($kr.karar -eq 'OLCULEMEDI') { $olcul.Add($sid); $say.olculemedi++; continue }
    if ($kr.karar -eq 'TEMIZ') { $say.temiz++; $kararlar[$sid] = [ordered]@{ karar = 'TEMIZ' } } else { $say.kusurlu++; $kararlar[$sid] = [ordered]@{ karar = 'KUSURLU'; kusurlar = @($kr.kusurlar) } }
  }
  foreach ($sid in $onceki.Keys) { $o = $onceki[$sid]; $kararlar[$sid] = $(if ("$($o.karar)" -eq 'KUSURLU') { [ordered]@{ karar = 'KUSURLU'; kusurlar = @($o.kusurlar); onceki = $true } } else { [ordered]@{ karar = 'TEMIZ'; onceki = $true } }) }
  $say.usd = S20BedelYaz $etiketA 'aciklama-hakemi' 's20-ah-banka'
  # 24.10 GİZLİLİK (Cem/koordinatör): kusur gerekçeleri soru içeriğine değinebilir, depo PUBLIC → gerekçeler YALNIZ AMBARA
  #   (kalip_parti satırı '__s20/ah-banka-karar-<no>', sinav SISTEM, sayımlara girmez; geri okunup doğrulanır). Depoya yalnız
  #   {soru_id: TEMIZ|KUSURLU|KARARSIZ} + sayım. Ambara yazım tutmazsa depoya da yazılmaz, emir damgalanmaz (yeniden koşu bedava hasat eder).
  $tarihA = (Get-Date -Format 'yyyy-MM-dd HH:mm'); $hakemA = [ordered]@{ model = (ModelKod $AH.model); effort = $AH.effort; maxTok = $AH.maxTok }
  $butceSid = @($r.butce_yok | ForEach-Object { $harita[$_] })
  $ambarEt = "__s20/ah-banka-karar-$no"
  [void](S20AmbarSistemYaz $ambarEt 's20-ah-banka' ([ordered]@{
        aciklama = 'S20 açıklama hakemi banka kararları + kusur gerekçeleri (arac/s20-ah-banka.ps1). Depodaki karar dosyasında gerekçe YOKTUR.'
        no = $no; tarih = $tarihA; girdi = "$($em.girdi)"; hakem = $hakemA; sayim = $say; olculen_oran = $r.oran
        kararlar = $kararlar; olculemedi = $olcul.ToArray(); butce_yetmedi = $butceSid; bulunamadi = @($bulunamadi) }))
  $kisa = [ordered]@{}
  foreach ($sid in $sira) { $kisa[$sid] = $(if ($kararlar.Contains($sid)) { "$($kararlar[$sid].karar)" } else { 'KARARSIZ' }) }
  $cikti = "veri/sinav/s20-ah-banka-karar-$no.json"
  S20JsonYaz $cikti ([ordered]@{
      no = $no; tarih = $tarihA; girdi = "$($em.girdi)"; hakem = $hakemA; sayim = $say; olculen_oran = $r.oran
      gerekce = "ambarda: kalip_parti etiket '$ambarEt' (depoya girmez)"; kararlar = $kisa
    }) 6
  Write-Host ("SONUÇ: temiz {0} · kusurlu {1} · ölçülemedi {2} · önceki {3} · bütçe yetmedi {4} · bulunamadı {5} · {6} USD" -f $say.temiz, $say.kusurlu, $say.olculemedi, $say.onceki, $say.butce_yetmedi, $say.bulunamadi, $say.usd)
  return @{ durum = 'tamam'; usd = $say.usd; cikti = $cikti }
}

if ($GirdiDosya) {
  Write-Host "DOĞRUDAN GİRDİ — her zaman KURU (para yalnız emir kapısından)."
  [void](& $kosAh ([pscustomobject]@{ no = 0; tavan_usd = 8; girdi = $GirdiDosya }) $false)
  exit 0
}
$kod = S20EmirIsle $EmirDosya ([bool]$Calistir) $kosAh
exit $kod
