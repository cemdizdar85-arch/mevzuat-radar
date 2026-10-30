// smmm-elle-ret.json'a tur2 temizliğinin kayıtlarını ekler (soru metni YOK). node ret-ekle2.js <smmm-elle-ret.json> <ret-tur2.json>
const fs = require('fs');
const [yol, kaynak] = process.argv.slice(2);
const ham = fs.readFileSync(yol, 'utf8'); const j = JSON.parse(ham.replace(/^\uFEFF/, ''));
const yeni = JSON.parse(fs.readFileSync(kaynak, 'utf8'));
const K = 'Cem 30.10 ilk 80 temizliği tur2: iki kör çözücü + resmî metinle doğrulayıcı kararı (C:\\TETIKTE-CALISMA\\kalip-olcum)';
let n = 0; for (const [id, g] of Object.entries(yeni)) { if (j.kayitlar[id]) continue; j.kayitlar[id] = { gerekce: g, kaynak: K, tarih: '2026-10-30' }; n++; }
fs.writeFileSync(yol, JSON.stringify(j, null, 4) + '\n'); console.log('eklendi', n, 'toplam', Object.keys(j.kayitlar).length);
