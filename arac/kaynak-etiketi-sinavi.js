#!/usr/bin/env node
/* KAYNAK ETİKETİ ÖZ-SINAVI (08.10.2026) — menu.js'teki KAYNAK-ETIKETI bloğunu GERÇEK kaynaktan çıkarır,
   sahte tarayıcıda (location / localStorage / sessionStorage / fetch) koşturur.
   Ölçtüğü: etiketsiz gelende HİÇ istek gitmemesi · ?k= süzgeci (biçim, uzunluk, Türkçe harf, HTML) · oturumda
   etiket başına 1 ziyaret · testin yalnız etiketliyse ve oturumda 1 kez · üyeliğin yalnız ≤ 2 gün hesapla, cihazda
   hesap başına 1 kez, oturum jetonuyla gitmesi · 30 gün ömrü · depolama kapalıyken çökmemesi · istemci deseni ile
   SQL göçündeki desenin aynı olması.
   Mutasyon: KE_MUTASYON=<ad> bloğun bir koşulunu bozar; her bozmada sınav KIRMIZI düşmelidir.
     node arac/kaynak-etiketi-sinavi.js            → sınav
     node arac/kaynak-etiketi-sinavi.js --mutasyon → her mutasyonu ayrı koşar, hepsi KIRMIZI değilse çıkış 1
   🚫 GÖRMEZ: sunucu tarafı (o ayrı: arac/kaynak-sayac-sinavi.sh, gerçek Postgres) · gerçek tarayıcının keepalive/CSP
   davranışı · sayfaların ttKaynak'ı doğru yerde çağırması (yalnız varlığına grep ile bakar). */
'use strict';
const fs = require('fs'), path = require('path'), vm = require('vm');
const KOK = path.join(__dirname, '..');

const MUTASYONLAR = {
  desen:     ["DESEN=/^[a-z0-9][a-z0-9_-]{0,31}$/", "DESEN=/^[\\s\\S]+$/"],
  etiketsiz: ["if(gelen){", "if(true){"],
  oturum:    ["if(!sayildi('ziyaret:'+gelen)) ", ""],
  omur:      ["Date.now()-x.t<OMUR", "true"],
  hesap:     ["if(!(Date.now()-acilis<HESAP_GUN*86400000)) return;", ""],
  tur:       ["tur!=='test'||", ""],
  uyetek:    ["if(localStorage.getItem(AD+'_uye')===id) return;", ""],
  jeton:     ["if(jeton) h.Authorization='Bearer '+jeton;", ""],
};

function blokOku() {
  const s = fs.readFileSync(path.join(KOK, 'menu.js'), 'utf8');
  const a = s.indexOf('/* ==== KAYNAK-ETIKETI-BASI'), b = s.indexOf('/* ==== KAYNAK-ETIKETI-SONU ==== */');
  if (a < 0 || b < 0 || b < a) throw new Error('menu.js KAYNAK-ETIKETI işaretleri bulunamadı');
  let blok = s.slice(a, b);
  const m = process.env.KE_MUTASYON;
  if (m) {
    const r = MUTASYONLAR[m]; if (!r) throw new Error('bilinmeyen mutasyon ' + m);
    if (blok.indexOf(r[0]) < 0) throw new Error('mutasyon hedefi kaynakta yok (sınav bayat): ' + m);
    blok = blok.split(r[0]).join(r[1]);
  }
  return blok;
}

function depo(atar) {
  const v = {};
  const d = {
    getItem(k) { if (atar) throw new Error('kapali'); return Object.prototype.hasOwnProperty.call(v, k) ? v[k] : null; },
    setItem(k, x) { if (atar) throw new Error('kapali'); v[k] = String(x); },
    removeItem(k) { delete v[k]; },
  };
  return new Proxy(d, {   /* Object.keys(localStorage) tarayıcıdaki gibi anahtarları versin */
    ownKeys() { if (atar) throw new Error('kapali'); return Object.keys(v); },
    getOwnPropertyDescriptor(t, k) { return Object.prototype.hasOwnProperty.call(v, k) ? { value: v[k], enumerable: true, configurable: true } : undefined; },
    get(t, k) { return t[k]; },
  });
}

function kos(blok, o) {
  const istekler = [];
  const pencere = {};
  const ortam = {
    window: pencere, location: { search: o.search || '' },
    localStorage: o.ls, sessionStorage: o.ss, URLSearchParams, JSON, Date: o.Date || Date, Object, String, Promise,
    fetch: (url, ayar) => { istekler.push({ url, ayar, govde: JSON.parse(ayar.body) });
      return o.fetchHata ? Promise.reject(new Error('ag')) : Promise.resolve({ ok: true, json: () => Promise.resolve(true) }); },
  };
  vm.runInNewContext(blok, ortam);
  return { ke: pencere.ttKaynak, istekler };
}
const bekle = () => new Promise(r => setImmediate(r));

async function sinav() {
  const blok = blokOku();
  const sonuc = []; let dus = 0;
  const vaka = (ad, kosul) => { sonuc.push((kosul ? 'GEÇTİ ' : 'DÜŞTÜ ') + ad); if (!kosul) dus++; };
  const yeniOturum = (ls) => ({ ls: ls || depo(), ss: depo() });
  const etiketDegeri = (ls) => { try { return JSON.parse(ls.getItem('tt_kaynak') || 'null'); } catch (e) { return null; } };

  // 1) etiketsiz: hiçbir istek, hiçbir kayıt
  { const o = yeniOturum(); const r = kos(blok, { ...o, search: '' });
    r.ke.olay('test'); o.ls.setItem('sb-x-auth-token', JSON.stringify({ access_token: 'J', user: { id: 'u1', created_at: new Date().toISOString() } })); r.ke.uye();
    vaka('etiketsiz gelen: 0 istek', r.istekler.length === 0);
    vaka('etiketsiz gelen: cihaza etiket yazılmaz', etiketDegeri(o.ls) === null);
    const r2 = kos(blok, { ...o, search: '?x=1&ref=abc' });
    vaka('ilgisiz parametre: 0 istek', r2.istekler.length === 0); }

  // 2) ?k=deneme → 1 ziyaret; aynı oturumda yeniden açılınca 0
  const ls = depo(); const ss = depo();
  { const r = kos(blok, { ls, ss, search: '?k=deneme' });
    vaka('?k=deneme: tek ziyaret isteği', r.istekler.length === 1 && /\/rpc\/kaynak_say$/.test(r.istekler[0].url)
      && r.istekler[0].govde.p_etiket === 'deneme' && r.istekler[0].govde.p_olay === 'ziyaret');
    vaka('ziyaret isteği oturum jetonu taşımaz', r.istekler.length === 1 && !r.istekler[0].ayar.headers.Authorization);
    vaka('?k=deneme: cihaza yazıldı', (etiketDegeri(ls) || {}).k === 'deneme');
    const r2 = kos(blok, { ls, ss, search: '?k=deneme' });
    vaka('aynı oturumda ikinci açılış: 0 ziyaret', r2.istekler.length === 0);
    r2.ke.olay('test'); r2.ke.olay('test');
    vaka('test başladı: oturumda 1 kez, etiketle', r2.istekler.length === 1 && r2.istekler[0].govde.p_olay === 'test' && r2.istekler[0].govde.p_etiket === 'deneme');
    r2.ke.olay('uye'); r2.ke.olay('ziyaret'); r2.ke.olay('sil');
    vaka('olay() yalnız test gönderir', r2.istekler.length === 1); }

  // 3) yeni oturum, linksiz sayfa: ziyaret yok ama test etiketi hatırlanır
  { const r = kos(blok, { ls, ss: depo(), search: '' });
    vaka('linksiz sonraki oturum: ziyaret yok', r.istekler.length === 0);
    r.ke.olay('test');
    vaka('linksiz sonraki oturum: test etiketle gider', r.istekler.length === 1 && r.istekler[0].govde.p_etiket === 'deneme'); }

  // 4) süzgeç
  const suzgec = [['?k=%3Cscript%3E', null], ['?k=' + 'a'.repeat(33), null], ['?k=' + 'a'.repeat(32), 'a'.repeat(32)],
    ['?k=%C3%B6%C4%9Frenci', null], ['?k=', null], ['?k=-tire', null], ['?k=%20Grup-WhatsApp%20', 'grup-whatsapp'],
    ['?k=grup_fb-2', 'grup_fb-2'], ['?utm_source=instagram', 'instagram'], ['?k=k%C3%B6t%C3%BC&utm_source=ig', 'ig'],
    ['?k=a%20b', null], ['?k=x%27%3Bdrop', null]];
  for (const [s, bek] of suzgec) {
    const r = kos(blok, { ls: depo(), ss: depo(), search: s });
    const giden = r.istekler.length ? r.istekler[0].govde.p_etiket : null;
    vaka('süzgeç ' + s + ' → ' + bek, giden === bek && r.istekler.length === (bek ? 1 : 0));
  }

  // 5) üyelik
  const simdi = Date.now();
  const oturumYaz = (l, gunOnce, ekstra) => l.setItem('sb-proje-auth-token', JSON.stringify(Object.assign({ access_token: 'JETON', expires_at: Math.floor(simdi / 1000) + 3600,
    user: { id: 'uye-1', created_at: new Date(simdi - gunOnce * 86400000).toISOString() } }, ekstra || {})));
  { const l = depo(); kos(blok, { ls: l, ss: depo(), search: '?k=deneme' }); oturumYaz(l, 0);
    const r = kos(blok, { ls: l, ss: depo(), search: '' });   // menu.js açılışta uye() çağırır
    vaka('yeni hesap + etiket: kaynak_uye 1 istek', r.istekler.length === 1 && /\/rpc\/kaynak_uye$/.test(r.istekler[0].url) && r.istekler[0].govde.p_etiket === 'deneme');
    vaka('kaynak_uye oturum jetonuyla', r.istekler.length === 1 && r.istekler[0].ayar.headers.Authorization === 'Bearer JETON');
    r.ke.uye();
    vaka('aynı sayfada ikinci uye(): 0', r.istekler.length === 1);
    await bekle(); await bekle();
    const r2 = kos(blok, { ls: l, ss: depo(), search: '' });
    vaka('sonraki sayfa: aynı hesap tekrar gönderilmez', r2.istekler.length === 0); }
  { const l = depo(); kos(blok, { ls: l, ss: depo(), search: '?k=deneme' }); oturumYaz(l, 3);
    const r = kos(blok, { ls: l, ss: depo(), search: '' });
    vaka('3 günlük hesap: üyelik gönderilmez', r.istekler.length === 0); }
  { const l = depo(); oturumYaz(l, 0);
    const r = kos(blok, { ls: l, ss: depo(), search: '' });
    vaka('etiketsiz yeni hesap: üyelik gönderilmez', r.istekler.length === 0); }
  { const l = depo(); kos(blok, { ls: l, ss: depo(), search: '?k=deneme' }); oturumYaz(l, 0, { expires_at: Math.floor(simdi / 1000) - 60 });
    const r = kos(blok, { ls: l, ss: depo(), search: '' });
    vaka('süresi dolmuş jeton: gönderilmez', r.istekler.length === 0); }
  { const l = depo(); kos(blok, { ls: l, ss: depo(), search: '?k=deneme' }); oturumYaz(l, 0);
    const r = kos(blok, { ls: l, ss: depo(), search: '', fetchHata: true });
    await bekle(); await bekle();
    const r2 = kos(blok, { ls: l, ss: depo(), search: '' });
    vaka('ağ hatasında üyelik sonraki sayfada yeniden dener', r.istekler.length === 1 && r2.istekler.length === 1); }

  // 6) 30 gün ömrü
  { const l = depo(); l.setItem('tt_kaynak', JSON.stringify({ k: 'eski', t: simdi - 31 * 86400000 }));
    const r = kos(blok, { ls: l, ss: depo(), search: '' }); r.ke.olay('test');
    vaka('31 günlük etiket: test gönderilmez', r.istekler.length === 0);
    l.setItem('tt_kaynak', JSON.stringify({ k: 'yeni', t: simdi - 29 * 86400000 }));
    const r2 = kos(blok, { ls: l, ss: depo(), search: '' }); r2.ke.olay('test');
    vaka('29 günlük etiket: test gider', r2.istekler.length === 1 && r2.istekler[0].govde.p_etiket === 'yeni');
    l.setItem('tt_kaynak', JSON.stringify({ k: '<b>', t: simdi }));
    const r3 = kos(blok, { ls: l, ss: depo(), search: '' }); r3.ke.olay('test');
    vaka('cihazdaki bozuk etiket kullanılmaz', r3.istekler.length === 0); }

  // 7) depolama kapalı: çökme yok, ziyaret yine 1
  { let r, hata = null;
    try { r = kos(blok, { ls: depo(true), ss: depo(true), search: '?k=deneme' }); r.ke.olay('test'); r.ke.uye(); } catch (e) { hata = e; }
    vaka('depolama kapalı: çökmez', !hata);
    vaka('depolama kapalı: ziyaret 1, test (etiket okunamaz) 0', !!r && r.istekler.length === 1 && r.istekler[0].govde.p_olay === 'ziyaret'); }
  { let hata = null; try { const r = kos(blok, { ls: depo(), ss: depo(), search: '?k=deneme', fetchHata: true }); await bekle(); } catch (e) { hata = e; }
    vaka('ağ hatası: çökmez', !hata); }

  // 8) istemci deseni = SQL deseni; sayfalar çağırıyor
  { const sqlAd = fs.readdirSync(path.join(KOK, 'radar-app/sql')).filter(f => /kaynak-sayac\.sql$/.test(f))[0];
    const sql = sqlAd ? fs.readFileSync(path.join(KOK, 'radar-app/sql', sqlAd), 'utf8') : '';
    const js = (/DESEN=\/(.+?)\/,/.exec(fs.readFileSync(path.join(KOK, 'menu.js'), 'utf8')) || [])[1];
    const sqlDesen = sql.match(/'\^\[a-z0-9\]\[a-z0-9_-\]\{0,31\}\$'/g) || [];
    vaka('JS deseni SQL deseniyle aynı (RPC ×2 + CHECK)', js === '^[a-z0-9][a-z0-9_-]{0,31}$' && sqlDesen.length >= 3);
    vaka('seviye-testi.html test başlangıcını bildiriyor', /ttKaynak\.olay\('test'\)/.test(fs.readFileSync(path.join(KOK, 'seviye-testi.html'), 'utf8')));
    vaka('ogrenci.html üyeliği bildiriyor', /ttKaynak\.uye\(\)/.test(fs.readFileSync(path.join(KOK, 'ogrenci.html'), 'utf8')));
    vaka('yonetim.html tabloyu okuyor', /rpc\('yonetim_kaynak'/.test(fs.readFileSync(path.join(KOK, 'yonetim.html'), 'utf8'))); }

  return { sonuc, dus };
}

(async () => {
  if (process.argv.includes('--mutasyon')) {
    const { execFileSync } = require('child_process');
    let kacan = 0; const ad = Object.keys(MUTASYONLAR);
    for (const m of ad) {
      let kirmizi = false;
      try { execFileSync(process.execPath, [__filename], { env: { ...process.env, KE_MUTASYON: m }, stdio: 'pipe' }); } catch (e) { kirmizi = e.status === 1; }
      console.log((kirmizi ? 'KIRMIZI (doğru) ' : 'YEŞİL KALDI (sınav kör) ') + m);
      if (!kirmizi) kacan++;
    }
    console.log(`MUTASYON: ${ad.length - kacan}/${ad.length} KIRMIZI`);
    process.exit(kacan ? 1 : 0);
  }
  const { sonuc, dus } = await sinav();
  sonuc.forEach(s => console.log(s));
  console.log(`KAYNAK ETİKETİ ÖZ-SINAVI: ${sonuc.length - dus}/${sonuc.length}` + (process.env.KE_MUTASYON ? ' (mutasyon ' + process.env.KE_MUTASYON + ')' : ''));
  process.exit(dus ? 1 : 0);
})().catch(e => { console.error('SINAV HATASI: ' + e.message); process.exit(2); });
