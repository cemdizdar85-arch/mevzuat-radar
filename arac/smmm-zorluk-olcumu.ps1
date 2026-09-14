#requires -Version 5.1
# ============================================================================
#  BİTİRME (SMMM) ÇIKMIŞ TEST ZORLUK DAĞILIMI   14.09.2026  (bedel 0, ölçüm)
#
#  NEDEN (Cem 14.09 "1.2.3 üçünü de yap", GM önerisi 3: "toplu basım planında zorluk payını sınava göre ayarlayalım"):
#  Karnedeki "sınav: kolay %42 · zor %52 · çok zor %7" SABİT yazılıydı ve motor/zorluk-kiyas-v2.ps1 ile 26.08'de YALNIZ SGS arşivinden
#  (veri/sgs-arsiv) ölçülmüştü; bitirmeye ait değil. Bu betik AYNI cetveli (zorluk-kiyas-v2 Zorluk: rakam yükü, hesap kökü, uzunluk;
#  çıkmışta tablo/yevmiye yok) bitirme TEST kitapçıklarına (tur=cikmis-soru, "CIKMIS SINAV - SMMM") uygular.
#  Kaynak: ambar sayfaları (KAPI-CB günlük disk önbelleği varsa oradan). Soru bölme: "SORU n:" (KapiCikmisDizin ile aynı).
#  Çıktı: veri/sinav/smmm-zorluk-olcumu.json — plandan-parti-kur (SMMM zorluk payı) ve soru-karnesi (SMMM sınav referansı) okur.
# ============================================================================
$ErrorActionPreference = 'Stop'
$depoKok = Split-Path -Parent $PSScriptRoot
. (Join-Path (Join-Path $depoKok 'motor') 'kapi-cikmis-gun.ps1')
$anahtarAmbar = "$($env:SUPABASE_SERVICE_KEY)".Trim(); if (-not $anahtarAmbar) { $anahtarAmbar = "$([Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'))".Trim() }
$basliklar = @{ apikey = $anahtarAmbar; Authorization = "Bearer $anahtarAmbar"; 'User-Agent' = 'mevzuat-radar-robot/1.0' }
# zorluk-kiyas-v2.ps1 ile BİREBİR aynı cetvel (kopya; biri değişirse öteki de)
$reHesap = [regex]'(?i)ka[cç]t[iı]r|hesapla|tutar[iı] ne|oran[iı] ka[cç]|ka[cç] TL'
$reRakam = [regex]'\d[\d.,]{2,}'
$reOncul = [regex]'(?m)(^|\s)II\.\s.*?(^|\s)III\.\s|hangileri|ka[cç] tanesi'
$reSasirt = [regex]'(?i)yanl[iı][sş]t[iı]r|de[gğ]ildir|s[oö]ylenemez|yer almaz|say[iı]lmaz|olamaz|bulunamaz|yap[iı]lamaz|m[uü]mk[uü]n de[gğ]il'
function ZorlukPuan([string]$soru) {
  $p = 0; $rak = $reRakam.Matches($soru).Count
  if ($rak -ge 6) { $p += 2 } elseif ($rak -ge 2) { $p += 1 }
  if ($reHesap.IsMatch($soru)) { $p += 1 }
  if ($soru.Length -gt 420) { $p += 1 }
  if ($p -ge 4) { return 3 } elseif ($p -ge 2) { return 2 } else { return 1 }
}
$sayfalar = CikmisSayfalariOku 'cikmis-soru' 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar?select=kaynak_ad,metin&tur=eq.cikmis-soru&order=id.asc&limit=40&offset=' $basliklar
$soruBol = [regex]'(?=SORU \d+\s*:)'; $soruBas = [regex]'^SORU (\d+)\s*:'
$say = @{ 1 = 0; 2 = 0; 3 = 0 }; $n = 0; $oncul = 0; $sasirt = 0; $belgeler = New-Object System.Collections.Generic.List[string]; $derse = @{}
foreach ($icerik in $sayfalar) {
  foreach ($st in @((ConvertFrom-Json -InputObject $icerik))) {
    if (-not $st -or "$($st.kaynak_ad)" -notmatch '^CIKMIS SINAV - SMMM') { continue }
    $belgeler.Add("$($st.kaynak_ad)")
    $ders = $(if ("$($st.kaynak_ad)" -match 'smmm_\d{4}_\d_(\d{2})') { $Matches[1] } else { '?' })
    foreach ($parca in $soruBol.Split(("$($st.metin)" -replace '[ \t\r\f]+', ' '))) {
      $m = $soruBas.Match($parca); if (-not $m.Success) { continue }
      $govde = $parca.Substring($m.Length).Trim(); if ($govde.Length -lt 20) { continue }
      $z = ZorlukPuan $govde; $say[$z]++; $n++
      if (-not $derse.ContainsKey($ders)) { $derse[$ders] = @{ 1 = 0; 2 = 0; 3 = 0 } }; $derse[$ders][$z]++
      if ($reOncul.IsMatch($govde)) { $oncul++ }; if ($reSasirt.IsMatch($govde)) { $sasirt++ }
    }
  }
}
if ($n -lt 100) { throw "bitirme test sorusu yalnız $n (beklenen >= 100) — ölçüm yazılmadı" }
$yuzde = { param($x) [math]::Round(100 * $x / $n, 1) }
$dersOzet = [ordered]@{}; foreach ($d in ($derse.Keys | Sort-Object)) { $t = $derse[$d][1] + $derse[$d][2] + $derse[$d][3]; $dersOzet[$d] = [ordered]@{ n = $t; kolay = [math]::Round(100 * $derse[$d][1] / $t, 1); zor = [math]::Round(100 * $derse[$d][2] / $t, 1); cokzor = [math]::Round(100 * $derse[$d][3] / $t, 1) } }
$sonuc = [ordered]@{
  olcum = (Get-Date -Format 'yyyy-MM-dd HH:mm'); yontem = 'zorluk-kiyas-v2 cetveli (tablo/yevmiye yok): rakam ≥6 → +2, ≥2 → +1; hesap kökü +1; >420 kr +1; puan ≥4 çok zor, ≥2 zor, aksi kolay. Gövde şıkları da içerir (SGS 26.08 ölçümüyle aynı biçim).'
  belge = @($belgeler | Select-Object -Unique).Count; soru = $n
  kolay = (& $yuzde $say[1]); zor = (& $yuzde $say[2]); cokzor = (& $yuzde $say[3]); oncullu = (& $yuzde $oncul); sasirtmali = (& $yuzde $sasirt)
  ders_kodu = $dersOzet
  not = 'SGS referansı (26.08, veri/sgs-arsiv): kolay 42 · zor 52 · çok zor 7 — bitirmeye UYGULANMAZ.'
}
$hedef = Join-Path (Join-Path (Join-Path $depoKok 'veri') 'sinav') 'smmm-zorluk-olcumu.json'
. (Join-Path (Join-Path $depoKok 'arac') 'rapor-yaz.ps1')
RaporYaz -Hedef $hedef -Nesne $sonuc
"BİTİRME ÇIKMIŞ TEST ZORLUĞU: $n soru / $($sonuc.belge) belge · kolay %$($sonuc.kolay) · zor %$($sonuc.zor) · çok zor %$($sonuc.cokzor) · öncüllü %$($sonuc.oncullu) · şaşırtmalı %$($sonuc.sasirtmali)"
