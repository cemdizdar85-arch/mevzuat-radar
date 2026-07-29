# ============================================================================
#  SGS KOTA KURUCU - Staja Giris Sinavi uretim recetesi   (PARA HARCAMAZ)
#
#  NEDEN VAR: 29.07.2026 gecesi 3.451 soru uretildi ve HEPSI Yeterlilik'e
#  gitti - kota (veri/uretim-kotasi.json) yalniz 8 Yeterlilik dersini
#  tanidigi icin SGS'ye TEK SORU dusmedi. SGS tarafinda ne varsa eski toplu
#  aktarimdan kalma ve carpik: Yabanci Dil sinavin %7,7'si iken kasanin
#  %23'u, Finansal Muhasebe ise sinavin EN BUYUK dersi (%20) oldugu halde
#  yari yariya eksik. Cem'in teshisi: "sayi bizi kandiriyor".
#
#  UC OLCU:
#   1) AGIRLIK : TESMER Uygulama Yonergesi 2024 m.6.2 (TURMOB YKK 17.07.2020/22)
#                soru adetleri - veri/sgs-sinav-yapisi.json'dan OKUNUR.
#                Bagimsiz teyit: 20 gercek SGS kitapciginin ders dagilimi
#                (veri/sgs-analiz.json) bu tabloyla birebir tutuyor
#                (Muhasebe 58 = FinMuh 26 + Maliyet 8 + Analiz 8 + Denetim 16).
#   2) KONU    : veri/konu-kaynak-karnesi.json - cikmis sinav konulari +
#                ambarda kaynak metni VAR MI. Karnenin kendi kurali:
#                "KAYNAK YOK ve MEVZUAT-DISI satirlarina fabrika SOKULMAZ."
#   3) MEVCUT  : kasadaki SGS sorusu (sinav='SGS' filtresi SART - "Finansal
#                Muhasebe" ve "Maliyet Muhasebesi" HEM SGS HEM Yeterlilik
#                dersi; filtresiz sayim 749 yerine 2.163 gosterir ve kotayi
#                oldugundan kucuk kurar).
#
#  URETILEMEYEN DERSLER: Matematik, Turkce, Ataturk Ilkeleri, Yabanci Dil.
#  Bunlarin kanun maddesi yok; uretici (soru-uret-v2.ps1 L17) kaynaksiz satiri
#  SESSIZCE ATLAR. Kotaya konsalardi para odenir, soru gelmezdi. Ayri is
#  olarak once kaynak kurulacak (Matematik: mufredat teori notu; Ataturk
#  Ilkeleri: Teskilat-i Esasiye/Tevhid-i Tedrisat/Soyadi gibi GERCEK kanun
#  metinleri mevzuat.gov.tr'den yutulur - karne bunlari toptan "mevzuat-disi"
#  saymis, bu kismen yanlis).
#
#  ENV: KOTA_CIPA (varsayilan 750 = %6,2'lik ders basina hedef havuz)
#       SUPABASE_SERVICE_KEY (varsa canli sayim; yoksa veri/kasa-sayim.json)
#  CIKTI: veri/sgs-uretim-kotasi.json
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$enc  = New-Object Text.UTF8Encoding($false)

$CIPA = if($env:KOTA_CIPA){ [int]$env:KOTA_CIPA } else { 750 }

# --- KURGU/UZUNLUK: SGS kitapciklarinda OLCULMEDI (sgs-analiz.json tip dagilimi
#     tutmuyor). Uydurmak yerine, AYNI DERSIN Yeterlilik'te 480 gercek test
#     sorusundan OLCULMUS dagilimi odunc alinir; kaynagi her satirda yazilir.
#     Ekonomi ve Maliye'nin Yeterlilik'te karsiligi yok - onlar TAHMIN olarak
#     isaretlenir; olculdugunde degistirilecek. (Bu bir uretim parametresidir,
#     ogrenciye gosterilen bir olgu degil - ama yine de kaynagi gorunur olsun.)
$KURGU = @{
  'Finansal Muhasebe'            = @{ k='kayit %40 · bilgi %35 · vaka %17 · hesap %8'; u='orta %60 · kisa %25 · uzun %15'; s='odunc: Yeterlilik/Finansal Muhasebe (olculdu)' }
  'Maliyet Muhasebesi'           = @{ k='bilgi %60 · hesap %38 · kayit %2';            u='orta %52 · kisa %33 · uzun %15'; s='odunc: Yeterlilik/Maliyet Muhasebesi (olculdu)' }
  'Mali Tablolar Analizi'        = @{ k='hesap %58 · bilgi %37 · vaka %5';             u='kisa %63 · orta %25 · uzun %12'; s='odunc: Yeterlilik/Finansal Tablolar ve Analizi (olculdu)' }
  'Denetim'                      = @{ k='bilgi %83 · vaka %15 · karsilastir %2';       u='orta %52 · uzun %33 · kisa %15'; s='odunc: Yeterlilik/Muhasebe Denetimi (olculdu)' }
  'Vergi Hukuku'                 = @{ k='bilgi %67 · hesap %20 · vaka %12 · karsilastir %2'; u='orta %42 · kisa %33 · uzun %25'; s='odunc: Yeterlilik/Vergi Mevzuati ve Uygulamasi (olculdu)' }
  'Meslek Hukuku'                = @{ k='bilgi %97 · karsilastir %2 · vaka %2';        u='orta %52 · kisa %40 · uzun %8';  s='odunc: Yeterlilik/Meslek Hukuku (olculdu)' }
  'Ticaret Hukuku'               = @{ k='bilgi %95 · vaka %3 · hesap %2';              u='kisa %45 · orta %43 · uzun %12'; s='odunc: Yeterlilik/Hukuk (olculdu)' }
  'Borclar Hukuku'               = @{ k='bilgi %95 · vaka %3 · hesap %2';              u='kisa %45 · orta %43 · uzun %12'; s='odunc: Yeterlilik/Hukuk (olculdu)' }
  'Is ve Sosyal Guvenlik Hukuku' = @{ k='bilgi %95 · vaka %3 · hesap %2';              u='kisa %45 · orta %43 · uzun %12'; s='odunc: Yeterlilik/Hukuk (olculdu)' }
  'Ekonomi'                      = @{ k='bilgi %70 · hesap %25 · karsilastir %5';      u='orta %50 · kisa %35 · uzun %15'; s='TAHMIN - olculmedi, Yeterlilik karsiligi yok' }
  'Maliye'                       = @{ k='bilgi %80 · hesap %12 · vaka %8';             u='orta %50 · kisa %35 · uzun %15'; s='TAHMIN - olculmedi, Yeterlilik karsiligi yok' }
}
$KONU_TAVAN = 12   # tek konudan en fazla kac soru - benzerlik kapisi zaten eler,
                   # bu tavan parayi kapiya yedirmeden onler

function Fold($s){
  $t = "$s".ToLowerInvariant().Trim()
  $t = $t -replace [char]0x00E7,'c' -replace [char]0x011F,'g' -replace [char]0x0131,'i' `
          -replace [char]0x00F6,'o' -replace [char]0x015F,'s' -replace [char]0x00FC,'u' `
          -replace [char]0x0130,'i'
  return $t
}

# --- ders-remap.ps1 ile AYNI sozluk (tek dogruluk kaynagi olsun diye birebir kopya)
$MUH_ESLEME = @(
  @{ ders='Denetim';               desen='bds|denetim|denetci|orneklem|teyit|calisma kagit|kanit|gorus|kacinma|sartli|hile|onemlilik|ic kontrol|analitik|bagimsizlik|kalite kontrol|musteri kabul|yanlislik' },
  @{ ders='Maliyet Muhasebesi';    desen='maliyet|basabas|katki payi|gug|safha|siparis|birlesik uru|yan urun|standart maliy|direkt iscilik|direkt ilk madde|7/a|7/b|uretim gider|esdeger|dagitim anahtar|fire|kapasite sapma' },
  @{ ders='Mali Tablolar Analizi'; desen='analiz|dikey yuzde|yatay|trend|oran(lar)?[ |]|likidite|cari oran|asit|nakit orani|kaldirac|devir hiz|calisma sermayesi|karlilik oran|finansman oran|deflat' },
  @{ ders='Finansal Muhasebe';     desen='.' }
)
$HUK_ESLEME = @(
  @{ ders='Meslek Hukuku';                desen='meslek|3568|smmm|ymm|yeminli mali musavir|ruhsat|disiplin|etik|oda(lar)? |tesmer|staj|reklam yasag|tabela|buro edinme|ucret tarifes|mucadele kurulu' },
  @{ ders='Is ve Sosyal Guvenlik Hukuku'; desen='4857|is kanunu|is sozlesme|is iliskisi|kidem|ihbar|fesih|calisma sure|fazla calisma|yillik izin|sendika|grev|lokavt|toplu is|tesmil|5510|sigorta|sgk|prim|issizlik|analik|malul|yaslilik|emekli|olum aylig|goremezlik|fiili hizmet|istihdam buro|is kazasi|6331|isci|isveren|ucret hukum|ucretin ise' },
  @{ ders='Vergi Hukuku';                 desen='vuk|213|vergi|tarh|teblig|tahakkuk|tahsil|6183|amme alac|gvk|gelir vergi|kvk|kurumlar vergi|kdv|katma deger|otv|damga|beyanname|matrah|istisna|muafiyet|mukellef|uzlasma|pismanlik|idari yargi|vergi mahkeme|deger artis|emsal kira' },
  @{ ders='Ticaret Hukuku';               desen='ttk|6102|ticar|tacir|sirket|anonim|limited|kollektif|komandit|cek|bono|police|kiymetli evrak|ciro|kambiyo|tescil|unvan|sermaye art|sermaye azalt|bedelsiz pay|genel kurul|yonetim kurulu' },
  @{ ders='Borclar Hukuku';               desen='tbk|6098|borc|sozlesme|ibra|takas|yenileme|sebepsiz zengin|haksiz fiil|hayvan|yapi maliki|adam calistiran|kusursuz|tehlike sorumlulug|zamanasimi|temerrut|muteselsil|kefalet|genel islem|irade|hata|hile(?= ile)|gabin|temsil|oneri|icap|tek tarafli|yazili sekil|imza sart|kesin hukumsuz' }
)

# Yonergedeki ders adi ile kasadaki etiket her zaman birebir ayni degil.
# Ornek: yonerge "Ataturk Ilkeleri ve Inkilap Tarihi", kasa "Ataturk Ilke ve
# Inkilap Tarihi" -> eslesmezse mevcut 0 sanilir, hedef oldugundan buyuk kurulur.
# Bu yuzden sayimda TAM ESLESME degil, katlanmis-anahtar esitligi kullanilir.
function SayimAnahtar($s){
  $t = Fold $s
  $t = $t -replace 'ilkeleri','ilke' -replace '\s+ve\s+',' ' -replace '\s+',' '
  return $t.Trim()
}

function HedefDers($kabaDers, $konu){
  $fd = Fold $kabaDers; $fk = Fold $konu
  if($fd -eq 'muhasebe'){
    foreach($e in $MUH_ESLEME){ if($fk -match $e.desen){ return $e.ders } }
    return 'Finansal Muhasebe'
  }
  if($fd -eq 'hukuk'){
    foreach($e in $HUK_ESLEME){ if($fk -match $e.desen){ return $e.ders } }
    return $null          # eslesmeyen YANLIS derse tasinmaz - kotaya girmez
  }
  if($fd -eq 'ekonomi'){ return 'Ekonomi' }
  if($fd -eq 'maliye'){  return 'Maliye'  }
  return $null            # Matematik-Istatistik / Genel Kultur / Yabanci Dil
}

# --- 1) RESMI AGIRLIK (yonergeden okunur, elle yazilmaz)
$yapi = Get-Content (Join-Path $kok "veri/sgs-sinav-yapisi.json") -Raw -Encoding UTF8 | ConvertFrom-Json
$AGIRLIK = [ordered]@{}
$toplamSoru = [int]$yapi.sgs.toplamSoru
foreach($b in $yapi.sgs.bolumler){ foreach($d in $b.dersler){ $AGIRLIK[[string]$d.ders] = [double]$d.soru } }
$kontrol = 0; foreach($v in $AGIRLIK.Values){ $kontrol += $v }
if([int]$kontrol -ne $toplamSoru){ throw "Yonerge ders adetleri toplami $kontrol, beklenen $toplamSoru - dosya bozuk." }
Write-Host ("Yonerge: {0} ders, toplam {1} soru  (toplam dogrulandi)" -f $AGIRLIK.Count, $toplamSoru)

$HAVUZ = [math]::Round($CIPA / (8.0 / $toplamSoru * 100.0) * 100.0)   # cipa = 8 soruluk ders (Matematik/Maliyet/Analiz)
$HAVUZ = [math]::Round($CIPA * $toplamSoru / 8.0)
Write-Host ("CIPA (8 soruluk ders) = {0}  ->  hedef SGS havuzu {1}" -f $CIPA, $HAVUZ)

# --- 2) MEVCUT SGS SAYIMI (sinav='SGS' filtresi SART)
$VAR = @{}
$sayimKaynak = ""
$KEY = $env:SUPABASE_SERVICE_KEY
if($KEY){
  $SB_URL = "https://bjrleanjpyujtajmazxn.supabase.co"
  $H = @{ apikey=$KEY; Authorization="Bearer $KEY" }
  $ofs = 0; $n = 0
  while($true){
    $u = "$SB_URL/rest/v1/soru_havuzu?select=ders&sinav=eq.SGS&order=ders&offset=$ofs&limit=1000"
    $ham = Invoke-WebRequest -UseBasicParsing -Uri $u -Headers $H -TimeoutSec 120
    $govde = if($ham.Content -is [byte[]]){ [Text.Encoding]::UTF8.GetString($ham.Content) } else { "$($ham.Content)" }
    $dilim = @($govde | ConvertFrom-Json)
    foreach($r in $dilim){ $ak = SayimAnahtar $r.ders; $VAR[$ak] = 1 + [int]$VAR[$ak] }
    $n += $dilim.Count
    if($dilim.Count -lt 1000){ break }
    $ofs += 1000
    if($ofs -gt 60000){ break }
  }
  $sayimKaynak = "canli Supabase (sinav=SGS), $n kayit"
} else {
  $s = Get-Content (Join-Path $kok "veri/kasa-sayim.json") -Raw -Encoding UTF8 | ConvertFrom-Json
  foreach($p in $s.sinav_ders.PSObject.Properties){
    $parca = "$($p.Name)" -split '\|', 2
    if($parca.Count -eq 2 -and $parca[0] -eq 'SGS'){ $VAR[(SayimAnahtar $parca[1])] = [int]$p.Value }
  }
  $sayimKaynak = "veri/kasa-sayim.json ($($s.tarih)) - SERVICE key yok"
}
Write-Host ("Mevcut sayim kaynagi: {0}" -f $sayimKaynak)

# --- 3) KARNEDEN URETILEBILIR KONULAR
$karne = Get-Content (Join-Path $kok "veri/konu-kaynak-karnesi.json") -Raw -Encoding UTF8 | ConvertFrom-Json
$dersKonu = @{}          # fine ders -> konu listesi
$eslesmeyen = 0; $mevzuatDisi = 0; $kaynakYok = 0
foreach($k in $karne.konular){
  if($k.karar -eq 'MEVZUAT-DISI'){ $mevzuatDisi++; continue }
  if($k.karar -eq 'KAYNAK YOK'){ $kaynakYok++; continue }
  $hd = HedefDers $k.ders $k.konu
  if(-not $hd){ $eslesmeyen++; continue }
  if(-not $dersKonu.ContainsKey($hd)){ $dersKonu[$hd] = New-Object System.Collections.Generic.List[object] }
  $dersKonu[$hd].Add([pscustomobject]@{ konu="$($k.konu)"; siklik=[math]::Max(1,[int]$k.cikmisSoru) })
}
Write-Host ("Karne: URET konu esleşti; mevzuat-disi {0}, kaynak yok {1}, derse eslenemeyen {2}" -f $mevzuatDisi, $kaynakYok, $eslesmeyen)

# --- 4) PLAN
$plan = New-Object System.Collections.Generic.List[object]
$ozet = New-Object System.Collections.Generic.List[object]
$uretilemez = New-Object System.Collections.Generic.List[object]
$toplamUretim = 0

foreach($ad in $AGIRLIK.Keys){
  $hedef = [math]::Round($HAVUZ * $AGIRLIK[$ad] / $toplamSoru)
  $mevcut = [int]$VAR[(SayimAnahtar $ad)]
  $eksik = [math]::Max(0, $hedef - $mevcut)

  if(-not $dersKonu.ContainsKey($ad) -or $dersKonu[$ad].Count -eq 0){
    if($eksik -gt 0){
      $uretilemez.Add([ordered]@{ ders=$ad; sinavSoru=$AGIRLIK[$ad]; hedef=$hedef; mevcut=$mevcut; eksik=$eksik
                                  neden="kaynak yok - dersin mevzuati yok, once ambara kaynak kurulacak" })
    }
    $ozet.Add([ordered]@{ ders=$ad; sinav_soru=$AGIRLIK[$ad]; hedef=$hedef; mevcut=$mevcut; uretilecek=0; konu_sayisi=0; durum=$(if($eksik -gt 0){"KAYNAK BEKLIYOR"}else{"yeterli"}) })
    continue
  }

  $konular = @($dersKonu[$ad] | Sort-Object -Property siklik -Descending)
  if($eksik -eq 0){
    $ozet.Add([ordered]@{ ders=$ad; sinav_soru=$AGIRLIK[$ad]; hedef=$hedef; mevcut=$mevcut; uretilecek=0; konu_sayisi=$konular.Count; durum="yeterli - uretim yok" })
    continue
  }

  $kapasite = $konular.Count * $KONU_TAVAN
  $hedefEksik = $eksik
  $kisildi = $false
  if($eksik -gt $kapasite){ $eksik = $kapasite; $kisildi = $true }

  $agirlikToplam = 0; foreach($x in $konular){ $agirlikToplam += $x.siklik }
  $dagitildi = 0
  foreach($x in $konular){
    $adet = [math]::Floor($eksik * $x.siklik / $agirlikToplam)
    if($adet -gt $KONU_TAVAN){ $adet = $KONU_TAVAN }
    if($adet -lt 1){ $adet = 1 }
    $dagitildi += $adet
    $plan.Add([ordered]@{ ders=$ad; konu=$x.konu; katman=$(if($x.siklik -ge 2){"A-omurga"}else{"B-kapsama"}); siklik=$x.siklik; adet=$adet })
  }
  # yuvarlamadan kalani en sik konulara serp
  $i = 0
  while($dagitildi -lt $eksik -and $i -lt $plan.Count * 3){
    foreach($sat in $plan){
      if($dagitildi -ge $eksik){ break }
      if($sat.ders -ne $ad){ continue }
      if($sat.adet -ge $KONU_TAVAN){ continue }
      $sat.adet = $sat.adet + 1; $dagitildi++
    }
    $i++
    if($i -gt 40){ break }
  }
  $toplamUretim += $dagitildi
  $kd = $KURGU[$ad]
  if(-not $kd){ throw "Ders '$ad' icin kurgu dagilimi tanimli degil - sessizce 'bilgi %100' uretilmesin diye durduruldu." }
  $ozet.Add([ordered]@{ ders=$ad; sinav_soru=$AGIRLIK[$ad]; hedef=$hedef; mevcut=$mevcut; uretilecek=$dagitildi
                        konu_sayisi=$konular.Count; konu_basina=[math]::Round($dagitildi/$konular.Count,1)
                        kurgu=$kd.k; uzunluk=$kd.u; kurgu_kaynak=$kd.s
                        durum=$(if($kisildi){"KISILDI - konu kapasitesi $kapasite, istenen $hedefEksik"}else{"tam"}) })
}

$cikti = [ordered]@{
  tarih   = (Get-Date -Format 'dd.MM.yyyy HH:mm')
  sinav   = "SGS"
  cipa    = $CIPA
  hedef_havuz = $HAVUZ
  toplam_uretim = $toplamUretim
  agirlik_kaynak = $yapi.kaynak
  mevcut_kaynak  = $sayimKaynak
  konu_kaynak    = "veri/konu-kaynak-karnesi.json - yalniz karar=URET satirlari"
  konu_tavan     = $KONU_TAVAN
  kurgu_notu     = "SGS kitapciklarinda kurgu/uzunluk dagilimi OLCULMEDI (sgs-analiz.json tipSayim tutmuyor). Uretici ders-notu olmadan varsayilan dagilimla yazar; olculdugunde buraya eklenecek."
  uretilemez     = $uretilemez
  ozet    = $ozet
  plan    = $plan
}
$yol = Join-Path $kok "veri/sgs-uretim-kotasi.json"
[IO.File]::WriteAllText($yol, ($cikti | ConvertTo-Json -Depth 6), $enc)

Write-Host ""
Write-Host ("{0,-32} {1,5} {2,6} {3,6} {4,7} {5,6}" -f "DERS","SINAV","HEDEF","VAR","URET","KONU")
foreach($o in $ozet){ Write-Host ("{0,-32} {1,5} {2,6} {3,6} {4,7} {5,6}  {6}" -f $o.ders,$o.sinav_soru,$o.hedef,$o.mevcut,$o.uretilecek,$o.konu_sayisi,$o.durum) }
Write-Host ""
Write-Host ("TOPLAM URETILECEK : {0} soru" -f $toplamUretim)
Write-Host ("TAHMINI MALIYET   : {0:N0} USD  (olculen 0,0194 uretim + 0,0044 hakem = 0,0238/soru)" -f ($toplamUretim*0.0238))
if($uretilemez.Count -gt 0){
  Write-Host ""
  Write-Host "KAYNAK BEKLEYENLER (kotaya KONMADI - konsaydi para yanardi):"
  foreach($u in $uretilemez){ Write-Host ("  {0,-32} eksik {1,5}  -> {2}" -f $u.ders,$u.eksik,$u.neden) }
}
Write-Host ""
Write-Host ("-> {0}" -f $yol)
