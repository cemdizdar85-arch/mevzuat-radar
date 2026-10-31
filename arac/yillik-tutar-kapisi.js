#!/usr/bin/env node
// ============================================================================
//  KAPI-YT - YILLIK TUTAR KAPISI (22.10.2026, Cem "1.2.3" + "sınavda 2025 çıkıyorsa 2026 sınavında 2025 olsun")
//  OLAY (ölçüldü 22.10): bir üye "2026 tarifesi yok, sınavda 2025 çıkıyor" diye üyeliği iptal etti. Banka taraması: bitirme
//  Vergi'de 402 sorunun 275'i 2026 yılı, 37'si 2026 tarife/had rakamına bağlı; 3 kıdem sorusu "2026 tavanı" diye 46.000 /
//  43.700 / 41.830 yazıyordu (resmî: 64.948,77 / 73.729,87; 41.830 aslında 2024/II tavanı). Çıkmış sınav ölçümü: Y yılı sınavı
//  Y-1 yılını sorar (2025 sınavları → 2024, 2026/1-2 → 2025).
//  Kütük: veri/sinav/yillik-tutarlar.json (üretici arac/yillik-tutar-kutugu.js, resmî metinden).
//
//  BULGULAR (her biri {tur, dur, not}):
//   YT-YIL         soru yılı > sınav yılı (hedef = bugünün yılı − 1) ve soru vergi/bordro bağlamında       → dur
//   YT-YANLIS-YIL  metinde kalemin BAŞKA yılın (kıdemde başka dönemin) resmî tutarı geçiyor                  → dur
//   YT-KAYNAKSIZ   "kıdem tavanı / mesken istisnası / asgari ücret … X" gerçekmiş gibi yazılmış, X o yılın
//                  resmî tutarı değil ve kökte "varsay" yok                                                  → dur
//   YT-ESKI-YIL    soru yılı < sınav yılı ve yıllık tutar kullanıyor ("zamanı geldi": yeni yıla taşınmalı)    → not
//   YT-EZBER       sınav yılının tutarı çözümde kullanılıyor ama kökte verilmiyor (öğrenci ezberden bilmeli)  → not
//  "dur" yalnız YENİ soruda durdurur (kör/hakem2 tarihi ≥ YT_BASLANGIC, vars. 2026-10-23): bugün yayında olan soru düşmez,
//  onlar NOT-YT ile günlüğe ve banka taramasına düşer (Cem 30.09 "geri çekilmesin, elle düzelt").
//
//  Kullanım: node arac/yillik-tutar-kapisi.js --tek <soru.json> | --banka [sinav-öneki] | --nobet [--kati] | --sinav [--mutasyon]
//  🚫 GÖRMEZ: kütükte olmayan YIL (kütük 2025-2026; 2024 dünyasında yazılmış soru tutar kullanmıyor sayılır) · kütükte olmayan kalem (VUK m.370 haddinin yılı, 2025 asgari ücret, SGK tavanı, MTV, harç - kütüğün "olculmedi"si) ·
//     tutarın kelime yakınında (±150 karakter) geçmediği yazım · sayıyı yazıyla ya da farklı biçimle (46655,43) yazan metin ·
//     aynı sayının iki kalemde/yılda geçerli olduğu çakışmalar (o zaman bulgu VERMEZ, sessiz kalır).
// ============================================================================
const fs = require('fs'), path = require('path');
const KOK = path.resolve(__dirname, '..');
const MUT = process.env.YT_MUTASYON || '';
let KUTUK = null;
function kutuk() { if (!KUTUK) KUTUK = JSON.parse(fs.readFileSync(path.join(KOK, 'veri', 'sinav', 'yillik-tutarlar.json'), 'utf8')); return KUTUK; }
function hedefYil() { return Number(process.env.YT_HEDEF_YIL || (new Date().getFullYear() - 1)); }
function baslangic() { return String(process.env.YT_BASLANGIC || '2026-10-23').trim(); }
const MODEL = ['hakem', 'hakem2', 'kor_cozum', 'simulasyon_sonnet', 'kaynak_metin_ozet', 'aciklama_hakem', 'capa_metin', 'capa_kaynak', 'olcum', 'cikmis'];

// 22.10 eşdeğerlik ölçümü: önbellekteki 15.786 kaydın 2.530'unda kör/hakem2 tarihi YOK (eski partiler); "tarihsiz = yeni" deseni
//   bugün yayında olan 107 soruyu durduracaktı. Kural: kayıttaki tarihlerin EN YENİSİ (kör, hakem2, sade, konu girişi) ≥ başlangıç;
//   hiç tarih yoksa ESKİ (yalnız NOT). Bedeli: tarihsiz hazır-soru girdisi ilk hakeme kadar durmaz (hakemden sonra tarih alır).
function yeniMi(k) {
  const t = [k && k.kor_cozum && k.kor_cozum.tarih, k && k.hakem2 && k.hakem2.tarih, k && k.sade && k.sade.tarih, k && k.konu_giris && k.konu_giris.tarih]
    .filter(Boolean).map(String).sort().pop();
  if (MUT === 'tarihsiz-yeni') return !t || t >= baslangic();
  return !!t && t >= baslangic();
}
const esc = x => x.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const sayiVar = (t, x) => new RegExp('(^|[^\\d.,])' + esc(x) + '(?![\\d]|[.,]\\d)').test(t);
function sayiYakin(t, x, gruplar) {   // x'in ±100 karakter yakınında HER kelime grubundan en az bir kelime var mı
  const G = (Array.isArray(gruplar[0]) ? gruplar : [gruplar]).map(g => g.map(w => w.toLocaleLowerCase('tr')));
  const re = new RegExp('(^|[^\\d.,])' + esc(x) + '(?![\\d]|[.,]\\d)', 'g'); let m;
  while ((m = re.exec(t))) { const p = t.slice(Math.max(0, m.index - 100), m.index + 100).toLocaleLowerCase('tr'); if (MUT === 'grup-tek' ? G.some(g => g.some(w => p.includes(w))) : G.every(g => g.some(w => p.includes(w)))) return true; }
  return false;
}
function metinler(k) {
  const kok = String((k && k.soru) || '');
  const o = {}; for (const a in (k || {})) if (!MODEL.includes(a) && a !== 'soru') o[a] = k[a];
  return { kok, cozum: JSON.stringify(o) };
}
// 22.10 ölçüm: "Y-1" düzeni yalnız GELİR/KURUMLAR VERGİSİ BEYANI sorularında; bitirme 2026/2'nin bir dersinde 2026 altı kez geçiyor
//   (muhasebe kaydı cari yılı kullanıyor). KDV/istisna/matrah gibi geniş kelimeler 767 bitirme sorusunu YT-YIL'a düşürüyordu.
const VERGI_BAGLAMI = /gelir vergisi|kurumlar vergisi|vergiye tabi gelir|beyanname|beyan edil|safi (?:kira|irat)|ticari kazanç|serbest meslek kazanc|ücret gelir|sermaye irad|tevkifat|stopaj/i;
// YT-YIL yalnız vergi KANUNU dilindeki kökte durdurur (banka 22.10: bitirme YT-YIL 473'ün 394'ü vergi dersi, 70'i Finansal Muhasebe;
//   muhasebe sınavı cari yılı da kullanıyor → orada yalnız NOT).
const VERGI_KANUN = /193 sayılı|5520 sayılı|gelir vergisi kanunu|kurumlar vergisi kanunu|beyanname|beyan edil|vergiye tabi gelir|gelir vergisi matrah/i;
function soruYili(kok) {
  const y = []; let m;
  const re = /(?:\b(20\d\d) (?:takvim )?yıl|\b(20\d\d) hesap dönem|\d{1,2}[./]\d{1,2}[./](20\d\d)|\b(20\d\d)\/(?:ocak|şubat|mart|nisan|mayıs|haziran|temmuz|ağustos|eylül|ekim|kasım|aralık)|\b(20\d\d) yılında|\b(20\d\d)'(?:de|da|te|ta|e|a)\b)/gi;
  while ((m = re.exec(kok))) y.push(Number(m.slice(1).find(Boolean)));
  if (!y.length) return null;
  // 22.10 banka ölçümü: "2025'te düzenlenen sözleşme 2026'da devredildi", "2026 geliri 2027'de beyan edilir" gibi iki yıllı
  //   kökte EN BÜYÜK yıl yanlış alarm veriyordu → olay yılı = kökte EN ÇOK geçen yıl (eşitlikte büyük olan).
  if (MUT === 'yil-max') return Math.max(...y);
  const c = {}; y.forEach(v => (c[v] = (c[v] || 0) + 1));
  return Number(Object.keys(c).sort((a, b) => c[b] - c[a] || b - a)[0]);
}
function kidemDonemi(kok) {   // en geç tarih → "YYYY-1|2"
  let en = null, m; const re = /(\d{1,2})[./](\d{1,2})[./](20\d\d)/g;
  while ((m = re.exec(kok))) { const v = Number(m[3]) * 100 + Number(m[2]); if (!en || v > en.v) en = { v, y: m[3], ay: Number(m[2]) }; }
  if (!en) return null;
  return MUT === 'donem-kapali' ? `${en.y}-1` : `${en.y}-${en.ay >= 7 ? 2 : 1}`;
}
// Gerçekmiş gibi yazılan tutar: kelime + (en fazla 80 karakter) + sayı
const OLGU = {
  kidem_tavani: /kıdem tazminatı tavanı[^.]{0,80}?(\d{1,3}(?:\.\d{3})+(?:,\d{2})?)\s*(?:₺|TL)/i,
  gvk_mesken_istisna: /mesken[^.]{0,60}istisna[^.]{0,40}?(\d{1,3}(?:\.\d{3})+)\s*(?:₺|TL)/i,
  asgari_ucret_brut_aylik: /asgari ücret(?:in)? aylık brüt(?: tutarı)?[^.]{0,20}?(\d{1,3}(?:\.\d{3})+(?:,\d{2})?)\s*(?:₺|TL)/i,
};
// 22.10 YT-VARSAYIM (Bitirme sınavı eksiklikleri oturumu buldu): "2026 yılı için X olduğu varsayılmıştır / kabul edilmiştir /
//   bilinmektedir" YT-KAYNAKSIZ'ı susturuyordu (4 vaka: telif haddi 1.100.000, 2. dilim 230.000, mesken 61.000 + 3. dilim ücret 1.900.000).
//   Kural: aynı cümlede YIL + varsayım fiili + kütük kalemi + sayı; o yılın resmî tutarı cümledeki sayılardan hiçbiri değilse bulgu.
//   Yıl adı olmayan varsayım ("tavanının 18.000 TL olduğu varsayılmıştır", çıkmış KGK 2023 dili) ve kütükte olmayan oran (%20 tevkifat) GEÇER.
//   Tarife dilimleri sıra sözcüğüyle ayrılır (yoksa "ikinci dilim" cümlesi öteki dilimlerle de kıyaslanıp yanlış alarm verir).
const VARSAYIM_FIIL = /varsay|kabul edil|bilinmektedir/i;
const DILIM_SIRA = {
  gvk_tarife_dilim1: /birinci (?:gelir )?dilim|ilk (?:gelir )?dilim/i, gvk_tarife_dilim2: /ikinci (?:gelir )?dilim/i,
  gvk_tarife_dilim3: /üçüncü (?:gelir )?dilim(?![^.]{0,30}ücret)/i, gvk_tarife_dilim3_ucret: /üçüncü[^.]{0,30}dilim[^.]{0,40}ücret|ücret[^.]{0,40}üçüncü (?:gelir )?dilim/i,
  gvk_tarife_dilim4: /dördüncü (?:gelir )?dilim|telif[^.]{0,200}istisna had/i,
  // banka ölçümü 22.10: ["beyan"]+["sınır","had"] grubu telif/mesken cümlelerini de yakalıyordu
  gvk_86_beyan_siniri: /beyan(?:name verme)? (?:sınırı|haddi)/i,
};
function varsayimKusurlari(kok, K) {
  const out = [];
  for (const cumle of kok.split(/(?<=[.?!])\s+/)) {
    if (!VARSAYIM_FIIL.test(cumle)) continue;
    const yillar = (cumle.match(/\b20\d\d\b/g) || []).map(Number); if (!yillar.length) continue;
    const Y = String(Math.max(...yillar)), dusuk = cumle.toLocaleLowerCase('tr');
    const sayilar = cumle.match(/\d{1,3}(?:\.\d{3})+(?:,\d{2})?/g) || []; if (!sayilar.length) continue;
    const eslesen = [];
    for (const [id, kal] of Object.entries(K.kalemler)) {
      const resmi = Object.entries(kal.degerler).filter(([ky]) => String(ky).slice(0, 4) === Y).map(([, d]) => d.deger);
      if (!resmi.length) continue;   // o yılın tutarı kütükte yok → hüküm verilmez (ölçülmedi)
      const sira = DILIM_SIRA[id];
      const uyar = sira && MUT !== 'sira-yok' ? sira.test(cumle) : (Array.isArray(kal.kelime[0]) ? kal.kelime : [kal.kelime]).every(g => g.some(w => dusuk.includes(w.toLocaleLowerCase('tr'))));
      if (uyar) eslesen.push({ kal, resmi });
    }
    // banka ölçümü 22.10: cümlede eşleşen kalemlerden BİRİNİN resmî tutarı geçiyorsa (ör. ikinci el binek 2.600.000 cümlesinde
    //   "binek amortisman" kalemi de eşleşir) o cümle doğru tutarı yazmıştır → hiçbir bulgu verilmez.
    const tumResmi = eslesen.flatMap(e => e.resmi);
    if (MUT !== 'cumle-tek' && sayilar.some(s => tumResmi.includes(s))) continue;
    for (const { kal, resmi } of eslesen)
      if (!sayilar.some(s => resmi.includes(s))) out.push({ tur: 'YT-VARSAYIM', dur: true, not: `${kal.ad}: ${Y} için ${sayilar.join('/')} varsayılmış; resmî ${resmi.join(' / ')}` });
  }
  return out;
}

function kusurlar(k, sec = {}) {
  const K = kutuk(), H = sec.hedefYil || hedefYil();
  const { kok, cozum } = metinler(k), tum = kok + ' ' + cozum;
  const out = [], yil = soruYili(kok), beklenen = String(yil || H), kd = kidemDonemi(kok);
  const varsay = /varsay/i.test(kok);
  let tutarKullanir = false;
  for (const [id, kal] of Object.entries(K.kalemler)) {
    const bek = id === 'kidem_tavani' ? kd : beklenen;
    for (const [ky, d] of Object.entries(kal.degerler)) {
      if (!sayiYakin(tum, d.deger, kal.kelime)) continue;
      tutarKullanir = true;
      if (MUT === 'tutar-kapali' || !bek || ky === bek) continue;
      // çakışma: aynı sayı beklenen yılın başka bir kaleminde de geçerliyse sessiz kal
      const cakisma = Object.entries(K.kalemler).some(([id2, k2]) => k2.degerler[id2 === 'kidem_tavani' ? kd : beklenen] && k2.degerler[id2 === 'kidem_tavani' ? kd : beklenen].deger === d.deger && sayiYakin(tum, d.deger, k2.kelime));
      // 22.10 banka ölçümü: 25 tekil bulgunun ~11'i gerçek (soru verisindeki tutar, karşılaştırmalı anlatım yanlış alarm) → yalnız NOT
      if (!cakisma && !(varsay && MUT !== 'varsay-yok')) out.push({ tur: 'YT-YANLIS-YIL', dur: MUT === 'yanlis-dur', not: `${kal.ad}: ${d.deger} ${ky} tutarı, soru ${bek}` });
    }
  }
  if (MUT !== 'kaynaksiz-kapali') for (const [id, re] of Object.entries(OLGU)) {
    const m = kok.match(re); if (!m) continue;
    const kal = K.kalemler[id]; if (!kal) continue;
    const bek = id === 'kidem_tavani' ? kd : beklenen; const resmi = kal.degerler[bek];
    const herhangi = Object.values(kal.degerler).some(d => d.deger === m[1]);
    if (resmi && m[1] !== resmi.deger && !herhangi && !(varsay && MUT !== 'varsay-yok'))
      out.push({ tur: 'YT-KAYNAKSIZ', dur: true, not: `${kal.ad} "${m[1]}" yazıyor; ${bek} resmî tutarı ${resmi.deger} (${resmi.kaynak})` });
  }
  if (MUT !== 'varsayim-kapali') out.push(...varsayimKusurlari(kok, K));
  if (MUT !== 'yil-kapali' && yil && yil > H && (tutarKullanir || VERGI_BAGLAMI.test(kok)))
    out.push({ tur: 'YT-YIL', dur: MUT === 'kanun-kapsam' || VERGI_KANUN.test(kok), not: `soru yılı ${yil} > sınavın sorduğu yıl ${H} (Y sınavı Y-1 yılını sorar)` });
  if (MUT !== 'eski-kapali' && yil && yil < H && tutarKullanir) out.push({ tur: 'YT-ESKI-YIL', dur: false, not: `soru yılı ${yil} < sınav yılı ${H}: yıllık tutar ${H} değerine taşınmalı` });
  if (MUT !== 'ezber-kapali') for (const [id, kal] of Object.entries(K.kalemler)) {
    const d = kal.degerler[id === 'kidem_tavani' ? kd : beklenen]; if (!d) continue;
    if (sayiYakin(cozum, d.deger, kal.kelime) && !sayiVar(kok, d.deger)) out.push({ tur: 'YT-EZBER', dur: false, not: `${kal.ad} ${d.deger} çözümde var, kökte verilmiyor` });
  }
  return out;
}
// soru-kalite-kapisi bağlantısı: "KAPI-YT: …" (YENİ soruda durdurur) / "NOT-YT: …"
function satirlar(k) {
  const y = yeniMi(k) && MUT !== 'yeni-bagsiz';
  return kusurlar(k).map(b => (b.dur && y ? 'KAPI-YT: ' : 'NOT-YT: ') + b.tur + ' ' + b.not);
}

// --nobet: ambara yeni yılın tebliği/genelgesi düştü mü, kütükte sınav yılı var mı
function nobet() {
  const K = kutuk(), H = hedefYil(), dir = path.join(KOK, 'veri', 'mevzuat'), bek = [];
  const maxYil = (dosyaRe, metinRe) => { let mx = 0; for (const f of fs.readdirSync(dir).filter(f => dosyaRe.test(f))) { const t = fs.readFileSync(path.join(dir, f), 'utf8'); for (const m of t.matchAll(metinRe)) mx = Math.max(mx, Number(m[1])); } return mx; };
  const kutukMax = id => Math.max(0, ...Object.keys((K.kalemler[id] || {}).degerler || {}).map(y => Number(String(y).slice(0, 4))));
  const aile = [
    ['GVK yeniden değerleme tebliği', /^gvkgt\d+\.json$/, /(\d{4}) takvim yılında uygulanmak üzere/g, 'gvk_mesken_istisna'],
    ['Damga azami tutar tebliği', /^damgagt\d+\.json$/, /1\/1\/(\d{4}) tarihinden itibaren (?:üst sınır )?[\d.]+,\d{2} Türk Lirası/g, 'damga_azami'],
    ['Kıdem tavanı genelgesi', /^kidemtavani\.json$/, /1\/[17]\/(\d{4}) tarihinden itibaren işçilere/g, 'kidem_tavani'],
    ['Asgari ücret kararı', /^asgariucret\d{4}\.json$/, /(\d{4}) - RG/g, 'asgari_ucret_brut_aylik'],
  ];
  for (const [ad, dRe, mRe, id] of aile) { const a = maxYil(dRe, mRe), k = kutukMax(id); if (a > k) bek.push(`${ad}: ambarda ${a} var, kütükte en geç ${k} → node arac/yillik-tutar-kutugu.js --yaz`); }
  for (const [id, kal] of Object.entries(K.kalemler)) { const ys = Object.keys(kal.degerler).map(y => String(y).slice(0, 4)); if (!ys.includes(String(H))) bek.push(`${kal.ad}: sınav yılı ${H} tutarı kütükte YOK (sorular bu yıla taşınamaz)`); }
  return bek;
}

function sinav() {
  const prev = { h: process.env.YT_HEDEF_YIL, b: process.env.YT_BASLANGIC }; process.env.YT_HEDEF_YIL = '2025'; process.env.YT_BASLANGIC = '2026-10-23';
  const yeni = s => ({ soru: s, kor_cozum: { tarih: '2026-10-25' }, adimlar: [] });
  const eski = s => ({ soru: s, kor_cozum: { tarih: '2026-10-01' }, adimlar: [] });
  const ad = (k, f) => { k.adimlar = [{ formul: f }]; return k; };
  const tur = k => kusurlar(k).map(b => b.tur);
  const dur = k => satirlar(k).some(s => /^KAPI-YT/.test(s));
  const V = [
    ['2025 mesken 47.000 (kökte) → temiz', () => !dur(yeni('Kira dışında geliri olmayan (S), 2025 yılında konutunu kiraya vermiştir. Mesken istisnası 47.000 TL\'dir. Gelir vergisi beyanı?'))],
    ['2026 gelir vergisi sorusu (yeni, kanun dili) → YT-YIL durur', () => dur(yeni('Tüccar Bay (A)\'nın 2026 yılı ticari kazancı 746.400 ₺\'dir. 193 sayılı Gelir Vergisi Kanunu\'na göre gelir vergisi?'))],
    ['muhasebe: "2026 … kurumlar vergisi karşılığı" (kanun atfı yok) → YT-YIL yalnız NOT', () => { const k = yeni('İşletme 2026 hesap dönemi sonunda kurumlar vergisi karşılığı ayırmıştır. Yevmiye kaydı?'); return tur(k).includes('YT-YIL') && !dur(k); }],
    // 22.10 YT-VARSAYIM - 4 gerçek vaka (Bitirme sınavı eksiklikleri oturumu) + 3 yanlış alarm vakası
    ['VARSAYIM: telif istisna haddi "(2026 yılı için) 1.100.000 … bilinmektedir" → durur', () => { const k = yeni('(A) 2026 yılında telif kazancı elde etmiştir. Telif kazançlarına ilişkin istisna haddinin (2026 yılı için) 1.100.000 ₺ olduğu bilinmektedir. Beyan?'); return tur(k).includes('YT-VARSAYIM') && dur(k); }],
    ['VARSAYIM: "ikinci gelir diliminde yer alan tutarın 2026 yılı için 230.000 varsayılmıştır" → durur', () => tur(yeni('103. maddedeki tarifenin ikinci gelir diliminde yer alan tutarın 2026 yılı için 230.000 ₺ olduğu varsayılmıştır.')).includes('YT-VARSAYIM')],
    ['VARSAYIM: mesken 61.000 + 3. dilim ücret 1.900.000 (2026) → iki bulgu', () => kusurlar(yeni('Mesken kira istisnası haddinin 2026 yılı için 61.000 ₺, istisnadan faydalanma sınırı olan üçüncü dilim ücret tutarının 1.900.000 ₺ olduğu varsayılmıştır.')).filter(b => b.tur === 'YT-VARSAYIM').length === 2],
    ['VARSAYIM: "2025 tarifenin ikinci dilim tutarı 330.000 kabul edilmiştir" (resmî) → temiz, öteki dilimlerle kıyaslanmaz', () => !tur(yeni('Tarifenin ikinci gelir diliminde yer alan tutar 2025 yılı için 330.000 ₺ olarak kabul edilmiştir.')).includes('YT-VARSAYIM')],
    ['VARSAYIM yanlış alarm yok: "%20 tevkifat yapıldığı varsayılmıştır" (kütükte olmayan oran)', () => !tur(yeni('Ödemeler üzerinden 2025 yılında %20 oranında 150.000 ₺ tevkifat yapıldığı varsayılmıştır.')).includes('YT-VARSAYIM')],
    ['VARSAYIM yanlış alarm yok: yıl adı geçmeyen "tavanının 18.000 TL olduğu varsayılmıştır"', () => !tur(yeni('İşçi 15.03.2017\'de başlamış. Kıdem tazminatı tavanının 18.000 TL olduğu varsayılmıştır.')).includes('YT-VARSAYIM')],
    ['VARSAYIM banka: ikinci el binek amortisman sınırı 2.600.000 (2026, resmî) → binek amortisman kalemi de eşleşse temiz', () => !tur(yeni('İkinci el binek otomobil için amortismana tabi tutar sınırının 2026 yılı için 2.600.000 ₺ olduğu varsayılmıştır.')).includes('YT-VARSAYIM')],
    ['VARSAYIM ESKİ soruda yalnız NOT', () => { const k = eski('Mesken kira istisnası haddinin 2026 yılı için 61.000 ₺ olduğu varsayılmıştır.'); return !dur(k) && satirlar(k).some(s => /^NOT-YT: YT-VARSAYIM/.test(s)); }],
    ['eşdeğerlik: tarihsiz eski kayıt (2.530 vaka) → durmaz', () => !dur({ soru: 'Tüccar Bay (A)\'nın 2026 yılı ticari kazancı 746.400 ₺\'dir. 193 sayılı Gelir Vergisi Kanunu\'na göre gelir vergisi?' })],
    ['YANLIŞ YIL tutarı yeni soruda yalnız NOT (isabet ~%45, 22.10)', () => { const k = ad(yeni('(S) Hanım 2025 yılında dairesini konut olarak kiraya vermiştir.'), 'mesken istisnası 58.000'); return tur(k).includes('YT-YANLIS-YIL') && !dur(k); }],
    ['2025 soru 2026 mesken tutarı 58.000 → YT-YANLIS-YIL', () => tur(ad(yeni('(S) Hanım 2025 yılında dairesini konut olarak kiraya vermiştir. Gelir vergisi?'), 'Vergiye tabi = 196.000 - mesken istisnası 58.000 = 138.000')).includes('YT-YANLIS-YIL')],
    ['kıdem 15.03.2025 tavan 46.655,43 → temiz', () => !dur(yeni('İşçi 15.03.2017\'de başlamış, 15.03.2025\'te ayrılmıştır. Kıdem tazminatı tavanı 46.655,43 ₺\'dir.'))],
    ['kıdem "tavanı 46.000" gerçekmiş gibi → YT-KAYNAKSIZ', () => tur(yeni('İşçi 15.03.2017\'de başlamış, 15.03.2025\'te ayrılmıştır. Kıdem tazminatı tavanı 46.000 ₺\'dir.')).includes('YT-KAYNAKSIZ')],
    ['kıdem "18.000 olduğu varsayılmıştır" → temiz (çıkmış KGK 2023 dili)', () => !dur(yeni('İşçi 15.03.2017\'de başlamış, 15.03.2025\'te ayrılmıştır. Kıdem tazminatı tavanının 18.000 TL olduğu varsayılmıştır.'))],
    ['kıdem 15.09.2025 (II. dönem) ama I. dönem tavanı 46.655,43 → YT-YANLIS-YIL', () => tur(yeni('İşçi 15.03.2014\'te başlamış, 15.09.2025\'te ayrılmıştır. Kıdem tazminatı tavanı 46.655,43 ₺\'dir.')).includes('YT-YANLIS-YIL')],
    ['ESKİ soruda aynı kusur → yalnız NOT (yayındaki soru düşmez)', () => { const k = ad(eski('(S) Hanım 2025 yılında dairesini konut olarak kiraya vermiştir. Gelir vergisi?'), 'mesken istisnası 58.000'); return !dur(k) && satirlar(k).some(s => /^NOT-YT: YT-YANLIS-YIL/.test(s)); }],
    ['banka ölçümü: Maliyet "Yemekhane" gider yeri 300 ₺ → yemek istisnası sanılmaz', () => !tur(yeni('2025 yılında yardımcı gider yeri Yemekhane\'nin 300 ₺ gideri kademeli yöntemle dağıtılmaktadır.')).includes('YT-YANLIS-YIL')],
    ['banka ölçümü: soru verisi "800.000 ₺ kâr payı" tarife dilimi sanılmaz', () => !tur(yeni('Bayan (E), 2025 yılında tam mükellef bir şirketten 800.000 ₺ kâr payı almıştır. Gelir vergisi beyanı?')).includes('YT-YANLIS-YIL')],
    ['banka ölçümü: "2025 yılında düzenlenen … 2025 yılı azami … 2026 yılında devredilmiş" → 2025 azami doğru, bulgu yok', () => !tur(yeni('2025 yılında düzenlenen bir mukavelename, Damga Vergisi Kanununun 14 üncü maddesindeki 2025 yılı azami tutarı olan 24.477.478,90 TL üzerinden damga vergisine tabi tutulmuştur. Bu mukavelename 2026 yılında devredilmiştir.')).includes('YT-YANLIS-YIL')],
    ['muhasebe kaydı "2026 hesap dönemi", vergi bağlamı yok → YT-YIL yok', () => !tur(yeni('İşletme 2026 hesap döneminde 120 ALICILAR hesabına 50.000 ₺ borç kaydetmiştir. Yevmiye kaydı?')).includes('YT-YIL')],
    ['2025 tarife 1.200.000 (ücret dilimi) → çakışmada sessiz, temiz', () => !dur(ad(yeni('(L) Hanım 2025 yılında ücret geliri elde etmiştir. Gelir vergisi tarifesi?'), 'ücret dilim 330.000 ile 1.200.000 arası %27'))],
    ['sınav yılı tarifesi çözümde var, kökte yok → NOT YT-EZBER', () => { const k = ad(yeni('Tüccar Bay (K) 2025 yılında 486.300 ₺ kazanç elde etmiştir. Gelir vergisi?'), 'tarife: 330.000 TL\'si için 58.100, aşan %27 dilim'); return tur(k).includes('YT-EZBER') && !satirlar(k).some(s => /^KAPI-YT: YT-EZBER/.test(s)); }],
    // "zamanı gelince": 2027'de sınav yılı 2026 olur; 2025 tutarlı soru taşınmalı diye işaretlenir (durdurmaz)
    ['sınav yılı 2026 iken 2025 mesken 47.000 kullanan soru → NOT YT-ESKI-YIL', () => { const k = ad(yeni('(S) 2025 yılında konutunu kiraya vermiştir. Gelir vergisi?'), 'mesken istisnası 47.000'); return kusurlar(k, { hedefYil: 2026 }).some(b => b.tur === 'YT-ESKI-YIL' && !b.dur); }],
  ];
  let ok = 0; for (const [a, f] of V) { let g = false; try { g = !!f(); } catch (e) { g = false; } if (g) ok++; if (!process.env.YT_SESSIZ) console.log((g ? '  ✓ ' : '  ✗ ') + a); }
  process.env.YT_HEDEF_YIL = prev.h || ''; if (!prev.h) delete process.env.YT_HEDEF_YIL; if (prev.b) process.env.YT_BASLANGIC = prev.b; else delete process.env.YT_BASLANGIC;
  console.log(`KAPI-YT ÖZ-SINAVI ${ok === V.length ? 'YEŞİL' : 'KIRMIZI'} (${ok}/${V.length})`); return ok === V.length;
}

module.exports = { kusurlar, satirlar, yeniMi, soruYili, nobet };
if (require.main === module) {
  const a = process.argv.slice(2);
  if (a[0] === '--sinav') {
    const g = sinav();
    if (a.includes('--mutasyon')) {
      const { spawnSync } = require('child_process'); const ler = ['yil-kapali', 'tutar-kapali', 'kaynaksiz-kapali', 'donem-kapali', 'varsay-yok', 'yeni-bagsiz', 'eski-kapali', 'ezber-kapali', 'grup-tek', 'yil-max', 'kanun-kapsam', 'yanlis-dur', 'tarihsiz-yeni', 'varsayim-kapali', 'sira-yok', 'cumle-tek']; let y = 0;
      for (const m of ler) { const r = spawnSync(process.execPath, [__filename, '--sinav'], { env: { ...process.env, YT_MUTASYON: m, YT_SESSIZ: '1' }, encoding: 'utf8' }); const kr = r.status !== 0; if (kr) y++; console.log(`  mutasyon ${m}: ${kr ? 'KIRMIZI (beklenen)' : 'YEŞİL - sınav kör!'}`); }
      console.log(`MUTASYON ${y}/${ler.length}`); process.exit(g && y === ler.length ? 0 : 1);
    }
    process.exit(g ? 0 : 1);
  } else if (a[0] === '--tek') { satirlar(JSON.parse(fs.readFileSync(a[1], 'utf8').replace(/^﻿/, ''))).forEach(s => console.log(s)); }
  else if (a[0] === '--nobet') { const b = nobet(); b.forEach(x => console.log('BEKLEYEN ' + x)); console.log(`YILLIK TUTAR NÖBETİ: ${b.length ? b.length + ' bekleyen' : 'kütük güncel'} (sınav yılı ${hedefYil()})`); process.exit(a.includes('--kati') && b.length ? 1 : 0); }
  else if (a[0] === '--banka') {   // yerel parti önbelleği (veri/fabrika) - yalnız kimlik + bulgu türü basar, soru metni BASMAZ
    const on = a[1] || 'smmm-', dir = path.join(KOK, 'veri', 'fabrika'), say = {}, ids = {};
    for (const f of fs.readdirSync(dir).filter(f => f.startsWith('kalip-parti-' + on) && f.endsWith('.json'))) {
      let p; try { p = JSON.parse(fs.readFileSync(path.join(dir, f), 'utf8').replace(/^﻿/, '')); } catch (e) { continue; }
      const et = f.slice(12, -5);
      for (const kp of Object.keys(p)) { if (!/^kp-/.test(kp) || !p[kp] || !p[kp].soru) continue; for (const b of kusurlar(p[kp])) { say[b.tur] = (say[b.tur] || 0) + 1; (ids[b.tur] = ids[b.tur] || []).push(et + '/' + kp); } }
    }
    for (const t of Object.keys(say).sort()) console.log(`${t}: ${say[t]}  ör: ${ids[t].slice(0, 3).join(', ')}`);
    if (process.env.YT_BANKA_CIKTI) fs.writeFileSync(process.env.YT_BANKA_CIKTI, JSON.stringify(ids, null, 1));
  } else { console.log('kullanım: --tek <soru.json> | --banka [önek] | --nobet [--kati] | --sinav [--mutasyon]'); process.exit(2); }
}
