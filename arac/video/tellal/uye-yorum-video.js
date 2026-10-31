#!/usr/bin/env node
/* ============================================================================
   ÜYE YORUMLARI + TETİKTE'YLE BİR GÜN · REELS VİDEOSU (01.11.2026, Cem "video gibi yapalım, 4 sayfadan fazla").
   8 GERÇEK Instagram yorumu (instagram-uye-yorumlari-kaydirma.md) + 3 senaryo sahnesi (instagram-tetikteyle-bir-gun.md)
   + kapanış + kap-A. Uydurma yorum YOK. Bedel 0 (yalnız kare + ffmpeg).
   METİN KAPISI: her yazı iki md'nin satırlarından (exit 3). GÜVENLİ ALAN: Reels üst 270 · alt 1248 · yan 43 (exit 4).
   Kurgu: her sahne ayrı mp4 (giriş/çıkış solması + sessiz ses), concat demuxer ile sırayla (30.10: çok girdili tek grafik kilitlendi).
   Kullanım: node arac/video/tellal/uye-yorum-video.js → <kasa>/tellal-reklam/UYE-YORUM-VIDEO.mp4
   🚫 GÖRMEZ: müzik (web yüklemesinde eklenemez; telefondan eklenir) · yorumun hâlâ yayında olup olmadığı.
   ============================================================================ */
'use strict';
const fs = require('fs'), path = require('path'), { execFileSync } = require('child_process');
let chromium; try { ({ chromium } = require('playwright')); } catch (e) { ({ chromium } = require('C:/Users/cemdi/.claude/araclar/kayit/node_modules/playwright')); }

const KOK = path.resolve(__dirname, '..', '..', '..');
const ANA = 'C:/Users/cemdi/OneDrive/Masaüstü/mevzuat işi';
const CIKTI = path.join(ANA, '_yerel-veri-kasasi', 'tellal-reklam');
const FF = (() => { const p = 'C:/Users/cemdi/AppData/Local/Microsoft/WinGet/Packages/Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe/ffmpeg-9.0-full_build/bin/ffmpeg.exe'; return fs.existsSync(p) ? p : 'ffmpeg'; })();
const ff = a => execFileSync(FF, ['-nostdin', '-y', '-v', 'error', ...a], { stdio: 'inherit' });
const oku = ad => { const t = fs.readFileSync(path.join(KOK, 'pazarlama', 'reklam', ad), 'utf8'), o = {}; for (const m of t.matchAll(/^(\d+)\. (.+)$/gm)) o[m[1]] = m[2].trim(); return n => { if (!o[n]) { console.error(`METİN KAPISI: ${ad} ${n}. satır yok`); process.exit(3); } return o[n]; }; };
const Y = oku('instagram-uye-yorumlari-kaydirma.md'), G = oku('instagram-tetikteyle-bir-gun.md');

const yorum = (y, k) => ({ baslik: Y(1), altbaslik: Y(2).replace(/ · kaydır →$/, ''), kartlar: [[Y(y), `${Y(k)} · ${Y(24)}`]] });
const sahne = (a, b, c) => ({ ust: G(1), not: G(2), sahne: [G(a), G(b), G(c)] });
const SAHNELER = [
  [{ baslik: Y(1), altbaslik: Y(2).replace(/ · kaydır →$/, '') }, 2.0],
  [yorum(3, 4), 3.6], [yorum(5, 6), 2.8], [yorum(7, 8), 3.6], [yorum(9, 10), 3.4],
  [yorum(11, 12), 3.4], [yorum(13, 14), 3.8], [yorum(15, 16), 3.2], [yorum(17, 18), 2.8],
  [sahne(3, 4, 5), 4.0], [sahne(6, 7, 8), 3.6], [sahne(9, 10, 11), 3.8],
  [{ son: [Y(19), Y(20), Y(21), Y(22), Y(23)] }, 3.6],
];

(async () => {
  const kareDiz = path.join(CIKTI, 'uye-yorum-video'); fs.rmSync(kareDiz, { recursive: true, force: true }); fs.mkdirSync(kareDiz, { recursive: true });
  const tarayici = await chromium.launch();
  const url = 'file:///' + path.join(__dirname, 'uye-yorumlari-kaydirma.html').replace(/\\/g, '/');
  for (let i = 0; i < SAHNELER.length; i++) {
    const sayfa = await tarayici.newPage({ viewport: { width: 1080, height: 1920 } });
    await sayfa.goto(url);
    await sayfa.evaluate(v => window.kur(v), { sayfa: SAHNELER[i][0], sira: i, toplam: SAHNELER.length, dikey: true });
    const sorun = await sayfa.evaluate(() => {
      const o = [], s = document.getElementById('sayfa');
      if (s.scrollHeight > s.clientHeight + 1) o.push(`taşıyor ${s.scrollHeight}>${s.clientHeight}`);
      for (const e of s.querySelectorAll('div')) {
        if (!e.childNodes.length || e.children.length > 1 && !e.classList.contains('soz')) continue;
        const g = document.createRange(); g.selectNodeContents(e); const r = g.getBoundingClientRect();
        if (r.width && (r.left < 43 || r.right > 1037 || r.top < 270 || r.bottom > 1248)) o.push(e.className || 'div');
      }
      return o;
    });
    if (sorun.length) { console.error(`GÜVENLİ ALAN (sahne ${i + 1}): ${sorun.join(', ')}`); process.exit(4); }
    await sayfa.screenshot({ path: path.join(kareDiz, `s${String(i).padStart(2, '0')}.png`) });
  }
  await tarayici.close();
  console.log(`güvenli alan: ${SAHNELER.length} sahnenin hepsi içeride`);

  const kod = ['-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-crf', '18', '-preset', 'medium', '-r', '30'];
  const ak = ['-c:a', 'aac', '-b:a', '192k', '-ar', '44100', '-ac', '2'];
  const parcalar = SAHNELER.map(([, sure], i) => {
    const cik = path.join(kareDiz, `p${String(i).padStart(2, '0')}.mp4`), d = sure.toFixed(2);
    ff(['-loop', '1', '-t', d, '-i', path.join(kareDiz, `s${String(i).padStart(2, '0')}.png`), '-f', 'lavfi', '-t', d, '-i', 'anullsrc=r=44100:cl=stereo',
        '-vf', `scale=1080:1920,fps=30,fade=t=in:st=0:d=0.25,fade=t=out:st=${(sure - 0.25).toFixed(2)}:d=0.25,format=yuv420p`,
        '-map', '0:v', '-map', '1:a', ...kod, ...ak, '-shortest', cik]);
    return cik;
  });
  const kap = path.join(kareDiz, 'kap.mp4');
  ff(['-i', path.join(ANA, '_yerel-veri-kasasi', 'ses-yarisma', 'kapanis', 'kap-A.mp4'), '-vf', 'scale=1080:1920,fps=30,setsar=1,format=yuv420p', ...kod, ...ak, kap]);
  const liste = path.join(kareDiz, 'liste.txt');
  fs.writeFileSync(liste, [...parcalar, kap].map(p => `file '${p.replace(/\\/g, '/')}'`).join('\n'));
  const film = path.join(CIKTI, 'UYE-YORUM-VIDEO.mp4');
  ff(['-f', 'concat', '-safe', '0', '-i', liste, '-c', 'copy', '-movflags', '+faststart', film]);
  console.log(`film: ${film}`);
})().catch(e => { console.error(e); process.exit(1); });
