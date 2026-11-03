// KGK kalıp elle etiketi için girdi: son 4 dönem (12103 Haz26 · 12104 Kas25 · 11972 Haz25 · 11769 Haz24), A kitapçıkları.
// Bağlama konu-profil.js kur ile aynı: kitapçıkta k. "SORU n:" = oturumun k. modülü. Çıktı yalnız bu klasöre (soru metni DEPOYA GİRMEZ).
// node girdi-kur.js <etiketKlasoru>  → girdi-<parca>.json (≈140 soru/parça) + ayirici-girdi.json (hepsi)
const fs = require('fs'), path = require('path');
const IS = path.join(__dirname, '..'), ET = process.argv[2];
const oku = f => JSON.parse(fs.readFileSync(f, 'utf8').replace(/^﻿/, ''));
const C = oku(path.join(IS, 'cikmis-kgk-onbellek.json'));
const DONEM = { 12103: '12103', 12104: '12104', 11972: '11972', 11769: '11769' };
const isB = d => /(_B[_\-\. ]|B_Kit|-B-|_B\)|Oturumu-B|_-_B|B_Grubu|_B$|SABAH_B|OGLE_B|B_KİT|Sabah_B|ÖS_B|OS_B)/i.test(d);
const isOgle = d => /(ö_?s_|ös_|öğle|ogle|ikinci|ıkinci|II__Oturum|OS_|Ö_S)/i.test(d);
const hep = []; const rapor = [];
for (const [f, id] of Object.entries(DONEM)) {
  const j = oku(path.join(ET, f + '.json')); const mods = []; for (const q of j.sorular) if (!mods.includes(q.modul)) mods.push(q.modul);
  const kit = C.filter(k => !/CEVAP|GORSEL/.test(k.d) && k.d.includes(id) && !isB(k.d.split('(').pop())); let kalan = [...mods];
  for (const L of [kit.filter(k => !isOgle(k.d.split('(').pop())), kit.filter(k => isOgle(k.d.split('(').pop()))]) {
    if (!L.length) continue;
    const S = L[0].m.split(/\n(?=SORU \d+:)/).map(s => s.match(/^SORU (\d+):\s*([\s\S]*?)\n\s*A\)\s*([\s\S]*)$/)).filter(Boolean);
    const bu = kalan.splice(0, S.filter(s => +s[1] === 1).length); const say = {};
    for (const s of S) {
      const n = +s[1]; say[n] = (say[n] || 0) + 1; const md = bu[say[n] - 1]; if (!md) continue;
      const et = j.sorular.find(q => q.modul === md && q.no === n); if (!et) continue;
      const siklar = s[3].split(/\n\s*[B-E]\)\s*/).map(x => x.replace(/\s+\d+\s+[A-ZÇĞİÖŞÜ ,]{8,}.*$/, '').replace(/\s+/g, ' ').trim());
      hep.push({ kimlik: `${f}|${md}|${n}`, donem: j.donem, modul: md, no: n, konu: et.konu, kok: s[2].replace(/\s+/g, ' ').trim(), siklar });
    }
    rapor.push(`${f} ${j.donem}: ${bu.join(' · ')}`);
  }
}
fs.writeFileSync(path.join(__dirname, 'ayirici-girdi.json'), JSON.stringify(hep));
const PARCA = 140; let p = 0;
for (let i = 0; i < hep.length; i += PARCA) { p++; fs.writeFileSync(path.join(__dirname, `girdi-${p}.json`), JSON.stringify(hep.slice(i, i + PARCA).map(({ kimlik, modul, kok, siklar }) => ({ kimlik, modul, kok, siklar })), null, 1)); }
console.log(rapor.join('\n') + `\n→ ${hep.length} soru · ${p} parça`);
