/* uygulama-ozet.js — "BUGÜN" ve "KARNEM" SEKMELERİ + İLK AÇILIŞ + ÇALIŞMA AYARLARI (26.09.2026, yalnız telefon)
 *
 * Rakiplerde olup uygulamada olmayanlar (UWorld, Pocket Prep, Duolingo, AMBOSS incelemesi):
 *   - İlk açılış akışı: sınavını seç → günlük hedef → hatırlatıcı (Duolingo/Pocket Prep).
 *   - Bugün: günlük hedef + seri + doğru oranı ölçüsü · Devam et (kaldığın soru) · Günün sorusu · zayıf ders.
 *   - Karnem: çözülen / doğru / işaretli ölçüsü + derse göre doğru oranı + derse göre "yanlışlarını çöz".
 * 26.09 2. sürüm (Cem "yapay zekâ gibi durmasın, Nvidia/Tesla gibi"): emoji YOK, ince çizgi ikon, büyük ince rakam.
 * Rakamlar YALNIZ ilerleme.js kaydından (tt_ilerleme): her sorunun SON cevabı sayılır; tahmin/"geçme ihtimali" YOK.
 * Veri: ilerleme.js. Sayfalar: katalog.js (TT_KATALOG). Hesaba eşitleme: ilerleme.js esitle (ogrenci_ilerleme).
 * BU DOSYA ŞUNU YAPMAZ: sitede yüklenmez · paket okumaz (uygulama.js 'tt-durum').
 */
(function () {
  var IL = window.TTIlerleme, K = window.TT_KATALOG || {};
  if (!IL) return;
  function $(id) { return document.getElementById(id); }
  function esc(t) { return String(t).replace(/[&<>"]/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]; }); }
  function ik(ad, sinif) { return '<svg class="ik' + (sinif ? ' ' + sinif : '') + '" aria-hidden="true"><use href="#i-' + ad + '"/></svg>'; }
  var OK = ik('ok', 'ok');
  var tumSayfa = [].concat(K.paket || [], K.ucretsiz || []);
  function sayfa(yol) { return tumSayfa.filter(function (x) { return x.yol === yol; })[0] || null; }
  function sayfaAdi(yol) { var s = sayfa(yol); return s ? s.baslik : 'Son çalıştığın ders'; }
  function acikMi(yol) {  /* ücretsiz her zaman; paket sayfası hesapta açıksa (uygulama.js TT_DURUM) */
    if ((K.ucretsiz || []).some(function (x) { return x.yol === yol; })) return true;
    var D = window.TT_DURUM; return !!(D && D.acik && D.acik.indexOf(yol) >= 0);
  }

  var st = document.createElement('style');
  st.textContent = [
    '#ozet .kart,#karne .kart{margin-top:16px}',
    '.karneS{display:flex;align-items:center;gap:12px;padding:14px 16px}',
    '.karneS a,.karneS .blok{flex:1;min-width:0;color:var(--yazi);text-decoration:none}',
    '.karneS .ad{display:flex;justify-content:space-between;align-items:baseline;gap:10px;font-weight:550}',
    '.karneS .ad b{font-weight:300;font-size:20px;letter-spacing:-.02em;font-variant-numeric:tabular-nums}',
    '.karneS small{display:block;font-size:12.5px;color:var(--soluk);margin-top:1px}',
    '.karneS .bar{height:2px;background:var(--cizgi);margin-top:9px}',
    '.karneS .bar i{display:block;height:100%;background:var(--yazi)}',
    '.karneS .yanB{flex:none;display:flex;align-items:center;gap:6px;padding:8px 10px;border-radius:6px;border:1px solid var(--cizgi2);' +
      'background:none;color:var(--yazi);font:600 12px/1 inherit}',
    '.karneS .yanB svg{width:14px;height:14px}',
    /* ilk açılış */
    '#kurulum{position:fixed;inset:0;z-index:100;background:var(--taban);color:var(--yazi);display:flex;flex-direction:column;justify-content:flex-end;' +
      'padding:24px 20px calc(28px + max(env(safe-area-inset-bottom),var(--safe-area-inset-bottom,0px)))}',
    '#kurulum:before{content:"";position:absolute;left:20px;top:calc(30px + max(env(safe-area-inset-top),var(--safe-area-inset-top,0px)));width:7px;height:7px;background:var(--vurgu)}',
    '#kurulum:after{content:"TETİKTE";position:absolute;left:37px;top:calc(24px + max(env(safe-area-inset-top),var(--safe-area-inset-top,0px)));font-weight:700;font-size:13px;letter-spacing:.32em}',
    '#kurulum .adim{font-size:11px;font-weight:600;letter-spacing:.16em;color:var(--soluk);margin-bottom:18px;font-variant-numeric:tabular-nums}',
    '#kurulum .adim i{display:block;height:2px;background:var(--cizgi);margin-top:10px}',
    '#kurulum .adim i b{display:block;height:100%;background:var(--vurgu)}',
    '#kurulum h1{font-size:30px;margin:0 0 8px}',
    '#kurulum p{color:var(--soluk);margin:0 0 22px}',
    '#kurulum .atla{margin-top:14px;background:none;border:0;color:var(--soluk);font-size:13px;padding:10px}'
  ].join('\n');
  document.head.appendChild(st);

  var bugunB = $('ozet'), karneB = $('karne');

  /* ?tek=1: Kaydır-Çöz tek kart modu — yalnız o soru, kaydırma yok (26.09 Cem: "alt alta bir sürü soru çıkıyor") */
  function gununSorusu(sinav) {
    sinav = sinav || IL.veri().ayar.sinav || 'yeterlilik';
    var s = (K.ucretsiz || []).filter(function (x) { return x.sinav === sinav; })[0];
    if (!s) return null;
    var d = new Date(), gun = Math.floor((d.getTime() - d.getTimezoneOffset() * 60000) / 86400000);
    var i = gun % (s.adet || 30), on = (K.onizleme && K.onizleme[sinav] || [])[i] || null;
    return { yol: s.yol, sira: i, baslik: s.baslik, sinav: sinav, on: on };
  }

  /* derse göre sonuç (yalnız katalogdaki sayfalar); yanlış kimlikleri "yanlışlarını çöz" için */
  function dersler() {
    var v = IL.veri(), m = {};
    for (var sid in v.cevap) {
      var c = v.cevap[sid]; if (!c || !c.yol || !sayfa(c.yol)) continue;
      var r = m[c.yol] || (m[c.yol] = { yol: c.yol, ok: 0, yan: 0, yanlar: [] });
      if (c.s === 'ok') r.ok++; else { r.yan++; r.yanlar.push(sid); }
    }
    return Object.keys(m).map(function (y) { var r = m[y]; r.n = r.ok + r.yan; r.ad = sayfaAdi(y); r.oran = r.ok / r.n; return r; });
  }
  function toplam() {
    var v = IL.veri(), ok = 0, n = 0, bay = 0;
    for (var s in v.cevap) { n++; if (v.cevap[s].s === 'ok') ok++; }
    for (var b in v.bayrak) { if (v.bayrak[b] && !v.bayrak[b].yok) bay++; }
    return { n: n, ok: ok, bay: bay };
  }
  /* en zayıf ders: sorunun GERÇEK dersine göre (kayıttaki d; yoksa sayfa adı). Ancak en az iki ders (her biri 5+ cevap)
     kıyaslanabilince ve o dersin sayfası hesapta açıksa gösterilir — kilitli derse "şimdi çalış" demek yanıltır. */
  function enZayif() {
    var v = IL.veri(), m = {};
    for (var s in v.cevap) {
      var c = v.cevap[s]; if (!c || !c.yol) continue;
      var ad = c.d || sayfaAdi(c.yol), r = m[ad] || (m[ad] = { ad: ad, ok: 0, n: 0 });
      r.n++; if (c.s === 'ok') r.ok++;
    }
    var kiyas = Object.keys(m).map(function (k) { var r = m[k]; r.oran = r.ok / r.n; return r; }).filter(function (r) { return r.n >= 5; });
    if (kiyas.length < 2) return null;
    var z = kiyas.sort(function (a, b) { return a.oran - b.oran; })[0];
    var sayfaD = (K.paket || []).filter(function (d) { return d.baslik === z.ad && acikMi(d.yol); })[0];
    if (!sayfaD) return null;
    z.yol = sayfaD.yol;
    return z;
  }
  function yuzde(x) { return Math.round(x * 100); }
  function tarihYazi() {
    try { return new Date().toLocaleDateString('tr-TR', { weekday: 'long', day: 'numeric', month: 'long' }); } catch (e) { return ''; }
  }

  /* paketi olmayan (yeni gelen ya da paketsiz üye): açılış ekranı "Ücretsiz" (Cem 26.09 "başa ücretsiz").
     Paketi olan: "Bugün" (devam et, hedef, günün sorusu). acik === null (paket okunamadı) → paketli sayılmaz. */
  function paketsiz() { var D = window.TT_DURUM; return !D || !D.acik || !D.acik.length; }
  window.TTOzet = { paketsiz: paketsiz };

  function olcuKarti(v, h, bugun, seri, t) {
    return '<div class="kart"><div class="olcu">' +
      '<div><b>' + bugun + '<small> / ' + h + '</small></b><span>Soru</span></div>' +
      '<div><b>' + seri + '</b><span>Seri · gün</span></div>' +
      '<div><b>' + (t.n ? '<small>%</small>' + yuzde(t.ok / t.n) : '—') + '</b><span>Doğru</span></div></div>' +
      '<div class="cizgiBar"><i style="width:' + Math.min(100, Math.round(bugun / h * 100)) + '%"></i></div>' +
      '<div class="durumYazi">' + (bugun >= h ? 'Günlük hedef tamam. Seri korunuyor.' :
        (bugun ? 'Hedefe ' + (h - bugun) + ' soru kaldı.' : 'Günlük hedef ' + h + ' soru. İlk soruyla gün başlar.')) + '</div>' + haftaSeridi(h) + '</div>';
  }
  var KISA = { sgs: 'SGS', yeterlilik: 'Yeterlilik' };
  /* her sınavın günün sorusu (hariç: kahraman kartında gösterilen) */
  function gununSatiri(haric) {
    return ['sgs', 'yeterlilik'].filter(function (s) { return s !== haric; }).map(function (s) {
      var gs = gununSorusu(s); if (!gs) return '';
      return '<a class="srt" href="' + esc(gs.yol) + '?tek=1#s=' + gs.sira + '">' + ik('takvim') + '<span class="ad">Günün sorusu · ' + KISA[s] + '<small>' +
        esc(gs.on ? gs.on.d : gs.baslik) + (gs.on && gs.on.p ? ' · ' + gs.on.p + ' dönemde soru geldi' : ' · her gün yeni bir soru') + '</small></span>' + OK + '</a>';
    }).join('');
  }
  /* radar çizgisi — marka işareti (Tetikte = nöbette); süs değil, kartın köşesinde ince çizgi */
  var RADAR = '<svg class="radar" viewBox="0 0 200 200" aria-hidden="true"><circle cx="200" cy="0" r="60"/><circle cx="200" cy="0" r="105"/>' +
    '<circle cx="200" cy="0" r="150"/><circle cx="200" cy="0" r="195"/><path d="M200 0 L62 138"/></svg>';
  /* KAHRAMAN: günün sorusunun GERÇEK önizlemesi (kök + şıklar; doğru şık kartta YOK) — site kahramanı "Yanlışını böyle öğrenirsin." */
  function kahramanKart(sinav) {
    var gs = gununSorusu(sinav); if (!gs || !gs.on) return '';
    var o = gs.on, url = esc(gs.yol) + '?tek=1#s=' + gs.sira;
    var h = '<a class="kahraman" href="' + url + '">' + RADAR +
      '<span class="kUst"><i></i>Günün sorusu · ' + KISA[sinav] + ' · ' + esc(o.d) + '</span>' +
      (o.p ? '<span class="kDonem">' + o.p + ' dönemde soru geldi</span>' : '') +
      '<span class="kSoru">' + esc(o.s) + '</span><span class="kSiklar">';
    ['A', 'B', 'C', 'D', 'E'].forEach(function (x) { if (o.k[x]) h += '<span><b>' + x + '</b>' + esc(o.k[x]) + '</span>'; });
    return h + '</span><span class="kDugme">Çöz, tuzağını gör' + ik('ok') + '</span></a>';
  }
  /* bu haftanın 7 günü: dolu = hedef tuttu, çerçeve = çözdü ama hedefe varmadı (gerçek kayıt) */
  function haftaSeridi(h) {
    var v = IL.veri(), bas = new Date(), g = (bas.getDay() + 6) % 7, s = '<div class="hafta">';
    ['P', 'S', 'Ç', 'P', 'C', 'C', 'P'].forEach(function (ad, i) {
      var d = new Date(bas.getFullYear(), bas.getMonth(), bas.getDate() - g + i), n = v.gun[IL.bugun(d.getTime())] || 0;
      s += '<span class="' + (n >= h ? 'dolu' : n ? 'yari' : '') + (i === g ? ' bugun' : '') + '"><i></i>' + ad + '</span>';
    });
    return s + '</div>';
  }
  var SINAV_SIRA = [{ id: 'sgs', ad: 'SGS · Staja Giriş' }, { id: 'yeterlilik', ad: 'SMMM Yeterlilik' }, { id: 'kgk', ad: 'KGK Bağımsız Denetçilik' }];

  function ucretsizCiz(v, h, bugun, seri, t) {
    var D0 = window.TT_DURUM, uye = !!(D0 && D0.girisli);
    var secS = v.ayar.sinav === 'sgs' ? 'sgs' : 'yeterlilik';
    var html = '<span class="etk">' + (uye ? 'Ücretsiz üyeliğin açık' : 'Ücretsiz · ilk 3 soru hesapsız') + '</span>' +
      '<h1 class="slogan">Yanlışını böyle öğrenirsin.</h1>' +
      '<p class="soluk" style="margin-top:8px">Yanlış şıkta tuzağın adı ve doğrusu anında. Sınav başına 30 soru ücretsiz' +
      (uye ? '.' : '; 3 sorudan sonrası ücretsiz üyelikle.') + '</p>' + kahramanKart(secS);
    /* hangi sınavlara açığız — katalogdan, sabit yazı yok */
    html += '<span class="etk" style="margin-top:22px">Ücretsiz açık olanlar</span><div class="satirlar">';
    SINAV_SIRA.forEach(function (x) {
      var u = (K.ucretsiz || []).filter(function (d) { return d.sinav === x.id; })[0];
      if (u) {
        var r = IL.dersSonucu(u.yol), n = r.ok + r.yan;
        html += '<a class="srt" href="' + esc(u.yol) + '">' + ik('oynat') + '<span class="ad">' + esc(x.ad) + '<small>' +
          (u.adet || 30) + ' soru · açıklamalı</small></span>' + (n ? '<span class="sag">' + n + '/' + (u.adet || n) + '</span>' : '') + OK + '</a>';
      } else {
        html += '<div class="srt kilit">' + ik('kilit') + '<span class="ad">' + esc(x.ad) + '<small>Hazırlanıyor</small></span></div>';
      }
    });
    html += gununSatiri(secS) + '</div>';

    /* tam paket: sınav başına gerçek soru/ders sayısı, kilitli; dokununca o sınavın içi */
    var paketli = SINAV_SIRA.filter(function (x) { return (K.paket || []).some(function (d) { return d.sinav === x.id; }); });
    if (paketli.length) {
      html += '<span class="etk">Tam paket · kilitli</span><div class="satirlar">';
      paketli.forEach(function (x) {
        var p = (K.paket || []).filter(function (d) { return d.sinav === x.id; }), y = (K.yakinda || []).filter(function (d) { return d.sinav === x.id; });
        html += '<button type="button" class="srt kilit" data-sinav="' + x.id + '">' + ik('kilit') + '<span class="ad">' + esc(x.ad) + '<small>' +
          (p.length + y.length) + ' ders' + (y.length ? ' (' + y.length + ' hazırlanıyor)' : '') + ' · tüm sorular' +
          '</small></span>' + OK + '</button>';
      });
      html += '</div><p class="soluk kucuk" style="margin-top:10px">Pakette: ders ders çözme, kısa sınav, en çok çıkanlar ve sınav gibi deneme.</p>';
    }
    if (t.n) html += '<span class="etk">Bugün</span>' + olcuKarti(v, h, bugun, seri, t).replace('<div class="kart">', '<div class="kart" style="margin-top:0">');
    return html;
  }

  function bugunCiz() {
    IL.yenidenOku();
    var v = IL.veri(), h = v.ayar.hedef || 10, bugun = v.gun[IL.bugun()] || 0, seri = IL.seri(), t = toplam();
    var html;
    if (paketsiz()) html = ucretsizCiz(v, h, bugun, seri, t);
    else {
      html = '<span class="etk">' + esc(tarihYazi()) + '</span><h1>Bugün</h1>' + olcuKarti(v, h, bugun, seri, t);
      html += '<span class="etk">Sıradaki</span><div class="satirlar">';
      if (v.son && v.son.yol && acikMi(v.son.yol)) {
        html += '<a class="srt birincil" href="' + esc(v.son.yol) + '">' + ik('oynat') + '<span class="ad">Devam et<small>' +
          esc(sayfaAdi(v.son.yol)) + ' · ' + ((v.son.i || 0) + 1) + '. soru</small></span>' + OK + '</a>';
      } else {
        html += '<button type="button" class="srt birincil" data-sinav="' + esc(v.ayar.sinav || 'yeterlilik') + '">' + ik('oynat') +
          '<span class="ad">Çalışmaya başla<small>Dersini seç</small></span>' + OK + '</button>';
      }
      html += gununSatiri(v.ayar.sinav === 'sgs' ? 'sgs' : 'yeterlilik');
      var z = enZayif();
      if (z) html += '<a class="srt" href="' + esc(z.yol) + '">' + ik('karne') + '<span class="ad">En zayıf dersin<small>' +
        esc(z.ad) + '</small></span><span class="sag">%' + yuzde(z.oran) + '</span>' + OK + '</a>';
      html += '</div>' + kahramanKart(v.ayar.sinav === 'sgs' ? 'sgs' : 'yeterlilik');
    }

    var D = window.TT_DURUM;
    if (D && !D.girisli) {
      html += '<span class="etk">Hesap</span><div class="satirlar"><button type="button" class="srt" data-git="uyeol">' + ik('hesap') +
        '<span class="ad">Ücretsiz üye ol<small>30 soru, açıklamalar ve karnen açılır; kart istenmez</small></span>' + OK + '</button>' +
        '<button type="button" class="srt" data-git="giris">' + ik('giris') +
        '<span class="ad">Hesabım var, giriş yap<small>Paketindeki dersler açılır</small></span>' + OK + '</button></div>';
    }
    bugunB.innerHTML = html;
    [].forEach.call(bugunB.querySelectorAll('[data-git]'), function (g) {
      g.onclick = function () { if (window.TTGiris) window.TTGiris.ac(g.dataset.git === 'uyeol' ? 'uye' : 'giris'); };
    });
    [].forEach.call(bugunB.querySelectorAll('[data-sinav]'), function (b) {
      b.onclick = function () { if (window.TTSinavlar) window.TTSinavlar.ac(b.dataset.sinav); };
    });
    try { document.dispatchEvent(new CustomEvent('tt-acilis', { detail: paketsiz() ? 'ucretsiz' : 'bugun' })); } catch (e) {}
  }

  /* uygulama-kaydir.js tekrarKur: sayfa açılınca yalnız bu kimliklerin kartları görünür */
  function yanlislariCoz(r) {
    try { sessionStorage.setItem('tt_tekrar', JSON.stringify({ yol: r.yol, sid: r.yanlar })); } catch (e) {}
    location.href = r.yol;
  }

  /* ---------- KARNEM (26.09.2026, Cem "yurt dışı rakiplerde ne varsa, dikkat çeken bir şey; paralı kısım kapalı kalsın")
     Rakip incelemesi: UWorld/AMBOSS/Pocket Prep karnesi = derse göre başarı + soru başına süre + yanlışlarım + zayıf alan.
     Bizde olup onlarda olmayan: TUZAK HARİTASI — her yanlış şıkkın adı (kalıbın tuzak alanı) sayılır, "en çok hangi
     tuzağa düşüyorsun" gösterilir. Açık (herkese): özet, hafta, derslere göre güçlü/zayıf + açıklama, yanlışlarım.
     Paketliye: tuzak haritası + konu haritası; paketi olmayana GERÇEK verisi bulanık + "Kilidi aç" (pazarlama kapısı).
     Rakamlar yalnız cevap kaydından (tt_ilerleme). Eski kayıtta ders/süre/tuzak yoksa o kayıt o hesaba girmez. */
  function sure(sn) { if (!sn) return '0 dk'; if (sn < 60) return sn + ' sn'; var d = Math.round(sn / 60); return d < 60 ? d + ' dk' : Math.floor(d / 60) + ' sa ' + (d % 60) + ' dk'; }
  function kayitlar() {
    var v = IL.veri(), l = [];
    for (var s in v.cevap) { var c = v.cevap[s]; if (c && c.yol) { var r = Object.create(c); r.sid = s; r.ders = c.d || sayfaAdi(c.yol); l.push(r); } }
    return l;
  }
  function grupla(l, anahtar) {
    var m = {};
    l.forEach(function (c) { var a = anahtar(c); if (!a) return; var g = m[a] || (m[a] = { ad: a, ok: 0, yan: 0, sn: 0, snN: 0, tz: {}, yanlar: [] });
      if (c.s === 'ok') g.ok++; else { g.yan++; g.yanlar.push(c); if (c.tz) g.tz[c.tz] = (g.tz[c.tz] || 0) + 1; }
      if (c.sn) { g.sn += c.sn; g.snN++; } });
    return Object.keys(m).map(function (a) { var g = m[a]; g.n = g.ok + g.yan; g.oran = g.ok / g.n; return g; });
  }
  function enCok(o) { var k = Object.keys(o).sort(function (a, b) { return o[b] - o[a]; })[0]; return k ? { ad: k, n: o[k] } : null; }
  function kilitKutusu(baslik, alt, icerik, acik) {
    return '<span class="etk">' + baslik + (acik ? '' : ' · paket') + '</span><div class="kart kilitKutu' + (acik ? '' : ' kapali') + '">' +
      '<div class="kIcerik">' + icerik + '</div>' + (acik ? '' : '<div class="kPerde">' + ik('kilit') + '<b>' + alt + '</b>' +
      '<button type="button" class="ana" data-kilitac="1">Kilidi aç</button></div>') + '</div>';
  }

  function karneCiz() {
    var l = kayitlar(), html = '<h1>Karnem</h1>';
    if (!l.length) {
      karneB.innerHTML = html + '<div class="kart bosDurum"><b>Henüz ölçüm yok</b>' +
        'Çözdüğün her soru burada ölçülür: derse göre başarın, harcadığın süre, yanlışların ve en çok düştüğün tuzaklar.</div>';
      return;
    }
    var ok = l.filter(function (c) { return c.s === 'ok'; }).length, n = l.length, y = yuzde(ok / n), C = 2 * Math.PI * 42;
    var snT = 0, snN = 0; l.forEach(function (c) { if (c.sn) { snT += c.sn; snN++; } });
    html += '<div class="kart karneUst"><svg class="halka" viewBox="0 0 100 100" aria-hidden="true"><circle cx="50" cy="50" r="42"/>' +
      '<circle class="dolu" cx="50" cy="50" r="42" stroke-dasharray="' + (C * y / 100).toFixed(1) + ' ' + C.toFixed(1) + '"/></svg>' +
      '<div class="halkaYazi"><b><small>%</small>' + y + '</b><span>Doğru</span></div>' +
      '<div class="olcu iki"><div><b>' + n.toLocaleString('tr-TR') + '</b><span>Çözülen</span></div>' +
      '<div><b>' + (snN ? sure(snT) : '—') + '</b><span>Süre</span></div></div></div>';

    /* bu hafta: günlük soru sayısı (gerçek kayıt) */
    var v = IL.veri(), bugunD = new Date(), g0 = (bugunD.getDay() + 6) % 7, gunler = [], enFazla = 1;
    for (var i = 0; i < 7; i++) { var d = new Date(bugunD.getFullYear(), bugunD.getMonth(), bugunD.getDate() - g0 + i), s = v.gun[IL.bugun(d.getTime())] || 0; gunler.push(s); if (s > enFazla) enFazla = s; }
    var haftaT = gunler.reduce(function (a, b) { return a + b; }, 0);
    html += '<span class="etk">Bu hafta</span><div class="kart"><div class="cubukGrafik">' + gunler.map(function (s, i) {
      return '<span class="' + (i === g0 ? 'bugun' : '') + '"><i style="height:' + Math.round(s / enFazla * 100) + '%"></i><em>' + (s || '') + '</em>' + ['P', 'S', 'Ç', 'P', 'C', 'C', 'P'][i] + '</span>';
    }).join('') + '</div><div class="durumYazi">Bu hafta ' + haftaT + ' soru' + (snN ? ' · soru başına ortalama ' + Math.round(snT / snN) + ' sn' : '') + '</div></div>';

    /* derslere göre: güçlü / zayıf + açıklama (en az 5 cevap) */
    var ds = grupla(l, function (c) { return c.ders; }).sort(function (a, b) { return b.n - a.n; });
    html += '<span class="etk">Derslere göre</span><div class="satirlar">';
    ds.forEach(function (g) {
      var yy = yuzde(g.oran), etiket = g.n < 5 ? '<span class="etiketK">Ölçülüyor</span>' : yy >= 70 ? '<span class="etiketK iyi">Güçlü</span>' : yy < 50 ? '<span class="etiketK zayif">Zayıf</span>' : '';
      html += '<div class="karneS"><div class="blok"><span class="ad"><span>' + esc(g.ad) + ' ' + etiket + '</span><b>%' + yy + '</b></span>' +
        '<small>' + g.n + ' soru · ' + g.yan + ' yanlış' + (g.snN ? ' · ort. ' + Math.round(g.sn / g.snN) + ' sn' : '') + '</small>' +
        '<div class="bar"><i style="width:' + yy + '%"></i></div></div></div>';
    });
    html += '</div>';
    var olcfinal = ds.filter(function (g) { return g.n >= 5; });
    if (olcfinal.length) {
      var z = olcfinal.slice().sort(function (a, b) { return a.oran - b.oran; })[0], gu = olcfinal.slice().sort(function (a, b) { return b.oran - a.oran; })[0];
      html += '<p class="aciklama">' + (gu !== z ? 'En güçlü dersin <b>' + esc(gu.ad) + '</b> (%' + yuzde(gu.oran) + '). ' : '') +
        'En çok zorlandığın ders <b>' + esc(z.ad) + '</b>: ' + z.n + ' sorunun ' + z.yan + '\'i yanlış' +
        (z.snN && snN && z.sn / z.snN > snT / snN * 1.2 ? ', üstelik bu derste soru başına ortalamadan daha uzun düşünüyorsun' : '') + '.</p>';
    }

    /* yanlışlarım: son 8 yanlış, dokununca o soru tek başına açılır */
    var yan = l.filter(function (c) { return c.s !== 'ok'; }).sort(function (a, b) { return b.t - a.t; });
    if (yan.length) {
      html += '<span class="etk">Yanlışlarım · ' + yan.length + '</span><div class="satirlar">';
      yan.slice(0, 8).forEach(function (c, j) {
        var acik = acikMi(c.yol), tarih = new Date(c.t).toLocaleDateString('tr-TR', { day: 'numeric', month: 'short' });
        html += '<button type="button" class="srt" data-yanlis="' + j + '"' + (acik ? '' : ' disabled') + '>' + ik('tekrar') + '<span class="ad">' + esc(c.k || c.ders) +
          '<small>' + esc(c.ders) + ' · ' + tarih + (c.tz ? ' · ' + esc(c.tz) : '') + '</small></span>' + (acik ? OK : '') + '</button>';
      });
      html += '</div>';
    }

    /* PAKETLİ: tuzak haritası + konu haritası (paketsize gerçek veri bulanık, kilitli) */
    var paketli = !paketsiz();
    var tzT = {}; l.forEach(function (c) { if (c.s !== 'ok' && c.tz) tzT[c.tz] = (tzT[c.tz] || 0) + 1; });
    var tzL = Object.keys(tzT).sort(function (a, b) { return tzT[b] - tzT[a]; }).slice(0, 5);
    var tzIc = tzL.length ? tzL.map(function (a) { return '<div class="sira"><span>' + esc(a) + '</span><b>' + tzT[a] + ' kez</b></div>'; }).join('') :
      '<div class="sira"><span>Henüz tuzağa düşmedin</span><b>—</b></div>';
    html += kilitKutusu('Tuzak haritası', 'En çok düştüğün tuzaklar pakette', '<p class="kAlt">Yanlış şıkların hangi tuzaktan geldiği: en çok düştüklerin.</p>' + tzIc, paketli);
    var ks = grupla(l.filter(function (c) { return c.k; }), function (c) { return c.k; }).filter(function (g) { return g.n >= 2; })
      .sort(function (a, b) { return a.oran - b.oran; }).slice(0, 5);
    var cok = l.filter(function (c) { return c.p >= 5; }), cokOk = cok.filter(function (c) { return c.s === 'ok'; }).length;
    var kIc = (cok.length ? '<div class="sira vurgu"><span>En çok çıkan konularda (5+ dönem) başarın</span><b>%' + yuzde(cokOk / cok.length) + '</b></div>' : '') +
      (ks.length ? ks.map(function (g) { return '<div class="sira"><span>' + esc(g.ad) + '</span><b>%' + yuzde(g.oran) + ' · ' + g.n + '</b></div>'; }).join('') :
        '<div class="sira"><span>Konu başına en az 2 soru çözünce görünür</span><b>—</b></div>');
    html += kilitKutusu('Konu haritası', 'Konu konu zayıf noktaların pakette', '<p class="kAlt">En zayıf konuların ve sınavda en çok çıkan konulardaki başarın.</p>' + kIc, paketli);

    html += '<p class="soluk kucuk" style="margin-top:14px">Her sorunun son cevabı sayılır. Süre, soru açıldığından cevaplanana kadar geçen zamandır. Ölçüm bu cihazda ve giriş yaptıysan hesabında tutulur.</p>';
    karneB.innerHTML = html;
    [].forEach.call(karneB.querySelectorAll('[data-yanlis]'), function (b) {
      b.onclick = function () {
        var c = yan[+b.dataset.yanlis];
        if (c.i != null) location.href = c.yol + '?tek=1#s=' + c.i;
        else { try { sessionStorage.setItem('tt_tekrar', JSON.stringify({ yol: c.yol, sid: [c.sid] })); } catch (e) {} location.href = c.yol; }
      };
    });
    [].forEach.call(karneB.querySelectorAll('[data-kilitac]'), function (b) {
      b.onclick = function () { if (window.TTSinavlar) window.TTSinavlar.ac(IL.veri().ayar.sinav === 'sgs' ? 'sgs' : 'yeterlilik'); };
    });
  }

  function ciz() { bugunCiz(); karneCiz(); }

  /* ilk açılış: sınav → günlük hedef → hatırlatıcı */
  function kurulum() {
    if (IL.veri().ayar.kurulum) return;
    var e = document.createElement('div'); e.id = 'kurulum'; document.body.appendChild(e);
    var bitir = function () { IL.ayarYaz({ kurulum: true }); e.remove(); ciz(); if (window.TTSinavlar) window.TTSinavlar.ciz(); };
    var bas = function (n) { return '<div class="adim">0' + n + ' / 03<i><b style="width:' + Math.round(n / 3 * 100) + '%"></b></i></div>'; };
    var secenek = function (v, ad, alt) { return '<button type="button" class="srt" data-v="' + v + '"><span class="ad">' + ad + '<small>' + alt + '</small></span>' + OK + '</button>'; };
    var adim1 = function () {
      e.innerHTML = bas(1) + '<h1>Hangi sınava hazırlanıyorsun?</h1><p>Günün sorusu ve öneriler buna göre gelir. Sonra Hesap’tan değiştirebilirsin.</p>' +
        '<div class="satirlar">' + secenek('yeterlilik', 'SMMM Yeterlilik', '8 ders') + secenek('sgs', 'SGS · Staja Giriş', 'Staja başlama sınavı') + '</div>' +
        '<button type="button" class="atla">Şimdilik geç</button>';
      e.querySelector('.atla').onclick = bitir;
      [].forEach.call(e.querySelectorAll('.srt'), function (b) {
        b.onclick = function () { IL.ayarYaz({ sinav: b.dataset.v }); try { sessionStorage.removeItem('tt_uyg_sinavsec'); } catch (x) {} adim2(); };
      });
    };
    var adim2 = function () {
      e.innerHTML = bas(2) + '<h1>Günde kaç soru?</h1><p>Hedefini tuttuğun her gün serin bir artar. Az ama her gün, çok ama arada bir çalışmaktan iyidir.</p>' +
        '<div class="satirlar">' + secenek('10', '10 soru', 'Günde yaklaşık 15 dakika') + secenek('20', '20 soru', 'Günde yaklaşık 30 dakika') +
        secenek('40', '40 soru', 'Günde yaklaşık 1 saat') + '</div>';
      [].forEach.call(e.querySelectorAll('.srt'), function (b) { b.onclick = function () { IL.ayarYaz({ hedef: +b.dataset.v }); adim3(); }; });
    };
    var adim3 = function () {
      var yerel = !!(window.Capacitor && window.Capacitor.isNativePlatform && window.Capacitor.isNativePlatform());
      if (!yerel || !$('hatAcik')) return bitir();
      e.innerHTML = bas(3) + '<h1>Her gün hatırlatayım mı?</h1><p>Akşam 20:00’de kısa bir bildirim. Saati Hesap’tan değiştirebilirsin.</p>' +
        '<div class="satirlar">' + secenek('evet', 'Evet, hatırlat', 'Her gün 20:00') + secenek('hayir', 'Hayır', 'Bildirim gönderilmez') + '</div>';
      [].forEach.call(e.querySelectorAll('.srt'), function (b) {
        b.onclick = function () { if (b.dataset.v === 'evet' && !$('hatAcik').checked) $('hatAcik').click(); bitir(); };
      });
    };
    adim1();
  }

  /* Hesap sekmesi: çalışma ayarları (ilk açılışta "sonra değiştirebilirsin" denen yer) */
  var ayarB = document.createElement('section');
  ayarB.id = 'calismaAyar'; ayarB.className = 'bolum'; ayarB.setAttribute('data-sekme', 'hesap');
  ayarB.innerHTML = '<span class="etk">Çalışma</span><div class="kart">' +
    '<label>Sınavım<select id="ayarSinav"><option value="yeterlilik">SMMM Yeterlilik</option><option value="sgs">SGS · Staja Giriş</option></select></label>' +
    '<label>Günlük hedef<select id="ayarHedef"><option value="10">10 soru</option><option value="20">20 soru</option><option value="40">40 soru</option></select></label>' +
    '<label style="margin-bottom:0">Görünüm<select id="ayarGorunum"><option value="acik">Açık (önerilen, okuması kolay)</option>' +
    '<option value="koyu">Koyu</option><option value="sistem">Telefonun ayarına göre</option></select></label></div>';
  $('hatirlatici').parentNode.insertBefore(ayarB, $('hatirlatici'));
  function ayarOku() { $('ayarSinav').value = IL.veri().ayar.sinav || 'yeterlilik'; $('ayarHedef').value = String(IL.veri().ayar.hedef || 10); }
  ayarOku();
  $('ayarSinav').onchange = function () {
    IL.ayarYaz({ sinav: this.value }); try { sessionStorage.removeItem('tt_uyg_sinavsec'); } catch (x) {}
    ciz(); if (window.TTSinavlar) window.TTSinavlar.ciz();
  };
  $('ayarHedef').onchange = function () { IL.ayarYaz({ hedef: +this.value }); ciz(); };
  if (window.TTGorunum) {
    $('ayarGorunum').value = window.TTGorunum.deger();
    $('ayarGorunum').onchange = function () {
      try { localStorage.setItem('tt_gorunum', this.value); } catch (e) {}
      document.documentElement.setAttribute('data-gorunum', window.TTGorunum.koyu() ? 'koyu' : 'acik');
      window.TTGorunum.cubuk();
    };
    window.TTGorunum.cubuk();
  }

  /* hesapla eşitleme: girişliyse sunucudaki kayıtla birleştir; değiştiyse yeniden çiz.
     Ağ yoksa sessizce yerelde kalır (ilerleme.js esitle → "yerel"). */
  function esitle() {
    try {
      if (!window.TT || !window.TT.istemci) return;
      var sb = window.TT.istemci();
      window.TT.kullanici(sb).then(function (k) {
        if (!k || k.cevrimdisi) return;
        IL.esitle(sb, k.id).then(function (s) { if (s === 'guncellendi') { ciz(); ayarOku(); if (window.TTSinavlar) window.TTSinavlar.ciz(); } });
      }).catch(function () {});
    } catch (e) {}
  }

  ciz();
  kurulum();
  /* giriş durumu değişince (uygulama.js) "devam et / giriş yap" uygunluğu değişir; oturum yeni açılmış olabilir */
  document.addEventListener('tt-durum', function () { ciz(); esitle(); });
  document.addEventListener('tt-sinav', function () { ayarOku(); ciz(); });
  document.addEventListener('visibilitychange', function () { if (!document.hidden) { ciz(); esitle(); } });
  window.addEventListener('pageshow', function () { ciz(); esitle(); });
})();
