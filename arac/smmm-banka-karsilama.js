#!/usr/bin/env node
/* ============================================================================
 *  YETERLİLİK BANKA KARŞILAMA — sitedeki soru bankası, çıkmış sınavda en sık sorulan konuları ne kadar karşılıyor?
 *  (05.10.2026, Cem "1 ve 2 yapalım" madde 2)
 *  GİRDİ: veri/sinav/smmm-konu-okuma.json (çıkmış: konu → kaç dönem, okunarak) + <klasör>/sonuc-bN.json (sitedeki her soru
 *         okunarak AYNI konu sözlüğüne bağlandı; paket_soru sinav=smmm). Kasa etiketi (paket_soru.konu) KULLANILMAZ — ölçüldü:
 *         standart maliyet farkı sorusu "kapanış kaydı" etiketli.
 *  ÇIKTI: veri/sinav/SMMM-BANKA-KARSILAMA.md (soru metni YOK; yalnız sayı) + .json
 *  DURUM: YOK (0 soru) · AZ (çıkmışta ≥10 dönem ama < 10 soru) · tamam. Eşik bir karar önerisidir, ölçü değil.
 *  🚫 GÖRMEZ: soru KALİTESİ (yalnız sayı) · eşleyicinin sınırda kararı · sözlükte olmayan konuya giden sitedeki sorular ("—" satırı).
 *  Kullanım: node arac/smmm-banka-karsilama.js <eşleme klasörü>
 * ==========================================================================*/
'use strict';
const fs = require('fs'), path = require('path');
const KOK = path.join(__dirname, '..');
const DIR = process.argv[2]; if (!DIR) { console.error('kullanım: <eşleme klasörü>'); process.exit(2); }
const ok = JSON.parse(fs.readFileSync(path.join(KOK, 'veri', 'sinav', 'smmm-konu-okuma.json'), 'utf8'));
const DONEM = ok.donem;
const dersSira = JSON.parse(fs.readFileSync(path.join(KOK, 'veri', 'soru-dizini.json'), 'utf8')).sinavlar.find(x => x.kod === 'smmm').dersler.map(d => d.ad);
const es = {}; fs.readdirSync(DIR).filter(f => /^sonuc-b\d+\.json$/.test(f)).forEach(f => Object.assign(es, JSON.parse(fs.readFileSync(path.join(DIR, f), 'utf8'))));
const bankaDers = JSON.parse(fs.readFileSync(path.join(DIR, 'banka-ders.json'), 'utf8'));   // id → ders (eşleme partisi kurulurken yazılır)
const eksik = Object.keys(bankaDers).filter(id => !(id in es));
if (eksik.length) { console.error('KIRMIZI: eşlemesi olmayan ' + eksik.length + ' soru'); process.exit(3); }

const cik = {}; for (const x of ok.kararlar) { const r = ((cik[x.ders] = cik[x.ders] || {})[x.konu] = cik[x.ders][x.konu] || new Set()); r.add(x.donem); }
const site = {}, bosta = {}; let yanlisAd = 0;
for (const [id, konular] of Object.entries(es)) {
  const d = bankaDers[id];
  if (!konular.length) { bosta[d] = (bosta[d] || 0) + 1; continue; }
  for (const k of konular) { if (!(k in ok.konular[d])) { yanlisAd++; continue; } site[d] = site[d] || {}; site[d][k] = (site[d][k] || 0) + 1; }
}
if (yanlisAd) { console.error('KIRMIZI: sözlükte olmayan ' + yanlisAd + ' konu adı'); process.exit(3); }
const satirlar = {}, ozet = [];
for (const d of dersSira) {
  const L = Object.keys(ok.konular[d]).map(k => {
    const don = cik[d][k] ? cik[d][k].size : 0, n = (site[d] || {})[k] || 0;
    const durum = n === 0 ? (don ? 'YOK' : '—') : (don >= 10 && n < 10 ? 'AZ' : 'tamam');
    return { konu: k, donem: don, soru: n, durum };
  }).sort((p, q) => q.donem - p.donem || q.soru - p.soru);
  satirlar[d] = L;
  const ilk10 = L.filter(x => x.donem).slice(0, 10);
  ozet.push({ ders: d, banka: Object.values(bankaDers).filter(x => x === d).length, ilk10_yok: ilk10.filter(x => x.durum === 'YOK').length, ilk10_az: ilk10.filter(x => x.durum === 'AZ').length, sozluk_disi: bosta[d] || 0 });
}
const tarih = new Date().toISOString().slice(0, 10);
let md = `# Yeterlilik — soru bankası, çıkmışta sık sorulan konuları karşılıyor mu?\n\n`
  + `> Üretici: \`arac/smmm-banka-karsilama.js\` (elle düzenlenmez) · ölçüm ${tarih}\n`
  + `> Çıkmış: ${ok.pencere}, ${DONEM} dönem, okunarak (veri/sinav/smmm-konu-okuma.json). Site: paket_soru sinav=smmm, ${Object.keys(bankaDers).length} soru, her soru okunarak aynı sözlüğe bağlandı.\n`
  + `> Durum: **YOK** = sitede 0 soru · **AZ** = çıkmışta ≥10 dönem ama sitede <10 soru (eşik öneridir). Soru KALİTESİ bu raporda ölçülmez.\n\n`
  + `## Özet\n\n| Ders | Sitede soru | İlk 10 konuda YOK | İlk 10 konuda AZ | Sözlük dışı soru |\n|---|---|---|---|---|\n`
  + ozet.map(o => `| ${o.ders} | ${o.banka} | ${o.ilk10_yok} | ${o.ilk10_az} | ${o.sozluk_disi} |`).join('\n') + '\n';
for (const d of dersSira) {
  md += `\n## ${d}\n\n| Konu | Çıkmışta dönem | Sitede soru | Durum |\n|---|---|---|---|\n`
    + satirlar[d].map(x => `| ${x.konu} | ${x.donem} / ${DONEM} | ${x.soru} | ${x.durum === 'tamam' ? '' : '**' + x.durum + '**'} |`).join('\n') + '\n';
}
fs.writeFileSync(path.join(KOK, 'veri', 'sinav', 'SMMM-BANKA-KARSILAMA.md'), md);
fs.writeFileSync(path.join(KOK, 'veri', 'sinav', 'smmm-banka-karsilama.json'), JSON.stringify({ olcum: tarih, donem: DONEM, ozet, satirlar }, null, 1));
console.log(ozet.map(o => o.ders + ': banka ' + o.banka + ' · ilk10 YOK ' + o.ilk10_yok + ' AZ ' + o.ilk10_az + ' · sözlük dışı ' + o.sozluk_disi).join('\n'));
