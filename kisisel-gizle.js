/* kisisel-gizle.js — SORU METNİNDEN KİŞİSEL BİLGİ GİZLEME (14.09.2026)
 *
 * Neden: Net Cevap soruyu yurt dışındaki yapay zekâ sağlayıcısına (Anthropic, yedekte
 * OpenRouter) ve cevaplanamazsa e-posta hattına (Resend) gönderir. Kullanıcı soruya
 * TC kimlik, VKN, telefon, e-posta ya da IBAN yazarsa o bilgi yurt dışına gider.
 * Bu dosya metni GÖNDERMEDEN ÖNCE, tarayıcıda gizler: "[TC kimlik no]" gibi bir etiket
 * kalır, soru anlamını kaybetmez.
 *
 * Yanlış alarm frenleri (tutar gizlenmesin):
 *  - 11 hane yalnız TC kimlik ALGORİTMASI tutarsa, 10 hane yalnız VKN ALGORİTMASI tutarsa gizlenir.
 *  - Arkasından TL / ₺ / lira / USD / EUR / $ / € gelen sayı tutardır, gizlenmez.
 *
 * ⚠ radar-app/edge/net-cevap.ts içinde AYNI fonksiyonun kopyası var (sunucu tarafı ikinci kat).
 *   İkisi birebir aynı kalmalı: `node kisisel-gizle.js --sinav` bunu da denetler.
 */
// GIZLE-BASLA
function kisiselGizle(metin) {
  var s = String(metin == null ? '' : metin);
  var sayac = { iban: 0, eposta: 0, telefon: 0, tckn: 0, vkn: 0 };
  var PARA = /^\s*(tl|₺|try|lira|usd|eur|\$|€|dolar|euro|avro)\b/i;
  function tcknGecerli(d) {
    if (d.length !== 11 || d[0] === '0') return false;
    var n = d.split('').map(Number);
    var on = ((n[0] + n[2] + n[4] + n[6] + n[8]) * 7 - (n[1] + n[3] + n[5] + n[7])) % 10;
    if (((on % 10) + 10) % 10 !== n[9]) return false;
    var top = 0; for (var i = 0; i < 10; i++) top += n[i];
    return top % 10 === n[10];
  }
  function vknGecerli(d) {
    if (d.length !== 10) return false;
    var n = d.split('').map(Number), top = 0;
    for (var i = 0; i < 9; i++) {
      var t = (n[i] + (9 - i)) % 10;
      var v = (t * Math.pow(2, 9 - i)) % 9;
      if (t !== 0 && v === 0) v = 9;
      top += v;
    }
    return (10 - (top % 10)) % 10 === n[9];
  }
  s = s.replace(/\bTR\s?\d{2}(?:\s?\d{4}){5}\s?\d{2}\b/gi, function () { sayac.iban++; return '[IBAN]'; });
  s = s.replace(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/gi, function () { sayac.eposta++; return '[e-posta]'; });
  s = s.replace(/(^|[^\d])((?:(?:\+90|0090|90)[\s-]?)?\(?0?5\d{2}\)?[\s-]?\d{3}[\s-]?\d{2}[\s-]?\d{2})(?!\d)/g, function (m, on, tel) {
    sayac.telefon++; return on + '[telefon]';
  });
  s = s.replace(/(^|[^\d.,])(\d{10,11})(?![\d.,]*\d)/g, function (m, on, d, konum, tum) {
    var sonra = tum.slice(konum + m.length);
    if (PARA.test(sonra)) return m;
    if (d.length === 11 && tcknGecerli(d)) { sayac.tckn++; return on + '[TC kimlik no]'; }
    if (d.length === 10 && vknGecerli(d)) { sayac.vkn++; return on + '[vergi no]'; }
    return m;
  });
  var toplam = sayac.iban + sayac.eposta + sayac.telefon + sayac.tckn + sayac.vkn;
  return { metin: s, gizlenen: toplam, sayac: sayac };
}
// GIZLE-BITIR

if (typeof window !== 'undefined') window.kisiselGizle = kisiselGizle;
if (typeof module !== 'undefined' && module.exports) {
  module.exports = { kisiselGizle: kisiselGizle };
  if (require.main === module && process.argv.indexOf('--sinav') > -1) {
    var fs = require('fs'), path = require('path'), hata = 0;
    var t = function (ad, kosul) { if (kosul) console.log('  geçti: ' + ad); else { hata++; console.log('  DÜŞTÜ: ' + ad); } };
    var g = function (x) { return kisiselGizle(x).metin; };
    // gerçek algoritmayla geçerli örnekler (kimseye ait değil: test amaçlı üretilmiş)
    t('geçerli TCKN gizlenir', g('TC 10000000146 olan çalışan') === 'TC [TC kimlik no] olan çalışan');
    t('algoritması tutmayan 11 hane kalır', g('10000000147 numara') === '10000000147 numara');
    t('tutar (TL) gizlenmez', g('10000000146 TL ciro') === '10000000146 TL ciro');
    t('noktalı tutar gizlenmez', g('1.500.000.000 lira') === '1.500.000.000 lira');
    t('cep telefonu gizlenir', g('beni 0532 123 45 67 den ara') === 'beni [telefon] den ara');
    t('+90 telefon gizlenir', g('+905321234567') === '[telefon]');
    t('e-posta gizlenir', g('adresim ali.veli@ornek.com.tr') === 'adresim [e-posta]');
    t('IBAN gizlenir', g('TR33 0006 1005 1978 6457 8413 26 hesabına') === '[IBAN] hesabına');
    t('mevzuat sorusu bozulmaz', g('7103 sayılı Kanun 213 VUK m.359 ceza 2026 yılı %20') === '7103 sayılı Kanun 213 VUK m.359 ceza 2026 yılı %20');
    t('sayaç doğru', kisiselGizle('a@b.co 0532 123 45 67 10000000146').gizlenen === 3);
    // VKN algoritmasını bağımsız bilinen örnekle sına: 0000000002? -> hesapla ve tersini kontrol et
    var bulunan = null; for (var i = 1000000000; i < 1000000100; i++) { var d = String(i); if (g('x ' + d + ' y') !== 'x ' + d + ' y') { bulunan = d; break; } }
    t('VKN algoritması 100 aday içinde en az birini tanır', !!bulunan);
    t('tanınan VKN cümle içinde etiketlenir', !!bulunan && g('VKN ' + bulunan + ' firma') === 'VKN [vergi no] firma');
    var yalanci = 0; for (var j = 1000000000; j < 1000001000; j++) { if (g(String(j)) !== String(j)) yalanci++; }
    t('10 haneli rastgele sayının ~%10’u VKN sayılır (algoritma çalışıyor, hepsi değil): ' + yalanci + '/1000', yalanci > 50 && yalanci < 150);
    // sunucu kopyası birebir mi
    var js = fs.readFileSync(__filename, 'utf8'), ts = fs.readFileSync(path.join(__dirname, 'radar-app', 'edge', 'net-cevap.ts'), 'utf8');
    var kes = function (x) { var a = x.indexOf('// GIZLE-BASLA'), b = x.indexOf('// GIZLE-BITIR'); return a > -1 && b > a ? x.slice(a, b).replace(/\r\n/g, '\n') : null; };
    t('net-cevap.ts kopyası birebir aynı', kes(js) !== null && kes(js) === kes(ts));
    console.log(hata ? 'ÖZ-SINAV DÜŞTÜ (' + hata + ')' : 'ÖZ-SINAV GEÇTİ');
    process.exit(hata ? 1 : 0);
  }
}
