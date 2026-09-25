#!/usr/bin/env node
/* ============================================================================
   SAYI İDDİASI KAPISI — "sitede yazan soru sayısı, sitede gerçekten var mı?"
   24.09.2026, Cem "1 ve 3 yap"

   NİYE VAR: 24.09 hukuk taramasında fark.html'de "Bu ekrandan 30.000'den
   fazla var." yazdığı görüldü; o gün sitede yayında olan soru 7.117'ydi
   (SGS 4.388 + SMMM 2.729, kaydir/<sınav>/index.html). Ticari Reklam ve
   Haksız Ticari Uygulamalar Yön. m.9: iddianın ispatı reklam verendedir.
   Rakam bir kez doğru yazılsa bile sonra yanlışa dönebilir: yayından soru
   çekilirse (ör. 22.09 VUK m.370 alarmı ~689 soruyu çekti) sayı düşer,
   metin aynı kalır.

   HÜKÜM: yayındaki sayfalarda bir SORU SAYISI İDDİASI bulunur ve sitedeki
   sayıyla kıyaslanır. İddia > sitedeki sayı → KIRMIZI.
     • "N soru", "N+ soru", "N'den fazla (özgün) soru", "N bin soru"
     • "N'den fazla" / "N+" yanında "soru" yoksa bile, 250 karakter içinde
       "soru" geçiyorsa (fark.html vakası: "Bu ekrandan 30.000'den fazla var.")
     • Yakınında (±60 karakter) SGS/Staja geçiyorsa SGS sayısıyla,
       Yeterlilik/Bitirme geçiyorsa SMMM sayısıyla, KGK/Bağımsız Denetim
       geçiyorsa KGK sayısıyla kıyaslanır; yoksa toplamla.
   Karşı sayı: kaydir/<sınav>/index.html'deki "N soru ·" satırı (ziyaretçinin
   gördüğü yayın dizini). Kasa sayısı (veri/kasa-sayim.json) KULLANILMAZ —
   kasada olup sayfası basılmamış soru ziyaretçiye görünmez.

   🚫 BU KAPI ŞUNLARI GÖRMEZ (körlükler, "ölçülmedi" sayılır):
     • Görseldeki yazı (og-*.png, duyuru kareleri, videolar)
     • Çalışma anında JS ile kurulan sayı ("${n} soru")
     • Sayısız iddia ("binlerce soru", "en kapsamlı banka") ve soru dışı
       iddialar ("her gün doğrulanır", "%95 isabet")
     • Depo dışı metin (Instagram, e-posta, duyuru)
     • 100'ün altındaki sayılar (deneme/test boyu: "30 soruluk test")
     • kaydir/ altındaki soru sayfaları (soru metnindeki tutarlar iddia değil; taranmaz)
   RAKİP İDDİASI: karşılaştırma sayfasında rakibin kendi rakamı meşru veri
   olabilir → aynı satıra ya da bir üst satıra
   "sayi-iddia:gec <gerekçe (en az 10 harf)>" yazılır. Gerekçesiz geç = KIRMIZI.

   Kullanım:  node arac/sayi-iddia-kapisi.js           (depoyu tarar)
              node arac/sayi-iddia-kapisi.js --sinav   (öz-sınav)
   Çıkış:     0 temiz · 1 kırmızı ya da KÖR (sitedeki sayı okunamadı)
   Bedel:     0 (yalnız dosya okur)
   Mutasyon:  SIK_MUTASYON=kiyas|fazla|sinav|yorum|gec|kor → öz-sınav KIRMIZI düşmeli
   ============================================================================ */
'use strict';
const fs = require('fs');
const path = require('path');

const KOK = path.resolve(__dirname, '..');
const MUT = process.env.SIK_MUTASYON || '';

// Taranmayanlar: soru içeriği (kaydir: soru metnindeki sayılar iddia değil),
// arşiv/robot çıktısı/tasarım taslağı, git dışı klasörler.
const HARIC_KLASOR = new Set(['kaydir', 'arsiv', 'motor', 'veri', 'tasarim', 'node_modules',
  '_kaynak', '.git', '.github', 'arac', 'radar-app', 'test', 'testler']);

const SINAVLAR = [
  { kod: 'sgs',  ad: 'SGS',  desen: /\bSGS\b|staja?\s+giri[şs]|staja?\s+ba[şs]lama/iu },
  { kod: 'smmm', ad: 'SMMM Yeterlilik', desen: /yeterlilik|bitirme/iu },
  { kod: 'kgk',  ad: 'KGK',  desen: /\bKGK\b|ba[ğg][ıi]ms[ıi]z\s+denet/iu },
];

// Sayı: 7.000 / 30.000 / 4388 / "7 bin" / "7,5 bin". Önünde/arkasında rakam, nokta, eğik çizgi olmaz (2025/1 gibi).
const SAYI = String.raw`(?<![\d.,/])(\d{1,3}(?:\.\d{3})+|\d{3,})(?![\d/]|[.,]\d)|(?<![\d.,/])(\d+(?:,\d+)?)\s*bin\b`;
const FAZLA = String.raw`(?:\s*\+|\s*['’]?\s*(?:den|dan|ten|tan)\s+fazla|\s+üzeri|\s*['’]?\s*[iıuü]\s+aşkın)`;
// 1) "N ... soru" (arada en çok iki kelime: "7.000'den fazla özgün soru"); "soruluk" test boyudur, iddia değil
const DESEN_SORU = new RegExp(`(?:${SAYI})${FAZLA}?(?:\\s+[a-zçğıöşüâîû]+){0,2}\\s+soru(?!luk)`, 'giu');
// 2) "N'den fazla" / "N+" tek başına — yakında "soru" geçiyorsa
const DESEN_FAZLA = new RegExp(`(?:${SAYI})${FAZLA}`, 'giu');

function sayiDegeri(m) {
  if (m[1]) return parseInt(m[1].replace(/\./g, ''), 10);
  if (m[2]) return Math.round(parseFloat(m[2].replace(',', '.')) * 1000);
  return NaN;
}

// Yorumları satır numarası bozulmadan boşlukla doldurur (HTML <!-- -->, JS /* */ ve satır başı //).
function yorumSil(metin) {
  if (MUT === 'yorum') return metin;
  const bosalt = s => s.replace(/[^\n]/g, ' ');
  return metin
    .replace(/<!--[\s\S]*?-->/g, s => /sayi-iddia:gec/.test(s) ? s : bosalt(s))
    .replace(/\/\*[\s\S]*?\*\//g, s => /sayi-iddia:gec/.test(s) ? s : bosalt(s))
    .replace(/^[ \t]*\/\/.*$/gm, s => /sayi-iddia:gec/.test(s) ? s : bosalt(s));
}

function gecisVarMi(satirlar, i) {
  for (const s of [satirlar[i], satirlar[i - 1] || '']) {
    const m = /sayi-iddia:gec\s*([^\n]*?)(?:-->|\*\/|$)/.exec(s);
    if (m) {
      const gerekce = m[1].replace(/[^a-zçğıöşüA-ZÇĞİÖŞÜ]/g, '');
      return { var: true, gecerli: MUT === 'gec' ? true : gerekce.length >= 10, gerekce: m[1].trim() };
    }
  }
  return { var: false };
}

function hangiSinav(baglam) {
  if (MUT === 'sinav') return null;
  for (const s of SINAVLAR) if (s.desen.test(baglam)) return s;
  return null;
}

/* sayilar: { sgs: 4388, smmm: 2729, kgk: null } — null = sayfası yok (o sınavda sitede soru yok)
   Dönüş: [{dosya, satir, iddia, deger, karsi, karsiAd, hukum}] */
function metniTara(dosya, hamMetin, sayilar) {
  const metin = yorumSil(hamMetin);
  const satirBas = [0];
  for (let i = 0; i < metin.length; i++) if (metin[i] === '\n') satirBas.push(i + 1);
  const satirNo = poz => { let lo = 0, hi = satirBas.length - 1; while (lo < hi) { const md = (lo + hi + 1) >> 1; if (satirBas[md] <= poz) lo = md; else hi = md - 1; } return lo; };
  const hamSatirlar = hamMetin.split('\n');
  const toplam = Object.values(sayilar).reduce((a, b) => a + (b || 0), 0);
  const bulgular = [];
  const gorulen = new Set();

  const isle = (m, tur) => {
    const deger = sayiDegeri(m);
    if (!(deger >= 100)) return;
    const poz = m.index;
    if (gorulen.has(poz)) return;
    gorulen.add(poz);
    const baglam = metin.slice(Math.max(0, poz - 60), poz + m[0].length + 60);
    const sinav = hangiSinav(baglam);
    let karsi, karsiAd;
    if (sinav) { karsi = sayilar[sinav.kod] == null ? 0 : sayilar[sinav.kod]; karsiAd = `${sinav.ad} sitede`; }
    else { karsi = toplam; karsiAd = 'sitede toplam'; }
    const satir = satirNo(poz);
    const gec = gecisVarMi(hamSatirlar, satir);
    let hukum;
    if (MUT === 'kiyas') hukum = 'YESIL';
    else if (deger <= karsi) hukum = 'YESIL';
    else if (gec.var && gec.gecerli) hukum = 'GEC';
    else hukum = gec.var ? 'KIRMIZI-GEREKCESIZ-GEC' : 'KIRMIZI';
    bulgular.push({ dosya, satir: satir + 1, tur, iddia: m[0].replace(/\s+/g, ' ').trim(), deger, karsi, karsiAd, hukum, gerekce: gec.gerekce });
  };

  for (const m of metin.matchAll(DESEN_SORU)) isle(m, 'soru');
  if (MUT !== 'fazla') {
    for (const m of metin.matchAll(DESEN_FAZLA)) {
      const pencere = metin.slice(Math.max(0, m.index - 250), m.index + m[0].length + 250);
      if (/soru(?!luk)/iu.test(pencere)) isle(m, 'fazla+yakın soru');
    }
  }
  return bulgular;
}

/* Sitedeki sayı: kaydir/<kod>/index.html içindeki ilk "N soru ·".
   Dönüş: { sayilar, kor: [..] } — dizin var ama okunamıyorsa KÖR. */
function sitedekiSayilar(kok) {
  const sayilar = {}, kor = [];
  for (const s of SINAVLAR) {
    const yol = path.join(kok, 'kaydir', s.kod, 'index.html');
    if (!fs.existsSync(yol)) { sayilar[s.kod] = null; continue; }
    const m = /(\d[\d.]*)\s+soru\s+·/u.exec(fs.readFileSync(yol, 'utf8'));
    if (!m || MUT === 'kor') {
      if (MUT === 'kor') { sayilar[s.kod] = null; continue; }
      kor.push(`kaydir/${s.kod}/index.html: "N soru ·" satırı bulunamadı`);
      sayilar[s.kod] = null;
      continue;
    }
    sayilar[s.kod] = parseInt(m[1].replace(/\./g, ''), 10);
  }
  if (Object.values(sayilar).every(v => v == null) && MUT !== 'kor') kor.push('hiçbir sınavın yayın dizini yok (kaydir/*/index.html)');
  return { sayilar, kor };
}

function dosyalar(kok) {
  const sonuc = [];
  const gez = dizin => {
    for (const g of fs.readdirSync(dizin, { withFileTypes: true })) {
      if (g.name.startsWith('.') && g.isDirectory()) continue;
      const tam = path.join(dizin, g.name);
      if (g.isDirectory()) { if (!HARIC_KLASOR.has(g.name) && !g.name.startsWith('_')) gez(tam); continue; }
      if (/\.html?$/i.test(g.name) || g.name === 'menu.js' || g.name === 'sitemap.xml') sonuc.push(tam);
    }
  };
  gez(kok);
  return sonuc;
}

function depoyuTara(kok) {
  const { sayilar, kor } = sitedekiSayilar(kok);
  const liste = dosyalar(kok);
  const bulgular = [];
  for (const d of liste) bulgular.push(...metniTara(path.relative(kok, d).replace(/\\/g, '/'), fs.readFileSync(d, 'utf8'), sayilar));
  return { sayilar, kor, taranan: liste.length, bulgular };
}

function yazdir(r) {
  const s = r.sayilar;
  console.log(`SİTEDEKİ SAYI (kaydir/*/index.html): SGS ${s.sgs ?? 'sayfa yok'} · SMMM ${s.smmm ?? 'sayfa yok'} · KGK ${s.kgk ?? 'sayfa yok'}`);
  for (const b of r.bulgular) {
    const isaret = b.hukum === 'YESIL' ? '  ok ' : b.hukum === 'GEC' ? '  gec' : '  ✗  ';
    console.log(`${isaret} ${b.dosya}:${b.satir}  "${b.iddia}" = ${b.deger} · ${b.karsiAd} ${b.karsi}${b.hukum === 'GEC' ? ' · gerekçe: ' + b.gerekce : ''}${b.hukum.startsWith('KIRMIZI') ? '  ← ' + b.hukum : ''}`);
  }
  for (const k of r.kor) console.log(`  KÖR ${k}`);
  const kirmizi = r.bulgular.filter(b => b.hukum.startsWith('KIRMIZI')).length;
  const gec = r.bulgular.filter(b => b.hukum === 'GEC').length;
  const durum = r.kor.length ? 'KÖR' : kirmizi ? 'KIRMIZI' : 'YEŞİL';
  console.log(`SAYI İDDİASI: ${durum} · taranan dosya ${r.taranan} · iddia ${r.bulgular.length} · kırmızı ${kirmizi} · gerekçeli geç ${gec} · kör ${r.kor.length}`);
  console.log('GÖRMEZ: görseldeki yazı · JS ile kurulan sayı · sayısız iddia · depo dışı metin · 100 altı sayı · kaydir/ soru sayfaları');
  return durum === 'YEŞİL' ? 0 : 1;
}

/* ---------------------------------------------------------------- ÖZ-SINAV */
function ozSinav() {
  const say = { sgs: 4388, smmm: 2729, kgk: null };
  const V = [
    // [ad, metin, beklenen kırmızı sayısı, beklenen iddia sayısı (null = bakma)]
    ['fark.html vakası: "N\'den fazla var" + yakında soru', "<h2>Bu ekrandan 30.000'den fazla var.</h2>\n<p>Her soru; tuzağın adı</p>", 1, null],
    ['doğru iddia yeşil', "<p>7.000'den fazla soru</p>", 0, 1],
    ['N+ soru fazla', '<p>12.000+ soru seni bekliyor</p>', 1, null],
    ['SGS özelinde fazla (toplam yetse de)', '<p>5.000 SGS sorusu</p>', 1, null],
    ['Yeterlilik özelinde fazla', "<p>4.000'den fazla Yeterlilik sorusu</p>", 1, null],
    ['KGK sayfası yok → 0 ile kıyas', '<p>1.000 KGK sorusu</p>', 1, null],
    ['"bin" yazımı fazla', '<p>30 bin soru</p>', 1, null],
    ['"bin" yazımı doğru', '<p>7 bin soru</p>', 0, 1],
    ['yorumdaki sayı iddia değil', '<!-- eski: 30.000 soru -->\n<p>merhaba</p>', 0, 0],
    ['JS satır yorumu iddia değil', '<script>\n  // 30.000 soru vardı\n</script>', 0, 0],
    ['soruluk = test boyu, iddia değil', '<p>9.000 soruluk kitapçık</p>', 0, 0],
    ['tutar iddia değil (yakında soru yok)', '<p>8.000 TL ücret</p>', 0, 0],
    ['dönem kodu iddia değil', '<p>SGS 2025/1 Soru 12</p>', 0, 0],
    ['rakip rakamı gerekçeli geç', '<td>15.000 soru</td><!-- sayi-iddia:gec rakibin kendi sitesindeki iddiası, 29.08 ölçüldü -->', 0, 1],
    ['gerekçesiz geç kırmızı', '<td>15.000 soru</td><!-- sayi-iddia:gec -->', 1, null],
    ['üst satırdaki geç işareti', '<!-- sayi-iddia:gec rakip kurumun ilanındaki rakam -->\n<td>20.000 soru</td>', 0, 1],
    ['yanlış alarm yok: küçük sayı', '<p>120 soru, 150 dakika</p>', 0, null],
  ];
  let hata = 0;
  for (const [ad, metin, bekKirmizi, bekIddia] of V) {
    const b = metniTara('vaka.html', metin, say);
    const kir = b.filter(x => x.hukum.startsWith('KIRMIZI')).length;
    const ok = kir === bekKirmizi && (bekIddia == null || b.length === bekIddia);
    if (!ok) { hata++; console.log(`  ✗ ${ad}: kırmızı ${kir} (beklenen ${bekKirmizi}), iddia ${b.length}${bekIddia == null ? '' : ' (beklenen ' + bekIddia + ')'}`); }
    else console.log(`  ok ${ad}`);
  }
  // Sitedeki sayı okuma: gerçek dizin biçimleri + okunamayan dizin KÖR
  const gecici = fs.mkdtempSync(path.join(require('os').tmpdir(), 'sayi-iddia-'));
  try {
    const yaz = (k, icerik) => { fs.mkdirSync(path.join(gecici, 'kaydir', k), { recursive: true }); fs.writeFileSync(path.join(gecici, 'kaydir', k, 'index.html'), icerik); };
    yaz('sgs', '<p>4388 soru · 15 ders · her soru</p>');
    yaz('smmm', '<p>2729 soru · sekiz ders. Soru bankası</p>');
    let r = sitedekiSayilar(gecici);
    const okuma = r.sayilar.sgs === 4388 && r.sayilar.smmm === 2729 && r.sayilar.kgk === null && r.kor.length === 0;
    console.log(`  ${okuma ? 'ok' : '✗ '} dizin okuma (SGS ${r.sayilar.sgs}, SMMM ${r.sayilar.smmm}, KGK ${r.sayilar.kgk})`);
    if (!okuma) hata++;
    yaz('smmm', '<p>Soru bankası yeniden düzenleniyor</p>');
    r = sitedekiSayilar(gecici);
    const korOk = r.kor.length === 1;
    console.log(`  ${korOk ? 'ok' : '✗ '} biçimi bozulan dizin KÖR (kör ${r.kor.length})`);
    if (!korOk) hata++;
  } finally { fs.rmSync(gecici, { recursive: true, force: true }); }
  const toplamVaka = V.length + 2;
  console.log(`SAYI İDDİASI ÖZ-SINAVI: ${hata ? 'KIRMIZI' : 'YEŞİL'} (${toplamVaka - hata}/${toplamVaka})${MUT ? ' · mutasyon: ' + MUT : ''}`);
  return hata ? 1 : 0;
}

if (require.main === module) {
  process.exit(process.argv.includes('--sinav') ? ozSinav() : yazdir(depoyuTara(KOK)));
}
module.exports = { metniTara, sitedekiSayilar };
