# ============================================================================
#  KAMU IHALE BULTENI - SONUC ILANLARI AYRISTIRICI (14.08.2026)
#
#  Cem: "EKAP isini cozersek super olacak, ordaki bilgileri almamiz lazim."
#
#  BULGU: bulten ZIP'inde IKI PDF varmis, ikincisini her gun cope atiyormusuz.
#    BULTEN_<tarih>_<TUR>.pdf        ->  ihale ilanlari      (3,2 MB)
#    BULTEN_<tarih>_<TUR>_SONUC.pdf  ->  SONUC ilanlari     (12,1 MB)
#
#  SONUC ILANI NEDEN KIYMETLI:
#  Yaklasik maliyet ihale ILANINDA aciklanmaz (4734) - bu yuzden acik ihalelerde
#  ancak m.13 ilan suresinden TAVAN cikarabiliyoruz. Ama ihale bitince SONUC
#  ilaninda yaklasik maliyet AYNEN yazilir; yanina sozlesme bedeli, kazanan
#  firma, kac kisi dokuman indirdi ve kac teklif geldigi de eklenir.
#
#  Birebir ornek (14.08 bulteni, 2026/1401837):
#    Yaklasik Maliyet : 2.948.333,33 TRY
#    Dokuman indiren  : 2      Toplam teklif : 1
#    Sozlesme bedeli  : 2.750.000,00 TRY
#    Yuklenici        : Avcan Tasimacilik ... Ltd. Sti.
#    -> kirim orani %6,7
#
#  BUNUN ISE YARADIGI YER: teklif verecek kisi "bu is gercekte kaca yapiliyor,
#  ne kadar kirim var, kac kisi giriyor" diye sorar. Acik ilan bunu soylemez;
#  gecmis SONUC ilanlari soyler.
#
#  RAKAM DISIPLINI: her alan ilan metninde YAZDIGI gibi alinir. Kirim orani
#  hesaplanan tek deger, o da iki YAZILI tutarin oranidir.
#  OLCUM betigi - -Yaz verilmedikce dosya yazmaz.
# ============================================================================
param([switch]$Yaz, [int]$Ornek = 0)
$ErrorActionPreference = "Continue"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
# PARALEL SERIT (30.08): 36 aylik yutma tek seritte ~14 saat surer. Serit serit
# bolununce her serit KENDI gecici klasorune indirmeli, yoksa ikisi ayni
# sonuc-mal.txt'yi ezer ve biri digerinin bultenini ayristirir - sessiz, en kotu
# tur hata. Klasor disaridan verilebilir; verilmezse eski davranis aynen.
$kls  = if("$($env:IHALE_BULTEN_KLASOR)".Trim()){ $env:IHALE_BULTEN_KLASOR }
        else { Join-Path ([IO.Path]::GetTempPath()) "tetikte-bulten" }
# 🔴 IS KLASORU (30.08, yutma sirasinda olculdu): indirme klasoru serit serit
# ayrilmisti ama ARA DOSYALAR (gunluk havuz + kosu damgasi) hala ORTAKTI.
# Alti serit ayni veri\ihale-sonuc.json ve ihale-son-kosu-damga.json'a yazinca:
#   - "dosyaya erisemiyor" hatalari (serit-0)
#   - bir serit BASKA seridin damgasini okuyup sahte "ARSIV VERMEDI" yazdi
#     (istenen 2025-09-22, gelen 2026-08-27) ve o gunu KALICI atlama listesine
#     soktu -> sessiz kapsam kaybi.
# Ara dosyalar artik seridin kendi klasorunde. Verilmezse eski davranis aynen.
$isKls = if("$($env:IHALE_IS_KLASORU)".Trim()){ $env:IHALE_IS_KLASORU } else { Join-Path $kok 'veri' }
if(-not (Test-Path $isKls)){ New-Item -ItemType Directory -Force $isKls | Out-Null }

function Alan([string]$b, [string]$d){
  $m = [regex]::Match($b, $d)
  if($m.Success){ return ($m.Groups[1].Value -replace '\s+',' ').Trim() }
  return ""
}
function Para([string]$s){
  # "2.948.333,33 TRY" -> 2948333.33   (yazili degeri sayiya cevirir, yuvarlamaz)
  if(-not $s){ return $null }
  $t = ($s -replace '[^\d.,]','') -replace '\.',''
  $t = $t -replace ',','.'
  $d = 0.0
  if([double]::TryParse($t, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$d)){ return $d }
  return $null
}

# ===== BULTEN DAMGASI (30.08.2026) =========================================
# Kaydin HANGI GUNUN bulteninden geldigi bugune kadar hicbir yere yazilmiyordu;
# "hangi gunler kasada, hangileri eksik" sorusu bu yuzden cevapsizdi.
#
# Tarih UYDURULMAZ, KAYNAKTAN okunur: bultenin her sayfasinin ust bilgisinde
# "27 AĞUSTOS 2026 – Sayı 5686" yazili (tek gunun Mal bulteninde 919 kez,
# hepsi ayni - 30.08'de olculdu). Asagidaki SonuclariCoz bu satiri sayfa
# altbilgisi diye SILIYOR; damga o yuzden silmeden ONCE alinir.
#
# NIYE "-Tarih parametresinden al" DEGIL: hasat betigi arsiv formunu yanlis
# doldurursa KIK sessizce BUGUNUN bultenini dondurur (14.08'de bir kez oldu).
# Istenen gun ile GELEN gun ancak kaynaktan okunursa karsilastirilabilir;
# backfill bu farki gorunce o gunu "yapildi" diye kutuge YAZMAZ.
$script:AYLAR = @{ 'OCAK'=1;'ŞUBAT'=2;'MART'=3;'NİSAN'=4;'MAYIS'=5;'HAZİRAN'=6
                   'TEMMUZ'=7;'AĞUSTOS'=8;'EYLÜL'=9;'EKİM'=10;'KASIM'=11;'ARALIK'=12 }
function BultenDamgasi([string]$hamMetin){
  $d = $hamMetin -replace '\s+',' '
  $m = [regex]::Match($d, '(\d{1,2})\s+(OCAK|ŞUBAT|MART|NİSAN|MAYIS|HAZİRAN|TEMMUZ|AĞUSTOS|EYLÜL|EKİM|KASIM|ARALIK)\s+(\d{4})\s*[–—-]\s*Sayı\s*(\d+)')
  if(-not $m.Success){ return @{ tarih = $null; sayi = $null } }
  $ay = $script:AYLAR[$m.Groups[2].Value]
  if(-not $ay){ return @{ tarih = $null; sayi = $null } }
  return @{
    tarih = ('{0:0000}-{1:00}-{2:00}' -f [int]$m.Groups[3].Value, $ay, [int]$m.Groups[1].Value)
    sayi  = [int]$m.Groups[4].Value
  }
}

# ===== TAM INDI MI (30.08.2026, Cem: "tam indirdigimizi BILELIM") ==========
# Bultenin KENDI icinde capraz kontrolu var: basindaki ICINDEKILER bolumu o
# gunun butun IKN'lerini listeler, govde ayni IKN'leri tekrarlar.
# 27.08 Mal bulteninde olculdu: ICINDEKILER 225 tekil IKN · govde 225 · fark 0.
#
# NIYE ISE YARAR: indirme yarida keserse ya da PDF->metin bir sayfa dusurse
# GOVDE kucululur, ICINDEKILER aynen kalir - fark aninda gorunur. Kendi
# sayimimizi kendi sayimimizla degil, KAYNAGIN kendi listesiyle denetliyoruz.
# ("yesil kosu = tam veri degildir" kuralinin bu hattaki karsiligi)
function TamlikOlc([string]$hamMetin){
  $d = $hamMetin -replace '\s+',' '
  $ilk = $d.IndexOf('İhale kayıt numarası')
  $b = -1
  foreach($mm in [regex]::Matches($d, '1\.\s*İHALE SONUÇLARININ İLANLARI')){
    if($ilk -lt 0 -or $mm.Index -lt $ilk){ $b = $mm.Index } else { break }
  }
  if($b -lt 0){ return @{ beklenen = $null; bulunan = $null; eksik = @() } }
  $ic  = $d.Substring(0, $b)
  $gov = $d.Substring($b)
  $toc = @([regex]::Matches($ic,  '(\d{4}/\d{5,8})') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique)
  $gvd = @([regex]::Matches($gov, 'İhale kayıt numarası\s*:\s*(\d{4}/\d+)') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique)
  # 🔴 OLCUT DUZELTMESI (31.08, 2.038 satirda olculdu):
  # "bulunan = govdedeki tekil IKN" idi ve tamlik esitlikle olculuyordu. Ama
  # govde ICINDEKILER'den FAZLA da cikabiliyor (471 satirda oldu; ort. 1-2 ilan
  # icindekiler dizininde gorunmuyor ama govdede var). Fazlalik KAYIP DEGILDIR;
  # buna ragmen gun "EKSIK" damgalaniyor ve sonsuza kadar yeniden cekiliyordu.
  # Dogru soru: "ICINDEKILER'deki bir ilan govdede YOK mu?"
  # Bu yuzden bulunan = ICINDEKILER'den govdede BULUNAN sayisi. Boylece
  # tam = (beklenen = bulunan) tam olarak "hic ilan dusmedi" demek olur ve
  # kasadaki ihale_kutuk_yaz'in esitlik mantigi degistirilmeden dogru calisir.
  # Govdenin kendi toplami ayrica tasinir (log icin), olcute girmez.
  $eksik = @($toc | Where-Object { $gvd -notcontains $_ })
  return @{
    beklenen = $toc.Count
    bulunan  = $toc.Count - $eksik.Count
    govde    = $gvd.Count
    eksik    = $eksik
  }
}

function SonuclariCoz([string]$metin, [string]$tur){
  $damga = BultenDamgasi $metin
  $duz = $metin -replace '\s+',' '
  # sayfa altbilgisi ilan metninin ortasina dusuyor (ilan ayristiricisinda da
  # ayni tuzak vardi) - kaynakta silinir
  foreach($kalip in @(
    'Kamu İhale Kurumu\s*[–—-]\s*www\.kik\.gov\.tr\s*\d{0,4}',
    'KAMU İHALE BÜLTENİ',
    '\d{1,2}\s+(?:OCAK|ŞUBAT|MART|NİSAN|MAYIS|HAZİRAN|TEMMUZ|AĞUSTOS|EYLÜL|EKİM|KASIM|ARALIK)\s+\d{4}\s*[–—-]\s*Sayı\s*\d+',
    '(?:MAL ALIMI|YAPIM İŞLERİ|HİZMET ALIMI|DANIŞMANLIK HİZMET ALIMI)\s+İHALELERİ BÜLTENİ\s*[–—-]?\s*(?:Sonuç İlanları)?'
  )){ $duz = $duz -replace $kalip, ' ' }
  $duz = $duz -replace '\s+',' '

  # ilan bolumu: icindekiler tablosunu atla, "1. İHALE SONUÇLARININ İLANLARI"
  # basliginin IKINCI gecisinden sonrasi gercek govdedir
  # SABIT/SIRA VARSAYIMI YERINE YAPISAL OLCUT (14.08 dersi): ilan ayristiricisinda
  # "20000. karakterden sonra ara" varsayimi, bulten kucululunce 77 ilani sessizce
  # sifirlamisti. Buradaki "ikinci gecisi al" varsayimi da ayni aileden. Dogrusu:
  # ilk "İhale kayıt numarası"ndan ONCEKI son bolum basligi (icindekilerde IKN yok).
  $ilkIkn = $duz.IndexOf('İhale kayıt numarası')
  $b = -1
  foreach($mm in [regex]::Matches($duz, '1\.\s*İHALE SONUÇLARININ İLANLARI')){
    if($ilkIkn -lt 0 -or $mm.Index -lt $ilkIkn){ $b = $mm.Index } else { break }
  }
  if($b -lt 0){ $b = 0 }
  $govde = $duz.Substring($b)

  # her sonuc ilani "İhale kayıt numarası : yyyy/nnnn" ile baslar
  $bas = [regex]::Matches($govde, 'İhale kayıt numarası\s*:\s*(\d{4}/\d+)')
  $sonuc = New-Object Collections.ArrayList
  for($i=0; $i -lt $bas.Count; $i++){
    $bit = if($i+1 -lt $bas.Count){ $bas[$i+1].Index } else { $govde.Length }
    $bl  = $govde.Substring($bas[$i].Index, $bit - $bas[$i].Index)
    $onek = $govde.Substring([math]::Max(0, $bas[$i].Index-600), [math]::Min(600, $bas[$i].Index))

    $ymTxt = Alan $bl 'Yaklaşık Maliyeti\s*:\s*([\d.,]+\s*[A-Z]{0,3})'
    $sbTxt = Alan $bl 'b\)\s*Bedeli\s*:\s*([\d.,]+\s*[A-Z]{0,3})'
    $ym = Para $ymTxt
    $sb = Para $sbTxt
    $rec = [ordered]@{
      ikn        = $bas[$i].Groups[1].Value
      tur        = $tur
      # kaynagin kendi ust bilgisinden okundu (bkz. BultenDamgasi)
      bultenTarih = $damga.tarih
      bultenSayi  = $damga.sayi
      # TUZAK (olculdu): kapsam disi ilanlarda "b) Yapılacağı..." satiri YOK;
      # desen 180 karakter tasip "3- Teklifler a) Toplam Teklif Sayısı :6"
      # kuyrugunu is adina katiyordu (2026/1270737'de gorundu).
      isAdi      = (Alan $bl 'a\)\s*Adı\s*:\s*(.{3,180}?)\s*(?:b\)|3-\s*Teklifler|2-\s*İhale)')
      # TUZAK (gozle yakalandi): onek "SONUÇ İLANI 31. 2026/1138413 AKARYAKIT SATIN
      # ALINACAKTIR AKARYAKIT SATIN ALINACAKTIR ELAZIĞ İL ÖZEL İDARESİ" seklinde -
      # ilan basligi IKI KEZ tekrarlaniyor, idare en sonda. Kurum-soneki deseni
      # soldan basladigi icin basligi da iceri aliyordu.
      # COZUM: onekten, ilan basliginin SON bitis kelimesinden ("ALINACAKTIR",
      # "ALIMI", "YAPTIRILACAKTIR"...) sonraki kisim alinir; idare orasidir.
      idare      = $(
        $on2 = $onek
        $sonBas = [regex]::Matches($on2, '(?:ALINACAKTIR|YAPTIRILACAKTIR|EDİLECEKTİR|KİRALANACAKTIR|ALIMI|İŞİ)\s+')
        if($sonBas.Count){ $son = $sonBas[$sonBas.Count-1]; $on2 = $on2.Substring($son.Index + $son.Length) }
        $id = Alan $on2 '^([A-ZÇĞİÖŞÜ][A-ZÇĞİÖŞÜ0-9 .,\-/()]{6,130}?(?:MÜDÜRLÜĞÜ|BAŞKANLIĞI|BAKANLIĞI|REKTÖRLÜĞÜ|BELEDİYESİ|ŞİRKETİ|HASTANESİ|ÜNİVERSİTESİ|KURUMU|KOMUTANLIĞI|VALİLİĞİ|DAİRESİ|SEKRETERLİĞİ|BİRLİĞİ|İDARESİ))\s*$'
        if(-not $id){ $id = Alan $on2 '^([A-ZÇĞİÖŞÜ][A-ZÇĞİÖŞÜ0-9 .,\-/()]{8,130})\s*$' }
        if(-not $id){ $id = Alan $onek '([A-ZÇĞİÖŞÜ][A-ZÇĞİÖŞÜ0-9 .,\-/()]{6,120}?(?:MÜDÜRLÜĞÜ|BAŞKANLIĞI|BAKANLIĞI|REKTÖRLÜĞÜ|BELEDİYESİ|ŞİRKETİ|HASTANESİ|ÜNİVERSİTESİ|KURUMU|KOMUTANLIĞI|VALİLİĞİ|DAİRESİ|İDARESİ))\s*$' }
        $id)
      ihaleTarih = (Alan $bl 'a\)\s*Tarihi\s*:\s*([\d.]+)')
      ihaleTuru  = (Alan $bl 'b\)\s*Türü\s*:\s*([^:]{3,40}?)\s*c\)')
      usul       = (Alan $bl 'c\)\s*Usulü\s*:\s*([^:]{3,60}?)\s*[de]\)')
      yaklasikMaliyet = $ym
      ymBirim         = (Alan $bl 'Yaklaşık Maliyeti\s*:\s*[\d.,]+\s*([A-Z]{3})')
      sbBirim         = (Alan $bl 'b\)\s*Bedeli\s*:\s*[\d.,]+\s*([A-Z]{3})')
      dokumanIndiren  = (Alan $bl 'Dokümanı EKAP üzerinden\s*:?\s*(\d+)\s*e-imza')
      teklifSayisi    = (Alan $bl 'Toplam Teklif Sayısı\s*:?\s*(\d+)')
      gecerliTeklif   = (Alan $bl 'Toplam Geçerli Teklif Sayısı\s*:?\s*(\d+)')
      yerliAvantaj    = (Alan $bl 'fiyat avantajı uygulaması\s*:?\s*([^:]{3,40}?)\s*4-')
      sozlesmeTarih   = (Alan $bl 'a\)\s*Tarihi\s*:\s*([\d.]+)\s*b\)\s*Bedeli')
      sozlesmeBedeli  = $sb
      # TUZAK 1 (olculdu): alan adi iki turlu - 4734 kapsaminda "d) Yüklenicisi",
      #   kapsam disi (3-g) ilanlarda "d) Yüklenici". Eski desen yalniz ilkini
      #   ariyordu -> %25 doluluk.
      # TUZAK 2 (olculdu, hasat betiginde zaten belgeliydi): PDF tablo hucresi
      #   DIKEY ORTALI oldugu icin uzun firma adi etiketin HEM ONUNE HEM ARDINA
      #   tasiyor: "İren Makina ... Limited  d) Yüklenici :  Şirketi".
      #   Cozum: once etiket silinir, sonra firma adi sirket ekiyle yakalanir.
      yuklenici       = $(
        $tmz = $bl -replace 'd\)\s*Yüklenicisi?\s*:', ' '
        $tmz = $tmz -replace '\s+',' '
        $y = Alan $tmz '([A-ZÇĞİÖŞÜ][^:]{4,170}?(?:Limited Şirketi|Anonim Şirketi|Ltd\.? ?Şti\.?|A\.Ş\.|Kooperatifi|Sanayi ve Ticaret))\s*e\)'
        if(-not $y){ $y = Alan $bl 'd\)\s*Yüklenicisi?\s*:\s*(.{3,170}?)\s*e\)' }
        $y)
      # kismi teklife acik ihale kaniti (asagida kullanilir)
      kisimKaniti = ($bl -match 'Sözleşmeye Esas Kısımlarının')
      # kirim asagida, KISIMLI ihale ayikladiktan SONRA hesaplanir (bkz. not)
      kirimYuzde = $null
    }
    [void]$sonuc.Add($rec)
  }
  return $sonuc
}

$hepsi = New-Object Collections.ArrayList
# KOSU DAMGASI (30.08): bu kosuda HANGI bultenin islendigi disari yazilir.
# Backfill bunu iki is icin okur: (1) istedigi gun ile GELEN gunu karsilastirip
# yanlis bulteni "yapildi" saymamak, (2) kasadaki kutuge (gun,tur,sayi,kayit)
# satirini yazmak. Kutuk olmadan "hangi gun eksik" sorusu cevapsizdir.
$damgalar = New-Object Collections.ArrayList
# IS KOLU DORT (30.08, Cem sarti). KIK bulten sayfasindaki "Ihale Turu"
# listesinden okundu: Mal(1) · Yapim(2) · Hizmet(3) · Danismanlik(4).
# 30.08'e kadar burada UC tur donuyordu; gunluk is akisi Danismanlik bultenini
# INDIRIYOR ama bu dongu ona hic bakmiyordu - koca bir is kolu sessizce
# cope gidiyordu (27.08 olcumu: Danismanlik sonuc bulteni 1 ilan).
$eksikTur = @()
foreach($t in @('Mal','Yapim','Hizmet','Danismanlik')){
  $p = Join-Path $kls ("sonuc-{0}.txt" -f $t.ToLower())
  if(-not (Test-Path $p)){
    # 🔴 "INDIRME DUSTU" ile "O GUN BULTEN YOK" AYRIMI (31.08 olculdu):
    # 349 Danismanlik gunu "indirilemedi" sayiliyordu ve o gunler HICBIR ZAMAN
    # tamamlanamiyordu - her kosuda yeniden cekiliyorlardi. Olcum: 25.10.2023
    # icin zip 988 KB olarak INDI, icinde ilan PDF'i vardi ama SONUC PDF'i YOKTU.
    # Yani KIK o gun o is kolunda sonuc bulteni yayimlamamis. Indirme hatasi degil.
    # AYIRT EDICI: zip/pdf klasorde duruyorsa indirme BASARILI olmus, sonuc
    # bolumu yok demektir -> "bulten yok/bos" (kutuge 0 kayitla TAM yazilir).
    # Zip de yoksa gercekten inmemistir -> "indirilemedi" (gun geri gelir).
    $zip = Join-Path $kls ("bulten-{0}.zip" -f $t.ToLower())
    $pdf = Join-Path $kls ("bulten-{0}.pdf" -f $t.ToLower())
    $ham = Join-Path $kls ("bulten-{0}.ham" -f $t.ToLower())
    $indi = (Test-Path $zip) -or (Test-Path $pdf)
    $sbp  = if($indi){ 'bulten yok/bos' } else { 'indirilemedi' }
    # 🔴 IKINCI AYIRT EDICI (31.08 olculdu): 249 Danismanlik gunu hala
    # "indirilemedi" kaliyordu ve hicbir zaman tamamlanamiyordu. Olcum
    # (19.08.2026, Danismanlik): sunucu 200 dondu ama zip vermedi - gelen sey
    # EKAP arsiv sayfasinin KENDISI (37 KB HTML). Yani baglanti kurulmus,
    # istek islenmis, o gun o is kolunda bulten YOK.
    # Bayt duzeyinde kesin: zip 'PK' (0x50 0x4B) ile baslar, HTML '<' ile.
    # ham cevap var ama zip degilse -> sunucu cevapladi, bulten yok.
    # ham hic yoksa -> baglanti kurulamadi, gercekten indirilemedi.
    if(-not $indi -and (Test-Path $ham)){
      try{
        $bay = [IO.File]::ReadAllBytes($ham)
        if($bay.Length -gt 2 -and -not ($bay[0] -eq 0x50 -and $bay[1] -eq 0x4B)){
          $sbp = 'bulten yok/bos'
        }
      }catch{}
    }
    Write-Host ("{0,-12}: sonuc metni yok -> {1}" -f $t, $sbp)
    [void]$damgalar.Add([ordered]@{ tur=$t; tarih=$null; sayi=$null; kayit=0
                                    beklenen=$null; bulunan=$null; tam=$false; eksikIkn=@(); sebep=$sbp })
    if(-not $indi){ $eksikTur += $t }
    continue
  }
  $m = [IO.File]::ReadAllText($p,[Text.Encoding]::UTF8)
  $c  = @(SonuclariCoz $m $t)
  $dm = BultenDamgasi $m
  $tm = TamlikOlc $m
  $tam = ($null -ne $tm.beklenen -and $null -ne $tm.bulunan -and $tm.beklenen -eq $tm.bulunan)
  Write-Host ("{0,-12}: {1,5} kayit · bulten {2} (sayi {3}) · icindekiler {4} / bulunan {5} (govde {6}) -> {7}" -f `
              $t, $c.Count, $(if($dm.tarih){$dm.tarih}else{'OKUNAMADI'}), $dm.sayi,
              $tm.beklenen, $tm.bulunan, $tm.govde, $(if($tam){'TAM'}else{'EKSIK'}))
  if(-not $tam -and $tm.eksik.Count){
    $eksikTur += $t
    Write-Host ("   !! {0} ilan ICINDEKILER'de var, govdede YOK: {1}" -f $tm.eksik.Count, (($tm.eksik | Select-Object -First 6) -join ', '))
  }
  if($m.Length -gt 50000 -and $c.Count -eq 0){ Write-Host ("   !! UYARI: {0} sonuc bulteni {1:N0} karakter geldi ama HIC kayit cikmadi" -f $t, $m.Length) }
  $sebep = if($c.Count -gt 0){ $null } elseif($m.Length -lt 50000){ 'bulten yok/bos' } else { 'ayristirilamadi' }
  [void]$damgalar.Add([ordered]@{ tur=$t; tarih=$dm.tarih; sayi=$dm.sayi; kayit=$c.Count
                                  beklenen=$tm.beklenen; bulunan=$tm.bulunan; tam=$tam
                                  eksikIkn=@($tm.eksik); sebep=$sebep })
  foreach($x in $c){ [void]$hepsi.Add($x) }
}
if($eksikTur.Count){
  Write-Host ("`n!! TAM INMEDI: {0} · bu gun kutuge 'tam' diye YAZILMAZ, yeniden cekilir." -f ($eksikTur -join ', '))
}
# Damga dosyasi BOS KOSUDA DA yazilir: "cekildi ama bostu" ile "hic cekilmedi"
# ayri seylerdir; ayirmayan kutuk yalan soyler.
($damgalar | ConvertTo-Json -Depth 4) | Out-File (Join-Path $isKls "ihale-son-kosu-damga.json") -Encoding utf8
if(-not $hepsi.Count){ Write-Host "Hic sonuc ilani cikmadi."; if($Yaz){ exit 1 }; return }

# ===== KISIMLI IHALE TUZAGI (14.08 olculdu, ilk hesap YANLISTI) =============
# Ilk turda "ortalama kirim %89,9" cikti - imkansiz bir rakam. Sebep: KISMI
# teklife acik ihaleler. Bir ihale kisimlara bolunup ayri firmalara veriliyor,
# her kisim icin AYRI sozlesme bloguu yaziliyor; ama "Yaklasik Maliyet"
# IHALENIN TAMAMINA ait. Yani 8.123.960 TL'lik ihalenin bir kismi 8.750 TL'ye
# verilmis, ben 8.750/8.123.960 diye bolup "%99,9 kirim" demistim.
# Ornek: 2026/1344107 ayni bultende IKI kez, 467.400 ve 8.750 bedelli.
#
# DOGRUSU: kirim orani YALNIZ tek sozlesmeli ihalelerde hesaplanabilir.
# Kisimlarin toplamini almak da guvenli degil - kisimlarin bir kismi baska
# gunun bulteninde sonuclanmis olabilir, elimizdeki toplam eksik kalir.
# Kisimli ihalede kirim NULL birakilir ve kayda "kisimli" damgasi vurulur.
# OLCUT DUZELTILDI (2. tur): once "ayni IKN birden fazla kez geciyorsa kisimli"
# demistim. Eksikti - 2026/1336834 bultende TEK kez geciyor ama 1,6 milyonluk
# ihalenin 15.750 TL'lik bir KALEMI; digerleri baska gunun bulteninde. Yani IKN
# tekrari kismiligi tam olarak olcmuyor.
# DOGRU KANIT METINDE: kismi teklife acik ihalelerde idare "Sözleşmeye Esas
# Kısımlarının Yaklaşık Maliyeti" satirini yaziyor. Bu satir varsa ihale
# bolunmustur ve TOPLAM yaklasik maliyetle sozlesme bedelini karsilastirmak
# YANLIS olur. Iki olcut BIRLIKTE kullanilir (metin kaniti + IKN tekrari).
$iknSayim = @{}
foreach($x in $hepsi){ if($x.ikn){ $iknSayim["$($x.ikn)"] = 1 + $(if($iknSayim["$($x.ikn)"]){$iknSayim["$($x.ikn)"]}else{0}) } }
$kisimli = 0
foreach($x in $hepsi){
  $n = $iknSayim["$($x.ikn)"]
  $x['kisimSayisi'] = $n
  $x['kisimliMi']   = ($n -gt 1 -or $x.kisimKaniti)
  if($x.kisimliMi){ $kisimli++; continue }   # kirim hesaplanmaz
  $ym = $x.yaklasikMaliyet; $sb = $x.sozlesmeBedeli
  if($x.ymBirim -and $x.sbBirim -and $x.ymBirim -ne $x.sbBirim){ continue }   # farkli para birimi -> kirim yok
  if($ym -and $sb -and $ym -gt 0){
    $x['kirimYuzde'] = [math]::Round((1 - $sb/$ym)*100, 1)
  }
}
Write-Host ("`nKISIMLI ihale kaydi (kirim hesaplanmadi): {0}/{1}" -f $kisimli, $hepsi.Count)

Write-Host ("`n=== ALAN DOLULUK ({0} sonuc ilani) ===" -f $hepsi.Count)
foreach($a in @('isAdi','idare','ihaleTarih','usul','yaklasikMaliyet','dokumanIndiren','teklifSayisi','sozlesmeBedeli','yuklenici','kirimYuzde')){
  $n = @($hepsi | Where-Object { $null -ne $_.$a -and "$($_.$a)".Trim() }).Count
  Write-Host ("  {0,-16} {1,4}/{2}  %{3}" -f $a, $n, $hepsi.Count, [math]::Round(100.0*$n/$hepsi.Count))
}
# kirim istatistigi (olculen, uydurulmayan)
$kr = @($hepsi | Where-Object { $null -ne $_.kirimYuzde } | ForEach-Object { $_.kirimYuzde })
if($kr.Count){
  $s = ($kr | Measure-Object -Average -Minimum -Maximum)
  Write-Host ("`nKIRIM ORANI ({0} ihalede olculdu): ortalama %{1} · en dusuk %{2} · en yuksek %{3}" -f $kr.Count, [math]::Round($s.Average,1), $s.Minimum, $s.Maximum)
}
if($Ornek -gt 0){
  foreach($x in ($hepsi | Select-Object -First $Ornek)){
    Write-Host ("`n--- {0} · {1} ---" -f $x.ikn, $x.tur)
    $x.GetEnumerator() | ForEach-Object { if($null -ne $_.Value -and "$($_.Value)".Trim()){ Write-Host ("   {0,-16}: {1}" -f $_.Key, $_.Value) } }
  }
}
if($Yaz){
  $yol = Join-Path $isKls "ihale-sonuc.json"
  # BIRIKIMLI: gecmis sonuclar birikince "bu is kaca yapiliyor" sorusu
  # cevaplanabilir hale gelir. Ayni IKN tekrar gelirse yenisi gecerlidir.
  # ANAHTAR TUZAGI (olculdu): ilk surumde anahtar sadece IKN idi; 1395 kayit
  # ayristirilip havuza 469 yazildi - KISIMLI ihalelerin her kismi digerini
  # eziyordu (ayni IKN, farkli sozlesme). Anahtar = IKN + sozlesme tarihi +
  # bedel + yuklenici. Ayni kisim tekrar gelirse yine tek kayit kalir.
  $anahtar = { param($e) "{0}|{1}|{2}|{3}" -f $e.ikn, $e.sozlesmeTarih, $e.sozlesmeBedeli, $e.yuklenici }
  $havuz = [ordered]@{}
  if(Test-Path $yol){
    try { foreach($e in @((Get-Content $yol -Raw -Encoding UTF8 | ConvertFrom-Json).sonuclar)){ if($e.ikn){ $havuz[(& $anahtar $e)] = $e } } } catch {}
  }
  $eskiSay = $havuz.Count
  foreach($x in $hepsi){ if($x.ikn){ $havuz[(& $anahtar $x)] = $x } }
  $liste = @($havuz.Values)
  Write-Host ("`nHAVUZ: {0} eski -> {1} kayit" -f $eskiSay, $liste.Count)
  $cikti = [ordered]@{
    guncelleme = "Kaynak: Kamu İhale Bülteni — Sonuç İlanları (KİK). Son çekim: " + (Get-Date -Format "dd.MM.yyyy HH:mm") + "."
    not = "Yaklaşık maliyet ve sözleşme bedeli, sonuç ilanında idarece AÇIKLANAN tutarlardır. Kırım oranı bu iki yazılı tutarın oranıdır; başka hiçbir rakam türetilmemiştir."
    sonuclar = $liste
  }
  ($cikti | ConvertTo-Json -Depth 5) | Out-File $yol -Encoding utf8
  $geri = Get-Content $yol -Raw -Encoding UTF8 | ConvertFrom-Json
  Write-Host ("-> {0} · geri okuma: {1} kayit" -f $yol, @($geri.sonuclar).Count)
} else { Write-Host "`n(olcum modu - yazmak icin -Yaz)" }
