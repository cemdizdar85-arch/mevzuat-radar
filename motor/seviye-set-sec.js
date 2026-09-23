// ============================================================================
//  SEVİYE TESTİ SABİT SETİ SEÇİCİ (23.09.2026)
//
//  Cem 23.09: "30 soru çözüp seviyelerini ölçecekler, kazanma ihtimallerini ... sadece 30 soru görecekler,
//  biz 30 soruyu istediğimiz gibi değiştireceğiz" + "çıkmış sınav sorularına göre hangi soru sınavda daha fazla
//  soruluyorsa ona göre ayarlamamız lazım". Havuz/uyarlamalı seçim YOK: her sınavın SABİT 30 soruluk seti.
//
//  SEÇİM KURALI (yalnız ölçülü veriden):
//   · DERS PAYI = Cem kararı 23.09 ("önerimden"): FM 5 · Maliyet 5 · FTA 4 · Vergi 4 · Denetim/Hukuk/Meslek/SPK 3.
//     Ölçüm (veri/smmm-analiz.json): 2026 test biçiminde her ders 20 soru, her biri ayrı notlanır (m.16/b) - resmî
//     ağırlık eşit; FM ve Maliyet'e fazladan pay Cem'in "sınavda en değerli dersler" tercihi. Sıklık ders düzeyine
//     taşınmaz: analizde FM'nin her yevmiye satırı ayrı "soru" sayılıyor (klasik dönem ort. 44/sınav).
//   · KONU: ders içinde veri/fabrika/smmm-kapsama.csv `son10` (son 10 yılda kaç kez soruldu) büyükten küçüğe;
//     son10 = 0 konu sete GİRMEZ (CLAUDE.md 0b son 10 yıl kuralı). Her konudan en çok 1 soru.
//   · SORU: kasada (paket_soru, sinav=smmm) yayındaki soru; hakem EVET + öğrenci simülasyonu doğru; hariç listesi
//     (arac/vitrin-haric.json: kimlik + konu) uygulanır; vitrindeki 70 soru mümkünse ALINMAZ (günün kartı set
//     sorusunu ele vermesin).
//   · ZORLUK: --zorluk kolay/zor/cokzor yüzdesi (varsayılan 20/50/30 -> 6/15/9); yuvalar derslere sırayla dağıtılır,
//     konunun o zorlukta sorusu yoksa en yakın zorluk alınır (sayım raporda).
//
//  ÇIKTI: veri/seviye/<sinav>-set.json - YALNIZ KİMLİK + ders/konu/zorluk/son10 (soru metni depoya GİRMEZ).
//  Set elle okunup onaylanmadan yayına alınmaz: "onay" alanı boş basılır.
//  GÖRMEZ: konu etiketinin soruyla uyumunu (23.09 vitrin ölçümü: 94 sorudan 20'si yanlış etiketli) -> elle okuma şart.
//
//  Kullanım: node motor/seviye-set-sec.js smmm [--adet 30] [--zorluk 20/50/30] [--kuru]
//  Kasa okuması için SUPABASE_SERVICE_KEY ortam değişkeni gerekir.
// ============================================================================
const fs = require('fs');
const path = require('path');
const KOK = path.resolve(__dirname, '..');
const argv = process.argv.slice(2);
const al = (ad, vars) => { const i = argv.indexOf(ad); return i >= 0 ? argv[i + 1] : vars; };
const SINAV = argv.find(a => !a.startsWith('--') && argv[argv.indexOf(a) - 1] !== '--adet' && argv[argv.indexOf(a) - 1] !== '--zorluk') || 'smmm';
const ADET = parseInt(al('--adet', '30'), 10);
const ZOR = al('--zorluk', '20/50/30').split('/').map(Number);
const KURU = argv.includes('--kuru');
const ZORLUKLAR = ['kolay', 'zor', 'cokzor'];
if (SINAV !== 'smmm') { console.error('şimdilik yalnız smmm (Yeterlilik): kapsama tablosu yalnız bitirmede var'); process.exit(2); }
if (ZOR.length !== 3 || ZOR.some(isNaN)) { console.error('--zorluk kolay/zor/cokzor, ör. 20/50/30'); process.exit(2); }

const jsonOku = y => JSON.parse(fs.readFileSync(y, 'utf8').replace(/^﻿/, ''));
const katla = s => String(s || '').split('|')[0].toLocaleLowerCase('tr')
  .replace(/ç/g, 'c').replace(/ğ/g, 'g').replace(/ı/g, 'i').replace(/i̇/g, 'i').replace(/ö/g, 'o').replace(/ş/g, 's').replace(/ü/g, 'u')
  .replace(/\s+/g, ' ').trim();
// kapsama tablosu ile kasa ders adları farklı yazılıyor (23.09 ölçüldü: Meslek Hukuku eşleşmiyordu, set 7 derse düştü)
const DERS_ES = { 'muh. ve mali mus. meslek hukuku': 'meslek hukuku' };
const dersK = s => { const k = katla(s); return DERS_ES[k] || k; };
const KOTA = { 'finansal muhasebe': 5, 'maliyet muhasebesi': 5, 'finansal tablolar ve analizi': 4, 'vergi mevzuati ve uygulamasi': 4,
  'muhasebe denetimi': 3, 'hukuk': 3, 'meslek hukuku': 3, 'sermaye piyasasi mevzuati': 3 };
const zorluk = id => /cokzor/.test(id) ? 'cokzor' : /-zor/.test(id) ? 'zor' : /kolay/.test(id) ? 'kolay' : null;

// --- kapsama tablosu (son10) ---
function csvSatir(s) { const o = []; let c = '', q = false; for (const h of s) { if (h === '"') q = !q; else if (h === ',' && !q) { o.push(c); c = ''; } else c += h; } o.push(c); return o; }
const csvYol = path.join(KOK, 'veri', 'fabrika', 'smmm-kapsama.csv');
const satirlar = fs.readFileSync(csvYol, 'utf8').replace(/^﻿/, '').split(/\r?\n/).filter(Boolean);
const bas = csvSatir(satirlar[0]);
const kapsama = {};
for (const s of satirlar.slice(1)) {
  const r = csvSatir(s); const o = {}; bas.forEach((b, i) => o[b] = r[i]);
  if (String(o.ders).includes(' / ')) continue;   // "A / B" ortak konular: ders payını karıştırmasın
  const k = dersK(o.ders) + '|' + katla(o.konu);
  const onceki = kapsama[k];
  if (!onceki || +o.son10 > onceki.son10) kapsama[k] = { son10: +o.son10 || 0, cikmis: +o.cikmis || 0, son_soruldu: o.son_soruldu || '' };
}
const csvYas = (Date.now() - fs.statSync(csvYol).mtimeMs) / 3600000;
if (csvYas > 24) console.warn(`⚠ kapsama tablosu ${Math.round(csvYas)} saat eski - önce arac/smmm-kapsama-tablosu.ps1`);

// --- hariç + vitrin ---
let haric = {}, haricKonu = {};
try { const h = jsonOku(path.join(KOK, 'arac', 'vitrin-haric.json')); haric = h.haric || {}; haricKonu = h.haric_konu || {}; } catch (e) {}
const vitrin = new Set();
try { for (const x of jsonOku(path.join(KOK, 'veri', 'sinav', 'kaydir-secim', 'vitrin-smmm-secim.json'))) vitrin.add(x.etiket + '/' + x.id); } catch (e) {}

(async () => {
  const K = process.env.SUPABASE_SERVICE_KEY;
  if (!K) throw new Error('SUPABASE_SERVICE_KEY yok - kasa okunamaz');
  const hd = { apikey: K, Authorization: 'Bearer ' + K };
  const kasa = [];
  for (let i = 0; ; i += 500) {
    const r = await fetch('https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/paket_soru?select=id,ders,konu,veri&sinav=eq.smmm&order=id.asc&limit=500&offset=' + i, { headers: hd });
    if (!r.ok) throw new Error('kasa okunamadı: HTTP ' + r.status);
    const p = await r.json(); kasa.push(...p); if (p.length < 500) break;
  }

  // ders -> konu -> zorluk -> [soru]
  const agac = {}, dersAd = {}, sayac = { kasa: kasa.length, haric: 0, olcum: 0, kapsamasiz: 0, son10sifir: 0, zorluksuz: 0 };
  for (const r of kasa) {
    const v = r.veri || {}, o = v.olcum || {};
    const dk = dersK(r.ders), kk = katla(r.konu || v.konu);
    if (haric[r.id] || haricKonu['smmm|' + kk]) { sayac.haric++; continue; }
    if (String(o.hakem) !== 'EVET' || !(o.sim && o.sim.dogru === true)) { sayac.olcum++; continue; }
    const kp = kapsama[dk + '|' + kk];
    if (!kp) { sayac.kapsamasiz++; continue; }
    if (!(kp.son10 > 0)) { sayac.son10sifir++; continue; }
    const z = zorluk(r.id); if (!z) { sayac.zorluksuz++; continue; }
    dersAd[dk] = r.ders;
    const kon = ((agac[dk] = agac[dk] || {})[kk] = agac[dk][kk] || { konu: r.konu || v.konu, ...kp, z: { kolay: [], zor: [], cokzor: [] } });
    kon.z[z].push({ id: r.id, vitrinde: vitrin.has(r.id) });
  }
  const dersler = Object.keys(agac);
  if (!dersler.length) throw new Error('aday yok');

  // ders kotası: Cem kararı (KOTA); tabloda olmayan ders ya da toplam ADET değilse DUR
  const eksik = Object.keys(KOTA).filter(d => !agac[d]), fazla = dersler.filter(d => !(d in KOTA));
  if (eksik.length || fazla.length) throw new Error('ders eşleşmedi - eksik: ' + eksik.join(',') + ' · tanımsız: ' + fazla.join(','));
  const kota = { ...KOTA };
  if (Object.values(kota).reduce((a, b) => a + b, 0) !== ADET) throw new Error('KOTA toplamı ' + ADET + ' değil');

  // zorluk yuvaları: 6/15/9 gibi, dersler sırasıyla (her derste karışık olsun diye) dağıtılır
  const zAdet = ZOR.map(p => Math.floor(ADET * p / 100));
  let zk = ADET - zAdet.reduce((a, b) => a + b, 0);
  ZOR.map((p, i) => ({ i, art: ADET * p / 100 - zAdet[i] })).sort((a, b) => b.art - a.art).forEach(x => { if (zk > 0) { zAdet[x.i]++; zk--; } });
  const yuvalar = []; ZORLUKLAR.forEach((z, i) => { for (let n = 0; n < zAdet[i]; n++) yuvalar.push(z); });
  // dersleri kota kadar tekrar eden sıra (serpiştirilmiş) -> her yuvaya bir ders
  const dersSira = []; const kalanKota = { ...kota };
  while (dersSira.length < ADET) for (const d of dersler) if (kalanKota[d] > 0) { dersSira.push(d); kalanKota[d]--; }
  const dersYuva = {}; dersSira.forEach((d, i) => (dersYuva[d] = dersYuva[d] || []).push(yuvalar[i]));

  const set = [], yakin = { istenen_yok: 0 };
  for (const d of dersler) {
    const konular = Object.values(agac[d]).sort((a, b) => b.son10 - a.son10 || b.cikmis - a.cikmis || a.konu.localeCompare(b.konu, 'tr'));
    const istek = dersYuva[d].slice(), kullan = new Set();
    // 1. tur: yalnız istenen zorluk, sık konudan seyreğe; 2. tur (yetmezse): kalan konudan en yakın zorluk
    for (const tur of [1, 2]) {
      for (const kon of konular) {
        if (!istek.length) break;
        if (kullan.has(kon.konu)) continue;
        let secZ = istek.find(z => kon.z[z].length), kaydir = false;
        if (!secZ && tur === 2) { secZ = ['cokzor', 'zor', 'kolay'].find(z => kon.z[z].length); kaydir = true; }
        if (!secZ) continue;
        const q = kon.z[secZ].slice().sort((x, y) => (x.vitrinde - y.vitrinde) || x.id.localeCompare(y.id))[0];
        istek.splice(kaydir ? 0 : istek.indexOf(secZ), 1); kullan.add(kon.konu);
        if (kaydir) yakin.istenen_yok++;
        set.push({ id: q.id, ders: dersAd[d], konu: kon.konu, zorluk: secZ, son10: kon.son10, cikmis: kon.cikmis, son_soruldu: kon.son_soruldu, vitrinde: q.vitrinde });
      }
    }
    if (istek.length) console.warn(`⚠ ${dersAd[d]}: ${istek.length} yuva doldurulamadı (son10>0 konu yetmedi)`);
  }

  const zSay = {}; set.forEach(s => zSay[s.zorluk] = (zSay[s.zorluk] || 0) + 1);
  console.log(`SEVİYE SETİ (${SINAV}) · kasa ${sayac.kasa} · hariç ${sayac.haric} · hakem/sim düşen ${sayac.olcum} · kapsamada yok ${sayac.kapsamasiz} · son10=0 ${sayac.son10sifir} · zorluksuz ${sayac.zorluksuz}`);
  console.log(`  seçilen ${set.length}/${ADET} · zorluk ${ZORLUKLAR.map(z => z + ' ' + (zSay[z] || 0)).join(' · ')} (hedef ${zAdet.join('/')}; konuda istenen zorluk yok -> kaydırılan ${yakin.istenen_yok}) · vitrinde olan ${set.filter(s => s.vitrinde).length}`);
  for (const d of dersler) console.log(`  ${dersAd[d]}: ${set.filter(s => s.ders === dersAd[d]).map(s => `${s.konu} [${s.son10}/${s.zorluk}]`).join(' · ')}`);
  if (set.length !== ADET) { console.error('KIRMIZI: set ' + set.length + ' soru, beklenen ' + ADET + ' - yazılmadı'); process.exit(3); }
  if (KURU) { console.log('  kuru - yazılmadı'); return; }
  const cikti = {
    uretici: 'motor/seviye-set-sec.js', sinav: SINAV, adet: ADET, zorluk_yuzde: ZOR.join('/'),
    kural: 'ders payı FM5 Maliyet5 FTA4 Vergi4 diğer 3 (Cem 23.09) · ders içinde konu son10 büyükten küçüğe, son10=0 yok · konu başı 1 soru · hakem EVET + sim doğru · arac/vitrin-haric.json',
    kapsama_tarih: new Date(fs.statSync(csvYol).mtimeMs).toISOString(),
    onay: null,   // elle okunup Cem'e gösterildikten sonra doldurulur; onaysız set yayına alınmaz
    sorular: set.map(({ vitrinde, ...s }) => s)
  };
  const hedef = path.join(KOK, 'veri', 'seviye', SINAV + '-set.json');
  fs.mkdirSync(path.dirname(hedef), { recursive: true });
  fs.writeFileSync(hedef, JSON.stringify(cikti, null, 2) + '\n', 'utf8');
  console.log('  yazıldı -> ' + path.relative(KOK, hedef));
})().catch(e => { console.error(e.message); process.exit(4); });
