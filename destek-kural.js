/* ===========================================================================
   DESTEK TAKİBİ — profil→kurum kuralı. TEK KAYNAK (21.08.2026).

   Neden ayrı dosya: kural iki yerde kullanılıyor —
     destekler.html  (girişsiz kayıt kutusu)
     radar-app.html  (üye paneli, "Destek takibim")
   Kopyalamak yerine ikisi de buradan okur. Üçüncü bir kopya AÇILMAZ.

   Robot tarafındaki eşi: motor/destek-takip-nobeti.ps1 içindeki KurumAdi().
   PowerShell bu dosyayı okuyamadığı için orada zorunlu bir ikinci kopya var;
   BİRİ DEĞİŞİRSE ÖTEKİ DE DEĞİŞİR. Değişmezi denetleyen ölçüm: cagri-radar.json'daki
   her kaynağın ürettiği kurum adı, aşağıdaki anahtarlar arasında olmalı.

   ÖNEMLİ SINIR: çağrı kayıtlarında uygunluk verisi (kim başvurabilir) YOKTUR.
   Bu yüzden eşleşme PROGRAM değil KURUM düzeyindedir. Aşağıdaki kurallar
   ELLE yazılmıştır; çağrı başlığından kelime tahmini YAPILMAZ.
   =========================================================================== */
(function(g){
  'use strict';

  var KURAL = {
    "KOSGEB":            function(c){ return true; },                                    // KOBİ geneli
    "KALKINMA AJANSI":   function(c){ return true; },                                    // bölge geneli
    "TÜBİTAK":           function(c){ return ['imalat','teknoloji'].indexOf(c.faaliyet) >= 0; },
    "TKDK":              function(c){ return c.faaliyet === 'imalat'; },                 // tarım-gıda-kırsal
    "HAMLE":             function(c){ return c.faaliyet === 'imalat'; },                 // öncelikli ürün, sanayi
    "KKYDP":             function(c){ return c.faaliyet === 'imalat'; },                 // kırsal kalkınma tebliğleri
    "TİCARET BAKANLIĞI": function(c){ return ['var','hedef'].indexOf(c.ihracat) >= 0 && c.yapi !== 'sahis'; }
                                                                                          // 5973: şahıs işletmesi giremez
  };

  var ALANLAR = ['durum','faaliyet','ihracat','ihtiyac','yapi'];

  // Panel formunu bundan çizer; destekler.html'deki sorularla AYNI metinler.
  g.DESTEK_SORULAR = [
    { k:'durum',    ad:'İşletmen ne durumda?',       se:[['kurmadim','Henüz kurmadım'],['yeni','Yeni kurdum'],['kurulu','Kurulu, çalışıyor']] },
    { k:'faaliyet', ad:'Ne iş yapıyorsun?',          se:[['imalat','Üretim / imalat'],['teknoloji','Yazılım / teknoloji'],['ticaret','Ticaret / hizmet']] },
    { k:'ihracat',  ad:'İhracat?',                   se:[['var','Yapıyorum'],['hedef','Hedefliyorum'],['yok','Gündemimde yok']] },
    { k:'ihtiyac',  ad:'Ne arıyorsun?',              se:[['hibe','Hibe / geri ödemesiz'],['finans','Kredi / finansman'],['hepsi','İkisi de olur']] },
    { k:'yapi',     ad:'Hukuki yapın?',              se:[['sahis','Şahıs işletmesi'],['sirket','Ltd / AŞ (ticaret şirketi)'],['yok','Henüz yok']] }
  ];

  g.DESTEK_KURUMLAR   = Object.keys(KURAL);
  g.destekProfilDolu  = function(c){ return !!c && ALANLAR.every(function(k){ return c[k]; }); };
  // Profil eksikse HEPSİ izlenir: "bilmiyorsak eleme" - sessizce daraltmayız.
  g.destekKurumlari   = function(c){
    return g.destekProfilDolu(c)
      ? Object.keys(KURAL).filter(function(k){ return KURAL[k](c); })
      : Object.keys(KURAL);
  };
  g.destekKapaliKurumlar = function(c){
    var acik = g.destekKurumlari(c);
    return Object.keys(KURAL).filter(function(k){ return acik.indexOf(k) < 0; });
  };
})(window);
