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
    # BULTEN DAMGASI (30.08): kaydin hangi gunun bulteninden geldigi. Kaynaktan
    # okunur (ayristirici), burada yalniz tasinir. Bos gecerse tabloda NULL
    # kalir ve ihale_sayi().damgasiz sayaci bunu gorunur kilar.
    bulten_tarih     = $(if("$($x.bultenTarih)".Trim()){ "$($x.bultenTarih)".Trim() } else { $null })
    bulten_sayi      = (Tam $x.bultenSayi)
  })
}
# ayni anahtardan iki kayit varsa sonuncusu gecerlidir (havuz kurali)
# TUZAK (olculdu 20.08): PowerShell'in hashtable/ordered sozlugu BUYUK-KUCUK HARF
# AYIRMAZ; Postgres'in text karsilastirmasi ayirir. "...LIMITED SIRKETI" ile
# "...Limited Sirketi" iki AYRI kayitken sozlukte tek anahtara duserler ve biri
# sessizce dusurulur. 45.410 gonderilirken kasada 45.411 cikmasinin sebebi buydu:
# fark bir kayitti ama sessizdi. Ordinal (harf duyarli) sozluk kullanilir.
$tekil = New-Object 'System.Collections.Generic.Dictionary[string,object]' ([StringComparer]::Ordinal)
foreach ($h in $hazir) { $tekil[$h.anahtar] = $h }
$gonderilecek = @($tekil.Values)
Write-Host ("HAZIR : {0:N0} tekil kayit (anahtarsiz atlanan: {1})" -f $gonderilecek.Count, $anahtarsiz)

if ($Olc) { Write-Host "`n(olcum modu - hicbir sey yazilmadi)"; exit 0 }

# --- GOC KAPISI (30.08) -----------------------------------------------------
# 2026-08-30-ihale-bulten-kutugu.sql basilmadan yazmak, damgasiz kayit uretir.
# 36 aylik yutmayi damgasiz kosmak = 775.000 kaydin uzerine "hangi gunden
# geldigini bilmiyorum" yazmak; ikinci kez yutmak gerekir. Bu yuzden kapi.
# Olcut: ihale_sayi() cevabinda 'damgasiz' alani VAR MI. Eski surumde yok.
# (kalici-sigorta 4. katman: kapi neden dustugunu SOYLER)
try {
  $on = @(RpcCagir 'ihale_sayi' @{})[0]
  if ($null -eq $on.PSObject.Properties['damgasiz']) {
    Write-Host ''
    Write-Host '!! DURDURULDU: bulten kutugu gocu Supabase-e BASILMAMIS.'
    Write-Host '   Kanit: ihale_sayi() cevabinda "damgasiz" alani yok (eski surum).'
    Write-Host '   Yapilacak: Supabase SQL Editor -> radar-app/sql/2026-08-30-ihale-bulten-kutugu.sql'
    Write-Host '              (BOLUM BOLUM calistir, sonra bu betigi tekrar kos)'
    Write-Host '   Neden kapi: damgasiz yazilan kayit hangi gunden geldigini soylemez;'
    Write-Host '               36 aylik yutma bu haliyle bastan tekrar edilmek zorunda kalir.'
    exit 1
  }
  Write-Host ("GOC KAPISI: acik · kasada {0:N0} kayit, {1:N0} tanesi damgasiz" -f [int]$on.kayit, [int]$on.damgasiz)
} catch {
  Write-Host ("!! GOC KAPISI olculemedi: {0}" -f $_.Exception.Message)
  exit 1
}

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

# --- KUTUGE CENTIK (30.08) --------------------------------------------------
# "Hangi bulten cekildi" sorusunun tek cevabi kasadaki ihale_kutuk olacak.
# Centik YAZMA BASARILI OLDUKTAN SONRA atilir - once kutuge yazip sonra
# yuklemede patlamak, tam da bu goce sebep olan yalani uretir (yerel kutuk
# 4 gun diyordu, kasada 62+ gun vardi).
# Yalniz VARSAYILAN kaynak yuklenirken atilir: $env:HEDEF ile baska bir
# ambar yuklenirken elimizdeki damga o ambara ait DEGILDIR.
$damgaYol = Join-Path $kok 'veri\ihale-son-kosu-damga.json'
if (-not "$($env:HEDEF)".Trim() -and (Test-Path $damgaYol)) {
  try {
    $damgalar = @(Get-Content $damgaYol -Raw -Encoding UTF8 | ConvertFrom-Json)
    $c = 0
    foreach ($d in $damgalar) {
      if (-not $d.tarih) {
        Write-Host ("  kutuk atlandi ({0}): bulten tarihi kaynaktan okunamadi" -f $d.tur)
        continue
      }
      RpcCagir 'ihale_kutuk_yaz' @{
        p_gun         = "$($d.tarih)"
        p_tur         = "$($d.tur)"
        p_bulten_sayi = (Tam $d.sayi)
        p_kayit       = (Tam $d.kayit)
        p_beklenen    = (Tam $d.beklenen)
        p_bulunan     = (Tam $d.bulunan)
        p_eksik_ikn   = @($d.eksikIkn)
        p_bos_sebep   = "$($d.sebep)"
      } | Out-Null
      $c++
      Write-Host ("  kutuk: {0} · {1,-12} · beklenen {2} / bulunan {3} · {4}" -f `
                  $d.tarih, $d.tur, $d.beklenen, $d.bulunan, $(if($d.tam){'TAM'}else{'EKSIK'}))
    }
    Write-Host ("KUTUK: {0} (gun,tur) satiri yazildi" -f $c)
  } catch {
    Write-Host ("!! kutuge yazilamadi: {0}" -f $_.Exception.Message)
    exit 1
  }
}
