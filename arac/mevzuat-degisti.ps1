# ============================================================================
#  MEVZUAT DEĞİŞTİ — YENİ HAT ENGEL LİSTESİ (ortak işlevler, dot-source)   16.09.2026  (bedel 0)
#
#  Cem 16.09 "SGS sınavı gibi nöbetçi ... herşey var": motor/soru-dayanak-nobetcisi.ps1 yalnız ESKİ kasadaki (soru_havuzu)
#  soruları işaretliyordu. Yeni hat (Kaydır-Çöz; ambar kalip_parti → kilitli kasa paket_soru) hiç izlenmiyordu.
#  Nöbetçi artık damgası değişen/silinen maddeyi KAYNAK olarak kullanmış yeni hat sorusunu bu listeye yazar
#  (veri/sinav/mevzuat-degisti-yeni-hat.json — yalnız kimlik + içerik izi + madde; soru metni YOK) ve kasadan çeker.
#  Yayın şartları (arac/smmm-yayin-sarti.ps1; SGS yayını için arac/sgs-650-bas.ps1 sahibi bağlar) listedeki soruyu geçirmez.
#  İÇERİK İZİ: soru yeniden yazılırsa (yeni kaynakla, bütün kapılardan yeniden geçerek) iz değişir ve engel kendiliğinden kalkar.
#  Aynı soru metni duruyorsa engel sürer — hakem/GM yeniden yargılamadan yayına dönmez.
# ============================================================================
function MdIcerikIzi($v) {
  $sik = @('A', 'B', 'C', 'D', 'E') | ForEach-Object { "$($v.siklar.$_)" }
  $metin = ("$($v.soru)" + '|' + ($sik -join '|') + '|' + "$($v.dogru)".Trim().ToUpperInvariant()) -replace "`r`n", "`n"
  $sha = [Security.Cryptography.SHA256]::Create()
  try { return (($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($metin)) | Select-Object -First 8 | ForEach-Object { $_.ToString('x2') }) -join '') }
  finally { $sha.Dispose() }
}
function MdListeYolu([string]$depoKokYolu) { return (Join-Path (Join-Path (Join-Path $depoKokYolu 'veri') 'sinav') 'mevzuat-degisti-yeni-hat.json') }
function MdListeOku([string]$depoKokYolu) {
  $h = @{}; $y = MdListeYolu $depoKokYolu
  if (Test-Path $y) { foreach ($k in @((Get-Content $y -Raw -Encoding UTF8 | ConvertFrom-Json).kayitlar)) { if ($k) { $h["$($k.anahtar)"] = $k } } }
  return $h
}
# anahtar = "etiket/id"; döner: engel kaydı (madde) ya da $null
function MdEngel($liste, [string]$anahtar, $v) {
  if (-not $liste -or -not $liste.ContainsKey($anahtar)) { return $null }
  $k = $liste[$anahtar]
  if ("$($k.iz)" -ne (MdIcerikIzi $v)) { return $null }   # soru yeniden yazılmış → engel kalkar
  return $k
}
# ----------------------------------------------------------------------------
#  DAMGA DEĞİŞİM TÜRÜ (23.09.2026) — "damga farklı" HER ZAMAN "metin değişti" DEMEK DEĞİL.
#  22.09 olayı (ölçüldü): nöbetçi 12 maddeye "değişti" dedi, 414 soru çekildi; 7 maddede parçaları ters
#  sırayla birleştirince eski damga BİREBİR çıktı. motor/madde-damga.ps1 aynı anahtara düşen parçaları
#  (m.X, m.X/A, mük. m.X) 'sira' ile diziyor; eşit sıralı parçaların dizilişi kayıt kimliğine bağlı ve
#  her yeniden yutmada kayıyor. Ayrıca aynı anahtara YENİ bir kayıt eklenince (ör. mük. m.121 ambara
#  girince m.121'in damgası) mevcut maddenin metni değişmeden damga değişir.
#  Çözüm: damga dosyası her anahtar için PARÇA İZLERİ de tutar ("<ad kökü izi>:<parça metni izi>").
#    ayni    → damga aynı
#    sira    → parça izleri aynı çok-küme, yalnız dizilişi farklı       → DEĞİŞİKLİK DEĞİL
#    ekleme  → eskinin her parçası yenide aynen var + eklenen parçalar ESKİ ad köklerinden DEĞİL
#              (başka bir kayıt: mük./ek/‑A maddesi)                     → mevcut metin DEĞİŞMEDİ
#    degisti → eski bir parça yok ya da eski bir kaydın devam parçası eklenmiş (madde uzamış) ya da iz yok
#    silindi → anahtar yok
#  🚫 BU AYRIM ŞUNU GÖRMEZ: eski taban parça izi taşımıyorsa ölçemez → 'degisti' (eski davranış, temkinli).
#    Eklenen AYRI kaydın kendisi (yeni mük. madde) soru açısından ölçülmez; yalnız mevcut metnin değişmediği söylenir.
#  Öz-sınav: arac/damga-degisim-sinavi.ps1
# ----------------------------------------------------------------------------
function MdAlan($o, [string]$ad) {
  if ($null -eq $o) { return $null }
  if ($o -is [System.Collections.IDictionary]) { return $o[$ad] }
  $p = $o.PSObject.Properties[$ad]; if ($p) { return $p.Value }; return $null
}
# parça adı → ad kökü ("... m.121 - Başlık [2/4]" → "... m.121 - Başlık"; yinelenen ad eki " (2)" de atılır)
function MdAdKoku([string]$ad) { return (("$ad" -replace '\s*\(\d+\)\s*$', '') -replace '\s*\[\d+/\d+\]\s*$', '').Trim() }
function MdDamgaDegisimi($eski, $yeni) {
  if ($null -eq $yeni) { return 'silindi' }
  if ("$(MdAlan $eski 'damga')" -eq "$(MdAlan $yeni 'damga')") { return 'ayni' }
  $ei = @(MdAlan $eski 'parca_izleri' | Where-Object { $_ }); $yi = @(MdAlan $yeni 'parca_izleri' | Where-Object { $_ })
  if (-not $ei.Count -or -not $yi.Count) { return 'degisti' }
  $kalan = New-Object System.Collections.Generic.List[string]; foreach ($x in $yi) { $kalan.Add("$x") }
  foreach ($x in $ei) { if (-not $kalan.Remove("$x")) { return 'degisti' } }
  if (-not $kalan.Count) { return 'sira' }
  $eskiKok = @{}; foreach ($x in $ei) { $eskiKok["$x".Split(':')[0]] = 1 }
  foreach ($x in $kalan) { if ($eskiKok.ContainsKey("$x".Split(':')[0])) { return 'degisti' } }   # aynı kaydın devam parçası = madde uzadı
  return 'ekleme'
}

# ----------------------------------------------------------------------------
#  SORU MADDEYE GERÇEKTEN DEĞİYOR MU? (23.09.2026, Cem "1.2.3 üçünü de yap")
#  ÖLÇÜLDÜ (TTK geç. m.7, AYM iptali): nöbetçi paketinde değişen madde bulunan 93 SMMM sorusunu çekti; elle okumada
#  yalnız 2'si iptal edilen hükme değiyordu (uzun madde pakete MIKNATIS olarak giriyor). Kural: yutucu, madde metni
#  değişince eski/yeni kelime kümesi farkını (AYIRT EDİCİ belirteçler) veri/mevzuat/_degisen-kokler.json'a yazar;
#  nöbetçi, soru + şıklar + açıklamasında bu belirteçlerden HİÇBİRİ geçmeyen soruyu çekmez (kaydına yazar).
#  Belirteç: ≥4 harfli kelimenin ilk 5 harfi + sayılar (%18, 500.000, 7/1) + sayı/süre sözcükleri (on, beş, yıl, ay…).
#  Şerh/dipnot dili (iptal, cümle, yürürlüğe girer, Resmî Gazete…) sayılmaz — 23.09'da yanlış alarmın kaynağıydı.
#  ÖLÇÜLDÜ (tek vaka!): 93 sorudan 14'ü işaretlendi, gerçekten değen 2'nin 2'si yakalandı.
#  🚫 GÖRMEZ: eş anlamlı ifade ("devlete geçer" ↔ "Hazineye intikal"); farkın belirteci yoksa (yalnız söz dizimi değişti)
#     MdAyirtEdici $null döner → nöbetçi HEPSİNİ çeker (temkinli, eski davranış).
#  Öz-sınav: arac/soru-etki-sinavi.ps1
# ----------------------------------------------------------------------------
$script:MD_SERH = @{}; foreach ($w in 'iptal ikinc ucunc cumle karar anaya mahke yurur girer resmi gazet yayim tarih sayil madde fikra degis eklen mulga bendi bentt ibare'.Split(' ')) { $script:MD_SERH[$w] = 1 }
$script:MD_SAYI = @{}; foreach ($w in 'bir iki uc dort bes alti yedi sekiz dokuz on yirmi otuz kirk elli altmis yetmis seksen doksan yuz bin milyon gun ay yil hafta saat yarim ceyrek'.Split(' ')) { $script:MD_SAYI[$w] = 1 }
function MdKatla([string]$s) { return ("$s".Replace([char]0x0130, 'I').Replace([char]0x0131, 'i').ToLowerInvariant() -replace 'ş', 's' -replace 'ğ', 'g' -replace 'ü', 'u' -replace 'ö', 'o' -replace 'ç', 'c') }
function MdBelirtecler([string]$t) {
  $h = @{}; $k = MdKatla $t
  foreach ($m in [regex]::Matches($k, '[a-z]+')) { $w = $m.Value
    if ($script:MD_SAYI.ContainsKey($w)) { $h["~$w"] = 1; continue }
    if ($w.Length -lt 4) { continue }
    $r = $w.Substring(0, [Math]::Min(5, $w.Length)); if (-not $script:MD_SERH.ContainsKey($r)) { $h[$r] = 1 } }
  foreach ($m in [regex]::Matches($k, '%\s*\d+(?:[.,]\d+)?|\d{1,3}(?:\.\d{3})+(?:,\d+)?|\d+(?:[.,/]\d+)*')) { $h['#' + ($m.Value -replace '\s', '')] = 1 }
  return $h
}
# eski/yeni metin → ayırt edici belirteçler; metin aynıysa @() ; fark var ama belirteci yoksa $null (belirsiz)
function MdAyirtEdici([string]$eski, [string]$yeni) {
  if ((($eski -replace '\s+', ' ').Trim()) -eq (($yeni -replace '\s+', ' ').Trim())) { return , @() }
  $be = MdBelirtecler $eski; $by = MdBelirtecler $yeni
  $f = @(@($be.Keys | Where-Object { -not $by.ContainsKey($_) }) + @($by.Keys | Where-Object { -not $be.ContainsKey($_) }))
  if (-not $f.Count) { return $null }
  return , $f
}
# soru nesnesi ($v: soru, siklar, aciklama) ayırt edici belirteçlerden birini taşıyor mu? → eşleşen belirteçler
function MdSoruDegiyor($v, $ayirt) {
  $metin = "$($v.soru) " + ((@('A', 'B', 'C', 'D', 'E') | ForEach-Object { "$($v.siklar.$_)" }) -join ' ') + ' ' + ($v.aciklama | ConvertTo-Json -Compress -Depth 4)
  $b = MdBelirtecler $metin
  # ⚠ virgülsüz: ", @()" boş sonucu tek elemanlı (içi boş dizi) diziye çevirip @().Count = 1 yapıyordu (öz-sınav yakaladı, 23.09)
  return @(@($ayirt) | Where-Object { $b.ContainsKey("$_") })
}
# madde anahtarı: motor/madde-damga.ps1 satır 88-104'ün AYNASI (kanun|seri+madde). Ayrışırsa öz-sınav düşer.
function MdAnahtar([string]$ad) {
  $kn = [regex]::Match($ad, '(?<![\d/])(\d{3,4})\s*(?:s\.|say[ıi]l[ıi])'); if (-not $kn.Success) { $kn = [regex]::Match($ad, '\((\d{3,4})\)') }
  $mn = [regex]::Match($ad, '[^a-zA-Z0-9]m\.\s*(\d{1,4})(?!\d)')
  if (-not ($kn.Success -and $mn.Success)) { return '' }
  $seri = ''; if ($ad -match '(?i)ge[çc]ici\s*m\.?|gec\.\s*m\.') { $seri = 'gec' } elseif ($ad -match '(?i)ek\s+m\.') { $seri = 'ek' }
  return ("{0}|{1}{2}" -f $kn.Groups[1].Value, $seri, $mn.Groups[1].Value)
}

# kaynak adı ("VUK (213 s.K.) m.10 - Kanuni temsilcilerin ödevi [1/2]") → madde kökü ("VUK (213 s.K.) m.10")
function MdMaddeKoku([string]$ad) {
  $m = [regex]::Match("$ad", '^(.*?\bm\.\s*\d+(?:/[A-Z])?)(?=\s|$|\[)')
  if ($m.Success) { return $m.Groups[1].Value.Trim() }
  return ''
}
# 24.09.2026 (Cem "1.2.3"): TEORİ NOTU İZLEME. Nöbetçi yalnız kanun anahtarlarını ('213|370') izliyordu; ambar teori notları
# ('ad|TEORI - …') damgada vardı ama değişince hiçbir soru çekilmiyordu (kollektif notu TBK 623'ün tersini öğretiyordu,
# yayında 7 yanlış soru elle bulundu). Kaynak kökü: kanun maddesi → 'VUK (213 s.K.) m.370'; teori notu → 'TEORI:<ad>'.
function MdKaynakKoku([string]$ad) {
  $mk = MdMaddeKoku $ad; if ($mk) { return $mk }
  $a = MdAdKoku $ad; if ($a -like 'TEORI*') { return "TEORI:$a" }
  return ''
}
function MdIzlenenAnahtar([string]$anahtar) { return ($anahtar -match '^\d+\|' -or $anahtar -match '^ad\|TEORI') }
# _degisen-kokler.json'a eski/yeni metnin ayırt edici belirteçlerini ekler (mevzuat-yut ile aynı biçim; aynı anahtarda önceki
# kayıtla BİRLEŞİR, biri belirsizse belirsiz). Döner: 'ayni' (metin aynı, yazılmadı) | 'belirsiz' | 'yazildi'
function MdDegisenKokEkle([string]$dkYol, [string]$anahtar, [string]$eski, [string]$yeni, [string]$kaynak) {
  $af = MdAyirtEdici $eski $yeni
  if ($null -ne $af -and @($af).Count -eq 0) { return 'ayni' }
  $bel = ($null -eq $af); $dizi = @($af | Where-Object { $_ })
  $dk = [ordered]@{}; if (Test-Path $dkYol) { foreach ($p in (Get-Content $dkYol -Raw -Encoding UTF8 | ConvertFrom-Json).maddeler.PSObject.Properties) { $dk[$p.Name] = $p.Value } }
  if ($dk.Contains($anahtar) -and $dk[$anahtar]) { if ($dk[$anahtar].belirsiz) { $bel = $true }; $dizi = @(@($dizi) + @($dk[$anahtar].belirtecler) | Where-Object { $_ } | Select-Object -Unique) }
  $dk[$anahtar] = [ordered]@{ tarih = (Get-Date -Format 'yyyy-MM-dd HH:mm'); kaynak = $kaynak; belirsiz = $bel; belirtecler = $dizi }
  [IO.File]::WriteAllText($dkYol, (ConvertTo-Json -InputObject ([ordered]@{ aciklama = 'Madde/not metni değişince eski/yeni ayırt edici belirteçler (motor/mevzuat-yut.ps1, arac/teori-notu-duzelt-*.ps1). Nöbetçi, soru bu belirteçlerden hiçbirine değmiyorsa çekmez; belirsiz=true ise hepsini çeker.'; maddeler = $dk }) -Depth 5), (New-Object Text.UTF8Encoding $false))
  return $(if ($bel) { 'belirsiz' } else { 'yazildi' })
}