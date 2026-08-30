/* ============================================================================
   GTİP damping/sübvansiyon ORAN ÇÖZÜCÜSÜ — GTİP Kontrolü + Menşe Senaryo Raporu
   ortak motoru. 30.08.2026'da eklendi.

   NEDEN VAR: veri/gtip-damping.json'daki 141 kaydın oranı ÜÇ AYRI BİÇİMDE
   yazılmış (kaynak Excel'de bazı hücreler metin, bazıları yüzde-biçimli sayı):
     1) "%38,26-%45,99"   yüzde ÖNDE  (47 kayıt)
     2) "21,12%-28,87%"   yüzde SONDA ( 3 kayıt)
     3) "0.29" / "3.95E-2" çıplak ondalık = %29 / %3,95  (27 kayıt)
     4) "140-320 $/Kg"    spesifik vergi, yüzde DEĞİL   (64 kayıt)
   Eski okuyucu yalnız (1)'i tanıyordu. (2) ve (3) sessizce SIFIR sayılıyordu →
   140 GTİP kodunda damping yokmuş gibi görünüyordu (en büyüğü %56,50, Çin,
   8415.83 klima, tebliğ 2022/1). Bu, cezalı menşeyi "en avantajlı" gösteriyordu.

   (3)'ün oran olduğu ÇAPRAZ TEYİTLE saptandı: aynı GTİP kodunda iki biçim yan
   yana duruyor — 7208.10 Rusya "%6,10-%9" (metin) / Japonya "0.09" (ondalık).
   27 ondalığın hepsi 1'in altında; ×100 aralığı %3,95–%56,50, metin biçimlilerin
   aralığı %0–92,25 ile örtüşüyor.

   RAKAM DİSİPLİNİ: uydurma yok. Okunamayan biçim sessizce 0 sayılmaz,
   `okunamadi` bayrağıyla işaretlenir; nöbetçi (arac/damping-oran-kapisi.js)
   okunamayan kayıt çıkarsa kapıyı KIRMIZI'ya düşürür.
   ========================================================================== */
(function(kok){
  'use strict';

  // spesifik (maktu) vergi: $/ton, $/kg, $/m2 ... — yüzde toplamına GİRMEZ
  var SPESIFIK = /\$\s*\/\s*(ton|kg|kilo|adet|m2|m3|litre|çift|cift|gram|adet)/i;

  function sayiya(s){ return parseFloat(String(s).replace(',', '.')); }

  /* ham metni çöz → { lo, hi, yuzdeler[], spesifik, okunamadi, bicim, metin }
     lo/hi: yüzde cinsinden alt/üst sınır (yoksa 0)
     spesifik: $/birim vergi var mı (ayrı uyarı gerekir)
     okunamadi: içerik dolu ama hiçbir biçime uymadı (nöbetçi bunu yakalar) */
  function coz(ham){
    var t = (ham === null || ham === undefined) ? '' : String(ham).trim();
    var sonuc = { lo:0, hi:0, yuzdeler:[], spesifik:false, okunamadi:false, bicim:'bos', metin:t };
    if(!t) return sonuc;

    sonuc.spesifik = SPESIFIK.test(t);

    if(t.indexOf('%') >= 0){
      // % işareti önde de olabilir sonda da; aralığın tek tarafında da olabilir
      // ("%8,00- 14,45"). Bu yüzden $ kısmını attıktan sonra metindeki TÜM
      // sayılar yüzde kabul edilir.
      // DİKKAT: spesifik kısım ARALIK olabilir ("140-320 $/Kg"). Sadece son sayıyı
      // atmak yetmez, "140-" sızıp yüzde sanılır (30.08'de göz denetiminde yakalandı:
      // "%15-%25, 140-320 $/Kg" → yanlışlıkla %140 üst sınır veriyordu).
      var temiz = t.replace(/[\d.,]+(?:\s*[-–]\s*[\d.,]+)*\s*\$\s*\/\s*[^\s,;]+/gi, ' ')
                   .replace(/\$/g, ' ');
      var bulunan = temiz.match(/\d+(?:[.,]\d+)?/g) || [];
      sonuc.yuzdeler = bulunan.map(sayiya).filter(function(n){ return !isNaN(n); });
      sonuc.bicim = 'yuzde';
    } else if(/^\d*[.,]?\d+(?:[eE][-+]?\d+)?$/.test(t)){
      // çıplak sayı: Excel'de yüzde biçimli hücre ham ondalık iner (0,29 = %29)
      var n = sayiya(t);
      if(!isNaN(n)){
        if(n < 1){ sonuc.yuzdeler = [n * 100]; sonuc.bicim = 'ondalik'; }
        else      { sonuc.yuzdeler = [n];       sonuc.bicim = 'ciplak'; }
      }
    } else if(sonuc.spesifik){
      sonuc.bicim = 'spesifik';           // yalnız $/birim — yüzde yok, normal
    } else {
      sonuc.okunamadi = true;             // dolu ama tanınmadı → nöbetçi yakalar
      sonuc.bicim = 'taninmadi';
    }

    if(sonuc.yuzdeler.length){
      // Excel ondalığı ×100 yapınca kayan nokta gürültüsü kalıyor
      // (0.28999999999999998 → 28.999999999999996). 2 haneye yuvarlanır.
      sonuc.yuzdeler = sonuc.yuzdeler.map(function(n){ return Math.round(n*100)/100; });
      sonuc.lo = Math.min.apply(null, sonuc.yuzdeler);
      sonuc.hi = Math.max.apply(null, sonuc.yuzdeler);
    }
    return sonuc;
  }

  // ekranda gösterilecek insan-okur metin ("%29" / "%16,76–%62,94" / ham metin)
  function yaz(ham){
    var c = coz(ham);
    var p = [];
    if(c.yuzdeler.length){
      var b = function(n){ return '%' + (Math.round(n*100)/100).toLocaleString('tr-TR'); };
      p.push(c.hi > c.lo ? (b(c.lo) + '–' + b(c.hi)) : b(c.lo));
    }
    if(c.spesifik){
      // spesifik kısmı ham haliyle gösterilir — miktara bağlı, yüzdeye çevrilemez
      var sp = (c.metin.match(/[\d.,]+(?:\s*[-–]\s*[\d.,]+)*\s*\$\s*\/\s*[^\s,;]+/i) || [])[0];
      p.push((sp ? sp.trim() : 'spesifik vergi'));
    }
    if(!p.length) p.push(c.metin || 'kaynağa bakınız');
    return p.join(' + ');
  }

  kok.GtipDampingOran = { coz: coz, yaz: yaz, SPESIFIK: SPESIFIK };

  // node tarafı (nöbetçi betiği) için
  if(typeof module !== 'undefined' && module.exports) module.exports = kok.GtipDampingOran;

})(typeof globalThis !== 'undefined' ? globalThis : this);
