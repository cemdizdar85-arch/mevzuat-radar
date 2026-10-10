// arac/model-izi-olc.js — soru partilerinde model ADI izi ölçümü (10.10.2026, CLAUDE.md "veriye model adı girmez"). BEDEL 0, AĞ YOK.
// Okur: veri/fabrika/kalip-parti-*.json (yerel önbellek; ambarın kopyası DEĞİL, en son indirme anı kadar tazedir — rapora yazılır).
// Basar: yalnız alan YOLU + değer (model adı) + kayıt sayısı + sınav kırılımı. Soru kimliği, soru metni, şık BASILMAZ.
// Sayım: (1) anahtarı tam "model" olan ve değeri claude- ile başlayan alan (motor/model-kod.ps1'in çevirdiği küme)
//        (2) başka anahtarda TAM model kimliği değeri (^claude-(haiku|sonnet|opus)…$) — ağ bunu ÇEVİRMEZ, ayrı sayılır
//        (3) anahtar ADINDA model (simulasyon_sonnet) — ağ bunu ÇEVİRMEZ, ayrı sayılır
// 🚫 GÖRMEZ: düz metnin içinde geçen ad (alt dize araması yapılmaz: "msgbatch_…Kq4EUoPUS…" kimliği "opus" içerir, 10.10 ilk ölçümde yanlış alarm verdi).
// Kullanım: node arac/model-izi-olc.js [--klasor veri/fabrika] [--cikti dosya.json]
'use strict';
const fs = require('fs'), path = require('path');
const arg = (ad, vars) => { const i = process.argv.indexOf(ad); return i > 0 ? process.argv[i + 1] : vars; };
const klasor = arg('--klasor', path.join(__dirname, '..', 'veri', 'fabrika'));
const cikti = arg('--cikti', '');
const TAM_ID = /^claude-(haiku|sonnet|opus)[a-z0-9.-]*$/i, ANAHTAR = /(sonnet|haiku|opus|claude)/i;

const dosyalar = fs.readdirSync(klasor).filter(f => /^kalip-parti-.*\.json$/.test(f));
const r = { olcum: new Date().toISOString(), klasor: path.relative(path.join(__dirname, '..'), klasor).replace(/\\/g, '/'),
  dosya_toplam: dosyalar.length, dosya_okunamayan: 0, sistem_dosyasi_atlanan: 0, onbellek_en_eski: null, onbellek_en_yeni: null,
  kayit_toplam: 0, kayit_izli: 0, sinav: {}, model_alani: {}, baska_anahtarda_tam_id: {}, anahtar_adinda_model: {} };
const ekle = (h, k) => { h[k] = (h[k] || 0) + 1; };
function gez(o, yol, acc) {
  if (!o || typeof o !== 'object') return;
  if (Array.isArray(o)) { for (const x of o) gez(x, yol + '[]', acc); return; }
  for (const [k, v] of Object.entries(o)) {
    const y = yol ? yol + '.' + k : k;
    if (ANAHTAR.test(k)) acc.add('K|' + y);
    if (typeof v === 'string') {
      if (k === 'model' && /^claude-/i.test(v)) acc.add('M|' + y + ' = ' + v);
      else if (TAM_ID.test(v.trim())) acc.add('T|' + y + ' = ' + v);
    } else gez(v, y, acc);
  }
}
for (const f of dosyalar) {
  const tam = path.join(klasor, f), st = fs.statSync(tam);
  const m = st.mtime.toISOString();
  if (!r.onbellek_en_eski || m < r.onbellek_en_eski) r.onbellek_en_eski = m;
  if (!r.onbellek_en_yeni || m > r.onbellek_en_yeni) r.onbellek_en_yeni = m;
  const etiket = f.replace(/^kalip-parti-/, '').replace(/\.json$/, '');
  if (etiket.startsWith('__')) { r.sistem_dosyasi_atlanan++; continue; }
  let j; try { j = JSON.parse(fs.readFileSync(tam, 'utf8').replace(/^﻿/, '')); } catch (e) { r.dosya_okunamayan++; continue; }
  const sv = (etiket.match(/^([a-z]+)/) || [, 'diger'])[1];
  if (!r.sinav[sv]) r.sinav[sv] = { kayit: 0, izli: 0 };
  for (const s of Object.values(j && typeof j === 'object' && !Array.isArray(j) ? j : {})) {
    if (!s || typeof s !== 'object') continue;
    r.kayit_toplam++; r.sinav[sv].kayit++;
    const acc = new Set(); gez(s, '', acc);
    if (acc.size) { r.kayit_izli++; r.sinav[sv].izli++; }
    for (const a of acc) {
      const [tur, k] = [a.slice(0, 1), a.slice(2)];
      ekle(tur === 'M' ? r.model_alani : tur === 'T' ? r.baska_anahtarda_tam_id : r.anahtar_adinda_model, k);
    }
  }
}
const sirala = h => Object.fromEntries(Object.entries(h).sort((a, b) => b[1] - a[1]));
r.model_alani = sirala(r.model_alani); r.baska_anahtarda_tam_id = sirala(r.baska_anahtarda_tam_id); r.anahtar_adinda_model = sirala(r.anahtar_adinda_model);
r.model_alani_toplam = Object.values(r.model_alani).reduce((a, b) => a + b, 0);
const metin = JSON.stringify(r, null, 1);
if (cikti) fs.writeFileSync(cikti, metin + '\n'); else console.log(metin);
console.log(`MODEL-IZI-OLCUM: ${r.kayit_izli}/${r.kayit_toplam} kayıtta iz · model alanı ${r.model_alani_toplam} · okunamayan dosya ${r.dosya_okunamayan}`);
