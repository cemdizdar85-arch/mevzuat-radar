/* NET CEVAP — ARAMA MOTORU REGRESYON SINAVI
 *
 * Neden var: 21.08.2026 kalite turunda motorun 26 etiketli sorudan yalnız
 * 18'ini bildiği ve HİÇ "bilmiyorum" demediği ölçüldü. Kapsam dışı 6 sorunun
 * 6'sına da cevap uydurdu — üstelik altına "✓ Doğrulanmış birincil kaynak"
 * rozeti basarak. Onarımdan sonra 24/26'ya çıktı. Bu betik o seviyenin
 * düşmediğini kanıtlar.
 *
 * Nasıl çalışır: motoru KOPYALAMAZ — soru-cevap.html'in içinden canlı kodu
 * söküp çalıştırır. Böylece sayfa değişince test de onu ölçer, eskimez.
 *
 * Koşum:  node arac/net-cevap-kalite.js
 * Çıkış :  0 = eşik tutuyor, 1 = motor gerilemiş (CI'da kırmızı)
 */
const fs = require('fs');
const path = require('path');
const kok = path.join(__dirname, '..');

// CRLF -> LF: dosya Windows satır sonuyla duruyor, desenler \n bekliyor
const html = fs.readFileSync(path.join(kok, 'soru-cevap.html'), 'utf8').replace(/\r\n/g, '\n');
const KB = JSON.parse(fs.readFileSync(path.join(kok, 'veri/bilgi-tabani.json'), 'utf8'));
const SINAV = JSON.parse(fs.readFileSync(path.join(kok, 'veri/net-cevap-sinav.json'), 'utf8'));

// —— canlı motoru sayfadan sök ——————————————————————————————
function sok(ad, re) {
  const m = html.match(re);
  if (!m) {
    console.error('HATA: soru-cevap.html içinde "' + ad + '" bulunamadı.');
    console.error('Motor yeniden yazıldıysa bu betikteki sökme desenini de güncelle —');
    console.error('sessizce geçmesin diye kasten çöküyorum.');
    process.exit(2);
  }
  return m[0];
}
const parcalar = [
  sok('norm()',        /function norm\(s\)\{[^\n]*\}/),
  sok('STOP kümesi',   /const STOP=new Set\([^\n]*\);/),
  sok('eslesirSet()',  /function eslesirSet\(set,t\)\{[^\n]*\}/),
  sok('motor v2',      /const normK=[\s\S]*?\.sort\(\(a,b\)=>b\.s-a\.s\);\n\}/)
];

const ara = new Function('KB', parcalar.join('\n') + '\nreturn ara;')(KB);

// —— sınav ————————————————————————————————————————————————
let dogru = 0, bilmiyorum = 0;
const hatalar = [];
for (const { soru, kabul } of SINAV.sorular) {
  const r = ara(soru);
  const en = r[0];
  const ad = (en && en.kabul) ? en.k.konu : 'BILMIYORUM';
  if (ad === 'BILMIYORUM') bilmiyorum++;
  if (kabul.includes(ad)) dogru++;
  else hatalar.push('  x ' + soru + '\n      geldi : ' + ad + '\n      olmalı: ' + kabul.join(' / '));
}

const esik = SINAV.esik || 0;
console.log('NET CEVAP KALİTE SINAVI · KB ' + KB.kayitlar.length + ' kayıt');
console.log('  sonuç          : ' + dogru + '/' + SINAV.sorular.length + '   (eşik ' + esik + ')');
console.log('  "bilmiyorum"   : ' + bilmiyorum + '   (kapsam dışı sorularda çalışması beklenir)');
if (hatalar.length) { console.log('  kalan kusurlar :'); console.log(hatalar.join('\n')); }

if (dogru < esik) {
  console.error('\nKIRMIZI: motor gerilemiş. Eşiği düşürerek değil, kusuru onararak geç.');
  process.exit(1);
}
if (bilmiyorum === 0) {
  console.error('\nKIRMIZI: motor hiç "bilmiyorum" demedi — dürüstlük kutusu ölmüş demektir.');
  process.exit(1);
}
console.log('\nYEŞİL');
