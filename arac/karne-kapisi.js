#!/usr/bin/env node
// ============================================================================
//  KAPI-KARNE — ŞIK KARNESİ CEVAP ANAHTARIYLA TUTARLI MI (27.10.2026, Cem "karne-anahtar tutarlılık kapısını kur") · 0 USD
//  Sayfa (motor/kaydir-coz.ps1) "şık karnesini" adımların `sik` + `karar` alanından çizer: karar "y" ile başlıyorsa
//  "YANLIŞ ifade ✗" (kırmızı), değilse "doğru ifade ✓" (yeşil). Karne öğrenciye tek şık göstermelidir: ya TEK yeşil
//  (olumlu kök: "hangisi doğrudur / hangisinde X") ya da TEK kırmızı (olumsuz kök: "hangisi yanlıştır / değildir"), ve o şık
//  ANAHTARDIR. Kök yönü okunmaz; kural yöne bakmaz: tek yeşil = anahtar YA DA tek kırmızı = anahtar.
//    KARNE-CIFT    : aynı harf birden çok adımda (kapanış adımına harf verilmiş / öncül şık harfiyle yazılmış) → karnede çift satır
//    KARNE-HARF    : sik alanı A–E dışı ("I", "V" — öncül şık sanılmış)
//    KARNE-ANAHTAR : tek yeşil = anahtar da değil, tek kırmızı = anahtar da değil (beşi aynı, çoklu yeşil, işaret başka şıkta)
//    KARNE-EKSIK   : en az 4 şık adımı var ama A–E'den biri eksik → yalnız NOT (karnede o satır boş kalır, öğrenciyi yanıltmaz)
//    ölçülmedi     : 4'ten az şık adımı olan soru (hesap sorusu; karne yok) → satır üretmez
//  NİYE VAR (ölçüldü): 24.10 aday bildirimi (KDV m.10/g: beş şık da "doğru ifade") → kasa taraması 10.494 sorunun 3.197'si karneli,
//    155'i çelişkili: farklı şık 34 · beşi aynı 5 · çoklu 116. 155'i elle okundu (24 + 27.10): 9 soru yayından çekildi (cevap/kök
//    güvenilmez), 146'sının açıklaması onarıldı. Kökler: (1) 17.09 arac/sik-kaydir.ps1 şıkları taşıdı, adımları taşımadı · (2) istem
//    "karar = İFADENİN kendisi doğru mu" diyordu → "hangisinde X" sorusunda beşi de doğru · (3) Roma rakamlı öncül şık harfine yazıldı ·
//    (4) kapanış adımına harf verildi.
//  DÜZEY: arac/soru-kalite-kapisi.js üzerinden YALNIZ YENİ2 soruda (kör/hakem2 ≥ 2026-10-04 ya da tarihsiz üretim girdisi) DURDURUR;
//    eski soruda NOT-KARNE. Eşdeğerlik: commit mesajında (ambar önbelleğinin tamamı + yayındaki kasa).
//  🚫 GÖRMEZ: adım METNİNİN doğruluğu (kararı doğru, anlatımı yanlış adım) · formuldeki karar sorusunun şıkla ilgisi · olay adımının
//    köke uyumu · `sik` alanı hiç yazılmamış serbest metin karne ("Şık A:" yazıp sik alanı boş) · kapanış satırındaki ✓/✗ ile karne
//    uyuşmazlığı (kapanış metni okunmaz) · sayfa karnesinin `tablo` alanı (o kaydir-coz'un ürünüdür; kapı kaynağa, adımlara bakar).
//  Kullanım: node arac/karne-kapisi.js --sinav [--mutasyon] | --tek <soru.json> | --kasa [önbellek klasörü]
// ============================================================================
'use strict';
const fs = require('fs'), path = require('path');
const MUT = process.env.KARNE_MUTASYON || '';
const ESIK = MUT === 'esik-3' ? 3 : MUT === 'esik-6' ? 6 : 4;   // karne sayılması için en az şık adımı
const HARFLER = ['A', 'B', 'C', 'D', 'E'];

function sikAdimlari(k) {
  return (Array.isArray(k && k.adimlar) ? k.adimlar : [])
    .filter(a => a && typeof a === 'object' && String(a.sik == null ? '' : a.sik).trim())
    .map(a => ({ h: String(a.sik).trim().toUpperCase(), y: /^y/i.test(String(a.karar || '').trim()) }));
}

// [{tur, not}] — soru metni taşımaz (günlük PUBLIC)
function kusurlar(k) {
  const st = sikAdimlari(k);
  if (st.length < ESIK) return [];
  const out = [];
  const say = {}; st.forEach(s => { say[s.h] = (say[s.h] || 0) + 1; });
  const cift = Object.keys(say).filter(h => say[h] > 1);
  if (cift.length && MUT !== 'cift-yok') out.push({ tur: 'KARNE-CIFT', not: 'harf ' + cift.join('') + ' birden çok adımda' });
  const disi = Object.keys(say).filter(h => !HARFLER.includes(h));
  if (disi.length && MUT !== 'harf-yok') out.push({ tur: 'KARNE-HARF', not: 'A–E dışı sik: ' + disi.join(',') });
  const anahtar = String(k.dogru || '').trim().toUpperCase();
  // Tek harf tek karar: aynı harf iki kez geçiyorsa SON adım karnede kalır sayılmaz — çiftlik zaten ayrı kusur; burada harf kümesi alınır.
  const yesil = [...new Set(st.filter(s => !s.y).map(s => s.h))], kirmizi = [...new Set(st.filter(s => s.y).map(s => s.h))];
  const tekYesil = yesil.length === 1 && yesil[0] === anahtar && !kirmizi.includes(anahtar);
  const tekKirmizi = kirmizi.length === 1 && kirmizi[0] === anahtar && !yesil.includes(anahtar);
  const tutarli = MUT === 'olumsuz-yok' ? tekYesil : MUT === 'olumlu-yok' ? tekKirmizi : (tekYesil || tekKirmizi);
  if (!tutarli && MUT !== 'anahtar-yok') out.push({ tur: 'KARNE-ANAHTAR', not: 'anahtar ' + (anahtar || '?') + ' · yeşil ' + (yesil.sort().join('') || '-') + ' · kırmızı ' + (kirmizi.sort().join('') || '-') });
  const eksik = HARFLER.filter(h => k.siklar && k.siklar[h] != null && String(k.siklar[h]).trim() && !say[h]);
  if (eksik.length) out.push({ tur: 'KARNE-EKSIK', not: 'şık adımı yok: ' + eksik.join('') });
  return out;
}

// ---- öz-sınav: hem yakalaması gereken hem yanlış alarm vermemesi gereken vakalar ----
function sinav() {
  const sik = { A: 'a', B: 'b', C: 'c', D: 'd', E: 'e' };
  const adim = (h, kr) => ({ sik: h, karar: kr, formul: 'Şık ' + h + ': ?', anlatim: '.' });
  const giris = [{ formul: 'Olay: …', anlatim: '.' }, { formul: 'Ne yapacağız: …', anlatim: '.' }];
  const kapanis = { formul: 'Kapanış: …', anlatim: '.' };
  const soru = (dogru, kararlar, ek) => ({ soru: 'Kök?', dogru, siklar: { ...sik }, adimlar: [...giris, ...HARFLER.map((h, i) => adim(h, kararlar[i])), kapanis, ...(ek || [])] });
  const tur = k => kusurlar(k).map(b => b.tur);
  const var_ = (k, t) => tur(k).includes(t);
  const temiz = k => !tur(k).some(t => t !== 'KARNE-EKSIK');
  const V = [
    // yanlış alarm vermemeli
    ['olumlu kök, tek yeşil = anahtar C → temiz', () => temiz(soru('C', ['yanlış', 'yanlış', 'doğru', 'yanlış', 'yanlış']))],
    ['olumsuz kök, tek kırmızı = anahtar B → temiz', () => temiz(soru('B', ['doğru', 'yanlış', 'doğru', 'doğru', 'doğru']))],
    ['karar büyük harf / ASCII ("Yanlis") → temiz', () => temiz(soru('A', ['DOGRU', 'Yanlis', 'yanlış', 'Yanlış', 'yanlis']))],
    ['Roma rakamlı: öncüller sik\'siz adımda + A–E şık adımı tek yeşil → temiz', () => { const k = soru('D', ['yanlış', 'yanlış', 'yanlış', 'doğru', 'yanlış']); k.adimlar.splice(2, 0, { formul: 'Öncül I: …', anlatim: 'Doğru.' }, { formul: 'Öncül II: …', anlatim: 'Yanlış.' }); return temiz(k); }],
    ['hesap sorusu (şık adımı yok) → satır yok', () => kusurlar({ dogru: 'A', siklar: { ...sik }, adimlar: giris }).length === 0],
    ['3 şık adımlı soru (eşik altı) → satır yok', () => kusurlar({ dogru: 'A', siklar: { ...sik }, adimlar: [adim('A', 'doğru'), adim('B', 'doğru'), adim('C', 'doğru')] }).length === 0],
    ['adım yok / adimlar dizi değil → satır yok, hata yok', () => kusurlar({ dogru: 'A', siklar: sik }).length === 0 && kusurlar({ dogru: 'A', adimlar: 'x' }).length === 0],
    ['sik alanı küçük harf/boşluklu (" c ") → harf sayılır, temiz', () => { const k = soru('C', ['yanlış', 'yanlış', 'doğru', 'yanlış', 'yanlış']); k.adimlar[4].sik = ' c '; return temiz(k); }],
    // yakalamalı
    ['24.10 KDV vakası: beşi "doğru", anahtar A → KARNE-ANAHTAR', () => var_(soru('A', ['doğru', 'doğru', 'doğru', 'doğru', 'doğru']), 'KARNE-ANAHTAR')],
    ['beşi "yanlış" → KARNE-ANAHTAR', () => var_(soru('D', ['yanlış', 'yanlış', 'yanlış', 'yanlış', 'yanlış']), 'KARNE-ANAHTAR')],
    ['harf takası: tek yeşil D ama anahtar E → KARNE-ANAHTAR', () => var_(soru('E', ['yanlış', 'yanlış', 'yanlış', 'doğru', 'yanlış']), 'KARNE-ANAHTAR')],
    ['olumsuz kökte tek kırmızı başka şıkta → KARNE-ANAHTAR', () => var_(soru('B', ['doğru', 'doğru', 'yanlış', 'doğru', 'doğru']), 'KARNE-ANAHTAR')],
    ['çoklu yeşil (Roma öncülü harfe yazılmış: A,B,C yeşil) → KARNE-ANAHTAR', () => var_(soru('A', ['doğru', 'doğru', 'doğru', 'yanlış', 'yanlış']), 'KARNE-ANAHTAR')],
    ['kapanış adımına harf (E iki kez) → KARNE-CIFT', () => { const k = soru('B', ['doğru', 'yanlış', 'doğru', 'doğru', 'doğru']); k.adimlar.push({ sik: 'E', karar: 'yanlış', formul: 'Kapanış: …' }); return var_(k, 'KARNE-CIFT'); }],
    ['çift harfin ikisi farklı karar (anahtar hem yeşil hem kırmızı) → KARNE-ANAHTAR', () => { const k = soru('C', ['yanlış', 'yanlış', 'doğru', 'yanlış', 'yanlış']); k.adimlar.push({ sik: 'C', karar: 'yanlış', formul: 'Kapanış' }); return var_(k, 'KARNE-ANAHTAR') && var_(k, 'KARNE-CIFT'); }],
    ['öncül "V" şık sanılmış → KARNE-HARF', () => { const k = soru('C', ['yanlış', 'yanlış', 'doğru', 'yanlış', 'yanlış']); k.adimlar.push(adim('V', 'doğru')); return var_(k, 'KARNE-HARF'); }],
    ['D adımı eksik → KARNE-EKSIK (yalnız not türü)', () => { const k = soru('C', ['yanlış', 'yanlış', 'doğru', 'yanlış', 'yanlış']); k.adimlar = k.adimlar.filter(a => a.sik !== 'D'); return var_(k, 'KARNE-EKSIK') && !var_(k, 'KARNE-ANAHTAR'); }],
    ['4 şık adımı (eşik tam) + beşi doğru → yakalanır', () => { const k = soru('A', ['doğru', 'doğru', 'doğru', 'doğru', 'doğru']); k.adimlar = k.adimlar.filter(a => a.sik !== 'E'); return var_(k, 'KARNE-ANAHTAR'); }],
  ];
  let ok = 0;
  for (const [ad, f] of V) { let g; try { g = f(); } catch (e) { g = 'HATA ' + e.message; } const t = g === true; if (t) ok++; console.log((t ? '  ✓ ' : '  ✗ ') + ad); }
  console.log((ok === V.length ? 'KAPI-KARNE ÖZ-SINAVI YEŞİL' : 'KAPI-KARNE ÖZ-SINAVI KIRMIZI') + ` (${ok}/${V.length})` + (MUT ? ' · KARNE_MUTASYON=' + MUT : ''));
  return ok === V.length;
}

// --kasa: yerel önbellekteki bütün partiler (veri/fabrika/kalip-parti-*.json) → tür sayımı (eşdeğerlik provası)
function kasa(dir) {
  const yeni2Mi = require('./soru-kalite-kapisi.js').yeni2Mi;
  const o = { dosya: 0, soru: 0, karneli: 0, yeni2: { soru: 0, kusurlu: 0, tur: {} }, eski: { soru: 0, kusurlu: 0, tur: {} }, ornek_yeni2: [] };
  for (const f of fs.readdirSync(dir).filter(f => /^kalip-parti-.*\.json$/.test(f))) {
    let p; try { p = JSON.parse(fs.readFileSync(path.join(dir, f), 'utf8').replace(/^﻿/, '')); } catch (e) { continue; }
    o.dosya++;
    for (const kp of Object.keys(p)) {
      if (!/^kp-/.test(kp) || !p[kp] || !p[kp].soru) continue; o.soru++;
      if (sikAdimlari(p[kp]).length >= ESIK) o.karneli++;
      const ks = kusurlar(p[kp]).filter(b => b.tur !== 'KARNE-EKSIK'); const g = yeni2Mi(p[kp]) ? o.yeni2 : o.eski;
      g.soru++; if (ks.length) { g.kusurlu++; ks.forEach(b => { g.tur[b.tur] = (g.tur[b.tur] || 0) + 1; }); if (g === o.yeni2 && o.ornek_yeni2.length < 400) o.ornek_yeni2.push(f.replace(/^kalip-parti-|\.json$/g, '') + '/' + kp); }
    }
  }
  return o;
}

module.exports = { kusurlar };
if (require.main === module) {
  const a = process.argv.slice(2);
  if (a[0] === '--sinav') {
    if (a.includes('--mutasyon')) {
      if (!sinav()) { console.log('MUTASYON koşulmadı: bozulmamış öz-sınav zaten KIRMIZI'); process.exit(1); }
      const { spawnSync } = require('child_process');
      const ler = ['esik-3', 'esik-6', 'cift-yok', 'harf-yok', 'anahtar-yok', 'olumsuz-yok', 'olumlu-yok'];
      let tutan = 0;
      for (const m of ler) { const r = spawnSync(process.execPath, [__filename, '--sinav'], { env: { ...process.env, KARNE_MUTASYON: m }, encoding: 'utf8' }); const kr = r.status !== 0; if (kr) tutan++; console.log('  mutasyon ' + m + (kr ? ' KIRMIZI (doğru)' : ' YEŞİL (SINAV KÖR!)')); }
      console.log('MUTASYON: ' + tutan + '/' + ler.length + ' mutasyon KIRMIZI'); process.exit(tutan === ler.length ? 0 : 1);
    }
    process.exit(sinav() ? 0 : 1);
  }
  if (a[0] === '--tek') { kusurlar(JSON.parse(fs.readFileSync(a[1], 'utf8').replace(/^﻿/, ''))).forEach(b => console.log(b.tur + ': ' + b.not)); process.exit(0); }
  if (a[0] === '--kasa') { console.log(JSON.stringify(kasa(a[1] || path.join(__dirname, '..', 'veri', 'fabrika')), null, 1)); process.exit(0); }
  console.log('kullanım: --sinav [--mutasyon] | --tek <soru.json> | --kasa [klasör]'); process.exit(2);
}
