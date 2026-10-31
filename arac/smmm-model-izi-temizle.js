#!/usr/bin/env node
// ============================================================================
//  SMMM AMBAR — MODEL ADI İZİ TEMİZLİĞİ (31.10.2026, Cem: "düzeltilmeyen alanlarda kalan model adlarını da temizle; sitedeki bitirme
//  sorularında model adı 0 olmalı, ölç ve sayıyı yaz." · CLAUDE.md "veriye model adı girmez")   BEDEL 0 (model yok; yalnız ambar okuma/yazma)
//
//  NİYE: parti-senkron -Yukle 10.10'dan beri ambara giden metinde "model":"claude-…" değerini nötr koda çeviriyor; o tarihten sonra
//  YENİDEN YÜKLENMEYEN partilerde (ve yükleyiciyi atlayan yazıcılarda) alt alanlarda (sade.model, …) gerçek ad kalmış olabilir.
//  arac/model-izi-olc.js yalnız YEREL önbelleği ölçer; bu araç AMBARI (kalip_parti, etiket smmm-*) ölçer ve temizler.
//
//  KÜME: anahtarı tam "model" ya da "*_model" olan, değeri metin olan ve kelime sınırlı claude|sonnet|haiku|opus|anthropic|gpt|gemini
//   geçen alan ("geminin" gibi Türkçe sözcük sayılmaz). Eşleme motor/model-kod.ps1 ModelKod'dan OKUNUR (powershell/pwsh ile aynı işlev
//   çağrılır, kopya yok). ModelKod'un çevirmediği değer (claude- ile başlamayan: gpt-…, gemini-…) DEĞİŞTİRİLMEZ, 'eşlemesiz' sayılır.
//  YAZIM (onarım hattı / smmm-ah-yalniz kapısı): damga oku → yalnız bu alanların değeri değişir (fark denetimi; başka yol değişirse DURUR)
//   → yazmadan hemen önce damga yeniden → KOŞULLU yazım (PATCH …&guncelleme=eq.<damga>) → geri okuma, kanonik birebir.
//   Damga değiştiyse o parti YAZILMAZ (başka yazan var — sonraki tur). Bulutta koşan partiler (arac/bulut-kosan-etiketler.ps1 -Kati) ATLANIR.
//  Komutlar:
//    node arac/smmm-model-izi-temizle.js --olc            ambarı ölçer (parti / kayıt / alan sayısı + değer dağılımı; kayıt metni BASILMAZ)
//    node arac/smmm-model-izi-temizle.js --kuru           + eşleme + bulutta koşan: kaç parti/kayıt/alan değişecek (yazma yok)
//    node arac/smmm-model-izi-temizle.js --yaz [--cikti f] yazar; değişen etiketler listesi --cikti dosyasına (yerel kopyalar eskir!)
//    node arac/smmm-model-izi-temizle.js --sinav          öz-sınav (sahte ambar, ağ yok)
//  🚫 GÖRMEZ: anahtar ADINDA model (simulasyon_sonnet — 30+ okuyan, ayrı iş) · düz metin içinde geçen ad · smmm- dışı partiler ·
//    yazımdan sonra yerel veri/fabrika kopyalarının eskimesi (teslimden önce parti-senkron -Indir gerekir — tazelik kapısı durdurur).
// ============================================================================
'use strict';
const fs = require('fs'), path = require('path'), os = require('os'), cp = require('child_process');
const KOK = path.resolve(__dirname, '..');
const TABAN = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1';
const MUT = process.env.MODEL_TEMIZ_MUTASYON || '';
const RX = /\b(claude|sonnet|haiku|opus|anthropic|gpt|gemini)\b/i;
const modelAnahtari = k => k === 'model' || /_model$/.test(k);
const kan = v => Array.isArray(v) ? v.map(kan) : (v && typeof v === 'object') ? Object.keys(v).sort().reduce((o, k) => (o[k] = kan(v[k]), o), {}) : v;
const esit = (a, b) => JSON.stringify(kan(a)) === JSON.stringify(kan(b));
function fark(a, b, p = '', out = []) {
  if (esit(a, b)) return out;
  if (a && b && typeof a === 'object' && typeof b === 'object' && Array.isArray(a) === Array.isArray(b)) {
    for (const k of new Set([...Object.keys(a), ...Object.keys(b)])) fark(a[k], b[k], p ? (Array.isArray(a) ? `${p}[${k}]` : `${p}.${k}`) : k, out);
  } else out.push(p);
  return out;
}
// bir partide izli alanlar: [{yol, kp, deger}]
function izler(icerik) {
  const out = [];
  const gez = (o, yol, kp) => { if (!o || typeof o !== 'object') return;
    if (Array.isArray(o)) { o.forEach((x, i) => gez(x, `${yol}[${i}]`, kp)); return; }
    for (const [k, v] of Object.entries(o)) { const y = yol ? `${yol}.${k}` : k;
      if (typeof v === 'string') { if (modelAnahtari(k) && RX.test(v)) out.push({ yol: y, kp, deger: v }); }
      else gez(v, y, kp); } };
  for (const [kp, v] of Object.entries(icerik || {})) gez(v, kp, kp);
  return out;
}
const yolKoy = (o, y, v) => { const p = y.split(/[.[\]]/).filter(Boolean); const son = p.pop(); const h = p.reduce((a, k) => a[k], o); h[son] = v; };
// Eşleme motor/model-kod.ps1 ModelKod'dan (aynı işlev; kopya yok)
function eslemeAl(degerler) {
  if (!degerler.length) return {};
  const tmp = path.join(os.tmpdir(), `model-kod-${process.pid}.json`); fs.writeFileSync(tmp, JSON.stringify(degerler));
  const ps = process.platform === 'win32' ? 'powershell' : 'pwsh';
  const kmt = `$ErrorActionPreference='Stop'; . '${path.join(KOK, 'motor', 'model-kod.ps1').replace(/'/g, "''")}'; $l = [IO.File]::ReadAllText('${tmp.replace(/'/g, "''")}') | ConvertFrom-Json; $h = [ordered]@{}; foreach($d in $l){ $h["$d"] = (ModelKod "$d") }; [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false); ConvertTo-Json -InputObject $h -Compress`;
  const r = cp.spawnSync(ps, ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', kmt], { encoding: 'utf8' }); try { fs.unlinkSync(tmp); } catch (x) { }
  if (r.status !== 0) throw new Error('ModelKod çağrılamadı: ' + (r.stderr || '').slice(0, 200));
  const j = JSON.parse(r.stdout.trim()); if (MUT === 'esleme-bozuk') for (const k of Object.keys(j)) j[k] = 'bozuk';
  return j;
}

// ---------------------------------------------------------------- IO
const anahtar = () => { const v = (process.env.SUPABASE_SERVICE_KEY || '').trim(); if (v) return v; if (process.platform !== 'win32') return '';
  return (cp.spawnSync('powershell', ['-NoProfile', '-Command', "[Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User')"], { encoding: 'utf8' }).stdout || '').trim(); };
function gercekIO() {
  let K = null; const bas = () => { if (K === null) K = anahtar(); if (!K) throw new Error('SUPABASE_SERVICE_KEY yok'); return { apikey: K, Authorization: 'Bearer ' + K, 'User-Agent': 'mevzuat-radar-robot/1.0', Accept: 'application/json' }; };
  const al = async (u, opt = {}) => { for (let d = 1; d <= 3; d++) { try { const r = await fetch(u, { ...opt, headers: { ...bas(), ...(opt.headers || {}) }, signal: AbortSignal.timeout(180000) }); if (!r.ok) throw new Error('ambar ' + r.status + ' ' + (await r.text()).slice(0, 200)); return r; } catch (e) { if (d === 3 || /ambar 4\d\d/.test(e.message)) throw e; await new Promise(z => setTimeout(z, 3000 * d)); } } };
  return {
    async etiketler() { const out = []; for (let off = 0; ; off += 1000) { const r = await (await al(`${TABAN}/kalip_parti?select=etiket&etiket=like.smmm-*&order=etiket.asc&limit=1000&offset=${off}`)).json(); for (const x of r) if (!String(x.etiket).includes('/')) out.push(x.etiket); if (r.length < 1000) break; } return out; },
    async ambarSatir(e) { const r = await al(`${TABAN}/kalip_parti?select=icerik,guncelleme&etiket=eq.${encodeURIComponent(e)}`); const row = (await r.json())[0]; if (!row) return null;
      return { icerik: typeof row.icerik === 'string' ? JSON.parse(row.icerik) : (row.icerik || {}), guncelleme: String(row.guncelleme) }; },
    async damga(e) { const r = await al(`${TABAN}/kalip_parti?select=guncelleme&etiket=eq.${encodeURIComponent(e)}`); const row = (await r.json())[0]; return row ? String(row.guncelleme) : null; },
    async kosulluYaz(e, damga, icerik) {
      const r = await al(`${TABAN}/kalip_parti?etiket=eq.${encodeURIComponent(e)}&guncelleme=eq.${encodeURIComponent(damga)}&select=guncelleme`, { method: 'PATCH',
        headers: { 'Content-Type': 'application/json; charset=utf-8', Prefer: 'return=representation' }, body: JSON.stringify({ icerik, yazan: 'smmm-model-izi-temizle' + (process.env.GITHUB_RUN_ID ? '-gh' + process.env.GITHUB_RUN_ID : '-yerel') }) });
      const rows = await r.json(); return { satir: rows.length }; },
    kosan() { const ps = process.platform === 'win32' ? 'powershell' : 'pwsh'; const r = cp.spawnSync(ps, ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', path.join(KOK, 'arac', 'bulut-kosan-etiketler.ps1'), '-Kati'], { cwd: KOK, encoding: 'utf8' });
      if (r.status !== 0) throw new Error('bulut-kosan-etiketler düştü (planı okunamayan koşan iş olabilir) — yazan araç bekler: ' + (r.stderr || '').slice(0, 200));
      return new Set((r.stdout || '').split(/\s+/).filter(Boolean)); },
  };
}
// sahte: { etiket: {icerik, guncelleme | guncelleme_sira} } bellekte
function sahteIO(P, kosanListe = []) {
  const sira = {}; const dmg = (e) => { const j = P[e]; if (!Array.isArray(j.guncelleme_sira)) return j.guncelleme; const n = sira[e] = (sira[e] || 0); sira[e]++; return j.guncelleme_sira[Math.min(n, j.guncelleme_sira.length - 1)]; };
  const io = { yazilan: [],
    async etiketler() { return Object.keys(P).filter(e => /^smmm-/.test(e)).sort(); },
    async ambarSatir(e) { if (!P[e]) return null; return { icerik: JSON.parse(JSON.stringify(P[e].icerik)), guncelleme: dmg(e) }; },
    async damga(e) { return P[e] ? dmg(e) : null; },
    async kosulluYaz(e, d, ic) { const j = P[e]; const simdi = Array.isArray(j.guncelleme_sira) ? j.guncelleme_sira[Math.min((sira[e] || 1) - 1, j.guncelleme_sira.length - 1)] : j.guncelleme;
      if (simdi !== d) return { satir: 0 }; j.icerik = JSON.parse(JSON.stringify(ic)); delete j.guncelleme_sira; j.guncelleme = 'y' + (io.yazilan.length + 1); io.yazilan.push(e); return { satir: 1 }; },
    kosan() { return new Set(kosanListe); } };
  return io;
}

// ---------------------------------------------------------------- ÖLÇ / TEMİZLE
async function havuz(isler, n, fn) { const out = new Array(isler.length); let i = 0; await Promise.all(Array.from({ length: n }, async () => { while (i < isler.length) { const j = i++; out[j] = await fn(isler[j], j); } })); return out; }
async function olc(io, opt = {}) {
  const ets = await io.etiketler(); const satir = {}; const sonuc = { parti_toplam: ets.length, kayit_toplam: 0, parti: 0, kayit: 0, alan: 0, deger: {}, alan_yolu: {} };
  await havuz(ets, opt.paralel || 6, async e => { const A = await io.ambarSatir(e); if (!A) return; sonuc.kayit_toplam += Object.keys(A.icerik || {}).length; const iz = izler(A.icerik);
    if (iz.length) { satir[e] = { A, iz }; sonuc.parti++; sonuc.kayit += new Set(iz.map(x => x.kp)).size; sonuc.alan += iz.length;
      for (const x of iz) { sonuc.deger[x.deger] = (sonuc.deger[x.deger] || 0) + 1; const yk = x.yol.replace(/^[^.[]+/, '<kp>').replace(/\[\d+\]/g, '[]'); sonuc.alan_yolu[yk] = (sonuc.alan_yolu[yk] || 0) + 1; } } });
  return { sonuc, satir };
}
async function temizle(io, opt = {}) {
  const { sonuc, satir } = await olc(io, opt);
  const esl = eslemeAl(Object.keys(sonuc.deger));
  const eslesiz = Object.keys(esl).filter(d => esl[d] === d || !/^model-[a-z]$/.test(String(esl[d])));
  const kosan = io.kosan();
  const r = { olcum: sonuc, esleme: esl, eslemesiz_deger: eslesiz, degisecek: { parti: 0, kayit: 0, alan: 0 }, atlanan_kosan: [], yazilan: [], yaris: [], uyusmaz: [], hata: [], kalan_eslemesiz_alan: 0 };
  for (const [e, { A, iz }] of Object.entries(satir).sort()) {
    const hedef = iz.filter(x => !eslesiz.includes(x.deger)); r.kalan_eslemesiz_alan += iz.length - hedef.length;
    if (!hedef.length) continue;
    if (kosan.has(e)) { r.atlanan_kosan.push(e); continue; }
    r.degisecek.parti++; r.degisecek.kayit += new Set(hedef.map(x => x.kp)).size; r.degisecek.alan += hedef.length;
    if (!opt.yaz) continue;
    const yeni = JSON.parse(JSON.stringify(A.icerik)); for (const x of hedef) yolKoy(yeni, x.yol, esl[x.deger]);
    if (MUT === 'baska-alan') { const kp0 = Object.keys(yeni)[0]; yeni[kp0].soru = String(yeni[kp0].soru || '') + ' '; }
    const izinli = new Set(hedef.map(x => x.yol)); const fk = fark(A.icerik, yeni); const izinsiz = fk.filter(y => !izinli.has(y));
    if (izinsiz.length || fk.length !== izinli.size) { r.hata.push(`${e}: beklenmeyen fark (${izinsiz.length} yol)`); continue; }
    const d2 = await io.damga(e); if (d2 !== A.guncelleme) { r.yaris.push(e); continue; }
    const w = await io.kosulluYaz(e, A.guncelleme, yeni); if (w.satir !== 1) { r.yaris.push(e); continue; }
    const G = await io.ambarSatir(e); if (G && esit(G.icerik, yeni)) r.yazilan.push(e); else r.uyusmaz.push(e);
  }
  return r;
}

async function sinav() {
  let ok = 0, top = 0; const S = (ad, g) => { top++; if (g) ok++; console.log((g ? '  ✓ ' : '  ✗ ') + ad); };
  const P = () => ({
    'smmm-a': { guncelleme: 'd1', icerik: { 'kp-01': { soru: 'geminin yükü', sade: { model: 'claude-haiku-4-5', dogru: 'x' }, hakem: { model: 'model-b' }, liste: [1] },
      'kp-02': { soru: 'S', konu_giris: { model: 'claude-sonnet-4-5' }, uyarlama_model: 'claude-opus-5-5', not_model: 'geminin', ikiz: { model: 'gpt-4o' } } } },
    'smmm-b': { guncelleme: 'd1', icerik: { 'kp-01': { soru: 'T', hakem2: { model: 'model-b' } } } },
    'smmm-c': { guncelleme_sira: ['d1', 'd2'], icerik: { 'kp-01': { soru: 'U', sade: { model: 'claude-haiku-4-5' } } } },
    'smmm-d': { guncelleme: 'd1', icerik: { 'kp-01': { soru: 'V', sade: { model: 'claude-sonnet-5' } } } },
    'sgs-x': { guncelleme: 'd1', icerik: { 'kp-01': { soru: 'W', sade: { model: 'claude-haiku-4-5' } } } } });
  const iz0 = izler(P()['smmm-a'].icerik);
  S('ölçüm: model / *_model alanı sayılır, "geminin" ve kod (model-b) sayılmaz, gpt sayılır', iz0.length === 4 && !iz0.some(x => /geminin/.test(x.deger)) && iz0.some(x => x.yol === 'kp-02.uyarlama_model'));
  const D = P(); const io = sahteIO(D, ['smmm-d']);
  const k = await temizle(io, { yaz: false });
  S('KURU: değişecek parti/kayıt/alan doğru (koşan smmm-d atlandı, gpt eşlemesiz), 0 yazma', k.degisecek.parti === 2 && k.degisecek.alan === 4 && k.atlanan_kosan.join() === 'smmm-d' && k.eslemesiz_deger.join() === 'gpt-4o' && io.yazilan.length === 0);
  S('eşleme motor/model-kod.ps1 ModelKod\'dan (haiku→model-a, sonnet→model-b, opus→model-c)', k.esleme['claude-haiku-4-5'] === 'model-a' && k.esleme['claude-sonnet-4-5'] === 'model-b' && k.esleme['claude-opus-5-5'] === 'model-c');
  const D2 = P(); const io2 = sahteIO(D2, ['smmm-d']); const w = await temizle(io2, { yaz: true });
  S('YAZ: smmm-a yazıldı, smmm-c damga değişti → YAZILMADI (yarış), smmm-d bulutta → atlandı, sgs dokunulmadı', w.yazilan.join() === 'smmm-a' && w.yaris.join() === 'smmm-c' && D2['smmm-c'].icerik['kp-01'].sade.model === 'claude-haiku-4-5' && D2['sgs-x'].icerik['kp-01'].sade.model === 'claude-haiku-4-5' && D2['smmm-d'].icerik['kp-01'].sade.model === 'claude-sonnet-5');
  const fk = fark(P()['smmm-a'].icerik, D2['smmm-a'].icerik);
  S('YAZ: yalnız model alanları değişti (3 yol), gpt-4o ve "geminin" aynı, öteki alanlar birebir', fk.length === 3 && fk.every(y => /\.(model|uyarlama_model)$/.test(y)) && D2['smmm-a'].icerik['kp-02'].ikiz.model === 'gpt-4o' && D2['smmm-a'].icerik['kp-02'].not_model === 'geminin' && D2['smmm-a'].icerik['kp-01'].soru === 'geminin yükü');
  const w2 = await temizle(io2, { yaz: true }); S('ikinci tur: smmm-a temiz (0 değişecek orada), kalan eşlemesiz alan 1 (gpt)', !w2.yazilan.includes('smmm-a') && w2.kalan_eslemesiz_alan === 1);
  const sub = cp.spawnSync(process.execPath, ['-e', `process.env.MODEL_TEMIZ_MUTASYON='baska-alan';const m=require(${JSON.stringify(__filename)});const D=${JSON.stringify(P())};const io=m.sahteIO(D,[]);m.temizle(io,{yaz:true}).then(r=>console.log(JSON.stringify({y:io.yazilan.length,h:r.hata.length})))`], { encoding: 'utf8' });
  let mu = false; try { const j = JSON.parse(sub.stdout.trim().split('\n').pop()); mu = j.y === 0 && j.h >= 1; } catch (x) { }
  S('MUTASYON: başka alanı değiştiren yazım DURDURULUR (0 yazma)', mu);
  console.log(`SMMM-MODEL-IZI-TEMIZLE ÖZ-SINAVI ${ok === top ? 'YEŞİL' : 'KIRMIZI'} (${ok}/${top})`); return ok === top;
}

module.exports = { izler, temizle, olc, sahteIO, eslemeAl };
if (require.main === module) {
  const a = process.argv.slice(2); const bayrak = n => { const i = a.indexOf(n); return i >= 0 ? a[i + 1] : undefined; };
  (async () => {
    if (a.includes('--sinav')) process.exit((await sinav()) ? 0 : 1);
    const io = gercekIO();
    if (a.includes('--olc')) { const { sonuc } = await olc(io); console.log(JSON.stringify(sonuc, null, 1)); return; }
    const yaz = a.includes('--yaz'); if (!yaz && !a.includes('--kuru')) { console.log('komut: --olc | --kuru | --yaz [--cikti f] | --sinav'); process.exit(2); }
    const r = await temizle(io, { yaz });
    const o = r.olcum;
    console.log(`ÖLÇÜM: ${o.parti_toplam} smmm partisi · ${o.kayit_toplam} kayıt → model adı izi: ${o.parti} parti · ${o.kayit} kayıt · ${o.alan} alan`);
    console.log(`  değer dağılımı: ${Object.entries(o.deger).map(([d, n]) => `${d}→${r.esleme[d]} ${n}`).join(' · ')}`);
    console.log(`  alan yolları: ${Object.entries(o.alan_yolu).sort((x, y) => y[1] - x[1]).map(([y, n]) => `${y} ${n}`).join(' · ')}`);
    console.log(`  eşlemesiz değer (ModelKod çevirmiyor, DEĞİŞMEZ): ${r.eslemesiz_deger.join(', ') || 'yok'} · bulutta koşan, atlanan parti: ${r.atlanan_kosan.length}`);
    console.log(`${yaz ? 'YAZ' : 'KURU'}: değişecek ${r.degisecek.parti} parti · ${r.degisecek.kayit} kayıt · ${r.degisecek.alan} alan${yaz ? ` → yazılan ${r.yazilan.length} · yarış (damga değişti, yazılmadı) ${r.yaris.length} · geri okuma uyuşmaz ${r.uyusmaz.length} · hata ${r.hata.length}` : ' (yazma yok)'}`);
    for (const h of r.hata) console.log('  ⛔ ' + h);
    if (r.yaris.length) console.log('  YARIŞ: ' + r.yaris.join(', '));
    if (r.atlanan_kosan.length) console.log('  BULUTTA (sonraki tur): ' + r.atlanan_kosan.join(', '));
    const cik = bayrak('--cikti'); if (cik) fs.writeFileSync(cik, JSON.stringify({ zaman: new Date().toISOString(), yazilan: r.yazilan, yaris: r.yaris, atlanan_kosan: r.atlanan_kosan, uyusmaz: r.uyusmaz, hata: r.hata, degisecek: r.degisecek }, null, 1));
    process.exit(r.hata.length || r.uyusmaz.length ? 1 : 0);
  })().catch(e => { console.error('HATA: ' + e.message); process.exit(1); });
}
