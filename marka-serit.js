/* ============================================================================
   MARKA ŞERİDİ (21.08.2026) - Cem: "bunları sitede bulamıyorum, marka radarının
   içinde niye göremiyorum". Yeni marka sayfaları yalnizca acilir menuye ve
   katalogda gizli duruyordu; marka sayfalarinin BIRBIRINE gecisi yoktu.
   Bu betik her marka sayfasinin en ustune gorunur bir arac seridi basar ve
   bulundugun sayfayi vurgular. Tek yerden bakim: yeni marka araci eklenince
   sadece asagidaki diziye satir eklenir.
   Kullanim: sayfanin sonuna  <script src="marka-serit.js"></script>
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

  var st = document.createElement("style");
  st.textContent = ''
    + '.mserit{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:8px;margin:0 0 20px}'
    + '.mserit a{display:block;text-decoration:none;border:1px solid rgba(255,255,255,.10);background:rgba(255,255,255,.02);'
    + 'border-radius:11px;padding:10px 12px;transition:border-color .15s,background .15s}'
    + '.mserit a:hover{border-color:rgba(245,165,36,.45);background:rgba(245,165,36,.06)}'
    + '.mserit a.aktif{border-color:rgba(245,165,36,.75);background:rgba(245,165,36,.10)}'
    + '.mserit b{display:block;font-size:13.5px;color:#eef2f7;font-weight:800;letter-spacing:-.2px}'
    + '.mserit span{display:block;font-size:11px;color:#8b98a9;margin-top:2px;line-height:1.35}'
    + '.mserit em{font-style:normal;margin-right:5px}'
    + '.mseritBas{font-size:11.5px;color:#5d6b7c;letter-spacing:1.1px;text-transform:uppercase;font-weight:800;margin:0 0 8px}';
  document.head.appendChild(st);

  var kap = document.createElement("div");
  var h = '<div class="mseritBas">Marka araçları</div><div class="mserit">';
  for (var i = 0; i < ARACLAR.length; i++) {
    var a = ARACLAR[i], aktif = (a[0].toLowerCase() === burasi) ? " aktif" : "";
    h += '<a class="mserit-a' + aktif + '" href="' + a[0] + '"><b><em>' + a[1] + '</em>' + a[2] + '</b><span>' + a[3] + '</span></a>';
  }
  h += '</div>';
  kap.innerHTML = h;
  kap.className = "mseritKap";
  // aktif sinifini dogru ogeye tasi (yukarida class adi birlesikti)
  var linkler = kap.querySelectorAll("a");
  for (var j = 0; j < linkler.length; j++) {
    if (linkler[j].getAttribute("href").toLowerCase() === burasi) linkler[j].classList.add("aktif");
  }

  function yerlestir(){
    var kok = document.querySelector(".wrap") || document.body;
    var h1 = kok.querySelector("h1");
    if (h1 && h1.parentNode) { h1.parentNode.insertBefore(kap, h1); }
    else { kok.insertBefore(kap, kok.firstChild); }
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", yerlestir);
  else yerlestir();
})();
