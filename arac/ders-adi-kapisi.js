#!/usr/bin/env node
/* KAPI-DA — DERS ADI KAPISI (10.10.2026, Cem "1.2.3 üçünü de yap")
 *
 * Olay (ölçüldü 10.10): satın alma sayfası Yeterlilik ders listesini fiyat-motoru.js DERSLER'den alıyordu ve orada
 * "Temel Hukuk" yazıyordu; sitede/kasada dersin adı "Hukuk". 09.10'da 4 ders (Denetim·Vergi·Hukuk·SPK) alan ilk
 * ödemeli müşterinin paket_uyeler.dersler dizisine "Temel Hukuk" girdi → sorular.html ve kasa RLS adı birebir eşlediği
 * için Hukuk dersi (439 soru) kilitli kaldı, öteki 3 ders açıldı. Müşteri mailiyle fark edildi.
 *
 * Kural (bedel 0, ağ yok): Yeterlilik ders adı yazan her liste, sitenin ders adlarıyla (veri/soru-dizini.json,
 * sinav kod 'smmm' → dersler[].ad) KÜME OLARAK AYNI olmalı:
 *   - fiyat-motoru.js DERSLER.yeterlilik      (web satın alma → siparisler.secilen_dersler → paket_uyeler.dersler)
 *   - radar-app/edge/magaza-dogrula.ts DERSLER (mobil mağaza → paket_uyeler.dersler)
 *   - radar-app/edge/karne-gonder.ts DERS_ADLARI_YET (karne maili)
 *   DA-YOK    listede sitede olmayan ad var (satılır ama açılmaz — 10.10 olayı)
 *   DA-EKSIK  sitede olan ders listede yok (satılamaz / karnede görünmez)
 *   DA-KOR    liste ya da site adları okunamadı (kapı ölçemiyor → KIRMIZI, "temiz" denmez)
 *
 * KGK KOLU (13.10.2026, site kolu — KGK modül paketleri zinciri): KGK'da satılan birim MODÜL (fiyat-motoru.js DERSLER.kgk,
 * KGK'nın dört konu başlığı), sitede/kasadaki birim DERS (soru-dizini.json kgk: "Türkiye Muhasebe Standartları",
 * "Kurumsal Yönetim", "Finansal Yönetim", …). Köprü fiyat-motoru.js KGK_MODUL_DERS (modül → sitedeki ders adları);
 * satin-al.html siparişe bu açılmış ders adlarını yazar. Kapı ölçer:
 *   DA-KGK-MODUL  DERSLER.kgk'daki bir modülün eşlemesi yok/boş (o modül satılır, hiçbir ders açılmaz) ya da eşlemede
 *                 DERSLER.kgk'da olmayan anahtar var (ölü satır)
 *   DA-YOK        eşlemedeki ders adı sitede KGK dersi değil (yazılır ama kasa açmaz — 10.10 olayının KGK hâli)
 *   DA-EKSIK      sitenin "temel alan" KGK dersi hiçbir modülün eşlemesinde yok (modül paketi alan onu hiç alamaz).
 *                 Ek alan dersleri (sürdürülebilirlik e/f/g) dört temel modülde DEĞİLDİR; eşlemede olmaması bulgu değil.
 *   DA-KGK-CIFT   aynı ders iki modülde (bir modül parasına öbür modülün dersi açılır)
 *   DA-KOR        eşleme / modül listesi / site KGK dersleri okunamadı
 *
 * 🚫 BU KAPI ŞUNU GÖRMEZ:
 *   - kasadaki paket_soru.ders adları (servis anahtarı ister; soru-dizini.json kasadan basılan sayfalardan sayılır)
 *   - geçmiş sipariş/üye satırlarındaki eski adlar (yerel tarama: scratchpad siparis-tara.js deseni)
 *   - satin-al.html'nin eşlemeyi gerçekten uyguladığı (gönderimdeki kgkModulDersleri çağrısı; tarayıcı ölçümü)
 *   - veritabanı tarafı (_siparis_isle kgk-[1-3] → dersler; göç içi öz-sınav ölçer)
 *   - adı burada sayılmayan yeni bir liste
 *
 * Kullanım:  node arac/ders-adi-kapisi.js          (depoyu denetler; bulgu varsa çıkış 1)
 *            node arac/ders-adi-kapisi.js --sinav  (öz-sınav; DA_MUTASYON=yok|eksik|kor|kgkmodul|kgkyok|kgkeksik|kgkcift ile bozarak sınanır)
 */
'use strict';
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const KOK = path.resolve(__dirname, '..');
const MUT = process.env.DA_MUTASYON || '';

function oku(g) { try { return fs.readFileSync(path.join(KOK, g), 'utf8'); } catch (e) { return null; } }

/* fiyat-motoru.js GERÇEK kodundan koşturulur (replika yok). */
function fiyatMotoruCalistir(metin, ifade) {
  if (metin == null) return null;
  try {
    const E = { console: { log() {}, warn() {}, error() {} } };
    E.window = E; E.document = { getElementById() { return null; }, querySelector() { return null; } };
    E.location = { search: '', hash: '', pathname: '/' };
    vm.createContext(E);
    vm.runInContext(metin + '\n;this.__D = (' + ifade + ');', E);
    return E.__D == null ? null : E.__D;
  } catch (e) { return null; }
}
function fiyatDersleri(metin) {
  const d = fiyatMotoruCalistir(metin, '(typeof DERSLER === "object" && DERSLER) ? DERSLER.yeterlilik : null');
  return Array.isArray(d) ? d.slice() : null;
}
function fiyatKgkModulleri(metin) {
  const d = fiyatMotoruCalistir(metin, '(typeof DERSLER === "object" && DERSLER) ? DERSLER.kgk : null');
  return Array.isArray(d) ? d.slice() : null;
}
function fiyatKgkEsleme(metin) {
  const d = fiyatMotoruCalistir(metin, '(typeof KGK_MODUL_DERS === "object" && KGK_MODUL_DERS) ? JSON.stringify(KGK_MODUL_DERS) : null');
  if (typeof d !== 'string') return null;
  try { const o = JSON.parse(d); return (o && typeof o === 'object' && !Array.isArray(o)) ? o : null; } catch (e) { return null; }
}

/* TS dosyasında "<anahtar>...[ ... ]" dizi literalini okur (yalnız çift/tek tırnaklı dizeler). */
function tsDizi(metin, desen) {
  if (metin == null) return null;
  const m = desen.exec(metin); if (!m) return null;
  const ic = m[1]; const ad = [];
  for (const x of ic.matchAll(/["']([^"']+)["']/g)) ad.push(x[1]);
  return ad.length ? ad : null;
}

function siteDersleri(metin) {
  if (metin == null) return null;
  try {
    const j = JSON.parse(metin);
    const s = (j.sinavlar || []).find((x) => x.kod === 'smmm');
    const a = s && (s.dersler || []).map((d) => d.ad).filter(Boolean);
    return a && a.length ? a : null;
  } catch (e) { return null; }
}
/* KGK: [{ad, bolum}] — bolum "temel alan …" / "ek alan — …" (soru-dizini.js yazar) */
function siteKgkDersleri(metin) {
  if (metin == null) return null;
  try {
    const j = JSON.parse(metin);
    const s = (j.sinavlar || []).find((x) => x.kod === 'kgk');
    const a = s && (s.dersler || []).filter((d) => d && d.ad).map((d) => ({ ad: d.ad, bolum: String(d.bolum || '') }));
    return a && a.length ? a : null;
  } catch (e) { return null; }
}

/* Girdi: { site:[ad], listeler:[{ad, dersler}] } -> bulgular */
function denetle(g) {
  const B = [];
  if (MUT !== 'kor') {
    if (!Array.isArray(g.site) || !g.site.length) { B.push({ kural: 'DA-KOR', yer: 'veri/soru-dizini.json', not: 'sitenin Yeterlilik ders adları okunamadı' }); return B; }
    for (const l of g.listeler) if (!Array.isArray(l.dersler) || !l.dersler.length) B.push({ kural: 'DA-KOR', yer: l.ad, not: 'ders listesi okunamadı' });
  }
  const site = new Set(g.site || []);
  for (const l of g.listeler) {
    if (!Array.isArray(l.dersler)) continue;
    const lk = new Set(l.dersler);
    if (MUT !== 'yok') for (const a of lk) if (!site.has(a)) B.push({ kural: 'DA-YOK', yer: l.ad, not: `"${a}" sitede ders adı değil (satılır/yazılır ama açılmaz)` });
    if (MUT !== 'eksik') for (const a of site) if (!lk.has(a)) B.push({ kural: 'DA-EKSIK', yer: l.ad, not: `sitedeki "${a}" bu listede yok` });
  }
  return B;
}

/* KGK girdisi: { site:[{ad,bolum}], moduller:[ad], esleme:{modul:[ders]} } -> bulgular */
function denetleKgk(g) {
  const B = [];
  const YER = 'fiyat-motoru.js KGK_MODUL_DERS';
  if (MUT !== 'kor') {
    if (!Array.isArray(g.site) || !g.site.length) { B.push({ kural: 'DA-KOR', yer: 'veri/soru-dizini.json (kgk)', not: 'sitenin KGK ders adları okunamadı' }); return B; }
    if (!Array.isArray(g.moduller) || !g.moduller.length) { B.push({ kural: 'DA-KOR', yer: 'fiyat-motoru.js DERSLER.kgk', not: 'modül listesi okunamadı' }); return B; }
    if (!g.esleme || typeof g.esleme !== 'object' || !Object.keys(g.esleme).length) { B.push({ kural: 'DA-KOR', yer: YER, not: 'modül → ders eşlemesi okunamadı' }); return B; }
  }
  const site = new Set((g.site || []).map((d) => d.ad));
  const moduller = g.moduller || []; const esleme = g.esleme || {};
  const gorulen = new Map();   // ders -> ilk modül
  if (MUT !== 'kgkmodul') {
    for (const m of moduller) if (!Array.isArray(esleme[m]) || !esleme[m].length) B.push({ kural: 'DA-KGK-MODUL', yer: YER, not: `"${m}" modülünün ders eşlemesi yok (satılır, hiçbir ders açılmaz)` });
    for (const m of Object.keys(esleme)) if (moduller.indexOf(m) < 0) B.push({ kural: 'DA-KGK-MODUL', yer: YER, not: `eşlemedeki "${m}" DERSLER.kgk'da modül değil (ölü satır)` });
  }
  for (const m of Object.keys(esleme)) {
    for (const d of (Array.isArray(esleme[m]) ? esleme[m] : [])) {
      if (MUT !== 'kgkyok' && !site.has(d)) B.push({ kural: 'DA-YOK', yer: YER, not: `"${d}" (${m}) sitede KGK dersi değil (yazılır ama kasa açmaz)` });
      if (MUT !== 'kgkcift' && gorulen.has(d) && gorulen.get(d) !== m) B.push({ kural: 'DA-KGK-CIFT', yer: YER, not: `"${d}" hem "${gorulen.get(d)}" hem "${m}" modülünde` });
      if (!gorulen.has(d)) gorulen.set(d, m);
    }
  }
  if (MUT !== 'kgkeksik') for (const d of (g.site || [])) if (/^temel alan/i.test(d.bolum) && !gorulen.has(d.ad)) B.push({ kural: 'DA-EKSIK', yer: YER, not: `sitedeki temel alan dersi "${d.ad}" hiçbir modülde yok (modül paketi alan onu alamaz)` });
  return B;
}

function gercekGirdi() {
  return {
    site: siteDersleri(oku('veri/soru-dizini.json')),
    listeler: [
      { ad: 'fiyat-motoru.js DERSLER.yeterlilik', dersler: fiyatDersleri(oku('fiyat-motoru.js')) },
      { ad: 'radar-app/edge/magaza-dogrula.ts DERSLER.yeterlilik', dersler: tsDizi(oku('radar-app/edge/magaza-dogrula.ts'), /const DERSLER\s*=\s*\{\s*yeterlilik:\s*\[([^\]]*)\]/) },
      { ad: 'radar-app/edge/karne-gonder.ts DERS_ADLARI_YET', dersler: tsDizi(oku('radar-app/edge/karne-gonder.ts'), /DERS_ADLARI_YET\s*=\s*\[([^\]]*)\]/) },
    ],
  };
}
function gercekKgkGirdi() {
  const fm = oku('fiyat-motoru.js');
  return { site: siteKgkDersleri(oku('veri/soru-dizini.json')), moduller: fiyatKgkModulleri(fm), esleme: fiyatKgkEsleme(fm) };
}

function ozSinav() {
  const gercek = gercekGirdi();
  const S = ['Finansal Muhasebe', 'Hukuk', 'Meslek Hukuku'];
  const V = [
    ['V1 gerçek depo bugün temiz', gercek, 0, null],
    ['V2 "Temel Hukuk" geri gelirse yakalar (10.10 olayı)', { site: S, listeler: [{ ad: 'f', dersler: ['Finansal Muhasebe', 'Temel Hukuk', 'Meslek Hukuku'] }] }, 2, null],
    ['V3 sitedeki ders listede yoksa yakalar', { site: S, listeler: [{ ad: 'f', dersler: ['Finansal Muhasebe', 'Hukuk'] }] }, 1, 'DA-EKSIK'],
    ['V4 sıra farkı alarm vermez', { site: S, listeler: [{ ad: 'f', dersler: ['Meslek Hukuku', 'Hukuk', 'Finansal Muhasebe'] }] }, 0, null],
    ['V5 "Meslek Hukuku" ile "Hukuk" karıştırılmaz (içerme değil birebir)', { site: S, listeler: [{ ad: 'f', dersler: ['Finansal Muhasebe', 'Meslek Hukuku', 'Meslek Hukuku'] }] }, 1, 'DA-EKSIK'],
    ['V6 liste okunamazsa KÖR = KIRMIZI', { site: S, listeler: [{ ad: 'f', dersler: null }] }, 1, 'DA-KOR'],
    ['V7 site adları okunamazsa KÖR = KIRMIZI', { site: null, listeler: [{ ad: 'f', dersler: S }] }, 1, 'DA-KOR'],
  ];
  let kir = 0;
  for (const [ad, girdi, bekSay, bekKural] of V) {
    const b = denetle(girdi);
    const ok = b.length === bekSay && (!bekKural || b.every((x) => x.kural === bekKural));
    if (!ok) kir++;
    console.log((ok ? 'GEÇTİ  ' : 'KALDI  ') + ad + (ok ? '' : '  -> ' + JSON.stringify(b)));
  }
  /* V2 ayrıntısı: Temel Hukuk = 1 DA-YOK + 1 DA-EKSIK (Hukuk eksik) */
  const b2 = denetle(V[1][1]);
  const ok2 = b2.some((x) => x.kural === 'DA-YOK' && /Temel Hukuk/.test(x.not)) && b2.some((x) => x.kural === 'DA-EKSIK' && /"Hukuk"/.test(x.not));
  if (!ok2) kir++;
  console.log((ok2 ? 'GEÇTİ  ' : 'KALDI  ') + 'V8 Temel Hukuk vakası DA-YOK + DA-EKSIK ikisini de adlandırır');
  /* V9 gerçek okuma: üç liste ve site gerçekten okundu (okuyucu körleşirse V1 "temiz" yalan söylemesin) */
  const ok9 = Array.isArray(gercek.site) && gercek.site.length >= 8 && gercek.listeler.every((l) => Array.isArray(l.dersler) && l.dersler.length >= 8);
  if (!ok9) kir++;
  console.log((ok9 ? 'GEÇTİ  ' : 'KALDI  ') + 'V9 site + 3 liste gerçek dosyalardan okundu (her biri ≥8 ders)');

  /* ---- KGK kolu (13.10) ---- */
  const gk = gercekKgkGirdi();
  const KS = [{ ad: 'Türkiye Muhasebe Standartları', bolum: 'temel alan (SMMM+YMM)' }, { ad: 'Türkiye Denetim Standartları', bolum: 'temel alan (SMMM+YMM)' },
              { ad: 'Kurumsal Yönetim', bolum: 'temel alan (yalnız SMMM)' }, { ad: 'Finansal Yönetim', bolum: 'temel alan (yalnız SMMM)' },
              { ad: 'Sermaye Piyasası Mevzuatı', bolum: 'ek alan — sermaye piyasası' }, { ad: 'Sürdürülebilirlik Denetimi', bolum: 'ek alan — sürdürülebilirlik' }];
  const KM = ['TMS', 'KY+FY', 'TDS', 'Sektör'];
  const KE = { 'TMS': ['Türkiye Muhasebe Standartları'], 'KY+FY': ['Kurumsal Yönetim', 'Finansal Yönetim'], 'TDS': ['Türkiye Denetim Standartları'], 'Sektör': ['Sermaye Piyasası Mevzuatı'] };
  const kgkV = [
    ['K1 gerçek depo KGK kolu bugün temiz', gk, 0, null],
    ['K2 örnek eşleme temiz (ek alan sürdürülebilirlik eşlemede yok = bulgu değil)', { site: KS, moduller: KM, esleme: KE }, 0, null],
    ['K3 modül adı sitede ders sanılırsa (eşleme yerine modül adı) DA-YOK + DA-EKSIK (10.10 vakasının KGK hâli)', { site: KS, moduller: KM, esleme: Object.assign({}, KE, { 'TMS': ['Muhasebe Standartları (TMS)'] }) }, 2, null],
    ['K4 modülün eşlemesi yoksa DA-KGK-MODUL', { site: KS, moduller: KM.concat(['Yeni Modül']), esleme: KE }, 1, 'DA-KGK-MODUL'],
    ['K5 eşlemede ölü anahtar DA-KGK-MODUL', { site: KS, moduller: KM, esleme: Object.assign({}, KE, { 'Eski': ['Finansal Yönetim'] }) }, 2, null],
    ['K6 temel alan dersi hiçbir modülde yoksa DA-EKSIK', { site: KS, moduller: KM, esleme: Object.assign({}, KE, { 'KY+FY': ['Kurumsal Yönetim'] }) }, 1, 'DA-EKSIK'],
    ['K7 aynı ders iki modülde DA-KGK-CIFT', { site: KS, moduller: KM, esleme: Object.assign({}, KE, { 'Sektör': ['Sermaye Piyasası Mevzuatı', 'Finansal Yönetim'] }) }, 1, 'DA-KGK-CIFT'],
    ['K8 eşleme okunamazsa KÖR = KIRMIZI', { site: KS, moduller: KM, esleme: null }, 1, 'DA-KOR'],
    ['K9 site KGK dersleri okunamazsa KÖR = KIRMIZI', { site: null, moduller: KM, esleme: KE }, 1, 'DA-KOR'],
  ];
  for (const [ad, girdi, bekSay, bekKural] of kgkV) {
    const b = denetleKgk(girdi);
    const ok = b.length === bekSay && (!bekKural || b.every((x) => x.kural === bekKural));
    if (!ok) kir++;
    console.log((ok ? 'GEÇTİ  ' : 'KALDI  ') + ad + (ok ? '' : '  -> ' + JSON.stringify(b)));
  }
  /* K5 ayrıntısı: ölü anahtar DA-KGK-MODUL + Finansal Yönetim iki modülde DA-KGK-CIFT */
  const b5 = denetleKgk(kgkV[4][1]);
  const ok5 = b5.some((x) => x.kural === 'DA-KGK-MODUL' && /"Eski"/.test(x.not)) && b5.some((x) => x.kural === 'DA-KGK-CIFT' && /Finansal Yönetim/.test(x.not));
  if (!ok5) kir++;
  console.log((ok5 ? 'GEÇTİ  ' : 'KALDI  ') + 'K10 ölü anahtar vakası DA-KGK-MODUL + DA-KGK-CIFT ikisini de adlandırır');
  /* K11 gerçek okuma: site KGK dersleri ≥ 7 (13.10: 9), modül 4, eşleme 4 anahtar */
  const ok11 = Array.isArray(gk.site) && gk.site.length >= 7 && Array.isArray(gk.moduller) && gk.moduller.length === 4 && gk.esleme && Object.keys(gk.esleme).length === 4;
  if (!ok11) kir++;
  console.log((ok11 ? 'GEÇTİ  ' : 'KALDI  ') + 'K11 site KGK dersleri (≥7) + 4 modül + 4 anahtarlı eşleme gerçek dosyalardan okundu');

  /* K12 ayrıntısı: K3'te DA-YOK modül adını, DA-EKSIK sitedeki TMS dersini adlandırır */
  const b3 = denetleKgk(kgkV[2][1]);
  const ok12 = b3.some((x) => x.kural === 'DA-YOK' && /Muhasebe Standartları \(TMS\)/.test(x.not)) && b3.some((x) => x.kural === 'DA-EKSIK' && /"Türkiye Muhasebe Standartları"/.test(x.not));
  if (!ok12) kir++;
  console.log((ok12 ? 'GEÇTİ  ' : 'KALDI  ') + 'K12 modül adı vakası DA-YOK (modül adı) + DA-EKSIK (sitedeki ders) ikisini de adlandırır');
  const top = V.length + 2 + kgkV.length + 3;
  console.log(kir ? `KAPI-DA ÖZ-SINAV: KIRMIZI (${kir}/${top} vaka kaldı)` : `KAPI-DA ÖZ-SINAV: YEŞİL (${top}/${top})`);
  process.exit(kir ? 1 : 0);
}

if (require.main === module) {
  if (process.argv.includes('--sinav')) ozSinav();
  const g = gercekGirdi();
  const gk = gercekKgkGirdi();
  const b = denetle(g).concat(denetleKgk(gk));
  console.log(`KAPI-DA: site Yeterlilik dersi ${g.site ? g.site.length : 'OKUNAMADI'} · liste ${g.listeler.length} · site KGK dersi ${gk.site ? gk.site.length : 'OKUNAMADI'} · KGK modül ${gk.moduller ? gk.moduller.length : 'OKUNAMADI'} · eşleme ${gk.esleme ? Object.keys(gk.esleme).length : 'OKUNAMADI'}`);
  for (const x of b) console.log(`  ${x.kural}  ${x.yer}: ${x.not}`);
  console.log(b.length ? `KAPI-DA: KIRMIZI (${b.length} bulgu)` : 'KAPI-DA: YEŞİL');
  process.exit(b.length ? 1 : 0);
}
module.exports = { denetle, denetleKgk, fiyatDersleri, fiyatKgkModulleri, fiyatKgkEsleme, siteDersleri, siteKgkDersleri, tsDizi };
