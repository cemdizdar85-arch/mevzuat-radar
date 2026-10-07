/* ============================================================================
   TEMA DÜĞMESİ — sınav ekranları (09.09.2026, Cem "sınavda ikisi de olsun, adam
   değiştirebilsin; ilk ekran beyaz" → GM kararı: varsayılan beyaz, koyu yalnız
   adayın tıklamasıyla, cihazda hatırlanır; işletim sistemi izlenmez).

   NASIL ÇALIŞIR
   Site açık temayı stil-acik.css ile alır (stil.css koyu tabanın ÜSTÜNE, sayfa
   sonunda bağlı). Koyu = o bağı kapatmak (link.disabled), açık = geri açmak.
   Anahtar kc_tema, Kaydır-Çöz sayfalarıyla ORTAK: aday bir yerde koyuya geçerse
   deneme, canlı deneme, günün tuzağı ve Nöbetçi aynı temada gelir.
   Düğme sol altta (menü düğmesi sağ altta). Yalnız tema jetonu; sabit renk yok.
   Bağlanan sayfalar: deneme.html · canli-deneme.html · tuzak.html (stil-acik
   bağından SONRA, gövde sonunda). Ana sayfada düğme YOK (bilinçli).
   ========================================================================== */
(function(){
  var KEY='kc_tema', d=document.documentElement;
  /* 07.10: stil-acik.css head'de de bağlı (titreme taraması) -> tek bağ değil hepsi */
  function uygula(koyu){
    [].forEach.call(document.querySelectorAll('link[href$="stil-acik.css"]'), function(l){ l.disabled=!!koyu; });
    if(koyu) d.setAttribute('data-theme','dark'); else d.removeAttribute('data-theme');
    var b=document.getElementById('temaB');
    if(b){ b.textContent=koyu?'☀':'☾'; var et=koyu?'Açık temaya geç':'Koyu temaya geç'; b.setAttribute('aria-label',et); b.title=et; }
  }
  /* 07.10 (Cem "bir yerde başka şey görünüyor sonra kayboluyor"): ölçüldü - deneme.html'de ilk gelen ziyaretçiye ~1,1. sn'de
     ~140 ms KOYU ekran. Sebep bu satırdaki eski "varsayılan koyu" (24.09) kararıydı: kc_tema yoksa stil-acik bağını kapatıyor,
     sonra tema-bas.js/menu.js açığa geri çeviriyordu. Varsayılan 04.10'dan beri AÇIK (tema-bas.js). tema-bas.js yüklü sayfada
     tema onun işidir; burada hiç dokunulmaz. Yüklü değilse varsayılan açık. */
  if(window.TetikteTema) return;
  var t=null; try{ t=localStorage.getItem(KEY); }catch(e){}
  uygula(t==='dark');
  function kur(){
    /* 23.09: tema-bas.js yüklü sayfada düğme menu.js'te, üst şeritte (tek düğme, tek anahtar) - burada kurulmaz */
    if(window.TetikteTema) return;
    if(document.getElementById('temaB')) return;
    var s=document.createElement('style');
    s.textContent='.temaB{position:fixed;left:10px;bottom:10px;z-index:45;width:34px;height:34px;border-radius:999px;border:1px solid var(--line2);background:var(--kagit);color:var(--ink);font:inherit;font-size:15px;line-height:1;cursor:pointer;box-shadow:0 4px 14px rgba(0,0,0,.18)}.temaB:focus-visible{outline:3px solid var(--accent);outline-offset:2px}';
    document.head.appendChild(s);
    var b=document.createElement('button'); b.id='temaB'; b.type='button'; b.className='temaB';
    document.body.appendChild(b);
    b.addEventListener('click',function(){
      var koyu=d.getAttribute('data-theme')!=='dark';
      uygula(koyu); try{ localStorage.setItem(KEY,koyu?'dark':'light'); }catch(e){}
    });
    uygula(d.getAttribute('data-theme')==='dark');
  }
  if(document.body) kur(); else document.addEventListener('DOMContentLoaded',kur);
})();
