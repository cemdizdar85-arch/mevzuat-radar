# ============================================================================
#  DAYANAK HARİTASI — hangi sayfa hangi maddeye yaslanıyor    (PARA HARCAMAZ)
#
#  NEDEN VAR (29.07.2026): KVKK sayfası, KVKK 6698 ambara girmeden BEŞ GÜN
#  ÖNCE şablondan yazılmıştı. Sonuç: m.9'un 2/3/2024 tarihli 7499 sayılı
#  Kanunla değiştiğini kimse görmedi; sayfa "yurt dışına aktarım açık rızayla
#  olur" diyordu, oysa yeni m.9'da açık rıza yalnızca ARIZİ aktarımlar için.
#  Hata metni okuyunca çıktı — çünkü sayfayla ambar arasında BAĞ YOKTU.
#
#  Ölçüldü: kanun atfı yapan 15 sayfanın HEPSİ, atıf yaptıkları kanun ambara
#  girmeden önce yazılmış. Yani KVKK istisna değil, DESEN.
#
#  Cem'in kendi teşhisi (29.07): "kanun değişince sorularda vs. her şeyde
#  değişikliği yapacaksın; GTİP değişti, otomatik hesaplamalarımız değişecek."
#  Sorular ambara bağlı olduğu için korunuyor; sayfalar ve araçlar değil.
#
#  BU BETİK NE YAPAR:
#   1) Her HTML sayfasından kanun atıflarını çıkarır (VUK m.344, TTK m.365,
#      "VUK — m.333/339/352" gibi çoklu biçimler dâhil).
#   2) Kısaltmayı kanun numarasına çevirir.
#   3) Her (kanun, madde) çiftini AMBARDA arar.
#   4) İki çıktı verir:
#        veri/dayanak-haritasi.json  → sayfa başına dayanak listesi
#        ekranda + logda            → AMBARDA BULUNAMAYAN atıflar
#
#  (4) neden önemli: ambarda olmayan bir maddeye atıf ya yanlış numaradır ya
#  uydurmadır. İkisi de okuyucuya "kaynaklı" görünür — sitenin en sinsi hata
#  türü, sorularda da aynıydı.
#
#  PARA HARCAMAZ: yalnız yerel dosya okuma + Supabase (dokumanlar açık).
# ============================================================================
$ErrorActionPreference = "Stop"
# Supabase gizli anahtarli istegi KIMLIKSIZ gelirse 401 ile reddeder.
# (16.08.2026 olculdu: ayni sorgu UA'siz 401, UA'li 5 kayit. madde-coz.ps1
#  bu yuzden her kaynaga "ambarda-yok" diyordu.) IRM ve IWR AYRI yazilir.
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$PSDefaultParameterValues['Invoke-WebRequest:UserAgent'] = 'mevzuat-radar-robot/1.0'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
try { Start-Transcript -Path (Join-Path $kok 'veri/dayanak-log.txt') -Force | Out-Null } catch {}

$SB_URL = "https://bjrleanjpyujtajmazxn.supabase.co"
$KEY = if($env:SUPABASE_KEY){ $env:SUPABASE_KEY } else { "sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg" }
$H = @{ apikey = $KEY; Authorization = "Bearer $KEY" }

# Kisaltma -> kanun no. Ambardaki kayit adi bicimi de yazili, cunku hepsi
# "(NNNN s.K.)" kalibinda DEGIL: 5510 "5510 s. SGK Kanunu" diye geciyor.
# Bu ayrimi bilmeden sorgu yazmak "5510 ambarda yok" gibi YANLIS ALARM verir -
# 29.07'de tam bu yasandi, desen duzeltilene kadar kanun yok sanildi.
$KANUN = @(
  @{ kisa='VUK';     no='213';  desen='213 s.K.' }
  @{ kisa='TTK';     no='6102'; desen='6102 s.K.' }
  @{ kisa='TBK';     no='6098'; desen='6098 s.K.' }
  @{ kisa='İİK';     no='2004'; desen='2004 s.K.' }
  @{ kisa='IIK';     no='2004'; desen='2004 s.K.' }
  @{ kisa='KDVK';    no='3065'; desen='3065 s.K.' }
  @{ kisa='KVK';     no='5520'; desen='5520 s.K.' }
  @{ kisa='KVKK';    no='6698'; desen='6698 s.K.' }
  @{ kisa='SMK';     no='6769'; desen='6769 s.K.' }
  @{ kisa='AATUHK';  no='6183'; desen='6183 s.K.' }
  @{ kisa='ÖTV';     no='4760'; desen='4760 s.K.' }
  @{ kisa='OTV';     no='4760'; desen='4760 s.K.' }
  @{ kisa='GVK';     no='193';  desen='193 s.K.' }
  @{ kisa='SGK';     no='5510'; desen='5510 s. SGK' }
)
function KanunBul([string]$kisa){
  foreach($k in $KANUN){ if($k.kisa -eq $kisa){ return $k } }
  return $null
}

# --- 1) sayfalardan atif cikar
$sayfalar = @(Get-ChildItem $kok -Filter "*.html" -File | Sort-Object Name)
Write-Host ("Taranan sayfa: {0}" -f $sayfalar.Count)
$harita = New-Object System.Collections.Generic.List[object]
$tumCift = @{}

foreach($f in $sayfalar){
  $metin = [IO.File]::ReadAllText($f.FullName, [Text.Encoding]::UTF8)
  $bulunan = @{}
  # "VUK m.344" / "VUK — m.333/339/352" / "TTK (6102 s.K.) m.365, m.370"
  foreach($m in [regex]::Matches($metin, '(?<kisa>VUK|TTK|TBK|İİK|IIK|KDVK|KVKK|KVK|SMK|AATUHK|ÖTV|OTV|GVK|SGK)\s*(?:\([^)]{0,20}\))?\s*[—\-–]?\s*m\.(?<mad>\d{1,4}(?:\s*/\s*\d{1,4})*)')){
    $k = KanunBul $m.Groups['kisa'].Value
    if(-not $k){ continue }
    foreach($tek in ($m.Groups['mad'].Value -split '\s*/\s*')){
      $tek = "$tek".Trim()
      if(-not $tek){ continue }
      $anahtar = "$($k.no)|$tek"
      $bulunan[$anahtar] = 1
      $tumCift[$anahtar] = $k.desen
    }
  }
  if($bulunan.Count -eq 0){ continue }
  $liste = @()
  foreach($a in ($bulunan.Keys | Sort-Object)){
    $p = $a -split '\|'
    $liste += [ordered]@{ kanun_no=$p[0]; madde_no=$p[1] }
  }
  $harita.Add([ordered]@{ sayfa=$f.Name; dayanak_sayisi=$liste.Count; dayanak=$liste })
  Write-Host ("  {0,-26} {1} dayanak" -f $f.Name, $liste.Count)
}

# --- 2) her cifti AMBARDA ara
Write-Host ""
Write-Host ("Tekil (kanun, madde) cifti: {0} - ambarda araniyor..." -f $tumCift.Count)
$yok = New-Object System.Collections.Generic.List[object]
$var = 0
foreach($a in ($tumCift.Keys | Sort-Object)){
  $p = $a -split '\|'
  $desen = $tumCift[$a]
  # kaynak_ad kaliplari: "VUK (213 s.K.) m.40", "5510 s. SGK Kanunu m.8 [2/5]"
  # Ardindan rakam GELMESIN: m.1 ile m.10 karismasin.
  $imatch = [uri]::EscapeDataString(("{0}.*m\.{1}(?![0-9])" -f [regex]::Escape($desen), $p[1]))
  try {
    $r = Invoke-WebRequest -UseBasicParsing -Uri "$SB_URL/rest/v1/dokumanlar?select=id&kaynak_ad=imatch.$imatch&limit=1" -Headers ($H + @{ Prefer='count=exact' }) -TimeoutSec 60
    $adet = [int](($r.Headers['Content-Range'] -split '/')[-1])
  } catch { $adet = -1 }
  if($adet -gt 0){ $var++ }
  else { $yok.Add([ordered]@{ kanun_no=$p[0]; madde_no=$p[1]; desen=$desen; durum=$(if($adet -eq 0){'ambarda-yok'}else{'sorgu-hatasi'}) }) }
}

Write-Host ("  ambarda BULUNAN : {0}" -f $var)
Write-Host ("  BULUNAMAYAN     : {0}" -f $yok.Count)
if($yok.Count -gt 0){
  Write-Host ""
  Write-Host "  BULUNAMAYAN ATIFLAR (yanlis numara ya da uydurma olabilir):"
  foreach($y in ($yok | Select-Object -First 40)){
    Write-Host ("     {0} m.{1}   [{2}]" -f $y.kanun_no, $y.madde_no, $y.durum)
  }
  Write-Host ""
  Write-Host "  NOT: 'ambarda-yok' KESIN HATA DEMEK DEGIL - madde gecici/ek seri"
  Write-Host "  olabilir ya da o kanun ambara henuz tam girmemis olabilir. GM"
  Write-Host "  tek tek bakacak. Ama her biri KONTROL EDILMEDEN yayinda kalmaz."
}

$cikti = [ordered]@{
  tarih  = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  aciklama = "Hangi sayfa hangi kanun maddesine yaslaniyor. Ambar damgasi degisince bu listeden hangi sayfanin etkilendigi bulunur."
  sayfa_sayisi = $harita.Count
  tekil_dayanak = $tumCift.Count
  ambarda_bulunan = $var
  bulunamayan = $yok
  sayfalar = $harita
}
[IO.File]::WriteAllText((Join-Path $kok 'veri/dayanak-haritasi.json'), ($cikti | ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding($false)))
Write-Host ""
Write-Host ("-> veri/dayanak-haritasi.json  ({0} sayfa, {1} tekil dayanak)" -f $harita.Count, $tumCift.Count)
try{Stop-Transcript|Out-Null}catch{}
