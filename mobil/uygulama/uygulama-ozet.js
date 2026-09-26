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
  /* sitenin resmî amblemi (logo-acik.svg) — index.html üst şeritteki ile aynı */
  var LOGO = "<svg class=\"logo\" viewBox=\"24 18 280 84\" role=\"img\" aria-label=\"Tetikte\"><defs><linearGradient id=\"ttLogoA2\" x1=\"0\" y1=\"0\" x2=\"1\" y2=\"1\"><stop offset=\"0\" stop-color=\"#f5a524\"/><stop offset=\"1\" stop-color=\"#ffc24b\"/></linearGradient><radialGradient id=\"ttLogoH2\" cx=\"50%\" cy=\"50%\" r=\"50%\"><stop offset=\"52%\" stop-color=\"#f5a524\" stop-opacity=\".26\"/><stop offset=\"100%\" stop-color=\"#f5a524\" stop-opacity=\"0\"/></radialGradient></defs><circle cx=\"62\" cy=\"60\" r=\"34\" fill=\"url(#ttLogoH2)\"/><circle cx=\"62\" cy=\"60\" r=\"19\" fill=\"url(#ttLogoA2)\"/><text x=\"112\" y=\"78\" font-family=\"Inter,Segoe UI,system-ui,-apple-system,Roboto,Arial,sans-serif\" font-size=\"58\" font-weight=\"800\" letter-spacing=\"-1.4\" textLength=\"181\" lengthAdjust=\"spacingAndGlyphs\" fill=\"currentColor\">tetıkte</text><circle cx=\"197\" cy=\"30\" r=\"7\" fill=\"url(#ttLogoA2)\"/></svg>";
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
    /* ilk açılış (26.09 Cem "üstü bomboş, kalite sıfır"): Apple karşılama ekranı düzeni — lacivert bant + ürünün
       kendisi (gerçek soru, yanlış şık, tuzağın adı, kural) + üç adım; boşluk bırakmayan akış, altta sabit düğme */
    '#kurulum{position:fixed;inset:0;z-index:100;background:radial-gradient(120% 420px at 50% -60px,var(--aura),transparent 70%) no-repeat,var(--taban);color:var(--yazi);overflow-y:auto;-webkit-overflow-scrolling:touch}',
    '#kurulum .kB{color:var(--yazi);padding:calc(20px + max(env(safe-area-inset-top),var(--safe-area-inset-top,0px))) 22px 8px}',
    '#kurulum .kMarka{display:flex;align-items:center;justify-content:space-between;font-weight:700;font-size:13px;letter-spacing:.32em}',
    '#kurulum .kMarka span{display:flex;align-items:center;gap:10px}#kurulum .kMarka i{width:7px;height:7px;background:#f5a524}',
    '#kurulum .kMarka em{font-style:normal;font-size:12px;font-weight:600;color:var(--soluk);font-variant-numeric:tabular-nums}',
    '#kurulum .kB h1{font-size:38px;line-height:1.02;margin:30px 0 12px}',
    '#kurulum .kB p{color:var(--soluk);margin:0;font-size:16px;line-height:1.5}',
    '#kurulum .kIc{padding:18px 16px calc(110px + max(env(safe-area-inset-bottom),var(--safe-area-inset-bottom,0px)))}',
    '#kurulum .ornek{background:var(--panel);border-radius:22px;box-shadow:var(--golge);padding:20px 18px;position:relative;overflow:hidden}',
    '#kurulum .oUst{font-size:10.5px;font-weight:600;letter-spacing:.14em;text-transform:uppercase;color:var(--vurgu)}',
    '#kurulum .oSoru{margin:10px 0 12px;font-size:14.5px;line-height:1.5;display:-webkit-box;-webkit-line-clamp:3;-webkit-box-orient:vertical;overflow:hidden}',
    '#kurulum .oSik{display:flex;align-items:center;gap:10px;padding:10px 12px;border-radius:10px;border:1.5px solid var(--hata);background:color-mix(in srgb,var(--hata) 7%,var(--panel));font-size:14px}',
    '#kurulum .oSik b{flex:none;width:22px;height:22px;display:grid;place-items:center;border-radius:5px;background:var(--hata);color:#fff;font-size:12px}',
    '#kurulum .oSik small{margin-left:auto;font-size:11px;color:var(--hata);font-weight:600;white-space:nowrap}',
    '#kurulum .oTuzak{display:inline-flex;align-items:center;gap:7px;margin:12px 0 8px;padding:6px 10px;border-radius:6px;background:color-mix(in srgb,#f5a524 16%,var(--panel));color:var(--yazi);font-size:12.5px;font-weight:600}',
    '#kurulum .oTuzak:before{content:"";width:6px;height:6px;background:#f5a524}',
    '#kurulum .oKural{font-size:13.5px;line-height:1.5;color:var(--soluk);display:-webkit-box;-webkit-line-clamp:3;-webkit-box-orient:vertical;overflow:hidden}',
    '#kurulum .oKural b{color:var(--iyi)}',
    '#kurulum .adimlar{margin-top:22px;display:grid;gap:18px;padding:0 6px}',
    '#kurulum .adimlar div{display:flex;gap:14px;align-items:flex-start}',
    '#kurulum .adimlar .no{flex:none;width:34px;height:34px;border-radius:12px;display:grid;place-items:center;background:var(--vurguDolgu);color:#1c1100;font:700 15px/1 var(--sistem)}',
    '#kurulum .adimlar b{display:block;font-size:15.5px;font-weight:600}',
    '#kurulum .adimlar span{display:block;font-size:13.5px;color:var(--soluk);margin-top:2px;line-height:1.45}',
    '#kurulum .kAlt{position:fixed;left:0;right:0;bottom:0;padding:14px 20px calc(16px + max(env(safe-area-inset-bottom),var(--safe-area-inset-bottom,0px)));background:linear-gradient(to top,var(--taban) 70%,transparent)}',
    '#kurulum .kAlt .ana{padding:17px;font-size:16px;border-radius:999px}',
    '#kurulum .secim{display:grid;gap:12px}',
    '#kurulum .secim .sinavKart{margin:0}',
    '#kurulum .secim .srt{min-height:64px}',
    '#kurulum .tempo{display:grid;grid-template-columns:1fr 1fr;gap:12px}',
    '#kurulum .tKart{position:relative;display:flex;flex-direction:column;align-items:flex-start;gap:2px;min-height:124px;padding:16px;border:2px solid transparent;border-radius:22px;background:var(--panel);box-shadow:var(--golge);color:var(--yazi);text-align:left;font:inherit}',
    '#kurulum .tKart b{font-size:30px;font-weight:800;letter-spacing:-.03em;line-height:1}',
    '#kurulum .tKart b small{font-size:13px;font-weight:600;color:var(--soluk);letter-spacing:0}',
    '#kurulum .tKart span{margin-top:auto;font-weight:700;font-size:14.5px}',
    '#kurulum .tKart em{font-style:normal;font-size:12.5px;color:var(--soluk)}',
    '#kurulum .tKart.oneri{border-color:var(--vurguDolgu)}',
    '#kurulum .tRozet{position:absolute;top:-11px;left:16px;font-size:10.5px;font-weight:700;padding:4px 8px;border-radius:999px;background:var(--vurguDolgu);color:#1c1100}',
    '#kurulum .tKart:active,#kurulum .sKart:active{transform:scale(.97)}',
    '#kurulum .saatler{display:grid;gap:12px}',
    '#kurulum .sKart{display:flex;align-items:center;gap:16px;padding:18px;border:2px solid transparent;border-radius:22px;background:var(--panel);box-shadow:var(--golge);color:var(--yazi);font:inherit;text-align:left}',
    '#kurulum .sKart b{font-size:26px;font-weight:800;letter-spacing:-.03em;font-variant-numeric:tabular-nums}',
    '#kurulum .sKart span{color:var(--soluk);font-weight:600}',
    '#kurulum .sKart[aria-pressed=true]{border-color:var(--vurguDolgu)}',
    '#kurulum .hic{margin-top:14px}',
    '#kurulum .kNot{margin:16px 6px 0;font-size:13px;color:var(--soluk);line-height:1.5}'
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

  /* 27.09: veri paneli — hedef halkası (SVG), doğru oranı çubuğu; ayrı ilerleme çizgisi kalktı (halka aynı bilgiyi veriyor) */
  function olcuKarti(v, h, bugun, seri, t) {
    var oran = Math.min(1, bugun / h), C = 97.4; /* 2πr, r=15.5 */
    return '<div class="kart"><div class="olcu panel">' +
      '<div class="oHalka"><svg viewBox="0 0 36 36" aria-hidden="true"><circle cx="18" cy="18" r="15.5"/><circle class="dolu" cx="18" cy="18" r="15.5" ' +
      'stroke-dasharray="' + (oran * C).toFixed(1) + ' ' + C + '"' + (oran ? '' : ' style="display:none"') + '/></svg><b>' + bugun + '<small>/' + h + '</small></b><span>Soru</span></div>' +
      '<div><b>' + seri + '</b><span>Seri · gün</span></div>' +
      '<div><b>' + (t.n ? '<small>%</small>' + yuzde(t.ok / t.n) : '—') + '</b><span>Doğru</span>' +
      '<em class="oBar"><i style="width:' + (t.n ? yuzde(t.ok / t.n) : 0) + '%"></i></em></div></div>' +
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
  /* tutarlar (8.125.400 ₺ gibi) hizalı rakam + hafif zemin; yalnız binlik ayraçlı sayılar — yıl, madde no dokunulmaz */
  function rakamVurgu(s) { return s.replace(/\d{1,3}(?:\.\d{3})+(?:,\d+)?(?:\s?(?:₺|TL))?/g, '<span class="rk">$&</span>'); }
  function kahramanKart(sinav) {
    var gs = gununSorusu(sinav); if (!gs || !gs.on) return '';
    var o = gs.on, url = esc(gs.yol) + '?tek=1#s=' + gs.sira;
    var h = '<a class="kahraman" href="' + url + '">' + RADAR +
      '<span class="kUst"><i></i>Günün sorusu · ' + KISA[sinav] + ' · ' + esc(o.d) + '</span>' +
      (o.p ? '<span class="kDonem"><i></i>' + o.p + ' dönemde soru geldi</span>' : '') +
      '<span class="kSoru">' + rakamVurgu(esc(o.s)) + '</span><span class="kSiklar">';
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
  var SINAV_AD = { sgs: 'SGS · Staja Giriş', yeterlilik: 'SMMM Yeterlilik (Bitirme)', kgk: 'KGK Bağımsız Denetçilik' };
  function seciliSinav() { return IL.veri().ayar.sinav === 'sgs' ? 'sgs' : 'yeterlilik'; }
  function sinaviNe(yol) { return /\/(sgs)(\.html|\/)/.test(yol) ? 'sgs' : 'yeterlilik'; }
  /* günlük tempo: [soru, ad, süre] — süre soru başına ~90 sn (sınav temposu) */
  var TEMPO = [[10, 'Isınma turu', 'Günde ~15 dk'], [20, 'İstikrarlı tempo', 'Günde ~30 dk'], [30, 'Hızlandırılmış', 'Günde ~45 dk'], [50, 'Sınav kampı', 'Günde ~75 dk']];
  var SINAV_SIRA = [{ id: 'sgs', ad: 'SGS · Staja Giriş' }, { id: 'yeterlilik', ad: 'SMMM Yeterlilik' }, { id: 'kgk', ad: 'KGK Bağımsız Denetçilik' }];

  function ucretsizCiz(v, h, bugun, seri, t) {
    var D0 = window.TT_DURUM, uye = !!(D0 && D0.girisli);
    var secS = seciliSinav();
    var html = '<div class="bant kompakt"><span class="etk">' + (uye ? 'Ücretsiz üyeliğin açık' : 'Ücretsiz · ilk 3 soru hesapsız') + '</span>' +
      '<h1 class="slogan">Yanlışını böyle öğrenirsin.</h1>' +
      '<p class="soluk">Yanlış şıkta tuzağın adı ve doğrusu anında. 30 soru ücretsiz' +
      (uye ? '.' : '; 3 sorudan sonrası ücretsiz üyelikle.') + '</p></div>' + kahramanKart(secS);
    /* hangi sınavlara açığız — katalogdan, sabit yazı yok */
    /* 26.09 Cem: "sınavını seçsin, bütün sınavları görmesin" — yalnız seçilen sınav */
    /* 27.09: örnek sorular düz satır değil, ilerleme çubuklu kart (Sınavlar ekranıyla aynı dil); tekrar satırı ayrı */
    html += '<span class="etk" style="margin-top:22px">Ücretsiz · ' + esc(SINAV_AD[secS]) + '</span>';
    var tk = tekrarSatiri();
    if (tk) html += '<div class="satirlar" style="margin-bottom:12px">' + tk + '</div>';
    var u = (K.ucretsiz || []).filter(function (d) { return d.sinav === secS; })[0];
    if (u) {
      var r0 = IL.dersSonucu(u.yol), n0 = r0.ok + r0.yan, top0 = u.adet || 30;
      html += '<a class="ilerKart" href="' + esc(u.yol) + '"><span class="iUst"><span class="iAd">Örnek sorular<small>' + top0 +
        ' soru · açıklamalı</small></span><span class="iDugme">' + (n0 ? 'Devam et' : 'Başla') + ik('ok') + '</span></span>' +
        '<span class="iCubuk"><i style="width:' + Math.min(100, Math.round(n0 / top0 * 100)) + '%"></i></span>' +
        '<span class="iAlt">' + n0 + ' / ' + top0 + ' soru çözüldü</span></a>';
    } else {
      html += '<div class="kart bosDurum"><b>Hazırlanıyor</b>Bu sınavın ücretsiz soruları yakında.</div>';
    }

    /* tam paket: sınav başına gerçek soru/ders sayısı, kilitli; dokununca o sınavın içi */
    var paketli = SINAV_SIRA.filter(function (x) { return x.id === secS && (K.paket || []).some(function (d) { return d.sinav === x.id; }); });
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
      html = '<div class="bant"><span class="etk">' + esc(tarihYazi()) + '</span><h1>Bugün</h1></div>' + olcuKarti(v, h, bugun, seri, t);
      html += '<span class="etk">Sıradaki</span><div class="satirlar">' + tekrarSatiri();
      if (v.son && v.son.yol && acikMi(v.son.yol)) {
        html += '<a class="srt birincil" href="' + esc(v.son.yol) + '">' + ik('oynat') + '<span class="ad">Devam et<small>' +
          esc(sayfaAdi(v.son.yol)) + ' · ' + ((v.son.i || 0) + 1) + '. soru</small></span>' + OK + '</a>';
      } else {
        html += '<button type="button" class="srt birincil" data-sinav="' + esc(v.ayar.sinav || 'yeterlilik') + '">' + ik('oynat') +
          '<span class="ad">Çalışmaya başla<small>Dersini seç</small></span>' + OK + '</button>';
      }
      var z = enZayif();
      if (z) html += '<a class="srt" href="' + esc(z.yol) + '">' + ik('karne') + '<span class="ad">En zayıf dersin<small>' +
        esc(z.ad) + '</small></span><span class="sag">%' + yuzde(z.oran) + '</span>' + OK + '</a>';
      html += '</div>' + kahramanKart(seciliSinav());
    }

    var D = window.TT_DURUM;
    if (D && !D.girisli) {
      html += '<span class="etk">Hesap</span><div class="satirlar"><button type="button" class="srt" data-git="uyeol">' + ik('hesap', 'rozet amber') +
        '<span class="ad">Ücretsiz üye ol<small>30 soru, açıklamalar ve karnen açılır; kart istenmez</small></span>' + OK + '</button>' +
        '<button type="button" class="srt" data-git="giris">' + ik('giris', 'rozet') +
        '<span class="ad">Hesabım var, giriş yap<small>Paketindeki dersler açılır</small></span>' + OK + '</button></div>';
    }
    bugunB.innerHTML = html;
    tekrarBagla(bugunB);
    [].forEach.call(bugunB.querySelectorAll('[data-git]'), function (g) {
      g.onclick = function () { if (window.TTGiris) window.TTGiris.ac(g.dataset.git === 'uyeol' ? 'uye' : 'giris'); };
    });
    [].forEach.call(bugunB.querySelectorAll('[data-sinav]'), function (b) {
      b.onclick = function () { if (window.TTSinavlar) window.TTSinavlar.ac(b.dataset.sinav); };
    });
    try { document.dispatchEvent(new CustomEvent('tt-acilis', { detail: paketsiz() ? 'ucretsiz' : 'bugun' })); } catch (e) {}
  }

  /* ---------- GÖRÜNMEZ TEKRAR (26.09 Cem "2 ve 3 yap"; kurallar TEKRAR-KURALLARI yorumunda) ----------
     K1 Yanlış cevaplanan soru, cevaptan en az 20 saat sonra "tekrar zamanı gelmiş" sayılır (dün ve öncesi).
     K2 Tekrarda doğru yapılırsa kayıt "ok" olur, kuyruktan kendiliğinden çıkar; yine yanlışsa zamanı sıfırlanır, ertesi gün yine gelir.
     K3 Sıradaki listesinin en üstünde tek satır: en çok bekleyen dersin tekrarı, dokununca YALNIZ o sorular açılır.
     K4 Yalnız erişilebilen sorular (ücretsiz ya da paketinde açık ders); seçili sınav dışındakiler sayılmaz.
     K5 Satırda o soruların en sık tuzağı yazılır ("En çok: … Tuzağı"). Kullanıcıya "yapay zekâ" vb. hiçbir şey söylenmez.
     Veri: yalnız cihazdaki/hesaptaki cevap kaydı (ilerleme.js). Sunucuya bir şey gönderilmez. */
  var TEKRAR_SAAT = 20;
  function tekrarKuyrugu() {
    var v = IL.veri(), sinir = Date.now() - TEKRAR_SAAT * 3600e3, sec = seciliSinav(), m = {};
    for (var s in v.cevap) {
      var c = v.cevap[s];
      if (!c || c.s === 'ok' || !c.yol || c.t > sinir || sinaviNe(c.yol) !== sec || !acikMi(c.yol)) continue;
      var g = m[c.yol] || (m[c.yol] = { yol: c.yol, ad: c.d || sayfaAdi(c.yol), yanlar: [], tz: {} });
      g.yanlar.push(s); if (c.tz) g.tz[c.tz] = (g.tz[c.tz] || 0) + 1;
    }
    var l = Object.keys(m).map(function (k) { return m[k]; }).sort(function (a, b) { return b.yanlar.length - a.yanlar.length; });
    return { toplam: l.reduce(function (a, g) { return a + g.yanlar.length; }, 0), ilk: l[0] || null };
  }
  function tekrarSatiri() {
    var q = tekrarKuyrugu(); if (!q.ilk) return '';
    var tz = Object.keys(q.ilk.tz).sort(function (a, b) { return q.ilk.tz[b] - q.ilk.tz[a]; })[0];
    return '<button type="button" class="srt" data-tekrar="1">' + ik('tekrar') + '<span class="ad">Tekrar zamanı · ' + q.ilk.yanlar.length + ' soru<small>' +
      esc(q.ilk.ad) + (tz ? ' · en çok: ' + esc(tz) : ' · dün ve önce yanlış yaptıkların') + '</small></span>' +
      (q.toplam > q.ilk.yanlar.length ? '<span class="sag">toplam ' + q.toplam + '</span>' : '') + OK + '</button>';
  }
  function tekrarBagla(kok) {
    var b = kok.querySelector('[data-tekrar]'); if (!b) return;
    b.onclick = function () { var q = tekrarKuyrugu(); if (q.ilk) yanlislariCoz(q.ilk); };
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
    var sec = seciliSinav();
    for (var s in v.cevap) { var c = v.cevap[s]; if (c && c.yol && sinaviNe(c.yol) === sec) { var r = Object.create(c); r.sid = s; r.ders = c.d || sayfaAdi(c.yol); l.push(r); } }
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
    var l = kayitlar(), html = '<div class="bant"><span class="etk">' + esc(SINAV_AD[seciliSinav()]) + '</span><h1>Karnem</h1></div>';
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
      b.onclick = function () {
        var s = IL.veri().ayar.sinav === 'sgs' ? 'sgs' : 'yeterlilik';
        if (window.TTOdeme && window.TTOdeme.ac(s)) return;
        if (window.TTSinavlar) window.TTSinavlar.ac(s);
      };
    });
  }

  function ciz() { bugunCiz(); karneCiz(); }

  /* ilk açılış: karşılama (nasıl öğrettiğimiz) → sınav → günlük hedef → hatırlatıcı */
  function kurulum() {
    var a0 = IL.veri().ayar, yalnizSinav = !!a0.kurulum && !a0.sinav;
    if (a0.kurulum && a0.sinav) return;
    var e = document.createElement('div'); e.id = 'kurulum'; document.body.appendChild(e);
    if (window.TTGorunum) window.TTGorunum.cubuk();
    var bitir = function () { IL.ayarYaz({ kurulum: true }); e.remove(); ciz(); if (window.TTSinavlar) window.TTSinavlar.ciz(); if (window.TTGorunum) window.TTGorunum.cubuk(); };
    var toplamAdim = yalnizSinav ? 1 : 3;
    var bant = function (n, baslik, alt) {
      return '<div class="kB"><div class="kMarka"><span>' + LOGO + '</span>' + (n ? '<em>0' + n + ' / 0' + toplamAdim + '</em>' : '') + '</div>' +
        '<h1>' + baslik + '</h1><p>' + alt + '</p></div>';
    };
    var secenek = function (v, ad, alt) { return '<button type="button" class="srt" data-v="' + v + '"><span class="ad">' + ad + '<small>' + alt + '</small></span>' + OK + '</button>'; };
    var sinavKarti = function (v, mono, ad, alt, kapali) {
      return '<button type="button" class="sinavKart" ' + (kapali ? 'disabled' : 'data-v="' + v + '"') + '><span class="mono">' + mono + '</span>' +
        '<span class="ad">' + ad + '<small>' + alt + '</small></span>' + (kapali ? '<span class="etiketK">Hazırlanıyor</span>' : OK) + '</button>';
    };
    /* 0) karşılama: ürünün kendisi — gerçek bir soru, yanlış şık, tuzağın adı, kural (katalog.tanitim, vitrin sorusu) */
    var karsilama = function () {
      var o = K.tanitim, ornek = '';
      if (o) ornek = '<div class="ornek"><div class="oUst">Gerçek bir soru · ' + esc(o.d) + '</div><div class="oSoru">' + esc(o.s) + '</div>' +
        '<div class="oSik"><b>' + esc(o.h) + '</b><span>' + esc(o.k) + '</span><small>Senin cevabın</small></div>' +
        '<div class="oTuzak">' + esc(o.tz) + '</div><div class="oKural"><b>Doğrusu:</b> ' + esc(o.kural) + '</div></div>';
      e.innerHTML = bant(0, 'Yanlışını böyle öğrenirsin.', 'Staja giriş ve yeterlilik sınavlarına, her yanlışın nedenini öğrenerek hazırlan.') +
        '<div class="kIc">' + ornek + '<div class="adimlar">' +
        '<div><span class="no">1</span><span><b>Gerçek sınav kalıbında çöz</b><span>Çıkmış sınavlara göre hazırlanmış sorular; her soruda konunun kaç dönemde sorulduğu.</span></span></div>' +
        '<div><span class="no">2</span><span><b>Tuzağını gör</b><span>Yanlış şıkkın hangi tuzaktan geldiği, doğrusu ve dayandığı kanun maddesi, anında.</span></span></div>' +
        '<div><span class="no">3</span><span><b>Karnende ölç</b><span>Hangi derste ve hangi tuzakta takıldığını gör; zayıf yerine çalış.</span></span></div>' +
        '</div></div><div class="kAlt"><button type="button" class="ana">Başla</button></div>';
      e.querySelector('.kAlt .ana').onclick = adim1;
    };
    var adim1 = function () {
      e.scrollTop = 0;
      e.innerHTML = bant(1, 'Hangi sınava hazırlanıyorsun?', 'Uygulama yalnız seçtiğin sınavı gösterir. İstediğin zaman üstteki sınav düğmesinden değiştirirsin.') +
        '<div class="kIc"><div class="secim">' + sinavKarti('sgs', 'SGS', 'SGS · Staja Giriş', 'Staja başlamak için giriş sınavı') +
        sinavKarti('yeterlilik', 'YET', 'SMMM Yeterlilik (Bitirme)', 'Staj bitirme · 8 ders') +
        sinavKarti('', 'KGK', 'KGK Bağımsız Denetçilik', '', true) + '</div>' +
        '<p class="kNot">Her sınavda 30 soru ücretsiz; ilk 3 soru için hesap bile gerekmez.</p></div>';
      [].forEach.call(e.querySelectorAll('[data-v]'), function (b) {
        b.onclick = function () {
          IL.ayarYaz({ sinav: b.dataset.v }); try { sessionStorage.removeItem('tt_uyg_sinavsec'); } catch (x) {}
          try { document.dispatchEvent(new CustomEvent('tt-sinav', { detail: b.dataset.v })); } catch (x) {}
          if (yalnizSinav) bitir(); else adim2();
        };
      });
    };
    /* 27.09: tempo KARTLARI (süre dürüst: sınav temposu soru başına ~90 sn — kısa sınavla aynı) */
    var adim2 = function () {
      e.scrollTop = 0;
      e.innerHTML = bant(2, 'Günlük temponu seç', 'Hedefini tuttuğun her gün serin bir artar. Az ama her gün, çok ama arada bir çalışmaktan iyidir.') +
        '<div class="kIc"><div class="tempo">' + TEMPO.map(function (x) {
          return '<button type="button" class="tKart' + (x[0] === 20 ? ' oneri' : '') + '" data-v="' + x[0] + '">' + (x[0] === 20 ? '<span class="tRozet">Önerilen</span>' : '') +
            '<b>' + x[0] + '<small> soru/gün</small></b><span>' + x[1] + '</span><em>' + x[2] + '</em></button>';
        }).join('') + '</div></div>';
      [].forEach.call(e.querySelectorAll('.tKart'), function (b) { b.onclick = function () { if (window.TTHis) window.TTHis.hafif(); IL.ayarYaz({ hedef: +b.dataset.v }); adim3(); }; });
    };
    /* 27.09: hatırlatma saati hızlı seçim kapsülleri; "Planımı oluştur" hatırlatıcıyı o saate kurar */
    var adim3 = function () {
      var yerel = !!(window.Capacitor && window.Capacitor.isNativePlatform && window.Capacitor.isNativePlatform());
      if (!yerel || !$('hatAcik')) return bitir();
      e.scrollTop = 0;
      var secili = '20:00';
      e.innerHTML = bant(3, 'Seni ne zaman çağıralım?', 'Her gün seçtiğin saatte kısa bir bildirim. Sonra Hesap’tan değiştirebilirsin.') +
        '<div class="kIc"><div class="saatler">' + [['08:30', 'Sabah kahvesi'], ['12:30', 'Öğle arası'], ['20:00', 'Mesai sonrası']].map(function (x) {
          return '<button type="button" class="sKart" data-v="' + x[0] + '" aria-pressed="' + (x[0] === secili) + '"><b>' + x[0] + '</b><span>' + x[1] + '</span></button>';
        }).join('') + '</div><button type="button" class="duz hic">Hatırlatma istemiyorum</button></div>' +
        '<div class="kAlt"><button type="button" class="ana">Planımı oluştur ve başla</button></div>';
      [].forEach.call(e.querySelectorAll('.sKart'), function (b) {
        b.onclick = function () { secili = b.dataset.v; [].forEach.call(e.querySelectorAll('.sKart'), function (x) { x.setAttribute('aria-pressed', x === b); }); if (window.TTHis) window.TTHis.hafif(); };
      });
      e.querySelector('.hic').onclick = bitir;
      e.querySelector('.kAlt .ana').onclick = function () {
        $('hatSaat').value = secili;
        if (!$('hatAcik').checked) $('hatAcik').click(); else $('hatSaat').dispatchEvent(new Event('change'));
        bitir();
      };
    };
    if (yalnizSinav) adim1(); else karsilama();
  }

  /* Hesap sekmesi: çalışma ayarları (ilk açılışta "sonra değiştirebilirsin" denen yer) */
  var ayarB = document.createElement('section');
  ayarB.id = 'calismaAyar'; ayarB.className = 'bolum'; ayarB.setAttribute('data-sekme', 'hesap');
  /* 27.09 Cem: "standart açılır kutular web formu gibi" → sınav satırı (alttan pencere), tempo kapsülleri, görünüm seçici */
  ayarB.innerHTML = '<span class="etk">Çalışma</span><div class="satirlar">' +
    '<button type="button" class="srt" id="ayarSinavSatir">' + ik('sinav') + '<span class="ad">Sınavım<small id="ayarSinavAd"></small></span><span class="sag">Değiştir</span>' + OK + '</button></div>' +
    '<div class="kart ayarKart"><span class="aBas">Günlük hedef</span><div class="kapsuller" id="ayarHedef">' +
    TEMPO.map(function (x) { return '<button type="button" data-v="' + x[0] + '">' + x[0] + '<small>soru</small></button>'; }).join('') + '</div>' +
    '<span class="aNot" id="ayarHedefNot"></span>' +
    '<span class="aBas" style="margin-top:18px">Görünüm</span><div class="segment ucP" id="ayarGorunum">' +
    '<button type="button" data-v="acik">' + ik('gunes') + 'Açık</button><button type="button" data-v="koyu">' + ik('ay') + 'Koyu</button>' +
    '<button type="button" data-v="sistem">' + ik('telefon') + 'Otomatik</button></div></div>';
  $('hatirlatici').parentNode.insertBefore(ayarB, $('hatirlatici'));
  var ADLAR = { sgs: 'SGS · Staja Giriş', yeterlilik: 'SMMM Yeterlilik (Bitirme)' };
  function ayarOku() {
    var a = IL.veri().ayar, h = a.hedef || 10;
    $('ayarSinavAd').textContent = ADLAR[a.sinav === 'sgs' ? 'sgs' : 'yeterlilik'];
    [].forEach.call($('ayarHedef').children, function (b) { b.setAttribute('aria-pressed', +b.dataset.v === h); });
    var tp = TEMPO.filter(function (x) { return x[0] === h; })[0];
    $('ayarHedefNot').textContent = tp ? tp[1] + ' · ' + tp[2].toLowerCase() : h + ' soru/gün';
    var g = window.TTGorunum ? window.TTGorunum.deger() : 'acik';
    [].forEach.call($('ayarGorunum').children, function (b) { b.setAttribute('aria-pressed', b.dataset.v === g); });
  }
  ayarOku();
  $('ayarSinavSatir').onclick = function () { if (window.TTSinavSec) window.TTSinavSec.ac(); };
  [].forEach.call($('ayarHedef').children, function (b) {
    b.onclick = function () { if (window.TTHis) window.TTHis.hafif(); IL.ayarYaz({ hedef: +b.dataset.v }); ayarOku(); ciz(); };
  });
  [].forEach.call($('ayarGorunum').children, function (b) {
    b.onclick = function () {
      if (window.TTHis) window.TTHis.hafif();
      try { localStorage.setItem('tt_gorunum', b.dataset.v); } catch (e) {}
      if (window.TTGorunum) { document.documentElement.setAttribute('data-gorunum', window.TTGorunum.koyu() ? 'koyu' : 'acik'); window.TTGorunum.cubuk(); }
      ayarOku();
    };
  });
  if (window.TTGorunum) window.TTGorunum.cubuk();

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

  /* ÜST ŞERİTTE SINAV DÜĞMESİ (26.09): uygulama tek sınava odaklı; değiştirmek tek dokunuş */
  var cip = document.createElement('button');
  cip.type = 'button'; cip.id = 'sinavCip'; cip.setAttribute('aria-label', 'Sınavı değiştir');
  var ust = document.querySelector('header.ust'); if (ust) ust.insertBefore(cip, $('durumRozet'));
  function cipCiz() { cip.innerHTML = (seciliSinav() === 'sgs' ? 'SGS' : 'Yeterlilik') + '<svg class="ik" aria-hidden="true"><use href="#i-ok"/></svg>'; }
  function sinavSecAc() {
    var e = document.createElement('div'); e.id = 'sinavSec'; e.setAttribute('role', 'dialog');
    var sec = seciliSinav(), sat = function (id, ad, alt) {
      return '<button type="button" class="srt" data-v="' + id + '"><span class="ad">' + ad + '<small>' + alt + '</small></span>' +
        (id === sec ? '<span class="etiketK acik">Seçili</span>' : OK) + '</button>';
    };
    e.innerHTML = '<div class="ic"><span class="etk">Sınavın</span><div class="satirlar">' + sat('sgs', 'SGS · Staja Giriş', 'Staja başlamak için giriş sınavı') +
      sat('yeterlilik', 'SMMM Yeterlilik (Bitirme)', 'Staj bitirme · 8 ders') +
      '<div class="srt kilit"><span class="ad">KGK Bağımsız Denetçilik<small>Hazırlanıyor</small></span></div></div>' +
      '<button type="button" class="duz kapat">Kapat</button></div>';
    document.body.appendChild(e);
    e.onclick = function (ev) { if (ev.target === e || ev.target.classList.contains('kapat')) e.remove(); };
    [].forEach.call(e.querySelectorAll('[data-v]'), function (b) {
      b.onclick = function () {
        IL.ayarYaz({ sinav: b.dataset.v }); e.remove();
        try { document.dispatchEvent(new CustomEvent('tt-sinav', { detail: b.dataset.v })); } catch (x) {}
      };
    });
  }
  cip.onclick = sinavSecAc;
  window.TTSinavSec = { ac: sinavSecAc };
  document.addEventListener('tt-sinav', cipCiz);
  cipCiz();

  ciz();
  kurulum();
  /* giriş durumu değişince (uygulama.js) "devam et / giriş yap" uygunluğu değişir; oturum yeni açılmış olabilir */
  document.addEventListener('tt-durum', function () { ciz(); esitle(); });
  document.addEventListener('tt-sinav', function () { ayarOku(); ciz(); });
  /* eski kurulumdaki 40 soru hedefi: kapsüllerde yok → en yakın 50'ye değil, olduğu gibi kalır; not satırı "40 soru/gün" yazar */
  document.addEventListener('visibilitychange', function () { if (!document.hidden) { ciz(); esitle(); } });
  window.addEventListener('pageshow', function () { ciz(); esitle(); });
})();
