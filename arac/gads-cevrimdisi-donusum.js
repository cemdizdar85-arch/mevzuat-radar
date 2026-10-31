#!/usr/bin/env node
/* GOOGLE ADS ÇEVRİMDIŞI DÖNÜŞÜM CSV'Sİ (28.10.2026, Cem 27.10 "satışı Google'a bildirelim").
   Son 90 günün ÖDENEN siparişlerinden Google tıklama kimliği (gclid) taşıyanları alır, Google Ads "Dönüşümler →
   İçe aktar" CSV'sini yazar. Kimlik reklam tıklamasında menu.js'te cihaza (tt_gclid), siparişte satin-al.html ile
   siparisler.gads_tiklama'ya yazılır (radar-app/sql/2026-10-28-gads-tiklama.sql).
   Google'a giden: tıklama kimliği · dönüşüm adı · ödeme zamanı · tutar · para birimi. Ad, e-posta, telefon, sipariş no
   GİTMEZ. Çıktı DEPOYA YAZILMAZ (depo public, satır bir alıcının ödemesine bağlı) → _yerel-veri-kasasi/gads/.
     node arac/gads-cevrimdisi-donusum.js                 → ambardan oku (SUPABASE_SERVICE_KEY), kasaya yaz
     node arac/gads-cevrimdisi-donusum.js --cikti <dosya> → başka yere yaz (depo içi reddedilir)
     node arac/gads-cevrimdisi-donusum.js --sinav         → öz-sınav (ağ yok)  · --mutasyon → her bozma KIRMIZI mı
   Yükleme Google Ads panelinden elle (pazarlama oturumu); dönüşüm işleminin adı TAM OLARAK DONUSUM_ADI olmalı.
   🚫 GÖRMEZ: gbraid/wbraid (iOS) tıklamaları (ilk sürümde siparişe yazılmıyor) · reklama tıklayıp başka cihazdan alan ·
   iade edilen siparişin daha önce yüklenmiş dönüşümü (Google'da elle geri alınır; bu betik yalnız 'odendi' yazar) ·
   aynı siparişin iki kez yüklenmesi (Google aynı kimlik + ad + zamanı tekrar sayar mı ölçülmedi; her yüklemede son 90
   gün yeniden yazılır → panelde yalnız yeni dosya yüklenir, eskisi silinmez). */
'use strict';
const fs = require('fs'), path = require('path');
const KOK = path.join(__dirname, '..');
const DONUSUM_ADI = 'Tetikte Satis (cevrimdisi)';
const PARA = 'TRY', TZ_DAKIKA = 180, GUN = 90;
const DESEN = /^[A-Za-z0-9_-]{10,200}$/;   // = menu.js TK_DESEN = SQL siparisler_gads_tiklama_bicim
const MUT = process.env.GADS_MUTASYON || '';

function yerelZaman(iso) {   // UTC → +03:00, "yyyy-MM-dd HH:mm:ss"
  const t = Date.parse(iso); if (isNaN(t)) return null;
  const d = new Date(t + (MUT === 'tz' ? 0 : TZ_DAKIKA * 60000));
  const p = n => String(n).padStart(2, '0');
  return `${d.getUTCFullYear()}-${p(d.getUTCMonth() + 1)}-${p(d.getUTCDate())} ${p(d.getUTCHours())}:${p(d.getUTCMinutes())}:${p(d.getUTCSeconds())}`;
}

/* satırlar: {durum, tutar, odendi_tarihi, gads_tiklama, gads_tiklama_zaman} → {csv, yazilan, atlanan:{neden:adet}} */
function csvUret(satirlar, simdi) {
  const sinir = simdi - GUN * 86400000, atlanan = {}, satir = [];
  const atla = n => { atlanan[n] = (atlanan[n] || 0) + 1; };
  for (const s of satirlar) {
    if (MUT !== 'durum' && s.durum !== 'odendi') { atla('odenmemis'); continue; }
    const k = String(s.gads_tiklama || '');
    if (!k) { atla('kimliksiz'); continue; }
    if (MUT !== 'desen' && !DESEN.test(k)) { atla('bozuk-kimlik'); continue; }
    const od = Date.parse(s.odendi_tarihi || '');
    if (isNaN(od)) { atla('odeme-zamani-yok'); continue; }
    if (MUT !== 'gun' && od < sinir) { atla('90-gunden-eski'); continue; }
    const tk = Date.parse(s.gads_tiklama_zaman || '');
    if (!isNaN(tk) && MUT !== 'gun' && tk < sinir) { atla('tiklama-90-gunden-eski'); continue; }
    if (!isNaN(tk) && MUT !== 'sira' && od < tk) { atla('odeme-tiklamadan-once'); continue; }
    const tutar = Number(s.tutar);
    if (!(tutar > 0)) { atla('tutarsiz'); continue; }
    satir.push([k, DONUSUM_ADI, yerelZaman(s.odendi_tarihi), tutar.toFixed(2), PARA].join(','));
  }
  const tz = (TZ_DAKIKA >= 0 ? '+' : '-') + String(Math.floor(Math.abs(TZ_DAKIKA) / 60)).padStart(2, '0') + String(Math.abs(TZ_DAKIKA) % 60).padStart(2, '0');
  const csv = ['Parameters:TimeZone=' + tz, 'Google Click ID,Conversion Name,Conversion Time,Conversion Value,Conversion Currency', ...satir].join('\r\n') + '\r\n';
  return { csv, yazilan: satir.length, atlanan };
}

function sinav() {
  const simdi = Date.parse('2026-10-28T12:00:00Z'), G = 'Cj0KCQjw' + 'a'.repeat(40), sonuc = []; let dus = 0;
  const vaka = (ad, k) => { sonuc.push((k ? 'GEÇTİ ' : 'DÜŞTÜ ') + ad); if (!k) dus++; };
  const s = (o) => Object.assign({ durum: 'odendi', tutar: 2988, odendi_tarihi: '2026-10-27T11:05:09Z', gads_tiklama: G, gads_tiklama_zaman: '2026-10-26T08:00:00Z' }, o);
  const r = csvUret([s({})], simdi), sat = r.csv.split('\r\n');
  vaka('ilk satır Parameters:TimeZone=+0300', sat[0] === 'Parameters:TimeZone=+0300');
  vaka('başlık satırı Google sütunlarıyla aynı', sat[1] === 'Google Click ID,Conversion Name,Conversion Time,Conversion Value,Conversion Currency');
  vaka('satır: kimlik, ad, +03 zaman, tutar, TRY', sat[2] === G + ',Tetikte Satis (cevrimdisi),2026-10-27 14:05:09,2988.00,TRY');
  vaka('gece yarısı geçişi (UTC 22:30 → ertesi gün 01:30)', csvUret([s({ odendi_tarihi: '2026-10-26T22:30:00Z' })], simdi).csv.indexOf(',2026-10-27 01:30:00,') > 0);
  vaka('ondalık tutar noktayla', csvUret([s({ tutar: '2867.5' })], simdi).csv.indexOf(',2867.50,TRY') > 0);
  const atlar = [[{ durum: 'odeme_bekliyor' }, 'odenmemis'], [{ durum: 'iade' }, 'odenmemis'], [{ durum: 'iptal' }, 'odenmemis'],
    [{ gads_tiklama: null }, 'kimliksiz'], [{ gads_tiklama: 'a,b"c' + 'x'.repeat(20) }, 'bozuk-kimlik'], [{ gads_tiklama: '=HYPERLINK("x")' + 'a'.repeat(10) }, 'bozuk-kimlik'],
    [{ odendi_tarihi: null }, 'odeme-zamani-yok'], [{ odendi_tarihi: '2026-07-29T11:00:00Z', gads_tiklama_zaman: null }, '90-gunden-eski'],
    [{ gads_tiklama_zaman: '2026-07-01T00:00:00Z' }, 'tiklama-90-gunden-eski'],
    [{ gads_tiklama_zaman: '2026-10-27T12:00:00Z' }, 'odeme-tiklamadan-once'], [{ tutar: 0 }, 'tutarsiz']];
  for (const [o, n] of atlar) { const x = csvUret([s(o)], simdi);
    vaka('atlanır: ' + JSON.stringify(o) + ' → ' + n, x.yazilan === 0 && x.atlanan[n] === 1 && x.csv.split('\r\n').filter(Boolean).length === 2); }
  vaka('tıklama zamanı yoksa yine yazılır', csvUret([s({ gads_tiklama_zaman: null })], simdi).yazilan === 1);
  vaka('89 günlük ödeme yazılır', csvUret([s({ odendi_tarihi: '2026-07-31T12:00:00Z', gads_tiklama_zaman: null })], simdi).yazilan === 1);
  const csv = csvUret([s({}), s({ gads_tiklama: 'EAIaIQob' + 'b'.repeat(40) })], simdi).csv;
  vaka('çıktıda kişisel alan yok (e-posta/ad/sipariş no sütunu yok, satır 5 alan)', csv.split('\r\n').slice(1).filter(Boolean).every(l => l.split(',').length === 5) && !/@/.test(csv));
  vaka('istemci + SQL deseniyle aynı', (() => {
    const m = /TK_DESEN=\/(.+?)\//.exec(fs.readFileSync(path.join(KOK, 'menu.js'), 'utf8'));
    const q = fs.readFileSync(path.join(KOK, 'radar-app/sql/2026-10-28-gads-tiklama.sql'), 'utf8');
    return !!m && m[1] === DESEN.source && q.split("'" + DESEN.source + "'").length >= 3; })());
  vaka('kasa yolu depo dışında', !icinde(KOK, kasaYolu(true) || path.join(KOK, '..', '_yerel-veri-kasasi')));
  sonuc.forEach(x => console.log(x));
  console.log(`GADS ÇEVRİMDIŞI DÖNÜŞÜM ÖZ-SINAVI: ${sonuc.length - dus}/${sonuc.length}` + (MUT ? ' (mutasyon ' + MUT + ')' : ''));
  return dus;
}

function icinde(ust, yol) { const g = path.relative(path.resolve(ust), path.resolve(yol)); return !!g && !g.startsWith('..') && !path.isAbsolute(g) || g === ''; }
function kasaYolu(sessiz) {
  const aday = [process.env.TETIKTE_VERI_KASASI, path.join(KOK, '..', '_yerel-veri-kasasi')].filter(Boolean);
  const k = aday.find(a => fs.existsSync(a));
  if (!k && !sessiz) throw new Error('veri kasası yok (' + aday.join(' · ') + '). Ayrı kopyadan koşuyorsan TETIKTE_VERI_KASASI ver ya da --cikti');
  return k || null;
}

async function ambardan() {
  const SK = (process.env.SUPABASE_SERVICE_KEY || '').trim(); if (!SK) throw new Error('SUPABASE_SERVICE_KEY yok');
  const sinir = new Date(Date.now() - GUN * 86400000).toISOString(), LIM = 5000;
  const url = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/siparisler?select=durum,tutar,odendi_tarihi,gads_tiklama,gads_tiklama_zaman'
    + '&durum=eq.odendi&gads_tiklama=not.is.null&odendi_tarihi=gte.' + encodeURIComponent(sinir) + '&order=odendi_tarihi.asc&limit=' + LIM;
  const r = await fetch(url, { headers: { apikey: SK, Authorization: 'Bearer ' + SK } });
  if (!r.ok) throw new Error('ambar ' + r.status + ' ' + (await r.text()).slice(0, 200));
  const v = await r.json();
  if (v.length >= LIM) throw new Error('satır tavanı ' + LIM + ' doldu: çıktı eksik olurdu, sayfalama ekle');
  return v;
}

(async () => {
  const a = process.argv.slice(2);
  if (a.includes('--mutasyon')) {
    const { execFileSync } = require('child_process'); let kacan = 0; const M = ['tz', 'durum', 'desen', 'gun', 'sira'];
    for (const m of M) { let kirmizi = false;
      try { execFileSync(process.execPath, [__filename, '--sinav'], { env: { ...process.env, GADS_MUTASYON: m }, stdio: 'pipe' }); } catch (e) { kirmizi = e.status === 1; }
      console.log((kirmizi ? 'KIRMIZI (doğru) ' : 'YEŞİL KALDI (sınav kör) ') + m); if (!kirmizi) kacan++; }
    console.log(`MUTASYON: ${M.length - kacan}/${M.length} KIRMIZI`); process.exit(kacan ? 1 : 0);
  }
  if (a.includes('--sinav')) process.exit(sinav() ? 1 : 0);
  const i = a.indexOf('--cikti');
  const hedef = i >= 0 ? path.resolve(a[i + 1] || '') : path.join(kasaYolu(), 'gads', 'gads-cevrimdisi-' + new Date(Date.now() + TZ_DAKIKA * 60000).toISOString().slice(0, 10).replace(/-/g, '') + '.csv');
  if (icinde(KOK, hedef)) throw new Error('çıktı depo içine yazılmaz (depo public): ' + hedef);
  const v = await ambardan();
  const r = csvUret(v, Date.now());
  fs.mkdirSync(path.dirname(hedef), { recursive: true });
  fs.writeFileSync(hedef, r.csv, 'utf8');
  console.log(`ambar: son ${GUN} günde gclid'li ödenen sipariş ${v.length} · CSV'ye yazılan ${r.yazilan} · atlanan ${JSON.stringify(r.atlanan)}`);
  console.log('dosya: ' + hedef);
  console.log('KÖR: gbraid/wbraid tıklamaları siparişe yazılmıyor (ilk sürüm) · başka cihazdan alan · iade sonrası Google\'daki eski dönüşüm');
})().catch(e => { console.error('HATA: ' + e.message); process.exit(2); });
