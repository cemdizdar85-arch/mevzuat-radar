/* ============================================================================
   TETİKTE FİYAT MOTORU — TEK GERÇEK KAYNAK  (kuruldu 21.08.2026)

   Neden ayrı dosya: bu veri 02.08'den beri fiyat.html'in içinde gömülüydü.
   satin-al.html açılınca aynı rakamın İKİ yerde durma riski doğdu; fiyat.html'in
   kendi notu şunu söylüyordu: "sayfada yazan rakam ile ödenecek rakam hep aynı
   olsun". Bu dosya o kuralı kod düzeyinde garanti eder.

   ⚠️ RAKAM DEĞİŞTİRİLECEKSE YALNIZ BURADAN DEĞİŞİR. fiyat.html ve satin-al.html
   ikisi de buradan okur; birine elle rakam yazmak iki sayfayı ayırır.

   ⚠️ Sınav tarihi ROBOTLA DEĞİŞTİRİLMEZ; elle teyitle güncellenir.
   ============================================================================ */

/* Tarihler TÜRMOB 2026 resmî sınav takviminden (22.07.2026'da okundu).
   06.08 düzeltmesi: Yeterlilik 3. dönem 28 KASIM (12-21 Aralık eski yazılı takvimdi). */
var SINAVLAR = [
  { ad:'Staja Başlama', tarih:'2026-11-21', yazi:'21 Kasım 2026', anahtar:'sgs' },
  { ad:'Yeterlilik',    tarih:'2026-11-28', yazi:'28 Kasım 2026', anahtar:'yeterlilik' }
];

/* 02.08.2026 FİYAT KARARI — ölçülmüş dayanaklarla (dayanak tabloları fiyat.html'de):
   SGS sınav ücreti 1.635 · Yeterlilik ilk başvuru 10.080 (TESMER 2026 tarifesi)
   kurs bandı 8.800-16.800 · sadece-video soru çözüm paketi 3.250 · soru bankası kitabı ~1.140.
   KGK 2.790: 06.08 Cem onayı, dayanak kgk-pazar-06-08 (kurs ders başına 12.600-17.500). */
var FIYAT = {
  sgs:        { erken:1790, orta:2190, son:2490 },
  yeterlilik: { erken:2790, orta:3190, son:3490 }
};

/* Uzun paketler basamaktan BAĞIMSIZ sabit fiyattır: iki sınav dönemini kapsar. */
var UZUN = { sgs:2790, yeterlilik:3990 };
var KGK_FIYAT = 2790;

function gunFarki(t){
  var s = new Date(t + 'T09:00:00+03:00');
  return Math.ceil((s - new Date()) / 86400000);
}
function basamak(g){ return g > 90 ? 'erken' : (g > 30 ? 'orta' : 'son'); }
function tl(n){ return n.toLocaleString('tr-TR'); }
function sinav(anahtar){
  return SINAVLAR.filter(function(x){ return x.anahtar === anahtar; })[0];
}
function basamakYazi(b){
  return b === 'erken' ? 'kuruluş fiyatı'
       : (b === 'orta' ? 'sınava 90 günden az kaldı' : 'son 30 gün fiyatı');
}

/* SATILABİLİR PAKETLER — satin-al.html'in ürün listesi buradan doğar.
   Bir paket burada yoksa SATILMAZ. "Son 15 Gün" (890 TL) bilerek YOK:
   sınava 30 gün kala ön satışa açılacağı fiyat.html'de yazılı, bugün ifa edilemez. */
function paketler(){
  var s = sinav('sgs'), y = sinav('yeterlilik');
  var gS = gunFarki(s.tarih), gY = gunFarki(y.tarih);
  var bS = basamak(gS), bY = basamak(gY);
  return [
    { id:'sgs-donem', ad:'Staja Başlama — sınav dönemi', grup:'Staja Başlama (SGS)',
      fiyat:FIYAT.sgs[bS], not:basamakYazi(bS),
      erisim:s.yazi + ' sınavına kadar sınırsız' },
    { id:'sgs-uzun', ad:'Staja Başlama — 12 ay', grup:'Staja Başlama (SGS)',
      fiyat:UZUN.sgs, not:'iki sınav dönemini kapsar',
      erisim:'Satın alma tarihinden itibaren 12 ay' },
    { id:'yeterlilik-donem', ad:'Yeterlilik — sınav dönemi', grup:'SMMM Yeterlilik',
      fiyat:FIYAT.yeterlilik[bY], not:basamakYazi(bY),
      erisim:y.yazi + ' sınavına kadar sınırsız' },
    { id:'yeterlilik-uzun', ad:'Yeterlilik — 12 ay', grup:'SMMM Yeterlilik',
      fiyat:UZUN.yeterlilik, not:'iki sınav dönemini kapsar',
      erisim:'Satın alma tarihinden itibaren 12 ay' },
    /* KGK'da günlük/basamak rakamı YOK: Kasım 2026 Bağımsız Denetçilik sınavının
       kesin günü henüz İLAN EDİLMEDİ, teyitsiz tarih yazılmaz. */
    { id:'kgk', ad:'Bağımsız Denetçi (KGK) — temel alan', grup:'Bağımsız Denetçilik',
      fiyat:KGK_FIYAT, not:'kuruluş fiyatı',
      erisim:'Kasım 2026 sınav dönemi sonuna kadar' }
  ];
}
function paketBul(id){
  return paketler().filter(function(p){ return p.id === id; })[0] || null;
}
