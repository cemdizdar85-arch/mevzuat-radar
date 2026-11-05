// KART ÖLÇÜSÜ (standart §7: K1 kartlı · K3 kök hedefi · K4 kalıp (atama + kart dağılımı) · Ş4 doğru şık en uzun · A4 harf ≤%30 · kökte yıl · tek harf ad). Bedel 0.
// node kart-olc.js <grup> [--tsv]   → soru başı satır + grup özeti; çıkış 1 = KUSUR var.
// GÖRMEZ: kalıp ayırıcının ±%12 hatası (KGK ayırıcısı ↔ elle %87,6) · kanıt cümlesinin doğruluğu (ayrı: kanit-ara) · ikiz (hazir-soru-denetle) · şık türünün anlamı (yalnız biçim).
'use strict';
const fs = require('fs'), path = require('path'); const IS = path.join(__dirname, '..'), oku = p => JSON.parse(fs.readFileSync(p, 'utf8').replace(/^\uFEFF/, ''));
const grup = process.argv[2], TSV = process.argv.includes('--tsv'); const FAB = 'C:/TETIKTE-CALISMA/kgk-basim/veri/fabrika';
const { ayir } = require(path.join(IS, 'kalip', 'kgk-kalip-ayirici.js'));
const kartlar = oku('C:/TETIKTE-CALISMA/kgk-basim/veri/sinav/kgk-konu-kartlari.json').kart; const KM = {}; for (const c of kartlar) KM[c.konu] = c;
const ALAN = ['ne_sorar', 'dayanak', 'celdirici', 'yazim_notu'];
const atama = {}; for (const l of fs.readFileSync(path.join(IS, 'konu', `atama-${grup}.txt`), 'utf8').split('\n')) { const m = l.match(/^\s+(.+?) → (.+?)\s{3}\[/); if (m) for (const p of m[2].split(' · ')) { const [z, h] = p.split(': '); atama[`${m[1]}|${z.trim()}`] = h.trim(); } }
const satir = [], harf = {}; let dogruEnUzun = 0, top = 0;
for (const z of ['kolay', 'zor', 'cokzor']) {
  const f = path.join(FAB, `hazir-kgk-t10-${grup}-${z}.json`); if (!fs.existsSync(f)) continue;
  oku(f).forEach((q, i) => {
    const k = [], c = KM[q.konu], sik = q.siklar || {}, L = Object.values(sik).map(String), kok = String(q.soru || ''); top++;
    if (!c) k.push('KART YOK'); else { if (!ALAN.every(x => String(c[x] || '').trim())) k.push('KART BOŞ'); if (/^\s*(AMBARDA YOK|BOZUK|OKUNAMADI)/.test(c.dayanak || '')) k.push('KART AMBARDA YOK'); }
    const kal = ayir(kok, L), at = atama[`${q.konu}|${z}`];
    if (!at) k.push('ATAMADA YOK'); else if (kal !== at) k.push(`kalıp ${kal}≠atama ${at}`);
    if (c && c.kalip_dagilim && !c.kalip_dagilim[kal]) k.push(`kalıp ${kal} kartta gerçek değil`);
    const uz = kok.length; if (c && c.kok_hedef_kr && (uz < c.kok_hedef_kr[0] || uz > c.kok_hedef_kr[1])) k.push(`kök ${uz} ∉ ${c.kok_hedef_kr.join('–')}`);
    if (/\b20\d\d\b/.test(kok)) k.push('kökte yıl (yalnız kural yıla bağlıysa — elle bak)');
    if (/\([A-ZÇĞİÖŞÜ]\)\s*(A\.?Ş|Ltd|işletme)/i.test(kok)) k.push('tek harf ad');
    if (/hepsi|hiçbiri/i.test(L.join(' '))) k.push('Ş9 hepsi/hiçbiri');
    const d = String(q.dogru || '').toUpperCase(); harf[d] = (harf[d] || 0) + 1;
    const uzs = Object.entries(sik).map(([h, s]) => [h, String(s).length]); const enUz = uzs.sort((a, b) => b[1] - a[1])[0]; if (enUz && enUz[0] === d && uzs[1] && enUz[1] > uzs[1][1]) dogruEnUzun++;
    const yumusak = k.filter(x => /kökte yıl/.test(x));
    satir.push({ kimlik: `${grup}-${z}[${i}]`, konu: q.konu, kalip: kal, atama: at || '—', kok: uz, hedef: c && c.kok_hedef_kr ? c.kok_hedef_kr.join('–') : '?', sik_medyan: L.map(s => s.length).sort((a, b) => a - b)[2] || 0, kart_sik: c ? c.sik_medyan_kr : '?', dogru: d, durum: k.length === yumusak.length ? (k.length ? 'KART-TEMIZ (not: ' + yumusak.join('; ') + ')' : 'KART-TEMIZ') : 'KUSUR: ' + k.join(' · ') });
  });
}
if (!top) { console.log(`ÖLÇÜLMEDİ: ${grup} hazır dosya yok`); process.exit(1); }
const ozet = []; for (const [h, n] of Object.entries(harf)) if (n / top > 0.3) ozet.push(`A4: ${h} harfi %${Math.round(100 * n / top)} > %30`);
if (dogruEnUzun / top > 0.4) ozet.push(`Ş4: doğru şık en uzun %${Math.round(100 * dogruEnUzun / top)} > %40`);
if (TSV) { const b = Object.keys(satir[0]); console.log([b.join('\t'), ...satir.map(s => b.map(x => s[x]).join('\t'))].join('\n')); }
else for (const s of satir) console.log(`${s.kimlik.padEnd(22)} ${s.kalip}/${s.atama} kök ${s.kok} (${s.hedef}) şık ~${s.sik_medyan}/${s.kart_sik} ${s.durum}`);
const kus = satir.filter(s => s.durum.startsWith('KUSUR')).length;
console.log(`ÖZET ${grup}: ${top} soru · KART-TEMIZ ${top - kus} · KUSUR ${kus} · harf ${JSON.stringify(harf)} · doğru şık en uzun ${dogruEnUzun}/${top}${ozet.length ? ' · ' + ozet.join(' · ') : ''}`);
process.exit(kus || ozet.length ? 1 : 0);
