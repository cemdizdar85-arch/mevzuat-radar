#requires -Version 5.1
# ============================================================================
#  BİTİRME (SMMM) KAYNAK İLGİ HAKEMİ — "pakete gelen kaynak bu konuyu gerçekten anlatıyor mu?"   16.09.2026  (PARALI, hep TOPLU)
#
#  NEDEN (Cem 16.09 "1.2.3 üçünü de yap"): kelime eşleşmesiyle ilgi ölçütü 26 elle doğrulanmış konuda en iyi 7 hata yaptı (%73):
#  kanun maddesi konunun kelimesiyle başlamıyor ("sermaye piyasası suçları" ← SPKn m.106-110 İLGİSİZ sayıldı), genel kelime yanlış
#  notu içeri alıyor ("ticari iş tanımı" ← ticari mal kaydı notu GÜÇLÜ). "Tek yanlış soru olmayacak" hedefi için model hakemi gerekir.
#
#  YOL: arac/smmm-kaynak-olcum.ps1 -PaketDok ile diske dökülmüş paketler okunur (ambar çağrısı yok). Her konu için paketin blokları
#  (kaynak adı + ilk 700 kr) modele verilir; model her bloğun konuyla İLGİLİ olup olmadığını ve paketle soru yazılıp yazılamayacağını söyler.
#  İlgili blokların TAM boyu toplanır: >=1000 GÜÇLÜ · 300-999 ZAYIF · paket dolu ama ilgili <300 İLGİSİZ · paket <300 KAYNAK YOK
#  (üreticinin kendi eşikleri). Model yargısı 'soru_yazilabilir=false' ise durum en çok ZAYIF olur.
#
#  BEDEL: hep toplu (Message Batches, %50). Ölçülen: konu başı ~2.100 giriş + ~80 çıkış jetonu → Sonnet 5 toplu ≈0,0025 USD/konu.
#  Bedel veri/fabrika/bedel-kayit.jsonl'a yazılır (koşucunun ay toplamı bunu görür). -Kuru: istek GÖNDERİLMEZ, yalnız sayar.
#  Kullanım:
#     powershell -NoProfile -File arac/smmm-ilgi-hakemi.ps1 -Liste <csv ders,konu[,ilgili]> -PaketDok <klasör> -Cikti <json> [-Kuru]
#  -Liste 'ilgili' sütunu taşıyorsa (0/1) KALİBRASYON raporu da basılır (doğruluk, yanlış GÜÇLÜ, kaçan).
# ============================================================================
param([Parameter(Mandatory = $true)][string]$Liste, [Parameter(Mandatory = $true)][string]$PaketDok, [Parameter(Mandatory = $true)][string]$Cikti,
  [string]$Model = 'claude-sonnet-5', [string]$Etiket = '', [int]$BlokKr = 700, [string]$HasatBid = '', [switch]$YalnizHasat, [switch]$Kuru)   # HasatBid: virgüllü toplu parti kimlikleri — bitmiş cevaplar BEDAVA toplanır, yalnız eksik istekler gönderilir
$ErrorActionPreference = 'Stop'
$depoKok = Split-Path -Parent $PSScriptRoot
. (Join-Path $depoKok 'motor\api-hedef.ps1')
if (-not $env:MEVZUAT_TOPLU_BEKLE_DK) { $env:MEVZUAT_TOPLU_BEKLE_DK = '1440' }   # Cem "hep toplu, ucuza bekle"
if (-not $Etiket) { $Etiket = "smmm-ilgi-hakemi-$(Get-Date -Format yyyyMMdd-HHmm)" }

function PaketAd([string]$ders, [string]$konu) { ((($ders.Substring(0, [math]::Min(12, $ders.Length))) + '__' + $konu) -replace '[^\w\-]', '_') + '.txt' }

$satirlar = @(Import-Csv $Liste -Encoding UTF8)
$isler = New-Object System.Collections.Generic.List[object]
$kayit = [ordered]@{}
$sira = 0
foreach ($s in $satirlar) {
  $sira++
  $yol = Join-Path $PaketDok (PaketAd "$($s.ders)" "$($s.konu)")
  $paket = $(if (Test-Path $yol) { [IO.File]::ReadAllText($yol, [Text.Encoding]::UTF8) } else { $null })
  $id = "k$sira"
  $bloklar = @(if ($paket) { @($paket -split "`n---`n") | Where-Object { $_ } })
  $kayit[$id] = [ordered]@{ ders = "$($s.ders)"; konu = "$($s.konu)"; paketBoy = $(if ($paket) { $paket.Length } else { -1 }); blokSayi = $bloklar.Count; bloklar = $bloklar
    etiket = $(if ($s.PSObject.Properties['ilgili']) { "$($s.ilgili)" } else { '' }) }
  if (-not $paket -or $paket.Length -lt 300) { continue }   # paket yok ya da KAYNAK YOK: modele gitmez
  $sb = New-Object Text.StringBuilder
  for ($i = 0; $i -lt $bloklar.Count; $i++) {
    $b = $bloklar[$i]; $ad = $(if ($b -match '^\[([^\]]+)\]') { $matches[1] } else { '(adsız)' })
    $govde = ($b -replace '^\[[^\]]+\]\s*', '' -replace '\s+', ' ')
    [void]$sb.AppendLine("[$($i + 1)] KAYNAK: $ad")
    [void]$sb.AppendLine("METİN (ilk $BlokKr kr): $($govde.Substring(0, [math]::Min($BlokKr, $govde.Length)))")
    [void]$sb.AppendLine()
  }
  $istem = @"
Sen SMMM Yeterlilik (bitirme) sınavı için soru yazılacak kaynak paketini denetleyen bir hakemsin.
DERS: $($s.ders)
KONU: $($s.konu)

Aşağıda pakete giren kaynak parçaları numaralı. Her parça için karar ver: bu parça, bu KONU hakkında sınav sorusu yazmak için gereken kuralı, tanımı, hesap yöntemini ya da muhasebe kaydını DOĞRUDAN içeriyor mu?
- Yalnız aynı kanundan ya da aynı dersten olması YETMEZ; parçanın kendisi konuyu anlatmalı.
- Konunun adıyla ortak kelime taşıyıp başka bir şeyi anlatan parça İLGİSİZDİR.
- Emin değilsen ilgisiz say.
Sonra paketin bütününe bak: ilgili parçalarla bu konuda doğru, cevabı kaynağa dayanan bir soru yazılabilir mi?

YALNIZ şu JSON'u döndür, başka hiçbir şey yazma:
{"ilgili":[ilgili parça numaraları],"soru_yazilabilir":true/false,"gerekce":"en çok 20 kelime"}

$($sb.ToString())
"@
  $istem = $istem -replace "`r`n", "`n"   # 16.09: satır sonu dosyanın çekiliş biçimine bağlıydı (yerel LF / bulut CRLF) → parmak izi tutmuyordu; tek biçim
  # 16.09 kalibrasyon: maxTok 400'de Sonnet 5 düşünmeyi bitirip metin yazamadı (1/23) → 1500; ücret yalnız kullanılan jeton
  $isler.Add(@{ id = $id; model = $Model; maxTok = 1500; icerik = @(@{ type = 'text'; text = $istem }) })
}
"İLGİ HAKEMİ: $($satirlar.Count) konu · modele gidecek $($isler.Count) · paketi olmayan $(@($kayit.Values | Where-Object { $_.paketBoy -lt 0 }).Count) · model $Model · etiket $Etiket"
if ($Kuru) {
  $kar = 0; foreach ($i in $isler) { $kar += "$($i.icerik[0].text)".Length }
  foreach ($i in $isler) { "PARMAK $($i.id) $(Get-IcerikParmak $i.icerik)" }   # buluta taşımada kuyruktaki partiye bağlanma kontrolü (yalnız özet değeri; içerik değil)
  "KURU: istek gönderilmedi. Toplam istem $kar kr (~$([math]::Round($kar / 3.2)) jeton) · tahmini toplu bedel ≈ $([math]::Round((($kar / 3.2) * 2 + $isler.Count * 80 * 10) / 1e6 / 2, 3)) USD (Sonnet 5)"
  exit 0
}
$sonuc = @{}
# 16.09 HASAT: iptal/yeniden başlatma sonrası bitmiş partinin cevapları kimlikle toplanır (bedel defterine bir kez yazılır), kalan istekler gönderilir
if ($HasatBid) {
  $hedefH = Get-TopluBasliklar
  foreach ($hb in @($HasatBid -split '[,\s]+' | Where-Object { $_ })) {
    $hs = Get-ClaudeTopluSonuc $hb $hedefH $Etiket
    if ($null -eq $hs) { "HASAT: $hb henüz bitmemiş — atlandı"; continue }
    $al = 0; foreach ($hk in @($hs.Keys)) { if ($hk -notlike '__*' -and ($isler | Where-Object { $_.id -eq $hk })) { $sonuc[$hk] = $hs[$hk]; $al++ } }
    "HASAT: $hb → $al cevap alındı"
  }
}
$kalanIs = @($isler | Where-Object { -not $sonuc.ContainsKey($_.id) })
"GÖNDERİLECEK: $($kalanIs.Count) istek (hasat edilen $($sonuc.Count))"
if ($kalanIs.Count -and $YalnizHasat) { "YALNIZ HASAT: $($kalanIs.Count) istek GÖNDERİLMEDİ (ölçülemedi sayılır)" }
elseif ($kalanIs.Count) { $yeniS = Invoke-ClaudeToplu -Isler $kalanIs -Etiket $Etiket -BeklemeDk ([int]$env:MEVZUAT_TOPLU_BEKLE_DK) -OnbelleksizToplu; foreach ($yk in @($yeniS.Keys)) { $sonuc[$yk] = $yeniS[$yk] } }
if ($sonuc.ContainsKey('__zaman_asimi')) { throw "TOPLU ZAMAN AŞIMI: $($sonuc['__zaman_asimi']) — sonuçlar bekleyen-partiler.json'da; aynı komutla yeniden koşunca bedava hasat edilir. Çıktı YAZILMADI." }

$cikis = New-Object System.Collections.Generic.List[object]
$bozuk = 0
foreach ($id in $kayit.Keys) {
  $k = $kayit[$id]
  $ilgiliNo = @(); $yazilabilir = $null; $gerekce = ''; $hakemDurum = ''
  if ($k.paketBoy -lt 0) { $hakemDurum = 'PAKET YOK' }
  elseif ($k.paketBoy -lt 300) { $hakemDurum = 'KAYNAK YOK' }
  elseif (-not $sonuc.ContainsKey($id)) { $hakemDurum = 'OLCULEMEDI'; $bozuk++ }
  else {
    $m = [regex]::Match("$($sonuc[$id].metin)", '(?s)\{.*\}')
    # 16.09 kalibrasyon (k7): düşünme jeton tavanını bitirip metin yazmadan kesilen cevap İLGİSİZ sayılıyordu → ÖLÇÜLEMEDİ
    if (-not $m.Success -or "$($sonuc[$id].dur)" -eq 'max_tokens') { $hakemDurum = 'OLCULEMEDI'; $bozuk++ }
    else {
      try { $j = ConvertFrom-Json -InputObject $m.Value; $ilgiliNo = @($j.ilgili | ForEach-Object { [int]$_ }); $yazilabilir = [bool]$j.soru_yazilabilir; $gerekce = "$($j.gerekce)" }
      catch { $hakemDurum = 'OLCULEMEDI'; $bozuk++ }
    }
  }
  $ilgiliBoy = 0; $ilgiliAd = @()
  foreach ($n in $ilgiliNo) { if ($n -ge 1 -and $n -le $k.bloklar.Count) { $b = $k.bloklar[$n - 1]; $ilgiliBoy += $b.Length; if ($b -match '^\[([^\]]+)\]') { $ilgiliAd += $matches[1] } } }
  if (-not $hakemDurum) {
    $hakemDurum = $(if ($ilgiliBoy -ge 1000) { 'GUCLU' } elseif ($ilgiliBoy -ge 300) { 'ZAYIF' } else { 'ILGISIZ' })
    if ($hakemDurum -eq 'GUCLU' -and $yazilabilir -eq $false) { $hakemDurum = 'ZAYIF' }
  }
  $cikis.Add([pscustomobject][ordered]@{ ders = $k.ders; konu = $k.konu; durum = $hakemDurum; paketBoy = $k.paketBoy; ilgiliBoy = $ilgiliBoy; ilgiliBlok = $ilgiliNo.Count; blokSayi = $k.blokSayi
      soruYazilabilir = $yazilabilir; gerekce = $gerekce; ilgiliKaynakAd = (@($ilgiliAd | Select-Object -First 5) -join ' ; '); etiket = $k.etiket })
}

# --- bedel defteri (koşucunun ay toplamı görsün) ---
$bz = Get-BedelOzet
if ($bz.toplamUsd -gt 0) {
  $bedelYol = Join-Path $depoKok 'veri\fabrika\bedel-kayit.jsonl'
  $bedelSatir = ((ConvertTo-Json -InputObject ([ordered]@{ zaman = (Get-Date -Format 'yyyy-MM-dd HH:mm'); etiket = $Etiket; ders = 'SMMM ilgi hakemi'; toplamUsd = $bz.toplamUsd; varsayim = $bz.fiyatVarsayim; satirlar = $bz.satirlar }) -Compress -Depth 4) + "`n")
  $bmx = New-Object System.Threading.Mutex($false, 'Global\tetikte-bedel-kayit'); $bal = $false
  try { $bal = $bmx.WaitOne(20000) } catch { $bal = $true }
  try { [IO.File]::AppendAllText($bedelYol, $bedelSatir, [Text.UTF8Encoding]::new($false)) }
  finally { if ($bal) { try { $bmx.ReleaseMutex() } catch {} }; $bmx.Dispose() }
}

$dizi = $cikis.ToArray()
[IO.File]::WriteAllText($Cikti, (ConvertTo-Json -InputObject ([ordered]@{ olcum = (Get-Date -Format 'yyyy-MM-dd HH:mm'); model = $Model; etiket = $Etiket; konu = $dizi.Count; bedelUsd = $bz.toplamUsd; olculemeyen = $bozuk; konular = $dizi }) -Depth 5), [Text.UTF8Encoding]::new($false))
"SONUÇ: $(($dizi | Group-Object durum | ForEach-Object { "$($_.Name)=$($_.Count)" }) -join ' · ') · ölçülemeyen $bozuk · bedel ≈ $($bz.toplamUsd) USD · $Cikti"

# --- kalibrasyon ---
$etk = @($dizi | Where-Object { $_.etiket -match '^[01]$' })
if ($etk.Count) {
  $hata = @(foreach ($x in $etk) { $tahmin = $(if ($x.durum -eq 'GUCLU') { 1 } else { 0 }); if ($tahmin -ne [int]$x.etiket) { [pscustomobject]@{ konu = $x.konu; beklenen = $x.etiket; durum = $x.durum; ilgiliBoy = $x.ilgiliBoy; gerekce = $x.gerekce } } })
  "KALİBRASYON: $($etk.Count) etiketli · doğru $($etk.Count - $hata.Count) (%$([math]::Round(100 * ($etk.Count - $hata.Count) / $etk.Count))) · yanlış GÜÇLÜ $(@($hata | Where-Object { $_.beklenen -eq '0' }).Count) · kaçan $(@($hata | Where-Object { $_.beklenen -eq '1' }).Count)"
  foreach ($h in $hata) { "  HATA $($h.konu): beklenen $(if ($h.beklenen -eq '1') { 'İLGİLİ' } else { 'İLGİSİZ' }) · hakem $($h.durum) ($($h.ilgiliBoy) kr) · $($h.gerekce)" }
}
