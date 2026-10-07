#!/usr/bin/env node
// ============================================================================
//  SIK ÇIKAN KONULAR DENEMESİ — set basıcısı (07.10.2026, Cem: "sınava yaklaşmadan en çok çıkan konulardan sınav" →
//  "bu ücretli olsun, üye çekelim" → "site üst tarafında görsünler ama ücretli olsun" → "uygun").
//
//  KONU LİSTESİ (dışarı giden): en-cok-cikan-konular sayfalarıyla AYNI liste, AYNI sıralama — okunarak sayılmış çıkmış soru
//    · SGS: veri/sinav/sgs-konu-okuma.json → Matematik hariç en sık 20 konu (motor/en-cok-cikan.js mantığı)
//    · Yeterlilik: veri/sinav/smmm-konu-okuma.json → her dersin en sık 5 konusu (motor/en-cok-cikan-yeterlilik.js mantığı)
//  SORU → KONU BAĞI (iç, dışarı rakam olarak gitmez):
//    · SGS: konunun okuma ifadesi (sgs-konu-okuma.json "ifade") sitedeki sorunun kökü + konu etiketine uygulanır; aynı ders şartı.
//      Elle okundu (07.10, 20 konu × 2 = 40 soru): 38 doğru konu, 2 sınırda (ücret ↔ kişisel çıkar; görüş ↔ açılış
//      bakiyesi). Ücret konusu için daraltılmış ifade aşağıda (DARALT).
//    · Yeterlilik: veri/sinav/smmm-banka-esleme.json (sitedeki soru, okunmuş konu).
//  BİÇİM: SGS 40 soru (20 konu × 2), 50 dk (gerçek sınavın soru başı süresi 165/130 ≈ 1,27 dk) · Yeterlilik ders başına
//    20 soru, 45 dk, yanlış 0,25 götürür (2026 düzeni; deneme.html Birebir Prova ile aynı).
//  SETLER: konu havuzu kart dağıtır gibi bölünür → setler arası AYNI SORU YOK. Bir soru birden çok konuya uyuyorsa yalnız
//    en sık konuya sayılır.
//  ÇIKTI: veri/deneme/<sgs|smmm>-sik-dizin.json + <sinav>-sik-set-NN.json — YALNIZ KİMLİK (metin/cevap sinav-gibi.html'de
//    paketli üyeye RLS'li kasadan gelir). Kaynak KASA (paket_soru), servis anahtarı ister.
//  🚫 GÖRMEZ: SGS'de konu ifadesi kökte geçmeyen ama konuyu ölçen soru (havuz alt sınırdır) · ifade geçip konuyu ölçmeyen
//    soru (%5 civarı, 40'lık okumada) · Yeterlilik eşlemesinin tek okuyucu hatası.
//  Kullanım: node motor/sik-konu-deneme-bas.js [sgs|smmm|hepsi] [--kuru]
// ============================================================================
'use strict';
const fs = require('fs'), path = require('path'), crypto = require('crypto');
const KOK = path.join(__dirname, '..');
const KURU = process.argv.includes('--kuru');
const HEDEF = (process.argv.slice(2).find(a => !a.startsWith('--')) || 'hepsi').toLowerCase();
const jsonOku = y => JSON.parse(fs.readFileSync(y, 'utf8').replace(/^﻿/, ''));
const srt = d => { const [y, n] = String(d).split('/'); return +y * 10 + +n; };
const karma = id => [...String(id)].reduce((h, c) => (h * 31 + c.charCodeAt(0)) % 1000003, 7);
const elleRet = ad => { try { return jsonOku(path.join(KOK, 'veri', 'sinav', ad)).kayitlar || {}; } catch (e) { return {}; } };

async function kasaOku(sinav) {
  const K = process.env.SUPABASE_SERVICE_KEY;
  if (!K) { console.log('KIRMIZI - SUPABASE_SERVICE_KEY yok, kasa okunamadı; yazılmadı.'); process.exit(1); }
  const h = { apikey: K, Authorization: 'Bearer ' + K }, satir = [];
  for (let i = 0; ; i += 500) {
    const r = await fetch(`https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/paket_soru?select=id,ders,sayfa,sira,veri&sinav=eq.${sinav}&order=id.asc&limit=500&offset=${i}`, { headers: h });
    if (!r.ok) { console.log('KIRMIZI - kasa HTTP ' + r.status + '; yazılmadı.'); process.exit(1); }
    const p = await r.json(); satir.push(...p); if (p.length < 500) break;
  }
  return satir;
}
const uygun = v => v && v.soru && v.siklar && v.dogru && v.siklar[v.dogru] && Object.keys(v.siklar).length >= 4;
const dersSayfasi = x => /^kaydir\/(sgs|smmm)\/[a-z0-9-]+\.html$/.test(String(x.sayfa || '')) && !/index\.html$/.test(x.sayfa);

// Havuzu (konu → soru listesi) setlere böler: her sette her konudan `pay[konu]` soru; set sayısı en dar konuyla sınırlı.
function setKur(konular, havuz, pay, tavan) {
  let n = tavan;
  for (const k of konular) n = Math.min(n, Math.floor(havuz[k].length / pay[k]));
  const setler = Array.from({ length: Math.max(0, n) }, () => []);
  for (const k of konular) havuz[k].slice(0, n * pay[k]).forEach((q, j) => setler[j % n].push(q));
  return setler;
}

function yazDegisirse(dosya, nesne, zamanAlani) {
  try {
    const a = { ...jsonOku(dosya) }, b = { ...nesne };
    if (zamanAlani) { delete a[zamanAlani]; delete b[zamanAlani]; }
    if (JSON.stringify(a) === JSON.stringify(b)) return false;
  } catch (e) {}
  fs.writeFileSync(dosya, JSON.stringify(nesne, null, 1) + '\n', 'utf8'); return true;
}
function yaz(sinav, dizin, setler) {
  const cikis = path.join(KOK, 'veri', 'deneme'); fs.mkdirSync(cikis, { recursive: true });
  const sizan = setler.flat().filter(q => q.soru || q.siklar || q.dogru).length;
  if (sizan) { console.log('KIRMIZI - ' + sizan + ' soruda metin/cevap alanı var; yazılmadı.'); process.exit(1); }
  if (KURU) { console.log('  kuru koşu - yazılmadı'); return; }
  let yazilan = 0;
  // eski fazla set dosyaları (set sayısı düştüyse) silinir
  for (const f of fs.readdirSync(cikis)) {
    const m = f.match(new RegExp(`^${sinav}-sik-set-(\\d+)\\.json$`));
    if (m && +m[1] > setler.length) { fs.unlinkSync(path.join(cikis, f)); yazilan++; }
  }
  setler.forEach((st, i) => {
    const no = String(i + 1).padStart(2, '0'), b = dizin.setler[i];
    if (yazDegisirse(path.join(cikis, `${sinav}-sik-set-${no}.json`), { sinav, tur: 'sik', no: i + 1, baslik: b.baslik, sure_dk: b.sure_dk, toplam: st.length, sorular: st.map((q, n) => ({ n: n + 1, ...q })) })) yazilan++;
  });
  dizin.surum = crypto.createHash('sha1').update(setler.map(st => st.map(q => q.id).join(',')).join('|')).digest('hex').slice(0, 10);
  if (yazDegisirse(path.join(cikis, `${sinav}-sik-dizin.json`), dizin, 'uretim')) yazilan++;
  console.log(`  yazılan/değişen dosya: ${yazilan}`);
}

// ---------------------------------------------------------------- SGS
const SGS_DERS = { 'Muhasebe': 'Finansal Muhasebe', 'İktisat': 'Ekonomi', 'Atatürk İlkeleri': 'Atatürk İlkeleri ve İnkılap Tarihi' };
// Elle okumada sınırda kalan konu: "ücret" kelimesi ücret gelirine/bağımlılığa da uyuyordu.
const DARALT = { 'Meslek mensubu ücreti (asgari ücret tarifesi)': /ücret tarife|asgari ücret|ücret esas|düşük ücret|ücret(?:i|ini|in)? (?:belirle|kararlaştır|talep|iste|alma)|ücret.{0,60}yönetmeli/i };
const SGS_KONU = 20, SGS_PAY = 2, SGS_SURE = 50, SGS_TAVAN = 10;
async function sgs() {
  console.log('SIK ÇIKAN KONULAR DENEMESİ · Staja Giriş');
  const ok = jsonOku(path.join(KOK, 'veri', 'sinav', 'sgs-konu-okuma.json'));
  const yapi = jsonOku(path.join(KOK, 'veri', 'sgs-sinav-yapisi.json')).sgs;
  // yapı dosyası harf katlanmış (Turkce, Borclar Hukuku): sıra katlanmış adla kıyaslanır
  const katla = s => String(s || '').toLocaleLowerCase('tr').replace(/ı/g, 'i').replace(/ğ/g, 'g').replace(/ü/g, 'u').replace(/ş/g, 's').replace(/ö/g, 'o').replace(/ç/g, 'c').replace(/[^a-z0-9]+/g, ' ').trim();
  const dersSira = []; yapi.bolumler.forEach(b => b.dersler.forEach(d => dersSira.push(katla(d.ders))));
  const K = {};
  for (const x of ok.kararlar) { if (!x.e) continue; const r = K[x.konu] = K[x.konu] || { ders: SGS_DERS[x.ders] || x.ders, konu: x.konu, kanit: [] }; r.kanit.push(x); }
  const top = Object.values(K).map(r => {
    const don = [...new Set(r.kanit.map(z => z.donem))].sort((p, q) => srt(p) - srt(q));
    return { ...r, don: don.length, soru: r.kanit.length, son: don[don.length - 1] };
  }).sort((p, q) => q.don - p.don || q.soru - p.soru || srt(q.son) - srt(p.son)).filter(x => x.ders !== 'Matematik').slice(0, SGS_KONU);
  const ifade = {}; ok.konular.forEach(k => { ifade[k.konu] = k.ifade; });
  const rx = s => { const m = /^\/(.*)\/([a-z]*)$/.exec(s || ''); return new RegExp(m ? m[1] : s, 'i'); };
  const ret = elleRet('sgs-elle-ret.json');
  const kasa = (await kasaOku('sgs')).filter(x => !ret[x.id] && dersSayfasi(x) && uygun(x.veri));
  console.log(`  kasa: ${kasa.length} uygun soru (elle ret + ders sayfası dışı + eksik şık atlandı)`);
  // elle okunan 40'lık örnekle AYNI metin: kök + soru + konu etiketi (etiket iç eşleme içindir, dışarı rakam gitmez)
  const kok = x => [x.veri.kok, x.veri.soru, x.veri.metin, x.veri.konu].filter(Boolean).join(' ');
  const dersAd = x => String(x.ders || '').split('|')[0].trim();
  const alindi = new Set(), havuz = {}, hata = [];
  for (const t of top) {   // en sık konu önce: çok konuya uyan soru yalnız en sık konuya
    const re = DARALT[t.konu] || rx(ifade[t.konu]);
    havuz[t.konu] = kasa.filter(x => dersAd(x) === t.ders && !alindi.has(x.id) && re.test(kok(x)))
      .sort((a, b) => karma(a.id) - karma(b.id))
      .map(x => { alindi.add(x.id); return { id: x.id, bolum: t.ders, ders: t.ders, konu: t.konu, sayfa: x.sayfa, sira: x.sira }; });
    if (dersSira.indexOf(katla(t.ders)) < 0) hata.push('ders yapıda yok: ' + t.ders);
    console.log(`  ${String(t.don).padStart(2)} dönem · ${String(havuz[t.konu].length).padStart(3)} soru · ${t.ders} › ${t.konu}`);
  }
  const konular = top.map(t => t.konu), pay = {}; konular.forEach(k => { pay[k] = SGS_PAY; });
  const setler = setKur(konular, havuz, pay, SGS_TAVAN);
  // set içi sıra: yönerge ders sırası, ders içinde konu sıklığı
  const sira = q => dersSira.indexOf(katla(q.ders)) * 100 + konular.indexOf(q.konu);
  setler.forEach(st => st.sort((a, b) => sira(a) - sira(b)));
  if (setler.length < 3) hata.push(`yalnız ${setler.length} set kurulabildi (en dar konu yetmiyor)`);
  setler.forEach((st, i) => { if (st.length !== SGS_KONU * SGS_PAY) hata.push(`set ${i + 1}: ${st.length} soru`); });
  if (hata.length) { console.log('KIRMIZI - yazılmadı:'); hata.forEach(h => console.log('  · ' + h)); process.exit(1); }
  console.log(`  ${setler.length} set × ${SGS_KONU * SGS_PAY} soru · setler arası tekrar 0`);
  yaz('sgs', {
    uretim: new Date().toISOString().slice(0, 16).replace('T', ' '), uretici: 'motor/sik-konu-deneme-bas.js',
    sinav: 'sgs', tur: 'sik', ad: 'Staja Giriş', baslik: 'Staja Giriş · sık çıkan konular denemesi',
    alt: `Son 10 yılın çıkmış sınavlarında en sık sorulan ${SGS_KONU} konudan ${SGS_KONU * SGS_PAY} soru: her konudan ${SGS_PAY}. Çözerken cevap görünmez; bitince konu konu karne gelir.`,
    kural: [`${SGS_KONU * SGS_PAY} soru`, `${SGS_SURE} dakika`, `${SGS_KONU} konu × ${SGS_PAY} soru`, 'Yanlış doğruyu götürmez', `${setler.length} set, setler arası tekrar yok`],
    not: `Konu listesi okunarak sayılmış çıkmış sorulardan (${ok.pencere}, ${ok.donem} dönem; Matematik hariç), "En sık sorulan konular" sayfasıyla aynı. Süre gerçek sınavın soru başı süresiyle (165 dk / 130 soru). Bu konular sınavda kesin çıkar demek değildir.`,
    sonuc_alt: 'Staja Giriş\'te yanlış doğruyu götürmez ve puan bağıl hesaplanır; burada doğru sayısı ve konu konu karne var.',
    karne: 'konu', puan: 'yok', liste_sayfa: 'en-cok-cikan-konular-sgs.html',
    konular: top.map(t => ({ ders: t.ders, konu: t.konu, donem: t.don })),
    setler: setler.map((st, i) => ({ no: i + 1, baslik: 'Set ' + (i + 1), sure_dk: SGS_SURE, toplam: st.length, dosya: `veri/deneme/sgs-sik-set-${String(i + 1).padStart(2, '0')}.json` }))
  }, setler);
  // 07.10 Nöbetçi planı (Hesabım "Hiç dokunmadığın konular", calisma-ozet.js): havuzun TAMAMI kimlik → konu sırası.
  // Setlerle AYNI bağ (aynı ifade + DARALT + ders şartı) → deneme karnesi ile Hesabım aynı konuyu sayar. YALNIZ KİMLİK.
  const kimlik = {}; top.forEach((t, i) => havuz[t.konu].forEach(q => { kimlik[q.id] = i; }));
  if (!KURU && yazDegisirse(path.join(KOK, 'veri', 'deneme', 'sgs-sik-kimlik.json'), {
    uretim: new Date().toISOString().slice(0, 16).replace('T', ' '), uretici: 'motor/sik-konu-deneme-bas.js',
    not: 'kimlik: soru kimliği → konular[] sırası. Bağ iç eşlemedir (okuma ifadesi kökte), dışarı rakam olarak verilmez.',
    pencere: ok.pencere, donem: ok.donem,
    konular: top.map(t => ({ ders: t.ders, konu: t.konu, donem: t.don, son: t.son, kanit: [...new Map(t.kanit.map(z => [z.donem + '/' + z.soru, { donem: z.donem, soru: z.soru }])).values()].sort((a, b) => srt(a.donem) - srt(b.donem) || a.soru - b.soru) })),
    kimlik
  }, 'uretim')) console.log(`  sgs-sik-kimlik.json: ${Object.keys(kimlik).length} soru → ${top.length} konu`);
}

// ---------------------------------------------------------------- YETERLİLİK
const SM_KONU = 5, SM_SORU = 20, SM_SURE = 45, SM_TAVAN = 5;
async function smmm() {
  console.log('SIK ÇIKAN KONULAR DENEMESİ · Yeterlilik');
  const ok = jsonOku(path.join(KOK, 'veri', 'sinav', 'smmm-konu-okuma.json'));
  const es = jsonOku(path.join(KOK, 'veri', 'sinav', 'smmm-banka-esleme.json')).sorular;
  const dizinS = jsonOku(path.join(KOK, 'veri', 'soru-dizini.json')).sinavlar.find(x => x.kod === 'smmm');
  const dersSira = dizinS.dersler.map(d => d.ad);
  const D = {};
  for (const x of ok.kararlar) {
    const r = ((D[x.ders] = D[x.ders] || {})[x.konu] = D[x.ders][x.konu] || { konu: x.konu, kanit: [] });
    if (!r.kanit.some(z => z.donem === x.donem && z.soru === x.soru)) r.kanit.push({ donem: x.donem, soru: x.soru });
  }
  const ret = elleRet('smmm-elle-ret.json');
  const kasa = {}; (await kasaOku('smmm')).forEach(x => { if (!ret[x.id] && dersSayfasi(x) && uygun(x.veri)) kasa[x.id] = x; });
  console.log(`  kasa: ${Object.keys(kasa).length} uygun soru`);
  const tumSet = [], dizinSet = [], konuListe = [], hata = [];
  for (const ders of dersSira) {
    const top = Object.values(D[ders] || {}).map(r => {
      const don = [...new Set(r.kanit.map(z => z.donem))].sort((p, q) => srt(p) - srt(q));
      return { konu: r.konu, don: don.length, soru: r.kanit.length, son: don[don.length - 1] };
    }).sort((p, q) => q.don - p.don || q.soru - p.soru || srt(q.son) - srt(p.son)).slice(0, SM_KONU);
    if (top.length < SM_KONU) { hata.push(`${ders}: ${top.length} konu`); continue; }
    const konular = top.map(t => t.konu), alindi = new Set(), havuz = {};
    for (const t of top) {
      havuz[t.konu] = Object.keys(es).filter(id => es[id].ders === ders && (es[id].konular || []).includes(t.konu) && kasa[id] && !alindi.has(id))
        .sort((a, b) => karma(a) - karma(b))
        .map(id => { alindi.add(id); const x = kasa[id]; return { id, bolum: ders, ders, konu: t.konu, sayfa: x.sayfa, sira: x.sira }; });
      konuListe.push({ ders, konu: t.konu, donem: t.don });
    }
    // pay: set sayısını en yükseğe çıkaran bölüşüm. S set için konu tavanı = min(6, havuz/S); her konu en az 1 soru;
    // tavanlar 20'yi karşılayan en büyük S seçilir, sonra 20 soru sıklık sırasıyla tur tur dağıtılır (sık konu önce artar).
    const pay = {}; let S = 0, tavan = {};
    for (let s = SM_TAVAN; s >= 1; s--) {
      const t = {}; konular.forEach(k => { t[k] = Math.min(6, Math.floor(havuz[k].length / s)); });
      if (konular.every(k => t[k] >= 1) && konular.reduce((a, k) => a + t[k], 0) >= SM_SORU) { S = s; tavan = t; break; }
    }
    if (!S) { hata.push(`${ders}: 5 konunun her birinden en az 1 soruyla 20'lik set kurulamıyor (havuz ${konular.map(k => havuz[k].length).join('/')})`); continue; }
    konular.forEach(k => { pay[k] = 1; });
    for (let kalan = SM_SORU - konular.length; kalan > 0;) {
      let ekledi = false;
      for (const k of konular) { if (kalan > 0 && pay[k] < tavan[k]) { pay[k]++; kalan--; ekledi = true; } }
      if (!ekledi) break;
    }
    const aktif = konular;
    const setler = setKur(aktif, havuz, pay, SM_TAVAN);
    setler.forEach(st => st.sort((a, b) => konular.indexOf(a.konu) - konular.indexOf(b.konu)));
    console.log(`  ${ders}: ${setler.length} set · pay ${konular.map(k => pay[k] + '/' + havuz[k].length).join(' ')}`);
    if (!setler.length) { hata.push(`${ders}: set kurulamadı`); continue; }
    setler.forEach((st, i) => {
      if (st.length !== SM_SORU) hata.push(`${ders} set ${i + 1}: ${st.length} soru`);
      tumSet.push(st); dizinSet.push({ no: tumSet.length, ders, baslik: `${ders} · Set ${i + 1}`, sure_dk: SM_SURE, toplam: st.length, dosya: `veri/deneme/smmm-sik-set-${String(tumSet.length).padStart(2, '0')}.json` });
    });
  }
  const gor = new Set(); tumSet.flat().forEach(q => { if (gor.has(q.id)) hata.push('tekrar: ' + q.id); gor.add(q.id); });
  if (hata.length) { console.log('KIRMIZI - yazılmadı:'); hata.forEach(h => console.log('  · ' + h)); process.exit(1); }
  console.log(`  ${tumSet.length} set (${dersSira.length} ders) × ${SM_SORU} soru · setler arası tekrar 0`);
  yaz('smmm', {
    uretim: new Date().toISOString().slice(0, 16).replace('T', ' '), uretici: 'motor/sik-konu-deneme-bas.js',
    sinav: 'smmm', tur: 'sik', ad: 'Yeterlilik', baslik: 'Yeterlilik · sık çıkan konular denemesi',
    alt: `Her dersin çıkmış sınavlarda en sık sorulan ${SM_KONU} konusundan ${SM_SORU} soru, gerçek 2026 düzeninde. Çözerken cevap görünmez; bitince konu konu karne gelir.`,
    kural: [`Ders başına ${SM_SORU} soru`, `${SM_SURE} dakika`, 'Yanlış 0,25 götürür', 'Baraj 50', 'Setler arası tekrar yok'],
    not: `Konu listesi okunarak sayılmış çıkmış sorulardan (${ok.pencere}), "En sık sorulan konular" sayfasıyla aynı. Konu payı bankadaki soru sayısına göre ayarlanır. Bu konular sınavda kesin çıkar demek değildir.`,
    sonuc_alt: 'Puan: (doğru − yanlış ÷ 4) × 5. Geçme barajı 50.',
    karne: 'konu', puan: 'yeterlilik', liste_sayfa: 'en-cok-cikan-konular-yeterlilik.html',
    konular: konuListe, setler: dizinSet
  }, tumSet);
}

(async () => {
  if (HEDEF === 'sgs' || HEDEF === 'hepsi') await sgs();
  if (HEDEF === 'smmm' || HEDEF === 'hepsi') await smmm();
})().catch(e => { console.log('KIRMIZI - ' + e.message); process.exit(1); });
