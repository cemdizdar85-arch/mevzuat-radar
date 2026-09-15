// arac/edge-imza.js — UÇ FONKSİYON KOD İMZASI (15.09.2026)
//
// NEDEN: Supabase fonksiyonları elle (panelde "Deploy") yükleniyor. 14.09'da karne-gonder ve net-cevap
// depoda 1 gün boyunca yeni, canlıda eski kaldı; kimse fark etmedi. Canlı kodu okumak yönetim anahtarı
// ister (yok). Bunun yerine her fonksiyon kendi kod imzasını taşır ve `?surum=1` ile söyler:
//   KOD_IMZA = dosya içeriğinin SHA-256'sı (ilk 16 hane), imza satırının DEĞERİ sıfırlanarak,
//              BOM atılıp satır sonları LF'ye çevrilerek hesaplanır.
// Böylece depo = canlı karşılaştırması anahtarsız yapılır (motor/edge-nobetcisi.js).
//
//   node arac/edge-imza.js --yaz       imzaları tazeler (kod değişince, commit'ten ÖNCE)
//   node arac/edge-imza.js --denetle   tazelenmemiş imza varsa çıkış 1
//   node arac/edge-imza.js --sinav     öz-sınav
'use strict';
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const KLASOR = path.join(__dirname, '..', 'radar-app', 'edge');
const SATIR = /const KOD_IMZA = "([0-9a-f]{16})";/;
const SIFIR = '0000000000000000';
// canlı ad -> depo dosyası (quick-task'ın kodu form-al.ts; ad tarihsel)
const ESLEME = { 'quick-task': 'form-al.ts', 'beyanname-oku': 'beyanname-oku.ts', 'karne-gonder': 'karne-gonder.ts', 'net-cevap': 'net-cevap.ts' };

function normal(metin) { return metin.replace(/^﻿/, '').replace(/\r\n/g, '\n'); }
function imzaHesapla(metin) {
  const n = normal(metin);
  if (!SATIR.test(n)) return null;
  return crypto.createHash('sha256').update(n.replace(SATIR, `const KOD_IMZA = "${SIFIR}";`)).digest('hex').slice(0, 16);
}
function imzaOku(metin) { const m = normal(metin).match(SATIR); return m ? m[1] : null; }

function dosyalar() { return Object.values(ESLEME).map(f => path.join(KLASOR, f)); }

function sinav() {
  let h = 0; const t = (ad, k) => { console.log((k ? '  geçti: ' : '  DÜŞTÜ: ') + ad); if (!k) h++; };
  const a = 'x\nconst KOD_IMZA = "0000000000000000";\ny\n';
  const i = imzaHesapla(a);
  const b = a.replace(SIFIR, i);
  t('imza satırının değeri hesabı değiştirmez', imzaHesapla(b) === i);
  t('CRLF ve BOM aynı imzayı verir', imzaHesapla('﻿' + b.replace(/\n/g, '\r\n')) === i);
  t('kod değişince imza değişir', imzaHesapla(b.replace('y', 'z')) !== i);
  t('imza satırı yoksa null', imzaHesapla('const x = 1;') === null);
  t('okunan imza yazılanla aynı', imzaOku(b) === i);
  console.log(h ? `ÖZ-SINAV DÜŞTÜ (${h})` : 'ÖZ-SINAV GEÇTİ');
  return h;
}

if (require.main === module) {
  if (process.argv.includes('--sinav')) process.exit(sinav() ? 1 : 0);
  const yaz = process.argv.includes('--yaz');
  let bayat = 0;
  for (const f of dosyalar()) {
    const ham = fs.readFileSync(f, 'utf8');
    const hesap = imzaHesapla(ham), yazili = imzaOku(ham);
    if (!hesap) { console.log(`  İMZA SATIRI YOK  ${path.basename(f)}`); bayat++; continue; }
    if (hesap === yazili) { console.log(`  güncel  ${path.basename(f)}  ${hesap}`); continue; }
    if (yaz) {
      fs.writeFileSync(f, ham.replace(SATIR, `const KOD_IMZA = "${hesap}";`));
      console.log(`  yazıldı ${path.basename(f)}  ${yazili} -> ${hesap}`);
    } else { console.log(`  BAYAT   ${path.basename(f)}  yazılı ${yazili} · olması gereken ${hesap}`); bayat++; }
  }
  if (!yaz && bayat) process.exit(1);
}
module.exports = { imzaHesapla, imzaOku, ESLEME, KLASOR };
