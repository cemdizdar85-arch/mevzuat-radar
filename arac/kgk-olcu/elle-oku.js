// Elle kalıp etiketlerini YENİ bağ kimliğiyle döndürür. Parça 1–25 eski (sıra kuralı) kimlikle yazıldı → kimlik-esle ile taşınır;
// parça 26+ yeni bağ kimliğiyle yazıldı → doğrudan. (İki kümeyi tek eşleme tablosuna karıştırmak aynı adlı iki kimliği birbirine geçirebilir.)
const fs = require('fs'), path = require('path');
module.exports = function elleOku(D = __dirname) {
  const oku = f => JSON.parse(fs.readFileSync(path.join(D, f), 'utf8').replace(/^﻿/, ''));
  const esle = oku('kimlik-esle.json'), out = {}; let tasinamayan = 0;
  for (const f of fs.readdirSync(D).filter(x => /^etiket-\d+\.json$/.test(x))) {
    const p = +f.match(/\d+/)[0];
    for (const [k, h] of Object.entries(oku(f))) { const y = p <= 25 ? esle[k] : k; if (y) out[y] = h; else tasinamayan++; }
  }
  return { etiket: out, tasinamayan };
};
