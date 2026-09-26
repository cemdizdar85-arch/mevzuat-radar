#!/usr/bin/env node
/* hazirla-sinavi.js — mobil/hazirla.js KAPILARININ ÖZ-SINAVI (25.09.2026, dogrula.yml)
 *
 * Gerçek betik koşar (replika YASAK): her vaka geçici bir depo kökü kurar, `node mobil/hazirla.js
 * --kok <geçici>` çağırır, çıkış kodunu + ihlal satırını bekleneniyle kıyaslar.
 *   - YAKALAMASI gereken: gömülü soru, kabuk işareti yok, sızan "dogru", satış bağı, satış düğmesi,
 *     kasa-yukle yaması tutmadı, beklenmeyen kasa yolu.
 *   - YANLIŞ ALARM VERMEMESİ gereken: vitrinde cevaplı soru (bilinçli açık), soru metninde "fiyat"
 *     kelimesi, gerçek depo.
 * Ek eşdeğerlik ölçümleri (kopya kaymasın diye):
 *   - ortak.js kapsar() ile paket-kapisi.js kapsar() aynı paket×sınav tablosunda AYNI sonucu vermeli.
 *   - kasa-yukle.js'in kasa sorgusu ile uygulama.js'in "cihaza indir" sorgusu aynı biçimde kalmalı
 *     (çevrimdışı önbellek anahtarı adresle eşleşir; biçim kayarsa indirilen ders çevrimdışı açılmaz).
 *
 * Mutasyon (kural 8): `node mobil/hazirla-sinavi.js --mutasyon` her kapıyı hazirla.js içinde
 * HZ_MUTASYON ile bilerek kör eder; her körlükte bu sınav KIRMIZI düşmeli.
 *
 * BU SINAV ŞUNU GÖRMEZ: yerel (Android/iOS) derlemeyi, kasa RLS'ini, cihazda çalışmayı.
 */
'use strict';
const fs = require('fs');
const os = require('os');
const path = require('path');
const vm = require('vm');
const { spawnSync } = require('child_process');

const DEPO = path.resolve(__dirname, '..');
const HAZIRLA = path.join(__dirname, 'hazirla.js');

/* --------- mutasyon kipi: kendini her kapı kör edilmiş olarak koşar, düşmesini bekler --------- */
if (process.argv.includes('--mutasyon')) {
  let tutan = 0; const MUT = ['kasa', 'sizinti', 'satis', 'yama', 'ucretsiz'];
  for (const m of MUT) {
    const r = spawnSync(process.execPath, [__filename], { env: Object.assign({}, process.env, { HZ_MUTASYON: m }), encoding: 'utf8' });
    const dustu = r.status !== 0;
    if (dustu) tutan++;
    console.log('  mutasyon ' + m.padEnd(10) + (dustu ? 'KIRMIZI (doğru — sınav körlüğü yakaladı)' : 'YESIL  (YANLIŞ — sınav bu kapıyı ölçmüyor)'));
  }
  console.log('MUTASYON: ' + tutan + '/' + MUT.length + ' → KIRMIZI');
  process.exit(tutan === MUT.length ? 0 : 1);
}

/* --------------------------- geçici depo kurucu --------------------------- */
const KABUK = (yol, ek) => '<!doctype html><html data-kasa-sayfa="' + yol + '" lang="tr"><head><script src="../../paket-kapisi.js"></script>' +
  '<title>Tetikte · Kaydır-Çöz</title></head><body><div id="akis"></div>' + (ek || '') +
  '<script type="text/x-tetikte-kasa" id="kasaAna">const SORULAR=window.__KASA_SORULAR||[];</script><script src="../../kasa-yukle.js"></script></body></html>';
const VITRIN = (ek, adet) => {
  const d = []; for (let i = 0; i < (adet || 1); i++) d.push({ soru: 'Mal fiyatı artarsa? ' + i, ders: 'D' + (i % 3), dogru: 'B' });
  return '<!doctype html><html lang="tr"><head><script src="../../paket-kapisi.js"></script></head><body>' +
    '<script>const SORULAR=' + JSON.stringify(d) + ';' + (ek || '') + '</script></body></html>';
};

function kur(degisiklik) {
  const k = fs.mkdtempSync(path.join(os.tmpdir(), 'hz-sinav-'));
  const d = {
    'arac/kasa-modu.json': JSON.stringify({ sayfalar: ['kaydir/sgs/turkce.html'] }),
    'paket-kapisi.js': "s.src = KOK + 'kutuphane/supabase-9.9.9.js';",
    'kutuphane/supabase-9.9.9.js': '/* kütüphane */',
    'kasa-yukle.js': "var PARCA = 100; mesaj('x','y', dugme('../../satin-al.html', 'Paketi güncelle'));",
    'cihaz-kapisi.js': '/* cihaz */',
    'captcha.js': '/* captcha */',
    'kaydir/sgs/index.html': '<a class="kart" href="turkce.html"><div class="ad">T&#252;rk&#231;e</div></a>',
    'kaydir/sgs/turkce.html': KABUK('kaydir/sgs/turkce.html'),
    'kaydir/sgs/maliye.html': '<html><script>const SORULAR=[{"dogru":"A"}]</script></html>',
    'kaydir/vitrin/sgs.html': VITRIN()
  };
  Object.assign(d, degisiklik || {});
  for (const [g, icerik] of Object.entries(d)) {
    if (icerik === null) continue;
    fs.mkdirSync(path.dirname(path.join(k, g)), { recursive: true });
    fs.writeFileSync(path.join(k, g), icerik);
  }
  fs.mkdirSync(path.join(k, 'mobil', 'uygulama'), { recursive: true });
  fs.copyFileSync(path.join(__dirname, 'package.json'), path.join(k, 'mobil', 'package.json'));
  for (const ad of fs.readdirSync(path.join(__dirname, 'uygulama'))) {
    fs.copyFileSync(path.join(__dirname, 'uygulama', ad), path.join(k, 'mobil', 'uygulama', ad));
  }
  return k;
}
function kos(kok) {
  const cikti = path.join(os.tmpdir(), 'hz-cikti-' + process.pid + '-' + Math.random().toString(36).slice(2));
  const r = spawnSync(process.execPath, [HAZIRLA, '--kok', kok, '--cikti', cikti], { encoding: 'utf8', env: process.env });
  fs.rmSync(cikti, { recursive: true, force: true });
  return { kod: r.status, metin: (r.stdout || '') + (r.stderr || '') };
}

const VAKALAR = [
  { ad: 'temiz kabuk + vitrin → YEŞİL', bekle: 0 },
  { ad: 'vitrinde cevaplı soru + "fiyat" kelimesi → YEŞİL (yanlış alarm yok)', bekle: 0,
    d: { 'kaydir/vitrin/sgs.html': VITRIN('var not="fiyatı yükselen mal";') } },
  { ad: 'vitrin 70 soru → 30\'a kesilir (sınav başına 30 ücretsiz)', bekle: 0, desen: /ücretsiz 1 sayfa\/30 soru/,
    d: { 'kaydir/vitrin/sgs.html': VITRIN('', 70) } },
  { ad: 'vitrin 12 soru → dokunulmaz (12)', bekle: 0, desen: /ücretsiz 1 sayfa\/12 soru/,
    d: { 'kaydir/vitrin/sgs.html': VITRIN('', 12) } },
  { ad: 'vitrinde SORULAR dizisi okunamıyor → KAPI-UCRETSIZ', bekle: 1, desen: /KAPI-UCRETSIZ/,
    d: { 'kaydir/vitrin/sgs.html': '<html><head><script src="../../paket-kapisi.js"></script></head><body><script>const SORULAR=[{bozuk</script></body></html>' } },
  { ad: 'kasa sayfasında gömülü SORULAR → KAPI-KASA', bekle: 1, desen: /KAPI-KASA.*gömülü/,
    d: { 'kaydir/sgs/turkce.html': KABUK('kaydir/sgs/turkce.html', '<script>const SORULAR=[{"x":1}]</script>') } },
  { ad: 'kabuk işareti yok (eski gömülü sayfa listeye yazılmış) → KAPI-KASA', bekle: 1, desen: /KAPI-KASA.*işareti yok/,
    d: { 'kaydir/sgs/turkce.html': '<html><head><script src="../../paket-kapisi.js"></script></head><body></body></html>' } },
  { ad: 'kasa listesinde beklenmeyen yol → KAPI-KASA', bekle: 1, desen: /KAPI-KASA.*beklenmeyen yol/,
    d: { 'arac/kasa-modu.json': JSON.stringify({ sayfalar: ['kaydir/sgs/turkce.html', 'veri/deneme/sgs-set-01.json'] }) } },
  { ad: 'uygulama dosyasında "dogru": → KAPI-SIZINTI', bekle: 1, desen: /KAPI-SIZINTI/,
    d: { 'cihaz-kapisi.js': 'var yedek=[{"soru":"s","dogru":"C"}];' } },
  { ad: 'kabukta satış sayfasına bağ → KAPI-SATIS', bekle: 1, desen: /KAPI-SATIS.*satış sayfasına bağ/,
    d: { 'kaydir/sgs/turkce.html': KABUK('kaydir/sgs/turkce.html', '<a href="../../fiyat.html">x</a>') } },
  { ad: 'ortak betikte satış düğmesi metni → KAPI-SATIS', bekle: 1, desen: /KAPI-SATIS.*düğmesi metni/,
    d: { 'cihaz-kapisi.js': "el.textContent='Paketleri gör';" } },
  { ad: 'kasa-yukle.js yaması tutmadı (düğme metni değişmiş) → KAPI-SATIS', bekle: 1, desen: /KAPI-SATIS.*yaması tutmadı/,
    d: { 'kasa-yukle.js': "var PARCA = 100; mesaj('x','y', dugme('../../satin-al.html', 'Paketini yükselt'));" } }
];

let gecen = 0, toplam = 0;
function sonuc(ad, tamam, not) { toplam++; if (tamam) gecen++; console.log((tamam ? '  ✓ ' : '  ✗ ') + ad + (tamam ? '' : '  → ' + not)); }

for (const v of VAKALAR) {
  const kok = kur(v.d);
  const r = kos(kok);
  fs.rmSync(kok, { recursive: true, force: true });
  const tamam = (r.kod === 0) === (v.bekle === 0) && (!v.desen || v.desen.test(r.metin));
  sonuc(v.ad, tamam, 'çıkış ' + r.kod + ' · ' + r.metin.trim().split('\n').slice(0, 3).join(' | '));
}

/* --------------------------- gerçek depo --------------------------- */
{
  const r = kos(DEPO);
  sonuc('gerçek depo → YEŞİL', r.kod === 0, r.metin.trim().split('\n').slice(0, 4).join(' | '));
}

/* --------------------------- kapsar() eşdeğerliği --------------------------- */
{
  const pk = fs.readFileSync(path.join(DEPO, 'paket-kapisi.js'), 'utf8');
  const m = pk.match(/var kapsar = function \(paket\) \{[\s\S]*?\n {6}\};/);
  let tamam = !!m, not = m ? '' : 'paket-kapisi.js içinde kapsar() bulunamadı';
  if (m) {
    const kutu = { window: {}, localStorage: null, navigator: {}, indexedDB: null };
    vm.createContext(kutu);
    vm.runInContext(fs.readFileSync(path.join(__dirname, 'uygulama', 'ortak.js'), 'utf8'), kutu);
    const PAKETLER = ['', null, 'tam', 'kurucu', 'sgs', 'sgs-ders', 'SGS', 'sinav-249', 'yeterlilik', 'yeterlilik-kgk', 'yeterlilik-x', 'smmm', 'kgk', 'radar', ' sgs '];
    const SINAVLAR = [null, 'sgs', 'yeterlilik'];
    let fark = 0;
    for (const s of SINAVLAR) {
      const site = new Function('sinavi', m[0] + ' return kapsar;')(s);
      for (const p of PAKETLER) if (site(p) !== kutu.window.TT.kapsar(p, s)) { fark++; not += ' [' + p + '/' + s + ']'; }
    }
    const yollar = ['/kaydir/sgs/turkce.html', '/kaydir/smmm/vergi.html', '/kaydir/vitrin/sgs.html', '/sinav-gibi.html'];
    const siteSinav = (y) => /\/kaydir\/sgs\//.test(y) || /sinav-gibi\.html$/.test(y) ? 'sgs' : (/\/kaydir\/smmm\//.test(y) ? 'yeterlilik' : null);
    for (const y of yollar) if (siteSinav(y) !== kutu.window.TT.sinaviBul(y)) { fark++; not += ' [yol ' + y + ']'; }
    /* Yol→sınav eşlemesi paket-kapisi.js'te satır içinde; biçimi değişirse yukarıdaki siteSinav kopyası bayatlar. */
    const SITE_YOL = [
      String.raw`/\/kaydir\/sgs\//.test(location.pathname) || /sinav-gibi\.html$/.test(location.pathname) ? 'sgs'`,
      String.raw`(/\/kaydir\/smmm\//.test(location.pathname) ? 'yeterlilik' : null)`
    ];
    for (const s of SITE_YOL) if (pk.indexOf(s) < 0) { fark++; not += ' [paket-kapisi sınav yolu biçimi değişmiş: ' + s.slice(0, 40) + ']'; }
    tamam = fark === 0; not = fark + ' fark' + not;
  }
  sonuc('kapsar()/sinaviBul() paket-kapisi.js ile aynı (' + 15 * 3 + ' paket×sınav + 4 yol)', tamam, not);
}

/* --------------------------- kasa sorgusu biçimi --------------------------- */
{
  const ky = fs.readFileSync(path.join(DEPO, 'kasa-yukle.js'), 'utf8');
  const uy = fs.readFileSync(path.join(__dirname, 'uygulama', 'uygulama.js'), 'utf8');
  const kalip = (d) => [
    'var PARCA = 100;',
    ".from('paket_soru').select('sira,veri', { count: 'exact' })",
    ".eq('sayfa', " + d + ").order('sira', { ascending: true }).range(0, PARCA - 1)",
    ".from('paket_soru').select('sira,veri')",
    ".eq('sayfa', " + d + ").order('sira', { ascending: true }).range(i, i + PARCA - 1)"
  ];
  const eksik = kalip('sayfa').filter((s) => ky.indexOf(s) < 0).map((s) => 'kasa-yukle: ' + s)
    .concat(kalip('yol').filter((s) => uy.indexOf(s) < 0).map((s) => 'uygulama: ' + s));
  sonuc('kasa sorgusu kasa-yukle.js ↔ uygulama.js aynı biçimde', eksik.length === 0, eksik.join(' | '));
}

console.log('HAZIRLA-SINAVI: ' + (gecen === toplam ? 'YESIL' : 'KIRMIZI') + ' — ' + gecen + '/' + toplam + (process.env.HZ_MUTASYON ? ' · HZ_MUTASYON=' + process.env.HZ_MUTASYON : ''));
process.exit(gecen === toplam ? 0 : 1);
