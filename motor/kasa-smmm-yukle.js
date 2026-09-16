// motor/kasa-smmm-yukle.js — BİTİRME (SMMM) SORULARINI DOĞRUDAN KİLİTLİ KASAYA YÜKLER (16.09.2026)
//
// Cem 16.09: "bu bastığımız soruları kilitli yere alacaksın direkt". Bitirme soruları açık depoya ya da
// kaydir/ klasörüne HİÇ yazılmaz: arac/smmm-kasa-yayin.ps1 sayfaları depo DIŞINDA (sql-yerel/, gitignore)
// kurar, bu betik oradaki SORULAR dizisini Supabase public.paket_soru'ya (sinav='smmm') yazar.
// Satır biçimi ve ayrıştırıcı SGS yükleyicisiyle aynı (motor/kasa-soru-yukle.js dışa açtığı işlevler).
//
//   node motor/kasa-smmm-yukle.js --dosya <html> --sayfa kaydir/smmm/<slug>.html [--dosya … --sayfa …]   KURU
//   node motor/kasa-smmm-yukle.js … --yaz      upsert + bu sayfalardaki bayat satırları sil
//   node motor/kasa-smmm-yukle.js --sinav      öz-sınav
//
// KAPILAR: kimlik tekrarı -> DUR · boş sayfa -> DUR · SMMM dışı kimlik -> DUR · tablo yok -> çıkış 3 · kasadaki < yazılan -> çıkış 2.
// Ekrana soru metni BASILMAZ (bulut günlüğü herkese açık): yalnız sayı.
'use strict';
const fs = require('fs');
const { sorulariCek, satirlariKur } = require('./kasa-soru-yukle.js');

const SB = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/';
const UA = 'tetikte-kasa-smmm/1.0';
const PARCA = 200;

function argumanlar(argv) {
  const dosya = [], sayfa = [];
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === '--dosya') dosya.push(argv[++i]);
    else if (argv[i] === '--sayfa') sayfa.push(argv[++i]);
  }
  if (dosya.length !== sayfa.length) throw new Error('--dosya ve --sayfa sayısı eşit olmalı');
  return dosya.map((d, i) => ({ dosya: d, yol: sayfa[i] }));
}

function sayfalariKur(ciftler, oku) {
  return ciftler.map(({ dosya, yol }) => {
    if (!/^kaydir\/smmm\/[a-z0-9-]+\.html$/.test(yol)) throw new Error(`sayfa adı kaydir/smmm/<slug>.html olmalı: ${yol}`);
    const sorular = sorulariCek(oku(dosya));
    if (!sorular.length) throw new Error(`BOŞ SAYFA KAPISI: ${yol} soru taşımıyor — yükleme durduruldu`);
    const yabanci = sorular.filter(q => !String(q.id || '').startsWith('smmm-'));
    if (yabanci.length) throw new Error(`SMMM DIŞI KİMLİK: ${yol} (${yabanci.length} soru) — yükleme durduruldu`);
    return { yol, sinav: 'smmm', ucretsiz: false, sorular };
  });
}

class TabloYok extends Error {}

async function yaz(satirlar, sayfaYollari) {
  const K = process.env.SUPABASE_SERVICE_KEY;
  if (!K) throw new Error('SUPABASE_SERVICE_KEY yok');
  const h = { apikey: K, Authorization: 'Bearer ' + K, 'User-Agent': UA, 'Content-Type': 'application/json' };
  const yok = await fetch(SB + 'paket_soru?select=id&limit=1', { headers: h });
  if (yok.status === 404 || yok.status === 400) throw new TabloYok('paket_soru tablosu yok (2026-09-16-paket-soru.sql basılmadı) — yazılmadı');
  if (!yok.ok) throw new Error(`kasa yoklaması HTTP ${yok.status}`);
  let yazilan = 0;
  for (let i = 0; i < satirlar.length; i += PARCA) {
    const parca = satirlar.slice(i, i + PARCA).map(s => Object.assign({}, s, { guncelleme: new Date().toISOString() }));
    const r = await fetch(SB + 'paket_soru?on_conflict=id', { method: 'POST', headers: Object.assign({ Prefer: 'resolution=merge-duplicates,return=minimal' }, h), body: JSON.stringify(parca) });
    if (!r.ok) throw new Error(`parça ${i}: HTTP ${r.status}`);
    yazilan += parca.length;
  }
  const guncel = new Set(satirlar.map(s => s.id));
  let silinen = 0;
  for (const yol of sayfaYollari) {
    const kasadaki = [];
    for (let i = 0; ; i += 1000) {
      const r = await fetch(SB + 'paket_soru?select=id&sinav=eq.smmm&sayfa=eq.' + encodeURIComponent(yol) + '&order=id.asc&limit=1000&offset=' + i, { headers: h });
      if (!r.ok) throw new Error(`bayat okuma ${yol}: HTTP ${r.status}`);
      const p = await r.json(); kasadaki.push(...p.map(x => x.id));
      if (p.length < 1000) break;
    }
    const bayat = kasadaki.filter(id => !guncel.has(id));
    for (let i = 0; i < bayat.length; i += 50) {
      const liste = bayat.slice(i, i + 50).map(id => '"' + String(id).replace(/"/g, '') + '"').join(',');
      const r = await fetch(SB + 'paket_soru?sinav=eq.smmm&id=in.(' + encodeURIComponent(liste) + ')', { method: 'DELETE', headers: Object.assign({ Prefer: 'return=minimal' }, h) });
      if (!r.ok) throw new Error(`bayat silme ${yol}: HTTP ${r.status}`);
      silinen += Math.min(50, bayat.length - i);
    }
  }
  const say = await fetch(SB + 'paket_soru?select=id&sinav=eq.smmm', { method: 'HEAD', headers: Object.assign({ Prefer: 'count=exact', Range: '0-0' }, h) });
  const kasada = Number((say.headers.get('content-range') || '').split('/')[1]);
  return { yazilan, kasada, silinen };
}

function sinav() {
  let hata = 0; const t = (ad, k) => { console.log((k ? '  geçti: ' : '  DÜŞTÜ: ') + ad); if (!k) hata++; };
  const sahte = { a: 'const SORULAR=[{"id":"smmm-4k-d1-yvergi-kolay-r1/kp-01","ders":"Vergi"}];', b: 'const SORULAR=[];', c: 'const SORULAR=[{"id":"sgs-x/kp-01","ders":"Vergi"}];' };
  const oku = d => sahte[d];
  const s = sayfalariKur([{ dosya: 'a', yol: 'kaydir/smmm/vergi.html' }], oku);
  t('smmm sayfası okunur, sinav=smmm', s.length === 1 && s[0].sinav === 'smmm' && satirlariKur(s).satirlar[0].sinav === 'smmm');
  let d1 = false; try { sayfalariKur([{ dosya: 'b', yol: 'kaydir/smmm/vergi.html' }], oku); } catch (e) { d1 = true; }
  t('boş sayfa durdurur', d1);
  let d2 = false; try { sayfalariKur([{ dosya: 'c', yol: 'kaydir/smmm/vergi.html' }], oku); } catch (e) { d2 = true; }
  t('SMMM dışı kimlik durdurur', d2);
  let d3 = false; try { sayfalariKur([{ dosya: 'a', yol: 'kaydir/sgs/vergi.html' }], oku); } catch (e) { d3 = true; }
  t('sgs sayfa adı reddedilir', d3);
  let d4 = false; try { argumanlar(['--dosya', 'x']); } catch (e) { d4 = true; }
  t('eşleşmeyen --dosya/--sayfa durdurur', d4);
  console.log(hata ? `ÖZ-SINAV DÜŞTÜ (${hata})` : 'ÖZ-SINAV GEÇTİ');
  return hata;
}

async function ana() {
  if (process.argv.includes('--sinav')) { process.exitCode = sinav() ? 1 : 0; return; }
  const ciftler = argumanlar(process.argv.slice(2));
  if (!ciftler.length) throw new Error('en az bir --dosya/--sayfa çifti gerekli');
  const sayfalar = sayfalariKur(ciftler, d => fs.readFileSync(d, 'utf8'));
  const { satirlar, tekrar } = satirlariKur(sayfalar);
  const bayt = satirlar.reduce((t, s) => t + Buffer.byteLength(JSON.stringify(s.veri)), 0);
  const dersSay = {}; for (const s of satirlar) dersSay[s.ders] = (dersSay[s.ders] || 0) + 1;
  console.log(`KASA SMMM · ${process.argv.includes('--yaz') ? 'YAZ' : 'KURU'} · sayfa ${sayfalar.length} · satır ${satirlar.length} · veri ${(bayt / 1048576).toFixed(2)} MB`);
  console.log('  ders: ' + Object.entries(dersSay).sort((a, b) => b[1] - a[1]).map(([d, n]) => `${d} ${n}`).join(' · '));
  if (tekrar.length) { console.log(`  ⛔ KİMLİK TEKRARI ${tekrar.length}`); process.exitCode = 2; return; }
  if (!process.argv.includes('--yaz')) { console.log('  KURU — hiçbir yere yazılmadı.'); return; }
  let r;
  try { r = await yaz(satirlar, sayfalar.map(s => s.yol)); }
  catch (e) { if (e instanceof TabloYok) { console.log('  ATLANDI: ' + e.message); process.exitCode = 3; return; } throw e; }
  console.log(`  yazılan ${r.yazilan} · bayat silinen ${r.silinen} · kasada (smmm) ${r.kasada}`);
  if (r.kasada < satirlar.length) { console.log('  ⛔ KASADAKİ SATIR < YAZILAN'); process.exitCode = 2; }
}

if (require.main === module) ana().catch(e => { console.error('KASA SMMM DÜŞTÜ: ' + e.message); process.exitCode = 1; });
module.exports = { sayfalariKur, argumanlar };
