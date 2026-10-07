/* Tetikte — ortak araç menüsü.
   Her sayfaya <script src="menu.js" defer></script> ile eklenir:
   sağ altta "☰ Araçlar" düğmesi + tam ekran aranabilir katalog paneli. */
(function(){
if(window.MRMenu) return;

/* ---- 14.08 MOBIL DOKUNMA HEDEFI (Cem: "onlari buyut") ----------------------
   Olculdu: ust menu baglantilari mobilde 21px yuksekligindeydi; parmakla
   basmak icin onerilen alt sinir ~44px. Duzeltme YALNIZ MOBILDE (<=600px)
   uygulanir - masaustu tasarimi degismesin. Menu 20+ sayfada ayni oldugu icin
   her dosyaya dokunmak yerine tek noktadan, menu.js'ten cozuluyor.
   Metin ICI baglantilar (cumle icinde gecenler) bilerek DISARIDA: onlari
   buyutmek metni bozar, standart uygulama da onlari muaf tutar. */
try {
  var dk = document.createElement('style');
  dk.textContent = '@media (max-width:600px){'
    + '.top a{display:inline-block;padding:15px 4px;line-height:1.1}'
    + '.top{gap:4px 10px}'
    + '}';
  (document.head||document.documentElement).appendChild(dk);
} catch(e){}

/* ---- 29.08 CERCEVE KALKANI (anti-clickjacking) -----------------------------
   Neden: GitHub Pages statik barindirma HTTP basligi yazdirmiyor; bu yuzden
   X-Frame-Options ve CSP frame-ancestors GONDERILEMIYOR (olculdu: alti guvenlik
   basliginin altisi da yok). Basliksiz sitede tek savunma JS tarafinda kalir.
   Risk somut: ODEME sayfasi (satin-al.html) baskasinin iframe'ine alinip
   ustune sahte form bindirilebilir - kullanici bizim adresi gorur, veriyi
   dolandiriciya yazar. Bu blok sayfayi yabanci cerceve icinde CIZDIRMEZ.
   Olculdu (29.08): depoda HICBIR sayfa iframe kullanmiyor (0 eslesme),
   bu yuzden mesru bir kullanimi kirma ihtimali yok.
   NOT: Bu blok PERDE-BASI isaretinin DISINDA duruyor - gong.ps1 acilista
   perdeyi siler ama bu kalkan yerinde kalir. */
try {
  if (window.top !== window.self) {
    var kacabildi = false;
    try { window.top.location = window.self.location; kacabildi = true; } catch (e) {}
    if (!kacabildi) {
      /* Cerceve yabanci (cross-origin): disari cikamiyoruz, o halde icerigi
         hic gostermeyelim ve kullaniciyi gercek adrese yollayalim. */
      document.documentElement.innerHTML =
        '<body style="margin:0;background:#0f1115;color:#e8e8ea;font:15px/1.6 -apple-system,\'Segoe UI\',system-ui,Roboto,Arial,sans-serif;'
        + 'display:flex;align-items:center;justify-content:center;min-height:100vh;text-align:center;padding:24px">'
        + '<div><p style="margin:0 0 14px"><b>Bu sayfa baska bir sitenin cercevesi icinde acilmis.</b><br>'
        + 'Guvenligin icin icerik gosterilmiyor.</p>'
        + '<p style="margin:0"><a href="https://tetikte.com/" target="_top" style="color:#f5a524;font-weight:700">'
        + 'tetikte.com adresinden devam et &rarr;</a></p></div></body>';
    }
  }
} catch (e) {}

/* ---- 29.09 DÖNÜŞÜM ÖLÇÜMÜ (Cem: "dönüşüm kodları + Instagram reklam") ----------
   donusum.js: Meta Pixel + Conversions API + GoatCounter aynası. PIKSEL_ID boşken
   Meta'ya hiçbir şey gitmez, bant çıkmaz. PERDE-BASI'ndan ÖNCE: perde açıkken de
   ölçülsün (perde e-postası = Lead). Mutlak yol: alt klasör sayfalarında da insin. */
try {
  if (!window.ttDonusum && !document.querySelector('script[src$="donusum.js"]')) {
    var dn = document.createElement('script'); dn.src = '/donusum.js'; dn.async = true;
    (document.head||document.documentElement).appendChild(dn);
  }
} catch (e) {}

/* 04.10.2026 iyzico başvuru şartı: KİMLİK satırı + ödeme/güven bandı - tek yerden (yasal altbilgi, perde, ana sayfa).
   Kimlik kaynağı iletisim.html künye tablosu (ticaret unvanı, MERSİS, sicil, vergi dairesi/no, adres, iletişim).
   PERDE-BASI işaretinin DIŞINDA: açılışta gong.ps1 perdeyi silince de kalır. Yollar KÖKTEN (alt klasör sayfaları için). */
var TT_KIMLIK = 'Dizdar Denetim Danışmanlık ve Yazılım A.Ş. · MERSİS 0301130343200001 · Ticaret Sicil 270764 (İzmir) · ' +
  'Kordon V.D. 3011303432 · Alsancak Mah. Atatürk Cad. Kavalalı İş Merkezi No:378 B, Konak/İzmir · destek@tetikte.com · 0532 344 80 58';
function ttOdemeBandi(yer) {
  if (!yer || document.getElementById('ttOdemeBandi')) return;
  if (!document.getElementById('ttOdemeStil')) {
    var st = document.createElement('style'); st.id = 'ttOdemeStil';
    st.textContent = '#ttOdemeBandi{max-width:980px;margin:18px auto 0;padding:0 18px 90px;display:flex;flex-wrap:wrap;align-items:center;gap:10px 18px;font-size:12px;color:var(--dim);line-height:1.6}' +
      '#ttOdemeBandi img{height:24px;width:auto;max-width:100%;display:block}' +
      '#ttOdemeBandi .ob-marka{text-decoration:none}#ttOdemeBandi .ob-soz{font-size:13px;font-weight:650;color:var(--muted)}' +
      '#ttOdemeBandi .ob-ara{flex-basis:100%;height:0}' +
      /* 08.10 Cem ("yanlışın sebebiyle öğren güzel görünmüyor telefonda"): dar ekranda logo ile slogan yan yana sıkışıyordu
         (logo iri, slogan kalın) -> slogan logonun altında kendi satırında, sade */
      '@media(max-width:560px){#ttOdemeBandi .ob-soz{flex-basis:100%;margin-top:-6px;font-size:13.5px;font-weight:600;color:var(--dim)}}' +
      '#ttOdemeBandi .ob-koyu{display:none}html[data-theme="dark"] #ttOdemeBandi .ob-acik{display:none}html[data-theme="dark"] #ttOdemeBandi .ob-koyu{display:block}';
    (document.head || document.documentElement).appendChild(st);
  }
  var b = document.createElement('div'); b.id = 'ttOdemeBandi';
  /* 04.10 Cem "Tetikte ismimiz sadece yukarıda görünüyor, aşağıda olmaz mı": her sayfanın dibinde logo + ana cümle */
  b.innerHTML = '<a class="marka ob-marka" href="/index.html" aria-label="Tetikte ana sayfa" style="--marka-olcu:20px"><span class="marka-lamba" aria-hidden="true"></span><b class="marka-ad">tet<span class="i">ı</span>kte</b></a>' +
    '<span class="ob-soz">Yanlışını, sebebiyle birlikte öğren.</span><span class="ob-ara" aria-hidden="true"></span>' +
    '<img class="ob-acik" src="/gorsel/odeme/iyzico-logo-bandi.svg" width="429" height="32" alt="iyzico ile Öde · Mastercard · Visa · American Express · Troy" loading="lazy">' +
    '<img class="ob-koyu" src="/gorsel/odeme/iyzico-logo-bandi-beyaz.svg" width="429" height="32" alt="iyzico ile Öde · Mastercard · Visa · American Express · Troy" loading="lazy">' +
    '<span>🔒 Bu sitedeki bütün bağlantılar SSL (HTTPS) ile şifrelenir.</span>';
  yer.appendChild(b);
}
window.ttOdemeBandi = ttOdemeBandi;

/* ==== PERDE-BASI (gong.ps1 bu isaretler arasini siler - ELLE DOKUNMA) ==== */
/* ---- AÇILIŞ PERDESİ (23.07.2026, Cem: site bitmeden insanlar gezmesin) ----
   Gizli anahtar: siteye bir kez ?kapi=tetikte2026 ile girilince cihaz tanınır.
   AÇILIŞ GÜNÜ: motor/gong.ps1 bu bloğu işaretlerden tanıyıp siler. */
try {
  var q = new URLSearchParams(location.search);
  if (q.get('kapi') === 'tetikte2026') { localStorage.setItem('mrOnizleme','1'); }
  /* 05.08: yasal sayfalar perdeden MUAF — odeme kurulusu (iyzico/PayTR) incelemesi
     mesafeli satis/iade/iletisim/KVKK metinlerini gormek zorunda; bu sayfalarin
     kanunen de acik olmasi gerekir. Urun icerigi tasimadiklari icin sizinti yok. */
  /* 14.09: on-bilgilendirme, gizlilik-politikasi, uyelik-sozlesmesi de muaf (ayni gerekce). */
  var yasalMuaf = /(?:^|\/)(mesafeli-satis|teslimat-iade|iletisim|kvkk|on-bilgilendirme|gizlilik-politikasi|uyelik-sozlesmesi)\.html$/.test(location.pathname);
  if (localStorage.getItem('mrOnizleme') !== '1' && !yasalMuaf) {
    var perde = function(){
      if (document.getElementById('mrPerde')) return;
      var d = document.createElement('div');
      d.id = 'mrPerde';
      d.style.cssText = 'position:fixed;inset:0;z-index:99999;background:var(--taban);color:var(--ink);display:flex;align-items:center;justify-content:center;text-align:center;padding:24px;font-family:-apple-system,"Segoe UI",system-ui,Roboto,Arial,sans-serif';
      /* 30.07: perde ziyaretcinin gordugu ILK ekran ve eski markayla duruyordu
         (koseli T kutusu + yesil nokta + yesil buton). Rebrand kurali: nobet
         lambasi + kehribar; yesil yalniz durum rengidir, marka rengi degil. */
      d.innerHTML = '<div style="max-width:460px">'+
        '<div style="width:18px;height:18px;border-radius:50%;background:#f5a524;box-shadow:0 0 0 7px rgba(245,165,36,.16),0 0 26px rgba(245,165,36,.6);display:inline-block;margin-bottom:20px;animation:mrNbz 2.2s ease-in-out infinite"></div>'+
        '<h1 style="font-size:30px;letter-spacing:-1px;margin:0 0 10px">Tetikte</h1>'+
        '<style>@keyframes mrNbz{0%,100%{opacity:1}50%{opacity:.4}}</style>'+
        '<p style="color:var(--muted);font-size:15px;line-height:1.65;margin:0 0 20px"><b style="color:var(--ink)">SMMM Staja Giriş ve Yeterlilik soru bankası çok yakında.</b><br>Yanlışını, sebebiyle birlikte öğren: her şıkkın gerekçesi, dayandığı maddeyle. Açılışta ilk sen haber al — kurucu fiyatı ilk gelenlerin.</p>'+
        '<form id="mrPerdeForm" style="display:flex;gap:8px;flex-wrap:wrap;justify-content:center">'+
        '<input type="email" required placeholder="e-posta adresin" style="flex:1;min-width:200px;background:var(--kagit);border:1px solid var(--line2);border-radius:11px;color:var(--ink);font:inherit;font-size:14px;padding:12px 14px">'+
        '<button type="submit" style="background:linear-gradient(135deg,var(--marka-lamba-1),var(--marka-lamba-2));color:#0f1115;font-weight:800;font-size:14px;padding:12px 22px;border:none;border-radius:11px;cursor:pointer">Haber ver →</button>'+
        /* 30.07: pasif "katilinca kabul edersin" satiri acik riza DEGILDI -
           karne formundaki gibi zorunlu onay kutusuna cevrildi (KVKK).
           kvkk.html koku: perde alt sayfalarda da cikar, mutlak yol sart. */
        '<label style="display:flex;gap:8px;align-items:flex-start;width:100%;justify-content:center;font-size:11.5px;color:var(--muted);margin-top:10px;text-align:left"><input type="checkbox" required style="margin-top:2px;accent-color:#f5a524;flex:none;width:16px;height:16px;padding:0">'+
        '<span style="max-width:400px">E-postamın, Tetikte açılış bilgilendirmeleri için işlenmesine izin veriyorum. İstediğimde çıkabilirim. <a href="/kvkk.html" target="_blank" style="color:#ffc24b">Aydınlatma metni</a></span></label></form>'+
        '<div id="mrPerdeOk" style="display:none;color:#3ddc97;font-weight:700;font-size:14px;margin-top:12px">✓ Kaydın alındı — açılışta ilk sen duyacaksın.</div>' +
        /* 04.10 iyzico: inceleyici açılıştan önce perdeyi görür -> yasal bağlantılar + kimlik + ödeme bandı perdede de */
        '<p style="font-size:12px;color:var(--muted);line-height:1.8;margin:22px 0 0">' +
        '<a href="/iletisim.html" style="color:var(--muted)">Hakkımızda ve İletişim</a> · <a href="/mesafeli-satis.html" style="color:var(--muted)">Mesafeli Satış Sözleşmesi</a> · ' +
        '<a href="/teslimat-iade.html" style="color:var(--muted)">Teslimat ve İade</a> · <a href="/gizlilik-politikasi.html" style="color:var(--muted)">Gizlilik Politikası</a> · ' +
        '<a href="/on-bilgilendirme.html" style="color:var(--muted)">Ön Bilgilendirme</a> · <a href="/kvkk.html" style="color:var(--muted)">KVKK</a><br>' + TT_KIMLIK + '</p>' +
        '<div id="mrPerdeBant" style="display:flex;justify-content:center;margin-top:12px"></div></div>';
      document.body.appendChild(d);
      try { ttOdemeBandi(document.getElementById('mrPerdeBant')); var pb=document.getElementById('ttOdemeBandi'); if(pb){ pb.style.padding='0'; pb.style.justifyContent='center'; } } catch(e){}
      d.style.overflowY = 'auto';
      document.documentElement.style.overflow = 'hidden';
      document.getElementById('mrPerdeForm').addEventListener('submit', function(e){
        e.preventDefault();
        var em = this.querySelector('input').value.trim();
        if(!em) return;
        /* 04.09: web3forms cikti - kendi uc fonksiyonumuz (canli adi quick-task, kod radar-app/edge/form-al.ts) */
        try { fetch('https://bjrleanjpyujtajmazxn.supabase.co/functions/v1/quick-task',{method:'POST',headers:{'apikey':'sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg','Authorization':'Bearer sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg','Content-Type':'application/json',Accept:'application/json'},body:JSON.stringify({email:em,subject:'Açılış perdesi: erken kayıt',from_name:'Tetikte Perde','Açılış bilgilendirme izni':'evet (zorunlu onay kutusu işaretlendi)','Onay metni':'E-postamın, Tetikte açılış bilgilendirmeleri için işlenmesine izin veriyorum. İstediğimde çıkabilirim.','Onay zamanı':new Date().toISOString()})}); } catch(err){}
        this.style.display='none';
        document.getElementById('mrPerdeOk').style.display='block';
      });
    };
    if (document.body) { perde(); } else { document.addEventListener('DOMContentLoaded', perde); }
    return; /* perde varken menu de kurulmasin */
  }
} catch(e) {}
/* ==== PERDE-SONU (gong.ps1 isaretli blogu buraya kadar siler) ==== */

/* 30.09 Cem: "site sadece SMMM başlama ve SMMM bitirme sınavları olacak" (açılış Pzt 05.10).
   Menüde yalnız SINAV grubu kalır. Gümrük, radar ve rehber sayfaları SİLİNMEDİ: robotları çalışır,
   URL'leri açık; yalnız görünmez (aşağıda GİZLİ ARAÇLAR listesine de eklendi). Geri açmak:
   grubu GRUPLAR'a geri koy + adı GIZLI listesinden sil + sitemap satırı. */
var GRUPLAR_GIZLI=[
 {ad:"🛃 Gümrük & İthalat", araclar:[
  ["gtip.html","🔎","GTİP · Kaç Vergi Öderim?","İthalatta gümrük vergisi, KDV ve kesintiler"],
  ["risk-taramasi.html","🛃","Beyanname Risk Taraması","Beyandan önce ceza kapılarını tara"],
  ["senaryo-raporu.html","🌍","Nereden Alsam?","Ülke ülke toplam vergi yükü karşılaştırma"],
  ["hizmet.html","🌐","Yurt Dışı Hizmet Faturası","2 No.lu KDV + stopaj hesabı"],
  ["fiyatfarki.html","💱","Credit / Debit Note","Sonradan gelen fiyat farkının vergisi"],
  ["toplu-gtip.html","📑","Toplu GTİP Kontrolü","Excel'ini yapıştır, kalem kalem vergi yükü"]]},
 {ad:"🧭 Rehberler ve sınav", araclar:[   /* 24.09 Cem: "bunları da kaldıralım, sistem yenileme devam edebilir, şu an sadece sitede görünmesin" - işletme araçları gizli; sayfalar ve robotları yerinde. */
  ["soru-cevap.html","💬","Net Cevap","Mevzuat sorunu sor, kaynaklı cevap al"],
  ["kurulus.html","🏢","Şirket Kuruluşu Rehberi","Şahıs mı, limited mi, anonim mi?"],
  ["tesvik-sihirbazi.html","🧲","Yatırım Teşvik Sihirbazı","9903: bölgen, desteklerin, 2026 fırsatları"],
  ["genc.html","🎓","Genç Müşavir","2026 sınav takvimi, geri sayımlı"],
  ["deneme.html","📝","Deneme Sınavı","Her şıkkın gerekçesi + kaynak kuralı"],
  ["canli-deneme.html","📡","Canlı Deneme","Aynı anda, herkese aynı set; katılanlar arasında yüzdelik sıralaman"],
  ["tuzak.html","🎯","Günün Tuzağı","Her gün bir soru — cevabı ve kanun maddesi açık"],
  ["karsilastirma.html","⚖️","Hangisi sana lazım?","Kurs, kitap, ücretsiz banka ve biz — dürüst tablo"],
  ["donem-plani.html","🗺️","Dönem Planı","Kalan haftaları haritayla faz faz doldur"],
  ["songun.html","⏳","Son Gün 5 Saat","Dönem finali + sınav sabahı rehberi"]]},
 {ad:"📡 Takip Radarları", araclar:[
  ["radar.html","📰","Bugün Resmî Gazete'de","Günün önemli mevzuat değişiklikleri"],
  ["kartlar.html","💊","Günün Hap Kartları","30 saniyelik özet kartlar"],
  ["destekler.html","🎯","Destek Radarı","Profiline uyan KOSGEB ve destekler"],
  ["alacak-radari.html","🚨","Alacak Radarı","Müşterin konkordato/iflasta — ilk sen duy"],
  ["marka-radari.html","™️","Marka Radarı","Yenileme + benzer başvuru uyarısı"],
  ["marka-portfoy.html","📋","Marka Portföy Panosu","Tüm markaların, tüm tarihler tek ekranda"],
  ["marka-izleme.html","📡","Marka İzleme Radarı","Markana benzer YENİ başvuru düştü mü"],
  ["marka-itiraz.html","🔍","Marka İtiraz & Benzerlik","İtiraz süren dolmadan gör"],
  ["marka-varlik.html","💼","Markanla ne yapabilirsin","Lisans, devir, rehin, muvafakat, Madrid"],
  // 17.08: marka-app.html BITMIS ve CALISAN bir uygulamaydi ama SITEDE HICBIR
  // YERDEN ERISILEMIYORDU - ne menude ne bir sayfada linki vardi. Tarama
  // yakaladi. Ayni durum evrak-app.html'de de vardi (asagida).
  ["marka-app.html","🔐","Marka İzleme — hesabım","Markalarını ekle, yenilemeyi biz takip edelim"]]}
 /* 24.09 Cem: "Muhasebe Bürosu (SMMM)" grubu sitede görünmesin - sonra verilecek (Fiş Fabrikası, Evrak Radarı, Belge Kasası, Süre Hatırlatıcı). */
];
var GRUPLAR=[
 {ad:"🎓 SMMM sınavları", araclar:[
  ["sorular.html","📚","Soru Çöz","Staja Giriş ve Yeterlilik — sınavını seç, ders ders çöz"],
  ["seviye-testi.html","📏","Geçme İhtimalini Ölç","30 soru, yaklaşık 30 dakika, ücretsiz"],
  ["deneme.html","📝","Deneme Sınavı","Her şıkkın gerekçesi + kaynak kuralı"],
  ["canli-deneme.html","📡","Canlı Deneme","Aynı anda, herkese aynı set; katılanlar arasında yüzdelik sıralaman"],
  /* 02.10 gizli (sayfa boş). Geri almak: bu satırı aç + GIZLI regex + komut.js + sitemap: ["tuzak.html","🎯","Günün Tuzağı","Her gün bir soru — cevabı ve kanun maddesi açık"], */
  /* 07.10 Cem ("ulaşamasın bunlara"): genc · donem-plani · songun · karsilastirma GİZLİ; sayfalar silinmedi. */
  ["fiyat.html","🏷️","Fiyatlar","Staja Giriş ve Yeterlilik paketleri, KDV dahil"]]}
];

/* ---- KÖK YOLU (28.08.2026) ------------------------------------------------
   Menü, footer ve damga bağlantıları bugüne kadar "gtip.html" gibi GÖRECELİ
   yazılıydı: kök dizindeki 55 sayfada doğru, alt klasördeki sayfalarda
   (sayfalar/…) hepsi kırık olurdu. Kök bir kez hesaplanır, üretilen her
   bağlantının başına eklenir — böylece menü her derinlikte aynı çalışır. */
var KOK=(function(){
  var p=location.pathname.replace(/^\/+/,'');
  var derinlik=p.split('/').length-1;   /* dosya adı hariç klasör sayısı */
  var s=''; for(var i=0;i<derinlik;i++) s+='../';
  return s;
})();

var css=''+
/* ---- GERİ BAĞLANTISI (28.08.2026, Cem: "geri gelme tuşu ekleyelim") -------
   Ölçü: GOV.UK Design System "Back link" bileşeni — sayfanın EN ÜSTÜNE,
   ana içerikten önce konur; breadcrumb ile BİRLİKTE kullanılmaz (bizde
   breadcrumb yok, tepe şerit var). Rozet değil düz bağlantı: tarayıcının
   geri tuşunun yerini almaz, onu görünür kılar.

   28.08 İKİNCİ TUR — Cem: "geri tuşu emanet gibi duruyor". Doğruydu:
   ilk sürüm kendi çerçeveli hapı olarak şeridin ÜSTÜNDE, boşlukta
   duruyordu. Artık şeridin İÇİNE ilk öge olarak giriyor ve şeridin
   tipografisini miras alıyor — ayrı bir nesne değil, gezinme şeridinin
   parçası. Şerit yoksa (6 sayfa) eski hap biçimi .mrxGeriPul sürüyor. */
/* Renk var(--muted) DEĞİL, inherit: şerit kendi rengini dayatır. Site
   sayfalarının bir kısmı koyu, bir kısmı (alacak-radari gibi) açık temalı
   ama şeridi koyu; açık temada --muted koyu gri (#4b5563) olduğu için
   koyu şeridin üstünde okunmaz olurdu. inherit + saydamlık her iki temada
   da şeridin kendi tonunu veriyor (ölçüldü: 7,27:1 → AAA). */
'#mrxGeri{display:inline-flex;align-items:center;gap:6px;color:inherit;opacity:.85;'+
 'text-decoration:none;font-weight:700;letter-spacing:.1px;padding:2px 0;'+
 'transition:opacity .15s}'+
'#mrxGeri:hover{opacity:1}'+
'#mrxGeri:focus-visible{outline:2px solid #f5a524;outline-offset:3px;border-radius:4px}'+
'#mrxGeri .ok{font-size:15px;line-height:1;transition:transform .15s}'+
'#mrxGeri:hover .ok{transform:translateX(-3px)}'+
/* şeridi olmayan sayfalarda tek başına durur; orada çerçeve gerekiyor */
'#mrxGeri.mrxGeriPul{margin:0 0 12px;padding:8px 14px 8px 11px;'+
 'border:1px solid var(--line2);border-radius:999px;'+
 'background:var(--yuzey,#0a0f17);font-size:13.5px}'+
'#mrxGeri.mrxGeriPul:hover{border-color:rgba(245,165,36,.45)}'+
/* mobilde 44px dokunma hedefi - menü linklerine 14.08'de uygulanan ölçünün aynısı.
   28.08 ölçüldü: hapta 12px dolgu 41px veriyordu, 14px'e çekildi. Şerit içinde
   .top a kuralı (15px dolgu) zaten 44px+ üretiyor. */
'@media(max-width:600px){#mrxGeri{padding:15px 4px 15px 0}'+
 '#mrxGeri.mrxGeriPul{padding:14px 16px;font-size:14px}}'+
'@media print{#mrxGeri,.mrxAyrac{display:none!important}}'+
/* 02.10 (Cem "1.2.3 yap"): 320px'te şerit (Ana sayfa · marka · Ara · tema) 328–376px'e taşıyordu
   (veri/mobil-tasma-taban.json 9 yasal sayfa + radar/kurulus). Dar ekranda "Ana sayfa" yazısı
   gizlenir, ok kalır (aria-label "Ana sayfaya git" zaten var) + ayraç gider; yine sığmazsa
   şerit ikinci satıra sarar (son çare, kesik yerine). */
'@media(max-width:360px){.top #mrxGeri{font-size:0}.top #mrxGeri .ok{font-size:18px;margin:0}'+
 '.top .mrxAyrac{display:none}.top{flex-wrap:wrap;row-gap:4px}}'+
/* tepe şeridi tam genişlik — hesap yorumu seritTamGenislik()'te.
   Kutuyu kabından 50vw taşırıp aynı payı iç dolgu olarak geri veriyoruz:
   kutu ekranı kaplıyor, YAZI içerik sütununun tam üstünde kalıyor
   (barSol = içerikSol - pay, yazı = barSol + pay = içerikSol).
   50vw kaydırma çubuğunu da sayar, yani şerit iki yandan ~7px taşar;
   overflow-x:clip onu kırpar — clip, hidden DEĞİL: kaydırma kabı
   oluşturmaz, position:sticky'yi bozmaz.
   Tüm blok @supports içinde: clip bilmeyen eski tarayıcı yatay kaydırma
   çubuğu yemesin diye şeridi hiç taşırmaz, eski görünümde kalır. */
'@supports (overflow-x:clip){'+
 'html{overflow-x:clip}'+
 '.mrxSeritGenis{margin-left:calc(50% - 50vw)!important;margin-right:calc(50% - 50vw)!important;'+
  'padding-left:calc(50vw - 50%)!important;padding-right:calc(50vw - 50%)!important}'+
 '@media print{.mrxSeritGenis{margin:0!important;padding-left:0!important;padding-right:0!important}}'+
'}'+
'#mrxFab{position:fixed;right:18px;bottom:18px;z-index:99990;appearance:none;border:1px solid var(--line2);'+
 'background:linear-gradient(135deg,var(--marka-lamba-1),var(--marka-lamba-2));color:#0f1115;font-weight:800;font-size:14px;'+
 'font-family:-apple-system,"Segoe UI",system-ui,Roboto,Arial,sans-serif;padding:12px 18px;border-radius:999px;'+
 /* 04.09: gölge MAVİYDİ (rgba(46,140,255)) - düğme amber, markanın paleti
    amber; mavi ışık 30.08'de kaldırılan mavi favicon'un son kalıntısıydı.
    Gölge artık lamba jetonundan türer; sabit renk yok. */
 'cursor:pointer;box-shadow:0 8px 28px color-mix(in srgb,var(--marka-lamba-1) 40%,transparent);letter-spacing:.2px;'+
 'transition:transform .28s ease,opacity .28s ease}'+
'#mrxFab:hover{transform:translateY(-2px)}'+
/* 23.09 tema düğmesi: ÜST ŞERİTTE Ara düğmesinin yanında, onun ölçüsünde (komut.css .kp-dugme);
   şerit yoksa sağ üstte sabit. Yalnız tema jetonu. */
'#mrxTema{appearance:none;cursor:pointer;font:inherit;font-size:15px;line-height:1;color:var(--muted);'+
'background:none;border:1px solid var(--line);border-radius:8px;min-width:34px;height:30px;padding:0 8px;'+
'display:inline-grid;place-items:center;margin-left:6px;vertical-align:middle;transition:border-color .15s,color .15s}'+
'#mrxTema:hover{color:var(--ink);border-color:var(--line2)}'+
'#mrxTema:focus-visible{outline:2px solid var(--amber);outline-offset:2px}'+
'#mrxTema.mrxTemaSabit{position:fixed;top:12px;right:14px;z-index:99990;background:var(--panel);min-width:40px;height:36px}'+
'@media print{#mrxTema{display:none!important}}'+
'#mrxFab.mrxGizli{transform:translateY(140%);opacity:0;pointer-events:none}'+
'#mrxKaplama{position:fixed;inset:0;z-index:99991;background:color-mix(in srgb,var(--taban) 93%,transparent);backdrop-filter:blur(6px);'+
 'display:none;overflow-y:auto;font-family:-apple-system,"Segoe UI",system-ui,Roboto,Arial,sans-serif}'+
'#mrxKaplama.acik{display:block}'+
'.mrxIc{max-width:1000px;margin:0 auto;padding:26px 18px 60px;color:var(--ink)}'+
'.mrxUst{display:flex;align-items:center;gap:12px;margin-bottom:18px;flex-wrap:wrap}'+
/* 30.08: burada TURUNCU KARE ICINDE "T" HARFI vardi ve bu 54/64 sayfada
   gorunuyordu - yani sitede en cok gorunen marka isareti, markanin kendi
   isareti DEGILDI. Marka motifi: amber lamba + "ı"nin ustundeki kendi noktasi.
   Tanim stil.css'teki .marka-rozet'e tasindi (tek kaynak); burada yalniz
   olcu veriliyor. Renkler --marka-lamba-1/2 jetonlarindan gelir ve temaya
   gore DEGISMEZ - logo.svg/favicon.svg ile birebir ayni. */
'.mrxLogo{--rozet-olcu:26px;margin-right:2px}'+
'.mrxUst b{font-size:16px}'+
'.mrxUst a{color:var(--muted);text-decoration:none;font-size:13.5px;font-weight:600;padding:8px 14px;'+
 'border:1px solid var(--line2);border-radius:10px}'+
'.mrxUst a:hover{color:var(--ink)}'+
'.mrxUst a.mrxUye{background:linear-gradient(135deg,var(--marka-lamba-1),var(--marka-lamba-2));color:#0f1115;border:0;font-weight:800}'+
/* 14.09: giris ikiye ayrildi (ogrenci / isletme). Dar ekranda iki buton alt satira
   yan yana iner; logo + Ana Sayfa + kapat ust satirda kalir. */
'@media(max-width:560px){.mrxUst a.mrxUye{order:5;flex:1 1 40%;text-align:center}}'+
'#mrxKapat{margin-left:auto;appearance:none;border:1px solid var(--line2);background:transparent;'+
 'color:var(--ink);font-size:18px;border-radius:10px;padding:6px 13px;cursor:pointer}'+
'#mrxAra{width:100%;padding:13px 16px;border:1px solid var(--line2);border-radius:12px;'+
 'background:var(--yuzey);color:var(--ink);font-size:15px;font-family:inherit;margin-bottom:6px}'+
'#mrxAra:focus{outline:none;border-color:#f5a524;box-shadow:0 0 0 3px rgba(245,165,36,.18)}'+
'.mrxGrup{margin-top:24px}'+
'.mrxGrup>h3{font-size:12px;letter-spacing:1.5px;text-transform:uppercase;color:var(--dim);margin:0 0 12px;'+
 'font-weight:800;display:flex;align-items:center;gap:10px}'+
'.mrxGrup>h3:after{content:"";flex:1;height:1px;background:var(--line)}'+
'.mrxGrid{display:grid;grid-template-columns:repeat(3,1fr);gap:10px}'+
'@media(max-width:860px){.mrxGrid{grid-template-columns:repeat(2,1fr)}}'+
'@media(max-width:540px){.mrxGrid{grid-template-columns:1fr}}'+
'.mrxArac{display:flex;gap:11px;align-items:flex-start;padding:12px 14px;border:1px solid var(--line);'+
 'border-radius:13px;background:var(--kagit);text-decoration:none;color:var(--ink);transition:border-color .15s}'+
'.mrxArac:hover{border-color:rgba(245,165,36,.45)}'+
'.mrxArac .em{font-size:20px;line-height:1;margin-top:2px}'+
'.mrxArac b{display:block;font-size:13.5px;letter-spacing:-.2px}'+
'.mrxArac span{display:block;font-size:12px;color:var(--muted);margin-top:2px;line-height:1.4}'+
'#mrxYok{display:none;text-align:center;color:var(--dim);padding:26px 0;font-size:14px}'+
/* 30.07 Cem: arac sayfalarinin tepesindeki duz "Tetikte" yazisi logoyu
   temsil etmiyordu. Ana sayfadaki marka yazisinin aynisi (kucuk harf,
   noktasiz i + ustunde kehribar lamba noktasi) buradan her sayfaya girer. */
'.mrxMarka{font-weight:800 !important;font-size:18px !important;letter-spacing:-.6px;'+
 'color:var(--ink) !important;text-decoration:none !important;line-height:1}'+
'.mrxMarka .mi{position:relative}'+
'.mrxMarka .mi:after{content:"";position:absolute;left:50%;top:-3px;transform:translateX(-50%);'+
 'width:5px;height:5px;border-radius:50%;background:#f5a524;box-shadow:0 0 8px rgba(245,165,36,.8)}'+
'@media print{#mrxFab,#mrxKaplama{display:none!important}}';

function trU(s){return s.replace(/i/g,'İ').replace(/ı/g,'I').toLocaleUpperCase('tr-TR');}

/* ── GERİ BAĞLANTISI ─────────────────────────────────────────────────────
   NEDEN. Site 62 sayfa ve araçlar birbirine link veriyor; bir araçtan
   ötekine geçen kullanıcının sayfa İÇİNDE dönüş yolu yoktu — tek çare
   tarayıcının geri tuşuydu (mobilde tarayıcı çubuğu gizlenince görünmez).

   DÜRÜSTLÜK KURALI. Etiket ne yapacağını söyler:
   · site içinden gelindiyse → "Geri" (history.back — sayfa eski hâliyle açılır)
   · dışarıdan/doğrudan gelindiyse → "Ana sayfa" (geri gitmek siteden ÇIKARIRDI)
   Yani düğme hiçbir zaman yalan söylemez.

   YER. GOV.UK ölçüsü: en üstte, içerikten önce. Sayfanın kendi kabına
   (.top şeridi / .wrap) sokulur ki metin sütunuyla hizalı dursun; kap
   yoksa gövdenin başına 980px'lik kendi kabıyla girer.

   ERİŞİLEBİLİRLİK. Gerçek <a href> — JS kapalıyken de, orta tıkta da
   çalışır; klavye odağı halkası var; mobilde 44px dokunma hedefi. */
function geriKur(){
  if(document.getElementById('mrxGeri')) return;
  var ad=(location.pathname.split('/').pop()||'index.html');
  /* ana sayfada geri diye bir yer yok */
  if(!KOK && (ad==='index.html'||ad==='')) return;

  var icerden=false;
  try{
    var r=document.referrer;
    icerden = !!r && new URL(r).origin===location.origin && r.split('#')[0]!==location.href.split('#')[0];
  }catch(e){}

  var a=document.createElement('a');
  a.id='mrxGeri';
  a.href=KOK+'index.html';                      /* JS'siz/orta-tık düşüşü */
  a.innerHTML='<span class="ok" aria-hidden="true">←</span>'+(icerden?'Geri':'Ana sayfa');
  a.setAttribute('aria-label', icerden?'Önceki sayfaya dön':'Ana sayfaya git');
  if(icerden){
    a.addEventListener('click',function(e){
      if(e.metaKey||e.ctrlKey||e.shiftKey||e.button!==0) return;  /* yeni sekme hakkı */
      e.preventDefault(); history.back();
    });
  }

  var top=document.querySelector('.top');
  if(top){
    /* şeridin İLK ögesi olarak içine gir; ayracı şeridin kendi " · "
       diliyle yaz ki sonradan eklenmiş görünmesin */
    var ayrac=document.createElement('span');
    ayrac.className='mrxAyrac';
    ayrac.textContent=' · ';
    top.insertBefore(ayrac,top.firstChild);
    top.insertBefore(a,top.firstChild);
    return;
  }
  a.classList.add('mrxGeriPul');
  var wrap=document.querySelector('.wrap,main,article');
  if(wrap){ wrap.insertBefore(a,wrap.firstChild); return; }
  var kab=document.createElement('div');
  kab.style.cssText='max-width:980px;margin:0 auto;padding:18px 18px 0';
  kab.appendChild(a);
  document.body.insertBefore(kab,document.body.firstChild);
}

/* ── TEPE ŞERİDİ TAM GENİŞLİK (28.08.2026) ───────────────────────────────
   Cem: "site yarım ekran görünüyor".

   ÖLÇÜLDÜ (1440px pencere, alacak-radari.html): içerik kabı 820px, tepe
   şeridi de 820px — ama şeridin KENDİ koyu zemini var. Sonuç: krem
   sayfanın ortasında duran siyah bir levha; göz bunu "sayfa yarım"
   diye okuyor.

   RAKİP ÖLÇÜMÜ (aynı 1440px pencere, canlı):
   · Companies House: başlık şeridi 1425px = pencerenin TAMAMI,
     içindeki satır 960px (içerikle aynı sütun).
   · SimplyDuty: başlık şeridi 1425px = pencerenin tamamı.
   Yani profesyonel kalıp "içeriği genişlet" değil: ŞERİT tam genişlik,
   İÇİNDEKİ satır içerik sütunuyla hizalı. Metin sütununu genişletmek
   okunurluğu bozardı (820px zaten doğru satır uzunluğu).

   NASIL. Şeridi kabından negatif kenar boşluğuyla taşırıp aynı miktarda
   iç dolgu veriyoruz: kutu ekranı kaplıyor, yazı yerinden kımıldamıyor.
   Ölçü vw ile değil documentElement.clientWidth ile alınır — vw kaydırma
   çubuğunu da sayar ve yatay kaydırma doğurur.

   YALNIZ zemini olan şeritlere dokunulur; koyu temalı sayfalarda şerit
   saydamdır, orada taşırmanın görünür bir karşılığı yoktur. */
function seritTamGenislik(){
  var t=document.querySelector('.top');
  if(!t) return;
  var cs=getComputedStyle(t);
  var z=cs.backgroundColor||'';
  if(!z || z==='transparent' || /^rgba\(0, 0, 0, 0\)$/.test(z)) return;

  /* Hesabı JS'e yaptırmak KIRILGAN çıktı: pencere değiştiğinde ölçüm
     ortamında ne resize olayı ne ResizeObserver ateşledi, şerit 1425px'te
     donup kaldı. Bu yüzden JS'in tek işi işareti koymak; ölçüyü tarayıcı
     kendi yapıyor (yukarıdaki @supports bloğu), yani hiçbir olaya
     bağımlı değil ve her pencere boyunda kendiliğinden doğru.

     İç dolguya şeridin KENDİ dolgusu EKLENMEZ; eklenseydi şerit yazısı
     içerik sütunundan 18px içeride kalırdı (ölçüldü: şerit 339, h1 321).
     Companies House ölçüsü de bu: başlık satırı ile içerik sütunu birebir
     aynı hizada. */
  t.classList.add('mrxSeritGenis');
}

/* ── ORTAK ÜST ŞERİT (04.10.2026, Cem: "üst şerit de ana sayfa gibi olsun - yap bunları da") ──────────────
   Ana sayfa V2 madde 4/5 menüsüyle yenilendi; alt sayfalarda her biri farklı bir ".top" iz satırı kalmıştı
   ("Tetikte · Soru çöz · Seviye testi", "tetikte", "T Tetikte · Genç Müşavir"...). Artık alt sayfanın .top'u kaldırılır,
   yerine ana sayfadakiyle AYNI şerit gelir: tetikte · Sınavlar · Fiyatlar · Giriş yap/Hesabım · [Ücretsiz başla].
   komut.js "Ara"yı ve tema düğmesini "nav .navlinks"e koyar -> yerleri aynı kalır. Logo ana sayfaya döndüğü için
   "← Geri" pulu bu şeritte kurulmaz. DOKUNULMAZ: ana sayfa (kendi #nav'ı) · kaydir/ soru kartları (uygulama şeridi) · perde.
   Renk yalnız jeton; stil-acik.css'in "nav .navlinks a{... !important}" kuralı daha özgül seçiciyle aşılır. */
function ustSeritKur(){
  var ad=(location.pathname.split('/').pop()||'index.html').toLowerCase();
  if(!KOK && (ad==='index.html'||ad==='')) return false;
  if(/\/kaydir\//.test(location.pathname)) return false;
  if(document.getElementById('ttUst')||document.getElementById('nav')) return false;
  var top=document.querySelector('.top'); if(!top) return false;
  var uye=false; try{ uye=Object.keys(localStorage).some(function(k){ return k.indexOf('-auth-token')>-1; }); }catch(e){}
  var st=document.createElement('style'); st.id='ttUstStil';
  st.textContent='html body #ttUst{position:sticky;top:0;z-index:50;background:var(--bg);border-bottom:1px solid var(--line);font-family:-apple-system,"Segoe UI",system-ui,Roboto,Arial,sans-serif}'+
    '#ttUst .ic{max-width:1120px;margin:0 auto;padding:0 20px;display:flex;align-items:center;gap:22px;height:64px}'+
    'html body #ttUst a.ust-logo{display:flex;align-items:center;gap:9px;text-decoration:none;font-weight:800;font-size:21px;letter-spacing:-.4px;color:var(--ink)!important}'+
    '#ttUst a.ust-logo i{width:11px;height:11px;border-radius:50%;background:var(--amber-dolgu);display:inline-block}'+
    '#ttUst .navlinks{margin-left:auto;display:flex;align-items:center;gap:20px}'+
    'html body #ttUst .navlinks a.nl{color:var(--muted)!important;text-decoration:none;font-weight:600;font-size:15.5px}'+
    'html body #ttUst .navlinks a.nl:hover,html body #ttUst .navlinks a.nl[aria-current=page]{color:var(--ink)!important}'+
    'html body #ttUst .navlinks a.ust-cta{display:inline-flex;align-items:center;min-height:42px;padding:0 16px;border-radius:10px;background:var(--ink);color:var(--bg)!important;font-weight:750;font-size:15px;text-decoration:none;white-space:nowrap}'+
    '#ttUst a:focus-visible{outline:3px solid var(--link);outline-offset:3px;border-radius:6px}'+
    '@media(max-width:760px){#ttUst .navlinks a.nl{display:none}#ttUst .ic{gap:10px}#ttUst .navlinks{gap:10px}}'+
    '@media(max-width:420px){html body #ttUst a.ust-logo{font-size:19px}html body #ttUst .navlinks a.ust-cta{padding:0 12px}}'+
    /* 04.10 mobil taşma kapısı: 320 px'te yasal sayfalarda şerit 335 px oldu (logo + Ara + tema + düğme) -> en darda sıkılaşır */
    '@media(max-width:360px){#ttUst .ic{padding:0 10px;gap:6px}#ttUst .navlinks{gap:5px}html body #ttUst a.ust-logo{font-size:17px;gap:6px}html body #ttUst .navlinks a.ust-cta{padding:0 9px;font-size:13.5px;min-height:40px}#ttUst .kp-dugme kbd{display:none}}'+
    '@media(min-width:761px){#mrxFab{display:none!important}}';
  document.head.appendChild(st);
  var n=document.createElement('nav'); n.id='ttUst'; n.setAttribute('aria-label','Ana menü');
  function bag(h,y){ return '<a class="nl" href="'+KOK+h+'"'+(ad===h?' aria-current="page"':'')+'>'+y+'</a>'; }
  n.innerHTML='<div class="ic"><a class="marka ust-logo" href="'+KOK+'index.html" aria-label="Tetikte ana sayfa" style="--marka-olcu:28px"><span class="marka-lamba" aria-hidden="true"></span><b class="marka-ad">tet<span class="i">ı</span>kte</b></a><div class="navlinks">'+
    bag('sorular.html','Sınavlar')+bag('fiyat.html','Fiyatlar')+bag('ogrenci.html',uye?'Hesabım':'Giriş yap')+
    /* 04.10 Cem'in ekranı: giriş yapmış üyeye "Ücretsiz başla" çıkıyordu -> üyeye "Soru çöz" (sınav seçimi) */
    (uye ? '<a class="ust-cta" href="'+KOK+'sorular.html">Soru çöz</a>' : '<a class="ust-cta" href="'+KOK+'seviye-testi.html">Ücretsiz başla</a>')+'</div></div>';
  top.parentNode.removeChild(top);
  document.body.insertBefore(n,document.body.firstChild);
  return true;
}

function kur(){
  var st=document.createElement('style'); st.textContent=css; document.head.appendChild(st);
  var ortakSerit=false; try{ ortakSerit=ustSeritKur(); }catch(e){}
  /* 07.10: tema-bas.js eski .top iz satırını bu ana dek gizliyordu (görünüp kaybolmasın) - şerit kuruldu ya da kurulmayacak, aç */
  document.documentElement.classList.remove('tt-ust-bekle');
  if(!ortakSerit){ try{ geriKur(); }catch(e){} }
  try{ seritTamGenislik(); }catch(e){}

  /* 07.10 Cem ("gizleme, kaldır"): yüzen "☰ Araçlar" düğmesi ve açtığı katalog paneli KALKTI. Gezinti üst şerit
     (Sınavlar · Fiyatlar · Hesabım · Ara) + telefonda alt menü. GRUPLAR listesi yalnız kayıt olarak duruyor. */

  /* 03.10.2026 MOBİL ALT MENÜ (Cem, V2 madde 24 "hepsini yap"): telefonda (<760 px) öğrenci sayfalarının altında
     Ana sayfa · Sınavlar · Yanlışlar · Deneme · Hesabım. Yalnız aşağıdaki listedeki sayfalarda; satın alma (kendi
     tutar çubuğu var), soru çözme ve sınav ekranlarında ÇIKMAZ. Bu sayfalarda yüzen "Araçlar" düğmesi telefonda gizlenir
     (ikisi üst üste biniyordu). Masaüstünde hiçbir şey değişmez. */
  (function(){
    var yol=(location.pathname.split('/').pop()||'index.html').toLowerCase();
    var SAYFALAR=['','index.html','sorular.html','yanlislarim.html','ogrenci.html','fiyat.html','ucretsiz-dene.html'];
    if(SAYFALAR.indexOf(yol)<0) return;
    var OGELER=[['index.html','Ana sayfa','M3 11l9-7 9 7v9a1 1 0 0 1-1 1h-5v-6h-6v6H4a1 1 0 0 1-1-1z'],
                ['sorular.html','Sınavlar','M5 4h14v16H5zM8 8h8M8 12h8M8 16h5'],
                ['yanlislarim.html','Yanlışlar','M4 12a8 8 0 1 0 2.3-5.6M4 4v4h4'],
                ['sinav-gibi.html','Deneme','M12 7v5l3 2M12 21a9 9 0 1 1 0-18 9 9 0 0 1 0 18z'],
                ['ogrenci.html','Hesabım','M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM4 21a8 8 0 0 1 16 0']];
    var aktif=yol===''?'index.html':yol;
    var st2=document.createElement('style');
    st2.textContent='#ttAltMenu{display:none}'
      +'@media(max-width:759px){#ttAltMenu{display:flex;position:fixed;left:0;right:0;bottom:0;z-index:60;background:var(--kagit,var(--panel));'
      +'border-top:1px solid var(--line2);padding:4px 4px calc(4px + env(safe-area-inset-bottom))}'
      +'#ttAltMenu a{flex:1;display:flex;flex-direction:column;align-items:center;gap:2px;min-height:52px;justify-content:center;'
      +'font-size:11.5px;font-weight:600;color:var(--muted);text-decoration:none}'
      +'#ttAltMenu a[aria-current=page]{color:var(--ink)}#ttAltMenu a[aria-current=page] svg{stroke:var(--amber-dolgu)}'
      +'#ttAltMenu svg{width:22px;height:22px;fill:none;stroke:currentColor;stroke-width:1.8;stroke-linecap:round;stroke-linejoin:round}'
      +'body.tt-alt-menu{padding-bottom:calc(64px + env(safe-area-inset-bottom))}body.tt-alt-menu #mrxFab{display:none!important}'
      /* 03.10 canlı tarama: telefonda üst şeritteki ☰ ekrandan taşıp kesiliyordu, "Ücretsiz başla" iki satıra kırılıyordu.
         Alt menü gezinmeyi taşıdığı için bu sayfalarda ☰ gizlenir, üst düğme tek satır kalır. */
      +'body.tt-alt-menu .mobbtn{display:none!important}body.tt-alt-menu #nav a.btn{white-space:nowrap}}';
    document.head.appendChild(st2);
    /* 03.10 canlı tarama: <nav> idi; index.html'in genel "nav{position:fixed;top:0…}" kuralı bunu da yakalıyordu ->
       telefonda menü bütün ekranı kaplayıp ana sayfayı örttü. Öğe <div role=navigation>; sayfa nav kuralları uygulanmaz. */
    var nav=document.createElement('div'); nav.id='ttAltMenu'; nav.setAttribute('role','navigation'); nav.setAttribute('aria-label','Alt menü');
    nav.innerHTML=OGELER.map(function(o){
      return '<a href="'+o[0]+'"'+(o[0]===aktif?' aria-current="page"':'')+'><svg viewBox="0 0 24 24" aria-hidden="true"><path d="'+o[2]+'"/></svg>'+o[1]+'</a>';
    }).join('');
    document.body.appendChild(nav); document.body.classList.add('tt-alt-menu');
    /* 03.10 canlı tarama: koyu zeminli sayfada (sorular.html, body.bz-koyu) jetonlar açık temadan geliyordu -> beyaz şerit üstünde
       açık yazı, etkin etiket görünmüyordu. Renkler sayfanın KENDİ zemin/yazı renginden alınır; her temada uyumlu. */
    /* 04.10 telefon turu: renk yalnız açılışta okunuyordu -> koyu temaya geçince alt menü kırık beyaz kalıyordu.
       Tema değişince ('tt-tema' olayı) yeniden okunur; tema geçişi bitsin diye bir kare beklenir. */
    function renkAl(){ try{ var bs=getComputedStyle(document.body), zemin=bs.backgroundColor, yazi=bs.color;
      if(zemin && zemin!=='rgba(0, 0, 0, 0)' && zemin!=='transparent'){ nav.style.background=zemin; }
      if(yazi){ nav.style.color=yazi; nav.style.borderTopColor='color-mix(in srgb,'+yazi+' 16%,transparent)';
        [].forEach.call(nav.querySelectorAll('a'),function(a){ a.style.color=yazi; a.style.opacity=a.getAttribute('aria-current')?'1':'.72'; if(a.getAttribute('aria-current')) a.style.fontWeight='800'; }); }
    }catch(e){} }
    renkAl();
    document.addEventListener('tt-tema',function(){ setTimeout(renkAl,60); setTimeout(renkAl,400); setTimeout(renkAl,900); });
  })();

  /* ============================================================================
     TEMA DÜĞMESİ (16.09.2026) — Cem: "site koyu, beyaz bir koyu yapalım; bir de oraya
     bir şey koy, bas beyaz olsun." Açık/koyu artık ZİYARETÇİNİN kararı.

     NASIL: açık tema tek bir dosyadan geliyor (stil-acik.css, her sayfada en sonda bağlı).
     Düğme o bağlantıyı devre dışı bırakır -> altındaki stil.css (koyu palet) ortaya çıkar;
     yeniden açınca açık temaya döner. Yani iki ayrı palet bakımı YOK, tek anahtar var.
     Tercih cihazda saklanır (tt_tema) ve her sayfada geçerlidir - menu.js her sayfada yüklü.
     Kaydır-Çöz'ün kendi anahtarı (kc_tema) ayrıdır, ona dokunulmaz.
     ⚠ Açık tema dosyası bağlı olmayan sayfada düğme HİÇ çıkmaz (zaten koyudur).
     ============================================================================ */
  /* 23.09.2026 — TEK TEMA (Cem: "renk her yerde tümden değişsin, üstten değiştirsinler"): anahtar artık
     Kaydır-Çöz'le ORTAK kc_tema ('dark'/'light'), kaynağı tema-bas.js (<head>'de, çizimden önce). Düğme sağ
     alttan ÜST ŞERİDE, Ara düğmesinin yanına taşındı (komut.js'in kullandığı yer: nav .navlinks / .top);
     şerit olmayan sayfada sağ üstte sabit durur. tema-bas.js yüklenmemiş eski sayfada da aynı anahtarla çalışır. */
  (function(){
    var baglar=[].slice.call(document.querySelectorAll('link[rel="stylesheet"]')).filter(function(l){
      return /stil-acik\.css/.test(l.getAttribute('href')||'');
    });
    if(!baglar.length) return;
    var T=window.TetikteTema||{
      oku:function(){ try{ var t=localStorage.getItem('kc_tema'); if(t==='dark'||t==='light') return t; return localStorage.getItem('tt_tema')==='koyu'?'dark':'light'; }catch(e){ return 'light'; } },   /* 04.10: varsayılan açık (tema-bas.js ile aynı) */
      yaz:function(t){ try{ localStorage.setItem('kc_tema',t); localStorage.removeItem('tt_tema'); }catch(e){} this.uygula(t); try{ document.dispatchEvent(new CustomEvent('tt-tema',{detail:t})); }catch(e){} },
      uygula:function(t){ baglar.forEach(function(l){ l.disabled=(t==='dark'); }); if(t==='dark') document.documentElement.setAttribute('data-theme','dark'); else document.documentElement.removeAttribute('data-theme'); }
    };
    var dugme=document.createElement('button');
    dugme.id='mrxTema'; dugme.type='button';
    function yaz(){ var koyu=T.oku()==='dark';
      dugme.textContent = koyu ? '☀' : '☾';
      dugme.title = koyu ? 'Açık temaya geç' : 'Koyu temaya geç';
      dugme.setAttribute('aria-label',dugme.title);
    }
    dugme.addEventListener('click',function(){ T.yaz(T.oku()==='dark'?'light':'dark'); yaz(); });
    document.addEventListener('tt-tema',yaz);
    T.uygula(T.oku()); yaz();
    /* yer: Ara düğmesinin hemen yanı; komut.js düğmeyi DOMContentLoaded'da kurar -> kısa süre beklenir */
    /* true = Ara'nın yanına oturdu (son yer). Ara henüz yoksa şeride geçici konur; Ara gelince yanına taşınır. */
    function yerlestir(){
      var ara=document.querySelector('.kp-dugme');
      if(ara){ if(ara.nextSibling!==dugme) ara.parentNode.insertBefore(dugme,ara.nextSibling); dugme.className='mrxTemaSerit'; return true; }
      var yer=document.querySelector('[data-komut-dugme]')||document.querySelector('nav .navlinks')||document.querySelector('.top');
      if(yer){ if(dugme.parentNode!==yer){ if(yer.classList.contains('top')) yer.appendChild(dugme); else yer.insertBefore(dugme,yer.firstChild); } dugme.className='mrxTemaSerit'; return false; }
      if(!dugme.parentNode){ dugme.className='mrxTemaSabit'; document.body.appendChild(dugme); }
      return false;
    }
    var deneme=0;
    if(!yerlestir()){ var zaman=setInterval(function(){ if(yerlestir()||++deneme>20) clearInterval(zaman); },150); }
  })();

  window.MRMenu={ac:function(){},kapat:function(){}};   /* yalnız çift yükleme koruması (satır 5) */

  /* Marka yukseltici: yalniz tepe seritteki (yaninda lamba/logo olan)
     "Tetikte" linkini logo yazisina cevirir; metin ici linklere dokunmaz. */
  try {
    document.querySelectorAll('a').forEach(function(a){
      if(a.textContent.trim()!=='Tetikte') return;
      var p=a.previousElementSibling;
      var tepede=(p&&p.classList&&(p.classList.contains('logo')||p.classList.contains('lamba')))
        ||(a.parentElement&&a.parentElement.classList&&a.parentElement.classList.contains('top'));
      if(!tepede) return;
      a.classList.add('mrxMarka');
      a.innerHTML='tet<span class="mi">ı</span>kte';
    });
  } catch(e) {}

  /* ── YASAL FOOTER (30.07 kurumsallik taramasi, bulgu #7) ──────────────
     13 sayfada KVKK/iletisim baglantisi yoktu; menu.js her sayfada yuklu
     oldugundan footer BURADAN enjekte edilir - tek dosya, 13 sayfa duzelir.
     Sayfanin kendi footer'inda kvkk.html linki zaten varsa EKLENMEZ
     (iletisim.html gibi tam kunyeli sayfalarda cift footer olmasin). */
  try {
    if (!document.querySelector('a[href$="kvkk.html"]')) {
      var yf = document.createElement('div');
      yf.style.cssText = 'max-width:980px;margin:34px auto 0;padding:14px 18px 26px;border-top:1px solid var(--line);font-size:12px;color:var(--dim);font-family:inherit;line-height:1.8';
      yf.innerHTML = '<a href="' + KOK + 'iletisim.html" style="color:var(--muted);text-decoration:none">Hakkımızda ve İletişim</a> · ' +
        '<a href="' + KOK + 'on-bilgilendirme.html" style="color:var(--muted);text-decoration:none">Ön Bilgilendirme</a> · ' +
        '<a href="' + KOK + 'mesafeli-satis.html" style="color:var(--muted);text-decoration:none">Mesafeli Satış</a> · ' +
        '<a href="' + KOK + 'teslimat-iade.html" style="color:var(--muted);text-decoration:none">Teslimat & İade</a> · ' +
        '<a href="' + KOK + 'gizlilik-politikasi.html" style="color:var(--muted);text-decoration:none">Gizlilik ve Çerez</a> · ' +
        '<a href="' + KOK + 'uyelik-sozlesmesi.html" style="color:var(--muted);text-decoration:none">Üyelik Koşulları</a> · ' +
        '<a href="' + KOK + 'kvkk.html" style="color:var(--muted);text-decoration:none">KVKK Aydınlatma</a> · ' +
        /* 01.10 Cem: elçi programı herkese açık başvuru (Trendyol influencer deseni) */
        '<a href="' + KOK + 'elci-programi.html" style="color:var(--muted);text-decoration:none">Elçi Programı</a>' +
        '<br>' + TT_KIMLIK +
        '<br><span data-veri-damgasi></span>';
      document.body.appendChild(yf);
    }
  } catch (e) {}

  /* ── ÖDEME / GÜVEN BANDI (04.10.2026, Cem: iyzico başvuru şartı) ──────────────
     iyzico domainde istedi: Kimlik · Mesafeli Satış · Teslimat ve İade · İletişim · Gizlilik Politikası · SSL ·
     "iyzico ile Öde" + Visa + MasterCard logoları. Logolar iyzico'nun RESMÎ logo paketinden (docs.iyzico.com →
     Ek Bilgiler → iyzico Logo Paketi, footer_iyzico_ile_ode bandı; elle çizilmedi): gorsel/odeme/. Koyu temada beyaz bant.
     Sayfada #ttOdemeBandi varsa (ana sayfa kendi altbilgisinde taşır) eklenmez. */
  try { ttOdemeBandi(document.body); } catch (e) {}

  /* ── VERİ TAZELİK DAMGASI (25.08.2026) ─────────────────────────────────
     Cem: "bir daha site okunmayan eskide kalmayacak · son güncellenme
     damgasını siteye koy."

     NEDEN. Verinin tazeliğini bugüne kadar YALNIZ BİZ görüyorduk (tazelik
     nöbetçisi, veri kapısı). Ziyaretçi baktığı rakamın ne zamanki veriden
     geldiğini bilmiyordu. Ciddi hukuk yayıncılarının hepsinde bu damga var.
     Yan faydası: bayat veriyi BİZ görmesek de müşteri görür — ikinci göz.

     ÖLÇÜ. veri/tazelik-damgasi.json, her sayfanın çektiği veri dosyalarının
     SON GİT COMMIT tarihinden üretilir; dosyanın İÇİNDEKİ tarihten değil.
     (25.08 dersi: nice-siniflar.json içindeki "30.12.2016" kaynak tebliğin
      RG tarihiydi, bayatlık damgası değil.)

     DÜRÜSTLÜK. Tek rakam gösterip diğerini saklamıyoruz: görünen "son" (veri
     en son ne zaman değişti), ipucu metninde "en eski" de var. Sözleşmedeki
     azami yaş aşılmışsa damga UYARIYA döner — sessizce iyi göstermez.

     Damga bulunamazsa HİÇBİR ŞEY yazılmaz (yanlış tarih basmaktansa boş). */
  try {
    /* Damga yasal footer'dan BAGIMSIZ olmali. Yasal footer yalniz sayfada
       kvkk.html linki YOKSA basiliyor; gtip.html gibi kendi kunyesi olan
       sayfalarda basilmiyor ve damga da onunla birlikte dusuyordu (canli
       olculdu: gtip.html'de [data-veri-damgasi] hic olusmadi). Bu yuzden
       yer bulunamazsa KENDI kabini olusturur. */
    var yer = document.querySelector('[data-veri-damgasi]');
    /* 25.09 Cem: "burda veri güncelleme niye var, böyle eski tarihler sitede olmasın, kaldıralım".
       Sayfa dibi "Veri son güncelleme" satırı KAPALI. Soru/seviye sayfalarında ziyaretçiye bilgi vermiyor, yalnız
       eski tarih gösteriyordu (seviye-testi.html "13.09.2026"); rakip sınav sitelerinde (UWorld, Becker) böyle satır yok.
       Tazeliği önemli sayfaların KENDİ damgası var (Alacak "en yeni ilan" + 3 gün bayatlık uyarısı, ana sayfa
       "Bu sabahın nöbeti"). Ölçüm yerinde: veri/tazelik-damgasi.json + arac/veri-tazelik.ps1 çalışmaya devam eder.
       Geri açmak için alttaki koşulu true yap. */
    if (false) {
      fetch(KOK + 'veri/tazelik-damgasi.json', { cache: 'no-store' })
        .then(function (r) { return r.ok ? r.json() : null; })
        .then(function (d) {
          if (!d || !d.sayfalar) return;
          var ad = (location.pathname.split('/').pop() || 'index.html');
          if (!ad) ad = 'index.html';
          var k = d.sayfalar[ad];
          if (!k || !k.son) return;                     // bu sayfa veri çekmiyorsa sus
          /* Kap ancak GOSTERILECEK BIR SEY VARSA olusturulur. Onceki surumde
             kap her sayfada pesin yaratiliyordu ve veri cekmeyen 27 sayfada
             (kvkk.html gibi) BOS kalip 22px bosluk birakiyordu - canli
             olculdu. Bos kap birakmaktansa hic birakma. */
          if (!yer) {
            var kab = document.createElement('div');
            kab.style.cssText = 'max-width:980px;margin:0 auto;padding:0 18px 22px;font-size:12px;color:var(--dim);font-family:inherit;line-height:1.8';
            kab.innerHTML = '<span data-veri-damgasi></span>';
            document.body.appendChild(kab);
            yer = kab.firstChild;
          }
          if (!yer) return;
          var gg = function (s) { var p = s.split('-'); return p[2] + '.' + p[1] + '.' + p[0]; };
          var ipucu = 'Bu sayfanın kullandığı ' + k.dosya + ' veri dosyası. ' +
                      'En eski veri: ' + gg(k.en_eski) + '. Ölçü: verinin depoya son işlendiği an.';
          yer.innerHTML = (k.bayat ? '⚠ ' : '') + 'Veri son güncelleme: ' +
            '<time datetime="' + k.son + '" title="' + ipucu + '" style="color:var(--muted)">' + gg(k.son) + '</time>' +
            (k.bayat ? ' <span style="color:var(--muted)">(beklenen tazelik aşıldı)</span>' : '');
        })
        .catch(function () { /* damga yoksa sessiz kal */ });
    }
  } catch (e) {}
}
if(document.readyState==='loading') document.addEventListener('DOMContentLoaded',kur); else kur();
})();

/* 31.07 Cem: "5 sorgu sonrasi uyelik - her yerde AYNI mantik" (deneme'deki
   5-soru duvarinin arac karsiligi). Ortak sayac: her arac kendi anahtariyla
   cagirir; uye (ayni alan adinda Supabase oturumu) sinirsiz. Donus: true =
   devam, false = duvar (cagiran sayfa uyelik kapisini gosterir). */
/* Ortak duvar: hak bittiyse standart kapak (modal) gosterir, false doner.
   Her aracin hesap fonksiyonu ilk satirda cagirir: if(!ttSorguKapisi('x'))return; */
function ttSorguKapisi(anahtar){
  if (ttSorguHakki(anahtar)) return true;
  try {
    var eski = document.getElementById('ttDuvar'); if (eski) eski.remove();
    var d = document.createElement('div');
    d.id = 'ttDuvar';
    d.style.cssText = 'position:fixed;inset:0;background:rgba(3,6,10,.82);z-index:9999;display:grid;place-items:center;padding:20px';
    d.innerHTML = '<div style="max-width:430px;background:var(--kagit);border:1px solid rgba(255,194,75,.4);border-radius:16px;padding:26px;text-align:center;font-family:inherit">' +
      '<div style="font-size:19px;font-weight:800;color:var(--ink);margin-bottom:8px">Bu ayın 5 bedava sorgusunu kullandın</div>' +
      '<div style="font-size:13.5px;color:var(--muted);line-height:1.6;margin-bottom:16px">Ücretsiz üyelikte tüm araçlar sınırsız — üstelik panelde firmanı tanıt, robot seni ilgilendiren değişiklikte haber versin.</div>' +
      '<a href="radar-app.html" style="display:inline-block;background:linear-gradient(135deg,var(--marka-lamba-1),var(--marka-lamba-2));color:#0f1115;font-weight:800;font-size:15px;padding:12px 22px;border-radius:12px;text-decoration:none">Ücretsiz üye ol →</a>' +
      '<div style="margin-top:12px"><a href="#" onclick="document.getElementById(\'ttDuvar\').remove();return false" style="color:var(--dim);font-size:12.5px">kapat</a></div></div>';
    document.body.appendChild(d);
  } catch (e) {}
  return false;
}
function ttSorguHakki(anahtar){
  try {
    /* ==== ONIZLEME-SINIRSIZ-BASI (gong.ps1 bu isaretler arasini siler - ELLE DOKUNMA) ==== */
    /* 20.08 Cem: "perde koduyla girene sinirsiz ver, acilista kapat".
       ?kapi=... ile bir kez giren DENEME cihazinda arac sayaci hic islemez;
       deneyen kisi uye olmadan butun araclari sinirsiz kullanir. Perde kalkinca
       bu blok da gong.ps1 tarafindan silinir - o an herkes normal 5 hakka doner. */
    if (localStorage.getItem('mrOnizleme') === '1') return true;
    /* ==== ONIZLEME-SINIRSIZ-SONU ==== */
    var uye = Object.keys(localStorage).some(function(k){ return k.indexOf('-auth-token') > -1; });
    if (uye) return true;
    // 31.07 Cem onayi: sayac AYLIK sifirlanir (NYT/Similarweb modeli - ayda 5 hak;
    // donen ziyaretci duvarda kalmasin). Anahtara ay damgasi gomulur.
    var simdi = new Date();
    var ay = simdi.getFullYear() + '-' + (simdi.getMonth() + 1);
    var ad = 'ttSayac_' + anahtar + '_' + ay;
    var n = parseInt(localStorage.getItem(ad) || '0', 10) || 0;
    if (n >= 5) return false;
    localStorage.setItem(ad, String(n + 1));
    return true;
  } catch (e) { return true; }
}

/* ---- GİZLİ ARAÇLAR (24.09.2026) --------------------------------------------
   Cem: "bunları da kaldıralım, sistem yenileme varsa devam edebilir, şu an sadece
   sitede görünmesin". Sayfalar ve robotları YERİNDE; yalnız bağlantılar görünmez.
   Menü/katalog/Ctrl+K/site haritasından elle çıkarıldı; sayfa İÇİNDEKİ bağlantılar
   (11 sayfada 28 adet) burada süzülür: düğme ya da "→" bağlantısı kalkar, cümle
   içindeki bağlantı düz yazıya döner. Geri açmak: adı bu listeden sil + menü/komut/
   sitemap satırlarını geri koy (commit "işletme araçları gizlendi").
   Kendi sayfasında süzmez (kendine bağ). ------------------------------------ */
(function () {
  /* 30.09 Cem "site sadece SMMM başlama + bitirme": gümrük, radar, marka, alacak, rehber ve işletme paneli de gizli. */
  /* 02.10: tuzak (Günün Tuzağı) eklendi — robot 0 soru tarıyor, sayfa boş. Geri almak: "tuzak|" sil. */
  /* 07.10 Cem ("ulaşamasın bunlara"): genc · donem-plani · songun · karsilastirma GİZLİ; sayfalar silinmedi. Geri almak: "genc|donem-plani|songun|karsilastirma" sil + sitemap + komut.js. */
  var GIZLI = /(^|\/)(tuzak|ceza-asistani|asgari-kv|arge-kapi-hesabi|kurulus-evrak|kurulus-nobeti|karne|bilgi|sayfalar\/index|gtip|toplu-gtip|risk-taramasi|senaryo-raporu|hizmet|fiyatfarki|soru-cevap|kurulus|tesvik-sihirbazi|radar|kartlar|destekler|alacak-radari|alacakli-rehberi|marka-radari|marka-portfoy|marka-izleme|marka-itiraz|marka-varlik|marka-app|marka-rapor|radar-app|radar-fiyat|canli-deneme|genc|donem-plani|songun|karsilastirma)\.html(?:[?#]|$)/;
  /* 03.10 V2 madde 39 (+36): gizli sayfalar bağlantısız ama doğrudan adresle açılıyordu (dosya yükleyen beyanname-oku /
     risk-taramasi ücretli model çağırıyor). Önizleme cihazı (?kapi= ile tanınmış, mrOnizleme=1) dışında ana sayfaya döner.
     Sayfalar SİLİNMEDİ ("silmiyoruz, gizliyoruz"). GÖRMEZ: sunucu uçlarını doğrudan çağıran; o koruma uçlardaki hız sınırında. */
  try {
    if (GIZLI.test(location.pathname) && localStorage.getItem('mrOnizleme') !== '1') { location.replace('/index.html'); return; }
  } catch (e) {}
  function suz() {
    var kendi = location.pathname;
    [].forEach.call(document.querySelectorAll('a[href]'), function (a) {
      var h = a.getAttribute('href') || '';
      if (/^(https?:)?\/\//.test(h) && h.indexOf(location.host) < 0) return;
      if (!GIZLI.test(h.replace(/^https?:\/\/[^\/]+/, ''))) return;
      if (GIZLI.test(kendi)) return;
      var metin = (a.textContent || '').trim();
      var dugme = /btn|dugme|kart|arac|mp\b/.test(a.className || '') || /→|›|»/.test(metin) || a.querySelector('div,b,img');
      if (dugme) { a.remove(); return; }
      var s = document.createElement('span'); s.textContent = a.textContent; a.replaceWith(s);
    });
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', suz); else suz();
})();
