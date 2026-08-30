#!/usr/bin/env node
/* ============================================================================
 *  XLSX COK-SATIRLI HUCRE TARAMASI  (30.08.2026)
 *
 *  NEDEN VAR: damping-hasat.ps1'in paylasilan-metin okuyucusundaki
 *  '<t[^>]*>(.*?)</t>' kalibinda (?s) YOKTU. .NET'te (?s) olmadan nokta yeni
 *  satiri tutmaz -> COK SATIRLI hucreler BOS okunur. Bu tek karakter yuzunden
 *  273 satirlik resmi damping listesinden 141 kayit hasat ediliyordu.
 *  AYNI KALIP 8 hasatcida daha duruyordu. "Ayni hata baska yerde de var mi?"
 *  sorusu TAHMINLE degil OLCUMLE cevaplanir - bu betik o olcumu yapar.
 *
 *  NE OLCER: her xlsx icin
 *    - paylasilan metin (si) sayisi, kacinda yeni satir var
 *    - VERI HUCRELERINDEN kaci o cok satirli metinlere isaret ediyor
 *      (asil risk olcusu: cok satirli si dosyada durur ama hic bir hucre onu
 *       kullanmiyorsa kayip da yoktur)
 *    - kayip hucrelerin sutunlari + ornek icerik
 *
 *  Kullanim:
 *    node motor/xlsx-coksatir-tarama.js <klasor|dosya> [<klasor|dosya> ...]
 *  Cikti: konsol ozeti + motor/cikti/xlsx-coksatir.json
 * ==========================================================================*/
'use strict';
const fs = require('fs'), path = require('path'), zlib = require('zlib');

const KOK = path.resolve(__dirname, '..');
const CIKTI_DIR = path.join(KOK, 'motor', 'cikti');

function zipGirdileri(buf) {
  let eocd = -1;
  for (let i = buf.length - 22; i >= 0; i--) { if (buf.readUInt32LE(i) === 0x06054b50) { eocd = i; break; } }
  if (eocd < 0) throw new Error('zip dizini yok');
  const adet = buf.readUInt16LE(eocd + 10), cdOff = buf.readUInt32LE(eocd + 16);
  let p = cdOff; const out = {};
  for (let k = 0; k < adet; k++) {
    const yontem = buf.readUInt16LE(p + 10), csize = buf.readUInt32LE(p + 20);
    const nl = buf.readUInt16LE(p + 28), el = buf.readUInt16LE(p + 30), cl = buf.readUInt16LE(p + 32);
    const lho = buf.readUInt32LE(p + 42);
    const ad = buf.toString('utf8', p + 46, p + 46 + nl);
    const lnl = buf.readUInt16LE(lho + 26), lel = buf.readUInt16LE(lho + 28);
    const bas = lho + 30 + lnl + lel;
    const ham = buf.subarray(bas, bas + csize);
    out[ad] = yontem === 0 ? ham : zlib.inflateRawSync(ham);
    p += 46 + nl + el + cl;
  }
  return out;
}

function tara(dosya) {
  const z = zipGirdileri(fs.readFileSync(dosya));
  const ss = z['xl/sharedStrings.xml'];
  const sonuc = { dosya: path.basename(dosya), si: 0, cokSatirliSi: 0, riskliHucre: 0, sutunlar: {}, ornek: [] };
  if (!ss) return sonuc;

  // paylasilan metinler: (?s) ESDEGERI [\s\S] ile - dogru okuma
  const metinler = [];
  for (const m of ss.toString('utf8').matchAll(/<si>([\s\S]*?)<\/si>/g))
    metinler.push([...m[1].matchAll(/<t[^>]*>([\s\S]*?)<\/t>/g)].map(x => x[1]).join(''));
  sonuc.si = metinler.length;

  const cokSatirli = new Set();
  metinler.forEach((t, i) => { if (/\r|\n|&#10;|_x000D_/.test(t)) { cokSatirli.add(i); } });
  sonuc.cokSatirliSi = cokSatirli.size;
  if (!cokSatirli.size) return sonuc;

  // hangi hucreler o metinlere bakiyor? (t="s" olan hucrenin <v> degeri si indeksidir)
  for (const ad of Object.keys(z).filter(k => /^xl\/worksheets\/sheet\d+\.xml$/.test(k))) {
    const xml = z[ad].toString('utf8');
    for (const c of xml.matchAll(/<c r="([A-Z]+)(\d+)"([^>]*)>([\s\S]*?)<\/c>/g)) {
      if (!/t="s"/.test(c[3])) continue;
      const v = (c[4].match(/<v>(\d+)<\/v>/) || [])[1];
      if (v === undefined || !cokSatirli.has(+v)) continue;
      sonuc.riskliHucre++;
      const kol = c[1];
      sonuc.sutunlar[kol] = (sonuc.sutunlar[kol] || 0) + 1;
      if (sonuc.ornek.length < 3)
        sonuc.ornek.push({ hucre: kol + c[2], sayfa: ad.replace('xl/worksheets/', ''), metin: metinler[+v].replace(/[\r\n]+/g, ' ⏎ ').slice(0, 90) });
    }
  }
  return sonuc;
}

/* ------------------------------------------------------------------- ANA */
const hedefler = process.argv.slice(2);
if (!hedefler.length) { console.error('Kullanim: node motor/xlsx-coksatir-tarama.js <klasor|dosya> ...'); process.exit(1); }

const dosyalar = [];
for (const h of hedefler) {
  const st = fs.statSync(h);
  if (st.isDirectory()) {
    const gez = d => fs.readdirSync(d, { withFileTypes: true }).forEach(e => {
      const p = path.join(d, e.name);
      if (e.isDirectory()) gez(p); else if (/\.xlsx$/i.test(e.name)) dosyalar.push(p);
    });
    gez(h);
  } else if (/\.xlsx$/i.test(h)) dosyalar.push(h);
}

const rapor = { taranan: dosyalar.length, kirli: [], temiz: [] };
for (const d of dosyalar.sort()) {
  let s; try { s = tara(d); } catch (e) { rapor.kirli.push({ dosya: path.basename(d), hata: e.message }); continue; }
  (s.riskliHucre > 0 ? rapor.kirli : rapor.temiz).push(s);
}

fs.mkdirSync(CIKTI_DIR, { recursive: true });
fs.writeFileSync(path.join(CIKTI_DIR, 'xlsx-coksatir.json'), JSON.stringify(rapor, null, 1), 'utf8');

console.log('=== XLSX COK-SATIRLI HUCRE TARAMASI ===');
console.log(`taranan dosya: ${rapor.taranan} · riskli: ${rapor.kirli.length} · temiz: ${rapor.temiz.length}\n`);
for (const s of rapor.kirli) {
  if (s.hata) { console.log(`  ⚠ ${s.dosya}: OKUNAMADI (${s.hata})`); continue; }
  console.log(`  🔴 ${s.dosya}`);
  console.log(`     cok satirli metin: ${s.cokSatirliSi}/${s.si} · (?s) olmadan BOS donecek hucre: ${s.riskliHucre}`);
  console.log(`     sutunlar: ${JSON.stringify(s.sutunlar)}`);
  s.ornek.forEach(o => console.log(`     ornek ${o.hucre}: ${o.metin}`));
}
if (rapor.temiz.length) {
  console.log('\n  ✅ TEMIZ (tek satirli hucre; (?s) olmadan da kayip yok):');
  rapor.temiz.forEach(s => console.log(`     ${s.dosya}  (si ${s.si}, cok satirli ${s.cokSatirliSi}, riskli hucre 0)`));
}
console.log('\nRapor -> motor/cikti/xlsx-coksatir.json');
