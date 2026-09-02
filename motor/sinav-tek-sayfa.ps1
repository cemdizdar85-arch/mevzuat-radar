# ============================================================================
#  SINAV TEK SAYFA — "sınavla ilgili her şey tek yerden, hızlı, güvenilir"
#
#  NEDEN VAR (02.09.2026, Cem): "Bu sınav ile ilgili her şeyin benim sana
#  sorduğumda hemen bulunacak ve karışıklık olmayacak şekilde nasıl tek yerden
#  hızlı güvenilir, kaybolmadan nasıl sağlarız?"
#
#  31.08'de elle kurulan SINAVKONUDAYANAKHARITASI31082026.xlsx aynı soruya
#  cevap veriyordu ama (1) masaüstünde donuk bir dosyaydı, (2) üreticisi depoya
#  girmemişti, (3) sayıları o günün sayılarıydı. Bu betik o haritanın ROBOT
#  hâlidir: hiçbir şeyi yeniden ölçmez, ölçüm robotlarının ürettiği dosyaları
#  TEK SAYFADA birleştirir ve her sayının yanına KAYNAĞINI + TARİHİNİ yazar.
#
#  CEM'İN 7 SORUSU = 7 BÖLÜM:
#   1 dersler (sınav başına, resmi liste)         5 kaynak sağlığı (bayat/kırık ne var)
#   2 çıkmış sorular (ders/konu kırılımı)         6 yutulmayan mevzuat (çıkmışa göre)
#   3 bizim sorular yeterli mi (kota vs kasa)     7 basılması gereken sorular
#   4 indirilen mevzuat (ambar özeti)
#
#  KURAL: Bir bölümün girdisi BAYAT (> 7 gün) ya da KIRIK ise o bölümdeki sayı
#  "ölçülmedi" sayılır ve satırın başında ⚠ ile işaretlenir. Sessiz "temiz" YOK.
#
#  ÇIKTI: veri/SINAV-TEK-SAYFA.md (insan) + veri/sinav-tek-sayfa.json (makine).
#  JSON RaporYaz ile yazılır (içerik aynıysa dosyaya dokunulmaz). MD yalnız JSON
#  değiştiğinde yazılır — robot boş commit üretmez.
#  0 USD · ağ yok · Excel COM yok (CI'da pwsh/Linux'ta koşar).
# ============================================================================
$ErrorActionPreference = 'Stop'
$here = if($PSScriptRoot){ $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$depoKok = Split-Path -Parent $here
. (Join-Path $depoKok 'arac\rapor-yaz.ps1')
$simdi = Get-Date
$BAYAT_GUN = 7

# ---------------------------------------------------------------------------
# GİRDİ KÜTÜĞÜ — her dosyanın üreticisi ve robotu (agent envanteri 02.09.2026)
# ---------------------------------------------------------------------------
$GIRDILER = @(
  @{ ad='ders-profili';       yol='veri\ders-profili.json';               uretici='motor/ders-profili-kur.ps1';           robot='yok (resmî liste; Cem onayıyla değişir)'; damga=''; sabit=$true }
  @{ ad='kasa-sayim';         yol='veri\kasa-sayim.json';                 uretici='motor/kasa-sayim.ps1';                 robot='kasa-sayim.yml · her gün 03:41 TR';     damga='tarih' }
  @{ ad='kota-smmm';          yol='veri\uretim-kotasi.json';              uretici='motor/kota-kur.ps1';                   robot='yok (Cem kararı; tarih anlamsız)';      damga='tarih'; sabit=$true }
  @{ ad='kota-sgs';           yol='veri\sgs-uretim-kotasi.json';          uretici='motor/sgs-kota-kur.ps1';               robot='yok (Cem kararı; tarih anlamsız)';      damga='tarih'; sabit=$true }
  @{ ad='kota-kgk';           yol='veri\kgk-uretim-kotasi.json';          uretici='motor/kota-kur.ps1 (elle)';            robot='yok (Cem kararı; tarih anlamsız)';      damga='tarih'; sabit=$true }
  @{ ad='konu-koprusu';       yol='veri\konu-koprusu-ozet.json';          uretici='motor/konu-koprusu-kur.ps1 (V2 canlı)'; robot='konu-koprusu.yml · her gün 07:40 TR';  damga='olcum' }
  @{ ad='ambar-envanteri';    yol='veri\AMBAR-ENVANTERI.md';              uretici='motor/ambar-envanteri.ps1';            robot='ambar-kapilari.yml · her gün 11:00 TR'; damga='md' }
  @{ ad='butunluk-raporu';    yol='veri\butunluk-raporu.json';            uretici='motor/butunluk-kapisi.ps1';            robot='ambar-kapilari.yml · her gün 11:00 TR'; damga='tarih' }
  @{ ad='cikmis-karnesi';     yol='veri\cikmis-soru-karnesi.json';        uretici='motor/cikmis-soru-karnesi.ps1';        robot='yok';                                   damga='tarih' }
  @{ ad='siklik-kunyesi';     yol='veri\siklik-kunyesi.json';             uretici='motor/siklik-kunyesi.ps1';             robot='konu-eslesme.yml · yalnız push';        damga='tarih' }
  @{ ad='kgk-analiz';         yol='veri\kgk-analiz.json';                 uretici='motor/kgk-siklik-derle.ps1';           robot='yok';                                   damga='guncelleme' }
  @{ ad='ders-karnesi';       yol='veri\ders-karnesi.json';               uretici='motor/ders-karnesi.ps1';               robot='dogrula.yml';                           damga='guncelleme' }
  @{ ad='karne-sgs';          yol='veri\konu-kaynak-karnesi.json';        uretici='motor/konu-kaynak-karnesi.ps1';        robot='karne.yml · sgs-analiz push tetikli';   damga='guncelleme' }
  @{ ad='karne-smmm';         yol='veri\konu-kaynak-karnesi-smmm.json';   uretici='motor/konu-kaynak-karnesi.ps1';        robot='karne.yml';                             damga='guncelleme' }
  @{ ad='karne-kgk';          yol='veri\konu-kaynak-karnesi-kgk.json';    uretici='motor/konu-kaynak-karnesi.ps1';        robot='karne.yml';                             damga='guncelleme' }
  @{ ad='dayanak-metinsiz';   yol='veri\dayanak-metinsiz-raporu.json';    uretici='arac/dayanak-metinsiz-tarama.ps1';     robot='yok';                                   damga='olcum' }
  @{ ad='dayanak-kara-liste'; yol='veri\dayanak-kara-liste.json';         uretici='arac/dayanak-kara-liste.ps1';          robot='yok';                                   damga='olcum' }
  @{ ad='bekleyen-partiler';  yol='veri\bekleyen-partiler.json';          uretici='motor/parti-hasat.ps1';                robot='parti-liste.yml · her gün 03:26 TR';    damga='' }
  @{ ad='sinav-ders-envanteri'; yol='veri\sinav-ders-envanteri.json';     uretici='motor/sinav-ders-envanteri.ps1';       robot='sinav-ders-envanteri.yml · yalnız push'; damga='' }
)

$script:SON_YUKLEME_HATASI = $false
function Yukle([string]$yol){
  $tam = Join-Path $depoKok $yol
  $script:SON_YUKLEME_HATASI = $false
  if(-not (Test-Path $tam)){ return $null }
  $ham = Get-Content $tam -Raw -Encoding UTF8
  # PS 5.1: boş dizi "[ ]" ConvertFrom-Json'dan $null döner — bu KIRIK değil, BOŞ'tur.
  if("$ham".Trim() -match '^\[\s*\]$'){ return ,@() }
  try { return ($ham | ConvertFrom-Json) } catch { $script:SON_YUKLEME_HATASI = $true; return $null }
}
# Damga metninden tarih çek: "02.09.2026 05:03" · "2026-08-26 00:11" · "19.08.2026 (TAM ARSIV)"
function DamgaTarih([string]$damga){
  $m = [regex]::Match("$damga", '(\d{2})\.(\d{2})\.(\d{4})')
  if($m.Success){ try { return [datetime]::new([int]$m.Groups[3].Value, [int]$m.Groups[2].Value, [int]$m.Groups[1].Value) } catch { return $null } }
  $m = [regex]::Match("$damga", '(\d{4})-(\d{2})-(\d{2})')
  if($m.Success){ try { return [datetime]::new([int]$m.Groups[1].Value, [int]$m.Groups[2].Value, [int]$m.Groups[3].Value) } catch { return $null } }
  return $null
}
function DamgaOku($nesne,[string]$alan){
  if(-not $nesne -or -not $alan -or $alan -eq 'md'){ return '' }
  $prop = $nesne.PSObject.Properties[$alan]
  if($prop){ return "$($prop.Value)" }
  return ''
}
# Türkçe katlama: ders adları üç dosyada üç türlü yazılıyor (Ataturk Ilke / Ataturk Ilkeleri ...)
function Katla([string]$metin){
  $t = "$metin" -creplace 'İ','i' -creplace 'I','i' -creplace 'ı','i' -creplace 'Ğ','g' -creplace 'ğ','g' -creplace 'Ü','u' -creplace 'ü','u' -creplace 'Ş','s' -creplace 'ş','s' -creplace 'Ö','o' -creplace 'ö','o' -creplace 'Ç','c' -creplace 'ç','c'
  $t = $t.ToLowerInvariant() -replace '[^a-z0-9]',''
  return $t
}
# Aynı ders dört dosyada dört türlü yazılı (ölçüldü 02.09): resmî profil "a) Türkiye
# Muhasebe Standartları", kasa "Muhasebe Standartlari", kota "Muhasebe Standartlari",
# SMMM profil "Hukuk (Ticaret H., Borçlar H., ...)" kasa "Hukuk". Önce süs atılır
# (harf-parantez öneki, parantez içi, köşeli kod), sonra katlanır, sonra eş anlam.
# Eş anlam HEDEFİ = resmî profil adının katlanmış hâli. Aynı hedefe düşen iki kasa
# etiketi TOPLANIR (KGK c: Kurumsal Yönetim + Finansal Yönetim tek resmî derstir).
$DERS_ESANLAM = @{
  'ataturkilkeveinkilaptarihi'        = 'ataturkilkeleriveinkilaptarihi'
  'muhvemalimusmeslekhukuku'          = 'muhasebecilikvemalimusavirlikmeslekhukuku'
  'muhasebestandartlari'              = 'turkiyemuhasebestandartlari'
  'denetimstandartlari'               = 'turkiyedenetimstandartlari'
  'kurumsalyonetim'                   = 'kurumsalyonetimilkelerivefinansalyonetim'
  'finansalyonetim'                   = 'kurumsalyonetimilkelerivefinansalyonetim'
  'surdurulebilirlikraporlamasi'      = 'kurumsalsurdurulebilirlikraporlamasi'
  'surdurulebilirlik'                 = 'kurumsalsurdurulebilirlikraporlamasi'
  'sigortacilikveozelemeklilikmevzuati' = 'sigortacilikveozelemeklilikmevzuati'
}
function DersAnahtar([string]$ders){
  $sade = "$ders" -replace '^\s*[a-zçğıöşü]\)\s*','' -replace '\([^)]*\)','' -replace '\[[^\]]*\]',''
  $k = Katla $sade
  if($DERS_ESANLAM.ContainsKey($k)){ return $DERS_ESANLAM[$k] }
  return $k
}
function Sayi($deger){ $n = 0; if([int]::TryParse("$deger", [ref]$n)){ return $n }; return 0 }
function Bin([int]$n){ return $n.ToString('N0', [Globalization.CultureInfo]::GetCultureInfo('tr-TR')) }
function K([string]$metin){ return ("$metin" -replace '\|','/' -replace '\r?\n',' ').Trim() }

# ---------------------------------------------------------------------------
# 5) KAYNAK SAĞLIĞI — önce ölçülür, çünkü diğer bölümler buna göre işaretlenir
# ---------------------------------------------------------------------------
$saglik = New-Object System.Collections.Generic.List[object]
$veri = @{}
foreach($g in $GIRDILER){
  $tam = Join-Path $depoKok $g.yol
  $durum = 'YOK'; $yas = -1; $mtime = ''; $damgaMetin = ''
  $nesne = $null
  if(Test-Path $tam){
    # Dosya tarihi = son COMMIT tarihi (CI'da checkout her dosyayı "bugün" yapar, mtime yalan
    # söyler; git tarihi hem yerelde hem CI'da aynıdır). Git yoksa mtime.
    $bilgi = Get-Item $tam
    $sonYazim = $bilgi.LastWriteTime
    try {
      $gitTarih = (& git -C $depoKok log -1 --format=%cI -- $g.yol 2>$null)
      if($gitTarih){ $sonYazim = [datetime]::Parse("$gitTarih", [Globalization.CultureInfo]::InvariantCulture) }
    } catch {}
    if($bilgi.LastWriteTime -gt $sonYazim.AddMinutes(5) -and -not $env:GITHUB_ACTIONS){ $sonYazim = $bilgi.LastWriteTime }  # yerelde commit'siz taze dosya
    $mtime = $sonYazim.ToString('dd.MM.yyyy HH:mm')
    $yas = [int]($simdi - $sonYazim).TotalDays
    if($g.yol -like '*.json'){
      $nesne = Yukle $g.yol
      if($script:SON_YUKLEME_HATASI -or $null -eq $nesne){ $durum = 'KIRIK (json okunamadı)' }
      elseif(-not ($nesne -is [array]) -and $nesne.PSObject.Properties['durum'] -and "$($nesne.durum)" -eq 'HATA'){ $durum = "KIRIK (durum=HATA: $($nesne.hata))" }
      elseif(-not ($nesne -is [array])){ $damgaMetin = DamgaOku $nesne $g.damga }
    } else {
      $ilk = Get-Content $tam -TotalCount 5 -Encoding UTF8
      $eslesme = [regex]::Match(($ilk -join ' '), 'Üretim: \*\*([^*]+)\*\*')
      if($eslesme.Success){ $damgaMetin = $eslesme.Groups[1].Value }
    }
    # Yaş: ölçüm DAMGASI esastır (RaporYaz içerik aynıysa dosyaya dokunmaz, mtime yalan
    # söyleyebilir; damga ise ölçümün gerçek günüdür). Damga yoksa dosya tarihi.
    $damgaGun = DamgaTarih $damgaMetin
    if($damgaGun){ $yas = [int]($simdi.Date - $damgaGun.Date).TotalDays }
    if($durum -eq 'YOK'){
      if($g.ContainsKey('sabit') -and $g.sabit){ $durum = 'SABİT (karar dosyası)' }
      else { $durum = if($yas -gt $BAYAT_GUN){ "BAYAT ($yas gün)" } else { 'TAZE' } }
    }
  }
  $veri[$g.ad] = $nesne
  $saglik.Add([pscustomobject]@{ ad=$g.ad; dosya=($g.yol -replace '\\','/'); durum=$durum; damga=$damgaMetin; mtime=$mtime; yas_gun=$yas; uretici=$g.uretici; robot=$g.robot })
}
function Guvenilir([string]$ad){ $satir = $saglik | Where-Object { $_.ad -eq $ad } | Select-Object -First 1; return ($satir -and ($satir.durum -eq 'TAZE' -or $satir.durum -like 'SABİT*')) }
function Isaret([string[]]$adlar){ foreach($a in $adlar){ if(-not (Guvenilir $a)){ return '⚠ ' } }; return '' }

# ---------------------------------------------------------------------------
# 1) DERSLER + 3) YETERLİ MİYİZ + 7) EKSİK — tek hesaptan üçü
# ---------------------------------------------------------------------------
$SINAV_KISA = [ordered]@{
  'STAJA BAŞLAMA (SGS)'                 = 'SGS'
  'STAJ BİTİRME / YETERLİLİK (SMMM)'    = 'SMMM'
  'BAĞIMSIZ DENETÇİLİK (KGK)'           = 'KGK'
  'SPK LİSANSLAMA (SPL)'                = 'SPL'
}
$kasa = $veri['kasa-sayim']
$kasaDers = @{}
if($kasa -and $kasa.sinav_ders){ foreach($p in $kasa.sinav_ders.PSObject.Properties){ $parca = $p.Name -split '\|',2; $anahtarK = "$($parca[0])|$(DersAnahtar $parca[1])"; if(-not $kasaDers.ContainsKey($anahtarK)){ $kasaDers[$anahtarK] = 0 }; $kasaDers[$anahtarK] += (Sayi $p.Value) } }

$hedefDers = @{}
if($veri['kota-sgs'] -and $veri['kota-sgs'].ozet){ foreach($o in @($veri['kota-sgs'].ozet)){ $hedefDers["SGS|$(DersAnahtar $o.ders)"] = Sayi $o.hedef } }
if($veri['kota-smmm'] -and $veri['kota-smmm'].ozet){ foreach($o in @($veri['kota-smmm'].ozet)){ $hedefDers["SMMM|$(DersAnahtar $o.ders)"] = Sayi $o.toplam_kota } }
if($veri['kota-kgk'] -and $veri['kota-kgk'].plan){ foreach($o in @($veri['kota-kgk'].plan)){ $anahtar = "KGK|$(DersAnahtar $o.ders)"; if(-not $hedefDers.ContainsKey($anahtar)){ $hedefDers[$anahtar] = 0 }; $hedefDers[$anahtar] += (Sayi $o.adet) } }

$dersSatirlari = New-Object System.Collections.Generic.List[object]
$profil = $veri['ders-profili']
if($profil -and $profil.sinavlar){
  foreach($sinavProp in $profil.sinavlar.PSObject.Properties){
    $sinavAd = $sinavProp.Name
    $kisa = if($SINAV_KISA.Contains($sinavAd)){ $SINAV_KISA[$sinavAd] } else { $sinavAd }
    foreach($dersProp in $sinavProp.Value.PSObject.Properties){
      $dersAd = $dersProp.Name; $d = $dersProp.Value
      $anahtar = "$kisa|$(DersAnahtar $dersAd)"
      $mevcut = if($kasaDers.ContainsKey($anahtar)){ $kasaDers[$anahtar] } else { 0 }
      $hedef = if($hedefDers.ContainsKey($anahtar)){ $hedefDers[$anahtar] } else { -1 }
      $eksik = if($hedef -ge 0){ [Math]::Max(0, $hedef - $mevcut) } else { -1 }
      $doluluk = if($hedef -gt 0){ [int][Math]::Min(100, [Math]::Round(100.0 * $mevcut / $hedef)) } else { -1 }
      $dersSatirlari.Add([pscustomobject]@{
        sinav=$kisa; sinav_uzun=$sinavAd; ders=$dersAd; bolum="$($d.bolum)"; sinav_soru=(Sayi $d.soru_sayisi)
        liste_dayanagi="$($d.liste_dayanagi)"; onay="$($d._onay)"
        bizim=$mevcut; hedef=$hedef; eksik=$eksik; doluluk=$doluluk
      })
    }
  }
}
# kasada var ama resmi ders listesinde yok → PLAN DIŞI etiket (sessizce kaybolmasın)
$planDisi = New-Object System.Collections.Generic.List[object]
foreach($anahtar in $kasaDers.Keys){
  $parca = $anahtar -split '\|',2
  $var = $dersSatirlari | Where-Object { $_.sinav -eq $parca[0] -and (DersAnahtar $_.ders) -eq $parca[1] } | Select-Object -First 1
  if(-not $var){ $ham = ($kasa.sinav_ders.PSObject.Properties | Where-Object { ($_.Name -split '\|',2)[0] -eq $parca[0] -and (DersAnahtar (($_.Name -split '\|',2)[1])) -eq $parca[1] } | Select-Object -First 1).Name; $planDisi.Add([pscustomobject]@{ etiket=$ham; soru=$kasaDers[$anahtar] }) }
}
$sinavOzet = New-Object System.Collections.Generic.List[object]
foreach($kisa in @('SGS','SMMM','KGK')){
  $satirlar = @($dersSatirlari | Where-Object { $_.sinav -eq $kisa })
  $kasaToplam = if($kasa -and $kasa.sinav -and $kasa.sinav.PSObject.Properties[$kisa]){ Sayi $kasa.sinav.$kisa } else { 0 }
  $hedefToplam = ($satirlar | Where-Object { $_.hedef -ge 0 } | Measure-Object hedef -Sum).Sum
  $eksikToplam = ($satirlar | Where-Object { $_.eksik -ge 0 } | Measure-Object eksik -Sum).Sum
  $sinavOzet.Add([pscustomobject]@{ sinav=$kisa; ders=$satirlar.Count; kasa=$kasaToplam; hedef=[int]$hedefToplam; eksik=[int]$eksikToplam; kotasiz_ders=@($satirlar | Where-Object { $_.hedef -lt 0 }).Count })
}

# ---------------------------------------------------------------------------
# 2) ÇIKMIŞ SORULAR
# ---------------------------------------------------------------------------
$cikmis = [ordered]@{}
$ck = $veri['cikmis-karnesi']
if($ck -and $ck.satirlar){
  $cikmis.arsiv = @($ck.satirlar | Group-Object sinav | ForEach-Object { [pscustomobject]@{ sinav=$_.Name; yil=$_.Count; evren=[int](($_.Group | Measure-Object evren -Sum).Sum); diskte=[int](($_.Group | Measure-Object diskte -Sum).Sum); ambarda=[int](($_.Group | Measure-Object ambarda -Sum).Sum); soru=[int](($_.Group | Measure-Object soru -Sum).Sum) } })
}
$sk = $veri['siklik-kunyesi']
if($sk){ $cikmis.sgs_siklik = [pscustomobject]@{ donem=(Sayi $sk.donem_sayisi); konu=(Sayi $sk.konu_sayisi); en_cok=@(@($sk.en_cok_cikan) | Select-Object -First 12 | ForEach-Object { [pscustomobject]@{ konu="$($_.konu)"; donem=(Sayi $_.donem); soru=(Sayi $_.soru) } }) } }
$ka = $veri['kgk-analiz']
if($ka -and $ka.donemler){ $cikmis.kgk = [pscustomobject]@{ donem=@($ka.donemler).Count; soru=[int]((@($ka.donemler) | Measure-Object toplamSoru -Sum).Sum) } }
$kop = $veri['konu-koprusu']
if($kop){
  $cikmis.kopru_durum = @($kop.durum.PSObject.Properties | ForEach-Object { [pscustomobject]@{ durum=$_.Name; konu=(Sayi $_.Value) } })
  $cikmis.kopru_ders = @(@($kop.ders_koprusu) | ForEach-Object { [pscustomobject]@{ sinav="$($_.sinav)"; arsiv_ders="$($_.arsiv_ders)"; bizim_ders="$($_.bizim_ders)"; konu=(Sayi $_.konu_sayisi); koprusuz=(-not "$($_.bizim_ders)") } })
  if($kop.PSObject.Properties['karantina_donem']){ $cikmis.karantina = @(@($kop.karantina_donem) | Where-Object { $_ -and "$($_.donem)" } | ForEach-Object { "$($_.sinav) $($_.donem): $($_.sebep) ($($_.atlanan_girdi) girdi atlandı)" }) }
}

# ---------------------------------------------------------------------------
# 4) AMBAR ÖZETİ
# ---------------------------------------------------------------------------
$ambar = [ordered]@{}
$envMd = Join-Path $depoKok 'veri\AMBAR-ENVANTERI.md'
if(Test-Path $envMd){
  $ozetSatir = (Get-Content $envMd -TotalCount 8 -Encoding UTF8 | Where-Object { $_ -like '**ÖZET:*' } | Select-Object -First 1)
  $ambar.ozet_satiri = "$ozetSatir" -replace '\*\*',''
}
$bt = $veri['butunluk-raporu']
if($bt){ $ambar.butunluk = [pscustomobject]@{ tarih="$($bt.tarih)"; durum="$($bt.durum)"; belge=(Sayi $bt.belge); kaynak_temiz=(Sayi $bt.kaynak_temiz); kaynak_sorunlu=(Sayi $bt.kaynak_sorunlu); kesik_belge=(Sayi $bt.kesik_belge); oksuz_belge=(Sayi $bt.oksuz_belge) } }

# ---------------------------------------------------------------------------
# 6) YUTULMAYAN MEVZUAT (çıkmış sorulara göre)
# ---------------------------------------------------------------------------
$yutulmayan = [ordered]@{}
$dm = $veri['dayanak-metinsiz']
if($dm){
  $yutulmayan.metinsiz = [pscustomobject]@{ kopru_dayanak=(Sayi $dm.kopru_tekil_dayanak); bulunan=(Sayi $dm.ambarda_bulunan); bulunmayan=(Sayi $dm.ambarda_BULUNMAYAN); yuzde="$($dm.bulunmayan_yuzde)"; etkilenen=(Sayi $dm.etkilenen_kopru_kaydi) }
  $yutulmayan.en_cok = @(@($dm.en_cok_etkileyenler) | Select-Object -First 15 | ForEach-Object { "$_" })
}
$yutulmayan.karne = @()
foreach($cift in @(@('SGS','karne-sgs'),@('SMMM','karne-smmm'),@('KGK','karne-kgk'))){
  $kr = $veri[$cift[1]]
  if($kr -and $kr.ozet){
    $yokListe = @()
    if($kr.konular){ $yokListe = @(@($kr.konular) | Where-Object { "$($_.karar)" -eq 'KAYNAK YOK' } | Sort-Object { -(Sayi $_.cikmisSoru) } | Select-Object -First 8 | ForEach-Object { "$($_.ders) › $($_.konu) ($(Sayi $_.cikmisSoru) çıkmış)" }) }
    $yutulmayan.karne += [pscustomobject]@{ sinav=$cift[0]; uret=(Sayi $kr.ozet.URET); kaynak_yok=(Sayi $kr.ozet.'KAYNAK YOK'); mevzuat_disi=(Sayi $kr.ozet.'MEVZUAT-DISI'); olculemedi=(Sayi $kr.ozet.OLCULEMEDI); ornekler=$yokListe }
  }
}
$kl = $veri['dayanak-kara-liste']
if($kl){ $yutulmayan.kara_liste = @(@($kl.kara_liste) | ForEach-Object { if($_ -is [string]){ $_ } else { "$($_.dayanak) (yanlış %$($_.yanlis_yuzde))" } }) }

# ---------------------------------------------------------------------------
# 7) BASILMASI GEREKENLER
# ---------------------------------------------------------------------------
$basilacak = [ordered]@{}
$basilacak.ders_eksik = @($dersSatirlari | Where-Object { $_.eksik -gt 0 } | Sort-Object eksik -Descending | ForEach-Object { [pscustomobject]@{ sinav=$_.sinav; ders=$_.ders; hedef=$_.hedef; bizim=$_.bizim; eksik=$_.eksik; doluluk=$_.doluluk } })
if($kop -and $kop.agir_bosluklar){ $basilacak.agir_bosluk_sayisi = @($kop.agir_bosluklar).Count; $basilacak.agir_bosluklar = @(@($kop.agir_bosluklar) | Sort-Object { -(Sayi $_.donem) } | Select-Object -First 25 | ForEach-Object { [pscustomobject]@{ sinav="$($_.sinav)"; konu="$($_.konu)"; donem=(Sayi $_.donem); cikmis=(Sayi $_.cikmis); arsiv_ders="$($_.arsiv_ders)"; dayanak="$($_.dayanak)"; guc="$($_.guc)" } }) }
$dk = $veri['ders-karnesi']
if($dk -and $dk.dersler){ $basilacak.sgs_ders_karari = @(@($dk.dersler) | ForEach-Object { [pscustomobject]@{ ders="$($_.ders)"; hazirlik=(Sayi $_.hazirlikYuzde); karar="$($_.karar)" } }) }
$bp = $veri['bekleyen-partiler']
$basilacak.bekleyen_parti = if($null -ne $bp){ @($bp).Count } else { -1 }

# ---------------------------------------------------------------------------
# JSON (makine) — RaporYaz: içerik aynıysa dokunmaz
# ---------------------------------------------------------------------------
# PS 5.1 TUZAĞI (02.09, sinav-ders-envanteri.ps1 satır 157 de aynı yerden kırıktı):
# [ordered]@{ ... } literalinin içinde @($liste) değerleri "Argument types do not
# match" ile patlıyor. Sözlük BOŞ açılır, alanlar tek tek atanır.
$cikti = [ordered]@{}
$cikti['olcum'] = $simdi.ToString('dd.MM.yyyy HH:mm')
$cikti['kural'] = 'Sınavla ilgili VAR/YOK/KAÇ sorusunun TEK cevabı bu dosyadır. ⚠ işaretli satırın girdisi bayat ya da kırıktır: o sayı ÖLÇÜLMEDİ sayılır. Elle düzenlenmez; üretici motor/sinav-tek-sayfa.ps1.'
$cikti['kaynak_sagligi'] = $saglik.ToArray()
$cikti['sinav_ozet'] = $sinavOzet.ToArray()
$cikti['dersler'] = $dersSatirlari.ToArray()
$cikti['plan_disi_etiketler'] = $planDisi.ToArray()
$cikti['cikmis'] = $cikmis
$cikti['ambar'] = $ambar
$cikti['yutulmayan'] = $yutulmayan
$cikti['basilacak'] = $basilacak
$jsonHedef = Join-Path $depoKok 'veri\sinav-tek-sayfa.json'
$mdHedef = Join-Path $depoKok 'veri\SINAV-TEK-SAYFA.md'
$degisti = RaporYaz -Hedef $jsonHedef -Nesne $cikti -Derinlik 8
if(-not $degisti -and (Test-Path $mdHedef)){ Write-Host 'SINAV TEK SAYFA: içerik değişmedi, MD de dokunulmadı.'; exit 0 }

# ---------------------------------------------------------------------------
# MD (insan)
# ---------------------------------------------------------------------------
$sb = [Text.StringBuilder]::new()
function Satir([string]$metin){ [void]$sb.AppendLine($metin) }
Satir '# SINAV TEK SAYFA — üç sınavın tek doğru sayfası'
Satir ''
Satir "> Üretim: **$($cikti.olcum)** (makine; elle düzenlenmez — motor/sinav-tek-sayfa.ps1, günlük robot). Makine hâli: veri/sinav-tek-sayfa.json"
Satir '> **KURAL:** Sınavla ilgili "var mı / kaç tane / eksik ne" sorusunun TEK cevabı bu sayfadır. Başında **⚠** olan satırın girdisi bayat (> 7 gün) ya da kırıktır: o sayı **ölçülmedi** sayılır, önce girdisi tazelenir (bölüm 5).'
Satir '> Bu sayfa hiçbir şeyi kendisi ölçmez; ölçüm robotlarının çıktılarını birleştirir ve her sayının yanına kaynağını + tarihini yazar.'
Satir ''
Satir '| Cem''in sorusu | Bölüm |'
Satir '|---|---|'
Satir '| Hangi sınavda hangi dersler var, her dersten kaç soru çıkıyor? | 1 |'
Satir '| Çıkmış sınav soruları ders ders / konu konu ne diyor? | 2 |'
Satir '| Bastığımız sorular yeterli mi? | 3 |'
Satir '| İndirdiğimiz mevzuat ne durumda? | 4 |'
Satir '| "İndirdik mi indirmedik mi" karmaşası nasıl biter? — girdi sağlığı | 5 |'
Satir '| Çıkmış sorulara göre yutmadığımız mevzuat var mı? | 6 |'
Satir '| Basmamız gereken sorular neler? | 7 |'
Satir ''

# --- 1
$isr1 = Isaret @('ders-profili','kasa-sayim')
Satir '## 1 · SINAVLAR VE DERSLER (resmî liste × kasadaki sorumuz × onaylı kota)'
Satir ''
Satir "$($isr1)Kaynak: ders listesi = veri/ders-profili.json (TESMER Yönergesi m.6.2 / KGK ilanı / SPL) · bizim soru = veri/kasa-sayim.json ($((($saglik | Where-Object { $_.ad -eq 'kasa-sayim' }).damga))) · kota = üç kota dosyası (bölüm 5)."
Satir ''
foreach($sinavProp in $SINAV_KISA.GetEnumerator()){
  $kisa = $sinavProp.Value
  $satirlar = @($dersSatirlari | Where-Object { $_.sinav -eq $kisa })
  if(-not $satirlar.Count){ continue }
  $ozet = $sinavOzet | Where-Object { $_.sinav -eq $kisa } | Select-Object -First 1
  $baslik = "### $($sinavProp.Key) — $($satirlar.Count) ders"
  if($ozet){ $baslik += " · kasada $(Bin $ozet.kasa) soru · kota $(Bin $ozet.hedef) · eksik $(Bin $ozet.eksik)" }
  Satir $baslik
  Satir ''
  Satir '| Ders | Bölüm | Sınavda soru | Bizim soru | Kota | Eksik | Doluluk | Onay |'
  Satir '|---|---|---:|---:|---:|---:|---:|---|'
  foreach($s in $satirlar){
    $hedefM = if($s.hedef -ge 0){ Bin $s.hedef } else { 'kota yok' }
    $eksikM = if($s.eksik -ge 0){ Bin $s.eksik } else { '—' }
    $dolM = if($s.doluluk -ge 0){ "%$($s.doluluk)" } else { '—' }
    $sinavSoruM = if($s.sinav_soru -gt 0){ "$($s.sinav_soru)" } else { '—' }
    Satir "| $(K $s.ders) | $(K $s.bolum) | $sinavSoruM | $(Bin $s.bizim) | $hedefM | $eksikM | $dolM | $(K $s.onay) |"
  }
  Satir ''
}
if($planDisi.Count){
  Satir '**Kasada var ama resmî ders listesinde karşılığı bulunamayan etiketler** (kaybolmasın diye yazıldı; ders adı eşleşmesi ya da plan dışı üretim):'
  Satir ''
  foreach($p in ($planDisi | Sort-Object soru -Descending)){ Satir "- $(K $p.etiket): $(Bin $p.soru) soru" }
  Satir ''
}

# --- 2
Satir '## 2 · ÇIKMIŞ SINAV SORULARI (arşiv, ders/konu kırılımı)'
Satir ''
$isr2 = Isaret @('cikmis-karnesi')
Satir "$($isr2)**Arşiv dökümü** — kaynak veri/cikmis-soru-karnesi.json ($((($saglik | Where-Object { $_.ad -eq 'cikmis-karnesi' }).damga))). EVREN = resmî keşif, DİSKTE = indirilen, AMBARDA = yutulan kitapçık; SORU = ayrıştırılan soru."
Satir ''
if($cikmis.arsiv){
  Satir '| Sınav | Yıl sayısı | Evren | Diskte | Ambarda | Çıkarılan soru |'
  Satir '|---|---:|---:|---:|---:|---:|'
  foreach($a in $cikmis.arsiv){ Satir "| $($a.sinav) | $($a.yil) | $($a.evren) | $($a.diskte) | $($a.ambarda) | $(Bin $a.soru) |" }
  Satir ''
}
$isr2b = Isaret @('siklik-kunyesi')
if($cikmis.sgs_siklik){
  Satir "$($isr2b)**SGS sıklık künyesi** — $($cikmis.sgs_siklik.donem) dönem, $(Bin $cikmis.sgs_siklik.konu) tekil konu (veri/siklik-kunyesi.json). En çok çıkan 12 konu:"
  Satir ''
  Satir '| Ders › konu | Dönem | Soru |'
  Satir '|---|---:|---:|'
  foreach($e in $cikmis.sgs_siklik.en_cok){ Satir "| $(K $e.konu) | $($e.donem) | $($e.soru) |" }
  Satir ''
}
$isr2c = Isaret @('kgk-analiz')
if($cikmis.kgk){ Satir "$($isr2c)**KGK arşivi** — $($cikmis.kgk.donem) dönem, $(Bin $cikmis.kgk.soru) soru, tamamı etiketli (veri/kgk-analiz.json)."; Satir '' }
$isr2d = Isaret @('konu-koprusu')
if($cikmis.kopru_durum){
  Satir "$($isr2d)**Konu köprüsü** (bizim konu adları ↔ çıkmış arşiv etiketleri; veri/konu-koprusu-ozet.json — V2: sayılar canlı kasadan + arşiv analizlerinden, çıkmış dayanağı 31.08 sözlüğünden; sözlükte olmayan konu 'dayanak ölçülmedi'):"
  Satir ''
  foreach($d in $cikmis.kopru_durum){ Satir "- $(K $d.durum): $(Bin $d.konu) konu" }
  Satir ''
  if($cikmis.karantina -and @($cikmis.karantina).Count){
    Satir "**⛔ Karantinadaki arşiv dönemleri** (aynı dönemde ders kitapçıkları birbirinin aynısı çıktı; ders etiketi güvenilmez, köprüye alınmadı — yeniden indirilince kendiliğinden açılır):"
    Satir ''
    foreach($kq in $cikmis.karantina){ Satir "- $(K $kq)" }
    Satir ''
  }
  $koprusuz = @($cikmis.kopru_ders | Where-Object { $_.koprusuz })
  Satir "**Arşiv dersi → bizim ders köprüsü:** $(@($cikmis.kopru_ders).Count) arşiv ders etiketi; **$($koprusuz.Count) tanesinin bizim tarafta karşılığı yok** (köprüsüz ders = o dersin çıkmış soruları hiçbir ölçüme girmiyor)."
  if($koprusuz.Count){
    Satir ''
    Satir '| Sınav | Arşiv dersi (köprüsüz) | Konu |'
    Satir '|---|---|---:|'
    foreach($k1 in ($koprusuz | Sort-Object konu -Descending | Select-Object -First 20)){ Satir "| $($k1.sinav) | $(K $k1.arsiv_ders) | $($k1.konu) |" }
  }
  Satir ''
}

# --- 3
Satir '## 3 · BASTIĞIMIZ SORULAR YETERLİ Mİ? (kota × kasa)'
Satir ''
Satir "$(Isaret @('kasa-sayim','kota-sgs','kota-smmm','kota-kgk'))Kota = Cem'in onayladığı ders başına hedef (SGS 31.07 · SMMM 31.07 · KGK 01.08). Kasa = canlı soru_havuzu sayımı. Ders ders tablo bölüm 1'de, sıralı eksik listesi bölüm 7'de."
Satir ''
Satir '| Sınav | Ders | Kasada | Kota toplamı | Eksik | Kotasız ders |'
Satir '|---|---:|---:|---:|---:|---:|'
foreach($o in $sinavOzet){ Satir "| $($o.sinav) | $($o.ders) | $(Bin $o.kasa) | $(Bin $o.hedef) | $(Bin $o.eksik) | $($o.kotasiz_ders) |" }
Satir ''
if($basilacak.sgs_ders_karari){
  Satir "$(Isaret @('ders-karnesi'))**SGS ders kararı** (veri/ders-karnesi.json — çıkmış konuların ambarda kaynağı var mı; %100 = her çıkmış konunun kaynağı ambarda):"
  Satir ''
  Satir '| Ders | Hazırlık | Karar |'
  Satir '|---|---:|---|'
  foreach($d in $basilacak.sgs_ders_karari){ Satir "| $(K $d.ders) | %$($d.hazirlik) | $(K $d.karar) |" }
  Satir ''
}

# --- 4
Satir '## 4 · İNDİRDİĞİMİZ MEVZUAT (ambar)'
Satir ''
Satir "$(Isaret @('ambar-envanteri','butunluk-raporu'))Ambarın kaynak kaynak dökümü **veri/AMBAR-ENVANTERI.md**'dedir (VAR MI / TAM MI / GÜNCEL Mİ). Burada yalnız özet:"
Satir ''
if($ambar.ozet_satiri){ Satir "- $(K $ambar.ozet_satiri)" }
if($ambar.butunluk){ $b = $ambar.butunluk; Satir "- Bütünlük kapısı ($($b.tarih)): **$($b.durum)** · $(Bin $b.belge) belge · temiz kaynak $(Bin $b.kaynak_temiz) · sorunlu kaynak $(Bin $b.kaynak_sorunlu) · kesik belge $(Bin $b.kesik_belge) · öksüz belge $(Bin $b.oksuz_belge) (veri/butunluk-raporu.json)" }
Satir '- Yutma günlüğü (ne zaman ne yutuldu): YUTMA-LISTESI.md (kök).'
Satir ''

# --- 5
Satir '## 5 · KAYNAK SAĞLIĞI — "indirdik mi, indirmedik mi" karmaşasının bittiği yer'
Satir ''
Satir "Bu sayfanın her girdisi aşağıda. **TAZE** = ≤ $BAYAT_GUN gün · **BAYAT** = daha eski (o bölüm ⚠ alır) · **KIRIK** = dosya okunamıyor ya da HATA yazıyor. Robot sütunu 'yok' ise dosya elle koşulmadıkça tazelenmez — karmaşanın kaynağı budur; hedef her satırda bir robot olması."
Satir ''
Satir '| Girdi | Dosya | Durum | Ölçüm damgası | Dosya tarihi | Üretici | Robot |'
Satir '|---|---|---|---|---|---|---|'
foreach($s in $saglik){
  $dur = $s.durum; if($dur -ne 'TAZE'){ $dur = "**$dur**" }
  Satir "| $($s.ad) | $($s.dosya) | $dur | $(K $s.damga) | $($s.mtime) | $($s.uretici) | $(K $s.robot) |"
}
Satir ''
$bayatlar = @($saglik | Where-Object { $_.durum -ne 'TAZE' })
Satir "**Şu an TAZE olmayan girdi: $($bayatlar.Count) / $($saglik.Count).**"
Satir ''

# --- 6
Satir '## 6 · ÇIKMIŞ SORULARA GÖRE YUTMADIĞIMIZ MEVZUAT'
Satir ''
if($yutulmayan.metinsiz){
  $m = $yutulmayan.metinsiz
  Satir "$(Isaret @('dayanak-metinsiz'))**Dayanak ↔ ambar taraması** (veri/dayanak-metinsiz-raporu.json): köprüdeki $(Bin $m.kopru_dayanak) tekil dayanaktan $(Bin $m.bulunan) ambarda bulundu, **$(Bin $m.bulunmayan) bulunamadı (%$($m.yuzde))**; etkilenen köprü kaydı $(Bin $m.etkilenen). Bulunamayan dayanak = hakem doğrulayamaz, üretici kaynak çekemez → o konuda soru üretilmez (çöp değil, kaynak eksiği)."
  Satir ''
  Satir 'En çok kaydı etkileyen bulunamayan dayanaklar:'
  Satir ''
  foreach($e in $yutulmayan.en_cok){ Satir "- $(K $e)" }
  Satir ''
}
if($yutulmayan.karne){
  Satir "$(Isaret @('karne-sgs','karne-smmm','karne-kgk'))**Konu-kaynak karnesi** (her çıkmış konu için ambarda kaynak var mı; veri/konu-kaynak-karnesi*.json):"
  Satir ''
  Satir '| Sınav | ÜRET (kaynağı var) | KAYNAK YOK | MEVZUAT DIŞI | Ölçülemedi |'
  Satir '|---|---:|---:|---:|---:|'
  foreach($k2 in $yutulmayan.karne){ Satir "| $($k2.sinav) | $(Bin $k2.uret) | **$(Bin $k2.kaynak_yok)** | $(Bin $k2.mevzuat_disi) | $(Bin $k2.olculemedi) |" }
  Satir ''
  foreach($k2 in $yutulmayan.karne){ if(@($k2.ornekler).Count){ Satir "KAYNAK YOK örnekleri ($($k2.sinav)):"; foreach($o in $k2.ornekler){ Satir "- $(K $o)" }; Satir '' } }
}
if($yutulmayan.kara_liste){
  Satir "$(Isaret @('dayanak-kara-liste'))**Dayanak kara listesi** (hakemle ölçüldü, yanlış oranı > %50; üretici yok sayar — veri/dayanak-kara-liste.json):"
  Satir ''
  foreach($k3 in $yutulmayan.kara_liste){ Satir "- $(K $k3)" }
  Satir ''
}

# --- 7
Satir '## 7 · BASMAMIZ GEREKEN SORULAR'
Satir ''
Satir "$(Isaret @('kasa-sayim','kota-sgs','kota-smmm','kota-kgk'))**Ders eksikleri** (kota − kasa, büyükten küçüğe):"
Satir ''
Satir '| Sınav | Ders | Kota | Bizim | Eksik | Doluluk |'
Satir '|---|---|---:|---:|---:|---:|'
foreach($e in $basilacak.ders_eksik){ Satir "| $($e.sinav) | $(K $e.ders) | $(Bin $e.hedef) | $(Bin $e.bizim) | **$(Bin $e.eksik)** | %$($e.doluluk) |" }
Satir ''
if($basilacak.agir_bosluklar){
  Satir "$(Isaret @('konu-koprusu'))**Ağır boşluklar** — çıkmışta ≥ 3 dönem var, bizde hiç yok: $(Bin $basilacak.agir_bosluk_sayisi) konu (veri/konu-koprusu-ozet.json). En çok çıkan 25'i:"
  Satir ''
  Satir '| Sınav | Konu | Dönem | Çıkmış soru | Arşiv dersi | Dayanak | Güç |'
  Satir '|---|---|---:|---:|---|---|---|'
  foreach($a in $basilacak.agir_bosluklar){ Satir "| $($a.sinav) | $(K $a.konu) | $($a.donem) | $($a.cikmis) | $(K $a.arsiv_ders) | $(K $a.dayanak) | $($a.guc) |" }
  Satir ''
}
Satir "Bekleyen üretim partisi: $(if($basilacak.bekleyen_parti -ge 0){ $basilacak.bekleyen_parti } else { 'ölçülmedi' }) (veri/bekleyen-partiler.json)."
Satir ''
Satir '---'
Satir '_Bu sayfayı elle düzenleme; girdisini düzelt, robot yeniden yazar._'

[IO.File]::WriteAllText($mdHedef, $sb.ToString(), [Text.UTF8Encoding]::new($false))
Write-Host "SINAV TEK SAYFA yazıldı: $($dersSatirlari.Count) ders · taze olmayan girdi $($bayatlar.Count)/$($saglik.Count) · ders eksik satırı $(@($basilacak.ders_eksik).Count)"
