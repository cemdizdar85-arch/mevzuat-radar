// motor/kasa-soru-yukle.js — PAKET SORULARINI KİLİTLİ KASAYA YÜKLER (Adım 2 madde 2 · 15.09.2026 TASLAK)
//
// Kaynak: yayındaki Kaydır-Çöz sayfalarının SORULAR dizisi (kaydir/sgs/*.html) + ücretsiz vitrin
// (kaydir/vitrin/sgs.html). Hedef: Supabase public.paket_soru (radar-app/sql/TASLAK-2026-09-15-paket-soru.sql).
// Adım 2'de basım hattı (yayin-bas.yml) sayfayı bastıktan hemen sonra bunu koşar.
//
//   node motor/kasa-soru-yukle.js            KURU: satır sayar, kimlik tekilliğini ve boyutu ölçer, HİÇBİR YERE yazmaz
//   node motor/kasa-soru-yukle.js --yaz      upsert (SUPABASE_SERVICE_KEY; tablo basılmadıysa durur)
//   node motor/kasa-soru-yukle.js --sinav    öz-sınav
//
// KAPILAR: kimlik tekrarı -> DUR · boş sayfa -> DUR (12.09 boş havuz dersi) · yazılan != sayılan -> KIRMIZI çıkış.
'use strict';
const fs = require('fs');
const path = require('path');

const KOK = path.resolve(__dirname, '..');
const SB = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/';
const UA = 'tetikte-kasa-yukle/1.0';
const PARCA = 200;

function sorulariCek(metin) {
  const i = metin.indexOf('const SORULAR=');
  if (i < 0) return [];
  const j = i + 'const SORULAR='.length;
  if (metin[j] !== '[') return [];
  let d = 0, z = false, e = false;
  for (let k = j; k < metin.length; k++) {
    const c = metin[k];
    if (z) { if (e) e = false; else if (c === '\\') e = true; else if (c === '"') z = false; continue; }
    if (c === '"') z = true; else if (c === '[') d++;
    else if (c === ']') { d--; if (d === 0) return JSON.parse(metin.slice(j, k + 1)); }
  }
  throw new Error('SORULAR dizisi kapanmadı');
}

// Satırları kurar. Aynı kimlik hem paket sayfasında hem vitrinde olabilir: paket satırı esas,
// vitrinde de varsa ucretsiz=true işaretlenir (satır tekrarlanmaz).
function satirlariKur(sayfalar) {
  const satir = new Map(); const tekrar = [];
  for (const s of sayfalar.filter(x => !x.ucretsiz)) {
    s.sorular.forEach((q, i) => {
      const id = String(q.id || '');
      if (!id) throw new Error(`${s.yol}: kimliksiz soru (sıra ${i})`);
      if (satir.has(id)) { tekrar.push(id + ' @ ' + s.yol); return; }
      satir.set(id, { id, sinav: s.sinav, ders: String(q.ders || ''), konu: q.konu || null, sayfa: s.yol, sira: i, ucretsiz: false, veri: q });
    });
  }
  for (const s of sayfalar.filter(x => x.ucretsiz)) {
    s.sorular.forEach((q, i) => {
      const id = String(q.id || '');
      if (satir.has(id)) satir.get(id).ucretsiz = true;
      else satir.set(id, { id, sinav: s.sinav, ders: String(q.ders || ''), konu: q.konu || null, sayfa: s.yol, sira: i, ucretsiz: true, veri: q });
    });
  }
  return { satirlar: [...satir.values()], tekrar };
}

// Ders sayfası listesi TEK KAYNAKTAN: veri/soru-dizini.json (sorular.html de bunu okur).
// 15.09 ilk kuru koşu: klasördeki her html okununca muhur-10.html ve kapituru-3.html (tek seferlik
// basımlar) ders sayfalarındaki 10+2 soruyu TEKRARLADIĞI için kimlik kapısı durdurdu. Doğru küme dizindeki sayfalar.
function dersSayfalari() {
  const d = JSON.parse(fs.readFileSync(path.join(KOK, 'veri', 'soru-dizini.json'), 'utf8').replace(/^﻿/, ''));
  const out = [];
  for (const s of d.sinavlar || []) for (const ders of s.dersler || []) if (ders.sayfa) out.push({ yol: ders.sayfa, sinav: s.kod });
  if (!out.length) throw new Error('soru-dizini.json ders sayfası vermedi — yükleme durduruldu');
  return out;
}

function sayfalariOku() {
  const out = [];
  for (const { yol, sinav } of dersSayfalari()) {
    const sorular = sorulariCek(fs.readFileSync(path.join(KOK, yol), 'utf8'));
    if (!sorular.length) throw new Error(`BOŞ SAYFA KAPISI: ${yol} soru taşımıyor — yükleme durduruldu`);
    out.push({ yol, sinav, ucretsiz: false, sorular });
  }
  const vit = path.join(KOK, 'kaydir', 'vitrin', 'sgs.html');
  if (fs.existsSync(vit)) out.push({ yol: 'kaydir/vitrin/sgs.html', sinav: 'sgs', ucretsiz: true, sorular: sorulariCek(fs.readFileSync(vit, 'utf8')) });
  return out;
}

async function yaz(satirlar) {
  const K = process.env.SUPABASE_SERVICE_KEY;
  if (!K) throw new Error('SUPABASE_SERVICE_KEY yok');
  const h = { apikey: K, Authorization: 'Bearer ' + K, 'User-Agent': UA, 'Content-Type': 'application/json' };
  const var_ = await fetch(SB + 'paket_soru?select=id&limit=1', { headers: h });
  if (var_.status === 404 || var_.status === 400) throw new Error('paket_soru tablosu yok (TASLAK SQL basılmadı) — yazılmadı');
  let yazilan = 0;
  for (let i = 0; i < satirlar.length; i += PARCA) {
    const parca = satirlar.slice(i, i + PARCA).map(s => Object.assign({}, s, { guncelleme: new Date().toISOString() }));
    const r = await fetch(SB + 'paket_soru?on_conflict=id', { method: 'POST', headers: Object.assign({ Prefer: 'resolution=merge-duplicates,return=minimal' }, h), body: JSON.stringify(parca) });
    if (!r.ok) throw new Error(`parça ${i}: HTTP ${r.status} ${(await r.text()).slice(0, 200)}`);
    yazilan += parca.length;
  }
  const say = await fetch(SB + 'paket_soru?select=id', { method: 'HEAD', headers: Object.assign({ Prefer: 'count=exact', Range: '0-0' }, h) });
  const kasada = Number((say.headers.get('content-range') || '').split('/')[1]);
  return { yazilan, kasada };
}

function sinav() {
  let hata = 0; const t = (ad, k) => { console.log((k ? '  geçti: ' : '  DÜŞTÜ: ') + ad); if (!k) hata++; };
  t('dize içindeki köşeli parantez kesmez', sorulariCek('const SORULAR=[{"id":"a/kp-01","soru":"x ] ["}];').length === 1);
  const s = satirlariKur([
    { yol: 'kaydir/sgs/a.html', sinav: 'sgs', ucretsiz: false, sorular: [{ id: 'e/kp-01', ders: 'A' }, { id: 'e/kp-02', ders: 'A' }] },
    { yol: 'kaydir/vitrin/sgs.html', sinav: 'sgs', ucretsiz: true, sorular: [{ id: 'e/kp-02', ders: 'A' }, { id: 'v/kp-09', ders: 'B' }] },
  ]);
  t('paket + vitrin ortak kimlik tek satır', s.satirlar.length === 3);
  t('vitrindeki paket sorusu ucretsiz işaretlenir, sayfası paket sayfası kalır', s.satirlar.find(x => x.id === 'e/kp-02').ucretsiz === true && s.satirlar.find(x => x.id === 'e/kp-02').sayfa === 'kaydir/sgs/a.html');
  t('yalnız vitrindeki soru ucretsiz satır', s.satirlar.find(x => x.id === 'v/kp-09').ucretsiz === true);
  t('sıra korunur', s.satirlar.find(x => x.id === 'e/kp-02').sira === 1);
  const t2 = satirlariKur([{ yol: 'a', sinav: 'sgs', ucretsiz: false, sorular: [{ id: 'x' }] }, { yol: 'b', sinav: 'sgs', ucretsiz: false, sorular: [{ id: 'x' }] }]);
  t('iki paket sayfasında aynı kimlik tekrar olarak raporlanır', t2.tekrar.length === 1);
  let atti = false; try { satirlariKur([{ yol: 'a', sinav: 'sgs', ucretsiz: false, sorular: [{ soru: 'kimliksiz' }] }]); } catch (e) { atti = true; }
  t('kimliksiz soru durdurur', atti);
  console.log(hata ? `ÖZ-SINAV DÜŞTÜ (${hata})` : 'ÖZ-SINAV GEÇTİ');
  return hata;
}

async function ana() {
  if (process.argv.includes('--sinav')) process.exit(sinav() ? 1 : 0);
  const sayfalar = sayfalariOku();
  const { satirlar, tekrar } = satirlariKur(sayfalar);
  const bayt = satirlar.reduce((t, s) => t + Buffer.byteLength(JSON.stringify(s.veri)), 0);
  const dersSay = {}; for (const s of satirlar) dersSay[s.ders] = (dersSay[s.ders] || 0) + 1;
  console.log(`KASA YÜKLEYİCİ · ${process.argv.includes('--yaz') ? 'YAZ' : 'KURU'}`);
  console.log(`  sayfa ${sayfalar.length} · satır ${satirlar.length} (ücretsiz ${satirlar.filter(s => s.ucretsiz).length}) · veri ${(bayt / 1048576).toFixed(1)} MB · soru başı ~${Math.round(bayt / satirlar.length / 1024)} KB`);
  console.log('  ders: ' + Object.entries(dersSay).sort((a, b) => b[1] - a[1]).map(([d, n]) => `${d} ${n}`).join(' · '));
  if (tekrar.length) { console.log(`  ⛔ KİMLİK TEKRARI ${tekrar.length}: ${tekrar.slice(0, 5).join(', ')}`); process.exit(2); }
  if (!process.argv.includes('--yaz')) { console.log('  KURU — hiçbir yere yazılmadı.'); return; }
  const r = await yaz(satirlar);
  console.log(`  yazılan ${r.yazilan} · kasada ${r.kasada}`);
  if (r.kasada < satirlar.length) { console.log('  ⛔ KASADAKİ SATIR < SAYILAN'); process.exit(2); }
}

if (require.main === module) ana().catch(e => { console.error('KASA YÜKLEYİCİ DÜŞTÜ: ' + e.message); process.exit(1); });
module.exports = { sorulariCek, satirlariKur };
