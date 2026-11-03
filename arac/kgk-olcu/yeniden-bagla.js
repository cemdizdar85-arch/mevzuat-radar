// Bütün dönemler içerikle yeniden bağlanır (bagla.js). Çıktı: ayirici-girdi-yeni.json (kimlik = yeni bağ) +
// kimlik-esle.json (eski kimlik → yeni kimlik; elle kalıp etiketi metne bağlı olduğu için yeni kimliğe taşınır). 0 USD.
// node yeniden-bagla.js <etiketKlasoru>
const fs = require('fs'), path = require('path'); const { bagla } = require('./bagla.js');
const IS = path.join(__dirname, '..'), ET = process.argv[2];
const oku = f => JSON.parse(fs.readFileSync(f, 'utf8').replace(/^﻿/, ''));
const C = oku(path.join(IS, 'cikmis-kgk-onbellek.json'));
const ID = { 12103: '12103', 12104: '12104', 11972: '11972', 11769: '11769', ca1444: 'ca1444', 10202: '10202', 10209: '10209', ca4695: 'ca4695', 10248: '10248',
  10270: '10270', ca4801: 'ca4801', '2022-11-12': '11486', '2023-07-08': '11487', 11544: '11544', 11967: '11967', 11966: '11966', 11969: '11969', 11970: '11970',
  11971: '11971', 6541: '6541', 6551: '6551', 6553: '6553', 8030: '8030', 8031: '8031' };
const ESKI_MODUL = /^\s*(muhasebe|genel hukuk.*)\s*$/i; // 03.11 düzeltme: eski desen 'Muhasebe Standartları'nı da dışlıyordu
const isB = d => /(_B[_\-\. ]|B_Kit|-B-|_B\)|Oturumu-B|_-_B|B_Grubu|_B$|SABAH_B|OGLE_B|B_KİT|Sabah_B|ÖS_B|OS_B|_B-\d|B-[12]\)|SINAV_SABAH_-_B|SONRA_-_B|SONRA-B|SABAH_-B)/i.test(d);
const isOgle = d => /(ö_?s_|ös_|öğle|ogle|ikinci|ıkinci|II__Oturum|OS_|Ö_S|-2\)|A-2|SONRA)/i.test(d);
const hep = [], esle = {}, rapor = [];
for (const [f, id] of Object.entries(ID)) {
  const ef = path.join(ET, f + '.json'); if (!fs.existsSync(ef)) continue;
  const j = oku(ef); const mods = []; for (const q of j.sorular) if (!mods.includes(q.modul)) mods.push(q.modul);
  const etiketBul = (m, n) => j.sorular.find(q => q.modul === m && q.no === n);
  const kit = C.filter(k => !/CEVAP|GORSEL/.test(k.d) && k.d.includes(id) && !isB(k.d.split('(').pop()));
  let kalan = [...mods], degisen = 0, top = 0;
  for (const L of [kit.filter(k => !isOgle(k.d.split('(').pop())), kit.filter(k => isOgle(k.d.split('(').pop()))]) {
    if (!L.length) continue;
    const S = L[0].m.split(/\n(?=SORU \d+:)/).map(s => s.match(/^SORU (\d+):\s*([\s\S]*?)\n\s*A\)\s*([\s\S]*)$/)).filter(Boolean)
      .map(s => ({ n: +s[1], kok: s[2].replace(/\s+/g, ' ').trim(), sik: s[3].split(/\n\s*[B-E]\)\s*/).map(x => x.replace(/\s+\d+\s+[A-ZÇĞİÖŞÜ ,]{8,}.*$/, '').replace(/\s+/g, ' ').trim()) }));
    const bu = kalan.splice(0, S.filter(s => s.n === 1).length);
    for (const x of bagla(S, bu, etiketBul)) {
      if (ESKI_MODUL.test(x.modul)) continue; const et = etiketBul(x.modul, x.no); if (!et) continue;
      const yeni = `${f}|${x.modul}|${x.no}`; esle[`${f}|${x.eskiModul}|${x.no}`] = yeni; top++; if (x.degisti) degisen++;
      hep.push({ kimlik: yeni, donem: j.donem, modul: x.modul, no: x.no, konu: et.konu, cevap: et.cevap, kok: x.kok, siklar: x.sik });
    }
  }
  rapor.push(`${f} ${j.donem}: ${top} soru · bağı değişen ${degisen} (%${top ? Math.round(100 * degisen / top) : 0})`);
}
fs.writeFileSync(path.join(__dirname, 'ayirici-girdi-yeni.json'), JSON.stringify(hep));
fs.writeFileSync(path.join(__dirname, 'kimlik-esle.json'), JSON.stringify(esle));
console.log(rapor.join('\n') + `\n→ ${hep.length} soru`);
