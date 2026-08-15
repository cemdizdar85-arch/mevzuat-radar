# ============================================================================
#  SONUC ILANLARINDAN OZET URET (14.08.2026)
#
#  Cem: "kartlara bagla".
#
#  NEDEN OZET, HAM VERI DEGIL:
#  ihale-sonuc.json 1,7 MB. Sayfa her acilista bunu indirseydi mobilde agir
#  olurdu ve ihale kartlarinin hicbiri o verinin tamamina ihtiyac duymuyor.
#  Kart yalnizca su uc soruya cevap ariyor:
#     "bu isi kim, kaca aldi" · "kirim ne kadar oluyor" · "kac kisi giriyor"
#  Bu yuzden ham kayit sitede degil ambarda kalir; siteye KUCUK ozet gider.
#
#  RAKAM DISIPLINI: her sayi OLCULEN kayitlardan gelir. Kirimi hesaplanamayan
#  (kisimli ihale / farkli para birimi) kayitlar ortalamaya GIRMEZ ve kac
#  kaydin olculdugu her satirda YAZILIR - "%21 kirim" degil, "117 ihalede
#  olculen ortalama %21,3". Az ornekli grup (n<3) hic yayimlanmaz.
# ============================================================================
#  BUYUME SINIRI: sonuc havuzu her gun biriktikce idare ve kelime sayisi artar.
#  Bu dosya SITEYE gidiyor, yani sinirsiz buyuyemez. Kayit sayisina gore
#  siralanip en cok kayitli N idare/kelime yazilir. Tur istatistigi HIC
#  kirpilmaz - kartin son care eslesmesi odur ve kapsami %100'dur.
param([switch]$Yaz, [int]$AsgariOrnek = 5, [int]$Tavan = 150)
$ErrorActionPreference = "Continue"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$kaynak = Join-Path $kok "veri\ihale-sonuc.json"
if(-not (Test-Path $kaynak)){ Write-Host "ihale-sonuc.json yok - once motor/ihale-sonuc-ayristir.ps1"; if($Yaz){ exit 1 }; return }
$s = @((Get-Content $kaynak -Raw -Encoding UTF8 | ConvertFrom-Json).sonuclar)
Write-Host ("kaynak: {0} sonuc ilani" -f $s.Count)

function Sade([string]$x){ ("$x".ToUpper() -replace '[^A-ZÇĞİÖŞÜ0-9 ]',' ' -replace '\s+',' ').Trim() }
function Ist($liste){
  # kirimi OLCULEBILEN kayitlarin istatistigi (digerleri sayilmaz)
  $k = @($liste | Where-Object { $null -ne $_.kirimYuzde } | ForEach-Object { [double]$_.kirimYuzde })
  $t = @($liste | Where-Object { $_.teklifSayisi } | ForEach-Object { [int]$_.teklifSayisi })
  $o = [ordered]@{ kayit = @($liste).Count }
  if($k.Count -ge 1){
    $m = ($k | Measure-Object -Average -Minimum -Maximum)
    $o.kirimOlculen = $k.Count
    $o.kirimOrt = [math]::Round($m.Average,1)
    $o.kirimEnAz = [math]::Round($m.Minimum,1)
    $o.kirimEnCok = [math]::Round($m.Maximum,1)
    # MEDYAN: ortalama tek bir uc kayittan bozulabiliyor (hizmette bir sozlesme
    # maliyetin %91,7 USTUNDE kapanmis, ortalamayi asagi cekiyor). Medyan
    # "ihalelerin yarisi bunun altinda" der - karta yazilacak olan budur.
    $sirali = @($k | Sort-Object)
    $orta = [int][math]::Floor($sirali.Count/2)
    $o.kirimMedyan = [math]::Round($(if($sirali.Count % 2 -eq 1){ $sirali[$orta] } else { ($sirali[$orta-1] + $sirali[$orta]) / 2 }),1)
    # maliyetin USTUNDE kapanan ihale sayisi (negatif kirim) - ayri sayilir ki
    # kartta "-%91,7" gibi kafa karistiran bir alt sinir yazmak zorunda kalmayalim
    $o.maliyetUstu = @($k | Where-Object { $_ -lt 0 }).Count
  }
  if($t.Count -ge 1){
    $o.teklifOlculen = $t.Count
    $o.teklifOrt = [math]::Round((($t | Measure-Object -Average).Average),1)
  }
  return $o
}

# --- 1) TUR bazinda (her kartta gosterilebilir, kapsam %100) ----------------
$turler = [ordered]@{}
foreach($t in @('Mal','Yapim','Hizmet')){
  $g = @($s | Where-Object { $_.tur -eq $t })
  if($g.Count){ $turler[$t] = (Ist $g) }
}

# --- 2) IDARE bazinda (ayni idarenin gecmisi - en degerli bilgi) ------------
$idareGrup = @{}
foreach($x in $s){
  if(-not $x.idare){ continue }
  $k = Sade $x.idare
  if($k.Length -lt 8){ continue }
  if(-not $idareGrup.ContainsKey($k)){ $idareGrup[$k] = New-Object Collections.ArrayList }
  [void]$idareGrup[$k].Add($x)
}
$idareAday = @()
foreach($k in $idareGrup.Keys){
  $g = @($idareGrup[$k])
  if($g.Count -lt $AsgariOrnek){ continue }
  $ist = Ist $g
  if(-not $ist.kirimOlculen){ continue }
  $idareAday += [pscustomobject]@{ ad = $k; ist = $ist; n = $ist.kirimOlculen }
}
$idareToplam = $idareAday.Count
$idareler = [ordered]@{}
# en cok OLCULEN kaydi olan idareler tutulur (en guvenilir istatistik onlarda)
foreach($a in ($idareAday | Sort-Object -Property n -Descending | Select-Object -First $Tavan | Sort-Object -Property ad)){
  $idareler[$a.ad] = $a.ist
}

# --- 3) ANAHTAR KELIME bazinda ("benzer is" yaklasimi) ----------------------
# Is adindaki anlamli kelimeler; cok genel olanlar (ALIMI, SATIN, İŞİ...) elenir.
$DUR = @('ALIMI','ALIM','SATIN','ALINACAKTIR','İŞİ','İŞ','VE','İLE','İÇİN','ADET','KALEM','MAL','HİZMET','YAPIM','YAPTIRILACAKTIR','KİRALAMA','TEMİNİ','TEMİN','MALZEME','MALZEMESİ','MALZEMELERİ','YILI','AYLIK','TOPLAM','MUHTELİF','ÇEŞİTLİ','GENEL','BAKIM','ONARIM')
$kelGrup = @{}
foreach($x in $s){
  if($null -eq $x.kirimYuzde){ continue }
  foreach($w in ((Sade $x.isAdi) -split ' ')){
    if($w.Length -lt 4 -or $DUR -contains $w){ continue }
    if(-not $kelGrup.ContainsKey($w)){ $kelGrup[$w] = New-Object Collections.ArrayList }
    [void]$kelGrup[$w].Add($x)
  }
}
$kelAday = @()
foreach($k in $kelGrup.Keys){
  $g = @($kelGrup[$k])
  if($g.Count -lt $AsgariOrnek){ continue }
  $kelAday += [pscustomobject]@{ ad = $k; ist = (Ist $g); n = $g.Count }
}
$kelimeToplam = $kelAday.Count
$kelimeler = [ordered]@{}
foreach($a in ($kelAday | Sort-Object -Property n -Descending | Select-Object -First $Tavan | Sort-Object -Property ad)){
  $kelimeler[$a.ad] = $a.ist
}

Write-Host ("`ntur       : {0}" -f $turler.Count)
Write-Host ("idare     : {0}/{1} (en az {2} olculen kayit · tavan {3})" -f $idareler.Count, $idareToplam, $AsgariOrnek, $Tavan)
Write-Host ("kelime    : {0}/{1} (tavan {2})" -f $kelimeler.Count, $kelimeToplam, $Tavan)
# SESSIZ KIRPMA YASAGI: tavan yuzunden dusen varsa SOYLENIR
if($idareToplam -gt $Tavan){ Write-Host ("   not: {0} idare tavan disinda kaldi (en az kayitlilar)" -f ($idareToplam-$Tavan)) }
if($kelimeToplam -gt $Tavan){ Write-Host ("   not: {0} kelime tavan disinda kaldi" -f ($kelimeToplam-$Tavan)) }
foreach($t in $turler.Keys){
  $i = $turler[$t]
  Write-Host ("  {0,-8} {1,5} kayit · kirim {2} ihalede ort %{3} · teklif ort {4}" -f $t, $i.kayit, $i.kirimOlculen, $i.kirimOrt, $i.teklifOrt)
}

if($Yaz){
  $yol = Join-Path $kok "veri\ihale-sonuc-ozet.json"
  $cikti = [ordered]@{
    guncelleme = "Kaynak: Kamu İhale Bülteni — Sonuç İlanları (KİK). Son çekim: " + (Get-Date -Format "dd.MM.yyyy HH:mm") + "."
    not = "Sayılar, sonuç ilanlarında idarece AÇIKLANAN yaklaşık maliyet ve sözleşme bedelinden ölçülmüştür. Kısmi teklife açık ihaleler ve farklı para birimli sözleşmeler kırım ortalamasına DAHİL DEĞİLDİR; her satırda kaç ihalede ölçüldüğü yazar."
    kayitSayisi = $s.Count
    tur = $turler
    idare = $idareler
    kelime = $kelimeler
  }
  ($cikti | ConvertTo-Json -Depth 6) | Out-File $yol -Encoding utf8
  $geri = Get-Content $yol -Raw -Encoding UTF8 | ConvertFrom-Json
  $boy = (Get-Item $yol).Length
  Write-Host ("`n-> {0}" -f $yol)
  Write-Host ("   boyut: {0:N0} KB (ham veri 1.667 KB idi) · geri okuma: {1} tur, {2} idare, {3} kelime" -f ($boy/1KB), @($geri.tur.PSObject.Properties).Count, @($geri.idare.PSObject.Properties).Count, @($geri.kelime.PSObject.Properties).Count)
} else { Write-Host "`n(olcum modu - yazmak icin -Yaz)" }
