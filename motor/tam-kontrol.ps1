# ============================================================================
#  TAM KONTROL — TEK HAT, TEK HÜKÜM  (25.08.2026)
#
#  CEM: "her soruda bir eksik çıkıyor sonra tekrar başa dönüyoruz, çok sıkıcı.
#        tüm kontrolleri kurup bir 100 soru yapsak"
#
#  HAKLI. Bugüne kadarki yöntem kusurluydu: her yeni mercek yeni bulgu veriyor,
#  liste bitmiyordu. ALTIN-STANDART-200.md bunu zaten yazmış:
#  "bu dosya soruyu tersine çevirir: 'başka ne bozuk?' değil,
#   'bu soru standarda uyuyor mu?' — evet/hayır, SONLU."
#
#  BU BETİK O DOSYANIN ÇALIŞAN HÂLİDİR. Bir soru girer, TEK HÜKÜM çıkar:
#     UYGUN | KUSURLU | ÖLÇÜLEMEDİ
#  Bir daha "başka ne bozuk" diye bakılmaz; kapı listesi burada ve sonludur.
#
#  ---------------------------------------------------------------- KAPILAR
#  A) DETERMİNİSTİK (0 USD, model yok) — 10 kapı:
#     D1  Türkçe ASCII bozulması        (ölçüm 25.08: kasada 288 soru)
#     D2  Şık-açıklama uyumu            (ölçüm 25.08: 1.302 soru — YENİ)
#     D3  Şık bütünlüğü (5 şık, boş yok)
#     D4  Doğru şık en uzun mu          (okumadan bilme ipucu)
#     D5  Mutlak terim ipucu            (asla/her zaman/hiçbir)
#     D6  Açıklama kopyası              (iki şıkta aynı cümle — SINAV-KURALLARI E3)
#     D7  Hap kartı hap mı              (200+ karakter = özet, hap değil)
#     D8  Dört parça düzeni             (Ne soruluyor/Kural/Bu olayda/Akılda kalsın)
#     D9  Fıkra atfı uydurma            (kaynak metni numaralandırma taşımıyorsa)
#     D10 Uydurma rakam ADAYI           (açıklamadaki rakam soruda yok ve türetilemiyor)
#
#  B) İÇERİK (tek model çağrısı, maddenin TAM METNİYLE) — 8 kapı:
#     M1  Cevap doğru mu                (maddeden BİREBİR ALINTIYLA)
#     M2  Tek doğru şık mı
#     M3  Açıklama maddeyle çelişiyor mu
#     M4  Her yanlış şık KENDİ şıkkını mı anlatıyor
#     M5  Kaynak konuyu kapsıyor mu
#     M6  Öğretiyor mu (bir benzerini çözdürür mü)
#     M7  Yapay zekâ kokusu
#     M8  Mevzuat güncel mi (metindeki değişiklik izlerine göre)
#
#  C) HAKEMİN HAKEMİ: model her hükmünü maddeden BİREBİR ALINTIYLA kanıtlar.
#     Alıntı gerçekten madde metninde geçiyor mu diye MAKİNEYLE bakılır.
#     Geçmiyorsa hüküm ÇÖPE ATILIR ve soru ÖLÇÜLEMEDİ olur. (profesor-v2 deseni)
#
#  KURAL: metni çözülemeyen soru YARGILANMAZ, 'ÖLÇÜLEMEDİ' işaretlenir.
#  Emin olunmayana kusur denmez — ölçülemeyen şey de temiz sayılmaz.
#
#  ÇIKTI: veri/fabrika/tam-kontrol-<tarih>.json (gitignore'lu — paralı içerik)
#         + veri/tam-kontrol-raporu.json (yalnız SAYILAR, içerik yok)
# ============================================================================
param(
  [int]$adet = 100,
  [string]$havuz = 'iki-kanitli',      # iki-kanitli | kasa
  [string]$idler = '',                 # dosyadan id listesi (her satır bir id)
  [string]$yerelDosya = '',            # kasadan DEĞİL bu JSON'dan oku (yeni üretilen sorular)
  [string]$model = 'claude-sonnet-5',
  [int]$tohum = 20260825,
  [switch]$olcum                       # PARA HARCAMAZ: yalnız deterministik kapılar
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
if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host 'SUPABASE_SERVICE_KEY yok.'; exit 1 }
if(-not $env:ANTHROPIC_API_KEY){ $env:ANTHROPIC_API_KEY = [Environment]::GetEnvironmentVariable('ANTHROPIC_API_KEY','User') }

$raporYol = Join-Path $kok 'veri/tam-kontrol-raporu.json'
function RaporYaz($n){ [IO.File]::WriteAllText($raporYol, (ConvertTo-Json -InputObject $n -Depth 8), (New-Object Text.UTF8Encoding($false))) }
trap {
  RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='HATA'; hata="$($_.Exception.Message)"; satir=$_.InvocationInfo.ScriptLineNumber })
  Write-Host ("HATA (satir {0}): {1}" -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.Message); exit 1
}
. (Join-Path $here 'madde-coz.ps1') -kutuphane

Add-Type -AssemblyName System.Net.Http
$hc = New-Object System.Net.Http.HttpClient
$hc.Timeout = [TimeSpan]::FromSeconds(300)
$hc.DefaultRequestHeaders.Add('apikey', $env:SUPABASE_SERVICE_KEY)
$hc.DefaultRequestHeaders.Add('Authorization', "Bearer $($env:SUPABASE_SERVICE_KEY)")
$hc.DefaultRequestHeaders.UserAgent.ParseAdd('mevzuat-radar-robot/1.0')
$U = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/soru_havuzu'
$HARFLER = @('A','B','C','D','E')   # $H KULLANMA: PS harf ayirmaz, $hf dongu degiskeni ezer

# ============================================================ YARDIMCILAR
$RX_SAYI = [regex]'\d[\d\.]*(?:,\d+)?'
function ToNum([string]$s){
  $n = ($s -replace '\.','') -replace ',','.'
  [double]$d = 0
  if([double]::TryParse($n,[Globalization.NumberStyles]::Float,[Globalization.CultureInfo]::InvariantCulture,[ref]$d)){ $d } else { $null }
}
function Sayilar([string]$t){
  $r = @(); foreach($m in $RX_SAYI.Matches("$t")){ $v = ToNum $m.Value; if($null -ne $v){ $r += $v } }
  return $r
}
# Normalize: alinti dogrulamasi icin. Turkce harf + noktalama farkini eritir.
function Duz([string]$t){
  $s = "$t".ToLowerInvariant()
  $s = $s -replace '[ıİi]','i' -replace '[şŞ]','s' -replace '[ğĞ]','g' -replace '[üÜ]','u' -replace '[öÖ]','o' -replace '[çÇ]','c'
  $s = $s -replace '[^a-z0-9]',' '
  return ($s -replace '\s+',' ').Trim()
}

# ============================================================ ONBELLEKLER
# Uc kapi (Y3 THP · Y4 cikmis ortusme · Y5 mukerrer) buyuk veri ister.
# Her kosuda yeniden cekmek dakikalar surer; diske onbelleklenir.
# ONBELLEK PARALI ICERIK TASIYABILIR -> veri/fabrika/ (gitignore'lu).
$obDir = Join-Path $kok 'veri/fabrika'
$null = New-Item -ItemType Directory -Force $obDir

function KelimeDizi([string]$t){
  $d = Duz $t
  return @($d -split ' ' | Where-Object { $_.Length -gt 1 })
}
# 8 kelimelik parmak izi. Kisa n-gram Turkce muhasebe dilinde her yerde geciyor
# (yalanci eslesme); 8 kelime birebir tekrar ederse bu tesaduf degildir.
function Parmak([string]$t, [int]$n = 8){
  $k = KelimeDizi $t
  $r = New-Object System.Collections.Generic.HashSet[string]
  if($k.Count -lt $n){ if($k.Count -ge 4){ [void]$r.Add(($k -join ' ')) }; return $r }
  for($i=0; $i -le $k.Count-$n; $i++){ [void]$r.Add(($k[$i..($i+$n-1)] -join ' ')) }
  return $r
}
function Ortusme($parmak, $kume){
  if($parmak.Count -eq 0){ return 0.0 }
  $v = 0; foreach($p in $parmak){ if($kume.Contains($p)){ $v++ } }
  return [math]::Round($v / $parmak.Count, 3)
}

# --- THP kod -> resmi ad haritasi (Y3)
$thpYol = Join-Path $obDir 'ob-thp.json'
$THP = @{}
if(Test-Path $thpYol){
  $tmp = Get-Content $thpYol -Raw -Encoding UTF8 | ConvertFrom-Json
  foreach($p in $tmp.PSObject.Properties){ $THP[$p.Name] = "$($p.Value)" }
  Write-Host ("THP haritasi onbellekten: {0} hesap" -f $THP.Count)
} else {
  Write-Host 'THP haritasi cekiliyor...'
  $sonId=''
  for($s=0;$s -lt 40;$s++){
    $f = if($sonId){ '&id=gt.'+[uri]::EscapeDataString($sonId) } else { '' }
    $b = $hc.GetStringAsync("https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar?select=id,kaynak_ad&kaynak_ad=like.THP%20*&order=id&limit=1000$f").GetAwaiter().GetResult()
    $r = @(($b|ConvertFrom-Json)|ForEach-Object{$_})
    if(-not $r.Count){ break }
    foreach($x in $r){
      # "THP 100 KASA" -> kod 100, ad KASA.  Ders: THP'de ad "kod - AD" olarak
      # gecer, ayirici tire OLMAYABILIR; ikisini de kabul et.
      if("$($x.kaynak_ad)" -match '^THP\s+(\d{3})\s*[-–]?\s*(.+)$'){
        $kod = $Matches[1]; $ad = $Matches[2].Trim()
        if(-not $THP.ContainsKey($kod)){ $THP[$kod] = $ad }
      }
    }
    $sonId = "$(@($r)[-1].id)"; if($r.Count -lt 1000){ break }
  }
  [IO.File]::WriteAllText($thpYol, (ConvertTo-Json -InputObject $THP -Depth 3), (New-Object Text.UTF8Encoding($false)))
  Write-Host ("THP haritasi: {0} hesap -> onbellege yazildi" -f $THP.Count)
}

# --- Cikmis sinav parmak izi kumesi (Y4)
$cikmisYol = Join-Path $obDir 'ob-cikmis-parmak.txt'
$CIKMIS = New-Object System.Collections.Generic.HashSet[string]
if(Test-Path $cikmisYol){
  foreach($l in [IO.File]::ReadAllLines($cikmisYol)){ if($l){ [void]$CIKMIS.Add($l) } }
  Write-Host ("Cikmis parmak izi onbellekten: {0} desen" -f $CIKMIS.Count)
} else {
  Write-Host 'Cikmis sinav arsivi cekiliyor (253 belge, bir kez)...'
  $sonId=''; $belge=0
  for($s=0;$s -lt 60;$s++){
    $f = if($sonId){ '&id=gt.'+[uri]::EscapeDataString($sonId) } else { '' }
    $b = $hc.GetStringAsync("https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar?select=id,metin&tur=eq.cikmis-soru&order=id&limit=10$f").GetAwaiter().GetResult()
    $r = @(($b|ConvertFrom-Json)|ForEach-Object{$_})
    if(-not $r.Count){ break }
    foreach($x in $r){ $belge++; foreach($p in (Parmak "$($x.metin)")){ [void]$CIKMIS.Add($p) } }
    $sonId = "$(@($r)[-1].id)"; if($r.Count -lt 10){ break }
    if($belge % 50 -eq 0){ Write-Host ("  ...{0} belge" -f $belge) }
  }
  [IO.File]::WriteAllLines($cikmisYol, @($CIKMIS), (New-Object Text.UTF8Encoding($false)))
  Write-Host ("Cikmis: {0} belge -> {1} parmak izi deseni" -f $belge,$CIKMIS.Count)
}

# --- Kasa govde parmak izi (Y5 mukerrer). id -> parmak, karsilastirma icin.
$kasaYol = Join-Path $obDir 'ob-kasa-kok.json'
$KASA_KOK = @{}
if(Test-Path $kasaYol){
  $tmp = Get-Content $kasaYol -Raw -Encoding UTF8 | ConvertFrom-Json
  foreach($p in $tmp.PSObject.Properties){ $KASA_KOK[$p.Name] = "$($p.Value)" }
  Write-Host ("Kasa kok onbellekten: {0}" -f $KASA_KOK.Count)
} else {
  Write-Host 'Kasa koklerı cekiliyor (mukerrer kapisi icin, bir kez)...'
  $sonId=''
  for($s=0;$s -lt 200;$s++){
    $f = if($sonId){ '&id=gt.'+[uri]::EscapeDataString($sonId) } else { '' }
    $b = $hc.GetStringAsync("$U`?select=id,soru&order=id&limit=1000$f").GetAwaiter().GetResult()
    $r = @(($b|ConvertFrom-Json)|ForEach-Object{$_})
    if(-not $r.Count){ break }
    foreach($x in $r){ $KASA_KOK["$($x.id)"] = Duz "$($x.soru)" }
    $sonId = "$(@($r)[-1].id)"; if($r.Count -lt 1000){ break }
    if($s -eq 199){ throw 'SAYFA TAVANINA CARPILDI - kasa eksik.' }
  }
  [IO.File]::WriteAllText($kasaYol, (ConvertTo-Json -InputObject $KASA_KOK -Depth 3), (New-Object Text.UTF8Encoding($false)))
  Write-Host ("Kasa kok: {0} -> onbellege yazildi" -f $KASA_KOK.Count)
}
# Mukerrer icin ters indeks: parmak deseni -> ilk goren id
$KASA_INDEKS = @{}
foreach($p in $KASA_KOK.GetEnumerator()){
  foreach($d in (Parmak $p.Value)){ if(-not $KASA_INDEKS.ContainsKey($d)){ $KASA_INDEKS[$d] = $p.Key } }
}
Write-Host ("Mukerrer indeksi: {0} desen" -f $KASA_INDEKS.Count)

# --- Yetki devri ibareleri (Y1). Madde bunlari tasiyorsa SABIT RAKAM ezberleten
#     soru, ikincil duzenleme kontrol edilmeden 'uygun' olamaz.
#     Ders: 5746 vakasi (kanun 50 der, gercek esik 15) · 7566 (5 puan -> 2 puan).
$YETKI = [regex]'(?i)(Cumhurba[şs]kan[ıi].{0,40}(yetkili|belirlemeye|art[ıi]rmaya|indirmeye)|Bakanlar Kurulu.{0,40}yetkili|Bakanl[ıi]k[çc]a belirlen|tebli[ğg]le belirlen|Y[öo]netmelikle belirlen|her y[ıi]l.{0,30}(yeniden de[ğg]erleme|art[ıi]r[ıi]l))'

# ============================================================ KAPILARIN SINAVI
# 25.08 DERSI: bugun dort olcum aracim yanlis sonuc verdi ve dordu de ilk
# bakista "temiz" diyordu (\w Turkce harfi kapsiyor · sayfa tavani sessiz
# kesiyor · $H/$hf cakismasi · fikra deseni satir basi ariyordu).
# ARTIK KURAL: bir kapi, BILINEN vakalari dogru ayirt ettigini kanitlamadan
# kosmaz. Kapi kendi sinavini gecemezse betik DURUR - yanlis rakam uretmektense
# hic rakam uretmemek yeglenir.
function KapiSinavi(){
  $hata = @()

  # S1 — Fikra kapisi: Is K. m.11 metni fikrasiz (uydurma yakalanmali),
  #      TTK m.55 metni fikrali (yakalanmamali).
  $fikrasiz = 'Madde 11 - Is iliskisinin bir sureye bagli olarak yapilmadigi halde sozlesme belirsiz sureli sayilir.'
  $fikrali  = 'MADDE 55- (1) Asagida sayilan haller haksiz rekabet hallerinin baslicalaridir: a) ... (2) Ikinci fikra.'
  $f1 = ($fikrasiz -match '(?i)MADDE\s*\d+\s*[-–]\s*\(\s*1\s*\)')
  $n1 = @(); foreach($m in [regex]::Matches($fikrasiz,'\(\s*([1-9]\d?)\s*\)')){ $n1 += $m.Groups[1].Value }
  if($f1 -or ($n1.Count -ge 2)){ $hata += 'S1a: fikrasiz metin FIKRALI sayildi' }
  $f2 = ($fikrali -match '(?i)MADDE\s*\d+\s*[-–]\s*\(\s*1\s*\)')
  if(-not $f2){ $hata += 'S1b: fikrali metin FIKRASIZ sayildi (TTK m.55 vakasi)' }

  # S2 — Turkce kapisi: bozuk yazim yakalanmali, DOGRU yazim yakalanmamali.
  if(-not $D1.IsMatch('sirket 2024 yilinda uretmistir')){ $hata += 'S2a: bozuk Turkce yakalanmadi' }
  if($D1.IsMatch('Şirket 2024 yılında üretmiştir ve hesaplanmıştır')){ $hata += 'S2b: DOGRU Turkce yalanci bayrak aldi' }

  # S3 — Parmak izi: ayni metin %100, alakasiz metin dusuk ortusmeli.
  $a = Parmak 'ayni cumlenin sekiz kelimeden uzun olmasi gerekir ki desen olussun'
  $b = New-Object System.Collections.Generic.HashSet[string]
  foreach($p in $a){ [void]$b.Add($p) }
  if((Ortusme $a $b) -lt 0.99){ $hata += 'S3a: ayni metin %100 ortusmedi' }
  $c = Parmak 'bambaska bir konudan tamamen farkli kelimelerle yazilmis ornek metin burada'
  if((Ortusme $c $b) -gt 0.05){ $hata += 'S3b: alakasiz metin ortusuyor gorundu' }

  # S4 — Sayi cozumu: Turkce binlik/ondalik ayraci.
  if((ToNum '1.847.600') -ne 1847600){ $hata += 'S4a: binlik ayraci yanlis cozuldu' }
  if([math]::Abs((ToNum '634,42') - 634.42) -gt 0.001){ $hata += 'S4b: ondalik ayraci yanlis cozuldu' }

  # S5 — D11 aritmetik kapisi: ELLE DOGRULANMIS bozuk soruyu (28453f9c)
  #      yakalamali; DOGRU kurulmus esdegerini yakalamamali.
  $bozuk = [pscustomobject]@{
    id='S5-bozuk'; ders='Maliyet Muhasebesi'; konu='test'; dogru='D'; hap='kisa hap'; tablo=$null
    soru='Ocak ayinda 180 adet kapi imal edilmistir. Ilk madde ve malzeme: 87.450 TL, Iscilik: 41.280 TL, Genel uretim giderleri: 18.670 TL, Genel idare giderleri: 12.900 TL. Isletme genel idare giderlerini maliyete dahil etmektedir. Birim maliyet kac TL?'
    siklar=[pscustomobject]@{ A='714,00'; B='796,11'; C='842,78'; D='888,50'; E='1.032,60' }
    aciklama=[pscustomobject]@{ A='Ne soruluyor: test. Kural: test. Bu olayda: test. Akılda kalsın: test.'; B='TUZAK: test'; C='TUZAK: test'; D='Ne soruluyor: birim maliyet. Kural: VUK. Bu olayda: toplam. Akılda kalsın: test.'; E='TUZAK: test' }
  }
  $dogruKurulu = [pscustomobject]@{
    id='S5-dogru'; ders='Maliyet Muhasebesi'; konu='test'; dogru='D'; hap='kisa hap'; tablo=$null
    soru=$bozuk.soru
    siklar=[pscustomobject]@{ A='714,00'; B='796,11'; C='842,78'; D='890,56'; E='1.032,60' }
    aciklama=$bozuk.aciklama
  }
  $b1 = DeterministikKapilar $bozuk ''
  $b2 = DeterministikKapilar $dogruKurulu ''
  if(-not (@($b1 | Where-Object { "$_" -like 'D11*' }).Count)){ $hata += 'S5a: D11 BOZUK soruyu yakalamadi (28453f9c vakasi)' }
  if(  (@($b2 | Where-Object { "$_" -like 'D11*' }).Count)){ $hata += 'S5b: D11 DOGRU soruya yalanci bayrak verdi' }

  # S6 — IKI KALEM DISLAMA (ALTIN-10 vakasi): dogru cevap 850.000+42.500+18.750
  #      +27.300+15.600 = 954.150; tabloda ayrica dislanan iki kalem var
  #      (173.700 KDV + 9.400 ilgisiz). Kapi buna KUSUR DEMEMELI.
  $ikiDislama = [pscustomobject]@{
    id='S6'; ders='Finansal Muhasebe'; konu='test'; dogru='E'; hap='kisa'
    soru='CNC tezgahinin maliyet bedeli kac TL?'
    tablo=[pscustomobject]@{ baslik='Kalemler'; kolonlar=@('Kalem','Tutar')
      satirlar=@(@('Fatura','850.000'),@('Gumruk','42.500'),@('Nakliye','18.750'),@('Montaj','27.300'),@('Kredi faizi','15.600'),@('Indirilebilir KDV','173.700'),@('Ilgisiz reklam','9.400')) }
    siklar=[pscustomobject]@{ A='1.127.850'; B='926.850'; C='963.550'; D='938.550'; E='954.150' }
    aciklama=[pscustomobject]@{ A='TUZAK: test'; B='TUZAK: test'; C='TUZAK: test'; D='TUZAK: test'
      E='Ne soruluyor: test. Kural: test. Bu olayda: test. Akılda kalsın: test.' }
  }
  $b3 = DeterministikKapilar $ikiDislama ''
  if(@($b3 | Where-Object { "$_" -like 'D11*' }).Count){ $hata += 'S6: D11 iki-kalem-dislamali DOGRU soruya yalanci bayrak verdi (ALTIN-10 vakasi)' }

  # S7 — D12 ayni iskelet: ALTIN-04'un GERCEK metniyle. Uc yanlis sik da
  #      "X sikki ... ; oysa ... bu yuzden X yanlistir" kalibindaydi.
  $ayniIskelet = [pscustomobject]@{
    id='S7'; ders='Ticaret Hukuku'; konu='test'; dogru='D'; hap='kisa'; tablo=$null
    soru='Tacir sifati ile ilgili hangisi dogrudur?'
    siklar=[pscustomobject]@{ A='bir'; B='iki'; C='uc'; D='dort'; E='bes' }
    aciklama=[pscustomobject]@{
      A='A şıkkı işletmenin tamamının kendi adına işletilmesini şart koşuyor; oysa kural açıkça kısmen de olsa işletmeyi yeterli görür, bu yüzden A yanlıştır.'
      B='B şıkkı ilan yoluyla bildirimin yetmediğini iddia ediyor; hâlbuki metin fiilen başlanmasa da tacir sayılacağını söyler, bu yüzden B yanlıştır.'
      C='C şıkkı adi şirket adına işlem yapanın sorumluluğunu tamamen ortadan kaldırıyor; oysa böyle kişi sorumlu tutulur, bu yüzden C yanlıştır.'
      D='Ne soruluyor: test. Kural: test. Bu olayda: test. Akılda kalsın: test.'
      E='E şıkkı sorumluluğu tüm üçüncü kişilere genişletiyor; oysa metin bunu sınırlar, bu yüzden E yanlıştır.' }
  }
  $b4 = DeterministikKapilar $ayniIskelet ''
  if(-not (@($b4 | Where-Object { "$_" -like 'D12*' }).Count)){ $hata += 'S7: D12 AYNI ISKELET kalibini yakalamadi (ALTIN-04 vakasi)' }
  if(-not (@($b4 | Where-Object { "$_" -like 'D8b*' }).Count)){ $hata += 'S7b: D8b yanlis siklarda dort parca eksigini gormedi' }

  # S8 — D12 YALANCI BAYRAK sinavi: dort ayri bicimde kurulmus, DORT PARCALI
  #      aciklamalar bayraklanMAmali.
  $farkliIskelet = [pscustomobject]@{
    id='S8'; ders='Ticaret Hukuku'; konu='test'; dogru='D'; hap='kisa'; tablo=$null
    soru='Tacir sifati ile ilgili hangisi dogrudur?'
    siklar=[pscustomobject]@{ A='bir'; B='iki'; C='uc'; D='dort'; E='bes' }
    aciklama=[pscustomobject]@{
      A='Tuzak: Kendi adına işletmek ile tamamını işletmek karıştırılıyor. Nereden geliyor: Ortaklıkta payı küçük olan tacir sayılmaz sanılır. Kırılma noktası: Maddede kısmen de olsa ifadesi geçer. Bu şık ne zaman doğru olurdu: Kanun tamamını işleten deseydi.'
      B='Tuzak: Sıfatı fiili faaliyete bağlama refleksi. Nereden geliyor: Vergi hukukunda bazı yükümlülükler gerçekten faaliyetle başlar. Kırılma noktası: Metinde başlamamış olsa bile denir. Bu şık ne zaman doğru olurdu: Madde bu ibareyi taşımasaydı.'
      C='Tuzak: Sorumluluğun büsbütün kalkması ile sınırlanması ayrımı. Nereden geliyor: Şirket yoksa borç da yoktur sezgisi. Kırılma noktası: İyiniyetli üçüncü kişiler ibaresi. Bu şık ne zaman doğru olurdu: Metin sorumluluğu hiç saymasaydı.'
      D='Ne soruluyor: test. Kural: test. Bu olayda: test. Akılda kalsın: test.'
      E='Tuzak: Sorumluluğun kapsamı genişletiliyor. Nereden geliyor: Görünüşe güven ilkesi herkesi korur sanılır. Kırılma noktası: Metin iyiniyetli sözcüğüyle sınırlar. Bu şık ne zaman doğru olurdu: Sınırlama yazılmasaydı.' }
  }
  $b5 = DeterministikKapilar $farkliIskelet ''
  if(@($b5 | Where-Object { "$_" -like 'D12*' }).Count){ $hata += 'S8: D12 FARKLI iskeletli aciklamalara yalanci bayrak verdi' }
  if(@($b5 | Where-Object { "$_" -like 'D8b*' }).Count){ $hata += 'S8b: D8b dort parcali yanlis siklara yalanci bayrak verdi' }

  # S9 — D13 tanimsiz terim: aciklamasiz gecen terim yakalanmali,
  #      aciklamali gecen yakalanmaMAmali.
  $tanimsiz = [pscustomobject]@{ id='S9a'; ders='x'; konu='y'; dogru='A'; hap='k'; tablo=$null
    soru='s'; siklar=[pscustomobject]@{A='1';B='2';C='3';D='4';E='5'}
    aciklama=[pscustomobject]@{ A='Ne soruluyor: test. Kural: Mamul maliyeti genel imal gideri ve genel idare gideri paylarını içerir. Bu olayda: test. Akılda kalsın: test.'; B='b';C='c';D='d';E='e' } }
  $tanimli = [pscustomobject]@{ id='S9b'; ders='x'; konu='y'; dogru='A'; hap='k'; tablo=$null
    soru='s'; siklar=[pscustomobject]@{A='1';B='2';C='3';D='4';E='5'}
    aciklama=[pscustomobject]@{ A='Ne soruluyor: test. Kural: Mamul maliyeti genel imal gideri — yani tek bir mamule doğrudan yazılamayan üretim giderleri: fabrika kirası, makine amortismanı — payını içerir; genel idare gideri ise şirketin yönetimiyle ilgili giderdir: genel müdürlük maaşları. Bu olayda: test. Akılda kalsın: test.'; B='b';C='c';D='d';E='e' } }
  if(-not (@((DeterministikKapilar $tanimsiz '') | Where-Object { "$_" -like 'D13*' }).Count)){ $hata += 'S9a: D13 tanimsiz terimi yakalamadi (ALTIN-06 vakasi)' }
  if(  (@((DeterministikKapilar $tanimli  '') | Where-Object { "$_" -like 'D13*' }).Count)){ $hata += 'S9b: D13 ACIKLANMIS terime yalanci bayrak verdi' }

  return ,$hata
}
# NOT: sinav CAGRISI, kapi desenleri ($D1 vb.) tanimlandiktan SONRA yapilir -
# fonksiyon onlari cagri aninda okur. (Ilk yazimda cagri buradaydi ve $D1 henuz
# tanimsizdi: "You cannot call a method on a null-valued expression". Yani kapi
# sinavinin kendisi de sinavdan gecmeliymis.)

# ============================================================ SORULARI SEC
# YEREL DOSYA MODU: yeni uretilen sorular kasaya YAZILMADAN once ayni 26 kapidan
# gecer. Tek kapi takimi, iki kaynak - kapilarin iki ayri kopyasi olursa biri
# gunceIlenir oteki unutulur (bu depoda daha once yasandi).
if($yerelDosya){
  if(-not (Test-Path $yerelDosya)){ throw "Yerel dosya yok: $yerelDosya" }
  $sorular = New-Object System.Collections.Generic.List[object]
  foreach($x in @((Get-Content $yerelDosya -Raw -Encoding UTF8 | ConvertFrom-Json))){ $sorular.Add($x) }
  Write-Host ("YEREL DOSYA: {0} soru  <- {1}" -f $sorular.Count,(Split-Path $yerelDosya -Leaf))
}

if(-not $yerelDosya){
Write-Host 'Sorular seciliyor...'
$secIdler = @()
if($idler -and (Test-Path $idler)){
  $secIdler = @(Get-Content $idler | ForEach-Object { $_.Trim([char]0xFEFF).Trim() } | Where-Object { $_ })
} elseif($havuz -eq 'iki-kanitli'){
  # Aday listesi PARALI ICERIGE isaret eder (hangi sorular yayina yakin) ->
  # veri/fabrika/ altinda tutulur, depoya girmez.
  $y = Join-Path $kok 'veri/fabrika/iki-kanitli-idler.txt'
  if(-not (Test-Path $y)){ throw "veri/fabrika/iki-kanitli-idler.txt yok. -havuz kasa ile calistirin ya da listeyi uretin." }
  $secIdler = @(Get-Content $y | ForEach-Object { $_.Trim([char]0xFEFF).Trim() } | Where-Object { $_ })
} else {
  $sonId=''; $tum=New-Object System.Collections.Generic.List[string]
  for($s=0;$s -lt 200;$s++){
    $f = if($sonId){ '&id=gt.'+[uri]::EscapeDataString($sonId) } else { '' }
    $r=@(($hc.GetStringAsync("$U`?select=id&order=id&limit=1000$f").GetAwaiter().GetResult()|ConvertFrom-Json)|ForEach-Object{$_})
    if(-not $r.Count){break}; foreach($x in $r){ $tum.Add("$($x.id)") }
    $sonId="$(@($r)[-1].id)"; if($r.Count -lt 1000){break}
  }
  $secIdler = @($tum)
}
# SABIT TOHUMLU rastgele secim - cimbizlanmis ornek yasak (13.08 kurali)
$rnd = New-Object Random $tohum
$sec = @(); $alinan = @{}
while($sec.Count -lt [Math]::Min($adet,$secIdler.Count)){
  $c = $secIdler[$rnd.Next(0,$secIdler.Count)]
  if(-not $alinan.ContainsKey($c)){ $alinan[$c]=1; $sec += $c }
}
Write-Host ("Havuz: {0}  ->  secilen: {1}  (tohum {2})" -f $secIdler.Count,$sec.Count,$tohum)

# --- tam metinleri cek (100'luk dilimler)
$sorular = New-Object System.Collections.Generic.List[object]
for($i=0; $i -lt $sec.Count; $i+=50){
  $dilim = $sec[$i..([Math]::Min($i+49,$sec.Count-1))]
  $liste = ($dilim | ForEach-Object { '"'+$_+'"' }) -join ','
  $b = $hc.GetStringAsync("$U`?select=id,sinav,ders,konu,soru,siklar,dogru,aciklama,hap,tablo,kaynak,kanun_no,madde_no,zorluk&id=in.($liste)").GetAwaiter().GetResult()
  foreach($x in @(($b|ConvertFrom-Json)|ForEach-Object{$_})){ $sorular.Add($x) }
}
Write-Host ("Cekilen soru: {0}" -f $sorular.Count)
}   # <- yerelDosya degilse blogu biter

# ============================================================ A) DETERMINISTIK KAPILAR
# ASCII'lesmis Turkce: desenler YALNIZ [a-z] kabul eder. Tek Turkce harf eslesmeyi
# kirar, boylece dogru yazilmis "hesaplanmistir" bayraklanmaz (25.08 kusuru).
$D1_parcalar = @('[a-z]+m[i]stir','[a-z]+mustur','[a-z]+lmis','[a-z]+ilmis','icin','isci[a-z]*','uretim',
  'uretil[a-z]*','uretmis[a-z]*','uretti[a-z]*','sirket[a-z]*','musteri[a-z]*','sozlesme[a-z]*','gorev[a-z]*',
  'donem[a-z]*','gecerli[a-z]*','tutari','degeri','yilinin','yilinda','cikardig[a-z]*','karsilig[a-z]*','ihrac',
  'odenmis','yapilmis','olmustur','bulunmaktadir','gerceklesmis[a-z]*')
$D1 = [regex]('(?i)\b(' + ($D1_parcalar -join '|') + ')\b')
$D5 = [regex]'(?i)\b(asla|her zaman|hi[çc]bir zaman|kesinlikle|mutlaka|t[üu]m[üu]|hepsi|hi[çc]biri)\b'
$D8_parca = @('Ne soruluyor','Kural','Bu olayda','Akılda kalsın')
# YANLIS sikta aranan dort parca (SINAV-KURALLARI E3-b, 25.08)
$D8Y_parca = @('Tuzak','Nereden geliyor','Kırılma noktası','Bu şık ne zaman doğru olurdu')
# D13 terim sozlugu: adayin BILMEDIGI varsayilan meslek terimleri. Liste DAR
# tutulur - genis liste yalanci bayrak uretir. Olcut: "konuyu hic bilmeyen bu
# kelimeyi duyunca ne anlar?" Anlamiyorsa listeye girer.
$TERIMLER = @(
  'genel imal gideri','genel imalat gideri','genel üretim gideri','genel idare gideri',
  'direkt işçilik','direkt ilk madde','ilk madde ve malzeme','iktisadi kıymet',
  'emsal bedel','maliyet bedeli','mukayyet değer','tasarruf değeri','itibari değer',
  'reeskont','karşılık ayırma','amortisman','tahakkuk','envanter',
  'objektif koşul','zincirleme sözleşme','basiretli tüccar','ticari işletme',
  'yan ürün','ortak maliyet','dönüşüm maliyeti','asal maliyet','normal kapasite',
  'dikey yüzde analizi','trend analizi','cari oran','asit-test oranı'
)
$YZ = [regex]'(?i)(bu ba[ğg]lamda|[öo]nemli bir husus|unutulmamal[ıi]d[ıi]r|sonu[çc] olarak|[öo]zetle\s*,|dikkat edilmesi gereken)'

# NOT: kapi sinavi CAGRISI, DeterministikKapilar tanimindan SONRA yapilir
#      (S5 sinavi o fonksiyonu cagiriyor). Asagida.

function DeterministikKapilar($s, [string]$maddeMetni){
  $bulgu = @()
  $sik = @{}; $acik = @{}
  foreach($hf in $HARFLER){ $sik[$hf] = "$($s.siklar.$hf)"; $acik[$hf] = "$($s.aciklama.$hf)" }
  $dogru = "$($s.dogru)"
  $kokMetin = "$($s.soru)"

  # D3 sik butunlugu
  foreach($hf in $HARFLER){ if(-not $sik[$hf].Trim()){ $bulgu += "D3 sik-bos:$hf" } }
  foreach($hf in $HARFLER){ if(-not $acik[$hf].Trim()){ $bulgu += "D3 aciklama-bos:$hf" } }

  # D1 Turkce bozulmasi (Yabanci Dil dersi haric - Ingilizce metin dogal ASCII)
  if("$($s.ders)" -ne 'Yabanci Dil'){
    $izler = @()
    foreach($p in (@($kokMetin) + @($HARFLER | ForEach-Object { $sik[$_] }) + @($HARFLER | ForEach-Object { $acik[$_] }))){
      foreach($m in $D1.Matches("$p")){ if($izler -notcontains $m.Value){ $izler += $m.Value } }
    }
    if($izler.Count){ $bulgu += "D1 turkce-bozuk: " + (($izler | Select-Object -First 6) -join ', ') }
  }

  # D2 sik-aciklama uyumu (yalniz bes sikki da tek sayi olan sorularda olculebilir)
  $deg = @{}; $hepsiSayi = $true
  foreach($hf in $HARFLER){
    $t = ($sik[$hf] -replace '(?i)\s*(TL|adet|lira|birim)\s*$','').Trim()
    if($t -notmatch '^\d[\d\.]*(,\d+)?$'){ $hepsiSayi = $false; break }
    $deg[$hf] = ToNum $t
  }
  if($hepsiSayi){
    foreach($hf in $HARFLER){
      if($hf -eq $dogru){ continue }
      $nums = Sayilar $acik[$hf]
      if(-not $nums.Count){ continue }
      $kendi = $false; foreach($n in $nums){ if([math]::Abs($n - $deg[$hf]) -le 1){ $kendi = $true } }
      if($kendi){ continue }
      $baska = @()
      foreach($hf2 in $HARFLER){ if($hf2 -eq $hf){continue}
        foreach($n in $nums){ if([math]::Abs($n - $deg[$hf2]) -le 1 -and $baska -notcontains $hf2){ $baska += $hf2 } } }
      if($baska.Count){ $bulgu += "D2 sik-aciklama-karisik: $hf($($deg[$hf])) aciklamasi $($baska -join '/') sikkini anlatiyor" }
    }
  }

  # D4 dogru sik en uzun mu
  $uz = @{}; foreach($hf in $HARFLER){ $uz[$hf] = $sik[$hf].Length }
  $enUzun = ($HARFLER | Sort-Object { $uz[$_] } -Descending | Select-Object -First 1)
  $ortDiger = 0; $say = 0
  foreach($hf in $HARFLER){ if($hf -ne $dogru){ $ortDiger += $uz[$hf]; $say++ } }
  if($say){ $ortDiger = $ortDiger / $say }
  if($enUzun -eq $dogru -and $ortDiger -gt 0 -and $uz[$dogru] -ge $ortDiger*1.6){
    $bulgu += "D4 dogru-sik-en-uzun: $($uz[$dogru]) vs ort $([math]::Round($ortDiger))"
  }

  # D5 mutlak terim
  foreach($hf in $HARFLER){ if($D5.IsMatch($sik[$hf])){ $bulgu += "D5 mutlak-terim:$hf" } }

  # D6 aciklama kopyasi (iki sikta ayni cumle)
  for($i=0; $i -lt $HARFLER.Count; $i++){
    for($j=$i+1; $j -lt $HARFLER.Count; $j++){
      $a1 = Duz $acik[$HARFLER[$i]]; $a2 = Duz $acik[$HARFLER[$j]]
      if($a1.Length -lt 40 -or $a2.Length -lt 40){ continue }
      $kisa = if($a1.Length -lt $a2.Length){ $a1 } else { $a2 }
      $uzun = if($a1.Length -lt $a2.Length){ $a2 } else { $a1 }
      # ilk 80 karakteri ayni ise kopya sayilir
      if($kisa.Length -ge 80 -and $uzun.Contains($kisa.Substring(0,80))){
        $bulgu += "D6 aciklama-kopyasi: $($HARFLER[$i]) ~ $($HARFLER[$j])"
      }
    }
  }

  # D7 hap kart
  $hap = "$($s.hap)"
  if(-not $hap.Trim()){ $bulgu += 'D7 hap-yok' }
  elseif($hap.Length -gt 200){ $bulgu += "D7 hap-uzun:$($hap.Length) (hap degil ozet)" }

  # D8 dort parca duzeni — DOGRU sikta
  $eksik = @()
  foreach($p in $D8_parca){ if($acik[$dogru] -notmatch [regex]::Escape($p)){ $eksik += $p } }
  if($eksik.Count){ $bulgu += "D8 dort-parca-eksik(dogru sik): $($eksik -join ', ')" }

  # D8-b DORT PARCA — YANLIS SIKLARDA DA  (25.08, Cem'in bulgusu)
  # Dogru sik dort parcaya zorlaniyordu, yanlis sik SERBEST birakilmisti. Oysa
  # aday zamaninin cogunu yanlis sikta gecirir. Okunan vaka (ALTIN-04): uc yanlis
  # sik da "X sikki ... iddia ediyor; oysa ... bu yuzden X yanlistir" diyordu -
  # yani kurali tekrar edip sikki reddediyordu, OGRETMIYORDU. Bkz SINAV-KURALLARI E3-b.
  foreach($hf in $HARFLER){
    if($hf -eq $dogru){ continue }
    if(-not $acik[$hf].Trim()){ continue }
    $ye = @()
    foreach($p in $D8Y_parca){ if($acik[$hf] -notmatch [regex]::Escape($p)){ $ye += $p } }
    if($ye.Count){ $bulgu += "D8b yanlis-sik-parca-eksik:$hf $($ye -join ' / ')" }
  }

  # D12 AYNI CUMLE ISKELETI  (25.08, Cem'in bulgusu)
  # D6 yalniz BIREBIR kopyayi ariyordu (80 karakter ayni mi). Asil kusur kopya
  # degil AYNI KALIP: dort aciklama da ayni iskeletle kuruluyor. Iki olcut:
  #   (a) ilk dort kelime imzasi ayni mi
  #   (b) govde kelime-uclusu ortusmesi yuksek mi
  $imzalar = @{}; $kapanislar = @{}; $govdeler = @{}
  foreach($hf in $HARFLER){
    if($hf -eq $dogru){ continue }
    $g = $acik[$hf]
    foreach($p in $D8Y_parca){ $g = $g -replace [regex]::Escape($p),' ' }
    $g = Duz $g
    $kelime = @($g -split ' ' | Where-Object { $_ })
    if($kelime.Count -lt 6){ continue }
    # 25.08: imza ONCE ilk DORT kelimeydi ve kapi kendi sinavindan dustu -
    # "X sikki isletmenin tamaminin" ile "X sikki ilan yoluyla" ucuncu kelimeden
    # itibaren ayriliyor. Oysa kalibi kuran sey ACILIS ("X sikki...") ve KAPANIS
    # ("bu yuzden X yanlistir"). Imza ikiye indirildi, ayrica kapanis da olculuyor.
    $imza = (@($kelime[0..1]) -join ' ') -replace '\b[abcde]\b','X'
    if($imzalar.ContainsKey($imza)){ $imzalar[$imza] += ",$hf" } else { $imzalar[$imza] = $hf }
    $kapanis = (@($kelime[([Math]::Max(0,$kelime.Count-3))..($kelime.Count-1)]) -join ' ') -replace '\b[abcde]\b','X'
    if($kapanislar.ContainsKey($kapanis)){ $kapanislar[$kapanis] += ",$hf" } else { $kapanislar[$kapanis] = $hf }
    $u = New-Object System.Collections.Generic.HashSet[string]
    for($i=0; $i -le $kelime.Count-3; $i++){ [void]$u.Add(($kelime[$i..($i+2)] -join ' ')) }
    $govdeler[$hf] = $u
  }
  foreach($im in $imzalar.GetEnumerator()){
    $kac = ($im.Value -split ',').Count
    if($kac -ge 3){ $bulgu += "D12 ayni-acilis: $kac yanlis sik ayni basliyor ($($im.Value)) -> `"$($im.Key)...`"" }
  }
  foreach($kp in $kapanislar.GetEnumerator()){
    $kac = ($kp.Value -split ',').Count
    if($kac -ge 3){ $bulgu += "D12 ayni-kapanis: $kac yanlis sik ayni bitiyor ($($kp.Value)) -> `"...$($kp.Key)`"" }
  }
  $cift = @($govdeler.Keys)
  for($i=0;$i -lt $cift.Count;$i++){
    for($j=$i+1;$j -lt $cift.Count;$j++){
      $a1=$govdeler[$cift[$i]]; $a2=$govdeler[$cift[$j]]
      if($a1.Count -lt 5 -or $a2.Count -lt 5){ continue }
      $ortak=0; foreach($x in $a1){ if($a2.Contains($x)){ $ortak++ } }
      $jac = $ortak / [double]($a1.Count + $a2.Count - $ortak)
      if($jac -ge 0.55){ $bulgu += ("D12 govde-benzer: {0} ~ {1} (%{2:N0} ortak)" -f $cift[$i],$cift[$j],(100*$jac)) }
    }
  }

  # D13 TANIMSIZ MESLEK TERIMI  (25.08, Cem'in bulgusu)
  # Urunun vaadi "konu okumadan ogrenmek". "Kural" bolumunde gecen meslek terimi
  # aday biliyor varsayilarak kullanilamaz. Okunan vaka (ALTIN-06): "genel imal
  # gideri" ve "genel idare gideri" hic aciklanmadan gecmis - ikisi birbirine
  # benziyor ve sinavin en sik tuzagi tam o benzerlik. Bkz SINAV-KURALLARI E3-d.
  $kuralBlok = ''
  $mk = [regex]::Match($acik[$dogru],'(?s)Kural\s*:\s*(.+?)(?=(Bu olayda\s*:)|$)')
  if($mk.Success){ $kuralBlok = $mk.Groups[1].Value }
  if($kuralBlok){
    $tanimsiz = @()
    foreach($tr in $TERIMLER){
      $mm = [regex]::Match($kuralBlok, '(?i)' + [regex]::Escape($tr))
      if(-not $mm.Success){ continue }
      # terimden sonraki 200 karakterde tanim isareti var mi?
      $son = $kuralBlok.Substring([Math]::Min($mm.Index+$mm.Length, $kuralBlok.Length))
      $pencere = $son.Substring(0, [Math]::Min(200, $son.Length))
      if($pencere -match '(?i)(\byani\b|—|–|\(|:\s|\bdemek\b|\bifade eder\b|\bgiderlerdir\b|\bgideridir\b)'){ continue }
      if($tanimsiz -notcontains $tr){ $tanimsiz += $tr }
    }
    if($tanimsiz.Count){ $bulgu += "D13 tanimsiz-terim: " + (($tanimsiz | Select-Object -First 4) -join ', ') }
  }

  # D9 FIKRA ATFI
  # 25.08 KENDI KUSURUM: ilk surum fikra numarasini SATIR BASINDA ariyordu
  # ('(?m)^\s*\(\d\)'). Oysa ambar metni tek paragraf: "MADDE 55- (1) Asagida
  # sayilan haller..." - numara SATIR ICINDE. 20 soruluk kosuda 5 YALANCI
  # bayrak verdi. Duzeltme: numarayi metnin HERHANGI BIR YERINDE ara.
  # Iki ayri hukum verilir:
  #   (a) metin fikrasiz  -> her "m.X/Y" atfi UYDURMADIR (Is K. m.11 vakasi)
  #   (b) metin fikrali   -> atfedilen fikra metinde GERCEKTEN var mi?
  $fikraNolar = @()
  if($maddeMetni){
    foreach($m in [regex]::Matches($maddeMetni,'\(\s*([1-9]\d?)\s*\)')){
      $nn = $m.Groups[1].Value; if($fikraNolar -notcontains $nn){ $fikraNolar += $nn }
    }
  }
  $fikraliMi = ($maddeMetni -match '(?i)MADDE\s*\d+\s*[-–]\s*\(\s*1\s*\)') -or ($fikraNolar.Count -ge 2)
  if($maddeMetni){
    foreach($hf in $HARFLER){
      foreach($m in [regex]::Matches($acik[$hf],'(?i)\bm(?:adde)?\.?\s*(\d{1,4})\s*/\s*(\d{1,2})')){
        $atifFikra = $m.Groups[2].Value
        if(-not $fikraliMi){
          $bulgu += "D9 fikra-atfi-uydurma:$hf $($m.Value) (kaynak metni fikra numarasi TASIMIYOR)"
        } elseif($fikraNolar -notcontains $atifFikra){
          $bulgu += "D9 fikra-yok:$hf $($m.Value) (metindeki fikralar: $($fikraNolar -join ','))"
        }
      }
    }
  }

  # D10 uydurma rakam ADAYI: aciklamadaki rakam ne soruda/siklarda var ne de
  # ordaki rakamlardan basit islemle turetilebiliyor. ADAY'dir - karari model verir.
  $kaynakSayi = @(Sayilar $kokMetin)
  foreach($hf in $HARFLER){ $kaynakSayi += Sayilar $sik[$hf] }
  # TABLO DA KAYNAKTIR. 25.08: bu satir eksikti ve tablolu sorularda tablodaki
  # gercek kalemler "uydurma rakam adayi" diye bayraklandi (ALTIN-01/05/06/10).
  # Kapi, sorunun verisinin YARISINI gormeden hukum veriyordu.
  if($s.tablo -and $s.tablo.satirlar){
    foreach($sat in @($s.tablo.satirlar)){ foreach($hu in @($sat)){ $kaynakSayi += Sayilar "$hu" } }
  }
  $kaynakSayi = @($kaynakSayi | Select-Object -Unique)
  $turemis = New-Object System.Collections.Generic.List[double]
  foreach($n in $kaynakSayi){ $turemis.Add($n) }
  for($i=0;$i -lt $kaynakSayi.Count;$i++){
    for($j=0;$j -lt $kaynakSayi.Count;$j++){
      if($i -eq $j){ continue }
      $turemis.Add($kaynakSayi[$i]+$kaynakSayi[$j]); $turemis.Add($kaynakSayi[$i]-$kaynakSayi[$j])
      $turemis.Add($kaynakSayi[$i]*$kaynakSayi[$j])
      if($kaynakSayi[$j] -ne 0){ $turemis.Add($kaynakSayi[$i]/$kaynakSayi[$j]) }
    }
  }
  # ucler ve dortluler icin yalniz TOPLAM (maliyet sorularinin ana kalibi)
  if($kaynakSayi.Count -ge 3 -and $kaynakSayi.Count -le 9){
    for($i=0;$i -lt $kaynakSayi.Count;$i++){ for($j=$i+1;$j -lt $kaynakSayi.Count;$j++){ for($k=$j+1;$k -lt $kaynakSayi.Count;$k++){
      $t3 = $kaynakSayi[$i]+$kaynakSayi[$j]+$kaynakSayi[$k]; $turemis.Add($t3)
      for($l=$k+1;$l -lt $kaynakSayi.Count;$l++){ $turemis.Add($t3+$kaynakSayi[$l]) }
    }}}
  }
  $adaylar = @()
  foreach($hf in $HARFLER){
    foreach($n in (Sayilar $acik[$hf])){
      if($n -lt 1000){ continue }              # kucuk sayilar (yil, yuzde, madde no) elenir
      $var = $false
      foreach($t in $turemis){ if([math]::Abs($t - $n) -le [math]::Max(1, [math]::Abs($n)*0.005)){ $var = $true; break } }
      if(-not $var -and $adaylar -notcontains "$hf`:$n"){ $adaylar += "$hf`:$n" }
    }
  }
  if($adaylar.Count){ $bulgu += "D10 uydurma-rakam-ADAYI: " + (($adaylar | Select-Object -First 5) -join ', ') }

  # D11 ARITMETIK SONUC KAPISI — 25.08, olcumle dogdu.
  # 20 soruluk kosuda 6 OLDURUCU kusurun 5'i aritmetikti ve MEVCUT aritmetik
  # kapisi (K13) bunlari gormedi: K13 aciklamanin KENDI ICINDE tutarli olup
  # olmadigina bakiyor, ISARETLI CEVABIN DOGRU OLUP OLMADIGINA BAKMIYOR.
  # Elle dogrulanan vaka (28453f9c): 87.450+41.280+18.670+12.900 = 160.300;
  # 160.300/180 = 890,56. Isaretli sik D = 888,50. Hicbir sik dogru degil.
  # Bu kapi PARA HARCAMADAN o sinifi yakalar.
  # DURUST SINIR: yalniz "kalemleri topla (ve adete bol)" kalibini dener.
  # Kalip tutmuyorsa SUSAR - hukum vermez. Olculemeyene kusur denmez.
  # 25.08 KENDI KUSURUM (kapi sinavi yakaladi): ilk surum $kaynakSayi kullaniyordu
  # ve o dizi SIK DEGERLERINI de iceriyor. 5 kalem + 5 sik = 10 oge, "en fazla 8"
  # sinirina takilip kapi SESSIZCE sustu. D11 yalniz SORU KOKUNDEKI verilerle
  # calisir - siklar zaten sinanan seydir, girdiye karistirilmaz.
  # 25.08 IKINCI KUSUR (10 altin soru okunurken cikti): kalemler TABLODA ise
  # D11 onlari gormuyordu ve soru kokunde kalan sayilardan (gun, yil, madde no)
  # anlamsiz bir sonuc uretip YALANCI BAYRAK veriyordu (ALTIN-05: gercek cevap
  # 971.000 iken kapi "118.801,81 olmali" dedi). Tablolu soruda kalem kaynagi
  # TABLODUR. Ayrica 1900-2100 arasi tam sayilar YIL'dir, kalem degildir.
  $kokSayi = @(Sayilar $kokMetin)
  if($s.tablo -and $s.tablo.satirlar){
    foreach($sat in @($s.tablo.satirlar)){ foreach($hu in @($sat)){ $kokSayi += Sayilar "$hu" } }
  }
  $kokSayi = @($kokSayi | Where-Object { -not ($_ -ge 1900 -and $_ -le 2100 -and [math]::Floor($_) -eq $_) })
  if($hepsiSayi -and $kokSayi.Count -ge 3){
    # Para tutari ile ADET'i ayir: tutarlar bin ve uzeri, adet kucuk tam sayi.
    $adet2 = @(); foreach($n in $kokSayi){ if($n -ge 2 -and $n -lt 1000 -and [math]::Floor($n) -eq $n){ $adet2 += $n } }
    $kalem = @($kokSayi | Where-Object { $_ -ge 1000 } | Select-Object -Unique)
    # 25.08 UCUNCU KUSUR (ALTIN-10 elle cozulerek bulundu): kapi yalniz "hepsini
    # topla" ve "birini cikar" kaliplarini deniyordu. O soruda IKI kalem birden
    # dislaniyordu (indirilebilir KDV + ilgisiz reklam gideri) ve kapi DOGRU
    # cevaba "yanlis" dedi.
    # DOGRU ANLAM: "isaretli cevap, kalemlerin HERHANGI BIR birlesimiyle
    # ulasilabiliyor mu?" Ulasilamiyorsa kesin kusurdur. Ulasilabiliyorsa kapi
    # SUSAR - hangi birlesimin hukuken dogru oldugu MODELIN isidir, makinenin degil.
    $sonuclar = @()
    if($kalem.Count -ge 2 -and $kalem.Count -le 12){
      $n2 = $kalem.Count
      $altKume = New-Object System.Collections.Generic.List[double]
      for($m=1; $m -lt [math]::Pow(2,$n2); $m++){
        $t = 0.0
        for($b=0; $b -lt $n2; $b++){ if($m -band [math]::Pow(2,$b)){ $t += $kalem[$b] } }
        $altKume.Add($t)
      }
      foreach($t in $altKume){
        $sonuclar += $t
        foreach($a in ($adet2 | Select-Object -Unique)){ if($a -gt 1){ $sonuclar += ($t / $a) } }
      }
    }
    if($sonuclar.Count){
      $dogruDeger = $deg[$dogru]
      $isaretliTutuyor = $false
      foreach($sn in $sonuclar){ if([math]::Abs($sn - $dogruDeger) -le [math]::Max(0.5, [math]::Abs($dogruDeger)*0.002)){ $isaretliTutuyor = $true; break } }
      if(-not $isaretliTutuyor){
        # Baska bir sik tutuyor mu? Tutuyorsa CEVAP ANAHTARI YANLIS demektir.
        $tutanSik = ''
        foreach($hf2 in $HARFLER){
          if($hf2 -eq $dogru){ continue }
          foreach($sn in $sonuclar){ if([math]::Abs($sn - $deg[$hf2]) -le [math]::Max(0.5,[math]::Abs($deg[$hf2])*0.002)){ $tutanSik = $hf2; break } }
          if($tutanSik){ break }
        }
        if($tutanSik){
          # ($hf2 dongu disinda son degerini tasiyordu - mesaj "D degil D" diyordu)
          $bulgu += ("D11 CEVAP-ANAHTARI-YANLIS: hesap {0} degil {1}={2:N2} sikkini veriyor (isaretli {0}={3:N2})" -f $dogru,$tutanSik,$deg[$tutanSik],$dogruDeger)
        } else {
          $enYakin = ($sonuclar | Sort-Object { [math]::Abs($_ - $dogruDeger) } | Select-Object -First 1)
          $bulgu += ("D11 HICBIR-SIK-DOGRU-DEGIL: kalem toplami/bolumu {0:N2} veriyor, isaretli {1}={2:N2}" -f $enYakin,$dogru,$dogruDeger)
        }
      }
    }
  }

  # ---------------------------------------------------------------- KATMAN 4
  # Y1 YETKI DEVRI — en tehlikeli sinif, cunku diger butun kapilardan SAG CIKAR.
  # Madde "Cumhurbaskani belirler / tebligle belirlenir" diyorsa ve soru SABIT
  # RAKAM ezberletiyorsa, kanun metnine bakan hakem "dogru" der; oysa gercek
  # oran ikincil duzenlemededir. Yasandi: 5746 (kanun 50, gercek esik 15) ·
  # 7566 ("5 puan" -> 2 puan). Burada KUSUR demiyoruz, "IKINCIL DUZENLEME
  # KONTROL EDILMELI" diyoruz - karar okumaya kalir.
  if($maddeMetni -and $YETKI.IsMatch($maddeMetni)){
    $sabitRakam = $false
    foreach($hf in $HARFLER){
      if($sik[$hf] -match '(?i)(%\s*\d|\d+\s*(TL|g[üu]n|ay|y[ıi]l|puan|kat)\b)'){ $sabitRakam = $true }
    }
    if($sabitRakam){
      $ib = $YETKI.Match($maddeMetni).Value
      $bulgu += "Y1 yetki-devri: madde ikincil duzenlemeye atif yapiyor ('$($ib.Substring(0,[Math]::Min(50,$ib.Length)))') ve siklar SABIT RAKAM tasiyor - ikincil duzenleme teyit edilmeli"
    }
  }

  # Y2 TABLO <-> METIN TUTARLILIGI. #58 vakasi: tabloda 60.000/35.000/25.000,
  # metinde 68.000/41.500. Hicbir kapi gormuyordu.
  if($s.tablo -and $s.tablo.satirlar){
    $tabloSayi = @()
    foreach($sat in @($s.tablo.satirlar)){ foreach($hu in @($sat)){ $tabloSayi += Sayilar "$hu" } }
    $metinSayi = @(Sayilar $kokMetin)
    foreach($hf in $HARFLER){ $metinSayi += Sayilar $acik[$hf] }
    $bulunmayan = @()
    foreach($t in ($tabloSayi | Select-Object -Unique)){
      if($t -lt 100){ continue }
      $var = $false
      foreach($m in $metinSayi){ if([math]::Abs($m-$t) -le [math]::Max(1,[math]::Abs($t)*0.005)){ $var=$true; break } }
      if(-not $var -and $bulunmayan -notcontains $t){ $bulunmayan += $t }
    }
    # Tablodaki her sayinin metinde gecmesi sart degil (ara toplamlar); ama
    # YARIDAN COGU gecmiyorsa tablo baska bir sorunun tablosudur.
    if($tabloSayi.Count -ge 4 -and $bulunmayan.Count -gt ($tabloSayi.Count/2)){
      $bulgu += "Y2 tablo-metin-uyumsuz: tablodaki {0} sayidan {1}'i soru/aciklama metninde YOK" -f $tabloSayi.Count,$bulunmayan.Count
    }
  }

  # Y3 THP HESAP KODU <-> RESMI AD, SIKLARIN ICINDE.
  # Mevcut kapi yalniz soru+aciklamayi tariyordu; 13.08'de okunan sorudaki
  # uydurma eslesme ("500 - ODENECEK VERGI VE FONLAR") tam da SIKTAYDI.
  if($THP.Count -gt 0){
    foreach($hf in $HARFLER){
      foreach($m in [regex]::Matches($sik[$hf], '(?<![\d.])([1-7]\d{2})\s*[-–:]\s*([A-ZÇĞİÖŞÜa-zçğıöşü][^,;()\r\n]{3,60})')){
        $kod = $m.Groups[1].Value; $ad = $m.Groups[2].Value.Trim()
        if(-not $THP.ContainsKey($kod)){ continue }
        $resmi = Duz $THP[$kod]; $yazan = Duz $ad
        if(-not $resmi){ continue }
        if($resmi.Contains($yazan) -or $yazan.Contains($resmi)){ continue }
        $bulgu += "Y3 hesap-kodu-yanlis:$hf `"$kod - $ad`" (THP: $($THP[$kod]))"
      }
    }
  }

  # Y4 CIKMIS SORU ORTUSMESI. SINAV-KURALLARI B2 "cikmis sinav sorusu
  # kopyalanmaz" diyordu ama olcen kapi YOKTU. 8 kelimelik birebir tekrar
  # tesaduf degildir.
  if($CIKMIS.Count -gt 0){
    $pk = Parmak $kokMetin
    $o = Ortusme $pk $CIKMIS
    if($o -ge 0.25){ $bulgu += "Y4 cikmis-soru-ortusmesi: %$([math]::Round($o*100)) (8-kelimelik birebir tekrar)" }
  }

  # Y5 MUKERRER (kasa ici). benzer_grup %23,8'de takili oldugu icin tekrar
  # freni fiilen calismiyor; bu kapi kokten olcer.
  if($KASA_INDEKS.Count -gt 0){
    $pk2 = Parmak $kokMetin
    $eslesen = @{}
    foreach($d in $pk2){
      if($KASA_INDEKS.ContainsKey($d)){
        $oid = $KASA_INDEKS[$d]
        if($oid -ne "$($s.id)"){ if($eslesen.ContainsKey($oid)){ $eslesen[$oid]++ } else { $eslesen[$oid]=1 } }
      }
    }
    if($pk2.Count -gt 0){
      $enCok = $eslesen.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1
      if($enCok -and ($enCok.Value / $pk2.Count) -ge 0.5){
        $bulgu += "Y5 mukerrer: $([math]::Round(100*$enCok.Value/$pk2.Count))% ortak -> $($enCok.Key.Substring(0,8))"
      }
    }
  }

  return ,$bulgu
}

# --- KAPI SINAVI: butun kapilar tanimlandi, simdi kendi sinavlarini versinler.
#     Gecemezse betik DURUR - yanlis rakam uretmektense hic uretmemek yegdir.
$sinavHata = KapiSinavi
if($sinavHata.Count){
  Write-Host ''
  Write-Host 'KAPI SINAVI DUSTU - olcum GECERSIZ, betik durduruldu:'
  foreach($e in $sinavHata){ Write-Host ("  - {0}" -f $e) }
  RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='KAPI-SINAVI-DUSTU'; hatalar=$sinavHata })
  exit 1
}
Write-Host 'Kapi sinavi: GECTI (9 sinav — D11/D12/D13 dahil)'

# ============================================================ ICERIK SOZLESMESI
function Nesne($gerekli,$ozellik){ @{ type='object'; additionalProperties=$false; required=$gerekli; properties=$ozellik } }
$Str = @{ type='string' }; $Bool = @{ type='boolean' }
$icerikSema = Nesne @('cevap_dogru','alinti','tek_dogru_sik','ikinci_dogru_siklar','aciklama_celiskili','celiskili_siklar',
                      'her_sik_kendini_anlatiyor','yanlis_anlatan_siklar','kaynak_konuyu_kapsiyor','ogretiyor',
                      'yapayzeka_kokusu','mevzuat_guncel','uydurma_rakamlar','hukum','gerekce') ([ordered]@{
  cevap_dogru               = $Bool
  alinti                    = $Str      # maddeden BIREBIR alinti - makine dogrular
  tek_dogru_sik             = $Bool
  ikinci_dogru_siklar       = $Str
  aciklama_celiskili        = $Bool
  celiskili_siklar          = $Str
  her_sik_kendini_anlatiyor = $Bool
  yanlis_anlatan_siklar     = $Str
  kaynak_konuyu_kapsiyor    = $Bool
  ogretiyor                 = $Bool
  yapayzeka_kokusu          = $Str
  mevzuat_guncel            = $Bool
  uydurma_rakamlar          = $Str
  hukum                     = @{ type='string'; enum=@('uygun','kusurlu','olculemedi') }
  gerekce                   = $Str
})

# ⚠ 25.08: burada kurulan istemin adi $istem idi. PowerShell HARF AYIRMAZ ->
# sablon $ISTEM ile ayni degisken. Ilk sorudan sonra sablon KIRLENDI ve her
# soru bir oncekinin istemini de gordu. Bu yuzden 20 soruluk olcumun sonuclari
# (%30 oldurucu vb.) GECERSIZDI. Kurulan istemin adi artik $soruIstemi.
# Nobetci: motor\degisken-cakisma-nobeti.ps1  ·  [[ps-degiskeni-cakismasi]]
$ISTEM = @'
Bir muhasebe meslek sınavı soru bankasının HAKEMİSİN. Tek bir soruyu yargılayacaksın.

PAZARLIKSIZ KURALLAR
1. YALNIZ sana verilen MADDE METNİNE dayan. Hafızandan kural tamamlama.
2. "alinti" alanına, hükmünü dayandırdığın cümleyi MADDE METNİNDEN BİREBİR kopyala.
   Bu alıntı makineyle denetlenir; metinde geçmiyorsa hükmün çöpe atılır.
   Madde metni hükmü vermeye yetmiyorsa hukum = "olculemedi" ve alinti = "".
3. Emin olmadığına KUSUR DEME. Ölçülemeyen şey üçüncü sonuçtur: "olculemedi".

NEYE BAKACAKSIN
- cevap_dogru: işaretli doğru şık, madde metnine göre gerçekten doğru mu?
- tek_dogru_sik: şıklardan TAM OLARAK BİRİ mi doğru? Başka savunulabilir doğru varsa yaz.
- aciklama_celiskili: açıklamalardan biri madde metniyle ya da başka bir açıklamayla çelişiyor mu?
- her_sik_kendini_anlatiyor: HER YANLIŞ ŞIKKIN açıklaması O ŞIKKI mı anlatıyor?
  (Ölçüldü: kasada 1.302 soruda B şıkkının açıklaması A şıkkını anlatıyor.)
- kaynak_konuyu_kapsiyor: madde, sorunun ölçtüğü konuyu gerçekten düzenliyor mu?
  Kavramdan söz etmesi YETMEZ; yöntemi/tekniği düzenlemeli.
- ogretiyor: açıklamalar öğrenciye BİR BENZERİNİ çözdürür mü, yoksa cevabı mı tekrarlıyor?
- yapayzeka_kokusu: iz DİLDEDİR, İSKELETTE DEĞİL.
  ⚠ "Ne soruluyor / Kural / Bu olayda / Akılda kalsın" düzeni BİZİM ZORUNLU
  STANDARDIMIZDIR (kapı D8 onu ŞART KOŞAR). Bunu ASLA yapay zekâ kokusu sayma.
  Yanlış şık açıklamalarının "TUZAK:" ile başlaması da standarttır, kusur değildir.
  Gerçekten bakacakların: klişe bağlaçlar ("bu bağlamda", "önemli bir husus",
  "unutulmamalıdır ki", "sonuç olarak"), gereksiz "oldukça/son derece",
  İngilizceden çeviri kokan cümle yapısı, senaryo adlarının/rakamlarının suni
  simetrisi (hep yuvarlak tutar, hep aynı şehir-şirket kalıbı, hep "Mehmet Bey").
  Bunlardan biri yoksa "" yaz — şablonu gerekçe gösterme.
  (25.08 ölçümü: bu kapı 9 sorunun 9'unda bayrak kaldırdı ve dokuzu da bizim
   kendi standardımızı kusur sanıyordu. Yalancı bayrak, kusuru gizler.)
- mevzuat_guncel: madde metninde "...ibaresi ...şeklinde değiştirilmiştir" gibi değişiklik
  izi varsa, sorudaki rakam/oran DEĞİŞİKLİK SONRASI hâlle uyumlu mu?
- uydurma_rakamlar: açıklamada geçen ama soruda olmayan ve hesaptan türemeyen rakamlar.
  Sana ADAY listesi verilebilir; adayı doğrulamak ya da elemek senin işin.

HÜKÜM
Yukarıdakilerden biri bile bozuksa hukum = "kusurlu".
Madde metni yargılamaya yetmiyorsa "olculemedi".
Hepsi temizse "uygun". gerekce: tek cümle, somut.
'@

# ============================================================ KOSU
$sonuc = New-Object System.Collections.Generic.List[object]
$topGiris = 0; $topCikis = 0
$AY = 'https://api.anthropic.com/v1/messages'
$i = 0
foreach($s in $sorular){
  $i++
  Write-Host ("[{0,3}/{1}] {2} {3}/{4}" -f $i,$sorular.Count,"$($s.id)".Substring(0,8),$s.ders,$s.konu)

  # kaynak metni
  $coz = KaynakCoz "$($s.kaynak)" "$($s.konu)"
  $maddeMetni = if($coz.durum -like 'cozuldu*'){ "$($coz.metin)" } else { '' }

  $dBulgu = DeterministikKapilar $s $maddeMetni
  if($dBulgu.Count){ Write-Host ("      D: {0}" -f (($dBulgu | Select-Object -First 3) -join ' | ')) }

  if($olcum -or -not $env:ANTHROPIC_API_KEY -or -not $maddeMetni){
    $hukum = if(-not $maddeMetni){ 'olculemedi' } elseif($dBulgu.Count){ 'kusurlu' } else { 'olculemedi' }
    $sonuc.Add([ordered]@{ id="$($s.id)"; ders=$s.ders; konu=$s.konu; kaynak=$s.kaynak
      kaynak_durum=$coz.durum; deterministik=$dBulgu; icerik=$null; hukum=$hukum
      not=$(if(-not $maddeMetni){'madde metni cozulemedi - yargilanmadi'}else{'olcum modu'}) })
    continue
  }

  # --- icerik cagrisi (tek cagri, tum icerik kapilari)
  $sikMetin = ''; $acikMetin = ''
  foreach($hf in $HARFLER){
    $sikMetin  += "  $hf) $($s.siklar.$hf)`n"
    $acikMetin += "[$hf] $($s.aciklama.$hf)`n`n"
  }
  $adaySatir = ($dBulgu | Where-Object { $_ -like 'D10*' }) -join '; '
  $mtn = $maddeMetni
  if($mtn.Length -gt 20000){ $mtn = $mtn.Substring(0,13000) + "`n[...orta atlandi...]`n" + $mtn.Substring($mtn.Length-7000) }

  $soruIstemi = $ISTEM + "`n`n=== MADDE METNI (dayanak: $($s.kaynak)) ===`n$mtn" +
           "`n`n=== SORU ===`nDERS: $($s.ders)   KONU: $($s.konu)`n$($s.soru)`n$sikMetin`nISARETLI DOGRU: $($s.dogru)" +
           "`n`n=== SIK ACIKLAMALARI ===`n$acikMetin" +
           "`n=== HAP KARTI ===`n$($s.hap)`n" +
           $(if($adaySatir){ "`n=== MAKINENIN UYDURMA RAKAM ADAYLARI (dogrula ya da ele) ===`n$adaySatir`n" } else { '' })

  # 25.08 KUSUR: max_tokens=3000 idi ve ILK cagri tam 3.000 cikis jetonuyla
  # kesildi, metin blogu hic gelmedi. Sebep: Sonnet 5'te DUSUNME VARSAYILAN
  # ACIK (adaptive) ve butceyi dusunme yedi. Hakemlik isinde dusunme degerli -
  # kapatmiyoruz, TAVANI yukseltiyoruz ve derinligi 'medium'da tutuyoruz.
  $govde = @{ model=$model; max_tokens=8000; messages=@(@{ role='user'; content=$soruIstemi })
              output_config=@{ effort='medium'; format=@{ type='json_schema'; schema=$icerikSema } } } | ConvertTo-Json -Depth 14

  $j = $null
  try {
    # HttpClient + acik UTF-8: PS 5.1'in IRM'i Anthropic cevabini Latin-1 sanip
    # Turkce harfleri bozuyor (25.08 olcumu). Bkz [[turkce-harf-bozulmasi]]
    $ic = New-Object System.Net.Http.StringContent($govde,[Text.Encoding]::UTF8,'application/json')
    $ist = New-Object System.Net.Http.HttpRequestMessage('POST',$AY); $ist.Content = $ic
    $ist.Headers.Add('x-api-key',$env:ANTHROPIC_API_KEY); $ist.Headers.Add('anthropic-version','2023-06-01')
    $yn = $hc.SendAsync($ist).GetAwaiter().GetResult()
    $ham = [Text.Encoding]::UTF8.GetString($yn.Content.ReadAsByteArrayAsync().GetAwaiter().GetResult())
    if(-not $yn.IsSuccessStatusCode){ Write-Host ("      API {0}: {1}" -f [int]$yn.StatusCode, $ham.Substring(0,[Math]::Min(200,$ham.Length))) }
    else {
      $cv = $ham | ConvertFrom-Json
      $topGiris += [int]$cv.usage.input_tokens; $topCikis += [int]$cv.usage.output_tokens
      $metinBlok = ($cv.content | Where-Object { $_.type -eq 'text' } | Select-Object -First 1).text
      if(-not $metinBlok){
        # Metin blogu yoksa sebebi SOYLE - "null'a metot cagrilamaz" diye
        # anlamsiz hata verme. En sik sebep: max_tokens dusunmeye harcandi.
        Write-Host ("      METIN BLOGU YOK - stop_reason={0} cikis={1} token" -f $cv.stop_reason, $cv.usage.output_tokens)
      } else { $j = $metinBlok | ConvertFrom-Json }
    }
  } catch { Write-Host ("      HATA: {0}" -f $_.Exception.Message) }

  if($null -eq $j){
    $sonuc.Add([ordered]@{ id="$($s.id)"; ders=$s.ders; konu=$s.konu; kaynak=$s.kaynak; kaynak_durum=$coz.durum
      deterministik=$dBulgu; icerik=$null; hukum='olculemedi'; not='icerik cagrisi basarisiz' })
    continue
  }

  # --- HAKEMIN HAKEMI: alinti gercekten madde metninde geciyor mu?
  $alintiGecerli = $true; $alintiNot = ''
  $al = Duz "$($j.alinti)"
  if($al.Length -ge 20){
    if((Duz $maddeMetni).Contains($al)){ $alintiNot = 'alinti dogrulandi' }
    else { $alintiGecerli = $false; $alintiNot = 'ALINTI MADDEDE GECMIYOR - hukum cope atildi' }
  } elseif("$($j.hukum)" -ne 'olculemedi'){
    $alintiGecerli = $false; $alintiNot = 'alinti yok/kisa - hukum dayanaksiz'
  }

  $icerikKusur = @()
  if(-not $j.cevap_dogru){ $icerikKusur += 'M1 cevap-yanlis' }
  if(-not $j.tek_dogru_sik){ $icerikKusur += "M2 cift-dogru: $($j.ikinci_dogru_siklar)" }
  if($j.aciklama_celiskili){ $icerikKusur += "M3 aciklama-celiskili: $($j.celiskili_siklar)" }
  if(-not $j.her_sik_kendini_anlatiyor){ $icerikKusur += "M4 sik-aciklama-karisik: $($j.yanlis_anlatan_siklar)" }
  if(-not $j.kaynak_konuyu_kapsiyor){ $icerikKusur += 'M5 kaynak-konu-uyumsuz' }
  if(-not $j.ogretiyor){ $icerikKusur += 'M6 ogretmiyor' }
  if("$($j.yapayzeka_kokusu)".Trim()){ $icerikKusur += "M7 yz-kokusu: $($j.yapayzeka_kokusu)" }
  if(-not $j.mevzuat_guncel){ $icerikKusur += 'M8 mevzuat-eskimis' }
  if("$($j.uydurma_rakamlar)".Trim()){ $icerikKusur += "M9 uydurma-rakam: $($j.uydurma_rakamlar)" }

  # TEK HUKUM
  $hukum = if(-not $alintiGecerli){ 'olculemedi' }
           elseif($dBulgu.Count -or $icerikKusur.Count){ 'kusurlu' }
           else { 'uygun' }
  Write-Host ("      -> {0}{1}" -f $hukum.ToUpper(), $(if($icerikKusur.Count){ "  ($($icerikKusur.Count) icerik kusuru)" }else{''}))

  $sonuc.Add([ordered]@{ id="$($s.id)"; ders=$s.ders; konu=$s.konu; kaynak=$s.kaynak; kaynak_durum=$coz.durum
    deterministik=$dBulgu; icerik=$icerikKusur; alinti_denetimi=$alintiNot
    gerekce="$($j.gerekce)"; hukum=$hukum })
}

# ============================================================ RAPOR
$uygun = @($sonuc | Where-Object { $_.hukum -eq 'uygun' })
$kusur = @($sonuc | Where-Object { $_.hukum -eq 'kusurlu' })
$olcme = @($sonuc | Where-Object { $_.hukum -eq 'olculemedi' })

# kusur sinifi dagilimi
$sinif = @{}
foreach($x in $sonuc){
  foreach($b in (@($x.deterministik) + @($x.icerik))){
    if(-not $b){ continue }
    $k = ("$b" -split ' ')[0]
    if($sinif.ContainsKey($k)){ $sinif[$k]++ } else { $sinif[$k]=1 }
  }
}

$TANITIM_SON = [datetime]'2026-08-31'
if((Get-Date) -le $TANITIM_SON -and $model -like 'claude-sonnet-5*'){ $fg=2.0; $fc=10.0; $fnot='tanitim' } else { $fg=3.0; $fc=15.0; $fnot='liste' }
$usd = ($topGiris/1e6*$fg) + ($topCikis/1e6*$fc)

Write-Host ''
Write-Host '================ TEK HUKUM ================'
Write-Host ("  UYGUN        : {0,4}  (%{1:N1})" -f $uygun.Count,(100*$uygun.Count/[math]::Max($sonuc.Count,1)))
Write-Host ("  KUSURLU      : {0,4}  (%{1:N1})" -f $kusur.Count,(100*$kusur.Count/[math]::Max($sonuc.Count,1)))
Write-Host ("  OLCULEMEDI   : {0,4}  (%{1:N1})" -f $olcme.Count,(100*$olcme.Count/[math]::Max($sonuc.Count,1)))
Write-Host ''
Write-Host '---- KUSUR SINIFLARI (bir soruda birden fazla olabilir) ----'
foreach($k in ($sinif.GetEnumerator() | Sort-Object Value -Descending)){ Write-Host ("  {0,-5} {1}" -f $k.Key,$k.Value) }

# ============================================================ KATMAN 5: PARTI KAPILARI
# SORU duzeyi ile PARTI duzeyi AYRI seylerdir. Yuz sorunun her biri tek tek
# kusursuz olabilir ama parti hala sinava benzemez. Bu kapilar soruyu degil
# PARTIYI reddeder. Olculmus sinav degerleri: SINAV-KURALLARI + 09.08 olcumu.
$P_olumsuz = [regex]'(?i)(de[ğg]ildir|yanl[ıi][şs]t[ıi]r|s[öo]ylenemez|olamaz|yer almaz|bulunmaz|gerekmez|hangisi de[ğg]il)'
$P_sirali  = [regex]'(?i)(s[ıi]ras[ıi]yla|ayr[ıi] ayr[ıi]|hangileri)'
$pOlumsuz=0; $pSirali=0; $pVeriTop=0; $pHarf=@{}
foreach($hf in $HARFLER){ $pHarf[$hf]=0 }
foreach($s in $sorular){
  $kk = "$($s.soru)"
  if($P_olumsuz.IsMatch($kk)){ $pOlumsuz++ }
  if($P_sirali.IsMatch($kk)){ $pSirali++ }
  $pVeriTop += @(Sayilar $kk).Count
  $d = "$($s.dogru)"; if($pHarf.ContainsKey($d)){ $pHarf[$d]++ }
}
$n = [math]::Max($sorular.Count,1)
$pOlumsuzYuzde = [math]::Round(100*$pOlumsuz/$n,1)
$pSiraliYuzde  = [math]::Round(100*$pSirali/$n,1)
$pVeriOrt      = [math]::Round($pVeriTop/$n,2)
$harfSapma     = 0
foreach($hf in $HARFLER){ $sp = [math]::Abs(100*$pHarf[$hf]/$n - 20); if($sp -gt $harfSapma){ $harfSapma = $sp } }

$partiKusur = @()
if($pOlumsuzYuzde -lt 12){ $partiKusur += "P1 olumsuz-kok az: %$pOlumsuzYuzde (sinavda %17-30)" }
if($pSiraliYuzde  -lt 4){  $partiKusur += "P2 cok-ciktili az: %$pSiraliYuzde (sinavda %6,7)" }
if($pVeriOrt      -lt 4.5){ $partiKusur += "P3 veri noktasi az: $pVeriOrt (sinavda 5,63)" }
if($harfSapma     -gt 10){ $partiKusur += "P4 cevap anahtari dengesiz: azami sapma $([math]::Round($harfSapma,1)) puan" }

Write-Host ''
Write-Host '================ KATMAN 5: PARTI KAPISI ================'
Write-Host ("  olumsuz kok      : %{0,-5}  (sinav %17-30)" -f $pOlumsuzYuzde)
Write-Host ("  cok ciktili      : %{0,-5}  (sinav %6,7)" -f $pSiraliYuzde)
Write-Host ("  veri noktasi/soru: {0,-6}  (sinav 5,63)" -f $pVeriOrt)
Write-Host ("  cevap anahtari   : " + (($HARFLER | ForEach-Object { "$_=$([math]::Round(100*$pHarf[$_]/$n))%" }) -join ' '))
if($partiKusur.Count){
  Write-Host '  PARTI HUKMU: RET' -ForegroundColor Yellow
  foreach($p in $partiKusur){ Write-Host ("    - {0}" -f $p) }
  Write-Host '  (sorular tek tek temiz olsa bile bu parti SINAVA BENZEMIYOR)'
} else { Write-Host '  PARTI HUKMU: GECER' }
Write-Host ''
Write-Host ("FATURA: giris {0:N0} + cikis {1:N0} token = {2:N4} USD  ({3}/{4} {5})" -f $topGiris,$topCikis,$usd,$fg,$fc,$fnot)
if($sonuc.Count){ Write-Host ("  soru basina {0:N4} USD  ->  1.000 soru icin ~{1:N2} USD" -f ($usd/$sonuc.Count), ($usd/$sonuc.Count*1000)) }

$damga = Get-Date -Format 'yyyyMMdd-HHmm'
$dosya = Join-Path $kok ("veri/fabrika/tam-kontrol-$damga.json")
$null = New-Item -ItemType Directory -Force (Split-Path $dosya)
[IO.File]::WriteAllText($dosya, (ConvertTo-Json -InputObject $sonuc -Depth 8), (New-Object Text.UTF8Encoding($false)))
Write-Host ''
Write-Host ("-> {0}" -f $dosya)

# ============================================================ KATMAN 6: INSAN OKUMASI
# Makine ADAY gosterir, KARARI OKUMA verir. Bu dosya okunmak icin yazilir:
# her sorunun kendisi, siklari, aciklamasi ve makinenin hukmu YAN YANA.
# Rapor okunmaz - SORU okunur (13.08 dersi: raporu degil soruyu oku).
$okuYol = Join-Path $kok ("veri/fabrika/tam-kontrol-OKUMA-$damga.md")
$md = New-Object System.Text.StringBuilder
[void]$md.AppendLine("# TAM KONTROL — İNSAN OKUMASI  ($damga)")
[void]$md.AppendLine()
[void]$md.AppendLine("> Makinenin hükmü **aday**dır. Karar okuyanındır. Katılmadığın hükmü işaretle;")
[void]$md.AppendLine("> kapı yanlış ölçüyorsa kapı düzeltilir — soru değil.")
[void]$md.AppendLine()
[void]$md.AppendLine("**Özet:** $($uygun.Count) uygun · $($kusur.Count) kusurlu · $($olcme.Count) ölçülemedi")
if($partiKusur.Count){ [void]$md.AppendLine(); [void]$md.AppendLine("**PARTİ HÜKMÜ: RET** — " + ($partiKusur -join ' · ')) }
[void]$md.AppendLine()
$sira = 0
# Once KUSURLU olanlar - okuma zamani en degerli orada
foreach($grup in @('kusurlu','olculemedi','uygun')){
  $liste = @($sonuc | Where-Object { $_.hukum -eq $grup })
  if(-not $liste.Count){ continue }
  [void]$md.AppendLine("---"); [void]$md.AppendLine(); [void]$md.AppendLine("# $($grup.ToUpper()) ($($liste.Count))"); [void]$md.AppendLine()
  foreach($x in $liste){
    $sira++
    $s = $sorular | Where-Object { "$($_.id)" -eq $x.id } | Select-Object -First 1
    [void]$md.AppendLine("## $sira · ``$($x.id)``  —  $($x.ders) / $($x.konu)")
    [void]$md.AppendLine("**Kaynak:** $($x.kaynak)  ·  *$($x.kaynak_durum)*")
    if($x.gerekce){ [void]$md.AppendLine(); [void]$md.AppendLine("**Makinenin gerekçesi:** $($x.gerekce)") }
    if(@($x.deterministik).Count){ [void]$md.AppendLine(); [void]$md.AppendLine('**Deterministik kapılar:**'); foreach($b in $x.deterministik){ [void]$md.AppendLine("- $b") } }
    if(@($x.icerik).Count){ [void]$md.AppendLine(); [void]$md.AppendLine('**İçerik kapıları:**'); foreach($b in $x.icerik){ [void]$md.AppendLine("- $b") } }
    if($x.alinti_denetimi){ [void]$md.AppendLine(); [void]$md.AppendLine("**Alıntı denetimi:** $($x.alinti_denetimi)") }
    if($s){
      [void]$md.AppendLine(); [void]$md.AppendLine('### Soru'); [void]$md.AppendLine("$($s.soru)"); [void]$md.AppendLine()
      foreach($hf in $HARFLER){
        $im = if($hf -eq "$($s.dogru)"){ '**✓**' } else { '  ' }
        [void]$md.AppendLine("$im **$hf)** $($s.siklar.$hf)")
      }
      [void]$md.AppendLine(); [void]$md.AppendLine('### Şık açıklamaları')
      foreach($hf in $HARFLER){ [void]$md.AppendLine(); [void]$md.AppendLine("**[$hf]** $($s.aciklama.$hf)") }
      [void]$md.AppendLine(); [void]$md.AppendLine("### Hap kartı"); [void]$md.AppendLine("$($s.hap)")
    }
    [void]$md.AppendLine(); [void]$md.AppendLine("**Okuyucu hükmü:** ☐ katılıyorum ☐ katılmıyorum — not: ______"); [void]$md.AppendLine()
  }
}
[IO.File]::WriteAllText($okuYol, $md.ToString(), (New-Object Text.UTF8Encoding($false)))
Write-Host ("-> {0}   <- KATMAN 6: bu dosya OKUNACAK" -f $okuYol)

RaporYaz ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); durum='TAMAM'; model=$model; havuz=$havuz; tohum=$tohum
  toplam=$sonuc.Count; uygun=$uygun.Count; kusurlu=$kusur.Count; olculemedi=$olcme.Count
  kusur_siniflari=$sinif
  parti=[ordered]@{ hukum=$(if($partiKusur.Count){'RET'}else{'GECER'}); kusurlar=$partiKusur
    olumsuz_kok_yuzde=$pOlumsuzYuzde; cok_ciktili_yuzde=$pSiraliYuzde; veri_noktasi_ort=$pVeriOrt
    cevap_anahtari=(@($HARFLER | ForEach-Object { "$_=$([math]::Round(100*$pHarf[$_]/$n,1))" }) -join ' ') }
  fatura=[ordered]@{ giris=$topGiris; cikis=$topCikis; usd=[math]::Round($usd,4); bin_soru_tahmini=[math]::Round($(if($sonuc.Count){$usd/$sonuc.Count*1000}else{0}),2) }
  not='Icerik dosyasi veri/fabrika/ altinda (gitignore). Bu rapor yalniz SAYI icerir.' })
Write-Host '-> veri/tam-kontrol-raporu.json'
