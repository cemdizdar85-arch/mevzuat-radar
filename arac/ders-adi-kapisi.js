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
 * 🚫 BU KAPI ŞUNU GÖRMEZ:
 *   - kasadaki paket_soru.ders adları (servis anahtarı ister; soru-dizini.json kasadan basılan sayfalardan sayılır)
 *   - geçmiş sipariş/üye satırlarındaki eski adlar (yerel tarama: scratchpad siparis-tara.js deseni)
 *   - KGK modül adları (KGK satışta değil; eklendiğinde aynı kural genişletilmeli)
 *   - adı burada sayılmayan yeni bir liste
 *
 * Kullanım:  node arac/ders-adi-kapisi.js          (depoyu denetler; bulgu varsa çıkış 1)
 *            node arac/ders-adi-kapisi.js --sinav  (öz-sınav; DA_MUTASYON=yok|eksik|kor ile bozarak sınanır)
 */
'use strict';
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const KOK = path.resolve(__dirname, '..');
const MUT = process.env.DA_MUTASYON || '';

function oku(g) { try { return fs.readFileSync(path.join(KOK, g), 'utf8'); } catch (e) { return null; } }

/* fiyat-motoru.js GERÇEK kodundan koşturulur (replika yok). */
function fiyatDersleri(metin) {
  if (metin == null) return null;
  try {
    const E = { console: { log() {}, warn() {}, error() {} } };
    E.window = E; E.document = { getElementById() { return null; }, querySelector() { return null; } };
    E.location = { search: '', hash: '', pathname: '/' };
    vm.createContext(E);
    vm.runInContext(metin + '\n;this.__D = (typeof DERSLER === "object" && DERSLER) ? DERSLER.yeterlilik : null;', E);
    return Array.isArray(E.__D) ? E.__D.slice() : null;
  } catch (e) { return null; }
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
  const top = V.length + 2;
  console.log(kir ? `KAPI-DA ÖZ-SINAV: KIRMIZI (${kir}/${top} vaka kaldı)` : `KAPI-DA ÖZ-SINAV: YEŞİL (${top}/${top})`);
  process.exit(kir ? 1 : 0);
}

if (require.main === module) {
  if (process.argv.includes('--sinav')) ozSinav();
  const g = gercekGirdi();
  const b = denetle(g);
  console.log(`KAPI-DA: site Yeterlilik dersi ${g.site ? g.site.length : 'OKUNAMADI'} · liste ${g.listeler.length}`);
  for (const x of b) console.log(`  ${x.kural}  ${x.yer}: ${x.not}`);
  console.log(b.length ? `KAPI-DA: KIRMIZI (${b.length} bulgu)` : 'KAPI-DA: YEŞİL');
  process.exit(b.length ? 1 : 0);
}
module.exports = { denetle, fiyatDersleri, siteDersleri, tsDizi };
