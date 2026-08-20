# ============================================================================
#  IHALE SONUC ARSIVI -> SUPABASE  (20.08.2026, Cem: "kimse gormesin")
#
#  NIYE: veri/ihale-sonuc.json public depoda ACIK duruyordu. 20 is gunluk
#  backfill'den sonra 28,2 MB - icinde 24.043 sonuc ilani, 6.844 firma, 3.681
#  idare ve kirim gecmisi, yani "bu is gercekte kaca yapiliyor" kartinin
#  TAMAMI. Arsiv artik yalniz Supabase'de durur (RLS acik, policy YOK);
#  siteye giden 251 KB'lik OZET dosyasi public kalir.
#
#  KULLANIM
#    ilk tam yukleme :  ./motor/ihale-supabase-yukle.ps1
#    baska kaynaktan :  $env:HEDEF='veri\ihale-sonuc.json'; ./motor/ihale-supabase-yukle.ps1
#    olcum modu      :  ./motor/ihale-supabase-yukle.ps1 -Olc     (hicbir sey yazmaz)
#
#  Anahtar: SUPABASE_SERVICE_KEY (User-env ya da Actions secret). YOKSA betik
#  "atlandi" der ve 0 ile cikar - sebebini ekrana yazar (kor kalma kurali).
#
#  YAZMA ANAHTARI ayristiricinin havuz anahtarinin AYNISI olmali:
#    ikn | sozlesmeTarih | sozlesmeBedeli | yuklenici
#  (ilk surumde anahtar yalniz IKN'di ve kisimli ihalenin her kismi digerini
#  eziyordu: 1.395 kayit ayristirilip havuza 469 yazilmisti.)
#
#  kirimYuzde GONDERILMEZ. O bir turetim; Supabase tarafinda ihale_sonuc_v
#  gorunumu TUM HAVUZ uzerinden hesaplar. Gun-ici hesap 1.133 kaydi yanlis
#  olcmustu; ayni tuzagi tabloya tasimayalim.
# ============================================================================
param([switch]$Olc, [int]$Parti = 400)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here

$SB_URL = 'https://bjrleanjpyujtajmazxn.supabase.co'
$anahtar = "$($env:SUPABASE_SERVICE_KEY)".Trim()
if (-not $anahtar) {
  Write-Host 'ATLANDI: SUPABASE_SERVICE_KEY yok - arsiv Supabase-e yazilmadi.'
  Write-Host '         Yerelde: anahtar-kur.cmd  |  Actions: repo Secrets -> SUPABASE_SERVICE_KEY'
  exit 0
}

$hedef = if ("$($env:HEDEF)".Trim()) {
  # HEDEF tam yol da olabilir (baska calisma kopyasindaki ambari yuklerken)
  if ([IO.Path]::IsPathRooted($env:HEDEF)) { $env:HEDEF } else { Join-Path $kok $env:HEDEF }
} else { Join-Path $kok 'veri\ihale-sonuc.json' }
if (-not (Test-Path $hedef)) { Write-Host "kaynak dosya yok: $hedef"; exit 0 }

Write-Host ("KAYNAK: {0} ({1:N1} MB)" -f (Split-Path $hedef -Leaf), ((Get-Item $hedef).Length/1MB))
$kayitlar = @((Get-Content $hedef -Raw -Encoding UTF8 | ConvertFrom-Json).sonuclar)
if (-not $kayitlar.Count) { Write-Host 'kaynakta sonuc ilani yok - cikiliyor'; exit 0 }
Write-Host ("        {0:N0} sonuc ilani" -f $kayitlar.Count)

$basliklar = @{
  'apikey'        = $anahtar
  'Authorization' = "Bearer $anahtar"
  'Content-Type'  = 'application/json'
  'Accept'        = 'application/json'
  'User-Agent'    = 'MevzuatRadar-IhaleYukleyici'
}
function RpcCagir([string]$ad, $govde) {
  $json = $govde | ConvertTo-Json -Depth 8 -Compress
  Invoke-RestMethod -Method Post -Uri "$SB_URL/rest/v1/rpc/$ad" `
    -Headers $basliklar -Body ([Text.Encoding]::UTF8.GetBytes($json)) -TimeoutSec 300
}
function Sayi([object]$v) {
  if ($null -eq $v -or "$v".Trim() -eq '') { return $null }
  $d = 0.0
  if ([double]::TryParse("$v", [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$d)) { return $d }
  return $null
}
function Tam([object]$v) {
  $d = Sayi $v
  if ($null -eq $d) { return $null }
  return [int]$d
}

# --- kayitlari tabloya uygun sekle getir -----------------------------------
$hazir = New-Object Collections.ArrayList
$anahtarsiz = 0
foreach ($x in $kayitlar) {
  if (-not $x.ikn) { $anahtarsiz++; continue }
  $ah = "{0}|{1}|{2}|{3}" -f $x.ikn, $x.sozlesmeTarih, $x.sozlesmeBedeli, $x.yuklenici
  [void]$hazir.Add([ordered]@{
    anahtar          = $ah
    ikn              = "$($x.ikn)"
    tur              = "$($x.tur)"
    is_adi           = "$($x.isAdi)"
    idare            = "$($x.idare)"
    ihale_tarih      = "$($x.ihaleTarih)"
    ihale_turu       = "$($x.ihaleTuru)"
    usul             = "$($x.usul)"
    yaklasik_maliyet = (Sayi $x.yaklasikMaliyet)
    ym_birim         = "$($x.ymBirim)"
    sb_birim         = "$($x.sbBirim)"
    dokuman_indiren  = (Tam $x.dokumanIndiren)
    teklif_sayisi    = (Tam $x.teklifSayisi)
    gecerli_teklif   = (Tam $x.gecerliTeklif)
    yerli_avantaj    = "$($x.yerliAvantaj)"
    sozlesme_tarih   = "$($x.sozlesmeTarih)"
    sozlesme_bedeli  = (Sayi $x.sozlesmeBedeli)
    yuklenici        = "$($x.yuklenici)"
    kisim_kaniti     = [bool]$x.kisimKaniti
  })
}
# ayni anahtardan iki kayit varsa sonuncusu gecerlidir (havuz kurali)
$tekil = [ordered]@{}
foreach ($h in $hazir) { $tekil[$h.anahtar] = $h }
$gonderilecek = @($tekil.Values)
Write-Host ("HAZIR : {0:N0} tekil kayit (anahtarsiz atlanan: {1})" -f $gonderilecek.Count, $anahtarsiz)

if ($Olc) { Write-Host "`n(olcum modu - hicbir sey yazilmadi)"; exit 0 }

# --- parti parti yaz --------------------------------------------------------
$yazilan = 0; $hatali = 0
for ($i = 0; $i -lt $gonderilecek.Count; $i += $Parti) {
  $son   = [Math]::Min($i + $Parti - 1, $gonderilecek.Count - 1)
  $parca = @($gonderilecek[$i..$son])
  try {
    $n = RpcCagir 'ihale_yaz' @{ p_kayitlar = $parca }
    $yazilan += [int]$n
  } catch {
    $hatali += $parca.Count
    Write-Host ("  ! parti {0}-{1} dustu: {2}" -f $i, $son, $_.Exception.Message)
  }
  if ((($i / $Parti) % 10) -eq 0) { Write-Host ("  ... {0:N0}/{1:N0}" -f ($son+1), $gonderilecek.Count) }
}
Write-Host ("`nYAZILAN: {0:N0} · dusen: {1:N0}" -f $yazilan, $hatali)

# --- GERI OKU (yesil kosu = tam veri degildir) ------------------------------
try {
  $s = RpcCagir 'ihale_sayi' @{}
  $r = @($s)[0]
  Write-Host ("GERI OKUMA: kayit {0:N0} · tekil IKN {1:N0} · kirim olculen {2:N0} · kisimli {3:N0}" -f `
              [int]$r.kayit, [int]$r.tekil_ikn, [int]$r.olculen, [int]$r.kisimli)
  if ([int]$r.kayit -lt $gonderilecek.Count) {
    Write-Host ("!! EKSIK: gonderilen {0:N0}, tabloda {1:N0}" -f $gonderilecek.Count, [int]$r.kayit)
    exit 1
  }
} catch {
  Write-Host ("!! geri okuma yapilamadi: {0}" -f $_.Exception.Message)
  exit 1
}
