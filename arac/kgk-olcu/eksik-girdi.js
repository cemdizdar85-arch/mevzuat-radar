// Yeni bağda kalıp etiketi olmayan sorular → girdi-26.. (elle etiket için). Etiket metne bağlı: eski parça etiketleri kimlik-esle ile taşınır.
const fs = require('fs'), path = require('path');
const D = __dirname, oku = f => JSON.parse(fs.readFileSync(path.join(D, f), 'utf8').replace(/^﻿/, ''));
const esle = oku('kimlik-esle.json'), G = oku('ayirici-girdi-yeni.json');
const var_ = new Set(); for (const f of fs.readdirSync(D).filter(x => /^etiket-\d+\.json$/.test(x))) for (const k of Object.keys(oku(f))) if (esle[k]) var_.add(esle[k]);
const eksik = G.filter(q => !var_.has(q.kimlik));
const bas = Math.max(25, ...fs.readdirSync(D).map(x => +(x.match(/^girdi-(\d+)\.json$/) || [])[1] || 0)); let p = bas;
for (let i = 0; i < eksik.length; i += 140) { p++; fs.writeFileSync(path.join(D, `girdi-${p}.json`), JSON.stringify(eksik.slice(i, i + 140).map(({ kimlik, modul, kok, siklar }) => ({ kimlik, modul, kok, siklar })), null, 1)); }
// bu parçaların kimliği zaten YENİ bağdadır → kimlik-esle'ye kendisiyle eşlenir
const yeniEsle = { ...esle }; for (const q of eksik) yeniEsle[q.kimlik] = yeniEsle[q.kimlik] || q.kimlik; fs.writeFileSync(path.join(D, 'kimlik-esle.json'), JSON.stringify(yeniEsle));
console.log(`etiketli ${var_.size} · eksik ${eksik.length} → girdi-${bas + 1}..${p}`);
