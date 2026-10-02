#!/usr/bin/env node
// ============================================================================
//  ONARIM HATTI (30.09.2026, Cem "geri çekilmesin, elle düzelt" + "1.2.3")
//  GM'nin yazdığı soru onarım TASLAKLARINI ambara güvenle uygular, geri okur, elle ret listesini günceller.
//  Taslak klasörü: <klasör>/<etiket>__<kp>.json (beyan: yeni/degisen_alanlar/kok_degisti/onarilamadi) + <klasör>/_tam/<etiket>__<kp>.tam.json
//
//  Komutlar (cwd = depo kökü):
//    node arac/onarim-hatti.js uygula <klasör> [--yaz]  fark denetimi + yerel partiye yazma → <klasör>/_uygulama-<zaman>.json
//    node arac/onarim-hatti.js teslim <klasör>          bulutta koşanı atla · yedek · yaz · ambara yükle · geri oku · elle ret
//    node arac/onarim-hatti.js hakem <plan.json...>     planlardaki pilotId kayıtları elle retteyse: ambarda
//                                                       hakem EVET → listeden çıkar · HAYIR → kalır, gerekçeye yazılır
//    node arac/onarim-hatti.js --sinav                  öz-sınav (ağ yok)
//  KURALLAR (ölçülerek konuldu, 30.09):
//   · Beyan edilmeyen yolda fark varsa kayıt REDDEDİLİR (aynı soruya iki parça dokunduğunda üstüne yazmayı önler; 4 vakada yakaladı).
//   · Anahtar/kök/şık değişmediyse model alanları (hakem…) KORUNUR ve kayıt elle retten çıkar (Cem: yeniden hakem yalnız
//     anahtar/kök değişene). Değiştiyse model alanları SİLİNİR, kayıt yeniden hakeme kadar elle rette kalır/eklenir.
//   · Bulutta koşan partinin kayıtları ATLANIR (CLAUDE.md "bulutta koşan partiye ambardan yazılmaz"); sonraki koşuda alınır.
//   · Ambar geri okuması SIRADAN BAĞIMSIZ karşılaştırır (sıra duyarlı ilk sürüm 3 doğru kaydı "uyuşmaz" saydı).
//   · Sonuç dosyası ZAMAN DAMGALI yazılır (tek dosyanın üstüne yazmak r4-05'in 11 yeniden-hakem kaydını kaybettirdi).
//  🚫 GÖRMEZ: taslağın İÇERİK doğruluğu (onu GM + resmî kaynak + yeniden hakem sağlar) · ambarda başka oturumun eşzamanlı yazması.
// ============================================================================
const fs = require('fs'), path = require('path'), cp = require('child_process');
const KOK = path.resolve(__dirname, '..');
// 30.09: aciklama_hakem (5. hakem, yeni üretim — CLAUDE.md SINAV kural 3) de model alanı. Hakem AÇIKLAMAYI okuduğu için her onarımda
//   (açıklama yolu dahil) SİLİNİR → onarılan YENİ soru yeniden açıklama hakeminden geçene kadar seçilmez (SGS soru kontrolü oturumu 30.09).
//   Yayındaki eski sorularda bu alan yok; onlar etkilenmez.
const MODEL = ['hakem', 'hakem2', 'kor_cozum', 'simulasyon_sonnet', 'kaynak_metin_ozet', 'aciklama_hakem'];
const HER_ONARIMDA_SIL = ['aciklama_hakem'];
let RET = path.join(KOK, 'veri', 'sinav', 'sgs-elle-ret.json');
// 30.09 (Cem "SMMM taslaklarını sen uygula"): teslim etiket önekinden sınavı bulur. Hepsi smmm- → SMMM elle ret listesi
//   (arac/smmm-kasa-yayin.ps1 okur); karışık klasör DURUR. sgs- için davranış aynı. parti-senkron sınavı etiketten zaten ayırıyor.
function retSec(etiketler) {
  const smmm = etiketler.filter(e => /^smmm-/.test(e)).length;
  if (smmm && smmm !== etiketler.length) throw new Error('klasörde SGS ve SMMM etiketi karışık — ayrı klasörlerle teslim et');
  RET = path.join(KOK, 'veri', 'sinav', smmm ? 'smmm-elle-ret.json' : 'sgs-elle-ret.json');
  return smmm ? 'SMMM' : 'SGS';
}

const kan = v => Array.isArray(v) ? v.map(kan) : (v && typeof v === 'object') ? Object.keys(v).sort().reduce((o, k) => (o[k] = kan(v[k]), o), {}) : v;
const esit = (a, b) => JSON.stringify(kan(a)) === JSON.stringify(kan(b));
function fark(a, b, p = '', out = []) {
  if (esit(a, b)) return out;
  if (a && b && typeof a === 'object' && typeof b === 'object' && Array.isArray(a) === Array.isArray(b)) {
    for (const k of new Set([...Object.keys(a), ...Object.keys(b)])) fark(a[k], b[k], p ? (Array.isArray(a) ? `${p}[${k}]` : `${p}.${k}`) : k, out);
  } else out.push(p);
  return out;
}
const izinli = (y, izin) => izin.some(z => y === z || y.startsWith(z + '.') || y.startsWith(z + '[') || z.startsWith(y + '.') || z.startsWith(y + '['));
const modelYolu = y => MODEL.some(m => y === m || y.startsWith(m + '.') || y.startsWith(m + '['));

// saf karar: eski kayıt + taslak (tam + beyan) → {durum, yeni}
function karar(eski, tam, bey) {
  if (bey && bey.onarilamadi) return { durum: 'onarilamadi', neden: String(bey.onarilamadi) };
  if (!eski) return { durum: 'red', neden: 'kayit yok' };
  const izin = [...new Set([...((bey && bey.degisen_alanlar) || []), ...Object.keys((bey && bey.yeni) || {})])];
  const fr = fark(eski, tam).filter(y => !modelYolu(y));
  if (!fr.length) return { durum: 'red', neden: 'hic fark yok' };
  const izinsiz = fr.filter(y => !izinli(y, izin));
  if (izinsiz.length) return { durum: 'red', neden: 'izinsiz fark: ' + izinsiz.slice(0, 5).join(',') };
  const kritik = tam.soru !== eski.soru || tam.dogru !== eski.dogru || !esit(tam.siklar, eski.siklar) || !!(bey && bey.kok_degisti);
  const yeni = JSON.parse(JSON.stringify(tam));
  if (kritik) { for (const m of MODEL) delete yeni[m]; return { durum: 'rehakem', yeni }; }
  for (const m of MODEL) { if (eski[m] !== undefined && !HER_ONARIMDA_SIL.includes(m)) yeni[m] = eski[m]; else delete yeni[m]; }
  return { durum: 'aciklama', yeni };
}

const okuJ = p => { const h = fs.readFileSync(p, 'utf8'); return { bom: h.charCodeAt(0) === 0xfeff, j: JSON.parse(h.replace(/^﻿/, '')) }; };
function uygula(K, yaz, atla = new Set()) {
  const tamDir = path.join(K, '_tam'); if (!fs.existsSync(tamDir)) throw new Error('_tam yok: ' + K);
  const s = { aciklama: [], rehakem: [], red: [], onarilamadi: [], atlanan: [], onceden: [] }; const partiler = new Map();
  // DEFTER: bu klasörden daha önce uygulanan kayıt YENİDEN uygulanmaz (30.09 ölçüldü: grup-D yeniden koşulsa, sonra kalite-ek'in
  //   düzelttiği 2 kaydı eski taslakla geri alacaktı). Defter <klasör>/_uygulanan.json.
  const defterYol = path.join(K, '_uygulanan.json'); const defter = fs.existsSync(defterYol) ? JSON.parse(fs.readFileSync(defterYol, 'utf8')) : {};
  for (const f of fs.readdirSync(tamDir).filter(f => f.endsWith('.tam.json'))) {
    const [et, kp] = f.replace('.tam.json', '').split('__'); const ad = et + '/' + kp;
    if (defter[ad]) { s.onceden.push(ad); continue; }
    if (atla.has(et)) { s.atlanan.push(ad); continue; }
    const bp = path.join(K, et + '__' + kp + '.json'); if (!fs.existsSync(bp)) { s.red.push(ad + ' (beyan yok)'); continue; }
    const pf = path.join(KOK, 'veri', 'fabrika', 'kalip-parti-' + et + '.json'); if (!fs.existsSync(pf)) { s.red.push(ad + ' (parti yok)'); continue; }
    if (!partiler.has(et)) partiler.set(et, { pf, ...okuJ(pf), degisti: false });
    const P = partiler.get(et);
    const r = karar(P.j[kp], JSON.parse(fs.readFileSync(path.join(tamDir, f), 'utf8')), JSON.parse(fs.readFileSync(bp, 'utf8')));
    if (r.durum === 'red') { s.red.push(ad + ' (' + r.neden + ')'); continue; }
    if (r.durum === 'onarilamadi') { s.onarilamadi.push(ad + ': ' + r.neden); continue; }
    P.j[kp] = r.yeni; P.degisti = true; s[r.durum].push(ad);
  }
  const etiketler = [...partiler.entries()].filter(([, p]) => p.degisti).map(([e]) => e);
  if (yaz) { for (const p of partiler.values()) if (p.degisti) fs.writeFileSync(p.pf, (p.bom ? '﻿' : '') + JSON.stringify(p.j, null, 4));
    const z = new Date().toISOString(); for (const ad of [...s.aciklama, ...s.rehakem]) defter[ad] = z; fs.writeFileSync(defterYol, JSON.stringify(defter, null, 1)); }
  const out = { zaman: new Date().toISOString(), yazildi: !!yaz, etiketler, ...s };
  fs.writeFileSync(path.join(K, `_uygulama-${out.zaman.replace(/[:.]/g, '')}.json`), JSON.stringify(out, null, 1));
  return out;
}
const ps = (args, env) => cp.spawnSync('powershell', ['-NoProfile', '-ExecutionPolicy', 'Bypass', ...args], { cwd: KOK, encoding: 'utf8', env: { ...process.env, ...(env || {}) } });
// Anahtar: önce ortam (bulut işi GitHub Secret'ı buraya koyar), yoksa Windows kullanıcı değişkeni (yerel). Hiçbir yere yazdırılmaz.
const anahtar = () => { if ((process.env.SUPABASE_SERVICE_KEY || '').trim()) return process.env.SUPABASE_SERVICE_KEY.trim(); if (process.platform !== 'win32') return ''; const r = ps(['-Command', "[Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User')"]); return (r.stdout || '').trim(); };
async function ambarParti(e, K) {
  const r = await fetch('https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/kalip_parti?select=icerik&etiket=eq.' + encodeURIComponent(e), { headers: { apikey: K, Authorization: 'Bearer ' + K, 'User-Agent': 'mevzuat-radar-robot/1.0' } });
  if (!r.ok) throw new Error('ambar ' + r.status); const row = (await r.json())[0] || {}; return typeof row.icerik === 'string' ? JSON.parse(row.icerik) : (row.icerik || {});
}
function retYaz(fn) { const o = okuJ(RET); const once = Object.keys(o.j.kayitlar).length; const not = fn(o.j.kayitlar, Object.values(o.j.kayitlar)[0] || {}); fs.writeFileSync(RET, JSON.stringify(o.j, null, 4) + '\n'); return { once, sonra: Object.keys(o.j.kayitlar).length, ...not }; }
// 30.09 ÖLÇÜLDÜ: t1-fmuh-kolay-b/kp-123 listede "kökte 220 hesap kodu yanlış" gerekçesiyle duruyordu; kalite-ek onarımı yalnız ikizdeki
//   %18 KDV'yi düzeltti, eski kural onu "açıklama onarımı" sayıp listeden ÇIKARDI → kök hatalı soru yayına döndü (SMMM'de de 1 vaka).
//   Kural: açıklama onarımı kaydı listeden yalnız listeye GİRİŞ GEREKÇESİ bu parçanın taradığı kusursa çıkarır
//   (gerekçede "risk taramasi grup <parça>" izi; "-ek" gibi türev klasör kökü sayılır). Aksi hâlde kayıt kalır ve raporlanır.
function retCikabilir(gerekce, klasor) {
  const kok = String(klasor).replace(/-ek$/, '');
  // risk taraması grup-A..D için "grup B" (tiresiz), r4-NN için "grup r4-NN" yazdı — ikisi de tanınır
  //   (30.09 geriye dönük taramada bu fark 25 meşru kaydı "çıkamaz" gösterdi).
  const adlar = [kok, ...(/^grup-[A-Z]$/.test(kok) ? [kok.slice(5)] : [])];
  const g = String(gerekce || '');
  return adlar.some(a => g.includes('risk taramasi grup ' + a + ':'));
}
const retKayit = (ornek, gerekce) => { const r = { gerekce }; if ('tarih' in ornek) r.tarih = new Date().toISOString().slice(0, 10); if ('kaynak' in ornek) r.kaynak = 'onarim-rehakem'; return r; };

async function teslim(K) {
  const kos = ps(['-File', 'arac/bulut-kosan-etiketler.ps1', '-Kati']);
  const atla = new Set((kos.stdout || '').split(/\s+/).filter(Boolean));
  const kuru = uygula(K, false, atla);
  if (!kuru.etiketler.length) return console.log(`${path.basename(K)}: uygulanacak kayıt yok · atlanan ${kuru.atlanan.length} · red ${kuru.red.length}`);
  const sinav = retSec(kuru.etiketler); console.log(`${path.basename(K)}: sınav ${sinav} · elle ret ${path.basename(RET)}`);
  const Y = path.join('C:\\TETIKTE-YEDEK',`onarim-${path.basename(K)}-${kuru.zaman.replace(/[:.]/g, '')}`); fs.mkdirSync(Y, { recursive: true });
  for (const e of kuru.etiketler) fs.copyFileSync(path.join(KOK, 'veri', 'fabrika', 'kalip-parti-' + e + '.json'), path.join(Y, 'kalip-parti-' + e + '.json'));
  const u = uygula(K, true, atla);
  const yuk = u.etiketler.map(e => ({ e, cikis: ps(['-File', 'arac/parti-senkron.ps1', '-Yukle', '-Etiket', e, '-Sinav', sinav, '-Yaz']).status }));
  const Kk = anahtar(); const onb = {}; const dog = new Set(), uys = [];
  for (const ad of [...u.aciklama, ...u.rehakem]) {
    const [e, kp] = ad.split('/'); if (!onb[e]) onb[e] = await ambarParti(e, Kk);
    const yerel = okuJ(path.join(KOK, 'veri', 'fabrika', 'kalip-parti-' + e + '.json')).j[kp];
    if (esit(onb[e][kp], yerel)) dog.add(ad); else uys.push(ad);
  }
  const baskaSebep = [];
  const rr = retYaz((kay, ornek) => { let c = 0, ek = 0;
    for (const k of u.aciklama) if (dog.has(k) && kay[k]) { if (retCikabilir(kay[k].gerekce, path.basename(K))) { delete kay[k]; c++; } else baskaSebep.push(k); }
    for (const k of u.rehakem) if (dog.has(k) && !kay[k]) { kay[k] = retKayit(ornek, `onarim ${path.basename(K)}: anahtar/kok degisti, yeniden hakeme kadar yayin disi`); ek++; }
    return { cikan: c, eklenen: ek }; });
  if (baskaSebep.length) console.log(`  LİSTEDE BAŞKA SEBEPLE, ÇIKARILMADI (${baskaSebep.length}): ${baskaSebep.join(', ')}`);
  console.log(`${path.basename(K)}: aciklama ${u.aciklama.length} · rehakem ${u.rehakem.length} · red ${u.red.length} · atlanan ${u.atlanan.length} · parti ${u.etiketler.length} (yükleme hatası ${yuk.filter(x => x.cikis).length})`);
  console.log(`  ambar geri okuma ${dog.size}/${u.aciklama.length + u.rehakem.length}${uys.length ? ' · UYUŞMAZ ' + uys.join(',') : ''} · elle ret ${rr.once}→${rr.sonra} (çıkan ${rr.cikan}, eklenen ${rr.eklenen})`);
  for (const r of u.red) if (!/hic fark yok/.test(r)) console.log('  RED ' + r);
}

// Yeniden hakem kapsamı AÇIK kaynaktan: verilen plan dosyalarının pilotId'leri (gerekçe metnine bakılmaz — risk taramasından
// gelen yanlış cevaplı kayıtların gerekçesinde "yeniden hakem" ifadesi yok, metinle arama onları kaçırırdı).
async function hakem(planlar) {
  // 02.10: SMMM planları da işlenir — liste etiket önekinden seçilir (teslim ile aynı retSec; karışık plan kümesi DURUR).
  const planSatir = []; for (const p of planlar) for (const r of JSON.parse(fs.readFileSync(path.resolve(p), 'utf8').replace(/^﻿/, ''))) planSatir.push(r);
  if (planSatir.length) retSec([...new Set(planSatir.map(r => String(r.etiket)))]);
  const o = okuJ(RET); const bekSet = new Set();
  for (const r of planSatir) for (const kp of String(r.pilotId || '').split(',').filter(Boolean)) bekSet.add(r.etiket + '/' + kp);
  const bek = [...bekSet].filter(k => o.j.kayitlar[k]);
  const Kk = anahtar(); const onb = {}; const evet = [], hayir = [], bekliyor = [];
  for (const ad of bek) { const [e, kp] = ad.split('/'); if (!onb[e]) onb[e] = await ambarParti(e, Kk); const q = onb[e][kp] || {};
    const k = q.hakem && String(q.hakem.karar || q.hakem.sonuc || '').toUpperCase();
    if (!q.hakem) bekliyor.push(ad); else if (k === 'EVET') evet.push(ad); else hayir.push(ad + ' (' + k + ')'); }
  const rr = retYaz(kay => { for (const k of evet) delete kay[k]; for (const h of hayir) { const k = h.split(' (')[0]; if (kay[k] && !/HAKEM HAYIR/.test(kay[k].gerekce)) kay[k].gerekce += ' | HAKEM HAYIR (yeniden onarim gerekir)'; } return {}; });
  console.log(`yeniden hakem: bekleyen ${bek.length} · EVET ${evet.length} (listeden çıktı) · HAYIR ${hayir.length} (yayın dışı kalır) · henüz hakemsiz ${bekliyor.length} · elle ret ${rr.once}→${rr.sonra}`);
}

function sinav() {
  const e = { soru: 'Kök', dogru: 'B', siklar: { A: '1', B: '2' }, aciklama: { A: 'a', B: 'b' }, hakem: { karar: 'EVET' } };
  const V = [
    ['yalnız açıklama → hakem korunur', karar(e, { ...e, aciklama: { A: 'a2', B: 'b' }, hakem: undefined }, { degisen_alanlar: ['aciklama.A'] }), r => r.durum === 'aciklama' && r.yeni.hakem && r.yeni.hakem.karar === 'EVET'],
    ['yalnız açıklama → aciklama_hakem SİLİNİR (hakem korunur)', karar({ ...e, aciklama_hakem: { karar: 'TEMIZ' } }, { ...e, aciklama: { A: 'a2', B: 'b' }, aciklama_hakem: { karar: 'TEMIZ' } }, { degisen_alanlar: ['aciklama.A'] }), r => r.durum === 'aciklama' && !r.yeni.aciklama_hakem && r.yeni.hakem && r.yeni.hakem.karar === 'EVET'],
    ['anahtar değişti → hakem silinir', karar(e, { ...e, dogru: 'A' }, { degisen_alanlar: ['dogru'] }), r => r.durum === 'rehakem' && !r.yeni.hakem],
    ['şık değişti → yeniden hakem', karar(e, { ...e, siklar: { A: '3', B: '2' } }, { degisen_alanlar: ['siklar.A'] }), r => r.durum === 'rehakem'],
    ['beyansız fark → red', karar(e, { ...e, aciklama: { A: 'a', B: 'b2' } }, { degisen_alanlar: ['aciklama.A'] }), r => r.durum === 'red' && /izinsiz/.test(r.neden)],
    ['fark yok → red', karar(e, { ...e }, { degisen_alanlar: ['aciklama.A'] }), r => r.durum === 'red' && /fark yok/.test(r.neden)],
    ['alan sırası farkı → eşit', { durum: esit({ a: 1, b: { c: 2, d: 3 } }, { b: { d: 3, c: 2 }, a: 1 }) ? 'ok' : 'x' }, r => r.durum === 'ok'],
    ['onarılamadı işareti', karar(e, e, { onarilamadi: 'kapı yanlış alarm' }), r => r.durum === 'onarilamadi'],
    ['aynı parçanın kusuru → listeden çıkabilir', { durum: retCikabilir('29.09 risk taramasi grup r4-07: AÇIKLAMA KUSURLU (KESİN) - …', 'r4-07') ? 'ok' : 'x' }, r => r.durum === 'ok'],
    ['BAŞKA sebeple listede (kp-123 vakası) → çıkamaz', { durum: retCikabilir("Soru kokunde hesap kodu yanlis: '220 ALICILAR'", 'kalite-ek') ? 'x' : 'ok' }, r => r.durum === 'ok'],
    ['başka parçanın kusuru → çıkamaz', { durum: retCikabilir('29.09 risk taramasi grup r4-01: CEVAP YANLIŞ …', 'r4-07') ? 'x' : 'ok' }, r => r.durum === 'ok'],
    ['türev klasör (grup-C-ek) kök parçayı tanır', { durum: retCikabilir('29.09 risk taramasi grup C: AÇIKLAMA KUSURLU …', 'grup-C-ek') ? 'ok' : 'x' }, r => r.durum === 'ok'],
    ['grup-B klasörü "grup B" gerekçesini tanır', { durum: retCikabilir('29.09 risk taramasi grup B: AÇIKLAMA KUSURLU …', 'grup-B') ? 'ok' : 'x' }, r => r.durum === 'ok'],
    ['grup-B klasörü "grup BC" gibi başka grubu tanımaz', { durum: retCikabilir('29.09 risk taramasi grup BC: …', 'grup-B') ? 'x' : 'ok' }, r => r.durum === 'ok'],
  ];
  let ok = 0; for (const [ad, r, t] of V) { const g = t(r); if (g) ok++; console.log((g ? '  ✓ ' : '  ✗ ') + ad); }
  console.log(`ONARIM HATTI ÖZ-SINAVI ${ok === V.length ? 'YEŞİL' : 'KIRMIZI'} (${ok}/${V.length})`); process.exit(ok === V.length ? 0 : 1);
}

module.exports = { karar, fark, esit, retCikabilir };
if (require.main === module) {
  const [kmt, arg, yaz] = process.argv.slice(2);
  if (kmt === '--sinav') sinav();
  else if (kmt === 'uygula') { const u = uygula(path.resolve(arg), yaz === '--yaz'); console.log(JSON.stringify({ aciklama: u.aciklama.length, rehakem: u.rehakem.length, red: u.red, atlanan: u.atlanan.length })); }
  else if (kmt === 'teslim') teslim(path.resolve(arg)).catch(e => { console.error(e.message); process.exit(1); });
  else if (kmt === 'hakem') hakem(process.argv.slice(3)).catch(e => { console.error(e.message); process.exit(1); });
  else { console.log('komut: uygula|teslim|hakem|--sinav'); process.exit(2); }
}
