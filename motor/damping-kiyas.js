#!/usr/bin/env node
/* ============================================================================
 *  DAMPING KIYAS  —  Ticaret Bakanligi resmi listeleri  <->  veri/gtip-damping.json
 *
 *  NE YAPAR:
 *   1) ticaret.gov.tr sorusturmalar sayfasindan GUNCEL xlsx baglantilarini BULUR
 *      (link dosya adinda tarih tasiyor: "Yururlukteki Onlemler 13.07.2026.xlsx"
 *       -> sabit URL yazmak robotu sessizce eski veriye kilitler).
 *   2) xlsx'i kutuphanesiz okur (zip + sharedStrings; tarayici tarafiyla ayni desen).
 *   3) Sutunlari SIRAYLA DEGIL BASLIK METNIYLE esler  <-- gozetim dersi:
 *      Bakanlik araya sutun eklerse sira kayar, deger yanlis kolondan okunur.
 *   4) (kod, ulke) ciftleri uzerinden bizim ambarla kiyaslar; eksik/fazla/kayma raporlar.
 *
 *  YAZMAZ. Sadece olcer ve rapor uretir -> motor/cikti/damping-kiyas.json
 *  Kullanim:  node motor/damping-kiyas.js  [--yerel <klasor>]
 * ==========================================================================*/
'use strict';
const fs = require('fs'), path = require('path'), zlib = require('zlib');

const KOK = path.resolve(__dirname, '..');
const CIKTI_DIR = path.join(KOK, 'motor', 'cikti');
const SAYFA = 'https://ticaret.gov.tr/ithalat/ticaret-politikasi-savunma-araclari/damping-ve-subvansiyon/sorusturmalar';

const args = process.argv.slice(2);
const yerelIdx = args.indexOf('--yerel');
const YEREL = yerelIdx > -1 ? args[yerelIdx + 1] : null;
const ambarIdx = args.indexOf('--ambar');            // kiyaslanacak json (varsayilan: veri/gtip-damping.json)
const AMBAR = ambarIdx > -1 ? args[ambarIdx + 1] : path.join(KOK, 'veri', 'gtip-damping.json');

/* ---------------------------------------------------------------- yardimci */
const trUp = s => String(s || '').toLocaleUpperCase('tr-TR');
const sadeKod = s => String(s || '').replace(/[^\d]/g, '');
const sadeUlke = s => trUp(s).replace(/\s+/g, ' ').trim();
const norm = s => String(s || '').replace(/\r?\n/g, ' ').replace(/\s+/g, ' ').trim();

/* --------------------------------------------------------- xlsx (zip) okuma */
function zipGirdileri(buf) {
  let eocd = -1;
  for (let i = buf.length - 22; i >= 0; i--) { if (buf.readUInt32LE(i) === 0x06054b50) { eocd = i; break; } }
  if (eocd < 0) throw new Error('zip dizini bulunamadi (dosya xlsx degil olabilir)');
  const adet = buf.readUInt16LE(eocd + 10), cdOff = buf.readUInt32LE(eocd + 16);
  let p = cdOff; const out = {};
  for (let k = 0; k < adet; k++) {
    const yontem = buf.readUInt16LE(p + 10), csize = buf.readUInt32LE(p + 20);
    const nl = buf.readUInt16LE(p + 28), el = buf.readUInt16LE(p + 30), cl = buf.readUInt16LE(p + 32);
    const lho = buf.readUInt32LE(p + 42);
    const ad = buf.toString('utf8', p + 46, p + 46 + nl);
    const lnl = buf.readUInt16LE(lho + 26), lel = buf.readUInt16LE(lho + 28);
    const bas = lho + 30 + lnl + lel;
    const ham = buf.subarray(bas, bas + csize);
    out[ad] = yontem === 0 ? ham : zlib.inflateRawSync(ham);
    p += 46 + nl + el + cl;
  }
  return out;
}
// NOT: ticaret.gov.tr baglantilarda Turkce harfi SAYISAL VARLIK olarak yaziyor (&#252; = u")
// -> sayisal varliklar cozulmezse "Yururlukteki" kalibi hicbir seye uymaz, robot "kaynak yok" der.
const cozXml = s => String(s).replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>')
  .replace(/&quot;/g, '"').replace(/&#39;/g, "'").replace(/&apos;/g, "'")
  .replace(/&#x([0-9a-f]+);/gi, (_, h) => String.fromCodePoint(parseInt(h, 16)))
  .replace(/&#(\d+);/g, (_, d) => String.fromCodePoint(+d));

function paylasilanMetin(z) {
  const out = []; const ss = z['xl/sharedStrings.xml']; if (!ss) return out;
  for (const m of ss.toString('utf8').matchAll(/<si>([\s\S]*?)<\/si>/g))
    out.push(cozXml([...m[1].matchAll(/<t[^>]*>([\s\S]*?)<\/t>/g)].map(x => x[1]).join('')));
  return out;
}
function sayfaDosyalari(z) {           // sayfa ADI -> sheetN.xml  (rels uzerinden, tahminle degil)
  const wb = z['xl/workbook.xml'].toString('utf8');
  const rels = z['xl/_rels/workbook.xml.rels'].toString('utf8');
  const rMap = {};
  for (const m of rels.matchAll(/Id="([^"]+)"[^>]*Target="([^"]+)"/g)) rMap[m[1]] = m[2].replace(/^\/?xl\//, '');
  const out = {};
  for (const m of wb.matchAll(/<sheet[^>]*name="([^"]+)"[^>]*r:id="([^"]+)"/g)) out[cozXml(m[1])] = 'xl/' + rMap[m[2]];
  return out;
}
function satirlar(z, sheetDosya) {
  const shared = paylasilanMetin(z);
  const xml = z[sheetDosya].toString('utf8'); const out = [];
  for (const r of xml.matchAll(/<row[^>]*>([\s\S]*?)<\/row>/g)) {
    const h = {};
    for (const c of r[1].matchAll(/<c r="([A-Z]+)\d+"([^>]*)>([\s\S]*?)<\/c>/g)) {
      const kol = c[1], attr = c[2], ic = c[3];
      const t = (attr.match(/t="([^"]+)"/) || [])[1];
      let v = (ic.match(/<v>([\s\S]*?)<\/v>/) || [])[1];
      if (t === 's') v = shared[+v];
      else if (t === 'inlineStr') v = [...ic.matchAll(/<t[^>]*>([\s\S]*?)<\/t>/g)].map(x => x[1]).join('');
      if (v !== undefined) h[kol] = cozXml(String(v));
    }
    out.push(h);
  }
  return out;
}
/* baslik satirini bul + istenen sutunlari BASLIK METNIYLE esle */
function basliktanSutunlar(rows, istek) {
  for (let i = 0; i < Math.min(rows.length, 30); i++) {
    const r = rows[i];
    const degerler = Object.entries(r).map(([k, v]) => [k, trUp(norm(v))]);
    if (!degerler.some(([, v]) => /G\.?T\.?İ\.?P|CN CODE/.test(v))) continue;
    const map = {};
    for (const [ad, kaliplar] of Object.entries(istek)) {
      for (const [kol, metin] of degerler) {
        if (map[ad]) continue;
        if (kaliplar.some(k => metin.includes(k))) map[ad] = kol;
      }
    }
    return { baslikSatiri: i, sutun: map };
  }
  return null;
}
const seriTarih = s => {                                   // Excel seri no -> YYYY-AA-GG
  const n = Number(s);
  if (!isFinite(n) || n < 20000 || n > 90000) return null;
  return new Date(Date.UTC(1899, 11, 30) + n * 86400000).toISOString().slice(0, 10);
};

/* ------------------------------------------------------------- indirme ucu */
async function metinAl(url) {
  const r = await fetch(url, { headers: { 'user-agent': 'Mozilla/5.0 tetikte-kiyas' } });
  if (!r.ok) throw new Error(`${url} -> HTTP ${r.status}`);
  return await r.text();
}
async function dosyaAl(url) {
  const r = await fetch(url, { headers: { 'user-agent': 'Mozilla/5.0 tetikte-kiyas' } });
  if (!r.ok) throw new Error(`${url} -> HTTP ${r.status}`);
  return Buffer.from(await r.arrayBuffer());
}
function baglantiBul(html, kalip) {
  const bulunan = [];
  for (const m of html.matchAll(/href="([^"]+\.xlsx?)"/gi)) {
    let u = cozXml(m[1]);                                  // once varliklar cozulur
    if (!u.startsWith('http')) u = 'https://ticaret.gov.tr' + (u.startsWith('/') ? '' : '/') + u;
    let okunur = u; try { okunur = decodeURIComponent(u); } catch { }
    if (kalip.test(okunur)) bulunan.push(encodeURI(okunur)); // bosluklu ad -> gecerli URL
  }
  return [...new Set(bulunan)];
}

/* ==================================================================== ANA */
(async () => {
  // NOT: rapora ZAMAN DAMGASI konmaz. Depo kurali (CLAUDE.md): zaman alani tasiyan
  // rapor, sonuc hic degismese bile her kosuda "degismis" gorunur -> bos commit +
  // kapanis denetiminde gurultu. Ne zaman kosuldugunu commit tarihi zaten soyler.
  const rapor = { kaynak: {}, ozet: {}, bulgular: [] };

  /* 1) kaynak dosyalari: yerel klasor ya da canli kesif */
  let onlemBuf, sorusturmaBuf, onlemUrl = null, sorusturmaUrl = null;
  if (YEREL) {
    onlemBuf = fs.readFileSync(path.join(YEREL, 'yururlukteki.xlsx'));
    sorusturmaBuf = fs.readFileSync(path.join(YEREL, 'yurutulen.xlsx'));
    onlemUrl = sorusturmaUrl = '(yerel dosya)';
  } else {
    const html = await metinAl(SAYFA);
    const onlemler = baglantiBul(html, /Y[üu]r[üu]rl[üu]kteki/i);
    const yurutulen = baglantiBul(html, /Y[üu]r[üu]t[üu]len/i);
    if (!onlemler.length || !yurutulen.length)
      throw new Error(`KAYNAK BULUNAMADI — sayfada beklenen xlsx baglantisi yok (onlem:${onlemler.length}, sorusturma:${yurutulen.length}). Bakanlik sayfayi degistirmis olabilir.`);
    onlemUrl = onlemler[0]; sorusturmaUrl = yurutulen[0];
    onlemBuf = await dosyaAl(onlemUrl);
    sorusturmaBuf = await dosyaAl(sorusturmaUrl);
  }
  rapor.kaynak = { onlemUrl: decodeURIComponent(onlemUrl), sorusturmaUrl: decodeURIComponent(sorusturmaUrl) };

  /* 2) YURURLUKTEKI ONLEMLER — kesin + gecici */
  const zO = zipGirdileri(onlemBuf);
  const sayfalarO = sayfaDosyalari(zO);
  rapor.kaynak.onlemSayfalari = Object.keys(sayfalarO);

  const ISTEK = {
    dosya: ['DOSYA NO'], urun: ['MADDE İSMİ', 'COMMODITY'], gtip: ['G.T.İ.P', 'CN CODE'],
    ulke: ['ÜLKE', 'COUNTRY'], teblig: ['ÖNLEM TEBLİĞ NO', 'TEBLİĞ NO'],
    oran: ['ÖNLEM ORANI'], tur: ['ÖNLEM TÜRÜ'], dolum: ['DOLUM TARİHİ'],
  };

  const bakanlik = [];                       // {kod, ulke, urun, oran, tur, dolum, kaynak}
  const sutunKaydi = {};
  for (const [ad, dosya] of Object.entries(sayfalarO)) {
    if (!/Kesin|Geçici|Gecici|Definitive|Prov/i.test(ad)) continue;
    const rows = satirlar(zO, dosya);
    const bas = basliktanSutunlar(rows, ISTEK);
    if (!bas) { rapor.bulgular.push(`UYARI: "${ad}" sayfasinda baslik satiri bulunamadi, atlandi.`); continue; }
    sutunKaydi[ad] = bas.sutun;
    const tip = /Kesin|Definitive/i.test(ad) ? 'Kesin' : 'Gecici';
    for (const r of rows.slice(bas.baslikSatiri + 1)) {
      const gtipHam = norm(r[bas.sutun.gtip]), ulke = norm(r[bas.sutun.ulke]);
      if (!gtipHam || !ulke) continue;
      if (/G\.?T\.?İ\.?P|ÜLKE/i.test(gtipHam)) continue;
      const kodlar = [];
      for (const tok of gtipHam.split(/\s+/)) {
        const t = tok.replace(/[^\d.]/g, '').replace(/^\.+|\.+$/g, '');
        if (/^\d{2,4}(\.\d{2}){0,4}$/.test(t)) kodlar.push(sadeKod(t));
      }
      if (!kodlar.length) continue;
      bakanlik.push({
        kodlar, ulke, urun: norm(r[bas.sutun.urun]),
        oran: norm(r[bas.sutun.oran]), tur: norm(r[bas.sutun.tur]),
        dolum: seriTarih(r[bas.sutun.dolum]), dolumHam: norm(r[bas.sutun.dolum]),
        dosya: norm(r[bas.sutun.dosya]), sayfa: tip,
      });
    }
  }
  rapor.kaynak.sutunEslesmesi = sutunKaydi;

  /* 3) BIZIM AMBAR */
  // PowerShell'in Out-File -Encoding utf8'i BOM yazar; Node'da JSON.parse patlar (tarayici BOM'u atar).
  const bizimHam = JSON.parse(fs.readFileSync(AMBAR, 'utf8').replace(/^﻿/, ''));
  rapor.kaynak.ambar = AMBAR;
  const bizim = bizimHam.map(x => ({ kodlar: String(x.k || '').split(/\s+/).filter(Boolean), ulke: norm(x.u), urun: norm(x.m), oran: norm(x.o), tur: norm(x.t), tip: x.tur }));

  /* 4) (kod, ulke) ciftleri */
  const cift = (k, u) => `${k}|${sadeUlke(u)}`;
  const bSet = new Map(), aSet = new Map();
  for (const r of bakanlik) for (const k of r.kodlar) if (!bSet.has(cift(k, r.ulke))) bSet.set(cift(k, r.ulke), r);
  for (const r of bizim) for (const k of r.kodlar) if (!aSet.has(cift(k, r.ulke))) aSet.set(cift(k, r.ulke), r);

  const eksik = [...bSet.keys()].filter(k => !aSet.has(k));       // Bakanlik'ta var, bizde YOK
  const fazla = [...aSet.keys()].filter(k => !bSet.has(k));       // bizde var, Bakanlik'ta YOK

  /* 5) SUTUN KAYMASI DENETIMI — oran alani bos ama tur alani rakam/isaret tasiyorsa kayma vardir */
  const oranBos = bizim.filter(x => !x.oran).length;
  const turdeOran = bizim.filter(x => /[%$€]|\d/.test(x.tur)).length;

  /* 6) YURUTULEN SORUSTURMALAR (devam edenler) */
  const zS = zipGirdileri(sorusturmaBuf);
  const sayfalarS = sayfaDosyalari(zS);
  const sorusturmalar = [];
  for (const [ad, dosya] of Object.entries(sayfalarS)) {
    const rows = satirlar(zS, dosya);
    const bas = basliktanSutunlar(rows, { ...ISTEK, tur: ['SORUŞTURMA TÜRÜ', 'INVESTIGATION TYPE'] });
    if (!bas) continue;
    for (const r of rows.slice(bas.baslikSatiri + 1)) {
      const gtipHam = norm(r[bas.sutun.gtip]), ulke = norm(r[bas.sutun.ulke]);
      if (!gtipHam || !ulke || /CN CODE|COUNTRY|G\.?T\.?İ\.?P/i.test(gtipHam)) continue;
      const kodlar = gtipHam.split(/\s+/).map(t => t.replace(/[^\d.]/g, '').replace(/^\.+|\.+$/g, ''))
        .filter(t => /^\d{2,4}(\.\d{2}){0,4}$/.test(t)).map(sadeKod);
      if (!kodlar.length) continue;
      sorusturmalar.push({ sayfa: ad, kodlar, ulke, urun: norm(r[bas.sutun.urun]), tur: norm(r[bas.sutun.tur]), dosya: norm(r[bas.sutun.dosya]) });
    }
  }

  /* 6b) SORUSTURMA AMBARI da kiyaslanir (veri/damping-sorusturma.json)
         Onlem listesi gibi bu da sessizce yarim kalabilir; kapi ayni. */
  const sorusturmaYolu = path.join(KOK, 'veri', 'damping-sorusturma.json');
  let sorusturmaEksik = null, sorusturmaFazla = null, ambarSorusturma = 0;
  if (fs.existsSync(sorusturmaYolu)) {
    const amb = JSON.parse(fs.readFileSync(sorusturmaYolu, 'utf8').replace(/^﻿/, ''));
    ambarSorusturma = amb.length;
    const bakSet = new Set(), ambSet = new Set();
    for (const r of sorusturmalar) for (const k of r.kodlar) bakSet.add(cift(k, r.ulke));
    for (const r of amb) for (const k of String(r.k || '').split(/\s+/).filter(Boolean)) ambSet.add(cift(k, r.u));
    sorusturmaEksik = [...bakSet].filter(k => !ambSet.has(k)).length;
    sorusturmaFazla = [...ambSet].filter(k => !bakSet.has(k)).length;
  }

  /* 7) SURE DOLUMU PENCERESI */
  const bugun = new Date().toISOString().slice(0, 10);
  const birYilSonra = new Date(Date.now() + 365 * 86400000).toISOString().slice(0, 10);
  const dolumOkunan = bakanlik.filter(r => r.dolum);
  const pencere = dolumOkunan.filter(r => r.dolum >= bugun && r.dolum <= birYilSonra).sort((a, b) => a.dolum < b.dolum ? -1 : 1);

  /* ------------------------------------------------------------------ RAPOR */
  // eksiklerin cinsi: pozisyon duzeyi (4-6 hane) mi, tam 12 haneli kod mu?
  const uzunlukDagilimi = (liste) => liste.reduce((a, k) => { const n = k.split('|')[0].length; a[n] = (a[n] || 0) + 1; return a; }, {});
  const sayfaDagilimi = bakanlik.reduce((a, r) => { a[r.sayfa] = (a[r.sayfa] || 0) + 1; return a; }, {});
  const bizimTur = bizim.reduce((a, r) => { a[r.tip || '?'] = (a[r.tip || '?'] || 0) + 1; return a; }, {});

  rapor.ozet = {
    bakanlik_satir: bakanlik.length,
    bakanlik_sayfa_dagilimi: sayfaDagilimi,
    bizim_tur_dagilimi: bizimTur,
    eksik_kod_uzunlugu: uzunlukDagilimi(eksik),
    bakanlik_kod_ulke_cifti: bSet.size,
    bakanlik_urun: new Set(bakanlik.map(r => r.urun)).size,
    bizim_kayit: bizim.length,
    bizim_kod_ulke_cifti: aSet.size,
    EKSIK_cift: eksik.length,
    FAZLA_cift: fazla.length,
    bizde_oran_alani_bos: oranBos,
    bizde_tur_alaninda_rakam: turdeOran,
    devam_eden_sorusturma_satir: sorusturmalar.length,
    sorusturma_ambar_kayit: ambarSorusturma,
    SORUSTURMA_EKSIK: sorusturmaEksik,     // null = ambar dosyasi yok (henuz kurulmamis)
    SORUSTURMA_FAZLA: sorusturmaFazla,
    dolum_tarihi_okunan: dolumOkunan.length,
    dolum_okunamayan: bakanlik.length - dolumOkunan.length,
    on_iki_ayda_dolacak: pencere.length,
  };
  rapor.eksikTam = eksik.map(k => { const r = bSet.get(k); return { kod: k.split('|')[0], ulke: r.ulke, urun: r.urun, oran: r.oran, sayfa: r.sayfa }; });
  rapor.eksikOrnek = rapor.eksikTam.slice(0, 40);
  rapor.fazlaOrnek = fazla.slice(0, 40).map(k => { const r = aSet.get(k); return { kod: k.split('|')[0], ulke: r.ulke, urun: r.urun }; });
  rapor.pencere = pencere.map(r => ({ dolum: r.dolum, urun: r.urun, ulke: r.ulke, kodlar: r.kodlar, oran: r.oran }));
  rapor.devamEden = sorusturmalar.map(r => ({ urun: r.urun, ulke: r.ulke, tur: r.tur, kodlar: r.kodlar, dosya: r.dosya }));

  fs.mkdirSync(CIKTI_DIR, { recursive: true });
  fs.writeFileSync(path.join(CIKTI_DIR, 'damping-kiyas.json'), JSON.stringify(rapor, null, 1), 'utf8');

  /* ---------------------------------------------------------------- konsol */
  const y = rapor.ozet;
  console.log('=== DAMPING KIYAS ===');
  console.log('kaynak (onlem)      :', rapor.kaynak.onlemUrl);
  console.log('kaynak (sorusturma) :', rapor.kaynak.sorusturmaUrl);
  console.log('sutun eslesmesi     :', JSON.stringify(sutunKaydi));
  console.log('');
  console.log(`Bakanlik : ${y.bakanlik_satir} satir | ${y.bakanlik_kod_ulke_cifti} (kod,ulke) cifti | ${y.bakanlik_urun} urun | sayfa: ${JSON.stringify(y.bakanlik_sayfa_dagilimi)}`);
  console.log(`Bizim    : ${y.bizim_kayit} kayit  | ${y.bizim_kod_ulke_cifti} (kod,ulke) cifti | tur: ${JSON.stringify(y.bizim_tur_dagilimi)}`);
  console.log(`Eksik kod uzunlugu (hane -> adet) : ${JSON.stringify(y.eksik_kod_uzunlugu)}`);
  console.log(`EKSIK (Bakanlikta var, bizde yok) : ${y.EKSIK_cift}`);
  console.log(`FAZLA (bizde var, Bakanlikta yok) : ${y.FAZLA_cift}`);
  console.log(`Sutun kaymasi izi : oran alani bos ${y.bizde_oran_alani_bos}/${y.bizim_kayit} · tur alaninda rakam ${y.bizde_tur_alaninda_rakam}/${y.bizim_kayit}`);
  console.log(`Devam eden sorusturma satiri : ${y.devam_eden_sorusturma_satir}` +
    (y.SORUSTURMA_EKSIK === null ? '  (ambar dosyasi YOK)' : `  · ambar ${y.sorusturma_ambar_kayit} kayit · EKSIK ${y.SORUSTURMA_EKSIK} / FAZLA ${y.SORUSTURMA_FAZLA}`));
  console.log(`Sure dolumu : okunan ${y.dolum_tarihi_okunan}, okunamayan ${y.dolum_okunamayan}, 12 ayda dolacak ${y.on_iki_ayda_dolacak}`);
  console.log('\n--- EKSIK ilk 15 ---');
  rapor.eksikOrnek.slice(0, 15).forEach(r => console.log(`  ${r.kod} | ${r.ulke} | ${r.urun} [${r.sayfa}]`));
  console.log('\n--- FAZLA ilk 15 ---');
  rapor.fazlaOrnek.slice(0, 15).forEach(r => console.log(`  ${r.kod} | ${r.ulke} | ${r.urun}`));
  console.log('\nRapor -> motor/cikti/damping-kiyas.json');
})().catch(e => { console.error('KIRMIZI:', e.message); process.exit(1); });
