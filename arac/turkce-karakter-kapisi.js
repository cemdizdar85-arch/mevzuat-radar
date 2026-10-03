#!/usr/bin/env node
// ============================================================================
//  KAPI-TR — TÜRKÇE KARAKTERSİZ (ASCII) AÇIKLAMA KAPISI (03.10.2026, Cem "bütün çıkan hataları kural yaz") · 0 USD
//  Neden: 02–03.10 elle okumada sitedeki SGS + bitirme sorularının açıklama katmanında Türkçe harfsiz yazılmış metin bulundu
//  ("ayni", "ogrenci", "dusunuyorsun"). Yayındaki TurkceOnar bunları TAHMİNLE düzeltiyor ve yanlış harf üretiyor
//  ("sık"/"şık", "dogru"→?); kökü üretimdedir. Bu kapı ASCII yazılmış Türkçe dizeyi üretimde yakalar.
//    TR-ASCII : görünen açıklama alanında ≥ 60 karakterlik dize · hiç ç ğ ı ö ş ü Ç Ğ İ Ö Ş Ü yok · en az 2 Türkçe işlev/işaret
//               sözcüğü (ve, bir, bu, icin, ile, olarak, degil, ogrenci, dogru …) · İngilizce değil · formül satırı değil
//  Taranan alanlar: sade.* · teshis.*.* · adimlar[].anlatim / formul · kural · hap · aciklama.* (model/tarih/kaynak/paragraf alt
//    alanları hariç). İngilizce koruması: İngilizce işlev sözcüğü (the, and, of, is, to …) ≥ 2 ve Türkçe sayısından az değilse dize
//    yabancı dil sayılır. Formül koruması: ≥ 2 harfli sözcük < 8 ya da harf oranı < %50 ise dize sayı/kod ağırlıklıdır, bakılmaz.
//  ÖLÇÜLDÜ: --kasa sonuçları commit mesajında / CLAUDE.md taslağında (03.10).
//  🚫 GÖRMEZ: 60 karakterden kısa ASCII dize ("Dogrusu: 150.000") · içinde tek bir Türkçe harf geçen karışık dize ("İşletme ayni
//     hesabi kullanir…") · tek tek yanlış harf ("sık"↔"şık", "kar"↔"kâr") · soru kökü / şıklar / ikiz / konu_giris / celdirici_yol /
//     sinav_taktigi / notlandirici alanları · Türkçe işlev sözcüğü taşımayan ASCII dize · İngilizceyle karışık Türkçe dize.
//  Kullanım: node arac/turkce-karakter-kapisi.js --sinav [--mutasyon] | --kasa <sgs|smmm> [cikti.json]
// ============================================================================
'use strict';
const fs = require('fs'), path = require('path');
const KOK = path.resolve(__dirname, '..');
const MUT = process.env.TR_MUTASYON || '';
const ESIK = MUT === 'esik-20' ? 20 : MUT === 'esik-200' ? 200 : 60;
const TR_HARF = /[çğıöşüâîûÇĞİÖŞÜÂÎÛ]/;   // â î û de Türkçe yazım işaretidir ("hâlâ", "kâr") — 03.10 kasa okuması: "Bu olay bir kere mi oldu, yoksa hâlâ…" yanlış alarmdı
// İki sözcük ailesi (⚠ İngilizcede de sözcük olanlar — "her", "once", "on", "a", "can", "son", "gun" — BİLEREK yok; kapı kuralı 5):
//   ISLEV  : Türkçe işlev sözcükleri; doğru yazımda da Türkçe harf taşımazlar (ve, bir, bu …) → dizenin Türkçe olduğunu gösterir
//   İŞARET : doğru yazımı Türkçe harf taşıyan sözcüğün ASCII biçimi (icin, degil, ogrenci …) ya da Türkçede ASCII'siz olamayan ek
//            (lar+i "lari", -miş "mis", art ünlüden sonra "-iyor"/"-dir") → dizenin ASCII YAZILDIĞINI gösterir.
//   Karar: ISLEV + İŞARET ≥ 2 ve İŞARET ≥ 1. İşaretsiz doğru Türkçe ("Bu olay bir kere mi oldu, yoksa devam eden bir durum mu?")
//   Türkçe harf taşımasa da düşmez.
const ISLEV = new Set(['ve', 'bir', 'bu', 'ile', 'olarak', 'olan', 'veya', 'ama', 'gibi', 'kadar', 'daha', 'sonra', 'da', 'de', 'ise', 'yani',
  'hem', 'mi', 'su', 'olur', 'eder', 'nedir', 'diye', 'buna', 'tutar', 'yoksa', 'neden', 'hangi']);
const ISARET_SOZ = /^(icin|degil\w*|cunku|ayni\w*|ogrenc\w+|dogru\w*|yanlis\w*|sikk\w*|siklar\w*|sik|gore|oldug\w*|olmadig\w*|uzerin\w*|hesabi\w*|kayd[ia]\w*|kayit\w*|isletme\w*|sirket\w*|islem\w*|odem\w*|odenen|odenir|odenecek|sonuc\w*|buyuk\w*|kucuk\w*|ozel\w*|onemli|cikar\w*|cikis\w*|giris\w*|yuzde\w*|musteri\w*|yatirim\w*|urun\w*|donem\w*|deger\w*|dusun\w*|sanir\w*|saniyor\w*|gecer\w*|iliski\w*|ucret\w*|gunu|gunluk|yil|yili|yillik|artis\w*|azalis\w*|satis\w*|alis\w*|borc\w*|soyle\w*|boyle\w*|simdi\w*|baska\w*|cogu\w*|cok|tutari\w*|alinir|yapilir|nasil|kaynag\w*)$/;
const ISARET_EK = /lari(n|ni|na|nda|ndan|nin|dir)?$|m[iu]s(tir|tur|sin|sun|lar|ti)?$|[aou][bcdfghjklmnprstvz]{1,2}iyor\w*$|[aou][bcdfghjklmnprstvz]{1,2}[dt]ir$/;
const isaretMi = w => ISARET_SOZ.test(w) || (MUT !== 'ek-yok' && ISARET_EK.test(w));
const EN_SOZ = new Set(['the', 'and', 'of', 'is', 'are', 'to', 'in', 'that', 'for', 'with', 'was', 'were', 'be', 'by', 'this', 'it', 'as', 'an',
  'which', 'should', 'not', 'or', 'from', 'have', 'has', 'will', 'would', 'their', 'its', 'been']);
const ATLA_ALT = /^(model|tarih|kaynak|kaynak_ad|paragraf|sik|karar|id|tur)$/i;
const ALANLAR = ['sade', 'teshis', 'kural', 'hap', 'aciklama'];

function gez(v, yol, out) {
  if (v == null) return out;
  if (typeof v === 'string') { out.push([yol, v]); return out; }
  if (Array.isArray(v)) { v.forEach((x, i) => gez(x, yol + '[' + i + ']', out)); return out; }
  if (typeof v === 'object') for (const [k, x] of Object.entries(v)) { if (ATLA_ALT.test(k)) continue; gez(x, yol + '.' + k, out); }
  return out;
}
// Tek dize: ASCII Türkçe mi? Döner { tr, en, sozcuk } ya da null
function asciiTurkce(s) {
  s = String(s || '');
  if (s.length < ESIK) return null;
  if (MUT !== 'trharf-yok' && TR_HARF.test(s)) return null;
  if (/https?:\/\/|www\./i.test(s)) return null;
  const sozler = (s.match(/[A-Za-z]{2,}/g) || []).map(x => x.toLowerCase());
  if (MUT !== 'formul-korumasi-yok') {
    const harf = (s.match(/[A-Za-z]/g) || []).length, dolu = s.replace(/\s/g, '').length || 1;
    if (sozler.length < 8 || harf / dolu < 0.5) return null;
  }
  let isl = 0, isr = 0, en = 0; for (const w of sozler) { if (ISLEV.has(w)) isl++; else if (isaretMi(w)) isr++; if (EN_SOZ.has(w)) en++; }
  const tr = isl + isr;
  if (MUT !== 'islev-yok' && tr < 2) return null;
  if (MUT !== 'isaret-yok' && isr < 1) return null;
  if (MUT !== 'ingilizce-yok' && en >= 2 && en >= tr) return null;
  return { tr, isaret: isr, en, sozcuk: sozler.length };
}
function dizeler(k) {
  const out = [];
  for (const a of ALANLAR) gez(k[a], a, out);
  if (MUT !== 'adim-yok' && Array.isArray(k.adimlar)) k.adimlar.forEach((x, i) => { if (!x) return; for (const al of ['anlatim', 'formul']) if (typeof x[al] === 'string') out.push(['adimlar[' + i + '].' + al, x[al]]); });
  return out;
}
function kusurlar(k) {
  const out = []; if (!k || typeof k !== 'object') return out;
  for (const [alan, t] of dizeler(k)) { const r = asciiTurkce(t); if (r) out.push({ tur: 'TR-ASCII', alan, uzunluk: t.length, tr: r.tr }); }
  return out;
}

// --kasa: kimlikler kasadan (paket_soru), içerik yerel partiden — adim-atif-kapisi.js ile AYNI düzen. Çıktıda soru metni YOK.
async function kasaIds(sinav) {
  const KEY = String(process.env.SUPABASE_SERVICE_KEY || '').trim(); if (!KEY) { console.log('SUPABASE_SERVICE_KEY yok — kasa okunamaz'); process.exit(2); }
  const ids = [];
  for (let ofs = 0; ; ofs += 1000) {
    const r = await fetch(`https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/paket_soru?select=id&sinav=eq.${sinav}&order=id.asc&limit=1000&offset=${ofs}`,
      { headers: { apikey: KEY, Authorization: 'Bearer ' + KEY, 'User-Agent': 'mevzuat-radar-robot/1.0' } });
    if (!r.ok) { console.log('kasa okunamadı: HTTP ' + r.status); process.exit(2); }
    const d = await r.json(); for (const x of d) if (x.id) ids.push(String(x.id)); if (d.length < 1000) break;
  }
  if (!ids.length) { console.log('kasada ' + sinav + ' sorusu 0 — durdu'); process.exit(2); }
  return ids;
}
async function kasa(sinav, cikti) {
  const ids = await kasaIds(sinav);
  const retY = path.join(KOK, 'veri', 'sinav', sinav + '-elle-ret.json');
  const ret = fs.existsSync(retY) ? (JSON.parse(fs.readFileSync(retY, 'utf8').replace(/^﻿/, '')).kayitlar || {}) : {};
  const P = {}; let okunan = 0, kor = 0, rette = 0; const sonuc = [], alan = {};
  for (const id of ids) {
    if (ret[id]) { rette++; continue; }
    const [e, kp] = id.split('/'); const pf = path.join(KOK, 'veri', 'fabrika', 'kalip-parti-' + e + '.json');
    if (!(e in P)) P[e] = fs.existsSync(pf) ? JSON.parse(fs.readFileSync(pf, 'utf8').replace(/^﻿/, '')) : null;
    const k = P[e] && P[e][kp]; if (!k) { kor++; continue; } okunan++;
    const b = kusurlar(k); if (b.length) { sonuc.push({ anahtar: id, kusurlar: b }); for (const x of b) { const a = x.alan.replace(/\[\d+\]/g, '[]').replace(/\.[A-E](?=\.|$)/g, '.X'); alan[a] = (alan[a] || 0) + 1; } }
  }
  console.log(`KAPI-TR kasa (${sinav}): kasada ${ids.length} · elle rette ${rette} · KÖR (yerel partide yok) ${kor} · taranan ${okunan} · bulgulu soru ${sonuc.length} · dize ${sonuc.reduce((s, x) => s + x.kusurlar.length, 0)}`);
  console.log('  alan dağılımı: ' + JSON.stringify(alan));
  if (cikti) fs.writeFileSync(cikti, JSON.stringify(sonuc, null, 1));
}

function sinav() {
  const ASCII_TR = 'Ogrenci burada ayni hesabi iki kez kullaniyor ve bu yuzden tutar yanlis cikiyor; dogru yol tek kayittir.';
  const TEMIZ_TR = 'Öğrenci burada aynı hesabı iki kez kullanıyor ve bu yüzden tutar yanlış çıkıyor; doğru yol tek kayıttır.';
  const T = (ek) => Object.assign({ soru: 'Kök?', dogru: 'C', siklar: { A: '1', B: '2', C: '3', D: '4', E: '5' },
    aciklama: { A: 'Tuzak A.', C: 'Ne soruluyor: kayıt. Doğrusu: C.' }, sade: { dogru: TEMIZ_TR }, teshis: { A: { yanilgi: TEMIZ_TR, paragraf: 'p.28' } },
    adimlar: [{ anlatim: 'Soru bize tutarları vermiş.', formul: 'Verilen: maliyet 300.000 (soruda verilen)' }] }, ek || {});
  const V = [
    ['Türkçe harfli temiz açıklama → bulgu yok', T(), 0],
    ['sade.dogru ASCII Türkçe → TR-ASCII', T({ sade: { dogru: ASCII_TR } }), 1],
    ['teshis.B.gercek ASCII Türkçe → TR-ASCII', T({ teshis: { B: { gercek: ASCII_TR } } }), 1],
    ['adimlar[].anlatim ASCII Türkçe → TR-ASCII', T({ adimlar: [{ anlatim: ASCII_TR, formul: 'x = 1' }] }), 1],
    ['aciklama.D düz dize ASCII Türkçe → TR-ASCII', T({ aciklama: { D: 'Tersine Kayit Tuzagi: ogrenci satisi iade sanir ve bu yuzden borc ile alacagi ters yazar. Dogrusu: satis kaydi.' } }), 1],
    ['hap ASCII Türkçe → TR-ASCII', T({ hap: 'Bir hesap ayni donemde hem borc hem alacak calisabilir, bu yuzden bakiyesi icin donem sonuna bakilir.' }), 1],
    // yanlış alarm vakaları
    ['İngilizce cümle (yabancı dil sorusu) → bulgu yok', T({ sade: { dogru: 'Once the auditor reviews her working papers, the engagement partner signs the report and files it with the regulator.' } }), 0],
    // "de"/"da" Türkçe listede; İngilizce metinde "de facto", "da Silva" gibi geçer → koruma gerekir
    ['İngilizce cümlede "de facto"/"da Silva"/"Artemis" (Türkçe sözcük + -mis eki çakışması) → bulgu yok', T({ teshis: { B: { gercek: 'The term de facto in this passage means that the rule is applied in practice, as da Silva argues about the Artemis program.' } } }), 0],
    ['yalnız EK işaretli ASCII ("ertelenmis", "tutarlari") → TR-ASCII', T({ hap: 'Bu kalemler ertelenmis vergi olarak raporlanmis ve bilancoda ayrica gosterilmistir; tutarlari netlestirilmez.' }), 1],
    ['işaretsiz doğru Türkçe (Türkçe harf gerekmeyen cümle) → bulgu yok', T({ teshis: { C: { ayirt: 'Bu olay bir kere mi oldu, yoksa hala devam eden bir durum mu, metne bakarak karar ver.' } } }), 0],
    ['sayı/kod ağırlıklı formül (ve/ile/bir/yil geçse de) → bulgu yok', T({ adimlar: [{ anlatim: 'Toplamı alıyoruz.', formul: 'Yil net = 400 ve 100 ile 300 bir 1.200 + 3.400 / 12 x 0,25 = 25.000 - 12.500 + 7.250 = 19.750 TL' }] }), 0],
    ['karışık dize: tek Türkçe harf varken ASCII kalan → bulgu yok (GÖRMEZ, bilerek)', T({ sade: { dogru: 'İşletme ayni hesabi iki kez kullaniyor ve bu yuzden tutar yanlis cikiyor; dogru yol tek kayittir.' } }), 0],
    ['kısa ASCII dize (< 60) → bulgu yok', T({ hap: 'Bu tutar ve oran icin ile hesap kurulur' }), 0],
    ['işlev sözcüksüz özel ad listesi → bulgu yok', T({ sade: { dogru: 'Deloitte, KPMG, PwC, EY, Grant Thornton, Mazars, BDO, Baker Tilly, Crowe, Artemis Partners, Moore Stephens' } }), 0],
    ['model/tarih alt alanı taranmaz → bulgu yok', T({ sade: { dogru: TEMIZ_TR, model: ASCII_TR, tarih: ASCII_TR } }), 0],
    ['soru kökü ASCII (kapsam dışı) → bulgu yok', T({ soru: ASCII_TR }), 0],
  ];
  let ok = 0;
  for (const [ad, k, bek] of V) { const b = kusurlar(k); const t = b.length === bek; if (t) ok++; console.log((t ? '  ✓ ' : '  ✗ ') + ad + (t ? '' : ' → ' + JSON.stringify(b))); }
  console.log((ok === V.length ? 'KAPI-TR ÖZ-SINAVI YEŞİL' : 'KAPI-TR ÖZ-SINAVI KIRMIZI') + ` (${ok}/${V.length})` + (MUT ? ' · TR_MUTASYON=' + MUT : ''));
  return ok === V.length;
}

module.exports = { kusurlar, asciiTurkce };
if (require.main === module) {
  const [a, b, c] = process.argv.slice(2);
  if (a === '--sinav') {
    if (process.argv.includes('--mutasyon')) {
      if (!sinav()) { console.log('MUTASYON koşulmadı: bozulmamış öz-sınav zaten KIRMIZI'); process.exit(1); }
      const { spawnSync } = require('child_process');
      const ler = ['esik-20', 'esik-200', 'islev-yok', 'isaret-yok', 'ek-yok', 'ingilizce-yok', 'formul-korumasi-yok', 'trharf-yok', 'adim-yok'];
      let tutan = 0;
      for (const m of ler) { const r = spawnSync(process.execPath, [__filename, '--sinav'], { env: { ...process.env, TR_MUTASYON: m }, encoding: 'utf8' }); const kr = r.status !== 0; if (kr) tutan++; console.log('  mutasyon ' + m + (kr ? ' KIRMIZI (doğru)' : ' YEŞİL (SINAV KÖR!)')); }
      console.log('MUTASYON: ' + tutan + '/' + ler.length + ' mutasyon KIRMIZI'); process.exit(tutan === ler.length ? 0 : 1);
    }
    process.exit(sinav() ? 0 : 1);
  } else if (a === '--kasa') kasa(b || 'sgs', c).catch(e => { console.log('kasa hatası: ' + e.message); process.exit(2); });
  else { console.log('--sinav [--mutasyon] | --kasa <sgs|smmm> [cikti.json]'); process.exit(2); }
}
