// KGK kitapçık metni ↔ etiket (modül+no+konu) İÇERİKLE bağlama (03.11). Eski kural "k. 'SORU n:' = oturumun k. modülü"
// iki sütunlu metinde kayıyordu: strict işaretli (kanun/standart no) sorularda 2023–2026 dönemlerinde %18–35 uyuşmazlık ölçüldü
// (bag-denetim.js; ör. 12103 "TMS S5" metni BDS 220 sorusuydu). Yeni kural: aynı numaralı k aday metin ↔ k modül arasında
// puanı en yüksek eşleme (en çok 4! = 24 permütasyon). Puan = etiket konusundaki standart/kanun numarası metinde (5) + konu kelime
// örtüşmesi (1/kelime) + modül anahtar kelimesi (≤3). Eşitlikte eski sıra korunur. 0 USD.
'use strict';
const katla = s => String(s).replace(/İ/g, 'I').replace(/ı/g, 'i').toLowerCase().replace(/i̇/g, 'i').replace(/ş/g, 's').replace(/ğ/g, 'g').replace(/ü/g, 'u').replace(/ö/g, 'o').replace(/ç/g, 'c').replace(/[âà]/g, 'a').replace(/î/g, 'i').replace(/û/g, 'u');
const kel = s => katla(s).replace(/[^a-z0-9 ]/g, ' ').split(/\s+/).filter(w => w.length >= 4 || /^\d{2,4}$/.test(w));
const MODUL_KELIME = [
  [/muhasebe standart|^muhasebe stand/i, /\b(tms|tfrs) ?\d|bobi|muhasebelestir|finansal durum tablosu|kar veya zarar|gercege uygun deger|serefiye|amortisman|hasilat|kiralama|stok/],
  [/denetim standart|^denetim$/i, /\bbds ?\d|denetci|kalite yonetim|kys ?\d|etik kural|ornekleme|onemlilik|yapisal risk|denetim kanit|gorus/],
  [/kurumsal yonetim|finansal yonetim/i, /kurumsal yonetim|yonetim kurulu|komite|yatirimci iliskileri|faiz|getiri|portfoy|nakit|sermaye maliyeti|oran|kaldirac|basabas|tahvil|temettu/],
  [/sermaye piyasas/i, /6362|sermaye piyasasi|kurul(ca)?\b|halka arz|izahname|yatirim kurulus|borsa|portfoy yonetim|kaydi|pay sahib/],
  [/bankac/i, /5411|banka|bddk|mevduat|katilim|kredi|ozkaynak|sermaye yeterlili/],
  [/sigorta/i, /5684|4632|sigorta|reasurans|emeklilik|police|teknik karsilik|guvence hesabi|katilimci/],
  [/surdurulebilir/i, /tsrs|surdurulebilir|sera gazi|iklim|emisyon|gds ?\d|guvence denetimi|kapsam [123]/],
];
function puan(metin, modul, konu) {
  const t = katla(metin), k = katla(konu || ''); let p = 0;
  for (const m of (k.match(/\b(tms|tfrs|bds|kys|gds|tsrs|ihs|sbds)\s?\d{1,4}\b/g) || [])) if (t.replace(/\s/g, '').includes(m.replace(/\s/g, ''))) p += 5;
  for (const m of (k.match(/\b(6362|5411|5684|4632|6102|6098|660)\b/g) || [])) if (t.includes(m)) p += 5;
  const tk = new Set(kel(metin)); for (const w of new Set(kel(konu))) if (tk.has(w)) p += 1;
  for (const [mre, kre] of MODUL_KELIME) if (mre.test(katla(modul))) { const say = (t.match(new RegExp(kre.source, 'g')) || []).length; p += Math.min(3, say); }
  return p;
}
function perms(n) { if (n <= 1) return [[0]]; const out = []; for (const p of perms(n - 1)) for (let i = 0; i <= p.length; i++) out.push([...p.slice(0, i), n - 1, ...p.slice(i)]); return out; }
// adaylar: [{n, kok, sik, sira}] (kitapçıktaki geliş sırasıyla) · moduller: oturumun modül listesi · etiketBul(modul, no) → {konu}
// dönüş: [{modul, no, kok, sik, eskiModul, degisti}]
function bagla(adaylar, moduller, etiketBul) {
  const byN = {}; for (const a of adaylar) (byN[a.n] = byN[a.n] || []).push(a);
  const out = [];
  for (const [n, L] of Object.entries(byN)) {
    const k = Math.min(L.length, moduller.length); const ms = moduller.slice(0, k); const xs = L.slice(0, k);
    let enIyi = null, enP = -1;
    for (const p of perms(k)) { // p[i] = xs[i]'nin gideceği modül indisi
      let s = 0; for (let i = 0; i < k; i++) s += puan(xs[i].kok + ' ' + (xs[i].sik || []).join(' '), ms[p[i]], (etiketBul(ms[p[i]], +n) || {}).konu);
      const kimlikMi = p.every((v, i) => v === i);
      if (s > enP || (s === enP && kimlikMi)) { enP = s; enIyi = p; }
    }
    for (let i = 0; i < k; i++) out.push({ modul: ms[enIyi[i]], no: +n, kok: xs[i].kok, sik: xs[i].sik, eskiModul: ms[i], degisti: enIyi[i] !== i });
  }
  return out;
}
module.exports = { bagla, puan };
