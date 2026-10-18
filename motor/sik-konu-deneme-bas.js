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
//  18.10 Yeterlilik (Cem "en çok puan verilen konuları önceliğe çıkaralım"): havuzun tamamı (floor(havuz/20) set), konu
//    sırası + set içi payı PUAN ağırlığıyla (puanSetKur; ağırlık arac/smmm-konu-puan.js → veri/sinav/smmm-konu-puan.json).
//    Ders denemesi sık konu sorusunu artık dışlamaz (18.10 Cem: 78 deneme kalsın).
//  ÇIKTI: veri/deneme/<sgs|smmm>-sik-dizin.json + <sinav>-sik-set-NN.json — YALNIZ KİMLİK (metin/cevap sinav-gibi.html'de
//    paketli üyeye RLS'li kasadan gelir). Kaynak KASA (paket_soru), servis anahtarı ister.
//  🚫 GÖRMEZ: SGS'de konu ifadesi kökte geçmeyen ama konuyu ölçen soru (havuz alt sınırdır) · ifade geçip konuyu ölçmeyen
//    soru (%5 civarı, 40'lık okumada) · Yeterlilik eşlemesinin tek okuyucu hatası.
//  11.10: 'smmm' ayrıca YETERLİLİK DERS DENEMESİ basar (smmm-ders-*.json, ayrıntı smmmDers() başında).
//  Kullanım: node motor/sik-konu-deneme-bas.js [sgs|smmm|hepsi] [--kuru]
// ============================================================================
'use strict';
const fs = require('fs'), path = require('path'), crypto = require('crypto');
const KOK = path.join(__dirname, '..');
const { agirlikliDiz, konuBulucu } = require('./smmm-ders-sira.js');
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

// 18.10 PUAN ÖNCELİKLİ SET KURUCU (Yeterlilik sık konu): havuzun tamamı kullanılır → S = floor(havuz / 20) set.
//   Artan (< 20) soru EN HAFİF konunun sonundan bırakılır. Her set 20 soruyu, stoğu kalan konular arasında puan ağırlığıyla
//   orantılı alır (en büyük kalan yöntemi; stoğu yetmeyen konunun payı öteki konulara taşar). Dar ama ağır konu ilk
//   setlerde tükenir → ilk setler en ağır konularla başlar, sonraki setler kalan konulardan dolar. Setler arası tekrar 0.
function puanSetKur(konular, havuz, w) {
  const stok = {}; konular.forEach(k => { stok[k] = havuz[k].slice(); });
  const toplam = konular.reduce((a, k) => a + stok[k].length, 0), S = Math.floor(toplam / SM_SORU);
  let fazla = toplam - S * SM_SORU;
  for (let i = konular.length - 1; i >= 0 && fazla > 0; i--) { const d = Math.min(fazla, stok[konular[i]].length); stok[konular[i]].splice(stok[konular[i]].length - d, d); fazla -= d; }
  const setler = [];
  for (let s = 0; s < S; s++) {
    const pay = {}; konular.forEach(k => { pay[k] = 0; });
    for (let kalan = SM_SORU; kalan > 0;) {
      const ak = konular.filter(k => stok[k].length > pay[k]); if (!ak.length) break;
      const tw = ak.reduce((a, k) => a + w[k], 0), ham = ak.map(k => ({ k, x: kalan * w[k] / tw }));
      let dag = 0;
      ham.forEach(h => { const n = Math.min(Math.floor(h.x), stok[h.k].length - pay[h.k]); pay[h.k] += n; dag += n; h.r = h.x - Math.floor(h.x); });
      if (dag === 0) {   // tam kısım dağıtmadıysa en büyük kalana birer birer
        for (const h of ham.sort((p, q) => q.r - p.r || w[q.k] - w[p.k])) { if (dag >= kalan) break; if (stok[h.k].length > pay[h.k]) { pay[h.k]++; dag++; } }
      }
      kalan -= dag;
    }
    setler.push(konular.flatMap(k => stok[k].splice(0, pay[k])));
  }
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
function yaz(sinav, dizin, setler, tur = 'sik') {
  const cikis = path.join(KOK, 'veri', 'deneme'); fs.mkdirSync(cikis, { recursive: true });
  const sizan = setler.flat().filter(q => q.soru || q.siklar || q.dogru).length;
  if (sizan) { console.log('KIRMIZI - ' + sizan + ' soruda metin/cevap alanı var; yazılmadı.'); process.exit(1); }
  if (KURU) { console.log('  kuru koşu - yazılmadı'); return; }
  let yazilan = 0;
  // 11.10: sürüm değişecekse eski setler ÖNCE arşive (yarım deneme "Devam et"i kaybolmasın; motor/deneme-arsiv.js)
  const yeniSurum = crypto.createHash('sha1').update(setler.map(st => st.map(q => q.id).join(',')).join('|')).digest('hex').slice(0, 10);
  const arsivN = require('./deneme-arsiv.js').arsivle(cikis, `${sinav}-${tur}`, yeniSurum, KURU);
  if (arsivN) console.log(`  eski ${sinav}-${tur} setleri arşive: ${arsivN} set`);
  // eski fazla set dosyaları (set sayısı düştüyse) silinir
  for (const f of fs.readdirSync(cikis)) {
    const m = f.match(new RegExp(`^${sinav}-${tur}-set-(\\d+)\\.json$`));
    if (m && +m[1] > setler.length) { fs.unlinkSync(path.join(cikis, f)); yazilan++; }
  }
  setler.forEach((st, i) => {
    const no = String(i + 1).padStart(2, '0'), b = dizin.setler[i];
    if (yazDegisirse(path.join(cikis, `${sinav}-${tur}-set-${no}.json`), { sinav, tur, no: i + 1, baslik: b.baslik, sure_dk: b.sure_dk, toplam: st.length, sorular: st.map((q, n) => ({ n: n + 1, ...q })) })) yazilan++;
  });
  dizin.surum = yeniSurum;
  if (yazDegisirse(path.join(cikis, `${sinav}-${tur}-dizin.json`), dizin, 'uretim')) yazilan++;
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
    sinav: 'sgs', tur: 'sik', ad: 'Staja Giriş', baslik: `Staja Giriş · En Çok Sorulan ${SGS_KONU} Konu Denemesi`,
    // 07.10 Cem: ürün adı "En Çok Sorulan 20 Konu Denemesi" - ana sayfa, deneme ve konu sayfaları adı buradan okur
    deneme_ad: `En Çok Sorulan ${SGS_KONU} Konu Denemesi`,
    // 07.10 Cem "anlam karmaşası var": "20 konudan 40 soru: her konudan 2" çıkmış soru sanılıyordu -> ne / biçim / kazanç ayrı cümle
    alt: `Son 10 yılın sınavlarında en sık sorulan ${SGS_KONU} konu tek denemede. Her konudan ${SGS_PAY} soru, toplam ${SGS_KONU * SGS_PAY} soru, ${SGS_SURE} dakika. Bitince hangi konuda eksiğin olduğunu konu konu görürsün.`,
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
const SM_KONU = 5, SM_SORU = 20, SM_SURE = 45;
async function smmm() {
  console.log('SIK ÇIKAN KONULAR DENEMESİ · Yeterlilik');
  const ok = jsonOku(path.join(KOK, 'veri', 'sinav', 'smmm-konu-okuma.json'));
  const es = jsonOku(path.join(KOK, 'veri', 'sinav', 'smmm-banka-esleme.json')).sorular;
  const dizinS = jsonOku(path.join(KOK, 'veri', 'soru-dizini.json')).sinavlar.find(x => x.kod === 'smmm');
  const dersSira = dizinS.dersler.map(d => d.ad);
  const puanJ = jsonOku(path.join(KOK, 'veri', 'sinav', 'smmm-konu-puan.json'));
  if (puanJ.pencere !== ok.pencere) { console.log(`KIRMIZI - smmm-konu-puan.json penceresi (${puanJ.pencere}) okumayla (${ok.pencere}) aynı değil - node arac/smmm-konu-puan.js; yazılmadı.`); process.exit(1); }
  const puanAgirlik = {}; for (const d of Object.keys(puanJ.dersler)) { puanAgirlik[d] = {}; puanJ.dersler[d].konular.forEach(k => { puanAgirlik[d][k.konu] = k.agirlik; }); }
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
    // 18.10 PUAN ÖNCELİĞİ: aynı 5 konu (en sık sorulan, "en sık sorulan konular" sayfasıyla aynı liste), ama sıra ve pay
    //   konunun son 10 yılda DÖNEM BAŞINA getirdiği puana göre (veri/sinav/smmm-konu-puan.json, arac/smmm-konu-puan.js).
    const pw = puanAgirlik[ders] || {};
    if (top.some(t => !(pw[t.konu] > 0))) { hata.push(`${ders}: puan ağırlığı yok (${top.filter(t => !(pw[t.konu] > 0)).map(t => t.konu).join(', ')}) - node arac/smmm-konu-puan.js`); continue; }
    top.sort((p, q) => pw[q.konu] - pw[p.konu] || q.don - p.don);
    const konular = top.map(t => t.konu), alindi = new Set(), havuz = {};
    for (const t of top) {   // birden çok konuya uyan soru yalnız en ağır konuya
      havuz[t.konu] = Object.keys(es).filter(id => es[id].ders === ders && (es[id].konular || []).includes(t.konu) && kasa[id] && !alindi.has(id))
        .sort((a, b) => karma(a) - karma(b))
        .map(id => { alindi.add(id); const x = kasa[id]; return { id, bolum: ders, ders, konu: t.konu, sayfa: x.sayfa, sira: x.sira }; });
      konuListe.push({ ders, konu: t.konu, donem: t.don, oncelik: konular.indexOf(t.konu) + 1 });
    }
    const setler = puanSetKur(konular, havuz, pw);
    setler.forEach(st => st.sort((a, b) => konular.indexOf(a.konu) - konular.indexOf(b.konu)));
    const say = st => konular.map(k => st.filter(q => q.konu === k).length).join('/');
    console.log(`  ${ders}: ${setler.length} set · havuz ${konular.map(k => havuz[k].length).join('/')} · ağırlık ${konular.map(k => pw[k]).join('/')}`);
    console.log(`    set 1: ${say(setler[0] || [])} · set ${setler.length}: ${say(setler[setler.length - 1] || [])} (konu sırası ağırdan hafife)`);
    if (!setler.length) { hata.push(`${ders}: set kurulamadı (havuz ${konular.map(k => havuz[k].length).join('/')})`); continue; }
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
    sinav: 'smmm', tur: 'sik', ad: 'Yeterlilik', baslik: `Yeterlilik · Her Dersin En Çok Sorulan ${SM_KONU} Konusu`,
    deneme_ad: `Her Dersin En Çok Sorulan ${SM_KONU} Konusu Denemesi`,
    alt: `Her dersin son 10 yılın sınavlarında en sık sorulan ${SM_KONU} konusu. Sınavda daha çok puan getiren konu önde: ilk testlerde ve her testte o konudan daha çok soru. Ders başına ${SM_SORU} soru, ${SM_SURE} dakika, gerçek 2026 düzeninde. Bitince hangi konuda eksiğin olduğunu konu konu görürsün.`,
    kural: [`Ders başına ${SM_SORU} soru`, `${SM_SURE} dakika`, 'Yanlış 0,25 götürür', 'Baraj 50', 'Setler arası tekrar yok'],
    not: `Konu listesi okunarak sayılmış çıkmış sorulardan (${ok.pencere}), "En sık sorulan konular" sayfasıyla aynı. Konu sırası ve payı, konunun bu sınavlarda dönem başına getirdiği puana göre (2026 testlerinde soru başı 5 puan; klasik dönemde komisyon cevabındaki puan, yazılı değilse sorular eşit sayıldı). Bu konular sınavda kesin çıkar demek değildir.`,
    sonuc_alt: 'Puan: (doğru − yanlış ÷ 4) × 5. Geçme barajı 50.',
    karne: 'konu', puan: 'yeterlilik', liste_sayfa: 'en-cok-cikan-konular-yeterlilik.html',
    konular: konuListe, setler: dizinSet
  }, tumSet);
  return { kullanilan: gor, kasa, es, D, dersSira, pencere: ok.pencere, donemSay: ok.donem };
}

// ---------------------------------------------------------------- YETERLİLİK DERS DENEMESİ
//  11.10.2026 (Cem: "tek ders aldı nasıl sınayacağız tek dersi alan kişiyi" → GM önerisi 1 "ders denemesi" → "1 yapalım").
//  Gerçek 2026 düzeninde her ders AYRI sınav (TÜRMOB YK 14.01.2026: ders başına 20 soru / 45 dk, yanlış 0,25 götürür,
//  baraj 50) → tek ders alan kendi dersinin sınavını, tüm dersleri alan sekizini ayrı ayrı çözer.
//  HAVUZ: dersin sitedeki sorularının TAMAMI (smmm-banka-esleme.json, kasada olan, elle ret dışı). 18.10 Cem: sık konu
//    testleriyle ortak soru SERBEST (eskiden dışlanıyordu; reklam "8 ders · 78 deneme" bu set sayısına bağlı).
//  AĞIRLIK: sorunun konusu okunmuş çıkmış sorularda (smmm-konu-okuma.json, son 10 yıl penceresi) kaç dönemde soruldu.
//    Konular yumuşak ağırlıklı sırayla (smooth weighted round-robin) dizilir: sık konu daha çok, ama her set dersin geniş
//    bir kesitini alır. Son 10 yılda hiç sorulmamış konunun sorusu yalnız ağırlıklı havuz 20'ye yetmezse girer.
//  SETLER: ilk (set × 20) soru kart dağıtır gibi bölünür → setler arası AYNI SORU YOK. Ders başına en çok DERS_TAVAN set.
//  🚫 GÖRMEZ: sorunun zorluğu (dağılım dengelenmez) · eşlemenin tek okuyucu hatası · gerçek kitapçık konu sırası (ölçülmedi).
const DERS_TAVAN = 10;
function smmmDers(sik) {
  console.log('DERS DENEMESİ · Yeterlilik');
  const { kullanilan, kasa, es, D, dersSira, pencere } = sik;
  const tumSet = [], dizinSet = [], dersOzet = [], hata = [], havuzDosya = {};
  let eskiDersSet = [];   // yayındaki ders denemesi setleri: [{ders, sorular}]
  try {
    eskiDersSet = jsonOku(path.join(KOK, 'veri', 'deneme', 'smmm-ders-dizin.json')).setler
      .map(s => ({ ders: s.ders, sorular: jsonOku(path.join(KOK, s.dosya)).sorular || [] }));
  } catch (e) { eskiDersSet = []; }
  for (const ders of dersSira) {
    const agirlik = {};
    Object.values(D[ders] || {}).forEach(r => { agirlik[r.konu] = new Set(r.kanit.map(z => z.donem)).size; });
    // sırala: verilen kimlikleri yumuşak ağırlıklı sıraya dizer → {dizi (son 10 yılda sorulmuş konular), sifir (sorulmamış)}
    // 12.10: sıra işlevi motor/smmm-ders-sira.js'te TEK yerde — bitirme ders sayfası (paket_soru.sira) aynı konu sırasından
    //   kurulur. Öz-sınavı 8 dersin tamamında 11.10 iç işleviyle aynı diziyi verdiğini ölçer (node motor/smmm-ders-sira.js --sinav).
    const sirala = idler => {
      const konu = konuBulucu(es, agirlik), { dizi, sifir } = agirlikliDiz(idler, konu, agirlik);
      const q = id => { const x = kasa[id]; return { id, bolum: ders, ders, konu: konu(id), sayfa: x.sayfa, sira: x.sira }; };
      return { dizi: dizi.map(q), sifir: sifir.map(q) };
    };
    const tum = Object.keys(es).filter(id => es[id].ders === ders && kasa[id]);
    // 11.10 SANA ÖZEL DENEME havuzu: dersin TÜM sitedeki soruları aynı ağırlıklı sırayla (sinav-gibi.html öğrencinin
    // görmediklerini bu sırayla seçer). YALNIZ KİMLİK + konu sırası + sayfa sırası.
    // Kaynak eşleme değil KASA: eşlemede olmayan sitedeki soru da havuza girer (konusuz → sona; 11.10 Vergi 402'nin 48'i).
    const h = sirala(Object.keys(kasa).filter(id => String(kasa[id].ders || '').split('|')[0].trim() === ders)),
      hs = h.dizi.concat(h.sifir), sayfa = hs.length ? hs[0].sayfa : '';
    if (hs.some(q => q.sayfa !== sayfa)) hata.push(`${ders}: havuzda birden çok sayfa`);
    const konuAd = [...new Set(hs.map(q => q.konu))];
    havuzDosya[ders] = { sayfa, soru: hs.length, konular: konuAd, sorular: hs.map(q => [q.id, konuAd.indexOf(q.konu), q.sira]) };
    // 18.10 Cem: sık konu dışlaması KALKTI (bir soru hem ders denemesinde hem sık konu testinde olabilir; reklam "78 deneme").
    //   KARARLILIK: dersin yayındaki setleri (eski dizin) bankada aynen duruyorsa (her kimlik kasada, bu derste) DOKUNULMAZ —
    //   yarım denemeler ve set numaraları yerinde kalır. Bir soru düşünce ders baştan, dışlamasız kurulur.
    const eskiSet = eskiDersSet.filter(s => s.ders === ders);
    const tumK = new Set(tum);
    if (eskiSet.length && eskiSet.every(s => s.sorular.length === SM_SORU && s.sorular.every(q => tumK.has(q.id)))) {
      const setlerE = eskiSet.map(s => s.sorular.map(q => { const x = kasa[q.id]; return { id: q.id, bolum: ders, ders, konu: q.konu, sayfa: x.sayfa, sira: x.sira }; }));
      console.log(`  ${ders}: ${setlerE.length} set · yayındaki setler bankada duruyor, AYNEN korundu`);
      dersOzet.push({ ders, set: setlerE.length, konu: new Set(setlerE.flat().map(q => q.konu)).size });
      setlerE.forEach((st, i) => { tumSet.push(st); dizinSet.push({ no: tumSet.length, ders, baslik: `${ders} · Deneme ${i + 1}`, sure_dk: SM_SURE, toplam: st.length, dosya: `veri/deneme/smmm-ders-set-${String(tumSet.length).padStart(2, '0')}.json` }); });
      continue;
    }
    const { dizi, sifir } = sirala(tum);
    const agirlikli = dizi.length;
    if (dizi.length < SM_SORU) dizi.push(...sifir);
    const S = Math.min(DERS_TAVAN, Math.floor(dizi.length / SM_SORU));
    if (!S) { hata.push(`${ders}: 20'lik set kurulamıyor (havuz ${dizi.length})`); continue; }
    const setler = Array.from({ length: S }, () => []);
    dizi.slice(0, S * SM_SORU).forEach((q, j) => setler[j % S].push(q));
    const konuSay = new Set(setler.flat().map(q => q.konu)).size;
    console.log(`  ${ders}: ${S} set · havuz ${agirlikli} ağırlıklı + ${sifir.length} son 10 yılda sorulmamış konu · setlerde ${konuSay} konu`);
    dersOzet.push({ ders, set: S, konu: konuSay });
    setler.forEach((st, i) => {
      if (st.length !== SM_SORU) hata.push(`${ders} set ${i + 1}: ${st.length} soru`);
      tumSet.push(st); dizinSet.push({ no: tumSet.length, ders, baslik: `${ders} · Deneme ${i + 1}`, sure_dk: SM_SURE, toplam: st.length, dosya: `veri/deneme/smmm-ders-set-${String(tumSet.length).padStart(2, '0')}.json` });
    });
  }
  const gor = new Set();
  tumSet.flat().forEach(q => { if (gor.has(q.id)) hata.push('tekrar: ' + q.id); gor.add(q.id); });
  if (hata.length) { console.log('KIRMIZI - yazılmadı:'); hata.forEach(h => console.log('  · ' + h)); process.exit(1); }
  console.log(`  ${tumSet.length} set (${dersOzet.length} ders) × ${SM_SORU} soru · setler arası tekrar 0 · sık konu testleriyle ortak ${[...gor].filter(id => kullanilan.has(id)).length} (18.10 dışlama kalktı)`);
  yaz('smmm', {
    uretim: new Date().toISOString().slice(0, 16).replace('T', ' '), uretici: 'motor/sik-konu-deneme-bas.js',
    sinav: 'smmm', tur: 'ders', ad: 'Yeterlilik', baslik: 'Yeterlilik · Ders Denemesi',
    deneme_ad: 'Ders Denemesi',
    alt: `Gerçek sınavda her ders ayrı bir sınav. Burada da öyle: dersini seç, ${SM_SORU} soru, ${SM_SURE} dakika, yanlış doğrunun 0,25'ini götürür. Sorular dersin bütün konularından; son 10 yılda sık sorulan konu daha çok gelir. Bitince puanın ve konu konu karnen.`,
    kural: [`Ders başına ${SM_SORU} soru`, `${SM_SURE} dakika`, 'Yanlış 0,25 götürür', 'Baraj 50', 'Setler arası tekrar yok'],
    not: `Sınav düzeni TÜRMOB Yönetim Kurulu kararından (14.01.2026). Konu ağırlığı okunarak sayılmış çıkmış sorulardan (${pencere}).`,
    sonuc_alt: 'Puan: (doğru − yanlış ÷ 4) × 5. Geçme barajı 50; gerçek sınavda her ders ≥ 50 ve ortalama ≥ 60.',
    karne: 'konu', puan: 'yeterlilik', liste_sayfa: 'en-cok-cikan-konular-yeterlilik.html',
    dersler: dersOzet, setler: dizinSet
  }, tumSet, 'ders');
  if (!KURU) {
    const hv = { uretim: new Date().toISOString().slice(0, 16).replace('T', ' '), uretici: 'motor/sik-konu-deneme-bas.js',
      not: 'Sana özel deneme havuzu: ders → sorular [kimlik, konular[] sırası, sayfa sırası], ağırlıklı sırada. Metin/cevap YOK.',
      dersler: havuzDosya };
    hv.surum = crypto.createHash('sha1').update(JSON.stringify(havuzDosya)).digest('hex').slice(0, 10);
    // sıkı JSON (girintisiz): sayfa bu dosyayı özel deneme açılınca indirir
    const hd = path.join(KOK, 'veri', 'deneme', 'smmm-ders-havuz.json');
    let eski = null; try { eski = jsonOku(hd); } catch (e) {}
    if (!eski || eski.surum !== hv.surum) { fs.writeFileSync(hd, JSON.stringify(hv) + '\n', 'utf8'); console.log('  smmm-ders-havuz.json yazıldı'); }
    // 12.10 NÖBETÇİ NOTU KANITI (nobetci-notu.js, Cem "1.2.3"; SINAV RAKAMI KANITLI kuralı): havuzdaki her konunun okunmuş
    //   çıkmış sorulardaki kanıtı — [dönem, soru no], yeniden eskiye. Rakam öğrenciye bu listeden sayılarak gider; listesi
    //   olmayan konuda rakam yazılmaz. Kaynak smmm-konu-okuma.json (soru metni okunarak sayılmış), pencere aynen yazılır.
    const kanit = {};
    for (const d of Object.keys(havuzDosya)) {
      kanit[d] = {};
      havuzDosya[d].konular.forEach(k => {
        const r = k && D[d] && D[d][k]; if (!r || !r.kanit.length) return;
        kanit[d][k] = r.kanit.slice().sort((p, q) => srt(q.donem) - srt(p.donem) || (+p.soru) - (+q.soru)).map(z => [z.donem, String(z.soru)]);
      });
    }
    if (yazDegisirse(path.join(KOK, 'veri', 'deneme', 'smmm-konu-kanit.json'), { uretim: new Date().toISOString().slice(0, 16).replace('T', ' '),
      uretici: 'motor/sik-konu-deneme-bas.js', not: 'Nöbetçi notu kanıtı: ders → konu → [dönem, soru no] (okunmuş çıkmış sorular). Metin YOK.',
      pencere, donem: sik.donemSay, dersler: kanit }, 'uretim')) console.log('  smmm-konu-kanit.json yazıldı');
  }
  console.log('  özel deneme havuzu: ' + Object.keys(havuzDosya).map(d => d + ' ' + havuzDosya[d].soru).join(' · '));
}

(async () => {
  if (HEDEF === 'sgs' || HEDEF === 'hepsi') await sgs();
  // 11.10: 'smmm' iki türü birlikte basar (ders denemesi, sık konu setlerinde kullanılan soruyu dışlar → aynı koşuda)
  if (HEDEF === 'smmm' || HEDEF === 'hepsi') smmmDers(await smmm());
})().catch(e => { console.log('KIRMIZI - ' + e.message); process.exit(1); });
