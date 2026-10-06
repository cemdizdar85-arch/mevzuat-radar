# ============================================================================
#  MEVZUAT YUT (GUNLUK) — kanunu madde madde yutan, GUNCEL kalan AYNA robotu.
#  Cem: "gunluk tazeleme lazim, RG gunluk cikiyor." Ilke: hiz = kaynagin hizi.
#  AKIS: (workflow bash adimi her kanunun mevzuat.gov.tr KONSOLIDE PDF'ini
#  indirip pdftotext ile ./_txt/<slug>.txt yapar) -> bu script her kanunu
#  hash'ler; hash DEGISTIYSE (kanun guncellendi/madde iptal) O KANUNU yeniden
#  parcalar + Supabase'e yeniden yukler + belge_tarihi=BUGUN (son senkron damgasi).
#  Degismeyeni ATLAR (israf yok). EZBER DEGIL: her gun guncel kaynagin aynasi.
#  ENV: SUPABASE_SERVICE_KEY (yukleme icin; yoksa yalniz dosya uretir).
#  ENV: ZORLA=1 (hash ayni olsa bile yeniden yut) · ENV: SADECE=<slug,slug> (yalniz o kaynaklar)
#  -OzSinav: parcalayicinin kisa madde kuralini iki vakayla sinar, ambara DOKUNMAZ.
# ============================================================================
param([switch]$OzSinav)
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
. (Join-Path (Join-Path $kok 'arac') 'mevzuat-degisti.ps1')   # 23.09: MdAnahtar · MdAyirtEdici (ayırt edici belirteçler)
$durum = @{}
if(Test-Path $durumYol){ try { (Get-Content $durumYol -Raw -Encoding UTF8 | ConvertFrom-Json).PSObject.Properties | ForEach-Object { $durum[$_.Name] = $_.Value } } catch {} }

# --- madde madde parcalayici (eski "Madde N -" + modern "MADDE N-"; TR unsuz yumusamasi) ---
# 22.07.2026: taksimli madde (32/A, 32/C...) + TUM-BUYUK "EK MADDE/GECICI MADDE/MUKERRER MADDE"
# varyantlari eklendi — KVK 32/C (asgari KV) ve 7524 ek maddeleri bu desenin disinda kaliyordu.
function AralikliMaddeDuzelt([string]$duzMetin){
  # PDF metninde madde basliginin UC bozuk yazimi (16.09 olculdu, KGK tamlik olcumu):
  #  1) harf harf aralikli : "M A D D E1 2 -"  / "M ADDE 25 –"   -> MADDE 12 - / MADDE 25 –
  #  2) sayi bitisik       : "MADDE1 –" / "MADDE13 –"            -> MADDE 1 – / MADDE 13 –   (Portfoy Saklama Tebligi III-56.1: 24 maddenin 11'i bu yuzden ambarda yoktu)
  #  3) dipnot isaretli    : "MADDE 4 (2) –"                     -> MADDE 4 –                (dipnot NUMARASI metin degil; Teknik Karsiliklar Yon. m.4 ve Gumruk Yon.)
  # Normal "MADDE 12 –" yazimina dokunulmaz.
  $s = [regex]::Replace($duzMetin, '\b(?!MADDE)(?=M ?A ?D ?D ?E)M ?A ?D ?D ?E ?((?:\d ?){1,3})(?=[-–:(])', { param($es) 'MADDE ' + ($es.Groups[1].Value -replace ' ','') + ' ' })
  $s = [regex]::Replace($s, '\bMADDE(\d{1,3})(?=\s*[-–:])', { param($es) 'MADDE ' + $es.Groups[1].Value })
  $s = [regex]::Replace($s, '\b(MADDE\s+\d{1,3})\s*\(\d{1,2}\)\s*(?=[-–])', { param($es) $es.Groups[1].Value + ' ' })
  return $s
}
# Maddenin KENDISI mulga mi? (yalniz ilk 70 karakterdeki "(Mülga:" / "(Mülga madde:" serhi; ibare/fikra mulgasi degil)
# Serhte mulgadan SONRA "Yeniden duzenleme" geliyorsa madde yururluktedir (23.09, VUK m.370 vakasi - asagida).
function MaddeKendisiMulga([string]$govde){
  $m = [regex]::Match($govde, '^.{0,70}?\((Mülga\s*(?:madde)?\s*:[^)]*)\)')
  if(-not $m.Success){ return ($govde -match '^.{0,70}\(Mülga\s*(?:madde)?\s*:') }   # kapanmayan serh: eski davranis
  $serh = $m.Groups[1].Value
  $mulgalar = [regex]::Matches($serh, 'Mülga'); $yenidenler = [regex]::Matches($serh, '(?i)Yeniden\s+düzenle')
  if($yenidenler.Count -and $yenidenler[$yenidenler.Count-1].Index -gt $mulgalar[$mulgalar.Count-1].Index){ return $false }
  return $true
}
# --- 06.10.2026 BASLIK SIZMASI (Cem "1.2.3 ucunu de yap"; is emri veri/AMBAR-YUTMA-IS-EMRI-20260930.md satir 23) ---
# mevzuat.gov.tr metninde madde basligi "MADDE N" satirinin USTUNDE durur ve iki nokta ALMAZ:
#   "...diger sermaye piyasasi kurumlaridir. Kitle fonlama platformlari MADDE 35/A – (1) ..."
# Parcala bolmeyi "MADDE N"den yaptigi icin baslik (ve "IKINCI BOLUM ..." gibi bolum basliklari) ONCEKI maddenin
# sonuna yapisiyordu; sonraki kaydin baslik alani bos kaliyordu. Zarar (olculdu, 06.10): 6362 m.35'in sonunda
# "Kitle fonlama platformlari" -> smmm-w3-yspk-zor/kp-01 + 6 soru IKI DOGRU SIKLI cikti (commit 2d9d1f89).
# Olcum: madde sinirinda noktalamasiz biten 23.352 kayit, 17.291 baslik kuyrugu adayi; 100'luk orneklemin 94'u gercek
# baslik (yanlis 6: 5 'bolum N' uzunluk parcasi - bu kural onlara DOKUNMAZ -, 1 dipnot numarasi "19").
# Kural: onceki parcanin son GERCEK cumle sonundan (. ! ? … ” ) - numaralandirma "2." "c)" "fff)" ve "md." degil)
# sonra kalan KUYRUK baslik gibi gorunuyorsa sonraki kaydin BASINA tasinir, baslik alanina da yazilir. kaynak_ad DEGISMEZ.
# BU KAPI SUNU GORMEZ (bilerek birakilir, tasinmaz): ':' veya ';' ile biten cumleden sonra gelen kuyruk (liste girisi
#   "sunlardir:" ile karisir) · sondan noktalamasiz son CUMLE ("... yurutur") ile fiille biten baslik (ayni ek) ·
#   kardes numarali liste ogesiyle ayni numarali hiyerarsik baslik ("b) X" govdede varken "c) Baslik") · dipnotla
#   yapisik cumle sonu ("sayilir.15 2. Ilgililer" disinda) · KGK standartlari / SPK portali / etik kurallar (baska yutucular).
$script:TR_HARF = 'abcçdefgğhıijklmnoöprsştuüvyz'
function KuyrukBaslikMi([string]$t, [string]$onceki){
  $t = $t.Trim()
  if($t.Length -lt 3 -or $t.Length -gt 250){ return $false }
  if(@($t -split '\s+').Count -gt 25){ return $false }
  if($t -match '[;:](\s|$)'){ return $false }                                  # liste/tanim girisi baslik degildir
  $gov = $t -creplace '^(?:(?:\d{1,3}|[IVXLC]{1,6})\s*[-–.)]\s*|[a-zçğıöşü]{1,3}\)\s*|[A-ZÇĞİÖŞÜ]\)\s*)+', ''
  if($gov -cnotmatch '^[A-ZÇĞİÖŞÜ0-9]'){ return $false }                        # kucuk harfle suren cumle
  if($gov -notmatch '\p{L}{3,}'){ return $false }                               # dipnot numarasi "19"
  if($gov -match '^\d' -and $gov -cnotmatch '^\d+\s+(sayılı|[A-ZÇĞİÖŞÜ])'){ return $false }
  $son = ([regex]::Match($t, '\p{L}+(?=\P{L}*$)')).Value.ToLowerInvariant()
  if($son -match '(ı|i|u|ü)r$|(dır|dir|dur|dür|tır|tir|tur|tür|maz|mez)$' -or ($son -match '(a|e)r$' -and $son -notmatch '(lar|ler)$')){ return $false }   # fiil: "yurutur", "girer"
  # liste devami: "c) X" kuyrugundan once govdede "b) " varsa son liste ogesidir, baslik degil
  #   (numarada bicim aynen aranir: "2." icin "1." - fikra numarasi "(1)" kardes SAYILMAZ)
  $ilk = [regex]::Match($t, '^(?:(?<n>\d{1,3})(?<a>[.)])|\(?(?<h>[a-zçğıöşü]{1,3})\))')
  $kardes = ''
  if($ilk.Groups['n'].Success -and [int]$ilk.Groups['n'].Value -gt 1){ $kardes = "$([int]$ilk.Groups['n'].Value - 1)" + [regex]::Escape($ilk.Groups['a'].Value) }
  elseif($ilk.Groups['h'].Success){
    $h = $ilk.Groups['h'].Value; $x = $script:TR_HARF.IndexOf($h.Substring(0,1))
    if($x -gt 0){ $kardes = '\(?' + ([string]$script:TR_HARF[$x-1]) * $h.Length + '\)' }
  }
  if($kardes){ $arka = if($onceki.Length -gt 1500){ $onceki.Substring($onceki.Length-1500) } else { $onceki }; if($arka -cmatch "(?<![\S])$kardes\s"){ return $false } }
  return $true
}
# Govdenin sonundaki baslik kuyrugunun baslangic indeksi; yoksa -1.
function BaslikKuyruguBul([string]$g){
  $s = $g.TrimEnd()
  # (akilli tirnaklar \u ile: PS tek tirnakli dizgide U+2019/U+201D dizgiyi KAPATIR)
  if($s.Length -lt 3 -or $s -match '[.;:!?\u2026\u201D"\u2019)\]]$'){ return -1 }
  $sinir = [regex]::Matches($s, '(?<=[.!?\u2026\u201D"\u2019)\]]|\p{Ll}[.!?]\d{1,3}|\p{Ll}(?:dır|dir|dur|dür|tır|tir|tur|tür)(?=\s+\p{Lu}))\s+')   # noktasiz cumle sonu: "...mensubunundur Is Kabulu"
  for($k = $sinir.Count-1; $k -ge 0; $k--){
    $b = $sinir[$k]; $onceki = $s.Substring(0, $b.Index)
    $tok = [regex]::Match($onceki, '\S+$').Value
    if($tok -cmatch '^\(?(\d{1,3}|[a-zçğıöşü]{1,3}|[A-ZÇĞİÖŞÜ]|[IVXLC]{1,6})[.)]$'){ continue }   # numaralandirma
    if($tok -match '^(md|s|no|vb|vs|bkz|dr|av|prof|sy|rg)\.\)?$'){ continue }                        # kisaltma
    if(KuyrukBaslikMi $s.Substring($b.Index + $b.Length) $onceki){ return ($b.Index + $b.Length) }
    return -1
  }
  return -1
}
# YEDEK YOL - HAM SATIR (06.10, asil vaka bununla yakalandi): 6362 m.35 noktasiz bir LISTEYLE biter
#   ("... h) Veri depolama kuruluslari / i) ... diger sermaye piyasasi kurumlari / Kitle fonlama platformlari / MADDE 35/A-")
#   - cumle sonu yok, yukaridaki kural bir sey bulamaz. Ham metinde (pdftotext) baslik KENDI SATIRINDADIR ve MADDE satirinin
#   hemen ustundedir. Kural: MADDE satirinin ustundeki tek satir baslik bicimindeyse (KuyrukBaslikMi) ve ondan onceki satir
#   KAYDIRMA degilse (onceki satir + 1 + basligin ilk kelimesi sayfa genisligine - satir boylarinin %95'lik dilimi - sigardi)
#   o satir "baslik satiri" sayilir. Cumle kurali bos donerse govde bu satirlardan biriyle bitiyorsa o tasinir.
# BU YOL SUNU GORMEZ: birden cok satirli baslik (yalniz SON satir tasinir; "IKINCI BOLUM" satiri yerinde kalir) ·
#   sayfa genisligine yakin uzunlukta biten liste ogesinden sonraki baslik (kaydirma sanilir, tasinmaz).
function BaslikSatirlari([string]$ham){
  $kume = New-Object 'System.Collections.Generic.HashSet[string]'
  $sat = @($ham -split '\r?\n' | ForEach-Object { ($_ -replace '\s+',' ').Trim() })
  $boy = @($sat | Where-Object { $_ } | ForEach-Object { $_.Length } | Sort-Object)
  if($boy.Count -lt 20){ return ,$kume }
  $gen = [Math]::Max(60, $boy[[int][Math]::Floor($boy.Count * 0.95)])
  $maddeRx = [regex]'^(?:MÜKERRER MADDE|EK GEÇİCİ MADDE|EK MADDE|GEÇİCİ MADDE|Mükerrer Madde|Ek Geçici Madde|Ek Madde|Geçici Madde|MADDE|Madde)\s+\d+(?:/[A-ZÇĞİÖŞÜ])?\s*[-–‐-―−(]'
  for($j=1; $j -lt $sat.Count; $j++){
    if(-not $maddeRx.IsMatch($sat[$j])){ continue }
    $a = $j-1; while($a -ge 0 -and -not $sat[$a]){ $a-- }; if($a -lt 1){ continue }
    $L = $sat[$a]
    if($L.Length -gt 120 -or $L -match '[.;:!?\u2026\u201D"\u2019)\]]$'){ continue }
    $onIx = $a-1; while($onIx -ge 0 -and -not $sat[$onIx]){ $onIx-- }; if($onIx -lt 0){ continue }
    $onSatir = $sat[$onIx]
    $ilkK = ($L -split ' ')[0]
    if($onSatir -notmatch '[.;:!?\u2026\u201D"\u2019)\]]$' -and ($onSatir.Length + 1 + $ilkK.Length) -gt $gen){ continue }   # kaydirma
    if(KuyrukBaslikMi $L $onSatir){ [void]$kume.Add($L) }
  }
  return ,$kume
}
function Parcala([string]$flatMetin, [string]$kanunAd, [string]$url, $baslikSatirlari = $null){
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
  # 06.10 BASLIK SIZMASI (yukarida): once her parcanin akibeti (mulga / onceki maddeye eklenir / kendi kaydi) bilinir;
  # kuyruk YALNIZ sonraki parca kendi kaydi olacaksa tasinir (mulga ya da eklenen parcaya tasinsa metin kaybolur/yer degistirirdi).
  $govdeler = New-Object System.Collections.Generic.List[string]; $akibet = New-Object System.Collections.Generic.List[string]
  for($i=0; $i -lt $m.Count; $i++){
    $end = if($i -lt $m.Count-1){ $m[$i+1].Index } else { $flatMetin.Length }
    $gv = $flatMetin.Substring($m[$i].Index, $end-$m[$i].Index).Trim(); $govdeler.Add($gv)
    $akibet.Add($(if(MaddeKendisiMulga $gv){ 'mulga' } elseif($gv.Length -lt 60 -and -not ($gv.Length -ge 30 -and $gv.EndsWith('.'))){ 'ekle' } else { 'kayit' }))
  }
  $kuyrukBas = @{}; $gelenBaslik = @{}
  for($i=0; $i -lt $m.Count-1; $i++){
    if($akibet[$i+1] -ne 'kayit'){ continue }
    $kb = BaslikKuyruguBul $govdeler[$i]
    if($kb -le 0 -and $null -ne $baslikSatirlari -and $baslikSatirlari.Count){   # yedek yol: ham satir (BaslikSatirlari)
      $kel = @($govdeler[$i] -split ' ')
      for($w = [Math]::Min(25, $kel.Count-1); $w -ge 1; $w--){
        $aday = ($kel[($kel.Count-$w)..($kel.Count-1)]) -join ' '
        if($baslikSatirlari.Contains($aday)){ $kb = $govdeler[$i].Length - $aday.Length; break }
      }
    }
    if($kb -gt 0){ $kuyrukBas[$i] = $kb; $gelenBaslik[$i+1] = $govdeler[$i].Substring($kb).Trim() }
  }
  for($i=0; $i -lt $m.Count; $i++){
    $govde = $govdeler[$i]
    $no = $m[$i].Groups['no'].Value; $tur = $m[$i].Groups['tur'].Value; $pre = $m[$i].Groups['pre'].Value.Trim()
    # 14.08 KUSUR (olculdu, Yerli Mali Tebligi vakasi): bu kontrol "(Mülga" gordugu
    # anda maddeyi atiyordu - ama "(Mülga ibare:...)" / "(Mülga fıkra:...)" MADDENIN
    # KENDISI degil, ICINDEKI bir parca mulga demektir; madde yururlukte.
    # Somut zarar: Yerli Mali Tebligi m.4 (yerli mali kabul sartlari) ve m.8 (yerli
    # katki orani formulu) ambara HIC GIRMEDI - ikisi de "(1) Sanayi (Mülga ibare:
    # RG-15/10/2025-33048) urunlerinin..." diye basliyor. Kapsama %77,7'ye dusmustu.
    # Artik yalniz MADDENIN KENDISI mulgaysa atlanir: "(Mülga:" veya "(Mülga madde".
    # 23.09.2026 KUSUR (olculdu, VUK m.370 vakasi): "(Mülga: 30/12/1980-2365/89 md.; Yeniden duzenleme:
    #   15/7/2016-6728/22 md.)" -> madde 1980'de kaldirilmis, 2016'da YENIDEN yazilmis, bugun YURURLUKTE.
    #   Kural serhin BASINA bakip atiyordu. Zarar: 21.09 VUK yutmasi 27.08'de elle eklenen m.370'i sildi,
    #   nobetci "m.370 SILINDI" dedi, 275 soru (228 SMMM) yayindan cekildi. Tum _txt taramasi: 455 mulga
    #   serhli maddenin 15'inde "Yeniden duzenleme" var (GVK m.20/22/32/33/80/81/121, KDVK m.38, VUK m.370,
    #   Gumruk m.244, TCMB m.44, TPKK m.5, Cevre m.4/5/18) - hepsi ambara HIC girmemisti.
    #   Kural: serhteki SON islem belirler. Cevre m.4 "...Yeniden duzenleme: 2006; Mülga: 2018" -> mulga, atlanir.
    #   BU KAPI SUNU GORMEZ: "(Mülga: ...) (Ek: ...)" gibi AYRI parantezle yeniden eklenen madde (olculmedi).
    if(MaddeKendisiMulga $govde){ continue }
    # 02.08 CEM KURALI ("ustunkoru degil, en kucuk maddesine kadar"): 60
    # karakterden kisa madde ATILIYORDU. Kisa madde de maddedir (yururluk,
    # yurutme, tanim fikralari) ve soru-cevap araci onlari da arar. Artik
    # atilmaz - onceki maddeye eklenir, yani metin kaybi sifir.
    # 21.09.2026 KUSUR (olculdu, SPK Kar Payi Tebligi II-19.1 vakasi): 60 karakterden kisa
    #   madde HEP onceki maddeye ekleniyordu. Metin kaybi yok ama MADDE KAYDI yok: "Yurutme
    #   MADDE 19 - (1) Bu Teblig hukumlerini Kurul yurutur." (55 kr) ambarda ayri belge degil,
    #   m.18'in kuyrugu olarak duruyordu. KGK mevzuat tamlik olcumu (16.09) bu tebligi "EKSIK"
    #   isaretliyordu (resmi 19 madde / ambar 18) ve m.19 diye arayan hicbir sorgu bulamiyordu.
    # AYRIM (olculdu, 719 _txt dosyasi): 60 kr altinda 75 gövde var; 37'si TAM CUMLE
    #   ("...yururlukten kaldirilmistir." / "...Maliye Bakani yurutur."), 38'i KIRIK PARCA
    #   ("Yururluk: Madde 117 -", "Mukellef: Madde 41 - Yangin"). Tam cumle olan gercek maddedir,
    #   kirik parca degildir. Kural: >=30 kr VE nokta ile bitiyorsa KENDI KAYDI olur; degilse
    #   eskisi gibi onceki maddeye eklenir (metin kaybi yine sifir).
    # BU KAPI SUNU GORMEZ: noktasiz biten gercek kisa madde (ornek olculmedi) ile 30 kr altindaki
    #   gercek madde birlesik kalmaya devam eder; ayrica kirik parcanin kendisi duzeltilmez.
    # Oz-sinav: powershell -File motor/mevzuat-yut.ps1 -OzSinav  (iki vaka: II-19.1 m.19 ayrilir,
    #   "Yururluk: Madde 117 -" birlesir)
    if($akibet[$i] -eq 'ekle'){
      $ekGovde = if($kuyrukBas.ContainsKey($i)){ $govde.Substring(0, $kuyrukBas[$i]).TrimEnd() } else { $govde }
      if($docs.Count -gt 0){ $docs[$docs.Count-1].metin = "$($docs[$docs.Count-1].metin) $ekGovde" }
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
    # 06.10 BASLIK SIZMASI: parca sayisi (dolayisiyla kaynak_ad'daki [k/n]) TASIMADAN ONCEKI govdeden hesaplandi;
    # kuyruk son parcadan dusulur, gelen baslik ilk parcanin basina eklenir. Son parca yalniz kuyruktan ibaretse
    # tasima iptal edilir (bos kayit/ad degisimi olmasin).
    if($kuyrukBas.ContainsKey($i)){
      $kuyruk = $govde.Substring($kuyrukBas[$i]).Trim(); $sonP = $parcalar[$parcalar.Count-1]
      $kesik = if($sonP.EndsWith($kuyruk)){ $sonP.Substring(0, $sonP.Length - $kuyruk.Length).TrimEnd() } else { '' }
      if($kesik){ $parcalar[$parcalar.Count-1] = $kesik } else { $gelenBaslik.Remove($i+1) }
    }
    $baslikAlan = $pre
    if($gelenBaslik.ContainsKey($i)){
      $parcalar[0] = "$($gelenBaslik[$i]) $($parcalar[0])"
      if(-not $pre){ $baslikAlan = $gelenBaslik[$i] }
    }
    for($p=0; $p -lt $parcalar.Count; $p++){
      $adTam = if($parcalar.Count -eq 1){ $ad } else { "$ad [$($p+1)/$($parcalar.Count)]" }
      $docs.Add([ordered]@{ tur="kanun-madde"; kaynak_ad=$adTam; baslik=$baslikAlan; metin=$parcalar[$p]; kaynak_url=$url; belge_tarihi=$bugun })
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
  # Iki bicim var (01.09 olculdu): KVK GUT "10.5. Baslik" (noktali biter),
  # KUMI/BOBI FRS "1.1 Bu bolum..." (noktasiz, en az bir ondalik). Ikisi de
  # denenir, MONOTON kabul sayisi buyuk olan kazanir - yanlis desen dogal
  # olarak az kabul uretir (sira tutmaz).
  $rxNoktali  = [regex]'(?<=\s)(?<no>\d{1,2}(?:\.\d{1,2}){0,3})\.\s+(?=[A-ZÇĞİÖŞÜ])'
  $rxNoktasiz = [regex]'(?<=\s)(?<no>\d{1,2}(?:\.\d{1,2}){1,3})\s+(?=[A-ZÇĞİÖŞÜ])'
  function NoParcala([string]$n){ @($n -split '\.') | ForEach-Object { [int]$_ } }
  function NoKiyas($a,$b){ # a<b => -1
    $pa=NoParcala $a; $pb=NoParcala $b
    for($q=0;$q -lt [Math]::Max($pa.Count,$pb.Count);$q++){
      $x=if($q -lt $pa.Count){$pa[$q]}else{-1}; $y=if($q -lt $pb.Count){$pb[$q]}else{-1}
      if($x -ne $y){ return [Math]::Sign($x-$y) }
    }
    return 0
  }
  function MonotonKabul($adaylar){
    $kl = New-Object System.Collections.Generic.List[object]
    $onceki = '0'
    foreach($a in $adaylar){
      $no=$a.Groups['no'].Value
      if((NoKiyas $onceki $no) -lt 0){ $kl.Add(@{no=$no;idx=$a.Index}); $onceki=$no }
    }
    return ,$kl
  }
  $kabul1 = MonotonKabul ($rxNoktali.Matches($flatMetin))
  $kabul2 = MonotonKabul ($rxNoktasiz.Matches($flatMetin))
  $kabul = if($kabul2.Count -gt $kabul1.Count){ $kabul2 } else { $kabul1 }
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

# --- OZ-SINAV (21.09.2026, kapi kurma kurali 2): kisa madde kurali iki vakayla sinanir.
#     Ambara DOKUNMAZ, ag istegi YAPMAZ. Cikis 0 = gecti, 1 = kaldi.
if($OzSinav){
  $sinavlar = @(
    @{ ad='II-19.1 m.19 tam cumle -> AYRI KAYIT'
       metin='Yururluk MADDE 18 - (1) Bu Teblig 1/2/2014 tarihinde yururluge girer ve yayimi ile birlikte uygulanmaya baslar. Yurutme MADDE 19 - (1) Bu Teblig hukumlerini Kurul yurutur.'
       bekle='m.19'; olmali=$true }
    @{ ad='Kirik parca "Yururluk: Madde 117 -" -> BIRLESIK KALIR'
       metin='Madde 116 - Bu madde yururluktedir ve yeterince uzun bir govdeye sahiptir, boylece ayri kayit olur. Yururluk: Madde 117 - Madde 118 - Bu Kanun hukumlerini Cumhurbaskani yurutur ve yayimi tarihinde yururluge girer.'
       bekle='m.117'; olmali=$false }
    # 23.09 - mulga serhinin SON islemi (VUK m.370 vakasi)
    @{ ad='VUK m.370 "Mülga ...; Yeniden düzenleme" -> YURURLUKTE, AYRI KAYIT'
       metin='Madde 369 - Bu madde yururluktedir ve yeterince uzun bir govdeye sahiptir, boylece ayri kayit olur. İzaha davet: Madde 370 – (Mülga: 30/12/1980-2365/89 md.; Yeniden düzenleme: 15/7/2016-6728/22 md.) (Değişik:5/12/2019-7194/25 md.) a) Vergi incelemesine başlanılmadan önce verginin ziyaa uğradığına delalet eden emareler bulunduğunda izaha davet edilir.'
       bekle='m.370'; olmali=$true }
    @{ ad='Cevre m.4 "...Yeniden düzenleme; Mülga" -> son islem MULGA, ATLANIR'
       metin='Madde 3 - Bu madde yururluktedir ve yeterince uzun bir govdeye sahiptir, boylece ayri kayit olur. Madde 4 – (Mülga: 9/8/1991 - KHK-443/43 md.; Yeniden düzenleme: 26/4/2006-5491/4 md.; Mülga: 2/7/2018-KHK-703/82 md.) Madde 5 - Bu madde de yururluktedir ve yeterince uzun bir govdeye sahiptir, ayri kayit olur.'
       bekle='m.4'; olmali=$false }
    @{ ad='Duz mulga "(Mülga: ...)" -> ATLANIR (eski davranis korunur)'
       metin='Madde 37 - Bu madde yururluktedir ve yeterince uzun bir govdeye sahiptir, boylece ayri kayit olur. Madde 38 – (Mülga: 22/7/1998 – 4369/82 md.) Ödeme yeri: Madde 39 – Hususi kanunlarında ödeme yeri gösterilmemiş amme alacakları borçlunun ikametgahında ödenir.'
       bekle='m.38'; olmali=$false }
  )
  # 06.10 - BASLIK SIZMASI vakalari. 'kontrol': cikan belgeler uzerinde dogru olmasi gereken kosul.
  $uzun = ('kelime ' * 253).Trim() + '.'   # 1.771 kr -> govde 1.785 (<=1800), baslikla 1.830 (>1800)
  $baslikSinav = @(
    @{ ad='6362 m.35 -> m.35/A: "Kitle fonlama platformlari" m.35/A basina + baslik alanina tasinir'
       metin='MADDE 35 – (1) Sermaye piyasası kurumları; aracı kurumlar ve diğer sermaye piyasası kurumlarıdır. Kitle fonlama platformları MADDE 35/A – (1) Kitle fonlaması yoluyla para toplanmasına aracılık eden platformlar Kuruldan izin alır.'
       kontrol={ param($c) $a=@($c | Where-Object { $_.kaynak_ad -eq 'SINAV m.35' })[0]; $b=@($c | Where-Object { $_.kaynak_ad -eq 'SINAV m.35/A' })[0]
                 $a.metin.EndsWith('kurumlarıdır.') -and $b.metin.StartsWith('Kitle fonlama platformları MADDE 35/A') -and $b.baslik -eq 'Kitle fonlama platformları' } }
    @{ ad='TTK hiyerarsik baslik "c) Gemiye el konulmasi ..." tasinir'
       metin='MADDE 1365- (1) Mahkeme ihtiyati haczi uygular. (2) İhtiyati haciz gece ve resmî tatil sayılan zamanlarda da yapılır. c) Gemiye el konulması ve muhafaza tedbirleri MADDE 1366- (1) İhtiyati haczine karar verilen bütün gemiler muhafaza altına alınır.'
       kontrol={ param($c) $c[0].metin.EndsWith('yapılır.') -and $c[1].baslik -eq 'c) Gemiye el konulması ve muhafaza tedbirleri' } }
    @{ ad='Liste devami "b) ... c) Diger gelirler" baslik SAYILMAZ (kardes numara)'
       metin='MADDE 18 – (1) Birliklerin gelirleri şunlardır: a) Giriş aidatı. b) Yıllık aidat. c) Diğer gelirler MADDE 19 – (1) Birliklerin giderleri yönetmelikle belirlenir ve denetlenir.'
       kontrol={ param($c) $c[0].metin.EndsWith('c) Diğer gelirler') -and -not $c[1].baslik } }
    @{ ad='Noktasiz son cumle "... yurutur" baslik SAYILMAZ (fiil)'
       metin='MADDE 8 – (1) Bu Kanun yayımı tarihinde yürürlüğe girer ve yeterince uzun bir govdesi vardir. Bu Kanun hükümlerini Cumhurbaşkanı yürütür MADDE 9 – (1) Geçici hükümler bu maddede sayılmıştır ve uygulanır.'
       kontrol={ param($c) $c[0].metin.EndsWith('Cumhurbaşkanı yürütür') -and -not $c[1].baslik } }
    @{ ad='Iki noktali liste girisi "...sunlardir: Baskan ve Yardimci" baslik SAYILMAZ'
       metin='MADDE 5 – (1) Kurul bu Kanunla kurulmuştur ve yeterince uzun bir govdesi vardir. Kurulun üyeleri şunlardır: Başkan ve Yardımcı MADDE 6 – (1) Kurul ayda bir toplanır ve kararlarını salt çoğunlukla alır.'
       kontrol={ param($c) $c[0].metin.EndsWith('Başkan ve Yardımcı') -and -not $c[1].baslik } }
    @{ ad='Dipnot numarasi "19" baslik SAYILMAZ'
       metin='MADDE 126 – (1) Bu fıkrada yer alan ibare "Cumhurbaşkanı" şeklinde değiştirilmiştir. 19 MADDE 127 – (1) Kurul personeli sürekli görev ve hizmetleri yürütür ve yeterince uzundur.'
       kontrol={ param($c) $c[0].metin.EndsWith('19') -and -not $c[1].baslik } }
    @{ ad='Noktasiz "-dir" cumlesinden sonra gelen baslik YALNIZ baslik olarak tasinir (06.10 orneklem #5)'
       metin='MADDE 23 – (1) Meslek mensubu yanında çalışanları seçer. Çalıştırılacak kişilerde öncelik ruhsatlı meslek mensubunundur İş Kabulü MADDE 24 – (1) Meslek mensubu işi yazılı sözleşme ile kabul eder ve yürütür.'
       kontrol={ param($c) $c[0].metin.EndsWith('mensubunundur') -and $c[1].baslik -eq 'İş Kabulü' } }
    @{ ad='Ek etiketi "EK-2" baslik SAYILMAZ (3 harfli kelime yok)'
       metin='MADDE 127 – (1) Kurul personeli sürekli görev ve hizmetleri yürütür ve yeterince uzundur. EK-2 MADDE 128 – (1) Kurul bütçesi her yıl Kurul kararıyla belirlenir ve yayımlanır.'
       kontrol={ param($c) $c[0].metin.EndsWith('EK-2') -and -not $c[1].baslik } }
    @{ ad='Rakamla baslayan cumle kalintisi "2025 yili icin ek tutarlar" baslik SAYILMAZ'
       metin='MADDE 8 – (1) Tutarlar her yıl yeniden değerleme oranında artırılarak uygulanır. 2025 yılı için ek tutarlar MADDE 9 – (1) Bu Tebliğ yayımı tarihinde yürürlüğe girer ve uygulanır.'
       kontrol={ param($c) $c[0].metin.EndsWith('ek tutarlar') -and -not $c[1].baslik } }
    @{ ad='Sonraki madde MULGA -> kuyruk TASINMAZ (yerinde kalir)'
       metin='MADDE 37 – (1) Bu madde yururluktedir ve yeterince uzun bir govdeye sahiptir, ayri kayit olur. Ödeme yeri MADDE 38 – (Mülga: 22/7/1998 – 4369/82 md.) MADDE 39 – (1) Hususi kanunlarında ödeme yeri gösterilmemiş amme alacakları ödenir.'
       kontrol={ param($c) $c[0].metin.EndsWith('Ödeme yeri') -and -not $c[1].baslik } }
    @{ ad='Gelen baslik parca sayisini BOZMAZ: ~1.780 kr govde tek parca kalir, ad [1/2] almaz'
       metin=("MADDE 1 – (1) Kisa ama yeterince uzun bir ilk madde govdesi vardir ve ayri kayit olur. Uzun başlık burada yer alan bölüm hükümleri MADDE 2 – (1) $uzun")
       kontrol={ param($c) @($c | Where-Object { $_.kaynak_ad -eq 'SINAV m.2' }).Count -eq 1 -and $c[1].metin.StartsWith('Uzun başlık') } }
  )
  $gecti = 0; $kaldi = 0
  foreach($s in $sinavlar){
    $cikan = Parcala $s.metin 'SINAV' 'http://ornek'
    $var = @($cikan | Where-Object { "$($_.kaynak_ad)" -match ([regex]::Escape($s.bekle) + '(\s|$)') }).Count -gt 0
    if($var -eq $s.olmali){ $gecti++; Write-Host ("  OK    {0}" -f $s.ad) }
    else { $kaldi++; Write-Host ("  KALDI {0} (beklenen: {1}, cikan: {2})" -f $s.ad,$s.olmali,$var) -ForegroundColor Red }
  }
  # Yedek yol (ham satir): 6362 m.35'in gercek satir dizilisi. Dolgu satirlari sayfa genisligini (~90) kurar.
  $dolgu = @(1..24 | ForEach-Object { "Dolgu cümlesi $_ sayfa genişliğini kurmak için yeterince uzun yazılmış bir satırdır ve devam" })
  $hamListe = (@('MADDE 34 – (1) Bu madde yeterince uzun bir govdeye sahiptir ve ayri kayit olur.') + $dolgu + @(
    'gider.', 'MADDE 35 – (1) Sermaye piyasası kurumları aşağıda gösterilmiştir:', 'h) Veri depolama kuruluşları',
    'ı) Kuruluş ve faaliyet esasları Kurulca belirlenen diğer sermaye piyasası kurumları', 'Kitle fonlama platformları',
    'MADDE 35/A- (Ek: 28/11/2017-7061/110 md.) (1) Kitle fonlama platformları Kuruldan izin alır.')) -join "`n"
  $hamKaydirma = (@('MADDE 34 – (1) Bu madde yeterince uzun bir govdeye sahiptir ve ayri kayit olur.') + $dolgu + @(
    'gider.', 'MADDE 35 – (1) Sermaye piyasası kurumları aşağıda gösterilmiştir: h) Veri depolama kuruluşları ve faaliyet esasları',
    'Kurulca belirlenen diğer kurumlar', 'MADDE 36 – (1) Kurul bu maddedeki kurumların faaliyet esaslarını belirler ve izler.')) -join "`n"
  $baslikSinav += @(
    @{ ad='YEDEK YOL: noktasiz liste + kendi satirindaki baslik (6362 m.35 -> 35/A) tasinir'; ham=$hamListe
       kontrol={ param($c) $a=@($c | Where-Object { $_.kaynak_ad -eq 'SINAV m.35' })[0]; $b=@($c | Where-Object { $_.kaynak_ad -eq 'SINAV m.35/A' })[0]
                 $a.metin.EndsWith('kurumları') -and $b.baslik -eq 'Kitle fonlama platformları' } }
    @{ ad='YEDEK YOL: sayfa genisliginde onceki satir = KAYDIRMA, devam satiri baslik SAYILMAZ'; ham=$hamKaydirma
       kontrol={ param($c) $a=@($c | Where-Object { $_.kaynak_ad -eq 'SINAV m.35' })[0]; $a.metin.EndsWith('Kurulca belirlenen diğer kurumlar') } }
  )
  foreach($s in $baslikSinav){
    $cikan = if($s.ham){ $fl = ($s.ham -replace "\r?\n"," ") -replace "\s+"," "; @(Parcala $fl 'SINAV' 'http://ornek' (BaslikSatirlari $s.ham)) } else { @(Parcala $s.metin 'SINAV' 'http://ornek') }
    $ok = $false; try { $ok = [bool](& $s.kontrol $cikan) } catch {}
    if($ok){ $gecti++; Write-Host ("  OK    {0}" -f $s.ad) }
    else { $kaldi++; Write-Host ("  KALDI {0}" -f $s.ad) -ForegroundColor Red; $cikan | ForEach-Object { Write-Host ("        [{0}] baslik=[{1}] {2}" -f $_.kaynak_ad,$_.baslik,$_.metin.Substring([Math]::Max(0,$_.metin.Length-70))) } }
  }
  Write-Host ("OZ-SINAV: gecti {0} - kaldi {1}" -f $gecti,$kaldi)
  exit $(if($kaldi){ 1 } else { 0 })
}

$SB_ANAHTAR = $env:SUPABASE_SERVICE_KEY
# 07.08: sb_secret anahtar robot User-Agent ister ("Forbidden use of secret API
# key in browser") - UA'siz IRM tarayici sayilip TUM ekleri reddediyordu.
$H = if($SB_ANAHTAR){ @{ apikey=$SB_ANAHTAR; Authorization="Bearer $SB_ANAHTAR"; 'User-Agent'='mevzuat-radar-robot/1.0' } } else { $null }
$degisen = New-Object System.Collections.Generic.List[string]
# 06.10: METNI degisen kaynaklar (hash farkli ya da yedek yol). ZORLA ile yalniz yeniden BOLUNEN (hash ayni) kaynak
# ambara yazilir ama etki zincirlerine (bilgi tabani kuyrugu + mail, soru askisi) GIRMEZ - hukum degismedi.
$metinDegisen = New-Object System.Collections.Generic.List[string]

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
          try { $wr=Invoke-WebRequest -Uri "$SB_URL/rest/v1/dokumanlar?select=id&limit=3&order=id.asc&tur=eq.kanun-madde&kaynak_ad=like.$q" -Headers ($H + @{ Prefer='count=exact' }) -UseBasicParsing -TimeoutSec 60; $cr="$($wr.Headers['Content-Range'])"; if($cr -match '/(\d+)$'){ $mevcutSayi=[int]$Matches[1] } } catch {}
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
          $degisen.Add($law.slug) | Out-Null; $metinDegisen.Add($law.slug) | Out-Null
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
  # 15.09.2026 KUSUR (olculdu, KGK Devlet Katkisi Yon.): bazi PDF'lerde madde basligi harf harf aralikli
  # cikiyor ("M A D D E1 2 -"); Parcala onu madde basi saymiyor, m.12 m.11'in icine yapisiyordu. Tum _txt
  # taramasi: 4 kaynak / 6 madde (bddk-kredi-islemleri m.13/17/20, bes-devlet-katkisi m.12, tahsilatgt11 m.1,
  # vukgt545 m.12). Hash DUZELTMEDEN ONCE alinir -> baska kaynak yeniden yutulmaz; etkilenenler ZORLA ile.
  $flat = AralikliMaddeDuzelt $flat

  $url = if("$($law.pdfId)" -like 'G7:*'){ "https://www.mevzuat.gov.tr/File/GeneratePdf?mevzuatNo=$("$($law.pdfId)".Substring(3))&mevzuatTur=KurumVeKurulusYonetmeligi&mevzuatTertip=5" }
         else { "https://www.mevzuat.gov.tr/mevzuatmetin/$($law.pdfId).pdf" }
  # 01.09: kilavuz-bolum yapili kaynak (manifest isareti) ozel parcalayiciyla bolunur
  $docs = if($law.PSObject.Properties['parcalayici'] -and "$($law.parcalayici)" -eq 'kilavuz-bolum'){ ParcalaKilavuz $flat "$($law.ad)" $url } else { Parcala $flat "$($law.ad)" $url (BaslikSatirlari $raw) }
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
  # 23.09.2026 AYIRT EDİCİ BELİRTEÇLER (arac/mevzuat-degisti.ps1 MdAyirtEdici): ayna üzerine yazılmadan ÖNCE eski/yeni
  # madde metinleri karşılaştırılır; değişen her madde için farkın belirteçleri veri/mevzuat/_degisen-kokler.json'a yazılır.
  # Soru-dayanak nöbetçisi bu belirteçlerden hiçbirine değmeyen soruyu çekmez (TTK geç. m.7: 93 sorudan 91'i değmiyordu).
  # Belirteç bulunamazsa 'belirsiz' yazılır → nöbetçi hepsini çeker. Hata olursa yutma DURMAZ (dosya yazılmaz = eski davranış).
  try {
    $eskiAyna = Join-Path $mevzuatDir "$($law.slug).json"
    if(Test-Path $eskiAyna){
      $eskiM=@{}; foreach($d in @((Get-Content $eskiAyna -Raw -Encoding UTF8 | ConvertFrom-Json).belgeler)){ $a=MdAnahtar "$($d.kaynak_ad)"; if($a){ $eskiM[$a]="$($eskiM[$a]) $($d.metin)" } }
      $yeniM=@{}; foreach($d in $docs){ $a=MdAnahtar "$($d.kaynak_ad)"; if($a){ $yeniM[$a]="$($yeniM[$a]) $($d.metin)" } }
      $dkY = Join-Path $mevzuatDir '_degisen-kokler.json'
      $dk=[ordered]@{}; if(Test-Path $dkY){ foreach($p in (Get-Content $dkY -Raw -Encoding UTF8 | ConvertFrom-Json).maddeler.PSObject.Properties){ $dk[$p.Name]=$p.Value } }
      $yeniKayit=0
      foreach($a in $eskiM.Keys){
        if(-not $yeniM.ContainsKey($a)){ continue }
        $af = MdAyirtEdici $eskiM[$a] $yeniM[$a]
        if($null -ne $af -and @($af).Count -eq 0){ continue }   # metin aynı
        # 06.10 YENIDEN BOLME: kanun metninin hash'i AYNI (ZORLA kosusu) ise fark yalniz parcalayicidan gelir (baslik
        # tasima, sinir kaymasi); hukum degismedi. Belirtecsiz + belirsiz=false yazilir -> nobetci bu maddeye dayanan soruyu
        # CEKMEZ (MdSoruDegiyor bos liste). Yazilmasaydi nobetci HEPSINI cekerdi: 06.10 provasi, baslik tasima tek basina
        # 8.886 yayindaki sorunun 2.146'sini cekecekti (688'i "belirsiz"). Hash farkliysa (gercek degisiklik) eski yol aynen.
        $saltBolme = (($yhash -eq $eski) -and -not ($dk.Contains($a) -and $dk[$a]))   # bekleyen gercek degisiklik varsa o korunur
        if($yhash -eq $eski){ $bel=$false; $belirtecDizi=@() } else { $bel=($null -eq $af); $belirtecDizi=@($af) }
        # aynı maddede önceki (henüz nöbetçinin işlemediği olabilecek) değişiklik: belirteçler BİRLEŞİR, biri belirsizse belirsiz
        if($dk.Contains($a) -and $dk[$a]){ if($dk[$a].belirsiz){ $bel=$true }; $belirtecDizi=@(@($belirtecDizi) + @($dk[$a].belirtecler) | Where-Object { $_ } | Select-Object -Unique) }
        $dk[$a] = [ordered]@{ tarih=(Get-Date -Format 'yyyy-MM-dd HH:mm'); kaynak=$law.slug; belirsiz=$bel; belirtecler=$belirtecDizi; yeniden_bolme=$saltBolme }
        $yeniKayit++
      }
      if($yeniKayit){ [IO.File]::WriteAllText($dkY, (ConvertTo-Json -InputObject ([ordered]@{ aciklama='Madde metni değişince eski/yeni ayırt edici belirteçler (motor/mevzuat-yut.ps1). Nöbetçi, soru bu belirteçlerden hiçbirine değmiyorsa çekmez; belirsiz=true ise hepsini çeker.'; maddeler=$dk }) -Depth 5), (New-Object Text.UTF8Encoding($false))); Write-Host ("  ayırt edici belirteç: {0} madde" -f $yeniKayit) }
    }
  } catch { Write-Host "  ⚠ ayırt edici belirteç hesaplanamadı (nöbetçi temkinli çalışır): $($_.Exception.Message)" }
  # dosyaya yaz
  $json = (@{ belgeler=$docs } | ConvertTo-Json -Depth 6)
  [IO.File]::WriteAllBytes((Join-Path $mevzuatDir "$($law.slug).json"), [Text.Encoding]::UTF8.GetBytes($json))
  $durum[$law.slug] = @{ hash=$yhash; son_senkron=$bugun; madde=$docs.Count; ad=$law.ad }  # DIKKAT: $h yazma — PS case-insensitive, $H(headers+anahtar) ile CAKISIR
  $degisen.Add($law.slug) | Out-Null; if($yhash -ne $eski){ $metinDegisen.Add($law.slug) | Out-Null }
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
      $wr = Invoke-WebRequest -Uri "$SB_URL/rest/v1/dokumanlar?select=id&limit=3&order=id.asc&tur=eq.kanun-madde&kaynak_ad=like.$q" -Headers ($H + @{ Prefer='count=exact' }) -UseBasicParsing -TimeoutSec 60
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
else { Write-Host ("GUNLUK MEVZUAT: {0} kanun yeniden yutuldu -> {1}" -f $degisen.Count, ($degisen -join ', ')) }; if($degisen.Count -gt $metinDegisen.Count){ Write-Host ("  bunlarin {0} tanesi YALNIZ YENIDEN BOLUNDU (metin hash ayni) -> etki zincirlerine girmedi" -f ($degisen.Count - $metinDegisen.Count)) }

# ============================================================================
# ETKI ZINCIRI (23.07.2026): kanun DEGISTIYSE, o kanuna atif yapan site
# icerigi (bilgi-tabani kayitlari) "yeniden dogrula" kuyruguna dusurulur ve
# mail atilir. Icerik otomatik degistirilmez — insan teyidiyle guncellenir.
# Hata olsa bile hasadi bozmasin diye tamamen try/catch icinde.
# ============================================================================
try {
  if($metinDegisen.Count -gt 0){
    $kbYol = Join-Path $kok "veri/bilgi-tabani.json"
    $kb = Get-Content $kbYol -Raw -Encoding UTF8 | ConvertFrom-Json
    # degisen slug -> kanun adi (manifest'ten); kaynak alaninda ad-parcasi ara
    $adlar = @{}
    foreach($l in $manifest.kanunlar){ if($metinDegisen -contains $l.slug){ $adlar[$l.slug]=$l.ad } }
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
        $html = "<h3>Etki Zinciri uyarisi</h3><p>Bugun degisen kanun(lar): <b>$($metinDegisen -join ', ')</b>. Bu kanunlara atif yapan $($etkilenen.Count) icerik kaydi yeniden dogrulama kuyruguna alindi (icerik canlida, otomatik degisiklik yok).</p><ul>$sat</ul><p>Tetikte — kanun aynasi</p>"
        $duz = "Etki Zinciri uyarisi`nBugun degisen kanun(lar): $($metinDegisen -join ', '). Bu kanunlara atif yapan $($etkilenen.Count) icerik kaydi yeniden dogrulama kuyruguna alindi (icerik canlida, otomatik degisiklik yok).`n" + (($etkilenen | Select-Object -First 20 | ForEach-Object { "- $($_.id) ($($_.konu)) — atif: $($_.kaynak) — degisen: $($_.kanun)" }) -join "`n") + "`nTetikte — kanun aynasi"
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
  if($metinDegisen.Count -gt 0 -and $H){
    $kanunNolar = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach($l in $manifest.kanunlar){
      if($metinDegisen -contains $l.slug){
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
