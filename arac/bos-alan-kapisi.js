#!/usr/bin/env node
// ============================================================================
//  KAPI-BOS — BOŞ AÇIKLAMA + VERİ KALINTISI KAPISI (30.09.2026, Cem "1.2.3 üçünü de yap")
//  Öğrenciye görünen soru alanlarında üretim kalıntısını yakalar:
//    BOS-ACIK   : bir şıkkın açıklaması yok / boş / yalnız "-" (doğru şık dahil — ekranda "undefined" çıkıyordu)
//    BOS-KALINTI: görünen alanın DEĞERİ yer tutucu: undefined · null · skip · placeholder · TODO · dummy · remove · yanilgi · x
//                 ya da metin içinde "placeholder"/"undefined"/"lorem" geçiyor
//    BOS-ANAHTAR: şıklarda ya da açıklamada A–E dışı / bozuk anahtar ("D2", "F_placeholder", "A_yanlis", "dummy", "B_teshis_note")
//  ÖLÇÜLDÜ (30.09 SGS onarım okumaları, elle): "F_placeholder) yok" şıkkı, boş "D2" şıkkı, hap "placeholder", teşhis değeri "yanilgi"/"skip",
//    doğru şıkta açıklama yok ("undefined"), aciklama.A_yanlis, dummy:"remove" — hepsi yayındaki sorularda.
//  🚫 GÖRMEZ: dolu ama anlamsız metin ("…yasak bu") · Türkçe harfsiz yazım · başka şıkkı anlatan açıklama (KAPI-AS ayrı) ·
//     tablo hücrelerindeki "-" (meşru boş hücre; tablolar taranmaz) · model alanları (hakem/kör…).
//  Kullanım: node arac/bos-alan-kapisi.js --sinav [--mutasyon] | --banka <sgs|smmm|kgk> [cikti.json]
// ============================================================================
'use strict';
const fs = require('fs'), path = require('path');
const KOK = path.resolve(__dirname, '..');
const MUT = process.env.BOS_MUTASYON || '';
const HARF = /^[A-E]$/;
// öğrenciye görünen, metin taşıyan alanlar (tablolar ve model alanları hariç)
const GORUNEN = ['soru', 'siklar', 'aciklama', 'sade', 'teshis', 'hap', 'dayanak', 'adimlar', 'konu_giris', 'celdirici_yol', 'notlandirici', 'sinav_taktigi', 'teori_ikiz'];
const YER_TUTUCU = /^\s*(undefined|null|skip|placeholder|todo|dummy|remove|yanilgi|x|n\/a|tbd)\s*$/i;
const ICINDE = /\b(placeholder|undefined|lorem ipsum)\b/i;

function gez(v, yol, out) {
  if (v == null) return out;
  if (typeof v === 'string') { out.push([yol, v]); return out; }
  if (Array.isArray(v)) { v.forEach((x, i) => gez(x, yol + '[' + i + ']', out)); return out; }
  if (typeof v === 'object') { for (const [k, x] of Object.entries(v)) { if (/tablo/i.test(k)) continue; gez(x, yol + '.' + k, out); } }
  return out;
}

function kusurlar(k) {
  const out = []; if (!k || typeof k !== 'object') return out;
  const ekle = (tur, alan, not) => out.push({ tur, alan, not });
  const siklar = (k.siklar && typeof k.siklar === 'object') ? k.siklar : {};
  // BOS-ANAHTAR: şık ve açıklama anahtarları
  if (MUT !== 'anahtar') {
    for (const h of Object.keys(siklar)) if (!HARF.test(h)) ekle('BOS-ANAHTAR', 'siklar.' + h, 'şıkta A–E dışı anahtar');
    for (const h of Object.keys(siklar)) if (HARF.test(h) && !String(siklar[h] == null ? '' : siklar[h]).trim()) ekle('BOS-ANAHTAR', 'siklar.' + h, 'boş şık metni');
    if (k.aciklama && typeof k.aciklama === 'object') for (const h of Object.keys(k.aciklama)) if (!HARF.test(h)) ekle('BOS-ANAHTAR', 'aciklama.' + h, 'açıklamada A–E dışı anahtar');
    for (const ust of ['dummy', 'B_teshis_note']) if (ust in k) ekle('BOS-ANAHTAR', ust, 'kalıntı anahtar');
  }
  // BOS-ACIK: her geçerli şıkkın açıklaması dolu olmalı
  if (k.aciklama && typeof k.aciklama === 'object' && MUT !== 'acik') {
    for (const h of Object.keys(siklar).filter(x => HARF.test(x))) {
      const v = k.aciklama[h]; const t = v == null ? '' : (typeof v === 'string' ? v : JSON.stringify(v));
      if (!t.trim() || /^\s*[-–—.]*\s*$/.test(t)) ekle('BOS-ACIK', 'aciklama.' + h, h === k.dogru ? 'DOĞRU şıkkın açıklaması yok' : 'şık açıklaması yok');
    }
  }
  // 01.10 (kapanış onarımı ölçtü: borclar-kolay-r4-bulut/kp-02): alan VAR ama boş dize — sayfada boş kutu çıkar
  if (MUT !== 'bos-dize') for (const a of ['hap', 'dayanak', 'notlandirici', 'sinav_taktigi']) if (a in k && typeof k[a] === 'string' && !k[a].trim()) ekle('BOS-KALINTI', a, 'alan boş');
  // BOS-KALINTI: görünen alanlarda yer tutucu değer
  if (MUT !== 'kalinti') {
    for (const alan of GORUNEN) for (const [yol, t] of gez(k[alan], alan, [])) {
      // 30.09 banka: matematikte şık metni "x" meşru (değişken) → şıklarda "x" kalıntı sayılmaz
      if (/^\s*x\s*$/i.test(t) && /(^|\.)siklar\./.test(yol) && MUT !== 'x-sik') continue;
      if (YER_TUTUCU.test(t) && !(MUT === 'x-yok' && /^\s*x\s*$/i.test(t))) ekle('BOS-KALINTI', yol, 'yer tutucu değer "' + t.trim().slice(0, 20) + '"');
      else if (MUT !== 'icinde' && ICINDE.test(t)) ekle('BOS-KALINTI', yol, 'metinde yer tutucu sözcük');
    }
  }
  return out;
}

function banka(sinav, cikti) {
  const d = path.join(KOK, 'veri', 'sinav', 'kaydir-secim'); const ids = new Set();
  for (const f of fs.readdirSync(d).filter(f => new RegExp('^(yayin|vitrin)-' + sinav + '-').test(f))) for (const r of JSON.parse(fs.readFileSync(path.join(d, f), 'utf8').replace(/^﻿/, ''))) if (r.etiket && r.id) ids.add(r.etiket + '/' + r.id);
  const P = {}; let okunan = 0; const sonuc = [];
  for (const id of ids) {
    const [e, kp] = id.split('/'); const pf = path.join(KOK, 'veri', 'fabrika', 'kalip-parti-' + e + '.json');
    if (!(e in P)) P[e] = fs.existsSync(pf) ? JSON.parse(fs.readFileSync(pf, 'utf8').replace(/^﻿/, '')) : null;
    const k = P[e] && P[e][kp]; if (!k) continue; okunan++;
    const b = kusurlar(k); if (b.length) sonuc.push({ anahtar: id, kusurlar: b });
  }
  const tur = {}; for (const s of sonuc) for (const b of s.kusurlar) tur[b.tur] = (tur[b.tur] || 0) + 1;
  console.log(`KAPI-BOS banka (${sinav}): yayında ${ids.size} · okunan ${okunan} · bulgulu soru ${sonuc.length} · ${JSON.stringify(tur)}`);
  if (cikti) fs.writeFileSync(cikti, JSON.stringify(sonuc, null, 1));
}

function sinav() {
  const T = () => ({ soru: 'Kök?', dogru: 'C', siklar: { A: 'a', B: 'b', C: 'c', D: 'd', E: 'e' },
    aciklama: { A: 'Tuzak A.', B: 'Tuzak B.', C: 'Ne soruluyor: … Doğrusu: C.', D: 'Tuzak D.', E: 'Tuzak E.' }, hap: 'Kısa kural.',
    cozum_tablo: { satirlar: [['Kalem', '-']] }, hakem: { gerekce: 'placeholder' } });
  const V = [
    ['temiz soru → bulgu yok', k => k, null],
    ['doğru şıkta açıklama yok', k => { delete k.aciklama.C; return k; }, 'BOS-ACIK'],
    ['yanlış şık açıklaması "-"', k => { k.aciklama.D = ' - '; return k; }, 'BOS-ACIK'],
    ['hap "placeholder"', k => { k.hap = 'placeholder'; return k; }, 'BOS-KALINTI'],
    ['teşhis değeri "yanilgi"', k => { k.teshis = 'yanilgi'; return k; }, 'BOS-KALINTI'],
    ['dayanak "x"', k => { k.dayanak = 'x'; return k; }, 'BOS-KALINTI'],
    ['metin içinde "undefined"', k => { k.sade = { siklar: { A: 'Bu şık undefined döner.' } }; return k; }, 'BOS-KALINTI'],
    ['şıkta "F_placeholder"', k => { k.siklar.F_placeholder = 'yok'; return k; }, 'BOS-ANAHTAR'],
    ['boş "D2" şıkkı', k => { k.siklar.D2 = ''; return k; }, 'BOS-ANAHTAR'],
    ['aciklama.A_yanlis', k => { k.aciklama.A_yanlis = 'x'; return k; }, 'BOS-ANAHTAR'],
    ['dummy:"remove"', k => { k.dummy = 'remove'; return k; }, 'BOS-ANAHTAR'],
    ['tablo hücresi "-" meşru → temiz', k => k, null],
    ['model alanındaki "placeholder" taranmaz', k => k, null],
    ['hap boş dize → KALINTI', k => { k.hap = '  '; return k; }, 'BOS-KALINTI'],
    ['matematik şıkkı "x" meşru → temiz', k => { k.siklar.B = 'x'; k.teori_ikiz = { siklar: { B: 'x' } }; return k; }, null],
    ['"x" sözcük içinde meşru ("x ve y değişkeni") → temiz', k => { k.soru = 'x ve y değişkenleri için çözünüz.'; return k; }, null],
  ];
  let ok = 0;
  for (const [ad, f, bek] of V) { const b = kusurlar(f(T())); const g = b.length ? b[0].tur : null; const t = g === bek; if (t) ok++; console.log((t ? '  ✓ ' : '  ✗ ') + ad + (t ? '' : ' → ' + JSON.stringify(b))); }
  console.log((ok === V.length ? 'KAPI-BOS ÖZ-SINAVI YEŞİL' : 'KAPI-BOS ÖZ-SINAVI KIRMIZI') + ` (${ok}/${V.length})` + (MUT ? ' · BOS_MUTASYON=' + MUT : ''));
  return ok === V.length;
}

module.exports = { kusurlar };
if (require.main === module) {
  const [a, b, c] = process.argv.slice(2);
  if (a === '--sinav') {
    if (process.argv.includes('--mutasyon')) {
      const { spawnSync } = require('child_process'); const ler = ['anahtar', 'acik', 'kalinti', 'icinde', 'x-yok', 'x-sik', 'bos-dize']; let tutan = 0;
      for (const m of ler) { const r = spawnSync(process.execPath, [__filename, '--sinav'], { env: { ...process.env, BOS_MUTASYON: m }, encoding: 'utf8' }); const kr = r.status !== 0; if (kr) tutan++; console.log('  mutasyon ' + m + (kr ? ' KIRMIZI (doğru)' : ' YEŞİL (SINAV KÖR!)')); }
      console.log('MUTASYON: ' + tutan + '/' + ler.length + ' → KIRMIZI'); process.exit(tutan === ler.length ? 0 : 1);
    }
    process.exit(sinav() ? 0 : 1);
  } else if (a === '--banka') banka(b || 'sgs', c);
  else { console.log('--sinav [--mutasyon] | --banka <sgs|smmm|kgk> [cikti.json]'); process.exit(2); }
}
