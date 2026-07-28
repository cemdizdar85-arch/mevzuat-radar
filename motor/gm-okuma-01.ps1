# gm-okuma-01.ps1 - 28.07.2026
# GM OKUMASI, PARTI 1: karantinada "hap-zayif" damgali 15 soru.
# Her biri elle okundu; hap alanlari elle yazildi; iddialar AMBARDAN birinci elden
# teyit edildi (TTK m.482/483/501, TBK m.89, 5510 m.7-8, VUK m.359, TMS 1, BDS 320).
#
# TEYIT SONUCU 3 HATA CIKTI - otomatik kapilarin (kaynak teyidi + iki cozucu)
# yakalayamadigi tur: KAYNAK VAR, ama kaynak sorunun iddia ettigi seyi SOYLEMIYOR.
#   * 89303193 (5510 m.8)  -> RED. Kanun 1 aylik istisnayi "issizlik ODENEGI ALAN"a
#     degil, "issizlik sigortasina TABI OLMAYAN sozlesmeli personel"e taniyor (m.8/1-c).
#     Soru bu iki farkli kavrami birbirine karistirmis.
#   * b8cb661a (TTK m.482) -> RED. "Satilamazsa esas sermaye azaltilir" hukmu kanunda
#     YOK. m.483/3 aksine mutemerrit pay sahibini acik kalan tutardan sorumlu tutuyor.
#   * 8d8f1464 (TTK m.482) -> DUZELTILDI. Iskat ihtari NOTER araciligiyla degil;
#     m.483/1-2 ilan (35. md. gazetesi) + internet sitesi mesaji, NAMA yazili senetlerde
#     iadeli taahhutlu mektup + internet mesaji ongoruyor. Sik ve aciklama duzeltildi,
#     kaynak m.483 olarak guncellendi.

$ErrorActionPreference = "Stop"
$kok = Split-Path -Parent $PSScriptRoot
$fabrikaDir = Join-Path $kok "veri\fabrika"

$HAP = @{
 'ff4a67a3' = "Toplulastirma riski CIFT YONLUDUR: cok sayida farkli kalemi tek satirda birlestirmek de, onemsiz kalemleri gereksiz yere tek tek ayirmak da bilgiyi karartir; TMS 1 m.30A ikisini de yasaklar. Olcut 'kac satir var' degil, 'okuyucu onemli bilgiyi gorebiliyor mu'dur. TUZAK: 'ayristirmak her zaman seffafliktir' sanmak - onemli kalem detay yigini icinde kayboluyorsa bu da karartmadir."
 '6085f617' = "Performans onemliligi, genel onemlilikten BILEREK dusuk belirlenir (BDS 320). Amaci: tek basina onemsiz kalan yanlisliklarin TOPLAMDA birikip genel onemliligi asma olasiligini kabul edilebilir dusuk bir seviyeye indirmektir. TUZAK: onu zamandan tasarruf ya da ucret pazarligi araci sanmak - tersine daha genis test gerektirir, cunku esik dustukce ornek buyur."
 '475ca300' = "Iki tarih arasi gun sayisinda 'baslangic ve bitis dahil' deniyorsa formul: (ilk ayin sonuna kadar kalan gun) + (ikinci ayda gecen gun). 23 Agustos-13 Eylul icin: Agustos'ta 31-23+1 = 9 gun, Eylul'de 13 gun, toplam 22 gun. TUZAK: iki tarihin farkini alip (21) bitis gununu saymayi unutmak - 'dahil' ifadesi gorulduginde sonuca 1 eklenir."
 'abb59c2c' = "Edilgen catili cumlede eylemi yapan degil, eylemin KENDISINE yapildigi kisi anlatiliyorsa o soz yonelme (-e) hali almalidir: 'Mustafa Kemal'e ... verilmistir'. Yalin birakilirsa ozne ile tumlec karisir, unvani veren taraf oymus gibi okunur. TUZAK: bozuklugu zaman uyumsuzlugu ya da siralama hatasi sanmak - yuklem edilgense once hal ekine bak."
 '33b28701' = "'Nitekim' onceki yargiyi DESTEKLEYEN, onu dogrulayan baglayicidir; 'oysa, aksine, buna karsin, yine de' ise ZITLIK kurar. Bosluktan onceki ve sonraki yargilar ayni yonde ilerliyorsa destekleyici baglac gelir. TUZAK: birinci cumlede 'en cok kayip' gibi agir/olumsuz bir ifade gorunce refleksle zitlik baglaci secmek - agirlik zitlik demek degildir."
 'eef24eba' = "Haksiz rekabette manevi tazminat kendiliginden dogmaz: TTK m.56/1-f, TBK m.58'deki kisilik hakkinin zedelenmesi sartlarinin AYRICA gerceklesmesini arar. Yani haksiz rekabetin ispati maddi tazminat icin yeter, manevi tazminat icin yetmez. TUZAK: 'haksiz rekabet varsa manevi tazminat da vardir' zinciri; ayrica manevi tazminati ceza mahkemesi kararina baglamak - boyle bir on sart yoktur."
 'eb74bc1f' = "Calisanin ya da eski calisanin musteri listesi, fiyatlandirma stratejisi gibi SIR niteligindeki bilgileri yetkisiz aktarmasi TTK m.55/1-d 'uretim ve is sirlarini hukuka aykiri ifsa' halidir. TUZAK: bunu (c) bendindeki 'baskalarinin is urunlerinden yetkisiz yararlanma' ile karistirmak - orada hazir bir is urununun kopyalanmasi vardir, burada gizli bilginin disari cikarilmasi."
 '788dc96f' = "Temsil yetkisinin sinirlandirilmasi kural olarak iyiniyetli ucuncu kisiye karsi ileri surulemez; TESCIL EDILMIS OLMASI bunu degistirmez (TTK m.371/2). Ucuncu kisiye karsi hukum ifade eden yalnizca iki sinirlama vardir: yetkinin merkez veya bir subenin islerine hasredilmesi ve birlikte temsil. TUZAK: 'tescil edildiyse herkesi baglar' genellemesi - islem TURUNE gore sinirlama bu iki istisnaya girmez."
 'f1563830' = "TBK m.89: aksi kararlastirilmadiysa para borcu alacaklinin odeme zamanindaki yerlesim yerinde, PARCA borcu SOZLESMENIN KURULDUGU ANDA esyanin bulundugu yerde, diger borclar dogduklari anda borclunun yerlesim yerinde ifa edilir. TUZAK: esya sonradan baska bir depoya tasininca ifa yerinin de tasindigini sanmak - olcut sozlesme anidir, teslim ani degil."
 '624e3725' = "Sigortalilik, bildirge verilmesiyle degil FIILEN calismaya baslanan tarihte dogar (5510 m.7). Ise giris bildirgesi bu durumu Kuruma bildirme aracidir; hic verilmemesi sigortaliligi ortadan kaldirmaz, isverene m.102'ye gore idari para cezasi getirir. TUZAK: baslangici denetim tutanaginin ya da gec verilen bildirgenin tarihine baglamak."
 '8d8f1464' = "Iskat kendiliginden olmaz: TTK m.483 once IHTAR sartini koyar ve bir aylik odeme suresi tanir. Ihtar, 35. maddedeki gazetede ilan ve internet sitesi mesajiyla; NAMA yazili pay senedi sahiplerine ise ilan yerine IADELI TAAHHUTLU MEKTUP ve internet mesajiyla yapilir, bir aylik sure mektubun alindigi tarihte baslar. TUZAK: 'noter ihtari sart' demek - kanun noteri degil, ilani/iadeli taahhutlu mektubu arar."
 'eba52857' = "Sermaye koyma borcunu ifa etmeyen pay sahibini iskat etme karari YONETIM KURULU tarafindan alinir (TTK m.482/2); genel kurul, denetci ya da mahkeme degil. Yonetim kurulu ayrica payi satip yerine baskasini almaya ve pay senedini iptale yetkilidir. TUZAK: 'sermayeyi ilgilendiren her karar genel kuruldadir' genellemesi - iskat acikca yonetim kuruluna birakilmistir."
 '0a901bdd' = "VUK m.359'daki HAPIS cezasi, fiili bilerek ve isteyerek gerceklestiren kisiye uygulanir; cezanin sahsiligi ilkesi geregi bu sorumluluk devredilemez. Kanuni temsilcinin VUK m.10 kapsamindaki sorumlulugu vergi ve vergi ziyai cezasina iliskin MALI bir sorumluluktur, hapis cezasini otomatik olarak ona yuklemez. TUZAK: m.10 mali sorumlulugu ile m.359 sahsi cezai sorumlulugunu ayni sanmak."
}

$RED = @{
 '89303193' = "GM RED (kaynak teyidi, 28.07): 5510 m.8/1-c bir aylik istisnayi 'issizlik ODENEGI ALMAKTA OLAN kisi'ye degil, 'kamu idarelerince istihdam edilen, 4447 sayili Kanuna gore issizlik sigortasina TABI OLMAYAN sozlesmeli personel ile kamu idarelerince yurt disi gorevde calismak uzere ise alinanlar'a taniyor. Soru bu iki farkli kavrami birbirine karistirmis; isaretlenen A sikki kanun metniyle dogrulanmiyor."
 'b8cb661a' = "GM RED (kaynak teyidi, 28.07): 'Pay satilamazsa esas sermaye o tutar kadar azaltilir' hukmu TTK m.482'de de m.483'te de YOK. m.482/2 yonetim kuruluna payi satip yerine baskasini alma ve senedi iptal etme yetkisi verir; m.483/3 ise mutemerrit pay sahibini yeni pay sahibinin odemelerinden ACIK KALAN TUTAR icin sirkete karsi sorumlu tutar. Otomatik sermaye azaltimi kanuni sonuc degildir."
}

$dosyalar = @(Get-ChildItem $fabrikaDir -Filter *.json | Sort-Object Name)
$ist = [ordered]@{ hapYazildi=0; redEdildi=0; icerikDuzeltildi=0; bulunamadi=0 }
$islenen = @{}

foreach($d in $dosyalar){
  try { $x = Get-Content $d.FullName -Raw -Encoding UTF8 | ConvertFrom-Json } catch { continue }
  if(-not $x.sorular){ continue }
  $degisti = $false

  foreach($s in @($x.sorular)){
    if(-not $s){ continue }
    $id = "$($s.id)"

    # --- RED edilenler
    if($RED.ContainsKey($id)){
      $s.durum = 'karantina-red'
      $s | Add-Member -NotePropertyName gmKarar -NotePropertyValue $RED[$id] -Force
      $s | Add-Member -NotePropertyName gmTarih -NotePropertyValue "28.07.2026" -Force
      $ist.redEdildi++; $islenen[$id]=$true; $degisti=$true
      continue
    }

    if(-not $HAP.ContainsKey($id)){ continue }

    # --- 8d8f1464: icerik duzeltmesi (noter -> TTK m.483 usulu)
    if($id -eq '8d8f1464'){
      $s.siklar.C = "Gecersizdir; iskat icin once TTK m.483'teki usulle (ilan ve internet sitesi mesaji; nama yazili pay senetlerinde iadeli taahhutlu mektup) ihtar cekilip bir ay odeme suresi verilmesi zorunludur"
      $s.siklar.B = "Gecerlidir, sozlu uyari yeterli oldugundan ayrica yazili ihtara gerek yoktur"
      $s.aciklama.C = "Dogru. TTK m.483/1 uyarinca yonetim kurulu, mutemerrit pay sahibine ihtarda bulunup temerrude konu tutari bir ay icinde odemesini istemek zorundadir; m.483/2'ye gore nama yazili pay senedi sahiplerine bu ihtar ilan yerine iadeli taahhutlu mektupla ve internet sitesi mesajiyla yapilir ve bir aylik sure mektubun alindigi tarihten baslar. Ihtar ve sure verilmeden alinan iskat karari gecersizdir."
      $s.aciklama.B = "Yanlis. Sozlu uyari yeterli degildir; kanun yazili/ilanen ihtar ve bir aylik sure sarti koyar."
      $s.kaynak = "TTK (6102 s.K.) m.483"
      $ist.icerikDuzeltildi++
    }

    $s.hap = $HAP[$id]
    $s.durum = 'gm-onay'
    $s | Add-Member -NotePropertyName gmKarar -NotePropertyValue "GM okudu, kaynak ambardan birinci elden teyit edildi, hap elle yazildi. Kasaya girmeye hazir." -Force
    $s | Add-Member -NotePropertyName gmTarih -NotePropertyValue "28.07.2026" -Force
    $ist.hapYazildi++; $islenen[$id]=$true; $degisti=$true
  }

  if($degisti){ [IO.File]::WriteAllText($d.FullName, ($x | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false))) }
}

foreach($id in (@($HAP.Keys) + @($RED.Keys))){ if(-not $islenen.ContainsKey($id)){ Write-Host ("BULUNAMADI: {0}" -f $id); $ist.bulunamadi++ } }

Write-Host ""
Write-Host "======== GM OKUMASI PARTI 1 ========"
foreach($k in $ist.Keys){ Write-Host ("  {0,-18} {1}" -f $k, $ist[$k]) }
if($ist.bulunamadi -gt 0){ Write-Host "KIRMIZI: bazi id'ler bulunamadi - dosyalar degismis olabilir"; exit 1 }
