#!/usr/bin/env node
/* hazirla.js — MAĞAZA UYGULAMASININ İÇERİĞİNİ DERLER + ÜÇ KAPI (25.09.2026)
 *
 * Cem 25.09 ("1.2.3 üçünü de yap"): uygulamada satış yok, giriş var · paket içeriği uygulamaya
 * GÖMÜLMEZ. Mağaza paketi (AAB/IPA) herkesin indirebildiği bir dosyadır; içine giren soru
 * açık depodakiyle aynı şekilde dağılır. Bu yüzden:
 *
 *   www/ = uygulama ekranı (mobil/uygulama/) + YALNIZ KASA MODUNDAKİ Kaydır-Çöz kabukları
 *          (arac/kasa-modu.json) + ücretsiz vitrin (bilinçli açık, Cem 31.07) + ortak betikler.
 *   Kasa modunda olmayan ders sayfası uygulamaya GİRMEZ; "Hazırlanıyor" listesine yazılır.
 *
 * KAPILAR (biri düşerse www silinir, çıkış 1 — derleme durur):
 *   KAPI-KASA   paket sayfası sorusuz kabuk olmalı: data-kasa-sayfa=<yol>,
 *               `const SORULAR=window.__KASA_SORULAR||[]`, gömülü SORULAR dizisi yok.
 *   KAPI-SIZINTI vitrin dışındaki HER dosyada `"dogru":` ve `const SORULAR=[` sıfır.
 *   KAPI-SATIS  hiçbir dosyada SİTENİN satış sayfasına bağ yok (satin-al/fiyat/radar-fiyat/mesafeli-satis .html)
 *               ve vitrin dışında sitenin satış düğmesi metni yok ("Paketi al", "Paketleri gör", "Paketi güncelle").
 *               Uygulama içi satın alma (magaza.js, Google Play ödemesi) bu kapının konusu DEĞİL.
 *   KAPI-UCRETSIZ (25.09, Cem "sınav başına 30 soru ücretsiz") vitrin sayfası uygulamaya en çok
 *               UCRETSIZ_SORU soruyla girer; ders dağılımı korunarak kesilir, kesilemezse derleme durur.
 *
 * BU KAPILAR ŞUNU GÖRMEZ (yazılı körlük):
 *   - Kasa satırlarının kendisini (paket_soru RLS'i sunucuda; burada yalnız dosyaya bakılır).
 *   - Vitrin sayfalarının içeriğini: vitrin bilerek açık, yalnız soru SAYISI raporlanır.
 *   - Satış çağrısının bağlantısız, başka kelimelerle yazılmış hâlini ("ödeme yap" vb.).
 *   - Sayfaların çalışma anında uzaktan yüklediği içerik (yalnız paket_soru; o da RLS'li).
 *
 * Kullanım:  node mobil/hazirla.js [--kok <depo>] [--cikti <klasör>]
 * Öz-sınav:  node mobil/hazirla-sinavi.js   (dogrula.yml; mutasyon: HZ_MUTASYON=kasa|sizinti|satis|yama|ucretsiz)
 */
'use strict';
const fs = require('fs');
const path = require('path');

const arg = (ad, varsayilan) => { const i = process.argv.indexOf(ad); return i > 0 ? process.argv[i + 1] : varsayilan; };
const KOK = path.resolve(arg('--kok', path.join(__dirname, '..')));
const MOBIL = path.join(KOK, 'mobil');
const CIKTI = path.resolve(arg('--cikti', path.join(MOBIL, 'www')));
const MUTASYON = process.env.HZ_MUTASYON || '';

const VITRIN = ['kaydir/vitrin/sgs.html', 'kaydir/vitrin/smmm.html'];
const KAPI_ETIKETI = '<script src="../../paket-kapisi.js"></script>';
const KASA_ISARETI = 'const SORULAR=window.__KASA_SORULAR||[]';
const SATIS_BAG = /(satin-al|fiyat|radar-fiyat|mesafeli-satis)\.html/i;
const SATIS_METNI = /Paketi al|Paketleri gör|Paketi güncelle/;
const KASA_YAMA_ESKI = "dugme('../../satin-al.html', 'Paketi güncelle')";
const KASA_YAMA_YENI = "''";
const SINAV_AD = { sgs: 'SGS', yeterlilik: 'SMMM Yeterlilik' };
const UCRETSIZ_SORU = 30;   // Cem 25.09: sınav başına 30 ücretsiz soru

/* Sayfadaki `const SORULAR=[...]` dizisinin başını/sonunu dize kaçışlarına dikkat ederek bulur. */
function soruDizisiBul(html) {
  const bas = html.indexOf('const SORULAR=[');
  if (bas < 0) return null;
  const i = bas + 'const SORULAR='.length;
  let d = 0, q = false, e = false, j = i;
  for (; j < html.length; j++) {
    const c = html[j];
    if (q) { if (e) e = false; else if (c === '\\') e = true; else if (c === '"') q = false; continue; }
    if (c === '"') q = true; else if (c === '[') d++; else if (c === ']') { d--; if (d === 0) break; }
  }
  try { return { bas: i, son: j + 1, dizi: JSON.parse(html.slice(i, j + 1)) }; } catch (hata) { return null; }
}
/* Ders dağılımını koruyarak ilk n soruyu seçer: dersler sayfadaki ilk görülme sırasıyla, sırayla birer soru. */
function dengeliSec(dizi, n) {
  const gruplar = new Map();
  for (const s of dizi) { const k = String(s.ders || ''); if (!gruplar.has(k)) gruplar.set(k, []); gruplar.get(k).push(s); }
  const secilen = new Set();
  const kuyruk = [...gruplar.values()];
  while (secilen.size < Math.min(n, dizi.length)) {
    for (const g of kuyruk) { if (g.length && secilen.size < n) secilen.add(g.shift()); }
  }
  return dizi.filter((s) => secilen.has(s));   // sayfadaki özgün sıra korunur
}

const hatalar = [];
function kapi(ad, kosul, mesaj) {
  if (MUTASYON && ad.toLowerCase().indexOf(MUTASYON) >= 0) return;   // öz-sınav: kapı bilerek kör
  if (!kosul) hatalar.push(ad + ': ' + mesaj);
}
const oku = (g) => fs.readFileSync(path.join(KOK, g), 'utf8');
const var_ = (g) => fs.existsSync(path.join(KOK, g));
function yaz(goreli, icerik) {
  const hedef = path.join(CIKTI, goreli);
  fs.mkdirSync(path.dirname(hedef), { recursive: true });
  fs.writeFileSync(hedef, icerik);
}
function kopyala(kaynak, hedefGoreli) {
  const hedef = path.join(CIKTI, hedefGoreli || kaynak);
  fs.mkdirSync(path.dirname(hedef), { recursive: true });
  fs.copyFileSync(path.join(KOK, kaynak), hedef);
}
function sinaviBul(yol) { return /^kaydir\/sgs\//.test(yol) ? 'sgs' : (/^kaydir\/smmm\//.test(yol) ? 'yeterlilik' : null); }
/* Ders adı: sayfa başlıkları hep "Tetikte · Kaydır-Çöz" olduğu için klasörün dizin sayfasındaki kart adından
   okunur (kaydir/<sınav>/index.html: <a class="kart" href="x.html"><div class="ad">Ad</div><div class="sayi">N soru</div>). */
const dizinOnbellek = {};
/* Ders kartındaki "N soru" (sitenin dizin sayfası — site sayısının TEK kaynağı); ana ekranda kilitli derste gösterilir. */
const sayiOnbellek = {};
function sayiBul(yol) { baslikBul(yol); return sayiOnbellek[yol] || null; }
function cozHtml(t) {
  return t.replace(/&#(\d+);/g, (_, n) => String.fromCharCode(+n)).replace(/&amp;/g, '&').replace(/&quot;/g, '"').replace(/&lt;/g, '<').replace(/&gt;/g, '>');
}
function baslikBul(yol) {
  const klasor = path.posix.dirname(yol), ad = path.posix.basename(yol);
  if (!dizinOnbellek[klasor]) {
    dizinOnbellek[klasor] = {};
    if (var_(klasor + '/index.html')) {
      const re = /<a[^>]*href="([a-z0-9-]+\.html)"[^>]*>\s*<div class="ad">([^<]*)<\/div>(?:\s*<div class="sayi">\s*([\d.]+)\s*soru)?/g;
      let m; const html = oku(klasor + '/index.html');
      while ((m = re.exec(html))) {
        dizinOnbellek[klasor][m[1]] = cozHtml(m[2]).trim();
        if (m[3]) sayiOnbellek[klasor + '/' + m[1]] = +m[3].replace(/\./g, '');
      }
    }
  }
  return dizinOnbellek[klasor][ad] || ad.replace(/\.html$/, '').split('-').map((s) => s.charAt(0).toLocaleUpperCase('tr') + s.slice(1)).join(' ');
}
function say(metin, desen) { return (metin.match(desen) || []).length; }

/* ---------- 0. temiz başlangıç ---------- */
fs.rmSync(CIKTI, { recursive: true, force: true });
fs.mkdirSync(CIKTI, { recursive: true });

/* ---------- 1. kasa listesi ---------- */
const kasa = JSON.parse(oku('arac/kasa-modu.json'));
const kasaSayfalari = (kasa.sayfalar || []).filter((y) => /^kaydir\/(sgs|smmm)\/[a-z0-9-]+\.html$/.test(y));
kapi('KAPI-KASA', kasaSayfalari.length === (kasa.sayfalar || []).length,
  'kasa-modu.json beklenmeyen yol içeriyor: ' + (kasa.sayfalar || []).filter((y) => kasaSayfalari.indexOf(y) < 0).join(', '));

/* supabase kütüphanesinin adı paket-kapisi.js'ten okunur (sürüm yükselirse kendiliğinden izler). */
const kutuphane = (oku('paket-kapisi.js').match(/kutuphane\/supabase-[0-9.]+\.js/) || [])[0];
kapi('KAPI-KASA', !!kutuphane && var_(kutuphane), 'supabase kütüphanesi paket-kapisi.js içinde bulunamadı');

const UC_ETIKET = '<script src="../../' + kutuphane + '"></script><script src="../../ortak.js"></script><script src="../../uygulama-kapisi.js"></script><script src="../../ilerleme.js"></script><script src="../../uygulama-kaydir.js"></script>';
const katalog = { surum: '', derleme: '', paket: [], ucretsiz: [], yakinda: [] };

/* ---------- 2. paket sayfaları (yalnız kasa modu) ---------- */
for (const yol of kasaSayfalari) {
  if (!var_(yol)) { kapi('KAPI-KASA', false, yol + ' yok'); continue; }
  let html = oku(yol);
  kapi('KAPI-KASA', html.indexOf('data-kasa-sayfa="' + yol + '"') >= 0, yol + ': data-kasa-sayfa işareti yok (kabuk değil)');
  kapi('KAPI-KASA', html.indexOf(KASA_ISARETI) >= 0, yol + ': kasa betiği işareti yok');
  kapi('KAPI-KASA', say(html, /const SORULAR=\[/g) === 0, yol + ': gömülü SORULAR dizisi var');
  kapi('KAPI-KASA', say(html, new RegExp(KAPI_ETIKETI.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'g')) === 1, yol + ': paket-kapisi etiketi tam 1 kez olmalı');
  html = html.split(KAPI_ETIKETI).join(UC_ETIKET);
  yaz(yol, html);
  const sinav = sinaviBul(yol);
  katalog.paket.push({ yol, baslik: baslikBul(yol), sinav, sinavAd: SINAV_AD[sinav] || '', adet: sayiBul(yol) });
}

/* ---------- 3. ücretsiz vitrin (bilinçli açık) ---------- */
let ucretsizSoru = 0;
for (const yol of VITRIN) {
  if (!var_(yol)) continue;
  let html = oku(yol);
  const bulunan = soruDizisiBul(html);
  kapi('KAPI-UCRETSIZ', !!bulunan, yol + ': SORULAR dizisi okunamadı (kesilemedi)');
  if (bulunan && MUTASYON !== 'ucretsiz') {
    const secilen = dengeliSec(bulunan.dizi, UCRETSIZ_SORU);
    /* JSON içinde "</" kalırsa <script> erken kapanır; "<\/" aynı JSON değerini verir. */
    html = html.slice(0, bulunan.bas) + JSON.stringify(secilen).replace(/<\//g, '<\\/') + html.slice(bulunan.son);
  }
  const sonra = soruDizisiBul(html);
  const adet = sonra ? sonra.dizi.length : -1;
  kapi('KAPI-UCRETSIZ', adet >= 0 && adet <= UCRETSIZ_SORU, yol + ': ücretsiz soru ' + adet + ' > ' + UCRETSIZ_SORU);
  ucretsizSoru += Math.max(adet, 0);
  html = html.split(KAPI_ETIKETI).join('<script src="../../uygulama-kapisi.js"></script><script src="../../ilerleme.js"></script><script src="../../uygulama-kaydir.js"></script>');
  yaz(yol, html);
  const smmm = yol.indexOf('smmm') >= 0;
  katalog.ucretsiz.push({ yol, baslik: smmm ? 'SMMM Yeterlilik örnek soruları' : 'SGS örnek soruları',
    sinav: smmm ? 'yeterlilik' : 'sgs', sinavAd: 'ücretsiz', adet: Math.max(adet, 0) });
}

/* ---------- 4. hazırlanıyor: kasaya taşınmamış ders sayfaları (yalnız ad) ---------- */
for (const klasor of ['kaydir/sgs', 'kaydir/smmm']) {
  if (!var_(klasor)) continue;
  for (const ad of fs.readdirSync(path.join(KOK, klasor)).sort()) {
    const yol = klasor + '/' + ad;
    if (!/\.html$/.test(ad) || ad === 'index.html' || kasaSayfalari.indexOf(yol) >= 0) continue;
    if (/^(muhur|kapituru)-/.test(ad)) continue;   // tekrar/tur sayfaları ders değil
    const sinav = sinaviBul(yol);
    katalog.yakinda.push({ baslik: baslikBul(yol), sinav, sinavAd: SINAV_AD[sinav] || '', adet: sayiBul(yol) });
  }
}

/* ---------- 5. ortak betikler + uygulama ekranı ---------- */
let kasaYukle = oku('kasa-yukle.js');
const yamaSayisi = kasaYukle.split(KASA_YAMA_ESKI).length - 1;
if (MUTASYON !== 'yama') kasaYukle = kasaYukle.split(KASA_YAMA_ESKI).join(KASA_YAMA_YENI);
kapi('KAPI-SATIS', yamaSayisi === 1, 'kasa-yukle.js satın alma düğmesi yaması tutmadı (beklenen 1, bulunan ' + yamaSayisi + ') — dosya değişmiş, hazirla.js güncellenmeli');
yaz('kasa-yukle.js', kasaYukle);
kopyala('cihaz-kapisi.js');
/* bot koruması (Turnstile): sitedekiyle AYNI dosya ve aynı anahtar — sitede açılınca uygulamada da açık olur (26.09) */
kopyala('captcha.js');
kopyala(kutuphane);
for (const ad of fs.readdirSync(path.join(MOBIL, 'uygulama'))) kopyala(path.join('mobil', 'uygulama', ad), ad);

const paket = JSON.parse(fs.readFileSync(path.join(MOBIL, 'package.json'), 'utf8'));
katalog.surum = paket.version;
/* Mağaza ürünleri: fiyat GÖMÜLMEZ (uygulama mağazadan okur); yalnız kimlik, ad, sınav, ders sayısı. */
const magazaYolu = path.join(MOBIL, 'magaza-urunleri.json');
if (fs.existsSync(magazaYolu)) {
  const m = JSON.parse(fs.readFileSync(magazaYolu, 'utf8'));
  katalog.urunler = (m.urunler || []).map((u) => ({ id: u.id, ad: u.ad, sinav: u.sinav, ders: u.ders }));
  katalog.dersler = m.dersler || {};
  katalog.iosSatis = m.ios_satis === true;   // App Store satış anahtarı (magaza-urunleri.json)
}
katalog.derleme = process.env.TT_DERLEME || new Date().toISOString().slice(0, 10);
yaz('katalog.js', '/* hazirla.js üretir, elle düzenlenmez */\nwindow.TT_KATALOG=' + JSON.stringify(katalog) + ';\n');

/* ---------- 6. tüm çıktı taraması: sızıntı + satış ---------- */
function dolas(k) {
  return fs.readdirSync(k, { withFileTypes: true }).flatMap((d) => d.isDirectory() ? dolas(path.join(k, d.name)) : [path.join(k, d.name)]);
}
let taranan = 0, bayt = 0;
for (const tam of dolas(CIKTI)) {
  const goreli = path.relative(CIKTI, tam).split(path.sep).join('/');
  bayt += fs.statSync(tam).size;
  if (!/\.(html|js|css|json)$/.test(goreli)) continue;
  taranan++;
  const metin = fs.readFileSync(tam, 'utf8');
  const vitrin = VITRIN.indexOf(goreli) >= 0;
  if (!vitrin) {
    kapi('KAPI-SIZINTI', say(metin, /"dogru":/g) === 0, goreli + ': "dogru": alanı var (soru cevabı sızıyor)');
    kapi('KAPI-SIZINTI', say(metin, /const SORULAR=\[/g) === 0, goreli + ': gömülü SORULAR dizisi var');
    kapi('KAPI-SATIS', !SATIS_METNI.test(metin), goreli + ': satış düğmesi metni var (' + (metin.match(SATIS_METNI) || [''])[0] + ')');
  }
  if (/\.(html|js)$/.test(goreli)) {
    const eslesen = (metin.match(new RegExp('["\'/]' + SATIS_BAG.source, 'gi')) || []);
    kapi('KAPI-SATIS', eslesen.length === 0, goreli + ': satış sayfasına bağ (' + eslesen.slice(0, 3).join(', ') + ')');
  }
}

/* ---------- 7. sonuç ---------- */
const ozet = 'paket sayfası ' + katalog.paket.length + ' · ücretsiz ' + katalog.ucretsiz.length + ' sayfa/' + ucretsizSoru +
  ' soru · hazırlanıyor ' + katalog.yakinda.length + ' · taranan ' + taranan + ' dosya · ' + (bayt / 1048576).toFixed(1) + ' MB';
if (hatalar.length) {
  fs.rmSync(CIKTI, { recursive: true, force: true });
  console.log('HAZIRLA: KIRMIZI — ' + hatalar.length + ' ihlal, www silindi');
  hatalar.forEach((h) => console.log('  - ' + h));
  process.exit(1);
}
console.log('HAZIRLA: YESIL — ' + ozet + (MUTASYON ? ' · MUTASYON=' + MUTASYON : ''));
