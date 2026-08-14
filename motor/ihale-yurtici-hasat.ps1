# ============================================================================
#  IHALE YURTICI HASAT - ilan.gov.tr (Basin Ilan Kurumu resmi portali) acik
#  listeleme API'sinden gunun kamu ihale ilanlarini ceker -> veri/ihale-yurtici.json
#  API: POST /api/api/services/app/Ad/AdsByFilter  (Ilan Turu attr=2, IHALE deger=45984)
#  Robot gunluk kosar (kaynak.yml); UI: ihale-radari.html Yurt Ici sekmesi.
# ============================================================================
param(
  [int]$Adet = 40,
  # 14.08 Cem "ilan gov tr 250 eslestir": havuzdaki ESKI ilanlarin cogu detay-cekme
  # ozelligi eklenmeden once girdigi icin detaysiz/IKN'siz kalmis (250'nin 209'u).
  # IKN olmayinca bultenle eslesemiyorlar. Bu mod API'ye HIC gitmez; havuzdaki
  # detaysiz ilanlarin url'indeki ilan.gov.tr ID'siyle detayi (ve IKN'yi) geriye
  # donuk doldurur. Gunluk hasat yeni ilanlari zaten detayli cekiyor; bu tek
  # seferlik toparlama.
  [switch]$DetayTamamla
)
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here

# 31.07 OLCUM: API'nin attributeId filtresi GUVENILMEZ - akademik/emlak/tebligat da
# donduruyor. Tek saglam kimlik slugifyTitle'daki resmi kategori yolu:
# 'ihale-duyurulari-<tur>-...' (mal-alim / hizmet-alim / yapim-ve-insaat).
# Sayfalanir, YALNIZ ihale-duyurulari alinir, tur cikarilir.
function SlugTur([string]$slug){
  if($slug -match 'mal-alim'){ return 'mal' }
  if($slug -match 'hizmet-alim'){ return 'hizmet' }
  if($slug -match 'yapim'){ return 'yapim' }
  return 'diger'
}
# 13.08 OLCUM (ihale-slug-kesif.ps1, 600 ilan): duzeltme ve iptal ilanlari AYRI ilan
# olarak dusuyor ve simdiye kadar acik ihale gibi listeleniyordu. Iyi haber: bu
# ilanlarin BASLIGINDA duzelttikleri/iptal ettikleri ilanin numarasi yaziyor:
#   "Duzeltme ilani ILN02527595 ihale"  ·  "Ihale iptal ilani ( ILN02523833 ihale)"
# Birlestirme kimligi bu numaradir - uydurmaya gerek yok, kaynakta yaziyor.
function IlanDurumu([string]$baslik, [string]$slug){
  $h = "$baslik $slug"
  if($h -imatch 'iptal'){ return 'iptal' }
  if($h -imatch 'd[uü]zeltme|tashih'){ return 'duzeltme' }
  return 'asil'
}
function AsilIlanNo([string]$baslik, [string]$kendiNo){
  # Baslikta kendi numarasi disinda bir ILN varsa, o duzeltilen/iptal edilen ilandir.
  foreach($m in ([regex]'ILN\d{6,}').Matches("$baslik")){
    if("$($m.Value)" -ne "$kendiNo"){ return $m.Value }
  }
  return ""
}
$hamAds = @()
$atla = 0; $tur = 0
while(-not $DetayTamamla -and $hamAds.Count -lt $Adet -and $tur -lt 25){
  $govde = @{ adFilterAttributes = @(@{ attributeId = 2; attributeValueIds = @(45984) }); maxResultCount = 20; skipCount = $atla } | ConvertTo-Json -Depth 5
  $r = Invoke-RestMethod -Method Post -Uri "https://www.ilan.gov.tr/api/api/services/app/Ad/AdsByFilter" `
    -Headers @{ "Accept"="application/json"; "User-Agent"="Mozilla/5.0 (MevzuatRadar-IhaleRobotu)" } `
    -Body ([System.Text.Encoding]::UTF8.GetBytes($govde)) -ContentType "application/json" -TimeoutSec 90
  $sayfa = @($r.result.ads)
  if(-not $sayfa.Count){ break }
  $hamAds += @($sayfa | Where-Object { "$($_.slugifyTitle)" -match '^ihale-duyurulari' })
  $atla += $sayfa.Count
  $tur++
  Start-Sleep -Milliseconds 400
}

# ============================================================================
#  14.08 Cem: "burada hap bilgi versek ihale bedeli vs gibi sence"
#  OLCULDU: ilan.gov.tr'nin DETAY ucu (AdDetail/GetAdDetail?id=) ilanin tam
#  metnini veriyor. Icinden cikan karar bilgileri: son teklif tarihi/saati, IKN,
#  ihale usulu, gecici teminat orani, yerli istekli sarti, is deneyimi orani,
#  teklif gecerlilik suresi, isin suresi, sinir deger katsayisi.
#  DIKKAT - YAKLASIK MALIYET YOK: 4734'te yaklasik maliyet ilanla aciklanmaz,
#  API'de de attrEstimatedPrice bos gelir. "Ihale bedeli" GOSTERILMEZ; olcmedigimiz
#  rakami yazmayiz. Gosterilenler yalniz ilan metninde YAZAN seylerdir.
#  Detay yalniz YENI ilanlar icin cekilir (havuzdakiler tekrar cekilmez).
# ============================================================================
function DetayCek([string]$id){
  try {
    $d = Invoke-RestMethod -Uri "https://www.ilan.gov.tr/api/api/services/app/AdDetail/GetAdDetail?id=$id" `
         -Headers @{ "Accept"="application/json"; "User-Agent"="Mozilla/5.0 (MevzuatRadar-IhaleRobotu)" } -TimeoutSec 60
  } catch { return $null }
  $h = "$($d.result.content)"
  if(-not $h){ return $null }
  # 14.08 CEM BULGUSU ("burda hap bilgi yok"): Osmangazi EDAS drone ilaninda kart
  # BOMBOS kaliyordu. Sebep: detay cikarici yalniz 4734 kaliplarini ariyordu
  # ("İhale Kayıt Numarası (İKN)", "geçici teminat", "4734 sayılı Kanunun ... maddesi")
  # ama o ilan 4734 KAPSAMINDA DEGIL - "Elektrik Dağıtım Şirketleri Satın Alma-Satma
  # ve İhale Yönetmeliği"ne tabi. Havuzdaki 97 detayli ilanin 9'u boyle.
  # COZUM: API'nin adTypeFilters alani usul/tur/kayit no/tarihi YAPISAL veriyor -
  # her rejimde calisir. Once oradan alinir, 4734'e ozgu alanlar metinden eklenir.
  $yapisal = @{}
  foreach($f in @($d.result.adTypeFilters)){ if($f.key){ $yapisal["$($f.key)"] = "$($f.value)".Trim() } }
  $kategori = (@($d.result.categories) | Where-Object { $_.name } | Select-Object -Last 2 | ForEach-Object { $_.name }) -join ' › '
  # HTML tablodan duz metin (etiketler sokulur, bosluklar sadelesir)
  $m = ($h -replace '<[^>]+>',' ') -replace '&nbsp;',' ' -replace '&amp;','&' -replace '\s+',' '
  $al = {
    param($desen)
    $r = [regex]::Match($m, $desen)
    if($r.Success){ return ($r.Groups[1].Value.Trim() -replace '\s{2,}',' ') }
    return ""
  }
  # 4734 disi ilanlarda tarih metin icinde serbest yazilir; yapisal alan yoksa
  # "Tekliflerin sunulacağı Tarih ve saat" kalibi denenir.
  $sonT = (& $al '2\.1\.\s*Tarih ve Saati\s*:\s*([\d.]+\s*-\s*[\d:]+)')
  if(-not $sonT){ $sonT = (& $al 'Teklif(?:ler)?in(?:in)? sunulaca[ğg][ıi] [Tt]arih ve saat\s*:?\s*([\d.]+[^0-9]{0,20}[\d:]+)') }
  if(-not $sonT -and $yapisal['İhale ve Teklif Açma Tarihi']){ $sonT = $yapisal['İhale ve Teklif Açma Tarihi'] }
  $u = (& $al '(4734 sayılı Kamu İhale Kanununun \d+ [^.]{0,40}maddesine göre [^.]{0,45}usul[üu])')
  if(-not $u){ $u = $yapisal['İhale Usulü'] }
  $k = (& $al 'İhale Kayıt Numarası \(İKN\)\s*:\s*(\d{4}/\d+)')
  if(-not $k){ $k = $yapisal['İhale Kayıt No'] }

  [ordered]@{
    ikn        = $k
    sonTeklif  = $sonT
    usul       = $u
    kapsam     = $(if("$u" -match '4734'){ '4734' } elseif($u){ 'ozel' } else { '' })
    tur        = $yapisal['İhale Türü']
    kategori   = $kategori
    # asagidakiler YALNIZ 4734 ilanlarinda bulunur; digerlerinde bos kalir (uydurulmaz)
    teminat    = (& $al '(teklif ettikleri bedelin\s*%\s*\d+\S{0,2}[^.]{0,60}geçici teminat)')
    yerliSart  = (& $al '(İhaleye sadece yerli istekliler katılabilecektir)')
    isDeneyimi = (& $al 'teklif edilen bedelin\s*%\s*(\d+)\s*oranından az olmamak')
    gecerlilik = (& $al 'tekliflerin geçerlilik süresi, ihale tarihinden itibaren\s*(\d+\s*\([^)]*\))')
    isSuresi   = (& $al '3\.4\.\s*Süresi/teslim tarihi\s*:\s*([^:]{5,90}?)\s*3\.5')
    sinirN     = (& $al 'Sınır Değer Katsayısı \(N\)\s*:\s*([\d,]+)')
    # 4734 disi ilanlarda kritik: dokuman nereden alinir + acik eksiltme var mi
    dokumanYer = (& $al '(?:İhale [Dd]okümanı|[Dd]etaylı bilgi)[^.]{0,90}?((?:www\.|https?://)[^\s,;]{6,60})')
    eksiltme   = (& $al '(Açık eksiltme [Tt]arih ve saati\s*:?\s*[\d.]+[^0-9]{0,20}[\d:]+)')
    # ---- DUZELTME/IPTAL ILANLARI ICIN (14.08 Cem'in bos kart bulgusu) --------
    # Duzeltme ilaninda okunmasi gereken tek sey NEYIN DEGISTIGI. Metinde
    # "...maddesi asagidaki sekilde degistirilmistir" / "Duzeltilen madde" gibi
    # kaliplarla yaziliyor. Asil ilanin numarasi da burada geciyor.
    asilIlanNo = (& $al '(?:[İI]lan [Nn]o|[İI]LN)\s*:?\s*(ILN\d{6,})')
    asilIkn    = (& $al 'İhale Kayıt Numarası[^0-9]{0,20}(\d{4}/\d+)')
    asilDosya  = (& $al '([A-Z]{2}\d{6,})\s*dosya numaralı')
    # OLCULDU (ADM Elektrik duzeltme ilani, ham metin okundu): duzeltme metni
    # "... ile ilgili asagidaki hususlarda degisiklik yapilmistir" cumlesiyle
    # basliyor, ardindan "Eski Hali / Yeni Hali" tablosu geliyor. Teklif
    # hazirlayanin bilmesi gereken sey ORADA: o ilanda ihale YERI Denizli'den
    # Izmir'e tasinmis, tarih 19.08 15:00 -> 25.08 11:30 kaymis.
    # Degisen sartname maddeleri toplanir; hicbiri uydurulmaz, metinde YAZAR.
    degisenler = $(
      $lst = @()
      foreach($mm in [regex]::Matches($m, '(?:İdari|Teknik)\s+Şartname[^.]{0,24}?Madde\s*\d+')){
        $lst += (($mm.Value -replace '\s+',' ').Trim())
      }
      ($lst | Select-Object -Unique) -join ' · ')
    yerDegisti = (& $al '(İhalenin Yapılacağı Adres\s*:\s*[^:]{6,90}?)\s*İhale \(Son Teklif')
    eskiTarih  = (& $al '(\d{2}/\d{2}/\d{4})[^.]{0,30}?günü saat\s*[\d:]+[^.]{0,20}?yapılacak olan')
  }
}

$yolOn = Join-Path $kok "veri\ihale-yurtici.json"

# ==== DETAY TAMAMLAMA MODU (14.08) ==========================================
# Havuzdaki detaysiz ilanlarin url'indeki ID ile detayi (ve IKN'yi) geriye donuk
# doldurur; API listeleme akisina hic girmez, dosyayi yerinde gunceller.
if($DetayTamamla){
  if(-not (Test-Path $yolOn)){ Write-Host "havuz yok - once normal hasat kosmali"; exit 1 }
  $veri = Get-Content $yolOn -Raw -Encoding UTF8 | ConvertFrom-Json
  $liste = @($veri.ilanlar)
  $detaysiz = @($liste | Where-Object { -not $_.detay })
  Write-Host ("Havuz: {0} ilan · detaysiz: {1}" -f $liste.Count, $detaysiz.Count)
  $dolduruldu = 0; $iknKazanan = 0; $basarisiz = 0
  foreach($x in $detaysiz){
    # url: https://www.ilan.gov.tr/ilan/<ID>/<slug>
    $mid = [regex]::Match("$($x.url)", '/ilan/(\d+)/')
    if(-not $mid.Success){ $basarisiz++; continue }
    $d = DetayCek $mid.Groups[1].Value
    if($d){
      $x | Add-Member -NotePropertyName detay -NotePropertyValue $d -Force
      $dolduruldu++
      if($d.ikn){ $iknKazanan++ }
    } else { $basarisiz++ }
    Start-Sleep -Milliseconds 350   # kaynaga nazik
    if($dolduruldu % 25 -eq 0 -and $dolduruldu){ Write-Host ("   ... {0} detay cekildi" -f $dolduruldu) }
  }
  Write-Host ("`nDetay dolduruldu: {0} · IKN kazanan: {1} · basarisiz: {2}" -f $dolduruldu, $iknKazanan, $basarisiz)
  # yaz + geri oku dogrulamasi
  $veri.ilanlar = $liste
  ($veri | ConvertTo-Json -Depth 8) | Out-File $yolOn -Encoding utf8
  $geri = Get-Content $yolOn -Raw -Encoding UTF8 | ConvertFrom-Json
  $iknli = @($geri.ilanlar | Where-Object { $_.detay -and $_.detay.ikn }).Count
  Write-Host ("-> geri okuma: {0} ilan · IKN'si olan: {1}" -f @($geri.ilanlar).Count, $iknli)
  exit 0
}

# Havuzda detayi ZATEN olan ilanlari tekrar cekmemek icin once eskiyi oku
$eskiDetay = @{}
if(Test-Path $yolOn){
  try {
    $on = Get-Content $yolOn -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach($e in @($on.ilanlar)){ if($e.detay){ $eskiDetay["$($e.ilanNo)"] = $e.detay } }
  } catch {}
}

$ilanlar = @()
$detayCekilen = 0
foreach($a in $hamAds){
  $tarih = ""
  if($a.publishStartDate){ try { $tarih = ([datetime]$a.publishStartDate).ToString("dd.MM.yyyy") } catch { $tarih = "$($a.publishStartDate)".Substring(0,10) } }
  $detay = $null
  # 14.08 CEM BULGUSU (ekran goruntusu, ADM Elektrik duzeltme ilani): kart BOMBOS,
  # icinde yalnizca "bu bir duzeltme ilanidir" damgasi ve altinda kocaman bosluk.
  # SEBEP: duzeltme/iptal ilanlarinin slug'i "ihale-duzeltme-zeyilname-duyurulari"
  # oldugu icin SlugTur 'diger' donuyor ve asagidaki kosul detayi HIC cekmiyordu.
  # Oysa duzeltme ilaninin metni tam da okunmasi gereken sey: neyin degistigi ve
  # asil ilanin numarasi orada. Artik durum'u duzeltme/iptal olanlarin da detayi
  # cekilir (gunde 4-5 ilan, kaynaga ek yuk yok).
  $ilanDurum = (IlanDurumu "$($a.title)" "$($a.slugifyTitle)")
  if($eskiDetay.ContainsKey("$($a.adNo)")){ $detay = $eskiDetay["$($a.adNo)"] }
  elseif((SlugTur "$($a.slugifyTitle)") -ne 'diger' -or $ilanDurum -in @('duzeltme','iptal')){
    # yalniz gercek ihale ilanlari icin detay cekilir; kaynaga nazik olmak icin bekleme
    $detay = DetayCek "$($a.id)"
    $detayCekilen++
    Start-Sleep -Milliseconds 350
  }
  $ilanlar += [ordered]@{
    ilanNo = $a.adNo
    baslik = $a.title
    kurum  = $a.advertiserName
    il     = $a.addressCityName
    ilce   = $a.addressCountyName
    tarih  = $tarih
    tur    = (SlugTur "$($a.slugifyTitle)")
    durum  = $ilanDurum
    # asil ilan no oncelikle BASLIKTAN cikarilir; baslikta yoksa (Cem'in gordugu
    # ADM ilaninda oyleydi - asilNo bostu) detay metnindeki ILN/IKN denenir.
    asilNo = $(
      $an = (AsilIlanNo "$($a.title)" "$($a.adNo)")
      if($an){ $an }
      elseif($detay -and $detay.asilIlanNo){ $detay.asilIlanNo }
      else { '' })
    detay  = $detay
    url    = "https://www.ilan.gov.tr/ilan/$($a.id)/$($a.slugifyTitle)"
  }
}
Write-Host ("Detay cekilen yeni ilan: {0} (havuzdan gelen detay: {1})" -f $detayCekilen, $eskiDetay.Count)
if(-not $ilanlar.Count){ Write-Host "UYARI: API bos dondu - json GUNCELLENMEDI (eski veri korunur)"; exit 0 }

# 31.07: BIRIKIMLI HAVUZ - her cekim dosyayi sifirlamasin; il suzgecinde derinlik
# olsun diye eski ilanlar korunur (mukerrer ilanNo ayiklanir, 14 gunden eski duser,
# tavan 250). Ihale ilanlari zaten teklif tarihinden gunler once yayinlanir.
$yol = Join-Path $kok "veri\ihale-yurtici.json"
$eskiler = @()
if(Test-Path $yol){
  try {
    $mevcut = Get-Content $yol -Raw -Encoding UTF8 | ConvertFrom-Json
    $yeniNolar = @($ilanlar | ForEach-Object { "$($_.ilanNo)" })
    $sinirTarih = (Get-Date).AddDays(-14)
    foreach($e in @($mevcut.ilanlar)){
      if($yeniNolar -contains "$($e.ilanNo)"){ continue }
      $eskiSlug = ("$($e.url)" -split '/')[-1]
      if($eskiSlug -notmatch '^ihale-duyurulari'){ continue }  # eski cop (emlak/tebligat/personel) havuzdan dusurulur
      $t = $null; try { $t = [datetime]::ParseExact("$($e.tarih)","dd.MM.yyyy",$null) } catch {}
      if($t -and $t -lt $sinirTarih){ continue }
      # eski havuz kayitlarina da durum/asilNo hesaplanir (yeni alanlar geriye donuk dolar)
      $eskiler += [ordered]@{ ilanNo=$e.ilanNo; baslik=$e.baslik; kurum=$e.kurum; il=$e.il; ilce=$e.ilce; tarih=$e.tarih;
        tur=(SlugTur $eskiSlug); durum=(IlanDurumu "$($e.baslik)" $eskiSlug); asilNo=(AsilIlanNo "$($e.baslik)" "$($e.ilanNo)");
        detay=$e.detay; url=$e.url }
    }
  } catch { Write-Host "NOT: eski json okunamadi, sifirdan yazilir" }
}
$ilanlar = @($ilanlar + $eskiler) | Select-Object -First 250

$cikti = [ordered]@{
  guncelleme = "Kaynak: Basın İlan Kurumu (195 s. Kanun'la kurulu kamu kurumu) Resmî İlan Portalı — ilan.gov.tr. Son çekim: " + (Get-Date -Format "dd.MM.yyyy HH:mm") + "."
  kaynak = "ilan.gov.tr"
  ilanlar = $ilanlar
}
($cikti | ConvertTo-Json -Depth 5) | Out-File $yol -Encoding utf8
Write-Host ("YURTICI IHALE: {0} ilan ({1} yeni cekim + {2} havuzdan) -> veri/ihale-yurtici.json" -f $ilanlar.Count, ($ilanlar.Count - $eskiler.Count), $eskiler.Count)
