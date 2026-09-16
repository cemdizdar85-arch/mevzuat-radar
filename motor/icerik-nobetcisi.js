// motor/icerik-nobetcisi.js — PAKET İÇERİĞİ NÖBETÇİSİ (14.09.2026)
//
// NEDEN: 14.09'da ölçüldü — "site güvenli" iddiası kişisel veri için doğruydu ama satılacak ürün
// (SGS soruları: soru + şıklar + doğru cevap + açıklama) herkese açık depoda ve canlı sitede duruyordu.
// İki karar ("sorular paralı olacak" + "soru dosyaları depoda") kimse tarafından birleştirilmedi.
// Bu nöbetçi o boşluğun bir daha SESSİZCE oluşmamasını sağlar: her gün depoda soru içeriği taşıyan
// dosyaları sayar, canlı sitede açık mı diye yoklar.
//
// HÜKÜM (Cem'in 3 hâl kuralı):
//   YEŞİL   açıkta paket içeriği yok
//   SARI    açıkta paket içeriği var AMA hepsi taban listesinde (bilinen, Adım 2'yi bekliyor)
//   KIRMIZI tabanda OLMAYAN yeni bir dosyada paket içeriği var (yeni sızıntı) -> mail
//   KÖR     tarama çalışmadı (dosya okunamadı / hiç dosya taranmadı)
// Taban: arac/icerik-nobeti-taban.json — elle tutulur, her değişiklik GEREKÇESİYLE. Adım 2 bitince boşalır.
//
// Soru içeriği tanımı (yanlış alarm frenli): bir nesnede SORU metni + ŞIKLAR + DOĞRU CEVAP birlikte.
//   uzun anahtarlar: soru + (siklar|secenekler) + (dogru|cevap)
//   kısa anahtarlar (veri/_cozme-sorular.json biçimi): s + o + c
//   HTML: "const SORULAR=" dizisi (Kaydır-Çöz sayfaları)
// Ücretsiz katman (bilinçli açık) ayrı sayılır, hükmü etkilemez: UCRETSIZ listesi.
//
//   node motor/icerik-nobetcisi.js            depoyu tarar + canlı siteyi yoklar, hüküm basar
//   node motor/icerik-nobetcisi.js --canli-yok canlı yoklama yok (yerel prova)
//   node motor/icerik-nobetcisi.js --taban-yaz açık dosya listesini tabana yazar (YALNIZ bilerek)
//   node motor/icerik-nobetcisi.js --sinav    öz-sınav (ağ yok)
// Çıkış kodu: YEŞİL/SARI 0 · KIRMIZI 2 · KÖR 3. Hüküm GITHUB_OUTPUT'a `hukum=` olarak da yazılır.
'use strict';
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const KOK = path.resolve(__dirname, '..');
const SITE = 'https://tetikte.com/';
const TABAN = path.join(KOK, 'arac', 'icerik-nobeti-taban.json');
const UCRETSIZ = [
  /^kaydir\/vitrin\//,                 // ana sayfa ve ücretsiz-dene örnek soruları
  /^veri\/seviye\/sgs-havuz\.json$/,    // ücretsiz seviye testi havuzu
  /^veri\/vitrin-kart-ozet\.json$/,     // günün sorusu (tek soru)
  /^veri\/vitrin-soru-havuzu\.json$/,
  /^veri\/vitrin\//
];
const BOYUT_TAVAN = 40 * 1024 * 1024;

function soruNesnesiMi(o) {
  if (!o || typeof o !== 'object' || Array.isArray(o)) return false;
  const uzun = typeof o.soru === 'string' && (o.siklar || o.secenekler) && (o.dogru != null || o.cevap != null);
  const kisa = typeof o.s === 'string' && o.o && o.c != null;
  return !!(uzun || kisa);
}

function soruSay(deger) {
  let n = 0;
  const yigin = [deger];
  while (yigin.length) {
    const x = yigin.pop();
    if (Array.isArray(x)) { for (const e of x) yigin.push(e); continue; }
    if (x && typeof x === 'object') {
      if (soruNesnesiMi(x)) { n++; continue; }
      for (const k in x) yigin.push(x[k]);
    }
  }
  return n;
}

// "const SORULAR=[...]" dizisini keser ve nesneleri döndürür (yoksa [], bozuksa null).
function htmlSorulariCek(metin) {
  const i = metin.indexOf('const SORULAR=');
  if (i < 0) return [];
  const j = i + 'const SORULAR='.length;
  if (metin[j] !== '[') return [];
  let derinlik = 0, dizede = false, kacis = false;
  for (let k = j; k < metin.length; k++) {
    const ch = metin[k];
    if (dizede) { if (kacis) kacis = false; else if (ch === '\\') kacis = true; else if (ch === '"') dizede = false; continue; }
    if (ch === '"') dizede = true;
    else if (ch === '[') derinlik++;
    else if (ch === ']') { derinlik--; if (derinlik === 0) { try { return JSON.parse(metin.slice(j, k + 1)); } catch (e) { return null; } } }
  }
  return null;
}

// KALİTE (15.09.2026): yayındaki soru ret kütüğünde mi? Basım kapısı (arac/sgs-650-bas.ps1) bu soruları
// düşürür; ama sayfa, hakem SONRADAN HAYIR dediyse yeniden basılana kadar soruyu taşımaya devam eder.
// 15.09 ölçümü: 3.809 yayındaki sorudan 4'ü (Matematik, KAYNAK-EKSIK) bu durumdaydı.
// Cevabı riskli sınıflar KIRMIZI (öğrenci yanlış öğrenir), diğerleri SARI (yeniden basım bekliyor).
const CEVAP_RISKI = /SIM-YANLIS|KOR-CELISKI|HESAP-YANLIS|CIFT-ANLAM|COK-ANLAMLI|CELDIRICI-SAHTE/;
function kaliteHukmu(yayindakiIdler, retKayitlari) {
  const ret = new Map();
  for (const r of retKayitlari || []) { const k = r.etiket + '/' + r.id; if (!ret.has(k)) ret.set(k, r); }
  const esles = [];
  for (const [id, sayfa] of yayindakiIdler) if (ret.has(id)) { const r = ret.get(id); esles.push({ id, sayfa, kapi: r.kapi, sinif: r.sinif, risk: CEVAP_RISKI.test(String(r.sinif)) }); }
  const hukum = esles.some(e => e.risk) ? 'KIRMIZI' : esles.length ? 'SARI' : 'YEŞİL';
  return { hukum, esles };
}

function htmlSorulariSay(metin) {
  const i = metin.indexOf('const SORULAR=');
  if (i < 0) return 0;
  let j = i + 'const SORULAR='.length;
  if (metin[j] !== '[') return 0;
  let derinlik = 0, dizede = false, kacis = false;
  for (let k = j; k < metin.length; k++) {
    const ch = metin[k];
    if (dizede) {
      if (kacis) kacis = false;
      else if (ch === '\\') kacis = true;
      else if (ch === '"') dizede = false;
      continue;
    }
    if (ch === '"') dizede = true;
    else if (ch === '[') derinlik++;
    else if (ch === ']') { derinlik--; if (derinlik === 0) {
      const dilim = metin.slice(j, k + 1);
      // JSON değilse (ör. ihale-radari.html'deki {q:"..."} anket dizisi) sınav içeriği değildir;
      // yalnız "soru" anahtarı taşıyıp ayrıştırılamıyorsa KÖR sayılır.
      try { return soruSay(JSON.parse(dilim)); } catch (e) { return /"soru"\s*:/.test(dilim) ? -1 : 0; }
    } }
  }
  return -1;
}

function dosyaSay(yol, metin) {
  if (/\.enc\.json$/.test(yol)) return 0;              // şifreli: içerik açık değil
  if (/\.html?$/.test(yol)) return htmlSorulariSay(metin);
  if (/\.json$/.test(yol)) { try { return soruSay(JSON.parse(metin.replace(/^﻿/, ''))); } catch (e) { return -1; } }
  return 0;
}

function ucretsizMi(yol) { return UCRETSIZ.some(r => r.test(yol)); }

// ADIM 2 (16.09.2026): kasa modundaki sayfa SORUSUZ kabuktur (motor/kasa-kabuk.js), sorusu Supabase paket_soru'da.
// Kabuk "kasada" sayılır. arac/kasa-modu.json'da olup depoda TAM duran sayfa = kabuk atlanıp tam sayfa itilmiş -> KIRMIZI.
const KABUK_ISARET = 'data-kasa-sayfa=';
function kasaModu() {
  try { return (JSON.parse(fs.readFileSync(path.join(KOK, 'arac', 'kasa-modu.json'), 'utf8').replace(/^﻿/, '')).sayfalar || []).map(String); }
  catch (e) { return null; }
}

function depoyuTara() {
  const liste = execSync('git ls-files -z', { cwd: KOK, maxBuffer: 64 * 1024 * 1024 }).toString('utf8')
    .split('\0').filter(p => /\.(html?|json)$/.test(p));
  const sonuc = { taranan: 0, okunamayan: [], paket: [], ucretsiz: [], kasada: [] };
  for (const yol of liste) {
    const tam = path.join(KOK, yol);
    let st; try { st = fs.statSync(tam); } catch (e) { continue; }
    if (st.size > BOYUT_TAVAN) continue;
    let metin; try { metin = fs.readFileSync(tam, 'utf8'); } catch (e) { sonuc.okunamayan.push(yol); continue; }
    sonuc.taranan++;
    if (/\.html?$/.test(yol) && metin.includes(KABUK_ISARET)) { sonuc.kasada.push(yol); continue; }
    // hızlı ön süzgeç: soru imzası yoksa ayrıştırma
    if (!/"soru"\s*:|"s"\s*:|const SORULAR=/.test(metin)) continue;
    const n = dosyaSay(yol, metin);
    if (n < 0) { sonuc.okunamayan.push(yol); continue; }
    if (n === 0) continue;
    (ucretsizMi(yol) ? sonuc.ucretsiz : sonuc.paket).push({ yol, soru: n });
  }
  return sonuc;
}

async function canliYokla(kayitlar) {
  for (const k of kayitlar.slice(0, 80)) {
    try {
      const r = await fetch(SITE + k.yol.split('/').map(encodeURIComponent).join('/'), { method: 'HEAD', redirect: 'follow' });
      k.canli = r.status;
    } catch (e) { k.canli = 'hata'; }
  }
}

function hukumVer(tarama, taban) {
  if (tarama.taranan === 0) return { hukum: 'KÖR', neden: 'hiç dosya taranmadı' };
  if (tarama.okunamayan.length) return { hukum: 'KÖR', neden: 'okunamayan/ayrıştırılamayan: ' + tarama.okunamayan.slice(0, 5).join(', ') };
  const kasada = new Set(tarama.kasada || []);
  const kabuksuz = (tarama.kasaModu || []).filter(y => !kasada.has(y));
  if (kabuksuz.length) return { hukum: 'KIRMIZI', neden: 'kasa modundaki sayfa depoda TAM duruyor (kabuk atlanmış): ' + kabuksuz.join(', '), yeni: kabuksuz.map(y => ({ yol: y, soru: 0 })) };
  const bilinen = new Set((taban && taban.acik_dosyalar) || []);
  const yeni = tarama.paket.filter(k => !bilinen.has(k.yol));
  if (yeni.length) return { hukum: 'KIRMIZI', neden: 'tabanda olmayan açık paket içeriği: ' + yeni.map(k => k.yol + ' (' + k.soru + ')').join(', '), yeni };
  if (tarama.paket.length) return { hukum: 'SARI', neden: 'açıkta ' + tarama.paket.length + ' bilinen dosya (Adım 2 bekliyor)' };
  return { hukum: 'YEŞİL', neden: 'açıkta paket içeriği yok' };
}

function sinav() {
  let h = 0; const t = (ad, k) => { console.log((k ? '  geçti: ' : '  DÜŞTÜ: ') + ad); if (!k) h++; };
  t('uzun anahtarlı soru sayılır', soruSay([{ soru: 'x', siklar: { A: 1 }, dogru: 'A' }]) === 1);
  t('kısa anahtarlı soru sayılır', soruSay({ liste: [{ s: 'x', o: ['a'], c: 0 }, { s: 'y', o: ['b'], c: 1 }] }) === 2);
  t('şıksız metin sayılmaz', soruSay([{ soru: 'x', dogru: 'A' }]) === 0);
  t('cevapsız sayılmaz', soruSay([{ soru: 'x', siklar: {} }]) === 0);
  t('sayaç dosyası sayılmaz', soruSay({ sinavlar: [{ kod: 'sgs', soru: 3678 }] }) === 0);
  t('HTML SORULAR dizisi sayılır', htmlSorulariSay('<script>const SORULAR=[{"soru":"a ] [ b","siklar":{"A":"x"},"dogru":"A"},{"soru":"c","siklar":{},"dogru":"B"}];</script>') === 2);
  t('dize içindeki kaçışlı tırnak kesmez', htmlSorulariSay('const SORULAR=[{"soru":"\\"]\\"","siklar":{"A":1},"dogru":"A"}];') === 1);
  t('SORULAR yoksa 0', htmlSorulariSay('<p>soru</p>') === 0);
  t('JSON olmayan anket dizisi 0 (KÖR değil)', htmlSorulariSay('const SORULAR=[\n {q:"Firman iflas?", b:["a"], k:"x"}\n];') === 0);
  t('BOM\'lu json okunur', dosyaSay('veri/x.json', '﻿[{"soru":"a","siklar":{"A":1},"dogru":"A"}]') === 1);
  t('şifreli json atlanır', dosyaSay('veri/canli/x.enc.json', '[{"soru":"a","siklar":{},"dogru":"A"}]') === 0);
  t('vitrin ücretsiz sayılır', ucretsizMi('kaydir/vitrin/sgs.html') && !ucretsizMi('kaydir/sgs/turkce.html'));
  const tar = { taranan: 5, okunamayan: [], paket: [{ yol: 'a.json', soru: 3 }], ucretsiz: [] };
  t('tabandaki dosya SARI', hukumVer(tar, { acik_dosyalar: ['a.json'] }).hukum === 'SARI');
  t('tabanda olmayan KIRMIZI', hukumVer(tar, { acik_dosyalar: [] }).hukum === 'KIRMIZI');
  t('açık yok YEŞİL', hukumVer({ taranan: 5, okunamayan: [], paket: [], ucretsiz: [] }, null).hukum === 'YEŞİL');
  t('hiç tarama yok KÖR', hukumVer({ taranan: 0, okunamayan: [], paket: [], ucretsiz: [] }, null).hukum === 'KÖR');
  t('kasa modundaki sayfa kabuksa YEŞİL', hukumVer({ taranan: 5, okunamayan: [], paket: [], ucretsiz: [], kasada: ['k/t.html'], kasaModu: ['k/t.html'] }, null).hukum === 'YEŞİL');
  t('kasa modundaki sayfa tam duruyorsa KIRMIZI (tabanda olsa bile)', hukumVer({ taranan: 5, okunamayan: [], paket: [{ yol: 'k/t.html', soru: 3 }], ucretsiz: [], kasada: [], kasaModu: ['k/t.html'] }, { acik_dosyalar: ['k/t.html'] }).hukum === 'KIRMIZI');
  const yay = new Map([['a/kp-01', 'x.html'], ['b/kp-02', 'y.html']]);
  t('kalite: ret yok YEŞİL', kaliteHukmu(yay, [{ etiket: 'c', id: 'kp-01', sinif: 'SIM-YANLIS' }]).hukum === 'YEŞİL');
  t('kalite: kaynak eksik SARI', kaliteHukmu(yay, [{ etiket: 'a', id: 'kp-01', sinif: 'KAYNAK-EKSIK' }]).hukum === 'SARI');
  t('kalite: simülasyon yanlış KIRMIZI', kaliteHukmu(yay, [{ etiket: 'b', id: 'kp-02', sinif: 'SIM-YANLIS' }]).hukum === 'KIRMIZI');
  t('kalite: SORULAR nesneleri çekilir', (htmlSorulariCek('const SORULAR=[{"id":"a/kp-01","soru":"]"}];') || [])[0].id === 'a/kp-01');
  console.log(h ? 'ÖZ-SINAV DÜŞTÜ (' + h + ')' : 'ÖZ-SINAV GEÇTİ');
  return h ? 1 : 0;
}

async function ana() {
  if (process.argv.includes('--sinav')) process.exit(sinav());
  let tarama, taban = null;
  try { tarama = depoyuTara(); } catch (e) { console.log('KÖR: tarama çöktü: ' + e.message); cikti('KÖR'); process.exit(3); }
  try { taban = JSON.parse(fs.readFileSync(TABAN, 'utf8')); } catch (e) { taban = null; }
  tarama.kasaModu = kasaModu();
  if (tarama.kasaModu === null) { console.log('KÖR: arac/kasa-modu.json okunamadı'); cikti('KÖR', 'kasa-modu.json okunamadı'); process.exit(3); }

  if (process.argv.includes('--taban-yaz')) {
    const yeni = { guncelleme: new Date().toISOString().slice(0, 10),
      gerekce: 'BİLİNEN AÇIK: Adım 2 (paket soruları kilitli kasadan servis + depodan/geçmişten çıkarma) bitene kadar. Adım 2 bitince bu liste BOŞALTILIR; yeni dosya eklemek sızıntıyı kabul etmektir, gerekçesiz eklenmez.',
      acik_dosyalar: tarama.paket.map(k => k.yol).sort() };
    fs.writeFileSync(TABAN, JSON.stringify(yeni, null, 2) + '\n');
    console.log('taban yazıldı: ' + yeni.acik_dosyalar.length + ' dosya');
    return;
  }

  if (!process.argv.includes('--canli-yok')) { await canliYokla(tarama.paket); await canliYokla(tarama.ucretsiz); }
  const h = hukumVer(tarama, taban);

  // KALİTE: yayındaki Kaydır-Çöz soruları × veri/ret-kutugu.json
  const yayin = new Map(); let kaliteKor = null;
  try {
    for (const dir of ['kaydir/sgs', 'kaydir/vitrin']) {
      const d = path.join(KOK, dir); if (!fs.existsSync(d)) continue;
      for (const f of fs.readdirSync(d).filter(x => x.endsWith('.html'))) {
        const arr = htmlSorulariCek(fs.readFileSync(path.join(d, f), 'utf8'));
        if (arr === null) { kaliteKor = dir + '/' + f + ' ayrıştırılamadı'; continue; }
        for (const q of arr) if (q && q.id) yayin.set(String(q.id), dir + '/' + f);
      }
    }
  } catch (e) { kaliteKor = e.message; }
  let kalite;
  try { kalite = kaliteHukmu(yayin, JSON.parse(fs.readFileSync(path.join(KOK, 'veri', 'ret-kutugu.json'), 'utf8').replace(/^﻿/, '')).kayitlar); }
  catch (e) { kalite = { hukum: 'KÖR', esles: [] }; kaliteKor = 'ret kütüğü okunamadı: ' + e.message; }
  if (kaliteKor) kalite.hukum = 'KÖR';
  console.log(`KALİTE · ${kalite.hukum} · yayındaki ${yayin.size} soru × ret kütüğü → ${kalite.esles.length} eşleşme${kaliteKor ? ' · ' + kaliteKor : ''}`);
  for (const e of kalite.esles) console.log(`    ${e.risk ? 'CEVAP RİSKİ' : 'yeniden basım'}  ${e.id}  ${e.kapi} ${e.sinif}  (${e.sayfa})`);
  const SIRA = { 'YEŞİL': 0, 'SARI': 1, 'KÖR': 2, 'KIRMIZI': 3 };
  if (SIRA[kalite.hukum] > SIRA[h.hukum]) { h.hukum = kalite.hukum; }
  // Kabuk sayfanın sorusu dosyada değil kasada: kalite taraması onları GÖRMEZ — sessiz geçilmez, yazılır.
  if (tarama.kasada.length) {
    h.neden += ` · kalite taraması kasadaki ${tarama.kasada.length} sayfayı kapsamıyor (${tarama.kasada.join(', ')})`;
    if (h.hukum === 'YEŞİL') h.hukum = 'SARI';
  }
  if (kalite.esles.length) h.neden += ` · kalite: yayında ${kalite.esles.length} ret kayıtlı soru (${kalite.esles.filter(e => e.risk).length} cevap riski)`;
  const topPaket = tarama.paket.reduce((t, k) => t + k.soru, 0);
  const topUcr = tarama.ucretsiz.reduce((t, k) => t + k.soru, 0);
  const canliAcik = tarama.paket.filter(k => k.canli === 200).length;
  // İLERLEME: tabanda olup artık açık olmayan dosya (kasaya geçti ya da silindi). Taban --taban-yaz ile BİLEREK küçültülür.
  const acikSet = new Set(tarama.paket.map(k => k.yol));
  const kapanan = ((taban && taban.acik_dosyalar) || []).filter(y => !acikSet.has(y));

  console.log(`İÇERİK NÖBETÇİSİ · ${h.hukum} · ${h.neden}`);
  console.log(`  taranan dosya ${tarama.taranan} · açık paket içeriği ${tarama.paket.length} dosya / ${topPaket} soru · canlı sitede 200 dönen ${canliAcik}`);
  console.log(`  ücretsiz katman (bilinçli açık) ${tarama.ucretsiz.length} dosya / ${topUcr} soru`);
  console.log(`  KASADA (kabuk) ${tarama.kasada.length} sayfa${tarama.kasada.length ? ': ' + tarama.kasada.join(', ') : ''} · tabandan kapanan ${kapanan.length}${kapanan.length ? ': ' + kapanan.join(', ') : ''}`);
  for (const k of tarama.paket.sort((a, b) => b.soru - a.soru)) console.log(`    PAKET  ${String(k.soru).padStart(5)}  ${k.yol}${k.canli ? '  [canlı ' + k.canli + ']' : ''}`);
  for (const k of tarama.ucretsiz) console.log(`    ÜCRETSİZ ${String(k.soru).padStart(3)}  ${k.yol}${k.canli ? '  [canlı ' + k.canli + ']' : ''}`);

  if (process.env.GITHUB_STEP_SUMMARY) {
    const md = [`### İçerik nöbetçisi: ${h.hukum}`, h.neden, '',
      `açık paket içeriği **${tarama.paket.length} dosya / ${topPaket} soru** (canlıda 200: ${canliAcik}) · ücretsiz katman ${tarama.ucretsiz.length} dosya / ${topUcr} soru`,
      `kasada (kabuk) **${tarama.kasada.length} sayfa** · tabandan kapanan ${kapanan.length}`, '',
      '| tür | soru | dosya | canlı |', '|---|---:|---|---|']
      .concat(tarama.paket.map(k => `| paket | ${k.soru} | ${k.yol} | ${k.canli || ''} |`))
      .concat(tarama.ucretsiz.map(k => `| ücretsiz | ${k.soru} | ${k.yol} | ${k.canli || ''} |`)).join('\n');
    fs.appendFileSync(process.env.GITHUB_STEP_SUMMARY, md + '\n');
    const tip = h.hukum === 'KIRMIZI' || h.hukum === 'KÖR' ? 'error' : (h.hukum === 'SARI' ? 'warning' : 'notice');
    console.log(`::${tip} title=icerik nobeti ${h.hukum}::${h.neden.slice(0, 300)}`);
  }
  cikti(h.hukum, h.neden);
  process.exit(h.hukum === 'KIRMIZI' ? 2 : h.hukum === 'KÖR' ? 3 : 0);
}

function cikti(hukum, neden) {
  if (process.env.GITHUB_OUTPUT) fs.appendFileSync(process.env.GITHUB_OUTPUT, `hukum=${hukum}\nneden=${String(neden || '').replace(/\r?\n/g, ' ').slice(0, 400)}\n`);
}

if (require.main === module) ana();
module.exports = { soruSay, htmlSorulariSay, hukumVer, ucretsizMi };
