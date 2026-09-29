/* ============================================================================
   TETİKTE FİYAT MOTORU — TEK GERÇEK KAYNAK
   Kuruldu 21.08.2026 · Baştan yazıldı 29.08.2026 (Cem onayı: "onay")

   ⚠️ RAKAM DEĞİŞTİRİLECEKSE YALNIZ BURADAN DEĞİŞİR.
   fiyat.html · satin-al.html · radar-fiyat.html üçü de buradan okur;
   birine elle rakam yazmak sayfaları ayırır.

   29.08 KARARLARI (fiyat oturumu, ölçümlü):
   1) GÜN MERDİVENİ KALKTI. Eski yapı sınava kalan güne göre fiyatı kendiliğinden
      yükseltiyordu; 29.08'de patladı (kutu 2.190 yazarken manşet 1.790 diyordu).
      Yerine ÜYE KOTASI: ilk N üye kuruluş fiyatı, sonrası liste fiyatı.
      Kotayı biz kontrol ederiz, sessizce tetiklenmez.
   2) SÜRE 3 AY (90 gün), sınav gününe bağlı değil. Sebep: "sınava kadar" derken
      sınava 20 gün kala alan aynı parayı ödeyip 20 gün alıyordu.
      Açık kapatan kural: paket en yakın sınavı kapsamıyorsa ücretsiz uzatılır.
   3) İKİ DÖNEMLİK PAKET SATILMIYOR. Piyasanın tamamı (Suat 20.000 ikili,
      Prensip 11.000 iki dönem, Deha 8de8 29.250) adayın kalacağını varsayıyor.
      Biz varsaymıyoruz. (25.09 Cem: ikinci dönem %50 ve üst sınav %30 sözleri kaldırıldı — uygulayan mekanizma yoktu.)
   4) DERS/MODÜL BAZLI SATIŞ. Yeterlilik'te ders ders kalınıyor; kaldığı 2 dersi
      olan adama 8 derslik paket satmak onu dışarıda bırakıyordu.
   5) İÇERİK KADEMESİ YOK. Ucuz pakette de konu notu ve madde bağı var —
      farkımızı göstermeyen paket, bedava rakibin kopyası olur.

   ⚠️ Sınav tarihi ROBOTLA DEĞİŞTİRİLMEZ; elle teyitle güncellenir.
   ============================================================================ */

var KDV_ORAN = 0.20;

/* Tarihler TÜRMOB 2026 resmî sınav takviminden (22.07.2026'da okundu).
   KGK Kasım 2026 sınavının kesin günü henüz İLAN EDİLMEDİ — teyitsiz tarih yazılmaz. */
var SINAVLAR = [
  { ad:'Staja Başlama', tarih:'2026-11-21', yazi:'21 Kasım 2026', anahtar:'sgs' },
  { ad:'Yeterlilik',    tarih:'2026-11-28', yazi:'28 Kasım 2026', anahtar:'yeterlilik' }
];

/* ---------------------------------------------------------------------------
   RESMÎ HARÇLAR — fiyat argümanımızın belkemiği. Hepsi BİRİNCİL kaynaktan,
   29.08.2026'da yeniden okundu. Sayfa bu rakamları kendisi yazar; elle
   kopyalanmaz (eskiyince tek yerden güncellenir).
   Kaynak 1: TESMER 2026 Yılı Sınav ve Eğitim Ücretleri (kendi PDF'i)
   Kaynak 2: KGK 2026 Ücret Listesi (29.12.2025 tarihli Kurul kararı)
--------------------------------------------------------------------------- */
var HARC = {
  sgs:        { basvuru:1635, itiraz:820 },
  yeterlilik: { ilkBasvuru:10080, ders:1260, itiraz:910 },
  /* KGK sınavı a-g konu yapısındadır. TEMEL ALAN = a-d (4 konu); e/f/g
     (sermaye piyasası · bankacılık · sigortacılık) EK ALANLARDIR ve ayrı
     yetki içindir. Ürünümüz temel alandır → çapa 4 konu, 7 değil.
     ⚠️ KGK'da harç ÇAPA OLARAK ZAYIFTIR (4 konu e-sınav 3.800 TL, bizim
     tüm modüller 3.990 TL). Bu yüzden KGK'nın satış çapası harç değil KURS
     fiyatıdır: 29.08 ölçümü — Suat Hoca tam paket 13.500, modül 5.250;
     Deha online full 15.120. Harç bilgi olarak yazılır, "ucuzuz" iddiası
     KURULMAZ. Yeterlilik'te tersi geçerli: orada her basamak harçtan ucuz. */
  kgk:        { konu:565, konuESinav:950, belge:1885, temelAlanKonu:4, ekAlanKonu:3 },
  diger:      { stajDosya:10500, zorunluEgitim:7890, stajyerKimlik:1540 }
};
var HARC_KAYNAK = {
  tesmer:'https://www.tesmer.org.tr/wp-content/uploads/2024/12/TESMER_2026_yili_ucretler-2.pdf',
  tesmerTarih:'29.08.2026',
  kgk:'https://www.alomaliye.com/2026/01/03/2026-yili-kamu-gozetimi-kurumu-hizmetlere-iliskin-ucret-listesi/',
  kgkTarih:'29.08.2026'
};

/* ---------------------------------------------------------------------------
   KOTA — kurucu fiyatının bitiş şartı. Kota dolunca fiyat liste fiyatına ÇIKAR — bu bir söz,
   tutulmazsa "üstü çizili sahte fiyat" yapmış oluruz (Ticari Reklam ve HTU Yön. m.14 + Ek A-7).
   27.09.2026 CEM KARARI: SGS ve Yeterlilik'te "ilk 1.000 kurucu" (sınav başına ayrı sayılır,
   yalnız ÖDEYEN: siparisler durum='odendi' + magaza_siparis verildi/tuketildi).
   Sayaç 27.09'dan beri EKRANDA GÖSTERİLİR ama yalnız sunucu gerçek sayıyı verirse
   (rpc kurucu_sayac, radar-app/sql/2026-09-27-kurucu-sayac.sql). Sunucu yanıt vermezse satır
   HİÇ çizilmez — tahmini/uydurma sayı yazılmaz.
--------------------------------------------------------------------------- */
var KOTA = { sgs:1000, yeterlilik:1000, kgk:150, radar:300, kurucu:100 };

/* Erişim: en az 3 ay VE en yakın sınavın gününe kadar (hangisi geçse). 25.09'dan beri vitrinde 'sınava kadar' yazılır. */
var SURE_GUN = 90;

/* Kart ödemesi açıldığında true yapılır — taksit satırları o zaman görünür.
   Bugün havale/EFT var, taksit YOK; kapalıyken hiçbir yerde taksit yazmaz. */
var TAKSIT_ACIK = false;
var TAKSIT_ADET = 3;

/* ---------------------------------------------------------------------------
   ELÇİ KODU — 15.09.2026 Cem kararı: elçi koduyla alan takipçiye SGS'de 400 TL
   indirim; 25.09'da 480'e çıkmıştı, 27.09 CEM KARARIYLA yine 400 TL KDV dahil (2.995 → 2.595). İndirimin geçerliliğine SUNUCU karar verir
   (radar-app/sql/2026-09-15-elci-programi.sql · siparis_elci_damga); buradaki
   rakam yalnız EKRAN gösterimidir ve sunucudaki elci_indirim tablosuyla AYNI olmalı.
   acik=false iken satin-al.html'de kod alanı HİÇ görünmez: SQL basılmadan
   açılırsa takipçi indirimi ekranda görür ama sipariş indirimsiz yazılır.
   SQL basılıp doğrulandıktan sonra true yapılır.
   29.09: Yeterlilik TÜM DERSLER de 400 TL (27.09 Cem: 3.490 → 3.090); 1–4 ders merdiveni indirimsiz
   (1 derste 1.190 − 400 − 750 komisyon zarar yazar). Sunucudaki elci_indirim ile birebir.
   Elçiler kendi panelinden (elci.html) satış adedini ve komisyonunu görür.
   29.09 AÇILDI: SQL Cem tarafından basıldı; anonim ölçüm AE42 → sgs 400 · yeterlilik-tum 400 · yeterlilik-1 0
   (bu nesneyle birebir), panel fonksiyonları anona 401. Site aynı akşam yayına girdi (GONG f28cf522).
--------------------------------------------------------------------------- */
var ELCI = { acik:true, indirim:{ sgs:400, 'yeterlilik-tum':400 }, bicim:/^[A-Z0-9]{3,12}$/ };

/* ---------------------------------------------------------------------------
   İÇERİK HAZIR MI — 15.09.2026 CEM KARARI ("1.2.3 yap"): soru sayfası yayında
   olmayan sınavın paketi SATILMAZ, ÖN KAYIT alınır. Ölçüm 15.09: sitede soru
   bankası, ücretsiz deneme ve seviye testi yalnız Staja Başlama için var;
   Yeterlilik ve KGK paketleri satışta görünüyordu ama alan kişinin girecek
   sayfası yoktu (kasada soru var, yayında sayfa yok).
   false iken: satin-al.html bu paketleri listelemez · fiyat.html düğmesi
   "Ön kayıt ol" olur (ucretsiz-dene.html?sinav=...#onkayit) · ana sayfa ön kayda
   yönlendirir (uye-durumu.js SINAVLAR.icerik ile AYNI tutulur).
   Sayfalar yayına girince true yapılır; iki dosya birlikte değişir.
--------------------------------------------------------------------------- */
/* 24.09 Cem ("bu da satışta" + "1.2.3 ÜÇÜNÜ DE YAP"): Yeterlilik SATIŞA AÇILDI. Dayanak: kaydir/smmm 8 ders sayfası
   yayında (18.09), paket-kapisi.js yeterlilik paketine açıyor, paket_soru kasası basılı (16.09). uye-durumu.js ile AYNI commit. */
var ICERIK_HAZIR = { sgs:true, yeterlilik:true, kgk:false };

/* ---------------------------------------------------------------------------
   KDV HARİÇ GÖSTERİM — 25.09.2026 CEM KARARI ("sitede artı KDV olarak yazalım, KDV'siz fiyatı görelim").
   Risk Cem'e iki kez yazıldı: 6502 m.54 + Fiyat Etiketi Yönetmeliği tüketiciye tüm vergiler dahil tutar
   gösterilmesini ister. Riski küçültmek için KDV dahil toplam HER YERDE hemen altında yazar; ödeme özeti
   KDV dahildir. Yalnız SGS: diğer paketler KDV dahil yuvarlak kuruldu (1.190 → '991,67 + KDV' olurdu).
   Kapatmak için sgs:false yeter; sayfalar bu iki yardımcıyı okur.
   27.09.2026 CEM KARARI ("tamam bu fiyatları uygula"): KAPATILDI. Ana rakam KDV dahil yazılır —
   Ticari Reklam ve HTU Yön. m.13/2 "reklamda fiyat tüm vergiler dahil toplam satış fiyatı" (resmî metin
   26.09'da mevzuat.gov.tr'den okundu). Rakiplerin bir kısmı '+KDV' yazıyor; bu bizim için kıyas avantajı.
--------------------------------------------------------------------------- */
var KDV_HARIC_GOSTER = { sgs:false };
function fiyatAna(id, n){ return KDV_HARIC_GOSTER[id] ? tl(Math.round(n / (1 + KDV_ORAN))) + ' TL + KDV' : tl(n) + ' TL'; }
function fiyatDahilNot(id, n){ return KDV_HARIC_GOSTER[id] ? 'KDV dahil ' + tl(n) + ' TL' : ''; }

/* ---------------------------------------------------------------------------
   FİYATLAR — kuruluş / liste çifti. TL, KDV DAHİL (sınav tarafı). Rakamlar hep KDV dahil tutulur;
   ekranda SGS 25.09'dan beri '+ KDV' gösterilir (KDV_HARIC_GOSTER), hesap değişmez.
   Sınav tarafı KDV dahil olmak ZORUNDA: 6502 m.54 + Fiyat Etiketi Yönetmeliği,
   tüketiciye satışta tüm vergiler dahil tek tutar gösterilir.
--------------------------------------------------------------------------- */
var FIYAT = {
  /* 15.09.2026 CEM KARARI: "1.990 + KDV" → etikette 2.390 (KDV dahil); liste 2.490 + KDV → 2.990.
     Gerekçe: rakip taraması (58 kurum) — uygulamalar 499, kurslar 4.500+; "ucuz = kalitesiz" algısı olmasın.
     Yeterlilik ve KGK bilerek DEĞİŞMEDİ (Cem: "bitirme ve KGK aynı kalsın").
     15.09 aksam GUNCELLEME (Cem onayi): kurulus 2.590. Elci koduyla 400 TL indirim -> takipci 2.190 oder.
     Kodsuz alan 2.590 oder; elci satisinda bize kalan ayni (2.190 uzerinden).
     25.09.2026 CEM KARARI: kurulus 3.390 (2.825 + KDV) / liste 3.990. Hedef: elci kodlu satista
     (3.390 - 400 = 2.990) 1.000 TL komisyon, %5 kart kesintisi ve %25 KV sonrasi bize 1.007 TL kalsin;
     elcisiz satista 1.992 TL. Etikette KDV dahil tutar buyuk, altinda 'KDV haric' kucuk (6502 m.54).
     25.09.2026 (aksam) CEM KARARI 'F isle': kurulus 2.590 + KDV = 3.108 (ilk 500) / liste 2.990 + KDV = 3.588.
     Elci kodu 400 + KDV = 480 TL -> takipci 2.190 + KDV = 2.628 oder. Kart acilinca 3 taksit (ayda 1.036 / 1.196).
     Rapor: Masaustu Tetikte-SGS-Fiyat-Raporu-20260925-v2.xlsx (1.000 uyede ~1,69 milyon TL net, %8 taksit komisyonuyla).
     Bant gerekcesi: uygulamalar 400-2.000, video 4.500-7.700 -> 3.108 uygulama rafinin ustunde, 'ucuz' okunmaz.
     27.09.2026 CEM KARARI ("tamam bu fiyatları uygula"): KURUCU 1.000 + LİSTE İKİ KATI. SGS kurucu 2.995 (ilk 1.000
     ödeyen) / liste 5.990; Yeterlilik merdiveninin listesi kurucu × 2 (tüm dersler 3.490 / 6.990). Hepsi KDV dahil.
     Liste fiyatı gerçekten uygulanacak fiyattır (video paketleri 5.900'e, canlı kurslar 8.500-14.000'e çıkıyor);
     'yüzde 50 indirim' DENMEZ (o fiyattan satış yapılmadı, m.14/3) -> '1.000 kurucudan sonra 5.990 TL' denir.
     Kalan (elçisiz, KDV + %8 kart + %25 KV sonrası): 2.995 -> ~1.690 · 5.990 -> ~3.380 · elçili 750 komisyonla ~900. */
  sgs:            { kurulus:2995, liste:5990 },
  /* Yeterlilik ders merdiveni — her basamak RESMÎ HARÇTAN UCUZ:
     1 ders 1.190 < 1.260 · 2 ders 1.990 < 2.520 · 3 ders 2.590 < 3.780
     4 ders 3.090 < 5.040 · tüm dersler 3.490 < 10.080
     ⚠ 27.09: liste (kurucu x 2) harçtan PAHALI; 'harçtan ucuz' cümlesi yalnız kurucu fiyatı için doğrudur. */
  yeterlilik:     [ null, {kurulus:1190,liste:2390}, {kurulus:1990,liste:3990},
                          {kurulus:2590,liste:5190}, {kurulus:3090,liste:6190} ],
  yeterlilikTum:  { kurulus:3490, liste:6990 },
  /* KGK modül merdiveni — çapa e-sınav harcı: 7 konu × 950 = 6.650 TL */
  kgk:            [ null, {kurulus:1490,liste:1990}, {kurulus:2490,liste:3290},
                          {kurulus:3190,liste:4190} ],
  kgkTum:         { kurulus:3990, liste:5490 },
  yeterlilikKgk:  { kurulus:5990, liste:8490 },
  son15:          { kurulus:890,  liste:890  }
};

/* ---------------------------------------------------------------------------
   RADAR — B2B, fiyatlar KDV HARİÇ yazılır (piyasa normu: rakip de "8.000+KDV"
   diyor) ama etikette KDV dahil karşılığı da gösterilir; tüketici de satın
   alabildiği için Fiyat Etiketi Yönetmeliği bunu gerektirir.
   Alıcı KDV'yi indirdiği için gerçek maliyeti değişmez, net gelirimiz %20 artar.
--------------------------------------------------------------------------- */
var RADAR = {
  tekFirma:  { ay:{kurulus:299, liste:399},  yil:{kurulus:2990, liste:3990},  kota:KOTA.radar },
  tekRadar:  { ay:{kurulus:599, liste:799},  yil:{kurulus:5990, liste:7990},  kota:KOTA.radar },
  tamPaket:  { ay:{kurulus:999, liste:1299}, yil:{kurulus:9990, liste:12990}, kota:KOTA.radar },
  /* KURUCU: "ömür boyu 599 SABİT" sözü 29.08'de KALDIRILDI.
     Sebep 1 — enflasyon: TÜİK Temmuz 2026 yıllık TÜFE %31,75. 599 TL beş yılda
     bugünkü parayla ~151 TL'ye, on yılda ~38 TL'ye düşer.
     Sebep 2 — hukuk: Abonelik Sözleşmeleri Yönetmeliği, taahhüt süresince
     tüketici aleyhine değişiklik yasak. "Ömür boyu sabit" yazarsak fiyatı
     HİÇBİR ZAMAN artıramayız.
     Yerine: 3 yıl nominal sabit, sonrasında ömür boyu liste fiyatının %46'sı
     (yani kalıcı %54 indirim) — rakam eskimez, indirim eskimez. */
  kurucu:    { ay:{kurulus:599, liste:1299}, sabitYil:3, omurBoyuOran:0.46, kota:KOTA.kurucu }
};

/* RADAR ABONELİK PLANLARI — radar-fiyat.html sipariş formu bunu okur (29.09, iyzico "aboneliği
   düzenleyin"). id siparisler.paket'e yazılır (<=40 karakter). Rakam YOK; hepsi RADAR'dan.
   kdvHaric = sipariş anındaki fiyat, liste = kota dolunca geçilecek fiyat. */
function radarPlanlari(){
  var P = [
    ['radar-tam-ay',     'Tam Paket',               RADAR.tamPaket, 'ay'],
    ['radar-tam-yil',    'Tam Paket',               RADAR.tamPaket, 'yil'],
    ['radar-tek-ay',     'Tek Radar',               RADAR.tekRadar, 'ay'],
    ['radar-tek-yil',    'Tek Radar',               RADAR.tekRadar, 'yil'],
    ['radar-firma-ay',   'Tek Firma',               RADAR.tekFirma, 'ay'],
    ['radar-firma-yil',  'Tek Firma',               RADAR.tekFirma, 'yil'],
    ['radar-kurucu-ay',  'Tam Paket · Kurucu fiyatı', RADAR.kurucu, 'ay']
  ];
  return P.map(function(x){
    var f = x[2][x[3]];
    return { id:x[0], ad:x[1], donem:x[3], donemAd:(x[3] === 'ay' ? 'Aylık' : 'Yıllık'),
             ay:(x[3] === 'ay' ? 1 : 12), kdvHaric:f.kurulus, liste:f.liste,
             kdvDahil:kdvDahil(f.kurulus), tekRadar:(x[2] === RADAR.tekRadar) };
  });
}
function radarPlanBul(id){ return radarPlanlari().filter(function(p){ return p.id === id; })[0] || null; }

/* BANKA — havale/EFT ödeme bilgisi, TEK YER (29.09'a dek satin-al.html içindeydi; radar abonelik
   formu da aynısını gösterdiği için buraya taşındı). IBAN '[' içerirse sipariş düğmeleri kapalı kalır.
   Ad ODEME_BANKA: 'BANKA' deneme.html ve kaydir/ sayfalarında SORU dizisinin adı, bu dosya oralarda da yüklenir. */
var ODEME_BANKA = {
  ad:   'VakıfBank',
  iban: 'TR74 0001 5001 5800 7376 2710 72'
};

/* ---------------------------------------------------------------------------
   DERS / MODÜL LİSTELERİ — ders bazlı satışın karşılığı.
   "2 ders" satmak yetmez; HANGİ iki ders olduğunu satın alma anında sormak
   zorundayız, yoksa erişimi neye açacağımızı bilemeyiz.
   Yeterlilik sekiz dersi 29.08.2026'da iki rakibin kendi sınav sayfasından
   birebir okundu (Fuat Hoca YTR 2026/3 · Suat Hoca Yeterlilik 2026-3).
   KGK dört modülü kendi vitrinimizde ilan ettiğimiz temel alan kapsamıdır.
--------------------------------------------------------------------------- */
var DERSLER = {
  yeterlilik: ['Finansal Muhasebe','Maliyet Muhasebesi','Finansal Tablolar ve Analizi',
               'Muhasebe Denetimi','Vergi Mevzuatı ve Uygulaması','Temel Hukuk',
               'Sermaye Piyasası Mevzuatı','Meslek Hukuku'],
  /* ⚠️ 29.08 DÜZELTMESİ — KGK konuları KGK'nın kendi sayfasından okundu
     (kgk.gov.tr/DynamicContentDetail/6617 ve /6618, 29.08.2026):
       SMMM'ler DÖRT konudan sorumlu: (a) Muhasebe Standartları,
       (b) Kurumsal Yönetim İlkeleri ve Finansal Yönetim, (c) Denetim,
       (d) Sermaye Piyasası/Bankacılık/Sigortacılık/Özel Emeklilik Mevzuatı
       — ve (d) için "bu sektörlerde denetim yapmayacaklar MUAFTIR".
       Yani tipik SMMM fiilen ÜÇ konudan sınava giriyor.
       YMM'ler ÜÇ konudan sorumlu: (a) Muhasebe Standartları, (b) Denetim,
       (c) sektör mevzuatı — aynı muafiyetle fiilen İKİ konu.
     Önceki liste YANLIŞTI: "Kurumsal Yönetim İlkeleri" ile "Finansal Yönetim"
     iki ayrı modül sanılmıştı; KGK'da bunlar TEK konudur. Sektör mevzuatı ise
     listede hiç yoktu. Dört modüllük kapsam sayısı doğruydu, içeriği değildi. */
  kgk:        ['Muhasebe Standartları (TMS)',
               'Kurumsal Yönetim İlkeleri ve Finansal Yönetim',
               'Denetim (TDS · etik · bağımsızlık · iç kontrol)',
               'Sermaye Piyasası, Bankacılık, Sigortacılık ve Özel Emeklilik Mevzuatı']
};

/* Kime hangi konular düşüyor — satın alma ekranı bunu kendisi söylesin ki
   adam "ben kaç konu alacağım" diye aramasın. Kaynak: kgk.gov.tr (yukarıda). */
var KGK_SORUMLULUK = [
  { kim:'SMMM',                 konu:3, not:'sektör mevzuatı hariç (o sektörlerde denetim yapmayacaksan muafsın)' },
  { kim:'SMMM · sektör denetimi', konu:4, not:'sermaye piyasası, bankacılık veya sigortacılık denetimi yapacaksan' },
  { kim:'YMM',                  konu:2, not:'sektör mevzuatı hariç' },
  { kim:'YMM · sektör denetimi',  konu:3, not:'sektör mevzuatı dahil' }
];

/* ---------------------------------------------------------------------------
   YARDIMCILAR
--------------------------------------------------------------------------- */
function tl(n){ return Number(n).toLocaleString('tr-TR'); }
function kdvDahil(net){ return Math.round(net * (1 + KDV_ORAN) * 100) / 100; }
function kdvDahilYazi(net){
  var d = kdvDahil(net);
  return d.toLocaleString('tr-TR', {minimumFractionDigits:2, maximumFractionDigits:2});
}
function indirimYuzde(kurulus, liste){
  if(!liste || liste <= kurulus) return 0;
  return Math.round((1 - kurulus / liste) * 100);
}
function gunFarki(t){
  var s = new Date(t + 'T09:00:00+03:00');
  return Math.ceil((s - new Date()) / 86400000);
}
function sinav(anahtar){
  return SINAVLAR.filter(function(x){ return x.anahtar === anahtar; })[0] || null;
}
function taksitYazi(fiyat){
  if(!TAKSIT_ACIK) return '';
  return TAKSIT_ADET + ' taksitle aylık ' + tl(Math.round(fiyat / TAKSIT_ADET)) + ' TL';
}

/* Erişimin biteceği gün: 90 gün, AMA en yakın sınavı kapsamıyorsa sınavdan
   3 gün sonrasına uzatılır. Bu bir söz: "paketin en yakın sınavı kapsamıyorsa
   ücretsiz uzatılır." Sayfa da satın alma ekranı da aynı fonksiyonu kullanır. */
function bitisTarihi(anahtar, baslangic){
  var b = baslangic ? new Date(baslangic) : new Date();
  var normal = new Date(b.getTime() + SURE_GUN * 86400000);
  var s = sinav(anahtar);
  if(!s) return normal;
  var sg = new Date(s.tarih + 'T09:00:00+03:00');
  if(sg < b) return normal;                       /* sınav geçmiş: normal süre */
  var uzatilmis = new Date(sg.getTime() + 3 * 86400000);
  return uzatilmis > normal ? uzatilmis : normal;
}
function sinaviKapsiyorMu(anahtar, baslangic){
  var b = baslangic ? new Date(baslangic) : new Date();
  var s = sinav(anahtar);
  if(!s) return null;                             /* tarihi ilan edilmemiş */
  var sg = new Date(s.tarih + 'T09:00:00+03:00');
  if(sg < b) return false;
  return sg <= new Date(b.getTime() + SURE_GUN * 86400000);
}
function erisimYazi(anahtar){
  var bit = bitisTarihi(anahtar);
  var kaps = sinaviKapsiyorMu(anahtar);
  var t = bit.toLocaleDateString('tr-TR', {day:'numeric', month:'long', year:'numeric'});
  var s = sinav(anahtar);
  /* 25.09 Cem: pazarın dili 'sınava kadar' (rakiplerin 4/4'ü). Kural DEĞİŞMEDİ: bitiş = max(90 gün, sınav+3 gün);
     25.09 akşam Cem ("aralığa kadar değil sınava kadar"): vitrinde YALNIZ sınav tarihi yazar, 90 günlük
     bitiş tarihi gösterilmez. Kural yine aynı; sınava az kala alana verilen fazladan süre sessiz kalır. */
  var sg = s ? new Date(s.tarih + 'T09:00:00+03:00') : null;
  if(s && sg >= new Date()){ return s.yazi + ' sınavına kadar'; }
  return 'Sınavına kadar · en az 3 ay (' + t + ')';
}

/* ---------------------------------------------------------------------------
   SATILABİLİR PAKETLER — satin-al.html'in ürün listesi buradan doğar.
   Bir paket burada yoksa SATILMAZ.
   `acik:false` olan paket listede görünür ama satın alınamaz — içeriği
   hazır olmayan paket satılmaz (dolu görünen boş paket satmayız).
--------------------------------------------------------------------------- */
function paketler(){
  var L = [];

  L.push({ id:'sgs', grup:'Staja Başlama (SGS)', ad:'Staja Başlama — soru bankası',
           fiyat:FIYAT.sgs.kurulus, liste:FIYAT.sgs.liste, kota:KOTA.sgs,
           erisim:erisimYazi('sgs'), sinav:'sgs',
           harcYazi:'Sınav başvuru bedeli ' + tl(HARC.sgs.basvuru) + ' TL', acik:true });

  for(var n = 1; n <= 4; n++){
    L.push({ id:'yeterlilik-' + n, grup:'SMMM Yeterlilik',
             ad:'Yeterlilik — ' + n + ' ders', ders:n,
             fiyat:FIYAT.yeterlilik[n].kurulus, liste:FIYAT.yeterlilik[n].liste,
             kota:KOTA.yeterlilik, erisim:erisimYazi('yeterlilik'), sinav:'yeterlilik',
             harcYazi:n + ' dersin harcı ' + tl(HARC.yeterlilik.ders * n) + ' TL', acik:ICERIK_HAZIR.yeterlilik });
  }
  L.push({ id:'yeterlilik-tum', grup:'SMMM Yeterlilik', ad:'Yeterlilik — tüm dersler', ders:8,
           fiyat:FIYAT.yeterlilikTum.kurulus, liste:FIYAT.yeterlilikTum.liste,
           kota:KOTA.yeterlilik, erisim:erisimYazi('yeterlilik'), sinav:'yeterlilik',
           harcYazi:'İlk başvuru harcı ' + tl(HARC.yeterlilik.ilkBasvuru) + ' TL', acik:ICERIK_HAZIR.yeterlilik });

  /* KGK'da harç çapası kullanılmaz (yukarıdaki nota bak); satır KURS fiyatını
     gösterir — 29.08'de rakiplerin kendi sitelerinden ölçüldü. */
  /* KGK paketleri KONU SAYISINA göre değil, KİME göre adlandırılır — çünkü
     alıcı "kaç modül lazım" diye değil "ben SMMM'yim, ne almalıyım" diye
     bakıyor. SMMM 3, YMM 2 konudan sorumlu (muafiyet: sektör mevzuatı).
     Harç çapası KGK'da kullanılmaz; satır KURS fiyatını gösterir. */
  var KGK_ADLAR = {
    1:'KGK — tek konu',
    2:'KGK — YMM paketi (2 konu)',
    3:'KGK — SMMM paketi (3 konu)'
  };
  var KGK_KIM = {
    1:'Kaldığın tek konu için',
    2:'YMM ruhsatlısına düşen kapsam',
    3:'SMMM ruhsatlısına düşen kapsam — en çok alınan'
  };
  for(var m = 1; m <= 3; m++){
    L.push({ id:'kgk-' + m, grup:'Bağımsız Denetçilik (KGK)',
             ad:KGK_ADLAR[m], kim:KGK_KIM[m], modul:m,
             fiyat:FIYAT.kgk[m].kurulus, liste:FIYAT.kgk[m].liste,
             kota:KOTA.kgk, erisim:'Sınavına kadar · en az 3 ay', sinav:null,
             /* 15.09.2026 ölçümü (kurumların kendi siteleri): modül başına kurs
                5.250 (Suat Hoca) · 7.250+KDV (Fuat Hoca, kayıttan) · 10.800 (Piyasa Okulu)
                · 12.600+KDV (Deha) · 13.500 (Uğurlu). Eski "2.500 – 5.250" ek alan
                modüllerini de sayıyordu, temel alan konusu için yanıltıcıydı. */
             harcYazi:'Piyasada konu başına kurs 5.250 TL\'den başlıyor', acik:ICERIK_HAZIR.kgk });
  }
  L.push({ id:'kgk-tum', grup:'Bağımsız Denetçilik (KGK)',
           ad:'KGK — dört konunun tamamı', modul:HARC.kgk.temelAlanKonu,
           kim:'Sektör mevzuatından da sorumluysan',
           fiyat:FIYAT.kgkTum.kurulus, liste:FIYAT.kgkTum.liste,
           kota:KOTA.kgk, erisim:'Sınavına kadar · en az 3 ay', sinav:null,
           harcYazi:'Piyasada tam paket kursu 13.500 – 15.120 TL', acik:ICERIK_HAZIR.kgk });

  L.push({ id:'yeterlilik-kgk', grup:'Bağımsız Denetçilik (KGK)',
           ad:'Yeterlilik + KGK', fiyat:FIYAT.yeterlilikKgk.kurulus, liste:FIYAT.yeterlilikKgk.liste,
           kota:KOTA.kgk, erisim:'İki sınava da kadar · en az 3 ay', sinav:null,
           harcYazi:'Ayrı ayrı ' + tl(FIYAT.yeterlilikTum.kurulus + FIYAT.kgkTum.kurulus) + ' TL',
           acik:(ICERIK_HAZIR.yeterlilik && ICERIK_HAZIR.kgk) });

  L.push({ id:'son15', grup:'Ek', ad:'Son 15 Gün planı',
           fiyat:FIYAT.son15.kurulus, liste:FIYAT.son15.liste, kota:null,
           erisim:'Sınavdan 15 gün önce açılır', sinav:null,
           harcYazi:'Paketlere dahildir; tek de alınır', acik:true });

  /* Ortak alanlar */
  L.forEach(function(p){
    p.indirim = indirimYuzde(p.fiyat, p.liste);
    /* 25.09 Cem: yüzde rozeti kaldırıldı. Liste fiyatı ÜSTÜ ÇİZİLİ de gösterilmez: o fiyattan hiç satış yapılmadı,
     çizili 'eski fiyat' İndirimli Satış mevzuatında sahte indirim sayılır (29.08 dersi 6). Liste ileriye dönük yazılır. */
  p.not     = (p.liste > p.fiyat && p.kota) ? 'kurucu fiyatı · ilk ' + tl(p.kota) + ' kurucu' : (p.indirim ? 'kurucu fiyatı' : 'sabit fiyat');
    p.taksit  = taksitYazi(p.fiyat);
  });
  return L;
}
function paketBul(id){
  return paketler().filter(function(p){ return p.id === id; })[0] || null;
}
function acikPaketler(){ return paketler().filter(function(p){ return p.acik; }); }

/* ---------------------------------------------------------------------------
   KURUCU SAYACI — 27.09.2026. Kalan kurucu yerini SUNUCUDAN okur (yalnız sayı döner,
   kişi verisi yok). Sunucu yanıt vermezse / fonksiyon basılmamışsa cb(null) → sayfa
   satırı HİÇ çizmez. Tek istek, sayfa başına önbellekli.
   cb(kalanlar) → { sgs: 873, yeterlilik: 1000 } (0'ın altına inmez)
--------------------------------------------------------------------------- */
var KURUCU_SB = { url:'https://bjrleanjpyujtajmazxn.supabase.co', key:'sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg' };
var __kurucuSoz = null;
function kurucuKalan(cb){
  if(!__kurucuSoz){
    __kurucuSoz = (typeof fetch !== 'function') ? Promise.resolve(null) :
      fetch(KURUCU_SB.url + '/rest/v1/rpc/kurucu_sayac', { method:'POST',
        headers:{ apikey:KURUCU_SB.key, Authorization:'Bearer ' + KURUCU_SB.key, 'Content-Type':'application/json' }, body:'{}' })
      .then(function(r){ return r.ok ? r.json() : null; })
      .then(function(d){
        if(!Array.isArray(d)) return null;
        var o = {}, n = 0;
        d.forEach(function(x){
          if(x && KOTA[x.sinav] && typeof x.satilan === 'number'){ o[x.sinav] = Math.max(0, KOTA[x.sinav] - x.satilan); n++; }
        });
        ['sgs','yeterlilik'].forEach(function(k){ if(!(k in o)) o[k] = KOTA[k]; });
        return o;
      })
      .catch(function(){ return null; });
  }
  __kurucuSoz.then(function(o){ try{ cb(o); }catch(e){} });
}
/* Sayfalar için tek cümle: 'Kalan kurucu yeri: 873' — sayaç yoksa boş dize. */
function kurucuSatir(sinavAnahtar, kalanlar){
  if(!kalanlar || !(sinavAnahtar in kalanlar)) return '';
  var k = kalanlar[sinavAnahtar];
  return k > 0 ? 'Kalan kurucu yeri: ' + tl(k) : 'Kurucu kontenjanı doldu';
}
