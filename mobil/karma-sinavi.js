#!/usr/bin/env node
/* karma-sinavi.js — uygulama-karma.js (kısa sınav / en çok çıkanlar) soru seçiminin öz-sınavı (26.09.2026)
 *
 * Sahte kasa (paket_soru) ile TTKarma.cek() koşturulur; ölçülen:
 *   K1 kısa sınav n soru döner, K2 dersler dengeli (en çok − en az ≤ 1), K3 aynı soru iki kez yok,
 *   K4 her kartın yolu sorunun GERÇEK sayfası (karne/ilerleme doğru derse yazılsın),
 *   K5 en çok çıkanlar yalnız en yüksek dönemli 3n içinden seçer, K6 1000+ satırda sayfalama (hepsi okunur),
 *   K7 kasada soru yoksa boş dizi (kasa-yukle.js "paketinde yok" mesajını gösterir).
 * Mutasyon: KR_MUTASYON=denge|sayfalama — seçici bilerek bozulur, sınav KIRMIZI vermeli.
 * Kullanım: node mobil/karma-sinavi.js   (dogrula.yml)
 */
'use strict';
const fs = require('fs'), path = require('path'), vm = require('vm');
const KAYNAK = fs.readFileSync(path.join(__dirname, 'uygulama', 'uygulama-karma.js'), 'utf8');
const MUT = process.env.KR_MUTASYON || '';

function kasa(adet, dersSayisi) {
  const s = [];
  for (let i = 0; i < adet; i++) {
    const d = i % dersSayisi;
    s.push({ id: 'k' + String(i).padStart(5, '0'), ders: 'Ders ' + d, sayfa: 'kaydir/smmm/d' + d + '.html', sinav: 'smmm',
      veri: { soru: 'soru ' + i, donem: i % 50 } });
  }
  return s;
}
function sahteSb(satirlar) {
  let okunan = 0;
  const sb = { okunan: () => okunan, from() {
    const q = { _in: null, _ara: null, select() { return q; }, eq() { return q; }, order() { return q; },
      range(a, b) { q._ara = [a, b]; return q; }, in(_, ids) { q._in = ids; return q; },
      then(coz, red) {
        let data;
        if (q._in) data = satirlar.filter((x) => q._in.includes(x.id)).map((x) => ({ id: x.id, veri: x.veri }));
        else {
          const [a, b] = q._ara;
          const ust = MUT === 'sayfalama' ? Math.min(b, 999) : b;
          data = satirlar.slice(a, ust + 1).map((x) => ({ id: x.id, ders: x.ders, sayfa: x.sayfa, donem: x.veri.donem }));
          if (MUT === 'sayfalama' && a > 0) data = [];
          okunan += data.length;
        }
        return Promise.resolve({ data, error: null }).then(coz, red);
      } };
    return q;
  } };
  return sb;
}
function yukle(arama) {
  const pencere = {};
  const belge = { documentElement: { getAttribute: () => 'kaydir/smmm/d0.html' },
    createElement: () => ({ style: {}, remove() {} }), head: { appendChild() {} }, body: { appendChild() {} },
    getElementById: () => null };
  let kaynak = KAYNAK;
  if (MUT === 'denge') kaynak = kaynak.replace('return karistir(s);', 'return karistir(liste).slice(0, n);');
  vm.runInNewContext(kaynak, { window: pencere, document: belge, location: { search: arama, pathname: '/x' },
    setTimeout: () => 0, setInterval: () => 0, clearInterval: () => 0, Math, Date, Object, JSON, Promise });
  return pencere.TTKarma;
}

let gecen = 0, toplam = 0;
function sonuc(ad, tamam, not) { toplam++; if (tamam) gecen++; console.log((tamam ? '  ✓ ' : '  ✗ ') + ad + (tamam ? '' : '  → ' + not)); }

(async () => {
  /* kısa sınav: 8 ders, 2.400 soru, n=20 */
  const k = kasa(2400, 8), sb = sahteSb(k), T = yukle('?karma=kisa&n=20');
  const s = await T.cek(sb);
  sonuc('K1 kısa sınav 20 soru döner', s.length === 20, s.length);
  const ders = {}; s.forEach((v) => { const d = k.find((x) => x.veri === v).ders; ders[d] = (ders[d] || 0) + 1; });
  const sayi = Object.values(ders);
  sonuc('K2 dersler dengeli (fark ≤ 1)', Object.keys(ders).length === 8 && Math.max(...sayi) - Math.min(...sayi) <= 1, JSON.stringify(ders));
  sonuc('K3 aynı soru iki kez yok', new Set(s).size === s.length, 'tekrar var');
  const yolDogru = s.every((v, i) => T.yol(i) === k.find((x) => x.veri === v).sayfa);
  sonuc('K4 kart yolu sorunun gerçek sayfası', yolDogru, 'yol kaydı yanlış');
  sonuc('K6 1000+ satır sayfalamayla okunur', sb.okunan() === 2400, 'okunan ' + sb.okunan());

  /* en çok çıkanlar: donem 0–49; n=20 → yalnız en yüksek 60 içinden */
  const T2 = yukle('?karma=cok&n=20'), s2 = await T2.cek(sahteSb(k));
  const esik = k.map((x) => x.veri.donem).sort((a, b) => b - a)[59];
  sonuc('K5 en çok çıkanlar üst 3n içinden', s2.length === 20 && s2.every((v) => v.donem >= esik), 'eşik ' + esik);

  const T3 = yukle('?karma=kisa&n=10'), s3 = await T3.cek(sahteSb([]));
  sonuc('K7 kasa boşsa boş dizi', Array.isArray(s3) && s3.length === 0, JSON.stringify(s3));

  const yesil = gecen === toplam;
  console.log('KARMA-SINAVI: ' + (yesil ? 'YESIL' : 'KIRMIZI') + ' — ' + gecen + '/' + toplam + (MUT ? ' (mutasyon: ' + MUT + ')' : ''));
  process.exit(yesil ? 0 : 1);
})().catch((e) => { console.error(e); process.exit(1); });
