/* ŞİFREYİ GÖSTER (08.10.2026, Cem: "şifre girerken şifreyi göster de koysak iyi olur").
   Sayfadaki her input[type=password] alanının sağına "Göster / Gizle" düğmesi koyar. Sonradan eklenen alanları da
   yakalar (MutationObserver). Düğme type=button (formu göndermez), aria-pressed ile durumunu söyler; tıklayınca imleç
   alanda kalır. Form gönderilince alan yeniden gizlenir (tarayıcı şifreyi düz metin olarak hatırlamasın diye).
   Renkler tema jetonlarından (sabit renk yok). Alanın flex/genişlik davranışı sarmalayıcıya taşınır. */
(function () {
  'use strict';
  if (window.__sifreGoster) return; window.__sifreGoster = true;
  var stil = document.createElement('style');
  stil.textContent = '.sg-sar{position:relative;display:block;min-width:0}'
    + '.sg-sar>input{width:100%;box-sizing:border-box;padding-right:76px!important}'
    + '.sg-dugme{position:absolute;top:50%;right:6px;transform:translateY(-50%);appearance:none;border:0;background:none;'
    + 'font:inherit;font-size:13px;font-weight:700;color:var(--link,var(--ink));cursor:pointer;padding:6px 8px;border-radius:7px;min-height:32px}'
    + '.sg-dugme:hover{background:color-mix(in srgb,var(--ink) 8%,transparent)}'
    + '.sg-dugme:focus-visible{outline:2px solid var(--amber);outline-offset:1px}';
  (document.head || document.documentElement).appendChild(stil);

  function kur(inp) {
    if (!inp || inp.__sg || inp.type !== 'password') return;
    inp.__sg = true;
    var cs = getComputedStyle(inp), sar = document.createElement('span');
    sar.className = 'sg-sar';
    /* satır içi (flex) alanda alanın payını sarmalayıcı alır: deneme.html giriş satırı */
    if (cs.flexGrow !== '0' || cs.flexBasis !== 'auto') { sar.style.flex = cs.flexGrow + ' ' + cs.flexShrink + ' ' + cs.flexBasis; }
    if (inp.style.minWidth) { sar.style.minWidth = inp.style.minWidth; }
    inp.parentNode.insertBefore(sar, inp); sar.appendChild(inp);
    var b = document.createElement('button');
    b.type = 'button'; b.className = 'sg-dugme'; b.textContent = 'Göster';
    b.setAttribute('aria-pressed', 'false'); b.setAttribute('aria-label', 'Şifreyi göster');
    b.addEventListener('mousedown', function (e) { e.preventDefault(); });   /* odak alanda kalsın */
    b.addEventListener('click', function () {
      var ac = inp.type === 'password';
      inp.type = ac ? 'text' : 'password';
      b.textContent = ac ? 'Gizle' : 'Göster';
      b.setAttribute('aria-pressed', ac ? 'true' : 'false');
      b.setAttribute('aria-label', ac ? 'Şifreyi gizle' : 'Şifreyi göster');
    });
    sar.appendChild(b);
    if (inp.form) inp.form.addEventListener('submit', function () {
      if (inp.type === 'text') { inp.type = 'password'; b.textContent = 'Göster'; b.setAttribute('aria-pressed', 'false'); b.setAttribute('aria-label', 'Şifreyi göster'); }
    }, true);
  }
  function tara(kok) { (kok.querySelectorAll ? kok : document).querySelectorAll('input[type=password]').forEach(kur); }
  function basla() {
    tara(document);
    try {
      new MutationObserver(function (l) {
        l.forEach(function (m) { m.addedNodes.forEach(function (n) { if (n.nodeType !== 1) return; if (n.matches && n.matches('input[type=password]')) kur(n); else tara(n); }); });
      }).observe(document.body, { childList: true, subtree: true });
    } catch (e) {}
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', basla); else basla();
})();
