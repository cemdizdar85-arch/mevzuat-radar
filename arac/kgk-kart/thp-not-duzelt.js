// Okuyucuların yanlış "Tekdüzen hesap planı ambarda yok / kod yazılmaz" notunu düzeltir (05.11 ölçüldü: "THP 100 - Kasa" … ambarda VAR). Bedel 0.
'use strict';
const fs = require('fs'), path = require('path'); const D = path.join(__dirname, 'kartlar');
const EK = ' [kgkbasim THP 05.11: Tekdüzen hesap planı ambarda VAR ("THP NNN - …" kayıtları); hesap kodu YALNIZ ambardaki THP (TMS/TFRS kökü) ya da KGK FRS planı (BOBİ kökü) kaydından alınır, hafızadan yazılmaz.]';
const RE = /hesap plan[ıi][^.]{0,60}(ambarda yok|yok)|kod (konmaz|yazılmaz|yazilmaz|yazma)/i;
let n = 0;
for (const f of fs.readdirSync(D)) {
  const a = JSON.parse(fs.readFileSync(path.join(D, f), 'utf8'));
  for (const c of a) if (RE.test(c.yazim_notu || '') && !(c.yazim_notu || '').includes('kgkbasim THP')) { c.yazim_notu += EK; n++; }
  fs.writeFileSync(path.join(D, f), JSON.stringify(a, null, 1) + '\n');
}
console.log('THP notu düzeltilen kart', n);
