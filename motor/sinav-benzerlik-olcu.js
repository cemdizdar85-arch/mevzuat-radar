#!/usr/bin/env node
// ============================================================================
//  SINAVA BENZERLİK ÖLÇÜSÜ — tek soru (30.10.2026, bedel 0, model yok)
//
//  Cem 30.10: "sınav soru kalitemiz kötü diye şikâyet alıyoruz … ilk önce düzgün sorularımızı görsünler".
//  Ölçüldü (sitedeki bankanın tamamı, gerçek = veri/sinav-anatomisi-<sınav>.json C_ders_kalibi): konu doğru, BİÇİM
//  sapıyor — kök uzun, sözel şık uzun, gerçek sınavın sözel/kayıt şık yazdığı derste bizde çıplak rakam.
//  Ölçüm kuralları arac/sinav-anatomisi.ps1 (satır 127–141) ile AYNI (C:\TETIKTE-CALISMA\sgs-s20-arac\sinav-benzerlik.js'ten
//  birebir taşındı): uzunluk = soru gövdesi karakter sayısı (şıklar hariç), tip/olumsuz/öncüllü/mevzuat düzenli ifadeleri aynı.
//
//  benzerMi (tek soru, ders kalıbına göre) — üçü birden:
//    1) kök ≤ gerçek kök medyanı × 1,35            (27.10 KAPI-BENZERLIK "kısa kök" eşiği)
//    2) şık medyanı ≤ gerçek şık medyanı × 1,5 + 10 (sinav-benzerlik.js sapma eşiği)
//    3) gerçek şık medyanı ≥ 30 olan derste şık medyanı ≥ gerçek × 0,35 (sözel/kayıt şıklı derste çıplak rakam şık değil)
//  🚫 GÖRMEZ: anlamsal benzerlik · konu (ayrı ölçüm) · sorunun doğruluğu · tek sorunun olumlu/olumsuz kökü (oran bir
//    dağılımdır, tek soru için kusur değildir) · gövdeye gömülü tablo biçimi.
//
//  node motor/sinav-benzerlik-olcu.js --sinav     öz-sınav
// ============================================================================
'use strict';
const katla = s => String(s).replace(/İ/g, 'I').replace(/ı/g, 'i').toLowerCase().replace(/i̇/g, 'i').replace(/ş/g, 's').replace(/ğ/g, 'g')
  .replace(/ü/g, 'u').replace(/ö/g, 'o').replace(/ç/g, 'c');
const med = a => { const s = [...a].sort((x, y) => x - y); return s.length ? s[Math.floor(s.length / 2)] : 0; };
const KOK_KAT = 1.35, SIK_KAT = 1.5, SIK_PAY = 10, SOZEL_SIK = 30, SOZEL_ALT = 0.35;

// tek sorunun biçim ölçüleri (kök 25 karakterden kısaysa null: ölçülmez)
function olcu(q) {
  const g = String((q && q.soru) || '').trim(); if (g.length < 25) return null;
  const kg = katla(g), siklar = Object.values((q && q.siklar) || {}).map(s => String(s).trim());
  const rakam = (g.match(/\d[\d\.,]*/g) || []).length;
  const tip = /muhasebe kayd|yevmiye maddesi|kayd[ıi] a[sş]a[gğ][ıi]dakilerden/.test(kg) ? 'kayit'
    : (rakam >= 3 && /kactir|ne kadar|tutari|hesapla|kac tl|kac ₺/.test(kg)) ? 'hesaplama'
    : /asagidakilerden hangisi|hangisi yanlis|hangisi dogru/.test(kg) ? 'teori' : 'diger';
  return {
    uz: g.length, tip,
    neg: /hangisi\s+(yanlis|dogru degil)|degildir|olamaz|soylenemez|yer almaz|bulunmaz/.test(kg),
    onc: /^\s*(I{1,3}|IV|V)\s*[\.\)]/m.test(g) || /yukaridakilerden hangisi|hangileri/.test(kg),
    mev: /\b\d{3,4}\s*sayili|\bmadde\s*\d|\bm\.\s*\d|\btms\s*\d|\btfrs\s*\d|\bbds\s*\d|\bvuk\b|\bttk\b/.test(kg),
    sikUz: med(siklar.map(s => s.length))
  };
}

// kalip = anatomi C_ders_kalibi[ders] ({uzunluk:{medyan}, sik_uzunlugu:{medyan}}); kalıp yoksa null (bilinmiyor)
function benzerMi(q, kalip) {
  if (!kalip || !kalip.uzunluk || !kalip.sik_uzunlugu) return null;
  const o = olcu(q); if (!o) return false;
  const km = kalip.uzunluk.medyan, sm = kalip.sik_uzunlugu.medyan;
  if (o.uz > km * KOK_KAT) return false;
  if (o.sikUz > sm * SIK_KAT + SIK_PAY) return false;
  if (sm >= SOZEL_SIK && o.sikUz < sm * SOZEL_ALT) return false;
  return true;
}

function sinav() {
  let hata = 0; const t = (ad, k) => { console.log((k ? '  geçti: ' : '  DÜŞTÜ: ') + ad); if (!k) hata++; };
  const K = { uzunluk: { medyan: 100 }, sik_uzunlugu: { medyan: 40 } }, R = { uzunluk: { medyan: 100 }, sik_uzunlugu: { medyan: 8 } };
  const s = (n, sik) => ({ soru: 'x'.repeat(n), siklar: { A: sik, B: sik, C: sik, D: sik, E: sik } });
  t('kısa kök + sınav boyu şık → benzer', benzerMi(s(120, 'y'.repeat(40)), K) === true);
  t('kök 1,35 katından uzun → değil', benzerMi(s(136, 'y'.repeat(40)), K) === false);
  t('kök tam sınırda (135) → benzer', benzerMi(s(135, 'y'.repeat(40)), K) === true);
  t('şık 1,5×+10 üstü → değil', benzerMi(s(80, 'y'.repeat(71)), K) === false);
  t('sözel şıklı derste çıplak rakam şık → değil', benzerMi(s(80, '45.000'), K) === false);
  t('rakam şıklı derste (gerçek medyan <30) rakam şık → benzer', benzerMi(s(80, '45.000'), R) === true);
  t('kalıp yok → null (bilinmiyor)', benzerMi(s(80, 'y'), null) === null);
  t('kök 25 karakterden kısa → değil', benzerMi(s(10, 'y'.repeat(40)), K) === false);
  const o = olcu({ soru: 'Aşağıdakilerden hangisi 6098 sayılı Kanun\'a göre doğru DEĞİLDİR?', siklar: { A: 'a' } });
  t('olumsuz kök (büyük İ) + mevzuat atfı okunur', o.neg && o.mev && o.tip === 'teori');
  console.log(hata ? `ÖZ-SINAV DÜŞTÜ (${hata})` : 'ÖZ-SINAV GEÇTİ');
  return hata;
}

if (require.main === module) {
  if (process.argv.includes('--sinav')) process.exitCode = sinav() ? 1 : 0;
  else { console.log('kullanım: --sinav'); process.exitCode = 1; }
}
module.exports = { katla, med, olcu, benzerMi };
