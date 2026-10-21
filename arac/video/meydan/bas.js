#!/usr/bin/env node
/* ============================================================================
   MEYDAN OKUMA (SAYAÇLI SORU) VİDEOSU — 21.10.2026, Cem "zor soru + geri akan saniyeler; hem Staja Giriş hem bitirme".
   Sahne: arac/video/sayac/sahne.html (29.09 sayaç reklamı; soru + 7 sn sayaç → yanlış şık → tuzak → doğrusu → kapanış).
   Bedel 0: YZ yok, ses ffmpeg sayaç tıkı + düşük ton (fısıltı yok).
   METİN KAPISI: ekrandaki her yazı pazarlama/reklam/meta-meydan-okuma-sayac.md "## <Sınav>" bölümünden SIRAYLA okunur
   (14 satır: etiket, açılış, soru, 5 şık, tuzak adı, tuzak nedeni, doğrusu, kural, kapanış, adres); eksikse durur (exit 3).
   GÜVENLİ ALAN: sahne.html alanDisi() her karede (Meta Reels üst %14 · alt %35 · yan %6); taşma varsa basmaz (exit 4).
   Kullanım: node arac/video/meydan/bas.js --sinav sgs|yet|hepsi [--yanlis D] [--cikti <klasör>] [--onizleme]
   🚫 GÖRMEZ: sorunun doğruluğu (md iç notunda elle hesap) · yazının okunma süresi yeterli mi (gözle).
   ============================================================================ */
'use strict';
const fs = require('fs'), path = require('path'), { execFileSync } = require('child_process');
let chromium; try { ({ chromium } = require('playwright')); } catch (e) { ({ chromium } = require('C:/Users/cemdi/.claude/araclar/kayit/node_modules/playwright')); }

const KOK = path.resolve(__dirname, '..', '..', '..');
const arg = n => { const i = process.argv.indexOf(n); return i > -1 ? process.argv[i + 1] : null; };
const SINAV = (arg('--sinav') || 'sgs').toLowerCase();
const CIKTI = arg('--cikti') || path.resolve(KOK, '..', '_yerel-veri-kasasi', 'meydan-okuma');
const ONIZLEME = process.argv.includes('--onizleme');
/* --v2 (21.10, yalnız yet): uygulama penceresi sahnesi (sahne2.html) + Nöbetçi seslendirmesi (ses.js alışı --ses-alis N) */
const V2 = process.argv.includes('--v2');
const SES_ALIS = arg('--ses-alis') || '2';
/* sesler (alış 2): v1 5,7 sn · v2 4,6 sn · v3 7,1 sn → v3 13,9'da başlar, 21,0'da biter; v2 filmi 22 sn, kapanış 21,2'de */
const SES_ANI = { v1: 0.2, v2: 9.1, v3: 13.9 };
const FPS = 25, SURE = V2 ? 23 : 19;
/* açılış cümlesi okunsun diye 2 sn (sayaç reklamında 1 sn); tüm çizelge 1 sn kayar */
const Z = { acilisSon: 2.0, sayacBas: 2.0, sayacSon: 9.0, yanlis: 9.0, dogru: 10.0, kutuBas: 10.0, kapanisBas: V2 ? 21.2 : 16.0, son: SURE };
const FF = (() => { const p = 'C:/Users/cemdi/AppData/Local/Microsoft/WinGet/Packages/Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe/ffmpeg-9.0-full_build/bin/ffmpeg.exe'; return fs.existsSync(p) ? p : 'ffmpeg'; })();
const md = fs.readFileSync(path.join(KOK, 'pazarlama', 'reklam', 'meta-meydan-okuma-sayac.md'), 'utf8').replace(/<!--[\s\S]*?-->\r?\n?/g, '');
const BOLUM = { sgs: 'Staja Giriş', yet: 'Yeterlilik' };
const YANLIS = { sgs: 'D', yet: 'A' };   /* yet: sitede en çok seçilen yanlış şık A (21.10 ölçüm: 27/86) */

function veriKur(sinav) {
  const m = new RegExp(`## ${BOLUM[sinav]}\\r?\\n([\\s\\S]*?)(?=\\r?\\n## )`).exec(md);
  if (!m) { console.error(`METİN KAPISI: "${BOLUM[sinav]}" bölümü yok`); process.exit(3); }
  const S = m[1].split(/\r?\n/).map(s => s.trim()).filter(Boolean);
  if (S.length !== 14 || S[0] !== 'Reklam') { console.error(`METİN KAPISI: ${BOLUM[sinav]} 14 satır olmalı (${S.length})`); process.exit(3); }
  const siklar = S.slice(3, 8).map(x => { const k = /^([A-E])\) (.+)$/.exec(x); if (!k) { console.error('şık biçimi: ' + x); process.exit(3); } return { h: k[1], m: k[2] }; });
  const dogruHarf = (/^Doğrusu ([A-E])\)/.exec(S[10]) || [])[1];
  const yanlis = (arg('--yanlis') || YANLIS[sinav]).toUpperCase();
  if (!dogruHarf || dogruHarf === yanlis) { console.error('doğru harf okunamadı ya da yanlış harfle aynı'); process.exit(3); }
  return { etiket: S[0], acilis: S[1], soru: S[2], siklar, fisiltiHarf: yanlis, dogruHarf, tuzakAd: S[8], tuzakNeden: S[9],
           dogrusu: S[10], kural: S[11], kapanis: S[12], adres: S[13], Z, tekSutun: siklar.some(x => x.m.length > 12), arayuz: arayuzKur(sinav) };
}
function arayuzKur(sinav) {
  if (!V2) return null;
  const m = new RegExp(`## Arayüz yazıları · ${BOLUM[sinav]}\\r?\\n([\\s\\S]*?)(?=\\r?\\n## )`).exec(md);
  const A = m ? m[1].split(/\r?\n/).map(s => s.trim()).filter(Boolean) : [];
  if (A.length !== 4) { console.error(`METİN KAPISI: Arayüz yazıları · ${BOLUM[sinav]} 4 satır olmalı (${A.length})`); process.exit(3); }
  return A;
}
function ff(argv) { execFileSync(FF, ['-nostdin', '-y', '-v', 'error', ...argv], { stdio: 'inherit' }); }

async function bas(sinav, tarayici) {
  const veri = veriKur(sinav);
  const sayfa = await tarayici.newPage({ viewport: { width: 360, height: 640 }, deviceScaleFactor: 2 });
  const sahne = V2 ? path.join(__dirname, 'sahne2.html') : path.join(KOK, 'arac', 'video', 'sayac', 'sahne.html');
  await sayfa.goto('file:///' + sahne.replace(/\\/g, '/'));
  if (V2 && !(await sayfa.evaluate(() => document.fonts.ready.then(() => document.fonts.check('800 12px Inter'))))) { console.error('Inter yazı tipi yüklenmedi'); process.exit(3); }
  await sayfa.evaluate(v => window.kur(v), veri);
  const kareDiz = path.join(CIKTI, `kareler-${sinav}`);
  fs.rmSync(kareDiz, { recursive: true, force: true }); fs.mkdirSync(kareDiz, { recursive: true });
  const anlar = ONIZLEME ? [1.0, 3.0, 8.5, 9.3, 11.0, 13.5, 17.5] : Array.from({ length: FPS * SURE }, (_, i) => i / FPS);
  const tasmalar = [];
  for (let i = 0; i < anlar.length; i++) {
    const tasma = await sayfa.evaluate(t => { window.kare(t); return window.alanDisi(); }, anlar[i]);
    if (tasma.length) tasmalar.push(`${anlar[i].toFixed(2)} sn: ${tasma.join(' | ')}`);
    await sayfa.screenshot({ path: path.join(kareDiz, (ONIZLEME ? `onizleme-${anlar[i].toFixed(1)}s` : String(i).padStart(4, '0')) + '.png') });
  }
  await sayfa.close();
  if (tasmalar.length) { console.error(`GÜVENLİ ALAN KIRMIZI (${sinav}) — ${tasmalar.length} karede taşma:\n  ` + tasmalar.slice(0, 6).join('\n  ')); process.exit(4); }
  console.log(`güvenli alan: ${anlar.length} karenin hepsi içeride (${sinav})`);
  if (ONIZLEME) { console.log(`önizleme: ${kareDiz}`); return; }
  const tik = path.join(CIKTI, 'tik.wav'), bom = path.join(CIKTI, 'bom.wav');
  if (!fs.existsSync(tik)) ff(['-f', 'lavfi', '-i', 'sine=frequency=1500:duration=0.035', '-af', 'afade=t=out:st=0.02:d=0.015,volume=0.35', tik]);
  if (!fs.existsSync(bom)) ff(['-f', 'lavfi', '-i', 'sine=frequency=180:duration=0.45', '-af', 'afade=t=out:st=0.1:d=0.35,volume=0.6', bom]);
  const tikAnlari = [2, 3, 4, 5, 6, 7, 8];
  const fc = [
    `[1:a]asplit=${tikAnlari.length}${tikAnlari.map((_, i) => `[t${i}]`).join('')}`,
    ...tikAnlari.map((a, i) => `[t${i}]adelay=${a * 1000}|${a * 1000}[d${i}]`),
    `[2:a]adelay=9000|9000[b]`,
    `${tikAnlari.map((_, i) => `[d${i}]`).join('')}[b]amix=inputs=${tikAnlari.length + 1}:normalize=0,apad,atrim=0:${SURE},alimiter=limit=0.9[a]`,
  ].join(';');
  const girdi = ['-framerate', String(FPS), '-i', path.join(kareDiz, '%04d.png'), '-i', tik, '-i', bom];
  let fcSon = fc;
  if (V2) {
    /* seslendirme: tıklar sesin altında kalsın diye kısılır; her klip kendi anında */
    const ad = Object.keys(SES_ANI), sesler = ad.map(a => path.join(CIKTI, `ses-${a}-alis${SES_ALIS}.mp3`));
    sesler.forEach(s => { if (!fs.existsSync(s)) { console.error('ses yok (önce ses.js): ' + s); process.exit(2); } girdi.push('-i', s); });
    fcSon = fc.replace(/,apad,atrim=0:\d+,alimiter=limit=0\.9\[a\]$/, ',volume=0.45[sfx]')
      + ';' + ad.map((a, i) => `[${3 + i}:a]adelay=${Math.round(SES_ANI[a] * 1000)}|${Math.round(SES_ANI[a] * 1000)},volume=1.15[s${i}]`).join(';')
      + `;[sfx]${ad.map((_, i) => `[s${i}]`).join('')}amix=inputs=${ad.length + 1}:normalize=0,apad,atrim=0:${SURE},alimiter=limit=0.9[a]`;
    if (fcSon === fc || !fcSon.includes('[sfx]')) { console.error('ses karışımı kurulamadı'); process.exit(1); }
  }
  const film = path.join(CIKTI, `meydan-${sinav}${V2 ? '-v2' : ''}.mp4`);
  ff([...girdi,
      '-filter_complex', fcSon, '-map', '0:v', '-map', '[a]', '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-crf', '18', '-preset', 'medium',
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
