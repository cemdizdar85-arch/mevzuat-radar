# ============================================================================
#  ALTIN 10 — SIFIRDAN KUSURSUZ SORU  (25.08.2026)
#
#  CEM: "bana 10 örnek soru yap, her şeyi kontrol ettiğimiz sorular; cevaplar
#        nasıl cevap veriyoruz, konuyu nasıl öğretiyoruz; ondan sonra ilerleyelim"
#
#  NEDEN SIFIRDAN, ONARIM DEGIL: 25.08 olcumu (20 soru, 26 kapi) sunu gosterdi -
#  "iki bagimsiz kanitli" havuzda bile %30 OLDURUCU, %60 ONARILIR kusur var.
#  Yani zaten neredeyse hepsi yeniden yazilacak. Onarim, yeniden yazmaktan pahali.
#
#  URET -> KAPIDAN GECIR -> DUSENI KAPININ SOYLEDIGI KUSURLA GERI GONDER -> TEKRAR
#  Bu dongu, "uret sonra ele" yonteminden farklidir: model kendi kusurunu
#  ISMIYLE gorur ve onu duzeltir. En fazla 3 tur; 3 turde temizlenmeyen soru
#  ATILIR (zorlamayla gecirilmez - esik gevsetmek kaliteyi olduren seydir).
#
#  PARTI TASARIMI (Katman 5'i SAGLAMAK icin bilerek kurulmustur):
#    - 3 soru OLUMSUZ KOK  ("hangisi yanlistir")  -> %30, sinavda %17-30
#    - 1 soru COK CIKTILI  ("sirasiyla")          -> %10, sinavda %6,7
#    - Dogru siklar A,B,C,D,E ikiser kez          -> cevap anahtari kusursuz dengeli
#    - Her soru en az 5 veri noktasi              -> sinavda 5,63
#  Boylece 10 soru hem TEK TEK kusursuz hem PARTI olarak sinava benzer.
#
#  CIKTI: veri/fabrika/altin-10.json  (kapi hatti bu dosyayi -yerelDosya ile okur)
#         + veri/fabrika/ALTIN-10.md  (okunacak dosya)
# ============================================================================
param(
  [string]$model = 'claude-sonnet-5',
  [int]$tur = 3,                  # azami onarim turu
  [switch]$olcum                  # PARA HARCAMAZ: yalniz plani goster
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
if(-not $env:SUPABASE_SERVICE_KEY){ Write-Host 'SUPABASE_SERVICE_KEY yok.'; exit 1 }
. (Join-Path $here 'madde-coz.ps1') -kutuphane

Add-Type -AssemblyName System.Net.Http
$hc = New-Object System.Net.Http.HttpClient
$hc.Timeout = [TimeSpan]::FromSeconds(600)

# ---------------------------------------------------------------- PARTI PLANI
# Kaynaklar BILEREK secildi: hepsi ambarda cozulen, konusu net maddeler.
# 'kalip' Katman 5'i saglar; 'dogru' cevap anahtarini dengeler.
$PLAN = @(
  [ordered]@{ no=1;  sinav='SGS';  ders='Finansal Muhasebe';                konu='imal edilen emtiada maliyet bedeli'; kaynak='VUK (213 s.K.) m.275'; kalip='hesap';    dogru='A' }
  [ordered]@{ no=2;  sinav='SGS';  ders='Hukuk';                            konu='zincirleme belirli sureli sozlesme';  kaynak='İş K. (4857 s.K.) m.11'; kalip='olumsuz'; dogru='B' }
  [ordered]@{ no=3;  sinav='SMMM'; ders='Muh. ve Mali Müş. Meslek Hukuku';  konu='haksiz rekabet halleri';              kaynak='TTK (6102 s.K.) m.55';  kalip='normal';  dogru='C' }
  [ordered]@{ no=4;  sinav='SGS';  ders='Ticaret Hukuku';                   konu='tacir sifatinin kazanilmasi';         kaynak='TTK (6102 s.K.) m.12';  kalip='normal';  dogru='D' }
  [ordered]@{ no=5;  sinav='SGS';  ders='Finansal Muhasebe';                konu='iktisadi kiymette maliyet bedeli';    kaynak='VUK (213 s.K.) m.262';  kalip='hesap';    dogru='E' }
  [ordered]@{ no=6;  sinav='SGS';  ders='Maliyet Muhasebesi';               konu='mamul maliyetinin unsurlari';         kaynak='VUK (213 s.K.) m.275';  kalip='sirasiyla'; dogru='A' }
  [ordered]@{ no=7;  sinav='SMMM'; ders='Hukuk';                            konu='belirli sureli sozlesmede objektif kosul'; kaynak='İş K. (4857 s.K.) m.11'; kalip='normal'; dogru='B' }
  [ordered]@{ no=8;  sinav='SMMM'; ders='Muh. ve Mali Müş. Meslek Hukuku';  konu='haksiz rekabette kotuleme';           kaynak='TTK (6102 s.K.) m.55';  kalip='olumsuz'; dogru='C' }
  [ordered]@{ no=9;  sinav='SGS';  ders='Ticaret Hukuku';                   konu='tacir olmanin sonuclari';             kaynak='TTK (6102 s.K.) m.12';  kalip='olumsuz'; dogru='D' }
  [ordered]@{ no=10; sinav='SGS';  ders='Finansal Muhasebe';                konu='maliyet bedeline giren giderler';     kaynak='VUK (213 s.K.) m.262';  kalip='hesap';    dogru='E' }
)

Write-Host '======== PARTI PLANI ========'
foreach($p in $PLAN){ Write-Host ("  {0,2}. {1,-34} {2,-10} dogru={3}  [{4}]" -f $p.no,$p.konu,$p.kalip,$p.dogru,$p.kaynak) }
$kalipSay = @{}; foreach($p in $PLAN){ $k=$p.kalip; if($kalipSay.ContainsKey($k)){$kalipSay[$k]++}else{$kalipSay[$k]=1} }
Write-Host ''
Write-Host ("  olumsuz kok : {0}/10 (%{1})   sinav %17-30" -f $kalipSay['olumsuz'],(10*$kalipSay['olumsuz']))
Write-Host ("  cok ciktili : {0}/10 (%{1})   sinav %6,7" -f $kalipSay['sirasiyla'],(10*$kalipSay['sirasiyla']))
Write-Host ("  cevap anahtari: " + ((($PLAN | Group-Object { $_.dogru } | Sort-Object Name) | ForEach-Object { "$($_.Name)=$($_.Count)" }) -join ' '))

# --- kaynaklari COZ (metin yoksa soru YAZILMAZ)
Write-Host ''
Write-Host 'Kaynaklar cozuluyor...'
$metinler = @{}
foreach($p in $PLAN){
  if($metinler.ContainsKey($p.kaynak)){ continue }
  $c = KaynakCoz $p.kaynak $p.konu
  if($c.durum -notlike 'cozuldu*'){ Write-Host ("  !! {0} -> {1}" -f $p.kaynak,$c.durum); continue }
  $metinler[$p.kaynak] = "$($c.metin)"
  Write-Host ("  {0,-32} -> {1} ({2} karakter)" -f $p.kaynak,$c.durum,"$($c.metin)".Length)
}
$eksik = @($PLAN | Where-Object { -not $metinler.ContainsKey($_.kaynak) })
if($eksik.Count){ Write-Host ''; Write-Host ("UYARI: {0} sorunun kaynagi cozulemedi - o sorular YAZILMAYACAK." -f $eksik.Count) }

# --- KONU KARTLARI. Soru kartin turevidir; kart yoksa soru KARTSIZ yazilir ve
#     bu bir kusurdur (urunun "konu ogretme" vaadini tasiyan sey karttir).
$KARTLAR = @()
$kartYol = Join-Path $kok 'veri/fabrika/konu-kartlari.json'
if(Test-Path $kartYol){
  $KARTLAR = @((Get-Content $kartYol -Raw -Encoding UTF8 | ConvertFrom-Json) | ForEach-Object {
    $_ | Add-Member -NotePropertyName kaynaklar_kume -NotePropertyValue (@($_.dayanaklar)) -Force -PassThru })
  Write-Host ''
  Write-Host ("Konu karti: {0} kart yuklendi" -f $KARTLAR.Count)
  foreach($p in $PLAN){
    $eslesen = @($KARTLAR | Where-Object { $_.kaynaklar_kume -contains $p.kaynak })
    if(-not $eslesen.Count){ Write-Host ("  !! KARTSIZ: {0} / {1}  [{2}]" -f $p.ders,$p.konu,$p.kaynak) }
  }
} else {
  Write-Host ''
  Write-Host 'UYARI: konu karti dosyasi YOK - sorular KARTSIZ yazilacak (motor\konu-karti.ps1 kosulmali).'
}

if($olcum){ Write-Host ''; Write-Host 'OLCUM MODU - hicbir istek atilmadi, 0 USD.'; exit 0 }
if(-not $env:ANTHROPIC_API_KEY){ Write-Host 'ANTHROPIC_API_KEY yok.'; exit 1 }

# ---------------------------------------------------------------- SOZLESME
function Nesne($g,$o){ @{ type='object'; additionalProperties=$false; required=$g; properties=$o } }
$Str=@{type='string'}
$sikNesne = Nesne @('A','B','C','D','E') ([ordered]@{ A=$Str;B=$Str;C=$Str;D=$Str;E=$Str })
$soruSema = Nesne @('soru','siklar','dogru','aciklama','hap','tablo_baslik','tablo_kolonlar','tablo_satirlar') ([ordered]@{
  soru     = $Str
  siklar   = $sikNesne
  dogru    = @{ type='string'; enum=@('A','B','C','D','E') }
  aciklama = $sikNesne
  hap      = $Str
  tablo_baslik   = $Str
  tablo_kolonlar = @{ type='array'; items=$Str }
  tablo_satirlar = @{ type='array'; items=@{ type='array'; items=$Str } }
})

$KURALLAR = @'
Bir muhasebe meslek sınavı (SGS/SMMM) için TEK BİR SORU yazacaksın.
Bu soru 27 kapıdan geçecek. Kapıya takılırsan sana kusurun ADIYLA geri gelecek.

PAZARLIKSIZ — DOĞRULUK
1. YALNIZ sana verilen MADDE METNİNE dayan. Metinde olmayan kural yazma.
2. FIKRA/BENT NUMARASI: yalnız madde metninde numaralandırma GÖRÜYORSAN yaz.
   Görmüyorsan sadece "m.11" yaz, "m.11/2" YAZMA. (Ölçüldü: model burada uyduruyor.)
3. HESAP SORUSUYSA: doğru şıkkın değeri, soru kökündeki kalemlerden ÇIKAN
   sonucun BİREBİR kendisi olacak. Yuvarlama yapma, kuruşu tutsun.
   (Ölçüldü: kasada 160.300/180 = 890,56 iken doğru şık 888,50 yazılmış; hiçbir
   şık doğru değildi. Bu soru yayına girseydi öğrenciye yanlış öğretecekti.)
4. HER YANLIŞ ŞIK GERÇEK BİR HATA YOLUNDAN ÇIKACAK: atlanan kalem, ters bölme,
   yanlış oran. Hiçbir hesaptan çıkmayan rakam çeldirici değil, gürültüdür.

PAZARLIKSIZ — ÖĞRETME
Bu ürünün vaadi şudur: aday KONU OKUMADAN, yalnız soru çözerek öğrenecek.
Onun için açıklama "cevabı gerekçelendirme" değil, DERSİN KENDİSİDİR.

5. DOĞRU şıkkın açıklaması TAM OLARAK bu dört başlıkla, bu sırayla:
   "Ne soruluyor:" / "Kural:" / "Bu olayda:" / "Akılda kalsın:"

6. HER YANLIŞ ŞIKKIN açıklaması da DÖRT PARÇALI olacak, tam bu başlıklarla:
   "Tuzak:"                        hangi iki kavram karıştırılıyor — adıyla
   "Nereden geliyor:"              bu şık neden mantıklı görünüyor. Çoğu zaman
                                   BAŞKA BİR YERDE DOĞRU olan bir kuraldır; orayı söyle
   "Kırılma noktası:"              kaynaktaki tam ifade — hangi kelime bu şıkkı öldürüyor
   "Bu şık ne zaman doğru olurdu:" karşı olgu. Şık hangi şartta doğru olurdu
   Son parçayı yazamıyorsan o şık gerçek bir hata yolundan türetilmemiştir;
   şıkkı DEĞİŞTİR. Türetilemeyen rakam/iddia çeldirici değil gürültüdür.

7. DÖRT YANLIŞ ŞIK AYNI CÜMLE İSKELETİYLE KURULAMAZ.
   Şu kalıp YASAK: "X şıkkı … iddia ediyor; oysa … bu yüzden X yanlıştır."
   Bu kalıp öğretmez, kuralı tekrar edip şıkkı reddeder — aday o kuralı zaten
   doğru şıkta okumuştur. Dördü dört ayrı biçimde kurulacak.

8. TERİM AÇIKLANMADAN KULLANILMAZ. "Kural" bölümünde geçen her meslek terimi,
   ilk geçtiğinde tek cümleyle ve ÖRNEKLE açıklanır; parantez, kısa çizgi ya da
   "yani" ile verilir, ayrı paragraf açılmaz.
   Kötü:  "…genel imal giderinden pay ile genel idare giderinden pay…"
   İyi:   "…genel imal giderinden pay — yani üretimin içinde olan ama tek bir
          mamule doğrudan yazılamayan giderler: fabrika kirası, makine
          amortismanı, ustabaşı ücreti — …; genel idare gideri ise üretimle
          değil şirketin yönetimiyle ilgili giderdir: genel müdürlük maaşları,
          muhasebe servisi, merkez ofis kirası."
   Birbirine benzeyen terimler (genel imal / genel idare) sınavın en sık
   tuzağıdır; açıklanmazsa tuzak GÖRÜNMEZ kalır.

9. HAP KARTI en çok 180 karakter. Uzunsa hap değil özet olur.

PAZARLIKSIZ — DİL
10. Temiz Türkçe. ASCII'leşmiş yazım YOK ("uretmistir" değil "üretmiştir").
11. Kanun cümlesi kopyalanmaz; hiç bilmeyen biri anlayacak şekilde yaz.
12. YASAK KALIPLAR: "bu bağlamda", "önemli bir husus", "unutulmamalıdır ki",
    "sonuç olarak", "özetle,", "dikkat edilmesi gereken". Şık açıklamaları
    AYNI CÜMLE İSKELETİYLE başlamayacak — dördü dört ayrı biçimde kurulacak.
13. Senaryo gerçek hayattan çıkmış dursun: yuvarlak olmayan rakamlar, sıradan
    şehir/şirket adları, 2025-2026 tarihleri. Aynı şehri/adı tekrar kullanma.

TABLO
Soru hesaplıysa kalemleri TABLO olarak ver (tablo_baslik/kolonlar/satirlar).
Değilse üçünü de boş bırak ("" ve []). Tablodaki her sayı soru metniyle TUTACAK.
'@

$KALIP_METNI = @{
  'normal'    = 'KALIP: düz soru — "aşağıdakilerden hangisi DOĞRUDUR" tipi.'
  'olumsuz'   = 'KALIP: OLUMSUZ KÖK — "aşağıdakilerden hangisi YANLIŞTIR / hangisi ... DEĞİLDİR". Dört şık doğru, biri yanlış olacak; doğru cevap YANLIŞ OLAN şıktır. (Gerçek sınavın %17-30''u bu kalıpta, bizde %0.)'
  'hesap'     = 'KALIP: HESAPLI — en az 5 veri noktası (kalem) ver, çok adımlı olsun. Doğru şık hesabın birebir sonucu.'
  'sirasiyla' = 'KALIP: ÇOK ÇIKTILI — "sırasıyla" tipi: iki büyüklük birden sorulacak (örn. toplam maliyet ve birim maliyet), şıklar "X TL – Y TL" biçiminde olacak. (Gerçek sınavın %6,7''si bu kalıpta, bizde %0,4.)'
}

$AY = 'https://api.anthropic.com/v1/messages'
function ModelCagir([string]$istem, $sema){
  $govde = @{ model=$model; max_tokens=20000; messages=@(@{ role='user'; content=$istem })
              output_config=@{ effort='medium'; format=@{ type='json_schema'; schema=$sema } } } | ConvertTo-Json -Depth 16
  # 25.08 OLCULDU: 10 istegin 1'i "Canli tutulacagi beklenen bir baglanti sunucu
  # tarafindan kapatildi" ile dustu (SocketException). Sistematik degil, keep-alive
  # kopmasi. Tek denemeyle calisan bir hat, 300 soruluk kosuda 30 soru kaybeder.
  # Her istek icin YENI HttpRequestMessage sart - ayni nesne iki kez gonderilemez.
  $yn = $null
  for($d=1; $d -le 3; $d++){
    $ic = New-Object System.Net.Http.StringContent($govde,[Text.Encoding]::UTF8,'application/json')
    $ist = New-Object System.Net.Http.HttpRequestMessage('POST',$AY); $ist.Content=$ic
    $ist.Headers.Add('x-api-key',$env:ANTHROPIC_API_KEY); $ist.Headers.Add('anthropic-version','2023-06-01')
    $ist.Headers.ConnectionClose = $true    # keep-alive kopmasini bastan onle
    try { $yn = $script:hc.SendAsync($ist).GetAwaiter().GetResult(); break }
    catch {
      $zincir = @(); $e = $_.Exception
      while($e){ $zincir += ("{0}: {1}" -f $e.GetType().Name, $e.Message); $e = $e.InnerException }
      if($d -eq 3){ return @{ hata = ("TASIMA (3 deneme) -> " + ($zincir -join '  |  ')) } }
      Write-Host ("   tasima hatasi, {0}. deneme yeniden..." -f ($d+1))
      Start-Sleep -Seconds (2*$d)
    }
  }
  $ham = [Text.Encoding]::UTF8.GetString($yn.Content.ReadAsByteArrayAsync().GetAwaiter().GetResult())
  if(-not $yn.IsSuccessStatusCode){ return @{ hata = $ham.Substring(0,[Math]::Min(300,$ham.Length)) } }
  $cv = $ham | ConvertFrom-Json
  $script:jetonG += [int]$cv.usage.input_tokens; $script:jetonC += [int]$cv.usage.output_tokens
  $mb = ($cv.content | Where-Object { $_.type -eq 'text' } | Select-Object -First 1).text
  if(-not $mb){ return @{ hata = "metin blogu yok - stop_reason=$($cv.stop_reason)" } }
  try { return @{ veri = ($mb | ConvertFrom-Json) } } catch { return @{ hata = 'JSON ayristirilamadi' } }
}

$script:jetonG = 0; $script:jetonC = 0
$uretilen = New-Object System.Collections.Generic.List[object]
$cikti = Join-Path $kok 'veri/fabrika/altin-10.json'
$null = New-Item -ItemType Directory -Force (Split-Path $cikti)

# 25.08 DERSI (aci veren): ilk kosuda 8 soru URETILDI, sonra JSON yazimi coktu
# ve SEKIZI DE KAYBOLDU - para harcandi, is ucup gitti. Bkz [[yukleyici-sessiz-kayip]].
# Artik HER SORU URETILIR URETILMEZ diske yazilir; kosu ortasinda cokse bile
# o ana kadarki is durur. Ayrica PS 5.1'de [ordered] icinde $null + ic ice
# PSCustomObject ConvertTo-Json'i "Bagimsiz degisken turleri eslesmiyor" ile
# dusuruyor - kayitlar once [pscustomobject]'e cevrilir.
function KaydetHemen($liste, [string]$yol){
  $duz = @()
  foreach($r in $liste){ $duz += ,([pscustomobject]$r) }
  try { [IO.File]::WriteAllText($yol, (ConvertTo-Json -InputObject $duz -Depth 12), (New-Object Text.UTF8Encoding($false))); return $true }
  catch { Write-Host ("   !! KAYIT HATASI: {0}" -f $_.Exception.Message); return $false }
}
foreach($p in $PLAN){
  if(-not $metinler.ContainsKey($p.kaynak)){ continue }
  Write-Host ''
  Write-Host ("=== {0,2}. {1} / {2}  [{3}]" -f $p.no,$p.ders,$p.konu,$p.kalip)
  # 25.08: KART ONCE, SORU SONRA. Cem: "TTK anlatacaksin, taciri anlatacaksin,
  # ilk once onu anlat". Kart kaynak, soru turevdir - soru kartin bir dalini
  # olcer ve o dala ATIF YAPAR. Kartsiz yazilan soru kartla uyumsuz cikiyordu
  # (ALTIN-09 m.12/3'e dokunuyor ama "tacir sayilir / tacir gibi sorumlu olur"
  #  ayrimini hic bilmiyordu - oysa kartin tuzak alaninda yaziyor).
  $kartBlok = ''
  $kart = $KARTLAR | Where-Object { $_.kaynaklar_kume -contains $p.kaynak } | Select-Object -First 1
  if($kart){
    $kartBlok = "`n`n=== KONU KARTI (aday bu karti SORUDAN ONCE okudu) ===`n"
    $kartBlok += "BASLIK: $($kart.baslik)`n"
    $kartBlok += "ZEMIN — $($kart.zemin.baslik): $($kart.zemin.metin)`n"
    if($kart.karisir -and "$($kart.karisir.komsu)".Trim()){
      $kartBlok += "KARISIR — $($kart.karisir.komsu):`n"
      foreach($o in @($kart.karisir.olcutler)){ $kartBlok += "   · $($o.olcut): [$($kart.karisir.komsu)] $($o.komsu)  |  [konu] $($o.konu)`n" }
    }
    $kartBlok += "DALLAR:`n"
    foreach($d in @($kart.dallar)){
      $kartBlok += "   · $($d.ad) ($($d.madde)): $($d.metin)`n"
      if("$($d.tuzak)".Trim()){ $kartBlok += "     TUZAK: $($d.tuzak)`n" }
    }
    if(@($kart.sonuclar).Count){
      $kartBlok += "SONUCLAR:`n"
      foreach($s2 in @($kart.sonuclar)){ $kartBlok += "   · $($s2.metin) ($($s2.madde))`n" }
    }
    $kartBlok += "AKILDA KALSIN: $($kart.akilda_kalsin)`n"
    $kartBlok += @'

KARTI NASIL KULLANACAKSIN:
- Soru, kartın BİR DALINI ölçer. Hangi dalı ölçtüğünü açıklamada söyle.
- Kartta "TUZAK" yazan bir incelik varsa, soruyu MÜMKÜNSE tam oraya kur —
  sınav o inceliklerden sorar.
- Açıklamada kartın terimlerini kullan; kartta olmayan yeni terim getirme.
- Kart adayın zaten okuduğu metindir: kartı olduğu gibi TEKRAR ETME,
  onu KULLANARAK bu olayı çöz.
'@
  }

  $istem = $KURALLAR + "`n`n" + $KALIP_METNI[$p.kalip] +
    "`nDOGRU SIK: `"$($p.dogru)`" olacak (cevap anahtari dengesi icin ZORUNLU)." +
    "`n`nDERS: $($p.ders)`nKONU: $($p.konu)`nDAYANAK: $($p.kaynak)" +
    $kartBlok +
    "`n`n=== MADDE METNI (dayanak) ===`n$($metinler[$p.kaynak])"
  $c = ModelCagir $istem $soruSema
  if($c.hata){ Write-Host ("   HATA: {0}" -f $c.hata); continue }
  $v = $c.veri
  $uretilen.Add([ordered]@{
    id = "ALTIN-$('{0:D2}' -f $p.no)"; sinav=$p.sinav; ders=$p.ders; konu=$p.konu
    soru="$($v.soru)"; siklar=$v.siklar; dogru="$($v.dogru)"; aciklama=$v.aciklama; hap="$($v.hap)"
    tablo = $(if("$($v.tablo_baslik)".Trim()){ [ordered]@{ baslik="$($v.tablo_baslik)"; kolonlar=@($v.tablo_kolonlar); satirlar=@($v.tablo_satirlar) } } else { $null })
    kaynak=$p.kaynak; kanun_no=''; madde_no=''; zorluk=$null; kalip=$p.kalip; tur=1
  })
  $k = KaydetHemen $uretilen $cikti
  Write-Host ("   yazildi - dogru sik: {0} (istenen {1}){2}" -f $v.dogru,$p.dogru,$(if($k){" · diske kaydedildi ($($uretilen.Count))"}else{" · KAYDEDILEMEDI"}))
}

[void](KaydetHemen $uretilen $cikti)

$TANITIM = [datetime]'2026-08-31'
if((Get-Date) -le $TANITIM -and $model -like 'claude-sonnet-5*'){ $fg=2.0;$fc=10.0 } else { $fg=3.0;$fc=15.0 }
$usd = ($script:jetonG/1e6*$fg) + ($script:jetonC/1e6*$fc)
Write-Host ''
Write-Host ("URETILDI: {0}/10   FATURA: {1:N4} USD  (giris {2:N0} + cikis {3:N0})" -f $uretilen.Count,$usd,$script:jetonG,$script:jetonC)
Write-Host ("-> {0}" -f $cikti)
Write-Host ''
Write-Host 'SIRADAKI ADIM — 27 kapidan gecir:'
Write-Host ("  motor\tam-kontrol.ps1 -yerelDosya `"{0}`"" -f $cikti)
