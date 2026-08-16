# ============================================================================
#  PROFESOR v2 — KATMAN 2  (28.07.2026)
#
#  NEDEN VAR: K2 denetcisi 107 itirazin 104'unde HAKSIZ cikti (%2,8 isabet).
#  Sebep tekti: K2'nin istemine maddenin ETIKETI gidiyordu ("VUK m.234"),
#  METNI degil. Yani K2 dogrulama yapmiyor, kendi hafizasindan cevap veriyordu.
#  Hafiza yanilir; metin yanilmaz. Profesor v2'nin istemine MADDENIN TAM METNI
#  gider (motor/madde-coz.ps1 ambardan getirir) ve model "yalniz bu metne
#  dayan" diye kisitlanir.
#
#  UC AYRI SORU sorulur — cunku bir soru uc ayri sekilde bozulabilir:
#    1) destek    : isaretli cevabi madde DESTEKLIYOR mu?
#    2) tek_dogru : sıklardan TAM OLARAK BIRI mi dogru? (iki dogru sik hatasi)
#    3) celiski   : aciklamalardan biri maddeyle CELISIYOR mu?
#
#  HAKEMIN HAKEMI: model her hukumde maddeden BIREBIR ALINTI vermek zorunda.
#  Alinti gercekten madde metninde geciyor mu diye MAKINEYLE bakilir. Gecmiyorsa
#  hukum COPE ATILIR ve soru GM'ye gider. Boylece profesorun uydurmasi da
#  yakalanir — Cem'in sarti: "hata olsa bile bizim yakalayacagimiz".
#
#  KURAL: metni cozulemeyen soru YARGILANMAZ, 'metin-yok' isaretlenip GM'ye
#  birakilir. Profesor asla bosluga hukum vermez.
#
#  PARA: -olcum modu HICBIR SEY HARCAMAZ, yalniz maliyet tahmini cikarir.
#  Gercek kosu Batch API ile yapilir (%50 indirim) ve ancak -calistir ile.
# ============================================================================
param(
  [switch]$olcum,        # para harcamaz: kac soru yargilanabilir + maliyet tahmini
  [switch]$calistir,     # GERCEK KOSU — para harcar
  [string]$kaynak = 'yerel',   # yerel | kasa
  [int]$sinir = 0,             # 0 = hepsi
  [string]$kurtar = '',        # ISLENMIS bir partinin sonucunu YENIDEN GONDERMEDEN cek
  [string]$idler = '',         # yalniz bu kimlikler yargilansin (JSON dizi dosyasi)
  [string]$haric = '',         # 02.08: bu dosyadaki kimlikler ATLANIR - odenmis yargi
                               # ikinci kez satin alinmasin (veri/hakem-hasadi.json)
  [string]$odak = 'genel',     # genel | ikili  (ikili = "iki dogru sik var mi" odagi)

  [string]$model = 'claude-sonnet-4-5-20250929',
  [string]$cikti = ''
)
$ErrorActionPreference = 'Stop'
# Supabase gizli anahtarli istegi KIMLIKSIZ gelirse 401 ile reddeder.
# (16.08.2026 olculdu: ayni sorgu UA'siz 401, UA'li 5 kayit. madde-coz.ps1
#  bu yuzden her kaynaga "ambarda-yok" diyordu.) IRM ve IWR AYRI yazilir.
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$PSDefaultParameterValues['Invoke-WebRequest:UserAgent'] = 'mevzuat-radar-robot/1.0'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here

# --- KENDI KAYDINI TUT. Actions loglari admin-kilitli; iki kosu ust uste dustu
# ve NEDEN dustugunu okuyamadik. Bir kanal, hatasini gosteremiyorsa kurulmus
# sayilmaz. Artik butun ciktisi dosyaya da yaziliyor ve is akisi commit'liyor.
$LOG = Join-Path $kok 'veri/profesor-log.txt'
try { Start-Transcript -Path $LOG -Force | Out-Null } catch { Write-Host "(transcript acilamadi: $($_.Exception.Message))" }

if(-not $olcum -and -not $calistir){
  Write-Host "Kullanim:"
  Write-Host "  profesor-v2.ps1 -olcum                 # PARA HARCAMAZ, maliyet cikarir"
  Write-Host "  profesor-v2.ps1 -calistir              # gercek kosu (Batch, %50 indirim)"
  exit 0
}

# --- madde cozucuyu yukle (fonksiyonlarini kullanacagiz)
. (Join-Path $here 'madde-coz.ps1') -kutuphane

$MAX_MADDE = 6000   # cok uzun maddeler kirpilir; kirpma ISARETLENIR

# ---------------------------------------------------------------- sorulari topla
function YerelSorular {
  $liste = New-Object System.Collections.Generic.List[object]
  foreach($d in @(Get-ChildItem (Join-Path $kok 'veri\fabrika') -Filter *.json -ErrorAction SilentlyContinue | Sort-Object Name)){
    try { $x = Get-Content $d.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
    if(-not $x.sorular){ continue }
    foreach($s in @($x.sorular)){ if($s){ $liste.Add($s) } }
  }
  return $liste
}
function KasaSorulari {
  $KEY = $env:SUPABASE_SERVICE_KEY
  if(-not $KEY){ Write-Host "SUPABASE_SERVICE_KEY yok - kasa okunamaz."; exit 1 }
  $H = @{ apikey=$KEY; Authorization="Bearer $KEY" }
  $u = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu"
  $liste = New-Object System.Collections.Generic.List[object]
  $bas = 0
  while($true){
    $s = Invoke-RestMethod -Uri "$u`?select=id,soru,siklar,dogru,aciklama,kaynak,ders,konu,sinav&order=id&offset=$bas&limit=500" -Headers $H -TimeoutSec 180
    $d = @($s); if($d.Count -eq 0){ break }
    foreach($x in $d){ $liste.Add($x) }
    if($d.Count -lt 500){ break }
    $bas += 500
    if($bas % 2000 -eq 0){ Write-Host ("  kasa ...{0}" -f $liste.Count) }
  }
  # SIGORTA: kolon jsonb yerine METIN ise siklar/aciklama string gelir ve
  # $s.siklar.A bos doner. O zaman istem SIKSIZ gider, profesor de dogal olarak
  # "yetersiz" der - 17 USD'lik bir kosu sessizce cope gider. Bir kez cevirip
  # gecelim; ceviremezsek KIRMIZI verip duralim.
  $bozuk = 0
  foreach($s in $liste){
    foreach($alan in @('siklar','aciklama')){
      $v = $s.$alan
      if($v -is [string] -and "$v".Trim().StartsWith('{')){
        try { $s.$alan = ($v | ConvertFrom-Json) } catch { $bozuk++ }
      }
    }
  }
  if($bozuk -gt 0){ Write-Host ("KIRMIZI: {0} kayitta siklar/aciklama cozulemedi." -f $bozuk); exit 1 }
  # ilk kaydin sikki gercekten okunuyor mu - kor kosuya karsi tek satirlik kanit
  if($liste.Count -gt 0){
    $ilk = $liste[0]
    Write-Host ("  kasa sekil kontrolu: siklar.A = '{0}'" -f "$($ilk.siklar.A)")
    if("$($ilk.siklar.A)".Trim().Length -eq 0){ Write-Host "KIRMIZI: kasadan gelen siklar okunamiyor - kosu durduruldu (bos istem gonderilmez)."; exit 1 }
  }
  return $liste
}

Write-Host ("PowerShell surumu: {0}" -f $PSVersionTable.PSVersion)
Write-Host ("Kok: {0}" -f $kok)
$sorular = if($kaynak -eq 'kasa'){ KasaSorulari } else { YerelSorular }
Write-Host ("Soru: {0} ({1})" -f $sorular.Count, $kaynak)

# --- HEDEFLI KOSU: yalniz verilen kimlikler. Tam taramayi tekrarlamak yerine
# belirli bir kusur sinifini yeniden yargilatmak icin. 3.950 soruyu yeniden
# gondermek 20 USD; 100 soruyu gondermek yarim dolar. Ayni bilgiyi 40 kat ucuza.
# 02.08 PARA SIGORTASI (Cem: "100 USD cikmasa cebimizden"): daha once yargilanmis
# sorular yeniden yargilanmaz. Kasa 25.850 soru; 3.922'sinin yargisi zaten satin
# alinmis durumda (veri/hakem-hasadi.json). Onlari cikarmak ~18 USD tasarruftur.
if($haric){
  if(-not (Test-Path $haric)){ Write-Host "UYARI: haric dosyasi yok - $haric (atlama yapilmadi)" }
  else {
    $atla = @{}
    foreach($x in @(Get-Content $haric -Raw -Encoding UTF8 | ConvertFrom-Json)){ $atla["$x"] = 1 }
    # 02.08: hakem raporlarindaki kimlikler KISA (8 hane) tutuluyor; kasadaki
    # kimlik tam UUID. Onek eslemesi olmazsa yargilanmis sorular yeniden
    # yargilanir ve para iki kez oder.
    $once = $sorular.Count
    $sorular = @($sorular | Where-Object {
      $tam = "$($_.id)"
      -not ($atla.ContainsKey($tam) -or ($tam.Length -ge 8 -and $atla.ContainsKey($tam.Substring(0,8))))
    })
    Write-Host ("HARIC: {0} yargilanmis kimlik atlandi ({1} -> {2})" -f $atla.Count, $once, $sorular.Count)
  }
}

if($idler){
  if(-not (Test-Path $idler)){ Write-Host "KIRMIZI: kimlik dosyasi yok - $idler"; try { Stop-Transcript | Out-Null } catch {}; exit 1 }
  $ist = @{}
  foreach($x in @(Get-Content $idler -Raw -Encoding UTF8 | ConvertFrom-Json)){ $ist["$x"] = 1 }
  $once = $sorular.Count
  $sorular = @($sorular | Where-Object { $ist.ContainsKey("$($_.id)") })
  Write-Host ("HEDEFLI KOSU: {0} kimlik istendi, {1} soru eslesti (havuz {2})" -f $ist.Count, $sorular.Count, $once)
  if($sorular.Count -eq 0){ Write-Host "KIRMIZI: hicbir kimlik eslesmedi - kosu durduruldu (bos parti gonderilmez)."; try { Stop-Transcript | Out-Null } catch {}; exit 1 }
}
if($sorular.Count -eq 0){
  Write-Host "KIRMIZI: hic soru okunamadi. veri/fabrika bos ya da erisilemiyor."
  try { Stop-Transcript | Out-Null } catch {}
  exit 1
}

# ---------------------------------------------------------------- istem kurucu
function IstemKur($s, $maddeMetni, $maddeEtiket){
  $sik = ""
  foreach($h in @('A','B','C','D','E')){
    $v = "$($s.siklar.$h)"
    if($v.Trim().Length -gt 0){ $sik += "$h) $v`n" }
  }
  $ack = ""
  foreach($h in @('A','B','C','D','E')){
    $v = "$($s.aciklama.$h)"
    if($v.Trim().Length -gt 0){ $ack += "$h : $v`n" }
  }
  if($ack.Trim().Length -eq 0){ $ack = "(aciklama yok)" }

  # --- ODAKLI ISTEM: "iki dogru sik" siniflandirmasi icin.
  # Genel istem uc soruyu birden sorunca model coguna "yetersiz" diyor: maddede
  # birebir yazmayan her sey "yetersiz" oluyor ve gercek kusur gurultuye gomuluyor.
  # Tam kasa taramasinda bayraklarin %88'i bu yuzden lafzi yanlis alarmdi.
  # Iki dogru sik ise METINDEN BAGIMSIZ olarak da denetlenebilir: sikin dogrulugu
  # tek tek sorulur. Bu yuzden ayri, DAR bir istem kullaniliyor.
  if($odak -eq 'ikili'){
    return @"
Asagida bir mevzuat hukmunun tam metni ve bu hukme dayanan bir coktan secmeli sinav sorusu var.

TEK BIR SEY soruyorum: siklardan KAC TANESI dogru?
Her sikki AYRI AYRI degerlendir ve "bu sik tek basina dogru bir ifade mi" diye sor.
Yalnizca yukaridaki metne ve sorunun kendi kurgusuna dayan; hafizandan hukum ekleme.

=== MEVZUAT METNI ($maddeEtiket) ===
$maddeMetni
=== METIN BITTI ===

SORU: $($s.soru)
SIKLAR:
$sik
ISARETLI DOGRU CEVAP: $($s.dogru)

ALINTI ZORUNLU: hukmune dayanak olan yeri METINDEN BIREBIR kopyala (en fazla 25 kelime). Alintin metinde birebir gecmiyorsa hukmun gecersiz sayilacak.

SADECE gecerli JSON dondur:
{"dogru_sik_sayisi":<0-5>,"dogru_siklar":"<orn: A,C>","isaretli_dogru_mu":"evet|hayir|yetersiz","gerekce":"<tek cumle>","alinti":"<metinden birebir>"}
"@
  }

  # 02.08 TEORI KAPISI: dayanak bir TEORI NOTU ise "mevzuat hukmu" demek yanlis
  # olur - model lafzi hukum ararken kavram tanimini "yetersiz" sayar. Etiket
  # 'Teori Notu' ile basliyorsa istem DILI degisir, kural ayni kalir: yalniz
  # verilen metne dayan.
  $teoriMi = ("$maddeEtiket" -match '(?i)^teori notu')
  if($teoriMi){
    return @"
Sen bir muhasebe/finans ders denetcisisin. Asagida bir DERS BILGISI NOTUNUN tam metni ve bu bilgiye dayandigi iddia edilen bir sinav sorusu var.

MUTLAK KURAL: YALNIZCA asagidaki NOTA dayanarak karar ver. Kendi hafizandan bilgi ekleme. Notta yazmayan bir seyi ne dogru ne yanlis say; not yetmiyorsa "yetersiz" de.

=== DERS NOTU ($maddeEtiket) ===
$maddeMetni
=== METIN BITTI ===

SORU: $($s.soru)
SIKLAR:
$sik
ISARETLI DOGRU CEVAP: $($s.dogru)
SIK ACIKLAMALARI:
$ack

Su uc soruyu AYRI AYRI cevapla:
1) destek: Isaretli dogru cevabi bu NOT destekliyor mu? (evet/hayir/yetersiz)
2) tek_dogru: Siklardan TAM OLARAK BIRI mi dogru? (evet/hayir/yetersiz)
3) celiski: Sik aciklamalarindan biri NOTLA celisiyor mu? (evet/hayir)

Her hukum icin NOTTAN BIREBIR ALINTI ver (alinti alani). Alinti veremiyorsan "yetersiz" de.
YALNIZ JSON dondur: {"destek":"...","alinti":"...","tek_dogru":"...","celiski":"...","gerekce":"..."}
"@
  }

  return @"
Sen bir mevzuat denetcisisin. Asagida bir mevzuat huknunun TAM METNI ve bu hukme dayandigi iddia edilen bir sinav sorusu var.

MUTLAK KURAL: YALNIZCA asagidaki METNE dayanarak karar ver. Kendi hafizandan hukum ekleme. Metinde yazmayan bir seyi ne dogru ne yanlis say; metin yetmiyorsa "yetersiz" de. Metin disinda bir kaynaga atif yapma.

KOMSU MADDE KURALI: Metnin altinda "KOMSU MADDELER" blogu olabilir. O blok
karar dayanagi DEGILDIR; tek isi sudur: isaretli cevabin asil dayanagi ANA
METINDE degil de komsu maddede duruyorsa destek=hayir de ve gerekceye
"kaynak kaymasi: m.<numara>" yaz. (Ornek vaka: soru TTK 482 etiketli ama
sorulan hukum m.483'te - boyle soru yanlis etiketlidir, onaylanamaz.)

=== MEVZUAT METNI ($maddeEtiket) ===
$maddeMetni
=== METIN BITTI ===

SORU: $($s.soru)
SIKLAR:
$sik
ISARETLI DOGRU CEVAP: $($s.dogru)
SIK ACIKLAMALARI:
$ack

Su uc soruyu AYRI AYRI cevapla:
1. destek    — Isaretli cevap ($($s.dogru)) yukaridaki metin tarafindan destekleniyor mu? (evet / hayir / yetersiz)
2. tek_dogru — Siklardan TAM OLARAK BIRI mi dogru? Birden fazla sik dogruysa "hayir". (evet / hayir / yetersiz)
3. celiski   — Sik aciklamalarindan HERHANGI BIRI metinle celisiyor mu? (evet / hayir)
   Buna TANIM/KAVRAM hatalari da dahildir: aciklama, metindeki bir kavrami
   yanlis tanimliyorsa (ornek vakalar: 4/b'liyi "kamu gorevlisi" diye tanitmak;
   "alis bedeli"ne "maliyet bedeli" demek; vakif istisnasini dernege uygulamak;
   metnin duzenledigi bir belgeye "boyle belge yok" demek) celiski=evet.
   YANLIS sik aciklamalari da bu denetime dahildir - aday onlari da okur.

ALINTI ZORUNLU: "alinti" alanina, hukmune dayanak olan yeri METINDEN BIREBIR kopyala (en fazla 25 kelime). Kendi cumleni yazma, degistirme, ozetleme. Alintin metinde birebir gecmiyorsa hukmun gecersiz sayilacak.

SADECE gecerli JSON dondur, baska hicbir sey yazma:
{"destek":"evet|hayir|yetersiz","tek_dogru":"evet|hayir|yetersiz","celiski":"evet|hayir","dogru_sik":"A|B|C|D|E|bilinmiyor","gerekce":"<tek cumle>","alinti":"<metinden birebir>"}
"@
}

# ---------------------------------------------------------------- hazirlik
$isler = New-Object System.Collections.Generic.List[object]
$ist = [ordered]@{ toplam=0; metinYok=0; mevzuatDisi=0; hazir=0 }
$sayac = 0
foreach($s in $sorular){
  $ist.toplam++
  if($sinir -gt 0 -and $isler.Count -ge $sinir){ break }
  $k = "$($s.kaynak)"
  # 02.08 TEORI KAPISI: "mevzuat disi" saydigimiz sorular ASLINDA kaynaksiz
  # degil - ambardaki teori notlarina dayaniyorlar. Once cozucuye sorulur;
  # teori notu bulunursa soru YARGILANIR (dogru metinle). Bulunmazsa eskisi
  # gibi mevzuat-disi sayilip atlanir. Konu bilgisi de gonderilir: kaynak
  # alani yanlis kanuna isaret etse bile konu dogru notu bulmaya yeter.
  $c = KaynakCoz $k "$($s.konu)"
  if(-not $c -or "$($c.durum)" -notin @('cozuldu','cozuldu-standart','cozuldu-teori','cozuldu-hesapplani')){
    if(MevzuatDisiMi $k){ $ist.mevzuatDisi++ } else { $ist.metinYok++ }
    continue
  }
  if(-not $c.metin -or "$($c.metin)".Trim().Length -lt 40){ $ist.metinYok++; continue }
  $metin = "$($c.metin)"
  $kirpildi = $false
  if($metin.Length -gt $MAX_MADDE){ $metin = $metin.Substring(0,$MAX_MADDE); $kirpildi = $true }
  # B13: duz kanun maddesinde komsu maddeleri de ekle (kaynak kaymasi avi).
  # Yalniz 'cozuldu' (kanun) durumunda ve duz seride; standart/teori/hesap
  # plani metinlerinde komsu kavrami yok.
  if("$($c.durum)" -eq 'cozuldu' -and "$($c.madde)" -match '^\d+$'){
    $komsular = KomsuMetinleri "$($c.kanun)" "$($c.madde)"
    if(@($komsular).Count -gt 0){
      $kb = "`n=== KOMSU MADDELER (karar dayanagi DEGIL - yalniz kaynak kaymasi kontrolu) ==="
      foreach($km in $komsular){ $kb += "`n[m.$($km.madde) | $($km.ad)]`n$($km.metin)`n" }
      $kb += "=== KOMSU BITTI ==="
      $metin += $kb
    }
  }
  $isler.Add([pscustomobject]@{
    id      = "$($s.id)"
    soru    = $s
    etiket  = "$($c.ad)"
    metin   = $metin
    kirpildi= $kirpildi
    istem   = (IstemKur $s $metin "$($c.etiket)")
  })
  $ist.hazir++
  $sayac++
  if($sayac % 100 -eq 0){ Write-Host ("  ...{0}" -f $sayac) }
}

Write-Host ""
Write-Host "======== PROFESOR v2 HAZIRLIK ========"
foreach($k in $ist.Keys){ Write-Host ("  {0,-14} {1}" -f $k, $ist[$k]) }

# ---------------------------------------------------------------- maliyet tahmini
$girisKr = 0; $cikisTahmin = 260   # JSON cevap ~260 token
foreach($i in $isler){ $girisKr += $i.istem.Length }
# Turkce metin icin kaba cevrim: ~3 karakter = 1 token (TAHMIN, olculmus deger degil)
$girisTok = [math]::Round($girisKr / 3)
$cikisTok = $isler.Count * $cikisTahmin

# LISTE FIYATI (1M token basina, USD) — Sonnet ailesi
$FIY_GIRIS = 3.0
$FIY_CIKIS = 15.0
$hamUSD   = ($girisTok/1e6*$FIY_GIRIS) + ($cikisTok/1e6*$FIY_CIKIS)
$batchUSD = $hamUSD / 2      # Batch API %50 indirim

Write-Host ""
Write-Host "======== MALIYET TAHMINI (TAHMINDIR, olculmus degil) ========"
Write-Host ("  yargilanacak soru : {0}" -f $isler.Count)
Write-Host ("  giris  ~{0:N0} token   (kaba cevrim: 3 karakter = 1 token)" -f $girisTok)
Write-Host ("  cikis  ~{0:N0} token   (soru basina ~{1} token varsayimi)" -f $cikisTok, $cikisTahmin)
Write-Host ("  model  : {0}" -f $model)
Write-Host ("  liste fiyati    : ~{0:N2} USD" -f $hamUSD)
Write-Host ("  BATCH (%50 ind.): ~{0:N2} USD  <-- kullanilacak yol" -f $batchUSD)
Write-Host ("  soru basina     : ~{0:N4} USD" -f $(if($isler.Count){ $batchUSD/$isler.Count } else { 0 }))

if($olcum){
  Write-Host ""
  Write-Host "OLCUM MODU — hicbir istek atilmadi, 0 USD harcandi."
  $ozet = [ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); kaynak=$kaynak; model=$model
    toplam=$ist.toplam; mevzuat_disi=$ist.mevzuatDisi; metin_yok=$ist.metinYok; yargilanabilir=$isler.Count
    tahmini_batch_usd=[math]::Round($batchUSD,2)
  }
  [IO.File]::WriteAllText((Join-Path $kok 'veri/profesor-olcum.json'), ($ozet | ConvertTo-Json -Depth 5), (New-Object Text.UTF8Encoding($false)))
  Write-Host "-> veri/profesor-olcum.json"
  exit 0
}

# ---------------------------------------------------------------- GERCEK KOSU
# 12.08: cift hat - hedef api-hedef.ps1'den (anthropic | aws)
. (Join-Path $PSScriptRoot 'api-hedef.ps1')
$HEDEF = $null
try { $HEDEF = Get-ApiHedef } catch { Write-Host $_.Exception.Message; exit 1 }
$AK = $HEDEF.anahtar
if($isler.Count -eq 0){ Write-Host "Yargilanacak soru yok."; exit 0 }

$HDR = $HEDEF.basliklar
$API_TABAN = $HEDEF.taban
Write-Host ("API hedefi: {0}" -f $HEDEF.ad)
$BATCH_MAX = 400   # tek partide en fazla

# --- HATA DEFTERI: Actions loglari admin-kilitli oldugu icin hata DOSYAYA yazilir.
# Is akisi bu dosyayi always() ile commit'ler; boylece kosu neden dustu diye
# kor kalmayiz. Depoda daha once ayni karar paket-yukle.ps1 icin alinmisti.
function HataYaz([string]$nerede, [string]$mesaj, [string]$sunucu, $ek){
  $y = Join-Path $kok 'veri/profesor-hata.json'
  $k = [ordered]@{
    zaman = (Get-Date -Format 'dd.MM.yyyy HH:mm')
    nerede = $nerede
    mesaj = $mesaj
    sunucu_cevabi = $(if($sunucu.Length -gt 1500){ $sunucu.Substring(0,1500) } else { $sunucu })
    ek = $ek
  }
  [IO.File]::WriteAllText($y, ($k | ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding($false)))
  Write-Host ("HATA [{0}]: {1}" -f $nerede, $mesaj)
  if($sunucu){ Write-Host ("SUNUCU: {0}" -f $sunucu.Substring(0,[Math]::Min(400,$sunucu.Length))) }
}

# --- SON KALKAN: yukaridaki try/catch'lerin disinda, BEKLENMEYEN bir yerde hata
# cikarsa da defter yazilsin. Iki kosu ust uste hata defteri BIRAKMADAN dustu;
# demek ki hata ongordugum yerlerde degildi. Artik nerede olursa olsun yakalanir.
trap {
  try {
    HataYaz "beklenmeyen" "$($_.Exception.Message)" "$($_.ScriptStackTrace)" @{
      satir = "$($_.InvocationInfo.ScriptLineNumber)"
      komut = "$($_.InvocationInfo.Line)".Trim()
      tur   = "$($_.Exception.GetType().FullName)"
    }
  } catch {}
  try { Stop-Transcript | Out-Null } catch {}
  exit 1
}

# --- ON KONTROL: 400 soruluk bir parti hazirlayip gondermeden ONCE anahtar ve
# model kimligi tek satirlik bir istekle sinanir. Maliyeti birkac token'dir.
# Iki kosu gonderim adiminda dustu; sebep anahtar/model ise bunu 1 saniyede ve
# neredeyse bedava ogrenmek, 1,5 USD'lik partiyi ceviren bir hatayla ogrenmekten
# iyidir. Hata mesaji da dogrudan sunucudan gelir - tahmin etmeye gerek kalmaz.
Write-Host "ON KONTROL: anahtar + model kimligi sinaniyor..."
try {
  $dene = @{ model=$model; max_tokens=1; messages=@(@{ role='user'; content='tamam' }) } | ConvertTo-Json -Depth 5
  $ok = Invoke-RestMethod -Method Post -Uri ($API_TABAN + '/v1/messages') -Headers $HDR -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($dene)) -TimeoutSec 60
  Write-Host ("  ON KONTROL TAMAM - model: {0}" -f $ok.model)
} catch {
  $cevap = ""
  try { $cevap = (New-Object IO.StreamReader($_.Exception.Response.GetResponseStream())).ReadToEnd() } catch {}
  HataYaz "on-kontrol" $_.Exception.Message $cevap @{ model=$model; not="Anahtar ya da model kimligi gecersiz. Parti GONDERILMEDI - para harcanmadi." }
  try { Stop-Transcript | Out-Null } catch {}
  exit 1
}

$sonuclar = @{}
$script:gercekGiris = 0
$script:gercekCikis = 0
$partiler = [math]::Ceiling($isler.Count / $BATCH_MAX)
for($p=0; $p -lt $partiler; $p++){
  $dilim = @($isler[($p*$BATCH_MAX)..([math]::Min(($p+1)*$BATCH_MAX-1, $isler.Count-1))])
  $req = @()
  foreach($i in $dilim){
    # 28.07 DUZELTME: custom_id eskiden SIRA NUMARASIYDI ("s0","s1"...) ve sonuc
    # okunurken Substring(1) ile geri cevriliyordu. custom_id bos gelince o satir
    # patladi ve ISLENMIS - yani PARASI ODENMIS - bir parti cope gitti.
    # Artik custom_id SORUNUN KENDI KIMLIGI. Sonuc dogrudan kimlikle eslesir;
    # sira, kirpma ya da bos alan hicbir seyi bozamaz.
    $req += @{
      custom_id = "$($i.id)"
      params = @{
        model = $model
        max_tokens = 500
        messages = @(@{ role='user'; content=$i.istem })
      }
    }
  }
  # --- KURTARMA: islenmis (parasi odenmis) bir partinin sonucunu YENIDEN
  # GONDERMEDEN cekmek icin. 3. kosuda 40 soruluk parti islendi ama ayristirici
  # patlayinca sonuc kayboldu; ayni isi ikinci kez odemek "bosa para harcamak"tir.
  if($kurtar -and $p -eq 0){
    Write-Host ("KURTARMA MODU: {0} partisinin sonucu YENIDEN GONDERILMEDEN cekiliyor (0 USD)." -f $kurtar)
    $bid = $kurtar
    $st = Invoke-RestMethod -Uri "$API_TABAN/v1/messages/batches/$bid" -Headers $HDR -TimeoutSec 60
    Write-Host ("  durum: {0}" -f $st.processing_status)
    if($st.processing_status -ne 'ended'){ Write-Host "  Parti henuz bitmemis - kurtarma yapilamaz."; try { Stop-Transcript | Out-Null } catch {}; exit 1 }
  } else {

  $govde = @{ requests = $req } | ConvertTo-Json -Depth 8
  Write-Host ("PARTI {0}/{1}: {2} soru gonderiliyor ({3:N0} KB govde)..." -f ($p+1), $partiler, $dilim.Count, ($govde.Length/1024))
  # 28.07: Actions loglari admin-kilitli. Hata ekrana yazilip kaybolursa kor kaliriz;
  # depo kuralı: HATA DOSYAYA YAZILIR, is akisi always() ile commit'ler.
  try {
    $b = Invoke-RestMethod -Method Post -Uri ($API_TABAN + '/v1/messages/batches') -Headers $HDR -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($govde))
  } catch {
    $cevap = ""
    try { $cevap = (New-Object IO.StreamReader($_.Exception.Response.GetResponseStream())).ReadToEnd() } catch {}
    HataYaz "batch-gonderim" $_.Exception.Message $cevap @{ parti=($p+1); adet=$dilim.Count; govde_kb=[math]::Round($govde.Length/1024) }
    throw
  }
  $bid = $b.id
  Write-Host ("  batch id: {0}" -f $bid)

  $tur = 0
  # HER PARTIDE SIFIRLANIR: sifirlanmazsa ilk zaman asimindan sonraki butun
  # partiler de atlanir ve parasi odenmis is cope gider.
  $zamanAsimi = $false
  while($true){
    Start-Sleep -Seconds 20
    $tur++
    $st = Invoke-RestMethod -Uri "$API_TABAN/v1/messages/batches/$bid" -Headers $HDR
    Write-Host ("  durum: {0}" -f $st.processing_status)
    if($st.processing_status -eq 'ended'){ break }
    # 29.07 IKI KUSUR BIRDEN DUZELTILDI.
    # (1) 30 DAKIKA COK KISAYDI. 4.107 soruluk denetimde besinci parti 30 dk'da
    #     bitmedi; oysa is sunucuda calismaya DEVAM ediyordu. Sinir 3 saate
    #     cikarildi - batch API'si zaten 24 saate kadar surebilir.
    # (2) ZAMAN ASIMINDAN SONRA SONUC CEKMEYE CALISIYORDU. Bitmemis partinin
    #     sonucu yoktur; 404 doner, betik olur, KOSU DUSER. Ustelik para
    #     harcanmistir: 4.107 soru icin 6 parti gonderilmis, ~18 USD odenmis
    #     ve tek satir sonuc alinamamisti.
    #     Artik zaman asiminda parti kimligi KAYDEDILIR ve o parti ATLANIR;
    #     sonra "-kurtar <id>" ile bedava hasat edilir.
    if($tur -ge 540){
      Write-Host "  ZAMAN ASIMI: parti 3 saatte bitmedi. SONUC CEKILMEYECEK."
      Write-Host ("  KURTARMA ICIN: -kurtar {0}" -f $bid)
      try {
        $bek = @()
        $byol = Join-Path $kok 'veri/bekleyen-partiler.json'
        if(Test-Path $byol){ foreach($x in (ConvertFrom-Json ([IO.File]::ReadAllText($byol)))){ $bek += "$x" } }
        if($bek -notcontains $bid){ $bek += $bid }
        [IO.File]::WriteAllText($byol, (ConvertTo-Json -InputObject ([object[]]$bek) -Depth 3), (New-Object Text.UTF8Encoding($false)))
        Write-Host "  -> veri/bekleyen-partiler.json guncellendi"
      } catch { Write-Host ("  bekleyen parti yazilamadi: {0}" -f $_.Exception.Message) }
      $zamanAsimi = $true
      break
    }
  }
  if($zamanAsimi){ continue }   # bu partiyi atla, digerlerine devam et
  }  # <- kurtarma degilse blogu biter
  # Sonuc adresini SABIT KODLAMA - durum cevabindaki results_url kullanilir.
  # Sabit adres bir yonlendirmeye takilirsa basliklar tasinmaz ve 403 alinir;
  # o hata da parayi harcadiktan SONRA cikar, en pahali yerde.
  $sonucAdres = if($st.results_url){ "$($st.results_url)" } else { "$API_TABAN/v1/messages/batches/$bid/results" }
  Write-Host ("  sonuc adresi: {0}" -f $sonucAdres)
  try {
    $cev = Invoke-WebRequest -UseBasicParsing -Uri $sonucAdres -Headers $HDR -TimeoutSec 300
    # 28.07 ASIL KUSUR BURADAYDI. PowerShell 7, icerik turunu METIN olarak
    # tanimadigi cevaplarda .Content'i BYTE DIZISI dondurur. Batch sonuclari
    # JSONL'dir ve tam da bu gruba girer. Kod onu string sanip satirlara
    # bolunce her BAYT ayri "satir" oldu: 146.618 karakterlik cevap 40.638
    # "satir" gorundu, ilk satir "123" (yani '{' karakterinin kodu) cikti,
    # custom_id her yerde bos geldi ve odenmis parti cope gitti.
    # Windows'ta (PS 5.1) ayni kod string dondurdugu icin yerelde hic gorulmezdi.
    $govdeMetin = if($cev.Content -is [byte[]]){ [Text.Encoding]::UTF8.GetString($cev.Content) } else { "$($cev.Content)" }
    $satirlar = $govdeMetin -split "`r?`n"
  } catch {
    $cevap = ""
    try { $cevap = (New-Object IO.StreamReader($_.Exception.Response.GetResponseStream())).ReadToEnd() } catch {}
    # BURASI KRITIK: parti islendi, yani PARA HARCANDI. Sonuc alinamazsa batch id
    # kaydedilir; ayni parayi ikinci kez odemeden sonuc elle cekilebilir.
    HataYaz "sonuc-cekme" $_.Exception.Message $cevap @{ batch_id=$bid; adres=$sonucAdres; UYARI="PARTI ISLENDI - PARA HARCANDI. Bu batch id ile sonuc yeniden cekilebilir, tekrar gonderilmemeli." }
    throw
  }
  # Ham cevabin basi loga yazilir: 3. kosuda custom_id BOS geldi ve ayristirici
  # patladi; ISLENMIS - yani parasi odenmis - bir parti cope gitti. Ham cevabi
  # gormeden bu tur bir seyi bir daha tahmin etmeye calismam.
  $ham = ($satirlar -join "`n")
  Write-Host ("  ham cevap: {0} satir, {1} karakter. Ilk 300: {2}" -f $satirlar.Count, $ham.Length, $(if($ham.Length -gt 300){$ham.Substring(0,300)}else{$ham}))

  $sirali = 0
  foreach($sat in $satirlar){
    if("$sat".Trim().Length -eq 0){ continue }
    try { $r = $sat | ConvertFrom-Json } catch { Write-Host ("  ATLANDI: satir JSON degil - {0}" -f $(if($sat.Length -gt 120){$sat.Substring(0,120)}else{$sat})); continue }

    # Kimlikle esleme. Eski partiler sira numarasi ("s0") kullaniyordu; kurtarma
    # kosusunda onlar da okunabilsin diye o bicim de destekleniyor. Kimlik hic
    # gelmezse SATIR SIRASINA duselim - sonucu cope atmaktan iyidir, cunku
    # bu parti ZATEN ODENDI.
    $cid = "$($r.custom_id)"
    $is = $null
    if($cid.Length -gt 0){ $is = @($dilim | Where-Object { "$($_.id)" -eq $cid })[0] }
    if(-not $is -and $cid -match '^s(\d+)$'){ $ix = [int]$Matches[1]; if($ix -lt $dilim.Count){ $is = $dilim[$ix] } }
    if(-not $is){
      # 28.07: bu yedek yol EN FAZLA dilim boyunca calisir. Kurtarma kosusunda
      # cevap bayt dizisi geldigi icin 40.638 sahte satir olustu ve yedek yol
      # 40 sorunun hepsine yanlis sonuc yapistirdi - sessiz cop uretti.
      # Artik yedek yol yalniz makul sayida kullanilir; asilirsa DURULUR.
      if($sirali -lt $dilim.Count){ $is = $dilim[$sirali]; Write-Host ("  UYARI: custom_id bos/taninmadi ('{0}') - satir sirasina gore eslendi: {1}" -f $cid, $is.id) }
      else {
        HataYaz "sonuc-ayristirma" "custom_id ile eslesmeyen satir sayisi dilim boyunu asti - cevap bicimi beklenenden farkli." "" @{ batch_id=$bid; dilim=$dilim.Count; satir=$satirlar.Count; ilk300=$(if($ham.Length -gt 300){$ham.Substring(0,300)}else{$ham}) }
        throw "Sonuc bicimi taninmadi - sessiz cop uretmektense duruluyor."
      }
    }
    $sirali++

    if("$($r.result.type)" -ne 'succeeded'){ $sonuclar[$is.id] = @{ hata="$($r.result.type)" }; continue }
    # GERCEK FATURA: tahmin degil, API'nin dondurdugu token sayisi. Rakam disiplini.
    $script:gercekGiris += [int]"$($r.result.message.usage.input_tokens)"
    $script:gercekCikis += [int]"$($r.result.message.usage.output_tokens)"
    $txt = "$($r.result.message.content[0].text)"
    $mt = [regex]::Match($txt, '\{[\s\S]*\}')
    if(-not $mt.Success){ $sonuclar[$is.id] = @{ hata='json-yok' }; continue }
    try { $j = $mt.Value | ConvertFrom-Json } catch { $sonuclar[$is.id] = @{ hata='json-bozuk' }; continue }
    $sonuclar[$is.id] = $j
  }
}

# ---------------------------------------------------------------- HAKEMIN HAKEMI
function Sadelestir([string]$t){
  $x = "$t".ToLowerInvariant()
  $x = $x -replace '[''‘’"“”]', "'"
  $x = $x -replace '[^\p{L}\p{Nd}]', ''
  return $x
}
$rapor = New-Object System.Collections.Generic.List[object]
$sy = [ordered]@{ temiz=0; bayrak=0; alintiUydurma=0; hata=0 }
foreach($i in $isler){
  $h = $sonuclar[$i.id]
  if(-not $h -or $h.hata){ $sy.hata++; continue }
  $al = Sadelestir "$($h.alinti)"
  $md = Sadelestir $i.metin
  $gecerli = ($al.Length -ge 20 -and $md.Contains($al))
  if(-not $gecerli){ $sy.alintiUydurma++ }
  if($odak -eq 'ikili'){
    # Odakli kosuda kusur tanimi DAR: tam olarak bir sik dogru olmali ve
    # isaretli cevap o sik olmali. "Madde birebir yazmiyor" burada bayrak degil.
    $adet = [int]"$($h.dogru_sik_sayisi)"
    $sorunlu = ($adet -ne 1) -or ("$($h.isaretli_dogru_mu)" -eq 'hayir')
    if($sorunlu){ $sy.bayrak++ } else { $sy.temiz++ }
    $rapor.Add([pscustomobject]@{
      id=$i.id; etiket=$i.etiket; odak='ikili'
      dogru_sik_sayisi=$adet; dogru_siklar="$($h.dogru_siklar)"
      isaretli_dogru_mu="$($h.isaretli_dogru_mu)"; isaretli="$($i.soru.dogru)"
      gerekce="$($h.gerekce)"; alinti="$($h.alinti)"
      alinti_dogrulandi=$gecerli
      hukum = $(if(-not $gecerli){ 'GECERSIZ-GM-OKUSUN' } elseif($sorunlu){ 'BAYRAK' } else { 'TEMIZ' })
    })
    continue
  }
  $sorunlu = ("$($h.destek)" -ne 'evet') -or ("$($h.tek_dogru)" -ne 'evet') -or ("$($h.celiski)" -eq 'evet')
  if($sorunlu){ $sy.bayrak++ } else { $sy.temiz++ }
  $rapor.Add([pscustomobject]@{
    id=$i.id; etiket=$i.etiket; kirpildi=$i.kirpildi
    destek="$($h.destek)"; tek_dogru="$($h.tek_dogru)"; celiski="$($h.celiski)"
    profesor_cevabi="$($h.dogru_sik)"; isaretli="$($i.soru.dogru)"
    gerekce="$($h.gerekce)"; alinti="$($h.alinti)"
    alinti_dogrulandi=$gecerli
    hukum = $(if(-not $gecerli){ 'GECERSIZ-GM-OKUSUN' } elseif($sorunlu){ 'BAYRAK' } else { 'TEMIZ' })
  })
}

Write-Host ""
Write-Host "======== PROFESOR v2 SONUC ========"
foreach($k in $sy.Keys){ Write-Host ("  {0,-16} {1}" -f $k, $sy[$k]) }
Write-Host ("  NOT: alinti dogrulanmayan {0} hukum COPE ATILDI, sorular GM'ye gidiyor." -f $sy.alintiUydurma)

# ---------------------------------------------------------------- KALIBRASYON
# Yerel kosuda sorularin bir kismini GM ELLE OKUDU ve etiketledi:
#   durum='karantina-red' -> GM BOZUK dedi   (profesor de bayrak kaldirmali)
#   durum='gm-onay'       -> GM SAGLAM dedi  (profesor temiz demeli)
# Bu iki kume profesorun ISABETINI olcer. Olcmeden tam kasaya para harcanmaz.
$kal = [ordered]@{ redToplam=0; redYakalanan=0; onayToplam=0; onayTemiz=0 }
foreach($i in $isler){
  $d = "$($i.soru.durum)"
  $r = @($rapor | Where-Object { $_.id -eq $i.id })[0]
  if(-not $r){ continue }
  if($d -eq 'karantina-red'){ $kal.redToplam++;  if($r.hukum -eq 'BAYRAK'){ $kal.redYakalanan++ } }
  if($d -eq 'gm-onay'){       $kal.onayToplam++; if($r.hukum -eq 'TEMIZ'){  $kal.onayTemiz++ } }
}
Write-Host ""
Write-Host "======== KALIBRASYON (GM etiketine karsi) ========"
Write-Host ("  GM'nin REDDETTIGI  : {0} soru -> profesor {1}'ini yakaladi" -f $kal.redToplam, $kal.redYakalanan)
Write-Host ("  GM'nin ONAYLADIGI  : {0} soru -> profesor {1}'ine temiz dedi" -f $kal.onayToplam, $kal.onayTemiz)
if($kal.onayToplam -gt 0){
  $yanlisAlarm = $kal.onayToplam - $kal.onayTemiz
  Write-Host ("  YANLIS ALARM       : {0} (GM saglam dedi, profesor bayrak kaldirdi)" -f $yanlisAlarm)
  Write-Host  "  NOT: yanlis alarm zararsizdir - o soru GM'ye geri gelir, yayina gitmez."
}

# ---------------------------------------------------------------- GERCEK FATURA
$gG = $script:gercekGiris; $gC = $script:gercekCikis
$gercekUSD = (($gG/1e6*$FIY_GIRIS) + ($gC/1e6*$FIY_CIKIS)) / 2   # Batch %50
Write-Host ""
Write-Host "======== GERCEK FATURA (API'nin dondurdugu token) ========"
Write-Host ("  giris  : {0:N0} token   (tahmin {1:N0} idi)" -f $gG, $girisTok)
Write-Host ("  cikis  : {0:N0} token   (tahmin {1:N0} idi)" -f $gC, $cikisTok)
Write-Host ("  TUTAR  : ~{0:N2} USD  (Batch %50 indirimli, liste fiyati {1}/{2} USD-M varsayimi)" -f $gercekUSD, $FIY_GIRIS, $FIY_CIKIS)

$yol = if($cikti){ $cikti } else { Join-Path $kok 'veri/profesor-v2-rapor.json' }
[IO.File]::WriteAllText($yol, ([ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); model=$model; kaynak=$kaynak
  ozet=$sy; kalibrasyon=$kal
  fatura=[ordered]@{ giris_token=$gG; cikis_token=$gC; batch_usd=[math]::Round($gercekUSD,2) }
  sonuclar=$rapor
} | ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding($false)))
Write-Host ("-> {0}" -f $yol)
try { Stop-Transcript | Out-Null } catch {}
exit 0
