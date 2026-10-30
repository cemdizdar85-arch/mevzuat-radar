#!/usr/bin/env node
// ============================================================================
//  BİTİRME TEMİZLİĞİ — kör çözücü düzeni (30.10.2026, Cem: "yanlış soru olmasın"; standart BITIRME-SORU-STANDARDI.md D3)
//  Bedel 0 (model çağrısı YOK; çözücüler Claude oturumunun kendi ajanlarıdır). Soru metni ve anahtar DEPOYA GİRMEZ:
//  bütün çıktılar veri/fabrika/temizlik/ altına (gitignore) ya da TEMIZLIK_DIR'e yazılır.
//
//  node arac/bitirme-temizlik/temizlik.js indir <N> <etiket>     her ders sayfasının ilk N sorusu (paket_soru.sira);
//        daha önce kontrol edilen (veri/sinav/bitirme-duzeltme/kontrol-edilen.json + önceki GIZLI-anahtar-*.json) ayrılır
//        → kor-<etiket>/<DERS>.json (YALNIZ id,sira,ders,soru,siklar — tablo/adım/açıklama YOK: 30.10'da sızdı)
//        → _anahtar-gizli/GIZLI-anahtar-<etiket>.json + <etiket>-tam.json  (çözücüye VERİLMEZ)
//  node arac/bitirme-temizlik/temizlik.js karsilastir <etiket>    cozum-<etiket>-A-*.json / -B-*.json ↔ anahtar
//        TEMIZ · ANAHTAR-SUPHE (iki tur aynı, anahtardan farklı) · INCELE → karsilastirma-<etiket>.json
//  node arac/bitirme-temizlik/temizlik.js ozet <etiket>           INCELE'yi sınıflar: CEVAP_AYRISIK · YIL_VERGI · KUSUR · YANLIS_ALARM
//        (yıl notu yalnız Vergi'de kusur — standart D7) + doğrulayıcı paketi _anahtar-gizli/dogrula-<etiket>.json
//  🚫 GÖRMEZ: çözücünün yanılgısı (kararı DOGRULAYICI-TALIMAT.md ile resmî metin verir) · açıklamadaki kusur (çözücü açıklamayı görmez;
//     doğrulayıcı görür) · sıralama değişince ilk N'e yeni giren soruyu bir sonraki 'indir' alır.
// ============================================================================
'use strict';
const fs = require('fs'), path = require('path');
const KOK = path.resolve(__dirname, '..', '..');
const W = process.env.TEMIZLIK_DIR || path.join(KOK, 'veri', 'fabrika', 'temizlik');
const G = path.join(W, '_anahtar-gizli');
const SB = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/';
const KOD = { 'finansal-muhasebe': 'FM', 'finansal-tablolar': 'FTA', 'maliyet-muhasebesi': 'MAL', 'muhasebe-denetimi': 'DEN', 'vergi': 'VER', 'hukuk': 'HUK', 'meslek-hukuku': 'MES', 'sermaye-piyasasi': 'SPK' };
const oku = f => JSON.parse(fs.readFileSync(f, 'utf8').replace(/^﻿/, ''));
const [, , kip, a1, a2] = process.argv;

async function indir(N, ET) {
  const K = process.env.SUPABASE_SERVICE_KEY; if (!K) { console.error('SUPABASE_SERVICE_KEY yok'); process.exit(2); }
  const h = { apikey: K, Authorization: 'Bearer ' + K };
  fs.mkdirSync(G, { recursive: true });
  const kontrol = new Set(oku(path.join(KOK, 'veri', 'sinav', 'bitirme-duzeltme', 'kontrol-edilen.json')).kimlik);
  for (const f of fs.readdirSync(G)) if (/^GIZLI-anahtar-.*\.json$/.test(f) && f !== `GIZLI-anahtar-${ET}.json`) Object.keys(oku(path.join(G, f))).forEach(i => kontrol.add(i));
  const out = [];
  for (const slug of Object.keys(KOD)) {
    const r = await fetch(`${SB}paket_soru?select=*&sinav=eq.smmm&sayfa=eq.${encodeURIComponent('kaydir/smmm/' + slug + '.html')}&order=sira.asc&limit=${N}`, { headers: h }).then(r => r.json());
    if (!Array.isArray(r)) { console.error('HATA', JSON.stringify(r).slice(0, 200)); process.exit(1); }
    out.push(...r);
  }
  const yeni = out.filter(r => !kontrol.has(r.id)); const kor = {}, an = {};
  for (const r of yeni) { const k = KOD[r.sayfa.replace(/.*\/|\.html/g, '')], v = r.veri || {}; (kor[k] ||= []).push({ id: r.id, sira: r.sira, ders: r.ders, soru: v.soru, siklar: v.siklar }); an[r.id] = { ders: k, sira: r.sira, dogru: v.dogru }; }
  const kd = path.join(W, `kor-${ET}`); fs.mkdirSync(kd, { recursive: true });
  for (const [k, a] of Object.entries(kor)) fs.writeFileSync(path.join(kd, `${k}.json`), JSON.stringify(a, null, 1));
  fs.writeFileSync(path.join(G, `GIZLI-anahtar-${ET}.json`), JSON.stringify(an, null, 1));
  fs.writeFileSync(path.join(G, `${ET}-tam.json`), JSON.stringify(yeni, null, 1));
  console.log(`ilk ${N}: toplam ${out.length} · daha önce kontrol edilen ${out.length - yeni.length} · yeni ${yeni.length}`, Object.fromEntries(Object.entries(kor).map(([k, a]) => [k, a.length])), '→', kd);
}

function karsilastir(ET) {
  const anahtar = oku(path.join(G, `GIZLI-anahtar-${ET}.json`)); const tur = { A: {}, B: {} };
  for (const f of fs.readdirSync(W)) { const m = f.match(new RegExp('^cozum-' + ET + '-([AB])-.*\\.json$')); if (m) for (const c of oku(path.join(W, f))) tur[m[1]][c.id] = c; }
  const sonuc = [], say = {};
  for (const [id, k] of Object.entries(anahtar)) {
    const a = tur.A[id], b = tur.B[id]; let karar;
    if (!a || !b) karar = 'EKSIK';
    else if (a.cevap === k.dogru && b.cevap === k.dogru && !a.kusur && !b.kusur) karar = 'TEMIZ';
    else if (a.cevap === b.cevap && /^[A-E]$/.test(a.cevap) && a.cevap !== k.dogru) karar = 'ANAHTAR-SUPHE';
    else karar = 'INCELE';
    (say[k.ders] ||= {})[karar] = (say[k.ders][karar] || 0) + 1;
    if (karar !== 'TEMIZ') sonuc.push({ id, ders: k.ders, sira: k.sira, karar, anahtar: k.dogru, A: a && { c: a.cevap, e: a.emin, d: a.dayanak, k: a.kusur }, B: b && { c: b.cevap, e: b.emin, d: b.dayanak, k: b.kusur } });
  }
  fs.writeFileSync(path.join(W, `karsilastirma-${ET}.json`), JSON.stringify(sonuc, null, 1));
  console.table(say); console.log('incelenecek', sonuc.length);
}

function ozet(ET) {
  const s = oku(path.join(W, `karsilastirma-${ET}.json`)); const tam = Object.fromEntries(oku(path.join(G, `${ET}-tam.json`)).map(r => [r.id, r]));
  const yil = x => [x.A && x.A.k, x.B && x.B.k].filter(Boolean).every(k => /^\s*YIL KURALI/i.test(k));
  const fark = x => (x.A && x.A.c !== x.anahtar) || (x.B && x.B.c !== x.anahtar);
  const L = { ANAHTAR: [], CEVAP_AYRISIK: [], YIL_VERGI: [], KUSUR: [], YANLIS_ALARM: [] };
  for (const x of s) { if (x.karar === 'EKSIK') continue; const g = x.karar === 'ANAHTAR-SUPHE' ? 'ANAHTAR' : fark(x) ? 'CEVAP_AYRISIK' : yil(x) ? (x.ders === 'VER' ? 'YIL_VERGI' : 'YANLIS_ALARM') : 'KUSUR'; L[g].push(x); }
  const paket = [...L.ANAHTAR, ...L.CEVAP_AYRISIK, ...L.KUSUR].map(x => { const v = tam[x.id].veri; return { id: x.id, ders: x.ders, sira: x.sira, soru: v.soru, siklar: v.siklar, anahtar: v.dogru, aciklama: (v.sade && v.sade.dogru) || v.kural || '', dayanak: v.dayanak || v.kaynak || '', cozucu_A: x.A, cozucu_B: x.B }; });
  fs.writeFileSync(path.join(G, `dogrula-${ET}.json`), JSON.stringify(paket, null, 1));
  fs.writeFileSync(path.join(W, `yil-vergi-${ET}.json`), JSON.stringify(L.YIL_VERGI.map(x => x.id), null, 1));
  for (const g of Object.keys(L)) console.log(g, L[g].length);
  console.log('doğrulayıcı paketi', paket.length, '→', path.join(G, `dogrula-${ET}.json`));
}

(async () => {
  if (kip === 'indir') await indir(+a1 || 120, a2 || 'tur3');
  else if (kip === 'karsilastir') karsilastir(a1);
  else if (kip === 'ozet') ozet(a1);
  else console.log('kip: indir <N> <etiket> | karsilastir <etiket> | ozet <etiket>');
})();
