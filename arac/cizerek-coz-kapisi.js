#!/usr/bin/env node
/* KAPI-CZ — "Nöbetçi çizerek çözsün" rakam/aritmetik kapısının öz-sınavı ve pilot listesi raporu (14.10.2026).
 *
 * Kapının kendisi cizerek-coz.js içinde (cizerekKapi): sitede düğme yalnız kapı geçerse çıkar.
 *   node arac/cizerek-coz-kapisi.js --sinav              öz-sınav (uydurma, bankada olmayan soru nesneleriyle; depo public)
 *   node arac/cizerek-coz-kapisi.js --sinav --mutasyon   her kilit koşulu tek tek bozulur (CIZ_MUTASYON), her bozmada sınav KIRMIZI olmalı
 *   node arac/cizerek-coz-kapisi.js --liste <paket.json> PILOT listesindeki her soruyu kapıdan geçirir. paket.json = { "<id>": { veri: {...} } }
 *                                                        (ambardan servis anahtarıyla yerelde çekilir; DEPOYA KONMAZ). Çıktıda soru metni yok.
 *
 * 🚫 GÖRMEZ: sözel kusur (adım metni yanlış kural anlatıyor ama sayılar tutuyor) · adım sırasının mantığı · birimli
 *   ifade ("5 kilogram × 18 ₺/kilogram") hesaplanmaz · kelimeli işlem ("3 Mart + 10 gün") hesaplanmaz · yalnız 3 haneli
 *   tam sayılardan oluşan toplam ("151 + 152 + 620") hesap kodu sayılır, denetlenmez · alt yazının anlamı.
 */
'use strict';
const path = require('path');
const { spawnSync } = require('child_process');
const C = require(path.join(__dirname, '..', 'cizerek-coz.js'));
const a = process.argv.slice(2);

/* Uydurma soru: bankadaki hiçbir soruyla aynı değildir (kural: depoya soru içeriği girmez). */
function soru(d) {
  return Object.assign({
    id: 'sinav/kp-01', soru: 'Bir işletme 1.03.2026 tarihinde 12 aylık 48.000 ₺ sigorta primini peşin ödemiş ve tamamını gider yazmıştır. 2026 yılı kârı kaç ₺ düşük gösterilmiştir?',
    siklar: { A: '8.000', B: '12.000', C: '40.000', D: '48.000', E: '36.000' }, dogru: 'A',
    adimlar: [
      { verilenAdim: true, formul: 'Verilen: prim 48.000 (soruda verilen); süre 12 ay (soruda verilen)', anlatim: 'Soru bize 48.000 ₺ primi ve 12 ayı vermiş.' },
      { formul: 'Aylık pay = 48.000 / 12 = 4.000', anlatim: 'Önce aylık payı buluyoruz.' },
      { formul: 'Cari dönem payı = 4.000 × 10 = 40.000', anlatim: 'Mart-aralık 10 ay.' },
      { formul: 'Fazla gider = 48.000 − 40.000 = 8.000 (3. adımda bulduk)', anlatim: 'Kâr bu kadar düşük gösterilmiştir.' },
      { formul: 'Yanlış yol: 48.000 − 36.000 = 12.000 (HATALI)', anlatim: 'Ay sayısını karıştırma.' }
    ],
    celdiriciYol: { B: '48.000 / 4 = 12.000 (çeyrek dönem sandın)', C: '4.000 × 10 = 40.000 (cari payı fark sandın)', D: '48.000 − 0 = 48.000 (hiç bölmedin)', E: '4.000 × 9 = 36.000 (ay sayısını eksik saydın)' },
    teshis: {}
  }, d || {});
}
function kopya(o) { return JSON.parse(JSON.stringify(o)); }

function sinav() {
  const hata = [], v = [];
  const kos = (ad, s, bekle, kod) => { const r = C.cizerekKapi(s); const ok = bekle ? r.gecer : (!r.gecer && r.neden.some(n => n.indexOf(kod) === 0)); v.push(ad); if (!ok) hata.push(ad + ' -> ' + (r.gecer ? 'GEÇTİ' : r.neden.join(' | '))); return r; };
  // 1) temiz soru geçer (yanlış alarm yok)
  const r1 = kos('temiz hesap sorusu geçer', soru(), true);
  if (r1.gecer) {
    const yz = r1.senaryo.sahne.filter(x => x.tur === 'yaz').map(x => x.satirlar.join(' | '));
    if (yz.join(' ').indexOf('adımda bulduk') >= 0) hata.push('sadeleştirme: "(N. adımda bulduk)" karalamaya sızdı');
    if (yz.some(x => /Yanlış yol/.test(x))) hata.push('"Yanlış yol" adımı karalamaya yazıldı');
    if (!r1.senaryo.sahne.some(x => x.tur === 'yaz' && x.son && /8\.000$/.test(x.satirlar[x.satirlar.length - 1]))) hata.push('doğru sonuç satırı yeşil (son) işaretlenmedi');
    v.push('sadeleştirme + son satır');
  }
  // 2) karalamada kaynakta olmayan sayı (dizici hatası benzetimi) -> RAKAM
  { const s = soru(); const sen = C.senaryo(s); sen.sahne.find(x => x.tur === 'yaz').satirlar[0] = 'Aylık pay = 48.000 / 12 = 4.100'; const r = C.cizerekKapi(s, sen); v.push('kaynakta olmayan sayı'); if (r.gecer || !r.neden.some(n => /^RAKAM/.test(n))) hata.push('kaynakta olmayan sayı -> ' + (r.gecer ? 'GEÇTİ' : r.neden.join(' | '))); }
  // 3) şık notunda kaynakta olmayan sayı -> RAKAM
  { const s = soru(); const sen = C.senaryo(s); sen.sahne.find(x => x.tur === 'karala' && x.not).not = '48.000 / 5 = 9.600'; const r = C.cizerekKapi(s, sen); v.push('notta kaynakta olmayan sayı'); if (r.gecer || !r.neden.some(n => /^RAKAM/.test(n))) hata.push('notta kaynakta olmayan sayı -> ' + (r.gecer ? 'GEÇTİ' : r.neden.join(' | '))); }
  // 4) adım hesabı tutmuyor -> ARITMETIK
  { const s = soru(); s.adimlar[2].formul = 'Cari dönem payı = 4.000 × 10 = 44.000'; s.siklar.C = '44.000'; kos('adım hesabı tutmuyor', s, false, 'ARITMETIK'); }
  // 5) çeldirici yolu hesabı tutmuyor -> ARITMETIK
  { const s = soru(); s.celdiriciYol.E = '4.000 × 9 = 38.000 (ay sayısını eksik saydın)'; kos('çeldirici hesabı tutmuyor', s, false, 'ARITMETIK'); }
  // 6) iç eşitlik yanlış: "(500 x 25 = 12.000)" -> ARITMETIK
  { const s = soru(); s.celdiriciYol.D = '30.000 + (500 x 25 = 12.000) = 42.000 (yanlış saat)'; s.siklar.D = '42.000'; kos('iç eşitlik yanlış', s, false, 'ARITMETIK'); }
  // 7) doğru şıkkın sayısı karalamada yok -> DOGRU
  { const s = soru(); s.dogru = 'E'; kos('çözüm doğru şıkka varmıyor', s, false, 'DOGRU'); }
  // 8) sözel soru (sayılı çözüm adımı 1) -> SOZEL
  { const s = soru(); s.adimlar = [s.adimlar[0], { formul: 'Kural: peşin giderin gelecek döneme ait kısmı 180 hesabına alınır', anlatim: '' }, s.adimlar[3]]; kos('sözel soru', s, false, 'SOZEL'); }
  // 9) veri eksik -> VERI
  { const s = soru(); delete s.dogru; kos('doğru harf yok', s, false, 'VERI'); }
  // 10) hesap kodu dizisi yanlış alarm vermez
  { const s = soru(); s.adimlar.splice(1, 0, { formul: 'Toplam = 151 + 152 = 40.000 + 8.000 = 48.000', anlatim: '' }); kos('hesap kodu dizisi (151 + 152) yanlış alarm yok', s, true); }
  // 11) yuvarlanmış yüzde yanlış alarm vermez
  { const s = soru(); s.adimlar.splice(1, 0, { formul: 'Oran: 40.000 / 48.000 = %83,33; Pay: 9.600 × %83,33 = 8.000', anlatim: '' }); kos('yuvarlanmış yüzde (%83,33) yanlış alarm yok', s, true); }
  // 12) doğrulanamayan sayılı alt yazı yazılmaz ama soru düşmez
  { const s = soru(); s.adimlar[1].anlatim = 'Aylık pay 4.000; 2025 yılında 3.500 idi.'; const r = kos('doğrulanamayan alt yazı düşer, soru geçer', s, true); if (r.gecer && r.senaryo.sahne.some(x => /3\.500/.test(x.alt || ''))) hata.push('doğrulanamayan alt yazı ekrana çıkıyor'); }
  // 13) "X nedir?" ile başlayan anlatım alt yazı olmaz
  { const s = soru(); s.adimlar[1].anlatim = '180 Gelecek Aylara Ait Giderler nedir? Peşin ödenen gideri taşır.'; const r = C.cizerekKapi(s); v.push('"nedir?" alt yazısı düşer'); if (!r.gecer || r.senaryo.sahne.some(x => /nedir|Peşin ödenen/.test(x.alt || ''))) hata.push('"nedir?" anlatımı alt yazıya çıktı'); }
  // 14) tanım adımı (yalnız hesap kodu) karalamaya yazılmaz
  { const s = soru(); s.adimlar.splice(1, 0, { formul: '180 Gelecek Aylara Ait Giderler nedir?', anlatim: '' }); const r = C.cizerekKapi(s); v.push('tanım adımı yazılmaz'); if (!r.gecer || r.senaryo.sahne.some(x => x.satirlar && x.satirlar.some(y => /nedir/.test(y)))) hata.push('tanım adımı karalamaya yazıldı'); }
  // 15) çeldirici: not + neden ayrımı
  { const b = C.celdiriciBol('(280.000 + 20.000) x %20 = 60.000 (sigortayı maliyete kattın)'); v.push('çeldirici not/neden ayrımı'); if (b.not !== '(280.000 + 20.000) x %20 = 60.000' || b.neden !== 'sigortayı maliyete kattın') hata.push('çeldirici ayrımı: ' + JSON.stringify(b)); }
  // 16) prova listesi: cizerek-coz.js PROVA = radar-app/sql/2026-10-15-prova-cizim.sql izin listesi (biri değişip öteki kalırsa
  //     sitede düğme çıkar ama sunucu boş döner, ya da tersi)
  {
    const fs = require('fs'); const sql = fs.readFileSync(path.join(__dirname, '..', 'radar-app', 'sql', '2026-10-15-prova-cizim.sql'), 'utf8');
    const s = new Set((sql.match(/'smmm-[^']+'|'sgs-[^']+'/g) || []).map(x => x.slice(1, -1)));
    let j = (C.PROVA && C.PROVA['YET-2410']) || []; if (process.env.CIZ_MUTASYON === 'provaliste') j = j.concat(['sgs-uydurma/kp-01']);
    v.push('prova listesi JS = SQL'); if (!j.length || j.length !== s.size || !j.every(x => s.has(x))) hata.push('prova listesi JS (' + j.length + ') ile SQL (' + s.size + ') farklı');
    if (C.PROVA && C.PROVA['SGS-1710']) hata.push('SGS-1710 prova listesinde: 17.10 akışına dokunulmaz');
  }
  const mut = process.env.CIZ_MUTASYON ?' (MUTASYON: ' + process.env.CIZ_MUTASYON + ')' : '';
  if (hata.length) { console.log('KAPI-CZ ÖZ-SINAV DÜŞTÜ' + mut + ': ' + hata.length + '/' + v.length); hata.forEach(h => console.log('  - ' + h)); return 1; }
  console.log('KAPI-CZ ÖZ-SINAV TEMİZ' + mut + ': ' + v.length + ' vaka'); return 0;
}

if (a.includes('--sinav')) {
  let kod = sinav();
  if (kod === 0 && a.includes('--mutasyon') && !process.env.CIZ_MUTASYON) {
    const M = ['rakam', 'aritmetik', 'dogru', 'sozel', 'hesapkodu', 'altyazi', 'provaliste'];
    let kac = 0;
    for (const m of M) {
      const r = spawnSync(process.execPath, [__filename, '--sinav'], { env: Object.assign({}, process.env, { CIZ_MUTASYON: m }), encoding: 'utf8' });
      const kirmizi = r.status !== 0; if (!kirmizi) kac++;
      console.log('  mutasyon ' + m.padEnd(10) + (kirmizi ? 'KIRMIZI ✓ ' : 'YEŞİL ✗ (sınav bu bozmayı görmüyor) ') + ((r.stdout || '').split('\n')[0] || ''));
    }
    if (kac) { console.log('MUTASYON: ' + kac + '/' + M.length + ' bozma yakalanmadı'); kod = 1; } else console.log('MUTASYON: ' + M.length + '/' + M.length + ' bozma KIRMIZI');
  }
  process.exit(kod);
}

if (a.includes('--liste')) {
  const dosya = a[a.indexOf('--liste') + 1];
  if (!dosya) { console.error('kullanım: --liste <paket.json>'); process.exit(2); }
  const P = require(path.resolve(dosya));
  let g = 0, d = 0, yok = 0;
  for (const id of C.PILOT) {
    const x = P[id]; if (!x) { yok++; console.log('KÖR   ' + id + ' (dosyada yok)'); continue; }
    const r = C.cizerekKapi(x.veri || x);
    if (r.gecer) { g++; const s = r.senaryo; console.log('GEÇER ' + id.padEnd(40) + ' adım ' + s.sahne.length + ' · karalama satırı ' + s.sahne.filter(y => y.tur === 'yaz').reduce((t, y) => t + y.satirlar.length, 0) + ' · şık notu ' + s.sahne.filter(y => y.not).length); }
    else { d++; console.log('DÖNDÜ ' + id.padEnd(40) + ' ' + r.neden.join(' | ')); }
  }
  console.log('PILOT ' + C.PILOT.length + ' · geçer ' + g + ' · döndü ' + d + ' · KÖR ' + yok);
  process.exit(d || yok ? 1 : 0);
}
console.log('kullanım: --sinav [--mutasyon] | --liste <paket.json>');
