# ============================================================================
#  DAYANAK NÖBETÇİSİ — kanun değişti, hangi SAYFALAR etkilendi?  (PARA HARCAMAZ)
#
#  ZİNCİRİN SON HALKASI. Cem'in teşhisi (29.07): "kanun değişince sorularda vs.
#  her şeyde değişikliği yapacaksın; GTİP değişti, otomatik hesaplamalarımız
#  değişecek."
#
#  Bugüne kadar zincir yarımdı:
#     mevzuat.gov.tr --[robot, her gün]--> AMBAR ✓
#                                            ↓
#                                        sorular ✓   (madde damgası çekiyor)
#                                        sayfalar ✗  (BAĞ YOKTU)
#
#  Bedeli görüldü: KVKK sayfası 11.07'de şablondan yazıldı, kanun ambara
#  27.07'de girdi, kimse dönüp karşılaştırmadı. m.9'un 2/3/2024 tarihli 7499
#  sayılı Kanunla değiştiği ancak 29.07'de metin okununca fark edildi.
#
#  BU BETİK: madde damgası "şu madde değişti" dediğinde, dayanak haritasından
#  o maddeye yaslanan SAYFALARI bulur ve isimleriyle önümüze koyar.
#
#  KOŞU KIRMIZI BİTER (exit 1) — ve bu bilerek yapılmıştır. Bu depoda dört
#  ayrı katman "kuruldu ama kimse görmedi" diye sessizce beklemişti: madde
#  damgasının -uygula anahtarı kapalıydı, karnenin iş akışı yoktu, akışın
#  tetiği robot push'una takılıydı, karne betiği log bile yazmıyordu.
#  Sessiz rapor okunmaz. Bir şeyi DURDURAMAYAN katman, katman değildir.
#
#  Çıktılar: veri/dayanak-uyari.json + ekrana döküm
#  PARA HARCAMAZ: yalnız yerel dosya okuma.
# ============================================================================
$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
try { Start-Transcript -Path (Join-Path $kok 'veri/dayanak-nobet-log.txt') -Force | Out-Null } catch {}

$degisimYol = Join-Path $kok 'veri/madde-degisim.json'
$haritaYol  = Join-Path $kok 'veri/dayanak-haritasi.json'

if(-not (Test-Path $degisimYol)){ Write-Host "madde-degisim.json yok - damga henuz kosmamis. Atlaniyor."; try{Stop-Transcript|Out-Null}catch{}; exit 0 }
if(-not (Test-Path $haritaYol)){  Write-Host "dayanak-haritasi.json yok - once motor/dayanak-haritasi.ps1 kosmali."; try{Stop-Transcript|Out-Null}catch{}; exit 0 }

$deg = Get-Content $degisimYol -Raw -Encoding UTF8 | ConvertFrom-Json
$har = Get-Content $haritaYol  -Raw -Encoding UTF8 | ConvertFrom-Json

if($deg.ilk_kurulum -eq $true){ Write-Host "Damga ILK KURULUM - karsilastirilacak onceki hal yok. Atlaniyor."; try{Stop-Transcript|Out-Null}catch{}; exit 0 }

$degisenler = @($deg.degisen)
Write-Host ("Degisen madde : {0}" -f $degisenler.Count)
Write-Host ("Haritadaki sayfa: {0}" -f @($har.sayfalar).Count)

if($degisenler.Count -eq 0){
  Write-Host ""
  Write-Host "TEMIZ: degisen madde yok, etkilenen sayfa yok."
  [IO.File]::WriteAllText((Join-Path $kok 'veri/dayanak-uyari.json'),
    ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); degisen_madde=0; etkilenen_sayfa=0; uyarilar=@() } | ConvertTo-Json -Depth 5),
    (New-Object Text.UTF8Encoding($false)))
  try{Stop-Transcript|Out-Null}catch{}
  exit 0
}

# --- degisen maddenin adindan (kanun_no, madde_no) cikar
# Ornek adlar: "VUK (213 s.K.) m.344"  ·  "5510 s. SGK Kanunu m.8"
# gec./ek serileri AYRI maddedir - normal m.N ile karistirilmamali.
$degisenCift = @{}
$ayristirilamayan = New-Object System.Collections.Generic.List[string]
$standartDegisen = 0; $tebligEkDegisen = 0
foreach($d in $degisenler){
  $ad = "$($d.ad)"
  # 28.08 TEK-YAZAR uyumu: standart parcalari (BDS/TMS/TFRS... p.N) ve teblig
  # EK aileleri site sayfalarinin dayanak haritasina kanun_no|madde_no ile
  # baglanmaz - bunlari 'ayristirilamayan' diye BAGIRMAK gurultu (27.08: 482
  # degisenin coguydu). Sayilir, raporda ayri alanda gosterilir, liste kirletmez.
  if($ad -match '^(BDS|GDS|SBDS|TMS|TFRS|TSRS|KYS|KKS)\s?\d+([A-Z])?\s+p\.'){ $standartDegisen++; continue }
  if($ad -match '\sGT\s\d+\sEK\s|\bEK\s*\[|Teori Notu - '){ $tebligEkDegisen++; continue }
  if($ad -match '(?i)\b(gec|ek|muk)\.?\s*m\.'){ $ayristirilamayan.Add("$ad (gec/ek serisi - normal madde ile eslestirilmedi)"); continue }
  $kn = $null; $mn = $null
  if($ad -match '(\d{3,4})\s*s\.'){ $kn = $Matches[1] }
  if($ad -match 'm\.(\d{1,4})'){ $mn = $Matches[1] }
  if($kn -and $mn){ $degisenCift["$kn|$mn"] = $ad }
  else { $ayristirilamayan.Add($ad) }
}
Write-Host ("  ayristirilan cift: {0}" -f $degisenCift.Count)
if($ayristirilamayan.Count -gt 0){
  Write-Host ("  AYRISTIRILAMAYAN {0} kayit (gozden kacmasin diye yaziliyor):" -f $ayristirilamayan.Count)
  foreach($x in ($ayristirilamayan | Select-Object -First 15)){ Write-Host ("     {0}" -f $x) }
}

# --- hangi sayfa hangi degisen maddeye yasliyor
$uyari = New-Object System.Collections.Generic.List[object]
foreach($s in @($har.sayfalar)){
  $vurulan = @()
  foreach($dy in @($s.dayanak)){
    $a = "$($dy.kanun_no)|$($dy.madde_no)"
    if($degisenCift.ContainsKey($a)){ $vurulan += $degisenCift[$a] }
  }
  if($vurulan.Count -gt 0){
    $uyari.Add([ordered]@{ sayfa="$($s.sayfa)"; etkileyen_madde_sayisi=$vurulan.Count; maddeler=$vurulan })
  }
}

$cikti = [ordered]@{
  tarih = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  aciklama = "Damgasi degisen maddeye yaslanan sayfalar. Her biri GM tarafindan okunup guncellenmeden dogru sayilmaz."
  degisen_madde = $degisenler.Count
  etkilenen_sayfa = $uyari.Count
  standart_degisen_bilgi = $standartDegisen
  teblig_ek_degisen_bilgi = $tebligEkDegisen
  ayristirilamayan = $ayristirilamayan
  uyarilar = $uyari
}
[IO.File]::WriteAllText((Join-Path $kok 'veri/dayanak-uyari.json'), ($cikti | ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding($false)))

Write-Host ""
if($uyari.Count -eq 0){
  Write-Host "Degisen madde var ama HICBIR SAYFA onlara yaslanmiyor - sayfa tarafi temiz."
  Write-Host "(Sorular ayri korunuyor: madde damgasi -uygula ile onlari yayindan cekiyor.)"
  try{Stop-Transcript|Out-Null}catch{}
  exit 0
}

Write-Host "======================================================================"
Write-Host ("  KANUN DEGISTI - {0} SAYFA ETKILENDI" -f $uyari.Count)
Write-Host "======================================================================"
foreach($u in $uyari){
  Write-Host ("  {0}" -f $u.sayfa)
  foreach($m in $u.maddeler){ Write-Host ("      <- {0}" -f $m) }
}
Write-Host ""
Write-Host "  Bu sayfalar OKUNUP GUNCELLENMEDEN dogru sayilmaz."
Write-Host "  -> veri/dayanak-uyari.json"
Write-Host ""
Write-Host "  KOSU BILEREK KIRMIZI BITIYOR: sessiz rapor okunmaz. Bu depoda dort"
Write-Host "  katman 'kuruldu ama kimse gormedi' diye bekledi; bu besincisi olmayacak."
try{Stop-Transcript|Out-Null}catch{}
exit 1
