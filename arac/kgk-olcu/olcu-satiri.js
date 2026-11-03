// KGK SORU BAŞI ÖLÇÜ SATIRI (sözleşme B31, 03.11; bitirme standardı §7 "Teslim raporu"nun KGK eşi). 0 USD.
// Her soru için tek satır: kimlik · konu · kalıp (KGK ayırıcısı) · konuda gerçek mi · modülde gerçek mi · kök/hedef/tavan · şık türü ·
// iki okuyucunun cevabı (r1/r2 benim_cevabim) · anahtar · kaynak sayısı · KGK ek kapı · yıl · tek harf ad · şık boy oranı → DURUM.
// Satırı eksik ya da DURUM≠GEÇER soru teslim edilmez; ölçü aracı çalışmazsa "ÖLÇÜLMEDİ" (geçer sayılmaz).
// 🚫 GÖRMEZ: dayanak cümlesinin ambarda AYNEN bulunduğu (kaynak adı sayılır, cümle aranmaz — okuyucu r1–r5 bakar) · çeldirici gücü.
// node olcu-satiri.js <fabrika> <dalga> <grup> [--yaz]   → olcu/<dalga>-<grup>.tsv
'use strict';
const fs = require('fs'), path = require('path'), cp = require('child_process');
const IS = __dirname, oku = f => JSON.parse(fs.readFileSync(f, 'utf8').replace(/^﻿/, ''));
const { ayir } = require('./kalip/kgk-kalip-ayirici.js'); const { olc, hedef } = require('./konu-profil.js');
const katla = s => String(s).replace(/İ/g, 'I').replace(/ı/g, 'i').toLowerCase().replace(/i̇/g, 'i').replace(/ş/g, 's').replace(/ğ/g, 'g').replace(/ü/g, 'u').replace(/ö/g, 'o').replace(/ç/g, 'c').replace(/[âà]/g, 'a').replace(/î/g, 'i').replace(/û/g, 'u').replace(/['’]/g, '');
const kk = s => katla(s).replace(/[^a-z0-9 ]/g, ' ').replace(/\s+/g, ' ').trim();
// gerçek p90 (plan-kur.js DERS ile AYNI; kalip/tavan-olc.js 03.11)
const TAVAN = { 'a) Türkiye Muhasebe Standartları': 707, 'b) Türkiye Denetim Standartları': 653, 'c) Finansal Yönetim': 366, 'c) Kurumsal Yönetim': 341, 'ç) Sermaye Piyasası Mevzuatı': 428, 'd) Bankacılık Mevzuatı': 501, 'e) Sigortacılık ve Özel Emeklilik': 519, 'f) Sürdürülebilirlik Raporlaması': 995, 'g) Sürdürülebilirlik Denetimi': 780 };
function satirlar(fab, dalga, grup) {
  const P = oku(path.join(IS, 'konu-profil-gercek.json')).konu, es = oku(path.join(IS, 'kgk-konu-es.json')).esleme;
  const MK = {}; for (const p of Object.values(P)) for (const x of p.sorular) if (x.kalip) (MK[p.modul] = MK[p.modul] || new Set()).add(x.kalip);
  const out = [];
  for (const z of ['kolay', 'zor', 'cokzor']) {
    const f = path.join(fab, `hazir-kgk-${dalga}-${grup}-${z}.json`); if (!fs.existsSync(f)) continue; const A = oku(f);
    const r = n => { const p = path.join(IS, 'okuma', `${dalga}-${grup}-${z}-${n}.json`); try { return oku(p); } catch (e) { return null; } };
    const r1 = r('r1'), r2 = r('r2');
    let ek = ''; try { ek = cp.spawnSync(process.execPath, [path.join(fab, '..', '..', 'arac', 'kgk-ek-kapi.js'), '--dosya', f], { encoding: 'utf8' }).stdout || ''; } catch (e) { ek = 'ÖLÇÜLMEDİ'; }
    A.forEach((q, i) => {
      const e = es[kk(q.konu)] || P[q.konu] && { k: q.konu, d: P[q.konu].modul }; const k = e ? e.k : q.konu, md = e ? e.d : '?';
      const siklar = Object.values(q.siklar || {}), o = olc(String(q.soru || ''), siklar), kal = ayir(String(q.soru || ''), siklar);
      const konuKal = new Set((P[k] ? P[k].sorular : []).map(x => x.kalip).filter(Boolean));
      const h = hedef(k, P); const tavan = TAVAN[md] || 784;
      const sikTur = /yalnız i\b|i ve ii|i, ii/i.test(siklar.join(' ')) ? 'öncül' : o.hsp ? 'sayı' : siklar.some(s => /\b[1-7]\d\d\s+[A-ZÇĞİÖŞÜ]/.test(s)) ? 'kayıt' : 'sözel';
      // okuma dosyası sırası, sonradan çıkarılan sorular yüzünden kayabilir → sıra + KONU birlikte tutmalı; yoksa "—" (ÖLÇÜLMEDİ)
      const cev = (R) => { const x = R && (R.find(y => +y.sira === i && y.konu === q.konu) || R.find(y => y.konu === q.konu && String(y.dogru_anahtar || '').toUpperCase() === String(q.dogru || '').toUpperCase())); return x && x.benim_cevabim ? String(x.benim_cevabim).toUpperCase() : '—'; };
      const ekSatir = (ek.match(new RegExp(`(KGK-[A-Z0-9]+)[^\\n]*\\b${z}\\[?${i}\\]?`, 'g')) || []).map(s => s.split(' ')[0]).join(',');
      const kusur = [];
      if (o.uz > tavan) kusur.push('kök>tavan'); if (!(MK[md] || new Set()).has(kal)) kusur.push('ders dışı kalıp'); if (o.tek) kusur.push('tek harf ad');
      if (/KGK-(CZ|DC|G2|MK)/.test(ekSatir)) kusur.push(ekSatir);
      const c1 = cev(r1), c2 = cev(r2), dogru = String(q.dogru || '').toUpperCase();
      if (c1 !== '—' && c1 !== dogru) kusur.push('okuyucu1≠anahtar'); if (c2 !== '—' && c2 !== dogru) kusur.push('okuyucu2≠anahtar');
      const olcülmedi = c1 === '—' && c2 === '—';
      out.push({ kimlik: `${grup}-${z}[${i}]`, konu: k, kalip: kal, konuda: konuKal.size ? (konuKal.has(kal) ? 'evet' : 'HAYIR') : 'konu<3', modulde: (MK[md] || new Set()).has(kal) ? 'evet' : 'HAYIR',
        kok: o.uz, hedef: h ? h.kok : '-', tavan, sik: sikTur, oku1: c1, oku2: c2, anahtar: dogru, kaynak: (q.kaynak_adlar || []).length, ekKapi: ekSatir || 'temiz', yil: o.yil ? 'VAR' : '-', tekHarf: o.tek ? 'VAR' : '-', sikOran: o.sor,
        durum: kusur.length ? 'KUSUR: ' + kusur.join(' · ') : olcülmedi ? 'ÖLÇÜLMEDİ: iki okuyucu cevabı yok' : 'GEÇER' });
    });
  }
  return out;
}
module.exports = { satirlar };
if (require.main === module) {
  const [fab, dalga, grup] = process.argv.slice(2); const L = satirlar(fab, dalga, grup);
  if (!L.length) { console.log(`ÖLÇÜLMEDİ: ${dalga}-${grup} hazır dosya yok`); process.exit(1); }
  const bas = Object.keys(L[0]); const tsv = [bas.join('\t'), ...L.map(x => bas.map(b => x[b]).join('\t'))].join('\n');
  if (process.argv.includes('--yaz')) { fs.mkdirSync(path.join(IS, 'olcu'), { recursive: true }); fs.writeFileSync(path.join(IS, 'olcu', `${dalga}-${grup}.tsv`), tsv + '\n'); }
  console.log(tsv); const k = L.filter(x => x.durum !== 'GEÇER').length;
  console.log(k ? `⛔ ÖLÇÜ SATIRI ${grup}: ${k}/${L.length} soru KUSUR` : `✓ ÖLÇÜ SATIRI ${grup}: ${L.length}/${L.length} GEÇER`); process.exitCode = k ? 1 : 0;
}
