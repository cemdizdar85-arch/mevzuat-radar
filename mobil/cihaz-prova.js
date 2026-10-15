#!/usr/bin/env node
/* ============================================================================
 * CİHAZ PROVASI — derlenmiş Android uygulamasını emülatörde gezer (15.10.2026, Cem "bunu deneyebilirsin")
 *
 * Neden: 1.8.3 R8 küçültmeli ilk derleme; R8 kapısı (r8-kapisi.js) yalnız eşleme dosyasına bakar, uygulamanın
 * cihazda açılıp açılmadığını GÖRMEZ. Bu betik mobil-cihaz-prova.yml içinde emülatöre kurulu APK'yı adb ile sürer:
 *   açılış → alt menü sekmeleri → ücretsiz örnek soru (şıkka dokun, ekran değişti mi) → Ders ders çöz → kapalı ders
 *   perdesi (✕) → çökme / ANR kaydı.
 * Çıktı: kanit/*.png (iş akışı ŞİFRELER, depo public) + günlüğe yalnız ETİKET ve SAYI (soru metni basılmaz:
 * yalnız ≤24 karakterlik tıklanabilir etiketler yazılır).
 *
 * GÖRMEZ: girişli üye akışı (şifre/Google/Apple girişi otomasyona verilmez) · paketli ders sayfası ve 12 sn
 * bildirimi (seviye notu yalnız girişli üyede çıkar) · gerçek telefon başarımı (emülatör x86_64) · iOS.
 * Çıkış: 0 = adımların hepsi geçti · 1 = en az bir adım düştü (ayrıntı günlükte) · 2 = cihaz yok.
 * ========================================================================== */
'use strict';
const { execFileSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const PAKET = 'com.tetikte.app';
const KANIT = path.resolve(process.argv[2] || 'kanit');
fs.mkdirSync(KANIT, { recursive: true });
const sonuclar = [];
let sira = 0;

function adb(args, opt) { return execFileSync('adb', args, Object.assign({ encoding: 'utf8', maxBuffer: 64 << 20 }, opt || {})); }
function bekle(ms) { Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, ms); }
function sonuc(ad, tamam, not) { sonuclar.push({ ad, tamam }); console.log((tamam ? 'GECTI ' : 'DUSTU ') + ad + (not ? '  — ' + not : '')); }

function goruntu(ad) {
  const dosya = path.join(KANIT, String(++sira).padStart(2, '0') + '-' + ad + '.png');
  fs.writeFileSync(dosya, execFileSync('adb', ['exec-out', 'screencap', '-p'], { maxBuffer: 64 << 20 }));
  return dosya;
}

/* uiautomator dökümü → düğüm listesi (metin + içerik açıklaması + sınır + tıklanabilir) */
function dokum() {
  for (let i = 0; i < 3; i++) {
    try {
      adb(['shell', 'uiautomator', 'dump', '/sdcard/ui.xml']);
      const xml = adb(['shell', 'cat', '/sdcard/ui.xml']);
      const dugum = [];
      const re = /<node ([^>]*?)\/?>/g; let m;
      while ((m = re.exec(xml))) {
        const a = {}; m[1].replace(/([\w-]+)="([^"]*)"/g, (_, k, v) => { a[k] = v.replace(/&amp;/g, '&').replace(/&quot;/g, '"').replace(/&#10;/g, ' '); });
        const b = /\[(\d+),(\d+)\]\[(\d+),(\d+)\]/.exec(a.bounds || '');
        if (!b) continue;
        dugum.push({ metin: (a.text || '').trim(), aciklama: (a['content-desc'] || '').trim(), tik: a.clickable === 'true',
          x: (+b[1] + +b[3]) >> 1, y: (+b[2] + +b[4]) >> 1, w: +b[3] - +b[1], h: +b[4] - +b[2] });
      }
      return dugum;
    } catch (e) { bekle(1500); }
  }
  return [];
}
const ad = (d) => d.metin || d.aciklama;
function etiketler(liste) {   // günlüğe yalnız kısa etiketler (soru metni sızmasın)
  const s = new Set(); for (const d of liste) { const t = ad(d); if (t && t.length <= 24) s.add(t); } return [...s].slice(0, 40).join(' | ');
}
function imza(liste) { return liste.map((d) => ad(d) + '@' + d.x + ',' + d.y).join(';'); }
function bul(liste, desen) { return liste.find((d) => desen.test(ad(d)) && d.w > 0 && d.h > 0); }
function dokun(d) { adb(['shell', 'input', 'tap', String(d.x), String(d.y)]); }
function bekleBul(desen, sn) {
  const son = Date.now() + sn * 1000; let l = [];
  while (Date.now() < son) { l = dokum(); const d = bul(l, desen); if (d) return { d, l }; bekle(1500); }
  return { d: null, l };
}
function geri() { adb(['shell', 'input', 'keyevent', '4']); bekle(2000); }

/* ---------------------------------------------------------------- */
try { adb(['get-state']); } catch (e) { console.log('CIHAZ YOK'); process.exit(2); }
adb(['logcat', '-c']);
adb(['shell', 'monkey', '-p', PAKET, '-c', 'android.intent.category.LAUNCHER', '1']);

// 1) açılış: alt menü görünmeli (Bugün / Sınavlar / Karnem / Hesap) ya da giriş ekranı
{
  const { d, l } = bekleBul(/^(Sınavlar|Bugün|Giriş yap|Hesap aç|Devam)$/, 60);
  goruntu('acilis');
  sonuc('açılış ekranı 60 sn içinde geldi', !!d, 'etiketler: ' + etiketler(l));
}

// 2) alt menü sekmeleri tek tek
for (const sekme of ['Bugün', 'Sınavlar', 'Karnem', 'Hesap']) {
  const l = dokum(); const d = bul(l, new RegExp('^' + sekme + '$'));
  if (!d) { sonuc('sekme ' + sekme, false, 'bulunamadı'); continue; }
  dokun(d); bekle(2500);
  const l2 = dokum(); goruntu('sekme-' + sekme.toLowerCase().replace('ü', 'u').replace('ı', 'i'));
  sonuc('sekme ' + sekme + ' açıldı', l2.length > 5, l2.length + ' düğüm · ' + etiketler(l2).slice(0, 300));
}

// 3) ücretsiz örnek soru: Sınavlar → Örnek sorular (Devam et / Başla) → şıkka dokun → ekran değişti mi
{
  let l = dokum(); const s = bul(l, /^Sınavlar$/); if (s) { dokun(s); bekle(2500); }
  l = dokum();
  const ornek = bul(l, /Örnek sorular/);
  let hedef = null;
  if (ornek) {   // aynı karttaki düğme (Devam et / Başla) ya da kartın kendisi
    hedef = l.filter((d) => /^(Devam et|Başla)/.test(ad(d)) && Math.abs(d.y - ornek.y) < 160)[0] || ornek;
  }
  if (!hedef) { goruntu('ornek-yok'); sonuc('örnek sorular kartı', false, etiketler(l)); }
  else {
    dokun(hedef);
    const { d: sik, l: l2 } = bekleBul(/^[A-E]$/, 45);
    goruntu('ornek-soru');
    sonuc('örnek soru 45 sn içinde yüklendi (şık harfi görünür)', !!sik, etiketler(l2).slice(0, 300));
    if (sik) {
      const once = imza(l2);
      const t0 = Date.now(); dokun(sik); bekle(2500);
      const l3 = dokum(); goruntu('sik-dokunuldu');
      sonuc('şıkka dokununca ekran değişti (sayfa donmuyor)', imza(l3) !== once, (Date.now() - t0) + ' ms · ' + l3.length + ' düğüm');
      // açık bildirim/pencere varsa ✕ ile kapanmalı
      const x = bul(l3, /^(✕|Kapat|×)$/);
      if (x) {
        const sayi = l3.filter((d) => /^(✕|Kapat|×)$/.test(ad(d))).length;
        dokun(x); bekle(1500); const l4 = dokum(); goruntu('x-dokunuldu');
        const sayi2 = l4.filter((d) => /^(✕|Kapat|×)$/.test(ad(d))).length;
        sonuc('✕ dokununca katman kapandı', sayi2 < sayi || imza(l4) !== imza(l3), sayi + ' → ' + sayi2 + ' ✕');
      } else console.log('BILGI ✕ yok (açık bildirim yok)');
    }
    geri(); geri();
  }
}

// 4) Ders ders çöz → bir ders → girişsiz: perde / kilit beklenir; ✕ ya da geri ile çıkılmalı
{
  let l = dokum(); const s = bul(l, /^Sınavlar$/); if (s) { dokun(s); bekle(2500); }
  l = dokum();
  let dd = bul(l, /Ders ders çöz/);
  if (!dd) { adb(['shell', 'input', 'swipe', '540', '1600', '540', '700', '400']); bekle(1500); l = dokum(); dd = bul(l, /Ders ders çöz/); }
  if (!dd) { goruntu('ders-ders-yok'); sonuc('Ders ders çöz kartı', false, etiketler(l)); }
  else {
    dokun(dd);
    const { d: ders, l: l2 } = bekleBul(/^Denetim$/, 20);
    goruntu('ders-listesi');
    sonuc('ders listesi açıldı (Denetim görünür)', !!ders, etiketler(l2).slice(0, 300));
    if (ders) {
      dokun(ders); bekle(8000);
      const l3 = dokum(); goruntu('denetim-girissiz');
      sonuc('Denetim sayfası tepki verdi (boş/donuk değil)', l3.length > 5, l3.length + ' düğüm · ' + etiketler(l3).slice(0, 300));
      const x = bul(l3, /^(✕|Kapat|×)$/);
      if (x) { dokun(x); bekle(3000); const l4 = dokum(); goruntu('denetim-x'); sonuc('perde ✕ çalıştı', imza(l4) !== imza(l3), etiketler(l4).slice(0, 200)); }
      geri(); geri();
    }
  }
}

// 5) çökme / donma kaydı
{
  const log = adb(['logcat', '-d', '-b', 'crash,main,system']);
  const cokme = (log.match(/FATAL EXCEPTION|AndroidRuntime: Process: com\.tetikte/g) || []).length;
  const anr = (log.match(/ANR in com\.tetikte/g) || []).length;
  const r8 = (log.match(/ClassNotFoundException|NoSuchMethodException|NoClassDefFoundError/g) || []).length;
  sonuc('çökme yok (FATAL EXCEPTION)', cokme === 0, String(cokme));
  sonuc('donma yok (ANR)', anr === 0, String(anr));
  sonuc('R8 sınıf kaybı izi yok (ClassNotFound/NoSuchMethod/NoClassDef)', r8 === 0, String(r8));
  const pid = adb(['shell', 'pidof', PAKET]).trim();
  sonuc('uygulama süreci hâlâ canlı', !!pid, pid || 'yok');
}

const dus = sonuclar.filter((s) => !s.tamam).length;
console.log('CIHAZ-PROVASI: ' + (dus ? 'KIRMIZI' : 'YESIL') + ' — ' + (sonuclar.length - dus) + '/' + sonuclar.length);
process.exit(dus ? 1 : 0);
