// VİTRİN SORUSU SEÇİCİ (09.09.2026, Cem: "koyacağımız sorular sınavın en zor ve dikkat çeken soruları olmalı";
// 09.09 akşam Cem: "vitrinde çok çıkan sorular olmalı, 1 tane değil")
// Ana sayfadaki gösterimlik karta girecek soruları HİSLE değil ÖLÇÜTLE seçer. Kaynak: basılı Kaydır-Çöz
// sayfalarındaki SORULAR verisi (kaydir/<sinav>/*.html) — hakem, simülasyon, çıkmış dönem sayımı orada hazır.
//
// Ölçütler (hepsi veride ölçülü, hiçbiri hafızadan değil):
//   ŞART  hakem EVET · öğrenci simülasyonu ikizi çözmüş · GERÇEK çıkma sayısı (cikmis.donemler) ≥ 3 dönem
//         (⚠ pencereDonemler.length PENCERE genişliğidir, her soruda 7; ilk sürüm onu sayıyordu — 09.09 düzeltildi)
//   PUAN  çıkma sayısı ×2 · hesaplı (tablolu) +2 · çözüm tablosu satırı /10 · dört tuzak dolu +1
//   ÇEŞİT ders başına en çok 3, aynı konudan 1
// Gerçek zorluk ölçüsü (hangi soruda ziyaretçi en çok yanılıyor) cevap_kayit kasası dolunca buraya eklenir.
//
// Kullanım: node motor/vitrin-soru-sec.js sgs [adet=10]
//   → veri/sinav/kaydir-secim/vitrin-<sinav>-secim.json  (kaydir-coz.ps1 -SecimDosya için)
// Basım: motor/vitrin-bas.ps1 -Sinav sgs  (seçim + kaydir/vitrin/<sinav>.html)
const fs = require('fs');
const path = require('path');
const sinav = process.argv[2] || 'sgs';
const adet = parseInt(process.argv[3] || '10', 10);
const EN_AZ_DONEM = 3;
const kok = path.resolve(__dirname, '..');
const dizin = path.join(kok, 'kaydir', sinav);
if (!fs.existsSync(dizin)) { console.error('Kaydır-Çöz sayfası yok: ' + dizin + ' (önce kaydir-yayin.ps1 -Sinav ' + sinav + ')'); process.exit(2); }

const adaylar = []; let toplam = 0;
for (const f of fs.readdirSync(dizin)) {
  if (!f.endsWith('.html') || f === 'index.html') continue;
  const h = fs.readFileSync(path.join(dizin, f), 'utf8');
  const m = h.match(/const SORULAR=(\[\{[\s\S]*?\}\]);\r?\n/);   // git autocrlf: yerelde CRLF olabilir
  if (!m) { console.warn('SORULAR bulunamadı: ' + f); continue; }
  let liste; try { liste = JSON.parse(m[1]); } catch (e) { console.warn('JSON okunamadı: ' + f); continue; }
  for (const s of liste) {
    toplam++;
    const o = s.olcum || {};
    if (String(o.hakem) !== 'EVET') continue;
    if (!(o.sim && o.sim.dogru === true)) continue;
    const donem = (s.cikmis && Array.isArray(s.cikmis.donemler)) ? s.cikmis.donemler.length : 0;
    if (donem < EN_AZ_DONEM) continue;
    const satir = (s.tablo && s.tablo.satirlar) ? s.tablo.satirlar.length : 0;
    const hesapli = !s.teori && satir > 2;
    const tuzak = s.tuzak ? Object.keys(s.tuzak).length : 0;
    const puan = donem * 2 + (hesapli ? 2 : 0) + satir / 10 + (tuzak >= 4 ? 1 : 0);
    const [etiket, id] = String(s.id).split('/');
    adaylar.push({ etiket, id, ders: s.ders, konu: s.konu, donem, kurtarma: false,
      _puan: Math.round(puan * 100) / 100, _hesapli: hesapli, _satir: satir, _capa: (s.capa && s.capa.kaynak) || '' });
  }
}
adaylar.sort((a, b) => b._puan - a._puan);
const secim = []; const dersSay = {}; const konuGordu = new Set();
for (const a of adaylar) {
  const konuAnahtar = String(a.konu || '').toLowerCase().replace(/\s+/g, ' ').trim();
  if (konuGordu.has(konuAnahtar)) continue;
  if ((dersSay[a.ders] || 0) >= 3) continue;
  konuGordu.add(konuAnahtar); dersSay[a.ders] = (dersSay[a.ders] || 0) + 1;
  secim.push(a);
  if (secim.length >= adet) break;
}
const hedef = path.join(kok, 'veri', 'sinav', 'kaydir-secim', 'vitrin-' + sinav + '-secim.json');
const temiz = secim.map(({ etiket, id, ders, konu, donem, kurtarma }) => ({ etiket, id, ders, konu, donem, kurtarma }));
fs.writeFileSync(hedef, JSON.stringify(temiz, null, 2) + '\n', 'utf8');
console.log('taranan ' + toplam + ' · ≥' + EN_AZ_DONEM + ' dönem aday ' + adaylar.length + ' · seçilen ' + secim.length + ' → ' + path.relative(kok, hedef));
for (const s of secim) console.log('  ' + s._puan.toFixed(2).padStart(6) + ' | ' + s.donem + ' dönem | ' + s.ders + ' | ' + s.konu + ' | ' + (s._hesapli ? 'hesaplı ' + s._satir + ' satır' : 'teori') + ' | ' + s._capa);
if (!secim.length) { console.error('hiç aday yok'); process.exit(3); }
