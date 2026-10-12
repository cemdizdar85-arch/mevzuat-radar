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
//    2) ZORLUK: konu sırası zorluk kovalarına bölünür (kova içinde konu sırası korunur). İlk ILK_KOLAY (10) soru KOLAY
//       kovadan; sonra kovalar kalan sayılarıyla orantılı yumuşak ağırlıklı sırayla serpiştirilir. Zorluk kimlikten okunur
//       (-kolay|-orta|-zor|-cokzor, kasa-yukle.js ile aynı ifade); etiketsiz soru "bilinmiyor" kovasıdır, ilk 10'a girmez.
//  KÜME DEĞİŞMEZ: yalnız sıra değişir. Çıktı girdiyle aynı sayıda ve aynı kimliklerden oluşmazsa ÇIKIŞ 2 (dosya yazılmaz).
//  🚫 GÖRMEZ: sorunun gerçek zorluğu (etiket üretim isteğidir, öğrenci verisi değil) · "orta" etiketi bankada yok (12.10) ·
//    etiketsiz 181 sorunun zorluğu · eşlemenin tek okuyucu hatası · sayfanın seviye testine göre yeniden sıralaması
//    (kasa-yukle.js seviyeSirala; zayıf öğrencide kolay önce, güçlüde zor önce — bu sıra ONUN girdisidir).
//
//  KULLANIM:
//    node motor/smmm-ders-sira.js --secim <secim-<slug>.json>   seçim dosyasını yerinde yeni sıraya dizer (yalnız sayı basar)
//    node motor/smmm-ders-sira.js --sinav                        öz-sınav (gerçek eşleme ile havuz eşdeğerliği dahil)
// ============================================================================
'use strict';
const fs = require('fs'), path = require('path');
const KOK = path.join(__dirname, '..');
const ILK_KOLAY = 10;
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

function zorluk(id) {
  const m = String(id || '').match(/-(kolay|orta|zor|cokzor)(?=[-\/]|$)/);
  return m ? m[1] : '?';
}

// konu sırasındaki kimlikleri zorluğa göre serpiştirir; ilk ILK_KOLAY kolay kovadan
function zorlukSerpistir(sirali) {
  const kova = {}; KOVA.forEach(k => { kova[k] = []; });
  sirali.forEach(id => kova[zorluk(id)].push(id));
  const out = [];
  const ilk = MUT === 'ilk-kolay-yok' ? 0 : ILK_KOLAY;
  while (out.length < ilk && kova.kolay.length) out.push(kova.kolay.shift());
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

// bir dersin kimlikleri → yeni sıra (küme aynı)
function dersSirala(idler, ders, es, A) {
  const agirlik = (A && A[ders]) || {};
  const { dizi, sifir } = agirlikliDiz(idler, konuBulucu(es, agirlik), agirlik);
  const konuSirasi = MUT === 'konu-yok' ? idler.slice().sort() : dizi.concat(sifir);
  return zorlukSerpistir(konuSirasi);
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
  const yeni = dersSirala([...harita.keys()], ders, es, A);
  if (!ayniKume([...harita.keys()], yeni)) { const e = new Error('KÜME DEĞİŞTİ — sıra yazılmadı'); e.kod = 2; throw e; }
  fs.writeFileSync(dosya, JSON.stringify(yeni.map(k => harita.get(k)), null, 1), 'utf8');
  const z = {}; yeni.slice(0, 40).forEach(k => { const t = zorluk(k); z[t] = (z[t] || 0) + 1; });
  const esli = yeni.filter(k => es[k]).length;
  console.log(`  SIRA ${ders}: ${yeni.length} soru · eşlemeli ${esli} · ilk 10 kolay ${yeni.slice(0, 10).filter(k => zorluk(k) === 'kolay').length}/10 · ilk 40 ${KOVA.filter(k => z[k]).map(k => k + ' ' + z[k]).join(' ')}`);
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
  // yapay ders: 3 konu (ağırlık 6/3/1), zorluk etiketleri alfabetik sırada "cokzor" önde
  const es = {}, A = { D: { a: 6, b: 3, c: 1 } }, idler = [];
  const zr = ['cokzor', 'kolay', 'zor', 'zor'];
  // konu kimlik sırasının TERSİNE dağıtılır (alfabede önce seyrek c gelir): sık konu öne ancak konu sırası çalışırsa çıkar
  for (let i = 0; i < 80; i++) { const id = `smmm-x-${zr[i % 4]}-r${String(i).padStart(2, '0')}/kp-01`; idler.push(id); es[id] = { ders: 'D', konular: [i < 27 ? 'c' : i < 54 ? 'b' : 'a'] }; }
  idler.push('smmm-z-etiketsiz/kp-01', 'smmm-z-etiketsiz/kp-02');
  const alfabe = idler.slice().sort();
  const y = dersSirala(alfabe, 'D', es, A);
  t('küme ve sayı aynı', ayniKume(alfabe, y));
  t('ilk 10 soru kolay', y.slice(0, 10).every(k => zorluk(k) === 'kolay'));
  t('alfabetik sıra: ilk soru çok zor (vaka gerçek)', zorluk(alfabe[0]) === 'cokzor');
  let ardisik = 0, enCok = 0; y.forEach(k => { ardisik = zorluk(k) === 'cokzor' ? ardisik + 1 : 0; enCok = Math.max(enCok, ardisik); });
  t('çok zor serpiştirilmiş (art arda en çok 1)', enCok <= 1);
  const cz40 = y.slice(0, 40).filter(k => zorluk(k) === 'cokzor').length;
  t('ilk 40ta çok zor payı tüm payı aşmaz (20/82 → ≤10)', cz40 <= 10 && cz40 >= 5);
  t('etiketsiz soru ilk 10a girmez', y.slice(0, 10).every(k => zorluk(k) !== '?'));
  const ilk20a = y.slice(0, 20).filter(k => es[k] && es[k].konular[0] === 'a').length, ilk20c = y.slice(0, 20).filter(k => es[k] && es[k].konular[0] === 'c').length;
  t('sık konu önde (ilk 20de a > c)', ilk20a > ilk20c);
  t('ilk 10da en az 2 konu (karışık)', new Set(y.slice(0, 10).map(k => (es[k] || { konular: ['?'] }).konular[0])).size >= 2);
  t('sıra kararlı (aynı girdi aynı çıktı, girdi sırası etkisiz)', JSON.stringify(dersSirala(alfabe.slice().reverse(), 'D', es, A)) === JSON.stringify(y));
  t('kolay yetmezse eldeki kadar (2 kolay)', (() => { const l = ['smmm-k-kolay-r1/kp-01', 'smmm-k-kolay-r2/kp-01', 'smmm-k-zor-r1/kp-01', 'smmm-k-cokzor-r1/kp-01']; const o = zorlukSerpistir(l); return ayniKume(l, o) && zorluk(o[0]) === 'kolay' && zorluk(o[1]) === 'kolay'; })());
  t('küme kapısı: eksik/tekrar yakalanır', !ayniKume(['a', 'b'], ['a', 'a']) && !ayniKume(['a', 'b'], ['a']));
  t('zorluk kimlikten (kasa-yukle.js ifadesi)', zorluk('smmm-4k-a-yvergi-cokzor-r5/kp-01') === 'cokzor' && zorluk('smmm-4k-d1-yvergi-kolay-r1/kp-01') === 'kolay' && zorluk('smmm-ab-a-hukuk/kp-02') === '?');
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
      const { spawnSync } = require('child_process'); let tutan = 0; const M = ['ilk-kolay-yok', 'serpistirme-yok', 'konu-yok'];
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
module.exports = { agirlikHaritasi, agirlikliDiz, konuBulucu, zorluk, zorlukSerpistir, dersSirala, ayniKume };
