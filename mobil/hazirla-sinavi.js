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
  let tutan = 0; const MUT = ['kasa', 'sizinti', 'satis', 'yama', 'ucretsiz', 'ioskilit', 'sayfa'];
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

/* 09.10 site sayfası (seviye testi): hazirla.js SAYFA_SOK işaretlerinin her biri TAM 1 kez + stil.css bağı; satış ve hesap bağı
   derlemede uygulama ekranına çevrilir. `eksik` verilen işaret sayfadan düşürülür (KAPI-SAYFA vakası). */
const SEVIYE = (ek, eksik) => {
  const satir = {
    canonical: '<link rel="canonical" href="https://tetikte.com/seviye-testi.html">',
    sayac: '<script data-goatcounter="https://x.goatcounter.com/count" async src="//gc.zgo.at/count.js"></script>',
    menu: '<script src="menu.js" defer></script>', komutcss: '<link rel="stylesheet" href="komut.css">', komut: '<script src="komut.js" defer></script>',
    fiyat: '<script src="fiyat-motoru.js?v=1"></script>', uye: '<script src="uye-durumu.js?v=1"></script>'
  };
  if (eksik) delete satir[eksik];
  return '<!doctype html><html lang="tr"><head>' + satir.canonical + '<link rel="stylesheet" href="stil.css"></head><body>' +
    '<div id="svTeklif"><a href="satin-al.html?paket=sgs">Tam bankayı aç →</a></div><a href="ogrenci.html?sonra=x#uye-ol">Hesap</a><a href="kvkk.html">KVKK</a>' +
    '<script>' + "fetch('veri/seviye/sgs-havuz.json'); var al='fiyat.html';" + (ek || '') + '</script>' +
    [satir.fiyat, satir.uye, satir.sayac, satir.menu, satir.komutcss, satir.komut].filter(Boolean).join('') + '</body></html>';
};
/* 09.10 1.8.1 öteki site sayfaları: hepsi bütün söküm işaretlerini taşır (listelenmeyen işaret çıktıda kalır, zararsız);
   sinav-gibi.html ayrıca kökteki paket-kapisi.js etiketini taşır. */
const SITE_DIGER = ['yanlislarim.html', 'canli-deneme.html', 'en-cok-cikan-konular-sgs.html', 'en-cok-cikan-konular-yeterlilik.html'];
const SINAV_GIBI = (ek, kapisiz) => SEVIYE(ek).replace('<link rel="stylesheet" href="stil.css">', kapisiz ? '' : '<script src="paket-kapisi.js"></script>')
  .replace('<a href="ogrenci.html', '<a href="sorular.html#sgs">Soru çöz</a><a href="ogrenci.html');
const SITE_EK_SAHTE = {};
['stil.css', 'stil-acik.css', 'tema-bas.js', 'seviye-model.js', 'seviye-model-yet.js', 'nobetci-oynatici.js', 'kutu-esitle.js', 'sinav-sonucu.js',
  'calisma-ozet.js', 'ayrinti.js', 'tema.js', 'nobetci-sor.js'].forEach((a) => { SITE_EK_SAHTE[a] = '/* ' + a + ' */'; });

function kur(degisiklik) {
  const k = fs.mkdtempSync(path.join(os.tmpdir(), 'hz-sinav-'));
  const d = Object.assign({
    'seviye-testi.html': SEVIYE(),
    'sinav-gibi.html': SINAV_GIBI()
  }, SITE_EK_SAHTE, Object.fromEntries(SITE_DIGER.map((y) => [y, SEVIYE()])), {
    'arac/kasa-modu.json': JSON.stringify({ sayfalar: ['kaydir/sgs/turkce.html'] }),
    'paket-kapisi.js': "s.src = KOK + 'kutuphane/supabase-9.9.9.js';",
    'kutuphane/supabase-9.9.9.js': '/* kütüphane */',
    'kasa-yukle.js': "var PARCA = 100; async function cek(sb) {} mesaj('x','y', dugme('../../satin-al.html', 'Paketi güncelle'));",
    'cihaz-kapisi.js': '/* cihaz */',
    'icerik-koruma.js': '/* koruma (09.10) */',
    'captcha.js': '/* captcha */',
    'kaydir/sgs/index.html': '<a class="kart" href="turkce.html"><div class="ad">T&#252;rk&#231;e</div></a>',
    'kaydir/sgs/turkce.html': KABUK('kaydir/sgs/turkce.html'),
    'kaydir/sgs/maliye.html': '<html><script>const SORULAR=[{"dogru":"A"}]</script></html>',
    'kaydir/vitrin/ornek-sgs.html': VITRIN()
  });
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
    d: { 'kaydir/vitrin/ornek-sgs.html': VITRIN('var not="fiyatı yükselen mal";') } },
  { ad: 'vitrin 70 soru → 30\'a kesilir (sınav başına 30 ücretsiz)', bekle: 0, desen: /ücretsiz 1 sayfa\/30 soru/,
    d: { 'kaydir/vitrin/ornek-sgs.html': VITRIN('', 70) } },
  { ad: 'vitrin 12 soru → dokunulmaz (12)', bekle: 0, desen: /ücretsiz 1 sayfa\/12 soru/,
    d: { 'kaydir/vitrin/ornek-sgs.html': VITRIN('', 12) } },
  { ad: 'vitrinde SORULAR dizisi okunamıyor → KAPI-UCRETSIZ', bekle: 1, desen: /KAPI-UCRETSIZ/,
    d: { 'kaydir/vitrin/ornek-sgs.html': '<html><head><script src="../../paket-kapisi.js"></script></head><body><script>const SORULAR=[{bozuk</script></body></html>' } },
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
    d: { 'kasa-yukle.js': "var PARCA = 100; async function cek(sb) {} mesaj('x','y', dugme('../../satin-al.html', 'Paketini yükselt'));" } },
  { ad: 'kasa-yukle.js cek() imzası değişmiş (kısa sınav kancası tutmaz) → KAPI-KASA', bekle: 1, desen: /KAPI-KASA.*karma kancası/,
    d: { 'kasa-yukle.js': "var PARCA = 100; async function cekSorular(sb) {} mesaj('x','y', dugme('../../satin-al.html', 'Paketi güncelle'));" } },
  /* 09.10 site sayfası (seviye testi) */
  { ad: 'seviye sayfası: satış + hesap bağı uygulama ekranına çevrilir, işaretler sökülür → YEŞİL', bekle: 0, desen: /HAZIRLA: YESIL/ },
  { ad: 'seviye sayfası yok → KAPI-SAYFA', bekle: 1, desen: /KAPI-SAYFA.*seviye-testi\.html yok/, d: { 'seviye-testi.html': null } },
  { ad: 'seviye sayfasında işaret eksik (fiyat-motoru.js) → KAPI-SAYFA', bekle: 1, desen: /KAPI-SAYFA.*"fiyat".*bulunan 0/,
    d: { 'seviye-testi.html': SEVIYE('', 'fiyat') } },
  { ad: 'seviye sayfasında cevaplı soru → KAPI-SIZINTI (sayfa vitrin değil)', bekle: 1, desen: /KAPI-SIZINTI.*seviye-testi\.html/,
    d: { 'seviye-testi.html': SEVIYE('var s={"dogru":"A"};') } },
  { ad: 'seviye sayfasında çevrilmeyen satış bağı (mesafeli-satis) → KAPI-SATIS', bekle: 1, desen: /KAPI-SATIS.*seviye-testi\.html.*satış sayfasına bağ/,
    d: { 'seviye-testi.html': SEVIYE("var m='mesafeli-satis.html';") } },
  /* 09.10 1.8.1 */
  { ad: 'sınav gibi sayfasında paket-kapisi.js etiketi yok → KAPI-SAYFA (kilit uygulamaya taşınamaz)', bekle: 1, desen: /KAPI-SAYFA.*sinav-gibi\.html.*paket-kapisi/,
    d: { 'sinav-gibi.html': SINAV_GIBI('', true) } },
  { ad: 'seviye sayfasında iPhone gizleme kimliği (svTeklif) yok → KAPI-SAYFA', bekle: 1, desen: /KAPI-SAYFA.*svTeklif/,
    d: { 'seviye-testi.html': SEVIYE().replace('id="svTeklif"', 'id="baska"') } },
  { ad: 'yanlışlarım sayfası yok → KAPI-SAYFA', bekle: 1, desen: /KAPI-SAYFA.*yanlislarim\.html yok/, d: { 'yanlislarim.html': null } },
  { ad: 'canlı deneme yardımcısı (tema.js) yok → KAPI-SAYFA', bekle: 1, desen: /KAPI-SAYFA.*tema\.js yok/, d: { 'tema.js': null } }
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

/* --------------------------- 02.10 B1: iPhone'da satış kapalıyken web paketi açılmaz --------------------------- */
{
  let kaynak = fs.readFileSync(path.join(__dirname, 'uygulama', 'ortak.js'), 'utf8');
  if (process.env.HZ_MUTASYON === 'ioskilit') kaynak = kaynak.replace('if (iosKilitli())', 'if (false)');
  const dene = async (platform, iosSatis) => {
    let sorgu = 0;
    const kutu = { window: platform ? { Capacitor: { getPlatform: () => platform } } : {}, localStorage: { setItem() {}, getItem() { return null; } }, navigator: {}, indexedDB: null };
    vm.createContext(kutu);
    vm.runInContext(iosSatis ? kaynak.replace('var IOS_SATIS = false; /*HAZIRLA:IOS_SATIS*/', 'var IOS_SATIS = true;') : kaynak, kutu);
    const sb = { from: () => ({ select: () => ({ eq: async () => { sorgu++; return { data: [{ paket: 'sgs', bitis: null }], error: null }; } }) }) };
    const r = await kutu.window.TT.paketler(sb, 'u1');
    return { acar: kutu.window.TT.acarMi(r.satir, 'sgs'), sorgu };
  };
  (async () => {
    const ios = await dene('ios', false), iosAcik = await dene('ios', true), android = await dene('android', false), web = await dene(null, false);
    const tamam = ios.acar === false && ios.sorgu === 0 && iosAcik.acar === true && android.acar === true && web.acar === true;
    sonuc('iPhone satış kapalı → web paketi açılmaz; iPhone satış açık / Android / web → açılır', tamam,
      JSON.stringify({ ios, iosAcik, android, web }));
    console.log('HAZIRLA-SINAVI: ' + (gecen === toplam ? 'YESIL' : 'KIRMIZI') + ' — ' + gecen + '/' + toplam + (process.env.HZ_MUTASYON ? ' · HZ_MUTASYON=' + process.env.HZ_MUTASYON : ''));
    process.exitCode = gecen === toplam ? 0 : 1;
  })();
}

/* --------------------------- kasa sorgusu biçimi --------------------------- */
{
  const ky = fs.readFileSync(path.join(DEPO, 'kasa-yukle.js'), 'utf8');
  const uy = fs.readFileSync(path.join(__dirname, 'uygulama', 'uygulama.js'), 'utf8');
  /* 09.10 KASA ÖLÇER: iki dosya da kasa_soru_getir(p_sayfa, p_bas, p_adet) fonksiyonunu AYNI imzayla çağırır;
     tabloya doğrudan okuma (from('paket_soru')) İKİSİNDE DE OLMAMALI (radar-app/sql/2026-10-09-kasa-olcer.sql kapattı). */
  const kalip = (d) => [
    'var PARCA = 100;',
    "sb.rpc('kasa_soru_getir', { p_sayfa: " + d + ", p_bas: bas, p_adet: adet })",
    "+ilk[0].toplam"
  ];
  const eksik = kalip('sayfa').filter((s) => ky.indexOf(s) < 0).map((s) => 'kasa-yukle: ' + s)
    .concat(kalip('yol').filter((s) => uy.indexOf(s) < 0).map((s) => 'uygulama: ' + s))
    .concat(ky.indexOf("from('paket_soru')") >= 0 ? ['kasa-yukle: tabloya doğrudan okuma kalmış'] : [])
    .concat(uy.indexOf("from('paket_soru')") >= 0 ? ['uygulama: tabloya doğrudan okuma kalmış'] : []);
  sonuc('kasa sorgusu kasa-yukle.js ↔ uygulama.js aynı biçimde (fonksiyon, doğrudan tablo yok)', eksik.length === 0, eksik.join(' | '));
}
/* sonuç satırı ve çıkış kodu iPhone vakası (eşzamansız) bitince yazılır — process.exit burada çağrılırsa o vaka hiç koşmaz */
