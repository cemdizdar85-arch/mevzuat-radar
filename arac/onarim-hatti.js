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
const HER_ONARIMDA_SIL = ['aciklama_hakem'];   // 07.10: TEMIZ karar istisnası karar() içinde (onarim_sonrasi izi)
const MUT = process.env.ONARIM_MUTASYON || '';
let RET = path.join(KOK, 'veri', 'sinav', 'sgs-elle-ret.json');
// 30.09 (Cem "SMMM taslaklarını sen uygula"): teslim etiket önekinden sınavı bulur. Hepsi smmm- → SMMM elle ret listesi
//   (arac/smmm-kasa-yayin.ps1 okur); karışık klasör DURUR. sgs- için davranış aynı. parti-senkron sınavı etiketten zaten ayırıyor.
// 07.10 (KGK oturumu, Cem "eksik kuralları yap" K8): kgk- etiketi SGS sayılıyor, onarım SGS elle ret listesine yazılıyordu
//   (KGK yayını kgk-elle-ret.json okur → rehakem bekleyen KGK sorusu yayında kalırdı). kgk- → KGK; sgs/smmm davranışı aynı.
function retSecim(etiketler) {
  const say = r => etiketler.filter(e => r.test(e)).length;
  const smmm = say(/^smmm-/), kgk = say(/^kgk-/);
  if ((smmm && smmm !== etiketler.length) || (kgk && kgk !== etiketler.length)) throw new Error('klasörde farklı sınavın etiketi karışık (sgs/smmm/kgk) — ayrı klasörlerle teslim et');
  if (process.env.ONARIM_MUTASYON === 'kgk-yok') return { sinav: smmm ? 'SMMM' : 'SGS', dosya: smmm ? 'smmm-elle-ret.json' : 'sgs-elle-ret.json' };
  return smmm ? { sinav: 'SMMM', dosya: 'smmm-elle-ret.json' } : kgk ? { sinav: 'KGK', dosya: 'kgk-elle-ret.json' } : { sinav: 'SGS', dosya: 'sgs-elle-ret.json' };
}
function retSec(etiketler) { const s = retSecim(etiketler); RET = path.join(KOK, 'veri', 'sinav', s.dosya); return s.sinav; }

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
  // 07.10 (Cem "1.2.3", SGS oturumu ölçtü): aciklama_hakem silinince YENİ soru (kör/hakem2 ≥ 10-01) yayın şartını kaybedip SESSİZCE
  //   düşüyordu (06.10: sgs-c5-fmuh-zor-r1-2/kp-07, ücretsiz). Kural: yalnız açıklama onarıldıysa ve önceki karar TEMIZ ise karar KORUNUR,
  //   yanına onarim_sonrasi izi düşülür (onarım GM + resmî kaynakla yapıldı; hakemin geçirdiği soru iyileşti). KUSURLU/başka karar
  //   silinir (o soru zaten yeniden açıklama hakemi ister). Kök/şık/anahtar değişince yukarıdaki rehakem yolu hepsini siler (değişmedi).
  //   Sıra: bu kontrol 06.10 reddinin ÖNÜNDE — TEMIZ kararlı YENİ soru reddedilmez, kararı korunarak onarılır; TEMIZ dışı YENİ soru reddedilir.
  if (MUT !== 'ah-hep-sil' && eski.aciklama_hakem && String(eski.aciklama_hakem.karar || '').toUpperCase() === 'TEMIZ') {
    for (const m of MODEL) { if (eski[m] !== undefined && !HER_ONARIMDA_SIL.includes(m)) yeni[m] = eski[m]; else delete yeni[m]; }
    yeni.aciklama_hakem = { ...eski.aciklama_hakem, onarim_sonrasi: { tarih: new Date().toISOString().slice(0, 10), not: 'karar onarımdan ÖNCEKİ metne ait; onarım yalnız açıklama katmanı' } };
    return { durum: 'aciklama', yeni };
  }
  // 06.10 (SGS oturumu uyardı, sınav oturumu ölçtü): YENİ soruda (kör/hakem2 ≥ 2026-10-01) aciklama_hakem YAYIN ŞARTI; silinirse soru
  //   sonraki kasa yayınında siteden düşer (06.10'da 1 SGS sorusu böyle düştü). Böyle bir kayda mekanik açıklama onarımı REDDEDİLİR;
  //   bilerek geçmek için ONARIM_AH_SIL=1 (sonra açıklama hakemi yeniden koşturulmalı). Eski soruda davranış aynı.
  if (eski.aciklama_hakem && yeniSoruMu(eski) && process.env.ONARIM_AH_SIL !== '1' && process.env.ONARIM_MUTASYON !== 'ah-koruma-yok')
    return { durum: 'red', neden: 'YENİ soru: aciklama_hakem silinirdi (yayın şartını kaybeder) — ONARIM_AH_SIL=1 ile bilerek geç, sonra AH yeniden' };
  for (const m of MODEL) { if (eski[m] !== undefined && !HER_ONARIMDA_SIL.includes(m)) yeni[m] = eski[m]; else delete yeni[m]; }
  return { durum: 'aciklama', yeni };
}
function yeniSoruMu(k) { const t = [k && k.kor_cozum && k.kor_cozum.tarih, k && k.hakem2 && k.hakem2.tarih].filter(Boolean).map(String).sort().pop(); return !!t && t >= '2026-10-01'; }

const okuJ = p => { const h = fs.readFileSync(p, 'utf8'); return { bom: h.charCodeAt(0) === 0xfeff, j: JSON.parse(h.replace(/^﻿/, '')) }; };
function uygula(K, yaz, atla = new Set(), fab = path.join(KOK, 'veri', 'fabrika')) {
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
    const pf = path.join(fab, 'kalip-parti-' + et + '.json'); if (!fs.existsSync(pf)) { s.red.push(ad + ' (parti yok)'); continue; }
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
// 22.10 (Cem "1.2.3", kıdem onarımı ölçtü): parti-senkron yüklerken "model":"claude-…" değerini nötr koda çevirir (veriye model adı
//   girmez kuralı). Geri okuma bunu UYUŞMAZ sayıyor, rehakem kaydı elle rete EKLENMİYORDU → 3 kök değişmiş sorunun 2'si hakemsiz
//   yayında kalacaktı. Kural: fark YALNIZ "...model" yollarında ve yerel değer "claude…" ise geri okuma tutmuş sayılır; başka her fark UYUŞMAZ.
const yolDeger = (o, y) => y.split(/[.[\]]/).filter(Boolean).reduce((a, k) => (a == null ? a : a[k]), o);
function yalnizModelIzi(ambar, yerel) {
  if (MUT === 'model-izi-yok') return false;
  const f = fark(ambar, yerel);
  return f.length > 0 && f.every(y => /(^|\.)model$/.test(y) && /^claude/i.test(String(yolDeger(yerel, y))));
}
// 22.10: kökü/anahtarı değişen (rehakem) soru geri okuma ne derse desin elle rete girer (güvenli yön: ambara yarım yazılmış
//   ya da uyuşmayan kayıt da hakemsiz yayına çıkmaz). Açıklama onarımında listeden ÇIKARMAK ise yalnız doğrulanmış geri okumayla.
function retGuncelle(kay, ornek, aciklama, rehakem, dog, klasor, baskaSebep) {
  let c = 0, ek = 0;
  for (const k of aciklama) if (dog.has(k) && kay[k]) { if (retCikabilir(kay[k].gerekce, klasor)) { delete kay[k]; c++; } else baskaSebep.push(k); }
  for (const k of rehakem) if ((MUT === 'rehakem-geriokuma' ? dog.has(k) : true) && !kay[k]) {
    kay[k] = retKayit(ornek, `onarim ${klasor}: anahtar/kok degisti, yeniden hakeme kadar yayin disi${dog.has(k) ? '' : ' (ambar geri okumasi UYUSMAZ - elle bak)'}`); ek++; }
  return { cikan: c, eklenen: ek };
}
const retKayit = (ornek, gerekce) => { const r = { gerekce }; if ('tarih' in ornek) r.tarih = new Date().toISOString().slice(0, 10); if ('kaynak' in ornek) r.kaynak = 'onarim-rehakem'; return r; };

// ============================================================================
// 31.10.2026 (Cem "DUR" + "teslim yalnız değişen soruyu yazacak, yerel dosya ambardan eskiyse teslim duracak"):
//   ÖLÇÜLEN AÇIK: teslim, parti-senkron -Yukle ile partinin TAMAMINI ambara yazıyordu (on_conflict=etiket, satır baştan).
//   Yerel kopya bayatsa partideki DOKUNULMAYAN soruların ambardaki yeni hâli (bulut hakemi, bulut onarımı, şık takası) ezilirdi.
//   kd1 teslimi (30.10, 19 parti) bunu fiilen yaptı; o seferde ezilen kayıt bulunmadı (118 kayıt, kanıt: bulut koşu günlükleri),
//   ama aynı ölçümde kd2–kd6'nın 89 etiketinin 12'sinde yerel ≠ ambar çıktı — sıradaki teslim ezecekti.
// YENİ DÜZEN:
//   (1) TAZELİK KAPISI: her etiket için ambar satırı okunur; yerel parti ambarla (model adı claude-…↔model-x farkı hariç) kayıt kayıt
//       KARŞILAŞTIRILIR. Tek kayıt farklıysa (değişecek kayıt dahil — taslak eski tabana yazılmış olur) teslim HİÇBİR ŞEY YAZMADAN durur.
//   (2) YALNIZ DEĞİŞEN SORU: ambara giden içerik AMBARDAKİ parti + yalnız bu klasörün değiştirdiği kayıtlardır (birlestir). Öteki kayıtlar
//       ambardaki hâliyle, bayt bayt aynı gider. (Tablo parti başına tek satır; satır-altı yazma yok — bu yüzden taban ambar.)
//   (3) YARIŞ KAPISI: yazmadan hemen önce ambar 'guncelleme' damgası yeniden okunur; tazelik okumasından sonra değiştiyse durur.
//   --kuru: (1)'i gerçek ambara karşı koşar, hiçbir şey yazmaz. --sahte: ağsız sahte ambarla üç senaryo (öz-sınavda da koşar).
// 🚫 GÖRMEZ: yarış kapısı ile yükleme arasındaki birkaç saniyede başka yazan · ambarın model kodu dışındaki normalizasyonu ·
//   yeni (ambarda olmayan) parti — bu durumda teslim durur, elle karar.
// ============================================================================
const modelKod = m => { const s = String(m).trim(); if (!/^claude-/i.test(s)) return m; if (/haiku/i.test(s)) return 'model-a'; if (/sonnet/i.test(s)) return 'model-b'; if (/opus/i.test(s)) return 'model-c'; return 'model-x'; };
const notrModel = v => Array.isArray(v) ? v.map(notrModel) : (v && typeof v === 'object') ? Object.keys(v).reduce((o, k) => (o[k] = (k === 'model' && typeof v[k] === 'string') ? modelKod(v[k]) : notrModel(v[k]), o), {}) : v;
function tazelikFarki(yerel, ambar) {
  const f = []; for (const kp of new Set([...Object.keys(yerel || {}), ...Object.keys(ambar || {})])) if (!esit(notrModel((yerel || {})[kp]), notrModel((ambar || {})[kp]))) f.push(kp);
  return f.sort();
}
function birlestir(ambar, yerelYeni, kpler) { const o = JSON.parse(JSON.stringify(ambar)); for (const kp of kpler) o[kp] = yerelYeni[kp]; return o; }
async function ambarSatir(e, K) {
  const r = await fetch('https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/kalip_parti?select=icerik,guncelleme&etiket=eq.' + encodeURIComponent(e), { headers: { apikey: K, Authorization: 'Bearer ' + K, 'User-Agent': 'mevzuat-radar-robot/1.0' } });
  if (!r.ok) throw new Error('ambar ' + r.status); const row = (await r.json())[0]; if (!row) return null;
  return { icerik: typeof row.icerik === 'string' ? JSON.parse(row.icerik) : (row.icerik || {}), guncelleme: String(row.guncelleme) };
}
const GERCEK_IO = {
  kosan: () => new Set((ps(['-File', 'arac/bulut-kosan-etiketler.ps1', '-Kati']).stdout || '').split(/\s+/).filter(Boolean)),
  anahtar, ambarSatir, fabrika: path.join(KOK, 'veri', 'fabrika'), yedekKok: 'C:\\TETIKTE-YEDEK',
  yukle: (e, sinav) => ps(['-File', 'arac/parti-senkron.ps1', '-Yukle', '-Etiket', e, '-Sinav', sinav, '-Yaz']).status,
  retYaz: fn => retYaz(fn), log: (...a) => console.log(...a),
};
async function teslim(K, opt = {}) {
  const io = { ...GERCEK_IO, ...(opt.io || {}) }; const ad = path.basename(K); const pf = e => path.join(io.fabrika, 'kalip-parti-' + e + '.json');
  const atla = io.kosan();
  const kuru = uygula(K, false, atla, io.fabrika);
  if (!kuru.etiketler.length) { io.log(`${ad}: uygulanacak kayıt yok · atlanan ${kuru.atlanan.length} · red ${kuru.red.length}`); return { durum: 'bos' }; }
  const sinav = opt.io ? 'SMMM' : retSec(kuru.etiketler); io.log(`${ad}: sınav ${sinav}`);
  const degisen = {}; for (const x of [...kuru.aciklama, ...kuru.rehakem]) { const [e, kp] = x.split('/'); (degisen[e] ||= []).push(kp); }
  // (1) TAZELİK KAPISI — yazmadan önce, bütün etiketler
  const Kk = io.anahtar(); const amb = {}; const bayat = [];
  for (const e of kuru.etiketler) {
    const A = await io.ambarSatir(e, Kk); if (!A) { bayat.push(`${e}: ambarda satır yok (yeni parti — elle karar)`); continue; }
    amb[e] = A; const f = tazelikFarki(okuJ(pf(e)).j, A.icerik);
    if (f.length) bayat.push(`${e}: ${f.length} kayıt farklı (${f.slice(0, 8).join(',')}${f.length > 8 ? ',…' : ''})`);
  }
  if (bayat.length) { io.log(`⛔ TESLİM DURDU — YEREL PARTİ AMBARDAN FARKLI (bayat). HİÇBİR ŞEY YAZILMADI.\n  ${bayat.join('\n  ')}\n  Yol: parti-senkron -Indir -Etiket <e> ile tazele, taslağı tazelenmiş kayda göre yeniden kur, 'uygula' kuru koşusunu tekrarla.`); return { durum: 'bayat', bayat }; }
  if (opt.kuru) { io.log(`KURU: tazelik kapısı GEÇTİ (${kuru.etiketler.length} parti). Yazılacak: ${Object.entries(degisen).map(([e, k]) => e + '[' + k.join(',') + ']').join(' ')} · ambara/ret listesine yazılmadı.`); return { durum: 'kuru', degisen }; }
  // yedek: yerel + AMBAR kopyası (teslimden önceki ambar hâli artık her teslimde saklanır)
  const Y = path.join(io.yedekKok, `onarim-${ad}-${kuru.zaman.replace(/[:.]/g, '')}`); fs.mkdirSync(Y, { recursive: true });
  for (const e of kuru.etiketler) { fs.copyFileSync(pf(e), path.join(Y, 'kalip-parti-' + e + '.json')); fs.writeFileSync(path.join(Y, 'ambar-' + e + '.json'), JSON.stringify(amb[e], null, 1)); }
  // (3) YARIŞ KAPISI
  const yaris = []; for (const e of kuru.etiketler) { const A2 = await io.ambarSatir(e, Kk); if (!A2 || A2.guncelleme !== amb[e].guncelleme) yaris.push(e); }
  if (yaris.length) { io.log(`⛔ TESLİM DURDU — tazelik okumasından sonra ambara başka yazan oldu: ${yaris.join(', ')}. HİÇBİR ŞEY YAZILMADI.`); return { durum: 'yaris', yaris }; }
  const u = uygula(K, true, atla, io.fabrika);
  // (2) YALNIZ DEĞİŞEN SORU: taban ambar, üstüne yalnız bu klasörün kayıtları
  const yuk = [];
  for (const e of u.etiketler) {
    const o = okuJ(pf(e)); const kpler = [...u.aciklama, ...u.rehakem].filter(x => x.startsWith(e + '/')).map(x => x.split('/')[1]);
    const birlesik = birlestir(amb[e].icerik, o.j, kpler); fs.writeFileSync(pf(e), (o.bom ? '﻿' : '') + JSON.stringify(birlesik, null, 4));
    yuk.push({ e, kpler, cikis: io.yukle(e, sinav) });
  }
  const onb = {}; const dog = new Set(), uys = [];
  for (const x of [...u.aciklama, ...u.rehakem]) {
    const [e, kp] = x.split('/'); if (!onb[e]) onb[e] = (await io.ambarSatir(e, Kk) || {}).icerik || {};
    const yerel = okuJ(pf(e)).j[kp];
    if (esit(onb[e][kp], yerel) || yalnizModelIzi(onb[e][kp], yerel)) dog.add(x); else uys.push(x);
  }
  const baskaSebep = [];
  const rr = io.retYaz((kay, ornek) => retGuncelle(kay, ornek, u.aciklama, u.rehakem, dog, ad, baskaSebep));
  if (baskaSebep.length) io.log(`  LİSTEDE BAŞKA SEBEPLE, ÇIKARILMADI (${baskaSebep.length}): ${baskaSebep.join(', ')}`);
  io.log(`${ad}: aciklama ${u.aciklama.length} · rehakem ${u.rehakem.length} · red ${u.red.length} · atlanan ${u.atlanan.length} · parti ${u.etiketler.length} (yükleme hatası ${yuk.filter(x => x.cikis).length}) · YALNIZ DEĞİŞEN: ${yuk.map(x => x.e + '[' + x.kpler.join(',') + ']').join(' ')}`);
  io.log(`  ambar geri okuma ${dog.size}/${u.aciklama.length + u.rehakem.length}${uys.length ? ' · UYUŞMAZ ' + uys.join(',') : ''} · elle ret ${rr.once}→${rr.sonra} (çıkan ${rr.cikan}, eklenen ${rr.eklenen})`);
  for (const r of u.red) if (!/hic fark yok/.test(r)) io.log('  RED ' + r);
  return { durum: 'yazildi', yuk, dog: [...dog], uys };
}

// SAHTE DENEME (ağ yok, gerçek ambar/ret listesi/fabrika yok): geçici klasörde 3 kayıtlı sahte parti + 1 açıklama onarımı taslağı.
async function sahteDeneme(sessiz) {
  const os = require('os'); const T = fs.mkdtempSync(path.join(os.tmpdir(), 'onarim-sahte-')); const fab = path.join(T, 'fab'), K = path.join(T, 'onarim-sahte'), Y = path.join(T, 'yedek');
  [fab, path.join(K, '_tam'), Y].forEach(d => fs.mkdirSync(d, { recursive: true }));
  const e = 'smmm-sahte-x', taban = () => ({
    'kp-01': { soru: 'Kök 1', dogru: 'B', siklar: { A: '1', B: '2' }, aciklama: { A: 'a', B: 'b' }, hakem: { karar: 'EVET', model: 'claude-sonnet-4-5' } },
    'kp-02': { soru: 'Kök 2', dogru: 'A', siklar: { A: 'x', B: 'y' }, aciklama: { A: 'p', B: 'q' }, hakem: { karar: 'EVET', model: 'claude-sonnet-4-5' } },
    'kp-03': { soru: 'Kök 3', dogru: 'A', siklar: { A: 'm', B: 'n' }, aciklama: { A: 'r', B: 's' } } });
  const tam = taban()['kp-01']; tam.aciklama = { A: 'a-YENİ', B: 'b' };
  fs.writeFileSync(path.join(K, '_tam', e + '__kp-01.tam.json'), JSON.stringify(tam)); fs.writeFileSync(path.join(K, e + '__kp-01.json'), JSON.stringify({ degisen_alanlar: ['aciklama.A'] }));
  const kur = (ambarIcerik, damgalar) => {
    fs.writeFileSync(path.join(fab, 'kalip-parti-' + e + '.json'), JSON.stringify(taban(), null, 4)); try { fs.unlinkSync(path.join(K, '_uygulanan.json')); } catch (x) { }
    const giden = []; let n = 0; const ret = { kayitlar: {} };
    const io = { kosan: () => new Set(), anahtar: () => 'x', fabrika: fab, yedekKok: Y, log: sessiz ? () => { } : (...a) => console.log('    ' + a.join(' ')),
      ambarSatir: async () => ({ icerik: JSON.parse(JSON.stringify(giden.length ? giden[giden.length - 1] : ambarIcerik)), guncelleme: damgalar[Math.min(n++, damgalar.length - 1)] }),
      yukle: et => { giden.push(okuJ(path.join(fab, 'kalip-parti-' + et + '.json')).j); return 0; },
      retYaz: fn => { const once = Object.keys(ret.kayitlar).length; const not = fn(ret.kayitlar, {}); return { once, sonra: Object.keys(ret.kayitlar).length, ...not }; } };
    return { io, giden, yerel: () => okuJ(path.join(fab, 'kalip-parti-' + e + '.json')).j };
  };
  const S = [];
  { // 1) BAYAT: ambarda kp-02 bulutta düzeltilmiş (yerelde eski) → teslim durmalı, hiçbir şey gitmemeli, yerel değişmemeli
    const amb = taban(); amb['kp-02'].soru = 'Kök 2 (bulutta düzeltildi)'; amb['kp-02'].hakem.model = 'model-b'; const t = kur(amb, ['d1']);
    const r = await teslim(K, { io: t.io }); S.push(['BAYAT yerel (kp-02 ambarda yeni) → DURUR, ambara 0 yazma, yerel aynı', r.durum === 'bayat' && t.giden.length === 0 && t.yerel()['kp-01'].aciklama.A === 'a']); }
  { // 2) TAZE: ambar = yerel (yalnız model adı kod) → yalnız kp-01 değişir; kp-02/kp-03 ambardaki hâliyle (model-b dahil) gider
    const amb = taban(); amb['kp-01'].hakem.model = 'model-b'; amb['kp-02'].hakem.model = 'model-b'; const t = kur(amb, ['d1']);
    const r = await teslim(K, { io: t.io }); const g = t.giden[0] || {};
    S.push(['TAZE → yazıldı, tek parti, yalnız kp-01', r.durum === 'yazildi' && t.giden.length === 1 && r.yuk[0].kpler.join() === 'kp-01']);
    S.push(['TAZE → kp-01 yeni açıklamayla gitti', g['kp-01'] && g['kp-01'].aciklama.A === 'a-YENİ']);
    S.push(['TAZE → kp-02 ve kp-03 AMBARDAKİ hâliyle gitti (model-b korunur, bayt bayt)', esit(g['kp-02'], amb['kp-02']) && esit(g['kp-03'], amb['kp-03'])]); }
  { // 3) YARIŞ: tazelik okumasından sonra damga değişti → DURUR, 0 yazma
    const amb = taban(); const t = kur(amb, ['d1', 'd2']);
    const r = await teslim(K, { io: t.io }); S.push(['YARIŞ (damga değişti) → DURUR, ambara 0 yazma', r.durum === 'yaris' && t.giden.length === 0]); }
  { // 4) KURU (--kuru) → yazma yok
    const t = kur(taban(), ['d1']); const r = await teslim(K, { io: t.io, kuru: true }); S.push(['KURU → yazma yok, değişecek kp-01 raporlanır', r.durum === 'kuru' && t.giden.length === 0 && (r.degisen[e] || []).join() === 'kp-01']); }
  fs.rmSync(T, { recursive: true, force: true });
  return S;
}

// Yeniden hakem kapsamı AÇIK kaynaktan: verilen plan dosyalarının pilotId'leri (gerekçe metnine bakılmaz — risk taramasından
// gelen yanlış cevaplı kayıtların gerekçesinde "yeniden hakem" ifadesi yok, metinle arama onları kaçırırdı).
async function hakem(planlar) {
  // 02.10: SMMM planları da işlenir — liste etiket önekinden seçilir (teslim ile aynı retSec; karışık plan kümesi DURUR).
  const planSatir = []; for (const p of planlar) for (const r of JSON.parse(fs.readFileSync(path.resolve(p), 'utf8').replace(/^﻿/, ''))) planSatir.push(r);
  const sec = planSatir.length ? retSec([...new Set(planSatir.map(r => String(r.etiket)))]) : null;
  const smmm = sec === 'SMMM';
  const o = okuJ(RET); const bekSet = new Set();
  for (const r of planSatir) for (const kp of String(r.pilotId || '').split(',').filter(Boolean)) bekSet.add(r.etiket + '/' + kp);
  const bek = [...bekSet].filter(k => o.j.kayitlar[k]);
  const Kk = anahtar(); const onb = {}; const evet = [], hayir = [], bekliyor = [], eksik = [];
  for (const ad of bek) { const [e, kp] = ad.split('/'); if (!onb[e]) onb[e] = await ambarParti(e, Kk); const q = onb[e][kp] || {};
    const k = q.hakem && String(q.hakem.karar || q.hakem.sonuc || '').toUpperCase();
    if (!q.hakem) bekliyor.push(ad); else if (k !== 'EVET') hayir.push(ad + ' (' + k + ')');
    else { const n = smmm ? gecmeNedeni(q) : null; if (n) eksik.push(ad + ' (' + n + ')'); else evet.push(ad); } }
  const rr = retYaz(kay => hakemRetIsle(kay, evet, hayir));
  console.log(`yeniden hakem: bekleyen ${bek.length} · EVET+tam ${evet.length} (listeden çıkan ${rr.cikan}) · EVET ama eksik ${eksik.length} (kalır) · HAYIR ${hayir.length} (yayın dışı kalır) · henüz hakemsiz ${bekliyor.length} · elle ret ${rr.once}→${rr.sonra}`);
  if (eksik.length) console.log(`  EVET AMA EKSİK (listede kalır): ${eksik.join(', ')}`);
  if (rr.korunan.length) console.log(`  ELLE KİLİT (Cem/kontrol kaydı, robot dokunmaz — kontrol düzeltmeyi okuyup elle çıkarır): ${rr.korunan.join(', ')}`);
}
// 31.10 ÖLÇÜLDÜ (8269da0e): robot yalnız hakem EVET'e bakıp 53 SMMM kaydını listeden çıkardı; 21'i kör yanlış ya da açıklama
//   hakemi KUSURLU'ydu (sitede yayın şartı tuttu, 0 sızdı). Cem 31.10 "evet yap": SMMM'de liste çıkışı = hakem EVET + hakem2 EVET +
//   kör doğru + simülasyon yanlış değil + açıklama hakemi TEMIZ. Kayıt yoksa (koşu sürüyor) çıkmaz, sonraki turda yeniden bakılır.
//   SGS/KGK davranışı değişmez (bitirme oturumu SGS'ye dokunmaz).
function gecmeNedeni(q) {
  const n = [];
  if (!q.hakem2) n.push('hakem2 yok'); else if (String(q.hakem2.karar || '').toUpperCase() !== 'EVET') n.push('hakem2 ' + q.hakem2.karar);
  if (!q.kor_cozum) n.push('kör yok'); else if (q.kor_cozum.dogru_mu !== true) n.push('kör yanlış');
  for (const sa of ['simulasyon_sonnet', 'simulasyon']) if (q[sa] && q[sa].dogru_mu === false) n.push('simülasyon yanlış');
  if (!q.aciklama_hakem) n.push('AH yok'); else if (String(q.aciklama_hakem.karar || '').toUpperCase() !== 'TEMIZ') n.push('AH ' + q.aciklama_hakem.karar);
  return n.join(', ');
}
// 31.10 ÖLÇÜLDÜ (ddbeecc2): Cem 01.11 (a) "yanlış-kesin" kaydı smmm-4k-a-yvergi-zor-r7/kp-02, ESKİ plan (o0610l) pilotId'si olduğu ve
//   ambardaki ESKİ hakem EVET'i durduğu için 40 dk sonra listeden silindi → kusurlu soru siteye döndü. Hakem kaydında tarih yok,
//   EVET'in retten sonra mı verildiği okunamıyor. KAPI: Cem/kontrol elle kaydı (kaynak alanında "Cem" / "kontrol" / "yanlış-kesin")
//   robotça ÇIKARILMAZ, gerekçesine de yazılmaz; onarım hattının kendi kaydı (kaynak onarim-rehakem) ve tarama kaynaklı kayıtlar eskisi gibi.
const ELLE_KILIT = /\bCem\b|kontrol|yanl[ıi][şs]-kesin/i;
const elleKilitli = kayit => !!kayit && ELLE_KILIT.test(String(kayit.kaynak || ''));
function hakemRetIsle(kay, evet, hayir) {
  const korunan = []; let cikan = 0;
  for (const k of evet) { if (!kay[k]) continue; if (elleKilitli(kay[k])) { korunan.push(k); continue; } delete kay[k]; cikan++; }
  for (const h of hayir) { const k = h.split(' (')[0]; if (!kay[k] || elleKilitli(kay[k])) continue; if (!/HAKEM HAYIR/.test(kay[k].gerekce)) kay[k].gerekce += ' | HAKEM HAYIR (yeniden onarim gerekir)'; }
  return { cikan, korunan };
}

function sinav() {
  const e = { soru: 'Kök', dogru: 'B', siklar: { A: '1', B: '2' }, aciklama: { A: 'a', B: 'b' }, hakem: { karar: 'EVET' } };
  const V = [
    ['yalnız açıklama → hakem korunur', karar(e, { ...e, aciklama: { A: 'a2', B: 'b' }, hakem: undefined }, { degisen_alanlar: ['aciklama.A'] }), r => r.durum === 'aciklama' && r.yeni.hakem && r.yeni.hakem.karar === 'EVET'],
    // 07.10: TEMIZ karar korunur + onarim_sonrasi izi; KUSURLU silinir; anahtar değişince silinir
    ['yalnız açıklama + AH TEMIZ → KORUNUR, onarim_sonrasi izi', karar({ ...e, aciklama_hakem: { karar: 'TEMIZ' } }, { ...e, aciklama: { A: 'a2', B: 'b' }, aciklama_hakem: { karar: 'TEMIZ' } }, { degisen_alanlar: ['aciklama.A'] }), r => r.durum === 'aciklama' && r.yeni.aciklama_hakem && r.yeni.aciklama_hakem.karar === 'TEMIZ' && r.yeni.aciklama_hakem.onarim_sonrasi && r.yeni.hakem && r.yeni.hakem.karar === 'EVET'],
    ['yalnız açıklama + AH KUSURLU → SİLİNİR', karar({ ...e, aciklama_hakem: { karar: 'KUSURLU' } }, { ...e, aciklama: { A: 'a2', B: 'b' }, aciklama_hakem: { karar: 'KUSURLU' } }, { degisen_alanlar: ['aciklama.A'] }), r => r.durum === 'aciklama' && !r.yeni.aciklama_hakem],
    ['anahtar değişti + AH TEMIZ → SİLİNİR (rehakem)', karar({ ...e, aciklama_hakem: { karar: 'TEMIZ' } }, { ...e, dogru: 'A', aciklama_hakem: { karar: 'TEMIZ' } }, { degisen_alanlar: ['dogru'] }), r => r.durum === 'rehakem' && !r.yeni.aciklama_hakem],
    ['YENİ soru (kör 10-02) + AH KUSURLU → açıklama onarımı REDDEDİLİR', karar({ ...e, kor_cozum: { tarih: '2026-10-02' }, aciklama_hakem: { karar: 'KUSURLU' } }, { ...e, aciklama: { A: 'a2', B: 'b' }, kor_cozum: { tarih: '2026-10-02' }, aciklama_hakem: { karar: 'KUSURLU' } }, { degisen_alanlar: ['aciklama.A'] }), r => r.durum === 'red' && /YENİ soru/.test(r.neden)],
    ['07.10: YENİ soru + AH TEMIZ → onarılır, karar KORUNUR (izli)', karar({ ...e, kor_cozum: { tarih: '2026-10-02' }, aciklama_hakem: { karar: 'TEMIZ' } }, { ...e, aciklama: { A: 'a2', B: 'b' }, kor_cozum: { tarih: '2026-10-02' }, aciklama_hakem: { karar: 'TEMIZ' } }, { degisen_alanlar: ['aciklama.A'] }), r => r.durum === 'aciklama' && r.yeni.aciklama_hakem && r.yeni.aciklama_hakem.onarim_sonrasi],
    ['eski soru (kör 09-20) + AH KUSURLU → onarım geçer, AH silinir', karar({ ...e, kor_cozum: { tarih: '2026-09-20' }, aciklama_hakem: { karar: 'KUSURLU' } }, { ...e, aciklama: { A: 'a2', B: 'b' }, kor_cozum: { tarih: '2026-09-20' }, aciklama_hakem: { karar: 'KUSURLU' } }, { degisen_alanlar: ['aciklama.A'] }), r => r.durum === 'aciklama' && !r.yeni.aciklama_hakem],
    ['YENİ soru AH\'siz → onarım geçer (silinecek bir şey yok)', karar({ ...e, kor_cozum: { tarih: '2026-10-02' } }, { ...e, aciklama: { A: 'a2', B: 'b' }, kor_cozum: { tarih: '2026-10-02' } }, { degisen_alanlar: ['aciklama.A'] }), r => r.durum === 'aciklama'],
    ['anahtar değişti → hakem silinir', karar(e, { ...e, dogru: 'A' }, { degisen_alanlar: ['dogru'] }), r => r.durum === 'rehakem' && !r.yeni.hakem],
    ['şık değişti → yeniden hakem', karar(e, { ...e, siklar: { A: '3', B: '2' } }, { degisen_alanlar: ['siklar.A'] }), r => r.durum === 'rehakem'],
    ['beyansız fark → red', karar(e, { ...e, aciklama: { A: 'a', B: 'b2' } }, { degisen_alanlar: ['aciklama.A'] }), r => r.durum === 'red' && /izinsiz/.test(r.neden)],
    ['fark yok → red', karar(e, { ...e }, { degisen_alanlar: ['aciklama.A'] }), r => r.durum === 'red' && /fark yok/.test(r.neden)],
    // 22.10 geri okuma: yükleme "claude-…" model izini nötr koda çevirir (kıdem onarımı, 2/3 kayıt)
    ['geri okuma: yalnız model izi (claude→nötr) → tuttu', { durum: yalnizModelIzi({ soru: 'K', sade: { model: 'model-a', t: 'x' } }, { soru: 'K', sade: { model: 'claude-haiku-4-5', t: 'x' } }) ? 'ok' : 'x' }, r => r.durum === 'ok'],
    ['geri okuma: model izi + içerik farkı → UYUŞMAZ', { durum: yalnizModelIzi({ soru: 'K2', sade: { model: 'model-a' } }, { soru: 'K', sade: { model: 'claude-haiku-4-5' } }) ? 'x' : 'ok' }, r => r.durum === 'ok'],
    ['geri okuma: nötr→nötr model farkı (claude değil) → UYUŞMAZ', { durum: yalnizModelIzi({ sade: { model: 'model-a' } }, { sade: { model: 'model-b' } }) ? 'x' : 'ok' }, r => r.durum === 'ok'],
    ['geri okuma: "model" ile biten ama model olmayan alan → UYUŞMAZ', { durum: yalnizModelIzi({ islem_model: 'a' }, { islem_model: 'claude-x' }) ? 'x' : 'ok' }, r => r.durum === 'ok'],
    ['rehakem: geri okuma UYUŞMAZ olsa da elle rete girer', (() => { const kay = {}; const r = retGuncelle(kay, { tarih: 'x' }, [], ['e/kp-1'], new Set(), 'k', []); return { durum: kay['e/kp-1'] && /UYUSMAZ/.test(kay['e/kp-1'].gerekce) && r.eklenen === 1 ? 'ok' : 'x' }; })(), r => r.durum === 'ok'],
    ['açıklama: geri okuma UYUŞMAZsa listeden ÇIKMAZ', (() => { const kay = { 'e/kp-2': { gerekce: 'risk taramasi grup k: x' } }; retGuncelle(kay, {}, ['e/kp-2'], [], new Set(), 'k', []); return { durum: kay['e/kp-2'] ? 'ok' : 'x' }; })(), r => r.durum === 'ok'],
    ['alan sırası farkı → eşit', { durum: esit({ a: 1, b: { c: 2, d: 3 } }, { b: { d: 3, c: 2 }, a: 1 }) ? 'ok' : 'x' }, r => r.durum === 'ok'],
    ['onarılamadı işareti', karar(e, e, { onarilamadi: 'kapı yanlış alarm' }), r => r.durum === 'onarilamadi'],
    ['aynı parçanın kusuru → listeden çıkabilir', { durum: retCikabilir('29.09 risk taramasi grup r4-07: AÇIKLAMA KUSURLU (KESİN) - …', 'r4-07') ? 'ok' : 'x' }, r => r.durum === 'ok'],
    ['BAŞKA sebeple listede (kp-123 vakası) → çıkamaz', { durum: retCikabilir("Soru kokunde hesap kodu yanlis: '220 ALICILAR'", 'kalite-ek') ? 'x' : 'ok' }, r => r.durum === 'ok'],
    ['başka parçanın kusuru → çıkamaz', { durum: retCikabilir('29.09 risk taramasi grup r4-01: CEVAP YANLIŞ …', 'r4-07') ? 'x' : 'ok' }, r => r.durum === 'ok'],
    ['türev klasör (grup-C-ek) kök parçayı tanır', { durum: retCikabilir('29.09 risk taramasi grup C: AÇIKLAMA KUSURLU …', 'grup-C-ek') ? 'ok' : 'x' }, r => r.durum === 'ok'],
    ['grup-B klasörü "grup B" gerekçesini tanır', { durum: retCikabilir('29.09 risk taramasi grup B: AÇIKLAMA KUSURLU …', 'grup-B') ? 'ok' : 'x' }, r => r.durum === 'ok'],
    ['grup-B klasörü "grup BC" gibi başka grubu tanımaz', { durum: retCikabilir('29.09 risk taramasi grup BC: …', 'grup-B') ? 'x' : 'ok' }, r => r.durum === 'ok'],
    // 31.10 ddbeecc2 vakası: eski planın bayat hakem EVET'i Cem/kontrol elle kaydını SİLMEZ
    ['hakem: eski EVET + Cem (a) yanlış-kesin elle ret → KALIR (ddbeecc2)', (() => { const g = 'TTK m.519/2-c'; const kay = { 'e/kp-02': { gerekce: g, kaynak: 'Cem 01.11 (a) yanlış-kesin: iki kör çözücü (Ajan 1)', tarih: '2026-10-30' } }; const r = hakemRetIsle(kay, ['e/kp-02'], []); return { durum: kay['e/kp-02'] && kay['e/kp-02'].gerekce === g && r.cikan === 0 && r.korunan.join() === 'e/kp-02' ? 'ok' : 'x' }; })(), r => r.durum === 'ok'],
    ['hakem: EVET + onarim-rehakem kaydı → ÇIKAR', (() => { const kay = { 'e/kp-1': { gerekce: 'onarim k: anahtar/kok degisti, yeniden hakeme kadar yayin disi', kaynak: 'onarim-rehakem' } }; const r = hakemRetIsle(kay, ['e/kp-1'], []); return { durum: !kay['e/kp-1'] && r.cikan === 1 ? 'ok' : 'x' }; })(), r => r.durum === 'ok'],
    ['hakem: EVET + tarama kaydı (sgs-risk-taramasi) → ÇIKAR (eski akış)', (() => { const kay = { 'e/kp-3': { gerekce: 'risk', kaynak: 'sgs-risk-taramasi' } }; hakemRetIsle(kay, ['e/kp-3'], []); return { durum: kay['e/kp-3'] ? 'x' : 'ok' }; })(), r => r.durum === 'ok'],
    ['hakem: HAYIR + Cem elle kaydı → gerekçe DEĞİŞMEZ', (() => { const kay = { 'e/kp-4': { gerekce: 'g', kaynak: 'Cem 30.10 ilk 120 temizliği' } }; hakemRetIsle(kay, [], ['e/kp-4 (HAYIR)']); return { durum: kay['e/kp-4'].gerekce === 'g' ? 'ok' : 'x' }; })(), r => r.durum === 'ok'],
    ['hakem: HAYIR + onarim kaydı → HAKEM HAYIR işlenir (bir kez)', (() => { const kay = { 'e/kp-5': { gerekce: 'g', kaynak: 'onarim-rehakem' } }; hakemRetIsle(kay, [], ['e/kp-5 (HAYIR)']); hakemRetIsle(kay, [], ['e/kp-5 (HAYIR)']); return { durum: kay['e/kp-5'].gerekce === 'g | HAKEM HAYIR (yeniden onarim gerekir)' ? 'ok' : 'x' }; })(), r => r.durum === 'ok'],
    ['hakem: "kontrol" kaynaklı elle kayıt → KALIR', { durum: elleKilitli({ kaynak: 'kontrol ajanı 01.11' }) && !elleKilitli({ kaynak: 'onarim-rehakem' }) && !elleKilitli({ kaynak: 'sinav kolu kanun değişikliği taraması' }) && !elleKilitli({}) ? 'ok' : 'x' }, r => r.durum === 'ok'],
    // 31.10 8269da0e vakası: SMMM'de hakem EVET tek başına listeden çıkarmaz
    ...(() => { const tam = { hakem: { karar: 'EVET' }, hakem2: { karar: 'EVET' }, kor_cozum: { dogru_mu: true }, simulasyon_sonnet: { dogru_mu: true }, aciklama_hakem: { karar: 'TEMIZ' } };
      return [['SMMM çıkış: hepsi geçti → neden yok', { durum: gecmeNedeni(tam) === '' ? 'ok' : 'x' }, r => r.durum === 'ok'],
        ['SMMM çıkış: kör yanlış → kalır', { durum: /kör yanlış/.test(gecmeNedeni({ ...tam, kor_cozum: { dogru_mu: false } })) ? 'ok' : 'x' }, r => r.durum === 'ok'],
        ['SMMM çıkış: AH KUSURLU → kalır', { durum: /AH KUSURLU/.test(gecmeNedeni({ ...tam, aciklama_hakem: { karar: 'KUSURLU' } })) ? 'ok' : 'x' }, r => r.durum === 'ok'],
        ['SMMM çıkış: AH henüz yok → kalır', { durum: /AH yok/.test(gecmeNedeni({ ...tam, aciklama_hakem: undefined })) ? 'ok' : 'x' }, r => r.durum === 'ok'],
        ['SMMM çıkış: simülasyon yanlış → kalır', { durum: /simülasyon/.test(gecmeNedeni({ ...tam, simulasyon_sonnet: { dogru_mu: false } })) ? 'ok' : 'x' }, r => r.durum === 'ok'],
        ['SMMM çıkış: hakem2 HAYIR → kalır', { durum: /hakem2 HAYIR/.test(gecmeNedeni({ ...tam, hakem2: { karar: 'HAYIR' } })) ? 'ok' : 'x' }, r => r.durum === 'ok'],
        ['SMMM çıkış: kör yok → kalır', { durum: /kör yok/.test(gecmeNedeni({ ...tam, kor_cozum: undefined })) ? 'ok' : 'x' }, r => r.durum === 'ok']]; })(),
    ['kgk- etiketleri → KGK elle ret listesi', retSecim(['kgk-d1-tds-zor-1', 'kgk-gm-ky-r1']), r => r.sinav === 'KGK' && r.dosya === 'kgk-elle-ret.json'],
    ['sgs- etiketi → SGS (davranış aynı)', retSecim(['sgs-c2-fmuh-zor-r3']), r => r.sinav === 'SGS' && r.dosya === 'sgs-elle-ret.json'],
    ['smmm- etiketi → SMMM (davranış aynı)', retSecim(['smmm-gm9-1-yvergi-zor']), r => r.sinav === 'SMMM' && r.dosya === 'smmm-elle-ret.json'],
    ['kgk + sgs karışık → DURUR', { durum: (() => { try { retSecim(['kgk-a', 'sgs-b']); return 'x'; } catch (e) { return 'ok'; } })() }, r => r.durum === 'ok'],
    // 31.10 tazelik kapısı + yalnız değişen soru
    ['tazelik: yalnız model adı farkı (claude↔model-b) → FARK YOK', { durum: tazelikFarki({ k: { soru: 'a', hakem: { model: 'claude-sonnet-4-5' } } }, { k: { soru: 'a', hakem: { model: 'model-b' } } }).length === 0 ? 'ok' : 'x' }, r => r.durum === 'ok'],
    ['tazelik: içerik farkı → o kayıt listelenir', { durum: tazelikFarki({ k1: { soru: 'a' }, k2: { soru: 'b' } }, { k1: { soru: 'a' }, k2: { soru: 'B' } }).join() === 'k2' ? 'ok' : 'x' }, r => r.durum === 'ok'],
    ['tazelik: ambarda olup yerelde olmayan kayıt → fark', { durum: tazelikFarki({ k1: { soru: 'a' } }, { k1: { soru: 'a' }, k9: { soru: 'z' } }).join() === 'k9' ? 'ok' : 'x' }, r => r.durum === 'ok'],
    ['birleştir: yalnız verilen kayıt değişir, öteki ambardaki hâliyle', { durum: (() => { const b = birlestir({ a: { s: 1 }, b: { s: 2 } }, { a: { s: 9 }, b: { s: 7 } }, ['a']); return b.a.s === 9 && b.b.s === 2 ? 'ok' : 'x'; })() }, r => r.durum === 'ok'],
  ];
  let ok = 0; for (const [ad, r, t] of V) { const g = t(r); if (g) ok++; console.log((g ? '  ✓ ' : '  ✗ ') + ad); }
  return { ok, toplam: V.length };
}

module.exports = { karar, fark, esit, retCikabilir, retSecim, hakemRetIsle, elleKilitli, gecmeNedeni, yalnizModelIzi, retGuncelle, tazelikFarki, birlestir, notrModel, teslim, sahteDeneme };
if (require.main === module) {
  const [kmt, arg, yaz] = process.argv.slice(2);
  if (kmt === '--sinav') (async () => {
    const a = sinav(); const s = await sahteDeneme(true); let sok = 0;
    for (const [ad, g] of s) { if (g) sok++; console.log((g ? '  ✓ ' : '  ✗ ') + 'SAHTE AMBAR: ' + ad); }
    const ok = a.ok + sok, top = a.toplam + s.length;
    console.log(`ONARIM HATTI ÖZ-SINAVI ${ok === top ? 'YEŞİL' : 'KIRMIZI'} (${ok}/${top})`); process.exit(ok === top ? 0 : 1);
  })();
  else if (kmt === '--sahte') sahteDeneme(false).then(s => { for (const [ad, g] of s) console.log((g ? '✓ ' : '✗ ') + ad); process.exit(s.every(x => x[1]) ? 0 : 1); });
  else if (kmt === 'uygula') { const u = uygula(path.resolve(arg), yaz === '--yaz'); console.log(JSON.stringify({ aciklama: u.aciklama.length, rehakem: u.rehakem.length, red: u.red, atlanan: u.atlanan.length })); }
  else if (kmt === 'teslim') teslim(path.resolve(arg), { kuru: yaz === '--kuru' }).then(r => process.exit(r && (r.durum === 'bayat' || r.durum === 'yaris') ? 3 : 0)).catch(e => { console.error(e.message); process.exit(1); });
  else if (kmt === 'hakem') hakem(process.argv.slice(3)).catch(e => { console.error(e.message); process.exit(1); });
  else { console.log('komut: uygula|teslim|hakem|--sinav'); process.exit(2); }
}
