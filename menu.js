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
  var yasalMuaf = /(?:^|\/)(mesafeli-satis|teslimat-iade|iletisim|kvkk)\.html$/.test(location.pathname);
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
        '<p style="color:var(--muted);font-size:15px;line-height:1.65;margin:0 0 20px"><b style="color:var(--ink)">İşinin nöbetçisi çok yakında.</b><br>Mevzuatı senin yerine izleyen sistem son hazırlıklarını yapıyor. Açılışta ilk sen haber al — Kurucu Üye avantajı ilk gelenlerin.</p>'+
        '<form id="mrPerdeForm" style="display:flex;gap:8px;flex-wrap:wrap;justify-content:center">'+
        '<input type="email" required placeholder="e-posta adresin" style="flex:1;min-width:200px;background:var(--kagit);border:1px solid rgba(255,255,255,.14);border-radius:11px;color:var(--ink);font:inherit;font-size:14px;padding:12px 14px">'+
        '<button type="submit" style="background:linear-gradient(135deg,#f5a524,#ffc24b);color:#03101f;font-weight:800;font-size:14px;padding:12px 22px;border:none;border-radius:11px;cursor:pointer">Haber ver →</button>'+
        /* 30.07: pasif "katilinca kabul edersin" satiri acik riza DEGILDI -
           karne formundaki gibi zorunlu onay kutusuna cevrildi (KVKK).
           kvkk.html koku: perde alt sayfalarda da cikar, mutlak yol sart. */
        '<label style="display:flex;gap:8px;align-items:flex-start;width:100%;justify-content:center;font-size:11.5px;color:var(--muted);margin-top:10px;text-align:left"><input type="checkbox" required style="margin-top:2px;accent-color:#f5a524;flex:none;width:16px;height:16px;padding:0">'+
        '<span style="max-width:400px">E-postamın, Tetikte açılış bilgilendirmeleri için işlenmesine izin veriyorum. İstediğimde çıkabilirim. <a href="/kvkk.html" target="_blank" style="color:#ffc24b">Aydınlatma metni</a></span></label></form>'+
        '<div id="mrPerdeOk" style="display:none;color:#3ddc97;font-weight:700;font-size:14px;margin-top:12px">✓ Kaydın alındı — açılışta ilk sen duyacaksın.</div></div>';
      document.body.appendChild(d);
      document.documentElement.style.overflow = 'hidden';
      document.getElementById('mrPerdeForm').addEventListener('submit', function(e){
        e.preventDefault();
        var em = this.querySelector('input').value.trim();
        if(!em) return;
        try { fetch('https://api.web3forms.com/submit',{method:'POST',headers:{'Content-Type':'application/json',Accept:'application/json'},body:JSON.stringify({access_key:'5b227e56-94fb-4123-a39a-4286f63db14a',email:em,subject:'ACILIS PERDESI erken kayit',from_name:'Tetikte Perde'})}); } catch(err){}
        this.style.display='none';
        document.getElementById('mrPerdeOk').style.display='block';
      });
    };
    if (document.body) { perde(); } else { document.addEventListener('DOMContentLoaded', perde); }
    return; /* perde varken menu de kurulmasin */
  }
} catch(e) {}
/* ==== PERDE-SONU (gong.ps1 isaretli blogu buraya kadar siler) ==== */

var GRUPLAR=[
 {ad:"🛃 Gümrük & İthalat", araclar:[
  ["gtip.html","🔎","GTİP · Kaç Vergi Öderim?","İthalatta gümrük vergisi, KDV ve kesintiler"],
  ["risk-taramasi.html","🛃","Beyanname Risk Taraması","Beyandan önce ceza kapılarını tara"],
  ["senaryo-raporu.html","🌍","Nereden Alsam?","Ülke ülke toplam vergi yükü karşılaştırma"],
  ["hizmet.html","🌐","Yurt Dışı Hizmet Faturası","2 No.lu KDV + stopaj hesabı"],
  ["fiyatfarki.html","💱","Credit / Debit Note","Sonradan gelen fiyat farkının vergisi"],
  ["toplu-gtip.html","📑","Toplu GTİP Kontrolü","Excel'ini yapıştır, kalem kalem vergi yükü"]]},
 {ad:"🧾 Vergi, Ceza & Rehberler", araclar:[
  ["soru-cevap.html","💬","Net Cevap","Mevzuat sorunu sor, kaynaklı cevap al"],
  ["ceza-asistani.html","⚖️","Ceza Asistanı","İndirim mi, uzlaşma mı, dava mı?"],
  ["asgari-kv.html","🧾","Asgari Kurumlar Vergisi","%10 tabana takılıyor musun?"],
  ["kdv-iade-rehberi.html","💰","KDV İade Rehberi","İadeyi adım adım al"],
  ["kurulus.html","🏢","Şirket Kuruluşu Rehberi","Şahıs mı, limited mi, anonim mi?"],
  ["tesvik-sihirbazi.html","🧲","Yatırım Teşvik Sihirbazı","9903: bölgen, desteklerin, 2026 fırsatları"],
  ["arge-kapi-hesabi.html","🔬","Ar-Ge Kapısı Hesabı","Merkez / Teknokent / TÜBİTAK — yıllık TL farkı"],
  ["kurulus-evrak.html","🗂️","Kuruluş Evrak Çantası","Hangi belge, kim doldurur, nereye?"],
  ["karne.html","📋","Yükümlülük Karnesi","Firmana özel yükümlülük fotoğrafı, PDF'li"],
  ["sayfalar/index.html","✅","Eşik Rehberi","Hangi zorunluluklar seni kapsıyor?"],
  ["bilgi.html","📚","Bilgi Havuzu","Sade Türkçe özet + kaynak maddesi"],
  ["genc.html","🎓","Genç Müşavir","2026 sınav takvimi, geri sayımlı"],
  ["deneme.html","📝","Deneme Sınavı","Her şıkkın gerekçesi + kaynak kuralı"],
  ["canli-deneme.html","📡","Canlı Deneme","Türkiye geneli, aynı anda; gerçek yüzdelik sıralaman"],
  ["tuzak.html","🎯","Günün Tuzağı","Her gün bir soru — cevabı ve kanun maddesi açık"],
  ["karsilastirma.html","⚖️","Hangisi sana lazım?","Kurs, kitap, ücretsiz banka ve biz — dürüst tablo"],
  ["donem-plani.html","🗺️","Dönem Planı","Kalan haftaları haritayla faz faz doldur"],
  ["songun.html","⏳","Son Gün 5 Saat","Dönem finali + sınav sabahı rehberi"]]},
 {ad:"📡 Takip Radarları", araclar:[
  ["radar.html","📰","Bugün Resmî Gazete'de","Günün önemli mevzuat değişiklikleri"],
  ["kartlar.html","💊","Günün Hap Kartları","30 saniyelik özet kartlar"],
  ["destekler.html","🎯","Destek Radarı","Profiline uyan KOSGEB ve destekler"],
  ["ihale-radari.html","📣","İhale Radarı","Yurt içi + Avrupa ihaleleri"],
  ["firma-analizi.html","🔎","Rakip Firma Analizi","Firma hangi ihaleleri kaça aldı"],
  ["idare-analizi.html","🏛️","İdare Analizi","Kurum ne açtı, kaça kapandı, kaç teklif"],
  ["alacak-radari.html","🚨","Alacak Radarı","Müşterin konkordato/iflasta — ilk sen duy"],
  ["marka-radari.html","™️","Marka Radarı","Yenileme + benzer başvuru uyarısı"],
  ["marka-portfoy.html","📋","Marka Portföy Panosu","Tüm markaların, tüm tarihler tek ekranda"],
  ["marka-izleme.html","📡","Marka İzleme Radarı","Markana benzer YENİ başvuru düştü mü"],
  ["marka-itiraz.html","🔍","Marka İtiraz & Benzerlik","İtiraz süren dolmadan gör"],
  ["marka-varlik.html","💼","Markanla ne yapabilirsin","Lisans, devir, rehin, muvafakat, Madrid"],
  // 17.08: marka-app.html BITMIS ve CALISAN bir uygulamaydi ama SITEDE HICBIR
  // YERDEN ERISILEMIYORDU - ne menude ne bir sayfada linki vardi. Tarama
  // yakaladi. Ayni durum evrak-app.html'de de vardi (asagida).
  ["marka-app.html","🔐","Marka İzleme — hesabım","Markalarını ekle, yenilemeyi biz takip edelim"]]},
 {ad:"🧮 Muhasebe Bürosu (SMMM)", araclar:[
  ["fis-fabrikasi.html","🏭","Fiş Fabrikası","Banka ekstresi → programına hazır fiş"],
  ["evrak-radari.html","📁","Evrak Radarı","Mükelleften evrak kovalamayı bitir"],
  ["evrak-app.html","🔐","Evrak Radarı — hesabım","Liste oluştur, mükellefe link at, cevapları gör"],
  ["belge-kasasi.html","🗄️","Belge Kasası","Belgeler tek yerde, süreleri takipte"],
  ["hatirlatici.html","⏰","Süre Hatırlatıcı","DİİB · KDV · SGK kritik tarihleri"]]}
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
   geri tuşunun yerini almaz, onu görünür kılar. */
'#mrxGeri{display:inline-flex;align-items:center;gap:7px;margin:0 0 12px;padding:8px 14px 8px 11px;'+
 'border:1px solid var(--line2,rgba(255,255,255,.13));border-radius:999px;background:var(--yuzey,#0a0f17);'+
 'color:var(--muted,#93a1b3);text-decoration:none;letter-spacing:.1px;'+
 'font:600 13.5px/1 -apple-system,"Segoe UI",system-ui,Roboto,Arial,sans-serif;'+
 'transition:color .15s,border-color .15s,transform .15s}'+
'#mrxGeri:hover{color:var(--ink,#eef2f7);border-color:rgba(245,165,36,.45);transform:translateX(-2px)}'+
'#mrxGeri:focus-visible{outline:none;box-shadow:0 0 0 3px rgba(245,165,36,.35)}'+
'#mrxGeri .ok{font-size:15px;line-height:1}'+
/* mobilde 44px dokunma hedefi - menü linklerine 14.08'de uygulanan ölçünün aynısı */
/* 28.08 ölçüldü: 12px dolguda yükseklik 41px çıktı — 44px alt sınırın altında.
   14px'e çıkarıldı, yeniden ölçüldü. */
'@media(max-width:600px){#mrxGeri{padding:14px 16px;font-size:14px}}'+
'@media print{#mrxGeri{display:none!important}}'+
'#mrxFab{position:fixed;right:18px;bottom:18px;z-index:99990;appearance:none;border:1px solid rgba(255,255,255,.16);'+
 'background:linear-gradient(135deg,#f5a524,#ffc24b);color:#03101f;font-weight:800;font-size:14px;'+
 'font-family:-apple-system,"Segoe UI",system-ui,Roboto,Arial,sans-serif;padding:12px 18px;border-radius:999px;'+
 'cursor:pointer;box-shadow:0 8px 28px rgba(46,140,255,.45);letter-spacing:.2px;'+
 'transition:transform .28s ease,opacity .28s ease}'+
'#mrxFab:hover{transform:translateY(-2px)}'+
'#mrxFab.mrxGizli{transform:translateY(140%);opacity:0;pointer-events:none}'+
'#mrxKaplama{position:fixed;inset:0;z-index:99991;background:rgba(3,6,12,.82);backdrop-filter:blur(6px);'+
 'display:none;overflow-y:auto;font-family:-apple-system,"Segoe UI",system-ui,Roboto,Arial,sans-serif}'+
'#mrxKaplama.acik{display:block}'+
'.mrxIc{max-width:1000px;margin:0 auto;padding:26px 18px 60px;color:var(--ink)}'+
'.mrxUst{display:flex;align-items:center;gap:12px;margin-bottom:18px;flex-wrap:wrap}'+
'.mrxLogo{width:34px;height:34px;border-radius:9px;background:linear-gradient(135deg,#f5a524,#ffc24b);'+
 'display:grid;place-items:center;color:#03101f;font-weight:800;font-size:14px}'+
'.mrxUst b{font-size:16px}'+
'.mrxUst a{color:var(--muted);text-decoration:none;font-size:13.5px;font-weight:600;padding:8px 14px;'+
 'border:1px solid rgba(255,255,255,.14);border-radius:10px}'+
'.mrxUst a:hover{color:#fff}'+
'.mrxUst a.mrxUye{background:linear-gradient(135deg,#f5a524,#ffc24b);color:#03101f;border:0;font-weight:800}'+
'#mrxKapat{margin-left:auto;appearance:none;border:1px solid rgba(255,255,255,.16);background:transparent;'+
 'color:var(--ink);font-size:18px;border-radius:10px;padding:6px 13px;cursor:pointer}'+
'#mrxAra{width:100%;padding:13px 16px;border:1px solid rgba(255,255,255,.16);border-radius:12px;'+
 'background:var(--yuzey);color:var(--ink);font-size:15px;font-family:inherit;margin-bottom:6px}'+
'#mrxAra:focus{outline:none;border-color:#f5a524;box-shadow:0 0 0 3px rgba(245,165,36,.18)}'+
'.mrxGrup{margin-top:24px}'+
'.mrxGrup>h3{font-size:12px;letter-spacing:1.5px;text-transform:uppercase;color:var(--dim);margin:0 0 12px;'+
 'font-weight:800;display:flex;align-items:center;gap:10px}'+
'.mrxGrup>h3:after{content:"";flex:1;height:1px;background:rgba(255,255,255,.09)}'+
'.mrxGrid{display:grid;grid-template-columns:repeat(3,1fr);gap:10px}'+
'@media(max-width:860px){.mrxGrid{grid-template-columns:repeat(2,1fr)}}'+
'@media(max-width:540px){.mrxGrid{grid-template-columns:1fr}}'+
'.mrxArac{display:flex;gap:11px;align-items:flex-start;padding:12px 14px;border:1px solid rgba(255,255,255,.09);'+
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
  if(top && top.parentNode){ top.parentNode.insertBefore(a,top); return; }
  var wrap=document.querySelector('.wrap,main,article');
  if(wrap){ wrap.insertBefore(a,wrap.firstChild); return; }
  var kab=document.createElement('div');
  kab.style.cssText='max-width:980px;margin:0 auto;padding:18px 18px 0';
  kab.appendChild(a);
  document.body.insertBefore(kab,document.body.firstChild);
}

function kur(){
  var st=document.createElement('style'); st.textContent=css; document.head.appendChild(st);
  try{ geriKur(); }catch(e){}

  var fab=document.createElement('button');
  fab.id='mrxFab'; fab.type='button'; fab.textContent='☰ Araçlar';
  document.body.appendChild(fab);

  var kap=document.createElement('div'); kap.id='mrxKaplama';
  var h='<div class="mrxIc"><div class="mrxUst">'+
    '<span class="mrxLogo">T</span><b>Tetikte</b>'+
    '<a href="'+KOK+'index.html">Ana Sayfa</a><a class="mrxUye" href="'+KOK+'radar-app.html">Giriş / Üye Ol</a>'+
    '<button id="mrxKapat" type="button" aria-label="Kapat">✕</button></div>'+
    '<input id="mrxAra" type="search" placeholder="🔍  Araç ara: ceza, KDV, marka, ihale, fiş…" autocomplete="off">';
  GRUPLAR.forEach(function(g){
    h+='<div class="mrxGrup"><h3>'+g.ad+'</h3><div class="mrxGrid">';
    g.araclar.forEach(function(a){
      h+='<a class="mrxArac" href="'+KOK+a[0]+'"><span class="em">'+a[1]+'</span><div><b>'+a[2]+'</b><span>'+a[3]+'</span></div></a>';
    });
    h+='</div></div>';
  });
  h+='<div id="mrxYok">Eşleşen araç yok — başka bir kelime dene.</div></div>';
  kap.innerHTML=h;
  document.body.appendChild(kap);

  function ac(){ kap.classList.add('acik'); document.body.style.overflow='hidden';
    var a=document.getElementById('mrxAra'); a.value=''; suz(''); setTimeout(function(){a.focus();},50); }
  function kapat(){ kap.classList.remove('acik'); document.body.style.overflow=''; }
  function suz(t){
    t=trU(t.trim()); var toplam=0;
    kap.querySelectorAll('.mrxGrup').forEach(function(g){
      var sayi=0;
      g.querySelectorAll('.mrxArac').forEach(function(a){
        var ok=!t||trU(a.textContent).indexOf(t)>=0;
        a.style.display=ok?'flex':'none'; if(ok)sayi++;
      });
      g.style.display=sayi?'block':'none'; toplam+=sayi;
    });
    document.getElementById('mrxYok').style.display=toplam?'none':'block';
  }
  fab.addEventListener('click',ac);
  // Aşağı kaydırırken düğmeyi kenara çek (içeriği örtmesin), yukarı kaydırınca
  // ya da durunca geri getir. Panel açıkken ve sayfa başındayken hep görünür.
  var sonY=window.pageYOffset||0;
  function scr(){
    if(kap.classList.contains('acik')){ return; }
    var y=window.pageYOffset||0;
    if(y<160){ fab.classList.remove('mrxGizli'); }          // sayfa başı: hep görünür
    else if(y>sonY+6){ fab.classList.add('mrxGizli'); }     // aşağı: kenara çek
    else if(y<sonY-6){ fab.classList.remove('mrxGizli'); }  // yukarı: geri getir
    sonY=y;
  }
  window.addEventListener('scroll',scr,{passive:true});
  document.getElementById('mrxKapat').addEventListener('click',kapat);
  kap.addEventListener('click',function(e){ if(e.target===kap) kapat(); });
  document.addEventListener('keydown',function(e){ if(e.key==='Escape') kapat(); });
  document.getElementById('mrxAra').addEventListener('input',function(e){ suz(e.target.value); });

  window.MRMenu={ac:ac,kapat:kapat};

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
      yf.style.cssText = 'max-width:980px;margin:34px auto 0;padding:14px 18px 26px;border-top:1px solid rgba(255,255,255,.08);font-size:12px;color:var(--dim);font-family:inherit;line-height:1.8';
      yf.innerHTML = '<a href="' + KOK + 'kvkk.html" style="color:var(--muted);text-decoration:none">KVKK Aydınlatma</a> · ' +
        '<a href="' + KOK + 'uyelik-sozlesmesi.html" style="color:var(--muted);text-decoration:none">Üyelik Koşulları</a> · ' +
        '<a href="' + KOK + 'mesafeli-satis.html" style="color:var(--muted);text-decoration:none">Mesafeli Satış</a> · ' +
        '<a href="' + KOK + 'teslimat-iade.html" style="color:var(--muted);text-decoration:none">Teslimat & İade</a> · ' +
        '<a href="' + KOK + 'iletisim.html" style="color:var(--muted);text-decoration:none">İletişim</a>' +
        '<br>Dizdar Denetim ve Yazılım A.Ş. · İzmir · info@dizdardenetim.com' +
        '<br><span data-veri-damgasi></span>';
      document.body.appendChild(yf);
    }
  } catch (e) {}

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
    {
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
      '<a href="radar-app.html" style="display:inline-block;background:linear-gradient(135deg,#f5a524,#ffc24b);color:#03101f;font-weight:800;font-size:15px;padding:12px 22px;border-radius:12px;text-decoration:none">Ücretsiz üye ol →</a>' +
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
