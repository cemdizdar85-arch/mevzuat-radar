// KGK kalıp elle etiketi — BÜTÜN sınavlar (Cem 03.11 "bütün kgk sınavlarına incele"). girdi-kur.js'in genişletilmişi.
// İlk 4 dönem (12103 · 12104 · 11972 · 11769) girdi-1..8'de etiketlendi → burada atlanır. Eski genel muhasebe + genel hukuk modülleri
// bugünkü sınavda yok → atlanır. Bağlama aynı: kitapçıkta k. "SORU n:" = oturumun k. modülü; SORU 1 sayısı modül sayısını tutmayan
// oturum RAPORLANIR ve atlanır (bozuk bağ etiketlenmez). Soru metni DEPOYA GİRMEZ.
// node girdi-kur-hepsi.js <etiketKlasoru>  → girdi-9.. + ayirici-girdi-hepsi.json
const fs = require('fs'), path = require('path');
const IS = path.join(__dirname, '..'), ET = process.argv[2];
const oku = f => JSON.parse(fs.readFileSync(f, 'utf8').replace(/^﻿/, ''));
const C = oku(path.join(IS, 'cikmis-kgk-onbellek.json'));
const YAPILDI = new Set(['12103', '12104', '11972', '11769']);
const ESKI_MODUL = /^(muhasebe|genel hukuk)/i;
const isB = d => /(_B[_\-\. ]|B_Kit|-B-|_B\)|Oturumu-B|_-_B|B_Grubu|_B$|SABAH_B|OGLE_B|B_KİT|Sabah_B|ÖS_B|OS_B|_B-\d|B-[12]\)|SINAV_SABAH_-_B|SONRA_-_B|SONRA-B|SABAH_-B)/i.test(d);
const isOgle = d => /(ö_?s_|ös_|öğle|ogle|ikinci|ıkinci|II__Oturum|OS_|Ö_S|-2\)|A-2|SONRA)/i.test(d);
// etiket dosyası → kitapçık kimliği (onbellek d alanında geçen önek)
const ID = { ca1444: 'ca1444', 8166: '8166', 10202: '10202', 10209: '10209', ca4695: 'ca4695', 10248: '10248', 10270: '10270', ca4801: 'ca4801',
  '2022-11-12': '11486', '2023-07-08': '11487', 11544: '11544', 11967: '11967', 11966: '11966', 11969: '11969', 11970: '11970', 11971: '11971',
  6541: '6541', 6551: '6551', 6553: '6553', 6555: '6555', 6557: '6557', 6558: '6558', 8030: '8030', 8031: '8031' };
const hep = []; const rapor = [];
for (const [f, id] of Object.entries(ID)) {
  if (YAPILDI.has(f)) continue;
  const ef = path.join(ET, f + '.json'); if (!fs.existsSync(ef)) { rapor.push(`${f}: etiket YOK`); continue; }
  const j = oku(ef); const mods = []; for (const q of j.sorular) if (!mods.includes(q.modul)) mods.push(q.modul);
  const kit = C.filter(k => !/CEVAP|GORSEL/.test(k.d) && k.d.includes(id) && !isB(k.d.split('(').pop()));
  let kalan = [...mods]; let eklendi = 0;
  for (const L of [kit.filter(k => !isOgle(k.d.split('(').pop())), kit.filter(k => isOgle(k.d.split('(').pop()))]) {
    if (!L.length) continue;
    const S = L[0].m.split(/\n(?=SORU \d+:)/).map(s => s.match(/^SORU (\d+):\s*([\s\S]*?)\n\s*A\)\s*([\s\S]*)$/)).filter(Boolean);
    const bir = S.filter(s => +s[1] === 1).length; const bu = kalan.splice(0, bir);
    // bağ denetimi: her modülde 30+ farklı soru numarası okunmalı; yoksa kitapçık metni bozuk → oturum atlanır
    const say = {}, gorulen = {};
    const adaylar = [];
    for (const s of S) {
      const n = +s[1]; say[n] = (say[n] || 0) + 1; const md = bu[say[n] - 1]; if (!md) continue;
      (gorulen[md] = gorulen[md] || new Set()).add(n);
      if (ESKI_MODUL.test(md)) continue;
      const et = j.sorular.find(q => q.modul === md && q.no === n); if (!et) continue;
      const siklar = s[3].split(/\n\s*[B-E]\)\s*/).map(x => x.replace(/\s+\d+\s+[A-ZÇĞİÖŞÜ ,]{8,}.*$/, '').replace(/\s+/g, ' ').trim());
      adaylar.push({ kimlik: `${f}|${md}|${n}`, donem: j.donem, modul: md, no: n, konu: et.konu, kok: s[2].replace(/\s+/g, ' ').trim(), siklar });
    }
    const zayif = bu.filter(md => !ESKI_MODUL.test(md) && (gorulen[md] || new Set()).size < 30);
    if (!bu.length || zayif.length) { rapor.push(`${f} ${j.donem} ${L[0].d.split('(').pop().slice(0, 30)}: BAĞ BOZUK (SORU1×${bir}, zayıf: ${zayif.map(x => x.slice(0, 14)).join(',') || '-'}) → atlandı`); continue; }
    hep.push(...adaylar); eklendi += adaylar.length;
  }
  rapor.push(`${f} ${j.donem}: ${eklendi} soru`);
}
fs.writeFileSync(path.join(__dirname, 'ayirici-girdi-hepsi.json'), JSON.stringify(hep));
const PARCA = 140; let p = 8;
for (let i = 0; i < hep.length; i += PARCA) { p++; fs.writeFileSync(path.join(__dirname, `girdi-${p}.json`), JSON.stringify(hep.slice(i, i + PARCA).map(({ kimlik, modul, kok, siklar }) => ({ kimlik, modul, kok, siklar })), null, 1)); }
console.log(rapor.join('\n') + `\n→ ${hep.length} soru · parça 9..${p}`);
