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
      Biz varsaymıyoruz; geçemeyene ikinci dönem %50.
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
   KOTA — kuruluş fiyatının bitiş şartı. Sayaç EKRANDA GÖSTERİLMEZ:
   açılışta "3 üye" yazması itibar kaybı, sahte sayaç ise yalan olurdu.
   Kota dolunca fiyat liste fiyatına ÇIKAR — bu bir söz, tutulmazsa
   "üstü çizili sahte fiyat" yapmış oluruz (İndirimli Satış mevzuatı).
--------------------------------------------------------------------------- */
var KOTA = { sgs:500, yeterlilik:200, kgk:150, radar:300, kurucu:100 };

/* Erişim süresi: 3 ay. Sınav gününe bağlı DEĞİL. */
var SURE_GUN = 90;

/* Kart ödemesi açıldığında true yapılır — taksit satırları o zaman görünür.
   Bugün havale/EFT var, taksit YOK; kapalıyken hiçbir yerde taksit yazmaz. */
var TAKSIT_ACIK = false;
var TAKSIT_ADET = 3;

/* ---------------------------------------------------------------------------
   FİYATLAR — kuruluş / liste çifti. TL, KDV DAHİL (sınav tarafı).
   Sınav tarafı KDV dahil olmak ZORUNDA: 6502 m.54 + Fiyat Etiketi Yönetmeliği,
   tüketiciye satışta tüm vergiler dahil tek tutar gösterilir.
--------------------------------------------------------------------------- */
var FIYAT = {
  sgs:            { kurulus:1790, liste:2490 },
  /* Yeterlilik ders merdiveni — her basamak RESMÎ HARÇTAN UCUZ:
     1 ders 1.190 < 1.260 · 2 ders 1.990 < 2.520 · 3 ders 2.590 < 3.780
     4 ders 3.090 < 5.040 · tüm dersler 3.490 < 10.080                     */
  yeterlilik:     [ null, {kurulus:1190,liste:1690}, {kurulus:1990,liste:2790},
                          {kurulus:2590,liste:3590}, {kurulus:3090,liste:4290} ],
  yeterlilikTum:  { kurulus:3490, liste:4990 },
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
  if(kaps === false && s){ return '3 ay (' + t + ') — ' + s.yazi + ' sınavına kadar ücretsiz uzatılır'; }
  return '3 ay · ' + t + ' tarihine kadar';
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
             harcYazi:n + ' dersin harcı ' + tl(HARC.yeterlilik.ders * n) + ' TL', acik:true });
  }
  L.push({ id:'yeterlilik-tum', grup:'SMMM Yeterlilik', ad:'Yeterlilik — tüm dersler', ders:8,
           fiyat:FIYAT.yeterlilikTum.kurulus, liste:FIYAT.yeterlilikTum.liste,
           kota:KOTA.yeterlilik, erisim:erisimYazi('yeterlilik'), sinav:'yeterlilik',
           harcYazi:'İlk başvuru harcı ' + tl(HARC.yeterlilik.ilkBasvuru) + ' TL', acik:true });

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
             kota:KOTA.kgk, erisim:'3 ay', sinav:null,
             harcYazi:'Piyasada tek modül kursu 2.500 – 5.250 TL', acik:true });
  }
  L.push({ id:'kgk-tum', grup:'Bağımsız Denetçilik (KGK)',
           ad:'KGK — dört konunun tamamı', modul:HARC.kgk.temelAlanKonu,
           kim:'Sektör mevzuatından da sorumluysan',
           fiyat:FIYAT.kgkTum.kurulus, liste:FIYAT.kgkTum.liste,
           kota:KOTA.kgk, erisim:'3 ay', sinav:null,
           harcYazi:'Piyasada tam paket kursu 13.500 – 15.120 TL', acik:true });

  L.push({ id:'yeterlilik-kgk', grup:'Bağımsız Denetçilik (KGK)',
           ad:'Yeterlilik + KGK', fiyat:FIYAT.yeterlilikKgk.kurulus, liste:FIYAT.yeterlilikKgk.liste,
           kota:KOTA.kgk, erisim:'3 ay · iki sınav birden', sinav:null,
           harcYazi:'Ayrı ayrı ' + tl(FIYAT.yeterlilikTum.kurulus + FIYAT.kgkTum.kurulus) + ' TL',
           acik:true });

  L.push({ id:'son15', grup:'Ek', ad:'Son 15 Gün planı',
           fiyat:FIYAT.son15.kurulus, liste:FIYAT.son15.liste, kota:null,
           erisim:'Sınavdan 15 gün önce açılır', sinav:null,
           harcYazi:'Paketlere dahildir; tek de alınır', acik:true });

  /* Ortak alanlar */
  L.forEach(function(p){
    p.indirim = indirimYuzde(p.fiyat, p.liste);
    p.not     = p.indirim ? 'kuruluş fiyatı · %' + p.indirim : 'sabit fiyat';
    p.taksit  = taksitYazi(p.fiyat);
  });
  return L;
}
function paketBul(id){
  return paketler().filter(function(p){ return p.id === id; })[0] || null;
}
function acikPaketler(){ return paketler().filter(function(p){ return p.acik; }); }
