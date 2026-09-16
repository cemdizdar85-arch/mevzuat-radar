#requires -Version 5.1
# ============================================================================
#  BEKLEYEN TOPLU PARTİ KAYDI — YEREL <-> AMBAR SENKRONU (16.09.2026, Cem "soru basmayı buluta taşıyalım")
#
#  NEDEN: veri/bekleyen-partiler.json gönderilmiş her Anthropic toplu partisinin kimliğini tutar. Üretici yeniden başlatıldığında
#  bitmiş partinin cevaplarını buradan BEDAVA hasat eder. Bulut koşusunda bu dosya runner'la birlikte siliniyordu: iş 350 dk
#  tavanına takılıp yeniden tetiklenirse aynı istekler İKİNCİ KEZ gönderilip ödenirdi. Kayıt artık ambarda da tutulur.
#
#  NEREDE: kalip_parti tablosunda tek satır — etiket '__sistem-bekleyen-partiler', sinav 'SISTEM'. Sayımlar ve parti indirmesi
#  sinav=SGS/SMMM/KGK süzdüğü için bu satır hiçbir soru sayımına girmez. Erişim servis anahtarıyla (GitHub Secret / kullanıcı
#  ortam değişkeni); anahtar ekrana basılmaz. İçerik yalnız parti kimliği + etiket + parmak izidir, soru metni taşımaz.
#
#  BİRLEŞTİRME: kimliğe göre birleşim (hiç kayıt silinmez). Aynı kimlik iki yerde varsa 'durum' alanı dolu olan kazanır,
#  ikisi de doluysa YEREL kazanır (durum güncellemesi yerelde yapılır).
#
#  Kullanım:  powershell -NoProfile -File arac/bekleyen-senkron.ps1 -Indir      (ambar -> yerel, birleştirerek)
#             powershell -NoProfile -File arac/bekleyen-senkron.ps1 -Yukle      (yerel -> ambar, birleştirerek)
#             -Kuru : yalnız sayar, yazmaz
# ============================================================================
param([switch]$Indir, [switch]$Yukle, [switch]$Kuru)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
if (-not ($Indir -xor $Yukle)) { throw 'Tek yön seç: -Indir YA DA -Yukle' }
$depoKok = Split-Path -Parent $PSScriptRoot
. (Join-Path $depoKok 'motor\api-hedef.ps1')   # Invoke-BekleyenKilitli (makine çapında Mutex) için
$SERVIS_ANAHTARI = "$env:SUPABASE_SERVICE_KEY"; if (-not $SERVIS_ANAHTARI) { $SERVIS_ANAHTARI = "$([Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'))" }
if (-not $SERVIS_ANAHTARI.Trim()) { throw 'SUPABASE_SERVICE_KEY yok' }
$SERVIS_ANAHTARI = $SERVIS_ANAHTARI.Trim()
$TABLO_UCU = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/kalip_parti'
$SISTEM_ETIKETI = '__sistem-bekleyen-partiler'
$ISTEK_BASLIK = @{ apikey = $SERVIS_ANAHTARI; Authorization = "Bearer $SERVIS_ANAHTARI"; Accept = 'application/json'; 'User-Agent' = 'mevzuat-radar-robot/1.0' }
$YEREL_YOL = Join-Path $depoKok 'veri\bekleyen-partiler.json'

function DiziyeCevir($ham) { if ($null -eq $ham) { return @() }; $sonuc = @(); foreach ($x in $ham) { if ($x -and "$($x.id)") { $sonuc += $x } }; return $sonuc }
function YereliOku { if (-not (Test-Path $YEREL_YOL)) { return @() }; return (DiziyeCevir (ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($YEREL_YOL)))) }
function AmbariOku {
  $cevap = Invoke-RestMethod -Uri ("$TABLO_UCU" + "?select=icerik&etiket=eq.$SISTEM_ETIKETI") -Headers $ISTEK_BASLIK -TimeoutSec 120
  $satirlar = @($cevap | ForEach-Object { $_ })
  if (-not $satirlar.Count) { return @() }
  $ic = $satirlar[0].icerik; if ($ic -is [string]) { $ic = ConvertFrom-Json -InputObject $ic }
  return (DiziyeCevir $ic.partiler)
}
function Birlestir($oncelikli, $diger) {
  $harita = [ordered]@{}
  foreach ($x in $diger) { $harita["$($x.id)"] = $x }
  foreach ($x in $oncelikli) {
    $k = "$($x.id)"
    if ($harita.Contains($k) -and -not "$($x.durum)" -and "$($harita[$k].durum)") { continue }   # durumu dolu olan kazanır
    $harita[$k] = $x
  }
  return @($harita.Values | Sort-Object { "$($_.zaman)" })
}

$ambarListe = AmbariOku
if ($Indir) {
  Invoke-BekleyenKilitli {
    $yerel = YereliOku
    $birlesik = Birlestir $yerel $ambarListe
    "BEKLEYEN İNDİR: ambar $($ambarListe.Count) · yerel $($yerel.Count) -> birleşik $($birlesik.Count)"
    if (-not $Kuru) { [IO.File]::WriteAllText($YEREL_YOL, (ConvertTo-Json -InputObject @($birlesik) -Depth 5), (New-Object Text.UTF8Encoding($false))) }
  }
} else {
  $yerel = @(); Invoke-BekleyenKilitli { $script:YEREL_KOPYA = YereliOku }; $yerel = @($script:YEREL_KOPYA)
  $birlesik = Birlestir $yerel $ambarListe
  "BEKLEYEN YÜKLE: yerel $($yerel.Count) · ambar $($ambarListe.Count) -> birleşik $($birlesik.Count)"
  if (-not $Kuru) {
    $govde = [ordered]@{ etiket = $SISTEM_ETIKETI; sinav = 'SISTEM'; yazan = 'bekleyen-senkron'; icerik = [ordered]@{ aciklama = 'Gönderilmiş toplu parti kimlikleri (arac/bekleyen-senkron.ps1). Soru değildir.'; partiler = @($birlesik) } }
    $bayt = [Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject $govde -Depth 8 -Compress))
    [void](Invoke-RestMethod -Method Post -Uri ($TABLO_UCU + '?on_conflict=etiket') -Headers ($ISTEK_BASLIK + @{ Prefer = 'resolution=merge-duplicates,return=minimal' }) -ContentType 'application/json; charset=utf-8' -Body $bayt -TimeoutSec 180)
    "ambara yazıldı: $($birlesik.Count) kayıt"
  }
}
