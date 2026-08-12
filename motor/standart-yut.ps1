# ============================================================================
#  TSRS 1 / TSRS 2 / BOBI FRS AMBARA YUTMA - 08.08.2026
#
#  CEM: "TSRS 1, TSRS 2 ve BOBI FRS metinleri yut sonra soru uret"
#
#  NEDEN: KGK sinavinin %7,4'u surdurulebilirlik/iklim, %2'si BOBI FRS.
#  Bizim bankada ikisi de SIFIR. Kaynaksiz soru yazilmadigi icin once
#  birincil metin ambara girer.
#
#  KAPSAMA KAPISI: bu projenin kurali - kaynak metnin ambara giren karakter
#  orani %98'in altina duserse KIRMIZI. Onun icin bolumleme "kaybetmeyen"
#  bicimde kurulur: ilk isaretten ONCEKI metin de ayri bir parca olarak
#  yazilir, hicbir karakter atilmaz. Sonunda oran OLCULUR ve basilir.
#
#  IDEMPOTENT: ayni kaynak yeniden yutulursa once eski kayitlar silinir;
#  boylece tekrar kosmak mukerrer uretmez.
#
#  TOPLU YAZIM DUSERSE SATIR SATIR DENENIR: PostgREST'te tek bozuk satir
#  butun partiyi dusuruyor (bu projede 147 saglam soru bir satir yuzunden
#  cope gitmisti).
#
#  Cikti: veri/standart-yutma.json  |  BEDAVA
# ============================================================================
# -sadece: yalniz adi bu onekle baslayan belgeler islenir. 09.08'de eklendi -
# BDS'ler yutulurken TSRS/TFRS/BOBI'nin bosuna yeniden yutulmasini onler
# (yutma idempotent oldugu icin siler+yazar; gereksiz risk ve zaman).
param([switch]$yaz, [int]$parcaTavan = 0, [string]$sadece = '')
$ErrorActionPreference='Continue'
$buradaDizin = Split-Path -Parent $MyInvocation.MyCommand.Path
$projeDizin  = Split-Path -Parent $buradaDizin
$kaynakDizin = Join-Path $env:TEMP 'standart-yut'

$anahtar = [Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User')
if(-not $anahtar){ $anahtar = $env:SUPABASE_SERVICE_KEY }
$adres = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1'
Add-Type -AssemblyName System.Net.Http
$istemci = New-Object System.Net.Http.HttpClient
$istemci.Timeout=[TimeSpan]::FromSeconds(180)
$istemci.DefaultRequestHeaders.Add('apikey',$anahtar)
$istemci.DefaultRequestHeaders.Add('Authorization',('Bearer '+$anahtar))

# BELGE TANIMLARI - her belgenin kendi paragraf isareti var
$BELGELER = @(
 @{ ad='TSRS-1'; kisaAd='TSRS 1'; baslik='Surdurulebilirlikle Iliskili Finansal Bilgilerin Aciklanmasina Iliskin Genel Hukumler'
    url='https://www.kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/Surdurulebilirlik/RaporlamaStandarti/TSRS%201(1).pdf'
    bolucu='(?m)^(?=\s{0,4}\d{1,3}\s{2,}\S)'; noDesen='^\s{0,4}(\d{1,3})\s{2,}' }
 @{ ad='TSRS-2'; kisaAd='TSRS 2'; baslik='Iklimle Ilgili Aciklamalar'
    url='https://www.kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/Surdurulebilirlik/RaporlamaStandarti/TSRS2_.pdf'
    bolucu='(?m)^(?=\s{0,4}\d{1,3}\s{2,}\S)'; noDesen='^\s{0,4}(\d{1,3})\s{2,}' }
 @{ ad='TSRS-1-karar-gerekceleri'; kisaAd='TSRS 1 Karar Gerekceleri'; baslik='TSRS 1 Karar Gerekceleri'
    url='https://www.kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/Surdurulebilirlik/RaporlamaStandarti/TSRS%201_Karar%20Gerekceleri.pdf'
    bolucu='(?m)^(?=\s{0,4}[A-ZÇĞİÖŞÜ]{2,3}\d{1,3}\s)'; noDesen='^\s{0,4}([A-ZÇĞİÖŞÜ]{2,3}\d{1,3})\s' }
 # 09.08 EKLENDI: TMS 17/18'e dayanan 9 soru yeniden yazilacak; TFRS 16 ve
 # TFRS 15 onlarin yerini alan yururlukteki standartlar. Kaynaksiz soru
 # yazilmadigi icin once metinleri ambara girer.
 @{ ad='TFRS-16'; kisaAd='TFRS 16'; baslik='Kiralamalar'
    url='https://kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TMS_TFRS_Setleri/2022/Mavi_Kitap/TFRS%2016.pdf'
    bolucu='(?m)^(?=\s{0,4}\d{1,3}\s{2,}\S)'; noDesen='^\s{0,4}(\d{1,3})\s{2,}' }
 @{ ad='TFRS-15'; kisaAd='TFRS 15'; baslik='Musteri Sozlesmelerinden Hasilat'
    url='https://www.kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TMS_TFRS_Setleri/2022/Kirmizi_Kitap/TFRS/TFRS%2015.pdf'
    bolucu='(?m)^(?=\s{0,4}\d{1,3}\s{2,}\S)'; noDesen='^\s{0,4}(\d{1,3})\s{2,}' }
 @{ ad='BOBI-FRS-2021'; kisaAd='BOBI FRS'; baslik='Buyuk ve Orta Boy Isletmeler Icin Finansal Raporlama Standardi (2021 Surumu)'
    url='https://www.kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/BOB%C4%B0_FRS/EK%202.pdf'
    # (?:...) SART: .NET'te Regex.Split deseninde YAKALAYAN grup varsa yakalanan
    # metin de diziye eklenir. Ilk halde (...) kullanilmisti ve kapsama %100,76
    # cikti - yuzden fazla olmasi imkansiz, metin cogaliyordu. Yazmadan once
    # yakalandi; yazilsaydi ambara "6.1" gibi parca satirlar girecekti.
    bolucu='(?m)^(?=\s{0,8}(?:\d{1,2}\.\d{1,3}|BÖLÜM\s+\d{1,2}|MADDE\s+\d{1,2})\s)'; noDesen='^\s{0,8}(\d{1,2}\.\d{1,3}|BÖLÜM\s+\d{1,2}|MADDE\s+\d{1,2})' }

 # ---------------------------------------------------------------------------
 # 09.08 EKLENDI - Cem: "hepsini yut sonra kapilara devam et".
 # YUTMA-LISTESI.md'de bos kutuda kalan 7 BDS. Denetim sinavda 16 soru =
 # en yuksek agirlikli ders, bu yuzden once bunlar.
 # DESEN GERCEK METNE BAKILARAK KURULDU (tahmin degil): pdftotext -layout
 # ciktisinda paragraflar satir basinda "1." ve aciklayici paragraflar "A5."
 # bicimindedir; ikisi de tek desenle yakalanir.
 # URL'ler HEAD ile dogrulandi: 7/7 gercek PDF (677 KB - 1,3 MB), PDF imzasi
 # da bayt duzeyinde kontrol edildi. (TMS 27 / TMS 41 ayni testte 1.499 baytlik
 # HTML hata sayfasi dondurdu - LISTEYE ALINMADI, dogru URL bulunmali.)
 # ---------------------------------------------------------------------------
 # 12.08 EKLENDI: itiraf siniflandirmasi BDS 300 (13 parca ozet) ve BDS 330
 # (6 parca) ambarinin ince oldugunu gosterdi; Denetim = sinavin en agir dersi.
 # URL'ler bayt duzeyinde dogrulandi (576 KB / 1,1 MB, %PDF- imzali).
 @{ ad='BDS-300'; kisaAd='BDS 300'; baslik='Finansal Tablolarin Bagimsiz Denetiminin Planlanmasi'
    url='https://www.kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TDS/TDS_2025_Seti/BDS%20300_2025.pdf'
    bolucu='(?m)^(?=\s{0,6}A?\d{1,3}\.\s)'; noDesen='^\s{0,6}(A?\d{1,3})\.' }

 # 12.08 PARTI: cikmis-sinav talep olcumu (8.409 soru) + P2 istek listesi
 # caprazlamasindan cikan 30 ince-ambar standart. Indirme+cikarma kaniti:
 # motor/yutma-partisi-1208.ps1 ciktisi. Hepsi bayt-imza dogrulamali.
 @{ ad='TMS-10'; kisaAd='TMS 10'; baslik='Raporlama Doneminden Sonraki Olaylar'
    url='https://kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TMS_TFRS_Setleri/2022/Mavi_Kitap/TMS%2010.pdf'
    bolucu='(?m)^(?=\s{0,4}\d{1,3}\s{2,}\S)'; noDesen='^\s{0,4}(\d{1,3})\s{2,}' }
 @{ ad='TMS-12'; kisaAd='TMS 12'; baslik='Gelir Vergileri'
    url='https://kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TMS_TFRS_Setleri/2022/Mavi_Kitap/TMS%2012.pdf'
    bolucu='(?m)^(?=\s{0,4}\d{1,3}\s{2,}\S)'; noDesen='^\s{0,4}(\d{1,3})\s{2,}' }
 @{ ad='TMS-19'; kisaAd='TMS 19'; baslik='Calisanlara Saglanan Faydalar'
    url='https://kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TMS_TFRS_Setleri/2022/Mavi_Kitap/TMS%2019.pdf'
    bolucu='(?m)^(?=\s{0,4}\d{1,3}\s{2,}\S)'; noDesen='^\s{0,4}(\d{1,3})\s{2,}' }
 @{ ad='TMS-20'; kisaAd='TMS 20'; baslik='Devlet Tesviklerinin Muhasebelestirilmesi'
    url='https://kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TMS_TFRS_Setleri/2022/Mavi_Kitap/TMS%2020.pdf'
    bolucu='(?m)^(?=\s{0,4}\d{1,3}\s{2,}\S)'; noDesen='^\s{0,4}(\d{1,3})\s{2,}' }
 @{ ad='TMS-23'; kisaAd='TMS 23'; baslik='Borclanma Maliyetleri'
    url='https://kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TMS_TFRS_Setleri/2022/Mavi_Kitap/TMS%2023.pdf'
    bolucu='(?m)^(?=\s{0,4}\d{1,3}\s{2,}\S)'; noDesen='^\s{0,4}(\d{1,3})\s{2,}' }
 @{ ad='TMS-24'; kisaAd='TMS 24'; baslik='Iliskili Taraf Aciklamalari'
    url='https://kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TMS_TFRS_Setleri/2022/Mavi_Kitap/TMS%2024.pdf'
    bolucu='(?m)^(?=\s{0,4}\d{1,3}\s{2,}\S)'; noDesen='^\s{0,4}(\d{1,3})\s{2,}' }
 @{ ad='TMS-28'; kisaAd='TMS 28'; baslik='Istiraklerdeki ve Is Ortakliklarindaki Yatirimlar'
    url='https://kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TMS_TFRS_Setleri/2022/Mavi_Kitap/TMS%2028.pdf'
    bolucu='(?m)^(?=\s{0,4}\d{1,3}\s{2,}\S)'; noDesen='^\s{0,4}(\d{1,3})\s{2,}' }
 @{ ad='TMS-29'; kisaAd='TMS 29'; baslik='Yuksek Enflasyonlu Ekonomilerde Finansal Raporlama'
    url='https://kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TMS_TFRS_Setleri/2022/Mavi_Kitap/TMS%2029.pdf'
    bolucu='(?m)^(?=\s{0,4}\d{1,3}\s{2,}\S)'; noDesen='^\s{0,4}(\d{1,3})\s{2,}' }
 @{ ad='TMS-32'; kisaAd='TMS 32'; baslik='Finansal Araclar: Sunum'
    url='https://kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TMS_TFRS_Setleri/2022/Mavi_Kitap/TMS%2032.pdf'
    bolucu='(?m)^(?=\s{0,4}\d{1,3}\s{2,}\S)'; noDesen='^\s{0,4}(\d{1,3})\s{2,}' }
 @{ ad='TMS-33'; kisaAd='TMS 33'; baslik='Hisse Basina Kazanc'
    url='https://kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TMS_TFRS_Setleri/2022/Mavi_Kitap/TMS%2033.pdf'
    bolucu='(?m)^(?=\s{0,4}\d{1,3}\s{2,}\S)'; noDesen='^\s{0,4}(\d{1,3})\s{2,}' }
 @{ ad='TMS-34'; kisaAd='TMS 34'; baslik='Ara Donem Finansal Raporlama'
    url='https://kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TMS_TFRS_Setleri/2022/Mavi_Kitap/TMS%2034.pdf'
    bolucu='(?m)^(?=\s{0,4}\d{1,3}\s{2,}\S)'; noDesen='^\s{0,4}(\d{1,3})\s{2,}' }
 @{ ad='TMS-36'; kisaAd='TMS 36'; baslik='Varliklarda Deger Dusuklugu'
    url='https://kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TMS_TFRS_Setleri/2022/Mavi_Kitap/TMS%2036.pdf'
    bolucu='(?m)^(?=\s{0,4}\d{1,3}\s{2,}\S)'; noDesen='^\s{0,4}(\d{1,3})\s{2,}' }
 @{ ad='TMS-38'; kisaAd='TMS 38'; baslik='Maddi Olmayan Duran Varliklar'
    url='https://kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TMS_TFRS_Setleri/2022/Mavi_Kitap/TMS%2038.pdf'
    bolucu='(?m)^(?=\s{0,4}\d{1,3}\s{2,}\S)'; noDesen='^\s{0,4}(\d{1,3})\s{2,}' }
 @{ ad='TMS-40'; kisaAd='TMS 40'; baslik='Yatirim Amacli Gayrimenkuller'
    url='https://kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TMS_TFRS_Setleri/2022/Mavi_Kitap/TMS%2040.pdf'
    bolucu='(?m)^(?=\s{0,4}\d{1,3}\s{2,}\S)'; noDesen='^\s{0,4}(\d{1,3})\s{2,}' }
 @{ ad='TFRS-2'; kisaAd='TFRS 2'; baslik='Hisse Bazli Odemeler'
    url='https://kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TMS_TFRS_Setleri/2022/Mavi_Kitap/TFRS%202.pdf'
    bolucu='(?m)^(?=\s{0,4}\d{1,3}\s{2,}\S)'; noDesen='^\s{0,4}(\d{1,3})\s{2,}' }
 @{ ad='TFRS-3'; kisaAd='TFRS 3'; baslik='Isletme Birlesmeleri'
    url='https://kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TMS_TFRS_Setleri/2022/Mavi_Kitap/TFRS%203.pdf'
    bolucu='(?m)^(?=\s{0,4}\d{1,3}\s{2,}\S)'; noDesen='^\s{0,4}(\d{1,3})\s{2,}' }
 @{ ad='TFRS-5'; kisaAd='TFRS 5'; baslik='Satis Amacli Elde Tutulan Duran Varliklar'
    url='https://kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TMS_TFRS_Setleri/2022/Mavi_Kitap/TFRS%205.pdf'
    bolucu='(?m)^(?=\s{0,4}\d{1,3}\s{2,}\S)'; noDesen='^\s{0,4}(\d{1,3})\s{2,}' }
 @{ ad='TFRS-7'; kisaAd='TFRS 7'; baslik='Finansal Araclar: Aciklamalar'
    url='https://kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TMS_TFRS_Setleri/2022/Mavi_Kitap/TFRS%207.pdf'
    bolucu='(?m)^(?=\s{0,4}\d{1,3}\s{2,}\S)'; noDesen='^\s{0,4}(\d{1,3})\s{2,}' }
 @{ ad='TFRS-8'; kisaAd='TFRS 8'; baslik='Faaliyet Bolumleri'
    url='https://kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TMS_TFRS_Setleri/2022/Mavi_Kitap/TFRS%208.pdf'
    bolucu='(?m)^(?=\s{0,4}\d{1,3}\s{2,}\S)'; noDesen='^\s{0,4}(\d{1,3})\s{2,}' }
 @{ ad='TFRS-10'; kisaAd='TFRS 10'; baslik='Konsolide Finansal Tablolar'
    url='https://kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TMS_TFRS_Setleri/2022/Mavi_Kitap/TFRS%2010.pdf'
    bolucu='(?m)^(?=\s{0,4}\d{1,3}\s{2,}\S)'; noDesen='^\s{0,4}(\d{1,3})\s{2,}' }
 @{ ad='TFRS-11'; kisaAd='TFRS 11'; baslik='Musterek Anlasmalar'
    url='https://kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TMS_TFRS_Setleri/2022/Mavi_Kitap/TFRS%2011.pdf'
    bolucu='(?m)^(?=\s{0,4}\d{1,3}\s{2,}\S)'; noDesen='^\s{0,4}(\d{1,3})\s{2,}' }
 @{ ad='TFRS-13'; kisaAd='TFRS 13'; baslik='Gercege Uygun Deger Olcumu'
    url='https://kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TMS_TFRS_Setleri/2022/Mavi_Kitap/TFRS%2013.pdf'
    bolucu='(?m)^(?=\s{0,4}\d{1,3}\s{2,}\S)'; noDesen='^\s{0,4}(\d{1,3})\s{2,}' }
 @{ ad='BDS-210'; kisaAd='BDS 210'; baslik='Bagimsiz Denetim Sozlesmesinin Sartlari'
    url='https://www.kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TDS/TDS_2025_Seti/BDS%20210_2025.pdf'
    bolucu='(?m)^(?=\s{0,6}A?\d{1,4}\.\s)'; noDesen='^\s{0,6}(A?\d{1,4})\.' }
 @{ ad='BDS-501'; kisaAd='BDS 501'; baslik='Denetim Kanitlari - Belirli Kalemler'
    url='https://www.kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TDS/TDS_2025_Seti/BDS%20501_2025.pdf'
    bolucu='(?m)^(?=\s{0,6}A?\d{1,4}\.\s)'; noDesen='^\s{0,6}(A?\d{1,4})\.' }
 @{ ad='BDS-520'; kisaAd='BDS 520'; baslik='Analitik Prosedurler'
    url='https://www.kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TDS/TDS_2025_Seti/BDS%20520_2025.pdf'
    bolucu='(?m)^(?=\s{0,6}A?\d{1,4}\.\s)'; noDesen='^\s{0,6}(A?\d{1,4})\.' }
 @{ ad='BDS-550'; kisaAd='BDS 550'; baslik='Iliskili Taraflar'
    url='https://www.kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TDS/TDS_2025_Seti/BDS%20550_2025.pdf'
    bolucu='(?m)^(?=\s{0,6}A?\d{1,4}\.\s)'; noDesen='^\s{0,6}(A?\d{1,4})\.' }
 @{ ad='BDS-701'; kisaAd='BDS 701'; baslik='Kilit Denetim Konularinin Bildirilmesi'
    url='https://www.kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TDS/TDS_2025_Seti/BDS%20701_2025.pdf'
    bolucu='(?m)^(?=\s{0,6}A?\d{1,4}\.\s)'; noDesen='^\s{0,6}(A?\d{1,4})\.' }
 @{ ad='BDS-706'; kisaAd='BDS 706'; baslik='Dikkat Cekilen Hususlar Paragraflari'
    url='https://www.kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TDS/TDS_2025_Seti/BDS%20706_2025.pdf'
    bolucu='(?m)^(?=\s{0,6}A?\d{1,4}\.\s)'; noDesen='^\s{0,6}(A?\d{1,4})\.' }
 @{ ad='GDS-3400'; kisaAd='GDS 3400'; baslik='Ileriye Yonelik Finansal Bilgilerin Incelenmesi'
    url='https://www.kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TDS/TDS_2025_Seti/GDS%203400_2025.pdf'
    bolucu='(?m)^(?=\s{0,6}A?\d{1,4}\.\s)'; noDesen='^\s{0,6}(A?\d{1,4})\.' }
 @{ ad='GDS-3420'; kisaAd='GDS 3420'; baslik='Proforma Finansal Bilgilerin Derlenmesi'
    url='https://www.kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TDS/TDS_2025_Seti/GDS%203420_2025.pdf'
    bolucu='(?m)^(?=\s{0,6}A?\d{1,4}\.\s)'; noDesen='^\s{0,6}(A?\d{1,4})\.' }
 @{ ad='BDS-330'; kisaAd='BDS 330'; baslik='Bagimsiz Denetcinin Degerlendirilmis Risklere Karsi Yapacagi Isler'
    url='https://www.kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TDS/TDS_2025_Seti/BDS%20330_2025.pdf'
    bolucu='(?m)^(?=\s{0,6}A?\d{1,3}\.\s)'; noDesen='^\s{0,6}(A?\d{1,3})\.' }
 @{ ad='BDS-260'; kisaAd='BDS 260'; baslik='Ust Yonetimden Sorumlu Olanlarla Iletisim'
    url='https://www.kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TDS/TDS_2025_Seti/BDS%20260_2025.pdf'
    bolucu='(?m)^(?=\s{0,6}A?\d{1,3}\.\s)'; noDesen='^\s{0,6}(A?\d{1,3})\.' }
 @{ ad='BDS-265'; kisaAd='BDS 265'; baslik='Ic Kontrol Eksikliklerinin Ust Yonetimden Sorumlu Olanlara ve Yonetime Bildirilmesi'
    url='https://www.kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TDS/TDS_2025_Seti/BDS%20265_2025.pdf'
    bolucu='(?m)^(?=\s{0,6}A?\d{1,3}\.\s)'; noDesen='^\s{0,6}(A?\d{1,3})\.' }
 @{ ad='BDS-510'; kisaAd='BDS 510'; baslik='Ilk Denetimler-Acilis Bakiyeleri'
    url='https://www.kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TDS/TDS_2025_Seti/BDS%20510_2025.pdf'
    bolucu='(?m)^(?=\s{0,6}A?\d{1,3}\.\s)'; noDesen='^\s{0,6}(A?\d{1,3})\.' }
 @{ ad='BDS-540'; kisaAd='BDS 540'; baslik='Muhasebe Tahminlerinin ve Ilgili Aciklamalarin Denetimi'
    url='https://www.kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TDS/TDS_2025_Seti/BDS%20540_2025.pdf'
    bolucu='(?m)^(?=\s{0,6}A?\d{1,3}\.\s)'; noDesen='^\s{0,6}(A?\d{1,3})\.' }
 @{ ad='BDS-580'; kisaAd='BDS 580'; baslik='Yazili Beyanlar'
    url='https://www.kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TDS/TDS_2025_Seti/BDS%20580_2025.pdf'
    bolucu='(?m)^(?=\s{0,6}A?\d{1,3}\.\s)'; noDesen='^\s{0,6}(A?\d{1,3})\.' }
 @{ ad='BDS-620'; kisaAd='BDS 620'; baslik='Uzman Calismalarinin Kullanilmasi'
    url='https://www.kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TDS/TDS_2025_Seti/BDS%20620_2025.pdf'
    bolucu='(?m)^(?=\s{0,6}A?\d{1,3}\.\s)'; noDesen='^\s{0,6}(A?\d{1,3})\.' }
 @{ ad='BDS-720'; kisaAd='BDS 720'; baslik='Bagimsiz Denetcinin Diger Bilgilere Iliskin Sorumluluklari'
    url='https://www.kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TDS/TDS_2025_Seti/BDS%20720_2025.pdf'
    bolucu='(?m)^(?=\s{0,6}A?\d{1,3}\.\s)'; noDesen='^\s{0,6}(A?\d{1,3})\.' }

 # TMS 27 ve TMS 41 - 2018 seti. 2025 setinde bu ikisi YOK (denendi, 1.499
 # baytlik HTML hata sayfasi dondu). Ambardaki TMS 8/16/37 de ayni 2018
 # setinden geliyor, yani kaynak secimi tutarli. Paragraf numaralari
 # "106A" gibi harf ekli olabildigi icin desen [A-Z]? tasir.
 @{ ad='TMS-27'; kisaAd='TMS 27'; baslik='Bireysel Finansal Tablolar'
    url='https://www.kgk.gov.tr/Portalv2Uploads/files/DynamicContentFiles/T%C3%BCrkiye%20Muhasebe%20Standartlar%C4%B1/TMSTFRS2018Seti/TMS/TMS_27_2018.pdf'
    bolucu='(?m)^(?=\s{0,6}\d{1,3}[A-Z]?\.\s)'; noDesen='^\s{0,6}(\d{1,3}[A-Z]?)\.' }
 @{ ad='TMS-41'; kisaAd='TMS 41'; baslik='Tarimsal Faaliyetler'
    url='https://www.kgk.gov.tr/Portalv2Uploads/files/DynamicContentFiles/T%C3%BCrkiye%20Muhasebe%20Standartlar%C4%B1/TMSTFRS2018Seti/TMS/TMS_41_2018.pdf'
    bolucu='(?m)^(?=\s{0,6}\d{1,3}[A-Z]?\.\s)'; noDesen='^\s{0,6}(\d{1,3}[A-Z]?)\.' }

 # ---------------------------------------------------------------------------
 # 11.08 EKLENDI - Cem: "yutmayi simdi yap". Ambardaki TFRS 9 el ile secilmis
 # 11 parcaydi (36 paragraf, 16,5K krk); riskten korunma (6.x) ve 5.7 gibi
 # bolumler YOKTU. Tam standart yutuluyor.
 # URL bayt duzeyinde dogrulandi: 200, 1.684 KB, %PDF- imzasi (Mavi Kitap 2022).
 # DESEN GERCEK METNE BAKILARAK KURULDU: pdftotext -layout ciktisinda
 # paragraflar satir basinda "1.1", "3.1.1", "6.1.1" gibi NOKTALI numara +
 # bosluk tasir; bolum basliklari da ("3.1 Ilk Defa...") ayni desenle yakalanir.
 # ---------------------------------------------------------------------------
 @{ ad='TFRS-9'; kisaAd='TFRS 9'; baslik='Finansal Araclar'
    url='https://www.kgk.gov.tr/Portalv2Uploads/files/Duyurular/v2/TMS_TFRS_Setleri/2022/Mavi_Kitap/TFRS%209.pdf'
    bolucu='(?m)^(?=\s{0,6}\d{1,2}\.\d{1,3}(?:\.\d{1,3})?[A-Z]?\s)'; noDesen='^\s{0,6}(\d{1,2}\.\d{1,3}(?:\.\d{1,3})?[A-Z]?)\s' }
)
if($sadece -ne ''){ $BELGELER = @($BELGELER | Where-Object { "$($_.ad)" -like ($sadece + '*') }) }

function Sayim([string]$sorgu){
  $istek = New-Object System.Net.Http.HttpRequestMessage ([System.Net.Http.HttpMethod]::Get), ($adres+'/dokumanlar?select=id&'+$sorgu)
  $istek.Headers.TryAddWithoutValidation('Prefer','count=exact') | Out-Null
  $istek.Headers.TryAddWithoutValidation('Range','0-0') | Out-Null
  $cevap = $istemci.SendAsync($istek).GetAwaiter().GetResult()
  $aralik = ''
  if($cevap.Content.Headers.Contains('Content-Range')){ $aralik = ($cevap.Content.Headers.GetValues('Content-Range') -join '') }
  $cevap.Dispose(); $istek.Dispose()
  if($aralik -match '/(\d+)$'){ return [int]$Matches[1] }
  return -1
}
function Sil([string]$kaynakOneki){
  $kodlu = [uri]::EscapeDataString($kaynakOneki + '%')
  $istek = New-Object System.Net.Http.HttpRequestMessage ([System.Net.Http.HttpMethod]::Delete), ($adres+'/dokumanlar?kaynak_ad=like.'+$kodlu)
  $cevap = $istemci.SendAsync($istek).GetAwaiter().GetResult()
  $kod = [int]$cevap.StatusCode
  $cevap.Dispose(); $istek.Dispose()
  return $kod
}
function TopluYaz($satirlar){
  $json = ConvertTo-Json -InputObject @($satirlar) -Depth 4 -Compress
  $istek = New-Object System.Net.Http.HttpRequestMessage ([System.Net.Http.HttpMethod]::Post), ($adres+'/dokumanlar')
  $istek.Content = New-Object System.Net.Http.StringContent ($json,[Text.Encoding]::UTF8,'application/json')
  $istek.Headers.TryAddWithoutValidation('Prefer','return=minimal') | Out-Null
  $cevap = $istemci.SendAsync($istek).GetAwaiter().GetResult()
  $kod = [int]$cevap.StatusCode
  $hataMetni = ''
  if($kod -ne 201){ $hataMetni = $cevap.Content.ReadAsStringAsync().GetAwaiter().GetResult() }
  $cevap.Dispose(); $istek.Dispose()
  return @{ kod=$kod; hata=$hataMetni }
}

$rapor = New-Object System.Collections.Generic.List[object]
foreach($belge in $BELGELER){
  $metinYolu = Join-Path $kaynakDizin ($belge.ad + '.txt')
  if(-not (Test-Path $metinYolu)){ Write-Host ("ATLANDI (metin yok): " + $belge.ad); continue }
  $kaynakMetin = Get-Content $metinYolu -Raw -Encoding UTF8
  $kaynakUzunluk = $kaynakMetin.Length

  # --- BOLUMLEME: hicbir karakter atilmaz ---
  $parcalar = New-Object System.Collections.Generic.List[object]
  $dilimler = [regex]::Split($kaynakMetin, $belge.bolucu)
  $sira = 0
  foreach($dilim in $dilimler){
    if($dilim.Trim().Length -eq 0){ continue }
    $sira++
    $noEslesme = [regex]::Match($dilim, $belge.noDesen)
    $paragrafNo = if($noEslesme.Success){ $noEslesme.Groups[1].Value } else { ('giris-' + $sira) }
    $ilkSatir = (($dilim -replace '\s+',' ').Trim())
    $ozet = $ilkSatir.Substring(0, [Math]::Min(70, $ilkSatir.Length))
    $parcalar.Add([pscustomobject]@{ no=$paragrafNo; metin=$dilim; ozet=$ozet })
  }
  if($parcaTavan -gt 0 -and $parcalar.Count -gt $parcaTavan){ $parcalar = [System.Collections.Generic.List[object]]@($parcalar | Select-Object -First $parcaTavan) }

  # --- KAPSAMA OLCUMU (yazmadan once) ---
  $parcaToplamUzunluk = 0
  foreach($parca in $parcalar){ $parcaToplamUzunluk += $parca.metin.Length }
  $kapsamaOrani = [math]::Round(100*$parcaToplamUzunluk/[math]::Max($kaynakUzunluk,1),2)
  $damga = if($kapsamaOrani -ge 98){ 'TAMAM' } else { 'KIRMIZI' }
  Write-Host ("{0,-26} kaynak {1,8:N0} krk | parca {2,5} | ambara giren {3,8:N0} krk | kapsama %{4}  {5}" -f $belge.kisaAd, $kaynakUzunluk, $parcalar.Count, $parcaToplamUzunluk, $kapsamaOrani, $damga)

  $yazilan = 0; $hataliParti = 0
  if($yaz){
    $silKod = Sil ($belge.kisaAd + ' p.')
    $satirlar = New-Object System.Collections.Generic.List[object]
    foreach($parca in $parcalar){
      $satirlar.Add([ordered]@{
        id = [guid]::NewGuid().ToString()
        tur = 'kanun-madde'
        kaynak_ad = ($belge.kisaAd + ' p.' + $parca.no + ' - ' + $parca.ozet)
        baslik = ($belge.kisaAd + ' - ' + $belge.baslik)
        metin = $parca.metin
        kaynak_url = $belge.url
      })
    }
    # 200'luk partiler halinde yaz
    for($basIndeks=0; $basIndeks -lt $satirlar.Count; $basIndeks += 200){
      $parti = @($satirlar | Select-Object -Skip $basIndeks -First 200)
      $sonuc = TopluYaz $parti
      if($sonuc.kod -eq 201){ $yazilan += $parti.Count }
      else {
        $hataliParti++
        Write-Host ("   parti {0} dustu (kod {1}) - satir satir deneniyor" -f $basIndeks, $sonuc.kod)
        foreach($tekSatir in $parti){
          $tekSonuc = TopluYaz @($tekSatir)
          if($tekSonuc.kod -eq 201){ $yazilan++ }
        }
      }
    }
    Write-Host ("   -> ambara yazilan: {0} / {1}" -f $yazilan, $satirlar.Count)
  }
  $rapor.Add([pscustomobject]@{ belge=$belge.kisaAd; kaynakKarakter=$kaynakUzunluk; parca=$parcalar.Count; ambarKarakter=$parcaToplamUzunluk; kapsama=$kapsamaOrani; damga=$damga; yazilan=$yazilan })
}

if($yaz){
  Write-Host ("`n--- AMBAR SON DURUM ---")
  foreach($belge in $BELGELER){
    $kodlu = [uri]::EscapeDataString($belge.kisaAd + ' p.%')
    Write-Host ("   {0,-26} {1}" -f $belge.kisaAd, (Sayim ('kaynak_ad=like.'+$kodlu)))
  }
}
[IO.File]::WriteAllText((Join-Path $projeDizin 'veri\standart-yutma.json'),
  (ConvertTo-Json -InputObject ([ordered]@{ tarih=(Get-Date -Format 'dd.MM.yyyy HH:mm'); kayitlar=$rapor.ToArray() }) -Depth 4),
  (New-Object Text.UTF8Encoding($false)))
Write-Host "`nKanit: veri/standart-yutma.json"
