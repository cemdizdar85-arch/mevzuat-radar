// Kartların "gorsel" alanından SVG çizer. Bedel 0. Kullanım: node arac/kart-sekil-ciz.js <kart.json> <çıktı klasörü> <önek>
// Renk SABİTİ YOK: çizim currentColor ve saydamlıkla yapılır; sayfanın yazı rengini alır (açık ve koyu temada okunur).
// 🚫 GÖRMEZ: metnin kutuya sığıp sığmadığını yalnız karakter sayısıyla kestirir (yazı tipi ölçmez); çok uzun satır taşabilir, gözle bakılmalı.
const fs = require('fs'), path = require('path');
const [, , kartYol, cikti, onek] = process.argv;
const j = JSON.parse(fs.readFileSync(kartYol, 'utf8'));
fs.mkdirSync(cikti, { recursive: true });
const esc = s => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
const sar = (s, n) => { const out = []; let c = ''; for (const w of String(s).split(/\s+/)) { if ((c + ' ' + w).trim().length > n) { if (c) out.push(c); c = w; } else c = (c + ' ' + w).trim(); } if (c) out.push(c); return out.length ? out : ['']; };
const G = 760, P = 20, LH = 19;
const metin = (lines, x, y, o = {}) => lines.map((l, i) => `<text x="${x}" y="${y + i * LH}" font-size="${o.fs || 14}" ${o.kalin ? 'font-weight="700"' : ''} ${o.orta ? 'text-anchor="middle"' : ''} fill="currentColor"${o.soluk ? ' fill-opacity="0.72"' : ''}>${esc(l)}</text>`).join('');
const kutu = (x, y, w, h, o = {}) => `<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="10" fill="currentColor" fill-opacity="${o.dolu || 0.05}" stroke="currentColor" stroke-opacity="${o.cizgi || 0.35}" stroke-width="${o.kalin ? 2 : 1.2}"/>`;
const ok = (x1, y, x2) => `<line x1="${x1}" y1="${y}" x2="${x2 - 7}" y2="${y}" stroke="currentColor" stroke-opacity="0.6" stroke-width="1.6"/><path d="M${x2 - 8},${y - 5} L${x2},${y} L${x2 - 8},${y + 5} Z" fill="currentColor" fill-opacity="0.6"/>`;

function satirCiz(s, y) { // "A → B" ok'lu iki kutu; düz satır tek kutu; "X · ..." başlık
  let g = '';
  if (/^[A-ZÇĞİÖŞÜ] · /.test(s)) { g += metin([s], P, y + 16, { kalin: true, fs: 13 }); return { g, h: 28 }; }
  if (!s.trim()) return { g: '', h: 8 };
  const p = s.replace(/^\s*→\s*/, '').split(/\s*→\s*/); const girinti = /^\s*→/.test(s) ? 34 : (/^\s{2,}/.test(s) ? 14 : 0);
  if (/^[├│└]/.test(s.trim())) { // ağaç satırı
    const der = /^│\s+[├└]/.test(s.trim()) ? 2 : 1; const t = s.replace(/^[│├└─\s]+/, ''); const x = P + der * 34; const l = sar(t, 82 - der * 6); const h = l.length * LH + 16;
    g += `<path d="M${x - 20},${y - 6} V${y + h / 2} H${x - 4}" fill="none" stroke="currentColor" stroke-opacity="0.45" stroke-width="1.4"/>` + kutu(x, y, G - x - P, h, { dolu: der === 1 ? 0.07 : 0.03 }) + metin(l, x + 12, y + 21);
    return { g, h: h + 8 };
  }
  if (p.length === 2) {
    const w1 = Math.round((G - 2 * P - girinti - 44) * 0.42), w2 = G - 2 * P - girinti - 44 - w1; const l1 = sar(p[0], Math.floor(w1 / 7.6)), l2 = sar(p[1], Math.floor(w2 / 7.6)); const h = Math.max(l1.length, l2.length) * LH + 18; const x1 = P + girinti, x2 = x1 + w1 + 44;
    g += kutu(x1, y, w1, h) + metin(l1, x1 + 12, y + 22) + ok(x1 + w1 + 6, y + h / 2, x2 - 4) + kutu(x2, y, w2, h, { dolu: 0.1, kalin: true }) + metin(l2, x2 + 12, y + 22, { kalin: true });
    return { g, h: h + 8 };
  }
  const x = P + girinti; const l = sar(p.join(' → '), Math.floor((G - x - P) / 7.4)); const h = l.length * LH + 18;
  g += (girinti >= 34 ? ok(x - 30, y + h / 2, x - 2) : '') + kutu(x, y, G - x - P, h, { dolu: girinti ? 0.03 : 0.07 }) + metin(l, x + 12, y + 22);
  return { g, h: h + 8 };
}
function tabloCiz(gz, y) {
  const n = gz.sutunlar.length, w0 = 250, w = (G - 2 * P - w0) / (n - 1); let g = '', yy = y; const X = i => i === 0 ? P : P + w0 + (i - 1) * w, W = i => i === 0 ? w0 : w;
  const satir = (h, bas) => { const ls = h.map((c, i) => sar(c, Math.floor(W(i) / (bas || i === 0 ? 8.2 : 9.4)))); const hh = Math.max(...ls.map(l => l.length)) * LH + 22;
    h.forEach((c, i) => { g += kutu(X(i) + 3, yy, W(i) - 6, hh, { dolu: bas ? 0.12 : (i === 0 ? 0.06 : 0.02), kalin: !bas && i > 0 }) + (bas || i === 0 ? metin(ls[i], X(i) + 14, yy + 24, { kalin: bas, fs: 13 }) : metin(ls[i], X(i) + W(i) / 2, yy + hh / 2 + 6 - (ls[i].length - 1) * LH / 2, { kalin: true, orta: true, fs: 16 })); }); yy += hh + 6; };
  satir(gz.sutunlar, true); gz.satirlar.forEach(r => satir(r, false));
  if (gz.alt_not) { const l = sar(gz.alt_not, 100); g += metin(l, P, yy + 16, { soluk: true, fs: 12.5 }); yy += l.length * LH + 10; }
  return { g, h: yy - y };
}
let say = 0;
for (const k of j.kart) {
  const gz = k.gorsel; if (!gz) continue; let y = 54, g = metin([gz.baslik], P, 32, { kalin: true, fs: 18 });
  if (gz.sutunlar) { const r = tabloCiz(gz, y); g += r.g; y += r.h; } else for (const s of gz.satirlar) { const r = satirCiz(s, y); g += r.g; y += r.h; }
  const H = y + 14;
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${G} ${H}" width="${G}" height="${H}" role="img" aria-label="${esc(gz.baslik)}" font-family="system-ui, -apple-system, 'Segoe UI', Roboto, Arial, sans-serif">${g}</svg>\n`;
  fs.writeFileSync(path.join(cikti, `${onek}-${k.no}.svg`), svg, 'utf8'); say++;
}
console.log('çizilen şekil:', say);
