#requires -Version 5.1
# ============================================================================
#  SGS (STAJA BAŞLAMA) YENİ KİTAPÇIK NÖBETÇİSİ   13.09.2026  (BEDEL 0)
#
#  NEDEN (Cem 13.09 "çıkmış sınav sorularından yenisi geldi mi otomatik çekiyor muyuz"):
#  Çekmiyorduk. motor/sinav-arsiv-kesif.ps1'i hiçbir robot SGS için çağırmıyor; etiketleme
#  robotunun (sinav-analiz.yml) zamanlaması kapalı. 2026/3 SGS kitapçığı yayımlansa fark etmezdik.
#  Bitirme için aynı nöbetçi arac/smmm-yeni-kitapcik.ps1 olarak kuruldu; bu dosya onun SGS ikizi.
#
#  NE YAPAR: TESMER'de bu yıl ve gelecek yılın SGS kitapçıklarını tarar (yalnız HEAD + ilk 8 bayt
#  %PDF, indirme yok) → veri/sinav-arsiv.json'da OLMAYAN kitapçıkları bulur → daha önce BİLDİRİLMEMİŞ
#  olan varsa Cem'e tek mail (Resend) atar. PARA HARCAMAZ: etiketleme emri vermez, arşive/ambara yazmaz.
#  (Otomatik indirme+yutma bilerek YOK: yutma dokumanlar tablosuna yazar; 13.09 gecesi o tablo
#  tur= taramalarında zaman aşımına düşüyordu. Ambar sağlıklı olunca ayrı adım olarak eklenir.)
#  KÖR KALMAZ: taramadan önce arşivde bilinen bir kitapçık aynı yolla sınanır; o bile "yok" çıkarsa
#  tarama güvenilmez → KÖR raporu + çıkış 1 (Actions kırmızı).
#
#  Çıktı: veri/sgs-yeni-kitapcik.json (RaporYaz) — bildirilen URL'ler burada birikir (tekrar mail yok).
#  ENV: RESEND_KEY + RESEND_FROM (yoksa mail gitmez, raporda "mail: gitmedi" yazar). -MailYok: yerel prova.
# ============================================================================
param([switch]$MailYok)
$ErrorActionPreference = 'Stop'
$depoKok = Split-Path -Parent $PSScriptRoot
. (Join-Path $depoKok 'arac/rapor-yaz.ps1')
$raporYol = Join-Path (Join-Path $depoKok 'veri') 'sgs-yeni-kitapcik.json'
$arsivYol = Join-Path (Join-Path $depoKok 'veri') 'sinav-arsiv.json'
$kesifYol = Join-Path ([IO.Path]::GetTempPath()) ("sgs-kesif-" + [guid]::NewGuid().ToString('N') + '.json')
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

$bilinen = 'https://www2.tesmer.org.tr/files/ortak/soru_cevaplar/sgs/2026/2/lisans_a_grubu/sgs_2026_2_lisans_a_grubu_ingilizce.pdf'
if (-not (BilinenPdfMi $bilinen)) {
  RaporYaz -Hedef $raporYol -Nesne ([ordered]@{ olcum = (Get-Date -Format 'yyyy-MM-dd HH:mm'); durum = 'KOR'; neden = "bilinen kitapçık PDF olarak okunamadı: $bilinen (TESMER erişimi ya da adres düzeni değişti)"; bildirilen = @($bildirilenEski) })
  Write-Host "KÖR: bilinen kitapçık okunamadı — tarama güvenilmez" -ForegroundColor Red
  exit 1
}

# --- 1) tarama (ortak keşif betiği, ayrı çıktı dosyasına) ---
& (Join-Path (Join-Path $depoKok 'motor') 'sinav-arsiv-kesif.ps1') -YalnizSGS -IlkYil $yilBu -SonYil ($yilBu + 1) -CiktiYolu $kesifYol | Out-Null
$kesif = Get-Content $kesifYol -Raw -Encoding UTF8 | ConvertFrom-Json
Remove-Item $kesifYol -ErrorAction SilentlyContinue
$bulunanlar = @($kesif.satirlar | Where-Object { $_ -and "$($_.sinav)" -eq 'SGS' })

# --- 2) arşivle karşılaştır ---
$arsiv = Get-Content $arsivYol -Raw -Encoding UTF8 | ConvertFrom-Json
$arsivUrl = @{}
foreach ($kayit in @($arsiv.donemler)) { if ($kayit -and "$($kayit.sinav)" -eq 'SGS' -and $kayit.url) { $arsivUrl["$($kayit.url)"] = "$($kayit.durum)" } }
$yeniler = @($bulunanlar | Where-Object { -not $arsivUrl.ContainsKey("$($_.url)") } | Sort-Object donem, grup, dil)
$bildirilecek = @($yeniler | Where-Object { $bildirilenEski -notcontains "$($_.url)" })

# --- 3) bildirim (yalnız daha önce bildirilmemiş yeni kitapçık varsa) ---
$mailDurum = 'gerek yok'
if ($bildirilecek.Count) {
  $donemOzet = @($bildirilecek | Group-Object donem | ForEach-Object { "$($_.Name): $($_.Count) kitapçık" })
  $konu = "Tetikte: SGS'de yeni kitapçık — $($donemOzet -join ', ')"
  $satir = @($bildirilecek | ForEach-Object { "<li>$($_.donem) · $($_.grup) · $($_.dil) · <a href=""$($_.url)"">$($_.url)</a></li>" }) -join ''
  $html = "<h3>SGS (Staja Başlama) — arşivde olmayan yeni kitapçık</h3><p>Haftalık nöbetçi TESMER'de arşivimizde (veri/sinav-arsiv.json) olmayan $($bildirilecek.Count) kitapçık buldu. Robot PARA HARCAMADI: arşive almadı, ambara yutmadı, etiketleme emri vermedi.</p><ul>$satir</ul><p>Sonraki adım (Cem onayıyla): arşive al + yut + etiketleme emri. Etiketleme bedeli SGS kitapçığı için bu nöbetçide ölçülmedi; emirden önce ölçülür.</p>"
  $duz = "SGS yeni kitapçık`n" + (@($bildirilecek | ForEach-Object { "$($_.donem) $($_.grup) $($_.dil): $($_.url)" }) -join "`n") + "`n`nRobot para harcamadı. Yutma ve etiketleme Cem onayıyla."
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
    arsivde_olmayan = @($yeniler | ForEach-Object { [ordered]@{ donem = "$($_.donem)"; grup = "$($_.grup)"; dil = "$($_.dil)"; url = "$($_.url)" } })
    bu_tur_bildirilecek = $bildirilecek.Count; mail = $mailDurum
    bildirilen = @($bildirilenYeni)
  })
Write-Host ("SGS yeni kitapçık nöbeti: bulunan {0} · arşivde olmayan {1} · bildirilecek {2} · mail {3}" -f $bulunanlar.Count, $yeniler.Count, $bildirilecek.Count, $mailDurum)
if ($bildirilecek.Count -and $mailDurum -ne 'gönderildi' -and -not $MailYok) { exit 1 }   # yeni kitapçık var ama haber verilemedi → kırmızı (sessiz kalmasın)
