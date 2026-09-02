# ============================================================================
#  METİNSİZ DAYANAK TARAMASI (02.09.2026 — Cem: "2 yap")
#
#  Köprüdeki bir dayanağın ambarda KARŞILIĞI yoksa o konu ölçülemez ve soru
#  üretilemez: hakem dayanağı doğrulayamaz, üretici kaynak metnini çekemez.
#  Bunlar ne "çöp" ne "sağlam" — ÖLÇÜLEMEZ. Ayrı ele alınmaları gerekir:
#  ya kaynak yutulur ya da konu kaynak borcuna yazılır.
#  (02.09'da kara liste ölçümünde üç dayanak böyle çıktı: "SPK Kararı",
#   "SPK Tebliğ (Seri: X, No: 22)", madde numarasız düz "TTK (6102 s.K.)".)
#
#  YÖNTEM: ambardaki TÜM kaynak adları sayfalanarak çekilir (tek kolon, hızlı),
#  köprünün tekil dayanaklarıyla karşılaştırılır. Üç eşleşme denenir:
#    1) birebir ad   2) madde öneki (" - açıklama" atılmış hâli)
#    3) önek eşleşmesi (ambar adı dayanakla başlıyor mu)
#  ÇIKTI: veri/dayanak-metinsiz-raporu.json — etkilenen konu sayısına göre sıralı.
#
#  ⚠ PS: döngü değişkenine $h/$d gibi tek harf VERİLMEZ ($H başlıkları ezer).
#  ⚠ PS: hashtable literalinde List'i @() ile sarma — .ToArray() kullan.
# ============================================================================
param(
  [int]$EnAzKonu=1,        # kac konuya bagli dayanaklar raporlansin
  [int]$ListeTavan=60      # ekrana/rapora kac ornek yazilsin
)
$ErrorActionPreference='Stop'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$depoKok=Split-Path -Parent $here
$KEY=$env:SUPABASE_SERVICE_KEY
if(-not $KEY){ throw 'SUPABASE_SERVICE_KEY yok.' }
$BASLIK=@{ apikey=$KEY; Authorization="Bearer $KEY"; 'User-Agent'='mevzuat-radar-robot/1.0' }
$AMBAR='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar'

# --- ambardaki tum kaynak adlari (sayfali; order SART - order'siz offset kararsizdir)
$ambarAdlari=New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
$ofs=0
while($true){
  $u=$AMBAR+"?select=kaynak_ad&order=kaynak_ad.asc&limit=1000&offset=$ofs"
  $cevap=$null
  foreach($deneme in 1..4){
    try{ $cevap=Invoke-WebRequest -UseBasicParsing -Uri $u -Headers $BASLIK -TimeoutSec 120; break }
    catch{ if($deneme -eq 4){ throw "ambar adlari cekilemedi (offset $ofs): $($_.Exception.Message)" }; Start-Sleep -Seconds (4*$deneme) }
  }
  $ham=ConvertFrom-Json -InputObject $cevap.Content
  $sayfa=@($ham)
  if($sayfa.Count -eq 0){ break }
  foreach($kayit in $sayfa){ if($kayit.kaynak_ad){ [void]$ambarAdlari.Add("$($kayit.kaynak_ad)") } }
  if($sayfa.Count -lt 1000){ break }
  $ofs+=1000
  if($ofs -gt 200000){ break }
}
Write-Host "ambarda tekil kaynak adi: $($ambarAdlari.Count)"

# hizli onek aramasi icin sirali dizi
$sirali=@($ambarAdlari) | Sort-Object
# 02.09 DUZELTME: ilk surum ham ad kiyasi yapiyordu ve "%50 ambarda yok" dedi -
# oysa cogu YAZIM FARKIYDI ("VUK m.275" vs ambardaki "VUK (213 s.K.) m.275 - Imal
# edilen emtia"). Artik deponun kendi DayanakAnahtar normalizasyonu + KANUN/STANDART
# kimlik cikarimi kullaniliyor; boylece "kaynak eksigi" ile "ad farki" ayrisir.
. (Join-Path $depoKok 'arac\dayanak-normalize.ps1')
$ambarAnahtar=New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
foreach($ad in $sirali){ $ak=DayanakAnahtar $ad; if($ak){ [void]$ambarAnahtar.Add($ak) } }
# kanun kisa adi + madde no / standart + paragraf cikarimi (uretici DesenUret mantigi)
function KimlikCikar([string]$metin){
  $sonuc=New-Object System.Collections.Generic.List[string]
  foreach($m in [regex]::Matches($metin,'(TMS|TFRS|BDS|GDS|TSRS|SBDS|KKS|KYS)\s*(\d+)')){ $sonuc.Add("$($m.Groups[1].Value) $($m.Groups[2].Value)") }
  # 03.09 (Cem "1 yap"): kanun numarasi UC yazimla geliyor - "5510 sayılı" / "5510 sayili" (ASCII)
  # / "5510 s. SGK Kanunu" / "(5510 s.K.)". Olculdu: 148 "bulunmayan"in cogu bu farkti.
  foreach($m in [regex]::Matches($metin,'(\d{3,4})\s*say[ıi]l[ıi]')){ $sonuc.Add("SK$($m.Groups[1].Value)") }
  foreach($m in [regex]::Matches($metin,'\b(\d{3,4})\s*s\.\s*K\.')){ $sonuc.Add("SK$($m.Groups[1].Value)") }
  foreach($m in [regex]::Matches($metin,'\b(\d{3,4})\s*s\.\s+[A-ZÇĞİÖŞÜ]')){ $sonuc.Add("SK$($m.Groups[1].Value)") }
  foreach($m in [regex]::Matches($metin,'\b(VUK|TTK|TBK|GVK|KVK|KDV|SPK|İİK|AATUHK|MSUGT|THP)\b')){ $sonuc.Add($m.Groups[1].Value.ToUpperInvariant()) }
  # 03.09: numarasiz kanun kisa adlari -> kanun numarasi (ambar "(4760 s.K.)" yazar)
  $kisaKanun=@{ 'ÖTV'='4760'; 'OTV'='4760'; 'KDVK'='3065'; 'KDV'='3065'; 'GVK'='193'; 'KVK'='5520'; 'VUK'='213'; 'TTK'='6102'; 'TBK'='6098'; 'İİK'='2004'; 'IIK'='2004'; 'AATUHK'='6183'; 'SGK'='5510'; 'İş K'='4857'; 'Is K'='4857'; 'TMK'='4721'; 'HMK'='6100'; 'CMK'='5271'; 'TCK'='5237'; 'İYUK'='2577'; 'IYUK'='2577' }
  foreach($kk in $kisaKanun.Keys){ if($metin -match ('(?i)(^|[^A-Za-zÇĞİÖŞÜçğıöşü])'+[regex]::Escape($kk)+'(\s*(Kanunu|K\.|K\b)|\b)')){ $sonuc.Add("SK$($kisaKanun[$kk])") } }
  foreach($m in [regex]::Matches($metin,'\bm\.?\s*(\d+)')){ $sonuc.Add("M$($m.Groups[1].Value)") }
  foreach($m in [regex]::Matches($metin,'(?i)\b(?:md\.?|madde)\s*(\d+)')){ $sonuc.Add("M$($m.Groups[1].Value)") }
  return @($sonuc)
}
# ambardaki her adin kimlik kumesi (bir kez hesaplanir)
$ambarKimlik=New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
foreach($ad in $sirali){ foreach($kim in (KimlikCikar $ad)){ [void]$ambarKimlik.Add($kim) } }

# 02.09 iki tuzak daha olculdu:
#  (a) PARAGRAF ARALIGI: kopruDE "TMS 40 p.1-4 - Amac ve kapsam" yaziyor, ambarda
#      "TMS 40 p.1 - Amac" olarak TEK TEK duruyor -> aralik acilip ilk paragraf aranir.
#  (b) TURKCE HARF: "MSUGT Tekduzen Hesap Plani" arandi, ambarda "Tekduzen" DEGIL
#      "Tekduzen"in u-umlautlu hali var -> katlanmis ad kumesi eklendi.
$ambarKatli=New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
function HarfKatla([string]$s){
  ("$s" -creplace 'İ','i' -creplace 'I','i' -creplace 'ı','i' -creplace 'Ğ','g' -creplace 'ğ','g' `
        -creplace 'Ü','u' -creplace 'ü','u' -creplace 'Ş','s' -creplace 'ş','s' `
        -creplace 'Ö','o' -creplace 'ö','o' -creplace 'Ç','c' -creplace 'ç','c').ToLowerInvariant()
}
foreach($ad in $sirali){ [void]$ambarKatli.Add((HarfKatla $ad)) }
$katliDizi=@($ambarKatli)
# 02.09 iki eslesme daha (olculdu):
#  "MSUGT Tekduzen Hesap Plani - 120" -> ambarda "THP 120 - Alicilar"
#  "BDS 230 madde 16" / "BDS 500 A31" -> ambarda "BDS 230 p.16" / "BDS 500 p.A31"
function EsAdlar([string]$dayanak){
  $liste=New-Object System.Collections.Generic.List[string]
  $m1=[regex]::Match($dayanak,'(?i)MSUGT.*?(\d{3})\s*$')
  if($m1.Success){ $liste.Add("THP $($m1.Groups[1].Value)") }
  # 03.09: hesap numarasiz genel "MSUGT Tekduzen Hesap Plani" (53 kayit) -> ambarda MSUGT
  # tebligi (42 parca) + THP hesaplari var; genel dayanak MSUGT onekiyle esleşir.
  if($dayanak -match '(?i)^MSUGT' -and -not $m1.Success){ $liste.Add('MSUGT') }
  # 03.09: MULGA STANDART -> HALEF (uretici HalefStandart ile ayni tablo). Mulga metni
  # yutmak yanlis; halef ambarda ise dayanak KARSILIKLIDIR.
  $halef=@{ 'KKS 1'='KYS 1'; 'TMS 18'='TFRS 15'; 'TMS 11'='TFRS 15'; 'TFRS 4'='TFRS 17'; 'TMS 17'='TFRS 16'; 'TMS 39'='TFRS 9'; 'TMS 31'='TFRS 11' }
  foreach($hk in $halef.Keys){ if($dayanak -match ('(?i)^'+[regex]::Escape($hk)+'\b')){ $liste.Add($halef[$hk]) } }
  # 03.09: "BDS 720 p.11/11T - AMACLAR" -> "BDS 720 p.11"
  $m3=[regex]::Match($dayanak,'^((?:TMS|TFRS|BDS|GDS|TSRS|SBDS|KKS|KYS)\s*\d+\s*p\.\s*\d+)/')
  if($m3.Success){ $liste.Add($m3.Groups[1].Value) }
  $m2=[regex]::Match($dayanak,'(?i)^((?:TMS|TFRS|BDS|GDS|TSRS|SBDS|KKS|KYS)\s*\d+)[\s,]+(?:madde|md\.?|Ek)?\s*(A?\d+)')
  if($m2.Success){ $liste.Add(("{0} p.{1}" -f $m2.Groups[1].Value,$m2.Groups[2].Value)) }
  # 03.09: "BDS 530 Denetimde Örnekleme, md.5" / ", madde 7" / ", Ek 3" (arada baslik var)
  $m4=[regex]::Match($dayanak,'(?i)^((?:TMS|TFRS|BDS|GDS|TSRS|SBDS|KKS|KYS)\s*\d+)\b[^,]*,\s*(?:madde|md\.?|par\.?|p\.)\s*(A?\d+)')
  if($m4.Success){ $liste.Add(("{0} p.{1}" -f $m4.Groups[1].Value,$m4.Groups[2].Value)) }
  $m5=[regex]::Match($dayanak,'(?i)^((?:TMS|TFRS|BDS|GDS|TSRS|SBDS|KKS|KYS)\s*\d+)\b[^,]*,\s*Ek\s*-?\s*(\d+)')
  if($m5.Success){ $liste.Add(("{0} Ek-{1}" -f $m5.Groups[1].Value,$m5.Groups[2].Value)); $liste.Add(("{0} Ek {1}" -f $m5.Groups[1].Value,$m5.Groups[2].Value)); $liste.Add(("{0} p.Ek{1}" -f $m5.Groups[1].Value,$m5.Groups[2].Value)) }
  # 03.09: "Tekdüzen Hesap Planı - 101 Alınan Çekler ..." / "1 Sıra No'lu MSUGT ... - 622 ..." -> THP 101 / THP 622
  $m6=[regex]::Match($dayanak,'(?i)(Tekd[üu]zen Hesap Plan[ıi]|Muhasebe Sistemi Uygulama Genel Tebli[ğg]i|MSUGT).*?\b([1-7]\d{2})\b')
  if($m6.Success){ $liste.Add("THP $($m6.Groups[2].Value)") }
  # 03.09: "BDS 500 Denetim Kanıtı, A31" / "BDS 500 madde A14-A25" / "BDS 200, Ek Açıklama A32-A40" -> "BDS 500 p.A31"
  $m7=[regex]::Match($dayanak,'(?i)^((?:BDS|GDS|SBDS|KYS)\s*\d+)\b.*?\b(A\d+)')
  if($m7.Success){ $liste.Add(("{0} p.{1}" -f $m7.Groups[1].Value,$m7.Groups[2].Value)) }
  # 03.09: "TMS 1, Bölüm 66-76" -> "TMS 1 p.66" ; "TDHP 380 ..." / "TDHP - 245 ..." -> "THP 380"
  $m9=[regex]::Match($dayanak,'(?i)^((?:TMS|TFRS|TSRS)\s*\d+)\b.*?B[öo]l[üu]m\s*(\d+)')
  if($m9.Success){ $liste.Add(("{0} p.{1}" -f $m9.Groups[1].Value,$m9.Groups[2].Value)) }
  $m10=[regex]::Match($dayanak,'(?i)\bTDHP\b\D{0,40}?([1-7]\d{2})\b')
  if($m10.Success){ $liste.Add("THP $($m10.Groups[1].Value)") }
  # 03.09: "TFRS 16 Kiralamalar p.33 ve p.38" / "BDS 230 (Belgelendirme) p.14-15" / "TSRS 2 ... p.29(a)" -> ilk paragraf
  $m8=[regex]::Match($dayanak,'(?i)^((?:TMS|TFRS|BDS|GDS|TSRS|SBDS|KKS|KYS)\s*\d+)\b.*?\bp\.\s*(\d+)')
  if($m8.Success){ $liste.Add(("{0} p.{1}" -f $m8.Groups[1].Value,$m8.Groups[2].Value)) }
  return @($liste)
}
function AralikAc([string]$dayanak){
  # "TMS 40 p.1-4 - Amac" -> "TMS 40 p.1" ; "BDS 540 p.1-11 - ..." -> "BDS 540 p.1"
  $m=[regex]::Match($dayanak,'^((?:TMS|TFRS|BDS|GDS|TSRS|SBDS|KKS)\s*\d+\s*p\.\s*)(\d+)\s*-\s*\d+')
  if($m.Success){ return ($m.Groups[1].Value+$m.Groups[2].Value) }
  return ''
}
# 03.09: MEVZUAT-DISI dayanak (Turkce/yabanci dil/matematik kurallari) "bulunmayan" degil,
# ayri siniftir - fabrika bu derslere girmez, elle yazilir (konu-kaynak-karnesi MEVZUAT_DISI ile ayni kural).
function MevzuatDisiMi([string]$dayanak){
  return ($dayanak -match '(?i)^TDK\b|kural[ıi]\s*$|kullan[ıi]m kural|paragraf|conditional|tense|causative|passive|reported speech|relative clause|modal|gerund|infinitive|phrasal|anlat[ıi]m|c[üu]mle|noktalama|yaz[ıi]m|s[öo]zc[üu]k|deyim|mecaz|say[ıi] dizi|ard[ıi]ş[ıi]k|olas[ıi]l[ıi]k|denklem|matematik|istatistik|\brule\b|\busage\b|formation|adjective|adverb|preposition|vocabulary|collocation|inversion|\bwish\b|\bwould\b|kelime bilgisi|okuma anlama|d[üu]nya sava|ink[ıi]lap|Atat[üu]rk|cumhuriyet d[öo]nemi|mill[iî] m[üu]cadele|ba[ğg]la[cç]|participle|used to|either|neither|pronoun|\bfiil\b|ferman|g[öo]kalp|\bzarf|[öo]zne|d[üu][şs][üu]nce|tamlama|s[ıi]fat|zaman ad|anlam fark|anlaml[ıi]|terminoloji|tanzimat|me[şs]rutiyet|osmanl[ıi]|lozan|sevr|kurtulu[şs]|padi[şs]ah|sadrazam|\bbe used\b|t[üu]rev|fonksiyon|mant[ıi]k|[öo]nerme|antla[şs]ma|ate[şs]kes|isyan|tarih bilgisi|tarih/s[üu]re|tarih/g[üu]n|toplama i[şs]lemi|oran-orant|oran orant|y[üu]zde hesap|y[üu]zdelerin|y[üu]zde art[ıi][şs]|kesir|integral|limit hesap|trigonometri|\bshould\b|\bcould\b|\bmust|\bfor vs|\bsince\b|\balthough\b|\bcomparative\b|affect-effect|\bvs\b|\bwhere\b|look forward|despite|past simple|belirte[çc]|edat|kal[ıi]b[ıi]\b')
}
function AmbardaVarMi([string]$dayanak){
  # 03.09: V1 koprusunden sarkan "  ⚠ ambarda YOK" kuyrugu ad kiyasini bozuyordu
  $dayanak=($dayanak -replace '\s*⚠.*$','').Trim()
  if($ambarAdlari.Contains($dayanak)){ return 'birebir' }
  # 03.09: "Teori Notu - X" icin GEVSEK onek ("teori notu" ile baslayan HERHANGI bir not) yanlis
  # pozitifti; teori notlari TAM ADLA aranir (katlanmis), yoksa gercekten yoktur.
  if($dayanak -match '(?i)^(Teori Notu|TEORI)\s*[-—–]'){
    # "(ogreti notu)" kuyrugu ve "TEORI - " / "Teori Notu — " onekleri atilir; govde iki yonlu
    # onekle kiyaslanir (>=20 kr). Olmazsa en az iki anahtar kokle TEORI adlarinda aranir.
    $govdeTeori=(($dayanak -replace '\s*\([^)]*\)\s*$','') -replace '(?i)^(Teori Notu|TEORI)\s*[-—–]\s*','').Trim()
    $tamKat=HarfKatla $govdeTeori
    if($tamKat.Length -ge 20){
      foreach($ad in $katliDizi){
        if(-not $ad.StartsWith('teori')){ continue }
        $adGovde=($ad -replace '^(teori notu|teori)\s*[-—–]\s*','')
        if($adGovde.StartsWith($tamKat,[StringComparison]::OrdinalIgnoreCase) -or ($adGovde.Length -ge 20 -and $tamKat.StartsWith($adGovde,[StringComparison]::OrdinalIgnoreCase))){ return 'teori-tam-ad' }
      }
    }
    $kokler=@(($tamKat -split '[^a-z0-9]+') | Where-Object { $_.Length -ge 5 -and $_ -notmatch '^(ogreti|notu|temel|kavram|genel|ilkele|teori)' } | Select-Object -First 5 | ForEach-Object { if($_.Length -ge 7){ $_.Substring(0,$_.Length-2) } else { $_ } })
    if($kokler.Count -ge 2){
      foreach($ad in $katliDizi){
        if(-not $ad.StartsWith('teori')){ continue }
        $tutan=@($kokler | Where-Object { $ad.Contains($_) }).Count
        if($tutan -ge 2){ return 'teori-anahtar-kelime' }
      }
    }
    return ''
  }
  # 03.09: "Mali Analiz Teknikleri - Dikey Yuzde", "Mikroiktisat - Capraz Talep Esnekligi",
  # "Kamu Maliyesi Teorisi - GSYH Deflatoru": teori dayanagi baska baslikla. Ambardaki TEORI
  # adlarinda konunun EN AZ IKI anahtar koku birlikte geciyorsa karsiligi var sayilir.
  if($dayanak -match '(?i)Teknikleri|Teorisi|Mikroiktisat|Makroiktisat|Mikroekonomi|Makroekonomi|Kamu Maliyesi|analiz tekni|T[ÜU][İI]K|TCMB|Uluslararas[ıi] [İi]ktisat|Marshall|Maliye Politikas|Maliyet Muhasebesi -|Mali Tablolar Analizi -|Kanuni bir dayana|Esneklik'){
    $kokler=@((HarfKatla ($dayanak -replace '^[^-–—]*[-–—]\s*','')) -split '[^a-z0-9]+' | Where-Object { $_.Length -ge 5 -and $_ -notmatch '^(analiz|teknik|yontem|yuzde|kural|degis|oran)' } | Select-Object -First 4 | ForEach-Object { if($_.Length -ge 7){ $_.Substring(0,$_.Length-2) } else { $_ } })
    if($kokler.Count -ge 2){
      foreach($ad in $katliDizi){
        if(-not $ad.StartsWith('teori')){ continue }
        $tutan=@($kokler | Where-Object { $ad.Contains($_) }).Count
        if($tutan -ge 2){ return 'teori-anahtar-kelime' }
      }
    }
  }
  # paragraf araligi
  $ilkPar=AralikAc $dayanak
  if($ilkPar){
    $ilkKat=HarfKatla $ilkPar
    foreach($ad in $katliDizi){ if($ad.StartsWith($ilkKat,[StringComparison]::OrdinalIgnoreCase)){ return 'paragraf-araligi' } }
  }
  # es-ad eslemesi (MSUGT->THP, "madde N"->"p.N")
  foreach($es in (EsAdlar $dayanak)){
    $esKat=HarfKatla $es
    foreach($ad in $katliDizi){ if($ad.StartsWith($esKat,[StringComparison]::OrdinalIgnoreCase)){ return 'es-ad' } }
  }
  # turkce harf katlamasi ile onek
  $dayKat=HarfKatla (($dayanak -replace ' - .*$','').Trim())
  if($dayKat.Length -ge 6){
    foreach($ad in $katliDizi){ if($ad.StartsWith($dayKat,[StringComparison]::OrdinalIgnoreCase)){ return 'harf-katlamasi' } }
  }
  $cekirdek=($dayanak -replace ' - .*$','').Trim()
  if($cekirdek -ne $dayanak -and $ambarAdlari.Contains($cekirdek)){ return 'cekirdek' }
  $anahtar=DayanakAnahtar $dayanak
  if($anahtar -and $ambarAnahtar.Contains($anahtar)){ return 'normalize-anahtar' }
  foreach($ad in $sirali){ if($ad.StartsWith($dayanak,[StringComparison]::OrdinalIgnoreCase)){ return 'onek' } }
  if($cekirdek -ne $dayanak){
    foreach($ad in $sirali){ if($ad.StartsWith($cekirdek,[StringComparison]::OrdinalIgnoreCase)){ return 'cekirdek-onek' } }
  }
  # kimlik eslesmesi: kanun/standart + madde/paragraf ikilisi ambarda geciyor mu
  $kimlikler=@(KimlikCikar $dayanak)
  if($kimlikler.Count -ge 2){
    $tutan=@($kimlikler | Where-Object { $ambarKimlik.Contains($_) }).Count
    if($tutan -eq $kimlikler.Count){ return 'kimlik' }
  }
  return ''
}

$tam=Get-Content (Join-Path $depoKok 'veri\fabrika\konu-koprusu.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$sayac=@{}
foreach($kayit in @($tam)){
  $day="$($kayit.dayanak)"; if(-not $day){ $day="$($kayit.cikmis_dayanak)" }
  $day=($day -replace '\s*\(\d+\)\s*$','').Trim()
  if(-not $day){ continue }
  if(-not $sayac.ContainsKey($day)){ $sayac[$day]=0 }
  $sayac[$day]++
}
Write-Host "koprude tekil dayanak: $($sayac.Keys.Count)"

$metinsiz=New-Object System.Collections.Generic.List[object]
$mevzuatDisi=New-Object System.Collections.Generic.List[object]
$varSayi=0; $yokKayit=0; $disiKayit=0
$yolSayac=@{}
$adaylar=@($sayac.Keys | Where-Object { $sayac[$_] -ge $EnAzKonu })
$ilerleme=0
foreach($dayanak in $adaylar){
  $ilerleme++
  if($ilerleme % 500 -eq 0){ Write-Host "  ...$ilerleme / $($adaylar.Count)" }
  if(MevzuatDisiMi $dayanak){ $disiKayit += $sayac[$dayanak]; $mevzuatDisi.Add([pscustomobject][ordered]@{ dayanak=$dayanak; etkilenen_kayit=$sayac[$dayanak] }); continue }
  $durum=AmbardaVarMi $dayanak
  if($durum){ $varSayi++; if(-not $yolSayac.ContainsKey($durum)){ $yolSayac[$durum]=0 }; $yolSayac[$durum]++; continue }
  $yokKayit += $sayac[$dayanak]
  $metinsiz.Add([pscustomobject][ordered]@{ dayanak=$dayanak; etkilenen_kayit=$sayac[$dayanak] })
}
$sirali2=@($metinsiz | Sort-Object { -[int]$_.etkilenen_kayit })
$siraliDisi=@($mevzuatDisi | Sort-Object { -[int]$_.etkilenen_kayit })

$cikti=[pscustomobject][ordered]@{
  aciklama="Koprudeki dayanaklarin ambarda KARSILIGI var mi taramasi. Karsiligi olmayan dayanak = OLCULEMEZ konu: hakem dogrulayamaz, uretici kaynak metnini cekemez, soru uretilemez. Bunlar cop DEGILDIR - kaynak eksigidir. Eslesme uc yolla denenir: birebir ad, ' - aciklama' atilmis cekirdek, onek eslesmesi."
  ambar_tekil_ad=$ambarAdlari.Count
  kopru_tekil_dayanak=$sayac.Keys.Count
  ambarda_bulunan=$varSayi
  ambarda_BULUNMAYAN=$metinsiz.Count
  bulunmayan_yuzde=$(if($adaylar.Count){[math]::Round(100*$metinsiz.Count/$adaylar.Count,1)}else{0})
  etkilenen_kopru_kaydi=$yokKayit
  mevzuat_disi_dayanak=$mevzuatDisi.Count
  mevzuat_disi_kayit=$disiKayit
  eslesme_yollari=$yolSayac
  en_cok_etkileyenler=@($sirali2 | Select-Object -First $ListeTavan | ForEach-Object { "$($_.dayanak) -> $($_.etkilenen_kayit) kayit" })
  mevzuat_disi_ornekleri=@($siraliDisi | Select-Object -First 15 | ForEach-Object { "$($_.dayanak) -> $($_.etkilenen_kayit) kayit" })
}
. (Join-Path $depoKok 'arac\rapor-yaz.ps1')
RaporYaz -Hedef (Join-Path $depoKok 'veri\dayanak-metinsiz-raporu.json') -Nesne $cikti

Write-Host ""
Write-Host "=== METINSIZ DAYANAK ==="
Write-Host ("  ambarda bulunan   : {0}" -f $varSayi)
Write-Host ("  BULUNMAYAN        : {0}  (%{1})" -f $metinsiz.Count,$cikti.bulunmayan_yuzde)
Write-Host ("  etkilenen kayit   : {0} / {1}" -f $yokKayit,@($tam).Count)
Write-Host ""
Write-Host "--- EN COK KAYIT ETKILEYEN METINSIZ DAYANAKLAR ---"
foreach($ornek in @($sirali2 | Select-Object -First 25)){
  Write-Host ("  {0,5} kayit <- {1}" -f $ornek.etkilenen_kayit,$ornek.dayanak)
}
