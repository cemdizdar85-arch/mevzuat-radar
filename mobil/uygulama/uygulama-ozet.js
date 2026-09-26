/* uygulama-ozet.js — ANA EKRANIN ÇALIŞMA ÖZETİ (26.09.2026, Cem "eksiklerin hepsini yapalım", yalnız telefon)
 *
 * Rakiplerde olup uygulamada olmayanlar (UWorld, Pocket Prep, Duolingo, AMBOSS incelemesi):
 *   - İlk açılış akışı: sınavını seç → günlük hedef → hatırlatıcı (Duolingo/Pocket Prep).
 *   - "Bugün" kartı: günlük hedef çubuğu + 🔥 seri (hedefi tutan ardışık gün).
 *   - "Devam et": en son çalışılan ders, kaldığın soruda açılır (tek dokunuş).
 *   - "Günün sorusu": seçtiğin sınavın ücretsiz sorularından her gün bir tane (herkese açık, hesap gerekmez).
 *   - "Karnem": derse göre doğru oranı + en zayıf ders için "Şimdi çalış" düğmesi.
 * Veri: ilerleme.js (tt_ilerleme). Sayfalar: katalog.js (TT_KATALOG). Bölüm "Sınavlar" sekmesinin başında.
 * BU DOSYA ŞUNU YAPMAZ: sunucuya yazmaz (hesaba eşitleme B kümesi); sitede yüklenmez.
 */
(function () {
  var IL = window.TTIlerleme, K = window.TT_KATALOG || {};
  if (!IL) return;
  function $(id) { return document.getElementById(id); }
  function esc(t) { return String(t).replace(/[&<>"]/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]; }); }
  var tumSayfa = [].concat(K.paket || [], K.ucretsiz || []);
  function sayfaAdi(yol) { var s = tumSayfa.filter(function (x) { return x.yol === yol; })[0]; return s ? s.baslik : 'Son çalıştığın ders'; }
  function acikMi(yol) {  /* ücretsiz her zaman; paket sayfası ana ekranda listelenmişse (hesapta açık) */
    if ((K.ucretsiz || []).some(function (x) { return x.yol === yol; })) return true;
    return !!document.querySelector('#liste a[href="' + yol + '"]');
  }

  var st = document.createElement('style');
  st.textContent = [
    '#ozet .kart{margin-bottom:12px}',
    '#ozet .ust2{display:flex;justify-content:space-between;align-items:baseline;gap:10px;margin-bottom:8px}',
    '#ozet .ust2 b{font-size:15px}',
    '#ozet .seri{font-weight:800;color:var(--vurgu)}',
    '#ozet .cubuk{height:10px;border-radius:99px;background:var(--cizgi);overflow:hidden}',
    '#ozet .cubuk i{display:block;height:100%;background:linear-gradient(90deg,var(--vurgu),var(--vurgu2));border-radius:99px}',
    '#ozet .alt2{font-size:13px;color:var(--soluk);margin-top:6px}',
    '#ozet a.buyuk{display:flex;align-items:center;gap:12px;text-decoration:none;color:var(--yazi)}',
    '#ozet a.buyuk .ik{font-size:26px}',
    '#ozet a.buyuk .ad{flex:1;font-weight:750}',
    '#ozet a.buyuk .ad small{display:block;font-weight:500;color:var(--soluk);font-size:12.5px}',
    '#ozet a.buyuk .ok{font-size:20px;color:var(--vurgu)}',
    '#ozet .ders2{display:grid;grid-template-columns:1fr auto;gap:4px 10px;align-items:center;font-size:14px;margin:8px 0}',
    '#ozet .ders2 .cubuk{grid-column:1/3;height:6px}',
    '#ozet .zayif{margin-top:10px}',
    '#ozet .zayif a{display:block;text-align:center;padding:11px;border-radius:12px;background:var(--vurgu);color:var(--vurguYazi);font-weight:800;text-decoration:none}',
    '#kurulum{position:fixed;inset:0;z-index:100;background:var(--taban);color:var(--yazi);display:flex;flex-direction:column;justify-content:center;padding:24px 20px calc(24px + max(env(safe-area-inset-bottom),var(--safe-area-inset-bottom,0px)))}',
    '#kurulum h1{font-size:26px;margin:0 0 6px}',
    '#kurulum p{color:var(--soluk);margin:0 0 18px}',
    '#kurulum .sec{display:grid;gap:10px}',
    '#kurulum .sec button{text-align:left;padding:16px;border-radius:14px;border:1px solid var(--cizgi);background:var(--panel);color:var(--yazi);font-weight:750;font-size:16px}',
    '#kurulum .sec button small{display:block;font-weight:500;color:var(--soluk);font-size:13px;margin-top:2px}',
    '#kurulum .atla{margin-top:18px;background:none;border:0;color:var(--soluk);text-decoration:underline}',
    '#kurulum .adim{font-size:12px;font-weight:700;color:var(--vurgu);letter-spacing:.5px;margin-bottom:6px}'
  ].join('\n');
  document.head.appendChild(st);

  /* bölüm: Sınavlar sekmesinin en başı */
  var bolum = document.createElement('section');
  bolum.id = 'ozet'; bolum.className = 'bolum'; bolum.setAttribute('data-sekme', 'sinav');
  var main = document.querySelector('main');
  main.insertBefore(bolum, main.firstChild);

  /* ?tek=1: Kaydır-Çöz tek kart modu — yalnız o soru, kaydırma yok (26.09 Cem: "alt alta bir sürü soru çıkıyor") */
  function gununSorusu() {
    var sinav = IL.veri().ayar.sinav || 'yeterlilik';
    var s = (K.ucretsiz || []).filter(function (x) { return x.sinav === sinav; })[0] || (K.ucretsiz || [])[0];
    if (!s) return null;
    var d = new Date(), gun = Math.floor((d.getTime() - d.getTimezoneOffset() * 60000) / 86400000);
    return { yol: s.yol, sira: gun % 30, baslik: s.baslik };
  }

  function ciz() {
    IL.yenidenOku();
    var v = IL.veri(), h = v.ayar.hedef || 10, bugun = v.gun[IL.bugun()] || 0, seri = IL.seri();
    var html = '';
    html += '<div class="kart"><div class="ust2"><b>Bugün</b><span class="seri">🔥 ' + seri + ' gün</span></div>' +
      '<div class="cubuk"><i style="width:' + Math.min(100, Math.round(bugun / h * 100)) + '%"></i></div>' +
      '<div class="alt2">' + (bugun >= h ? '🎯 Günlük hedef tamam (' + bugun + ' soru). Seri devam ediyor.' :
        bugun + ' / ' + h + ' soru · hedefe ' + (h - bugun) + ' soru kaldı') + '</div></div>';
    if (v.son && v.son.yol && acikMi(v.son.yol)) {
      html += '<a class="kart buyuk" href="' + esc(v.son.yol) + '"><span class="ik">▶️</span><span class="ad">Devam et<small>' +
        esc(sayfaAdi(v.son.yol)) + ' · ' + ((v.son.i || 0) + 1) + '. soru</small></span><span class="ok">›</span></a>';
    }
    var gs = gununSorusu();
    if (gs) html += '<a class="kart buyuk" href="' + esc(gs.yol) + '?tek=1#s=' + gs.sira + '"><span class="ik">☀️</span><span class="ad">Günün sorusu<small>' +
      esc(gs.baslik) + ' · her gün yeni bir soru</small></span><span class="ok">›</span></a>';
    /* karnem: en az 1 cevaplı dersler */
    var dersler = tumSayfa.map(function (s) { var r = IL.dersSonucu(s.yol); r.yol = s.yol; r.ad = s.baslik; r.n = r.ok + r.yan; return r; })
      .filter(function (r) { return r.n > 0; });
    if (dersler.length) {
      html += '<div class="kart"><div class="ust2"><b>Karnem</b><span class="alt2" style="margin:0">doğru oranı</span></div>';
      dersler.sort(function (a, b) { return b.n - a.n; }).forEach(function (r) {
        var y = Math.round(r.ok / r.n * 100);
        html += '<div class="ders2"><span>' + esc(r.ad) + ' <small style="color:var(--soluk)">(' + r.n + ')</small></span><b>%' + y + '</b>' +
          '<div class="cubuk"><i style="width:' + y + '%"></i></div></div>';
      });
      /* "en zayıf" ancak en az iki ders (her biri 5+ cevap) kıyaslanabilince anlamlı */
      var kiyas = dersler.filter(function (r) { return r.n >= 5; });
      var aday = kiyas.filter(function (r) { return acikMi(r.yol); }).sort(function (a, b) { return a.ok / a.n - b.ok / b.n; })[0];
      if (aday && kiyas.length >= 2) html += '<div class="zayif"><a href="' + esc(aday.yol) + '">En zayıf dersin: ' + esc(aday.ad) + ' · Şimdi çalış</a></div>';
      html += '</div>';
    }
    bolum.innerHTML = html;
  }

  /* ilk açılış: sınav → günlük hedef → hatırlatıcı */
  function kurulum() {
    if (IL.veri().ayar.kurulum) return;
    var e = document.createElement('div'); e.id = 'kurulum'; document.body.appendChild(e);
    var bitir = function () { IL.ayarYaz({ kurulum: true }); e.remove(); ciz(); };
    var adim1 = function () {
      e.innerHTML = '<div class="adim">1 / 3</div><h1>Hangi sınava hazırlanıyorsun?</h1><p>Günün sorusu ve öneriler buna göre gelir. Sonra değiştirebilirsin.</p>' +
        '<div class="sec"><button data-v="yeterlilik">SMMM Yeterlilik<small>8 ders</small></button><button data-v="sgs">SGS (Staja Giriş)<small>Staja başlama sınavı</small></button></div>' +
        '<button type="button" class="atla">Şimdilik geç</button>';
      e.querySelector('.atla').onclick = bitir;
      [].forEach.call(e.querySelectorAll('.sec button'), function (b) { b.onclick = function () { IL.ayarYaz({ sinav: b.dataset.v }); adim2(); }; });
    };
    var adim2 = function () {
      e.innerHTML = '<div class="adim">2 / 3</div><h1>Günde kaç soru?</h1><p>Hedefini tuttuğun her gün serin büyür 🔥 Az ama her gün, çoktan ama arada bir çalışmaktan iyidir.</p>' +
        '<div class="sec"><button data-v="10">10 soru<small>Günde ~15 dakika</small></button><button data-v="20">20 soru<small>Günde ~30 dakika</small></button><button data-v="40">40 soru<small>Günde ~1 saat</small></button></div>';
      [].forEach.call(e.querySelectorAll('.sec button'), function (b) { b.onclick = function () { IL.ayarYaz({ hedef: +b.dataset.v }); adim3(); }; });
    };
    var adim3 = function () {
      var yerel = !!(window.Capacitor && window.Capacitor.isNativePlatform && window.Capacitor.isNativePlatform());
      if (!yerel || !$('hatAcik')) return bitir();
      e.innerHTML = '<div class="adim">3 / 3</div><h1>Her gün hatırlatayım mı?</h1><p>Akşam 20:00\'de kısa bir bildirim. Saati Hesap sekmesinden değiştirebilirsin.</p>' +
        '<div class="sec"><button data-v="evet">Evet, hatırlat</button><button data-v="hayir">Hayır, gerek yok</button></div>';
      [].forEach.call(e.querySelectorAll('.sec button'), function (b) {
        b.onclick = function () { if (b.dataset.v === 'evet' && !$('hatAcik').checked) $('hatAcik').click(); bitir(); };
      });
    };
    adim1();
  }

  /* Hesap sekmesi: çalışma ayarları (ilk açılışta "sonra değiştirebilirsin" denen yer) */
  var ayarB = document.createElement('section');
  ayarB.id = 'calismaAyar'; ayarB.className = 'bolum'; ayarB.setAttribute('data-sekme', 'hesap');
  ayarB.innerHTML = '<h2>Çalışma ayarları</h2><div class="kart">' +
    '<label>Sınavım<select id="ayarSinav" style="display:block;width:100%;margin-top:6px;padding:12px;font:inherit;color:var(--yazi);background:var(--taban);border:1px solid var(--cizgi);border-radius:11px">' +
    '<option value="yeterlilik">SMMM Yeterlilik</option><option value="sgs">SGS (Staja Giriş)</option></select></label>' +
    '<label>Günlük hedef<select id="ayarHedef" style="display:block;width:100%;margin-top:6px;padding:12px;font:inherit;color:var(--yazi);background:var(--taban);border:1px solid var(--cizgi);border-radius:11px">' +
    '<option value="10">10 soru</option><option value="20">20 soru</option><option value="40">40 soru</option></select></label></div>';
  var hesapB = $('hesap'); main.insertBefore(ayarB, hesapB || null);
  $('ayarSinav').value = IL.veri().ayar.sinav || 'yeterlilik';
  $('ayarHedef').value = String(IL.veri().ayar.hedef || 10);
  $('ayarSinav').onchange = function () { IL.ayarYaz({ sinav: this.value }); ciz(); };
  $('ayarHedef').onchange = function () { IL.ayarYaz({ hedef: +this.value }); ciz(); };

  /* hesapla eşitleme (B kümesi): girişliyse sunucudaki kayıtla birleştir; değiştiyse yeniden çiz.
     Tablo basılmadıysa / ağ yoksa sessizce yerelde kalır (ilerleme.js esitle → "yerel"). */
  function esitle() {
    try {
      if (!window.TT || !window.TT.istemci) return;
      var sb = window.TT.istemci();
      window.TT.kullanici(sb).then(function (k) {
        if (!k || k.cevrimdisi) return;
        IL.esitle(sb, k.id).then(function (s) { if (s === 'guncellendi') { ciz(); $('ayarSinav').value = IL.veri().ayar.sinav || 'yeterlilik'; $('ayarHedef').value = String(IL.veri().ayar.hedef || 10); } });
      }).catch(function () {});
    } catch (e) {}
  }

  ciz();
  kurulum();
  esitle();
  /* sınav listesi (#liste) giriş sonrası dolunca "devam et / şimdi çalış" uygunluğu değişir ve oturum yeni açılmış
     olabilir → yeniden çiz + eşitle; soru ekranından dönüşte de */
  try { new MutationObserver(function () { ciz(); esitle(); }).observe($('liste'), { childList: true }); } catch (e) {}
  document.addEventListener('visibilitychange', function () { if (!document.hidden) { ciz(); esitle(); } });
  window.addEventListener('pageshow', function () { ciz(); esitle(); });
})();
