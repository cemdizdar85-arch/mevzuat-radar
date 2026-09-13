// ============================================================================
//  DENEME SETİ BASICI — "Sınav gibi çöz" (sinav-gibi.html) için hazır setler.
//
//  NEDEN VAR (13.09.2026)
//  Cem: "sınav sınav, bir de sınav gibi her dersten soru çıkacak bir şey yapmak
//  lazım." Ölçüm: deneme.html'in bankası (veri/soru-bankasi.json) 09.09'da Cem
//  kararıyla boşaltıldı (0 soru); onaylı sorular (hakem + simülasyon + kör çözüm
//  + ikinci hakem) ders ders Kaydır-Çöz sayfalarında duruyor (SGS 3.678).
//
//  NE YAPAR
//   · Dağılım  : veri/sgs-sinav-yapisi.json (TESMER Uygulama Yönergesi m.6.2 -
//                ders başına soru; toplam 130). Elle rakam yazılmaz.
//   · Soru     : kaydir/sgs/<ders>.html içindeki SORULAR (yayında olan sorular).
//   · Seçim    : her derste sorular çıkmış dönem sayısına göre sıralanır (çok çıkan
//                önce), ilk (ders soru sayısı × SET) soru kart dağıtır gibi setlere
//                dağıtılır: j. soru -> (j mod SET). Böylece her set çok çıkanla az
//                çıkanı dengeli alır ve SETLER ARASINDA AYNI SORU YOKTUR.
//   · Sıra     : set içinde bölüm sırası yönerge tablosundaki gibi (Genel Kültür ve
//                Yetenek -> Yabancı Dil -> Alan Bilgisi), bölüm içinde ders sırası
//                aynı tablodaki gibi. GERÇEK KİTAPÇIK SIRASI ÖLÇÜLMEDİ (yalnız
//                Maliyet 57-64 ölçülü) - sayfa bunu açıkça yazar.
//   · Süre     : 165 dk - TÜRMOB-TESMER Staja Giriş Sınavı Uygulama Kılavuzu
//                ("toplam cevaplama süresi 165 dakikadır").
//   · Her soruya "Nöbetçi anlatsın" bağlantısı: kaydir/sgs/<ders>.html#s=<sıra>.
//
//  ÇIKTI: veri/deneme/sgs-dizin.json + veri/deneme/sgs-set-NN.json
//  API maliyeti SIFIR. Kaydır-Çöz sayfaları yeniden basılınca bu betik de koşar
//  (motor/kaydir-yayin.ps1 sonunda). Kullanım: node motor/deneme-seti-bas.js [--kuru]
// ============================================================================
const fs = require('fs');
const path = require('path');

const KOK = path.join(__dirname, '..');
const KURU = process.argv.includes('--kuru');
const SET = 10;
const SURE_DK = 165;   // TÜRMOB-TESMER Staja Giriş Sınavı Uygulama Kılavuzu
const SURE_KAYNAK = 'TÜRMOB-TESMER Staja Giriş Sınavı Uygulama Kılavuzu: toplam cevaplama süresi 165 dakika';

function jsonOku(yol) { return JSON.parse(fs.readFileSync(yol, 'utf8').replace(/^﻿/, '')); }
function katla(s) {
  return String(s || '').toLocaleLowerCase('tr')
    .replace(/ı/g, 'i').replace(/ğ/g, 'g').replace(/ü/g, 'u').replace(/ş/g, 's').replace(/ö/g, 'o').replace(/ç/g, 'c')
    .replace(/[^a-z0-9]+/g, ' ').trim();
}
const slug = s => katla(s).replace(/ /g, '-');
function sayfaOku(dosya) {
  const h = fs.readFileSync(dosya, 'utf8');
  const bas = h.indexOf('const SORULAR='); if (bas < 0) return null;
  const son = h.indexOf('\n', bas); const satir = h.slice(bas, son < 0 ? h.length : son);
  const a = satir.indexOf('['), b = satir.lastIndexOf(']'); if (a < 0 || b <= a) return null;
  try { return JSON.parse(satir.slice(a, b + 1)); } catch (e) { return null; }
}

const yapi = jsonOku(path.join(KOK, 'veri', 'sgs-sinav-yapisi.json')).sgs;
// Değerlendirme cümlesi sayfaya düzgün Türkçe yazılır; kaynak not harf katlanmış. Kaynaktaki iki OLGU
// değişirse (60+ geçer, yanlış doğruyu götürmez) bu cümle eskir -> betik DÜŞER, sessizce yanlış yazmaz.
const DEGERLENDIRME = 'Bağıl değerlendirme (ortalama 50, standart sapma 10); 60 ve üzeri puan geçer. 5 seçenekli, yanlış doğruyu götürmez.';
if (!/60\+ puan gecer/.test(yapi.not || '') || !/yanlis dogruyu goturmez/.test(yapi.not || '') || !/ortalama 50, std sapma 10/.test(yapi.not || '')) {
  console.log('KIRMIZI - veri/sgs-sinav-yapisi.json değerlendirme notu değişmiş; DEGERLENDIRME cümlesini kaynağa göre güncelle.'); process.exit(1);
}
const BOLUM_AD = { 'genel kultur ve yetenek': 'Genel Kültür ve Yetenek', 'yabanci dil': 'Yabancı Dil', 'alan bilgisi': 'Alan Bilgisi' };

// ders sayfaları: katlanmış ders adı -> {dosya, ad, sorular}
const dizin = path.join(KOK, 'kaydir', 'sgs');
const sayfalar = {};
for (const f of fs.readdirSync(dizin)) {
  if (!f.endsWith('.html') || f === 'index.html') continue;
  const S = sayfaOku(path.join(dizin, f)); if (!S || !S.length) continue;
  const ad = String(S[0].ders || '').split('|')[0].trim();
  if (slug(ad) + '.html' !== f) continue;   // deneme sayfaları (kapituru-3, muhur-10) ders sayfası değil
  sayfalar[katla(ad)] = { dosya: `kaydir/sgs/${f}`, ad, sorular: S };
}

const hatalar = [];
const setler = Array.from({ length: SET }, () => []);
const plan = [];
for (const bolum of yapi.bolumler) {
  for (const d of bolum.dersler) {
    const p = sayfalar[katla(d.ders)];
    if (!p) { hatalar.push(`ders sayfası yok: ${d.ders}`); continue; }
    const gerek = d.soru * SET;
    const havuz = p.sorular.map((s, sira) => ({ s, sira, donem: Math.max(+s.donem || 0, (s.cikmis && Array.isArray(s.cikmis.donemler)) ? s.cikmis.donemler.length : 0) }))
      .filter(x => x.s.soru && x.s.siklar && x.s.dogru && x.s.siklar[x.s.dogru] && Object.keys(x.s.siklar).length === 5)
      .sort((x, y) => (y.donem - x.donem) || String(x.s.id).localeCompare(String(y.s.id)));
    if (havuz.length < gerek) { hatalar.push(`${p.ad}: ${gerek} soru gerekli, uygun ${havuz.length}`); continue; }
    havuz.slice(0, gerek).forEach((x, j) => {
      setler[j % SET].push({
        id: x.s.id, bolum: BOLUM_AD[katla(bolum.ad)] || bolum.ad, ders: p.ad, konu: String(x.s.konu || '').trim(), donem: x.donem,
        soru: x.s.soru, siklar: x.s.siklar, dogru: x.s.dogru, sayfa: p.dosya, sira: x.sira
      });
    });
    plan.push(`${p.ad}: sınavda ${d.soru} × ${SET} set = ${gerek} (sayfada ${p.sorular.length}, uygun ${havuz.length})`);
  }
}

// ÖZ-SINAV: her set 130, setler arası tekrar yok, her setin ders dağılımı yönergeyle aynı
const beklenen = {}; yapi.bolumler.forEach(b => b.dersler.forEach(d => { beklenen[katla(d.ders)] = d.soru; }));
const gorulen = new Set();
setler.forEach((st, i) => {
  if (st.length !== yapi.toplamSoru) hatalar.push(`set ${i + 1}: ${st.length} soru (beklenen ${yapi.toplamSoru})`);
  const say = {}; st.forEach(q => { say[katla(q.ders)] = (say[katla(q.ders)] || 0) + 1; if (gorulen.has(q.id)) hatalar.push(`tekrar: ${q.id}`); gorulen.add(q.id); });
  for (const k in beklenen) if ((say[k] || 0) !== beklenen[k]) hatalar.push(`set ${i + 1} ${k}: ${say[k] || 0} (beklenen ${beklenen[k]})`);
});

console.log('DENEME SETİ BASICI (SGS)');
plan.forEach(p => console.log('  ' + p));
if (hatalar.length) { console.log('KIRMIZI - yazılmadı:'); hatalar.slice(0, 20).forEach(h => console.log('  · ' + h)); process.exit(1); }
console.log(`  ${SET} set × ${yapi.toplamSoru} soru · setler arası tekrar 0 · ders dağılımı her sette yönergeyle aynı`);
if (KURU) { console.log('  kuru koşu - yazılmadı'); process.exit(0); }

const cikis = path.join(KOK, 'veri', 'deneme'); fs.mkdirSync(cikis, { recursive: true });
function yazDegisirse(dosya, nesne, zamanAlani) {
  const yeni = JSON.stringify(nesne, null, 1) + '\n';
  try {
    const eski = jsonOku(dosya); const a = { ...eski }, b = { ...nesne };
    if (zamanAlani) { delete a[zamanAlani]; delete b[zamanAlani]; }
    if (JSON.stringify(a) === JSON.stringify(b)) return false;
  } catch (e) {}
  fs.writeFileSync(dosya, yeni, 'utf8'); return true;
}
let yazilan = 0;
setler.forEach((st, i) => {
  const no = String(i + 1).padStart(2, '0');
  if (yazDegisirse(path.join(cikis, `sgs-set-${no}.json`), { sinav: 'sgs', no: i + 1, sure_dk: SURE_DK, toplam: st.length, sorular: st.map((q, n) => ({ n: n + 1, ...q })) })) yazilan++;
});
if (yazDegisirse(path.join(cikis, 'sgs-dizin.json'), {
  uretim: new Date().toISOString().slice(0, 16).replace('T', ' '), uretici: 'motor/deneme-seti-bas.js',
  sinav: 'sgs', ad: 'Staja Giriş', set_sayisi: SET, toplam_soru: yapi.toplamSoru, sure_dk: SURE_DK, sure_kaynak: SURE_KAYNAK,
  dagilim_kaynak: 'veri/sgs-sinav-yapisi.json', dagilim_ad: 'TESMER Uygulama Yönergesi m.6.2',
  degerlendirme: DEGERLENDIRME,
  sira_notu: 'Sorular yönerge tablosundaki bölüm ve ders sırasıyla gelir; gerçek kitapçık sırası ölçülmedi.',
  setler: setler.map((st, i) => ({ no: i + 1, dosya: `veri/deneme/sgs-set-${String(i + 1).padStart(2, '0')}.json` }))
}, 'uretim')) yazilan++;
console.log(`  yazılan/değişen dosya: ${yazilan}`);
