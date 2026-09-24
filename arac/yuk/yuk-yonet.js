// arac/yuk/yuk-yonet.js — 1.000 tarayicili yuk testinin yonetimi (24.09.2026). Uc komut:
//   node arac/yuk/yuk-yonet.js zaman      kapi saatini + oturum kodunu kurar, GERCEK oturumla cakisirsa DURUR
//   node arac/yuk/yuk-yonet.js kapi       kapi saatinde anahtari GERCEK Storage'a basar (servis anahtari)
//   node arac/yuk/yuk-yonet.js temizlik   test sonuclarini, anahtari ve deneme uyelerini siler; "kalan 0" olcer
// Stdout'a yalniz sayi/kod basilir. Sir yalniz ortam degiskeninde (SUPABASE_SERVICE_KEY).
// GORMEZ (temizlik): deneme uyesinin baska tablolara yazdigi satirlar - auth.users FK'leri ON DELETE CASCADE
//   (soru_havuzu 07-23, alacak 08-19, ogrenci_sonuc 09-13 goclerinde olculdu); cascade'siz yeni bir tablo eklenirse gormez.
'use strict';
const fs = require('fs'), path = require('path'), crypto = require('crypto');
const SB = 'https://bjrleanjpyujtajmazxn.supabase.co';
const E = process.env, KOK = path.resolve(__dirname, '..', '..');
const UA = 'tetikte-yuk-testi/1.0';   // tarayici UA'si KULLANILMAZ ("Forbidden use of secret API key in browser")
const cikti = (k, v) => { if (E.GITHUB_OUTPUT) fs.appendFileSync(E.GITHUB_OUTPUT, k + '=' + v + '\n'); console.log(k + '=' + v); };
const sh = () => { const K = (E.SUPABASE_SERVICE_KEY || '').trim(); if (!K) throw new Error('SUPABASE_SERVICE_KEY yok'); return { apikey: K, Authorization: 'Bearer ' + K, 'User-Agent': UA }; };

function trParca(ms) {
  const f = new Intl.DateTimeFormat('tr-TR', { timeZone: 'Europe/Istanbul', year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit', hour12: false });
  const p = Object.fromEntries(f.formatToParts(new Date(ms)).map(x => [x.type, x.value]));
  return { tarih: `${p.day}.${p.month}.${p.year}`, saat: `${p.hour}:${p.minute}`, kod: 'SGS-' + p.day + p.month };
}

async function zaman() {
  const hazirlik = +(E.HAZIRLIK_DK || 20), makine = Math.min(40, Math.max(1, +(E.MAKINE || 20)));
  const kapiMs = Math.ceil((Date.now() + hazirlik * 60000) / 60000) * 60000;
  const t = trParca(kapiMs);
  // GERCEK oturumla cakisma kapisi: test kodunun sonuclari ve anahtari temizlikte SILINIR - gercek oturumun kodu olamaz
  const takvim = JSON.parse(fs.readFileSync(path.join(KOK, 'veri', 'canli-deneme.json'), 'utf8').replace(/^﻿/, ''));
  const gercek = (takvim.oturumlar || []).map(o => { const p = o.tarih.split('.'); return ((o.sinav || '').indexOf('SGS') >= 0 ? 'SGS' : 'YET') + '-' + p[0] + p[1]; });
  if (gercek.includes(t.kod)) throw new Error(`CAKISMA: ${t.kod} gercek bir oturumun kodu - test bugun kosulamaz`);
  // canli uc: bu kodla hic sonuc var mi (varsa baskasinindir, silinmesin)
  const r = await fetch(`${SB}/rest/v1/canli_sonuc?select=id&oturum=eq.${t.kod}&limit=1`, { headers: sh() });
  if (!r.ok) throw new Error('canli_sonuc okunamadi HTTP ' + r.status);
  if ((await r.json()).length) throw new Error(`CAKISMA: canli_sonuc'ta ${t.kod} kodlu satir ZATEN var - test kosulmaz`);
  cikti('kapi_ms', kapiMs); cikti('tarih', t.tarih); cikti('saat', t.saat); cikti('kod', t.kod);
  cikti('liste', JSON.stringify(Array.from({ length: makine }, (_, i) => i + 1)));
}

async function kapi() {
  const kapiMs = +E.KAPI_MS, kod = E.KOD, run = E.RUN;
  const anahtar = crypto.createHash('sha256').update('tetikte-yuk-' + run).digest().toString('base64');
  const once = kapiMs - 1500 - Date.now();
  console.log(`kapiya ${Math.round(once / 1000)} sn`);
  if (once > 0) await new Promise(r => setTimeout(r, once));
  const r = await fetch(`${SB}/storage/v1/object/canli/anahtar-${kod}.json`, { method: 'POST', headers: { ...sh(), 'Content-Type': 'application/json', 'x-upsert': 'true' }, body: JSON.stringify({ anahtar }) });
  console.log(`anahtar yuklendi: HTTP ${r.status} · kapidan ${((Date.now() - kapiMs) / 1000).toFixed(2)} sn sonra`);
  if (!r.ok) throw new Error('anahtar yuklenemedi');
  const g = await fetch(`${SB}/storage/v1/object/public/canli/anahtar-${kod}.json?t=${Date.now()}`, { headers: { 'User-Agent': UA } });
  console.log(`herkese acik uctan okundu: HTTP ${g.status} · kapidan ${((Date.now() - kapiMs) / 1000).toFixed(2)} sn sonra`);
}

async function temizlik() {
  const kod = E.KOD, run = E.RUN, h = sh();
  if (!/^SGS-\d{4}$/.test(kod || '') || !run) throw new Error('KOD/RUN eksik - temizlik yapilmadi');
  // 1) test sonuclari
  const s = await fetch(`${SB}/rest/v1/canli_sonuc?oturum=eq.${kod}`, { method: 'DELETE', headers: { ...h, Prefer: 'return=representation' } });
  const sil = s.ok ? (await s.json()) : [];
  const cevapli = sil.filter(x => x.cevaplar).length;
  const k = await (await fetch(`${SB}/rest/v1/canli_sonuc?select=id&oturum=eq.${kod}`, { headers: h })).json();
  console.log(`canli_sonuc: silinen ${sil.length} (cevap dizili ${cevapli}) · kalan ${k.length}`);
  // 2) anahtar
  const a = await fetch(`${SB}/storage/v1/object/canli`, { method: 'DELETE', headers: { ...h, 'Content-Type': 'application/json' }, body: JSON.stringify({ prefixes: [`anahtar-${kod}.json`] }) });
  console.log(`anahtar silme: HTTP ${a.status}`);
  // 3) deneme uyeleri (yalniz bu kosunun e-posta onekiyle)
  const onek = `yuktest-${run}-`;
  let silinen = 0, hata = 0;
  for (let tur = 0; tur < 3; tur++) {
    const hedef = [];
    for (let p = 1; p <= 50; p++) {
      const r = await fetch(`${SB}/auth/v1/admin/users?page=${p}&per_page=1000`, { headers: h });
      if (!r.ok) throw new Error('uye listesi HTTP ' + r.status);
      const u = (await r.json()).users || [];
      u.filter(x => (x.email || '').startsWith(onek)).forEach(x => hedef.push(x.id));
      if (u.length < 1000) break;
    }
    if (!hedef.length) break;
    for (let i = 0; i < hedef.length; i += 10) {
      const rs = await Promise.all(hedef.slice(i, i + 10).map(id => fetch(`${SB}/auth/v1/admin/users/${id}`, { method: 'DELETE', headers: h }).then(r => r.ok)));
      rs.forEach(ok => ok ? silinen++ : hata++);
    }
  }
  let kalan = 0;
  for (let p = 1; p <= 50; p++) {
    const r = await fetch(`${SB}/auth/v1/admin/users?page=${p}&per_page=1000`, { headers: h });
    const u = (await r.json()).users || []; kalan += u.filter(x => (x.email || '').startsWith(onek)).length;
    if (u.length < 1000) break;
  }
  console.log(`deneme uyeleri: silinen ${silinen} · silme hatasi ${hata} · kalan ${kalan}`);
  if (k.length || kalan) throw new Error('TEMIZLIK EKSIK - elle bakilmali');
}

const kom = process.argv[2];
({ zaman, kapi, temizlik }[kom] || (async () => { throw new Error('komut: zaman | kapi | temizlik'); }))()
  .catch(e => { console.log('HATA: ' + e.message); process.exit(1); });
