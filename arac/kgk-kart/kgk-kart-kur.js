// KGK KONU KARTI — ölçülebilir alanlar (bedel 0). BITIRME-SORU-STANDARDI K1'in KGK eşi (Cem 05.11, DEVIR §3; bitirme kart-kur.js biçimi).
// Veri: konu-profil-gercek.json (3.893 çıkmış KGK sorusu 2016+, metin↔konu bağı içerikle, elle kalıp) + kalip/ayirici-girdi-yeni.json (kök+şık metni)
//   + veri/fabrika/kgk-konu-kapsama.csv (son 10 yıl, sitede, hedef, eksik).
// Her konu: dönem sayısı · son dönem · soru sayısı · son örnekler · GERÇEK kalıp DAĞILIMI (K8) · kök hedefi (konu medyanı ±%25) · şık medyanı ·
//   şık türü · olumsuz/öncüllü/hesap payı. Okuyucunun dolduracağı alanlar boş: ne_sorar, dayanak, celdirici, yazim_notu.
// Çıkmışta 3'ten az soru → kalıp yine gerçek sorulardan; kök/şık hedefi o kalıbın MODÜL medyanından (tahmini_hedef: true).
// GÖRMEZ: elle kalıp etiketinin okuyucu hatası · konu bağının (bagla.js) ölçülmüş %0–9 kayması · 2013–2015 ve Kasım 2018 (metin bozuk, yok) ·
//   beceri düzeyi (KGK'da elle ölçülmedi; hesap payından TÜRETİLİR, "beceri_kaynak" alanı bunu söyler).
// node kgk-kart-kur.js <depo> [--yaz]  → kart/kartlar/<KOD>.json
'use strict';
const fs = require('fs'), path = require('path');
const IS = path.join(__dirname, '..'), D = __dirname, oku = p => JSON.parse(fs.readFileSync(p, 'utf8').replace(/^\uFEFF/, ''));
const depo = process.argv[2] || 'C:/TETIKTE-CALISMA/kgk-basim', YAZ = process.argv.includes('--yaz');
const P = oku(path.join(IS, 'konu-profil-gercek.json')).konu, G = oku(path.join(IS, 'kalip', 'ayirici-girdi-yeni.json'));
const es = oku(path.join(IS, 'kgk-konu-es.json')).esleme;
const katla = s => String(s).replace(/İ/g, 'I').replace(/ı/g, 'i').toLowerCase().replace(/i̇/g, 'i').replace(/ş/g, 's').replace(/ğ/g, 'g').replace(/ü/g, 'u').replace(/ö/g, 'o').replace(/ç/g, 'c').trim();
const kume = k => { const e = es[katla(k)] || es[k]; return e ? e.k : k; };
const MOD = { 'a) Türkiye Muhasebe Standartları': 'TMS', 'b) Türkiye Denetim Standartları': 'TDS', 'c) Finansal Yönetim': 'FY', 'c) Kurumsal Yönetim': 'KY',
  'ç) Sermaye Piyasası Mevzuatı': 'SPK', 'd) Bankacılık Mevzuatı': 'BANKA', 'e) Sigortacılık ve Özel Emeklilik': 'SIGORTA', 'f) Sürdürülebilirlik Raporlaması': 'TSRS', 'g) Sürdürülebilirlik Denetimi': 'GDS' };
const SIRA = ['TSRS', 'GDS', 'SIGORTA', 'BANKA', 'SPK', 'KY', 'FY', 'TMS', 'TDS'];
const KAD = { A: 'doğrudur', B: 'yanlıştır', C: 'değildir/sayılmaz', U: 'sayılır/kapsam', D: 'öncüllü', E: 'boşluk', G: 'süre/oran/eşik ezberi', F: 'hesap', L: 'sırasıyla', I: 'defter kaydı', J: 'hangi hesap', K: 'kayıt→işlem', M: 'tanım↔terim', N: 'yetkili merci', O: 'ceza/suç', P: 'durum→davranış', S: 'grafik/tablo' };
const SIK = { A: 'hüküm cümlesi', B: 'hüküm cümlesi (biri tek noktası bozuk)', C: 'kısa kalem/terim', U: 'kısa kalem/terim', D: '"Yalnız I", "I ve II"…', E: 'boşluğa gelecek ifade(ler)', G: 'sıralı sayı/süre/oran', F: 'sıralı sayı', L: 'sıralı değer grupları', I: 'kod + hesap adı + tutar satırları', J: 'hesap adı', K: 'işlem cümlesi', M: 'aynı aileden 5 terim/tanım', N: 'kurum/merci adı', O: 'ceza/suç adı', P: 'davranış/görüş cümlesi', S: 'kısa yorum cümlesi' };
const med = a => { const s = a.filter(x => x > 0).sort((x, y) => x - y); return s.length ? s[Math.floor(s.length / 2)] : null; };
const AY = { Ocak: 1, Şubat: 2, Mart: 3, Nisan: 4, Mayıs: 5, Haziran: 6, Temmuz: 7, Ağustos: 8, Eylül: 9, Ekim: 10, Kasım: 11, Aralık: 12 };
const tarih = d => { const m = String(d).match(/(\d+)\s+(\S+)\s+(\d{4})/); return m ? +m[3] * 10000 + (AY[m[2]] || 0) * 100 + +m[1] : 0; };
// metin dizini: dönem|no|kume(konu) → şıklar
const MT = {}; let gMetin = 0;
for (const q of G) { const k = `${q.donem}|${q.no}|${kume(q.konu)}`; MT[k] = q; }
// kapsama
const csv = fs.readFileSync(path.join(depo, 'veri/fabrika/kgk-konu-kapsama.csv'), 'utf8').replace(/^\uFEFF/, '').split(/\r?\n/).slice(1).filter(Boolean).map(l => l.split(';').map(x => x.replace(/^"|"$/g, '')));
const KP = {}; for (const r of csv) KP[r[1]] = { diger: r[2], son10: +r[3], sinav: +r[4], sitede: +r[7], hedef: +r[8], durum: r[9], eksik: +r[10] };
// modül × kalıp medyanları (seyrek konu yedeği)
const MK = {};
for (const p of Object.values(P)) for (const x of p.sorular) { const q = MT[`${x.donem}|${x.no}|${kume(Object.keys(P).find(k => P[k] === p))}`]; const r = ((MK[p.modul] ||= {})[x.kalip] ||= { kok: [], sik: [] }); r.kok.push(x.uz); if (q) r.sik.push(med(q.siklar.map(s => String(s).length))); }
const out = {}; let n = 0, eslesen = 0, soruT = 0;
for (const [konu, p] of Object.entries(P)) {
  const kod = MOD[p.modul]; if (!kod) continue; const L = p.sorular; soruT += L.length;
  const kal = {}; for (const x of L) if (x.kalip) kal[x.kalip] = (kal[x.kalip] || 0) + 1;
  const sikU = []; for (const x of L) { const q = MT[`${x.donem}|${x.no}|${konu}`]; if (q) { eslesen++; sikU.push(med(q.siklar.map(s => String(s).length))); } }
  const seyrek = L.length < 3, ks = Object.entries(kal).sort((a, b) => b[1] - a[1]);
  const kokM = seyrek ? med(ks.flatMap(([h]) => (MK[p.modul][h] || { kok: [] }).kok)) : med(L.map(x => x.uz));
  const sikM = seyrek ? med(ks.flatMap(([h]) => (MK[p.modul][h] || { sik: [] }).sik)) : med(sikU);
  const donemler = [...new Set(L.map(x => x.donem))].sort((a, b) => tarih(a) - tarih(b));
  const pay = f => Math.round(100 * L.filter(f).length / L.length);
  const kp = KP[konu] || {};
  (out[kod] ||= []).push({
    modul: p.modul, konu, diger_adlar: kp.diger || '', donem_sayisi: donemler.length, son_donem: donemler.slice(-1)[0] || '', soru_sayisi: L.length,
    son10: kp.son10 ?? null, sitede: kp.sitede ?? null, hedef: kp.hedef ?? null, eksik: kp.eksik ?? null,
    ornek: L.slice().sort((a, b) => tarih(b.donem) - tarih(a.donem)).slice(0, 3).map(x => `${x.donem} S${x.no}`),
    kalip: ks.map(([h, c]) => `${h} ${KAD[h] || h} ×${c}`), kalip_dagilim: Object.fromEntries(ks),
    tahmini_hedef: seyrek, beceri: L.some(x => x.hsp) ? (pay(x => x.hsp) >= 50 ? ['UYGULAMA'] : ['BILGI', 'UYGULAMA']) : ['BILGI'], beceri_kaynak: 'türetilmiş (hesap payı) — KGK beceri elle ÖLÇÜLMEDİ',
    kok_hedef_kr: kokM ? [Math.round(kokM * 0.75), Math.round(kokM * 1.25)] : null, sik_medyan_kr: sikM, sik_turu: [...new Set(ks.map(([h]) => SIK[h] || h))],
    olumsuz_pay: pay(x => x.olm), oncullu_pay: pay(x => x.onc), hesap_pay: pay(x => x.hsp),
    ne_sorar: '', dayanak: '', celdirici: '', yazim_notu: ''
  }); n++;
}
for (const k of Object.keys(out)) out[k].sort((a, b) => (b.son10 || 0) - (a.son10 || 0) || b.soru_sayisi - a.soru_sayisi || b.donem_sayisi - a.donem_sayisi);
for (const k of SIRA) if (out[k]) console.log(k.padEnd(8), String(out[k].length).padStart(4), 'kart ·', out[k].filter(c => !c.tahmini_hedef).length, 'konu hedefli ·', out[k].filter(c => c.tahmini_hedef).length, 'modül yedekli · son10≥2:', out[k].filter(c => c.son10 >= 2).length);
console.log(`toplam ${n} kart · ${soruT} soru · şık metni eşleşen ${eslesen} (%${Math.round(100 * eslesen / soruT)})`);
if (YAZ) { fs.mkdirSync(path.join(D, 'kartlar'), { recursive: true }); for (const [k, a] of Object.entries(out)) fs.writeFileSync(path.join(D, 'kartlar', `${k}.json`), JSON.stringify(a, null, 1) + '\n'); console.log('yazıldı kart/kartlar/*.json'); }
