#!/usr/bin/env node
/* ============================================================================
 *  DAMPING GECMIS HASAT (30.08.2026)
 *  Ticaret Bak. tarihsel listeleri -> veri/damping-gecmis.json
 *
 *  NEDEN: gtip-damping.json "bugun ne odersin", damping-sorusturma.json
 *  "yakinda ne odeyebilirsin" diyor. Ucuncu soru: "bu urunde DAHA ONCE ne oldu?"
 *  Ayni koda gecmiste onlem konmus ve suresi dolmussa, ya da sorusturma acilip
 *  ONLEMSIZ kapanmissa, bu ithalatcinin olasilik tahminini degistirir.
 *
 *  UC KAYNAK (uc farkli sayfada, uc farkli tarihte damgalanmis):
 *    onlemsiz  : "Herhangi bir onlem alinmadan sonuclandirilan sorusturmalar"
 *    dolan     : "Yururlukte kalma suresi sona eren onlemler"
 *    kalkan    : "Gozden gecirme sorusturmasi sonucunda kaldirilan onlemler"
 *
 *  🔴 TAMLIK UYARISI (rapora da yazilir): bu listeler BAYAT ve tamligi
 *  dogrulanmamistir (30.08 olcumu: kalkanlar dosyasi 13.05.2022 damgali,
 *  30 yilda yalniz 47 "suresi dolan" onlem gorunuyor). Bu veriden ORAN/OLASILIK
 *  cikarilmaz - "sorusturmalarin %X'i vergiyle biter" YASAK. Yalniz TEKIL
 *  gecmis olay soylenir: "bu urunde onlem vardi, suresi doldu (kaynak damgasi: ...)".
 *
 *  ⚠ ESKI .xls: onlemsiz kapananlar dosyasi 1989'dan birikmis ESKI BIFF
 *  bicimindedir (zip degil OLE2), Linux runner'da acilmaz. Yerelde Excel ile
 *  xlsx'e cevrilip --onlemsiz <yol> ile verilir; verilmezse mevcut JSON'daki
 *  onlemsiz kayitlar OLDUGU GIBI KORUNUR (silinmez) ve rapor "elle tazelenecek"
 *  der. Kaynak dosyanin adi/boyutu her kosuda kaydedilir; degisirse gorulur.
 *
 *  Kullanim:
 *    node motor/damping-gecmis-hasat.js
 *    node motor/damping-gecmis-hasat.js --onlemsiz <yerelde-cevrilmis.xlsx>
 * ==========================================================================*/
'use strict';
const fs = require('fs'), path = require('path'), zlib = require('zlib');

const KOK = path.resolve(__dirname, '..');
const CIKTI = path.join(KOK, 'veri', 'damping-gecmis.json');
const args = process.argv.slice(2);
const oi = args.indexOf('--onlemsiz');
const ONLEMSIZ_XLSX = oi > -1 ? args[oi + 1] : null;

const SAYFALAR = [
  'https://ticaret.gov.tr/ithalat/ticaret-politikasi-savunma-araclari/damping-ve-subvansiyon/yururlukten-kalkan-onlemler',
  'https://ticaret.gov.tr/ithalat/ticaret-politikasi-savunma-araclari/damping-ve-subvansiyon/sorusturmalar',
];

/* ------------------------------------------------------------- xlsx okuma */
function zipGirdileri(buf) {
  let e = -1; for (let i = buf.length - 22; i >= 0; i--) { if (buf.readUInt32LE(i) === 0x06054b50) { e = i; break; } }
  if (e < 0) throw new Error('zip dizini yok (dosya eski .xls olabilir)');
  const n = buf.readUInt16LE(e + 10), cd = buf.readUInt32LE(e + 16); let p = cd; const o = {};
  for (let k = 0; k < n; k++) {
    const y = buf.readUInt16LE(p + 10), cs = buf.readUInt32LE(p + 20), nl = buf.readUInt16LE(p + 28),
      el = buf.readUInt16LE(p + 30), cl = buf.readUInt16LE(p + 32), lho = buf.readUInt32LE(p + 42);
    const ad = buf.toString('utf8', p + 46, p + 46 + nl);
    const lnl = buf.readUInt16LE(lho + 26), lel = buf.readUInt16LE(lho + 28), bas = lho + 30 + lnl + lel;
    const ham = buf.subarray(bas, bas + cs);
    o[ad] = y === 0 ? ham : zlib.inflateRawSync(ham);
    p += 46 + nl + el + cl;
  }
  return o;
}
const cozXml = s => String(s).replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>')
  .replace(/&quot;/g, '"').replace(/&#x([0-9a-f]+);/gi, (_, h) => String.fromCodePoint(parseInt(h, 16)))
  .replace(/&#(\d+);/g, (_, d) => String.fromCodePoint(+d));

function satirlariOku(buf) {
  const z = zipGirdileri(buf);
  const ss = [];
  if (z['xl/sharedStrings.xml'])
    for (const m of z['xl/sharedStrings.xml'].toString('utf8').matchAll(/<si>([\s\S]*?)<\/si>/g))
      ss.push(cozXml([...m[1].matchAll(/<t[^>]*>([\s\S]*?)<\/t>/g)].map(x => x[1]).join('')));
  const sayfa = Object.keys(z).filter(k => /^xl\/worksheets\/sheet\d+\.xml$/.test(k)).sort()[0];
  const out = [];
  for (const r of z[sayfa].toString('utf8').matchAll(/<row[^>]*>([\s\S]*?)<\/row>/g)) {
    const c = {};
    for (const cm of r[1].matchAll(/<c r="([A-Z]+)\d+"([^>]*)>([\s\S]*?)<\/c>/g)) {
      const t = (cm[2].match(/t="([^"]+)"/) || [])[1];
      let v = (cm[3].match(/<v>([\s\S]*?)<\/v>/) || [])[1];
      if (t === 's') v = ss[+v];
      else if (t === 'inlineStr') v = [...cm[3].matchAll(/<t[^>]*>([\s\S]*?)<\/t>/g)].map(x => x[1]).join('');
      if (v !== undefined) c[cm[1]] = cozXml(String(v));
    }
    out.push(c);
  }
  return out;
}
const norm = s => String(s || '').replace(/\s+/g, ' ').trim();
const kodlariAyikla = ham => {
  const out = [];
  for (const tok of norm(ham).split(/\s+/)) {
    const t = tok.replace(/[^\d.]/g, '').replace(/^\.+|\.+$/g, '');
    if (/^\d{2,4}(\.\d{2}){0,4}$/.test(t)) out.push(t.replace(/\./g, ''));
  }
  return out;
};
/* A=GTIP, B=madde, C=ulke, D=teblig, E.. = RG bilgileri (uc dosyada da ayni duzen) */
function kayitlar(rows, tip) {
  const out = [];
  for (const c of rows) {
    const kod = kodlariAyikla(c.A);
    // Madde ismi HARF icermeli: bu dosyalarda satir numarasi/sayac artigi
    // hucreler var ("9" gibi) ve bunlar urun adi diye gecerse ekranda
    // "Bu urunde gecmiste onlem vardi: 9" yazar. En az 3 harf sarti.
    const ad = norm(c.B);
    if (!kod.length || (ad.match(/\p{L}/gu) || []).length < 3) continue;
    out.push({ k: kod.join(' '), m: norm(c.B), u: norm(c.C), tb: norm(c.D), rg: norm(c.E), tip });
  }
  return out;
}

/* -------------------------------------------------------------- indirme */
async function metin(u) { const r = await fetch(u, { headers: { 'user-agent': 'Mozilla/5.0 tetikte-gecmis' } }); if (!r.ok) throw new Error(`${u} -> ${r.status}`); return r.text(); }
async function dosya(u) { const r = await fetch(u, { headers: { 'user-agent': 'Mozilla/5.0 tetikte-gecmis' } }); if (!r.ok) throw new Error(`${u} -> ${r.status}`); return Buffer.from(await r.arrayBuffer()); }
function baglantilar(html) {
  const out = [];
  for (const m of html.matchAll(/href="([^"]+\.xlsx?)"/gi)) {
    let u = cozXml(m[1]);
    if (!u.startsWith('http')) u = 'https://ticaret.gov.tr' + (u.startsWith('/') ? '' : '/') + u;
    let okunur = u; try { okunur = decodeURIComponent(u); } catch { }
    out.push({ url: encodeURI(okunur), ad: okunur.split('/').pop() });
  }
  return out;
}

/* ==================================================================== ANA */
(async () => {
  let hepsi = [];
  for (const s of SAYFALAR) hepsi = hepsi.concat(baglantilar(await metin(s)));
  const bul = re => hepsi.find(x => re.test(x.ad));
  const kaynak = {
    dolan: bul(/suresidolanlar/i),
    kalkan: bul(/gozgeckalkanlar/i),
    onlemsiz: bul(/onlemsizkapananlar/i),
  };
  for (const [ad, k] of Object.entries(kaynak))
    if (!k) throw new Error(`KIRMIZI: '${ad}' listesinin baglantisi sayfalarda bulunamadi - Bakanlik sayfa yapisi degismis olabilir.`);

  const kayit = [];
  const damga = {};
  for (const [ad, tip] of [['dolan', 'suresi-doldu'], ['kalkan', 'gozden-gecirmede-kalkti']]) {
    const buf = await dosya(kaynak[ad].url);
    const k = kayitlar(satirlariOku(buf), tip);
    kayit.push(...k);
    damga[ad] = { dosya: kaynak[ad].ad, bayt: buf.length, kayit: k.length };
  }

  /* onlemsiz kapananlar: eski .xls */
  let onlemsizKayit = [], onlemsizNot = '';
  const onlemsizBuf = await dosya(kaynak.onlemsiz.url);          // her kosuda indirilir: degisti mi gorulsun
  if (ONLEMSIZ_XLSX) {
    onlemsizKayit = kayitlar(satirlariOku(fs.readFileSync(ONLEMSIZ_XLSX)), 'onlemsiz-kapandi');
    onlemsizNot = 'yerelde xlsx-e cevrilmis dosyadan okundu';
  } else if (fs.existsSync(CIKTI)) {
    const eski = JSON.parse(fs.readFileSync(CIKTI, 'utf8').replace(/^﻿/, ''));
    onlemsizKayit = (eski.kayitlar || []).filter(x => x.tip === 'onlemsiz-kapandi');
    onlemsizNot = 'ESKI JSON KORUNDU (eski .xls bicimi burada acilamaz; yerelde Excel ile cevirip --onlemsiz ile ver)';
  } else {
    onlemsizNot = 'OKUNAMADI ve elde eski kayit da yok';
  }
  kayit.push(...onlemsizKayit);
  damga.onlemsiz = { dosya: kaynak.onlemsiz.ad, bayt: onlemsizBuf.length, kayit: onlemsizKayit.length, not: onlemsizNot };

  const cikti = {
    // 🔴 Bu uyari VERININ ICINDE durur ki kullanan her yerde gorunsun.
    uyari: 'Bu listeler Ticaret Bakanligi\'nin yayimladigi hallerdir ve FARKLI TARIHLERDE DAMGALIDIR; tamlik dogrulanmamistir. Oran/olasilik cikarilmaz, yalniz tekil gecmis olay soylenir.',
    damga,
    kayitlar: kayit,
  };
  fs.writeFileSync(CIKTI, JSON.stringify(cikti), 'utf8');

  const say = t => kayit.filter(x => x.tip === t).length;
  console.log('=== DAMPING GECMIS HASAT ===');
  for (const [ad, d] of Object.entries(damga)) console.log(`  ${ad.padEnd(9)} ${d.dosya}  (${d.bayt} bayt) -> ${d.kayit} kayit${d.not ? ' · ' + d.not : ''}`);
  console.log(`\n  suresi-doldu ${say('suresi-doldu')} · gozden-gecirmede-kalkti ${say('gozden-gecirmede-kalkti')} · onlemsiz-kapandi ${say('onlemsiz-kapandi')}`);
  console.log(`  TOPLAM ${kayit.length} kayit · ${new Set(kayit.map(x => x.m)).size} urun -> veri/damping-gecmis.json`);
})().catch(e => { console.error('KIRMIZI:', e.message); process.exit(1); });
