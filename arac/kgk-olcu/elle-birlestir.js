// 25 parça elle etiketi → yeni bağ kimliğine taşı → depo dosyası (soru metni YOK; yalnız dönem|modül → 40 harflik dizi).
// node elle-birlestir.js <depo>   → <depo>/veri/sinav/kgk-kalip-elle-<n>.json
const fs = require('fs'), path = require('path');
const D = __dirname, oku = f => JSON.parse(fs.readFileSync(path.join(D, f), 'utf8').replace(/^﻿/, ''));
const yeni = oku('ayirici-girdi-yeni.json'); const donem = {}; for (const q of yeni) donem[q.kimlik.split('|')[0]] = q.donem;
const gecerli = new Set(yeni.map(q => q.kimlik));
const { etiket, tasinamayan: kayip } = require('./elle-oku.js')(D);
const tasinan = {}; let n = 0; for (const [k, h] of Object.entries(etiket)) if (gecerli.has(k)) { tasinan[k] = h; n++; }
const dizi = {};
for (const [k, h] of Object.entries(tasinan)) { const [f, m, no] = k.split('|'); const a = (dizi[`${f}|${m}`] = dizi[`${f}|${m}`] || Array(40).fill('.')); a[+no - 1] = h; }
const cikti = { _aciklama: `03.11.2026 elle okuma (25 okuyucu, Cem "Evet, kur" + "bütün kgk sınavlarına incele"): KGK çıkmış soru cümlesi kalıbı. Anahtar = etiket dosyası|modül (veri/kgk-arsiv/etiket/<id>.json), dizi sırası = soru no 1..40, '.' = etiketlenmedi/bağlanamadı, '?' = metin okunamadı. Harfler bitirme sözlüğüyle AYNI (bitirme-kalip-elle-320.json): A doğrudur · B yanlıştır · C değildir/sayılmaz · U sayılır/görevidir · D öncüllü · E boşluk · G hüküm sayısı/zamanı · F hesap · L sırasıyla · I defter kaydı · J hangi hesap · K kayıt→işlem · M tanım↔terim · N yetkili merci · O eylem→ceza/suç · P durum→davranış · S grafik/tablo yorumu. Metin↔etiket bağı içerikle kuruldu (kgk-is/kalip/bagla.js; eski sıra kuralı %18–35 kayıyordu). Kapsam dışı: 2013, 2014, Mart 2015, Kasım 2018 (kitapçık metni bozuk) + eski genel muhasebe/genel hukuk modülleri. ${n} soru.`, donemler: donem, ...Object.fromEntries(Object.entries(dizi).sort().map(([k, a]) => [k, a.join('')])) };
const hedef = path.join(process.argv[2], 'veri', 'sinav', `kgk-kalip-elle-${n}.json`);
fs.writeFileSync(hedef, JSON.stringify(cikti, null, 1) + '\n');
console.log(`taşınan ${n} · eşi bulunamayan ${kayip} → ${hedef}`);
