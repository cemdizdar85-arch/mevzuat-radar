#!/usr/bin/env node
// ============================================================================
//  BİTİRME DERS SAYFASI SORU SIRASI (12.10.2026, bedel 0, model yok)
//
//  OLAY (ölçüldü 12.10): paket_soru.sira, arac/smmm-kasa-yayin.ps1 seçimi "etiket, id" ile ALFABETİK dizdiği için doluyordu.
//    Etiketlerde "-cokzor-" "-kolay-"dan önce geldiğinden her bitirme sayfası çok zor sorularla açılıyordu (Vergi ilk 7,
//    Hukuk 9, SPK 9, Denetim 11, Finansal Tablolar 18 soru çok zor; ilk 40 tek dalgadan, smmm-4k-a). 3 paketli üyenin 3'ü de
//    bu ilk sorularda bıraktı (kasa_cevap: Vergi üyesi 9 denemede 1 doğru).
//  KURAL (ders başına):
//    1) KONU: veri/deneme/smmm-ders-havuz.json ile AYNI ağırlıklı sıra (motor/sik-konu-deneme-bas.js bu dosyadaki
//       agirlikliDiz'i kullanır, kopya yok): konu ağırlığı = okunmuş çıkmış sorularda (smmm-konu-okuma.json) kaç dönemde
//       soruldu; konular yumuşak ağırlıklı sırayla dizilir (sık konu daha çok ve önde, ama her kesit karışık). Son 10 yılda
//       sorulmamış ya da eşlemesiz konunun sorusu sona.
//    2) İLK 10 (Cem 12.10 düzeltmesi: "çok kolay olursa o zaman sıkılır, en çok çıkan konular olabilir"): en sık sorulan
//       konulardan, HER BİRİ FARKLI KONU, ağırlık sırasıyla; zorluk orta/zor. Konunun orta/zor sorusu yoksa o konu atlanır;
//       10 dolmazsa ikinci turda kolay, en son etiketsiz soru alınır. ÇOK ZOR ilk 10'a HİÇ girmez.
//    3) SONRASI: kalan sorular konu sırasıyla zorluk kovalarına bölünür (kova içinde konu sırası korunur), kovalar kalan
//       sayılarıyla orantılı yumuşak ağırlıklı sırayla serpiştirilir. Zorluk kimlikten okunur (-kolay|-orta|-zor|-cokzor,
//       kasa-yukle.js ile aynı ifade); etiketsiz soru "bilinmiyor" kovasıdır.
//    4) SINAVA BENZEYEN ÖNCE (30.10, Cem "ilk önce bunu yapalım, düzgün sorularımızı görsünler"): ders kimlikleri
//       motor/sinav-benzerlik-olcu.js benzerMi ile ikiye ayrılır (kök ≤ gerçek medyan ×1,35 · şık sınav boyunda · sözel şıklı
//       derste çıplak rakam şık yok). İlk 10 önce benzer sorulardan kurulur (2. kural aynen), yetmezse ötekinden tamamlanır;
//       sonra benzerler 3. kuralla, en sonda benzemeyenler 3. kuralla. Soru metni veri/fabrika/kalip-parti-<etiket>.json'dan
//       okunur (yayın betiği zaten indirmiştir; seçim dosyası yine yalnız kimlik taşır). Metin ya da ders kalıbı yoksa benzer
//       kümesi boş → sıra 30.10 öncesiyle BİREBİR aynı (öz-sınav eşdeğerlik çapası). ANAHTAR arac/smmm-soru-sirasi.json
//       "sinava_benzer_once". Ölçü: 30.10 prova, ilk 40'ta Denetim kök 329→143 (gerçek 178), Vergi şık 7→92 (gerçek 72).
//    5) KALIP UYUMU (30.10, Cem "1.2.3 üçünü de yap"): her sorunun soru cümlesi kalıbı motor/soru-kalibi.js ile okunur;
//       gerçek dağılım veri/sinav/smmm-soru-kalibi.json (2026/1+2, ders başına 40 soru, elle). a) Dersin gerçek dağılımında
//       payı 0 olan kalıptaki soru benzer kümesine GİRMEZ (Meslek/SPK "doğrudur", Hukuk hesap…) → öteki kümesine düşer.
//       b) İlk 40 gerçek kalıp oranına yakın kurulur: ilk 10'da her konu için en açığı olan kalıbın sorusu, 11–40 arası
//       en büyük açıklı kalıptan (kalıp içinde 3. kuralın sırası korunur); benzerler 40'ı doldurmazsa kalan yerler ötekinden yine
//       kalıp oranıyla (benzerler hep önde; payı 0 kalıp ancak başka kalmayınca); 40'tan sonrası 3. kuralla aynen. c) SONA (silinmez):
//       Hukuk'ta hesap kalıbı (F), Denetim'de kökte şirket adlı vaka (vakaMi) — benzemeyenlerden de sonra.
//       ANAHTAR arac/smmm-soru-sirasi.json "kalip_uyumu"; kalıp verisi yoksa ya da anahtar kapalıysa sıra 4. kuraldaki gibi.
//  KÜME DEĞİŞMEZ: yalnız sıra değişir. Çıktı girdiyle aynı sayıda ve aynı kimliklerden oluşmazsa ÇIKIŞ 2 (dosya yazılmaz).
//  🚫 GÖRMEZ: sorunun gerçek zorluğu (etiket/plan üretim isteğidir, öğrenci verisi değil) · "orta" etiketi bankada yok (12.10) ·
//    planı olmayan elle yazılmış 15 sorunun zorluğu (gm-p1/gm-p2/denetim-30) · eşlemenin tek okuyucu hatası · sayfanın seviye testine göre yeniden sıralaması
//    (kasa-yukle.js seviyeSirala; zayıf öğrencide kolay önce, güçlüde zor önce — bu sıra ONUN girdisidir).
//
//  KULLANIM:
//    node motor/smmm-ders-sira.js --secim <secim-<slug>.json>   seçim dosyasını yerinde yeni sıraya dizer (yalnız sayı basar)
//    node motor/smmm-ders-sira.js --sinav                        öz-sınav (gerçek eşleme ile havuz eşdeğerliği dahil)
// ============================================================================
'use strict';
const fs = require('fs'), path = require('path');
const KOK = path.join(__dirname, '..');
const ILK = 10;
const ILK_ZORLUK = [['orta', 'zor'], ['kolay'], ['?']];   // ilk 10 için turlar: önce orta/zor, yetmezse kolay, en son etiketsiz
const KOVA = ['kolay', 'orta', '?', 'zor', 'cokzor'];   // eşitlikte önce gelen kova kazanır
const jsonOku = y => JSON.parse(fs.readFileSync(y, 'utf8').replace(/^﻿/, ''));
const karma = id => [...String(id)].reduce((h, c) => (h * 31 + c.charCodeAt(0)) % 1000003, 7);
const MUT = process.env.SIRA_MUTASYON || '';   // öz-sınavın bozma anahtarı (yalnız --sinav)

// okunmuş çıkmış sorulardan ders → konu → kaç farklı dönemde soruldu (sik-konu-deneme-bas.js smmm() ile aynı sayım)
function agirlikHaritasi(ok) {
  const D = {};
  for (const x of ok.kararlar) {
    const r = ((D[x.ders] = D[x.ders] || {})[x.konu] = D[x.ders][x.konu] || { konu: x.konu, kanit: [] });
    if (!r.kanit.some(z => z.donem === x.donem && z.soru === x.soru)) r.kanit.push({ donem: x.donem, soru: x.soru });
  }
  const A = {};
  for (const d in D) { A[d] = {}; Object.values(D[d]).forEach(r => { A[d][r.konu] = new Set(r.kanit.map(z => z.donem)).size; }); }
  return A;
}

// YUMUŞAK AĞIRLIKLI SIRA: kimlikler önce karma ile sabit karıştırılır, her adımda her konunun sayacı ağırlığı kadar artar,
// en yüksek sayaçlı konu bir soru verir. → {dizi (ağırlıklı konular), sifir (konusuz / ağırlığı 0)}. Havuz bu işlevle kurulur.
function agirlikliDiz(idler, konuBul, agirlik) {
  const kuyruk = {}, sifir = [];
  idler.slice().sort((a, b) => karma(a) - karma(b)).forEach(id => {
    const kn = konuBul(id);
    if (kn && agirlik[kn] > 0) (kuyruk[kn] = kuyruk[kn] || []).push(id); else sifir.push(id);
  });
  const dizi = [], sayac = {};
  let acik = Object.keys(kuyruk);
  acik.forEach(k => { sayac[k] = 0; });
  while (acik.length) {
    const top = acik.reduce((t, k) => t + agirlik[k], 0);
    acik.forEach(k => { sayac[k] += agirlik[k]; });
    const sec = acik.reduce((m, k) => (sayac[k] > sayac[m] || (sayac[k] === sayac[m] && agirlik[k] > agirlik[m])) ? k : m);
    sayac[sec] -= top; dizi.push(kuyruk[sec].shift());
    if (!kuyruk[sec].length) acik = acik.filter(k => k !== sec);
  }
  return { dizi, sifir };
}
// sorunun konusu: eşlemedeki konulardan en sık sorulanı (deneme karnesi de o konuyu sayar)
const konuBulucu = (es, agirlik) => id => ((es[id] && es[id].konular) || []).slice().sort((p, q) => (agirlik[q] || 0) - (agirlik[p] || 0))[0] || '';

// 12.10 (GM2): kimlikte zorluk yoksa partinin PLAN dosyasındaki zorluk (veri/sinav/plan-smmm-*.json "etiket" → "zorluk";
//   üretim isteği, bedel 0). Etiket birden çok zorlukla planlandıysa ya da planı yoksa (elle yazılmış GM partileri) "?".
//   12.10 ölçümü: etiketsiz 181 sorunun 166'sı plandan çözüldü (ab-hukuk kolay; ab2-maliyet, dog1-vergi, olc2-vergi zor).
let PLAN_Z = null;
function planZorluk() {
  if (PLAN_Z) return PLAN_Z;
  PLAN_Z = {};
  if (MUT === 'plan-yok') return PLAN_Z;
  const d = path.join(KOK, 'veri', 'sinav'), m = {};
  try {
    for (const f of fs.readdirSync(d).filter(x => /^plan-smmm-.*\.json$/.test(x))) {
      let p; try { p = jsonOku(path.join(d, f)); } catch (e) { continue; }
      (Array.isArray(p) ? p : [p]).forEach(r => { if (r && r.etiket && /^(kolay|orta|zor|cokzor)$/.test(r.zorluk)) (m[r.etiket] = m[r.etiket] || new Set()).add(r.zorluk); });
    }
  } catch (e) {}
  for (const e in m) if (m[e].size === 1) PLAN_Z[e] = [...m[e]][0];
  return PLAN_Z;
}
function zorluk(id) {
  const m = String(id || '').match(/-(kolay|orta|zor|cokzor)(?=[-\/]|$)/);
  if (m) return m[1];
  return planZorluk()[String(id || '').split('/')[0]] || '?';
}

// ilk 10: en sık konulardan, her biri farklı konu, orta/zor (yoksa kolay, en son etiketsiz); çok zor hiç.
// secici (5. kural): konunun adaylarından birini seçer (adaylar, şimdiye kadar seçilenler) → kimlik; yoksa ilk aday.
function ilkOn(taban, konuBul, agirlik, secici) {
  const ilkKonum = {}; taban.forEach((id, i) => { const k = konuBul(id); if (k && agirlik[k] > 0 && !(k in ilkKonum)) ilkKonum[k] = i; });
  const konular = Object.keys(ilkKonum).sort((p, q) => (agirlik[q] - agirlik[p]) || (ilkKonum[p] - ilkKonum[q]));
  const secilen = [], kullanilan = new Set(), alinan = new Set();
  for (const tur of ILK_ZORLUK) {
    for (const k of konular) {
      if (secilen.length >= ILK) break;
      if (kullanilan.has(k)) continue;
      const id = secici ? secici(taban.filter(x => !alinan.has(x) && konuBul(x) === k && tur.includes(zorluk(x))), secilen)
        : taban.find(x => !alinan.has(x) && konuBul(x) === k && tur.includes(zorluk(x)));
      if (id) { secilen.push(id); kullanilan.add(k); alinan.add(id); }
    }
  }
  return secilen;
}

// konu sırasındaki kimlikleri zorluğa göre serpiştirir
function zorlukSerpistir(sirali) {
  const kova = {}; KOVA.forEach(k => { kova[k] = []; });
  sirali.forEach(id => kova[zorluk(id)].push(id));
  const out = [];
  if (MUT === 'serpistirme-yok') { KOVA.forEach(k => out.push(...kova[k])); return out; }
  const agirlik = {}; KOVA.forEach(k => { agirlik[k] = kova[k].length; });
  const sayac = {}; KOVA.forEach(k => { sayac[k] = 0; });
  let acik = KOVA.filter(k => kova[k].length);
  while (acik.length) {
    const top = acik.reduce((t, k) => t + agirlik[k], 0);
    acik.forEach(k => { sayac[k] += agirlik[k]; });
    const sec = acik.reduce((m, k) => (sayac[k] > sayac[m] ? k : m));
    sayac[sec] -= top; out.push(kova[sec].shift());
    if (!kova[sec].length) acik = acik.filter(k => k !== sec);
  }
  return out;
}

// 5. kural: kalıp açığı. havuzdaki kalıplardan gerçek payı > 0 olanların payı, n. konumda olması gereken sayı = pay × n / toplam;
// açık = olması gereken − yerleşen. sec: ilk 10'da konunun adaylarından en açıklı kalıbınki (eşitlikte önce gelen);
// diz: ilk N'ye kadar her konumda en açıklı kalıbın sıradaki sorusu (eşitlikte payı büyük, sonra ilk görülen), sonrası aynen.
function kalipAcigi(havuz, harf, pay) {
  const top = [...new Set(havuz.map(harf))].reduce((t, h) => t + (pay[h] || 0), 0);
  const acik = (h, n, yer) => top ? (pay[h] || 0) * n / top - (yer[h] || 0) : 0;
  const say = liste => { const y = {}; liste.forEach(id => { const h = harf(id); y[h] = (y[h] || 0) + 1; }); return y; };
  // önce gerçek payı > 0 kalıp (payı 0 kalıp ancak başka kalmayınca), sonra en büyük açık, sonra büyük pay
  const ust = (h, a, e, eA) => ((pay[h] || 0) > 0) !== ((pay[e] || 0) > 0) ? (pay[h] || 0) > 0
    : a > eA + 1e-9 || (Math.abs(a - eA) <= 1e-9 && (pay[h] || 0) > (pay[e] || 0));
  return {
    sec(adaylar, secilen) {
      if (!adaylar.length) return undefined;
      const yer = say(secilen), n = secilen.length + 1;
      let en = adaylar[0], enA = acik(harf(en), n, yer);
      for (const id of adaylar) { const a = acik(harf(id), n, yer); if (harf(id) !== harf(en) && ust(harf(id), a, harf(en), enA)) { en = id; enA = a; } }
      return en;
    },
    diz(ilk, kalan, N) {
      const yer = say(ilk), kova = {}, sira = [], out = [];
      kalan.forEach(id => { const h = harf(id); if (!kova[h]) { kova[h] = []; sira.push(h); } kova[h].push(id); });
      for (let n = ilk.length + 1; n <= N; n++) {
        const dolu = sira.filter(h => kova[h].length); if (!dolu.length) break;
        let en = dolu[0], enA = acik(en, n, yer);
        for (const h of dolu) { const a = acik(h, n, yer); if (ust(h, a, en, enA)) { en = h; enA = a; } }
        out.push(kova[en].shift()); yer[en] = (yer[en] || 0) + 1;
      }
      const alinan = new Set(out);
      return out.concat(kalan.filter(id => !alinan.has(id)));
    }
  };
}
const KOTA = 40;   // 5b: gerçek kalıp oranına yakın kurulan baş

// bir dersin kimlikleri → yeni sıra (küme aynı). benzer: sınava benzeyen kimlik kümesi (Set) ya da yok → 4. kural kapalı.
// kalip (5. kural): { harf: {kimlik: kalıp harfi}, pay: {harf: gerçek sayı}, sona: Set } ya da yok → 5. kural kapalı
function dersSirala(idler, ders, es, A, benzer, kalip) {
  const agirlik = (A && A[ders]) || {};
  const { dizi, sifir } = agirlikliDiz(idler, konuBulucu(es, agirlik), agirlik);
  const konuSirasi = MUT === 'konu-yok' ? idler.slice().sort() : dizi.concat(sifir);
  const kb = kalip && kalip.harf && kalip.pay ? kalip : null;
  const harf = id => (kb && kb.harf[id]) || '?';
  const sona = kb && kb.sona && MUT !== 'sona-yok' ? kb.sona : new Set();
  let bz = (MUT === 'benzer-yok' || !benzer) ? new Set() : benzer;
  if (kb) bz = new Set([...bz].filter(id => !sona.has(id) && (MUT === 'kalip-suzgec-yok' || (kb.pay[harf(id)] || 0) > 0)));
  const bOnce = konuSirasi.filter(id => bz.has(id)), oteki = konuSirasi.filter(id => !bz.has(id) && !sona.has(id));
  const son = konuSirasi.filter(id => !bz.has(id) && sona.has(id));
  const kota = kb && MUT !== 'kota-yok' ? kalipAcigi(bOnce, harf, kb.pay) : null;
  let ilk = [];
  if (MUT !== 'ilk-sik-yok') {
    ilk = ilkOn(bOnce, konuBulucu(es, agirlik), agirlik, kota ? kota.sec : undefined);
    if (ilk.length < ILK) {   // benzerlerden 10 dolmadıysa: kalan yerler, kullanılmamış konulardan, öteki sorulardan (2. kural aynen)
      const kn = konuBulucu(es, agirlik), kul = new Set(ilk.map(kn));
      const ilkB = ilk, kotaT = kota && kalipAcigi(bOnce.concat(oteki), harf, kb.pay);   // 5b: öteki dolgusu da kalıp oranıyla
      ilk = ilk.concat(ilkOn(oteki.filter(id => !kul.has(kn(id))), kn, agirlik, kotaT ? (ad, sec) => kotaT.sec(ad, ilkB.concat(sec)) : undefined).slice(0, ILK - ilk.length));
    }
  }
  const ilkS = new Set(ilk);
  let bKalan = zorlukSerpistir(bOnce.filter(id => !ilkS.has(id))), oKalan = zorlukSerpistir(oteki.filter(id => !ilkS.has(id)));
  if (kota) {
    bKalan = kota.diz(ilk, bKalan, KOTA);
    // benzerler 40'ı doldurmadıysa: kalan yerler ötekinden yine gerçek kalıp oranıyla (benzerler yine önde)
    if (ilk.length + bKalan.length < KOTA) oKalan = kalipAcigi(bOnce.concat(oteki), harf, kb.pay).diz(ilk.concat(bKalan), oKalan, KOTA);
  }
  return ilk.concat(bKalan, oKalan, zorlukSerpistir(son));
}

// 4. kural: seçimdeki kimliklerden sınava benzeyenler. Ders kalıbı veri/sinav-anatomisi-smmm.json; ad eşlemesi aşağıda.
const KALIP_AD = { 'Meslek Hukuku': 'Muhasebecilik ve Mali Müşavirlik Meslek Hukuku', Hukuk: 'Hukuk (Ticaret H., Borçlar H., İş H., SSK ve Bağ-Kur Mevzuatı, İdari Yargılama H.)',
  'Sermaye Piyasası Mevzuatı': 'Sermaye Piyasası Mevzuatı (Ek: RG-19/8/2014-29093)' };
// 5. kural da buradan beslenir: harf = her metinli sorunun soru cümlesi kalıbı, sona = 5c kümesi (ders kuralı SONA'da).
const SONA = { Hukuk: (v, h) => h === 'F', 'Muhasebe Denetimi': v => require('./soru-kalibi.js').vakaMi(v.soru) };
function benzerKume(liste, ders) {
  const { benzerMi } = require('./sinav-benzerlik-olcu.js'), { soruKalibi } = require('./soru-kalibi.js');
  let kalip = null;
  try { const C = jsonOku(path.join(KOK, 'veri', 'sinav-anatomisi-smmm.json')).C_ders_kalibi; kalip = C[KALIP_AD[ders] || ders] || null; } catch (e) {}
  const s = new Set(), harf = {}, sona = new Set(), parti = {}, fab = process.env.SIRA_FABRIKA || path.join(KOK, 'veri', 'fabrika');
  let metinsiz = 0;
  if (!kalip) return { s, kalip: false, metinsiz: liste.length, harf, sona };
  for (const x of liste) {
    if (!(x.etiket in parti)) { try { parti[x.etiket] = jsonOku(path.join(fab, 'kalip-parti-' + x.etiket + '.json')); } catch (e) { parti[x.etiket] = null; } }
    const v = parti[x.etiket] && parti[x.etiket][x.id];
    if (!v || !v.soru) { metinsiz++; continue; }
    const k = x.etiket + '/' + x.id, h = soruKalibi(v);
    harf[k] = h;
    if (SONA[ders] && SONA[ders](v, h)) sona.add(k);
    if (benzerMi(v, kalip)) s.add(k);
  }
  return { s, kalip: true, metinsiz, harf, sona };
}
const anahtar = ad => { try { return jsonOku(path.join(KOK, 'arac', 'smmm-soru-sirasi.json'))[ad] === true; } catch (e) { return false; } };
const benzerAnahtari = () => anahtar('sinava_benzer_once');
// gerçek kalıp dağılımı (dersin 40 sorusu, harf → sayı) ya da null
function kalipPay(ders) {
  try { const d = jsonOku(path.join(KOK, 'veri', 'sinav', 'smmm-soru-kalibi.json')).ders[ders]; if (!d) return null; const p = Object.assign({}, d); delete p.n; return p; } catch (e) { return null; }
}
// ilk N'nin kalıp dağılımının gerçekten sapması (toplam değişim uzaklığı, %): ½ Σ |pay_baş − pay_gerçek|
function kalipSapma(bas, harf, pay) {
  const n = bas.length, g = Object.values(pay).reduce((t, x) => t + x, 0), say = {};
  bas.forEach(id => { const h = harf[id] || '?'; say[h] = (say[h] || 0) + 1; });
  const H = new Set(Object.keys(say).concat(Object.keys(pay)));
  return Math.round(50 * [...H].reduce((t, h) => t + Math.abs((say[h] || 0) / n - (pay[h] || 0) / g), 0));
}

function ayniKume(a, b) {
  if (a.length !== b.length) return false;
  const s = new Set(a); if (s.size !== a.length) return false;
  return b.every(x => s.has(x)) && new Set(b).size === b.length;
}

function veriYukle() {
  return {
    es: jsonOku(path.join(KOK, 'veri', 'sinav', 'smmm-banka-esleme.json')).sorular,
    A: agirlikHaritasi(jsonOku(path.join(KOK, 'veri', 'sinav', 'smmm-konu-okuma.json')))
  };
}

// seçim dosyası (arac/smmm-kasa-yayin.ps1: [{etiket,id,ders,konu,donem}], tek ders) → yerinde yeni sıra
function secimSirala(dosya) {
  const liste = jsonOku(dosya);
  if (!Array.isArray(liste) || !liste.length) throw new Error('seçim dosyası boş ya da dizi değil');
  const ders = String(liste[0].ders || '');
  if (liste.some(x => String(x.ders || '') !== ders)) throw new Error('seçim dosyasında birden çok ders');
  const anahtar = x => x.etiket + '/' + x.id, harita = new Map(liste.map(x => [anahtar(x), x]));
  if (harita.size !== liste.length) throw new Error('seçimde kimlik tekrarı');
  const { es, A } = veriYukle();
  const bAc = benzerAnahtari(), kAc = anahtar('kalip_uyumu');
  const bkTum = (bAc || kAc) ? benzerKume(liste, ders) : null, bk = bAc ? bkTum : null;
  const pay = kAc ? kalipPay(ders) : null, kb = bkTum && pay ? { harf: bkTum.harf, pay, sona: bkTum.sona } : null;
  const yeni = dersSirala([...harita.keys()], ders, es, A, bk && bk.s, kb);
  if (!ayniKume([...harita.keys()], yeni)) { const e = new Error('KÜME DEĞİŞTİ — sıra yazılmadı'); e.kod = 2; throw e; }
  fs.writeFileSync(dosya, JSON.stringify(yeni.map(k => harita.get(k)), null, 1), 'utf8');
  const z = {}; yeni.slice(0, 40).forEach(k => { const t = zorluk(k); z[t] = (z[t] || 0) + 1; });
  const esli = yeni.filter(k => es[k]).length;
  const bzYazi = !bk ? 'sınava benzer önce KAPALI' : !bk.kalip ? 'sınava benzer: DERS KALIBI YOK (eski sıra)'
    : `sınava benzer ${bk.s.size} · ilk 40'ta ${yeni.slice(0, 40).filter(k => bk.s.has(k)).length}` + (bk.metinsiz ? ` · metni okunamayan ${bk.metinsiz}` : '');
  const kYazi = !kAc ? 'kalıp uyumu KAPALI' : !kb ? 'kalıp uyumu: GERÇEK DAĞILIM YOK (4. kural sırası)'
    : `kalıp uyumu: ilk 40 gerçekten sapma %${kalipSapma(yeni.slice(0, 40), kb.harf, kb.pay)} · payı 0 kalıp ${bk ? [...bk.s].filter(k => !(kb.pay[kb.harf[k]] > 0)).length : 0} · sona ${kb.sona.size}`;
  console.log(`  SIRA ${ders}: ${yeni.length} soru · eşlemeli ${esli} · ilk 10 farklı konu ${new Set(yeni.slice(0, 10).map(konuBulucu(es, A[ders] || {}))).size}/10 · ilk 10 çok zor ${yeni.slice(0, 10).filter(k => zorluk(k) === 'cokzor').length} · ilk 40 ${KOVA.filter(k => z[k]).map(k => k + ' ' + z[k]).join(' ')} · ${bzYazi} · ${kYazi}`);
}

// ---------------------------------------------------------------- ÖZ-SINAV
// sik-konu-deneme-bas.js'in 11.10 iç sirala() işlevinin AYNEN kopyası (eşdeğerlik çapası; havuz sırası bununla kurulmuştu)
function eskiSirala(idler, es, agirlik) {
  const kuyruk = {}, sifir = [];
  idler.slice().sort((a, b) => karma(a) - karma(b)).forEach(id => {
    const kn = ((es[id] && es[id].konular) || []).slice().sort((p, q) => (agirlik[q] || 0) - (agirlik[p] || 0))[0] || '';
    if (kn && agirlik[kn] > 0) (kuyruk[kn] = kuyruk[kn] || []).push(id); else sifir.push(id);
  });
  const dizi = [], sayac = {};
  let acik = Object.keys(kuyruk);
  acik.forEach(k => { sayac[k] = 0; });
  while (acik.length) {
    const top = acik.reduce((t, k) => t + agirlik[k], 0);
    acik.forEach(k => { sayac[k] += agirlik[k]; });
    const sec = acik.reduce((m, k) => (sayac[k] > sayac[m] || (sayac[k] === sayac[m] && agirlik[k] > agirlik[m])) ? k : m);
    sayac[sec] -= top; dizi.push(kuyruk[sec].shift());
    if (!kuyruk[sec].length) acik = acik.filter(k => k !== sec);
  }
  return { dizi, sifir };
}

function sinav() {
  let hata = 0; const t = (ad, k) => { console.log((k ? '  geçti: ' : '  DÜŞTÜ: ') + ad); if (!k) hata++; };
  // yapay ders: 12 konu k01..k12, ağırlık 12..1. Konu kimlik sırasının TERSİNE dağıtılır (alfabede önce seyrek konu gelir):
  // sık konu öne ancak konu sırası çalışırsa çıkar. Zorluk etiketleri alfabede "cokzor" önde (12.10 gerçek vakası).
  const es = {}, A = { D: {} }, idler = [], KN = Array.from({ length: 12 }, (_, i) => 'k' + String(i + 1).padStart(2, '0'));
  KN.forEach((k, i) => { A.D[k] = 12 - i; });
  const zr = ['cokzor', 'kolay', 'zor', 'zor', 'kolay', 'cokzor'];
  for (let i = 0; i < 144; i++) { const id = `smmm-x-${zr[i % 6]}-r${String(i).padStart(3, '0')}/kp-01`; idler.push(id); es[id] = { ders: 'D', konular: [KN[11 - Math.floor(i / 12)]] }; }
  idler.push('smmm-z-etiketsiz/kp-01', 'smmm-z-etiketsiz/kp-02');
  const alfabe = idler.slice().sort(), kn = id => (es[id] || { konular: ['?'] }).konular[0];
  const y = dersSirala(alfabe, 'D', es, A), on = y.slice(0, 10);
  t('küme ve sayı aynı', ayniKume(alfabe, y));
  t('alfabetik sıra: ilk soru çok zor (vaka gerçek)', zorluk(alfabe[0]) === 'cokzor');
  t('ilk 10da çok zor yok', on.every(k => zorluk(k) !== 'cokzor'));
  t('ilk 10da kolay yok (orta/zor varken)', on.every(k => zorluk(k) === 'zor' || zorluk(k) === 'orta'));
  t('ilk 10 her biri farklı konu', new Set(on.map(kn)).size === 10);
  t('ilk 10 en sık 10 konu, ağırlık sırasıyla', on.map(kn).join(',') === KN.slice(0, 10).join(','));
  let ardisik = 0, enCok = 0; y.slice(10).forEach(k => { ardisik = zorluk(k) === 'cokzor' ? ardisik + 1 : 0; enCok = Math.max(enCok, ardisik); });
  t('sonrası: çok zor serpiştirilmiş (art arda en çok 1)', enCok <= 1);
  const s20 = y.slice(10, 40); t('sonrası: 11–40 arasında sık konu (k01–k03) seyrekten (k10–k12) çok', s20.filter(k => ['k01', 'k02', 'k03'].includes(kn(k))).length > s20.filter(k => ['k10', 'k11', 'k12'].includes(kn(k))).length);
  t('sıra kararlı (girdi sırası etkisiz)', JSON.stringify(dersSirala(alfabe.slice().reverse(), 'D', es, A)) === JSON.stringify(y));
  // orta/zor yetmezse: konu yalnız kolay sorulu → ikinci turda kolay; çok zor yine girmez
  const es2 = { 'smmm-a-cokzor-r1/kp-01': { konular: ['p'] }, 'smmm-a-kolay-r1/kp-01': { konular: ['p'] }, 'smmm-a-zor-r1/kp-01': { konular: ['q'] } };
  const y2 = dersSirala(Object.keys(es2), 'E', es2, { E: { p: 5, q: 1 } });
  t('orta/zor yoksa konu ikinci turda kolayla gelir, çok zor ilk 10a girmez', y2[0] === 'smmm-a-zor-r1/kp-01' && y2[1] === 'smmm-a-kolay-r1/kp-01' && y2[2] === 'smmm-a-cokzor-r1/kp-01');
  t('küme kapısı: eksik/tekrar yakalanır', !ayniKume(['a', 'b'], ['a', 'a']) && !ayniKume(['a', 'b'], ['a']));
  // 4. kural (30.10): sınava benzeyen önce. Benzer kümesi her üç sorudan biri (bütün konulara yayılır).
  const bz = new Set(alfabe.filter((k, i) => i % 3 === 0)), yb = dersSirala(alfabe, 'D', es, A, bz);
  t('benzer: küme ve sayı aynı', ayniKume(alfabe, yb));
  t('benzer: ilk 10 hep benzer, çok zor yok, farklı konu', yb.slice(0, 10).every(k => bz.has(k) && zorluk(k) !== 'cokzor') && new Set(yb.slice(0, 10).map(kn)).size === 10);
  t('benzer: bütün benzerler benzemeyenlerden önce', yb.slice(0, bz.size).every(k => bz.has(k)));
  t('benzer kümesi boş/yok → sıra 30.10 öncesiyle BİREBİR aynı', JSON.stringify(dersSirala(alfabe, 'D', es, A, new Set())) === JSON.stringify(y) && JSON.stringify(dersSirala(alfabe, 'D', es, A, null)) === JSON.stringify(y));
  const az = new Set([alfabe.find(k => kn(k) === 'k01' && zorluk(k) === 'zor')]), ya = dersSirala(alfabe, 'D', es, A, az);
  t('benzer 10dan azsa ilk 10 ötekinden tamamlanır, konu tekrarı yok', az.has(ya[0]) && new Set(ya.slice(0, 10).map(kn)).size === 10 && ya.slice(0, 10).every(k => zorluk(k) !== 'cokzor'));
  // 5. kural (30.10): kalıp uyumu. Her soru benzer; kalıplar sırayla F A C G (bankada eşit). Gerçek pay: F 0, A 2, C 6, G 2
  // → ilk 40 hedefi A 8 · C 24 · G 8, F hiç. Sona: her 12 sorudan biri (C kalıbından, konulara yayılır).
  const KH = ['F', 'A', 'C', 'G'], harfK = {}; alfabe.forEach((k, i) => { harfK[k] = KH[i % 4]; });
  const sonaK = new Set(alfabe.filter((k, i) => i % 12 === 6)), payK = { A: 2, C: 6, G: 2 }, hepsi = new Set(alfabe);
  const yk = dersSirala(alfabe, 'D', es, A, hepsi, { harf: harfK, pay: payK, sona: sonaK }), b40 = yk.slice(0, 40);
  const say40 = h => b40.filter(k => harfK[k] === h).length, bzN = alfabe.filter(k => harfK[k] !== 'F' && !sonaK.has(k)).length;
  t('kalıp: küme ve sayı aynı', ayniKume(alfabe, yk));
  t('kalıp: gerçek payı 0 kalıp (F) benzer kümesine girmez — hepsi benzerlerden sonra', yk.slice(0, bzN).every(k => harfK[k] !== 'F'));
  t(`kalıp: ilk 40 gerçek orana yakın (A ${say40('A')}/8 · C ${say40('C')}/24 · G ${say40('G')}/8, ±2)`, Math.abs(say40('A') - 8) <= 2 && Math.abs(say40('C') - 24) <= 2 && Math.abs(say40('G') - 8) <= 2);
  t('kalıp: ilk 10 yine benzer, farklı konu, çok zor yok', yk.slice(0, 10).every(k => harfK[k] !== 'F' && !sonaK.has(k) && zorluk(k) !== 'cokzor') && new Set(yk.slice(0, 10).map(kn)).size === 10);
  t('kalıp: sona kümesi en sonda, silinmez', yk.slice(-sonaK.size).every(k => sonaK.has(k)) && sonaK.size > 0);
  t('kalıp: kalıp kotası tek başına (11–40) — ilk 10 dışındaki 30 soruda C en az 17', b40.slice(10).filter(k => harfK[k] === 'C').length >= 17);
  const az5 = new Set(alfabe.filter(k => harfK[k] === 'A' && !sonaK.has(k)).slice(0, 5)), ya5 = dersSirala(alfabe, 'D', es, A, az5, { harf: harfK, pay: payK, sona: sonaK });
  const c5 = ya5.slice(0, 40).filter(k => harfK[k] === 'C').length;
  t(`kalıp: benzer 5 iken 40 ötekinden de orana yakın dolar (C ${c5}/24), benzerler önde, F yok`, ayniKume(alfabe, ya5) && c5 >= 20 && ya5.slice(0, 40).every(k => harfK[k] !== 'F') && [...az5].every(k => ya5.indexOf(k) < ILK + az5.size));
  t('kalıp verisi yok → sıra 4. kuralla BİREBİR aynı', JSON.stringify(dersSirala(alfabe, 'D', es, A, bz, null)) === JSON.stringify(yb));
  t('kalıp: hiçbir sorunun metni okunamadıysa (benzer yok, kalıp yok) sıra 4. kuralla aynı', JSON.stringify(dersSirala(alfabe, 'D', es, A, new Set(), { harf: {}, pay: payK, sona: new Set() })) === JSON.stringify(y));
  t('kalıp: Hukuk hesap ve Denetim vaka sona kuralı', SONA.Hukuk({}, 'F') && !SONA.Hukuk({}, 'C') && SONA['Muhasebe Denetimi']({ soru: '(T) A.Ş.\'nin denetiminde' }) && !SONA['Muhasebe Denetimi']({ soru: 'BDS 220\'ye göre' }) && !SONA['Meslek Hukuku']);
  try {
    const kv = jsonOku(path.join(KOK, 'veri', 'sinav', 'smmm-soru-kalibi.json')).ders, dn = Object.keys(kv);
    t(`gerçek kalıp dağılımı: ${dn.length} ders × 40 soru, Meslek/SPK "doğrudur" 0, Hukuk hesap 0`, dn.length === 8 && dn.every(d => kv[d].n === 40 && Object.keys(kv[d]).filter(h => h !== 'n').reduce((t, h) => t + kv[d][h], 0) === 40)
      && !kv['Meslek Hukuku'].A && !kv['Sermaye Piyasası Mevzuatı'].A && !kv.Hukuk.F && kalipPay('Hukuk') && !('n' in kalipPay('Hukuk')));
  } catch (e) { t('gerçek kalıp dağılımı okunamadı: ' + e.message, false); }
  const eskiF = process.env.SIRA_FABRIKA; process.env.SIRA_FABRIKA = path.join(KOK, 'yok-boyle-klasor');
  const bkY = benzerKume([{ etiket: 'smmm-x', id: 'kp-01' }], 'Finansal Muhasebe');
  if (eskiF === undefined) delete process.env.SIRA_FABRIKA; else process.env.SIRA_FABRIKA = eskiF;
  t('soru metni okunamazsa benzer kümesi boş (eski sıra), sayılır', bkY.s.size === 0 && bkY.metinsiz === 1);
  t('etiketsiz kimlikte zorluk plandan (dog1-vergi zor, ab-a-hukuk kolay), planı yoksa ?', zorluk('smmm-dog1-vergi/kp-01') === 'zor' && zorluk('smmm-ab-a-hukuk/kp-01') === 'kolay' && zorluk('smmm-gm-p1-yvergi/kp-01') === '?');
  t('zorluk kimlikten (kasa-yukle.js ifadesi)', zorluk('smmm-4k-a-yvergi-cokzor-r5/kp-01') === 'cokzor' && zorluk('smmm-4k-d1-yvergi-kolay-r1/kp-01') === 'kolay' && zorluk('smmm-yok-hic/kp-02') === '?');
  // EŞDEĞERLİK ÇAPASI (gerçek veri): ortak agirlikliDiz, havuzun kurulduğu eski iç sirala() ile 8 dersin TAMAMINDA aynı dizi
  try {
    const v = veriYukle(); const ders = {};
    Object.keys(v.es).forEach(id => { (ders[v.es[id].ders] = ders[v.es[id].ders] || []).push(id); });
    let ayni = 0, top = 0;
    for (const d in ders) {
      const ag = v.A[d] || {}, a = agirlikliDiz(ders[d], konuBulucu(v.es, ag), ag), b = eskiSirala(ders[d], v.es, ag);
      top++; if (JSON.stringify(a) === JSON.stringify(b)) ayni++;
    }
    t(`gerçek eşleme: ${top} dersin ${ayni}'inde ortak işlev = havuzun eski sırası`, top >= 8 && ayni === top);
  } catch (e) { t('gerçek eşleme okunamadı: ' + e.message, false); }
  console.log(hata ? `ÖZ-SINAV DÜŞTÜ (${hata})` : 'ÖZ-SINAV GEÇTİ');
  return hata;
}

if (require.main === module) {
  const a = process.argv.slice(2);
  try {
    if (a.includes('--mutasyon')) {
      // kural 8: her bozmada öz-sınav KIRMIZI düşmeli
      const { spawnSync } = require('child_process'); let tutan = 0; const M = ['ilk-sik-yok', 'serpistirme-yok', 'konu-yok', 'plan-yok', 'benzer-yok', 'kalip-suzgec-yok', 'kota-yok', 'sona-yok'];
      for (const m of M) {
        const r = spawnSync(process.execPath, [__filename, '--sinav'], { env: Object.assign({}, process.env, { SIRA_MUTASYON: m }), encoding: 'utf8' });
        const k = r.status !== 0; if (k) tutan++; console.log(`  mutasyon ${m.padEnd(16)} ${k ? 'KIRMIZI (doğru)' : 'YEŞİL — SINAV KÖR'}`);
      }
      console.log(`MUTASYON: ${tutan}/${M.length} → KIRMIZI`); process.exitCode = tutan === M.length ? 0 : 1;
    }
    else if (a.includes('--sinav')) process.exitCode = sinav() ? 1 : 0;
    else if (a.includes('--secim')) secimSirala(a[a.indexOf('--secim') + 1]);
    else { console.log('kullanım: --secim <dosya> | --sinav'); process.exitCode = 1; }
  } catch (e) { console.log('SIRA DÜŞTÜ: ' + e.message); process.exitCode = e.kod || 1; }
}
module.exports = { agirlikHaritasi, agirlikliDiz, konuBulucu, zorluk, zorlukSerpistir, ilkOn, dersSirala, ayniKume, kalipAcigi, kalipSapma };
