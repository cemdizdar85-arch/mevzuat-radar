#!/usr/bin/env node
/* magaza-sinavi.js — UYGULAMA İÇİ SATIN ALMANIN ÖZ-SINAVI (25.09.2026, dogrula.yml)
 *
 * radar-app/edge/magaza-dogrula.ts'in SAF bloğunu (// SAF-BASLA … // SAF-BITIS, tip yazımı yok) Node'da
 * vm ile GERÇEK kodundan koşturur (replika YASAK) ve ölçer:
 *   A) hakKarari(): kime ne tanımlanır, ne REDDEDİLİR (red = tüketilmez = Google 3 günde iade eder)
 *   B) dersleriDogrula() ve googleHukmu() (başka hesabın jetonu, bekleyen/iptal ödeme)
 *   C) bitisHesapla() = fiyat-motoru.js bitisTarihi() — 400 farklı günde aynı gün
 *   D) paketSinavlari() = paket-kapisi.js kapsar() — paket×sınav tablosunda aynı
 *   E) Katalog tutarlılığı: magaza-urunleri.json ↔ edge URUNLER/DERSLER · site fiyatı = fiyat-motoru.js
 *      kuruluş fiyatı · mağaza fiyatı = ⌈site ÷ 0,85⌉ · ders adları = kasadaki (kaydir/smmm/index.html) adlar
 *
 * Mutasyon (kural 8): `--mutasyon` SAF bloğu bilerek bozar (hesap kontrolü, zaten-açık reddi, başka-sınav
 * reddi, ders sayısı, bitiş uzatması) — her bozmada sınav KIRMIZI düşmeli.
 * BU SINAV ŞUNU GÖRMEZ: Google API'nin gerçek yanıtı, Supabase yazımı, ağ (hepsi canlı prova ister).
 */
'use strict';
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const { spawnSync } = require('child_process');

const DEPO = path.resolve(__dirname, '..');
const EDGE = path.join(DEPO, 'radar-app', 'edge', 'magaza-dogrula.ts');

const MUTASYONLAR = {
  'hesap':        ['g.obfuscatedExternalAccountId !== kullaniciId', 'false'],
  'zaten-acik':   ['if (!yeniDers.length) return { islem: "red", neden: "zaten-acik" };', ''],
  'baska-sinav':  ['if (paketSinavlari(p).indexOf(u.sinav) < 0) return { islem: "red", neden: "baska-sinav" };', ''],
  'ders-sayisi':  ['if (temiz.length !== u.ders) return { tamam: false, hata: "ders-sayisi" };', ''],
  'uzatma':       ['const uzat = satir.bitis && satir.bitis > yeniBitis ? satir.bitis : yeniBitis;', 'const uzat = yeniBitis;']
};

if (process.argv.includes('--mutasyon')) {
  let tutan = 0;
  for (const ad of Object.keys(MUTASYONLAR)) {
    const r = spawnSync(process.execPath, [__filename], { env: Object.assign({}, process.env, { MG_MUTASYON: ad }), encoding: 'utf8' });
    const dustu = r.status !== 0;
    if (dustu) tutan++;
    console.log('  mutasyon ' + ad.padEnd(12) + (dustu ? 'KIRMIZI (doğru)' : 'YESIL (YANLIŞ — sınav bu kuralı ölçmüyor)'));
  }
  console.log('MUTASYON: ' + tutan + '/' + Object.keys(MUTASYONLAR).length + ' → KIRMIZI');
  process.exit(tutan === Object.keys(MUTASYONLAR).length ? 0 : 1);
}

let gecen = 0, toplam = 0;
function t(ad, kosul, not) { toplam++; if (kosul) gecen++; console.log((kosul ? '  ✓ ' : '  ✗ ') + ad + (kosul ? '' : '  → ' + (not || ''))); }

/* ---- SAF bloğu yükle ---- */
const ts = fs.readFileSync(EDGE, 'utf8').replace(/\r\n/g, '\n');
const b = ts.indexOf('// SAF-BASLA'), s = ts.indexOf('// SAF-BITIS');
if (b < 0 || s < 0) { console.log('SAF blok işaretleri yok'); process.exit(1); }
let saf = ts.slice(b, s);
const mut = process.env.MG_MUTASYON;
if (mut) {
  const [eski, yeni] = MUTASYONLAR[mut];
  if (saf.indexOf(eski) < 0) { console.log('mutasyon hedefi bulunamadı: ' + mut); process.exit(3); }
  saf = saf.split(eski).join(yeni);
}
const E = {};
vm.createContext(E);
vm.runInContext(saf + '\n;this.X={URUNLER,DERSLER,SINAV_TARIHI,SURE_GUN,bitisHesapla,paketSinavlari,dersleriDogrula,hakKarari,googleHukmu,trGunu};', E);
const X = E.X;

/* ---- A) hakKarari ---- */
const SIMDI = new Date('2026-09-25T10:00:00+03:00').getTime();
const Y = X.DERSLER.yeterlilik;
const gelecek = '2026-12-31', gecmis = '2026-01-01';
const k = (satir, urun, dersler) => X.hakKarari(satir, urun, dersler, SIMDI);

let r = k(null, 'sgs', null);
t('A1 satırı yok + SGS → ekle, paket sgs, bitiş = geç olan (90 gün 2026-12-24 > sınav+3 2026-11-24)', r.islem === 'ekle' && r.yeni.paket === 'sgs' && r.yeni.bitis === '2026-12-24', JSON.stringify(r));
r = k({ paket: 'sgs', bitis: gecmis, dersler: null }, 'yeterlilik_2', [Y[0], Y[1]]);
t('A2 süresi bitmiş SGS + Yeterlilik 2 ders → guncelle (eskinin yerine)', r.islem === 'guncelle' && r.yeni.paket === 'yeterlilik-2' && r.yeni.dersler.length === 2, JSON.stringify(r));
r = k({ paket: 'sgs', bitis: gelecek, dersler: null }, 'yeterlilik_1', [Y[0]]);
t('A3 aktif SGS + Yeterlilik → RED baska-sinav (tek satır sınırı)', r.islem === 'red' && r.neden === 'baska-sinav', JSON.stringify(r));
r = k({ paket: 'kurucu', bitis: null, dersler: null }, 'sgs', null);
t('A4 kurucu (her şey açık) + SGS → RED zaten-acik', r.islem === 'red' && r.neden === 'zaten-acik', JSON.stringify(r));
r = k({ paket: 'sgs', bitis: gelecek, dersler: null }, 'sgs', null);
t('A5 aktif SGS + SGS yeniden → guncelle, bitiş KISALMAZ (2026-12-31 kalır)', r.islem === 'guncelle' && r.yeni.bitis === gelecek, JSON.stringify(r));
r = k({ paket: 'yeterlilik-2', bitis: gelecek, dersler: [Y[0], Y[1]] }, 'yeterlilik_1', [Y[2]]);
t('A6 2 ders + 1 yeni ders → yeterlilik-3, 3 ders', r.islem === 'guncelle' && r.yeni.paket === 'yeterlilik-3' && r.yeni.dersler.length === 3, JSON.stringify(r));
r = k({ paket: 'yeterlilik-2', bitis: gelecek, dersler: [Y[0], Y[1]] }, 'yeterlilik_1', [Y[1]]);
t('A7 zaten sahip olduğu dersi yeniden alma → RED zaten-acik', r.islem === 'red' && r.neden === 'zaten-acik', JSON.stringify(r));
r = k({ paket: 'yeterlilik-4', bitis: gelecek, dersler: Y.slice(0, 4) }, 'yeterlilik_4', Y.slice(4, 8));
t('A8 4 + 4 ders = 8 → yeterlilik-tum, dersler null', r.islem === 'guncelle' && r.yeni.paket === 'yeterlilik-tum' && r.yeni.dersler === null, JSON.stringify(r));
r = k({ paket: 'yeterlilik-tum', bitis: gelecek, dersler: null }, 'yeterlilik_1', [Y[0]]);
t('A9 tüm dersler açık + 1 ders → RED zaten-acik', r.islem === 'red' && r.neden === 'zaten-acik', JSON.stringify(r));
r = k({ paket: 'yeterlilik-1', bitis: gelecek, dersler: [Y[0]] }, 'yeterlilik_tum', null);
t('A10 1 ders + tüm dersler → yeterlilik-tum', r.islem === 'guncelle' && r.yeni.paket === 'yeterlilik-tum' && r.yeni.dersler === null, JSON.stringify(r));
r = k({ paket: 'yeterlilik-kgk', bitis: gelecek, dersler: null }, 'yeterlilik_1', [Y[0]]);
t('A11 yeterlilik-kgk (yeterlilik kapsar, tüm dersler) + 1 ders → RED zaten-acik', r.islem === 'red' && r.neden === 'zaten-acik', JSON.stringify(r));
r = k({ paket: 'yeterlilik-2', bitis: '2027-06-01', dersler: [Y[0], Y[1]] }, 'yeterlilik_1', [Y[5]]);
t('A12 ders eklerken daha geç bitiş korunur (2027-06-01)', r.islem === 'guncelle' && r.yeni.bitis === '2027-06-01', JSON.stringify(r));

/* ---- B) dersleriDogrula + googleHukmu ---- */
t('B1 1 derslik ürüne 2 ders → ders-sayisi', X.dersleriDogrula('yeterlilik_1', [Y[0], Y[1]]).hata === 'ders-sayisi');
t('B2 listede olmayan ders adı (sitenin "Temel Hukuk"u) → ders-gecersiz', X.dersleriDogrula('yeterlilik_1', ['Temel Hukuk']).hata === 'ders-gecersiz');
t('B3 ders seçilmemiş → ders-secilmedi', X.dersleriDogrula('yeterlilik_2', null).hata === 'ders-secilmedi');
t('B4 SGS ve tüm dersler ders istemez (dersler null)', X.dersleriDogrula('sgs', ['x']).dersler === null && X.dersleriDogrula('yeterlilik_tum', null).dersler === null);
t('B5 bilinmeyen ürün → urun-yok', X.dersleriDogrula('radar_ay', null).hata === 'urun-yok');
t('B6 aynı ders iki kez seçilirse sayı tutmaz', X.dersleriDogrula('yeterlilik_2', [Y[0], Y[0]]).hata === 'ders-sayisi');
const U = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';
t('B7 Google: satın alındı + bu hesap → tamam', X.googleHukmu({ purchaseState: 0, obfuscatedExternalAccountId: U }, U) === 'tamam');
t('B8 Google: başka hesabın jetonu → baska-hesap', X.googleHukmu({ purchaseState: 0, obfuscatedExternalAccountId: 'x' }, U) === 'baska-hesap');
t('B9 Google: hesap kimliği boş → baska-hesap', X.googleHukmu({ purchaseState: 0 }, U) === 'baska-hesap');
t('B10 Google: bekleyen ödeme → beklemede, iptal → iptal', X.googleHukmu({ purchaseState: 2, obfuscatedExternalAccountId: U }, U) === 'beklemede' && X.googleHukmu({ purchaseState: 1, obfuscatedExternalAccountId: U }, U) === 'iptal');

/* ---- C) bitiş = fiyat-motoru.js ---- */
const F = { window: {}, console };
vm.createContext(F);
vm.runInContext(fs.readFileSync(path.join(DEPO, 'fiyat-motoru.js'), 'utf8') + '\n;this.Z={SINAVLAR,SURE_GUN,bitisTarihi,FIYAT};', F);
const Z = F.Z;
let fark = 0, ornek = '';
for (let g = 0; g < 400; g++) {
  const an = new Date('2026-06-01T09:30:00+03:00').getTime() + g * 86400000;
  for (const sn of ['sgs', 'yeterlilik']) {
    const site = X.trGunu(Z.bitisTarihi(sn, an).getTime());
    const edge = X.bitisHesapla(sn, an);
    if (site !== edge) { fark++; if (!ornek) ornek = sn + ' ' + new Date(an).toISOString() + ' site ' + site + ' edge ' + edge; }
  }
}
t('C1 bitisHesapla = fiyat-motoru bitisTarihi (400 gün × 2 sınav)', fark === 0, fark + ' fark · ' + ornek);
t('C2 sınav tarihleri ve süre fiyat-motoru.js ile aynı',
  Z.SURE_GUN === X.SURE_GUN && Z.SINAVLAR.every((s) => X.SINAV_TARIHI[s.anahtar] === s.tarih),
  JSON.stringify(Z.SINAVLAR.map((s) => [s.anahtar, s.tarih])) + ' / ' + JSON.stringify(X.SINAV_TARIHI));

/* ---- D) paketSinavlari = paket-kapisi.js kapsar ---- */
{
  const pk = fs.readFileSync(path.join(DEPO, 'paket-kapisi.js'), 'utf8');
  const m = pk.match(/var kapsar = function \(paket\) \{[\s\S]*?\n {6}\};/);
  let dfark = 0, dnot = '';
  if (!m) dfark = 1;
  else {
    for (const sn of ['sgs', 'yeterlilik']) {
      const site = new Function('sinavi', m[0] + ' return kapsar;')(sn);
      for (const p of ['', 'tam', 'kurucu', 'sgs', 'sgs-x', 'sinav-249', 'yeterlilik', 'yeterlilik-2', 'yeterlilik-kgk', 'smmm', 'kgk', 'kgk-2', 'son15', 'radar']) {
        const edge = X.paketSinavlari(p).indexOf(sn) >= 0;
        if (site(p) !== edge) { dfark++; dnot += ' [' + p + '/' + sn + ' site ' + site(p) + ' edge ' + edge + ']'; }
      }
    }
  }
  t('D1 paketSinavlari() = paket-kapisi.js kapsar() (14 paket × 2 sınav)', dfark === 0, dnot || 'kapsar bulunamadı');
}

/* ---- E) katalog ---- */
{
  const J = JSON.parse(fs.readFileSync(path.join(__dirname, 'magaza-urunleri.json'), 'utf8'));
  const eslesmeyen = J.urunler.filter((u) => { const e = X.URUNLER[u.id]; return !e || e.paket !== u.paket || e.sinav !== u.sinav || e.ders !== u.ders; }).map((u) => u.id)
    .concat(Object.keys(X.URUNLER).filter((id) => !J.urunler.some((u) => u.id === id)));
  t('E1 ürün listesi JSON = edge URUNLER (kimlik, paket, sınav, ders sayısı)', eslesmeyen.length === 0, eslesmeyen.join(', '));
  t('E2 ders listesi JSON = edge DERSLER', JSON.stringify(J.dersler.yeterlilik) === JSON.stringify(X.DERSLER.yeterlilik));
  const siteFiyat = { sgs: Z.FIYAT.sgs.kurulus, yeterlilik_tum: Z.FIYAT.yeterlilikTum.kurulus };
  for (let n = 1; n <= 4; n++) siteFiyat['yeterlilik_' + n] = Z.FIYAT.yeterlilik[n].kurulus;
  const fiyatFark = J.urunler.filter((u) => u.site_tl !== siteFiyat[u.id] || u.fiyat_tl !== Math.ceil(u.site_tl / 0.85))
    .map((u) => u.id + ' site ' + u.site_tl + '/' + siteFiyat[u.id] + ' mağaza ' + u.fiyat_tl + '/' + Math.ceil(u.site_tl / 0.85));
  t('E3 site fiyatı = fiyat-motoru kuruluş · mağaza fiyatı = ⌈site ÷ 0,85⌉', fiyatFark.length === 0, fiyatFark.join(' | '));
  const dizin = fs.readFileSync(path.join(DEPO, 'kaydir', 'smmm', 'index.html'), 'utf8');
  const kasaAd = [];
  const re = /<div class="ad">([^<]*)<\/div>/g; let mm;
  while ((mm = re.exec(dizin))) kasaAd.push(mm[1].replace(/&#(\d+);/g, (_, c) => String.fromCharCode(+c)).trim());
  const yok = J.dersler.yeterlilik.filter((d) => kasaAd.indexOf(d) < 0);
  t('E4 satılan ders adları kasadaki ders adlarıyla aynı (RLS dersler eşlemesi)', yok.length === 0 && kasaAd.length === 8, 'kasada yok: ' + yok.join(', ') + ' · kasa ' + kasaAd.length);
}

console.log('MAGAZA-SINAVI: ' + (gecen === toplam ? 'YESIL' : 'KIRMIZI') + ' — ' + gecen + '/' + toplam + (mut ? ' · MG_MUTASYON=' + mut : ''));
process.exit(gecen === toplam ? 0 : 1);
