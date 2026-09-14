#requires -Version 5.1
# ============================================================================
#  KGK KAYNAK ÖLÇÜMÜ — konu × resmî metin × tamlık                  (BEDEL 0)
#
#  NEDEN (14.09.2026, Cem): bir haftalık KGK basım sprinti öncesi "hangi konunun
#  kaynağı ambarda VAR, hangisi YOK" ölçülür; kaynağı olmayan konuya üretim hattı
#  açılmaz. Cem şartı: "tüm yerlerde resmî metin olması ve metnin tam olması".
#  Ret kütüğünde KGK retlerinin yarıya yakını KAYNAK-EKSIK (paket hükmü taşımıyor).
#
#  ESKİ KARNE NEDEN YETMEDİ: veri/konu-kaynak-karnesi-kgk.json "URET" kararını
#  tüm ambarda iki anahtar kelimenin geçmesine bağlıyor ("kurulus + banka" -> 956
#  kayıt). Kaynağın hangi metin olduğu, resmî mi özet mi olduğu, tam mı olduğu
#  ölçülmüyor. Bu betik konuyu BEKLENEN RESMÎ METNE bağlar ve o metni ölçer.
#
#  NE YAPAR (yalnız okuma; ambara, kasaya, soruya YAZMAZ):
#   1) dokumanlar(id,tur,kaynak_ad) listesini id sıralı anahtar sayfalamayla çeker
#   2) KGK'nın 8 dersi için tanımlı kaynak ailelerinin satırlarını id=in.() ile
#      indirir (önbellek: veri/fabrika/kosucu-log/, git'e girmez)
#   3) aile başına: parça · karakter · RESMÎ oranı (Türkçe harf + büyük harf
#      ölçütü; elle yazılmış ASCII özet ayrılır) · madde/paragraf deliği ·
#      [k/n] bölünmüş parça eksiği · kesik adayı
#   4) kota konu satırı (veri/kgk-uretim-kotasi.json) başına: beklenen aile +
#      hüküm anahtar kelimesi ailenin İÇİNDE aranır (tüm ambarda değil)
#   5) çıkmış arşiv konuları (veri/kgk-analiz.json) kota satırlarına dağıtılır
#   6) sınıf: HAZIR / ZAYIF / YOK (+ ÖLÇÜLMEDİ: sorgu hatası ya da aile tanımsız)
#
#  Kullanım : powershell -NoProfile -File arac/kgk-kaynak-olcumu.ps1 [-Tazele]
#             -Tazele yoksa önbellek (varsa) kullanılır, ambara gidilmez.
#  Çıktı    : veri/kgk-kaynak-olcumu.json (RaporYaz — içerik aynıysa dokunmaz)
#  Yük      : ~47 hafif sayfa + aile satırları 80'lik partilerle; her sayfa
#             süresi ölçülür, 5 sn'yi aşan sayfada betik DURUR (ambar-nabız kuralı).
# ============================================================================
param([switch]$Tazele)
$ErrorActionPreference='Stop'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$depoKok=Split-Path -Parent $PSScriptRoot
. (Join-Path $depoKok 'arac\rapor-yaz.ps1')
$onbellekDizini=Join-Path $depoKok 'veri\fabrika\kosucu-log'
New-Item -ItemType Directory -Force $onbellekDizini | Out-Null
$adOnbellek=Join-Path $onbellekDizini 'kgk-kaynak-adlar.json'
$metinOnbellek=Join-Path $onbellekDizini 'kgk-kaynak-metinler.json'
$hedefYol=Join-Path $depoKok 'veri\kgk-kaynak-olcumu.json'

$servisAnahtari="$($env:SUPABASE_SERVICE_KEY)".Trim()
if(-not $servisAnahtari){ $servisAnahtari="$([Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User'))".Trim() }
$istekBasliklari=@{ apikey=$servisAnahtari; Authorization="Bearer $servisAnahtari"; Accept='application/json'; 'User-Agent'='mevzuat-radar-robot/1.0' }
$restTabani='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/'

function Katla([string]$hamMetin){
  if(-not $hamMetin){ return '' }
  $katliMetin=$hamMetin.Replace([string][char]0x0130,'i').ToLowerInvariant()
  $katliMetin=$katliMetin.Replace([string][char]0x00E7,'c').Replace([string][char]0x011F,'g').Replace([string][char]0x0131,'i').Replace([string][char]0x00F6,'o').Replace([string][char]0x015F,'s').Replace([string][char]0x00FC,'u').Replace([string][char]0x00E2,'a').Replace([string][char]0x00EE,'i').Replace([string][char]0x00FB,'u').Replace([string][char]0x0307,'')
  return $katliMetin
}

function GetirSayfa([string]$yolMetni){
  for($denemeSirasi=1;$denemeSirasi -le 3;$denemeSirasi++){
    $sureOlcer=[Diagnostics.Stopwatch]::StartNew()
    try{
      $donenVeri=Invoke-RestMethod -Uri ($restTabani+$yolMetni) -Headers $istekBasliklari -TimeoutSec 60
      $gecenSn=$sureOlcer.Elapsed.TotalSeconds
      if($gecenSn -gt 5){ throw "AMBAR YAVAŞ: sayfa $([math]::Round($gecenSn,1)) sn (>5) — ağır okuma durduruldu" }
      return ,@($donenVeri)
    }catch{
      if("$($_.Exception.Message)" -like 'AMBAR YAVAŞ*'){ throw }
      if($denemeSirasi -eq 3){ throw "sorgu 3 denemede okunamadı: $($_.Exception.Message)" }
      Start-Sleep -Seconds (3*$denemeSirasi)
    }
  }
}

# ---------------------------------------------------------------- 1) ad listesi
if($Tazele -or -not (Test-Path $adOnbellek)){
  $adSatirlari=New-Object System.Collections.Generic.List[object]
  $sonAnahtar=''
  while($true){
    $ekFiltre= if($sonAnahtar){ "&id=gt.$sonAnahtar" } else { '' }
    $sayfaSatirlari=GetirSayfa "dokumanlar?select=id,tur,kaynak_ad&order=id.asc&limit=1000$ekFiltre"
    foreach($tekSatir in $sayfaSatirlari){ $adSatirlari.Add($tekSatir) }
    if($sayfaSatirlari.Count -lt 1000){ break }
    $sonAnahtar=$sayfaSatirlari[-1].id
    Start-Sleep -Milliseconds 250
  }
  [IO.File]::WriteAllText($adOnbellek,(ConvertTo-Json -InputObject $adSatirlari.ToArray() -Compress -Depth 3),(New-Object Text.UTF8Encoding($false)))
}
$adDizisi=Get-Content $adOnbellek -Raw -Encoding UTF8 | ConvertFrom-Json
$adOlcumZamani=(Get-Item $adOnbellek).LastWriteTime.ToString('dd.MM.yyyy HH:mm')
foreach($adSatiri in $adDizisi){ $adSatiri | Add-Member -NotePropertyName katli -NotePropertyValue (Katla "$($adSatiri.kaynak_ad)") -Force }
Write-Host "ambar satırı: $($adDizisi.Count) (ad listesi $adOlcumZamani)"

# ---------------------------------------------------------------- 2) kaynak aileleri
# desen = KATLANMIŞ kaynak_ad üzerinde regex. resmi = aile resmî metin mi olmalı
# (teori notu ailesi resmî değildir; HAZIR olamaz). ad = raporda görünen ad.
$aileler=[ordered]@{}
function AileEkle([string]$aileKodu,[string]$gorunenAd,[string]$adDeseni,[string]$aileTuru='resmi',[string]$turSarti=''){
  $script:aileler[$aileKodu]=[pscustomobject]@{ kod=$aileKodu; ad=$gorunenAd; desen=$adDeseni; tur=$aileTuru; turSarti=$turSarti }
}
foreach($stdNo in 1,2,7,8,10,12,16,19,20,21,23,24,26,27,28,29,32,33,34,36,37,38,40,41){ AileEkle "TMS $stdNo" "TMS $stdNo" "^tms $stdNo(?![0-9])" }
foreach($stdNo in 1,2,3,5,7,8,9,10,11,12,13,15,16,17,18){ AileEkle "TFRS $stdNo" "TFRS $stdNo" "^tfrs $stdNo(?![0-9])" }
AileEkle 'BOBI FRS' 'BOBİ FRS' '^bobi frs'
foreach($stdNo in 200,210,220,230,240,250,260,265,300,315,320,330,402,450,500,501,505,510,520,530,540,550,560,570,580,600,610,620,700,701,705,706,710,720){ AileEkle "BDS $stdNo" "BDS $stdNo" "^bds $stdNo(?![0-9])" }
AileEkle 'BDY' 'Bağımsız Denetim Yönetmeliği' '^bagimsiz denetim yonetmeligi'
AileEkle '660 KHK' 'KGK Kuruluş KHK (660 s.)' '^kgk kurulus khk'
AileEkle 'ETIK' 'Bağımsız Denetçiler için Etik Kurallar' '^etik kurallar'
AileEkle 'KYS 1' 'KYS 1' '^kys 1(?![0-9])'
AileEkle 'II-17.1' 'Kurumsal Yönetim Tebliği (II-17.1)' 'kurumsal yonetim tebligi \(ii-17\.1\)'
AileEkle 'FY-TEORI' 'Finansal Yönetim teori notları (resmî metin DEĞİL)' '(oran|paranin zaman|isletme sermayesi|calisma sermayesi|nakit donus|sermaye maliyeti|wacc|sermaye butcelemesi|kaldirac|basabas|tahvil|faiz|finansal piyasa|risk getiri|portfoy|sharpe|capm|finansman kaynak|finansal kiralama|temettu|kar payi|eldeki kus|turev|opsiyon|black-scholes|vadeli islem|sermaye yapisi|hisse senedi|pay senedi|finansal yonetim|finansal planlama|doviz kuru riski)' 'teori' 'teori-notu'
AileEkle 'KY-TEORI' 'Kurumsal yönetim teori notları (resmî metin DEĞİL)' '(kurumsal yonetim|menfaat sahipleri|pay sahipligi|kamuyu aydinlatma)' 'teori' 'teori-notu'
AileEkle '6361' 'Finansal Kiralama, Faktoring, Finansman ve Tasarruf Finansman Şirketleri K. (6361)' '6361 s\.k'
AileEkle '6362' 'Sermaye Piyasası K. (6362)' '^sermaye piyasasi k\. \(6362'
AileEkle 'BORSA-YON' 'Borsalar ve Piyasa İşleticilerinin Kuruluş… Yönetmeliği' 'borsalar ve piyasa isleticilerinin'
AileEkle 'II-5.2' 'Sermaye Piyasası Araçlarının Satışı Tebliği (II-5.2)' '(araclarinin satisi tebligi \(ii-5\.2\))'
AileEkle 'II-5.1' 'İzahname ve İhraç Belgesi Tebliği (II-5.1)' 'izahname ve ihrac belgesi tebligi'
AileEkle 'VII-128.8' 'Borçlanma Araçları Tebliği (VII-128.8)' 'borclanma araclari tebligi \(vii-128\.8\)'
AileEkle 'II-18.1' 'Kayıtlı Sermaye Sistemi Tebliği (II-18.1)' 'kayitli sermaye sistemi tebligi'
AileEkle '5411' 'Bankacılık K. (5411)' '^bankacilik k\. \(5411'
AileEkle 'VYS-YON' 'Varlık Yönetim Şirketlerinin Kuruluş ve Faaliyet Esasları Yön.' 'varlik yonetim sirketlerinin kurulus'
AileEkle 'BBD-YON' 'Bankaların Bağımsız Denetimi Hakkında Yön.' '^bankalarin bagimsiz denetimi hakkinda'
AileEkle 'KREDI-YON' 'Bankaların Kredi İşlemlerine İlişkin Yön.' 'bankalarin kredi islemlerine iliskin'
AileEkle 'BANKA-THP' 'Bankaların Tekdüzen Hesap Planı Yön. + THP izahname' '(bankalarin tekduzen hesap plani|^bddk thp)'
AileEkle 'SY-YON' 'Bankaların Sermaye Yeterliliğinin Ölçülmesine… Yön.' 'bankalarin sermaye yeterliliginin'
AileEkle 'KSK-YON' 'Kredilerin Sınıflandırılması ve Karşılıklar Yön.' 'kredilerin siniflandirilmasi ve karsiliklar'
AileEkle 'SORUNLU-REH' 'BDDK Sorunlu Alacak Çözümleme Rehberi' 'sorunlu alacak'
AileEkle 'IC-SIS-BANKA' 'Bankaların İç Sistemleri ve İSEDES Yön.' 'bankalarin ic sistemleri'
AileEkle '5684' 'Sigortacılık K. (5684)' '^sigortacilik k\. \(5684'
AileEkle '4632' 'Bireysel Emeklilik Tasarruf ve Yatırım Sistemi K. (4632)' '^bes k\. \(4632'
AileEkle 'TK-YON' 'Sigorta… Teknik Karşılıklarına… Yön.' 'teknik karsiliklarina'
AileEkle 'TTK-SORUMLULUK' 'TTK m.1473-1486 (sorumluluk sigortaları)' '^ttk \(6102 s\.k\.\) m\.14(7[3-9]|8[0-6])(?![0-9])'
AileEkle 'TTK-HAYAT' 'TTK m.1487-1520 (hayat sigortaları)' '^ttk \(6102 s\.k\.\) m\.1(48[7-9]|49[0-9]|50[0-9]|51[0-9]|520)(?![0-9])'
AileEkle 'IC-SIS-SIGORTA' 'Sigorta ve Reasürans ile Emeklilik Şirketlerinin İç Sistemlerine İlişkin Yön.' '(sigorta|emeklilik).*ic sistem'
AileEkle 'DEVLET-KATKI-YON' 'Bireysel Emeklilik Sisteminde Devlet Katkısı Hakkında Yön.' 'devlet katkisi hakkinda'
AileEkle 'TSRS 1' 'TSRS 1' '^tsrs 1(?![0-9])'
AileEkle 'TSRS 2' 'TSRS 2 (+ 28.07.2026 değişiklikleri)' '^tsrs 2(?![0-9])'
AileEkle 'TSRS-KAPSAM' 'KGK sürdürülebilirlik raporlaması kapsam kararı' '(surdurulebilirlik raporlamasina tabi|tsrs.*kapsam.*karar|surdurulebilirlik.*uygulama kapsam)'
AileEkle 'GDS 3000' 'GDS 3000' '^gds 3000(?![0-9])'
AileEkle 'GDS 3400' 'GDS 3400' '^gds 3400(?![0-9])'
AileEkle 'GDS 3402' 'GDS 3402' '^gds 3402(?![0-9])'
AileEkle 'GDS 3410' 'GDS 3410' '^gds 3410(?![0-9])'
AileEkle 'SGDS 5000' 'SGDS 5000 (TASLAK — soru dayanağı yapılamaz)' 'sgds 5000' 'taslak'

# aile -> satır kimlikleri
$aileSatirlari=@{}
foreach($aileNesnesi in $aileler.Values){
  $eslesenler=New-Object System.Collections.Generic.List[object]
  foreach($adSatiri in $adDizisi){
    if($aileNesnesi.turSarti -and $adSatiri.tur -ne $aileNesnesi.turSarti){ continue }
    if(-not $aileNesnesi.turSarti -and $adSatiri.tur -in 'teori-notu','cikmis-soru','cikmis-komisyon-cevabi'){ continue }
    if($adSatiri.katli -match $aileNesnesi.desen){ $eslesenler.Add($adSatiri) }
  }
  $aileSatirlari[$aileNesnesi.kod]=$eslesenler
}

# ---------------------------------------------------------------- 3) metin indirme
$metinSozlugu=@{}
if((Test-Path $metinOnbellek) -and -not $Tazele){
  foreach($onbellekSatiri in (Get-Content $metinOnbellek -Raw -Encoding UTF8 | ConvertFrom-Json)){ $metinSozlugu["$($onbellekSatiri.id)"]=$onbellekSatiri }
}
$istenenKimlikler=New-Object System.Collections.Generic.HashSet[string]
foreach($listeNesnesi in $aileSatirlari.Values){ foreach($adSatiri in $listeNesnesi){ [void]$istenenKimlikler.Add("$($adSatiri.id)") } }
$eksikKimlikler=@($istenenKimlikler | Where-Object { -not $metinSozlugu.ContainsKey($_) })
Write-Host "aile satırı: $($istenenKimlikler.Count) · indirilecek: $($eksikKimlikler.Count)"
for($partiBasi=0;$partiBasi -lt $eksikKimlikler.Count;$partiBasi+=80){
  $partiSonu=[Math]::Min($partiBasi+79,$eksikKimlikler.Count-1)
  $partiKimlikleri=$eksikKimlikler[$partiBasi..$partiSonu] -join ','
  $partiSatirlari=GetirSayfa "dokumanlar?select=id,tur,kaynak_ad,baslik,metin,kaynak_url&id=in.($partiKimlikleri)&order=id.asc"
  foreach($tekSatir in $partiSatirlari){ $metinSozlugu["$($tekSatir.id)"]=$tekSatir }
  Start-Sleep -Milliseconds 200
}
if($eksikKimlikler.Count -gt 0){
  [IO.File]::WriteAllText($metinOnbellek,(ConvertTo-Json -InputObject @($metinSozlugu.Values) -Compress -Depth 3),(New-Object Text.UTF8Encoding($false)))
}

# ---------------------------------------------------------------- 4) aile ölçümü
$turkHarfDeseni='[' + [char]0x00E7 + [char]0x011F + [char]0x0131 + [char]0x00F6 + [char]0x015F + [char]0x00FC + [char]0x00C7 + [char]0x011E + [char]0x0130 + [char]0x00D6 + [char]0x015E + [char]0x00DC + ']'
$bitisDeseni='[\.\:\;\)\!\?\]' + [char]0x0022 + [char]0x0027 + [char]0x201D + [char]0x2019 + ']'
$aileOlcumu=[ordered]@{}
$aileKatliMetin=@{}
foreach($aileNesnesi in $aileler.Values){
  $satirListesi=$aileSatirlari[$aileNesnesi.kod]
  $parcaSayisi=$satirListesi.Count
  $toplamKarakter=0; $resmiParca=0; $kesikAdayi=0; $kaynakUrlVar=0
  $numaralar=New-Object System.Collections.Generic.HashSet[int]
  $bolunmus=@{}
  $katliParcalar=New-Object System.Collections.Generic.List[object]
  foreach($adSatiri in $satirListesi){
    $tamSatir=$metinSozlugu["$($adSatiri.id)"]
    $govdeMetni= if($tamSatir){ "$($tamSatir.metin)" } else { '' }
    $toplamKarakter+=$govdeMetni.Length
    if($tamSatir -and "$($tamSatir.kaynak_url)"){ $kaynakUrlVar++ }
    $harfSayisi=([regex]::Matches($govdeMetni,'\p{L}')).Count
    $turkSayisi=([regex]::Matches($govdeMetni,$turkHarfDeseni)).Count
    $buyukSayisi=([regex]::Matches($govdeMetni,'\p{Lu}')).Count
    if($harfSayisi -gt 0 -and ($turkSayisi/$harfSayisi) -ge 0.015 -and ($buyukSayisi/$harfSayisi) -lt 0.35){ $resmiParca++ }
    $sonKarakter=$govdeMetni.TrimEnd()
    $bolumEsi=[regex]::Match("$($adSatiri.kaynak_ad)",'\[(\d+)/(\d+)\]\s*$')
    $sonParcaMi= (-not $bolumEsi.Success) -or ($bolumEsi.Groups[1].Value -eq $bolumEsi.Groups[2].Value)
    # 14.09 ölçüt dersi: ilk sürüm "noktalamayla bitmiyor" diyordu ve kanunlarda
    # %50+ alarm verdi; örneklenince çoğunun sonraki maddenin BAŞLIĞI olduğu görüldü
    # ("…uygulanır. Yürürlük"). Kesik = kuyruk bağlaç/virgülle bitiyor ya da uzun.
    if($sonKarakter.Length -gt 0 -and $sonParcaMi -and ($sonKarakter[-1] -notmatch $bitisDeseni)){
      $sonNoktaYeri=[regex]::Match($sonKarakter,'[\.\:\;\)\!\?][^\.\:\;\)\!\?]*$')
      $kuyrukMetni= if($sonNoktaYeri.Success){ $sonKarakter.Substring($sonNoktaYeri.Index+1).Trim() } else { $sonKarakter }
      if($kuyrukMetni.Length -gt 120 -or $kuyrukMetni -match '(\s(ve|veya|ile|ya da|ya|ki|ise|olan|göre|gore|için|icin)|[,\(\-])$'){ $kesikAdayi++ }
    }
    if($bolumEsi.Success){
      $bolumKoku=([regex]::Replace("$($adSatiri.kaynak_ad)",'\s*\[\d+/\d+\]\s*$',''))
      if(-not $bolunmus.ContainsKey($bolumKoku)){ $bolunmus[$bolumKoku]=@{ n=[int]$bolumEsi.Groups[2].Value; k=(New-Object System.Collections.Generic.HashSet[int]) } }
      [void]$bolunmus[$bolumKoku].k.Add([int]$bolumEsi.Groups[1].Value)
    }
    $numaraEsi=[regex]::Match($adSatiri.katli,'(?:^|\s)(?:m|p)\.(\d+)(?![0-9])')
    if($numaraEsi.Success -and $adSatiri.katli -notmatch '(gec|ek)\. m\.' -and $adSatiri.katli -notmatch 'p\.a\d'){ [void]$numaralar.Add([int]$numaraEsi.Groups[1].Value) }
    $katliParcalar.Add([pscustomobject]@{ ad="$($adSatiri.kaynak_ad)"; k=(Katla ("$($adSatiri.kaynak_ad) $($tamSatir.baslik) $govdeMetni")) })
  }
  $aileKatliMetin[$aileNesnesi.kod]=$katliParcalar
  $eksikBolum=0
  foreach($bolumKaydi in $bolunmus.Values){ $eksikBolum+=($bolumKaydi.n - $bolumKaydi.k.Count) }
  $enBuyukNo=0; $delikSayisi=0; $delikOrnek=@()
  if($numaralar.Count -gt 0){
    # ana dizi: en küçükten başlayıp 20'den büyük ilk sıçramada kesilir (Etik
    # Kurallar 100/110/120… ve "p.900" gibi uç numaralar deliği şişirmesin);
    # dizi 20'nin altında başlıyorsa 1'den sayılır, üstündeyse (TTK m.1473…) kendinden.
    $siraliNumaralar=@($numaralar | Sort-Object)
    $enKucukNo=$siraliNumaralar[0]; $enBuyukNo=$enKucukNo
    $anaDizi=New-Object System.Collections.Generic.List[int]
    foreach($siradakiNo in $siraliNumaralar){ if($anaDizi.Count -gt 0 -and ($siradakiNo - $anaDizi[$anaDizi.Count-1]) -gt 20){ break }; $anaDizi.Add($siradakiNo) }
    # tek uç numara (660 KHK m.34'te biter, "m.46" adlı tek parça bir nottur) diziyi uzatmasın
    if($anaDizi.Count -ge 3 -and ($anaDizi[$anaDizi.Count-1] - $anaDizi[$anaDizi.Count-2]) -gt 5){ $anaDizi.RemoveAt($anaDizi.Count-1) }
    $enBuyukNo=$anaDizi[$anaDizi.Count-1]
    $baslangicNo= if($enKucukNo -le 20){ 1 } else { $enKucukNo }
    foreach($aranNo in $baslangicNo..$enBuyukNo){ if(-not $numaralar.Contains($aranNo)){ $delikSayisi++; if($delikOrnek.Count -lt 12){ $delikOrnek+=$aranNo } } }
    $enBuyukNo=$enBuyukNo - $baslangicNo + 1
  }
  $resmiOrani= if($parcaSayisi){ [math]::Round($resmiParca/$parcaSayisi,2) } else { 0 }
  $tamlik='OLCULMEDI'
  if($parcaSayisi -eq 0){ $tamlik='YOK' }
  else{
    $delikOrani= if($enBuyukNo -gt 0){ $delikSayisi/$enBuyukNo } else { 0 }
    $kesikOrani=$kesikAdayi/$parcaSayisi
    if($eksikBolum -eq 0 -and $delikOrani -le 0.05 -and $kesikOrani -le 0.05){ $tamlik='TAM' } else { $tamlik='DELIKLI' }
  }
  $metinNiteligi= if($aileNesnesi.tur -eq 'teori'){ 'TEORI-NOTU' } elseif($aileNesnesi.tur -eq 'taslak'){ 'TASLAK' } elseif($parcaSayisi -eq 0){ '-' } elseif($resmiOrani -ge 0.8){ 'RESMI' } elseif($resmiOrani -ge 0.3){ 'KARISIK' } else { 'OZET' }
  $aileOlcumu[$aileNesnesi.kod]=[ordered]@{
    ad=$aileNesnesi.ad; parca=$parcaSayisi; karakter=$toplamKarakter; resmi_orani=$resmiOrani; nitelik=$metinNiteligi
    numara_dizi=$enBuyukNo; numara_delik=$delikSayisi; delik_ornek=($delikOrnek -join ','); bolum_eksik=$eksikBolum; kesik_adayi=$kesikAdayi
    kaynak_url_olan=$kaynakUrlVar; tamlik=$tamlik
  }
}

# ---------------------------------------------------------------- 5) kota konu satırları
# her satır: aileler (virgüllü) + hüküm anahtar deseni (katlanmış metinde regex, ; = VE)
$konuTanimi=@{
 'tms 1 finansal tablolarin sunulusu onemlilik netlestirme'=@('TMS 1','onemli;netlestir|mahsup')
 'tms 1 isletmenin surekliligi ve tablo seti'=@('TMS 1','surekliligi')
 'tms 2 stoklar maliyet ve net gerceklesebilir deger'=@('TMS 2','net gerceklesebilir')
 'tms 7 nakit akis tablosu isletme yatirim finansman'=@('TMS 7','yatirim faaliyet')
 'tms 8 muhasebe politikalari tahmin degisikligi hata'=@('TMS 8','tahmin')
 'tms 10 raporlama doneminden sonraki olaylar'=@('TMS 10','duzeltme gerektir')
 'tms 12 gelir vergileri ertelenmis vergi'=@('TMS 12','ertelenmis vergi')
 'tms 16 maddi duran varliklar amortisman yeniden degerleme'=@('TMS 16','yeniden degerleme')
 'tms 19 calisanlara saglanan faydalar kidem karsiligi'=@('TMS 19','tanimlanmis fayda')
 'tms 21 kur degisiminin etkileri parasal kalemler'=@('TMS 21','parasal kalem')
 'tms 23 borclanma maliyetleri aktiflestirme'=@('TMS 23','ozellikli varlik')
 'tms 24 iliskili taraf aciklamalari'=@('TMS 24','iliskili taraf')
 'tms 27 bireysel finansal tablolar'=@('TMS 27','bireysel finansal tablo')
 'tms 28 istiraklerdeki yatirimlar ozkaynak yontemi'=@('TMS 28','ozkaynak yontemi')
 'tms 29 yuksek enflasyonlu ekonomide raporlama'=@('TMS 29','yuksek enflasyon')
 'tms 36 varliklarda deger dusuklugu geri kazanilabilir tutar'=@('TMS 36','geri kazanilabilir')
 'tms 37 karsiliklar kosullu borclar kosullu varliklar'=@('TMS 37','kosullu')
 'tms 38 maddi olmayan duran varliklar gelistirme gideri'=@('TMS 38','gelistirme')
 'tms 40 yatirim amacli gayrimenkuller gercege uygun deger'=@('TMS 40','gercege uygun deger')
 'tms 41 tarimsal faaliyetler canli varlik'=@('TMS 41','canli varlik')
 'tfrs 3 isletme birlesmeleri serefiye'=@('TFRS 3','serefiye')
 'tfrs 5 satis amacli elde tutulan duran varliklar durdurulan faaliyetler'=@('TFRS 5','durdurulan faaliyet')
 'tfrs 7 finansal araclar aciklamalar risk'=@('TFRS 7','likidite riski|kredi riski')
 'tfrs 8 faaliyet bolumleri raporlanabilir bolum'=@('TFRS 8','raporlanabilir bolum')
 'tfrs 9 finansal araclar siniflandirma deger dusuklugu beklenen kredi zarari'=@('TFRS 9','beklenen kredi zarar')
 'tfrs 9 korunma muhasebesi'=@('TFRS 9','riskten korunma')
 'tfrs 10 konsolide finansal tablolar kontrol'=@('TFRS 10','kontrol')
 'tfrs 13 gercege uygun deger olcumu hiyerarsi'=@('TFRS 13','seviye')
 'tfrs 15 musteri sozlesmelerinden hasilat bes adim'=@('TFRS 15','edim yukumlulug')
 'tfrs 16 kiralamalar kullanim hakki varligi'=@('TFRS 16','kullanim hakki')
 'bds 200 bagimsiz denetimin amaci makul guvence'=@('BDS 200','makul guvence')
 'bds 210 denetim sozlesmesinin sartlari'=@('BDS 210','sozlesme')
 'bds 220 denetimde kalite yonetimi sorumlu denetci'=@('BDS 220','kalite')
 'bds 230 denetimin belgelendirilmesi calisma kagitlari'=@('BDS 230','belgelendir')
 'bds 240 finansal tablolarin denetiminde hile'=@('BDS 240','hile')
 'bds 260 ust yonetimden sorumlu olanlarla kurulacak iletisim'=@('BDS 260','ust yonetimden sorumlu')
 'bds 265 ic kontrol eksikliklerinin bildirilmesi'=@('BDS 265','eksiklik')
 'bds 300 denetimin planlanmasi strateji'=@('BDS 300','strateji')
 'bds 315 onemli yanlislik risklerinin belirlenmesi isletmeyi tanima'=@('BDS 315','onemli yanlislik risk')
 'bds 320 onemlilik kiyaslama noktasi performans onemliligi'=@('BDS 320','performans onemliligi')
 'bds 330 degerlendirilen risklere karsi yapilacak isler maddi dogrulama'=@('BDS 330','maddi dogrulama')
 'bds 450 denetim sirasinda tespit edilen yanlisliklarin degerlendirilmesi'=@('BDS 450','yanlislik')
 'bds 500 denetim kanitlari yeterli uygun kanit'=@('BDS 500','kanit')
 'bds 501 belirli kalemlere iliskin kanitlar stok sayimi dava'=@('BDS 501','sayim|dava')
 'bds 505 dis teyitler olumlu olumsuz teyit'=@('BDS 505','teyit')
 'bds 510 ilk denetimler acilis bakiyeleri'=@('BDS 510','acilis bakiye')
 'bds 520 analitik prosedurler'=@('BDS 520','analitik')
 'bds 530 denetimde orneklem orneklem buyuklugu'=@('BDS 530','orneklem')
 'bds 540 muhasebe tahminlerinin denetimi gercege uygun deger tahmini'=@('BDS 540','tahmin')
 'bds 550 iliskili taraflarin denetimi'=@('BDS 550','iliskili taraf')
 'bds 570 isletmenin surekliligi denetci degerlendirmesi'=@('BDS 570','sureklilig')
 'bds 580 yazili beyanlar'=@('BDS 580','yazili beyan')
 'bds 620 uzman calismalarinin kullanilmasi'=@('BDS 620','uzman')
 'bds 700 finansal tablolara iliskin gorus olusturma denetci raporu'=@('BDS 700','gorus')
 'bds 701 kilit denetim konulari'=@('BDS 701','kilit denetim')
 'bds 705 gorus sartli olumsuz gorus vermekten kacinma'=@('BDS 705','kacinma')
 'bds 706 dikkat cekilen hususlar diger hususlar'=@('BDS 706','dikkat cekilen')
 'bds 720 diger bilgilere iliskin sorumluluklar'=@('BDS 720','diger bilgi')
 'bagimsiz denetim yonetmeligi denetci yetkilendirme sartlari'=@('BDY','yetkilendir')
 'bagimsiz denetim yonetmeligi bagimsizlik yasaklar rotasyon'=@('BDY','bagimsizlik')
 '660 khk kamu gozetimi kurumu gorev yetki'=@('660 KHK','gorev')
 'kurumsal yonetim tebligi komiteler ve gorevleri denetim riskin erken saptanmasi ucret aday gosterme'=@('II-17.1','riskin erken saptanmasi')
 'kurumsal yonetim tebligi iliskili taraf islemleri yaygin ve sureklilik arz eden islemler'=@('II-17.1','yaygin ve sureklilik arz')
 'kurumsal yonetim tebligi genel kurul toplanti usul ve ilkeleri'=@('II-17.1','genel kurul')
 'kurumsal yonetim tebligi menfaat sahipleri calisanlar paydaslar'=@('II-17.1','menfaat sahip')
 'kurumsal yonetim tebligi yatirimci iliskileri bolumu gorevleri'=@('II-17.1','yatirimci iliskileri')
 'kurumsal yonetim tebligi faaliyet raporu icerigi'=@('II-17.1','faaliyet rapor')
 'kurumsal yonetim tebligi kamuyu aydinlatma ve seffaflik'=@('II-17.1','kamuyu aydinlatma')
 'kurumsal yonetim tebligi teminat rehin ipotek yasagi'=@('II-17.1','rehin|ipotek')
 'kurumsal yonetim tebligi pay sahipligi haklari azlik haklari'=@('II-17.1','azlik')
 'kurumsal yonetim ilkeleri uyum raporu kapsam ve zorunluluk'=@('II-17.1','uyum rapor')
 'finansal analiz oranlari likidite kaldirac karlilik dupont'=@('FY-TEORI','cari oran|likidite oran')
 'paranin zaman degeri bugunku deger anuite'=@('FY-TEORI','bugunku deger')
 'isletme sermayesi yonetimi nakit dongusu finanslama stratejileri'=@('FY-TEORI','isletme sermayesi|calisma sermayesi')
 'sermaye maliyeti wacc ozkaynak maliyeti'=@('FY-TEORI','agirlikli ortalama sermaye maliyeti|wacc')
 'sermaye butcelemesi net bugunku deger ic verim orani geri odeme'=@('FY-TEORI','ic verim|net bugunku deger')
 'basabas noktasi faaliyet ve finansal kaldirac'=@('FY-TEORI','basabas|basa bas')
 'tahvil ve para piyasasi araclari ozellikleri fiyatlama finansman bonosu'=@('FY-TEORI','tahvil')
 'faiz hesaplari basit bilesik efektif faiz'=@('FY-TEORI','bilesik faiz')
 'risk getiri portfoy beta capm'=@('FY-TEORI','beta|capm')
 'finansman teknikleri factoring forfaiting leasing'=@('FY-TEORI,6361','faktoring|finansal kiralama;forfaiting')
 'temettu kar payi politikasi'=@('FY-TEORI','temettu|kar payi')
 'turev urunler forward futures opsiyon swap varant'=@('FY-TEORI','opsiyon|swap')
 'teknik karsiliklar yonetmeligi'=@('TK-YON','karsilik')
 'tfrs 17 sigorta sözleşmeleri'=@('TFRS 17','sigorta sozlesme')
 'ttk sorumluluk sigortalari'=@('TTK-SORUMLULUK','sorumluluk sigorta')
 'ttk hayat sigortalari'=@('TTK-HAYAT','hayat sigorta')
 'sigortacilik ic sistemler yonetmeligi'=@('IC-SIS-SIGORTA','ic sistem')
 'bireysel emeklilik devlet katkisi'=@('4632,DEVLET-KATKI-YON','devlet katkisi')
 'borsalar ve piyasa isleticileri'=@('BORSA-YON,6362','piyasa isletici')
 'nitelikli yatirimciya satis'=@('II-5.2','nitelikli yatirimci')
 'sermaye piyasası suçları'=@('6362','piyasa dolandiriciligi|bilgi suistimali')
 'borclanma araclari tebligi degistirilebilir tahvil'=@('VII-128.8','degistirilebilir')
 'izahname tebliği muafiyet halleri'=@('II-5.1','muafiyet|yayimlanmasi zorunlu olmayan|izahname yayimlanmaksizin')
 'satis tebligi fiyat dagitim esaslari'=@('II-5.2','dagitim')
 'halka arz satış yöntemleri'=@('II-5.2','talep toplama')
 'kayitli sermaye sistemi'=@('II-18.1','kayitli sermaye tavan')
 'tsrs 2 sektorler arasi metrikler'=@('TSRS 2','sektorler.?arasi')
 'tsrs 2 iklim direncliligi senaryo analizi'=@('TSRS 2','direnc')
 'tsrs 1 gercege uygun sunum'=@('TSRS 1','gercege uygun sunum')
 'tsrs 1 temel niteliksel ozellikler'=@('TSRS 1','niteliksel ozellik')
 'tsrs 1 muhakeme hususlari'=@('TSRS 1','muhakeme')
 'tsrs 1 capraz referans'=@('TSRS 1','capraz referans|atif yoluyla|atifta bulun')
 'tsrs 2 iklim hedefleri'=@('TSRS 2','hedef')
 'tsrs 2 kapsam 3 olcum cercevesi'=@('TSRS 2','kapsam 3')
 'tsrs 2 senaryo analizi varsayimlari'=@('TSRS 2','senaryo analizi')
 'tsrs 2 kapsam 3 kategorileri'=@('TSRS 2','kapsam 3;kategori')
 'tsrs 1 iklim oncelikli gecis muafiyeti'=@('TSRS 1','gecis')
 'tsrs 2 finanse edilen emisyonlar'=@('TSRS 2','finanse edilen')
 'tsrs 1 senaryo analizi tanimi'=@('TSRS 1,TSRS 2','senaryo analizi')
 'varlik yonetim sirketleri yonetmeligi'=@('VYS-YON','varlik yonetim')
 'bankalarin bagimsiz denetimi yonetmeligi'=@('BBD-YON','bagimsiz denetim')
 'kredi islemleri yonetmeligi hesap durumu belgesi'=@('KREDI-YON','hesap durumu belgesi')
 'kredi islemleri yonetmeligi kredi komitesi'=@('KREDI-YON,5411','kredi komitesi')
 'kredi islemleri yonetmeligi kredi acma yetkisi'=@('KREDI-YON,5411','kredi acma yetki')
 'katilim bankasi fon kullandirma yontemleri'=@('KREDI-YON,5411,BANKA-THP','katilim;fon kullandir')
 'bankacilik duzeltici onlemler'=@('5411','duzeltici')
 'bankalar tekdüzen hesap planı'=@('BANKA-THP','hesap')
 'sermaye yeterliliği yönetmeliği operasyonel risk'=@('SY-YON','operasyonel risk')
 'genel karsilik tfrs 9'=@('KSK-YON','genel karsilik')
 'sorunlu alacak yonetimi'=@('KSK-YON,SORUNLU-REH','sorunlu|donuk alacak')
 'gds 3000 tarihi finansal bilgi disindaki guvence denetimleri cerceve'=@('GDS 3000','guvence denetim')
 'gds 3000 guvence denetiminde kanit ve onemlilik'=@('GDS 3000','onemlilik;kanit')
 'gds 3410 sera gazi beyanlarina iliskin guvence denetimleri'=@('GDS 3410','sera gazi')
 'gds 3400 ileriye yonelik finansal bilgilerin incelenmesi'=@('GDS 3400','ileriye yonelik')
 'gds 3402 hizmet kurulusundaki kontrollere iliskin guvence raporlari'=@('GDS 3402','hizmet kurulus')
 'gds 3410 kapsami'=@('GDS 3410','kapsam')
}
$dersAdi=@{
 'Muhasebe Standartlari'='a) Türkiye Muhasebe Standartları'; 'Denetim Standartlari'='b) Türkiye Denetim Standartları'
 'Kurumsal Yonetim'='c) Kurumsal Yönetim İlkeleri ve Finansal Yönetim'; 'Finansal Yonetim'='c) Kurumsal Yönetim İlkeleri ve Finansal Yönetim'
 'Sermaye Piyasasi Mevzuati'='ç) Sermaye Piyasası Mevzuatı'; 'Bankacilik Mevzuati'='d) Bankacılık Mevzuatı'
 'Sigortacilik ve Ozel Emeklilik Mevzuati'='e) Sigortacılık ve Özel Emeklilik Mevzuatı'; 'Surdurulebilirlik Raporlamasi'='f) Kurumsal Sürdürülebilirlik Raporlaması'
 'Surdurulebilirlik Denetimi'='g) Sürdürülebilirlik Denetimi'
}

# ---------------------------------------------------------------- 6) çıkmış arşiv -> kota satırı
$arsivVerisi=Get-Content (Join-Path $depoKok 'veri\kgk-analiz.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$arsivKonu=@{}; $arsivDonem=@{}
foreach($donemKaydi in $arsivVerisi.donemler){
  foreach($konuOzelligi in $donemKaydi.konuSayim.PSObject.Properties){
    $arsivKonu[$konuOzelligi.Name]=[int]$arsivKonu[$konuOzelligi.Name]+[int]$konuOzelligi.Value
    $arsivDonem[$konuOzelligi.Name]=[int]$arsivDonem[$konuOzelligi.Name]+1
  }
}
$kotaVerisi=Get-Content (Join-Path $depoKok 'veri\kgk-uretim-kotasi.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$kasaVerisi=Get-Content (Join-Path $depoKok 'veri\kasa-sayim.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$bosKelimeler='ve','ile','icin','bir','iliskin','olan','gore','hesabi','hesaplama','tanimi','turleri','ozellikleri','kapsami','yonetmeligi','tebligi','kanunu','hukumleri','esaslari','sartlari','islemleri','finansal','denetim','muhasebe','raporlama','yonetimi','degeri','tablolar','tablolari','bankalarin','sirketleri','varliklar','sermaye','piyasasi'
function KonuKelimeleri([string]$konuMetni){ return @((Katla $konuMetni) -split '[^a-z0-9]+' | Where-Object { $_.Length -ge 4 -and $bosKelimeler -notcontains $_ }) }
$satirKelime=@{}; $satirStd=@{}
foreach($planSatiri in $kotaVerisi.plan){
  $satirKelime[$planSatiri.konu]=KonuKelimeleri $planSatiri.konu
  $stdEsi=[regex]::Match((Katla $planSatiri.konu),'^(tms|tfrs|bds|gds|tsrs) (\d+)')
  $satirStd[$planSatiri.konu]= if($stdEsi.Success){ "$($stdEsi.Groups[1].Value) $($stdEsi.Groups[2].Value)" } else { '' }
}
$arsivDersEsleme=@{
 'muhasebe standartlari'='Muhasebe Standartlari'; 'muhasebe'='Muhasebe Standartlari'; 'turkiye muhasebe standartlari'='Muhasebe Standartlari'
 'denetim'='Denetim Standartlari'; 'turkiye denetim standartlari'='Denetim Standartlari'
 'kurumsal yonetim ilkeleri ve finansal yonetim'='KYFY'; 'kurumsal yonetim ve finansal yonetim'='KYFY'
 'sermaye piyasasi, bankacilik, sigortacilik ve ozel emeklilik mevzuati'='SBS'; 'sermaye piyasasi bankacilik sigortacilik'='SBS'
 'sermaye piyasasi mevzuati'='Sermaye Piyasasi Mevzuati'; 'sermaye piyasasi'='Sermaye Piyasasi Mevzuati'
 'bankacilik mevzuati'='Bankacilik Mevzuati'; 'bankacilik'='Bankacilik Mevzuati'
 'sigortacilik ve ozel emeklilik mevzuati'='Sigortacilik ve Ozel Emeklilik Mevzuati'; 'sigortacilik ve ozel emeklilik'='Sigortacilik ve Ozel Emeklilik Mevzuati'
 'kurumsal surdurulebilirlik raporlamasi ve denetimi'='SURD'
 'genel hukuk mevzuati'='KAPSAM-DISI'
}
$satirCikmis=@{}; $satirDonem=@{}
$dagitilamayan=@{}; $kapsamDisiSoru=0
foreach($arsivAnahtari in $arsivKonu.Keys){
  $parcaAyrimi=$arsivAnahtari -split '\|',2
  $arsivDersi=$arsivDersEsleme[(Katla $parcaAyrimi[0]).Trim()]
  $arsivKonuAdi=$parcaAyrimi[1]; $katliKonu=Katla $arsivKonuAdi
  if($arsivDersi -eq 'KAPSAM-DISI' -or -not $arsivDersi){ $kapsamDisiSoru+=$arsivKonu[$arsivAnahtari]; continue }
  if($arsivDersi -eq 'KYFY'){ $arsivDersi= if($katliKonu -match 'kurumsal yonetim|komite|yonetim kurulu|genel kurul|pay sahip|menfaat|yatirimci iliskileri|faaliyet raporu|kamuyu aydinlatma|seffaflik|bagimsiz uye|uyum rapor|iliskili taraf|azlik|oy hakki|imtiyaz'){ 'Kurumsal Yonetim' } else { 'Finansal Yonetim' } }
  if($arsivDersi -eq 'SBS'){ $arsivDersi= if($katliKonu -match 'bank|bddk|5411|kredi|mevduat|katilim|tmsf|varlik yonetim|faktoring|leasing|kiralama'){ 'Bankacilik Mevzuati' } elseif($katliKonu -match 'sigorta|emeklilik|bes|5684|4632|reasurans|acente|broker|hasar|police|teknik karsilik|tfrs 17'){ 'Sigortacilik ve Ozel Emeklilik Mevzuati' } else { 'Sermaye Piyasasi Mevzuati' } }
  if($arsivDersi -eq 'SURD'){ $arsivDersi= if($katliKonu -match 'gds|guvence|denetci|denetim'){ 'Surdurulebilirlik Denetimi' } else { 'Surdurulebilirlik Raporlamasi' } }
  $konuStdEsi=[regex]::Match($katliKonu,'(tms|tfrs|bds|gds|tsrs|isa|uds)\s*(\d+)')
  $konuStd= if($konuStdEsi.Success){ ($konuStdEsi.Groups[1].Value -replace 'isa|uds','bds') + ' ' + $konuStdEsi.Groups[2].Value } else { '' }
  $konuKelimeleri=KonuKelimeleri $arsivKonuAdi
  $enIyiSatir=$null; $enIyiPuan=0
  foreach($planSatiri in @($kotaVerisi.plan | Where-Object { $_.ders -eq $arsivDersi })){
    $puanDegeri=0
    if($konuStd -and $satirStd[$planSatiri.konu] -eq $konuStd){ $puanDegeri+=10 }
    elseif($konuStd -and $satirStd[$planSatiri.konu]){ continue }
    foreach($kelimeDegeri in $konuKelimeleri){ if($satirKelime[$planSatiri.konu] -contains $kelimeDegeri){ $puanDegeri+=2 } }
    if($puanDegeri -gt $enIyiPuan){ $enIyiPuan=$puanDegeri; $enIyiSatir=$planSatiri.konu }
  }
  if($enIyiSatir -and $enIyiPuan -ge 4){
    $satirCikmis[$enIyiSatir]=[int]$satirCikmis[$enIyiSatir]+$arsivKonu[$arsivAnahtari]
    $satirDonem[$enIyiSatir]=[int]$satirDonem[$enIyiSatir]+$arsivDonem[$arsivAnahtari]
  } else {
    $dagitAnahtari="$arsivDersi|$arsivKonuAdi"
    $dagitilamayan[$dagitAnahtari]=[int]$dagitilamayan[$dagitAnahtari]+$arsivKonu[$arsivAnahtari]
  }
}

# ---------------------------------------------------------------- 7) sınıflandırma
$konuSonuclari=New-Object System.Collections.Generic.List[object]
foreach($planSatiri in $kotaVerisi.plan){
  $tanimDizisi=$konuTanimi[$planSatiri.konu]
  $kasadaAdet=[int]$kasaVerisi.konu_yogunluk."$($planSatiri.ders)|$($planSatiri.konu)"
  $sonucKaydi=[ordered]@{ ders=$dersAdi[$planSatiri.ders]; kota_ders=$planSatiri.ders; konu=$planSatiri.konu; kota=[int]$planSatiri.adet; kasada_ayni_konu=$kasadaAdet; cikmis_soru=[int]$satirCikmis[$planSatiri.konu]; cikmis_donem=[int]$satirDonem[$planSatiri.konu]; aileler=''; aile_parca=0; nitelik=''; tamlik=''; hukum_parca=0; hukum_ornek=''; sinif='OLCULMEDI'; gerekce='' }
  if(-not $tanimDizisi){ $sonucKaydi.gerekce='konu tanımı yok (betiğe eklenmeli)'; $konuSonuclari.Add([pscustomobject]$sonucKaydi); continue }
  $aileKodlari=@($tanimDizisi[0] -split ',')
  $hukumKosullari=@($tanimDizisi[1] -split ';')
  $sonucKaydi.aileler=$aileKodlari -join ' + '
  $toplamAileParca=0; $resmiTamAile=@(); $zayifAile=@(); $hukumSayaci=0; $hukumOrnekleri=@()
  foreach($aileKodu in $aileKodlari){
    $olcumKaydi=$aileOlcumu[$aileKodu]
    $toplamAileParca+=$olcumKaydi.parca
    if($olcumKaydi.parca -eq 0){ continue }
    $aileHukumSayaci=0
    foreach($katliParca in $aileKatliMetin[$aileKodu]){
      $hepsiTuttu=$true
      # kelime arası esnek: resmî metin tırnak/tire taşıyor (önemli yanlışlık tırnaklı, sektörler-arası tireli — 14.09 ölçüldü)
      foreach($kosulDeseni in $hukumKosullari){ if($katliParca.k -notmatch ($kosulDeseni -replace ' ','[^a-z0-9]{1,4}')){ $hepsiTuttu=$false; break } }
      if($hepsiTuttu){ $aileHukumSayaci++; if($hukumOrnekleri.Count -lt 3){ $hukumOrnekleri+=$katliParca.ad } }
    }
    $hukumSayaci+=$aileHukumSayaci
    if($aileHukumSayaci -gt 0){
      if($olcumKaydi.nitelik -eq 'RESMI' -and $olcumKaydi.tamlik -eq 'TAM'){ $resmiTamAile+=$aileKodu } else { $zayifAile+=("{0}: {1}/{2}" -f $aileKodu,$olcumKaydi.nitelik,$olcumKaydi.tamlik) }
    }
  }
  $sonucKaydi.aile_parca=$toplamAileParca
  $sonucKaydi.nitelik=(@($aileKodlari | ForEach-Object { "{0}={1}" -f $_,$aileOlcumu[$_].nitelik }) -join ' ')
  $sonucKaydi.tamlik=(@($aileKodlari | ForEach-Object { "{0}={1}" -f $_,$aileOlcumu[$_].tamlik }) -join ' ')
  $sonucKaydi.hukum_parca=$hukumSayaci
  $sonucKaydi.hukum_ornek=($hukumOrnekleri -join ' || ')
  # Cem şartı (14.09): "resmî metin ve metnin tam olması" — yalnız özet/teori notu/taslak varsa resmî metin YOK sayılır
  $resmiAileParca=0
  foreach($aileKodu in $aileKodlari){ if($aileOlcumu[$aileKodu].nitelik -in 'RESMI','KARISIK'){ $resmiAileParca+=$aileOlcumu[$aileKodu].parca } }
  if($toplamAileParca -eq 0){ $sonucKaydi.sinif='YOK'; $sonucKaydi.gerekce='beklenen resmî metin ambarda yok' }
  elseif($resmiAileParca -eq 0){ $sonucKaydi.sinif='YOK'; $sonucKaydi.gerekce=('resmî metin yok — ambarda yalnız ' + ((@($aileKodlari | ForEach-Object { "$_ $($aileOlcumu[$_].nitelik) ($($aileOlcumu[$_].parca) parça)" })) -join ', ')) }
  elseif($resmiTamAile.Count -gt 0 -and $hukumSayaci -ge 2){ $sonucKaydi.sinif='HAZIR'; $sonucKaydi.gerekce="resmî+tam aile içinde hüküm anahtarı $hukumSayaci parçada" }
  elseif($hukumSayaci -eq 0){ $sonucKaydi.sinif='ZAYIF'; $sonucKaydi.gerekce='aile var ama hüküm anahtarı ailenin içinde bulunamadı' }
  else { $sonucKaydi.sinif='ZAYIF'; $sonucKaydi.gerekce= if($zayifAile.Count){ 'hüküm var ama metin: ' + ($zayifAile -join '; ') } else { "hüküm yalnız $hukumSayaci parçada" } }
  $konuSonuclari.Add([pscustomobject]$sonucKaydi)
}

$dagitilamayanListe=@($dagitilamayan.GetEnumerator() | Where-Object { $_.Value -ge 3 } | Sort-Object Value -Descending | ForEach-Object { [ordered]@{ ders_konu=$_.Key; cikmis_soru=$_.Value } })
$sinifOzeti=[ordered]@{}
foreach($grupKaydi in ($konuSonuclari | Group-Object ders)){
  $sinifOzeti[$grupKaydi.Name]=[ordered]@{
    HAZIR=@($grupKaydi.Group | Where-Object sinif -eq 'HAZIR').Count; ZAYIF=@($grupKaydi.Group | Where-Object sinif -eq 'ZAYIF').Count
    YOK=@($grupKaydi.Group | Where-Object sinif -eq 'YOK').Count; OLCULMEDI=@($grupKaydi.Group | Where-Object sinif -eq 'OLCULMEDI').Count
    kota_HAZIR=(@($grupKaydi.Group | Where-Object sinif -eq 'HAZIR') | Measure-Object kota -Sum).Sum
    kota_toplam=($grupKaydi.Group | Measure-Object kota -Sum).Sum
  }
}
$ciktiNesnesi=[ordered]@{
  olcum=(Get-Date).ToString('dd.MM.yyyy HH:mm')
  ad_listesi_olcumu=$adOlcumZamani
  kural='HAZIR = beklenen resmî metin ambarda + RESMI nitelik (Türkçe harfli, özet değil) + TAM (madde/paragraf deliği ≤%5, bölünmüş parça eksiği 0, kesik adayı ≤%5) + hüküm anahtarı ailenin içinde ≥2 parçada. ZAYIF = resmî metin var ama delikli/kesik ya da hüküm anahtarı ailenin içinde <2 parçada. YOK = beklenen resmî metin ambarda yok YA DA yalnız elle yazılmış özet/teori notu/taslak var (Cem 14.09: resmî metin şartı). Numara deliği iki anlama gelir: metin yok ya da başka parçaya yapışık (TMS 16 p.31-40 yapışık çıktı); ikisinde de paket seçici hükmü getiremez. Hüküm anahtarı mekanik bir göstergedir; hakem teyidi değildir.'
  ambar_satiri=$adDizisi.Count
  ozet=$sinifOzeti
  aileler=$aileOlcumu
  konular=$konuSonuclari.ToArray()
  arsiv_kapsam_disi_soru=$kapsamDisiSoru
  arsiv_kota_disi_sik_konular=$dagitilamayanListe
}
$yazildiMi=RaporYaz -Hedef $hedefYol -Nesne $ciktiNesnesi -Sessiz
Write-Host ("yazıldı={0} · {1}" -f $yazildiMi,$hedefYol)
foreach($ozetAnahtari in $sinifOzeti.Keys){ $ozetDegeri=$sinifOzeti[$ozetAnahtari]; Write-Host ("  {0,-52} HAZIR {1,3} · ZAYIF {2,3} · YOK {3,3} · ÖLÇÜLMEDİ {4}" -f $ozetAnahtari,$ozetDegeri.HAZIR,$ozetDegeri.ZAYIF,$ozetDegeri.YOK,$ozetDegeri.OLCULMEDI) }
