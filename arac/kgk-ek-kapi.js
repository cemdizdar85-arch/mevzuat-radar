// KGK EK KAPI — hazır soru ön denetiminde YALNIZ kgk- etiketinde koşar (arac/hazir-soru-denetle.ps1 KgkEkKapi). 0 USD, model yok.
// 14.10.2026 KGK oturumu, Cem "1.2.3" (t4 dalgasının iki bağımsız okuyucu bulgularından; ölçüm aşağıda).
//
// KGK-DC (DURDURUR) "Doğru cevap" kayması: açıklamadaki "Doğru cevap: <tutar>" tutarı doğru şıkta geçmiyor.
//   Olay (ölçüldü 14.10): t4 tms-g1'de 5 hesaplı soruda yazar tutarları değiştirmiş, açıklama A–E'deki "Doğru cevap" satırını
//   eski tutarda bırakmıştı; ön denetim "kusursuz" dedi, iki okuyucu ayrı ayrı yakaladı.
// KGK-MK (DURDURUR) eski yetkili makam: sigorta/BES bağlamında "Müsteşarlık / Hazine Müsteşarlığı / Bakan(ın) yetkili…" öğretiliyor.
//   Dayanak: SEDDK Teşkilat CBK (47 s.) m.19/1 — 5684'teki Müsteşarlık/Bakan atıfları Kuruma/Kurula yapılmış sayılır (ambarda:
//   "SEDDK Teskilat ve Gorevleri Hakkinda CBK (47 s.) m.19"). Ambardaki 5684 metni eski adları taşıdığı için yazar oradan alıyor.
//   Olay (ölçüldü 14.10): t4 sigorta-g2'de 4 soru (3'ü kök/şıkta → dalgadan çıktı); eski boşluk partilerinde 101 sigorta sorusunun 14'ü.
// NOT-KGK-KA (DURDURMAZ) kısa alanda şart düşmesi: hap / sinav_taktigi / sade.* alanında ISTISNA sözlüğündeki bir atıf geçiyor ama
//   o hükmün şartı/istisnası AYNI alanda yok. t4 son turlarında okuyucuların bulduğu kusurların çoğu bu sınıftı (K14).
//   Yalnız NOT: atfın şartı başka cümlede/alanda meşru olarak verilmiş olabilir — okuyucu karar verir.
// 🚫 GÖRMEZ: "Doğru cevap" kalıbı dışında yazılmış yanlış tutar · sözel cevaplı soruda kayma · sigorta kelimesi geçmeyen soruda eski
//   makam · sözlükte olmayan paragrafın istisnası · şartın eş anlamlı başka sözle yazılması (KA yanlış alarm verir).
// ÖLÇÜLDÜ (14.10, güncel 1.606 KGK hazır soru): DC 0 · MK 0 · KA 2 not — ikisi de YANLIŞ ALARM (atıf yalnız "p.27, p.28 ve p.9 …"
//   gibi bir madde listesinde geçiyor, kural cümlesi yok). Okuyucu öncesi ilk hâller (t4 yedek): tms-g1 DC 5/5 yakalandı ·
//   sigorta-g2 MK 4/4 yakalandı.
// Öz-sınav: node arac/kgk-ek-kapi.js --sinav (vakalar + her kural için mutasyon: kapatılınca sınav KIRMIZI düşmeli).
// Kullanım: node arac/kgk-ek-kapi.js --tek <soru.json>   ·   --dosya <hazir.json> (dizi; soru başına satır)
'use strict';
const fs = require('fs');
let MUT = process.env.KGK_EK_MUTASYON || '';

const sayilar = s => (String(s).match(/\d{1,3}(?:\.\d{3})+(?:,\d+)?|\d+(?:,\d+)?/g) || [])
  .map(x => String(+x.replace(/\./g, '').replace(',', '.'))).filter(n => !/^(19|20)\d\d$/.test(n));   // 32,00 = 32; yıl karşılaştırılmaz
function dogruSik(q) {
  const h = String(q.dogru || '').trim().toUpperCase();
  if (Array.isArray(q.siklar)) return q.siklar['ABCDE'.indexOf(h)];
  return (q.siklar || {})[h];
}
function DC(q) {
  if (MUT === 'dc') return [];
  const sik = dogruSik(q); if (sik == null) return [];
  const ds = new Set(sayilar(typeof sik === 'object' ? JSON.stringify(sik) : sik));
  const metin = JSON.stringify({ aciklama: q.aciklama, adimlar: q.adimlar, teshis: q.teshis, sade: q.sade });
  const yanlis = new Set();
  for (const m of metin.matchAll(/[Dd]o[gğ]ru cevap\s*[:=]\s*([^.\\"]*\d[^\\"]{0,30})/g)) {
    const ns = sayilar(m[1]).filter(n => +n >= 10);
    if (ns.length && !ns.some(n => ds.has(n))) yanlis.add(ns[0]);
  }
  return yanlis.size ? [`KGK-DC "Doğru cevap" kayması: açıklama ${[...yanlis].join(', ')} diyor, doğru şıkta yok (tutarı her alanda düzelt)`] : [];
}
const SIG = /sigorta|reasürans|eksper|acente|bireysel emeklilik|emeklilik şirket|4632|5684|garanti fonu/i;
const ESKI = /Müsteşarlı[kğ]|Hazine Müsteşar|\bBakan(?:ın|ca|ce)?\s+(?:yetkili|izn|onay|belirle|tarafından)|\bBakanın\s|\bBakanca\b/;
const ESKI_HARIC = /eski ad|önceki ad|yerini al|devredil|yapılmış sayılır|CBK \(47/i;
function MK(q) {
  if (MUT === 'mk') return [];
  const s = JSON.stringify(q);
  if (MUT !== 'sigorta' && !SIG.test(s)) return [];
  const o = [];
  const tara = (ad, deger) => { const t = typeof deger === 'string' ? deger : JSON.stringify(deger || ''); for (const c of t.split(/(?<=[.!?;])\s+|\\n/)) if (ESKI.test(c) && !ESKI_HARIC.test(c)) { o.push(ad); return; } };
  for (const k of Object.keys(q)) if (!['konu', 'zorluk', 'kaynak_adlar'].includes(k)) tara(k, q[k]);
  return o.length ? [`KGK-MK eski yetkili makam ("Müsteşarlık/Bakan") ${o.join(', ')} alanında — bugün SEDDK Kurum/Kurul (CBK 47 m.19/1); kök/şıktaysa soru yeniden yazılır`] : [];
}
// atıf → aynı kısa alanda bulunması gereken şart/istisna (t4 okumalarından; her satırın kaynağı paragrafın kendisi)
const ISTISNA = [
  [/TMS 32 p\.22(?![A0-9])/, /22A/, 'TMS 32 p.22 → p.22A istisnası'],
  [/TFRS 9 p\.5\.4\.1(?![0-9])/, /kredi.de[ğg]er d[üu][şs][üu]kl/i, 'TFRS 9 p.5.4.1 → kredi-değer düşüklüğü istisnası'],
  [/TMS 12 p\.58(?![0-9])/, /i[şs]letme birle[şs]me/i, 'TMS 12 p.58 → işletme birleşmesi bendi'],
  [/TFRS 15 p\.56(?![0-9])/, /kuvvetle muhtemel/i, 'TFRS 15 p.56 → "kuvvetle muhtemel" eşiği'],
  [/TFRS 3 p\.B55\(a\)/, /kendili[ğg]inden/i, 'TFRS 3 p.B55(a) → "kendiliğinden" kesilen ödeme'],
  [/TFRS 5 p\.11(?![0-9])/, /ihtimali y[üu]ksek/i, 'TFRS 5 p.11 → "ihtimali yüksek"'],
  [/TMS 29 p\.27(?![0-9])/, /fiyat d[üu]zeyine ba[ğg]l[ıi] olma/i, 'TMS 29 p.27 → fiyat düzeyine bağlı olmama şartı'],
  [/m\.1445\/6/, /riziko ger[çc]ekle[şs]meden/i, 'TTK m.1445/6 → riziko gerçekleşmeden'],
  [/5684[^.]{0,40}m\.17\/4|m\.17\/4[^.]{0,40}5684/, /hayat d[ıi][şs][ıi]/i, '5684 m.17/4 → yalnız hayat dışı'],
];
function KA(q) {
  if (MUT === 'ka') return [];
  const alanlar = [['hap', q.hap], ['sinav_taktigi', q.sinav_taktigi]];
  if (q.sade && typeof q.sade === 'object') for (const [k, v] of Object.entries(q.sade)) alanlar.push(['sade.' + k, v]);
  const o = [];
  for (const [ad, v] of alanlar) {
    const t = typeof v === 'string' ? v : JSON.stringify(v || '');
    for (const [atif, sart, etk] of ISTISNA) if (atif.test(t) && !sart.test(t)) o.push(`NOT-KGK-KA ${ad}: ${etk} aynı alanda yok (K14 — şart başka cümlede verildiyse geç)`);
  }
  return o;
}
// KGK-CZ (DURDURUR) çizim kapısı: hazır soru sitedeki "✍️ Nöbetçi çizerek çözsün" kapısından (cizerek-coz.js cizimKapi) geçmiyor.
//   22.10.2026 KGK oturumu, Cem: "KGK eksiklerini tamamla ama Nöbetçi çizsin ve çizimle anlatsın; 'var zaten' deme." KGK'da düğme
//   listeyle değil kuralla açılır (kgk- öneki + cizimKapi): kapıdan dönen soru yayına düğmesiz çıkar → hedefe sayılmaz.
//   Hazır dosya site biçiminde değildir: siteVeri() motor/kaydir-coz.ps1'in kapıya giren alanlarını aynen kurar (tuzak = açıklamanın
//   "Ad: metin" ayrımı arac/tuzak-ayir.ps1 · kural/olay = doğru şıkkın açıklamasındaki "Kural:" / "Bu olayda:"/"Hesap:" · taktik =
//   sinav_taktigi · celdiriciYol = celdirici_yol · verilenAdim · aynı ad+sonuçlu art arda adım birleşir).
//   ÖLÇÜLDÜ (22.10, `--esdeger`, ambarın TAMAMI): kasadaki 1.627 KGK sorusunun dalga kimlikli 1.294'ü hazır karşılığıyla eşlendi;
//   1.294'ünde siteVeri() + cizimKapi kasadaki veriyle AYNI sonucu verdi (fark 0). Eşlenmeyen 333 = eski kimlik biçimi (d1/o2/gm-r1…).
//   Kasada geçen: t7 75/88 · t8 100/127 (KGK toplam 1.290/1.627).
//   Talimat karşılığı: arac/GM-HAZIR-SORU-TALIMATI-KGK.md "K17 — ÇİZİM KAPISI" (CZ1–CZ6); kusur satırı hangi CZ kuralının ihlal edildiğini söyler.
//   🚫 GÖRMEZ: TurkceOnar onarımı (kaydir-coz.ps1 ASCII Türkçeyi düzeltir; hazır dosya zaten Türkçe yazılır — ölçülmüş fark yok, ama
//   ASCII yazılmış alan sitede başka sayı/cümle sınırı verebilir) · sayfadaki seviye/şık kaydırma (kapı harfe değil şık metnine bakar) ·
//   çizimin anlamca doğru olup olmadığı (cizerek-coz.js GÖRMEZ satırları aynen geçerli) · KGK_DIS'e elle eklenen kimlik.
const path = require('path');
let CIZ = null;
function cizimModulu() { if (CIZ === null) { try { CIZ = require(path.join(__dirname, '..', 'cizerek-coz.js')); } catch (e) { CIZ = false; } } return CIZ; }
const TZ_KALINTI = /^(ne soruluyor|kural|hesap|bu olayda|do[gğ]rusu)$|^ne soruluyor|ne soruluyor\?|tekrar edilmez|tekrarlanmaz|tekrarlamadan|tekrar etmeden/i;
const TZ_ISTEM = /^Ne soruluyor[^.:]{0,40}?(tekrar edilmez|tekrarlanmaz|tekrarlamadan|tekrar etmeden)[^.:A-ZÇĞİÖŞÜ]*[.,]?\s*/i;
function tuzakAyirHam(a) { const m = String(a).match(/^([^:]{3,60}):\s*([\s\S]*)$/); return m ? { ad: m[1].trim().replace(/^\[|\]$/g, '').replace(/\]\s*/g, ' '), metin: m[2].trim() } : { ad: 'Tuzak', metin: String(a) }; }
function tuzakAyir(a) {   // arac/tuzak-ayir.ps1 TuzakAyir'in JS karşılığı (PS -match büyük/küçük harf duyarsız)
  const c = tuzakAyirHam(a); if (!TZ_KALINTI.test(c.ad)) return c;
  const u = String(a).replace(TZ_ISTEM, '');
  if (u !== a) { const d = tuzakAyirHam(u); if (!TZ_KALINTI.test(d.ad)) return d; }
  const m = u.match(/(?:^|[.;]\s+|\s)([A-ZÇĞİÖŞÜ][^.:;]{1,58}?Tuza[gğ][iı])\s*:\s*([\s\S]*)$/);
  if (m) return { ad: m[1].trim(), metin: m[2].trim() };
  let r = u.replace(/^Ne soruluyor\s*:\s*[\s\S]*?(?=\s(?:Kural|Hesap|Bu olayda|Do[gğ]rusu)\s*:|$)/i, '').trim();
  if (!r) r = u.replace(/^Ne soruluyor\s*:\s*/i, '').trim();
  r = r.replace(/\s*Hesap\s*:\s*[-–—](?=\s|$)/gi, ' ').trim().replace(/\s{2,}/g, ' ');
  return { ad: 'Tuzak', metin: r || u };
}
function aciklamaDuz(a) {
  if (a == null) return ''; if (typeof a === 'string') return a;
  const p = []; for (const [k, on] of [['ne_soruluyor', 'Ne soruluyor: '], ['kural', 'Kural: '], ['tuzak', ''], ['hesap', 'Hesap: '], ['dogrusu', 'Doğrusu: ']]) if (a[k]) p.push(on + a[k]);
  return (p.length ? p : Object.values(a).map(String)).join(' ');
}
function tuzakMetin(a) { if (a == null) return ''; if (typeof a === 'string') return a; if (a.tuzak) return a.tuzak + (a.dogrusu ? ' Doğrusu: ' + a.dogrusu : ''); return aciklamaDuz(a); }
function siteVeri(q) {   // motor/kaydir-coz.ps1 satır ~240-439'un kapıya giren alanları
  const d = String(q.dogru || ''), ac = q.aciklama || {}, acD = aciklamaDuz(ac[d]);
  const mk = acD.match(/Kural:\s*([\s\S]*?)(?=(Hesap:|Bu olayda:|Doğrusu:|Dogrusu:|$))/), mo = acD.match(/(Hesap:|Bu olayda:)\s*([\s\S]*?)(?=(Doğrusu:|Dogrusu:|$))/);
  const tuzak = {}; for (const h of 'ABCDE') if (h !== d && ac[h] && MUT !== 'cz-tuzak') tuzak[h] = MUT === 'cz-tuzakayir' ? tuzakAyirHam(tuzakMetin(ac[h])) : tuzakAyir(tuzakMetin(ac[h]));
  const siklar = {}; for (const h of 'ABCDE') if ((q.siklar || {})[h]) siklar[h] = String(q.siklar[h]);
  const adK = f => { const p = String(f).split(/\s=\s/); return [p[0].replace(/\s+/g, ' ').trim().toLowerCase(), p[p.length - 1].replace(/\s*\([^)]*\)/g, '').replace(/\s+/g, ' ').trim().toLowerCase()]; };
  const adimlar = [];
  for (const a of (q.adimlar || [])) {
    if (!a) continue; let fm = String(a.formul || '').trim(); const an = String(a.anlatim || '');
    if (!fm) { fm = an.split(/(?<=[.!?])\s+/)[0]; if (fm.length > 110) fm = fm.slice(0, 108) + '…'; }
    if (adimlar.length) { const k1 = adK(adimlar[adimlar.length - 1].formul), k2 = adK(fm); if (k1[0] === k2[0] && k1[1] === k2[1] && !/^(verilen|soruda ne var|yanlış yol)/.test(k1[0])) { adimlar[adimlar.length - 1].anlatim = (adimlar[adimlar.length - 1].anlatim + ' ' + an).trim(); continue; } }
    const o = { formul: fm, anlatim: an }; for (const fx of ['sik', 'karar', 'paragraf']) if (a[fx] && String(a[fx]).trim()) o[fx] = String(a[fx]).trim();
    adimlar.push(o);
  }
  if (adimlar.length && /^(Verilen|Soruda ne var|Soru bize)/.test(adimlar[0].formul)) adimlar[0].verilenAdim = true;
  let celdiriciYol = null; if (q.celdirici_yol) { celdiriciYol = {}; for (const [h, v] of Object.entries(q.celdirici_yol)) if (String(v || '').trim()) celdiriciYol[h] = String(v); }
  let teshis = null; if (q.teshis) { teshis = {}; for (const [h, o] of Object.entries(q.teshis)) if (o) teshis[h] = { yanilgi: String(o.yanilgi || ''), gercek: String(o.gercek || ''), ayirt: String(o.ayirt || ''), paragraf: String(o.paragraf || '') }; }
  return { soru: String(q.soru || ''), siklar, dogru: d, tuzak, kural: mk && MUT !== 'cz-kural' ? mk[1].trim() : acD, olay: mo ? mo[2].trim() : '', hap: String(q.hap || ''), taktik: MUT === 'cz-taktik' ? '' : String(q.sinav_taktigi || ''), dayanak: String(q.dayanak || ''), adimlar, teshis, celdiriciYol };
}
const CZ_KURAL = [[/^SZ-(HUKUM|SONUC|ONCUL)/, 'CZ1 öncül hükmü ("Bu olayda: I doğru · II yanlış …")'], [/^SZ-(DOGRU|CIFT|YOK)/, 'CZ2 doğru şık hap/teşhiste AYNEN'],
  [/^(SZ-)?RAKAM/, 'CZ3 sayı disiplini'], [/^(ARITMETIK|DOGRU)/, 'CZ4 hesap adımı'], [/^SZ-NEDEN/, 'CZ5 her yanlış şıkta tuzak metni'], [/^SZ-(ALT|CELISKI)|^SOZEL|^VERI|^HATA/, 'CZ6 kök/şık biçimi']];
function cizimSonuc(q, id) {
  const C = cizimModulu(); if (!C) return { kor: true };
  const s = Object.assign({ id: id || 'kgk-on-kapi/kp-01' }, siteVeri(q));
  let r; try { r = C.cizimKapi(s); } catch (e) { r = { gecer: false, neden: ['HATA ' + e.message] }; }
  if (MUT === 'cz-gecir') r = { gecer: true, neden: [], senaryo: r.senaryo };
  return r;
}
function CZ(q) {
  if (MUT === 'cz') return [];
  const r = cizimSonuc(q); if (r.kor) return ['NOT-KGK-CZ KÖR: cizerek-coz.js yüklenemedi (çizim kapısı ölçülmedi)'];
  if (r.gecer) return [];
  /* sayısal kapı SOZEL ile dönüp sözel şablon da düştüyse "SOZEL"/"doğru şıkta sayı yok" gürültüdür: asıl neden sözel kodlarda */
  let ne = r.neden; const sz = ne.filter(n => /^SZ-/.test(n)); if (sz.length) ne = sz;
  const kural = [...new Set(ne.map(n => (CZ_KURAL.find(([re]) => re.test(n)) || [0, 'CZ6 kök/şık biçimi'])[1]))];
  return [`KGK-CZ çizim kapısından dönüyor → ${kural.join(' · ')} :: ${ne.slice(0, 3).join(' | ').slice(0, 240)}`];
}
// KGK-G2 (DURDURUR) öncüllü çeldirici: şıklar Romen öncül kümesiyse ("Yalnız I", "I ve III", "I, II ve IV") her yanlış şık doğru
//   kümeden TAM BİR öncülle ayrılmalı (simetrik fark = 1). 29.10 KGK bitiş dalgası, Cem "gm önerilerini yap": Bankacılık t9
//   okumalarında çıkarılan 11 sorunun 7'si bu sınıftı (r1–r5 ayrı ayrı "çeldirici iki öncülle ayrılıyor, tek yanılgı bu şıkkı
//   vermiyor" diye CIKAR); her biri beş tur okuma harcamıştı. Kapı okuyucunun uyguladığı kuralı teslimde mekanik yapar.
//   🚫 GÖRMEZ: çıkmış KGK sınavında 3 öncüllü soruda iki öncülle ayrılan şık görülebilir (ölçülmedi) — bu kapı bizim okuma
//   ölçütümüzle aynıdır, sınavdan sıkı olabilir; çözüm dördüncü öncül eklemek · tek yanılgının açıklamada gerçekten yazılı olması
//   (anlam) · Romen dışı öncül numarası (a, b, 1., 2.).
const ROMA_K = /^(I{1,3}|IV|V|VI{0,3})$/;
function kumeOku(t) { const p = String(t || '').replace(/^\s*Yalnız\s+/i, '').split(/\s*(?:,|\bve\b)\s*/).map(x => x.trim()).filter(Boolean); return p.length && p.every(x => ROMA_K.test(x)) ? new Set(p) : null; }
function G2(q) {
  if (MUT === 'g2') return [];
  const s = q.siklar || {}, d = String(q.dogru || '').toUpperCase(), D = kumeOku(s[d]); if (!D) return [];
  const H = Object.keys(s).filter(h => h !== d); const K = H.map(h => [h, kumeOku(s[h])]); if (K.some(([, k]) => !k)) return [];
  const kotu = K.filter(([, k]) => [...k].filter(x => !D.has(x)).length + [...D].filter(x => !k.has(x)).length !== 1).map(([h]) => `${h} (${s[h]})`);
  return kotu.length ? [`KGK-G2 öncüllü çeldirici doğru kümeden (${s[d]}) birden çok öncülle ayrılıyor: ${kotu.join(', ')} — her yanlış şık TEK öncül eklemeli/çıkarmalı (gerekirse dördüncü öncül ekle)`] : [];
}
const denetle = q => [...DC(q), ...MK(q), ...KA(q), ...CZ(q), ...G2(q)];

/* KGK-CZ öz-sınav soruları: hazır dosya biçiminde, uydurma (bankadaki hiçbir soruyla aynı değil) */
const czO = (o) => Object.assign({ konu: 'uydurma öncül', zorluk: 'cokzor',
  soru: '(K) A.Ş. denetçisi Uydurma Denetim\'dir. Uydurma Standarda göre aşağıdaki ifadelerden hangileri doğrudur?\nI. Denetçi bağımsızdır.\nII. Denetçi müşterinin defterini tutar.\nIII. Denetçi çalışma kâğıdı hazırlar.',
  siklar: { A: 'Yalnız I', B: 'I ve II', C: 'I ve III', D: 'II ve III', E: 'I, II ve III' }, dogru: 'C',
  adimlar: [{ formul: 'Soruda ne var: üç öncül · istenen: doğru olanlar', anlatim: 'Her öncülü ayrı sına.' }, { formul: 'Kural: denetçi bağımsızdır, defter tutmaz, kâğıt hazırlar', anlatim: '' },
    { formul: 'Bu olayda: I doğru · II yanlış · III doğru', anlatim: 'Doğru küme I ve III.' }, { formul: 'Doğru şık: I ve III', anlatim: 'Doğru cevap: I ve III.' }],
  aciklama: { A: 'Eksik Öncül Tuzağı: III de doğrudur; denetçi çalışma kâğıdı hazırlar.', B: 'Defter Tuzağı: II yanlıştır; denetçi müşterinin defterini tutmaz.', C: 'Kural: bağımsızlık ve belgeleme. Bu olayda: I ve III doğru.',
    D: 'Bağımsızlık Tuzağı: I de doğrudur; denetçi bağımsızdır.', E: 'Hepsi Tuzağı: II yanlıştır; defter tutmak bağımsızlığı bozar.' },
  hap: 'Denetçi bağımsız kalır ve belgeler; defter tutmaz.', sinav_taktigi: 'Defter tutma diyen öncülü önce sına.', dayanak: 'Uydurma Standart: Denetçi bağımsızdır ve çalışma kâğıdı hazırlar.' }, o);
const czD = (o) => Object.assign({ konu: 'uydurma düz', zorluk: 'kolay', soru: 'Uydurma Kanuna göre denetçiyi hangi kurum yetkilendirir?',
  siklar: { A: 'Uydurma Kurumu', B: 'Ticaret odası', C: 'Belediye', D: 'Noter', E: 'Valilik' }, dogru: 'A',
  adimlar: [{ formul: 'Soruda ne var: yetki makamı', anlatim: '' }, { formul: 'Kural: yetki kanunla tek kuruma verilir', anlatim: '' }, { formul: 'Doğru şık: Uydurma Kurumu', anlatim: '' }],
  aciklama: { A: 'Kural: yetki kanunla verilir.', B: 'Oda Tuzağı: oda meslek kuruluşudur, yetki vermez.', C: 'Yerel Tuzak: belediye yerel yönetimdir.', D: 'Noter Tuzağı: noter onay verir, yetkilendirmez.', E: 'Mülki Tuzak: valilik mülki idaredir.' },
  teshis: { A: { gercek: 'Denetçiyi Uydurma Kurumu yetkilendirir.', yanilgi: '' } }, hap: 'Yetki kanunla verilir.', sinav_taktigi: 'Yetki sorusunda kanundaki makamı ara.', dayanak: 'Uydurma Kanun: Denetçiyi Kurum yetkilendirir.' }, o);
const czS = (o) => Object.assign({ konu: 'uydurma ifade', zorluk: 'zor', soru: 'Uydurma Ltd. ilk kez denetlenmektedir. Uydurma Standarda göre aşağıdakilerden hangisi doğrudur?',
  siklar: { A: 'Denetçi önceki dönem tablolarını hiç okumadan görüş verir.', B: 'Denetçi açılış bakiyeleri için yeterli ve uygun kanıt elde eder.', C: 'Açılış bakiyeleri denetim kapsamı dışında kalır.', D: 'Önceki denetçiyle iletişim yasaktır.', E: 'İlk denetimde önemlilik belirlenmez.' }, dogru: 'B',
  adimlar: [{ formul: 'Soruda ne var: ilk denetim', anlatim: '' }, { formul: 'Kural: paragraf 29 gereği açılış bakiyesi için kanıt aranır', anlatim: '' }, { formul: 'Doğru şık: açılış bakiyesi için kanıt', anlatim: '' }],
  aciklama: { A: 'İnceleme Tuzağı: önceki dönem tabloları okunur.', B: 'Kural: açılış bakiyesi kanıtı.', C: 'Kapsam Tuzağı: açılış bakiyeleri kapsamdadır.', D: 'İletişim Tuzağı: önceki denetçiyle görüşülebilir.', E: 'Önemlilik Tuzağı: önemlilik her denetimde belirlenir.' },
  teshis: { B: { gercek: 'Açılış bakiyeleri için yeterli ve uygun kanıt elde edilir.' } }, hap: 'İlk denetimde açılış bakiyeleri için kanıt aranır.', sinav_taktigi: 'Açılış bakiyesini ara.', dayanak: 'Uydurma Std p.29: açılış bakiyeleri için kanıt elde edilir.' }, o);
const czH = (o) => Object.assign({ konu: 'uydurma hesap', zorluk: 'kolay', soru: 'Uydurma A.Ş. 12 aylık kira için peşin 48.000 TL ödemiştir. Aylık kira gideri kaç TL\'dir?',
  siklar: { A: '4.000 TL', B: '3.000 TL', C: '6.000 TL', D: '8.000 TL', E: '12.000 TL' }, dogru: 'A',
  adimlar: [{ formul: 'Verilen: kira 48.000 (soruda verilen); süre 12 ay (soruda verilen)', anlatim: 'Soru kirayı ve süreyi vermiş.' }, { formul: 'Aylık kira = 48.000 / 12 = 4.000', anlatim: 'Toplamı aya böleriz.' }, { formul: 'Sağlama = 4.000 × 12 = 48.000', anlatim: '' }],
  celdirici_yol: { B: '48.000 / 16 = 3.000 (ay sayısını yanlış aldı)', C: '48.000 / 8 = 6.000 (sekiz ay saydı)', D: '48.000 / 6 = 8.000 (altı ay saydı)', E: '48.000 / 4 = 12.000 (çeyrek sandı)' },
  aciklama: { A: 'Kural: toplam ay sayısına bölünür.', B: 'Ay Tuzağı: ay sayısı 12dir.', C: 'Ay Tuzağı: sekiz değil on iki ay.', D: 'Ay Tuzağı: altı değil on iki ay.', E: 'Çeyrek Tuzağı: dönem bir yıldır.' },
  hap: 'Peşin kira ay sayısına bölünür.', sinav_taktigi: 'Önce ay sayısını bul.', dayanak: 'Uydurma Std: gider dönemine dağıtılır.' }, o);
function sinav() {
  const sq = (o) => Object.assign({ konu: 'x', zorluk: 'zor', soru: 'Kök', siklar: { A: '1.000 TL', B: '3.767.000 TL', C: '5.000 TL', D: '6.000 TL', E: '7.000 TL' }, dogru: 'B' }, o);
  const V = [
    ['DC: kayma yakalanır', sq({ aciklama: { A: 'Yanlış. Doğru cevap: 3.740.000 TL.' } }), /KGK-DC/, 1],
    ['DC: doğru tutar geçer', sq({ aciklama: { A: 'Yanlış. Doğru cevap: 3.767.000 TL.' } }), /KGK-DC/, 0],
    ['DC: 32,00 = 32 eşit sayılır', sq({ siklar: { A: '%32,00', B: 'x', C: 'y', D: 'z', E: 'w' }, dogru: 'A', aciklama: { B: 'Doğru cevap: %32.' } }), /KGK-DC/, 0],
    ['DC: yıl karşılaştırılmaz', sq({ aciklama: { A: 'Doğru cevap: 2026 dönemi için 3.767.000 TL.' } }), /KGK-DC/, 0],
    ['DC: dizi şıklar', sq({ siklar: ['1 TL', '20 TL', '30 TL', '40 TL', '50 TL'], dogru: 'C', aciklama: { A: 'Doğru cevap: 25 TL.' } }), /KGK-DC/, 1],
    ['MK: Müsteşarlık izni (sigorta) yakalanır', sq({ soru: 'Sigorta kooperatifi kurulması için', aciklama: { A: 'Müsteşarlık izni gerekir.' } }), /KGK-MK/, 1],
    ['MK: Bakan yetkilidir (5684) yakalanır', sq({ soru: '5684 sayılı Kanun garanti fonu', adimlar: [{ anlatim: 'Bakan yetkilidir; Bakanın belirlediği oran.' }] }), /KGK-MK/, 1],
    ['MK: SEDDK/Kurum geçer', sq({ soru: 'Sigorta şirketi', aciklama: { A: 'Kurum (SEDDK) izni gerekir.' } }), /KGK-MK/, 0],
    ['MK: sigorta dışı bağlam geçer (bankacılık)', sq({ soru: 'Banka kuruluşu', aciklama: { A: 'Müsteşarlık eski düzenlemede yer alırdı.' } }), /KGK-MK/, 0],
    ['MK: "Hazine ve Maliye Bakanlığınca" geçer', sq({ soru: 'Bireysel emeklilik devlet katkısı', aciklama: { A: 'Hazine ve Maliye Bakanlığınca ödenir.' } }), /KGK-MK/, 0],
    ['MK: eski ad açıklaması geçer', sq({ soru: 'Sigorta denetimi', aciklama: { A: 'Hazine Müsteşarlığının görevleri CBK (47 s.) m.19 ile Kuruma yapılmış sayılır.' } }), /KGK-MK/, 0],
    ['KA: TMS 32 p.22 hap\'ta 22A yok', sq({ hap: 'TMS 32 p.22 gereği prim özkaynaktır.' }), /NOT-KGK-KA/, 1],
    ['KA: aynı alanda 22A var geçer', sq({ hap: 'TMS 32 p.22 gereği (p.22A hariç) prim özkaynaktır.' }), /NOT-KGK-KA/, 0],
    ['KA: sade.dogru TFRS 15 p.56 eşiksiz', sq({ sade: { dogru: 'TFRS 15 p.56 gereği iptal riski yüksek bedel eklenmez.' } }), /NOT-KGK-KA/, 1],
    ['KA: açıklamada atıf ölçülmez (uzun alan)', sq({ aciklama: { A: 'TMS 32 p.22 gereği prim özkaynaktır.' } }), /NOT-KGK-KA/, 0],
    ['KA: TMS 32 p.22A atfı p.22 sayılmaz', sq({ hap: 'TMS 32 p.22A istisnası uygulanır.' }), /NOT-KGK-KA/, 0],
    // ---- KGK-CZ (22.10) — uydurma hazır sorular (bankada yok; depo public) ----
    ['CZ: öncüllü + "Bu olayda" satırı geçer (CZ1)', czO(), /KGK-CZ/, 0],
    ['CZ: öncüllü "I: … → DOĞRU", Bu olayda yok → CZ1', czO({ adimlar: czO().adimlar.slice(0, 2).concat([{ formul: 'I: Denetçi bağımsızdır → DOĞRU', anlatim: '' }, { formul: 'II: Denetçi defter tutmaz → YANLIŞ', anlatim: '' }, { formul: 'III: Denetçi kâğıt hazırlar → DOĞRU', anlatim: '' }, czO().adimlar[3]]),
      aciklama: { A: 'Eksik Öncül Tuzağı: denetçi çalışma kâğıdı hazırlar.', B: 'Defter Tuzağı: denetçi müşterinin defterini tutmaz.', C: 'Kural: bağımsızlık ve belgeleme.', D: 'Bağımsızlık Tuzağı: denetçi bağımsızdır.', E: 'Hepsi Tuzağı: defter tutmak bağımsızlığı bozar.' } }), /KGK-CZ.*CZ1/, 1],
    ['CZ: öncül hükmü tuzakla çelişir → CZ1', czO({ aciklama: Object.assign({}, czO().aciklama, { E: 'Hepsi Tuzağı: II de doğrudur; denetçi defter tutabilir.' }) }), /KGK-CZ.*CZ1/, 1],
    ['CZ: düz soru, doğru şık teşhiste aynen → geçer (CZ2)', czD(), /KGK-CZ/, 0],
    ['CZ: düz soru, doğru şık hiçbir cümlede yok → CZ2', czD({ teshis: {} }), /KGK-CZ.*CZ2/, 1],
    ['CZ: ifade sorusu, taktikte dayanakta olmayan paragraf no → CZ3', czS({ sinav_taktigi: 'Paragraf 29 açılış bakiyesini sorar.' }), /KGK-CZ.*CZ3/, 1],
    ['CZ: ifade sorusu, rakamsız taktik geçer', czS(), /KGK-CZ/, 0],
    ['CZ: hesap adımı tutmuyor → CZ4', czH({ adimlar: [czH().adimlar[0], { formul: 'Aylık kira = 48.000 / 12 = 4.500', anlatim: '' }, { formul: 'Toplam = 4.000 × 12 = 48.000', anlatim: '' }] }), /KGK-CZ.*CZ4/, 1],
    ['CZ: hesap sorusu geçer', czH(), /KGK-CZ/, 0],
    ['CZ: yanlış şıkkın açıklaması yok → CZ5', czD({ aciklama: Object.assign({}, czD().aciklama, { C: '' }) }), /KGK-CZ.*CZ5/, 1],
    // ---- KGK-G2 (29.10) ----
    ['G2: her çeldirici tek öncülle ayrılıyor → geçer', sq({ siklar: { A: 'Yalnız I', B: 'I ve III', C: 'Yalnız III', D: 'I, II ve III', E: 'I, III ve IV' }, dogru: 'B' }), /KGK-G2/, 0],
    ['G2: "II ve IV" ↔ doğru "I ve III" (dört öncül fark) → KUSUR', sq({ siklar: { A: 'Yalnız I', B: 'I ve III', C: 'II ve IV', D: 'I, II ve III', E: 'I, III ve IV' }, dogru: 'B' }), /KGK-G2/, 1],
    ['G2: "Yalnız I" ↔ doğru "I, II ve III" (iki öncül fark) → KUSUR', sq({ siklar: { A: 'Yalnız I', B: 'I ve II', C: 'I ve III', D: 'II ve III', E: 'I, II ve III' }, dogru: 'E' }), /KGK-G2/, 1],
    ['G2: öncülsüz şıklar → ölçülmez', sq(), /KGK-G2/, 0],
  ];
  const kos = () => { let h = 0; const d = []; for (const [ad, q, re, bek] of V) { const n = denetle(q).filter(x => re.test(x)).length > 0 ? 1 : 0; if (n !== bek) { h++; d.push(`  DÜŞTÜ: ${ad} → ${n} (beklenen ${bek})`); } }
    // dönüştürücü alanları (site biçimi motor/kaydir-coz.ps1 ile aynı): tuzak adı · kural/olay ayrımı · taktik
    const sv = siteVeri(czO({ aciklama: Object.assign({}, czO().aciklama, { C: 'Ne soruluyor: doğru öncüller. Kural: bağımsızlık ve belgeleme. Bu olayda: I ve III doğru. Doğrusu: I ve III.', B: 'Ne soruluyor sorusu tekrar edilmez. Bildirim Yönü Tuzağı: süre bildirimden başlar.' }) }));
    const bek = [['tuzak.A.ad', sv.tuzak.A && sv.tuzak.A.ad, 'Eksik Öncül Tuzağı'], ['tuzak.B.ad (kalıntılı)', sv.tuzak.B && sv.tuzak.B.ad, 'Bildirim Yönü Tuzağı'], ['kural', sv.kural, 'bağımsızlık ve belgeleme.'], ['olay', sv.olay, 'I ve III doğru.'], ['taktik', sv.taktik, 'Defter tutma diyen öncülü önce sına.'], ['verilenAdim', !!sv.adimlar[0].verilenAdim, true]];
    for (const [ad, al, b] of bek) if (al !== b) { h++; d.push(`  DÜŞTÜ: dönüştürücü ${ad} → ${JSON.stringify(al)} (beklenen ${JSON.stringify(b)})`); }
    return { h, d }; };
  MUT = ''; const t = kos();
  if (t.h) { console.log(t.d.join('\n')); console.log(`KGK EK KAPI SINAVI KIRMIZI: ${t.h}/${V.length}`); process.exit(1); }
  console.log(`KGK EK KAPI SINAVI YEŞİL: ${V.length}/${V.length}`);
  let kor = 0;
  const MS = ['dc', 'mk', 'ka', 'sigorta', 'cz', 'cz-gecir', 'cz-tuzak', 'cz-tuzakayir', 'cz-taktik', 'cz-kural', 'g2'];
  for (const m of MS) { MUT = m; const r = kos(); console.log(`  mutasyon ${m}: ${r.h ? `KIRMIZI (${r.h} vaka düştü) ✓` : 'YEŞİL ✗ sınav bu bozmayı görmüyor'}`); if (!r.h) kor++; }
  MUT = '';
  if (kor) { console.log(`MUTASYON: ${kor} bozma yakalanmadı — sınav eksik`); process.exit(1); }
  console.log(`MUTASYON: ${MS.length}/${MS.length} bozma sınavı KIRMIZI düşürdü`);
}

const [kip, yol] = process.argv.slice(2);
if (kip === '--sinav') sinav();
else if (kip === '--tek') { const q = JSON.parse(fs.readFileSync(yol, 'utf8').replace(/^﻿/, '')); for (const x of denetle(q)) console.log(x); }
else if (kip === '--dosya') {
  const A = JSON.parse(fs.readFileSync(yol, 'utf8').replace(/^﻿/, '')); let n = 0;
  A.forEach((q, i) => { for (const x of denetle(q)) { n++; console.log(`[${i}] ${q.konu} · ${x}`); } });
  console.log(`taranan ${A.length} soru · satır ${n}`);
} else if (kip === '--esdeger') {
  /* dönüştürücü eşdeğerliği: kasadaki (paket_soru, servis anahtarıyla yerelde çekilir, DEPOYA KONMAZ) her kgk-<dalga> sorusunun hazır
     karşılığı (aynı soru metni) siteVeri() ile kurulur; iki biçimde kapı sonucu aynı mı. Çıktıda soru metni yok, yalnız kimlik. */
  const fab = process.argv[4], P = JSON.parse(fs.readFileSync(yol, 'utf8')), H = {}; let es = 0, ayni = 0, bulunamadi = 0; const ayr = [];
  for (const x of P) {
    const m = String(x.id).match(/^(kgk-[a-z0-9]+-[a-z]+-g\d+-(?:kolay|zor|cokzor)(?:-\d+)?)\//); if (!m) continue;
    const f = path.join(fab, 'hazir-' + m[1] + '.json'); if (!fs.existsSync(f)) { bulunamadi++; continue; }
    const A = H[f] = H[f] || JSON.parse(fs.readFileSync(f, 'utf8').replace(/^﻿/, '')); const h = A.find(s => s.soru === (x.veri || {}).soru); if (!h) { bulunamadi++; continue; }
    es++; const C = cizimModulu(); const rk = C.cizimKapi(Object.assign({ id: x.id }, x.veri)), rh = cizimSonuc(h, x.id);
    if (rk.gecer === rh.gecer) ayni++; else ayr.push(x.id + ' kasa ' + (rk.gecer ? 'GEÇER' : 'DÖNER') + ' · hazır ' + (rh.gecer ? 'GEÇER' : 'DÖNER'));
  }
  console.log(`eşdeğerlik: eşlenen ${es} · aynı sonuç ${ayni} · farklı ${es - ayni} · hazır karşılığı bulunamayan ${bulunamadi}`); ayr.slice(0, 30).forEach(z => console.log('  ' + z));
  process.exit(es && ayni === es ? 0 : 1);
} else { console.log('kullanım: --tek <soru.json> | --dosya <hazir.json> | --sinav | --esdeger <kgk-paket.json> <fabrika>'); process.exit(2); }
