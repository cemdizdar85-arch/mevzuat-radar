#!/usr/bin/env node
/* ============================================================================
 *  GÜNÜN SORUSU GÖRSELİ (07.10.2026, Cem "günlük 1 soru: hem Instagram günün sorusu hem sitede" -> "2 yapalım")
 *
 *  NE YAPAR: ana sayfa kartıyla AYNI soruyu (veri/vitrin-hesap.json, gün sırası = floor(Date.now()/864e5) % N, index.html ile
 *  aynı formül) Instagram'a hazır 1080x1350 karelere basar, her sınav için iki kare:
 *    · <sinav>-soru.png  : bugünün sorusu + şıklar + "Sen olsan hangisini işaretlerdin? Cevap yarın"
 *    · <sinav>-cevap.png : DÜNÜN sorusunun cevabı: en sık yanlış (kırmızı) + tuzağı, doğru (yeşil) + Nöbetçi'nin açıklaması
 *  + veri/gunun-sorusu.json (tarih, kimlikler, paylaşım metinleri). Paylaşım sayfası: gunun-sorusu.html.
 *  Instagram'a OTOMATİK PAYLAŞMAZ (Meta işletme bağlantısı yok); görseli ekip elle paylaşır.
 *
 *  Kurallar: soru/şık/açıklama kasadan (robot dosyası) AYNEN; rakam/iddia eklenmez ("çok çıkan", "%X geçti" YOK -
 *  SINAV RAKAMI KANITLI kuralı). Renkler site paletinden (stil-acik.css). Basım: Chrome headless (--screenshot).
 *  🚫 GÖRMEZ: görselde metin taşması (uzun soru küçük puntoya iner; 560+ harf soru listeye zaten girmez) - ilk basımlar gözle bakılır.
 *
 *  Kullanım: node motor/gunun-sorusu-gorsel.js [--tarih 2026-10-08] [--cikti gorsel/gunun]  (CHROME yolu: ortam CHROME ya da bilinen yollar)
 * ==========================================================================*/
'use strict';
const fs = require('fs'), path = require('path'), { execFileSync } = require('child_process');
const KOK = path.join(__dirname, '..');
const arg = (a, v) => { const i = process.argv.indexOf(a); return i > 0 ? process.argv[i + 1] : v; };
const CIKTI = path.join(KOK, arg('--cikti', 'gorsel/gunun'));
const GUN = 864e5;
const simdi = arg('--tarih') ? new Date(arg('--tarih') + 'T07:00:00+03:00').getTime() : Date.now();
const AD = { sgs: 'SMMM Staja Giriş', yeterlilik: 'SMMM Yeterlilik' };
const ETIKET = { sgs: '#smmm #stajagiris #sgs #muhasebe #mali​musavir #tetikte'.replace(/\u200b/g, ''), yeterlilik: '#smmm #yeterlilik #bitirme #muhasebe #malimusavir #tetikte' };
const kac = s => String(s == null ? '' : s).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
const buyuk = s => String(s).replace(/i/g, 'İ').toUpperCase();
const kisalt = (s, n) => { s = String(s || '').replace(/\s+/g, ' ').trim(); if (s.length <= n) return s; const k = s.slice(0, n); const p = Math.max(k.lastIndexOf('. '), k.lastIndexOf('; ')); return (p > n * 0.5 ? k.slice(0, p + 1) : k.replace(/\s+\S*$/, '') + '…'); };

function chrome() {
  const adaylar = [process.env.CHROME, 'google-chrome', 'google-chrome-stable', 'chromium-browser', 'chromium',
    'C:/Program Files/Google/Chrome/Application/chrome.exe', 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe'].filter(Boolean);
  for (const c of adaylar) { try { execFileSync(c, ['--version'], { stdio: 'ignore' }); return c; } catch (e) { if (fs.existsSync(c)) return c; } }
  throw new Error('Chrome bulunamadı (CHROME ortam değişkeni ver)');
}

const STIL = `*{box-sizing:border-box}html,body{margin:0;width:1080px;height:1350px}
body{background:#fbfaf8;color:#0f1b2d;font-family:Inter,"Segoe UI","DejaVu Sans",Arial,sans-serif;display:flex;flex-direction:column;padding:64px 72px 56px}
.ust{display:flex;align-items:center;justify-content:space-between;margin-bottom:34px}.ust img{height:58px}
.etiket{font-size:24px;letter-spacing:.12em;font-weight:800;color:#8a6224}
.ders{font-size:26px;color:#3d4b63;font-weight:600;margin:0 0 18px}
.soru{font-weight:700;line-height:1.38;margin:0 0 28px}
.siklar{display:grid;gap:14px;margin:0}
.sik{display:flex;gap:18px;align-items:flex-start;background:#fff;border:2px solid #e6e2da;border-radius:16px;padding:16px 22px;font-size:30px;line-height:1.3}
.sik b{flex:none;min-width:34px}.sik em{margin-left:auto;font-style:normal;font-weight:800;font-size:24px;white-space:nowrap;padding-left:12px}
.sik.sen{border-color:#b91c1c;background:#fbeeee}.sik.sen em{color:#b91c1c}.sik.dogru{border-color:#146f35;background:#ecf6ef}.sik.dogru em{color:#146f35}
.blok{border-left:6px solid;border-radius:0 14px 14px 0;padding:16px 22px;margin:0 0 16px;font-size:25px;line-height:1.4}.kisa .sik{padding:11px 20px;font-size:27px}.kisa .siklar{gap:10px}
.blok.sen{border-color:#b91c1c;background:#fbeeee}.blok.dogru{border-color:#146f35;background:#ecf6ef}.blok h3{margin:0 0 8px;font-size:30px}
.blok.sen h3{color:#b91c1c}.blok.dogru h3{color:#146f35}
.dip{margin-top:auto;padding-top:26px;border-top:2px solid #e6e2da;display:flex;justify-content:space-between;align-items:flex-end;gap:20px}
.dip .cagri{font-size:32px;font-weight:800;line-height:1.3}.dip .cagri span{color:#8a6224}.dip .alan{font-size:30px;font-weight:800;white-space:nowrap}`;
const sayfa = (govde, logo) => `<!doctype html><html lang="tr"><head><meta charset="utf-8"><link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700;800&display=swap" rel="stylesheet"><style>${STIL}</style></head><body>
<div class="ust"><img src="${logo}" alt="Tetikte"><div class="etiket">${govde.etiket}</div></div>${govde.html}</body></html>`;

function soruKare(s, k, logo) {
  const n = String(k.soru).length, punto = n > 420 ? 31 : n > 300 ? 35 : 40;
  const siklar = Object.keys(k.siklar).sort().map(h => `<div class="sik"><b>${h})</b><span>${kac(k.siklar[h])}</span></div>`).join('');
  return sayfa({ etiket: 'GÜNÜN SORUSU', html: `<p class="ders">${kac(AD[s])} · ${kac(k.ders)}</p>
<p class="soru" style="font-size:${punto}px">${kac(k.soru)}</p><div class="siklar">${siklar}</div>
<div class="dip"><div class="cagri">Sen olsan hangisini işaretlerdin?<br><span>Cevap ve Nöbetçi'nin anlatımı yarın.</span></div><div class="alan">tetikte.com</div></div>` }, logo);
}
function cevapKare(s, k, logo) {
  const t = (k.tuzaklar || {})[k.secim] || { ad: k.tuzak_ad, metin: k.tuzak_metin };
  const siklar = Object.keys(k.siklar).sort().map(h => { const c = h === k.dogru ? 'dogru' : h === k.secim ? 'sen' : ''; const e = h === k.dogru ? 'Doğru ✓' : h === k.secim ? 'En sık yanlış ✕' : '';
    return `<div class="sik ${c}"><b>${h})</b><span>${kac(k.siklar[h])}</span><em>${e}</em></div>`; }).join('');
  return sayfa({ etiket: 'DÜNÜN SORUSUNUN CEVABI', html: `<div class="kisa" style="display:contents"><p class="ders">${kac(AD[s])} · ${kac(k.ders)}</p>
<p class="soru" style="font-size:26px;font-weight:600;color:#3d4b63;margin-bottom:20px">${kac(kisalt(k.soru, 190))}</p>
<div class="siklar" style="margin-bottom:22px">${siklar}</div>
<div class="blok sen"><h3>Tuzak: ${kac(t.ad || 'en sık yapılan yanlış')}</h3>${kac(kisalt(t.metin, 230))}</div>
<div class="blok dogru"><h3>Doğrusu ${kac(k.dogru)})</h3>${kac(kisalt(k.aciklama, 260))}</div>
<div class="dip"><div class="cagri">Her yanlışını Nöbetçi böyle anlatır.<br><span>Bugünün sorusu sitede, kendin çöz.</span></div><div class="alan">tetikte.com</div></div></div>` }, logo);
}
const metinSoru = (s, k) => `Günün sorusu · ${AD[s]} · ${k.ders}\n\nSen olsan hangisini işaretlerdin? Cevabını yoruma yaz; doğru cevap ve Nöbetçi'nin anlatımı yarın.\n\nBeklemek istemiyorsan tetikte.com'da kendin çöz, Nöbetçi anında anlatsın.\n\n${ETIKET[s]}`;
const metinCevap = (s, k) => { const t = (k.tuzaklar || {})[k.secim] || { ad: k.tuzak_ad };
  return `Dünün sorusunun cevabı: ${k.dogru}) ${k.siklar[k.dogru]}\n\nEn sık yapılan yanlış ${k.secim}) - ${t.ad || 'tuzak'}. Nöbetçi'nin anlatımı görselde.\n\nBugünün sorusu tetikte.com'da: çöz, yanlışını Nöbetçi anlatsın.\n\n${ETIKET[s]}`; };

function bas(c, html, png) {
  const tmp = png.replace(/\.png$/, '.html'); fs.writeFileSync(tmp, html);
  execFileSync(c, ['--headless=new', '--disable-gpu', '--hide-scrollbars', '--no-sandbox', '--force-device-scale-factor=1', '--window-size=1080,1350',
    '--virtual-time-budget=4000', '--allow-file-access-from-files', '--screenshot=' + png, 'file://' + tmp.replace(/\\/g, '/').replace(/^([A-Za-z]):/, '/$1:')], { stdio: 'ignore', timeout: 60000 });
  fs.unlinkSync(tmp);
  if (!fs.existsSync(png) || fs.statSync(png).size < 20000) throw new Error('görsel basılamadı: ' + path.basename(png));
}

function ana() {
  const d = JSON.parse(fs.readFileSync(path.join(KOK, 'veri', 'vitrin-hesap.json'), 'utf8')).sinavlar || {};
  fs.mkdirSync(CIKTI, { recursive: true });
  const c = chrome(), logo = 'file://' + path.join(KOK, 'gorsel', 'logo-mail.png').replace(/\\/g, '/').replace(/^([A-Za-z]):/, '/$1:');
  /* 07.10 Cem ("1.2 yap"): basım vitrin robotunun ARKASINDAN koşar (gunun-sorusu.yml workflow_run) ve gün içinde birkaç kez
     tetiklenebilir. Sabah paylaşılan soru gün ortasında değişmesin: bugünün (TR) dosyası zaten basılmışsa DOKUNULMAZ
     (bilerek yeniden basım: --zorla). Gün sırası TÜRKİYE günüdür (önceden dünya saati günüydü: 00:00-03:00 arası basımda
     yeni günün tarihine eski günün sorusu yazılıyordu). Dünün cevabı, dün GERÇEKTEN basılan sorudan (eski dosya) alınır;
     eski dosya dünün değilse formül. */
  const trGun = Math.floor((simdi + 3 * 36e5) / GUN), tarih = new Date(simdi + 3 * 36e5).toISOString().slice(0, 10);
  const dunTarih = new Date(simdi + 3 * 36e5 - GUN).toISOString().slice(0, 10);
  let eski = null; try { eski = JSON.parse(fs.readFileSync(path.join(KOK, 'veri', 'gunun-sorusu.json'), 'utf8')); } catch (e) {}
  if (eski && eski.tarih === tarih && !process.argv.includes('--zorla') && !arg('--tarih')) { console.log(`GÜNÜN SORUSU: ${tarih} zaten basılmış - dokunulmadı (yeniden basmak için --zorla)`); return; }
  const gun = trGun, ozet = { uretici: 'motor/gunun-sorusu-gorsel.js', tarih, sinavlar: {} };
  for (const s of ['sgs', 'yeterlilik']) {
    const L = d[s] || []; if (!L.length) { console.log(`GÜNÜN SORUSU ${s}: liste boş - atlandı`); continue; }
    const dunId = eski && eski.tarih === dunTarih && eski.sinavlar && eski.sinavlar[s] && eski.sinavlar[s].soru_id;
    const bugun = L[gun % L.length], dun = (dunId && L.find(x => x.id === dunId)) || L[(gun - 1 + L.length) % L.length];
    bas(c, soruKare(s, bugun, logo), path.join(CIKTI, s + '-soru.png'));
    bas(c, cevapKare(s, dun, logo), path.join(CIKTI, s + '-cevap.png'));
    ozet.sinavlar[s] = { soru_id: bugun.id, cevap_id: dun.id, soru_metni: metinSoru(s, bugun), cevap_metni: metinCevap(s, dun), sira: (gun % L.length) + 1, toplam: L.length };
    console.log(`GÜNÜN SORUSU ${s}: bugün ${bugun.id} · dünün cevabı ${dun.id} (${(gun % L.length) + 1}/${L.length})`);
  }
  fs.writeFileSync(path.join(KOK, 'veri', 'gunun-sorusu.json'), JSON.stringify(ozet, null, 1) + '\n');
}
try { ana(); } catch (e) { console.log('GÜNÜN SORUSU HATA: ' + e.message); process.exitCode = 1; }
