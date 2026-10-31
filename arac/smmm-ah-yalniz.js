#!/usr/bin/env node
// ============================================================================
//  SMMM (BİTİRME) — YALNIZ AÇIKLAMA DENETİMİ YOLU, VERİ TARAFI (31.10.2026, Cem "13 açıklamanın denetimi: (b)")
//  Cem: "Bitirme hattına ayrı 'yalnız açıklama denetimi' yolu yaz; SGS dosyalarına ve SGS oturumuna dokunma. Yolu önce sahte bir
//  soruyla sına, sonra 13 soruyu koştur. Bu yol kalıcı olsun, ileride bulunacak açıklama hataları da buradan geçsin."
//  + "Hakemin 'kusurlu' dediği her soruyu resmî metinle okumadan kabul etme; ilgili madde metnini ambardan hakeme ver."
//
//  NİYE: açıklama hakemi (AH) yalnız üretimde ve yalnız YENİ soruya (kör/hakem2 ≥ 2026-10-01) koşuyor (arac/aciklama-hakemi-uretim.ps1
//  AhAday). Açıklaması onarılan ESKİ soruya AH koşturmanın SMMM yolu yoktu; tek hazır yol SGS aracıydı (s20-ah-banka — kullanılmaz).
//  31.10 ÖLÇÜLDÜ: AH 17 kararın 4'ünde madde metnini görmeden yanlış bent/fıkra iddia etti → bu yolda AH'ye madde metni AMBARDAN verilir.
//
//  Bu dosya ağ + kayıt işini yapar; model çağrısı arac/smmm-ah-yalniz.ps1'de (çekirdek istem + toplu + bedel). Komutlar (cwd fark etmez):
//    node arac/smmm-ah-yalniz.js girdi <onarım klasörü> --ad <ad>     onarım klasöründen (beyan + _tam) depo girdisi kurar:
//                                                                    veri/sinav/smmm-ah-yalniz-girdi-<ad>.json — kimlik + taslak parmak izi
//                                                                    + dayanaklar (kaynak adı + kısa resmî alıntı). SORU METNİ YOK.
//    node arac/smmm-ah-yalniz.js hazirla <girdi> <hazir.json> [--dayanak f] [--kosan f] [--madde-kr N] [--yeniden] [--ustune-yaz]
//                                                                    ambardan yalnız istenen partiler okunur → tazelik (taslak parmak izi)
//                                                                    + madde metni → hazır dosya (GEÇİCİ klasöre; soru içeriği taşır)
//    node arac/smmm-ah-yalniz.js yaz <hazir.json> <kararlar.json> <sonuc.json> [--meta f]
//                                                                    yarış kapısı + YALNIZ hedef kaydın aciklama_hakem alanı + geri okuma
//    node arac/smmm-ah-yalniz.js --sinav                             öz-sınav (sahte ambar, ağ yok)
//  KURALLAR:
//   · Yalnız smmm- etiketi (ve sınama etiketi __sinama/smmm-ah-yalniz). sgs-/kgk- kimliği ATLANIR (SGS'ye dokunulmaz).
//   · TAZELİK: girdide taslak_sha varsa ambardaki kaydın (model alanları hariç, model adı nötr) parmak izi ona eşit olmalı; değilse
//     kayıt ATLANIR (onarım teslimi bitmemiş ya da sonradan değişmiş — eski metin hakemlenmez).
//   · Önceki karar: aynı yolun aynı içeriğe kararı varsa yeniden gönderilmez (0 USD; --yeniden ile zorla). Başka kaynaklı (üretim)
//     aciklama_hakem varsa üstüne YAZILMAZ (YENİ soruda yayın şartıdır; --ustune-yaz ile bilerek).
//   · MADDE METNİ (sıra): (1) kayıttaki kaynak_metin_ozet — yalnız beyan alıntılarının tamamını içeriyorsa; (2) girdinin dayanakları
//     → ambar dokumanlar; (3) kaydın kendi dayanağı / kaynak_adlar (kart); okunamazsa özet varsa 'kayit', yoksa 'kaynaksiz' işaretlenir, soru yine koşar.
//   · YAZIM (onarım hattı teslim disiplini): parti satırı ambardan okunur; damga hazırlıktaki damgayla aynı değilse HİÇBİR ŞEY yazılmaz
//     (yarış). Yeni içerik = ambardaki parti + yalnız hedef kp'lerin aciklama_hakem alanı (başka yol değişirse DURUR). Yazmadan hemen
//     önce damga yeniden okunur; yazım KOŞULLU (PATCH ... &guncelleme=eq.<damga>) — arada başka yazan olduysa 0 satır güncellenir, durur.
//     Sonra geri okunur: hedef alan yazılan, partinin geri kalanı yazımdan önceki ambar hâliyle kanonik olarak birebir.
//   · KUSURLU karar "geçmedi" SAYILMAZ: kayda aciklama_hakem {karar:'KUSURLU', kaynak_okundu:false, incelenecek:true} yazılır, sonuç
//     dosyasında 'incelenecek' listesine düşer; resmî metinle okunmadan kesinleşmez. (onarim-hatti gecmeNedeni 'AH KUSURLU' → elle
//     retten çıkmaz; smmm-yayin-sarti eski soruda AH aramaz → bu yol YAYINI DEĞİŞTİRMEZ.)
//   · Sonuç dosyası (depo PUBLIC): kimlik + karar + kusur ALAN adları + madde adları. Kusur gerekçesi yalnız ambardaki kayıtta.
//  🚫 GÖRMEZ: kararın doğruluğu (hakemin işi; KUSURLU elle okunur) · madde metninin güncelliği (ambar ne ise o) · koşullu yazım ile
//    geri okuma arasındaki başka yazan (geri okuma 'UYUŞMAZ' der) · bulutta koşan partinin sonradan bütün partiyi yüklemesi
//    (PS tarafı bulut-kosan-etiketler ile o partiyi gönderimden önce atlar).
// ============================================================================
'use strict';
const fs = require('fs'), path = require('path'), os = require('os'), cp = require('child_process'), crypto = require('crypto');
const KOK = path.resolve(__dirname, '..');
const TABAN = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1';
const SINAMA_ETIKET = '__sinama/smmm-ah-yalniz';
const YOL = 'smmm-ah-yalniz';
// onarim-hatti.js MODEL listesiyle aynı (model alanları içerik parmak izine girmez)
const MODEL = ['hakem', 'hakem2', 'kor_cozum', 'simulasyon_sonnet', 'kaynak_metin_ozet', 'aciklama_hakem'];
const MUT = process.env.SMMM_AH_MUTASYON || '';

const kan = v => Array.isArray(v) ? v.map(kan) : (v && typeof v === 'object') ? Object.keys(v).sort().reduce((o, k) => (o[k] = kan(v[k]), o), {}) : v;
const esit = (a, b) => JSON.stringify(kan(a)) === JSON.stringify(kan(b));
function fark(a, b, p = '', out = []) {
  if (esit(a, b)) return out;
  if (a && b && typeof a === 'object' && typeof b === 'object' && Array.isArray(a) === Array.isArray(b)) {
    for (const k of new Set([...Object.keys(a), ...Object.keys(b)])) fark(a[k], b[k], p ? (Array.isArray(a) ? `${p}[${k}]` : `${p}.${k}`) : k, out);
  } else out.push(p);
  return out;
}
const modelKod = m => { const s = String(m).trim(); if (!/^claude-/i.test(s)) return m; if (/haiku/i.test(s)) return 'model-a'; if (/sonnet/i.test(s)) return 'model-b'; if (/opus/i.test(s)) return 'model-c'; return 'model-x'; };
const notrModel = v => Array.isArray(v) ? v.map(notrModel) : (v && typeof v === 'object') ? Object.keys(v).reduce((o, k) => (o[k] = (k === 'model' && typeof v[k] === 'string') ? modelKod(v[k]) : notrModel(v[k]), o), {}) : v;
// içerik parmak izi: model alanları hariç, model adı nötr, anahtar sıralı. Taslak (_tam) ile ambar kaydı aynı ölçüyle kıyaslanır.
function icerikSha(k) { if (!k || typeof k !== 'object') return ''; const c = {}; for (const a of Object.keys(k)) if (!MODEL.includes(a)) c[a] = k[a]; return crypto.createHash('sha256').update(JSON.stringify(kan(notrModel(c)))).digest('hex'); }
const okuJson = p => JSON.parse(fs.readFileSync(p, 'utf8').replace(/^﻿/, ''));
const yazJson = (p, o) => { fs.mkdirSync(path.dirname(p), { recursive: true }); fs.writeFileSync(p, JSON.stringify(o, null, 1) + '\n'); };
const etiketGecerli = e => e === SINAMA_ETIKET || /^smmm-[a-z0-9][a-z0-9.-]*$/i.test(e);
function kimlikAyir(sid) { const s = String(sid || '').trim(); const i = s.lastIndexOf('/'); if (i < 1) return null; const e = s.slice(0, i), kp = s.slice(i + 1); if (!/^[A-Za-z0-9_.-]+$/.test(kp)) return null; return { e, kp }; }

// ---------------------------------------------------------------- IO (gerçek: Supabase REST · sahte: klasör)
const anahtar = () => { const v = (process.env.SUPABASE_SERVICE_KEY || '').trim(); if (v) return v; if (process.platform !== 'win32') return '';
  return (cp.spawnSync('powershell', ['-NoProfile', '-Command', "[Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User')"], { encoding: 'utf8' }).stdout || '').trim(); };
function gercekIO() {
  let K = null; const bas = () => { if (K === null) K = anahtar(); if (!K) throw new Error('SUPABASE_SERVICE_KEY yok'); return { apikey: K, Authorization: 'Bearer ' + K, 'User-Agent': 'mevzuat-radar-robot/1.0', Accept: 'application/json' }; };
  const al = async (u, opt = {}) => { for (let d = 1; d <= 3; d++) { try { const r = await fetch(u, { ...opt, headers: { ...bas(), ...(opt.headers || {}) }, signal: AbortSignal.timeout(120000) }); if (!r.ok) throw new Error('ambar ' + r.status + ' ' + (await r.text()).slice(0, 200)); return r; } catch (e) { if (d === 3 || /ambar 4\d\d/.test(e.message)) throw e; await new Promise(z => setTimeout(z, 3000 * d)); } } };
  return {
    async ambarSatir(e) { const r = await al(`${TABAN}/kalip_parti?select=icerik,guncelleme,sinav&etiket=eq.${encodeURIComponent(e)}`); const row = (await r.json())[0]; if (!row) return null;
      return { icerik: typeof row.icerik === 'string' ? JSON.parse(row.icerik) : (row.icerik || {}), guncelleme: String(row.guncelleme), sinav: row.sinav }; },
    async damga(e) { const r = await al(`${TABAN}/kalip_parti?select=guncelleme&etiket=eq.${encodeURIComponent(e)}`); const row = (await r.json())[0]; return row ? String(row.guncelleme) : null; },
    // KOŞULLU yazım: yalnız damga hâlâ aynıysa günceller. Dönüş: güncellenen satır sayısı + yeni damga
    async kosulluYaz(e, damga, icerik) {
      const r = await al(`${TABAN}/kalip_parti?etiket=eq.${encodeURIComponent(e)}&guncelleme=eq.${encodeURIComponent(damga)}&select=guncelleme`, { method: 'PATCH',
        headers: { 'Content-Type': 'application/json; charset=utf-8', Prefer: 'return=representation' }, body: JSON.stringify({ icerik, yazan: 'smmm-ah-yalniz' + (process.env.GITHUB_RUN_ID ? '-gh' + process.env.GITHUB_RUN_ID : '-yerel') }) });
      const rows = await r.json(); return { satir: rows.length, damga: rows[0] ? String(rows[0].guncelleme) : null }; },
    async dokuman(ad, kip) { // kip: 'eq' | 'like' (ad içinde * joker)
      const f = kip === 'eq' ? 'eq.' + encodeURIComponent(ad) : 'like.' + encodeURIComponent(ad);
      const r = await al(`${TABAN}/dokumanlar?select=kaynak_ad,metin&kaynak_ad=${f}&order=kaynak_ad.asc&limit=20`); return (await r.json()) || []; },
  };
}
// SAHTE IO: <klasör>/ambar/<etiket '/'→'~'>.json = {icerik, guncelleme | guncelleme_sira:[…]} · <klasör>/dokuman.json = [{kaynak_ad, metin}]
function sahteIO(D) {
  const af = e => path.join(D, 'ambar', e.replace(/\//g, '~') + '.json');
  const sira = {};
  const damgaAl = (e, j) => { if (!Array.isArray(j.guncelleme_sira)) return String(j.guncelleme); const n = sira[e] = (sira[e] || 0); sira[e]++; return String(j.guncelleme_sira[Math.min(n, j.guncelleme_sira.length - 1)]); };
  const io = {
    yazilan: [],
    async ambarSatir(e) { if (!fs.existsSync(af(e))) return null; const j = okuJson(af(e)); return { icerik: j.icerik, guncelleme: damgaAl(e, j), sinav: j.sinav || 'SMMM' }; },
    async damga(e) { if (!fs.existsSync(af(e))) return null; return damgaAl(e, okuJson(af(e))); },
    async kosulluYaz(e, damga, icerik) { const j = okuJson(af(e)); const simdi = Array.isArray(j.guncelleme_sira) ? String(j.guncelleme_sira[Math.min((sira[e] || 1) - 1, j.guncelleme_sira.length - 1)]) : String(j.guncelleme);
      if (simdi !== damga) return { satir: 0, damga: null };
      const yeni = 'd-' + (io.yazilan.length + 1) + '-' + e; j.icerik = icerik; delete j.guncelleme_sira; j.guncelleme = yeni; fs.writeFileSync(af(e), JSON.stringify(j)); io.yazilan.push(e); return { satir: 1, damga: yeni }; },
    async dokuman(ad, kip) { const p = path.join(D, 'dokuman.json'); if (!fs.existsSync(p)) return []; const L = okuJson(p);
      if (kip === 'eq') return L.filter(x => x.kaynak_ad === ad); const rx = new RegExp('^' + ad.split('*').map(s => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')).join('.*') + '$'); return L.filter(x => rx.test(x.kaynak_ad)).sort((a, b) => a.kaynak_ad < b.kaynak_ad ? -1 : 1); },
  };
  return io;
}
const ioSec = () => process.env.SMMM_AH_SAHTE ? sahteIO(process.env.SMMM_AH_SAHTE) : gercekIO();

// ---------------------------------------------------------------- MADDE METNİ
const trKucuk = s => String(s || '').toLocaleLowerCase('tr-TR').replace(/[’'`"“”«»]/g, '').replace(/\s+/g, ' ').trim();
function alintiYeri(metin, alinti) {
  const m = trKucuk(metin); const parca = String(alinti || '').split(/\.\.\.|…/).map(trKucuk).filter(s => s.length >= 12);
  if (!parca.length) return { bulundu: false, yer: -1 };
  let ilk = -1, hepsi = true; for (const p of parca) { const i = m.indexOf(p); if (i < 0) hepsi = false; else if (ilk < 0) ilk = i; }
  // trKucuk boşluk daralttığı için konum yaklaşık; pencere için yeterli
  return { bulundu: hepsi, yer: ilk };
}
const parcaNo = ad => { const m = /\[(\d+)\/(\d+)\]\s*$/.exec(ad); return m ? +m[1] : 0; };
async function adlaOku(io, ad) {
  const s = String(ad || '').trim(); if (!s || s.startsWith('(')) return [];
  let r = await io.dokuman(s, 'eq'); if (r.length) return r;
  const m = /^(.*?)\s*\[\d+\/\d+\]\s*$/.exec(s);
  if (m) { r = await io.dokuman(m[1] + ' [*', 'like'); if (r.length) return r; }
  // "GVK (193 s.K.) m.74" → "m.74 - Başlık" ya da "m.74 [i/n]" (m.7 sorgusu m.74'ü getirmesin diye ayraçlı)
  for (const desen of [s + ' -*', s + ' [*']) { r = await io.dokuman(desen, 'like'); if (r.length) return r; }
  return [];
}
// dayanak (kaynak_ad + alıntı) listesi → birleşik madde metni (en çok maxKr). Alıntının geçtiği parça önce, uzunsa alıntı çevresi.
async function maddeMetni(io, dayanaklar, kayit, maxKr) {
  const PARCA = Math.max(1200, Math.floor(maxKr * 0.6));
  const kartAdlari = () => { const out = []; const d = String((kayit && kayit.dayanak) || '').split(' - ')[0].trim(); if (d) out.push({ kaynak_ad: d, alinti: '' });
    for (const k of ((kayit && Array.isArray(kayit.kaynak_adlar)) ? kayit.kaynak_adlar : [])) { if (d && String(k).startsWith(d)) out.push({ kaynak_ad: k, alinti: '' }); }
    if (!d) for (const k of ((kayit && Array.isArray(kayit.kaynak_adlar)) ? kayit.kaynak_adlar.slice(0, 2) : [])) out.push({ kaynak_ad: k, alinti: '' });
    return out; };
  const dene = async (liste) => { const satirlar = new Map(); const alintilar = [];
    for (const d of liste) { const rows = await adlaOku(io, d.kaynak_ad); for (const x of rows) if (!satirlar.has(x.kaynak_ad)) satirlar.set(x.kaynak_ad, x.metin || ''); if (d.alinti) alintilar.push(String(d.alinti)); }
    return { satirlar, alintilar }; };
  // SIRA (koordinatör 31.10, 1880bf9d sonrası): (1) kayıttaki kaynak_metin_ozet — çekirdek istem onu KAYNAK olarak zaten taşır;
  //   (2) yoksa beyan dayanakları → ambar; (3) yoksa kaydın dayanağı / kaynak_adlar → ambar.
  //   KORUMA (31.10 ÖLÇÜLDÜ, onarim-ah17): 13 kaydın 10'unda özet (ilk 5.000 kr, hakemin gördüğü) beyandaki resmî alıntıyı İÇERMİYOR
  //   ve hiçbir beyan kaynak_metin_ozet'i değişen alan saymıyor → özet tek başına yetseydi AH yine madde metnini görmeyecekti (17'de 4
  //   yanlış bent iddiasının nedeni). Bu yüzden (1) yalnız beyan alıntılarının TAMAMI özette geçiyorsa (ya da beyanda alıntı yoksa) tek
  //   kaynak sayılır; değilse (2)/(3) okunur. Hiçbiri okunamazsa ve özet varsa 'kayit' (alıntı doğrulanamadı) — en son 'kaynaksiz'.
  const ozetHam = kayit && kayit.kaynak_metin_ozet; const ozet = ozetHam ? String(typeof ozetHam === 'string' ? ozetHam : JSON.stringify(ozetHam)).slice(0, 5000) : '';
  const beyanAl = (dayanaklar || []).map(d => d && d.alinti).filter(Boolean).map(String);
  if (ozet.trim()) { const bul = beyanAl.map(a => alintiYeri(ozet, a).bulundu);
    if (!beyanAl.length || bul.every(Boolean)) return { kaynak: 'kayit', adlar: ['kaynak_metin_ozet'], metin: '', alinti_dogrulandi: beyanAl.length ? true : null }; }
  let kaynak = 'ambar'; let { satirlar, alintilar } = await dene((dayanaklar || []).filter(d => d && d.kaynak_ad && !String(d.kaynak_ad).trim().startsWith('(')));
  if (!satirlar.size) { kaynak = 'kart'; ({ satirlar, alintilar } = await dene(kartAdlari())); }
  if (!satirlar.size && ozet.trim()) return { kaynak: 'kayit', adlar: ['kaynak_metin_ozet'], metin: '', alinti_dogrulandi: beyanAl.length ? false : null };
  if (!satirlar.size) return { kaynak: 'kaynaksiz', adlar: [], metin: '', alinti_dogrulandi: null };
  const parcalar = [...satirlar.entries()].map(([ad, metin]) => { let yer = -1, bul = false; for (const a of alintilar) { const y = alintiYeri(metin, a); if (y.bulundu || y.yer >= 0) { bul = bul || y.bulundu; if (yer < 0) yer = y.yer; } } return { ad, metin, yer, bul }; })
    .sort((a, b) => (b.yer >= 0) - (a.yer >= 0) || (a.ad.replace(/\s*\[\d+\/\d+\]\s*$/, '') < b.ad.replace(/\s*\[\d+\/\d+\]\s*$/, '') ? -1 : a.ad.replace(/\s*\[\d+\/\d+\]\s*$/, '') > b.ad.replace(/\s*\[\d+\/\d+\]\s*$/, '') ? 1 : parcaNo(a.ad) - parcaNo(b.ad)));
  let kalan = maxKr; const bolum = []; const adlar = [];
  for (const p of parcalar) {
    if (kalan < 300) break;
    let t = p.metin; const sinir = Math.min(PARCA, kalan);
    if (t.length > sinir) { const merkez = p.yer >= 0 ? p.yer : 0; let bas = Math.max(0, merkez - Math.floor(sinir / 3)); if (bas + sinir > t.length) bas = Math.max(0, t.length - sinir); t = (bas > 0 ? '…' : '') + t.slice(bas, bas + sinir) + (bas + sinir < p.metin.length ? '…' : ''); }
    bolum.push('== ' + p.ad + '\n' + t); adlar.push(p.ad); kalan -= t.length + p.ad.length + 4;
  }
  const alintiVar = alintilar.length > 0; const dogru = alintiVar ? parcalar.some(p => p.bul) : null;
  return { kaynak, adlar, metin: bolum.join('\n\n'), alinti_dogrulandi: dogru };
}

// ---------------------------------------------------------------- GİRDİ (onarım klasöründen)
function girdiKur(klasor, ad) {
  if (!/^[a-z0-9][a-z0-9-]{1,60}$/.test(ad)) throw new Error('--ad küçük harf/rakam/tire olmalı: ' + ad);
  const tamDir = path.join(klasor, '_tam'); if (!fs.existsSync(tamDir)) throw new Error('_tam yok: ' + klasor);
  const kimlikler = [];
  for (const f of fs.readdirSync(tamDir).filter(f => f.endsWith('.tam.json')).sort()) {
    const [e, kp] = f.replace('.tam.json', '').split('__'); const bp = path.join(klasor, e + '__' + kp + '.json');
    const bey = fs.existsSync(bp) ? okuJson(bp) : {};
    if (bey.onarilamadi) continue;
    const day = (Array.isArray(bey.dayanaklar) ? bey.dayanaklar : []).filter(d => d && d.kaynak_ad && !String(d.kaynak_ad).trim().startsWith('('))
      .map(d => ({ kaynak_ad: String(d.kaynak_ad), alinti: String(d.alinti || '').slice(0, 400) }));
    kimlikler.push({ soru_id: e + '/' + kp, taslak_sha: icerikSha(okuJson(path.join(tamDir, f))), dayanaklar: day });
  }
  return { ad, olusturma: new Date().toISOString(), kaynak_klasor: path.relative(KOK, path.resolve(klasor)).replace(/\\/g, '/'),
    not: 'smmm-ah-yalniz girdisi: kimlik + taslak parmak izi (sha256, model alanları hariç) + dayanak adı/resmî alıntı. Soru metni YOK.', kimlikler };
}
function girdiOku(p, dayanakYol) {
  const j = okuJson(p); let L = Array.isArray(j) ? j : (j.kimlikler || []);
  L = L.map(x => typeof x === 'string' ? { soru_id: x } : x);
  if (dayanakYol) { const D = okuJson(dayanakYol); for (const x of L) if (D[x.soru_id]) x.dayanaklar = [...(x.dayanaklar || []), ...D[x.soru_id]]; }
  return { ad: Array.isArray(j) ? '' : (j.ad || ''), kimlikler: L };
}

// ---------------------------------------------------------------- HAZIRLA
async function hazirla(girdi, opt = {}, io = ioSec()) {
  const maxKr = opt.maddeKr || 4000; const kosan = new Set(opt.kosan || []);
  const ogeler = []; const damgalar = {}; const satirlar = {}; const gor = new Set();
  for (const x of girdi.kimlikler) {
    const sid = String(x.soru_id || '').trim(); if (!sid || gor.has(sid)) continue; gor.add(sid);
    const o = { soru_id: sid, durum: 'atla', neden: '' }; ogeler.push(o);
    const ka = kimlikAyir(sid); if (!ka) { o.neden = 'kimlik biçimi <etiket>/<kp> değil'; continue; }
    o.etiket = ka.e; o.kp = ka.kp;
    if (!etiketGecerli(ka.e)) { o.neden = 'SMMM etiketi değil (yalnız smmm- — SGS/KGK bu yoldan geçmez)'; continue; }
    if (kosan.has(ka.e)) { o.neden = 'parti bulutta koşuyor (bulut-uretim) — sonra'; continue; }
    if (!(ka.e in satirlar)) { satirlar[ka.e] = await io.ambarSatir(ka.e); if (satirlar[ka.e]) damgalar[ka.e] = satirlar[ka.e].guncelleme; }
    const S = satirlar[ka.e]; if (!S) { o.neden = 'ambarda parti yok'; continue; }
    if (ka.e !== SINAMA_ETIKET && S.sinav && S.sinav !== 'SMMM') { o.neden = 'ambar satırı sinav=' + S.sinav + ' (SMMM değil)'; continue; }
    const k = S.icerik[ka.kp]; if (!k || !k.soru) { o.neden = 'kayıt yok / soru yok'; continue; }
    const sha = icerikSha(k); o.icerik_sha = sha;
    if (x.taslak_sha && x.taslak_sha !== sha) { o.neden = 'ambar ≠ taslak (onarım teslimi bitmemiş ya da kayıt sonradan değişmiş) — eski metin hakemlenmez'; continue; }
    o.taslak_denetimi = x.taslak_sha ? 'esit' : 'yok';
    const ah = k.aciklama_hakem;
    if (ah && ah.yol === YOL && ah.icerik_sha === sha && /^(TEMIZ|KUSURLU)$/.test(String(ah.karar)) && !opt.yeniden) { o.durum = 'onceki'; o.neden = 'bu yolun aynı içeriğe kararı var (' + ah.karar + ') — yeniden gönderilmez'; o.onceki = { karar: ah.karar }; continue; }
    if (ah && ah.yol !== YOL && !opt.ustuneYaz) { o.neden = 'kayıtta başka kaynaklı aciklama_hakem var (' + (ah.karar || '?') + ') — üstüne yazılmaz (--ustune-yaz)'; continue; }
    o.madde = await maddeMetni(io, x.dayanaklar || [], k, maxKr);
    o.kayit = k; o.durum = 'hazir'; o.neden = '';
    o.yeni_soru = (() => { const t = [k.kor_cozum && k.kor_cozum.tarih, k.hakem2 && k.hakem2.tarih].filter(Boolean).map(String).sort().pop(); return !!t && t >= '2026-10-01'; })();
  }
  return { zaman: new Date().toISOString(), girdi_ad: girdi.ad, damgalar, ogeler };
}

// ---------------------------------------------------------------- YAZ
// kararlar: { "<soru_id>": { karar, kusurlar, model, tarih } } (PS'den; OLCULEMEDI gelmez). meta: {ad, kosu, butce_usd, usd, hakem:{…}}
async function yaz(hazir, kararlar, meta = {}, io = ioSec()) {
  const out = { durum: 'yazildi', yazilan: [], yaris: [], uyusmaz: [], kayit_degisti: [], hata: [] };
  const hedef = {}; // etiket → [öğe]
  for (const o of hazir.ogeler) { if (o.durum !== 'hazir' || !kararlar[o.soru_id]) continue; (hedef[o.etiket] ||= []).push(o); }
  const ets = Object.keys(hedef);
  // (1) TAZELİK/YARIŞ: bütün partiler hazırlıktaki damgada mı — biri bile değiştiyse HİÇBİR ŞEY yazılmaz
  const A = {};
  for (const e of ets) { const S = await io.ambarSatir(e); if (!S || S.guncelleme !== hazir.damgalar[e]) out.yaris.push(e); else A[e] = S; }
  if (out.yaris.length) { out.durum = 'yaris'; return out; }
  for (const e of ets) {
    const yeni = JSON.parse(JSON.stringify(A[e].icerik)); const kpler = [];
    for (const o of hedef[e]) {
      const k = yeni[o.kp]; if (!k || icerikSha(k) !== o.icerik_sha) { out.kayit_degisti.push(o.soru_id); continue; }
      const kr = kararlar[o.soru_id]; const kus = String(kr.karar).toUpperCase() === 'KUSURLU';
      const ah = { karar: kus ? 'KUSURLU' : 'TEMIZ', kusurlar: Array.isArray(kr.kusurlar) ? kr.kusurlar : [], model: modelKod(kr.model || ''), tarih: kr.tarih || new Date().toISOString().slice(0, 10),
        yol: YOL, kosu: meta.ad || hazir.girdi_ad || '', icerik_sha: o.icerik_sha,
        madde_kaynak: o.madde ? o.madde.kaynak : 'kaynaksiz', madde_adlari: o.madde ? o.madde.adlar : [] };
      if (o.madde && o.madde.alinti_dogrulandi !== null && o.madde.alinti_dogrulandi !== undefined) ah.alinti_dogrulandi = o.madde.alinti_dogrulandi;
      if (kus) { ah.kaynak_okundu = false; ah.incelenecek = true; ah.not = 'KUSURLU kesin değil: resmî metinle okunmadan "geçmedi" sayılmaz (Cem 31.10)'; }
      if (ah.madde_kaynak === 'kaynaksiz') ah.kaynaksiz = true;
      k.aciklama_hakem = ah; if (MUT === 'baska-alan') k.soru = k.soru + ' '; kpler.push(o.kp);
    }
    if (!kpler.length) continue;
    // yalnız hedef kp'lerin aciklama_hakem alanı değişmiş olmalı
    const izinsiz = fark(A[e].icerik, yeni).filter(y => !kpler.some(kp => y === kp + '.aciklama_hakem' || y.startsWith(kp + '.aciklama_hakem.') || y.startsWith(kp + '.aciklama_hakem[')));
    if (izinsiz.length) { out.hata.push(e + ': beklenmeyen fark ' + izinsiz.slice(0, 5).join(',')); out.durum = 'hata'; return out; }
    // (2) YARIŞ KAPISI: hemen önce damga + KOŞULLU yazım
    const d2 = await io.damga(e); if (d2 !== A[e].guncelleme) { out.yaris.push(e); out.durum = 'yaris'; return out; }
    const w = await io.kosulluYaz(e, A[e].guncelleme, yeni);
    if (w.satir !== 1) { out.yaris.push(e); out.durum = 'yaris'; return out; }
    // (3) GERİ OKUMA
    const G = await io.ambarSatir(e);
    // yeni = ambar hâli + yalnız hedef aciklama_hakem (yukarıda fark ile doğrulandı) → geri okunan yeni ile kanonik birebir olmalı
    const tamam = !!G && esit(notrModel(G.icerik), notrModel(yeni));
    for (const kp of kpler) (tamam ? out.yazilan : out.uyusmaz).push(e + '/' + kp);
  }
  if (out.uyusmaz.length || out.kayit_degisti.length) out.durum = out.yazilan.length ? 'kismi' : 'hata';
  return out;
}

// ---------------------------------------------------------------- SONUÇ DOSYASI (soru metni / gerekçe YOK)
function sonucKur(hazir, kararlar, olculemedi, w, meta = {}) {
  const sayim = { istenen: hazir.ogeler.length, gonderilen: hazir.ogeler.filter(o => o.durum === 'hazir').length, temiz: 0, kusurlu: 0, olculemedi: (olculemedi || []).length,
    onceki: 0, atlanan: 0, yazilan: (w && w.yazilan || []).length, kaynaksiz: 0, kaynaksiz_kusurlu: 0, usd: meta.usd || 0 };
  const K = {}; const incelenecek = [], kaynaksiz = [], atlanan = {};
  for (const o of hazir.ogeler) {
    if (o.durum === 'onceki') { sayim.onceki++; K[o.soru_id] = { karar: o.onceki.karar, onceki: true }; continue; }
    if (o.durum !== 'hazir') { sayim.atlanan++; atlanan[o.soru_id] = o.neden; continue; }
    const mk = o.madde ? o.madde.kaynak : 'kaynaksiz'; if (mk === 'kaynaksiz') { sayim.kaynaksiz++; kaynaksiz.push(o.soru_id); }
    const kr = kararlar[o.soru_id]; if (!kr) { K[o.soru_id] = { karar: 'OLCULEMEDI', madde_kaynak: mk }; continue; }
    const kus = String(kr.karar).toUpperCase() === 'KUSURLU'; if (kus) { sayim.kusurlu++; incelenecek.push(o.soru_id); if (mk === 'kaynaksiz') sayim.kaynaksiz_kusurlu++; } else sayim.temiz++;
    const yazildi = !!(w && (w.yazilan || []).includes(o.soru_id));
    K[o.soru_id] = { karar: kus ? 'KUSURLU' : 'TEMIZ', kusur_alanlari: (kr.kusurlar || []).map(x => String((x && x.alan) || '')).filter(Boolean), madde_kaynak: mk, madde_adlari: o.madde ? o.madde.adlar : [],
      alinti_dogrulandi: o.madde ? o.madde.alinti_dogrulandi : null, kayda_yazildi: yazildi, ...(kus ? { kaynak_okundu: false } : {}) };
  }
  return { ad: meta.ad || hazir.girdi_ad, tarih: new Date().toISOString(), yol: YOL, kosu: meta.kosu || '', hakem: meta.hakem || {}, butce_usd: meta.butce_usd, yazim: w ? w.durum : 'yok',
    sayim, kararlar: K, incelenecek, kaynaksiz, kaynaksiz_kusurlu: incelenecek.filter(s => kaynaksiz.includes(s)), atlanan,
    yaris: w ? w.yaris : [], uyusmaz: w ? w.uyusmaz : [],
    gerekce: 'kusur gerekçeleri yalnız ambardaki kayıtta: kalip_parti icerik-><kp>->aciklama_hakem.kusurlar (depo PUBLIC, buraya yazılmaz)',
    not: 'KUSURLU = incelenecek: resmî metinle okunmadan kesin "geçmedi" sayılmaz (kayıtta kaynak_okundu:false). Bu yol yayını değiştirmez.' };
}

// ---------------------------------------------------------------- ÖZ-SINAV (sahte ambar, ağ yok)
async function sinav() {
  const T = fs.mkdtempSync(path.join(os.tmpdir(), 'smmm-ah-yalniz-'));
  let ok = 0, top = 0; const S = (ad, g) => { top++; if (g) ok++; console.log((g ? '  ✓ ' : '  ✗ ') + ad); };
  const e = 'smmm-sahte-ah', e2 = 'smmm-sahte-ah2';
  const taban = () => ({
    'kp-01': { soru: 'Kök 1', dogru: 'B', siklar: { A: '1', B: '2' }, aciklama: { A: 'a', B: 'b-YENİ' }, dayanak: 'KDVK (3065 s.K.) m.28', hakem: { karar: 'EVET', model: 'model-b' }, kor_cozum: { tarih: '2026-09-20', dogru_mu: true } },
    'kp-02': { soru: 'Kök 2', dogru: 'A', siklar: { A: 'x', B: 'y' }, aciklama: { A: 'p', B: 'q' }, adimlar: [{ anlatim: 'tek' }], bosluk: [[0, 1]], hakem: { karar: 'EVET', model: 'model-b' } },
    'kp-03': { soru: 'Kök 3', dogru: 'A', siklar: { A: 'm', B: 'n' }, aciklama: { A: 'r', B: 's' }, dayanak: 'YOKK (1 s.K.) m.1' } });
  const kur = (ad, partiler, dok) => { const D = path.join(T, ad); fs.mkdirSync(path.join(D, 'ambar'), { recursive: true });
    for (const [et, j] of Object.entries(partiler)) fs.writeFileSync(path.join(D, 'ambar', et.replace(/\//g, '~') + '.json'), JSON.stringify(j));
    fs.writeFileSync(path.join(D, 'dokuman.json'), JSON.stringify(dok || [{ kaynak_ad: 'KDVK (3065 s.K.) m.28', metin: 'Katma değer vergisinin genel oranı yüzde yirmidir. Cumhurbaşkanı bu oranı değiştirmeye yetkilidir.' }]));
    return { D, io: sahteIO(D), parti: et => okuJson(path.join(D, 'ambar', et.replace(/\//g, '~') + '.json')) }; };
  const g = (sid, extra = {}) => ({ soru_id: sid, dayanaklar: [{ kaynak_ad: 'KDVK (3065 s.K.) m.28', alinti: 'genel oranı yüzde yirmidir' }], ...extra });
  const krT = { karar: 'TEMIZ', kusurlar: [], model: 'claude-opus-5-5', tarih: '2026-10-31' };
  const krK = { karar: 'KUSURLU', kusurlar: [{ alan: 'aciklama.A', neden: 'oran yanlış' }], model: 'claude-opus-5-5', tarih: '2026-10-31' };
  { // 1) TEMIZ yazılır + yalnız hedef kp'nin aciklama_hakem alanı değişir, partinin geri kalanı kanonik olarak birebir
    const t = kur('s1', { [e]: { icerik: taban(), guncelleme: 'd1' } });
    const H = await hazirla({ ad: 's1', kimlikler: [g(e + '/kp-01', { taslak_sha: icerikSha(taban()['kp-01']) })] }, {}, t.io);
    const w = await yaz(H, { [e + '/kp-01']: krT }, { ad: 's1' }, t.io); const P = t.parti(e).icerik;
    S('TEMIZ → yazıldı (1 kayıt, 1 parti yazımı)', w.durum === 'yazildi' && w.yazilan.join() === e + '/kp-01' && t.io.yazilan.length === 1);
    S('TEMIZ → aciklama_hakem: karar TEMIZ, model nötr kod, yol + içerik izi, kaynak_okundu YOK', P['kp-01'].aciklama_hakem.karar === 'TEMIZ' && P['kp-01'].aciklama_hakem.model === 'model-c' && P['kp-01'].aciklama_hakem.yol === YOL && P['kp-01'].aciklama_hakem.icerik_sha === icerikSha(taban()['kp-01']) && !('kaynak_okundu' in P['kp-01'].aciklama_hakem));
    const fk = fark(taban(), P); S('YALNIZ hedef alan değişti: fark yolları = [kp-01.aciklama_hakem]', fk.length === 1 && fk[0] === 'kp-01.aciklama_hakem');
    S('partinin geri kalanı birebir (kp-02/kp-03 + kp-01 öteki alanları; tek elemanlı dizi korunur)', esit(P['kp-02'], taban()['kp-02']) && esit(P['kp-03'], taban()['kp-03']) && Array.isArray(P['kp-02'].bosluk[0]) && esit({ ...P['kp-01'], aciklama_hakem: undefined }, { ...taban()['kp-01'], aciklama_hakem: undefined }));
    S('madde metni ambardan okundu, alıntı doğrulandı', H.ogeler[0].madde.kaynak === 'ambar' && H.ogeler[0].madde.alinti_dogrulandi === true && /yüzde yirmidir/.test(H.ogeler[0].madde.metin));
    const sn = sonucKur(H, { [e + '/kp-01']: krT }, [], w, { ad: 's1' });
    S('sonuç dosyası soru/açıklama metni taşımaz', !/Kök 1|b-YENİ/.test(JSON.stringify(sn)) && sn.sayim.temiz === 1 && sn.sayim.yazilan === 1);
    // aynı içerik yeniden → 'onceki', gönderilmez
    const H2 = await hazirla({ ad: 's1', kimlikler: [g(e + '/kp-01')] }, {}, t.io); S('aynı yolun aynı içeriğe kararı var → yeniden gönderilmez (onceki)', H2.ogeler[0].durum === 'onceki');
  }
  { // 2) KUSURLU → incelenecek + kaynak_okundu:false (geçmedi sayılmaz)
    const t = kur('s2', { [e]: { icerik: taban(), guncelleme: 'd1' } });
    const H = await hazirla({ ad: 's2', kimlikler: [g(e + '/kp-01')] }, {}, t.io); const w = await yaz(H, { [e + '/kp-01']: krK }, {}, t.io); const A = t.parti(e).icerik['kp-01'].aciklama_hakem;
    const sn = sonucKur(H, { [e + '/kp-01']: krK }, [], w, {});
    S('KUSURLU → kayıtta karar KUSURLU + kaynak_okundu:false + incelenecek:true', w.durum === 'yazildi' && A.karar === 'KUSURLU' && A.kaynak_okundu === false && A.incelenecek === true);
    S('KUSURLU → sonuçta incelenecek listesinde, kusur ALAN adı var, gerekçe metni YOK', sn.incelenecek.join() === e + '/kp-01' && sn.kararlar[e + '/kp-01'].kusur_alanlari.join() === 'aciklama.A' && !/oran yanlış/.test(JSON.stringify(sn)));
  }
  { // 3) ambar açıklaması taslakla farklı → atlanır, 0 yazma
    const t = kur('s3', { [e]: { icerik: taban(), guncelleme: 'd1' } }); const eskiTaslak = taban()['kp-01']; eskiTaslak.aciklama.B = 'b-ESKİ-DEĞİL';
    const H = await hazirla({ ad: 's3', kimlikler: [g(e + '/kp-01', { taslak_sha: icerikSha(eskiTaslak) })] }, {}, t.io); const w = await yaz(H, { [e + '/kp-01']: krT }, {}, t.io);
    S('ambar ≠ taslak → ATLANDI, ambara 0 yazma', H.ogeler[0].durum === 'atla' && /taslak/.test(H.ogeler[0].neden) && t.io.yazilan.length === 0 && w.yazilan.length === 0);
    // model alanı farkı (claude-… ↔ model-b) tazeliği bozmaz
    const tm = taban()['kp-01']; tm.hakem.model = 'claude-sonnet-4-5'; tm.aciklama_hakem = { karar: 'KUSURLU' };
    S('taslak parmak izi model alanlarını saymaz (hakem/aciklama_hakem farkı → eşit)', icerikSha(tm) === icerikSha(taban()['kp-01']));
  }
  { // 4) damga değişti → durur (hazırlıktan sonra) · yazmadan hemen önce değişti → durur · koşullu yazım 0 satır → durur
    const t = kur('s4', { [e]: { icerik: taban(), guncelleme_sira: ['d1', 'd2'] } });
    const H = await hazirla({ ad: 's4', kimlikler: [g(e + '/kp-01')] }, {}, t.io); const w = await yaz(H, { [e + '/kp-01']: krT }, {}, t.io);
    S('damga değişti (hazırlık d1 → yazım d2) → DURUR, 0 yazma', w.durum === 'yaris' && t.io.yazilan.length === 0 && !t.parti(e).icerik['kp-01'].aciklama_hakem);
    const t2 = kur('s4b', { [e]: { icerik: taban(), guncelleme_sira: ['d1', 'd1', 'd3'] } });
    const H2 = await hazirla({ ad: 's4b', kimlikler: [g(e + '/kp-01')] }, {}, t2.io); const w2 = await yaz(H2, { [e + '/kp-01']: krT }, {}, t2.io);
    S('yazmadan hemen önce damga değişti → DURUR, 0 yazma', w2.durum === 'yaris' && t2.io.yazilan.length === 0);
    const t3 = kur('s4c', { [e]: { icerik: taban(), guncelleme_sira: ['d1', 'd1', 'd1', 'd9'] } }); // koşullu yazım anında d9
    const H3 = await hazirla({ ad: 's4c', kimlikler: [g(e + '/kp-01')] }, {}, t3.io); const io3 = t3.io; const kos = io3.kosulluYaz; io3.kosulluYaz = async (et, d, ic) => { await io3.damga(et); return kos(et, d, ic); };
    const w3 = await yaz(H3, { [e + '/kp-01']: krT }, {}, io3);
    S('koşullu yazım anında başka yazan (0 satır güncellendi) → DURUR', w3.durum === 'yaris' && io3.yazilan.length === 0);
    // iki partiden biri değişti → hiçbiri yazılmaz
    const t4 = kur('s4d', { [e]: { icerik: taban(), guncelleme: 'd1' }, [e2]: { icerik: taban(), guncelleme_sira: ['x1', 'x2'] } });
    const H4 = await hazirla({ ad: 's4d', kimlikler: [g(e + '/kp-01'), g(e2 + '/kp-02')] }, {}, t4.io); const w4 = await yaz(H4, { [e + '/kp-01']: krT, [e2 + '/kp-02']: krT }, {}, t4.io);
    S('iki partiden BİRİNİN damgası değişti → HİÇBİRİ yazılmaz', w4.durum === 'yaris' && t4.io.yazilan.length === 0 && w4.yaris.join() === e2);
  }
  { // 5) madde metni bulunamadı → kaynaksız işareti (yine koşar), KUSURLU ise ayrıca işaretli
    const t = kur('s5', { [e]: { icerik: taban(), guncelleme: 'd1' } }, []);
    const H = await hazirla({ ad: 's5', kimlikler: [{ soru_id: e + '/kp-03', dayanaklar: [{ kaynak_ad: 'YOK (0 s.K.) m.0', alinti: '' }] }] }, {}, t.io);
    const w = await yaz(H, { [e + '/kp-03']: krK }, {}, t.io); const A = t.parti(e).icerik['kp-03'].aciklama_hakem; const sn = sonucKur(H, { [e + '/kp-03']: krK }, [], w, {});
    S('madde metni yok → hazır (koşar), madde.kaynak = kaynaksiz', H.ogeler[0].durum === 'hazir' && H.ogeler[0].madde.kaynak === 'kaynaksiz');
    S('kaynaksız KUSURLU → kayıtta kaynaksiz:true, sonuçta kaynaksiz_kusurlu listesinde', A.kaynaksiz === true && A.karar === 'KUSURLU' && sn.kaynaksiz_kusurlu.join() === e + '/kp-03' && sn.sayim.kaynaksiz_kusurlu === 1);
    // dayanak yok → kaydın kendi dayanağı (kart) okunur
    const t2 = kur('s5b', { [e]: { icerik: taban(), guncelleme: 'd1' } });
    const H2 = await hazirla({ ad: 's5b', kimlikler: [{ soru_id: e + '/kp-01' }] }, {}, t2.io);
    S('girdide dayanak yok → kaydın dayanağı (kart) ambardan okunur', H2.ogeler[0].madde.kaynak === 'kart' && H2.ogeler[0].madde.adlar.join() === 'KDVK (3065 s.K.) m.28');
  }
  { // 6) koruma kapıları
    const t = kur('s6', { [e]: { icerik: { ...taban(), 'kp-04': { ...taban()['kp-01'], aciklama_hakem: { karar: 'TEMIZ', model: 'model-c' } } }, guncelleme: 'd1' }, 'sgs-sahte': { icerik: taban(), guncelleme: 'd1', sinav: 'SGS' } });
    const H = await hazirla({ ad: 's6', kimlikler: [g('sgs-sahte/kp-01'), g(e + '/kp-04'), g(e + '/kp-01')] }, { kosan: [] }, t.io);
    S('sgs- kimliği ATLANIR (SGS bu yoldan geçmez)', H.ogeler[0].durum === 'atla' && /SMMM etiketi değil/.test(H.ogeler[0].neden));
    S('başka kaynaklı (üretim) aciklama_hakem → üstüne yazılmaz', H.ogeler[1].durum === 'atla' && /üstüne yazılmaz/.test(H.ogeler[1].neden));
    const Hk = await hazirla({ ad: 's6', kimlikler: [g(e + '/kp-01')] }, { kosan: [e] }, t.io);
    S('bulutta koşan parti → atlanır', Hk.ogeler[0].durum === 'atla' && /bulutta/.test(Hk.ogeler[0].neden));
    const t2 = kur('s6b', { [e]: { icerik: taban(), guncelleme: 'd1' } }); const H2 = await hazirla({ ad: 's6b', kimlikler: [g(e + '/kp-01')] }, {}, t2.io);
    // MUT sabit modül yüklenirken okunur → mutasyonu alt süreçte sına
    let dur = false;
    const r = cp.spawnSync(process.execPath, ['-e', `process.env.SMMM_AH_MUTASYON='baska-alan';const m=require(${JSON.stringify(__filename)});const io=m.sahteIO(${JSON.stringify(t2.D)});m.yaz(${JSON.stringify(H2)},{${JSON.stringify(e + '/kp-01')}:${JSON.stringify(krT)}},{},io).then(w=>{console.log(JSON.stringify({d:w.durum,y:io.yazilan.length}))})`], { encoding: 'utf8' });
    try { const j = JSON.parse(r.stdout.trim().split('\n').pop()); dur = j.d === 'hata' && j.y === 0; } catch (x) { dur = false; }
    S('MUTASYON: başka alanı (soru) değiştiren yazım DURDURULUR, 0 yazma', dur && !t2.parti(e).icerik['kp-01'].aciklama_hakem);
  }
  { // 7) girdi kurucu: onarım klasöründen kimlik + taslak parmak izi + dayanak; soru metni dosyaya girmez
    const K = path.join(T, 'onarim'); fs.mkdirSync(path.join(K, '_tam'), { recursive: true });
    fs.writeFileSync(path.join(K, '_tam', e + '__kp-01.tam.json'), JSON.stringify(taban()['kp-01']));
    fs.writeFileSync(path.join(K, e + '__kp-01.json'), JSON.stringify({ degisen_alanlar: ['aciklama.B'], dayanaklar: [{ kaynak_ad: 'KDVK (3065 s.K.) m.28', alinti: 'genel oranı yüzde yirmidir' }, { kaynak_ad: '(iç tutarlılık)', alinti: '' }] }));
    const G = girdiKur(K, 'sinav-ad');
    S('girdi: kimlik + taslak_sha + dayanak (iç tutarlılık notu düşer), soru metni YOK', G.kimlikler.length === 1 && G.kimlikler[0].taslak_sha === icerikSha(taban()['kp-01']) && G.kimlikler[0].dayanaklar.length === 1 && !/Kök 1|b-YENİ/.test(JSON.stringify(G)));
  }
  { // 8) madde kaynağı sırası: özet alıntıyı içeriyorsa 'kayit' (ek okuma yok); içermiyorsa beyan dayanağı ambardan
    const tb = taban(); tb['kp-01'].kaynak_metin_ozet = 'KDVK m.28: Katma değer vergisinin genel oranı yüzde yirmidir.'; tb['kp-02'].kaynak_metin_ozet = 'Başka bir konu özeti, oran geçmiyor.';
    const t = kur('s8', { [e]: { icerik: tb, guncelleme: 'd1' } });
    const H = await hazirla({ ad: 's8', kimlikler: [g(e + '/kp-01'), g(e + '/kp-02')] }, {}, t.io);
    S('özet beyan alıntısını içeriyor → madde kaynağı kayit (kaynak_metin_ozet), ambar okunmaz', H.ogeler[0].madde.kaynak === 'kayit' && H.ogeler[0].madde.alinti_dogrulandi === true && !H.ogeler[0].madde.metin);
    S('özet alıntıyı İÇERMİYOR → beyan dayanağı ambardan okunur (31.10 ölçümü: 13 kaydın 10 tanesi)', H.ogeler[1].madde.kaynak === 'ambar' && /yüzde yirmidir/.test(H.ogeler[1].madde.metin));
    const t2 = kur('s8b', { [e]: { icerik: tb, guncelleme: 'd1' } }, []);
    const H2 = await hazirla({ ad: 's8b', kimlikler: [g(e + '/kp-02')] }, {}, t2.io);
    S('özet alıntıyı içermiyor + ambarda madde yok → kayit (alıntı doğrulanamadı), kaynaksız DEĞİL', H2.ogeler[0].madde.kaynak === 'kayit' && H2.ogeler[0].madde.alinti_dogrulandi === false);
  }
  fs.rmSync(T, { recursive: true, force: true });
  console.log(`SMMM-AH-YALNIZ ÖZ-SINAVI ${ok === top ? 'YEŞİL' : 'KIRMIZI'} (${ok}/${top})`);
  return ok === top;
}

module.exports = { icerikSha, hazirla, yaz, sonucKur, girdiKur, girdiOku, maddeMetni, sahteIO, notrModel, esit, fark, SINAMA_ETIKET };
if (require.main === module) {
  const a = process.argv.slice(2); const bayrak = n => { const i = a.indexOf(n); return i >= 0 ? a[i + 1] : undefined; };
  const kmt = a[0];
  (async () => {
    if (kmt === '--sinav') process.exit((await sinav()) ? 0 : 1);
    if (kmt === 'girdi') { const ad = bayrak('--ad'); const G = girdiKur(path.resolve(a[1]), ad); const hedef = bayrak('--cikti') || path.join(KOK, 'veri', 'sinav', `smmm-ah-yalniz-girdi-${ad}.json`);
      yazJson(hedef, G); console.log(`GİRDİ: ${G.kimlikler.length} kimlik · dayanaklı ${G.kimlikler.filter(x => x.dayanaklar.length).length} → ${path.relative(KOK, hedef)}`); return; }
    if (kmt === 'hazirla') {
      const G = girdiOku(path.resolve(a[1]), bayrak('--dayanak')); const kos = bayrak('--kosan');
      const H = await hazirla(G, { maddeKr: +(bayrak('--madde-kr') || 4000), kosan: kos && fs.existsSync(kos) ? fs.readFileSync(kos, 'utf8').split(/\s+/).filter(Boolean) : [], yeniden: a.includes('--yeniden'), ustuneYaz: a.includes('--ustune-yaz') });
      yazJson(path.resolve(a[2]), H);
      const say = d => H.ogeler.filter(o => o.durum === d).length; const mk = k => H.ogeler.filter(o => o.durum === 'hazir' && o.madde && o.madde.kaynak === k).length;
      console.log(`HAZIRLA: istenen ${H.ogeler.length} · hazır ${say('hazir')} (madde ambar ${mk('ambar')} · kart ${mk('kart')} · KAYNAKSIZ ${mk('kaynaksiz')}) · önceki ${say('onceki')} · atlanan ${say('atla')} · parti ${Object.keys(H.damgalar).length}`);
      for (const o of H.ogeler) if (o.durum !== 'hazir') console.log(`  ${o.durum.toUpperCase()} ${o.soru_id}: ${o.neden}`);
      for (const o of H.ogeler) if (o.durum === 'hazir') console.log(`  hazır ${o.soru_id}: taslak ${o.taslak_denetimi} · madde ${o.madde.kaynak} (${o.madde.adlar.length} parça, ${o.madde.metin.length} kr${o.madde.alinti_dogrulandi === false ? ', ALINTI METİNDE BULUNAMADI' : ''})${o.yeni_soru ? ' · YENİ soru' : ''}`);
      return; }
    if (kmt === 'yaz') {
      const H = okuJson(path.resolve(a[1])); const KR = okuJson(path.resolve(a[2])); const meta = bayrak('--meta') ? okuJson(path.resolve(bayrak('--meta'))) : {};
      const kararlar = KR.kararlar || {}; const olculemedi = KR.olculemedi || [];
      const w = Object.keys(kararlar).length ? await yaz(H, kararlar, meta) : { durum: 'bos', yazilan: [], yaris: [], uyusmaz: [], kayit_degisti: [], hata: [] };
      const sn = sonucKur(H, kararlar, olculemedi, w, meta); sn.olculemedi = olculemedi; sn.kayit_degisti = w.kayit_degisti; sn.hata = w.hata;
      yazJson(path.resolve(a[3]), sn);
      console.log(`YAZ: ${w.durum} · yazılan ${w.yazilan.length} · TEMIZ ${sn.sayim.temiz} · KUSURLU(incelenecek) ${sn.sayim.kusurlu} · ölçülemedi ${sn.sayim.olculemedi} · kaynaksız ${sn.sayim.kaynaksiz} (kusurlu ${sn.sayim.kaynaksiz_kusurlu}) · atlanan ${sn.sayim.atlanan} · önceki ${sn.sayim.onceki}`);
      if (w.yaris.length) console.log(`  ⛔ YARIŞ — damga değişti, HİÇBİR ŞEY YAZILMADI: ${w.yaris.join(', ')} (yeniden koşu aynı istemi bedava hasat eder)`);
      if (w.uyusmaz.length) console.log(`  ⚠ GERİ OKUMA UYUŞMAZ: ${w.uyusmaz.join(', ')}`);
      if (w.kayit_degisti.length) console.log(`  ⚠ kayıt hazırlıktan sonra değişti, yazılmadı: ${w.kayit_degisti.join(', ')}`);
      for (const h of w.hata) console.log('  ⛔ ' + h);
      process.exit(w.durum === 'yaris' ? 3 : (w.durum === 'hata' ? 1 : 0)); }
    console.log('komut: girdi | hazirla | yaz | --sinav'); process.exit(2);
  })().catch(e => { console.error('HATA: ' + e.message); process.exit(1); });
}
