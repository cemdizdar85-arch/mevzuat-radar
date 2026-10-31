#!/usr/bin/env node
/* ============================================================================
   ÜRÜN DEMOSU REELS (01.11.2026, Cem "Tesla sahibi bunları böyle açıklar"): siyah ekran + tek cümle + sitenin GERÇEK
   ekran kaydı (telefon çerçevesinde) + kap-A. Bedel 0.
   1) Kayıt: tetikte.com/kaydir/vitrin/ornek-sgs.html, 390×844 telefon, 1. soruda A (yanlış) → Ayrıntılı açıklama → kaydır.
      Yazma istekleri (supabase/functions/goatcounter) ENGELLİ: gerçek cevap istatistiği kirlenmez.
   2) Metin kapısı: yazılar pazarlama/reklam/instagram-urun-demo.md satırlarından (exit 3).
   3) Kurgu: sahne başına mp4 + concat demuxer (30.10: çok girdili tek grafik kilitlendi).
   Kullanım: node arac/video/tellal/urun-demo.js → <kasa>/tellal-reklam/URUN-DEMO.mp4
   🚫 GÖRMEZ: sitenin o anki görünümü değişirse kayıt da değişir (her koşuda yeniden kaydedilir) · müzik (telefondan eklenir).
   ============================================================================ */
'use strict';
const fs = require('fs'), path = require('path'), { execFileSync } = require('child_process');
let chromium; try { ({ chromium } = require('playwright')); } catch (e) { ({ chromium } = require('C:/Users/cemdi/.claude/araclar/kayit/node_modules/playwright')); }

const KOK = path.resolve(__dirname, '..', '..', '..');
const ANA = 'C:/Users/cemdi/OneDrive/Masaüstü/mevzuat işi';
const CIKTI = path.join(ANA, '_yerel-veri-kasasi', 'tellal-reklam'), IS = path.join(CIKTI, 'urun-demo');
const FF = (() => { const p = 'C:/Users/cemdi/AppData/Local/Microsoft/WinGet/Packages/Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe/ffmpeg-9.0-full_build/bin/ffmpeg.exe'; return fs.existsSync(p) ? p : 'ffmpeg'; })();
const ff = a => execFileSync(FF, ['-nostdin', '-y', '-v', 'error', ...a], { stdio: 'inherit' });
const md = fs.readFileSync(path.join(KOK, 'pazarlama', 'reklam', 'instagram-urun-demo.md'), 'utf8');
const SATIR = {}; for (const m of md.matchAll(/^(\d+)\. (.+)$/gm)) SATIR[m[1]] = m[2].trim();
const S = n => { if (!SATIR[n]) { console.error(`METİN KAPISI: md'de ${n}. satır yok`); process.exit(3); } return SATIR[n]; };

// [tür, yazı/ayar, süre]; sarı = vurgu
const AKIS = [['yazi', [S(1), '#ffffff'], 2.3], ['yazi', [S(2), '#f5b301'], 2.1], ['demo', null, 8.0],
  ['yazi', [S(3), '#ffffff'], 1.5], ['yazi', [S(4), '#ffffff'], 2.2], ['yazi', [S(5), '#f5b301'], 2.4],
  ['yazi', [S(6), '#ffffff'], 1.8], ['yazi', [S(7), '#f5b301'], 1.6]];

const sayfaHtml = (yazi, renk) => `<!doctype html><meta charset="utf-8"><style>html,body{margin:0;width:1080px;height:1920px;background:#000;display:flex;align-items:center;justify-content:center}
div{width:900px;text-align:center;color:${renk};font:900 92px/1.18 "Segoe UI",Arial,sans-serif;letter-spacing:-1px}</style><div>${yazi.replace(/[&<>]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;' }[c]))}</div>`;
const cerceveHtml = `<!doctype html><style>html,body{margin:0;width:1080px;height:1920px;background:transparent}
.t{position:absolute;left:290px;top:260px;width:500px;height:1082px;border-radius:56px;box-shadow:0 0 0 14px #2a2f36,0 0 0 16px #555,0 30px 80px rgba(255,255,255,.08)}</style><div class="t"></div>`;

(async () => {
  fs.rmSync(IS, { recursive: true, force: true }); fs.mkdirSync(IS, { recursive: true });
  const b = await chromium.launch();
  /* 1) gerçek ekran kaydı */
  const c = await b.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2, isMobile: true, hasTouch: true, recordVideo: { dir: IS, size: { width: 780, height: 1688 } } });
  await c.route('**/*', r => { const q = r.request(); if (q.method() !== 'GET' && /supabase|goatcounter|rest\/v1|functions/.test(q.url())) return r.abort(); return r.continue(); });
  const t0 = Date.now(); const p = await c.newPage();
  await p.goto('https://tetikte.com/kaydir/vitrin/ornek-sgs.html', { waitUntil: 'networkidle' }); await p.waitForTimeout(1500);
  const bas = (Date.now() - t0) / 1000 - 0.6;
  await p.tap('button.sik >> nth=0'); await p.waitForTimeout(3000);
  await p.getByText('Ayrıntılı açıklama').first().tap(); await p.waitForTimeout(1400);
  await p.mouse.wheel(0, 380); await p.waitForTimeout(2600);
  const kayit = await p.video().path(); await c.close();
  /* 2) yazı sayfaları + telefon çerçevesi */
  const pg = await b.newPage({ viewport: { width: 1080, height: 1920 } });
  for (let i = 0; i < AKIS.length; i++) if (AKIS[i][0] === 'yazi') {
    await pg.setContent(sayfaHtml(...AKIS[i][1]));
    const tas = await pg.evaluate(() => { const r = document.querySelector('div').getBoundingClientRect(); return r.top < 270 || r.bottom > 1248 || r.left < 43 || r.right > 1037; });
    if (tas) { console.error(`GÜVENLİ ALAN: sahne ${i + 1}`); process.exit(4); }
    await pg.screenshot({ path: path.join(IS, `y${i}.png`) });
  }
  await pg.setContent(cerceveHtml); await pg.screenshot({ path: path.join(IS, 'cerceve.png'), omitBackground: true });
  await b.close();
  /* 3) kurgu */
  const kod = ['-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-crf', '18', '-preset', 'medium', '-r', '30'];
  const ak = ['-c:a', 'aac', '-b:a', '192k', '-ar', '44100', '-ac', '2'];
  const sessiz = d => ['-f', 'lavfi', '-t', d, '-i', 'anullsrc=r=44100:cl=stereo'];
  const parca = AKIS.map(([tur, , sure], i) => {
    const cik = path.join(IS, `p${i}.mp4`), d = sure.toFixed(2), sol = `fade=t=in:st=0:d=0.2,fade=t=out:st=${(sure - 0.2).toFixed(2)}:d=0.2`;
    if (tur === 'yazi') ff(['-loop', '1', '-t', d, '-i', path.join(IS, `y${i}.png`), ...sessiz(d), '-vf', `fps=30,${sol},format=yuv420p`, '-map', '0:v', '-map', '1:a', ...kod, ...ak, '-shortest', cik]);
    else ff(['-ss', bas.toFixed(2), '-t', d, '-i', kayit, '-loop', '1', '-t', d, '-i', path.join(IS, 'cerceve.png'), ...sessiz(d), '-filter_complex',
      // Playwright kaydı 1x çiziyor ve 780×1688'in sol üst 390×844'üne koyuyor (01.11 ölçüldü) → önce kırp, sonra büyüt
      `color=c=black:s=1080x1920:r=30:d=${d}[z];[0:v]crop=390:844:0:0,scale=500:1082:flags=lanczos,setsar=1[e];[z][e]overlay=290:260[a];[a][1:v]overlay=0:0,fps=30,${sol},format=yuv420p[v]`,
      '-map', '[v]', '-map', '2:a', ...kod, ...ak, '-shortest', cik]);
    return cik;
  });
  const kap = path.join(IS, 'kap.mp4');
  ff(['-i', path.join(ANA, '_yerel-veri-kasasi', 'ses-yarisma', 'kapanis', 'kap-A.mp4'), '-vf', 'scale=1080:1920,fps=30,setsar=1,format=yuv420p', ...kod, ...ak, kap]);
  fs.writeFileSync(path.join(IS, 'liste.txt'), [...parca, kap].map(x => `file '${x.replace(/\\/g, '/')}'`).join('\n'));
  const film = path.join(CIKTI, 'URUN-DEMO.mp4');
  ff(['-f', 'concat', '-safe', '0', '-i', path.join(IS, 'liste.txt'), '-c', 'copy', '-movflags', '+faststart', film]);
  console.log(`film: ${film}`);
})().catch(e => { console.error(e); process.exit(1); });
