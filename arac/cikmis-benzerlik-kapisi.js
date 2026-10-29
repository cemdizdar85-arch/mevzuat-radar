#!/usr/bin/env node
// KAPI-A1 ÇIKMIŞ BENZERLİK (29.10.2026, Cem "evet kur"). Sözleşme A1 (telif: çıkmış soruyu birebir almak yasak) kapısızdı;
// SORU-URETIM-SOZLESMESI.md "kural olarak yazılı ama mekanik kapısı kurulmamış" tablosundaydı.
// ÖLÇÜ: soru + şıklar kelimelere katlanır (Türkçe harf → ASCII, küçük harf, noktalama boşluk), 5'li kelime öbekleri ambardaki
//   çıkmış arşivle (tur=cikmis-soru SGS+SMMM test + tur=cikmis-komisyon-cevabi SMMM 2008–2025) eşleşir. Arşivde de mevzuat
//   metninde de (veri/mevzuat-hazir/*.txt; hesap planı msugt2.txt içinde) geçen öbek MUAF: kanun lafzı ve hesap adı sınavın da
//   bizim de ortak dilidir; yerelde olmayan lafız (BDS/TMS standartları) ambarın kanun/standart belgelerinde öbek aramasıyla ayıklanır
//   (olcTam). Muaf olmayan eşleşmelerin art arda en uzun dizisi ≥ ESIK kelime → KUSUR.
//   İKİNCİ ÖLÇÜT (ORAN): soru+şık öbeklerinin ≥%60'ı TEK bir arşiv belgesinde → KUSUR, muafiyetsiz (lafız şıklı tam kopya).
// 29.10 ölçümü (140 Son 20 Gün sorusu, 548 belge): muafiyetsiz en uzun dizi 18 kelime (GVK m.1 gelir tanımı, yurt dışı zarar
//   mahsubu), 15+ yalnız 2 soru, ikisi de kanun lafzı. Kök kalıbı ("213 sayılı … Kanunu'na göre aşağıdakilerden hangisi
//   doğrudur") en çok 10–12 kelime → eşiğin altında, ayrıca ayıklanmaz.
// ÖNBELLEK: veri/fabrika/cikmis-5li.bin (+ .json künye), 7 günden eskiyse ambardan yeniden kurulur; ambara ulaşılamazsa eski
//   önbellek kullanılır ve söylenir; önbellek de yoksa KÖR (soru düşmez, "ÖLÇÜLMEDİ" yazılır).
// 🚫 GÖRMEZ: ambarda olmayan çıkmış soru (SMMM 2019–25 soru metni OCR'dan, KGK arşivi dahil DEĞİL — KGK hattı ayrı) ·
//   kelime sırası değiştirilmiş/eş anlamlıyla yeniden yazılmış kopya (anlam benzerliği değil, metin benzerliği) ·
//   rakamları değiştirilmiş ama kurgusu aynı soru (rakamlar dizi kırar).
// KULLANIM: node arac/cikmis-benzerlik-kapisi.js --dosya <hazir.json> [--esik 15] [--tazele]
//           node arac/cikmis-benzerlik-kapisi.js --kur          (önbelleği şimdi kur)
//           node arac/cikmis-benzerlik-kapisi.js --sinav        (öz-sınav: arşivden kopya → KUSUR, özgün → ok)
// ÇIKTI (--dosya): "A1<TAB><sıra 1..n><TAB><ileti>" yalnız kusurlu sorular için; "A1-BILGI<TAB><ileti>" künye.
// Mutasyon: DENETLE_A1_MUTASYON=muafyok → mevzuat muafiyeti kapalı (öz-sınavın kapının kör olmadığını göstermesi için).
"use strict";
const fs = require("fs"), path = require("path");
const KOK = path.resolve(__dirname, "..");
const FAB = path.join(KOK, "veri", "fabrika"), MEV = path.join(KOK, "veri", "mevzuat-hazir");
const BIN = path.join(FAB, "cikmis-5li.bin"), KUNYE = path.join(FAB, "cikmis-5li.json");
const N = 5, GUN = 7, SURUM = 3;   // SURUM 2: KGK kitapçıkları da arşivde · 3: kök kalıbı kelimeleri iki tarafta da atılır
const SB = "https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/dokumanlar";
const arg = process.argv.slice(2), al = k => { const i = arg.indexOf(k); return i >= 0 ? arg[i + 1] : null; };
const ESIK = +(al("--esik") || 15), ORAN = +(al("--oran") || 0.6);

const katla = s => String(s || "").replace(/İ/g, "i").replace(/I/g, "ı").toLowerCase()
  .replace(/ı/g, "i").replace(/ğ/g, "g").replace(/ü/g, "u").replace(/ş/g, "s").replace(/ö/g, "o").replace(/ç/g, "c")
  .replace(/[âà]/g, "a").replace(/î/g, "i").replace(/û/g, "u")
  .replace(/[^a-z0-9]+/g, " ").trim().split(" ").filter(Boolean);
const fnv = s => { let h = 0x811c9dc5; for (let i = 0; i < s.length; i++) { h ^= s.charCodeAt(i); h = Math.imul(h, 0x01000193); } return h >>> 0; };
const oobek = (w, p) => fnv(w.slice(p, p + N).join(" "));

function anahtar() { return (process.env.SUPABASE_SERVICE_KEY || "").trim(); }
async function cek(url, K) {
  for (let d = 1; d <= 3; d++) {
    try { const r = await fetch(url, { headers: { apikey: K, Authorization: "Bearer " + K, "User-Agent": "mevzuat-radar-robot/1.0" } });
      const j = await r.json(); if (Array.isArray(j)) return j; } catch (e) { }
    await new Promise(r => setTimeout(r, 3000 * d));
  }
  throw new Error("ambar okunamadı: " + url.slice(0, 120));
}
// arşiv belgeleri sırayla (bellek dar: 25'er), her belge için cb(ad, kelimeler)
async function arsivGez(K, cb) {
  const kume = [["cikmis-soru", null], ["cikmis-komisyon-cevabi", null]];   // SGS + SMMM test + KGK + SMMM komisyon cevabı
  for (const [tur, ad] of kume) for (let o = 0; ; o += 25) {
    const j = await cek(SB + "?select=kaynak_ad,metin&tur=eq." + tur + (ad ? "&kaynak_ad=ilike." + encodeURIComponent(ad) : "") +
      "&order=kaynak_ad.asc&limit=25&offset=" + o, K);
    for (const d of j) cb(d.kaynak_ad, sade(katla(d.metin)));
    if (j.length < 25) break;
  }
}
async function kur() {
  const K = anahtar(); if (!K) throw new Error("SUPABASE_SERVICE_KEY yok");
  const adlar = [], h = [], b = [];
  await arsivGez(K, (ad, w) => { const bi = adlar.length; adlar.push(ad); for (let p = 0; p + N <= w.length; p++) { h.push(oobek(w, p)); b.push(bi); } });
  const ix = Uint32Array.from(h.keys()).sort((x, y) => h[x] - h[y] || x - y);
  const H = new Uint32Array(ix.length), B = new Uint16Array(ix.length);
  ix.forEach((x, i) => { H[i] = h[x]; B[i] = b[x]; });
  fs.writeFileSync(BIN, Buffer.concat([Buffer.from(H.buffer), Buffer.from(B.buffer)]));
  fs.writeFileSync(KUNYE, JSON.stringify({ surum: SURUM, kuruldu: new Date().toISOString(), oobek: H.length, belge: adlar.length, adlar }, null, 0));
  return { H, B, adlar, kaynak: "ambardan yeni kuruldu" };
}
async function yukle(tazele) {
  let kunye = null; try { kunye = JSON.parse(fs.readFileSync(KUNYE, "utf8")); } catch (e) { }
  const yas = kunye ? (Date.now() - Date.parse(kunye.kuruldu)) / 864e5 : Infinity;
  if (tazele || !kunye || kunye.surum !== SURUM || !fs.existsSync(BIN) || yas > GUN) {
    try { return await kur(); } catch (e) { if (!kunye || !fs.existsSync(BIN)) return { kor: "KÖR: arşiv önbelleği yok ve kurulamadı (" + e.message + ")" }; }
  }
  const buf = fs.readFileSync(BIN), n = kunye.oobek;
  const H = new Uint32Array(buf.buffer.slice(buf.byteOffset, buf.byteOffset + n * 4));
  const B = new Uint16Array(buf.buffer.slice(buf.byteOffset + n * 4, buf.byteOffset + n * 6));
  return { H, B, adlar: kunye.adlar, kaynak: "önbellek " + kunye.kuruldu.slice(0, 10) + (yas > GUN ? " (BAYAT, ambar okunamadı)" : "") };
}
function bul(H, x) { let lo = 0, hi = H.length - 1; while (lo <= hi) { const m = (lo + hi) >> 1; if (H[m] < x) lo = m + 1; else if (H[m] > x) hi = m - 1; else return m; } return -1; }
// mevzuatta geçen öbekler: veri/fabrika/mevzuat-5li.bin (sıralı öbek parmak izi); mevzuat-hazir'de önbellekten yeni dosya
//   varsa yeniden kurulur (27 MB metni her dosyada baştan katlamak dosya başına ~10 sn idi).
const MBIN = path.join(FAB, "mevzuat-5li-v" + SURUM + ".bin");
let MZ = null;
function mevzuatOnbellek() {
  if (MZ) return MZ;
  const txt = fs.readdirSync(MEV).filter(f => f.endsWith(".txt"));
  const enYeni = Math.max(...txt.map(f => fs.statSync(path.join(MEV, f)).mtimeMs));
  if (fs.existsSync(MBIN) && fs.statSync(MBIN).mtimeMs >= enYeni) { const b = fs.readFileSync(MBIN); return MZ = new Uint32Array(b.buffer.slice(b.byteOffset, b.byteOffset + b.length)); }
  let parca = [], top = 0;
  for (const f of txt) { const w = sade(katla(fs.readFileSync(path.join(MEV, f), "utf8"))); const a = new Uint32Array(Math.max(0, w.length - N + 1));
    for (let p = 0; p < a.length; p++) a[p] = oobek(w, p); parca.push(a); top += a.length; }
  const H = new Uint32Array(top); let o = 0; for (const a of parca) { H.set(a, o); o += a.length; } parca = null;
  H.sort(); fs.writeFileSync(MBIN, Buffer.from(H.buffer)); return MZ = H;
}
function mevzuatMuaf(aday) {
  const var_ = new Set(); if (!aday.size || process.env.DENETLE_A1_MUTASYON === "muafyok") return var_;
  const H = mevzuatOnbellek(); aday.forEach(x => { if (bul(H, x) >= 0) var_.add(x); });
  return var_;
}
// AYIRICILAR (29.10 ambar taraması, 53 KUSUR'un elle sınıflaması): soru tarafında bu kelimeler dizi KIRAR, kendileri eşleşmez.
//   (1) HESAP ADI: THP kodu + adı ("129 Şüpheli Ticari Alacaklar Karşılığı") — kayıt şıkkı yeniden yazılamaz; 8 FM/Maliyet KUSUR'u
//       yalnız hesap adı zinciriydi. Liste veri/sinav/thp-hesap-kodlari.json (KAPI-HK ile aynı).
//   (2) KÖK KALIBI: "aşağıdaki… / hangisi… / doğrudur / yanlıştır / değildir / göre / uyarınca" kelimeleri ARŞİV, MEVZUAT ve SORU
//       tarafında ATILIR (dizi kırmaz, saymaz). İlk sürüm bunları kırıcı yapmıştı: öz-sınavda 16 kelimelik kopyanın içindeki tek
//       "göre" diziyi 12'ye böldü (KIRMIZI). Atınca "BDS 701 …'ne göre aşağıdaki ifadelerden hangisi yanlıştır" zinciri kısalır,
//       kopya parça ise bütün kalır.
let THP = null;
function thp() { if (THP) return THP; THP = new Map(); try { const j = JSON.parse(fs.readFileSync(path.join(KOK, "veri", "sinav", "thp-hesap-kodlari.json"), "utf8")).kodlar || {};
  for (const [k, ad] of Object.entries(j)) THP.set(k, katla(ad)); } catch (e) { } return THP; }
const KALIP = /^(asagidaki\w*|hangisi\w*|dogrudur|yanlistir|degildir|gore|uyarinca)$/;
function sade(w) { return w.filter(x => !KALIP.test(x)); }
// soru kelimeleri → { a: kalıpsız kelimeler (hesap adı = null kırıcı), k: a'daki her kelimenin özgün konumu }
function ayir(w) {
  const hes = new Set(), T = thp();
  if (process.env.DENETLE_A1_MUTASYON !== "ayiracyok") for (let i = 0; i < w.length; i++) {
    const ad = T.get(w[i]); if (!ad || !ad.length) continue;
    let k = 0; while (k < ad.length && w[i + 1 + k] === ad[k]) k++;
    if (k >= Math.min(2, ad.length)) { for (let j = i; j <= i + k; j++) hes.add(j); if (w[i + 1 + k] === "hesabi") hes.add(i + 1 + k); }
  }
  const a = [], k = []; w.forEach((x, i) => { if (KALIP.test(x)) return; a.push(hes.has(i) ? null : x); k.push(i); });
  return { a, k };
}
function sikMetin(q) { const s = q && q.siklar; if (!s) return []; return Array.isArray(s) ? s.map(x => (x && x.metin) || x) : Object.values(s); }
function olc(sorular, ar, ekMuaf = []) {
  const W = sorular.map(q => katla((q && q.soru || "") + " " + sikMetin(q).join(" ")));
  const Y = W.map(ayir), A = Y.map(y => y.a);
  const esle = A.map(w => { const e = []; for (let p = 0; p + N <= w.length; p++) { if (w.slice(p, p + N).includes(null)) { e.push(null); continue; }
    const x = oobek(w, p), i = bul(ar.H, x); e.push(i >= 0 ? [x, ar.B[i]] : null); } return e; });
  const aday = new Set(); esle.forEach(e => e.forEach(m => m && aday.add(m[0])));
  const muaf = mevzuatMuaf(aday);
  const belgeler = x => { let m = bul(ar.H, x); if (m < 0) return []; while (m > 0 && ar.H[m - 1] === x) m--; const g = new Set(); for (; m < ar.H.length && ar.H[m] === x; m++) g.add(ar.B[m]); return [...g]; };
  return W.map((w, qi) => { let en = 0, cur = 0, bas = 0, belge = -1;
    // ORAN: sorunun öbeklerinin tek bir arşiv belgesinde geçen payı, muafiyet UYGULANMADAN (lafız şıklı sorunun tamamı kopyalanırsa
    //   dizi ölçütü muafiyet yüzünden kör kalır — 29.10 uçtan uca denemesinde 32 kelimelik KVK lafzı şıkkı geçti)
    const bs = new Map(); esle[qi].forEach(m => { if (m) belgeler(m[0]).forEach(d => bs.set(d, (bs.get(d) || 0) + 1)); });
    const ob = [...bs.entries()].sort((a, b) => b[1] - a[1])[0] || [-1, 0], oran = esle[qi].length ? ob[1] / esle[qi].length : 0;
    const ek = ekMuaf[qi] || new Set();
    esle[qi].forEach((m, p) => { if (m && !muaf.has(m[0]) && !ek.has(p)) { cur++; if (cur > en) { en = cur; bas = p - cur + 1; belge = m[1]; } } else cur = 0; });
    const dizi = en ? en + N - 1 : 0;
    // kaynak: dizinin öbeklerini en çok içeren belge (aynı öbek birçok belgede olabilir)
    if (en) { const say = new Map(); for (let k = bas; k < bas + en; k++) belgeler(esle[qi][k][0]).forEach(d => say.set(d, (say.get(d) || 0) + 1));
      belge = [...say.entries()].sort((a, b) => b[1] - a[1])[0][0]; }
    const K = Y[qi].k, ozgun = dizi ? w.slice(K[bas], K[bas + dizi - 1] + 1) : [];
    const r = { dizi, metin: ozgun.join(" "), kaynak: belge >= 0 ? ar.adlar[belge] : "", oran: +oran.toFixed(3), oranKaynak: ob[0] >= 0 ? ar.adlar[ob[0]] : "", _w: w, _k: K, _bas: bas, _en: en };
    r.kusur = dizi >= ESIK ? "KAPI-A1 çıkmış soruyla " + dizi + " kelime aynı dizi (" + r.kaynak + "): «" + r.metin + "» — soruyu kendi cümlenle yeniden kur"
      : oran >= ORAN ? "KAPI-A1 soru+şık öbeklerinin %" + Math.round(oran * 100) + "'i tek çıkmış belgede (" + r.oranKaynak + ") — lafız şıklı olsa da kurgu kopya; soruyu baştan kur" : "";
    return r; });
}
// İKİNCİ MUAFİYET KATMANI (29.10 ambar taraması: 25.736 soruda 113 KUSUR, örneklerin çoğu BDS/TMS standart lafzıydı — yerel
//   mevzuat-hazir standart metni taşımıyor). Yerel muafiyetten sonra hâlâ ≥ESIK dizi kalırsa dizi 15 kelimelik pencerelerle (5 adım)
//   ambarın yasal kaynaklarında (tur kanun-madde · standart-madde · kanun; teori-notu ve çıkmışlar HARİÇ) arama_fold=phfts(simple)
//   ile öbek olarak aranır; bulunan pencerenin öbekleri muaf sayılır ve dizi yeniden ölçülür (en çok 4 tur).
//   Sonuçlar veri/fabrika/cikmis-lafiz.json'da saklanır. Ambara ulaşılamazsa KUSUR kalır, iletiye "lafız sorgusu yapılamadı" eklenir.
const LAFIZ = path.join(FAB, "cikmis-lafiz.json"); let LZ = null, lzKirli = false;
async function lafizAmbarda(ifade) {
  if (!LZ) { try { LZ = JSON.parse(fs.readFileSync(LAFIZ, "utf8")); } catch (e) { LZ = {}; } }
  if (ifade in LZ) return LZ[ifade];
  const K = anahtar(); if (!K) return null;
  try { const j = await cek(SB + "?select=kaynak_ad&tur=in.(kanun-madde,standart-madde,kanun)&arama_fold=phfts(simple)." + encodeURIComponent(ifade) + "&limit=1", K);
    LZ[ifade] = j.length ? j[0].kaynak_ad : ""; lzKirli = true; return LZ[ifade]; } catch (e) { return null; }
}
function lafizKaydet() { if (lzKirli) { fs.writeFileSync(LAFIZ, JSON.stringify(LZ)); lzKirli = false; } }
async function olcTam(sorular, ar) {
  const ek = sorular.map(() => new Set()); let r = olc(sorular, ar, ek); const hata = new Set(), lafizK = sorular.map(() => []);
  if (process.env.DENETLE_A1_MUTASYON === "muafyok") return r;
  for (let tur = 0; tur < 4; tur++) {
    let degisti = false;
    for (let qi = 0; qi < r.length; qi++) { const x = r[qi]; if (x.dizi < ESIK) continue;
      const L = x.dizi, pen = [];   // pencere kalıpsız konumlarda; ambar sorgusu özgün kelimelerle (kalıp kelimeleri dahil, öbek bitişik kalsın)
      for (let a = 0; a + ESIK <= L; a += 5) pen.push(a); if (L > ESIK && (L - ESIK) % 5) pen.push(L - ESIK);
      for (const a of pen) { const k = await lafizAmbarda(x._w.slice(x._k[x._bas + a], x._k[x._bas + a + ESIK - 1] + 1).join(" "));
        if (k === null) { hata.add(qi); continue; } if (!k) continue;
        for (let p = x._bas + a; p + N <= x._bas + a + ESIK; p++) ek[qi].add(p); lafizK[qi].push(k); degisti = true; } }
    if (!degisti) break; r = olc(sorular, ar, ek);
  }
  lafizKaydet();
  r.forEach((x, qi) => { if (lafizK[qi].length) x.lafiz = [...new Set(lafizK[qi])].slice(0, 3); if (x.kusur && hata.has(qi)) x.kusur += " (lafız sorgusu yapılamadı)"; });
  return r;
}
function liste(dosya) { const j = JSON.parse(fs.readFileSync(dosya, "utf8").replace(/^﻿/, "")); return Array.isArray(j) ? j : j.soru ? [j] : (j.sorular || Object.values(j)); }

(async () => {
  if (arg.includes("--kur")) { const a = await kur(); console.log("A1-BILGI\tönbellek kuruldu: " + a.adlar.length + " belge · " + a.H.length + " öbek"); return; }
  if (arg.includes("--sinav")) {
    const ar = await yukle(false); if (ar.kor) { console.log("KAPI-A1 SINAVI KÖR: " + ar.kor); process.exitCode = 2; return; }
    const K = anahtar(); const j = await cek(SB + "?select=metin&kaynak_ad=eq." + encodeURIComponent("CIKMIS SINAV - SMMM 2026/1 (smmm_2026_1_05)"), K);
    const w = sade(katla(j[0].metin));
    // mevzuatta geçmeyen 30 kelimelik pencere (kanun lafzı muaf olduğu için kopya sınavı lafız dışı bir parçayla yapılır)
    const pen = []; for (let p = 400; p + 30 <= w.length && pen.length < 40; p += 37) pen.push(p);
    const adayS = new Set(); pen.forEach(p => { for (let k = 0; k + N <= 30; k++) adayS.add(oobek(w, p + k)); });
    const mz = mevzuatMuaf(adayS); const p0 = pen.find(p => { for (let k = 0; k + N <= 30; k++) if (mz.has(oobek(w, p + k))) return false; return true; });
    if (p0 === undefined) { console.log("KAPI-A1 SINAVI KÖR: lafız dışı pencere bulunamadı"); process.exitCode = 2; return; }
    const kopya = { soru: w.slice(p0, p0 + 30).join(" "), siklar: { A: "bir", B: "iki", C: "üç", D: "dört", E: "beş" } };
    const yarim = { soru: "Bir işletmenin muhasebe müdürü yıl sonunda şu notu düştü: " + w.slice(p0, p0 + 8).join(" ") + " göre aşağıdakilerden " + w.slice(p0 + 8, p0 + 16).join(" ") + " — buna göre hangisi doğrudur?", siklar: { A: "x", B: "y", C: "z", D: "t", E: "u" } };
    const ozgun = { soru: "Mor Lale Ticaret AŞ, depodaki yirmi iki koli kırık fincanı yıl sonunda saydığında bunların on birinin sigortalı olduğunu fark etmiştir. Buna göre aşağıdakilerden hangisi doğrudur?", siklar: { A: "Kolilerin tamamı gider yazılır", B: "Sigortalı koliler alacak kaydedilir", C: "Kayıt yapılmaz", D: "Stok artırılır", E: "Sermaye azaltılır" } };
    // lafız ağırlıklı 50 kelimelik parça: dizi ölçütü muafiyet yüzünden < ESIK kalan ilk pencere → oran ölçütü yakalamalı
    let lafiz = null; for (let p = 0; p + 50 <= w.length && !lafiz; p += 11) { const c = { soru: w.slice(p, p + 50).join(" ") }; if (olc([c], ar)[0].dizi < ESIK) lafiz = c; }
    if (!lafiz) { console.log("KAPI-A1 SINAVI KÖR: lafız ağırlıklı pencere bulunamadı"); process.exitCode = 2; return; }
    const ad = ["kopya 30 kelime", "16 kelime gömülü (ortasında kök kalıbı)", "özgün", "lafız ağırlıklı tam kopya 50 kelime"];
    const r = await olcTam([kopya, yarim, ozgun, lafiz], ar), bek = [true, true, false, true];
    let h = 0; r.forEach((x, i) => { const ok = !!x.kusur === bek[i]; if (!ok) h++; console.log((ok ? "  ✓ " : "  ✗ ") + ad[i] + ": dizi " + x.dizi + " · tek belge %" + Math.round(x.oran * 100) + (x.kaynak ? " · " + x.kaynak : "")); });
    console.log(h ? "KAPI-A1 SINAVI KIRMIZI: " + h + "/" + r.length : "KAPI-A1 SINAVI YESIL: " + r.length + "/" + r.length); process.exitCode = h ? 1 : 0; return;
  }
  if (arg.includes("--toplu")) {   // node … --toplu <klasör> [--desen <regex>]: önbellek bir kez yüklenir, her dosya ölçülür (eşdeğerlik: ambarın TAMAMI)
    const kl = al("--toplu"), de = new RegExp(al("--desen") || "^(kalip-parti|hazir)-(?!dusen).*\\.json$"), ar = await yukle(false);
    if (ar.kor) { console.log("A1-BILGI\t" + ar.kor); process.exitCode = 2; return; }
    let dS = 0, sS = 0, kS = 0, hata = 0; const enD = [0, ""], enO = [0, ""];
    for (const f of fs.readdirSync(kl).filter(f => de.test(f))) { let L; try { L = liste(path.join(kl, f)).filter(q => q && q.soru); } catch (e) { hata++; continue; }
      dS++; sS += L.length; (await olcTam(L, ar)).forEach((x, i) => { if (x.dizi > enD[0]) { enD[0] = x.dizi; enD[1] = f + "[" + i + "]"; } if (x.oran > enO[0]) { enO[0] = x.oran; enO[1] = f + "[" + i + "]"; }
        if (x.kusur) { kS++; console.log("A1T\t" + f + "\t" + (i + 1) + "\t" + x.kusur); } }); }
    console.log("A1-BILGI\tTOPLU: " + dS + " dosya · " + sS + " soru · KUSUR " + kS + " · okunamayan dosya " + hata + " · en uzun dizi " + enD[0] + " (" + enD[1] + ") · tek belge en çok %" + Math.round(enO[0] * 100) + " (" + enO[1] + ") · " + ar.adlar.length + " arşiv belgesi");
    return;
  }
  const dosya = al("--dosya"); if (!dosya) { console.error("kullanım: --dosya <hazir.json> | --kur | --sinav"); process.exitCode = 2; return; }
  const ar = await yukle(arg.includes("--tazele"));
  if (ar.kor) { console.log("A1-BILGI\tÇIKMIŞ BENZERLİK (KAPI-A1): ÖLÇÜLMEDİ — " + ar.kor); return; }
  const r = await olcTam(liste(dosya), ar);
  console.log("A1-BILGI\tÇIKMIŞ BENZERLİK (KAPI-A1): " + ar.adlar.length + " arşiv belgesi · " + ar.kaynak + " · eşik " + ESIK + " kelime · en uzun dizi " + Math.max(0, ...r.map(x => x.dizi)) + " · tek belge oranı en çok %" + Math.round(100 * Math.max(0, ...r.map(x => x.oran))) + " (eşik %" + Math.round(ORAN * 100) + ")" + (process.env.DENETLE_A1_MUTASYON === "muafyok" ? " · ⚠ MUTASYON muafyok" : ""));
  r.forEach((x, i) => { if (x.kusur) console.log("A1\t" + (i + 1) + "\t" + x.kusur); });
})().catch(e => { console.log("A1-BILGI\tÇIKMIŞ BENZERLİK (KAPI-A1): ÖLÇÜLMEDİ — " + e.message); });
