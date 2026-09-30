// arac/aciklama-sayi-kapisi.js — KAPI-AS: ŞIK AÇIKLAMASI O ŞIKKIN SAYISINI ANLATIYOR MU (30.09.2026, Cem "1.2.3 yap ve kural koy")
//
// Olay (ölçüldü 30.09): SGS risk taramasında elle okunan 1.744 sorunun 334'ü kusurlu çıktı, çoğu AÇIKLAMA kusuru:
// "B neden yanlış" metni B'nin sayısını değil başka şıkkın sayısını anlatıyordu (ör. sade B "4.000 TL" diyor, B = 2.000).
// Dört hakem (hakem · kör çözüm · simülasyon · hakem2) soruya ve anahtara bakıyor; sade/açıklama metnini okuyan yoktu,
// KAPI-KC yalnız DOLULUK ölçüyordu. Bu kapı parasızdır (model yok), yalnız metin ve sayı kıyaslar.
//
// KURAL: sayısal şık X için (şık metninde tek sayı var) X'in açıklama alanlarından biri (aciklama.X, sade.siklar.X)
//   · BAŞKA bir şıkkın sayısını (kökte geçmeyen) içeriyor VE
//   · X'in kendi sayısını hiç içermiyor  → KUSUR "AS1: <alan> <X> şıkkı yerine <Y> şıkkının sayısını anlatıyor".
// 🚫 GÖRMEZ: sözel şıklar · sayıyı doğru yazıp yanlış yoldan anlatan metin · adımlar/ikiz/teşhis içi hesap hataları ·
//   yanlış hesap kodu/madde atfı · şıkkın sayısı kökte de geçiyorsa (belirsiz, atlanır) · birden çok sayılı şık metni.
//   Bunlar açıklama hakeminin (ücretli, ayrı adım) ve elle okumanın işidir; bu kapı "açıklama doğru" DEMEZ.
//
// Kullanım:
//   node arac/aciklama-sayi-kapisi.js --sinav              öz-sınav (dogrula.yml); AS_MUTASYON=<ad> ile bozulmuş hâl
//   node arac/aciklama-sayi-kapisi.js --sinav --mutasyon   her mutasyonda sınav KIRMIZI düşmeli
//   node arac/aciklama-sayi-kapisi.js --dosya <kalip-parti-*.json> [...]   bulguları yazar, bulgu varsa çıkış 1
//   node arac/aciklama-sayi-kapisi.js --banka <önek> [--etiket-dosyasi <risk sonuc klasörü>]   banka taraması + isabet
//   Modül: require('./aciklama-sayi-kapisi.js').denetle(kayit) → [{kod, alan, sik, diger, not}]
'use strict';
const fs = require('fs'), path = require('path');
const MUT = process.env.AS_MUTASYON || '';

/* Türkçe sayı: 96.000 · 2,4 · 1.250,50 · %20 → sayı. Tarih/yıl/madde no gürültüsü kökteki sayılarla elenir. */
const SAYI_RE = /\d{1,3}(?:\.\d{3})+(?:,\d+)?|\d+(?:,\d+)?/g;
function sayilar(metin) {
  const m = String(metin == null ? '' : metin).match(SAYI_RE) || [];
  return m.map(s => Number(s.replace(/\./g, '').replace(',', '.'))).filter(n => isFinite(n));
}
function sikSayisi(metin) {
  const s = sayilar(metin);
  if (MUT === 'cok-sayi') return s.length ? s[0] : null;
  return s.length === 1 ? s[0] : null;
}
/* metinde n sayısı SONUÇ olarak mı geçiyor: ardından (≤ 14 kr) buldun/çıkar/çıktı/elde…, ya da önünde "sonuç"/"bulunan" */
/* 2. ölçüm (30.09): ara değer kalıpları yanlış alarm veriyordu → sayı ile fiil arasında işlem işareti/parantez olmaz
   ("(10+2x5)/50 hesaplarsın" = ara değer), "bulunca/bulunup" ara adımdır, "bulduğun X" önceki adımın sonucudur. */
const SONRA_RE = /^[^+\-−x×*\/÷=()]{0,14}?(?<![a-zçğıöşü])(buldu[mn]?\b|bulmuş|bulur|bulunur|buluyor|bulacak|çıkar\b|çıktı|çıkıyor|çıkmış|çıkacak|elde\s+ed|hesapla(dın|mış|rsın))/i;
const ONCE_RE = /(sonu[cç]\w*|bulunan|çıkan)\s*(olarak\s*)?(:|=)?\s*[^\d]{0,6}$/i;
function sonucMu(metin, n) {
  const t = String(metin); SAYI_RE.lastIndex = 0; let m;
  while ((m = SAYI_RE.exec(t))) {
    if (Number(m[0].replace(/\./g, '').replace(',', '.')) !== n) continue;
    const sonra = t.slice(m.index + m[0].length), once = t.slice(Math.max(0, m.index - 30), m.index);
    if (/[+\-−x×*\/÷(]\s*$/.test(once) && MUT !== 'islem-say') continue;   // işlemin terimi: "(9+3)/3" → ara değer
    if (SONRA_RE.test(sonra) || ONCE_RE.test(once)) return true;
  }
  return false;
}
function metinAl(v) { return v == null ? '' : (typeof v === 'string' ? v : JSON.stringify(v)); }

/* AS2 — AÇIKLAMA KAYMASI (30.09 onarımlarında 7+ soruda görüldü; bankada 233 soru): doğru şıkkın "Ne soruluyor" çözüm metni
   başka harfin altında duruyor ya da açıklamada şıklarda olmayan harf (F) var → öğrenci doğru şıkta çözümü değil tuzak metnini görür.
   Kök kısmen SikSirala (sıralanmış sayısal şık); kalanın kökü ÖLÇÜLMEDİ. */
function kaymaDenetle(k) {
  const b = [];
  if (!k || !k.aciklama || typeof k.aciklama !== 'object' || !k.dogru) return b;
  const ns = Object.keys(k.aciklama).filter(h => /^\s*Ne soruluyor/i.test(metinAl(k.aciklama[h])));
  if (ns.length && (!ns.includes(k.dogru) || MUT === 'kayma-yok') && MUT !== 'kayma-kapali')
    b.push({ kod: 'AS2', alan: 'aciklama', sik: k.dogru, diger: ns.join(','), not: 'aciklama kaymış: doğru şık ' + k.dogru + ', çözüm metni ("Ne soruluyor") ' + ns.join(',') + ' altında' });
  // 30.09 (SGS ticaret onarımı 3 kayıtta gördü; sitede 193 soru ölçüldü): "Ne soruluyor: … Kural: …" çözüm kalıbı doğru şıkla BİRLİKTE
  //   başka şıkta da duruyor → o yanlış şıkta öğrenci tuzak anlatımı yerine çözüm kalıbını görür. İki nokta şart ("Ne soruluyor cümlesindeki…" tuzak cümlesi sayılmaz).
  const nsTam = Object.keys(k.aciklama).filter(h => /^\s*Ne soruluyor\s*:/i.test(metinAl(k.aciklama[h])));
  if (nsTam.length > 1 && MUT !== 'coklu-kapali')
    b.push({ kod: 'AS2', alan: 'aciklama', sik: k.dogru, diger: nsTam.join(','), not: 'çözüm kalıbı ("Ne soruluyor:") birden çok şıkta: ' + nsTam.join(',') });
  const fazla = Object.keys(k.aciklama).filter(h => /^[A-Z]$/.test(h) && k.siklar && !(h in k.siklar));
  if (fazla.length && MUT !== 'fazla-kapali') b.push({ kod: 'AS2', alan: 'aciklama', sik: k.dogru, diger: fazla.join(','), not: 'aciklama şıklarda olmayan harf taşıyor: ' + fazla.join(',') });
  return b;
}
function denetle(k) {
  const bulgu = kaymaDenetle(k);
  if (!k || !k.siklar || typeof k.siklar !== 'object') return bulgu;
  const harfler = Object.keys(k.siklar).filter(h => /^[A-E]$/.test(h));
  const deger = {};
  harfler.forEach(h => { deger[h] = sikSayisi(k.siklar[h]); });
  const sayisal = harfler.filter(h => deger[h] !== null);
  if (sayisal.length < 3) return bulgu;                    // sayısal soru değil
  const kok = new Set(sayilar(k.soru));
  const alanlar = [['aciklama', k.aciklama], ['sade.siklar', k.sade && k.sade.siklar]];
  for (const h of sayisal) {
    if (h === k.dogru && MUT !== 'dogru-dahil') continue;   // doğru şıkkın açıklaması tüm çözümü anlatır
    const v = deger[h];
    if (kok.has(v) && MUT !== 'kok-dahil') continue;         // şık sayısı kökte de geçiyor: belirsiz
    /* doğru şıkkın sayısı sayılmaz: "Doğrusu: 6" meşru (30.09 ölçümü: yanlış alarmların çoğu buydu) */
    const digerleri = sayisal.filter(y => y !== h && (y !== k.dogru || MUT === 'dogru-say') && deger[y] !== v && !kok.has(deger[y]));
    for (const [ad, nesne] of alanlar) {
      if (!nesne || nesne[h] == null) continue;
      const ss = new Set(sayilar(metinAl(nesne[h])));
      const kendi = MUT === 'kendi-yok' ? false : ss.has(v);
      if (kendi) continue;
      /* 30.09 ölçümü: yalnız "sayı geçiyor" kuralı elle okunmuş 1.406 temiz sorunun 194'ünde alarm verdi; örneklenen 16
         alarmın ~2-3'ü gerçekti (ara değer olarak geçen sayı meşru: "(10+2x5)/50"). Kural: başka şıkkın sayısı SONUÇ
         olarak söylenmeli ("40.000 TL çıktı", "20.000 çıkar", "9 buldun", "sonuç 9"). */
      const t = metinAl(nesne[h]);
      const y = digerleri.find(d => ss.has(deger[d]) && (MUT === 'sonuc-yok' || sonucMu(t, deger[d])));
      if (y) bulgu.push({ kod: 'AS1', alan: ad + '.' + h, sik: h, diger: y,
        not: ad + '.' + h + ' ' + h + ' şıkkının sayısını (' + k.siklar[h] + ') değil ' + y + ' şıkkının sayısını (' + k.siklar[y] + ') sonuç diye anlatıyor' });
    }
  }
  return bulgu;
}

/* ---------------- öz-sınav ---------------- */
function sinav() {
  const temel = () => ({ soru: 'Toplam sabit GÜG 96.000 TL, normal kapasite 8.000 birim, üretim 6.000 birim. Fark kaç TL?',
    dogru: 'D', siklar: { A: '3', B: '4', C: '9', D: '12', E: '16' },
    aciklama: { A: '24.000 / 8.000 = 3 buldun.', B: '24.000 / 6.000 = 4 buldun.', C: '72.000 / 8.000 = 9 buldun.', D: 'Ne soruluyor: 96.000 / 8.000 = 12.', E: '96.000 / 6.000 = 16 buldun.' },
    sade: { siklar: { A: 'Boşu kapasiteye bölüp 3 buldun.', B: 'Boşu üretime bölüp 4 buldun.', C: 'İki kez bölüp 9 buldun.', E: 'Üretime bölüp 16 buldun.' } } });
  const vakalar = [
    ['temiz soru → bulgu yok', k => k, 0],
    ['sade B başka şıkkı (9) anlatıyor → AS1', k => { k.sade.siklar.B = 'Yüklenen gideri kapasiteye bölüp 9 buldun.'; return k; }, 1],
    ['aciklama C başka şıkkı (16) anlatıyor → AS1', k => { k.aciklama.C = 'Üretime bölüp 16 buldun.'; return k; }, 1],
    ['kendi sayısını da yazıyorsa alarm yok (kıyas cümlesi)', k => { k.sade.siklar.B = '4 buldun; kapasiteye bölen ise 9 bulur.'; return k; }, 0],
    ['doğru şıkkın açıklaması başka şıkkı sonuç diye anabilir', k => { k.aciklama.D = 'Yanlış yolda 9 buldun sanırsın; doğru yol kapasiteye bölmektir.'; return k; }, 0],
    ['öteki şıkkın sayısı kökte geçiyorsa sayılmaz', k => { k.siklar.E = '6.000'; k.aciklama.E = 'Üretimi yazdın.'; k.sade.siklar.E = 'Üretimi yazdın.'; k.sade.siklar.B = 'Boşu 6.000 birime bölüp 4 bulmak yerine 6.000 dedin.'; k.sade.siklar.B = 'Boşu 6.000 ile karıştırdın.'; return k; }, 0],
    ['başka şıkkın sayısı ARA DEĞER olarak geçiyorsa alarm yok', k => { k.sade.siklar.B = 'Boşta kalanı (16 × 1.500) üretime böldün.'; return k; }, 0],
    ['ara adım kalıpları alarm vermez ("bulduğun 9", "9 bulunca", "(9+3)/3 hesaplarsın")', k => { k.sade.siklar.B = 'Bulduğun 9 değerini (9+3)/3 hesaplarsın; 9 bulunca durmadın.'; return k; }, 0],
    ['"sonuç: 9" biçimi de yakalanır', k => { k.aciklama.A = 'Kapasiteye bölmedin; sonuç 9 olur.'; return k; }, 1],
    ['yanlış şık açıklaması doğru cevabı anarsa ("Doğrusu: 12") alarm yok', k => { k.aciklama.B = 'Pay tuzağı. Doğrusu: 12 çıkar.'; return k; }, 0],
    ['şıkkın kendi sayısı kökte geçiyorsa belirsiz → atlanır', k => { k.soru += ' Birim fiyat 4 TL.'; k.sade.siklar.B = 'Kapasiteye bölüp 9 buldun.'; return k; }, 0],
    ['sözel şıklar → kapı devre dışı', k => { k.siklar = { A: 'Kasa', B: 'Banka', C: 'Alıcılar', D: 'Satışlar', E: 'Stok' }; k.sade.siklar.B = '9'; return k; }, 0],
    ['binlik nokta ve ondalık virgül aynı sayı sayılır', k => { k.siklar = { A: '1.200', B: '2,4', C: '3.600', D: '12.000', E: '4,8' }; k.soru = 'x'; k.dogru = 'D';
      k.aciklama = { A: '1.200 buldun', B: '2,4 buldun', C: '3.600 buldun', D: 'çözüm', E: '4,8 buldun' }; k.sade.siklar = { A: '1200 değil 1.200', B: 'oran 2,4', C: '3.600', E: '4,8' }; return k; }, 0],
    ['iki sayılı şık metni belirsiz → atlanır', k => { k.siklar.B = '4 TL / 2 birim'; k.sade.siklar.B = '9 buldun'; return k; }, 0],
    ['AS2: "Ne soruluyor" doğru şık dışında → kayma', k => { k.aciklama.D = 'Boşu kapasiteye böldün.'; k.aciklama.A = 'Ne soruluyor: 96.000 / 8.000 = 12.'; return k; }, 1],
    ['AS2: açıklamada fazladan F harfi → kayma', k => { k.aciklama.F = 'Fazla metin.'; return k; }, 1],
    ['AS2: doğru şıkta "Ne soruluyor" varsa temiz', k => { k.aciklama.D = 'Ne soruluyor: 96.000 / 8.000 = 12.'; return k; }, 0],
    ['AS2: çözüm kalıbı doğru şıkla birlikte A\'da da → kayma', k => { k.aciklama.A = 'Ne soruluyor: fark soruluyor. Kural: boşu kapasiteye böl.'; return k; }, 1],
    ['AS2: "Ne soruluyor cümlesindeki…" tuzak cümlesi kalıp sayılmaz', k => { k.aciklama.C = 'Ne soruluyor cümlesindeki "fark" sözcüğünü toplam sandın.'; return k; }, 0],
    ['iki alan birden kusurlu → iki bulgu', k => { k.aciklama.A = '9 buldun'; k.sade.siklar.A = '16 buldun'; return k; }, 2]
  ];
  let gecen = 0;
  for (const [ad, f, beklenen] of vakalar) {
    const b = denetle(f(temel()));
    const ok = b.length === beklenen;
    if (ok) gecen++;
    console.log((ok ? '  ✓ ' : '  ✗ ') + ad + (ok ? '' : ' (beklenen ' + beklenen + ', çıkan ' + b.length + ': ' + b.map(x => x.not).join(' | ') + ')'));
  }
  console.log('ACIKLAMA-SAYI-SINAVI: ' + (gecen === vakalar.length ? 'YESIL' : 'KIRMIZI') + ' — ' + gecen + '/' + vakalar.length + (MUT ? ' · AS_MUTASYON=' + MUT : ''));
  return gecen === vakalar.length;
}

/* ---------------- dosya / banka ---------------- */
function partiOku(dosya) { try { return JSON.parse(fs.readFileSync(dosya, 'utf8')); } catch (e) { return null; } }
function partiDenetle(dosya) {
  const p = partiOku(dosya); if (!p || typeof p !== 'object') return [];
  const etiket = path.basename(dosya).replace(/^kalip-parti-/, '').replace(/\.json$/, '');
  const c = [];
  for (const kp of Object.keys(p)) { if (!/^kp-/.test(kp)) continue; denetle(p[kp]).forEach(b => c.push(Object.assign({ anahtar: etiket + '/' + kp }, b))); }
  return c;
}

if (require.main === module) {
  const a = process.argv.slice(2);
  if (a.includes('--sinav')) {
    if (a.includes('--mutasyon')) {
      const { spawnSync } = require('child_process');
      const ler = ['kendi-yok', 'dogru-dahil', 'kok-dahil', 'cok-sayi', 'dogru-say', 'sonuc-yok', 'islem-say', 'kayma-yok', 'kayma-kapali', 'fazla-kapali', 'coklu-kapali'];
      let tutan = 0;
      for (const m of ler) {
        const r = spawnSync(process.execPath, [__filename, '--sinav'], { env: Object.assign({}, process.env, { AS_MUTASYON: m }), encoding: 'utf8' });
        const dustu = r.status !== 0; if (dustu) tutan++;
        console.log('  mutasyon ' + m.padEnd(12) + (dustu ? 'KIRMIZI (doğru)' : 'YESIL (YANLIŞ — sınav bu koşulu ölçmüyor)'));
      }
      console.log('MUTASYON: ' + tutan + '/' + ler.length + ' → KIRMIZI');
      process.exit(tutan === ler.length ? 0 : 1);
    }
    process.exit(sinav() ? 0 : 1);
  }
  const i = a.indexOf('--dosya');
  if (i >= 0) {
    const dosyalar = a.slice(i + 1).filter(x => !x.startsWith('--'));
    let n = 0;
    for (const d of dosyalar) partiDenetle(d).forEach(b => { n++; console.log('KAPI-AS ' + b.anahtar + ' ' + b.not); });
    console.log('KAPI-AS: ' + dosyalar.length + ' parti, ' + n + ' bulgu');
    process.exit(n ? 1 : 0);
  }
  const j = a.indexOf('--banka');
  if (j >= 0) {
    const onek = a[j + 1] || 'sgs-';
    const kok = path.join(__dirname, '..', 'veri', 'fabrika');
    const dosyalar = fs.readdirSync(kok).filter(f => f.startsWith('kalip-parti-' + onek) && f.endsWith('.json'));
    const bulgular = []; let soru = 0, sayisalSoru = 0;
    for (const f of dosyalar) {
      const p = partiOku(path.join(kok, f)); if (!p) continue;
      const et = f.replace(/^kalip-parti-/, '').replace(/\.json$/, '');
      for (const kp of Object.keys(p)) {
        if (!/^kp-/.test(kp)) continue; soru++;
        const k = p[kp];
        if (k && k.siklar && Object.values(k.siklar).filter(s => sikSayisi(s) !== null).length >= 3) sayisalSoru++;
        denetle(k).forEach(b => bulgular.push(Object.assign({ anahtar: et + '/' + kp }, b)));
      }
    }
    const isaretli = new Set(bulgular.map(b => b.anahtar));
    console.log('KAPI-AS BANKA (' + onek + '*): ' + dosyalar.length + ' parti · ' + soru + ' soru · sayısal ' + sayisalSoru + ' · işaretli soru ' + isaretli.size + ' · bulgu ' + bulgular.length);
    const e = a.indexOf('--etiket-dosyasi');
    if (e >= 0) {
      /* isabet: elle okunmuş risk etiketleriyle kıyas (TEMİZ = kusursuz; AÇIKLAMA KUSURLU = kusurlu) */
      const kl = a[e + 1]; const etiket = {};
      for (const f of fs.readdirSync(kl).filter(x => /^sonuc-.*\.json$/.test(x))) {
        let r; try { r = JSON.parse(fs.readFileSync(path.join(kl, f), 'utf8')); } catch (x) { continue; }
        const arr = Array.isArray(r) ? r : (Object.values(r).find(Array.isArray) || []);
        arr.forEach(s => { if (s && s.anahtar) etiket[s.anahtar] = s; });
      }
      let tp = 0, fp = 0, fn = 0, tn = 0; const fpList = [], tpList = [];
      for (const [an, s] of Object.entries(etiket)) {
        const kar = String(s.karar || '');
        if (/OKUNAMADI|ölçülmedi/i.test(kar)) continue;
        const kusurlu = !/^TEM[İI]Z$/i.test(kar);
        const isa = isaretli.has(an);
        if (isa && kusurlu) { tp++; tpList.push(an); } else if (isa && !kusurlu) { fp++; fpList.push(an); } else if (!isa && kusurlu) fn++; else tn++;
      }
      console.log('İSABET (elle okunan ' + (tp + fp + fn + tn) + ' soru): yakalanan kusurlu ' + tp + ' / ' + (tp + fn) + ' · temize yanlış alarm ' + fp + ' / ' + (fp + tn));
      if (fpList.length) console.log('YANLIŞ ALARM: ' + fpList.slice(0, 30).join(', '));
    }
    const o = a.indexOf('--yaz');
    if (o >= 0) fs.writeFileSync(a[o + 1], JSON.stringify({ olcum: new Date().toISOString(), onek, soru, bulgular }, null, 1));
    process.exit(0);
  }
  console.log('kullanım: --sinav [--mutasyon] | --dosya <parti.json...> | --banka <önek> [--etiket-dosyasi <klasör>] [--yaz <çıktı>]');
  process.exit(2);
}
module.exports = { denetle, sayilar, sikSayisi };
