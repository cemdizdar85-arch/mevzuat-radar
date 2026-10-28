#!/usr/bin/env node
// ============================================================================
//  SGS DERS SAYFASI SORU SIRASI — AYNI KONU ART ARDA GELMESİN (28.10.2026, bedel 0, model yok)
//
//  OLAY (ölçüldü 28.10, paket_soru sayfa+sira+veri.konu): 15 SGS ders sayfasının 15'inde aynı konu 3+ soru art arda;
//    15'inin 15'inde ilk 10 soruda. En uzun: Yabancı Dil 28, Denetim 15, MTA/Maliyet/Türkçe 14; Denetim, MTA, Maliyet,
//    Türkçe, Matematik, Meslek Hukuku, Vergi'de ilk 10 sorunun 10'u TEK konu. Cem'in hesabında SGS Finansal Muhasebe
//    "kesin mizan" sorusunu 5 kez art arda verdi. Kök: arac/sgs-650-bas.ps1 seçim dosyalarını (her biri tek konu) dosya
//    sırasıyla birleştiriyordu. Yeterlilik (motor/smmm-ders-sira.js, 12.10) ve KGK'da sorun yok (en uzun 3 / 2).
//    Cem 28.10: "ders sayfalarında aynı konudan sorular art arda gelmesin; önce kaç derste böyle olduğunu ölç, sonra karıştır".
//  KURAL (ders başına; ders = seçim kaydının 'ders' alanı, motor/kaydir-yayin.ps1'in sayfa grubuyla aynı):
//    1) İLK 10: her biri FARKLI konudan (dersin konu sayısı 10'dan azsa o kadar farklı, sonra 2. tur).
//    2) SONRASI: yumuşak ağırlıklı sıra, ağırlık = konunun bu dersteki soru sayısı (büyük konu daha sık, ama dağılarak);
//       seçilen konu bir önceki soruyla AYNIYSA, sorusu kalan başka konu varsa o alınır → art arda aynı konu yalnız
//       dersin kalan sorularının hepsi tek konudaysa olur.
//    3) Konu içinde seçim dosyasındaki sıra korunur. Eşitlikte konu adı karması (sabit; her yayında aynı sıra).
//  KÜME DEĞİŞMEZ: yalnız sıra değişir; kayıtların alanlarına dokunulmaz. Çıktı girdiyle aynı sayıda ve aynı (etiket,id)
//    kümesinden oluşmazsa ÇIKIŞ 2 (dosya yazılmaz).
//  KALDIĞIN YER: sıra değişince uygulamanın sıra numarasıyla tuttuğu konum başka soruyu gösterir → yayin-bas.yml bu
//    sırayla AYNI işte arac/smmm-konum-gocu.js --kod sgs ile eski i → kimlik → yeni i çevirir (12.10 bitirme düzeni).
//  🚫 GÖRMEZ: konu adı yazımı farklı ama aynı konu (katlama: küçük harf + boşluk; "denklem cozme"/"denklem çözme" iki konu
//    sayılır) · zorluk serpiştirme (SGS'de etiketten okunur ama bu araç bakmaz) · kasa-yukle.js seviyeSirala'nın cihazda
//    yeniden dizmesi (bu sıra onun girdisidir).
//
//  KULLANIM:
//    node motor/sgs-ders-sira.js --secim <yol>      seçim dosyasını yerinde yeni sıraya dizer (ders başına önce/sonra en uzun dizi)
//    node motor/sgs-ders-sira.js --olc <yol>        yalnız ölçer (yazmaz)
//    node motor/sgs-ders-sira.js --sinav            öz-sınav (yapay vakalar + depodaki seçim dosyasında eşdeğerlik)
//    node motor/sgs-ders-sira.js --mutasyon         her kuralı bilerek bozar; öz-sınav her birinde KIRMIZI düşmeli
// ============================================================================
'use strict';
const fs = require('fs'), path = require('path');
const ILK = 10;
const MUT = process.env.SIRA_MUTASYON || '';
const katla = k => String(k || '').trim().toLocaleLowerCase('tr').replace(/\s+/g, ' ');
const karma = s => [...String(s)].reduce((h, c) => (h * 31 + c.charCodeAt(0)) % 1000003, 7);
const anahtar = r => r.etiket + '/' + r.id;

// Bir dersin kayıtlarını yeni sıraya dizer (saf).
function dersDiz(kayitlar) {
  const gr = new Map();
  kayitlar.forEach(r => { const k = katla(r.konu); if (!gr.has(k)) gr.set(k, []); gr.get(k).push(r); });
  const konular = [...gr.keys()].sort((a, b) => gr.get(b).length - gr.get(a).length || karma(a) - karma(b));
  const kalan = new Map(konular.map(k => [k, gr.get(k).slice()])), toplam = kayitlar.length, agirlik = new Map(konular.map(k => [k, gr.get(k).length]));
  const sayac = new Map(konular.map(k => [k, 0])), out = [], ilkKullanilan = new Set();
  let onceki = null;
  while (out.length < toplam) {
    const acik = konular.filter(k => kalan.get(k).length);
    acik.forEach(k => sayac.set(k, sayac.get(k) + agirlik.get(k)));
    let aday = acik.slice().sort((a, b) => sayac.get(b) - sayac.get(a) || karma(a) - karma(b));
    if (out.length < ILK && MUT !== 'ilk10') { const yeni = aday.filter(k => !ilkKullanilan.has(k)); if (yeni.length) aday = yeni; }
    if (MUT !== 'artarda' && aday.length > 1 && aday[0] === onceki) aday = aday.slice(1).concat(aday[0]);
    const k = aday[0];
    out.push(kalan.get(k).shift()); sayac.set(k, sayac.get(k) - toplam); onceki = k; if (out.length <= ILK) ilkKullanilan.add(k);
  }
  if (MUT === 'kayip') out.pop();
  return out;
}

// Seçim dizisini ders başına dizer; ders blokları ilk görülme sırasında kalır (kaydir-yayin.ps1 zaten derse göre gruplar).
function secimDiz(dizi) {
  const dersler = new Map();
  dizi.forEach(r => { const d = String(r.ders || ''); if (!dersler.has(d)) dersler.set(d, []); dersler.get(d).push(r); });
  const out = []; for (const [, L] of dersler) out.push(...dersDiz(L));
  return out;
}

// Ölçü: ders başına en uzun art arda aynı konu, ilk 10'da en uzun, ilk 10'da farklı konu.
function olc(dizi) {
  const D = new Map(); dizi.forEach(r => { const d = String(r.ders || ''); if (!D.has(d)) D.set(d, []); D.get(d).push(katla(r.konu)); });
  const s = {};
  for (const [d, k] of D) { let en = 1, cur = 1, bas = 1; for (let i = 1; i < k.length; i++) { cur = k[i] === k[i - 1] ? cur + 1 : 1; en = Math.max(en, cur); if (i < ILK) bas = Math.max(bas, cur); }
    s[d] = { n: k.length, enUzun: k.length ? en : 0, ilk10Uzun: k.length ? bas : 0, ilk10Farkli: new Set(k.slice(0, ILK)).size, konu: new Set(k).size }; }
  return s;
}
function kumeAyni(a, b) { if (a.length !== b.length) return false; const s = new Set(a.map(anahtar)); return b.every(r => s.has(anahtar(r))) && new Set(b.map(anahtar)).size === b.length; }
// Dersin kalan soruları tek konuya kalmadıkça art arda aynı konu olmamalı: izinli dizi = sondaki tek-konu kuyruğu.
function artArdaIhlal(dizi) {
  const D = new Map(); dizi.forEach(r => { const d = String(r.ders || ''); if (!D.has(d)) D.set(d, []); D.get(d).push(katla(r.konu)); });
  let ihlal = 0;
  for (const [, k] of D) { let kuyruk = k.length - 1; while (kuyruk > 0 && k[kuyruk - 1] === k[k.length - 1]) kuyruk--;
    for (let i = 1; i < kuyruk; i++) if (k[i] === k[i - 1]) ihlal++; }
  return ihlal;
}

function sinav() {
  const V = []; const t = (ad, k) => V.push([ad, !!k]);
  const yap = (ders, plan) => { const L = []; plan.forEach(([konu, n]) => { for (let i = 0; i < n; i++) L.push({ etiket: 'e-' + konu, id: 'kp-' + i, ders, konu }); }); return L; };
  const A = yap('X', [['a', 20], ['b', 5], ['c', 3], ['d', 2], ['e', 2], ['f', 1], ['g', 1], ['h', 1], ['i', 1], ['j', 1], ['k', 1]]);
  const ra = secimDiz(A), oa = olc(ra).X;
  t('küme aynı (38 soru)', kumeAyni(A, ra));
  t('ilk 10 hepsi farklı konu (11 konu var)', oa.ilk10Farkli === 10);
  t('art arda aynı konu yok (tek konu kuyruğu dışında)', artArdaIhlal(ra) === 0);
  const B = yap('Y', [['a', 6], ['b', 6]]), rb = secimDiz(B);
  t('iki eşit konu tam dönüşümlü (en uzun 1)', olc(rb).Y.enUzun === 1);
  const C = yap('Z', [['a', 10], ['b', 1]]), rc = secimDiz(C);
  t('baskın konu: kuyruk dışında art arda yok', artArdaIhlal(rc) === 0 && kumeAyni(C, rc));
  const E = yap('P', [['a', 3]]).concat(yap('Q', [['b', 2], ['c', 2]])), re = secimDiz(E);
  t('ders blokları korunur (P önce, Q sonra)', re.slice(0, 3).every(r => r.ders === 'P') && re.slice(3).every(r => r.ders === 'Q'));
  t('sabit: iki koşu aynı sıra', JSON.stringify(secimDiz(A).map(anahtar)) === JSON.stringify(ra.map(anahtar)));
  t('konu içi sıra korunur (a: kp-0 kp-1 …)', ra.filter(r => r.konu === 'a').every((r, i) => r.id === 'kp-' + i));
  const yol = path.join(__dirname, '..', 'veri', 'sinav', 'kaydir-secim', 'sgs-650-secim.json');
  if (fs.existsSync(yol)) {
    const G = JSON.parse(fs.readFileSync(yol, 'utf8').replace(/^﻿/, '')), rg = secimDiz(G), og = olc(rg), once = olc(G);
    const dersler = Object.keys(og);
    t('GERÇEK seçim: küme aynı (' + G.length + ' soru)', kumeAyni(G, rg));
    t('GERÇEK seçim: art arda ihlal 0 (önce ' + artArdaIhlal(G) + ')', artArdaIhlal(rg) === 0);
    t('GERÇEK seçim: her derste ilk 10 farklı konu (konu ≥10 olan derslerde)', dersler.every(d => og[d].konu < ILK || og[d].ilk10Farkli === ILK));
    t('GERÇEK seçim: ders sayısı ve ders başına soru aynı', dersler.length === Object.keys(once).length && dersler.every(d => once[d].n === og[d].n));
  } else t('GERÇEK seçim dosyası var', false);
  V.forEach(([a, k]) => console.log((k ? '  ✓ ' : '  ✗ ') + a));
  const g = V.filter(v => v[1]).length; console.log('SGS-SIRA ÖZ-SINAV: ' + g + '/' + V.length + (MUT ? ' (mutasyon ' + MUT + ')' : ''));
  return g === V.length;
}

module.exports = { dersDiz, secimDiz, olc };
const arg = process.argv.slice(2), al = n => { const i = arg.indexOf(n); return i >= 0 ? arg[i + 1] : null; };
if (require.main !== module) { /* başka betikten çağrıldı: yalnız işlevler */ }
else if (arg.includes('--mutasyon')) {
  const { spawnSync } = require('child_process'); let ok = 0; const M = ['ilk10', 'artarda', 'kayip'];
  for (const m of M) { const r = spawnSync(process.execPath, [__filename, '--sinav'], { env: Object.assign({}, process.env, { SIRA_MUTASYON: m }), encoding: 'utf8' });
    const kir = r.status !== 0; if (kir) ok++; console.log('  mutasyon ' + m.padEnd(8) + (kir ? 'KIRMIZI (doğru — sınav yakaladı)' : 'YEŞİL (YANLIŞ — sınav kör)')); }
  console.log('MUTASYON: ' + ok + '/' + M.length + ' → KIRMIZI'); process.exit(ok === M.length ? 0 : 1);
} else if (arg.includes('--sinav')) {
  process.exit(sinav() ? 0 : 1);
} else if (al('--secim') || al('--olc')) {
  const yol = al('--secim') || al('--olc'), G = JSON.parse(fs.readFileSync(yol, 'utf8').replace(/^﻿/, ''));
  const once = olc(G), rg = secimDiz(G), sonra = olc(rg);
  for (const d of Object.keys(sonra)) console.log('  ' + d.padEnd(40) + ' n=' + String(sonra[d].n).padStart(4) + '  en uzun ' + once[d].enUzun + ' → ' + sonra[d].enUzun + '  ilk10 farklı ' + once[d].ilk10Farkli + ' → ' + sonra[d].ilk10Farkli);
  if (!kumeAyni(G, rg)) { console.error('KÜME DEĞİŞTİ — dosya yazılmadı'); process.exit(2); }
  if (al('--secim')) { fs.writeFileSync(yol, JSON.stringify(rg, null, 2)); console.log('SGS SIRA: ' + rg.length + ' soru yeni sırayla yazıldı'); }
} else { console.log('kullanım: --secim <yol> | --olc <yol> | --sinav | --mutasyon'); process.exit(1); }
