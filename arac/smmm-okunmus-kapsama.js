#!/usr/bin/env node
/* ============================================================================
 *  YETERLİLİK (SMMM bitirme) OKUNMUŞ KAPSAMA TABLOSU — plan "okunmuş konu"ya bağlanır (05.10.2026, Cem "1.2.3", GM1)
 *  NİYE: arac/smmm-kapsama-tablosu.ps1 hedefi konu ETİKETİ sayımından (veri/smmm-analiz.json), "yazdık"ı kasa etiketinden
 *    (paket konu alanı) kurar. ÖLÇÜLDÜ (05.10, veri/sinav/YETERLILIK-BANKA-ACIKLARI-20261005.md):
 *      · tablonun 983 engelsiz açığının 229'u okunmuş eşlemeye göre ZATEN DOLU konulara düşüyor (Kalite yönetimi okunmuşta
 *        hedefin 64 üstünde, tablo 11 açık diyor); 410'u ölçülemez.
 *      · "GVK › Yıllık beyan ve GV hesabı" 25/31 dönemde çıkmış, okunmuş açık 51; tablo 15 açık görüyor — çıkmış sayımı onlarca
 *        etikete bölünmüş, "gelir vergisi hesabi" anahtarının sitede saydığı 10 sorunun 9'u okumada mükellefiyet türleri.
 *  YÖNTEM: hedef = aynı kural (toplam 4.000, ders tabanı 350, en büyük kalan), ağırlık = konunun 2016/1–2026/2 çıkmışta
 *    göründüğü DÖNEM sayısı (veri/sinav/smmm-konu-okuma.json, okunarak). Mevcut = sitedeki soruların okunmuş eşlemesi
 *    (veri/sinav/smmm-banka-esleme.json; çok konulu soru her konusuna 1/n) + sitede olmayıp yayın şartını geçen parti
 *    soruları (kapsama kütüğü: smmm-kapsama-tablosu.ps1 -SoruKutugu). Parti sorusunun konusu: (1) konu alanı okunmuş ad ise
 *    doğrudan (okunmuş plandan basılan yeni soru), (2) değilse KÖPRÜ: o kasa anahtarının sitedeki soruları ≥2 ve ≥%60 tek
 *    okunmuş konudaysa o konu; (3) yoksa EŞLENEMEDİ (sayılır, raporda KÖR olarak yazılır).
 *  ÇIKTI: veri/fabrika/smmm-okunmus-kapsama.csv — smmm-kapsama.csv ile AYNI sütunlar (ders · konu · cikmis · son10 ·
 *    son_soruldu · yenilik · yazdik · yayinlanabilir · hedef · acik · durum · engel); ders adı plan kurucunun kanonik adı.
 *    + veri/sinav/smmm-okunmus-kapsama-ozet.json (yalnız sayı; commit edilebilir).
 *  Plan: arac/smmm-plan-kur.ps1 -Tablo veri/fabrika/smmm-okunmus-kapsama.csv · dalga: arac/smmm-dalga-dongu.ps1 -Okunmus
 *  🚫 GÖRMEZ: okuyucu kararının doğruluğu (tek okuyucu; 30.09: tek okuyucunun TEMİZ dediği 10 sorudan 6'sı kusurluydu) ·
 *    sözlük dışı sitedeki sorular (sayılmaz, raporda) · köprüsüz kasa anahtarındaki site dışı sorular (EŞLENEMEDİ) ·
 *    konu ENGELİ için yalnız veri/sinav/kisir-konu-okunmus.json'a bakar (eski kısır listesi kasa adlarıyla, bağlanmadı).
 *  Kullanım:
 *    node arac/smmm-okunmus-kapsama.js --esleme-topla <klasör>     (sonuc-b*.json + banka-ders.json → veri/sinav/smmm-banka-esleme.json)
 *    node arac/smmm-okunmus-kapsama.js [--kutuk <yol>] [--sinav]   (vars. veri/fabrika/smmm-kapsama-kutuk.json)
 * ==========================================================================*/
'use strict';
const fs = require('fs'), path = require('path');
const KOK = path.join(__dirname, '..');
const arg = process.argv.slice(2);
const al = k => { const i = arg.indexOf(k); return i >= 0 ? arg[i + 1] : null; };
const SITE_PLAN = { 'Meslek Hukuku': 'Muh. ve Mali Müş. Meslek Hukuku' };   // site ders adı → plan/tablo kanonik adı
const OKUMA_SITE = { 'Muh. ve Mali Müş. Meslek Hukuku': 'Meslek Hukuku' };  // okuma ders adı → site ders adı
const PLAN_SITE = OKUMA_SITE;                                                // plan/kütük kanonik ders adı → site ders adı
const TOPLAM = 4000, TABAN = 350, KOPRU_MIN = 2, KOPRU_PAY = 0.6;

function nrm(s) {
  return String(s || '').replace(/İ/g, 'I').replace(/ı/g, 'i').toLowerCase().replace(/ı/g, 'i').replace(/ş/g, 's').replace(/ğ/g, 'g')
    .replace(/ü/g, 'u').replace(/ö/g, 'o').replace(/ç/g, 'c').replace(/â/g, 'a').replace(/î/g, 'i').replace(/û/g, 'u')
    .replace(/[^a-z0-9 ]/g, ' ').replace(/\s+/g, ' ').trim();
}
// en büyük kalan: ağırlık haritası üzerinden TAM `top` birim
function ebk(ag, top) {
  const r = {}; const w = Object.values(ag).reduce((a, b) => a + b, 0); if (!w || top <= 0) return r;
  const ks = []; let dag = 0;
  for (const [k, v] of Object.entries(ag)) { if (v <= 0) continue; const t = top * v / w, tb = Math.floor(t); r[k] = tb; dag += tb; ks.push([k, t - tb, v]); }
  ks.sort((a, b) => b[1] - a[1] || b[2] - a[2] || (a[0] < b[0] ? -1 : 1)).slice(0, top - dag).forEach(x => r[x[0]]++);
  return r;
}
// hedef dağıtımı (smmm-kapsama-tablosu.ps1 ile aynı kural): W = { 'ders|konu': ağırlık }
function hedefDagit(W, toplam = TOPLAM, taban = (process.env.OKT_MUTASYON === 'taban' ? 0 : TABAN)) {
  const dersW = {}; for (const [k, v] of Object.entries(W)) { const d = k.split('|')[0]; dersW[d] = (dersW[d] || 0) + v; }
  if (Object.keys(dersW).length * taban > toplam) throw new Error('ders tabanı toplamı aşıyor');
  const sabit = new Set(); let deg;
  do { deg = false; const kT = toplam - sabit.size * taban; let kW = 0; for (const d in dersW) if (!sabit.has(d)) kW += dersW[d];
    for (const d in dersW) { if (sabit.has(d)) continue; if (kT * dersW[d] / kW < taban) { sabit.add(d); deg = true; } } } while (deg);
  const serbest = {}; for (const d in dersW) if (!sabit.has(d)) serbest[d] = dersW[d];
  const pay = ebk(serbest, toplam - sabit.size * taban); for (const d of sabit) pay[d] = taban;
  const h = {}; for (const d in pay) { const kw = {}; for (const [k, v] of Object.entries(W)) if (k.split('|')[0] === d) kw[k] = v; Object.assign(h, ebk(kw, pay[d])); }
  return h;
}
// tablo: girdi nesneleri → satırlar (saf işlev; öz-sınav bunu çağırır)
function tabloKur({ okuma, esleme, kutuk, kisir }) {
  const sozluk = {}; // ders(site adı) → { nrm(konu): konu }
  for (const [d0, ks] of Object.entries(okuma.konular)) { const d = OKUMA_SITE[d0] || d0; sozluk[d] = sozluk[d] || {}; for (const k of Object.keys(ks)) sozluk[d][nrm(k)] = k; }
  const donem = {}, son = {};
  for (const x of okuma.kararlar) { const d = OKUMA_SITE[x.ders] || x.ders; const k = d + '|' + x.konu; (donem[k] = donem[k] || new Set()).add(x.donem);
    const [y, n] = String(x.donem).split('/'); const s = +y * 10 + +n; if (!son[k] || s > son[k]) son[k] = s; }
  const W = {}; for (const [k, s] of Object.entries(donem)) W[k] = s.size;
  const hedef = hedefDagit(W);
  const say = {}, yaz = {}; let sozlukDisi = 0, eslenemedi = 0, dogrudan = 0, koprulu = 0, siteSay = 0;
  const ekle = (h, k, v) => { h[k] = (h[k] || 0) + v; };
  // 1) sitedeki sorular: okunmuş eşleme
  const site = esleme.sorular;
  for (const [id, x] of Object.entries(site)) { siteSay++; if (!x.konular.length) { sozlukDisi++; continue; }
    for (const k of x.konular) { if (!(sozluk[x.ders] || {})[nrm(k)]) throw new Error('eşlemede sözlük dışı konu adı: ' + x.ders + ' | ' + k); const pay = process.env.OKT_MUTASYON === 'kesir' ? 1 : 1 / x.konular.length; ekle(say, x.ders + '|' + k, pay); ekle(yaz, x.ders + '|' + k, pay); } }
  // 2) köprü: kasa anahtarı → okunmuş konu (sitedeki sorulardan, çoğunluk)
  const anah = {};
  for (const [id, t] of Object.entries(kutuk)) { if (!site[id]) continue; const a = (anah[t.anahtar] = anah[t.anahtar] || { n: 0, ok: {} }); a.n++; for (const k of site[id].konular) ekle(a.ok, site[id].ders + '|' + k, 1); }
  const kopru = {};
  for (const [a, v] of Object.entries(anah)) { if (v.n < KOPRU_MIN) continue; const en = Object.entries(v.ok).sort((p, q) => q[1] - p[1])[0]; if (en && en[1] / v.n >= (process.env.OKT_MUTASYON === 'kopru' ? 0 : KOPRU_PAY)) kopru[a] = en[0]; }
  // 3) sitede olmayan parti soruları
  for (const [id, t] of Object.entries(kutuk)) { if (site[id]) continue;
    let k = null;
    // okunmuş plandan basılmış yeni soru: konu alanı (anahtar) bir okunmuş adın nrm'si ve ders etiketten
    const td = PLAN_SITE[t.ders] || t.ders;   // kütükte ders plan/kanonik adla yazılır
    if (process.env.OKT_MUTASYON !== 'dogrudan' && td && sozluk[td] && sozluk[td][t.anahtar]) { k = td + '|' + sozluk[td][t.anahtar]; dogrudan++; }
    else if (kopru[t.anahtar]) { k = kopru[t.anahtar]; koprulu++; }
    if (!k) { if (t.gecer) eslenemedi++; continue; }
    ekle(yaz, k, 1); if (t.gecer) ekle(say, k, 1); }
  const engel = {}; for (const x of (kisir || [])) engel[x.ders + '|' + x.konu] = x.neden || 'KISIR';
  const satir = [];
  for (const d of Object.keys(sozluk)) for (const konu of Object.values(sozluk[d])) {
    const k = d + '|' + konu, h = hedef[k] || 0, y = Math.round(say[k] || 0), dn = donem[k] ? donem[k].size : 0;
    satir.push({ ders: SITE_PLAN[d] || d, konu, cikmis: dn, son10: dn, son_soruldu: son[k] ? Math.floor(son[k] / 10) + '/' + (son[k] % 10) : '',
      yenilik: dn ? 'YENI' : 'OLCULMEDI', yazdik: Math.round(yaz[k] || 0), yayinlanabilir: y, hedef: h, acik: Math.max(0, h - y),
      durum: y >= h ? 'YETER' : (y === 0 ? 'HIC YOK' : 'EKSIK'), engel: engel[k] || '' });
  }
  return { satir, sayim: { site: siteSay, sozluk_disi_site: sozlukDisi, site_disi_gecer_eslenemedi: eslenemedi, site_disi_dogrudan: dogrudan, site_disi_koprulu: koprulu, kopru_anahtar: Object.keys(kopru).length } };
}
module.exports = { nrm, hedefDagit, tabloKur };

const csvHucre = v => '"' + String(v).replace(/"/g, '""') + '"';
function main() {
  const top = al('--esleme-topla');
  if (top) {
    const es = {}; fs.readdirSync(top).filter(f => /^sonuc-b\d+\.json$/.test(f)).forEach(f => Object.assign(es, JSON.parse(fs.readFileSync(path.join(top, f), 'utf8'))));
    const bd = JSON.parse(fs.readFileSync(path.join(top, 'banka-ders.json'), 'utf8'));
    const eksik = Object.keys(bd).filter(id => !(id in es)); if (eksik.length) { console.error('KIRMIZI: eşlemesi olmayan ' + eksik.length); process.exit(3); }
    const sorular = {}; for (const id of Object.keys(bd).sort()) sorular[id] = { ders: bd[id], konular: es[id] };
    fs.writeFileSync(path.join(KOK, 'veri/sinav/smmm-banka-esleme.json'), JSON.stringify({ kaynak: 'sitedeki Yeterlilik soruları (paket_soru sinav=smmm), ders başına tek okuyucu, sözlük veri/sinav/smmm-konu-okuma.json; soru metni YOK', soru: Object.keys(sorular).length, sorular }, null, 0));
    console.log('eşleme yazıldı: ' + Object.keys(sorular).length + ' soru'); return;
  }
  if (arg.includes('--sinav')) return sinav();
  const kutukYol = al('--kutuk') || path.join(KOK, 'veri/fabrika/smmm-kapsama-kutuk.json');
  if (!fs.existsSync(kutukYol)) { console.error('kapsama kütüğü yok: ' + kutukYol + ' — önce: powershell -File arac/smmm-kapsama-tablosu.ps1 -SoruKutugu ' + kutukYol); process.exit(2); }
  const yas = (Date.now() - fs.statSync(kutukYol).mtimeMs) / 3600e3;
  if (yas > 12 && !arg.includes('--zorla')) { console.error(`kapsama kütüğü BAYAT (${yas.toFixed(1)} saat > 12) — plan bayat veriyle kurulmaz (CLAUDE.md). Bilerek: --zorla`); process.exit(2); }
  const oku = p => JSON.parse(fs.readFileSync(path.join(KOK, p), 'utf8').replace(/^﻿/, ''));
  const kutuk = JSON.parse(fs.readFileSync(kutukYol, 'utf8').replace(/^﻿/, ''));
  const kisirYol = path.join(KOK, 'veri/sinav/kisir-konu-okunmus.json');
  const { satir, sayim } = tabloKur({ okuma: oku('veri/sinav/smmm-konu-okuma.json'), esleme: oku('veri/sinav/smmm-banka-esleme.json'), kutuk,
    kisir: fs.existsSync(kisirYol) ? JSON.parse(fs.readFileSync(kisirYol, 'utf8')).konular : [] });
  const S = ['ders', 'konu', 'cikmis', 'son10', 'son_soruldu', 'yenilik', 'yazdik', 'yayinlanabilir', 'hedef', 'acik', 'durum', 'engel'];
  satir.sort((a, b) => (a.ders < b.ders ? -1 : a.ders > b.ders ? 1 : b.acik - a.acik));
  fs.writeFileSync(path.join(KOK, 'veri/fabrika/smmm-okunmus-kapsama.csv'), '﻿' + [S.map(csvHucre).join(',')].concat(satir.map(r => S.map(s => csvHucre(r[s])).join(','))).join('\r\n') + '\r\n');
  const dersOz = {}; for (const r of satir) { const o = (dersOz[r.ders] = dersOz[r.ders] || { konu: 0, hedef: 0, yayinlanabilir: 0, acik: 0 }); o.konu++; o.hedef += r.hedef; o.yayinlanabilir += r.yayinlanabilir; o.acik += r.engel ? 0 : r.acik; }
  const ozet = { kural: `hedef ${TOPLAM}, ders tabanı ${TABAN}, ağırlık = okunmuş dönem sayısı`, sayim, toplam: { hedef: satir.reduce((a, r) => a + r.hedef, 0), yayinlanabilir: satir.reduce((a, r) => a + r.yayinlanabilir, 0), acik: satir.filter(r => !r.engel).reduce((a, r) => a + r.acik, 0) }, ders: dersOz };
  const ozYol = path.join(KOK, 'veri/sinav/smmm-okunmus-kapsama-ozet.json'), yeni = JSON.stringify(ozet, null, 1) + '\n';
  if (!fs.existsSync(ozYol) || fs.readFileSync(ozYol, 'utf8') !== yeni) fs.writeFileSync(ozYol, yeni);
  console.log(`OKUNMUŞ KAPSAMA · konu ${satir.length} · hedef ${ozet.toplam.hedef} · yayınlanabilir ${ozet.toplam.yayinlanabilir} · AÇIK ${ozet.toplam.acik}`);
  console.log(`  site ${sayim.site} (sözlük dışı ${sayim.sozluk_disi_site}) · site dışı: doğrudan ${sayim.site_disi_dogrudan} · köprülü ${sayim.site_disi_koprulu} · geçer ama EŞLENEMEDİ (KÖR) ${sayim.site_disi_gecer_eslenemedi} · köprü anahtarı ${sayim.kopru_anahtar}`);
  for (const [d, o] of Object.entries(dersOz)) console.log(`  ${d.padEnd(34)} hedef ${o.hedef} · yayınlanabilir ${o.yayinlanabilir} · açık ${o.acik}`);
}

// ÖZ-SINAV: yakalaması gereken + yanlış alarm vermemesi gereken. Mutasyon: OKT_MUTASYON=kopru|kesir|taban|dogrudan
function sinav() {
  const M = process.env.OKT_MUTASYON || '';
  let ok = 0, kotu = 0; const V = (ad, kosul) => { if (kosul) ok++; else { kotu++; console.log('  DÜŞTÜ: ' + ad); } };
  const okuma = { konular: { 'Vergi Mevzuatı ve Uygulaması': { 'GVK › Yıllık beyan': 't', 'GVK › Ücret': 't', 'KDV › İndirim': 't' }, 'Hukuk': { 'TTK › Tacir': 't' }, 'Muh. ve Mali Müş. Meslek Hukuku': { 'Staj': 't' } },
    kararlar: [] };
  const V0 = 'Vergi Mevzuatı ve Uygulaması';
  for (let i = 1; i <= 10; i++) okuma.kararlar.push({ ders: V0, donem: '2020/' + (i % 3 + 1) + 'x' + i, konu: 'GVK › Yıllık beyan' });
  for (let i = 1; i <= 2; i++) okuma.kararlar.push({ ders: V0, donem: '2021/' + i, konu: 'GVK › Ücret' });
  okuma.kararlar.push({ ders: V0, donem: '2016/1', konu: 'KDV › İndirim' });
  okuma.kararlar.push({ ders: 'Hukuk', donem: '2019/1', konu: 'TTK › Tacir' });
  okuma.kararlar.push({ ders: 'Muh. ve Mali Müş. Meslek Hukuku', donem: '2018/1', konu: 'Staj' });
  const esleme = { sorular: {
    's1': { ders: V0, konular: ['KDV › İndirim'] }, 's2': { ders: V0, konular: ['KDV › İndirim'] }, 's3': { ders: V0, konular: ['KDV › İndirim', 'GVK › Ücret'] },
    's4': { ders: V0, konular: [] }, 's5': { ders: 'Meslek Hukuku', konular: ['Staj'] }, 's6': { ders: V0, konular: ['GVK › Ücret', 'KDV › İndirim'] } } };
  const kutuk = {
    's1': { anahtar: 'gelir vergisi hesabi', gecer: true }, 's2': { anahtar: 'gelir vergisi hesabi', gecer: true }, 's3': { anahtar: 'gelir vergisi hesabi', gecer: true },
    'p1': { anahtar: 'gelir vergisi hesabi', gecer: true },                            // köprü → KDV › İndirim (2/3 ≥ %60 değil: 2,5/3 hayır → hesap aşağıda)
    'p2': { anahtar: nrm('GVK › Yıllık beyan'), ders: V0, gecer: true },               // okunmuş plandan yeni soru → doğrudan
    'p3': { anahtar: nrm('GVK › Yıllık beyan'), ders: V0, gecer: false },              // geçmeyen: yazdık'a girer, yayınlanabilir'e girmez
    'p4': { anahtar: 'bilinmeyen etiket', gecer: true },
    'p5': { anahtar: nrm('Staj'), ders: 'Muh. ve Mali Müş. Meslek Hukuku', gecer: true } };            // kanonik plan adıyla Meslek → site adına çevrilip doğrudan                             // köprüsüz → EŞLENEMEDİ
  let r;
  const kur = (o) => { const x = tabloKur(o); return x; };
  r = kur({ okuma, esleme, kutuk, kisir: [{ ders: 'Hukuk', konu: 'TTK › Tacir', neden: 'KISIR' }] });
  const bul = k => r.satir.find(x => x.konu === k);
  // köprü: anahtar 'gelir vergisi hesabi' sitede 3 soru, KDV › İndirim payı (1+1+0,5... sayım konu başı 1) = 3/3 → köprü KDV › İndirim
  V('köprü: site dışı p1 KDV › İndirim\'e yazıldı', bul('KDV › İndirim').yayinlanabilir === Math.round(1 + 1 + 0.5 + 0.5 + 1));
  V('doğrudan: okunmuş adlı yeni soru sayıldı', bul('GVK › Yıllık beyan').yayinlanabilir === 1 && bul('GVK › Yıllık beyan').yazdik === 2);
  V('köprüsüz geçer soru EŞLENEMEDİ sayıldı', r.sayim.site_disi_gecer_eslenemedi === 1);
  V('sözlük dışı site sorusu sayılmadı', r.sayim.sozluk_disi_site === 1);
  V('çok konulu soru 1/n (Ücret 0,5 + 0,5 = 1; tam sayılsa 2)', bul('GVK › Ücret').yayinlanabilir === 1);
  V('Meslek Hukuku kanonik plan adına çevrildi', !!r.satir.find(x => x.ders === 'Muh. ve Mali Müş. Meslek Hukuku' && x.konu === 'Staj'));
  V('kütükte kanonik Meslek adı → doğrudan sayıldı (site 1 + yeni 1)', r.satir.find(x => x.konu === 'Staj').yayinlanabilir === 2);
  V('engel yazıldı', bul('TTK › Tacir').engel === 'KISIR');
  V('hedef toplamı tam 4000', r.satir.reduce((a, x) => a + x.hedef, 0) === 4000);
  V('ders tabanı: her ders ≥350', ['Hukuk', 'Muh. ve Mali Müş. Meslek Hukuku'].every(d => r.satir.filter(x => x.ders === d).reduce((a, x) => a + x.hedef, 0) >= 350));
  V('dönem sayısı = ağırlık (Yıllık beyan 10 > Ücret 2)', bul('GVK › Yıllık beyan').hedef > bul('GVK › Ücret').hedef);
  // yanlış alarm: eşlemede sözlük dışı ad → durur
  let atti = false; try { tabloKur({ okuma, esleme: { sorular: { x: { ders: V0, konular: ['UYDURMA'] } } }, kutuk: {}, kisir: [] }); } catch { atti = true; }
  V('eşlemede sözlük dışı ad → KIRMIZI', atti);
  // yanlış alarm: köprü azınlıkla kurulmaz
  const r2 = tabloKur({ okuma, esleme: { sorular: { a: { ders: V0, konular: ['KDV › İndirim'] }, b: { ders: V0, konular: ['GVK › Ücret'] }, c: { ders: V0, konular: ['GVK › Yıllık beyan'] } } },
    kutuk: { a: { anahtar: 'k' }, b: { anahtar: 'k' }, c: { anahtar: 'k' }, d: { anahtar: 'k', gecer: true } }, kisir: [] });
  V('köprü %60 altı kurulmaz (3 konuya bölünmüş anahtar)', r2.sayim.kopru_anahtar === 0 && r2.sayim.site_disi_gecer_eslenemedi === 1);
  console.log(`OKUNMUŞ KAPSAMA ÖZ-SINAV: ${ok}/${ok + kotu}` + (M ? ` (mutasyon ${M})` : ''));
  process.exit(kotu ? 1 : 0);
}
if (require.main === module) main();
