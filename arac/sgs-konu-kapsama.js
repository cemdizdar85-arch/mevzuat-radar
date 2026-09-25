#!/usr/bin/env node
/*
================================================================================
  SGS KONU KAPSAMA — "ders · konu · son 10 yılda kaç soru çıktı · sitede kaç sorumuz var"
  25.09.2026 · bedel 0 (model yok, ağ yok — yalnız depodaki dosyalar)

  Cem 25.09: "konu konu sınavda çıkan ... 10 yılda kaç çıkan bizim kaç soru bastığımız
  bunların listesini at, sonra ne eksiğimiz var". İlk liste (konu adıyla birebir eşleşme)
  YANLIŞTI: çıkmış arşivi (veri/sgs-analiz.json) aynı konuyu çok farklı adlarla etiketliyor
  ("sözleşmenin kurulması" / "sözleşme kuruluşu"), sitedeki soruların konu adı da bu
  etiketlerden biri. Birebir eşleşme "hiç yok" sayısını 864'e şişiriyordu.

  ÇÖZÜM: veri/sinav/sgs-konu-es.json — her arşiv etiketini bir KONU KÜMESİNE ve GERÇEK DERSE
  bağlar (arşiv ders etiketi kaba: "Muhasebe", "Hukuk", "Genel Kultur-Genel Yetenek"; ayrıca
  yanlış derse düşmüş etiketler var — FM altında "halkçılık" gibi). Sözlük 25.09'da 1.678
  "hiç yok" etiketi okunarak kuruldu; her etiket EN İYİ TEK site konusuna bağlandı (site
  konuları birbirine bağlanmaz → zincirleme birleşme yok). GM örneklemi 82 satır / 1 hata.

  GİRDİ : veri/sgs-analiz.json · kaydir/sgs/*.html (sitedeki soru = konu alanı) · veri/sinav/sgs-konu-es.json
  ÇIKTI : veri/fabrika/sgs-konu-kapsama.csv (Excel, ; ayraçlı) + .json · veri/sinav/SGS-KAPSAMA.md (özet)

  DURUM : VAR (sitede ≥ Kat × çıkan) · AZ · HİÇ YOK · 10 YILDIR ÇIKMIYOR · ÇIKMIŞTA YOK (bizim konu)
          Türkçe (kasa modu sayfası): konu havuzun seçim dosyasından okunur (25.09)

  🚫 GÖRMEZ:
    · Sözlükte olmayan yeni arşiv etiketi (yeni sınav yutulunca) kendi kümesi olur, dersi '?' —
      özet satırında "sözlükte yok" sayısı yazılır; o etiketler okunup sözlüğe eklenmeli.
    · Sitedeki soru sayısı SAYFADAN okunur (paket_soru değil); kasa sayımıyla ±5 fark ölçüldü (25.09).
    · Kümeleme doğruluğu örneklemle ölçüldü, tamamı okunmadı.

  KULLANIM
    node arac/sgs-konu-kapsama.js            (Kat 1 — sitedeki soru ≥ son 10 yılda çıkan soru)
    node arac/sgs-konu-kapsama.js --kat 2
    node arac/sgs-konu-kapsama.js --yil 2016  (pencere başlangıç yılı)
================================================================================
*/
'use strict';
const fs = require('fs'), path = require('path');
const KOK = path.resolve(__dirname, '..');
const arg = (ad, vars) => { const i = process.argv.indexOf(ad); return i > 0 ? process.argv[i + 1] : vars; };
const KAT = Number(arg('--kat', 1)), YIL = Number(arg('--yil', 2016));

function coz(s) { return String(s).replace(/\\u([0-9a-fA-F]{4})/g, (m, h) => String.fromCharCode(parseInt(h, 16))); }
function katla(s) {
  let t = coz(s).replace(/İ/g, 'I').replace(/ı/g, 'i').toLowerCase();
  t = t.replace(/i̇/g, 'i').replace(/ş/g, 's').replace(/ğ/g, 'g').replace(/ü/g, 'u').replace(/ö/g, 'o').replace(/ç/g, 'c')
    .replace(/[âà]/g, 'a').replace(/î/g, 'i').replace(/û/g, 'u').replace(/['’]/g, '');
  return t.replace(/[^a-z0-9 ]/g, ' ').replace(/\s+/g, ' ').trim();
}
const oku = p => JSON.parse(fs.readFileSync(path.join(KOK, p), 'utf8').replace(/^﻿/, ''));

const es = oku('veri/sinav/sgs-konu-es.json').esleme;
const an = oku('veri/sgs-analiz.json');

// 1) çıkmış: etiket → sayımlar
const cik = new Map(); let pencere = 0;
for (const d of an.donemler) {
  const yil = +String(d.donem).split('/')[0], dk = +String(d.donem).replace('/', '');
  if (yil >= YIL) pencere++;
  for (const [k, v] of Object.entries(d.konuSayim)) {
    const lab = k.replace(/^[^|]*\|/, ''), a = katla(lab); if (!a) continue;
    if (!cik.has(a)) cik.set(a, { a, ad: lab, son: 0, tum: 0, donem: new Set(), sonD: '', sonDk: 0, site: 0 });
    const c = cik.get(a); c.tum += +v;
    if (yil >= YIL) { c.son += +v; c.donem.add(d.donem); }
    if (dk > c.sonDk) { c.sonDk = dk; c.sonD = d.donem; }
  }
}
// 2) site: sayfadaki her sorunun konu alanı
const site = new Map(); let siteTop = 0;
const dizin = path.join(KOK, 'kaydir', 'sgs');
// 25.09: özel sayfalar (muhur-10 vitrin, kapituru deneme, index) ders sayfalarından seçilmiş sorudur → sayılırsa soru İKİ kez sayılır
//   (ölçüldü: muhur-10'daki 10 soru ders sayfalarında da var).
for (const f of fs.readdirSync(dizin).filter(f => f.endsWith('.html') && !/^(index|muhur-|kapituru-)/.test(f))) {
  const h = fs.readFileSync(path.join(dizin, f), 'utf8');
  const ds = [...h.matchAll(/"ders":"([^"]*)"/g)].map(m => coz(m[1]));
  if (!ds.length) {
    // 25.09: kasa modundaki sayfa (Türkçe) soru taşımaz → konu, havuzun seçim dosyasından (veri/sinav/kaydir-secim/yayin-sgs-<sayfa>.json).
    //   Ölçüldü: yayin-sgs-turkce.json 127 kayıt = kasadaki Türkçe 127. 🚫 GÖRMEZ: seçimden sonra sayfa basıcıda (sgs-650-bas) düşen soruyu.
    const sec = path.join(KOK, 'veri', 'sinav', 'kaydir-secim', 'yayin-sgs-' + f.replace(/\.html$/, '.json'));
    if (!fs.existsSync(sec)) continue;
    for (const r of JSON.parse(fs.readFileSync(sec, 'utf8').replace(/^﻿/, ''))) {
      siteTop++; const k = r.ders + '|' + katla(r.konu); if (!site.has(k)) site.set(k, { ad: r.konu, n: 0 }); site.get(k).n++;
    }
    continue;
  }
  const say = {}; ds.forEach(x => say[x] = (say[x] || 0) + 1);
  const dA = Object.entries(say).sort((a, b) => b[1] - a[1])[0][0];
  for (const m of h.matchAll(/"konu":"([^"]*)"/g)) { siteTop++; const k = dA + '|' + katla(m[1]); if (!site.has(k)) site.set(k, { ad: coz(m[1]), n: 0 }); site.get(k).n++; }
}
const siteDisi = [];
for (const [k, v] of site) { const a = k.split('|')[1]; if (cik.has(a)) cik.get(a).site += v.n; else siteDisi.push([k, v]); }

// 3) kümele
let sozlukteYok = 0;
const kume = new Map();
for (const c of cik.values()) {
  const e = es[c.a]; if (!e) { sozlukteYok++; if (process.env.SGS_KAPSAMA_HATA) console.error("sozlukte yok:", c.ad); }
  const kk = e ? e.k : c.a, ders = e ? e.d : '?';
  if (!kume.has(kk)) kume.set(kk, { uye: [], dersOy: {} });
  const K = kume.get(kk); K.uye.push(c); K.dersOy[ders] = (K.dersOy[ders] || 0) + 1;
}
const sat = [];
for (const [kk, K] of kume) {
  const L = K.uye;
  const son = L.reduce((s, c) => s + c.son, 0), tum = L.reduce((s, c) => s + c.tum, 0), siteN = L.reduce((s, c) => s + c.site, 0);
  const don = new Set(); L.forEach(c => c.donem.forEach(x => don.add(x)));
  const sonD = L.map(c => c.sonD).sort((a, b) => +b.replace('/', '') - +a.replace('/', ''))[0];
  const ders = Object.entries(K.dersOy).sort((a, b) => b[1] - a[1])[0][0];
  const bas = L.find(c => c.a === kk) || [...L].sort((a, b) => b.site - a.site || b.son - a.son)[0];
  let durum;
  if (son === 0) durum = tum > 0 ? '10 YILDIR ÇIKMIYOR' : '—';
  else if (siteN === 0) durum = 'HİÇ YOK';
  else if (siteN < KAT * son) durum = 'AZ';
  else durum = 'VAR';
  const eksik = (durum === 'AZ' || durum === 'HİÇ YOK') ? Math.ceil(KAT * son) - siteN : 0;
  sat.push({ ders, konu: bas.ad, diger: L.filter(c => c !== bas).map(c => c.ad).join(' | '), son, don: don.size, tum, sonD, site: siteN, durum, eksik });
}
for (const [k, v] of siteDisi) sat.push({ ders: k.split('|')[0], konu: v.ad, diger: '', son: 0, don: 0, tum: 0, sonD: '-', site: v.n, durum: 'ÇIKMIŞTA YOK (bizim konu)', eksik: 0 });
sat.sort((a, b) => a.ders.localeCompare(b.ders, 'tr') || b.son - a.son || b.don - a.don || b.site - a.site);

// 4) çıktılar
const q = s => '"' + String(s).replace(/"/g, '""') + '"';
const bas = ['Ders', 'Konu', 'Aynı konunun arşivdeki diğer adları', `Son 10 yılda çıkan soru (${YIL}+, ${pencere} dönem)`, 'Kaç dönemde çıktı', 'Tüm zamanlar', 'Son çıktığı dönem', 'Sitede bizim soru', 'Durum', `Hedefe (${KAT} kat) eksik soru`];
const fab = path.join(KOK, 'veri', 'fabrika'); fs.mkdirSync(fab, { recursive: true });
fs.writeFileSync(path.join(fab, 'sgs-konu-kapsama.csv'), '﻿' + [bas.map(q).join(';'), ...sat.map(r => [r.ders, r.konu, r.diger, r.son, r.don, r.tum, r.sonD, r.site, r.durum, r.eksik].map(q).join(';'))].join('\r\n'));
fs.writeFileSync(path.join(fab, 'sgs-konu-kapsama.json'), JSON.stringify({ kat: KAT, yil: YIL, pencere, satirlar: sat }));

const D = {};
for (const r of sat) {
  const d = D[r.ders] || (D[r.ders] = { k: 0, son: 0, site: 0, VAR: 0, AZ: 0, Y2: 0, Y1: 0, e3: 0 });
  d.site += r.site;
  if (r.son > 0) { d.k++; d.son += r.son; if (r.durum === 'VAR') d.VAR++; if (r.durum === 'AZ') d.AZ++; if (r.durum === 'HİÇ YOK') { r.don >= 2 ? d.Y2++ : d.Y1++; } if (r.don >= 3) d.e3 += r.eksik; }
}
const sayi = n => Number(n).toLocaleString('tr-TR');
const md = [];
md.push('# SGS — KONU KAPSAMA', '');
md.push(`> Türetilmiştir (\`arac/sgs-konu-kapsama.js\`), **elle düzenlenmez**. Hedef: sitede **${KAT} kat** (son 10 yılda çıkan soru sayısı kadar × ${KAT}). Pencere: ${YIL}+ (${pencere} dönem).`);
md.push('> Eşleme sözlüğü: `veri/sinav/sgs-konu-es.json` (aynı konunun farklı arşiv adları tek kümede). Tam liste: `veri/fabrika/sgs-konu-kapsama.csv`.', '');
md.push(`Sitede sayfadan okunan soru: **${sayi(siteTop)}** (kasa modundaki sayfa seçim dosyasından) · konu kümesi: ${sayi(kume.size)} · sözlükte olmayan arşiv etiketi: **${sozlukteYok}**`, '');
md.push('| Ders | Çıkmış konu | Son 10 yılda çıkan soru | Sınav başı | Sitede | VAR | AZ | Hiç yok (2+ dönem) | Hiç yok (1 dönem) | 3+ dönem konularda hedefe eksik |', '|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|');
for (const [k, d] of Object.entries(D).sort((a, b) => b[1].son - a[1].son)) md.push(`| ${k} | ${d.k} | ${d.son} | ${(d.son / pencere).toFixed(1).replace('.', ',')} | ${d.site} | ${d.VAR} | ${d.AZ} | ${d.Y2} | ${d.Y1} | ${d.e3} |`);
const trsiz = r => r.ders !== '?';
const oz = f => { const x = sat.filter(r => trsiz(r) && r.eksik > 0 && f(r)); return `${x.length} konu / ${x.reduce((a, r) => a + r.eksik, 0)} soru`; };
md.push('', '## Hedefe eksik', '', `- 3+ dönem çıkmış: **${oz(r => r.don >= 3)}**`, `- 2 dönem çıkmış: ${oz(r => r.don === 2)}`, `- 1 dönem çıkmış: ${oz(r => r.don < 2)}`, '');
md.push('## Birden çok dönem çıkmış, sitede hiç sorusu olmayan', '', '| Ders | Konu | Çıkan / dönem | Son |', '|---|---|---:|---|');
for (const r of sat.filter(r => trsiz(r) && r.durum === 'HİÇ YOK' && r.don >= 2).sort((a, b) => b.don - a.don || b.son - a.son)) md.push(`| ${r.ders} | ${r.konu} | ${r.son} / ${r.don} | ${r.sonD} |`);
md.push('', '## 3+ dönem çıkmış, en büyük 30 eksik', '', '| Ders | Konu | Çıkan / dönem | Sitede | Eksik |', '|---|---|---:|---:|---:|');
for (const r of sat.filter(r => trsiz(r) && r.durum === 'AZ' && r.don >= 3).sort((a, b) => b.eksik - a.eksik).slice(0, 30)) md.push(`| ${r.ders} | ${r.konu} | ${r.son} / ${r.don} | ${r.site} | ${r.eksik} |`);
fs.writeFileSync(path.join(KOK, 'veri', 'sinav', 'SGS-KAPSAMA.md'), md.join('\n') + '\n');
console.log(`SGS kapsama: kume ${kume.size} · site ${siteTop} · sozlukte yok ${sozlukteYok} · 3+ donem eksik ${oz(r => r.don >= 3)} (kat ${KAT})`);
