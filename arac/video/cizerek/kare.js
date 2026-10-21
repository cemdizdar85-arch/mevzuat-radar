#!/usr/bin/env node
/* ============================================================================
   NÖBETÇİ ÇİZEREK ÇÖZÜYOR v2 — TAM EKRAN, KARE KARE (22.10.2026, Cem: "görüntü çok kötü, boş boş geçiyor, belli olmuyor,
   tam ekran olmalı; profesyoneller paylaşır mı"). v1 (kayit.js + bas.js) canlı kaydı 390 px'ten büyütüyordu (bulanık),
   telefon çerçevesi ekranın yarısını alıyordu, bekleme boşlukları vardı, maskot yoktu.
   v2: canlı tetikte.com örnek soru sayfası 360×640 · DPR 3 (= 1080×1920) açılır, sayfanın SAATİ DURDURULUR (Playwright clock)
   ve her kare 40 ms ilerletilip ekran görüntüsü alınır → sitenin kendi kalem animasyonu bozulmadan, tam çözünürlükte.
   Çizim penceresi (.czKat) üst 70 px ile alt 500 px arasına alınır (Reels üst/alt arayüzü dışında kalsın; transform/zoom YOK,
   yalnız yükseklik → kalemin işaret yerleri doğru kalır). Nöbetçi maskotu sitenin alt yazı satırının solunda, konuşurken hareket eder.
   Adımlar seslendirme süresine göre ilerler (boşluk 0,25 sn). Ses: ses.js'in alışı.
   METİN KAPISI: eklenen yazılar pazarlama/reklam/instagram-nobetci-cizerek-cozuyor.md "## Ekrana eklenen yazılar"dan.
   Kullanım: node arac/video/cizerek/kare.js [--ses-alis 2] [--onizleme]
   g��� GÖRMEZ: sitedeki çizimin doğruluğu (sitenin kapıları) · ses tonlaması (kulakla) · Instagram arayüzünün cihaza göre değişen boyu.
   ============================================================================ */
'use strict';
const fs = require('fs'), path = require('path'), { execFileSync } = require('child_process');
let chromium; try { ({ chromium } = require('playwright')); } catch (e) { ({ chromium } = require('C:/Users/cemdi/.claude/araclar/kayit/node_modules/playwright')); }
const KOK = path.resolve(__dirname, '..', '..', '..');
const arg = n => { const i = process.argv.indexOf(n); return i > -1 ? process.argv[i + 1] : null; };
const ALIS = arg('--ses-alis') || '2', ONIZLEME = process.argv.includes('--onizleme');
const DIZ = 'C:/Users/cemdi/OneDrive/Masaüstü/mevzuat işi/_yerel-veri-kasasi/nobetci-cizerek';
const FF = 'C:/Users/cemdi/AppData/Local/Microsoft/WinGet/Packages/Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe/ffmpeg-9.0-full_build/bin/ffmpeg.exe';
const ff = a => execFileSync(FF, ['-nostdin', '-y', '-v', 'error', ...a], { stdio: 'inherit' });
const URL = 'https://tetikte.com/kaydir/vitrin/ornek-smmm.html?k=kontrol';
const FPS = 25, KARE = 1000 / FPS;

const md = fs.readFileSync(path.join(KOK, 'pazarlama', 'reklam', 'instagram-nobetci-cizerek-cozuyor.md'), 'utf8').replace(/<!--[\s\S]*?-->\r?\n?/g, '');
const Y = (/## Ekrana eklenen yazılar\r?\n([\s\S]*?)(?=\r?\n## )/.exec(md) || [, ''])[1].split(/\r?\n/).map(s => s.trim()).filter(Boolean);
if (Y.length !== 5 || Y[0] !== 'Reklam') { console.error('METİN KAPISI: "Ekrana eklenen yazılar" 5 satır olmalı'); process.exit(3); }
const [ETIKET, HOOK, BASLIK, KAPANIS, ADRES] = Y;
const sure = JSON.parse(fs.readFileSync(path.join(DIZ, `sureler-alis${ALIS}.json`), 'utf8'));
const MASKOT = 'data:image/jpeg;base64,' + fs.readFileSync(path.join(KOK, 'gorsel', 'maskot-giris.jpg')).toString('base64');

/* Zaman çizelgesi (sn): her parça bir sesle eş; konuşma = maskot hareketi */
const P = []; let t = 0;
const ekle = (ad, sn, ses) => { P.push({ ad, bas: t, son: t + sn, ses }); t += sn; };
ekle('kanca', sure.s0 + 0.3, 's0');           // soru ekranı + üstte kanca bandı, s0
ekle('secim', 1.6, null);                      // A'ya dokunulur, sonuç ekranı kısa görünür
ekle('ac', 0.8, null);                         // "Nöbetçi çizerek çözsün" açılır
for (let i = 1; i <= 8; i++) ekle('adim' + i, sure['s' + i] + 0.25, 's' + i);
ekle('kapanis', 2.4, null);
const TOPLAM = t;

const CSS = `
.czKat{top:70px!important;bottom:auto!important;height:430px!important;border-radius:18px 18px 0 0;box-shadow:0 -6px 30px #0006}
.czAlc{display:none!important}
.czAlt{position:relative;padding-left:64px!important;text-align:left!important;font-size:1em!important;min-height:4.4em!important}
#vZemin{position:fixed;inset:0;z-index:2147480500;background:radial-gradient(circle at 80% 8%,#f5a52429,transparent 42%),radial-gradient(circle at 10% 90%,#3b82f624,transparent 45%),#0b1626}
#vZemin .bas{position:absolute;left:0;right:0;top:26px;text-align:center;font:900 19px/1 Inter,"Segoe UI",sans-serif;color:#f4f6fa;letter-spacing:-.4px}
#vZemin .bas b{color:#ffc24b}
#vMaskot{width:48px;height:48px;border-radius:50%;background:#fff url(${MASKOT}) center 18%/150% no-repeat;
  box-shadow:0 0 0 2px #f5a524,0 4px 12px #0005;transform-origin:50% 90%}
#vKanca{position:fixed;left:12px;right:12px;top:78px;z-index:2147483000;background:#0b1626ee;border:1.5px solid #f87171;border-radius:14px;
  padding:12px 14px;font:800 19px/1.25 Inter,"Segoe UI",sans-serif;color:#fff;text-align:center;letter-spacing:-.3px;display:none}
#vKanca em{font-style:normal;color:#f87171}
#vEt{position:fixed;left:10px;top:6px;z-index:2147483001;font:600 9px Inter,sans-serif;color:#f4f6fab3}
#vKapanis{position:fixed;inset:0;z-index:2147483002;display:none;background:radial-gradient(circle at 50% 30%,#f5a52433,transparent 50%),#0b1626;
  flex-direction:column;align-items:center;justify-content:center;gap:18px;padding:0 30px 140px;text-align:center;font-family:Inter,"Segoe UI",sans-serif}
#vKapanis .m{width:120px;height:120px;border-radius:50%;background:#fff url(${MASKOT}) center 18%/150% no-repeat;box-shadow:0 0 0 4px #f5a524,0 0 40px #f5a52499}
#vKapanis p{font-weight:900;font-size:30px;line-height:1.12;color:#f4f6fa;letter-spacing:-.8px}
#vKapanis .a{font-size:24px;color:#ffc24b;letter-spacing:0}
#vDokun{position:fixed;z-index:2147483003;width:44px;height:44px;margin:-22px 0 0 -22px;border-radius:50%;border:3px solid #ffc24b;display:none;pointer-events:none}`;
const esc = s => s.replace(/&/g, '&amp;').replace(/</g, '&lt;');

(async () => {
  fs.mkdirSync(DIZ, { recursive: true });
  const kareDiz = path.join(DIZ, 'kareler2'); fs.rmSync(kareDiz, { recursive: true, force: true }); fs.mkdirSync(kareDiz, { recursive: true });
  const tarayici = await chromium.launch();
  const ctx = await tarayici.newContext({ viewport: { width: 360, height: 640 }, deviceScaleFactor: 3, isMobile: true, hasTouch: true, locale: 'tr-TR' });
  const sayfa = await ctx.newPage();
  await sayfa.clock.install();
  await sayfa.goto(URL, { waitUntil: 'networkidle' });
  await sayfa.clock.runFor(1500);
  await sayfa.addStyleTag({ content: '@import url("https://fonts.googleapis.com/css2?family=Inter:wght@600;800;900&display=block");' + CSS });
  await sayfa.evaluate(([et, hook, bas, kap, adr]) => {
    const d = document.createElement('div'); d.innerHTML =
      `<div id="vEt">${et}</div><div id="vKanca">${hook}</div><div id="vDokun"></div>` +
      `<div id="vKapanis"><div class="m"></div><p>${kap}</p><p class="a">${adr}</p></div>`;
    document.body.appendChild(d);
    window.__vBas = bas;
  }, [esc(ETIKET), esc(HOOK).replace(/(Her \d+ kişiden \d+'\S+ yanlış yaptı\.)/, '<em>$1</em>'), esc(BASLIK).replace(/(çizerek)/, '<b>$1</b>'), esc(KAPANIS), esc(ADRES)]);
  await sayfa.evaluate(() => document.fonts.ready);
  await sayfa.clock.runFor(300);

  const yap = async (ad) => {   /* parça başında bir kez çalışan site eylemleri */
    if (ad === 'kanca') await sayfa.evaluate(() => { document.getElementById('vKanca').style.display = 'block'; });
    if (ad === 'secim') {
      await sayfa.evaluate(() => { document.getElementById('vKanca').style.display = 'none'; });
      const a = sayfa.getByText('40.000 ₺ yüksek gösterilmiştir', { exact: false }).first();
      const k = await a.boundingBox();
      await sayfa.evaluate(([x, y]) => { const d = document.getElementById('vDokun'); d.style.left = x + 'px'; d.style.top = y + 'px'; d.style.display = 'block'; }, [k.x + k.width / 2, k.y + k.height / 2]);
      await a.click({ noWaitAfter: true });
    }
    if (ad === 'ac') {
      await sayfa.evaluate(() => { document.getElementById('vDokun').style.display = 'none'; });
      const b = sayfa.getByText('Nöbetçi çizerek çözsün', { exact: false }).first();
      await b.evaluate(el => el.click());
      await sayfa.clock.runFor(60);
      await sayfa.evaluate((bas) => {   /* zemin + maskot (çizim penceresi açıldıktan sonra) */
        const z = document.createElement('div'); z.id = 'vZemin'; z.innerHTML = `<div class="bas">✍️ ${bas}</div>`; document.body.appendChild(z);
        /* site her adımda .czAlt'ı yeniden yazıyor (içine konan maskot siliniyordu, 22.10 önizleme) → maskot gövdede, sabit konumlu;
           yeri her karede .czAlt'a göre ayarlanır */
        const m = document.createElement('div'); m.id = 'vMaskot'; m.style.position = 'fixed'; m.style.zIndex = '2147482000'; document.body.appendChild(m);
      }, await sayfa.evaluate(() => window.__vBas));
    }
    const m = /^adim(\d)$/.exec(ad);
    if (m) {
      await sayfa.evaluate(() => document.querySelector('.czIleri').click());
      if (m[1] === '2') await sayfa.evaluate(() => { const g = document.querySelector('.czGovde'); g.scrollTo({ top: g.scrollHeight, behavior: 'smooth' }); });
    }
    if (ad === 'kapanis') await sayfa.evaluate(() => { document.getElementById('vKapanis').style.display = 'flex'; });
  };

  const N = Math.round(TOPLAM * FPS); let parca = -1;
  const anlar = ONIZLEME ? new Set([1, 4, 6.5, 8.5, 12, 17, 23, 29, 35, 41, 46, TOPLAM - 1].map(s => Math.round(s * FPS))) : null;
  for (let i = 0; i < N; i++) {
    const sn = i / FPS;
    const pi = P.findIndex(p => sn >= p.bas && sn < p.son);
    if (pi !== parca) { parca = pi; await yap(P[pi].ad); }
    const p = P[pi], konusuyor = p.ses && sn - p.bas < sure[p.ses];
    await sayfa.evaluate(([k, s]) => {
      const m = document.getElementById('vMaskot'); if (!m) return;
      const alt = document.querySelector('.czAlt'); if (alt) { const r = alt.getBoundingClientRect(); m.style.left = (r.left + 8) + 'px'; m.style.top = (r.top + 10) + 'px'; }
      m.style.display = document.getElementById('vKapanis').style.display === 'flex' ? 'none' : 'block';
      const z = k ? Math.abs(Math.sin(s * 9)) : 0;
      m.style.transform = `translateY(${(-3 * z).toFixed(2)}px) rotate(${(k ? Math.sin(s * 4.5) * 4 : 0).toFixed(2)}deg) scale(${(1 + 0.05 * z).toFixed(3)})`;
    }, [konusuyor, sn]);
    if (!anlar || anlar.has(i)) await sayfa.screenshot({ path: path.join(kareDiz, (anlar ? 'o' + sn.toFixed(1) + 's' : String(i).padStart(5, '0')) + '.png') });
    await sayfa.clock.runFor(KARE);
  }
  await tarayici.close();
  if (ONIZLEME) { console.log('önizleme: ' + kareDiz); return; }
  /* ses + birleştir */
  const sesler = P.filter(p => p.ses).map(p => ({ f: path.join(DIZ, `ses-${p.ses}-alis${ALIS}.mp3`), at: p.bas + 0.1 }));
  const girdi = ['-framerate', String(FPS), '-i', path.join(kareDiz, '%05d.png')]; sesler.forEach(s => girdi.push('-i', s.f));
  const fc = sesler.map((s, i) => `[${1 + i}:a]adelay=${Math.round(s.at * 1000)}|${Math.round(s.at * 1000)}[a${i}]`).join(';')
    + ';' + sesler.map((_, i) => `[a${i}]`).join('') + `amix=inputs=${sesler.length}:normalize=0,apad,atrim=0:${TOPLAM.toFixed(3)},loudnorm=I=-14:TP=-1.5:LRA=11[a]`;
  const film = path.join(DIZ, 'nobetci-cizerek-v2.mp4');
  ff([...girdi, '-filter_complex', fc, '-map', '0:v', '-map', '[a]', '-c:v', 'libx264', '-crf', '17', '-preset', 'medium', '-pix_fmt', 'yuv420p',
      '-c:a', 'aac', '-b:a', '160k', '-ar', '44100', '-t', TOPLAM.toFixed(3), '-movflags', '+faststart', film]);
  fs.rmSync(kareDiz, { recursive: true, force: true });
  console.log(`film: ${film} (${TOPLAM.toFixed(1)} sn) · ` + P.map(p => p.ad + '@' + p.bas.toFixed(1)).join(' '));
})().catch(e => { console.error(e); process.exit(1); });
