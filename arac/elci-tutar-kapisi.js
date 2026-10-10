// arac/elci-tutar-kapisi.js — KAPI-ET: ELÇİ TUTARLARI DÖRT YERDE AYNI MI (10.10.2026, Cem "3 yapalım")
//
// NEDEN: elçi indirimi ve komisyonu dört ayrı yerde elle yazılı:
//   1) sözleşme metni   elci.html <template id="sozlesmeMetni"> Madde 5 tablosu + 6.1 kademe + 6.8 ders başı
//   2) onay maili       radar-app/edge/elci-sozlesme.ts PAKET_OZET + KADEME_NOTU
//   3) panel            elci.html DERS_KOMISYON + KADEME
//   4) satış ekranı     fiyat-motoru.js ELCI.indirim
// Biri değişip öbürü unutulursa elçiye sözleşmeden farklı rakam söylenir. Bu kapı dördünü okur, paket paket kıyaslar.
//
// 🚫 GÖRMEZ: sunucudaki elci_indirim tablosu (servis anahtarı ister; 10.10 elle ölçüldü: indirim + sabit_komisyon_tl
//    150/300/450/600 aynı) · PDF'in kendisi (yalnız template; PDF template'ten üretilir) · fiyatlar (Madde 5'in fiyat
//    sütunu; o fiyat-urun kapısının işi) · paket ADI yazım farkı (ad → paket eşlemesi aşağıdaki desenlerle).
//
//   node arac/elci-tutar-kapisi.js           gerçek depo; fark ya da okunamayan kaynak varsa çıkış 1
//   node arac/elci-tutar-kapisi.js --sinav   öz-sınav (KAPI_MUTASYON=<ad> ile bilerek bozulur, sınav KIRMIZI düşmeli)
'use strict';
const fs = require('fs');
const path = require('path');

const PAKETLER = ['sgs', 'yeterlilik-tum', 'yeterlilik-1', 'yeterlilik-2', 'yeterlilik-3', 'yeterlilik-4'];
const DERSLER = ['yeterlilik-1', 'yeterlilik-2', 'yeterlilik-3', 'yeterlilik-4'];
const MUT = process.env.KAPI_MUTASYON || '';

function sayi(s) { return Number(String(s).replace(/\./g, '')); }
function paketBul(ad) {
  if (/SGS|Staja Giriş/i.test(ad)) return 'sgs';
  if (/tüm sınav dersleri/i.test(ad)) return 'yeterlilik-tum';
  const m = /([1-4]) sınav dersi/.exec(ad);
  return m ? 'yeterlilik-' + m[1] : null;
}

// --- okuyucular: her biri {indirim:{}, komisyon:{}, kademe:[]} ya da null (okunamadı = KÖR) ---
function sozlesmeOku(html) {
  const t = /<template id="sozlesmeMetni">([\s\S]*?)<\/template>/.exec(html);
  if (!t) return null;
  const m5 = /MADDE 5[\s\S]*?<table>([\s\S]*?)<\/table>/.exec(t[1]);
  const m61 = /<b>6\.1\.<\/b>[\s\S]*?<table>([\s\S]*?)<\/table>/.exec(t[1]);
  const m68 = /<b>6\.8\.[\s\S]*?<\/p>/.exec(t[1]);
  if (!m5 || !m61 || !m68) return null;
  const indirim = {};
  for (const r of m5[1].matchAll(/<tr><td>([^<]+)<\/td><td>([\d.]+) TL<\/td>/g)) { const p = paketBul(r[1]); if (p) indirim[p] = sayi(r[2]); }
  const kademe = [...m61[1].matchAll(/<td>([\d.]+) TL<\/td>/g)].map(r => sayi(r[1]));
  const komisyon = {};
  for (const r of m68[0].matchAll(/([1-4]) sınav dersi ([\d.]+) TL/g)) komisyon['yeterlilik-' + r[1]] = sayi(r[2]);
  return { indirim, komisyon, kademe };
}
function mailOku(ts) {
  const b = /PAKET_OZET[^=]*=\s*\[([\s\S]*?)\n\];/.exec(ts);
  const k = /const KADEME_NOTU = "([^"]+)"/.exec(ts);
  if (!b || !k) return null;
  const indirim = {}, komisyon = {};
  for (const r of b[1].matchAll(/\["([^"]+)",\s*(\d+),\s*"([^"]+)"\]/g)) {
    const p = paketBul(r[1]); if (!p) continue;
    indirim[p] = Number(r[2]);
    if (DERSLER.includes(p)) { const km = /^([\d.]+) TL$/.exec(r[3]); komisyon[p] = km ? sayi(km[1]) : NaN; }
  }
  const kademe = [...k[1].matchAll(/satış ([\d.]+) TL/g)].map(r => sayi(r[1]));
  return { indirim, komisyon, kademe };
}
function panelOku(html) {
  const d = /var DERS_KOMISYON = \{([^}]+)\}/.exec(html);
  const k = /var KADEME = \[(.*?)\];/.exec(html);
  if (!d || !k) return null;
  const komisyon = {};
  for (const r of d[1].matchAll(/'(yeterlilik-[1-4])':(\d+)/g)) komisyon[r[1]] = Number(r[2]);
  const kademe = [...k[1].matchAll(/', (\d+), \d\]/g)].map(r => Number(r[1]));
  return { indirim: null, komisyon, kademe };
}
function fiyatOku(js) {
  const m = /var ELCI = \{[^]*?indirim:\{([^}]+)\}/.exec(js);
  if (!m) return null;
  const indirim = {};
  for (const r of m[1].matchAll(/'?([a-z0-9-]+)'?:(\d+)/g)) indirim[r[1]] = Number(r[2]);
  return { indirim, komisyon: null, kademe: null };
}

function kiyasla(kaynaklar) {
  const bulgu = [], kor = [];
  for (const [ad, v] of Object.entries(kaynaklar)) if (!v) kor.push(ad + ' okunamadı');
  const esas = kaynaklar['sözleşme'];
  if (!esas) return { bulgu, kor };
  for (const [ad, v] of Object.entries(kaynaklar)) {
    if (!v || ad === 'sözleşme') continue;
    if (v.indirim) for (const p of PAKETLER) {
      const a = esas.indirim[p], b = v.indirim[p];
      if (MUT === 'indirim-kor') continue;
      if (a === undefined) kor.push('sözleşmede ' + p + ' indirimi yok');
      else if (a !== b) bulgu.push(`${ad}: ${p} indirimi ${b} TL, sözleşme ${a} TL`);
    }
    if (v.komisyon) for (const p of DERSLER) {
      const a = esas.komisyon[p], b = v.komisyon[p];
      if (MUT === 'komisyon-kor') continue;
      if (a === undefined) kor.push('sözleşmede ' + p + ' komisyonu yok');
      else if (a !== b) bulgu.push(`${ad}: ${p} komisyonu ${b} TL, sözleşme ${a} TL`);
    }
    if (v.kademe && MUT !== 'kademe-kor') {
      const a = esas.kademe.slice(0, 3).join('/'), b = v.kademe.slice(0, 3).join('/');
      if (a !== b) bulgu.push(`${ad}: kademe ${b}, sözleşme ${a}`);
    }
  }
  return { bulgu, kor };
}

function depodan(kok) {
  const oku = f => { try { return fs.readFileSync(path.join(kok, f), 'utf8'); } catch (e) { return ''; } };
  const elci = oku('elci.html');
  return {
    'sözleşme': sozlesmeOku(elci),
    'onay maili': mailOku(oku('radar-app/edge/elci-sozlesme.ts')),
    'panel': panelOku(elci),
    'fiyat-motoru': fiyatOku(oku('fiyat-motoru.js')),
  };
}

function sinav() {
  const kok = path.join(__dirname, '..');
  const elci = fs.readFileSync(path.join(kok, 'elci.html'), 'utf8');
  const ts = fs.readFileSync(path.join(kok, 'radar-app/edge/elci-sozlesme.ts'), 'utf8');
  const fm = fs.readFileSync(path.join(kok, 'fiyat-motoru.js'), 'utf8');
  const kur = (e, t, f) => ({ 'sözleşme': sozlesmeOku(e), 'onay maili': mailOku(t), 'panel': panelOku(e), 'fiyat-motoru': fiyatOku(f) });
  const vakalar = [
    // [ad, elci, ts, fm, beklenen: 'temiz' | 'bulgu' | 'kor']
    ['gerçek depo temiz', elci, ts, fm, 'temiz'],
    ['mail tek ders komisyonu 150→200', elci, ts.replace('["SMMM Yeterlilik — 1 sınav dersi", 50, "150 TL"]', '["SMMM Yeterlilik — 1 sınav dersi", 50, "200 TL"]'), fm, 'bulgu'],
    ['mail SGS indirimi 400→480', elci, ts.replace('["Staja Giriş (SGS)", 400,', '["Staja Giriş (SGS)", 480,'), fm, 'bulgu'],
    ['mail kademe 1.000→1.100', elci, ts.replace('10–49. satış 1.000 TL', '10–49. satış 1.100 TL'), fm, 'bulgu'],
    ['panel 4 ders komisyonu 600→650', elci.replace("'yeterlilik-4':600", "'yeterlilik-4':650"), ts, fm, 'bulgu'],
    ['panel kademe 750→800', elci.replace("['1 – 9. satış', 750, 1]", "['1 – 9. satış', 800, 1]"), ts, fm, 'bulgu'],
    ['fiyat-motoru 2 ders indirimi 100→120', elci, ts, fm.replace("'yeterlilik-2':100", "'yeterlilik-2':120"), 'bulgu'],
    ['sözleşme 3 ders indirimi değişti, öbürleri eski', elci.replace('<td>SMMM Yeterlilik — 3 sınav dersi</td><td>150 TL</td>', '<td>SMMM Yeterlilik — 3 sınav dersi</td><td>175 TL</td>'), ts, fm, 'bulgu'],
    ['mail tablosu silinmiş → KÖR', elci, ts.replace('PAKET_OZET', 'PAKET_X'), fm, 'kor'],
    ['sözleşme şablonu yok → KÖR', elci.replace('id="sozlesmeMetni"', 'id="baska"'), ts, fm, 'kor'],
    // yanlış alarm: tutar dışı metin değişikliği bulgu üretmemeli
    ['yanlış alarm: mail notunda yazım değişikliği', elci, ts.replace('Tutarlar brüttür;', 'Bütün tutarlar brüttür;'), fm, 'temiz'],
    ['yanlış alarm: Madde 5 fiyat sütunu değişti (indirim aynı)', elci.replace('2.988 → 2.588 TL', '2.990 → 2.590 TL'), ts, fm, 'temiz'],
  ];
  let kirmizi = 0;
  for (const [ad, e, t, f, bek] of vakalar) {
    const s = kiyasla(kur(e, t, f));
    const olan = s.kor.length ? 'kor' : s.bulgu.length ? 'bulgu' : 'temiz';
    const ok = olan === bek;
    if (!ok) kirmizi++;
    console.log(`${ok ? 'YEŞİL ' : 'KIRMIZI'}  ${ad}  (beklenen ${bek}, olan ${olan}${s.bulgu.length ? ': ' + s.bulgu[0] : ''})`);
  }
  console.log(`KAPI-ET öz-sınav: ${vakalar.length - kirmizi}/${vakalar.length}${MUT ? ' · mutasyon ' + MUT : ''}`);
  process.exit(kirmizi ? 1 : 0);
}

if (process.argv.includes('--sinav')) sinav();
else {
  const s = kiyasla(depodan(path.join(__dirname, '..')));
  for (const b of s.bulgu) console.log('FARK  ' + b);
  for (const k of s.kor) console.log('KÖR   ' + k);
  console.log(`KAPI-ET: ${s.bulgu.length} fark · ${s.kor.length} kör · kıyaslanan: sözleşme ↔ onay maili, panel, fiyat-motoru (6 paket indirim, 4 ders komisyonu, 3 kademe)`);
  process.exit(s.bulgu.length || s.kor.length ? 1 : 0);
}
