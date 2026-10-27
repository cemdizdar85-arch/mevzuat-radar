#!/usr/bin/env node
/* KAPI-FU — FİYAT-ÜRÜN KAPISI (02.10.2026, Cem "1.2.3 üçünü de yap", madde 2)
 *
 * Olay (ölçüldü 02.10): fiyat-motoru.js "Son 15 Gün planı"nı (son15, 890 TL) satışa AÇIK tutuyordu, satin-al.html
 * her paket sayfasında 'Ek' kutusunda gösteriyordu; ürün HİÇBİR sınavı açmıyordu (paketSinavlari('son15') = []),
 * içeriği hiç kurulmamıştı. Cem fark etti, a0a66f51 ile kalktı. Para alınıp karşılığında hiçbir şey açılmayacaktı.
 *
 * Kurallar (bedel 0, ağ yok):
 *   FU-KARSILIKSIZ  satışa açık (acik:true) paket, uye-durumu.js paketSinavlari() ile hiçbir sınavı açmıyor
 *   FU-PAKET-YOK    bir sayfa/betik var olmayan paketi anıyor: "?paket=<id>" bağlantısı ya da paketBul('<id>')
 *   FU-KOR          fiyat-motoru.js ya da paketSinavlari okunamadı (kapı ölçemiyor -> KIRMIZI, "temiz" denmez)
 *
 * 🚫 BU KAPI ŞUNU GÖRMEZ:
 *   - sayfada YAZIYLA vaat edilen özellik (SRS destesi, Tetikte Skoru, "3 davet kodu" …) gerçekten var mı — yalnız PAKET bakar
 *   - paketin açtığı sınavda soru/içerik gerçekten yayında mı (ICERIK_HAZIR ayrı anahtar)
 *   - motorda hiç olmayan, yalnız düz metinle yazılmış ürün + fiyat ("X planı 890 TL" gibi elle yazılmış satır)
 *   - dinamik kurulan bağlantı ('?paket=' + değişken) ve kaydir/, veri/ altındaki sayfalar
 *   - mobil mağaza ürün listesi (mobil/magaza-sinavi.js ayrı ölçer)
 *
 * Kullanım:  node arac/fiyat-urun-kapisi.js          (depoyu denetler; bulgu varsa çıkış 1)
 *            node arac/fiyat-urun-kapisi.js --sinav  (öz-sınav; FU_MUTASYON=karsiliksiz|paket-yok|kor ile bozarak sınanır)
 */
'use strict';
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const KOK = path.resolve(__dirname, '..');
const MUT = process.env.FU_MUTASYON || '';

/* fiyat-motoru.js'i GERÇEK kodundan koşturur (replika yok). */
function motorYukle(metin) {
  const E = { console: { log() {}, warn() {}, error() {} } };
  E.window = E; E.document = { getElementById() { return null; }, querySelector() { return null; } };
  E.location = { search: '', hash: '', pathname: '/' };
  vm.createContext(E);
  vm.runInContext(metin + '\n;this.__L = (typeof paketler === "function") ? paketler() : null;', E);
  return E.__L;
}

/* uye-durumu.js'teki paketSinavlari() GERÇEK gövdesiyle çıkarılır (paket-kapisi.js kapsar() ile eşliği mobil sınav ölçer). */
function paketSinavlariYukle(metin) {
  const sira = /var SIRA = (\[[^\]]*\]);/.exec(metin);
  const fn = /function paketSinavlari\(paket\) \{[\s\S]*?\n  \}/.exec(metin);
  if (!sira || !fn) return null;
  return new Function('var SIRA = ' + sira[1] + ';\n' + fn[0] + '\nreturn paketSinavlari;')();
}

function yorumsuz(metin) {
  return metin.replace(/<!--[\s\S]*?-->/g, ' ').replace(/\/\*[\s\S]*?\*\//g, ' ').replace(/(^|[^:'"])\/\/[^\n]*/g, '$1');
}

/* Girdi: { paketler:[{id,acik}], paketSinavlari:fn, dosyalar:[{ad,metin}] }  ->  bulgular */
function denetle(g) {
  const B = [];
  if (MUT !== 'kor' && (!Array.isArray(g.paketler) || !g.paketler.length || typeof g.paketSinavlari !== 'function')) {
    B.push({ kural: 'FU-KOR', yer: 'fiyat-motoru.js / uye-durumu.js', not: 'paket listesi ya da paketSinavlari okunamadı' });
    return B;
  }
  const idler = new Set((g.paketler || []).map((p) => p.id));
  for (const p of g.paketler || []) {
    if (p.acik !== true) continue;
    const s = MUT === 'karsiliksiz' ? ['x'] : g.paketSinavlari(p.id);
    if (!s || !s.length) B.push({ kural: 'FU-KARSILIKSIZ', yer: 'fiyat-motoru.js', not: `satışta "${p.id}" (${p.ad || ''}) hiçbir sınavı açmıyor` });
  }
  for (const d of g.dosyalar) {
    const m = yorumsuz(d.metin);
    const anilan = new Set();
    for (const x of m.matchAll(/[?&]paket=([a-z0-9][a-z0-9-]*)/gi)) anilan.add(x[1].toLowerCase());
    for (const x of m.matchAll(/paketBul\(\s*['"]([a-z0-9-]+)['"]\s*\)/gi)) anilan.add(x[1].toLowerCase());
    for (const id of anilan) {
      if (MUT === 'paket-yok') continue;
      if (!idler.has(id)) B.push({ kural: 'FU-PAKET-YOK', yer: d.ad, not: `"${id}" fiyat-motoru.js paketlerinde yok` });
    }
  }
  return B;
}

function depoDosyalari() {
  const out = [];
  const atla = /^(veri|node_modules|_kaynak|kaydir|radar-app|mobil|\.git|\.github)$/;
  (function gez(dz, derin) {
    for (const e of fs.readdirSync(dz, { withFileTypes: true })) {
      const tam = path.join(dz, e.name);
      if (e.isDirectory()) { if (derin < 3 && !atla.test(e.name)) gez(tam, derin + 1); continue; }
      if (/\.html$/i.test(e.name) || (derin === 0 && /\.js$/i.test(e.name))) out.push({ ad: path.relative(KOK, tam).replace(/\\/g, '/'), metin: fs.readFileSync(tam, 'utf8') });
    }
  })(KOK, 0);
  return out;
}

function gercekGirdi() {
  let paketler = null, ps = null;
  try { paketler = motorYukle(fs.readFileSync(path.join(KOK, 'fiyat-motoru.js'), 'utf8')); } catch (e) { paketler = null; }
  try { ps = paketSinavlariYukle(fs.readFileSync(path.join(KOK, 'uye-durumu.js'), 'utf8')); } catch (e) { ps = null; }
  return { paketler, paketSinavlari: ps, dosyalar: depoDosyalari() };
}

function ozSinav() {
  const gercek = gercekGirdi();
  const ps = gercek.paketSinavlari || (() => []);
  const temelP = [{ id: 'sgs', acik: true }, { id: 'yeterlilik-1', acik: true }, { id: 'kgk-1', acik: false }];
  const V = [
    ['V1 gerçek depo bugün temiz (son15 kalktıktan sonra)', gercek, 0, null],
    ['V2 son15 geri eklenirse yakalar (02.10 olayı)', { paketler: temelP.concat([{ id: 'son15', ad: 'Son 15 Gün planı', acik: true }]), paketSinavlari: ps, dosyalar: [] }, 1, 'FU-KARSILIKSIZ'],
    ['V3 satışa KAPALI karşılıksız paket alarm vermez (KGK ön kayıt deseni)', { paketler: temelP.concat([{ id: 'deneme-x', acik: false }]), paketSinavlari: ps, dosyalar: [] }, 0, null],
    ['V4 var olmayan pakete bağlantı yakalanır', { paketler: temelP, paketSinavlari: ps, dosyalar: [{ ad: 'f.html', metin: '<a href="satin-al.html?paket=son15">al</a>' }] }, 1, 'FU-PAKET-YOK'],
    ['V5 paketBul ile var olmayan paket yakalanır', { paketler: temelP, paketSinavlari: ps, dosyalar: [{ ad: 'f.html', metin: "<script>var p = paketBul('son15');</script>" }] }, 1, 'FU-PAKET-YOK'],
    ['V6 yorum içindeki ?paket=X alarm vermez (satin-al.html:288 deseni)', { paketler: temelP, paketSinavlari: ps, dosyalar: [{ ad: 'f.html', metin: "<script>/* ?paket=X ile gelen */\n// paketBul('yok')\n</script><!-- ?paket=eski -->" }] }, 0, null],
    ['V7 dinamik bağlantı alarm vermez', { paketler: temelP, paketSinavlari: ps, dosyalar: [{ ad: 'f.html', metin: "a.href = 'satin-al.html?paket=' + x[2];" }] }, 0, null],
    ['V8 var olan pakete bağlantı alarm vermez', { paketler: temelP, paketSinavlari: ps, dosyalar: [{ ad: 'f.html', metin: '<a href="satin-al.html?paket=sgs">' }] }, 0, null],
    ['V9 motor okunamazsa KÖR = KIRMIZI', { paketler: null, paketSinavlari: ps, dosyalar: [] }, 1, 'FU-KOR'],
  ];
  let kir = 0;
  for (const [ad, girdi, bekSay, bekKural] of V) {
    const b = denetle(girdi);
    const ok = b.length === bekSay && (!bekKural || b.every((x) => x.kural === bekKural));
    if (!ok) kir++;
    console.log((ok ? 'GEÇTİ  ' : 'KALDI  ') + ad + (ok ? '' : '  -> ' + JSON.stringify(b)));
  }
  /* gerçek koşu da sınavın parçası: paketSinavlari bugün sgs ve yeterlilik paketlerine boş dememeli */
  const ps1 = ps('sgs'), ps2 = ps('yeterlilik-1');
  const okPs = ps1.indexOf('sgs') >= 0 && ps2.indexOf('yeterlilik') >= 0;
  if (!okPs) kir++;
  console.log((okPs ? 'GEÇTİ  ' : 'KALDI  ') + 'V10 uye-durumu.js paketSinavlari gerçek gövdesiyle okundu');
  console.log(kir ? `KAPI-FU ÖZ-SINAV: KIRMIZI (${kir}/${V.length + 1} vaka kaldı)` : `KAPI-FU ÖZ-SINAV: YEŞİL (${V.length + 1}/${V.length + 1})`);
  process.exit(kir ? 1 : 0);
}

if (require.main === module) {
  if (process.argv.includes('--sinav')) ozSinav();
  const g = gercekGirdi();
  const b = denetle(g);
  const acik = (g.paketler || []).filter((p) => p.acik === true).length;
  console.log(`KAPI-FU: paket ${g.paketler ? g.paketler.length : 'OKUNAMADI'} (satışta ${acik}) · taranan dosya ${g.dosyalar.length}`);
  for (const x of b) console.log(`  ${x.kural}  ${x.yer}: ${x.not}`);
  console.log(b.length ? `KAPI-FU: KIRMIZI (${b.length} bulgu)` : 'KAPI-FU: YEŞİL');
  process.exit(b.length ? 1 : 0);
}
module.exports = { denetle, motorYukle, paketSinavlariYukle };
