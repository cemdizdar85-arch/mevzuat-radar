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

# kaynak adı ("VUK (213 s.K.) m.10 - Kanuni temsilcilerin ödevi [1/2]") → madde kökü ("VUK (213 s.K.) m.10")
function MdMaddeKoku([string]$ad) {
  $m = [regex]::Match("$ad", '^(.*?\bm\.\s*\d+(?:/[A-Z])?)(?=\s|$|\[)')
  if ($m.Success) { return $m.Groups[1].Value.Trim() }
  return ''
}
