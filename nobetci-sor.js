/* nobetci-sor.js — "💬 Nöbetçiye sor" + "Ekibe sor" (04.10.2026, Cem: "nöbetçi sor diye düğme olacak, bu önemli";
   "GM önerilerini yap": yapay zekâ olduğu AÇIK yazılır, yetmezse insan cevabı 24 saat içinde e-postayla)
   paket-kapisi.js bu dosyayı bütün soru (kaydir) sayfalarına yükler. Kartta "🖍 İşaretle · 📝 Notum" satırına düğme ekler.
   Sunucu: radar-app/edge/nobetci-sor.ts (paket kapısı, günde 10 soru, aylık tavan sunucuda). Burada para harcayan hiçbir
   karar yok; sınır ve yetki sunucuda. Soru kimliği kartın not kutusundaki data-id'den (motor/kaydir-coz.ps1). */
(function () {
  if (window.__nobetciSor) return; window.__nobetciSor = true;
  var UC = 'https://bjrleanjpyujtajmazxn.supabase.co/functions/v1/nobetci-sor';
  var ANON = 'sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg';
  var st = document.createElement('style');
  st.textContent =
    '.nbPanel{margin:0 0 12px;border:1px solid var(--cizgi);border-radius:12px;padding:10px 12px;background:var(--kart)}' +
    '.nbPanel[hidden]{display:none}' +
    '.nbNot{font-size:.74em;color:var(--dim);margin:0 0 6px}' +
    '.nbPanel textarea{width:100%;box-sizing:border-box;font:inherit;font-size:.9em;border:1px solid var(--cizgi);border-radius:9px;padding:8px 10px;background:var(--kart);color:var(--yazi);resize:vertical}' +
    '.nbSatir{display:flex;gap:8px;align-items:center;flex-wrap:wrap;margin-top:6px}' +
    '.nbBtn{all:unset;box-sizing:border-box;cursor:pointer;font-weight:700;font-size:.82em;border-radius:9px;padding:7px 12px;border:1px solid var(--cizgi);min-height:34px;display:inline-flex;align-items:center}' +
    '.nbBtn.ana{border-color:var(--altin);color:var(--yazi)}' +
    '.nbBtn[disabled]{opacity:.5;cursor:default}' +
    '.nbCevap{white-space:pre-wrap;font-size:.92em;line-height:1.55;margin-top:10px;padding-top:8px;border-top:1px dashed var(--cizgi)}' +
    '.nbDurum{font-size:.76em;color:var(--dim)}' +
    '.nbEkip{margin-top:10px;padding-top:8px;border-top:1px dashed var(--cizgi)}' +
    '.nbEkip[hidden]{display:none}';
  document.head.appendChild(st);

  function esc(s) { return String(s == null ? '' : s).replace(/[&<>"]/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]; }); }
  function oturum() {
    var sb = window.__pkSb;
    if (!sb || !sb.auth) return Promise.resolve(null);
    return sb.auth.getSession().then(function (r) { return (r && r.data && r.data.session) || null; }, function () { return null; });
  }

  function panelKur(arac) {
    var govde = arac.parentElement, alan = govde && govde.querySelector('.notumAlan');
    var soruId = alan && alan.getAttribute('data-id'); if (!soruId) return;
    var b = document.createElement('button'); b.type = 'button'; b.className = 'arac bNobetci'; b.textContent = '💬 Nöbetçiye sor';
    arac.appendChild(b);
    var p = document.createElement('div'); p.className = 'nbPanel'; p.hidden = true;
    p.innerHTML = '<p class="nbNot">Nöbetçi, Tetikte\'nin <b>yapay zekâ</b> anlatıcısıdır: yalnız bu soruyu, açıklaması ve dayanak maddesi üzerinden anlatır. Paket sahiplerine açık, günde 10 soru.</p>' +
      '<textarea class="nbMesaj" rows="2" maxlength="1000" placeholder="Neyi anlamadın? Örnek: Neden C değil de B?"></textarea>' +
      '<div class="nbSatir"><button type="button" class="nbBtn ana nbSor">Sor</button><span class="nbDurum"></span></div>' +
      '<div class="nbCevap" hidden></div>' +
      '<div class="nbSatir"><button type="button" class="nbBtn nbEkipAc">Yetmedi mi? Ekibe sor</button></div>' +
      '<div class="nbEkip" hidden><p class="nbNot">Sorun Tetikte ekibine gider; <b>24 saat içinde</b> cevap e-postana gelir.</p>' +
      '<textarea class="nbEkipMesaj" rows="3" maxlength="2000" placeholder="Takıldığın yeri yaz"></textarea>' +
      '<div class="nbSatir"><button type="button" class="nbBtn ana nbEkipGonder">Ekibe gönder</button><span class="nbEkipDurum nbDurum"></span></div></div>';
    var hedef = govde.querySelector('.notumKutu') || govde.querySelector('.soru');
    hedef.parentNode.insertBefore(p, hedef.nextSibling);
    var q = function (s) { return p.querySelector(s); };
    var sonCevap = '';

    b.addEventListener('click', function () { p.hidden = !p.hidden; b.classList.toggle('acik', !p.hidden); if (!p.hidden) q('.nbMesaj').focus(); });

    q('.nbSor').addEventListener('click', function () {
      var mesaj = q('.nbMesaj').value.trim();
      if (mesaj.length < 2) { q('.nbDurum').textContent = 'Önce sorunu yaz.'; return; }
      var kart = govde.closest('[class]') || govde;
      var cevapladi = !!(govde.parentElement && govde.parentElement.querySelector('.sik.dogru')) || !!govde.querySelector('.sik.dogru');
      var btn = q('.nbSor'); btn.disabled = true; q('.nbDurum').textContent = 'Nöbetçi düşünüyor…';
      oturum().then(function (o) {
        if (!o) { q('.nbDurum').innerHTML = 'Nöbetçi paket sahiplerine açık. <a href="/ogrenci.html">Giriş yap</a>'; btn.disabled = false; return; }
        return fetch(UC, { method: 'POST', headers: { 'Content-Type': 'application/json', apikey: ANON, Authorization: 'Bearer ' + o.access_token },
          body: JSON.stringify({ islem: 'sor', soru_id: soruId, mesaj: mesaj, cevapladi: cevapladi }) })
          .then(function (r) { return r.json().catch(function () { return {}; }).then(function (j) { return { ok: r.ok, j: j }; }); })
          .then(function (x) {
            btn.disabled = false;
            if (x.ok && x.j.success) {
              sonCevap = x.j.cevap || '';
              var c = q('.nbCevap'); c.hidden = false; c.textContent = sonCevap;
              q('.nbDurum').textContent = 'Bugün kalan: ' + (x.j.kalan != null ? x.j.kalan : '?') + ' soru';
            } else {
              q('.nbDurum').textContent = (x.j && x.j.mesaj) || 'Nöbetçi şu an cevap veremedi. "Ekibe sor"u kullanabilirsin.';
            }
          });
      }).catch(function () { btn.disabled = false; q('.nbDurum').textContent = 'Bağlantı sorunu. Biraz sonra yeniden dene.'; });
    });

    q('.nbEkipAc').addEventListener('click', function () {
      var e = q('.nbEkip'); e.hidden = !e.hidden;
      if (!e.hidden && !q('.nbEkipMesaj').value) q('.nbEkipMesaj').value = q('.nbMesaj').value;
    });
    q('.nbEkipGonder').addEventListener('click', function () {
      var mesaj = q('.nbEkipMesaj').value.trim(), d = q('.nbEkipDurum'), btn = q('.nbEkipGonder');
      if (mesaj.length < 3) { d.textContent = 'Takıldığın yeri yaz.'; return; }
      btn.disabled = true; d.textContent = 'Gönderiliyor…';
      oturum().then(function (o) {
        if (!o) { d.innerHTML = 'Ekibe sormak için <a href="/ogrenci.html">giriş yap</a>.'; btn.disabled = false; return; }
        var soruKisa = ((govde.querySelector('.soru') || {}).textContent || '').slice(0, 600);
        return window.__pkSb.from('ekibe_soru').insert({ soru_id: soruId, soru_kisa: soruKisa, mesaj: mesaj, nobetci_cevap: sonCevap ? sonCevap.slice(0, 4000) : null })
          .then(function (r) {
            if (r && r.error) { btn.disabled = false; d.textContent = /row-level|policy/i.test(r.error.message || '') ? 'Bugün yeterince soru gönderdin; yarın yeniden dene.' : 'Gönderilemedi, biraz sonra yeniden dene.'; return; }
            d.textContent = '✓ Ekibe iletildi. 24 saat içinde e-postana cevap gelir.'; q('.nbEkipMesaj').value = '';
            fetch(UC, { method: 'POST', headers: { 'Content-Type': 'application/json', apikey: ANON, Authorization: 'Bearer ' + o.access_token }, body: JSON.stringify({ islem: 'ekip_haber' }) }).catch(function () {});
          });
      }).catch(function () { btn.disabled = false; d.textContent = 'Bağlantı sorunu.'; });
    });
  }

  function tara() { [].forEach.call(document.querySelectorAll('.soruArac'), function (a) { if (!a.querySelector('.bNobetci')) { try { panelKur(a); } catch (e) {} } }); }
  tara();
  /* kartlar sonradan (kasadan) çizilir: değişiklikleri karede bir kez tara - soru sayfası çok sık değişiyor */
  var bekliyor = false;
  try { new MutationObserver(function () { if (bekliyor) return; bekliyor = true; requestAnimationFrame(function () { bekliyor = false; tara(); }); }).observe(document.body, { childList: true, subtree: true }); } catch (e) {}
})();
