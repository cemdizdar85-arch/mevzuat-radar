#!/usr/bin/env node
// ============================================================================
//  KAPI-BP — BDS PARAGRAF ATFI KAPISI (30.09.2026, Cem "1.2.3 üçünü de yap")
//  Öğrenciye görünen alanlarda geçen "BDS 500 p.A27" / "BDS 500 A27 paragrafı" atfını ambardaki GÜNCEL paragraf başlığıyla sınar:
//    BP-YOK   : atfedilen paragraf o standartta yok (ör. BDS 500 A90)
//    BP-KONU  : atfın geçtiği cümle BAŞKA bir paragrafın konusunu adıyla anıyor, atfedilen paragrafın konusunu anmıyor
//               (ör. "güvenilirlik ... BDS 500 A27" — güncel A27 Sorgulama, güvenilirlik A35–A38)
//  ÖLÇÜLDÜ (30.09 SGS sözel örneklem): BDS 500'de eski numaralar güncel metinde 4 ileri kaymış (A25→A29 … A31→A35);
//    156 soruluk örneklemde 7 denetim sorusu eski numaraya atıf yapıyordu, hükmün kendisi doğruydu.
//  Başlık listesi: veri/sinav/bds-paragraf-basliklari.json (ambardan: node arac/bds-atif-kapisi.js --tazele; SUPABASE_SERVICE_KEY).
//  🚫 GÖRMEZ: başlığı bilgi taşımayan paragraf ("BDS 315, 16 ncı paragraf", "Kapsam", "Giriş") — hüküm verilmez ·
//     konusu cümlede adıyla geçmeyen yanlış atıf · aralık atfının ("A25–A31") iç paragrafları · BDS dışı standart (TMS/TFRS/ISA) ·
//     başlık doğru ama paragraf içeriği iddiayı taşımıyor.
//  Kullanım: node arac/bds-atif-kapisi.js --sinav | --tazele | --banka <sgs|smmm|kgk> [cikti.json]
// ============================================================================
'use strict';
const fs = require('fs'), path = require('path');
const KOK = path.resolve(__dirname, '..');
const LISTE = path.join(KOK, 'veri', 'sinav', 'bds-paragraf-basliklari.json');
const MODEL = new Set(['hakem', 'hakem2', 'kor_cozum', 'simulasyon_sonnet', 'kaynak_metin_ozet', 'kaynak_adlar', 'capa_metin', 'capa_kaynak', 'atif_genisletme', 'mukerrer', 'aciklama_hakem']);
// Başlıkta konu taşımayan kökler (her BDS'de geçer) — konu anahtarından çıkarılır
const GENEL = new Set(['denet', 'kanit', 'prose', 'bilgi', 'genel', 'ilisk', 'uygul', 'gerek', 'bagim', 'hakki', 'kapsa', 'yurur', 'giris', 'tanim', 'amac', 'amaci', 'parag', 'nolu', 'bkz']);

// Tek başına konu bildirmeyen kökler: başlık anahtarı yalnız bunlardan biriyse ve cümlede geçiyorsa "başka konu" sayılmaz
//   (30.09 SGS banka ölçümü: "rapor" 24+, "sorum" 31, "yeter" 9 bulgu — hepsi genel sözcük)
const TEKIL_GENEL = new Set(['rapor', 'sorum', 'yeter', 'riski', 'deger', 'adres', 'imzas', 'kayna', 'ornek', 'belge', 'diger', 'gorus', 'durum', 'yonet', 'islem', 'iletis', 'ileti']);
const katla = s => String(s || '').toLocaleLowerCase('tr-TR').replace(/[çğıöşüâîû]/g, c => ({ ç: 'c', ğ: 'g', ı: 'i', ö: 'o', ş: 's', ü: 'u', â: 'a', î: 'i', û: 'u' }[c])).replace(/[^a-z0-9]+/g, ' ').trim();
const koklar = s => katla(s).split(' ').filter(w => w.length >= 4 && !/^\d/.test(w)).map(w => w.slice(0, 5));
function anahtar(baslik) {
  if (/^BDS\s*\d+\s*,|parag|Bkz|^\s*(Giriş|Kapsam|Yürürlük|Tanımlar|Amaç)/i.test(baslik)) return [];
  return koklar(baslik).filter(k => !GENEL.has(k)).slice(0, 2);
}

let LST = null, GOVDE = {}, GOMULU = {};
function liste() {
  if (LST) return LST;
  const j = fs.existsSync(LISTE) ? JSON.parse(fs.readFileSync(LISTE, 'utf8')) : {};
  LST = j.standartlar || {}; GOVDE = j.govde || {}; GOMULU = j.gomulu || {}; return LST;
}

function metinleri(o, p, out) {
  if (o == null) return out;
  if (typeof o === 'string') { out.push([p, o]); return out; }
  if (typeof o === 'object') for (const [k, v] of Object.entries(o)) { if (!p && MODEL.has(k)) continue; metinleri(v, p ? p + '.' + k : k, out); }
  return out;
}

// "BDS 500 p.A27", "BDS 500 A27", "BDS 500'ün A27 paragrafı", "BDS 500 paragraf 7", "BDS 500 p.7". Aralık "A25–A31" → yalnız ilk uç.
const ATIF = /BDS\s*(\d{3})\b([^.;:\n]{0,22}?)(?:\bp\.\s*|\bparagraf(?:[ıi])?\s*|(?=A\d))(A?\d{1,3})(?![\d/])/g;

function kusurlar(soru) {
  const L = liste(); if (!Object.keys(L).length) return [{ tur: 'BP-KOR', std: '', par: '', alan: '', not: 'başlık listesi yok' }];
  const out = []; const gor = new Set();
  for (const [alan, t] of metinleri(soru, '', [])) {
    let m; ATIF.lastIndex = 0;
    while ((m = ATIF.exec(t))) {
      // 30.09 yargı: "BDS 315 ve BDS 520 p.5" → p.5 ilk standarda bağlanıyordu; arada başka "BDS" varsa ondan yeniden dene
      if (/BDS/i.test(m[2])) { ATIF.lastIndex = m.index + 3; continue; }
      const std = m[1], par = m[3], S = L[std]; if (!S) continue;            // standart ambarda yoksa hüküm yok
      const anah = alan + std + par; if (gor.has(anah)) continue; gor.add(anah);
      // 30.09 yargı: BDS 500 p.11 ambarda ayrı kayıt değil, p.10'un gövdesine gömülü → paragraf var sayılır
      if (!S[par] && (GOMULU[std] || []).includes(par)) continue;
      if (!S[par]) { out.push({ tur: 'BP-YOK', std, par, alan, not: 'BDS ' + std + ' ' + par + ' yok' }); continue; }
      const kp = anahtar(S[par]);   // başlık bilgi taşımıyorsa kp=[] → aşağıdaki var_(kp) true → hüküm yok
      // atfın geçtiği cümle
      const bas = Math.max(t.lastIndexOf('.', m.index - 1), t.lastIndexOf(';', m.index - 1), t.lastIndexOf('\n', m.index - 1)) + 1;
      let son = t.slice(m.index + m[0].length).search(/[.;\n]/); son = son < 0 ? t.length : m.index + m[0].length + son;
      const cumle = koklar(t.slice(bas, son));
      const var_ = k => k.every(x => cumle.includes(x));
      if (var_(kp)) continue;                                                  // atfedilen konu cümlede → uyumlu
      // 30.09 ilk banka ölçümü: tüm standart başlıklarıyla kıyas 254 soru/807 bulgu verdi, çoğu genel başlık ("Temel Kavramlar",
      //   "rapor", "kaynak") → yalnız KOMŞU paragraflar (aynı tür A/ana metin, ±8 numara) kıyaslanır: numara kayması imzası budur.
      const tip = par[0] === 'A' ? 'A' : '', no = parseInt(par.replace('A', ''), 10);
      const komsu = Object.entries(S).filter(([p]) => (p[0] === 'A' ? 'A' : '') === tip && p !== par && Math.abs(parseInt(p.replace('A', ''), 10) - no) <= 8).map(([, b]) => b);
      const baska = [...new Set(komsu.map(anahtar).filter(k => k.length && k.join() !== kp.join() && !k.every(x => kp.includes(x))).map(k => k.join(' ')))]
        .filter(k => var_(k.split(' ')))
        .filter(k => k.includes(' ') || !TEKIL_GENEL.has(k));   // tek kökte genel sözcük ("rapor", "sorum") konu sayılmaz (30.09 banka ölçümü)
      if (!baska.length) continue;
      // 30.09 yargı (60 bulgu, resmî metinle): yanlış alarmların ~25/29'unda atfedilen paragrafın GÖVDESİ cümlenin konusunu taşıyordu
      //   (başlık blok başlığı: "Temel Kavramlar", "Mevzuatta Öngörülen Denetçi Raporu"). Gövde konuyu taşıyorsa ZAYIF (durdurmaz).
      const govde = (GOVDE[std] && GOVDE[std][par] || '').split(' ');
      const zayif = baska[0].split(' ').every(x => govde.includes(x));
      out.push({ tur: zayif ? 'BP-ZAYIF' : 'BP-KONU', std, par, alan, not: 'cümle "' + baska[0] + '" diyor; ' + par + ' = ' + S[par].slice(0, 50) });
    }
  }
  return out;
}

async function tazele() {
  const Kk = process.env.SUPABASE_SERVICE_KEY; if (!Kk) { console.error('SUPABASE_SERVICE_KEY yok'); process.exit(2); }
  const satir = [];
  for (let o = 0; ; o += 500) {
    const r = await fetch('https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar?select=kaynak_ad,metin&order=kaynak_ad.asc&kaynak_ad=like.' + encodeURIComponent('BDS %') + '&limit=500&offset=' + o,
      { headers: { apikey: Kk, Authorization: 'Bearer ' + Kk, 'User-Agent': 'mevzuat-radar-robot/1.0' } });
    const j = await r.json(); if (!Array.isArray(j)) { console.error('ambar okunamadı'); process.exit(2); }
    satir.push(...j); if (j.length < 500) break;
  }
  const S = {}, G = {}, GM = {};
  for (const x of satir) {
    const m = x.kaynak_ad.match(/^BDS (\d{3}) p\.(A?\d{1,3})[a-z]?\s*-\s*(.*?)(\s*\[\d+\/\d+\])?$/); if (!m) continue;   // Ek paragrafları (BDS 210 Ek 1 …) alınmaz
    const [, std, par, bas] = m;
    (S[std] = S[std] || {})[par] = bas.trim();
    // gövde yalnız KÖK kümesi olarak tutulur (depo public; metnin kendisi yazılmaz). Parçalı kayıtlar ([2/3]) birleşir.
    const g = G[std] = G[std] || {}; g[par] = [...new Set(((g[par] || '') + ' ' + koklar(x.metin).join(' ')).trim().split(' '))].join(' ');
    // gömülü paragraf: p.N gövdesinde satır başı "N+1." / "N+2." ile başlayan ayrı paragraf (30.09: BDS 500 p.11, p.10'un içinde)
    const tip = par[0] === 'A' ? 'A' : '', no = parseInt(par.replace('A', ''), 10);
    for (const d of [1, 2]) { const hedef = tip + (no + d); const re = new RegExp('(^|\\s)' + hedef + '\\.\\s+[A-ZÇĞİÖŞÜ]'); if (re.test(String(x.metin || ''))) (GM[std] = GM[std] || []).push(hedef); }
  }
  for (const std of Object.keys(GM)) GM[std] = [...new Set(GM[std])].filter(p => !S[std][p]);
  const n = Object.values(S).reduce((a, b) => a + Object.keys(b).length, 0);
  if (n < 2000) { console.error('paragraf sayısı ' + n + ' < 2000 — liste yazılmadı'); process.exit(2); }
  fs.writeFileSync(LISTE, JSON.stringify({ aciklama: 'BDS güncel paragraf başlıkları + gövde kök kümesi + gömülü paragraflar (ambar dokumanlar). Üretici: node arac/bds-atif-kapisi.js --tazele. Elle düzenlenmez.', olcum: new Date().toISOString().slice(0, 10), standartlar: S, gomulu: GM, govde: G }));
  console.log('BDS başlık listesi: ' + Object.keys(S).length + ' standart · ' + n + ' paragraf · gömülü ' + Object.values(GM).reduce((a, b) => a + b.length, 0));
}

function banka(sinav, cikti) {
  const d = path.join(KOK, 'veri', 'sinav', 'kaydir-secim'); const ids = new Set();
  for (const f of fs.readdirSync(d).filter(f => new RegExp('^(yayin|vitrin)-' + sinav + '-').test(f))) for (const r of JSON.parse(fs.readFileSync(path.join(d, f), 'utf8').replace(/^﻿/, ''))) if (r.etiket && r.id) ids.add(r.etiket + '/' + r.id);
  const partiler = {}; let okunan = 0; const sonuc = [];
  for (const id of ids) {
    const [e, kp] = id.split('/'); const pf = path.join(KOK, 'veri', 'fabrika', 'kalip-parti-' + e + '.json');
    if (!(e in partiler)) partiler[e] = fs.existsSync(pf) ? JSON.parse(fs.readFileSync(pf, 'utf8').replace(/^﻿/, '')) : null;
    const k = partiler[e] && partiler[e][kp]; if (!k) continue; okunan++;
    const b = kusurlar(k); if (b.length) sonuc.push({ anahtar: id, kusurlar: b });
  }
  const tur = {}; for (const s of sonuc) for (const b of s.kusurlar) tur[b.tur] = (tur[b.tur] || 0) + 1;
  console.log(`KAPI-BP banka (${sinav}): yayında ${ids.size} · okunan ${okunan} · bulgulu soru ${sonuc.length} · ${JSON.stringify(tur)}`);
  if (cikti) fs.writeFileSync(cikti, JSON.stringify(sonuc, null, 1));
}

function sinav() {
  LST = { '500': { 'A25': 'Analitik Prosedürler', 'A26': 'Sorgulama', 'A27': 'Sorgulama', 'A31': 'İhtiyaca Uygunluk', 'A35': 'Güvenilirlik', 'A6': 'BDS 315, 16 ncı paragraf', '7': 'İhtiyaca Uygunluk ve Güvenilirlik' },
          '705': { '2': 'Kapsam', '7': 'Olumlu Görüşten Farklı Görüş Türleri' },
          '700': { '20': 'Denetçinin Görüşü', '21': 'Rapor' } };
  LST['500']['A12'] = 'Analitik İnceleme';   // A35'e 23 uzak: komşu değil
  LST['315'] = { '5': 'Temel Kavramlar', '8': 'Risk Değerlendirme Prosedürleri' };
  GOVDE = { '315': { '5': 'yapis risk kontr deger ayrı' } }; GOMULU = { '500': ['11'] };
  const V = [
    ['eski numara: güvenilirlik → A27 (Sorgulama)', { aciklama: { A: 'Dış kaynaklı kanıtın güvenilirliği BDS 500 A27 paragrafında düzenlenir.' } }, 'BP-KONU'],
    ['eski numara, "p." biçimi', { adimlar: [{ anlatim: 'İhtiyaca uygunluk için BDS 500 p.A26 esas alınır.' }] }, 'BP-KONU'],
    ['olmayan paragraf', { dayanak: 'BDS 500 p.A90' }, 'BP-YOK'],
    ['doğru atıf → temiz (güvenilirlik A35)', { aciklama: { B: 'Kanıtın güvenilirliği BDS 500 A35 paragrafında düzenlenir.' } }, null],
    ['doğru atıf → temiz (sorgulama A26)', { teshis: { C: 'Sorgulama tek başına yeterli değildir (BDS 500 p.A26).' } }, null],
    ['konusuz cümle → temiz (hüküm yok)', { hap: 'Bkz. BDS 500 A27.' }, null],
    ['bilgi taşımayan başlık → temiz (A6)', { aciklama: { A: 'Güvenilirlik konusu için BDS 500 A6.' } }, null],
    ['başka cümledeki konu karışmaz', { aciklama: { A: 'Güvenilirlik önemlidir. Sorgulama BDS 500 A27 paragrafındadır.' } }, null],
    ['doğru konu + komşu konu birlikte → temiz (sorgulama + güvenilirlik A35)', { aciklama: { A: 'Sorgulama ile elde edilen kanıtın güvenilirliği BDS 500 A35 paragrafındadır.' } }, null],
    ['ana metin atfı A-paragrafıyla kıyaslanmaz (p.7 ↔ A12)', { aciklama: { A: 'Analitik incelemede BDS 500 p.7 esas alınır.' } }, null],
    ['standart listede yok → hüküm yok', { dayanak: 'BDS 999 p.A5 güvenilirlik' }, null],
    ['ana metin paragrafı (p.7) konu uyumlu → temiz', { aciklama: { D: 'İhtiyaca uygunluk ve güvenilirlik BDS 500 p.7 ile değerlendirilir.' } }, null],
    ['uzak paragrafın konusu sayılmaz (analitik ↔ A35, 23 uzak)', { aciklama: { A: 'Analitik incelemede de BDS 500 A35 dikkate alınır.' } }, null],
    ['tek genel sözcük konu sayılmaz ("rapor" ↔ 700 p.20)', { aciklama: { A: 'Rapor BDS 700 p.20 uyarınca imzalanır.' } }, null],
    ['gövde konuyu taşıyor → ZAYIF (315 p.5 "risk değerlendirme")', { aciklama: { A: 'Risk değerlendirmesi BDS 315 p.5 uyarınca yapılır.' } }, 'BP-ZAYIF'],
    ['gömülü paragraf var sayılır (BDS 500 p.11)', { dayanak: 'BDS 500 p.11' }, null],
    ['arada başka BDS → doğru standarda bağlanır', { aciklama: { A: 'BDS 700 ve BDS 500 A35 güvenilirlik hükmü.' } }, null],
    ['arada başka BDS → ikinci atıf yine denetlenir', { aciklama: { A: 'BDS 700 ile BDS 500 A27 güvenilirlik hükmü.' } }, 'BP-KONU'],
    ['model alanı taranmaz', { hakem: { gerekce: 'güvenilirlik BDS 500 A27' } }, null],
  ];
  let ok = 0;
  for (const [ad, soru, bek] of V) {
    const b = kusurlar(soru); const g = b.length ? b[0].tur : null; const tamam = g === bek;
    if (tamam) ok++; console.log((tamam ? '  ✓ ' : '  ✗ ') + ad + (tamam ? '' : ' → ' + JSON.stringify(b)));
  }
  console.log(ok === V.length ? `KAPI-BP ÖZ-SINAVI YEŞİL (${ok}/${V.length})` : `KAPI-BP ÖZ-SINAVI KIRMIZI (${ok}/${V.length})`);
  process.exit(ok === V.length ? 0 : 1);
}

module.exports = { kusurlar };
if (require.main === module) {
  const [a, b, c] = process.argv.slice(2);
  if (a === '--sinav') sinav();
  else if (a === '--tazele') tazele();
  else if (a === '--banka') banka(b || 'sgs', c);
  else { console.log('--sinav | --tazele | --banka <sgs|smmm|kgk> [cikti.json]'); process.exit(2); }
}
