// ============================================================================
//  KGK KONU PROFİLİ — her konunun GERÇEK sınav biçimi (30.10.2026, Cem "evet, koy"; 0 USD, model yok)
//
//  Neden: ders ortalaması kusuru gizliyordu. Gerçek sınav aynı konuyu KARIŞIK sorar (sözel + hesap + "yanlıştır"),
//  biz konu başına TEK kalıp yazmışız (30.10 ölçüm: TMS 10 gerçek 13 sorunun 0'ı hesap ↔ bizim 3/3 hesap;
//  "net işletme sermayesi tanımı" gerçek 59 krk sözel ↔ bizim 3/3 hesap; ilk 15 konuda olumsuz kök bizde hep ~0).
//
//  Gerçek = veri/kgk-arsiv/etiket/<id>.json (modül+no+konu) ↔ kitapçık metni (cikmis-kgk-onbellek.json), 2018+.
//  Bağlama: kitapçıkta k. "SORU n:" geçişi = o oturumun k. modülü. 30.10: 31/31 kitapçıkta SORU 1 sayısı modül listesini tuttu.
//
//  node konu-profil.js kur <etiketKlasoru>                  → konu-profil-gercek.json (yeniden kurulum; yeni sınav yutulunca)
//  node konu-profil.js hedef <grup> [--yaz]                  → konu/<grup>.json konularının hedef tablosu (--yaz: konu/profil-<grup>.txt)
//  node konu-profil.js denetle <fabrika> <hazirDesen> <grup> → grubun 3 zorluk dosyasını konu profiline göre ölçer; KUSUR satırı = plan yok
//  node konu-profil.js --sinav                               → öz-sınav (gerçek sorulardan kurulan grup GEÇER, tek kalıp grup DÜŞER)
//
//  🚫 GÖRMEZ: anlamsal benzerlik · sorunun doğruluğu · şık uzunluğu (iki sütunlu kitapçık metninde şık ayrımı oynak;
//    ders düzeyi şık hedefi BRIF-BITIS'te) · çıkmışta 3'ten az sorulmuş konu (konu hedefi yok → ders hedefi geçerli).
// ============================================================================
'use strict';
const fs = require('fs'), path = require('path');
const IS = __dirname, GERCEK = path.join(IS, 'konu-profil-gercek.json');
const katla = s => String(s).replace(/İ/g, 'I').replace(/ı/g, 'i').toLowerCase().replace(/i̇/g, 'i').replace(/ş/g, 's').replace(/ğ/g, 'g').replace(/ü/g, 'u').replace(/ö/g, 'o').replace(/ç/g, 'c').replace(/[âà]/g, 'a').replace(/î/g, 'i').replace(/û/g, 'u').replace(/['’]/g, '');
const kk = s => katla(s).replace(/[^a-z0-9 ]/g, ' ').replace(/\s+/g, ' ').trim();
const med = a => { const s = [...a].sort((x, y) => x - y); return s.length ? s[Math.floor(s.length / 2)] : 0; };
const oku = f => JSON.parse(fs.readFileSync(f, 'utf8').replace(/^﻿/, ''));
const OLUMSUZ = /(yanlistir|yanlis olan|degildir|soylenemez|olamaz|aykiridir|yer almaz|bulunmaz|kapsaminda degil|hangisi yanlis)/;
const ONCUL = /(^|\n|\s)(I|II|III|IV)\.\s/;
// hesap = şıkların en az 3'ü sayı (tutar/oran/süre); kökteki tarih hesap saydırmaz
const sayiSik = s => /^\s*[-−(]?\s*[%]?\s*\d/.test(String(s)) && String(s).replace(/[\d\s.,%()\-−₺TLyılgünay]/gi, '').length <= 6;
// GİZLİ İZLER (03.11, Cem "Evet, kur"; 30.10 ölçümü: "(K) A.Ş." gerçek %0 ↔ biz %53 · kökte yıl %9 ↔ %66 · şık boy oranı 2,1 ↔ 1,3)
//   tek = tek harfli parantezli ad ("(K) A.Ş.", "(L) Bankası"); I/V/X hariç — "(I) ____" boşluk kalıbı Roma rakamıdır.
const TEK_HARF = /\(\s*[A-HJ-UWYZÇĞİÖŞÜ]\s*\)\s*(A\.?\s?Ş|AŞ|[A-ZÇĞİÖŞÜ][a-zçğıöşü])/;
const YIL = /\b20[0-3]\d\b/;
function olc(kok, siklar) {
  const k = katla(kok), u = siklar.map(s => String(s).trim().length || 1);
  return { uz: kok.trim().length, olm: OLUMSUZ.test(k), onc: ONCUL.test(kok), hsp: siklar.filter(sayiSik).length >= 3,
    yil: YIL.test(kok), tek: TEK_HARF.test(kok), sor: u.length ? Math.round(10 * Math.max(...u) / Math.min(...u)) / 10 : 1 };
}

// ---------------------------------------------------------------- kur
// 03.11: bağ İÇERİKLE (kalip/bagla.js). Eski sıra kuralı (aşağıdaki kurEski) iki sütunlu metinde %18–35 kayıyordu — 30.10 profilleri
// kısmen yanlış konudan ölçülmüştü. Girdi: kalip/ayirici-girdi-yeni.json (yeniden-bagla.js) + elle kalıp etiketi (etiket-*.json → kimlik-esle).
function kur() {
  const es = oku(path.join(IS, 'kgk-konu-es.json')).esleme, K = path.join(IS, 'kalip');
  const G = oku(path.join(K, 'ayirici-girdi-yeni.json')), elle = require(path.join(K, 'elle-oku.js'))(K).etiket;
  const P = {}; let n = 0, kalipli = 0;
  for (const q of G) {
    const e = es[kk(q.konu)]; if (!e || e.e) continue; n++;
    const kalip = elle[q.kimlik] && elle[q.kimlik] !== '?' ? elle[q.kimlik] : null; if (kalip) kalipli++;
    (P[e.k] = P[e.k] || { modul: e.d, sorular: [] }).sorular.push({ donem: q.donem, no: q.no, kalip, ...olc(q.kok, q.siklar) });
  }
  fs.writeFileSync(GERCEK, JSON.stringify({ aciklama: 'KGK konu profili (konu-profil.js kur, 03.11 içerik bağı). Her konu: çıkmış soruların ölçüsü (2016+; 2013–14, Mart 2015, Kasım 2018 metni bozuk → yok) + elle kalıp harfi.', kurulus: new Date().toISOString().slice(0, 10), soru: n, kalipli, konu: P }, null, 1));
  console.log(`→ ${GERCEK}: ${Object.keys(P).length} konu · ${n} soru · kalıp etiketli ${kalipli}`);
}
function kurEski(etDir) {
  const es = oku(path.join(IS, 'kgk-konu-es.json')).esleme;
  const C = oku(path.join(IS, 'cikmis-kgk-onbellek.json'));
  const ID = { ca1444: 'ca1444', 8166: '8166', 10202: '10202', 10209: '10209', ca4695: 'ca4695', 10248: '10248', 10270: '10270', ca4801: 'ca4801', '2022-11-12': '11486', '2023-07-08': '11487', 11544: '11544', 11769: '11769', 11967: '11967', 11972: '11972', 12104: '12104', 12103: '12103', 11966: '11966', 11969: '11969', 11970: '11970', 11971: '11971' };
  const isB = d => /(_B[_\-\. ]|B_Kit|-B-|_B\)|Oturumu-B|_-_B|B_Grubu|_B$|SABAH_B|OGLE_B|B_KİT|Sabah_B|ÖS_B|OS_B)/i.test(d);
  const isOgle = d => /(ö_?s_|ös_|öğle|ogle|ikinci|ıkinci|II__Oturum|OS_|Ö_S)/i.test(d);
  const sorular = m => m.split(/\n(?=SORU \d+:)/).map(s => s.match(/^SORU (\d+):\s*([\s\S]*?)\n\s*A\)\s*([\s\S]*)$/)).filter(Boolean).map(x => ({ n: +x[1], kok: x[2].trim(), sik: x[3].split(/\n\s*[B-E]\)\s*/).map(y => y.trim()) }));
  const P = {}, rapor = [];
  for (const [f, id] of Object.entries(ID)) {
    const ef = path.join(etDir, f + '.json'); if (!fs.existsSync(ef)) { rapor.push(f + ': etiket YOK'); continue; }
    const j = oku(ef); const mods = []; for (const q of j.sorular) if (!mods.includes(q.modul)) mods.push(q.modul);
    const kit = C.filter(k => !/CEVAP|GORSEL/.test(k.d) && k.d.includes(id) && !isB(k.d.split('(').pop()));
    let kalan = [...mods];
    for (const L of [kit.filter(k => !isOgle(k.d.split('(').pop())), kit.filter(k => isOgle(k.d.split('(').pop()))]) {
      if (!L.length) continue; const S = sorular(L[0].m); const bu = kalan.splice(0, S.filter(s => s.n === 1).length); const say = {};
      for (const s of S) {
        say[s.n] = (say[s.n] || 0) + 1; const md = bu[say[s.n] - 1]; if (!md) continue;
        const et = j.sorular.find(q => q.modul === md && q.no === s.n); if (!et) continue;
        const e = es[kk(et.konu)]; if (!e || e.e) continue;
        (P[e.k] = P[e.k] || { modul: e.d, sorular: [] }).sorular.push({ donem: j.donem, no: s.n, ...olc(s.kok, s.sik) });
      }
      rapor.push(`${f}: ${bu.length} modül bağlandı`);
    }
  }
  const n = Object.values(P).reduce((a, x) => a + x.sorular.length, 0);
  fs.writeFileSync(GERCEK, JSON.stringify({ aciklama: 'KGK konu profili (konu-profil.js kur). Her konu: çıkmış soruların ölçüsü (2018+).', kurulus: new Date().toISOString().slice(0, 10), soru: n, konu: P }, null, 1));
  console.log(rapor.join('\n') + `\n→ ${GERCEK}: ${Object.keys(P).length} konu · ${n} soru`);
}

// ---------------------------------------------------------------- hedef: 3 soruluk konu payı
const ESIK_N = 3;   // çıkmışta en az 3 kez sorulmuş konu profil taşır
function hedef(konu, P) {
  const p = P[konu]; if (!p || p.sorular.length < ESIK_N) return null;
  const L = p.sorular, n = L.length, pay = f => L.filter(f).length / n;
  const kac = r => Math.round(3 * r);   // grubun 3 sorusunda beklenen adet
  return { n, kok: med(L.map(x => x.uz)), hsp: kac(pay(x => x.hsp)), olm: kac(pay(x => x.olm)), onc: kac(pay(x => x.onc)),
    ham: `${n} soru · kök medyanı ${med(L.map(x => x.uz))} krk · hesap ${L.filter(x => x.hsp).length} · "yanlıştır/değildir" ${L.filter(x => x.olm).length} · öncüllü ${L.filter(x => x.onc).length}`,
    ornek: L.slice(-3).map(x => `${x.donem} S${x.no}`).join(', ') };
}
function hedefTablo(grup, P) {
  const konular = oku(path.join(IS, 'konu', grup + '.json')); const sat = [];
  sat.push(`KONU PROFİLİ — ${grup} (konu-profil.js; gerçek = çıkmış KGK 2016+, metin↔konu bağı içerikle, kalıp elle etiket). Her konunun 3 sorusu (kolay/zor/çok zor) BU KARIŞIMI tutar:`);
  for (const k of konular) {
    const h = hedef(k, P);
    if (!h) { sat.push(`  ${k} → çıkmışta <${ESIK_N} soru: ders hedefi (BRIF-BITIS §1) geçerli`); continue; }
    const tip = h.hsp === 0 ? 'HEPSİ SÖZEL (hesap sorusu YAZMA)' : h.hsp >= 3 ? '3 hesap' : `${h.hsp} hesap + ${3 - h.hsp} sözel`;
    sat.push(`  ${k} → ${tip} · ${h.olm} "yanlıştır/değildir" · ${h.onc} öncüllü · kök ≈${h.kok} krk (en çok ${Math.round(h.kok * 1.35)})`);
    sat.push(`      gerçek: ${h.ham} · bak: ${h.ornek} (cikmis-ara.js)`);
    // B30 kalıp karışımı (03.11): gerçekte bu konu hangi soru cümlesi kalıplarıyla soruldu · sitede hangileri var · önce hangisi yazılır
    const gk = kalipDag(P[k].sorular.map(x => x.kalip)), sk = (siteKalip().konu || {})[k] || {};
    const eksik = Object.keys(gk).filter(x => gk[x] >= 2 && !sk[x]);  // tabloyla aynı tanım: gerçekte ≥2 kez (1 kez görülen kalıp hedef değil) const sTop = Object.entries(sk).sort((a, b) => b[1] - a[1])[0];
    sat.push(`      KALIP: gerçek ${kalipYaz(gk)} · sitede ${kalipYaz(sk) || '—'}${eksik.length ? ` · ÖNCE YAZ: ${eksik.map(x => KALIP_AD[x] || x).join(', ')}` : ''}${sTop && sTop[1] >= 3 ? ` · "${KALIP_AD[sTop[0]] || sTop[0]}" kalıbını EKLEME (sitede zaten ${sTop[1]})` : ''}`);
  }
  sat.push('', 'Kalıp harfleri: ' + Object.entries(KALIP_AD).map(([h, a]) => `${h} ${a}`).join(' · '));
  return sat.join('\n');
}
// ---------------------------------------------------------------- B30 kalıp (03.11)
const KALIP_AD = { A: 'doğrudur', B: 'yanlıştır', C: 'değildir/sayılmaz', U: 'sayılır/kapsam', D: 'öncüllü', E: 'boşluk', G: 'süre/oran/eşik ezberi', F: 'hesap', L: 'sırasıyla', I: 'defter kaydı', J: 'hangi hesap', K: 'kayıt→işlem', M: 'tanım↔terim', N: 'yetkili merci', O: 'ceza/suç', P: 'durum→davranış', S: 'grafik/tablo' };
const kalipDag = L => { const c = {}; for (const h of L) if (h) c[h] = (c[h] || 0) + 1; return c; };
const kalipYaz = c => Object.entries(c).sort((a, b) => b[1] - a[1]).map(([h, n]) => `${h}${n}`).join(' ');
let _site = null; const siteKalip = () => _site || (_site = (() => { try { return oku(path.join(IS, 'kalip', 'site-konu-kalip.json')); } catch (e) { return { konu: {} }; } })());
let _ayir = null; const ayirK = (q) => q._kalip || (_ayir = _ayir || require(path.join(IS, 'kalip', 'kgk-kalip-ayirici.js')).ayir)(String(q.soru || ''), Object.values(q.siklar || {}));
const MODUL_KALIP = {}; const modulKalip = (md, P) => MODUL_KALIP[md] || (MODUL_KALIP[md] = kalipDag(Object.values(P).filter(p => p.modul === md).flatMap(p => p.sorular.map(x => x.kalip))));

// ---------------------------------------------------------------- denetle
// Eşikler 30.10 kalibre edildi (kalibrasyon: gerçek sorulardan 400 rastgele 7 konuluk grup ↔ sitedeki 79 grubumuz).
// Konu başına 3 soru ölçü için az: konu düzeyinde kök kuralı gerçeğin %55'ini düşürüyordu → kök ve olumsuz GRUP düzeyinde.
//   GRUP kök medyanı ≤ konuların gerçek kök medyanlarının medyanı × 1,3     (gerçek %6 düşer · bizimkiler %48)
//   GRUP "yanlıştır/değildir" ≥ gerçek karışımın yarısı                       (gerçek %2 · bizim %53)
//   GRUP hesap adedi gerçek karışımdan en çok max(3, yarısı) kadar sapar       (gerçek %2 · bizim %24)
//   KONU: gerçekte hesap sorulmayan konuya 3 hesap (ya da hedeften 3 fazla)    (gerçek %0 · TMS 10 vakası)
// hazır dosyadaki konu adı sözlük biçiminde olmayabilir (t6/t7 "TMS 10 …") → kgk-konu-es.json ile küme başına (kapsama ile aynı)
let ES = null;
const kume = (k, P) => { if (P[k]) return k; ES = ES || oku(path.join(IS, 'kgk-konu-es.json')).esleme; const e = ES[kk(k)]; return e ? e.k : k; };
// Seyrek konu (çıkmışta <3) → o MODÜLÜN gerçek profili (yedek hedef; konu düzeyi hesap kuralı uygulanmaz).
// 30.10 ölçüldü: t6/t7 seyrek konulara yazılmıştı, yedeksiz kapı 202 konuyu hiç görmüyordu.
const MODUL = {};
function modulHedef(modul, P) {
  if (!modul) return null;
  if (!MODUL[modul]) { const L = Object.values(P).filter(p => p.modul === modul).flatMap(p => p.sorular); const pay = f => L.filter(f).length / (L.length || 1);
    MODUL[modul] = L.length < 30 ? null : { n: L.length, kok: med(L.map(x => x.uz)), hsp: 3 * pay(x => x.hsp), olm: 3 * pay(x => x.olm), onc: 3 * pay(x => x.onc), modul: true }; }
  return MODUL[modul];
}
const modulu = (k, P) => { if (P[k]) return P[k].modul; ES = ES || oku(path.join(IS, 'kgk-konu-es.json')).esleme; const e = ES[kk(k)]; return e ? e.d : null; };
function denetleListe(qs, P) {
  const by = {}; for (const q of qs) { const k = kume(String(q.konu || ''), P); (by[k] = by[k] || []).push(q); }
  const kusur = []; let Ho = 0, Bo = 0, Hh = 0, Bh = 0, prof = 0, yedek = 0; const kg = [], kb = [];
  for (const [k, L] of Object.entries(by)) {
    let h = hedef(k, P); if (h) prof++; else { h = modulHedef(modulu(k, P), P); if (!h) continue; yedek++; }
    const o = L.map(q => olc(String(q.soru || ''), Object.values(q.siklar || {})));
    const hs = o.filter(x => x.hsp).length, ol = o.filter(x => x.olm).length, oran = L.length / 3, hH = Math.round(h.hsp * oran);
    Ho += h.olm * oran; Bo += ol; Hh += h.hsp * oran; Bh += hs; kg.push(h.kok); kb.push(...o.map(x => x.uz));
    if (!h.modul && ((hH === 0 && hs >= 3) || hs - hH >= 3)) kusur.push(`KUSUR ${k}: ${hs}/${L.length} hesap sorusu — gerçekte bu konu ağırlıkla sözel sorulur (${h.ham})`);
  }
  const KG = med(kg), KB = med(kb); prof += yedek;
  if (prof && KB > KG * 1.3) kusur.push(`KUSUR GRUP: kök medyanı ${KB} krk > ${Math.round(KG * 1.3)} (konuların gerçek medyanı ${KG})`);
  if (prof && Bo < Ho * 0.5) kusur.push(`KUSUR GRUP: "yanlıştır/değildir" ${Bo} soru, gerçek karışım ≈${Math.round(Ho)} (en az ${Math.ceil(Ho * 0.5)})`);
  if (prof && Math.abs(Bh - Hh) > Math.max(3, Hh * 0.5)) kusur.push(`KUSUR GRUP: hesap sorusu ${Bh}, gerçek karışım ≈${Math.round(Hh)}`);
  // GİZLİ İZLER — 03.11 kalibre (kalip/iz-kalibre.js, içerik bağlı 3.893 çıkmış soru, 2.000 rastgele 21'lik grup):
  //   tek harfli ad gerçekte 0/3.893 → TEK soruda KUSUR · yıllı kök 21'de p99 = 4 ama eşik 6: 4'te gerçek grupların yalnız %86'sı geçti (gerçeği cezalandırmamak için) · 21'e oranla >6 KUSUR ·
  //   şık en uzun/en kısa medyanı p1 = 1,7 → altı KUSUR. Bizde: t1–t8 tek harf %36–98, yıllı 18–21/21, şık oranı 1,1–1,7; t9 0 · 5 · 1,7.
  const iz = qs.map(q => ({ id: `${q.konu}`, ...olc(String(q.soru || ''), Object.values(q.siklar || {})) }));
  const tekler = iz.filter(x => x.tek); if (tekler.length) kusur.push(`KUSUR İZ: ${tekler.length} soruda tek harfli ad ("(K) A.Ş." gibi; gerçekte 0/3.347) — konular: ${[...new Set(tekler.map(x => x.id))].slice(0, 4).join(', ')}`);
  const yilli = iz.filter(x => x.yil).length, yilTavan = Math.max(1, Math.round(6 * iz.length / 21));  // 4'te gerçek grupların yalnız %86'sı geçiyordu (öz-sınav) → 6
  if (iz.length >= 6 && yilli > yilTavan) kusur.push(`KUSUR İZ: ${yilli}/${iz.length} kökte açık yıl (20xx), en çok ${yilTavan} (gerçek %9) — yıl yalnız kural yıla bağlıysa`);
  const sorM = med(iz.map(x => x.sor)); if (iz.length >= 6 && sorM < 1.7) kusur.push(`KUSUR İZ: şık boy oranı medyanı ${sorM} < 1,7 (gerçek 2,2) — şıklar yapay eşit`);
  // B30 KALIP (03.11): (a) modülün gerçek sınavında hiç görülmemiş kalıp yazılmaz · (b) sitede ≥%60 tek kalıba yığılmış konuya aynı kalıpla
  //   yalnız ekleme yapılmaz (karışım düzelmiyorsa). Kalıp = KGK ayırıcısı (elle etikete uyum %88 — ayırıcı hatası payı vardır).
  let dersDisi = 0; const tekTip = [];
  for (const [k, L] of Object.entries(by)) {
    const md = modulu(k, P); const mk = md ? modulKalip(md, P) : {}; const ks = L.map(ayirK);
    for (const h of ks) if (md && Object.keys(mk).length && !mk[h]) dersDisi++;
    const gk = P[k] ? kalipDag(P[k].sorular.map(x => x.kalip)) : {}; if (Object.keys(gk).length < 2) continue;
    const sk = { ...((siteKalip().konu || {})[k] || {}) }; for (const h of ks) sk[h] = (sk[h] || 0) + 1;
    const top = Object.entries(sk).sort((a, b) => b[1] - a[1])[0]; const n = Object.values(sk).reduce((a, b) => a + b, 0);
    if (n >= 5 && top[1] / n > 0.6 && ks.every(h => h === top[0])) tekTip.push(`${k} (${top[0]} ${top[1]}/${n})`);
  }
  if (dersDisi) kusur.push(`KUSUR KALIP: ${dersDisi} soru modülün gerçek sınavında hiç görülmemiş kalıpla yazılmış`);
  if (tekTip.length) kusur.push(`KUSUR KALIP (B30): tek tipe yığılmış konuya yine aynı kalıp — ${tekTip.slice(0, 3).join(', ')} (hedef dosyasındaki "ÖNCE YAZ" kalıplarından yaz)`);
  return { kusur, prof, ozet: `profilli konu ${prof - yedek}/${Object.keys(by).length} (+${yedek} modül yedeği) · kök ${KB}↔${KG} · olumsuz ${Bo}/≈${Math.round(Ho)} · hesap ${Bh}/≈${Math.round(Hh)} · iz: tek harf ${tekler.length} · yıllı ${yilli}/${iz.length} · şık oranı ${sorM}` };
}
function denetle(fab, desen, grup, P) {
  const re = new RegExp(desen); const qs = [];
  for (const f of fs.readdirSync(fab).filter(x => re.test(x) && new RegExp(`-${grup}-(kolay|zor|cokzor)\\.json$`).test(x))) qs.push(...oku(path.join(fab, f)));
  if (!qs.length) { console.log(`KUSUR ${grup}: hazır dosya bulunamadı (${desen})`); return 1; }
  const r = denetleListe(qs, P);
  console.log(`konu-profil ${grup}: ${qs.length} soru · ${r.ozet}`); for (const k of r.kusur) console.log('  ' + k);
  console.log(r.kusur.length ? `⛔ KONU PROFİLİ ${grup}: ${r.kusur.length} KUSUR` : `✓ KONU PROFİLİ ${grup}: temiz`);
  return r.kusur.length ? 1 : 0;
}

// ---------------------------------------------------------------- öz-sınav
function sinav(P) {
  let hata = 0; const t = (ad, k) => { console.log((k ? '  geçti: ' : '  DÜŞTÜ: ') + ad); if (!k) hata++; };
  const konular = Object.entries(P).filter(([, p]) => p.sorular.length >= 6);
  // gerçek sorulardan grup: her konudan çıkmış 3 soruyu (ölçü olarak) sahte soruya çevir — 200 rastgele 7'li grup
  let rnd = 7; const R = () => (rnd = (rnd * 16807) % 2147483647) / 2147483647;
  // sahte soru gerçek sorunun ölçülerini taşır (olumsuz/öncül/uzunluk/hesap/yıl/şık boy oranı)
  const sik = (x) => { const a = 12, b = Math.max(a, Math.round(a * (x.sor || 1))); return x.hsp ? { A: '10.000 TL', B: '20.000 TL', C: '30.000 TL', D: '40.000 TL', E: '1' + '0'.repeat(Math.max(1, Math.round(9 * (x.sor || 1)) - 1)) + ' TL' } : { A: 'm'.repeat(a), B: 'm'.repeat(a + 1), C: 'm'.repeat(Math.round((a + b) / 2)), D: 'm'.repeat(b - 1), E: 'm'.repeat(b) }; };
  const sahte = (k, x) => ({ konu: k, _kalip: x.kalip, soru: (x.olm ? 'Aşağıdakilerden hangisi yanlıştır? ' : '') + (x.onc ? '\nI. a\nII. b\n' : '') + (x.yil ? '2025 ' : '') + 'x'.repeat(Math.max(0, x.uz - 45)), siklar: sik(x) });
  // gerçek-grup testi SİTE VERİSİZ koşar: B30 tek-tip kuralı bizim sitedeki yığılmaya bakar, gerçek grubun kendisini ölçmez
  const siteYedek = _site; _site = { konu: {} };
  let gecen = 0; const N = 200; const nedenSay = {};
  for (let i = 0; i < N; i++) {
    const qs = []; for (let j = 0; j < 7; j++) { const [k, p] = konular[Math.floor(R() * konular.length)]; const L = [...p.sorular].sort(() => R() - 0.5).slice(0, 3); for (const x of L) qs.push(sahte(k, x)); }
    const ks = denetleListe(qs, P).kusur; if (!ks.length) gecen++; for (const x of ks) { const t = x.replace(/:.*$/, ''); nedenSay[t] = (nedenSay[t] || 0) + 1; }
  }
  console.log('  bilgi: gerçek gruplarda düşme nedenleri: ' + Object.entries(nedenSay).map(([k, v]) => `${k} ${v}`).join(' · '));
  console.log(`  bilgi: gerçek sorulardan kurulan ${N} grubun ${gecen}'i temiz (%${Math.round(100 * gecen / N)})`);
  t('gerçek sorulardan kurulan grupların ≥%85\'i temiz (eşik gerçeği cezalandırmıyor)', gecen / N >= 0.85);
  // B30 vaka: sitede bir konu 5 kez "A"; grup aynı konuya 3 "A" → KUSUR · 3 farklı gerçek kalıp → temiz
  const kB = Object.keys(P).find(k => new Set(P[k].sorular.map(x => x.kalip).filter(Boolean)).size >= 3 && P[k].sorular.length >= 6);
  if (kB) {
    _site = { konu: { [kB]: { A: 5 } } };
    const uc = h => [0, 1, 2].map(i => ({ konu: kB, _kalip: h[i], soru: 'x'.repeat(150), siklar: { A: 'aaaaaaaaaaaaaaaa', B: 'aaaa', C: 'aaaaaaaaa', D: 'aaaaaaa', E: 'aaaaaaaaaaaaa' } }));
    const gk = [...new Set(P[kB].sorular.map(x => x.kalip).filter(h => h && h !== 'A'))];
    t('B30: sitede tek tip konuya yine 3 aynı kalıp → KUSUR', /KALIP \(B30\)/.test(denetleListe(uc(['A', 'A', 'A']), P).kusur.join('|')));
    t('B30: aynı konuya gerçekte görülen farklı kalıplar → B30 temiz', !/KALIP \(B30\)/.test(denetleListe(uc([gk[0], gk[1] || gk[0], 'A']), P).kusur.join('|')));
  }
  _site = siteYedek;
  const k10 = 'tms 10 raporlama sonrasi olaylar';
  if (P[k10]) {
    const tek = [0, 1, 2].map(() => ({ konu: k10, soru: 'x'.repeat(520), siklar: { A: '1.000.000 TL', B: '2.000.000 TL', C: '3.000.000 TL', D: '4.000.000 TL', E: '5.000.000 TL' } }));
    t('TMS 10\'u 3 uzun hesap sorusuyla yazan grup DÜŞER (30.10 vakası)', denetleListe(tek, P).kusur.length > 0);
  }
  const yok = denetleListe([{ konu: 'olmayan konu adi', soru: 'x'.repeat(900), siklar: {} }], P);
  t('profili olmayan konu konu kapısından düşmez (ders hedefine kalır)', yok.kusur.length === 0 && yok.prof === 0);
  t('sayı şık okunur, "TL" yazılı metin şık okunmaz', sayiSik('1.250.000 TL') && sayiSik('%12,5') && !sayiSik('Ertelenmiş vergi varlığı, 1.000 TL'));
  t('tek harfli ad okunur ("(K) A.Ş.", "(L) Bankası"); "(I) ____" boşluğu ve "(TMS 16)" okunmaz',
    TEK_HARF.test('(K) A.Ş., 01.03.2026') && TEK_HARF.test('(L) Bankası kredi') && !TEK_HARF.test('(I) ____ ve (II) ____') && !TEK_HARF.test('(TMS 16) uyarınca'));
  const izG = Array.from({ length: 21 }, (_, i) => ({ konu: 'olmayan konu adi', soru: (i < 10 ? '2026 yılında ' : '') + 'x'.repeat(200), siklar: { A: 'aaaaaaaaaa', B: 'aaaaaaaaaa', C: 'aaaaaaaaab', D: 'aaaaaaaaac', E: 'aaaaaaaaad' } }));
  const izR = denetleListe(izG, P).kusur.join(' | ');
  t('21 soruda 10 yıllı kök + eşit boy şık → iki İZ kusuru', /açık yıl/.test(izR) && /şık boy oranı/.test(izR));
  console.log(hata ? `ÖZ-SINAV DÜŞTÜ (${hata})` : 'ÖZ-SINAV GEÇTİ'); return hata;
}

if (require.main === module) {
  const [kip, a, b, c] = process.argv.slice(2);
  if (kip === 'kur') { kur(a); process.exit(0); }
  const P = oku(GERCEK).konu;
  if (kip === '--sinav') process.exitCode = sinav(P) ? 1 : 0;
  else if (kip === 'hedef') { const s = hedefTablo(a, P); console.log(s); if (process.argv.includes('--yaz')) fs.writeFileSync(path.join(IS, 'konu', `profil-${a}.txt`), s + '\n'); }
  else if (kip === 'denetle') process.exitCode = denetle(a, b, c, P);
  else { console.log('kullanım: kur <etiket> | hedef <grup> [--yaz] | denetle <fabrika> <desen> <grup> | --sinav'); process.exitCode = 1; }
}
module.exports = { olc, hedef, denetleListe };
