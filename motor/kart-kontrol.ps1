# ============================================================================
#  KONU KARTI KONTROLU — 25.08.2026
#  CEM: "kartları 27 kapıdan geçir"
#
#  NEDEN AYRI BETIK: kart ile soru AYRI SEKILLERDE bozulur. Sorunun "sikki",
#  kartin "dali" vardir; sorunun "cevabi", kartin "kapsami" vardir. 27 kapinin
#  bir kismi karta AYNEN uyar (Turkce, fikra atfi, tanimsiz terim, YZ kokusu),
#  bir kismi ANLAMSIZDIR (sik butunlugu, cevap anahtari, aritmetik), bir kismi
#  ise KARTA OZGUDUR ve soruda karsiligi yoktur:
#
#    K1 EKSIK DAL   - kaynak metnindeki dallarin TAMAMI kartta var mi?
#                     (TTK m.55'in ALTI bendi varsa kartta alti dal olmali;
#                      dordunu yazip birakmak konuyu YARIM ogretir)
#    K2 UYDURMA DAL - kartta olup kaynak metninde OLMAYAN dal var mi?
#    K3 KONU UYUMU  - kart istenen konu hakkinda mi (uretici kapisinin aynasi)
#    K4 ZEMIN VAR MI- konunun dayandigi temel kavram aciklanmis mi
#
#  ⚠ KART SORUDAN TEHLIKELIDIR: hatasi tek soruya degil O KONUDAKI BUTUN
#  sorulara dagilir. Bu yuzden esik daha yuksektir: kartta OLDURUCU kusur
#  varsa o konudaki sorular da yayina GIREMEZ.
#
#  Girdi : veri/fabrika/konu-kartlari.json
#  Cikti : veri/fabrika/kart-kontrol-<damga>.json + OKUMA.md
#          veri/kart-kontrol-raporu.json (yalniz SAYI)
# ============================================================================
param(
  [string]$dosya = '',
  [string]$model = 'claude-sonnet-5',
  [switch]$olcum
)
# --- HAT ON KONTROLU (25.08) -------------------------------------------------
# Buyuk/kucuk harf cakismasi bu hatti 25.08'de BES kez sessizce curuttu.
# Cakisma varsa bu betik HIC BASLAMAZ. Kirli olcum > hic olcmemek DEGILDIR.
. (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'hat-onkontrol.ps1')
HatOnKontrol $MyInvocation.MyCommand.Path
# -----------------------------------------------------------------------------
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$kok  = Split-Path -Parent $here
if(-not $env:SUPABASE_SERVICE_KEY){ $env:SUPABASE_SERVICE_KEY = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
if(-not $env:ANTHROPIC_API_KEY){ $env:ANTHROPIC_API_KEY = [Environment]::GetEnvironmentVariable('ANTHROPIC_API_KEY','User') }
if(-not $dosya){ $dosya = Join-Path $kok 'veri/fabrika/konu-kartlari.json' }
if(-not (Test-Path $dosya)){ Write-Host "Kart dosyasi yok: $dosya"; exit 1 }
$raporYol = Join-Path $kok 'veri/kart-kontrol-raporu.json'
function RaporYaz($n){ [IO.File]::WriteAllText($raporYol,(ConvertTo-Json -InputObject $n -Depth 8),(New-Object Text.UTF8Encoding($false))) }
trap {
  RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'; hata="$($_.Exception.Message)"; satir=$_.InvocationInfo.ScriptLineNumber })
  Write-Host ("HATA (satir {0}): {1}" -f $_.InvocationInfo.ScriptLineNumber,$_.Exception.Message); exit 1
}
. (Join-Path $here 'madde-coz.ps1') -kutuphane
Add-Type -AssemblyName System.Net.Http
$hc = New-Object System.Net.Http.HttpClient; $hc.Timeout=[TimeSpan]::FromSeconds(300)

# ------------------------------------------------------------------ ORTAK
function DuzK([string]$t){
  $s="$t".ToLowerInvariant()
  $s=$s -replace '[ıİi]','i' -replace '[şŞ]','s' -replace '[ğĞ]','g' -replace '[üÜ]','u' -replace '[öÖ]','o' -replace '[çÇ]','c'
  $s=$s -replace '[^a-z0-9]',' '
  return ($s -replace '\s+',' ').Trim()
}
# Turkce ASCII bozulmasi — desenler YALNIZ [a-z]; tek Turkce harf eslesmeyi kirar
$KD1 = [regex]('(?i)\b(' + (@('[a-z]+m[i]stir','[a-z]+mustur','[a-z]+lmis','icin','isci[a-z]*','uretim','uretil[a-z]*',
  'sirket[a-z]*','musteri[a-z]*','sozlesme[a-z]*','gorev[a-z]*','donem[a-z]*','gecerli[a-z]*','tutari','degeri',
  'yilinda','karsilig[a-z]*','odenmis','yapilmis','olmustur','bulunmaktadir') -join '|') + ')\b')
$KD5 = [regex]'(?i)\b(asla|her zaman|hi[çc]bir zaman|kesinlikle|istisnas[ıi]z)\b'
$KYZ = [regex]'(?i)(bu ba[ğg]lamda|[öo]nemli bir husus|unutulmamal[ıi]d[ıi]r|sonu[çc] olarak|[öo]zetle\s*,|dikkat edilmesi gereken)'
$KTERIM = @('ticari işletme','iyiniyet','iflasa tabi','basiretli','tescil','emsal bedel','maliyet bedeli',
  'iktisadi kıymet','mukayyet değer','tahakkuk','envanter','objektif koşul','zincirleme','haksız rekabet',
  'genel imal gideri','genel üretim gideri','genel idare gideri','amortisman','ihtiyari','müteferri')

function KartMetni($k){
  $p = @("$($k.baslik)","$($k.zemin.baslik)","$($k.zemin.metin)","$($k.akilda_kalsin)")
  foreach($d in @($k.dallar)){ $p += "$($d.ad)"; $p += "$($d.metin)"; $p += "$($d.tuzak)" }
  foreach($s in @($k.sonuclar)){ $p += "$($s.metin)" }
  if($k.karisir){ $p += "$($k.karisir.komsu)"; foreach($o in @($k.karisir.olcutler)){ $p += "$($o.olcut)"; $p += "$($o.komsu)"; $p += "$($o.konu)" } }
  return ($p -join "`n")
}

# ============================================================================
#  KART KAPISI SINAVI — 25.08.2026   ·   Cem: "1-2-3 yap" (GM onerisi 2)
#  Sayim: motorda 93 karar veren betik, oz-sinavi olan 2. Bu ucuncusu.
#  KURAL: her kapi BILINEN-BOZUK vakayi yakalamali VE BILINEN-TEMIZ vakayi
#  rahat birakmali. Ikincisi en az birincisi kadar onemli - M7 tam bu yuzden
#  bes kartin besinde YANLIS tetiklendi (zorunlu semayi kusur sandi).
#  Sinav duserse kosu durur: kendini kanitlayamayan kapi karar veremez.
# ============================================================================
function SinavKart($dallar,$akilda){
  [pscustomobject]@{
    baslik='Sinav karti'
    zemin=[pscustomobject]@{ baslik='Zemin'; metin='Ticari işletme, esnaf işletmesi sınırını aşan düzeyde gelir sağlamayı hedefleyen faaliyet birimidir. Bu birim sürekli ve bağımsız biçimde yürütülür; kazanç amacı taşır ve ticaret siciline tescil edilir.'; maddeler=@('m.11') }
    karisir=[pscustomobject]@{ komsu='Esnaf'; olcutler=@() }
    dallar=$dallar
    sonuclar=@([pscustomobject]@{ metin='Tacir ticari defter tutmakla yükümlüdür.'; madde='m.18' })
    akilda_kalsin=$akilda
  }
}
function KartKapiSinavi([string]$kaynak){
  $dusen=@()
  $iyiDal = @(
    [pscustomobject]@{ ad='İşletmeyi işleten'; madde='m.12'; metin='Bir ticari işletmeyi kısmen de olsa kendi adına işleten kişi tacirdir.'; tuzak='Kendi adına işletmeyen tacir sayılmaz.' }
    [pscustomobject]@{ ad='İşletmeyi açan'; madde='m.12'; metin='İşletmeyi kurup açıkça ilan eden kişi, fiilen işletmese de tacir sayılır.'; tuzak='İlan yoksa bu yol işlemez.' }
    [pscustomobject]@{ ad='Ticaret ortaklıkları'; madde='m.16'; metin='Ticaret ortaklıkları kuruluşla birlikte tacir sıfatını kazanır.'; tuzak='Adi ortaklık ticaret ortaklığı değildir.' }
  )
  $vakalar=@(
    # --- BILINEN BOZUK
    @{ ad='D7 akilda kalsin yok'; bekle='D7'
       k=(SinavKart $iyiDal '') }
    @{ ad='D7 akilda kalsin 200 karakteri asiyor'; bekle='D7'
       k=(SinavKart $iyiDal (('Tacir sıfatı üç yoldan kazanılır ve her yolun kendi sonucu vardır; bu sonuçlar defter tutma, sicile kayıt ve özenli davranma yükümlülüklerini kapsar. '*3))) }
    @{ ad='D12 uc dal ayni kelimeyle basliyor'; bekle='D12'
       k=(SinavKart @(
          [pscustomobject]@{ ad='A'; madde='m.12'; metin='Bir ticari işletmeyi kendi adına işleten kişi tacirdir.'; tuzak='x' }
          [pscustomobject]@{ ad='B'; madde='m.12'; metin='Bir ticari işletmeyi açan kişi de tacir sayılır.'; tuzak='y' }
          [pscustomobject]@{ ad='C'; madde='m.16'; metin='Bir ticari işletmeyi devralan ortaklık tacirdir.'; tuzak='z' }) 'Tacir üç yoldan olunur.') }
    # --- BILINEN TEMIZ: hicbir deterministik kapi tetiklenmemeli
    @{ ad='TEMIZ kart'; bekle=''
       k=(SinavKart $iyiDal 'Tacir olmanın üç yolu vardır; üçünde de defter tutma yükümlülüğü doğar.') }
  )
  foreach($v in $vakalar){
    # KartKapilari "return ,$b" ile doner: dizi SARMALANMIS gelir ve @() onu
    # ACMAZ. Gercek cagri yeri (asagida) sarmalamadan aldigi icin hat calisiyor;
    # sinav kosumu @() ile sarinca tek elemanli ic ice dizi olusuyordu ve butun
    # bulgular tek dizgede birlesmis gorunuyordu. Once ata, sonra ac.
    $ham = KartKapilari $v.k $kaynak
    $b = @($ham)
    if($b.Count -eq 1 -and $b[0] -is [array]){ $b = @($b[0]) }
    $tipler = @($b | ForEach-Object { ("$_" -split '[\s:]')[0] })
    if($env:KART_SINAV_AYRINTI){
      Write-Host ("    [tani] {0} -> akilda='{1}' dal={2} bulgu={3}" -f $v.ad, "$($v.k.akilda_kalsin)", @($v.k.dallar).Count, $b.Count)
      foreach($bb in $b){ Write-Host "         · $bb" }
    }
    if($v.bekle){
      if($tipler -notcontains $v.bekle){
        $dusen += ("{0}: BEKLENEN '{1}' ISARETLENMEDI (cikan: {2})" -f $v.ad,$v.bekle,$(if($tipler.Count){$tipler -join ','}else{'hicbiri'}))
      }
    } else {
      # TEMIZ vaka: D13 (tanimsiz terim) haric tut - sozluk tabanlidir ve
      # sentetik kisa kartta kacinilmaz tetiklenir; otekiler tetiklenmemeli.
      $kalan = @($tipler | Where-Object { $_ -ne 'D13' })
      if($kalan.Count){ $dusen += ("{0}: TEMIZ VAKA HAKSIZ ISARETLENDI -> {1}" -f $v.ad, ($kalan -join ',')) }
    }
  }
  return $dusen
}
# --------------------------------------------------- DETERMINISTIK KART KAPILARI
function KartKapilari($k, [string]$kaynakMetni){
  $b = @()
  $hepsi = KartMetni $k

  # KD1 Turkce
  $iz=@(); foreach($m in $KD1.Matches($hepsi)){ if($iz -notcontains $m.Value){ $iz += $m.Value } }
  if($iz.Count){ $b += "D1 turkce-bozuk: " + (($iz|Select-Object -First 5) -join ', ') }

  # KD5 mutlak terim — hukuk kartinda "asla/her zaman" neredeyse hep yanlistir
  foreach($m in $KD5.Matches($hepsi)){ $b += "D5 mutlak-terim: `"$($m.Value)`"" ; break }

  # KD7 akilda kalsin uzunlugu
  $ak = "$($k.akilda_kalsin)"
  if(-not $ak.Trim()){ $b += 'D7 akilda-kalsin-yok' }
  elseif($ak.Length -gt 200){ $b += "D7 akilda-kalsin-uzun:$($ak.Length)" }

  # KD9 fikra atfi uydurma — kaynak metni numaralandirma tasimiyorsa m.X/Y olamaz
  $fikraNo=@()
  foreach($m in [regex]::Matches($kaynakMetni,'\(\s*([1-9]\d?)\s*\)')){ $n=$m.Groups[1].Value; if($fikraNo -notcontains $n){ $fikraNo+=$n } }
  $fikraliMi = ($kaynakMetni -match '(?i)MADDE\s*\d+\s*[-–]\s*\(\s*1\s*\)') -or ($fikraNo.Count -ge 2)
  foreach($m in [regex]::Matches($hepsi,'(?i)\bm(?:adde)?\.?\s*(\d{1,4})\s*/\s*(\d{1,2})')){
    if(-not $fikraliMi){ $b += "D9 fikra-atfi-uydurma: $($m.Value) (kaynakta fikra numarasi YOK)" }
    elseif($fikraNo -notcontains $m.Groups[2].Value){ $b += "D9 fikra-yok: $($m.Value) (metindeki fikralar: $($fikraNo -join ','))" }
  }

  # KD12 dallar ayni iskeletle mi yazilmis
  $imza=@{}
  foreach($d in @($k.dallar)){
    $kel = @((DuzK "$($d.metin)") -split ' ' | Where-Object { $_ })
    if($kel.Count -lt 4){ continue }
    $im = (@($kel[0..1]) -join ' ')
    if($imza.ContainsKey($im)){ $imza[$im]++ } else { $imza[$im]=1 }
  }
  foreach($x in $imza.GetEnumerator()){ if($x.Value -ge 3){ $b += "D12 ayni-iskelet: $($x.Value) dal ayni basliyor -> `"$($x.Key)...`"" } }

  # KD13 tanimsiz terim — kartin BUTUN AMACI konuyu sifirdan ogretmek
  $tanimsiz=@()
  foreach($tr in $KTERIM){
    $mm=[regex]::Match($hepsi,'(?i)'+[regex]::Escape($tr))
    if(-not $mm.Success){ continue }
    $son=$hepsi.Substring([Math]::Min($mm.Index+$mm.Length,$hepsi.Length))
    $pen=$son.Substring(0,[Math]::Min(220,$son.Length))
    if($pen -match '(?i)(\byani\b|—|–|\(|:\s|\bdemek\b|\bifade eder\b|\bdir\b|\bdur\b)'){ continue }
    if($tanimsiz -notcontains $tr){ $tanimsiz += $tr }
  }
  if($tanimsiz.Count){ $b += "D13 tanimsiz-terim: " + (($tanimsiz|Select-Object -First 4) -join ', ') }

  # KD-YZ kalip dil
  foreach($m in $KYZ.Matches($hepsi)){ $b += "M7 yz-kalibi: `"$($m.Value)`"" ; break }

  # KD14 TEKRAR DONGUSU (25.08 — uretilen Tacir kartinda yakalandi)
  # Model KARISIR alaninda "ekonomik faaliyet sermaye agirliklidir" cumlesini
  # 19 KEZ tekrarlamis, aralarinda bozuk yazimlarla ("ononomik"). Bu klasik
  # uretim cokusu (degeneration) ve BARIZ - model kapisina birakilmaz, cunku
  # model kendi ciktisini "yz kokusu" diye rapor etmek zorunda kalir. Makine
  # sayarak bulur: ayni dort kelimelik dizi 4+ kez tekrarliyorsa donguye girmis.
  $alanlar = New-Object System.Collections.Generic.List[object]
  $alanlar.Add(@{ ad='zemin'; m="$($k.zemin.metin)" })
  $alanlar.Add(@{ ad='akilda_kalsin'; m="$($k.akilda_kalsin)" })
  foreach($d in @($k.dallar)){ $alanlar.Add(@{ ad="dal:$($d.ad)"; m="$($d.metin) $($d.tuzak)" }) }
  foreach($s in @($k.sonuclar)){ $alanlar.Add(@{ ad='sonuc'; m="$($s.metin)" }) }
  if($k.karisir){ foreach($o in @($k.karisir.olcutler)){
    $alanlar.Add(@{ ad="karisir:$($o.olcut)"; m="$($o.komsu) $($o.konu)" }) } }
  foreach($a in $alanlar){
    $kel = @((DuzK $a.m) -split ' ' | Where-Object { $_ })
    if($kel.Count -lt 12){ continue }
    $say=@{}
    for($i=0; $i -le $kel.Count-4; $i++){
      $d4 = ($kel[$i..($i+3)] -join ' ')
      if($say.ContainsKey($d4)){ $say[$d4]++ } else { $say[$d4]=1 }
    }
    $enCok = $say.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1
    if($enCok -and $enCok.Value -ge 4){
      $b += ("D14 TEKRAR-DONGUSU: [{0}] `"{1}`" {2} kez tekrarlanmis" -f $a.ad,$enCok.Key,$enCok.Value)
    }
  }

  # K4 ZEMIN
  if(-not "$($k.zemin.metin)".Trim()){ $b += 'K4 zemin-yok (konunun temel kavrami aciklanmamis)' }
  elseif("$($k.zemin.metin)".Length -lt 120){ $b += "K4 zemin-cok-kisa:$("$($k.zemin.metin)".Length) karakter" }

  # K3 KONU UYUMU
  $ist = @((DuzK ($k.konu)) -split ' ' | Where-Object { $_.Length -ge 4 })
  $gel = @((DuzK ($k.baslik)) -split ' ' | Where-Object { $_.Length -ge 4 })
  if($ist.Count -and $gel.Count){
    $ortak = @($gel | Where-Object { $ist -contains $_ })
    if(-not $ortak.Count){ $b += "K3 konu-uyumsuz: konu `"$($k.konu)`" ama baslik `"$($k.baslik)`"" }
  }

  # Dal sayisi mantik denetimi
  if(@($k.dallar).Count -lt 2){ $b += "K1 dal-az: $(@($k.dallar).Count)" }
  return ,$b
}

# ------------------------------------------------------------------ SOZLESME
function NesneK($g,$o){ @{ type='object'; additionalProperties=$false; required=$g; properties=$o } }
$S=@{type='string'}; $B=@{type='boolean'}
$kartSema = NesneK @('kapsam_tam','eksik_dallar','uydurma_dallar','alinti','celiski','celiski_nerede',
                     'sifirdan_ogretiyor','ogretme_bosluklari','terim_acik','tanimsiz_terimler',
                     'guncel','yz_kokusu','hukum','gerekce') ([ordered]@{
  kapsam_tam         = $B; eksik_dallar = $S
  uydurma_dallar     = $S
  alinti             = $S       # kaynak metninden BIREBIR - makine dogrular
  celiski            = $B; celiski_nerede = $S
  sifirdan_ogretiyor = $B; ogretme_bosluklari = $S
  terim_acik         = $B; tanimsiz_terimler = $S
  guncel             = $B
  yz_kokusu          = $S
  hukum              = @{ type='string'; enum=@('uygun','kusurlu','olculemedi') }
  gerekce            = $S
})

$ISTEM = @'
Bir muhasebe meslek sınavı bankasının KONU KARTI HAKEMİSİN.

KART NEDİR: adayın soruyu görmeden önce okuduğu, konuyu SIFIRDAN öğreten kart.
Hedef kitle: o konuyu HİÇ BİLMEYEN aday.

⚠ KART SORUDAN TEHLİKELİDİR: yanlışsa hata tek soruya değil, o konudaki BÜTÜN
sorulara dağılır. Bu yüzden eşik yüksektir.

PAZARLIKSIZ
1. YALNIZ sana verilen kaynak metinlerine dayan. Hafızandan kural tamamlama.
2. "alinti" alanına, hükmünü dayandırdığın cümleyi kaynak metninden BİREBİR
   kopyala. Makineyle denetlenir; metinde geçmiyorsa hükmün çöpe atılır.
   Metin hüküm vermeye yetmiyorsa hukum = "olculemedi", alinti = "".
3. Emin olmadığına kusur deme; "olculemedi" üçüncü sonuçtur.

NEYE BAKACAKSIN
- kapsam_tam: kaynak metnindeki dalların/hâllerin TAMAMI kartta var mı?
  Metin altı bent sayıyorsa kartta altı dal olmalı. Dördünü yazıp bırakmak
  konuyu YARIM öğretir ve aday sınavda eksik dalla karşılaşır.
  Eksikleri eksik_dallar alanına tek tek yaz.
- uydurma_dallar: kartta olup kaynak metninde OLMAYAN dal/hüküm var mı?
- celiski: kart kendi içinde ya da kaynak metniyle çelişiyor mu?
- sifirdan_ogretiyor: konuyu HİÇ BİLMEYEN biri bu kartı okuyunca konuyu
  öğrenir mi? Yoksa zaten bilene hatırlatma mı? Boşlukları yaz.
- terim_acik: kartta geçen meslek terimleri açıklanmış mı? Açıklanmayanları yaz.
- guncel: kaynak metninde değişiklik izi varsa ("...ibaresi ... değiştirilmiştir")
  kart değişiklik SONRASI hâlle uyumlu mu?
- yz_kokusu: kalıp DİL, dalların aynı CÜMLE İSKELETİYLE yazılması, suni simetri.
  ⚠ ZORUNLU ŞEMAYI KUSUR SAYMA. Kart şemasında her dalın "tuzak" alanı
  ZORUNLUDUR; bu yüzden her dalda bir TUZAK satırı GÖRÜNÜR. Aynı şekilde
  ZEMİN/KARIŞIR/DALLAR/SONUÇLAR düzeni ve KARIŞIR bölümündeki
  [komsu]/[konu] karşılaştırma sütunları da şartnamenin dayattığı yapıdır.
  "Her dal TUZAK ile bitiyor" ya da "her dal aynı bölüm sırasını izliyor"
  KUSUR DEĞİLDİR — istenen düzendir.
  (ÖLÇÜLDÜ 25.08: bu ayrım yapılmadığı için M7 beş kartın BEŞİNDE de
   tetiklendi ve gerekçe her seferinde 'her dal TUZAK: ile bitiyor' oldu.
   Kapı, kendi şemamızı kusur sanıyordu. Aynı sınıf hata soru hattında da
   olmuştu: M7, zorunlu 'Ne soruluyor / Kural / Bu olayda / Akılda kalsın'
   düzenini yz kokusu saymıştı.)
  ARADIĞIN ŞEY DİLDE: aynı bağlaçların tekrarı, "önemli bir husus" türü
  boş kalıplar, her cümlenin aynı uzunlukta ve aynı ritimde olması,
  içerik taşımayan simetrik doldurma. Bunları bulursan yaz; bulamazsan
  yz_kokusu alanını BOŞ bırak. İskelet aynı diye kusur yazma.
  Bulduklarını yaz, yoksa "".

HÜKÜM
Yukarıdakilerden biri bile bozuksa "kusurlu". Metin yetmiyorsa "olculemedi".
Hepsi temizse "uygun". gerekce: tek cümle, somut.
'@

# ------------------------------------------------------------------ KOSU
$kartlar = @((Get-Content $dosya -Raw -Encoding UTF8 | ConvertFrom-Json))
Write-Host ("Kart: {0}  <- {1}" -f $kartlar.Count,(Split-Path $dosya -Leaf))
$sonuc = New-Object System.Collections.Generic.List[object]
$jG=0;$jC=0
$AY='https://api.anthropic.com/v1/messages'

# --- KAPI SINAVI: olcum baslamadan ONCE, 0 USD -------------------------------
# Kendini kanitlayamayan kapi karar veremez. Sinav duserse hicbir kart
# olculmez - supheli olcum, olcumsuzlukten daha zararlidir.
Write-Host ''
Write-Host 'Kapi sinavi...'
$sinavKaynak = 'MADDE 12 - (1) Bir ticari isletmeyi kismen de olsa kendi adina isleten kisiye tacir denir. (2) Bir ticari isletmeyi kurup acikca ilan eden kisi, fiilen islemeye baslamamis olsa da tacir sayilir. MADDE 16 - (1) Ticaret sirketleri tacir sayilir. MADDE 11 - (1) Ticari isletme, esnaf isletmesi icin ongorulen siniri asan duzeyde gelir saglamayi hedef edinen faaliyetlerin surekli ve bagimsiz sekilde yurutuldugu isletmedir. MADDE 18 - (1) Tacir her turlu borcu icin iflasa tabidir; ticari defter tutmakla yukumludur.'
$kapiDusen = @(KartKapiSinavi $sinavKaynak)
if($kapiDusen.Count){
  Write-Host ''
  Write-Host '  !! KART KAPISI KENDI SINAVINDAN DUSTU:' -ForegroundColor Red
  foreach($d in $kapiDusen){ Write-Host "     $d" }
  Write-Host ''
  Write-Host '  Kosu durduruldu. Kirli olcum uretmektense hic olcmemek yeglenir.'
  RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='KAPI SINAVI DUSTU'; dusen=$kapiDusen })
  exit 1
}
Write-Host '  4/4 vaka gecti (3 bilinen-bozuk yakalandi, 1 bilinen-temiz rahat birakildi)'
# 25.08 DERSI: sinav yalniz SINADIGI dali korur. Neyin kanitlanmadigi yazilir.
Write-Host '  SINANMAYAN DALLAR: D1 turkce · D5 mutlak terim · D9 fikra atfi · D13 tanimsiz terim · K1-K4 (hakem dali, model cagirir) · kaynak cozme'

foreach($k in $kartlar){
  Write-Host ''
  Write-Host ("=== {0}  {1}" -f $k.id,$k.baslik)
  # kaynak metinleri
  $blok=''; $tumMetin=''
  foreach($kk in @($k.dayanaklar)){
    $c = KaynakCoz $kk $k.konu
    if($c.durum -notlike 'cozuldu*'){ Write-Host ("   !! kaynak cozulemedi: {0} ({1})" -f $kk,$c.durum); continue }
    $t="$($c.metin)"; $tumMetin += "`n$t"
    if($t.Length -gt 9000){ $t=$t.Substring(0,6000)+"`n[...orta atlandi...]`n"+$t.Substring($t.Length-3000) }
    $blok += "`n=== $kk ===`n$t`n"
  }
  $dBulgu = KartKapilari $k $tumMetin
  if($dBulgu.Count){ Write-Host ("   D: {0}" -f (($dBulgu|Select-Object -First 3) -join ' | ')) }

  if($olcum -or -not $env:ANTHROPIC_API_KEY -or -not $blok){
    $sonuc.Add([ordered]@{ id=$k.id; baslik=$k.baslik; ders=$k.ders; konu=$k.konu
      deterministik=$dBulgu; icerik=$null; hukum=$(if($dBulgu.Count){'kusurlu'}else{'olculemedi'}); not='olcum modu' })
    continue
  }

  # kart metnini modele oku
  $kartYazi = "BASLIK: $($k.baslik)`nZEMIN — $($k.zemin.baslik): $($k.zemin.metin)`n"
  if($k.karisir -and "$($k.karisir.komsu)".Trim()){
    $kartYazi += "KARISIR — $($k.karisir.komsu):`n"
    foreach($o in @($k.karisir.olcutler)){ $kartYazi += "   · $($o.olcut): [komsu] $($o.komsu) | [konu] $($o.konu)`n" }
  }
  $kartYazi += "DALLAR:`n"
  foreach($d in @($k.dallar)){ $kartYazi += "   · $($d.ad) ($($d.madde)): $($d.metin)`n"; if("$($d.tuzak)".Trim()){ $kartYazi += "     TUZAK: $($d.tuzak)`n" } }
  if(@($k.sonuclar).Count){ $kartYazi += "SONUCLAR:`n"; foreach($s in @($k.sonuclar)){ $kartYazi += "   · $($s.metin) ($($s.madde))`n" } }
  $kartYazi += "AKILDA KALSIN: $($k.akilda_kalsin)`n"

  $denetimIstemi = $ISTEM + "`n`n=== KAYNAK METINLERI ===$blok`n`n=== DENETLENECEK KART ===`n$kartYazi"
  $govde = @{ model=$model; max_tokens=8000; messages=@(@{role='user';content=$denetimIstemi})
              output_config=@{ effort='high'; format=@{ type='json_schema'; schema=$kartSema } } } | ConvertTo-Json -Depth 16
  $j=$null
  for($d=1;$d -le 3;$d++){
    $ic=New-Object System.Net.Http.StringContent($govde,[Text.Encoding]::UTF8,'application/json')
    $ist=New-Object System.Net.Http.HttpRequestMessage('POST',$AY); $ist.Content=$ic
    $ist.Headers.Add('x-api-key',$env:ANTHROPIC_API_KEY); $ist.Headers.Add('anthropic-version','2023-06-01')
    $ist.Headers.ConnectionClose=$true
    try{
      $yn=$hc.SendAsync($ist).GetAwaiter().GetResult()
      $ham=[Text.Encoding]::UTF8.GetString($yn.Content.ReadAsByteArrayAsync().GetAwaiter().GetResult())
      if(-not $yn.IsSuccessStatusCode){ Write-Host ("   API {0}: {1}" -f [int]$yn.StatusCode,$ham.Substring(0,[Math]::Min(200,$ham.Length))); break }
      $cv=$ham|ConvertFrom-Json; $jG+=[int]$cv.usage.input_tokens; $jC+=[int]$cv.usage.output_tokens
      $mb=($cv.content|Where-Object{$_.type -eq 'text'}|Select-Object -First 1).text
      if($mb){ $j=$mb|ConvertFrom-Json }
      break
    } catch { if($d -eq 3){ Write-Host ("   TASIMA: {0}" -f $_.Exception.Message) } else { Start-Sleep -Seconds (2*$d) } }
  }
  if($null -eq $j){
    $sonuc.Add([ordered]@{ id=$k.id; baslik=$k.baslik; ders=$k.ders; konu=$k.konu; deterministik=$dBulgu; icerik=$null; hukum='olculemedi'; not='icerik cagrisi basarisiz' })
    continue
  }

  # HAKEMIN HAKEMI
  $al = DuzK "$($j.alinti)"; $alNot=''; $alTamam=$true
  if($al.Length -ge 20){
    if((DuzK $tumMetin).Contains($al)){ $alNot='alinti dogrulandi' }
    else { $alTamam=$false; $alNot='ALINTI KAYNAKTA GECMIYOR - hukum cope atildi' }
  } elseif("$($j.hukum)" -ne 'olculemedi'){ $alTamam=$false; $alNot='alinti yok/kisa - hukum dayanaksiz' }

  $ik=@()
  if(-not $j.kapsam_tam){ $ik += "K1 EKSIK DAL: $($j.eksik_dallar)" }
  if("$($j.uydurma_dallar)".Trim()){ $ik += "K2 UYDURMA DAL: $($j.uydurma_dallar)" }
  if($j.celiski){ $ik += "M3 celiski: $($j.celiski_nerede)" }
  if(-not $j.sifirdan_ogretiyor){ $ik += "M6 SIFIRDAN OGRETMIYOR: $($j.ogretme_bosluklari)" }
  if(-not $j.terim_acik){ $ik += "D13 tanimsiz terim: $($j.tanimsiz_terimler)" }
  if(-not $j.guncel){ $ik += 'M8 mevzuat-eskimis' }
  if("$($j.yz_kokusu)".Trim()){ $ik += "M7 yz-kokusu: $($j.yz_kokusu)" }

  $hukum = if(-not $alTamam){ 'olculemedi' } elseif($dBulgu.Count -or $ik.Count){ 'kusurlu' } else { 'uygun' }
  Write-Host ("   -> {0}{1}" -f $hukum.ToUpper(), $(if($ik.Count){" ($($ik.Count) icerik kusuru)"}else{''}))
  $sonuc.Add([ordered]@{ id=$k.id; baslik=$k.baslik; ders=$k.ders; konu=$k.konu
    deterministik=$dBulgu; icerik=$ik; alinti_denetimi=$alNot; gerekce="$($j.gerekce)"; hukum=$hukum })
}

$uygun=@($sonuc|Where-Object{$_.hukum -eq 'uygun'})
$kusur=@($sonuc|Where-Object{$_.hukum -eq 'kusurlu'})
$olcme=@($sonuc|Where-Object{$_.hukum -eq 'olculemedi'})
$TAN=[datetime]'2026-08-31'
if((Get-Date) -le $TAN -and $model -like 'claude-sonnet-5*'){ $fg=2.0;$fc=10.0 } else { $fg=3.0;$fc=15.0 }
$usd=($jG/1e6*$fg)+($jC/1e6*$fc)

Write-Host ''
Write-Host '================ KART HUKMU ================'
Write-Host ("  UYGUN      : {0}" -f $uygun.Count)
Write-Host ("  KUSURLU    : {0}" -f $kusur.Count)
Write-Host ("  OLCULEMEDI : {0}" -f $olcme.Count)
Write-Host ''
foreach($x in $sonuc){
  Write-Host ("--- {0} {1}  [{2}]" -f $x.id,$x.baslik,$x.hukum.ToUpper())
  foreach($bb in @($x.deterministik)){ Write-Host ("      D  {0}" -f $bb) }
  foreach($bb in @($x.icerik)){ Write-Host ("      M  {0}" -f $bb) }
  if($x.gerekce){ Write-Host ("      gerekce: {0}" -f $x.gerekce) }
}
Write-Host ''
Write-Host ("FATURA: {0:N4} USD  (giris {1:N0} + cikis {2:N0})" -f $usd,$jG,$jC)

$damga=Get-Date -Format 'yyyyMMdd-HHmm'
$cikti=Join-Path $kok "veri/fabrika/kart-kontrol-$damga.json"
$duz=@(); foreach($r in $sonuc){ $duz += ,([pscustomobject]$r) }
[IO.File]::WriteAllText($cikti,(ConvertTo-Json -InputObject $duz -Depth 8),(New-Object Text.UTF8Encoding($false)))
Write-Host ("-> {0}" -f $cikti)
RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='TAMAM'; model=$model
  toplam=$sonuc.Count; uygun=$uygun.Count; kusurlu=$kusur.Count; olculemedi=$olcme.Count
  fatura=[ordered]@{ giris=$jG; cikis=$jC; usd=[math]::Round($usd,4) } })
Write-Host '-> veri/kart-kontrol-raporu.json'
