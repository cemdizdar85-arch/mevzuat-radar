#!/usr/bin/env node
/* ilerleme-sinavi.js — HESABA EŞİTLEMENİN BİRLEŞTİRME ÖZ-SINAVI (26.09.2026, dogrula.yml)
 *
 * mobil/uygulama/ilerleme.js'in GERÇEK birlestir() işlevini (replika değil) Node'da çalıştırır ve ölçer:
 * telefon ile sunucu (ya da iki cihaz) kaydı birleşince hiçbir ilerleme kaybolmuyor mu?
 *   - soru başına en yeni cevap kazanır; yalnız bir tarafta olan cevap korunur
 *   - kaldırılan bayrak/not (yok izi) diğer cihazdaki ESKİ kaydı siler; daha yeni ekleme izi ezer
 *   - günlük sayaçta büyük olan, kaldığın yerde en yeni, ayarda en yeni kazanır
 *   - birleştirme simetrik (a+b = b+a) ve kendine uygulanınca değişmez; girdileri değiştirmez
 * Mutasyon (kural 8): `--mutasyon` birleştirmeyi bilerek bozar — her bozmada sınav KIRMIZI düşmeli.
 * BU SINAV ŞUNU GÖRMEZ: Supabase tablosu, RLS, ağ (canlı prova ister).
 */
'use strict';
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const { spawnSync } = require('child_process');

const DOSYA = path.join(__dirname, 'uygulama', 'ilerleme.js');
const MUTASYONLAR = {
  'en-yeni':  ['return tt(b) > tt(a) ? b : a;', 'return a;'],
  'gun-max':  ['g[k] = Math.max(g[k] || 0, b.gun[k]);', 'g[k] = b.gun[k];'],
  'tek-taraf': ['for (k in a) s[k] = a[k];', ''],
  'ayar':     ['ayar: tt(b.ayar) > tt(a.ayar) ? b.ayar : a.ayar', 'ayar: a.ayar']
};

if (process.argv.includes('--mutasyon')) {
  let tutan = 0;
  for (const ad of Object.keys(MUTASYONLAR)) {
    const r = spawnSync(process.execPath, [__filename], { env: Object.assign({}, process.env, { IL_MUTASYON: ad }), encoding: 'utf8' });
    const dustu = r.status !== 0; if (dustu) tutan++;
    console.log('  mutasyon ' + ad.padEnd(10) + (dustu ? 'KIRMIZI (doğru)' : 'YESIL (YANLIŞ — sınav bu kuralı ölçmüyor)'));
  }
  console.log('MUTASYON: ' + tutan + '/' + Object.keys(MUTASYONLAR).length + ' → KIRMIZI');
  process.exit(tutan === Object.keys(MUTASYONLAR).length ? 0 : 1);
}

let kod = fs.readFileSync(DOSYA, 'utf8');
const mut = process.env.IL_MUTASYON;
if (mut) {
  const [eski, yeni] = MUTASYONLAR[mut];
  if (kod.indexOf(eski) < 0) { console.log('mutasyon hedefi bulunamadı: ' + mut); process.exit(3); }
  kod = kod.split(eski).join(yeni);
}
const kutu = { module: { exports: {} } };
kutu.exports = kutu.module.exports;
vm.createContext(kutu);
vm.runInContext('var module=this.module;(function(){' + kod + '}).call(this.exports);', kutu);
const { birlestir, ayni } = kutu.module.exports;
if (typeof birlestir !== 'function') { console.log('birlestir dışa verilmedi'); process.exit(1); }

let gecen = 0, toplam = 0;
function t(ad, kosul, not) { toplam++; if (kosul) gecen++; console.log((kosul ? '  ✓ ' : '  ✗ ') + ad + (kosul ? '' : '  → ' + (not || ''))); }
const J = (x) => JSON.stringify(x);

const tel = { surum: 1,
  cevap: { a1: { s: 'yan', t: 100, yol: 'x' }, a2: { s: 'ok', t: 300, yol: 'x' } },
  bayrak: { b1: { yol: 'x', i: 1, t: 100 }, b2: { yok: 1, t: 500 } },
  not: { n1: { m: 'telefon', t: 200 } },
  konum: { 'x': { i: 4, t: 400 } }, son: { yol: 'x', i: 4, t: 400 },
  gun: { '2026-09-26': 7 }, ayar: { hedef: 20, t: 50 } };
const sun = { surum: 1,
  cevap: { a1: { s: 'ok', t: 200, yol: 'x' }, a3: { s: 'yan', t: 150, yol: 'y' } },
  bayrak: { b2: { yol: 'x', i: 2, t: 300 }, b3: { yok: 1, t: 90 } },
  not: { n1: { yok: 1, t: 250 }, n2: { m: 'site', t: 10 } },
  konum: { 'x': { i: 9, t: 350 }, 'y': { i: 2, t: 10 } }, son: { yol: 'y', i: 2, t: 10 },
  gun: { '2026-09-26': 3, '2026-09-25': 12 }, ayar: { hedef: 40, t: 900 } };
const telKopya = J(tel), sunKopya = J(sun);
const r = birlestir(tel, sun);

t('1 aynı soru iki cihazda: en yeni cevap kazanır (a1 sunucudaki "ok")', r.cevap.a1.s === 'ok', J(r.cevap.a1));
t('2 yalnız telefonda olan cevap korunur (a2)', r.cevap.a2 && r.cevap.a2.s === 'ok', J(r.cevap));
t('3 yalnız sunucuda olan cevap gelir (a3)', r.cevap.a3 && r.cevap.a3.yol === 'y', J(r.cevap));
t('4 telefonda KALDIRILAN bayrak (yeni iz) sunucudaki eski bayrağı siler (b2 yok)', r.bayrak.b2 && r.bayrak.b2.yok === 1, J(r.bayrak.b2));
t('5 eski kaldırma izi yeni bayrağı ezmez (b1 duruyor)', r.bayrak.b1 && !r.bayrak.b1.yok, J(r.bayrak.b1));
t('6 sunucuda daha yeni silinen not telefondaki eski notu siler (n1 yok)', r.not.n1 && r.not.n1.yok === 1, J(r.not.n1));
t('7 yalnız bir tarafta olan not korunur (n2)', r.not.n2 && r.not.n2.m === 'site', J(r.not));
t('8 kaldığın yer: ders başına en yeni (x → 4. soru, telefon daha yeni)', r.konum.x.i === 4 && r.konum.y.i === 2, J(r.konum));
t('9 son çalışılan: en yeni (telefondaki x)', r.son && r.son.yol === 'x', J(r.son));
t('10 günlük sayaç: aynı günde büyük olan (7), başka gün korunur (12)', r.gun['2026-09-26'] === 7 && r.gun['2026-09-25'] === 12, J(r.gun));
t('11 ayar: en yeni değişiklik kazanır (hedef 40)', r.ayar.hedef === 40, J(r.ayar));
t('12 girdiler değişmedi (saf işlev)', J(tel) === telKopya && J(sun) === sunKopya);
const r2 = birlestir(sun, tel);
t('13 simetrik: a+b = b+a (anahtar sırası hariç)', ayni(r, r2), 'fark var');
t('14 kendine uygulanınca değişmez (birleşik + birleşik = birleşik)', ayni(birlestir(r, r), r));
t('15 boş sunucu (ilk eşitleme): telefonun kaydı aynen kalır', J(birlestir(tel, null).cevap) === J(tel.cevap) && birlestir(tel, null).gun['2026-09-26'] === 7);
t('16 eski biçim konum (sayı) bozulmadan taşınır', birlestir({ surum: 1, konum: { z: 5 } }, null).konum.z.i === 5);

console.log('ILERLEME-SINAVI: ' + (gecen === toplam ? 'YESIL' : 'KIRMIZI') + ' — ' + gecen + '/' + toplam + (mut ? ' · IL_MUTASYON=' + mut : ''));
process.exit(gecen === toplam ? 0 : 1);
