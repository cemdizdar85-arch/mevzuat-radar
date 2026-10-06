#!/usr/bin/env node
// ============================================================================
//  KAPI-BOS — BOŞ AÇIKLAMA + VERİ KALINTISI KAPISI (30.09.2026, Cem "1.2.3 üçünü de yap")
//  Öğrenciye görünen soru alanlarında üretim kalıntısını yakalar:
//    BOS-ACIK   : bir şıkkın açıklaması yok / boş / yalnız "-" (doğru şık dahil — ekranda "undefined" çıkıyordu)
//    BOS-KALINTI: görünen alanın DEĞERİ yer tutucu: undefined · null · skip · placeholder · TODO · dummy · remove · yanilgi · x
//                 ya da metin içinde "placeholder"/"undefined"/"lorem" geçiyor
//    BOS-ANAHTAR: şıklarda ya da açıklamada A–E dışı / bozuk anahtar ("D2", "F_placeholder", "A_yanlis", "dummy", "B_teshis_note")
//    BOS-KALIP  : (03.10) istem cümlesi / iç etiket ekrana sızmış: "… sorusu/cümlesi tekrar edilmez" · "Seçilmemiş, bu doğru şıktır" ·
//                 "noktasından geliyor" cümlesinde standart künyesiz "p.28 SINAV TUZAĞI" etiketi. soru-kalite-kapisi.js bunu yalnız YENİ2
//                 (kör/hakem2 ≥ 2026-10-04) soruda durdurur; eski soruda NOT-BOS.
//  ÖLÇÜLDÜ (30.09 SGS onarım okumaları, elle): "F_placeholder) yok" şıkkı, boş "D2" şıkkı, hap "placeholder", teşhis değeri "yanilgi"/"skip",
//    doğru şıkta açıklama yok ("undefined"), aciklama.A_yanlis, dummy:"remove" — hepsi yayındaki sorularda.
//  🚫 GÖRMEZ: dolu ama anlamsız metin ("…yasak bu") · Türkçe harfsiz yazım · başka şıkkı anlatan açıklama (KAPI-AS ayrı) ·
//     tablo hücrelerindeki "-" (meşru boş hücre; tablolar taranmaz) · model alanları (hakem/kör…) · BOS-KALIP listesinde olmayan
//     başka istem kalıntısı · "p.28" etiketinin "noktasından geliyor" cümlesi dışında geçmesi · kaynaksız ama küçük harfli etiket.
//  Kullanım: node arac/bos-alan-kapisi.js --sinav [--mutasyon] | --banka <sgs|smmm|kgk> [cikti.json]
// ============================================================================
'use strict';
const fs = require('fs'), path = require('path');
const KOK = path.resolve(__dirname, '..');
const MUT = process.env.BOS_MUTASYON || '';
const HARF = /^[A-E]$/;
// öğrenciye görünen, metin taşıyan alanlar (tablolar ve model alanları hariç)
const GORUNEN = ['soru', 'siklar', 'aciklama', 'sade', 'teshis', 'hap', 'dayanak', 'adimlar', 'konu_giris', 'celdirici_yol', 'notlandirici', 'sinav_taktigi', 'teori_ikiz'];
const YER_TUTUCU = /^\s*(undefined|null|skip|placeholder|todo|dummy|remove|yanilgi|x|n\/a|tbd)\s*$/i;
const ICINDE = /\b(placeholder|undefined|lorem ipsum)\b/i;
// 03.10 BOS-KALIP (Cem "bütün çıkan hataları kural yaz"; 02–03.10 elle okumada sitedeki SGS+bitirme açıklamalarında görüldü):
//   üretim istemindeki talimat cümlesi ya da iç etiket ekrana sızmış. soru-kalite-kapisi.js bunu YALNIZ YENİ2 soruda (≥ 2026-10-04) durdurur.
//   (1) "Ne soruluyor sorusu/cümlesi tekrar edilmez", "bu cümle tekrar edilmez" — istem 3b'nin kendisi ("tamamlama safhasında tekrar edilmez" meşru)
//   (2) "Seçilmemiş, bu doğru şıktır" — teşhis/sade yer tutucusu
//   (3) "Bu soru p.28 SINAV TUZAĞI (1) noktasından geliyor" — kaynak paketinin iç sayfa etiketi; standart künyesi önde ise ("TMS 36 p.28") meşru
const KALIP = [
  ['tekrar-edilmez', /\b(sorusu|soru|c[üu]mle(si)?)\s+tekrar\s+edilmez/i],
  ['secilmemis', /(^|[.;:]\s*)se[çc]ilmemi[şs]\s*[,.]|se[çc]ilmemi[şs],?\s*bu\s+do[ğg]ru\s+[şs][ıi]kt[ıi]r/i],
];
const ETIKET_P = /(?<!(?:TMS|TFRS|BDS|IAS|IFRS|UMS|BOBİ FRS|KGK|ISA|SPK)\s*\d{0,4}[A-Z]?\s*)\bp\.\s?\d+[a-z]?\s+[A-ZÇĞİÖŞÜ]{3,}/;
function kalipBul(t) {
  if (MUT === 'kalip') return null;
  for (const [ad, re] of KALIP) if (re.test(t)) return ad;
  if (/noktas[ıi]ndan\s+geliyor/i.test(t) && (MUT === 'p-etiket-genis' ? /\bp\.\s?\d+\s+[A-ZÇĞİÖŞÜ]{3,}/ : ETIKET_P).test(t)) return 'p-etiketi';
  return null;
}

// 06.10 BOS-KALIP 'tuzak-adi' (Cem "1.2.3"; sinav oturumu t3-olcum): YANLIŞ şıkkın açıklaması tuzak adıyla değil doğru şıkkın çözüm
//   kalıbıyla başlıyor ("Ne soruluyor: …", tek başına "Kural:/Hesap:/Doğrusu:", "…tekrar edilmez/tekrar etmeden…") → ders sayfası tuzak
//   adını "Ne soruluyor" diye basıyordu (SMMM yayında 241 soru; yalnız 4'ünü eski BOS-KALIP görüyordu). Desen arac/tuzak-ayir.ps1
//   TUZAK_KALINTI ile AYNI (sayfa dönüştürücüsü görünümü onarır; bu kapı yeni üretimde kökü durdurur). Doğru şık taranmaz (orada meşru).
//   🚫 GÖRMEZ: tuzak adlı ama içeriği başka şıkkı anlatan açıklama (KAPI-AS) · doğru şıkkın tuzak etiketli olması.
const TUZAK_KALINTI = /^(ne soruluyor|kural|hesap|bu olayda|do[gğ]rusu)$|^ne soruluyor|ne soruluyor\?|tekrar edilmez|tekrarlanmaz|tekrarlamadan|tekrar etmeden/i;
function tuzakAdiKalinti(k) {
  if (MUT === 'tuzak-adi' || !k || !k.aciklama || typeof k.aciklama !== 'object') return [];
  const out = [];
  for (const h of ['A', 'B', 'C', 'D', 'E']) {
    if (h === k.dogru) continue; const v = k.aciklama[h]; if (typeof v !== 'string') continue;
    const m = /^([^:]{3,60}):/.exec(v.trim()); if (!m) continue;
    const ad = m[1].trim().replace(/^\[|\]$/g, '').replace(/\]\s*/g, ' ');
    if (TUZAK_KALINTI.test(ad)) out.push('aciklama.' + h);
  }
  return out;
}

function gez(v, yol, out) {
  if (v == null) return out;
  if (typeof v === 'string') { out.push([yol, v]); return out; }
  if (Array.isArray(v)) { v.forEach((x, i) => gez(x, yol + '[' + i + ']', out)); return out; }
  if (typeof v === 'object') { for (const [k, x] of Object.entries(v)) { if (/tablo/i.test(k)) continue; gez(x, yol + '.' + k, out); } }
  return out;
}

function kusurlar(k) {
  const out = []; if (!k || typeof k !== 'object') return out;
  const ekle = (tur, alan, not) => out.push({ tur, alan, not });
  const siklar = (k.siklar && typeof k.siklar === 'object') ? k.siklar : {};
  // BOS-ANAHTAR: şık ve açıklama anahtarları
  if (MUT !== 'anahtar') {
    for (const h of Object.keys(siklar)) if (!HARF.test(h)) ekle('BOS-ANAHTAR', 'siklar.' + h, 'şıkta A–E dışı anahtar');
    for (const h of Object.keys(siklar)) if (HARF.test(h) && !String(siklar[h] == null ? '' : siklar[h]).trim()) ekle('BOS-ANAHTAR', 'siklar.' + h, 'boş şık metni');
    if (k.aciklama && typeof k.aciklama === 'object') for (const h of Object.keys(k.aciklama)) if (!HARF.test(h)) ekle('BOS-ANAHTAR', 'aciklama.' + h, 'açıklamada A–E dışı anahtar');
    for (const ust of ['dummy', 'B_teshis_note']) if (ust in k) ekle('BOS-ANAHTAR', ust, 'kalıntı anahtar');
  }
  // BOS-ACIK: her geçerli şıkkın açıklaması dolu olmalı
  if (k.aciklama && typeof k.aciklama === 'object' && MUT !== 'acik') {
    for (const h of Object.keys(siklar).filter(x => HARF.test(x))) {
      const v = k.aciklama[h]; const t = v == null ? '' : (typeof v === 'string' ? v : JSON.stringify(v));
      if (!t.trim() || /^\s*[-–—.]*\s*$/.test(t)) ekle('BOS-ACIK', 'aciklama.' + h, h === k.dogru ? 'DOĞRU şıkkın açıklaması yok' : 'şık açıklaması yok');
    }
  }
  // 01.10 (kapanış onarımı ölçtü: borclar-kolay-r4-bulut/kp-02): alan VAR ama boş dize — sayfada boş kutu çıkar
  if (MUT !== 'bos-dize') for (const a of ['hap', 'dayanak', 'notlandirici', 'sinav_taktigi']) if (a in k && typeof k[a] === 'string' && !k[a].trim()) ekle('BOS-KALINTI', a, 'alan boş');
  // BOS-KALINTI: görünen alanlarda yer tutucu değer
  if (MUT !== 'kalinti') {
    for (const alan of GORUNEN) for (const [yol, t] of gez(k[alan], alan, [])) {
      // 30.09 banka: matematikte şık metni "x" meşru (değişken) → şıklarda "x" kalıntı sayılmaz
      if (/^\s*x\s*$/i.test(t) && /(^|\.)siklar\./.test(yol) && MUT !== 'x-sik') continue;
      if (YER_TUTUCU.test(t) && !(MUT === 'x-yok' && /^\s*x\s*$/i.test(t))) ekle('BOS-KALINTI', yol, 'yer tutucu değer "' + t.trim().slice(0, 20) + '"');
      else if (MUT !== 'icinde' && ICINDE.test(t)) ekle('BOS-KALINTI', yol, 'metinde yer tutucu sözcük');
      else { const kb = kalipBul(t); if (kb) ekle('BOS-KALIP', yol, 'üretim kalıntısı kalıp: ' + kb); }
    }
  }
  for (const yol of tuzakAdiKalinti(k)) if (!out.some(b => b.alan === yol && b.tur === 'BOS-KALIP')) ekle('BOS-KALIP', yol, 'üretim kalıntısı kalıp: tuzak-adi (yanlış şık açıklaması çözüm kalıbıyla başlıyor)');
  return out;
}

function banka(sinav, cikti) {
  const d = path.join(KOK, 'veri', 'sinav', 'kaydir-secim'); const ids = new Set();
  for (const f of fs.readdirSync(d).filter(f => new RegExp('^(yayin|vitrin)-' + sinav + '-').test(f))) for (const r of JSON.parse(fs.readFileSync(path.join(d, f), 'utf8').replace(/^﻿/, ''))) if (r.etiket && r.id) ids.add(r.etiket + '/' + r.id);
  const P = {}; let okunan = 0; const sonuc = [];
  for (const id of ids) {
    const [e, kp] = id.split('/'); const pf = path.join(KOK, 'veri', 'fabrika', 'kalip-parti-' + e + '.json');
    if (!(e in P)) P[e] = fs.existsSync(pf) ? JSON.parse(fs.readFileSync(pf, 'utf8').replace(/^﻿/, '')) : null;
    const k = P[e] && P[e][kp]; if (!k) continue; okunan++;
    const b = kusurlar(k); if (b.length) sonuc.push({ anahtar: id, kusurlar: b });
  }
  const tur = {}; for (const s of sonuc) for (const b of s.kusurlar) tur[b.tur] = (tur[b.tur] || 0) + 1;
  console.log(`KAPI-BOS banka (${sinav}): yayında ${ids.size} · okunan ${okunan} · bulgulu soru ${sonuc.length} · ${JSON.stringify(tur)}`);
  if (cikti) fs.writeFileSync(cikti, JSON.stringify(sonuc, null, 1));
}

function sinav() {
  const T = () => ({ soru: 'Kök?', dogru: 'C', siklar: { A: 'a', B: 'b', C: 'c', D: 'd', E: 'e' },
    aciklama: { A: 'Tuzak A.', B: 'Tuzak B.', C: 'Ne soruluyor: … Doğrusu: C.', D: 'Tuzak D.', E: 'Tuzak E.' }, hap: 'Kısa kural.',
    cozum_tablo: { satirlar: [['Kalem', '-']] }, hakem: { gerekce: 'placeholder' } });
  const V = [
    ['temiz soru → bulgu yok', k => k, null],
    ['doğru şıkta açıklama yok', k => { delete k.aciklama.C; return k; }, 'BOS-ACIK'],
    ['yanlış şık açıklaması "-"', k => { k.aciklama.D = ' - '; return k; }, 'BOS-ACIK'],
    ['hap "placeholder"', k => { k.hap = 'placeholder'; return k; }, 'BOS-KALINTI'],
    ['teşhis değeri "yanilgi"', k => { k.teshis = 'yanilgi'; return k; }, 'BOS-KALINTI'],
    ['dayanak "x"', k => { k.dayanak = 'x'; return k; }, 'BOS-KALINTI'],
    ['metin içinde "undefined"', k => { k.sade = { siklar: { A: 'Bu şık undefined döner.' } }; return k; }, 'BOS-KALINTI'],
    ['şıkta "F_placeholder"', k => { k.siklar.F_placeholder = 'yok'; return k; }, 'BOS-ANAHTAR'],
    ['boş "D2" şıkkı', k => { k.siklar.D2 = ''; return k; }, 'BOS-ANAHTAR'],
    ['aciklama.A_yanlis', k => { k.aciklama.A_yanlis = 'x'; return k; }, 'BOS-ANAHTAR'],
    ['dummy:"remove"', k => { k.dummy = 'remove'; return k; }, 'BOS-ANAHTAR'],
    ['tablo hücresi "-" meşru → temiz', k => k, null],
    ['model alanındaki "placeholder" taranmaz', k => k, null],
    ['hap boş dize → KALINTI', k => { k.hap = '  '; return k; }, 'BOS-KALINTI'],
    ['matematik şıkkı "x" meşru → temiz', k => { k.siklar.B = 'x'; k.teori_ikiz = { siklar: { B: 'x' } }; return k; }, null],
    ['"x" sözcük içinde meşru ("x ve y değişkeni") → temiz', k => { k.soru = 'x ve y değişkenleri için çözünüz.'; return k; }, null],
    // 03.10 BOS-KALIP — yakalama (02–03.10 sitede görülen kalıntılar) + meşru kullanım (kapı kuralı 5)
    ['"Ne soruluyor sorusu tekrar edilmez" → KALIP', k => { k.aciklama.A = 'Ne soruluyor sorusu tekrar edilmez. Kural: süre 30 gündür.'; return k; }, 'BOS-KALIP'],
    ['"bu cümle tekrar edilmez" → KALIP', k => { k.sade = { siklar: { B: 'Ne soruluyor: bu cümle tekrar edilmez. Süreyi karıştırdın.' } }; return k; }, 'BOS-KALIP'],
    ['teşhis "Seçilmemiş, bu doğru şıktır." → KALIP', k => { k.teshis = { C: { yanilgi: 'Seçilmemiş, bu doğru şıktır.' } }; return k; }, 'BOS-KALIP'],
    ['"Bu soru p.28 SINAV TUZAĞI (1) noktasından geliyor" → KALIP', k => { k.teshis = { B: { ayirt: 'Bu soru p.28 SINAV TUZAĞI (1) noktasından geliyor.' } }; return k; }, 'BOS-KALIP'],
    ['meşru: "tamamlama safhasında tekrar edilmez" → temiz', k => { k.aciklama.D = 'Safha Karıştırma Tuzağı: Doğrusu: dürüstlük değerlendirmesi kabul safhasında yapılır, tamamlama safhasında tekrar edilmez.'; return k; }, null],
    ['meşru: "Bu soru TMS 36 p.28 KAPSAM noktasından geliyor" (standart künyeli) → temiz', k => { k.hap = 'Bu soru TMS 36 p.28 KAPSAM ayrımı noktasından geliyor.'; return k; }, null],
    ['meşru: "Bu soru … değerlendirilmesi noktasından geliyor" (etiketsiz) → temiz', k => { k.hap = 'Bu soru iki tarafın ayrı değerlendirilmesi noktasından geliyor.'; return k; }, null],
    ['meşru: adımda "Bu doğru şıktır." → temiz', k => { k.adimlar = [{ anlatim: 'Sonuç: 100 KASA alacaklı olur. Bu doğru şıktır.' }]; return k; }, null],
    // 06.10 tuzak-adi — yakalama (t3-olcum sınıfları) + meşru adlar (kapı kuralı 5)
    ['yanlış şık "Ne soruluyor: …" ile başlıyor → KALIP', k => { k.aciklama.A = 'Ne soruluyor: dönem kârı. Kural: götürü gider. Doğrusu: 120.000.'; return k; }, 'BOS-KALIP'],
    ['yanlış şık "Kural: …" ile başlıyor → KALIP', k => { k.aciklama.B = 'Kural: m.40 gereği %70 indirilir.'; return k; }, 'BOS-KALIP'],
    ['yanlış şık tuzak adsız "Doğrusu: …" ile başlıyor → KALIP (06.10 kararı: yanlış şık "<Ad> Tuzağı:" ile başlar)', k => { k.aciklama.D = 'Doğrusu: dürüstlük değerlendirmesi kabul safhasında yapılır.'; return k; }, 'BOS-KALIP'],
    ['meşru: "Kural Tuzağı: …" → temiz', k => { k.aciklama.D = 'Kural Tuzağı: kuralı ters uyguladın.'; return k; }, null],
    ['meşru: "Hesap Seçimi Tuzağı: …" → temiz', k => { k.aciklama.E = 'Hesap Seçimi Tuzağı: 191 yerine 391 seçtin.'; return k; }, null],
  ];
  let ok = 0;
  for (const [ad, f, bek] of V) { const b = kusurlar(f(T())); const g = b.length ? b[0].tur : null; const t = g === bek; if (t) ok++; console.log((t ? '  ✓ ' : '  ✗ ') + ad + (t ? '' : ' → ' + JSON.stringify(b))); }
  console.log((ok === V.length ? 'KAPI-BOS ÖZ-SINAVI YEŞİL' : 'KAPI-BOS ÖZ-SINAVI KIRMIZI') + ` (${ok}/${V.length})` + (MUT ? ' · BOS_MUTASYON=' + MUT : ''));
  return ok === V.length;
}

module.exports = { kusurlar };
if (require.main === module) {
  const [a, b, c] = process.argv.slice(2);
  if (a === '--sinav') {
    if (process.argv.includes('--mutasyon')) {
      // 03.10: önce bozulmamış öz-sınav (eskiden --mutasyon yalnız bozmaları koşuyordu; YEŞİL olmayan sınav da "9/9 KIRMIZI" verebilirdi)
      if (!sinav()) { console.log('MUTASYON koşulmadı: bozulmamış öz-sınav zaten KIRMIZI'); process.exit(1); }
      const { spawnSync } = require('child_process'); const ler = ['anahtar', 'acik', 'kalinti', 'icinde', 'x-yok', 'x-sik', 'bos-dize', 'kalip', 'p-etiket-genis', 'tuzak-adi']; let tutan = 0;
      for (const m of ler) { const r = spawnSync(process.execPath, [__filename, '--sinav'], { env: { ...process.env, BOS_MUTASYON: m }, encoding: 'utf8' }); const kr = r.status !== 0; if (kr) tutan++; console.log('  mutasyon ' + m + (kr ? ' KIRMIZI (doğru)' : ' YEŞİL (SINAV KÖR!)')); }
      console.log('MUTASYON: ' + tutan + '/' + ler.length + ' → KIRMIZI'); process.exit(tutan === ler.length ? 0 : 1);
    }
    process.exit(sinav() ? 0 : 1);
  } else if (a === '--banka') banka(b || 'sgs', c);
  else { console.log('--sinav [--mutasyon] | --banka <sgs|smmm|kgk> [cikti.json]'); process.exit(2); }
}
