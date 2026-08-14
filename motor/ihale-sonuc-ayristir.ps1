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
$kls  = Join-Path ([IO.Path]::GetTempPath()) "tetikte-bulten"

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

function SonuclariCoz([string]$metin, [string]$tur){
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
foreach($t in @('Mal','Yapim','Hizmet')){
  $p = Join-Path $kls ("sonuc-{0}.txt" -f $t.ToLower())
  if(-not (Test-Path $p)){ Write-Host ("{0,-8}: sonuc metni yok (once motor/ihale-bulten-hasat.ps1)" -f $t); continue }
  $m = [IO.File]::ReadAllText($p,[Text.Encoding]::UTF8)
  $c = @(SonuclariCoz $m $t)
  Write-Host ("{0,-8}: {1} sonuc ilani" -f $t, $c.Count)
  if($m.Length -gt 50000 -and $c.Count -eq 0){ Write-Host ("   !! UYARI: {0} sonuc bulteni {1:N0} karakter geldi ama HIC kayit cikmadi" -f $t, $m.Length) }
  foreach($x in $c){ [void]$hepsi.Add($x) }
}
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
  $yol = Join-Path $kok "veri\ihale-sonuc.json"
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
