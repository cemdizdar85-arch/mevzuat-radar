#!/usr/bin/env node
/* ============================================================================
 *  DERS SAYFASI PAYLAŞIM ÖNİZLEMESİ (og:image) — 24.11.2026 (Cem: "ders linki paylaşılınca aynı kapak görünsün")
 *  kaydir/sgs/*.html ve kaydir/smmm/*.html başına <!--og-ders-->…<!--/og-ders--> bloğu yazar: og:title, og:description,
 *  og:image (gorsel/ders/og/<kapak>.jpg, 1200×630 — WhatsApp webp göstermez), og:url, twitter:card. Ders adı ve sınav
 *  veri/soru-dizini.json'dan (sayfa yolu eşlemesi). Blok varsa yenilenir (aynı içerikse dosyaya dokunmaz) → idempotent.
 *  Sayfalar robotla basıldığı için bu araç basım hattının sonunda da koşar (yayin-bas.yml, smmm-kasa-yayin.yml).
 *  🚫 GÖRMEZ: KGK sayfaları (kapak yok) · <title> (üretici yazar, dokunulmaz) · kapak listesinde olmayan yeni ders.
 *  Kullanım: node arac/ders-og.js [--yaz] [--sinav]
 * ==========================================================================*/
'use strict';
const fs = require('fs'), path = require('path');
const KOK = path.resolve(__dirname, '..');
const KAPAK = ['turkce', 'matematik', 'ataturk-ilkeleri-ve-inkilap-tarihi', 'yabanci-dil', 'finansal-muhasebe', 'maliyet-muhasebesi', 'mali-tablolar-analizi', 'denetim', 'ekonomi', 'maliye', 'meslek-hukuku', 'is-ve-sosyal-guvenlik-hukuku', 'vergi-hukuku', 'ticaret-hukuku', 'borclar-hukuku', 'hukuk', 'sermaye-piyasasi'];
const ESLE = { 'finansal-tablolar': 'mali-tablolar-analizi', 'muhasebe-denetimi': 'denetim', 'vergi': 'vergi-hukuku' };
const SINAV_AD = { sgs: 'SMMM Staja Giriş', smmm: 'SMMM Yeterlilik' };
const esc = s => String(s).replace(/&/g, '&amp;').replace(/"/g, '&quot;').replace(/</g, '&lt;');

function blok(sayfa, dersAd, sinav) {
  let b = path.basename(sayfa, '.html'); b = ESLE[b] || b;
  if (!KAPAK.includes(b)) return null;
  const baslik = `${dersAd} soruları · ${SINAV_AD[sinav]} | Tetikte`;
  const acik = `${SINAV_AD[sinav]} sınavına ${dersAd} sorularıyla hazırlan: cevaptan sonra doğrusu, yanlışının nedeni ve dayandığı madde açılır.`;
  return '<!--og-ders-->' +
    `<meta property="og:type" content="website"><meta property="og:site_name" content="Tetikte">` +
    `<meta property="og:title" content="${esc(baslik)}"><meta property="og:description" content="${esc(acik)}">` +
    `<meta property="og:url" content="https://tetikte.com/${esc(sayfa)}">` +
    `<meta property="og:image" content="https://tetikte.com/gorsel/ders/og/${b}.jpg"><meta property="og:image:width" content="1200"><meta property="og:image:height" content="630">` +
    `<meta property="og:image:alt" content="${esc(dersAd)} — Tetikte ders kapağı">` +
    `<meta name="twitter:card" content="summary_large_image">` +
    '<!--/og-ders-->';
}
function uygula(html, b) {
  const temiz = html.replace(/<!--og-ders-->[\s\S]*?<!--\/og-ders-->/, '');
  if (!b) return temiz;
  const i = temiz.indexOf('</title>');
  return i > -1 ? temiz.slice(0, i + 8) + b + temiz.slice(i + 8) : temiz.replace('</head>', b + '</head>');
}

if (process.argv.includes('--sinav')) {
  let n = 0; const ok = (k, m) => { if (!k) { console.error('SINAV DUSTU: ' + m); process.exit(1); } n++; };
  const h = '<html><head><title>X</title></head><body></body></html>';
  const b1 = blok('kaydir/smmm/vergi.html', 'Vergi Mevzuatı ve Uygulaması', 'smmm');
  ok(b1 && b1.includes('/gorsel/ders/og/vergi-hukuku.jpg'), 'eşleme (vergi -> vergi-hukuku)');
  const h1 = uygula(h, b1); ok(h1.indexOf('og:image') > h1.indexOf('</title>'), 'blok başlıktan sonra');
  ok(uygula(h1, b1) === h1, 'idempotent (ikinci koşu aynı)');
  ok((uygula(h1, b1).match(/<!--og-ders-->/g) || []).length === 1, 'tek blok');
  ok(blok('kaydir/kgk/bankacilik.html', 'Bankacılık', 'kgk') === null, 'KGK kapaksız');
  ok(!uygula(h1, null).includes('og:image'), 'kapak yoksa eski blok silinir');
  console.log('ders-og öz-sınav: ' + n + '/6 TAMAM'); process.exit(0);
}

const yaz = process.argv.includes('--yaz');
const dizin = JSON.parse(fs.readFileSync(path.join(KOK, 'veri/soru-dizini.json'), 'utf8'));
let degisen = 0, bakilan = 0, kapaksiz = 0, eksikJpg = 0;
for (const s of dizin.sinavlar || []) {
  if (!SINAV_AD[s.kod]) continue;
  for (const d of s.dersler || []) {
    if (!d.sayfa) continue;
    const f = path.join(KOK, d.sayfa); if (!fs.existsSync(f)) continue;
    bakilan++;
    const b = blok(d.sayfa, d.ad, s.kod); if (!b) { kapaksiz++; continue; }
    const jpg = b.match(/gorsel\/ders\/og\/([a-z0-9-]+)\.jpg/)[1];
    if (!fs.existsSync(path.join(KOK, 'gorsel/ders/og', jpg + '.jpg'))) { eksikJpg++; console.error('EKSİK JPG: ' + jpg); continue; }
    const eski = fs.readFileSync(f, 'utf8'), yeni = uygula(eski, b);
    if (yeni !== eski) { degisen++; if (yaz) fs.writeFileSync(f, yeni); }
  }
}
console.log(`ders-og: bakılan ${bakilan} · değişen ${degisen}${yaz ? ' (yazıldı)' : ' (KURU)'} · kapaksız ${kapaksiz} · eksik jpg ${eksikJpg}`);
if (eksikJpg) process.exitCode = 2;
