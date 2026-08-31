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
# Parti 400 -> 250 (30.08): 275.000 satirlik tabloda 400'luk upsert yuk altinda
# statement timeout'a dusuyordu. Kucuk parti = kisa islem = daha az zaman asimi.
param([switch]$Olc, [int]$Parti = 250)
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

# IS KLASORU (30.08): paralel seritler ayni ara dosyalari eziyordu. Ayristirici
# gunluk havuzu ve kosu damgasini buraya yaziyor, yukleyici buradan okuyor.
# Verilmezse eski davranis aynen (kok\veri).
$isKls = if ("$($env:IHALE_IS_KLASORU)".Trim()) { $env:IHALE_IS_KLASORU } else { Join-Path $kok 'veri' }

$hedef = if ("$($env:HEDEF)".Trim()) {
  # HEDEF tam yol da olabilir (baska calisma kopyasindaki ambari yuklerken)
  if ([IO.Path]::IsPathRooted($env:HEDEF)) { $env:HEDEF } else { Join-Path $kok $env:HEDEF }
} else { Join-Path $isKls 'ihale-sonuc.json' }
$damgaYol = Join-Path $isKls 'ihale-son-kosu-damga.json'

# KAYIT YOKSA DA CIKILMAZ: resmi tatilde hicbir is kolunda bulten cikmiyor,
# havuz dosyasi hic olusmuyor. Eskiden burada "kaynak dosya yok" deyip
# cikiliyordu ve kutuge tek satir yazilmadigi icin o gunler sonsuza kadar
# "hic cekilmedi" kaliyordu. Artik bayrak konur, kutuk yine yazilir.
$kaynakVar = (Test-Path $hedef)
$kayitlar = @()
if ($kaynakVar) {
  Write-Host ("KAYNAK: {0} ({1:N1} MB)" -f (Split-Path $hedef -Leaf), ((Get-Item $hedef).Length/1MB))
  $kayitlar = @((Get-Content $hedef -Raw -Encoding UTF8 | ConvertFrom-Json).sonuclar)
  Write-Host ("        {0:N0} sonuc ilani" -f $kayitlar.Count)
} else {
  Write-Host ("KAYNAK YOK: {0} - bu gun hicbir is kolunda kayit uretilmedi" -f (Split-Path $hedef -Leaf))
}

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
# 🔴 30.08 OLCUMU: Invoke-RestMethod tek satirlik JSON dizisini ACMADAN
# akitiyor; @(...)[0] o zaman SATIRI degil, iceren DIZIYI verir.
# $r.kayit yine calisir (PowerShell uye numaralandirmasi diziye de uygulanir)
# ama $r.PSObject.Properties['damgasiz'] calismaz - PSObject dizinin kendisine
# aittir. Goc kapisi tam bu yuzden basili gocu "basilmamis" sandi ve provanin
# iki gunu de dustu. Bir kat duzlestirip ILK SATIRI donduruyoruz.
function IlkSatir($cevap) {
  foreach ($z in $cevap) {
    if ($z -is [Array]) { foreach ($y in $z) { return $y } }
    else { return $z }
  }
  return $null
}
# 🔴 30.08 OLCUMU - PAHALI KAPI 419 GUNU DUSURDU:
# Goc kapisi ve geri okuma her gun icin ihale_sayi() cagiriyordu. O fonksiyon
# ihale_sonuc_v uzerinden calisiyor; gorunum IKN'e gore pencere fonksiyonu
# tasiyor ve ustune count(distinct ikn) var. Havuz 275.000 satira cikip alti
# serit birden sordugunda uc HTTP 500 dondurmeye basladi:
#   "!! GOC KAPISI olculemedi: (500) Ic Sunucu Hatasi" -> o gun HIC yazilmadi.
# 783 gunun 419'u boyle dustu. Bozulma olmadi (kapi yazmadan ONCE calisiyor)
# ama yutmanin yarisindan cogu bosa gitti.
# DERS: her yazmada calisan kapi, kasanin en pahali sorgusu OLAMAZ.
# Kapi artik tek satirlik varlik yoklamasi; sayim da GORUNUM yerine TABLO
# uzerinden (Content-Range) aliniyor.
function Yokla([string]$yol) {
  return Invoke-WebRequest -UseBasicParsing -Method Get -Uri "$SB_URL/rest/v1/$yol" `
           -Headers $basliklar -TimeoutSec 120
}
function TabloSay([string]$tablo) {
  $b = $basliklar.Clone(); $b['Prefer'] = 'count=exact'
  $c = Invoke-WebRequest -UseBasicParsing -Method Get -Uri "$SB_URL/rest/v1/$tablo`?select=anahtar&limit=1" `
         -Headers $b -TimeoutSec 180
  if ("$($c.Headers['Content-Range'])" -match '/(\d+)$') { return [int]$Matches[1] }
  return -1
}
function Sayi([object]$v) {
  if ($null -eq $v -or "$v".Trim() -eq '') { return $null }
  $d = 0.0
  if ([double]::TryParse("$v", [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$d)) { return $d }
  return $null
}
# 🔴 TAMAMEN BOS GUN KUTUGE HIC YAZILMIYORDU (31.08 olculdu):
# Resmi tatillerde HICBIR is kolunda bulten cikmiyor. O gun ayristirici kayit
# uretmiyor, veri\ihale-sonuc.json hic olusmuyor ve bu betik en basta
# "kaynak dosya yok" deyip cikiyordu - kutuge tek satir bile yazilmadan.
# Sonuc: ~34 gun x 4 is kolu = 136 (gun,is kolu) sonsuza kadar "hic cekilmedi"
# kaliyor, her turda yeniden indiriliyor ve hicbir zaman tamamlanmiyordu.
# Kutuk yazimi artik AYRI bir islev; kayit olsa da olmasa da calisiyor.
# "Cekildi, bostu" ile "hic cekilmedi" ayrimi kutugun kurulus sebebiydi;
# tamamen bos gun bu ayrimin en uc halidir.
function KutugeYaz($gonderilecek) {
  if ("$($env:HEDEF)".Trim()) { return }          # baska ambar yukleniyor
  if (-not (Test-Path $damgaYol)) { return }
  try {
    $damgaHam = ConvertFrom-Json -InputObject (Get-Content $damgaYol -Raw -Encoding UTF8)
    $damgalar = @($damgaHam)
    $turSayim = New-Object 'System.Collections.Generic.Dictionary[string,int]' ([StringComparer]::Ordinal)
    foreach ($g in @($gonderilecek)) {
      $tt = "$($g.tur)"
      if ($tt) { if ($turSayim.ContainsKey($tt)) { $turSayim[$tt] += 1 } else { $turSayim[$tt] = 1 } }
    }
    $c = 0
    foreach ($d in $damgalar) {
      $gun = "$($d.tarih)"
      if (-not $gun) {
        $istenen = "$($env:IHALE_ISTENEN_GUN)".Trim()
        if ($istenen -and "$($d.sebep)" -eq 'bulten yok/bos') {
          $gun = $istenen
          Write-Host ("  kutuk: {0} · {1,-12} · bulten YOK (bos gun, tam sayiliyor)" -f $gun, $d.tur)
        } else {
          Write-Host ("  kutuk atlandi ({0}): bulten tarihi okunamadi, sebep '{1}'" -f $d.tur, $d.sebep)
          continue
        }
      }
      $bek = (Tam $d.beklenen); $bul = (Tam $d.bulunan)
      if (-not $d.tarih) { $bek = 0; $bul = 0 }
      RpcCagir 'ihale_kutuk_yaz' @{
        p_gun         = $gun
        p_tur         = "$($d.tur)"
        p_bulten_sayi = (Tam $d.sayi)
        p_kayit       = $(if ($turSayim.ContainsKey("$($d.tur)")) { $turSayim["$($d.tur)"] } else { 0 })
        p_beklenen    = $bek
        p_bulunan     = $bul
        p_eksik_ikn   = @($d.eksikIkn)
        p_bos_sebep   = "$($d.sebep)"
      } | Out-Null
      $c++
      if ($d.tarih) {
        Write-Host ("  kutuk: {0} · {1,-12} · beklenen {2} / bulunan {3} · {4}" -f `
                    $gun, $d.tur, $bek, $bul, $(if($d.tam){'TAM'}else{'EKSIK'}))
      }
    }
    Write-Host ("KUTUK: {0} (gun,tur) satiri yazildi" -f $c)
  } catch {
    Write-Host ("!! kutuge yazilamadi: {0}" -f $_.Exception.Message)
    exit 1
  }
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
# Olcut: bulten_tarih KOLONU kasada var mi (tek satirlik yoklama).
# (kalici-sigorta 4. katman: kapi neden dustugunu SOYLER)
try {
  # 🔴 KAPI YANLIS TESHIS KOYUYORDU (30.08, prova sirasinda olculdu):
  # ilk surumde "istek dustu" = "goc basilmamis" sayiliyordu. Kasa yuk altinda
  # zaman asimina dusunce kapi "BASILMAMIS" diye BAGIRDI - oysa goc basiliydi.
  # Yanlis teshis koyan kapi, kapi olmaktan cikar; insan ona inanip bosuna
  # SQL'e gider. Iki hal AYRILIR:
  #   404 / PGRST205  -> tablo yok  = goc GERCEKTEN basilmamis
  #   diger her hata  -> OLCULEMEDI = kasa mesgul; farkli mesaj, farkli tavsiye
  # Yoklama en KUCUK tablodan yapilir (ihale_kutuk ~1.100 satir), ihale_sonuc'tan
  # degil; 275.000 satirlik tabloya dokunan her sorgu yuk altinda zaman asimina
  # dusuyor. Ucuncu bir savunma: uc deneme, artan bekleme.
  $kolonVar = $false; $tabloYok = $false; $sonHataK = ''
  for ($dn = 1; $dn -le 3 -and -not $kolonVar; $dn++) {
    try { Yokla 'ihale_kutuk?select=gun&limit=1' | Out-Null; $kolonVar = $true }
    catch {
      $sonHataK = $_.Exception.Message
      $kod = 0
      if ($_.Exception.Response) { $kod = [int]$_.Exception.Response.StatusCode }
      if ($kod -eq 404 -or $kod -eq 400) { $tabloYok = $true; break }
      if ($dn -lt 3) { Start-Sleep -Seconds (5 * $dn) }
    }
  }
  if (-not $kolonVar -and -not $tabloYok) {
    Write-Host ''
    Write-Host '!! OLCULEMEDI: kasa yanit vermedi, goc basili mi anlasilamadi.'
    Write-Host ("   Son hata: {0}" -f $sonHataK)
    Write-Host '   Bu "goc basilmamis" DEMEK DEGILDIR - kasa mesgul olabilir.'
    Write-Host '   Yapilacak: birazdan tekrar kos. Surekli tekrar ediyorsa serit'
    Write-Host '              sayisini dusur (ayni anda daha az yazma).'
    exit 1
  }
  if ($tabloYok) {
    Write-Host ''
    Write-Host '!! DURDURULDU: bulten kutugu gocu Supabase-e BASILMAMIS.'
    Write-Host '   Kanit: ihale_kutuk tablosu kasada yok (404/400).'
    Write-Host '   Yapilacak: Supabase SQL Editor -> radar-app/sql/2026-08-30-ihale-bulten-kutugu.sql'
    Write-Host '              (BOLUM BOLUM calistir, sonra bu betigi tekrar kos)'
    Write-Host '   Neden kapi: damgasiz yazilan kayit hangi gunden geldigini soylemez;'
    Write-Host '               36 aylik yutma bu haliyle bastan tekrar edilmek zorunda kalir.'
    exit 1
  }
  Write-Host 'GOC KAPISI: acik (ihale_kutuk tablosu var)'
} catch {
  Write-Host ("!! GOC KAPISI olculemedi: {0}" -f $_.Exception.Message)
  exit 1
}

# Yazilacak kayit yok ama gun ISLENDI: kutuge "bu gun bostu" satirlari yazilir
# ve gun tamamlanir. Yoksa her turda yeniden indirilir, hicbir zaman bitmez.
if (-not $kaynakVar -or -not $kayitlar.Count) {
  KutugeYaz @()
  exit 0
}

# --- parti parti yaz --------------------------------------------------------
$yazilan = 0; $hatali = 0
for ($i = 0; $i -lt $gonderilecek.Count; $i += $Parti) {
  $son   = [Math]::Min($i + $Parti - 1, $gonderilecek.Count - 1)
  $parca = @($gonderilecek[$i..$son])
  # YENIDEN DENEME (30.08 olculdu): kasa yuk altinda gecici olarak 500 /
  # 57014 (statement timeout) donduruyor. Ayni parti 20 sn sonra sorunsuz
  # geciyor. Tek denemede birakmak, 783 gunluk kosuda yuzlerce gunu bosa
  # dusuruyordu. Uc deneme, artan bekleme.
  $denendi = 0; $gecti = $false; $sonHata = ''
  while (-not $gecti -and $denendi -lt 3) {
    $denendi++
    try {
      $n = RpcCagir 'ihale_yaz' @{ p_kayitlar = $parca }
      $yazilan += [int]$n
      $gecti = $true
    } catch {
      $sonHata = $_.Exception.Message
      if ($denendi -lt 3) { Start-Sleep -Seconds (5 * $denendi) }
    }
  }
  if (-not $gecti) {
    $hatali += $parca.Count
    Write-Host ("  ! parti {0}-{1} UC denemede de dustu: {2}" -f $i, $son, $sonHata)
  } elseif ($denendi -gt 1) {
    Write-Host ("  ~ parti {0}-{1} {2}. denemede gecti" -f $i, $son, $denendi)
  }
  if ((($i / $Parti) % 10) -eq 0) { Write-Host ("  ... {0:N0}/{1:N0}" -f ($son+1), $gonderilecek.Count) }
}
Write-Host ("`nYAZILAN: {0:N0} · dusen: {1:N0}" -f $yazilan, $hatali)

# --- GERI OKU (yesil kosu = tam veri degildir) ------------------------------
# 🔴 30.08 - HER YAZMADA TAM SAYIM YAPILMAZ (iki kez olculdu):
#   ihale_sayi()          -> gorunumde pencere fonksiyonu + count(distinct) -> 500
#   count=exact (tablo)   -> 57014 "canceling statement due to statement timeout"
# 275.000 satirda tam sayim kasanin tahammulunu asiyor; her gun cagrilinca
# 783 gunun 419'unu dusurdu. Sayima IHTIYAC DA YOK: ihale_yaz zaten kac satir
# yazdigini donduruyor. Dogrulama artik yazanin kendi raporundan.
# Havuz butunlugu gun gun degil, SONDA ihale_kutuk_denetim() ile olculur -
# pahali sorgu tek sefer kosar, her yazmada degil.
if ($hatali -gt 0) {
  Write-Host ("!! {0:N0} kayit dusen partilerde kaldi - kutuge centik atilmiyor" -f $hatali)
  exit 1
}
if ($yazilan -lt $gonderilecek.Count) {
  Write-Host ("!! EKSIK: gonderilen {0:N0}, kasanin kabul ettigi {1:N0}" -f $gonderilecek.Count, $yazilan)
  exit 1
}
Write-Host ("GERI OKUMA: kasa {0:N0} kaydi kabul etti (gonderilen {1:N0})" -f $yazilan, $gonderilecek.Count)

# --- KUTUGE CENTIK ----------------------------------------------------------
# "Hangi bulten cekildi" sorusunun tek cevabi kasadaki ihale_kutuk.
# Centik YAZMA BASARILI OLDUKTAN SONRA atilir - once kutuge yazip sonra
# yuklemede patlamak, tam da bu goce sebep olan yalani uretir.
# Govde KutugeYaz islevine tasindi (31.08): kayit uretilmeyen gunlerde de
# calismasi gerekiyor, o yuzden tek yerde durup iki yerden cagriliyor.
KutugeYaz $gonderilecek