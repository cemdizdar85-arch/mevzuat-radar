// KGK EK KAPI — hazır soru ön denetiminde YALNIZ kgk- etiketinde koşar (arac/hazir-soru-denetle.ps1 KgkEkKapi). 0 USD, model yok.
// 14.10.2026 KGK oturumu, Cem "1.2.3" (t4 dalgasının iki bağımsız okuyucu bulgularından; ölçüm aşağıda).
//
// KGK-DC (DURDURUR) "Doğru cevap" kayması: açıklamadaki "Doğru cevap: <tutar>" tutarı doğru şıkta geçmiyor.
//   Olay (ölçüldü 14.10): t4 tms-g1'de 5 hesaplı soruda yazar tutarları değiştirmiş, açıklama A–E'deki "Doğru cevap" satırını
//   eski tutarda bırakmıştı; ön denetim "kusursuz" dedi, iki okuyucu ayrı ayrı yakaladı.
// KGK-MK (DURDURUR) eski yetkili makam: sigorta/BES bağlamında "Müsteşarlık / Hazine Müsteşarlığı / Bakan(ın) yetkili…" öğretiliyor.
//   Dayanak: SEDDK Teşkilat CBK (47 s.) m.19/1 — 5684'teki Müsteşarlık/Bakan atıfları Kuruma/Kurula yapılmış sayılır (ambarda:
//   "SEDDK Teskilat ve Gorevleri Hakkinda CBK (47 s.) m.19"). Ambardaki 5684 metni eski adları taşıdığı için yazar oradan alıyor.
//   Olay (ölçüldü 14.10): t4 sigorta-g2'de 4 soru (3'ü kök/şıkta → dalgadan çıktı); eski boşluk partilerinde 101 sigorta sorusunun 14'ü.
// NOT-KGK-KA (DURDURMAZ) kısa alanda şart düşmesi: hap / sinav_taktigi / sade.* alanında ISTISNA sözlüğündeki bir atıf geçiyor ama
//   o hükmün şartı/istisnası AYNI alanda yok. t4 son turlarında okuyucuların bulduğu kusurların çoğu bu sınıftı (K14).
//   Yalnız NOT: atfın şartı başka cümlede/alanda meşru olarak verilmiş olabilir — okuyucu karar verir.
// 🚫 GÖRMEZ: "Doğru cevap" kalıbı dışında yazılmış yanlış tutar · sözel cevaplı soruda kayma · sigorta kelimesi geçmeyen soruda eski
//   makam · sözlükte olmayan paragrafın istisnası · şartın eş anlamlı başka sözle yazılması (KA yanlış alarm verir).
// ÖLÇÜLDÜ (14.10, güncel 1.606 KGK hazır soru): DC 0 · MK 0 · KA 2 not — ikisi de YANLIŞ ALARM (atıf yalnız "p.27, p.28 ve p.9 …"
//   gibi bir madde listesinde geçiyor, kural cümlesi yok). Okuyucu öncesi ilk hâller (t4 yedek): tms-g1 DC 5/5 yakalandı ·
//   sigorta-g2 MK 4/4 yakalandı.
// Öz-sınav: node arac/kgk-ek-kapi.js --sinav (vakalar + her kural için mutasyon: kapatılınca sınav KIRMIZI düşmeli).
// Kullanım: node arac/kgk-ek-kapi.js --tek <soru.json>   ·   --dosya <hazir.json> (dizi; soru başına satır)
'use strict';
const fs = require('fs');
let MUT = process.env.KGK_EK_MUTASYON || '';

const sayilar = s => (String(s).match(/\d{1,3}(?:\.\d{3})+(?:,\d+)?|\d+(?:,\d+)?/g) || [])
  .map(x => String(+x.replace(/\./g, '').replace(',', '.'))).filter(n => !/^(19|20)\d\d$/.test(n));   // 32,00 = 32; yıl karşılaştırılmaz
function dogruSik(q) {
  const h = String(q.dogru || '').trim().toUpperCase();
  if (Array.isArray(q.siklar)) return q.siklar['ABCDE'.indexOf(h)];
  return (q.siklar || {})[h];
}
function DC(q) {
  if (MUT === 'dc') return [];
  const sik = dogruSik(q); if (sik == null) return [];
  const ds = new Set(sayilar(typeof sik === 'object' ? JSON.stringify(sik) : sik));
  const metin = JSON.stringify({ aciklama: q.aciklama, adimlar: q.adimlar, teshis: q.teshis, sade: q.sade });
  const yanlis = new Set();
  for (const m of metin.matchAll(/[Dd]o[gğ]ru cevap\s*[:=]\s*([^.\\"]*\d[^\\"]{0,30})/g)) {
    const ns = sayilar(m[1]).filter(n => +n >= 10);
    if (ns.length && !ns.some(n => ds.has(n))) yanlis.add(ns[0]);
  }
  return yanlis.size ? [`KGK-DC "Doğru cevap" kayması: açıklama ${[...yanlis].join(', ')} diyor, doğru şıkta yok (tutarı her alanda düzelt)`] : [];
}
const SIG = /sigorta|reasürans|eksper|acente|bireysel emeklilik|emeklilik şirket|4632|5684|garanti fonu/i;
const ESKI = /Müsteşarlı[kğ]|Hazine Müsteşar|\bBakan(?:ın|ca|ce)?\s+(?:yetkili|izn|onay|belirle|tarafından)|\bBakanın\s|\bBakanca\b/;
const ESKI_HARIC = /eski ad|önceki ad|yerini al|devredil|yapılmış sayılır|CBK \(47/i;
function MK(q) {
  if (MUT === 'mk') return [];
  const s = JSON.stringify(q);
  if (MUT !== 'sigorta' && !SIG.test(s)) return [];
  const o = [];
  const tara = (ad, deger) => { const t = typeof deger === 'string' ? deger : JSON.stringify(deger || ''); for (const c of t.split(/(?<=[.!?;])\s+|\\n/)) if (ESKI.test(c) && !ESKI_HARIC.test(c)) { o.push(ad); return; } };
  for (const k of Object.keys(q)) if (!['konu', 'zorluk', 'kaynak_adlar'].includes(k)) tara(k, q[k]);
  return o.length ? [`KGK-MK eski yetkili makam ("Müsteşarlık/Bakan") ${o.join(', ')} alanında — bugün SEDDK Kurum/Kurul (CBK 47 m.19/1); kök/şıktaysa soru yeniden yazılır`] : [];
}
// atıf → aynı kısa alanda bulunması gereken şart/istisna (t4 okumalarından; her satırın kaynağı paragrafın kendisi)
const ISTISNA = [
  [/TMS 32 p\.22(?![A0-9])/, /22A/, 'TMS 32 p.22 → p.22A istisnası'],
  [/TFRS 9 p\.5\.4\.1(?![0-9])/, /kredi.de[ğg]er d[üu][şs][üu]kl/i, 'TFRS 9 p.5.4.1 → kredi-değer düşüklüğü istisnası'],
  [/TMS 12 p\.58(?![0-9])/, /i[şs]letme birle[şs]me/i, 'TMS 12 p.58 → işletme birleşmesi bendi'],
  [/TFRS 15 p\.56(?![0-9])/, /kuvvetle muhtemel/i, 'TFRS 15 p.56 → "kuvvetle muhtemel" eşiği'],
  [/TFRS 3 p\.B55\(a\)/, /kendili[ğg]inden/i, 'TFRS 3 p.B55(a) → "kendiliğinden" kesilen ödeme'],
  [/TFRS 5 p\.11(?![0-9])/, /ihtimali y[üu]ksek/i, 'TFRS 5 p.11 → "ihtimali yüksek"'],
  [/TMS 29 p\.27(?![0-9])/, /fiyat d[üu]zeyine ba[ğg]l[ıi] olma/i, 'TMS 29 p.27 → fiyat düzeyine bağlı olmama şartı'],
  [/m\.1445\/6/, /riziko ger[çc]ekle[şs]meden/i, 'TTK m.1445/6 → riziko gerçekleşmeden'],
  [/5684[^.]{0,40}m\.17\/4|m\.17\/4[^.]{0,40}5684/, /hayat d[ıi][şs][ıi]/i, '5684 m.17/4 → yalnız hayat dışı'],
];
function KA(q) {
  if (MUT === 'ka') return [];
  const alanlar = [['hap', q.hap], ['sinav_taktigi', q.sinav_taktigi]];
  if (q.sade && typeof q.sade === 'object') for (const [k, v] of Object.entries(q.sade)) alanlar.push(['sade.' + k, v]);
  const o = [];
  for (const [ad, v] of alanlar) {
    const t = typeof v === 'string' ? v : JSON.stringify(v || '');
    for (const [atif, sart, etk] of ISTISNA) if (atif.test(t) && !sart.test(t)) o.push(`NOT-KGK-KA ${ad}: ${etk} aynı alanda yok (K14 — şart başka cümlede verildiyse geç)`);
  }
  return o;
}
const denetle = q => [...DC(q), ...MK(q), ...KA(q)];

function sinav() {
  const sq = (o) => Object.assign({ konu: 'x', zorluk: 'zor', soru: 'Kök', siklar: { A: '1.000 TL', B: '3.767.000 TL', C: '5.000 TL', D: '6.000 TL', E: '7.000 TL' }, dogru: 'B' }, o);
  const V = [
    ['DC: kayma yakalanır', sq({ aciklama: { A: 'Yanlış. Doğru cevap: 3.740.000 TL.' } }), /KGK-DC/, 1],
    ['DC: doğru tutar geçer', sq({ aciklama: { A: 'Yanlış. Doğru cevap: 3.767.000 TL.' } }), /KGK-DC/, 0],
    ['DC: 32,00 = 32 eşit sayılır', sq({ siklar: { A: '%32,00', B: 'x', C: 'y', D: 'z', E: 'w' }, dogru: 'A', aciklama: { B: 'Doğru cevap: %32.' } }), /KGK-DC/, 0],
    ['DC: yıl karşılaştırılmaz', sq({ aciklama: { A: 'Doğru cevap: 2026 dönemi için 3.767.000 TL.' } }), /KGK-DC/, 0],
    ['DC: dizi şıklar', sq({ siklar: ['1 TL', '20 TL', '30 TL', '40 TL', '50 TL'], dogru: 'C', aciklama: { A: 'Doğru cevap: 25 TL.' } }), /KGK-DC/, 1],
    ['MK: Müsteşarlık izni (sigorta) yakalanır', sq({ soru: 'Sigorta kooperatifi kurulması için', aciklama: { A: 'Müsteşarlık izni gerekir.' } }), /KGK-MK/, 1],
    ['MK: Bakan yetkilidir (5684) yakalanır', sq({ soru: '5684 sayılı Kanun garanti fonu', adimlar: [{ anlatim: 'Bakan yetkilidir; Bakanın belirlediği oran.' }] }), /KGK-MK/, 1],
    ['MK: SEDDK/Kurum geçer', sq({ soru: 'Sigorta şirketi', aciklama: { A: 'Kurum (SEDDK) izni gerekir.' } }), /KGK-MK/, 0],
    ['MK: sigorta dışı bağlam geçer (bankacılık)', sq({ soru: 'Banka kuruluşu', aciklama: { A: 'Müsteşarlık eski düzenlemede yer alırdı.' } }), /KGK-MK/, 0],
    ['MK: "Hazine ve Maliye Bakanlığınca" geçer', sq({ soru: 'Bireysel emeklilik devlet katkısı', aciklama: { A: 'Hazine ve Maliye Bakanlığınca ödenir.' } }), /KGK-MK/, 0],
    ['MK: eski ad açıklaması geçer', sq({ soru: 'Sigorta denetimi', aciklama: { A: 'Hazine Müsteşarlığının görevleri CBK (47 s.) m.19 ile Kuruma yapılmış sayılır.' } }), /KGK-MK/, 0],
    ['KA: TMS 32 p.22 hap\'ta 22A yok', sq({ hap: 'TMS 32 p.22 gereği prim özkaynaktır.' }), /NOT-KGK-KA/, 1],
    ['KA: aynı alanda 22A var geçer', sq({ hap: 'TMS 32 p.22 gereği (p.22A hariç) prim özkaynaktır.' }), /NOT-KGK-KA/, 0],
    ['KA: sade.dogru TFRS 15 p.56 eşiksiz', sq({ sade: { dogru: 'TFRS 15 p.56 gereği iptal riski yüksek bedel eklenmez.' } }), /NOT-KGK-KA/, 1],
    ['KA: açıklamada atıf ölçülmez (uzun alan)', sq({ aciklama: { A: 'TMS 32 p.22 gereği prim özkaynaktır.' } }), /NOT-KGK-KA/, 0],
    ['KA: TMS 32 p.22A atfı p.22 sayılmaz', sq({ hap: 'TMS 32 p.22A istisnası uygulanır.' }), /NOT-KGK-KA/, 0],
  ];
  const kos = () => { let h = 0; const d = []; for (const [ad, q, re, bek] of V) { const n = denetle(q).filter(x => re.test(x)).length > 0 ? 1 : 0; if (n !== bek) { h++; d.push(`  DÜŞTÜ: ${ad} → ${n} (beklenen ${bek})`); } } return { h, d }; };
  MUT = ''; const t = kos();
  if (t.h) { console.log(t.d.join('\n')); console.log(`KGK EK KAPI SINAVI KIRMIZI: ${t.h}/${V.length}`); process.exit(1); }
  console.log(`KGK EK KAPI SINAVI YEŞİL: ${V.length}/${V.length}`);
  let kor = 0;
  for (const m of ['dc', 'mk', 'ka', 'sigorta']) { MUT = m; const r = kos(); console.log(`  mutasyon ${m}: ${r.h ? `KIRMIZI (${r.h} vaka düştü) ✓` : 'YEŞİL ✗ sınav bu bozmayı görmüyor'}`); if (!r.h) kor++; }
  MUT = '';
  if (kor) { console.log(`MUTASYON: ${kor} bozma yakalanmadı — sınav eksik`); process.exit(1); }
  console.log('MUTASYON: 4/4 bozma sınavı KIRMIZI düşürdü');
}

const [kip, yol] = process.argv.slice(2);
if (kip === '--sinav') sinav();
else if (kip === '--tek') { const q = JSON.parse(fs.readFileSync(yol, 'utf8').replace(/^﻿/, '')); for (const x of denetle(q)) console.log(x); }
else if (kip === '--dosya') {
  const A = JSON.parse(fs.readFileSync(yol, 'utf8').replace(/^﻿/, '')); let n = 0;
  A.forEach((q, i) => { for (const x of denetle(q)) { n++; console.log(`[${i}] ${q.konu} · ${x}`); } });
  console.log(`taranan ${A.length} soru · satır ${n}`);
} else { console.log('kullanım: --tek <soru.json> | --dosya <hazir.json> | --sinav'); process.exit(2); }
