#requires -Version 5.1
<#
================================================================================
  DERS AYRISTIRICI  (11.09.2026, Cem "1 ve 2 yap")

  SORUN: konu-koprusu'nde 1.887 konu KABA ders adi tasiyor — "Muhasebe" 621,
  "Hukuk" 551 konu. Oysa SGS'de "Muhasebe" DORT ayri derstir (Finansal
  Muhasebe 26 soru, Denetim 16, Maliyet 8, Mali Tablolar 8) ve "Hukuk" BES
  ayri derstir (Ticaret 6, Borclar 6, Vergi 6, Is-SGK 6, Meslek 6).
  Ayristirma olmadan "hangi derse kac soru basacagiz" sorusu cevaplanamaz.

  ⛔ BU BETIK KENDINI SINAR. Kural yazip "oldu" DEMEZ: koprude `bizim_ders`i
  ZATEN BILINEN konular uzerinde kurallari kosar, isabeti olcer ve ekrana
  basar. Isabet dusukse uygulama YAPILMAZ — o zaman kural listesi duzeltilir.
  (Bu oturumda ayni sinifta iki kez yanildim: KAPI-KE %35 isabetle 63 iyi
  soruyu bozacakti; ret siniflandiricisinin ilk deseni 1.288 retin 1.210'unu
  siniflayamamisti. Olcmeden uygulanan kural pahali.)

  ⛔ TAHMIN ETMEZ: kurallardan HICBIRI tutmuyorsa konu '(ayristirilamadi)'
  kalir ve rapora yazilir. Yanlis derse atamak, atamamaktan kotudur -
  o ders adina soru basariz ve sinavda o dersten cikmaz.

  CIKTI: veri/ders-ayristirma.json  (konu -> ders, gerekce, guven)
  BEDEL 0 — yalniz yerel dosya okur.
================================================================================
#>
param([switch]$Uygula)    # olmadan: yalniz olcer ve rapor eder
$ErrorActionPreference='Stop'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok=Split-Path -Parent $here

function Katla([string]$s){
  $x="$s".Trim().ToLowerInvariant()
  foreach($c in @(@('ç','c'),@('ğ','g'),@('ı','i'),@('İ','i'),@('ö','o'),@('ş','s'),@('ü','u'),@('â','a'),@('î','i'),@('û','u'))){ $x=$x.Replace($c[0],$c[1]) }
  return ($x -replace '[^a-z0-9]+',' ').Trim()
}

# --- KURALLAR ----------------------------------------------------------------
# Sira ONEMLI: ustteki once dener. Dar/ozel desenler USTTE, genis desenler ALTTA.
# Her desen katlanmis (ASCII, kucuk harf) metne uygulanir.
# ⛔ KELIME SINIRI ZORUNLU. Ilk surumde 'oda' deseni **"modal fiil"** icinde
#    eslesti ve Yabanci Dil sorusunu Meslek Hukuku sandi; 'harc' da
#    "kamu harcamalari"nda eslesip Maliye'yi Vergi yapti. Kisa anahtarlar
#    artik \b ile cevrili.
# ⛔ SIRA: ozel desen USTTE. "finansman bonosu" (FM) genel "bono" (Ticaret)
#    kuralindan ONCE denenmeli, yoksa muhasebe sorusu hukuka gider.
$KURAL=@(
  # --- ONCE AYRIKSI DURUMLAR (geri sinamada yakalananlar) ---
  @{ ders='Finansal Muhasebe'; desen='\b(finansman|hazine) bonosu|nakit akis tablo|isletmenin surekli' }
  @{ ders='Mali Tablolar Analizi'; desen='net isletme sermaye|isletme sermayesi' }
  # ⛔ 2. TUR (11.09): TICARET %68 idi. Sebep SIRAYDI - Finansal Muhasebe kurali
  #    Ticaret'ten ONCE deneniyordu ve 'sermaye', 'sirket kurulus', 'kambiyo',
  #    'senet' desenleri sirketler hukuku sorularini muhasebeye cekiyordu
  #    ("anonim sirket sermaye", "limited sirket kurulusu", "kambiyo senedi
  #    beyaz ciro"). SIRKETLER HUKUKU + KIYMETLI EVRAK artik EN USTTE.
  @{ ders='Ticaret Hukuku'; desen='(anonim|limited|kollektif|komandit|sermayesi paylara)\s*sirket|sirket (kurulus|birlesme|bolunme|tur degis|tasfiye)|kambiyo sened|kiymetli evrak|\bciro\b|(zorunlu|sekil) unsur|karsiliksiz cek|\bcek\b.*(unsur|ibraz|zorunlu)|ticari temsil|\btemsil yetki|bedelsiz pay|ayni sermaye|sermaye (azalt|artirim).*(sirket|pay)|pay sahib|imtiyazli pay' }
  @{ ders='Borclar Hukuku'; desen='haksiz fiil|sebepsiz zenginles|hizmet borclan' }
  # ⛔ 2. TUR: MALIYE %42 idi. Sebep: Vergi Hukuku kuralindaki genis 'vergi'
  #    deseni MALIYE TEORISINI yutuyordu ("verginin yansimasi", "vergi takozu",
  #    "vergi gayreti" hepsi Vergi Hukuku sanildi). Ayrim su: MALIYE = kamu
  #    maliyesi TEORISI (yansima, kapitalizasyon, takoz, gayret, oranlilik,
  #    siniflandirma, tarife tipi); VERGI HUKUKU = USUL ve KANUN (VUK, beyanname,
  #    tarh, tahakkuk, tebligat). Teori desenleri Vergi'den ONCE denenir.
  @{ ders='Maliye'; desen='kamu harcama|kamu gelir|kamu borc|\bbutce\b|parafiskal|stagflasyon|verginin (yansima|karar|gelir|ikame)|vergi (yansima|kapitalizasyon|takoz|gayret|harcamasi|siniflandirma|oranlilik|entegrasyon|rekabet|erozyon|adalet|kacakcilik teori)|artan oranli|azalan oranli|duz oranli|spesifik.?advalorem|advalorem|(dolayli|dolaysiz) vergi|servet vergisi|dilim tarife|vergi tarife|mali sistem|maliye politika' }
  # --- MUHASEBE kovasinin dort dersi ---
  @{ ders='Denetim'; desen='denetim|denetci|\bbds\b|bagimsiz denet|ic kontrol|\bkanit\b|guvence|calisma kagi|yonetim iddia|onemlilik|orneklem|\bhile\b|gorus turleri|kilit denetim|dikkat cekilen husus|vurgu paragraf|serbestlik|tarafsizlik' }
  @{ ders='Maliyet Muhasebesi'; desen='maliyet|siparis|\bsafha\b|genel uretim gider|birlesik urun|\byan urun\b|bosa gecen|esdeger urun|direkt ilk madde|direkt iscilik|faaliyet tabanli|katki pay|basabas|butce fark' }
  @{ ders='Mali Tablolar Analizi'; desen='oran analiz|dikey analiz|yatay analiz|egilim yuzde|karsilastirmali tablo|likidite oran|cari oran|asit test|devir hiz|kaldirac|fon akim|ozkaynak degisim|mali tablo analiz|karlilik oran' }
  @{ ders='Finansal Muhasebe'; desen='\btms\b|\btfrs\b|\bthp\b|hesap plan|yevmiye|buyuk defter|\bmizan\b|amortisman|deger dusuklugu|stok degerleme|\balacak\b|\bsenet\b|kambiyo|sermaye|kar dagitim|serefiye|sirket kurulus|donem sonu|envanter|reeskont|\bkidem\b|hasilat|kira muhasebe|yatirim amacli|nazim hesap|\bkasa\b|\bbanka\b|depozito|\bavans\b|\bgider\b|\bgelir\b|karsilik|maddi duran varlik|maddi olmayan duran' }
  # --- HUKUK kovasinin bes dersi ---
  @{ ders='Meslek Hukuku'; desen='\bsmmm\b|\bymm\b|3568|meslek mensu|disiplin|\boda\b|turmob|tesmer|\bstaj\b|\bruhsat\b|mesleki? etik|ucret tarife|mesleki sorumluluk sigorta|calisma usul' }
  @{ ders='Is ve Sosyal Guvenlik Hukuku'; desen='is sozlesme|\biscil|isveren|kidem tazminat|ihbar tazminat|fazla calisma|yillik izin|is guvence|sendika|toplu is|\bsgk\b|sigortali|\bprim\b|emeklilik|is kazasi|meslek hastali|asgari ucret|is saglig|isten cikar|fesih bildirim|ucret yonetmelig' }
  @{ ders='Vergi Hukuku'; desen='\bvuk\b|vergi|\bgvk\b|\bkvk\b|\bkdv\b|\botv\b|damga|beyanname|\btarh\b|tahakkuk|tebligat|uzlasma|ceza kesme|amme alacak|6183|\btecil\b|\bterkin\b|transfer fiyatland|ortulu sermaye|stopaj|tevkifat|mukellef' }
  @{ ders='Ticaret Hukuku'; desen='\bttk\b|ticaret sirket|anonim sirket|limited sirket|kollektif|komandit|\bbono\b|\bpolice\b|\btacir\b|ticari isletme|ticaret sicil|\bunvan\b|\bmarka\b|rekabet yasag|birlesme devral|tasfiye|genel kurul|yonetim kurulu|pay senedi|imtiyaz' }
  @{ ders='Borclar Hukuku'; desen='borclar|sozlesme|temerrut|\bifa\b|\btakas\b|\btemsil\b|vekalet|kefalet|alacagin devri|borcun ustlenil|muteselsil|irade sakat|hata hile ikrah|cezai sart|zamanasimi' }
  # --- digerleri ---
  @{ ders='Ekonomi'; desen='\barz\b|\btalep\b|esneklik|enflasyon|issizlik|milli gelir|\bgsyh\b|para politika|\bfaiz\b|doviz kuru|piyasa yapisi|\btekel\b|oligopol|marjinal|uretim fonksiyon|firma dengesi|dis ticaret|odemeler dengesi' }
  @{ ders='Maliye'; desen='kamu maliye|vergileme ilke|mali politika|yerinden yonetim|mali anestezi|otomatik istikrar|dissal fayda|kamusal mal|laffer|vergi yansima|\bharc\b' }
  # --- sozel dersler: yanlis kovaya dusmesinler ---
  @{ ders='Yabanci Dil'; desen='\bmodal\b|\btense\b|\bedat\b|preposition|kelime bilgisi|cumle tamamlama|\bfiil\b.*ingiliz|okuma parca' }
  @{ ders='Turkce'; desen='yazim kural|noktalama|anlatim bozuk|ses olay|paragraf|sozcuk turu|cumle oge|buyuk harf|unlu (dusme|degisim|daralma)|deyim|atasozu' }
  @{ ders='Matematik'; desen='\bkume\b|\bdenklem\b|\bfonksiyon\b|olasilik|permutasyon|kombinasyon|\borani\b.*problem|sayi problem|isci havuz|yuzde problem|faiz problem|\bebob\b|\bekok\b' }
)
function DersBul([string]$konu){
  $k=Katla $konu
  foreach($r in $KURAL){ if($k -match $r.desen){ return $r.ders } }
  return ''
}

# --- KOPRUYU OKU -------------------------------------------------------------
$kopruHam=Get-Content (Join-Path $depoKok 'veri\fabrika\konu-koprusu.json') -Raw -Encoding UTF8|ConvertFrom-Json
$bilinen=New-Object System.Collections.Generic.List[object]   # bizim_ders DOLU -> sinama kumesi
$kaba=New-Object System.Collections.Generic.List[object]      # bizim_ders BOS  -> ayristirilacak
foreach($r in @($kopruHam)){
  if("$($r.sinav)" -ne 'SGS'){ continue }
  if([int]$r.cikmis -lt 1){ continue }
  $d="$($r.bizim_ders)".Trim()
  if($d){ $bilinen.Add([pscustomobject]@{ konu="$($r.konu)"; gercek=$d }) }
  else  { $kaba.Add([pscustomobject]@{ konu="$($r.konu)"; kaba=("$($r.arsiv_ders)".Trim() -replace '\s*/\s*.*$',''); cikmis=[int]$r.cikmis }) }
}
Write-Host ("sinama kumesi (bizim_ders dolu): {0:N0}" -f $bilinen.Count) -ForegroundColor Cyan
Write-Host ("ayristirilacak (bizim_ders bos): {0:N0}" -f $kaba.Count) -ForegroundColor Cyan

# --- GERI SINAMA: kurallar BILINEN konularda ne kadar isabetli? ---------------
$dogru=0; $yanlis=0; $bos=0
$yanlisOrnek=New-Object System.Collections.Generic.List[string]
$dersIsabet=@{}
foreach($b in $bilinen){
  $t=DersBul $b.konu
  if(-not $t){ $bos++; continue }
  $g=Katla $b.gercek; $tk=Katla $t
  if(-not $dersIsabet.ContainsKey($b.gercek)){ $dersIsabet[$b.gercek]=@{ d=0; y=0 } }
  if($g -eq $tk){ $dogru++; $dersIsabet[$b.gercek].d++ }
  else{ $yanlis++; $dersIsabet[$b.gercek].y++
        if($yanlisOrnek.Count -lt 15){ $yanlisOrnek.Add(("{0}  ->  tahmin {1} · gercek {2}" -f $b.konu,$t,$b.gercek)) } }
}
$karar=$dogru+$yanlis
Write-Host ""
Write-Host "=== GERI SINAMA ===" -ForegroundColor Yellow
Write-Host ("  karar verilen : {0:N0}  (kural tutmayan {1:N0})" -f $karar,$bos)
if($karar){ Write-Host ("  ISABET        : {0:N0} / {1:N0} = %{2:N1}" -f $dogru,$karar,(100*$dogru/[double]$karar)) -ForegroundColor $(if((100*$dogru/[double]$karar) -ge 85){'Green'}else{'Red'}) }
Write-Host ""
Write-Host "  ders ders isabet:"
foreach($k in ($dersIsabet.GetEnumerator()|Sort-Object { -($_.Value.d + $_.Value.y) })){
  $n=$k.Value.d + $k.Value.y; if(-not $n){ continue }
  Write-Host ("    {0,-34} {1,4}/{2,-4} %{3,5:N1}" -f $k.Key,$k.Value.d,$n,(100*$k.Value.d/[double]$n))
}
if($yanlisOrnek.Count){
  Write-Host ""
  Write-Host "  YANLIS ORNEKLER:" -ForegroundColor DarkYellow
  foreach($y in $yanlisOrnek){ Write-Host ("    {0}" -f $y) }
}

$oran=if($karar){ 100*$dogru/[double]$karar } else { 0 }
if($oran -lt 85){
  Write-Host ""
  Write-Host ("⛔ ISABET %{0:N1} < %85 - UYGULAMA YAPILMADI. Kural listesi duzeltilmeli." -f $oran) -ForegroundColor Red
  return
}

# --- AYRISTIR ----------------------------------------------------------------
$cikti=New-Object System.Collections.Generic.List[object]
$cozulen=0; $cozulemeyen=@{}
foreach($z in $kaba){
  $t=DersBul $z.konu
  if($t){ $cozulen++ } else { $cozulemeyen[$z.kaba]=1+[int]$cozulemeyen[$z.kaba] }
  $cikti.Add([ordered]@{ konu=$z.konu; kaba_ders=$z.kaba; ders=$(if($t){$t}else{'(ayristirilamadi)'}); cikmis=$z.cikmis })
}
Write-Host ""
Write-Host ("AYRISTIRILDI: {0:N0} / {1:N0}  (%{2:N1})" -f $cozulen,$kaba.Count,(100*$cozulen/[double]$kaba.Count)) -ForegroundColor Green
$yeniDers=@{}
foreach($c in $cikti){ if($c.ders -ne '(ayristirilamadi)'){ $yeniDers[$c.ders]=1+[int]$yeniDers[$c.ders] } }
foreach($k in ($yeniDers.GetEnumerator()|Sort-Object Value -Descending)){ Write-Host ("  {0,-34} {1,5} konu" -f $k.Key,$k.Value) }
if($cozulemeyen.Count){
  Write-Host ""
  Write-Host "  COZULEMEYEN (kaba kovada kaliyor):" -ForegroundColor DarkYellow
  foreach($k in ($cozulemeyen.GetEnumerator()|Sort-Object Value -Descending)){ Write-Host ("    {0,-40} {1,5}" -f $k.Key,$k.Value) }
}

. (Join-Path $depoKok 'arac\rapor-yaz.ps1')
RaporYaz -Hedef (Join-Path $depoKok 'veri\ders-ayristirma-sgs.json') -Nesne ([ordered]@{
  olcum=(Get-Date -Format 'yyyy-MM-dd HH:mm')
  kural='Anahtar kelime kurallari; gerekce konu adinda. Kural tutmayan konu (ayristirilamadi) kalir - TAHMIN EDILMEZ.'
  geri_sinama=[ordered]@{ karar=$karar; dogru=$dogru; yanlis=$yanlis; isabet_yuzde=[math]::Round($oran,1); esik=85 }
  ayristirilan=$cozulen; toplam=$kaba.Count
  kayitlar=@($cikti | ForEach-Object { [pscustomobject]$_ })
})
Write-Host "`n-> veri/ders-ayristirma.json" -ForegroundColor Green
