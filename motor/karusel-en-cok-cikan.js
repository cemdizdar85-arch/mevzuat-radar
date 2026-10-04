#!/usr/bin/env node
/* ============================================================================
 *  INSTAGRAM KARUSELİ: "Staja Giriş'te son 10 yılda en sık sorulan 20 konu" (04.10.2026, Cem "1.2.3 üçünü de yap" - madde 3)
 *  en-cok-cikan-konular-sgs.html ile AYNI veriden: veri/sinav/sgs-konu-okuma.json (okunarak sayım; Matematik hariç, ilk 20)
 *  1080x1350 (Instagram dikey) 6 PNG basar: kapak · 4 liste · kapanış. Başsız Chrome (arac/tarayici.js).
 *  Çıktı: Masaüstü\Tetikte-Instagram\sgs-en-cok-cikan\ (depoya GİRMEZ; paylaşmak Cem'de - dışa dönük yayın onayı).
 *  ⛔ İddia yok: "garanti", "kesin çıkar" yazılmaz; yalnız sayılan dönem. Unvan yok ("kurucu" bile yazılmaz - marka konuşur).
 *  Kullanım: node motor/karusel-en-cok-cikan.js
 * ==========================================================================*/
'use strict';
const fs = require('fs'), path = require('path'), os = require('os');
const { tarayiciAc, bekle } = require(path.join(__dirname, '..', 'arac', 'tarayici.js'));
const KOK = path.join(__dirname, '..');
// 04.10: TEK KAYNAK veri/sinav/sgs-konu-okuma.json (okunarak sayım) — etiket sayımı (sgs-konu-kapsama) KULLANILMAZ (CLAUDE.md kuralı)
const ok = JSON.parse(fs.readFileSync(path.join(KOK, 'veri', 'sinav', 'sgs-konu-okuma.json'), 'utf8'));
const DONEM = ok.donem, DERS = { 'Muhasebe': 'Finansal Muhasebe', 'İktisat': 'Ekonomi', 'Atatürk İlkeleri': 'Atatürk İlkeleri ve İnkılap Tarihi' };
const srt = d => { const [y, n] = d.split('/'); return +y * 10 + +n; };
const Kk = {}; for (const x of ok.kararlar) if (x.e) (Kk[x.konu] = Kk[x.konu] || { ders: DERS[x.ders] || x.ders, konu: x.konu, d: new Set(), n: 0 }), Kk[x.konu].d.add(x.donem), Kk[x.konu].n++;
const top = Object.values(Kk).map(r => ({ ...r, don: r.d.size, son: [...r.d].sort((p, q) => srt(q) - srt(p))[0] })).filter(x => x.ders !== 'Matematik')
  .sort((p, q) => q.don - p.don || q.n - p.n || srt(q.son) - srt(p.son)).slice(0, 20);
const esc = s => String(s).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
const HEDEF = path.join(os.homedir(), 'OneDrive', 'Masaüstü', 'Tetikte-Instagram', 'sgs-en-cok-cikan');
fs.mkdirSync(HEDEF, { recursive: true });

const CSS = `*{box-sizing:border-box;margin:0}
body{width:1080px;height:1350px;background:#faf8f4;color:#0f1b2d;font-family:"Segoe UI",-apple-system,system-ui,Roboto,Arial,sans-serif;overflow:hidden}
.k{width:1080px;height:1350px;padding:84px 80px 150px;display:flex;flex-direction:column;position:relative}
.marka{display:flex;align-items:center;gap:14px;font-weight:800;font-size:40px;letter-spacing:-.8px}
.lamba{width:22px;height:22px;border-radius:50%;background:#f3a52a;box-shadow:0 0 0 10px rgba(243,165,42,.18)}
.ust{font-size:26px;font-weight:700;color:#8a6224;letter-spacing:2px;text-transform:uppercase;margin-top:70px}
h1{font-size:92px;line-height:1.02;letter-spacing:-2.5px;font-weight:850;margin-top:22px}
h1 em{font-style:normal;color:#c9821b}
.alt{font-size:34px;line-height:1.35;color:#3d4b63;margin-top:34px;max-width:880px}
.kaydir{margin-top:auto;font-size:30px;font-weight:700;color:#0f1b2d;display:flex;align-items:center;gap:14px}
.kaydir b{background:#0f1b2d;color:#faf8f4;border-radius:999px;padding:12px 26px}
.kaynak{position:absolute;left:80px;right:80px;bottom:44px;font-size:21px;color:#6a7488}
.baslik{font-size:30px;font-weight:800;color:#8a6224;margin-top:44px;letter-spacing:1px;text-transform:uppercase}
.liste{margin-top:26px;display:flex;flex-direction:column;gap:18px}
.s{display:grid;grid-template-columns:78px 1fr;gap:22px;align-items:center;background:#ffffff;border:2px solid #ece6db;border-radius:24px;padding:20px 26px}
.no{font-size:46px;font-weight:850;color:#c9821b;text-align:center}
.ad{font-size:34px;font-weight:750;line-height:1.15;letter-spacing:-.4px}
.d{font-size:23px;color:#3d4b63;margin-top:6px;display:flex;align-items:center;gap:14px}
.cubuk{flex:0 0 220px;height:12px;border-radius:99px;background:#ece6db;overflow:hidden}
.cubuk i{display:block;height:100%;background:#f3a52a;border-radius:99px}
.son h1{font-size:84px}
.dugme{margin-top:46px;display:inline-block;background:#f3a52a;color:#0f1b2d;font-weight:850;font-size:40px;border-radius:22px;padding:26px 40px;align-self:flex-start}
.site{margin-top:28px;font-size:36px;font-weight:800}`;
const kaynak = `<div class="kaynak">Kaynak: SGS çıkmış soruları 2016/1–2026/2 (${DONEM} dönem; 27'si TESMER, 5'i ikincil yayın). Her soru okunarak sayıldı; kanıt listesi sitede.</div>`;
const marka = `<div class="marka"><span class="lamba"></span>tetikte</div>`;
const sayfalar = [];
sayfalar.push(`<div class="k">${marka}<div class="ust">SMMM Staja Giriş Sınavı</div><h1>Son 10 yılda <em>en sık sorulan</em> 20 konu</h1><p class="alt">${DONEM} sınav döneminin çıkmış sorularını tek tek okuyarak saydık. Hangi konu kaç dönemde soruldu? Her rakamın kanıtı sitede: sınav + soru no.</p><div class="kaydir">Kaydır <b>→</b></div>${kaynak}</div>`);
const parca = [[0, 7], [7, 14], [14, 20]];
parca.forEach(([a, b], i) => {
  const s = top.slice(a, b).map((x, j) => `<div class="s"><div class="no">${a + j + 1}</div><div><div class="ad">${esc(x.konu)}</div><div class="d">${esc(x.ders)} · ${x.don}/${DONEM} dönem<span class="cubuk"><i style="width:${Math.round(100 * x.don / DONEM)}%"></i></span></div></div></div>`).join('');
  sayfalar.push(`<div class="k">${marka}<div class="baslik">${a + 1}–${b}. konular · sorulduğu dönem</div><div class="liste">${s}</div>${kaynak}</div>`);
});
sayfalar.push(`<div class="k son">${marka}<div class="ust">Sıra sende</div><h1>Sen bu konularda <em>neredesin?</em></h1><p class="alt">30 soruda seviyeni ölç: ücretsiz, form yok. Bitince geçme ihtimalini ve en zayıf alanını görürsün.</p><div class="dugme">30 soruda seviyeni ölç</div><div class="site">tetikte.com</div><p class="alt" style="font-size:28px;margin-top:18px">Kanıt listesi ve yöntem: tetikte.com/en-cok-cikan-konular-sgs.html</p>${kaynak}</div>`);

(async () => {
  const t = await tarayiciAc(); if (t.hata) throw new Error(t.hata);
  const c = await t.cdp.cagir('Target.createTarget', { url: 'about:blank' });
  const o = (await t.cdp.cagir('Target.attachToTarget', { targetId: c.targetId, flatten: true })).sessionId;
  await t.cdp.cagir('Emulation.setDeviceMetricsOverride', { width: 1080, height: 1350, deviceScaleFactor: 1, mobile: false }, o);
  await t.cdp.cagir('Page.enable', {}, o);
  for (let i = 0; i < sayfalar.length; i++) {
    const html = `<!doctype html><html lang="tr"><head><meta charset="utf-8"><style>${CSS}</style></head><body>${sayfalar[i]}</body></html>`;
    await t.cdp.cagir('Page.navigate', { url: 'data:text/html;charset=utf-8;base64,' + Buffer.from(html).toString('base64') }, o);
    await bekle(900);
    const r = await t.cdp.cagir('Page.captureScreenshot', { format: 'png', clip: { x: 0, y: 0, width: 1080, height: 1350, scale: 1 } }, o);
    const ad = path.join(HEDEF, `${String(i + 1).padStart(2, '0')}.png`);
    fs.writeFileSync(ad, Buffer.from(r.data, 'base64'));
    console.log('yazıldı: ' + ad);
  }
  t.kapat();
})().catch(e => { console.error('HATA', e.message); process.exit(1); });
