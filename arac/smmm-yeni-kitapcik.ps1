#requires -Version 5.1
# ============================================================================
#  BİTİRME (SMMM YETERLİLİK) YENİ KİTAPÇIK NÖBETÇİSİ   13.09.2026  (BEDEL 0)
#
#  NEDEN (Cem 13.09 "eski çıkmış sınav sorularının yenisi çıktı mı kontrolü yapıyor muyuz" → "1 yap"):
#  motor/sinav-arsiv-kesif.ps1 vardı ama hiçbir robot çağırmıyordu (son tam koşu 23.08); etiketleme
#  robotunun (sinav-analiz.yml) zamanlaması kapalı; duyuru nöbetçisi PDF'i arşive almaz. Sonuç: 2026/3
#  kitapçıkları yayımlansa kendiliğimizden fark etmezdik.
#
#  NE YAPAR: TESMER'de bu yıl ve gelecek yılın SMMM kitapçıklarını tarar (yalnız HEAD + ilk 8 bayt
#  %PDF, indirme yok) → veri/sinav-arsiv.json'da OLMAYAN kitapçıkları bulur → daha önce BİLDİRİLMEMİŞ
#  olan varsa Cem'e tek mail (Resend) atar. PARA HARCAMAZ: etiketleme emri vermez, arşive yazmaz.
#  KÖR KALMAZ: taramadan önce arşivde bilinen bir kitapçık (smmm_2026_1_01) aynı yolla sınanır; o bile
#  "yok" çıkarsa tarama güvenilmez → KÖR raporu + çıkış 1 (Actions kırmızı, ci-kirmizi nöbetçisi görür).
#
#  Çıktı: veri/smmm-yeni-kitapcik.json (RaporYaz) — bildirilen URL'ler burada birikir (tekrar mail yok).
#  ENV: RESEND_KEY + RESEND_FROM (yoksa mail gitmez, raporda "mail: gitmedi" yazar). -MailYok: yerel prova.
#  SGS'ye dokunmaz (Cem 13.09: bitirme oturumu SGS'de değişiklik yapmaz).
# ============================================================================
param([switch]$MailYok)
$ErrorActionPreference = 'Stop'
$depoKok = Split-Path -Parent $PSScriptRoot
. (Join-Path $depoKok 'arac/rapor-yaz.ps1')
$raporYol = Join-Path (Join-Path $depoKok 'veri') 'smmm-yeni-kitapcik.json'
$arsivYol = Join-Path (Join-Path $depoKok 'veri') 'sinav-arsiv.json'
$kesifYol = Join-Path ([IO.Path]::GetTempPath()) ("smmm-kesif-" + [guid]::NewGuid().ToString('N') + '.json')
$yilBu = (Get-Date).Year

# --- 0) KÖR testi: bilinen kitapçık gerçekten PDF olarak görünüyor mu ---
$UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
function BilinenPdfMi([string]$adres) {
  try {
    $istek = [System.Net.HttpWebRequest]::Create($adres); $istek.UserAgent = $UA; $istek.Timeout = 30000; $istek.AddRange(0, 7)
    $yanit = $istek.GetResponse(); $akis = $yanit.GetResponseStream(); $tampon = New-Object byte[] 8; $okunan = 0
    while ($okunan -lt 4) { $n = $akis.Read($tampon, $okunan, 8 - $okunan); if ($n -le 0) { break }; $okunan += $n }
    $yanit.Close()
    return ([Text.Encoding]::ASCII.GetString($tampon, 0, 4) -eq '%PDF')
  } catch { return $false }
}
$eskiRapor = $null
if (Test-Path $raporYol) { try { $eskiRapor = Get-Content $raporYol -Raw -Encoding UTF8 | ConvertFrom-Json } catch { $eskiRapor = $null } }
$bildirilenEski = @(); if ($eskiRapor -and $eskiRapor.PSObject.Properties['bildirilen']) { $bildirilenEski = @($eskiRapor.bildirilen | ForEach-Object { "$_" }) }

$bilinen = 'https://www2.tesmer.org.tr/files/ortak/soru_cevaplar/smmm/2026/1/01/smmm_2026_1_01.pdf'
if (-not (BilinenPdfMi $bilinen)) {
  RaporYaz -Hedef $raporYol -Nesne ([ordered]@{ olcum = (Get-Date -Format 'yyyy-MM-dd HH:mm'); durum = 'KOR'; neden = "bilinen kitapçık PDF olarak okunamadı: $bilinen (TESMER erişimi ya da adres düzeni değişti)"; bildirilen = @($bildirilenEski) })
  Write-Host "KÖR: bilinen kitapçık okunamadı — tarama güvenilmez" -ForegroundColor Red
  exit 1
}

# --- 1) tarama (ortak keşif betiği, ayrı çıktı dosyasına) ---
& (Join-Path (Join-Path $depoKok 'motor') 'sinav-arsiv-kesif.ps1') -YalnizSMMM -IlkYil $yilBu -SonYil ($yilBu + 1) -CiktiYolu $kesifYol | Out-Null
$kesif = Get-Content $kesifYol -Raw -Encoding UTF8 | ConvertFrom-Json
Remove-Item $kesifYol -ErrorAction SilentlyContinue
$bulunanlar = @($kesif.satirlar | Where-Object { $_ -and "$($_.sinav)" -eq 'SMMM' })

# --- 2) arşivle karşılaştır ---
$arsiv = Get-Content $arsivYol -Raw -Encoding UTF8 | ConvertFrom-Json
$arsivUrl = @{}
foreach ($kayit in @($arsiv.donemler)) { if ($kayit -and "$($kayit.sinav)" -eq 'SMMM' -and $kayit.url) { $arsivUrl["$($kayit.url)"] = "$($kayit.durum)" } }
$yeniler = @($bulunanlar | Where-Object { -not $arsivUrl.ContainsKey("$($_.url)") } | Sort-Object donem, grup)
$bildirilecek = @($yeniler | Where-Object { $bildirilenEski -notcontains "$($_.url)" })

# --- 3) bildirim (yalnız daha önce bildirilmemiş yeni kitapçık varsa) ---
$mailDurum = 'gerek yok'
if ($bildirilecek.Count) {
  $donemOzet = @($bildirilecek | Group-Object donem | ForEach-Object { "$($_.Name): $($_.Count)/8 ders" })
  $konu = "Tetikte: bitirme (SMMM) sınavında yeni kitapçık — $($donemOzet -join ', ')"
  $satir = @($bildirilecek | ForEach-Object { "<li>$($_.donem) · ders $($_.grup) · <a href=""$($_.url)"">$($_.url)</a></li>" }) -join ''
  $html = "<h3>Bitirme (SMMM Yeterlilik) — arşivde olmayan yeni kitapçık</h3><p>Haftalık nöbetçi TESMER'de arşivimizde (veri/sinav-arsiv.json) olmayan $($bildirilecek.Count) kitapçık buldu. Robot PARA HARCAMADI: arşive almadı, etiketleme emri vermedi.</p><ul>$satir</ul><p>Sonraki adım (Cem onayıyla): arşive al + etiketleme emri. Ölçülen bedel yazılı kitapçıkta ~0,06 USD/kitapçık (emir #13: 280 kitapçık 16,49 USD); test kitapçığı için ölçülmedi.</p>"
  $duz = "Bitirme (SMMM) yeni kitapçık`n" + (@($bildirilecek | ForEach-Object { "$($_.donem) ders $($_.grup): $($_.url)" }) -join "`n") + "`n`nRobot para harcamadı. Etiketleme Cem onayıyla."
  if ($MailYok) { $mailDurum = 'gitmedi (-MailYok prova)' }
  elseif (-not $env:RESEND_KEY -or -not $env:RESEND_FROM) { $mailDurum = 'gitmedi (RESEND_KEY/RESEND_FROM yok)' }
  else {
    try {
      $govde = @{ from = $env:RESEND_FROM; to = @('cemdizdar85@hotmail.com'); subject = $konu; html = $html; text = $duz } | ConvertTo-Json -Depth 3
      Invoke-RestMethod -Method Post -Uri 'https://api.resend.com/emails' -Headers @{ Authorization = ('Bearer ' + ("$env:RESEND_KEY" -replace '[^\x21-\x7e]', '')) } -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -ContentType 'application/json' -TimeoutSec 60 | Out-Null
      $mailDurum = 'gönderildi'
    } catch { $mailDurum = "gitmedi (Resend hatası: $($_.Exception.Message))" }
  }
}
$bildirilenYeni = @($bildirilenEski)
if ($mailDurum -eq 'gönderildi') { $bildirilenYeni = @($bildirilenEski + @($bildirilecek | ForEach-Object { "$($_.url)" }) | Select-Object -Unique) }

RaporYaz -Hedef $raporYol -Nesne ([ordered]@{
    olcum = (Get-Date -Format 'yyyy-MM-dd HH:mm'); durum = 'YESIL'
    taranan_yillar = "$yilBu-$($yilBu + 1)"; denenen = $kesif.denenen; bulunan = $bulunanlar.Count
    arsivde_olmayan = @($yeniler | ForEach-Object { [ordered]@{ donem = "$($_.donem)"; ders = "$($_.grup)"; url = "$($_.url)" } })
    bu_tur_bildirilecek = $bildirilecek.Count; mail = $mailDurum
    bildirilen = @($bildirilenYeni)
  })
Write-Host ("SMMM yeni kitapçık nöbeti: bulunan {0} · arşivde olmayan {1} · bildirilecek {2} · mail {3}" -f $bulunanlar.Count, $yeniler.Count, $bildirilecek.Count, $mailDurum)
if ($bildirilecek.Count -and $mailDurum -ne 'gönderildi' -and -not $MailYok) { exit 1 }   # yeni kitapçık var ama haber verilemedi → kırmızı (sessiz kalmasın)
