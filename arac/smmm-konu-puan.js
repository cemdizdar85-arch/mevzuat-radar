#!/usr/bin/env node
// ============================================================================
//  YETERLİLİK KONU PUAN AĞIRLIĞI (18.10.2026, Cem: "en çok çıkan sorulardan olsun ve puanlarda en çok puan verilen
//  konuları önceliğe çıkaralım ki insanlara gerçekten kazandıralım sınavı").
//
//  Soru: bir konu, son 10 yılın (smmm-konu-okuma.json penceresi) sınavlarında DÖNEM BAŞINA ortalama kaç puan getirdi?
//  Kaynaklar:
//    · konu ↔ (dönem, soru no): veri/sinav/smmm-konu-okuma.json (soru metni okunarak eşlenmiş; tek okuyucu)
//    · 2026/1–2026/2 TEST usulü: her soru 5 puan (TÜRMOB YK 14.01.2026: 20 soru, yanlış 0,25 götürür) → ölçülmüş kural.
//    · 2016–2025 KLASİK: soru puanı komisyon cevabında YAZILIYSA yerel arşivden okunur
//      (_yerel-veri-kasasi/cikmis-sinav/SINAV-SMMM-*.json, git'e girmez). Bir kâğıt yalnız ana soruların HEPSİNİN puanı
//      okunup toplamı 100 ±2 tutarsa "puanlı" sayılır; yoksa o kâğıtta ana sorular EŞİT puan sayılır (= "ölçülmedi, eşit").
//  Bölüşüm: ana sorunun puanı, o ana sorunun okunmuş konu satırlarına (alt soru × konu) eşit bölünür.
//  Ağırlık = konunun pencere boyunca topladığı puan ÷ dersin pencere dönem sayısı (dönem başına beklenen puan).
//  ÇIKTI: veri/sinav/smmm-konu-puan.json — yalnız rakam + dönem + soru no (soru metni YOK).
//  🚫 GÖRMEZ: alt soru puanı (ana soru içinde eşit bölünür) · OCR'lı 2019–2025 kâğıtlarında arşive metin olarak girmemiş
//    puan · okuyucunun konu genişliği farkı · puanı yazılı olmayan kâğıdın gerçek puanı (eşit varsayılır, rapor sayar).
//  Kullanım: node arac/smmm-konu-puan.js [--arsiv <klasör>] [--kuru] [--tablo]
// ============================================================================
'use strict';
const fs = require('fs'), path = require('path');
const KOK = path.join(__dirname, '..');
const arg = k => { const i = process.argv.indexOf(k); return i > 0 ? process.argv[i + 1] : null; };
const ARSIV = arg('--arsiv') || path.join(KOK, '..', '_yerel-veri-kasasi', 'cikmis-sinav');
const KURU = process.argv.includes('--kuru'), TABLO = process.argv.includes('--tablo');
const jsonOku = y => JSON.parse(fs.readFileSync(y, 'utf8').replace(/^﻿/, ''));
const srt = d => { const [y, n] = String(d).split('/'); return +y * 10 + +n; };
// arşiv dosya adındaki ders sırası (smmm_YYYY_N_NN) → okumadaki ders adı
const DERS_NO = { '01': 'Finansal Muhasebe', '02': 'Finansal Tablolar ve Analizi', '03': 'Maliyet Muhasebesi', '04': 'Muhasebe Denetimi',
  '05': 'Vergi Mevzuatı ve Uygulaması', '06': 'Hukuk', '07': 'Meslek Hukuku', '08': 'Sermaye Piyasası Mevzuatı' };
// ana soru no: '1a', '1A-B', '12' → sayı; Maliyet 2021/2 Roma rakamıyla (I–IV)
const ROMA = { I: 1, II: 2, III: 3, IV: 4, V: 5, VI: 6, VII: 7, VIII: 8, IX: 9, X: 10 };
const anaNo = s => { const m = String(s).match(/^\d+/); if (m) return m[0]; const r = String(s).match(/^(X|IX|VIII|VII|VI|V|IV|III|II|I)\b/); return r ? String(ROMA[r[1]]) : ''; };
const sayi = s => +String(s).replace(',', '.');

// Bir kâğıdın metninden ana soru → puan. Yalnız tam ve 100 ±2 tutan okuma döner, yoksa null.
function kagitPuan(metin, anaListe) {
  const t = String(metin).replace(/\r/g, '');
  const iz = []; const re = /(?:^|\n)\s*(?:SORU|CEVAP)\s*[-:.]?\s*(\d{1,2})\s*[-:.)]/gi; let m;
  while ((m = re.exec(t))) iz.push({ no: m[1], i: m.index });
  if (!iz.length) return null;
  // aynı numara birden çok kez (soru kitapçığı + cevap) → her numara için puanı okunabilen İLK bölüm
  const puan = {};
  iz.forEach((b, k) => {
    if (puan[b.no] != null) return;
    const parca = t.slice(b.i, k + 1 < iz.length ? iz[k + 1].i : t.length);
    if (/her\s*(bir)?\s*(madde|şık|kayıt|biri)[^\n]{0,30}puan|puan\s*\/|yarı puan/i.test(parca)) return;   // kalemli puan: okunmaz
    const top = parca.match(/toplam\s*[:=]?\s*(\d{1,3}(?:,\d+)?)\s*puan/i);
    if (top) { puan[b.no] = sayi(top[1]); return; }
    const p = [...parca.matchAll(/\(\s*(\d{1,3}(?:,\d+)?)\s*puan\s*\)/gi)].map(x => sayi(x[1]));
    if (p.length) puan[b.no] = p.reduce((a, x) => a + x, 0);
  });
  if (!anaListe.every(n => puan[n] > 0)) return null;
  const toplam = anaListe.reduce((a, n) => a + puan[n], 0);
  return Math.abs(toplam - 100) <= 2 ? Object.fromEntries(anaListe.map(n => [n, puan[n]])) : null;
}

const ok = jsonOku(path.join(KOK, 'veri', 'sinav', 'smmm-konu-okuma.json'));
// kâğıt = (ders, dönem) → ana soru → konu satırları
const K = {};
for (const x of ok.kararlar) {
  const a = anaNo(x.soru); if (!a) continue;
  const kg = (K[x.ders + '|' + x.donem] = K[x.ders + '|' + x.donem] || { ders: x.ders, donem: x.donem, ana: {} });
  (kg.ana[a] = kg.ana[a] || []).push({ soru: x.soru, konu: x.konu });
}
// arşiv metinleri (yalnız SMMM, ders + dönem dosya adından)
const metin = {};
let arsivVar = false;
try {
  for (const f of fs.readdirSync(ARSIV)) {
    const m = f.match(/smmm-(20\d\d)-(\d)-(0\d)\.json$/); if (!m || !f.startsWith('SINAV-SMMM-')) continue;
    const ders = DERS_NO[m[3]]; if (!ders) continue;
    arsivVar = true;
    const j = jsonOku(path.join(ARSIV, f));
    metin[ders + '|' + m[1] + '/' + m[2]] = (j.belgeler || []).map(b => b.metin || '').join('\n');
  }
} catch (e) {}
if (!arsivVar && !KURU) { console.log('KIRMIZI - yerel arşiv okunamadı (' + ARSIV + '); yazılmadı.'); process.exit(1); }

// FİNANSAL MUHASEBE klasik kâğıdı tek büyük uygulama sorusudur; komisyon puanı ana soruya değil KALEME yazar
//   ("Yevmiye kayıtlarının her biri 2,8 puan · Bilançonun düzenlenmesi 5,4 puan · Gelir Tablosunun düzenlenmesi 5 puan").
//   Ana soru eşit bölüşümü burada bilançoya ~50 puan verirdi; ölçülen 10–15. Kural: bilanço + gelir tablosu puanı
//   kâğıtta yazılıysa o (puanli), değilse puanı okunan FM kâğıtlarının ortalaması (tahmin); kalan puan öteki konu
//   satırlarına eşit (kâğıtta "her biri" eşit puan yazıyor).
const FM = 'Finansal Muhasebe', FM_BILANCO = 'Bilanço ve gelir tablosu düzenleme';
function fmBilancoPuan(t) {
  const b = String(t || '').match(/bilanço(?:nun)?\s*(?:düzenlenmesi)?[^\n\d]{0,30}?(\d{1,2}(?:,\d+)?)\s*puan/i);
  const g = String(t || '').match(/gelir\s*tablosu(?:nun)?\s*(?:düzenlenmesi)?[^\n\d]{0,30}?(\d{1,2}(?:,\d+)?)\s*puan/i);
  return b && g ? sayi(b[1]) + sayi(g[1]) : null;
}
const fmOlcu = Object.keys(metin).filter(k => k.startsWith(FM + '|') && K[k])   /* yalnız pencere dönemleri (okumada olan kâğıt) */
  .map(k => fmBilancoPuan(metin[k])).filter(x => x != null);
const FM_ORT = fmOlcu.length ? fmOlcu.reduce((a, x) => a + x, 0) / fmOlcu.length : null;

const kaynakSay = { test: 0, puanli: 0, esit: 0, tahmin: 0 };
const konu = {};   // ders → konu → {puan, soru:[[dönem, soru no, puan]]}
const dersDonem = {};
for (const kg of Object.values(K)) {
  const test = srt(kg.donem) >= 20261;
  const anaListe = Object.keys(kg.ana).sort((a, b) => a - b);
  let p = null, kaynak, satirPay = null;
  const mt = metin[kg.ders + '|' + kg.donem];
  if (test) { p = Object.fromEntries(anaListe.map(n => [n, 5])); kaynak = 'test'; }
  else if (kg.ders === FM && FM_ORT != null) {
    // satır başı puan: bilanço satırları B'yi, öteki satırlar (100 − B)'yi eşit paylaşır
    const tum = anaListe.flatMap(n => kg.ana[n]), bs = tum.filter(s => s.konu === FM_BILANCO).length;
    const olc = fmBilancoPuan(mt), B = bs ? (olc != null ? olc : FM_ORT) : 0;
    kaynak = olc != null || !bs ? (olc != null ? 'puanli' : 'esit') : 'tahmin';
    satirPay = s => s.konu === FM_BILANCO ? B / bs : (100 - B) / (tum.length - bs);
  } else { p = mt ? kagitPuan(mt, anaListe) : null; kaynak = p ? 'puanli' : 'esit';
    if (!p) p = Object.fromEntries(anaListe.map(n => [n, 100 / anaListe.length])); }
  kaynakSay[kaynak]++;
  (dersDonem[kg.ders] = dersDonem[kg.ders] || new Set()).add(kg.donem);
  for (const n of anaListe) {
    const satir = kg.ana[n];
    for (const s of satir) {
      const pay = satirPay ? satirPay(s) : p[n] / satir.length;
      const r = ((konu[kg.ders] = konu[kg.ders] || {})[s.konu] = konu[kg.ders][s.konu] || { puan: 0, test_soru: 0, klasik_puanli: 0, klasik_esit: 0, kanit: [] });
      r.puan += pay; if (kaynak === 'test') r.test_soru++; else if (kaynak === 'puanli') r.klasik_puanli += pay; else r.klasik_esit += pay;
      r.kanit.push([kg.donem, s.soru, Math.round(pay * 100) / 100, kaynak[0]]);
    }
  }
}
const yuv = x => Math.round(x * 100) / 100;
const dersler = {};
for (const d of Object.keys(konu)) {
  const nd = dersDonem[d].size;
  dersler[d] = { donem: nd, konular: Object.entries(konu[d]).map(([k, r]) => {
    const don = [...new Set(r.kanit.map(z => z[0]))];
    return { konu: k, agirlik: yuv(r.puan / nd), toplam_puan: yuv(r.puan), donem: don.length, satir: r.kanit.length,
      test_soru: r.test_soru, klasik_puanli: yuv(r.klasik_puanli), klasik_esit: yuv(r.klasik_esit),
      kanit: r.kanit.sort((a, b) => srt(b[0]) - srt(a[0])) };
  }).sort((a, b) => b.agirlik - a.agirlik || b.donem - a.donem) };
}
const cikti = { uretim: new Date().toISOString().slice(0, 16).replace('T', ' '), uretici: 'arac/smmm-konu-puan.js',
  pencere: ok.pencere, olcum: kaynakSay, fm_bilanco_olculen: fmOlcu, fm_bilanco_ort: FM_ORT == null ? null : yuv(FM_ORT),
  not: 'agirlik = konunun pencere boyunca topladığı puan ÷ dersin dönem sayısı (dönem başına beklenen puan, kâğıt 100). Test 2026: soru 5 puan. Klasik: komisyon cevabında yazılı puan (puanli) ya da ana sorular eşit (esit, ölçülmedi). kanit: [dönem, soru no, puan payı, t/p/e]. Soru metni YOK.',
  dersler };
console.log(`kâğıt: test ${kaynakSay.test} · klasik puanı okunan ${kaynakSay.puanli} · okunamayan: eşit ${kaynakSay.esit} + FM ortalama tahmin ${kaynakSay.tahmin} · FM bilanço+GT ölçülen ${fmOlcu.join("/")} (ort ${FM_ORT == null ? "-" : yuv(FM_ORT)})`);
if (TABLO) for (const d of Object.keys(dersler)) {
  console.log(`\n${d} (${dersler[d].donem} dönem)`);
  dersler[d].konular.slice(0, 8).forEach(k => console.log(`  ${String(k.agirlik).padStart(6)} puan/dönem · ${String(k.donem).padStart(2)} dönem · test ${k.test_soru} soru · klasik okunan ${k.klasik_puanli} / eşit ${k.klasik_esit} · ${k.konu}`));
}
if (!KURU) {
  const hedef = path.join(KOK, 'veri', 'sinav', 'smmm-konu-puan.json');
  let ayni = false; try { const a = jsonOku(hedef); delete a.uretim; const b = { ...cikti }; delete b.uretim; ayni = JSON.stringify(a) === JSON.stringify(b); } catch (e) {}
  if (!ayni) { fs.writeFileSync(hedef, JSON.stringify(cikti, null, 1) + '\n', 'utf8'); console.log('veri/sinav/smmm-konu-puan.json yazıldı'); }
}
