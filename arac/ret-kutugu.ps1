#requires -Version 5.1
<#
================================================================================
  RET KÜTÜĞÜ — düşen her sorunun NEDENİ ve ONARIM EMRİ  (11.09.2026)
  Cem: "retleri topla ama bir daha karşılaşmayacak şekilde KURUMSAL olarak kâğıda dök"

  NİYE VAR: 11.09'da kapı turunda 3 sorudan 1'i düştü. Cem "nedeni ne, nasıl
  kaldırırız" diye sordu; nedeni bulmak için kaydı ELLE açıp hakem gerekçesini
  okumak gerekti. Bu, her ret için tek tek yapılamaz — 3.701 soruluk fabrikada
  945 ret var. Ret nedenleri okunmadığı sürece AYNI kusur tekrar üretiliyor:
  kp-01'in nedeni (kaynak paketi ortadan kesik) 11.09'a kadar hiç görülmemişti,
  çünkü kimse ret gerekçelerini TOPLUCA okumamıştı.

  NE YAPAR: bütün parti dosyalarını tarar, düşen her soruyu KAPIYA ve
  KÖK NEDEN SINIFINA göre gruplar, iki çıktı üretir:
     veri/RET-KUTUGU.md    — insan okur (Cem)
     veri/ret-kutugu.json  — iş emri (onarım betikleri okur)

  KÖK NEDEN SINIFI: hakem gerekçesi serbest metindir; aynı kusur her seferinde
  başka cümleyle anlatılır. Aşağıdaki desenler gerekçeyi SINIFA bağlar, böylece
  "bu ay en çok hangi kusurdan düştük" sorusu cevaplanabilir hâle gelir.
  Sınıfa bağlanamayan gerekçe '(siniflanmamis)' olur ve AYRICA listelenir —
  sessizce 'diger' kovasına atılmaz; yeni bir kusur ailesi doğuyorsa oradan
  görülür ve desen eklenir.

  ⛔ KURAL (bu betiğin var oluş sebebi): ÜRETİM TURU BİTTİĞİNDE BU BETİK KOŞAR.
     Ret nedenleri okunmadan yeni tur başlatılmaz. Bir sınıf ilk üçe giriyorsa
     önce ona kapı kurulur; kapısız tekrar üretim, aynı parayı ikinci kez yakar.

  BEDEL 0 — yalnız yerel dosya okur.
================================================================================
#>
param(
  [string]$Etiket = '',                       # yalniz bu partiyi tara (bos = hepsi)
  [switch]$YalnizYeni                         # yalniz `sade` turunda tazelenmis kayitlar
)
$ErrorActionPreference='Stop'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok=Split-Path -Parent $here

# --- OLCUM KAPILARI (11.09, Cem "olcum araclarina oz-sinav ekle") -------------
# Bu betik OLCUM yapar; olcum aracinin kendisi bozuksa cikan rakam yanlis KARAR
# urettirir (11.09'da dort kez oldu). Oz-sinav kirmizi donerse HIC olcmez.
. (Join-Path $here 'olcum-kapilari.ps1')
$ok_kusur=Test-OlcumKapilari -Sessiz
if((Dizi $ok_kusur).Count){
  Write-Host '⛔ OLCUM KAPILARI KIRMIZI - bu olcume guvenilmez:' -ForegroundColor Red
  foreach($h in (Dizi $ok_kusur)){ Write-Host "   - $h" -ForegroundColor Red }
  throw 'olcum kapilari oz-sinavi dustu'
}


# --- KÖK NEDEN SINIFLARI ------------------------------------------------------
# Her satir: sinif adi · gerekce deseni · ONARIM YOLU (ne yapilmali)
# Desenler 11.09 itibariyla GERCEK ret gerekcelerinden cikarildi; yenisi
# gorulunce buraya eklenir (betik '(siniflanmamis)' diye haber verir).
$RET_SINIFLARI=@(
  # ⚠ SIRA ONEMLI: yukaridaki desen once dener. KESIK, EKSIK'in ozel halidir.
  @{ ad='KAYNAK-KESIK'   ; desen='(?i)kesinti|kesilmi|tamamlanmam|yarim kal|eksik metin|devami yok|yaln[iı]zca m\.\d|ba[sş]lang[iı]c[iı] bulunmakta'
     onarim='Kaynak paketi KIRPILMIS (kp-01 sinifi). KAPI-KP (11.09) bunu onluyor; ESKI kayitlar icin hakem tazelenir.' }
  # 11.09 OLCULDU: fabrikadaki 1.288 retin buyuk cogunlugu BU sinif. Ilk desenim
  # cok dardi ("yer almamaktadir") ve 946 gerekceyi siniflayamadi. Hakem ayni
  # kusuru ON AYRI FIILLE anlatiyor; hepsi burada:
  # IKI KOSULLU: cumleler uzun oldugu icin YAKINLIK sarti tutmuyordu ("Kaynak metni
  # TMS 36 paragraf 2'de ... girmesi gerektigini acikca belirtmemektedir" = 120+ krk).
  # Artik iki bagimsiz kosul: (1) kaynak/paket/metin ANILIYOR ve (2) VARLIK YOKSAMASI
  # var. Ikisi cumlenin neresinde olursa olsun eslesir.
  @{ ad='KAYNAK-EKSIK'
     desen ='(?i)kaynak|pakette|sa[gğ]lanan metin|verilen metin'
     # ⛔ 12.09 GENISLETILDI — (siniflanmamis) 275 okundu, 103'u KAPI-HAKEM'di ve
     #   BUNLARIN 100'U KAYNAK diyordu; desen2 sadece "yokluk" fiillerini ariyordu,
     #   hakem ayni kusuru "eksiktir / yetersiz / sadece X icerir / dayanak madde
     #   yok / tasimamaktadir" diye de yaziyor. Ornek (kgk-muhstd/kp-17):
     #   "...temel mantigi kaynakta EKSIKTIR" -> hicbir yokluk fiili yok, siniflanamiyordu.
     # ⚠ "eksik" TEK BASINA KULLANILMAZ — prova yakaladi: "Dogru sik ifadesi EKSIK ve
     #   yaniltici" cumlesi kaynakla ilgili degil, ama yakalaniyordu (COK-ANLAMLI'dan
     #   calmisti). O yuzden eksik/yetersiz YALNIZ 'kaynak' kelimesine YAKINSA sayilir.
     desen2='(?i)(yer alma|yer verme|bulunma|ge[cç]me|i[cç]erme|belirtme|desteklenme|[cç][iı]kar[iı]lama|mevcut de[gğ]il|sunulma|bahsedilme|yoktur|a[cç][iı]k bir kural yok|hi[cç] (bahsedil|ge[cç]m|yer al)|kaynak\w*.{0,45}(eksik|yetersiz)|(eksik|yetersiz).{0,35}kaynak|dayanak (madde|paragraf|h[uü]k[uü]m|metni)|sadece .{0,60}i[cç]erir|ta[sş][iı]mamakta|ta[sş][iı]m[iı]yor)'
     onarim='Paket cevabi destekleyen HUKMU tasimiyor. Once KAYNAK SIRALAMASI (KAPI-KP) ve konu-kaynak bagi bakilir; kaynak ambarda yoksa yutma is emri.' }
  @{ ad='KAYNAK-ILGISIZ' ; desen='(?i)ilgisiz kaynak|konuyla ilgili kaynak|ba[sş]ka bir (standart|kanun|konu)ya ait'
     onarim='Pakete konunun kaynagi hic girmemis. Konu-kaynak bagi (veri/konu-kaynak-bagi.json) duzeltilir.' }
  @{ ad='SINAV-DUZEYI'   ; desen='(?i)(YMM|ba[gğ][iı]ms[iı]z denet[cç]i|akademik|hukuk s[iı]nav[iı]).{0,40}(d[uü]zey|yak[iı]n|kal[iı]p)|SGS.{0,30}kullan[iı]lmaz|d[uü]zeyin[ei] (g[oö]re )?(a[gğ][iı]r|[uü]st)'
     onarim='Soru SGS duzeyinin USTUNDE (paragraf numarasi sorgusu vb). Konu kartina zorluk tavani yazilir; soru sadelestirilir.' }
  # ⛔ 12.09 GENISLETILDI — (siniflanmamis) 275'in 172'si KAPI-HAKEM2'ydi ve
  #   BUNLARIN 158'I SIK KALIBI diyordu. Ikinci hakemin dili cok degisken; 61'i
  #   duz "KOKU:" ile basliyor, kalani "A, C, E siklarinda 'yalnizca' kelimesinin
  #   mekanik tekrari" gibi serbest cumleler. Eski desen yalnizca bes kalip
  #   ariyordu ve hepsini kaciriyordu.
  @{ ad='YZ-KOKUSU'      ; desen='(?i)kli[sş]e|yapay kesinlik|HER ZAMAN do[gğ]rudur|do[gğ]ru [sş][iı]k.{0,40}daha uzun|ek n[uü]ans|^\s*KOKU\s*:|[sş][iı]k.{0,40}(ayn[iı] kal[iı]b|kal[iı]p.{0,12}tekrar|tekrar[iı] [sş]eklinde|mekanik tekrar|birebir ayn[iı])|absol[uü]tist|mutlak.{0,25}(dil|kal[iı]p|ifade|g[uü]vence)|kelime e[sş]le[sş]mesiyle ele ver'
     onarim='Yapay zeka kokusu: en uzun sik dogru, mutlak ifade. Sik boylari esitlenir, mutlak zarflar atilir.' }
  @{ ad='HESAP-YANLIS'   ; desen='(?i)hesap kodu (yanli|hatal)|yanlis hesap|kod-ad|THP \d{3}.*(yanli|olmal)'
     onarim='kp-80 sinifi. KAPI-HS beyaz listesi ve hesap kalibi guncellenir; soru yeniden yazilir.' }
  @{ ad='DOGRU-SIK-YOK'  ; desen='(?i)dogru s[iı]k yok|hicbir s[iı]k|birden fazla dogru|iki s[iı]k da dogru'
     onarim='Anahtar hatali ya da sik kumesi bozuk. Soru yeniden uretilir (kurtarilamaz).' }
  @{ ad='DERS-DISI'      ; desen='(?i)ders[- ]d[iı]s[iı]|bu dersin kapsam[iı] d[iı]s[iı]nda'
     onarim='Etiket/ders eslesmesi yanlis. -DersRegex dogru mu (KAPI-DR)? Degilse konu kartina tasinir.' }
  @{ ad='KONU-DISI'      ; desen='(?i)konu[- ]d[iı]s[iı]|farkli bir konu|konu ile ilgisi'
     onarim='Konu etiketi soru ile uyusmuyor. Konu kartindaki istem cumlesi duzeltilir.' }
  @{ ad='ESKI-MEVZUAT'   ; desen='(?i)y[uü]r[uü]rl[uü]kten|mülga|eski d[oö]nem|g[uü]ncel de[gğ]il|degismis oran'
     onarim='Kaynak bayat. Ambardaki mevzuat tazelenir, soru yeniden uretilir.' }
  @{ ad='COK-ANLAMLI'    ; desen='(?i)birden fazla (anlam|yorum)|belirsiz|mu[gğ]lak|net de[gğ]il'
     onarim='Istem cumlesi tek anlama indirilir; cogu zaman tek kelime duzeltmesi yeter.' }
  @{ ad='CELDIRICI-SAHTE'; desen='(?i)[cç]eldirici.*(rastgele|gercek de[gğ]il|hesaplanm|yol yok)'
     onarim='Celdirici sayilar uydurulmus. KAPI-C yolu; soru yeniden uretilir.' }
  @{ ad='YAPAY-DIL'      ; desen='(?i)yapay|s[iı]nav dili de[gğ]il|ders kitab[iı] gibi|kitabi dil'
     onarim='Dil kapisi. Istem, cikmis sinav yazimina gore yeniden kurulur.' }
)
# PS TUZAGI (11.09, bu betikte YASANDI): dizinin adi $SINIF idi ve asagida
#    "$sinif=SinifBul ..." yazdim. PS harf AYIRMAZ -> ilk atama sinif dizisini
#    STRING ile ezdi, ikinci cagri null dondu, betik "array index null" ile
#    coktu. Depo kurali: global sabitlere kisa/cakisan ad YASAK. Ad: $RET_SINIFLARI.
# YAPISAL SINIFLAR: gerekcesi serbest METIN OLMAYAN kapilar. Bunlar desenle
# siniflanamaz (kor cozum "kor B · anahtar D" der, hakem hic kosmamissa gerekce
# YOKTUR) ve '(siniflanmamis)' kovasina dusurulurse o kova anlamsiz sisiyordu:
# 748'in 264'u boyleydi. Kapidan DOGRUDAN sinif verilir.
$RET_YAPISAL=@{
  'hakem KOSMADI'  = @{ ad='HAKEM-KOSMADI'; onarim='Soru hic denetlenmemis. Parti -PilotId ile yeniden kosulur; kapilardan gecerse hasada girer.' }
  'KAPI-KOR'       = @{ ad='KOR-CELISKI'  ; onarim='Bagimsiz kor cozum anahtardan FARKLI cevap verdi. Ikisinden biri yanlis: once anahtari elle dogrula, sonra soruyu yeniden uret.' }
  'KAPI-SIM'       = @{ ad='SIM-YANLIS'   ; onarim='Ogrenci simulasyonu yanlis cevapladi. Celdirici cok guclu ya da istem mugllak; genelde tek kelime duzeltmesi yeter.' }
}
function SinifBul([string]$gerekce,[string]$kapi){
  if($RET_YAPISAL.ContainsKey($kapi) -and -not "$gerekce".Trim()){ return $RET_YAPISAL[$kapi].ad }
  foreach($s in $RET_SINIFLARI){
    if("$gerekce" -notmatch $s.desen){ continue }
    if($s.ContainsKey('desen2') -and "$gerekce" -notmatch $s.desen2){ continue }
    return $s.ad
  }
  if($RET_YAPISAL.ContainsKey($kapi)){ return $RET_YAPISAL[$kapi].ad }
  return '(siniflanmamis)'
}
function OnarimBul([string]$ad){
  $x=($RET_SINIFLARI|Where-Object{ $_.ad -eq $ad }|Select-Object -First 1)
  if($x){ return $x.onarim }
  foreach($k in $RET_YAPISAL.Keys){ if($RET_YAPISAL[$k].ad -eq $ad){ return $RET_YAPISAL[$k].onarim } }
  return ''
}

# --- TARAMA -------------------------------------------------------------------
$dosyalar=@(Get-ChildItem (Join-Path $depoKok 'veri\fabrika') -Filter 'kalip-parti-*.json'|Sort-Object Name)
if($Etiket){ $dosyalar=@($dosyalar|Where-Object{ $_.BaseName -eq "kalip-parti-$Etiket" }) }

$ret=New-Object System.Collections.Generic.List[object]
$kapiSay=[ordered]@{}; $sinifSay=@{}; $toplam=0
foreach($x in $dosyalar){
  $et=($x.BaseName -replace '^kalip-parti-','')
  $c=$null; try{ $c=Get-Content $x.FullName -Raw -Encoding UTF8|ConvertFrom-Json }catch{ continue }
  foreach($p in $c.PSObject.Properties){
    $v=$p.Value; if(-not $v -or -not $v.soru){ continue }
    $toplam++
    $kapi=''; $ger=''
    if(-not $v.hakem){ $kapi='hakem KOSMADI'; $ger='' }
    elseif("$($v.hakem.karar)" -eq 'HAYIR'){ $kapi='KAPI-HAKEM'; $ger="$($v.hakem.gerekce) $($v.hakem.dogru_sik_gerekce) $($v.hakem.atif_gerekce)" }
    elseif("$($v.hakem.hesap_uyum)" -eq 'HESAP-YANLIS'){ $kapi='KAPI-HS (hesap)'; $ger="$($v.hakem.hesap_gerekce)" }
    elseif($v.kor_cozum -and $v.kor_cozum.PSObject.Properties['dogru_mu'] -and -not [bool]$v.kor_cozum.dogru_mu){
      $kapi='KAPI-KOR'; $ger="kor cozum $($v.kor_cozum.cevap) · anahtar $($v.dogru)" }
    elseif($v.hakem2 -and "$($v.hakem2.karar)" -eq 'HAYIR'){
      # ⚠ 11.09: burada sinav_gerekce + celdirici_gerekce'yi KORU KORUNE birlestiriyordum.
      #    Ikisi de GECEN boyut oldugunda gerekce OLUMLU metin oluyor ("sinav diliyle
      #    uyumlu...") ve siniflandirici bosa dusuyordu. Artik yalniz DUSUREN boyut
      #    okunur; yapay zeka kokusu (koku) her hâlükârda eklenir.
      $kapi='KAPI-HAKEM2'; $gp=New-Object System.Collections.Generic.List[string]
      if("$($v.hakem2.sinav_gibi)" -eq 'HAYIR' -and "$($v.hakem2.sinav_gerekce)".Trim()){ $gp.Add("$($v.hakem2.sinav_gerekce)") }
      if("$($v.hakem2.celdirici_gercek)" -eq 'HAYIR' -and "$($v.hakem2.celdirici_gerekce)".Trim()){ $gp.Add("$($v.hakem2.celdirici_gerekce)") }
      foreach($ka in @($v.hakem2.koku)){ if("$ka".Trim()){ $gp.Add("KOKU: $ka") } }
      if(-not $gp.Count -and "$($v.hakem2.sinav_gerekce)".Trim()){ $gp.Add("$($v.hakem2.sinav_gerekce)") }
      $ger=($gp -join ' · ')
    }
    else{
      $simK=''
      foreach($sa in 'simulasyon_sonnet','simulasyon'){ if($v.$sa -and $v.$sa.PSObject.Properties['dogru_mu'] -and -not [bool]$v.$sa.dogru_mu){ $simK=$sa } }
      if($simK){ $kapi='KAPI-SIM'; $ger="$($v.$simK.gerekce)" }
    }
    if(-not $kapi){ continue }
    if($YalnizYeni -and -not ($v.hakem -and $v.hakem.PSObject.Properties['hesap_uyum'])){ continue }
    $sinif=SinifBul $ger $kapi
    $kapiSay[$kapi]=1+[int]$kapiSay[$kapi]
    $sinifSay[$sinif]=1+[int]$sinifSay[$sinif]
    $ret.Add([ordered]@{
      etiket=$et; id=$p.Name; konu="$($v.konu)"; kapi=$kapi; sinif=$sinif
      gerekce=("$ger" -replace '\s+',' ').Trim()
      onarim=(OnarimBul $sinif)
    })
  }
}

# ⛔ KISMI KOSU TAM RAPORU EZMEZ (11.09, bu oturumda IKINCI kez yasandi):
#    -Etiket ya da -YalnizYeni ile kosulan tur, evrenin YALNIZ BIR PARCASINI
#    tarar. Ayni dosyaya yazarsa "1.288 ret" raporunun yerine "44 ret" gecer
#    ve kimse fark etmez. Kismi kosular AYRI dosyaya yazar.
$ekAd = ''
if($YalnizYeni){ $ekAd = '-yeni' }
elseif($Etiket){ $ekAd = "-$Etiket" }
# --- CIKTI --------------------------------------------------------------------
. (Join-Path $here 'rapor-yaz.ps1')
RaporYaz -Hedef (Join-Path $depoKok ("veri\ret-kutugu$ekAd.json")) -Nesne ([ordered]@{
  olcum=(Get-Date -Format 'yyyy-MM-dd HH:mm')
  kural='URETIM TURU BITTIGINDE BU BETIK KOSAR. Ret nedenleri okunmadan yeni tur baslatilmaz.'
  taranan_soru=$toplam; ret=$ret.Count
  # RaporYaz kiyaslama yaparken OrderedDictionary'yi sindiremiyor (ArgumentException,
  # 11.09'da yasandi) -> duz nesneye cevrilir.
  kapi_dagilimi=([pscustomobject]($kapiSay.GetEnumerator()|Sort-Object Value -Descending|ForEach-Object -Begin {$h=[ordered]@{}} -Process {$h[$_.Key]=$_.Value} -End {$h}))
  sinif_dagilimi=([pscustomobject]($sinifSay.GetEnumerator()|Sort-Object Value -Descending|ForEach-Object -Begin {$h2=[ordered]@{}} -Process {$h2[$_.Key]=$_.Value} -End {$h2}))
  kayitlar=@($ret | ForEach-Object { [pscustomobject]$_ })
})

$m=New-Object System.Text.StringBuilder
function Y([string]$s){ [void]$m.AppendLine($s) }
Y "# RET KUTUGU — dusen sorularin nedeni ve onarim emri"
Y ""
Y ("> Uretim: **{0}** (makine; elle duzenlenmez — arac/ret-kutugu.ps1). Bedel 0." -f (Get-Date -Format 'dd.MM.yyyy HH:mm'))
Y ("> Taranan {0:N0} soru · dusen **{1:N0}** (%{2:N1})" -f $toplam,$ret.Count,$(if($toplam){100*$ret.Count/[double]$toplam}else{0}))
Y ""
Y "## KURAL"
Y ""
Y "**Uretim turu bittiginde bu betik kosar. Ret nedenleri okunmadan yeni tur baslatilmaz.**"
Y "Bir kok neden sinifi ilk uce giriyorsa once ona KAPI kurulur — kapisiz tekrar uretim, ayni parayi ikinci kez yakar."
Y ""
Y "## 1 · HANGI KAPI DUSURDU"
Y ""
Y "| Kapi | Soru | Pay |"
Y "|---|---:|---:|"
foreach($k in ($kapiSay.GetEnumerator()|Sort-Object Value -Descending)){
  Y ("| {0} | {1:N0} | %{2:N1} |" -f $k.Key,$k.Value,(100*$k.Value/[double]$ret.Count))
}
Y ""
Y "## 2 · KOK NEDEN SINIFI — asil okunacak tablo"
Y ""
Y "| Sinif | Soru | Pay | Onarim yolu |"
Y "|---|---:|---:|---|"
foreach($s in ($sinifSay.GetEnumerator()|Sort-Object Value -Descending)){
  $on=OnarimBul $s.Key
  if(-not $on){ $on='**Desen yok — yeni kusur ailesi olabilir, asagidaki orneklere bak ve SINIF listesine desen ekle.**' }
  Y ("| {0} | {1:N0} | %{2:N1} | {3} |" -f $s.Key,$s.Value,(100*$s.Value/[double]$ret.Count),$on)
}
if($sinifSay.ContainsKey('(siniflanmamis)')){
  Y ""
  Y ("### Siniflanmamis {0} gerekceden ornekler" -f $sinifSay['(siniflanmamis)'])
  Y ""
  foreach($r in (@($ret|Where-Object{ $_.sinif -eq '(siniflanmamis)' -and $_.gerekce })|Select-Object -First 12)){
    $g=$r.gerekce; if($g.Length -gt 190){ $g=$g.Substring(0,190)+'…' }
    Y ("- `{0}/{1}` [{2}] {3}" -f $r.etiket,$r.id,$r.kapi,$g)
  }
}
Y ""
Y "## 3 · ONARIM EMRI — sinif sinif ilk 10 soru"
Y ""
foreach($s in ($sinifSay.GetEnumerator()|Sort-Object Value -Descending)){
  if($s.Key -eq '(siniflanmamis)'){ continue }
  Y ("### {0} ({1} soru)" -f $s.Key,$s.Value)
  Y ""
  Y "| Parti / id | Konu | Gerekce |"
  Y "|---|---|---|"
  foreach($r in (@($ret|Where-Object{ $_.sinif -eq $s.Key })|Select-Object -First 10)){
    $g=$r.gerekce; if($g.Length -gt 150){ $g=$g.Substring(0,150)+'…' }
    Y ("| {0}/{1} | {2} | {3} |" -f $r.etiket,$r.id,$r.konu,$g)
  }
  Y ""
}
[IO.File]::WriteAllText((Join-Path $depoKok ("veri\RET-KUTUGU$($ekAd.ToUpperInvariant()).md")),$m.ToString(),(New-Object Text.UTF8Encoding $true))

Write-Host ("taranan {0:N0} soru · dusen {1:N0}" -f $toplam,$ret.Count) -ForegroundColor Cyan
Write-Host "`nKAPI:" -ForegroundColor Cyan
foreach($k in ($kapiSay.GetEnumerator()|Sort-Object Value -Descending)){ Write-Host ("  {0,-18} {1,5}" -f $k.Key,$k.Value) }
Write-Host "`nKOK NEDEN:" -ForegroundColor Cyan
foreach($s in ($sinifSay.GetEnumerator()|Sort-Object Value -Descending)){
  $renk=if($s.Key -eq '(siniflanmamis)'){'Yellow'}else{'Gray'}
  Write-Host ("  {0,-18} {1,5}" -f $s.Key,$s.Value) -ForegroundColor $renk
}
Write-Host ("`n-> veri/RET-KUTUGU$($ekAd.ToUpperInvariant()).md · veri/ret-kutugu$ekAd.json") -ForegroundColor Green
