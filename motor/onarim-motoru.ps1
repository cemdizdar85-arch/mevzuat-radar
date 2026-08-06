# ============================================================================
#  ONARIM MOTORU (02.08.2026) — SINAV-KURALLARI D1/D2/D7/D8 tamamlayicisi
#  Sartname: ONARIM-MOTOR-SARTNAMESI.md (bu gecenin TUM kararlari orada)
#
#  CEM'IN KURALI: "parali islemi bir kez calistirip birakalim" + "tekrar tekrar
#  yapmayalim". Bu yuzden motor bir soruyu ACAR ve EKSIK OLAN NE VARSA HEPSINI
#  AYNI CAGRIDA uretir. Bir soruya BIR KEZ dokunulur.
#
#  UC MOD:
#   (varsayilan) KURU  : 0 USD. Kimin neyi eksik oldugunu sayar, ORNEK ISTEMLERI
#                        dosyaya yazar. Hicbir API cagrisi YOK. Gozle kontrol icin.
#   -uygula -sinir N   : PARALI pilot. N soru islenir, GERCEK FATURA olculur.
#   -uygula            : PARALI tam parti (Cem'in acik "bas"i olmadan kosulmaz).
#
#  KIRMIZI CIZGILER (sartname 3):
#   - Dayanak metni COZULEMEYEN soru ATLANIR, uydurulmaz (D4).
#   - Zaten TAM olan madde uretilmez (hem para hem kalite kaybi).
#   - Yazma PATCH ile (kismi upsert NOT NULL duvarina carpar - 27.07 dersi).
#   - Yazilan her soru GERI OKUNUR; dogrulanmayan "yapildi" sayilmaz.
#   - Her kosu rapor yazar (kor kalma): islenen/yazilan/dogrulanan/atlanan+sebep.
#
#  ENV: SUPABASE_SERVICE_KEY (+ -uygula icin ANTHROPIC_API_KEY)
#  Cikti: veri/onarim-motor-raporu.json · veri/onarim-motor-ornek-istem.txt
# ============================================================================
param(
  [switch]$uygula,
  [int]$sinir = 0,
  [string]$model = 'claude-haiku-4-5-20251001'
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent'] = 'mevzuat-radar-robot/1.0'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
$raporYol = Join-Path $kok 'veri/onarim-motor-raporu.json'
$ornekYol = Join-Path $kok 'veri/onarim-motor-ornek-istem.txt'

trap {
  $g = ""; if($_.ErrorDetails -and $_.ErrorDetails.Message){ $g = $_.ErrorDetails.Message }
  Set-Content -LiteralPath $raporYol -Encoding UTF8 -NoNewline -Value (ConvertTo-Json -Depth 4 -InputObject ([ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'
    hata="$($_.Exception.Message)"; sunucu=$g; satir=$_.InvocationInfo.ScriptLineNumber }))
  Write-Host ("HATA (satir {0}): {1} | {2}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message, $g)
  exit 1
}
if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host "SUPABASE_SERVICE_KEY yok - cikildi."; exit 0 }
$U  = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu"
$DK = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar"
$SB = @{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization="Bearer $($env:SUPABASE_SERVICE_KEY)" }

# Ham JSON ile cek: IRM diziyi bozup tek nesne verebiliyor (bu gece 2 kez yandik)
# ============================================================================
#  RAPOR SIZINTI SIGORTASI — 03.08 sabahi kondu, sebebi acikca sudur:
#
#  $etiketAdi'nin eski adi $PARTI idi; 200 soruluk dizinin adi da $parti.
#  PowerShell degisken adlarinda BUYUK/KUCUK HARF AYIRMAZ - ikisi ayni degisken
#  cikti, dizi adin uzerine yazdi ve raporun "parti" alanina 200 PARALI SORUNUN
#  TAM METNI dokuldu. Rapor public depoya commit edilir; sizinti oradan gitti.
#
#  Ad cakismasi duzeltildi ama bu YETMEZ: baska bir yanlisla ayni sey tekrar
#  olabilir. Bu yuzden rapor artik TEK KAPIDAN yazilir ve o kapi olcer:
#  rapor 20 KB'i asiyorsa icinde olmamasi gereken bir sey vardir - icerik
#  yazilmaz, yerine KIRMIZI uyari yazilir. Kucuk ve sayisal kalmak zorunda.
# ============================================================================
function RaporYaz($nesne){
  $j = ConvertTo-Json -InputObject $nesne -Depth 6
  if($j.Length -gt 20480){
    Write-Host ("!! RAPOR SISMIS ({0} bayt) - icerik sizmis olabilir, YAZILMADI." -f $j.Length)
    $j = ConvertTo-Json -Depth 3 -InputObject ([ordered]@{
      tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='KIRMIZI - RAPOR SISMIS'
      boyut_bayt=$j.Length
      sebep='Rapor 20 KB siniri asti. Raporda yalniz SAYI olur; bu buyukluk soru metni sizdigi anlamina gelir.'
      yapilacak='Rapor uretimindeki alan adlarini denetle (PS degisken adlari buyuk/kucuk harf ayirmaz).' })
  }
  Set-Content -LiteralPath $raporYol -Value $j -Encoding UTF8 -NoNewline
}

function CekListe([string]$uri){
  $h = Invoke-WebRequest -Uri $uri -Headers $SB -UseBasicParsing -TimeoutSec 180
  $m = if($h.RawContentStream){ [Text.Encoding]::UTF8.GetString($h.RawContentStream.ToArray()) } else { "$($h.Content)" }
  return @($m | ConvertFrom-Json)
}

# --- kasa ---
$kasa = New-Object System.Collections.Generic.List[object]
for($o=0; $o -lt 60000; $o+=1000){
  $r = CekListe "$U`?select=id,ders,konu,soru,siklar,dogru,aciklama,tablo,yevmiye,kaynak&order=id&limit=1000&offset=$o"
  if($r.Count -eq 0){ break }
  foreach($x in $r){ if($null -ne $x){ $kasa.Add($x) } }
  if($r.Count -lt 1000){ break }
}
Write-Host ("Kasa: {0} soru" -f $kasa.Count)
if($kasa.Count -lt 1000){ Write-Host "!! SUPHELI: kasa beklenenden kucuk - sayfalama kirik olabilir." }

# --- sozlesme denetleyicileri (aciklama-sozlesme-olcum.ps1 ile AYNI desenler) ---
$reNe=[regex]'(?i)ne\s+sorul'; $reKural=[regex]'(?i)(^|\n|\*|\||>)\s*kural\s*:'
$reOlay=[regex]'(?i)bu\s+olayda'; $reAkil=[regex]'(?i)ak[ıi]lda\s+kals[ıi]n'
$reTuzak=[regex]'(?i)tuzak\s*:|kar[ıi][sş]t[ıi]r'; $reDogrusu=[regex]'(?i)do[ğg]rusu\s*:'
$reHesapli=[regex]'(?i)ka[çc]\s*TL|ne\s+kadar|hesapla|tutar[ıi]n[ıi]|maliyet bedeli|amortisman|toplam[ıi]'
$reKayit=[regex]'(?i)yevmiye|kay[ıi]t|kaydeder|muhasebele[şs]tir|bor[çc]land|alacakland'
$reKarsi=[regex]'(?i)hangisi\s+do[ğg]rudur|a[şs]a[ğg][ıi]dakilerden\s+hangisi'
function Dolu($v){ if($null -eq $v){ return $false }; $s="$v"; if($s.Trim().Length -lt 5){ return $false }; return ($s -ne '{}' -and $s -ne '[]' -and $s -ne 'null') }

# --- her soru icin EKSIK LISTESI cikar ---
$isler = New-Object System.Collections.Generic.List[object]
foreach($s in $kasa){
  $a = $s.aciklama; if($null -eq $a){ continue }
  $dh = "$($s.dogru)".Trim().ToUpper()
  $dm = ""; try { if($a.PSObject.Properties[$dh]){ $dm = "$($a.$dh)" } } catch {}
  $eksik = @()
  $p = 0
  if($reNe.IsMatch($dm)){$p++}; if($reKural.IsMatch($dm)){$p++}
  if($reOlay.IsMatch($dm)){$p++}; if($reAkil.IsMatch($dm)){$p++}
  if($p -lt 4){ $eksik += 'D1_dort_parca' }
  $tz=0; $dg=0
  foreach($h in 'A','B','C','D','E'){
    if($h -eq $dh){ continue }
    $m=""; try { if($a.PSObject.Properties[$h]){ $m="$($a.$h)" } } catch {}
    if($m.Length -lt 5){ continue }
    if($reTuzak.IsMatch($m)){$tz++}; if($reDogrusu.IsMatch($m)){$dg++}
  }
  if($tz -lt 3){ $eksik += 'D2_tuzak' }
  if($dg -lt 3){ $eksik += 'D2_dogrusu' }
  $gv = "$($s.soru)"
  if($reHesapli.IsMatch($gv) -and -not (Dolu $s.tablo)){ $eksik += 'D7_tablo' }
  if($reKayit.IsMatch($gv)   -and -not (Dolu $s.yevmiye)){ $eksik += 'D7_yevmiye' }
  if($reKarsi.IsMatch($gv) -and -not $reHesapli.IsMatch($gv) -and -not (Dolu $s.tablo)){ $eksik += 'D8_karsilastirma' }
  # ==========================================================================
  #  D9 - KEHRIBAR KART (hap) ARTIK MOTORUN KAPSAMINDA (04.08, Cem'in karari)
  #
  #  Cem: "bunu sadece bu soruya degil tum sorulara uygulayalim" (puf noktasi
  #  kurali) + "kehribar karti ekle". Motor bugune kadar 'hap' alanini HIC
  #  uretmiyordu; yani puf noktasi kurali isteme yazilsa bile mevcut kartlara
  #  ULASAMIYORDU - bu, kapsam boslugunun ta kendisiydi.
  #
  #  SIMDILIK DAR: yalnizca kart YOK ya da cok kisaysa uretilir (acik kusur).
  #  Dolu ve makul kartlara D11 geregi dokunulmuyor. Cem "mevcut kartlara da
  #  puf noktasi girsin" derse burasi genisletilir - o zaman maliyet artar,
  #  once olculur.
  # ==========================================================================
  if("$($s.hap)".Trim().Length -lt 15){ $eksik += 'D9_hap' }
  if($eksik.Count -eq 0){ continue }
  # 04.08 - EKSIK HARF KAPISI icin: bu sorunun YANLIS sik harfleri (dogru sik
  # haric, bos olmayanlar). Hem isteme yazilir hem uretilen cikti buna karsi
  # denetlenir. (Cem'in "sadece 2 adet geldi" bulgusu.)
  $dgH = "$($s.dogru)".Trim().ToUpper()
  $yh = @()
  foreach($h in 'A','B','C','D','E'){
    if($s.siklar -and $s.siklar.PSObject.Properties[$h] -and "$($s.siklar.$h)".Trim() -ne '' -and $h -ne $dgH){ $yh += $h }
  }
  $isler.Add([pscustomobject]@{ soru=$s; eksik=$eksik; yanlisHarfler=$yh })
}
Write-Host ("Eksigi olan soru: {0}" -f $isler.Count)

# --- DAYANAK KAPISI (D4): kaynak metni ambarda yoksa soru ATLANIR ---
# Uydurma kanun/oran yasak; "Dogrusu" yalniz dayanak metninden turetilir.
#
# 02.08 GECE - IKI KUSUR DUZELTILDI (kuru kosu 8.098 soruyu haksiz atlamisti):
#
# KUSUR 1 - MEVZUAT DISI DERSLER. Kuru kosunun atlananlari arasinda "Prepositions
# of Time (in/on/at)", "Unless sart baglaci", "lend-borrow ayrimi", "TDK cumle
# ogeleri" vardi. Yabanci Dil / Turkce / Matematik sorularinin mevzuat dayanagi
# YOKTUR - olamaz da. Bunlar artik dayanak aranmadan gecer; istem karsiliginda
# "bu bir dil/beceri sorusu, HICBIR kanun/madde/oran atfi yapamazsin" der.
# Boylece uydurma riski kapali kalir ama soru cope gitmez.
#
# KUSUR 2 - ETIKETIN TAMAMIYLA ARAMA. "TMS 1 Finansal Tablolarin Sunulusu, m.38
# (Karsilastirmali Bilgi ilkesi)" etiketi ambarda birebir boyle gecmez, bu yuzden
# ilike bos donuyordu. Artik once tam etiket, olmazsa etiketten cikarilan
# STANDART/KANUN KODU ("TMS 1", "BDS 230", "TTK 474", "6362") aranir.
$reDilDers = [regex]'(?i)yabanc[ıi]\s*dil|ingiliz|t[üu]rk[çc]e|matematik|atat[üu]rk|inkil[âa]p|genel\s*k[üu]lt[üu]r'
$reKod = [regex]'(?i)\b(TMS|TFRS|BDS|KKS|TSRS|SGDS|VUK|TTK|TBK|GVK|KVK|KDVK|AATUHK|SMK|[İI][İI]K|MSUGT|THP)\s*(GT\s*)?(\d{1,4})?'
$reSayiliK = [regex]'(?i)\b(\d{4})\s*say[ıi]l[ıi]'

# 03.08 - CEM'IN HESAP KODU BULGUSU. Soru etiketi "1 Sira No'lu Muhasebe Sistemi
# Uygulama Genel Tebligi - Tekduzen Hesap Plani" diyordu; arama kodu yalniz MSUGT
# ve THP KISALTMALARINI taniyordu, ACIK TURKCE ADINI tanimiyordu. Sonuc: ya hic
# eslesmedi ya da yanlis MSUGT belgesi (ilkeler metni) geldi - icinde hesap listesi
# olmayan bir metin. Model de 253/122/127 gibi hesap kodlarini KENDI HAFIZASINDAN
# yazdi (253 = Tesis Makine Cihazlar; personel avansi 196'dir).
# Cozum: acik adlari kisaltmaya cevir ve HESAP PLANI etiketinde TAM listeyi ara.
$ADSOZLUK = @(
  @{ desen='(?i)tekd[üu]zen\s*hesap\s*plan|hesap\s*plan[ıi]';        ara='thp-tam' }
  @{ desen='(?i)muhasebe\s*sistemi\s*uygulama\s*genel\s*tebli';      ara='msugt' }
  @{ desen='(?i)vergi\s*usul\s*kanunu';                              ara='vuk' }
  @{ desen='(?i)t[üu]rk\s*ticaret\s*kanunu';                         ara='ttk' }
  @{ desen='(?i)t[üu]rk\s*bor[çc]lar\s*kanunu';                      ara='tbk' }
  @{ desen='(?i)gelir\s*vergisi\s*kanunu';                           ara='gvk' }
  @{ desen='(?i)kurumlar\s*vergisi\s*kanunu';                        ara='kvk' }
  @{ desen='(?i)katma\s*de[ğg]er\s*vergisi';                         ara='kdv' }
  @{ desen='(?i)[İIi]cra\s*ve\s*[İIi]flas\s*Kanunu';                 ara='iik' }
  @{ desen='(?i)sosyal\s*sigortalar|5510';                           ara='5510' }
  @{ desen='(?i)[İIi][şs]\s*Kanunu|4857';                            ara='4857' }
)
# ============================================================================
#  KARDES KAYNAK — 03.08, Cem: "ara tasdik var miydi? boyle ayrintiya kadar
#  verirsek buyuklugumuz ortaya cikar."
#
#  ACIK SUYDU: dayanak TEK MADDEYE kilitliydi. Defter tasdiki sorusunun kaynagi
#  TTK m.64/3 (acilis-kapanis onayi); ama ARA TASDIK/YENILEME hukmu VUK m.222'de
#  ("Defterlerini ertesi yilda da kullanmak isteyenler Ocak ayi... icinde
#  tasdiki yeniletmeye mecburdurlar"). Motor o maddeyi HIC gormedigi icin
#  yazamiyordu - D4 geregi de yazmamaliydi. Yani kusur bilgide degil KAPSAMDA.
#
#  COZUM: konu kumeleri icin KARDES MADDELER de dayanaga eklenir. Boylece
#  D15 (sinir ciz) gercekten calisir: ogrenci acilis + kapanis + yenileme
#  uclusunu bir arada gorur. Uydurma yok - hepsi ambardan okunur.
#
#  Liste KUCUK ve ELLE tutulur; her satir gercek bir sinav kumesidir.
# ============================================================================
$script:KARDES = @(
  @{ desen='(?i)defter\s*tasdik|yevmiye\s*defter|defteri\s*kebir|a[çc][ıi]l[ıi][şs]\s*onay|kapan[ıi][şs]\s*onay|ticari\s*defter'
     ekler=@(@{kod='VUK';madde='220'},@{kod='VUK';madde='221'},@{kod='VUK';madde='222'},@{kod='TTK';madde='64'}) }
  @{ desen='(?i)amortisman'
     ekler=@(@{kod='VUK';madde='313'},@{kod='VUK';madde='315'},@{kod='VUK';madde='320'}) }
  @{ desen='(?i)[şs][üu]pheli\s*alacak|de[ğg]ersiz\s*alacak'
     ekler=@(@{kod='VUK';madde='322'},@{kod='VUK';madde='323'},@{kod='VUK';madde='324'}) }
  @{ desen='(?i)maliyet\s*bedeli|de[ğg]erleme'
     ekler=@(@{kod='VUK';madde='262'},@{kod='VUK';madde='270'},@{kod='VUK';madde='275'}) }
  @{ desen='(?i)fatura|sevk\s*irsaliye|belge\s*d[üu]zen'
     ekler=@(@{kod='VUK';madde='229'},@{kod='VUK';madde='231'},@{kod='VUK';madde='232'}) }
)
# 03.08 - CEM: "bugun dun bulduklarimiza 'onu yapacaksin' deme."
# Elle yazdigim 5 kume artik TEK basina degil: kardes-kaynak-cikar.ps1 kasadaki
# konu dagilimindan kumeleri OLCUMLE cikariyor. Dosya varsa o da yuklenir ve
# elle listeye eklenir; yoksa elle liste tek basina calisir (geriye donuk uyum).
$kkYol = Join-Path $kok 'veri/kardes-kaynak.json'
if(Test-Path $kkYol){
  try {
    $kkVeri = Get-Content $kkYol -Raw -Encoding UTF8 | ConvertFrom-Json
    $eklenen = 0
    foreach($km in @($kkVeri.kumeler)){
      $ad = "$($km.konu)".Trim(); if($ad.Length -lt 3){ continue }
      $ekList = @()
      foreach($m in @($km.maddeler)){ $ekList += @{ kod="$($m.kod)"; madde="$($m.madde)" } }
      if($ekList.Count -lt 2){ continue }
      $script:KARDES += @{ desen = '(?i)' + [regex]::Escape($ad); ekler = $ekList }
      $eklenen++
    }
    Write-Host ("Kardes kume (olcumle cikan): {0} eklendi" -f $eklenen)
  } catch { Write-Host "kardes-kaynak.json okunamadi, elle liste kullanilacak." }
} else { Write-Host "kardes-kaynak.json yok - elle liste kullanilacak." }

$kardesOnbellek = @{}
function KardesMetin([string]$kod, [string]$madde){
  $anah = "$kod|$madde"
  if($kardesOnbellek.ContainsKey($anah)){ return $kardesOnbellek[$anah] }
  $sonuc = ''
  try {
    $a = [Uri]::EscapeDataString($kod)
    $b = CekListe "$DK`?select=metin&kaynak_ad=ilike.*$a*&limit=1"
    if($b.Count -gt 0){
      $d = DayanakDilim "$($b[0].metin)" "m.$madde"
      if($d.bulundu){ $sonuc = $d.metin.Substring(0, [Math]::Min(1200, $d.metin.Length)) }
    }
  } catch {}
  $kardesOnbellek[$anah] = $sonuc
  return $sonuc
}

$atlanan = New-Object System.Collections.Generic.List[object]
$hazir   = New-Object System.Collections.Generic.List[object]
$dilSoru = 0
$tahdidiYenilenen = 0
$kardesEklenen = 0
$formulEksikYenilenen = 0
$hesapKoduYanlis = 0
$hesapKoduDuzeltilen = 0
$hesapKoduSupheli = 0
$hesapKoduGecersizUretim = 0                                        # uretilen kod 3-hane/THP degil - unwrap bug'i sinifi
$hesapKoduSilmeAdayi = 0                                            # 04.08: SILME KAPATILDI - yalniz aday sayilir, metne dokunulmaz
$script:eksikHarfTekrar = 0                                         # dogrusu/tuzak harfi eksikti, yeniden istendi
$script:eksikHarfKalan  = 0                                         # uc denemede de tamamlanmadi - SESSIZ KAYIP YOK
$script:hesapKoduOrnek = New-Object System.Collections.Generic.List[object]  # rapora ornek (yalniz THP kod-ad, soru metni YOK)
$dayanakOnbellek = @{}
foreach($i in $isler){
  $kay = "$($i.soru.kaynak)".Trim()
  $ders = "$($i.soru.ders)"

  # --- mevzuat disi ders: dayanak aranmaz, ama kanun atfi da YASAK ---
  if($reDilDers.IsMatch($ders)){
    $i | Add-Member -NotePropertyName dayanak -NotePropertyValue '' -Force
    $i | Add-Member -NotePropertyName mevzuatdisi -NotePropertyValue $true -Force
    $hazir.Add($i); $dilSoru++
    if($sinir -gt 0 -and $hazir.Count -ge $sinir){ break }
    continue
  }

  if($kay.Length -lt 6){ $atlanan.Add([ordered]@{ id="$($i.soru.id)"; sebep='kaynak etiketi yok' }); continue }
  if(-not $dayanakOnbellek.ContainsKey($kay)){
    $metin = ''
    # 1) tam etiket
    $arama = [Uri]::EscapeDataString(($kay -replace '\s+',' '))
    try {
      $bul = CekListe "$DK`?select=metin&kaynak_ad=ilike.*$arama*&limit=1"
      if($bul.Count -gt 0){ $metin = "$($bul[0].metin)" }
    } catch {}
    # 2) olmazsa etiketten cikarilan standart/kanun kodu
    if($metin.Length -lt 40){
      $kod = ''
      # 1) ACIK TURKCE AD -> kisaltma (Cem'in hesap kodu bulgusu, 03.08)
      foreach($a in $ADSOZLUK){ if($kay -match $a.desen){ $kod = $a.ara; break } }
      # 2) etiketin icindeki kisaltma/standart kodu
      if($kod -eq ''){
        $m = $reKod.Match($kay)
        if($m.Success){ $kod = (($m.Groups[1].Value + ' ' + $m.Groups[3].Value).Trim()) }
      }
      if($kod -eq ''){ $m2 = $reSayiliK.Match($kay); if($m2.Success){ $kod = $m2.Groups[1].Value } }
      if($kod -ne ''){
        $a2 = [Uri]::EscapeDataString($kod)
        try {
          $b2 = CekListe "$DK`?select=metin&kaynak_ad=ilike.*$a2*&limit=1"
          if($b2.Count -gt 0){ $metin = "$($b2[0].metin)" }
        } catch {}
      }
    }
    $dayanakOnbellek[$kay] = $metin
  }
  $metin = $dayanakOnbellek[$kay]
  if($metin.Length -lt 40){ $atlanan.Add([ordered]@{ id="$($i.soru.id)"; sebep="dayanak ambarda cozulemedi: $kay" }); continue }
  $i | Add-Member -NotePropertyName dayanak -NotePropertyValue $metin -Force
  $i | Add-Member -NotePropertyName mevzuatdisi -NotePropertyValue $false -Force

  # ---- D11'E IKINCI DAR ISTISNA: YONTEM VAR AMA FORMUL YOK ----
  # 03.08, Cem: "dikey analiz soruluyor, formulu goremedim - boyle karar almistik."
  # Hakli ve kusur KURGUMDA: D13-ek (yontem adi gecerse tanimi + formulu yaz)
  # kurali DORT PARCA isteminin ICINE gomuluydu. Bu soruda dort parca
  # ISTENMEMISTI (eskisi tam), dolayisiyla formul kurali hic calismadi.
  # Kural vardi ama yalnizca dort parca yeniden yazilirken devreye giriyordu.
  # Cozum: yontem adi gecen VE mevcut Kural'da formul BULUNMAYAN soruda dort
  # parca yenilenir. Tahdidi liste istisnasinin ayni mantigi.
  if($i.eksik -notcontains 'D1_dort_parca'){
    # 03.08 gece - Cem: "degisim orani" sorusunda formul yoktu ama bu kalip
    # listede hic yoktu, D13-ek hic tetiklenmedi. Karsilastirmali/yatay analiz
    # ailesinin butun yaygin adlarini ekledim.
    $reYontem = [regex]'(?i)dikey\s*y[üu]zde|yatay\s*y[üu]zde|y[üu]zde\s*analiz|dikey\s*analiz|yatay\s*analiz|devir\s*h[ıi]z|oran\s*analiz|rasyo|maliyetleme\s*y[öo]ntem|de[ğg]i[şs]ken\s*maliyet|tam\s*maliyet|k[ıi]st\s*amortisman|reeskont|e[şs]de[ğg]er\s*[üu]r[üu]n|trend\s*analiz|de[ğg]i[şs]im\s*oran|art[ıi][şs]\s*oran|azal[ıi][şs]\s*oran|b[üu]y[üu]me\s*oran|kar[şs][ıi]la[şs]t[ıi]rmal[ıi]\s*(tablo|analiz)|kald[ıi]ra[çc]|cari\s*oran|likidite\s*oran|asit\s*test|kar[şs][ıi]l[ıi]k\s*oran|k[aâ]rl[ıi]l[ıi]k\s*oran|stok\s*devir|alacak\s*devir|bor[çc]\s*oran|[öo]z\s*kaynak\s*oran'
    $dhy = "$($i.soru.dogru)".Trim().ToUpper()
    $mevcutY = ''
    try { if($i.soru.aciklama -and $i.soru.aciklama.PSObject.Properties[$dhy]){ $mevcutY = "$($i.soru.aciklama.$dhy)" } } catch {}
    # Formul izi: "X = Y" ya da bolme/carpma isareti tasiyan bir ifade
    $formulVar = [regex]::IsMatch($mevcutY, '(?i)[A-Za-zÇĞİÖŞÜçğıöşü\)]\s*[=÷]\s*|[A-Za-zÇĞİÖŞÜçğıöşü]\s*/\s*[A-Za-zÇĞİÖŞÜçğıöşü]')
    if($reYontem.IsMatch("$($i.soru.soru) $($i.soru.konu)") -and -not $formulVar){
      $i.eksik = @($i.eksik) + 'D1_dort_parca'
      $script:formulEksikYenilenen++
    }
  }

  # ---- D11'E DAR ISTISNA (03.08, Cem'in Is K. m.4 bulgusu) ----
  # D11 "dolu ve iyi olana dokunma" der. Ama biçimsel olarak TAM olan bir Kural
  # parcasi, dayanak TAHDIDI LISTE ise (kanun "yalnizca sunlar" diyorsa) yine de
  # EKSIK olabilir: ogrenci dogru cevabi okuyor ama listenin kalanini gormuyor,
  # yani SINIRI ogrenmiyor. Is K. m.4 vakasi: eski Kural yalniz "tarim/orman
  # 50'den az" diyordu; deniz-hava tasima, ev hizmetleri, ciraklar, sporcular
  # hic gecmiyordu. O bilgi yalniz A sikkinda kalmisti - C'yi isaretleyen hic
  # gormuyordu.
  # Bu yuzden: dayanak tahdidi liste VE mevcut Kural o bentleri yansitmiyorsa
  # dort parca YENIDEN yazilir. Diger sorulara dokunulmaz - istisna DAR.
  if($i.eksik -notcontains 'D1_dort_parca'){
    $bentSayisi = ([regex]::Matches($metin, '(?m)^\s*[a-ıi]\)\s')).Count
    if($bentSayisi -lt 3){ $bentSayisi = ([regex]::Matches($metin, '\s[a-ıi]\)\s')).Count }
    # 03.08 - KENDI TETIGIMI SIKILASTIRDIM. Once yalniz "dayanakta 4+ bent var mi"
    # diye bakiyordum; bu VEKIL bir olcu, gercek sart degil. Duzenli yazilmis her
    # madde bentlidir - o zaman iyi bir aciklamayi bosuna yeniden yazdiririz, yani
    # D11'in onlemek icin var oldugu zarari ben acmis olurum.
    # GERCEK SART SORUNUN KENDISINDE: soru bir KAPSAM/SINIR sorusu mu?
    # {0,30} dardi, "hangisi ... degildir" kalibini kaciriyordu (arada 30+ karakter
    # var). Kendi testim yakaladi; {0,80}'e acildi.
    # 03.08 IKINCI GENISLETME (Cem'in TTK m.516 bulgusu): desen yalniz OLUMSUZ
    # sinir sorularini taniyordu ("hangisi uygulanmaz/degildir"). Oysa TAHDIDI
    # LISTE olumlu de sorulur: "hangi bilgi faaliyet raporunda MUTLAKA yer
    # almalidir?" - TTK m.516/2 uc bent sayar (sonraki olaylar, Ar-Ge,
    # yoneticilere odenen mali menfaatler); aciklama yalniz ucuncusunu
    # anlatiyordu. Olumlu kaliplar da eklendi.
    # Yanlis pozitif riski yok: tetik AYRICA dayanakta 4+ bent sarti ariyor.
    $reSinirSorusu = [regex]'(?i)hangisi(nde)?\s+.{0,80}(uygulanmaz|kapsam\s*d[ıi][şs][ıi]|say[ıi]lmaz|girmez|de[ğg]ildir|dahil\s+de[ğg]il)|hangi(si)?\s+.{0,80}(zorunlu|mutlaka|yer\s+alma|dahildir|say[ıi]l[ıi]r|gerekir|aran[ıi]r)|istisna|kapsam[ıi]\s+d[ıi][şs][ıi]nda|zorunlu\s+olarak\s+yer'
    $sinirSorusuMu = $reSinirSorusu.IsMatch("$($i.soru.soru)")
    if($bentSayisi -ge 4 -and $sinirSorusuMu){
      $dhx = "$($i.soru.dogru)".Trim().ToUpper()
      $mevcut = ''
      try { if($i.soru.aciklama -and $i.soru.aciklama.PSObject.Properties[$dhx]){ $mevcut = "$($i.soru.aciklama.$dhx)" } } catch {}
      $mevcutBent = ([regex]::Matches($mevcut, '\s[a-ıi]\)\s')).Count
      if($mevcutBent -lt 3){
        $i.eksik = @($i.eksik) + 'D1_dort_parca'
        $script:tahdidiYenilenen++
      }
    }
  }
  $hazir.Add($i)
  if($sinir -gt 0 -and $hazir.Count -ge $sinir){ break }
}
Write-Host ("Mevzuat disi ders (dayanak aranmadan gecen): {0}" -f $dilSoru)
Write-Host ("Islenebilir: {0} | Atlanan (dayanaksiz): {1}" -f $hazir.Count, $atlanan.Count)

# ============================================================================
#  DAYANAK DILIMI — 03.08, Cem "aciklama az olmus" deyince bulundu.
#
#  ESKI HALI: $dayanak.Substring(0,2500) — belgenin ILK 2500 karakteri.
#  "Is K. (4857 s.K.) m.11" dendiginde ambardaki belge BUTUN Is Kanunu'dur;
#  ilk 2500 karakter amac/kapsam maddeleridir. Yani modele m.11 HIC GITMEDI,
#  model kendi bildiginden yazdi. Aciklamalarin cilizligi buradan geliyordu.
#
#  YENI HALI: etiketteki madde numarasi metinde ARANIR ve o maddenin ETRAFINDAN
#  pencere alinir. Pencere genis (5000) cunku KOMSU MADDELER de lazim: ogrenciye
#  "bu kavram aslinda nerede dogru" diyebilmek icin yan maddeyi gormesi gerekir
#  (TTK 482->483 dersi, B13 komsu madde).
# ============================================================================
$reMadde = [regex]'(?i)\b(?:m|md|madde|par|p)\.?\s*(\d{1,3})'
function DayanakDilim([string]$metin, [string]$kaynak){
  if($metin.Length -le 5000){ return @{ metin=$metin; bulundu=$true } }
  $mm = $reMadde.Match($kaynak)
  if($mm.Success){
    $no = $mm.Groups[1].Value
    # "MADDE 11", "Madde 11-", "MADDE 11 –" gibi bicimleri ara
    $ara = [regex]::new('(?im)^\s*madde\s*' + [regex]::Escape($no) + '\s*[-–—:\.\s]')
    $bul = $ara.Match($metin)
    if(-not $bul.Success){
      $ara2 = [regex]::new('(?i)madde\s*' + [regex]::Escape($no) + '\s*[-–—:]')
      $bul = $ara2.Match($metin)
    }
    if($bul.Success){
      $bas = [Math]::Max(0, $bul.Index - 300)
      $uz  = [Math]::Min(5000, $metin.Length - $bas)
      return @{ metin=$metin.Substring($bas, $uz); bulundu=$true }
    }
  }
  # madde bulunamadi: bastan al ama ISARETLE - model uydurmasin diye bilmeli
  return @{ metin=$metin.Substring(0, [Math]::Min(5000, $metin.Length)); bulundu=$false }
}

# --- THP LISTESI: yevmiye/tablo istenen soruda resmi kod->ad listesi isteme
#     eklenir. 03.08 dersi (Cem'in 253 bulgusu): kanun metninde hesap kodu
#     YOKTUR; listeyi vermezsen model hafizadan yazar. ---
$script:THP_AD = @{}   # kod -> resmi ad (Cem'in 181 bulgusu icin esleme denetimi)
$script:THP_LISTE = ''
# ============================================================================
#  TURKCE BUYUK HARF TUZAGI (03.08 gece, Cem'in "hicbiri eslesmiyor" bulgusu)
#
#  Iki KATMANLI kultur hatasi: (1) .ToUpperInvariant() Turkce 'i' harfini
#  buyutmuyor bile (invariant kulturde eslesigi yok, kucuk kaliyor). (2) bu
#  sunucunun sistem kulturu tr-TR; PowerShell'in -replace/-match operatoru
#  kultur duyarli calisiyor ve tr-TR altinda DUZ BUYUK 'I' harfi bile [A-Z]
#  araligina GIRMIYOR ('I' -match '[A-Z]' => False). Sonuc: 'i' ya da 'i'
#  gecen HER kelime (yani neredeyse her Turkce hesap adi) harf temizleme
#  satirinda parcalaniyor - "Genel Uretim Giderleri" -> GENEL|URET|DERLER
#  oluyor, ÜRETIM kelimesi tumden kayboluyor. Bu yuzden 0 duzeltme cikti.
#
#  DUZELTME: Turkce kulturune gore buyut + CultureInvariant regex kullan
#  (regex araligi kultur collation'undan etkilenmesin).
# ============================================================================
$script:TR_KULTUR = [Globalization.CultureInfo]::GetCultureInfo('tr-TR')
$script:REGEX_KI  = [System.Text.RegularExpressions.RegexOptions]::CultureInvariant
function AnlamliKelimeler([string]$metin){
  $u = $metin.ToUpper($script:TR_KULTUR)
  $temiz = [regex]::Replace($u, '[^A-ZÇĞİÖŞÜ ]', ' ', $script:REGEX_KI)
  return @($temiz -split '\s+' | Where-Object { $_.Length -ge 4 })
}
# 03.08 - TEK DOSYA DEGIL HEPSI (Cem: "hesap planini tam yut"):
# msugt-thp-tam.json 199 hesap tasiyor ama 100 KASA, 102 BANKALAR, 120 ALICILAR,
# 600 YURTICI SATISLAR, 730 GENEL URETIM GIDERLERI ICERMIYOR - onlar msugt-thp2
# ve digerlerinde. Yani modele EKSIK liste veriyordum; kullanmasi gereken kod
# listede olmayinca yine hafizadan yazmasi kaciniLmazdi.
# Birlesince 230 hesap ve temel hesaplarin hepsi var.
$c2 = New-Object System.Collections.Generic.List[string]
foreach($tf in (Get-ChildItem (Join-Path $kok 'veri/mevzuat/msugt*.json') -ErrorAction SilentlyContinue)){
  try {
    $thpVeri2 = Get-Content $tf.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach($b in @($thpVeri2.belgeler)){
      $m2t = [regex]::Match("$($b.kaynak_ad)", '(?i)THP\s*(\d{3})\s*[-–—]\s*(.+)$')
      if($m2t.Success -and -not $script:THP_AD.ContainsKey($m2t.Groups[1].Value)){
        $c2.Add(($m2t.Groups[1].Value + ' ' + $m2t.Groups[2].Value.Trim()))
        $script:THP_AD[$m2t.Groups[1].Value] = $m2t.Groups[2].Value.Trim()
      }
    }
  } catch {}
}
if($c2.Count -ge 50){ $script:THP_LISTE = ($c2 | Sort-Object) -join "`n" }
Write-Host ("THP listesi: {0} hesap (tum msugt dosyalari birlestirildi)" -f $script:THP_AD.Count)

# ============================================================================
#  THP LISTESI KIME GIDER — 03.08 gece OLCUMUYLE GENISLETILDI
#
#  Olcum (veri/thp-liste-maliyet-raporu.json): simdiki genis desen 19.094
#  soruya listeyi gonderiyor (48,19 USD). Daraltma senaryolari 21-25 USD
#  kazandiriyordu AMA 9.087 soruyu listesiz birakiyordu -> yanlis hesap kodu
#  riski. 21 USD icin bunu goze almak KOTU TAKAS: bir tek yanlis kod ogrenciye
#  yanlis ogretir.
#
#  Ayni olcum GERCEK BIR DELIK buldu: 842 soru simdiki desene UYMUYOR ama
#  metninde GERCEK hesap kodu VAR - yani liste gitmiyor, model hafizadan
#  yaziyor. Cem'in yakaladigi 181 vakasinin ta kendisi, hala acikti.
#
#  KARAR: daraltma YOK, tam tersi GENISLETME (+2,12 USD, ~842 soru kurtulur).
#  Kosula "metinde gercek hesap kodu izi var mi" eklendi ve artik SORU+SIKLAR+
#  ACIKLAMA taranir (eskiden yalniz ders+konu+soru bakiliyordu - delik oradaydi).
#
#  KULTUR NOTU: [regex]::IsMatch(..., CultureInvariant) kullanilir. PowerShell
#  -match operatoru kultur duyarlidir ve tr-TR'de 'I' harfi [A-Z] araligina
#  GIRMEZ - bu gece ayni tuzaga uc kez dustuk, dorduncusu olmasin.
# ============================================================================
#  BIRIM TUZAGI (bu gecenin en sik sahte alarmi): "750 TL", "480 adet" hesap
#  kodu DEGIL tutardir. Sayidan sonraki kelime birim ya da "numarali/hesap"
#  gibi bir baglayici ise eslesme SAYILMAZ.
$script:RE_KOD_IZI = New-Object System.Text.RegularExpressions.Regex(
  '(?<![\d.,])\b[1-8]\d{2}(?!\d)\s*[-–—]?\s*(?!(?:TL|USD|EUR|LIRA|L[İI]RA|adet|kalem|tane|ki[şs]i|g[üu]n|ay\b|y[ıi]l|saat|kg|ton|puan|kuru[şs]|taksit|numaral|no\.?lu|say[ıi]l|hesab|hesap|kodlu|nolu))[A-Za-zÇĞİÖŞÜçğıöşü]|[A-Za-zÇĞİÖŞÜçğıöşü]\s*\(\s*[1-8]\d{2}\s*\)',
  ([System.Text.RegularExpressions.RegexOptions]::CultureInvariant -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase))
function HesapKoduIziVar($s){
  $t = "$($s.soru)"
  try { if($s.siklar){   foreach($p in $s.siklar.PSObject.Properties){   $t += ' ' + "$($p.Value)" } } } catch {}
  try { if($s.aciklama){ foreach($p in $s.aciklama.PSObject.Properties){ $t += ' ' + "$($p.Value)" } } } catch {}
  return $script:RE_KOD_IZI.IsMatch($t)
}

# --- ISTEM KURUCU: yalniz EKSIK olanlari ister ---
function IstemKur($i){
  $s = $i.soru
  $sik = ""
  foreach($h in 'A','B','C','D','E'){ if($s.siklar.PSObject.Properties[$h]){ $sik += "$h) $($s.siklar.$h)`n" } }
  $ist = @()
  if($i.eksik -contains 'D1_dort_parca'){ $ist += @'
dort_parca: dogru sikkin aciklamasi. DORT BASLIK ZORUNLU, birebir su sirayla ve
  bu adlarla yazilacak (baslik atlanirsa is REDDEDILIR):
    "Ne soruluyor:"  -> sorunun ne sordugunu tek cumleyle sadelestir.
    "Kural:"         -> kurali GUNLUK DILLE anlat. Kanun cumlesini KOPYALAMA,
                        cevir. Gerekiyorsa madde numarasini sonda parantezde ver.
                        !! ILKENIN ADINI SOYLE (04.08, Cem'in bulgusu) !!
                        Bir kural bir ILKEDEN doguyorsa o ilkenin ADI yazilacak:
                        donemsellik, ihtiyatlilik, maliyet bedeli, tam aciklama,
                        ozun onceligi, tutarlilik, isletmenin surekliligi...
                        Cem'in yakaladigi vaka: "pesin odenen kirada yalniz cari
                        aya dusen kisim gider yazilir" DENMIS ama NEDEN yazilmamis.
                        Dogrusu: "...DONEMSELLIK ILKESI geregi yalnizca cari aya
                        dusen kisim gider yazilir; kalani 180'de bekler."
                        Ogrenci mekanigi degil GEREKCEYI ogrenirse transfer eder.
                        SINIRI DA CIZ (Cem'in 03.08 talimati): dayanakta goruyorsan
                        kisaca say -> NELER GIRER, NELER GIRMEZ, NELER IHTIYARIDIR.
                        Ornek (maliyet bedeli): "Montaj ve nakliye girer; envantere
                        alindiktan SONRAKI sigorta girmez; gayrimenkullerde noter,
                        tapu harci ve emlak alim vergisini maliyete katmak ya da
                        dogrudan gider yazmak ISLETMENIN TERCIHIDIR."
                        TAHDIDI LISTE ISE (kanun "yalnizca sunlar" diyorsa) LISTENIN
                        TAMAMINI yaz ve sorunun olayi hangi bende dustugunu isaretle.
                        Ornek: Is K. m.4 istisnalari a-i bentleri - hepsini say, cunku
                        sinav hep LISTEDE OLMAYANI sorar. Liste ana aciklamada bir kez
                        durur; siklarda TEKRARLANMAZ (sisme yapar).
                        Ogrenci yalniz bu olayi degil KURALIN SINIRINI ogrenmeli;
                        sinav ayni kurali baska bir kalemle sorar. Dayanakta
                        gormedigin kalemi SAYMA - liste uydurmak yasak.
    "Bu olayda:"     -> SORUDAKI KENDI RAKAMLARINI kullanarak adim adim goster
                        (ornek: "Ham madde 68.328 + Iscilik 14.205 + GUG 9.118 =
                        91.651 TL"). Rakam yoksa olayi somut anlat.
    "Akilda kalsin:" -> sinavda ise yarayacak TEK cumlelik pusula.
  400-700 karakter. Olcut sudur: MUHASEBE HIC BILMEYEN biri okuyunca anlamali.

  YONTEM ADI GECIYORSA ONU ANLAT + FORMULU YAZ (03.08, Cem'in talimati):
  Soru bir YONTEM/TEKNIK adi tasiyorsa (degisken maliyetleme, tam maliyetleme,
  dikey yuzde analizi, kist amortisman, reeskont, esdeger urun...) Kural parcasi
  once o yontemin NE OLDUGUNU bir cumleyle soyler, sonra FORMULU ayri satirda
  verir. Ornek:
    "Degisken maliyetleme: mamulun sirtina yalniz uretim arttikca artan giderler
     yuklenir; uretim olsa da olmasa da degismeyen sabit giderler donem gideri
     sayilir.
     Birim maliyet = (direkt hammadde + direkt iscilik + DEGISKEN genel uretim
     gideri) / uretim adedi   -- sabit genel uretim gideri BU FORMULE GIRMEZ."
  Ogrenci yontemi bilmeden rakami dogru bulsa bile bir sonraki soruda kaybeder.
  Formulu dayanakta gormesen de yontemin TANIMI mevzuat degil muhasebe teknigidir
  ve yazilabilir; ancak ORAN/TUTAR/ESIK yine yalniz dayanaktan alinir.

  GUNCEL TERIM ONDE, KANUN DILI PARANTEZDE (03.08, Cem: "sinava gireceklere
  eski Turkce ogretmeyelim"):
  Kanunun metni eski terim kullaniyorsa ama bugunku Tekduzen Hesap Plani /
  sinav dili baska terim kullaniyorsa, ONCE GUNCEL TERIMI yaz, kanunun
  lafzini BIR KEZ parantezde ver. Tersi YASAK.
    "genel uretim giderleri (VUK m.275'te 'genel imal giderleri' denir)"  DOGRU
    "genel imal giderleri"  TEK BASINA YAZILMAZ - aday sinavda bu terimi gormez.
  Ayni sekilde: "satin alma" (mubayaa), "gider" (masraf), "stok/emtia" ikisi de
  gecerlidir - zorlama cevrim yapma. Kod adi verirken THP'nin RESMI ADINI kullan
  (730 GENEL URETIM GIDERLERI).
  Emin degilsen kanun lafzini birak; UYDURMA es anlamli terim yazma.

  TERIMI ACIKLA (03.08, Cem: "annem bile anlasin o anlamda diyorum"):
  Bir teknik terim ILK GECTIGI yerde kisa bir parantezle gunluk dile cevrilir.
  Ornek: "genel idare gideri (muhasebecinin maasi, ofis kirasi, yonetim
  giderleri gibi uretim atolyesiyle dogrudan ilgisi olmayan giderler)".
  Ornek: "reeskont (vadeli alacagin bugunku degerine indirgenmesi)".
  Terimi aciklamadan kullanmak, aciklamayi yalnizca BILENE yazmak demektir -
  oysa aciklamayi BILMEYEN okuyor. Terim zaten sorunun icinde tanimlanmissa
  tekrar etme; parantez KISA olacak, cumleyi bogmayacak.

  "AKILDA KALSIN" KURAL ILE CELISEMEZ: Kural "ihtiyaridir" diyorsa Akilda
  kalsin "girer" diye baslayamaz. (Pilotta tam bu oldu: Kural "katilmasi
  ihtiyaridir" derken Akilda kalsin "maliyet bedeline girer ama..." dedi -
  ogrenciyi ters yone ceker.) Dogrusu: "katmak zorunlu degil, isletmenin
  tercihi". Iki parca ayni yone bakacak.

  YASAK KELIMELER (kanun kopyasi kokuyor, kullanma): "bilumum", "muteferri",
  "munasebetiyle", "isbu", "mezkur", "ifade eder", "tanzim", "mutazammin",
  "sair", "taht-i", "keyfiyet". Bunlarin yerine gunluk karsiligini yaz.

  !! TERIM UYDURMA (04.08, Cem'in bulgusu) !!
  Kendi kisaltmani icat etme; YERLESIK terimi kullan. Cem "cok donemli
  giderler" ifadesini "cok ONEMLI" diye okudu - bir SMMM yanlis okuyorsa
  aday kesin yanlis okur. YASAK -> DOGRUSU:
    "cok donemli gider"      -> "birden fazla donemi ilgilendiren gider"
                                 (ya da dogrudan "pesin odenen gider")
    "cok yilli gider"        -> "gelecek yillara ait giderler"
    "donemsel gider"         -> "doneme ait gider"
    "coklu donem"            -> "birden fazla donem"
    "giderlestirme islemi"   -> "gider kaydi"
  KURAL: bir kavrami iki kelimeye sikistirmak yerine MEVZUATTAKI ya da
  ders kitabindaki adiyla yaz. Uzun ama dogru, kisa ama uydurmaya yegdir.

  ESKI TERIM (04.08 olcumu: 4.328 soruda var, 2.975'i kehribar kartta):
    "genel imal gideri/giderleri" -> "genel uretim giderleri (THP 730)"
    "genel idare gideri/giderleri" -> "genel yonetim giderleri" (06.08 Cem
    onayi; VUK m.275 baglaminda parantezle: "(VUK lafzi: genel idare)")
    "iptidai madde" -> "ilk madde ve malzeme" (06.08 Cem onayi #15; senaryo
    cumlesinde arkaik kacar; kanun metni TIRNAK icinde aktariliyorsa korunur)
  ISTISNA: kanunun KENDI lafzi tirnak icinde aktariliyorsa degistirme
  (ornek: VUK m.275 "imal edilen emtia" der - o kanun metnidir, korunur;
  D26: guncel terim onde, kanun lafzi parantezde).

  YAPAY ZEKA KOKUSU YASAK: "onemli bir husustur", "dikkat edilmesi gereken
  nokta", "sonuc olarak", "ozetle", "bu baglamda", "unutulmamalidir ki" gibi
  doldurma kaliplari kullanma. Dogrudan konuyu anlat, giris-gelisme-sonuc kurma.

  D28 - KAPSAM SORUSUNDA UNSURLAR HER DURUMDA SAYILIR (06.08, Cem #102 +
  duzeltmesi: "kalip yazmazsa saymayacak misin?"): tetik KALIP degil SORU
  TIPIDIR. Soru bir kapsam/liste hukmune dayaniyorsa (hangileri dahildir /
  neler girer / hangisi sayilmistir tipi), dogru sik aciklamasi dayanaktaki
  unsurlari TEK TEK sayar - "sinirli sayida" yazsa da yazmasa da (VUK m.275
  orneginde birebir: hammadde, iscilik, genel uretim giderleri, ihtiyari
  genel yonetim payi, zaruri ambalaj). "Sinirli sayida/tahdidi" gibi kaliplar
  tek basina yazilamaz; kullanilacaksa sade Turkcesiyle ("kanun bunlari tek
  tek saymistir; listede olmayan giremez") ve listeyle birlikte gelir.

  D29 - "X, Y DEGILDIR" TOTOLOJISI YASAK + TERIM KARARI (06.08, Cem onayi;
  UC SINAV icin de gecerli): iki terim karsilastiriliyorsa IKISI DE birer
  somut ornekle tanimlanir: genel uretim gideri = uretimle ilgili ama tek
  mamule dogrudan yuklenemeyen gider (atolye kirasi, uretim makinesi
  amortismani, fabrika elektrigi); genel yonetim gideri = isletme yonetiminin
  gideri (genel mudur maasi, merkez ofis kirasi, muhasebe personeli ucreti).
  Turnusol cumlesi verilir: gider FABRIKADAN mi dogdu, YONETIMDEN mi?
  TERIM: ana terim "genel yonetim giderleri"dir (OLCULDU: 112 gercek sinav
  kitapciginda 116 kez "genel yonetim", yalniz 2 kez "genel idare"); VUK
  m.275 baglaminda lafzi parantezle verilir: "genel yonetim giderleri
  (VUK m.275 lafzi: genel idare giderleri)". Kanun metni TIRNAK icinde
  aktariliyorsa lafiz korunur (D26 istisnasi).

  D30 - ASAMA GEREKCESI (06.08): bir giderin maliyete girmeme sebebi yazilirken
  "dahil degildir" demek yetmez; HANGI ASAMANIN gideri oldugu soylenir
  (pazarlama/satis giderleri uretim asamasinin degil SATIS asamasinin
  gideridir -> donem gideri). Zaruri mamul ambalaji (maliyete girer) ile
  satis/pazarlama ambalaji (donem gideri) ayrimi acikca yazilir.

  D31 - SAYISAL ORNEK TABLOYA DOKULUR (06.08, Cem onayi; STANDART-ACIKLAMA
  §4 "gorsel borcu"nun guclendirilmesi): aciklamadaki sayisal mini ornek
  (orn. 12.000 TL yillik sigorta -> Ocak 1.000 gider, 11.000 TL 180'e)
  "tablo" ya da "yevmiye" alanina da dokulur. Donemsellik/degerleme/mahsup
  anlatimi sozde kalmaz - soz ucar, tablo ogretir.

  D32 - DEGERLEME TERIMI MEVZUATINA GORE (06.08, Cem onayi): VUK'a dayanan
  soruda "mukayyet deger (defterde kayitli tutar)" - VUK m.265 lafzi; TMS/TFRS
  sorusunda "defter degeri". Capraz kullanim duzeltilir (kanun alintisi
  tirnak icindeyse korunur, D26 istisnasi).

  D34 - ANALIZ TABLOSU BASLIK VE ENDEKS (06.08, Cem onayi): egilim/dikey/yatay
  analiz tablolarinda kolon basligi sinav terimi + baz bilgisi: "Egilim
  Yuzdesi (2022=100)". "Trend endeksi" duzeltilir (kitapciklarda 0 kez; egilim
  yuzdeleri 10, trend analizi 8). Endeks degeri isaretsiz rakam (133,72);
  metin yorumu endeks-100 cevirisini yapar ("%33,72 artis").

  D35 - ONCE GUNLUK DIL + SORUDAKI KELIMEYLE (06.08, Cem onayi, #12): teknik
  terim ilk gecisinde ONCE gunluk anlatim, terim sonra adlandirilir (anlam ->
  ornek -> terim; terim atilmaz, sira degisir). Bir cumlede 2+ teknik terim
  varsa cumle bolunur. Aciklama soyut kural dersi vermez; SORUDAKI gercek
  kelime/rakami isler. Yanlis sik UC ADIM: cazibe (tuzagin adi) -> sorudaki
  kelimeyle gosterim -> "Dogrusu:" tek cumle.
  KOTU: "Iyelik eki almis tamlayan ile ozneyi karistiriyor."
  IYI : "'Ogretmenin' kelimesi isi yapan degil - kimin hazirladigini soyluyor;
  begenilen sey 'sinav sorulari', ozne o. (Bu tur kelimelere tamlayan denir.)"

  D36 - FORMUL AYNASI (06.08, Cem onayi; dev platformlarda bile sistematik
  YOK - bizim farkimiz): hesap sorusunda yanlis sikkin aciklamasi uc satir:
  (1) "Bu rakami sectiysen hesabin suydu:" + YANLIS islem rakamlariyla,
  (2) hatanin adi gunluk dille, (3) dogru islem adimi. Celdirici hicbir
  mantikli isleme oturmuyorsa D14 geregi rakami tersine coz; cozulmuyorsa
  celdirici yeniden uretilir.

  D37 - ETIKET DOGRULAMA NOTU (06.08, Cem onayi #13; ornek: SGS'de jenerator
  kredi faizi sorusunun konusu 'esdeger mamul hesabi' cikti): sorunun konu
  etiketi ICERIKLE uyusmuyorsa aciklama o etikete gore YAZILMAZ - icerige
  gore yazilir ve uyusmazlik raporda isaretlenir. Etiketin kendisinin
  duzeltilmesi ayri etiket-onarim adiminin isidir (karne/koc/tuyolar bu
  etikete dayanir; yanlis etiket koçu da yaniltir).

  D38 - YASAKLI SENARYO ADI DEGISIMI (06.08, Cem onayi #14): senaryoda
  su adlar geciyorsa FARKLI adlarla degistirilir - kisi: Mehmet, Fatma,
  Hatice, Ayse, Ahmet; sirket: Yildirim, Yilmaz, Yildiz, Karadeniz, Demir,
  Demirhan (04.08 olcumu: 'Mehmet' %7,5, 'Yildirim' %8 - makine izi).
  SINIR: yalniz AD degisir; rakamlar, hukum, hesap, siklarin icerigi AYNEN
  kalir. Ad degisimi icerik degisimi SAYILMAZ (Cem onayi 06.08) - soru
  govdesinde yalniz bu amacla dokunulabilir; cinsiyet uyumu korunur
  (Bey/Hanim ekleri adla tutarli kalir).
'@ }
  # ========================================================================
  #  04.08 - HARFLERI ACIKCA SAY (Cem: "burada sadece 2 adet yanlis cevap
  #  geldi"). Bes sikli soruda dogru cevap D iken A/B/C/E'nin DORDUNE de
  #  "Dogrusu" gerekirken yalniz A ve B gelmisti.
  #  Kok sebep: istem "HER YANLIS SIK ICIN" diyordu ama HANGI harfler
  #  oldugunu SOYLEMIYORDU; model kac tane yazacagini kendi seciyordu.
  #  Artik harfler tek tek sayiliyor ve adedi yaziliyor. (Denetimi de
  #  asagida yeni kapi yapar - kural + kapi birlikte.)
  # ========================================================================
  $dogruH = "$($s.dogru)".Trim().ToUpper()
  $yanlisHarfler = @()
  foreach($h in 'A','B','C','D','E'){
    if($s.siklar -and $s.siklar.PSObject.Properties[$h] -and "$($s.siklar.$h)".Trim() -ne '' -and $h -ne $dogruH){ $yanlisHarfler += $h }
  }
  $harfListesi = ($yanlisHarfler -join ', ')
  if($i.eksik -contains 'D2_tuzak'){    $ist += 'tuzak: her YANLIS sik icin tuzagin ADINI koy — "<A> ile <B> karistiriliyor. <A> sudur; <B> ise budur." Her sik icin FARKLI tuzak; ayni cumle iki sikka yazilamaz. Basina "TUZAK:" yazma, oneki sistem koyar.' + "`n  ZORUNLU: tuzak nesnesinde SU $($yanlisHarfler.Count) HARFIN HEPSI bulunacak: $harfListesi. Eksik harf birakma." }
  # 03.08 - CEM YAKALADI: ilk pilotta dort yanlis sikka da AYNI cumle yazilmisti
  # ("Belirli sureli is sozlesmesi esasli neden olmadikca zincirleme yapilamaz").
  # Bu, D3'un kilik degistirmis hali: "bu sik yanlis cunku dogru cevap D" demenin
  # baska yolu. Ogrenciye A'nin NESI yanlis onu soylemiyor. Istem simdi her sikkin
  # KENDI IDDIASIYLA yuzlesmeyi zorunlu kiliyor ve ayni cumleyi yasakliyor.
  if($i.eksik -contains 'D2_dogrusu'){  $ist += @'
dogrusu: HER YANLIS SIK ICIN AYRI bir duzeltme. UC SEYI ANLATACAK:
  (1) YANILGININ KAYNAGI — sikkin iddiasi hangi baska kuraldan geliyor.

  !! CUMLE KALIBINI HER SIKTA DEGISTIR (03.08, Cem'in bulgusu) !!
  Ilk pilotta dort sik da "X ile karistiriliyor" diye basladi. Ust uste ayni
  acilis = MAKINE IZI; insan editor boyle yazmaz. Bir soruda ayni acilisi EN
  FAZLA BIR KEZ kullan. Digerlerinde bunlardan farkli farkli sec:
    - dogrudan konuya gir : "SPK'nin yetkisi ayrintiya iliskindir; temel kaynak..."
    - sanilan-oysa        : "Burada Maliye'nin plani akla geliyor, oysa..."
    - soru-cevap          : "Peki neden SPK degil? Cunku 88. madde..."
    - tuzagi adiyla koy   : "Klasik yetki karmasi: yayimlayan kurum ile..."
    - ogrenci sesiyle     : "Cogu aday burada uluslararasi metni isaretler;..."
  Ayni soruda dort acilisin dordu de FARKLI olacak. Ayrica "karistiriliyor"
  kelimesini bir soruda en fazla BIR kez kullanabilirsin.
  (2) O KURAL ASLINDA NEDIR — kisaca ANLAT: o kavram nerede, hangi halde gecerlidir.
      Bu parca ZORUNLU. Ogrenci "bu yanlismis" bilgisiyle kalmamali, karistirdigi
      kavrami DOGRU yerinde ogrenmeli. Yalnizca DAYANAK METNINDE gordugun kadarini
      yaz; dayanakta yoksa "bu sorunun konusu disindadir" deyip gec, UYDURMA.
  (3) BURADA NEDEN GECERSIZ — o kural bu sorunun sordugu seye neden cevap degil.

  MUGLAK IFADE YASAK (03.08, Cem'in bulgusu): "belirli sartlarda", "bazi
  hallerde", "kanunda ongorulen durumlarda", "gerekli kosullar saglandiginda",
  "mevzuatta belirtilen olculerde" gibi kaliplar bilgi VAAT EDIP VERMEZ - hic
  yazmamaktan kotudur, cunku ogrenci bir sey ogrendigini sanir.
  KURAL: bu kaliplardan birini yazacaksan SARTLARI SAY. Dayanakta varsa kisaca
  madde madde yaz; dayanakta yoksa kalibi HIC KULLANMA, yalnizca dayanakta
  YAZANI soyle.
  ORNEK: "supheli alacak belirli sartlarda ayrilir" YERINE -> "supheli alacak
  icin dort sart aranir: dava veya icra safhasinda olmasi; ya da protesto
  edilmis yahut yaziyla bir defadan fazla istenmis kucuk alacak olmasi;
  teminatsiz olmasi; ticari kazancin elde edilmesiyle ilgili olmasi."

  YASAKLAR:
  - DOGRU CEVABI TEKRAR ETMEK YASAK. "Dogrusu: <sorunun genel kurali>" yazma; bu
    "bu sik yanlis cunku dogru cevap X" demenin gizli halidir, ogretmez.
  - IKI SIKKA AYNI CUMLEYI YAZAMAZSIN. Her metin o sikka OZEL olacak.
  - Basina "Dogrusu:" YAZMA - yalniz metni ver, oneki sistem koyar.
  - EKSIK HARF BIRAKMAK YASAK. Asagida sayilan harflerin HEPSI icin metin
    yazacaksin; birini atlamak isi REDDETTIRIR.

  HESAPLI SORULARDA (siklarda rakam varsa) BUNU YAP - Cem'in 03.08 talimati:
    Her yanlis rakam BIR HATADAN dogar. O hatayi TERSINE COZ ve goster:
      "Bu rakama soyle ulasilir: <islem>. Hata: <ne yanlis yapilmis>.
       Bir daha dusmemek icin: <tek cumlelik pusula>."
    ORNEK (dogru 1.189,58 = 570.800 / 480 adet):
      B) 1.275,42 -> "1.189,58 + (41.200 / 480 = 85,83) = 1.275,42. Hata: genel
         idare giderinden mamule dusen pay da maliyete katilmis. Oysa metinde
         isletme bu payi maliyete DAHIL ETMEMEYI secmis. Bir daha dusmemek icin:
         once 'isletme neyi tercih etmis' diye bak, sonra topla."
      D) 724,63 -> "347.820 / 480 = 724,63. Hata: yalniz ham madde alinmis;
         iscilik ve genel imal giderleri unutulmus. Bir daha dusmemek icin:
         imal edilen malda maliyet UC ayaklidir, birini birakma."
    RAKAM DISIPLINI: iddia ettigin islem GERCEKTEN o rakami vermeli. Once hesapla,
    tutmuyorsa UYDURMA - "bu rakam dogru bir yontemle elde edilemez, celdiricidir"
    de ve gec. Tutmayan islem yazmak, hic yazmamaktan kotudur.

  ORNEK (soru: zincirleme is sozlesmesinin sarti nedir, dogru cevap "esasli neden"):
    ZAYIF (boyle YAZMA): "Yazili sekil sartiyla karistiriliyor; yazili sekil
      sozlesmenin kurulusuna iliskindir, zincirlemenin sarti degildir."
      -> Ogrenci yazili seklin NE oldugunu ogrenmedi. Eksik.
    IYI (boyle YAZ): "Yazili sekil sartiyla karistiriliyor. Yazili sekil, belirli
      sureli is sozlesmesinin KURULUSUNA iliskin bir sarttir ve dayanakta belirtilen
      hallerde aranir - sozlesmenin ispati ve iceriginin belirlenmesi icindir.
      Zincirleme yapilip yapilamayacagi ise ayri bir sorudur; oradaki olcut sekil
      degil, sozlesmenin yenilenmesini hakli kilan sebeptir."
      -> Ogrenci hem yanlisi hem yazili seklin gercek yerini ogrendi.
  Iki sik icin yazdigin metinler birbirinden FARKLI olacak.
'@
    # 04.08 - harfleri ACIKCA say (Cem'in "sadece 2 adet geldi" bulgusu)
    $ist += "  ZORUNLU HARF LISTESI: dogrusu nesnesinde SU $($yanlisHarfler.Count) HARFIN HEPSI bulunacak -> $harfListesi`n  (Dogru sik $dogruH'dir, ona Dogrusu YAZILMAZ. Yukaridaki harflerden biri bile eksikse cevap REDDEDILIR.)"
  }
  if($i.eksik -contains 'D7_tablo'){    $ist += @'
tablo: hesap tablosu uret. Kolonlar: kalem + deger. SON SATIR SONUCTUR (sorunun
  cevabi); ekranda o satir vurgulanacak, ona gore yaz.
  BIRIM BASLIGI DIKKAT (03.08, Cem'in bulgusu): kolon basligina "Tutar (TL)"
  yazip icine ORAN koyma. Bir tabloda hem TL hem oran/kat/adet varsa baslik
  yalnizca "Deger" olur ve birim SATIRIN kendisinde belirtilir
  ("Aktif Devir Hizi (kat)", "Ortalama Aktif (TL)"). Yanlis birim basligi
  dikkatli adayi takar. Butun satirlar ayni birimdeyse baslik "Tutar (TL)" olabilir.
  Adimlar gorunsun: verilen degerler -> ara islem -> sonuc.
  HESAP HAREKETI TABLOSU KURALI (03.08 gece, Cem: "muhasebe kaydi gibi gorunsun,
  gencler daha iyi anlar"): tablo bir hesabin (kapanis, T-hesap, "... Hesabi
  Islemleri" gibi) BORC/ALACAK hareketlerini gosteriyorsa TEK "Tutar + Isaret"
  sutunu KULLANMA. Bunun yerine GERCEK MUHASEBE KAYDI gibi UC kolon yaz:
  "Hesap" | "Borc" | "Alacak". Kalem adini KISA tut - kod + kisa hesap adi yeter
  ("600 Yurtici Satislar"), aciklama cumlesi ekleme. Tutar hangi tarafa aitse
  O kolona yazilir, diger kolon "-" ile doldurulur (bos birakma).
  ORNEK SATIRLAR: ["600 Yurtici Satislar","-","487.300"],
  ["621 Satilan Ticari Mallar Maliyeti","316.850","-"]. Son satir yine SONUC
  (hesabin bakiyesi/kapanis tutari). Bu kural yalniz borc/alacak tasiyan
  hesap tablolarina uygulanir - saf oran/hesaplama tablosunda (Aktif Devir
  Hizi gibi) eski "kalem + deger" bicimi kalir, orada Borc/Alacak yoktur.
'@ }
  if($i.eksik -contains 'D7_yevmiye'){  $ist += 'yevmiye: yevmiye fisi uret (her satir: hesap adi VE KODU, borc, alacak; borc toplami = alacak toplami).' }
  if($i.eksik -contains 'D8_karsilastirma'){ $ist += 'tablo: karsilastirma tablosu uret (ayrimi yapilan kavramlar satir satir; sorunun konusu olan satiri "<-" ile isaretle).' }
  if($i.eksik -contains 'D9_hap'){ $ist += @'
hap: KEHRIBAR KART. Sinav ekraninda cevaptan sonra beliren, adayin EZBERLEYECEGI
  kart. Aciklamanin kapanisindan (Kisacasi) FARKLI olacak: kapanis O SORUYA
  ozeldir, kart KONUNUN TAMAMINI ozetler.
  UZUNLUK: 1-3 cumle. Kisa, net, ezberlenebilir.

  !! PUF NOKTASI ZORUNLU (04.08, Cem'in talimati) !!
  Kart yalniz kavrami TEKRAR ETMEZ; adayin sinavda SANIYEDE uygulayacagi
  TANIMA IPUCUNU verir. Soruyu ele veren MEKANIK isaret varsa onu yaz:
  cumle yapisi, edat, ek, anahtar kelime, hesap yonu.
    ZAYIF (boyle YAZMA): "Sahip kim, akisa bak."
    IYI  (boyle YAZ)   : "'___ me your notes' -> fiilden hemen sonra dolayli
       nesne (me) varsa LEND. BORROW dolayli nesne almaz; o kalip 'Could I
       borrow your notes?' olurdu. Yani: nesne varsa LEND, yoksa BORROW."
    IYI  (muhasebe)    : "Pesin odendi + gelecek doneme ait -> 180/280.
       Tahakkuk etti + henuz tahsil yok -> 181/281. Once 'odendi mi tahakkuk
       mu' diye sor, sonra vadesine bak."
    IYI  (hukuk)       : "'...den itibaren' sureyi OLAY GUNUNDEN baslatir;
       '...i takip eden' bir sonraki gun/ay/yildan baslatir. Edat sureyi
       belirler."

  SINIR (uydurma taktik YASAK): ipucu GERCEK bir dilbilgisi/mevzuat/muhasebe
  kuralina dayanacak. "Sikta 'her zaman' geciyorsa yanlistir", "en uzun sik
  dogrudur" gibi SINAV OYUNU yazma - bazen tutar, tuttugunda yanlis sey
  ogretir. Ipucunu dogrulayamiyorsan kavrami duz ve dogru anlat, uydurma.
  D20: kart, Kural parcasiyla CELISEMEZ.

  D33 - MUGLAK FIIL YASAK (06.08, Cem #103: "doneme yayginlastirilir ne
  demek?"): kartin her cumlesi NET muhasebe/hukuk fiiliyle biter: gider
  yazilir, aktiflestirilir, mahsup edilir, karsilik ayrilir, iade edilir,
  beyan edilir. Turnusol: bu cumleyi okuyan aday DEFTERE HANGI KAYDI YAPAR
  soralim - cevabi yoksa cumle muglaktir, yeniden yazilir.
  KOTU: "ilgili olduklari doneme yayginlastirilir"
  IYI : "donemi geldiginde gider yazilir"
'@ }
  # --- Mevzuat disi ders (Yabanci Dil / Turkce / Matematik): dayanak metni YOK.
  #     Uydurma riski dayanak yerine YASAKLA kapatilir: hicbir kanun atfi yapamaz. ---
  if($i.mevzuatdisi){
    $kaynakKurali = @"
- Bu bir DIL/BECERI sorusudur; mevzuat dayanagi yoktur. Bu yuzden hicbir kanun,
  madde, teblig, oran veya tutar ATFI YAPAMAZSIN. Kurali dilin kendi kuralı olarak
  yaz (ornek: "Unless = if...not; olumsuz yan cumle kurar"). Emin degilsen bos birak.
"@
    $dayanakBlok = "DAYANAK: (yok - dil/beceri sorusu, kanun atfi yasak)"
  } else {
    $kaynakKurali = @"
- Yazdigin her cumle YALNIZCA asagidaki DAYANAK METNINDEN turetilecek. Dayanakta
  olmayan kanun, madde, oran, tutar veya tarih YAZAMAZSIN. Emin degilsen o alani bos birak.
"@
    $dil = DayanakDilim $i.dayanak "$($s.kaynak)"
    if(-not $dil.bulundu){ $script:maddeBulunamadi++ }
    $uyari = if($dil.bulundu){ '' } else { "(DIKKAT: etiketteki madde metinde bulunamadi - asagisi belgenin BASI. Aradigin maddeyi goremiyorsan o alani BOS BIRAK, uydurma.)`n" }
    $dayanakBlok = "DAYANAK METNI:`n" + $uyari + $dil.metin
    # KARDES MADDELER: konu kumesine giriyorsa yan hukumler de eklenir, boylece
    # "sinir cizme" (D15) gercekten yapilabilir. Hepsi ambardan okunur.
    $kardesMetin = ''
    $ara = "$($s.kaynak) $($s.konu) $($s.soru)"
    foreach($kg in $KARDES){
      if($ara -notmatch $kg.desen){ continue }
      foreach($ek in $kg.ekler){
        $mt = KardesMetin $ek.kod $ek.madde
        if($mt.Length -gt 60){ $kardesMetin += "`n--- $($ek.kod) m.$($ek.madde) ---`n$mt`n" }
      }
      break
    }
    if($kardesMetin -ne ''){
      $dayanakBlok += "`n`nBAGLANTILI MADDELER (ayni konunun diger ayaklari - sinir cizerken bunlari da kullan; yine YALNIZ burada YAZANI yaz):" + $kardesMetin
      $script:kardesEklenen++
    }
  }
@"
Sen bir SMMM sinav sorusu editorusun. ASAGIDAKI SORUYA YALNIZCA ISTENEN ALANLARI uret.

MUTLAK KURALLAR:
$kaynakKurali- "Bu sik yanlis cunku dogru cevap X" gibi cumle YASAK - ogretmez.
- Var olan dogru metni degistirme; yalnizca istenen alanlari uret.
- Ciktiyi SAF JSON ver, baska hicbir sey yazma.

DERS: $($s.ders) | KONU: $($s.konu)
KAYNAK: $($s.kaynak)

$dayanakBlok
$(if($script:THP_LISTE -ne '' -and (
     ($i.eksik -contains 'D7_yevmiye') -or ($i.eksik -contains 'D7_tablo') -or
     # 03.08 - CEM'IN 181 BULGUSU: listeyi YALNIZ tablo/yevmiye istendiginde
     # ekliyordum. Oysa hesap kodu "Dogrusu" metninde de geciyor. O soruda
     # yalniz Dogrusu istenmisti -> liste HIC gitmedi -> model yine hafizadan
     # yazdi ve "181 Diger Donen Varliklar" dedi (181 = GELIR TAHAKKUKLARI;
     # personel avansi 196). Formul vakasinin ayni hatasi: KAYNAGI YANLIS
     # KOSULA BAGLAMISIM. Artik muhasebe baglami varsa liste HER ZAMAN gider.
     ("$($s.ders) $($s.konu) $($s.soru)" -match '(?i)muhasebe|hesap|yevmiye|defter|kay[ıi]t|bilan[çc]o|gelir tablo|maliyet|stok|amortisman|avans|kar[şs][ıi]l[ıi]k|reeskont') -or
     # 03.08 GENISLETME (olcum: 842 soru bu delikten dusuyordu): yukaridaki
     # desen ders+konu+soru'ya bakar; hesap kodu SIKTA ya da ACIKLAMADA da
     # olabilir. Metinde gercek kod izi varsa liste MUTLAKA gider.
     (HesapKoduIziVar $s)
   )){ @"

=== TEKDUZEN HESAP PLANI (resmi kod listesi) ===
$($script:THP_LISTE)
=== HESAP PLANI BITTI ===
HESAP KODU KURALI: kod yazacaksan YALNIZCA bu listeden; kod-ad eslesmesi listeyle
birebir ayni olacak. Listede gormedigin kodu YAZMA - yalniz hesap adini yaz.
"@ })

SORU:
$($s.soru)

SIKLAR:
$sik
DOGRU SIK: $($s.dogru)

URETILECEK ALANLAR:
$([string]::Join("`n", ($ist | ForEach-Object { "- $_" })))

CIKTI BICIMI (yalniz istenen anahtarlari doldur):
{"dort_parca":"...","tuzak":{"A":"...","B":"..."},"dogrusu":{"A":"...","B":"..."},"tablo":{"baslik":"...","kolonlar":["..."],"satirlar":[["..."]]},"yevmiye":[{"hesap":"100 KASA","borc":0,"alacak":0}],"hap":"..."}
"@
}

# --- KURU MOD: ornek istemleri yaz, para harcama ---
if(-not $uygula){
  $sb = New-Object Text.StringBuilder
  $ornekSayi = [Math]::Min(10, $hazir.Count)
  for($n=0; $n -lt $ornekSayi; $n++){
    [void]$sb.AppendLine("=============== ORNEK $($n+1) / $ornekSayi ===============")
    [void]$sb.AppendLine("SORU ID : $($hazir[$n].soru.id)")
    [void]$sb.AppendLine("EKSIK   : $($hazir[$n].eksik -join ', ')")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine((IstemKur $hazir[$n]))
    [void]$sb.AppendLine("")
  }
  Set-Content -LiteralPath $ornekYol -Value $sb.ToString() -Encoding UTF8
  $dagilim = @{}
  foreach($i in $hazir){ foreach($e in $i.eksik){ $dagilim[$e] = 1 + $dagilim[$e] } }
  $rapor = [ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); mod='KURU (0 USD)'
    kasa=$kasa.Count; eksigi_olan=$isler.Count; islenebilir=$hazir.Count
    atlanan_dayanaksiz=$atlanan.Count
    mevzuat_disi_gecen=$dilSoru
    tahdidi_liste_yenilenen=$tahdidiYenilenen   # D11 istisnasi: sinir eksik oldugu icin Kural yeniden yazilacak
    kardes_kaynak_eklenen=$kardesEklenen        # yan hukumler de dayanaga eklendi (ara tasdik gibi)
    formul_eksik_yenilenen=$formulEksikYenilenen # yontem adi var ama Kural da formul yoktu
    eksik_dagilimi=[ordered]@{}
    atlanan_ornek=@($atlanan | Select-Object -First 20)
    not='Hicbir API cagrisi YAPILMADI. veri/onarim-motor-ornek-istem.txt icindeki 10 ornek GOZLE okunacak; Cem onaylayinca -uygula -sinir 200 ile pilot kosulur.'
  }
  foreach($k in ($dagilim.Keys | Sort-Object)){ $rapor.eksik_dagilimi[$k] = $dagilim[$k] }
  RaporYaz $rapor
  Write-Host "`n=== KURU KOSU ==="
  foreach($k in ($dagilim.Keys | Sort-Object)){ Write-Host ("  {0,-20} {1}" -f $k, $dagilim[$k]) }
  Write-Host ("`n-> {0}`n-> {1}" -f $raporYol, $ornekYol)
  Write-Host "PARA HARCANMADI. Ornek istemler gozle kontrol edilecek."
  exit 0
}

# ============================================================================
#  UYGULA — PARALI KATMAN (Cem'in 02.08 "pilot calistir 200 soru" onayiyla acildi)
#
#  BU KOSU KASAYA YAZMAZ. Sebebi: bu motorun ilk paralı koşusu. Kalitesi
#  gorulmeden 200 soruya dokunursak, kotu cikan parti kasada temizlenecek is
#  birakir. Pilot yalnizca (1) gercek faturayi olcer, (2) ciktilari dosyaya
#  yazar. Kasaya yazma ayri bir anahtarla (-yaz) ve Cem'in ikinci onayiyla olur.
#
#  CIKTI veri/fabrika/ ALTINA yazilir - orasi .gitignore'da. Parali soru icerigi
#  public depoya GIRMEZ (29-30.07 karari).
# ============================================================================
if(-not $env:ANTHROPIC_API_KEY){
  Write-Host "ANTHROPIC_API_KEY yok - parali kosu yapilamaz."
  Set-Content -LiteralPath $raporYol -Encoding UTF8 -NoNewline -Value (ConvertTo-Json -Depth 3 -InputObject ([ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); mod='PILOT - ANAHTAR YOK'; durum='KIRMIZI'
    not='ANTHROPIC_API_KEY sirri tanimli degil; hicbir cagri yapilmadi, para harcanmadi.' }))
  exit 1
}
$MODEL = 'claude-haiku-4-5-20251001'
# Fiyat: 1 USD / M giris token, 5 USD / M cikis token (Haiku 4.5 liste fiyati).
# Token sayilari OLCUMDUR (API'nin usage alani); USD bu iki katsayiyla turetilir.
$FIY_IN = 1.0 / 1000000.0
$FIY_OUT = 5.0 / 1000000.0

# --- CIKTI NEREYE GIDIYOR ---
# 03.08 dersi: ilk pilotta ciktilar veri/fabrika altina yazildi. Orasi .gitignore'da
# (dogru), ama kosucu makine gecici - dosya commit edilmeyince MAKINEYLE BIRLIKTE
# SILINDI. 0,78 USD odendi, maliyet olculdu, 200 cikti kayboldu.
# Artik ciktilar SUPABASE'e (soru_onarim_taslak) yazilir: ozel, kalici, gozle
# okunabilir. Depoya ve artifact'a HICBIR icerik gitmez.
$etiketAdi = "pilot-$(Get-Date -Format 'ddMM-HHmm')"

# ============================================================================
#  UCUS ONCESI: TASLAK DEPOSU HAZIR MI?  (Cem'e is cikarmayan yol)
#
#  Tablo yaratmak DDL ister; DDL'i yalnizca Cem panelden calistirabilir.
#  Ama ayni ihtiyaci Supabase STORAGE karsiliyor ve kova yaratmak SERVIS
#  ANAHTARIYLA yapilabilir - yani robot kendi kuruyor, Cem'in eli degmiyor.
#
#  KOVA OZEL OLACAK. 17.07 denetiminde "fisler" kovasi public bulunmustu;
#  ayni hata burada tekrarlanmaz: public=false ile yaratilir VE yaratildiktan
#  sonra geri okunup public olmadigi DOGRULANIR. Ozel degilse pilot BASLAMAZ.
# ============================================================================
$KOVA = 'onarim-taslak'
$STOR = "https://bjrleanjpyujtajmazxn.supabase.co/storage/v1"
$SK   = @{ apikey=$env:SUPABASE_SERVICE_KEY; Authorization="Bearer $($env:SUPABASE_SERVICE_KEY)" }
function KovaDurum {
  try {
    $h = Invoke-WebRequest -Uri "$STOR/bucket/$KOVA" -Headers $SK -UseBasicParsing -TimeoutSec 60
    $m = if($h.RawContentStream){ [Text.Encoding]::UTF8.GetString($h.RawContentStream.ToArray()) } else { "$($h.Content)" }
    return ($m | ConvertFrom-Json)
  } catch { return $null }
}
$kv = KovaDurum
if($null -eq $kv){
  Write-Host "Taslak kovasi yok - OZEL olarak yaratiliyor..."
  $kgovde = ConvertTo-Json -Compress -InputObject @{ id=$KOVA; name=$KOVA; public=$false }
  try {
    Invoke-RestMethod -Uri "$STOR/bucket" -Method Post -Headers ($SK + @{ 'Content-Type'='application/json' }) -Body ([Text.Encoding]::UTF8.GetBytes($kgovde)) -TimeoutSec 60 | Out-Null
  } catch {
    $g=''; if($_.ErrorDetails -and $_.ErrorDetails.Message){ $g=$_.ErrorDetails.Message }
    Write-Host "!! KOVA YARATILAMADI - pilot BASLATILMADI, para harcanmadi."
    Set-Content -LiteralPath $raporYol -Encoding UTF8 -NoNewline -Value (ConvertTo-Json -Depth 3 -InputObject ([ordered]@{
      tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); mod='PILOT BASLATILMADI'; durum='KIRMIZI'; maliyet_usd=0
      sebep='taslak kovasi yaratilamadi'; sunucu=$g
      not='Hicbir API cagrisi yapilmadi. Ciktinin kaybolacagi kosuya para verilmez.' }))
    exit 1
  }
  $kv = KovaDurum
}
if($null -eq $kv -or $kv.public -eq $true){
  Write-Host "!! KOVA OZEL DEGIL (veya okunamadi) - pilot BASLATILMADI, para harcanmadi."
  Set-Content -LiteralPath $raporYol -Encoding UTF8 -NoNewline -Value (ConvertTo-Json -Depth 3 -InputObject ([ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); mod='PILOT BASLATILMADI'; durum='KIRMIZI'; maliyet_usd=0
    sebep='taslak kovasi PUBLIC gorundu - parali icerik acik yere yazilamaz (17.07 fisler-bucket dersi)'
    not='Hicbir API cagrisi yapilmadi.' }))
  exit 1
}
Write-Host ("Ucus oncesi: taslak kovasi hazir ve OZEL (public={0})." -f $kv.public)

# --- DENEME YAZMASI: kovaya gercekten yazabiliyor muyuz? ---
# 03.08 dersi: iki kosuda da 200 cagri YAPILDI, para gitti, sonra yazma bozuk
# cikti ve ciktilar kayboldu. Artik yazma yetenegi TEK KURUS harcanmadan
# denenir. Deneme dosyasi yazilip geri okunamiyorsa pilot BASLAMAZ.
try {
  $dGovde = ConvertTo-Json -Compress -InputObject @{ deneme=$true; etiket=$etiketAdi }
  Invoke-RestMethod -Uri "$STOR/object/$KOVA/_deneme.json" -Method Post `
    -Headers ($SK + @{ 'Content-Type'='application/json'; 'x-upsert'='true' }) `
    -Body ([Text.Encoding]::UTF8.GetBytes($dGovde)) -TimeoutSec 60 | Out-Null
  $dh = Invoke-WebRequest -Uri "$STOR/object/$KOVA/_deneme.json" -Headers $SK -UseBasicParsing -TimeoutSec 60
  $dm = if($dh.RawContentStream){ [Text.Encoding]::UTF8.GetString($dh.RawContentStream.ToArray()) } else { "$($dh.Content)" }
  if(($dm | ConvertFrom-Json).etiket -ne $etiketAdi){ throw "geri okunan icerik yazilanla ayni degil" }
  Write-Host "Ucus oncesi: kovaya yazma DENENDI ve dogrulandi."
} catch {
  $g=''; if($_.ErrorDetails -and $_.ErrorDetails.Message){ $g=$_.ErrorDetails.Message }
  Write-Host "!! KOVAYA YAZILAMIYOR - pilot BASLATILMADI, para harcanmadi."
  RaporYaz ([ordered]@{
    tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); mod='PILOT BASLATILMADI'; durum='KIRMIZI'; maliyet_usd=0
    sebep='taslak kovasina deneme yazmasi basarisiz'; hata="$($_.Exception.Message)"; sunucu=$g
    not='Hicbir API cagrisi yapilmadi. Ciktinin kaybolacagi kosuya para verilmez (03.08 dersi: iki kez oldu).' })
  exit 1
}

$AH = @{ 'x-api-key'=$env:ANTHROPIC_API_KEY; 'anthropic-version'='2023-06-01'; 'content-type'='application/json' }
$sonuc = New-Object System.Collections.Generic.List[object]
$tIn=0; $tOut=0; $basarili=0; $bozukJson=0; $hataliCagri=0; $tekrarKusurlu=0
$tekrarDenenen=0; $kesilen=0
$islenmeyen = New-Object System.Collections.Generic.List[object]
$dayanakDisiSoru=0; $dayanakDisiIddia=0; $maddeBulunamadi=0
$istenmeyenAlan=0; $dortParcaEksik=0; $kanunKopyasi=0; $yzKokusu=0; $tekduzeKusurlu=0
$muglakIfade=0
$parti = @($hazir | Select-Object -First $(if($sinir -gt 0){$sinir}else{$hazir.Count}))
Write-Host ("PILOT basliyor: {0} soru | model {1}" -f $parti.Count, $MODEL)

for($n=0; $n -lt $parti.Count; $n++){
  $i = $parti[$n]
  $istem = IstemKur $i
  # ========================================================================
  #  KESILME VE TEKRAR DENEME — 03.08, Cem "Model gecerli JSON uretemedi"
  #  kartini gordu.
  #
  #  Kok sebep bendim: max_tokens=1500 idi. Dort parca + dort tuzak + dort
  #  "Dogrusu" + tablo yazilinca cikti sinira dayaniyor ve JSON ORTASINDA
  #  KESILIYOR. Model hata yapmiyor, ben yerini dar birakmisim.
  #  (Teshis: stop_reason='max_tokens' ise kesilmedir, model kusuru degil.)
  #
  #  Ayrica o soru SESSIZCE kayboluyordu. Artik: bir kez daha denenir; yine
  #  olmazsa ID'si rapora yazilir - "islenmedi" bilinerek kalir.
  # ========================================================================
  # ========================================================================
  #  04.08 - UCUNCU DENEME EKLENDI (Cem: "yine boyle hata almaya devam
  #  ediyoruz" - taslakta "Model gecerli JSON uretemedi" karti gordu)
  #
  #  Iki kusur vardi:
  #   1) IKINCI DENEME CELISKILIYDI: tavani 6000'e cikariyor AMA ayni anda
  #      "daha kisa yaz" diyordu. Icerik gercekten uzunsa bu ikisi kavga eder;
  #      model kisaltmaya calisirken yine kesiliyordu.
  #   2) UCUNCU SANS YOKTU: iki denemede olmazsa soru islenmeden kaliyordu.
  #      200'de 1 (%0,5) -> tam kasada ~137 soru demek.
  #
  #  YENI DUZEN:
  #   1. deneme: 4000, normal istem
  #   2. deneme: 8000, "KISALTMA - sadece kapali JSON dondur" (celiski yok,
  #      yer aciyoruz, kisaltma istemiyoruz)
  #   3. deneme: 8000, KAPSAM KUCULTULUR - hacimli tablo/yevmiye ISTENMEZ.
  #      Gerekce: eksik aciklama, hic aciklamadan iyidir. Tablo bir sonraki
  #      kosuda tamamlanabilir; sorunun tamamen islenmemesi ise kayiptir.
  # ========================================================================
  $obj = $null; $temiz = ''; $kesildi = $false
  for($deneme = 1; $deneme -le 3; $deneme++){
    $tavan = if($deneme -eq 1){ 4000 } else { 8000 }
    $istemBu = switch($deneme){
      1 { $istem }
      2 { $istem + "`n`nUYARI: onceki cevabin GECERLI JSON DEGILDI - buyuk ihtimalle uzunlugundan kesildi. Bu kez YER ACILDI; icerigi kisaltmana gerek yok, YALNIZ kapali ve gecerli TEK bir JSON nesnesi dondur. JSON disinda hicbir sey yazma." }
      3 { ($istem -replace '(?m)^- tablo:.*$','' -replace '(?m)^- yevmiye:.*$','') + "`n`nUYARI: iki kez gecerli JSON alinamadi. Bu kez TABLO VE YEVMIYE URETME - yalniz metin alanlarini (dort_parca/tuzak/dogrusu) yaz. Kisa tut ve MUTLAKA kapali, gecerli tek bir JSON nesnesi dondur." }
    }
    $govde = ConvertTo-Json -Depth 5 -Compress -InputObject @{
      model=$MODEL; max_tokens=$tavan
      messages=@(@{ role='user'; content=$istemBu })
    }
    try {
      $c = Invoke-RestMethod -Uri 'https://api.anthropic.com/v1/messages' -Method Post -Headers $AH `
           -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 180
    } catch {
      if($deneme -eq 3){ $hataliCagri++; Write-Host ("  [{0}] CAGRI HATASI: {1}" -f ($n+1), $_.Exception.Message) }
      continue
    }
    $tIn += [int]$c.usage.input_tokens; $tOut += [int]$c.usage.output_tokens
    if("$($c.stop_reason)" -eq 'max_tokens'){ $kesildi = $true }
    $metin = ''
    foreach($p in @($c.content)){ if($p.type -eq 'text'){ $metin += "$($p.text)" } }
    $temiz = ($metin -replace '(?s)^\s*```(?:json)?\s*','' -replace '(?s)\s*```\s*$','').Trim()
    try { $obj = $temiz | ConvertFrom-Json } catch { $obj = $null }

    # ======================================================================
    #  EKSIK HARF KAPISI (04.08, Cem: "burada sadece 2 adet yanlis cevap
    #  geldi") — bes sikli soruda dogru cevap D iken A/B/C/E'nin dordune de
    #  Dogrusu gerekirken yalniz A ve B gelmisti.
    #
    #  KUSUR: JSON GECERLIYDI, o yuzden hicbir sey yakalamadi - kod "basarili"
    #  sayip devam etti. Bu gecenin tekrarlayan deseni: KURAL ISTEMDE VAR AMA
    #  KAPI YOK. Artik uretilen dogrusu/tuzak nesnesinde beklenen harflerin
    #  hepsi var mi diye BAKILIR; eksikse ayni cagri dongusunde EKSIK HARFLER
    #  ADIYLA ISTENIR. Uc denemede de tamamlanmazsa eksik oldugu RAPORLANIR
    #  (sessiz kayip yok).
    # ======================================================================
    # ======================================================================
    #  D27 — ISTENEN ALAN GELMEDIYSE IS BITMEMISTIR (04.08, Cem: "sen kural
    #  koy hepsine, bundan bir daha cikmasin")
    #
    #  Taslak denetimi (200 soru) tek ornegin istisna OLMADIGINI gosterdi:
    #    Dogrusu : 199 istendi, 70 SORUDA EKSIK (204 harf) - tamlik %64,8
    #    Tablo   : 97 istendi, 69 geldi
    #    Yevmiye : 27 istendi, 13 geldi
    #    Tuzak   : 40 istendi, 40 geldi (%100)
    #  Yani kapi yalniz dogrusu/tuzak'a konsaydi tablo ve yevmiye acikta
    #  kalirdi. ARTIK KAPI ISTENEN HER ALANI DENETLER - biri eksikse cevap
    #  kabul edilmez, EKSIGIN ADI SOYLENEREK yeniden istenir.
    # ======================================================================
    $eksikHarf = @()
    if($null -ne $obj){
      # 1) dogrusu / tuzak: yanlis siklarin HEPSI dolu olmali
      foreach($alanAdi in @('dogrusu','tuzak')){
        if(-not ($i.eksik -contains "D2_$alanAdi")){ continue }
        $v = $null; try { if($obj.PSObject.Properties[$alanAdi]){ $v = $obj.$alanAdi } } catch {}
        foreach($h in $i.yanlisHarfler){
          $m2 = ''
          try { if($null -ne $v -and $v.PSObject.Properties[$h]){ $m2 = "$($v.$h)" } } catch {}
          if($m2.Trim().Length -lt 15){ $eksikHarf += "$alanAdi.$h" }
        }
      }
      # 2) dort_parca: gelmeli VE dort baslik tam olmali (motorun tespit
      #    asamasinda kullandigi AYNI desenler - o desenler gercek veride
      #    calistigi kanitli: 200 sorunun 176'sinda dort parcayi dogru buldu)
      if($i.eksik -contains 'D1_dort_parca'){
        $d4 = ''; try { if($obj.PSObject.Properties['dort_parca']){ $d4 = "$($obj.dort_parca)" } } catch {}
        if($d4.Trim().Length -lt 30){ $eksikHarf += 'dort_parca' }
        else {
          if(-not $reNe.IsMatch($d4)){    $eksikHarf += 'dort_parca:"Ne soruluyor:" basligi' }
          if(-not $reKural.IsMatch($d4)){ $eksikHarf += 'dort_parca:"Kural:" basligi' }
          if(-not $reOlay.IsMatch($d4)){  $eksikHarf += 'dort_parca:"Bu olayda:" basligi' }
          if(-not $reAkil.IsMatch($d4)){  $eksikHarf += 'dort_parca:"Akilda kalsin:" basligi' }
        }
      }
      # 3) tablo: istenmisse satirli gelmeli
      #    NOT: 3. denemede tablo/yevmiye BILEREK istenmiyor (kapsam kucultme,
      #    kesilmeye karsi). Istemedigimiz seyi eksik saymak kendi kendimizle
      #    celismek olurdu - o yuzden yalniz 1-2. denemede denetlenir.
      if($deneme -lt 3 -and (($i.eksik -contains 'D7_tablo') -or ($i.eksik -contains 'D8_karsilastirma'))){
        $tOk = $false
        try { if($obj.PSObject.Properties['tablo'] -and $null -ne $obj.tablo -and @($obj.tablo.satirlar).Count -gt 0){ $tOk = $true } } catch {}
        if(-not $tOk){ $eksikHarf += 'tablo' }
      }
      # 3b) hap (kehribar kart): istenmisse gelmeli ve ezberlenebilir uzunlukta
      #     olmali. Tek kelimelik/bos kart ise gelmemis sayilir.
      if($i.eksik -contains 'D9_hap'){
        $hh = ''; try { if($obj.PSObject.Properties['hap']){ $hh = "$($obj.hap)" } } catch {}
        if($hh.Trim().Length -lt 25){ $eksikHarf += 'hap' }
      }
      # 4) yevmiye: istenmisse satirli gelmeli (3. denemede istenmiyor - yukari bak)
      if($deneme -lt 3 -and ($i.eksik -contains 'D7_yevmiye')){
        $yOk = $false
        try { if($obj.PSObject.Properties['yevmiye'] -and @($obj.yevmiye).Count -gt 0){ $yOk = $true } } catch {}
        if(-not $yOk){ $eksikHarf += 'yevmiye' }
      }
    }
    if($null -ne $obj -and $eksikHarf.Count -eq 0){ break }
    if($null -ne $obj -and $eksikHarf.Count -gt 0 -and $deneme -lt 3){
      $script:eksikHarfTekrar++
      Write-Host ("  [{0}] EKSIK ALAN ({1}) - {2}. deneme" -f ($n+1), ($eksikHarf -join ','), ($deneme+1))
      $istem = $istem + "`n`nUYARI: onceki cevabinda SU ALANLAR EKSIK ya da cok kisaydi: " + ($eksikHarf -join ', ') + ".`nBu kez HEPSINI eksiksiz doldur. Her metin en az bir tam cumle olsun. Dort parca istendiyse DORT BASLIK da birebir bu adlarla bulunsun: 'Ne soruluyor:', 'Kural:', 'Bu olayda:', 'Akilda kalsin:'."
      $obj = $null
      continue
    }
    if($null -ne $obj -and $eksikHarf.Count -gt 0){
      $script:eksikHarfKalan++   # uc denemede de tamamlanmadi - RAPORLANIR
      break
    }
    if($deneme -lt 3){ $tekrarDenenen++; Write-Host ("  [{0}] JSON bozuk (kesildi={1}) - {2}. deneme" -f ($n+1), $kesildi, ($deneme+1)) }
  }
  if($null -eq $obj){
    $bozukJson++
    $islenmeyen.Add([ordered]@{ id="$($i.soru.id)"; sebep=$(if($kesildi){'cikti kesildi (max_tokens)'}else{'gecerli JSON uretilemedi'}) })
  } else { $basarili++ }
  if($kesildi){ $kesilen++ }

  # ========================================================================
  #  ISTENMEYENI AT — 03.08, Cem'in ikinci bulgusu.
  #
  #  Cem iyi yazilmis bir aciklamanin yanina modelin yazdigi TEK PARAGRAFLIK
  #  hukuk metnini gordu ve "eski cevap daha iyi" dedi. Haklyidi. Sebep: o
  #  soruda dort_parca ISTENMEMISTI (eski metinde zaten vardi, dedektor de
  #  dogru buluyor) - model kendiliginden yazdi.
  #
  #  Parali kosuda bu FELAKET olurdu: iyi yazilmis aciklamalar istenmeden
  #  yenisiyle ezilirdi. Artik istenmeyen her alan CIKARILIR. Motor yalniz
  #  BOS OLANI doldurur, dolu olana dokunmaz.
  # ========================================================================
  $atilanAlan = 0
  if($null -ne $obj){
    $izin = @{}
    if($i.eksik -contains 'D1_dort_parca'){ $izin['dort_parca'] = 1 }
    if($i.eksik -contains 'D2_tuzak'){      $izin['tuzak'] = 1 }
    if($i.eksik -contains 'D2_dogrusu'){    $izin['dogrusu'] = 1 }
    if(($i.eksik -contains 'D7_tablo') -or ($i.eksik -contains 'D8_karsilastirma')){ $izin['tablo'] = 1 }
    if($i.eksik -contains 'D7_yevmiye'){    $izin['yevmiye'] = 1 }
    if($i.eksik -contains 'D9_hap'){        $izin['hap'] = 1 }   # 04.08: kehribar kart kapsama girdi
    foreach($p in @($obj.PSObject.Properties.Name)){
      if(-not $izin.ContainsKey($p)){
        try { $obj.PSObject.Properties.Remove($p); $atilanAlan++ } catch {}
      }
    }
  }
  $istenmeyenAlan += $atilanAlan

  # ========================================================================
  #  HESAP KODU OTOMATIK DUZELTME (03.08, Cem onayi)
  #
  #  OLCUM SUNU GOSTERDI: model 230 kodluk TAM listeyi elinde tutarken bile
  #  59 kez yanlis eslestirme yapti. Yani LISTE VERMEK YETMIYOR - modele
  #  guvenmek yerine cikti DUZELTILIR. Deterministik, bedava, kesin.
  #
  #  MANTIK - ve siniri:
  #   * Yazilan AD, resmi listede TEK BIR hesapla eslesiyorsa: KOD o hesabin
  #     kodu yapilir ve ad resmi yazimina cevrilir.
  #     "253 Personel Avanslari" -> "196 PERSONEL AVANSLARI"  (ad tek eslesiyor)
  #   * Ad HICBIRIYLE ya da BIRDEN FAZLASIYLA eslesiyorsa DOKUNULMAZ, yalniz
  #     supheli sayilir. Belirsizken duzeltmek, yanlisi baska yanlisla
  #     degistirmektir - bugun tam bunu yapmamak icin ugrastik.
  # ========================================================================
  if($null -ne $obj -and $script:THP_AD.Count -gt 50){
    function ResmiKodBul([string]$adMetni){
      $bulunan = @()
      foreach($kk in $script:THP_AD.Keys){
        $a = AnlamliKelimeler $adMetni
        $b = AnlamliKelimeler $script:THP_AD[$kk]
        if($a.Count -eq 0 -or $b.Count -eq 0){ continue }
        # TAM eslesme ariyoruz: yazilan adin TUM anlamli kelimeleri resmi adda olmali
        $hepsiVar = $true
        foreach($x in $a){
          $var = $false
          foreach($y in $b){ if($x.StartsWith($y) -or $y.StartsWith($x)){ $var = $true; break } }
          if(-not $var){ $hepsiVar = $false; break }
        }
        if($hepsiVar){ $bulunan += $kk }
      }
      return $bulunan
    }
    # 04.08 - BIRIM TUZAGI BURAYA DA KONDU. Eski desen "750 TL"yi hesap kodu
    # sayiyordu (750 THP'de var: ARASTIRMA VE GELISTIRME GIDERLERI). Bugune
    # kadar zarari yoktu cunku belirsiz kalinca DOKUNULMUYORDU; ama artik
    # belirsiz kod SILINIYOR - o yuzden "750 TL" -> "TL" olurdu. Once tuzak
    # kapatildi, sonra silme eklendi.
    # ========================================================================
    #  04.08 REGRESYON VE DUZELTMESI — "690 Hesabinda" VAKASI
    #
    #  Birim tuzagini kapatirken desenin sonuna \b ekledim. Bu, ONEK olarak
    #  calismasi gereken baglayicilari BOZDU: "hesab" + \b, "Hesabinda"
    #  icinde eslesmiyor (b'den sonra harf var, sinir yok) -> eleme calismadi
    #  -> "Hesabinda" hesap ADI sanildi -> 690/691/692/151 gibi DOGRU kodlar
    #  SILINDI. Pilot 0408-0835'te 27 dogru kod boyle silindi ve sayac
    #  "yanlis 63->27 dustu" diye YANLIS BIR IYILESME gosterdi.
    #
    #  Ders: \b'yi topluca eklemek serbest degil. Baglayici kelimeler
    #  (hesab/hesap/numaral/sayil...) ONEK olarak elenir - Turkce ekler
    #  yuzunden ("hesabinda", "numarali", "sayili") sinir aranmaz.
    #  Yalniz "ay" gibi KISA ve baska kelimelerin basi olabilecekler \b ister
    #  (yoksa "ayrica", "ayni" da elenirdi).
    # ========================================================================
    $reCift = [regex]'(?<![\d.,])\b([1-8]\d{2})(?!\d)\s*[-–—]?\s*(?!(?:numaral|no\.?lu|say[ıi]l|adet|kalem|tane|hesab|hesap|kodlu|nolu|TL|USD|EUR|LIRA|L[İI]RA|ki[şs]i|g[üu]n|y[ıi]l|saat|kg|ton|puan|kuru[şs]|taksit)|(?:ay|adet)\b)([A-Za-zÇĞİÖŞÜçğıöşü][A-Za-zÇĞİÖŞÜçğıöşü\.]*(?:\s+[A-Za-zÇĞİÖŞÜçğıöşü\.]+){0,4})'
    # Yazilan ad HERHANGI bir resmi hesap adina benziyor mu? (hesap-kodu-denetimi
    # ile ayni "beyaz liste" mantigi: benzemiyorsa o zaten hesap adi degildir,
    # dokunulmaz - "paragraf"/"veya" gibi kelimelerin kodu silinmesin.)
    # 04.08 IKINCI SAVUNMA KATMANI ("690 Hesabinda" dersi): TEK kelimelik ve
    # genel bir ifade ASLA hesap adi sayilmaz. Eski hali tek kelimeyle bile
    # "true" donuyordu - "HESABINDA", THP'deki "...YANSITMA HESABI" adinin
    # "HESABI" kelimesine onek uydugu icin hesap adi sanildi ve DOGRU kod
    # silindi. Artik EN AZ IKI anlamli kelimenin ayni resmi adda eslesmesi
    # gerekir; boylece "Hesabinda", "tutarinin", "kaydedilir" gibi tasiyici
    # kelimeler tek basina silme tetikleyemez.
    $script:TASIYICI = @('HESAB','HESAP','TUTAR','KAYIT','KAYDED','ALACAG','BORCU','BORCA','ISLEM','DONEM','TOPLAM','BAKIYE')
    function HesapAdiIddiasiMi([string]$ad){
      $a = @(AnlamliKelimeler $ad)
      if($a.Count -eq 0){ return $false }
      # Tasiyici (genel muhasebe dili) kelimeleri sayimdan dusur
      $ozgun = @($a | Where-Object { $w = $_; -not ($script:TASIYICI | Where-Object { $w.StartsWith($_) }) })
      if($ozgun.Count -lt 2){ return $false }
      foreach($kk in $script:THP_AD.Keys){
        $b = @(AnlamliKelimeler $script:THP_AD[$kk])
        if($b.Count -eq 0){ continue }
        $eslesen = 0
        foreach($x in $ozgun){
          foreach($y in $b){ if($x.StartsWith($y) -or $y.StartsWith($x)){ $eslesen++; break } }
        }
        if($eslesen -ge 2){ return $true }   # en az IKI ozgun kelime ayni hesapta
      }
      return $false
    }
    function KoduDuzelt([string]$metin){
      if($metin -eq ''){ return $metin }
      return $reCift.Replace($metin, {
        param($m)
        $k = $m.Groups[1].Value; $a = $m.Groups[2].Value.Trim()
        if($a.Length -lt 4){ return $m.Value }
        if(-not $script:THP_AD.ContainsKey($k)){ return $m.Value }
        # Zaten dogruysa dokunma
        $x = AnlamliKelimeler $a
        $y = AnlamliKelimeler $script:THP_AD[$k]
        foreach($p in $x){ foreach($q in $y){ if($p.StartsWith($q) -or $q.StartsWith($p)){ return $m.Value } } }
        # 03.08 gece dersi: ResmiKodBul TEK eslesme donunce PowerShell donusu
        # skaler string'e "unwrap" ediyordu - $aday[0] o zaman dizinin ilk
        # elemanini degil, STRING'IN ILK KARAKTERINI veriyordu ("159" -> "1").
        # Bu YUZDEN hesap_kodu_duzeltilen hep ~0 cikiyordu VE tek cikan "1"
        # duzeltme de cop veriydi ("1 " yazilmis olmali). @() cagri noktasinda
        # sarip diziligi garanti eder.
        # ==================================================================
        #  ACGOZLU YAKALAMA DUZELTMESI (04.08) — D14-ek'in NEDEN HEP 0
        #  VERDIGININ KOK SEBEBI
        #
        #  $reCift hesap adini BES KELIMEYE KADAR yakaliyor:
        #    "253 Personel Avanslari hesabina borc kaydedilir"
        #  -> ad = "Personel Avanslari hesabina borc kaydedilir"
        #  ResmiKodBul bu bes kelimenin HEPSININ resmi adda gecmesini
        #  istedigi icin HICBIR ZAMAN eslesme bulamiyordu. Dort pilotta
        #  duzeltilen 0/1/2/0 cikmasinin sebebi buydu - motor bozuk degildi,
        #  aday adi cop kelimelerle uzuyordu.
        #
        #  Cozum: UZUNDAN KISAYA prefix dene. Ilk anlamli n kelimeyle TEK
        #  eslesme bulunursa o kullanilir. Iki kelimenin altina INILMEZ -
        #  tek kelime ("Personel") onlarca hesaba uyar, tahmin olur.
        # ==================================================================
        $kelimeler = @($a -split '\s+' | Where-Object { $_ -ne '' })
        $aday = @()
        $eslesenAd = $a
        for($n = [Math]::Min(5, $kelimeler.Count); $n -ge 2; $n--){
          $parcaAd = ($kelimeler[0..($n-1)] -join ' ')
          $bul = @(ResmiKodBul $parcaAd)
          if($bul.Count -eq 1){ $aday = $bul; $eslesenAd = $parcaAd; break }
        }
        if($aday.Count -eq 1){
          $yeniKod = "$($aday[0])"
          # ==================================================================
          #  KENDI CIKTISINI DENETLE (03.08 gece, unwrap bug'inin dersi)
          #
          #  Unwrap bug'i "159" yerine "1" uretiyordu ve HICBIR KAPI bunu
          #  yakalamadi - sayac "1 duzeltme yapildi" diyordu, icerik copdu.
          #  Sayac ARTIK YETMEZ: uretilen kod GERCEKTEN 3 haneli ve THP'de
          #  var mi diye burada denetlenir. Degilse duzeltme YAPILMAZ ve
          #  ayrica sayilir - bir dahaki sefere sessizce gecemez.
          # ==================================================================
          if($yeniKod -notmatch '^[1-8]\d{2}$' -or -not $script:THP_AD.ContainsKey($yeniKod)){
            $script:hesapKoduGecersizUretim++
            return $m.Value
          }
          $script:hesapKoduDuzeltilen++
          # CUMLENIN DEVAMI KORUNUR: eslesme yalniz ADIN ilk n kelimesiyle
          # kuruldu; geri kalan ("hesabina borc kaydedilir") aynen birakilir.
          # Yoksa duzeltme cumleyi kirpardi - bu, duzeltmeden BETER olurdu.
          $kalan = ''
          if($kelimeler.Count -gt ($eslesenAd -split '\s+').Count){
            $kalan = ' ' + (($kelimeler[(($eslesenAd -split '\s+').Count)..($kelimeler.Count-1)]) -join ' ')
          }
          # Rapora ORNEK: yalniz THP kod-ad cifti (herkese acik veri), soru
          # metni DEGIL - boylece "ilk on ornegi gozle oku" kurali sayaca
          # degil ICERIGE uygulanabilir. En fazla 10 tane, rapor kucuk kalsin.
          if($script:hesapKoduOrnek.Count -lt 10){
            $script:hesapKoduOrnek.Add([ordered]@{ yazilan="$k $eslesenAd"; duzeltilen="$yeniKod $($script:THP_AD[$yeniKod])" })
          }
          return ($yeniKod + ' ' + $script:THP_AD[$yeniKod] + $kalan)
        }
        # ==================================================================
        #  BELIRSIZ KOD SILINIR (04.08, Cem: "bunu duzeltelim o zaman")
        #
        #  Dort pilotun dersi: otomatik DUZELTME neredeyse hic tetiklenmiyor
        #  (0/1/2/0) cunku yazilan ad cogu zaman TEK bir hesaba karsilik
        #  gelmiyor ("Ortaklardan Alacaklar" hem 131 hem 231). Eski davranis
        #  belirsizken YANLIS KODU OLDUGU GIBI BIRAKMAKTI - hesap_kodu_yanlis
        #  63'e ciktigi halde hicbiri onarilmiyordu.
        #
        #  Dogru cozum "daha cok tahmin" degil: KODU SIL, ADI BIRAK.
        #  "181 Diger Donen Varliklar" -> "Diger Donen Varliklar"
        #  Cunku: (a) yanlis kod ogrenciye YANLIS OGRETIR, ad tek basina
        #  dogrudur; (b) istem zaten "Listede gormedigin kodu YAZMA - yalniz
        #  hesap adini yaz" diyor, bu onun deterministik uygulamasidir;
        #  (c) tahmin yok, uydurma yok - bilgi kaybi minimum.
        #
        #  SINIR: yalnizca ad GERCEKTEN bir hesap adina benziyorsa silinir.
        #  Benzemiyorsa ("620 paragrafinda", "400 veya") dokunulmaz - bu
        #  gece sekiz kez yandigimiz sahte alarm sinifi.
        # ==================================================================
        # ==================================================================
        #  SILME KAPATILDI (04.08, Cem'in karari: "kapat")
        #
        #  Silme fikri dogruydu (yanlis kod ogrenciye yanlis ogretir) ama
        #  UYGULAMASI tutmadi: prose icinde "kod + hesap adi" cifti ile
        #  "kod + cumlenin devami" ayrimi regex ile guvenilir yapilamiyor.
        #  BU GECE UC YANLIS-POZITIF SINIFI YASANDI:
        #    1) birim tuzagi   : "750 TL" kod sanildi
        #    2) \b regresyonu  : "690 Hesabinda" -> 27 DOGRU kod silindi
        #    3) baglac tuzagi  : "102 ise bu varliklarin deger dusuklugu"
        #  Her duzeltme yenisini dogurdu. Ayrica ALTI pilottur
        #  hesap_kodu_duzeltilen = 0: ozellik fayda uretmiyor, risk uretiyor.
        #
        #  OGRENCIYI ZATEN IKI KATMAN KORUYOR:
        #   - yayin-kapisi.ps1 K4: kod-ad uyusmayan soru YAYINA CIKAMAZ
        #   - sik-hesap-kodu-uygula.ps1: kasadaki gercek temizlik (105 soru,
        #     105/105 geri okuma dogrulandi, yedekli ve geri alinabilir)
        #
        #  Sayaclar ve ornekler KALIYOR (olcum degerli, kor kalmayalim) ama
        #  METNE DOKUNULMUYOR. Yeniden acmak icin: asagidaki $SILME_ACIK'i
        #  $true yap - ama once yanlis-pozitif sinifini coz, yoksa dorduncusu
        #  gelir.
        # ==================================================================
        if(HesapAdiIddiasiMi $a){
          $script:hesapKoduSilmeAdayi++
          if($script:hesapKoduOrnek.Count -lt 10){
            $script:hesapKoduOrnek.Add([ordered]@{ yazilan="$k $a"; oneri="(silme ADAYI - uygulanmadi)"; })
          }
          return $m.Value          # <-- METNE DOKUNULMUYOR
        }
        $script:hesapKoduSupheli++
        return $m.Value
      })
    }
    foreach($alan in 'dort_parca','tuzak','dogrusu'){
      try {
        if(-not $obj.PSObject.Properties[$alan]){ continue }
        $v = $obj.$alan
        if($v -is [string]){ $obj.$alan = KoduDuzelt $v; continue }
        foreach($h in 'A','B','C','D','E'){
          if($v.PSObject.Properties[$h]){ $v.$h = KoduDuzelt "$($v.$h)" }
        }
      } catch {}
    }
  }

  # --- TEKRAR KAPISI (03.08, Cem'in bulgusu) ---
  # Istem "her sikka ayri cumle" diyor ama SOYLEMEK olcmek degildir. Model dort
  # yanlis sikka ayni cumleyi yazarsa bu kapida yakalanir ve soru KUSURLU sayilir.
  # Onek de burada temizlenir: model "Dogrusu:" yazip sistem de eklerse cift olur.
  $tekrarVar = $false
  if($null -ne $obj){
    foreach($alan in 'dogrusu','tuzak'){
      $v = $null; try { if($obj.PSObject.Properties[$alan]){ $v = $obj.$alan } } catch {}
      if($null -eq $v){ continue }
      $gorulen = @{}
      foreach($h in 'A','B','C','D','E'){
        $m = ''; try { if($v.PSObject.Properties[$h]){ $m = "$($v.$h)" } } catch {}
        if($m.Trim().Length -lt 5){ continue }
        # model onegi yazdiysa kirp (cift "Dogrusu: Dogrusu:" olmasin)
        # 03.08 kendi testim yakaladi: model "Dogrusu: Dogrusu: ..." yazinca tek
        # temizlik yetmiyordu, biri kaliyor ve ekran bir tane daha ekleyince yine
        # cift oluyordu. (…)+ ile TEKRARLARIN HEPSI kirpilir.
        $m = ($m -replace '(?i)^\s*((dogrusu|do[ğg]rusu|tuzak)\s*:\s*)+','').Trim()
        try { $v.$h = $m } catch {}
        $anahtar = ($m.ToLowerInvariant() -replace '[^\p{L}\p{Nd}]','')
        if($gorulen.ContainsKey($anahtar)){ $tekrarVar = $true }
        $gorulen[$anahtar] = 1
      }
    }
  }
  if($tekrarVar){ $tekrarKusurlu++ }

  # ========================================================================
  #  TEKDUZELIK KAPISI — 03.08, Cem: "hep karistiriliyor diyor, yapay zeka
  #  yaptigi anlasilmamali."
  #
  #  Tekrar kapisi AYNI CUMLEYI yakaliyordu; bu ondan farkli ve daha sinsi:
  #  cumleler FARKLI ama hepsi ayni kalipla ACILIYOR ("X ile karistiriliyor",
  #  "Y ile karistiriliyor"...). Ust uste ayni acilis makine izidir - defterde
  #  yazili: iz DILDE, iskelette degil; tekduzelik hatadan cok ele verir.
  #  Kok sebep bendim: isteme "(1) neyle karistiriliyor" yazmisim, model bunu
  #  sablon sandi. Istem duzeltildi; burada da OLCULUYOR.
  #
  #  Iki olcu: (a) ilk uc kelime ayni mi, (b) "karistiriliyor" kac kez geciyor.
  # ========================================================================
  if($null -ne $obj){
    $acilislar = @(); $karistirSayisi = 0; $sablonFiil = @{}
    foreach($alan in 'dogrusu','tuzak'){
      $v = $null; try { if($obj.PSObject.Properties[$alan]){ $v = $obj.$alan } } catch {}
      if($null -eq $v){ continue }
      foreach($h in 'A','B','C','D','E'){
        $m = ''; try { if($v.PSObject.Properties[$h]){ $m = "$($v.$h)" } } catch {}
        if($m.Trim().Length -lt 15){ continue }
        $kelimeler = @(($m.ToLowerInvariant() -replace '[^\p{L}\s]','') -split '\s+' | Where-Object { $_ })
        if($kelimeler.Count -ge 3){ $acilislar += ($kelimeler[0..2] -join ' ') }
        # Tek bir kelimeye degil, SABLON FIILLERININ HEPSINE bak: hangisi olursa
        # olsun ayni fiil ust uste kullanilirsa tekduzedir.
        foreach($f in 'kar[ıi][şs]t[ıi]r','san[ıi]l','zannedil','akla gel'){
          if([regex]::IsMatch($m, "(?i)$f")){ $sablonFiil[$f] = 1 + $sablonFiil[$f] }
        }
        $karistirSayisi += ([regex]::Matches($m, '(?i)kar[ıi][şs]t[ıi]r')).Count
      }
    }
    $tekduzeMi = $false
    if($acilislar.Count -ge 3){
      $benzersiz = @($acilislar | Select-Object -Unique).Count
      if($benzersiz -lt [Math]::Ceiling($acilislar.Count / 2.0)){ $tekduzeMi = $true }
    }
    if($karistirSayisi -ge 3){ $tekduzeMi = $true }
    foreach($f in $sablonFiil.Keys){ if($sablonFiil[$f] -ge 3){ $tekduzeMi = $true } }
    if($tekduzeMi){ $tekduzeKusurlu++ }

    # MUGLAK IFADE KAPISI (03.08, Cem: "belirli sartlarda deyip gecmis").
    # Bilgi vaat edip vermeyen kaliplar. Istem bunlari yasakliyor; burada
    # OLCULUYOR - soylemek olcmek degildir.
    $tumUretilen = ''
    foreach($alan in 'dort_parca','tuzak','dogrusu'){
      try {
        if(-not $obj.PSObject.Properties[$alan]){ continue }
        $vv = $obj.$alan
        if($vv -is [string]){ $tumUretilen += ' ' + $vv; continue }
        foreach($h in 'A','B','C','D','E'){ if($vv.PSObject.Properties[$h]){ $tumUretilen += ' ' + "$($vv.$h)" } }
      } catch {}
    }
    if([regex]::IsMatch($tumUretilen, '(?i)belirli\s+[şs]artlar|baz[ıi]\s+hallerde|kanunda\s+[öo]ng[öo]r[üu]len\s+durum|gerekli\s+ko[şs]ullar\s+sa[ğg]lan|mevzuatta\s+belirtilen\s+[öo]l[çc][üu]')){
      $muglakIfade++
    }
  }

  # --- DORT PARCA + DIL KAPISI (03.08, Cem: "annem bile anlasin") ---
  # Istemde "dort baslik zorunlu" demek yetmez; model tek paragraf hukuk metni
  # yazdi. Burada OLCULUR: dort baslik da yoksa kusurlu. Ayrica kanun kopyasi
  # ve yapay zeka doldurma kaliplari sayilir (yapayzeka-kokusu: iz DILDEDIR).
  if($null -ne $obj -and ($i.eksik -contains 'D1_dort_parca')){
    $dp = ''; try { if($obj.PSObject.Properties['dort_parca']){ $dp = "$($obj.dort_parca)" } } catch {}
    $c4 = 0
    if($reNe.IsMatch($dp)){$c4++}; if($reKural.IsMatch($dp)){$c4++}
    if($reOlay.IsMatch($dp)){$c4++}; if($reAkil.IsMatch($dp)){$c4++}
    if($c4 -lt 4){ $dortParcaEksik++ }
    if([regex]::IsMatch($dp, '(?i)bil[üu]mum|m[üu]teferri|m[üu]nasebetiyle|i[şs]bu|mezk[üu]r|tanzim|mutazammin|keyfiyet')){ $kanunKopyasi++ }
    if([regex]::IsMatch($dp, '(?i)[öo]nemli bir husus|dikkat edilmesi gereken|sonu[çc] olarak|[öo]zetle,|bu ba[ğg]lamda|unutulmamal[ıi]d[ıi]r')){ $yzKokusu++ }
  }

  # ========================================================================
  #  DAYANAK DISI IDDIA KAPISI — 03.08, Cem: "kendi bildigini yazmayi
  #  engellesek mi?"
  #
  #  Modele "yazma" demek DILEKTIR; olcmek KURALDIR. Uretilen metindeki
  #  DOGRULANABILIR iddialar (madde no, kanun no, yuzde, tutar) dayanak
  #  metninde ARANIR. Dayanakta gecmiyorsa model onu kendi bildiginden
  #  yazmistir - sayilir ve raporda gorunur.
  #
  #  Dil/beceri sorularinda dayanak YOKTUR; oradaki HER kanun atfi ihlaldir
  #  (istem zaten "hicbir kanun atfi yapamazsin" diyor).
  # ========================================================================
  if($null -ne $obj){
    $uretilen = ''
    foreach($alan in 'dort_parca','tuzak','dogrusu'){
      try {
        if(-not $obj.PSObject.Properties[$alan]){ continue }
        $v = $obj.$alan
        if($v -is [string]){ $uretilen += ' ' + $v; continue }
        foreach($h in 'A','B','C','D','E'){ if($v.PSObject.Properties[$h]){ $uretilen += ' ' + "$($v.$h)" } }
      } catch {}
    }
    # 03.08 - KENDI KAPIM SAHTE ALARM URETIYORDU (601 iddia).
    # D16 ile hesap kodlari artik THP LISTESINDEN geliyor - bu DOGRU davranis.
    # Ama kapi onlari yalniz DAYANAK METNINDE ariyordu; bulamayinca "uydurma"
    # sayiyordu. Yani modeli dogru yaptigi is icin sucluyordum.
    # Cozum: dogrulama havuzuna THP listesi de girer.
    $dayanakMetni = "$($i.dayanak)" + " " + $script:THP_LISTE
    $disi = 0
    # HESAP KODU DESENI (03.08, Cem): "253 Personel Avanslari" gibi UC HANELI kod +
    # buyuk harfle baslayan hesap adi. Eski kapi yalniz "m.275" tipi atiflari
    # ariyordu, ciplak hesap kodunu TANIMIYORDU - model 253/122/127'yi uydurdu ve
    # kapi sustu. (253 Tesis Makine Cihazlar'dir; personel avansi 196'dir.)
    foreach($re in @('(?i)%\s*\d+(?:[.,]\d+)?', '(?i)\b\d{1,3}(?:\.\d{3})+\s*(?:TL|lira)', '(?i)\b\d{4}\s*say[ıi]l[ıi]', '(?i)\bm(?:adde)?\.?\s*\d{1,3}\b', '\b[1-8]\d{2}\s+[A-ZÇĞİÖŞÜ]')){
      foreach($mm in [regex]::Matches($uretilen, $re)){
        $iz = ($mm.Value -replace '[^\p{Nd}]','')     # yalniz rakamlari kiyasla
        if($iz.Length -eq 0){ continue }
        if($i.mevzuatdisi){ $disi++; continue }        # dil sorusunda her atif ihlal
        if(($dayanakMetni -replace '[^\p{Nd}]','') -notlike "*$iz*"){ $disi++ }
      }
    }
    if($disi -gt 0){ $dayanakDisiSoru++; $dayanakDisiIddia += $disi }

    # ====================================================================
    #  HESAP KODU-AD ESLESME KAPISI (03.08, Cem'in 181 bulgusu)
    #
    #  Dayanak-disi kapisi kodun VARLIGINA bakiyordu: 181 THP'de var, gecti.
    #  Ama sorun kodun varligi degil, KOD ILE ADIN ESLESMESI: "181 Diger Donen
    #  Varliklar" yazilmis; 181 GELIR TAHAKKUKLARI'dir. Yani yanlis esleme
    #  butun kapilardan geciyordu. Artik motor kendi ciktisini THP'nin resmi
    #  kod->ad listesine karsi denetler - yayin kapisi K4'un uretim anindaki hali.
    # ====================================================================
    if($script:THP_AD.Count -gt 50){
      # 03.08 - genis desen (Cem: "hesap planina gore kontrol et"): kucuk harfli
      # ad, tireli yazim ve "Ad (NNN)" bicimi de goruluyor; adsiz "620 numarali
      # hesap" disarida - orada dogrulanacak eslesme yok.
      $ciftlerU = New-Object System.Collections.Generic.List[object]
      foreach($mm in [regex]::Matches($uretilen, '(?<![\d.,])\b([1-8]\d{2})(?!\d)\s*[-–—]?\s*(?!numaral|no.?lu|say[ıi]l|adet|kalem|tane|hesab|hesap|kodlu|nolu)([A-Za-zÇĞİÖŞÜçğıöşü][A-Za-zÇĞİÖŞÜçğıöşü\.]*(?:\s+[A-Za-zÇĞİÖŞÜçğıöşü\.]+){0,4})')){
        $ciftlerU.Add(@{ kod=$mm.Groups[1].Value; ad=$mm.Groups[2].Value.Trim() })
      }
      foreach($mm in [regex]::Matches($uretilen, '([A-Za-zÇĞİÖŞÜçğıöşü][A-Za-zÇĞİÖŞÜçğıöşü\.]*(?:\s+[A-Za-zÇĞİÖŞÜçğıöşü\.]+){0,4})\s*\(\s*([1-8]\d{2})\s*\)')){
        $ciftlerU.Add(@{ kod=$mm.Groups[2].Value; ad=$mm.Groups[1].Value.Trim() })
      }
      foreach($cf in $ciftlerU){
        $kod = $cf.kod; $ad = $cf.ad
        if($ad.Length -lt 4){ continue }
        if(-not $script:THP_AD.ContainsKey($kod)){ continue }
        $a = AnlamliKelimeler $ad
        $b = AnlamliKelimeler $script:THP_AD[$kod]
        if($a.Count -eq 0 -or $b.Count -eq 0){ continue }
        $tutar = $false
        foreach($x in $a){ foreach($y in $b){ if($x.StartsWith($y) -or $y.StartsWith($x)){ $tutar = $true } } }
        if(-not $tutar){ $script:hesapKoduYanlis++ }
      }
    }
  }
  $sonuc.Add([ordered]@{
    soru_id="$($i.soru.id)"; parti=$etiketAdi; model=$MODEL
    ders="$($i.soru.ders)"; konu="$($i.soru.konu)"; kaynak="$($i.soru.kaynak)"
    mevzuatdisi=[bool]$i.mevzuatdisi; eksik=@($i.eksik)
    cikti=$(if($null -ne $obj){ $obj } else { @{ ham=$temiz } })
    gecerli_json=($null -ne $obj)
    giris_token=[int]$c.usage.input_tokens; cikis_token=[int]$c.usage.output_tokens
  })
  if((($n+1) % 25) -eq 0){ Write-Host ("  {0}/{1} | giris {2} cikis {3} token" -f ($n+1), $parti.Count, $tIn, $tOut) }
}

$maliyet = [Math]::Round(($tIn * $FIY_IN) + ($tOut * $FIY_OUT), 4)
$birim = if($parti.Count -gt 0){ [Math]::Round($maliyet / $parti.Count, 6) } else { 0 }

# --- TASLAK KOVASINA YAZ + GERI OKU ---
# Yazdiktan sonra GERI OKUYUP SAYMAK sart: "yesil kosu = tam veri" degil
# (yukleyici 3.162 kaydi sessizce kaybetmisti). Geri okunan sayi istenene esit
# degilse kosu KIRMIZI biter - cunku para harcanip cikti yine kaybolmus olur.
$hepsi = $sonuc.ToArray()
$dosyaAd = "$etiketAdi.json"
$govde2 = ConvertTo-Json -Depth 8 -InputObject $hepsi
$yazilan = 0; $yazmaHatasi = ''
try {
  Invoke-RestMethod -Uri "$STOR/object/$KOVA/$dosyaAd" -Method Post `
    -Headers ($SK + @{ 'Content-Type'='application/json'; 'x-upsert'='true' }) `
    -Body ([Text.Encoding]::UTF8.GetBytes($govde2)) -TimeoutSec 180 | Out-Null
  $yazilan = $hepsi.Count
} catch {
  $g=''; if($_.ErrorDetails -and $_.ErrorDetails.Message){ $g=$_.ErrorDetails.Message }
  $yazmaHatasi = "$($_.Exception.Message) | $g"
  Write-Host ("  KOVAYA YAZMA HATASI: {0}" -f $yazmaHatasi)
}
$geriOkuma = -1
try {
  $ho = Invoke-WebRequest -Uri "$STOR/object/$KOVA/$dosyaAd" -Headers $SK -UseBasicParsing -TimeoutSec 180
  $mo = if($ho.RawContentStream){ [Text.Encoding]::UTF8.GetString($ho.RawContentStream.ToArray()) } else { "$($ho.Content)" }
  $geriOkuma = @($mo | ConvertFrom-Json | Where-Object { $null -ne $_ }).Count
} catch { $geriOkuma = -1 }
Write-Host ("  Kovaya yazilan: {0} | GERI OKUMA: {1} satir" -f $yazilan, $geriOkuma)

# --- RAPOR: yalniz SAYILAR depoya gider, soru icerigi GITMEZ ---
$rapor = [ordered]@{
  tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); mod='PILOT (PARALI, kasaya YAZILMADI)'
  model=$MODEL; istenen=$parti.Count
  basarili_json=$basarili; bozuk_json=$bozukJson; cagri_hatasi=$hataliCagri
  tekrar_denenen=$tekrarDenenen          # ilk denemede JSON bozuktu, yeniden istendi
  eksik_harf_tekrar=$script:eksikHarfTekrar  # dogrusu/tuzak harfi eksikti -> yeniden istendi (04.08 kapisi)
  eksik_harf_kalan=$script:eksikHarfKalan    # uc denemede de tamamlanmadi - KALAN EKSIK (sessiz kayip yok)
  cikti_kesilen=$kesilen                 # max_tokens sinirina dayandi
  islenmeyen=$islenmeyen.ToArray()       # iki denemede de olmayanlar - SESSIZ KAYIP YOK
  tekrar_kusurlu=$tekrarKusurlu           # ayni cumleyi birden fazla sikka yazan soru
  dayanak_disi_soru=$dayanakDisiSoru      # dayanakta OLMAYAN sayi/madde/oran yazan soru
  dayanak_disi_iddia=$dayanakDisiIddia    # toplam kac tane oyle iddia var
  madde_bulunamadi=$maddeBulunamadi       # etiketteki madde belge metninde bulunamadi
  istenmeyen_alan=$istenmeyenAlan         # model istenmeden yazip ATILAN alan sayisi
  dort_parca_eksik=$dortParcaEksik        # dort baslik istendi ama gelmedi
  kanun_kopyasi=$kanunKopyasi             # "bilumum/muteferri" gibi kanun dili
  yapayzeka_kokusu=$yzKokusu              # doldurma kaliplari
  tekduze_kusurlu=$tekduzeKusurlu         # siklar ayni kalipla aciliyor (makine izi)
  muglak_ifade=$muglakIfade               # "belirli sartlarda" deyip sartlari saymayan
  hesap_kodu_yanlis=$hesapKoduYanlis          # kod ile ad THP de eslesmiyor (181 vakasi)
  hesap_kodu_duzeltilen=$hesapKoduDuzeltilen  # motor kendisi duzeltti (ad tek hesapla eslesti)
  hesap_kodu_supheli=$hesapKoduSupheli        # belirsiz - DOKUNULMADI, gozle bakilacak
  hesap_kodu_gecersiz_uretim=$hesapKoduGecersizUretim  # uretilen kod 3-hane/THP degildi - REDDEDILDI (unwrap bug sinifi)
  hesap_kodu_silme_adayi=$hesapKoduSilmeAdayi # 04.08 SILME KAPALI: yalniz OLCUM, metne dokunulmadi (uc yanlis-pozitif sinifi yasandi)
  # Ornekler: yalniz THP kod-ad cifti (herkese acik), SORU METNI DEGIL.
  # Sebep: sayac "1 duzeltme yapildi" derken icerik cop olabiliyordu (03.08
  # unwrap bug'i). "Ilk on ornegi gozle oku" kurali artik ICERIGE uygulanabilir.
  hesap_kodu_ornek=$script:hesapKoduOrnek.ToArray()
  giris_token=$tIn; cikis_token=$tOut
  maliyet_usd=$maliyet; birim_usd_soru=$birim
  fiyat_katsayisi='1 USD/M giris + 5 USD/M cikis (Haiku 4.5 liste fiyati)'
  tahmin_tam_kasa_usd=[Math]::Round($birim * $kasa.Count, 2)
  parti=$etiketAdi
  taslaga_yazilan=$yazilan
  geri_okuma=$geriOkuma
  taslak_yeri="Supabase Storage / kova '$KOVA' (OZEL) / dosya $etiketAdi.json"
  taslak_durum=$(if($geriOkuma -eq $parti.Count){'TAMAM'}elseif($geriOkuma -lt 0){'OKUNAMADI'}else{'KIRMIZI - eksik yazildi'})
  yazma_hatasi=$yazmaHatasi
  not='Ciktilar soru_onarim_taslak tablosunda (ozel). KASAYA YAZILMADI - taslak kasa degildir, site degismedi.'
}
RaporYaz $rapor
Write-Host "`n=== PILOT BITTI ==="
Write-Host ("  Soru: {0} | Gecerli JSON: {1} | Bozuk: {2} | Cagri hatasi: {3}" -f $parti.Count, $basarili, $bozukJson, $hataliCagri)
Write-Host ("  Token: giris {0} / cikis {1}" -f $tIn, $tOut)
Write-Host ("  MALIYET: {0} USD | soru basina {1} USD" -f $maliyet, $birim)
Write-Host ("  Tam kasa tahmini ({0} soru): {1} USD" -f $kasa.Count, $rapor.tahmin_tam_kasa_usd)
Write-Host ("  Taslak partisi: {0} | yazilan {1} | geri okuma {2} | {3}" -f $etiketAdi, $yazilan, $geriOkuma, $rapor.taslak_durum)
Write-Host "  KASAYA YAZILMADI - taslak kasa degildir, site degismedi."
# Taslaga yazamadiysak parayi harcayip ciktiyi yine kaybetmisiz demektir: KIRMIZI.
if($geriOkuma -ne $parti.Count){ Write-Host "!! TASLAK EKSIK - kor kalma riski, rapora bak."; exit 1 }
exit 0
