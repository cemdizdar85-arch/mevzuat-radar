// ============================================================================
//  SEVİYE HAVUZU BASICI — "30 soruda geçme ihtimalini ölç" (seviye-testi.html) soru havuzu.
//
//  NEDEN (13.09.2026, Cem): "ilk testim müşteri çekmek için; bu sınavda kaç puan alırsın,
//  denetle tarzı; sınav kadar soru çözersek olmaz." -> 20 soruluk uyarlamalı test.
//
//  NE YAPAR
//   · 30 soruluk plan: her dersin sınavdaki payı × 30, en büyük artık yöntemiyle, her derse
//     en az 1 (veri/sgs-sinav-yapisi.json). Sonuç: FM 6, Denetim 4, Maliyet/MTA/Matematik/Türkçe/
//     YD/Ekonomi/Maliye 2'şer, kalan 6 ders 1'er - öz-sınav toplamın 30 ve dağılımın bu olduğunu doğrular.
//   · Dört grup (sonuç ekranı + karne maili): Muhasebe (FM, Maliyet, MTA, Denetim) · Hukuk
//     (Meslek, İş-SGK, Vergi, Ticaret, Borçlar) · Ekonomi ve Maliye · Genel Kültür ve Yabancı Dil.
//     Tek soruyla ders hakkında hüküm verilmez; grup düzeyinde gösterilir.
//   · Her ders × zorluk (kolay/zor/çok zor, soru kimliğindeki üretim etiketi) kutusundan en çok
//     KUTU soru: önce "Sınav gibi çöz" setlerinde OLMAYANLAR (test denemeyi bozmasın), yetmezse
//     (Türkçe, Atatürk, Matematik'te setlere girmeyen soru neredeyse yok) tüm havuzdan tamamlanır.
//   · Sayfa: aynı cihaza daha önce gösterilen soruyu tekrar göstermez, şık sırasını karıştırır.
//
//  ÇIKTI: veri/seviye/sgs-havuz.json · API maliyeti SIFIR.
//  Kaydır-Çöz SGS basımından sonra motor/kaydir-yayin.ps1 koşturur (deneme setlerinden SONRA).
// ============================================================================
const fs = require('fs');
const path = require('path');
const KOK = path.join(__dirname, '..');
const KURU = process.argv.includes('--kuru');
// 16.09.2026 — 20 -> 30 SORU (Cem kararı). Ölçüldü (benzetim, sitenin kendi modeliyle 700 sahte aday):
// tahminin gerçekten sapması 20 soruda ±12,5 puan · 30'da ±10,7 · 35'te ±10,1 · 40'ta ±9,4; geçer/kalır
// tersine çıkma 20'de %10,4 · 30'da %9,0. Kazancın çoğu 30'da alınıyor, sonrası düzleşiyor. Ayrıca 20 soruda
// 8 ders TEK soruyla temsil ediliyordu (tek soruyla ders hakkında hüküm verilemez); 30'da FM 6, Denetim 4.
// KUTU 10 -> 15: üye tekrar çözdüğünde aynı soruların dönmemesi için ders×zorluk kutusu büyütüldü.
const TEST_SORU = 30, KUTU = 15;
const ZORLUKLAR = ['kolay', 'zor', 'cokzor'];

const jsonOku = y => JSON.parse(fs.readFileSync(y, 'utf8').replace(/^﻿/, ''));
const katla = s => String(s || '').toLocaleLowerCase('tr').replace(/ı/g, 'i').replace(/ğ/g, 'g').replace(/ü/g, 'u').replace(/ş/g, 's').replace(/ö/g, 'o').replace(/ç/g, 'c').replace(/[^a-z0-9]+/g, ' ').trim();
const slug = s => katla(s).replace(/ /g, '-');
function sayfaOku(d) { const h = fs.readFileSync(d, 'utf8'); const b = h.indexOf('const SORULAR='); if (b < 0) return null; const e = h.indexOf('\n', b); const s = h.slice(b, e < 0 ? h.length : e); try { return JSON.parse(s.slice(s.indexOf('['), s.lastIndexOf(']') + 1)); } catch (x) { return null; } }
const zorluk = id => /cokzor/.test(id) ? 'cokzor' : /-zor/.test(id) ? 'zor' : /kolay/.test(id) ? 'kolay' : null;

const GRUP = {
  'finansal muhasebe': 'Muhasebe', 'maliyet muhasebesi': 'Muhasebe', 'mali tablolar analizi': 'Muhasebe', 'denetim': 'Muhasebe',
  'meslek hukuku': 'Hukuk', 'is ve sosyal guvenlik hukuku': 'Hukuk', 'vergi hukuku': 'Hukuk', 'ticaret hukuku': 'Hukuk', 'borclar hukuku': 'Hukuk',
  'ekonomi': 'Ekonomi ve Maliye', 'maliye': 'Ekonomi ve Maliye',
  'turkce': 'Genel Kültür ve Yabancı Dil', 'matematik': 'Genel Kültür ve Yabancı Dil', 'ataturk ilkeleri ve inkilap tarihi': 'Genel Kültür ve Yabancı Dil', 'yabanci dil': 'Genel Kültür ve Yabancı Dil'
};

const yapi = jsonOku(path.join(KOK, 'veri', 'sgs-sinav-yapisi.json')).sgs;
const dersler = []; yapi.bolumler.forEach(b => b.dersler.forEach(d => dersler.push({ ders: d.ders, sinav: d.soru })));
// 20 soruluk plan: en az 1, kalan en büyük artıkla
const toplam = dersler.reduce((t, d) => t + d.sinav, 0);
// artık = tam pay − VERİLEN adet. "En az 1"e yükseltilen dersin artığı eksiye düşer ve fazladan soru almaz.
// (İlk sürüm artığı floor'a göre alıyordu: Ekonomi 0,92 ile 2 soru kapıyordu, Yabancı Dil 1'de kalıyordu -
//  öz-sınav "FM 4 / Denetim 2 / YD 2" kontrolüyle yakaladı.)
dersler.forEach(d => { const tam = d.sinav * TEST_SORU / toplam; d.test = Math.max(1, Math.floor(tam)); d.artik = tam - d.test; });
let kalan = TEST_SORU - dersler.reduce((t, d) => t + d.test, 0);
dersler.slice().sort((a, b) => b.artik - a.artik).forEach(d => { if (kalan > 0) { d.test++; kalan--; } });

const setIdleri = new Set();
try { const dz = jsonOku(path.join(KOK, 'veri', 'deneme', 'sgs-dizin.json')); dz.setler.forEach(s => jsonOku(path.join(KOK, s.dosya)).sorular.forEach(q => setIdleri.add(q.id))); } catch (e) {}

const sayfalar = {};
for (const f of fs.readdirSync(path.join(KOK, 'kaydir', 'sgs'))) {
  if (!f.endsWith('.html') || f === 'index.html') continue;
  const S = sayfaOku(path.join(KOK, 'kaydir', 'sgs', f)); if (!S || !S.length) continue;
  const ad = String(S[0].ders || '').split('|')[0].trim(); if (slug(ad) + '.html' !== f) continue;
  sayfalar[katla(ad)] = { ad, dosya: `kaydir/sgs/${f}`, S };
}

const hatalar = [], havuz = {}, plan = [], rapor = [];
for (const d of dersler) {
  const k = katla(d.ders), p = sayfalar[k];
  if (!p) { hatalar.push('ders sayfası yok: ' + d.ders); continue; }
  if (!GRUP[k]) { hatalar.push('grup eşlemesi yok: ' + d.ders); continue; }
  plan.push({ ders: p.ad, grup: GRUP[k], adet: d.test });
  havuz[p.ad] = {};
  const satir = [];
  for (const z of ZORLUKLAR) {
    const uygun = p.S.map((s, sira) => ({ s, sira })).filter(x => zorluk(String(x.s.id)) === z && x.s.soru && x.s.siklar && Object.keys(x.s.siklar).length === 5 && x.s.siklar[x.s.dogru])
      .sort((a, b) => String(a.s.id).localeCompare(String(b.s.id)));
    const setsiz = uygun.filter(x => !setIdleri.has(x.s.id)), setli = uygun.filter(x => setIdleri.has(x.s.id));
    const secilen = setsiz.slice(0, KUTU).concat(setli.slice(0, Math.max(0, KUTU - setsiz.length)));
    if (secilen.length < d.test) hatalar.push(`${p.ad} ${z}: ${secilen.length} soru, en az ${d.test} gerekli`);
    havuz[p.ad][z] = secilen.map(x => ({ id: x.s.id, soru: x.s.soru, siklar: x.s.siklar, dogru: x.s.dogru, sayfa: p.dosya, sira: x.sira }));
    satir.push(`${z} ${secilen.length} (setsiz ${Math.min(setsiz.length, KUTU)})`);
  }
  rapor.push(`${p.ad.padEnd(34)} testte ${d.test} · ${satir.join(' · ')}`);
}

// ÖZ-SINAV
const planToplam = plan.reduce((t, x) => t + x.adet, 0);
if (planToplam !== TEST_SORU) hatalar.push(`plan toplamı ${planToplam} (beklenen ${TEST_SORU})`);
const fm = plan.find(x => katla(x.ders) === 'finansal muhasebe'), den = plan.find(x => katla(x.ders) === 'denetim'), yd = plan.find(x => katla(x.ders) === 'yabanci dil');
// 16.09: 30 soruluk planın beklenen dağılımı (sınav payından: FM 26/130, Denetim 16/130, YD 10/130)
if (!fm || fm.adet !== 6 || !den || den.adet !== 4 || !yd || yd.adet !== 2) hatalar.push('plan dağılımı beklenenden farklı (FM 6 / Denetim 4 / YD 2)');
if (plan.some(x => x.adet < 1)) hatalar.push('sıfır sorulu ders var');
const grupToplam = {}; plan.forEach(x => grupToplam[x.grup] = (grupToplam[x.grup] || 0) + x.adet);

console.log('SEVİYE HAVUZU (SGS)');
rapor.forEach(r => console.log('  ' + r));
console.log('  grup başına soru:', JSON.stringify(grupToplam));
if (hatalar.length) { console.log('KIRMIZI - yazılmadı:'); hatalar.forEach(h => console.log('  · ' + h)); process.exit(1); }
if (KURU) { console.log('  kuru koşu - yazılmadı'); process.exit(0); }

const cikti = { uretici: 'motor/seviye-havuz-bas.js', sinav: 'sgs', test_soru: TEST_SORU, plan, havuz };
const hedef = path.join(KOK, 'veri', 'seviye', 'sgs-havuz.json');
fs.mkdirSync(path.dirname(hedef), { recursive: true });
const yeni = JSON.stringify(cikti) + '\n';
let eski = null; try { eski = fs.readFileSync(hedef, 'utf8'); } catch (e) {}
if (eski === yeni) console.log('  değişiklik yok - dosyaya dokunulmadı');
else { fs.writeFileSync(hedef, yeni, 'utf8'); console.log(`  yazıldı -> veri/seviye/sgs-havuz.json (${Math.round(yeni.length / 1024)} KB)`); }
