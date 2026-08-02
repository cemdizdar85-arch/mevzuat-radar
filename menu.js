/* Tetikte — ortak araç menüsü.
   Her sayfaya <script src="menu.js" defer></script> ile eklenir:
   sağ altta "☰ Araçlar" düğmesi + tam ekran aranabilir katalog paneli. */
(function(){
if(window.MRMenu) return;

/* ---- AÇILIŞ PERDESİ (23.07.2026, Cem: site bitmeden insanlar gezmesin) ----
   Gizli anahtar: siteye bir kez ?kapi=tetikte2026 ile girilince cihaz tanınır.
   AÇILIŞ GÜNÜ bu bloğun tamamı silinecek (rebrand gecesi kontrol listesinde). */
try {
  var q = new URLSearchParams(location.search);
  if (q.get('kapi') === 'tetikte2026') { localStorage.setItem('mrOnizleme','1'); }
  if (localStorage.getItem('mrOnizleme') !== '1') {
    var perde = function(){
      if (document.getElementById('mrPerde')) return;
      var d = document.createElement('div');
      d.id = 'mrPerde';
      d.style.cssText = 'position:fixed;inset:0;z-index:99999;background:#06090f;color:#eef2f7;display:flex;align-items:center;justify-content:center;text-align:center;padding:24px;font-family:-apple-system,"Segoe UI",system-ui,Roboto,Arial,sans-serif';
      /* 30.07: perde ziyaretcinin gordugu ILK ekran ve eski markayla duruyordu
         (koseli T kutusu + yesil nokta + yesil buton). Rebrand kurali: nobet
         lambasi + kehribar; yesil yalniz durum rengidir, marka rengi degil. */
      d.innerHTML = '<div style="max-width:460px">'+
        '<div style="width:18px;height:18px;border-radius:50%;background:#f5a524;box-shadow:0 0 0 7px rgba(245,165,36,.16),0 0 26px rgba(245,165,36,.6);display:inline-block;margin-bottom:20px;animation:mrNbz 2.2s ease-in-out infinite"></div>'+
        '<h1 style="font-size:30px;letter-spacing:-1px;margin:0 0 10px">Tetikte</h1>'+
        '<style>@keyframes mrNbz{0%,100%{opacity:1}50%{opacity:.4}}</style>'+
        '<p style="color:#93a1b3;font-size:15px;line-height:1.65;margin:0 0 20px"><b style="color:#eef2f7">İşinin nöbetçisi çok yakında.</b><br>Mevzuatı senin yerine izleyen sistem son hazırlıklarını yapıyor. Açılışta ilk sen haber al — Kurucu Üye avantajı ilk gelenlerin.</p>'+
        '<form id="mrPerdeForm" style="display:flex;gap:8px;flex-wrap:wrap;justify-content:center">'+
        '<input type="email" required placeholder="e-posta adresin" style="flex:1;min-width:200px;background:#0d141e;border:1px solid rgba(255,255,255,.14);border-radius:11px;color:#eef2f7;font:inherit;font-size:14px;padding:12px 14px">'+
        '<button type="submit" style="background:linear-gradient(135deg,#f5a524,#ffc24b);color:#03101f;font-weight:800;font-size:14px;padding:12px 22px;border:none;border-radius:11px;cursor:pointer">Haber ver →</button>'+
        /* 30.07: pasif "katilinca kabul edersin" satiri acik riza DEGILDI -
           karne formundaki gibi zorunlu onay kutusuna cevrildi (KVKK).
           kvkk.html koku: perde alt sayfalarda da cikar, mutlak yol sart. */
        '<label style="display:flex;gap:8px;align-items:flex-start;width:100%;justify-content:center;font-size:11.5px;color:#93a1b3;margin-top:10px;text-align:left"><input type="checkbox" required style="margin-top:2px;accent-color:#f5a524;flex:none;width:16px;height:16px;padding:0">'+
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

var GRUPLAR=[
 {ad:"🛃 Gümrük & İthalat", araclar:[
  ["gtip.html","🔎","GTİP · Kaç Vergi Öderim?","İthalatta gümrük vergisi, KDV ve kesintiler"],
  ["risk-taramasi.html","🛃","Beyanname Risk Taraması","Beyandan önce ceza kapılarını tara"],
  ["senaryo-raporu.html","🌍","Nereden Alsam?","Ülke ülke toplam vergi yükü karşılaştırma"],
  ["hizmet.html","🌐","Yurt Dışı Hizmet Faturası","2 No.lu KDV + stopaj hesabı"],
  ["fiyatfarki.html","💱","Credit / Debit Note","Sonradan gelen fiyat farkının vergisi"]]},
 {ad:"🧾 Vergi, Ceza & Rehberler", araclar:[
  ["soru-cevap.html","💬","Net Cevap","Mevzuat sorunu sor, kaynaklı cevap al"],
  ["ceza-asistani.html","⚖️","Ceza Asistanı","İndirim mi, uzlaşma mı, dava mı?"],
  ["asgari-kv.html","🧾","Asgari Kurumlar Vergisi","%10 tabana takılıyor musun?"],
  ["kdv-iade-rehberi.html","💰","KDV İade Rehberi","İadeyi adım adım al"],
  ["kurulus.html","🏢","Şirket Kuruluşu Rehberi","Şahıs mı, limited mi, anonim mi?"],
  ["kurulus-evrak.html","🗂️","Kuruluş Evrak Çantası","Hangi belge, kim doldurur, nereye?"],
  ["karne.html","📋","Yükümlülük Karnesi","Firmana özel yükümlülük fotoğrafı, PDF'li"],
  ["sayfalar/index.html","✅","Eşik Rehberi","Hangi zorunluluklar seni kapsıyor?"],
  ["bilgi.html","📚","Bilgi Havuzu","Sade Türkçe özet + kaynak maddesi"],
  ["genc.html","🎓","Genç Müşavir","2026 sınav takvimi, geri sayımlı"],
  ["deneme.html","📝","Deneme Sınavı","Her şıkkın gerekçesi + kaynak kuralı"],
  ["tuzak.html","🎯","Günün Tuzağı","Her gün bir soru — cevabı ve kanun maddesi açık"],
  ["karsilastirma.html","⚖️","Hangisi sana lazım?","Kurs, kitap, ücretsiz banka ve biz — dürüst tablo"],
  ["donem-plani.html","🗺️","Dönem Planı","Kalan haftaları haritayla faz faz doldur"],
  ["songun.html","⏳","Son Gün 5 Saat","Dönem finali + sınav sabahı rehberi"]]},
 {ad:"📡 Takip Radarları", araclar:[
  ["radar.html","📰","Bugün Resmî Gazete'de","Günün önemli mevzuat değişiklikleri"],
  ["kartlar.html","💊","Günün Hap Kartları","30 saniyelik özet kartlar"],
  ["destekler.html","🎯","Destek Radarı","Profiline uyan KOSGEB ve destekler"],
  ["ihale-radari.html","📣","İhale Radarı","Yurt içi + Avrupa ihaleleri"],
  ["alacak-radari.html","🚨","Alacak Radarı","Müşterin konkordato/iflasta — ilk sen duy"],
  ["marka-radari.html","™️","Marka Radarı","Yenileme + benzer başvuru uyarısı"],
  ["marka-itiraz.html","🔍","Marka İtiraz & Benzerlik","İtiraz süren dolmadan gör"]]},
 {ad:"🧮 Muhasebe Bürosu (SMMM)", araclar:[
  ["fis-fabrikasi.html","🏭","Fiş Fabrikası","Banka ekstresi → programına hazır fiş"],
  ["evrak-radari.html","📁","Evrak Radarı","Mükelleften evrak kovalamayı bitir"],
  ["belge-kasasi.html","🗄️","Belge Kasası","Belgeler tek yerde, süreleri takipte"],
  ["hatirlatici.html","⏰","Süre Hatırlatıcı","DİİB · KDV · SGK kritik tarihleri"]]}
];

var css=''+
'#mrxFab{position:fixed;right:18px;bottom:18px;z-index:99990;appearance:none;border:1px solid rgba(255,255,255,.16);'+
 'background:linear-gradient(135deg,#f5a524,#ffc24b);color:#03101f;font-weight:800;font-size:14px;'+
 'font-family:-apple-system,"Segoe UI",system-ui,Roboto,Arial,sans-serif;padding:12px 18px;border-radius:999px;'+
 'cursor:pointer;box-shadow:0 8px 28px rgba(46,140,255,.45);letter-spacing:.2px}'+
'#mrxFab:hover{transform:translateY(-2px)}'+
'#mrxKaplama{position:fixed;inset:0;z-index:99991;background:rgba(3,6,12,.82);backdrop-filter:blur(6px);'+
 'display:none;overflow-y:auto;font-family:-apple-system,"Segoe UI",system-ui,Roboto,Arial,sans-serif}'+
'#mrxKaplama.acik{display:block}'+
'.mrxIc{max-width:1000px;margin:0 auto;padding:26px 18px 60px;color:#eef2f7}'+
'.mrxUst{display:flex;align-items:center;gap:12px;margin-bottom:18px;flex-wrap:wrap}'+
'.mrxLogo{width:34px;height:34px;border-radius:9px;background:linear-gradient(135deg,#f5a524,#ffc24b);'+
 'display:grid;place-items:center;color:#03101f;font-weight:800;font-size:14px}'+
'.mrxUst b{font-size:16px}'+
'.mrxUst a{color:#93a1b3;text-decoration:none;font-size:13.5px;font-weight:600;padding:8px 14px;'+
 'border:1px solid rgba(255,255,255,.14);border-radius:10px}'+
'.mrxUst a:hover{color:#fff}'+
'.mrxUst a.mrxUye{background:linear-gradient(135deg,#f5a524,#ffc24b);color:#03101f;border:0;font-weight:800}'+
'#mrxKapat{margin-left:auto;appearance:none;border:1px solid rgba(255,255,255,.16);background:transparent;'+
 'color:#eef2f7;font-size:18px;border-radius:10px;padding:6px 13px;cursor:pointer}'+
'#mrxAra{width:100%;padding:13px 16px;border:1px solid rgba(255,255,255,.16);border-radius:12px;'+
 'background:#0a0f17;color:#eef2f7;font-size:15px;font-family:inherit;margin-bottom:6px}'+
'#mrxAra:focus{outline:none;border-color:#f5a524;box-shadow:0 0 0 3px rgba(245,165,36,.18)}'+
'.mrxGrup{margin-top:24px}'+
'.mrxGrup>h3{font-size:12px;letter-spacing:1.5px;text-transform:uppercase;color:#5d6b7c;margin:0 0 12px;'+
 'font-weight:800;display:flex;align-items:center;gap:10px}'+
'.mrxGrup>h3:after{content:"";flex:1;height:1px;background:rgba(255,255,255,.09)}'+
'.mrxGrid{display:grid;grid-template-columns:repeat(3,1fr);gap:10px}'+
'@media(max-width:860px){.mrxGrid{grid-template-columns:repeat(2,1fr)}}'+
'@media(max-width:540px){.mrxGrid{grid-template-columns:1fr}}'+
'.mrxArac{display:flex;gap:11px;align-items:flex-start;padding:12px 14px;border:1px solid rgba(255,255,255,.09);'+
 'border-radius:13px;background:#0d141e;text-decoration:none;color:#eef2f7;transition:border-color .15s}'+
'.mrxArac:hover{border-color:rgba(245,165,36,.45)}'+
'.mrxArac .em{font-size:20px;line-height:1;margin-top:2px}'+
'.mrxArac b{display:block;font-size:13.5px;letter-spacing:-.2px}'+
'.mrxArac span{display:block;font-size:12px;color:#93a1b3;margin-top:2px;line-height:1.4}'+
'#mrxYok{display:none;text-align:center;color:#5d6b7c;padding:26px 0;font-size:14px}'+
/* 30.07 Cem: arac sayfalarinin tepesindeki duz "Tetikte" yazisi logoyu
   temsil etmiyordu. Ana sayfadaki marka yazisinin aynisi (kucuk harf,
   noktasiz i + ustunde kehribar lamba noktasi) buradan her sayfaya girer. */
'.mrxMarka{font-weight:800 !important;font-size:18px !important;letter-spacing:-.6px;'+
 'color:#eef2f7 !important;text-decoration:none !important;line-height:1}'+
'.mrxMarka .mi{position:relative}'+
'.mrxMarka .mi:after{content:"";position:absolute;left:50%;top:-3px;transform:translateX(-50%);'+
 'width:5px;height:5px;border-radius:50%;background:#f5a524;box-shadow:0 0 8px rgba(245,165,36,.8)}'+
'@media print{#mrxFab,#mrxKaplama{display:none!important}}';

function trU(s){return s.replace(/i/g,'İ').replace(/ı/g,'I').toLocaleUpperCase('tr-TR');}

function kur(){
  var st=document.createElement('style'); st.textContent=css; document.head.appendChild(st);

  var fab=document.createElement('button');
  fab.id='mrxFab'; fab.type='button'; fab.textContent='☰ Araçlar';
  document.body.appendChild(fab);

  var kap=document.createElement('div'); kap.id='mrxKaplama';
  var h='<div class="mrxIc"><div class="mrxUst">'+
    '<span class="mrxLogo">T</span><b>Tetikte</b>'+
    '<a href="index.html">Ana Sayfa</a><a class="mrxUye" href="radar-app.html">Giriş / Üye Ol</a>'+
    '<button id="mrxKapat" type="button" aria-label="Kapat">✕</button></div>'+
    '<input id="mrxAra" type="search" placeholder="🔍  Araç ara: ceza, KDV, marka, ihale, fiş…" autocomplete="off">';
  GRUPLAR.forEach(function(g){
    h+='<div class="mrxGrup"><h3>'+g.ad+'</h3><div class="mrxGrid">';
    g.araclar.forEach(function(a){
      h+='<a class="mrxArac" href="'+a[0]+'"><span class="em">'+a[1]+'</span><div><b>'+a[2]+'</b><span>'+a[3]+'</span></div></a>';
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
      yf.style.cssText = 'max-width:980px;margin:34px auto 0;padding:14px 18px 26px;border-top:1px solid rgba(255,255,255,.08);font-size:12px;color:#5d6b7c;font-family:inherit;line-height:1.8';
      yf.innerHTML = '<a href="kvkk.html" style="color:#93a1b3;text-decoration:none">KVKK Aydınlatma</a> · ' +
        '<a href="uyelik-sozlesmesi.html" style="color:#93a1b3;text-decoration:none">Üyelik Koşulları</a> · ' +
        '<a href="mesafeli-satis.html" style="color:#93a1b3;text-decoration:none">Mesafeli Satış</a> · ' +
        '<a href="teslimat-iade.html" style="color:#93a1b3;text-decoration:none">Teslimat & İade</a> · ' +
        '<a href="iletisim.html" style="color:#93a1b3;text-decoration:none">İletişim</a>' +
        '<br>Dizdar Denetim ve Yazılım A.Ş. · İzmir · info@dizdardenetim.com';
      document.body.appendChild(yf);
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
    d.innerHTML = '<div style="max-width:430px;background:#0d141e;border:1px solid rgba(255,194,75,.4);border-radius:16px;padding:26px;text-align:center;font-family:inherit">' +
      '<div style="font-size:19px;font-weight:800;color:#eef2f7;margin-bottom:8px">Bu ayın 5 bedava sorgusunu kullandın</div>' +
      '<div style="font-size:13.5px;color:#93a1b3;line-height:1.6;margin-bottom:16px">Ücretsiz üyelikte tüm araçlar sınırsız — üstelik panelde firmanı tanıt, robot seni ilgilendiren değişiklikte haber versin.</div>' +
      '<a href="radar-app.html" style="display:inline-block;background:linear-gradient(135deg,#f5a524,#ffc24b);color:#03101f;font-weight:800;font-size:15px;padding:12px 22px;border-radius:12px;text-decoration:none">Ücretsiz üye ol →</a>' +
      '<div style="margin-top:12px"><a href="#" onclick="document.getElementById(\'ttDuvar\').remove();return false" style="color:#5d6b7c;font-size:12.5px">kapat</a></div></div>';
    document.body.appendChild(d);
  } catch (e) {}
  return false;
}
function ttSorguHakki(anahtar){
  try {
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
