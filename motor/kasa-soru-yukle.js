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

// 16.09: kasa modundaki sayfa kabuktur (motor/kasa-kabuk.js) — sorusu kasada, sayfada değil.
// Kabuk ATLANIR; kasadaki satırlarına dokunulmaz (silme de yapılmaz).
function sayfalariOku(atlanan) {
  const out = [];
  for (const { yol, sinav } of dersSayfalari()) {
    const html = fs.readFileSync(path.join(KOK, yol), 'utf8');
    if (html.includes('data-kasa-sayfa=')) { if (atlanan) atlanan.push(yol); continue; }
    const sorular = sorulariCek(html);
    if (!sorular.length) throw new Error(`BOŞ SAYFA KAPISI: ${yol} soru taşımıyor — yükleme durduruldu`);
    out.push({ yol, sinav, ucretsiz: false, sorular });
  }
  const vit = path.join(KOK, 'kaydir', 'vitrin', 'sgs.html');
  if (fs.existsSync(vit)) out.push({ yol: 'kaydir/vitrin/sgs.html', sinav: 'sgs', ucretsiz: true, sorular: sorulariCek(fs.readFileSync(vit, 'utf8')) });
  return out;
}

// Seviye testi havuzu (ücretsiz katman): sunucu cevap kontrolü (seviye_kontrol) yalnız ucretsiz satırlarda
// çalıştığı için bu kimlikler de ucretsiz işaretlenir. Havuzda olup ders sayfasında olmayan kimlik -> hata listesi.
function seviyeKimlikleri() {
  const y = path.join(KOK, 'veri', 'seviye', 'sgs-havuz.json');
  if (!fs.existsSync(y)) return [];
  const h = JSON.parse(fs.readFileSync(y, 'utf8').replace(/^﻿/, ''));
  // biçim: havuz[ders][zorluk] = [{id, soru, siklar, dogru, sayfa, sira}]
  const ids = [];
  (function gez(x) { if (Array.isArray(x)) x.forEach(gez); else if (x && typeof x === 'object') { if (x.id && x.soru) ids.push(String(x.id)); else for (const k in x) gez(x[k]); } })(h.havuz);
  return ids;
}
function seviyeIsaretle(satirlar, kimlikler) {
  const m = new Map(satirlar.map(s => [s.id, s])); const bulunamayan = [];
  for (const id of kimlikler) { if (m.has(id)) m.get(id).ucretsiz = true; else bulunamayan.push(id); }
  return bulunamayan;
}

// Tablo yoksa: kasa modunda sayfa YOKSA yayın bugünkü gibi sürer (çıkış 3 = "atla");
// kasa modunda sayfa VARSA durulur (kabuklar kasasız kalır). Bkz arac/kasa-modu.json.
class TabloYok extends Error {}

async function yaz(satirlar, sayfaYollari) {
  const K = process.env.SUPABASE_SERVICE_KEY;
  if (!K) throw new Error('SUPABASE_SERVICE_KEY yok');
  const h = { apikey: K, Authorization: 'Bearer ' + K, 'User-Agent': UA, 'Content-Type': 'application/json' };
  const var_ = await fetch(SB + 'paket_soru?select=id&limit=1', { headers: h });
  if (var_.status === 404 || var_.status === 400) throw new TabloYok('paket_soru tablosu yok (2026-09-16-paket-soru.sql basılmadı) — yazılmadı');
  if (!var_.ok) throw new Error(`kasa yoklaması HTTP ${var_.status}`);
  let yazilan = 0;
  for (let i = 0; i < satirlar.length; i += PARCA) {
    const parca = satirlar.slice(i, i + PARCA).map(s => Object.assign({}, s, { guncelleme: new Date().toISOString() }));
    const r = await fetch(SB + 'paket_soru?on_conflict=id', { method: 'POST', headers: Object.assign({ Prefer: 'resolution=merge-duplicates,return=minimal' }, h), body: JSON.stringify(parca) });
    if (!r.ok) throw new Error(`parça ${i}: HTTP ${r.status} ${(await r.text()).slice(0, 200)}`);
    yazilan += parca.length;
  }
  // Bayat satır: bu koşuda okunan sayfalara ait olup artık o sayfada olmayan kimlik (soru yayından düştü).
  // Kimlik başka sayfaya taşındıysa upsert sayfa alanını zaten güncelledi; burada yakalanmaz.
  const guncel = new Set(satirlar.map(s => s.id));
  let silinen = 0;
  for (const yol of sayfaYollari) {
    const kasadaki = [];
    for (let i = 0; ; i += 1000) {
      const r = await fetch(SB + 'paket_soru?select=id&sayfa=eq.' + encodeURIComponent(yol) + '&order=id.asc&limit=1000&offset=' + i, { headers: h });
      if (!r.ok) throw new Error(`bayat okuma ${yol}: HTTP ${r.status}`);
      const p = await r.json(); kasadaki.push(...p.map(x => x.id));
      if (p.length < 1000) break;
    }
    const bayat = kasadaki.filter(id => !guncel.has(id));
    for (let i = 0; i < bayat.length; i += 50) {
      const liste = bayat.slice(i, i + 50).map(id => '"' + String(id).replace(/"/g, '') + '"').join(',');
      const r = await fetch(SB + 'paket_soru?id=in.(' + encodeURIComponent(liste) + ')', { method: 'DELETE', headers: Object.assign({ Prefer: 'return=minimal' }, h) });
      if (!r.ok) throw new Error(`bayat silme ${yol}: HTTP ${r.status}`);
      silinen += Math.min(50, bayat.length - i);
    }
  }
  const say =await fetch(SB + 'paket_soru?select=id', { method: 'HEAD', headers: Object.assign({ Prefer: 'count=exact', Range: '0-0' }, h) });
  const kasada = Number((say.headers.get('content-range') || '').split('/')[1]);
  return { yazilan, kasada, silinen };
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
  const sv = [{ id: 'a' , ucretsiz: false }, { id: 'b', ucretsiz: false }];
  const svy = seviyeIsaretle(sv, ['b', 'z']);
  t('seviye kimliği ucretsiz işaretlenir, olmayan raporlanır', sv[1].ucretsiz === true && sv[0].ucretsiz === false && svy.length === 1 && svy[0] === 'z');
  let atti = false; try { satirlariKur([{ yol: 'a', sinav: 'sgs', ucretsiz: false, sorular: [{ soru: 'kimliksiz' }] }]); } catch (e) { atti = true; }
  t('kimliksiz soru durdurur', atti);
  console.log(hata ? `ÖZ-SINAV DÜŞTÜ (${hata})` : 'ÖZ-SINAV GEÇTİ');
  return hata;
}

async function ana() {
  if (process.argv.includes('--sinav')) { process.exitCode = sinav() ? 1 : 0; return; }
  const atlanan = [];
  const sayfalar = sayfalariOku(atlanan);
  const { satirlar, tekrar } = satirlariKur(sayfalar);
  if (atlanan.length) console.log(`  kabuk (atlandı, kasadaki satırları korunur): ${atlanan.join(', ')}`);
  const svKimlik = seviyeKimlikleri();
  const svYok = seviyeIsaretle(satirlar, svKimlik);
  console.log(`  seviye havuzu ${svKimlik.length} kimlik · kasada bulunamayan ${svYok.length}`);
  // Kabuk sayfanın sorusu bu koşuda okunmadı; seviye kimliği o sayfadaysa "bulunamadı" görünür ama kasada durur.
  if (svYok.length && !atlanan.length) { console.log(`  ⛔ SEVİYE HAVUZUNDA KASADA OLMAYAN KİMLİK: ${svYok.slice(0, 5).join(', ')}`); process.exitCode = 2; return; }
  if (svYok.length) console.log(`  (kabuk sayfa var: ${svYok.length} seviye kimliği bu koşuda doğrulanamadı — kasadaki ucretsiz işaretine dokunulmaz)`);
  const bayt = satirlar.reduce((t, s) => t + Buffer.byteLength(JSON.stringify(s.veri)), 0);
  const dersSay = {}; for (const s of satirlar) dersSay[s.ders] = (dersSay[s.ders] || 0) + 1;
  console.log(`KASA YÜKLEYİCİ · ${process.argv.includes('--yaz') ? 'YAZ' : 'KURU'}`);
  console.log(`  sayfa ${sayfalar.length} · satır ${satirlar.length} (ücretsiz ${satirlar.filter(s => s.ucretsiz).length}) · veri ${(bayt / 1048576).toFixed(1)} MB · soru başı ~${Math.round(bayt / satirlar.length / 1024)} KB`);
  console.log('  ders: ' + Object.entries(dersSay).sort((a, b) => b[1] - a[1]).map(([d, n]) => `${d} ${n}`).join(' · '));
  if (tekrar.length) { console.log(`  ⛔ KİMLİK TEKRARI ${tekrar.length}: ${tekrar.slice(0, 5).join(', ')}`); process.exitCode = 2; return; }
  if (!process.argv.includes('--yaz')) { console.log('  KURU — hiçbir yere yazılmadı.'); return; }
  let r;
  try { r = await yaz(satirlar, sayfalar.map(s => s.yol)); }
  catch (e) {
    if (!(e instanceof TabloYok)) throw e;
    const km = JSON.parse(fs.readFileSync(path.join(KOK, 'arac', 'kasa-modu.json'), 'utf8').replace(/^﻿/, ''));
    if ((km.sayfalar || []).length) { console.error('  ⛔ ' + e.message + ' — ama kasa modunda sayfa var, DURULDU'); process.exitCode = 1; return; }
    console.log('  ATLANDI: ' + e.message + ' (kasa modunda sayfa yok, yayın bugünkü gibi sürer)'); process.exitCode = 3; return;
  }
  console.log(`  yazılan ${r.yazilan} · bayat silinen ${r.silinen} · kasada ${r.kasada}`);
  if (r.kasada < satirlar.length) { console.log('  ⛔ KASADAKİ SATIR < SAYILAN'); process.exitCode = 2; return; }
}

if (require.main === module) ana().catch(e => { console.error('KASA YÜKLEYİCİ DÜŞTÜ: ' + e.message); process.exitCode = 1; return; });
module.exports = { sorulariCek, satirlariKur, seviyeIsaretle };
