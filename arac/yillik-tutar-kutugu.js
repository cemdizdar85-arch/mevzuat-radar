#!/usr/bin/env node
// ============================================================================
//  YILLIK TUTAR KÜTÜĞÜ ÜRETİCİSİ (22.10.2026, Cem "1.2.3" + "sınavda 2025 çıkıyorsa 2026 sınavında 2025 olsun")
//  Ambardaki RESMÎ metinden (veri/mevzuat/*.json, yoksa veri/mevzuat-hazir/*.txt) yıl yıl değişen tutarları çıkarır →
//  veri/sinav/yillik-tutarlar.json. Elle yazılmaz; yeni tebliğ ambara düşünce bu betik yeniden koşar.
//  Her değerin yanında kaynak slug + alıntı durur; kaynağı okunamayan kalem "olculmedi" listesine düşer, uydurulmaz.
//
//  Kullanım (depo kökü): node arac/yillik-tutar-kutugu.js            → kuru: ne çıkardığını basar
//                         node arac/yillik-tutar-kutugu.js --yaz      → dosyayı yazar (içerik aynıysa dokunmaz)
//  🚫 GÖRMEZ: ambarda olmayan tebliğ (2025 asgari ücret, VUK m.370 haddinin yılı, SGK tavanı, MTV/harç tarifeleri) ·
//     tebliğin biçimi değişirse (desen tutmaz → kalem "olculmedi"ye düşer, sessiz yanlış değer yazılmaz).
// ============================================================================
const fs = require('fs'), path = require('path');
const KOK = path.resolve(__dirname, '..');
const HEDEF = path.join(KOK, 'veri', 'sinav', 'yillik-tutarlar.json');

function metin(slug) {
  const j = path.join(KOK, 'veri', 'mevzuat', slug + '.json');
  if (fs.existsSync(j)) return { kaynak: 'ambar:' + slug, t: JSON.parse(fs.readFileSync(j, 'utf8').replace(/^﻿/, '')).belgeler.map(b => b.metin).join(' ').replace(/\s+/g, ' ') };
  const h = path.join(KOK, 'veri', 'mevzuat-hazir', slug + '.txt');
  if (fs.existsSync(h)) return { kaynak: 'hazir:' + slug, t: fs.readFileSync(h, 'utf8').replace(/^﻿/, '').replace(/\s+/g, ' ') };
  return null;
}
const tl = x => String(x).trim();
// kelime: GRUP listesi - sayının ±100 karakter yakınında HER gruptan en az bir kelime geçmeli (22.10 banka ölçümü: tek kelime
//   "yemek" Maliyet'teki Yemekhane'yi, "tarife" sorudaki 800.000 ₺ kâr payını yakalıyordu; 67 bulgunun çoğu yanlış alarmdı).
// DILIM'de yalın "tarife" YOK: banka ölçümünde ÖTV tarifesi sorularını (galeri, 1.000.000) gelir vergisi dilimi sanıyordu.
const SINIR = ['sınır', 'had', 'kabul', 'azami', 'üst'], DILIM = ['dilim', "tl'si için", 'tl’si için', 'gelir vergisi tarife'];
const GRUP = {
  gvk_eticaret_hasilat: [['internet', 'elektronik'], ['hasılat']], gvk_mesken_istisna: [['mesken', 'konut'], ['istisna']],
  gvk_yemek_istisna: [['yemek'], ['istisna']], gvk_ulasim_istisna: [['ulaşım', 'gidip gel', 'yol'], ['istisna']],
  gvk_engelli_1: [['engell'], ['indirim'], ['derece']], gvk_engelli_2: [['engell'], ['indirim'], ['derece']], gvk_engelli_3: [['engell'], ['indirim'], ['derece']],
  gvk_binek_kira: [['binek'], ['kira'], SINIR], gvk_binek_otv_kdv: [['binek'], ['ötv', 'özel tüketim'], SINIR],
  gvk_binek_amortisman: [['binek'], ['amortisman'], SINIR], gvk_binek_amortisman_ikinci_el: [['binek'], ['amortisman'], SINIR],
  gvk_deger_artisi_istisna: [['değer artışı'], ['istisna']], gvk_arizi_istisna: [['arızi'], ['istisna']], gvk_86_beyan_siniri: [['beyan'], ['sınır', 'had']],
  gvk_tarife_dilim1: [DILIM], gvk_tarife_dilim2: [DILIM], gvk_tarife_dilim3: [DILIM], gvk_tarife_dilim3_ucret: [DILIM, ['ücret']], gvk_tarife_dilim4: [DILIM],
  gvk_mukerrer121: [['121', 'vergi indirimi'], ['sınır', 'tutar', 'had']],
};

// GVK Genel Tebliği (yeniden değerleme) - her yıl aynı düzen. Desen tutmazsa kalem yazılmaz.
const GVK_DESEN = {
  gvk_eticaret_hasilat: { ad: 'GVK 9/10 internet satış hasılatı haddi', re: /satış hasılatı ([\d.]+) TL/, kelime: ['internet', 'elektronik ortam'] },
  gvk_mesken_istisna: { ad: 'GVK 21 mesken kira istisnası', re: /mesken kira gelirleri için uygulanan istisna tutarı ([\d.]+) TL/, kelime: ['mesken', 'konut'] },
  gvk_yemek_istisna: { ad: 'GVK 23/8 günlük yemek istisnası', re: /bir günlük yemek bedeline ilişkin istisna tutarı ([\d.]+) TL/, kelime: ['yemek'] },
  gvk_ulasim_istisna: { ad: 'GVK 23/10 günlük ulaşım istisnası', re: /gidip gelmesi için sağlanan menfaatlere ilişkin istisna tutarı ([\d.]+) TL/, kelime: ['ulaşım', 'gidip gel'] },
  gvk_engelli_1: { ad: 'GVK 31 engellilik indirimi 1. derece', re: /Birinci derece engelliler için ([\d.]+) TL/, kelime: ['engell'] },
  gvk_engelli_2: { ad: 'GVK 31 engellilik indirimi 2. derece', re: /İkinci derece engelliler için ([\d.]+) TL/, kelime: ['engell'] },
  gvk_engelli_3: { ad: 'GVK 31 engellilik indirimi 3. derece', re: /Üçüncü derece engelliler için ([\d.]+) TL/, kelime: ['engell'] },
  gvk_binek_kira: { ad: 'GVK 40/1-KVK binek aylık kira gider sınırı', re: /binek otomobillerinin her birine ilişkin aylık kira bedeli ([\d.]+) TL/, kelime: ['binek'] },
  gvk_binek_otv_kdv: { ad: 'GVK 40/1 binek ÖTV+KDV gider sınırı', re: /katma değer vergisinin toplam tutarı ([\d.]+) TL/, kelime: ['binek'] },
  gvk_binek_amortisman: { ad: 'GVK 40/7 binek amortisman sınırı', re: /katma değer vergisi hariç ([\d.]+) TL/, kelime: ['binek'] },
  gvk_binek_amortisman_ikinci_el: { ad: 'GVK 40/7 binek amortisman sınırı (vergiler maliyette / ikinci el)', re: /ikinci el olarak iktisap edildiği hallerde ([\d.]+) TL/, kelime: ['binek'] },
  gvk_deger_artisi_istisna: { ad: 'GVK mük.80 değer artışı istisnası', re: /değer artışı kazançlarına ilişkin istisna tutarı ([\d.]+) TL/, kelime: ['değer artışı'] },
  gvk_arizi_istisna: { ad: 'GVK 82 arızi kazanç istisnası', re: /arızi kazançlara ilişkin istisna tutarı ([\d.]+) TL/, kelime: ['arızi'] },
  gvk_86_beyan_siniri: { ad: 'GVK 86/1-d menkul+gayrimenkul sermaye iradı beyan sınırı', re: /beyanname verme sınırı ([\d.]+) TL/, kelime: ['beyan'] },
  // 22.10: 2025 tebliği (329) ’ , 2026 tebliği (332) ' kesme işareti kullanıyor → ikisi de kabul
  gvk_tarife_dilim1: { ad: 'GVK 103 tarife 1. dilim üst sınırı', re: /([\d.]+) TL['’]ye kadar % 15/, kelime: ['tarife', 'dilim', 'gelir vergisi'] },
  gvk_tarife_dilim2: { ad: 'GVK 103 tarife 2. dilim üst sınırı', re: /kadar % 15 ([\d.]+) TL['’]nin/, kelime: ['tarife', 'dilim', 'gelir vergisi'] },
  gvk_tarife_dilim3: { ad: 'GVK 103 tarife 3. dilim üst sınırı (ücret dışı)', re: /fazlası % 20 ([\d.]+) TL['’]nin/, kelime: ['tarife', 'dilim', 'gelir vergisi'] },
  gvk_tarife_dilim3_ucret: { ad: 'GVK 103 tarife 3. dilim üst sınırı (ücret)', re: /\(ücret gelirlerinde ([\d.]+) TL['’]nin [\d.]+ TL['’]si için [\d.]+ TL\),? fazlası % 27/, kelime: ['tarife', 'dilim', 'ücret'] },
  gvk_tarife_dilim4: { ad: 'GVK 103 tarife 4. dilim üst sınırı', re: /fazlası % 27 ([\d.]+) TL['’]nin/, kelime: ['tarife', 'dilim', 'gelir vergisi'] },
  gvk_mukerrer121: { ad: 'GVK mük.121 vergi indirimi tutar sınırı', re: /beyannamelerinde uygulanmak üzere ([\d.]+) TL olarak tespit/, kelime: ['vergi indirimi', '121'] },
};
const GVK_TEBLIG = [['gvkgt329', '2025'], ['gvkgt332', '2026']];

function uret() {
  const kalemler = {}, olculmedi = [];
  const ekle = (id, ad, kelime, yil, deger, kaynak, alinti) => {
    kalemler[id] = kalemler[id] || { ad, kelime: GRUP[id] || kelime, degerler: {} };
    kalemler[id].degerler[yil] = { deger: tl(deger), kaynak, alinti: alinti.slice(0, 220) };
  };
  for (const [slug, yil] of GVK_TEBLIG) {
    const m = metin(slug); if (!m) { olculmedi.push(`${slug} (${yil} GVK hadleri) ambarda yok`); continue; }
    const i = m.t.indexOf(`${yil} takvim yılında uygulanmak üzere`);
    if (i < 0) { olculmedi.push(`${slug}: "${yil} takvim yılında uygulanmak üzere" bulunamadı`); continue; }
    const govde = m.t.slice(i, i + 6000);
    for (const [id, d] of Object.entries(GVK_DESEN)) {
      const r = govde.match(d.re);
      if (r) ekle(id, d.ad, d.kelime, yil, r[1], m.kaynak, govde.slice(Math.max(0, r.index - 60), r.index + r[0].length)); else olculmedi.push(`${id} ${yil}: desen tutmadı (${slug})`);
    }
  }
  // Damga Vergisi Kanunu m.14 azami tutar - her yıl ayrı genel tebliğ
  for (const [slug, yil] of [['damgagt70', '2025'], ['damgagt71', '2026']]) {
    const m = metin(slug); const r = m && m.t.match(new RegExp(`1/1/${yil} tarihinden itibaren (?:üst sınır )?([\\d.]+,\\d{2}) Türk Lirası`));
    if (r) ekle('damga_azami', 'DVK 14 bir kağıt için azami damga vergisi', [['damga'], ['azami', 'üst sınır']], yil, r[1], m.kaynak, m.t.slice(Math.max(0, r.index - 80), r.index + r[0].length));
    else olculmedi.push(`damga_azami ${yil}: ${m ? 'desen tutmadı' : 'ambarda yok'} (${slug})`);
  }
  // Kıdem tazminatı tavanı - yılda iki dönem (HMB Mali ve Sosyal Haklar genelgeleri)
  const kd = metin('kidemtavani');
  if (kd) {
    for (const r of kd.t.matchAll(/1\/(1|7)\/(\d{4}) tarihinden itibaren işçilere ödenecek kıdem tazminatının yıllık tavan tutarı ([\d.]+,\d{2}) TL/g))
      ekle('kidem_tavani', 'İş K. 1475 m.14 kıdem tazminatı yıllık tavanı', [['kıdem'], ['tavan']], `${r[2]}-${r[1] === '1' ? '1' : '2'}`, r[3], kd.kaynak, r[0]);
  } else olculmedi.push('kidem_tavani: kidemtavani kaynağı yok');
  // Asgari ücret - yalnız ambarda kararı olan yıllar
  const au = metin('asgariucret2026'); const ar = au && au.t.match(/aylık brüt asgari ücret [\d.]+ x 30 = ([\d.]+) TL/);
  if (ar) ekle('asgari_ucret_brut_aylik', 'Asgari ücret aylık brüt', [['asgari ücret']], '2026', ar[1], au.kaynak, ar[0]); else olculmedi.push('asgari_ucret 2026: desen tutmadı');
  olculmedi.push('asgari_ucret 2025: Asgari Ücret Tespit Komisyonu 2025 kararı ambarda yok');
  olculmedi.push('VUK m.370 izaha davet haddi: ambardaki VUK metni yalnız güncel tutarı (870.000) taşıyor, YILI ve 2025 değeri ölçülmedi');
  olculmedi.push('SGK prim tavanı/tabanı, MTV, harç, veraset istisnaları: kütüğe henüz alınmadı');
  return {
    aciklama: 'Yıl yıl değişen tutarlar; ÜRETİCİ arac/yillik-tutar-kutugu.js (elle düzenlenmez). Kapı: arac/yillik-tutar-kapisi.js.',
    sinav_yili_kurali: 'Y yılında yapılan sınav Y-1 yılının gelir/tutarlarını sorar (ölçüm 22.10.2026: 2025 sınavlarında vergi soruları 2024, 2026/1-2026/2\'de 2025 yılını kullanıyor). Soru yılı = sınavın sorduğu yıl (Cem 22.10.2026).',
    kalemler, olculmedi,
  };
}

const kan = v => Array.isArray(v) ? v.map(kan) : (v && typeof v === 'object') ? Object.keys(v).sort().reduce((o, k) => (o[k] = kan(v[k]), o), {}) : v;
if (require.main === module) {
  const k = uret();
  for (const [id, x] of Object.entries(k.kalemler)) console.log(id.padEnd(34), Object.entries(x.degerler).map(([y, d]) => `${y}=${d.deger}`).join('  '));
  console.log('ÖLÇÜLMEDİ:', k.olculmedi.length); k.olculmedi.forEach(o => console.log('  - ' + o));
  if (process.argv.includes('--yaz')) {
    const eski = fs.existsSync(HEDEF) ? JSON.parse(fs.readFileSync(HEDEF, 'utf8')) : null;
    if (eski && JSON.stringify(kan(eski)) === JSON.stringify(kan(k))) console.log('içerik aynı - dosyaya dokunulmadı');
    else { fs.writeFileSync(HEDEF, JSON.stringify(k, null, 1) + '\n'); console.log('yazıldı: veri/sinav/yillik-tutarlar.json'); }
  }
}
module.exports = { uret, HEDEF };
