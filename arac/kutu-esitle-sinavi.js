#!/usr/bin/env node
/* kutu-esitle-sinavi.js — YANLIŞ KUTUSU + ÇÖZÜLEN KAYDI HESAP EŞİTLEMESİNİN ÖZ-SINAVI (07.10.2026, dogrula.yml)
 *
 * kutu-esitle.js'in GERÇEK işlevlerini (replika değil) Node'da yükler ve ölçer:
 *   kutu (üç yönlü, cihazdaki "son eşitlenen" iziyle):
 *     - ilk eşitlemede hesapta olmayan yerel kayıt t=1 eklenir, hesaptaki ezilmez
 *     - bu cihazda eklenen / değişen hesaba "şimdi" damgasıyla gider; değişmeyen gönderilmez
 *     - bu cihazda çıkarılan hesaba {yok:1} gider (öbür cihaz da çıkarsın); zaten yok olan yeniden yazılmaz
 *     - cihaz kutusu kurulurken yok kayıtları atlanır, cihazdaki kimlik tipi (sayı/metin) korunur
 *   kayıt (çözülen / doğru %):
 *     - soru başına cihazdaki SON cevap, hesaptakinden yeniyse gider; eskiyse gitmez
 *     - hesap satırı büyükse (1,2 MB) konu/ders yazılmaz, yalnız {d,t}
 *     - hesaptaki daha yeni cevap cihaz günlüğüne eklenir (konu/ders dahil), günlük zamana göre sıralı, en çok 500
 * Mutasyon (kural 8): `--mutasyon` kuralları tek tek bozar — her bozmada sınav KIRMIZI düşmeli.
 * BU SINAV ŞUNU GÖRMEZ: Supabase tablosu, RLS, ağ, ilerleme.js'in birleştirmesi (o: mobil/ilerleme-sinavi.js),
 * sayfaların olayı dinleyip yeniden çizmesi (tarayıcıda ölçüldü 07.10, burada yok).
 */
'use strict';
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const DOSYA = path.join(__dirname, '..', 'kutu-esitle.js');
const MUTASYONLAR = {
  'ilk-esitleme': ['if (!izler) { if (!uzak[id]) d[id] = kayit(x, 1); return; }', 'if (!izler) { d[id] = kayit(x, 1); return; }'],
  'degisim':      ['if (!izler[id] || farkli(izler[id], x))', 'if (!izler[id])'],
  'cikarma':      ['if (!yerelId[id] && uzak[id] && !uzak[id].yok) d[id] = { yok: 1, t: simdi };', 'if (!yerelId[id] && uzak[id] && !uzak[id].yok) {}'],
  'yok-atla':     ['if (!x || x.yok) continue;', 'if (!x) continue;'],
  'kimlik-tipi':  ['id: id in tip ? tip[id] : id, konu: x.konu', 'id: id, konu: x.konu'],
  'kayit-yeni':   ['if (u && (u.t || 0) >= t) continue;', ''],
  'kayit-buyuk':  ['d[id] = buyuk ? { d: r.dogru ? 1 : 0, t: t } :', 'd[id] = false ? { d: r.dogru ? 1 : 0, t: t } :'],
  'kayit-kur':    ['if (!u || !u.t || u.t <= (sonYerel[id] || 0)) continue;', 'if (!u || !u.t) continue;'],
  'kayit-tavan':  ['return yeni.slice(-KAYIT_TAVAN);', 'return yeni;']
};

function yukle(kod) {
  const pencere = {};
  const ls = { length: 0, key() { return null; }, getItem() { return null; }, setItem() {} };
  const doc = { currentScript: null, addEventListener() {}, dispatchEvent() {} };
  vm.runInNewContext(kod, { window: pencere, document: doc, localStorage: ls, CustomEvent: function () {}, console: console });
  return pencere.ttKutuEsitle;
}

function sinav(K) {
  const s = []; const t = (ad, ok) => s.push([ad, !!ok]);
  const x = (id, tur, due, yanlis) => ({ id, konu: 'k', ders: 'd', donem: 0, tur, due, yanlis });
  let d;
  // --- kutu
  d = K.degisimler([x('a', 1, 10, 1), x('b', 1, 10, 1)], null, { b: { tur: 2, due: 50, yanlis: 1, t: 5 } }, 999);
  t('kutu ilk: hesapta olmayan t=1 eklenir', d.a && d.a.t === 1);
  t('kutu ilk: hesaptaki ezilmez', !d.b);
  d = K.degisimler([x('a', 1, 10, 1), x('c', 1, 20, 1)], { a: { tur: 1, due: 10, yanlis: 1 } }, { a: { tur: 1, due: 10, yanlis: 1, t: 1 } }, 999);
  t('kutu: bu cihazda eklenen hesaba', d.c && d.c.t === 999);
  t('kutu: değişmeyen gönderilmez', !d.a);
  d = K.degisimler([x('a', 2, 70, 1)], { a: { tur: 1, due: 10, yanlis: 1 } }, { a: { tur: 1, due: 10, yanlis: 1, t: 1 } }, 999);
  t('kutu: değişen hesaba', d.a && d.a.tur === 2 && d.a.t === 999);
  d = K.degisimler([], { a: { tur: 1, due: 10, yanlis: 1 } }, { a: { tur: 1, due: 10, yanlis: 1, t: 1 } }, 999);
  t('kutu: çıkarılan {yok} gider', d.a && d.a.yok === 1 && d.a.t === 999);
  d = K.degisimler([], { a: { tur: 1, due: 10, yanlis: 1 } }, { a: { yok: 1, t: 5 } }, 999);
  t('kutu: zaten yok olan yeniden yazılmaz', !d.a);
  const k = K.kutuKur({ '7': { tur: 1, due: 1, yanlis: 1, t: 1 }, z: { yok: 1, t: 2 }, q: { tur: 2, due: 3, yanlis: 2, t: 1 } }, [x(7, 1, 1, 1)]);
  t('kutu kur: yok atlanır', k.length === 2 && !k.some(y => y.id === 'z'));
  t('kutu kur: sayı kimlik korunur', k.some(y => y.id === 7));
  // --- kayıt
  const r = (id, dogru, tt) => ({ id, konu: 'Konu ' + id, ders: 'Ders', donem: 0, dogru, t: tt });
  d = K.kayitDegisim([r('a', false, 10), r('a', true, 20), r('b', true, 5)], { b: { d: 0, t: 50 } }, false);
  t('kayıt: soru başına son cevap gider', d.a && d.a.d === 1 && d.a.t === 20);
  t('kayıt: hesaptaki daha yeniyse gitmez', !d.b);
  t('kayıt: konu/ders yazılır', d.a && d.a.k === 'Konu a' && d.a.ders === 'Ders');
  d = K.kayitDegisim([r('a', true, 20)], {}, true);
  t('kayıt: büyük hesapta yalnız d,t', d.a && d.a.k === undefined && d.a.ders === undefined && d.a.t === 20);
  let log = K.kayitKur([r('a', true, 10)], { a: { d: 0, t: 5 }, b: { d: 1, t: 30, k: 'KB', ders: 'DB' }, c: { d: 0, t: 7 } }, {});
  t('kayıt kur: hesaptaki yeni cevap eklenir', log.some(y => y.id === 'b' && y.dogru === true && y.konu === 'KB' && y.ders === 'DB'));
  t('kayıt kur: cihazdakinden eski hesap cevabı eklenmez', log.filter(y => y.id === 'a').length === 1);
  t('kayıt kur: zamana göre sıralı', log.every((y, i) => !i || log[i - 1].t <= y.t));
  const cok = []; for (let i = 0; i < 520; i++) cok.push(r('s' + i, true, i + 1));
  t('kayıt kur: en çok 500', K.kayitKur(cok, {}, {}).length === 500);
  log = K.kayitKur([r(7, true, 1)], { '7': { d: 0, t: 9 } }, { '7': 7 });
  t('kayıt kur: sayı kimlik korunur', log.some(y => y.id === 7 && y.t === 9));
  return s;
}

function kos(kod) { try { return sinav(yukle(kod)); } catch (e) { return [['çöktü: ' + e.message, false]]; } }

const kod = fs.readFileSync(DOSYA, 'utf8');
if (process.argv.includes('--mutasyon')) {
  let tutan = 0; const adlar = Object.keys(MUTASYONLAR);
  for (const ad of adlar) {
    const [eski, yeni] = MUTASYONLAR[ad];
    if (kod.indexOf(eski) < 0) { console.log('mutasyon hedefi bulunamadı: ' + ad); process.exit(3); }
    const dustu = kos(kod.replace(eski, yeni)).some(v => !v[1]);
    console.log('  mutasyon ' + ad.padEnd(13) + (dustu ? 'KIRMIZI (doğru)' : 'YESIL (YANLIŞ — sınav bu kuralı ölçmüyor)'));
    if (dustu) tutan++;
  }
  console.log('MUTASYON: ' + tutan + '/' + adlar.length + ' kırmızı');
  process.exit(tutan === adlar.length ? 0 : 1);
}
const s = kos(kod);
s.forEach(([ad, ok]) => console.log((ok ? '  GEÇTİ ' : '  DÜŞTÜ ') + ad));
const gec = s.filter(v => v[1]).length;
console.log('KUTU-ESITLE ÖZ-SINAVI: ' + gec + '/' + s.length);
process.exit(gec === s.length ? 0 : 1);
