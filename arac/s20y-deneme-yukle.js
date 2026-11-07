#!/usr/bin/env node
/* s20y-deneme-yukle.js — YETERLİLİK SON 20 GÜN denemesini veritabanına yükler (07.11.2026, Cem: "1. denemeyi site koluna yükleme için onaylıyorum").
 *
 * Soru metni depoya YAZILMAZ: girdi depo dışındadır (kaydir-coz çıktısı sql-yerel/ gitignore'da, seçim C:\TETIKTE-CALISMA\yet-s20-arac\d1).
 * Girdi: kaydir-coz HTML dosyaları (const SORULAR=[...]) + seçim dosyası [{etiket,id,ders,konu,_kod,_no}].
 * Denetim (bedel 0): ders başına tam 20 soru · 8 ders · kimlik tekrarı yok · bilinmeyen ders yok · doğru A–E · beş şık · soru metni dolu ·
 *   kayıtta üretici/denetim alanı ya da model adı yok · doğru harf seçim dosyasındakiyle aynı · konu seçim dosyasındakiyle birebir.
 * AÇILIŞ: --kalite verilmezse deneme KAPALI kalır (acilis yazılı olsa da açılmaz).
 *
 * Kullanım:
 *   node arac/s20y-deneme-yukle.js --secim <json> --html <a.html> [--html <b.html>] --no 1 [--acilis 2026-11-08T00:00:00+03:00]
 *        [--kalite "<Cem'in onay cümlesi + tarih>"] [--uygula] [--zorla]
 *   --uygula yoksa KURU: yalnız denetler. Anahtar: SUPABASE_SERVICE_KEY.
 *   node arac/s20y-deneme-yukle.js --sinav   (öz-sınav; ağ yok)
 *   node arac/s20y-deneme-yukle.js --gerial --no 1 --ozet   yüklenen dersler için soru sayısı + doğru harf özeti (içerik basmaz)
 * 🚫 GÖRMEZ: sorunun doğruluğu (kalite raporu + hakem hattı) · kaydir-coz son kapısı (dönüştürücüde) · ambar ile kasa arasındaki sonraki düzeltme.
 */
'use strict';
const fs = require('fs');
const SB_URL = 'https://bjrleanjpyujtajmazxn.supabase.co';
const DERSLER = ['Finansal Muhasebe', 'Finansal Tablolar ve Analizi', 'Maliyet Muhasebesi', 'Muhasebe Denetimi', 'Vergi Mevzuatı ve Uygulaması', 'Hukuk', 'Meslek Hukuku', 'Sermaye Piyasası Mevzuatı'];
const YASAK_ALAN = ['hakem', 'hakem2', 'kor_cozum', 'simulasyon_sonnet', 'aciklama_hakem', 'yazar', 'notlandirici', 'gm_kapi', 'kaynak_metin_ozet'];

function sorulariOku(html) {
  const b = html.indexOf('const SORULAR=');
  if (b < 0) throw new Error('SORULAR yok');
  const on = html.slice(b + 'const SORULAR='.length);
  let d = 0, ic = false, ka = false, son = -1;
  for (let i = 0; i < on.length; i++) { const c = on[i];
    if (ka) { ka = false; continue; } if (c === '\\') { if (ic) ka = true; continue; } if (c === '"') { ic = !ic; continue; } if (ic) continue;
    if (c === '[' || c === '{') d++; else if (c === ']' || c === '}') { d--; if (d === 0) { son = i; break; } } }
  if (son < 0) throw new Error('SORULAR kapanmadı');
  return JSON.parse(on.slice(0, son + 1));
}

/* secim: seçim satırları · sorular: site kayıtları · no: deneme no → { kusur[], paketler[] } */
function hazirla(secim, sorular, no) {
  const kusur = [], kayit = new Map(sorular.map(s => [s.id, s])), paket = new Map(DERSLER.map(d => [d, []])), goruldu = new Set();
  for (const l of secim) {
    const id = `${l.etiket}/${l.id}`, v = kayit.get(id);
    if (goruldu.has(id)) { kusur.push(`tekrar: ${id}`); continue; } goruldu.add(id);
    if (!paket.has(l.ders)) { kusur.push(`bilinmeyen ders "${l.ders}" (${id})`); continue; }
    if (!v) { kusur.push(`dönüşümde yok: ${id}`); continue; }
    if (!String(v.soru || '').trim()) kusur.push(`soru metni boş: ${id}`);
    if (!/^[A-E]$/.test(v.dogru || '')) kusur.push(`doğru bozuk: ${id}`);
    if (!v.siklar || Object.keys(v.siklar).sort().join('') !== 'ABCDE') kusur.push(`şık sayısı: ${id}`);
    if (l.dogru && l.dogru !== v.dogru) kusur.push(`doğru harf farklı: ${id}`);
    if (v.konu !== l.konu) kusur.push(`konu farklı: ${id}`);
    for (const a of YASAK_ALAN) if (a in v) kusur.push(`üretici alanı "${a}": ${id}`);
    if (/claude-|sonnet|opus-/i.test(JSON.stringify(v))) kusur.push(`model adı: ${id}`);
    paket.get(l.ders).push({ id, sira: paket.get(l.ders).length + 1, konu: v.konu, veri: v });
  }
  for (const [d, q] of paket) if (q.length !== 20) kusur.push(`${d}: ${q.length} / 20`);
  return { kusur, paketler: DERSLER.map(d => ({ ders: d, no, sorular: paket.get(d) })) };
}

function arg(ad, vars) { const i = process.argv.indexOf(ad); return i > -1 ? process.argv[i + 1] : vars; }
function argTum(ad) { const c = []; process.argv.forEach((x, i) => { if (x === ad) c.push(process.argv[i + 1]); }); return c; }

async function geriOku(no, anahtar) {
  const h = { apikey: anahtar, Authorization: 'Bearer ' + anahtar };
  const say = {}; let top = 0, yok = 0;
  const r = await fetch(`${SB_URL}/rest/v1/s20y_soru?select=ders,id,veri->>dogru,veri->>soru&no=eq.${no}&limit=400`, { headers: h }).then(x => x.json());
  for (const s of r) { top++; say[s.ders] = (say[s.ders] || 0) + 1; if (!s.dogru || !s.soru) yok++; }
  const d = await fetch(`${SB_URL}/rest/v1/s20y_deneme?select=ders,no,acilis,kalite_onay&no=eq.${no}`, { headers: h }).then(x => x.json());
  console.log(`GERİ OKUMA deneme ${no}: ${top} soru · eksik alan ${yok} · ` + DERSLER.map(x => `${x} ${say[x] || 0}`).join(' · '));
  console.log('  açılış: ' + [...new Set(d.map(x => x.acilis))].join(', ') + ' · kalite onaylı ders ' + d.filter(x => (x.kalite_onay || '').trim()).length + '/' + d.length);
  return { top, yok };
}

async function ana() {
  const no = parseInt(arg('--no'), 10); if (!no) { console.error('--no gerekli'); process.exit(2); }
  const anahtar = (process.env.SUPABASE_SERVICE_KEY || '').trim();
  if (process.argv.includes('--gerial')) { if (!anahtar) { console.error('SUPABASE_SERVICE_KEY yok'); process.exit(1); } const g = await geriOku(no, anahtar); process.exit(g.top === 160 && !g.yok ? 0 : 1); }
  const secim = JSON.parse(fs.readFileSync(arg('--secim'), 'utf8').replace(/^\uFEFF/, ''));
  const sorular = argTum('--html').flatMap(f => sorulariOku(fs.readFileSync(f, 'utf8')));
  const h = hazirla(secim, sorular, no);
  const kalite = (arg('--kalite', '') || '').trim(), acilis = arg('--acilis', '2026-11-08T00:00:00+03:00');
  console.log(`S20Y DENEME ${no}: ` + h.paketler.map(p => `${p.ders} ${p.sorular.length}/20`).join(' · '));
  console.log(`  açılış ${acilis} · kalite onayı: ${kalite || 'YOK → KAPALI yüklenir'}`);
  if (h.kusur.length) { console.error('  KUSUR:\n   - ' + h.kusur.join('\n   - ')); process.exit(1); }
  if (!process.argv.includes('--uygula')) { console.log('  KURU: yazılmadı (--uygula ile yazar).'); return; }
  if (!anahtar) { console.error('SUPABASE_SERVICE_KEY yok'); process.exit(1); }
  for (const p of h.paketler) {
    const govde = { p: { ders: p.ders, no, ad: `Deneme ${no}`, sure_dk: 45, acilis, kalite_onay: kalite, zorla: process.argv.includes('--zorla') ? 'evet' : '', sorular: p.sorular } };
    const r = await fetch(SB_URL + '/rest/v1/rpc/s20y_deneme_yukle', { method: 'POST', headers: { apikey: anahtar, Authorization: 'Bearer ' + anahtar, 'Content-Type': 'application/json' }, body: JSON.stringify(govde) });
    const t = await r.text();
    if (!r.ok) { console.error(`  YAZILAMADI ${p.ders} (${r.status}): ${t.slice(0, 300)}`); process.exit(1); }
    console.log('  yazıldı: ' + t.slice(0, 140));
  }
  await geriOku(no, anahtar);
}

function ozSinav() {
  const sahte = []; const secim = [];
  DERSLER.forEach((d, k) => { for (let i = 1; i <= 20; i++) { const id = `smmm-s20-x${k}-d1/kp-${i}`;
    sahte.push({ id, soru: 'Soru?', dogru: 'B', konu: 'K' + i, siklar: { A: 'a', B: 'b', C: 'c', D: 'd', E: 'e' } });
    secim.push({ etiket: `smmm-s20-x${k}-d1`, id: `kp-${i}`, ders: d, konu: 'K' + i, dogru: 'B' }); } });
  const kopya = o => JSON.parse(JSON.stringify(o));
  const bozSoru = f => { const s = kopya(sahte); f(s[0]); return s; };
  const V = [
    ['tam 160 temiz', secim, sahte, 0],
    ['bir soru dönüşümde yok', secim, sahte.slice(1), 1],
    ['seçim satırı tekrar', secim.map((x, i) => (i === 1 ? secim[0] : x)), sahte, 1],
    ['bilinmeyen ders', secim.map((x, i) => (i === 0 ? { ...x, ders: 'Muhasebe' } : x)), sahte, 1],
    ['doğru harf farklı', secim, bozSoru(s => { s.dogru = 'C'; }), 1],
    ['doğru bozuk', secim, bozSoru(s => { s.dogru = 'F'; }), 1],
    ['dört şık', secim, bozSoru(s => { delete s.siklar.E; }), 1],
    ['boş soru', secim, bozSoru(s => { s.soru = ' '; }), 1],
    ['konu farklı (görev eşlemesi bozulur)', secim, bozSoru(s => { s.konu = 'Başka'; }), 1],
    ['hakem alanı sızdı', secim, bozSoru(s => { s.hakem = { karar: 'EVET' }; }), 1],
    ['model adı sızdı', secim, bozSoru(s => { s.not = 'claude-x'; }), 1],
  ];
  let kir = 0;
  for (const [ad, se, so, b] of V) { const n = hazirla(se, so, 1).kusur.length; const ok = b === 0 ? n === 0 : n >= 1; console.log((ok ? 'GEÇTİ ' : 'DÜŞTÜ ') + ad + ` (kusur ${n})`); if (!ok) kir++; }
  const p = hazirla(secim, sahte, 1).paketler; const dz = p.length === 8 && p.every(x => x.sorular.length === 20 && x.sorular[19].sira === 20);
  console.log((dz ? 'GEÇTİ ' : 'DÜŞTÜ ') + '8 ders × 20 sıra'); if (!dz) kir++;
  const h = 'x;const SORULAR=[{"id":"a]","soru":"s\\"}"}];const B=[];';
  const o = sorulariOku(h); const ok2 = o.length === 1 && o[0].id === 'a]' && o[0].soru === 's"}';
  console.log((ok2 ? 'GEÇTİ ' : 'DÜŞTÜ ') + 'SORULAR metin içi köşeli ayraçtan etkilenmez'); if (!ok2) kir++;
  console.log(`S20Y YÜKLEYİCİ ÖZ-SINAV: ${kir ? 'KIRMIZI' : 'YEŞİL'} (${V.length + 2 - kir}/${V.length + 2})`);
  process.exit(kir ? 1 : 0);
}

if (process.argv.includes('--sinav')) ozSinav(); else ana().catch(e => { console.error(e); process.exit(1); });
