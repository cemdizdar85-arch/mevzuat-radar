# ============================================================================
#  ÜYE ALARMI — saatlik yeni üye sayımı, sahte hesap dalgasına erken uyarı
#
#  NEDEN (23.09.2026, Cem "1 yap"): 23.09'da e-posta onayı kapatıldı; sahte
#  hesap açmak kolaylaştı ve bot koruması (captcha) 4 Ekim sonrasına kaldı.
#  Bu alarm olmadan bin sahte hesap açılsa haftalar sonra görürdük.
#
#  NASIL: Supabase'de public.uye_sayim() fonksiyonu (radar-app/sql/
#  2026-09-23-uye-sayim.sql) YALNIZ SAYI döndürür — e-posta/ad/kimlik
#  dönmez. Kişi verisi Actions'a GİRMEZ (depo public, CLAUDE.md bulut m.4).
#
#  SEVİYELER (ölçülen: son 1 saat · son 24 saat · son 1 saatin en yoğun dakikası)
#    KIRMIZI : en yoğun dakika >= 30  (insan bu hızda kaydolmaz, bot olur)
#              ya da son 1 saat >= 300
#    SARI    : en yoğun dakika >= 15, son 1 saat >= 100, son 24 saat >= 1000
#    SARI    : (23.09 hesap paylaşımı) son 24 saatte ekranı 8+ kez el değiştiren
#              üye >= 1, ya da 4. cihazla girmeye çalışan üye >= 3
#    YEŞİL   : hiçbiri
#    KÖR     : sayım okunamadı (fonksiyon yok / yetki / ağ) — "temiz" SAYILMAZ
#
#  MAİL: SARI / KIRMIZI / KÖR'de Cem'e (arac/alarm-maili.ps1). Aynı ya da daha
#  düşük seviye için 6 saat içinde ikinci mail GİTMEZ (gürültülü kapı kapı
#  değildir); seviye YÜKSELİRSE hemen gider. KÖR için tekrar aralığı 24 saat.
#
#  BU KAPI ŞUNU GÖRMEZ (KAPI KURMA KURALLARI m.3):
#    - YAVAŞ bot: saatte 100'ün, dakikada 15'in altında ve çok IP'den gelen
#      sahte kayıt insan kaydından AYIRT EDİLEMEZ.
#    - Sahte hesabın NİTELİĞİ (uydurma alan adı, rastgele ad) — sayım e-postaya
#      bakmaz, bilerek (kişi verisi dışarı çıkmasın).
#    - Meşru kalabalık (viral gönderi, 4 Ekim kayıt dalgası) de SARI/KIRMIZI
#      yakar — alarm "bak" der, "saldırı var" demez.
#
#  KULLANIM:
#    ./motor/uye-alarmi.ps1              # ölç, raporla, gerekirse mail
#    ./motor/uye-alarmi.ps1 -Kuru        # ölç, raporla, MAIL ATMA
#    ./motor/uye-alarmi.ps1 -Sinav       # öz-sınav (ağa gitmez), dogrula.yml'de koşar
#  ÇIKIŞ: 0 = YEŞİL/SARI · 1 = KIRMIZI ya da KÖR (Actions kırmızı olsun)
# ============================================================================
[CmdletBinding()]
param(
  [switch]$Kuru,
  [switch]$Sinav
)
$ErrorActionPreference = 'Stop'
$depoKoku = Split-Path -Parent $PSScriptRoot
$raporYolu = Join-Path $depoKoku 'veri/uye-alarmi.json'
$SUPABASE_ADRES = 'https://bjrleanjpyujtajmazxn.supabase.co'

$ESIK = [ordered]@{
  kirmizi_dakika = 30; kirmizi_saat = 300
  sari_dakika = 15; sari_saat = 100; sari_gun = 1000
  tekrar_saat = 6; kor_tekrar_saat = 24
  paylasim_sari = 1; cihaz_siniri_sari = 3
}
$SEVIYE_SIRA = @{ 'YESIL' = 0; 'SARI' = 1; 'KIRMIZI' = 2; 'KOR' = 3 }

# ---- saf fonksiyonlar (öz-sınav bunları ağsız sınar) -------------------------
function Get-UyeSeviyesi {
  param($SayimGirdisi)
  if ($null -eq $SayimGirdisi) { return [pscustomobject]@{ seviye = 'KOR'; gerekce = 'sayim okunamadi' } }
  $saatlik = [int]$SayimGirdisi.son_1_saat
  $gunluk  = [int]$SayimGirdisi.son_24_saat
  $dakikaTepe = [int]$SayimGirdisi.en_yogun_dakika
  if ($dakikaTepe -ge $ESIK.kirmizi_dakika) { return [pscustomobject]@{ seviye = 'KIRMIZI'; gerekce = "bir dakikada $dakikaTepe kayit (bot hizi, esik $($ESIK.kirmizi_dakika))" } }
  if ($saatlik -ge $ESIK.kirmizi_saat)       { return [pscustomobject]@{ seviye = 'KIRMIZI'; gerekce = "son 1 saatte $saatlik kayit (esik $($ESIK.kirmizi_saat))" } }
  if ($dakikaTepe -ge $ESIK.sari_dakika)     { return [pscustomobject]@{ seviye = 'SARI'; gerekce = "bir dakikada $dakikaTepe kayit (esik $($ESIK.sari_dakika))" } }
  if ($saatlik -ge $ESIK.sari_saat)          { return [pscustomobject]@{ seviye = 'SARI'; gerekce = "son 1 saatte $saatlik kayit (esik $($ESIK.sari_saat))" } }
  if ($gunluk -ge $ESIK.sari_gun)            { return [pscustomobject]@{ seviye = 'SARI'; gerekce = "son 24 saatte $gunluk kayit (esik $($ESIK.sari_gun))" } }
  # 23.09 hesap paylaşımı belirtileri (eski uye_sayim bu alanları döndürmez -> 0 sayılır)
  $paylasimSupheli = [int]$SayimGirdisi.paylasim_supheli
  $cihazSiniriAsan = [int]$SayimGirdisi.cihaz_siniri_24s
  if ($paylasimSupheli -ge $ESIK.paylasim_sari) { return [pscustomobject]@{ seviye = 'SARI'; gerekce = "$paylasimSupheli uyede ekran 24 saatte 8+ kez el degistirdi (hesap paylasimi belirtisi)" } }
  if ($cihazSiniriAsan -ge $ESIK.cihaz_siniri_sari) { return [pscustomobject]@{ seviye = 'SARI'; gerekce = "$cihazSiniriAsan uye 24 saatte 4. cihazla girmeye calisti (esik $($ESIK.cihaz_siniri_sari))" } }
  return [pscustomobject]@{ seviye = 'YESIL'; gerekce = 'esiklerin altinda' }
}

function Test-MailGerekli {
  param([string]$SimdikiSeviye, $EskiAlarm, [datetime]$OlcumAni)
  if ($SimdikiSeviye -eq 'YESIL') { return $false }
  if ($null -eq $EskiAlarm -or -not $EskiAlarm.zaman) { return $true }
  # PS7 ConvertFrom-Json ISO tarihi DateTime'a cevirir, PS5.1 metin birakir - ikisi de karsilanir
  $eskiZaman = if ($EskiAlarm.zaman -is [datetime]) { ([datetime]$EskiAlarm.zaman).ToUniversalTime() } else { [datetime]::Parse([string]$EskiAlarm.zaman, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::RoundtripKind).ToUniversalTime() }
  $gecenSaat = ($OlcumAni - $eskiZaman).TotalHours
  $aralik = if ($SimdikiSeviye -eq 'KOR') { $ESIK.kor_tekrar_saat } else { $ESIK.tekrar_saat }
  if ($SEVIYE_SIRA[$SimdikiSeviye] -gt $SEVIYE_SIRA[[string]$EskiAlarm.seviye]) { return $true }   # seviye yükseldi
  return ($gecenSaat -ge $aralik)
}

# ---- öz-sınav ----------------------------------------------------------------
if ($Sinav) {
  $simdiUtc = [datetime]::UtcNow
  $vakalar = @(
    @{ ad = 'sakin gun';                 s = @{ son_1_saat = 1;   son_24_saat = 5;    en_yogun_dakika = 1 };  bek = 'YESIL' },
    @{ ad = 'sinir altinda (yanlis alarm vermemeli)'; s = @{ son_1_saat = 99; son_24_saat = 999; en_yogun_dakika = 14 }; bek = 'YESIL' },
    @{ ad = 'saatlik kalabalik';         s = @{ son_1_saat = 120; son_24_saat = 300;  en_yogun_dakika = 5 };  bek = 'SARI' },
    @{ ad = 'gunluk kalabalik';          s = @{ son_1_saat = 10;  son_24_saat = 1200; en_yogun_dakika = 3 };  bek = 'SARI' },
    @{ ad = 'dakikada 16 (hizli)';       s = @{ son_1_saat = 20;  son_24_saat = 20;   en_yogun_dakika = 16 }; bek = 'SARI' },
    @{ ad = 'dakikada 35 (bot hizi)';    s = @{ son_1_saat = 40;  son_24_saat = 40;   en_yogun_dakika = 35 }; bek = 'KIRMIZI' },
    @{ ad = 'saatte 350';                s = @{ son_1_saat = 350; son_24_saat = 400;  en_yogun_dakika = 10 }; bek = 'KIRMIZI' },
    @{ ad = 'sayim yok';                 s = $null;                                                               bek = 'KOR' },
    @{ ad = 'paylasim supheli 1 uye';    s = @{ son_1_saat = 0; son_24_saat = 0; en_yogun_dakika = 0; paylasim_supheli = 1; cihaz_siniri_24s = 0 }; bek = 'SARI' },
    @{ ad = 'cihaz siniri 2 (yanlis alarm vermemeli)'; s = @{ son_1_saat = 0; son_24_saat = 0; en_yogun_dakika = 0; paylasim_supheli = 0; cihaz_siniri_24s = 2 }; bek = 'YESIL' },
    @{ ad = 'cihaz siniri 3 uye';        s = @{ son_1_saat = 0; son_24_saat = 0; en_yogun_dakika = 0; paylasim_supheli = 0; cihaz_siniri_24s = 3 }; bek = 'SARI' },
    @{ ad = 'eski sayim (paylasim alani yok)'; s = @{ son_1_saat = 1; son_24_saat = 2; en_yogun_dakika = 1 };           bek = 'YESIL' }
  )
  $dusen = 0
  foreach ($v in $vakalar) {
    $girdi = if ($null -eq $v.s) { $null } else { [pscustomobject]$v.s }
    $sonucSeviye = (Get-UyeSeviyesi -SayimGirdisi $girdi).seviye
    $tamam = ($sonucSeviye -eq $v.bek)
    if (-not $tamam) { $dusen++ }
    Write-Host ("  [{0}] {1}: bekl {2}, cikti {3}" -f ($(if ($tamam) { 'OK ' } else { 'DUS' })), $v.ad, $v.bek, $sonucSeviye)
  }
  $mailVakalari = @(
    @{ ad = 'YESIL -> mail yok';                      sv = 'YESIL';   onc = $null;                                                              bek = $false },
    @{ ad = 'ilk SARI -> mail';                       sv = 'SARI';    onc = $null;                                                              bek = $true },
    @{ ad = 'SARI, 2 sa once SARI -> tekrar yok';     sv = 'SARI';    onc = @{ seviye = 'SARI'; zaman = $simdiUtc.AddHours(-2).ToString('o') }; bek = $false },
    @{ ad = 'SARI, 7 sa once SARI -> mail';           sv = 'SARI';    onc = @{ seviye = 'SARI'; zaman = $simdiUtc.AddHours(-7).ToString('o') }; bek = $true },
    @{ ad = 'KIRMIZI, 1 sa once SARI -> yukseldi';    sv = 'KIRMIZI'; onc = @{ seviye = 'SARI'; zaman = $simdiUtc.AddHours(-1).ToString('o') }; bek = $true },
    @{ ad = 'SARI, 1 sa once KIRMIZI -> tekrar yok';  sv = 'SARI';    onc = @{ seviye = 'KIRMIZI'; zaman = $simdiUtc.AddHours(-1).ToString('o') }; bek = $false },
    @{ ad = 'KOR, 8 sa once KOR -> tekrar yok (24s)'; sv = 'KOR';     onc = @{ seviye = 'KOR'; zaman = $simdiUtc.AddHours(-8).ToString('o') }; bek = $false }
  )
  foreach ($m in $mailVakalari) {
    $onceki = if ($null -eq $m.onc) { $null } else { [pscustomobject]$m.onc }
    $sonucMail = Test-MailGerekli -SimdikiSeviye $m.sv -EskiAlarm $onceki -OlcumAni $simdiUtc
    $tamam = ($sonucMail -eq $m.bek)
    if (-not $tamam) { $dusen++ }
    Write-Host ("  [{0}] {1}: bekl {2}, cikti {3}" -f ($(if ($tamam) { 'OK ' } else { 'DUS' })), $m.ad, $m.bek, $sonucMail)
  }
  $toplamVaka = $vakalar.Count + $mailVakalari.Count
  if ($dusen -gt 0) { Write-Host "UYE ALARMI OZ-SINAVI KIRMIZI ($dusen / $toplamVaka vaka dustu)"; exit 1 }
  Write-Host "UYE ALARMI OZ-SINAVI YESIL ($toplamVaka vaka: $($vakalar.Count) seviye + $($mailVakalari.Count) mail tekrari)"
  exit 0
}

# ---- ölçüm -------------------------------------------------------------------
$servisAnahtari = ("$env:SUPABASE_SERVICE_KEY" -replace '[^\x21-\x7E]', '')
if (-not $servisAnahtari) { $servisAnahtari = ([Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY', 'User') -replace '[^\x21-\x7E]', '') }

$sayim = $null; $okumaHatasi = ''
if (-not $servisAnahtari) {
  $okumaHatasi = 'SUPABASE_SERVICE_KEY yok'
} else {
  try {
    # UA bilerek düz: Supabase, tarayıcıya benzeyen UA'da gizli anahtarı reddediyor
    # ("Forbidden use of secret API key in browser" — 23.09'da yaşandı).
    $sayim = Invoke-RestMethod -Uri "$SUPABASE_ADRES/rest/v1/rpc/uye_sayim" -Method Post `
      -Headers @{ apikey = $servisAnahtari; Authorization = "Bearer $servisAnahtari"; 'Content-Type' = 'application/json' } `
      -Body '{}' -UserAgent 'tetikte-uye-alarmi/1.0' -TimeoutSec 40
  } catch {
    $okumaHatasi = "$($_.Exception.Message)"
    if ($okumaHatasi -match '404|PGRST202|Could not find the function') {
      $okumaHatasi = 'uye_sayim() fonksiyonu YOK - radar-app/sql/2026-09-23-uye-sayim.sql basilmamis'
    }
    $sayim = $null
  }
}

$karar = Get-UyeSeviyesi -SayimGirdisi $sayim
$simdi = [datetime]::UtcNow
$oncekiRapor = $null
if (Test-Path $raporYolu) { try { $oncekiRapor = Get-Content $raporYolu -Raw -Encoding UTF8 | ConvertFrom-Json } catch { $oncekiRapor = $null } }
$oncekiAlarm = if ($oncekiRapor) { $oncekiRapor.son_alarm } else { $null }
$mailGerek = Test-MailGerekli -SimdikiSeviye $karar.seviye -EskiAlarm $oncekiAlarm -OlcumAni $simdi

Write-Host "=== UYE ALARMI ==="
Write-Host ("SEVIYE: {0} - {1}" -f $karar.seviye, $karar.gerekce)
if ($sayim) { Write-Host ("  son 1 saat: {0} · son 24 saat: {1} · en yogun dakika: {2} · toplam: {3}" -f $sayim.son_1_saat, $sayim.son_24_saat, $sayim.en_yogun_dakika, $sayim.toplam) }
else { Write-Host "  KOR: $okumaHatasi" }

$yeniAlarm = $oncekiAlarm
if ($mailGerek) {
  $konu = switch ($karar.seviye) {
    'KIRMIZI' { 'TETIKTE - UYE ALARMI KIRMIZI: sahte hesap dalgasi olabilir' }
    'SARI'    { 'TETIKTE - Uye alarmi SARI: beklenmedik kayit artisi' }
    default   { 'TETIKTE - Uye alarmi KOR: yeni uye sayisi okunamiyor' }
  }
  $mesaj = if ($sayim) {
@"
Seviye: $($karar.seviye) - $($karar.gerekce)

Son 1 saat: $($sayim.son_1_saat) yeni uye
Son 24 saat: $($sayim.son_24_saat) yeni uye
Son 1 saatin en yogun dakikasi: $($sayim.en_yogun_dakika) kayit
Toplam uye: $($sayim.toplam)
Hesap paylasimi belirtisi (24 sa, ekran 8+ kez el degistirdi): $([int]$sayim.paylasim_supheli) uye
4. cihazla girmeye calisan (24 sa): $([int]$sayim.cihaz_siniri_24s) uye

Ne yapmali:
- Bir dakikada 30'dan fazla kayit insan hizi degildir; bot olabilir.
- Hazirda bekleyen bot korumasi (captcha.js, KAPALI) acilabilir; adimlar dosyanin basinda.
- Mesru kalabalik (viral gonderi, canli deneme kaydi) de bu alarmi yakar: once hangi paylasimdan sonra geldigine bak.

Bu alarm e-posta adreslerine BAKMAZ (kisi verisi disari cikmasin diye) - yalniz sayar.
Ayni seviye icin 6 saat icinde tekrar mail gelmez.
"@
  } else {
@"
Yeni uye sayisi okunamadi - alarm su an KOR (yani sahte hesap dalgasi olsa gormeyiz).
Sebep: $okumaHatasi

Bu mail 24 saatte bir tekrarlanir, sorun duzelene kadar.
"@
  }
  if ($Kuru) {
    Write-Host "KURU KOSU - mail gonderilmedi. Konu: $konu"
  } else {
    & (Join-Path $depoKoku 'arac/alarm-maili.ps1') -Konu $konu -Mesaj $mesaj
    $yeniAlarm = [ordered]@{ seviye = $karar.seviye; zaman = $simdi.ToString('o') }
  }
}

# ---- rapor (kişi verisi YOK: yalnız sayılar) ----------------------------------
. (Join-Path $depoKoku 'arac/rapor-yaz.ps1')
$rapor = [ordered]@{
  olcum = $simdi.ToString('o')
  seviye = $karar.seviye
  gerekce = $karar.gerekce
  son_1_saat = if ($sayim) { [int]$sayim.son_1_saat } else { $null }
  son_24_saat = if ($sayim) { [int]$sayim.son_24_saat } else { $null }
  en_yogun_dakika = if ($sayim) { [int]$sayim.en_yogun_dakika } else { $null }
  toplam = if ($sayim) { [int]$sayim.toplam } else { $null }
  paylasim_supheli = if ($sayim) { [int]$sayim.paylasim_supheli } else { $null }
  cihaz_siniri_24s = if ($sayim) { [int]$sayim.cihaz_siniri_24s } else { $null }
  okuma_hatasi = if ($okumaHatasi) { $okumaHatasi } else { $null }
  esikler = $ESIK
  son_alarm = $yeniAlarm
  gormedigi = @(
    'yavas bot: saatte 100 / dakikada 15 altinda, cok IP - insandan ayirt edilemez',
    'sahte hesabin niteligi (uydurma alan adi) - e-postaya bilerek bakilmaz',
    'mesru kalabalik da SARI/KIRMIZI yakar - alarm "bak" der, "saldiri var" demez',
    'sirali paylasim (biri sabah biri aksam, toplam 3 cihazi asmadan) ekran el degistirmesi az oldugu icin gorunmez'
  )
}
if (-not $Kuru) { RaporYaz -Hedef $raporYolu -Nesne $rapor | Out-Null }
else { Write-Host "KURU KOSU - rapor yazilmadi." }

if ($karar.seviye -in @('KIRMIZI', 'KOR')) { exit 1 }
exit 0
