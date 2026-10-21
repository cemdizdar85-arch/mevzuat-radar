#!/usr/bin/env node
/* ============================================================================
   NÖBETÇİ ÇİZEREK ÇÖZÜYOR v3 — KAMERALI KURGU (22.10.2026, Cem: "ekran görüntüsü iyi değil, sen bak").
   v2 (kare.js) tam ekran ve keskindi ama "sitenin ekran kaydı" gibi duruyordu: başlık iki kez (bizim bant + sitenin pencere başlığı/✕),
   altta boş koyu şerit, göz nereye bakacağını bilmiyordu, maskot küçüktü.
   v3: sayfanın saati durdurulur (Playwright clock), her karede KAMERA penceresi (kare, CSS px) kalemin o an çalıştığı yere
   yumuşakça kayar ve o bölge DPR 3 ile kırpılarak çekilir (page.screenshot clip) → yakınlaşma netliği bozmaz; sitenin çizim
   katmanına transform/zoom UYGULANMAZ (zoom kalemin işaret yerlerini kaydırıyordu, 21.10 ölçüldü).
   Kurgu (1080×1920): üst 0–200 marka şeridi + tek başlık · 200–1280 kamera (1080×1080) · 1280–1500 iri alt yazı · altta büyük Nöbetçi
   (konuşurken zıplar). Sitenin pencere başlığı, düğmeleri ve kendi alt yazı satırı gizlenir (alt yazı bizim şeritte, iri).
   METİN KAPISI: md "## Ekrana eklenen yazılar" + "## Alt yazılar".   Kullanım: node arac/video/cizerek/kare3.js [--ses-alis 4] [--onizleme]
   🚫 GÖRMEZ: sitedeki çizimin doğruluğu · ses tonlaması (kulakla) · kamera hedefinin her soruda doğru seçilmesi (bu soruya göre ayarlı).
   ============================================================================ */
'use strict';
const fs = require('fs'), path = require('path'), { execFileSync } = require('child_process');
let chromium; try { ({ chromium } = require('playwright')); } catch (e) { ({ chromium } = require('C:/Users/cemdi/.claude/araclar/kayit/node_modules/playwright')); }
const KOK = path.resolve(__dirname, '..', '..', '..');
const arg = n => { const i = process.argv.indexOf(n); return i > -1 ? process.argv[i + 1] : null; };
const ALIS = arg('--ses-alis') || '4', ONIZLEME = process.argv.includes('--onizleme');
const DIZ = 'C:/Users/cemdi/OneDrive/Masaüstü/mevzuat işi/_yerel-veri-kasasi/nobetci-cizerek';
const FF = 'C:/Users/cemdi/AppData/Local/Microsoft/WinGet/Packages/Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe/ffmpeg-9.0-full_build/bin/ffmpeg.exe';
const ff = a => execFileSync(FF, ['-nostdin', '-y', '-v', 'error', ...a], { stdio: 'inherit' });
const URL = 'https://tetikte.com/kaydir/vitrin/ornek-smmm.html?k=kontrol';
const FPS = 25, KARE = 1000 / FPS, VW = 360, VH = 640;

const md = fs.readFileSync(path.join(KOK, 'pazarlama', 'reklam', 'instagram-nobetci-cizerek-cozuyor.md'), 'utf8').replace(/<!--[\s\S]*?-->\r?\n?/g, '');
const bolum = ad => (new RegExp(`## ${ad}\\r?\\n([\\s\\S]*?)(?=\\r?\\n## )`).exec(md) || [, ''])[1];
const Y = bolum('Ekrana eklenen yazılar').split(/\r?\n/).map(s => s.trim()).filter(Boolean);
if (Y.length !== 5 || Y[0] !== 'Reklam') { console.error('METİN KAPISI: "Ekrana eklenen yazılar" 5 satır olmalı'); process.exit(3); }
const [ETIKET, , BASLIK, KAPANIS, ADRES] = Y;
const ALT = Object.fromEntries([...bolum('Alt yazılar').matchAll(/^(a\d): (.+)$/gm)].map(x => [x[1], x[2].trim()]));
if (Object.keys(ALT).length !== 9) { console.error('METİN KAPISI: "Alt yazılar" 9 satır olmalı'); process.exit(3); }
const sure = JSON.parse(fs.readFileSync(path.join(DIZ, `sureler-alis${ALIS}.json`), 'utf8'));
const MASKOT = path.join(KOK, 'gorsel', 'maskot-giris.jpg');

/* Zaman çizelgesi: her parça bir sesle eş */
const P = []; let t = 0;
const ekle = (ad, sn, ses, alt) => { P.push({ ad, bas: t, son: t + sn, ses, alt }); t += sn; };
ekle('kanca', sure.s0 + 0.3, 's0', 'a0');
ekle('secim', 1.6, null, 'a0');
ekle('ac', 0.6, null, null);
for (let i = 1; i <= 8; i++) ekle('adim' + i, sure['s' + i] + 0.25, 's' + i, 'a' + i);
ekle('kapanis', 2.4, null, null);
const TOPLAM = t;
const CAM_Y = 200, CAM = 1080, ALT_Y = 1280;

const CSS = `.czUst,.czAlc,.czAlt{display:none!important}.czKat{border-radius:0!important}
#vDokun{position:fixed;z-index:2147483003;width:44px;height:44px;margin:-22px 0 0 -22px;border-radius:50%;border:3px solid #ffc24b;display:none;pointer-events:none}`;

(async () => {
  const kareDiz = path.join(DIZ, 'kareler3'); fs.rmSync(kareDiz, { recursive: true, force: true }); fs.mkdirSync(kareDiz, { recursive: true });
  const tarayici = await chromium.launch();
  /* 1) sabit kurgu parçaları: zemin, maskot, alt yazılar, kapanış (1080 px ölçeğinde) */
  const sayfaBas = async (w, h, html, dosya) => { const p = await tarayici.newPage({ viewport: { width: w, height: h } });
    await p.setContent('<!doctype html><meta charset="utf-8"><link href="https://fonts.googleapis.com/css2?family=Inter:wght@600;800;900&display=block" rel="stylesheet">' + html, { waitUntil: 'networkidle' });
    await p.evaluate(() => document.fonts.ready); await p.screenshot({ path: dosya, omitBackground: true }); await p.close(); };
  const ZEMIN = 'background:radial-gradient(circle at 80% 4%,#f5a52433,transparent 40%),radial-gradient(circle at 10% 96%,#3b82f629,transparent 45%),#0b1626';
  const esc = s => s.replace(/&/g, '&amp;').replace(/</g, '&lt;');
  await sayfaBas(1080, 1920, `<style>*{margin:0}body{width:1080px;height:1920px;${ZEMIN};font-family:Inter,sans-serif;color:#f4f6fa}
    .et{position:absolute;left:44px;top:236px}.b{position:absolute;left:0;right:0;top:96px;text-align:center;font-weight:900;font-size:56px;letter-spacing:-1.5px}
    .b b{color:#ffc24b}.cer{position:absolute;left:0;top:${CAM_Y}px;width:1080px;height:${CAM}px;background:#fff}
    .adr{position:absolute;left:0;right:0;top:1660px;text-align:center;font-weight:800;font-size:46px;color:#ffc24b;opacity:.85}
    .cz{position:absolute;left:240px;right:240px;top:1620px;height:2px;background:#f5a52455}</style>
    <div class="b">✍️ ${esc(BASLIK).replace(/(çizerek)/, '<b>$1</b>')}</div><div class="cer"></div><div class="cz"></div><div class="adr">${esc(ADRES)}</div>`, path.join(DIZ, 'v3-zemin.png'));
  const mb64 = 'data:image/jpeg;base64,' + fs.readFileSync(MASKOT).toString('base64');
  await sayfaBas(300, 300, `<style>*{margin:0}body{background:transparent}div{width:280px;height:280px;margin:10px;border-radius:50%;background:#fff url(${mb64}) center 18%/150% no-repeat;box-shadow:0 0 0 8px #f5a524}</style><div></div>`, path.join(DIZ, 'v3-maskot.png'));
  for (const [k, v] of Object.entries(ALT)) await sayfaBas(1080, 240, `<style>*{margin:0}body{width:1080px;height:240px;display:flex;align-items:center;padding:0 40px 0 330px;box-sizing:border-box;
      font:800 50px/1.18 Inter,sans-serif;color:#fff;letter-spacing:-1px}em{font-style:normal;color:#ffc24b}</style>
      <p>${esc(v).replace(/(\d{1,3}(?:\.\d{3})+(?:\s*₺)?(?:\s*−\s*\d{1,3}(?:\.\d{3})+)?|Her 5 kişiden 4'ü yanlış yaptı\.|E\b)/g, '<em>$1</em>')}</p>`, path.join(DIZ, `v3-${k}.png`));
  await sayfaBas(1080, 1920, `<style>*{margin:0}body{width:1080px;height:1920px;${ZEMIN};display:flex;flex-direction:column;align-items:center;justify-content:center;gap:50px;padding-bottom:300px;box-sizing:border-box;font-family:Inter,sans-serif;text-align:center}
    .m{width:340px;height:340px;border-radius:50%;background:#fff url(${mb64}) center 18%/150% no-repeat;box-shadow:0 0 0 12px #f5a524,0 0 90px #f5a52499}
    p{font-weight:900;font-size:86px;line-height:1.1;color:#f4f6fa;letter-spacing:-2.5px;padding:0 70px}.a{font-size:68px;color:#ffc24b;letter-spacing:0}.et{position:absolute;left:44px;top:236px;font-size:28px;color:#f4f6fab3}</style>
    <div class="m"></div><p>${esc(KAPANIS)}</p><p class="a">${esc(ADRES)}</p>`, path.join(DIZ, 'v3-kapanis.png'));

  /* 2) site: saat durdurulur, kamera kare kare */
  const ctx = await tarayici.newContext({ viewport: { width: VW, height: VH }, deviceScaleFactor: 3, isMobile: true, hasTouch: true, locale: 'tr-TR' });
  const sayfa = await ctx.newPage();
  await sayfa.clock.install();
  await sayfa.goto(URL, { waitUntil: 'networkidle' });
  await sayfa.clock.runFor(1500);
  await sayfa.addStyleTag({ content: CSS });
  await sayfa.evaluate(() => { const d = document.createElement('div'); d.id = 'vDokun'; document.body.appendChild(d); });
  await sayfa.clock.runFor(200);

  const yap = async (ad) => {
    if (ad === 'secim') {
      const a = sayfa.getByText('40.000 ₺ yüksek gösterilmiştir', { exact: false }).first(); const k = await a.boundingBox();
      await sayfa.evaluate(([x, y]) => { const d = document.getElementById('vDokun'); d.style.left = x + 'px'; d.style.top = y + 'px'; d.style.display = 'block'; }, [k.x + k.width / 2, k.y + k.height / 2]);
      await a.click({ noWaitAfter: true });
    }
    if (ad === 'ac') { await sayfa.evaluate(() => { document.getElementById('vDokun').style.display = 'none'; });
      await sayfa.getByText('Nöbetçi çizerek çözsün', { exact: false }).first().evaluate(el => el.click()); }
    const m = /^adim(\d)$/.exec(ad);
    if (m) { await sayfa.evaluate(() => document.querySelector('.czIleri').click());
      if (m[1] === '2') await sayfa.evaluate(() => { const g = document.querySelector('.czGovde'); g.scrollTo({ top: g.scrollHeight, behavior: 'smooth' }); }); }
  };
  /* kamera hedefi (CSS px, kare pencere): parçaya göre ilgi alanı */
  const hedef = (ad) => sayfa.evaluate((ad) => {
    const R = el => el && el.getBoundingClientRect(); const VW = 360;
    const kutu = (r, pay, enAz) => { if (!r) return null; const w = Math.max(enAz, r.width + pay * 2, r.height + pay * 2); return { cx: r.left + r.width / 2, cy: r.top + r.height / 2, w }; };
    if (ad === 'kanca') { const s = [...document.querySelectorAll('div,p')].find(x => /İşletme, 1\.09\.2026/.test(x.textContent) && x.children.length < 3 && x.getBoundingClientRect().height < 300); return kutu(R(s), 10, 340); }
    if (ad === 'secim') { const s = [...document.querySelectorAll('*')].find(x => /Senin seçimin A/.test(x.textContent) && x.children.length < 8 && x.getBoundingClientRect().height < 260); return kutu(R(s), 14, 330); }
    if (ad === 'ac' || ad === 'adim1') return kutu(R(document.querySelector('.czSoru')), 8, 340);
    if (/^adim[2-6]$/.test(ad)) { const s = [...document.querySelectorAll('.czSat')].filter(x => x.textContent.trim()); const son = s[s.length - 1];
      const kar = R(document.querySelector('.czKar')); if (!son) return kutu(kar, 6, 320);
      /* pencere karalama kutusunun sol kenarına hizalı (ortalı 300 px'te satır başları kesiliyordu, 22.10 önizleme) */
      /* son satır pencerenin alt %72'sinde: yazılmış satırlar ekranı doldursun (ortalıda altta boş satırlar kalıyordu, 22.10) */
      const r = R(son), w = 324; return { cx: (kar ? kar.left - 4 : 10) + w / 2, cy: r.top + r.height / 2 - w * 0.32, w }; }
    if (ad === 'adim7') { const e = [...document.querySelectorAll('.czSik')].find(x => /^E\)/.test(x.textContent.trim())); return kutu(R(e), 70, 320); }
    if (ad === 'adim8') { const a = [...document.querySelectorAll('.czSik')].find(x => /^A\)/.test(x.textContent.trim())); return kutu(R(a), 60, 320); }
    return { cx: VW / 2, cy: 320, w: 360 };
  }, ad);

  const N = Math.round(TOPLAM * FPS); let parca = -1, cam = null;
  const ornek = ONIZLEME ? new Set([1.5, 6.5, 9, 13, 18, 24, 29, 33, 39, 43].map(s => Math.round(s * FPS))) : null;
  const kayit = [];
  for (let i = 0; i < N; i++) {
    const sn = i / FPS, pi = P.findIndex(p => sn >= p.bas && sn < p.son);
    if (pi !== parca) { parca = pi; await yap(P[pi].ad); }
    const p = P[pi];
    if (p.ad !== 'kapanis') {
      const h = (await hedef(p.ad)) || { cx: VW / 2, cy: 320, w: 360 };
      h.w = Math.min(VW, Math.max(260, h.w));
      cam = cam ? { cx: cam.cx + (h.cx - cam.cx) * 0.12, cy: cam.cy + (h.cy - cam.cy) * 0.12, w: cam.w + (h.w - cam.w) * 0.12 } : h;
      let w = Math.round(cam.w), x = Math.round(cam.cx - w / 2), y = Math.round(cam.cy - w / 2);
      x = Math.max(0, Math.min(VW - w, x)); y = Math.max(0, Math.min(VH - w, y));
      if (!ornek || ornek.has(i)) await sayfa.screenshot({ path: path.join(kareDiz, String(i).padStart(5, '0') + '.png'), clip: { x, y, width: w, height: w } });
      kayit.push([x, y, w]);
    }
    await sayfa.clock.runFor(KARE);
  }
  await tarayici.close();
  /* 3) kurgu: kamera kareleri 1080×1080'e (değişen kırpım boyu ffmpeg'de yeniden ölçeklenir) + zemin + alt yazılar + maskot */
  const kamN = kayit.length, KAM_SN = kamN / FPS;
  if (ONIZLEME) { console.log('önizleme kareleri: ' + kareDiz); return; }
  const kamVid = path.join(DIZ, 'v3-kamera.mp4');
  ff(['-framerate', String(FPS), '-i', path.join(kareDiz, '%05d.png'), '-vf', `scale=${CAM}:${CAM}:flags=lanczos,format=yuv420p`, '-c:v', 'libx264', '-crf', '16', '-preset', 'medium', kamVid]);
  const altlar = P.filter(p => p.alt);
  const girdi = ['-loop', '1', '-i', path.join(DIZ, 'v3-zemin.png'), '-i', kamVid, '-loop', '1', '-i', path.join(DIZ, 'v3-maskot.png'), '-loop', '1', '-i', path.join(DIZ, 'v3-kapanis.png')];
  const altDosya = [...new Set(altlar.map(p => p.alt))]; altDosya.forEach(a => girdi.push('-loop', '1', '-i', path.join(DIZ, `v3-${a}.png`)));
  const konus = P.filter(p => p.ses).map(p => `between(t,${p.bas.toFixed(2)},${(p.bas + sure[p.ses]).toFixed(2)})`).join('+');
  let fc = `[0:v][1:v]overlay=0:${CAM_Y}:eof_action=pass[v0]`; let son = 'v0';
  altlar.forEach((p, i) => { const k = 4 + altDosya.indexOf(p.alt); fc += `;[${son}][${k}:v]overlay=0:${ALT_Y}:enable='between(t,${p.bas.toFixed(2)},${p.son.toFixed(2)})'[va${i}]`; son = 'va' + i; });
  fc += `;[${son}][2:v]overlay=24:'${ALT_Y - 30}-if(${konus},14*abs(sin(t*9)),0)':enable='lt(t,${KAM_SN.toFixed(2)})'[vm]`;
  fc += `;[vm][3:v]overlay=0:0:enable='gte(t,${KAM_SN.toFixed(2)})',format=yuv420p[v]`;
  const sesler = P.filter(p => p.ses).map(p => ({ f: path.join(DIZ, `ses-${p.ses}-alis${ALIS}.mp3`), at: p.bas + 0.1 }));
  const s0 = girdi.length / 2; // sonraki giriş dizini (her giriş için '-i' çifti; -loop'lu girişler 4 öğe) → hesap aşağıda
  const vidGirdiSay = 4 + altDosya.length;
  sesler.forEach(s => girdi.push('-i', s.f));
  fc += ';' + sesler.map((s, i) => `[${vidGirdiSay + i}:a]adelay=${Math.round(s.at * 1000)}|${Math.round(s.at * 1000)}[a${i}]`).join(';')
    + ';' + sesler.map((_, i) => `[a${i}]`).join('') + `amix=inputs=${sesler.length}:normalize=0,apad,atrim=0:${TOPLAM.toFixed(3)},loudnorm=I=-14:TP=-1.5:LRA=11[a]`;
  const film = path.join(DIZ, 'nobetci-cizerek-v3.mp4');
  ff([...girdi, '-filter_complex', fc, '-map', '[v]', '-map', '[a]', '-t', TOPLAM.toFixed(3), '-r', String(FPS), '-c:v', 'libx264', '-crf', '17', '-preset', 'medium',
      '-c:a', 'aac', '-b:a', '160k', '-ar', '44100', '-movflags', '+faststart', film]);
  fs.rmSync(kareDiz, { recursive: true, force: true });
  console.log(`film: ${film} (${TOPLAM.toFixed(1)} sn) · ` + P.map(p => p.ad + '@' + p.bas.toFixed(1)).join(' '));
})().catch(e => { console.error(e); process.exit(1); });
