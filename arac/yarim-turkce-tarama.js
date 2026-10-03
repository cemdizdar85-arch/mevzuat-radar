#!/usr/bin/env node
// ============================================================================
//  YARIM TÜRKÇE / TÜRKÇE HARFSİZ KELİME TARAMASI (03.10.2026, Cem "1.2.3 üçünü de şimdi yap") · 0 USD · YALNIZ ÖLÇÜM
//  Sitedeki sorunun öğrencinin gördüğü açıklama alanlarında (sade, teshis, adimlar, kural, hap, aciklama, celdirici_yol, konuGiris,
//  tablo) kelime düzeyinde iki sınıf sayar. Korpus = yerel partilerin (veri/fabrika/kalip-parti-*.json) bütün metni.
//    Y1 YARIM TÜRKÇE : kelimede Türkçe harf VAR, ama harfleri ASCII'ye katlanınca korpusta ≥20 kat daha sık geçen BAŞKA bir
//                      Türkçe yazımla aynı ("borçunu"→"borcunu", "ıtiraz"→"itiraz", "wıll"→"will")
//    Y2 HARFSİZ      : kelime tamamen ASCII, korpusta aynı katlanmış biçimin Türkçe harfli yazımı ≥20 kat daha sık
//                      ("ogrenci"→"öğrenci", "ayni"→"aynı") — KAPI-TR'nin <60 karakter körlüğünü kapatır
//  Kelime korpusta ≤3 kez geçmeli (yaygın biçim kendi başına doğrudur); İngilizce stoplist ve belirsiz kelime listesi korunur
//  (kar/kâr, hala/hâlâ, tur/tür, bol/böl, asli, esasi, ucu, kara, asil, kati, on, is, su, ise, one, once — bağlama bağlı).
//  🚫 GÖRMEZ: korpusta Türkçe biçimi hiç ya da az geçen kelime · harf eklemesi/eksiği gerektiren yazım hatası ("kaliyla")
//     · kısaltma eki ("TTK'nin") · İngilizce cümle içindeki Türkçe kelime (İngilizce kelime gibi görünürse) · soru kökü/şıklar.
//  Kullanım: node arac/yarim-turkce-tarama.js --sinav | --kasa <sgs|smmm> [cikti.json]
//  Çıktı: kimlik + alan + kelime + öneri (soru metni YOK; depo public).
// ============================================================================
'use strict';
const fs = require('fs'), path = require('path'), https = require('https');
const KOK = path.resolve(__dirname, '..');
const ALAN = ['sade', 'teshis', 'adimlar', 'kural', 'hap', 'aciklama', 'celdirici_yol', 'konuGiris', 'tablo'];
const KELIME = /[A-Za-zÇĞİÖŞÜçğıöşüÂâÎîÛû]{3,}/g;
const KATLA = { ç: 'c', ğ: 'g', ı: 'i', ö: 'o', ş: 's', ü: 'u', â: 'a', î: 'i', û: 'u' };
const katla = w => w.replace(/[çğıöşüâîû]/g, c => KATLA[c]);
// Türkçe harf taşımayan kelime İngilizce küçültülür ("Information" → "information", tr ile "ınformation" olurdu)
// TÜMÜ BÜYÜK kelime Türkçe kuralla küçültülür ("KAZANIR" → "kazanır" doğru; en ile "kazanir" olup Y2 sanılıyordu — 03.10 ölçüldü, ajanlar 40+ yanlış alarm gördü)
const kucuk = w => (/[çğıöşüâîûÇĞİÖŞÜÂÎÛ]/.test(w) || (process.env.YT_MUTASYON !== 'buyuk-en' && w.length > 1 && w === w.toUpperCase())) ? w.toLocaleLowerCase('tr') : w.toLowerCase();
const KORU = new Set(['kar', 'kari', 'karin', 'kara', 'hala', 'tur', 'bol', 'asli', 'esasi', 'ucu', 'asil', 'kati', 'on', 'is', 'su', 'ise', 'one', 'once', 'sure', 'son', 'sik', 'ilan', 'tabi', 'hal', 'adet', 'hakim', 'dahil', 'mali', 'iste', 'alim', 'katip']);
const EN = new Set(['the', 'which', 'this', 'that', 'since', 'with', 'will', 'would', 'should', 'have', 'has', 'was', 'were', 'are', 'for', 'and', 'from', 'into', 'than', 'then', 'there', 'their', 'what', 'when', 'where', 'while', 'whose', 'who', 'whom', 'been', 'being', 'does', 'did', 'not', 'but', 'his', 'her', 'its', 'our', 'your', 'they', 'them', 'these', 'those', 'such', 'only', 'also', 'very', 'more', 'most', 'some', 'any', 'all', 'each', 'other', 'about', 'after', 'before', 'because', 'although', 'though', 'unless', 'until', 'though', 'might', 'must', 'can', 'could', 'may', 'shall']);
const yap = (x, o, yol) => { if (x == null) return; if (typeof x === 'string') o.push([yol, x]); else if (Array.isArray(x)) x.forEach((v, i) => yap(v, o, yol + '[' + i + ']')); else if (typeof x === 'object') for (const k in x) yap(x[k], o, yol + '.' + k); };

function korpusKur(kayitlar) {
  const frek = new Map();
  for (const q of kayitlar) { if (!q || typeof q !== 'object') continue; const o = []; for (const a of ALAN.concat(['soru', 'siklar'])) yap(q[a], o, a); for (const [, t] of o) for (const m of t.match(KELIME) || []) { const w = kucuk(m); frek.set(w, (frek.get(w) || 0) + 1); } }
  const enIyi = new Map(); for (const [w, n] of frek) { const k = katla(w); const e = enIyi.get(k); if (!e || n > e[1]) enIyi.set(k, [w, n]); }
  return { frek, enIyi };
}
function kelimeSinif(w, kor) {
  const k = kucuk(w); if (k.length < 4 || KORU.has(katla(k)) || EN.has(k)) return null;
  const n = kor.frek.get(k) || 0; if (n > 3) return null;
  const e = kor.enIyi.get(katla(k)); if (!e || e[0] === k || e[1] < 20 * Math.max(1, n)) return null;
  if (k.replace(/[âîû]/g, c => ({ â: 'a', î: 'i', û: 'u' })[c]) === e[0].replace(/[âîû]/g, c => ({ â: 'a', î: 'i', û: 'u' })[c])) return null;   // yalnız şapka farkı (azamî/azami) doğru
  const turkHarf = /[çğıöşüâîû]/.test(k);
  if (turkHarf) return { sinif: 'Y1', oneri: e[0] };
  if (/[çğıöşüâîû]/.test(e[0])) return { sinif: 'Y2', oneri: e[0] };
  return null;
}
function incele(q, kor) {
  const out = []; const o = []; for (const a of ALAN) yap(q[a], o, a);
  for (const [yol, t] of o) {
    const enAgir = (t.match(/\b[A-Za-z]+\b/g) || []).filter(w => EN.has(w.toLowerCase())).length >= 3;   // İngilizce cümle
    for (const m of t.match(KELIME) || []) { if (enAgir && !/[çğıöşüÇĞİÖŞÜ]/.test(m)) continue; const s = kelimeSinif(m, kor); if (s) out.push({ sinif: s.sinif, yol, kelime: m, oneri: s.oneri }); }
  }
  return out;
}
function partiler() {
  const d = path.join(KOK, 'veri', 'fabrika'); const r = {};
  for (const f of fs.readdirSync(d).filter(f => /^kalip-parti-.*\.json$/.test(f))) { try { r[f.slice(12, -5)] = JSON.parse(fs.readFileSync(path.join(d, f), 'utf8').replace(/^﻿/, '')); } catch (e) { } }
  return r;
}
function al(yol, key) { return new Promise((ok, no) => { https.get({ host: 'bjrleanjpyujtajmazxn.supabase.co', path: yol, headers: { apikey: key, Authorization: 'Bearer ' + key, 'User-Agent': 'mevzuat-radar-robot/1.0' } }, r => { let s = ''; r.setEncoding('utf8'); r.on('data', d => s += d); r.on('end', () => r.statusCode === 200 ? ok(JSON.parse(s)) : no(new Error(r.statusCode + ''))); }).on('error', no); }); }
async function kasa(sinav, cikti) {
  const key = process.env.SUPABASE_SERVICE_KEY; if (!key) { console.log('SUPABASE_SERVICE_KEY yok — kasa okunamaz (KÖR)'); process.exit(2); }
  const ids = []; for (let o = 0; ; o += 1000) { const p = await al(`/rest/v1/paket_soru?select=id&sinav=eq.${sinav}&order=id&limit=1000&offset=${o}`, key); ids.push(...p.map(x => x.id)); if (p.length < 1000) break; }
  const P = partiler(); const tum = []; for (const e in P) for (const k in P[e]) tum.push(P[e][k]); const kor = korpusKur(tum);
  const retY = path.join(KOK, 'veri', 'sinav', sinav + '-elle-ret.json'); const ret = new Set(fs.existsSync(retY) ? Object.keys(JSON.parse(fs.readFileSync(retY, 'utf8').replace(/^﻿/, '')).kayitlar) : []);
  const sonuc = []; let kor_ = 0, rette = 0; const say = { Y1: 0, Y2: 0 };
  for (const id of ids) { if (ret.has(id)) { rette++; continue; } const [e, kp] = id.split('/'); const q = P[e] && P[e][kp]; if (!q) { kor_++; continue; } const b = incele(q, kor); if (b.length) { sonuc.push({ anahtar: id, bulgular: b }); for (const x of b) say[x.sinif]++; } }
  const soruY = s => sonuc.filter(x => x.bulgular.some(b => b.sinif === s)).length;
  if (cikti) fs.writeFileSync(cikti, JSON.stringify(sonuc, null, 1));
  console.log(`YARIM-TR kasa (${sinav}): kasada ${ids.length} · elle rette ${rette} · KÖR (yerel partide yok) ${kor_} · Y1 yarım Türkçe ${soruY('Y1')} soru / ${say.Y1} kelime · Y2 harfsiz ${soruY('Y2')} soru / ${say.Y2} kelime`);
}
function sinav() {
  const kor = korpusKur([].concat(
    Array(30).fill({ sade: { dogru: 'öğrenci aynı borcunu itiraz işçi geçmişe boşluğun will kazanır' } }),
    Array(30).fill({ sade: { dogru: 'kâr hâlâ tür esası katı' } }),
    Array(30).fill({ sade: { dogru: 'çase' } })));   // yapay: İngilizce 'case' kelimesinin korpusta Türkçe harfli ikizi olsun (İngilizce korumasını sınar)
  const vakalar = [
    ['Y1 borçunu → borcunu', { sade: { dogru: 'borçunu öder' } }, 'Y1'],
    ['Y1 ıtiraz → itiraz', { teshis: { A: { gercek: 'ıtiraz eder' } } }, 'Y1'],
    ['Y1 wıll → will (İngilizce kelimede ı)', { sade: { dogru: 'He wıll go' } }, 'Y1'],
    ['Y2 ogrenci → öğrenci', { hap: 'ogrenci okur' }, 'Y2'],
    ['Y2 kısa dize (KAPI-TR <60 körlüğü)', { aciklama: { A: 'ayni' } }, 'Y2'],
    ['doğru Türkçe → alarm yok', { sade: { dogru: 'öğrenci aynı borcunu öder' } }, null],
    ['belirsiz esasi/kati korunur (Kanun-i Esasi, kati sure)', { sade: { dogru: 'esasi kati' } }, null],
    ['İngilizce cümle korunur (case, korpusta çase var)', { sade: { dogru: 'which will be the case that has gone' } }, null],
    ['TÜMÜ BÜYÜK doğru Türkçe (KAZANIR) Y2 sayılmaz', { sade: { dogru: 'KAZANIR' } }, null],
    ['TÜMÜ BÜYÜK yanlış (OGRENCI) yine Y1/Y2 yakalanır', { sade: { dogru: 'OGRENCI' } }, 'Y1'],
    ['İngilizce büyük harfli kelime (Information) Y1 sayılmaz', { sade: { dogru: 'Information çase' } }, null],
    ['yalnız şapka farkı (azamî) alarm vermez', { sade: { dogru: 'azamî' } }, null],
    ['soru kökü taranmaz', { soru: 'ogrenci ayni', sade: { dogru: 'öğrenci' } }, null],
    ['sık geçen yazım (korpusta >3) alarm vermez', { sade: { dogru: 'öğrenci' } }, null],
  ];
  const MUT = process.env.YT_MUTASYON || '';
  let gecen = 0;
  for (const [ad, q, bek] of vakalar) {
    let b = incele(q, kor);
    if (MUT === 'y1-kapali') b = b.filter(x => x.sinif !== 'Y1');
    if (MUT === 'y2-kapali') b = b.filter(x => x.sinif !== 'Y2');
    if (MUT === 'koru-yok') { KORU.clear(); b = incele(q, kor); }
    if (MUT === 'en-yok') { EN.clear(); b = incele(q, kor); }
    if (MUT === 'alan-kok') { ALAN.push('soru'); b = incele(q, kor); ALAN.pop(); }
    const c = b.length ? b[0].sinif : null;
    if (c === bek) { gecen++; if (!MUT) console.log('  ✓ ' + ad); } else if (!MUT) console.log('  ✗ ' + ad + ' — beklenen ' + bek + ', çıkan ' + c);
  }
  const ok = gecen === vakalar.length;
  if (!MUT) console.log(`YARIM-TR ÖZ-SINAVI ${ok ? 'YEŞİL' : 'KIRMIZI'} (${gecen}/${vakalar.length})`);
  return ok;
}
if (require.main === module) {
  const [a, b, c] = process.argv.slice(2);
  if (a === '--sinav') {
    if (process.argv.includes('--mutasyon')) {
      if (!sinav()) process.exit(1);
      const cp = require('child_process'); const M = ['y1-kapali', 'y2-kapali', 'koru-yok', 'en-yok', 'alan-kok', 'buyuk-en']; let k = 0;
      for (const m of M) { const r = cp.spawnSync(process.execPath, [__filename, '--sinav'], { env: Object.assign({}, process.env, { YT_MUTASYON: m }), encoding: 'utf8' }); if (r.status !== 0) { k++; console.log('  mutasyon ' + m + ' KIRMIZI (doğru)'); } else console.log('  mutasyon ' + m + ' YEŞİL (YANLIŞ)'); }
      console.log(`MUTASYON: ${k}/${M.length} mutasyon KIRMIZI`); process.exit(k === M.length ? 0 : 1);
    }
    process.exit(sinav() ? 0 : 1);
  } else if (a === '--kasa') kasa(b || 'sgs', c).catch(e => { console.log('kasa hatası: ' + e.message); process.exit(2); });
  else { console.log('--sinav [--mutasyon] | --kasa <sgs|smmm> [cikti.json]'); process.exit(2); }
}
module.exports = { incele, korpusKur, kelimeSinif };
