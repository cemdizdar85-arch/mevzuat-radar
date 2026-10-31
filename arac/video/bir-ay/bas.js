#!/usr/bin/env node
/* ============================================================================
   BİR AY KALDI REKLAMI — kurgu (21.10.2026, Cem "sınava az kaldı reklamı, hem video hem yazı")
   Bedel 0: YZ klibi/sesi yok. Görüntü sahne.html'den kare kare, ses ffmpeg'le üretilen saat tıkı.

   METİN KAPISI: ekrandaki her satır pazarlama/reklam/meta-bir-ay-kaldi.md'nin "Ekrandaki yazı · <sınav>"
   bölümünden OKUNUR (film, reklam metni kapısından geçmiş metinden sapamaz); bölümde 9 satır yoksa durur (exit 3).
   GÜVENLİ ALAN KAPISI: Meta Reels 9:16'da üst %14, alt %35, yanlar %6 yazısız (sayac/bas.js ile aynı ölçü).
   Tek karede taşma varsa film basılmaz (exit 4).

   Kullanım: node arac/video/bir-ay/bas.js --sinav sgs|yet|hepsi [--cikti <klasör>] [--onizleme]
   Çıktı: <cikti>/bir-ay-<sinav>.mp4 (720×1280, 25 fps, 19 sn). Medya depoya GİRMEZ.
   🚫 GÖRMEZ: yazının okunabilirliği (süre yeterli mi) · renk körlüğü · Meta'nın kendi kırpması.
   ============================================================================ */
'use strict';
const fs = require('fs'), path = require('path'), { execFileSync } = require('child_process');
let chromium; try { ({ chromium } = require('playwright')); } catch (e) { ({ chromium } = require('C:/Users/cemdi/.claude/araclar/kayit/node_modules/playwright')); }

const KOK = path.resolve(__dirname, '..', '..', '..');
const arg = n => { const i = process.argv.indexOf(n); return i > -1 ? process.argv[i + 1] : null; };
const SINAV = (arg('--sinav') || 'sgs').toLowerCase();
const CIKTI = arg('--cikti') || path.resolve(KOK, '..', '_yerel-veri-kasasi', 'bir-ay-reklami');
const ONIZLEME = process.argv.includes('--onizleme');
const FPS = 25, SURE = 19;
const FF = (() => { const p = 'C:/Users/cemdi/AppData/Local/Microsoft/WinGet/Packages/Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe/ffmpeg-9.0-full_build/bin/ffmpeg.exe'; return fs.existsSync(p) ? p : 'ffmpeg'; })();

const md = fs.readFileSync(path.join(KOK, 'pazarlama', 'reklam', 'meta-bir-ay-kaldi.md'), 'utf8');
const BOLUM = { sgs: ['Staja Giriş', 'SMMM Staja Giriş · 21 Kasım'], yet: ['Yeterlilik', 'SMMM Yeterlilik · 28 Kasım'] };
function veriKur(sinav) {
  const [ad, tarih] = BOLUM[sinav];
  const m = new RegExp(`## Ekrandaki yazı · ${ad} \\(kare kare\\)\\r?\\n([\\s\\S]*?)(?=\\r?\\n## )`).exec(md);
  if (!m) { console.error(`METİN KAPISI: "${ad}" bölümü yok`); process.exit(3); }
  const satirlar = [...m[1].matchAll(/^\d+\. (.+)$/gm)].map(x => x[1].trim());
  if (satirlar.length !== 9 || !/^Reklam$/m.test(m[1])) { console.error(`METİN KAPISI: ${ad} bölümünde 9 satır + "Reklam" yok (${satirlar.length})`); process.exit(3); }
  if (!md.includes(tarih)) { console.error(`METİN KAPISI: tarih satırı md'de yok: ${tarih}`); process.exit(3); }
  return { etiket: 'Reklam', tarih, satirlar };
}
function ff(argv) { execFileSync(FF, ['-nostdin', '-y', '-v', 'error', ...argv], { stdio: 'inherit' }); }

async function bas(sinav, tarayici) {
  const veri = veriKur(sinav);
  const sayfa = await tarayici.newPage({ viewport: { width: 360, height: 640 }, deviceScaleFactor: 2 });
  await sayfa.goto('file:///' + path.join(__dirname, 'sahne.html').replace(/\\/g, '/'));
  await sayfa.evaluate(v => window.kur(v), veri);
  const kareDiz = path.join(CIKTI, `kareler-${sinav}`);
  fs.rmSync(kareDiz, { recursive: true, force: true }); fs.mkdirSync(kareDiz, { recursive: true });
  const anlar = ONIZLEME ? [1.2, 3.3, 5.9, 8.0, 10.2, 12.8, 15.0, 17.5] : Array.from({ length: FPS * SURE }, (_, i) => i / FPS);
  const tasmalar = [];
  for (let i = 0; i < anlar.length; i++) {
    const tasma = await sayfa.evaluate(t => { window.kare(t); return window.alanDisi(); }, anlar[i]);
    if (tasma.length) tasmalar.push(`${anlar[i].toFixed(2)} sn: ${tasma.join(' | ')}`);
    await sayfa.screenshot({ path: path.join(kareDiz, (ONIZLEME ? `onizleme-${anlar[i].toFixed(1)}s` : String(i).padStart(4, '0')) + '.png') });
  }
  await sayfa.close();
  if (tasmalar.length) { console.error(`GÜVENLİ ALAN KIRMIZI — ${tasmalar.length} karede taşma:\n  ` + tasmalar.slice(0, 6).join('\n  ')); process.exit(4); }
  console.log(`güvenli alan: ${anlar.length} karenin hepsi içeride (${sinav})`);
  if (ONIZLEME) { console.log(`önizleme: ${kareDiz}`); return; }

  /* ses: 0–8 sn her saniye tık (son 3'ü sıklaşır), 6,6 sn derin "çözülme" tonu, 15,8 sn kapanış tonu */
  const tik = path.join(CIKTI, 'tik.wav'), coz = path.join(CIKTI, 'coz.wav'), kap = path.join(CIKTI, 'kap.wav');
  if (!fs.existsSync(tik)) ff(['-f', 'lavfi', '-i', 'sine=frequency=1500:duration=0.035', '-af', 'afade=t=out:st=0.02:d=0.015,volume=0.35', tik]);
  if (!fs.existsSync(coz)) ff(['-f', 'lavfi', '-i', 'sine=frequency=180:duration=0.6', '-af', 'afade=t=out:st=0.1:d=0.5,volume=0.6', coz]);
  if (!fs.existsSync(kap)) ff(['-f', 'lavfi', '-i', 'sine=frequency=660:duration=0.5', '-af', 'afade=t=out:st=0.05:d=0.45,volume=0.3', kap]);
  const tikAnlari = [0.3, 1.3, 2.3, 3.3, 4.3, 5.0, 5.6, 6.1];
  const fc = [
    `[1:a]asplit=${tikAnlari.length}${tikAnlari.map((_, i) => `[t${i}]`).join('')}`,
    ...tikAnlari.map((a, i) => `[t${i}]adelay=${Math.round(a * 1000)}|${Math.round(a * 1000)}[d${i}]`),
    `[2:a]adelay=6600|6600[c]`, `[3:a]adelay=15800|15800[k]`,
    `${tikAnlari.map((_, i) => `[d${i}]`).join('')}[c][k]amix=inputs=${tikAnlari.length + 2}:normalize=0,apad,atrim=0:${SURE},alimiter=limit=0.9[a]`,
  ].join(';');
  const film = path.join(CIKTI, `bir-ay-${sinav}.mp4`);
  ff(['-framerate', String(FPS), '-i', path.join(kareDiz, '%04d.png'), '-i', tik, '-i', coz, '-i', kap,
      '-filter_complex', fc, '-map', '0:v', '-map', '[a]', '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-crf', '18', '-preset', 'medium',
      '-c:a', 'aac', '-b:a', '160k', '-ar', '44100', '-t', String(SURE), '-movflags', '+faststart', film]);
  fs.rmSync(kareDiz, { recursive: true, force: true });
  console.log(`film: ${film}`);
}

(async () => {
  fs.mkdirSync(CIKTI, { recursive: true });
  const tarayici = await chromium.launch();
  try { for (const s of SINAV === 'hepsi' ? ['sgs', 'yet'] : [SINAV]) await bas(s, tarayici); }
  finally { await tarayici.close(); }
})().catch(e => { console.error(e); process.exit(1); });
