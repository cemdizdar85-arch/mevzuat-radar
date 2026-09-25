// arac/yuk/kalabalik.js — CANLI DENEME YUK TESTI: bir makinede N gercek tarayici (24.09.2026, Cem "evet 1000 tarayici testini kur")
//
// Akis (.github/workflows/yuk-testi-1000.yml): 20 makine x 50 tarayici = 1.000 gercek tarayici, 20 ayri IP.
// Her makine sayfayi KENDI yerel sunucusundan sunar (canli siteye / takvime dokunulmaz), ama yuk GERCEK
// Supabase'e biner: uyelik (Auth), anahtar (Storage), sonuc (canli_sonuc).
// Her sanal kisi: ogrenci.html'den UYE OLUR -> canli-deneme.html'de kapiyi bekler -> 20 soru cevaplar ->
// her 4 kisiden biri sinav ortasinda sayfayi yeniler -> bitirir -> sonucun ulastigini ekranda dogrular.
//
// Paket: GERCEK SORU YOK. RUN kimliginden turetilen anahtarla sifrelenmis 93 uydurma soru. Anahtari kapi
// saatinde akisin 'kapi' isi Storage'a basar (ayni turetme). Stdout'a yalniz SAYI basilir (bulut guvenligi kurali 2).
// GORMEZ: 1.000 AYRI IP (yalniz makine sayisi kadar IP); gercek mobil ag/yavas cihaz; 120 dk'lik oturum (kisiler hemen bitirir).
'use strict';
const fs = require('fs'), path = require('path'), http = require('http'), crypto = require('crypto');

const E = process.env;
const NO = +E.NO || 1, KISI = +E.KISI || 50, KAPI_MS = +E.KAPI_MS, KOD = E.KOD, TARIH = E.TARIH, SAAT = E.SAAT;
const KAYIT_DK = +(E.KAYIT_DK || 10), RUN = E.RUN || 'yerel', KOK = path.resolve(E.KOK || path.join(__dirname, '..', '..'));
const KAYIT = E.KAYIT !== '0', PORT = +(E.PORT || 8080);
if (!KAPI_MS || !KOD || !TARIH || !SAAT) { console.log('EKSIK ORTAM: KAPI_MS/KOD/TARIH/SAAT'); process.exit(2); }
if (!/^SGS-\d{4}$/.test(KOD)) { console.log('KOD bicimi beklenmedik: ' + KOD); process.exit(2); }

function anahtarUret(run) {
  return { anahtar: crypto.createHash('sha256').update('tetikte-yuk-' + run).digest(),
           iv: crypto.createHash('sha256').update('tetikte-yuk-iv-' + run).digest().subarray(0, 16) };
}
function paketYaz() {
  const { anahtar, iv } = anahtarUret(RUN);
  const sorular = [];
  for (let n = 1; n <= 93; n++) sorular.push({ id: 'yuk-' + n, ders: 'Yük testi', konu: 'test', soru: 'Yük testi sorusu ' + n + ' (gerçek soru değil)',
    siklar: { A: 'birinci', B: 'ikinci', C: 'üçüncü', D: 'dördüncü', E: 'beşinci' }, dogru: 'ABCDE'[n % 5], aciklama: { ['ABCDE'[n % 5]]: 'Test açıklaması.' } });
  const c = crypto.createCipheriv('aes-256-cbc', anahtar, iv);
  const veri = Buffer.concat([c.update(JSON.stringify({ sorular, sure_dk: 120 }), 'utf8'), c.final()]);
  fs.mkdirSync(path.join(KOK, 'veri', 'canli'), { recursive: true });
  fs.writeFileSync(path.join(KOK, 'veri', 'canli', KOD + '.enc.json'), JSON.stringify({ iv: iv.toString('base64'), veri: veri.toString('base64') }));
  // takvim YALNIZ bu makinenin kopyasinda; canli sitedeki veri/canli-deneme.json'a dokunulmaz
  // 24.09 kayit kesimi kurali: test oturumunda kesim KAPIDAN 1 DK ONCE (kayitlar kapi-90 sn'ye kadar biter)
  fs.writeFileSync(path.join(KOK, 'veri', 'canli-deneme.json'), JSON.stringify({ durum: 'kayit', oturumlar: [{ ad: 'Yük testi', sinav: 'SGS', tarih: TARIH, saat: SAAT, kayit_kesim: new Date(KAPI_MS - 60000).toISOString() }] }));
  if (E.YEREL_ANAHTAR === '1') fs.writeFileSync(path.join(KOK, 'veri', 'canli', 'anahtar-' + KOD + '.json'), JSON.stringify({ anahtar: anahtar.toString('base64') }));
}
const TUR = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.css': 'text/css', '.json': 'application/json', '.svg': 'image/svg+xml', '.png': 'image/png', '.ico': 'image/x-icon', '.woff2': 'font/woff2' };
function sunucu() {
  return http.createServer((q, s) => {
    let p = decodeURIComponent(q.url.split('?')[0]); if (p.endsWith('/')) p += 'index.html';
    const f = path.join(KOK, p); if (!f.startsWith(KOK)) { s.writeHead(403); return s.end(); }
    fs.readFile(f, (e, d) => { if (e) { s.writeHead(404); return s.end(); } s.writeHead(200, { 'Content-Type': TUR[path.extname(f)] || 'application/octet-stream', 'Cache-Control': 'no-store' }); s.end(d); });
  }).listen(PORT);
}
const bekle = ms => new Promise(r => setTimeout(r, Math.max(0, ms)));
const say = {}; const art = k => { say[k] = (say[k] || 0) + 1; };
const kayitMs = [], acilisSn = [], sonucSn = [], hataOrnek = {};
const acilisErken = [];

async function kisi(tarayici, i) {
  const mobil = i % 5 !== 0;
  const ctx = await tarayici.newContext({ viewport: mobil ? { width: 390, height: 800 } : { width: 1280, height: 800 }, timezoneId: 'Europe/Istanbul', locale: 'tr-TR' });
  const sayfa = await ctx.newPage();
  sayfa.on('dialog', d => d.accept().catch(() => {}));
  const U = 'http://127.0.0.1:' + PORT + '/';
  let asama = 'baslangic';
  // 24.09 kayit kesimi kontrol gruplari: kapi bu ikisinde KAPALI kalmali (canli-deneme.html katilabilir())
  const kayitsiz = KAYIT && i % 12 === 11;   // hic kaydolmayan
  const gecKayit = KAYIT && i % 12 === 10;   // kesimden (kapi-60 sn) SONRA kaydolan
  try {
    if (KAYIT && !kayitsiz) {
      asama = 'kayit';
      const sonKayit = KAPI_MS - 90000;
      const t = gecKayit ? KAPI_MS - 45000 + Math.random() * 5000
        : Date.now() + Math.min(i * (KAYIT_DK * 60000 / KISI) + Math.random() * 5000, Math.max(0, sonKayit - Date.now()));
      await bekle(t - Date.now());
      await sayfa.goto(U + 'ogrenci.html?kapi=tetikte2026&sonra=canli-deneme.html', { waitUntil: 'domcontentloaded', timeout: 60000 });
      await sayfa.fill('#ogEposta', 'yuktest-' + RUN + '-' + NO + '-' + i + '@tetikte.com');
      await sayfa.fill('#ogSifre', crypto.randomBytes(9).toString('base64'));
      await sayfa.check('#ogKosul');
      const t0 = Date.now();
      await sayfa.click('#ogKayit');
      const sonuc = await sayfa.waitForFunction(() => {
        for (let k = 0; k < localStorage.length; k++) if (/^sb-[a-z0-9]+-auth-token$/.test(localStorage.key(k))) return 'ok';
        const h = document.getElementById('ogHata'); return (h && h.textContent.trim()) ? 'hata:' + h.textContent.trim().slice(0, 60) : false;
      }, null, { timeout: 45000, polling: 250 }).then(h => h.jsonValue()).catch(() => 'zaman-asimi');
      if (sonuc === 'ok') { art('kayit_ok'); kayitMs.push(Date.now() - t0); }
      else if (sonuc === 'zaman-asimi') art('kayit_zaman_asimi');
      else { art(/yoğunluk|rate|limit|çok fazla|429|too many/i.test(sonuc) ? 'kayit_hiz_siniri' : 'kayit_hata'); if (!say['_ornek_' + sonuc]) { say['_ornek_' + sonuc] = 1; } }
    } else {
      await sayfa.goto(U + 'index.html?kapi=tetikte2026', { waitUntil: 'domcontentloaded', timeout: 60000 }).catch(() => {});
    }
    asama = 'salon';
    // 24.09 1. kosu: ogrenci.html kayittan sonra KENDISI canli-deneme.html'e gider (panel -> sonraGit ->
    // location.replace). Betik ayni anda goto yapinca iki gezinme carpisiyordu (22/1.008 'salon' hatasi,
    // 9 makineye dagilmis). Gercek kullanici tek yonlendirme yasar: once o beklenir, ustune gezinme yapilmaz.
    // 24.09 2. kosu: /canli-deneme\.html/ duz desen ogrenci.html'in '?sonra=canli-deneme.html' SORGUSUNA da
    // uyuyordu; kaydi reddedilen (yonlendirilmeyen) kisi kayit sayfasinda kaliyor, 'salon' hatasi sayiliyordu.
    // Artik yalniz YOL (pathname) bakilir.
    const sinavSayfasi = u => { try { return new URL(String(u)).pathname.endsWith('/canli-deneme.html'); } catch (e) { return false; } };
    if (KAYIT && !kayitsiz) await sayfa.waitForURL(u => sinavSayfasi(u), { timeout: 20000 }).catch(() => art('yonlendirme_gelmedi'));
    const gec = i % 6 === 5;   // her 6 kisiden biri kapidan 10-90 sn sonra girer
    if (gec) { await bekle(KAPI_MS + 10000 + Math.random() * 80000 - Date.now()); }
    if (gec || !sinavSayfasi(sayfa.url())) await sayfa.goto(U + 'canli-deneme.html', { waitUntil: 'domcontentloaded', timeout: 60000 });
    // sinav ekrani ACILDI mi, yoksa kayit kesimi kapisi KAPALI mi dedi
    const kapi = await sayfa.waitForFunction(() => {
      const e = document.getElementById('sinavEkran'); if (e && e.offsetParent !== null) return 'acik';
      const d = document.getElementById('salonDurum'); return (d && d.getAttribute('data-kapi') === 'kapali') ? 'kapali' : false;
    }, null, { timeout: Math.max(60000, KAPI_MS + 6 * 60000 - Date.now()), polling: 500 }).then(h => h.jsonValue());
    if (kayitsiz || gecKayit) {
      art(kapi === 'kapali' ? 'kapi_dogru_kapali' : 'kapi_HATALI_acildi');
      if (kapi === 'kapali') return;
    } else if (kapi === 'kapali') { art('kapi_HATALI_kapali'); return; }
    art('sinav_acildi'); acilisSn.push((Date.now() - KAPI_MS) / 1000); if (!gec) acilisErken.push((Date.now() - KAPI_MS) / 1000);
    asama = 'cevap';
    for (let j = 0; j < 20; j++) {
      const btn = sayfa.locator('#seSiklar button');
      const n = await btn.count(); if (n) await btn.nth(Math.floor(Math.random() * n)).click();
      await sayfa.click('#seIleri'); await bekle(150 + Math.random() * 500);
      if (j === 9 && i % 4 === 0) {
        asama = 'yenileme'; art('yenileme_deneme');
        const once = await sayfa.evaluate(k => Object.keys((JSON.parse(localStorage.getItem('canliDurum-' + k) || '{}').cevap) || {}).length, KOD);
        await sayfa.reload({ waitUntil: 'domcontentloaded' });
        await sayfa.waitForSelector('#sinavEkran', { state: 'visible', timeout: 90000 });
        const sonra = await sayfa.evaluate(k => Object.keys((JSON.parse(localStorage.getItem('canliDurum-' + k) || '{}').cevap) || {}).length, KOD);
        if (sonra >= once && once > 0) art('yenileme_ok'); else art('yenileme_kayip');
        asama = 'cevap';
      }
    }
    asama = 'bitir';
    await sayfa.click('#seBitir');
    await sayfa.waitForSelector('#sonucEkran', { state: 'visible', timeout: 30000 });
    if (KAYIT) { const kilit = await sayfa.locator('#soListe').innerHTML(); if (/🔒/.test(kilit)) art('uye_gorunum_kilitli'); else art('uye_gorunum_acik'); }
    asama = 'gonderim';
    const tg = Date.now();
    const g = await sayfa.waitForFunction(() => { const x = document.getElementById('soGonderim'); const t = x ? x.textContent : ''; return /✓/.test(t) ? 'ok' : (/gönderilemedi/.test(t) ? 'hata' : false); },
      null, { timeout: 240000, polling: 1000 }).then(h => h.jsonValue()).catch(() => 'zaman-asimi');
    art('sonuc_' + g); if (g === 'ok') sonucSn.push((Date.now() - tg) / 1000);
  } catch (e) {
    art('asama_hatasi_' + asama);
    // teshis: hata mesajinin basi + sayfadaki salon durum yazisi (kisisel veri/soru metni icermez)
    const durum = await sayfa.evaluate(() => { const d = document.getElementById('salonDurum'); return d ? d.textContent.trim().slice(0, 70) : '(salonDurum yok)'; }).catch(() => '(okunamadi)');
    const msj = String(e && e.message || e).split('\n')[0].replace(/https?:\/\/\S+/g, '<url>').slice(0, 90);
    const k = asama + ' | ' + msj + ' | ' + durum; hataOrnek[k] = (hataOrnek[k] || 0) + 1;
  } finally { await ctx.close().catch(() => {}); }
}

function ist(a) { if (!a.length) return null; const s = [...a].sort((x, y) => x - y); const q = p => s[Math.min(s.length - 1, Math.floor(p * s.length))]; return { n: s.length, min: +s[0].toFixed(1), p50: +q(0.5).toFixed(1), p95: +q(0.95).toFixed(1), max: +s[s.length - 1].toFixed(1) }; }

(async () => {
  paketYaz();
  const srv = sunucu();
  const { chromium } = require('playwright');
  const tarayici = await chromium.launch({ args: ['--disable-dev-shm-usage'] });
  console.log(`makine ${NO}: ${KISI} tarayici · kapi ${new Date(KAPI_MS).toISOString()} · kayit ${KAYIT ? KAYIT_DK + ' dk yayili' : 'KAPALI'}`);
  const is = [];
  for (let i = 0; i < KISI; i++) { is.push(kisi(tarayici, i)); await bekle(200); }
  await Promise.all(is);
  await tarayici.close(); srv.close();
  const ornek = Object.keys(say).filter(k => k.startsWith('_ornek_')).map(k => k.slice(7)); ornek.forEach(k => delete say['_ornek_' + k]);
  console.log('OZET ' + JSON.stringify({ makine: NO, kisi: KISI, say, kayit_ms: ist(kayitMs), acilis_sn: ist(acilisSn), acilis_erken_sn: ist(acilisErken), sonuc_sn: ist(sonucSn), kayit_hata_ornek: ornek.slice(0, 3), hata_ornek: hataOrnek }));
})().catch(e => { console.log('KALABALIK DUSTU: ' + e.message); process.exit(1); });
