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
# kaynak adı ("VUK (213 s.K.) m.10 - Kanuni temsilcilerin ödevi [1/2]") → madde kökü ("VUK (213 s.K.) m.10")
function MdMaddeKoku([string]$ad) {
  $m = [regex]::Match("$ad", '^(.*?\bm\.\s*\d+(?:/[A-Z])?)(?=\s|$|\[)')
  if ($m.Success) { return $m.Groups[1].Value.Trim() }
  return ''
}
