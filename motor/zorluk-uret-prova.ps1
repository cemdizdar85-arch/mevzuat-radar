# ============================================================================
#  ZORLUK URETIM PROVASI - 20 SORU (26.08.2026 gece, Cem: "farkli tipte 20 uret bakalim")
#
#  Zorluk kiyasi v2 + kor hakem bulgularindan turetilen TIP KARISIMI:
#    6 sasirtmali kok · 4 onculu (I-II-III) · 4 vaka-temelli hukuk Z3 ·
#    4 muhteva hedefi (hesapli) · 2 "secici" (5-puan denemesi)
#  Istem: ALTIN-STANDART 18 madde ozeti + cila v3 aciklama takimi.
#  Dayanak: ambardan CANLI cekilir (kaynaksiz uretim yok).
#  Cikti: KASAYA YAZILMAZ - veri/fabrika/zorluk-prova-*.jsonl -> Cem inceleme dosyasi.
# ============================================================================
param([switch]$gonder, [switch]$durum, [switch]$indir,
      [switch]$direkt,   # 26.08 gece: batch kuyrugu tikandiginda ayni 20'yi dogrudan hat ile uret
      [switch]$onar,     # 27.08: kaynak_yetersiz/kesik donen satirlari GENIS kaynakla yeniden uret, yerine yaz
      [string]$yeniden='',   # 27.08: virgullu custom_id listesi - saglam olsa da ZORLA yeniden uret (kural degisikligi sonrasi)
      [string]$sinav='SGS')   # 27.08 Cem: uc sinav uc ayri 20'lik takim (SGS / SMMM / KGK)
$ErrorActionPreference='Stop'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$PSDefaultParameterValues['Invoke-RestMethod:UserAgent']='mevzuat-radar-robot/1.0'
$here=Split-Path -Parent $MyInvocation.MyCommand.Path
$kok=Split-Path -Parent $here
if(-not $env:SUPABASE_SERVICE_KEY){ $env:SUPABASE_SERVICE_KEY=[Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User') }
$KEY=$env:SUPABASE_SERVICE_KEY
$H=@{apikey=$KEY; Authorization="Bearer $KEY"}
$U='https://bjrleanjpyujtajmazxn.supabase.co/rest/v1'
$FAB=Join-Path $kok 'veri\fabrika'
$ANT='https://api.anthropic.com/v1/messages/batches'
function AntBas(){ $k=$env:ANTHROPIC_API_KEY; if(-not $k){ $k=[Environment]::GetEnvironmentVariable('ANTHROPIC_API_KEY','User') }; return @{ 'x-api-key'=$k; 'anthropic-version'='2023-06-01'; 'content-type'='application/json' } }
$IDLER=Join-Path $FAB 'zorluk-batch-idler.json'

# ---- 20'lik plan: tip | ders | konu | dayanak arama deseni (imatch, 3 alan) ----
# 5. kolon = kaynak_ad ON EKI (ilike '<onek>%'): arama YALNIZ o kaynagin
# kayitlarinda yapilir - 26.08 gece dersi: serbest metin aramasi TMS 36 isterken
# VUK tebligi getiriyordu, model hakli olarak 'kaynak_yetersiz' donuyordu.
$plan=@(
 @('sasirtmali','Muhasebe Standartlari','tms 36 deger dusuklugu gostergeleri','g[oö]sterge','TMS 36'),
 @('sasirtmali','Borclar Hukuku','genel islem kosullari','genel i[sş]lem','TBK'),
 @('sasirtmali','Is ve Sosyal Guvenlik Hukuku','yillik ucretli izin','y[iı]ll[iı]k [uü]cretli izin',''),
 @('sasirtmali','Meslek Hukuku','disiplin cezalari','disiplin',''),
 @('sasirtmali','Denetim','denetim kaniti guvenilirligi','g[uü]venilir','BDS 500'),
 @('sasirtmali','Ticaret Hukuku','tacir sifatinin sonuclari','tacir','TTK'),
 @('onculu','Denetim','ic kontrol bilesenleri','i[cç] kontrol','BDS 315'),
 @('onculu','Ticaret Hukuku','anonim sirketin organlari ve genel kurul devredilemez yetkileri','genel kurul','TTK'),
 @('onculu','Vergi Hukuku','vuk degerleme olculeri','de[gğ]erleme','VUK'),
 @('onculu','Kurumsal Yonetim','yonetim kurulu komiteleri','komite',''),
 @('vaka','Borclar Hukuku','sebepsiz zenginlesme sartlari ve iadenin kapsami (TBK m.79-80 geri verme kapsami - iyiniyetli zenginlesenin elinden cikan kisim - MUTLAKA hesaba katilacak; senaryo bu ayrimi test etsin)','zenginle[sş]','TBK'),
 @('vaka','Is ve Sosyal Guvenlik Hukuku','kidem tazminati hak kazanma ve hesap','k[iı]dem tazminat[iı]',''),
 @('vaka','Ticaret Hukuku','bononun zorunlu unsurlari ve eksikligin sonucu','bono','TTK'),
 @('vaka','Vergi Hukuku','uzlasma kapsami ve sonuclari','uzla[sş]ma','VUK'),
 @('hesapli','Muhasebe Standartlari','tms 36 geri kazanilabilir tutar hesabi','geri kazan[iı]labilir','TMS 36'),
 @('hesapli','Mali Tablolar Analizi','net isletme sermayesi hesabi','net i[sş]letme sermayesi',''),
 @('hesapli','Finansal Muhasebe','nakit akis tablosu isletme faaliyetleri','dolayl[iı]','TMS 7'),
 @('hesapli','Maliyet Muhasebesi','genel uretim gideri yukleme orani (normal maliyet yontemi)','genel [uü]retim','Teori'),
 @('secici','Finansal Muhasebe','amortisman + yenileme fonu + satis kaydi birlesik vaka','yenileme fonu','VUK'),
 @('secici','Denetim','onemlilik + ornekleme + gorus iliskisi','[oö]nemlilik','BDS 320')
)

# ---- YETERLILIK (staj bitirme) 20'lik takim (27.08) ----
$planSMMM=@(
 @('sasirtmali','Finansal Muhasebe','tms 2 stok maliyetine girmeyecek unsurlar','maliyet','TMS 2'),
 @('sasirtmali','Finansal Muhasebe','tfrs 15 hasilatin kaydedilme sartlari','has[iı]lat','TFRS 15'),
 @('sasirtmali','Vergi Mevzuati ve Uygulamasi','amortisman ayirma kurallari','amortisman','VUK'),
 @('sasirtmali','Meslek Hukuku','meslek etigi temel ilkeleri','etik ilke',''),
 @('sasirtmali','Vergi Mevzuati ve Uygulamasi','kdv indirim sartlari','indirim','KDV'),
 @('sasirtmali','Finansal Muhasebe','donem sonu reeskont islemleri','reeskont','VUK'),
 @('onculu','Finansal Tablolar ve Analizi','bilanco ilkeleri','bilan[cç]o','MSUGT'),
 @('onculu','Hukuk','ttk defter tutma ve saklama yukumlulukleri','defter','TTK'),
 @('onculu','Finansal Tablolar ve Analizi','oran analizi gruplari','oran analizi',''),
 @('onculu','Muhasebe Denetimi','denetim gorusu turleri ve sartlari','g[oö]r[uü][sş]','BDS 700'),
 @('vaka','Vergi Mevzuati ve Uygulamasi','supheli alacak karsiligi sartlari','[sş][uü]pheli alacak','VUK'),
 @('vaka','Maliyet Muhasebesi','safha maliyetinde donusturme maliyeti ve birim maliyet','d[oö]n[uü][sş]t[uü]rme','Teori'),
 @('vaka','Vergi Mevzuati ve Uygulamasi','fatura ve irsaliye duzenleme sureleri','fatura','VUK'),
 @('vaka','Meslek Hukuku','smmm sozlesmesi ve ucret tarifesi','[uü]cret','SMMM K'),
 @('hesapli','Finansal Muhasebe','fifo yontemiyle stok degerleme ve satis maliyeti (YALNIZ maliyet/kazanc hesabi - vergi TEVKIFATI/stopaj hesabi SORMA, oranlar donemseldir ve kaynakta yoktur)','ilk giren',''),
 @('hesapli','Vergi Mevzuati ve Uygulamasi','binek otomobilde kist amortisman hesabi','binek','VUK'),
 @('hesapli','Finansal Tablolar ve Analizi','cari oran ve asit-test hesabi','asit[- ]test',''),
 @('hesapli','Maliyet Muhasebesi','basabas noktasi hesabi','ba[sş]aba[sş]',''),
 @('secici','Finansal Muhasebe','donem sonu birlesik vaka: alacak/borc senedi reeskontu (238 no.lu VUK GT: ic iskonto + kisa vadeli avans orani) + degerleme olculeri','irca','VUK;VERGİ USUL KANUNU GENEL TEBLİĞİ (SIRA NO: 238)'),
 @('secici','Finansal Tablolar ve Analizi','tfrs 10 kontrol + konsolidasyon karari birlesik vaka','kontrol','TFRS 10')
)

# ---- KGK (bagimsiz denetim) 20'lik takim (27.08) - zorluk acigi en buyuk ayak ----
$planKGK=@(
 @('sasirtmali','Denetim','kys 1 kalite yonetim sistemi unsurlari (DIKKAT: ambarda KYS 1 kayitlarindaki p.N SAYFA numarasidir, paragraf DEGILDIR - aciklamada paragraf numarasi atfi YAPMA, bolum/kavram adiyla atif yap)','kalite','KYS 1'),
 @('sasirtmali','Denetim','bds 315 onemli yanlislik riskinin belirlenmesi','risk','BDS 315'),
 @('sasirtmali','Muhasebe Standartlari','tms 36 deger dusuklugu gostergeleri','g[oö]sterge','TMS 36'),
 @('sasirtmali','Muhasebe Standartlari','tfrs 16 kiralama muhasebesi','kiralama','TFRS 16'),
 @('sasirtmali','Denetim','bagimsizlik ve etik hukumleri','ba[gğ][iı]ms[iı]zl[iı]k',''),
 @('sasirtmali','Surdurulebilirlik','tsrs 2 sera gazi emisyon aciklamalari','emisyon','TSRS 2'),
 @('onculu','Denetim','ic kontrol bilesenleri','i[cç] kontrol','BDS 315'),
 @('onculu','Denetim','olumlu disindaki gorus turlerinin sartlari','g[oö]r[uü][sş]','BDS 705'),
 @('onculu','Kurumsal Yonetim','yonetim kurulu komiteleri','denetim komitesi',''),
 @('onculu','Sermaye Piyasasi Mevzuati','kaydilestirme ve sonuclari (kok TEK BIR teblige atif yapmasin - her onculun dayanagi verilen kaynak metinlerinde olmali, kural 4c-e)','kaydile[sş]tir',''),
 @('vaka','Denetim','ornekleme ve tespit edememe riski','[oö]rnekle','BDS 530'),
 @('vaka','Denetim','isletmenin surekliligi supheli olayda denetci adimlari','s[uü]reklilik','BDS 570'),
 @('vaka','Denetim','ilk denetimde acilis bakiyeleri','a[cç][iı]l[iı][sş]','BDS 510'),
 @('vaka','Denetim','topluluk denetiminde birim denetcisi (grup denetimi)','birim den','BDS 600'),
 @('hesapli','Kurumsal Yonetim','net isletme sermayesi hesabi','net i[sş]letme sermayesi',''),
 @('hesapli','Denetim','onemlilik ve performans onemliligi hesabi','k[iı]yaslama noktas[iı]','BDS 320'),
 @('hesapli','Muhasebe Standartlari','tms 36 geri kazanilabilir tutar hesabi','geri kazan[iı]labilir','TMS 36'),
 @('hesapli','Kurumsal Yonetim','agirlikli ortalama sermaye maliyeti hesabi','sermaye maliyeti','Teori'),
 @('secici','Denetim','onemlilik + ornekleme + gorus birlesik vakasi','[oö]nemlilik','BDS 320;BDS 530;BDS 705'),
 @('secici','Muhasebe Standartlari','tfrs 16 kullanim hakki varliginda tms 36 deger dusuklugu','de[gğ]er d[uü][sş]','TMS 36;TFRS 16')
)
if($sinav -eq 'SMMM'){ $plan=$planSMMM } elseif($sinav -eq 'KGK'){ $plan=$planKGK }

$tipTalimat=@{
 'sasirtmali'='KOK SASIRTMALI OLACAK: "Asagidakilerden hangisi ... YANLIStir / DEGILdir / soylenemez" tipi olumsuz kok kullan. Dort sik DOGRU bilgi tasir (her biri kaynaktan), tek sik yanlis bilgidir ve isaretli cevap odur. Olumsuz kelimeyi BUYUK harfle vurgula.'
 'onculu'='ONCULU SORU OLACAK: govdede "I. ... II. ... III. ..." uc oncul ver (gerekirse IV), kok "Yukaridakilerden hangileri dogrudur/yanlistir?" olsun; siklar oncul kombinasyonlari (orn. "Yalniz I", "I ve II", "I, II ve III"). Onculler AYNI konunun uc farkli bilgisini test etsin - tek soruda uc bilgi.'
 'vaka'='VAKA SORUSU OLACAK: 3-5 cumlelik gercekci olay orgusu (2025-2026 tarihli senaryo, ozgun sirket/sehir adi - Yildirim/Bursa/Kocaeli YASAK), olayin icinde EN AZ IKI hukuki kavram birlesecek; cozum iki kuralin birlikte uygulanmasini istesin. Bilissel hedef: kor hakem cetvelinde 3-4 puan.'
 'hesapli'='COK ADIMLI HESAP SORUSU OLACAK: en az 5 veri noktasi (sinav ortalamasi 5,63), en az 2 islem adimi; celdiricilerin HER BIRI gercek bir hata yolundan turetilebilir olsun (atlanan kalem, ters oran, yanlis isaret). cozum_tablo ZORUNLU. Veri noktalarini (tutar, adet, tarih) SEN kurgularsin - kaynaktan yalnizca hesabin KURALINI alirsin; kural kaynakta varsa rakam eksikligi kaynak_yetersiz sebebi DEGILDIR.'
 'secici'='SECICI SORU OLACAK (sinavin en zor bandi): EN AZ UC kavram ayni vakada birlessin, cozum coklu adim + yorum istesin, celdiriciler kismi-dogru yollardan turesin. Bilissel hedef: 5 puan. Bu tip sinavda nadirdir - kaliteli olsun, zorlama olmasin.'
}

$sartname=@'
Sen SMMM/SGS sinavi icin SORU YAZARI'sin. Sana DERS, KONU, SORU TIPI ve AMBARDAN GERCEK KAYNAK METNI verilecek. SIFIRDAN, ozgun bir soru yazacaksin.

ALTIN STANDART (hepsi zorunlu):
1. TEK dogru sik; diger dordu KESIN yanlis (olumsuz-kok tipinde tersi).
2. Hukuki her iddia SADECE verilen kaynak metnine dayanir - kaynakta olmayan HUKUKI parametre (oran, sure, had, yontem kurali) UYDURMA. SENARYO VERISI SERBESTTIR: sirket adi, tutar, adet, tarih, maliyet kalemi gibi olay kurgusunu SEN uydurursun - bu ihlal degildir; onemli olan bu verilere uygulanan KURALIN kaynaktan gelmesidir. (Ornek: kaynak amortisman yontemini veriyorsa makine bedelini 480.000 TL diye kurgulamak serbesttir.) Yalnizca sorunun test ettigi HUKUKI KURAL kaynakta hic yoksa "kaynak_yetersiz":true dondur.
3. Hesapli soruda aritmetik BIREBIR dogru; her celdirici gercek hata yolundan turetilir.
4. Dogru sik digerlerinden uzun OLMASIN; dogru cevap harfini rastgele sec.
4b. SIK BICIMI = SINAV BICIMI (27.08 arsiv dersi): gercek sinavda hesap sorusunun siklari YALNIZ sonuctur - "A) 1.200 TL'lik ertelenen vergi varligi", "A) Faiz Gelirleri 17.000" gibi tutar + en fazla kisa isim etiketi. Sikka gerekce/hesap yolu YAZILMAZ ("525.000 TL; toplam 7 yillik kidem uzerinden hesaplanir" YASAK - dogru cevabi ele verir ve sinav biciminde degildir). Gerekce ACIKLAMANIN isidir. Hukuk sorusunda sik tam cumle olabilir ama o cumle IDDIA olur, iddianin gerekcesi olmaz.
4c. CEVAP SIZINTISI YASAGI (27.08 kor hakem dersi - 60 sorunun 12'sinde cikti): (a) celdiriciler "her durumda / hicbir sekilde / yalnizca / kesinlikle" MUTLAKIYETCI kaliba yigilmasin - kalip bilen aday dogruyu bilgisiz bulur; EN AZ BIR celdirici de dogru sik gibi nuansli/sartli kurulsun. (b) Dogru sik tek "nuansli-uzun" sik olmasin (kural 4'un tamamlayicisi). (c) Iki sik birbirinin birebir tersi olmasin - yan yana okununca cevap sizar. (d) BUYUK harf vurgusu YALNIZ olumsuz kok kelimesinde kullanilir; sik metninde vurgulama yasak. (e) Kok hangi kaynaga atif yapiyorsa dogru cevabin ve oncullerin dayanagi O kaynakta olmali - baska teblige dayanan oncul koke atif yapilan kaynakla dogrulanamaz.
GERCEK CIKMIS ORNEK (2014-1 SGS - KONUYU degil BICIMI ornek al; govde kisa-net, siklar sonuc+kisa etiket):
"39. ABC Isletmesi, 2013 yilinda calisanlarla ilgili olarak 15.000 TL kidem tazminati karsiligi ayirmistir. Ayni donemde isten ayrilan personele 9.000 TL kidem tazminati odemistir. Vergi orani %20 olup, kidem tazminati tutari ayrildigi donemde degil, odendigi donemde vergi matrahindan dusulebilmektedir. TMS 12 Gelir Vergileri standardina gore bu olaya iliskin olarak 2013 yilinda asagidakilerden hangisi meydana gelmistir?
A) 1.200 TL'lik ertelenen vergi varligi  B) 1.800 TL'lik ertelenen vergi yukumlulugu  C) 3.000 TL'lik indirilebilir gecici fark  D) 4.200 TL'lik vergilendirilebilir gecici fark  E) 6.000 TL'lik surekli fark"
2c. KANUNI SINIR/TAVAN KURALI: hesabin konusunda kanuni tavan/taban/had olabilir (kidem tazminati tavani, istisna haddi, azami oran...). Guncel sinir rakami verilen kaynak metinde YOKSA: senaryoyu sinira CARPMAYACAK sekilde kur (orn. kidem hesabinda dusuk gunluk ucret sec) ve dogru sikkin aciklamasinda sinirin varligini bir cumleyle not et ("gercekte ucret kidem tavanini asarsa tavan esas alinir"). Sinir rakamini ASLA hafizadan yazma.
5. DIL: sinav dili esas (eski kanun terimi ana terim olamaz; ilk geciste parantezle kopru: "genel uretim giderleri (kanunda 'genel imal giderleri'; THP 730)"); arkaik ifade yasak ("vucuda getirilmek" degil "uretilmek"); ne kanun agzi ne sokak agzi - sade profesyonel ders dili; "kar" kazanc anlaminda hep sapkali (kâr).
6. Senaryo tarihi 2025-2026; sirket/sehir adi ozgun (Yildirim, Bursa, Kocaeli, Mehmet Bey YASAK).
7. ACIKLAMA TAKIMI (cila v3): dogru sikta DORT PARCA (Ne soruluyor / Kural / Bu olayda / Akilda kalsin); her yanlis sikta tuzagin adi DOGAL kalipla ("X'i Y sanan ogrenci bu sikki secer" - "TUZAK" kelimesi soru basina en fazla 1 kez) + "Dogrusu:" cumlesi; sinav_taktigi (tipe ozel tek cumle); notlandirici (bu tipte adaylar nereden puan kaybeder); dayanak (kaynak kunyesi); hesapli/tabloluysa cozum_tablo; surec konusuysa akis.
8. IC MONOLOG YASAK - ogrenciye konusan bitmis metin.
9. KAVRAM KAPISI: dogru sikkin "Kural:" parcasinin ILK cumlesi dayanagin kimligini sade dille tanitir ("BDS 500, 'Denetim Kaniti' standardidir; ..."). Paragraf numarasi tek basina anilmaz - once kavram adi, parantezde numara: "orneklemenin amaci hukmu (A67)". Teknik jargon ilk geciste yarim-cumle tanimla acilir: "anakitle (denetlenen kalemlerin tamami)".
10. TAKTIK SORUDAN KONUSUR: sinav_taktigi sinav aninda uygulanabilir olmali (aday elinde kaynak metni YOK); ornek verilecekse SORUNUN gercek ifadesinden - soru disindan ornek uydurma. UZUN VAKA metinlerinde (BDS 510/600 tipi) taktik ZAMAN/OKUMA yonetimini de icersin (28.08 Cem karari): once sorunun son cumlesini oku, tarih-tutar-taraf isaretle, takilirsan sona birak gibi - ama soruya OZEL kur, ezber kalip olmasin.
11. MADDE DIYETI + ONCE MANTIK (28.08 Cem onayi): aciklama HOCA gibi ogretir, hukukcu gibi savunmaz. "Kural:" parcasinin ilk cumlesi kanun koyucunun DERDINI gunluk dille anlatir (kural neden var, hangi kacisi kapatiyor); madde kunyesi cumle sonunda parantezde. Bes sikkin tamaminda kunye TOPLAM en fazla 2 kez; kalan atiflar kunyesiz ("kanun bu kapiyi kapatmis"); "Dogrusu:" cumleleri kunyesiz saf insan dili. Kunyelerin tam listesi dayanak alanina.

Yanit YALNIZCA su JSON:
{"soru":"...","siklar":{"A":"...","B":"...","C":"...","D":"...","E":"..."},"dogru":"A","aciklama":{"A":"...","B":"...","C":"...","D":"...","E":"..."},"hap":"...","sinav_taktigi":"...","dayanak":"...","notlandirici":"...","cozum_tablo":{"basliklar":[],"satirlar":[]},"akis":[],"zorluk_hedefi":"...","kaynak_yetersiz":false}

=== GOREV ===
DERS: {DERS}
KONU: {KONU}
TIP TALIMATI: {TIP}

KAYNAK METNI (ambar):
{KAYNAK}
'@

if($direkt){
  . (Join-Path $here 'api-hedef.ps1')
  $cikti=Join-Path $FAB ("zorluk-prova-{0}.jsonl" -f $sinav)
  if(Test-Path $cikti){ Remove-Item $cikti }
  $sw=[IO.StreamWriter]::new($cikti,$false,[Text.UTF8Encoding]::new($false))
  $n=0; $ok=0; $hata=0; $gT=0; $cT=0
  foreach($p in $plan){
    $n++
    $tip=$p[0]; $ders=$p[1]; $konu=$p[2]; $desen=$p[3]; $onek=$p[4]
    $e=[uri]::EscapeDataString($desen)
    $kaynak=''
    $r=@()
    if($onek){
      $oe=[uri]::EscapeDataString($onek)
      # 27.08 dersi: kavram bazen METINDE degil BASLIKTA gecer (TBK 'sebepsiz
      # zenginlesme' vakasi) - onekli arama iki alana da bakar
      $r=@(Invoke-RestMethod -Uri "$U/dokumanlar?select=kaynak_ad,metin&kaynak_ad=ilike.$oe%25&or=(metin.imatch.$e,baslik.imatch.$e)&limit=4" -Headers $H -TimeoutSec 60 | % { $_ })
      if($r.Count -eq 0){
        # kavram kaynak_ad'in kendisinde de olabilir ('TBK m.77 - Sebepsiz zenginlesme')
        $r=@(Invoke-RestMethod -Uri "$U/dokumanlar?select=kaynak_ad,metin&kaynak_ad=ilike.$oe%25&kaynak_ad=imatch.$e&limit=4" -Headers $H -TimeoutSec 60 | % { $_ })
      }
    }
    if($r.Count -eq 0){
      $r=@(Invoke-RestMethod -Uri "$U/dokumanlar?select=kaynak_ad,metin&or=(metin.imatch.$e,baslik.imatch.$e)&tur=not.in.(cikmis-soru,cikmis-komisyon-cevabi)&limit=3" -Headers $H -TimeoutSec 60 | % { $_ })
    }
    foreach($x in $r){ $kaynak += "[$($x.kaynak_ad)] " + $x.metin.Substring(0,[Math]::Min(2200,$x.metin.Length)) + "`n`n" }
    if([string]::IsNullOrWhiteSpace($kaynak)){ $kaynak='(kaynak bulunamadi)' }
    $istem=$sartname.Replace('{DERS}',$ders).Replace('{KONU}',$konu).Replace('{TIP}',$tipTalimat[$tip]).Replace('{KAYNAK}',$kaynak)
    try{
      $y=$null
      foreach($d in 1..3){ try{ $y=Invoke-ClaudeMesaj -Model 'claude-sonnet-5' -Icerik $istem -MaxTok 10000; break }catch{ if($d -eq 3){throw}; Start-Sleep -Seconds (5*$d) } }
      # dusunme butcesi metni yediyse (bos/kesik) TEK tekrar, 16k tavanla
      if(-not $y.metin -or $y.metin.Trim().Length -lt 50){
        try{ $y=Invoke-ClaudeMesaj -Model 'claude-sonnet-5' -Icerik $istem -MaxTok 16000 }catch{}
      }
      $gT+=[int]$y.girdi; $cT+=[int]$y.cikti
      # goster betiginin bekledigi jsonl bicimi (batch sonuc sekli)
      $kayit=[ordered]@{ custom_id=("{0}-{1:d2}-{2}" -f $sinav,$n,$tip); result=[ordered]@{ type='succeeded'; message=[ordered]@{ stop_reason=$y.dur; content=@(@{type='text';text=$y.metin}) } } }
      $sw.WriteLine(($kayit | ConvertTo-Json -Depth 8 -Compress)); $ok++
    }catch{ $hata++; Write-Host "  HATA [$n/$tip]: $($_.Exception.Message)" }
    Write-Host ("  {0}/20 {1} ({2})" -f $n,$tip,$(if($y){$y.dur}else{'hata'}))
  }
  $sw.Close()
  "DIREKT bitti: ok $ok / hata $hata | girdi $gT cikti $cT tok (~`$$([math]::Round(($gT*2+$cT*10)/1e6,2)) liste)"
}

if($onar){
  # 27.08 sabah dersi: 60'in 18'i 'kaynak_yetersiz' dondu - onek+desen HEDEFI
  # tutturamayinca model (dogru davranisla) uydurmayi reddetti. Onarim: yalniz
  # basarisiz satirlar, GENIS kaynakla (onekli 6 + serbest 4 parca, 3000'er
  # karakter) ve dogrudan 16k tavanla yeniden; ayrica max_tokens kesigine tekrar.
  . (Join-Path $here 'api-hedef.ps1')
  $cikti=Join-Path $FAB ("zorluk-prova-{0}.jsonl" -f $sinav)
  $satlar=[System.Collections.ArrayList]@(Get-Content $cikti -Encoding UTF8)
  $alarmY=Join-Path $FAB 'uretim-kaynak-alarm.json'
  $alarm=@(); if(Test-Path $alarmY){ $alarm=@(Get-Content $alarmY -Raw -Encoding UTF8 | ConvertFrom-Json) }
  $onarilan=0; $kalan=0; $gT=0; $cT=0
  for($i=0; $i -lt $satlar.Count; $i++){
    $r=$satlar[$i] | ConvertFrom-Json
    $txt=(@($r.result.message.content) | ? { $_.type -eq 'text' } | Select-Object -Last 1).text
    $tt="$txt".Trim() -replace '^```json\s*','' -replace '^```\s*','' -replace '\s*```$',''
    $c=$null; try{ $c=$tt | ConvertFrom-Json }catch{ $son=$tt.LastIndexOf('}'); if($son -gt 0){ try{ $c=$tt.Substring(0,$son+1) | ConvertFrom-Json }catch{} } }
    $zorla=$yeniden -and (($yeniden -split ',') -contains $r.custom_id)
    if($c -and $c.soru -and -not $zorla){ continue }   # saglam - dokunma
    $p=$plan[$i]
    $tip=$p[0]; $ders=$p[1]; $konu=$p[2]; $desen=$p[3]; $onek=$p[4]
    $e=[uri]::EscapeDataString($desen)
    $r2=@()
    if($onek){
      # 27.08: birlesik-konu sorusu icin coklu kaynak - onek ';' ile ayrilir,
      # her kaynaktan ayri cekilir; desen tutmazsa o kaynagin ilk parcalari alinir
      foreach($tekOnek in ($onek -split ';')){
        $oe=[uri]::EscapeDataString($tekOnek.Trim())
        $par=@(Invoke-RestMethod -Uri "$U/dokumanlar?select=kaynak_ad,metin&kaynak_ad=ilike.$oe%25&or=(metin.imatch.$e,baslik.imatch.$e,kaynak_ad.imatch.$e)&limit=4" -Headers $H -TimeoutSec 60 | % { $_ })
        if($par.Count -eq 0){ $par=@(Invoke-RestMethod -Uri "$U/dokumanlar?select=kaynak_ad,metin&kaynak_ad=ilike.$oe%25&limit=3" -Headers $H -TimeoutSec 60 | % { $_ }) }
        $r2+=$par
      }
    }
    $r2+=@(Invoke-RestMethod -Uri "$U/dokumanlar?select=kaynak_ad,metin&or=(metin.imatch.$e,baslik.imatch.$e)&tur=not.in.(cikmis-soru,cikmis-komisyon-cevabi)&limit=4" -Headers $H -TimeoutSec 60 | % { $_ })
    $kaynak=''; $gor=@{}
    foreach($x in $r2){ if($gor["$($x.kaynak_ad)"]){continue}; $gor["$($x.kaynak_ad)"]=1; $kaynak += "[$($x.kaynak_ad)] " + $x.metin.Substring(0,[Math]::Min(3000,$x.metin.Length)) + "`n`n" }
    if([string]::IsNullOrWhiteSpace($kaynak)){ $kaynak='(kaynak bulunamadi)' }
    $istem=$sartname.Replace('{DERS}',$ders).Replace('{KONU}',$konu).Replace('{TIP}',$tipTalimat[$tip]).Replace('{KAYNAK}',$kaynak)
    $y=$null
    foreach($d in 1..3){ try{ $y=Invoke-ClaudeMesaj -Model 'claude-sonnet-5' -Icerik $istem -MaxTok 30000; break }catch{ if($d -eq 3){throw}; Start-Sleep -Seconds (5*$d) } }
    $gT+=[int]$y.girdi; $cT+=[int]$y.cikti
    $yeni=[ordered]@{ custom_id=$r.custom_id; result=[ordered]@{ type='succeeded'; message=[ordered]@{ stop_reason=$y.dur; content=@(@{type='text';text=$y.metin}) } } }
    $satlar[$i]=($yeni | ConvertTo-Json -Depth 8 -Compress)
    # sonuc kontrolu + alarm kaydi (Cem sozu: sik konu SESSIZCE bos kalmaz)
    $t2="$($y.metin)".Trim() -replace '^```json\s*','' -replace '^```\s*','' -replace '\s*```$',''
    $c2=$null; try{ $c2=$t2 | ConvertFrom-Json }catch{ $son=$t2.LastIndexOf('}'); if($son -gt 0){ try{ $c2=$t2.Substring(0,$son+1) | ConvertFrom-Json }catch{} } }
    if($c2 -and $c2.soru){ $onarilan++; Write-Host "  ONARILDI $($r.custom_id)" }
    else{
      $kalan++
      $alarm+=[pscustomobject]@{tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm');sinav=$sinav;id=$r.custom_id;ders=$ders;konu=$konu;durum='genis-kaynakla-da-uretilemedi'}
      Write-Host "  HALA RED $($r.custom_id) -> alarm"
    }
  }
  [IO.File]::WriteAllLines($cikti,[string[]]$satlar,[Text.UTF8Encoding]::new($false))
  ConvertTo-Json @($alarm) -Depth 4 | Out-File $alarmY -Encoding utf8
  "ONARIM bitti [$sinav]: onarilan $onarilan / hala-red $kalan | girdi $gT cikti $cT tok"
}

if($gonder){
  $istekler=@()
  $n=0
  foreach($p in $plan){
    $n++
    $tip=$p[0]; $ders=$p[1]; $konu=$p[2]; $desen=$p[3]; $onek=$p[4]
    $e=[uri]::EscapeDataString($desen)
    $kaynak=''
    $r=@()
    if($onek){
      $oe=[uri]::EscapeDataString($onek)
      # 27.08 dersi: kavram bazen METINDE degil BASLIKTA gecer (TBK 'sebepsiz
      # zenginlesme' vakasi) - onekli arama iki alana da bakar
      $r=@(Invoke-RestMethod -Uri "$U/dokumanlar?select=kaynak_ad,metin&kaynak_ad=ilike.$oe%25&or=(metin.imatch.$e,baslik.imatch.$e)&limit=4" -Headers $H -TimeoutSec 60 | % { $_ })
      if($r.Count -eq 0){
        # kavram kaynak_ad'in kendisinde de olabilir ('TBK m.77 - Sebepsiz zenginlesme')
        $r=@(Invoke-RestMethod -Uri "$U/dokumanlar?select=kaynak_ad,metin&kaynak_ad=ilike.$oe%25&kaynak_ad=imatch.$e&limit=4" -Headers $H -TimeoutSec 60 | % { $_ })
      }
    }
    if($r.Count -eq 0){
      $r=@(Invoke-RestMethod -Uri "$U/dokumanlar?select=kaynak_ad,metin&or=(metin.imatch.$e,baslik.imatch.$e)&tur=not.in.(cikmis-soru,cikmis-komisyon-cevabi)&limit=3" -Headers $H -TimeoutSec 60 | % { $_ })
    }
    foreach($x in $r){ $kaynak += "[$($x.kaynak_ad)] " + $x.metin.Substring(0,[Math]::Min(2200,$x.metin.Length)) + "`n`n" }
    if([string]::IsNullOrWhiteSpace($kaynak)){ Write-Host "  UYARI: kaynak bulunamadi -> $konu (istek yine gider, model kaynak_yetersiz donebilir)"; $kaynak='(kaynak bulunamadi)' }
    $istem=$sartname.Replace('{DERS}',$ders).Replace('{KONU}',$konu).Replace('{TIP}',$tipTalimat[$tip]).Replace('{KAYNAK}',$kaynak)
    $istekler += [ordered]@{ custom_id=("zorluk-{0:d2}-{1}" -f $n,$tip); params=[ordered]@{ model='claude-sonnet-5'; max_tokens=10000; messages=@(@{role='user';content=$istem}) } }
  }
  $HB=AntBas
  $govde=@{requests=$istekler} | ConvertTo-Json -Depth 10 -Compress
  $r=Invoke-RestMethod -Method Post -Uri $ANT -Headers $HB -Body ([Text.Encoding]::UTF8.GetBytes($govde)) -TimeoutSec 300
  "gonderildi: $($r.id) ($($istekler.Count) istek)"
  @([pscustomobject]@{batch=$r.id;adet=$istekler.Count;tarih=(Get-Date -Format 's')}) | ConvertTo-Json -Depth 3 | Out-File $IDLER -Encoding utf8
}
if($durum){
  $HB=AntBas
  foreach($b in (Get-Content $IDLER -Raw -Encoding UTF8 | ConvertFrom-Json)){
    $r=Invoke-RestMethod -Uri "$ANT/$($b.batch)" -Headers $HB -TimeoutSec 60
    "{0}  {1}  {2}/{3}  hata {4}" -f $b.batch,$r.processing_status,$r.request_counts.succeeded,$b.adet,$r.request_counts.errored
  }
}
if($indir){
  $HB=AntBas
  foreach($b in (Get-Content $IDLER -Raw -Encoding UTF8 | ConvertFrom-Json)){
    $r=Invoke-RestMethod -Uri "$ANT/$($b.batch)" -Headers $HB -TimeoutSec 60
    if($r.processing_status -ne 'ended'){ "bitmedi: $($b.batch)"; continue }
    $hedef=Join-Path $FAB ("zorluk-prova-{0}.jsonl" -f $b.batch)
    Invoke-WebRequest -Uri $r.results_url -Headers $HB -OutFile $hedef -TimeoutSec 600
    "indirildi: $(Split-Path $hedef -Leaf)"
  }
}
