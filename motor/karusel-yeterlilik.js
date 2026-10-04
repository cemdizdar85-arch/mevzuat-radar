#!/usr/bin/env node
/* ============================================================================
 *  INSTAGRAM KARUSELİ: "SMMM Yeterlilik — ders ders en sık sorulan konular" (05.10.2026, Cem "1 ve 2 yapalım" madde 1)
 *  en-cok-cikan-konular-yeterlilik.html ile AYNI veri: veri/sinav/smmm-konu-okuma.json (her ders tek okuyucu, 31 dönem okundu).
 *  1080x1350, 4 görsel: kapak · ders 1–4 · ders 5–8 (her derste en sık 2 konu) · kapanış. Başsız Chrome (arac/tarayici.js).
 *  Çıktı: Masaüstü\Tetikte-Instagram\yeterlilik-en-cok-cikan\ (depoya GİRMEZ; paylaşmak Cem'de).
 *  ⛔ Etiket sayımı KULLANILMAZ (CLAUDE.md "dışarı çıkan sınav rakamı soru metniyle doğrulanır"). "Garanti/kesin çıkar" yazılmaz.
 *  Kullanım: node motor/karusel-yeterlilik.js
 * ==========================================================================*/
'use strict';
const fs = require('fs'), path = require('path'), os = require('os');
const { tarayiciAc, bekle } = require(path.join(__dirname, '..', 'arac', 'tarayici.js'));
const KOK = path.join(__dirname, '..');
const ok = JSON.parse(fs.readFileSync(path.join(KOK, 'veri', 'sinav', 'smmm-konu-okuma.json'), 'utf8'));
const DONEM = ok.donem;
const dersSira = JSON.parse(fs.readFileSync(path.join(KOK, 'veri', 'soru-dizini.json'), 'utf8')).sinavlar.find(x => x.kod === 'smmm').dersler.map(d => d.ad);
const srt = d => { const [y, n] = d.split('/'); return +y * 10 + +n; };
const gorunen = k => k.replace(/ › /g, ' — ');
const D = {};
for (const x of ok.kararlar) { const r = ((D[x.ders] = D[x.ders] || {})[x.konu] = D[x.ders][x.konu] || { konu: x.konu, d: new Set(), n: 0 }); r.d.add(x.donem); r.n++; }
const top = {}; for (const d of dersSira) top[d] = Object.values(D[d]).map(r => ({ ...r, don: r.d.size })).sort((p, q) => q.don - p.don || q.n - p.n).slice(0, 2);
const esc = s => String(s).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
const HEDEF = path.join(os.homedir(), 'OneDrive', 'Masaüstü', 'Tetikte-Instagram', 'yeterlilik-en-cok-cikan');
fs.mkdirSync(HEDEF, { recursive: true });

const CSS = `*{box-sizing:border-box;margin:0}
body{width:1080px;height:1350px;background:#faf8f4;color:#0f1b2d;font-family:"Segoe UI",-apple-system,system-ui,Roboto,Arial,sans-serif;overflow:hidden}
.k{width:1080px;height:1350px;padding:84px 80px 150px;display:flex;flex-direction:column;position:relative}
.marka{display:flex;align-items:center;gap:14px;font-weight:800;font-size:40px;letter-spacing:-.8px}
.lamba{width:22px;height:22px;border-radius:50%;background:#f3a52a;box-shadow:0 0 0 10px rgba(243,165,42,.18)}
.ust{font-size:26px;font-weight:700;color:#8a6224;letter-spacing:2px;text-transform:uppercase;margin-top:70px}
h1{font-size:88px;line-height:1.03;letter-spacing:-2.5px;font-weight:850;margin-top:22px}
h1 em{font-style:normal;color:#c9821b}
.alt{font-size:34px;line-height:1.35;color:#3d4b63;margin-top:34px;max-width:900px}
.kaydir{margin-top:auto;font-size:30px;font-weight:700;display:flex;align-items:center;gap:14px}
.kaydir b{background:#0f1b2d;color:#faf8f4;border-radius:999px;padding:12px 26px}
.kaynak{position:absolute;left:80px;right:80px;bottom:44px;font-size:21px;color:#6a7488}
.baslik{font-size:28px;font-weight:800;color:#8a6224;margin-top:34px;letter-spacing:1px;text-transform:uppercase}
.dersler{margin-top:22px;display:flex;flex-direction:column;gap:16px}
.ders{background:#fff;border:2px solid #ece6db;border-radius:24px;padding:18px 26px}
.ders h3{font-size:25px;font-weight:800;color:#8a6224;letter-spacing:.5px;text-transform:uppercase;margin-bottom:8px}
.k1{display:flex;justify-content:space-between;align-items:baseline;gap:18px;padding:6px 0}
.k1+.k1{border-top:1px solid #ece6db}
.ad{font-size:29px;font-weight:750;line-height:1.18;letter-spacing:-.3px}
.sy{font-size:27px;font-weight:800;color:#c9821b;white-space:nowrap}
.sy small{font-size:20px;color:#6a7488;font-weight:600}
.son h1{font-size:84px}
.dugme{margin-top:46px;display:inline-block;background:#f3a52a;color:#0f1b2d;font-weight:850;font-size:40px;border-radius:22px;padding:26px 40px;align-self:flex-start}
.site{margin-top:28px;font-size:36px;font-weight:800}`;
const kaynak = `<div class="kaynak">Kaynak: TÜRMOB-TESMER Yeterlilik soruları 2016/1–2026/2 (${DONEM} dönem; 2020/3 dahil değil). Her soru okunarak sayıldı; kanıt listesi sitede.</div>`;
const marka = `<div class="marka"><span class="lamba"></span>tetikte</div>`;
const sayfalar = [];
sayfalar.push(`<div class="k">${marka}<div class="ust">SMMM Yeterlilik Sınavı</div><h1>Ders ders <em>en sık sorulan</em> konular</h1><p class="alt">${DONEM} sınav döneminin çıkmış sorularını tek tek okuduk. 8 dersin her birinde hangi konu kaç dönemde soruldu? Her rakamın kanıtı sitede: sınav + soru no.</p><div class="kaydir">Kaydır <b>→</b></div>${kaynak}</div>`);
[[0, 4], [4, 8]].forEach(([a, b]) => {
  const kart = dersSira.slice(a, b).map(d => `<div class="ders"><h3>${esc(d)}</h3>${top[d].map(x => `<div class="k1"><span class="ad">${esc(gorunen(x.konu))}</span><span class="sy">${x.don}<small> / ${DONEM} dönem</small></span></div>`).join('')}</div>`).join('');
  sayfalar.push(`<div class="k">${marka}<div class="baslik">Her dersin en sık 2 konusu</div><div class="dersler">${kart}</div>${kaynak}</div>`);
});
sayfalar.push(`<div class="k son">${marka}<div class="ust">Sıra sende</div><h1>Sen bu konularda <em>neredesin?</em></h1><p class="alt">30 soruda seviyeni ölç: ücretsiz, form yok. Bitince geçme ihtimalini ve en zayıf alanını görürsün.</p><div class="dugme">30 soruda seviyeni ölç</div><div class="site">tetikte.com</div><p class="alt" style="font-size:28px;margin-top:18px">Her dersin ilk 5 konusu ve kanıtı: tetikte.com/en-cok-cikan-konular-yeterlilik.html</p>${kaynak}</div>`);

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
    // taşma bekçisi: içerik kaynak satırına binerse KIRMIZI
    const tas = await t.cdp.cagir('Runtime.evaluate', { expression: `(()=>{const k=document.querySelector('.kaynak').getBoundingClientRect().top;const l=[...document.querySelectorAll('.ders,.kaydir,.dugme,.alt')].map(e=>e.getBoundingClientRect().bottom);return Math.max(0,...l)>k-8})()`, returnByValue: true }, o);
    if (tas.result.value) { console.error('KIRMIZI: görsel ' + (i + 1) + ' kaynak satırına taşıyor'); process.exitCode = 3; }
    const r = await t.cdp.cagir('Page.captureScreenshot', { format: 'png', clip: { x: 0, y: 0, width: 1080, height: 1350, scale: 1 } }, o);
    const ad = path.join(HEDEF, `${String(i + 1).padStart(2, '0')}.png`);
    fs.writeFileSync(ad, Buffer.from(r.data, 'base64'));
    console.log('yazıldı: ' + ad);
  }
  t.kapat();
})().catch(e => { console.error('HATA', e.message); process.exitCode = 1; });
