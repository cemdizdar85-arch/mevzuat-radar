#requires -Version 5.1
<#
================================================================================
  SPK LİSANS SINAVLARI — RESMÎ KONU LİSTESİ HASADI (10.09.2026)

  NE YAPAR: SPL'nin (Sermaye Piyasası Lisanslama Sicil ve Eğitim Kuruluşu)
  yayımladığı 9 lisans sınavının konu ve alt konu başlıklarını çeker,
  `veri/spk-sinav-konulari.json` üretir.

  NEDEN DEĞERLİ — İKİ SEBEP
  -------------------------
  1) KONU KARTI LİSTESİ HAZIR GELİYOR. GVK'da 22 konuyu elle çıkarmak zorunda
     kaldım (kural B18: konu adından kanuna kelime arayarak gidilmez, konu
     OKUNUR ve hangi mevzuatın düzenlediğine KARAR verilir). SPK'da bu emek
     gereksiz: kurum listeyi kendisi yazmış.

  2) MÜFREDAT DAYANAĞI DA SÖYLÜYOR. Alt konu başlıkları tebliğ numarasını
     içeriyor ("Özel Durumlar Tebliği II-15.1", "Yatırım Fonlarına İlişkin
     Esaslar Tebliği III-52.1"). Yani konu → dayanak eşleşmesi tahmin değil,
     KAYIT. Kart katmanının en zayıf halkası burada tahmin işi olmaktan çıkıyor.

  ⚠️ SINIRI: SPL'nin kendi uyarısı — "lisanslama sınav sorularının tamamen bu
  kaynaklardan oluşturulması zorunluluğu bulunmamaktadır." Müfredat sınavın
  SINIRI DEĞİL, kapsamıdır. SPK mevzuatı (ambarda 5.160 belge) yine gerekli.

  ⚠️ SPK'DA ÇIKMIŞ SORU YOK: ölçüldü (10.09) — eski ambarda tur=cikmis-soru
  olan 253 belgenin tamamı SGS/KGK/SMMM. SPL geçmiş sınav sorularını
  yayımlamıyor. Yani SPK için "gerçek sınav kalıbı" ölçümü YAPILAMAZ; kalıp
  çalışma sorularından ve konu ağırlıklarından türetilmek zorunda.

  KULLANIM
    powershell -NoProfile -File arac/spk-sinav-konulari-cek.ps1
================================================================================
#>
param(
  [string]$Adres = 'https://spl.com.tr/sinav-konulari-ve-alt-konu-basliklari/'
)

$ErrorActionPreference = 'Stop'

# TLS: spl.com.tr TLS 1.2'yi REDDEDIYOR (olculdu 10.09 - "SSL/TLS guvenli
# kanali olusturulamadi"). PS 5.1 varsayilani yetmiyor; 1.3 varsa o da acilir.
# Enum'da Tls13 olmayan makinelerde try/catch ile sessizce 1.2'de kalinir.
try   { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]'Tls12,Tls13' }
catch { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 }
$here    = Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok = Split-Path -Parent $here

Write-Host "== SPL sinav konulari cekiliyor ==" -ForegroundColor Cyan
$r = Invoke-WebRequest -Uri $Adres -UseBasicParsing -TimeoutSec 120 `
        -Headers @{ 'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) mevzuat-radar/1.0' }
$html = $r.Content

function Temizle([string]$s) {
  # HTML -> duz metin. Blok etiketleri satir sonuna cevrilir ki alt konu
  # basliklari birbirine YAPISMASIN ("1.1. Sermaye Piyasasi Kanunu1.2. ...").
  $t = $s -replace '(?is)<(script|style).*?</\1>', ''
  $t = $t -replace '(?i)</(p|div|li|tr|h[1-6])>', "`n"
  $t = $t -replace '(?i)<br\s*/?>', "`n"
  $t = $t -replace '(?s)<[^>]+>', ''
  $t = [System.Net.WebUtility]::HtmlDecode($t)
  $t = $t -replace '[ \t]+', ' '
  $t = ($t -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ }) -join "`n"
  return $t.Trim()
}

# Elementor "toggle" bileseni: baslik ve icerik ayri div'lerde, ikisi de
# sunucu tarafinda basiliyor (gizli olmalari JS ile). Yani tarayicisiz cekilir.
$basEs = [regex]::Matches($html, '(?is)<a[^>]*class="[^"]*elementor-toggle-title[^"]*"[^>]*>(.*?)</a>')
$icEs  = [regex]::Matches($html, '(?is)<div[^>]*class="[^"]*elementor-tab-content[^"]*"[^>]*>(.*?)</div>\s*</div>')

if ($basEs.Count -eq 0) {
  throw "SPL sayfa yapisi degismis olabilir: elementor-toggle-title bulunamadi. Once sayfayi elle ac ve yapiyi olc."
}

$sinavlar = New-Object System.Collections.Generic.List[object]
for ($i = 0; $i -lt $basEs.Count; $i++) {
  $ad = Temizle $basEs[$i].Groups[1].Value
  if (-not $ad) { continue }
  $ic = if ($i -lt $icEs.Count) { Temizle $icEs[$i].Groups[1].Value } else { '' }

  # Alt konu satirlarini ayikla: "1.", "1.1.", "1.2.1." ile baslayanlar
  $satirlar = @($ic -split "`n" | Where-Object { $_ -match '^\d+(\.\d+)*\.\s*\S' })
  # ANA KONU = "1." ile baslayip ARDINDAN RAKAM GELMEYEN satir.
  # '^\d+\.\s*\S' deseni "1.1. Sermaye..." satirini da ANA sayiyordu: '\d+\.'
  # bastaki "1." ile eslesip '\s*' hicbir sey tuketmeyince '\S' ikinci "1"i
  # yakaliyordu. Olculdu: dokuz sinavda da ana_konu = alt_konu cikti, yani
  # sayim tamamen anlamsizdi. (?!\d) negatif ileri bakisi bunu kapatir.
  $anaKonu  = @($satirlar | Where-Object { $_ -match '^\d+\.(?!\d)' })

  $sinavlar.Add([pscustomobject][ordered]@{
    sinav        = $ad
    ana_konu     = $anaKonu.Count
    alt_konu     = $satirlar.Count
    karakter     = $ic.Length
    konu_satiri  = $satirlar
  }) | Out-Null
  Write-Host ("  {0,-58} ana {1,2} · alt {2,3}" -f $ad, $anaKonu.Count, $satirlar.Count)
}

if ($sinavlar.Count -eq 0) { throw 'Hic sinav cikmadi - hasat BASARISIZ, dosya YAZILMADI.' }

$cikti = [ordered]@{
  olcum   = (Get-Date -Format 'yyyy-MM-dd HH:mm')
  kaynak  = $Adres
  kurum   = 'SPL - Sermaye Piyasasi Lisanslama Sicil ve Egitim Kurulusu A.S.'
  uyari   = "SPL: lisanslama sinav sorularinin tamamen bu kaynaklardan olusturulmasi zorunlulugu bulunmamaktadir. Mufredat sinavin SINIRI degil, KAPSAMIDIR."
  not_    = "SPK'da cikmis sinav sorusu YOK (10.09 olculdu) - SPL gecmis sorulari yayimlamiyor. Kalip olcumu bu hattan YAPILAMAZ."
  sinav_sayisi = $sinavlar.Count
  sinavlar     = $sinavlar
}

. (Join-Path $here 'rapor-yaz.ps1')
RaporYaz -Hedef (Join-Path $depoKok 'veri\spk-sinav-konulari.json') -Nesne $cikti

$toplamAlt = ($sinavlar | Measure-Object -Property alt_konu -Sum).Sum
Write-Host ""
Write-Host ("TOPLAM: {0} sinav · {1} konu satiri -> veri/spk-sinav-konulari.json" -f $sinavlar.Count, $toplamAlt) -ForegroundColor Green
