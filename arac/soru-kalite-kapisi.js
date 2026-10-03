// arac/soru-kalite-kapisi.js — YENİ SORU KALİTE KAPILARI tek giriş (30.09.2026, Cem "1.2.3 yap ve kural koy"; 03.10 YENİ2 katmanı)
// PowerShell üretim hattı bunu çağırır; mantık modüllerde (aciklama-sayi, eski-kural, hesap-kodu, bds-atif, bos-alan, adim-atif,
// yanlis-yol, turkce-karakter), burada kopya YOK.
//   node arac/soru-kalite-kapisi.js --tek <soru.json>      → her bulgu bir satır "KAPI-AS2: ..." / "NOT-ADIM: ..." (bulgu yoksa boş)
//   node arac/soru-kalite-kapisi.js --parti <kalip-parti-*.json> → JSON {"kp-01":["KAPI-AS2: ..."], ...} (yalnız DURDURAN bulgulu kp'ler)
//   node arac/soru-kalite-kapisi.js --sinav [--mutasyon]   → YENİ2 bağlarının öz-sınavı (ağ yok)
// Çıkış kodu her zaman 0 (karar çağıranın); dosya okunamazsa "KAPI-KALITE KÖR: <neden>" satırı basar, çıkış 2.
// Günlük PUBLIC: satırlar soru metni taşımaz, yalnız alan adı + kural kodu (+ KAPI-AS'ta şık sayıları).
//
// ⭐ 03.10 YENİ2 (Cem: "bütün çıkan hataları kural yaz, bundan sonra basılacak SGS, bitirme, KGK, SPK ne varsa aynı hatayı istemiyorum").
//   Aşağıdaki dört bulgu YALNIZ "YENİ2" soruda DURDURUR; öteki soruda NOT- satırıdır (günlükte görünür, soru düşmez):
//     KAPI-YY   YY-DOGRU / YY-SIKSIZ  (yanlış yol adımı doğru cevaba ya da hiçbir şıkka varmıyor; arac/yanlis-yol-kapisi.js)
//     KAPI-ADIM ADIM-KAYMA            ("(N. adımda bulduk)" başka adımı gösteriyor; ADIM-YOK her zaman NOT)
//     KAPI-TR   TR-ASCII              (açıklama Türkçe harfsiz yazılmış; arac/turkce-karakter-kapisi.js)
//     KAPI-BOS  BOS-KALIP             (istem cümlesi / iç etiket kalıntısı; arac/bos-alan-kapisi.js)
//   YENİ2 = kör çözüm ya da hakem2 tarihinin EN YENİSİ ≥ KALITE_BASLANGIC_YENI2 (varsayılan 2026-10-04; ortam değişkeni yalnız prova
//   içindir — KALITE_BASLANGIC düzeninin kopyası). İkisi de YOKSA soru henüz hakemden geçmemiş üretim girdisidir (FAZ GM hazır soru,
//   koşucu seçiminden önceki taslak) → YENİ2 sayılır. Yayın seçimleri (havuz-kur YeniSoruMu, smmm-yayin-sarti SmmmYeniSoruMu) zaten
//   yalnız tarihli (≥ 2026-10-01) soruyu bu kapıya verir; bugün yayında olan hiçbir sorunun tarihi ≥ 2026-10-04 değildir → hiçbiri düşmez
//   (eşdeğerlik provası 03.10, ambarın tamamı: commit mesajında).
// 🚫 GÖRMEZ (YENİ2 katmanı): yanlış madde/fıkra atfı (S6 — kaynak metinle karşılaştırma gerekir) · soruda olmayan bilgi uydurma / "(soruda
//   verilen)" etiketinin hesaplanan değere konması (S7) · kök muğlaklığı (S8) — üçü açıklama hakemi + elle okuma işidir. Modüllerin
//   kendi GÖRMEZ satırları ayrıca geçerlidir.
'use strict';
const fs = require('fs');
const AS = require('./aciklama-sayi-kapisi.js'), EK = require('./eski-kural-kapisi.js'), HK = require('./hesap-kodu-kapisi.js'), BP = require('./bds-atif-kapisi.js'), BOS = require('./bos-alan-kapisi.js'), ADIM = require('./adim-atif-kapisi.js');
const YY = require('./yanlis-yol-kapisi.js'), TR = require('./turkce-karakter-kapisi.js');
const MUT = process.env.KALITE_MUTASYON || '';
function yeni2Baslangic() { return String(process.env.KALITE_BASLANGIC_YENI2 || '2026-10-04').trim(); }
// Soru YENİ2 mi? (tarih biçimi "YYYY-MM-DD" ya da "YYYY-MM-DD HH:mm"; dize kıyası yeter)
function yeni2Mi(k) {
  if (MUT === 'yeni2-hep-eski') return false;
  if (MUT === 'yeni2-hep-yeni') return true;
  const t = [k && k.kor_cozum && k.kor_cozum.tarih, k && k.hakem2 && k.hakem2.tarih].filter(Boolean).map(String).sort().pop();
  if (!t) return MUT !== 'tarihsiz-eski';
  return t >= yeni2Baslangic();
}
/* 30.09 ölçümü (onarımcılar 93 AS1 alarmını elle okudu): AS1 alarmlarının SGS'de %54'ü, SMMM'de %76'sı YANLIŞ → AS1 soru DURDURMAZ,
   "NOT-AS1" satırı olarak günlüğe düşer. DURDURANLAR: AS2 (açıklama kayması, yapısal) + EK (onarımda 101 soruda 4 yanlış alarm, hepsi
   bilerek konmuş "eski oran" çeldiricisi — arac/eski-kurallar.json haric'i genişletildi). */
function satirlar(k) {
  const c = [];
  const y2 = yeni2Mi(k);
  AS.denetle(k).forEach(b => c.push(b.kod === 'AS2' ? 'KAPI-AS2: ' + b.not : 'NOT-AS1: ' + b.alan + ' ' + b.sik + ' şıkkı yerine ' + b.diger + ' şıkkının sayısını sonuç diye anlatıyor olabilir'));
  EK.denetle(k).forEach(b => c.push('KAPI-EK: ' + b.kod + ' ' + b.alan + ' (' + b.kural + ')'));
  // 30.09 KAPI-HK (Cem "1.2.3, bu kural olsun her sınavda"): THP'de olmayan kod / kodun yanında yanlış hesap adı → DURDURUR.
  //   Adsız "(hesap bağlamı)" bulgusu gürültülü (SGS bankasında 19 bulgunun bir kısmı tutar/gün) → yalnız NOT-HK.
  //   Satır soru metni taşımaz: tür + kod + alan.
  HK.kusurlar(k).forEach(b => c.push((b.tur === 'HK-YOK' && /hesap bağlamı/.test(b.ad) ? 'NOT-HK: ' : 'KAPI-HK: ') + b.tur + ' ' + b.kod + ' ' + b.alan));
  // 30.09 KAPI-BP (Cem "1.2.3"): BDS paragraf atfı. BP-KONU/BP-YOK DURDURUR — 60 bulguluk resmî metin yargısında isabet 24/28 (%86);
  //   BP-ZAYIF (atfedilen paragrafın gövdesi konuyu taşıyor) yalnız NOT-BP — aynı yargıda 30'un 23'ü yanlış alarmdı.
  BP.kusurlar(k).forEach(b => { if (b.tur === 'BP-KOR') return; c.push((b.tur === 'BP-ZAYIF' ? 'NOT-BP: ' : 'KAPI-BP: ') + b.tur + ' BDS ' + b.std + ' ' + b.par + ' ' + b.alan); });
  // 30.09 KAPI-BOS (Cem "1.2.3"): boş şık açıklaması / yer tutucu değer ("placeholder", "yanilgi", "skip") / A–E dışı anahtar → DURDURUR.
  //   SGS bankası 30.09: 42 soru; elle bakılan örneklerin hepsi gerçek (tek yanlış alarm — matematik şıkkı "x" — öz-sınavla ayıklandı).
  //   03.10 BOS-KALIP (istem/iç etiket kalıntısı) yalnız YENİ2'de DURDURUR, eskide NOT-BOS.
  BOS.kusurlar(k).forEach(b => {
    if (b.tur === 'BOS-KALIP') { c.push((y2 && MUT !== 'bos-bagsiz' ? 'KAPI-BOS: ' : 'NOT-BOS: ') + b.tur + ' ' + b.alan); return; }
    c.push('KAPI-BOS: ' + b.tur + ' ' + b.alan);
  });
  // 30.09 KAPI-ADIM (SMMM + SGS ölçtü): "(N. adımda bulduk)" yanlış adımı gösteriyor. 03.10: ADIM-KAYMA yalnız YENİ2'de DURDURUR
  //   (istem kökü son10-uret.ps1 kural 7(d0) 30.09'dan beri). Tek adaylı kaymayı `adim-atif-kapisi.js --duzelt-parti` düzeltebilir ama
  //   03.10 itibarıyla üretime BAĞLI DEĞİL → düzeltilebilir kayma da soruyu döndürür (iş emri: koşucu 8.1'den önce bağlanmalı).
  //   ADIM-YOK (değer hiçbir adımda "= sonuç" değil; biçim farkı olabilir) her zaman NOT.
  ADIM.kusurlar(k).forEach(b => c.push((b.tur === 'ADIM-KAYMA' && y2 && MUT !== 'adim-bagsiz' ? 'KAPI-ADIM: ' : 'NOT-ADIM: ') + b.tur + ' ' + b.alan + ' (' + b.N + '. adım' + (b.dogruN ? ' → ' + b.dogruN : '') + ')'));
  // 03.10 KAPI-YY: yanlış yol adımının sonucu doğru şıkka (YY-DOGRU) ya da hiçbir şıkka (YY-SIKSIZ) varıyor → YENİ2'de DURDURUR.
  //   Ölçüldü 03.10 (--kasa): SGS 974 yanlış yollu sorunun 257'si, SMMM 1.961'in 565'i; elle okunan 15 bulgunun 13'ü gerçek.
  //   Sözel / sonuç sayısız (ölçülmedi) sınıflar satır üretmez.
  YY.kusurlar(k).forEach(b => c.push((y2 && MUT !== 'yy-bagsiz' ? 'KAPI-YY: ' : 'NOT-YY: ') + b.tur + ' ' + b.alan));
  // 03.10 KAPI-TR: Türkçe harfsiz (ASCII) açıklama dizesi → YENİ2'de DURDURUR (yayındaki TurkceOnar tahminle düzeltip hata üretiyordu).
  TR.kusurlar(k).forEach(b => c.push((y2 && MUT !== 'tr-bagsiz' ? 'KAPI-TR: ' : 'NOT-TR: ') + b.tur + ' ' + b.alan));
  return c;
}

// ---- öz-sınav: YENİ2 bağları (yeni soru durur / eski soru durmaz / tarihsiz üretim girdisi durur / ortam değişkeni) ----
function sinav() {
  const SIK = { A: '120.000', B: '147.500', C: '150.000', D: '160.000', E: '175.000' };
  const TEMIZ = 'Öğrenci payı brüt tutar üzerinden hesaplıyor; doğru yol net tutarın yarısını almaktır.';
  const temel = () => ({ soru: 'Kök?', dogru: 'C', siklar: { ...SIK },
    aciklama: { A: 'Oran Tuzağı: oranı ters aldın. Doğrusu: 150.000.', B: 'Kesinti Tuzağı: kesintiyi düştün. Doğrusu: 150.000.', C: 'Ne soruluyor: payın tutarı. Kural: maliyetin yarısı. Doğrusu: 150.000.', D: 'Ekleme Tuzağı: gideri ekledin. Doğrusu: 150.000.', E: 'Toplam Tuzağı: tamamını aldın. Doğrusu: 150.000.' },
    sade: { dogru: TEMIZ },
    adimlar: [{ anlatim: 'Soru bize maliyeti vermiş.', formul: 'Verilen: maliyet 300.000 (soruda verilen)' },
      { anlatim: 'Payı buluyoruz.', formul: 'Pay = 300.000 (soruda verilen) / 2 = 150.000' },
      { anlatim: 'En sık hata kesintiyi düşmektir.', formul: 'Yanlış yol: 300.000 / 2 − 2.500 = 147.500 (HATALI) → doğrusu 150.000 (2. adımda bulduk)' }] });
  const tarihli = (k, t) => { k.kor_cozum = { tarih: t, dogru_mu: true }; k.hakem2 = { tarih: t, karar: 'EVET' }; return k; };
  const bozYY = k => { k.adimlar[2].formul = 'Yanlış yol: 294.000 / 2 = 147.000 (HATALI) → doğrusu 150.000 (2. adımda bulduk)'; return k; };
  const bozADIM = k => { k.adimlar[2].formul = 'Yanlış yol: 300.000 / 2 − 2.500 = 147.500 (HATALI) → doğrusu 150.000 (1. adımda bulduk)'; return k; };
  const bozTR = k => { k.sade = { dogru: 'Ogrenci payi brut tutar uzerinden hesapliyor ve bu yuzden yanlis cikiyor; dogru yol net tutarin yarisini almaktir.' }; return k; };
  const bozBOS = k => { k.aciklama.A = 'Ne soruluyor sorusu tekrar edilmez. Oran Tuzağı: oranı ters aldın. Doğrusu: 150.000.'; return k; };
  const dur = (k, kod) => satirlar(k).some(s => s.startsWith('KAPI-' + kod + ':'));
  const V = [];
  for (const [kod, boz] of [['YY', bozYY], ['ADIM', bozADIM], ['TR', bozTR], ['BOS', bozBOS]]) {
    V.push(['YENİ2 (2026-10-05) soruda ' + kod + ' kusuru → DURUR', () => dur(tarihli(boz(temel()), '2026-10-05'), kod), true]);
    V.push(['eski (2026-10-02, bugün yayında olabilir) soruda ' + kod + ' kusuru → DURMAZ (NOT)', () => !dur(tarihli(boz(temel()), '2026-10-02'), kod) && satirlar(tarihli(boz(temel()), '2026-10-02')).some(s => s.startsWith('NOT-' + kod + ':')), true]);
  }
  V.push(['tarihsiz üretim girdisi (FAZ GM hazır soru) YY kusuru → DURUR', () => dur(bozYY(temel()), 'YY'), true]);
  V.push(['temiz YENİ2 soru → hiç DURDURAN satır yok', () => satirlar(tarihli(temel(), '2026-10-05')).filter(s => /^KAPI-/.test(s)).length === 0, true]);
  V.push(['ADIM-YOK YENİ2\'de de yalnız NOT', () => { const k = tarihli(temel(), '2026-10-05'); k.adimlar[2].formul = 'Yanlış yol: 300.000 / 2 − 2.500 = 147.500 (HATALI) → doğrusu 999 (2. adımda bulduk)'; return !dur(k, 'ADIM') && satirlar(k).some(s => s.startsWith('NOT-ADIM: ADIM-YOK')); }, true]);
  V.push(['ortam değişkeni KALITE_BASLANGIC_YENI2=2026-10-01 → 2026-10-02 soru DURUR', () => { const e = process.env.KALITE_BASLANGIC_YENI2; process.env.KALITE_BASLANGIC_YENI2 = '2026-10-01'; try { return dur(tarihli(bozTR(temel()), '2026-10-02'), 'TR'); } finally { if (e === undefined) delete process.env.KALITE_BASLANGIC_YENI2; else process.env.KALITE_BASLANGIC_YENI2 = e; } }, true]);
  V.push(['kör ve hakem2 tarihinin EN YENİSİ alınır (kör 09-20, hakem2 10-05 → YENİ2)', () => { const k = bozYY(temel()); k.kor_cozum = { tarih: '2026-09-20' }; k.hakem2 = { tarih: '2026-10-05' }; return dur(k, 'YY'); }, true]);
  V.push(['eski bağlar değişmedi: AS2 tarihten bağımsız DURDURUR (eski soru)', () => { const k = tarihli(temel(), '2026-09-01'); k.aciklama.A = 'Ne soruluyor: payın tutarı. Kural: maliyetin yarısı. Doğrusu: 150.000.'; return satirlar(k).some(s => s.startsWith('KAPI-AS2:')); }, true]);
  let ok = 0;
  for (const [ad, f, bek] of V) { let g; try { g = f(); } catch (e) { g = 'HATA ' + e.message; } const t = g === bek; if (t) ok++; console.log((t ? '  ✓ ' : '  ✗ ') + ad); }
  console.log((ok === V.length ? 'KAPI-KALITE YENİ2 ÖZ-SINAVI YEŞİL' : 'KAPI-KALITE YENİ2 ÖZ-SINAVI KIRMIZI') + ` (${ok}/${V.length})` + (MUT ? ' · KALITE_MUTASYON=' + MUT : ''));
  return ok === V.length;
}

module.exports = { satirlar, yeni2Mi };
if (require.main === module) {
  const a = process.argv.slice(2);
  if (a[0] === '--sinav') {
    if (a.includes('--mutasyon')) {
      if (!sinav()) { console.log('MUTASYON koşulmadı: bozulmamış öz-sınav zaten KIRMIZI'); process.exit(1); }
      const { spawnSync } = require('child_process');
      const ler = ['yeni2-hep-eski', 'yeni2-hep-yeni', 'tarihsiz-eski', 'yy-bagsiz', 'adim-bagsiz', 'tr-bagsiz', 'bos-bagsiz'];
      let tutan = 0;
      for (const m of ler) { const r = spawnSync(process.execPath, [__filename, '--sinav'], { env: { ...process.env, KALITE_MUTASYON: m }, encoding: 'utf8' }); const kr = r.status !== 0; if (kr) tutan++; console.log('  mutasyon ' + m + (kr ? ' KIRMIZI (doğru)' : ' YEŞİL (SINAV KÖR!)')); }
      console.log('MUTASYON: ' + tutan + '/' + ler.length + ' mutasyon KIRMIZI'); process.exit(tutan === ler.length ? 0 : 1);
    }
    process.exit(sinav() ? 0 : 1);
  }
  try {
    if (a[0] === '--tek') { satirlar(JSON.parse(fs.readFileSync(a[1], 'utf8').replace(/^﻿/, ''))).forEach(s => console.log(s)); process.exit(0); }
    if (a[0] === '--parti') {
      const p = JSON.parse(fs.readFileSync(a[1], 'utf8').replace(/^﻿/, '')), o = {};
      for (const kp of Object.keys(p)) { if (!/^kp-/.test(kp)) continue; const s = satirlar(p[kp]).filter(x => /^KAPI-/.test(x)); if (s.length) o[kp] = s; }   // yalnız DURDURAN bulgular (NOT-* hariç)
      console.log(JSON.stringify(o)); process.exit(0);
    }
  } catch (e) { console.log('KAPI-KALITE KÖR: ' + String(e.message).slice(0, 120)); process.exit(2); }
  console.log('kullanım: --tek <soru.json> | --parti <kalip-parti.json> | --sinav [--mutasyon]'); process.exit(2);
}
