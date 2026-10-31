#!/usr/bin/env node
/* ============================================================================
   SON GÜN REELS + HİKÂYE (31.10.2026, Cem "kampanya yarın son, kaçırma son fırsatı gibi" + "yarın SGS testini açıklayacağız,
   ders ders çözecek, bitince yanlışını görecek ve öğrenecek"). Bedel 0: yeni klip/ses yok, 30.10 tellal filmi kesilir.
   Kurgu (çıkış zamanı ← film zamanı):
     A  0,00– 9,30 ← 0,00– 9,30   r1 r2 r3 r4 + YK kâğıdı   · üstüne "YARIN SON GÜN" damgası
     B  9,30–14,42 ← 15,30–20,42  r8 + soru kartı (tuzaklar kırmızı, doğru yeşil, dayanak)
     C 14,42–17,07 ← 22,77–25,42  r10 "Duyduk duymadık demeyin! Bir Kasım gece yarısı!"
     T 17,07–20,57   lacivert tanıtım kartı: YARIN AÇILIYOR · SGS · Son 20 Gün sınavı · 3 adım (zil sesi)
     K 20,57–      ← 25,42–son    kap-A "Yanlışını böyle öğrenirsin."
   METİN KAPISI: yeni yazılar pazarlama/reklam/instagram-son-gun-sgs-testi.md "Ekrandaki yazı" + "Hikâye görseli" satırlarından (exit 3).
   GÜVENLİ ALAN KAPISI: Reels üst %14 · alt %35 · yan %6 (exit 4).
   Kullanım: node arac/video/tellal/son-gun.js [--metin <md>] [--ad <önek>] [--hikaye]
             → <kasa>/tellal-reklam/<önek>-SGS.mp4 + <önek>-HIKAYE.png + <önek>-GONDERI-4x5.png (önek vars. SON-GUN)
   🚫 GÖRMEZ: filmden gelen yazılar (30.10 bas.js kapısından geçti) · hikâyeye telefondan eklenen çıkartmalar · yazının okunma süresi.
   ============================================================================ */
'use strict';
const fs = require('fs'), path = require('path'), { execFileSync } = require('child_process');
let chromium; try { ({ chromium } = require('playwright')); } catch (e) { ({ chromium } = require('C:/Users/cemdi/.claude/araclar/kayit/node_modules/playwright')); }

const KOK = path.resolve(__dirname, '..', '..', '..');
const ANA = 'C:/Users/cemdi/OneDrive/Masaüstü/mevzuat işi';
const CIKTI = path.join(ANA, '_yerel-veri-kasasi', 'tellal-reklam');
const FILM = path.join(CIKTI, 'TELLAL-YK-KARARI.mp4');
const FPS = 25;
const FF = (() => { const p = 'C:/Users/cemdi/AppData/Local/Microsoft/WinGet/Packages/Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe/ffmpeg-9.0-full_build/bin/ffmpeg.exe'; return fs.existsSync(p) ? p : 'ffmpeg'; })();
const FP = FF.replace(/ffmpeg\.exe$/, 'ffprobe.exe');
const ff = a => execFileSync(FF, ['-nostdin', '-y', '-v', 'error', ...a], { stdio: 'inherit' });
const sure = f => parseFloat(execFileSync(FP, ['-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', f]).toString());

/* ---- metin kapısı ---- */
// --metin <md> + --ad <önek>: aynı tasarımın başka sürümü (1 Kasım: instagram-son-gun-bugun.md → SON-GUN-BUGUN-*)
const arg = n => { const i = process.argv.indexOf(n); return i > -1 ? process.argv[i + 1] : null; };
const MD = arg('--metin') || path.join('pazarlama', 'reklam', 'instagram-son-gun-sgs-testi.md');
const AD = arg('--ad') || 'SON-GUN';
const md = fs.readFileSync(path.resolve(KOK, MD), 'utf8');
const SATIR = {}; for (const m of md.matchAll(/^(\d+)\. (.+)$/gm)) SATIR[m[1]] = m[2].trim();
const S = n => { if (!SATIR[n]) { console.error(`METİN KAPISI: md'de ${n}. satır yok`); process.exit(3); } return SATIR[n]; };

const filmSure = sure(FILM);
const PARCA = [['A', 0, 9.30], ['B', 15.30, 20.42], ['C', 22.77, 25.42], ['T', null, 4.50], ['K', 25.42, filmSure]];
let t = 0; const CIZELGE = {};
for (const [ad, a, b] of PARCA) { const d = a === null ? b : b - a; CIZELGE[ad] = [t, t + d]; t += d; }
const SON = t;

const V = {
  damga: S(1), damgaAlt: S(2), damgaZaman: [0.30, 4.40],
  ust: S(3), baslik: S(4), baslikAlt: S(13), guven: S(15), adimlar: [S(5), S(6), S(7)], tanitZaman: CIZELGE.T,
};

(async () => {
  const tarayici = await chromium.launch();
  const sayfa = await tarayici.newPage({ viewport: { width: 720, height: 1280 }, deviceScaleFactor: 1 });
  const url = 'file:///' + path.join(__dirname, 'son-gun.html').replace(/\\/g, '/');
  await sayfa.goto(url);
  await sayfa.evaluate(v => window.kur(v), V);
  const kareDiz = path.join(CIKTI, 'son-gun-katman');
  fs.rmSync(kareDiz, { recursive: true, force: true }); fs.mkdirSync(kareDiz, { recursive: true });
  const YALNIZ_HIKAYE = process.argv.includes('--hikaye');   // yalnız hikâye görseli yeniden çizilir, film dokunulmaz
  const n = Math.round(FPS * SON), tasma = [];
  for (let i = 0; i < (YALNIZ_HIKAYE ? 0 : n); i++) {
    const x = await sayfa.evaluate(s => { window.kare(s); return window.alanDisi(); }, i / FPS);
    if (x.length) tasma.push(`${(i / FPS).toFixed(2)} sn: ${x.join(' | ')}`);
    await sayfa.screenshot({ path: path.join(kareDiz, String(i).padStart(4, '0') + '.png'), omitBackground: true });
  }
  if (tasma.length) { console.error(`GÜVENLİ ALAN KIRMIZI — ${tasma.length} karede taşma:\n  ` + tasma.slice(0, 8).join('\n  ')); process.exit(4); }
  if (!YALNIZ_HIKAYE) console.log(`güvenli alan: ${n} karenin hepsi içeride`);

  /* ---- hikâye görseli: filmden zil karesi + yazılar, 1080×1920 ---- */
  const foto = path.join(CIKTI, 'son-gun-foto.png');
  ff(['-ss', '1.60', '-i', FILM, '-frames:v', '1', foto]);
  const hs = await tarayici.newPage({ viewport: { width: 720, height: 1280 }, deviceScaleFactor: 1.5 });
  await hs.goto(url);
  await hs.evaluate(v => window.kur(v), { ...V, hikaye: { foto: 'file:///' + foto.replace(/\\/g, '/'), s1: S(14), s2: S(10), s3: S(15), s4: S(12) } });
  await hs.waitForFunction(() => document.getElementById('hkFoto').complete);
  if (S(8) !== S(1)) { console.error('METİN KAPISI: hikâye damgası (8) Reels damgasıyla (1) aynı değil'); process.exit(3); }
  const hikaye = path.join(CIKTI, `${AD}-HIKAYE.png`);
  await hs.screenshot({ path: hikaye });
  await tarayici.close();
  console.log(`hikâye: ${hikaye}`);
  // akış gönderisi 4:5 (Instagram fotoğrafı en çok 4:5; 9:16 kırpılır): başlıktan kutunun altına kadar
  const gonderi = path.join(CIKTI, `${AD}-GONDERI-4x5.png`);
  ff(['-i', hikaye, '-vf', 'crop=1080:1420:0:160,scale=-2:1350,pad=1080:1350:(ow-iw)/2:0:color=0x10233a', gonderi]);
  console.log(`gönderi: ${gonderi}`);
  if (YALNIZ_HIKAYE) return;

  /* ---- parçalar aynı biçimde, concat demuxer ile sırayla (30.10: tek grafik kilitlendi) ---- */
  const kod = ['-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-crf', '18', '-preset', 'medium', '-r', String(FPS)];
  const ak = ['-c:a', 'aac', '-b:a', '192k', '-ar', '44100', '-ac', '2'];
  const zil = path.join(CIKTI, 'zil.wav');
  const dosyalar = PARCA.map(([ad, a, b]) => {
    const cik = path.join(CIKTI, `songun-${ad}.mp4`);
    if (a === null) ff(['-f', 'lavfi', '-i', `color=c=0x0f2338:s=720x1280:r=${FPS}:d=${b}`, '-i', zil, '-filter_complex',
      `[1:a]aformat=channel_layouts=stereo,aresample=44100,apad,atrim=0:${b}[a]`, '-map', '0:v', '-map', '[a]', ...kod, ...ak, '-t', String(b), cik]);
    else ff(['-ss', a.toFixed(2), '-i', FILM, '-t', (b - a).toFixed(2), ...kod, ...ak, cik]);
    return cik;
  });
  const liste = path.join(CIKTI, 'songun.txt');
  fs.writeFileSync(liste, dosyalar.map(p => `file '${p.replace(/\\/g, '/')}'`).join('\n'));
  const taban = path.join(CIKTI, 'songun-taban.mp4');
  ff(['-f', 'concat', '-safe', '0', '-i', liste, '-c', 'copy', taban]);
  const film = path.join(CIKTI, `${AD}-SGS.mp4`);
  ff(['-i', taban, '-framerate', String(FPS), '-i', path.join(kareDiz, '%04d.png'), '-filter_complex',
      '[1:v]format=rgba[kat];[0:v][kat]overlay=0:0:eof_action=pass,format=yuv420p[v]', '-map', '[v]', '-map', '0:a',
      ...kod, '-c:a', 'copy', '-movflags', '+faststart', film]);
  console.log(`film: ${film} (${sure(film).toFixed(2)} sn)`);
})().catch(e => { console.error(e); process.exit(1); });
