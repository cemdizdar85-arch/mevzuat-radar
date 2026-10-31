#!/usr/bin/env node
/* ============================================================================
   TELLAL REKLAMI — kurgu (30.10.2026, Cem "maskot ile çok dikkat çeken reklam, YK yazısı buruşuk kağıtla,
   eski postacılar gibi haber versek" → "en iyin ol").
   Üç ücretli maskot klibi (arac/video/uret.ps1, sahne-TLA/TLB/TLC) + bizim katmanımız (ek.html, kare kare, 0 TL):
   buruşuk YK yazısı, soru kartı, altyazı, sabit şerit, 6. replik çipleri. Ses: TELLAL alis9 (tek parça, klipler ona hizalı)
   + kendi sentezimiz zil + kapanış kap-A.

   METİN KAPISI: katmandaki her yazı pazarlama/reklam/instagram-tellal-yk-karari.md "Ekrandaki yazı" bölümünde AYNEN
   olmalı; yoksa film basılmaz (exit 3). YK karar cümlesi duyuru HTML'inden okunur (metin elle yazılmaz).
   GÜVENLİ ALAN KAPISI: Reels 9:16 üst %14 · alt %35 · yan %6 yazısız; tek karede taşma varsa basılmaz (exit 4).

   Kullanım: node arac/video/tellal/bas.js [--onizleme] [--cikti <klasör>]
   Çıktı: <cikti>/TELLAL-YK-KARARI.mp4 (720×1280, 25 fps). Medya depoya GİRMEZ.
   🚫 GÖRMEZ: klipteki dudak senkronu (klip-denetim kare tabakası, gözle) · yazının okunma süresi yeterli mi ·
      Meta'nın kendi kırpması · buruşuk kağıt efektinin "inandırıcılığı" (gözle).
   ============================================================================ */
'use strict';
const fs = require('fs'), path = require('path'), { execFileSync } = require('child_process');
let chromium; try { ({ chromium } = require('playwright')); } catch (e) { ({ chromium } = require('C:/Users/cemdi/.claude/araclar/kayit/node_modules/playwright')); }

const KOK = path.resolve(__dirname, '..', '..', '..');
const ANA = 'C:/Users/cemdi/OneDrive/Masaüstü/mevzuat işi';
const KASA = path.join(ANA, '_yerel-veri-kasasi');
const SG = path.join(ANA, 'mevzuat-radar', 'video', 'sorunun-gunlugu');
const arg = n => { const i = process.argv.indexOf(n); return i > -1 ? process.argv[i + 1] : null; };
const CIKTI = arg('--cikti') || path.join(KASA, 'tellal-reklam');
const ONIZLEME = process.argv.includes('--onizleme');
const FPS = 25;
const FF = (() => { const p = 'C:/Users/cemdi/AppData/Local/Microsoft/WinGet/Packages/Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe/ffmpeg-9.0-full_build/bin/ffmpeg.exe'; return fs.existsSync(p) ? p : 'ffmpeg'; })();
const FP = FF.replace(/ffmpeg\.exe$/, 'ffprobe.exe');
const ff = a => execFileSync(FF, ['-nostdin', '-y', '-v', 'error', ...a], { stdio: 'inherit' });
const sure = f => parseFloat(execFileSync(FP, ['-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', f]).toString());

/* ---- zaman çizelgesi: TELLAL alis9 sessizlik + whisper kelime zamanı (30.10; alis6 'bağırma' tonu Seedance'te InputAudioSensitiveContentDetected aldı) ---- */
// TLB klibi referans sesi iki basımda da tutmadı (model kendi konuşmasını üretti); 1151 alışının ağız aralıkları ölçüldü,
// ana kayda 10,42 sn'de 0,30 sn sessizlik eklendi (r5 ile r6 arası) -> sonrası +0,30. Bedel 0.
const KAY = x => (x > 10.42 ? +(x + 0.30).toFixed(2) : x);
const SES = path.join(KASA, 'instagram-seviye', 'diyalog', 'TELLAL-diyalog-alis9-B03.mp3');
const SON = KAY(25.12);
const ZAMAN = { a: [0, 4.40], i1: [4.40, 9.30], b: [9.30, KAY(15.00)], i2: [KAY(15.00), KAY(20.12)], c: [KAY(20.12), SON] };
const ALTYAZI = [
  ['soru', 0.00, 1.29, 2], ['aday', 1.64, 2.88, 3], ['soru', 2.92, 4.27, 4], ['soru', 4.52, 9.16, 5],
  ['aday', 9.45, 10.29, 6], ['soru', 10.54, 13.36, 7], ['aday', 13.69, 14.86, 10], ['soru', 15.06, 19.89, 11],
  ['aday', 20.17, 22.27, 12], ['soru', 22.47, SON, 13],
];

/* ---- metin kapısı ---- */
const md = fs.readFileSync(path.join(KOK, 'pazarlama', 'reklam', 'instagram-tellal-yk-karari.md'), 'utf8');
const bolum = /## Ekrandaki yazı \(kare kare\)\r?\n([\s\S]*?)(?=\r?\n## )/.exec(md);
if (!bolum) { console.error('METİN KAPISI: "Ekrandaki yazı" bölümü yok'); process.exit(3); }
const SATIR = {}; for (const m of bolum[1].matchAll(/^(\d+)\. (.+)$/gm)) SATIR[m[1]] = m[2].trim();
const S = n => { if (!SATIR[n]) { console.error(`METİN KAPISI: md'de ${n}. satır yok`); process.exit(3); } return SATIR[n]; };

/* ---- YK karar cümlesi duyurudan ---- */
const ykHtml = fs.readFileSync(path.join(ANA, 'Tetikte-Instagram', 'yk-duyuru-29-ekim.html'), 'utf8');
const karar = (/<div class="karar">([\s\S]*?)<\/div>/.exec(ykHtml) || [])[1];
if (!karar || !karar.includes('kazanana kadar')) { console.error('METİN KAPISI: duyuruda karar cümlesi okunamadı'); process.exit(3); }
const kararHtml = karar.trim()
  .replace('1 Kasım 2026 saat 23:59', '<mark>1 Kasım 2026 saat 23:59</mark>')
  .replace('kazanana kadar', '<mark>kazanana kadar</mark>')
  .replace('ek ücret ödemeden', '<mark>ek ücret ödemeden</mark>');

/* ---- soru: ornek-sgs vitrininden (pazarlama soru kapısı YEŞİL 30.10) ---- */
function soruOku(id) {
  const t = fs.readFileSync(path.join(KOK, 'kaydir', 'vitrin', 'ornek-sgs.html'), 'utf8');
  const i = t.indexOf(`"${id}"`); if (i < 0) { console.error(`soru yok: ${id}`); process.exit(3); }
  let d = 0, s = i; for (; s > 0; s--) { const c = t[s]; if (c === '}') d++; else if (c === '{') { if (d === 0) break; d--; } }
  let e = s; d = 0; for (; e < t.length; e++) { const c = t[e]; if (c === '{') d++; else if (c === '}') { d--; if (d === 0) break; } }
  return JSON.parse(t.slice(s, e + 1));
}
const q = soruOku('sgs-d5-vergi-cokzor-r2/kp-02');
const ETIKET = { A: S(15), B: S(16), C: S(17), D: S(18) };   // sorunun tuzak.ad alanının kısa yazımı
for (const h of 'ABCD') {
  const ad = (q.tuzak[h] && q.tuzak[h].ad || '').toLocaleLowerCase('tr');
  const kisa = ETIKET[h].toLocaleLowerCase('tr').replace(' tuzağı', '');
  if (!ad.includes(kisa)) { console.error(`METİN KAPISI: ${h} etiketi sorunun tuzak adıyla uyuşmuyor ("${ad}" ↔ "${kisa}")`); process.exit(3); }
}
if (q.dogru !== 'E' || q.siklar.E !== '230.000' || !S(19).endsWith(q.siklar.E)) { console.error('METİN KAPISI: doğru şık 230.000 değil'); process.exit(3); }
// şıklar r8 içinde sırayla yanar: "Her şıkkın" 16.16 → 17.8; doğru "maddeyi" 18.6, dayanak 18.8
const an0 = KAY(16.25) - ZAMAN.i2[0];
const siklar = ['A', 'B', 'C', 'D', 'E'].map((h, i) => ({
  h, deger: q.siklar[h], dogru: h === 'E', etiket: h === 'E' ? '✓ ' + S(19) : ETIKET[h], an: h === 'E' ? KAY(18.55) - ZAMAN.i2[0] : an0 + i * 0.4,
}));

const V = {
  zaman: ZAMAN,
  serit: S(1),
  ykGorsel: 'file:///' + path.join(ANA, 'Tetikte-Instagram', 'yk-duyuru-29-ekim.png').replace(/\\/g, '/'),
  ykBaslik: S(21), kararHtml,
  soru: { rozet: S(14), kok: q.soru, siklar, dayanak: S(20), dayanakAn: KAY(18.8) - ZAMAN.i2[0] },
  cip: [S(8), S(9)], cipZaman: [11.30, 11.85, 12.95, 13.65].map(KAY),
  altyazi: ALTYAZI.map(([kim, bas, son, n]) => ({ kim, bas: KAY(bas), son: KAY(son), metin: S(n) })),
};

(async () => {
  fs.mkdirSync(CIKTI, { recursive: true });
  const tarayici = await chromium.launch();
  const sayfa = await tarayici.newPage({ viewport: { width: 720, height: 1280 }, deviceScaleFactor: 1 });
  await sayfa.goto('file:///' + path.join(__dirname, 'ek.html').replace(/\\/g, '/'));
  await sayfa.evaluate(v => window.kur(v), V);
  await sayfa.waitForFunction(() => document.getElementById('ykimg').complete);
  const kareDiz = path.join(CIKTI, ONIZLEME ? 'onizleme' : 'katman');
  const anlar = ONIZLEME ? [0.6, 2.2, 3.6, 4.8, 5.6, 7.0, 8.5, 9.8, 11.9, 13.2, 15.5, 17.0, 19.0, 21.0, 24.0]
    : Array.from({ length: Math.round(FPS * SON) }, (_, i) => i / FPS);
  // --kurgu: katman bu kodla tam basılmış ve güvenli alandan geçmişse yalnız kurgu yeniden koşar (kare sayısı tutmalı)
  const yalnizKurgu = process.argv.includes('--kurgu') && !ONIZLEME && fs.existsSync(kareDiz)
    && fs.readdirSync(kareDiz).filter(f => f.endsWith('.png')).length === anlar.length;
  if (!yalnizKurgu) { fs.rmSync(kareDiz, { recursive: true, force: true }); fs.mkdirSync(kareDiz, { recursive: true }); }
  const tasma = [];
  for (let i = 0; i < (yalnizKurgu ? 0 : anlar.length); i++) {
    const t = await sayfa.evaluate(x => { window.kare(x); return window.alanDisi(); }, anlar[i]);
    if (t.length) tasma.push(`${anlar[i].toFixed(2)} sn: ${t.join(' | ')}`);
    await sayfa.screenshot({ path: path.join(kareDiz, (ONIZLEME ? `o-${anlar[i].toFixed(1)}s` : String(i).padStart(4, '0')) + '.png'), omitBackground: true });
  }
  await tarayici.close();
  if (tasma.length) { console.error(`GÜVENLİ ALAN KIRMIZI — ${tasma.length} karede taşma:\n  ` + tasma.slice(0, 8).join('\n  ')); process.exit(4); }
  console.log(`güvenli alan: ${anlar.length} karenin hepsi içeride`);
  if (ONIZLEME) { console.log(`önizleme: ${kareDiz}`); return; }

  /* ---- klipler (en yeni 720p) ---- */
  const klip = ad => {
    const l = fs.readdirSync(SG).filter(f => f.startsWith(ad) && f.endsWith('.mp4') && f.includes('-720p-')).sort();
    if (!l.length) { console.error(`klip yok: ${ad}-…-720p-*.mp4`); process.exit(5); }
    return path.join(SG, l[l.length - 1]);
  };
  const kA = klip('TLA-tellal-acilis'), kB = path.join(SG, 'TLB-tellal-orta-6-720p-20261030-1151.mp4'), kC = klip('TLC-tellal-kapanis');
  console.log('klipler:', [kA, kB, kC].map(f => path.basename(f)).join(' · '));

  /* ---- zil (kendi sentezimiz) ---- */
  const zil = path.join(CIKTI, 'zil.wav');
  if (!fs.existsSync(zil)) ff(['-f', 'lavfi', '-i',
    "aevalsrc='0.5*exp(-5*t)*(sin(2*PI*1320*t)+0.55*sin(2*PI*2690*t)+0.3*sin(2*PI*4020*t))*(0.6+0.4*sin(2*PI*9*t))':s=44100:d=1.2", zil]);
  const kap = path.join(KASA, 'ses-yarisma', 'kapanis', 'kap-A.mp4');
  const kapSure = sure(kap);

  /* ---- görüntü: klipler zaman çizelgesine, eklerde lacivert, üstüne katman; sonda kap-A ---- */
  /* 30.10: tek filtre grafiği (7 girdi) ffmpeg 9'da 12:06'da kilitlendi, CPU 1 sa 48 dk hiç artmadı.
     Üç adıma bölündü: görüntü gövdesi · ses gövdesi · kap-A ile birleştirme. */
  const film = path.join(CIKTI, 'TELLAL-YK-KARARI.mp4');
  const govV = path.join(CIKTI, 'govde-v.mp4'), govA = path.join(CIKTI, 'govde-a.wav'), kapN = path.join(CIKTI, 'kap-n.mp4');
  const kod = ['-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-crf', '18', '-preset', 'medium'];
  // beş parçayı tek concat filtresinde birleştirmek de 3,16. sn'de kilitlendi → her parça ayrı dosya, sırayla concat demuxer
  const parca = [['a', kA], ['i1', null], ['b', kB], ['i2', null], ['c', kC]].map(([z, k]) => {
    const d = (ZAMAN[z][1] - ZAMAN[z][0]).toFixed(3), cik = path.join(CIKTI, `parca-${z}.mp4`);
    ff(k ? ['-i', k, '-an', '-vf', `trim=0:${d},setpts=PTS-STARTPTS,scale=720:1280:force_original_aspect_ratio=increase,crop=720:1280,fps=${FPS},setsar=1,format=yuv420p`, ...kod, cik]
         : ['-f', 'lavfi', '-i', `color=c=0x0f2338:s=720x1280:r=${FPS}:d=${d}`, '-vf', 'setsar=1,format=yuv420p', ...kod, cik]);
    return cik;
  });
  const liste = path.join(CIKTI, 'parca.txt');
  fs.writeFileSync(liste, parca.map(p => `file '${p.replace(/\\/g, '/')}'`).join('\n'));
  const taban = path.join(CIKTI, 'taban.mp4');
  ff(['-f', 'concat', '-safe', '0', '-i', liste, '-c', 'copy', taban]);
  ff(['-i', taban, '-framerate', String(FPS), '-i', path.join(kareDiz, '%04d.png'), '-filter_complex',
      `[1:v]format=rgba[kat];[0:v][kat]overlay=0:0:eof_action=pass,format=yuv420p[v]`, '-map', '[v]', ...kod, '-t', SON.toFixed(2), govV]);
  ff(['-i', SES, '-i', zil, '-filter_complex', [
    `[0:a]aresample=44100,aformat=channel_layouts=stereo,apad,atrim=0:${SON}[konus]`,
    `[1:a]aformat=channel_layouts=stereo,asplit=2[z1][z2]`, `[z2]adelay=22650|22650[zz2]`,
    `[konus][z1][zz2]amix=inputs=3:normalize=0:duration=first[a]`,
  ].join(';'), '-map', '[a]', '-ar', '44100', '-t', SON.toFixed(2), govA]);
  // gövde ve kap-A aynı biçime (h264 25 fps + aac 44,1 kHz stereo) getirilir, sırayla eklenir, en sonda yalnız ses ses düzeyine çekilir
  const ak = ['-c:a', 'aac', '-b:a', '192k', '-ar', '44100', '-ac', '2'];
  const govde = path.join(CIKTI, 'govde.mp4');
  ff(['-i', govV, '-i', govA, '-map', '0:v', '-map', '1:a', '-c:v', 'copy', ...ak, '-shortest', govde]);
  ff(['-i', kap, '-vf', `scale=720:1280,fps=${FPS},setsar=1,format=yuv420p`, ...kod, ...ak, kapN]);
  fs.writeFileSync(liste, [govde, kapN].map(p => `file '${p.replace(/\\/g, '/')}'`).join('\n'));
  const ham = path.join(CIKTI, 'ham.mp4');
  ff(['-f', 'concat', '-safe', '0', '-i', liste, '-c', 'copy', ham]);
  ff(['-i', ham, '-c:v', 'copy', '-af', 'loudnorm=I=-14:TP=-1.5:LRA=11', ...ak, '-movflags', '+faststart', film]);
  console.log(`film: ${film} (${sure(film).toFixed(2)} sn)`);
})().catch(e => { console.error(e); process.exit(1); });
