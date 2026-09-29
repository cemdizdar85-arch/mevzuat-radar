#!/usr/bin/env node
/* ============================================================================
   SAYAÇ REKLAMI — kurgu (29.09.2026, Cem "videoyu bu metinle kurgula")
   Bedel 0: YZ klibi yok. Görüntü sahne.html'den kare kare, ses fisilti.ps1 (ElevenLabs aboneliği)
   + ffmpeg'le üretilen sayaç tıkları.

   METİN KAPISI (bu betiğin içinde, basımdan ÖNCE): ekrana basılacak her yazı
   pazarlama/reklam/sayac-reklami.md'de BİREBİR aranır; bulunmazsa durur (exit 3).
   Böylece film, reklam metni kapısından (arac/reklam-metni-kapisi.js) geçmiş metinden sapamaz.
   Soru ve tuzak metni tek kaynaktan: veri/feda-ornek-1.json 1. soru.
   GÜVENLİ ALAN KAPISI: Meta Reels 9:16'da üst %14, alt %35, yanlar %6 yazısız kalmalı
   (facebook.com/business/help/980593475366490, 29.09 okundu). Her karede sahne.html alanDisi()
   ölçülür; tek karede taşma varsa film basılmaz (exit 4).

   Kullanım:
     node arac/video/sayac/bas.js --acilis A|B|C|hepsi --fisilti <mp3> [--cikti <klasör>] [--onizleme]
   --onizleme: yalnız 8 anahtar kare png (film basılmaz).
   Çıktı: <cikti>/sayac-<harf>.mp4 (720×1280, 25 fps, 18 sn). Medya depoya GİRMEZ (kasa).
   Sonra: node arac/video/klip-denetim.js <film> arac/video/sayac/fisilti.json  (bitmiş film denetimi)
   ============================================================================ */
'use strict';
const fs = require('fs'), path = require('path'), { execFileSync } = require('child_process');
let chromium; try { ({ chromium } = require('playwright')); } catch (e) { ({ chromium } = require('C:/Users/cemdi/.claude/araclar/kayit/node_modules/playwright')); }

const KOK = path.resolve(__dirname, '..', '..', '..');
const arg = n => { const i = process.argv.indexOf(n); return i > -1 ? process.argv[i + 1] : null; };
const ACILIS = (arg('--acilis') || 'A').toUpperCase();
const FISILTI = arg('--fisilti');
const CIKTI = arg('--cikti') || path.resolve(KOK, '..', '_yerel-veri-kasasi', 'sayac-reklami');
const ONIZLEME = process.argv.includes('--onizleme');
const FPS = 25, SURE = 18, FISILTI_BAS = 2.0;
const FF = (() => { const p = 'C:/Users/cemdi/AppData/Local/Microsoft/WinGet/Packages/Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe/ffmpeg-9.0-full_build/bin/ffmpeg.exe'; return fs.existsSync(p) ? p : 'ffmpeg'; })();

/* ---- metin: reklam dosyası + feda sorusu ---- */
const md = fs.readFileSync(path.join(KOK, 'pazarlama', 'reklam', 'sayac-reklami.md'), 'utf8');
const acilislar = {};
for (const m of md.matchAll(/^- ([ABC]): (.+)$/gm)) acilislar[m[1]] = m[2].trim();
const feda = JSON.parse(fs.readFileSync(path.join(KOK, 'veri', 'feda-ornek-1.json'), 'utf8'));
const s = Array.isArray(feda) ? feda[0] : (feda.sorular ? feda.sorular[0] : feda);
const FISILTI_HARF = 'A';
const [tuzakAd, tuzakNeden] = s.tuzaklar[FISILTI_HARF].split(' — ');
const ortak = {
  etiket: 'Reklam · Yapay zekâ ile üretilmiştir',
  soru: s.soru,
  siklar: Object.keys(s.siklar).sort().map(h => ({ h, m: s.siklar[h] })),
  fisiltiHarf: FISILTI_HARF, dogruHarf: s.dogru,
  tuzakAd, tuzakNeden,
  dogrusu: `Doğrusu ${s.dogru}) ${s.siklar[s.dogru]}`,
  kural: 'Pay eşdeğer miktarla dağıtılır, birim maliyet fiili miktara bölünür.',
  kapanis: 'Yirmi soru, bedava, üyeliksiz.',
  adres: 'tetikte.com',
};
function metinKapisi(veri) {
  const ekranda = [veri.etiket, veri.acilis, veri.soru, ...veri.siklar.map(x => `${x.h}) ${x.m}`), veri.tuzakAd, veri.tuzakNeden,
    veri.dogrusu, veri.kural, veri.kapanis, veri.adres];
  const eksik = ekranda.filter(y => !md.includes(y));
  if (eksik.length) { console.error('METİN KAPISI KIRMIZI — reklam dosyasında birebir yok:\n  ' + eksik.join('\n  ')); process.exit(3); }
  if (s.dogru === FISILTI_HARF) { console.error('fısıltı harfi DOĞRU cevap — fısıltı hep yanlış şıkkı söyler'); process.exit(3); }
}

function ff(argv) { execFileSync(FF, ['-nostdin', '-y', '-v', 'error', ...argv], { stdio: 'inherit' }); }

async function bas(harf, tarayici) {
  const veri = { ...ortak, acilis: acilislar[harf] };
  if (!veri.acilis) { console.error(`açılış kartı ${harf} reklam dosyasında yok`); process.exit(3); }
  metinKapisi(veri);
  const sayfa = await tarayici.newPage({ viewport: { width: 360, height: 640 }, deviceScaleFactor: 2 });
  await sayfa.goto('file:///' + path.join(__dirname, 'sahne.html').replace(/\\/g, '/'));
  await sayfa.evaluate(v => window.kur(v), veri);
  const kareDiz = path.join(CIKTI, `kareler-${harf}`);
  fs.rmSync(kareDiz, { recursive: true, force: true }); fs.mkdirSync(kareDiz, { recursive: true });
  const anlar = ONIZLEME ? [0.5, 1.5, 4.0, 7.9, 8.2, 10.0, 12.5, 16.5] : Array.from({ length: FPS * SURE }, (_, i) => i / FPS);
  const tasmalar = [];
  for (let i = 0; i < anlar.length; i++) {
    const tasma = await sayfa.evaluate(t => { window.kare(t); return window.alanDisi(); }, anlar[i]);
    if (tasma.length) tasmalar.push(`${anlar[i].toFixed(2)} sn: ${tasma.join(' | ')}`);
    await sayfa.screenshot({ path: path.join(kareDiz, (ONIZLEME ? `onizleme-${anlar[i].toFixed(1)}s` : String(i).padStart(4, '0')) + '.png') });
  }
  await sayfa.close();
  /* GÜVENLİ ALAN KAPISI (Meta Reels: üst %14, alt %35, yan %6 yazısız) — taşan karede film BASILMAZ */
  if (tasmalar.length) { console.error(`GÜVENLİ ALAN KIRMIZI — ${tasmalar.length} karede taşma:\n  ` + tasmalar.slice(0, 6).join('\n  ')); process.exit(4); }
  console.log(`güvenli alan: ${anlar.length} karenin hepsi içeride`);
  if (ONIZLEME) { console.log(`önizleme: ${kareDiz}`); return; }

  /* ses: sayaç tıkları (1..7 sn), 8. sn düşük ton, fısıltı 2,0 sn */
  const tik = path.join(CIKTI, 'tik.wav'), bom = path.join(CIKTI, 'bom.wav');
  if (!fs.existsSync(tik)) ff(['-f', 'lavfi', '-i', 'sine=frequency=1500:duration=0.035', '-af', 'afade=t=out:st=0.02:d=0.015,volume=0.35', tik]);
  if (!fs.existsSync(bom)) ff(['-f', 'lavfi', '-i', 'sine=frequency=180:duration=0.45', '-af', 'afade=t=out:st=0.1:d=0.35,volume=0.6', bom]);
  const tikAnlari = [1, 2, 3, 4, 5, 6, 7];
  const fc = [
    `[1:a]asplit=${tikAnlari.length}${tikAnlari.map((_, i) => `[t${i}]`).join('')}`,
    ...tikAnlari.map((a, i) => `[t${i}]adelay=${a * 1000}|${a * 1000}[d${i}]`),
    `[2:a]adelay=${8000}|${8000}[b]`,
    `[3:a]adelay=${FISILTI_BAS * 1000}|${FISILTI_BAS * 1000},volume=1.6[f]`,
    `${tikAnlari.map((_, i) => `[d${i}]`).join('')}[b][f]amix=inputs=${tikAnlari.length + 2}:normalize=0,apad,atrim=0:${SURE},alimiter=limit=0.9[a]`,
  ].join(';');
  const film = path.join(CIKTI, `sayac-${harf}.mp4`);
  ff(['-framerate', String(FPS), '-i', path.join(kareDiz, '%04d.png'), '-i', tik, '-i', bom, '-i', FISILTI,
      '-filter_complex', fc, '-map', '0:v', '-map', '[a]', '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-crf', '18', '-preset', 'medium',
      '-c:a', 'aac', '-b:a', '160k', '-ar', '44100', '-t', String(SURE), '-movflags', '+faststart', film]);
  fs.rmSync(kareDiz, { recursive: true, force: true });
  console.log(`film: ${film}`);
}

(async () => {
  if (!ONIZLEME && (!FISILTI || !fs.existsSync(FISILTI))) { console.error('--fisilti <mp3> şart (denetimden YEŞİL geçmiş alış)'); process.exit(2); }
  fs.mkdirSync(CIKTI, { recursive: true });
  const tarayici = await chromium.launch();
  try { for (const h of ACILIS === 'HEPSI' ? ['A', 'B', 'C'] : [ACILIS]) await bas(h, tarayici); }
  finally { await tarayici.close(); }
})().catch(e => { console.error(e); process.exit(1); });
