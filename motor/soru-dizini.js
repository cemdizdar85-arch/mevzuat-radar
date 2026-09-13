// ============================================================================
//  SORU DİZİNİ — "Soru çözmeye başla" sayfasının (sorular.html) tek veri kaynağı.
//
//  NEDEN VAR (13.09.2026)
//  Cem: "soru çözmeye başla dediğinde direkt sorular geliyor; başta sınavlar
//  gelmesi lazım (staja giriş, staj bitirme, bağımsız denetim; SPK bitirirsek
//  onu alırız), onların altında sorular ders ders olmalı."
//  Rakip ölçümü aynı sırayı gösterdi: UWorld/Becker bölüm -> konu -> test;
//  Müşavirler Kulübü SBS / Yeterlilik -> soru bankası -> konu.
//
//  NE YAPAR
//   · Sınav ve ders listesi   : veri/sinav-tek-sayfa.json (TESMER/KGK dağılımı,
//                               "sınavda kaç soru"). SPK (SPL) BİLEREK dışarıda.
//   · Çözülebilir soru        : kaydir/<sinav>/<ders>.html içindeki SORULAR -
//                               ziyaretçinin gerçekten açabildiği sayfa. Kasadaki
//                               ham sayı (15.827 gibi) BURADA KULLANILMAZ, çünkü
//                               o soruların hepsi yayında değil.
//   · En çok çıkan konular    : aynı SORULAR'dan, çıkmış dönem sayısına göre.
//   Sayfası olmayan sınavın durumu "hazirlaniyor" yazılır, ders listesi yine
//   gösterilir (ne geleceği görünsün), düğme açılmaz.
//
//  Ders sayfası sayılmayan dosyalar: index.html ve adı dersinin adından
//  türemeyen deneme sayfaları (kapituru-3, muhur-10 gibi).
//
//  ÇIKTI: veri/soru-dizini.json · API maliyeti SIFIR · yalnız yerel dosya okur.
//  Kullanım: node motor/soru-dizini.js [--kuru]
// ============================================================================
const fs = require('fs');
const path = require('path');

const KOK = path.join(__dirname, '..');
const KURU = process.argv.includes('--kuru');

function jsonOku(yol) {
  // BOM'lu dosya (PS 5.1 yazımı) JSON.parse'ı düşürür - 13.09'da yaşandı.
  return JSON.parse(fs.readFileSync(yol, 'utf8').replace(/^﻿/, ''));
}
function katla(s) {
  return String(s || '').toLocaleLowerCase('tr')
    .replace(/ı/g, 'i').replace(/ğ/g, 'g').replace(/ü/g, 'u').replace(/ş/g, 's').replace(/ö/g, 'o').replace(/ç/g, 'c')
    .replace(/[^a-z0-9]+/g, ' ').trim();
}
function slug(s) { return katla(s).replace(/ /g, '-'); }

// Sınavların sitedeki adı - adayın dili (09.09 TESMER menüsü ölçümü).
const SINAVLAR = [
  { kod: 'sgs', tek: 'SGS', ad: 'Staja Giriş', uzun: 'SMMM Staja Başlama Sınavı' },
  { kod: 'smmm', tek: 'SMMM', ad: 'Staj Bitirme', uzun: 'SMMM Yeterlilik Sınavı' },
  { kod: 'kgk', tek: 'KGK', ad: 'Bağımsız Denetçilik', uzun: 'KGK Bağımsız Denetçilik Sınavı' }
];
// sinav-tek-sayfa'da SGS bölüm adları harf katlanmış yazılı; ekranda düzgün Türkçe.
const BOLUM_AD = { 'genel kultur ve yetenek': 'Genel Kültür ve Yetenek', 'yabanci dil': 'Yabancı Dil', 'alan bilgisi': 'Alan Bilgisi' };

// "Hukuk (Ticaret H., Borçlar H., …)" -> ad "Hukuk", alt "Ticaret H., Borçlar H., …"
// "a) Türkiye Muhasebe Standartları" -> "Türkiye Muhasebe Standartları"
function adAyir(ham) {
  let ad = String(ham || '').replace(/^[a-zçğ]\)\s*/i, '').trim();
  let alt = '';
  const m = ad.match(/^(.*?)\s*\((.*)\)\s*$/);
  if (m) { ad = m[1].trim(); alt = /^Ek:/i.test(m[2]) ? '' : m[2].trim(); }
  return { ad, alt };
}

function sayfaOku(dosya) {
  const h = fs.readFileSync(dosya, 'utf8');
  const bas = h.indexOf('const SORULAR=');
  if (bas < 0) return null;
  const son = h.indexOf('\n', bas);
  const satir = h.slice(bas, son < 0 ? h.length : son);
  const a = satir.indexOf('['), b = satir.lastIndexOf(']');
  if (a < 0 || b <= a) return null;
  try { return JSON.parse(satir.slice(a, b + 1)); } catch (e) { return null; }
}

const tek = jsonOku(path.join(KOK, 'veri', 'sinav-tek-sayfa.json'));
const cikti = { uretim: new Date().toISOString().slice(0, 16).replace('T', ' '), uretici: 'motor/soru-dizini.js', sinavlar: [] };
const rapor = [];

for (const S of SINAVLAR) {
  const satirlar = (tek.dersler || []).filter(d => d.sinav === S.tek);
  const dizin = path.join(KOK, 'kaydir', S.kod);
  const sayfalar = {};   // katlanmış ders adı -> { dosya, sorular }
  if (fs.existsSync(dizin)) {
    for (const f of fs.readdirSync(dizin)) {
      if (!f.endsWith('.html') || f === 'index.html') continue;
      const sorular = sayfaOku(path.join(dizin, f));
      if (!sorular || !sorular.length) { rapor.push(`  atlandı (SORULAR yok): kaydir/${S.kod}/${f}`); continue; }
      const dersAdi = String(sorular[0].ders || '').split('|')[0].trim();
      if (slug(dersAdi) + '.html' !== f) { rapor.push(`  atlandı (ders sayfası değil): kaydir/${S.kod}/${f} · ${sorular.length} soru`); continue; }
      sayfalar[katla(dersAdi)] = { dosya: `kaydir/${S.kod}/${f}`, ad: dersAdi, sorular };
    }
  }
  const dersler = satirlar.map(d => {
    const sayfa = sayfalar[katla(d.ders)];
    const { ad, alt } = adAyir(sayfa ? sayfa.ad : d.ders);
    let konular = [];
    if (sayfa) {
      const enCok = new Map();
      for (const s of sayfa.sorular) {
        const k = String(s.konu || '').trim(); if (!k) continue;
        const donem = Math.max(+s.donem || 0, (s.cikmis && Array.isArray(s.cikmis.donemler)) ? s.cikmis.donemler.length : 0);
        const anahtar = katla(k);
        const eski = enCok.get(anahtar);
        if (!eski || donem > eski.donem) enCok.set(anahtar, { ad: k, donem });
      }
      konular = [...enCok.values()].filter(x => x.donem > 0).sort((x, y) => y.donem - x.donem).slice(0, 3);
    }
    return {
      ad, alt,
      bolum: BOLUM_AD[katla(d.bolum)] || d.bolum || '',
      sinav_soru: +d.sinav_soru || 0,
      soru: sayfa ? sayfa.sorular.length : 0,
      sayfa: sayfa ? sayfa.dosya : null,
      konular
    };
  });
  const soru = dersler.reduce((t, d) => t + d.soru, 0);
  const acikDers = dersler.filter(d => d.sayfa).length;
  cikti.sinavlar.push({
    kod: S.kod, ad: S.ad, uzun: S.uzun,
    durum: acikDers ? 'acik' : 'hazirlaniyor',
    ders_sayisi: dersler.length, acik_ders: acikDers, soru, dersler
  });
  rapor.push(`${S.ad} (${S.tek}): ${dersler.length} ders · sayfası olan ${acikDers} · çözülebilir soru ${soru}`);
  const eslesmeyen = Object.keys(sayfalar).filter(k => !satirlar.some(d => katla(d.ders) === k));
  for (const k of eslesmeyen) rapor.push(`  ⚠ ders listesinde karşılığı yok: ${sayfalar[k].dosya}`);
}

console.log('SORU DİZİNİ');
rapor.forEach(r => console.log('  ' + r));

// ÖZ-SINAV: sayfa tarafı ile dizin tarafı aynı sayıyı söylemeli; tutmazsa YAZMA.
const sgs = cikti.sinavlar.find(s => s.kod === 'sgs');
const hatalar = [];
if (!sgs || sgs.durum !== 'acik') hatalar.push('SGS açık değil - kaydir/sgs okunamadı');
for (const s of cikti.sinavlar) for (const d of s.dersler) {
  if (d.sayfa && !fs.existsSync(path.join(KOK, d.sayfa))) hatalar.push(`sayfa yok: ${d.sayfa}`);
  if (d.sayfa && d.soru === 0) hatalar.push(`sayfası var ama soru 0: ${d.ad}`);
}
if (hatalar.length) { console.log('  KIRMIZI - dizin YAZILMADI:'); hatalar.forEach(h => console.log('   · ' + h)); process.exit(1); }
if (KURU) { console.log('  kuru koşu - dosyaya YAZILMADI.'); process.exit(0); }

const hedef = path.join(KOK, 'veri', 'soru-dizini.json');
const yeni = JSON.stringify(cikti, null, 1) + '\n';
// Zaman damgası dışında değişiklik yoksa dosyaya dokunma (robot boş commit üretmesin).
let eskiGovde = null;
try { const e = jsonOku(hedef); delete e.uretim; eskiGovde = JSON.stringify(e); } catch (e) {}
const yeniGovde = (() => { const c = JSON.parse(yeni); delete c.uretim; return JSON.stringify(c); })();
if (eskiGovde === yeniGovde) { console.log('  değişiklik yok - dosyaya dokunulmadı.'); }
else { fs.writeFileSync(hedef, yeni, 'utf8'); console.log('  yazıldı -> veri/soru-dizini.json'); }
