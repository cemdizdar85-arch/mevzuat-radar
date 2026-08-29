/* ============================================================================
   MARKA ŞERİDİ (21.08.2026) - Cem: "bunları sitede bulamıyorum, marka radarının
   içinde niye göremiyorum". Yeni marka sayfaları yalnizca acilir menuye ve
   katalogda gizli duruyordu; marka sayfalarinin BIRBIRINE gecisi yoktu.
   Bu betik her marka sayfasinin en ustune gorunur bir arac seridi basar ve
   bulundugun sayfayi vurgular. Tek yerden bakim: yeni marka araci eklenince
   sadece asagidaki diziye satir eklenir.
   Kullanim: sayfanin sonuna  <script src="marka-serit.js"></script>
   29.08 EK (Cem: "marka ile ilgili cok sey yapmistik ama panelde goremiyorum"):
   Radar Paneli'nin GIRIS ekraninda hicbir marka baglantisi yoktu - marka islerinin
   tamami app() icinde, yani girisin arkasindaydi. Betik artik data-elle="1" ile
   cagrilirsa kendiliginden yerlestirmez, window.markaSeritCiz(hedef, baslik) ile
   istenen yere cizilir. Arac listesi TEK yerde kalir (asagidaki ARACLAR dizisi).
============================================================================ */
(function(){
  var ARACLAR = [
    ["marka-portfoy.html", "🔎", "Portföyüm",      "Unvandan bütün markaların"],
    ["marka-radari.html",  "™️", "Yenileme",        "Markan ne zaman düşüyor"],
    ["marka-izleme.html",  "📡", "Benzer başvuru", "Markana benzeyen düştü mü"],
    ["marka-itiraz.html",  "🔍", "İtiraz",          "İtiraz eder misin, süren ne"],
    ["marka-varlik.html",  "💼", "Lisans / devir",  "Satış, rehin, muvafakat, Madrid"]
  ];
  var burasi = (location.pathname.split("/").pop() || "index.html").toLowerCase();

  // ==========================================================================
  // 29.08 IKINCI TUR (Cem: "goruntu olmamis, ben bile zor buldum, cok kucuk
  // asagida kalmis; diger siteler nasil yapiyor bakalim"). Iki referans
  // olculdu -- Ahrefs "Free SEO Tools" ve Semrush "Free Tools":
  //   1) Aile listesi kahramanin HEMEN ALTINDA duruyor, sayfa dibinde degil.
  //   2) Kart BUYUK: ikon kendi kutusunda, ad 16-20px kalin, aciklama kucuk.
  //   3) Kartin tiklanabilir oldugu okla/vurguyla belli ediliyor.
  // Bizimki 13,5px ad + 11px aciklama + 8px bosluktu; goz onu "kart" diye
  // okumuyordu. Olculer buyutuldu, ikon kendi kutusuna alindi, ok eklendi.
  //
  // 29.08 BIRINCI KUSUR (ayni turda): cerceve rgba(255,255,255,.10) yazilmisti
  // - bu betik site KOYU temadayken (21.08) yazildi. Acik temada (kagit zemin
  // #fbfaf8) beyaz cerceve beyaz zeminde KAYBOLMUSTU. Artik tema degiskeni.
  // DERS: sabit renk yazan her satir, tema degisince sessizce kaybolur.
  // ==========================================================================
  var st = document.createElement("style");
  st.textContent = ''
    + '.mserit{display:grid;grid-template-columns:repeat(auto-fit,minmax(212px,1fr));gap:12px;margin:0 0 6px}'
    + '.mserit a{position:relative;display:block;text-decoration:none;border:1px solid var(--line);background:var(--panel);'
    + 'border-radius:14px;padding:15px 40px 15px 15px;transition:border-color .15s,box-shadow .15s,transform .15s}'
    + '.mserit a:hover{border-color:var(--accent);box-shadow:0 6px 20px rgba(245,165,36,.16);transform:translateY(-2px)}'
    + '.mserit a:focus-visible{outline:2px solid var(--accent);outline-offset:2px}'
    + '.mserit a.aktif{border-color:var(--accent);background:rgba(245,165,36,.07)}'
    + '.mserit a::after{content:"\\2192";position:absolute;right:15px;top:14px;font-size:16px;font-weight:700;color:var(--dim);transition:color .15s,transform .15s}'
    + '.mserit a:hover::after{color:var(--accent2);transform:translateX(3px)}'
    + '.mserit a.aktif::after{content:"buradasın";font-size:10px;font-weight:800;letter-spacing:.6px;text-transform:uppercase;color:var(--accent2);top:17px}'
    + '.mserit em{display:grid;place-items:center;width:38px;height:38px;border-radius:11px;'
    + 'background:rgba(245,165,36,.13);font-size:19px;font-style:normal;margin:0 0 11px;line-height:1}'
    + '.mserit b{display:block;font-size:15.5px;color:var(--ink);font-weight:800;letter-spacing:-.3px;line-height:1.25}'
    + '.mserit span{display:block;font-size:12.5px;color:var(--muted);margin-top:4px;line-height:1.4}'
    + '.mseritBas{font-size:12.5px;color:var(--dim);letter-spacing:1.1px;text-transform:uppercase;font-weight:800;margin:0 0 11px}'
    + '@media (prefers-reduced-motion:reduce){.mserit a,.mserit a::after{transition:none}.mserit a:hover{transform:none}}';
  document.head.appendChild(st);

  function kur(baslik){
    var kap = document.createElement("div");
    var h = '<div class="mseritBas">' + (baslik || "Marka araçları") + '</div><div class="mserit">';
    for (var i = 0; i < ARACLAR.length; i++) {
      var a = ARACLAR[i];
      h += '<a href="' + a[0] + '"><b><em>' + a[1] + '</em>' + a[2] + '</b><span>' + a[3] + '</span></a>';
    }
    h += '</div>';
    kap.innerHTML = h;
    kap.className = "mseritKap";
    var linkler = kap.querySelectorAll("a");
    for (var j = 0; j < linkler.length; j++) {
      if (linkler[j].getAttribute("href").toLowerCase() === burasi) linkler[j].classList.add("aktif");
    }
    return kap;
  }

  // Disari acilan uc: istenen kaba istenen baslikla ciz (radar-app giris ekrani).
  window.MARKA_ARACLARI = ARACLAR;
  window.markaSeritCiz = function(hedef, baslik){
    if (!hedef) return null;
    var k = kur(baslik);
    hedef.innerHTML = '';
    hedef.appendChild(k);
    return k;
  };

  // data-elle="1" ile cagrildiysa kendiliginden yerlestirme yapma.
  var kendi = document.currentScript;
  if (kendi && kendi.getAttribute("data-elle") === "1") return;

  function yerlestir(){
    var kok = document.querySelector(".wrap") || document.body;
    var h1 = kok.querySelector("h1");
    var kap = kur("Marka araçları");
    if (h1 && h1.parentNode) { h1.parentNode.insertBefore(kap, h1); }
    else { kok.insertBefore(kap, kok.firstChild); }
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", yerlestir);
  else yerlestir();
})();
