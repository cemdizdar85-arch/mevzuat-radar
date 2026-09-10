# ============================================================================
#  DEV PARCA TARAMASI — "hangi belgeler bolunmemis, ne kadar buyuk?"
#
#  NEDEN VAR (10.09.2026). Konu getirme karnesi olculdu: fabrikanin atladigi
#  278 konunun 276'sina madde_ara cevap veriyor AMA 276 cevabin yalniz 114'u
#  tekil belge ve TEK BELGE 110 konuya cevap oluyor:
#      SPK Teblig (Seri: X, No: 22)  ->  43.516 karakter, TEK SATIR
#      SPK Teblig (Seri: V, No: 34) [giris] -> 126.127 karakter, TEK SATIR
#  Dev parca Turkcedeki her yaygin kelimeyi icerir; madde_ara'nin `kapsanan`
#  bonusu (1 + 0.35*(n-1)) onu "cok kelime iceriyor" diye one tasir. Kucuk ve
#  DOGRU madde kaybeder. Bu yuzden "denetci bagimsizligi" ile "onemlilik
#  kavrami" AYNI maddeyi donduruyor.
#
#  Iki ayar kanali da tukendi (olculdu 10.09): sirala-tarti -Dil en iyi +1,
#  -Dene en iyi +1. Yani kusur ON-ISLEMEDE de PUANLAMADA da degil - VERIDE.
#
#  PARCALAYICI KUSURU (motor/spk-mevzuat-yut.ps1):
#    · satir 76-81  [giris] parcasi HIC boy sinirina tabi degil. MADDE regex'i
#                   gec eslesirse giris butun belgeyi yutar.
#    · BolumleriCikar dogru calisiyor (boy=3500) ama madde adi/dilim adi
#      tasimayan CIPLAK satirlar onun elinden cikmis olamaz -> baska bir
#      yoldan girmis dev satirlar var.
#
#  BU ARAC OLCER, ONARMAZ. Salt okuma. Cikti bir IS EMRIDIR: hangi kaynak_ad
#  yeniden parcalanacak, kac karakter, hangi desen.
#
#  NOT - OLCUM TUZAGI (10.09 yasandi): PS 5.1'de
#      @(Invoke-RestMethod ...)   sayfa basina TEK satir donduruyor.
#  Sayfalama Invoke-WebRequest + ConvertFrom-Json ile yapilir; asagida oyle.
#  Ayrica order YALNIZ indeksli kolondan (id) verilir - kaynak_ad'a gore
#  siralama 3 sn'lik statement timeout'a takiliyor (57014).
#
#  CIKTI: veri/dev-parca-taramasi.json
#  KOSMA: powershell -NoProfile -File arac/dev-parca-taramasi.ps1
#         powershell -NoProfile -File arac/dev-parca-taramasi.ps1 -Esik 3500
# ============================================================================
param(
  [int]$Esik = 3500,     # parcalayicinin kendi `boy` degeri; bunu asan parca DEVdir
  [int]$Sayfa = 500,     # tek istekte cekilecek satir
  [int]$FrenMs = 400,
  [int]$EnFazlaOlcum = 1500  # metni olculecek en fazla aday (govde buyur)
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$kok = Split-Path -Parent $PSScriptRoot
$SB  = 'https://bjrleanjpyujtajmazxn.supabase.co'
$KEY = if($env:SB_PUBLISHABLE){ $env:SB_PUBLISHABLE } else { 'sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg' }
$H   = @{ apikey = $KEY; Authorization = "Bearer $KEY" }
$hedef = Join-Path $kok 'veri\dev-parca-taramasi.json'
. (Join-Path $kok 'arac\rapor-yaz.ps1')

function Getir([string]$yol){
  foreach($d in 1..3){
    try {
      $r = Invoke-WebRequest -Uri ($SB + $yol) -Headers $H -UseBasicParsing -UserAgent 'mevzuat-radar-robot/1.0' -TimeoutSec 120
      return ($r.Content | ConvertFrom-Json)
    } catch {
      if($d -eq 3){ throw "GET $yol : $($_.Exception.Message)" }
      Start-Sleep -Seconds (2*$d)
    }
  }
}

# --- 1) BUTUN kaynak_ad'lar (ad ucuz, metin pahali) ------------------------
Write-Host 'Adlar cekiliyor (id sirasiyla)...'
$satir = New-Object System.Collections.ArrayList
$off = 0
while($true){
  $s = @(Getir ("/rest/v1/dokumanlar?select=id,tur,kaynak_ad&order=id&limit=$Sayfa&offset=$off") | ForEach-Object { $_ })
  if($s.Count -eq 0){ break }
  foreach($x in $s){ [void]$satir.Add($x) }
  $off += $Sayfa
  if($satir.Count % 5000 -lt $Sayfa){ Write-Host ("  {0:N0} ..." -f $satir.Count) }
  Start-Sleep -Milliseconds $FrenMs
}
Write-Host ("Toplam satir: {0:N0}" -f $satir.Count)

# --- 2) Ad desenine gore sinifla -------------------------------------------
# madde adli  : "... m.12", "gec. m.3", "ek m.1", "muk. m.5"  -> parcalanmis
# dilim adli  : "... [3/17]"                                   -> parcalanmis
# [giris]     : ilk maddeden onceki metin                      -> SINIRSIZ, sanik
# ciplak      : hicbiri                                        -> hic bolunmemis, sanik
$rxMadde = '\s(?:muk\.\s*m\.|ek\s*gec\.\s*m\.|ek\s*m\.|gec\.\s*m\.|m\.)\s*\d'
$rxDilim = '\[\d+/\d+\]\s*$'
$rxGiris = '\[giris\]\s*$'

# 10.09 ODAKLAMA (ilk kosuda ogrenildi): ilk tarama saniklari id sirasiyla
# aldi ve orneklem CIKMIS SINAV kitapciklarina takildi - 57 dev parcanin
# neredeyse hepsi tek satirlik sinav kitapcigiydi (en buyugu 123.627 krk).
# Onlar GERCEKTEN dev, ama madde_ara zaten `tur not like 'cikmis%'` ile
# ELIYOR - yani aramayi bozmuyorlar. Olcum, aramanin GORDUGU satirlara
# odaklanmazsa gercek miknatisi hic gormeden dolar.
# Ayrica konum eki YALNIZ 'm.X' degil: kaynak-kok.ps1'in kendi listesi
# p.12 · p.A95 · ilke · bolum 2 · kisim 1 eklerini de parcalanmis sayar.
# O ekleri saymayan siniflandirici 16.699 "ciplak" uretiyordu - sisik.
$rxKonum = '\s(?:p\.\s*[A-Za-z0-9]|ilke|b[oö]l[uü]m\s*\d|k[iı]s[iı]m\s*\d)'

$sanik = New-Object System.Collections.ArrayList
$girisler = New-Object System.Collections.ArrayList
$sayac = @{ madde=0; dilim=0; giris=0; ciplak=0; cikmis_haric=0 }
foreach($x in $satir){
  $ad = "$($x.kaynak_ad)"
  # madde_ara'nin gormedigi turler olcume girmez - onlarin buyuklugu SIRALAMAYI
  # bozmaz (ayri bir is: soru fabrikasi onlari okuyor, o baska olcum).
  if("$($x.tur)" -like 'cikmis*'){ $sayac.cikmis_haric++; continue }
  if($ad -match $rxGiris){ $sayac.giris++; [void]$girisler.Add($x); continue }
  if($ad -match $rxDilim){ $sayac.dilim++; continue }
  if($ad -match $rxMadde -or $ad -match $rxKonum){ $sayac.madde++; continue }
  $sayac.ciplak++; [void]$sanik.Add($x)
}
# [giris] parcalari EN ONE alinir: miknatisin iki ornegi de oradan cikti.
$sanik.InsertRange(0, $girisler)
Write-Host ("  madde adli {0:N0} · dilim adli {1:N0} · [giris] {2:N0} · CIPLAK {3:N0}" -f $sayac.madde,$sayac.dilim,$sayac.giris,$sayac.ciplak)
Write-Host ("  olculecek sanik: {0:N0}" -f $sanik.Count)

# --- 3) Yalniz saniklarin metin uzunlugu -----------------------------------
# Metin cekmek pahalidir; bu yuzden SADECE sanik satirlar, id ile tek tek
# degil KUMELE cekilir (id=in.(...)) ve kume kucuk tutulur - dev metinler
# govdeyi sisirir.
$olcum = New-Object System.Collections.ArrayList
$aday = @($sanik | Select-Object -First $EnFazlaOlcum)
if($sanik.Count -gt $EnFazlaOlcum){ Write-Host ("  UYARI: sanik {0:N0} > tavan {1:N0} - olcum ILK {1:N0} ile sinirli, sonuc ALT SINIRDIR" -f $sanik.Count,$EnFazlaOlcum) -ForegroundColor Yellow }
$kume = 15; $i = 0
while($i -lt $aday.Count){
  $dilim2 = @($aday[$i..([Math]::Min($i+$kume-1,$aday.Count-1))])
  $idler = ($dilim2 | ForEach-Object { $_.id }) -join ','
  $s = @(Getir ("/rest/v1/dokumanlar?select=id,kaynak_ad,metin&id=in.($idler)") | ForEach-Object { $_ })
  foreach($x in $s){
    [void]$olcum.Add([pscustomobject]@{ id=$x.id; kaynak_ad="$($x.kaynak_ad)"; uzunluk="$($x.metin)".Length })
  }
  $i += $kume
  if($i % 300 -lt $kume){ Write-Host ("  metin {0}/{1} ..." -f $i,$aday.Count) }
  Start-Sleep -Milliseconds $FrenMs
}

$dev = @($olcum | Where-Object { $_.uzunluk -gt $Esik } | Sort-Object uzunluk -Descending)
$topKarakter = ($dev | Measure-Object uzunluk -Sum).Sum

$cikti = [ordered]@{
  olcum   = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  aciklama= "Bolunmemis DEV parcalar. Esik = parcalayicinin kendi boy degeri ($Esik krk). Bu satirlar aramada MIKNATIS gibi calisiyor: her yaygin kelimeyi icerdikleri icin alakasiz sorgularda birinci geliyorlar."
  esik    = $Esik
  kapsam  = [ordered]@{
    toplam_satir   = $satir.Count
    madde_adli     = $sayac.madde
    dilim_adli     = $sayac.dilim
    giris_parcasi  = $sayac.giris
    ciplak         = $sayac.ciplak
    metni_olculen  = $olcum.Count
    olcum_tavani   = $EnFazlaOlcum
    tam_mi         = $(if($sanik.Count -le $EnFazlaOlcum){ 'TAM' } else { "KISMI - sanik $($sanik.Count), olculen $($olcum.Count); sonuc ALT SINIR" })
  }
  ozet    = [ordered]@{
    dev_parca_sayisi = $dev.Count
    dev_toplam_karakter = $topKarakter
    en_buyuk = $(if($dev.Count){ $dev[0].uzunluk } else { 0 })
    ortanca  = $(if($dev.Count){ ($dev | Sort-Object uzunluk)[[int]($dev.Count/2)].uzunluk } else { 0 })
  }
  is_emri = @($dev | Select-Object -First 200)
}
$yazildi = RaporYaz -Hedef $hedef -Nesne $cikti -ZamanAlanlari @('olcum')

Write-Host ''
Write-Host ("DEV PARCA: {0} satir > {1} krk  (toplam {2:N0} karakter)" -f $dev.Count,$Esik,$topKarakter)
if($dev.Count){
  Write-Host '--- en buyuk 10 ---'
  $dev | Select-Object -First 10 | ForEach-Object { Write-Host ("  {0,9:N0} krk  {1}" -f $_.uzunluk, $_.kaynak_ad.Substring(0,[Math]::Min(72,$_.kaynak_ad.Length))) }
}
if($yazildi){ Write-Host '  -> veri/dev-parca-taramasi.json yazildi' } else { Write-Host '  -> icerik ayni, dosyaya dokunulmadi' }
