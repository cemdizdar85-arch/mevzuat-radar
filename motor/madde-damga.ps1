# ============================================================================
#  MADDE DAMGASI — KATMAN 3 (RG NOBETI)  28.07.2026
#
#  SORUN: bugune kadar damga KANUN BAZINDAYDI (veri/mevzuat/_durum.json).
#  Bir kanun degisince "degisti" diyorduk ama HANGI MADDE degisti bilmiyorduk.
#  Bilmeyince de o maddeye dayanan sorulari ayiramiyorduk. Sonuc: Resmi
#  Gazete'de bir oran/sure degisiyor, kasadaki soru ESKI HALIYLE yayinda
#  kaliyor ve ogrenciye yanlis ogretiyor. Sitenin en sinsi hata kaynagi budur -
#  cunku soru yazildigi gun DOGRUYDU.
#
#  COZUM: damgayi MADDE BAZINA indir. Her (kanun_no, madde_no) ciftinin metni
#  ayri ayri parmak izlenir. Hasat sonrasi karsilastirilir:
#     yeni     -> ambara yeni madde girdi
#     degisen  -> METIN DEGISTI. Bu maddeye dayanan sorular YAYINDAN CEKILIR
#                 ve GM'ye dusar. Insan okumadan geri donmez.
#     kaybolan -> madde mulga/kaldirilmis olabilir; ayrica incelenir
#
#  BU BETIK PARA HARCAMAZ. Yalniz ambar okur, hash hesaplar, rapor yazar.
#
#  NOT (28.07): kasada 'yayin' kolonu HENUZ YOK - yani bir soruyu silmeden
#  yayindan cekmenin yolu yok. Kolon eklenene kadar bu betik SADECE RAPOR
#  uretir, kasaya dokunmaz. Kolon gelince -uygula anahtari acilir.
# ============================================================================
param(
  [switch]$uygula     # kasadaki sorulari yayindan cek (kolon gerektirir)
)
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$SB_URL = "https://bjrleanjpyujtajmazxn.supabase.co"
$KEY = if($env:SUPABASE_SERVICE_KEY){ $env:SUPABASE_SERVICE_KEY } else { "sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg" }
$H = @{ apikey = $KEY; Authorization = "Bearer $KEY" }

# --- metni damgalamadan once SADELESTIR: bosluk/noktalama/buyuk-kucuk farki
# "degisiklik" sayilmamali. Yoksa her yeniden-hasatta yuzlerce sahte alarm cikar
# ve alarm sistemi guvenilirligini yitirir - kimse bakmaz olur.
function Sadelestir([string]$t){
  $x = "$t".ToLowerInvariant()
  $x = $x -replace '[''‘’"“”]', "'"
  $x = $x -replace '\s+', ' '
  return $x.Trim()
}
function Damga([string]$t){
  $sha = [Security.Cryptography.SHA256]::Create()
  $b = $sha.ComputeHash([Text.Encoding]::UTF8.GetBytes((Sadelestir $t)))
  return ([BitConverter]::ToString($b) -replace '-','').Substring(0,16).ToLowerInvariant()
}

Write-Host "MADDE DAMGASI - ambar taraniyor (para harcamaz)..."

# --- ambardan kanun maddelerini sayfali cek
$kayit = New-Object System.Collections.Generic.List[object]
$bas = 0
while($true){
  $u = "$SB_URL/rest/v1/dokumanlar?select=kaynak_ad,metin&order=kaynak_ad&offset=$bas&limit=500"
  $s = Invoke-RestMethod -Uri $u -Headers $H -TimeoutSec 180
  $d = @($s); if($d.Count -eq 0){ break }
  foreach($x in $d){ $kayit.Add($x) }
  if($d.Count -lt 500){ break }
  $bas += 500
  if($bas % 5000 -eq 0){ Write-Host ("  ...{0}" -f $kayit.Count) }
}
Write-Host ("  ambar kaydi: {0}" -f $kayit.Count)

# --- kaynak_ad'dan (kanun_no, madde_no) cikar
# Kaliplar: "VUK (213 s.K.) m.40", "5510 s. SGK Kanunu m.8 [2/5]", "KDVK (3065 s.K.) m.2 - Teslim"
# gec./ek maddeler AYRI seridir, ayri anahtarla damgalanir (karistirilirsa yanlis alarm dogar).
$mad = @{}
$madde = 0; $serbest = 0
foreach($k in $kayit){
  $ad = "$($k.kaynak_ad)"
  $kn = [regex]::Match($ad, '(?<![\d/])(\d{3,4})\s*(?:s\.|say[ıi]l[ıi])')
  # 28.07 DUZELTME: ilk kosuda 1.436 GERCEK kanun maddesi damga disinda kaldi.
  # Sebep: "Anayasa (2709) gec. m.1" gibi kayitlarda numara PARANTEZ ICINDE ve
  # ardindan "s." / "sayili" GELMIYOR. Desen bunu istiyordu. Sessiz kapsam
  # bosluguydu: o maddeler degisse alarm calmayacakti.
  if(-not $kn.Success){ $kn = [regex]::Match($ad, '\((\d{3,4})\)') }
  $mn = [regex]::Match($ad, '[^a-zA-Z0-9]m\.\s*(\d{1,4})(?!\d)')
  $parca = 0
  $p = [regex]::Match($ad, '\[(\d+)/\d+\]')
  if($p.Success){ $parca = [int]$p.Groups[1].Value }

  if($kn.Success -and $mn.Success){
    # KANUN MADDESI anahtari: sorulardaki atif ("VUK m.234") dogrudan buna baglanir.
    # gec./ek maddeler AYRI seridir; karistirilirsa yanlis alarm dogar.
    $seri = ''
    if($ad -match '(?i)ge[çc]ici\s*m\.?|gec\.\s*m\.'){ $seri = 'gec' }
    elseif($ad -match '(?i)ek\s+m\.'){ $seri = 'ek' }
    $anahtar = "{0}|{1}{2}" -f $kn.Groups[1].Value, $seri, $mn.Groups[1].Value
    $madde++
  } else {
    # 28.07: AYRISTIRAMADIGIM KAYIT DA DAMGASIZ KALMASIN. Standartlar (TMS/TFRS/BDS),
    # tebligler, rehberler kanun-madde kalibina uymuyor ama sorular ONLARA DA
    # dayaniyor. Ayristiramadigim seyi kapsam disi birakmak, tam da gormek
    # istedigim degisikligi gormemek demek. Anahtar = kaynak adinin kendisi
    # ([n/m] parca isareti atilarak, cunku parcalar zaten birlestiriliyor).
    $anahtar = "ad|" + ($ad -replace '\s*\[\d+/\d+\]\s*$','').Trim()
    $serbest++
  }
  if(-not $mad.ContainsKey($anahtar)){ $mad[$anahtar] = New-Object System.Collections.Generic.List[object] }
  $mad[$anahtar].Add([pscustomobject]@{ sira=$parca; ad=$ad; metin="$($k.metin)" })
}
Write-Host ("  anahtar: {0}   (kanun-madde kayit {1} + serbest kayit {2} = {3}, ambarin TAMAMI)" -f $mad.Count, $madde, $serbest, ($madde+$serbest))

# --- her madde icin damga
$yeniTablo = [ordered]@{}
foreach($a in ($mad.Keys | Sort-Object)){
  $sirali = @($mad[$a] | Sort-Object sira)
  $metin = (@($sirali | ForEach-Object { $_.metin }) -join ' ')
  $yeniTablo[$a] = [ordered]@{
    damga = (Damga $metin)
    parca = $sirali.Count
    uzunluk = $metin.Length
    ad = $sirali[0].ad
  }
}

# --- eski damgayla karsilastir
$yol = Join-Path $kok "veri/mevzuat/_madde-damga.json"
$ilkKurulum = -not (Test-Path $yol)
$eski = @{}
if(-not $ilkKurulum){
  $e = Get-Content $yol -Raw -Encoding UTF8 | ConvertFrom-Json
  foreach($p in $e.maddeler.PSObject.Properties){ $eski[$p.Name] = $p.Value }
}

$yeni = @(); $degisen = @(); $kaybolan = @()
foreach($a in $yeniTablo.Keys){
  if(-not $eski.ContainsKey($a)){ $yeni += $a; continue }
  if("$($eski[$a].damga)" -ne "$($yeniTablo[$a].damga)"){
    $degisen += [pscustomobject]@{
      anahtar=$a; ad=$yeniTablo[$a].ad
      eski_damga="$($eski[$a].damga)"; yeni_damga="$($yeniTablo[$a].damga)"
      eski_uzunluk=[int]"$($eski[$a].uzunluk)"; yeni_uzunluk=$yeniTablo[$a].uzunluk
    }
  }
}
foreach($a in $eski.Keys){ if(-not $yeniTablo.Contains($a)){ $kaybolan += $a } }

Write-Host ""
Write-Host "======== MADDE DAMGASI ========"
if($ilkKurulum){
  Write-Host ("  ILK KURULUM: {0} madde damgalandi. Karsilastirma bir sonraki hasattan itibaren." -f $yeniTablo.Count)
} else {
  Write-Host ("  toplam madde : {0}" -f $yeniTablo.Count)
  Write-Host ("  YENI         : {0}" -f $yeni.Count)
  Write-Host ("  DEGISEN      : {0}   <-- bunlara dayanan sorular yayindan cekilmeli" -f $degisen.Count)
  Write-Host ("  KAYBOLAN     : {0}" -f $kaybolan.Count)
  foreach($d in ($degisen | Select-Object -First 25)){
    Write-Host ("    DEGISTI: {0}  ({1} -> {2} karakter)" -f $d.ad, $d.eski_uzunluk, $d.yeni_uzunluk)
  }
}

# --- damga tablosunu yaz
[IO.File]::WriteAllText($yol, ([ordered]@{
  tarih = (Get-Date -Format "dd.MM.yyyy HH:mm")
  aciklama = "Madde bazli parmak izi. Hasat sonrasi karsilastirilir; damgasi degisen maddeye dayanan sorular yayindan cekilir ve GM okur."
  adet = $yeniTablo.Count
  maddeler = $yeniTablo
} | ConvertTo-Json -Depth 5), (New-Object Text.UTF8Encoding($false)))
Write-Host "-> veri/mevzuat/_madde-damga.json"

# --- degisim raporu (Yayin Kapisi bunu okur)
$rapYol = Join-Path $kok "veri/madde-degisim.json"
[IO.File]::WriteAllText($rapYol, ([ordered]@{
  tarih=(Get-Date -Format "dd.MM.yyyy HH:mm"); ilk_kurulum=$ilkKurulum
  yeni=$yeni; degisen=$degisen; kaybolan=$kaybolan
} | ConvertTo-Json -Depth 5), (New-Object Text.UTF8Encoding($false)))
Write-Host "-> veri/madde-degisim.json"

# --- kasadaki sorulari yayindan cekme (kolon gerektirir)
if($uygula -and $degisen.Count -gt 0){
  $var = $false
  try { Invoke-RestMethod -Uri "$SB_URL/rest/v1/soru_havuzu?select=yayin&limit=1" -Headers $H -TimeoutSec 30 | Out-Null; $var = $true } catch { $var = $false }
  if(-not $var){
    Write-Host ""
    Write-Host "UYARI: kasada 'yayin' kolonu YOK - soru yayindan cekilemedi."
    Write-Host "       Rapor yazildi ama KAPI CALISMIYOR. Kolon eklenmeden Katman 4 kurulamaz."
    exit 3
  }
  Write-Host "  (yayindan cekme: kolon var, uygulaniyor)"
  # kanun_no/madde_no kolonlari da gerekli - Katman 1 baglamasi oraya yazilacak
}
exit 0
