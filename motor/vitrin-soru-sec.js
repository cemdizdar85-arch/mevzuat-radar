// VİTRİN SORUSU SEÇİCİ (09.09.2026, Cem: "koyacağımız sorular sınavın en zor ve dikkat çeken soruları olmalı")
// Ana sayfadaki Nöbetçi kartına girecek soruları HİSLE değil ÖLÇÜTLE seçer. Kaynak: basılı Kaydır-Çöz
// sayfalarındaki SORULAR verisi (kaydir/<sinav>/*.html) — hakem, simülasyon, çıkmış dönem sayımı orada hazır.
//
// Ölçütler (hepsi veride ölçülü, hiçbiri hafızadan değil):
//   ŞART  hakem EVET · öğrenci simülasyonu ikizi çözmüş · çıkmış pencere sayımı var
//   PUAN  hesaplı (tablolu) +3 · son 7 dönemin kaçında çıktı (0–7) · çözüm tablosu satırı /5 · dört tuzak dolu +1
//   ÇEŞİT ders başına en çok 3 soru
// Gerçek zorluk ölçüsü (hangi soruda ziyaretçi en çok yanılıyor) cevap_kayit kasası dolunca buraya eklenir;
// bugünkü "tablo uzunluğu" bir vekildir ve öyle söylenir.
//
// Kullanım: node motor/vitrin-soru-sec.js sgs [adet=10]
//   → veri/sinav/kaydir-secim/vitrin-<sinav>-secim.json  (kaydir-coz.ps1 -SecimDosya için)
// Basım: motor/vitrin-bas.ps1 -Sinav sgs  (seçim + kaydir/vitrin/<sinav>.html)
const fs = require('fs');
const path = require('path');
const sinav = process.argv[2] || 'sgs';
const adet = parseInt(process.argv[3] || '10', 10);
const kok = path.resolve(__dirname, '..');
const dizin = path.join(kok, 'kaydir', sinav);
if (!fs.existsSync(dizin)) { console.error('Kaydır-Çöz sayfası yok: ' + dizin + ' (önce kaydir-yayin.ps1 -Sinav ' + sinav + ')'); process.exit(2); }

const adaylar = [];
for (const f of fs.readdirSync(dizin)) {
  if (!f.endsWith('.html') || f === 'index.html') continue;
  const h = fs.readFileSync(path.join(dizin, f), 'utf8');
  const m = h.match(/const SORULAR=(\[\{[\s\S]*?\}\]);\n/);
  if (!m) { console.warn('SORULAR bulunamadı: ' + f); continue; }
  let liste; try { liste = JSON.parse(m[1]); } catch (e) { console.warn('JSON okunamadı: ' + f); continue; }
  for (const s of liste) {
    const o = s.olcum || {};
    if (String(o.hakem) !== 'EVET') continue;
    if (!(o.sim && o.sim.dogru === true)) continue;
    const donem = (s.cikmis && s.cikmis.pencereDonemler) ? s.cikmis.pencereDonemler.length : 0;
    if (!donem) continue;
    const satir = (s.tablo && s.tablo.satirlar) ? s.tablo.satirlar.length : 0;
    const hesapli = !s.teori && satir > 2;
    const tuzak = s.tuzak ? Object.keys(s.tuzak).length : 0;
    const puan = (hesapli ? 3 : 0) + donem + satir / 5 + (tuzak >= 4 ? 1 : 0);
    const [etiket, id] = String(s.id).split('/');
    adaylar.push({ etiket, id, ders: s.ders, konu: s.konu, donem, kurtarma: false,
      _puan: Math.round(puan * 100) / 100, _hesapli: hesapli, _satir: satir, _capa: (s.capa && s.capa.kaynak) || '' });
  }
}
adaylar.sort((a, b) => b._puan - a._puan);
const secim = []; const dersSay = {};
for (const a of adaylar) {
  if ((dersSay[a.ders] || 0) >= 3) continue;
  dersSay[a.ders] = (dersSay[a.ders] || 0) + 1;
  secim.push(a);
  if (secim.length >= adet) break;
}
const hedef = path.join(kok, 'veri', 'sinav', 'kaydir-secim', 'vitrin-' + sinav + '-secim.json');
const temiz = secim.map(({ etiket, id, ders, konu, donem, kurtarma }) => ({ etiket, id, ders, konu, donem, kurtarma }));
fs.writeFileSync(hedef, JSON.stringify(temiz, null, 2) + '\n', 'utf8');
console.log('aday ' + adaylar.length + ' · seçilen ' + secim.length + ' → ' + path.relative(kok, hedef));
for (const s of secim) console.log('  ' + s._puan.toFixed(2).padStart(6) + ' | ' + s.ders + ' | ' + s.konu + ' | ' + (s._hesapli ? 'hesaplı ' + s._satir + ' satır' : 'teori') + ' | dönem ' + s.donem + ' | ' + s._capa);
