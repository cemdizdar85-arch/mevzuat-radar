// arac/soru-kalite-kapisi.js — YENİ SORU KALİTE KAPILARI (KAPI-AS + KAPI-EK) tek giriş (30.09.2026, Cem "1.2.3 yap ve kural koy")
// PowerShell üretim hattı bunu çağırır; mantık iki modülde (aciklama-sayi-kapisi.js, eski-kural-kapisi.js), burada kopya YOK.
//   node arac/soru-kalite-kapisi.js --tek <soru.json>      → her bulgu bir satır "KAPI-AS: ..." / "KAPI-EK: ..." (bulgu yoksa boş)
//   node arac/soru-kalite-kapisi.js --parti <kalip-parti-*.json> → JSON {"kp-01":["KAPI-AS2: ..."], ...} (yalnız DURDURAN bulgulu kp'ler)
// Çıkış kodu her zaman 0 (karar çağıranın); dosya okunamazsa "KAPI-KALITE KÖR: <neden>" satırı basar, çıkış 2.
// Günlük PUBLIC: satırlar soru metni taşımaz, yalnız alan adı + kural kodu (+ KAPI-AS'ta şık sayıları).
'use strict';
const fs = require('fs');
const AS = require('./aciklama-sayi-kapisi.js'), EK = require('./eski-kural-kapisi.js'), HK = require('./hesap-kodu-kapisi.js'), BP = require('./bds-atif-kapisi.js');
/* 30.09 ölçümü (onarımcılar 93 AS1 alarmını elle okudu): AS1 alarmlarının SGS'de %54'ü, SMMM'de %76'sı YANLIŞ → AS1 soru DURDURMAZ,
   "NOT-AS1" satırı olarak günlüğe düşer. DURDURANLAR: AS2 (açıklama kayması, yapısal) + EK (onarımda 101 soruda 4 yanlış alarm, hepsi
   bilerek konmuş "eski oran" çeldiricisi — arac/eski-kurallar.json haric'i genişletildi). */
function satirlar(k) {
  const c = [];
  AS.denetle(k).forEach(b => c.push(b.kod === 'AS2' ? 'KAPI-AS2: ' + b.not : 'NOT-AS1: ' + b.alan + ' ' + b.sik + ' şıkkı yerine ' + b.diger + ' şıkkının sayısını sonuç diye anlatıyor olabilir'));
  EK.denetle(k).forEach(b => c.push('KAPI-EK: ' + b.kod + ' ' + b.alan + ' (' + b.kural + ')'));
  // 30.09 KAPI-HK (Cem "1.2.3, bu kural olsun her sınavda"): THP'de olmayan kod / kodun yanında yanlış hesap adı → DURDURUR.
  //   Adsız "(hesap bağlamı)" bulgusu gürültülü (SGS bankasında 19 bulgunun bir kısmı tutar/gün) → yalnız NOT-HK.
  //   Satır soru metni taşımaz: tür + kod + alan.
  HK.kusurlar(k).forEach(b => c.push((b.tur === 'HK-YOK' && /hesap bağlamı/.test(b.ad) ? 'NOT-HK: ' : 'KAPI-HK: ') + b.tur + ' ' + b.kod + ' ' + b.alan));
  // 30.09 KAPI-BP (Cem "1.2.3"): BDS paragraf atfı. BP-KONU/BP-YOK DURDURUR — 60 bulguluk resmî metin yargısında isabet 24/28 (%86);
  //   BP-ZAYIF (atfedilen paragrafın gövdesi konuyu taşıyor) yalnız NOT-BP — aynı yargıda 30'un 23'ü yanlış alarmdı.
  BP.kusurlar(k).forEach(b => { if (b.tur === 'BP-KOR') return; c.push((b.tur === 'BP-ZAYIF' ? 'NOT-BP: ' : 'KAPI-BP: ') + b.tur + ' BDS ' + b.std + ' ' + b.par + ' ' + b.alan); });
  return c;
}
const a = process.argv.slice(2);
try {
  if (a[0] === '--tek') { satirlar(JSON.parse(fs.readFileSync(a[1], 'utf8'))).forEach(s => console.log(s)); process.exit(0); }
  if (a[0] === '--parti') {
    const p = JSON.parse(fs.readFileSync(a[1], 'utf8')), o = {};
    for (const kp of Object.keys(p)) { if (!/^kp-/.test(kp)) continue; const s = satirlar(p[kp]).filter(x => /^KAPI-/.test(x)); if (s.length) o[kp] = s; }   // yalnız DURDURAN bulgular (NOT-AS1 hariç)
    console.log(JSON.stringify(o)); process.exit(0);
  }
} catch (e) { console.log('KAPI-KALITE KÖR: ' + String(e.message).slice(0, 120)); process.exit(2); }
console.log('kullanım: --tek <soru.json> | --parti <kalip-parti.json>'); process.exit(2);
