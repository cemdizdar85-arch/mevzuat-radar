#!/usr/bin/env node
/*
================================================================================
  KGK KONU KAPSAMA — "modül · konu · son 10 yılda kaç soru çıktı · sitede kaç sorumuz var · eksik"
  27.09.2026 · bedel 0 (model yok; ağ yalnız paket_soru sayımı için, anahtar yoksa site KÖR yazılır)

  Cem 26.09: "ders ders altında hangi konularda sorular çıkmış onu da istiyorum · ders altındaki
  konuya göre gitmeli". Kural SGS ile AYNI (arac/sgs-konu-kapsama.js): hedef = sitede, son 10 yılda
  o konudan çıkan soru kadar soru (1 kat). Cem onayı 26.09: hedef 4.229 (eski genel muhasebe hariç).

  NEDEN SÖZLÜK: KGK çıkmış arşivi (veri/kgk-analiz.json, 30 sınav) aynı konuyu farklı adlarla
  etiketliyor ("bankacilik denetim komitesi" / "... gorevleri"). Sözlüksüz sayımda Denetim
  Standartları'nda 3+ sınavda çıkan konu 53 görünüyordu, sözlükle 124.
  Sözlük: veri/sinav/kgk-konu-es.json — etiket → küme başı (k) + gerçek modül (d) + eski genel
  muhasebe (e). 26-27.09 GM + 5 okuyucu; GM örneklemi 80 küme / 1 şüpheli.

  GİRDİ : veri/kgk-analiz.json · veri/sinav/kgk-konu-es.json · ambar paket_soru (sinav=kgk)
  ÇIKTI : veri/sinav/KGK-KAPSAMA.md · veri/fabrika/kgk-konu-kapsama.csv + .json

  🚫 GÖRMEZ:
    · Genel Hukuk Mevzuatı (2022'den beri sınavda yok) — sayılmaz, satırı yazılmaz.
    · Sözlükte olmayan yeni etiket (yeni sınav yutulunca) → özet satırında "sözlükte yok" sayısı;
      o etiketler okunup sözlüğe eklenmeli. Kendi kümesi olur, modülü '?'.
    · e=true (eski genel muhasebe: standarda bağlı olmayan kayıt/hesap) konuların hedefi 0'dır;
      bugünkü TMS modülünde doğrudan sorulmuyor varsayımı ÖLÇÜLMEDİ, karar Cem'in (26.09).
    · Sitedeki sorunun konusu paket_soru.konu alanından okunur; sözlükte yoksa "ÇIKMIŞTA YOK" satırı olur.
    · Kümeleme doğruluğu örneklemle ölçüldü, tamamı okunmadı.

  KULLANIM
    node arac/kgk-konu-kapsama.js            (Kat 1, pencere 2016+)
    node arac/kgk-konu-kapsama.js --kat 2 --yil 2016
================================================================================
*/
'use strict';
const fs = require('fs'), path = require('path');
const KOK = path.resolve(__dirname, '..');
const arg = (ad, vars) => { const i = process.argv.indexOf(ad); return i > 0 ? process.argv[i + 1] : vars; };
const KAT = Number(arg('--kat', 1)), YIL = Number(arg('--yil', 2016));

function katla(s) {
  let t = String(s).replace(/İ/g, 'I').replace(/ı/g, 'i').toLowerCase();
  t = t.replace(/i̇/g, 'i').replace(/ş/g, 's').replace(/ğ/g, 'g').replace(/ü/g, 'u').replace(/ö/g, 'o').replace(/ç/g, 'c')
    .replace(/[âà]/g, 'a').replace(/î/g, 'i').replace(/û/g, 'u').replace(/['’]/g, '');
  return t.replace(/[^a-z0-9 ]/g, ' ').replace(/\s+/g, ' ').trim();
}
const oku = p => JSON.parse(fs.readFileSync(path.join(KOK, p), 'utf8').replace(/^﻿/, ''));
const AY = { ocak: 1, subat: 2, mart: 3, nisan: 4, mayis: 5, haziran: 6, temmuz: 7, agustos: 8, eylul: 9, ekim: 10, kasim: 11, aralik: 12 };
function tarih(d) { const p = katla(d).split(' '); const y = +p[2], a = AY[p[1]], g = +p[0]; if (!y || !a) throw new Error('donem cozulemedi: ' + d); return { y, dk: y * 10000 + a * 100 + g }; }

const es = oku('veri/sinav/kgk-konu-es.json').esleme;
const an = oku('veri/kgk-analiz.json');

async function siteOku() {
  const anahtar = (process.env.SUPABASE_SERVICE_KEY || '').trim();
  if (!anahtar) return null;
  const L = []; let son = '';
  for (;;) {
    const u = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/paket_soru?select=id,ders,konu&sinav=eq.kgk&order=id&limit=1000' + (son ? '&id=gt.' + encodeURIComponent(son) : '');
    const r = await fetch(u, { headers: { apikey: anahtar, Authorization: 'Bearer ' + anahtar, 'User-Agent': 'mevzuat-radar-robot/1.0' } });
    if (!r.ok) throw new Error('paket_soru ' + r.status);
    const s = await r.json(); L.push(...s); if (s.length < 1000) break; son = s[s.length - 1].id;
  }
  return L;
}

(async () => {
  // 1) çıkmış: etiket → sayımlar (Genel Hukuk hariç)
  const cik = new Map(); const pencereD = new Set();
  for (const d of an.donemler) {
    const t = tarih(d.donem); if (t.y >= YIL) pencereD.add(d.donem);
    for (const [k, v] of Object.entries(d.konuSayim)) {
      const ham = k.split('|')[0], lab = k.split('|').slice(1).join('|');
      if (/genel hukuk/.test(katla(ham))) continue;
      const a = katla(lab); if (!a) continue;
      if (!cik.has(a)) cik.set(a, { a, ad: lab, son: 0, tum: 0, donem: new Set(), sonD: '', sonDk: 0, site: 0 });
      const c = cik.get(a); c.tum += +v;
      if (t.y >= YIL) { c.son += +v; c.donem.add(d.donem); }
      if (t.dk > c.sonDk) { c.sonDk = t.dk; c.sonD = d.donem; }
    }
  }
  // 2) site: paket_soru (sinav=kgk) konu alanı
  let siteL = null, siteHata = '';
  try { siteL = await siteOku(); } catch (e) { siteHata = e.message; }
  const siteDisi = new Map(); let siteTop = 0;
  if (siteL) for (const r of siteL) {
    siteTop++; const a = katla(r.konu || '');
    if (cik.has(a)) cik.get(a).site++;
    else { const k = (r.ders || '?') + '|' + a; if (!siteDisi.has(k)) siteDisi.set(k, { ders: r.ders || '?', ad: r.konu, n: 0 }); siteDisi.get(k).n++; }
  }
  // 3) kümele
  let sozlukteYok = 0; const kume = new Map();
  for (const c of cik.values()) {
    const e = es[c.a]; if (!e) { sozlukteYok++; if (process.env.KGK_KAPSAMA_HATA) console.error('sozlukte yok:', c.ad); }
    const m = e ? e.d : '?', kk = m + '|' + (e ? e.k : c.a);
    if (!kume.has(kk)) kume.set(kk, { m, k: e ? e.k : c.a, uye: [], eski: true });
    const K = kume.get(kk); K.uye.push(c); K.eski = K.eski && !!(e && e.e);
  }
  const sat = [];
  for (const K of kume.values()) {
    const L = K.uye, son = L.reduce((s, c) => s + c.son, 0), tum = L.reduce((s, c) => s + c.tum, 0), siteN = L.reduce((s, c) => s + c.site, 0);
    const don = new Set(); L.forEach(c => c.donem.forEach(x => don.add(x)));
    const sonC = [...L].sort((a, b) => b.sonDk - a.sonDk)[0];
    const bas = L.find(c => c.a === K.k) || [...L].sort((a, b) => b.son - a.son)[0];
    let durum;
    if (K.eski) durum = 'ESKİ MUHASEBE (hedef dışı)';
    else if (son === 0) durum = tum > 0 ? '10 YILDIR ÇIKMIYOR' : '—';
    else if (!siteL) durum = 'SİTE ÖLÇÜLMEDİ';
    else if (siteN === 0) durum = 'HİÇ YOK';
    else if (siteN < KAT * son) durum = 'AZ';
    else durum = 'VAR';
    const hedef = (K.eski || son === 0) ? 0 : Math.ceil(KAT * son);
    const eksik = Math.max(0, hedef - siteN);
    sat.push({ ders: K.m, konu: bas.ad, diger: [...new Set(L.filter(c => c !== bas).map(c => c.ad))].join(' | '), son, don: don.size, tum, sonD: sonC.sonD, site: siteN, hedef, durum, eksik });
  }
  for (const v of siteDisi.values()) sat.push({ ders: v.ders, konu: v.ad, diger: '', son: 0, don: 0, tum: 0, sonD: '-', site: v.n, hedef: 0, durum: 'ÇIKMIŞTA YOK (bizim konu)', eksik: 0 });
  sat.sort((a, b) => a.ders.localeCompare(b.ders, 'tr') || b.son - a.son || b.don - a.don || b.site - a.site);

  // 4) çıktılar
  const q = s => '"' + String(s).replace(/"/g, '""') + '"';
  const baslik = ['Modül', 'Konu', 'Aynı konunun arşivdeki diğer adları', `Son 10 yılda çıkan soru (${YIL}+, ${pencereD.size} sınav)`, 'Kaç sınavda çıktı', 'Tüm zamanlar', 'Son çıktığı sınav', 'Sitede bizim soru', `Hedef (${KAT} kat)`, 'Durum', 'Eksik'];
  const fab = path.join(KOK, 'veri', 'fabrika'); fs.mkdirSync(fab, { recursive: true });
  fs.writeFileSync(path.join(fab, 'kgk-konu-kapsama.csv'), '﻿' + [baslik.map(q).join(';'), ...sat.map(r => [r.ders, r.konu, r.diger, r.son, r.don, r.tum, r.sonD, r.site, r.hedef, r.durum, r.eksik].map(q).join(';'))].join('\r\n'));
  fs.writeFileSync(path.join(fab, 'kgk-konu-kapsama.json'), JSON.stringify({ kat: KAT, yil: YIL, pencere: pencereD.size, site_olculdu: !!siteL, satirlar: sat }));

  const D = {};
  for (const r of sat) {
    const d = D[r.ders] || (D[r.ders] = { k: 0, son: 0, site: 0, hedef: 0, eksik: 0, VAR: 0, AZ: 0, Y2: 0, Y1: 0, eski: 0 });
    d.site += r.site; d.hedef += r.hedef; d.eksik += r.eksik;
    if (r.durum.startsWith('ESKİ')) d.eski++;
    if (r.hedef > 0) { d.k++; d.son += r.son; if (r.durum === 'VAR') d.VAR++; if (r.durum === 'AZ') d.AZ++; if (r.durum === 'HİÇ YOK') { r.don >= 2 ? d.Y2++ : d.Y1++; } }
  }
  const sayi = n => Number(n).toLocaleString('tr-TR');
  const T = Object.values(D).reduce((t, d) => ({ hedef: t.hedef + d.hedef, eksik: t.eksik + d.eksik, site: t.site + d.site, k: t.k + d.k }), { hedef: 0, eksik: 0, site: 0, k: 0 });
  const md = [];
  md.push('# KGK — KONU KAPSAMA', '');
  md.push(`> Türetilmiştir (\`arac/kgk-konu-kapsama.js\`), **elle düzenlenmez**. Hedef: sitede **${KAT} kat** (son 10 yılda çıkan soru sayısı kadar × ${KAT}). Pencere: ${YIL}+ (${pencereD.size} sınav). Eski genel muhasebe konuları hedef dışı. Genel Hukuk (2022'den beri sınavda yok) sayılmaz.`);
  md.push('> Eşleme sözlüğü: `veri/sinav/kgk-konu-es.json`. Tam liste: `veri/fabrika/kgk-konu-kapsama.csv`.', '');
  md.push(siteL ? `Sitede (paket_soru, sinav=kgk): **${sayi(siteTop)}** soru · konu kümesi: ${sayi(kume.size)} · sözlükte olmayan arşiv etiketi: **${sozlukteYok}**` : `⚠ **Site KÖR** — paket_soru okunamadı (${siteHata || 'SUPABASE_SERVICE_KEY yok'}); "sitede" sütunu ölçülmedi, eksik = hedef varsayıldı. Sözlükte olmayan etiket: **${sozlukteYok}**`, '');
  md.push(`**TOPLAM: hedef ${sayi(T.hedef)} · sitede ${sayi(T.site)} · EKSİK ${sayi(T.eksik)}** (${sayi(T.k)} konu)`, '');
  md.push('| Modül | Hedefli konu | Son 10 yılda çıkan | Hedef | Sitede | EKSİK | VAR | AZ | Hiç yok (2+ sınav) | Hiç yok (1 sınav) | Eski muhasebe konusu |', '|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|');
  for (const [k, d] of Object.entries(D).sort((a, b) => b[1].hedef - a[1].hedef)) md.push(`| ${k} | ${d.k} | ${d.son} | ${d.hedef} | ${d.site} | **${d.eksik}** | ${d.VAR} | ${d.AZ} | ${d.Y2} | ${d.Y1} | ${d.eski} |`);
  const oz = f => { const x = sat.filter(r => r.eksik > 0 && f(r)); return `${x.length} konu / ${x.reduce((a, r) => a + r.eksik, 0)} soru`; };
  md.push('', '## Eksik — sıklık katmanı (plan bu sırayla kurulur)', '', `- Hedefi 5+ soru olan konular: **${oz(r => r.hedef >= 5)}**`, `- Hedefi 2–4 soru: ${oz(r => r.hedef >= 2 && r.hedef < 5)}`, `- Hedefi 1 soru: ${oz(r => r.hedef === 1)}`, '');
  md.push('## En büyük 40 eksik', '', '| Modül | Konu | Son 10 yıl çıkan / sınav | Sitede | Eksik |', '|---|---|---:|---:|---:|');
  for (const r of sat.filter(r => r.eksik > 0).sort((a, b) => b.eksik - a.eksik || b.don - a.don).slice(0, 40)) md.push(`| ${r.ders} | ${r.konu} | ${r.son} / ${r.don} | ${r.site} | ${r.eksik} |`);
  fs.writeFileSync(path.join(KOK, 'veri', 'sinav', 'KGK-KAPSAMA.md'), md.join('\n') + '\n');
  console.log(`KGK kapsama: kume ${kume.size} · hedef ${T.hedef} · site ${siteL ? siteTop : 'KOR'} · eksik ${T.eksik} · sozlukte yok ${sozlukteYok} (kat ${KAT}, ${YIL}+)`);
})().catch(e => { console.error('HATA:', e.message); process.exit(1); });
