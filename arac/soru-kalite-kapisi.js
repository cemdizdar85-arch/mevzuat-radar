// arac/soru-kalite-kapisi.js — YENİ SORU KALİTE KAPILARI (KAPI-AS + KAPI-EK) tek giriş (30.09.2026, Cem "1.2.3 yap ve kural koy")
// PowerShell üretim hattı bunu çağırır; mantık iki modülde (aciklama-sayi-kapisi.js, eski-kural-kapisi.js), burada kopya YOK.
//   node arac/soru-kalite-kapisi.js --tek <soru.json>      → her bulgu bir satır "KAPI-AS: ..." / "KAPI-EK: ..." (bulgu yoksa boş)
//   node arac/soru-kalite-kapisi.js --parti <kalip-parti-*.json> → JSON {"kp-01":["KAPI-AS: ..."], ...} (yalnız bulgulu kp'ler)
// Çıkış kodu her zaman 0 (karar çağıranın); dosya okunamazsa "KAPI-KALITE KÖR: <neden>" satırı basar, çıkış 2.
// Günlük PUBLIC: satırlar soru metni taşımaz, yalnız alan adı + kural kodu (+ KAPI-AS'ta şık sayıları).
'use strict';
const fs = require('fs');
const AS = require('./aciklama-sayi-kapisi.js'), EK = require('./eski-kural-kapisi.js');
function satirlar(k) {
  const c = [];
  AS.denetle(k).forEach(b => c.push('KAPI-AS: ' + b.alan + ' ' + b.sik + ' şıkkı yerine ' + b.diger + ' şıkkının sayısını sonuç diye anlatıyor'));
  EK.denetle(k).forEach(b => c.push('KAPI-EK: ' + b.kod + ' ' + b.alan + ' (' + b.kural + ')'));
  return c;
}
const a = process.argv.slice(2);
try {
  if (a[0] === '--tek') { satirlar(JSON.parse(fs.readFileSync(a[1], 'utf8'))).forEach(s => console.log(s)); process.exit(0); }
  if (a[0] === '--parti') {
    const p = JSON.parse(fs.readFileSync(a[1], 'utf8')), o = {};
    for (const kp of Object.keys(p)) { if (!/^kp-/.test(kp)) continue; const s = satirlar(p[kp]); if (s.length) o[kp] = s; }
    console.log(JSON.stringify(o)); process.exit(0);
  }
} catch (e) { console.log('KAPI-KALITE KÖR: ' + String(e.message).slice(0, 120)); process.exit(2); }
console.log('kullanım: --tek <soru.json> | --parti <kalip-parti.json>'); process.exit(2);
