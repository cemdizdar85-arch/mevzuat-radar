#!/usr/bin/env node
/* ============================================================================
 *  SINAV NÖBETİ — Instagram görseli (05.10.2026, Cem "Sınav Nöbeti haber hattını kuralım")
 *  veri/sinav-nobeti.json'daki duyurudan 1080x1350 gönderi + 1080x1920 hikâye basar. Başsız Chrome (arac/tarayici.js) → YEREL koşar.
 *  ⛔ Görselde yalnız RESMÎ BAŞLIK + KURUM + TARİH + kaynak alan adı. Özet/yorum YOK. Paylaşmak Cem'de: önce duyurunun kendisi okunur.
 *  Çıktı: Masaüstü\Tetikte-Instagram\sinav-nobeti\<tarih>-<kurum>-<kısa>-{gonderi,hikaye}.png (depoya GİRMEZ)
 *  Kullanım: node motor/sinav-nobeti-gorsel.js            (en yeni 1 duyuru)
 *            node motor/sinav-nobeti-gorsel.js --son 3    (en yeni 3)
 *            node motor/sinav-nobeti-gorsel.js --url <duyuru linki>
 * ==========================================================================*/
'use strict';
const fs = require('fs'), path = require('path'), os = require('os');
const { tarayiciAc, bekle } = require(path.join(__dirname, '..', 'arac', 'tarayici.js'));
const KOK = path.join(__dirname, '..');
const arg = (ad, vars) => { const i = process.argv.indexOf(ad); return i > 0 ? process.argv[i + 1] : vars; };
const kayit = JSON.parse(fs.readFileSync(path.join(KOK, 'veri', 'sinav-nobeti.json'), 'utf8')).duyurular;
const secilen = arg('--url') ? kayit.filter(d => d.url === arg('--url')) : kayit.slice(0, Number(arg('--son', 1)));
if (!secilen.length) { console.error('duyuru bulunamadı'); process.exit(2); }
const HEDEF = path.join(os.homedir(), 'OneDrive', 'Masaüstü', 'Tetikte-Instagram', 'sinav-nobeti');
fs.mkdirSync(HEDEF, { recursive: true });
const esc = s => String(s).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
const trTarih = iso => { const [y, a, g] = iso.split('-'); return `${g}.${a}.${y}`; };
const kisa = s => s.toLocaleLowerCase('tr').replace(/ç/g, 'c').replace(/ğ/g, 'g').replace(/ı/g, 'i').replace(/ö/g, 'o').replace(/ş/g, 's').replace(/ü/g, 'u').replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '').slice(0, 40);

const CSS = (w, h) => `*{box-sizing:border-box;margin:0}
body{width:${w}px;height:${h}px;background:#0f1b2d;color:#faf8f4;font-family:"Segoe UI",-apple-system,system-ui,Roboto,Arial,sans-serif;overflow:hidden}
.k{width:${w}px;height:${h}px;padding:${h > 1500 ? 170 : 90}px 84px ${h > 1500 ? 230 : 150}px;display:flex;flex-direction:column;position:relative}
.marka{display:flex;align-items:center;gap:14px;font-weight:800;font-size:40px;letter-spacing:-.8px}
.lamba{width:22px;height:22px;border-radius:50%;background:#f3a52a;box-shadow:0 0 0 10px rgba(243,165,42,.22)}
.serit{margin-top:${h > 1500 ? 120 : 80}px;display:inline-flex;align-self:flex-start;gap:14px;align-items:center;background:#f3a52a;color:#0f1b2d;font-weight:850;font-size:30px;letter-spacing:2px;text-transform:uppercase;border-radius:999px;padding:12px 28px}
.ust{margin-top:40px;font-size:32px;color:#c9d2e0;font-weight:700}
.ust b{color:#f3a52a}
h1{margin-top:22px;font-weight:850;letter-spacing:-1.5px;line-height:1.08}
.kaynak{margin-top:auto;font-size:28px;color:#c9d2e0;line-height:1.4}
.kaynak b{color:#faf8f4}
.alt{position:absolute;left:84px;right:84px;bottom:${h > 1500 ? 120 : 52}px;font-size:22px;color:#8c98ab}`;
// başlık boyuna göre punto (taşma bekçisi ayrıca ölçer)
const punto = (b, h) => { const n = b.length; const t = h > 1500 ? 1.15 : 1; return Math.round((n < 50 ? 82 : n < 80 ? 70 : n < 120 ? 58 : 48) * t); };
const sayfa = (d, w, h) => `<!doctype html><html lang="tr"><head><meta charset="utf-8"><style>${CSS(w, h)}</style></head><body><div class="k">
<div class="marka"><span class="lamba"></span>tetikte</div>
<div class="serit">Sınav Nöbeti</div>
<div class="ust"><b>${esc(d.kurum)}</b> duyurdu · ${esc(trTarih(d.tarih))}</div>
<h1 style="font-size:${punto(d.baslik, h)}px">${esc(d.baslik)}</h1>
<p class="kaynak">Duyurunun tamamı: <b>${esc(new URL(d.url).hostname.replace(/^www\./, ''))}</b><br>Tüm sınav duyuruları: <b>tetikte.com/sinav-nobeti</b></p>
<div class="alt">Resmî başlık aynen aktarılmıştır. Bağlayıcı metin kurumun kendi sayfasındadır.</div>
</div></body></html>`;

(async () => {
  const t = await tarayiciAc(); if (t.hata) throw new Error(t.hata);
  const c = await t.cdp.cagir('Target.createTarget', { url: 'about:blank' });
  const o = (await t.cdp.cagir('Target.attachToTarget', { targetId: c.targetId, flatten: true })).sessionId;
  await t.cdp.cagir('Page.enable', {}, o);
  for (const d of secilen) {
    for (const [tur, w, h] of [['gonderi', 1080, 1350], ['hikaye', 1080, 1920]]) {
      await t.cdp.cagir('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: 1, mobile: false }, o);
      await t.cdp.cagir('Page.navigate', { url: 'data:text/html;charset=utf-8;base64,' + Buffer.from(sayfa(d, w, h)).toString('base64') }, o);
      await bekle(800);
      const tas = await t.cdp.cagir('Runtime.evaluate', { expression: `(()=>{const k=document.querySelector('.kaynak').getBoundingClientRect().top;return document.querySelector('h1').getBoundingClientRect().bottom>k-20})()`, returnByValue: true }, o);
      if (tas.result.value) { console.error('KIRMIZI: başlık kaynak satırına taşıyor → ' + d.baslik); process.exitCode = 3; }
      const r = await t.cdp.cagir('Page.captureScreenshot', { format: 'png', clip: { x: 0, y: 0, width: w, height: h, scale: 1 } }, o);
      const ad = path.join(HEDEF, `${d.tarih}-${kisa(d.kurum)}-${kisa(d.baslik)}-${tur}.png`);
      fs.writeFileSync(ad, Buffer.from(r.data, 'base64'));
      console.log('yazıldı: ' + ad);
    }
  }
  t.kapat();
})().catch(e => { console.error('HATA', e.message); process.exitCode = 1; });
