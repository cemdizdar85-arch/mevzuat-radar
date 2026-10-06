// ============================================================================
//  SEVİYE HAVUZU BASICI — "30 soruda geçme ihtimalini ölç" (seviye-testi.html) soru havuzu.
//
//  NEDEN (13.09.2026, Cem): "ilk testim müşteri çekmek için; bu sınavda kaç puan alırsın,
//  denetle tarzı; sınav kadar soru çözersek olmaz." -> 20 soruluk uyarlamalı test.
//
//  NE YAPAR
//   · 30 soruluk plan: her dersin sınavdaki payı × 30, en büyük artık yöntemiyle, her derse
//     en az 1 (veri/sgs-sinav-yapisi.json). Sonuç: FM 6, Denetim 4, Maliyet/MTA/Matematik/Türkçe/
//     YD/Ekonomi/Maliye 2'şer, kalan 6 ders 1'er - öz-sınav toplamın 30 ve dağılımın bu olduğunu doğrular.
//   · Dört grup (sonuç ekranı + karne maili): Muhasebe (FM, Maliyet, MTA, Denetim) · Hukuk
//     (Meslek, İş-SGK, Vergi, Ticaret, Borçlar) · Ekonomi ve Maliye · Genel Kültür ve Yabancı Dil.
//     Tek soruyla ders hakkında hüküm verilmez; grup düzeyinde gösterilir.
//   · Her ders × zorluk (kolay/zor/çok zor, soru kimliğindeki üretim etiketi) kutusundan en çok
//     KUTU soru: 06.10'dan beri KONU SIKLIĞINA göre (son 10 yılda en çok dönemde çıkan konular önce,
//     her konudan 1 soru; bkz. konuSiklik). Eşitlikte "Sınav gibi çöz" setlerinde OLMAYANLAR önce.
//   · Sayfa: aynı cihaza daha önce gösterilen soruyu tekrar göstermez, şık sırasını karıştırır.
//
//  ÇIKTI: veri/seviye/sgs-havuz.json · API maliyeti SIFIR. 29.09.2026'dan beri YALNIZ KİMLİK (id, sayfa, sıra):
//  soru metni ucretsiz_soru'dan cevapsız gelir, doğru mu kontrolü sunucuda (seviye_kontrol). Önceden 675 soru
//  cevabıyla açık dosyadaydı ve 16.09'dan beri tazelenmediği için 281'i yayından düşmüştü (29.09 ölçümü).
//  Bulutta yayin-bas.yml her yayında koşturur (sayfalar tam basıldıktan, kasa yüklemesinden ÖNCE).
//  Kaydır-Çöz SGS basımından sonra motor/kaydir-yayin.ps1 koşturur (deneme setlerinden SONRA).
// ============================================================================
const fs = require('fs');
const path = require('path');
const KOK = path.join(__dirname, '..');
const KURU = process.argv.includes('--kuru');
// 16.09.2026 — 20 -> 30 SORU (Cem kararı). Ölçüldü (benzetim, sitenin kendi modeliyle 700 sahte aday):
// tahminin gerçekten sapması 20 soruda ±12,5 puan · 30'da ±10,7 · 35'te ±10,1 · 40'ta ±9,4; geçer/kalır
// tersine çıkma 20'de %10,4 · 30'da %9,0. Kazancın çoğu 30'da alınıyor, sonrası düzleşiyor. Ayrıca 20 soruda
// 8 ders TEK soruyla temsil ediliyordu (tek soruyla ders hakkında hüküm verilemez); 30'da FM 6, Denetim 4.
// KUTU 10 -> 15: üye tekrar çözdüğünde aynı soruların dönmemesi için ders×zorluk kutusu büyütüldü.
const TEST_SORU = 30, KUTU = 15;
const ZORLUKLAR = ['kolay', 'zor', 'cokzor'];

const jsonOku = y => JSON.parse(fs.readFileSync(y, 'utf8').replace(/^﻿/, ''));
const katla = s => String(s || '').toLocaleLowerCase('tr').replace(/ı/g, 'i').replace(/ğ/g, 'g').replace(/ü/g, 'u').replace(/ş/g, 's').replace(/ö/g, 'o').replace(/ç/g, 'c').replace(/[^a-z0-9]+/g, ' ').trim();
const slug = s => katla(s).replace(/ /g, '-');
function sayfaOku(d) { const h = fs.readFileSync(d, 'utf8'); const b = h.indexOf('const SORULAR='); if (b < 0) return null; const e = h.indexOf('\n', b); const s = h.slice(b, e < 0 ? h.length : e); try { return JSON.parse(s.slice(s.indexOf('['), s.lastIndexOf(']') + 1)); } catch (x) { return null; } }
const zorluk = id => /cokzor/.test(id) ? 'cokzor' : /-zor/.test(id) ? 'zor' : /kolay/.test(id) ? 'kolay' : null;

const GRUP = {
  'finansal muhasebe': 'Muhasebe', 'maliyet muhasebesi': 'Muhasebe', 'mali tablolar analizi': 'Muhasebe', 'denetim': 'Muhasebe',
  'meslek hukuku': 'Hukuk', 'is ve sosyal guvenlik hukuku': 'Hukuk', 'vergi hukuku': 'Hukuk', 'ticaret hukuku': 'Hukuk', 'borclar hukuku': 'Hukuk',
  'ekonomi': 'Ekonomi ve Maliye', 'maliye': 'Ekonomi ve Maliye',
  'turkce': 'Genel Kültür ve Yabancı Dil', 'matematik': 'Genel Kültür ve Yabancı Dil', 'ataturk ilkeleri ve inkilap tarihi': 'Genel Kültür ve Yabancı Dil', 'yabanci dil': 'Genel Kültür ve Yabancı Dil'
};

const yapi = jsonOku(path.join(KOK, 'veri', 'sgs-sinav-yapisi.json')).sgs;
const dersler = []; yapi.bolumler.forEach(b => b.dersler.forEach(d => dersler.push({ ders: d.ders, sinav: d.soru })));
// 20 soruluk plan: en az 1, kalan en büyük artıkla
const toplam = dersler.reduce((t, d) => t + d.sinav, 0);
// artık = tam pay − VERİLEN adet. "En az 1"e yükseltilen dersin artığı eksiye düşer ve fazladan soru almaz.
// (İlk sürüm artığı floor'a göre alıyordu: Ekonomi 0,92 ile 2 soru kapıyordu, Yabancı Dil 1'de kalıyordu -
//  öz-sınav "FM 4 / Denetim 2 / YD 2" kontrolüyle yakaladı.)
dersler.forEach(d => { const tam = d.sinav * TEST_SORU / toplam; d.test = Math.max(1, Math.floor(tam)); d.artik = tam - d.test; });
let kalan = TEST_SORU - dersler.reduce((t, d) => t + d.test, 0);
dersler.slice().sort((a, b) => b.artik - a.artik).forEach(d => { if (kalan > 0) { d.test++; kalan--; } });

// 06.10.2026 KONU SIKLIĞI (Cem: "30 soruyu en çok çıkan konudan yapalım"): kutu önceden kimlik ALFABESİNE göre ilk KUTU soruydu
// (konu sıklığıyla ilgisiz). Artık her sorunun konusu çıkmış arşivindeki konu kümesine bağlanır (arac/sgs-konu-kapsama.js ile aynı
// yol: veri/sgs-analiz.json + veri/sinav/sgs-konu-es.json, ders kapısı dahil) ve kümenin SON 10 YILDA kaç dönemde çıktığı (w) bulunur.
// Kutu: her konudan en çok 1 soru, w büyükten küçüğe; eşitlikte deneme setinde olmayan önce. Sayfa kutudan w ağırlıklı seçer ve
// aynı konudan ikinci soru vermez (k). w İÇ PLANLAMA içindir (etiket sayımı) - dışarıya rakam olarak verilmez (SINAV RAKAMI KANITLI).
// 🚫 GÖRMEZ: arşiv etiketinin yanlış konuya bağlanması (sözlük örneklemle ölçüldü) · konu alanı boş/sözlükte olmayan soru (w=0, sona).
const katla2 = s => String(s || '').replace(/İ/g, 'I').replace(/ı/g, 'i').toLowerCase().replace(/i̇/g, 'i').replace(/ş/g, 's').replace(/ğ/g, 'g').replace(/ü/g, 'u')
  .replace(/ö/g, 'o').replace(/ç/g, 'c').replace(/[âà]/g, 'a').replace(/î/g, 'i').replace(/û/g, 'u').replace(/['’]/g, '').replace(/[^a-z0-9 ]/g, ' ').replace(/\s+/g, ' ').trim();
const SIK_YIL = 2016;
const konuEs = jsonOku(path.join(KOK, 'veri', 'sinav', 'sgs-konu-es.json')).esleme;
const kumeDonem = new Map(), etiketVar = new Set();
for (const d of jsonOku(path.join(KOK, 'veri', 'sgs-analiz.json')).donemler) {
  const yil = +String(d.donem).split('/')[0];
  for (const k of Object.keys(d.konuSayim || {})) {
    const a = katla2(k.replace(/^[^|]*\|/, '')); if (!a) continue; etiketVar.add(a);
    if (yil < SIK_YIL) continue;
    const kk = konuEs[a] ? konuEs[a].k : a; if (!kumeDonem.has(kk)) kumeDonem.set(kk, new Set()); kumeDonem.get(kk).add(d.donem);
  }
}
function konuSiklik(ders, konu) {
  const a = katla2(konu); if (!a) return { k: '', w: 0 };
  const hedef = etiketVar.has(a) ? a : (konuEs[a] && etiketVar.has(konuEs[a].k) ? konuEs[a].k : null);
  if (!hedef) return { k: a, w: 0 };
  const e = konuEs[a] || konuEs[hedef]; if (e && e.d && e.d !== ders && !/ayrılmadı/.test(e.d)) return { k: a, w: 0 };   // ders kapısı
  const kk = konuEs[hedef] ? konuEs[hedef].k : hedef;
  return { k: kk, w: (kumeDonem.get(kk) || new Set()).size };
}

const setIdleri = new Set();
try { const dz = jsonOku(path.join(KOK, 'veri', 'deneme', 'sgs-dizin.json')); dz.setler.forEach(s => jsonOku(path.join(KOK, s.dosya)).sorular.forEach(q => setIdleri.add(q.id))); } catch (e) {}

// 29.09.2026 ADIM 2: kasa modundaki sayfa depoda SORUSUZ kabuktur (motor/kasa-kabuk.js). Kabuğun soruları
// paket_soru'dan (sayfa + sıra) okunur - yalnız SUPABASE_SERVICE_KEY varsa; yoksa o ders "sayfa yok" düşer
// (tahminle havuz kurulmaz). Bulutta (yayin-bas.yml) sayfalar tam basıldıktan sonra koşar, kasaya gitmez.
const UA = 'tetikte-seviye-havuz/1.0';
async function kasadanOku(yol) {
  const K = process.env.SUPABASE_SERVICE_KEY; if (!K) return null;
  const h = { apikey: K, Authorization: 'Bearer ' + K, 'User-Agent': UA };
  const S = [];
  for (let i = 0; ; i += 500) {
    const r = await fetch('https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/paket_soru?select=sira,veri&sayfa=eq.' + encodeURIComponent(yol) + '&order=sira.asc&limit=500&offset=' + i, { headers: h });
    if (!r.ok) throw new Error(`kasa okuma ${yol}: HTTP ${r.status}`);
    const p = await r.json(); p.forEach(x => { S[x.sira] = x.veri; });
    if (p.length < 500) break;
  }
  return S.length && S.every(Boolean) ? S : null;   // sırada boşluk = eksik yükleme -> kullanılmaz
}

(async () => {
const sayfalar = {};
for (const f of fs.readdirSync(path.join(KOK, 'kaydir', 'sgs'))) {
  if (!f.endsWith('.html') || f === 'index.html') continue;
  const yol = `kaydir/sgs/${f}`, tam = path.join(KOK, 'kaydir', 'sgs', f);
  let S = sayfaOku(tam);
  if ((!S || !S.length) && fs.readFileSync(tam, 'utf8').includes('data-kasa-sayfa=')) S = await kasadanOku(yol);
  if (!S || !S.length) continue;
  const ad = String(S[0].ders || '').split('|')[0].trim(); if (slug(ad) + '.html' !== f) continue;
  sayfalar[katla(ad)] = { ad, dosya: yol, S };
}

const hatalar = [], havuz = {}, plan = [], rapor = [], siklikRapor = [];
for (const d of dersler) {
  const k = katla(d.ders), p = sayfalar[k];
  if (!p) { hatalar.push('ders sayfası yok: ' + d.ders); continue; }
  if (!GRUP[k]) { hatalar.push('grup eşlemesi yok: ' + d.ders); continue; }
  plan.push({ ders: p.ad, grup: GRUP[k], adet: d.test });
  havuz[p.ad] = {};
  const satir = [];
  for (const z of ZORLUKLAR) {
    const uygun = p.S.map((s, sira) => ({ s, sira })).filter(x => zorluk(String(x.s.id)) === z && x.s.soru && x.s.siklar && Object.keys(x.s.siklar).length === 5 && x.s.siklar[x.s.dogru])
      .sort((a, b) => String(a.s.id).localeCompare(String(b.s.id)));
    // eski seçim (alfabe) yalnız karşılaştırma raporu için
    const eski = uygun.filter(x => !setIdleri.has(x.s.id)).slice(0, KUTU).concat(uygun.filter(x => setIdleri.has(x.s.id))).slice(0, KUTU);
    uygun.forEach(x => Object.assign(x, konuSiklik(p.ad, x.s.konu)));
    const sirali = uygun.slice().sort((a, b) => b.w - a.w || (setIdleri.has(a.s.id) - setIdleri.has(b.s.id)) || String(a.s.id).localeCompare(String(b.s.id)));
    const secilen = [], konular = new Set();
    for (const x of sirali) { if (secilen.length >= KUTU) break; if (x.k && konular.has(x.k)) continue; secilen.push(x); if (x.k) konular.add(x.k); }
    for (const x of sirali) { if (secilen.length >= KUTU) break; if (!secilen.includes(x)) secilen.push(x); }   // konu yetmezse doldur
    if (secilen.length < d.test) hatalar.push(`${p.ad} ${z}: ${secilen.length} soru, en az ${d.test} gerekli`);
    // 29.09 ADIM 2: dosya herkese açık -> YALNIZ kimlik (+ konu kümesi k, sıklık w). Metin ucretsiz_soru'dan (cevapsız), doğru seviye_kontrol'den.
    havuz[p.ad][z] = secilen.map(x => ({ id: x.s.id, sayfa: p.dosya, sira: x.sira, k: x.k, w: x.w }));
    const ort = L => L.length ? (L.reduce((t, x) => t + (x.w != null ? x.w : konuSiklik(p.ad, x.s.konu).w), 0) / L.length).toFixed(1) : '-';
    // öz-sınav konu bazında kıyaslar (yeninin İLK n konusu, n = eskinin konu sayısı): eski seçim aynı sık konudan birkaç soru alabiliyordu, yeni seçim her konudan 1 (bilerek çeşitlilik)
    const konuOrt = L => { const m = new Map(); L.forEach(x => { const s = konuSiklik(p.ad, x.s.konu); m.set(s.k || x.s.id, s.w); }); const v = [...m.values()]; return v.length ? v.reduce((t, w) => t + w, 0) / v.length : 0; };
    siklikRapor.push({ ders: p.ad, z, eski: +ort(eski) || 0, yeni: +ort(secilen) || 0, eskiK: konuOrt(eski), yeniK: konuOrt(secilen.slice(0, new Set(eski.map(x => konuSiklik(p.ad, x.s.konu).k)).size)), konuEski: new Set(eski.map(x => konuSiklik(p.ad, x.s.konu).k)).size, n: secilen.length, sifir: secilen.filter(x => !x.w).length });
    satir.push(`${z} ${secilen.length} (ort. dönem eski ${ort(eski)} -> yeni ${ort(secilen)})`);
  }
  rapor.push(`${p.ad.padEnd(34)} testte ${d.test} · ${satir.join(' · ')}`);
}

// ÖZ-SINAV
const planToplam = plan.reduce((t, x) => t + x.adet, 0);
if (planToplam !== TEST_SORU) hatalar.push(`plan toplamı ${planToplam} (beklenen ${TEST_SORU})`);
const fm = plan.find(x => katla(x.ders) === 'finansal muhasebe'), den = plan.find(x => katla(x.ders) === 'denetim'), yd = plan.find(x => katla(x.ders) === 'yabanci dil');
// 16.09: 30 soruluk planın beklenen dağılımı (sınav payından: FM 26/130, Denetim 16/130, YD 10/130)
if (!fm || fm.adet !== 6 || !den || den.adet !== 4 || !yd || yd.adet !== 2) hatalar.push('plan dağılımı beklenenden farklı (FM 6 / Denetim 4 / YD 2)');
if (plan.some(x => x.adet < 1)) hatalar.push('sıfır sorulu ders var');
const grupToplam = {}; plan.forEach(x => grupToplam[x.grup] = (grupToplam[x.grup] || 0) + x.adet);
// 06.10 öz-sınav: konu sıklığı seçimi eskisinden kötü olamaz (her kutuda yeni ort. >= eski ort.); bir kutuda konu bulunamazsa uyarı
siklikRapor.forEach(r => { if (r.yeniK + 1e-9 < r.eskiK) hatalar.push(`${r.ders} ${r.z}: konu sıklığı eskisinden düşük (${r.yeniK.toFixed(1)} < ${r.eskiK.toFixed(1)})`); });
const sifirKutu = siklikRapor.filter(r => r.sifir === r.n);

console.log('SEVİYE HAVUZU (SGS)');
rapor.forEach(r => console.log('  ' + r));
console.log('  grup başına soru:', JSON.stringify(grupToplam));
{ const t = k => (siklikRapor.reduce((s, r) => s + r[k] * r.n, 0) / Math.max(1, siklikRapor.reduce((s, r) => s + r.n, 0))).toFixed(1);
  console.log(`  KONU SIKLIĞI: kutudaki sorunun konusu son 10 yılda (${SIK_YIL}+) ortalama kaç dönemde çıktı - eski seçim ${t('eski')} · yeni ${t('yeni')}`
    + (sifirKutu.length ? ` · ⚠ konusu bağlanamayan kutu: ${sifirKutu.map(r => r.ders + ' ' + r.z).join(', ')}` : '')); }
if (hatalar.length) { console.log('KIRMIZI - yazılmadı:'); hatalar.forEach(h => console.log('  · ' + h)); process.exit(1); }
if (KURU) { console.log('  kuru koşu - yazılmadı'); process.exit(0); }

const cikti = { uretici: 'motor/seviye-havuz-bas.js', sinav: 'sgs', test_soru: TEST_SORU, plan, havuz };
const hedef = path.join(KOK, 'veri', 'seviye', 'sgs-havuz.json');
fs.mkdirSync(path.dirname(hedef), { recursive: true });
const yeni = JSON.stringify(cikti) + '\n';
let eski = null; try { eski = fs.readFileSync(hedef, 'utf8'); } catch (e) {}
if (eski === yeni) console.log('  değişiklik yok - dosyaya dokunulmadı');
else { fs.writeFileSync(hedef, yeni, 'utf8'); console.log(`  yazıldı -> veri/seviye/sgs-havuz.json (${Math.round(yeni.length / 1024)} KB)`); }
})().catch(e => { console.error('SEVİYE HAVUZU DÜŞTÜ: ' + e.message); process.exit(1); });
