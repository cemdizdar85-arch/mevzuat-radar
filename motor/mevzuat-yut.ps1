# ============================================================================
#  MEVZUAT YUT (GUNLUK) — kanunu madde madde yutan, GUNCEL kalan AYNA robotu.
#  Cem: "gunluk tazeleme lazim, RG gunluk cikiyor." Ilke: hiz = kaynagin hizi.
#  AKIS: (workflow bash adimi her kanunun mevzuat.gov.tr KONSOLIDE PDF'ini
#  indirip pdftotext ile ./_txt/<slug>.txt yapar) -> bu script her kanunu
#  hash'ler; hash DEGISTIYSE (kanun guncellendi/madde iptal) O KANUNU yeniden
#  parcalar + Supabase'e yeniden yukler + belge_tarihi=BUGUN (son senkron damgasi).
#  Degismeyeni ATLAR (israf yok). EZBER DEGIL: her gun guncel kaynagin aynasi.
#  ENV: SUPABASE_SERVICE_KEY (yukleme icin; yoksa yalniz dosya uretir).
# ============================================================================
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
try { [System.Text.Encoding]::RegisterProvider([System.Text.CodePagesEncodingProvider]::Instance) } catch {}

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$SB_URL = "https://bjrleanjpyujtajmazxn.supabase.co"
$txtDir = Join-Path $kok "_txt"                 # bash adimi buraya <slug>.txt koyar
$mevzuatDir = Join-Path $kok "veri\mevzuat"
$durumYol = Join-Path $mevzuatDir "_durum.json"
$bugun = (Get-Date).ToString("yyyy-MM-dd")
if(-not (Test-Path $mevzuatDir)){ New-Item -ItemType Directory -Path $mevzuatDir -Force | Out-Null }

$manifest = Get-Content (Join-Path $kok "veri\mevzuat-kaynaklar.json") -Raw -Encoding UTF8 | ConvertFrom-Json
$durum = @{}
if(Test-Path $durumYol){ try { (Get-Content $durumYol -Raw -Encoding UTF8 | ConvertFrom-Json).PSObject.Properties | ForEach-Object { $durum[$_.Name] = $_.Value } } catch {} }

# --- madde madde parcalayici (eski "Madde N -" + modern "MADDE N-"; TR unsuz yumusamasi) ---
# 22.07.2026: taksimli madde (32/A, 32/C...) + TUM-BUYUK "EK MADDE/GECICI MADDE/MUKERRER MADDE"
# varyantlari eklendi — KVK 32/C (asgari KV) ve 7524 ek maddeleri bu desenin disinda kaliyordu.
function Parcala([string]$flatMetin, [string]$kanunAd, [string]$url){
  # 14.08 KUSUR (olculdu, Dahilde Isleme Rejimi Karari vakasi): desen madde
  # numarasindan HEMEN SONRA tire bekliyordu. Ama bazi metinlerde degisiklik
  # parantezi ARAYA giriyor ve tire ondan SONRA geliyor:
  #     "Madde 12- ..."                        <- eski desen yakaliyor
  #     "Madde 13 (Değişik: R.G.-...)- ..."    <- tire parantezten SONRA
  #     "Madde 16 (Değişik: R.G.-...) Şartlı"  <- ayrac HIC YOK
  #     "Madde 21 (Değişik: R.G.-...): Firma"  <- ayrac IKI NOKTA
  # Somut zarar: diib-karar'da m.13/16/20/21/22/23 (ihracatin gerceklestirilmesi,
  # sartli muafiyet, denetim yetkisi) ambara HIC girmemisti.
  # Kural: numaradan sonra ya DOGRUDAN tire gelir, ya da bir DEGISIKLIK PARANTEZI
  # gelir ve ardindaki ayrac istege baglidir.
  # PARANTEZ HERHANGI BIR PARANTEZ OLAMAZ (14.08 olculdu): serbest birakilinca
  # 4734'un sonundaki esik deger tablosu ve degisiklik listesindeki ATIFLAR
  # ("MADDE 3 (g)", "MADDE 21 (f)", "MADDE 53 (j)/1") madde basligi sanildi ve
  # 7 SAHTE madde uretti. Bu yuzden parantez yalniz Degisik/Mulga/Ek/Baslik
  # kaliplariyla baslarsa kabul edilir - gercek degisiklik serhleri boyledir.
  # --- BASLIK DOGRULAMA (bkz. asagida "17.08 BASLIK KIRPILMASI") -------------
  # Gercek madde basligi: cumle degildir (nokta ile bitmez), bolum basligi
  # degildir, kirik bir kelimeyle baslamaz.
  function BaslikGecerli([string]$b){
    $t = "$b".Trim()
    if($t.Length -lt 3){ return $false }
    if($t.EndsWith('.')){ return $false }                       # "Amortismana tabi tutulur."
    if($t -match '(?i)\b(KISIM|BÖLÜM|KİTAP|FASIL|AYIRIM)\s*$'){ return $false }  # "Ü KISIM"
    if($t -match '^\S{1,2}\s'){ return $false }                 # tek-iki harflik kirik bas
    if($t -match '^\d'){ return $false }                        # "3 (g)" gibi atif kalintisi
    return $true
  }

  # 30.08.2026 KUSUR (olculdu, III-45.1 vakasi): ayirici sinifi yalniz UC tire
  # taniyordu: - (U+002D), – (U+2013), — (U+2014). Ama mevzuat.gov.tr PDF'lerinin
  # bir kisminda madde ayiricisi ‒ (U+2012 FIGURE DASH) veya − (U+2212 MINUS).
  # Gozle ayirt edilemez, regex icin baska karakterdir. SESSIZ zarar:
  #   III-45.1 (Belge ve Kayit Duzeni): 33 maddenin 32'si kaciyor, tebligin
  #     TAMAMI tek "m.5/A" blobu olarak yutuluyordu (23 parcaya bolunmus).
  #   KGK Kurulus KHK 660: ambarda 1 parca / 1 madde - kaynakta 35 madde.
  #     Zaten satilan bagimsiz denetim sinavinin KURUCU mevzuati, yillardir
  #     tek blob. Envanterde satir VARDI, icerik YOKTU.
  # Kapsama kapisi bunu yakalamadi cunku metin kaybi yok - metin tek maddede
  # duruyor; kaybolan SINIRLAR. Ders: "kapsama %" madde SAYISINI olcmez.
  # Olcum: tum _txt (706 dosya) tarandi - U+2012 76 kez / 4 dosyada, U+2212 8 kez.
  $rx = [regex]'(?:(?<pre>\p{Lu}[^:]{1,70}):\s*)?(?<tur>MÜKERRER MADDE|EK GEÇİCİ MADDE|EK MADDE|GEÇİCİ MADDE|Mükerrer MADDE|Ek Geçici MADDE|Ek MADDE|Geçici MADDE|MADDE|Mükerrer Madde|Ek Geçici Madde|Ek Madde|Geçici Madde|Madde)\s+(?<no>\d+(?:/[A-ZÇĞİÖŞÜ])?)\s*(?:\(\s*(?:Değişik|Mülga|Ek|Yeniden|Başlığı|Değiştirilen)[^)]{0,140}\)\s*[:‐-―−-]?|[‐-―−-])'
  $m = $rx.Matches($flatMetin)
  $docs = New-Object System.Collections.Generic.List[object]
  for($i=0; $i -lt $m.Count; $i++){
    $start = $m[$i].Index
    $end = if($i -lt $m.Count-1){ $m[$i+1].Index } else { $flatMetin.Length }
    $govde = $flatMetin.Substring($start, $end-$start).Trim()
    $no = $m[$i].Groups['no'].Value; $tur = $m[$i].Groups['tur'].Value; $pre = $m[$i].Groups['pre'].Value.Trim()
    # 14.08 KUSUR (olculdu, Yerli Mali Tebligi vakasi): bu kontrol "(Mülga" gordugu
    # anda maddeyi atiyordu - ama "(Mülga ibare:...)" / "(Mülga fıkra:...)" MADDENIN
    # KENDISI degil, ICINDEKI bir parca mulga demektir; madde yururlukte.
    # Somut zarar: Yerli Mali Tebligi m.4 (yerli mali kabul sartlari) ve m.8 (yerli
    # katki orani formulu) ambara HIC GIRMEDI - ikisi de "(1) Sanayi (Mülga ibare:
    # RG-15/10/2025-33048) urunlerinin..." diye basliyor. Kapsama %77,7'ye dusmustu.
    # Artik yalniz MADDENIN KENDISI mulgaysa atlanir: "(Mülga:" veya "(Mülga madde".
    if($govde -match '^.{0,70}\(Mülga\s*(?:madde)?\s*:'){ continue }
    # 02.08 CEM KURALI ("ustunkoru degil, en kucuk maddesine kadar"): 60
    # karakterden kisa madde ATILIYORDU. Kisa madde de maddedir (yururluk,
    # yurutme, tanim fikralari) ve soru-cevap araci onlari da arar. Artik
    # atilmaz - onceki maddeye eklenir, yani metin kaybi sifir.
    if($govde.Length -lt 60){
      if($docs.Count -gt 0){ $docs[$docs.Count-1].metin = "$($docs[$docs.Count-1].metin) $govde" }
      continue
    }
    if($tur -match 'kerrer'){ $md = "muk. m.$no" } elseif($tur -match 'Ek Ge'){ $md = "ek gec. m.$no" } elseif($tur -match 'Ge'){ $md = "gec. m.$no" } elseif($tur -match 'Ek'){ $md = "ek m.$no" } else { $md = "m.$no" }
    # 17.08 BASLIK KIRPILMASI. Olculen iki vaka:
    #   VUK m.227 -> "Ü KISIM"                    (BESINCI/DORDUNCU KISIM kuyrugu)
    #   VUK m.315 -> "Amortismana tabi tutulur."  (onceki maddenin son CUMLESI)
    # Sebep: pre deseni maddenin onundeki metinden en fazla 70 karakter geri
    # gidiyor; baslik yoksa oradaki metnin KUYRUGUNU baslik saniyor.
    # Cozum: yakalanan basligi DOGRULA. Gecmezse baslik hic yazilmaz - kayit
    # "VUK m.315" olur. Yanlis baslik, baslik yoklugundan KOTUDUR: arama ve
    # hakem o basliga bakip maddeyi yanlis taniyor.
    if($pre -and -not (BaslikGecerli $pre)){ $pre = '' }
    $ad = if($pre){ "$kanunAd $md - $pre" } else { "$kanunAd $md" }

    # 27.07.2026 DUZELTME — 1800 KESIGI:
    # Eski hal: $govde.Substring(0,1800) -> maddenin gerisi SESSIZCE KAYBOLUYORDU.
    # Olculdu: dosyalardaki 14.961 belgenin 1.730'u (%11,6) tam 1800 karakterde
    # kesikti. Somut zarar: SMK m.5'in muvafakatname fikrasi (5/3) ambarda YOKTU;
    # 27.07'de marka basvurusunda eksik bilgiyle konusuldu, RG metnine gidilerek
    # yakalandi. En cok etkilenen: SGK 5510 (132), Gumruk Yon. (103), SSIY (61),
    # VUK (59), SPK (58), GVK (57), TTK (53).
    # Yeni hal: KESMIYOR, PARCALIYOR. Uzun madde ~1800'luk parcalara CUMLE
    # SINIRINDAN bolunur; her parca ayri kayit olur, adina [1/3] eki gelir.
    # Tam metin korunur, kayitlar aramaya/retrieval'a uygun boyutta kalir.
    $PARCA_BOY = 1800
    $parcalar = New-Object System.Collections.Generic.List[string]
    if($govde.Length -le $PARCA_BOY){ $parcalar.Add($govde) }
    else {
      $kalan = $govde
      while($kalan.Length -gt $PARCA_BOY){
        $kes = $kalan.Substring(0, $PARCA_BOY)
        $kir = $kes.LastIndexOf('. ')                     # once cumle sonu
        if($kir -lt 900){ $kir = $kes.LastIndexOf(' ') }  # olmazsa son bosluk
        if($kir -lt 900){ $kir = $PARCA_BOY - 1 }         # o da olmazsa duz kes
        $parcalar.Add($kalan.Substring(0, $kir+1).Trim())
        $kalan = $kalan.Substring($kir+1).Trim()
      }
      if($kalan.Length -gt 0){ $parcalar.Add($kalan) }
    }
    for($p=0; $p -lt $parcalar.Count; $p++){
      $adTam = if($parcalar.Count -eq 1){ $ad } else { "$ad [$($p+1)/$($parcalar.Count)]" }
      $docs.Add([ordered]@{ tur="kanun-madde"; kaynak_ad=$adTam; baslik=$pre; metin=$parcalar[$p]; kaynak_url=$url; belge_tarihi=$bugun })
    }
  }
  $g=@{}; foreach($d in $docs){ $k=$d.kaynak_ad; if($g.ContainsKey($k)){ $g[$k]++; $d.kaynak_ad="$k ($($g[$k]))" } else { $g[$k]=1 } }
  return $docs
}

# --- 01.09 KILAVUZ-BOLUM PARCALAYICISI (Cem: "KVK GUT bolucu onarimi yap") -----
# KVK GUT (1 Seri No) gibi kilavuz tebligler "10.5. Baslik" bolum yapisindadir;
# MADDE deseni metnin ICINDE alintilanan kanun maddelerini baslik sanar (olculdu:
# 505 parcada 6 sahte ana-madde + 'gec. m.3' altinda 405 parcalik yigin, 105
# sahte-kesik). docs>=5 esigi de tetiklenmedigi icin bolum-parcalayici hic
# devreye girmedi. Manifest kaydinda parcalayici='kilavuz-bolum' olan kaynaklar
# bu fonksiyonla bolunur; genel Parcala'ya DOKUNULMADI.
# Sahte-pozitif frenleri: (a) bolum no MONOTON artmali (metin ici "213." gibi
# atiflar sirayi bozar -> atilir), (b) 120 karakterden kisa bolum onceki bolume
# eklenir (metin kaybi sifir), (c) tarih deseni (31.12.2025) eslesemez cunku
# no parcalari en fazla 2 hane + ardindan BUYUK harf sarti var.
function ParcalaKilavuz([string]$flatMetin, [string]$kanunAd, [string]$url){
  $rx = [regex]'(?<=\s)(?<no>\d{1,2}(?:\.\d{1,2}){0,3})\.\s+(?=[A-ZÇĞİÖŞÜ])'
  $adaylar = $rx.Matches($flatMetin)
  function NoParcala([string]$n){ @($n -split '\.') | ForEach-Object { [int]$_ } }
  function NoKiyas($a,$b){ # a<b => -1
    $pa=NoParcala $a; $pb=NoParcala $b
    for($q=0;$q -lt [Math]::Max($pa.Count,$pb.Count);$q++){
      $x=if($q -lt $pa.Count){$pa[$q]}else{-1}; $y=if($q -lt $pb.Count){$pb[$q]}else{-1}
      if($x -ne $y){ return [Math]::Sign($x-$y) }
    }
    return 0
  }
  $kabul = New-Object System.Collections.Generic.List[object]
  $onceki = '0'
  foreach($a in $adaylar){
    $no=$a.Groups['no'].Value
    if((NoKiyas $onceki $no) -lt 0){ $kabul.Add(@{no=$no;idx=$a.Index}); $onceki=$no }
  }
  $docs = New-Object System.Collections.Generic.List[object]
  for($i=0; $i -lt $kabul.Count; $i++){
    $start=$kabul[$i].idx
    $end = if($i -lt $kabul.Count-1){ $kabul[$i+1].idx } else { $flatMetin.Length }
    $govde = $flatMetin.Substring($start, $end-$start).Trim()
    if($govde.Length -lt 120){
      if($docs.Count -gt 0){ $docs[$docs.Count-1].metin = "$($docs[$docs.Count-1].metin) $govde" }
      continue
    }
    $ad = "$kanunAd b.$($kabul[$i].no)"
    $PARCA_BOY = 1800
    $parcalar = New-Object System.Collections.Generic.List[string]
    if($govde.Length -le $PARCA_BOY){ $parcalar.Add($govde) }
    else {
      $kalan = $govde
      while($kalan.Length -gt $PARCA_BOY){
        $kes = $kalan.Substring(0, $PARCA_BOY)
        $kir = $kes.LastIndexOf('. ')
        if($kir -lt 900){ $kir = $kes.LastIndexOf(' ') }
        if($kir -lt 900){ $kir = $PARCA_BOY - 1 }
        $parcalar.Add($kalan.Substring(0, $kir+1).Trim())
        $kalan = $kalan.Substring($kir+1).Trim()
      }
      if($kalan.Length -gt 0){ $parcalar.Add($kalan) }
    }
    for($p=0; $p -lt $parcalar.Count; $p++){
      $adTam = if($parcalar.Count -eq 1){ $ad } else { "$ad [$($p+1)/$($parcalar.Count)]" }
      $docs.Add([ordered]@{ tur="kanun-madde"; kaynak_ad=$adTam; baslik=''; metin=$parcalar[$p]; kaynak_url=$url; belge_tarihi=$bugun })
    }
  }
  $g=@{}; foreach($d in $docs){ $k=$d.kaynak_ad; if($g.ContainsKey($k)){ $g[$k]++; $d.kaynak_ad="$k ($($g[$k]))" } else { $g[$k]=1 } }
  return $docs
}

function Sha([string]$s){ $sha=[Security.Cryptography.SHA256]::Create(); ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($s))) -replace '-','').Substring(0,16) }

$SB_ANAHTAR = $env:SUPABASE_SERVICE_KEY
# 07.08: sb_secret anahtar robot User-Agent ister ("Forbidden use of secret API
# key in browser") - UA'siz IRM tarayici sayilip TUM ekleri reddediyordu.
$H = if($SB_ANAHTAR){ @{ apikey=$SB_ANAHTAR; Authorization="Bearer $SB_ANAHTAR"; 'User-Agent'='mevzuat-radar-robot/1.0' } } else { $null }
$degisen = New-Object System.Collections.Generic.List[string]

foreach($law in $manifest.kanunlar){
  # ==========================================================================
  #  SADECE filtresi (05.08 - kurtarma hatti icin)
  #
  #  NEDEN: son 5 gunluk-ayna kosusunun BESI de iptal (03.08 12:42'den beri).
  #  Olum sarmali: kosu 6 saatlik GitHub tavaninda oluyor -> _durum.json hic
  #  commit'lenmiyor -> sonraki kosu her seyi "ilk kez" sanip 650 kaynagi
  #  bastan indiriyor -> yine tavana takiliyor. Sonuc: 2 gundur ambara TEK
  #  kaynak inmedi; 6 SMMM yonetmeligi de bu batakta bekliyordu.
  #
  #  SADECE="slug1,slug2" verilirse yalniz o kaynaklar islenir - kucuk
  #  kurtarma kosulari tam turun kaderine bagli olmaz. Bos/verilmemisse
  #  davranis eskisiyle BIREBIR ayni (tam tur).
  # ==========================================================================
  if("$($env:SADECE)".Trim() -ne ''){
    $sadeceListe = @("$($env:SADECE)" -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
    if($sadeceListe -notcontains "$($law.slug)"){ continue }
  }
  $txt = Join-Path $txtDir "$($law.slug).txt"
  if(-not (Test-Path $txt)){
    # YEDEK YOL: indirme basarisiz (mevzuat.gov.tr runner'a yavas/kapali olabilir).
    # Kanun _durum'da hic yoksa (hic yuklenmemis) ama repoda hazir JSON varsa ONDAN yukle.
    # _durum'a hash YAZILMAZ -> kaynak indirilebildigi ilk gun gercek metinden yeniden yutulur.
    $hazirJson = Join-Path $mevzuatDir "$($law.slug).json"
    if($H -and -not $durum.ContainsKey($law.slug) -and (Test-Path $hazirJson)){
      try {
        $hd = (Get-Content $hazirJson -Raw -Encoding UTF8 | ConvertFrom-Json).belgeler
        foreach($d in @($hd)){ if($d.tur -eq 'kanun' -or -not $d.tur){ $d.tur = 'kanun-madde' } }   # 'kanun'->normalize; 'teblig' KORUNUR
        if(@($hd).Count -ge 5){
          $adPrefix = "$($law.ad)"; $q = [uri]::EscapeDataString("$adPrefix*")
          # SILME FRENI (27.08): yedek yol da ayni frene tabi - ambarda bu kalipla
          # kayit VARSA (durum dosyasi ne derse desin) eski repo-JSON canliyi ezemez
          $mevcutSayi=-1
          try { $wr=Invoke-WebRequest -Uri "$SB_URL/rest/v1/dokumanlar?select=id&limit=1&tur=eq.kanun-madde&kaynak_ad=like.$q" -Headers ($H + @{ Prefer='count=exact' }) -UseBasicParsing -TimeoutSec 60; $cr="$($wr.Headers['Content-Range'])"; if($cr -match '/(\d+)$'){ $mevcutSayi=[int]$Matches[1] } } catch {}
          if($mevcutSayi -ne 0){ Write-Host ("  YEDEK-YOL FREN [{0}]: ambarda {1} kayit var (veya sayim KOR) - yedekten YAZILMADI" -f $law.ad,$mevcutSayi); continue }
          try { Invoke-RestMethod -Method Delete -Uri "$SB_URL/rest/v1/dokumanlar?tur=eq.kanun-madde&kaynak_ad=like.$q" -Headers ($H + @{ Prefer="return=minimal" }) -TimeoutSec 120 | Out-Null } catch {}
          for($i=0; $i -lt @($hd).Count; $i += 500){
            $son=[Math]::Min($i+500,@($hd).Count)-1; $dilim=@($hd)[$i..$son]
            $bj=($dilim | ConvertTo-Json -Depth 5); if(@($dilim).Count -eq 1){ $bj="[$bj]" }
            Invoke-RestMethod -Method Post -Uri "$SB_URL/rest/v1/dokumanlar" -Headers ($H + @{ Prefer="return=minimal" }) -ContentType "application/json; charset=utf-8" -Body ([Text.Encoding]::UTF8.GetBytes($bj)) -TimeoutSec 180 | Out-Null
          }
          # durum izi birak: 'yedek-json' -> her kosuda TEKRAR yuklemez; gercek indirme
          # basarili oldugu ilk gun hash uyusmaz -> kaynaktan yeniden yutulur (ayna kurali)
          $durum[$law.slug] = @{ hash='yedek-json'; son_senkron=$bugun; madde=@($hd).Count; ad=$law.ad }
          $degisen.Add($law.slug) | Out-Null
          Write-Host ("YEDEKTEN YUKLENDI (indirme yok, repo JSON): {0} -> {1} madde" -f $law.ad, @($hd).Count)
        }
      } catch { Write-Host "  yedek yukleme HATA [$($law.slug)]: $_" }
    } else {
      Write-Host "ATLA (txt yok): $($law.slug)"
    }
    continue
  }
  # 02.08 CEM KURALI: TEBLIGLER ARTIK ATLANMIYOR. Eski hal: 'G9:' onekli
  # kaynaklar (KDV GUT, VUK 509, KVK GUT, SPK II-17.1) madde yapili olmadigi
  # icin gunluk aynada HIC yutulmuyordu - yani teblig degisse bile ambar eski
  # kaliyordu ve soru-cevap araci bayat metinle cevap veriyordu. Artik madde
  # deseni tutmazsa BOLUM parcalayicisi devreye girer (asagida), metin ambara
  # tam girer. Kural: "okumadigimiz metin kalmayacak".
  # SEYREK KAYNAK (02.08): teblig arsivi (yuzlerce VUK GT) her gun indirilmez -
  # bir kez yutulur, sonra HAFTADA BIR (pazar) tazelenir. ZORLA hepsini acar.
  # Amac: kanunlarin gunluk tazeligi 185 tebligin indirme yuku yuzunden gecikmesin.
  if($law.PSObject.Properties['seyrek'] -and $law.seyrek -eq $true){
    $ilkKez = -not $durum.ContainsKey($law.slug)
    $pazar  = ((Get-Date).DayOfWeek -eq 'Sunday')
    $zorla  = ("$($env:ZORLA)" -eq "1" -or "$($env:ZORLA)" -eq "true")
    if(-not ($ilkKez -or $pazar -or $zorla)){ continue }
  }
  $raw = Get-Content $txt -Raw -Encoding UTF8
  $flat = ($raw -replace "\r?\n"," ") -replace "\s+"," "
  $yhash = Sha $flat
  $eski = if($durum.ContainsKey($law.slug)){ "$($durum[$law.slug].hash)" } else { "" }
  # ZORLA=1: hash ayni olsa bile yeniden yut. Parcalayici degistiginde (or.
  # 27.07 1800-kesigi duzeltmesi) kanun metni degismedigi icin hash de aynidir
  # ve hicbir kanun yeniden yutulmaz; bu bayrak o kapiyi acar.
  if($yhash -eq $eski -and "$($env:ZORLA)" -ne "1" -and "$($env:ZORLA)" -ne "true"){ Write-Host ("DEGISMEDI: {0}" -f $law.ad); continue }
  if($yhash -eq $eski){ Write-Host ("ZORLA: {0} (hash ayni ama yeniden yutuluyor)" -f $law.ad) }

  $url = if("$($law.pdfId)" -like 'G7:*'){ "https://www.mevzuat.gov.tr/File/GeneratePdf?mevzuatNo=$("$($law.pdfId)".Substring(3))&mevzuatTur=KurumVeKurulusYonetmeligi&mevzuatTertip=5" }
         else { "https://www.mevzuat.gov.tr/mevzuatmetin/$($law.pdfId).pdf" }
  # 01.09: kilavuz-bolum yapili kaynak (manifest isareti) ozel parcalayiciyla bolunur
  $docs = if($law.PSObject.Properties['parcalayici'] -and "$($law.parcalayici)" -eq 'kilavuz-bolum'){ ParcalaKilavuz $flat "$($law.ad)" $url } else { Parcala $flat "$($law.ad)" $url }
  # 02.08 CEM KURALI: madde deseni tutmayan metin (teblig/bolum yapili) ARTIK
  # ATLANMIYOR - bolum bolum yutuluyor. Eski hal "az madde -> atlandi" diyip
  # metni ambarin disinda birakiyordu. Indirme gercekten bozuksa metin cok
  # kisadir; o durumda (<4.000 karakter) atlama korunur.
  if($docs.Count -lt 5){
    # 07.08: esik 4000 -> 300. Oran/had tebligleri (orn. VUK GT 585, 688 kr)
    # GERCEKTEN tek paragraftir ve 4000 esigi onlari "bozuk" diye disarida
    # birakiyordu. Bozuk-indirme riski artik kaynakta cozuldu: yerel-ayna
    # %PDF imzasi dogruluyor, bot HTML'i buraya ulasamiyor.
    if($flat.Length -lt 300){ Write-Host ("UYARI cok kisa metin ({0} kr) -> {1}, atlandi (indirme bozuk)" -f $flat.Length, $law.ad); continue }
    Write-Host ("MADDE DESENI TUTMADI ({0} parca) -> {1}: BOLUM parcalayicisi devrede" -f $docs.Count, $law.ad)
    $docs = New-Object System.Collections.Generic.List[object]
    $PARCA_BOYU = 1800; $d = 0; $n = 1
    while($d -lt $flat.Length){
      $boy = [Math]::Min($PARCA_BOYU, $flat.Length - $d)
      $kes = $flat.Substring($d, $boy)
      if($d + $boy -lt $flat.Length){
        $kir = $kes.LastIndexOf('. ')
        if($kir -lt 900){ $kir = $kes.LastIndexOf(' ') }
        if($kir -ge 900){ $kes = $kes.Substring(0, $kir+1); $boy = $kir+1 }
      }
      $docs.Add([ordered]@{ tur="kanun-madde"; kaynak_ad=("$($law.ad) bolum $n"); baslik=""; metin=$kes.Trim(); kaynak_url=$url; belge_tarihi=$bugun })
      $d += $boy; $n++
    }
  }
  # KAPSAMA KAPISI (02.08): kaynak metnin yuzde kaci ambara girdi? %98 alti KIRMIZI.
  $ambarKr = ((($docs | ForEach-Object { $_.metin }) -join ' ') -replace '\s+',' ').Length
  $kapsama = if($flat.Length -gt 0){ [math]::Round(100*$ambarKr/$flat.Length,1) } else { 0 }
  if($kapsama -lt 98){ Write-Host ("  KAPSAMA UYARISI: {0} -> %{1} (mulga maddeler dusuldugunde normal olabilir)" -f $law.ad, $kapsama) }
  else { Write-Host ("  kapsama %{0}" -f $kapsama) }
  # dosyaya yaz
  $json = (@{ belgeler=$docs } | ConvertTo-Json -Depth 6)
  [IO.File]::WriteAllBytes((Join-Path $mevzuatDir "$($law.slug).json"), [Text.Encoding]::UTF8.GetBytes($json))
  $durum[$law.slug] = @{ hash=$yhash; son_senkron=$bugun; madde=$docs.Count; ad=$law.ad }  # DIKKAT: $h yazma — PS case-insensitive, $H(headers+anahtar) ile CAKISIR
  $degisen.Add($law.slug) | Out-Null
  Write-Host ("YENIDEN YUTULDU: {0} -> {1} madde (son senkron {2})" -f $law.ad, $docs.Count, $bugun)

  # Supabase: bu kanunun eski satirlarini sil + yeniden yukle (yalniz degisen kanun)
  if($H){
    $adPrefix = "$($law.ad)"
    $q = [uri]::EscapeDataString("$adPrefix*")
    # ================= SILME FRENI (27.08 KIYIM DERSI) =================
    # 27.08: robot, Supabase'e dogrudan yapilmis onarimlarin (25.08 standart
    # onarimi 6.051 parca) uzerine kendi ESKI parcalayici ciktisini basti -
    # TFRS 16 213->12. Kural: yenisi mevcttakinin %70'inden AZSA bu kaynagi
    # ATLA ve KIRMIZI raporla; kuculme mesruysa (madde ilga) insan onayiyla
    # ZORLA_KUCULT=1 ortam degiskeni gecilir. Uc durum: YESIL/KIRMIZI/KOR.
    $mevcutSayi = -1
    try {
      $wr = Invoke-WebRequest -Uri "$SB_URL/rest/v1/dokumanlar?select=id&limit=1&tur=eq.kanun-madde&kaynak_ad=like.$q" -Headers ($H + @{ Prefer='count=exact' }) -UseBasicParsing -TimeoutSec 60
      $cr = "$($wr.Headers['Content-Range'])"; if($cr -match '/(\d+)$'){ $mevcutSayi = [int]$Matches[1] }
    } catch { Write-Host "  FREN KOR: mevcut sayilamadi ($_) - guvenli taraf: SILME ATLANDI"; $durum[$law.slug].hash='FREN-KOR'; continue }
    if($mevcutSayi -lt 0){ Write-Host "  FREN KOR: sayim belirsiz - SILME ATLANDI"; $durum[$law.slug].hash='FREN-KOR'; continue }
    if($mevcutSayi -gt 20 -and $docs.Count -lt [math]::Ceiling($mevcutSayi * 0.7) -and "$($env:ZORLA_KUCULT)" -ne '1'){
      Write-Host ("  FREN KIRMIZI [{0}]: ambarda {1} kayit var, yeni yukleme {2} parca (<%70) - SILME/YAZMA ATLANDI. Mesru kuculmeyse ZORLA_KUCULT=1 ile kos." -f $law.ad,$mevcutSayi,$docs.Count)
      # damgayi FREN isaretine cek -> her kosuda yeniden dener ve BAGIRMAYA devam eder;
      # sessiz kalici sapma olusmaz (27.08 dersi: fren sustugu gun sigorta degildir)
      $durum[$law.slug].hash='FREN-KIRMIZI'
      continue
    }
    # ===================================================================
    try { Invoke-RestMethod -Method Delete -Uri "$SB_URL/rest/v1/dokumanlar?tur=eq.kanun-madde&kaynak_ad=like.$q" -Headers ($H + @{ Prefer="return=minimal" }) -TimeoutSec 120 | Out-Null } catch { Write-Host "  sil UYARI: $_" }
    for($i=0; $i -lt $docs.Count; $i += 500){
      $son=[Math]::Min($i+500,$docs.Count)-1; $dilim=$docs[$i..$son]
      $bj = ($dilim | ConvertTo-Json -Depth 5); if($dilim.Count -eq 1){ $bj="[$bj]" }
      $gonder=[Text.Encoding]::UTF8.GetBytes($bj)
      try { Invoke-RestMethod -Method Post -Uri "$SB_URL/rest/v1/dokumanlar" -Headers ($H + @{ Prefer="return=minimal" }) -ContentType "application/json; charset=utf-8" -Body $gonder -TimeoutSec 180 | Out-Null } catch { Write-Host ("  ekle HATA batch {0}: {1}" -f $i,$_) }
    }
    Write-Host ("  Supabase guncellendi: {0}" -f $law.ad)
  }
}

# durum dosyasini yaz (commit edilir)
$dj = ($durum | ConvertTo-Json -Depth 5)
[IO.File]::WriteAllBytes($durumYol, [Text.Encoding]::UTF8.GetBytes($dj))

if($degisen.Count -eq 0){ Write-Host "GUNLUK MEVZUAT: hicbir kanun degismemis - is yok." }
else { Write-Host ("GUNLUK MEVZUAT: {0} kanun yeniden yutuldu -> {1}" -f $degisen.Count, ($degisen -join ', ')) }

# ============================================================================
# ETKI ZINCIRI (23.07.2026): kanun DEGISTIYSE, o kanuna atif yapan site
# icerigi (bilgi-tabani kayitlari) "yeniden dogrula" kuyruguna dusurulur ve
# mail atilir. Icerik otomatik degistirilmez — insan teyidiyle guncellenir.
# Hata olsa bile hasadi bozmasin diye tamamen try/catch icinde.
# ============================================================================
try {
  if($degisen.Count -gt 0){
    $kbYol = Join-Path $kok "veri/bilgi-tabani.json"
    $kb = Get-Content $kbYol -Raw -Encoding UTF8 | ConvertFrom-Json
    # degisen slug -> kanun adi (manifest'ten); kaynak alaninda ad-parcasi ara
    $adlar = @{}
    foreach($l in $manifest.kanunlar){ if($degisen -contains $l.slug){ $adlar[$l.slug]=$l.ad } }
    $etkilenen = New-Object System.Collections.Generic.List[object]
    foreach($kayit in $kb.kayitlar){
      $kk = "$($kayit.kaynak)".ToLowerInvariant()
      foreach($slug in $adlar.Keys){
        $ad = $adlar[$slug].ToLowerInvariant()
        # esleme: kanun numarasi (or. 5520) veya kisaltma parcasi (parantez oncesi ilk kelime)
        $no = [regex]::Match($ad,'\d{3,4}').Value
        $kisa = ($ad -split '[\s\(]')[0]
        if(($no -and $kk -match [regex]::Escape($no)) -or ($kisa.Length -ge 3 -and $kk -match [regex]::Escape($kisa))){
          $etkilenen.Add([pscustomobject]@{ id=$kayit.id; konu=$kayit.konu; kaynak=$kayit.kaynak; kanun=$adlar[$slug]; tarih=$bugun })
          break
        }
      }
    }
    if($etkilenen.Count -gt 0){
      $kuyrukYol = Join-Path $kok "veri/yeniden-dogrula.json"
      $mev = if(Test-Path $kuyrukYol){ Get-Content $kuyrukYol -Raw -Encoding UTF8 | ConvertFrom-Json } else { [pscustomobject]@{ kayitlar=@() } }
      $lst = New-Object System.Collections.Generic.List[object]
      if($mev.kayitlar){ $lst.AddRange(@($mev.kayitlar)) }
      foreach($e in $etkilenen){ if(-not ($lst | Where-Object { $_.id -eq $e.id -and $_.kanun -eq $e.kanun })){ $lst.Add($e) } }
      $outq = [pscustomobject]@{ guncelleme=$bugun; kayitlar=$lst.ToArray() }
      [IO.File]::WriteAllText($kuyrukYol, ($outq | ConvertTo-Json -Depth 5), (New-Object Text.UTF8Encoding($false)))
      Write-Host ("ETKI ZINCIRI: {0} icerik kaydi degisen kanunlara atif yapiyor -> yeniden-dogrula kuyruguna yazildi." -f $etkilenen.Count)
      if($env:RESEND_KEY){
        $sat = ($etkilenen | Select-Object -First 20 | ForEach-Object { "<li><b>$($_.id)</b> ($($_.konu)) — atif: $($_.kaynak) — degisen: $($_.kanun)</li>" }) -join ""
        $html = "<h3>Etki Zinciri uyarisi</h3><p>Bugun degisen kanun(lar): <b>$($degisen -join ', ')</b>. Bu kanunlara atif yapan $($etkilenen.Count) icerik kaydi yeniden dogrulama kuyruguna alindi (icerik canlida, otomatik degisiklik yok).</p><ul>$sat</ul><p>Tetikte — kanun aynasi</p>"
        $duz = "Etki Zinciri uyarisi`nBugun degisen kanun(lar): $($degisen -join ', '). Bu kanunlara atif yapan $($etkilenen.Count) icerik kaydi yeniden dogrulama kuyruguna alindi (icerik canlida, otomatik degisiklik yok).`n" + (($etkilenen | Select-Object -First 20 | ForEach-Object { "- $($_.id) ($($_.konu)) — atif: $($_.kaynak) — degisen: $($_.kanun)" }) -join "`n") + "`nTetikte — kanun aynasi"
        $mb = @{ from=$env:RESEND_FROM; to=@("cemdizdar85@hotmail.com"); subject="Tetikte etki zinciri: degisen kanun $($etkilenen.Count) icerigi etkiliyor"; html=$html; text=$duz } | ConvertTo-Json -Depth 3
        try { Invoke-RestMethod -Method Post -Uri "https://api.resend.com/emails" -Headers @{ Authorization=("Bearer " + ("$env:RESEND_KEY" -replace '[^\x21-\x7E]','')) } -Body ([Text.Encoding]::UTF8.GetBytes($mb)) -ContentType "application/json" | Out-Null } catch { Write-Host "etki maili hatasi: $_" }
      }
    } else { Write-Host "ETKI ZINCIRI: degisen kanunlara atif yapan icerik yok." }
  }
} catch { Write-Host "ETKI ZINCIRI UYARI (hasat etkilenmedi): $_" }

# ============================================================================
# SORU ETKI ZINCIRI (13.08.2026 — Cem: "kanun-degisince-soru-askiya, yapalim"):
# kanun DEGISTIYSE, o kanuna dayanan YAYINDAKI sorular OTOMATIK ASKIYA alinir
# (yayin=false + yayin_notu damgasi). Soru masum kanitlanana dek yayinda kalmaz;
# okuyucu hatti yeniden dogrulayinca insan karariyla geri acilir. try/catch:
# hata olsa bile hasat bozulmaz.
# ============================================================================
try {
  if($degisen.Count -gt 0 -and $H){
    $kanunNolar = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach($l in $manifest.kanunlar){
      if($degisen -contains $l.slug){
        $no = [regex]::Match("$($l.ad)",'\b\d{3,5}\b').Value
        if(-not $no){ $no = [regex]::Match("$($l.slug)",'\d{3,5}').Value }
        if($no){ [void]$kanunNolar.Add($no) }
      }
    }
    if($kanunNolar.Count -gt 0){
      $inListe = ($kanunNolar | ForEach-Object { '"' + $_ + '"' }) -join ','
      $sr = Invoke-WebRequest -UseBasicParsing -Uri "$SB_URL/rest/v1/soru_havuzu?select=id,ders,kanun_no&yayin=eq.true&kanun_no=in.($inListe)&limit=2000" -Headers $H -TimeoutSec 120
      $askiAday = @(([Text.Encoding]::UTF8.GetString($sr.RawContentStream.ToArray()) | ConvertFrom-Json))
      if($askiAday.Count -gt 0){
        $notMetni = "ETKI-ZINCIRI ASKISI $bugun : dayandigi kanun degisti ($(($kanunNolar) -join ',')) - okuyucu yeniden dogrulayana kadar yayin disi."
        $govde = (@{ yayin=$false; yayin_notu=$notMetni } | ConvertTo-Json)
        foreach($grup in ($askiAday | Group-Object { [math]::Floor([array]::IndexOf($askiAday,$_)/100) })){
          $idIn = ($grup.Group | ForEach-Object { '"' + $_.id + '"' }) -join ','
          Invoke-RestMethod -Method Patch -Uri "$SB_URL/rest/v1/soru_havuzu?id=in.($idIn)" -Headers ($H + @{ Prefer='return=minimal' }) -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 120 | Out-Null
        }
        Write-Host ("SORU ETKI ZINCIRI: {0} yayindaki soru askiya alindi (kanun: {1})." -f $askiAday.Count, ($kanunNolar -join ', '))
        if($env:RESEND_KEY){
          $sat2 = ($askiAday | Select-Object -First 25 | ForEach-Object { "<li><b>$($_.id)</b> ($($_.ders)) — kanun $($_.kanun_no)</li>" }) -join ""
          $html2 = "<h3>Soru Etki Zinciri</h3><p>Degisen kanun(lar) <b>$($kanunNolar -join ', ')</b> nedeniyle <b>$($askiAday.Count)</b> yayindaki soru OTOMATIK ASKIYA alindi. Okuyucu hatti yeniden dogrulayinca insan karariyla acilir.</p><ul>$sat2</ul><p>Tetikte — soru sigortasi</p>"
          $duz2 = "Soru Etki Zinciri`nDegisen kanun(lar) $($kanunNolar -join ', ') nedeniyle $($askiAday.Count) yayindaki soru otomatik askiya alindi. Okuyucu hatti yeniden dogrulayinca insan karariyla acilir.`n" + (($askiAday | Select-Object -First 25 | ForEach-Object { "- $($_.id) ($($_.ders)) — kanun $($_.kanun_no)" }) -join "`n") + "`nTetikte — soru sigortasi"
          $mb2 = @{ from=$env:RESEND_FROM; to=@("cemdizdar85@hotmail.com"); subject="Tetikte soru askisi: kanun degisti, $($askiAday.Count) soru yayindan cekildi"; html=$html2; text=$duz2 } | ConvertTo-Json -Depth 3
          try { Invoke-RestMethod -Method Post -Uri "https://api.resend.com/emails" -Headers @{ Authorization=("Bearer " + ("$env:RESEND_KEY" -replace '[^\x21-\x7E]','')) } -Body ([Text.Encoding]::UTF8.GetBytes($mb2)) -ContentType "application/json" | Out-Null } catch { Write-Host "soru-aski maili hatasi: $_" }
        }
      } else { Write-Host "SORU ETKI ZINCIRI: degisen kanunlara dayanan yayinda soru yok." }
    }
  }
} catch { Write-Host "SORU ETKI ZINCIRI UYARI (hasat etkilenmedi): $_" }

# ============================================================================
# ENVANTER TETIGI (30.08.2026 — Cem: "1 yap")
#
# NEDEN VAR: ev kurali "VAR/YOK cevabi YALNIZ veri/AMBAR-ENVANTERI.md'den
# verilir" idi; ama envanteri hicbir yutucu ve hicbir workflow cagirmiyordu -
# yalniz gunluk 06:45 gorevi kosuyordu. Sonuc: her yutmadan ERTESI SABAHA
# KADAR envanter yalan soyluyordu.
#   OLCULEN VAKA (30.08, ayni gece): 10 SPK kaynagi + 584 parca ambara yazildi;
#   envanter 06:47 damgasiyla eski duruyordu. O saatte "SPK kaynagi var mi?"
#   diye sorulsa, kural geregi envanterden okunup "YOK" denecekti - ambarda
#   dururken. Cem sormasaydi kayit eksik kalacakti.
# Artik ambara YAZILDIYSA envanter ayni kosuda tazelenir; tek dogru sayfa
# gercekten tek dogru sayfa olur.
#
# DORT FREN: (1) yalniz yazma oldiysa kosar - bos kosuda ambar bastan taranmaz.
# (2) anahtar yoksa ATLAR ve bunu SOYLER (sessiz atlama kor kalmadir).
# (3) BOZUK-TAZELEME FRENI (asagida) - envanterin TAM MI / GUNCEL MI sutunlari
#     veri/butunluk-raporu.json + veri/fabrika/surum-tazeligi-karnesi.json'dan
#     gelir; ikisi de .gitignore'da, yani TEMIZ KLONDA ve CI runner'inda YOK.
#     Orada kosarsa envanter uretilir ama iki sutun komple "olculmedi" olur ve
#     depodaki IYI olcumleri EZER. Olculdu (30.08 denemesi): temiz worktree'de
#     "butunluk olculen 0 / surum olculen 0" cikti. Bu yuzden iki girdi de
#     yoksa TAZELEME YAPILMAZ - bayat envanter, yanlis envanterden iyidir.
# (4) try/catch - envanter patlasa bile YUTMA BOZULMAZ; yutma zaten bitti,
#     envanter yalnizca rapordur.
# ============================================================================
if($degisen.Count -gt 0 -and "$($env:ENVANTER_ATLA)" -ne '1'){
  $butunVar = (Test-Path (Join-Path $kok 'veri\butunluk-raporu.json')) -or (Test-Path (Join-Path $kok 'veri\butunluk-raporu-standartlar.json'))
  $surumVar = Test-Path (Join-Path $kok 'veri\fabrika\surum-tazeligi-karnesi.json')
  if(-not $SB_ANAHTAR){
    Write-Host "ENVANTER TETIGI: ATLANDI - SUPABASE_SERVICE_KEY yok, envanter ambari sayamaz. veri/AMBAR-ENVANTERI.md ESKIDIR."
  } elseif(-not ($butunVar -and $surumVar)){
    Write-Host ("ENVANTER TETIGI: ATLANDI - kapi ciktilari yok (butunluk:{0} surum:{1}). Tazelense TAM MI/GUNCEL MI sutunlari sifirlanir ve depodaki olcumler EZILIR." -f $butunVar, $surumVar)
    Write-Host "  -> veri/AMBAR-ENVANTERI.md ESKI kaldi (bilerek). Tazeleme, kapilarin ciktisi duran makinede yapilir."
  } else {
    try {
      Write-Host "ENVANTER TETIGI: ambara yazildi ($($degisen.Count) kaynak) - envanter tazeleniyor..."
      & (Join-Path $here 'ambar-envanteri.ps1')
      Write-Host "ENVANTER TETIGI: veri/AMBAR-ENVANTERI.md tazelendi."
    } catch {
      Write-Host "ENVANTER TETIGI UYARI (yutma etkilenmedi): $_"
      Write-Host "  -> veri/AMBAR-ENVANTERI.md ESKI kaldi; 'eksik var mi?' cevabi bu kosu icin GUVENILMEZ."
    }
  }
}
exit 0
