#!/usr/bin/env node
/* ============================================================================
 *  FİYAT DENETİMİ (23.11.2026, Cem "bu fiyat denetimini haftada bir otomatik koştur; bir yerde farklı fiyat çıkarsa
 *  mail gelsin … fiyat başka yerde çıkmasın, aynı")
 *
 *  NEDEN (ölçüldü 23.11): SGS 2027 + Yeterlilik 2027 fiyat değişiminden sonra 140 sayfa canlıda tek tek açıldı; fiyat
 *  motoruna bağlı OLMAYAN üç yer eski/bozuk tutar gösteriyordu: en çok çıkan sayfalarında "Açılış fiyatı ilk 0 ödeyene;
 *  sonra 2.988 TL" (3 sayfa), elçi programında satıştan kalkan 2026 SGS "2.988 → 2.588" + "4.161,6" (eksik hane),
 *  kampanya sayfasında biten kampanyanın "2.988 yerine 2.388".
 *
 *  NE YAPAR: canlı fiyat-motoru.js'i (tetikte.com'dan) çalıştırıp satıştaki paketlerin GEÇERLİ tutarlarını kendisi
 *  hesaplar (fiyat, KDV hariç, KDV dahil, 1 Ocak fiyatı, fark, 3 taksit, ayrı paket kıyası, elçi kodlu tutar, anlık
 *  teklif, resmî harçlar). Sonra sitedeki her sayfayı 1280 px'te açar, GÖRÜNEN metindeki TL tutarlarını toplar ve:
 *    ESKI   paket bağlamında (KDV / paket / taksit / ders / satın …) geçen tutar geçerli kümede yok
 *    BOZUK  "ilk 0 ödeyene" ya da tek kuruş haneli tutar ("4.161,6 TL")
 *  KIRMIZIda çıkış 1 (iş akışında Cem'e e-posta). Rapor dosyaya yazılır; depoya yazmaz.
 *
 *  🚫 GÖRMEZ: soru metinlerindeki tutarlar (paket bağlamı yoksa sayılmaz) · resmî harç/kurs tutarları dışında paket
 *     bağlamında geçen başka meşru tutar (yanlış alarm verir → GEÇERLİ_EK'e yazılır) · oturum isteyen sayfalar (Hesabım,
 *     yönetim) · telefon genişliği · mobil uygulama · reklam görselleri · e-postalar · kampanya-son-20-gun.html (biten
 *     kampanyanın kayıtlı koşulları; "sona erdi" notuyla bilerek eski tutar taşır, ATLANIR).
 *  Öz-sınav: node motor/fiyat-denetimi.js --sinav  (data: sayfalarla) · bozma: FD_MUTASYON=gecir|bozuk|tavan
 * ==========================================================================*/
'use strict';
const fs = require('fs'), path = require('path'), vm = require('vm');
const { tarayiciAc, bekle } = require(path.join(__dirname, '..', 'arac', 'tarayici.js'));
const KOK = path.join(__dirname, '..');
const TABAN = 'https://tetikte.com';
const MUT = process.env.FD_MUTASYON || '';
const ATLA = new Set(['kampanya-son-20-gun.html', 'yonetim.html', 'elci.html', '404.html']);
/* paket bağlamı: bu kelimelerden biri tutarın çevresinde yoksa (soru metni, hesap örneği) tutar sayılmaz */
const BAGLAM = /KDV|paket|Paket|taksit|Taksit|[Ss]atın al\b|ders(?:ler)?\b|Kodunla|Sitede|açılış fiyat|1 Ocak|oluyor|daha az öde/;
/* 23.11 ilk canlı koşu: soru metnindeki "makine satın almıştır … 780.000 ₺" ve "185.000 ₺'lik taksit" yanlış alarm verdi →
   paket fiyatı TAVAN_TL'yi geçmez; üstündeki tutar paket fiyatı sayılmaz (bugünkü en yüksek paket 10.425,60 TL) */
const TAVAN_TL = 50000;
function sayi(x){ return Number(String(x).replace(/\./g, '').replace(',', '.')); }

function tl(n) { n = Number(n); return (Math.round(n * 100) % 100) ? n.toLocaleString('tr-TR', { minimumFractionDigits: 2, maximumFractionDigits: 2 }) : n.toLocaleString('tr-TR'); }

/* geçerli tutar kümesi: fiyat motorunun KENDİ kodundan (replika yok) */
function gecerliKume(motorMetni) {
  const E = { console: { log() {}, warn() {}, error() {} } };
  E.window = E; E.document = { getElementById() { return null; }, querySelector() { return null; } };
  vm.createContext(E);
  vm.runInContext(motorMetni + `
;this.__K = (function(){ var k = [];
  function ek(n){ if(n === null || n === undefined || !isFinite(n)) return; k.push(tl(n)); k.push(tl(Math.round(n / (1 + KDV_ORAN) * 100) / 100)); }
  acikPaketler().forEach(function(p){
    ek(p.fiyat); ek(p.liste);
    var ar = (typeof artisBilgi === 'function') ? artisBilgi(p) : null; if(ar){ ek(Math.round((p.liste - p.fiyat) * 100) / 100); }
    if(p.taksitAdet){ ek(Math.round(p.fiyat / p.taksitAdet * 100) / 100); ek(Math.round(p.liste / p.taksitAdet * 100) / 100); }
    if(typeof ELCI !== 'undefined' && ELCI.indirim && ELCI.indirim[p.id] > 0){ ek(p.fiyat - ELCI.indirim[p.id]); ek(ELCI.indirim[p.id]); }
    if(typeof ANLIK_TEKLIF !== 'undefined' && ANLIK_TEKLIF.indirim && ANLIK_TEKLIF.indirim[p.id]){ ek(p.fiyat - ANLIK_TEKLIF.indirim[p.id]); ek(ANLIK_TEKLIF.indirim[p.id]); }
  });
  try { var ay = yeterlilikAyriEnAz('kurulus'); if(ay) ek(ay.tutar); } catch(e){}
  (function harc(o){ for(var a in o){ if(typeof o[a] === 'number') k.push(tl(o[a])), k.push(tl(o[a] * 2)), k.push(tl(o[a] * 3)), k.push(tl(o[a] * 4)); else if(o[a] && typeof o[a] === 'object') harc(o[a]); } })(HARC);
  return k; })();`, E);
  const k = new Set(E.__K || []);
  /* GEÇERLİ_EK: paket bağlamında geçen, motordan türemeyen meşru tutarlar (kurs fiyatı kıyası, KGK ücretleri) */
  ['5.250', '13.500', '15.120', '7.250', '10.800', '12.600', '2.500', '565', '950', '1.885', '3.800', '6.650'].forEach(x => k.add(x));
  return k;
}

const TOPLA = String.raw`(function(){
  function gizli(el){ for(var e=el; e && e.nodeType===1; e=e.parentElement){ if(e.hidden) return true; var cs=getComputedStyle(e); if(cs.display==='none') return true; if(/^(SCRIPT|STYLE|NOSCRIPT|TEMPLATE)$/.test(e.tagName)) return true; } return false; }
  var w=document.createTreeWalker(document.body,NodeFilter.SHOW_TEXT), p=[], n;
  while((n=w.nextNode())){ if(!n.nodeValue.trim()) continue; if(gizli(n.parentElement)) continue; p.push(n.nodeValue); }
  var t=p.join(' ').replace(/\s+/g,' '), out=[], re=/(\d{1,3}(?:\.\d{3})*(?:,\d{1,2})?)\s*(?:TL|₺)/g, m;
  while((m=re.exec(t))){ out.push({ tutar:m[1], cevre:t.slice(Math.max(0,m.index-60), m.index+m[0].length+30) }); }
  var ilk0 = /ilk 0 ödeyene/.test(t);
  return { tutarlar: out, ilk0: ilk0 }; })()`;

function denetle(sayfa, veri, kume) {
  const B = [];
  if (veri.ilk0 && MUT !== 'bozuk') B.push({ kural: 'BOZUK', sayfa, not: '"ilk 0 ödeyene" yazıyor' });
  for (const x of veri.tutarlar) {
    if (/,\d$/.test(x.tutar) && MUT !== 'bozuk') { B.push({ kural: 'BOZUK', sayfa, not: x.tutar + ' TL tek kuruş haneli · ' + x.cevre }); continue; }
    if (!BAGLAM.test(x.cevre)) continue;
    if (sayi(x.tutar) > TAVAN_TL && MUT !== 'tavan') continue;
    if (MUT === 'gecir' || kume.has(x.tutar)) continue;
    B.push({ kural: 'ESKI', sayfa, not: x.tutar + ' TL geçerli fiyatlarda yok · ' + x.cevre });
  }
  return B;
}

async function sekme(t) {
  const c = await t.cdp.cagir('Target.createTarget', { url: 'about:blank' });
  const a = await t.cdp.cagir('Target.attachToTarget', { targetId: c.targetId, flatten: true });
  const o = a.sessionId;
  await t.cdp.cagir('Emulation.setDeviceMetricsOverride', { width: 1280, height: 900, deviceScaleFactor: 1, mobile: false }, o);
  await t.cdp.cagir('Page.enable', {}, o);
  return o;
}
async function topla(t, o, url, ms) {
  await t.cdp.cagir('Page.navigate', { url }, o); await bekle(ms);
  const r = await t.cdp.cagir('Runtime.evaluate', { expression: TOPLA, returnByValue: true }, o);
  return r.result.value || { tutarlar: [], ilk0: false };
}

function sayfaListesi() {
  const L = [];
  for (const f of fs.readdirSync(KOK)) if (/\.html$/.test(f) && !ATLA.has(f) && !/^google/.test(f)) L.push(f);
  for (const d of ['sayfalar']) { try { for (const f of fs.readdirSync(path.join(KOK, d))) if (/\.html$/.test(f)) L.push(d + '/' + f); } catch (e) {} }
  (function gez(d) { let g = []; try { g = fs.readdirSync(path.join(KOK, d), { withFileTypes: true }); } catch (e) {}
    for (const e of g) { const y = d + '/' + e.name; if (e.isDirectory()) gez(y); else if (/\.html$/.test(e.name)) L.push(y); } })('kaydir');
  const ek = [];
  for (const s of ['index.html', 'fiyat.html', 'satin-al.html', 'seviye-testi.html', 'en-cok-cikan-sorular.html']) ek.push(s + '?sinav=yeterlilik');
  return L.concat(ek);
}

async function sinav() {
  const motor = fs.readFileSync(path.join(KOK, 'fiyat-motoru.js'), 'utf8');
  const kume = gecerliKume(motor);
  const E = { console: { log() {} } }; vm.createContext(E);
  vm.runInContext(motor + ';this.p=paketBul("sgs-2027");this.y=paketBul("yeterlilik-tum");', E);
  const gecerli = tl(E.p.fiyat), gecerli2 = tl(E.y.fiyat);
  const sayfa = (govde) => 'data:text/html;charset=utf-8,' + encodeURIComponent('<!doctype html><html><body>' + govde + '</body></html>');
  const V = [
    ['V1 geçerli fiyatlar temiz', sayfa('<p>SGS 2027 paketi KDV dahil ' + gecerli + ' TL · tüm dersler KDV dahil ' + gecerli2 + ' TL</p>'), 0, null],
    ['V2 eski paket fiyatı yakalanır', sayfa('<p>Tam Paket 2.490 TL + KDV (KDV dahil 2.988 TL)</p>'), 1, 'ESKI'],
    ['V3 "ilk 0 ödeyene" yakalanır', sayfa('<small>Açılış fiyatı ilk 0 ödeyene; sonra ' + gecerli + ' TL + KDV.</small>'), 1, 'BOZUK'],
    ['V4 tek kuruş haneli tutar yakalanır', sayfa('<td>Yeterlilik — tüm dersler</td><td>4.161,6 TL</td>'), 1, 'BOZUK'],
    ['V5 soru metnindeki tutar alarm vermez', sayfa('<p>İşletme 350.000 ₺ malzeme gideri ve 180.000 ₺ işçilik gideri yapmıştır.</p>'), 0, null],
    ['V6 gizli öğedeki eski fiyat alarm vermez', sayfa('<div hidden>Tam Paket 2.490 TL + KDV</div><div style="display:none">2.388 TL paket</div>'), 0, null],
    ['V8 soru metninde "satın almıştır" / "taksit" + büyük tutar alarm vermez (23.11 canlı yanlış alarmı)', sayfa('<p>Bir makine satın almıştır. Makinenin fatura bedeli 780.000 ₺; bir yıl içinde ödenecek 185.000 ₺\'lik taksit tutarı</p>'), 0, null],
    ['V7 resmî harç alarm vermez', sayfa('<p>Kalınan her ders için harç 1.260 TL, ilk başvuruda sekiz ders 10.080 TL; Tetikte 1 ders paketi</p>'), 0, null]
  ];
  const t = await tarayiciAc(); if (t.hata) { console.log('KOR: tarayıcı açılmadı ' + t.hata); process.exit(1); }
  let kir = 0;
  try {
    const o = await sekme(t);
    for (const [ad, url, bek, kural] of V) {
      const b = denetle('sinav', await topla(t, o, url, 400), kume);
      const ok = b.length === bek && (!kural || b.every(x => x.kural === kural));
      if (!ok) kir++;
      console.log((ok ? 'GEÇTİ  ' : 'KALDI  ') + ad + (ok ? '' : '  -> ' + JSON.stringify(b).slice(0, 300)));
    }
  } finally { t.kapat(); }
  console.log(kir ? `FİYAT DENETİMİ ÖZ-SINAV: KIRMIZI (${kir}/${V.length})` : `FİYAT DENETİMİ ÖZ-SINAV: YEŞİL (${V.length}/${V.length})`);
  process.exit(kir ? 1 : 0);
}

async function canli() {
  const ci = process.argv.indexOf('--cikti'), cikti = ci > -1 ? process.argv[ci + 1] : null;
  let motor;
  try { motor = await (await fetch(TABAN + '/fiyat-motoru.js?_=' + Date.now())).text(); } catch (e) { motor = ''; }
  if (!/var FIYAT = \{/.test(motor)) { const m = 'FİYAT DENETİMİ KÖR: canlı fiyat-motoru.js okunamadı'; console.log(m); if (cikti) fs.writeFileSync(cikti, m); process.exit(1); }
  const kume = gecerliKume(motor);
  const L = sayfaListesi();
  const t = await tarayiciAc(); if (t.hata) { const m = 'FİYAT DENETİMİ KÖR: tarayıcı açılmadı (' + t.hata + ')'; console.log(m); if (cikti) fs.writeFileSync(cikti, m); process.exit(1); }
  const B = []; let kor = 0, tutarli = 0;
  try {
    const o = await sekme(t);
    for (const s of L) {
      const url = TABAN + '/' + s + (s.includes('?') ? '&' : '?') + '_=' + Date.now();
      let v; try { v = await topla(t, o, url, 4000); } catch (e) { kor++; B.push({ kural: 'KOR', sayfa: s, not: e.message }); continue; }
      if (v.tutarlar.length) tutarli++;
      B.push(...denetle(s, v, kume));
    }
  } finally { t.kapat(); }
  const ozet = `FİYAT DENETİMİ: sayfa ${L.length} · tutar gösteren ${tutarli} · geçerli tutar ${kume.size} · bulgu ${B.length} (KÖR ${kor})`;
  const rapor = [ozet].concat(B.map(x => `  ${x.kural}  ${x.sayfa}: ${x.not}`)).join('\n');
  console.log(rapor + '\n' + (B.length ? 'FİYAT DENETİMİ: KIRMIZI' : 'FİYAT DENETİMİ: YEŞİL'));
  if (cikti) fs.writeFileSync(cikti, rapor);
  process.exit(B.length ? 1 : 0);
}

if (process.argv.includes('--sinav')) sinav(); else canli();
