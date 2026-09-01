# ============================================================================
#  KALIP PARTİ ÜRETİCİSİ — SÖZLEŞME UYGULAYICI (01.09.2026 gece)
#  Cem: "HEPSİNİ ONAYLIYORUM... 30 soru yap BÜTÜN kararlarla, ben kontrol edeyim"
#
#  KALIP-SOZLESMESI.md'nin 10 maddesini uygular:
#   1 çekirdek (soru+5şık+tuzaklı açıklama+HAP)  2 hesaplıda tablo+verilenler+oynatıcı
#   3 konu başına İKİZ  4 ipucu merdiveni  5 SAYILI rozet (köprüden)
#   6 biçim çapası (onaylı örnek istemde)  8 makine kapıları (aritmetik+kaynak+ikiz-kod-denetimi)
#   (9 kart-akışı ayrı ürün ekranı; bu sayfa KONTROL sayfasıdır — tıklanabilir tam deneyim)
#  Konular KÖPRÜDEN (en çok çıkan), kaynaklar AMBARDAN; kaynaksız konu üretilmez
#  ve KAYNAK-BORCU olarak raporlanır (Cem kuralı: çok çıkıyorsa yutulacak).
#  Cache: veri/fabrika/kalip-parti-<etiket>.json (kesinti güvenli). KASAYA YAZMAZ.
# ============================================================================
param(
  [string]$Sinav='SGS',
  [string]$DersRegex='Finansal Muhasebe',
  [int]$Adet=30,
  [string]$Etiket='sgs-fmuh-30',
  # 01.09 Cem: "bunlar tam FMuh degil" - arsiv tum muhasebeyi tek catida tutuyor;
  # KAYIT-ODAKLI parti icin analiz/ileri-TMS konulari regex'le DISLANIR (dislanan
  # konu kendi dersinin partisine gider, cope degil).
  [string]$KonuDisla=''
)
$ErrorActionPreference='Stop'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$kok=Split-Path -Parent $here
. (Join-Path $here 'api-hedef.ps1')
$CACHE=Join-Path $kok "veri\fabrika\kalip-parti-$Etiket.json"
$HEDEF=Join-Path $kok "sql-yerel\kalip-parti-$Etiket.html"
$KEY=$env:SUPABASE_SERVICE_KEY
if(-not $KEY){ throw 'SUPABASE_SERVICE_KEY yok.' }
$SB=@{ apikey=$KEY; Authorization="Bearer $KEY"; 'User-Agent'='mevzuat-radar-robot/1.0' }

function Coz([string]$txt){
  $tt="$txt".Trim() -replace '^```json\s*','' -replace '^```\s*','' -replace '\s*```$',''
  $c=$null; try{ $c=$tt|ConvertFrom-Json }catch{ $son=$tt.LastIndexOf('}'); if($son -gt 0){ try{ $c=$tt.Substring(0,$son+1)|ConvertFrom-Json }catch{} } }
  return $c
}
function K([string]$t){ return "$t".Replace('&','&amp;').Replace('<','&lt;').Replace('>','&gt;') }
# 01.09 Cem yakaladi: model aciklamayi bazen YAPILI nesne dondurur; ekrana ham
# '@{ne_soruluyor=...}' dokulur. Nesneyse alanlarindan okunur metin derlenir.
function AciklamaDuz($a){
  if($null -eq $a){ return '' }
  if($a -is [string]){ return $a }
  $p=New-Object System.Collections.Generic.List[string]
  if($a.PSObject.Properties['ne_soruluyor'] -and $a.ne_soruluyor){ $p.Add("Ne soruluyor: $($a.ne_soruluyor)") }
  if($a.PSObject.Properties['kural'] -and $a.kural){ $p.Add("Kural: $($a.kural)") }
  if($a.PSObject.Properties['tuzak'] -and $a.tuzak){ $p.Add("$($a.tuzak)") }
  if($a.PSObject.Properties['hesap'] -and $a.hesap){ $p.Add("Hesap: $($a.hesap)") }
  if($a.PSObject.Properties['dogrusu'] -and $a.dogrusu){ $p.Add("Dogrusu: $($a.dogrusu)") }
  if($p.Count -eq 0){ foreach($pr in $a.PSObject.Properties){ $p.Add("$($pr.Value)") } }
  return ($p -join ' ')
}
# sema tur adlari serbest donebiliyor - cizdiricinin tanidigi enum'a indir
function SemaNormalize($s){
  if($null -eq $s -or -not $s.tur){ return $s }
  $t="$($s.tur)".ToLowerInvariant() -replace 'ş','s' -replace 'ı','i'
  $yeni=switch -Regex ($t){ 'yevmiye' {'yevmiye'} 'elem' {'eleme'} 'karar' {'karar'} 'akis|akis' {'akis'} default {''} }
  if(-not $yeni){
    if($s.PSObject.Properties['ogeler'] -and $s.ogeler -and $s.ogeler.PSObject.Properties['borc']){ $yeni='yevmiye' }
    elseif($s.PSObject.Properties['kayitlar'] -and $s.kayitlar){ $yeni='yevmiye' }
    elseif($s.PSObject.Properties['ogeler'] -and @($s.ogeler).Count -and @($s.ogeler)[0] -is [string]){ $yeni='akis' }
  }
  if($yeni){ $s.tur=$yeni }
  return $s
}
function AmbarCek([string[]]$desenler,[int]$tavan=9000){
  $topla=New-Object System.Collections.Generic.List[string]
  $adlar=New-Object System.Collections.Generic.List[string]
  foreach($d in $desenler){
    if(-not $d){ continue }
    $u='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar?select=kaynak_ad,metin&kaynak_ad=ilike.'+[uri]::EscapeDataString($d)+'&limit=6'
    try{ $r=Invoke-RestMethod -Uri $u -Headers $SB -TimeoutSec 60 }catch{ continue }
    foreach($x in @($r)){
      if($adlar -notcontains $x.kaynak_ad){ $adlar.Add($x.kaynak_ad); $topla.Add("[$($x.kaynak_ad)] $($x.metin)") }
    }
    if($adlar.Count -ge 10){ break }
  }
  $m=($topla -join "`n---`n"); if($m.Length -gt $tavan){ $m=$m.Substring(0,$tavan) }
  return @{ metin=$m; adlar=@($adlar) }
}
# dayanak ham metninden ambar sorgu desenleri türet
$KANUN=@{ 'VUK'='VUK (213 s.K.)'; 'TTK'='TTK (6102 s.K.)'; 'TBK'='TBK (6098 s.K.)'; 'GVK'='GVK (193 s.K.)'; 'KVK'='KVK GUT (1 Seri No)'; 'KDV'='KDV%'; 'SPK'='Sermaye Piyasası K. (6362 s.K.)'; 'İİK'='İİK%'; 'SGK'='SGK%' }
function DesenUret($kayit){
  $d=New-Object System.Collections.Generic.List[string]
  foreach($ham in @("$($kayit.dayanak)","$($kayit.cikmis_dayanak)")){
    if(-not $ham){ continue }
    foreach($m in [regex]::Matches($ham,'(TMS|TFRS|BDS|GDS|TSRS|SBDS)\s*(\d+)')){ $d.Add("$($m.Groups[1].Value) $($m.Groups[2].Value) p.%") }
    foreach($m in [regex]::Matches($ham,'THP\s*(\d{3})')){ $d.Add("THP $($m.Groups[1].Value)%") }
    foreach($m in [regex]::Matches($ham,'(VUK|TTK|TBK|GVK)[^m]*m\.?\s*(\d+)(?:\s*[-–]\s*(\d+))?')){
      $ka=$KANUN[$m.Groups[1].Value]; $n1=[int]$m.Groups[2].Value
      $n2=if($m.Groups[3].Success){[int]$m.Groups[3].Value}else{$n1}
      if($n2-$n1 -gt 8){ $n2=$n1+8 }
      for($n=$n1;$n -le $n2;$n++){ $d.Add("$ka m.$n%") }
    }
  }
  if($d.Count -eq 0){
    # teori/eslesmemis: konu adiyla ad-aramasi. 01.09 dersi (7. ek-tuzagi vakasi):
    # 'tahakkuku' ambardaki 'TAHAKKUKLARI' ile eslesmiyordu - kelime KOKUNE inilir
    # (>=6 harfli kelimenin son 2 harfi atilir, joker girer).
    $kel=@(("$($kayit.konu)" -split '\s+') | Where-Object { $_.Length -ge 4 } | Select-Object -First 2 | ForEach-Object { if($_.Length -ge 6){ $_.Substring(0,$_.Length-2) } else { $_ } })
    if($kel.Count -ge 1){ $d.Add('%'+($kel -join '%')+'%') }
  }
  return @($d | Select-Object -Unique)
}
# Haritanin YANLIS dayanak yazdigi konular icin elle dogru kaynak (01.09:
# 'gelir tahakkuku'na 3568 m.29, 'hesap isleyisi'ne TTK 720 yazilmisti - ikisi de
# alakasiz ZAYIF tahmin; gercek kaynaklar THP/VUK).
$OZEL_DESEN=@{
  'gelir tahakkuku' = @('THP 181%','THP 281%','VUK (213 s.K.) m.22%','VUK (213 s.K.) m.283%')
  'hesap isleyisi'  = @('THP 102%','THP 120%','THP 320%','THP 191%','THP 391%')
  # 01.09 hakem-red onarimlari: kuralin YASADIGI paragraflar (tanim+yururluk degil)
  'tms 36 deger dusuklugu'   = @('TMS 36 p.2%','TMS 36 p.4%','TMS 36 p.6%','TMS 36 p.8%','TMS 36 p.9%','TMS 36 p.59%','TMS 36 p.60%')
  'nakit akis tablosu'       = @('TMS 7 p.10%','TMS 7 p.13%','TMS 7 p.14%','TMS 7 p.16%','TMS 7 p.18%','TMS 7 p.19%','TMS 7 p.20%')
  'tms 7 nakit akis tablosu' = @('TMS 7 p.7%','TMS 7 p.8%','TMS 7 p.45%','TMS 7 p.46%','TMS 7 p.10%')
  'tms 12 ertelenmis vergi'  = @('TMS 12 p.5%','TMS 12 p.15%','TMS 12 p.16%','TMS 12 p.20%','TMS 12 p.24%','TMS 12 p.47%')
  # 01.09 kayit-odakli yeni konular (FMuh suzgeci sonrasi)
  'kar dagitimi kaydi'       = @('TTK (6102 s.K.) m.519%','TTK (6102 s.K.) m.523%','THP 570%','THP 590%','THP 591%')
  'kar dagitimi'             = @('TTK (6102 s.K.) m.519%','TTK (6102 s.K.) m.523%','THP 570%','THP 590%','THP 591%')
  'fifo yontemi'             = @('TMS 2 p.25%','TMS 2 p.27%','VUK (213 s.K.) m.274%','THP 153%')
  'finansman bonosu ihraci'  = @('THP 305%','THP 308%','THP 300%')
  'hazine bonosu tahsili'    = @('THP 112%','THP 111%','THP 102%')
  'police muhasebelestirme'  = @('THP 121%','THP 321%','TTK (6102 s.K.) m.671%','TTK (6102 s.K.) m.672%')
  'önemlilik kavramı'        = @('MSUGT 1 kavram%')
  'amortisman ayirma'        = @('THP 257%','THP 730%','THP 770%','VUK (213 s.K.) m.313%','VUK (213 s.K.) m.315%')
  'kesin mizan'              = @('%mizan%','THP 100%','MSUGT 1%')
}
# Hakem yakalamalarindan dogan konu-ozel uretim uyarilari (isteme eklenir)
$OZEL_NOT=@{
  'kar dagitimi kaydi' = "DIKKAT (hakem yakaladi): TTK m.519/2-c'ye gore II. tertip kanuni yedek, 'pay sahiplerine %5 kar payi odendikten sonra KARA KATILACAK KISILERE DAGITILMASI KARARLASTIRILAN TOPLAM TUTARIN %10'u'dur - 'dagitim sonrasi kalan tutarin %10'u' DEGILDIR. Hesabi bu dogru kuralla kur."
  # 01.09 ders-uyum hakemi yakalamalari: konu mesru, SORU acisi kaymisti - KAYIT acisiyla kur
  'muhasebe bilgi sistemi' = "DERS UYARISI (hakem yakaladi): belgenin vergi-hukuku gecerliligini SORMA; belge->yevmiye->defter KAYIT AKISINI ve muhasebe surecindeki rolunu sor (FMuh boyutu)."
  'amortisman ayirma'      = "DERS UYARISI (hakem yakaladi): amortisman HESAPLAMA teknigi/oran secimi Vergi Hukuku'na kacar; burada AYIRMA KAYDINI sor - 7xx/730 gider, 257 Birikmis Amortismanlar isleyisi, dogrudan/endirekt kayit yontemi. Hesap sade tutulur (duz amortisman, tam yil)."
  'gelir tablosu hesaplari'= "DERS UYARISI (hakem yakaladi): dikey yuzde/oran analizi Mali Tablolar Analizi'ne kacar; burada 6xx GELIR TABLOSU HESAPLARININ ISLEYISINI sor - hangi islem hangi hesaba, yansitma/kapanis kayitlari, brut satistan net kara akisin KAYIT boyutu."
}

# --- DERS PROFILI (01.09 Cem: "Excel'de ders ders gonderdim") ----------------
# Resmi ders tanimi veri/ders-profili.json'dan okunur (2-DERSLER sekmesi kokenli).
$DERS_TARIF=''; $KOMSULAR=''
$profYol=Join-Path $kok 'veri\ders-profili.json'
if(Test-Path $profYol){
  $prof=Get-Content $profYol -Raw -Encoding UTF8 | ConvertFrom-Json
  $svTam=@($prof.sinavlar.PSObject.Properties.Name | Where-Object { $_ -match [regex]::Escape($Sinav) }) | Select-Object -First 1
  if($svTam){
    $dAd=@($prof.sinavlar.$svTam.PSObject.Properties.Name | Where-Object { $_ -match $DersRegex }) | Select-Object -First 1
    if($dAd){
      $dp=$prof.sinavlar.$svTam.$dAd
      if($dp.kapsam_tarifi){ $DERS_TARIF="$($dp.kapsam_tarifi)" }
      $KOMSULAR=(@($dp.komsu_dersler) -join ', ')
      "ders profili: $svTam / $dAd | tarif: $($DERS_TARIF.Length) kr | komsu: $(@($dp.komsu_dersler).Count) ders"
    }
  }
}

# --- KONULAR: kopruden en cok cikan (tekil) ---------------------------------
$tam=Get-Content (Join-Path $kok 'veri\fabrika\konu-koprusu.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$adaylar=@($tam | Where-Object { $_.sinav -eq $Sinav -and ("$($_.bizim_ders)$($_.arsiv_ders)" -match $DersRegex) -and $_.donem -ge 1 } | Sort-Object donem -Descending)
$gorulen=@{}; $KONULAR=New-Object System.Collections.Generic.List[object]; $sira=0
foreach($a in $adaylar){
  $kAd="$($a.konu)".ToLowerInvariant()
  if($KonuDisla -and $kAd -match $KonuDisla){ continue }
  if($gorulen[$kAd]){ continue }
  $gorulen[$kAd]=1; $sira++
  $KONULAR.Add(@{ id=('kp-{0:d2}' -f $sira); kayit=$a })
  if($KONULAR.Count -ge $Adet){ break }
}
"konu secildi: $($KONULAR.Count) (kopruden, donem-sirali tekil)"

# --- bicim capasi: onayli p90-SGS-01 ornegi ---------------------------------
$ornekSoru=''
try{
  foreach($sat in (Get-Content (Join-Path $kok 'veri\fabrika\sik90-sonuc.jsonl') -Encoding UTF8)){
    if($sat -match 'p90-SGS-01-'){
      $r=$sat|ConvertFrom-Json
      $e=Coz ((@($r.result.message.content)|? { $_.type -eq 'text' }|Select-Object -Last 1).text)
      if($e -and $e.soru){ $ornekSoru="$($e.soru)`nA) $($e.siklar.A)`nB) $($e.siklar.B)`nC) $($e.siklar.C)`nD) $($e.siklar.D)`nE) $($e.siklar.E)"; break }
    }
  }
}catch{}
"bicim ornegi: $($ornekSoru.Length) kr"

# --- cache ---
$don=[ordered]@{}
if(Test-Path $CACHE){ foreach($p in (Get-Content $CACHE -Raw -Encoding UTF8|ConvertFrom-Json).PSObject.Properties){ $don[$p.Name]=$p.Value } }
"cache: $($don.Count) hazir"
function CacheYaz{ $dN=[ordered]@{}; foreach($x in ($don.Keys|Sort-Object)){ $dN[$x]=$don[$x] }; [IO.File]::WriteAllText($CACHE,(ConvertTo-Json -InputObject $dN -Depth 10),[Text.UTF8Encoding]::new($false)) }

# --- son10'dan canli: genc-dili adim istemi + css + Tablo/Sema cizdiriciler --
$son10=Get-Content (Join-Path $here 'son10-uret.ps1') -Raw -Encoding UTF8
$adimIstem=[regex]::Match($son10,"(?s)\`$adimIstem=@'(.*?)'@").Groups[1].Value
$css=[regex]::Match($son10,"(?s)\`$css=@'(.*?)'@").Groups[1].Value
if($adimIstem.Length -lt 500 -or $css.Length -lt 500){ throw 'son10 sablonlari cekilemedi' }
Invoke-Expression ([regex]::Match($son10,'(?s)function TabloHtml.*?\n\}\r?\n').Value)
Invoke-Expression ([regex]::Match($son10,'(?s)function SemaHtml.*?\n\}\r?\n(?=\r?\n)').Value)

# --- FAZ A: SORU ------------------------------------------------------------
$soruIstem=@'
Sen "Nobetci" adli hoca-yazarsin. {SINAV} sinavinin {DERS} dersinden, verilen KONUda, SIFIRDAN bir sinav sorusu uret. Universite mezunu gence, gercek sinav ayarinda.
KURALLAR (KALIP SOZLESMESI - kural 19-25 seti):
1. YALNIZ asagidaki KAYNAK METNINE dayan; kural/oran/tanim kaynaktan. Senaryo tutarlari serbest.
2. 5 sik, TEK dogru; her yanlis sik BIR ADLI TUZAGIN sonucu.
3. Aciklama takimi her sik icin TEK PARCA DUZ METIN STRING (nesne/alt-alan YASAK): "Ne soruluyor: ... Kural: ... [Ad] Tuzagi: ... Dogrusu: ..." akisiyla. Dogru sikta Hesap: zinciri (hesapliysa).
4. HESAPLI konuysa COZUM TABLOSU ZORUNLU ({"basliklar":[...],"satirlar":[[...]]}, ilk kolon kalem, SON SATIR SONUC). Teorik konuysa cozum_tablo null olabilir ama SEMA ZORUNLU.
4b. MALI TABLO FORMU (Cem: "bilanco/gelir tablosu gibi gorelim"): konu finansal durum/
   bilanco/oran tipiyse tablo BILANCO duzeninde kurulur - bolum basligi AYRI SATIR olur
   ve tutar kolonlari '-' birakilir (or. ["DONEN VARLIKLAR","-"]), altina kalemler,
   sonra ["Donen Varliklar Toplami","120.000"]. Gelir tablosu tipiyse GELIR TABLOSU
   akisi (Brut Satislar'dan asagi). Yevmiye tipiyse sema tur=yevmiye zaten T-cetveli verir.
5. SEMA: tur alani YALNIZ su dort degerden biri olabilir: "yevmiye" | "eleme" | "karar" | "akis" (baska ad/varyant YASAK). Bu ders KAYIT dersiyse ve soru bir islemin muhasebesine dokunuyorsa tur=yevmiye ZORUNLUDUR ({"tur":"yevmiye","baslik":"...","ogeler":{"borc":[{"hesap":"181 GELIR TAHAKKUKLARI","tutar":"..."}],"alacak":[...]}}) - T-cetveli budur. SORUNUN KENDI VERISIYLE, jenerik yasak.
6. hap (tek cumle kalici kural), sinav_taktigi (1 cumle), notlandirici (en cok puan kaybettiren nokta).
7. Rakamlar her katmanda BIREBIR tutarli.
8. DERS KAPSAMI (RESMI - 01.09): {DERS_TARIF}
   Bu kapsamin DISINA cikan soru uretme; konu kapsama uymuyorsa soruyu KAPSAMA
   UYAN acisiyla kur (or. TMS konusu geldiyse KAYIT boyutunu sor, olcum teknigi degil).
BICIM CAPASI - asagidaki onayli ornekle AYNI ses/uzunluk/sik yapisi:
{ORNEK}
Cevap YALNIZ JSON:
{"soru":"...","siklar":{"A":"...","B":"...","C":"...","D":"...","E":"..."},"dogru":"X","aciklama":{...},"hap":"...","sinav_taktigi":"...","notlandirici":"...","sema":{...},"cozum_tablo":{...veya null},"dayanak":"kisa kunye"}
=== KONU === {KONU}  (cikmis arsivde {DONEM} ayri donemde soruldu)
=== KAYNAK METNI (ambardan) === {KAYNAK}
'@
$rapor=New-Object System.Collections.Generic.List[string]
$kaynakBorcu=New-Object System.Collections.Generic.List[string]
foreach($kk in $KONULAR){
  $id=$kk.id
  if($don.Contains($id) -and $don[$id].soru){ continue }
  $ky=$kk.kayit
  $konuLc="$($ky.konu)".ToLowerInvariant()
  $desenler=if($OZEL_DESEN.ContainsKey($konuLc)){ $OZEL_DESEN[$konuLc] } else { DesenUret $ky }
  $amb=AmbarCek $desenler
  if(-not $amb.metin -or $amb.metin.Length -lt 300){
    $kaynakBorcu.Add("[$($ky.donem) donem] $($ky.konu) | dayanak: $($ky.dayanak) / $($ky.cikmis_dayanak)")
    Write-Host "  KAYNAK BORCU: $($ky.konu)" -ForegroundColor Yellow
    continue
  }
  # KAPI A (01.09 Cem: "boyle yanlislar olursa ben yanarim"): kaynak-konu ALAKA denetimi.
  # Konu kelime koklerinden en az biri kaynak metninde gecmeli; gecmiyorsa kaynak
  # ALAKASIZ demektir (haritanin yanlis dayanagi ambarda var diye soruya sizamaz).
  # 10. Turkce vakasi: kokler ve metin AYNI katlamadan gecmeli ('dagiti' vs 'dağıtı')
  function KokKatla([string]$s){ ("$s" -creplace 'İ','i' -creplace 'I','i' -creplace 'ı','i' -creplace 'Ğ','g' -creplace 'ğ','g' -creplace 'Ü','u' -creplace 'ü','u' -creplace 'Ş','s' -creplace 'ş','s' -creplace 'Ö','o' -creplace 'ö','o' -creplace 'Ç','c' -creplace 'ç','c').ToLowerInvariant() }
  $konuKokler=@(("$($ky.konu)" -split '\s+') | Where-Object { $_.Length -ge 4 -and $_ -notmatch '^\d' } | ForEach-Object { $k2=KokKatla $_; if($k2.Length -ge 6){ $k2.Substring(0,$k2.Length-2) } else { $k2 } })
  $ambLc=KokKatla $amb.metin
  $alaka=($konuKokler.Count -eq 0) -or (@($konuKokler | Where-Object { $ambLc.Contains($_) }).Count -ge 1)
  if(-not $alaka){
    $kaynakBorcu.Add("[$($ky.donem) donem] $($ky.konu) | KAPI-A: cekilen kaynak konuyla ALAKASIZ ($((@($amb.adlar)|Select-Object -First 2) -join '; '))")
    Write-Host "  KAPI-A RED (alakasiz kaynak): $($ky.konu)" -ForegroundColor Yellow
    continue
  }
  $ekNot=if($OZEL_NOT.ContainsKey($konuLc)){ "`nOZEL UYARI: $($OZEL_NOT[$konuLc])" } else { '' }
  $ist=$soruIstem.Replace('{SINAV}',$Sinav).Replace('{DERS}',$DersRegex).Replace('{DERS_TARIF}',$DERS_TARIF).Replace('{KONU}',"$($ky.konu)").Replace('{DONEM}',"$($ky.donem)").Replace('{ORNEK}',$ornekSoru).Replace('{KAYNAK}',$amb.metin)+$ekNot
  $y=$null
  foreach($d in 1..3){ try{ $y=Invoke-ClaudeMesaj -Model 'claude-sonnet-5' -Icerik $ist -MaxTok 20000; break }catch{ if($d -eq 3){throw}; Start-Sleep -Seconds (10*$d) } }
  $cvp=Coz $y.metin
  if($cvp -and $cvp.soru -and $cvp.aciklama){
    # sema alan-adi normalizasyonu (01.09 bug: model 'ogeler' yerine 'adimlar' dondurdu -> bos cizim)
    if($cvp.sema -and -not $cvp.sema.PSObject.Properties['ogeler'] -and $cvp.sema.PSObject.Properties['adimlar']){
      $cvp.sema | Add-Member -NotePropertyName ogeler -NotePropertyValue @($cvp.sema.adimlar) -Force
    }
    $cvp | Add-Member -NotePropertyName konu -NotePropertyValue "$($ky.konu)" -Force
    $cvp | Add-Member -NotePropertyName kaynak_metin_ozet -NotePropertyValue ($amb.metin.Substring(0,[Math]::Min(4500,$amb.metin.Length))) -Force
    $cvp | Add-Member -NotePropertyName donem -NotePropertyValue $ky.donem -Force
    $cvp | Add-Member -NotePropertyName kaynak_adlar -NotePropertyValue @($amb.adlar) -Force
    $don[$id]=$cvp; CacheYaz
    Write-Host "  SORU OK [$($don.Count)/$($KONULAR.Count)] $id $($ky.konu)"
  } else { $rapor.Add("BOZUK: $($ky.konu)"); Write-Host "  BOZUK: $id" -ForegroundColor Yellow }
}

# --- FAZ B: ADIMLAR (hesaplilarda; genc dili) --------------------------------
foreach($id in @($don.Keys)){
  $cvp=$don[$id]
  if(-not $cvp.cozum_tablo -or -not $cvp.cozum_tablo.satirlar){ continue }
  if($cvp.PSObject.Properties['adimlar'] -and $cvp.adimlar -and $cvp.PSObject.Properties['verilen']){ continue }
  $ist2=$adimIstem.Replace('{SORUM}',"$($cvp.soru)").Replace('{TABLO}',(ConvertTo-Json -InputObject $cvp.cozum_tablo -Depth 5 -Compress)).Replace('{ACIK}',"$($cvp.aciklama.$($cvp.dogru))")
  $y2=$null
  foreach($d in 1..3){ try{ $y2=Invoke-ClaudeMesaj -Model 'claude-sonnet-5' -Icerik $ist2 -MaxTok 12000; break }catch{ if($d -eq 3){throw}; Start-Sleep -Seconds (10*$d) } }
  $a2=Coz $y2.metin
  if($a2 -and $a2.adimlar){
    $cvp | Add-Member -NotePropertyName adimlar -NotePropertyValue $a2.adimlar -Force
    $cvp | Add-Member -NotePropertyName verilen -NotePropertyValue @($a2.verilen) -Force
    CacheYaz; Write-Host "  ADIM OK $id"
  } else { $rapor.Add("ADIM BOZUK: $id") }
}

# --- FAZ C: IKIZ (konu basina 1 = her soru; kod denetimli) -------------------
$ikizIstem=@'
Asagidaki COZULMUS sorunun IKIZINI uret: AYNI yontem, FARKLI rakamlar/adlar, FARKLI hedef kalem sorulabilir. Ogrenci tabloyu KENDISI dolduracak.
KURALLAR:
1. ikiz_soru: yeni kisa soru metni (rakamlar YENI). hedef_cumle: "tabloyu doldur ve X'in ... oldugunu bul" tarzi tek cumle.
2. tablo: ana soruyla AYNI kolon yapisi; TUM hucre degerleri YENI rakamlarla DOLU (dogru cevaplar - kontrol icin).
3. verilen: [[satir,kolon],...] = YALNIZ ikiz_soru METNINDE ACIKCA verilen degerlerin koordinatlari.
4. bosluk: [[satir,kolon],...] = ogrencinin dolduracagi TUM kalan hucreler (kalem kolonu haric). verilen+bosluk = kalem-disi TUM hucreler; SIZINTI YASAK (verilende olmayan hicbir deger metinde gecmez).
5. Rakamlar aritmetik TUTARLI.
Cevap YALNIZ JSON: {"ikiz_soru":"...","hedef_cumle":"...","tablo":{"basliklar":[...],"satirlar":[[...]]},"verilen":[[r,c],...],"bosluk":[[r,c],...]}
=== ANA SORU === {SORU}
=== ANA TABLO === {TABLO}
'@
foreach($id in @($don.Keys)){
  $cvp=$don[$id]
  if(-not $cvp.cozum_tablo -or -not $cvp.cozum_tablo.satirlar){ continue }
  if($cvp.PSObject.Properties['ikiz'] -and $cvp.ikiz){ continue }
  $ist3=$ikizIstem.Replace('{SORU}',"$($cvp.soru)").Replace('{TABLO}',(ConvertTo-Json -InputObject $cvp.cozum_tablo -Depth 5 -Compress))
  $y3=$null
  foreach($d in 1..3){ try{ $y3=Invoke-ClaudeMesaj -Model 'claude-sonnet-5' -Icerik $ist3 -MaxTok 9000; break }catch{ if($d -eq 3){throw}; Start-Sleep -Seconds (10*$d) } }
  $a3=Coz $y3.metin
  $gecerli=$false
  if($a3 -and $a3.tablo -and $a3.tablo.satirlar){
    # KOD DENETIMI (fark.html dersi): verilen ∪ bosluk = kalem-disi tum hucreler
    $kume=@{}
    foreach($v in @($a3.verilen)){ $kume["$(@($v)[0]),$(@($v)[1])"]='v' }
    foreach($v in @($a3.bosluk)){ $kume["$(@($v)[0]),$(@($v)[1])"]='b' }
    $gecerli=$true
    $ns=@($a3.tablo.satirlar).Count
    for($r=0;$r -lt $ns;$r++){
      $kc=@(@($a3.tablo.satirlar)[$r]).Count
      for($c=1;$c -lt $kc;$c++){
        $hv="$(@(@($a3.tablo.satirlar)[$r])[$c])"
        if($hv -eq '-' -or $hv -eq ''){ continue }
        if(-not $kume.ContainsKey("$r,$c")){ $gecerli=$false }
      }
    }
  }
  if($gecerli){
    $cvp | Add-Member -NotePropertyName ikiz -NotePropertyValue $a3 -Force
    CacheYaz; Write-Host "  IKIZ OK $id"
  } else { $rapor.Add("IKIZ REDDEDILDI (kapsama denetimi): $id"); Write-Host "  IKIZ RED: $id" -ForegroundColor Yellow }
}

# --- FAZ S: YEVMIYE TAMAMLAMA (01.09 Cem: "muhasebe kaydini gostermiyorsun,
# T-cetveli soru cozecektik") - KAYIT dersinde tablolu her soru yevmiyesiz kalamaz.
$yevmiyeIstem=@'
Asagidaki cozulmus muhasebe sorusunun YEVMIYE KAYDINI/KAYITLARINI (T-cetveli) uret. Rakamlar soru/tablodakiyle BIREBIR; hesap adlari Tekduzen Hesap Plani kod+adiyla ("121 ALACAK SENETLERI" gibi).
ZINCIR KURALI (Cem 01.09): Soruda birden fazla islem (OLAY ZINCIRI) varsa her islemin maddesi AYRI kayit olarak SIRAYLA verilir - ornek: 1) Satis kaydi: 120 ALICILAR borc / 600 YURTICI SATISLAR alacak + 391 HESAPLANAN KDV alacak, 2) Policenin kabulu: 121 ALACAK SENETLERI borc / 120 ALICILAR alacak. Ogrenci "bu kayit nereden geldi" diye gormeli. Tek islem varsa tek kayit yeterli. Her kayit basligi "1) ...", "2) ..." diye numarali ve islemi soyler.
Cevap YALNIZ JSON: {"tur":"yevmiye","baslik":"...","kayitlar":[{"baslik":"1) ...","ogeler":{"borc":[{"hesap":"...","tutar":"..."}],"alacak":[{"hesap":"...","tutar":"..."}]}}]}
ISTISNA: Soru KAVRAMSAL ya da SALT HESAPLAMA ise (ornek: ozkaynak = aktif - borclar hesabi, TMS kavram sorusu) ve yevmiye kaydi GERCEKTEN uygulanmiyorsa UYDURMA kayit yazma - su JSON'u dondur: {"tur":"yok","sebep":"tek cumle neden"}
=== SORU === {SORU}
=== COZUM TABLOSU === {TABLO}
=== DOGRU ACIKLAMA === {ACIK}
'@
foreach($id in @($don.Keys)){
  $cvp=$don[$id]
  if(-not $cvp.soru -or -not $cvp.cozum_tablo -or -not $cvp.cozum_tablo.satirlar){ continue }
  $cvp.sema=SemaNormalize $cvp.sema
  # atlama SIKI: tur=yevmiye YETMEZ, yapisi da standart olmali (01.09: 11 soruda
  # modelin serbest 'madde/kayit' bicimi cizdiriciye BOS tablo bastirdi).
  # 01.09 zincir kurali: artik ZORUNLU bicim 'kayitlar' dizisi - eski tek-'ogeler'
  # kayitlar yeniden basilir ki olay zinciri (satis + police) tam gorunsun.
  $ky0=$null; if($cvp.sema -and $cvp.sema.PSObject.Properties['kayitlar']){ $ky0=@($cvp.sema.kayitlar) }
  if($cvp.sema -and "$($cvp.sema.tur)" -eq 'yevmiye' -and $ky0 -and $ky0.Count -ge 1 -and -not @($ky0 | Where-Object { -not ($_.ogeler -and $_.ogeler.PSObject.Properties['borc'] -and @($_.ogeler.borc).Count -ge 1) }).Count){ continue }
  # gerekceli 'yevmiye uygulanmaz' karari (kp-07 ozkaynak hesabi, kp-21 TMS kavrami) - tekrar denenmez
  if($cvp.PSObject.Properties['yevmiye_yok'] -and $cvp.yevmiye_yok){ continue }
  $istY=$yevmiyeIstem.Replace('{SORU}',"$($cvp.soru)").Replace('{TABLO}',(ConvertTo-Json -InputObject $cvp.cozum_tablo -Depth 5 -Compress)).Replace('{ACIK}',(AciklamaDuz $cvp.aciklama.$($cvp.dogru)))
  $yv=$null
  foreach($d in 1..3){ try{ $yv=Invoke-ClaudeMesaj -Model 'claude-sonnet-5' -Icerik $istY -MaxTok 3000; break }catch{ if($d -eq 3){throw}; Start-Sleep -Seconds (8*$d) } }
  $sv2=Coz $yv.metin
  # 01.09: her tablolu soru kayit sorusu degil - model gerekcesiyle 'yok' derse
  # uydurma kayit YAZDIRILMAZ. Sozel sema (eleme/karar/akis) varsa korunur;
  # sahte tek-yevmiye varsa dusurulur (sema='yok' -> cizdirici hic basmaz).
  if($sv2 -and "$($sv2.tur)" -eq 'yok'){
    $sozel=($cvp.sema -and (@('eleme','karar','akis') -contains "$($cvp.sema.tur)") -and $cvp.sema.PSObject.Properties['ogeler'] -and $cvp.sema.ogeler)
    if(-not $sozel){ $cvp | Add-Member -NotePropertyName sema -NotePropertyValue ([pscustomobject]@{tur='yok'}) -Force }
    $cvp | Add-Member -NotePropertyName yevmiye_yok -NotePropertyValue "$($sv2.sebep)" -Force
    CacheYaz; Write-Host "  YEVMIYE GEREKMIYOR (gerekceli) $id"; continue
  }
  # zincir bicimi dogrulama: kayitlar[] var ve HER kayitta borc dolu; eski tek-ogeler de kabul (sarmalanir)
  if($sv2 -and -not ($sv2.PSObject.Properties['kayitlar'] -and $sv2.kayitlar) -and $sv2.ogeler -and $sv2.ogeler.borc){
    $sv2 | Add-Member -NotePropertyName kayitlar -NotePropertyValue @(,([pscustomobject]@{baslik='';ogeler=$sv2.ogeler})) -Force
  }
  if($sv2 -and $sv2.kayitlar -and @($sv2.kayitlar).Count -ge 1 -and -not @(@($sv2.kayitlar) | Where-Object { -not ($_.ogeler -and $_.ogeler.borc) }).Count){
    $cvp | Add-Member -NotePropertyName sema -NotePropertyValue $sv2 -Force
    CacheYaz; Write-Host "  YEVMIYE OK $id"
  } else { $rapor.Add("YEVMIYE BOZUK: $id") }
}

# --- YEVMIYE DENKLIK KAPISI (01.09 Cem: "altinda toplam borcun alacagin tuttugu")
# Her kayitta borc toplami = alacak toplami olmali; tutmayan uretim notuna duser.
function YvT2([string]$t){ $s=("$t" -replace '(?i)\s*tl\s*','' -replace '[^\d\.,]',''); if(-not $s){ return $null }; try{ return [decimal]::Parse($s,[Globalization.CultureInfo]::GetCultureInfo('tr-TR')) }catch{ return $null } }
foreach($id in @($don.Keys)){
  $cvp=$don[$id]
  if(-not ($cvp.sema -and "$($cvp.sema.tur)" -eq 'yevmiye' -and $cvp.sema.PSObject.Properties['kayitlar'])){ continue }
  $ki=0
  foreach($ky in @($cvp.sema.kayitlar)){
    $ki++
    if(-not $ky.ogeler){ continue }
    $tB=[decimal]0; $tA=[decimal]0; $tam=$true
    foreach($og in @($ky.ogeler.borc)){ $n=YvT2 $og.tutar; if($null -ne $n){ $tB+=$n } else { $tam=$false } }
    foreach($og in @($ky.ogeler.alacak)){ $n=YvT2 $og.tutar; if($null -ne $n){ $tA+=$n } else { $tam=$false } }
    if($tam -and $tB -ne $tA){ $rapor.Add("YEVMIYE DENK DEGIL: $id kayit $ki (borc $tB / alacak $tA)") }
  }
}

# --- KAPI B: DAYANAK HAKEMI (01.09 Cem guvencesi) ----------------------------
# Bagimsiz ucuz gozle her soru sinanir: "dogru sikkin kurali kaynaktan cikiyor mu?"
# HAYIR -> sayfada kirmizi HAKEM REDDI damgasi; kasa yolunda karantina demektir.
$hakemIstem=@'
Sen bagimsiz bir DENETCI-HAKEMSIN. IKI ayri karar vereceksin:
1) DAYANAK: sorunun DOGRU sikkinin dayandigi kural/bilgi, verilen KAYNAK METNINDEN gercekten cikiyor mu?
   Kaynakta ACIKCA destegi varsa EVET; kural kaynakta yoksa ya da celisiyorsa HAYIR.
   (Parasal senaryo tutarlari kaynakta olmak zorunda degil; KURAL/oran/tanim kaynaktan olmali.)
2) DERS UYUMU (KAPI C - 01.09): soru "{DERS}" dersinin RESMI KAPSAMINA uyuyor mu,
   yoksa su komsu derslerden birinin sorusu mu: {KOMSULAR}?
   RESMI KAPSAM: {TARIF}
   Kapsama uyuyorsa EVET; baska dersin sorusuysa DERS-DISI (+hangi ders).
Cevap YALNIZ JSON: {"karar":"EVET|HAYIR","gerekce":"tek cumle","ders_uyum":"EVET|DERS-DISI","ders_gerekce":"tek cumle (DERS-DISI ise hangi ders)"}
=== SORU === {SORU}
=== DOGRU SIK ({DOGRU}) === {SIK}
=== DOGRU SIKKIN ACIKLAMASI === {ACIK}
=== KAYNAK METNI === {KAYNAK}
'@
foreach($id in @($don.Keys)){
  $cvp=$don[$id]
  if(-not $cvp.soru){ continue }
  if($cvp.PSObject.Properties['hakem'] -and $cvp.hakem -and $cvp.hakem.PSObject.Properties['ders_uyum']){ continue }
  # sema normalizasyonu geriye donuk (ogeler<-adimlar)
  if($cvp.sema -and -not $cvp.sema.PSObject.Properties['ogeler'] -and $cvp.sema.PSObject.Properties['adimlar']){
    $cvp.sema | Add-Member -NotePropertyName ogeler -NotePropertyValue @($cvp.sema.adimlar) -Force
  }
  $kMetin=''
  if($cvp.PSObject.Properties['kaynak_metin_ozet'] -and $cvp.kaynak_metin_ozet){ $kMetin=$cvp.kaynak_metin_ozet }
  elseif($cvp.PSObject.Properties['kaynak_adlar'] -and @($cvp.kaynak_adlar).Count){
    $parca=New-Object System.Collections.Generic.List[string]
    foreach($ka in (@($cvp.kaynak_adlar) | Select-Object -First 4)){
      $u='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar?select=metin&kaynak_ad=eq.'+[uri]::EscapeDataString($ka)+'&limit=1'
      try{ $r=Invoke-RestMethod -Uri $u -Headers $SB -TimeoutSec 60; if(@($r).Count){ $parca.Add("[$ka] $(@($r)[0].metin)") } }catch{}
    }
    $kMetin=($parca -join "`n---`n"); if($kMetin.Length -gt 4500){ $kMetin=$kMetin.Substring(0,4500) }
  }
  else{
    # hakem-red onarimi: kaynak alanlari silinmisse OZEL_DESEN/DesenUret ile TAZE cek
    $konuLc2="$($cvp.konu)".ToLowerInvariant()
    $ds=if($OZEL_DESEN.ContainsKey($konuLc2)){ $OZEL_DESEN[$konuLc2] } else { DesenUret ([pscustomobject]@{konu=$cvp.konu;dayanak=$cvp.dayanak;cikmis_dayanak=''}) }
    $amb2=AmbarCek $ds
    $kMetin=$amb2.metin
    if($amb2.adlar.Count){ $cvp | Add-Member -NotePropertyName kaynak_adlar -NotePropertyValue @($amb2.adlar) -Force }
  }
  if(-not $kMetin){ $rapor.Add("HAKEM ATLANDI (kaynak cekilemedi): $id"); continue }
  $ih=$hakemIstem.Replace('{DERS}',$DersRegex).Replace('{KOMSULAR}',$KOMSULAR).Replace('{TARIF}',$DERS_TARIF).Replace('{SORU}',"$($cvp.soru)").Replace('{DOGRU}',"$($cvp.dogru)").Replace('{SIK}',"$($cvp.siklar.$($cvp.dogru))").Replace('{ACIK}',"$($cvp.aciklama.$($cvp.dogru))").Replace('{KAYNAK}',$kMetin)
  $yh=$null
  foreach($d in 1..3){ try{ $yh=Invoke-ClaudeMesaj -Model 'claude-haiku-4-5-20251001' -Icerik $ih -MaxTok 600; break }catch{ if($d -eq 3){throw}; Start-Sleep -Seconds (8*$d) } }
  $hk=Coz $yh.metin
  if($hk -and $hk.karar){
    $cvp | Add-Member -NotePropertyName hakem -NotePropertyValue $hk -Force
    CacheYaz
    $renk=if("$($hk.karar)" -eq 'EVET'){'Green'}else{'Red'}
    Write-Host "  HAKEM $($hk.karar): $id" -ForegroundColor $renk
  } else { $rapor.Add("HAKEM CIKTISI BOZUK: $id") }
}
$hakemRed=@($don.Keys | Where-Object { $don[$_].PSObject.Properties['hakem'] -and "$($don[$_].hakem.karar)" -eq 'HAYIR' })
$dersRed=@($don.Keys | Where-Object { $don[$_].PSObject.Properties['hakem'] -and "$($don[$_].hakem.ders_uyum)" -eq 'DERS-DISI' })

# --- ARITMETIK KAPISI --------------------------------------------------------
function SayiCoz([string]$s){ $t=$s -replace '\.','' -replace ',','.'; $v=0.0; if([double]::TryParse($t,[Globalization.NumberStyles]::Any,[Globalization.CultureInfo]::InvariantCulture,[ref]$v)){ return $v }; return $null }
# 01.09 v2: TAM-ZINCIR degerlendirme - "a + b + c = d" gibi cok terimlileri
# ilk surum son iki terimden okuyup 8 SAHTE alarm uretmisti. Artik '=' solundaki
# butun sayi-op dizisi soldan saga hesaplanir (kimlik parantezleri atilir).
$aritUyari=New-Object System.Collections.Generic.List[string]
foreach($id in @($don.Keys)){
  foreach($a in @($don[$id].adimlar)){
    foreach($sat in ("$($a.formul)" -split "`n")){
      # birim sozcukleri sayi zincirini kirmasin ('108.000 TL x 6/12' vakasi)
      $tmz=$sat -replace '×','x' -replace 'X','x' -replace '\([^)]*\)',' ' -replace '%\s*([\d\.,]+)','$1/100 ' -replace '(?i)\b(TL|USD|EUR|kg|ton|adet|ay|yil|gun|saat|birim|kisi)\b',' '
      foreach($m in [regex]::Matches($tmz,'((?:[\d\.,]+\s*[x*/+\-]\s*)+[\d\.,]+)\s*=\s*([\d\.,]+)')){
        $sol=$m.Groups[1].Value; $c1=SayiCoz $m.Groups[2].Value
        # DIL-IFADESI filtresi (01.09, Cem yakaladi): "X'in %5'i = Y" carpim isareti
        # icermez; %-normalizasyonu sonrasi tek basina 'N/100 = Y' kalir - bu bir
        # hesap zinciri DEGIL, degerlendirilemez. Ayni sekilde salt-yuzde toplami
        # ('50/100 + 30/100 ... = 100') yuzde-puani toplamidir, atlanir.
        if($sol -match '^\s*[\d\.,]+\s*/\s*100\s*$'){ continue }
        if($sol -match '^(\s*[\d\.,]+\s*/\s*100\s*\+?\s*)+$'){ continue }
        if($null -eq $c1){ continue }
        $parcalar=[regex]::Matches($sol,'([\d\.,]+)|([x*/+\-])')
        $hes=$null; $op=$null; $gecerli=$true
        foreach($pp in $parcalar){
          $tk=$pp.Value
          if($tk -match '^[x*/+\-]$'){ $op=$tk }
          else{
            $v=SayiCoz $tk; if($null -eq $v){ $gecerli=$false; break }
            if($null -eq $hes){ $hes=$v }
            else{
              switch($op){ '/'{ if($v -ne 0){$hes=$hes/$v}else{$gecerli=$false} } 'x'{$hes=$hes*$v} '*'{$hes=$hes*$v} '+'{$hes=$hes+$v} '-'{$hes=$hes-$v} default{$gecerli=$false} }
            }
          }
        }
        if($gecerli -and $null -ne $hes -and [Math]::Abs($hes-$c1) -gt [Math]::Max(0.51,[Math]::Abs($c1)*0.001)){ $aritUyari.Add("$id : '$($m.Value)' hesap=$([math]::Round($hes,2))") }
      }
    }
  }
}

# --- SAYFA (tiklanabilir TAM deneyim: sik->tuzak->oynatici->ikiz->ipucu) -----
$ekCss=@'
.sikbtn{display:block;width:100%;text-align:left;background:#26231f;border:1px solid #3b372f;border-radius:10px;color:#e8e6e3;padding:10px 13px;margin:6px 0;font-size:.95em;cursor:pointer;font-family:inherit}
.sikbtn:hover{border-color:#c9a227}.sikbtn.dg{border-color:#7fc98f;background:rgba(127,201,143,.10)}.sikbtn.yn{border-color:#e07b7b;background:rgba(224,123,123,.10)}
.tzk{display:none;border-left:3px solid #e07b7b;background:rgba(224,123,123,.08);border-radius:0 8px 8px 0;padding:8px 11px;margin:8px 0;font-size:.9em}
.acik{display:none}
.ikizB{display:none;border:1px dashed #7fc98f;border-radius:12px;padding:12px;margin-top:10px}
.ikx{width:104px;background:#1b1b1f;border:1px solid #5a5648;border-radius:6px;color:#e8e6e3;padding:4px 7px;font-family:inherit;font-size:.9em}
.ikx.dog{border-color:#7fc98f;background:rgba(127,201,143,.12)}.ikx.yan{border-color:#e07b7b;background:rgba(224,123,123,.12)}
.verilen{box-shadow:inset 3px 0 0 #78b4ff}
.ipP{display:none;border:1px solid #78b4ff;border-radius:10px;padding:9px 12px;margin-top:8px;background:rgba(120,180,255,.07);font-size:.9em}
.ipP .ipf{font-family:Consolas,monospace;font-size:.92em;color:#8fd0ff;background:rgba(120,180,255,.10);border-radius:8px;padding:6px 9px;margin-top:5px;white-space:pre-line}
.dgm2{display:inline-block;background:#c9a227;color:#1b1b1f;font-weight:800;border:none;border-radius:8px;padding:7px 13px;cursor:pointer;font-family:inherit;margin:8px 6px 0 0;font-size:.88em}
.rozet2{display:inline-block;background:rgba(201,162,39,.14);border:1px solid #c9a227;color:#c9a227;border-radius:999px;padding:2px 10px;font-size:.78em;font-weight:800;margin-left:8px}
'@
$sb=[Text.StringBuilder]::new()
[void]$sb.Append("<!doctype html><html lang=""tr""><head><meta charset=""utf-8""><title>KALIP PARTİSİ — $Sinav $DersRegex ($($don.Count) soru)</title><style>$css$ekCss</style></head><body>")
[void]$sb.Append("<h1>🧪 KALIP PARTİSİ — $Sinav / $DersRegex — SÖZLEŞMENİN TAMAMI, TIKLANABİLİR</h1><p style='color:#aaa;font-size:13px'>Şık seç → tuzak kutusu → açıklama → 🎬 adım adım → ✍️ ikiz + 💡 ipucu. Konular köprüden, kaynaklar ambardan. KASAYA YAZILMADI.</p>")
if($kaynakBorcu.Count){ [void]$sb.Append("<div style='border:1px solid #e07b7b;border-radius:10px;padding:10px;margin:10px 0;font-size:.85em'><b>📌 KAYNAK BORCU (üretilmedi — yutulacak):</b><br>$(($kaynakBorcu | ForEach-Object { K $_ }) -join '<br>')</div>") }
if($rapor.Count){ [void]$sb.Append("<p style='color:#e0a458;font-size:12px'>Üretim notları: $(K ($rapor -join ' · '))</p>") }
if($aritUyari.Count){ [void]$sb.Append("<p style='color:#ff8080;font-size:12px'>⚠ Aritmetik uyarı ($($aritUyari.Count)): $(K (($aritUyari|Select-Object -First 6) -join ' · '))</p>") }
if($hakemRed.Count){ [void]$sb.Append("<div style='border:2px solid #ff6b5e;border-radius:10px;padding:10px;margin:10px 0;font-size:.85em'><b>⛔ HAKEM REDDİ ($($hakemRed.Count)) — kasa yolunda karantina:</b><br>$(($hakemRed | ForEach-Object { K ("$_ : "+$don[$_].hakem.gerekce) }) -join '<br>')</div>") }
else{ [void]$sb.Append("<p style='color:#7fc98f;font-size:12.5px'>✅ Dayanak Hakemi: $(@($don.Keys | Where-Object { $don[$_].PSObject.Properties['hakem'] }).Count) sorunun tamamı ONAYLI.</p>") }
if($dersRed.Count){ [void]$sb.Append("<div style='border:2px solid #e0a458;border-radius:10px;padding:10px;margin:10px 0;font-size:.85em'><b>📚 DERS-DIŞI ($($dersRed.Count)) — kendi dersinin partisine devredilecek:</b><br>$(($dersRed | ForEach-Object { K ("$_ ($($don[$_].konu)) : "+$don[$_].hakem.ders_gerekce) }) -join '<br>')</div>") }
else{ [void]$sb.Append("<p style='color:#7fc98f;font-size:12.5px'>✅ Ders-Uyum Hakemi (KAPI C): tüm sorular '$DersRegex' resmî kapsamına uygun.</p>") }
$adet=0
$amap=[ordered]@{}; $vmap=[ordered]@{}; $tzmap=[ordered]@{}; $ikmap=[ordered]@{}
foreach($id in ($don.Keys|Sort-Object)){
  $cvp=$don[$id]; if(-not $cvp.soru){ continue }
  $adet++
  $adVar=($cvp.PSObject.Properties['adimlar'] -and $cvp.adimlar)
  $ikVar=($cvp.PSObject.Properties['ikiz'] -and $cvp.ikiz)
  # tuzak sozlugu: aciklamalardan ad cek
  $tz=[ordered]@{}
  foreach($hh in 'A','B','C','D','E'){
    if("$($cvp.dogru)" -eq $hh){ continue }
    $mt=[regex]::Match((AciklamaDuz $cvp.aciklama.$hh),'([A-ZÇĞİÖŞÜ][\w çğıöşüÇĞİÖŞÜ\-]{2,60}?Tuza[ğg]ı)')
    if($mt.Success){ $tz[$hh]=$mt.Groups[1].Value.Trim() }
  }
  $tzmap[$id]=$tz
  $hkDamga=''
  if($cvp.PSObject.Properties['hakem'] -and $cvp.hakem){
    if("$($cvp.hakem.karar)" -eq 'EVET'){ $hkDamga="<span style='color:#7fc98f;font-size:.72em;font-weight:800;margin-left:8px'>✅ hakem onaylı</span>" }
    else{ $hkDamga="<span style='color:#ff6b5e;font-size:.72em;font-weight:800;margin-left:8px'>⛔ HAKEM REDDİ: $(K $cvp.hakem.gerekce)</span>" }
  }
  [void]$sb.Append("<div class='soru' data-sid='$id' data-dogru='$($cvp.dogru)'><span class='tip'>YENİ</span><span class='konu'>#$adet · $(K $cvp.konu)</span><span class='rozet2'>📌 Çıkmış arşivde $($cvp.donem) dönemde soruldu</span>$hkDamga<div style='font-size:.72em;color:#777;margin-top:2px'>kaynak: $(K ((@($cvp.kaynak_adlar)|Select-Object -First 2) -join '; '))</div>")
  [void]$sb.Append("<p><b>$(K $cvp.soru)</b></p>")
  foreach($hh in 'A','B','C','D','E'){ [void]$sb.Append("<button class='sikbtn' data-h='$hh'>$hh) $(K $cvp.siklar.$hh)</button>") }
  [void]$sb.Append("<div class='tzk'></div><div class='acik'><div class='ac'>")
  foreach($hh in 'A','B','C','D','E'){
    $isr=''; if("$($cvp.dogru)" -eq $hh){ $isr=' ✓' }
    [void]$sb.Append("<p><b>$hh$isr)</b> $(K (AciklamaDuz $cvp.aciklama.$hh))</p>")
  }
  if($adVar){ [void]$sb.Append("<div><button class='padim'>🎬 Bu çözümü adım adım yaşa</button><div class='panlat'><div class='psayac'></div><div class='pformul'></div><div class='pmetin' style='margin-top:6px;font-size:.93em'></div><button class='padim pileri' style='margin-top:8px;padding:6px 12px;font-size:.85em'>İleri →</button></div></div>") }
  $verList=$null; if($cvp.PSObject.Properties['verilen']){ $verList=$cvp.verilen }
  [void]$sb.Append((TabloHtml $cvp.cozum_tablo $verList))
  [void]$sb.Append((SemaHtml $cvp.sema))
  if($ikVar){
    $ik=$cvp.ikiz
    $ikVerK=@{}; foreach($v in @($ik.verilen)){ $ikVerK["$(@($v)[0]),$(@($v)[1])"]=1 }
    $ikBosK=@{}; foreach($v in @($ik.bosluk)){ $ikBosK["$(@($v)[0]),$(@($v)[1])"]=1 }
    $tb=[Text.StringBuilder]::new()
    [void]$tb.Append("<table class='tcetvel'><tr>")
    foreach($b in @($ik.tablo.basliklar)){ [void]$tb.Append("<th>$(K $b)</th>") }
    [void]$tb.Append('</tr>')
    $rq=0
    foreach($st in @($ik.tablo.satirlar)){
      $rq++
      [void]$tb.Append('<tr>')
      $cq=0
      foreach($hc in @($st)){
        $kkey="$($rq-1),$cq"
        if($cq -eq 0){ [void]$tb.Append("<td style='font-weight:600'>$(K $hc)</td>") }
        elseif($ikBosK.ContainsKey($kkey)){ [void]$tb.Append("<td><input class='ikx' data-dogru='$(K $hc)' placeholder='?'></td>") }
        elseif($ikVerK.ContainsKey($kkey)){ [void]$tb.Append("<td class='verilen'>$(K $hc)</td>") }
        else{ [void]$tb.Append("<td>$(K $hc)</td>") }
        $cq++
      }
      [void]$tb.Append('</tr>')
    }
    [void]$tb.Append('</table>')
    [void]$sb.Append("<div style='margin-top:12px'><button class='dgm2 ikizAcB'>✍️ Şimdi sen dene — aynı yöntemi yeni rakamlarla</button><div class='ikizB'><p style='font-weight:600'>$(K $ik.ikiz_soru)</p><p style='color:#7fc98f;font-size:.88em'>🎯 $(K $ik.hedef_cumle) — 🔷 maviler soruda verildi; boşları SEN doldur.</p>$($tb.ToString())<button class='dgm2 ikKontrol'>Kontrol et</button><button class='dgm2 ipAl' style='background:#78b4ff'>💡 Takıldım — ipucu (1/3)</button><button class='dgm2 ikGoster' style='background:#5a5648;color:#e8e6e3'>Doğruları göster</button><span class='ikSkor' style='margin-left:8px;font-weight:800'></span><div class='ipP'><span style='font-weight:800;color:#78b4ff;font-size:.8em' class='ipB'></span><div class='ipM' style='margin-top:4px'></div><div class='ipf' style='display:none'></div></div></div></div>")
    # ipucu verisi: formul zinciri adimlardan
    $genel=New-Object System.Collections.Generic.List[string]
    foreach($aa in @($cvp.adimlar)){
      $ilkS=@("$($aa.formul)" -split "`n")[0].Trim()
      if($ilkS -and $ilkS -notmatch '^Verilenler' -and $ilkS -match '='){
        $gnl=($ilkS -split '=')[0].Trim()+' = '+(($ilkS -split '=')[1]).Trim()
        if($gnl -notmatch '\d{2}' -and -not $genel.Contains($gnl)){ [void]$genel.Add($gnl) }
      }
    }
    $ilkBos=$null; foreach($v in @($ik.bosluk)){ $ilkBos=$v; break }
    $ilkDeger=''; if($ilkBos){ $ilkDeger="$(@(@($ik.tablo.satirlar)[@($ilkBos)[0]])[@($ilkBos)[1]])" }
    $ikmap[$id]=@(
      @{ b='💡 İPUCU 1/3 — Formül zinciri'; m='Cevabı söylemiyorum — yolu gösteriyorum:'; f=(($genel | ForEach-Object -Begin{$q=0} -Process{ $q++; "$q) $_" }) -join "`n") },
      @{ b='💡 İPUCU 2/3 — Soru sana ne verdi?'; m='Mavi kenarlı hücreler sorunun verdikleri. Önce onları formül zincirine yerleştir.' },
      @{ b='💡 İPUCU 3/3 — İlk adımı beraber yapalım'; m=('İlk boş hücreyi doldurdum: {0}. Kalanı aynı yöntemle SEN.' -f $ilkDeger); doldur=$ilkDeger }
    )
  }
  if($cvp.sinav_taktigi){ [void]$sb.Append("<div class='kutu'>🎯 <b>Sınav taktiği:</b> $(K $cvp.sinav_taktigi)</div>") }
  if($cvp.notlandirici){ [void]$sb.Append("<div class='kutu2'>⚖️ <b>Notlandırıcı gözü:</b> $(K $cvp.notlandirici)</div>") }
  if($cvp.hap){ [void]$sb.Append("<div class='kutu2'><b>HAP:</b> $(K $cvp.hap)</div>") }
  [void]$sb.Append("</div></div></div>")
  if($adVar){ $amap[$id]=@($cvp.adimlar) }
  if($cvp.PSObject.Properties['verilen'] -and $cvp.verilen -and $cvp.cozum_tablo){
    $vb=[Text.StringBuilder]::new()
    [void]$vb.Append("<div style='font-weight:800;font-size:.8em;margin-bottom:4px'>📋 SORUNUN VERDİKLERİ</div><table class='vtab'><tr><th>Kalem</th><th>Alan</th><th>Değer</th></tr>")
    $ok=$true
    foreach($vv in @($cvp.verilen)){
      $r=@($vv)[0]; $c=@($vv)[1]
      $sat=@(@($cvp.cozum_tablo.satirlar)[$r])
      if($null -eq $sat -or $c -ge @($sat).Count){ $ok=$false; break }
      [void]$vb.Append("<tr><td>$(K $sat[0])</td><td>$(K @($cvp.cozum_tablo.basliklar)[$c])</td><td>$(K $sat[$c])</td></tr>")
    }
    [void]$vb.Append('</table>')
    if($ok){ $vmap[$id]=$vb.ToString() }
  }
}
$amapJson='{}'; if($amap.Count){ $amapJson=ConvertTo-Json -InputObject $amap -Depth 7 -Compress }
$vmapJson='{}'; if($vmap.Count){ $vmapJson=ConvertTo-Json -InputObject $vmap -Depth 3 -Compress }
$tzJson=ConvertTo-Json -InputObject $tzmap -Depth 3 -Compress
$ikJson='{}'; if($ikmap.Count){ $ikJson=ConvertTo-Json -InputObject $ikmap -Depth 4 -Compress }
[void]$sb.Append(@"
<script>
const ADIMMAP=$amapJson; const VTMAP=$vmapJson; const TUZAKMAP=$tzJson; const IPUCUMAP=$ikJson;
document.querySelectorAll('.soru').forEach(soru=>{
  const sid=soru.dataset.sid, DOGRU=soru.dataset.dogru, TZ=TUZAKMAP[sid]||{};
  // SIK -> tuzak + aciklama
  soru.querySelectorAll('.sikbtn').forEach(b=>{ b.addEventListener('click',()=>{
    soru.querySelectorAll('.sikbtn').forEach(x=>{ x.disabled=true; if(x.dataset.h===DOGRU)x.classList.add('dg'); });
    if(b.dataset.h!==DOGRU){ b.classList.add('yn');
      const tk=soru.querySelector('.tzk');
      if(TZ[b.dataset.h]){ tk.innerHTML='🪤 <b>Düştüğün tuzağın adı:</b> '+TZ[b.dataset.h]+' — aşağıda nasıl çalıştığını göreceksin.'; tk.style.display='block'; } }
    soru.querySelector('.acik').style.display='block';
  });});
  // OYNATICI
  const adimlar=ADIMMAP[sid], btn=soru.querySelector('.padim:not(.pileri)');
  if(adimlar&&btn){
    const pan=soru.querySelector('.panlat'), say=soru.querySelector('.psayac'), met=soru.querySelector('.pmetin'), frm=soru.querySelector('.pformul'), ile=soru.querySelector('.pileri');
    const hcs=()=>soru.querySelectorAll('.hcell');
    const hc=(r,c)=>soru.querySelector(".hcell[data-r='"+r+"'][data-c='"+c+"']");
    let ad=-1;
    const g=()=>{ const s=adimlar[ad];
      say.textContent='ADIM '+(ad+1)+' / '+adimlar.length; met.textContent=s.anlatim;
      if(ad===0&&VTMAP[sid]){ frm.innerHTML=VTMAP[sid]; } else { frm.textContent=s.formul||''; }
      (s.doldur||[]).forEach(k=>{const el=hc(k[0],k[1]); if(el){el.classList.remove('gizli'); el.classList.add('parla'); setTimeout(()=>el.classList.remove('parla'),950);}});
      if(ad===adimlar.length-1){ hcs().forEach(el=>el.classList.remove('gizli')); }
      ile.textContent=(ad===adimlar.length-1)?'🔄 Baştan':'İleri →'; };
    btn.addEventListener('click',()=>{ hcs().forEach(el=>el.classList.add('gizli')); btn.style.display='none'; pan.style.display='block'; ad=0; g(); });
    ile.addEventListener('click',()=>{ if(ad===adimlar.length-1){ hcs().forEach(el=>el.classList.add('gizli')); ad=0; g(); return; } ad++; g(); });
  }
  // IKIZ + IPUCU
  const ikA=soru.querySelector('.ikizAcB');
  if(ikA){
    const norm=t=>String(t||'').toLowerCase().replace(/tl|kg|%/g,'').replace(/[.\s]/g,'').replace(',','.').trim();
    ikA.addEventListener('click',()=>{ ikA.style.display='none'; soru.querySelector('.ikizB').style.display='block'; });
    soru.querySelector('.ikKontrol').addEventListener('click',()=>{
      let d=0,t=0;
      soru.querySelectorAll('.ikx').forEach(i=>{ t++; const ok=norm(i.value)===norm(i.dataset.dogru); i.classList.remove('dog','yan'); i.classList.add(ok?'dog':'yan'); if(ok)d++; });
      const sk=soru.querySelector('.ikSkor'); sk.textContent=d+'/'+t+(d===t?' 🎉 Yöntem senin!':''); sk.style.color=(d===t)?'#7fc98f':'#c9a227';
    });
    soru.querySelector('.ikGoster').addEventListener('click',()=>{ soru.querySelectorAll('.ikx').forEach(i=>{ i.value=i.dataset.dogru; i.classList.remove('yan'); i.classList.add('dog'); }); });
    const IP=IPUCUMAP[sid]||null, ipBtn=soru.querySelector('.ipAl');
    if(IP&&ipBtn){ let n=0;
      ipBtn.addEventListener('click',()=>{ if(n>=IP.length) return; const ip=IP[n];
        soru.querySelector('.ipB').textContent=ip.b; soru.querySelector('.ipM').textContent=ip.m;
        const f=soru.querySelector('.ipf'); f.textContent=ip.f||''; f.style.display=ip.f?'block':'none';
        if(n===1){ soru.querySelectorAll('.ikizB td.verilen').forEach(td=>{ td.classList.remove('parla'); void td.offsetWidth; td.classList.add('parla'); }); }
        if(ip.doldur){ const ilk=soru.querySelector('.ikizB .ikx'); if(ilk&&!ilk.value){ ilk.value=ip.doldur; ilk.classList.add('dog'); } }
        soru.querySelector('.ipP').style.display='block'; n++;
        ipBtn.textContent=(n>=IP.length)?'💡 İpucu bitti — kalanı sende!':'💡 Takıldım — ipucu ('+(n+1)+'/3)';
        if(n>=IP.length){ ipBtn.style.opacity='.55'; } }); }
    else if(ipBtn){ ipBtn.style.display='none'; }
  }
});
</script>
"@)
[void]$sb.Append("</body></html>")
[IO.File]::WriteAllText($HEDEF,$sb.ToString(),[Text.UTF8Encoding]::new($false))
"yazildi: kalip-parti-$Etiket.html | soru: $adet | ikiz: $($ikmap.Count) | kaynak-borcu: $($kaynakBorcu.Count) | aritmetik uyari: $($aritUyari.Count)"
