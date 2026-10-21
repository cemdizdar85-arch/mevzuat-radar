#!/usr/bin/env node
/* ============================================================================
   NÖBETÇİ ÇİZEREK ÇÖZÜYOR — kurgu (21.10.2026). Girdi: kayit.js'in kayit.webm + olaylar.json, ses.js'in sesleri.
   Kurgu: açılış kartı (3 sn) → sitenin gerçek kaydı telefon çerçevesinde (marka zemini, üstte "Nöbetçi çizerek çözüyor")
   → kapanış kartı (3 sn). Ses: s0 açılışta, s1…s8 her kalem adımının tıklandığı anda (olaylar.json) → ses ile görüntü eş.
   METİN KAPISI: eklenen yazılar pazarlama/reklam/instagram-nobetci-cizerek-cozuyor.md "## Ekrana eklenen yazılar"dan okunur.
   GÜVENLİ ALAN (organik Reels 1080×1920: üst 220 · alt 420 · sağ 150×500 y1000): telefon x 240–840, y 170–1468; başlık y 80–150
   (Reels'in üst simgeleri yazısız bölgede kalmalı → başlık 220 altında DEĞİL; ölçüldü: başlık y≥96 ve x 120–960 ortada, üst sol/sağ
   simgelerle çakışmaz — gözle bakılır).
   Kullanım: node arac/video/cizerek/bas.js [--ses-alis 2]   → <kasa>/nobetci-cizerek/nobetci-cizerek.mp4
   🚫 GÖRMEZ: kayıttaki site içeriğinin doğruluğu (sitenin kendi kapıları) · ses tonlaması (kulakla).
   ============================================================================ */
'use strict';
const fs = require('fs'), path = require('path'), { execFileSync } = require('child_process');
let chromium; try { ({ chromium } = require('playwright')); } catch (e) { ({ chromium } = require('C:/Users/cemdi/.claude/araclar/kayit/node_modules/playwright')); }
const KOK = path.resolve(__dirname, '..', '..', '..');
const arg = n => { const i = process.argv.indexOf(n); return i > -1 ? process.argv[i + 1] : null; };
const ALIS = arg('--ses-alis') || '2';
const DIZ = 'C:/Users/cemdi/OneDrive/Masaüstü/mevzuat işi/_yerel-veri-kasasi/nobetci-cizerek';
const FF = 'C:/Users/cemdi/AppData/Local/Microsoft/WinGet/Packages/Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe/ffmpeg-9.0-full_build/bin/ffmpeg.exe';
const ff = a => execFileSync(FF, ['-nostdin', '-y', '-v', 'error', ...a], { stdio: 'inherit' });
const ACILIS = 3.0, KAPANIS = 3.2, TEL = { x: 240, y: 170, w: 600, h: 1298 };

const md = fs.readFileSync(path.join(KOK, 'pazarlama', 'reklam', 'instagram-nobetci-cizerek-cozuyor.md'), 'utf8').replace(/<!--[\s\S]*?-->\r?\n?/g, '');
const Y = (/## Ekrana eklenen yazılar\r?\n([\s\S]*?)(?=\r?\n## )/.exec(md) || [, ''])[1].split(/\r?\n/).map(s => s.trim()).filter(Boolean);
if (Y.length !== 5 || Y[0] !== 'Reklam') { console.error('METİN KAPISI: "Ekrana eklenen yazılar" 5 satır olmalı (' + Y.length + ')'); process.exit(3); }
const [ETIKET, HOOK, BASLIK, KAPANIS_CUMLE, ADRES] = Y;
const { olay } = JSON.parse(fs.readFileSync(path.join(DIZ, 'olaylar.json'), 'utf8'));
const an = ad => { const o = olay.find(x => x.ad === ad); if (!o) { console.error('olay yok: ' + ad); process.exit(3); } return o.ms / 1000; };
const BAS = an('sayfa'), SON = an('son');
const KAYIT_SURE = SON - BAS;

const CSS = `:root{--zemin:#0b1626;--ink:#f4f6fa;--soluk:#9fb0c8;--amber:#f5a524;--amber2:#ffc24b;--kirmizi:#f87171}
*{margin:0;padding:0;box-sizing:border-box}body{width:1080px;height:1920px;overflow:hidden;color:var(--ink);font-family:Inter,"Segoe UI",sans-serif;
background:radial-gradient(circle at 80% 8%,color-mix(in srgb,var(--amber) 16%,transparent),transparent 42%),radial-gradient(circle at 10% 90%,color-mix(in srgb,#3b82f6 14%,transparent),transparent 45%),
repeating-linear-gradient(0deg,color-mix(in srgb,var(--soluk) 6%,transparent) 0 2px,transparent 2px 72px),repeating-linear-gradient(90deg,color-mix(in srgb,var(--soluk) 6%,transparent) 0 2px,transparent 2px 72px),var(--zemin)}
.et{position:absolute;left:66px;top:236px;font-size:28px;font-weight:600;color:color-mix(in srgb,var(--ink) 70%,transparent)}`;
const FONT = '<link href="https://fonts.googleapis.com/css2?family=Inter:wght@600;800;900&display=block" rel="stylesheet">';
const esc = s => s.replace(/&/g, '&amp;').replace(/</g, '&lt;');
const sayfalar = {
  zemin: `<style>${CSS}
    .bas{position:absolute;left:0;right:0;top:92px;text-align:center;font-size:50px;font-weight:900;letter-spacing:-1.5px}
    .bas b{color:var(--amber2)} .tel{position:absolute;left:${TEL.x - 14}px;top:${TEL.y - 14}px;width:${TEL.w + 28}px;height:${TEL.h + 28}px;border-radius:58px;
    background:#05080e;box-shadow:0 0 0 3px color-mix(in srgb,var(--amber) 45%,#1c2a40),0 30px 80px #000c,0 0 70px color-mix(in srgb,var(--amber) 18%,transparent)}</style>
    <div class="bas">✍️ ${esc(BASLIK).replace(/(çizerek)/, '<b>$1</b>')}</div><div class="tel"></div>`,
  maske: `<style>*{margin:0}body{width:${TEL.w}px;height:${TEL.h}px;background:#000}div{width:100%;height:100%;border-radius:44px;background:#fff}</style><div></div>`,
  acilis: `<style>${CSS}.ic{position:absolute;left:90px;right:90px;top:300px;bottom:520px;display:flex;align-items:center;justify-content:center;text-align:center}
    p{font-size:92px;line-height:1.1;font-weight:900;letter-spacing:-3px}p em{font-style:normal;color:var(--kirmizi)}</style>
    <span class="et">${esc(ETIKET)}</span><div class="ic"><p>${esc(HOOK).replace(/(Yalnız %\d+'i doğruyu buldu\.)/, '<em>$1</em>')}</p></div>`,
  kapanis: `<style>${CSS}.ic{position:absolute;left:90px;right:90px;top:300px;bottom:520px;display:flex;flex-direction:column;gap:46px;align-items:center;justify-content:center;text-align:center}
    .l{width:64px;height:64px;border-radius:50%;background:var(--amber);box-shadow:0 0 0 18px color-mix(in srgb,var(--amber) 18%,transparent),0 0 70px var(--amber)}
    p{font-size:84px;line-height:1.12;font-weight:900;letter-spacing:-2.5px}.a{font-size:66px;color:var(--amber2);letter-spacing:0}</style>
    <span class="et">${esc(ETIKET)}</span><div class="ic"><div class="l"></div><p>${esc(KAPANIS_CUMLE)}</p><p class="a">${esc(ADRES)}</p></div>`,
};

(async () => {
  const t = await chromium.launch();
  for (const [ad, govde] of Object.entries(sayfalar)) {
    const boy = ad === 'maske' ? { width: TEL.w, height: TEL.h } : { width: 1080, height: 1920 };
    const p = await t.newPage({ viewport: boy });
    await p.setContent('<!doctype html><meta charset="utf-8">' + FONT + govde, { waitUntil: 'networkidle' });
    await p.evaluate(() => document.fonts.ready);
    await p.screenshot({ path: path.join(DIZ, ad + '.png') }); await p.close();
  }
  await t.close();
  /* 1) kayıt → telefon (kırp: sayfa..son, ölçekle, köşe maskesi, zemine bindir) */
  const orta = path.join(DIZ, 'orta.mp4');
  ff(['-loop', '1', '-i', path.join(DIZ, 'zemin.png'), '-ss', BAS.toFixed(3), '-t', KAYIT_SURE.toFixed(3), '-i', path.join(DIZ, 'kayit.webm'), '-loop', '1', '-i', path.join(DIZ, 'maske.png'),
      '-filter_complex', `[1:v]fps=25,scale=${TEL.w}:${TEL.h}:flags=lanczos,format=rgba[v];[2:v]format=gray,scale=${TEL.w}:${TEL.h}[m];[v][m]alphamerge[vm];[0:v][vm]overlay=${TEL.x}:${TEL.y}:shortest=1,format=yuv420p[o]`,
      '-map', '[o]', '-t', KAYIT_SURE.toFixed(3), '-r', '25', '-c:v', 'libx264', '-crf', '18', '-preset', 'medium', orta]);
  /* 2) kartlar */
  const kart = (png, sn, out) => ff(['-loop', '1', '-i', png, '-t', String(sn), '-r', '25', '-vf', 'format=yuv420p', '-c:v', 'libx264', '-crf', '18', out]);
  kart(path.join(DIZ, 'acilis.png'), ACILIS, path.join(DIZ, 'k1.mp4')); kart(path.join(DIZ, 'kapanis.png'), KAPANIS, path.join(DIZ, 'k2.mp4'));
  /* 3) birleştir + ses: s0 0,3 sn; sN = açılış + (adim-N anı − kayıt başı) + 0,25 */
  const TOPLAM = ACILIS + KAYIT_SURE + KAPANIS;
  const sesler = [{ f: 's0', at: 0.3 }, ...[1, 2, 3, 4, 5, 6, 7, 8].map(n => ({ f: 's' + n, at: ACILIS + (an('adim-' + n) - BAS) + 0.25 }))];
  const girdi = ['-i', path.join(DIZ, 'k1.mp4'), '-i', orta, '-i', path.join(DIZ, 'k2.mp4')];
  sesler.forEach(s => girdi.push('-i', path.join(DIZ, `ses-${s.f}-alis${ALIS}.mp3`)));
  const fc = `[0:v][1:v][2:v]concat=n=3:v=1:a=0[v];` + sesler.map((s, i) => `[${3 + i}:a]adelay=${Math.round(s.at * 1000)}|${Math.round(s.at * 1000)}[a${i}]`).join(';')
    + ';' + sesler.map((_, i) => `[a${i}]`).join('') + `amix=inputs=${sesler.length}:normalize=0,apad,atrim=0:${TOPLAM.toFixed(3)},loudnorm=I=-14:TP=-1.5:LRA=11[a]`;
  const film = path.join(DIZ, 'nobetci-cizerek.mp4');
  ff([...girdi, '-filter_complex', fc, '-map', '[v]', '-map', '[a]', '-c:v', 'libx264', '-crf', '18', '-preset', 'medium', '-pix_fmt', 'yuv420p',
      '-c:a', 'aac', '-b:a', '160k', '-ar', '44100', '-t', TOPLAM.toFixed(3), '-movflags', '+faststart', film]);
  /* bitmiş film denetimi için beklenen replikler */
  const sesMd = (/## Seslendirme\r?\n([\s\S]*?)(?=\r?\n## )/.exec(md) || [, ''])[1];
  fs.writeFileSync(path.join(DIZ, 'film.json'), JSON.stringify({ not: 'nobetci cizerek bitmis film', beklenen_replikler: [...sesMd.matchAll(/^s\d: (.+)$/gm)].map(x => x[1].trim()) }));
  console.log(`film: ${film} (${TOPLAM.toFixed(1)} sn) · sesler: ` + sesler.map(s => s.f + '@' + s.at.toFixed(1)).join(' '));
})().catch(e => { console.error(e); process.exit(1); });
