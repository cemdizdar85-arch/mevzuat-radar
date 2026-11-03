// KGK konu × kalıp tablosu (B30/B31 adım 3, 03.11). Gerçek = konu-profil-gercek.json (içerik bağı + ELLE kalıp harfi);
// sitede = paket_soru (kasa-cek.js çıktısı) + KGK ayırıcısı (kgk-kalip-ayirici.js; elle etikete uyumu ayrıca ölçülür).
// Sütunlar: gerçek n / kalıp dağılımı · sitede n / kalıp dağılımı · EKSİK KALIP (gerçekte konuda ≥2 kez, sitede 0) ·
// TEK TİP (sitede ≥5 soru ve tek kalıp >%60 — B30) · DERS DIŞI KALIP (modülün gerçek sınavında hiç görülmeyen kalıp sitede).
// Soru metni ÇIKTIYA GİRMEZ. node konu-kalip-tablo.js <kasa.json> <ciktiMd> [<ozetJson>]
const fs = require('fs'), path = require('path'); const { ayir } = require('./kgk-kalip-ayirici.js');
const oku = f => JSON.parse(fs.readFileSync(f, 'utf8').replace(/^﻿/, ''));
const katla = s => String(s).replace(/İ/g, 'I').replace(/ı/g, 'i').toLowerCase().replace(/i̇/g, 'i').replace(/ş/g, 's').replace(/ğ/g, 'g').replace(/ü/g, 'u').replace(/ö/g, 'o').replace(/ç/g, 'c').replace(/[âà]/g, 'a').replace(/î/g, 'i').replace(/û/g, 'u').replace(/['’]/g, '');
const kk = s => katla(s).replace(/[^a-z0-9 ]/g, ' ').replace(/\s+/g, ' ').trim();
const IS = path.join(__dirname, '..'); const P = oku(path.join(IS, 'konu-profil-gercek.json')).konu, es = oku(path.join(IS, 'kgk-konu-es.json')).esleme;
const [kasaF, mdF, ozetF] = process.argv.slice(2);
const SAYFA = { 'muhasebe-standartlari': 'a) Türkiye Muhasebe Standartları', 'denetim-standartlari': 'b) Türkiye Denetim Standartları', 'finansal-yonetim': 'c) Finansal Yönetim', 'kurumsal-yonetim': 'c) Kurumsal Yönetim', 'sermaye-piyasasi': 'ç) Sermaye Piyasası Mevzuatı', 'bankacilik': 'd) Bankacılık Mevzuatı', 'sigortacilik': 'e) Sigortacılık ve Özel Emeklilik', 'surdurulebilirlik-raporlamasi': 'f) Sürdürülebilirlik Raporlaması', 'surdurulebilirlik-denetimi': 'g) Sürdürülebilirlik Denetimi' };
const dag = L => { const c = {}; for (const h of L) if (h) c[h] = (c[h] || 0) + 1; return c; };
const yaz = c => Object.entries(c).sort((a, b) => b[1] - a[1]).map(([h, n]) => `${h}${n}`).join(' ') || '—';
// gerçek: konu → kalıplar; modül → kalıp kümesi
const G = {}, MK = {}; for (const [k, p] of Object.entries(P)) { const L = p.sorular.map(x => x.kalip).filter(Boolean); G[k] = { modul: p.modul, n: p.sorular.length, kalip: dag(L) }; for (const h of L) (MK[p.modul] = MK[p.modul] || {})[h] = ((MK[p.modul] || {})[h] || 0) + 1; }
// sitede
const S = {}; const sitede = oku(kasaF);
for (const r of sitede) { const v = r.veri || {}; const e = es[kk(v.konu || '')]; const k = e ? e.k : '(sözlükte yok) ' + (v.konu || ''); const md = SAYFA[(r.sayfa.match(/kgk\/(.*)\.html/) || [])[1]] || '?';
  const s = (S[k] = S[k] || { modul: md, n: 0, kalip: {} }); s.n++; const h = ayir(String(v.soru || ''), Object.values(v.siklar || {})); s.kalip[h] = (s.kalip[h] || 0) + 1; }
const satir = [], ozet = {};
for (const k of new Set([...Object.keys(G), ...Object.keys(S)])) {
  const g = G[k] || { n: 0, kalip: {}, modul: (S[k] || {}).modul }, s = S[k] || { n: 0, kalip: {} }; const md = g.modul || s.modul;
  const eksik = Object.entries(g.kalip).filter(([h, n]) => n >= 2 && !s.kalip[h]).map(([h]) => h);
  const enCok = Math.max(0, ...Object.values(s.kalip)); const tekTip = s.n >= 5 && enCok / s.n > 0.6;
  const disi = Object.keys(s.kalip).filter(h => !(MK[md] || {})[h]);
  satir.push({ md, k, gn: g.n, gk: yaz(g.kalip), sn: s.n, sk: yaz(s.kalip), eksik, tekTip, disi });
  const o = (ozet[md] = ozet[md] || { konu: 0, gercek: 0, sitede: 0, eksikKalipKonu: 0, eksikKalip: 0, tekTipKonu: 0, besPlusKonu: 0, dersDisiSoru: 0 });
  o.konu++; o.gercek += g.n; o.sitede += s.n; if (eksik.length) { o.eksikKalipKonu++; o.eksikKalip += eksik.length; } if (s.n >= 5) o.besPlusKonu++; if (tekTip) o.tekTipKonu++; o.dersDisiSoru += disi.reduce((a, h) => a + s.kalip[h], 0);
}
// md: modül başına özet + gerçekte en sık 25 konu
const md = ['# KGK — KONU × KALIP TABLOSU', '', `> Türetilmiştir (\`kgk-is/kalip/konu-kalip-tablo.js\`, ${new Date().toISOString().slice(0, 10)}), elle düzenlenmez. Sözleşme B30/B31.`,
  '> Gerçek = çıkmış KGK (2016+; 2013–14, Mart 2015, Kasım 2018 kitapçık metni bozuk → yok), soru↔konu bağı içerikle, kalıp ELLE etiket (veri/sinav/kgk-kalip-elle-*.json).',
  '> Sitede = paket_soru sinav=kgk, kalıp KGK ayırıcısıyla (elle etikete uyumu aşağıda). Harfler: A doğrudur · B yanlıştır · C değildir · U sayılır · D öncüllü · E boşluk · G hüküm sayısı · F hesap · L sırasıyla · I kayıt · J hangi hesap · K kayıt→işlem · M tanım↔terim · N merci · O ceza · P durum→davranış · S grafik/tablo.',
  '', '| Modül | Konu | Gerçek soru | Sitede soru | Eksik kalıplı konu (eksik kalıp) | 5+ sorulu konu | TEK TİP (>%60) | Modülde hiç sorulmamış kalıpla yazılmış soru |', '|---|---:|---:|---:|---:|---:|---:|---:|'];
for (const [m, o] of Object.entries(ozet).sort()) md.push(`| ${m} | ${o.konu} | ${o.gercek} | ${o.sitede} | ${o.eksikKalipKonu} (${o.eksikKalip}) | ${o.besPlusKonu} | ${o.tekTipKonu} | ${o.dersDisiSoru} |`);
for (const m of Object.keys(ozet).sort()) {
  md.push('', `## ${m}`, '', `Modülün gerçek kalıp dağılımı: ${yaz(MK[m] || {})}`, '', '| Konu | Gerçek n | Gerçek kalıp | Sitede n | Sitedeki kalıp | Eksik kalıp | Tek tip |', '|---|---:|---|---:|---|---|---|');
  for (const s of satir.filter(x => x.md === m && x.gn > 0).sort((a, b) => b.gn - a.gn).slice(0, 25)) md.push(`| ${s.k} | ${s.gn} | ${s.gk} | ${s.sn} | ${s.sk} | ${s.eksik.join(' ') || '—'} | ${s.tekTip ? 'EVET' : ''} |`);
}
fs.writeFileSync(mdF, md.join('\n') + '\n'); if (ozetF) fs.writeFileSync(ozetF, JSON.stringify({ ozet, modulKalip: MK }, null, 1));
// kapı için: sitedeki konu → kalıp dağılımı (konu-profil.js denetle B30 kuralı bunu okur)
fs.writeFileSync(path.join(__dirname, 'site-konu-kalip.json'), JSON.stringify({ kurulus: new Date().toISOString().slice(0, 10), sitede: sitede.length, konu: Object.fromEntries(Object.entries(S).map(([k, s]) => [k, s.kalip])) }));
console.table(ozet);
