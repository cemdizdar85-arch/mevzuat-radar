/* Mevzuat Radarı — ortak araç menüsü.
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
      d.innerHTML = '<div style="max-width:460px">'+
        '<div style="width:64px;height:64px;border-radius:18px;background:linear-gradient(135deg,#2f7bff,#26d0fe);display:inline-grid;place-items:center;color:#03101f;font-weight:800;font-size:26px;margin-bottom:18px">T</div>'+
        '<h1 style="font-size:30px;letter-spacing:-1px;margin:0 0 10px">Tetikte <span style="display:inline-block;width:10px;height:10px;border-radius:50%;background:#3ddc97;animation:mrNbz 1.6s ease-out infinite"></span></h1>'+
        '<style>@keyframes mrNbz{0%,100%{opacity:1}50%{opacity:.4}}</style>'+
        '<p style="color:#93a1b3;font-size:15px;line-height:1.65;margin:0 0 20px"><b style="color:#eef2f7">İşinin nöbetçisi çok yakında.</b><br>Mevzuatı senin yerine izleyen sistem son hazırlıklarını yapıyor. Açılışta ilk sen haber al — Kurucu Üye avantajı ilk gelenlerin.</p>'+
        '<form id="mrPerdeForm" style="display:flex;gap:8px;flex-wrap:wrap;justify-content:center">'+
        '<input type="email" required placeholder="e-posta adresin" style="flex:1;min-width:200px;background:#0d141e;border:1px solid rgba(255,255,255,.14);border-radius:11px;color:#eef2f7;font:inherit;font-size:14px;padding:12px 14px">'+
        '<button type="submit" style="background:linear-gradient(135deg,#3ddc97,#26d0fe);color:#03140d;font-weight:800;font-size:14px;padding:12px 22px;border:none;border-radius:11px;cursor:pointer">Haber ver →</button></form>'+
        '<div id="mrPerdeOk" style="display:none;color:#3ddc97;font-weight:700;font-size:14px;margin-top:12px">✓ Kaydın alındı — açılışta ilk sen duyacaksın.</div>'+
        '<div style="font-size:11px;color:#5d6b7c;margin-top:16px">Katılınca bilgilendirme e-postası almayı kabul edersin.</div></div>';
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
  ["sayfalar/index.html","✅","Eşik Rehberi","Hangi zorunluluklar seni kapsıyor?"],
  ["bilgi.html","📚","Bilgi Havuzu","Sade Türkçe özet + kaynak maddesi"],
  ["genc.html","🎓","Genç Müşavir","2026 sınav takvimi, geri sayımlı"],
  ["deneme.html","📝","Deneme Sınavı","Her şıkkın gerekçesi + kaynak kuralı"],
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
 'background:linear-gradient(135deg,#2f7bff,#26d0fe);color:#03101f;font-weight:800;font-size:14px;'+
 'font-family:-apple-system,"Segoe UI",system-ui,Roboto,Arial,sans-serif;padding:12px 18px;border-radius:999px;'+
 'cursor:pointer;box-shadow:0 8px 28px rgba(46,140,255,.45);letter-spacing:.2px}'+
'#mrxFab:hover{transform:translateY(-2px)}'+
'#mrxKaplama{position:fixed;inset:0;z-index:99991;background:rgba(3,6,12,.82);backdrop-filter:blur(6px);'+
 'display:none;overflow-y:auto;font-family:-apple-system,"Segoe UI",system-ui,Roboto,Arial,sans-serif}'+
'#mrxKaplama.acik{display:block}'+
'.mrxIc{max-width:1000px;margin:0 auto;padding:26px 18px 60px;color:#eef2f7}'+
'.mrxUst{display:flex;align-items:center;gap:12px;margin-bottom:18px;flex-wrap:wrap}'+
'.mrxLogo{width:34px;height:34px;border-radius:9px;background:linear-gradient(135deg,#2f7bff,#26d0fe);'+
 'display:grid;place-items:center;color:#03101f;font-weight:800;font-size:14px}'+
'.mrxUst b{font-size:16px}'+
'.mrxUst a{color:#93a1b3;text-decoration:none;font-size:13.5px;font-weight:600;padding:8px 14px;'+
 'border:1px solid rgba(255,255,255,.14);border-radius:10px}'+
'.mrxUst a:hover{color:#fff}'+
'.mrxUst a.mrxUye{background:linear-gradient(135deg,#2f7bff,#26d0fe);color:#03101f;border:0;font-weight:800}'+
'#mrxKapat{margin-left:auto;appearance:none;border:1px solid rgba(255,255,255,.16);background:transparent;'+
 'color:#eef2f7;font-size:18px;border-radius:10px;padding:6px 13px;cursor:pointer}'+
'#mrxAra{width:100%;padding:13px 16px;border:1px solid rgba(255,255,255,.16);border-radius:12px;'+
 'background:#0a0f17;color:#eef2f7;font-size:15px;font-family:inherit;margin-bottom:6px}'+
'#mrxAra:focus{outline:none;border-color:#3e9bff;box-shadow:0 0 0 3px rgba(62,155,255,.18)}'+
'.mrxGrup{margin-top:24px}'+
'.mrxGrup>h3{font-size:12px;letter-spacing:1.5px;text-transform:uppercase;color:#5d6b7c;margin:0 0 12px;'+
 'font-weight:800;display:flex;align-items:center;gap:10px}'+
'.mrxGrup>h3:after{content:"";flex:1;height:1px;background:rgba(255,255,255,.09)}'+
'.mrxGrid{display:grid;grid-template-columns:repeat(3,1fr);gap:10px}'+
'@media(max-width:860px){.mrxGrid{grid-template-columns:repeat(2,1fr)}}'+
'@media(max-width:540px){.mrxGrid{grid-template-columns:1fr}}'+
'.mrxArac{display:flex;gap:11px;align-items:flex-start;padding:12px 14px;border:1px solid rgba(255,255,255,.09);'+
 'border-radius:13px;background:#0d141e;text-decoration:none;color:#eef2f7;transition:border-color .15s}'+
'.mrxArac:hover{border-color:rgba(62,155,255,.45)}'+
'.mrxArac .em{font-size:20px;line-height:1;margin-top:2px}'+
'.mrxArac b{display:block;font-size:13.5px;letter-spacing:-.2px}'+
'.mrxArac span{display:block;font-size:12px;color:#93a1b3;margin-top:2px;line-height:1.4}'+
'#mrxYok{display:none;text-align:center;color:#5d6b7c;padding:26px 0;font-size:14px}'+
'@media print{#mrxFab,#mrxKaplama{display:none!important}}';

function trU(s){return s.replace(/i/g,'İ').replace(/ı/g,'I').toLocaleUpperCase('tr-TR');}

function kur(){
  var st=document.createElement('style'); st.textContent=css; document.head.appendChild(st);

  var fab=document.createElement('button');
  fab.id='mrxFab'; fab.type='button'; fab.textContent='☰ Araçlar';
  document.body.appendChild(fab);

  var kap=document.createElement('div'); kap.id='mrxKaplama';
  var h='<div class="mrxIc"><div class="mrxUst">'+
    '<span class="mrxLogo">MR</span><b>Mevzuat Radarı</b>'+
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
}
if(document.readyState==='loading') document.addEventListener('DOMContentLoaded',kur); else kur();
})();
