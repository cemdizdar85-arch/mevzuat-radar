#!/usr/bin/env node
// ============================================================================
//  KAYNAK ADI TAŞIMA — soru kayıtlarının kaynak_adlar alanında ESKİ madde adını YENİ adla değiştirir
//  (31.10.2026, Cem onayı: "34 sorunun kaynak bağı"). BEDEL 0 (model yok; yalnız ambar okuma/yazma).
//
//  NİYE: motor/mevzuat-yut.ps1 başlık deseni (31.10 onarımı) önceki maddenin son cümlesini sonraki maddenin ADINA
//  yapıştırıyordu ("KDVK (3065 s.K.) m.45 - Tarhiyata muhatap tutulurlar. Tarh zamanı"). Kaynak yeniden yutulunca bu
//  adlar ambardan kalkar; kayıtların kaynak_adlar alanı boşa düşer. Bu araç eşleme dosyasındaki {eski: yeni} çiftlerini uygular.
//  YAZIM (smmm-model-izi-temizle / smmm-ah-yalniz kalıbı): damga oku → YALNIZ kp.kaynak_adlar[i] değerleri değişir (fark
//   denetimi; başka yol değişirse DURUR) → yazmadan hemen önce damga yeniden → KOŞULLU yazım (PATCH …&guncelleme=eq.<damga>)
//   → geri okuma, kanonik birebir. Damga değiştiyse YAZILMAZ (yarış). Bulutta koşan partiler (arac/bulut-kosan-etiketler.ps1 -Kati) ATLANIR.
//  Komutlar:
//    node arac/kaynak-adi-tasi.js --kuru  <esleme.json>    kaç parti/kayıt/ad değişecek, bulutta koşan (yazma yok)
//    node arac/kaynak-adi-tasi.js --yaz   <esleme.json> [--cikti f]
//    node arac/kaynak-adi-tasi.js --sinav                  öz-sınav (sahte ambar, ağ yok)
//  esleme.json: { "esleme": { "<eski kaynak_ad>": "<yeni kaynak_ad>", ... } }  — yeni adın ambarda var olduğu yazmadan ÖNCE denetlenir.
//  🚫 GÖRMEZ: kaynak_adlar dışındaki alanlarda (dayanak, kaynak_metin_ozet, açıklama) geçen eski ad · smmm- dışı partiler ·
//    yerel veri/fabrika kopyalarının eskimesi (teslimden önce parti-senkron -Indir).
// ============================================================================
'use strict';
const fs = require('fs'), path = require('path'), cp = require('child_process');
const KOK = path.resolve(__dirname, '..');
const TABAN = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1';
const MUT = process.env.KAYNAK_TASI_MUTASYON || '';
const kan = v => Array.isArray(v) ? v.map(kan) : (v && typeof v === 'object') ? Object.keys(v).sort().reduce((o, k) => (o[k] = kan(v[k]), o), {}) : v;
const esit = (a, b) => JSON.stringify(kan(a)) === JSON.stringify(kan(b));
function fark(a, b, p = '', out = []) {
  if (esit(a, b)) return out;
  if (a && b && typeof a === 'object' && typeof b === 'object' && Array.isArray(a) === Array.isArray(b)) {
    for (const k of new Set([...Object.keys(a), ...Object.keys(b)])) fark(a[k], b[k], p ? (Array.isArray(a) ? `${p}[${k}]` : `${p}.${k}`) : k, out);
  } else out.push(p);
  return out;
}
const anahtar = () => { const v = (process.env.SUPABASE_SERVICE_KEY || '').trim(); if (v) return v; if (process.platform !== 'win32') return '';
  return (cp.spawnSync('powershell', ['-NoProfile', '-Command', "[Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User')"], { encoding: 'utf8' }).stdout || '').trim(); };
function gercekIO() {
  let K = null; const bas = () => { if (K === null) K = anahtar(); if (!K) throw new Error('SUPABASE_SERVICE_KEY yok'); return { apikey: K, Authorization: 'Bearer ' + K, 'User-Agent': 'mevzuat-radar-robot/1.0', Accept: 'application/json' }; };
  const al = async (u, opt = {}) => { for (let d = 1; d <= 3; d++) { try { const r = await fetch(u, { ...opt, headers: { ...bas(), ...(opt.headers || {}) }, signal: AbortSignal.timeout(180000) }); if (!r.ok) throw new Error('ambar ' + r.status + ' ' + (await r.text()).slice(0, 200)); return r; } catch (e) { if (d === 3) throw e; await new Promise(z => setTimeout(z, 2000 * d)); } } };
  return {
    async etiketler() { const out = []; for (let off = 0; ; off += 1000) { const r = await (await al(`${TABAN}/kalip_parti?select=etiket&etiket=like.smmm-*&order=etiket.asc&limit=1000&offset=${off}`)).json(); for (const x of r) if (!String(x.etiket).includes('/')) out.push(x.etiket); if (r.length < 1000) break; } return out; },
    async ambarSatir(e) { const r = await al(`${TABAN}/kalip_parti?select=icerik,guncelleme&etiket=eq.${encodeURIComponent(e)}`); const row = (await r.json())[0]; if (!row) return null;
      return { icerik: typeof row.icerik === 'string' ? JSON.parse(row.icerik) : (row.icerik || {}), guncelleme: String(row.guncelleme) }; },
    async damga(e) { const r = await al(`${TABAN}/kalip_parti?select=guncelleme&etiket=eq.${encodeURIComponent(e)}`); const row = (await r.json())[0]; return row ? String(row.guncelleme) : null; },
    async kosulluYaz(e, damga, icerik) {
      const r = await al(`${TABAN}/kalip_parti?etiket=eq.${encodeURIComponent(e)}&guncelleme=eq.${encodeURIComponent(damga)}&select=guncelleme`, { method: 'PATCH',
        headers: { 'Content-Type': 'application/json; charset=utf-8', Prefer: 'return=representation' }, body: JSON.stringify({ icerik, yazan: 'kaynak-adi-tasi-yerel' }) });
      return { satir: (await r.json()).length }; },
    async adVar(ad) { const r = await al(`${TABAN}/dokumanlar?select=id&kaynak_ad=eq.${encodeURIComponent(ad)}&limit=1`); return (await r.json()).length > 0; },
    kosan() { const r = cp.spawnSync('powershell', ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', path.join(KOK, 'arac', 'bulut-kosan-etiketler.ps1'), '-Kati'], { cwd: KOK, encoding: 'utf8' });
      if (r.status !== 0) throw new Error('bulut-kosan-etiketler düştü — yazan araç bekler: ' + (r.stderr || '').slice(0, 200));
      return new Set((r.stdout || '').split(/\s+/).filter(Boolean)); },
  };
}
function sahteIO(P, kosanListe = [], adlar = null) {
  const sira = {}; const dmg = e => { const j = P[e]; if (!Array.isArray(j.guncelleme_sira)) return j.guncelleme; const n = sira[e] = (sira[e] || 0); sira[e]++; return j.guncelleme_sira[Math.min(n, j.guncelleme_sira.length - 1)]; };
  const io = { yazilan: [],
    async etiketler() { return Object.keys(P).filter(e => /^smmm-/.test(e)).sort(); },
    async ambarSatir(e) { if (!P[e]) return null; return { icerik: JSON.parse(JSON.stringify(P[e].icerik)), guncelleme: dmg(e) }; },
    async damga(e) { return P[e] ? dmg(e) : null; },
    async kosulluYaz(e, d, ic) { const j = P[e]; const simdi = Array.isArray(j.guncelleme_sira) ? j.guncelleme_sira[Math.min((sira[e] || 1) - 1, j.guncelleme_sira.length - 1)] : j.guncelleme;
      if (simdi !== d) return { satir: 0 }; j.icerik = JSON.parse(JSON.stringify(ic)); delete j.guncelleme_sira; j.guncelleme = 'y' + (io.yazilan.length + 1); io.yazilan.push(e); return { satir: 1 }; },
    async adVar(ad) { return adlar ? adlar.includes(ad) : true; },
    kosan() { return new Set(kosanListe); } };
  return io;
}
async function havuz(isler, n, fn) { let i = 0; await Promise.all(Array.from({ length: n }, async () => { while (i < isler.length) { const j = i++; await fn(isler[j], j); } })); }

async function tasi(io, esleme, opt = {}) {
  const r = { parti_toplam: 0, degisecek: { parti: 0, kayit: 0, ad: 0 }, kimlik: [], ad_sayim: {}, atlanan_kosan: [], yazilan: [], yaris: [], uyusmaz: [], hata: [], yeni_ad_yok: [] };
  for (const y of new Set(Object.values(esleme))) if (!(await io.adVar(y))) r.yeni_ad_yok.push(y);
  if (r.yeni_ad_yok.length) { r.hata.push('yeni ad ambarda yok: ' + r.yeni_ad_yok.length + ' — HİÇBİR ŞEY yazılmadı'); return r; }
  const ets = await io.etiketler(); r.parti_toplam = ets.length; const satir = {};
  await havuz(ets, opt.paralel || 6, async e => { const A = await io.ambarSatir(e); if (!A) return; const iz = [];
    for (const [kp, k] of Object.entries(A.icerik || {})) { if (!k || !Array.isArray(k.kaynak_adlar)) continue; k.kaynak_adlar.forEach((a, i) => { if (Object.prototype.hasOwnProperty.call(esleme, a)) iz.push({ kp, i, eski: a, yeni: esleme[a] }); }); }
    if (iz.length) satir[e] = { A, iz }; });
  const kosan = io.kosan();
  for (const [e, { A, iz }] of Object.entries(satir).sort()) {
    if (kosan.has(e)) { r.atlanan_kosan.push(e + ' (' + [...new Set(iz.map(x => x.kp))].join(',') + ')'); continue; }
    r.degisecek.parti++; r.degisecek.kayit += new Set(iz.map(x => x.kp)).size; r.degisecek.ad += iz.length;
    for (const x of iz) { r.ad_sayim[x.eski] = (r.ad_sayim[x.eski] || 0) + 1; } for (const kp of new Set(iz.map(x => x.kp))) r.kimlik.push(e + '/' + kp);
    if (!opt.yaz) continue;
    const yeni = JSON.parse(JSON.stringify(A.icerik)); for (const x of iz) yeni[x.kp].kaynak_adlar[x.i] = x.yeni;
    if (MUT === 'baska-alan') { const kp0 = iz[0].kp; yeni[kp0].soru = String(yeni[kp0].soru || '') + ' '; }
    const izinli = new Set(iz.map(x => `${x.kp}.kaynak_adlar[${x.i}]`)); const fk = fark(A.icerik, yeni); const izinsiz = fk.filter(y => !izinli.has(y));
    if (izinsiz.length || fk.length !== izinli.size) { r.hata.push(`${e}: beklenmeyen fark (${izinsiz.length} yol)`); continue; }
    const d2 = await io.damga(e); if (d2 !== A.guncelleme) { r.yaris.push(e); continue; }
    const w = await io.kosulluYaz(e, A.guncelleme, yeni); if (w.satir !== 1) { r.yaris.push(e); continue; }
    const G = await io.ambarSatir(e); if (G && esit(G.icerik, yeni)) r.yazilan.push(e); else r.uyusmaz.push(e);
  }
  return r;
}

async function sinav() {
  let ok = 0, top = 0; const S = (ad, g) => { top++; if (g) ok++; console.log((g ? '  ✓ ' : '  ✗ ') + ad); };
  const E = { 'K m.45 - Kirli. Tarh zamanı': 'K m.45 - Tarh zamanı' };
  const P = () => ({ 'smmm-a': { guncelleme: 'd1', icerik: { 'kp-01': { soru: 'S', kaynak_adlar: ['K m.44 - X', 'K m.45 - Kirli. Tarh zamanı'], dayanak: 'K m.45 - Kirli. Tarh zamanı' }, 'kp-02': { soru: 'T', kaynak_adlar: ['K m.1'] } } },
    'smmm-b': { guncelleme: 'd1', icerik: { 'kp-01': { soru: 'U', kaynak_adlar: ['K m.45 - Kirli. Tarh zamanı'] } } },
    'smmm-c': { guncelleme_sira: ['d1', 'd2'], icerik: { 'kp-03': { soru: 'V', kaynak_adlar: ['K m.45 - Kirli. Tarh zamanı'] } } },
    'smmm-d': { guncelleme: 'd1', icerik: { 'kp-04': { soru: 'W', kaynak_adlar: ['K m.45 - Kirli. Tarh zamanı'] } } } });
  { const p = P(); const io = sahteIO(p, ['smmm-d']); const k = await tasi(io, E);
    S('KURU: 3 parti / 3 kayıt / 3 ad değişecek, koşan smmm-d atlandı, 0 yazma', k.degisecek.parti === 3 && k.degisecek.ad === 3 && k.atlanan_kosan.length === 1 && io.yazilan.length === 0); }
  { const p = P(); const io = sahteIO(p, ['smmm-d']); const w = await tasi(io, E, { yaz: true });
    S('YAZ: a ve b yazıldı, c YARIŞ (damga değişti), d bulutta', w.yazilan.join() === 'smmm-a,smmm-b' && w.yaris.join() === 'smmm-c' && p['smmm-d'].guncelleme === 'd1');
    S('YAZ: yalnız kaynak_adlar değişti; dayanak ve öteki adlar AYNI', p['smmm-a'].icerik['kp-01'].kaynak_adlar.join('|') === 'K m.44 - X|K m.45 - Tarh zamanı' && p['smmm-a'].icerik['kp-01'].dayanak === 'K m.45 - Kirli. Tarh zamanı' && p['smmm-a'].icerik['kp-02'].kaynak_adlar.join() === 'K m.1'); }
  { const p = P(); const io = sahteIO(p, [], []); const w = await tasi(io, E, { yaz: true });
    S('Yeni ad ambarda YOKSA hiçbir şey yazılmaz', io.yazilan.length === 0 && w.yeni_ad_yok.length === 1); }
  { process.env.KAYNAK_TASI_MUTASYON = ''; }
  console.log(`ÖZ-SINAV ${ok}/${top}`); return ok === top;
}

(async () => {
  const kip = process.argv[2];
  if (kip === '--sinav') { const g = await sinav();
    if (!MUT) { const c = cp.spawnSync(process.execPath, [__filename, '--sinav'], { env: { ...process.env, KAYNAK_TASI_MUTASYON: 'baska-alan' }, encoding: 'utf8' });
      const yakalandi = /✗ YAZ: yalnız kaynak_adlar|✗ YAZ: a ve b/.test(c.stdout); console.log((yakalandi ? '  ✓ ' : '  ✗ ') + 'MUTASYON baska-alan (soru da değişiyor) YAKALANDI'); process.exit(g && yakalandi ? 0 : 1); }
    process.exit(g ? 0 : 1); }
  if (kip !== '--kuru' && kip !== '--yaz') { console.error('kullanım: --kuru|--yaz <esleme.json> | --sinav'); process.exit(2); }
  const esleme = JSON.parse(fs.readFileSync(process.argv[3], 'utf8').replace(/^﻿/, '')).esleme;
  const r = await tasi(gercekIO(), esleme, { yaz: kip === '--yaz' });
  console.log(`parti ${r.parti_toplam} · değişecek parti ${r.degisecek.parti} · kayıt ${r.degisecek.kayit} · ad ${r.degisecek.ad} · bulutta koşan atlanan ${r.atlanan_kosan.length}`);
  for (const [a, n] of Object.entries(r.ad_sayim)) console.log(`  ${n} × ${a}`);
  if (r.atlanan_kosan.length) console.log('  BULUTTA (sonraki tur): ' + r.atlanan_kosan.join(', '));
  if (kip === '--yaz') console.log(`yazılan ${r.yazilan.length} · yarış ${r.yaris.length} ${r.yaris.join(',')} · geri okuma uyuşmaz ${r.uyusmaz.length} · hata ${r.hata.length} ${r.hata.join('; ')}`);
  else if (r.hata.length) console.log('HATA: ' + r.hata.join('; '));
  const i = process.argv.indexOf('--cikti'); if (i > 0) fs.writeFileSync(process.argv[i + 1], JSON.stringify({ zaman: new Date().toISOString(), ...r }, null, 1));
  process.exit(r.hata.length || r.uyusmaz.length ? 1 : 0);
})();
