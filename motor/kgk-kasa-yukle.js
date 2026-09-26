// motor/kgk-kasa-yukle.js — KGK (BAĞIMSIZ DENETÇİLİK) SORULARINI DOĞRUDAN KİLİTLİ KASAYA YÜKLER (27.09.2026)
//
// motor/kasa-smmm-yukle.js'in KGK eşi. Cem 27.09: "bu oturum YALNIZ KGK, SMMM betiklerine dokunma" → SMMM yükleyicisi
// değiştirilmedi (orada sayfa yolu/kimlik öneki/sinav 'smmm' sabit). Satır biçimi ve ayrıştırıcı ORTAK:
// motor/kasa-soru-yukle.js (sorulariCek, satirlariKur, seviyeIsaretle) değiştirilmeden çağrılır.
// arac/kgk-kasa-yayin.ps1 sayfaları depo DIŞINDA (sql-yerel/, gitignore) kurar, bu betik SORULAR dizisini
// Supabase public.paket_soru'ya (sinav='kgk'; tablo CHECK'i 'kgk'yi zaten kabul ediyor — 2026-09-16-paket-soru.sql) yazar.
//
//   node motor/kgk-kasa-yukle.js --dosya <html> --sayfa kaydir/kgk/<slug>.html [--dosya … --sayfa …]   KURU
//   node motor/kgk-kasa-yukle.js … --yaz      upsert + bu sayfalardaki bayat satırları sil
//   node motor/kgk-kasa-yukle.js --sinav      öz-sınav
//
// KAPILAR: kimlik tekrarı -> DUR · boş sayfa -> DUR · KGK dışı kimlik -> DUR · kaydir/kgk dışı sayfa -> DUR ·
//          tablo yok -> çıkış 3 · kasadaki < yazılan -> çıkış 2.
// Ücretsiz/seviye listesi: veri/sinav/kgk-ucretsiz.json · veri/seviye/kgk-set.json (bugün YOK → hiçbir satır ücretsiz değil).
// Ekrana soru metni BASILMAZ (bulut günlüğü herkese açık): yalnız sayı.
'use strict';
const fs = require('fs');
const path = require('path');
const { sorulariCek, satirlariKur, seviyeIsaretle } = require('./kasa-soru-yukle.js');

const SINAV = 'kgk';
const UCRETSIZ_LISTE = path.join(__dirname, '..', 'veri', 'sinav', 'kgk-ucretsiz.json');
const SEVIYE_SET = path.join(__dirname, '..', 'veri', 'seviye', 'kgk-set.json');
const SB = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/';
const UA = 'tetikte-kasa-kgk/1.0';
const PARCA = 200;

function ucretsizKimlikleri(oku) {
  const idler = [];
  const ham = oku(UCRETSIZ_LISTE);
  if (ham != null) idler.push(...(JSON.parse(ham).kimlikler || []).map(k => String(k.id || '')));
  const sv = oku(SEVIYE_SET);
  if (sv != null) idler.push(...(JSON.parse(sv).sorular || []).map(k => String(k.id || '')));
  return [...new Set(idler.filter(Boolean))];
}

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
    if (!/^kaydir\/kgk\/[a-z0-9-]+\.html$/.test(yol)) throw new Error(`sayfa adı kaydir/kgk/<slug>.html olmalı: ${yol}`);
    const sorular = sorulariCek(oku(dosya));
    if (!sorular.length) throw new Error(`BOŞ SAYFA KAPISI: ${yol} soru taşımıyor — yükleme durduruldu`);
    const yabanci = sorular.filter(q => !String(q.id || '').startsWith('kgk-'));
    if (yabanci.length) throw new Error(`KGK DIŞI KİMLİK: ${yol} (${yabanci.length} soru) — yükleme durduruldu`);
    return { yol, sinav: SINAV, ucretsiz: false, sorular };
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
      const r = await fetch(SB + 'paket_soru?select=id&sinav=eq.' + SINAV + '&sayfa=eq.' + encodeURIComponent(yol) + '&order=id.asc&limit=1000&offset=' + i, { headers: h });
      if (!r.ok) throw new Error(`bayat okuma ${yol}: HTTP ${r.status}`);
      const p = await r.json(); kasadaki.push(...p.map(x => x.id));
      if (p.length < 1000) break;
    }
    const bayat = kasadaki.filter(id => !guncel.has(id));
    for (let i = 0; i < bayat.length; i += 50) {
      const liste = bayat.slice(i, i + 50).map(id => '"' + String(id).replace(/"/g, '') + '"').join(',');
      const r = await fetch(SB + 'paket_soru?sinav=eq.' + SINAV + '&id=in.(' + encodeURIComponent(liste) + ')', { method: 'DELETE', headers: Object.assign({ Prefer: 'return=minimal' }, h) });
      if (!r.ok) throw new Error(`bayat silme ${yol}: HTTP ${r.status}`);
      silinen += Math.min(50, bayat.length - i);
    }
  }
  const say = await fetch(SB + 'paket_soru?select=id&sinav=eq.' + SINAV, { method: 'HEAD', headers: Object.assign({ Prefer: 'count=exact', Range: '0-0' }, h) });
  const kasada = Number((say.headers.get('content-range') || '').split('/')[1]);
  return { yazilan, kasada, silinen };
}

function sinav() {
  let hata = 0; const t = (ad, k) => { console.log((k ? '  geçti: ' : '  DÜŞTÜ: ') + ad); if (!k) hata++; };
  const sahte = {
    a: 'const SORULAR=[{"id":"kgk-gm-tms-r1/kp-01","ders":"Türkiye Muhasebe Standartları"}];',
    b: 'const SORULAR=[];',
    c: 'const SORULAR=[{"id":"smmm-x/kp-01","ders":"Vergi"}];',
    d: 'const SORULAR=[{"id":"sgs-x/kp-01","ders":"Denetim"}];',
  };
  const oku = d => sahte[d];
  const s = sayfalariKur([{ dosya: 'a', yol: 'kaydir/kgk/muhasebe-standartlari.html' }], oku);
  t('kgk sayfası okunur, sinav=kgk', s.length === 1 && s[0].sinav === 'kgk' && satirlariKur(s).satirlar[0].sinav === 'kgk');
  const at = f => { try { f(); return false; } catch (e) { return true; } };
  t('boş sayfa durdurur', at(() => sayfalariKur([{ dosya: 'b', yol: 'kaydir/kgk/x.html' }], oku)));
  t('SMMM kimliği durdurur', at(() => sayfalariKur([{ dosya: 'c', yol: 'kaydir/kgk/x.html' }], oku)));
  t('SGS kimliği durdurur', at(() => sayfalariKur([{ dosya: 'd', yol: 'kaydir/kgk/x.html' }], oku)));
  t('kaydir/smmm sayfa adı reddedilir', at(() => sayfalariKur([{ dosya: 'a', yol: 'kaydir/smmm/vergi.html' }], oku)));
  t('kaydir/sgs sayfa adı reddedilir', at(() => sayfalariKur([{ dosya: 'a', yol: 'kaydir/sgs/denetim.html' }], oku)));
  t('eşleşmeyen --dosya/--sayfa durdurur', at(() => argumanlar(['--dosya', 'x'])));
  const st = satirlariKur(s).satirlar;
  const ids = ucretsizKimlikleri(y => (y === UCRETSIZ_LISTE ? JSON.stringify({ kimlikler: [{ id: 'kgk-gm-tms-r1/kp-01' }, { id: 'kgk-yok/kp-09' }] }) : null));
  const yok = seviyeIsaretle(st, ids);
  t('ücretsiz listedeki kimlik işaretlenir, kasada olmayan sayılır', st[0].ucretsiz === true && yok.length === 1);
  t('ücretsiz liste dosyası yoksa boş liste', ucretsizKimlikleri(() => null).length === 0);
  t('SMMM ücretsiz/seviye dosyası OKUNMAZ (yol kgk-*)', /kgk-ucretsiz\.json$/.test(UCRETSIZ_LISTE) && /kgk-set\.json$/.test(SEVIYE_SET));
  console.log(hata ? `ÖZ-SINAV DÜŞTÜ (${hata})` : 'ÖZ-SINAV GEÇTİ');
  return hata;
}

async function ana() {
  if (process.argv.includes('--sinav')) { process.exitCode = sinav() ? 1 : 0; return; }
  const ciftler = argumanlar(process.argv.slice(2));
  if (!ciftler.length) throw new Error('en az bir --dosya/--sayfa çifti gerekli');
  const sayfalar = sayfalariKur(ciftler, d => fs.readFileSync(d, 'utf8'));
  const { satirlar, tekrar } = satirlariKur(sayfalar);
  const ucKimlik = ucretsizKimlikleri(y => (fs.existsSync(y) ? fs.readFileSync(y, 'utf8') : null));
  const ucYok = seviyeIsaretle(satirlar, ucKimlik);
  console.log(`  ücretsiz: listede ${ucKimlik.length} · işaretlenen ${satirlar.filter(s => s.ucretsiz).length} · kasada olmayan ${ucYok.length}`);
  const bayt = satirlar.reduce((t, s) => t + Buffer.byteLength(JSON.stringify(s.veri)), 0);
  const dersSay = {}; for (const s of satirlar) dersSay[s.ders] = (dersSay[s.ders] || 0) + 1;
  console.log(`KASA KGK · ${process.argv.includes('--yaz') ? 'YAZ' : 'KURU'} · sayfa ${sayfalar.length} · satır ${satirlar.length} · veri ${(bayt / 1048576).toFixed(2)} MB`);
  console.log('  ders: ' + Object.entries(dersSay).sort((a, b) => b[1] - a[1]).map(([d, n]) => `${d} ${n}`).join(' · '));
  if (tekrar.length) { console.log(`  ⛔ KİMLİK TEKRARI ${tekrar.length}`); process.exitCode = 2; return; }
  if (!process.argv.includes('--yaz')) { console.log('  KURU — hiçbir yere yazılmadı.'); return; }
  let r;
  try { r = await yaz(satirlar, sayfalar.map(s => s.yol)); }
  catch (e) { if (e instanceof TabloYok) { console.log('  ATLANDI: ' + e.message); process.exitCode = 3; return; } throw e; }
  console.log(`  yazılan ${r.yazilan} · bayat silinen ${r.silinen} · kasada (kgk) ${r.kasada}`);
  if (r.kasada < satirlar.length) { console.log('  ⛔ KASADAKİ SATIR < YAZILAN'); process.exitCode = 2; }
}

if (require.main === module) ana().catch(e => { console.error('KASA KGK DÜŞTÜ: ' + e.message); process.exitCode = 1; });
module.exports = { sayfalariKur, argumanlar, ucretsizKimlikleri };
